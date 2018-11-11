MODULE helper
  use generator
  use ids_routines
  use ual_low_level_wrap
  implicit none

!INTEGER, PARAMETER :: DIM_SIZE = 1

!INTEGER, PARAMETER :: noOfSlices = DIM_SIZE
INTEGER, PARAMETER :: TESTSHOT = 9998
INTEGER, PARAMETER :: TESTRUN = 9998
!INTEGER, DIMENSION(:),allocatable :: SEED
!REAL(ids_real), DIMENSION(DIM_SIZE) :: timeVector

CHARACTER(len=:), ALLOCATABLE :: dataVersion
CHARACTER(len=:), ALLOCATABLE :: userName

!CHARACTER (LEN=*), PARAMETER ::PRINTABLE = '0123456789abcdef'
!CHARACTER(LEN=*), PARAMETER :: PRINTABLE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\\"#$%&amp;\'()*+,-./:;&lt;=&gt;?@[\\]^_`{|}~\t\n\r"

CONTAINS





SUBROUTINE getUser(userName) 
   	CHARACTER(len=:), ALLOCATABLE, INTENT(OUT) :: userName
	CHARACTER(len=255) :: buffer
	integer :: userNameSize
	
	if(allocated(userName)) then
		return
	endif
	
	CALL getenv("USER", buffer)
	userNameSize = LEN_TRIM(buffer)
	if(userNameSize < 1) then
		write(*,*) "PANIC: $USER not found! Exiting..."
		CALL exit(1)
	endif

	allocate(character(userNameSize):: userName)
	username = trim(buffer)
END SUBROUTINE getUser
!	
SUBROUTINE getDataVersion(dataVersion) 
   	CHARACTER(len=:), ALLOCATABLE, INTENT(OUT) :: dataVersion
	CHARACTER(len=255) :: buffer
	integer :: dataVersionSize
	
	if(allocated(dataVersion)) then
		return
	endif
	
	CALL getenv("IMAS_VERSION", buffer)
	dataVersionSize = LEN_TRIM(buffer)
	
	if(dataVersionSize < 1) then
		write(*,*) "PANIC: $IMAS_VERSION not found! Exiting..."
		CALL exit(1)
	endif
	
	allocate(character(dataVersionSize):: dataVersion)
	dataVersion = trim(buffer)
END SUBROUTINE getDataVersion


SUBROUTINE initEnv()
	CALL getDataVersion(dataVersion) 
	CALL getUser(userName)
END SUBROUTINE initEnv

SUBROUTINE create(idx)
	INTEGER, INTENT(OUT) :: idx

    CALL initTime()
    CALL initEnv()
    CALL imas_create_env('ids',TESTSHOT,TESTRUN, TESTSHOT,TESTRUN,idx, userName, 'test', dataVersion)

	print *, "IDX:", idx

END SUBROUTINE create

SUBROUTINE createslice(idx)
  INTEGER, INTENT(OUT) :: idx

  CALL initTime()
  CALL initEnv()
  CALL imas_create_env('ids',TESTSHOT+1,TESTRUN+1, TESTSHOT+1,TESTRUN+1,idx, userName, 'test', dataVersion)

  print *, "IDX:", idx

END SUBROUTINE createslice


SUBROUTINE open(idx)
	INTEGER, INTENT(OUT) :: idx

  CALL initTime()
  CALL initEnv()
	CALL imas_open_env('ids',TESTSHOT,TESTRUN, idx, userName, 'test', dataVersion)
	print *, "IDX:", idx

END SUBROUTINE open

SUBROUTINE openslice(idx)
  INTEGER, INTENT(OUT) :: idx

  CALL initTime()
  CALL initEnv()
  CALL imas_open_env('ids',TESTSHOT+1,TESTRUN+1, idx, userName, 'test', dataVersion)
  print *, "IDX:", idx

END SUBROUTINE openslice
	

SUBROUTINE close(idx)
	   INTEGER, INTENT(IN) :: idx
	  
	   call imas_close(idx)

END SUBROUTINE close

END MODULE helper



