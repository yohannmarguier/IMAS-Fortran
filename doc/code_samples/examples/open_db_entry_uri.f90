subroutine open_db_entry_uri

  use ids_routines
  implicit none

  integer             :: pulse         = 1      ! pulse number of MDS+ file
  integer             :: run           = 10     ! shot number of MDS+ file
  integer             :: idx                    ! index of opened input file
  integer             :: status                 ! error code of the operation
  integer             :: i                      ! used for loops over timed values
  character(len=256)  :: userName               ! name of the user running the code
  character(len=10)   :: dbName        = 'test' ! name of the database
  character(len=5)    :: treeName      = 'ids'  ! name of the MDS+ tree structure 
  character(len=1024) :: uri                    ! uri containes location of the data

!   Available backends are:
!   ascii - only for debugging purposes
!   mdsplus
!   hdf5
!   memory - data is lost after entry is closed
!   uda

! Get users name so we can access their personal database.

  call get_environment_variable( "USER" , userName)

  uri = 'imas:mdsplus?user='//trim(userName)//';pulse=1;run=10;database=test;version=3'

  ! Create the database entry by providing an IMAS URI
  call imas_open(uri, FORCE_CREATE_PULSE, idx, status)

  if (status.ne.0) then
    WRITE(*,*)  'Error! Issue while creating MDS+ file.'
  end if

end subroutine create_db_entry_legacy

