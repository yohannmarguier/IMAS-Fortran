program test_multi_put_slice_static
  use ids_routines
  implicit none

  type(ids_gas_injection) :: gas_inj, gas_check
  integer :: status, pctx, i, j
  integer :: s, length, b
  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']
  s      = 2
  length = 2

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_gas_injection', FORCE_CREATE_PULSE, pctx)

     gas_inj%ids_properties%homogeneous_time = 1
     allocate(gas_inj%pipe(1))
     allocate(gas_inj%time(s))
     allocate(gas_inj%pipe(1)%name(1))
     allocate(gas_inj%pipe(1)%flow_rate%data(s))
     allocate(gas_inj%pipe(1)%valve_indices(3))
     allocate(gas_inj%code%output_flag(s))

     allocate(gas_inj%valve(3))
     allocate(gas_inj%valve(1)%name(1))
     allocate(gas_inj%valve(2)%name(1))
     allocate(gas_inj%valve(3)%name(1))
     gas_inj%valve(1)%name(1) = "A"
     gas_inj%valve(2)%name(1) = "B"
     gas_inj%valve(3)%name(1) = "C"
     
     gas_inj%pipe(1)%name = "AG"
     gas_inj%pipe(1)%valve_indices(1) = 3
     gas_inj%pipe(1)%valve_indices(2) = 2
     gas_inj%pipe(1)%valve_indices(3) = 1
     do j=1,s
        do i=1,length
           gas_inj%time(i)                   = 0.1_ids_real*i+j
           gas_inj%pipe(1)%flow_rate%data(j) = .33*j
           gas_inj%code%output_flag(i)       = 0
        end do
        print *,"put_slice #",j
        call ids_put_slice(pctx,"gas_injection",gas_inj)
     end do
     
     call ids_get(pctx,"gas_injection",gas_check)
     
     print *,gas_check%time
     if (SIZE(gas_check%time).ne.(s*length)) ERROR STOP 'Error: wrong size for time'
     
     print *,gas_check%code%output_flag
     if (SIZE(gas_check%code%output_flag).ne.(s*length)) ERROR STOP 'Error: wrong size for code%output_flag'
     
     do i=1,SIZE(gas_check%pipe(1)%valve_indices)
        print *,gas_check%valve(gas_check%pipe(1)%valve_indices(i))%name
     end do
     if (SIZE(gas_check%pipe(1)%valve_indices).ne.3) then
         ERROR STOP 'Error: wrong size for pipe(1)%valve_indices'
     end if
     
     call al_close_pulse(pctx, CLOSE_PULSE, status)
     if (status.ne.0) ERROR STOP 'Error closing the pulse'
     
     call al_end_action(pctx, status)
     if (status.ne.0) ERROR STOP 'Error ending the pulse context'
     
  end do
  
end program test_multi_put_slice_static
