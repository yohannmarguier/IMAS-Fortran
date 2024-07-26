subroutine open_db_entry_uri
  !! Routine illustrating how to open pulse file in Fortran using
  !! URI based approach.

  use ids_routines
  implicit none

  integer                   :: pulse         = 1      ! pulse number of MDS+ file
  integer                   :: run           = 10     ! shot number of MDS+ file
  integer                   :: version       = 3      ! DD major version schema
  character(len=5)          :: strPulse               ! string placeholder for Pulse
  character(len=5)          :: strRun                 ! string placeholder for Run
  character(len=5)          :: strVersion             ! string placeholder for DD Version
  integer                   :: idx                    ! index of opened input file
  integer                   :: status                 ! error code of the operation
  integer                   :: i                      ! used for loops over timed values
  character(len=256)        :: userName               ! name of the user running the code
  character(len=10)         :: dbName        = 'test' ! name of the database
  character(len=5)          :: treeName      = 'ids'  ! name of the MDS+ tree structure 
  character(len=1024)       :: uri                    ! uri containes location of the data
  character(:), allocatable :: retmsg                 ! message returned by imas_open subroutine

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
  call imas_open(trim(uri), FORCE_CREATE_PULSE, idx, status, retmsg)

  if (status.ne.0) then
    write(*,*)  'Error! Issue while creating MDS+ file.'

    if (allocated(retmsg)) then
      write(*,*) 'error message was: ', retmsg
    end if
  end if

end subroutine open_db_entry_uri


subroutine create_db_entry_legacy
  !! Routine illustrating how to open pulse file (using Fortran) with
  !! a legacy based approach.
  use ids_routines
  use ids_routines
  implicit none

  integer                   :: pulse         = 1      ! pulse number of MDS+ file
  integer                   :: run           = 10     ! shot number of MDS+ file
  integer                   :: idx                    ! index of opened input file
  integer                   :: status                 ! error code of the operation
  integer                   :: i                      ! used for loops over timed values
  character(len=256)        :: userName               ! name of the user running the code
  character(len=10)         :: dbName        = 'test' ! name of the database
  character(len=5)          :: treeName      = 'ids'  ! name of the MDS+ tree structure

! Get users name so we can access their personal database.

  call get_environment_variable( "USER" , userName)

! Please note that legacy create function allows to create MDS+ files only.
! For HDF5 files you have to either call low level functions or use
! URI based open functions - URI based open is shown in other samples.

  call imas_create_env( treeName,          &
                        pulse,             &
                        run,               &
                        0,                 &
                        0,                 &
                        idx,               &
                        trim( userName ),  &
                        dbName,            &
                        '3',               &
                        status)
  if (status.ne.0) then
    write(*,*)  'Error! Issue while creating MDS+ file.'
  end if

end subroutine create_db_entry_legacy


subroutine create_db_entry_uri_with_path
  !! Routine illustrating how to create database (various backends) using Fortran.
  !! For a simplicity we use hardcoded locations for all files.
  use ids_routines
  use al_low_level_wrap

  character (len=*), parameter :: uriHDF5  = 'imas:hdf5?path=./testdb_hdf5'
  character (len=*), parameter :: uriMDS   = 'imas:mdsplus?path=./testdb_mdsplus'
  character (len=*), parameter :: uriASCII = 'imas:ascii?path=./testdb_ascii'
  integer                      :: idx    ! index of opened input file
  integer                      :: status ! error code of the operation 
  character(:), allocatable    :: retmsg ! message returned by imas_open subroutine

  call imas_open(uriMDS, FORCE_CREATE_PULSE, idx, status, retmsg)

  if (status.ne.0) then
    write(*,*)  'Error! Issue while creating MDS+ file.'

    if (allocated(retmsg)) then
      write(*,*) 'error message was: ', retmsg
    end if
  end if
  ! Content of ./testdb_mdsplus directory: ['ids_001.characteristics', 'ids_001.datafile', 'ids_001.tree']
  ! Structure of this directory does not depends on entry content. All IDS data are stored in printed files

  call imas_open(trim(uriHDF5), FORCE_CREATE_PULSE, idx, status, retmsg)

  if (status.ne.0) then
    write(*,*)  'Error! Issue while creating HDF5 file.'

    if (allocated(retmsg)) then
      write(*,*) 'error message was: ', retmsg
    end if
  end if
  ! Content of ./testdb_hdf5 directory: ['master.h5']
  ! Structure of this directory depends on entry content. Every IDS with data will be stored in <ids_name>.h5 file

  call imas_open(trim(uriASCII), FORCE_CREATE_PULSE, idx, status, retmsg)

  if (status.ne.0) then
    write(*,*)  'Error! Issue while creating ASCII file.'

    if (allocated(retmsg)) then
      write(*,*) 'error message was: ', retmsg
    end if
  end if
  ! Content of ./testdb_ascii directory: []
  ! Structure of this directory depends on entry content. Every IDS with data will be stored in <ids_name>.ids file

end subroutine create_db_entry_uri_with_path
