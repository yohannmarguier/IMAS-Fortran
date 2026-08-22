! Reads both equilibrium fixtures through the multiversion shim and prints,
! path by path, every leaf attribute of the equilibrium IDS (DD 4.1.1) --
! column 1 is the DD 4.1.1 pulse read straight, column 2 is the DD 3.39.0
! pulse converted on the way in. A verdict column classifies the relationship
! between the two columns for that row, and the whole line is colored by
! verdict so a real difference stands out without reading every value:
!
!   same    white    both columns agree
!   FLIP    yellow   equal up to sign -- a COCOS 11 -> 17 flip
!   DIFF    red      both present, and they disagree
!   SHAPE   magenta  both present, different extents
!   only4   cyan     4.1.1 has it, the 3.39.0 read produced nothing
!   only3   blue     the 3.39.0 read produced it, 4.1.1 has nothing
!   --      gray     neither side has it
!
! For arrays, the verdict is computed over the whole array; only element (1)
! is printed as a sample.
!
! Colors are unconditional ANSI escapes (no isatty check -- that intrinsic
! isn't portable to the NAG build), so redirect through `less -R` or `cat -v`
! rather than a plain pager if piping this to a file.
!
! This program is compiled against ONE data dictionary: the DD 4.1.1 al-fortran
! in ../install-shim. Both pulses are therefore read into the same DD 4.1.1
! derived type. The 4.1.1 pulse passes through the shim untouched; the 3.39.0
! pulse is a different dictionary, so the shim converts it on the way in --
! translating the paths al_read_data asks for, applying the COCOS 11 -> 17 sign
! flips, and refusing the paths its map declares unservable.
!
! Scope decisions:
!  - error-bar companions (_error_upper/_error_lower) are included: "all
!    fields" means all fields, not just the ones anyone actually populates.
!  - arrays of structures print element (1) only, not every element -- this
!    dump exists to compare which fields the shim populates, not to audit
!    fixture data volume.
!  - the generic-grid mesh topology under grids_ggd(1)/grid(1)/{space,
!    grid_subset} is reported as association + size only. Recursing into it
!    means describing an open-ended mesh format that has nothing to do with
!    equilibrium physics or the shim's conversion map (the one leaf the shim
!    refuses there, coordinates_type, is already why this program used to stop
!    dead before time_slice existed -- see git history / FINDINGS.md).
!  - ids_properties/provenance and ids_properties/plugins are Access-Layer
!    bookkeeping filled by the AL itself, not by an equilibrium code; only
!    association + size (+ node(1)/path for provenance) is reported.
!
! A field unset on both sides prints '-' or '(not provided)' with a gray '--'
! verdict; a field unset on only one side prints the same placeholder text but
! gets 'only4'/'only3' instead -- the verdict column, not the placeholder
! text, is what tells the two cases apart.

module eq_table
  use ids_routines
  implicit none

  integer, parameter :: PW = 56                          ! path column width
  integer, parameter :: SW = 40                           ! string sample width
  real(ids_real), parameter :: TOL = 1.0e-9_ids_real

  character(len=*), parameter :: ESC     = achar(27)
  character(len=*), parameter :: C_RESET = ESC//'[0m'
  character(len=*), parameter :: C_SAME  = ESC//'[97m'   ! white   -- same
  character(len=*), parameter :: C_FLIP  = ESC//'[33m'   ! yellow  -- FLIP
  character(len=*), parameter :: C_DIFF  = ESC//'[31m'   ! red     -- DIFF
  character(len=*), parameter :: C_SHAPE = ESC//'[35m'   ! magenta -- SHAPE
  character(len=*), parameter :: C_ONLY4 = ESC//'[36m'   ! cyan    -- only4
  character(len=*), parameter :: C_ONLY3 = ESC//'[34m'   ! blue    -- only3
  character(len=*), parameter :: C_NONE  = ESC//'[90m'   ! gray    -- --

  interface row_struct_ptr
    module procedure row_struct_ptr_provenance, row_struct_ptr_plugins
  end interface

