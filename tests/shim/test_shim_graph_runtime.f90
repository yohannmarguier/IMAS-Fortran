! The graph-selected shim test package serves a controlled, complete
! equilibrium scope. This scenario stays at the generated HLI boundary: a
! DD-4 client writes one evidenced COCOS leaf into a DD-3 pulse, then gets it
! back through the same installed shim. The retyped coordinates_type field is
! deliberately present in the scope so the read also proves the ordinary
! PARTIAL_READ/skip channel remains visible to the HLI.
program test_shim_graph_runtime
  use ids_routines, only: ids_equilibrium, ids_real, OPEN_PULSE, imas_open, imas_close, &
                          ids_get, ids_put_slice
  use al_get_policy, only: PARTIAL_READ, al_get_skipped_count, al_get_skipped_path, &
                           AL_SKIP_PATH_LEN, AL_SKIP_LOG_CAPACITY
  implicit none

  integer, parameter :: psi_count = 2
  real(ids_real), parameter :: expected_time = 2.0_ids_real
  real(ids_real), parameter :: expected_psi(psi_count) = [-2.5_ids_real, 7.25_ids_real]
  ! `al_get_policy` stores the generated traversal's field spelling rather
  ! than a shim C-ABI joined path. Pair it with the frozen retype reason so
  ! this remains a meaningful HLI-visible observation.
  character(len=*), parameter :: retyped_path = 'coordinates_type'
  character(len=*), parameter :: retyped_reason = 'container changed shape'

  type(ids_equilibrium) :: written, read_back
  character(len=512) :: fixture, skipped_path, skipped_message
  integer :: context, status, i, skipped_code
  logical :: found_retyped_refusal, found

  call get_command_argument(1, fixture)
  if (len_trim(fixture) == 0) error stop 'SCENARIO-FAILURE: missing graph-runtime fixture'

  ! `ids_put_slice` reaches the HLI-generated write path.  `psi` is one of the
  ! graph scope's independently evidenced sign-flip leaves, so the stored DD-3
  ! value must be inverted on this write and restored by the get below.
  written%ids_properties%homogeneous_time = 1
  allocate(written%time(1))
  written%time = expected_time
  allocate(written%time_slice(1))
  written%time_slice(1)%time = expected_time
  allocate(written%time_slice(1)%profiles_1d%psi(psi_count))
  written%time_slice(1)%profiles_1d%psi = expected_psi

  call imas_open('imas:hdf5?path='//trim(fixture), OPEN_PULSE, context)
  call ids_put_slice(context, 'equilibrium', written, status)
  if (status /= 0) error stop 'SCENARIO-FAILURE: graph-backed generated slice write failed'

  call ids_get(context, 'equilibrium', read_back, status)
  call imas_close(context)

  if (status /= PARTIAL_READ) then
    error stop 'SCENARIO-FAILURE: retyped graph path did not produce the expected partial read'
  end if
  if (.not. associated(read_back%time_slice)) then
    error stop 'SCENARIO-FAILURE: graph-backed read returned no time slices'
  end if
  if (size(read_back%time_slice) /= 3) then
    error stop 'SCENARIO-FAILURE: graph-backed slice write was not persisted'
  end if
  if (.not. associated(read_back%time_slice(3)%profiles_1d%psi)) then
    error stop 'SCENARIO-FAILURE: graph-backed COCOS leaf was not read back'
  end if
  if (size(read_back%time_slice(3)%profiles_1d%psi) /= psi_count) then
    error stop 'SCENARIO-FAILURE: graph-backed COCOS leaf changed rank or extent'
  end if
  if (any(read_back%time_slice(3)%profiles_1d%psi /= expected_psi)) then
    error stop 'SCENARIO-FAILURE: graph-backed COCOS write/read changed psi values'
  end if

  found_retyped_refusal = .false.
  do i = 1, min(al_get_skipped_count(), AL_SKIP_LOG_CAPACITY)
    call al_get_skipped_path(i, skipped_path, skipped_code, skipped_message, found)
    if (found .and. trim(skipped_path) == retyped_path .and. &
        index(skipped_message, retyped_reason) > 0) found_retyped_refusal = .true.
  end do
  if (.not. found_retyped_refusal) then
    error stop 'SCENARIO-FAILURE: retyped graph refusal was not retained in the HLI skip log'
  end if

  write(*, '(a)') 'graph-runtime: generated HLI COCOS round trip and retype refusal observed'
end program test_shim_graph_runtime
