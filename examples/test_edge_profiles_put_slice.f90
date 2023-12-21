program test
  ! This program puts dummy data in the DB entry, just for practicing the AL PUT command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  use ids_routines
  implicit none

  !integer,parameter :: ids_real=kind(1.0D0)
  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_edge_profiles) :: ep, ep2, ep3  ! Declaration of the empty ids to be filled

  integer :: pulse, run, refpulse, refrun, status, i, j, k, dum1, nfast, nprofiles, nggd, b
  integer :: interpol, pulsectx
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3

  character(len=132):: longstring
  character(len=132)::user, tokamak, version
  character(STRMAXLEN):: uri
  integer, dimension(2) :: BACKEND = (/MDSPLUS_BACKEND, HDF5_BACKEND/)

  pulse =100
  run = 3

  ! length of each GGD AoS
  nfast = 100 ! total number of fast steps
  nprofiles = 10 ! save every 10 fast steps
  nggd = 50  ! save every 50 fast steps

  ! write(*,*) 'Open pulse in MDS !'
  call get_environment_variable('USER',user)
  tokamak = 'test'
  version = '3'

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)
     call al_build_uri_from_legacy_parameters(BACKEND(b), pulse, run, user, tokamak, version, "", uri, status)
     call al_begin_dataentry_action(uri, FORCE_CREATE_PULSE, pulsectx, status)
     write(*,*) 'Created pulse file, pulsectx = ', pulsectx

     ! Define a first generic vector and its time base
     time_1 = (/1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0/)
     vect1DDouble_1 = time_1*10
     
     ! Define a second generic vector
     time_2 = (/11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0/)
     vect1DDouble_2 = time_2*2.+10.
     
     ! Fill the time-independent fields with data
     ep%ids_properties%homogeneous_time = 0 ! Mandatory to define this property
     allocate(ep%ids_properties%comment(1))
     ep%ids_properties%comment(1) = 'This is a test ids put using put_slice'
     
     ! call ids_put_non_timed(pulsectx,"edge_profiles",ep)  ! OLD LL
     ! write(*,*) 'Completed put_non_timed'
     
     do i=1,nfast
        ep%ids_properties%homogeneous_time = 0 ! Redefine it in the IDS variable for the time loop
        ! allocate the ids fields in the fast loop
        allocate(ep%ggd_fast(1)) ! Allocate only the AoS to be put, time coordinate of size 1
        ep%ggd_fast(1)%time = 0.1 * i
        allocate(ep%ggd_fast(1)%electrons%temperature(1)) ! Value given on 1 position
        ep%ggd_fast(1)%electrons%temperature(1)%value = 100.0 + 0.1*i
        !write(*,*) 'Completed allocation of ggd_fast'
        
        if (modulo(i,nprofiles).EQ.1) then
           write(*,*) "Time to save full ggd", i
           allocate(ep%ggd(1)) ! Allocate only the AoS to be put, time coordinate of size 1
           ep%ggd(1)%time = 0.1 * i
           allocate(ep%ggd(1)%electrons%temperature(1)) ! Value given on 1 subset
           allocate(ep%ggd(1)%electrons%temperature(1)%values(3)) ! Let's assume 3 elements in the grid subset 
           ep%ggd(1)%electrons%temperature(1)%values(1) = 100.0 + 0.1*i
           ep%ggd(1)%electrons%temperature(1)%values(2) = 101.0 + 0.1*i
           ep%ggd(1)%electrons%temperature(1)%values(3) = 102.0 + 0.1*i
        endif
        
        if (modulo(i,nggd).EQ.1) then
           write(*,*) "Time to save the grid itself", i
           allocate(ep%grid_ggd(1)) ! Allocate only the AoS to be put, time coordinate of size 1
           ep%grid_ggd(1)%time = 0.1 * i
           allocate(ep%grid_ggd(1)%space(1)) ! 1 space in this grid
           ep%grid_ggd(1)%space(1)%geometry_type%index = floor(real(i/nggd)) ! Let's assume the coordinate type is changing (quite unrealistic but we will see a variation of the grid !)
        endif
        
        ! temporary patch : fill generic IDS time to the same value as the fastest time scale ... see later if we can avoid to allocate it at all (due to usage of begin_ids_put_slice)
        allocate(ep%time(1)) ! Allocate only the AoS to be put, time coordinate of size 1
        ep%time(1) = ep%ggd_fast(1)%time
        
        if (i.EQ.1) then
           call ids_put(pulsectx,"edge_profiles",ep)  ! First PUT must be called with dynamic fields to be used by subsequent put_slice calls already ALLOCATED and FILLED 
           write(*,*) 'Initial Put ',i
        else 
           call ids_put_slice(pulsectx,"edge_profiles",ep)
           write(*,*) 'Put slice ',i
        endif
        
        call ids_deallocate(ep)  ! reinitialize the IDS variable after each put/put_slice to loop again
     enddo
     
     call al_close_pulse(pulsectx, FORCE_CREATE_PULSE, status)

  end do

end program test
