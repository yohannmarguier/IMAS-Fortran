subroutine put_entire_ids()
    !! This example focuses on putting IDS into entry and passing IDS validation
    use ids_routines
    implicit none

    type(ids_equilibrium) :: equilibrium
    integer(ids_int) :: data_entry, status

    ! NOTE: this block of code uses FORCE_CREATE_PULSE mode in order to create example data
    call imas_open('imas:mdsplus?path=./testdb_mdsplus', FORCE_CREATE_PULSE, data_entry, status)

    ! set mandatory field
    equilibrium%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS

    ! when ids_properties.homogeneous_time is set to IDS_TIME_MODE_HOMOGENEOUS,
    ! all time-dependent fields values correspond to <ids>.time vector.
    allocate(equilibrium%time(3))
    equilibrium%time = (/ 1.0, 2.0, 3.0 /)

    ! equilibrium/vacuum_toroidal_field/b0 should have the same size as equilibrium/time
    allocate(equilibrium%vacuum_toroidal_field%b0(3))
    equilibrium%vacuum_toroidal_field%b0 = (/ 1.0, 2.0, 3.0 /)
    call ids_put(data_entry, 'equilibrium', equilibrium)

    ! NOTE: some IDS fields are put automatically by Access Layer. Examples of this type of fields are:
    ! - <ids>/ids_properties/version_put/data_dictionary
    ! - <ids>/ids_properties/version_put/access_layer
    ! - <ids>/ids_properties/version_put/access_layer_language

    ! IDSs fields can be printed using write or print statement
    write(*,*) 'printing equilibrium from put_entire_ids() subroutine'
    write(*,*) 'equilibrium/time:'
    write(*,'(F5.2)') equilibrium%time
    write(*,*) 'equilibrium/vacuum_toroidal_field/b0 :'
    write(*,'(F5.2)') equilibrium%vacuum_toroidal_field%b0

    call ids_deallocate(equilibrium)
    call imas_close(data_entry, status)

end subroutine put_entire_ids

subroutine put_slice()
    !! This example focuses on putting multiple slices of IDS into entry
    use ids_routines
    implicit none

    type(ids_summary) :: summary
    integer(ids_int) :: data_entry, status
    integer :: i,j,k

    character(len=1) :: loop_iteration_str

    ! NOTE: this block of code uses FORCE_CREATE_PULSE mode in order to create example data
    call imas_open('imas:mdsplus?path=./testdb_mdsplus', FORCE_CREATE_PULSE, data_entry, status)

    ! set mandatory field
    summary%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS

    allocate(summary%heating_current_drive%nbi(1))
    allocate(summary%stationary_phase_flag%value(1))

    do i = 1,5
        ! NOTE: time-independent data is being put only if it is empty in entry
        ! In this case summary/stationary_phase_flag/source will be put only at first iteration.
        ! Suggested way to fill this type of fields is to do this outside loop
        write (loop_iteration_str, '(I1)') i
        allocate(summary%stationary_phase_flag%source(1))
        summary%stationary_phase_flag%source(1) = "Name saved by example code iteration: " // loop_iteration_str

        ! Fill example data
        summary%stationary_phase_flag%value = (/ 10.0 * i /)

        allocate(summary%heating_current_drive%nbi(1)%beam_current_fraction%value(3, 1))
        do j = 1,3
            ! Fill 2D data
            summary%heating_current_drive%nbi(1)%beam_current_fraction%value(j, 1) = 100.0 * i
        end do

        ! NOTE: it is user's responsibility to organize <ids>/time field in ascending manner
        ! breaking this rule will make get_slice() command to fail
        ! slice time is being appended to <ids>/time stored in entry

        allocate(summary%time(1))
        summary%time = (/ i /)

        call ids_put_slice(data_entry, 'summary', summary)
    end do
    
    write (*,*) 'Value of summary/stationary_phase_flag/source after 5 put_slice() calls:'
    write (*,*) summary%stationary_phase_flag%source(1)

    deallocate(summary%stationary_phase_flag%value)
    deallocate(summary%time)

    ! multiple slices can be put into entry as well
    allocate(summary%stationary_phase_flag%value(3))
    summary%stationary_phase_flag%value = (/ 11.0, 12.0, 13.0 /)

    deallocate(summary%heating_current_drive%nbi(1)%beam_current_fraction%value)
    allocate(summary%heating_current_drive%nbi(1)%beam_current_fraction%value(3,3))

    do i = 1,3
        do j = 1,3
            summary%heating_current_drive%nbi(1)%beam_current_fraction%value(i,j) = 1000.0 * j
        end do
    end do

    allocate(summary%time(3))
    summary%time =(/ 50.0, 60.0, 70.0 /)
    call ids_put_slice(data_entry, 'summary', summary)

    ! IDSs fields can be printed using write or print statement
    write(*,*) 'printing summary from put_slice() subroutine'
    write(*,*) 'summary/time:'
    write(*,'(F5.2)') summary%time

    write(*,*) 'summary/stationary_phase_flag/value:'
    write(*,*) summary%stationary_phase_flag%value

    write(*,*) 'summary/heating_current_drive/nbi(1)/beam_current_fraction/value:'
    write(*,'(F7.2)') summary%heating_current_drive%nbi(1)%beam_current_fraction%value
    
end subroutine put_slice

subroutine put_into_non_default_occurrence()
    !! This example focuses on putting IDS into another occurrence
    use ids_routines
    implicit none

    type(ids_equilibrium) :: equilibrium
    integer(ids_int) :: data_entry, status
    integer :: i

    character(len=:), allocatable :: node_content_list(:)
    integer, allocatable :: occurrence_list(:)

    ! NOTE: this block of code uses FORCE_CREATE_PULSE mode in order to create example data
    call imas_open('imas:mdsplus?path=./testdb_mdsplus', FORCE_CREATE_PULSE, data_entry, status)
    ! default occurrence for get/put is 0
    ! list of available occurrences can be found inside Data Dictionary documentation.

    ! set mandatory field
    equilibrium%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS

    ! when ids_properties.homogeneous_time is set to IDS_TIME_MODE_HOMOGENEOUS,
    ! all time-dependent fields values correspond to <ids>.time vector.
    allocate(equilibrium%time(3))
    equilibrium%time = (/ 1.0, 2.0, 3.0 /)

    ! fill fields with some data
    allocate(equilibrium%ids_properties%comment(1))
    equilibrium%ids_properties%comment = '1st comment';

    ! put IDS into occurrence 1
    call ids_put(data_entry, 'equilibrium/1', equilibrium)

    ! modify data, so differences between occurrences can be spotted
    equilibrium%ids_properties%comment = '2nd comment';

    ! put IDS into occurrence 2
    call ids_put(data_entry, 'equilibrium/2', equilibrium)

    ! NOTE: there is ids_properties/occurrence_type structure
    ! it stores additional information about specific occurrence

    ! occurrences can be listed with list_all_occurrences() function
    ! list_all_occurrences also returns content of IDS pointed by node_path argument
    call list_all_occurrences(data_entry, "equilibrium", "ids_properties/comment", node_content_list, occurrence_list)

    if(allocated(occurrence_list)) then 
        write(*,*) "i     occurrence_list(i)      node_content_list(i)"
        do i = 1, size(occurrence_list)
            write(*,*) i,occurrence_list(i),"'"//node_content_list(i)//"'"
        end do
    else 
        write(*,*) "node_content_list, occurrence_list are empty"
    end if 
end subroutine put_into_non_default_occurrence

