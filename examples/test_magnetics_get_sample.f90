program test_magnetics_get_sample
   use ids_routines
   implicit none
   real(ids_real) :: time = 0.2
   integer(ids_int) :: interp = 2
   integer :: dynamicsize = 10
   integer :: staticsize = 3
   integer :: idx, i, j, b
   real(ids_real) ::  tmin, tmax
   integer(ids_int) :: valid_nb_time_slice
   real(ids_real), dimension(0) :: dtime
   real(ids_real), dimension(1) :: dtime_1
   type(ids_magnetics) :: magnetics
   integer(ids_int) :: status

   character(len=7), dimension(1) :: BACKEND = ['hdf5   ']

   tmin = 0.3
   tmax = 0.8

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

      status = 0
      call ids_get_sample(idx, "magnetics", magnetics,  tmin, tmax, dtime, 0, status)

      if (status.ne.0) write(*,*) "Error in get_sample example: ", "error in ids_get_sample"

    
      if (ASSOCIATED(magnetics%time)) then
         write(*,*) "magnetics%time: ", size(magnetics%time)
         valid_nb_time_slice = nint((tmax-tmin)/0.1+1)
         if (size(magnetics%time) .ne. valid_nb_time_slice .and. size(magnetics%flux_loop(0)%flux%data) .ne. valid_nb_time_slice) then
            write(*,*) "Error in get_sample example", "must have ",valid_nb_time_slice," time slice"
         end if
      else
        write(*,*) "Error in get_sample example", " magnetics%time is null"
      end if

      dtime_1 =  (/0.02/) ! step

      call ids_get_sample(idx, "magnetics", magnetics,  tmin ,tmax, dtime_1, 1, status)

      if (status.ne.0) write(*,*) "Error in ids_get_sample example"
      if (ASSOCIATED(magnetics%time)) then
         write(*,*) "magnetics%time: ", size(magnetics%time), " "
         valid_nb_time_slice = nint((tmax-tmin)/dtime_1(1)+1)
         if (size(magnetics%time) .ne. valid_nb_time_slice .and. size(magnetics%flux_loop(0)%flux%data) .ne. valid_nb_time_slice) then
            write(*,*) "Error in get_sample example", "must have ",valid_nb_time_slice," time slice"
         end if
      end if

      call imas_close(idx)

   end do

 end program test_magnetics_get_sample
