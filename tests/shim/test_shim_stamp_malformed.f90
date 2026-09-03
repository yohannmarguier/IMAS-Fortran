! A present-but-invalid stamp refuses at occurrence open.  ids_get is guarded
! behind a successful open solely to make reaching a data seam an explicit
! failure: the expected refusal must prevent that branch from executing.
program test_shim_stamp_malformed
  use ids_routines, only: ids_equilibrium, OPEN_PULSE, imas_open, imas_close, ids_get
  use al_defs, only: is_external_refusal
  implicit none

  type(ids_equilibrium) :: equilibrium
  character(len=512) :: fixture
  character(:), allocatable :: message
  integer :: context, open_status, get_status

  call get_command_argument(1, fixture)
  if (len_trim(fixture) == 0) error stop 'missing stamp-malformed fixture'

  call imas_open('imas:hdf5?path='//trim(fixture), OPEN_PULSE, context, open_status, message)
  if (.not. is_external_refusal(open_status)) error stop 'malformed stamp did not refuse at open'
  if (.not. allocated(message)) error stop 'malformed stamp refusal supplied no reason'
  if (index(message, 'malformed DD-version stamp') == 0) error stop 'malformed stamp refusal reason changed'

  if (open_status == 0) then
    call ids_get(context, 'equilibrium', equilibrium, get_status)
    call imas_close(context)
    error stop 'malformed stamp forwarded to a data seam'
  endif
end program test_shim_stamp_malformed
