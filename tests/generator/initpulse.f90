PROGRAM initpulse
  use ids_schemas
  use ids_routines
  use ual_low_level_wrap
  implicit none

  INTEGER, PARAMETER :: TESTSHOT = 9998
  INTEGER, PARAMETER :: TESTRUN = 9998
  CHARACTER(len=:), ALLOCATABLE :: dataVersion
  CHARACTER(len=:), ALLOCATABLE :: userName
  INTEGER :: idx, idxslice

  CHARACTER(len=255) :: buffer
  integer :: userNameSize
  integer :: dataVersionSize

  CALL get_environment_variable("USER", buffer)
  userNameSize = LEN_TRIM(buffer)
  if(userNameSize < 1) then
     ERROR STOP "PANIC: $USER not found! Exiting..."
  endif
  allocate(character(userNameSize):: userName)
  userName = trim(buffer)

  CALL get_environment_variable("IMAS_VERSION", buffer)
  dataVersionSize = LEN_TRIM(buffer)
  if(dataVersionSize < 1) then
     ERROR STOP "PANIC: $IMAS_VERSION not found! Exiting..."
  endif
  allocate(character(dataVersionSize):: dataVersion)
  dataVersion = trim(buffer)

  print *,"CREATE PULSEFILE ",TESTSHOT,TESTRUN," FOR FULL OPERATIONS"
  CALL imas_create_env('ids',TESTSHOT,TESTRUN,0,0,idx,& 
       userName,'test',dataVersion)

  print *,"CREATE PULSEFILE ",TESTSHOT+1,TESTRUN+1," FOR SLICE OPERATIONS"
  CALL imas_create_env('ids',TESTSHOT+1,TESTRUN+1,0,0,&
       idxslice,userName,'test',dataVersion)
  
  call imas_close(idx)
  call imas_close(idxslice)

END PROGRAM initpulse


