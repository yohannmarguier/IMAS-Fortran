subroutine creating_completly_new_ids()
    ! This example focuses on creating empty IDS and allocating arrays inside IDS structure
    use ids_routines
    implicit none

    ! empty IDS structures can be created without opening data entry
    ! all you have to do is to instantiate IDS object
    type(ids_core_profiles) :: empty_core_profiles

    ! Note! Every IDS must have <ids>/ids_properties/homogeneous_time field set with one of possible values
    ! Possible homogeneous_time values are:
    !  IDS_TIME_MODE_HETEROGENEOUS: All time-dependent quantities in the IDS may have different time coordinates.
    !  IDS_TIME_MODE_HOMOGENEOUS: All time-dependent quantities in this IDS use the same time coordinate, namely <ids>/time
    !  IDS_TIME_MODE_INDEPENDENT: The IDS stores no time-dependent data.
    empty_core_profiles%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS

    ! it is also recommended to provide basic information regarding data source
    ! even though this information is not required to store IDS, it is highly recommended
    ! to fill these fields.
    !  <ids>/ids_properties/comment
    !  <ids>/ids_properties/provider
    !  <ids>/ids_properties/creation_date

    ! when ids_properties.homogeneous_time is set to IDS_TIME_MODE_HOMOGENEOUS, 
    ! all time-dependent fields values correspond to <ids>.time vector.
    allocate(empty_core_profiles%time(3))
    empty_core_profiles%time = (/ 1.0, 2.0, 3.0 /)

    ! size of time dependent variables must be equal to the size of time vector
    allocate(empty_core_profiles%global_quantities%ip(3))
    empty_core_profiles%global_quantities%ip = (/ 1.0, 2.0, 3.0 /)

    ! IDSs fields can br printed using write or print statement
    write(*,*) 'printing empty_core_profiles%time from creating_completly_new_ids() function'
    write(*,'(5(F0.3,TR1))') empty_core_profiles%time

    ! some fields are automatically written by AL during 'put' procedure
    ! AL adds some information behind your back. This is particularly important
    ! in case you want later on find out what particular version of AL was used when data were stored.
    ! examples of this type of fields are <ids>/ids_properties/version_put and <ids>/ids_properties/plugins

end subroutine creating_completly_new_ids


