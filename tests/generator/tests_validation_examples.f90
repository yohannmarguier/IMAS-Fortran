module validation_example_tests

USE ids_routines
USE comparator, ONLY: assertField_validate 

contains


SUBROUTINE distributions_example_tests
	IMPLICIT NONE
	TYPE (ids_distributions) :: ids 
	CHARACTER (999) :: err_msg = "" 
    CHARACTER(999)  :: expected
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
        WRITE(*,*) "--- --- ---Testing HOMOGENEOUS simplest case Failed"
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
    expected = "Error with distribution."
    expected = trim(expected)//achar(13)//achar(10)//"Error with distribution/profiles_2d."
    expected = trim(expected)//achar(13)//achar(10)//"Coordinate consistency error for distribution/profiles_2d/density (dimension 2). "//&
    "Exactly one of the coordinate must be verified. (distribution(i1)/profiles_2d(itime)/grid/z OR distribution(i1)/profiles_2d(itime)"//&
    "/grid/theta_geometric OR distribution(i1)/profiles_2d(itime)/grid/theta_straight)"
    CALL ids_validate(ids, status, err_msg) 
    isEqual = assertField_validate(err_msg, "distributions",expected)
	IF (.not.isEqual) STOP
	
    !---- Testing HOMOGENEOUS multiple alternative coordinates wrong dim2
    WRITE(*,*) "--- --- Testing HOMOGENEOUS multiple alternative coordinates wrong dim2"
    DO i1=1,max1
        DO i2=1,static_size
            DEALLOCATE(ids%distribution(i1)%profiles_2d(i2)%grid%theta_straight)
            ! density dim2 still wrong
        END DO
    END DO
    expected = "Error with distribution."
    expected = trim(expected)//achar(13)//achar(10)//"Error with distribution/profiles_2d."
    expected = trim(expected)//achar(13)//achar(10)//"Wrong dimension 2 for distribution/profiles_2d/density. "//&
                "(distribution(i1)/profiles_2d(itime)/grid/z OR distribution(i1)/profiles_2d(itime)/grid/theta_geometric "//&
                "OR distribution(i1)/profiles_2d(itime)/grid/theta_straight)"
    CALL ids_validate(ids, status, err_msg)
    isEqual = assertField_validate(err_msg, "distributions",expected)
	IF (.not.isEqual) STOP

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
        WRITE(*,*) "--- --- ---Testing HOMOGENEOUS multiple alternative coordinates fixing dim2 Failed"
        WRITE(*,*) err_msg
        STOP
    END IF

    !---- Testing HOMOGENEOUS multiple alternative coordinates same_as
    WRITE(*,*) "--- --- Testing HOMOGENEOUS multiple alternative coordinates same_as"
    !distribution(i1)/ggd(itime)/grid/grid_subset(i2)/base(i3)/tensor_contravariant
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
    expected = "Error with distribution."
    expected = trim(expected)//achar(13)//achar(10)//"Error with distribution/ggd."
    expected = trim(expected)//achar(13)//achar(10)//"Error with distribution/ggd/grid."
    expected = trim(expected)//achar(13)//achar(10)//"Error with grid_subset."
    expected = trim(expected)//achar(13)//achar(10)//"Error with base."
    expected = trim(expected)//achar(13)//achar(10)//"array_size of tensor_contravariant wrong dimension. Must be the size of tensor_covariant."
    CALL ids_validate(ids, status, err_msg)
    isEqual = assertField_validate(err_msg, "distributions",expected)
	IF (.not.isEqual) STOP

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
        WRITE(*,*) "--- --- ---Testing HETEROGENEOUS time coordinate Failed"
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
    WRITE(*,*) "--- --- Testing HETEROGENEOUS time coordinate"
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
    IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HETEROGENEOUS time coordinate Failed"
        WRITE(*,*) err_msg
        STOP
    END IF

    !---- Garbage collection
    DO i1=1,max1
        DEALLOCATE(ids%distribution(i1)%global_quantities)
        DEALLOCATE(ids%distribution(i1)%profiles_1d)
        DEALLOCATE(ids%distribution(i1)%profiles_2d)
    END DO
    DEALLOCATE(ids%distribution)
    DEALLOCATE(ids%time)
    

END SUBROUTINE distributions_example_tests
    

