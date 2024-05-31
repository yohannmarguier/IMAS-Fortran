program test_multi_put_slice_dynamic
  use ids_routines
  implicit none

  type(ids_equilibrium) :: equil, equil_check
  integer :: status, pctx, i, j
  integer :: s, r, b
  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']
  s    = 2
  r    = 2

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_core_profiles', FORCE_CREATE_PULSE, pctx)

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
