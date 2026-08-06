! Read a DD 3.39.0 equilibrium entry through a DD 4.1.1 library, and check that what
! comes back is the DD 4.1.1 representation of it.
!
! The conversion is done entirely by the Rust read-path middleware
! (middleware/src/lib.rs) executing dd-maps/equilibrium/3.39.0--4.1.1.xml: the program
! below is ordinary DD 4.1.1 al-fortran code and says nothing about DD 3. Contrast
! play_eq_two_dd.f90 + eq_convert_3to4.f90, which do the same job by reading into a DD 3
! type and copying field by field — 1132 lines of hand-written Fortran that has to be
! rewritten for every IDS and every version pair.
!
! What makes this checkable rather than merely runnable: imas-python-fixtures/ ships the
! *pair*. equilibrium_seed.py writes fixtures/dd-3.39.0 and fixtures/dd-4.1.1 from one set
! of numbers, applying by hand exactly the renames, folds and sign flips the map declares.
! So fill_dd4()'s values are the right answer, independently arrived at, and the
! assertions below are transcribed from it.
!
! Run it from this directory (the fixture path is relative):
!   IMAS_FORTRAN_PREFIX=install-equilibrium ./build.sh play_eq_mw_convert.f90
!   ./bin/play_eq_mw_convert
!   IMAS_MW_TRACE=1 ./bin/play_eq_mw_convert     # and see every read and its rewrite
program play_eq_mw_convert
  use ids_routines
  use iso_c_binding
  implicit none

  character(*), parameter :: FIXTURE = '../imas-python-fixtures/fixtures/dd-3.39.0'
  integer, parameter :: NTIME = 2, NPSI = 4, NDIM1 = 2, NDIM2 = 3

  ! The middleware's own exports. imas_mw_conversion_report prints what the conversion
  ! cost; imas_mw_conversion_losses is the same thing as a number, so a program can assert
  ! on it without parsing stderr. setenv is here because the map is a run-time switch and
  ! this program is about one specific conversion — asking the caller to remember an
  ! environment variable would make it fail confusingly when they did not.
  interface
     subroutine imas_mw_conversion_report() bind(C, name="imas_mw_conversion_report")
     end subroutine imas_mw_conversion_report

     function imas_mw_conversion_losses() bind(C, name="imas_mw_conversion_losses")
       use, intrinsic :: iso_c_binding
       integer(C_INT64_T) :: imas_mw_conversion_losses
     end function imas_mw_conversion_losses

     function setenv(name, value, overwrite) bind(C, name="setenv")
       use, intrinsic :: iso_c_binding
       character(C_CHAR), dimension(*), intent(in) :: name, value
       integer(C_INT), value, intent(in) :: overwrite
       integer(C_INT) :: setenv
     end function setenv
  end interface

  integer :: idx, status, i, r, c, failures
  integer(C_INT) :: ignored
  character(:), allocatable :: retmsg
  type(ids_equilibrium) :: eq

  failures = 0

  ! Set before the first read: the middleware reads the variable once, through a OnceLock,
  ! and imas_open does not go through the read path.
  ignored = setenv('IMAS_MW_CONVERT'//C_NULL_CHAR, '3.39.0'//C_NULL_CHAR, 0_C_INT)

  print '(a,a)', ' library DD version : ', trim(al_dd_version)
  print '(a,a)', ' entry being read   : ', FIXTURE

  call imas_open('imas:hdf5?path='//FIXTURE, OPEN_PULSE, idx, status, retmsg)
  if (status /= 0) then
     print *, 'imas_open failed: ', retmsg
     stop 1
  end if

  call ids_get(idx, 'equilibrium', eq, status)
  if (status /= 0) then
     print *, 'ids_get failed, status = ', status
     call imas_close(idx)
     stop 1
  end if
  call imas_close(idx)

  ! ---------------------------------------------------------------- identical paths

  call check('vacuum_toroidal_field/r0', eq%vacuum_toroidal_field%r0, 6.2d0)
  call check_1d('vacuum_toroidal_field/b0', eq%vacuum_toroidal_field%b0, [5.3d0, 5.2d0])
  call check_1d('time', eq%time, [1.0d0, 1.5d0])

  if (.not. associated(eq%time_slice)) then
     print *, 'FAILED: time_slice was not read at all'
     stop 1
  end if
  if (size(eq%time_slice) /= NTIME) then
     print *, 'FAILED: expected ', NTIME, ' time slices, got ', size(eq%time_slice)
     stop 1
  end if

  do i = 1, NTIME
     print '(a,i0,a)', ' --- time_slice(', i, ')'

     ! ------------------------------------------------------------ COCOS sign flips
     ! Identical paths whose *value* changes: COCOS 11 -> 17 flips the sign, and the map
     ! lists 32 such paths. Nothing here renames anything.
     call check_1d('profiles_1d/psi', eq%time_slice(i)%profiles_1d%psi, &
          [(-(0.25d0 + (r - 1) + 10.0d0 * (i - 1)), r = 1, NPSI)])
     call check_1d('profiles_1d/f_df_dpsi', eq%time_slice(i)%profiles_1d%f_df_dpsi, &
          [(1.5d0 + (r - 1) + 0.5d0 * (i - 1), r = 1, NPSI)])
     call check('global_quantities/ip', eq%time_slice(i)%global_quantities%ip, &
          -(15.0d6 + 1.0d5 * (i - 1)))
     call check('constraints/ip/measured', &
          eq%time_slice(i)%constraints%ip%measured, -(15.1d6 + 1.0d5 * (i - 1)))

     ! ------------------------------------------------------------ merged (fold-p1d-j)
     ! The map gives j_phi precedence 1 and j_tor precedence 2, but 3.39.0 has no
     ! profiles_1d/j_phi at all - j_tor is the only spelling there is. So this passing
     ! means the middleware fell through to precedence 2. Plus the flip.
     call check_1d('profiles_1d/j_phi <- j_tor', eq%time_slice(i)%profiles_1d%j_phi, &
          [(-(1.0d6 + 1.0d5 * (r - 1) + 1.0d4 * (i - 1)), r = 1, NPSI)])

     ! ------------------------------------------------------------ merged (fold-p2d-bphi)
     ! Three DD 3 spellings collapse to one: b_field_phi, b_field_tor, b_tor. Only the
     ! latter two exist in 3.39.0, and the fixture fills both with the same number - they
     ! are one quantity, so a fold cannot pick a wrong precedence here. Not in the map's
     ! <cocos> list, so no flip.
     if (.not. associated(eq%time_slice(i)%profiles_2d)) then
        call fail('profiles_2d', 'the array of structures is empty')
     else
        call check_1d('profiles_2d/grid/dim1', &
             eq%time_slice(i)%profiles_2d(1)%grid%dim1, [4.0d0, 5.0d0])
        call check_1d('profiles_2d/grid/dim2', &
             eq%time_slice(i)%profiles_2d(1)%grid%dim2, [-1.0d0, 0.0d0, 1.0d0])
        if (.not. associated(eq%time_slice(i)%profiles_2d(1)%b_field_phi)) then
           call fail('profiles_2d/b_field_phi <- b_field_tor', 'not read')
        else
           do r = 1, NDIM1
              do c = 1, NDIM2
                 call check('profiles_2d/b_field_phi <- b_field_tor', &
                      eq%time_slice(i)%profiles_2d(1)%b_field_phi(r, c), &
                      3.1d0 + (r - 1) + 0.1d0 * (c - 1) + (i - 1))
              end do
           end do
        end if
     end if

     ! ------------------------------------------------------------ merged (fold-axis-bphi)
     call check('global_quantities/magnetic_axis/b_field_phi <- b_field_tor', &
          eq%time_slice(i)%global_quantities%magnetic_axis%b_field_phi, &
          5.2d0 + 0.1d0 * (i - 1))

     ! ------------------------------------------------------------ renamed
     call check('global_quantities/beta_tor_norm <- beta_normal', &
          eq%time_slice(i)%global_quantities%beta_tor_norm, 1.8d0 + 0.1d0 * (i - 1))

     ! ------------------------------------------------------------ split (split-psi-axis)
     ! One DD 3 path feeds both DD 4 spellings, and both take the flip.
     call check('global_quantities/psi_magnetic_axis <- psi_axis', &
          eq%time_slice(i)%global_quantities%psi_magnetic_axis, 0.75d0 + 0.05d0 * (i - 1))
     call check('global_quantities/psi_axis', &
          eq%time_slice(i)%global_quantities%psi_axis, 0.75d0 + 0.05d0 * (i - 1))

     ! ------------------------------------------------------------ renamed AOS
     ! constraints/bpol_probe -> constraints/b_field_pol_probe is an array of structures,
     ! so it is renamed when the context opens, not when a field is read. Without that,
     ! the array comes back zero-length and the whole subtree is silently lost.
     if (.not. associated(eq%time_slice(i)%constraints%b_field_pol_probe)) then
        call fail('constraints/b_field_pol_probe <- bpol_probe', &
             'the array of structures is empty - the AOS path was not rewritten')
     else
        call check('constraints/b_field_pol_probe(1)/measured <- bpol_probe(1)/measured', &
             eq%time_slice(i)%constraints%b_field_pol_probe(1)%measured, &
             0.42d0 + 0.01d0 * (i - 1))
     end if

     ! ------------------------------------------------------------ refused
     ! chi_squared_r went from m to m^-2: chi-squared is now normalised by the measurement
     ! variance, and no factor inverts that without the variance used at reconstruction
     ! time. The map calls it unmappable, so the middleware hands back ids_real_invalid
     ! rather than the DD 3 number wearing DD 4 units.
     !
     ! This is the one place the middleware deliberately does NOT reproduce
     ! fixtures/dd-4.1.1, where equilibrium_seed.py copies the value across unchanged.
     if (.not. associated(eq%time_slice(i)%constraints%strike_point)) then
        call fail('constraints/strike_point', 'the array of structures is empty')
     else
        call check('constraints/strike_point(1)/chi_squared_r (refused)', &
             eq%time_slice(i)%constraints%strike_point(1)%chi_squared_r, ids_real_invalid)
     end if

     ! ------------------------------------------------------------ right_only
     ! New in DD 4, nothing in DD 3 to build it from. The read still happens — the DD 4
     ! name is simply not in the DD 3 entry — so the field comes back as ids_real_invalid,
     ! exactly as a sparsely filled entry's unwritten fields do. That the read is not
     ! *skipped* is what keeps it from being uninitialised stack memory instead.
     call check('boundary/rho_tor (no DD3 source)', &
          eq%time_slice(i)%boundary%rho_tor, ids_real_invalid)
  end do

  call ids_deallocate(eq)

  ! ---------------------------------------------------------------- the cost

  print *
  call imas_mw_conversion_report()
  print *

  if (imas_mw_conversion_losses() <= 0) then
     print *, 'FAILED: the middleware reported no conversion at all -'
     print *, '        either it is not linked in or IMAS_MW_CONVERT did not take'
     failures = failures + 1
  end if

  if (failures > 0) then
     print '(a,i0,a)', ' FAILED: ', failures, ' checks did not match the DD 4.1.1 fixture'
     stop 1
  end if
  print *, 'PASSED: the DD 3.39.0 entry read back as its DD 4.1.1 representation.'

contains

  ! Relative comparison, since the values here span 0.1 to 1.5e7. The conversion is a
  ! rename, a fallback or a sign flip, none of which perturbs a mantissa, so the tolerance
  ! only has to cover the decimal literals above.
  subroutine check(what, got, want)
    character(*), intent(in) :: what
    real(ids_real), intent(in) :: got, want
    real(ids_real) :: scale
    scale = max(abs(want), 1.0d0)
    if (abs(got - want) > 1.0d-12 * scale) then
       print '(a,a)', '   FAILED ', what
       print '(a,es24.16,a,es24.16)', '     got ', got, '  want ', want
       failures = failures + 1
    else
       print '(a,a,a,es14.7)', '   ok     ', what, ' = ', got
    end if
  end subroutine check

  subroutine check_1d(what, got, want)
    character(*), intent(in) :: what
    real(ids_real), dimension(:), pointer, intent(in) :: got
    real(ids_real), dimension(:), intent(in) :: want
    integer :: k
    if (.not. associated(got)) then
       call fail(what, 'not read (null pointer)')
       return
    end if
    if (size(got) /= size(want)) then
       print '(a,a,a,i0,a,i0)', '   FAILED ', what, ': got ', size(got), &
            ' values, want ', size(want)
       failures = failures + 1
       return
    end if
    do k = 1, size(want)
       call check(what, got(k), want(k))
    end do
  end subroutine check_1d

  subroutine fail(what, why)
    character(*), intent(in) :: what, why
    print '(a,a,a,a)', '   FAILED ', what, ': ', why
    failures = failures + 1
  end subroutine fail

end program play_eq_mw_convert
