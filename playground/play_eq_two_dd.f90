program play_eq_two_dd
    ! Read the checked-in equilibrium fixture of each DD version with that version's own
    ! routines, and print the DD 3.39.0 -> 4.1.1 differences side by side. Both fixtures
    ! hold the same physical equilibrium, so every line below is a dictionary difference,
    ! not a physics one.
    !
    ! A third column, 'converted', is a DD 4.1.1 IDS built from the DD 3.39.0 one by
    ! convert_v3_to_v4, which executes dd-maps/equilibrium/3.39.0--4.1.1.xml (see
    ! eq_convert_3to4.f90). The last column is the verdict: '=' where the converted
    ! value matches the 4.1.1 fixture, '!=' where it does not.
    !
    ! Two rows differ on purpose, and both are places where the map and the fixture
    ! take opposite positions - see the notes on those rows.
    !
    ! The differences are the ones imas-dd's migration guide reports for equilibrium
    ! (COCOS 11 -> 17, 13 rename families, 12 unit changes), restricted to what
    ! equilibrium_seed.py actually writes into the fixture pair.
    !
    ! Needs a two-version build (AL_SECOND_DD_IDSDEF), e.g.
    !   IMAS_FORTRAN_PREFIX=install-equilibrium-two-dd \
    !       ./build.sh play_eq_two_dd.f90 eq_convert_3to4.f90
    use ids_routines_v4_1_1
    use ids_routines_v3_39_0
    use eq_convert_3_39_0_to_4_1_1

    implicit none

    character(*), parameter :: FIXTURE_v4 = '../imas-python-fixtures/fixtures/dd-4.1.1'
    character(*), parameter :: FIXTURE_v3 = '../imas-python-fixtures/fixtures/dd-3.39.0'
    integer :: idx, status, i

    character(:), allocatable :: retmsg

    !what the conversion had to drop or refuse, printed after the report
    type(conversion_log) :: cvlog

    !type declaration
    type(ids_equilibrium_v4_1_1) :: eq4
    type(ids_equilibrium_v3_39_0) :: eq3
    !the DD 4.1.1 IDS the conversion is to produce out of eq3
    type(ids_equilibrium_v4_1_1) :: eq4c

    ! Whatever the conversion has not built yet is read from this default-initialised
    ! slice instead: its scalars are the invalid marker and its arrays are null, so a
    ! missing piece prints as <empty> rather than walking off a null pointer.
    type(ids_equilibrium_time_slice_v4_1_1), target :: empty_slice
    type(ids_equilibrium_time_slice_v4_1_1), pointer :: cs

    !open DBentry and get ids
    call imas_open('imas:hdf5?path='//FIXTURE_v4, OPEN_PULSE, idx, status, retmsg)
    if (status /= 0) then
        print *, 'imas_open failed : ', retmsg
        stop 1
    end if
    call ids_get(idx, 'equilibrium', eq4, status)
    if (status /= 0) then
        print *, 'ids_get failed : ', status
        stop 1
    end if
    call imas_close(idx)

    call imas_open('imas:hdf5?path='//FIXTURE_v3, OPEN_PULSE, idx, status, retmsg)
    if (status /= 0) then
        print *, 'imas_open failed : ', retmsg
        stop 1
    end if
    call ids_get(idx, 'equilibrium', eq3, status)
    if (status /= 0) then
        print *, 'ids_get failed : ', status
        stop 1
    end if
    call imas_close(idx)

    call convert_v3_to_v4(eq3, eq4c, cvlog)

    write(*,'(a)') ' equilibrium: DD 3.39.0 -> 4.1.1, one physical equilibrium in two dictionaries'
    write(*,'(a)') ' stamped     : '//trim(eq3%ids_properties%version_put%data_dictionary(1))// &
         ' / '//trim(eq4%ids_properties%version_put%data_dictionary(1))//'   (COCOS 11 -> 17)'
    write(*,'(a)') ' columns     : 3.39.0 as read | 4.1.1 as read | converted = convert_v3_to_v4(3.39.0)'
    write(*,'(a)') ' tags        : SAME unchanged | RENAME name only | SIGN COCOS flip |'// &
         ' MOVED restructured | UNITS | TRAP'
    write(*,'(a)') ' verdict     : "=" converted matches 4.1.1, "!=" it does not'
    write(*,*)

    call block('MOVED', 'ids_properties/source -> ids_properties/provenance/node/reference/name', &
         source_v3(eq3), provenance_v4(eq4), provenance_v4(eq4c))
    call diff_0d('SAME', 'vacuum_toroidal_field/r0', &
         eq3%vacuum_toroidal_field%r0, eq4%vacuum_toroidal_field%r0, eq4c%vacuum_toroidal_field%r0)
    call diff_1d('SAME', 'vacuum_toroidal_field/b0', &
         eq3%vacuum_toroidal_field%b0, eq4%vacuum_toroidal_field%b0, eq4c%vacuum_toroidal_field%b0)
    call diff_1d('SAME', 'time', eq3%time, eq4%time, eq4c%time)

    do i = 1, min(size(eq3%time_slice), size(eq4%time_slice))
        write(*,'(/,a,i0,a,f6.3)') ' --- time_slice(', i, ')  t = ', eq4%time_slice(i)%time
        cs => converted_slice(eq4c, i)

        ! COCOS 11 -> 17 flips psi_like, ip_like and dodpsi_like fields; b0_like keeps its sign.
        call diff_1d('SIGN', 'profiles_1d/psi                                   psi_like x-1', &
             eq3%time_slice(i)%profiles_1d%psi, eq4%time_slice(i)%profiles_1d%psi, &
             cs%profiles_1d%psi)
        call diff_1d('SIGN', 'profiles_1d/f_df_dpsi                          dodpsi_like x-1', &
             eq3%time_slice(i)%profiles_1d%f_df_dpsi, eq4%time_slice(i)%profiles_1d%f_df_dpsi, &
             cs%profiles_1d%f_df_dpsi)
        call diff_1d('RENAME+SIGN', 'profiles_1d/j_tor -> j_phi                          ip_like x-1', &
             eq3%time_slice(i)%profiles_1d%j_tor, eq4%time_slice(i)%profiles_1d%j_phi, &
             cs%profiles_1d%j_phi)
        call diff_0d('SIGN', 'global_quantities/ip                               ip_like x-1', &
             eq3%time_slice(i)%global_quantities%ip, eq4%time_slice(i)%global_quantities%ip, &
             cs%global_quantities%ip)
        call diff_0d('RENAME+SIGN', 'global_quantities/psi_axis -> psi_magnetic_axis    psi_like x-1', &
             eq3%time_slice(i)%global_quantities%psi_axis, &
             eq4%time_slice(i)%global_quantities%psi_magnetic_axis, &
             cs%global_quantities%psi_magnetic_axis)
        ! psi_axis was not deleted in DD 4.1.1, it stayed as an obsolescent node that
        ! nothing writes - so reading it by its old name silently returns nothing, and a
        ! conversion that fills it instead of psi_magnetic_axis is wrong in the same way.
        !
        ! This row differs on purpose. The map's split-psi-axis rule feeds the DD3
        ! value to BOTH psi_axis and psi_magnetic_axis, so the conversion fills a
        ! node the fixture leaves empty. The rule carries decision="yes" precisely
        ! because nothing in the DD settles it; validate.py lists it for review.
        call diff_0d('TRAP', 'global_quantities/psi_axis      still there in DD 4, obsolescent', &
             eq3%time_slice(i)%global_quantities%psi_axis, &
             eq4%time_slice(i)%global_quantities%psi_axis, &
             cs%global_quantities%psi_axis)
        call diff_0d('RENAME', 'global_quantities/beta_normal -> beta_tor_norm       no sign change', &
             eq3%time_slice(i)%global_quantities%beta_normal, &
             eq4%time_slice(i)%global_quantities%beta_tor_norm, &
             cs%global_quantities%beta_tor_norm)
        call diff_0d('RENAME', 'global_quantities/magnetic_axis/b_field_tor -> b_field_phi', &
             eq3%time_slice(i)%global_quantities%magnetic_axis%b_field_tor, &
             eq4%time_slice(i)%global_quantities%magnetic_axis%b_field_phi, &
             cs%global_quantities%magnetic_axis%b_field_phi)
        call block('RENAME', 'profiles_2d(1)/b_field_tor -> b_field_phi              row 1 of 2', &
             row_v3(eq3%time_slice(i)%profiles_2d, 1), &
             row_v4(eq4%time_slice(i)%profiles_2d, 1), &
             row_v4(cs%profiles_2d, 1))
        call block('RENAME', 'constraints/bpol_probe(1) -> b_field_pol_probe(1) /measured', &
             probe_v3(eq3%time_slice(i)%constraints%bpol_probe), &
             probe_v4(eq4%time_slice(i)%constraints%b_field_pol_probe), &
             probe_v4(cs%constraints%b_field_pol_probe))
        call diff_0d('SIGN', 'constraints/ip/measured                            ip_like x-1', &
             eq3%time_slice(i)%constraints%ip%measured, &
             eq4%time_slice(i)%constraints%ip%measured, &
             cs%constraints%ip%measured)
        ! Same path, same type, same number - only the unit moved, which no reader can see.
        !
        ! This row differs on purpose too, the other way round. The fixture copies the
        ! value through unchanged; the map declares m -> m^-2 a <redefine> with
        ! fidelity unmappable both ways, because chi-squared is now normalised by the
        ! measurement variance and no factor inverts that without the variance used at
        ! reconstruction time. So the conversion refuses the field rather than guess,
        ! and it shows up in the log below.
        call block('UNITS', 'constraints/strike_point(1)/chi_squared_r          m -> m^-2', &
             strike_v3(eq3%time_slice(i)%constraints%strike_point), &
             strike_v4(eq4%time_slice(i)%constraints%strike_point), &
             strike_v4(cs%constraints%strike_point))
    end do

    call log_report(cvlog)

    call ids_deallocate(eq4)
    call ids_deallocate(eq3)
    call ids_deallocate(eq4c)

contains

    ! Slice i of the converted IDS, or the empty stand-in while the conversion has not
    ! built it. The shape is checked here, once, so no row below can hit a null pointer
    ! however far along the conversion is.
    function converted_slice(eq, slice) result(ts)
        type(ids_equilibrium_v4_1_1), intent(in) :: eq
        integer, intent(in) :: slice
        type(ids_equilibrium_time_slice_v4_1_1), pointer :: ts
        ts => empty_slice
        if (.not. associated(eq%time_slice)) return
        if (size(eq%time_slice) < slice) return
        ts => eq%time_slice(slice)
    end function

    ! ------------------------------------------------------------------------ reporting

    ! One difference: its tag, the DD 3 path (and the DD 4 one where it differs), then the
    ! three columns. The helpers take values rather than IDSs, so they are shared between
    ! the two versions even though the types are not.
    subroutine block(tag, what, s3, s4, sc)
        character(*), intent(in) :: tag, what, s3, s4, sc
        character(11) :: t
        character(2) :: verdict
        t = tag
        ! Comparing the rendered strings rather than the numbers keeps one code
        ! path for scalars, arrays, 2D rows and character fields alike, and makes
        ! <empty> compare equal to <empty> instead of tripping over the marker.
        verdict = '!='
        if (s4 == sc) verdict = '= '
        write(*,'(2x,"[",a,"] ",a)') t, what
        write(*,'(6x,"3.39.0    :",a)') s3
        write(*,'(6x,"4.1.1     :",a)') s4
        write(*,'(6x,"converted :",a,"   ",a)') sc, verdict
    end subroutine

    subroutine diff_0d(tag, what, v3, v4, vc)
        character(*), intent(in) :: tag, what
        real(ids_real), intent(in) :: v3, v4, vc
        call block(tag, what, fmt0(v3), fmt0(v4), fmt0(vc))
    end subroutine

    subroutine diff_1d(tag, what, v3, v4, vc)
        character(*), intent(in) :: tag, what
        real(ids_real), pointer, intent(in) :: v3(:), v4(:), vc(:)
        call block(tag, what, fmt1(v3), fmt1(v4), fmt1(vc))
    end subroutine

    ! An unset node reads back as the invalid marker, not as zero - print it as such, so
    ! absence (the obsolescent-node trap, or a field the conversion has not filled) shows
    ! up as absence rather than as a wild number.
    function fmt0(x) result(s)
        real(ids_real), intent(in) :: x
        character(14) :: s
        if (x == ids_real_invalid) then
            s = '       <empty>'
        else
            write(s,'(es14.5)') x
        end if
    end function

    function fmt1(a) result(s)
        real(ids_real), pointer, intent(in) :: a(:)
        character(:), allocatable :: s
        integer :: k
        if (.not. associated(a)) then
            s = '       <empty>'
            return
        end if
        s = ''
        do k = 1, size(a)
            s = s//fmt0(a(k))
        end do
    end function

    ! Everything below reaches through an array of structures, so each one checks that
    ! its array is there before indexing it - the converted IDS may have none of them.

    function row_v3(p2d, r) result(s)
        type(ids_equilibrium_profiles_2d_v3_39_0), pointer, intent(in) :: p2d(:)
        integer, intent(in) :: r
        character(:), allocatable :: s
        s = '       <empty>'
        if (.not. associated(p2d)) return
        if (.not. associated(p2d(1)%b_field_tor)) return
        s = fmt1_view(p2d(1)%b_field_tor(r, :))
    end function

    function row_v4(p2d, r) result(s)
        type(ids_equilibrium_profiles_2d_v4_1_1), pointer, intent(in) :: p2d(:)
        integer, intent(in) :: r
        character(:), allocatable :: s
        s = '       <empty>'
        if (.not. associated(p2d)) return
        if (.not. associated(p2d(1)%b_field_phi)) return
        s = fmt1_view(p2d(1)%b_field_phi(r, :))
    end function

    ! Same as fmt1 for something that is not a pointer, e.g. a row of a 2D array.
    function fmt1_view(a) result(s)
        real(ids_real), intent(in) :: a(:)
        character(:), allocatable :: s
        integer :: k
        s = ''
        do k = 1, size(a)
            s = s//fmt0(a(k))
        end do
    end function

    function probe_v3(probes) result(s)
        type(ids_equilibrium_constraints_0D_one_like_v3_39_0), pointer, intent(in) :: probes(:)
        character(:), allocatable :: s
        s = '       <empty>'
        if (associated(probes)) s = fmt0(probes(1)%measured)
    end function

    function probe_v4(probes) result(s)
        type(ids_equilibrium_constraints_0D_one_like_v4_1_1), pointer, intent(in) :: probes(:)
        character(:), allocatable :: s
        s = '       <empty>'
        if (associated(probes)) s = fmt0(probes(1)%measured)
    end function

    function strike_v3(points) result(s)
        type(ids_equilibrium_constraints_pure_position_v3_39_0), pointer, intent(in) :: points(:)
        character(:), allocatable :: s
        s = '       <empty>'
        if (associated(points)) s = fmt0(points(1)%chi_squared_r)
    end function

    function strike_v4(points) result(s)
        type(ids_equilibrium_constraints_pure_position_v4_1_1), pointer, intent(in) :: points(:)
        character(:), allocatable :: s
        s = '       <empty>'
        if (associated(points)) s = fmt0(points(1)%chi_squared_r)
    end function

    function source_v3(eq) result(s)
        type(ids_equilibrium_v3_39_0), intent(in) :: eq
        character(:), allocatable :: s
        s = ' <empty>'
        if (associated(eq%ids_properties%source)) s = ' '//trim(eq%ids_properties%source(1))
    end function

    function provenance_v4(eq) result(s)
        type(ids_equilibrium_v4_1_1), intent(in) :: eq
        character(:), allocatable :: s
        s = ' <empty>'
        if (.not. associated(eq%ids_properties%provenance%node)) return
        if (.not. associated(eq%ids_properties%provenance%node(1)%reference)) return
        s = ' '//trim(eq%ids_properties%provenance%node(1)%reference(1)%name(1))
    end function

end program play_eq_two_dd
