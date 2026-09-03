! Assert, per rule rather than per leaf, that every COCOS 11 -> 17 rule in
! shim_rule_table produces agreement between:
!
!   - a DD 3.39.0 pulse read via a DD 4.1.1 HLI through the shim (converted,
!     which must apply the sign flip),
!   - the DD 4.1.1 fixture read directly, same-version, plain passthrough
!     (already written with the flip applied — see equilibrium_v4_1_1.py).
!
! The second pulse is the oracle: imas-python-fixtures/README.md states it is
! the independently-authored expected result of converting the first, so
! comparing against it needs no value literal transcribed into Fortran, and
! no sign is hand-flipped here either.
!
! This is the assertion issue #63 calls the whole suite's reason to exist: a
! quantity whose required sign flip stopped being applied must fail, and fail
! under the verdict that names that specific failure. shim_comparison's
! verdict_real / verdict_real_vector already distinguish it: two values equal
! in magnitude but opposite in sign report 'NOFLIP', not the generic 'DIFF' a
! reader could skim past, and NOFLIP carries mismatch severity, not warning
! severity (see shim_comparison's color_for_verdict and its unit test). This
! program supplies no comparison logic of its own; per-rule kind and verdict
! come entirely from shim_rule_table, per the suite's stated-once design.
program test_shim_cocos_rules
  use ids_routines, only: ids_equilibrium, OPEN_PULSE, imas_open, imas_close, ids_get, ids_real
  use al_get_policy, only: PARTIAL_READ
  use ids_schemas_equilibrium, only: ids_equilibrium_constraints_0D_position
  use shim_comparison, only: verdict_real, verdict_real_vector_by_size
  use shim_rule_table, only: cocos_rules, cocos_rule_count, expected_verdict_for_kind, kind_name
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

  call check('cocos-boundary-psi', &
       verdict_real(eq_cross%time_slice(1)%boundary%psi, eq_control%time_slice(1)%boundary%psi))

  call check('cocos-flux-loop-measured', &
       verdict_real(eq_cross%time_slice(1)%constraints%flux_loop(1)%measured, &
                    eq_control%time_slice(1)%constraints%flux_loop(1)%measured))
  call check('cocos-flux-loop-reconstructed', &
       verdict_real(eq_cross%time_slice(1)%constraints%flux_loop(1)%reconstructed, &
                    eq_control%time_slice(1)%constraints%flux_loop(1)%reconstructed))

  call check('cocos-ip-measured', &
       verdict_real(eq_cross%time_slice(1)%constraints%ip%measured, &
                    eq_control%time_slice(1)%constraints%ip%measured))
  call check('cocos-ip-reconstructed', &
       verdict_real(eq_cross%time_slice(1)%constraints%ip%reconstructed, &
                    eq_control%time_slice(1)%constraints%ip%reconstructed))

  call check('cocos-j-phi-position-psi', &
       position_psi_verdict(eq_cross%time_slice(1)%constraints%j_phi, &
                             eq_control%time_slice(1)%constraints%j_phi))
  call check('cocos-n-e-position-psi', &
       position_psi_verdict(eq_cross%time_slice(1)%constraints%n_e, &
                             eq_control%time_slice(1)%constraints%n_e))

  call check('cocos-pf-current-measured', &
       verdict_real(eq_cross%time_slice(1)%constraints%pf_current(1)%measured, &
                    eq_control%time_slice(1)%constraints%pf_current(1)%measured))
  call check('cocos-pf-current-reconstructed', &
       verdict_real(eq_cross%time_slice(1)%constraints%pf_current(1)%reconstructed, &
                    eq_control%time_slice(1)%constraints%pf_current(1)%reconstructed))

  call check('cocos-pressure-position-psi', &
       position_psi_verdict(eq_cross%time_slice(1)%constraints%pressure, &
                             eq_control%time_slice(1)%constraints%pressure))
  call check('cocos-pressure-rot-position-psi', &
       position_psi_verdict(eq_cross%time_slice(1)%constraints%pressure_rotational, &
                             eq_control%time_slice(1)%constraints%pressure_rotational))
  call check('cocos-q-position-psi', &
       position_psi_verdict(eq_cross%time_slice(1)%constraints%q, &
                             eq_control%time_slice(1)%constraints%q))

  call check('cocos-ggd-psi-values', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%ggd(1)%psi(1)%values, &
                                   eq_control%time_slice(1)%ggd(1)%psi(1)%values))

  call check('cocos-gq-ip', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%ip, &
                    eq_control%time_slice(1)%global_quantities%ip))
  call check('cocos-psi-axis', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%psi_axis, &
                    eq_control%time_slice(1)%global_quantities%psi_axis))
  call check('cocos-psi-magnetic-axis', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%psi_magnetic_axis, &
                    eq_control%time_slice(1)%global_quantities%psi_magnetic_axis))
  call check('cocos-psi-boundary', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%psi_boundary, &
                    eq_control%time_slice(1)%global_quantities%psi_boundary))
  call check('cocos-psi-external-average', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%psi_external_average, &
                    eq_control%time_slice(1)%global_quantities%psi_external_average))
  call check('cocos-v-external', &
       verdict_real(eq_cross%time_slice(1)%global_quantities%v_external, &
                    eq_control%time_slice(1)%global_quantities%v_external))

  call check('cocos-p1d-darea-dpsi', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%profiles_1d%darea_dpsi, &
                                   eq_control%time_slice(1)%profiles_1d%darea_dpsi))
  call check('cocos-p1d-dpressure-dpsi', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%profiles_1d%dpressure_dpsi, &
                                   eq_control%time_slice(1)%profiles_1d%dpressure_dpsi))
  call check('cocos-p1d-dpsi-drho-tor', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%profiles_1d%dpsi_drho_tor, &
                                   eq_control%time_slice(1)%profiles_1d%dpsi_drho_tor))
  call check('cocos-p1d-dvolume-dpsi', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%profiles_1d%dvolume_dpsi, &
                                   eq_control%time_slice(1)%profiles_1d%dvolume_dpsi))
  call check('cocos-p1d-f-df-dpsi', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%profiles_1d%f_df_dpsi, &
                                   eq_control%time_slice(1)%profiles_1d%f_df_dpsi))
  call check('cocos-p1d-j-parallel', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%profiles_1d%j_parallel, &
                                   eq_control%time_slice(1)%profiles_1d%j_parallel))
  call check('cocos-p1d-j-phi', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%profiles_1d%j_phi, &
                                   eq_control%time_slice(1)%profiles_1d%j_phi))
  call check('cocos-p1d-psi', &
       verdict_real_vector_by_size(eq_cross%time_slice(1)%profiles_1d%psi, &
                                   eq_control%time_slice(1)%profiles_1d%psi))

  call check('cocos-p2d-j-parallel', &
       flat_2d_verdict(eq_cross%time_slice(1)%profiles_2d(1)%j_parallel, &
                        eq_control%time_slice(1)%profiles_2d(1)%j_parallel))
  call check('cocos-p2d-j-phi', &
       flat_2d_verdict(eq_cross%time_slice(1)%profiles_2d(1)%j_phi, &
                        eq_control%time_slice(1)%profiles_2d(1)%j_phi))
  call check('cocos-p2d-psi', &
       flat_2d_verdict(eq_cross%time_slice(1)%profiles_2d(1)%psi, &
                        eq_control%time_slice(1)%profiles_2d(1)%psi))

  if (expectations /= cocos_rule_count) then
    write(*, '(a,i0,a,i0,a)') 'COCOS-FAILURE: only ', expectations, ' of ', cocos_rule_count, &
      ' rule table entries were checked'
    failures = failures + 1
  end if

  if (failures > 0) then
    write(*, '(a,i0,a)') 'COCOS-FAILURE: ', failures, ' cocos rule(s) failed'
    stop 1
  end if

