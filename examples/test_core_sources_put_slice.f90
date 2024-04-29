program test
  ! This program puts dummy data in the DB entry, just for practicing the AL PUT command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  use ids_routines
  implicit none

  !integer,parameter :: ids_real=kind(1.0D0)
  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_core_sources) :: cs  ! Declaration of the empty ids to be filled

  integer :: idx, pulse, run, refpulse, refrun, status, i, j, k, dum1
  integer :: interpol
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3
  logical :: first_slice
  character(len=132):: longstring, usr

  character(len=5)::treename
  pulse =40
  run = 3
  refpulse = 10
  refrun =0
  treename = 'ids'

  call get_environment_variable("USER",usr)

  ! write(*,*) 'Open pulse in MDS !'
  call imas_open('imas:mdsplus?path=./test_db', FORCE_CREATE_PULSE, idx)

  !call imas_create_env(treename,pulse,run,refpulse,refrun,idx,usr,'test','3')
  write(*,*) 'Created MDS pulse file, idx = ', idx


  ! Define a first generic vector and its time base
  time_1 = (/1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0/)
  vect1DDouble_1 = time_1*10

  ! Define a second generic vector
  time_2 = (/11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0/)
  vect1DDouble_2 = time_2*2.+10.

  ! Fill the ids fields with data
  cs%ids_properties%homogeneous_time = 1 ! Mandatory to define this property
  allocate(cs%ids_properties%comment(1))
  cs%ids_properties%comment(1) = 'This is a test ids'

  ! allocate the ids fields
  allocate(cs%source(2))

  first_slice = .true.
  do i=1,size(time_1)
     !write(*,*) "Loop i = ",i

     allocate(cs%source(1)%profiles_1d(1))
     allocate(cs%source(2)%profiles_1d(1))
     allocate(cs%source(1)%profiles_1d(1)%grid%rho_tor_norm(i))        ! Varies the size of the array of structure children with time index
     cs%source(1)%profiles_1d(1)%grid%rho_tor_norm = vect1DDouble_1(1:i)
     !cs%source(1)%profiles_1d(1)%time = time_1(i)
     allocate(cs%source(1)%profiles_1d(1)%ion(i))  ! Test nested arrays of structure (type 2 AoS below a type 3), varying also the size of the nested AoS
     do j=1,i
        !write(*,*) "Loop 1 j = ",j

        cs%source(1)%profiles_1d(1)%ion(j)%z_ion = time_1(j)
        allocate(cs%source(1)%profiles_1d(1)%ion(j)%particles(i))    ! radial grid size = i == size(grid%rho_tor_norm), for ion #j of time slice #i (already quite complicated)
        cs%source(1)%profiles_1d(1)%ion(j)%particles = vect1DDouble_1(1:i) + j
     enddo
     !      allocate(cs%sources(1)%profiles_1d(i)%ion(j)%state(10))  ! Test 3rd level of nested arrays of structure (type 2 AoS below a type 2 AoS below a type 3)
     !      do k=1,10
     !          cp%profiles_1d(i)%ion(j)%state(k)%z_min = k
     !      enddo
     allocate(cs%source(2)%profiles_1d(1)%grid%rho_tor_norm(i))        ! Varies the size of the array of structure children with time index
     cs%source(2)%profiles_1d(1)%grid%rho_tor_norm = vect1DDouble_1(1:i)
     !cs%source(2)%profiles_1d(1)%time = time_1(i)
     allocate(cs%source(2)%profiles_1d(1)%ion(i))  ! Test nested arrays of structure (type 2 AoS below a type 3), varying also the size of the nested AoS
     do j=1,i
        !write(*,*) "Loop 2 j = ",j
        cs%source(2)%profiles_1d(1)%ion(j)%z_ion = time_1(j)
        allocate(cs%source(2)%profiles_1d(1)%ion(j)%particles(i))    ! radial grid size = i == size(grid/rho_tor_norm), for ion #j of time slice #i (already quite complicated)
        cs%source(2)%profiles_1d(1)%ion(j)%particles = vect1DDouble_1(1:i) + j

     enddo
     allocate(cs%time(1))
     cs%time = time_1(i)

     if (first_slice) then
        call ids_put(idx,"core_sources",cs)
        first_slice = .false.
     else
        call ids_put_slice(idx,"core_sources",cs)
     end if
  enddo

  write(*,*) "========END of PUT Part======================"

  call ids_deallocate(cs)

  call imas_close(idx)
end program test
