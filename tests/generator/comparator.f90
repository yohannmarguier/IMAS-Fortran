MODULE comparator

use ids_schemas
use ids_routines

implicit none

       INTERFACE assertField
              MODULE PROCEDURE &
	      		assertField_INT, assertField_INT1DArray, assertField_INT2DArray, assertField_INT3DArray, assertField_INT4DArray, assertField_INT5DArray, assertField_INT6DArray,&
			assertField_FLT, assertField_FLT1DArray, assertField_FLT2DArray, assertField_FLT3DArray, assertField_FLT4DArray, assertField_FLT5DArray, assertField_FLT6DArray,&
			assertField_STR
       END INTERFACE
CONTAINS

! =================================================================
! 		INTEGER 
! =================================================================
       SUBROUTINE assertField_INT(observed, expected, fieldName)
       IMPLICIT NONE
       
       INTEGER, INTENT (IN)      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	if(observed == expected) then
	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_INT
! =================================================================
       SUBROUTINE assertField_INT1DArray(observed, expected, fieldName)
       IMPLICIT NONE
       
       INTEGER, DIMENSION(:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_INT1DArray
       ! =================================================================
       SUBROUTINE assertField_INT2DArray(observed, expected, fieldName)
       IMPLICIT NONE
       
       INTEGER, DIMENSION(:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_INT2DArray
       ! =================================================================
       SUBROUTINE assertField_INT3DArray(observed, expected, fieldName)
       IMPLICIT NONE
       
       INTEGER, DIMENSION(:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_INT3DArray
       ! =================================================================
       SUBROUTINE assertField_INT4DArray(observed, expected, fieldName)
       IMPLICIT NONE
       
       INTEGER, DIMENSION(:,:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_INT4DArray
       ! =================================================================
           SUBROUTINE assertField_INT5DArray(observed, expected, fieldName)
       IMPLICIT NONE
       
       INTEGER, DIMENSION(:,:,:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_INT5DArray
       ! =================================================================
       SUBROUTINE assertField_INT6DArray(observed, expected, fieldName)
       IMPLICIT NONE
       
       INTEGER, DIMENSION(:,:,:,:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_INT6DArray
       
! =================================================================
! 		Float
! =================================================================
       SUBROUTINE assertField_FLT(observed, expected, fieldName)
       IMPLICIT NONE
       
       REAL(DP), INTENT (IN)      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
		if(observed == expected) then
	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_FLT
       
       SUBROUTINE assertField_FLT1DArray(observed, expected, fieldName)
       IMPLICIT NONE
       
       REAL(DP), DIMENSION(:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       
        IF(.NOT. associated(observed)) then
		write(*,*) "Error! ", fieldName, " is not associated!"
		return
	end if
	
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_FLT1DArray
       
        ! =================================================================
         SUBROUTINE assertField_FLT2DArray(observed, expected, fieldName)
       IMPLICIT NONE
              REAL(DP), DIMENSION(:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_FLT2DArray
       
       
         SUBROUTINE assertField_FLT3DArray(observed, expected, fieldName)
       IMPLICIT NONE
              REAL(DP), DIMENSION(:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_FLT3DArray
       
         ! =================================================================
         SUBROUTINE assertField_FLT4DArray(observed, expected, fieldName)
       IMPLICIT NONE
              REAL(DP), DIMENSION(:,:,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_FLT4DArray
        
      ! =================================================================
       SUBROUTINE assertField_FLT5DArray(observed, expected, fieldName)
       IMPLICIT NONE
              REAL(DP), DIMENSION(:,:,:, :,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
	 ! =================================================================
       END SUBROUTINE assertField_FLT5DArray
        
         SUBROUTINE assertField_FLT6DArray(observed, expected, fieldName)
       IMPLICIT NONE
              REAL(DP), DIMENSION(:,:,:, :,:,:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	IF(ALL(observed.EQ.expected)) then

	write(*,*) fieldName, " : OK "
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_FLT6DArray

       
! =================================================================
! 		STRING 
! =================================================================
       SUBROUTINE assertField_STR(observed, expected, fieldName)
       IMPLICIT NONE
       
       CHARACTER(LEN=132), DIMENSION(:), POINTER      :: observed, expected
       CHARACTER*(*),INTENT(IN) :: fieldName
       	
	IF(.not. associated(observed)) then
		write(*,*) fieldName, " : ERROR, field is not associated!!!"
		return
	END IF
	
	if(observed(1) == expected(1)) then
	write(*,*) fieldName, " : OK"
	  
	  else
	write(*,*) fieldName, " : error, observed=", observed,  ", expected=", expected
	
	end if
	
       END SUBROUTINE assertField_STR
       
END MODULE comparator


