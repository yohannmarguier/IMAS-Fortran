program test_magnetics_get
  use ids_routines
  implicit none

  real(ids_real) :: time = 0.21
  integer(ids_int) :: interp = 2
  integer :: pulse = 54
  integer :: run = 1
  integer :: dynamicsize = 10
  integer :: staticsize = 3
  integer :: pulsectx, status, i, j, b
  type(ids_magnetics) :: magnetics,magnetics_slice
  character(256) :: userName 
  character(STRMAXLEN) :: uri
  integer :: slices, fl, d
  integer, dimension(2) :: BACKEND = (/MDSPLUS_BACKEND, HDF5_BACKEND/)

  call get_environment_variable("USER",userName)

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call al_build_uri_from_legacy_parameters(BACKEND(b), pulse, run, userName, "test", "3", "", uri, status)
     call al_begin_dataentry_action(uri, OPEN_PULSE, pulsectx, status);
     write(*,*) 'Opened pulse file, pulsectx = ', pulsectx

     print *,"getting full magnetics"
     call ids_get(pulsectx,"magnetics",magnetics)

     slices = SIZE(magnetics%time)
     fl = SIZE(magnetics%flux_loop)
     print *,"nb of time slices = ",slices
     print *,"nb of flux_loop elements = ",fl

     do j=1,fl
        d = SIZE(magnetics%flux_loop(j)%flux%data)
        print *,"nb of data slices for flux_loop(",j,") = ",d
        do i=1,d
           print *,"data(",i,") = ",magnetics%flux_loop(j)%flux%data(i)
        end do
     end do
     
     print *,"get single slice of magnetics"
     call ids_get_slice(pulsectx,"magnetics",magnetics_slice,time,interp)
     
     print *,"time(0) = ",magnetics%time(1)
     print *,"flux_loop(0).flux.data(0) = ",magnetics%flux_loop(1)%flux%data(1)
     
     call imas_close(pulsectx)

  end do
  
end program test_magnetics_get
