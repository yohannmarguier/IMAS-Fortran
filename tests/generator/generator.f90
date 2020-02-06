MODULE generator

use ids_types, only: ids_real
  implicit none

INTEGER, PARAMETER :: DIM_SIZE = 5

INTEGER, PARAMETER :: noOfSlices = DIM_SIZE
INTEGER, DIMENSION(:),allocatable :: SEED
REAL(ids_real), DIMENSION(DIM_SIZE), TARGET :: timeVector


CHARACTER (LEN=*), PARAMETER ::PRINTABLE = '0123456789abcdef'
!CHARACTER(LEN=*), PARAMETER :: PRINTABLE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\\"#$%&amp;\'()*+,-./:;&lt;=&gt;?@[\\]^_`{|}~\t\n\r"

CONTAINS
  SUBROUTINE initTime
    INTEGER :: I
    do I = 1, DIM_SIZE
       timeVector(I) = I
    end do
  END SUBROUTINE initTime
 
  function getHomogeneousTime() result(homogeneousTime)
    integer :: homogeneousTime
    character(len=255) :: buffer
    integer :: bufferSize, stat
    
    call get_environment_variable("TESTHOMOGENEOUS", buffer)
    bufferSize = LEN_TRIM(buffer)
    if(bufferSize < 1) then
       homogeneousTime = 1
    else
       read(buffer,*,iostat=stat) homogeneousTime 
       if (stat .eq. 0) then
          print *,"selected homogeneousTime = ",homogeneousTime
       else
          print *,"wrong homogeneousTime read as ",homogeneousTime
          STOP
       end if
    endif
    RETURN
  end function getHomogeneousTime


  
      FUNCTION getTimeScalar(idxTime) RESULT (outTime)
        REAL(ids_real) :: outTime
	INTEGER :: idxTime
	
        outTime = timeVector(idxTime)
    RETURN
  END FUNCTION getTimeScalar
  

      FUNCTION getTimeVector(size, index) RESULT (outArray)
        INTEGER, INTENT(in)::size
	INTEGER, INTENT(in)::index 
   	REAL(ids_real), DIMENSION(:), POINTER      :: outArray

	allocate(outArray(size))
	
	if(size == 1) then
		outArray = timeVector(index:index)
	else
		outArray = timeVector(1:size)
	end if

        RETURN
    END FUNCTION getTimeVector


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


FUNCTION getComplex() RESULT (outValue)
  COMPLEX(ids_real):: outValue
  REAL(ids_real):: r,i
  !     outValue=rand() *1000.00
  call random_number(r)
  call random_number(i)
  outValue = CMPLX(r*1000,i*1000)
  
  RETURN
END FUNCTION getComplex

FUNCTION getComplexArray(sizeOfArray) RESULT (outArray)
  INTEGER, INTENT(in)::sizeOfArray
  COMPLEX(ids_real),DIMENSION(:), POINTER :: outArray
  INTEGER::I
  
  ALLOCATE(outArray(sizeofArray))
  do I = 1, sizeOfArray
     outArray(I) = getComplex()
  end do
  RETURN
END FUNCTION getComplexArray

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

FUNCTION getInteger4DArray(dim1, dim2, dim3, dim4) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3, dim4
    INTEGER ::sizeOfArray
    INTEGER, DIMENSION(:), POINTER :: flatArray
    INTEGER, DIMENSION(:,:,:,:), POINTER :: outArray
    INTEGER::I


    !sizeOfArray = dim1 * dim2 * dim3 * dim4
    sizeOfArray = DIM_SIZE **4

    flatArray => getIntegerArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3, dim4))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3 * dim4), (/dim1, dim2, dim3,dim4/))

RETURN

END FUNCTION getInteger4DArray

FUNCTION getInteger5DArray(dim1, dim2, dim3, dim4, dim5) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3, dim4, dim5
    INTEGER ::sizeOfArray
    INTEGER, DIMENSION(:), POINTER :: flatArray
    INTEGER, DIMENSION(:,:,:,:,:), POINTER :: outArray
    INTEGER::I


    !sizeOfArray = dim1 * dim2 * dim3 * dim4 * dim5
    sizeOfArray = DIM_SIZE **5

    flatArray => getIntegerArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3, dim4, dim5))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3 * dim4 * dim5), (/dim1, dim2, dim3, dim4, dim5/))

RETURN

END FUNCTION getInteger5DArray

FUNCTION getInteger6DArray(dim1, dim2, dim3, dim4, dim5, dim6) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3, dim4, dim5, dim6
    INTEGER ::sizeOfArray
    INTEGER, DIMENSION(:), POINTER :: flatArray
    INTEGER, DIMENSION(:,:,:,:,:,:), POINTER :: outArray
    INTEGER::I


    !sizeOfArray = dim1 * dim2 * dim3 * dim4 * dim5 * dim6
    sizeOfArray = DIM_SIZE **5

    flatArray => getIntegerArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3, dim4, dim5, dim6))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3 * dim4 * dim5 * dim6), (/dim1, dim2, dim3, dim4, dim5, dim6/))

RETURN

END FUNCTION getInteger6DArray


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
! 		COMPLEX ARRAYS
! =================================================================
FUNCTION getComplex1DArray(dim1) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1
    INTEGER ::sizeOfArray
    COMPLEX(ids_real),DIMENSION(:), POINTER :: outArray
    COMPLEX(ids_real),DIMENSION(:), POINTER :: flatArray
    INTEGER::I

    !sizeOfArray = dim1
    sizeOfArray = DIM_SIZE **1

    flatArray => getComplexArray(sizeOfArray)

    ALLOCATE(outArray(dim1))

    outArray =  RESHAPE(flatArray(:dim1), (/dim1/))

    RETURN
  END FUNCTION getComplex1DArray

! =================================================================

  FUNCTION getComplex2DArray(dim1, dim2) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2
    INTEGER ::sizeOfArray
    COMPLEX(ids_real),DIMENSION(:), POINTER :: flatArray
    COMPLEX(ids_real),DIMENSION(:,:), POINTER :: outArray
    INTEGER::I

    !sizeOfArray = dim1 * dim2
    sizeOfArray = DIM_SIZE **2

    flatArray => getComplexArray(sizeOfArray)

    ALLOCATE(outArray(dim1, dim2))

    outArray =  RESHAPE(flatArray(:dim1 * dim2),(/dim1, dim2/))

    RETURN
  END FUNCTION getComplex2DArray

! =================================================================

FUNCTION getComplex3DArray(dim1, dim2, dim3) RESULT (outArray)
    INTEGER, INTENT(in) :: dim1, dim2, dim3

    INTEGER ::sizeOfArray
    COMPLEX(ids_real),DIMENSION(:), POINTER :: flatArray
    COMPLEX(ids_real),DIMENSION(:,:,:), POINTER :: outArray
    INTEGER :: I



   !sizeOfArray = dim1 * dim2 * dim3
    sizeOfArray = DIM_SIZE **3

    flatArray => getComplexArray(sizeOfArray)
    ALLOCATE(outArray(dim1, dim2, dim3))

    outArray =  RESHAPE(flatArray(:dim1 * dim2 * dim3), (/dim1, dim2, dim3/))

    RETURN
  END FUNCTION getComplex3DArray


END MODULE generator



