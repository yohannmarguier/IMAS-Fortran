program test
  ! This program gets data from the DB entry, just for practicing the AL GET command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  use ids_routines
  implicit none

  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_core_profiles) :: cp, cp2, cp3  ! Declaration of the empty ids to be filled

  integer :: idx, i, j, b
  integer :: interpol
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3

  character(:), allocatable :: errmsg
  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)
     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_core_profiles_slices', OPEN_PULSE, idx)
    
     write(*,*) 'Opened file, idx = ', idx

!!!! TEST OF THE GET FULL IDS
     if (.TRUE.) THEN
        call ids_get(idx,"core_profiles",cp)
        write(*,*) "IDS_Properties homogeneous : ", cp%IDS_Properties%homogeneous_time
        write(*,*) "IDS_Properties comment : ", cp%IDS_Properties%comment(1)
        write(*,*) "Size of cp%profiles_1d : ", size(cp%profiles_1d)
        write(*,*) "cp%profiles_1d%time : ",cp%profiles_1d(:)%time
        write(*,*) "Main IDS time : ", cp%time
        write(*,*) "Ip = ", cp%global_quantities%ip
        
        do i=1,size(time_1)
           write(*,*) "Time slice i = ", cp%profiles_1d(i)%time
           write(*,*) "rho = ", cp%profiles_1d(i)%grid%rho_tor_norm
           write(*,*) "List of ion average charge = ", cp%profiles_1d(i)%ion%z_ion
           do j=1,size(cp%profiles_1d(i)%ion)
              write(*,*) "Density for ion j at time i", cp%profiles_1d(i)%ion(j)%density
              write(*,*) "List of charge states for ion j at time i", cp%profiles_1d(i)%ion(j)%state%z_min
           enddo
        enddo
        
        write(*,*) "Main IDS time : ", cp%time
        write(*,*) "Ip = ", cp%global_quantities%ip
        
     endif ! if 0
     write(*,*) "Test of the GET_SLICE function"
     interpol = 1 ! Interpolation mode = closest neighbour
     twant = 4.4
     call ids_get_slice(idx,"core_profiles",cp2,twant,interpol)
     write(*,*) "IDS_Properties homogeneous : ", cp2%IDS_Properties%homogeneous_time
     write(*,*) "IDS_Properties comment : ", cp2%IDS_Properties%comment(1)
     write(*,*) "Size of cp%profiles_1d : ", size(cp2%profiles_1d)
     write(*,*) "cp%profiles_1d%time : ",cp2%profiles_1d(:)%time
     write(*,*) "Main IDS time : ", cp2%time
     write(*,*) "Ip = ", cp2%global_quantities%ip
     
     do i=1,size(cp2%profiles_1d)
        write(*,*) "Time slice i = ", cp2%profiles_1d(i)%time
        write(*,*) "rho = ", cp2%profiles_1d(i)%grid%rho_tor_norm
        write(*,*) "List of ion average charge = ", cp2%profiles_1d(i)%ion%z_ion
        do j=1,size(cp2%profiles_1d(i)%ion)
           write(*,*) "Density for ion j at time i", cp2%profiles_1d(i)%ion(j)%density
           write(*,*) "List of charge states for ion j at time i", cp2%profiles_1d(i)%ion(j)%state%z_min
        enddo
     enddo
     
     call ids_deallocate(cp)
     call ids_deallocate(cp2)

     call imas_close(idx)
  end do
  write(*,*) "Program completed"

end program test
