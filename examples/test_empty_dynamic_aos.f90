program test_empty_dynamic_aos
  use ids_routines
  implicit none

  type(ids_core_profiles) :: corep, corep2
  integer :: idx, s, b

  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)
     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_empty_dynamic_aos', FORCE_CREATE_PULSE, idx)

     corep%ids_properties%homogeneous_time = 1
     allocate(corep%time(1))
     corep%time(1) = 0.01
     
     allocate(corep%profiles_1d(1))
     
     call ids_put(idx,'core_profiles',corep)
     call ids_get(idx,'core_profiles',corep2)
     
     if (ASSOCIATED(corep2%profiles_1d)) then
        s = SIZE(corep%profiles_1d)
        print *,'SIZE(core_profiles%profiles_1d) = ',s
        if (s.ne.1) then
           print *,' while size of 1 was expected (ERROR)'
        end if
     else
        print *,'ERROR: core_profiles%profiles_1d is not associated!'
     end if
     
     call ids_deallocate(corep)
     call ids_deallocate(corep2)
     
     call imas_close(idx)
  end do

end program test_empty_dynamic_aos
