program test_multi_put_slice_dynamic
  use ids_routines
  implicit none

  type(ids_equilibrium) :: equil, equil_check
  integer :: status, pctx, i, j
  character(len=132):: usr
  character(STRMAXLEN):: uri
  integer :: pulse, run, s, r, b
  integer, dimension(2) :: BACKEND = (/MDSPLUS_BACKEND, HDF5_BACKEND/)

  pulse = 1
  run  = 1234
  s    = 2
  r    = 2
  call get_environment_variable("USER",usr)

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call al_build_uri_from_legacy_parameters(BACKEND(b),pulse,run,usr,"test","3", "", uri, status)
     call al_begin_dataentry_action(uri, FORCE_CREATE_PULSE, pctx, status)
     ! if (status.ne.0) ERROR STOP 'Error setting up the pulse'
     if (status.ne.0) ERROR STOP 'Error creating the pulse'
  
     equil%ids_properties%homogeneous_time = 1
     allocate(equil%time(s))
     allocate(equil%time_slice(s))
     allocate(equil%code%output_flag(s))
     
     do j=1,r
        do i=1,s
           equil%time(i)                            = 0.1_ids_real*i+j
           equil%time_slice(i)%global_quantities%ip = -1.0_ids_real*i-j*10
           equil%code%output_flag(i)                = 0
        end do
        print *,"put_slice #",j
        call ids_put_slice(pctx,"equilibrium",equil)
     end do
     
     call ids_get(pctx,"equilibrium",equil_check)
     
     print *,equil_check%time
     if (SIZE(equil_check%time).ne.(s*r)) ERROR STOP 'Error: wrong size for time'
     
     print *,equil_check%code%output_flag
     if (SIZE(equil_check%code%output_flag).ne.(s*r)) ERROR STOP 'Error: wrong size for code%output_flag'
     
     do i=1,SIZE(equil_check%time_slice)
        print *,equil_check%time_slice(i)%global_quantities%ip
     end do
     if (SIZE(equil_check%time_slice).ne.(s*r)) ERROR STOP 'Error: wrong size for time_slice AoS'
     
     call al_close_pulse(pctx, CLOSE_PULSE, status)
     if (status.ne.0) ERROR STOP 'Error closing the pulse'
     
     call al_end_action(pctx, status)
     if (status.ne.0) ERROR STOP 'Error ending the pulse context'

  end do
  
end program test_multi_put_slice_dynamic
