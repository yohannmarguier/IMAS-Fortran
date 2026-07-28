program play_magnetics
  use ids_routines
  implicit none

  integer :: idx, status, i
  character(:), allocatable :: retmsg
  type(ids_magnetics) :: magnetics_out, magnetics_in

  call imas_open('imas:ascii?path=./playground_db', FORCE_CREATE_PULSE, idx, status, retmsg)
  if (status /= 0) then
     print *, 'imas_open failed: ', retmsg
     stop 1
  end if

  magnetics_out%ids_properties%homogeneous_time = 1
  allocate(magnetics_out%time(5))
  do i = 1, 5
     magnetics_out%time(i) = 0.1 * i
  end do

  print *, 'Putting magnetics IDS...'
  call ids_put(idx, 'magnetics', magnetics_out)

  print *, 'Getting magnetics IDS back...'
  call ids_get(idx, 'magnetics', magnetics_in)

  print *, 'Time values read back: ', magnetics_in%time

  call imas_close(idx)

  print *, 'Done.'
end program play_magnetics
