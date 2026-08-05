! Shows that the Rust read-path middleware is really in the path of an ids_get.
!
! Every read al-fortran issues goes through imas_mw_read_data (middleware/src/lib.rs)
! on its way to al-core's al_read_data. That is invisible by construction — the shim
! forwards unchanged — so this program asserts it from the outside instead of trusting
! the values it reads back: it counts the reads the shim saw, and checks the count moves
! only across the get and that the data survives the round trip intact.
!
! Run with IMAS_MW_TRACE=1 to also see one line per field on stderr:
!   IMAS_FORTRAN_PREFIX=install-equilibrium ./build.sh play_middleware.f90
!   IMAS_MW_TRACE=1 ./bin/play_middleware
program play_middleware
  use ids_routines
  use iso_c_binding
  implicit none

  ! The shim's own counter. Reaching for it here rather than parsing the trace is the
  ! point: a program can assert the middleware is installed without tracing being on,
  ! and the assertion fails loudly if the wrapper is ever re-pointed at al_read_data.
  interface
     function imas_mw_read_count() bind(C, name="imas_mw_read_count")
       use, intrinsic :: iso_c_binding
       integer(C_INT64_T) :: imas_mw_read_count
     end function imas_mw_read_count
  end interface

  integer, parameter :: NTIME = 5
  integer :: idx, status, i
  character(:), allocatable :: retmsg
  type(ids_equilibrium) :: eq_out, eq_in
  integer(C_INT64_T) :: at_start, after_put, after_get

  at_start = imas_mw_read_count()
  print '(a,i0)', ' reads seen by the middleware at startup: ', at_start

  call imas_open('imas:ascii?path=./playground_db_middleware', FORCE_CREATE_PULSE, &
       idx, status, retmsg)
  if (status /= 0) then
     print *, 'imas_open failed: ', retmsg
     stop 1
  end if

  eq_out%ids_properties%homogeneous_time = 1
  allocate(eq_out%time(NTIME))
  do i = 1, NTIME
     eq_out%time(i) = 0.1d0 * i
  end do

  print *, 'Putting equilibrium IDS...'
  call ids_put(idx, 'equilibrium', eq_out)
  after_put = imas_mw_read_count()

  print *, 'Getting equilibrium IDS back...'
  call ids_get(idx, 'equilibrium', eq_in)
  after_get = imas_mw_read_count()

  call imas_close(idx)

  print '(a,i0)', ' reads during put(): ', after_put - at_start
  print '(a,i0)', ' reads during get(): ', after_get - after_put

  ! A put writes; if it read anything through the shim the counter would say so.
  if (after_put /= at_start) then
     print *, 'NOTE: put() went through the read path ', after_put - at_start, ' times'
  end if

  if (after_get <= after_put) then
     print *, 'FAILED: get() drove no reads through the middleware - it is not in the path'
     stop 1
  end if

  ! Array components of a generated IDS type are pointers, not allocatables, so an
  ! unread field is a null pointer rather than an unallocated one.
  if (.not. associated(eq_in%time)) then
     print *, 'FAILED: time was not read back'
     stop 1
  end if
  if (size(eq_in%time) /= NTIME) then
     print *, 'FAILED: expected ', NTIME, ' time points, read ', size(eq_in%time)
     stop 1
  end if
  do i = 1, NTIME
     if (abs(eq_in%time(i) - 0.1d0 * i) > 1.0d-12) then
        print *, 'FAILED: time(', i, ') came back as ', eq_in%time(i)
        stop 1
     end if
  end do

  print *, 'Time values read back through the middleware: ', eq_in%time
  print *, 'PASSED: the middleware is in the read path and forwards unchanged.'
end program play_middleware
