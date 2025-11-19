program test

  use ids_routines
  implicit none

  integer :: idx, status, b
   
  type (ids_magnetics) :: mag  ! Declaration of the ids
  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     ! Registering the 'partial_get' plugin
     call al_register_plugin ('partial_get', status)
  
     ! Binding the 'partial_get' plugin to the 'grids_ggd' node of the equilibrium IDS (as a demo purpose)
     call al_bind_plugin ('magnetics:0/flux_loop', 'partial_get', status)
  
     ! Opening the pulse file
     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_partial_plugin', FORCE_CREATE_PULSE, idx)
     write(*,*) 'Opening pulse file, idx = ', idx
  
     ! Calling 'get' will call the 'partial_get' plugin
     call ids_get(idx,"magnetics", mag)
     print *, 'flux_loop pointer associated = ', associated(mag%flux_loop)
     call ids_deallocate(mag)
     ! Unregistering the plugin since we do not need it anymore
     call al_unregister_plugin ('partial_get', status)
     call imas_close(idx)
  end do
  
end program test
