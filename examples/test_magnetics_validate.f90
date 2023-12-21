PROGRAM test_magnetics_validate
    USE al_defs 
    USE ids_schemas_magnetics
	USE magnetics_put_struct
	USE magnetics_put_slice_struct
	USE magnetics_get_struct
	USE magnetics_get_slice_struct
	USE magnetics_delete
	USE magnetics_copy_struct
	USE magnetics_deallocate_struct
	USE magnetics_validate_struct
	IMPLICIT NONE
	TYPE (ids_magnetics) :: ids  
    CHARACTER(:), allocatable :: err_msg
	INTEGER         :: status 
    INTEGER         :: static_size = 3
	INTEGER :: i1, i2, i3

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

    !---- Testing HOMOGENEOUS with wrong fixed coordinate
    WRITE(*,*) "--- --- Testing HOMOGENEOUS with wrong fixed coordinate"
    ALLOCATE(ids%flux_loop(static_size))
    DO i1=1,static_size
        ALLOCATE(ids%flux_loop(i1)%indices_differential(7))
    END DO

    CALL ids_validate(ids, status, err_msg)
	IF (status==0) STOP "Error expected"
    
    !---- Testing HOMOGENEOUS with wrong data size
    WRITE(*,*) "--- --- Testing HOMOGENEOUS with wrong data size"
    DO i1=1,static_size
        DEALLOCATE(ids%flux_loop(i1)%indices_differential)
        ALLOCATE(ids%flux_loop(i1)%indices_differential(2))
        ALLOCATE(ids%flux_loop(i1)%flux%data(static_size+1))
    END DO

    CALL ids_validate(ids, status, err_msg)
	IF (status==0) STOP "Error expected"


    !---- Testing HETEROGENEOUS with missing time coordinate
    WRITE(*,*) "--- --- Testing HETEROGENEOUS with missing time coordinate"
    ids%ids_properties%homogeneous_time = IDS_TIME_MODE_HETEROGENEOUS

    CALL ids_validate(ids, status, err_msg)
	IF (status==0) STOP "Error expected"


    !---- Testing HETEROGENEOUS by fixing the error
    WRITE(*,*) "--- --- Testing HETEROGENEOUS by fixing the issue"
    DO i1=1,static_size
        ALLOCATE(ids%flux_loop(i1)%flux%time(static_size+1))
    END DO
    CALL ids_validate(ids, status, err_msg)
	IF (status .ne. 0) THEN
        WRITE(*,*) "--- --- ---Testing HETEROGENEOUS by fixing the issue Failed (error)"
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
        WRITE(*,*) "--- --- ---Testing HETEROGENEOUS advanced usage (error)"
        WRITE(*,*) err_msg
        STOP
    END IF

     !---- Testing HETEROGENEOUS logic coordinate consistency
    WRITE(*,*) "--- --- Testing HETEROGENEOUS logic coordinate consistency"
    DO i1=1,13
        ALLOCATE(ids%b_field_pol_probe(i1)%non_linear_response%b_field_linear(3))
        ALLOCATE(ids%b_field_pol_probe(i1)%non_linear_response%b_field_non_linear(4))
    END DO
    CALL ids_validate(ids, status, err_msg)

	IF (status==0) STOP "Error expected"

    !---- Garbage collection
    call ids_deallocate(ids)
    
    CONTAINS 

    ! =================================================================
    ! 		VALIDATION MESSAGE
    ! =================================================================
    FUNCTION assertField_validate(observed, idsName, expected) RESULT (outValue)
    IMPLICIT NONE

    CHARACTER(:), ALLOCATABLE, INTENT(IN) :: observed
    CHARACTER(999) ,INTENT(IN) :: expected
    CHARACTER(*) ,INTENT(IN) :: idsName
    LOGICAL    :: outValue
    INTEGER     :: lastDim

    outValue = .TRUE.

    if(observed == expected) then
    else
    write(*,*) idsName, " : ERROR:"
    write(*,*) "observed=", observed
    write(*,*) "expected=", trim(expected)
                outValue = .FALSE.
                return
    end if
    END FUNCTION assertField_validate

END PROGRAM test_magnetics_validate