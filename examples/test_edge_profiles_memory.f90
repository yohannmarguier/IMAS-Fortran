! This program puts dummy data in the DB entry, just for practicing the AL PUT command
! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
! Heterogenous case with 3 different AoS
program test
  use ids_routines
  implicit none

  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_edge_profiles) :: ep, ep2, ep3 

  integer :: i, j, k, dum1, nfast, nprofiles, nggd
  integer :: interpol, idx
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3

  ! length of each GGD AoS
  nfast = 100 ! total number of fast steps
  nprofiles = 10 ! save every 10 fast steps
  nggd = 50  ! save every 50 fast steps

  call imas_open('imas:memory?path=./test_db_test_edge_profiles', FORCE_CREATE_PULSE, idx)
  write(*,*) 'Created in-memory pulse, idx = ', idx

  ! Define a first generic vector and its time base
  time_1 = (/1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0/)
  vect1DDouble_1 = time_1*10

  ! Define a second generic vector
  time_2 = (/11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0/)
  vect1DDouble_2 = time_2*2.+10.

  ! Fill the time-independent fields with data
  ep%ids_properties%homogeneous_time = 0 ! Mandatory to define this property
  allocate(ep%ids_properties%comment(1))
  ep%ids_properties%comment(1) = 'This is a test ids'

  allocate(ep%ggd_fast(nfast))
  do i=1,nfast
     ! allocate the ids fields in the fast loop
     ep%ggd_fast(i)%time = 0.1 * i
     allocate(ep%ggd_fast(i)%electrons%temperature(1)) ! Value given on 1 position
     ep%ggd_fast(i)%electrons%temperature(1)%value = 100.0 + 0.1*i
  enddo

  allocate(ep%ggd(floor(real(nfast/nprofiles)))) 
  do i=1,floor(real(nfast/nprofiles))
     ep%ggd(i)%time = 0.1 * i
     allocate(ep%ggd(i)%electrons%temperature(1)) ! Value given on 1 subset
     allocate(ep%ggd(i)%electrons%temperature(1)%values(3)) ! Let's assume 3 elements in the grid subset 
     ep%ggd(i)%electrons%temperature(1)%values(1) = 100.0 + 0.1*i
     ep%ggd(i)%electrons%temperature(1)%values(2) = 101.0 + 0.1*i
     ep%ggd(i)%electrons%temperature(1)%values(3) = 102.0 + 0.1*i
  enddo

  allocate(ep%grid_ggd(floor(real(nfast/nggd)))) ! Allocate only the AoS to be put, time coordinate of size 
  do i=1,floor(real(nfast/nggd))
     ep%grid_ggd(i)%time = 0.1 * i
     allocate(ep%grid_ggd(i)%space(1)) ! 1 space in this grid
     ep%grid_ggd(i)%space(1)%geometry_type%index = floor(real(i/2)) ! Let's assume the coordinate type is changing (quite unrealistic but we will see a variation of the grid !)
  enddo

  call ids_put(idx,"edge_profiles",ep)  ! First PUT must be called with dynamic fields to be used by subsequent put_slice calls already ALLOCATED and FILLED 
  call ids_deallocate(ep)  ! reinitialize the IDS variable after each put/put_slice to loop again
  write(*,*) "Put completed"


  if (.TRUE.) THEN
     call ids_get(idx,"edge_profiles",ep2)
     write(*,*) "IDS_Properties homogeneous : ", ep2%IDS_Properties%homogeneous_time
     write(*,*) "IDS_Properties comment : ", ep2%IDS_Properties%comment(1)
     write(*,*) "Size of ggd_fast : ", size(ep2%ggd_fast)
     write(*,*) "ep2%ggd_fast%time : ",ep2%ggd_fast(:)%time
     write(*,*) "ep2%ggd_fast(1)%electrons%temperature(1)%value : ", ep2%ggd_fast(1)%electrons%temperature(1)%value
     write(*,*) "ep2%ggd_fast(100)%electrons%temperature(1)%value : ", ep2%ggd_fast(100)%electrons%temperature(1)%value

     write(*,*) "Size of full ggd : ", size(ep2%ggd)
     write(*,*) "ep2%ggd%time : ",ep2%ggd(:)%time
     write(*,*) "ep2%ggd(1)%electrons%temperature(1)%values : ", ep2%ggd(1)%electrons%temperature(1)%values
     write(*,*) "ep2%ggd(10)%electrons%temperature(1)%values : ", ep2%ggd(10)%electrons%temperature(1)%values

     write(*,*) "Size of grid_ggd : ", size(ep2%grid_ggd)
     write(*,*) "ep2%grid_ggd%time : ",ep2%grid_ggd(:)%time
     write(*,*) "ep2%grid_ggd(1)%space(1)%geometry_type%index : ", ep2%grid_ggd(1)%space(1)%geometry_type%index 
     write(*,*) "ep2%grid_ggd(2)%space(1)%geometry_type%index : ", ep2%grid_ggd(2)%space(1)%geometry_type%index

  endif ! if 0

  write(*,*) "Test of the GET_SLICE function"
  interpol = 1 ! Interpolation mode = closest neighbour
  twant = 4.06
  call ids_get_slice(idx,"edge_profiles",ep3,twant,interpol)
  write(*,*) "IDS_Properties homogeneous : ", ep3%IDS_Properties%homogeneous_time
  write(*,*) "IDS_Properties comment : ", ep3%IDS_Properties%comment(1)
  write(*,*) "Size of ggd_fast : ", size(ep3%ggd_fast)
  write(*,*) "ep3%ggd_fast%time : ",ep3%ggd_fast(:)%time
  write(*,*) "ep3%ggd_fast(1)%electrons%temperature(1)%value : ", ep3%ggd_fast(1)%electrons%temperature(1)%value

  write(*,*) "Size of full ggd : ", size(ep3%ggd)
  write(*,*) "ep3%ggd%time : ",ep3%ggd(1)%time
  write(*,*) "ep3%ggd(1)%electrons%temperature(1)%values : ", ep3%ggd(1)%electrons%temperature(1)%values

  write(*,*) "Size of grid_ggd : ", size(ep3%grid_ggd)
  write(*,*) "ep3%grid_ggd%time : ",ep3%grid_ggd(1)%time
  write(*,*) "ep3%grid_ggd(1)%space(1)%geometry_type%index : ", ep3%grid_ggd(1)%space(1)%geometry_type%index 

  call ids_deallocate(ep2)
  call ids_deallocate(ep3)

  call imas_close(idx)
end program test
