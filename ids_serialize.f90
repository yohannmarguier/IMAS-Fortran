module ids_serialize
use ids_schemas

contains

!> Turn an IDS into a bunch of bytes
function serialize(ids_in, protocol) result(buffer) ! TODO: return a (pointer to a) buffer
  use, intrinsic :: ISO_C_BINDING

  class(ids), intent(in) :: ids_in
  integer, intent(in) :: protocol
  character(len=:), allocatable :: buffer

  character(len=:), allocatable :: fname
  integer :: pulsectx
  integer :: status
  integer :: unit
  integer :: file_size

  if (protocol .eq. ASCII_SERIALIZER_PROTOCOL) then
    fname = generate_tmp_file()
    if (len_trim(fname) .eq. 0) then
      write(*,*) 'SERIALIZE: ERROR generating temporary file name'
      return
    end if

    ! Write to file
    call ual_begin_pulse_action(ASCII_BACKEND, 0, 0, 'serialize', 'serialize', '3', pulsectx)
    call ual_open_pulse(pulsectx, FORCE_CREATE_PULSE, '-fullpath ' // fname, status)
    if (status .neq. 0) then
      write(*,*) "SERIALIZE: ERROR opening ASCII backend - ual_open_pulse"
      buffer = ''
      return
    end if

    call ids_put(ids_in, 'serialize', 'serialize')

    call ual_close_pulse(pulsectx, FORCE_CREATE_PULSE, '', status)
    if (status .neq. 0) then
      write(*,*) "SERIALIZE: ERROR closing ASCII backend - ual_close_pulse"
      buffer = ''
      call ual_end_action(pulsectx)
      return
    end if


    ! Read from file
    unit = get_file_unit()
    open(unit=unit, action='read', status='old', form='unformatted', access='stream')
    inquire(unit=unit, size=file_size)
    allocate(character(file_size) :: buffer)
    read(unit) buffer
    close(unit, status='delete')

    ! DEBUG
    write(*,*) buffer

  else
    write(*,*) 'SERIALIZE: ERROR, unrecognized serialization protocol'
  end if
end

end subroutine serialize

function generate_tmp_file() result(fname)
  character(len=:), allocatable :: fname
  ! Follow same approach as the Python standard library in generating a random temporary file
  character(len=*), parameter :: fs_safe_characters = 'abcdefghijklmnopqrstuvwxyz0123456789_'
  integer, parameter :: n = 8 ! number of random characters in the file
  integer, parameter :: MAX_TMP_FILES = 1000

  ! On Windows and Mac OSX, use the current working directory as temporary directory (since /dev/shm does not exist).
  ! On any recent Linux (2.6 or later according to Wikipedia [1]) the /dev/shm folder exists for shared memory.
  ! Since glibc assumes this to exist anyway [2], we will as well.
  ! [1] https://en.wikipedia.org/wiki/Shared_memory
  ! [2] https://www.kernel.org/doc/Documentation/filesystems/tmpfs.txt
#if defined(_Linux)
#  define SERIALIZE_TEMPORARY_DIRECTORY '/dev/shm/'
#else
#  define SERIALIZE_TEMPORARY_DIRECTORY ''
#endif

  real, dimension(n) :: rd
  integer :: string_base_length
  integer :: i, j, k
  integer :: unit ! Unit number to open file with
  integer :: iostat

  ! Setup the base of the filename
  string_base_length = len(SERIALIZE_TEMPORARY_DIRECTORY) + len('al_serialize_')
  !allocate(fname(string_base_length + n))
  fname = SERIALIZE_TEMPORARY_DIRECTORY // 'al_serialize_' // repeat(' ', n) ! implicitly allocates to the right size

  ! get a free unit number
  unit = get_file_unit()

  do i=1,MAX_TMP_FILES
    call random_number(rd)
    do j=1,n
      k = ceiling(rd(j)*len(fs_safe_characters))
      fname(string_base_length + j:string_base_length + j) = fs_safe_characters(k:k)
    end do

    open(unit=unit, action='write', file=fname, status='new', iostat=iostat)
    if (iostat .gt. 0) cycle

    ! if we get here the file was opened successfully. Delete it, and return the filename found
    close(unit=unit, status='delete')
    return ! implies fname
  end do
  fname = ''
end function generate_tmp_file

function get_file_unit() result(unit)
  !< Get a free file unit description number without using Fortran 2008 newunit feature.
  integer :: unit, iostat
  logical :: opened

  do unit = 97,1,-1
    inquire (unit=unit, opened=opened, iostat=iostat)
    if (iostat .ne. 0) cycle
    if (.not. opened) exit
  end do
end function get_file_unit

end module ids_serialize