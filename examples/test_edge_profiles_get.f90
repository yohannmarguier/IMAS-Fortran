program test
  ! This program gets data from the DB entry, just for practicing the AL GET command
  ! It servers also as a nested of 3 level nested AoS (type 3 at the top, type 2 below)
  use ids_routines
  implicit none

  !integer,parameter :: ids_real=kind(1.0D0)
  real(ids_real) :: time_1(10), vect1DDouble_1(10), time_2(12), vect1DDouble_2(12)
  type (ids_edge_profiles) :: cp, cp2, cp3  ! Declaration of the empty ids to be filled

  integer :: idx, i, j, b
  integer :: interpol
  real(ids_real) :: temps, temps_ret, twant
  real(ids_real) :: double_3
  character(len=7), dimension(2) :: BACKEND = ['mdsplus','hdf5   ']

  do b=1,size(BACKEND)
     print *,"Test with backend ",BACKEND(b)

     call imas_open('imas:'//trim(BACKEND(b))//'?path=./test_db_test_edge_profiles', OPEN_PULSE, idx)
     write(*,*) 'Opened pulse file, idx = ', idx


!!!! TEST OF THE GET FULL IDS
     if (.TRUE.) THEN
        call ids_get(idx,"edge_profiles",cp)
        write(*,*) "IDS_Properties homogeneous : ", cp%IDS_Properties%homogeneous_time
        write(*,*) "IDS_Properties comment : ", cp%IDS_Properties%comment(1)
        write(*,*) "Size of ggd_fast : ", size(cp%ggd_fast)
        write(*,*) "cp%ggd_fast%time : ",cp%ggd_fast(:)%time
        write(*,*) "cp%ggd_fast(1)%electrons%temperature(1)%value : ", cp%ggd_fast(1)%electrons%temperature(1)%value
        write(*,*) "cp%ggd_fast(100)%electrons%temperature(1)%value : ", cp%ggd_fast(100)%electrons%temperature(1)%value
        
        write(*,*) "Size of full ggd : ", size(cp%ggd)
        write(*,*) "cp%ggd%time : ",cp%ggd(:)%time
        write(*,*) "cp%ggd(1)%electrons%temperature(1)%values : ", cp%ggd(1)%electrons%temperature(1)%values
        write(*,*) "cp%ggd(10)%electrons%temperature(1)%values : ", cp%ggd(10)%electrons%temperature(1)%values
        
        write(*,*) "Size of grid_ggd : ", size(cp%grid_ggd)
        write(*,*) "cp%grid_ggd%time : ",cp%grid_ggd(:)%time
        write(*,*) "cp%grid_ggd(1)%space(1)%geometry_type%index : ", cp%grid_ggd(1)%space(1)%geometry_type%index 
        write(*,*) "cp%grid_ggd(2)%space(1)%geometry_type%index : ", cp%grid_ggd(2)%space(1)%geometry_type%index
        
     endif ! if 0
     
     write(*,*) "Test of the GET_SLICE function"
     interpol = 1 ! Interpolation mode = closest neighbour
     twant = 4.06
     call ids_get_slice(idx,"edge_profiles",cp2,twant,interpol)
     write(*,*) "IDS_Properties homogeneous : ", cp2%IDS_Properties%homogeneous_time
     write(*,*) "IDS_Properties comment : ", cp2%IDS_Properties%comment(1)
     write(*,*) "Size of ggd_fast : ", size(cp2%ggd_fast)
     write(*,*) "cp%ggd_fast%time : ",cp2%ggd_fast(:)%time
     write(*,*) "cp%ggd_fast(1)%electrons%temperature(1)%value : ", cp2%ggd_fast(1)%electrons%temperature(1)%value
     
     write(*,*) "Size of full ggd : ", size(cp2%ggd)
     write(*,*) "cp%ggd%time : ",cp2%ggd(1)%time
     write(*,*) "cp%ggd(1)%electrons%temperature(1)%values : ", cp2%ggd(1)%electrons%temperature(1)%values
     
     write(*,*) "Size of grid_ggd : ", size(cp2%grid_ggd)
     write(*,*) "cp%grid_ggd%time : ",cp2%grid_ggd(1)%time
     write(*,*) "cp%grid_ggd(1)%space(1)%geometry_type%index : ", cp2%grid_ggd(1)%space(1)%geometry_type%index 
     
     
     call ids_deallocate(cp)
     call ids_deallocate(cp2)
     
     call imas_close(idx)
     write(*,*) "Program completed"

  end do

end program test
   
