! Assert, per rule rather than per leaf, that every structural rule in
! shim_rule_table produces agreement between:
!
!   - a DD 3.39.0 pulse read via a DD 4.1.1 HLI through the shim (converted),
!   - the DD 4.1.1 fixture read directly, same-version, plain passthrough.
!
! The second pulse is the oracle: imas-python-fixtures/README.md states it is
! the independently-authored expected result of converting the first, so
! comparing against it needs no value literals transcribed into Fortran.
!
! A failing check below names the rule that broke (id, kind and cited
! source), not only the field, per the suite's design (docs/adr/0002 and
! issue #63's acceptance criteria for this ticket).
program test_shim_structural_rules
  use ids_routines, only: ids_equilibrium, OPEN_PULSE, imas_open, imas_close, ids_get, ids_real
  use al_get_policy, only: PARTIAL_READ
  use shim_comparison, only: verdict_real, verdict_real_vector
  use shim_rule_table, only: structural_rules, structural_rule_count, expected_verdict_for_kind, kind_name
  implicit none

  type(ids_equilibrium) :: eq_cross, eq_control
  character(len=512) :: fixture_root
  integer :: context, status_cross, status_control
  integer :: failures, expectations

  call get_command_argument(1, fixture_root)
  if (len_trim(fixture_root) == 0) error stop 'missing fixture root'

  call imas_open('imas:hdf5?path='//trim(fixture_root)//'/dd-3.39.0', OPEN_PULSE, context)
  call ids_get(context, 'equilibrium', eq_cross, status_cross)
  call imas_close(context)

  call imas_open('imas:hdf5?path='//trim(fixture_root)//'/dd-4.1.1', OPEN_PULSE, context)
  call ids_get(context, 'equilibrium', eq_control, status_control)
  call imas_close(context)

  if (status_control /= 0) error stop 'same-version control read did not succeed cleanly'
  if (status_cross /= 0 .and. status_cross /= PARTIAL_READ) error stop 'cross-version read failed outright'

  failures = 0
  expectations = 0

  ! -- identical --
  call check('identical-vacuum-r0', &
       verdict_real(eq_cross%vacuum_toroidal_field%r0, eq_control%vacuum_toroidal_field%r0))
  call check('identical-time', &
       verdict_real_vector(.true., eq_cross%time, .true., eq_control%time))
  call check('identical-beta-pol', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%beta_pol, &
                    eq_control%time_slice(1)%global_quantities%beta_pol))

  ! -- renamed --
  call check('rename-beta-normal', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%beta_tor_norm, &
                    eq_control%time_slice(1)%global_quantities%beta_tor_norm))
  call check('rename-bpol-probe', &
       verdict_real(eq_cross%time_slice(1)%constraints%b_field_pol_probe(1)%measured, &
                    eq_control%time_slice(1)%constraints%b_field_pol_probe(1)%measured))
  call check('rename-mse-polarisation-angle', &
       verdict_real(eq_cross%time_slice(1)%constraints%mse_polarization_angle(1)%measured, &
                    eq_control%time_slice(1)%constraints%mse_polarization_angle(1)%measured))
  call check('rename-magnetisation-r', &
       verdict_real(eq_cross%time_slice(1)%constraints%iron_core_segment(1)%magnetization_r%measured, &
                    eq_control%time_slice(1)%constraints%iron_core_segment(1)%magnetization_r%measured))
  call check('rename-magnetisation-z', &
       verdict_real(eq_cross%time_slice(1)%constraints%iron_core_segment(1)%magnetization_z%measured, &
                    eq_control%time_slice(1)%constraints%iron_core_segment(1)%magnetization_z%measured))

  ! -- moved (each rule combines a r/z pair into one verdict) --
  call check('move-closest-wall-point', &
       combine2(verdict_real(eq_cross%time_slice(1)%boundary%closest_wall_point%r, &
                              eq_control%time_slice(1)%boundary%closest_wall_point%r), &
                verdict_real(eq_cross%time_slice(1)%boundary%closest_wall_point%z, &
                              eq_control%time_slice(1)%boundary%closest_wall_point%z)))
  call check('move-dr-dz-zero-point', &
       combine2(verdict_real(eq_cross%time_slice(1)%boundary%dr_dz_zero_point%r, &
                              eq_control%time_slice(1)%boundary%dr_dz_zero_point%r), &
                verdict_real(eq_cross%time_slice(1)%boundary%dr_dz_zero_point%z, &
                              eq_control%time_slice(1)%boundary%dr_dz_zero_point%z)))
  call check('move-gap', &
       combine2(verdict_real(eq_cross%time_slice(1)%boundary%gap(1)%r, &
                              eq_control%time_slice(1)%boundary%gap(1)%r), &
                verdict_real(eq_cross%time_slice(1)%boundary%gap(1)%z, &
                              eq_control%time_slice(1)%boundary%gap(1)%z)))

  ! -- merged: the eight folds --
  call check('fold-p2d-br', flat_2d_verdict(eq_cross%time_slice(1)%profiles_2d(1)%b_field_r, &
                                             eq_control%time_slice(1)%profiles_2d(1)%b_field_r))
  call check('fold-p2d-bz', flat_2d_verdict(eq_cross%time_slice(1)%profiles_2d(1)%b_field_z, &
                                             eq_control%time_slice(1)%profiles_2d(1)%b_field_z))
  call check('fold-p2d-bphi', flat_2d_verdict(eq_cross%time_slice(1)%profiles_2d(1)%b_field_phi, &
                                               eq_control%time_slice(1)%profiles_2d(1)%b_field_phi))
  call check('fold-axis-bphi', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%magnetic_axis%b_field_phi, &
                    eq_control%time_slice(1)%global_quantities%magnetic_axis%b_field_phi))
  call check('fold-p1d-baverage', &
       verdict_real_vector(.true., eq_cross%time_slice(1)%profiles_1d%b_field_average, &
                            .true., eq_control%time_slice(1)%profiles_1d%b_field_average))
  call check('fold-p1d-bmax', &
       verdict_real_vector(.true., eq_cross%time_slice(1)%profiles_1d%b_field_max, &
                            .true., eq_control%time_slice(1)%profiles_1d%b_field_max))
  call check('fold-p1d-bmin', &
       verdict_real_vector(.true., eq_cross%time_slice(1)%profiles_1d%b_field_min, &
                            .true., eq_control%time_slice(1)%profiles_1d%b_field_min))
  call check('fold-energy-mhd', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%energy_mhd, &
                    eq_control%time_slice(1)%global_quantities%energy_mhd))

  ! -- split: one DD3 source feeds two DD4 targets; both must agree --
  call check('split-psi-axis', &
       combine2(verdict_real(eq_cross%time_slice(1)%global_quantities%psi_axis, &
                              eq_control%time_slice(1)%global_quantities%psi_axis), &
                verdict_real(eq_cross%time_slice(1)%global_quantities%psi_magnetic_axis, &
                              eq_control%time_slice(1)%global_quantities%psi_magnetic_axis)))

  if (expectations /= structural_rule_count) then
    write(*, '(a,i0,a,i0,a)') 'STRUCTURAL-FAILURE: only ', expectations, ' of ', structural_rule_count, &
      ' rule table entries were checked'
    failures = failures + 1
  end if

  if (failures > 0) then
    write(*, '(a,i0,a)') 'STRUCTURAL-FAILURE: ', failures, ' structural rule(s) failed'
    stop 1
  end if