SUBROUTINE magnetics_example_tests
	IMPLICIT NONE
	TYPE (ids_magnetics) :: ids 
	CHARACTER (999) :: err_msg = "" 
    CHARACTER(999)  :: expected
	INTEGER         :: status 
	LOGICAL         :: isEqual 
    INTEGER         :: static_size = 3
	INTEGER :: i1, i2, i3

    !---- Testing HOMOGENEOUS simplest case
    WRITE(*,*) "--- --- Testing HOMOGENEOUS simplest case"
    ids%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
    ALLOCATE(ids%time(static_size)) 

    CALL ids_validate(ids, status, err_msg) 
	IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HOMOGENEOUS simplest case Failed"
        WRITE(*,*) err_msg
        STOP
    END IF 

    !---- Testing HOMOGENEOUS with wrong fixed coordinate
    WRITE(*,*) "--- --- Testing HOMOGENEOUS with wrong fixed coordinate"
    ALLOCATE(ids%flux_loop(static_size))
    DO i1=1,static_size
        ALLOCATE(ids%flux_loop(i1)%indices_differential(7))
    END DO
    expected = "Error with flux_loop."
    expected = trim(expected)//achar(13)//achar(10)//"array_size of flux_loop/indices_differential wrong dimension 1. Must be 2."
    CALL ids_validate(ids, status, err_msg) 
	isEqual = assertField_validate(err_msg, "magnetics",expected)
	IF (.not.isEqual) STOP
    
    !---- Testing HOMOGENEOUS with wrong data size
    WRITE(*,*) "--- --- Testing HOMOGENEOUS with wrong data size"
    DO i1=1,static_size
        DEALLOCATE(ids%flux_loop(i1)%indices_differential)
        ALLOCATE(ids%flux_loop(i1)%indices_differential(2))
        ALLOCATE(ids%flux_loop(i1)%flux%data(static_size+1))
    END DO

    expected = "Error with flux_loop."
    expected = trim(expected)//achar(13)//achar(10)//"Error with flux_loop/flux."
    expected = trim(expected)//achar(13)//achar(10)//"array_size of data wrong dimension."
    CALL ids_validate(ids, status, err_msg)
    isEqual = assertField_validate(err_msg, "magnetics",expected)
	IF (.not.isEqual) STOP


    !---- Testing HETEROGENEOUS with missing time coordinate
    WRITE(*,*) "--- --- Testing HETEROGENEOUS with missing time coordinate"
    ids%ids_properties%homogeneous_time = IDS_TIME_MODE_HETEROGENEOUS

    expected = "Error with flux_loop."
    expected = trim(expected)//achar(13)//achar(10)//"Error with flux_loop/flux."
    expected = trim(expected)//achar(13)//achar(10)//"signal_flt_1d_validity/time must be allocated."
    CALL ids_validate(ids, status, err_msg)
    isEqual = assertField_validate(err_msg, "magnetics",expected)
	IF (.not.isEqual) STOP


    !---- Testing HETEROGENEOUS by fixing the error
    WRITE(*,*) "--- --- Testing HETEROGENEOUS by fixing the error"
    DO i1=1,static_size
        ALLOCATE(ids%flux_loop(i1)%flux%time(static_size+1))
    END DO
    CALL ids_validate(ids, status, err_msg) 
	IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HETEROGENEOUS by fixing the error Failed"
        WRITE(*,*) err_msg
        STOP
    END IF 

    !---- Testing HETEROGENEOUS advanced usage
    WRITE(*,*) "--- --- Testing HETEROGENEOUS advanced usage"
    ALLOCATE(ids%shunt(5))
    DO i1=1,5
        ALLOCATE(ids%shunt(i1)%voltage%data(4))
        ALLOCATE(ids%shunt(i1)%voltage%time(4))
    END DO
    ALLOCATE(ids%diamagnetic_flux(7))
    DO i1=1,7
        ALLOCATE(ids%diamagnetic_flux(i1)%data(5))
        ALLOCATE(ids%diamagnetic_flux(i1)%time(5))
    END DO
    ALLOCATE(ids%b_field_tor_probe(13))
    ALLOCATE(ids%b_field_pol_probe(13))
    DO i1=1,13
        ALLOCATE(ids%b_field_tor_probe(i1)%field%data(9))
        ALLOCATE(ids%b_field_tor_probe(i1)%field%time(9))
        ALLOCATE(ids%b_field_pol_probe(i1)%field%data(6))
        ALLOCATE(ids%b_field_pol_probe(i1)%field%time(6))
    END DO
    CALL ids_validate(ids, status, err_msg) 
	IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HETEROGENEOUS advanced usage"
        WRITE(*,*) err_msg
        STOP
    END IF

     !---- Testing HETEROGENEOUS logic coordinate consistency
    WRITE(*,*) "--- --- Testing HETEROGENEOUS logic coordinate consistency"
    DO i1=1,13
        ALLOCATE(ids%b_field_pol_probe(i1)%non_linear_response%b_field_linear(3))
        ALLOCATE(ids%b_field_pol_probe(i1)%non_linear_response%b_field_non_linear(4))
    END DO
    expected = "Error with b_field_pol_probe."
    expected = trim(expected)//achar(13)//achar(10)//"Error with bpol_probe/non_linear_response."
    expected = trim(expected)//achar(13)//achar(10)//"Wrong dimension 1 for bpol_probe/non_linear_response/b_field_non_linear."&
                //" (bpol_probe(i1)/non_linear_response/b_field_linear)"
    CALL ids_validate(ids, status, err_msg) 
    isEqual = assertField_validate(err_msg, "magnetics",expected)
	IF (.not.isEqual) STOP

    !---- Garbage collection
    DO i1=1,13
        DEALLOCATE(ids%b_field_pol_probe(i1)%non_linear_response%b_field_linear)
        DEALLOCATE(ids%b_field_pol_probe(i1)%non_linear_response%b_field_non_linear)
        DEALLOCATE(ids%b_field_tor_probe(i1)%field%data)
        DEALLOCATE(ids%b_field_tor_probe(i1)%field%time)
        DEALLOCATE(ids%b_field_pol_probe(i1)%field%data)
        DEALLOCATE(ids%b_field_pol_probe(i1)%field%time)
    END DO
    DEALLOCATE(ids%b_field_tor_probe)
    DEALLOCATE(ids%b_field_pol_probe)
    DO i1=1,5
        DEALLOCATE(ids%shunt(i1)%voltage%data)
        DEALLOCATE(ids%shunt(i1)%voltage%time)
    END DO
    DEALLOCATE(ids%shunt)
    DO i1=1,7
        DEALLOCATE(ids%diamagnetic_flux(i1)%data)
        DEALLOCATE(ids%diamagnetic_flux(i1)%time)
    END DO
    DEALLOCATE(ids%diamagnetic_flux)
    DO i1=1,static_size
        DEALLOCATE(ids%flux_loop(i1)%indices_differential)
        DEALLOCATE(ids%flux_loop(i1)%flux%data)
        DEALLOCATE(ids%flux_loop(i1)%flux%time)
    END DO
    DEALLOCATE(ids%flux_loop)
    DEALLOCATE(ids%time)

END SUBROUTINE magnetics_example_tests



END MODULE