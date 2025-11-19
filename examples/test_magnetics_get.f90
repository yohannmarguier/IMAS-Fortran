program test_magnetics_get
  use ids_routines
  implicit none

  real(ids_real) :: time = 0.21
  integer(ids_int) :: interp = 2
  integer :: i, j, b
  type(ids_magnetics) :: magnetics,magnetics_slice
  integer :: idx, slices, fl, d

  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_magnetics', OPEN_PULSE, idx)     
     write(*,*) 'Opened pulse file, idx = ', idx

     print *,"getting full magnetics"
     call ids_get(idx,"magnetics",magnetics)

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
     call ids_get_slice(idx,"magnetics",magnetics_slice,time,interp)
     
     print *,"time(0) = ",magnetics%time(1)
     print *,"flux_loop(0).flux.data(0) = ",magnetics%flux_loop(1)%flux%data(1)
     
     call imas_close(idx)

  end do
  
end program test_magnetics_get
