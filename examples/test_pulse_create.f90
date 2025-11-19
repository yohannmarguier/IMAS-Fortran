program test
  use ids_routines
  implicit none

  integer :: idx, status, b
  character(:), allocatable :: retmsg

  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)
  
     write(*,*) 'Calling imas_create pulse file'
     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_pulse_create', FORCE_CREATE_PULSE, idx, status, retmsg)
     
     if (status.ne.0) then
        print *,retmsg
     else
        write(*,*) 'Calling imas_close'
        call imas_close(idx)
     end if
  end do
end program test

