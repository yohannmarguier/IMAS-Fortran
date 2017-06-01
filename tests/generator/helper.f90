MODULE helper
use ids_schemas
use ids_routines

implicit none

INTEGER, PARAMETER :: DIM_SIZE = 2
INTEGER, PARAMETER :: TESTSHOT = 9998
INTEGER, PARAMETER :: TESTRUN = 9998
INTEGER, PARAMETER :: SEED(9) = (/1,2,3,4,5,6,7,8,9/)




CHARACTER (LEN=*), PARAMETER ::PRINTABLE = '0123456789abcdef'
!CHARACTER(LEN=*), PARAMETER :: PRINTABLE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\\"#$%&amp;\'()*+,-./:;&lt;=&gt;?@[\\]^_`{|}~\t\n\r"

CONTAINS
    FUNCTION getTime() RESULT (outValue)
        REAL(ids_real):: outValue

        outValue = 1.0
        RETURN
    END FUNCTION getTime

    FUNCTION getString() RESULT (outValue)
        CHARACTER(LEN=132), dimension(:), POINTER :: outValue

        allocate(outValue(1))
        outValue(1) = PRINTABLE
        RETURN
    END FUNCTION getString

 subroutine setString_(cpoField)
character(len=132), dimension(:), pointer :: cpoField

allocate(cpoField(1))
cpoField(1) = PRINTABLE
        RETURN
    END subroutine setString_

    FUNCTION getStringArray(sizeOfArray) RESULT (outArray)
    INTEGER, INTENT(in)::sizeOfArray
    CHARACTER(len=132),DIMENSION(:), POINTER :: outArray
    INTEGER::I

    ALLOCATE(outArray(sizeofArray))
    do I = 1, sizeOfArray
        outArray(I) = PRINTABLE
    end do
    RETURN
	END FUNCTION getStringArray

    FUNCTION getDouble() RESULT (outValue)
        REAL(ids_real):: outValue

   !     outValue=rand() *1000.00
     call random_number(outValue)
     outValue = outValue * 1000

        RETURN
    END FUNCTION getDouble

    FUNCTION getDoubleArray(sizeOfArray) RESULT (outArray)
    INTEGER, INTENT(in)::sizeOfArray
    REAL(ids_real),DIMENSION(:), POINTER :: outArray
    INTEGER::I

    ALLOCATE(outArray(sizeofArray))
    do I = 1, sizeOfArray
        outArray(I) = getDouble()
    end do
    RETURN

END FUNCTION getDoubleArray



    FUNCTION getInteger() RESULT (outValue)
        INTEGER:: outValue
	        REAL(ids_real):: randValue

     !   outValue=rand() * 1000.0
         call random_number(randValue)
     	outValue = randValue * 1000

        RETURN
    END FUNCTION getInteger





FUNCTION getIntegerArray(sizeOfArray) RESULT (outArray)
    INTEGER, INTENT(in) ::sizeOfArray
    INTEGER,DIMENSION(:), POINTER :: outArray
    INTEGER::I


    ALLOCATE(outArray(sizeofArray))
    do I = 1, sizeOfArray
        outArray(I) = getInteger()
    end do
    RETURN
END FUNCTION getIntegerArray


! =================================================================
! 		STRING ARRAYS
! =================================================================
FUNCTION getString1DArray(dim1) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1
    INTEGER  ::sizeOfArray
    CHARACTER(len=132),DIMENSION(:), POINTER :: outArray
    INTEGER::I

    sizeOfArray = dim1

    ALLOCATE(outArray(dim1))
    outArray =  getStringArray(sizeOfArray)


    RETURN

END FUNCTION getString1DArray

! =================================================================
! 		INTEGER ARRAYS
! =================================================================
FUNCTION getInteger1DArray(dim1) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1
    INTEGER  ::sizeOfArray
    INTEGER, DIMENSION(:), POINTER :: flatArray
    INTEGER,DIMENSION(:), POINTER :: outArray
    INTEGER::I

    !sizeOfArray = dim1
     sizeOfArray = DIM_SIZE **1

    flatArray => getIntegerArray(sizeOfArray)
    ALLOCATE(outArray(dim1))

    outArray =  RESHAPE(flatArray(:dim1), (/dim1/))

    RETURN
END FUNCTION getInteger1DArray

! =================================================================

FUNCTION getInteger2DArray(dim1, dim2) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2
    INTEGER ::sizeOfArray

    INTEGER, DIMENSION(:), POINTER :: flatArray
    INTEGER,DIMENSION(:,:), POINTER :: outArray
    INTEGER::I


    !sizeOfArray = dim1 * dim2
    sizeOfArray = DIM_SIZE **2

    flatArray => getIntegerArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2))

    outArray =  RESHAPE(flatArray(:dim1 * dim2), (/dim1, dim2/))

RETURN

END FUNCTION getInteger2DArray

! =================================================================

FUNCTION getInteger3DArray(dim1, dim2, dim3) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3
    INTEGER ::sizeOfArray
    INTEGER, DIMENSION(:), POINTER :: flatArray
    INTEGER, DIMENSION(:,:,:), POINTER :: outArray
    INTEGER::I


    !sizeOfArray = dim1 * dim2 * dim3
    sizeOfArray = DIM_SIZE **3

    flatArray => getIntegerArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3), (/dim1, dim2, dim3/))

RETURN

END FUNCTION getInteger3DArray



