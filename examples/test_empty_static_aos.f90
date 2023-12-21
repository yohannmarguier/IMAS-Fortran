program test_empty_static_aos
  use ids_routines
  implicit none

  type(ids_core_sources) :: cores, cores2
  integer :: idx, s
  integer, parameter :: nsources = 3

  character(len=132) :: usr

  call get_environment_variable("USER",usr)
  call imas_create_env('ids',1,2,0,0,idx,TRIM(usr),'test','3')

  cores%ids_properties%homogeneous_time = 1
  allocate(cores%time(1))
  cores%time(1) = 0.01

  allocate(cores%source(nsources))

  call ids_put(idx,'core_sources',cores)

  call ids_get(idx,'core_sources',cores2)

  if (ASSOCIATED(cores2%source)) then
     s = SIZE(cores%source)
     print *,'SIZE(core_sources%source) = ',s
     if (s.ne.nsources) then
        print *,' while size of ',nsources,' was expected (ERROR)'
     end if
  else
     print *,'ERROR: core_sources%source is not associated!'
  end if

  call ids_deallocate(cores)
  call ids_deallocate(cores2)
  
  call imas_close(idx)

end program test_empty_static_aos
