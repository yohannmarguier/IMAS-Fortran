program test_debug_plugin

  use ids_routines
  implicit none

  integer :: idx, mode, status
   
  type (ids_magnetics) :: mag  ! Declaration of the ids
  character(STRMAXLEN) :: uri
  character(len=132):: usr
  integer :: pulse = 54
  integer :: run = 1
  integer :: pulsectx

  call get_environment_variable("USER",usr)

  ! Registering the 'debug' plugin
  call al_register_plugin ('debug', status)
  
  ! Binding the 'debug' plugin to the access_layer node of the magnetics IDS (as a demo purpose)
  call al_bind_plugin ('magnetics:0/ids_properties/version_put/access_layer', 'debug', status)
  
  ! Opening the pulse file
  call al_build_uri_from_legacy_parameters(MDSPLUS_BACKEND, pulse, run, usr, "test", "3", "", uri, status)
  call al_begin_dataentry_action(uri, OPEN_PULSE, pulsectx, status);
  write(*,*) 'Opened pulse file, pulsectx = ', pulsectx
  
  ! Calling 'get' will call the 'debug' plugin
  call ids_get(pulsectx,"magnetics", mag)

  call imas_close(pulsectx)
  
end program test_debug_plugin