subroutine default_values_and_aos_operations()
    ! This example focuses on handling arrays of structures and default values
    use ids_routines
    implicit none

    ! create empty edge_profiles
    type(ids_edge_profiles) :: edge_profiles
    type(ids_edge_profiles) :: edge_profiles2
    type(ids_generic_grid_aos3_root), pointer :: tmp_grid_ggd(:)
    integer :: copy_starting_index, i

    ! set mandatory field
    edge_profiles%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS

    ! edge_profiles/grid_ggd is array of structures and must be resized before accessing any of it's elements
    allocate(edge_profiles%grid_ggd(1))
    ! NOTE: for historic reason IDS STR_0D fields are in fact character(len=132), pointer (:)
    allocate(edge_profiles%grid_ggd(1)%identifier%name(1))
    edge_profiles%grid_ggd(1)%identifier%name(1) = 'First test struct'

    ! AoS can be resized with deallocate(node); allocate(node(n)). After calling this, the array of structures will have n elements.
    ! Resizing an array of structures will clear all data inside the array of structures!
    ! Use a temporary variable (as in below example) to keep existing data.
    allocate(tmp_grid_ggd(1))
    call ids_copy(edge_profiles%grid_ggd(1), tmp_grid_ggd(1)) 

    ! actual resize and AoS repopulation
    call ids_deallocate_struct(edge_profiles%grid_ggd(1), .false.)
    allocate(edge_profiles%grid_ggd(3))
    call ids_copy(tmp_grid_ggd(1), edge_profiles%grid_ggd(1))

    ! single element can be added to AoS the following way
    ! tmp_grid_ggd will be reused in this example
    allocate(tmp_grid_ggd(1)%identifier%name(1))
    tmp_grid_ggd(1)%identifier%name(1) = 'Second test struct'

    ! append aos_element to edge_profiles.grid_ggd AoS
    call ids_copy(tmp_grid_ggd(1), edge_profiles%grid_ggd(2))

    ! common action would be merging two different AoS
    ! edge_profiles2/grid_ggd will be merged with edge_profiles/grid_ggd
    ! first, we have to create new AoS and fill it with data
    allocate(edge_profiles2%grid_ggd(1))
    allocate(edge_profiles2%grid_ggd(1)%identifier%name(1))
    edge_profiles2%grid_ggd(1)%identifier%name(1) = 'Third test struct'

    ! once data are in place, we can merge two AoS objects
    ! Note: in real-life situation user has to extract starting index from target array.
    ! since this IDS is created and deleted in this function, we know starting index is 2 (copying starts from starting_index+1)
    copy_starting_index = 2
    do i = 1, size(edge_profiles2%grid_ggd)
        call ids_copy(edge_profiles2%grid_ggd(i), edge_profiles%grid_ggd(copy_starting_index+i))
    end do

    do i = 1, size(edge_profiles%grid_ggd)
        write(*,*) 'Value of edge_profiles%grid_ggd(', i , ')%identifier%name: ', edge_profiles%grid_ggd(i)%identifier%name(1)
    end do

    ! ids fields have default values different for every data type
    write(*,*) 'Default value for INT     data  (edge_profiles/midplane/index)                                 :', &
        edge_profiles%midplane%index
    write(*,*) 'Default value for FLOAT   data  (edge_profiles/vacuum_toroidal_field/vacuum_toroidal_field/r0) :', &
        edge_profiles%vacuum_toroidal_field%r0
    write(*,*) 'Default value for COMPLEX data                                                                 :', &
        IDS_COMPLEX_INVALID
    write(*,*) 'Default value for 1+ dimensional data                                                          :', &
        edge_profiles%vacuum_toroidal_field%b0

    ! clear memory
    call ids_deallocate(edge_profiles)
    call ids_deallocate(edge_profiles2)
    ! second argument in ids_deallocate_struct() indicates if struct was retrieved from entry (.true.),
    ! or defined in Fortran code (.false.)
    call ids_deallocate_struct(tmp_grid_ggd(1), .false.)
    deallocate(tmp_grid_ggd)

end subroutine default_values_and_aos_operations


