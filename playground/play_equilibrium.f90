program play_equilibrium
  ! Read the checked-in equilibrium fixture pair (imas-python-fixtures/) and print every
  ! field equilibrium_seed.py writes, for both DD versions side by side in one table, so
  ! the two can be compared by eye to check the read-path middleware's conversion.
  !
  ! FIXTURE_DD4 is this build's own DD version, read natively - no conversion involved.
  ! FIXTURE_DD3 is the older DD 3.39.0 fixture, read through the Rust read-path middleware
  ! (middleware/) with IMAS_MW_CONVERT armed. Both reads happen in this one process: the
  ! middleware decides *per entry*, from ids_properties/version_put/data_dictionary,
  ! whether a given read actually needs the map applied (middleware/src/lib.rs,
  ! opened_root/entry_needs_conversion) - so arming the switch up front does not touch the
  ! native DD 4.1.1 read at all, and only the DD 3.39.0 read is actually converted.
  !
  ! Output is two forms of the same table, field by field, DD 4.1.1 next to DD 3.39.0:
  !   - a fixed-column table on the terminal (long values are clipped to keep columns
  !     aligned - "..." marks where a cell was cut)
  !   - a Markdown table written to play_equilibrium_report.md (untruncated; open it in an
  !     editor or a Markdown viewer when a value is too wide to read clipped in a terminal)
  ! Both list identical rows in identical order, so a genuine conversion bug shows up as a
  ! mismatched pair rather than something to spot across two separate program runs. Where
  ! the two columns disagree by design (see dd-maps/equilibrium/3.39.0--4.1.1.xml and the
  ! conversion report this program prints at the end) is not a bug: "(empty)" or an invalid
  ! marker on the DD 3.39.0 side is the map declaring that field ABSENT, LOSSY or REFUSED.
  !
  ! Run from this directory:
  !   ./bin/play_equilibrium
  use ids_routines
  use iso_c_binding
  implicit none

  character(*), parameter :: FIXTURE_DD4 = '../imas-python-fixtures/fixtures/dd-4.1.1'
  character(*), parameter :: FIXTURE_DD3 = '../imas-python-fixtures/fixtures/dd-3.39.0'
  character(*), parameter :: REPORT_MD = 'play_equilibrium_report.md'
  integer, parameter :: LABEL_W = 44, VAL_W = 34

  ! ANSI SGR codes marking, on the terminal, which fields the conversion touched - and
  ! whether it got away with it. BLUE is a converted field that came back with a value;
  ! PURPLE is one where the DD 3.39.0 side came back with nothing (see failed_read), which
  ! is the map declaring the field ABSENT or REFUSED, or a rewrite that did not find its
  ! target. Uncoloured means no rule claims the path: it was read straight through.
  !
  ! The Markdown file has no colour, so it marks the same two cases as **bold** and
  ! **bold** followed by a warning sign.
  character(*), parameter :: BLUE = achar(27)//'[34m'
  character(*), parameter :: PURPLE = achar(27)//'[35m'
  character(*), parameter :: CRESET = achar(27)//'[0m'

  ! What a value-to-string helper prints when there was nothing to print. Kept here rather
  ! than as literals at each site so failed_read below cannot drift from what is produced:
  ! NOT_READ is a leaf whose pointer came back disassociated, EMPTY is an array of
  ! structures with no elements at all (so its whole subtree is gone), NO_ELEMS is an array
  ! that exists but holds nothing.
  character(*), parameter :: NOT_READ = '(not read)'
  character(*), parameter :: EMPTY = '(empty)'
  character(*), parameter :: NO_ELEMS = '(0 elems)'

  ! ids_real_invalid as `rs` renders it. al-core writes the marker into a scalar that is not
  ! in the entry, so this is what "absent" looks like when there is no pointer to be null.
  character(*), parameter :: INVALID_SHOWN = '-9.00000E+40'

  interface
     subroutine imas_mw_conversion_report() bind(C, name="imas_mw_conversion_report")
     end subroutine imas_mw_conversion_report

     function imas_mw_path_needs_conversion(field) result(needs) &
          bind(C, name="imas_mw_path_needs_conversion")
       use, intrinsic :: iso_c_binding
       character(C_CHAR), dimension(*), intent(in) :: field
       integer(C_INT) :: needs
     end function imas_mw_path_needs_conversion

     function setenv(name, value, overwrite) bind(C, name="setenv")
       use, intrinsic :: iso_c_binding
       character(C_CHAR), dimension(*), intent(in) :: name, value
       integer(C_INT), value, intent(in) :: overwrite
       integer(C_INT) :: setenv
     end function setenv
  end interface

  integer(C_INT) :: ignored
  integer :: mdunit
  logical :: in_time_slice = .false.
  type(ids_equilibrium) :: eq4, eq3

  ! Armed before the first read: the middleware's "is conversion on at all" switch is read
  ! once via a OnceLock (convert::enabled), so setting it later would be too late. Which
  ! *entries* it actually touches is decided separately, per open, by entry_needs_conversion.
  ignored = setenv('IMAS_MW_CONVERT'//C_NULL_CHAR, '3.39.0'//C_NULL_CHAR, 0_C_INT)

  print *, 'DD version of this al-fortran build: ', trim(al_dd_version)

  call read_entry(FIXTURE_DD4, eq4)
  call read_entry(FIXTURE_DD3, eq3)

  open(newunit=mdunit, file=REPORT_MD, status='replace', action='write')
  write(mdunit, '(A)') '# play_equilibrium: DD 4.1.1 (native) vs DD 3.39.0 (converted)'
  write(mdunit, '(A)') ''
  write(mdunit, '(A)') 'Generated by `playground/play_equilibrium.f90`. Every row compares'
  write(mdunit, '(A)') 'one field read natively from the DD 4.1.1 fixture against the same'
  write(mdunit, '(A)') 'field read from the DD 3.39.0 fixture through the Rust read-path'
  write(mdunit, '(A)') 'middleware. `(empty)` or an invalid marker on the DD 3.39.0 side can'
  write(mdunit, '(A)') 'be an intentional ABSENT/REFUSED conversion outcome, not a bug - see'
  write(mdunit, '(A)') 'the conversion report at the end of the run.'

  call print_table_header()
  call dump_pair(eq4, eq3)

  call ids_deallocate(eq4)
  call ids_deallocate(eq3)
  close(mdunit)

  print *
  call imas_mw_conversion_report()

  print *
  print *, 'Done. Markdown report written to ', REPORT_MD

contains

  subroutine read_entry(fixture, eq)
    character(*), intent(in) :: fixture
    type(ids_equilibrium), intent(inout) :: eq
    integer :: idx, status
    character(:), allocatable :: retmsg

    call imas_open('imas:hdf5?path='//fixture, OPEN_PULSE, idx, status, retmsg)
    if (status /= 0) then
       print *, 'imas_open failed for ', fixture, ': ', retmsg
       stop 1
    end if
    call ids_get(idx, 'equilibrium', eq, status)
    if (status /= 0) then
       print *, 'ids_get failed for ', fixture, ', status = ', status
       call imas_close(idx)
       stop 1
    end if
    call imas_close(idx)
  end subroutine read_entry

  ! ---------------------------------------------------------------- table plumbing

  subroutine print_table_header()
    character(LABEL_W) :: lbl
    character(VAL_W) :: c4, c3
    lbl = 'field'
    c4 = 'DD 4.1.1 (native)'
    c3 = 'DD 3.39.0 (converted)'
    print *
    print *, 'field name colour: '//BLUE//'converted, value delivered'//CRESET//'   ' &
         //PURPLE//'converted, nothing came back'//CRESET//'   plain: no rule, read as-is'
    print *
    write(*, '(A,A,A,A,A)') lbl, ' | ', c4, ' | ', c3
    print '(a)', repeat('-', LABEL_W) // '-+-' // repeat('-', VAL_W) // '-+-' // repeat('-', VAL_W)
  end subroutine print_table_header

  ! A new heading and a fresh Markdown table: GitHub-flavored Markdown needs its own
  ! header/separator per table, so restarting one per section is the natural thing to do,
  ! not a limitation worked around.
  subroutine section(title)
    character(*), intent(in) :: title
    print *
    print *, '=== '//trim(title)//' ==='
    write(mdunit, '(A)') ''
    write(mdunit, '(A)') '## '//trim(title)
    write(mdunit, '(A)') ''
    write(mdunit, '(A)') '| field | DD 4.1.1 (native) | DD 3.39.0 (converted) |'
    write(mdunit, '(A)') '|---|---|---|'
  end subroutine section

  subroutine row(label, v4, v3)
    character(*), intent(in) :: label, v4, v3
    character(LABEL_W) :: lbl
    character(VAL_W) :: c4, c3
    logical :: converted
    lbl = label
    c4 = clip(v4)
    c3 = clip(v3)
    converted = needs_conversion(dd_path(label))
    if (.not. converted) then
       write(*, '(A,A,A,A,A)') lbl, ' | ', c4, ' | ', c3
       write(mdunit, '(A)') '| '//trim(label)//' | '//mdcell(v4)//' | '//mdcell(v3)//' |'
    else if (failed_read(v3)) then
       write(*, '(A,A,A,A,A,A,A)') PURPLE, lbl, CRESET, ' | ', c4, ' | ', c3
       write(mdunit, '(A)') '| **'//trim(label)//'** :warning: | '//mdcell(v4)//' | ' &
            //mdcell(v3)//' |'
    else
       write(*, '(A,A,A,A,A,A,A)') BLUE, lbl, CRESET, ' | ', c4, ' | ', c3
       write(mdunit, '(A)') '| **'//trim(label)//'** | '//mdcell(v4)//' | '//mdcell(v3)//' |'
    end if
  end subroutine row

  ! Whether the DD 3.39.0 cell holds no usable value, so a converted row can be told apart
  ! from one the conversion merely touched. Three sentinels, plus the invalid marker for the
  ! scalars that have no pointer to be null.
  !
  ! A composite cell ("m=... r=... chi2=...") counts as failed as soon as *any* part of it is
  ! the invalid marker: the row is then not something to read off as a converted value, which
  ! is the question the colour answers. Deliberately not the same question as the middleware's
  ! own per-rule report - that says what the *map* promises, this says what *this entry* gave.
  function failed_read(v3) result(failed)
    character(*), intent(in) :: v3
    logical :: failed
    failed = trim(v3) == NOT_READ .or. trim(v3) == EMPTY .or. trim(v3) == NO_ELEMS &
         .or. index(v3, INVALID_SHOWN) > 0
  end function failed_read

  ! The label is already written path-shaped ("boundary%outline%r"), so recovering the
  ! actual DD 4.1.1 path the map indexes on is mostly `%` -> `/` plus a `time_slice/`
  ! prefix for anything printed inside the per-slice loop. Two labels carry a literal
  ! "(1)" (the grids_ggd summary rows) that is not part of the path and is stripped first.
  ! A path this cannot reconstruct exactly (a few AoS summary labels fold more than one DD
  ! leaf into one row - see dump_constraints) just fails to match any rule and prints
  ! uncoloured, which under-highlights rather than mis-highlights.
  function dd_path(label) result(p)
    character(*), intent(in) :: label
    character(:), allocatable :: p
    integer :: k
    p = label
    k = index(p, '(1)')
    if (k > 0) p = p(1:k-1)//p(k+3:)
    do k = 1, len(p)
       if (p(k:k) == '%') p(k:k) = '/'
    end do
    if (in_time_slice) p = 'time_slice/'//p
  end function dd_path

  function needs_conversion(path) result(yes)
    character(*), intent(in) :: path
    logical :: yes
    yes = imas_mw_path_needs_conversion(trim(path)//C_NULL_CHAR) /= 0_C_INT
  end function needs_conversion

  ! The terminal column is fixed-width, so anything longer than VAL_W has to be cut to
  ! keep the columns lined up; the Markdown file (mdcell, below) never truncates.
  function clip(s) result(out)
    character(*), intent(in) :: s
    character(:), allocatable :: out
    if (len_trim(s) > VAL_W) then
       out = s(1:VAL_W - 3)//'...'
    else
       out = trim(s)
    end if
  end function clip

  ! Markdown table cells break on a literal "|"; none of the values this program prints
  ! contain one, but escaping is cheap insurance against that ever changing quietly.
  function mdcell(s) result(out)
    character(*), intent(in) :: s
    character(:), allocatable :: out
    integer :: k
    out = ''
    do k = 1, len_trim(s)
       if (s(k:k) == '|') then
          out = out//'\|'
       else
          out = out//s(k:k)
       end if
    end do
  end function mdcell

  ! ------------------------------------------------------------- value-to-string helpers
  ! Every function here takes exactly one side's data and returns a display string,
  ! handling the associated()/size() checks internally - the one place they are allowed to
  ! happen, so a call site is never tempted to index a disassociated pointer.

  function rs(x) result(s)
    real(ids_real), intent(in) :: x
    character(:), allocatable :: s
    character(24) :: buf
    write(buf, '(ES13.5)') x
    s = trim(adjustl(buf))
  end function rs

  function is(x) result(s)
    integer(ids_int), intent(in) :: x
    character(:), allocatable :: s
    character(16) :: buf
    write(buf, '(I0)') x
    s = trim(buf)
  end function is

  function ss(x) result(s)
    character(len=*), dimension(:), pointer, intent(in) :: x
    character(:), allocatable :: s
    if (associated(x)) then
       if (size(x) >= 1) then
          s = trim(x(1))
          return
       end if
    end if
    s = NOT_READ
  end function ss

  function ras(x) result(s)
    real(ids_real), dimension(:), pointer, intent(in) :: x
    character(:), allocatable :: s
    character(20) :: buf
    integer :: k
    if (.not. associated(x)) then
       s = NOT_READ
       return
    end if
    if (size(x) == 0) then
       s = NO_ELEMS
       return
    end if
    s = ''
    do k = 1, size(x)
       write(buf, '(ES11.4)') x(k)
       if (k > 1) s = s//','
       s = s//trim(adjustl(buf))
    end do
  end function ras

  function ia1s(x) result(s)
    integer(ids_int), dimension(:), pointer, intent(in) :: x
    character(:), allocatable :: s
    character(16) :: buf
    integer :: k
    if (.not. associated(x)) then
       s = NOT_READ
       return
    end if
    if (size(x) == 0) then
       s = NO_ELEMS
       return
    end if
    s = ''
    do k = 1, size(x)
       write(buf, '(I0)') x(k)
       if (k > 1) s = s//','
       s = s//trim(buf)
    end do
  end function ia1s

  function ra2s(x) result(s)
    real(ids_real), dimension(:,:), pointer, intent(in) :: x
    character(:), allocatable :: s
    character(20) :: buf
    integer :: i, j
    if (.not. associated(x)) then
       s = NOT_READ
       return
    end if
    s = 'shape='//is(size(x,1))//'x'//is(size(x,2))//': '
    do j = 1, size(x, 2)
       do i = 1, size(x, 1)
          write(buf, '(ES11.4)') x(i,j)
          if (i > 1 .or. j > 1) s = s//','
          s = s//trim(adjustl(buf))
       end do
    end do
  end function ra2s

  function ra4shape(x) result(s)
    real(ids_real), dimension(:,:,:,:), pointer, intent(in) :: x
    character(:), allocatable :: s
    if (associated(x)) then
       s = 'shape='//is(size(x,1))//'x'//is(size(x,2))//'x'//is(size(x,3))//'x'//is(size(x,4))
    else
       s = NOT_READ
    end if
  end function ra4shape

  function ia2shape(x) result(s)
    integer(ids_int), dimension(:,:), pointer, intent(in) :: x
    character(:), allocatable :: s
    if (associated(x)) then
       s = 'shape='//is(size(x,1))//'x'//is(size(x,2))
    else
       s = NOT_READ
    end if
  end function ia2shape

  ! Identifier structures (name/index/description) recur under several distinct derived
  ! types with the same three fields; passed as the two fields rather than the whole
  ! struct, this works for any of them. The description is dropped from the table - it is
  ! fixed boilerplate text, identical on both sides, not physics data under test.
  function idn(name, idx) result(s)
    character(len=*), dimension(:), pointer, intent(in) :: name
    integer(ids_int), intent(in) :: idx
    character(:), allocatable :: s
    s = ss(name)//' ('//is(idx)//')'
  end function idn

  ! "n=<count>" when the array is associated, "(empty)" otherwise. `n` must already have
  ! been computed guarded by `has` at the call site - size() of a disassociated pointer is
  ! not something to evaluate even as a discarded argument.
  function cnt(has, n) result(s)
    logical, intent(in) :: has
    integer, intent(in) :: n
    character(:), allocatable :: s
    if (has) then
       s = 'n='//is(n)
    else
       s = EMPTY
    end if
  end function cnt

  ! --------------------------------------------------------- constraint 0D value strings
  ! ids_equilibrium_constraints_0D*_v4_1_1 all carry the same seven fields under distinct
  ! type names, so each needs its own function rather than one generic one.

  function zero_d_str(node) result(s)
    type(ids_equilibrium_constraints_0D_v4_1_1), intent(in) :: node
    character(:), allocatable :: s
    s = 'm='//rs(node%measured)//' r='//rs(node%reconstructed)//' chi2='//rs(node%chi_squared)
  end function zero_d_str

  function zero_d_ip_str(node) result(s)
    type(ids_equilibrium_constraints_0D_ip_like_v4_1_1), intent(in) :: node
    character(:), allocatable :: s
    s = 'm='//rs(node%measured)//' r='//rs(node%reconstructed)//' chi2='//rs(node%chi_squared)
  end function zero_d_ip_str

  function zero_d_b0_str(node) result(s)
    type(ids_equilibrium_constraints_0D_b0_like_v4_1_1), intent(in) :: node
    character(:), allocatable :: s
    s = 'm='//rs(node%measured)//' r='//rs(node%reconstructed)//' chi2='//rs(node%chi_squared)
  end function zero_d_b0_str

  function zero_d_one_str(node) result(s)
    type(ids_equilibrium_constraints_0D_one_like_v4_1_1), intent(in) :: node
    character(:), allocatable :: s
    s = 'm='//rs(node%measured)//' r='//rs(node%reconstructed)//' chi2='//rs(node%chi_squared)
  end function zero_d_one_str

  function zero_d_aos_str(arr) result(s)
    type(ids_equilibrium_constraints_0D_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] '//zero_d_str(arr(1))
    end if
  end function zero_d_aos_str

  function zero_d_ip_aos_str(arr) result(s)
    type(ids_equilibrium_constraints_0D_ip_like_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] '//zero_d_ip_str(arr(1))
    end if
  end function zero_d_ip_aos_str

  function zero_d_one_aos_str(arr) result(s)
    type(ids_equilibrium_constraints_0D_one_like_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] '//zero_d_one_str(arr(1))
    end if
  end function zero_d_one_aos_str

  function position_str(node) result(s)
    type(ids_equilibrium_constraints_0D_position_v4_1_1), intent(in) :: node
    character(:), allocatable :: s
    s = 'm='//rs(node%measured)//' r='//rs(node%reconstructed)//' chi2='//rs(node%chi_squared)// &
         ' pos(r,phi,z)=('//rs(node%position%r)//','//rs(node%position%phi)//','// &
         rs(node%position%z)//')'
  end function position_str

  function position_aos_str(arr) result(s)
    type(ids_equilibrium_constraints_0D_position_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] '//position_str(arr(1))
    end if
  end function position_aos_str

  function pure_position_str(node) result(s)
    type(ids_equilibrium_constraints_pure_position_v4_1_1), intent(in) :: node
    character(:), allocatable :: s
    s = 'meas(r,z)=('//rs(node%position_measured%r)//','//rs(node%position_measured%z)//')'// &
         ' recon(r,z)=('//rs(node%position_reconstructed%r)//','// &
         rs(node%position_reconstructed%z)//')'// &
         ' chi2(r,z)=('//rs(node%chi_squared_r)//','//rs(node%chi_squared_z)//')'
  end function pure_position_str

  function pure_position_aos_str(arr) result(s)
    type(ids_equilibrium_constraints_pure_position_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] '//pure_position_str(arr(1))
    end if
  end function pure_position_aos_str

  function magnetization_aos_str(arr) result(s)
    type(ids_equilibrium_constraints_magnetization_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] r:'//zero_d_str(arr(1)%magnetization_r)// &
            ' z:'//zero_d_str(arr(1)%magnetization_z)
    end if
  end function magnetization_aos_str

  function gap_aos_str(arr) result(s)
    type(ids_equilibrium_gap_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] '//ss(arr(1)%name)//': r='//rs(arr(1)%r)//' z='// &
            rs(arr(1)%z)//' angle='//rs(arr(1)%angle)//' value='//rs(arr(1)%value)
    end if
  end function gap_aos_str

  function contour_node_aos_str(arr) result(s)
    type(ids_equilibrium_contour_tree_node_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] type='//is(arr(1)%critical_type)//' r='//rs(arr(1)%r)// &
            ' z='//rs(arr(1)%z)//' psi='//rs(arr(1)%psi)
    end if
  end function contour_node_aos_str

  function grid_scalar_aos_str(arr) result(s)
    type(ids_generic_grid_scalar_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1].values='//ras(arr(1)%values)
    end if
  end function grid_scalar_aos_str

  function grid_dynamic_aos_str(arr) result(s)
    type(ids_generic_grid_dynamic_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    integer :: nspace, nsubset
    if (.not. associated(arr)) then
       s = EMPTY
       return
    end if
    nspace = 0
    if (associated(arr(1)%space)) nspace = size(arr(1)%space)
    nsubset = 0
    if (associated(arr(1)%grid_subset)) nsubset = size(arr(1)%grid_subset)
    s = 'n='//is(size(arr))//' [1] '//idn(arr(1)%identifier%name, arr(1)%identifier%index)// &
         ' space.n='//is(nspace)//' grid_subset.n='//is(nsubset)
  end function grid_dynamic_aos_str

  function library_aos_str(arr) result(s)
    type(ids_library_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
    else
       s = 'n='//is(size(arr))//' [1] '//ss(arr(1)%name)//' '//ss(arr(1)%version)
    end if
  end function library_aos_str

  function provenance_node_aos_str(arr) result(s)
    type(ids_ids_provenance_node_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
       return
    end if
    s = 'n='//is(size(arr))//' [1] path='//ss(arr(1)%path)
    if (associated(arr(1)%reference)) then
       s = s//' ref[1].name='//ss(arr(1)%reference(1)%name)
    end if
  end function provenance_node_aos_str

  function plugins_node_aos_str(arr) result(s)
    type(ids_ids_plugins_node_v4_1_1), dimension(:), pointer, intent(in) :: arr
    character(:), allocatable :: s
    if (.not. associated(arr)) then
       s = EMPTY
       return
    end if
    s = 'n='//is(size(arr))//' [1] path='//ss(arr(1)%path)
    if (associated(arr(1)%put_operation)) then
       s = s//' put_operation[1].name='//ss(arr(1)%put_operation(1)%name)
    end if
  end function plugins_node_aos_str

  ! -------------------------------------------------------------------------- sections

  subroutine dump_ids_properties(ip4, ip3)
    type(ids_ids_properties_v4_1_1), intent(in) :: ip4, ip3
    call row('ids_properties%comment', ss(ip4%comment), ss(ip3%comment))
    call row('ids_properties%name', ss(ip4%name), ss(ip3%name))
    call row('ids_properties%homogeneous_time', is(ip4%homogeneous_time), is(ip3%homogeneous_time))
    call row('ids_properties%occurrence_type', idn(ip4%occurrence_type%name, ip4%occurrence_type%index), &
         idn(ip3%occurrence_type%name, ip3%occurrence_type%index))
    call row('ids_properties%provider', ss(ip4%provider), ss(ip3%provider))
    call row('ids_properties%creation_date', ss(ip4%creation_date), ss(ip3%creation_date))
    call row('ids_properties%version_put%data_dictionary', ss(ip4%version_put%data_dictionary), &
         ss(ip3%version_put%data_dictionary))
    call row('ids_properties%version_put%access_layer', ss(ip4%version_put%access_layer), &
         ss(ip3%version_put%access_layer))
    call row('ids_properties%version_put%access_layer_language', &
         ss(ip4%version_put%access_layer_language), ss(ip3%version_put%access_layer_language))
    call row('ids_properties%provenance%node', provenance_node_aos_str(ip4%provenance%node), &
         provenance_node_aos_str(ip3%provenance%node))
    call row('ids_properties%plugins%node', plugins_node_aos_str(ip4%plugins%node), &
         plugins_node_aos_str(ip3%plugins%node))
    call row('ids_properties%plugins%infrastructure_put', ss(ip4%plugins%infrastructure_put%name), &
         ss(ip3%plugins%infrastructure_put%name))
    call row('ids_properties%plugins%infrastructure_get', ss(ip4%plugins%infrastructure_get%name), &
         ss(ip3%plugins%infrastructure_get%name))
  end subroutine dump_ids_properties

  subroutine dump_code(label, c4, c3)
    character(*), intent(in) :: label
    type(ids_code_v4_1_1), intent(in) :: c4, c3
    call row(trim(label)//'%name', ss(c4%name), ss(c3%name))
    call row(trim(label)//'%description', ss(c4%description), ss(c3%description))
    call row(trim(label)//'%version', ss(c4%version), ss(c3%version))
    call row(trim(label)//'%repository', ss(c4%repository), ss(c3%repository))
    call row(trim(label)//'%output_flag', ia1s(c4%output_flag), ia1s(c3%output_flag))
    call row(trim(label)//'%library', library_aos_str(c4%library), library_aos_str(c3%library))
  end subroutine dump_code

  subroutine dump_grids_ggd(gg4, gg3)
    type(ids_equilibrium_ggd_array_v4_1_1), dimension(:), pointer, intent(in) :: gg4, gg3
    logical :: has4, has3
    integer :: n4, n3
    has4 = associated(gg4); has3 = associated(gg3)
    n4 = 0; if (has4) n4 = size(gg4)
    n3 = 0; if (has3) n3 = size(gg3)
    call row('grids_ggd', cnt(has4, n4), cnt(has3, n3))
    if (has4 .and. has3) then
       call row('grids_ggd(1)%time', rs(gg4(1)%time), rs(gg3(1)%time))
       call row('grids_ggd(1)%grid', grid_dynamic_aos_str(gg4(1)%grid), grid_dynamic_aos_str(gg3(1)%grid))
    end if
  end subroutine dump_grids_ggd

  subroutine dump_boundary(b4, b3)
    type(ids_equilibrium_boundary_v4_1_1), intent(in) :: b4, b3
    call row('boundary%type', is(b4%type), is(b3%type))
    call row('boundary%outline%r', ras(b4%outline%r), ras(b3%outline%r))
    call row('boundary%outline%z', ras(b4%outline%z), ras(b3%outline%z))
    call row('boundary%psi_norm', rs(b4%psi_norm), rs(b3%psi_norm))
    call row('boundary%psi', rs(b4%psi), rs(b3%psi))
    call row('boundary%geometric_axis%r', rs(b4%geometric_axis%r), rs(b3%geometric_axis%r))
    call row('boundary%geometric_axis%z', rs(b4%geometric_axis%z), rs(b3%geometric_axis%z))
    call row('boundary%minor_radius', rs(b4%minor_radius), rs(b3%minor_radius))
    call row('boundary%elongation', rs(b4%elongation), rs(b3%elongation))
    call row('boundary%triangularity', rs(b4%triangularity), rs(b3%triangularity))
    call row('boundary%triangularity_upper', rs(b4%triangularity_upper), rs(b3%triangularity_upper))
    call row('boundary%triangularity_lower', rs(b4%triangularity_lower), rs(b3%triangularity_lower))
    call row('boundary%squareness_upper_inner', rs(b4%squareness_upper_inner), rs(b3%squareness_upper_inner))
    call row('boundary%squareness_upper_outer', rs(b4%squareness_upper_outer), rs(b3%squareness_upper_outer))
    call row('boundary%squareness_lower_inner', rs(b4%squareness_lower_inner), rs(b3%squareness_lower_inner))
    call row('boundary%squareness_lower_outer', rs(b4%squareness_lower_outer), rs(b3%squareness_lower_outer))
    call row('boundary%closest_wall_point%r', rs(b4%closest_wall_point%r), rs(b3%closest_wall_point%r))
    call row('boundary%closest_wall_point%z', rs(b4%closest_wall_point%z), rs(b3%closest_wall_point%z))
    call row('boundary%closest_wall_point%distance', rs(b4%closest_wall_point%distance), &
         rs(b3%closest_wall_point%distance))
    call row('boundary%dr_dz_zero_point%r', rs(b4%dr_dz_zero_point%r), rs(b3%dr_dz_zero_point%r))
    call row('boundary%dr_dz_zero_point%z', rs(b4%dr_dz_zero_point%z), rs(b3%dr_dz_zero_point%z))
    call row('boundary%gap', gap_aos_str(b4%gap), gap_aos_str(b3%gap))
    call row('boundary%rho_tor', rs(b4%rho_tor), rs(b3%rho_tor))
    call row('boundary%phi', rs(b4%phi), rs(b3%phi))
    call row('boundary%phi_poloidal_current', rs(b4%phi_poloidal_current), rs(b3%phi_poloidal_current))
  end subroutine dump_boundary

  subroutine dump_contour_tree(ct4, ct3)
    type(ids_equilibrium_contour_tree_v4_1_1), intent(in) :: ct4, ct3
    call row('contour_tree%node', contour_node_aos_str(ct4%node), contour_node_aos_str(ct3%node))
    call row('contour_tree%edges', ia2shape(ct4%edges), ia2shape(ct3%edges))
  end subroutine dump_contour_tree

  subroutine dump_constraints(c4, c3)
    type(ids_equilibrium_constraints_v4_1_1), intent(in) :: c4, c3
    call row('constraints%b_field_tor_vacuum_r', zero_d_str(c4%b_field_tor_vacuum_r), &
         zero_d_str(c3%b_field_tor_vacuum_r))
    call row('constraints%ip', zero_d_ip_str(c4%ip), zero_d_ip_str(c3%ip))
    call row('constraints%diamagnetic_flux', zero_d_b0_str(c4%diamagnetic_flux), &
         zero_d_b0_str(c3%diamagnetic_flux))
    call row('constraints%b_field_pol_probe', zero_d_one_aos_str(c4%b_field_pol_probe), &
         zero_d_one_aos_str(c3%b_field_pol_probe))
    call row('constraints%faraday_angle', zero_d_aos_str(c4%faraday_angle), &
         zero_d_aos_str(c3%faraday_angle))
    call row('constraints%mse_polarization_angle', zero_d_aos_str(c4%mse_polarization_angle), &
         zero_d_aos_str(c3%mse_polarization_angle))
    call row('constraints%flux_loop', zero_d_aos_str(c4%flux_loop), zero_d_aos_str(c3%flux_loop))
    call row('constraints%n_e_line', zero_d_aos_str(c4%n_e_line), zero_d_aos_str(c3%n_e_line))
    call row('constraints%pf_current', zero_d_ip_aos_str(c4%pf_current), &
         zero_d_ip_aos_str(c3%pf_current))
    call row('constraints%pf_passive_current', zero_d_aos_str(c4%pf_passive_current), &
         zero_d_aos_str(c3%pf_passive_current))
    call row('constraints%n_e', position_aos_str(c4%n_e), position_aos_str(c3%n_e))
    call row('constraints%pressure', position_aos_str(c4%pressure), position_aos_str(c3%pressure))
    call row('constraints%pressure_rotational', position_aos_str(c4%pressure_rotational), &
         position_aos_str(c3%pressure_rotational))
    call row('constraints%q', position_aos_str(c4%q), position_aos_str(c3%q))
    call row('constraints%j_phi', position_aos_str(c4%j_phi), position_aos_str(c3%j_phi))
    call row('constraints%j_parallel', position_aos_str(c4%j_parallel), position_aos_str(c3%j_parallel))
    call row('constraints%iron_core_segment', magnetization_aos_str(c4%iron_core_segment), &
         magnetization_aos_str(c3%iron_core_segment))
    call row('constraints%x_point', pure_position_aos_str(c4%x_point), pure_position_aos_str(c3%x_point))
    call row('constraints%strike_point', pure_position_aos_str(c4%strike_point), &
         pure_position_aos_str(c3%strike_point))
    call row('constraints%chi_squared_reduced', rs(c4%chi_squared_reduced), rs(c3%chi_squared_reduced))
    call row('constraints%freedom_degrees_n', is(c4%freedom_degrees_n), is(c3%freedom_degrees_n))
    call row('constraints%constraints_n', is(c4%constraints_n), is(c3%constraints_n))
  end subroutine dump_constraints

  subroutine dump_global_quantities(g4, g3)
    type(ids_equlibrium_global_quantities_v4_1_1), intent(in) :: g4, g3
    call row('global_quantities%beta_pol', rs(g4%beta_pol), rs(g3%beta_pol))
    call row('global_quantities%beta_tor', rs(g4%beta_tor), rs(g3%beta_tor))
    call row('global_quantities%beta_tor_norm', rs(g4%beta_tor_norm), rs(g3%beta_tor_norm))
    call row('global_quantities%ip', rs(g4%ip), rs(g3%ip))
    call row('global_quantities%li_3', rs(g4%li_3), rs(g3%li_3))
    call row('global_quantities%volume', rs(g4%volume), rs(g3%volume))
    call row('global_quantities%area', rs(g4%area), rs(g3%area))
    call row('global_quantities%surface', rs(g4%surface), rs(g3%surface))
    call row('global_quantities%length_pol', rs(g4%length_pol), rs(g3%length_pol))
    call row('global_quantities%psi_axis', rs(g4%psi_axis), rs(g3%psi_axis))
    call row('global_quantities%psi_magnetic_axis', rs(g4%psi_magnetic_axis), rs(g3%psi_magnetic_axis))
    call row('global_quantities%psi_boundary', rs(g4%psi_boundary), rs(g3%psi_boundary))
    call row('global_quantities%rho_tor_boundary', rs(g4%rho_tor_boundary), rs(g3%rho_tor_boundary))
    call row('global_quantities%magnetic_axis%r', rs(g4%magnetic_axis%r), rs(g3%magnetic_axis%r))
    call row('global_quantities%magnetic_axis%z', rs(g4%magnetic_axis%z), rs(g3%magnetic_axis%z))
    call row('global_quantities%magnetic_axis%b_field_phi', rs(g4%magnetic_axis%b_field_phi), &
         rs(g3%magnetic_axis%b_field_phi))
    call row('global_quantities%current_centre%r', rs(g4%current_centre%r), rs(g3%current_centre%r))
    call row('global_quantities%current_centre%z', rs(g4%current_centre%z), rs(g3%current_centre%z))
    call row('global_quantities%current_centre%velocity_z', rs(g4%current_centre%velocity_z), &
         rs(g3%current_centre%velocity_z))
    call row('global_quantities%q_axis', rs(g4%q_axis), rs(g3%q_axis))
    call row('global_quantities%q_95', rs(g4%q_95), rs(g3%q_95))
    call row('global_quantities%q_min%value', rs(g4%q_min%value), rs(g3%q_min%value))
    call row('global_quantities%q_min%rho_tor_norm', rs(g4%q_min%rho_tor_norm), rs(g3%q_min%rho_tor_norm))
    call row('global_quantities%q_min%psi_norm', rs(g4%q_min%psi_norm), rs(g3%q_min%psi_norm))
    call row('global_quantities%q_min%psi', rs(g4%q_min%psi), rs(g3%q_min%psi))
    call row('global_quantities%energy_mhd', rs(g4%energy_mhd), rs(g3%energy_mhd))
    call row('global_quantities%psi_external_average', rs(g4%psi_external_average), rs(g3%psi_external_average))
    call row('global_quantities%v_external', rs(g4%v_external), rs(g3%v_external))
    call row('global_quantities%plasma_inductance', rs(g4%plasma_inductance), rs(g3%plasma_inductance))
    call row('global_quantities%plasma_resistance', rs(g4%plasma_resistance), rs(g3%plasma_resistance))
  end subroutine dump_global_quantities

  subroutine dump_profiles_1d(p4, p3)
    type(ids_equilibrium_profiles_1d_v4_1_1), intent(in) :: p4, p3
    call row('profiles_1d%psi', ras(p4%psi), ras(p3%psi))
    call row('profiles_1d%psi_norm', ras(p4%psi_norm), ras(p3%psi_norm))
    call row('profiles_1d%phi', ras(p4%phi), ras(p3%phi))
    call row('profiles_1d%pressure', ras(p4%pressure), ras(p3%pressure))
    call row('profiles_1d%f', ras(p4%f), ras(p3%f))
    call row('profiles_1d%dpressure_dpsi', ras(p4%dpressure_dpsi), ras(p3%dpressure_dpsi))
    call row('profiles_1d%f_df_dpsi', ras(p4%f_df_dpsi), ras(p3%f_df_dpsi))
    call row('profiles_1d%j_phi', ras(p4%j_phi), ras(p3%j_phi))
    call row('profiles_1d%j_parallel', ras(p4%j_parallel), ras(p3%j_parallel))
    call row('profiles_1d%q', ras(p4%q), ras(p3%q))
    call row('profiles_1d%magnetic_shear', ras(p4%magnetic_shear), ras(p3%magnetic_shear))
    call row('profiles_1d%r_inboard', ras(p4%r_inboard), ras(p3%r_inboard))
    call row('profiles_1d%r_outboard', ras(p4%r_outboard), ras(p3%r_outboard))
    call row('profiles_1d%rho_tor', ras(p4%rho_tor), ras(p3%rho_tor))
    call row('profiles_1d%rho_tor_norm', ras(p4%rho_tor_norm), ras(p3%rho_tor_norm))
    call row('profiles_1d%dpsi_drho_tor', ras(p4%dpsi_drho_tor), ras(p3%dpsi_drho_tor))
    call row('profiles_1d%geometric_axis%r', ras(p4%geometric_axis%r), ras(p3%geometric_axis%r))
    call row('profiles_1d%geometric_axis%z', ras(p4%geometric_axis%z), ras(p3%geometric_axis%z))
    call row('profiles_1d%elongation', ras(p4%elongation), ras(p3%elongation))
    call row('profiles_1d%triangularity_upper', ras(p4%triangularity_upper), ras(p3%triangularity_upper))
    call row('profiles_1d%triangularity_lower', ras(p4%triangularity_lower), ras(p3%triangularity_lower))
    call row('profiles_1d%squareness_upper_inner', ras(p4%squareness_upper_inner), &
         ras(p3%squareness_upper_inner))
    call row('profiles_1d%squareness_upper_outer', ras(p4%squareness_upper_outer), &
         ras(p3%squareness_upper_outer))
    call row('profiles_1d%squareness_lower_inner', ras(p4%squareness_lower_inner), &
         ras(p3%squareness_lower_inner))
    call row('profiles_1d%squareness_lower_outer', ras(p4%squareness_lower_outer), &
         ras(p3%squareness_lower_outer))
    call row('profiles_1d%volume', ras(p4%volume), ras(p3%volume))
    call row('profiles_1d%rho_volume_norm', ras(p4%rho_volume_norm), ras(p3%rho_volume_norm))
    call row('profiles_1d%dvolume_dpsi', ras(p4%dvolume_dpsi), ras(p3%dvolume_dpsi))
    call row('profiles_1d%dvolume_drho_tor', ras(p4%dvolume_drho_tor), ras(p3%dvolume_drho_tor))
    call row('profiles_1d%area', ras(p4%area), ras(p3%area))
    call row('profiles_1d%darea_dpsi', ras(p4%darea_dpsi), ras(p3%darea_dpsi))
    call row('profiles_1d%darea_drho_tor', ras(p4%darea_drho_tor), ras(p3%darea_drho_tor))
    call row('profiles_1d%surface', ras(p4%surface), ras(p3%surface))
    call row('profiles_1d%trapped_fraction', ras(p4%trapped_fraction), ras(p3%trapped_fraction))
    call row('profiles_1d%gm1', ras(p4%gm1), ras(p3%gm1))
    call row('profiles_1d%gm2', ras(p4%gm2), ras(p3%gm2))
    call row('profiles_1d%gm3', ras(p4%gm3), ras(p3%gm3))
    call row('profiles_1d%gm4', ras(p4%gm4), ras(p3%gm4))
    call row('profiles_1d%gm5', ras(p4%gm5), ras(p3%gm5))
    call row('profiles_1d%gm6', ras(p4%gm6), ras(p3%gm6))
    call row('profiles_1d%gm7', ras(p4%gm7), ras(p3%gm7))
    call row('profiles_1d%gm8', ras(p4%gm8), ras(p3%gm8))
    call row('profiles_1d%gm9', ras(p4%gm9), ras(p3%gm9))
    call row('profiles_1d%b_field_average', ras(p4%b_field_average), ras(p3%b_field_average))
    call row('profiles_1d%b_field_min', ras(p4%b_field_min), ras(p3%b_field_min))
    call row('profiles_1d%b_field_max', ras(p4%b_field_max), ras(p3%b_field_max))
    call row('profiles_1d%beta_pol', ras(p4%beta_pol), ras(p3%beta_pol))
    call row('profiles_1d%mass_density', ras(p4%mass_density), ras(p3%mass_density))
  end subroutine dump_profiles_1d

  subroutine dump_profiles_2d(p4, p3)
    type(ids_equilibrium_profiles_2d_v4_1_1), intent(in) :: p4, p3
    call row('profiles_2d%type', idn(p4%type%name, p4%type%index), idn(p3%type%name, p3%type%index))
    call row('profiles_2d%grid_type', idn(p4%grid_type%name, p4%grid_type%index), &
         idn(p3%grid_type%name, p3%grid_type%index))
    call row('profiles_2d%grid%dim1', ras(p4%grid%dim1), ras(p3%grid%dim1))
    call row('profiles_2d%grid%dim2', ras(p4%grid%dim2), ras(p3%grid%dim2))
    call row('profiles_2d%grid%volume_element', ra2s(p4%grid%volume_element), ra2s(p3%grid%volume_element))
    call row('profiles_2d%r', ra2s(p4%r), ra2s(p3%r))
    call row('profiles_2d%z', ra2s(p4%z), ra2s(p3%z))
    call row('profiles_2d%psi', ra2s(p4%psi), ra2s(p3%psi))
    call row('profiles_2d%theta', ra2s(p4%theta), ra2s(p3%theta))
    call row('profiles_2d%phi', ra2s(p4%phi), ra2s(p3%phi))
    call row('profiles_2d%j_phi', ra2s(p4%j_phi), ra2s(p3%j_phi))
    call row('profiles_2d%j_parallel', ra2s(p4%j_parallel), ra2s(p3%j_parallel))
    call row('profiles_2d%b_field_r', ra2s(p4%b_field_r), ra2s(p3%b_field_r))
    call row('profiles_2d%b_field_phi', ra2s(p4%b_field_phi), ra2s(p3%b_field_phi))
    call row('profiles_2d%b_field_z', ra2s(p4%b_field_z), ra2s(p3%b_field_z))
  end subroutine dump_profiles_2d

  subroutine dump_ggd(gg4, gg3)
    type(ids_equilibrium_ggd_v4_1_1), dimension(:), pointer, intent(in) :: gg4, gg3
    logical :: has4, has3
    integer :: n4, n3
    has4 = associated(gg4); has3 = associated(gg3)
    n4 = 0; if (has4) n4 = size(gg4)
    n3 = 0; if (has3) n3 = size(gg3)
    call row('ggd', cnt(has4, n4), cnt(has3, n3))
    if (.not. (has4 .and. has3)) return
    call row('ggd(1)%r', grid_scalar_aos_str(gg4(1)%r), grid_scalar_aos_str(gg3(1)%r))
    call row('ggd(1)%z', grid_scalar_aos_str(gg4(1)%z), grid_scalar_aos_str(gg3(1)%z))
    call row('ggd(1)%psi', grid_scalar_aos_str(gg4(1)%psi), grid_scalar_aos_str(gg3(1)%psi))
    call row('ggd(1)%phi', grid_scalar_aos_str(gg4(1)%phi), grid_scalar_aos_str(gg3(1)%phi))
    call row('ggd(1)%theta', grid_scalar_aos_str(gg4(1)%theta), grid_scalar_aos_str(gg3(1)%theta))
    call row('ggd(1)%j_phi', grid_scalar_aos_str(gg4(1)%j_phi), grid_scalar_aos_str(gg3(1)%j_phi))
    call row('ggd(1)%j_parallel', grid_scalar_aos_str(gg4(1)%j_parallel), &
         grid_scalar_aos_str(gg3(1)%j_parallel))
    call row('ggd(1)%b_field_r', grid_scalar_aos_str(gg4(1)%b_field_r), &
         grid_scalar_aos_str(gg3(1)%b_field_r))
    call row('ggd(1)%b_field_z', grid_scalar_aos_str(gg4(1)%b_field_z), &
         grid_scalar_aos_str(gg3(1)%b_field_z))
    call row('ggd(1)%b_field_phi', grid_scalar_aos_str(gg4(1)%b_field_phi), &
         grid_scalar_aos_str(gg3(1)%b_field_phi))
  end subroutine dump_ggd

  subroutine dump_coordinate_system(cs4, cs3)
    type(ids_equilibrium_coordinate_system_v4_1_1), intent(in) :: cs4, cs3
    call row('coordinate_system%grid_type', idn(cs4%grid_type%name, cs4%grid_type%index), &
         idn(cs3%grid_type%name, cs3%grid_type%index))
    call row('coordinate_system%grid%dim1', ras(cs4%grid%dim1), ras(cs3%grid%dim1))
    call row('coordinate_system%grid%dim2', ras(cs4%grid%dim2), ras(cs3%grid%dim2))
    call row('coordinate_system%grid%volume_element', ra2s(cs4%grid%volume_element), &
         ra2s(cs3%grid%volume_element))
    call row('coordinate_system%r', ra2s(cs4%r), ra2s(cs3%r))
    call row('coordinate_system%z', ra2s(cs4%z), ra2s(cs3%z))
    call row('coordinate_system%jacobian', ra2s(cs4%jacobian), ra2s(cs3%jacobian))
    call row('coordinate_system%tensor_covariant', ra4shape(cs4%tensor_covariant), &
         ra4shape(cs3%tensor_covariant))
    call row('coordinate_system%tensor_contravariant', ra4shape(cs4%tensor_contravariant), &
         ra4shape(cs3%tensor_contravariant))
  end subroutine dump_coordinate_system

  subroutine dump_convergence(cv4, cv3)
    type(ids_equilibrium_convergence_v4_1_1), intent(in) :: cv4, cv3
    call row('convergence%iterations_n', is(cv4%iterations_n), is(cv3%iterations_n))
    call row('convergence%grad_shafranov_deviation_expression', &
         idn(cv4%grad_shafranov_deviation_expression%name, &
         cv4%grad_shafranov_deviation_expression%index), &
         idn(cv3%grad_shafranov_deviation_expression%name, &
         cv3%grad_shafranov_deviation_expression%index))
    call row('convergence%grad_shafranov_deviation_value', rs(cv4%grad_shafranov_deviation_value), &
         rs(cv3%grad_shafranov_deviation_value))
    call row('convergence%result', idn(cv4%result%name, cv4%result%index), &
         idn(cv3%result%name, cv3%result%index))
  end subroutine dump_convergence

  ! ------------------------------------------------------------------------- the table

  subroutine dump_pair(eq4, eq3)
    type(ids_equilibrium), intent(in) :: eq4, eq3
    integer :: i, n4, n3, n
    logical :: has4, has3

    call section('ids_properties')
    call dump_ids_properties(eq4%ids_properties, eq3%ids_properties)

    call section('vacuum_toroidal_field / time')
    call row('vacuum_toroidal_field%r0', rs(eq4%vacuum_toroidal_field%r0), &
         rs(eq3%vacuum_toroidal_field%r0))
    call row('vacuum_toroidal_field%b0', ras(eq4%vacuum_toroidal_field%b0), &
         ras(eq3%vacuum_toroidal_field%b0))
    call row('time', ras(eq4%time), ras(eq3%time))

    call section('grids_ggd')
    call dump_grids_ggd(eq4%grids_ggd, eq3%grids_ggd)

    call section('code')
    call dump_code('code', eq4%code, eq3%code)

    has4 = associated(eq4%time_slice); has3 = associated(eq3%time_slice)
    n4 = 0; if (has4) n4 = size(eq4%time_slice)
    n3 = 0; if (has3) n3 = size(eq3%time_slice)
    n = min(n4, n3)
    if (n4 /= n3) then
       call section('time_slice')
       call row('time_slice count MISMATCH', cnt(has4, n4), cnt(has3, n3))
    end if

    in_time_slice = .true.
    do i = 1, n
       call section('time_slice('//is(i)//')')
       call row('time', rs(eq4%time_slice(i)%time), rs(eq3%time_slice(i)%time))
       call dump_boundary(eq4%time_slice(i)%boundary, eq3%time_slice(i)%boundary)
       call dump_contour_tree(eq4%time_slice(i)%contour_tree, eq3%time_slice(i)%contour_tree)
       call dump_constraints(eq4%time_slice(i)%constraints, eq3%time_slice(i)%constraints)
       call dump_global_quantities(eq4%time_slice(i)%global_quantities, &
            eq3%time_slice(i)%global_quantities)
       call dump_profiles_1d(eq4%time_slice(i)%profiles_1d, eq3%time_slice(i)%profiles_1d)

       block
         logical :: p4has, p3has
         integer :: p4n, p3n
         p4has = associated(eq4%time_slice(i)%profiles_2d)
         p3has = associated(eq3%time_slice(i)%profiles_2d)
         p4n = 0; if (p4has) p4n = size(eq4%time_slice(i)%profiles_2d)
         p3n = 0; if (p3has) p3n = size(eq3%time_slice(i)%profiles_2d)
         call row('profiles_2d', cnt(p4has, p4n), cnt(p3has, p3n))
         if (p4has .and. p3has) &
              call dump_profiles_2d(eq4%time_slice(i)%profiles_2d(1), eq3%time_slice(i)%profiles_2d(1))
       end block

       call dump_ggd(eq4%time_slice(i)%ggd, eq3%time_slice(i)%ggd)
       call dump_coordinate_system(eq4%time_slice(i)%coordinate_system, &
            eq3%time_slice(i)%coordinate_system)
       call dump_convergence(eq4%time_slice(i)%convergence, eq3%time_slice(i)%convergence)
    end do
    in_time_slice = .false.
  end subroutine dump_pair

end program play_equilibrium
