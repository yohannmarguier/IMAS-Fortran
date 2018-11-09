MODULE comparator

use ids_types, only: ids_real
use generator

implicit none

       INTERFACE assertField
              MODULE PROCEDURE &
	      		assertField_INT, assertField_INT1DArray, assertField_INT2DArray, assertField_INT3DArray, assertField_INT4DArray, assertField_INT5DArray, assertField_INT6DArray, &
			assertField_FLT, assertField_FLT1DArray, assertField_FLT2DArray, assertField_FLT3DArray, assertField_FLT4DArray, assertField_FLT5DArray, assertField_FLT6DArray, &
			assertField_STR
       END INTERFACE


LOGICAL, PARAMETER :: debugMode = .FALSE.
INTEGER, PARAMETER :: dim1 = DIM_SIZE, dim2 = DIM_SIZE, dim3 = DIM_SIZE, dim4 = DIM_SIZE, dim5 = DIM_SIZE, dim6 = DIM_SIZE
contains
!


! =================================================================
!              TIME
! =================================================================
  
FUNCTION assertHomogeneousTimeField(observed, isSliceMode, fieldName) RESULT (outValue)
       INTEGER, INTENT (IN)      :: observed 
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName

        LOGICAL    :: outValue
        INTEGER     :: expected

        outValue = .TRUE.
        
         expected = getHomogeneousTime()

        if(observed == expected) then
                if (debugMode) write(*,*) fieldName, " : OK "
        else
                write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
                outValue = .FALSE.
                return
        end if

 END FUNCTION assertHomogeneousTimeField
  
 FUNCTION assertTimeField(observed, isSliceMode, idx, fieldName) RESULT (outValue)
       REAL(ids_real), DIMENSION(:), POINTER      :: observed, expected 
        INTEGER, INTENT (IN)      :: idx 
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName

        LOGICAL    :: outValue

        outValue = .TRUE.
        
        IF(.NOT. associated(observed)) then
                write(*,*) "ERROR: ", fieldName, " is not associated!"
                outValue = .FALSE.
                return
        end if

        IF( isSliceMode ) then
            expected => timeVector(idx:idx)
        ELSE
            expected => timeVector(:DIM1)
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
        

 END FUNCTION assertTimeField
 
