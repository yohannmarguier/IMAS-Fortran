program test
  ! This program puts dummy data in the DB entry, just for practicing the AL PUT command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  use ids_routines
  implicit none

  !integer,parameter :: DP=kind(1.0D0)
  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_core_profiles) :: cp, cp2, cp3  ! Declaration of the empty ids to be filled

  integer :: idx, status, i, j, k, b
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3
  integer :: interpol

  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_core_profiles', FORCE_CREATE_PULSE, idx)
     write(*,*) 'Created file, status = ', status

     ! Define a first generic vector and its time base
     time_1 = (/1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0/)
     vect1DDouble_1 = time_1*10

     ! Define a second generic vector
     time_2 = (/11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0/)
     vect1DDouble_2 = time_2*2.+10.

     ! allocate the ids fields
     allocate(cp%profiles_1d(size(time_1)))
     
     write(*,*) 'Completed allocation of profiles_1d'
     
     do i=1,size(time_1)
        allocate(cp%profiles_1d(i)%grid%rho_tor_norm(i))        ! Varies the size of the array of structure children with time index
        cp%profiles_1d(i)%grid%rho_tor_norm = vect1DDouble_1(1:i)
        cp%profiles_1d(i)%time = time_1(i)
        allocate(cp%profiles_1d(i)%ion(i))  ! Test nested arrays of structure (type 2 AoS below a type 3), varying also the size of the nested AoS
        do j=1,i
           cp%profiles_1d(i)%ion(j)%z_ion = time_1(j)
           allocate(cp%profiles_1d(i)%ion(j)%density(3))    ! Fixed radial grid size = 3, for ion #j of time slice #i (already quite complicated)
           cp%profiles_1d(i)%ion(j)%density = vect1DDouble_1(1:3) + j
           
           allocate(cp%profiles_1d(i)%ion(j)%state(10))  ! Test 3rd level of nested arrays of structure (type 2 AoS below a type 2 AoS below a type 3)
           do k=1,10
              cp%profiles_1d(i)%ion(j)%state(k)%z_min = k
           end do
        enddo
     enddo
     
     write(*,*) 'Completed filling of profiles_1d fields'
     
     
     ! Fill the ids fields with data
     cp%ids_properties%homogeneous_time = 0 ! Mandatory to define this property
     allocate(cp%ids_properties%comment(1))
     cp%ids_properties%comment(1) = 'This is a test ids'
     allocate(cp%global_quantities%ip(size(time_2)))
     cp%global_quantities%ip = vect1DDouble_2
     allocate(cp%time(size(time_2)))
     cp%time = time_2
     
     write(*,*) 'Start Putting the core_profiles IDS'
     
     call ids_put(idx,"core_profiles",cp)
     write(*,*) "========END of PUT Part======================"
     
     
     
!!!! TEST OF THE GET FULL ids
     call ids_get(idx,"core_profiles",cp2)
     write(*,*) "ids_Properties homogeneous : ", cp2%ids_Properties%homogeneous_time
     write(*,*) "ids_Properties comment : ", cp2%ids_Properties%comment(1)
     write(*,*) "Size of the profiles_1d array : ", size(cp2%profiles_1d)
     do i=1,size(cp2%profiles_1d)
        write(*,*) "Slice ",i
        write(*,*) "Rho_tor_norm : ", cp2%profiles_1d(i)%grid%rho_tor_norm
        write(*,*) "Time slice : ", cp2%profiles_1d(i)%time
        write(*,*) "Size of the ion array : ", size(cp2%profiles_1d(i)%ion)
        do j=1,size(cp2%profiles_1d(i)%ion)
           write(*,*) "Ion ",j 
           write(*,*) "Ion charge : ", cp2%profiles_1d(i)%ion(j)%z_ion
           write(*,*) "Ion density : ", cp2%profiles_1d(i)%ion(j)%density    ! Fixed radial grid size = 3, for ion #j of !time slice #i (already quite complicated)
           write(*,*) "Size of the state array : ", size(cp2%profiles_1d(i)%ion(j)%state)
           do k=1,10
              write(*,*) "State z_min", cp2%profiles_1d(i)%ion(j)%state(k)%z_min
           enddo
        enddo
     enddo
     
     write(*,*) "Plasma current ", cp2%global_quantities%ip
     write(*,*) "IDS root time ", cp2%time
     
     call ids_deallocate(cp2)
     write(*,*) "========END of GET Part======================"
     
!!!! TEST OF THE GET SLICE ids
     interpol = 2 ! Interpolation mode = Previous neighbour
     twant = 2.5
     call ids_get_slice(idx,"core_profiles",cp3, twant, interpol)
     write(*,*) "========GET SLICE RESULTS AT TIME ", twant
     
     write(*,*) "ids_Properties homogeneous : ", cp3%ids_Properties%homogeneous_time
     write(*,*) "ids_Properties comment : ", cp3%ids_Properties%comment(1)
     write(*,*) "Size of the profiles_1d array : ", size(cp3%profiles_1d)
     do i=1,size(cp3%profiles_1d)
        write(*,*) "Slice ",i
        write(*,*) "Rho_tor_norm : ", cp3%profiles_1d(i)%grid%rho_tor_norm
        write(*,*) "Time slice : ", cp3%profiles_1d(i)%time
        write(*,*) "Size of the ion array : ", size(cp3%profiles_1d(i)%ion)
        do j=1,size(cp3%profiles_1d(i)%ion)
           write(*,*) "Ion ",j 
           write(*,*) "Ion charge : ", cp3%profiles_1d(i)%ion(j)%z_ion
           write(*,*) "Ion density : ", cp3%profiles_1d(i)%ion(j)%density    ! Fixed radial grid size = 3, for ion #j of !time slice #i (already quite complicated)
           write(*,*) "Size of the state array : ", size(cp3%profiles_1d(i)%ion(j)%state)
           do k=1,10
              write(*,*) "State z_min", cp3%profiles_1d(i)%ion(j)%state(k)%z_min
           enddo
        enddo
     enddo
     
     write(*,*) "Plasma current ", cp3%global_quantities%ip
     write(*,*) "IDS root time ", cp3%time
     
     call ids_deallocate(cp)
     
     call imas_close(idx)

  end do
  
end program test
