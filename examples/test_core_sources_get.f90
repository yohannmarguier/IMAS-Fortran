program test
  ! This program gets data from the DB entry, just for practicing the AL GET command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  use ids_routines
  implicit none

  !integer,parameter :: ids_real=kind(1.0D0)
  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_core_sources) :: cs , cs2 ! Declaration of the empty ids to be filled

  integer :: idx, i, j
  integer :: interpol
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3

  call imas_open('imas:mdsplus?path=./test_db_test_core_sources', OPEN_PULSE, idx)
  write(*,*) 'Opened MDS pulse file, idx = ', idx

!!!! TEST OF THE GET FULL IDS
  if (.TRUE.) THEN
     call ids_get(idx,"core_sources",cs)
     write(*,*) "IDS_Properties homogeneous : ", cs%IDS_Properties%homogeneous_time
     !  write(*,*) "IDS_Properties comment : ", cs%IDS_Properties%comment(1)
     write(*,*) "Size of cs%source : ", size(cs%source)
     write(*,*) "Size of cs%source(1)%profiles_1d : ", size(cs%source(1)%profiles_1d)
     write(*,*) "Size of cs%source(2)%profiles_1d : ", size(cs%source(2)%profiles_1d)

     do i=1,size(cs%source(1)%profiles_1d)
        write(*,*) "Time slice i = ", cs%source(1)%profiles_1d(i)%time
     enddo

  endif ! if 0


  if (.TRUE.) THEN
     write(*,*) "Test of the GET_SLICE function"
     interpol = 2 ! Interpolation mode = Linear interpolation
     twant = 360
     call ids_deallocate(cs)

     call ids_get_slice(idx,"core_sources/2",cs,twant,interpol)
     write(*,*) "IDS_Properties homogeneous : ", cs%IDS_Properties%homogeneous_time
     !  write(*,*) "IDS_Properties comment : ", cs%IDS_Properties%comment(1)
     write(*,*) "Size of cs%source : ", size(cs%source)
     write(*,*) "Size of cs%source(1)%profiles_1d : ", size(cs%source(1)%profiles_1d)
     write(*,*) "Size of cs%source(2)%profiles_1d : ", size(cs%source(2)%profiles_1d)

     do i=1,size(cs%source(1)%profiles_1d)
        write(*,*) "Time slice i = ", cs%source(1)%profiles_1d(i)%time
        write(*,*) "rho = ", cs%source(1)%profiles_1d(i)%grid%rho_tor_norm
     enddo
  endif


  call ids_deallocate(cs)

  call imas_close(idx)
  write(*,*) "Program completed"

end program test
