program test
  ! This program puts dummy data in the DB entry, just for practicing the AL PUT command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  ! Heterogenous case with 3 different AoS
  use ids_schemas
  use ids_routines
  implicit none

  !integer,parameter :: ids_real=kind(1.0D0)
  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_edge_profiles) :: cp, cp2, cp3  ! Declaration of the empty ids to be filled

  integer :: status, i, j, k, nfast, nprofiles, nggd, b
  integer :: interpol, idx
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3

  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  ! length of each GGD AoS
  nfast = 100 ! total number of fast steps
  nprofiles = 10 ! save every 10 fast steps
  nggd = 50  ! save every 50 fast steps

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)
     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_edge_profiles', FORCE_CREATE_PULSE, idx)
     write(*,*) 'Created pulse file, idx = ', idx

     ! Define a first generic vector and its time base
     time_1 = (/1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0/)
     vect1DDouble_1 = time_1*10

     ! Define a second generic vector
     time_2 = (/11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0/)
     vect1DDouble_2 = time_2*2.+10.
     
     ! Fill the time-independent fields with data
     cp%ids_properties%homogeneous_time = 0 ! Mandatory to define this property
     allocate(cp%ids_properties%comment(1))
     cp%ids_properties%comment(1) = 'This is a test ids'
     
     ! call ids_put_non_timed(idx,"edge_profiles",cp)  ! OLD LL
     ! write(*,*) 'Completed put_non_timed'
     
     allocate(cp%ggd_fast(nfast))
     do i=1,nfast
        ! allocate the ids fields in the fast loop
        cp%ggd_fast(i)%time = 0.1 * i
        allocate(cp%ggd_fast(i)%electrons%temperature(1)) ! Value given on 1 position
        cp%ggd_fast(i)%electrons%temperature(1)%value = 100.0 + 0.1*i
        !write(*,*) 'Completed allocation of ggd_fast'
     enddo

     allocate(cp%ggd(floor(real(nfast/nprofiles)))) 
     do i=1,floor(real(nfast/nprofiles))
        cp%ggd(i)%time = 0.1 * i
        allocate(cp%ggd(i)%electrons%temperature(1)) ! Value given on 1 subset
        allocate(cp%ggd(i)%electrons%temperature(1)%values(3)) ! Let's assume 3 elements in the grid subset 
        cp%ggd(i)%electrons%temperature(1)%values(1) = 100.0 + 0.1*i
        cp%ggd(i)%electrons%temperature(1)%values(2) = 101.0 + 0.1*i
        cp%ggd(i)%electrons%temperature(1)%values(3) = 102.0 + 0.1*i
     enddo

     allocate(cp%grid_ggd(floor(real(nfast/nggd)))) ! Allocate only the AoS to be put, time coordinate of size 
     do i=1,floor(real(nfast/nggd))
        cp%grid_ggd(i)%time = 0.1 * i
        allocate(cp%grid_ggd(i)%space(1)) ! 1 space in this grid
        cp%grid_ggd(i)%space(1)%geometry_type%index = floor(real(i/2)) ! Let's assume the coordinate type is changing (quite unrealistic but we will see a variation of the grid !)
     enddo

     ! temporary patch : fill generic IDS time to the same value as the fastest time scale ... see later if we can avoid to allocate it at all (due to usage of begin_ids_put_slice)
     !allocate(cp%time(nfast)) ! Allocate only the AoS to be put, time coordinate of size 1
     !do i=1,nfast
     !  cp%time(i) = cp%ggd_fast(i)%time
     !enddo

     call ids_put(idx,"edge_profiles",cp)  ! First PUT must be called with dynamic fields to be used by subsequent put_slice calls already ALLOCATED and FILLED 
     call ids_deallocate(cp)  ! reinitialize the IDS variable after each put/put_slice to loop again
     write(*,*) "Put completed"

     call imas_close(idx)
  end do
  
end program test

