program play_eq_two_dd
    ! Read the checked-in equilibrium fixture of each DD version with that version's own
    ! routines, and print the same physical quantities in the two versions' spellings.
    ! Needs a two-version build (AL_SECOND_DD_IDSDEF), e.g.
    !   IMAS_FORTRAN_PREFIX=install-equilibrium-two-dd ./build.sh play_eq_two_dd.f90
    use ids_routines_v4_1_1
    use ids_routines_v3_39_0

    implicit none

    character(*), parameter :: FIXTURE_v4 = '../imas-python-fixtures/fixtures/dd-4.1.1'
    character(*), parameter :: FIXTURE_v3 = '../imas-python-fixtures/fixtures/dd-3.39.0'
    integer :: idx, status
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

    call print_v4(eq4)
    call print_v3(eq3)

    call ids_deallocate(eq4)
    call ids_deallocate(eq3)

contains

    ! One routine per version: the types differ, and so do the field names the DD 3 -> DD 4
    ! renames touched (j_tor -> j_phi, psi_axis -> psi_magnetic_axis, beta_normal ->
    ! beta_tor_norm, b_field_tor -> b_field_phi). The COCOS 11 -> 17 change also flips the
    ! sign of psi and j, so the two printouts are the same equilibrium, not the same numbers.
    subroutine print_v4(eq)
        type(ids_equilibrium_v4_1_1), intent(in) :: eq
        integer :: i

        print *, '=== DD 4.1.1 ==='
        print *, 'version_put       : ', trim(eq%ids_properties%version_put%data_dictionary(1))
        if (associated(eq%ids_properties%provenance%node)) then
            print *, 'provenance name   : ', &
                 trim(eq%ids_properties%provenance%node(1)%reference(1)%name(1))
        end if
        print *, 'vacuum r0 / b0    : ', eq%vacuum_toroidal_field%r0, eq%vacuum_toroidal_field%b0
        print *, 'time              : ', eq%time
        do i = 1, size(eq%time_slice)
            print *, '--- time_slice(', i, ') t =', eq%time_slice(i)%time
            print *, '  psi             : ', eq%time_slice(i)%profiles_1d%psi
            print *, '  f_df_dpsi       : ', eq%time_slice(i)%profiles_1d%f_df_dpsi
            print *, '  j_phi           : ', eq%time_slice(i)%profiles_1d%j_phi
            print *, '  ip              : ', eq%time_slice(i)%global_quantities%ip
            print *, '  psi_magnetic_axis: ', eq%time_slice(i)%global_quantities%psi_magnetic_axis
            print *, '  beta_tor_norm   : ', eq%time_slice(i)%global_quantities%beta_tor_norm
            print *, '  axis b_field_phi: ', &
                 eq%time_slice(i)%global_quantities%magnetic_axis%b_field_phi
        end do
    end subroutine

    subroutine print_v3(eq)
        type(ids_equilibrium_v3_39_0), intent(in) :: eq
        integer :: i

        print *, '=== DD 3.39.0 ==='
        print *, 'version_put       : ', trim(eq%ids_properties%version_put%data_dictionary(1))
        if (associated(eq%ids_properties%source)) then
            print *, 'source            : ', trim(eq%ids_properties%source(1))
        end if
        print *, 'vacuum r0 / b0    : ', eq%vacuum_toroidal_field%r0, eq%vacuum_toroidal_field%b0
        print *, 'time              : ', eq%time
        do i = 1, size(eq%time_slice)
            print *, '--- time_slice(', i, ') t =', eq%time_slice(i)%time
            print *, '  psi             : ', eq%time_slice(i)%profiles_1d%psi
            print *, '  f_df_dpsi       : ', eq%time_slice(i)%profiles_1d%f_df_dpsi
            print *, '  j_tor           : ', eq%time_slice(i)%profiles_1d%j_tor
            print *, '  ip              : ', eq%time_slice(i)%global_quantities%ip
            print *, '  psi_axis        : ', eq%time_slice(i)%global_quantities%psi_axis
            print *, '  beta_normal     : ', eq%time_slice(i)%global_quantities%beta_normal
            print *, '  axis b_field_tor: ', &
                 eq%time_slice(i)%global_quantities%magnetic_axis%b_field_tor
        end do
    end subroutine

end program play_eq_two_dd
