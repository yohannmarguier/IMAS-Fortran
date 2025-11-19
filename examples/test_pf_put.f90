program test
  ! This program puts dummy data in the DB entry, just for practicing the AL PUT command
  use ids_routines
  implicit none

  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_pf_active) :: pf, pf2, pf3  ! Declaration of the empty ids to be filled

  integer :: idx, i, b
  integer :: interpol
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3

  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_pf', FORCE_CREATE_PULSE, idx)
     write(*,*) 'Created pulse file, idx = ', idx

     ! Define a first generic vector and its time base
     time_1 = (/1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0/)
     vect1DDouble_1 = time_1*10
     
     ! Define a second generic vector and its time base
     time_2 = (/11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0/)
     vect1DDouble_2 = time_2*2.+10.
     
     ! allocate the ids fields
     allocate(pf%coil(2))
     allocate(pf%coil(1)%current%data(size(vect1DDouble_1)))
     allocate(pf%coil(1)%current%time(size(vect1DDouble_1)))
     allocate(pf%coil(2)%current%data(size(vect1DDouble_2)))
     allocate(pf%coil(2)%current%time(size(vect1DDouble_2)))
     ! Fill the ids fields with data
     pf%ids_properties%homogeneous_time = 0 ! Mandatory to define this property
     allocate(pf%ids_properties%comment(1))
     pf%ids_properties%comment(1) = 'This is a test ids'
     allocate(pf%coil(1)%name(1))
     pf%coil(1)%name(1) = 'VS 1'
     allocate(pf%coil(2)%name(1))
     pf%coil(2)%name(1) = 'VS 2'
     pf%coil(1)%current%data = vect1DDouble_1
     pf%coil(1)%current%time = time_1
     pf%coil(2)%current%data = vect1DDouble_2
     pf%coil(2)%current%time = time_2
     write(*,*) 'Start Putting the PF ids'
     
     call ids_put(idx,"pf_active",pf)
     write(*,*) "========END of PUT Part======================"
     
     
!!!! TEST OF THE GET FULL ids
     call ids_get(idx,"pf_active",pf2)
     write(*,*) "ids_Properties homogeneous : ", pf2%ids_Properties%homogeneous_time
     write(*,*) "ids_Properties comment : ", pf2%ids_Properties%comment(1)
     write(*,*) "Coil 1 current data : ", pf2%coil(1)%current%data
     write(*,*) "Coil 1 current time : ", pf2%coil(1)%current%time
     write(*,*) "Coil 2 current data : ", pf2%coil(2)%current%data
     write(*,*) "Coil 2 current time : ", pf2%coil(2)%current%time
     write(*,*) "Coil 1 name : ", pf2%coil(1)%name(1)
     write(*,*) "Coil 2 name : ", pf2%coil(2)%name(1)
     
     call ids_deallocate(pf2)
     write(*,*) "========END of GET Part======================"
     
!!!! TEST OF THE GET SLICE ids
     interpol = 2 ! Interpolation mode = Previous neighbour
     twant = 21
     call ids_get_slice(idx,"pf_active",pf3, twant, interpol)
     write(*,*) "========GET SLICE RESULTS AT TIME ", twant
     write(*,*) "Coil 1 current data : ", pf3%coil(1)%current%data
     write(*,*) "Coil 1 current time : ", pf3%coil(1)%current%time
     write(*,*) "Coil 2 current data : ", pf3%coil(2)%current%data
     write(*,*) "Coil 2 current time : ", pf3%coil(2)%current%time
     write(*,*) "Coil 1 name : ", pf3%coil(1)%name(1)
     write(*,*) "Coil 2 name : ", pf3%coil(2)%name(1)
     
     call ids_deallocate(pf)
     call ids_deallocate(pf3)
     
     call imas_close(idx)

  end do
  
end program test
