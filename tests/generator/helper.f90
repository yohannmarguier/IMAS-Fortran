MODULE helper
  use test_defs
  use generator
  use ids_routines
  use ual_low_level_wrap
  implicit none


CHARACTER(len=:), ALLOCATABLE :: dataVersion
CHARACTER(len=:), ALLOCATABLE :: userName

CONTAINS

FUNCTION backend2str( backendID ) RESULT (strBackend)
    INTEGER, INTENT(IN) :: backendID
    CHARACTER(len=10) :: strBackend

    SELECT CASE (backendID)

        ! MDSPLUS_BACKEND
        CASE (MDSPLUS_BACKEND)                   
              strBackend =  "MDSPLUS"               
        
        ! MEMORY_BACKEND
        CASE (MEMORY_BACKEND)                   
              strBackend =  "MEMORY"               

        ! ASCII_BACKEND
        CASE (ASCII_BACKEND)                   
              strBackend =  "ASCII"               

        ! HDF5_BACKEND
        CASE (HDF5_BACKEND)                   
              strBackend =  "HDF5"               

        ! UDA_BACKEND
        CASE (UDA_BACKEND)                   
              strBackend =  "UDA"               

        CASE default
              strBackend = "UNKNOWN"
    END SELECT 



END FUNCTION backend2str


FUNCTION timeMode2str( idsTimeMode ) RESULT (strTimeMode)
    INTEGER, INTENT(IN) :: idsTimeMode
    CHARACTER(len=14) :: strTimeMode

    SELECT CASE (idsTimeMode)

        ! MDSPLUS_BACKEND
        CASE (IDS_TIME_MODE_HOMOGENEOUS)                   
              strTimeMode =  "HOMOGENEOUS"               

        ! MEMORY_BACKEND
        CASE (IDS_TIME_MODE_HETEROGENEOUS)                   
              strTimeMode =  "HETEROGENEOUS"               

        ! ASCII_BACKEND
        CASE (IDS_TIME_MODE_INDEPENDENT)                   
              strTimeMode =  "INDEPENDENT"               

        CASE default
              strTimeMode = "UNKNOWN"
    END SELECT 

END FUNCTION timeMode2str


SUBROUTINE getUser(userName) 
   	CHARACTER(len=:), ALLOCATABLE, INTENT(OUT) :: userName
	CHARACTER(len=255) :: buffer
	integer :: userNameSize
	
	if(allocated(userName)) then
		return
	endif
	
	CALL get_environment_variable("USER", buffer)
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
	
	CALL get_environment_variable("IMAS_VERSION", buffer)
	dataVersionSize = LEN_TRIM(buffer)
	
	if(dataVersionSize < 1) then
		write(*,*) "PANIC: $IMAS_VERSION not found! Exiting..."
		CALL exit(1)
	endif
	
	allocate(character(dataVersionSize):: dataVersion)
	dataVersion = trim(buffer)
END SUBROUTINE getDataVersion



