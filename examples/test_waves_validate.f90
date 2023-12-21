PROGRAM test_waves_validate
    USE al_defs 
    USE ids_schemas_waves
	USE waves_put_struct
	USE waves_put_slice_struct
	USE waves_get_struct
	USE waves_get_slice_struct
	USE waves_delete
	USE waves_copy_struct
	USE waves_deallocate_struct
	USE waves_validate_struct
	IMPLICIT NONE
	TYPE (ids_waves) :: ids 
    CHARACTER(:), allocatable :: err_msg
	INTEGER         :: status 
    INTEGER         :: static_size = 3
	INTEGER :: i1, i2, i3, itime
    INTEGER :: max1 = 5
    INTEGER :: max2 = 4
    INTEGER :: max3 = 3
    INTEGER :: max_dim = 8

    !---- Testing HOMOGENEOUS simplest case
    WRITE(*,*) "--- --- Testing HOMOGENEOUS simplest case"
    ids%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
    ALLOCATE(ids%time(static_size)) 

    CALL ids_validate(ids, status, err_msg) 
	IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HOMOGENEOUS simplest case Failed (error)"
        WRITE(*,*) err_msg
        STOP
    END IF 

    !---- Testing HOMOGENEOUS multiple alternative coordinates
    WRITE(*,*) "--- --- Testing HOMOGENEOUS alternative/fixed coordinates"
    ALLOCATE(ids%coherent_wave(max1))
    DO i1=1, max1 
        ALLOCATE(ids%coherent_wave(i1)%beam_tracing(max_dim))
        DO itime=1, max_dim
            ALLOCATE(ids%coherent_wave(i1)%beam_tracing(itime)%beam(max2))
            DO i2=1, max2 
                ALLOCATE(ids%coherent_wave(i1)%beam_tracing(itime)%beam(i2)%wave_vector%n_tor(5))
            END DO
        END DO
    END DO
    CALL ids_validate(ids, status, err_msg)
	IF (status==0) STOP "Error expected"


    !---- Garbage collection
    call ids_deallocate(ids)

END PROGRAM test_waves_validate