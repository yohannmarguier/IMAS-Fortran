! Read-side policy for paths an interposing layer refuses to serve.
!
! Background. When al-fortran is linked against a DD-conversion layer (the
! IMAS-Multiversion-DD-Loader, see docs/adr/0001-multiversion-shim-linkage.md)
! rather than against IMAS-Core directly, a read of a pulse written under a
! different Data Dictionary version can hit a path that layer cannot serve --
! typically because the container changed shape between the two dictionaries and
! no value transformation maps one onto the other. The layer answers such a read
! with a refusal rather than with data.
!
! A refusal is not a failure of the read. The path does not exist in the calling
! HLI's dictionary and no retry can make it appear, so aborting the whole ids_get
! gains nothing and costs every other field in the IDS. This module is what lets
! the generated read routines leave the refused field unset and carry on, while
! keeping a record of exactly what was skipped.
!
! Two predicates are deliberately kept apart:
!
!   is_external_refusal(code)  -- is this status *eligible* to be tolerated?
!   (node locality)            -- is this *site* one where tolerating is sound?
!
! The second is not expressed here, because it is structural rather than a
! run-time test. Only two sites in IDSDef2F90Routines.xsl may consult this
! module: isErrorCritical, and the failure arm of al_begin_arraystruct_action.
! Both are per-field. The refusal code is *also* what the conversion layer
! returns from al_begin_global_action and the data-entry seams, for a malformed
! version stamp or a version-latch conflict; tolerating one of those would sail
! past an IDS that was never opened. Do not reuse the predicate there.
!
! The log is process-global and not thread-safe. That matches the rest of the
! generated code, which is already non-reentrant in the same way (the IDS-level
! routines declare `integer(ids_int) :: status = 0`, whose initialiser implies
! SAVE). The contract is one GET at a time per process.
module al_get_policy

  use al_defs
  implicit none

  ! Kept small and fixed. This is written from an error path, where growing an
  ! allocatable is its own failure mode. A read that refuses more than this many
  ! distinct paths is pathological; the counter below still reports the truth.
  integer, parameter :: AL_SKIP_LOG_CAPACITY = 64
  integer, parameter :: AL_SKIP_PATH_LEN     = 256

  type :: al_skipped_path
     character(len=AL_SKIP_PATH_LEN)  :: path    = ' '
     character(len=MAX_ERR_MSG_LEN)   :: message = ' '
     integer                          :: code    = 0
  end type al_skipped_path

  type(al_skipped_path), save :: al_skip_log(AL_SKIP_LOG_CAPACITY)

  ! Number of paths skipped by the current operation. May exceed
  ! AL_SKIP_LOG_CAPACITY, in which case only the first CAPACITY are retained.
  integer, save :: al_skip_total = 0

  ! Set by fstatus in al_low_level_wrap on every non-zero status, so that the
  ! explanatory text the C layer produced can be attached to a skip without
  ! threading an extra argument through every generated call site. Only trusted
  ! when the code matches the one being recorded.
  integer,                        save :: al_last_status_code    = 0
  character(len=MAX_ERR_MSG_LEN), save :: al_last_status_message = ' '

contains

  ! Is this status one an interposing layer uses to say "I cannot serve this
  ! path"? IMAS-Core allocates only -1..-5 (UNKNOWN_ERR..CONSISTENCY_ERR), so a
  ! build without such a layer can never satisfy this test.
  pure logical function is_external_refusal(code)
    integer, intent(in) :: code
    is_external_refusal = (code .le. AL_EXTERNAL_REFUSAL_MAX) .and. &
                          (code .ge. AL_EXTERNAL_REFUSAL_MIN)
  end function is_external_refusal

  subroutine al_note_skipped_path(path, code)
    character(len=*), intent(in) :: path
    integer, intent(in) :: code
    integer :: slot

    al_skip_total = al_skip_total + 1
    if (al_skip_total .le. AL_SKIP_LOG_CAPACITY) then
       slot = al_skip_total
       al_skip_log(slot)%path = path
       al_skip_log(slot)%code = code
       if (al_last_status_code .eq. code) then
          al_skip_log(slot)%message = al_last_status_message
       else
          al_skip_log(slot)%message = ' '
       end if
    end if

    write(*,*) "SKIPPED: '", trim(path), "' cannot be served (status ", code, ")"
  end subroutine al_note_skipped_path

  ! Record the message belonging to a status, for al_note_skipped_path to pick
  ! up. Called from fstatus; not part of the API a reader should use.
  subroutine al_note_status_message(code, message)
    integer, intent(in) :: code
    character(len=*), intent(in) :: message
    al_last_status_code = code
    al_last_status_message = message
  end subroutine al_note_status_message

  ! How many paths the current operation left unset. Zero means the read was
  ! complete. This is the signal a caller checks alongside PARTIAL_READ.
  pure integer function al_get_skipped_count()
    al_get_skipped_count = al_skip_total
  end function al_get_skipped_count

  ! Retrieve one entry, 1-based. `found` is .FALSE. if the index is out of range
  ! or beyond what the fixed-size log retained.
  subroutine al_get_skipped_path(index, path, code, message, found)
    integer, intent(in) :: index
    character(len=*), intent(out) :: path, message
    integer, intent(out) :: code
    logical, intent(out) :: found

    if (index .lt. 1 .or. index .gt. min(al_skip_total, AL_SKIP_LOG_CAPACITY)) then
       path = ' '
       message = ' '
       code = 0
       found = .FALSE.
       return
    end if

    path = al_skip_log(index)%path
    message = al_skip_log(index)%message
    code = al_skip_log(index)%code
    found = .TRUE.
  end subroutine al_get_skipped_path

  ! Called at the start of each ids_get / ids_get_slice / ids_get_sample, so the
  ! log describes one operation rather than the life of the process.
  subroutine al_reset_skip_log()
    al_skip_total = 0
  end subroutine al_reset_skip_log

  subroutine al_report_skipped_paths(unit)
    integer, intent(in) :: unit
    integer :: i, shown

    if (al_skip_total .eq. 0) then
       write(unit,*) 'No paths were skipped: the read was complete.'
       return
    end if

    shown = min(al_skip_total, AL_SKIP_LOG_CAPACITY)
    write(unit,*) 'Paths left unset because they could not be served:', al_skip_total
    do i = 1, shown
       write(unit,*) '  ', trim(al_skip_log(i)%path), &
                     ' (status ', al_skip_log(i)%code, ') ', &
                     trim(al_skip_log(i)%message)
    end do
    if (al_skip_total .gt. shown) then
       write(unit,*) '  ... and', al_skip_total - shown, 'more, not retained.'
    end if
  end subroutine al_report_skipped_paths

end module al_get_policy
