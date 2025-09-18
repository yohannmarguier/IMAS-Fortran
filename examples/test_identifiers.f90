
! Test program for coordinate identifier functionality
program test_coordinate_identifier
  use al_coordinate_identifier, only: coordinate_identifier
  use ids_utilities
  
  implicit none

  integer :: idx
  character(len=132) :: nm, desc
  type(ids_identifier) :: my_identifier
  type(ids_identifier_static) :: my_static_identifier
  type(ids_identifier_static_1d) :: my_static_1d_identifier
  type(ids_identifier_dynamic_aos3) :: my_dynamic_aos3_identifier
  type(ids_identifier_dynamic_aos3_1d) :: my_dynamic_aos3_1d_identifier

  print *, ''
  print *, '=========================================='
  print *, '  COORDINATE IDENTIFIER TEST PROGRAM'
  print *, '=========================================='
  print *, ''
  print *, '=== Testing name to index conversion ==='
  print *, "Index for 'unspecified':", coordinate_identifier%index('unspecified')
  print *, "Index for 'x':", coordinate_identifier%index('x')
  print *, "Index for 'y':", coordinate_identifier%index('y')
  print *, "Index for 'z':", coordinate_identifier%index('z')
  print *, "Index for 'r':", coordinate_identifier%index('r')
  print *, "Index for 'invalid':", coordinate_identifier%index('invalid')
  print *, ''

  print *, '=== Testing index to name/description conversion ==='
  do idx = 0, 10
    nm = coordinate_identifier%name(idx)
    if (len_trim(nm) > 0) then
      desc = coordinate_identifier%description(idx)
      print *, 'Index:', idx, 'Name: "', trim(nm), '"'
      print *, '  Description: "', trim(desc), '"'
      print *, ''
    end if
  end do

  print *, '=== Testing set_ids_identifier method ==='
  
  call coordinate_identifier%set_ids_identifier(my_identifier, 'x')
  print *, "Set identifier for 'x':"
  print *, "  Index:", my_identifier%index
  if (associated(my_identifier%name)) then
    print *, "  Name: '", trim(my_identifier%name(1)), "'"
  end if
  if (associated(my_identifier%description)) then
    print *, "  Description: '", trim(my_identifier%description(1)), "'"
  end if
  print *, ''
  
  call coordinate_identifier%set_ids_identifier(my_identifier, 'r')
  print *, "Set identifier for 'r':"
  print *, "  Index:", my_identifier%index
  if (associated(my_identifier%name)) then
    print *, "  Name: '", trim(my_identifier%name(1)), "'"
  end if
  if (associated(my_identifier%description)) then
    print *, "  Description: '", trim(my_identifier%description(1)), "'"
  end if
  print *, ''
  
  call coordinate_identifier%set_ids_identifier(my_identifier, 'invalid')
  print *, "Set identifier for 'invalid':"
  print *, "  Index:", my_identifier%index
  if (associated(my_identifier%name)) then
    print *, "  Name: '", trim(my_identifier%name(1)), "'"
  end if
  if (associated(my_identifier%description)) then
    print *, "  Description: '", trim(my_identifier%description(1)), "'"
  end if
  print *, ''

  print *, '=== Testing set_ids_identifier_static method ==='
  
  call coordinate_identifier%set_ids_identifier_static(my_static_identifier, 'y')
  print *, "Set static identifier for 'y':"
  print *, "  Index:", my_static_identifier%index
  if (associated(my_static_identifier%name)) then
    print *, "  Name: '", trim(my_static_identifier%name(1)), "'"
  end if
  if (associated(my_static_identifier%description)) then
    print *, "  Description: '", trim(my_static_identifier%description(1)), "'"
  end if
  print *, ''

  print *, '=== Testing set_ids_identifier_static_1d method ==='
  
  call coordinate_identifier%set_ids_identifier_static_1d(my_static_1d_identifier, 'z')
  print *, "Set static 1d identifier for 'z':"
  if (associated(my_static_1d_identifier%indices)) then
    print *, "  Index:", my_static_1d_identifier%indices(1)
  end if
  if (associated(my_static_1d_identifier%names)) then
    print *, "  Name: '", trim(my_static_1d_identifier%names(1)), "'"
  end if
  if (associated(my_static_1d_identifier%descriptions)) then
    print *, "  Description: '", trim(my_static_1d_identifier%descriptions(1)), "'"
  end if
  print *, ''

  print *, '=== Testing set_ids_identifier_dynamic_aos3 method ==='
  
  call coordinate_identifier%set_ids_identifier_dynamic_aos3(my_dynamic_aos3_identifier, 'x')
  print *, "Set dynamic aos3 identifier for 'x':"
  print *, "  Index:", my_dynamic_aos3_identifier%index
  if (associated(my_dynamic_aos3_identifier%name)) then
    print *, "  Name: '", trim(my_dynamic_aos3_identifier%name(1)), "'"
  end if
  if (associated(my_dynamic_aos3_identifier%description)) then
    print *, "  Description: '", trim(my_dynamic_aos3_identifier%description(1)), "'"
  end if
  print *, ''

  print *, '=== Testing set_ids_identifier_dynamic_aos3_1d method ==='
  
  call coordinate_identifier%set_ids_identifier_dynamic_aos3_1d(my_dynamic_aos3_1d_identifier, 'r')
  print *, "Set dynamic aos3 1d identifier for 'r':"
  if (associated(my_dynamic_aos3_1d_identifier%indices)) then
    print *, "  Index:", my_dynamic_aos3_1d_identifier%indices(1)
  end if
  if (associated(my_dynamic_aos3_1d_identifier%names)) then
    print *, "  Name: '", trim(my_dynamic_aos3_1d_identifier%names(1)), "'"
  end if
  if (associated(my_dynamic_aos3_1d_identifier%descriptions)) then
    print *, "  Description: '", trim(my_dynamic_aos3_1d_identifier%descriptions(1)), "'"
  end if
  print *, ''

  print *, '=========================================='
  print *, '  ALL TESTS COMPLETED SUCCESSFULLY!'
  print *, '=========================================='
  print *, ''

end program test_coordinate_identifier