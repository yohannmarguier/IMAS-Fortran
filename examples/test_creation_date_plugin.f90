program test

  use ids_routines
  implicit none

  integer :: idx, mode, status
   
  type (ids_magnetics) :: mag  ! Declaration of the empty ids to be filled
  character(STRMAXLEN) :: uri
  character(len=132):: usr
  integer :: pulse = 54
  integer :: run = 1

  call get_environment_variable("USER",usr)

  call al_build_uri_from_legacy_parameters(MDSPLUS_BACKEND, pulse, run, usr, "test", "3", "", uri, status)
  mag%ids_properties%homogeneous_time = 1 ! Mandatory to define this property
  allocate(mag%time(1))
  mag%time = 0.0
  
 
  ! Registering the 'creation_date' plugin
  call al_register_plugin ('creation_date', status)
  
  write(*,*) 'Using the magnetics IDS for demo purpose'
  
  ! Binding the 'creation_date' node of the magnetics IDS to the 'creation_date' plugin (only for demo purpose)
  call al_bind_plugin ('magnetics:0/ids_properties/creation_date', 'creation_date', status)
  
  ! Creating the pulse file
  
  call al_begin_dataentry_action(uri, FORCE_CREATE_PULSE, idx, status)
  write(*,*) 'Creating pulse file, idx = ', idx
  call ids_put(idx,"magnetics",mag)

  write(*,*) 'Closing pulse file, idx = ', idx
  call imas_close(idx)
  
  ! Unregistering the plugin since we do not need it anymore
  call al_unregister_plugin ('creation_date', status)
  
  ! Opening the pulse file to check the value of 'creation_date'
  
  call al_begin_dataentry_action(uri, OPEN_PULSE, idx, status)
  write(*,*) 'Opening pulse file, idx = ', idx
  
  write(*,*) 'Reading pulse file, idx = ', idx
  call ids_get(idx,"magnetics",mag)

  print *, 'creation_date = ', mag%ids_properties%creation_date
  call imas_close(idx)
  
end program test
