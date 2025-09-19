
! Test program for coordinate identifier functionality
program test_coordinate_identifier
  use al_coordinate_identifier
  use ids_utilities
  use ids_types
  
  implicit none

  integer :: idx, i, test_count, pass_count, fail_count
  character(len=:), allocatable :: nm, desc
  type(ids_identifier) :: my_identifier
  type(ids_identifier_static) :: my_static_identifier
  type(ids_identifier_static_1d) :: my_static_1d_identifier
  type(ids_identifier_dynamic_aos3) :: my_dynamic_aos3_identifier
  type(ids_identifier_dynamic_aos3_1d) :: my_dynamic_aos3_1d_identifier
  
  ! Test coordinate names and expected indices
  character(len=20), dimension(15) :: test_coordinates = [ &
    'x                   ', 'y                   ', 'z                   ', &
    'r                   ', 'phi                 ', 'psi                 ', &
    'rho_tor             ', 'rho_tor_norm        ', 'rho_pol             ', &
    'rho_pol_norm        ', 'theta               ', 'velocity            ', &
    'momentum            ', 'energy_kinetic      ', 'pitch_angle         ' ]
  
  integer, dimension(15) :: expected_indices = [ &
    1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 20, 100, 200, 301, 402 ]

  test_count = 0
  pass_count = 0
  fail_count = 0

  ! Test 1: Basic index() method functionality
  print *, 'Testing index() method...'
  do i = 1, size(test_coordinates)
    test_count = test_count + 1
    idx = coordinate_identifier%index(trim(test_coordinates(i)))
    if (idx == expected_indices(i)) then
      pass_count = pass_count + 1
    else
      fail_count = fail_count + 1
      print *, 'FAIL: ', trim(test_coordinates(i)), ' returned ', idx, ', expected ', expected_indices(i)
    end if
  end do

  ! Test 2: Testing invalid coordinate names
  print *, 'Testing invalid coordinate names...'
  test_count = test_count + 1
  idx = coordinate_identifier%index('invalid_coordinate')
  if (idx == ids_int_invalid) then
    pass_count = pass_count + 1
  else
    fail_count = fail_count + 1
    print *, 'FAIL: Invalid coordinate returned ', idx, ', expected ', ids_int_invalid
  end if

  ! Test 3: Testing name() method (reverse lookup)
  print *, 'Testing name() method (reverse lookup)...'
  do i = 1, 5  ! Test first 5 coordinates
    test_count = test_count + 1
    nm = coordinate_identifier%name(expected_indices(i))
    if (trim(nm) == trim(test_coordinates(i))) then
      pass_count = pass_count + 1
    else
      fail_count = fail_count + 1
      print *, 'FAIL: Index ', expected_indices(i), ' returned "', trim(nm), '", expected "', trim(test_coordinates(i)), '"'
    end if
  end do

  ! Test 4: Testing description() method
  test_count = test_count + 1
  desc = coordinate_identifier%description(1)  ! Test 'x' coordinate
  if (len_trim(desc) > 0) then
    pass_count = pass_count + 1
  else
    fail_count = fail_count + 1
  end if

  ! Test 5: Testing set_ids_identifier() method
  print *, 'Testing set_ids_identifier() method...'
  test_count = test_count + 1
  call coordinate_identifier%set_ids_identifier(my_identifier, 'phi')
  if (my_identifier%index == 5 .and. &
      associated(my_identifier%name) .and. &
      associated(my_identifier%description)) then
    if (trim(my_identifier%name(1)) == 'phi') then
      pass_count = pass_count + 1
      print *, 'PASS: set_ids_identifier for phi - Index:', my_identifier%index, ', Name: "', trim(my_identifier%name(1)), '"'
    else
      fail_count = fail_count + 1
      print *, 'FAIL: set_ids_identifier name mismatch'
    end if
  else
    fail_count = fail_count + 1
    print *, 'FAIL: set_ids_identifier structure not properly set'
  end if

  ! Test 6: Testing set_ids_identifier_static_1d() method
  test_count = test_count + 1
  call coordinate_identifier%set_ids_identifier_static_1d(my_static_1d_identifier, 'rho_tor')
  if (associated(my_static_1d_identifier%indices) .and. &
      associated(my_static_1d_identifier%names) .and. &
      associated(my_static_1d_identifier%descriptions)) then
    if (my_static_1d_identifier%indices(1) == 11 .and. &
        trim(my_static_1d_identifier%names(1)) == 'rho_tor') then
      pass_count = pass_count + 1
    else
      fail_count = fail_count + 1
      print *, 'FAIL: set_ids_identifier names mismatch'
    end if
  else
    fail_count = fail_count + 1
    print *, 'FAIL: set_ids_identifier structure not properly set'
  end if

  ! Test 7: Round-trip consistency test
  do i = 1, 3  ! Test first 3 coordinates
    test_count = test_count + 1
    idx = coordinate_identifier%index(trim(test_coordinates(i)))
    nm = coordinate_identifier%name(idx)
    if (trim(nm) == trim(test_coordinates(i))) then
      pass_count = pass_count + 1
    else
      fail_count = fail_count + 1
      print *, 'FAIL: set_ids_identifier structure not properly set'
    end if
  end do

  if (fail_count == 0) then
    print *, 'ALL TESTS PASSED!'
  else
    print *, 'SOME TESTS FAILED!'
    stop 1  ! Exit with error code if tests failed
  end if

  ! Clean up allocated memory
  if (associated(my_identifier%name)) deallocate(my_identifier%name)
  if (associated(my_identifier%description)) deallocate(my_identifier%description)
  if (associated(my_static_1d_identifier%indices)) deallocate(my_static_1d_identifier%indices)
  if (associated(my_static_1d_identifier%names)) deallocate(my_static_1d_identifier%names)
  if (associated(my_static_1d_identifier%descriptions)) deallocate(my_static_1d_identifier%descriptions)

end program test_coordinate_identifier