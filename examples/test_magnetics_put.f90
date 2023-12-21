program test_magnetics_put
  use ids_routines
  implicit none

  real(ids_real) :: time = 0.2
  integer(ids_int) :: interp = 2
  integer :: pulse = 54
  integer :: run = 1
  integer :: dynamicsize = 10
  integer :: staticsize = 3
  integer :: pulsectx, status, i, j, b
  type(ids_magnetics) :: magnetics
  character(256) :: userName 
  character(STRMAXLEN) :: uri 
  integer, dimension(2) :: BACKEND = (/MDSPLUS_BACKEND, HDF5_BACKEND/)

  call get_environment_variable("USER",userName)

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call al_build_uri_from_legacy_parameters(BACKEND(b), pulse, run, userName, "test", "3", "", uri, status)
     call al_begin_dataentry_action(uri, FORCE_CREATE_PULSE, pulsectx, status);
     write(*,*) 'Created pulse file, pulsectx = ', pulsectx
  
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
     call ids_put(pulsectx,"magnetics",magnetics)
     
     call imas_close(pulsectx)

  end do
  
end program test_magnetics_put
