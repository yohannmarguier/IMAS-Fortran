program play_eq_two_dd
    ! Read the checked-in equilibrium fixture of each DD version with that version's own
    ! routines, and print the DD 3.39.0 -> 4.1.1 differences side by side. Both fixtures
    ! hold the same physical equilibrium, so every line below is a dictionary difference,
    ! not a physics one.
    !
    ! The differences are the ones imas-dd's migration guide reports for equilibrium
    ! (COCOS 11 -> 17, 13 rename families, 12 unit changes), restricted to what
    ! equilibrium_seed.py actually writes into the fixture pair.
    !
    ! Needs a two-version build (AL_SECOND_DD_IDSDEF), e.g.
    !   IMAS_FORTRAN_PREFIX=install-equilibrium-two-dd ./build.sh play_eq_two_dd.f90
    use ids_routines_v4_1_1
    use ids_routines_v3_39_0

    implicit none

    character(*), parameter :: FIXTURE_v4 = '../imas-python-fixtures/fixtures/dd-4.1.1'
    character(*), parameter :: FIXTURE_v3 = '../imas-python-fixtures/fixtures/dd-3.39.0'
    integer :: idx, status, i

    character(:), allocatable :: retmsg

    !type declaration
    type(ids_equilibrium_v4_1_1) :: eq4
    type(ids_equilibrium_v3_39_0) :: eq3

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

    write(*,'(a)') ' equilibrium: DD 3.39.0 -> 4.1.1, one physical equilibrium in two dictionaries'
    write(*,'(a)') ' stamped     : '//trim(eq3%ids_properties%version_put%data_dictionary(1))// &
         ' / '//trim(eq4%ids_properties%version_put%data_dictionary(1))//'   (COCOS 11 -> 17)'
    write(*,'(a)') ' tags        : SAME unchanged | RENAME name only | SIGN COCOS flip |'// &
         ' MOVED restructured | UNITS | TRAP'
    write(*,*)

    call diff_str('MOVED', 'ids_properties/source -> ids_properties/provenance/node/reference/name', &
         trim(eq3%ids_properties%source(1)), &
         trim(eq4%ids_properties%provenance%node(1)%reference(1)%name(1)))
    call diff_0d('SAME', 'vacuum_toroidal_field/r0', &
         eq3%vacuum_toroidal_field%r0, eq4%vacuum_toroidal_field%r0)
    call diff_1d('SAME', 'vacuum_toroidal_field/b0', &
         eq3%vacuum_toroidal_field%b0, eq4%vacuum_toroidal_field%b0)
    call diff_1d('SAME', 'time', eq3%time, eq4%time)

    do i = 1, min(size(eq3%time_slice), size(eq4%time_slice))
        write(*,'(/,a,i0,a,f6.3)') ' --- time_slice(', i, ')  t = ', eq4%time_slice(i)%time

        ! COCOS 11 -> 17 flips psi_like, ip_like and dodpsi_like fields; b0_like keeps its sign.
        call diff_1d('SIGN', 'profiles_1d/psi                                   psi_like x-1', &
             eq3%time_slice(i)%profiles_1d%psi, eq4%time_slice(i)%profiles_1d%psi)
        call diff_1d('SIGN', 'profiles_1d/f_df_dpsi                          dodpsi_like x-1', &
             eq3%time_slice(i)%profiles_1d%f_df_dpsi, eq4%time_slice(i)%profiles_1d%f_df_dpsi)
        call diff_1d('RENAME+SIGN', 'profiles_1d/j_tor -> j_phi                          ip_like x-1', &
             eq3%time_slice(i)%profiles_1d%j_tor, eq4%time_slice(i)%profiles_1d%j_phi)
        call diff_0d('SIGN', 'global_quantities/ip                               ip_like x-1', &
             eq3%time_slice(i)%global_quantities%ip, eq4%time_slice(i)%global_quantities%ip)
        call diff_0d('RENAME+SIGN', 'global_quantities/psi_axis -> psi_magnetic_axis    psi_like x-1', &
             eq3%time_slice(i)%global_quantities%psi_axis, &
             eq4%time_slice(i)%global_quantities%psi_magnetic_axis)
        ! psi_axis was not deleted in DD 4.1.1, it stayed as an obsolescent node that
        ! nothing writes - so reading it by its old name silently returns nothing.
        call diff_0d('TRAP', 'global_quantities/psi_axis      still there in DD 4, obsolescent', &
             eq3%time_slice(i)%global_quantities%psi_axis, &
             eq4%time_slice(i)%global_quantities%psi_axis)
        call diff_0d('RENAME', 'global_quantities/beta_normal -> beta_tor_norm       no sign change', &
             eq3%time_slice(i)%global_quantities%beta_normal, &
             eq4%time_slice(i)%global_quantities%beta_tor_norm)
        call diff_0d('RENAME', 'global_quantities/magnetic_axis/b_field_tor -> b_field_phi', &
             eq3%time_slice(i)%global_quantities%magnetic_axis%b_field_tor, &
             eq4%time_slice(i)%global_quantities%magnetic_axis%b_field_phi)
        call diff_1d('RENAME', 'profiles_2d(1)/b_field_tor -> b_field_phi              row 1 of 2', &
             eq3%time_slice(i)%profiles_2d(1)%b_field_tor(1,:), &
             eq4%time_slice(i)%profiles_2d(1)%b_field_phi(1,:))
        call diff_0d('RENAME', 'constraints/bpol_probe(1) -> b_field_pol_probe(1) /measured', &
             eq3%time_slice(i)%constraints%bpol_probe(1)%measured, &
             eq4%time_slice(i)%constraints%b_field_pol_probe(1)%measured)
        call diff_0d('SIGN', 'constraints/ip/measured                            ip_like x-1', &
             eq3%time_slice(i)%constraints%ip%measured, &
             eq4%time_slice(i)%constraints%ip%measured)
        ! Same path, same type, same number - only the unit moved, which no reader can see.
        call diff_0d('UNITS', 'constraints/strike_point(1)/chi_squared_r          m -> m^-2', &
             eq3%time_slice(i)%constraints%strike_point(1)%chi_squared_r, &
             eq4%time_slice(i)%constraints%strike_point(1)%chi_squared_r)
    end do

    call ids_deallocate(eq4)
    call ids_deallocate(eq3)

