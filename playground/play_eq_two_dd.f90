! Reads both equilibrium fixtures through the multiversion shim and prints, path
! by path, the DD 4.1.1 value beside the DD 3.39.0 one.
!
! This program is compiled against ONE data dictionary: the DD 4.1.1 al-fortran
! in ../install-shim. Both pulses are therefore read into the same DD 4.1.1
! derived type. The 4.1.1 pulse passes through the shim untouched; the 3.39.0
! pulse is a different dictionary, so the shim converts it on the way in --
! translating the paths al_read_data asks for, applying the COCOS 11 -> 17 sign
! flips, and refusing the paths its map declares unservable. The last column
! reports what came back:
!
!   same    both dictionaries gave the same number
!   FLIP    equal up to sign -- a COCOS 11 -> 17 flip
!   DIFF    both present, and they disagree
!   only4   4.1.1 has it, the 3.39.0 read produced nothing
!   only3   the 3.39.0 read produced it, 4.1.1 has nothing
!   SHAPE   both present, different extents
!   --      neither side has it
!
! Arrays print element 1 as a sample, with their extent in the path column; the
! verdict is computed over the whole array, not over the sample.

module eq_table
  use ids_routines
  implicit none

  integer, parameter :: PW = 52                          ! path column width
  real(ids_real), parameter :: TOL = 1.0e-9_ids_real

contains

  logical function unset_d(x)
    real(ids_real), intent(in) :: x
    unset_d = (x <= -1.0e40_ids_real) .or. (x /= x)
  end function

  logical function near(a, b)
    real(ids_real), intent(in) :: a, b
    near = abs(a - b) <= TOL * max(1.0_ids_real, abs(a), abs(b))
  end function

  logical function all_near(a, b)
    real(ids_real), intent(in) :: a(:), b(:)
    integer :: i
    all_near = .false.
    if (size(a) /= size(b)) return
    do i = 1, size(a)
      if (.not. near(a(i), b(i))) return
    end do
    all_near = .true.
  end function

  subroutine cmp_flat(a, b, same, flip)
    real(ids_real), intent(in) :: a(:), b(:)
    logical, intent(out) :: same, flip
    same = all_near(a, b)
    flip = .false.
    if (.not. same) flip = all_near(a, -b)
  end subroutine

  function pad(s) result(p)
    character(len=*), intent(in) :: s
    character(len=PW) :: p
    p = s
  end function

  function num_d(x) result(s)
    real(ids_real), intent(in) :: x
    character(len=15) :: s
    if (unset_d(x)) then
      s = '              -'
    else
      write(s, '(es15.6)') x
    end if
  end function

  ! The one place a verdict is decided, so every row type agrees on the words.
  subroutine emit(path, p4, p3, s4, s3, same, flip, shape_ok)
    character(len=*), intent(in) :: path
    logical, intent(in) :: p4, p3, same, flip, shape_ok
    real(ids_real), intent(in) :: s4, s3
    character(len=6) :: v

    if (.not. p4 .and. .not. p3) then
      v = '--'
    else if (.not. p3) then
      v = 'only4'
    else if (.not. p4) then
      v = 'only3'
    else if (.not. shape_ok) then
      v = 'SHAPE'
    else if (same) then
      v = 'same'
    else if (flip) then
      v = 'FLIP'
    else
      v = 'DIFF'
    end if
    write(*, '(a,2x,a15,2x,a15,2x,a)') pad(path), num_d(s4), num_d(s3), trim(v)
  end subroutine

  subroutine row_d(path, a, b)
    character(len=*), intent(in) :: path
    real(ids_real), intent(in) :: a, b
    call emit(path, .not. unset_d(a), .not. unset_d(b), a, b, &
              near(a, b), near(a, -b), .true.)
  end subroutine

  subroutine row_i(path, a, b)
    character(len=*), intent(in) :: path
    integer(ids_int), intent(in) :: a, b
    logical :: p4, p3
    character(len=15) :: s4, s3
    character(len=6) :: v

    p4 = (a /= ids_int_invalid)
    p3 = (b /= ids_int_invalid)
    s4 = '              -'
    s3 = '              -'
    if (p4) write(s4, '(i15)') a
    if (p3) write(s3, '(i15)') b

    if (.not. p4 .and. .not. p3) then
      v = '--'
    else if (.not. p3) then
      v = 'only4'
    else if (.not. p4) then
      v = 'only3'
    else if (a == b) then
      v = 'same'
    else
      v = 'DIFF'
    end if
    write(*, '(a,2x,a15,2x,a15,2x,a)') pad(path), s4, s3, trim(v)
  end subroutine

  subroutine row_d1(path, a, b)
    character(len=*), intent(in) :: path
    real(ids_real), pointer, intent(in) :: a(:), b(:)
    logical :: same, flip, shape_ok
    real(ids_real) :: s4, s3
    character(len=16) :: tag

    same = .false.; flip = .false.; shape_ok = .true.
    s4 = -9.0e40_ids_real; s3 = -9.0e40_ids_real
    tag = ''
    if (associated(a)) then
      write(tag, '(a,i0,a)') '[', size(a), ']'
      if (size(a) > 0) s4 = a(1)
    end if
    if (associated(b)) then
      if (size(b) > 0) s3 = b(1)
    end if
    if (associated(a) .and. associated(b)) then
      shape_ok = (size(a) == size(b))
      if (shape_ok) call cmp_flat(a, b, same, flip)
    end if
    call emit(trim(path)//trim(tag), associated(a), associated(b), &
              s4, s3, same, flip, shape_ok)
  end subroutine

  subroutine row_d2(path, a, b)
    character(len=*), intent(in) :: path
    real(ids_real), pointer, intent(in) :: a(:,:), b(:,:)
    logical :: same, flip, shape_ok
    real(ids_real) :: s4, s3
    character(len=20) :: tag

    same = .false.; flip = .false.; shape_ok = .true.
    s4 = -9.0e40_ids_real; s3 = -9.0e40_ids_real
    tag = ''
    if (associated(a)) then
      write(tag, '(a,i0,a,i0,a)') '[', size(a,1), 'x', size(a,2), ']'
      if (size(a) > 0) s4 = a(1,1)
    end if
    if (associated(b)) then
      if (size(b) > 0) s3 = b(1,1)
    end if
    if (associated(a) .and. associated(b)) then
      shape_ok = all(shape(a) == shape(b))
      if (shape_ok) call cmp_flat(reshape(a, [size(a)]), reshape(b, [size(b)]), same, flip)
    end if
    call emit(trim(path)//trim(tag), associated(a), associated(b), &
              s4, s3, same, flip, shape_ok)
  end subroutine

  subroutine row_d4(path, a, b)
    character(len=*), intent(in) :: path
    real(ids_real), pointer, intent(in) :: a(:,:,:,:), b(:,:,:,:)
    logical :: same, flip, shape_ok
    real(ids_real) :: s4, s3
    character(len=20) :: tag

    same = .false.; flip = .false.; shape_ok = .true.
    s4 = -9.0e40_ids_real; s3 = -9.0e40_ids_real
    tag = ''
    if (associated(a)) then
      write(tag, '(a,i0,a)') '[', size(a), ' tot]'
      if (size(a) > 0) s4 = a(1,1,1,1)
    end if
    if (associated(b)) then
      if (size(b) > 0) s3 = b(1,1,1,1)
    end if
    if (associated(a) .and. associated(b)) then
      shape_ok = all(shape(a) == shape(b))
      if (shape_ok) call cmp_flat(reshape(a, [size(a)]), reshape(b, [size(b)]), same, flip)
    end if
    call emit(trim(path)//trim(tag), associated(a), associated(b), &
              s4, s3, same, flip, shape_ok)
  end subroutine

  subroutine sect(title)
    character(len=*), intent(in) :: title
    write(*, '(a)') ''
    write(*, '(a)') '-- '//trim(title)//' '// &
                    repeat('-', max(1, 100 - 4 - len_trim(title)))
  end subroutine

  function dd_stamp(ids) result(s)
    type(ids_equilibrium), intent(in) :: ids
    character(len=32) :: s
    s = '(no version_put stamp)'
    if (associated(ids%ids_properties%version_put%data_dictionary)) then
      if (size(ids%ids_properties%version_put%data_dictionary) > 0) &
        s = ids%ids_properties%version_put%data_dictionary(1)
    end if
  end function

