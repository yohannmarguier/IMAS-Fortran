subroutine read_entire_ids()
    !! This example focuses on reading whole IDS from entry.
    !! We are storing and reading back an IDS - equilibrium. Data are stored inside MDS+ file.
    use ids_routines
    implicit none

    integer(ids_int) :: data_entry, status
    type(ids_equilibrium) :: equilibrium

    ! NOTE: this block of code uses FORCE_CREATE_PULSE mode in order to create example data
    call imas_open('imas:mdsplus?path=./testdb_mdsplus', FORCE_CREATE_PULSE, data_entry, status)

    ! fill IDS with example data
    equilibrium%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
    allocate(equilibrium%time(3))
    equilibrium%time = (/ 1.0, 2.0, 3.0 /)
    allocate(equilibrium%vacuum_toroidal_field%b0(3))
    equilibrium%vacuum_toroidal_field%b0 = (/ 1.0, 2.0, 3.0 /)
    
    call ids_put(data_entry, 'equilibrium', equilibrium)

    call ids_deallocate(equilibrium)
    call imas_close(data_entry, status)

    ! NOTE: this block of code uses OPEN_PULSE mode in order to read example data
    call imas_open('imas:mdsplus?path=./testdb_mdsplus', OPEN_PULSE, data_entry, status)

    call ids_get(data_entry, 'equilibrium', equilibrium)

    ! here you can access content of the IDS equilibrium
    ! some_variable = equilibrium.some_element
    ! equilibrium.some_element = ...
    ! etc.

    ! one may check if IDS was filled with data using ids_ids_defined(<ids>) subroutine
    write(*,*) 'is equilibrium defined?: ', ids_is_defined(equilibrium)
    call ids_deallocate(equilibrium)

end subroutine read_entire_ids

subroutine read_slice()
    !! This example focuses on reading IDS slices from entry
    !! We are storing and reading back an IDS - summary. Data are stored inside MDS+ file.
    use ids_routines
    implicit none

    integer(ids_int) :: data_entry, status
    integer :: i, j
    real(ids_real) :: twant ! searched time slice
    type(ids_summary) :: summary
    real, dimension(:,:), pointer :: beam_current_fraction_value

    ! NOTE: this block of code uses FORCE_CREATE_PULSE mode in order to create example data
    call imas_open('imas:mdsplus?path=./testdb_mdsplus', FORCE_CREATE_PULSE, data_entry, status)

    ! fill IDS with example data
    summary%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
    allocate(summary%global_quantities%ip%value(3))
    summary%global_quantities%ip%value = (/ 10.0, 11.0, 12.0 /)
    allocate(summary%heating_current_drive%nbi(1))

    allocate(summary%heating_current_drive%nbi(1)%beam_current_fraction%value(3, 3))
    do i = 1, 3
        do j = 1, 3
            summary%heating_current_drive%nbi(1)%beam_current_fraction%value(i, j) = i * j * 100
        end do
    end do

    allocate(summary%time(3))
    summary%time = (/ 1.0, 2.0, 3.0 /)
    
    call ids_put(data_entry, 'summary', summary)

    call ids_deallocate(summary)
    call imas_close(data_entry, status)

    ! NOTE: this block of code uses OPEN_PULSE mode in order to read example data
    call imas_open('imas:mdsplus?path=./testdb_mdsplus', OPEN_PULSE, data_entry, status)
    ! Access Layer API shares 3 different methods of interpolating values from DBEntry
    ! PREVIOUS_INTERP
    ! CLOSEST_INTERP
    ! LINEAR_INTERP

    twant = 1.75
    ! this part of code presents PREVIOUS_INTERP. It is interpolation method that returns the previous time slice if the requested time does not exactly exist in the original IDS
    ! if requested time is outside of time array, first, or last slice will be returned respectively
    call ids_get_slice(data_entry, 'summary', summary, twant, PREVIOUS_INTERP)
    ! previous time value for 1.75 is 1.0
    ! summary/global_quantities/ip/value and time=1 is 10.0
    write(*,*) 'summary/global_quantities/ip/value for time=1: ', summary%global_quantities%ip%value ,'(Should be 10.0)'
    call ids_deallocate(summary)

    ! this part of code presents CLOSEST_INTERP. It is interpolation method that returns the closest time slice in the original IDS
    ! if requested time is equally spaced between two time slices, slice with higher index will be returned
    call ids_get_slice(data_entry, 'summary', summary, twant, CLOSEST_INTERP)
    ! closest time value to 1.75 is 2.0
    ! value for summary/global_quantities/ip/value and time=2 is 11.0
    write(*,*) 'summary/global_quantities/ip/value for time=2: ', summary%global_quantities%ip%value ,'(Should be 11.0)'
    call ids_deallocate(summary)

    ! this part of code presents LINEAR_INTERP. It is interpolation method that returns a linear interpolation between the existing slices before and after the requested time.
    ! NOTE: The linear interpolation will be successful only if, between the two time slices of an interpolated dynamic array of structure,
    ! the same leaves are populated and they have the same size.
    ! Otherwise DBEntry.get_slice() will interpolate all fields with a compatible size and leave others empty.

    ! NOTE: If time requested is smaller than <ids>.time[0], first slice will be returned. If requested time exceeds highest time, last slice will be returned.
    call ids_get_slice(data_entry, 'summary', summary, twant, LINEAR_INTERP)
    ! interpolated value for summary/global_quantities/ip/value and time=1.75 is 10.75
    write(*,*) 'summary/global_quantities/ip/value for time=1.75: ', summary%global_quantities%ip%value , &
    '(Should be 10.75)'
    call ids_deallocate(summary)
end subroutine read_slice
