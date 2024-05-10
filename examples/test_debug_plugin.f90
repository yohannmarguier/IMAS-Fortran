program test_debug_plugin

  use ids_routines
  implicit none

  integer :: idx, mode, status
   
  type (ids_magnetics) :: mag  ! Declaration of the ids

  ! Registering the 'debug' plugin
  call al_register_plugin ('debug', status)
  
  ! Binding the 'debug' plugin to the access_layer node of the magnetics IDS (as a demo purpose)
  call al_bind_plugin ('magnetics:0/ids_properties/version_put/access_layer', 'debug', status)
  
  ! Opening the pulse file
  call imas_open('imas:mdsplus?path=./test_db_test_debug_plugin', FORCE_CREATE_PULSE, idx)
  write(*,*) 'Opened pulse file, idx = ', idx
  
  ! Calling 'get' will call the 'debug' plugin
  call ids_get(idx,"magnetics", mag)

  call imas_close(idx)
  
end program test_debug_plugin
