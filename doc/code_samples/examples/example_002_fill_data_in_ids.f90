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
    empty_core_profiles%time = (/ 1.0, 2.0, 3.0 /)

    ! size of time dependent variables must be equal to the size of time vector
    empty_core_profiles%global_quantities%ip = (/ 1.0, 2.0, 3.0 /)

    ! IDSs fields can br printed using write or print statement
    write(*,*) 'printing empty_core_profiles%time from creating_completly_new_ids() function'
    write(*,*) empty_core_profiles%time

    ! some fields are automatically written by AL during 'put' procedure
    ! AL adds some information behind your back. This is particularly important
    ! in case you want later on find out what particular version of AL was used when data were stored.
    ! examples of this type of fields are <ids>/ids_properties/version_put and <ids>/ids_properties/plugins

    ! this time we do not save IDS into database entry, all we do here is deallocating the memory
    ! we have allocated in all previous steps.
    call ids_deallocate(empty_core_profiles)

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
    edge_profiles%grid_ggd(1)%identifier%name = 'First test struct'

    ! AoScan be resized with deallocate(node); allocate(node(n)). After calling this, the array of structures will have n elements.
    ! Resizing an array of structures will clear all data inside the array of structures!
    ! Use a temporary variable (as in below example) to keep existing data.
    allocate(tmp_grid_ggd(1))
    tmp_grid_ggd(1) = edge_profiles%grid_ggd(1)

    deallocate(edge_profiles%grid_ggd)
    allocate(edge_profiles%grid_ggd(3))
    edge_profiles%grid_ggd = tmp_grid_ggd

    deallocate(tmp_grid_ggd)

    ! single element can be added to AoS the following way
    ! tmp_grid_ggd will be reused in this example
    allocate(tmp_grid_ggd(1))
    tmp_grid_ggd%identifier%name = 'Second test struct'

    ! append aos_element to edge_profiles.grid_ggd AoS
    edge_profiles%grid_ggd(2) = tmp_grid_ggd(2)
    deallocate(tmp_grid_ggd)

    ! common action would be merging two different AoS
    ! edge_profiles2/grid_ggd will be merged with edge_profiles/grid_ggd
    ! first, we have to create new AoS and fill it with data
    allocate(edge_profiles2%grid_ggd(1))
    edge_profiles2%grid_ggd(1)%identifier%name = 'Third test struct'

    ! once data are in place, we can merge two AoS objects
    ! Note: in real-life situation user has to extract starting index from target array.
    ! Since this IDS is created and deleted in this function, we know starting index is 3
    copy_starting_index = 3
    do i = 1, size(edge_profiles2%grid_ggd)
        edge_profiles%grid_ggd(copy_starting_index+i) = edge_profiles2%grid_ggd(i)
    end do

    ! ids fields have default values different for every data type
    write(*,*) 'Default value for INT     data  (edge_profiles/midplane/index)                                 :'&,
     edge_profiles%midplane%index
    write(*,*) 'Default value for FLOAT   data  (edge_profiles/vacuum_toroidal_field/vacuum_toroidal_field/r0) :'&,
     edge_profiles%vacuum_toroidal_field%r0
    write(*,*) 'Default value for COMPLEX data                                                                 :'&,
     IDS_COMPLEX_INVALID
    write(*,*) 'Default value for 1+ dimensional data                                                          :'&,
     edge_profiles%vacuum_toroidal_field%b0

 

    deallocate(edge_profiles)
    deallocate(edge_profiles2)

end subroutine default_values_and_aos_operations









subroutine copying_and_validating_ids()
    use ids_routines
    implicit none

end subroutine copying_and_validating_ids




program main
    print *, 'Hello world!'
    call creating_completly_new_ids()
    !call default_values_and_aos_operations()
end program main