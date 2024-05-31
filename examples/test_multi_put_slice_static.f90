program test_multi_put_slice_static
  use ids_routines
  implicit none

  type(ids_bolometer) :: bolo, bolo_check
  integer :: status, pctx, i, j
  integer :: s, r, b
  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']
  s    = 2
  r    = 2

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_core_profiles', FORCE_CREATE_PULSE, pctx)

     
     bolo%ids_properties%homogeneous_time = 1
     allocate(bolo%channel(1))
     allocate(bolo%time(s))
     allocate(bolo%channel(1)%power%data(s))
     allocate(bolo%code%output_flag(s))
     
     do j=1,r
        do i=1,s
           bolo%time(i)                  = 0.1_ids_real*i+j
           bolo%channel(1)%power%data(i) = 1000.0_ids_real*j+i*10
           bolo%code%output_flag(i)      = 0
        end do
        print *,"put_slice #",j
        call ids_put_slice(pctx,"bolometer",bolo)
     end do
     
     call ids_get(pctx,"bolometer",bolo_check)
     
     print *,bolo_check%time
     if (SIZE(bolo_check%time).ne.(s*r)) ERROR STOP 'Error: wrong size for time'
     
     print *,bolo_check%code%output_flag
     if (SIZE(bolo_check%code%output_flag).ne.(s*r)) ERROR STOP 'Error: wrong size for code%output_flag'
     
     do i=1,SIZE(bolo_check%channel(1)%power%data)
        print *,bolo_check%channel(1)%power%data(i)
     end do
     if (SIZE(bolo_check%channel(1)%power%data).ne.(s*r)) ERROR STOP 'Error: wrong size for channel(1)%power%data'
     
     call al_close_pulse(pctx, CLOSE_PULSE, status)
     if (status.ne.0) ERROR STOP 'Error closing the pulse'
     
     call al_end_action(pctx, status)
     if (status.ne.0) ERROR STOP 'Error ending the pulse context'
     
  end do
  
end program test_multi_put_slice_static
