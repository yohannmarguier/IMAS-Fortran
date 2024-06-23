subroutine create_db_entry_legacy

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

! Get users name so we can access their personal database.

  call get_environment_variable( "USER" , userName)

! Please note that legacy create function allows to create MDS+ files only.
! For HDF5 files you have to either call low level functions or use
! URI based open functions - URI based open is shown in other samples.

  call imas_create_env( treeName,          &
                        pulse,             &
                        run,               &
                        idx,               &
                        trim( userName ),  &
                        dbName,            &
                        '3',
                        status)
  if (status.ne.0) then
    WRITE(*,*)  'Error! Issue while creating MDS+ file.'
  end if

end subroutine create_db_entry_legacy

