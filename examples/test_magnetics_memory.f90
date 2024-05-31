program test_magnetics_memory
  use ids_routines
  implicit none

  real(ids_real) :: time = 0.21
  integer(ids_int) :: interp = 2
  integer :: dynamicsize = 10
  integer :: staticsize = 3
  integer :: idx, i, j
  type(ids_magnetics) :: magnetics, magnetics2, magnetics3
  integer :: slices, fl, d

  call imas_open('imas:memory?path=./test_db_test_magnetics', FORCE_CREATE_PULSE, idx)
  write(*,*) 'Created MDS pulse file, idx = ', idx
  
  ! set static data
  magnetics%ids_properties%homogeneous_time = 1

  ! set dynamic data
  allocate(magnetics%time(dynamicsize))
  do i=1,dynamicsize
     magnetics%time(i) = 0.1*i
  end do

  allocate(magnetics%flux_loop(staticsize))
  do j=1,staticsize
     allocate(magnetics%flux_loop(j)%flux%data(dynamicsize))
     do i=1,dynamicsize
        magnetics%flux_loop(j)%flux%data(i) = j*100.0+i
     end do
  end do
  
  print *,"putting magnetics"
  call ids_put(idx,"magnetics",magnetics)

  print *,"getting full magnetics"
  call ids_get(idx,"magnetics",magnetics2)

  slices = SIZE(magnetics2%time)
  fl = SIZE(magnetics2%flux_loop)
  print *,"nb of time slices = ",slices
  print *,"nb of flux_loop elements = ",fl

  do j=1,fl
     d = SIZE(magnetics2%flux_loop(j)%flux%data)
     print *,"nb of data slices for flux_loop(",j,") = ",d
     do i=1,d
	print *,"data(",i,") = ",magnetics2%flux_loop(j)%flux%data(i)
     end do
  end do

  print *,"get single slice of magnetics"
  call ids_get_slice(idx,"magnetics",magnetics3,time,interp)

  print *,"time(0) = ",magnetics3%time(1)
  print *,"flux_loop(0).flux.data(0) = ",magnetics3%flux_loop(1)%flux%data(1)

  call imas_close(idx)

end program test_magnetics_memory