! =================================================================
! 		INTEGER
! =================================================================
 FUNCTION assertField_INT(observed, isSliceMode, fieldName) RESULT (outValue)
       INTEGER, INTENT (IN)      :: observed 
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName

	LOGICAL    :: outValue
        INTEGER     :: expected

       	outValue = .TRUE.
       	
       	 expected = getInteger()

	if(observed == expected) then
		if (debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

 END FUNCTION assertField_INT

! =================================================================
FUNCTION assertField_INT1DArray(observed, isSliceMode, fieldName) RESULT (outValue)
      IMPLICIT NONE

	INTEGER, DIMENSION(:), POINTER      :: observed, expected
	    LOGICAL, INTENT (IN)    :: isSliceMode
       	CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue
	
	INTEGER     :: lastDim

  	outValue = .TRUE.
  	
  	
  	
  	

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF
	
	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM1
        END IF
        expected => getInteger1DArray(lastDim)
        

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
FUNCTION assertField_INT2DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE

       	INTEGER, DIMENSION(:,:), POINTER      :: observed, expected
       	    LOGICAL, INTENT (IN)    :: isSliceMode
       	CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue
        INTEGER     :: lastDim
        
  	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	
	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM2
        END IF
        expected => getInteger2DArray(DIM1, lastDim)
        
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
FUNCTION assertField_INT3DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE

       INTEGER, DIMENSION(:,:,:), POINTER      :: observed, expected
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim

       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	
	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM3
        END IF
        expected => getInteger3DArray(DIM1, DIM2, lastDim)
        
        
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
FUNCTION assertField_INT4DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE

       INTEGER, DIMENSION(:,:,:,:), POINTER      :: observed, expected
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF
	
	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM4
        END IF
        expected => getInteger4DArray(DIM1, DIM2, DIM3, lastDim)
        

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
    FUNCTION assertField_INT5DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE

       INTEGER, DIMENSION(:,:,:,:,:), POINTER      :: observed, expected
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName

       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF
	
	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM5
        END IF
        expected => getInteger5DArray(DIM1, DIM2, DIM3, DIM4, lastDim)
        

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
FUNCTION assertField_INT6DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE

       INTEGER, DIMENSION(:,:,:,:,:,:), POINTER      :: observed, expected
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

        IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM6
        END IF
        expected => getInteger6DArray(DIM1, DIM2, DIM3, DIM4, DIM5, lastDim) 
        
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
FUNCTION assertField_FLT(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE

       REAL(ids_real), INTENT (IN)      :: observed
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName

        REAL(ids_real)      :: expected
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.

        expected = getDouble()
        
	if(observed == expected) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
		outValue = .FALSE.
		return
	end if

END FUNCTION assertField_FLT


      ! =================================================================
FUNCTION assertField_FLT1DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE

       REAL(ids_real), DIMENSION(:), POINTER      :: observed, expected
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.

        IF(.NOT. associated(observed)) then
		write(*,*) "ERROR: ", fieldName, " is not associated!"
		outValue = .FALSE.
		return
	end if

	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM1
        END IF
        expected => getDouble1DArray(lastDim)
        

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
  FUNCTION assertField_FLT2DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:), POINTER      :: observed, expected
              LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	
	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM2
        END IF
        expected => getDouble2DArray(DIM1, lastDim)
        
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
  FUNCTION assertField_FLT3DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:,:), POINTER      :: observed, expected
              LOGICAL, INTENT (IN)    :: isSliceMode

       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: Field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

        IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM3
        END IF
        expected => getDouble3DArray(DIM1, DIM2, lastDim)
        
        
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
  FUNCTION assertField_FLT4DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:,:,:), POINTER      :: observed, expected
              LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	
	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM4
        END IF
        expected => getDouble4DArray(DIM1, DIM2, DIM3, lastDim)
        
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
FUNCTION assertField_FLT5DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:,:, :,:), POINTER      :: observed, expected
              LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM5
        END IF
        expected => getDouble5DArray(DIM1, DIM2, DIM3, DIM4, lastDim) 
        
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

  FUNCTION assertField_FLT6DArray(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE
              REAL(ids_real), DIMENSION(:,:,:, :,:,:), POINTER      :: observed, expected
              LOGICAL, INTENT (IN)    :: isSliceMode
        CHARACTER*(*),INTENT(IN) :: fieldName
	LOGICAL    :: outValue
	
	INTEGER :: lastDim
    
       	outValue = .TRUE.


	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	IF( isSliceMode ) then
            lastDim = 1
        ELSE
            lastDim = DIM6
        END IF
	expected => getDouble6DArray(DIM1, DIM2, DIM3, DIM4, DIM5, lastDim) 

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
! 		STRING
! =================================================================
FUNCTION assertField_STR(observed, isSliceMode, fieldName) RESULT (outValue)
       IMPLICIT NONE

       CHARACTER(LEN=132), DIMENSION(:), POINTER      :: observed, expected
       LOGICAL, INTENT (IN)    :: isSliceMode
       CHARACTER*(*),INTENT(IN) :: fieldName
       LOGICAL    :: outValue
       
       INTEGER     :: lastDim


       	outValue = .TRUE.

	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR: field is not associated!!!"
		outValue = .FALSE.
		return
	END IF

	expected => getString()
	if(observed(1) == expected(1)) then
		if(debugMode) write(*,*) fieldName, " : OK "
	else
		write(*,*) fieldName, " : ERROR: observed=", observed,  ", expected=", expected
                outValue = .FALSE.
                return
	end if

END FUNCTION assertField_STR



END MODULE comparator


