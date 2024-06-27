subroutine open_db_entry_uri

  use ids_routines
  implicit none

  integer             :: pulse         = 1      ! pulse number of MDS+ file
  integer             :: run           = 10     ! shot number of MDS+ file
  integer             :: version       = 3      ! DD major version schema
  character(len=5)    :: strPulse               ! string placeholder for Pulse
  character(len=5)    :: strRun                 ! string placeholder for Run
  character(len=5)    :: strVersion             ! string placeholder for DD Version
  integer             :: idx                    ! index of opened input file
  integer             :: status                 ! error code of the operation
  integer             :: i                      ! used for loops over timed values
  character(len=256)  :: userName               ! name of the user running the code
  character(len=10)   :: dbName        = 'test' ! name of the database
  character(len=5)    :: treeName      = 'ids'  ! name of the MDS+ tree structure 
  character(len=1024) :: uri                    ! uri containes location of the data

!   Available backends are:
!     ascii - only for debugging purposes
!     mdsplus
!     hdf5
!     memory - data is lost after entry is closed
!     uda

! Get users name so we can access their personal database.

  call get_environment_variable( "USER" , userName)

! Some tweaking of integer values; We follow here the code presented in Python
! where URI is a formatted string with various parameters. In Fortran we have
! to play a little bit with conversion and concatenation of strings

  write( strPulse, '(I0)') pulse
  write( strRun, '(I0)') run
  write( strVersion, '(I0)') version

  uri = 'imas:mdsplus?user='//trim(userName)// &
        ';pulse='//trim(strPulse)// &
        ';run='//trim(strRun)// &
        ';database='//trim(dbName)// &
        ';version='//trim(strVersion)

  ! Create the database entry by providing an IMAS URI
  ! Make sure to trim uri - we want to avoid any leading and trailing spaces.
  call imas_open(trim(uri), FORCE_CREATE_PULSE, idx, status)

  if (status.ne.0) then
    WRITE(*,*)  'Error! Issue while creating MDS+ file.'
  end if

end subroutine open_db_entry_uri

