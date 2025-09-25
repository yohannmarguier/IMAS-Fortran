
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
  
  ! Test coordinate names and expected indices (based on actual coordinate_identifier.f90)
  character(len=25), dimension(25) :: test_coordinates = [ &
    'unspecified              ', 'x                        ', 'y                        ', &
    'z                        ', 'r                        ', 'phi                      ', &
    'psi                      ', 'rho_tor                  ', 'rho_tor_norm             ', &
    'rho_pol                  ', 'rho_pol_norm             ', 'theta                    ', &
    'theta_straight           ', 'theta_equal_arc          ', 'velocity                 ', &
    'velocity_x               ', 'velocity_y               ', 'velocity_z               ', &
    'momentum                 ', 'momentum_parallel        ', 'energy_hamiltonian       ', &
    'energy_kinetic           ', 'magnetic_moment          ', 'lambda                   ', &
    'n_phi                    ' ]
  
  integer, dimension(25) :: expected_indices = [ &
    0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 20, 21, 22, 100, 101, 102, 103, &
    200, 201, 300, 301, 302, 400, 500 ]

  test_count = 0
  pass_count = 0
  fail_count = 0

  ! Test 1: Basic get_index() function functionality
  print *, 'Testing get_index() function...'
  do i = 1, size(test_coordinates)
    test_count = test_count + 1
    idx = get_index(trim(test_coordinates(i)))
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
  idx = get_index('invalid_coordinate')
  if (idx == ids_int_invalid) then
    pass_count = pass_count + 1
  else
    fail_count = fail_count + 1
    print *, 'FAIL: Invalid coordinate returned ', idx, ', expected ', ids_int_invalid
  end if

  ! Test 3: Testing get_name() function (reverse lookup)
  print *, 'Testing get_name() function (reverse lookup)...'
  do i = 1, 5  ! Test first 5 coordinates
    test_count = test_count + 1
    nm = get_name(expected_indices(i))
    if (trim(nm) == trim(test_coordinates(i))) then
      pass_count = pass_count + 1
    else
      fail_count = fail_count + 1
      print *, 'FAIL: Index ', expected_indices(i), ' returned "', trim(nm), '", expected "', trim(test_coordinates(i)), '"'
    end if
  end do

  ! Test 4: Testing get_description() function
  test_count = test_count + 1
  desc = get_description(1)  ! Test 'x' coordinate
  if (len_trim(desc) > 0) then
    pass_count = pass_count + 1
    print *, 'PASS: Description for x coordinate: "', trim(desc), '"'
  else
    fail_count = fail_count + 1
    print *, 'FAIL: Empty description for x coordinate'
  end if

  ! Test 5: Testing set_identifier() generic interface for ids_identifier
  print *, 'Testing set_identifier() for ids_identifier...'
  test_count = test_count + 1
  call set_identifier(my_identifier, 'phi')
  if (my_identifier%index == 5 .and. &
      associated(my_identifier%name) .and. &
      associated(my_identifier%description)) then
    if (trim(my_identifier%name(1)) == 'phi') then
      pass_count = pass_count + 1
      print *, 'PASS: set_identifier for phi - Index:', my_identifier%index, ', Name: "', trim(my_identifier%name(1)), '"'
    else
      fail_count = fail_count + 1
      print *, 'FAIL: set_identifier name mismatch'
    end if
  else
    fail_count = fail_count + 1
    print *, 'FAIL: set_identifier structure not properly set'
  end if

  ! Test 6: Testing set_identifier() generic interface for ids_identifier_static
  print *, 'Testing set_identifier() for ids_identifier_static...'
  test_count = test_count + 1
  call set_identifier(my_static_identifier, 'rho_tor')
  if (my_static_identifier%index == 11 .and. &
      associated(my_static_identifier%name) .and. &
      associated(my_static_identifier%description)) then
    if (trim(my_static_identifier%name(1)) == 'rho_tor') then
      pass_count = pass_count + 1
      print *, 'PASS: set_identifier for rho_tor - Index:', my_static_identifier%index, ', Name: "', trim(my_static_identifier%name(1)), '"'
    else
      fail_count = fail_count + 1
      print *, 'FAIL: set_identifier name mismatch'
    end if
  else
    fail_count = fail_count + 1
    print *, 'FAIL: set_identifier structure not properly set'
  end if

  ! Test 7: Testing set_identifier() generic interface for ids_identifier_static_1d
  print *, 'Testing set_identifier() for ids_identifier_static_1d...'
  test_count = test_count + 1
  call set_identifier(my_static_1d_identifier, ['theta     ', 'phi       '])
  if (associated(my_static_1d_identifier%indices) .and. &
      associated(my_static_1d_identifier%names) .and. &
      associated(my_static_1d_identifier%descriptions)) then
    if (size(my_static_1d_identifier%indices) == 2 .and. &
        my_static_1d_identifier%indices(1) == 20 .and. &
        my_static_1d_identifier%indices(2) == 5 .and. &
        trim(my_static_1d_identifier%names(1)) == 'theta' .and. &
        trim(my_static_1d_identifier%names(2)) == 'phi') then
      pass_count = pass_count + 1
      print *, 'PASS: set_identifier for multiple coordinates - Size:', size(my_static_1d_identifier%indices)
      print *, '  Index 1:', my_static_1d_identifier%indices(1), ', Name: "', trim(my_static_1d_identifier%names(1)), '"'
      print *, '  Index 2:', my_static_1d_identifier%indices(2), ', Name: "', trim(my_static_1d_identifier%names(2)), '"'
    else
      fail_count = fail_count + 1
      print *, 'FAIL: set_identifier indices/names mismatch'
    end if
  else
    fail_count = fail_count + 1
    print *, 'FAIL: set_identifier structure not properly set'
  end if

  ! Test 8: Testing set_identifier() generic interface for ids_identifier_dynamic_aos3
  print *, 'Testing set_identifier() for ids_identifier_dynamic_aos3...'
  test_count = test_count + 1
  call set_identifier(my_dynamic_aos3_identifier, 'velocity')
  if (my_dynamic_aos3_identifier%index == 100 .and. &
      associated(my_dynamic_aos3_identifier%name) .and. &
      associated(my_dynamic_aos3_identifier%description)) then
    if (trim(my_dynamic_aos3_identifier%name(1)) == 'velocity') then
      pass_count = pass_count + 1
      print *, 'PASS: set_identifier for velocity - Index:', my_dynamic_aos3_identifier%index, ', Name: "', trim(my_dynamic_aos3_identifier%name(1)), '"'
    else
      fail_count = fail_count + 1
      print *, 'FAIL: set_identifier name mismatch'
    end if
  else
    fail_count = fail_count + 1
    print *, 'FAIL: set_identifier structure not properly set'
  end if

  ! Test 9: Testing set_identifier() generic interface for ids_identifier_dynamic_aos3_1d
  print *, 'Testing set_identifier() for ids_identifier_dynamic_aos3_1d...'
  test_count = test_count + 1
  call set_identifier(my_dynamic_aos3_1d_identifier, ['momentum      ', 'velocity      ', 'energy_kinetic'])
  if (associated(my_dynamic_aos3_1d_identifier%indices) .and. &
      associated(my_dynamic_aos3_1d_identifier%names) .and. &
      associated(my_dynamic_aos3_1d_identifier%descriptions)) then
    if (size(my_dynamic_aos3_1d_identifier%indices) == 3 .and. &
        my_dynamic_aos3_1d_identifier%indices(1) == 200 .and. &
        my_dynamic_aos3_1d_identifier%indices(2) == 100 .and. &
        my_dynamic_aos3_1d_identifier%indices(3) == 301 .and. &
        trim(my_dynamic_aos3_1d_identifier%names(1)) == 'momentum' .and. &
        trim(my_dynamic_aos3_1d_identifier%names(2)) == 'velocity' .and. &
        trim(my_dynamic_aos3_1d_identifier%names(3)) == 'energy_kinetic') then
      pass_count = pass_count + 1
      print *, 'PASS: set_identifier for multiple coordinates - Size:', size(my_dynamic_aos3_1d_identifier%indices)
      print *, '  Index 1:', my_dynamic_aos3_1d_identifier%indices(1), ', Name: "', trim(my_dynamic_aos3_1d_identifier%names(1)), '"'
      print *, '  Index 2:', my_dynamic_aos3_1d_identifier%indices(2), ', Name: "', trim(my_dynamic_aos3_1d_identifier%names(2)), '"'
      print *, '  Index 3:', my_dynamic_aos3_1d_identifier%indices(3), ', Name: "', trim(my_dynamic_aos3_1d_identifier%names(3)), '"'
    else
      fail_count = fail_count + 1
      print *, 'FAIL: set_identifier indices/names mismatch'
    end if
  else
    fail_count = fail_count + 1
    print *, 'FAIL: set_identifier structure not properly set'
  end if

  ! Test 10: Round-trip consistency test
  print *, 'Testing round-trip consistency...'
  do i = 1, 3  ! Test first 3 coordinates
    test_count = test_count + 1
    idx = get_index(trim(test_coordinates(i)))
    nm = get_name(idx)
    if (trim(nm) == trim(test_coordinates(i))) then
      pass_count = pass_count + 1
    else
      fail_count = fail_count + 1
      print *, 'FAIL: Round-trip consistency failed for coordinate: ', trim(test_coordinates(i))
    end if
  end do

  ! Clean up allocated memory
  if (associated(my_identifier%name)) deallocate(my_identifier%name)
  if (associated(my_identifier%description)) deallocate(my_identifier%description)
  if (associated(my_static_identifier%name)) deallocate(my_static_identifier%name)
  if (associated(my_static_identifier%description)) deallocate(my_static_identifier%description)
  if (associated(my_static_1d_identifier%indices)) deallocate(my_static_1d_identifier%indices)
  if (associated(my_static_1d_identifier%names)) deallocate(my_static_1d_identifier%names)
  if (associated(my_static_1d_identifier%descriptions)) deallocate(my_static_1d_identifier%descriptions)
  if (associated(my_dynamic_aos3_identifier%name)) deallocate(my_dynamic_aos3_identifier%name)
  if (associated(my_dynamic_aos3_identifier%description)) deallocate(my_dynamic_aos3_identifier%description)
  if (associated(my_dynamic_aos3_1d_identifier%indices)) deallocate(my_dynamic_aos3_1d_identifier%indices)
  if (associated(my_dynamic_aos3_1d_identifier%names)) deallocate(my_dynamic_aos3_1d_identifier%names)
  if (associated(my_dynamic_aos3_1d_identifier%descriptions)) deallocate(my_dynamic_aos3_1d_identifier%descriptions)

end program test_coordinate_identifier