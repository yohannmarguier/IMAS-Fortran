! Truth table for the write-side refusal policy.
!
! Same reason for existing as test_get_policy: nothing in an ordinary build can
! make a write fail, so without this the tolerant arm of the put-side
! isErrorCritical is never entered by anything in the suite. The behavioural
! proof needs a pulse held under a different Data Dictionary version and a
! conversion layer to refuse a path, and lives in playground/.
!
! This test reaches the decision directly. isErrorCritical is a public module
! procedure of utilities_put_struct, and via checkErrorCtx it is the single
! chokepoint every leaf write and every nested struct/AoS-element call in the
! write path funnels through, so calling it with a hand-made status exercises
! exactly the decision that matters.
!
! This test deliberately drives the *fatal* branch too, and that branch prints
! "ERROR! with field ...". So its pass condition cannot be "the word ERROR is
! absent" -- it is the absence of POLICY-FAILURE, plus a zero exit status.
program test_put_policy
  use ids_types, only: ids_int
  use al_defs
  use al_put_policy
  use utilities_put_struct, only: isErrorCritical
  implicit none

  integer :: failures

  failures = 0
  call al_reset_refused_writes()

  ! Success is never critical.
  call expect(.not. critical(0, 'a/b'), 'status 0 must not be critical')

  ! Every status IMAS-Core itself allocates stays fatal. These are real failures
  ! of the write -- a backend or context problem -- and no amount of carrying on
  ! makes the occurrence more complete.
  call expect(critical(UNKNOWN_ERR,     'a/b'), 'UNKNOWN_ERR must be critical')
  call expect(critical(CONTEXT_ERR,     'a/b'), 'CONTEXT_ERR must be critical')
  call expect(critical(BACKEND_ERR,     'a/b'), 'BACKEND_ERR must be critical')
  call expect(critical(LOWLEVEL_ERR,    'a/b'), 'LOWLEVEL_ERR must be critical')
  call expect(critical(CONSISTENCY_ERR, 'a/b'), 'CONSISTENCY_ERR must be critical')

  ! None of those may be recorded as a refused write. If they were, a backend
  ! failure would come back as PARTIAL_PUT and read as a mostly-successful write.
  call expect(al_get_refused_write_count() == 0, &
              'a fatal status must not be counted as a refused write')

  ! A refusal is tolerated, and counted.
  call expect(.not. critical(AL_EXTERNAL_REFUSAL_MAX, 'time_slice/profiles_2d/grid_type/index'), &
              'a conversion refusal must not be critical')
  call expect(al_get_refused_write_count() == 1, 'a tolerated refusal must be counted')

  ! The whole reserved band is tolerated, not just the one value allocated today.
  call expect(.not. critical(AL_EXTERNAL_REFUSAL_MIN, 'x/y'), &
              'the far end of the reserved band must not be critical')
  call expect(al_get_refused_write_count() == 2, 'both tolerated refusals must be counted')

  ! Just outside the band, both sides, is fatal again.
  call expect(critical(AL_EXTERNAL_REFUSAL_MAX + 1, 'x/y'), &
              'just above the reserved band must be critical')
  call expect(critical(AL_EXTERNAL_REFUSAL_MIN - 1, 'x/y'), &
              'just below the reserved band must be critical')
  call expect(al_get_refused_write_count() == 2, &
              'a fatal status must not add to the refused-write count')

  ! A refused array of structures counts the same, because one refusal is one
  ! refusal as far as PARTIAL_PUT is concerned. It is only its report that
  ! differs, saying that a whole branch is unwritten rather than one value.
  call al_note_refused_write_subtree('time_slice/constraints/x_point', &
                                     AL_EXTERNAL_REFUSAL_MAX)
  call expect(al_get_refused_write_count() == 3, &
              'a refused array of structures must be counted')

  ! A reset makes the count describe one operation rather than the process.
  call al_reset_refused_writes()
  call expect(al_get_refused_write_count() == 0, 'reset must clear the count')

  ! PARTIAL_PUT has to stay distinguishable from every status the C ABI can
  ! produce, or a partial write would be indistinguishable from a failure.
  call expect(PARTIAL_PUT > 0, 'PARTIAL_PUT must be positive')
  call expect(.not. is_external_refusal(PARTIAL_PUT), 'PARTIAL_PUT must not look like a refusal')

  ! And from PARTIAL_READ, so a caller that both reads and writes can tell which
  ! half was incomplete.
  call expect(PARTIAL_PUT /= PARTIAL_READ, 'PARTIAL_PUT must differ from PARTIAL_READ')

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

end program test_put_policy
