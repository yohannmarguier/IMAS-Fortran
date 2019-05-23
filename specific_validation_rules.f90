! This file contains IDS-specific validation rules, operating on Fortran structures

module specific_validate_struct

interface ids_validate
  module procedure ids_validate_struct_plasma_composit2025
  module procedure ids_validate_struct_core_profile_io225
  module procedure ids_validate_struct_core_profiles_p1000
  module procedure ids_validate_core_profiles
end interface    

 contains

 
 subroutine ids_validate_struct_plasma_composit2025(struct_in,path,status)
  use ids_types
  use ids_utilities, only: ids_plasma_composition_neutral_element
  
  implicit none

  integer(ids_int) :: i,status
  character(len=200):: path

  type(ids_plasma_composition_neutral_element) :: struct_in
  
  if (.NOT.(ids_is_valid(struct_in%a))) then
    write(*,*) 'Invalid IDS : '//trim(path)//'a must be set'
    status = -1
    return
  endif
  if (.NOT.(ids_is_valid(struct_in%z_n))) then
    write(*,*) 'Invalid IDS : '//trim(path)//'z_n must be set'
    status = -1
    return
  endif
 
end subroutine


subroutine ids_validate_struct_core_profile_io225(struct_in,path,status)
  use ids_types
  use ids_utilities, only: ids_core_profile_ions
  implicit none

  integer(ids_int) :: i, status
  character(len=200):: newpath,path
  character(len=5) :: index_string

  type(ids_core_profile_ions) :: struct_in
  
  if (associated(struct_in%element)) then
    do i=1,size(struct_in%element)
       write(index_string,'(I5)') i
       newpath = trim(path)//'element('//trim(adjustl(index_string))//')/'
       call ids_validate(struct_in%element(i), newpath, status)
    enddo
  else
    write(*,*) 'Invalid IDS : '//trim(path)//'element must be set'
    status = -1
    return
  endif
  
end subroutine

subroutine ids_validate_struct_core_profiles_p1000(struct_in, path, status)
  use ids_types
  use ids_utilities, only: ids_core_profiles_profiles_1d
  implicit none

  integer(ids_int) :: i, status
  character(len=200):: path, newpath
  character(len=5) :: index_string

  type(ids_core_profiles_profiles_1d) :: struct_in
  
  if (associated(struct_in%ion)) then
    do i=1,size(struct_in%ion)
       write(index_string,'(I5)') i
       newpath = trim(path)//'ion('//trim(adjustl(index_string))//')/'
       call ids_validate(struct_in%ion(i), newpath, status)
    enddo
  endif 
  
end subroutine

subroutine ids_validate_core_profiles(struct_in, status)
  use ids_types
  use ids_schemas, only: ids_core_profiles
  implicit none

  integer(ids_int) :: i, status
  character(len=200):: path, newpath
  character(len=5) :: index_string
  type(ids_core_profiles) :: struct_in
  
  if (associated(struct_in%profiles_1d)) then
    do i=1,size(struct_in%profiles_1d)
       write(index_string,'(I5)') i
       newpath = 'core_profiles/profiles_1d('//trim(adjustl(index_string))//')/'
       call ids_validate(struct_in%profiles_1d(i),newpath,status)
       if (status.EQ.-1) return
    enddo
  endif 
  
end subroutine

end module