end module eq_table


program play_eq_two_dd
  use ids_routines
  use eq_table
  implicit none

  integer, parameter :: SL = 1                  ! which time slice the table shows

  type(ids_equilibrium) :: e4, e3
  type(ids_equilibrium_time_slice), pointer :: t4, t3
  type(ids_equilibrium_profiles_2d), pointer :: q4, q3
  character(len=512) :: root, arg, pulse4, pulse3
  integer :: idx

  ! argv: [fixture-root] [pulse-for-column-1] [pulse-for-column-2]. Passing the
  ! same pulse twice is the way to check the table itself rather than the shim:
  ! every row must then read 'same'.
  call get_command_argument(1, arg)
  root = 'imas-python-fixtures/fixtures'
  if (len_trim(arg) > 0) root = trim(arg)
  call get_command_argument(2, arg)
  pulse4 = 'dd-4.1.1'
  if (len_trim(arg) > 0) pulse4 = trim(arg)
  call get_command_argument(3, arg)
  pulse3 = 'dd-3.39.0'
  if (len_trim(arg) > 0) pulse3 = trim(arg)

  call imas_open('imas:hdf5?path='//trim(root)//'/'//trim(pulse4), OPEN_PULSE, idx)
  call ids_get(idx, 'equilibrium', e4)
  call imas_close(idx)

  call imas_open('imas:hdf5?path='//trim(root)//'/'//trim(pulse3), OPEN_PULSE, idx)
  call ids_get(idx, 'equilibrium', e3)
  call imas_close(idx)

  write(*, '(a)') ''
  write(*, '(a)') 'HLI dictionary   : 4.1.1 (both pulses read into the DD 4.1.1 type)'
  write(*, '(a)') 'column 1         : '//trim(pulse4)//'  stamp '//trim(dd_stamp(e4))
  write(*, '(a)') 'column 2         : '//trim(pulse3)//'  stamp '//trim(dd_stamp(e3))
  write(*, '(a)') 'time slice shown : '//char(48 + SL)

  if (.not. associated(e4%time_slice) .or. .not. associated(e3%time_slice)) then
    write(*, '(a)') 'ERROR: a pulse came back with no time_slice'
    stop 1
  end if
  if (size(e4%time_slice) < SL .or. size(e3%time_slice) < SL) then
    write(*, '(a)') 'ERROR: a pulse has fewer time slices than requested'
    stop 1
  end if
  t4 => e4%time_slice(SL)
  t3 => e3%time_slice(SL)

  write(*, '(a)') ''
  write(*, '(a,2x,a15,2x,a15,2x,a)') pad('PATH'), '       column 1', '       column 2', 'SHIM'
  write(*, '(a)') repeat('=', 100)

  call sect('IDS level')
  call row_i('ids_properties/homogeneous_time', &
             e4%ids_properties%homogeneous_time, e3%ids_properties%homogeneous_time)
  call row_d('vacuum_toroidal_field/r0', &
             e4%vacuum_toroidal_field%r0, e3%vacuum_toroidal_field%r0)
  call row_d1('vacuum_toroidal_field/b0', &
              e4%vacuum_toroidal_field%b0, e3%vacuum_toroidal_field%b0)
  call row_d1('time', e4%time, e3%time)
  call row_d('time_slice/time', t4%time, t3%time)

  call sect('global_quantities  (beta_tor_norm <- beta_normal, energy_mhd <- w_mhd fold)')
  call row_d('global_quantities/ip', t4%global_quantities%ip, t3%global_quantities%ip)
  call row_d('global_quantities/beta_pol', t4%global_quantities%beta_pol, t3%global_quantities%beta_pol)
  call row_d('global_quantities/beta_tor', t4%global_quantities%beta_tor, t3%global_quantities%beta_tor)
  call row_d('global_quantities/beta_tor_norm', t4%global_quantities%beta_tor_norm, t3%global_quantities%beta_tor_norm)
  call row_d('global_quantities/li_3', t4%global_quantities%li_3, t3%global_quantities%li_3)
  call row_d('global_quantities/volume', t4%global_quantities%volume, t3%global_quantities%volume)
  call row_d('global_quantities/area', t4%global_quantities%area, t3%global_quantities%area)
  call row_d('global_quantities/surface', t4%global_quantities%surface, t3%global_quantities%surface)
  call row_d('global_quantities/length_pol', t4%global_quantities%length_pol, t3%global_quantities%length_pol)
  call row_d('global_quantities/psi_axis', t4%global_quantities%psi_axis, t3%global_quantities%psi_axis)
  call row_d('global_quantities/psi_magnetic_axis', t4%global_quantities%psi_magnetic_axis, t3%global_quantities%psi_magnetic_axis)
  call row_d('global_quantities/psi_boundary', t4%global_quantities%psi_boundary, t3%global_quantities%psi_boundary)
  call row_d('global_quantities/rho_tor_boundary', t4%global_quantities%rho_tor_boundary, t3%global_quantities%rho_tor_boundary)
  call row_d('global_quantities/magnetic_axis/r', t4%global_quantities%magnetic_axis%r, t3%global_quantities%magnetic_axis%r)
  call row_d('global_quantities/magnetic_axis/z', t4%global_quantities%magnetic_axis%z, t3%global_quantities%magnetic_axis%z)
  call row_d('global_quantities/magnetic_axis/b_field_phi', t4%global_quantities%magnetic_axis%b_field_phi, t3%global_quantities%magnetic_axis%b_field_phi)
  call row_d('global_quantities/current_centre/r', t4%global_quantities%current_centre%r, t3%global_quantities%current_centre%r)
  call row_d('global_quantities/current_centre/z', t4%global_quantities%current_centre%z, t3%global_quantities%current_centre%z)
  call row_d('global_quantities/current_centre/velocity_z', t4%global_quantities%current_centre%velocity_z, t3%global_quantities%current_centre%velocity_z)
  call row_d('global_quantities/q_axis', t4%global_quantities%q_axis, t3%global_quantities%q_axis)
  call row_d('global_quantities/q_95', t4%global_quantities%q_95, t3%global_quantities%q_95)
  call row_d('global_quantities/q_min/value', t4%global_quantities%q_min%value, t3%global_quantities%q_min%value)
  call row_d('global_quantities/q_min/rho_tor_norm', t4%global_quantities%q_min%rho_tor_norm, t3%global_quantities%q_min%rho_tor_norm)
  call row_d('global_quantities/q_min/psi_norm', t4%global_quantities%q_min%psi_norm, t3%global_quantities%q_min%psi_norm)
  call row_d('global_quantities/q_min/psi', t4%global_quantities%q_min%psi, t3%global_quantities%q_min%psi)
  call row_d('global_quantities/energy_mhd', t4%global_quantities%energy_mhd, t3%global_quantities%energy_mhd)
  call row_d('global_quantities/psi_external_average', t4%global_quantities%psi_external_average, t3%global_quantities%psi_external_average)
  call row_d('global_quantities/v_external', t4%global_quantities%v_external, t3%global_quantities%v_external)
  call row_d('global_quantities/plasma_inductance', t4%global_quantities%plasma_inductance, t3%global_quantities%plasma_inductance)
  call row_d('global_quantities/plasma_resistance', t4%global_quantities%plasma_resistance, t3%global_quantities%plasma_resistance)

  call sect('boundary  (closest_wall_point, dr_dz_zero_point, gap <- boundary_separatrix)')
  call row_i('boundary/type', t4%boundary%type, t3%boundary%type)
  call row_d1('boundary/outline/r', t4%boundary%outline%r, t3%boundary%outline%r)
  call row_d1('boundary/outline/z', t4%boundary%outline%z, t3%boundary%outline%z)
  call row_d('boundary/psi_norm', t4%boundary%psi_norm, t3%boundary%psi_norm)
  call row_d('boundary/psi', t4%boundary%psi, t3%boundary%psi)
  call row_d('boundary/geometric_axis/r', t4%boundary%geometric_axis%r, t3%boundary%geometric_axis%r)
  call row_d('boundary/geometric_axis/z', t4%boundary%geometric_axis%z, t3%boundary%geometric_axis%z)
  call row_d('boundary/minor_radius', t4%boundary%minor_radius, t3%boundary%minor_radius)
  call row_d('boundary/elongation', t4%boundary%elongation, t3%boundary%elongation)
  call row_d('boundary/triangularity', t4%boundary%triangularity, t3%boundary%triangularity)
  call row_d('boundary/triangularity_upper', t4%boundary%triangularity_upper, t3%boundary%triangularity_upper)
  call row_d('boundary/triangularity_lower', t4%boundary%triangularity_lower, t3%boundary%triangularity_lower)
  call row_d('boundary/squareness_upper_inner', t4%boundary%squareness_upper_inner, t3%boundary%squareness_upper_inner)
  call row_d('boundary/squareness_upper_outer', t4%boundary%squareness_upper_outer, t3%boundary%squareness_upper_outer)
  call row_d('boundary/squareness_lower_inner', t4%boundary%squareness_lower_inner, t3%boundary%squareness_lower_inner)
  call row_d('boundary/squareness_lower_outer', t4%boundary%squareness_lower_outer, t3%boundary%squareness_lower_outer)
  call row_d('boundary/closest_wall_point/r', t4%boundary%closest_wall_point%r, t3%boundary%closest_wall_point%r)
  call row_d('boundary/closest_wall_point/z', t4%boundary%closest_wall_point%z, t3%boundary%closest_wall_point%z)
  call row_d('boundary/closest_wall_point/distance', t4%boundary%closest_wall_point%distance, t3%boundary%closest_wall_point%distance)
  call row_d('boundary/dr_dz_zero_point/r', t4%boundary%dr_dz_zero_point%r, t3%boundary%dr_dz_zero_point%r)
  call row_d('boundary/dr_dz_zero_point/z', t4%boundary%dr_dz_zero_point%z, t3%boundary%dr_dz_zero_point%z)
  call row_d('boundary/rho_tor', t4%boundary%rho_tor, t3%boundary%rho_tor)
  call row_d('boundary/phi', t4%boundary%phi, t3%boundary%phi)
  call row_d('boundary/phi_poloidal_current', t4%boundary%phi_poloidal_current, t3%boundary%phi_poloidal_current)
  if (associated(t4%boundary%gap) .and. associated(t3%boundary%gap)) then
    if (size(t4%boundary%gap) > 0 .and. size(t3%boundary%gap) > 0) then
      call row_d('boundary/gap(1)/r', t4%boundary%gap(1)%r, t3%boundary%gap(1)%r)
      call row_d('boundary/gap(1)/z', t4%boundary%gap(1)%z, t3%boundary%gap(1)%z)
      call row_d('boundary/gap(1)/angle', t4%boundary%gap(1)%angle, t3%boundary%gap(1)%angle)
      call row_d('boundary/gap(1)/value', t4%boundary%gap(1)%value, t3%boundary%gap(1)%value)
    end if
  else
    write(*, '(a,a)') pad('boundary/gap(*)'), '   (AOS absent on one side)'
  end if

  ! DD 4.1.1 has no DD 3.39.0 source for this structure. Both columns are still
  ! read from their own pulse rather than one of them hardcoded to 'absent', so
  ! that a self-test (same pulse twice) reports 'same' here like everywhere else
  ! and only a genuine 3.39.0 read reports 'only4'.
  call sect('contour_tree  (no DD 3.39.0 source)')
  if (associated(t4%contour_tree%node) .and. associated(t3%contour_tree%node)) then
    call row_i('contour_tree/node(1)/critical_type', t4%contour_tree%node(1)%critical_type, t3%contour_tree%node(1)%critical_type)
    call row_d('contour_tree/node(1)/r', t4%contour_tree%node(1)%r, t3%contour_tree%node(1)%r)
    call row_d('contour_tree/node(1)/z', t4%contour_tree%node(1)%z, t3%contour_tree%node(1)%z)
    call row_d('contour_tree/node(1)/psi', t4%contour_tree%node(1)%psi, t3%contour_tree%node(1)%psi)
  else if (associated(t4%contour_tree%node)) then
    call row_i('contour_tree/node(1)/critical_type', t4%contour_tree%node(1)%critical_type, ids_int_invalid)
    call row_d('contour_tree/node(1)/r', t4%contour_tree%node(1)%r, -9.0e40_ids_real)
    call row_d('contour_tree/node(1)/z', t4%contour_tree%node(1)%z, -9.0e40_ids_real)
    call row_d('contour_tree/node(1)/psi', t4%contour_tree%node(1)%psi, -9.0e40_ids_real)
  else
    write(*, '(a,a)') pad('contour_tree/node(*)'), '   (absent on both sides)'
  end if

  call sect('profiles_1d  (j_phi <- j_tor; b_field_* <- b_* folds)')
  call row_d1('profiles_1d/psi', t4%profiles_1d%psi, t3%profiles_1d%psi)
  call row_d1('profiles_1d/psi_norm', t4%profiles_1d%psi_norm, t3%profiles_1d%psi_norm)
  call row_d1('profiles_1d/phi', t4%profiles_1d%phi, t3%profiles_1d%phi)
  call row_d1('profiles_1d/pressure', t4%profiles_1d%pressure, t3%profiles_1d%pressure)
  call row_d1('profiles_1d/f', t4%profiles_1d%f, t3%profiles_1d%f)
  call row_d1('profiles_1d/dpressure_dpsi', t4%profiles_1d%dpressure_dpsi, t3%profiles_1d%dpressure_dpsi)
  call row_d1('profiles_1d/f_df_dpsi', t4%profiles_1d%f_df_dpsi, t3%profiles_1d%f_df_dpsi)
  call row_d1('profiles_1d/j_phi', t4%profiles_1d%j_phi, t3%profiles_1d%j_phi)
  call row_d1('profiles_1d/j_parallel', t4%profiles_1d%j_parallel, t3%profiles_1d%j_parallel)
  call row_d1('profiles_1d/q', t4%profiles_1d%q, t3%profiles_1d%q)
  call row_d1('profiles_1d/magnetic_shear', t4%profiles_1d%magnetic_shear, t3%profiles_1d%magnetic_shear)
  call row_d1('profiles_1d/r_inboard', t4%profiles_1d%r_inboard, t3%profiles_1d%r_inboard)
  call row_d1('profiles_1d/r_outboard', t4%profiles_1d%r_outboard, t3%profiles_1d%r_outboard)
  call row_d1('profiles_1d/rho_tor', t4%profiles_1d%rho_tor, t3%profiles_1d%rho_tor)
  call row_d1('profiles_1d/rho_tor_norm', t4%profiles_1d%rho_tor_norm, t3%profiles_1d%rho_tor_norm)
  call row_d1('profiles_1d/dpsi_drho_tor', t4%profiles_1d%dpsi_drho_tor, t3%profiles_1d%dpsi_drho_tor)
  call row_d1('profiles_1d/geometric_axis/r', t4%profiles_1d%geometric_axis%r, t3%profiles_1d%geometric_axis%r)
  call row_d1('profiles_1d/geometric_axis/z', t4%profiles_1d%geometric_axis%z, t3%profiles_1d%geometric_axis%z)
  call row_d1('profiles_1d/elongation', t4%profiles_1d%elongation, t3%profiles_1d%elongation)
  call row_d1('profiles_1d/triangularity_upper', t4%profiles_1d%triangularity_upper, t3%profiles_1d%triangularity_upper)
  call row_d1('profiles_1d/triangularity_lower', t4%profiles_1d%triangularity_lower, t3%profiles_1d%triangularity_lower)
  call row_d1('profiles_1d/squareness_upper_inner', t4%profiles_1d%squareness_upper_inner, t3%profiles_1d%squareness_upper_inner)
  call row_d1('profiles_1d/squareness_upper_outer', t4%profiles_1d%squareness_upper_outer, t3%profiles_1d%squareness_upper_outer)
  call row_d1('profiles_1d/squareness_lower_inner', t4%profiles_1d%squareness_lower_inner, t3%profiles_1d%squareness_lower_inner)
  call row_d1('profiles_1d/squareness_lower_outer', t4%profiles_1d%squareness_lower_outer, t3%profiles_1d%squareness_lower_outer)
  call row_d1('profiles_1d/volume', t4%profiles_1d%volume, t3%profiles_1d%volume)
  call row_d1('profiles_1d/rho_volume_norm', t4%profiles_1d%rho_volume_norm, t3%profiles_1d%rho_volume_norm)
  call row_d1('profiles_1d/dvolume_dpsi', t4%profiles_1d%dvolume_dpsi, t3%profiles_1d%dvolume_dpsi)
  call row_d1('profiles_1d/dvolume_drho_tor', t4%profiles_1d%dvolume_drho_tor, t3%profiles_1d%dvolume_drho_tor)
  call row_d1('profiles_1d/area', t4%profiles_1d%area, t3%profiles_1d%area)
  call row_d1('profiles_1d/darea_dpsi', t4%profiles_1d%darea_dpsi, t3%profiles_1d%darea_dpsi)
  call row_d1('profiles_1d/darea_drho_tor', t4%profiles_1d%darea_drho_tor, t3%profiles_1d%darea_drho_tor)
  call row_d1('profiles_1d/surface', t4%profiles_1d%surface, t3%profiles_1d%surface)
  call row_d1('profiles_1d/trapped_fraction', t4%profiles_1d%trapped_fraction, t3%profiles_1d%trapped_fraction)
  call row_d1('profiles_1d/gm1', t4%profiles_1d%gm1, t3%profiles_1d%gm1)
  call row_d1('profiles_1d/gm2', t4%profiles_1d%gm2, t3%profiles_1d%gm2)
  call row_d1('profiles_1d/gm3', t4%profiles_1d%gm3, t3%profiles_1d%gm3)
  call row_d1('profiles_1d/gm4', t4%profiles_1d%gm4, t3%profiles_1d%gm4)
  call row_d1('profiles_1d/gm5', t4%profiles_1d%gm5, t3%profiles_1d%gm5)
  call row_d1('profiles_1d/gm6', t4%profiles_1d%gm6, t3%profiles_1d%gm6)
  call row_d1('profiles_1d/gm7', t4%profiles_1d%gm7, t3%profiles_1d%gm7)
  call row_d1('profiles_1d/gm8', t4%profiles_1d%gm8, t3%profiles_1d%gm8)
  call row_d1('profiles_1d/gm9', t4%profiles_1d%gm9, t3%profiles_1d%gm9)
  call row_d1('profiles_1d/b_field_average', t4%profiles_1d%b_field_average, t3%profiles_1d%b_field_average)
  call row_d1('profiles_1d/b_field_min', t4%profiles_1d%b_field_min, t3%profiles_1d%b_field_min)
  call row_d1('profiles_1d/b_field_max', t4%profiles_1d%b_field_max, t3%profiles_1d%b_field_max)
  call row_d1('profiles_1d/beta_pol', t4%profiles_1d%beta_pol, t3%profiles_1d%beta_pol)
  call row_d1('profiles_1d/mass_density', t4%profiles_1d%mass_density, t3%profiles_1d%mass_density)

  call sect('profiles_2d(1)  (j_phi <- j_tor, b_field_phi <- b_tor/b_field_tor)')
  if (associated(t4%profiles_2d) .and. associated(t3%profiles_2d)) then
    if (size(t4%profiles_2d) > 0 .and. size(t3%profiles_2d) > 0) then
      q4 => t4%profiles_2d(1)
      q3 => t3%profiles_2d(1)
      call row_d1('profiles_2d(1)/grid/dim1', q4%grid%dim1, q3%grid%dim1)
      call row_d1('profiles_2d(1)/grid/dim2', q4%grid%dim2, q3%grid%dim2)
      call row_d2('profiles_2d(1)/grid/volume_element', q4%grid%volume_element, q3%grid%volume_element)
      call row_d2('profiles_2d(1)/r', q4%r, q3%r)
      call row_d2('profiles_2d(1)/z', q4%z, q3%z)
      call row_d2('profiles_2d(1)/psi', q4%psi, q3%psi)
      call row_d2('profiles_2d(1)/theta', q4%theta, q3%theta)
      call row_d2('profiles_2d(1)/phi', q4%phi, q3%phi)
      call row_d2('profiles_2d(1)/j_phi', q4%j_phi, q3%j_phi)
      call row_d2('profiles_2d(1)/j_parallel', q4%j_parallel, q3%j_parallel)
      call row_d2('profiles_2d(1)/b_field_r', q4%b_field_r, q3%b_field_r)
      call row_d2('profiles_2d(1)/b_field_phi', q4%b_field_phi, q3%b_field_phi)
      call row_d2('profiles_2d(1)/b_field_z', q4%b_field_z, q3%b_field_z)
    end if
  else
    write(*, '(a,a)') pad('profiles_2d(*)'), '   (AOS absent on one side)'
  end if

  call sect('coordinate_system  (g_ij dropped in DD 4.1.1; tensors carry it)')
  call row_d1('coordinate_system/grid/dim1', t4%coordinate_system%grid%dim1, t3%coordinate_system%grid%dim1)
  call row_d1('coordinate_system/grid/dim2', t4%coordinate_system%grid%dim2, t3%coordinate_system%grid%dim2)
  call row_d2('coordinate_system/r', t4%coordinate_system%r, t3%coordinate_system%r)
  call row_d2('coordinate_system/z', t4%coordinate_system%z, t3%coordinate_system%z)
  call row_d2('coordinate_system/jacobian', t4%coordinate_system%jacobian, t3%coordinate_system%jacobian)
  call row_d4('coordinate_system/tensor_covariant', t4%coordinate_system%tensor_covariant, t3%coordinate_system%tensor_covariant)
  call row_d4('coordinate_system/tensor_contravariant', t4%coordinate_system%tensor_contravariant, t3%coordinate_system%tensor_contravariant)

  call sect('ggd(1)  (j_phi <- j_tor, b_field_phi <- b_field_tor)')
  if (associated(t4%ggd) .and. associated(t3%ggd)) then
    if (size(t4%ggd) > 0 .and. size(t3%ggd) > 0) then
      call ggd_row('ggd(1)/psi(1)/values', 1)
      call ggd_row('ggd(1)/phi(1)/values', 2)
      call ggd_row('ggd(1)/theta(1)/values', 3)
      call ggd_row('ggd(1)/j_phi(1)/values', 4)
      call ggd_row('ggd(1)/j_parallel(1)/values', 5)
      call ggd_row('ggd(1)/b_field_r(1)/values', 6)
      call ggd_row('ggd(1)/b_field_phi(1)/values', 7)
      call ggd_row('ggd(1)/b_field_z(1)/values', 8)
    end if
  else
    write(*, '(a,a)') pad('ggd(*)'), '   (AOS absent on one side)'
  end if

  call sect('constraints  (b_field_pol_probe <- bpol_probe, mse_polarization_angle, j_phi)')
  call row_d('constraints/b_field_tor_vacuum_r/measured', t4%constraints%b_field_tor_vacuum_r%measured, t3%constraints%b_field_tor_vacuum_r%measured)
  call row_d('constraints/b_field_tor_vacuum_r/reconstructed', t4%constraints%b_field_tor_vacuum_r%reconstructed, t3%constraints%b_field_tor_vacuum_r%reconstructed)
  call row_d('constraints/diamagnetic_flux/measured', t4%constraints%diamagnetic_flux%measured, t3%constraints%diamagnetic_flux%measured)
  call row_d('constraints/ip/measured', t4%constraints%ip%measured, t3%constraints%ip%measured)
  call row_d('constraints/ip/reconstructed', t4%constraints%ip%reconstructed, t3%constraints%ip%reconstructed)
  call row_d('constraints/chi_squared_reduced', t4%constraints%chi_squared_reduced, t3%constraints%chi_squared_reduced)
  call row_i('constraints/freedom_degrees_n', t4%constraints%freedom_degrees_n, t3%constraints%freedom_degrees_n)
  call row_i('constraints/constraints_n', t4%constraints%constraints_n, t3%constraints%constraints_n)
  if (associated(t4%constraints%b_field_pol_probe) .and. associated(t3%constraints%b_field_pol_probe)) then
    call row_d('constraints/b_field_pol_probe(1)/measured', t4%constraints%b_field_pol_probe(1)%measured, t3%constraints%b_field_pol_probe(1)%measured)
    call row_d('constraints/b_field_pol_probe(1)/reconstructed', t4%constraints%b_field_pol_probe(1)%reconstructed, t3%constraints%b_field_pol_probe(1)%reconstructed)
    call row_d('constraints/b_field_pol_probe(1)/chi_squared', t4%constraints%b_field_pol_probe(1)%chi_squared, t3%constraints%b_field_pol_probe(1)%chi_squared)
  else
    write(*, '(a,a)') pad('constraints/b_field_pol_probe(*)'), '   (AOS absent on one side)'
  end if
  if (associated(t4%constraints%mse_polarization_angle) .and. associated(t3%constraints%mse_polarization_angle)) then
    call row_d('constraints/mse_polarization_angle(1)/measured', t4%constraints%mse_polarization_angle(1)%measured, t3%constraints%mse_polarization_angle(1)%measured)
  else
    write(*, '(a,a)') pad('constraints/mse_polarization_angle(*)'), '   (AOS absent on one side)'
  end if
  if (associated(t4%constraints%iron_core_segment) .and. associated(t3%constraints%iron_core_segment)) then
    call row_d('constraints/iron_core_segment(1)/magnetization_r/measured', t4%constraints%iron_core_segment(1)%magnetization_r%measured, t3%constraints%iron_core_segment(1)%magnetization_r%measured)
    call row_d('constraints/iron_core_segment(1)/magnetization_z/measured', t4%constraints%iron_core_segment(1)%magnetization_z%measured, t3%constraints%iron_core_segment(1)%magnetization_z%measured)
  else
    write(*, '(a,a)') pad('constraints/iron_core_segment(*)'), '   (AOS absent on one side)'
  end if
  if (associated(t4%constraints%j_phi) .and. associated(t3%constraints%j_phi)) then
    call row_d('constraints/j_phi(1)/measured', t4%constraints%j_phi(1)%measured, t3%constraints%j_phi(1)%measured)
  else
    write(*, '(a,a)') pad('constraints/j_phi(*)'), '   (AOS absent on one side)'
  end if
  if (associated(t4%constraints%flux_loop) .and. associated(t3%constraints%flux_loop)) then
    call row_d('constraints/flux_loop(1)/measured', t4%constraints%flux_loop(1)%measured, t3%constraints%flux_loop(1)%measured)
  end if
  if (associated(t4%constraints%n_e) .and. associated(t3%constraints%n_e)) then
    call row_d('constraints/n_e(1)/measured', t4%constraints%n_e(1)%measured, t3%constraints%n_e(1)%measured)
  end if
  if (associated(t4%constraints%pressure) .and. associated(t3%constraints%pressure)) then
    call row_d('constraints/pressure(1)/measured', t4%constraints%pressure(1)%measured, t3%constraints%pressure(1)%measured)
  end if
  if (associated(t4%constraints%q) .and. associated(t3%constraints%q)) then
    call row_d('constraints/q(1)/measured', t4%constraints%q(1)%measured, t3%constraints%q(1)%measured)
  end if

  call sect('constraints chi_squared_r/z  (m -> m^-2 redefinition: unmappable)')
  if (associated(t4%constraints%x_point) .and. associated(t3%constraints%x_point)) then
    call row_d('constraints/x_point(1)/position_measured/r', t4%constraints%x_point(1)%position_measured%r, t3%constraints%x_point(1)%position_measured%r)
    call row_d('constraints/x_point(1)/position_measured/z', t4%constraints%x_point(1)%position_measured%z, t3%constraints%x_point(1)%position_measured%z)
    call row_d('constraints/x_point(1)/chi_squared_r', t4%constraints%x_point(1)%chi_squared_r, t3%constraints%x_point(1)%chi_squared_r)
    call row_d('constraints/x_point(1)/chi_squared_z', t4%constraints%x_point(1)%chi_squared_z, t3%constraints%x_point(1)%chi_squared_z)
  end if
  if (associated(t4%constraints%strike_point) .and. associated(t3%constraints%strike_point)) then
    call row_d('constraints/strike_point(1)/chi_squared_r', t4%constraints%strike_point(1)%chi_squared_r, t3%constraints%strike_point(1)%chi_squared_r)
    call row_d('constraints/strike_point(1)/chi_squared_z', t4%constraints%strike_point(1)%chi_squared_z, t3%constraints%strike_point(1)%chi_squared_z)
  end if

  call sect('convergence')
  call row_i('convergence/iterations_n', t4%convergence%iterations_n, t3%convergence%iterations_n)
  call row_d('convergence/grad_shafranov_deviation_value', t4%convergence%grad_shafranov_deviation_value, t3%convergence%grad_shafranov_deviation_value)

  write(*, '(a)') ''
  write(*, '(a)') repeat('=', 100)
  write(*, '(a)') 'end of table'

  call ids_deallocate(e4)
  call ids_deallocate(e3)

contains

  ! The eight ggd scalar quantities differ only in which component they read, and
  ! Fortran has no way to name a component indirectly -- hence the selector.
  subroutine ggd_row(path, which)
    character(len=*), intent(in) :: path
    integer, intent(in) :: which
    real(ids_real), pointer :: v4(:), v3(:)

    v4 => null()
    v3 => null()
    select case (which)
    case (1)
      if (associated(t4%ggd(1)%psi)) v4 => t4%ggd(1)%psi(1)%values
      if (associated(t3%ggd(1)%psi)) v3 => t3%ggd(1)%psi(1)%values
    case (2)
      if (associated(t4%ggd(1)%phi)) v4 => t4%ggd(1)%phi(1)%values
      if (associated(t3%ggd(1)%phi)) v3 => t3%ggd(1)%phi(1)%values
    case (3)
      if (associated(t4%ggd(1)%theta)) v4 => t4%ggd(1)%theta(1)%values
      if (associated(t3%ggd(1)%theta)) v3 => t3%ggd(1)%theta(1)%values
    case (4)
      if (associated(t4%ggd(1)%j_phi)) v4 => t4%ggd(1)%j_phi(1)%values
      if (associated(t3%ggd(1)%j_phi)) v3 => t3%ggd(1)%j_phi(1)%values
    case (5)
      if (associated(t4%ggd(1)%j_parallel)) v4 => t4%ggd(1)%j_parallel(1)%values
      if (associated(t3%ggd(1)%j_parallel)) v3 => t3%ggd(1)%j_parallel(1)%values
    case (6)
      if (associated(t4%ggd(1)%b_field_r)) v4 => t4%ggd(1)%b_field_r(1)%values
      if (associated(t3%ggd(1)%b_field_r)) v3 => t3%ggd(1)%b_field_r(1)%values
    case (7)
      if (associated(t4%ggd(1)%b_field_phi)) v4 => t4%ggd(1)%b_field_phi(1)%values
      if (associated(t3%ggd(1)%b_field_phi)) v3 => t3%ggd(1)%b_field_phi(1)%values
    case (8)
      if (associated(t4%ggd(1)%b_field_z)) v4 => t4%ggd(1)%b_field_z(1)%values
      if (associated(t3%ggd(1)%b_field_z)) v3 => t3%ggd(1)%b_field_z(1)%values
    end select
    call row_d1(path, v4, v3)
  end subroutine

end program play_eq_two_dd