subroutine copying_and_validating_ids()
    ! This example focuses on creating multi-dimensional arrays, using copmlex type and copying IDS structures
    use ids_routines
    implicit none

    ! create empty gyrokinetics_local
    ! NOTE: gyrokinetics_local is an alpha IDS
    type(ids_gyrokinetics_local) :: gyrokinetics_local
    type(ids_gyrokinetics_local) :: gyrokinetics_local_copy
    character(:), allocatable :: err_msg
    integer :: status

    ! set mandatory field
    gyrokinetics_local%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
    allocate(gyrokinetics_local%time(3))
    gyrokinetics_local%time = (/ 1.0, 2.0, 3.0 /)

    ! some IDS fields contain multi-dimensional arrays
    allocate(gyrokinetics_local%non_linear%fields_zonal_2d%phi_potential_perturbed_norm(3,3))
    gyrokinetics_local%non_linear%fields_zonal_2d%phi_potential_perturbed_norm = &
        reshape([cmplx(1.0, 1.0), cmplx(2.0, 2.0), cmplx(3.0, 3.0), &
                 cmplx(4.0, 4.0), cmplx(5.0, 5.0), cmplx(6.0, 6.0), &
                 cmplx(7.0, 7.0), cmplx(8.0, 8.0), cmplx(9.0, 9.0)], &
                 [3, 3])

    write(*,*) 'Filled 2D array (gyrokinetics_local/non_linear/fields_zonal_2d/phi_potential_perturbed_norm):'
    write(*,'(3(F0.1,"+",F0.1,"i",TR1))') gyrokinetics_local%non_linear%fields_zonal_2d%phi_potential_perturbed_norm

    ! some fields have coordinates consistency. <isd>.validate() method checks for this consistency.
    ! example of field of this type is gyrokinetics_local/non_linear/fields_zonal_2d/phi_potential_perturbed_norm
    ! it's first dimension size must be equal to non_linear/radial_wavevector_norm size and second dimension size equal to non_linear/time_norm
    
    call ids_validate(gyrokinetics_local, status, err_msg)
    if (status /= 0) then
        write (*,*) 'IDS validation failed (intentionally), error message: ', err_msg
    end if

    ! to fix this
    allocate(gyrokinetics_local%non_linear%radial_wavevector_norm(3))
    allocate(gyrokinetics_local%non_linear%time_norm(3))
    gyrokinetics_local%non_linear%radial_wavevector_norm = (/ 1.0, 2.0, 3.0 /)
    gyrokinetics_local%non_linear%time_norm              = (/ 1.0, 2.0, 3.0 /)

    call ids_validate(gyrokinetics_local, status, err_msg)
    if (status /= 0) then
        write (*,*) 'IDS validation failed , error message: ', err_msg
    else
        write (*,*) 'IDS validation passed successfully'
    end if

    ! IDSs can be copied using ids_copy subroutine
    ! gyrokinetics_local/linear.wavevector(i1)/eigenmode(i2)/fields.phi_potential_perturbed_norm has two dimensions and stores complex numbers

    allocate(gyrokinetics_local%linear%wavevector(1))
    allocate(gyrokinetics_local%linear%wavevector(1)%eigenmode(1))
    allocate(gyrokinetics_local%linear%wavevector(1)%eigenmode(1)%fields%phi_potential_perturbed_norm(3,3))
    gyrokinetics_local%linear%wavevector(1)%eigenmode(1)%fields%phi_potential_perturbed_norm = &
        reshape([cmplx(1.0, 1.0), cmplx(2.0, 2.0), cmplx(3.0, 3.0), &
                 cmplx(4.0, 4.0), cmplx(5.0, 5.0), cmplx(6.0, 6.0), &
                 cmplx(7.0, 7.0), cmplx(8.0, 8.0), cmplx(9.0, 9.0)], &
                 [3, 3])

    ! right way to copy IDS
    call ids_copy(gyrokinetics_local, gyrokinetics_local_copy)


    gyrokinetics_local_copy%linear%wavevector(1)%eigenmode(1)%fields%phi_potential_perturbed_norm = &
        reshape([cmplx(11.0, 11.0), cmplx(12.0, 12.0), cmplx(13.0, 13.0), &
                 cmplx(14.0, 14.0), cmplx(15.0, 15.0), cmplx(16.0, 16.0), &
                 cmplx(17.0, 17.0), cmplx(18.0, 18.0), cmplx(19.0, 19.0)], &
                 [3, 3])
    gyrokinetics_local%linear%wavevector(1)%eigenmode(1)%fields%phi_potential_perturbed_norm(1,1) = cmplx(21,37)

    write(*,*) 'Original value:'
    write(*,'(3(F0.1,"+",F0.1,"i",TR1))') &
     gyrokinetics_local%linear%wavevector(1)%eigenmode(1)%fields%phi_potential_perturbed_norm

    write(*,*) 'Copied value:'
    write(*,'(3(F0.1,"+",F0.1,"i",TR1))') &
     gyrokinetics_local_copy%linear%wavevector(1)%eigenmode(1)%fields%phi_potential_perturbed_norm

    call ids_deallocate(gyrokinetics_local)
    call ids_deallocate(gyrokinetics_local_copy)
    
end subroutine copying_and_validating_ids


program main
    call creating_completly_new_ids()
    call default_values_and_aos_operations()
    call copying_and_validating_ids()
end program main