SUBROUTINE setCmdlOptions()

    character(len=32)           :: arg, argValue
    integer                     :: i, argCount

    i = 1
    argCount = command_argument_count()


    do 
        if (i > argCount) exit

        call get_command_argument(i, arg)
        
        select case (arg)
            !!! IDS Time Mode
            case ('-t', '--time-mode')
                i = i + 1
                call get_command_argument(i, argValue)
                select case (argValue)

                   ! ALL (default)
                    case ('0')
                            config%idsTimeModeArray = ARRAY_ALL_TIME_MODES

                    ! IDS_TIME_MODE_HOMOGENEOUS
                    case ('1')
                            ! clear the array
                            config%idsTimeModeArray = IDS_TIME_MODE_UNKNOWN
                            ! set user chosen mode
                            config%idsTimeModeArray(1) = IDS_TIME_MODE_HOMOGENEOUS

                    !IDS_TIME_MODE_HETEROGENEOUS
                    case ('2')
                            ! clear the array
                            config%idsTimeModeArray = IDS_TIME_MODE_UNKNOWN
                            ! set user chosen mode
                            config%idsTimeModeArray(1) = IDS_TIME_MODE_HETEROGENEOUS

                    !IDS_TIME_MODE_INDEPENDENT
                    case ('3')
                            ! clear the array
                            config%idsTimeModeArray = IDS_TIME_MODE_UNKNOWN
                            ! set user chosen mode
                            config%idsTimeModeArray(1) = IDS_TIME_MODE_INDEPENDENT

                    case default
                        print *, 'Error! IDS Time Mode: Unrecognised value [ ', trim(argValue), ' ]'
                       call print_help()
                        call exit(1)
                    
                end select

            !!! Backend
            case ('-b', '--backend')
                i = i + 1
                call get_command_argument(i, argValue)
                select case (argValue)

                   ! ALL (default)
                    case ('0')
                            config%backendIDArray = ARRAY_ALL_BACKENDS
                    ! MDSPLUS_BACKEND
                    case ('1')                   
                            ! clear array
                            config%backendIDArray = NO_BACKEND        
                            ! set user chosen backend
                            config%backendIDArray(1) = MDSPLUS_BACKEND

                    ! MEMORY_BACKEND
                    case ('2')
                            ! clear array
                            config%backendIDArray = NO_BACKEND        
                            ! set user chosen backend
                            config%backendIDArray(1) = MEMORY_BACKEND

                   ! ASCII_BACKEND
                    case ('3')
                            ! clear array
                            config%backendIDArray = NO_BACKEND        
                            ! set user chosen backend
                            config%backendIDArray(1) = ASCII_BACKEND

                   ! HDF5_BACKEND
                    case ('4')
                            ! clear array
                            config%backendIDArray = NO_BACKEND        
                            ! set user chosen backend
                            config%backendIDArray(1) = HDF5_BACKEND

                    case default
                        print *, 'Error! Backend: Unrecognised value [ ', trim(argValue), ' ]'
                        call print_help()
                        call exit(1)
                end select
            
             !!! TEST MODE
            case ('-m', '--test-mode')
                i = i + 1
                call get_command_argument(i, argValue)
                select case (argValue)

                   ! ALL (default)
                    case ('a', 'all')
                            config%testMode = TEST_MODE_ALL

                    ! TEST_MODE_GLOBAL
                    case ('g', 'global')
                            config%testMode = TEST_MODE_GLOBAL

                    ! TEST_MODE_SLICE
                    case ('s', 'slice')
                            config%testMode = TEST_MODE_SLICE

                    case default
                        print *, 'Error! Test Mode: Unrecognised value [ ', trim(argValue), ' ]'
                       call print_help()
                       call exit(1)
                    
            end select

           !!! Use existing pulse file
            case ('-u', '--use-pulsefile')
                    config%useExistingPulseFile = .TRUE.

            case ('-o', '--num-occurr')
                i = i + 1
                call get_command_argument(i, argValue)
                read(argValue, *) config%occToTest

            case ('-s', '--num-slices')
                i = i + 1
                call get_command_argument(i, argValue)
                read(argValue, *) config%timeSize

            case ('-d', '--data-size')
                i = i + 1
                call get_command_argument(i, argValue)
                read(argValue, *) config%dataSize

            case ('-h', '--help')
                call print_help()
                call exit(1)
            case default
                print '(2a, /)', 'Unrecognised command-line option: ',arg
                call print_help()
                call exit(1)
        end select
                i = i + 1
    end do
END SUBROUTINE setCmdlOptions

