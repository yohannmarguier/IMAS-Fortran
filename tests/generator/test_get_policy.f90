! Truth table for the read-side refusal policy.
!
! The behavioural proof of best-effort reads lives in playground/, because it
! needs a pulse written under a different Data Dictionary version and a
! conversion layer to refuse a path. Nothing in an ordinary build can make a read
! fail, so the whole suite otherwise runs without ever entering the tolerant arm.
!
! This test reaches it directly. isErrorCritical is a public module procedure of
! utilities_get_struct, and it is the single chokepoint every leaf read and every
! nested struct/AoS-element call in the read path funnels through, so calling it
! with a hand-made status exercises exactly the decision that matters.
!
! This test deliberately drives the *fatal* branch too, and that branch prints
! "ERROR! with field ...". So unlike the generated per-IDS tests, its pass
! condition cannot be "the word ERROR is absent" -- it is the absence of
! POLICY-FAILURE, plus a zero exit status.
program test_get_policy
  use ids_types, only: ids_int
  use al_defs
  use al_get_policy
  use utilities_get_struct, only: isErrorCritical
  implicit none

  integer :: failures
  character(len=AL_SKIP_PATH_LEN) :: path
  character(len=MAX_ERR_MSG_LEN) :: message
  integer :: code
  logical :: found

  failures = 0
  call al_reset_skip_log()

  ! Success is never critical.
  call expect(.not. critical(0, 'a/b'), 'status 0 must not be critical')

  ! Every status IMAS-Core itself allocates stays fatal. If any of these were
  ! tolerated, a backend or context failure would come back as a sparse IDS.
  call expect(critical(UNKNOWN_ERR,     'a/b'), 'UNKNOWN_ERR must be critical')
  call expect(critical(CONTEXT_ERR,     'a/b'), 'CONTEXT_ERR must be critical')
  call expect(critical(BACKEND_ERR,     'a/b'), 'BACKEND_ERR must be critical')
  call expect(critical(LOWLEVEL_ERR,    'a/b'), 'LOWLEVEL_ERR must be critical')
  call expect(critical(CONSISTENCY_ERR, 'a/b'), 'CONSISTENCY_ERR must be critical')

  ! Nothing has been skipped yet: the fatal statuses above must not have been
  ! logged as skips.
  call expect(al_get_skipped_count() == 0, 'a fatal status must not be logged as a skip')

  ! A refusal is tolerated, and recorded.
  call expect(.not. critical(AL_EXTERNAL_REFUSAL_MAX, 'grids_ggd/grid/space/coordinates_type'), &
              'a conversion refusal must not be critical')
  call expect(al_get_skipped_count() == 1, 'a tolerated refusal must be logged')

  call al_get_skipped_path(1, path, code, message, found)
  call expect(found, 'the logged skip must be retrievable')
  call expect(trim(path) == 'grids_ggd/grid/space/coordinates_type', 'the logged path must be the refused one')
  call expect(code == AL_EXTERNAL_REFUSAL_MAX, 'the logged code must be the refusal status')

  ! The whole reserved band is tolerated, not just the one value allocated today.
  call expect(.not. critical(AL_EXTERNAL_REFUSAL_MIN, 'x/y'), &
              'the far end of the reserved band must not be critical')

  ! Just outside the band, both sides, is fatal again.
  call expect(critical(AL_EXTERNAL_REFUSAL_MAX + 1, 'x/y'), &
              'just above the reserved band must be critical')
  call expect(critical(AL_EXTERNAL_REFUSAL_MIN - 1, 'x/y'), &
              'just below the reserved band must be critical')

  ! A reset makes the log describe one operation rather than the process.
  call expect(al_get_skipped_count() == 2, 'both tolerated refusals must be counted')
  call al_reset_skip_log()
  call expect(al_get_skipped_count() == 0, 'reset must empty the log')
  call al_get_skipped_path(1, path, code, message, found)
  call expect(.not. found, 'nothing must be retrievable after a reset')

  ! PARTIAL_READ has to stay distinguishable from every status the C ABI can
  ! produce, or a partial read would be indistinguishable from a failure.
  call expect(PARTIAL_READ > 0, 'PARTIAL_READ must be positive')
  call expect(.not. is_external_refusal(PARTIAL_READ), 'PARTIAL_READ must not look like a refusal')

  if (failures > 0) then
     write(*,*) 'POLICY-FAILURE: ', failures, ' expectation(s) failed'
     stop 1
  end if

contains

  ! isErrorCritical takes `integer(ids_int) :: status, ctx` with no INTENT, so
  ! neither may be a literal at the call site. Copy into locals first.
  logical function critical(with_status, what)
    integer, intent(in) :: with_status
    character(len=*), intent(in) :: what
    integer(ids_int) :: st, cx
    st = with_status
    cx = 0
    critical = isErrorCritical(st, cx, what)
  end function critical

  subroutine expect(condition, what)
    logical, intent(in) :: condition
    character(len=*), intent(in) :: what
    if (.not. condition) then
       write(*,*) 'POLICY-FAILURE: ', what
       failures = failures + 1
    end if
  end subroutine expect

end program test_get_policy
