program test
  use ids_routines
  implicit none

  integer :: idx

  write(*,*) 'Calling imas_create pulse file'
  call imas_open('imas:mdsplus?path=./test_db_test_pulse_create', FORCE_CREATE_PULSE, idx)

  ! This function creates the (pulse, run) entry and opens it. The result is an identifier idx that must be used for all further access to this entry. Make sure you previously created database layout for machine 'test' by running the command `imasdb test`

  write(*,*) 'Calling imas_close'
  call imas_close(idx)

end program test

