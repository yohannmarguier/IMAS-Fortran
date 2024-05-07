program test
  ! This program puts dummy data in the DB entry, just for practicing the AL PUT_SLICE command
  use ids_routines
  implicit none

  real(ids_real) :: vect1DDouble_1(10), time_1(10), vect1DDouble_2(12), time_2(12)
  type (ids_pf_active) :: pf, pf2, pf3  ! Declaration of the empty ids to be filled

  integer :: idx, pulse, run, refpulse, refrun, status, i, lentime_1, dum1, lentime_2
  integer :: interpol
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3

  character(len=132):: longstring, usr
  logical :: first_slice
  character(len=5)::treename
  pulse =10
  run = 1
  refpulse = 10
  refrun =0
  treename = 'ids'


  call get_environment_variable("USER",usr)
  call imas_open('imas:mdsplus?path=./test_db_test_pf_put_slice', FORCE_CREATE_PULSE, idx)

  write(*,*) 'Created MDS pulse file, idx = ', idx


  ! Allocate a first generic vector and its time base
  lentime_1 = 10
  time_1 = (/1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0/)
  vect1DDouble_1 = time_1*10

  ! Allocate a second generic vector and its time base
  lentime_2 = 12
  time_2 = (/11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0/)
  vect1DDouble_2 = time_2*2.+10.


  ! allocate the ids fields
  allocate(pf%coil(2))

  ! Fill the ids fields with data
  pf%ids_Properties%Homogeneous_time = 1 ! Mandatory to define this property
  allocate(pf%ids_Properties%comment(1))
  pf%ids_Properties%comment(1) = 'This is a test ids'
  allocate(pf%coil(1)%name(1))
  pf%coil(1)%name(1) = 'VS 1'
  allocate(pf%coil(2)%name(1))
  pf%coil(2)%name(1) = 'VS 2'

  ! call ids_put(idx,"pf_active",pf)
  ! write(*,*) 'Start Put non-timed'
  ! call ids_put_non_timed(idx,"pf_active",pf)
  ! write(*,*) 'Completed Put non-timed'

  ! start filling the time-dependent part of the ids and put_slice it progressively within a time loop
  allocate(pf%coil(1)%current%data(1))    ! One time slice only in signals
  allocate(pf%coil(2)%current%data(1))
  allocate(pf%time(1))                 ! One time slice for the time

  first_slice = .true.
  do i=1,lentime_1
     pf%coil(1)%current%data = vect1DDouble_1(i)
     pf%coil(2)%current%data = vect1DDouble_2(i)
     pf%time = time_1(i)
     if (first_slice) then
        call ids_put(idx,"pf_active",pf)
        first_slice = .false.
     else
        call ids_put_slice(idx,"pf_active",pf)
     end if
     write(*,*) 'Put slice ',i
  enddo


  write(*,*) "========END of PUT Part======================"



!!!! TEST OF THE GET FULL ids
  call ids_get(idx,"pf_active",pf2)
  write(*,*) "Coil 1 current data : ", pf2%coil(1)%current%data
  !  write(*,*) "Coil 1 current time : ", pf2%coil(1)%current%time
  write(*,*) "Coil 2 current data : ", pf2%coil(2)%current%data
  !  write(*,*) "Coil 2 current time : ", pf2%coil(2)%current%time
  write(*,*) "Homogeneous time : ",pf2%time
  write(*,*) "Coil 1 name : ", pf2%coil(1)%name(1)
  write(*,*) "Coil 2 name : ", pf2%coil(2)%name(1)
  write(*,*) "ids_Properties comment : ", pf2%ids_Properties%comment(1)
  write(*,*) "ids_Properties homogeneous : ", pf2%ids_Properties%homogeneous_time

  write(*,*) "========END of GET Part======================"

!!!! TEST OF THE GET SLICE ids
  interpol = 3 ! Interpolation mode = Linear interpolation
  twant = 4.5
  call ids_get_slice(idx,"pf_active",pf3, twant, interpol)
  write(*,*) "========GET SLICE RESULTS AT TIME ", twant
  write(*,*) "Coil 1 current data : ", pf3%coil(1)%current%data
  !  write(*,*) "Coil 1 current time : ", pf3%coil(1)%current%time
  write(*,*) "Coil 2 current data : ", pf3%coil(2)%current%data
  !  write(*,*) "Coil 2 current time : ", pf3%coil(2)%current%time
  write(*,*) "Homogeneous time : ",pf3%time
  write(*,*) "Coil 1 name : ", pf3%coil(1)%name(1)
  write(*,*) "Coil 2 name : ", pf3%coil(2)%name(1)


  call ids_deallocate(pf)
  call ids_deallocate(pf2)
  call ids_deallocate(pf3)

  call imas_close(idx)
end program test
