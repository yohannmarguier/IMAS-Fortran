program test
  use ids_routines
  implicit none

  integer :: idx, status
  character(:), allocatable :: retmsg

  write(*,*) 'Calling imas_create pulse file'
  call imas_open('imas:hdf5?path=./test_db_test_pulse_create', FORCE_CREATE_PULSE, idx, status, retmsg)

  if (status.ne.0) then
     print *,retmsg
  else
     write(*,*) 'Calling imas_close'
     call imas_close(idx)
  end if
  
end program test

