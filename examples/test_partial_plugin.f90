program test

  use ids_routines
  implicit none

  integer :: idx, mode, status
   
  type (ids_magnetics) :: mag  ! Declaration of the ids
  character(STRMAXLEN) :: uri
  character(len=132)::  usr
  integer :: pulse = 54
  integer :: run = 1

  call get_environment_variable("USER",usr)

  call al_build_uri_from_legacy_parameters(MDSPLUS_BACKEND, pulse, run, usr, "test", "3", "", uri, status)
  
  ! Registering the 'partial_get' plugin
  call al_register_plugin ('partial_get', status)
  
  ! Binding the 'partial_get' plugin to the 'grids_ggd' node of the equilibrium IDS (as a demo purpose)
  call al_bind_plugin ('magnetics:0/flux_loop', 'partial_get', status)
  
  ! Opening the pulse file
  call al_begin_dataentry_action(uri, OPEN_PULSE, idx, status);
  write(*,*) 'Opening pulse file, idx = ', idx
  
  ! Calling 'get' will call the 'partial_get' plugin
  call ids_get(idx,"magnetics", mag)
  print *, 'flux_loop pointer associated = ', associated(mag%flux_loop)
  call imas_close(idx)
  
end program test