contains

    ! One difference: its tag, the DD 3 path (and the DD 4 one where it differs), then the
    ! two versions' values. The helpers take values rather than IDSs, so they are shared
    ! between the two versions even though the types are not.
    subroutine block(tag, what, s3, s4)
        character(*), intent(in) :: tag, what, s3, s4
        character(11) :: t
        t = tag
        write(*,'(2x,"[",a,"] ",a)') t, what
        write(*,'(9x,"3.39.0 :",a)') s3
        write(*,'(9x,"4.1.1  :",a)') s4
    end subroutine

    subroutine diff_0d(tag, what, v3, v4)
        character(*), intent(in) :: tag, what
        real(ids_real), intent(in) :: v3, v4
        call block(tag, what, fmt0(v3), fmt0(v4))
    end subroutine

    subroutine diff_1d(tag, what, v3, v4)
        character(*), intent(in) :: tag, what
        real(ids_real), intent(in) :: v3(:), v4(:)
        call block(tag, what, fmt1(v3), fmt1(v4))
    end subroutine

    subroutine diff_str(tag, what, s3, s4)
        character(*), intent(in) :: tag, what, s3, s4
        call block(tag, what, ' '//s3, ' '//s4)
    end subroutine

    ! An unset node reads back as the invalid marker, not as zero - print it as such, so
    ! the obsolescent-node trap above shows up as absence rather than as a wild number.
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
        real(ids_real), intent(in) :: a(:)
        character(:), allocatable :: s
        integer :: k
        s = ''
        do k = 1, size(a)
            s = s//fmt0(a(k))
        end do
    end function

end program play_eq_two_dd