! =================================================================
! 		DOUBLE ARRAYS
! =================================================================
FUNCTION getDouble1DArray(dim1) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1
    INTEGER ::sizeOfArray
    REAL(ids_real),DIMENSION(:), POINTER :: outArray
    REAL(ids_real),DIMENSION(:), POINTER :: flatArray
    INTEGER::I

    !sizeOfArray = dim1
    sizeOfArray = DIM_SIZE **1

    flatArray => getDoubleArray(sizeOfArray)

    ALLOCATE(outArray(dim1))

    outArray =  RESHAPE(flatArray(:dim1), (/dim1/))

    RETURN
END FUNCTION getDouble1DArray

! =================================================================

FUNCTION getDouble2DArray(dim1, dim2) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2
    INTEGER ::sizeOfArray
    REAL(ids_real),DIMENSION(:), POINTER :: flatArray
    REAL(ids_real),DIMENSION(:,:), POINTER :: outArray
    INTEGER::I

    !sizeOfArray = dim1 * dim2
    sizeOfArray = DIM_SIZE **2

    flatArray => getDoubleArray(sizeOfArray)

    ALLOCATE(outArray(dim1, dim2))

    outArray =  RESHAPE(flatArray(:dim1 * dim2),(/dim1, dim2/))

    RETURN
END FUNCTION getDouble2DArray

! =================================================================

FUNCTION getDouble3DArray(dim1, dim2, dim3) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3

    INTEGER ::sizeOfArray
    REAL(ids_real),DIMENSION(:), POINTER :: flatArray
    REAL(ids_real),DIMENSION(:,:,:), POINTER :: outArray
    INTEGER :: I



   !sizeOfArray = dim1 * dim2 * dim3
    sizeOfArray = DIM_SIZE **3

    flatArray => getDoubleArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3), (/dim1, dim2, dim3/))

    RETURN
END FUNCTION getDouble3DArray

! =================================================================

FUNCTION getDouble4DArray(dim1, dim2, dim3, dim4) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3, dim4
    INTEGER ::sizeOfArray
        REAL(ids_real),DIMENSION(:), POINTER :: flatArray
    REAL(ids_real),DIMENSION(:,:,:, :), POINTER :: outArray
    INTEGER::I

    !sizeOfArray = dim1 * dim2 * dim3 * dim4
    sizeOfArray = DIM_SIZE **4

    flatArray => getDoubleArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3, dim4))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3 * dim4), (/dim1, dim2, dim3, dim4/))

    RETURN
END FUNCTION getDouble4DArray

! =================================================================
FUNCTION getDouble5DArray(dim1, dim2, dim3, dim4, dim5) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3, dim4, dim5
    INTEGER ::sizeOfArray
    REAL(ids_real),DIMENSION(:), POINTER :: flatArray
    REAL(ids_real),DIMENSION(:,:,:,:,:), POINTER :: outArray
    INTEGER::I

    !sizeOfArray = dim1 * dim2 * dim3 * dim4 * dim5
    sizeOfArray = DIM_SIZE **5

    flatArray => getDoubleArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3, dim4, dim5))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3 * dim4 * dim5), (/dim1, dim2, dim3, dim4, dim5/))

    RETURN
END FUNCTION getDouble5DArray

! =================================================================

FUNCTION getDouble6DArray(dim1, dim2, dim3, dim4, dim5, dim6) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3, dim4, dim5, dim6

    INTEGER ::sizeOfArray
    REAL(ids_real),DIMENSION(:), POINTER :: flatArray
    REAL(ids_real),DIMENSION(:,:,:,:,:,:), POINTER :: outArray
    INTEGER::I

    !sizeOfArray = dim1 * dim2 * dim3 * dim4 * dim5 * dim6
    sizeOfArray = DIM_SIZE **6

    flatArray => getDoubleArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3, dim4, dim5, dim6))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3 * dim4 * dim5 * dim6), (/dim1, dim2, dim3, dim4, dim5, dim6/))

    RETURN
END FUNCTION getDouble6DArray

! =================================================================
! =================================================================
! BEGINNING OF A SUBROUTINE HAS BEEN LOST HERE ???
!IF(ALL(ARRAY1.EQ.ARRAY1)) THEN
!CALL DOEQUAL
!ELSE
!CALL DOUNEQUAL
!ENDIF

!which works for all types of array1 and array2 as long as they have the same type and length,but I think it isslow because an array of logicals is created first. So much faster would be

!DO I=1,SIZE(ARRAY1)
!IF(ARRAY1(1).EQ.ARRAY2(I)) EXIT
!ENDDO
!IF(I.GT.N) THEN
!CALL DOEQUAL
!ELSE
!CALL DOUNEQUAL
!ENDIF

!!
!  SUBROUTINE f(N)
!   IMPLICIT NONE

!   INTEGER N

!   REAL, DIMENSION(N) :: A	!! You can define arrays using
                                !! VARIABLES in Fortran 90.... like Ada    

!   INTEGER i

!   DO i = 1, N
!      A(i) = i
!   END DO

!   print *, A			!! Print an entire array

!  END SUBROUTINE

!  PROGRAM main
!   IMPLICIT NONE

!   CALL f(2)			!! Create array of size 2

!   CALL f(3)			!! Create array of size 3
!  END




	SUBROUTINE init(idx)
	INTEGER, INTENT(OUT) :: idx

  		CALL imas_create('ids',TESTSHOT,TESTRUN, TESTSHOT,TESTRUN,idx)
		print *, "IDX:", idx

        END SUBROUTINE init



	SUBROUTINE open(idx)
	INTEGER, INTENT(OUT) :: idx

  		CALL imas_open('ids',TESTSHOT,TESTRUN, idx)
		print *, "IDX:", idx

        END SUBROUTINE open
	

        SUBROUTINE finish(idx)
	   INTEGER, INTENT(IN) :: idx
	  
	   call imas_close(idx)

        END SUBROUTINE finish

END MODULE helper



