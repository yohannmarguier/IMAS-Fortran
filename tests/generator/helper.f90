MODULE helper
use ids_schemas
use ids_routines

implicit none

INTEGER, PARAMETER :: seed = 0
INTEGER, PARAMETER :: DIM_SIZE = 2
INTEGER, PARAMETER :: TESTSHOT = 9998
INTEGER, PARAMETER :: TESTRUN = 9998	





CHARACTER (LEN=*), PARAMETER ::PRINTABLE = '0123456789abcdef'
!CHARACTER(LEN=*), PARAMETER :: PRINTABLE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\\"#$%&amp;\'()*+,-./:;&lt;=&gt;?@[\\]^_`{|}~\t\n\r"
	
CONTAINS
    FUNCTION getTime() RESULT (outValue)
        REAL(DP):: outValue

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
        REAL(DP):: outValue

        outValue=rand() *1000.00
        RETURN
    END FUNCTION getDouble
    
    FUNCTION getDoubleArray(sizeOfArray) RESULT (outArray)
    INTEGER, INTENT(in)::sizeOfArray
    REAL(DP),DIMENSION(:), POINTER :: outArray
    INTEGER::I
    
    ALLOCATE(outArray(sizeofArray))
    do I = 1, sizeOfArray
        outArray(I) = getDouble() 
    end do     
    RETURN
    
END FUNCTION getDoubleArray

	

    FUNCTION getInteger() RESULT (outValue)
        INTEGER:: outValue

        outValue=rand() * 1000.0
    
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
FUNCTION getString1DArray() RESULT (outArray)
    INTEGER  ::sizeOfArray
    CHARACTER(len=132),DIMENSION(:), POINTER :: outArray
    INTEGER::I
    
    sizeOfArray = DIM_SIZE**1
    
    ALLOCATE(outArray(DIM_SIZE))
    outArray =  getStringArray(sizeOfArray)

    
    RETURN
    
END FUNCTION getString1DArray

! =================================================================
! 		INTEGER ARRAYS
! =================================================================
FUNCTION getInteger1DArray() RESULT (outArray)
    INTEGER  ::sizeOfArray
    INTEGER,DIMENSION(:), POINTER :: outArray
    INTEGER::I
    
    sizeOfArray = DIM_SIZE**1
    
    ALLOCATE(outArray(sizeofArray))

    outArray = getIntegerArray(sizeOfArray) 
    RETURN
END FUNCTION getInteger1DArray

FUNCTION getInteger2DArray() RESULT (outArray)
    INTEGER ::sizeOfArray
    INTEGER,DIMENSION(:,:), POINTER :: outArray
    INTEGER::I
    
    
    sizeOfArray = DIM_SIZE**2
    ALLOCATE(outArray(DIM_SIZE, DIM_SIZE))
    
    outArray =  RESHAPE(getIntegerArray(sizeOfArray), (/DIM_SIZE, DIM_SIZE/))
    
RETURN
    
END FUNCTION getInteger2DArray

FUNCTION getInteger3DArray() RESULT (outArray)
    INTEGER ::sizeOfArray
    INTEGER,DIMENSION(:,:,:), POINTER :: outArray
    INTEGER::I
    
    
    sizeOfArray = DIM_SIZE**3
    ALLOCATE(outArray(DIM_SIZE, DIM_SIZE, DIM_SIZE))
    
    outArray =  RESHAPE(getIntegerArray(sizeOfArray), (/DIM_SIZE, DIM_SIZE, DIM_SIZE/))
    
RETURN
    
END FUNCTION getInteger3DArray



! =================================================================
! 		DOUBLE ARRAYS
! =================================================================
FUNCTION getDouble1DArray() RESULT (outArray)
    INTEGER ::sizeOfArray
    REAL(DP),DIMENSION(:), POINTER :: outArray
    INTEGER::I
   
    sizeOfArray = DIM_SIZE**1
        
    ALLOCATE(outArray(DIM_SIZE))
    
    outArray =  getDoubleArray(sizeOfArray)
    
    RETURN
END FUNCTION getDouble1DArray


FUNCTION getDouble2DArray() RESULT (outArray)
    INTEGER ::sizeOfArray
    REAL(DP),DIMENSION(:,:), POINTER :: outArray
    INTEGER::I
   
    sizeOfArray = DIM_SIZE**2
        
    ALLOCATE(outArray(DIM_SIZE, DIM_SIZE))
    
    outArray =  RESHAPE(getDoubleArray(sizeOfArray), (/DIM_SIZE, DIM_SIZE/))
    
    RETURN