contains

  ! Guards the five constraints/{n_e,pressure,pressure_rotational,q,j_phi}
  ! position/psi checks against indexing an empty AOS. Found the hard way:
  ! the shim refuses `constraints/j_phi` outright on the cross-version
  ! read -- "this path is served by several stored candidates, and only a
  ! data read can try them in turn" -- because DD3 offers it two ways
  ! (`j_phi` itself and the obsolescent `j_tor` alias fold-constraints-j
  ! merges) and the shim's path-level resolution won't pick between them
  ! the way it does for a plain scalar fold. That leaves
  ! `eq_cross%...%j_phi` an unassociated pointer, not an allocated
  ! zero-length array, so indexing element 1 unconditionally segfaults the
  ! whole suite before any rule gets to report anything -- worse than a red
  ! test, since it hides every other rule's result too. This mirrors the
  ! fold-axis-bphi candidate-fallback
  ! defect shim_rule_table.f90 already documents for the structural rules,
  ! just refusing outright here instead of returning a wrong not-found
  ! value. Not chased here -- that is shim work; this suite reports it as
  ! the ordinary rule failure it is (expected 'same', the refused cross
  ! side reads as 'only3') rather than crashing.
  !
  ! `cross`/`control` must stay POINTER dummies: a refused subtree leaves the
  ! generated get routine's pointer component unassociated (its `=> null()`
  ! default), not allocated to size zero. Binding an unassociated pointer to
  ! a plain assumed-shape dummy is undefined behaviour in Fortran -- even
  ! `size()` on it crashes before any branch below runs, regardless of
  ! -fcheck=bounds -- so associated() has to gate size() here rather than
  ! size() alone gating the element access.
  function position_psi_verdict(cross, control) result(verdict)
    type(ids_equilibrium_constraints_0D_position), pointer, intent(in) :: cross(:), control(:)
    character(len=6) :: verdict
    logical :: has_left, has_right

    has_left = associated(cross)
    if (has_left) has_left = size(cross) >= 1
    has_right = associated(control)
    if (has_right) has_right = size(control) >= 1
    if (.not. has_left .and. .not. has_right) then
      verdict = '--'
    else if (.not. has_right) then
      verdict = 'only4'
    else if (.not. has_left) then
      verdict = 'only3'
    else
      verdict = verdict_real(cross(1)%position%psi, control(1)%position%psi)
    end if
  end function position_psi_verdict

  function flat_2d_verdict(left, right) result(verdict)
    real(ids_real), intent(in) :: left(:,:), right(:,:)
    character(len=6) :: verdict

    verdict = verdict_real_vector_by_size(reshape(left, [size(left)]), reshape(right, [size(right)]))
  end function flat_2d_verdict

  function find_rule(id) result(idx)
    character(len=*), intent(in) :: id
    integer :: idx
    integer :: i

    idx = 0
    do i = 1, cocos_rule_count
      if (trim(cocos_rules(i)%id) == trim(id)) then
        idx = i
        return
      end if
    end do
    error stop 'test_shim_cocos_rules: rule id not found in shim_rule_table: '//trim(id)
  end function find_rule

  subroutine check(id, verdict)
    character(len=*), intent(in) :: id
    character(len=6), intent(in) :: verdict
    integer :: idx
    character(len=6) :: expected

    idx = find_rule(id)
    expected = expected_verdict_for_kind(cocos_rules(idx)%kind)
    expectations = expectations + 1
    if (trim(verdict) /= trim(expected)) then
      failures = failures + 1
      write(*, '(a,a,a,a,a,a,a,a,a,a)') 'COCOS-FAILURE: rule ', trim(id), ' (', &
        trim(kind_name(cocos_rules(idx)%kind)), ') path ', trim(cocos_rules(idx)%hli_path), &
        ' verdict=', trim(verdict), ' expected=', trim(expected)
      write(*, '(a,a)') '  source: ', trim(cocos_rules(idx)%source)
      if (trim(verdict) == 'NOFLIP') then
        write(*, '(a)') '  the required COCOS sign flip did not happen'
      end if
    end if
  end subroutine check

end program test_shim_cocos_rules
