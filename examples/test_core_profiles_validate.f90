PROGRAM test_core_profiles_validate
    USE al_defs 
    USE ids_schemas_core_profiles
    USE core_profiles_put_struct
    USE core_profiles_put_slice_struct
    USE core_profiles_get_struct
    USE core_profiles_get_slice_struct
    USE core_profiles_delete
    USE core_profiles_copy_struct
    USE core_profiles_deallocate_struct
    USE core_profiles_validate_struct
    IMPLICIT NONE
    INTEGER :: status
    TYPE(ids_core_profiles) :: core_profiles
    CHARACTER(:), ALLOCATABLE :: err_msg


    WRITE(*,*) "--- --- Testing HETEROGENEOUS scalar time coordinate issue"
    core_profiles%ids_properties%homogeneous_time = IDS_TIME_MODE_HETEROGENEOUS
    allocate(core_profiles%profiles_1d(1)) !! core_profiles%profiles_1d(1)%time must be valid
    CALL ids_validate(core_profiles, status, err_msg)

    IF (status==0) STOP "Error expected"

    WRITE(*,*) "--- --- Testing HETEROGENEOUS scalar time coordinate fixed issue"
    core_profiles%profiles_1d(1)%time = 0.1

    CALL ids_validate(core_profiles, status, err_msg)
	IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HETEROGENEOUS scalar time coordinate fixed Failed (error)"
        WRITE(*,*) err_msg
        STOP
    END IF 

    !---- Garbage collection
    call ids_deallocate(core_profiles)


END PROGRAM test_core_profiles_validate
