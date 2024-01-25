program test
  ! This program gets data from the DB entry, just for practicing the AL GET command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  use ids_routines
  implicit none

  !integer,parameter :: ids_real=kind(1.0D0)
  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_core_profiles) :: cp, cp2, cp3  ! Declaration of the empty ids to be filled

  integer :: idx, pulse, run, refpulse, refrun, status, i, j, dum1
  integer :: interpol
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3

  character(len=132):: longstring, usr

  character(len=5)::treename
  character(STRMAXLEN):: uri
  character(:), allocatable :: errmsg

  pulse =400
  run = 3
  refpulse = 10
  refrun =0
  treename = 'ids'

  !call imas_connect('ssh://hpc-login4.iter.org') ! Use to connect a remote IMAS database / account

  call get_environment_variable("USER",usr)

  call al_build_uri_from_legacy_parameters(MDSPLUS_BACKEND, pulse, run, usr, "test", "3", "", uri, status)
  !print *,TRIM(uri)
  call al_begin_dataentry_action(uri,OPEN_PULSE,idx,status,errmsg)
  if (status.ne.0) then
     print *,"errmsg=",errmsg
     STOP
  end if
  write(*,*) 'Opened MDS pulse file, idx = ', idx


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
  write(*,*) "Program completed"

end program test
