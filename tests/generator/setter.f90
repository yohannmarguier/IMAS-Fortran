MODULE setter

use ids_types, only: ids_real
use test_defs
use generator

implicit none

       INTERFACE initField
              MODULE PROCEDURE &
	      		initField_INT, initField_INT1DArray, initField_INT2DArray, initField_INT3DArray, initField_INT4DArray, initField_INT5DArray, initField_INT6DArray, &
			initField_FLT, initField_FLT1DArray, initField_FLT2DArray, initField_FLT3DArray, initField_FLT4DArray, initField_FLT5DArray, initField_FLT6DArray, &
			initField_CPX, initField_CPX1DArray, initField_CPX2DArray, initField_CPX3DArray, initField_CPX4DArray, initField_CPX5DArray, initField_CPX6DArray,&
			initField_STR
       END INTERFACE

contains
  
SUBROUTINE initTimeField(idsField, isSliceMode, idx)
    IMPLICIT NONE  
    REAL(ids_real), DIMENSION(:), POINTER :: idsField
    LOGICAL, INTENT (IN)    :: isSliceMode
    INTEGER, INTENT(IN)     :: idx 

       
    IF(isSliceMode) then
            allocate(idsField(1))
            idsField = timeVector(idx:idx)
        ELSE
            allocate(idsField(config%timeSize))
            idsField = timeVector(:config%timeSize)
        END IF
        
END SUBROUTINE initTimeField
  

SUBROUTINE initTimeFieldScalar(idsField, isSliceMode, idx)
    IMPLICIT NONE  
    REAL(ids_real) :: idsField
    LOGICAL, INTENT (IN)    :: isSliceMode
    INTEGER, INTENT(IN)     :: idx 


        IF(idx < 1) then
             idsField = timeVector(1)
        ELSE
            idsField = timeVector(idx)
        END IF

END SUBROUTINE initTimeFieldScalar
  
!
! ===============================================================================================
! ===============================================================================================
!                                       INTEGER
! ===============================================================================================
! ===============================================================================================


SUBROUTINE initField_INT(idsField, isSliceMode)
    IMPLICIT NONE  
    INTEGER, INTENT (INOUT)  :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

    idsField = getInteger()

END SUBROUTINE initField_INT

! =================================================================

