program test_debug_plugin

  use ids_routines
  implicit none

  integer :: idx, mode, status, b
   
  type (ids_magnetics) :: mag  ! Declaration of the ids

  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  ! Registering the 'debug' plugin
  call al_register_plugin ('debug', status)
  
  ! Binding the 'debug' plugin to the access_layer node of the magnetics IDS (as a demo purpose)
  call al_bind_plugin ('magnetics:0/ids_properties/version_put/access_layer', 'debug', status)
  
  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     ! Opening the pulse file
     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_debug_plugin', FORCE_CREATE_PULSE, idx)
     write(*,*) 'Opened pulse file, idx = ', idx
     
     ! Calling 'get' will call the 'debug' plugin
     call ids_get(idx,"magnetics", mag)
     
     call imas_close(idx)
  end do
end program test_debug_plugin
