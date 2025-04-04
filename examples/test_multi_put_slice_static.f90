program test_multi_put_slice_static
  use ids_routines
  implicit none

  type(ids_camera_visible) :: camera, camera_check
  integer :: status, pctx, i, j
  integer :: s, r, b
  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']
  s    = 2
  r    = 2

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_core_profiles', FORCE_CREATE_PULSE, pctx)

     
     camera%ids_properties%homogeneous_time = 1
     allocate(camera%channel(1))
     allocate(camera%time(s))
     allocate(camera%channel(1)%viewing_angle_beta_bounds(s))
     allocate(camera%code%output_flag(s))
     
     do j=1,r
        do i=1,s
           camera%time(i)                  = 0.1_ids_real*i+j
           camera%channel(1)%viewing_angle_beta_bounds(i) = 1000.0_ids_real*j+i*10
           camera%code%output_flag(i)      = 0
        end do
        print *,"put_slice #",j
        call ids_put_slice(pctx,"camera_visible",camera)
     end do
     
     call ids_get(pctx,"camera_visible",camera_check)
     
     print *,camera_check%time
     if (SIZE(camera_check%time).ne.(s*r)) ERROR STOP 'Error: wrong size for time'
     
     print *,camera_check%code%output_flag
     if (SIZE(camera_check%code%output_flag).ne.(s*r)) ERROR STOP 'Error: wrong size for code%output_flag'
     
     do i=1,SIZE(camera_check%channel(1)%viewing_angle_beta_bounds)
        print *,camera_check%channel(1)%viewing_angle_beta_bounds(i)
     end do
     if (SIZE(camera_check%channel(1)%viewing_angle_beta_bounds).ne.(s)) then
         ERROR STOP 'Error: wrong size for channel(1)%viewing_angle_beta_bounds'
     end if
     
     call al_close_pulse(pctx, CLOSE_PULSE, status)
     if (status.ne.0) ERROR STOP 'Error closing the pulse'
     
     call al_end_action(pctx, status)
     if (status.ne.0) ERROR STOP 'Error ending the pulse context'
     
  end do
  
end program test_multi_put_slice_static
