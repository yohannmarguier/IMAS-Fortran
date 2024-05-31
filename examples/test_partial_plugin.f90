program test

  use ids_routines
  implicit none

  integer :: idx, status
   
  type (ids_magnetics) :: mag  ! Declaration of the ids
  
  ! Registering the 'partial_get' plugin
  call al_register_plugin ('partial_get', status)
  
  ! Binding the 'partial_get' plugin to the 'grids_ggd' node of the equilibrium IDS (as a demo purpose)
  call al_bind_plugin ('magnetics:0/flux_loop', 'partial_get', status)
  
  ! Opening the pulse file
  call imas_open('imas:mdsplus?path=./test_db_test_partial_plugin', FORCE_CREATE_PULSE, idx)
  write(*,*) 'Opening pulse file, idx = ', idx
  
  ! Calling 'get' will call the 'partial_get' plugin
  call ids_get(idx,"magnetics", mag)
  print *, 'flux_loop pointer associated = ', associated(mag%flux_loop)
  call imas_close(idx)
  
end program test
