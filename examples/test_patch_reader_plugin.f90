program test_patch_reader_plugin

  use ids_routines
  implicit none

  integer :: i, j, k, idx, status, nx, ny
   
  type (ids_camera_ir) :: cir  ! Declaration of the empty ids to be filled

  cir%ids_properties%homogeneous_time = 1 ! Mandatory to define this property
  allocate(cir%time(2))
  cir%time = (/ 0.0, 0.1 /)
  
  allocate(cir%frame(2))
  
  nx = 15
  ny = 5
  
  allocate(cir%frame(2))
 
  do k=1,2
     allocate(cir%frame(k)%surface_temperature(nx,ny))
     do j=1,ny
        do i=1,nx
           cir%frame(k)%surface_temperature(i,j) = i + j + k - 3
        enddo
     enddo
  enddo
  
  ! Creating the pulse file
 
 write(*,*) 'Creating pulse file, idx = ', idx
 call imas_open('imas:mdsplus?path=./test_db_test_patch_reader_plugin', FORCE_CREATE_PULSE, idx)

  call ids_put(idx,"camera_ir",cir)
  
  write(*,*) 'displaying frame 1', cir%frame(1)%surface_temperature
  write(*,*) 'displaying frame 2', cir%frame(2)%surface_temperature
  
  write(*,*) 'Closing pulse file, idx = ', idx
  call imas_close(idx)
  
  ! Registering the 'debug' plugin
  call al_register_plugin ('patch_reader', status)
  
  ! Binding the 'surface_temperature' node of the camera_ir IDS to the 'patch_reader' plugin (only for demo purpose)
  call al_bind_plugin ('camera_ir:0/frame/surface_temperature', 'patch_reader', status)
  
  call al_setvalue_int_scalar_parameter_plugin("op", 2, 'patch_reader', status);
  
  ! Opening the pulse file
  write(*,*) 'Opening pulse file, idx = ', idx
  call imas_open('imas:mdsplus?path=./test_db_test_patch_reader_plugin', OPEN_PULSE, idx)
  
  call ids_get(idx,"camera_ir",cir)
  
  write(*,*) 'displaying patched frame 1', cir%frame(1)%surface_temperature
  write(*,*) 'displaying patched frame 2', cir%frame(2)%surface_temperature
  
  call imas_close(idx)
  
  call ids_deallocate(cir)
  
  ! Unregistering the plugin since we do not need it anymore
  call al_unregister_plugin ('patch_reader', status)
  
end program test_patch_reader_plugin