END FUNCTION getDouble2DArray

FUNCTION getDouble3DArray() RESULT (outArray)
    INTEGER ::sizeOfArray
    REAL(DP),DIMENSION(:,:,:), POINTER :: outArray
    INTEGER::I
   
    sizeOfArray = DIM_SIZE**3
        
    ALLOCATE(outArray(DIM_SIZE, DIM_SIZE, DIM_SIZE))
    
    outArray =  RESHAPE(getDoubleArray(sizeOfArray), (/DIM_SIZE, DIM_SIZE, DIM_SIZE/))
    
    RETURN
END FUNCTION getDouble3DArray

FUNCTION getDouble4DArray() RESULT (outArray)
    INTEGER ::sizeOfArray
    REAL(DP),DIMENSION(:,:,:, :), POINTER :: outArray
    INTEGER::I
   
    sizeOfArray = DIM_SIZE**4
        
    ALLOCATE(outArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE))
    
    outArray =  RESHAPE(getDoubleArray(sizeOfArray), (/DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE/))
    
    RETURN
END FUNCTION getDouble4DArray

FUNCTION getDouble5DArray() RESULT (outArray)
    INTEGER ::sizeOfArray
    REAL(DP),DIMENSION(:,:,:,:,:), POINTER :: outArray
    INTEGER::I
   
    sizeOfArray = DIM_SIZE**5
        
    ALLOCATE(outArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE))
    
    outArray =  RESHAPE(getDoubleArray(sizeOfArray), (/DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE/))
    
    RETURN
END FUNCTION getDouble5DArray

FUNCTION getDouble6DArray() RESULT (outArray)
    INTEGER ::sizeOfArray
    REAL(DP),DIMENSION(:,:,:,:,:,:), POINTER :: outArray
    INTEGER::I
   
    sizeOfArray = DIM_SIZE**6
        
    ALLOCATE(outArray(DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE))
    
    outArray =  RESHAPE(getDoubleArray(sizeOfArray), (/DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE, DIM_SIZE/))
    
    RETURN
END FUNCTION getDouble6DArray


!IF(ALL(ARRAY1.EQ.ARRAY1)) THENCALL DOEQUALELSECALL DOUNEQUALENDIFwhich works for all types of array1 and array2 as long as they have the same type and length,but I think it isslow because an array of logicals is created first. So much faster would beDO I=1,SIZE(ARRAY1)IF(ARRAY1(1).EQ.ARRAY2(I)) EXITENDDOIF(I.GT.N) THENCALL DOEQUALELSECALL DOUNEQUALENDIF

!!  SUBROUTINE f(N)   IMPLICIT NONE   INTEGER N   REAL, DIMENSION(N) :: A	!! You can define arrays using                                !! VARIABLES in Fortran 90.... like Ada       INTEGER i   DO i = 1, N      A(i) = i   END DO   print *, A			!! Print an entire array  END SUBROUTINE  PROGRAM main   IMPLICIT NONE   CALL f(2)			!! Create array of size 2   CALL f(3)			!! Create array of size 3  END

      
	
	
	SUBROUTINE init(idx2)
	INTEGER, INTENT(OUT) :: idx2

  	CALL imas_create('ids',TESTSHOT,TESTRUN, TESTSHOT,TESTRUN,idx2)
	print *, "IDX:", idx2
!	if (cmd.hasOption("seed"))
!        seed = Long.valueOf(cmd.getOptionValue("seed"));
        
!	if (cmd.hasOption("remote"))
!        UALAccess.connect(cmd.getOptionValue("remote"));
!        if (cmd.hasOption("method") &amp;&amp; cmd.getOptionValue("method").equals("get")) {
!        if (cmd.hasOption("hdf5"))
!        idx = UALAccess.openHdf5("euitm", TESTSHOT, TESTRUN);
!        else
!        idx = UALAccess.open("euitm", TESTSHOT, TESTRUN);
!        } else {
!        if (cmd.hasOption("hdf5"))
!        idx = UALAccess.createHdf5("euitm", TESTSHOT, TESTRUN, -1, -1);
!        else
!        idx = UALAccess.create("euitm", TESTSHOT, TESTRUN, -1, -1);
!        }
        END SUBROUTINE init
        

        SUBROUTINE finish
	 !       UALAccess.close(idx);
 !       if (cmd.hasOption("remote"))
 !       UALAccess.disconnect();
        END SUBROUTINE finish 
        
END MODULE helper



