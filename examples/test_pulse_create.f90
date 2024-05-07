program test
  use ids_routines
  implicit none

  integer :: idx,nameLen, pulse, run, refpulse, refrun
  character(len=132):: usr
  character(len=5):: treename
  pulse =11      ! your choice
  run = 1       ! your choice
  refpulse = 0   ! dummy, not used
  refrun =0     ! dummy, not used
  treename = 'euitm'  ! dummy, not used anymore

  call get_environment_variable("USER",usr)

  write(*,*) 'Calling imas_create for pulse = ',pulse,' and run = ',run
  call imas_open('imas:mdsplus?path=./test_db_test_pulse_create', FORCE_CREATE_PULSE, idx)

  ! This function creates the (pulse, run) entry and opens it. The result is an identifier idx that must be used for all further access to this entry. Make sure you previously created database layout for machine 'test' by running the command `imasdb test`

  write(*,*) 'Calling imas_close'
  call imas_close(idx)

end program test

