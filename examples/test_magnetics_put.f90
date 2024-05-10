program test_magnetics_put
  use ids_routines
  implicit none

  real(ids_real) :: time = 0.2
  integer(ids_int) :: interp = 2
  integer :: dynamicsize = 10
  integer :: staticsize = 3
  integer :: idx, i, j, b
  type(ids_magnetics) :: magnetics
    character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_core_profiles', FORCE_CREATE_PULSE, idx)

     write(*,*) 'Created pulse file, idx = ', idx
  
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
     
     call imas_close(idx)

  end do
  
end program test_magnetics_put
