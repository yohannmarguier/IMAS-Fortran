program test_empty_aos
  use ids_routines
  implicit none

  type(ids_core_profiles) :: corep, corep2
  type(ids_core_sources) :: cores, cores2
  integer :: idx, s

  character(len=132) :: usr

  call get_environment_variable("USER",usr)
  call imas_open('imas:mdsplus?path=./test_db', FORCE_CREATE_PULSE, idx)

  corep%ids_properties%homogeneous_time = 1
  allocate(corep%time(1))
  corep%time(1) = 0.01

  cores%ids_properties%homogeneous_time = 1
  allocate(cores%time(1))
  cores%time(1) = 0.01

  call ids_put(idx,'core_profiles',corep)
  call ids_put(idx,'core_sources',cores)

  call ids_get(idx,'core_profiles',corep2)
  call ids_get(idx,'core_sources',cores2)

  if (ASSOCIATED(corep2%profiles_1d)) then
     s = SIZE(corep%profiles_1d)
     print *,'ERROR: SIZE(core_profiles%profiles_1d) = ',s,' while expected to be not associated!'
  else
     print *,'core_profiles%profiles_1d is not associated, as expected'
  end if

  if (ASSOCIATED(cores2%source)) then
     s = SIZE(cores2%source)
     print *,'ERROR: SIZE(core_sources%source) = ',s,' while expected to be not associated!'
  else
     print *,'core_sources%source is not associated, as expected'
  end if

  call ids_deallocate(corep)
  call ids_deallocate(corep2)

  call ids_deallocate(cores)
  call ids_deallocate(cores2)
  
  call imas_close(idx)
  
end program test_empty_aos