contains

  ! One rule can combine several leaf verdicts (e.g. an r/z pair); the rule
  ! fails if either does, and the first non-agreeing verdict is reported.
  function combine2(first, second) result(combined)
    character(len=6), intent(in) :: first, second
    character(len=6) :: combined

    if (first == 'same' .and. second == 'same') then
      combined = 'same'
    else if (first /= 'same') then
      combined = first
    else
      combined = second
    end if
  end function combine2

  function flat_2d_verdict(left, right) result(verdict)
    real(ids_real), intent(in) :: left(:,:), right(:,:)
    character(len=6) :: verdict

    verdict = verdict_real_vector(.true., reshape(left, [size(left)]), .true., reshape(right, [size(right)]))
  end function flat_2d_verdict

  function find_rule(id) result(idx)
    character(len=*), intent(in) :: id
    integer :: idx
    integer :: i

    idx = 0
    do i = 1, structural_rule_count
      if (trim(structural_rules(i)%id) == trim(id)) then
        idx = i
        return
      end if
    end do
    error stop 'test_shim_structural_rules: rule id not found in shim_rule_table: '//trim(id)
  end function find_rule

  subroutine check(id, verdict)
    character(len=*), intent(in) :: id
    character(len=6), intent(in) :: verdict
    integer :: idx
    character(len=6) :: expected

    idx = find_rule(id)
    expected = expected_verdict_for_kind(structural_rules(idx)%kind)
    expectations = expectations + 1
    if (trim(verdict) /= trim(expected)) then
      failures = failures + 1
      write(*, '(a,a,a,a,a,a,a,a,a,a)') 'STRUCTURAL-FAILURE: rule ', trim(id), ' (', &
        trim(kind_name(structural_rules(idx)%kind)), ') path ', trim(structural_rules(idx)%hli_path), &
        ' verdict=', trim(verdict), ' expected=', trim(expected)
      write(*, '(a,a)') '  source: ', trim(structural_rules(idx)%source)
    end if
  end subroutine check

end program test_shim_structural_rules
