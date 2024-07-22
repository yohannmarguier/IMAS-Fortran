program test_magnetics_getsample
   use ids_routines
   implicit none
   real(ids_real) :: time = 0.2
   integer(ids_int) :: interp = 2
   integer :: dynamicsize = 10
   integer :: staticsize = 3
   integer :: idx, i, j, b
   real(ids_real), dimension(0) :: dtime
   type(ids_magnetics) :: magnetics
   integer(ids_int) :: status

   character(len=7), dimension(1) :: BACKEND = ['hdf5   ']
   !character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

   do b=1,size(BACKEND)
      print *,"Test with backend ",BACKEND(b)

      call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_magnetics', FORCE_CREATE_PULSE, idx)

      write(*,*) 'Created pulse file, idx = ', idx

      ! set static data
      magnetics%ids_properties%homogeneous_time = 1

      ! set dynamic data
      allocate(magnetics%time(dynamicsize))
      do i=1,dynamicsize
         magnetics%time(i) = 0.1*i
      end do

      allocate(magnetics%flux_loop(staticsize))
      do j=1,staticsize
         allocate(magnetics%flux_loop(j)%flux%data(dynamicsize))
         do i=1,dynamicsize
            magnetics%flux_loop(j)%flux%data(i) = j*100.0+i
         end do
      end do

      print *,"putting magnetics"
      call ids_put(idx,"magnetics",magnetics)

      call imas_close(idx)

      call ids_deallocate(magnetics)

      call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_magnetics', OPEN_PULSE, idx)
      print *,"Reading sample "

      !!dtime = (/0.3, 0.4, 0.5, 0.6, 0.7, 0.8/)
      status = 0
      call ids_getSample(idx, "magnetics", magnetics,  0.3, 0.8, dtime, 0, status)
      !!call ids_get(idx,"magnetics",magnetics)

      if (status.ne.0) write(*,*) "Error in getSample example: ", "error in ids_getSample"

    
      if (ASSOCIATED(magnetics%time)) then
         write(*,*) "magnetics%time: ", size(magnetics%time)
         if (size(magnetics%time) .ne. 6 .and. size(magnetics%flux_loop(0)%flux%data) .ne. 6) then
            write(*,*) "Error in getSample example", "must have 6 time slice"
         end if
      else
        write(*,*) "Error in getSample example", " magnetics%time is null"
      end if
      call imas_close(idx)

   end do

end program test_magnetics_getsample