SUBROUTINE print_help()
        print '(a, /)', 'Options:'
        print '(a)',    '  -d, --data-size <value>  - Set size of vectors'
        print '(a)',    '  -s, --num-slices <value> - Set number of slices to be tested'
        print '(a)',    '  -t, --time-mode <value>  - Sets time mode'
        print '(a)',    '                Values:'
        print '(a)',    '                       0 - All modes (default)'
        print '(a)',    '                       1 - Homogeneous'
        print '(a)',    '                       2 - Heterogeneous'
        print '(a)',    '                       3 - Time-independent'
        print '(a)',    '  -b, --backend  <value>   - Sets AL backend:'
        print '(a)',    '                Values:'
        print '(a)',    '                       0 - All backends (default)'
        print '(a)',    '                       1 - MDSPlus'
        print '(a)',    '                       2 - Memory Backend'
        print '(a)',    '                       3 - ASCII Backend'
        print '(a)',    '                       4 - HDF5 Backend'
        print '(a)',    '  -o, --num-occurr <value> - Set maximum number of occurrences to be tested'
        print '(a)',    '  -m, --test-mode  <value> - Sets if slice and/or global operations should be tested:'
        print '(a)',    '                Values:'
        print '(a)',    '                       a, all    - All operations (default)'
        print '(a)',    '                       g, global - Global operations (put/get)'
        print '(a)',    '                       s, slice  - Slice operations (putSlice/getSlice)'
!        print '(a)',    '  -u, --use-pulsefile     - use existing pulse file'
        print '(a)',    '  -h, --help       print usage information and exit'
! stop at first error
END SUBROUTINE print_help

SUBROUTINE initEnv()

    INTEGER     :: argCount

    CALL getDataVersion(dataVersion) 
    CALL getUser(userName)


    argCount = command_argument_count()
    if (argCount > 0) then  
        CALL setCmdlOptions()
    end if
    
    CALL initTime(config%timeSize)

    dim1 = config%dataSize
    dim2 = config%dataSize
    dim3 = config%dataSize
    dim4 = config%dataSize

    dim5 = config%dataSize
    dim6 = config%dataSize

END SUBROUTINE initEnv

SUBROUTINE create_db(backendID, shot, run, idx)
  INTEGER, INTENT(IN)   :: backendID
  INTEGER, INTENT(IN)   :: shot
  INTEGER, INTENT(IN)   :: run
  INTEGER, INTENT(OUT) :: idx
  INTEGER :: status, mode
  CHARACTER(STRMAXLEN) :: uri

  !CALL imas_create_env('ids',TESTSHOT,TESTRUN, TESTSHOT,TESTRUN,idx, userName, 'test', dataVersion)
  CALL ual_build_uri_from_legacy_parameters(backendID, shot, run, userName, 'test', dataVersion, uri, status)

  mode = FORCE_CREATE_PULSE

  if (idx .ge. 0) then
     CALL ual_begin_dataentry_action(uri, mode, idx, status)
     if (status .eq. 0) then
        print *, "IDX:", idx
        return
     end if
  end if
END SUBROUTINE create_db



SUBROUTINE open_db(backendID, shot, run, idx)
  INTEGER, INTENT(IN)   :: backendID
  INTEGER, INTENT(IN)   :: shot
  INTEGER, INTENT(IN)   :: run
  INTEGER, INTENT(OUT)  :: idx
  INTEGER :: status
  CHARACTER(STRMAXLEN) :: uri

  !CALL imas_open_env('ids',TESTSHOT,TESTRUN, idx, userName, 'test', dataVersion)
  CALL ual_build_uri_from_legacy_parameters(backendID, shot, run, userName, 'test', dataVersion, uri, status)

  if (idx .ge. 0) then
     CALL ual_begin_dataentry_action(uri, OPEN_PULSE, idx, status)
     if (status .eq. 0) then
        print *, "IDX:", idx
        return
     end if
  end if

END SUBROUTINE open_db


	

SUBROUTINE close_db(idx)

  INTEGER, INTENT(IN) :: idx
  call imas_close(idx)

END SUBROUTINE close_db

END MODULE helper



