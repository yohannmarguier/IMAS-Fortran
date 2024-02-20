program read_summary_ids

  use ids_routines
  implicit none

! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║              initialize pulse description (e.g. pusle No.)                   ║
! ╚══════════════════════════════════════════════════════════════════════════════╝

  integer             :: pulse         = 54     ! pulse number of MDS+ file
  integer             :: run           = 1      ! shot number of MDS+ file
  integer             :: idxIn                  ! index of opened input file
  integer             :: idxOut                 ! index of opened output file
  integer             :: status                 ! error code of the operation
  integer             :: i                      ! used for loops over timed values
  type(ids_summary)   :: summaryIDSin           ! Summary IDS structure for input
  type(ids_summary)   :: summaryIDSout          ! Summary IDS structure for output
  character(len=256)  :: userName               ! name of the user running the code
  character(len=10)   :: dbName        = 'f4f'  ! name of the database
  character(len=5)    :: treeName      = 'ids'  ! name of the MDS+ tree structure 

! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║                          open existing pulse file                            ║
! ╚══════════════════════════════════════════════════════════════════════════════╝

! Get users name so we can access their personal database.

  call get_environment_variable( "USER" , userName)

! Please note that legacy open function allows to open MDS+ files only.
! For HDF5 files you have to either call low level functions or use
! URI based open functions - URI based open is shown in other samples.

  call imas_open_env( treeName,          &
                      pulse,             &
                      run,               &
                      idxIn,             &
                      trim( userName ),  &
                      dbName,            &
                      '3' )

! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║                                get Summary IDS                               ║
! ╚══════════════════════════════════════════════════════════════════════════════╝

  call ids_get( idxIn, "summary", summaryIDSin )

! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║                                data extraction                               ║
! ╚══════════════════════════════════════════════════════════════════════════════╝

  write (*,*) '=== IDS SUMMARY COMMENT: ',                 summaryIDSin%ids_properties%comment
  write (*,*) '=== IDS SUMMARY AL PUT VERSION: ',          summaryIDSin%ids_properties%version_put%access_layer
  write (*,*) '=== IDS SUMMARY global_quantities/ip size', size( summaryIDSin%global_quantities%ip%value )
  do i=1,size( summaryIDSin%global_quantities%ip%value )
    write(*,*) summaryIDSin%global_quantities%ip%value( i )
  enddo

! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║                      create new data entry (new pulse file)                  ║
! ╚══════════════════════════════════════════════════════════════════════════════╝

! We are stroring new entry with a run number of input increased by 1.

  call imas_create_env( treeName,          &
                        pulse,             &
                        run + 1,           &
                        0,                 &   ! reference pulse and shot are
                        0,                 &   ! not used; it's safe to pass 0
                        idxOut,            &
                        trim( userName ),  &
                        dbName,            &
                        '3' )

! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║                          copy data into new Summary IDS                      ║
! ╚══════════════════════════════════════════════════════════════════════════════╝

! Copy time vector from input IDS to output IDS; at first, we have to allocate
! memory for the time vector.

  allocate(summaryIDSout%time( size( summaryIDSin%time ) ) )
  do i=1, size( summaryIDSin%time )
    summaryIDSout%time( i ) = summaryIDSin%time( i )
  enddo

! Set time mode to homogenous time; note that field
!
!          ids_properties%homogeneous_time
!
! must be set!

  summaryIDSout%ids_properties%homogeneous_time         = 1
  summaryIDSout%ids_properties%comment                  = summaryIDSin%ids_properties%comment
  summaryIDSout%ids_properties%version_put%access_layer = summaryIDSin%ids_properties%version_put%access_layer
  
! Copy global_quantties%ip%value field; at first, we have to allocate
! memory for the ip vector.

  allocate( summaryIDSout%global_quantities%ip%value(       &
              size( summaryIDSin%global_quantities%ip%value ) &
            )                                              &
          )
  
  do i=1, size( summaryIDSin%global_quantities%ip%value )
    summaryIDSout%global_quantities%ip%value( i ) = summaryIDSin%global_quantities%ip%value( i )
  enddo

! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║                          save data into new pulse file                       ║
! ╚══════════════════════════════════════════════════════════════════════════════╝

  call ids_put( idxOut, "summary", summaryIDSout )

! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║                             clean up and close files                         ║
! ╚══════════════════════════════════════════════════════════════════════════════╝

  call ids_deallocate( summaryIDSin  )
  call ids_deallocate( summaryIDSout )

  call imas_close( idxIn  )
  call imas_close( idxOut )

end program read_summary_ids