SUBROUTINE initField_INT1DArray(idsField, isSliceMode)
    IMPLICIT NONE     
    INTEGER, DIMENSION(:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
    
    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
  
    idsField => getInteger1DArray(lastDim)     

END SUBROUTINE initField_INT1DArray

! ===========================================================================

SUBROUTINE initField_INT2DArray(idsField, isSliceMode)
    IMPLICIT NONE

    INTEGER, DIMENSION(:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
           INTEGER :: lastDim

    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
    
    idsField => getInteger2DArray(dim1, lastDim)

END SUBROUTINE initField_INT2DArray

! =================================================================

SUBROUTINE initField_INT3DArray(idsField, isSliceMode)
    IMPLICIT NONE
    INTEGER, DIMENSION(:,:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
                   INTEGER :: lastDim

    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
    
    idsField => getInteger3DArray(dim1, dim2, lastDim)

END SUBROUTINE initField_INT3DArray

! ===========================================================================

SUBROUTINE initField_INT4DArray(idsField, isSliceMode)
    IMPLICIT NONE
    INTEGER, DIMENSION(:,:,:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
    
    idsField => getInteger4DArray(dim1, dim2, dim3, lastDim)


END SUBROUTINE initField_INT4DArray

! ===========================================================================

SUBROUTINE initField_INT5DArray(idsField, isSliceMode)
    IMPLICIT NONE
    INTEGER, DIMENSION(:,:,:,:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
    
    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF       

    idsField => getInteger5DArray(dim1, dim2, dim3, dim4, lastDim)

END SUBROUTINE initField_INT5DArray

! ===========================================================================

SUBROUTINE initField_INT6DArray(idsField, isSliceMode)
    IMPLICIT NONE
    INTEGER, DIMENSION(:,:,:,:,:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
    
    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
    
    idsField => getInteger6DArray(dim1, dim2, dim3, dim4, dim5, lastDim)

END SUBROUTINE initField_INT6DArray


! ===============================================================================================
! ===============================================================================================
!                                       FLOAT
! ===============================================================================================
! ===============================================================================================


SUBROUTINE initField_FLT(idsField, isSliceMode)
    IMPLICIT NONE
    REAL(ids_real), INTENT (INOUT):: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
    
    idsField = getDouble()

END SUBROUTINE initField_FLT

! =================================================================

SUBROUTINE initField_FLT1DArray(idsField, isSliceMode)
    IMPLICIT NONE
    REAL(ids_real), DIMENSION(:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

    INTEGER :: lastDim
    
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF

    idsField => getDouble1DArray(lastDim)
    
END SUBROUTINE initField_FLT1DArray

 ! ===========================================================================

 SUBROUTINE initField_FLT2DArray(idsField, isSliceMode)
    IMPLICIT NONE
    REAL(ids_real), DIMENSION(:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

    INTEGER :: lastDim
    
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF

    idsField => getDouble2DArray(dim1, lastDim)

END SUBROUTINE initField_FLT2DArray

! ===========================================================================

SUBROUTINE initField_FLT3DArray(idsField, isSliceMode)
    IMPLICIT NONE
    REAL(ids_real), DIMENSION(:,:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
    
    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
                
    idsField => getDouble3DArray(dim1, dim2,  lastDim)
    
END SUBROUTINE initField_FLT3DArray

! ===========================================================================

SUBROUTINE initField_FLT4DArray(idsField, isSliceMode)
    IMPLICIT NONE
    REAL(ids_real), DIMENSION(:,:,:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
 
    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
    
    idsField => getDouble4DArray(dim1, dim2, dim3, lastDim)

END SUBROUTINE initField_FLT4DArray

! =================================================================

SUBROUTINE initField_FLT5DArray(idsField, isSliceMode)
    IMPLICIT NONE
    REAL(ids_real), DIMENSION(:,:,:, :,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
    
    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
    
    idsField => getDouble5DArray(dim1, dim2, dim3, dim4, lastDim)

END SUBROUTINE initField_FLT5DArray

! ===========================================================================

SUBROUTINE initField_FLT6DArray(idsField, isSliceMode)
    IMPLICIT NONE
    REAL(ids_real), DIMENSION(:,:,:, :,:,:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
        
    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF       
    
    idsField => getDouble6DArray(dim1, dim2, dim3, dim4, dim5, lastDim)

END SUBROUTINE initField_FLT6DArray


! ===============================================================================================
! ===============================================================================================
!                                       COMPLEX
! ===============================================================================================
! ===============================================================================================


SUBROUTINE initField_CPX(idsField, isSliceMode)
    IMPLICIT NONE
    COMPLEX(ids_real), INTENT (INOUT)      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

    idsField = getComplex()

END SUBROUTINE initField_CPX

! ===========================================================================

SUBROUTINE initField_CPX1DArray(idsField, isSliceMode)
    IMPLICIT NONE
    COMPLEX(ids_real), DIMENSION(:), POINTER   :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

    INTEGER :: lastDim
    
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
        
    
    idsField => getComplex1DArray(lastDim)

END SUBROUTINE initField_CPX1DArray

! ===========================================================================

SUBROUTINE initField_CPX2DArray(idsField, isSliceMode)
    IMPLICIT NONE
    COMPLEX(ids_real), DIMENSION(:,:), POINTER    :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

    INTEGER :: lastDim
    
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
            
    
    idsField => getComplex2DArray(dim1, lastDim)

END SUBROUTINE initField_CPX2DArray

! ===========================================================================

SUBROUTINE initField_CPX3DArray(idsField, isSliceMode)
    IMPLICIT NONE
    COMPLEX(ids_real), DIMENSION(:,:,:), POINTER    :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

    INTEGER :: lastDim
 
    IF( isSliceMode ) then
        lastDim = 1
    ELSE
        lastDim = config%timeSize
    END IF
                
    
    idsField => getComplex3DArray(dim1, dim2,  lastDim)

END SUBROUTINE initField_CPX3DArray

! ===========================================================================
       
SUBROUTINE initField_CPX4DArray(idsField, isSliceMode)
    IMPLICIT NONE
    COMPLEX(ids_real), DIMENSION(:,:,:,:), POINTER  :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

END SUBROUTINE initField_CPX4DArray

! ====================================================================================

SUBROUTINE initField_CPX5DArray(idsField, isSliceMode)
    IMPLICIT NONE
    COMPLEX(ids_real), DIMENSION(:,:,:, :,:), POINTER    :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

END SUBROUTINE initField_CPX5DArray

 ! ===========================================================================

SUBROUTINE initField_CPX6DArray(idsField, isSliceMode)
    IMPLICIT NONE
    COMPLEX(ids_real), DIMENSION(:,:,:, :,:,:), POINTER    :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode

END SUBROUTINE initField_CPX6DArray

! ===============================================================================================
! ===============================================================================================
!                                       STRING
! ===============================================================================================
! ===============================================================================================

SUBROUTINE initField_STR(idsField, isSliceMode)
    IMPLICIT NONE
    CHARACTER(LEN=132), DIMENSION(:), POINTER      :: idsField
    LOGICAL, INTENT (IN)  :: isSliceMode
 
    idsField => getString()   

END SUBROUTINE initField_STR



END MODULE setter