contains

  logical function unset_d(x)
    real(ids_real), intent(in) :: x
    unset_d = (x <= -1.0e40_ids_real) .or. (x /= x)
  end function

  logical function near(a, b)
    real(ids_real), intent(in) :: a, b
    near = abs(a - b) <= TOL * max(1.0_ids_real, abs(a), abs(b))
  end function

  logical function all_near(a, b)
    real(ids_real), intent(in) :: a(:), b(:)
    integer :: i
    all_near = .false.
    if (size(a) /= size(b)) return
    do i = 1, size(a)
      if (.not. near(a(i), b(i))) return
    end do
    all_near = .true.
  end function

  subroutine cmp_flat(a, b, same, flip)
    real(ids_real), intent(in) :: a(:), b(:)
    logical, intent(out) :: same, flip
    same = all_near(a, b)
    flip = .false.
    if (.not. same) flip = all_near(a, -b)
  end subroutine

  ! The one place a verdict's color is decided, so every row type agrees.
  subroutine paint(path, col1, col2, verdict)
    character(len=*), intent(in) :: path, col1, col2, verdict
    character(len=9) :: color
    select case (trim(verdict))
    case ('same');  color = C_SAME
    case ('FLIP');  color = C_FLIP
    case ('DIFF');  color = C_DIFF
    case ('SHAPE'); color = C_SHAPE
    case ('only4'); color = C_ONLY4
    case ('only3'); color = C_ONLY3
    case default;   color = C_NONE   ! '--'
    end select
    write(*, '(a,a,2x,a,2x,a,2x,a,a)') trim(color), pad(path), col1, col2, verdict, C_RESET
  end subroutine

  function verdict_d(a, b) result(v)
    real(ids_real), intent(in) :: a, b
    character(len=6) :: v
    logical :: pa, pb
    pa = .not. unset_d(a); pb = .not. unset_d(b)
    if (.not. pa .and. .not. pb) then
      v = '--'
    else if (.not. pb) then
      v = 'only4'
    else if (.not. pa) then
      v = 'only3'
    else if (near(a, b)) then
      v = 'same'
    else if (near(a, -b)) then
      v = 'FLIP'
    else
      v = 'DIFF'
    end if
  end function

  function verdict_i(a, b) result(v)
    integer(ids_int), intent(in) :: a, b
    character(len=6) :: v
    logical :: pa, pb
    pa = (a /= ids_int_invalid); pb = (b /= ids_int_invalid)
    if (.not. pa .and. .not. pb) then
      v = '--'
    else if (.not. pb) then
      v = 'only4'
    else if (.not. pa) then
      v = 'only3'
    else if (a == b) then
      v = 'same'
    else
      v = 'DIFF'
    end if
  end function

  function pad(s) result(p)
    character(len=*), intent(in) :: s
    character(len=PW) :: p
    p = s
  end function

  function pads(s) result(p)
    character(len=*), intent(in) :: s
    character(len=SW) :: p
    p = s
  end function

  function num_d(x) result(s)
    real(ids_real), intent(in) :: x
    character(len=15) :: s
    if (unset_d(x)) then
      s = '              -'
    else
      write(s, '(es15.6)') x
    end if
  end function

  function num_i(x) result(s)
    integer(ids_int), intent(in) :: x
    character(len=15) :: s
    if (x == ids_int_invalid) then
      s = '              -'
    else
      write(s, '(i15)') x
    end if
  end function

  subroutine sect(title)
    character(len=*), intent(in) :: title
    write(*, '(a)') ''
    write(*, '(a)') '-- '//trim(title)//' '// &
                    repeat('-', max(1, 100 - 4 - len_trim(title)))
  end subroutine

  function dd_stamp(ids) result(s)
    type(ids_equilibrium), intent(in) :: ids
    character(len=32) :: s
    s = '(no version_put stamp)'
    if (associated(ids%ids_properties%version_put%data_dictionary)) then
      if (size(ids%ids_properties%version_put%data_dictionary) > 0) &
        s = ids%ids_properties%version_put%data_dictionary(1)
    end if
  end function

  ! ------------------------------------------------------------------ rows

  subroutine row_d(path, a, b)
    character(len=*), intent(in) :: path
    real(ids_real), intent(in) :: a, b
    call paint(path, num_d(a), num_d(b), verdict_d(a, b))
  end subroutine

  subroutine row_i(path, a, b)
    character(len=*), intent(in) :: path
    integer(ids_int), intent(in) :: a, b
    call paint(path, num_i(a), num_i(b), verdict_i(a, b))
  end subroutine

  subroutine row_d1(path, a, b)
    character(len=*), intent(in) :: path
    real(ids_real), pointer, intent(in) :: a(:), b(:)
    real(ids_real) :: s4, s3
    character(len=16) :: tag
    logical :: ha, hb, same, flip
    character(len=6) :: v
    s4 = -9.0e40_ids_real; s3 = -9.0e40_ids_real
    tag = ''
    ha = associated(a); hb = associated(b)
    if (ha) then
      write(tag, '(a,i0,a)') '[', size(a), ']'
      if (size(a) > 0) s4 = a(1)
    end if
    if (hb) then
      if (size(b) > 0) s3 = b(1)
    end if
    if (.not. ha .and. .not. hb) then
      v = '--'
    else if (.not. hb) then
      v = 'only4'
    else if (.not. ha) then
      v = 'only3'
    else if (size(a) /= size(b)) then
      v = 'SHAPE'
    else
      call cmp_flat(a, b, same, flip)
      if (same) then
        v = 'same'
      else if (flip) then
        v = 'FLIP'
      else
        v = 'DIFF'
      end if
    end if
    call paint(trim(path)//trim(tag), num_d(s4), num_d(s3), v)
  end subroutine

  subroutine row_i1(path, a, b)
    character(len=*), intent(in) :: path
    integer(ids_int), pointer, intent(in) :: a(:), b(:)
    integer(ids_int) :: s4, s3
    character(len=16) :: tag
    logical :: ha, hb
    character(len=6) :: v
    s4 = ids_int_invalid; s3 = ids_int_invalid
    tag = ''
    ha = associated(a); hb = associated(b)
    if (ha) then
      write(tag, '(a,i0,a)') '[', size(a), ']'
      if (size(a) > 0) s4 = a(1)
    end if
    if (hb) then
      if (size(b) > 0) s3 = b(1)
    end if
    if (.not. ha .and. .not. hb) then
      v = '--'
    else if (.not. hb) then
      v = 'only4'
    else if (.not. ha) then
      v = 'only3'
    else if (size(a) /= size(b)) then
      v = 'SHAPE'
    else if (all(a == b)) then
      v = 'same'
    else
      v = 'DIFF'
    end if
    call paint(trim(path)//trim(tag), num_i(s4), num_i(s3), v)
  end subroutine

  subroutine row_d2(path, a, b)
    character(len=*), intent(in) :: path
    real(ids_real), pointer, intent(in) :: a(:,:), b(:,:)
    real(ids_real) :: s4, s3
    character(len=20) :: tag
    logical :: ha, hb, same, flip
    character(len=6) :: v
    s4 = -9.0e40_ids_real; s3 = -9.0e40_ids_real
    tag = ''
    ha = associated(a); hb = associated(b)
    if (ha) then
      write(tag, '(a,i0,a,i0,a)') '[', size(a,1), 'x', size(a,2), ']'
      if (size(a) > 0) s4 = a(1,1)
    end if
    if (hb) then
      if (size(b) > 0) s3 = b(1,1)
    end if
    if (.not. ha .and. .not. hb) then
      v = '--'
    else if (.not. hb) then
      v = 'only4'
    else if (.not. ha) then
      v = 'only3'
    else if (.not. all(shape(a) == shape(b))) then
      v = 'SHAPE'
    else
      call cmp_flat(reshape(a, [size(a)]), reshape(b, [size(b)]), same, flip)
      if (same) then
        v = 'same'
      else if (flip) then
        v = 'FLIP'
      else
        v = 'DIFF'
      end if
    end if
    call paint(trim(path)//trim(tag), num_d(s4), num_d(s3), v)
  end subroutine

  subroutine row_d4(path, a, b)
    character(len=*), intent(in) :: path
    real(ids_real), pointer, intent(in) :: a(:,:,:,:), b(:,:,:,:)
    real(ids_real) :: s4, s3
    character(len=20) :: tag
    logical :: ha, hb, same, flip
    character(len=6) :: v
    s4 = -9.0e40_ids_real; s3 = -9.0e40_ids_real
    tag = ''
    ha = associated(a); hb = associated(b)
    if (ha) then
      write(tag, '(a,i0,a)') '[', size(a), ' tot]'
      if (size(a) > 0) s4 = a(1,1,1,1)
    end if
    if (hb) then
      if (size(b) > 0) s3 = b(1,1,1,1)
    end if
    if (.not. ha .and. .not. hb) then
      v = '--'
    else if (.not. hb) then
      v = 'only4'
    else if (.not. ha) then
      v = 'only3'
    else if (.not. all(shape(a) == shape(b))) then
      v = 'SHAPE'
    else
      call cmp_flat(reshape(a, [size(a)]), reshape(b, [size(b)]), same, flip)
      if (same) then
        v = 'same'
      else if (flip) then
        v = 'FLIP'
      else
        v = 'DIFF'
      end if
    end if
    call paint(trim(path)//trim(tag), num_d(s4), num_d(s3), v)
  end subroutine

  subroutine row_s1(path, a, b)
    character(len=*), intent(in) :: path
    character(len=ids_string_length), pointer, intent(in) :: a(:), b(:)
    character(len=SW) :: s4, s3
    character(len=16) :: tag
    logical :: ha, hb
    character(len=6) :: v
    s4 = '(not provided)'; s3 = '(not provided)'
    tag = ''
    ha = associated(a); hb = associated(b)
    if (ha) then
      write(tag, '(a,i0,a)') '[', size(a), ']'
      if (size(a) > 0) then
        if (len_trim(a(1)) > 0) s4 = a(1)
      end if
    end if
    if (hb) then
      if (size(b) > 0) then
        if (len_trim(b(1)) > 0) s3 = b(1)
      end if
    end if
    if (.not. ha .and. .not. hb) then
      v = '--'
    else if (.not. hb) then
      v = 'only4'
    else if (.not. ha) then
      v = 'only3'
    else if (trim(s4) == trim(s3)) then
      v = 'same'
    else
      v = 'DIFF'
    end if
    call paint(trim(path)//trim(tag), pads(s4), pads(s3), v)
  end subroutine

  subroutine row_id(path, name4, idx4, descr4, name3, idx3, descr3)
    character(len=*), intent(in) :: path
    character(len=ids_string_length), pointer, intent(in) :: name4(:), descr4(:), name3(:), descr3(:)
    integer(ids_int), intent(in) :: idx4, idx3
    call row_s1(trim(path)//'/name', name4, name3)
    call row_i(trim(path)//'/index', idx4, idx3)
    call row_s1(trim(path)//'/description', descr4, descr3)
  end subroutine

  ! Structural-only row for the generic-grid mesh topology and AL bookkeeping
  ! arrays that are deliberately not expanded field-by-field (see header).
  subroutine row_struct(path, has4, n4, has3, n3)
    character(len=*), intent(in) :: path
    logical, intent(in) :: has4, has3
    integer, intent(in) :: n4, n3
    character(len=SW) :: s4, s3
    character(len=6) :: v
    s4 = '(not provided)'; s3 = '(not provided)'
    if (has4) write(s4, '(a,i0,a)') 'associated[', n4, ']'
    if (has3) write(s3, '(a,i0,a)') 'associated[', n3, ']'
    if (.not. has4 .and. .not. has3) then
      v = '--'
    else if (.not. has3) then
      v = 'only4'
    else if (.not. has4) then
      v = 'only3'
    else if (n4 == n3) then
      v = 'same'
    else
      v = 'DIFF'
    end if
    call paint(path, pads(s4), pads(s3), v)
  end subroutine

  ! ------------------------------------------------------ AOS(1) presence

  ! Every "row_*_ptr" below turns a possibly-absent-on-either-side array of
  ! structures into a single element(1) (or an all-defaults stand-in, thanks
  ! to the DD's own component-default initializers) and defers to the
  ! matching scalar worker -- so every leaf field still gets its own row
  ! instead of the whole substructure being skipped when one side is empty.

  subroutine row_meas0d_scalar_std(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D), intent(in) :: a, b
    call row_d(trim(path)//'/measured', a%measured, b%measured)
    call row_d(trim(path)//'/measured_error_upper', a%measured_error_upper, b%measured_error_upper)
    call row_d(trim(path)//'/measured_error_lower', a%measured_error_lower, b%measured_error_lower)
    call row_s1(trim(path)//'/source', a%source, b%source)
    call row_d(trim(path)//'/time_measurement', a%time_measurement, b%time_measurement)
    call row_d(trim(path)//'/time_measurement_error_upper', a%time_measurement_error_upper, b%time_measurement_error_upper)
    call row_d(trim(path)//'/time_measurement_error_lower', a%time_measurement_error_lower, b%time_measurement_error_lower)
    call row_i(trim(path)//'/exact', a%exact, b%exact)
    call row_d(trim(path)//'/weight', a%weight, b%weight)
    call row_d(trim(path)//'/weight_error_upper', a%weight_error_upper, b%weight_error_upper)
    call row_d(trim(path)//'/weight_error_lower', a%weight_error_lower, b%weight_error_lower)
    call row_d(trim(path)//'/reconstructed', a%reconstructed, b%reconstructed)
    call row_d(trim(path)//'/reconstructed_error_upper', a%reconstructed_error_upper, b%reconstructed_error_upper)
    call row_d(trim(path)//'/reconstructed_error_lower', a%reconstructed_error_lower, b%reconstructed_error_lower)
    call row_d(trim(path)//'/chi_squared', a%chi_squared, b%chi_squared)
    call row_d(trim(path)//'/chi_squared_error_upper', a%chi_squared_error_upper, b%chi_squared_error_upper)
    call row_d(trim(path)//'/chi_squared_error_lower', a%chi_squared_error_lower, b%chi_squared_error_lower)
  end subroutine

  subroutine row_meas0d_scalar_one(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D_one_like), intent(in) :: a, b
    call row_d(trim(path)//'/measured', a%measured, b%measured)
    call row_d(trim(path)//'/measured_error_upper', a%measured_error_upper, b%measured_error_upper)
    call row_d(trim(path)//'/measured_error_lower', a%measured_error_lower, b%measured_error_lower)
    call row_s1(trim(path)//'/source', a%source, b%source)
    call row_d(trim(path)//'/time_measurement', a%time_measurement, b%time_measurement)
    call row_d(trim(path)//'/time_measurement_error_upper', a%time_measurement_error_upper, b%time_measurement_error_upper)
    call row_d(trim(path)//'/time_measurement_error_lower', a%time_measurement_error_lower, b%time_measurement_error_lower)
    call row_i(trim(path)//'/exact', a%exact, b%exact)
    call row_d(trim(path)//'/weight', a%weight, b%weight)
    call row_d(trim(path)//'/weight_error_upper', a%weight_error_upper, b%weight_error_upper)
    call row_d(trim(path)//'/weight_error_lower', a%weight_error_lower, b%weight_error_lower)
    call row_d(trim(path)//'/reconstructed', a%reconstructed, b%reconstructed)
    call row_d(trim(path)//'/reconstructed_error_upper', a%reconstructed_error_upper, b%reconstructed_error_upper)
    call row_d(trim(path)//'/reconstructed_error_lower', a%reconstructed_error_lower, b%reconstructed_error_lower)
    call row_d(trim(path)//'/chi_squared', a%chi_squared, b%chi_squared)
    call row_d(trim(path)//'/chi_squared_error_upper', a%chi_squared_error_upper, b%chi_squared_error_upper)
    call row_d(trim(path)//'/chi_squared_error_lower', a%chi_squared_error_lower, b%chi_squared_error_lower)
  end subroutine

  subroutine row_meas0d_scalar_b0(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D_b0_like), intent(in) :: a, b
    call row_d(trim(path)//'/measured', a%measured, b%measured)
    call row_d(trim(path)//'/measured_error_upper', a%measured_error_upper, b%measured_error_upper)
    call row_d(trim(path)//'/measured_error_lower', a%measured_error_lower, b%measured_error_lower)
    call row_s1(trim(path)//'/source', a%source, b%source)
    call row_d(trim(path)//'/time_measurement', a%time_measurement, b%time_measurement)
    call row_d(trim(path)//'/time_measurement_error_upper', a%time_measurement_error_upper, b%time_measurement_error_upper)
    call row_d(trim(path)//'/time_measurement_error_lower', a%time_measurement_error_lower, b%time_measurement_error_lower)
    call row_i(trim(path)//'/exact', a%exact, b%exact)
    call row_d(trim(path)//'/weight', a%weight, b%weight)
    call row_d(trim(path)//'/weight_error_upper', a%weight_error_upper, b%weight_error_upper)
    call row_d(trim(path)//'/weight_error_lower', a%weight_error_lower, b%weight_error_lower)
    call row_d(trim(path)//'/reconstructed', a%reconstructed, b%reconstructed)
    call row_d(trim(path)//'/reconstructed_error_upper', a%reconstructed_error_upper, b%reconstructed_error_upper)
    call row_d(trim(path)//'/reconstructed_error_lower', a%reconstructed_error_lower, b%reconstructed_error_lower)
    call row_d(trim(path)//'/chi_squared', a%chi_squared, b%chi_squared)
    call row_d(trim(path)//'/chi_squared_error_upper', a%chi_squared_error_upper, b%chi_squared_error_upper)
    call row_d(trim(path)//'/chi_squared_error_lower', a%chi_squared_error_lower, b%chi_squared_error_lower)
  end subroutine

  subroutine row_meas0d_scalar_ip(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D_ip_like), intent(in) :: a, b
    call row_d(trim(path)//'/measured', a%measured, b%measured)
    call row_d(trim(path)//'/measured_error_upper', a%measured_error_upper, b%measured_error_upper)
    call row_d(trim(path)//'/measured_error_lower', a%measured_error_lower, b%measured_error_lower)
    call row_s1(trim(path)//'/source', a%source, b%source)
    call row_d(trim(path)//'/time_measurement', a%time_measurement, b%time_measurement)
    call row_d(trim(path)//'/time_measurement_error_upper', a%time_measurement_error_upper, b%time_measurement_error_upper)
    call row_d(trim(path)//'/time_measurement_error_lower', a%time_measurement_error_lower, b%time_measurement_error_lower)
    call row_i(trim(path)//'/exact', a%exact, b%exact)
    call row_d(trim(path)//'/weight', a%weight, b%weight)
    call row_d(trim(path)//'/weight_error_upper', a%weight_error_upper, b%weight_error_upper)
    call row_d(trim(path)//'/weight_error_lower', a%weight_error_lower, b%weight_error_lower)
    call row_d(trim(path)//'/reconstructed', a%reconstructed, b%reconstructed)
    call row_d(trim(path)//'/reconstructed_error_upper', a%reconstructed_error_upper, b%reconstructed_error_upper)
    call row_d(trim(path)//'/reconstructed_error_lower', a%reconstructed_error_lower, b%reconstructed_error_lower)
    call row_d(trim(path)//'/chi_squared', a%chi_squared, b%chi_squared)
    call row_d(trim(path)//'/chi_squared_error_upper', a%chi_squared_error_upper, b%chi_squared_error_upper)
    call row_d(trim(path)//'/chi_squared_error_lower', a%chi_squared_error_lower, b%chi_squared_error_lower)
  end subroutine

  subroutine row_meas0d_ptr_std(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_constraints_0D) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_meas0d_scalar_std(path, a(1), b(1))
    else if (ha) then
      call row_meas0d_scalar_std(path, a(1), empty)
    else if (hb) then
      call row_meas0d_scalar_std(path, empty, b(1))
    else
      call row_meas0d_scalar_std(path, empty, empty)
    end if
  end subroutine

  subroutine row_meas0d_ptr_one(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D_one_like), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_constraints_0D_one_like) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_meas0d_scalar_one(path, a(1), b(1))
    else if (ha) then
      call row_meas0d_scalar_one(path, a(1), empty)
    else if (hb) then
      call row_meas0d_scalar_one(path, empty, b(1))
    else
      call row_meas0d_scalar_one(path, empty, empty)
    end if
  end subroutine

  subroutine row_meas0d_ptr_ip(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D_ip_like), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_constraints_0D_ip_like) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_meas0d_scalar_ip(path, a(1), b(1))
    else if (ha) then
      call row_meas0d_scalar_ip(path, a(1), empty)
    else if (hb) then
      call row_meas0d_scalar_ip(path, empty, b(1))
    else
      call row_meas0d_scalar_ip(path, empty, empty)
    end if
  end subroutine

  subroutine row_iron_core(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_magnetization), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_constraints_0D) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_meas0d_scalar_std(trim(path)//'/magnetization_r', a(1)%magnetization_r, b(1)%magnetization_r)
      call row_meas0d_scalar_std(trim(path)//'/magnetization_z', a(1)%magnetization_z, b(1)%magnetization_z)
    else if (ha) then
      call row_meas0d_scalar_std(trim(path)//'/magnetization_r', a(1)%magnetization_r, empty)
      call row_meas0d_scalar_std(trim(path)//'/magnetization_z', a(1)%magnetization_z, empty)
    else if (hb) then
      call row_meas0d_scalar_std(trim(path)//'/magnetization_r', empty, b(1)%magnetization_r)
      call row_meas0d_scalar_std(trim(path)//'/magnetization_z', empty, b(1)%magnetization_z)
    else
      call row_meas0d_scalar_std(trim(path)//'/magnetization_r', empty, empty)
      call row_meas0d_scalar_std(trim(path)//'/magnetization_z', empty, empty)
    end if
  end subroutine

  subroutine row_pos0d_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D_position), intent(in) :: a, b
    call row_d(trim(path)//'/measured', a%measured, b%measured)
    call row_d(trim(path)//'/measured_error_upper', a%measured_error_upper, b%measured_error_upper)
    call row_d(trim(path)//'/measured_error_lower', a%measured_error_lower, b%measured_error_lower)
    call row_d(trim(path)//'/position/r', a%position%r, b%position%r)
    call row_d(trim(path)//'/position/r_error_upper', a%position%r_error_upper, b%position%r_error_upper)
    call row_d(trim(path)//'/position/r_error_lower', a%position%r_error_lower, b%position%r_error_lower)
    call row_d(trim(path)//'/position/phi', a%position%phi, b%position%phi)
    call row_d(trim(path)//'/position/phi_error_upper', a%position%phi_error_upper, b%position%phi_error_upper)
    call row_d(trim(path)//'/position/phi_error_lower', a%position%phi_error_lower, b%position%phi_error_lower)
    call row_d(trim(path)//'/position/z', a%position%z, b%position%z)
    call row_d(trim(path)//'/position/z_error_upper', a%position%z_error_upper, b%position%z_error_upper)
    call row_d(trim(path)//'/position/z_error_lower', a%position%z_error_lower, b%position%z_error_lower)
    call row_d(trim(path)//'/position/rho_tor_norm', a%position%rho_tor_norm, b%position%rho_tor_norm)
    call row_d(trim(path)//'/position/rho_tor_norm_error_upper', a%position%rho_tor_norm_error_upper, b%position%rho_tor_norm_error_upper)
    call row_d(trim(path)//'/position/rho_tor_norm_error_lower', a%position%rho_tor_norm_error_lower, b%position%rho_tor_norm_error_lower)
    call row_d(trim(path)//'/position/psi', a%position%psi, b%position%psi)
    call row_d(trim(path)//'/position/psi_error_upper', a%position%psi_error_upper, b%position%psi_error_upper)
    call row_d(trim(path)//'/position/psi_error_lower', a%position%psi_error_lower, b%position%psi_error_lower)
    call row_s1(trim(path)//'/source', a%source, b%source)
    call row_d(trim(path)//'/time_measurement', a%time_measurement, b%time_measurement)
    call row_d(trim(path)//'/time_measurement_error_upper', a%time_measurement_error_upper, b%time_measurement_error_upper)
    call row_d(trim(path)//'/time_measurement_error_lower', a%time_measurement_error_lower, b%time_measurement_error_lower)
    call row_i(trim(path)//'/exact', a%exact, b%exact)
    call row_d(trim(path)//'/weight', a%weight, b%weight)
    call row_d(trim(path)//'/weight_error_upper', a%weight_error_upper, b%weight_error_upper)
    call row_d(trim(path)//'/weight_error_lower', a%weight_error_lower, b%weight_error_lower)
    call row_d(trim(path)//'/reconstructed', a%reconstructed, b%reconstructed)
    call row_d(trim(path)//'/reconstructed_error_upper', a%reconstructed_error_upper, b%reconstructed_error_upper)
    call row_d(trim(path)//'/reconstructed_error_lower', a%reconstructed_error_lower, b%reconstructed_error_lower)
    call row_d(trim(path)//'/chi_squared', a%chi_squared, b%chi_squared)
    call row_d(trim(path)//'/chi_squared_error_upper', a%chi_squared_error_upper, b%chi_squared_error_upper)
    call row_d(trim(path)//'/chi_squared_error_lower', a%chi_squared_error_lower, b%chi_squared_error_lower)
  end subroutine

  subroutine row_pos0d_ptr(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_0D_position), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_constraints_0D_position) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_pos0d_scalar(path, a(1), b(1))
    else if (ha) then
      call row_pos0d_scalar(path, a(1), empty)
    else if (hb) then
      call row_pos0d_scalar(path, empty, b(1))
    else
      call row_pos0d_scalar(path, empty, empty)
    end if
  end subroutine

  subroutine row_pureposition_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_pure_position), intent(in) :: a, b
    call row_d(trim(path)//'/position_measured/r', a%position_measured%r, b%position_measured%r)
    call row_d(trim(path)//'/position_measured/r_error_upper', a%position_measured%r_error_upper, b%position_measured%r_error_upper)
    call row_d(trim(path)//'/position_measured/r_error_lower', a%position_measured%r_error_lower, b%position_measured%r_error_lower)
    call row_d(trim(path)//'/position_measured/z', a%position_measured%z, b%position_measured%z)
    call row_d(trim(path)//'/position_measured/z_error_upper', a%position_measured%z_error_upper, b%position_measured%z_error_upper)
    call row_d(trim(path)//'/position_measured/z_error_lower', a%position_measured%z_error_lower, b%position_measured%z_error_lower)
    call row_s1(trim(path)//'/source', a%source, b%source)
    call row_d(trim(path)//'/time_measurement', a%time_measurement, b%time_measurement)
    call row_d(trim(path)//'/time_measurement_error_upper', a%time_measurement_error_upper, b%time_measurement_error_upper)
    call row_d(trim(path)//'/time_measurement_error_lower', a%time_measurement_error_lower, b%time_measurement_error_lower)
    call row_i(trim(path)//'/exact', a%exact, b%exact)
    call row_d(trim(path)//'/weight', a%weight, b%weight)
    call row_d(trim(path)//'/weight_error_upper', a%weight_error_upper, b%weight_error_upper)
    call row_d(trim(path)//'/weight_error_lower', a%weight_error_lower, b%weight_error_lower)
    call row_d(trim(path)//'/position_reconstructed/r', a%position_reconstructed%r, b%position_reconstructed%r)
    call row_d(trim(path)//'/position_reconstructed/r_error_upper', a%position_reconstructed%r_error_upper, b%position_reconstructed%r_error_upper)
    call row_d(trim(path)//'/position_reconstructed/r_error_lower', a%position_reconstructed%r_error_lower, b%position_reconstructed%r_error_lower)
    call row_d(trim(path)//'/position_reconstructed/z', a%position_reconstructed%z, b%position_reconstructed%z)
    call row_d(trim(path)//'/position_reconstructed/z_error_upper', a%position_reconstructed%z_error_upper, b%position_reconstructed%z_error_upper)
    call row_d(trim(path)//'/position_reconstructed/z_error_lower', a%position_reconstructed%z_error_lower, b%position_reconstructed%z_error_lower)
    call row_d(trim(path)//'/chi_squared_r', a%chi_squared_r, b%chi_squared_r)
    call row_d(trim(path)//'/chi_squared_r_error_upper', a%chi_squared_r_error_upper, b%chi_squared_r_error_upper)
    call row_d(trim(path)//'/chi_squared_r_error_lower', a%chi_squared_r_error_lower, b%chi_squared_r_error_lower)
    call row_d(trim(path)//'/chi_squared_z', a%chi_squared_z, b%chi_squared_z)
    call row_d(trim(path)//'/chi_squared_z_error_upper', a%chi_squared_z_error_upper, b%chi_squared_z_error_upper)
    call row_d(trim(path)//'/chi_squared_z_error_lower', a%chi_squared_z_error_lower, b%chi_squared_z_error_lower)
  end subroutine

  subroutine row_pureposition_ptr(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_constraints_pure_position), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_constraints_pure_position) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_pureposition_scalar(path, a(1), b(1))
    else if (ha) then
      call row_pureposition_scalar(path, a(1), empty)
    else if (hb) then
      call row_pureposition_scalar(path, empty, b(1))
    else
      call row_pureposition_scalar(path, empty, empty)
    end if
  end subroutine

  subroutine row_gap_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_gap), intent(in) :: a, b
    call row_s1(trim(path)//'/name', a%name, b%name)
    call row_s1(trim(path)//'/description', a%description, b%description)
    call row_d(trim(path)//'/r', a%r, b%r)
    call row_d(trim(path)//'/r_error_upper', a%r_error_upper, b%r_error_upper)
    call row_d(trim(path)//'/r_error_lower', a%r_error_lower, b%r_error_lower)
    call row_d(trim(path)//'/z', a%z, b%z)
    call row_d(trim(path)//'/z_error_upper', a%z_error_upper, b%z_error_upper)
    call row_d(trim(path)//'/z_error_lower', a%z_error_lower, b%z_error_lower)
    call row_d(trim(path)//'/angle', a%angle, b%angle)
    call row_d(trim(path)//'/angle_error_upper', a%angle_error_upper, b%angle_error_upper)
    call row_d(trim(path)//'/angle_error_lower', a%angle_error_lower, b%angle_error_lower)
    call row_d(trim(path)//'/value', a%value, b%value)
    call row_d(trim(path)//'/value_error_upper', a%value_error_upper, b%value_error_upper)
    call row_d(trim(path)//'/value_error_lower', a%value_error_lower, b%value_error_lower)
  end subroutine

  subroutine row_gap_ptr(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_gap), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_gap) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_gap_scalar(path, a(1), b(1))
    else if (ha) then
      call row_gap_scalar(path, a(1), empty)
    else if (hb) then
      call row_gap_scalar(path, empty, b(1))
    else
      call row_gap_scalar(path, empty, empty)
    end if
  end subroutine

  subroutine row_ctnode_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_contour_tree_node), intent(in) :: a, b
    call row_i(trim(path)//'/critical_type', a%critical_type, b%critical_type)
    call row_d(trim(path)//'/r', a%r, b%r)
    call row_d(trim(path)//'/r_error_upper', a%r_error_upper, b%r_error_upper)
    call row_d(trim(path)//'/r_error_lower', a%r_error_lower, b%r_error_lower)
    call row_d(trim(path)//'/z', a%z, b%z)
    call row_d(trim(path)//'/z_error_upper', a%z_error_upper, b%z_error_upper)
    call row_d(trim(path)//'/z_error_lower', a%z_error_lower, b%z_error_lower)
    call row_d(trim(path)//'/psi', a%psi, b%psi)
    call row_d(trim(path)//'/psi_error_upper', a%psi_error_upper, b%psi_error_upper)
    call row_d(trim(path)//'/psi_error_lower', a%psi_error_lower, b%psi_error_lower)
    call row_d1(trim(path)//'/levelset/r', a%levelset%r, b%levelset%r)
    call row_d1(trim(path)//'/levelset/r_error_upper', a%levelset%r_error_upper, b%levelset%r_error_upper)
    call row_d1(trim(path)//'/levelset/r_error_lower', a%levelset%r_error_lower, b%levelset%r_error_lower)
    call row_d1(trim(path)//'/levelset/z', a%levelset%z, b%levelset%z)
    call row_d1(trim(path)//'/levelset/z_error_upper', a%levelset%z_error_upper, b%levelset%z_error_upper)
    call row_d1(trim(path)//'/levelset/z_error_lower', a%levelset%z_error_lower, b%levelset%z_error_lower)
  end subroutine

  subroutine row_ctnode_ptr(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_contour_tree_node), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_contour_tree_node) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_ctnode_scalar(path, a(1), b(1))
    else if (ha) then
      call row_ctnode_scalar(path, a(1), empty)
    else if (hb) then
      call row_ctnode_scalar(path, empty, b(1))
    else
      call row_ctnode_scalar(path, empty, empty)
    end if
  end subroutine

  subroutine row_edges(path, a, b)
    character(len=*), intent(in) :: path
    integer(ids_int), pointer, intent(in) :: a(:,:), b(:,:)
    logical :: ha, hb
    integer :: n4, n3
    ha = associated(a); n4 = 0; if (ha) n4 = size(a)
    hb = associated(b); n3 = 0; if (hb) n3 = size(b)
    call row_struct(path, ha, n4, hb, n3)
  end subroutine

  subroutine row_library_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_library), intent(in) :: a, b
    call row_s1(trim(path)//'/name', a%name, b%name)
    call row_s1(trim(path)//'/description', a%description, b%description)
    call row_s1(trim(path)//'/commit', a%commit, b%commit)
    call row_s1(trim(path)//'/version', a%version, b%version)
    call row_s1(trim(path)//'/repository', a%repository, b%repository)
    call row_s1(trim(path)//'/parameters', a%parameters, b%parameters)
  end subroutine

  subroutine row_library_ptr(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_library), pointer, intent(in) :: a(:), b(:)
    type(ids_library) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_library_scalar(path, a(1), b(1))
    else if (ha) then
      call row_library_scalar(path, a(1), empty)
    else if (hb) then
      call row_library_scalar(path, empty, b(1))
    else
      call row_library_scalar(path, empty, empty)
    end if
  end subroutine

  subroutine row_ggscalar_val(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_generic_grid_scalar), intent(in) :: a, b
    call row_i(trim(path)//'/grid_index', a%grid_index, b%grid_index)
    call row_i(trim(path)//'/grid_subset_index', a%grid_subset_index, b%grid_subset_index)
    call row_d1(trim(path)//'/values', a%values, b%values)
    call row_d1(trim(path)//'/values_error_upper', a%values_error_upper, b%values_error_upper)
    call row_d1(trim(path)//'/values_error_lower', a%values_error_lower, b%values_error_lower)
    call row_d2(trim(path)//'/coefficients', a%coefficients, b%coefficients)
    call row_d2(trim(path)//'/coefficients_error_upper', a%coefficients_error_upper, b%coefficients_error_upper)
    call row_d2(trim(path)//'/coefficients_error_lower', a%coefficients_error_lower, b%coefficients_error_lower)
  end subroutine

  ! a, b address element (1) of a per-quantity ids_generic_grid_scalar array
  ! that may itself be disassociated (the quantity was never populated) even
  ! when the enclosing ggd(1) container exists.
  subroutine row_ggscalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_generic_grid_scalar), pointer, intent(in) :: a(:), b(:)
    type(ids_generic_grid_scalar) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_ggscalar_val(path, a(1), b(1))
    else if (ha) then
      call row_ggscalar_val(path, a(1), empty)
    else if (hb) then
      call row_ggscalar_val(path, empty, b(1))
    else
      call row_ggscalar_val(path, empty, empty)
    end if
  end subroutine

  ! The ten ggd(1) scalar quantities differ only in which component they
  ! read; a is/isn't associated independently of the enclosing ggd(1)
  ! container also being present, so both levels get the same treatment.
  subroutine row_ggd_container(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_ggd), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_ggd) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_ggd_scalar(path, a(1), b(1))
    else if (ha) then
      call row_ggd_scalar(path, a(1), empty)
    else if (hb) then
      call row_ggd_scalar(path, empty, b(1))
    else
      call row_ggd_scalar(path, empty, empty)
    end if
  end subroutine

  subroutine row_ggd_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_ggd), intent(in) :: a, b
    call row_ggscalar(trim(path)//'/r(1)', a%r, b%r)
    call row_ggscalar(trim(path)//'/z(1)', a%z, b%z)
    call row_ggscalar(trim(path)//'/psi(1)', a%psi, b%psi)
    call row_ggscalar(trim(path)//'/phi(1)', a%phi, b%phi)
    call row_ggscalar(trim(path)//'/theta(1)', a%theta, b%theta)
    call row_ggscalar(trim(path)//'/j_phi(1)', a%j_phi, b%j_phi)
    call row_ggscalar(trim(path)//'/j_parallel(1)', a%j_parallel, b%j_parallel)
    call row_ggscalar(trim(path)//'/b_field_r(1)', a%b_field_r, b%b_field_r)
    call row_ggscalar(trim(path)//'/b_field_phi(1)', a%b_field_phi, b%b_field_phi)
    call row_ggscalar(trim(path)//'/b_field_z(1)', a%b_field_z, b%b_field_z)
  end subroutine

  subroutine row_profiles2d_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_profiles_2d), intent(in) :: a, b
    call row_id(trim(path)//'/type', a%type%name, a%type%index, a%type%description, &
                                      b%type%name, b%type%index, b%type%description)
    call row_id(trim(path)//'/grid_type', a%grid_type%name, a%grid_type%index, a%grid_type%description, &
                                           b%grid_type%name, b%grid_type%index, b%grid_type%description)
    call row_d1(trim(path)//'/grid/dim1', a%grid%dim1, b%grid%dim1)
    call row_d1(trim(path)//'/grid/dim1_error_upper', a%grid%dim1_error_upper, b%grid%dim1_error_upper)
    call row_d1(trim(path)//'/grid/dim1_error_lower', a%grid%dim1_error_lower, b%grid%dim1_error_lower)
    call row_d1(trim(path)//'/grid/dim2', a%grid%dim2, b%grid%dim2)
    call row_d1(trim(path)//'/grid/dim2_error_upper', a%grid%dim2_error_upper, b%grid%dim2_error_upper)
    call row_d1(trim(path)//'/grid/dim2_error_lower', a%grid%dim2_error_lower, b%grid%dim2_error_lower)
    call row_d2(trim(path)//'/grid/volume_element', a%grid%volume_element, b%grid%volume_element)
    call row_d2(trim(path)//'/grid/volume_element_error_upper', a%grid%volume_element_error_upper, b%grid%volume_element_error_upper)
    call row_d2(trim(path)//'/grid/volume_element_error_lower', a%grid%volume_element_error_lower, b%grid%volume_element_error_lower)
    call row_d2(trim(path)//'/r', a%r, b%r)
    call row_d2(trim(path)//'/r_error_upper', a%r_error_upper, b%r_error_upper)
    call row_d2(trim(path)//'/r_error_lower', a%r_error_lower, b%r_error_lower)
    call row_d2(trim(path)//'/z', a%z, b%z)
    call row_d2(trim(path)//'/z_error_upper', a%z_error_upper, b%z_error_upper)
    call row_d2(trim(path)//'/z_error_lower', a%z_error_lower, b%z_error_lower)
    call row_d2(trim(path)//'/psi', a%psi, b%psi)
    call row_d2(trim(path)//'/psi_error_upper', a%psi_error_upper, b%psi_error_upper)
    call row_d2(trim(path)//'/psi_error_lower', a%psi_error_lower, b%psi_error_lower)
    call row_d2(trim(path)//'/theta', a%theta, b%theta)
    call row_d2(trim(path)//'/theta_error_upper', a%theta_error_upper, b%theta_error_upper)
    call row_d2(trim(path)//'/theta_error_lower', a%theta_error_lower, b%theta_error_lower)
    call row_d2(trim(path)//'/phi', a%phi, b%phi)
    call row_d2(trim(path)//'/phi_error_upper', a%phi_error_upper, b%phi_error_upper)
    call row_d2(trim(path)//'/phi_error_lower', a%phi_error_lower, b%phi_error_lower)
    call row_d2(trim(path)//'/j_phi', a%j_phi, b%j_phi)
    call row_d2(trim(path)//'/j_phi_error_upper', a%j_phi_error_upper, b%j_phi_error_upper)
    call row_d2(trim(path)//'/j_phi_error_lower', a%j_phi_error_lower, b%j_phi_error_lower)
    call row_d2(trim(path)//'/j_parallel', a%j_parallel, b%j_parallel)
    call row_d2(trim(path)//'/j_parallel_error_upper', a%j_parallel_error_upper, b%j_parallel_error_upper)
    call row_d2(trim(path)//'/j_parallel_error_lower', a%j_parallel_error_lower, b%j_parallel_error_lower)
    call row_d2(trim(path)//'/b_field_r', a%b_field_r, b%b_field_r)
    call row_d2(trim(path)//'/b_field_r_error_upper', a%b_field_r_error_upper, b%b_field_r_error_upper)
    call row_d2(trim(path)//'/b_field_r_error_lower', a%b_field_r_error_lower, b%b_field_r_error_lower)
    call row_d2(trim(path)//'/b_field_phi', a%b_field_phi, b%b_field_phi)
    call row_d2(trim(path)//'/b_field_phi_error_upper', a%b_field_phi_error_upper, b%b_field_phi_error_upper)
    call row_d2(trim(path)//'/b_field_phi_error_lower', a%b_field_phi_error_lower, b%b_field_phi_error_lower)
    call row_d2(trim(path)//'/b_field_z', a%b_field_z, b%b_field_z)
    call row_d2(trim(path)//'/b_field_z_error_upper', a%b_field_z_error_upper, b%b_field_z_error_upper)
    call row_d2(trim(path)//'/b_field_z_error_lower', a%b_field_z_error_lower, b%b_field_z_error_lower)
  end subroutine

  subroutine row_profiles2d_ptr(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_profiles_2d), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_profiles_2d) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_profiles2d_scalar(path, a(1), b(1))
    else if (ha) then
      call row_profiles2d_scalar(path, a(1), empty)
    else if (hb) then
      call row_profiles2d_scalar(path, empty, b(1))
    else
      call row_profiles2d_scalar(path, empty, empty)
    end if
  end subroutine

  ! grid(1)/space and grid(1)/grid_subset are the deep generic-mesh topology
  ! this program deliberately does not expand -- see module header.
  subroutine row_grid_dynamic_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_generic_grid_dynamic), intent(in) :: a, b
    logical :: ha, hb
    integer :: n4, n3
    call row_id(trim(path)//'/identifier', a%identifier%name, a%identifier%index, a%identifier%description, &
                                            b%identifier%name, b%identifier%index, b%identifier%description)
    call row_s1(trim(path)//'/path', a%path, b%path)
    ha = associated(a%space); n4 = 0; if (ha) n4 = size(a%space)
    hb = associated(b%space); n3 = 0; if (hb) n3 = size(b%space)
    call row_struct(trim(path)//'/space', ha, n4, hb, n3)
    ha = associated(a%grid_subset); n4 = 0; if (ha) n4 = size(a%grid_subset)
    hb = associated(b%grid_subset); n3 = 0; if (hb) n3 = size(b%grid_subset)
    call row_struct(trim(path)//'/grid_subset', ha, n4, hb, n3)
  end subroutine

  subroutine row_grid_dynamic_ptr(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_generic_grid_dynamic), pointer, intent(in) :: a(:), b(:)
    type(ids_generic_grid_dynamic) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_grid_dynamic_scalar(path, a(1), b(1))
    else if (ha) then
      call row_grid_dynamic_scalar(path, a(1), empty)
    else if (hb) then
      call row_grid_dynamic_scalar(path, empty, b(1))
    else
      call row_grid_dynamic_scalar(path, empty, empty)
    end if
  end subroutine

  subroutine row_ggd_array_scalar(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_ggd_array), intent(in) :: a, b
    call row_d(trim(path)//'/time', a%time, b%time)
    call row_grid_dynamic_ptr(trim(path)//'/grid(1)', a%grid, b%grid)
  end subroutine

  subroutine row_ggd_array_ptr(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_equilibrium_ggd_array), pointer, intent(in) :: a(:), b(:)
    type(ids_equilibrium_ggd_array) :: empty
    logical :: ha, hb
    ha = associated(a); if (ha) ha = size(a) > 0
    hb = associated(b); if (hb) hb = size(b) > 0
    if (ha .and. hb) then
      call row_ggd_array_scalar(path, a(1), b(1))
    else if (ha) then
      call row_ggd_array_scalar(path, a(1), empty)
    else if (hb) then
      call row_ggd_array_scalar(path, empty, b(1))
    else
      call row_ggd_array_scalar(path, empty, empty)
    end if
  end subroutine

  ! Structural-only presence check for a pointer array of any AOS -- used at
  ! call sites (ids_properties/provenance/node, .../plugins/node) where the
  ! array's element type isn't otherwise handled by a dedicated row_* helper.
  subroutine row_struct_ptr_provenance(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_ids_provenance_node), pointer, intent(in) :: a(:), b(:)
    logical :: ha, hb
    integer :: n4, n3
    ha = associated(a); n4 = 0; if (ha) n4 = size(a)
    hb = associated(b); n3 = 0; if (hb) n3 = size(b)
    call row_struct(path, ha, n4, hb, n3)
  end subroutine

  subroutine row_struct_ptr_plugins(path, a, b)
    character(len=*), intent(in) :: path
    type(ids_ids_plugins_node), pointer, intent(in) :: a(:), b(:)
    logical :: ha, hb
    integer :: n4, n3
    ha = associated(a); n4 = 0; if (ha) n4 = size(a)
    hb = associated(b); n3 = 0; if (hb) n3 = size(b)
    call row_struct(path, ha, n4, hb, n3)
  end subroutine

end module eq_table


program play_eq_two_dd
  use ids_routines
  use al_get_policy
  use iso_fortran_env, only: output_unit
  use eq_table
  implicit none

  integer, parameter :: SL = 1                  ! which time slice the table shows

  type(ids_equilibrium) :: e4, e3
  type(ids_equilibrium_time_slice), pointer :: t4, t3
  character(len=512) :: root, arg, pulse4, pulse3
  integer :: idx
  integer :: status4, status3, skipped4, skipped3

  ! argv: [fixture-root] [pulse-for-column-1] [pulse-for-column-2]. Passing the
  ! same pulse twice is the way to check the table itself rather than the shim:
  ! every row must then read the same value in both columns.
  call get_command_argument(1, arg)
  root = 'imas-python-fixtures/fixtures'
  if (len_trim(arg) > 0) root = trim(arg)
  call get_command_argument(2, arg)
  pulse4 = 'dd-4.1.1'
  if (len_trim(arg) > 0) pulse4 = trim(arg)
  call get_command_argument(3, arg)
  pulse3 = 'dd-3.39.0'
  if (len_trim(arg) > 0) pulse3 = trim(arg)

  call imas_open('imas:hdf5?path='//trim(root)//'/'//trim(pulse4), OPEN_PULSE, idx)
  call ids_get(idx, 'equilibrium', e4, status4)
  call imas_close(idx)
  skipped4 = al_get_skipped_count()

  call imas_open('imas:hdf5?path='//trim(root)//'/'//trim(pulse3), OPEN_PULSE, idx)
  call ids_get(idx, 'equilibrium', e3, status3)
  call imas_close(idx)
  ! The skip log is reset by each ids_get, so read it before the next one.
  skipped3 = al_get_skipped_count()
  call al_report_skipped_paths(output_unit)

  write(*, '(a)') ''
  write(*, '(a)') 'HLI dictionary   : 4.1.1 (both pulses read into the DD 4.1.1 type)'
  write(*, '(a)') 'column 1         : '//trim(pulse4)//'  stamp '//trim(dd_stamp(e4))
  write(*, '(a)') 'column 2         : '//trim(pulse3)//'  stamp '//trim(dd_stamp(e3))
  write(*, '(a)') 'time slice shown : '//char(48 + SL)
  write(*, '(a,i0,a,i0,a)') 'column 1 read    : status ', status4, ', ', skipped4, ' path(s) skipped'
  write(*, '(a,i0,a,i0,a)') 'column 2 read    : status ', status3, ', ', skipped3, ' path(s) skipped'

  ! A cross-version read is expected to come back PARTIAL_READ: the conversion
  ! layer refuses grids_ggd/grid/space/coordinates_type, which is INT_1D in
  ! DD 3.39.0 and an array of identifier structures in DD 4.1.1. What must NOT
  ! happen any more is the read stopping there -- everything below this line is
  ! time_slice data that used to be unreachable.
  if (status4 < 0 .or. status3 < 0) then
    write(*, '(a)') 'ERROR: a read failed outright'
    stop 1
  end if
  if (skipped3 > 0 .and. status3 /= PARTIAL_READ) then
    write(*, '(a)') 'ERROR: paths were skipped but the read did not report PARTIAL_READ'
    stop 1
  end if

  if (.not. associated(e4%time_slice) .or. .not. associated(e3%time_slice)) then
    write(*, '(a)') 'ERROR: a pulse came back with no time_slice'
    stop 1
  end if
  if (size(e4%time_slice) < SL .or. size(e3%time_slice) < SL) then
    write(*, '(a)') 'ERROR: a pulse has fewer time slices than requested'
    stop 1
  end if
  t4 => e4%time_slice(SL)
  t3 => e3%time_slice(SL)

  write(*, '(a)') ''
  write(*, '(a)') C_SAME//'legend: same'//C_RESET//'  '// &
                  C_FLIP//'FLIP'//C_RESET//'  '// &
                  C_DIFF//'DIFF'//C_RESET//'  '// &
                  C_SHAPE//'SHAPE'//C_RESET//'  '// &
                  C_ONLY4//'only4'//C_RESET//'  '// &
                  C_ONLY3//'only3'//C_RESET//'  '// &
                  C_NONE//'--'//C_RESET
  write(*, '(a)') ''
  write(*, '(a,2x,a15,2x,a15,2x,a)') pad('PATH'), '       column 1', '       column 2', 'VERDICT'
  write(*, '(a)') repeat('=', 100)

  call sect('ids_properties')
  call row_s1('ids_properties/comment', e4%ids_properties%comment, e3%ids_properties%comment)
  call row_s1('ids_properties/name', e4%ids_properties%name, e3%ids_properties%name)
  call row_i('ids_properties/homogeneous_time', e4%ids_properties%homogeneous_time, e3%ids_properties%homogeneous_time)
  call row_id('ids_properties/occurrence_type', e4%ids_properties%occurrence_type%name, e4%ids_properties%occurrence_type%index, e4%ids_properties%occurrence_type%description, &
              e3%ids_properties%occurrence_type%name, e3%ids_properties%occurrence_type%index, e3%ids_properties%occurrence_type%description)
  call row_s1('ids_properties/provider', e4%ids_properties%provider, e3%ids_properties%provider)
  call row_s1('ids_properties/creation_date', e4%ids_properties%creation_date, e3%ids_properties%creation_date)
  call row_s1('ids_properties/version_put/data_dictionary', e4%ids_properties%version_put%data_dictionary, e3%ids_properties%version_put%data_dictionary)
  call row_s1('ids_properties/version_put/access_layer', e4%ids_properties%version_put%access_layer, e3%ids_properties%version_put%access_layer)
  call row_s1('ids_properties/version_put/access_layer_language', e4%ids_properties%version_put%access_layer_language, e3%ids_properties%version_put%access_layer_language)
  ! provenance/plugins are Access-Layer bookkeeping, not equilibrium physics -- structural check only
  call row_struct_ptr('ids_properties/provenance/node', e4%ids_properties%provenance%node, e3%ids_properties%provenance%node)
  if (associated(e4%ids_properties%provenance%node)) then
    if (size(e4%ids_properties%provenance%node) > 0 .and. associated(e3%ids_properties%provenance%node)) then
      if (size(e3%ids_properties%provenance%node) > 0) then
        call row_s1('ids_properties/provenance/node(1)/path', e4%ids_properties%provenance%node(1)%path, e3%ids_properties%provenance%node(1)%path)
      end if
    end if
  end if
  call row_struct_ptr('ids_properties/plugins/node', e4%ids_properties%plugins%node, e3%ids_properties%plugins%node)

  call sect('vacuum_toroidal_field')
  call row_d('vacuum_toroidal_field/r0', e4%vacuum_toroidal_field%r0, e3%vacuum_toroidal_field%r0)
  call row_d('vacuum_toroidal_field/r0_error_upper', e4%vacuum_toroidal_field%r0_error_upper, e3%vacuum_toroidal_field%r0_error_upper)
  call row_d('vacuum_toroidal_field/r0_error_lower', e4%vacuum_toroidal_field%r0_error_lower, e3%vacuum_toroidal_field%r0_error_lower)
  call row_d1('vacuum_toroidal_field/b0', e4%vacuum_toroidal_field%b0, e3%vacuum_toroidal_field%b0)
  call row_d1('vacuum_toroidal_field/b0_error_upper', e4%vacuum_toroidal_field%b0_error_upper, e3%vacuum_toroidal_field%b0_error_upper)
  call row_d1('vacuum_toroidal_field/b0_error_lower', e4%vacuum_toroidal_field%b0_error_lower, e3%vacuum_toroidal_field%b0_error_lower)

  call sect('grids_ggd  (top-level; deep generic-mesh space/grid_subset out of scope, see header comment)')
  call row_ggd_array_ptr('grids_ggd(1)', e4%grids_ggd, e3%grids_ggd)

  call sect('code')
  call row_s1('code/name', e4%code%name, e3%code%name)
  call row_s1('code/description', e4%code%description, e3%code%description)
  call row_s1('code/commit', e4%code%commit, e3%code%commit)
  call row_s1('code/version', e4%code%version, e3%code%version)
  call row_s1('code/repository', e4%code%repository, e3%code%repository)
  call row_s1('code/parameters', e4%code%parameters, e3%code%parameters)
  call row_i1('code/output_flag', e4%code%output_flag, e3%code%output_flag)
  call row_library_ptr('code/library(1)', e4%code%library, e3%code%library)

  call sect('time-base')
  call row_d1('time', e4%time, e3%time)
  call row_d('time_slice/time', t4%time, t3%time)

  call sect('global_quantities  (beta_tor_norm <- beta_normal, energy_mhd <- w_mhd fold)')
  call row_d('global_quantities/ip', t4%global_quantities%ip, t3%global_quantities%ip)
  call row_d('global_quantities/ip_error_upper', t4%global_quantities%ip_error_upper, t3%global_quantities%ip_error_upper)
  call row_d('global_quantities/ip_error_lower', t4%global_quantities%ip_error_lower, t3%global_quantities%ip_error_lower)
  call row_d('global_quantities/beta_pol', t4%global_quantities%beta_pol, t3%global_quantities%beta_pol)
  call row_d('global_quantities/beta_pol_error_upper', t4%global_quantities%beta_pol_error_upper, t3%global_quantities%beta_pol_error_upper)
  call row_d('global_quantities/beta_pol_error_lower', t4%global_quantities%beta_pol_error_lower, t3%global_quantities%beta_pol_error_lower)
  call row_d('global_quantities/beta_tor', t4%global_quantities%beta_tor, t3%global_quantities%beta_tor)
  call row_d('global_quantities/beta_tor_error_upper', t4%global_quantities%beta_tor_error_upper, t3%global_quantities%beta_tor_error_upper)
  call row_d('global_quantities/beta_tor_error_lower', t4%global_quantities%beta_tor_error_lower, t3%global_quantities%beta_tor_error_lower)
  call row_d('global_quantities/beta_tor_norm', t4%global_quantities%beta_tor_norm, t3%global_quantities%beta_tor_norm)
  call row_d('global_quantities/beta_tor_norm_error_upper', t4%global_quantities%beta_tor_norm_error_upper, t3%global_quantities%beta_tor_norm_error_upper)
  call row_d('global_quantities/beta_tor_norm_error_lower', t4%global_quantities%beta_tor_norm_error_lower, t3%global_quantities%beta_tor_norm_error_lower)
  call row_d('global_quantities/li_3', t4%global_quantities%li_3, t3%global_quantities%li_3)
  call row_d('global_quantities/li_3_error_upper', t4%global_quantities%li_3_error_upper, t3%global_quantities%li_3_error_upper)
  call row_d('global_quantities/li_3_error_lower', t4%global_quantities%li_3_error_lower, t3%global_quantities%li_3_error_lower)
  call row_d('global_quantities/volume', t4%global_quantities%volume, t3%global_quantities%volume)
  call row_d('global_quantities/volume_error_upper', t4%global_quantities%volume_error_upper, t3%global_quantities%volume_error_upper)
  call row_d('global_quantities/volume_error_lower', t4%global_quantities%volume_error_lower, t3%global_quantities%volume_error_lower)
  call row_d('global_quantities/area', t4%global_quantities%area, t3%global_quantities%area)
  call row_d('global_quantities/area_error_upper', t4%global_quantities%area_error_upper, t3%global_quantities%area_error_upper)
  call row_d('global_quantities/area_error_lower', t4%global_quantities%area_error_lower, t3%global_quantities%area_error_lower)
  call row_d('global_quantities/surface', t4%global_quantities%surface, t3%global_quantities%surface)
  call row_d('global_quantities/surface_error_upper', t4%global_quantities%surface_error_upper, t3%global_quantities%surface_error_upper)
  call row_d('global_quantities/surface_error_lower', t4%global_quantities%surface_error_lower, t3%global_quantities%surface_error_lower)
  call row_d('global_quantities/length_pol', t4%global_quantities%length_pol, t3%global_quantities%length_pol)
  call row_d('global_quantities/length_pol_error_upper', t4%global_quantities%length_pol_error_upper, t3%global_quantities%length_pol_error_upper)
  call row_d('global_quantities/length_pol_error_lower', t4%global_quantities%length_pol_error_lower, t3%global_quantities%length_pol_error_lower)
  call row_d('global_quantities/psi_axis', t4%global_quantities%psi_axis, t3%global_quantities%psi_axis)
  call row_d('global_quantities/psi_axis_error_upper', t4%global_quantities%psi_axis_error_upper, t3%global_quantities%psi_axis_error_upper)
  call row_d('global_quantities/psi_axis_error_lower', t4%global_quantities%psi_axis_error_lower, t3%global_quantities%psi_axis_error_lower)
  call row_d('global_quantities/psi_magnetic_axis', t4%global_quantities%psi_magnetic_axis, t3%global_quantities%psi_magnetic_axis)
  call row_d('global_quantities/psi_magnetic_axis_error_upper', t4%global_quantities%psi_magnetic_axis_error_upper, t3%global_quantities%psi_magnetic_axis_error_upper)
  call row_d('global_quantities/psi_magnetic_axis_error_lower', t4%global_quantities%psi_magnetic_axis_error_lower, t3%global_quantities%psi_magnetic_axis_error_lower)
  call row_d('global_quantities/psi_boundary', t4%global_quantities%psi_boundary, t3%global_quantities%psi_boundary)
  call row_d('global_quantities/psi_boundary_error_upper', t4%global_quantities%psi_boundary_error_upper, t3%global_quantities%psi_boundary_error_upper)
  call row_d('global_quantities/psi_boundary_error_lower', t4%global_quantities%psi_boundary_error_lower, t3%global_quantities%psi_boundary_error_lower)
  call row_d('global_quantities/rho_tor_boundary', t4%global_quantities%rho_tor_boundary, t3%global_quantities%rho_tor_boundary)
  call row_d('global_quantities/rho_tor_boundary_error_upper', t4%global_quantities%rho_tor_boundary_error_upper, t3%global_quantities%rho_tor_boundary_error_upper)
  call row_d('global_quantities/rho_tor_boundary_error_lower', t4%global_quantities%rho_tor_boundary_error_lower, t3%global_quantities%rho_tor_boundary_error_lower)
  call row_d('global_quantities/q_axis', t4%global_quantities%q_axis, t3%global_quantities%q_axis)
  call row_d('global_quantities/q_axis_error_upper', t4%global_quantities%q_axis_error_upper, t3%global_quantities%q_axis_error_upper)
  call row_d('global_quantities/q_axis_error_lower', t4%global_quantities%q_axis_error_lower, t3%global_quantities%q_axis_error_lower)
  call row_d('global_quantities/q_95', t4%global_quantities%q_95, t3%global_quantities%q_95)
  call row_d('global_quantities/q_95_error_upper', t4%global_quantities%q_95_error_upper, t3%global_quantities%q_95_error_upper)
  call row_d('global_quantities/q_95_error_lower', t4%global_quantities%q_95_error_lower, t3%global_quantities%q_95_error_lower)
  call row_d('global_quantities/energy_mhd', t4%global_quantities%energy_mhd, t3%global_quantities%energy_mhd)
  call row_d('global_quantities/energy_mhd_error_upper', t4%global_quantities%energy_mhd_error_upper, t3%global_quantities%energy_mhd_error_upper)
  call row_d('global_quantities/energy_mhd_error_lower', t4%global_quantities%energy_mhd_error_lower, t3%global_quantities%energy_mhd_error_lower)
  call row_d('global_quantities/psi_external_average', t4%global_quantities%psi_external_average, t3%global_quantities%psi_external_average)
  call row_d('global_quantities/psi_external_average_error_upper', t4%global_quantities%psi_external_average_error_upper, t3%global_quantities%psi_external_average_error_upper)
  call row_d('global_quantities/psi_external_average_error_lower', t4%global_quantities%psi_external_average_error_lower, t3%global_quantities%psi_external_average_error_lower)
  call row_d('global_quantities/v_external', t4%global_quantities%v_external, t3%global_quantities%v_external)
  call row_d('global_quantities/v_external_error_upper', t4%global_quantities%v_external_error_upper, t3%global_quantities%v_external_error_upper)
  call row_d('global_quantities/v_external_error_lower', t4%global_quantities%v_external_error_lower, t3%global_quantities%v_external_error_lower)
  call row_d('global_quantities/plasma_inductance', t4%global_quantities%plasma_inductance, t3%global_quantities%plasma_inductance)
  call row_d('global_quantities/plasma_inductance_error_upper', t4%global_quantities%plasma_inductance_error_upper, t3%global_quantities%plasma_inductance_error_upper)
  call row_d('global_quantities/plasma_inductance_error_lower', t4%global_quantities%plasma_inductance_error_lower, t3%global_quantities%plasma_inductance_error_lower)
  call row_d('global_quantities/plasma_resistance', t4%global_quantities%plasma_resistance, t3%global_quantities%plasma_resistance)
  call row_d('global_quantities/plasma_resistance_error_upper', t4%global_quantities%plasma_resistance_error_upper, t3%global_quantities%plasma_resistance_error_upper)
  call row_d('global_quantities/plasma_resistance_error_lower', t4%global_quantities%plasma_resistance_error_lower, t3%global_quantities%plasma_resistance_error_lower)
  call row_d('global_quantities/magnetic_axis/r', t4%global_quantities%magnetic_axis%r, t3%global_quantities%magnetic_axis%r)
  call row_d('global_quantities/magnetic_axis/r_error_upper', t4%global_quantities%magnetic_axis%r_error_upper, t3%global_quantities%magnetic_axis%r_error_upper)
  call row_d('global_quantities/magnetic_axis/r_error_lower', t4%global_quantities%magnetic_axis%r_error_lower, t3%global_quantities%magnetic_axis%r_error_lower)
  call row_d('global_quantities/magnetic_axis/z', t4%global_quantities%magnetic_axis%z, t3%global_quantities%magnetic_axis%z)
  call row_d('global_quantities/magnetic_axis/z_error_upper', t4%global_quantities%magnetic_axis%z_error_upper, t3%global_quantities%magnetic_axis%z_error_upper)
  call row_d('global_quantities/magnetic_axis/z_error_lower', t4%global_quantities%magnetic_axis%z_error_lower, t3%global_quantities%magnetic_axis%z_error_lower)
  call row_d('global_quantities/magnetic_axis/b_field_phi', t4%global_quantities%magnetic_axis%b_field_phi, t3%global_quantities%magnetic_axis%b_field_phi)
  call row_d('global_quantities/magnetic_axis/b_field_phi_error_upper', t4%global_quantities%magnetic_axis%b_field_phi_error_upper, t3%global_quantities%magnetic_axis%b_field_phi_error_upper)
  call row_d('global_quantities/magnetic_axis/b_field_phi_error_lower', t4%global_quantities%magnetic_axis%b_field_phi_error_lower, t3%global_quantities%magnetic_axis%b_field_phi_error_lower)
  call row_d('global_quantities/current_centre/r', t4%global_quantities%current_centre%r, t3%global_quantities%current_centre%r)
  call row_d('global_quantities/current_centre/r_error_upper', t4%global_quantities%current_centre%r_error_upper, t3%global_quantities%current_centre%r_error_upper)
  call row_d('global_quantities/current_centre/r_error_lower', t4%global_quantities%current_centre%r_error_lower, t3%global_quantities%current_centre%r_error_lower)
  call row_d('global_quantities/current_centre/z', t4%global_quantities%current_centre%z, t3%global_quantities%current_centre%z)
  call row_d('global_quantities/current_centre/z_error_upper', t4%global_quantities%current_centre%z_error_upper, t3%global_quantities%current_centre%z_error_upper)
  call row_d('global_quantities/current_centre/z_error_lower', t4%global_quantities%current_centre%z_error_lower, t3%global_quantities%current_centre%z_error_lower)
  call row_d('global_quantities/current_centre/velocity_z', t4%global_quantities%current_centre%velocity_z, t3%global_quantities%current_centre%velocity_z)
  call row_d('global_quantities/current_centre/velocity_z_error_upper', t4%global_quantities%current_centre%velocity_z_error_upper, t3%global_quantities%current_centre%velocity_z_error_upper)
  call row_d('global_quantities/current_centre/velocity_z_error_lower', t4%global_quantities%current_centre%velocity_z_error_lower, t3%global_quantities%current_centre%velocity_z_error_lower)
  call row_d('global_quantities/q_min/value', t4%global_quantities%q_min%value, t3%global_quantities%q_min%value)
  call row_d('global_quantities/q_min/value_error_upper', t4%global_quantities%q_min%value_error_upper, t3%global_quantities%q_min%value_error_upper)
  call row_d('global_quantities/q_min/value_error_lower', t4%global_quantities%q_min%value_error_lower, t3%global_quantities%q_min%value_error_lower)
  call row_d('global_quantities/q_min/rho_tor_norm', t4%global_quantities%q_min%rho_tor_norm, t3%global_quantities%q_min%rho_tor_norm)
  call row_d('global_quantities/q_min/rho_tor_norm_error_upper', t4%global_quantities%q_min%rho_tor_norm_error_upper, t3%global_quantities%q_min%rho_tor_norm_error_upper)
  call row_d('global_quantities/q_min/rho_tor_norm_error_lower', t4%global_quantities%q_min%rho_tor_norm_error_lower, t3%global_quantities%q_min%rho_tor_norm_error_lower)
  call row_d('global_quantities/q_min/psi_norm', t4%global_quantities%q_min%psi_norm, t3%global_quantities%q_min%psi_norm)
  call row_d('global_quantities/q_min/psi_norm_error_upper', t4%global_quantities%q_min%psi_norm_error_upper, t3%global_quantities%q_min%psi_norm_error_upper)
  call row_d('global_quantities/q_min/psi_norm_error_lower', t4%global_quantities%q_min%psi_norm_error_lower, t3%global_quantities%q_min%psi_norm_error_lower)
  call row_d('global_quantities/q_min/psi', t4%global_quantities%q_min%psi, t3%global_quantities%q_min%psi)
  call row_d('global_quantities/q_min/psi_error_upper', t4%global_quantities%q_min%psi_error_upper, t3%global_quantities%q_min%psi_error_upper)
  call row_d('global_quantities/q_min/psi_error_lower', t4%global_quantities%q_min%psi_error_lower, t3%global_quantities%q_min%psi_error_lower)

  call sect('boundary  (closest_wall_point, dr_dz_zero_point, gap <- boundary_separatrix)')
  call row_i('boundary/type', t4%boundary%type, t3%boundary%type)
  call row_d1('boundary/outline/r', t4%boundary%outline%r, t3%boundary%outline%r)
  call row_d1('boundary/outline/r_error_upper', t4%boundary%outline%r_error_upper, t3%boundary%outline%r_error_upper)
  call row_d1('boundary/outline/r_error_lower', t4%boundary%outline%r_error_lower, t3%boundary%outline%r_error_lower)
  call row_d1('boundary/outline/z', t4%boundary%outline%z, t3%boundary%outline%z)
  call row_d1('boundary/outline/z_error_upper', t4%boundary%outline%z_error_upper, t3%boundary%outline%z_error_upper)
  call row_d1('boundary/outline/z_error_lower', t4%boundary%outline%z_error_lower, t3%boundary%outline%z_error_lower)
  call row_d('boundary/psi_norm', t4%boundary%psi_norm, t3%boundary%psi_norm)
  call row_d('boundary/psi_norm_error_upper', t4%boundary%psi_norm_error_upper, t3%boundary%psi_norm_error_upper)
  call row_d('boundary/psi_norm_error_lower', t4%boundary%psi_norm_error_lower, t3%boundary%psi_norm_error_lower)
  call row_d('boundary/psi', t4%boundary%psi, t3%boundary%psi)
  call row_d('boundary/psi_error_upper', t4%boundary%psi_error_upper, t3%boundary%psi_error_upper)
  call row_d('boundary/psi_error_lower', t4%boundary%psi_error_lower, t3%boundary%psi_error_lower)
  call row_d('boundary/minor_radius', t4%boundary%minor_radius, t3%boundary%minor_radius)
  call row_d('boundary/minor_radius_error_upper', t4%boundary%minor_radius_error_upper, t3%boundary%minor_radius_error_upper)
  call row_d('boundary/minor_radius_error_lower', t4%boundary%minor_radius_error_lower, t3%boundary%minor_radius_error_lower)
  call row_d('boundary/elongation', t4%boundary%elongation, t3%boundary%elongation)
  call row_d('boundary/elongation_error_upper', t4%boundary%elongation_error_upper, t3%boundary%elongation_error_upper)
  call row_d('boundary/elongation_error_lower', t4%boundary%elongation_error_lower, t3%boundary%elongation_error_lower)
  call row_d('boundary/triangularity', t4%boundary%triangularity, t3%boundary%triangularity)
  call row_d('boundary/triangularity_error_upper', t4%boundary%triangularity_error_upper, t3%boundary%triangularity_error_upper)
  call row_d('boundary/triangularity_error_lower', t4%boundary%triangularity_error_lower, t3%boundary%triangularity_error_lower)
  call row_d('boundary/triangularity_upper', t4%boundary%triangularity_upper, t3%boundary%triangularity_upper)
  call row_d('boundary/triangularity_upper_error_upper', t4%boundary%triangularity_upper_error_upper, t3%boundary%triangularity_upper_error_upper)
  call row_d('boundary/triangularity_upper_error_lower', t4%boundary%triangularity_upper_error_lower, t3%boundary%triangularity_upper_error_lower)
  call row_d('boundary/triangularity_lower', t4%boundary%triangularity_lower, t3%boundary%triangularity_lower)
  call row_d('boundary/triangularity_lower_error_upper', t4%boundary%triangularity_lower_error_upper, t3%boundary%triangularity_lower_error_upper)
  call row_d('boundary/triangularity_lower_error_lower', t4%boundary%triangularity_lower_error_lower, t3%boundary%triangularity_lower_error_lower)
  call row_d('boundary/squareness_upper_inner', t4%boundary%squareness_upper_inner, t3%boundary%squareness_upper_inner)
  call row_d('boundary/squareness_upper_inner_error_upper', t4%boundary%squareness_upper_inner_error_upper, t3%boundary%squareness_upper_inner_error_upper)
  call row_d('boundary/squareness_upper_inner_error_lower', t4%boundary%squareness_upper_inner_error_lower, t3%boundary%squareness_upper_inner_error_lower)
  call row_d('boundary/squareness_upper_outer', t4%boundary%squareness_upper_outer, t3%boundary%squareness_upper_outer)
  call row_d('boundary/squareness_upper_outer_error_upper', t4%boundary%squareness_upper_outer_error_upper, t3%boundary%squareness_upper_outer_error_upper)
  call row_d('boundary/squareness_upper_outer_error_lower', t4%boundary%squareness_upper_outer_error_lower, t3%boundary%squareness_upper_outer_error_lower)
  call row_d('boundary/squareness_lower_inner', t4%boundary%squareness_lower_inner, t3%boundary%squareness_lower_inner)
  call row_d('boundary/squareness_lower_inner_error_upper', t4%boundary%squareness_lower_inner_error_upper, t3%boundary%squareness_lower_inner_error_upper)
  call row_d('boundary/squareness_lower_inner_error_lower', t4%boundary%squareness_lower_inner_error_lower, t3%boundary%squareness_lower_inner_error_lower)
  call row_d('boundary/squareness_lower_outer', t4%boundary%squareness_lower_outer, t3%boundary%squareness_lower_outer)
  call row_d('boundary/squareness_lower_outer_error_upper', t4%boundary%squareness_lower_outer_error_upper, t3%boundary%squareness_lower_outer_error_upper)
  call row_d('boundary/squareness_lower_outer_error_lower', t4%boundary%squareness_lower_outer_error_lower, t3%boundary%squareness_lower_outer_error_lower)
  call row_d('boundary/rho_tor', t4%boundary%rho_tor, t3%boundary%rho_tor)
  call row_d('boundary/rho_tor_error_upper', t4%boundary%rho_tor_error_upper, t3%boundary%rho_tor_error_upper)
  call row_d('boundary/rho_tor_error_lower', t4%boundary%rho_tor_error_lower, t3%boundary%rho_tor_error_lower)
  call row_d('boundary/phi', t4%boundary%phi, t3%boundary%phi)
  call row_d('boundary/phi_error_upper', t4%boundary%phi_error_upper, t3%boundary%phi_error_upper)
  call row_d('boundary/phi_error_lower', t4%boundary%phi_error_lower, t3%boundary%phi_error_lower)
  call row_d('boundary/phi_poloidal_current', t4%boundary%phi_poloidal_current, t3%boundary%phi_poloidal_current)
  call row_d('boundary/phi_poloidal_current_error_upper', t4%boundary%phi_poloidal_current_error_upper, t3%boundary%phi_poloidal_current_error_upper)
  call row_d('boundary/phi_poloidal_current_error_lower', t4%boundary%phi_poloidal_current_error_lower, t3%boundary%phi_poloidal_current_error_lower)
  call row_d('boundary/geometric_axis/r', t4%boundary%geometric_axis%r, t3%boundary%geometric_axis%r)
  call row_d('boundary/geometric_axis/r_error_upper', t4%boundary%geometric_axis%r_error_upper, t3%boundary%geometric_axis%r_error_upper)
  call row_d('boundary/geometric_axis/r_error_lower', t4%boundary%geometric_axis%r_error_lower, t3%boundary%geometric_axis%r_error_lower)
  call row_d('boundary/geometric_axis/z', t4%boundary%geometric_axis%z, t3%boundary%geometric_axis%z)
  call row_d('boundary/geometric_axis/z_error_upper', t4%boundary%geometric_axis%z_error_upper, t3%boundary%geometric_axis%z_error_upper)
  call row_d('boundary/geometric_axis/z_error_lower', t4%boundary%geometric_axis%z_error_lower, t3%boundary%geometric_axis%z_error_lower)
  call row_d('boundary/closest_wall_point/r', t4%boundary%closest_wall_point%r, t3%boundary%closest_wall_point%r)
  call row_d('boundary/closest_wall_point/r_error_upper', t4%boundary%closest_wall_point%r_error_upper, t3%boundary%closest_wall_point%r_error_upper)
  call row_d('boundary/closest_wall_point/r_error_lower', t4%boundary%closest_wall_point%r_error_lower, t3%boundary%closest_wall_point%r_error_lower)
  call row_d('boundary/closest_wall_point/z', t4%boundary%closest_wall_point%z, t3%boundary%closest_wall_point%z)
  call row_d('boundary/closest_wall_point/z_error_upper', t4%boundary%closest_wall_point%z_error_upper, t3%boundary%closest_wall_point%z_error_upper)
  call row_d('boundary/closest_wall_point/z_error_lower', t4%boundary%closest_wall_point%z_error_lower, t3%boundary%closest_wall_point%z_error_lower)
  call row_d('boundary/closest_wall_point/distance', t4%boundary%closest_wall_point%distance, t3%boundary%closest_wall_point%distance)
  call row_d('boundary/closest_wall_point/distance_error_upper', t4%boundary%closest_wall_point%distance_error_upper, t3%boundary%closest_wall_point%distance_error_upper)
  call row_d('boundary/closest_wall_point/distance_error_lower', t4%boundary%closest_wall_point%distance_error_lower, t3%boundary%closest_wall_point%distance_error_lower)
  call row_d('boundary/dr_dz_zero_point/r', t4%boundary%dr_dz_zero_point%r, t3%boundary%dr_dz_zero_point%r)
  call row_d('boundary/dr_dz_zero_point/r_error_upper', t4%boundary%dr_dz_zero_point%r_error_upper, t3%boundary%dr_dz_zero_point%r_error_upper)
  call row_d('boundary/dr_dz_zero_point/r_error_lower', t4%boundary%dr_dz_zero_point%r_error_lower, t3%boundary%dr_dz_zero_point%r_error_lower)
  call row_d('boundary/dr_dz_zero_point/z', t4%boundary%dr_dz_zero_point%z, t3%boundary%dr_dz_zero_point%z)
  call row_d('boundary/dr_dz_zero_point/z_error_upper', t4%boundary%dr_dz_zero_point%z_error_upper, t3%boundary%dr_dz_zero_point%z_error_upper)
  call row_d('boundary/dr_dz_zero_point/z_error_lower', t4%boundary%dr_dz_zero_point%z_error_lower, t3%boundary%dr_dz_zero_point%z_error_lower)
  call row_gap_ptr('boundary/gap(1)', t4%boundary%gap, t3%boundary%gap)

  call sect('contour_tree  (no DD 3.39.0 source)')
  call row_ctnode_ptr('contour_tree/node(1)', t4%contour_tree%node, t3%contour_tree%node)
  call row_edges('contour_tree/edges', t4%contour_tree%edges, t3%contour_tree%edges)

  call sect('profiles_1d  (j_phi <- j_tor; b_field_* <- b_* folds)')
  call row_d1('profiles_1d/psi', t4%profiles_1d%psi, t3%profiles_1d%psi)
  call row_d1('profiles_1d/psi_error_upper', t4%profiles_1d%psi_error_upper, t3%profiles_1d%psi_error_upper)
  call row_d1('profiles_1d/psi_error_lower', t4%profiles_1d%psi_error_lower, t3%profiles_1d%psi_error_lower)
  call row_d1('profiles_1d/psi_norm', t4%profiles_1d%psi_norm, t3%profiles_1d%psi_norm)
  call row_d1('profiles_1d/psi_norm_error_upper', t4%profiles_1d%psi_norm_error_upper, t3%profiles_1d%psi_norm_error_upper)
  call row_d1('profiles_1d/psi_norm_error_lower', t4%profiles_1d%psi_norm_error_lower, t3%profiles_1d%psi_norm_error_lower)
  call row_d1('profiles_1d/phi', t4%profiles_1d%phi, t3%profiles_1d%phi)
  call row_d1('profiles_1d/phi_error_upper', t4%profiles_1d%phi_error_upper, t3%profiles_1d%phi_error_upper)
  call row_d1('profiles_1d/phi_error_lower', t4%profiles_1d%phi_error_lower, t3%profiles_1d%phi_error_lower)
  call row_d1('profiles_1d/pressure', t4%profiles_1d%pressure, t3%profiles_1d%pressure)
  call row_d1('profiles_1d/pressure_error_upper', t4%profiles_1d%pressure_error_upper, t3%profiles_1d%pressure_error_upper)
  call row_d1('profiles_1d/pressure_error_lower', t4%profiles_1d%pressure_error_lower, t3%profiles_1d%pressure_error_lower)
  call row_d1('profiles_1d/f', t4%profiles_1d%f, t3%profiles_1d%f)
  call row_d1('profiles_1d/f_error_upper', t4%profiles_1d%f_error_upper, t3%profiles_1d%f_error_upper)
  call row_d1('profiles_1d/f_error_lower', t4%profiles_1d%f_error_lower, t3%profiles_1d%f_error_lower)
  call row_d1('profiles_1d/dpressure_dpsi', t4%profiles_1d%dpressure_dpsi, t3%profiles_1d%dpressure_dpsi)
  call row_d1('profiles_1d/dpressure_dpsi_error_upper', t4%profiles_1d%dpressure_dpsi_error_upper, t3%profiles_1d%dpressure_dpsi_error_upper)
  call row_d1('profiles_1d/dpressure_dpsi_error_lower', t4%profiles_1d%dpressure_dpsi_error_lower, t3%profiles_1d%dpressure_dpsi_error_lower)
  call row_d1('profiles_1d/f_df_dpsi', t4%profiles_1d%f_df_dpsi, t3%profiles_1d%f_df_dpsi)
  call row_d1('profiles_1d/f_df_dpsi_error_upper', t4%profiles_1d%f_df_dpsi_error_upper, t3%profiles_1d%f_df_dpsi_error_upper)
  call row_d1('profiles_1d/f_df_dpsi_error_lower', t4%profiles_1d%f_df_dpsi_error_lower, t3%profiles_1d%f_df_dpsi_error_lower)
  call row_d1('profiles_1d/j_phi', t4%profiles_1d%j_phi, t3%profiles_1d%j_phi)
  call row_d1('profiles_1d/j_phi_error_upper', t4%profiles_1d%j_phi_error_upper, t3%profiles_1d%j_phi_error_upper)
  call row_d1('profiles_1d/j_phi_error_lower', t4%profiles_1d%j_phi_error_lower, t3%profiles_1d%j_phi_error_lower)
  call row_d1('profiles_1d/j_parallel', t4%profiles_1d%j_parallel, t3%profiles_1d%j_parallel)
  call row_d1('profiles_1d/j_parallel_error_upper', t4%profiles_1d%j_parallel_error_upper, t3%profiles_1d%j_parallel_error_upper)
  call row_d1('profiles_1d/j_parallel_error_lower', t4%profiles_1d%j_parallel_error_lower, t3%profiles_1d%j_parallel_error_lower)
  call row_d1('profiles_1d/q', t4%profiles_1d%q, t3%profiles_1d%q)
  call row_d1('profiles_1d/q_error_upper', t4%profiles_1d%q_error_upper, t3%profiles_1d%q_error_upper)
  call row_d1('profiles_1d/q_error_lower', t4%profiles_1d%q_error_lower, t3%profiles_1d%q_error_lower)
  call row_d1('profiles_1d/magnetic_shear', t4%profiles_1d%magnetic_shear, t3%profiles_1d%magnetic_shear)
  call row_d1('profiles_1d/magnetic_shear_error_upper', t4%profiles_1d%magnetic_shear_error_upper, t3%profiles_1d%magnetic_shear_error_upper)
  call row_d1('profiles_1d/magnetic_shear_error_lower', t4%profiles_1d%magnetic_shear_error_lower, t3%profiles_1d%magnetic_shear_error_lower)
  call row_d1('profiles_1d/r_inboard', t4%profiles_1d%r_inboard, t3%profiles_1d%r_inboard)
  call row_d1('profiles_1d/r_inboard_error_upper', t4%profiles_1d%r_inboard_error_upper, t3%profiles_1d%r_inboard_error_upper)
  call row_d1('profiles_1d/r_inboard_error_lower', t4%profiles_1d%r_inboard_error_lower, t3%profiles_1d%r_inboard_error_lower)
  call row_d1('profiles_1d/r_outboard', t4%profiles_1d%r_outboard, t3%profiles_1d%r_outboard)
  call row_d1('profiles_1d/r_outboard_error_upper', t4%profiles_1d%r_outboard_error_upper, t3%profiles_1d%r_outboard_error_upper)
  call row_d1('profiles_1d/r_outboard_error_lower', t4%profiles_1d%r_outboard_error_lower, t3%profiles_1d%r_outboard_error_lower)
  call row_d1('profiles_1d/rho_tor', t4%profiles_1d%rho_tor, t3%profiles_1d%rho_tor)
  call row_d1('profiles_1d/rho_tor_error_upper', t4%profiles_1d%rho_tor_error_upper, t3%profiles_1d%rho_tor_error_upper)
  call row_d1('profiles_1d/rho_tor_error_lower', t4%profiles_1d%rho_tor_error_lower, t3%profiles_1d%rho_tor_error_lower)
  call row_d1('profiles_1d/rho_tor_norm', t4%profiles_1d%rho_tor_norm, t3%profiles_1d%rho_tor_norm)
  call row_d1('profiles_1d/rho_tor_norm_error_upper', t4%profiles_1d%rho_tor_norm_error_upper, t3%profiles_1d%rho_tor_norm_error_upper)
  call row_d1('profiles_1d/rho_tor_norm_error_lower', t4%profiles_1d%rho_tor_norm_error_lower, t3%profiles_1d%rho_tor_norm_error_lower)
  call row_d1('profiles_1d/dpsi_drho_tor', t4%profiles_1d%dpsi_drho_tor, t3%profiles_1d%dpsi_drho_tor)
  call row_d1('profiles_1d/dpsi_drho_tor_error_upper', t4%profiles_1d%dpsi_drho_tor_error_upper, t3%profiles_1d%dpsi_drho_tor_error_upper)
  call row_d1('profiles_1d/dpsi_drho_tor_error_lower', t4%profiles_1d%dpsi_drho_tor_error_lower, t3%profiles_1d%dpsi_drho_tor_error_lower)
  call row_d1('profiles_1d/elongation', t4%profiles_1d%elongation, t3%profiles_1d%elongation)
  call row_d1('profiles_1d/elongation_error_upper', t4%profiles_1d%elongation_error_upper, t3%profiles_1d%elongation_error_upper)
  call row_d1('profiles_1d/elongation_error_lower', t4%profiles_1d%elongation_error_lower, t3%profiles_1d%elongation_error_lower)
  call row_d1('profiles_1d/triangularity_upper', t4%profiles_1d%triangularity_upper, t3%profiles_1d%triangularity_upper)
  call row_d1('profiles_1d/triangularity_upper_error_upper', t4%profiles_1d%triangularity_upper_error_upper, t3%profiles_1d%triangularity_upper_error_upper)
  call row_d1('profiles_1d/triangularity_upper_error_lower', t4%profiles_1d%triangularity_upper_error_lower, t3%profiles_1d%triangularity_upper_error_lower)
  call row_d1('profiles_1d/triangularity_lower', t4%profiles_1d%triangularity_lower, t3%profiles_1d%triangularity_lower)
  call row_d1('profiles_1d/triangularity_lower_error_upper', t4%profiles_1d%triangularity_lower_error_upper, t3%profiles_1d%triangularity_lower_error_upper)
  call row_d1('profiles_1d/triangularity_lower_error_lower', t4%profiles_1d%triangularity_lower_error_lower, t3%profiles_1d%triangularity_lower_error_lower)
  call row_d1('profiles_1d/squareness_upper_inner', t4%profiles_1d%squareness_upper_inner, t3%profiles_1d%squareness_upper_inner)
  call row_d1('profiles_1d/squareness_upper_inner_error_upper', t4%profiles_1d%squareness_upper_inner_error_upper, t3%profiles_1d%squareness_upper_inner_error_upper)
  call row_d1('profiles_1d/squareness_upper_inner_error_lower', t4%profiles_1d%squareness_upper_inner_error_lower, t3%profiles_1d%squareness_upper_inner_error_lower)
  call row_d1('profiles_1d/squareness_upper_outer', t4%profiles_1d%squareness_upper_outer, t3%profiles_1d%squareness_upper_outer)
  call row_d1('profiles_1d/squareness_upper_outer_error_upper', t4%profiles_1d%squareness_upper_outer_error_upper, t3%profiles_1d%squareness_upper_outer_error_upper)
  call row_d1('profiles_1d/squareness_upper_outer_error_lower', t4%profiles_1d%squareness_upper_outer_error_lower, t3%profiles_1d%squareness_upper_outer_error_lower)
  call row_d1('profiles_1d/squareness_lower_inner', t4%profiles_1d%squareness_lower_inner, t3%profiles_1d%squareness_lower_inner)
  call row_d1('profiles_1d/squareness_lower_inner_error_upper', t4%profiles_1d%squareness_lower_inner_error_upper, t3%profiles_1d%squareness_lower_inner_error_upper)
  call row_d1('profiles_1d/squareness_lower_inner_error_lower', t4%profiles_1d%squareness_lower_inner_error_lower, t3%profiles_1d%squareness_lower_inner_error_lower)
  call row_d1('profiles_1d/squareness_lower_outer', t4%profiles_1d%squareness_lower_outer, t3%profiles_1d%squareness_lower_outer)
  call row_d1('profiles_1d/squareness_lower_outer_error_upper', t4%profiles_1d%squareness_lower_outer_error_upper, t3%profiles_1d%squareness_lower_outer_error_upper)
  call row_d1('profiles_1d/squareness_lower_outer_error_lower', t4%profiles_1d%squareness_lower_outer_error_lower, t3%profiles_1d%squareness_lower_outer_error_lower)
  call row_d1('profiles_1d/volume', t4%profiles_1d%volume, t3%profiles_1d%volume)
  call row_d1('profiles_1d/volume_error_upper', t4%profiles_1d%volume_error_upper, t3%profiles_1d%volume_error_upper)
  call row_d1('profiles_1d/volume_error_lower', t4%profiles_1d%volume_error_lower, t3%profiles_1d%volume_error_lower)
  call row_d1('profiles_1d/rho_volume_norm', t4%profiles_1d%rho_volume_norm, t3%profiles_1d%rho_volume_norm)
  call row_d1('profiles_1d/rho_volume_norm_error_upper', t4%profiles_1d%rho_volume_norm_error_upper, t3%profiles_1d%rho_volume_norm_error_upper)
  call row_d1('profiles_1d/rho_volume_norm_error_lower', t4%profiles_1d%rho_volume_norm_error_lower, t3%profiles_1d%rho_volume_norm_error_lower)
  call row_d1('profiles_1d/dvolume_dpsi', t4%profiles_1d%dvolume_dpsi, t3%profiles_1d%dvolume_dpsi)
  call row_d1('profiles_1d/dvolume_dpsi_error_upper', t4%profiles_1d%dvolume_dpsi_error_upper, t3%profiles_1d%dvolume_dpsi_error_upper)
  call row_d1('profiles_1d/dvolume_dpsi_error_lower', t4%profiles_1d%dvolume_dpsi_error_lower, t3%profiles_1d%dvolume_dpsi_error_lower)
  call row_d1('profiles_1d/dvolume_drho_tor', t4%profiles_1d%dvolume_drho_tor, t3%profiles_1d%dvolume_drho_tor)
  call row_d1('profiles_1d/dvolume_drho_tor_error_upper', t4%profiles_1d%dvolume_drho_tor_error_upper, t3%profiles_1d%dvolume_drho_tor_error_upper)
  call row_d1('profiles_1d/dvolume_drho_tor_error_lower', t4%profiles_1d%dvolume_drho_tor_error_lower, t3%profiles_1d%dvolume_drho_tor_error_lower)
  call row_d1('profiles_1d/area', t4%profiles_1d%area, t3%profiles_1d%area)
  call row_d1('profiles_1d/area_error_upper', t4%profiles_1d%area_error_upper, t3%profiles_1d%area_error_upper)
  call row_d1('profiles_1d/area_error_lower', t4%profiles_1d%area_error_lower, t3%profiles_1d%area_error_lower)
  call row_d1('profiles_1d/darea_dpsi', t4%profiles_1d%darea_dpsi, t3%profiles_1d%darea_dpsi)
  call row_d1('profiles_1d/darea_dpsi_error_upper', t4%profiles_1d%darea_dpsi_error_upper, t3%profiles_1d%darea_dpsi_error_upper)
  call row_d1('profiles_1d/darea_dpsi_error_lower', t4%profiles_1d%darea_dpsi_error_lower, t3%profiles_1d%darea_dpsi_error_lower)
  call row_d1('profiles_1d/darea_drho_tor', t4%profiles_1d%darea_drho_tor, t3%profiles_1d%darea_drho_tor)
  call row_d1('profiles_1d/darea_drho_tor_error_upper', t4%profiles_1d%darea_drho_tor_error_upper, t3%profiles_1d%darea_drho_tor_error_upper)
  call row_d1('profiles_1d/darea_drho_tor_error_lower', t4%profiles_1d%darea_drho_tor_error_lower, t3%profiles_1d%darea_drho_tor_error_lower)
  call row_d1('profiles_1d/surface', t4%profiles_1d%surface, t3%profiles_1d%surface)
  call row_d1('profiles_1d/surface_error_upper', t4%profiles_1d%surface_error_upper, t3%profiles_1d%surface_error_upper)
  call row_d1('profiles_1d/surface_error_lower', t4%profiles_1d%surface_error_lower, t3%profiles_1d%surface_error_lower)
  call row_d1('profiles_1d/trapped_fraction', t4%profiles_1d%trapped_fraction, t3%profiles_1d%trapped_fraction)
  call row_d1('profiles_1d/trapped_fraction_error_upper', t4%profiles_1d%trapped_fraction_error_upper, t3%profiles_1d%trapped_fraction_error_upper)
  call row_d1('profiles_1d/trapped_fraction_error_lower', t4%profiles_1d%trapped_fraction_error_lower, t3%profiles_1d%trapped_fraction_error_lower)
  call row_d1('profiles_1d/gm1', t4%profiles_1d%gm1, t3%profiles_1d%gm1)
  call row_d1('profiles_1d/gm1_error_upper', t4%profiles_1d%gm1_error_upper, t3%profiles_1d%gm1_error_upper)
  call row_d1('profiles_1d/gm1_error_lower', t4%profiles_1d%gm1_error_lower, t3%profiles_1d%gm1_error_lower)
  call row_d1('profiles_1d/gm2', t4%profiles_1d%gm2, t3%profiles_1d%gm2)
  call row_d1('profiles_1d/gm2_error_upper', t4%profiles_1d%gm2_error_upper, t3%profiles_1d%gm2_error_upper)
  call row_d1('profiles_1d/gm2_error_lower', t4%profiles_1d%gm2_error_lower, t3%profiles_1d%gm2_error_lower)
  call row_d1('profiles_1d/gm3', t4%profiles_1d%gm3, t3%profiles_1d%gm3)
  call row_d1('profiles_1d/gm3_error_upper', t4%profiles_1d%gm3_error_upper, t3%profiles_1d%gm3_error_upper)
  call row_d1('profiles_1d/gm3_error_lower', t4%profiles_1d%gm3_error_lower, t3%profiles_1d%gm3_error_lower)
  call row_d1('profiles_1d/gm4', t4%profiles_1d%gm4, t3%profiles_1d%gm4)
  call row_d1('profiles_1d/gm4_error_upper', t4%profiles_1d%gm4_error_upper, t3%profiles_1d%gm4_error_upper)
  call row_d1('profiles_1d/gm4_error_lower', t4%profiles_1d%gm4_error_lower, t3%profiles_1d%gm4_error_lower)
  call row_d1('profiles_1d/gm5', t4%profiles_1d%gm5, t3%profiles_1d%gm5)
  call row_d1('profiles_1d/gm5_error_upper', t4%profiles_1d%gm5_error_upper, t3%profiles_1d%gm5_error_upper)
  call row_d1('profiles_1d/gm5_error_lower', t4%profiles_1d%gm5_error_lower, t3%profiles_1d%gm5_error_lower)
  call row_d1('profiles_1d/gm6', t4%profiles_1d%gm6, t3%profiles_1d%gm6)
  call row_d1('profiles_1d/gm6_error_upper', t4%profiles_1d%gm6_error_upper, t3%profiles_1d%gm6_error_upper)
  call row_d1('profiles_1d/gm6_error_lower', t4%profiles_1d%gm6_error_lower, t3%profiles_1d%gm6_error_lower)
  call row_d1('profiles_1d/gm7', t4%profiles_1d%gm7, t3%profiles_1d%gm7)
  call row_d1('profiles_1d/gm7_error_upper', t4%profiles_1d%gm7_error_upper, t3%profiles_1d%gm7_error_upper)
  call row_d1('profiles_1d/gm7_error_lower', t4%profiles_1d%gm7_error_lower, t3%profiles_1d%gm7_error_lower)
  call row_d1('profiles_1d/gm8', t4%profiles_1d%gm8, t3%profiles_1d%gm8)
  call row_d1('profiles_1d/gm8_error_upper', t4%profiles_1d%gm8_error_upper, t3%profiles_1d%gm8_error_upper)
  call row_d1('profiles_1d/gm8_error_lower', t4%profiles_1d%gm8_error_lower, t3%profiles_1d%gm8_error_lower)
  call row_d1('profiles_1d/gm9', t4%profiles_1d%gm9, t3%profiles_1d%gm9)
  call row_d1('profiles_1d/gm9_error_upper', t4%profiles_1d%gm9_error_upper, t3%profiles_1d%gm9_error_upper)
  call row_d1('profiles_1d/gm9_error_lower', t4%profiles_1d%gm9_error_lower, t3%profiles_1d%gm9_error_lower)
  call row_d1('profiles_1d/b_field_average', t4%profiles_1d%b_field_average, t3%profiles_1d%b_field_average)
  call row_d1('profiles_1d/b_field_average_error_upper', t4%profiles_1d%b_field_average_error_upper, t3%profiles_1d%b_field_average_error_upper)
  call row_d1('profiles_1d/b_field_average_error_lower', t4%profiles_1d%b_field_average_error_lower, t3%profiles_1d%b_field_average_error_lower)
  call row_d1('profiles_1d/b_field_min', t4%profiles_1d%b_field_min, t3%profiles_1d%b_field_min)
  call row_d1('profiles_1d/b_field_min_error_upper', t4%profiles_1d%b_field_min_error_upper, t3%profiles_1d%b_field_min_error_upper)
  call row_d1('profiles_1d/b_field_min_error_lower', t4%profiles_1d%b_field_min_error_lower, t3%profiles_1d%b_field_min_error_lower)
  call row_d1('profiles_1d/b_field_max', t4%profiles_1d%b_field_max, t3%profiles_1d%b_field_max)
  call row_d1('profiles_1d/b_field_max_error_upper', t4%profiles_1d%b_field_max_error_upper, t3%profiles_1d%b_field_max_error_upper)
  call row_d1('profiles_1d/b_field_max_error_lower', t4%profiles_1d%b_field_max_error_lower, t3%profiles_1d%b_field_max_error_lower)
  call row_d1('profiles_1d/beta_pol', t4%profiles_1d%beta_pol, t3%profiles_1d%beta_pol)
  call row_d1('profiles_1d/beta_pol_error_upper', t4%profiles_1d%beta_pol_error_upper, t3%profiles_1d%beta_pol_error_upper)
  call row_d1('profiles_1d/beta_pol_error_lower', t4%profiles_1d%beta_pol_error_lower, t3%profiles_1d%beta_pol_error_lower)
  call row_d1('profiles_1d/mass_density', t4%profiles_1d%mass_density, t3%profiles_1d%mass_density)
  call row_d1('profiles_1d/mass_density_error_upper', t4%profiles_1d%mass_density_error_upper, t3%profiles_1d%mass_density_error_upper)
  call row_d1('profiles_1d/mass_density_error_lower', t4%profiles_1d%mass_density_error_lower, t3%profiles_1d%mass_density_error_lower)
  call row_d1('profiles_1d/geometric_axis/r', t4%profiles_1d%geometric_axis%r, t3%profiles_1d%geometric_axis%r)
  call row_d1('profiles_1d/geometric_axis/r_error_upper', t4%profiles_1d%geometric_axis%r_error_upper, t3%profiles_1d%geometric_axis%r_error_upper)
  call row_d1('profiles_1d/geometric_axis/r_error_lower', t4%profiles_1d%geometric_axis%r_error_lower, t3%profiles_1d%geometric_axis%r_error_lower)
  call row_d1('profiles_1d/geometric_axis/z', t4%profiles_1d%geometric_axis%z, t3%profiles_1d%geometric_axis%z)
  call row_d1('profiles_1d/geometric_axis/z_error_upper', t4%profiles_1d%geometric_axis%z_error_upper, t3%profiles_1d%geometric_axis%z_error_upper)
  call row_d1('profiles_1d/geometric_axis/z_error_lower', t4%profiles_1d%geometric_axis%z_error_lower, t3%profiles_1d%geometric_axis%z_error_lower)

  call sect('profiles_2d(1)  (j_phi <- j_tor, b_field_phi <- b_tor/b_field_tor)')
  call row_profiles2d_ptr('profiles_2d(1)', t4%profiles_2d, t3%profiles_2d)

  call sect('coordinate_system  (g_ij dropped in DD 4.1.1; tensors carry it)')
  call row_id('coordinate_system/grid_type', t4%coordinate_system%grid_type%name, t4%coordinate_system%grid_type%index, t4%coordinate_system%grid_type%description, &
              t3%coordinate_system%grid_type%name, t3%coordinate_system%grid_type%index, t3%coordinate_system%grid_type%description)
  call row_d1('coordinate_system/grid/dim1', t4%coordinate_system%grid%dim1, t3%coordinate_system%grid%dim1)
  call row_d1('coordinate_system/grid/dim1_error_upper', t4%coordinate_system%grid%dim1_error_upper, t3%coordinate_system%grid%dim1_error_upper)
  call row_d1('coordinate_system/grid/dim1_error_lower', t4%coordinate_system%grid%dim1_error_lower, t3%coordinate_system%grid%dim1_error_lower)
  call row_d1('coordinate_system/grid/dim2', t4%coordinate_system%grid%dim2, t3%coordinate_system%grid%dim2)
  call row_d1('coordinate_system/grid/dim2_error_upper', t4%coordinate_system%grid%dim2_error_upper, t3%coordinate_system%grid%dim2_error_upper)
  call row_d1('coordinate_system/grid/dim2_error_lower', t4%coordinate_system%grid%dim2_error_lower, t3%coordinate_system%grid%dim2_error_lower)
  call row_d2('coordinate_system/grid/volume_element', t4%coordinate_system%grid%volume_element, t3%coordinate_system%grid%volume_element)
  call row_d2('coordinate_system/grid/volume_element_error_upper', t4%coordinate_system%grid%volume_element_error_upper, t3%coordinate_system%grid%volume_element_error_upper)
  call row_d2('coordinate_system/grid/volume_element_error_lower', t4%coordinate_system%grid%volume_element_error_lower, t3%coordinate_system%grid%volume_element_error_lower)
  call row_d2('coordinate_system/r', t4%coordinate_system%r, t3%coordinate_system%r)
  call row_d2('coordinate_system/r_error_upper', t4%coordinate_system%r_error_upper, t3%coordinate_system%r_error_upper)
  call row_d2('coordinate_system/r_error_lower', t4%coordinate_system%r_error_lower, t3%coordinate_system%r_error_lower)
  call row_d2('coordinate_system/z', t4%coordinate_system%z, t3%coordinate_system%z)
  call row_d2('coordinate_system/z_error_upper', t4%coordinate_system%z_error_upper, t3%coordinate_system%z_error_upper)
  call row_d2('coordinate_system/z_error_lower', t4%coordinate_system%z_error_lower, t3%coordinate_system%z_error_lower)
  call row_d2('coordinate_system/jacobian', t4%coordinate_system%jacobian, t3%coordinate_system%jacobian)
  call row_d2('coordinate_system/jacobian_error_upper', t4%coordinate_system%jacobian_error_upper, t3%coordinate_system%jacobian_error_upper)
  call row_d2('coordinate_system/jacobian_error_lower', t4%coordinate_system%jacobian_error_lower, t3%coordinate_system%jacobian_error_lower)
  call row_d4('coordinate_system/tensor_covariant', t4%coordinate_system%tensor_covariant, t3%coordinate_system%tensor_covariant)
  call row_d4('coordinate_system/tensor_covariant_error_upper', t4%coordinate_system%tensor_covariant_error_upper, t3%coordinate_system%tensor_covariant_error_upper)
  call row_d4('coordinate_system/tensor_covariant_error_lower', t4%coordinate_system%tensor_covariant_error_lower, t3%coordinate_system%tensor_covariant_error_lower)
  call row_d4('coordinate_system/tensor_contravariant', t4%coordinate_system%tensor_contravariant, t3%coordinate_system%tensor_contravariant)
  call row_d4('coordinate_system/tensor_contravariant_error_upper', t4%coordinate_system%tensor_contravariant_error_upper, t3%coordinate_system%tensor_contravariant_error_upper)
  call row_d4('coordinate_system/tensor_contravariant_error_lower', t4%coordinate_system%tensor_contravariant_error_lower, t3%coordinate_system%tensor_contravariant_error_lower)

  call sect('ggd(1)  (j_phi <- j_tor, b_field_phi <- b_field_tor)')
  call row_ggd_container('ggd(1)', t4%ggd, t3%ggd)

  call sect('convergence')
  call row_i('convergence/iterations_n', t4%convergence%iterations_n, t3%convergence%iterations_n)
  call row_id('convergence/grad_shafranov_deviation_expression', t4%convergence%grad_shafranov_deviation_expression%name, t4%convergence%grad_shafranov_deviation_expression%index, t4%convergence%grad_shafranov_deviation_expression%description, &
              t3%convergence%grad_shafranov_deviation_expression%name, t3%convergence%grad_shafranov_deviation_expression%index, t3%convergence%grad_shafranov_deviation_expression%description)
  call row_d('convergence/grad_shafranov_deviation_value', t4%convergence%grad_shafranov_deviation_value, t3%convergence%grad_shafranov_deviation_value)
  call row_d('convergence/grad_shafranov_deviation_value_error_upper', t4%convergence%grad_shafranov_deviation_value_error_upper, t3%convergence%grad_shafranov_deviation_value_error_upper)
  call row_d('convergence/grad_shafranov_deviation_value_error_lower', t4%convergence%grad_shafranov_deviation_value_error_lower, t3%convergence%grad_shafranov_deviation_value_error_lower)
  call row_id('convergence/result', t4%convergence%result%name, t4%convergence%result%index, t4%convergence%result%description, &
              t3%convergence%result%name, t3%convergence%result%index, t3%convergence%result%description)
  call sect('constraints  (b_field_pol_probe <- bpol_probe, mse_polarization_angle, j_phi)')
  call row_meas0d_scalar_std('constraints/b_field_tor_vacuum_r', t4%constraints%b_field_tor_vacuum_r, t3%constraints%b_field_tor_vacuum_r)
  call row_meas0d_ptr_one('constraints/b_field_pol_probe(1)', t4%constraints%b_field_pol_probe, t3%constraints%b_field_pol_probe)
  call row_meas0d_scalar_b0('constraints/diamagnetic_flux', t4%constraints%diamagnetic_flux, t3%constraints%diamagnetic_flux)
  call row_meas0d_ptr_std('constraints/faraday_angle(1)', t4%constraints%faraday_angle, t3%constraints%faraday_angle)
  call row_meas0d_ptr_std('constraints/mse_polarization_angle(1)', t4%constraints%mse_polarization_angle, t3%constraints%mse_polarization_angle)
  call row_meas0d_ptr_std('constraints/flux_loop(1)', t4%constraints%flux_loop, t3%constraints%flux_loop)
  call row_meas0d_scalar_ip('constraints/ip', t4%constraints%ip, t3%constraints%ip)
  call row_iron_core('constraints/iron_core_segment(1)', t4%constraints%iron_core_segment, t3%constraints%iron_core_segment)
  call row_pos0d_ptr('constraints/n_e(1)', t4%constraints%n_e, t3%constraints%n_e)
  call row_meas0d_ptr_std('constraints/n_e_line(1)', t4%constraints%n_e_line, t3%constraints%n_e_line)
  call row_meas0d_ptr_ip('constraints/pf_current(1)', t4%constraints%pf_current, t3%constraints%pf_current)
  call row_meas0d_ptr_std('constraints/pf_passive_current(1)', t4%constraints%pf_passive_current, t3%constraints%pf_passive_current)
  call row_pos0d_ptr('constraints/pressure(1)', t4%constraints%pressure, t3%constraints%pressure)
  call row_pos0d_ptr('constraints/pressure_rotational(1)', t4%constraints%pressure_rotational, t3%constraints%pressure_rotational)
  call row_pos0d_ptr('constraints/q(1)', t4%constraints%q, t3%constraints%q)
  call row_pos0d_ptr('constraints/j_phi(1)', t4%constraints%j_phi, t3%constraints%j_phi)
  call row_pos0d_ptr('constraints/j_parallel(1)', t4%constraints%j_parallel, t3%constraints%j_parallel)
  call row_pureposition_ptr('constraints/x_point(1)', t4%constraints%x_point, t3%constraints%x_point)
  call row_pureposition_ptr('constraints/strike_point(1)', t4%constraints%strike_point, t3%constraints%strike_point)
  call row_d('constraints/chi_squared_reduced', t4%constraints%chi_squared_reduced, t3%constraints%chi_squared_reduced)
  call row_d('constraints/chi_squared_reduced_error_upper', t4%constraints%chi_squared_reduced_error_upper, t3%constraints%chi_squared_reduced_error_upper)
  call row_d('constraints/chi_squared_reduced_error_lower', t4%constraints%chi_squared_reduced_error_lower, t3%constraints%chi_squared_reduced_error_lower)
  call row_i('constraints/freedom_degrees_n', t4%constraints%freedom_degrees_n, t3%constraints%freedom_degrees_n)
  call row_i('constraints/constraints_n', t4%constraints%constraints_n, t3%constraints%constraints_n)

  write(*, '(a)') ''
  write(*, '(a)') repeat('=', 100)
  write(*, '(a)') 'end of table'

  call ids_deallocate(e4)
  call ids_deallocate(e3)

end program play_eq_two_dd
