PROGRAM test_distributions_validate
    USE al_defs 
    USE ids_schemas_distributions
	USE distributions_put_struct
	USE distributions_put_slice_struct
	USE distributions_get_struct
	USE distributions_get_slice_struct
	USE distributions_delete
	USE distributions_copy_struct
	USE distributions_deallocate_struct
	USE distributions_validate_struct
	IMPLICIT NONE
	TYPE (ids_distributions) :: ids 
    CHARACTER(:), allocatable :: err_msg
	INTEGER         :: status 
	LOGICAL         :: isEqual 
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
    WRITE(*,*) "--- --- Testing HOMOGENEOUS multiple alternative coordinates"
    ALLOCATE(ids%distribution(max1))
    DO i1=1,max1
        ALLOCATE(ids%distribution(i1)%profiles_2d(static_size))
        DO i2=1,static_size
            ALLOCATE(ids%distribution(i1)%profiles_2d(i2)%grid%r(max_dim))
            ALLOCATE(ids%distribution(i1)%profiles_2d(i2)%grid%z(max_dim))
            ALLOCATE(ids%distribution(i1)%profiles_2d(i2)%grid%theta_straight(max_dim)) ! theta_straight and z should not be both associated
            ALLOCATE(ids%distribution(i1)%profiles_2d(i2)%density(max_dim,2))
        END DO
    END DO
    CALL ids_validate(ids, status, err_msg) 
	IF (status==0) STOP "Error expected"
	
    !---- Testing HOMOGENEOUS multiple alternative coordinates wrong dim2
    WRITE(*,*) "--- --- Testing HOMOGENEOUS multiple alternative coordinates wrong dim2"
    DO i1=1,max1
        DO i2=1,static_size
            DEALLOCATE(ids%distribution(i1)%profiles_2d(i2)%grid%theta_straight)
            ! density dim2 still wrong
        END DO
    END DO
    CALL ids_validate(ids, status, err_msg)
	IF (status==0) STOP "Error expected"

    !---- Testing HOMOGENEOUS multiple alternative coordinates fixing dim2
    WRITE(*,*) "--- --- Testing HOMOGENEOUS multiple alternative coordinates fixing dim2"
    DO i1=1,max1
        DO i2=1,static_size
            DEALLOCATE(ids%distribution(i1)%profiles_2d(i2)%density)
            ALLOCATE(ids%distribution(i1)%profiles_2d(i2)%density(max_dim,max_dim)) ! now density has the good dim2
        END DO
    END DO
    CALL ids_validate(ids, status, err_msg)
    IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HOMOGENEOUS multiple alternative coordinates fixing dim2 Failed (error)"
        WRITE(*,*) err_msg
        STOP
    END IF

    !---- Testing HOMOGENEOUS multiple alternative coordinates same_as
    WRITE(*,*) "--- --- Testing HOMOGENEOUS multiple alternative coordinates same_as"
    DO i1=1,max1
        ALLOCATE(ids%distribution(i1)%ggd(static_size))
        DO itime=1,static_size
            ALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(max2))
            DO i2=1,max2
                ALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%base(max3))
                ALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%element(max_dim))
                DO i3=1,max3 
                    ALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%base(i3)%tensor_covariant(max_dim,max_dim,max_dim))
                    ALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%base(i3)%tensor_contravariant(max_dim,max_dim,max_dim+1))
                END DO
            END DO
        END DO
    END DO
    CALL ids_validate(ids, status, err_msg)
	IF (status==0) STOP "Error expected"

    !---- Testing HOMOGENEOUS multiple alternative coordinates same_as fix
    WRITE(*,*) "--- --- Testing HOMOGENEOUS multiple alternative coordinates same_as fix"
    DO i1=1,max1
        DO itime=1,static_size
            DO i2=1,max2
                DO i3=1,max3 
                    DEALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%base(i3)%tensor_contravariant)
                    ALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%base(i3)%tensor_contravariant(max_dim,max_dim,max_dim))
                END DO
            END DO
        END DO
    END DO

    CALL ids_validate(ids, status, err_msg)
    IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HOMOGENEOUS multiple alternative coordinates same_as fix Failed (error)"
        WRITE(*,*) err_msg
        STOP
    END IF

    !---- Garbage collection
    DO i1=1,max1
        DO itime=1,static_size
            DO i2=1,max2
                DO i3=1,max3 
                    DEALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%base(i3)%tensor_covariant)
                    DEALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%base(i3)%tensor_contravariant)
                END DO
                DEALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%base)
                DEALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset(i2)%element)
            END DO
            DEALLOCATE(ids%distribution(i1)%ggd(itime)%grid%grid_subset)
        END DO
        DEALLOCATE(ids%distribution(i1)%ggd)
    END DO
    
    !---- Testing HETEROGENEOUS time coordinate
    WRITE(*,*) "--- --- Testing HETEROGENEOUS scalar time coordinate"
    ids%ids_properties%homogeneous_time = IDS_TIME_MODE_HETEROGENEOUS
    DO i1=1,max1
        DO i2=1,static_size
            DEALLOCATE(ids%distribution(i1)%profiles_2d(i2)%density)
            DEALLOCATE(ids%distribution(i1)%profiles_2d(i2)%grid%r)
            DEALLOCATE(ids%distribution(i1)%profiles_2d(i2)%grid%z)
        END DO
        DEALLOCATE(ids%distribution(i1)%profiles_2d)
        ALLOCATE(ids%distribution(i1)%global_quantities(static_size+1)) ! here the time coordinate should not raise an error
        ALLOCATE(ids%distribution(i1)%profiles_1d(static_size+2)) ! here the time coordinate should not raise an error
        ALLOCATE(ids%distribution(i1)%profiles_2d(static_size+3)) ! here the time coordinate should not raise an error
    END DO
    CALL ids_validate(ids, status, err_msg)
	IF (status==0) STOP "Error expected"

    WRITE(*,*) "--- --- Testing HETEROGENEOUS scalar time coordinate fixing"
    DO i1=1,max1
        DO itime=1,static_size+1
        ids%distribution(i1)%global_quantities(itime)%time = 0.1*itime ! now the value of 'time' is valid
        END DO
        DO itime=1,static_size+2
        ids%distribution(i1)%profiles_1d(itime)%time = 0.1*itime ! now the value of 'time' is valid
        END DO
        DO itime=1,static_size+3
        ids%distribution(i1)%profiles_2d(itime)%time = 0.1*itime ! now the value of 'time' is valid
        END DO
    END DO
    CALL ids_validate(ids, status, err_msg)
    IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HETEROGENEOUS scalar time coordinate Failed (error)"
        WRITE(*,*) err_msg
        STOP
    END IF

    !---- Garbage collection
    call ids_deallocate(ids)

END PROGRAM test_distributions_validate