MODULE comparator

use ids_schemas
use ids_routines

implicit none

       INTERFACE assertField
              MODULE PROCEDURE &
	      		assertField_INT, assertField_INT1DArray, assertField_INT2DArray, assertField_INT3DArray, assertField_INT4DArray, assertField_INT5DArray, assertField_INT6DArray, &
			assertField_FLT, assertField_FLT1DArray, assertField_FLT2DArray, assertField_FLT3DArray, assertField_FLT4DArray, assertField_FLT5DArray, assertField_FLT6DArray, &
			assertField_CPLX, assertField_CPLX1DArray, assertField_CPLX2DArray, assertField_CPLX3DArray, assertField_CPLX4DArray, assertField_CPLX5DArray, assertField_CPLX6DArray,&
			assertField_STR
       END INTERFACE


LOGICAL, PARAMETER :: debugMode = .FALSE.
contains
!
! =================================================================
! 		INTEGER
! =================================================================
 FUNCTION assertField_INT(observed, expected, fieldName) RESULT (outValue)
       INTEGER, INTENT (IN)      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName

	LOGICAL    :: outValue

       	outValue = .TRUE.

	if(observed == expected) then
		if (debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

 END FUNCTION assertField_INT

! =================================================================
FUNCTION assertField_INT1DArray(observed, expected, fieldName) RESULT (outValue)
      IMPLICIT NONE

	INTEGER, DIMENSION(:), POINTER      :: observed, expected
       	CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

  	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_INT1DArray

       ! =================================================================
FUNCTION assertField_INT2DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       	INTEGER, DIMENSION(:,:), POINTER      :: observed, expected
       	CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

  	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if


	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_INT2DArray

! =================================================================
FUNCTION assertField_INT3DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       INTEGER, DIMENSION(:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_INT3DArray
       ! =================================================================
FUNCTION assertField_INT4DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       INTEGER, DIMENSION(:,:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
		LOGICAL    :: outValue

       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_INT4DArray
       ! =================================================================
    FUNCTION assertField_INT5DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       INTEGER, DIMENSION(:,:,:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName

	LOGICAL    :: outValue

       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_INT5DArray
       ! =================================================================
FUNCTION assertField_INT6DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       INTEGER, DIMENSION(:,:,:,:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF


	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_INT6DArray

! =================================================================
! 		Float
! =================================================================
FUNCTION assertField_FLT(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       REAL(ids_real), INTENT (IN)      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName

       	LOGICAL    :: outValue

       	outValue = .TRUE.


	if(observed == expected) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_FLT


      ! =================================================================
FUNCTION assertField_FLT1DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       REAL(ids_real), DIMENSION(:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

       	outValue = .TRUE.

        IF(.NOT. associated(observed)) then
		write(*,*) "ERROR: ", fieldName, " is not associated!"
		outValue = .FALSE.
		return
	end if


	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_FLT1DArray

        ! =================================================================
  FUNCTION assertField_FLT2DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

       	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_FLT2DArray


        ! =================================================================
  FUNCTION assertField_FLT3DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:,:), POINTER      :: observed, expected

       CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

       	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: Field is not associated!!!"
		outValue = .FALSE.
		return
	END IF


	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_FLT3DArray

         ! =================================================================
  FUNCTION assertField_FLT4DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

       	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_FLT4DArray

      ! =================================================================
FUNCTION assertField_FLT5DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:,:, :,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       	LOGICAL    :: outValue

       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

	 ! =================================================================
END FUNCTION assertField_FLT5DArray

  FUNCTION assertField_FLT6DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:,:, :,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

       	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_FLT6DArray


! =================================================================
! 		COMPLEX
! =================================================================
       FUNCTION assertField_CPLX(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       COMPLEX(ids_real), INTENT (IN)      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
     	outValue = .TRUE.

	if(observed == expected) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

       END FUNCTION assertField_CPLX

       ! =================================================================
       FUNCTION assertField_CPLX1DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       COMPLEX(ids_real), DIMENSION(:), POINTER   :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue

 	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

       END FUNCTION assertField_CPLX1DArray
       ! =================================================================
       FUNCTION assertField_CPLX2DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       COMPLEX(ids_real), DIMENSION(:,:), POINTER    :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue

 	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

       END FUNCTION assertField_CPLX2DArray
       ! =================================================================

       FUNCTION assertField_CPLX3DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       COMPLEX(ids_real), DIMENSION(:,:,:), POINTER    :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue

 	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

       END FUNCTION assertField_CPLX3DArray


       FUNCTION assertField_CPLX4DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE
       ! =================================================================
       COMPLEX(ids_real), DIMENSION(:,:,:,:), POINTER  :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL :: outValue


 	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

       END FUNCTION assertField_CPLX4DArray

! ====================================================================================
       FUNCTION assertField_CPLX5DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       COMPLEX(ids_real), DIMENSION(:,:,:, :,:), POINTER    :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       	LOGICAL    :: outValue

 	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

       END FUNCTION assertField_CPLX5DArray
        ! =================================================================
       FUNCTION assertField_CPLX6DArray(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       COMPLEX(ids_real), DIMENSION(:,:,:, :,:,:), POINTER    :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue

 	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF(.NOT. ALL(shape(observed).EQ.shape( expected))) then
		write(*,*) fieldName, " : ERROR: Incorrect array shape:, observed=/", shape(observed),  "/, expected=/", shape(expected), "/"
		outValue = .FALSE.
		return
	end if

        IF(size(observed) .NE. size(expected)) then
		write(*,*) fieldName, " : ERROR: Array size differs!"
		outValue = .FALSE.
		return
	end if

	IF(ALL(observed.EQ.expected)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

       END FUNCTION assertField_CPLX6DArray
! =================================================================
! 		STRING
! =================================================================
FUNCTION assertField_STR(observed, expected, fieldName) RESULT (outValue)
       IMPLICIT NONE

       CHARACTER(LEN=132), DIMENSION(:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue

       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	if(observed(1) == expected(1)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
                outValue = .FALSE.
                return
	end if

END FUNCTION assertField_STR



END MODULE comparator


