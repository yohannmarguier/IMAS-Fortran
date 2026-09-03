! Synthetic truth table for the comparison oracle used by the shim contract
! suite.  A pulse can never prove its own comparator right, so every verdict is
! driven here from literals with an independently stated expected result.
program test_shim_comparison
  use ids_routines, only: ids_real, ids_int, ids_int_invalid
  use shim_comparison, only: verdict_real, verdict_integer, verdict_real_vector, color_for_verdict
  use shim_comparison, only: verdict_real_vector_by_size
  implicit none

  integer :: failures, expectations
  real(ids_real) :: absent_real, real_values(2), flipped_values(2), other_values(2), short_values(1)
  real(ids_real) :: empty_values(0)
  integer(ids_int) :: absent_integer

  failures = 0
  expectations = 0
  absent_real = -9.0e40_ids_real
  absent_integer = ids_int_invalid
  real_values = [1.0_ids_real, 2.0_ids_real]
  flipped_values = [-1.0_ids_real, -2.0_ids_real]
  other_values = [1.0_ids_real, 3.0_ids_real]
  short_values = [1.0_ids_real]

  call expect(verdict_real(3.0_ids_real, 3.0_ids_real) == 'same', 'equal reals are same')
  call expect(verdict_real(3.0_ids_real, -3.0_ids_real) == 'NOFLIP', &
              'unflipped reals are NOFLIP')
  call expect(verdict_real(3.0_ids_real, 4.0_ids_real) == 'DIFF', 'different reals are DIFF')
  call expect(verdict_real(3.0_ids_real, absent_real) == 'only4', 'right-absent real is only4')
  call expect(verdict_real(absent_real, 3.0_ids_real) == 'only3', 'left-absent real is only3')
  call expect(verdict_real(absent_real, absent_real) == '--', 'both-absent reals are --')
  call expect(verdict_integer(7_ids_int, 7_ids_int) == 'same', 'equal integers are same')
  call expect(verdict_integer(7_ids_int, 8_ids_int) == 'DIFF', 'different integers are DIFF')
  call expect(verdict_integer(7_ids_int, absent_integer) == 'only4', 'right-absent integer is only4')
  call expect(verdict_integer(absent_integer, 7_ids_int) == 'only3', 'left-absent integer is only3')
  call expect(verdict_integer(absent_integer, absent_integer) == '--', 'both-absent integers are --')
  call expect(verdict_real_vector(.true., real_values, .true., real_values) == 'same', &
              'equal vectors are same')
  call expect(verdict_real_vector(.true., real_values, .true., flipped_values) == 'NOFLIP', &
              'unflipped vectors are NOFLIP')
  call expect(verdict_real_vector(.true., real_values, .true., other_values) == 'DIFF', &
              'different vectors are DIFF')
  call expect(verdict_real_vector(.true., real_values, .true., short_values) == 'SHAPE', &
              'different vector extents are SHAPE')
  call expect(verdict_real_vector(.true., real_values, .false., short_values) == 'only4', &
              'right-absent vector is only4')
  call expect(verdict_real_vector(.false., short_values, .true., real_values) == 'only3', &
              'left-absent vector is only3')
  call expect(verdict_real_vector(.false., short_values, .false., short_values) == '--', &
              'both-absent vectors are --')
  call expect(color_for_verdict('NOFLIP') == color_for_verdict('DIFF'), &
              'NOFLIP has mismatch severity')

  ! The trap verdict_real_vector_by_size exists to close.  Asserting presence
  ! that was never checked -- `.true.` for a side the shim served nothing for --
  ! makes two empty readings agree, because equal extents send all_near into a
  ! loop that runs zero times and returns .true.
  call expect(verdict_real_vector(.true., empty_values, .true., empty_values) == 'same', &
              'hardcoded presence makes two unserved vectors agree')
  call expect(verdict_real_vector_by_size(empty_values, empty_values) == '--', &
              'size-derived presence calls two unserved vectors absent')
  call expect(verdict_real_vector_by_size(real_values, empty_values) == 'only4', &
              'size-derived presence calls an unserved right side only4')
  call expect(verdict_real_vector_by_size(empty_values, real_values) == 'only3', &
              'size-derived presence calls an unserved left side only3')
  call expect(verdict_real_vector_by_size(real_values, real_values) == 'same', &
              'size-derived presence still agrees on two served vectors')

  call expect(expectations == 24, 'all synthetic verdict cases must run')

  if (failures > 0) then
    write(*, '(a,i0,a)') 'COMPARISON-FAILURE: ', failures, ' expectation(s) failed'
    stop 1
  end if

contains

  subroutine expect(condition, what)
    logical, intent(in) :: condition
    character(len=*), intent(in) :: what

    expectations = expectations + 1
    if (.not. condition) then
      write(*, '(a,a)') 'COMPARISON-FAILURE: ', what
      failures = failures + 1
    end if
  end subroutine expect

end program test_shim_comparison
