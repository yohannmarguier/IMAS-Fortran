program test
  ! This program puts dummy data in the DB entry, just for practicing the AL PUT command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  use ids_routines
  implicit none

  !integer,parameter :: ids_real=kind(1.0D0)
  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_core_profiles) :: cp, cp2, cp3  ! Declaration of the empty ids to be filled

  integer :: idx, pulse, run, refpulse, refrun, status, i, j, k, dum1
  integer :: interpol
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3
  logical :: first_slice

  character(len=132):: longstring, usr

  character(len=5)::treename
  pulse =400
  run = 3
  refpulse = 10
  refrun =0
  treename = 'ids'

  call get_environment_variable("USER",usr)

  ! write(*,*) 'Open pulse in MDS !'
  call imas_create_env(treename,pulse,run,refpulse,refrun,idx,usr,'test','3')
  write(*,*) 'Created MDS pulse file, idx = ', idx


  ! Define a first generic vector and its time base
  time_1 = (/1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0/)
  vect1DDouble_1 = time_1*10

  ! Define a second generic vector
  time_2 = (/11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0/)
  vect1DDouble_2 = time_2*2.+10.

  ! Fill the time-independent fields with data
  cp%ids_properties%homogeneous_time = 1 ! Mandatory to define this property
  allocate(cp%ids_properties%comment(1))
  cp%ids_properties%comment(1) = 'This is a test ids put using put_slice'

  ! allocate the ids fields
  allocate(cp%global_quantities%ip(1)) ! Allocate all variables, time coordinate of size 1
  allocate(cp%time(1))
  allocate(cp%profiles_1d(1))

  write(*,*) 'Completed allocation of profiles_1d'

  ! start filling the time-dependent part of the ids and put_slice it progressively within a time loop
  first_slice = .true.
  do i=1,size(time_1)
     cp%global_quantities%ip = vect1DDouble_1(i)
     cp%time = time_1(i)
     allocate(cp%profiles_1d(1)%grid%rho_tor_norm(i))        ! Varies the size of the array of structure children with time index
     cp%profiles_1d(1)%grid%rho_tor_norm = vect1DDouble_1(1:i)
     cp%profiles_1d(1)%time = time_1(i)
     allocate(cp%profiles_1d(1)%ion(i))  ! Test nested arrays of structure (type 2 AoS below a type 3), varying also the size of the nested AoS
     do j=1,i
        cp%profiles_1d(1)%ion(j)%z_ion = time_1(j)
        allocate(cp%profiles_1d(1)%ion(j)%density(3))    ! Fixed radial grid size = 3, for ion #j of time slice #i (already quite complicated)
        cp%profiles_1d(1)%ion(j)%density = vect1DDouble_1(1:3) + j

        allocate(cp%profiles_1d(1)%ion(j)%state(10))  ! Test 3rd level of nested arrays of structure (type 2 AoS below a type 2 AoS below a type 3)
        do k=1,10
           cp%profiles_1d(1)%ion(j)%state(k)%z_min = k
        enddo
     enddo
     if (first_slice) then
        call ids_put(idx,"core_profiles",cp)
        first_slice = .false.
     else
        call ids_put_slice(idx,"core_profiles",cp)
     end if
  enddo

  write(*,*) "========END of PUT Part======================"

  call ids_deallocate(cp)
  call imas_close(idx)
end program test
