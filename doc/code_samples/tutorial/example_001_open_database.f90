!!! Routine illustrating how to open pulse file in Fortran using
!!! URI based approach.
subroutine open_db_entry_uri

    use ids_routines
    implicit none

    integer                   :: pulse         = 1      ! pulse number of MDS+ file
    integer                   :: run           = 10     ! shot number of MDS+ file
    character(len=5)          :: version       = '3'    ! DD major version schema
    integer                   :: idx                    ! index of opened input file
    integer                   :: status                 ! error code of the operation
    character(:), allocatable :: errmsg                 ! optional returned error message 
    integer                   :: i                      ! used for loops over timed values
    integer                   :: backendId              ! identification number of backend used in this example
    character(len=256)        :: userName               ! name of the user running the code
    character(len=10)         :: dbName        = 'test' ! name of the database
    character(len=5)          :: treeName      = 'ids'  ! name of the MDS+ tree structure
    character(strmaxlen)      :: uri                    ! uri containes location of the data
    character(len=1024)       :: options       = ''     ! options to be passed to backend
    
    !   Available backends are:
    !     ascii   | 11 - only for debugging purposes
    !     mdsplus | 12
    !     hdf5    | 13
    !     memory  | 14 - data is lost after entry is closed
    !     uda     | 15

    backendId = 12

    ! Get users name so we can access their personal database.
    call get_environment_variable( "USER" , userName)

    ! We follow here the code presented in Python where URI is a formatted string with various parameters.
    ! In Fortran we have to use al_build_uri_from_legacy_parameters() subroutine

    call al_build_uri_from_legacy_parameters(backendId, pulse, run, userName, dbName, version, options, uri, status)
    write(*,*) 'Prepared uri: ', trim(uri)

    ! Create the database entry by providing an IMAS URI
    ! Make sure to trim uri - we want to avoid any leading and trailing spaces.
    call imas_open(trim(uri), FORCE_CREATE_PULSE, idx, status, errmsg)
    if (status.ne.0) then
        write(*,*)  'Error! Issue while creating MDS+ file: '//errmsg
    end if

    ! Remember to close entry when you are done with it
    call imas_close(idx, status)

end subroutine open_db_entry_uri




!!! Routine illustrating how to open pulse file (using Fortran) with
!!! a legacy based approach.
subroutine create_db_entry_legacy
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

    call imas_create_env( treeName,        &
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

    ! Remember to close entry when you are done with it
    call imas_close(idx, status)

end subroutine create_db_entry_legacy




!!! Routine illustrating how to create database (various backends) using Fortran.
!!! For a simplicity we use hardcoded locations for all files.
subroutine create_db_entry_uri_with_path
    use ids_routines
    implicit none

    character (len=1024), parameter :: uriMDS   = 'imas:mdsplus?path=./testdb_mdsplus'
    character (len=1024), parameter :: uriHDF5  = 'imas:hdf5?path=./testdb_hdf5'
    character (len=1024), parameter :: uriASCII = 'imas:ascii?path=./testdb_ascii'
    integer                      :: idx                                   ! index of opened input file
    integer                      :: status                                ! error code of the operation
    character(:), allocatable    :: errmsg                                ! optional returned error message 

    call imas_open(trim(uriMDS), FORCE_CREATE_PULSE, idx, status, errmsg)
    if (status.ne.0) then
        write(*,*)  'Error! Issue while creating MDS+ file: '//errmsg
    end if
    ! Content of ./testdb_mdsplus directory: ['ids_001.characteristics', 'ids_001.datafile', 'ids_001.tree']
    ! Structure of this directory does not depends on entry content. All IDS data are stored in printed files
    call imas_close(idx, status)

    call imas_open(trim(uriHDF5), FORCE_CREATE_PULSE, idx, status, errmsg)
    if (status.ne.0) then
        write(*,*)  'Error! Issue while creating HDF5 file: '//errmsg
    end if
    ! Content of ./testdb_hdf5 directory: ['master.h5']
    ! Structure of this directory depends on entry content. Every IDS with data will be stored in <ids_name>.h5 file
    call imas_close(idx, status)

    call imas_open(trim(uriASCII), FORCE_CREATE_PULSE, idx, status, errmsg)
    if (status.ne.0) then
        write(*,*)  'Error! Issue while creating ASCII file: '//errmsg
    end if
    ! Content of ./testdb_ascii directory: []
    ! Structure of this directory depends on entry content. Every IDS with data will be stored in <ids_name>.ids file
    call imas_close(idx, status)

end subroutine create_db_entry_uri_with_path
