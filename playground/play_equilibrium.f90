program play_equilibrium
  ! Read the checked-in equilibrium fixture pair (imas-python-fixtures/) and print every
  ! field equilibrium_seed.py writes, for both DD versions, so the two can be compared by
  ! eye to check the read-path middleware's conversion.
  !
  ! FIXTURE_DD4 is this build's own DD version, read natively - no conversion involved.
  ! FIXTURE_DD3 is the older DD 3.39.0 fixture, read through the Rust read-path middleware
  ! (middleware/) with IMAS_MW_CONVERT armed. Both reads happen in this one process: the
  ! middleware decides *per entry*, from ids_properties/version_put/data_dictionary,
  ! whether a given read actually needs the map applied (middleware/src/lib.rs,
  ! opened_root/entry_needs_conversion) - so arming the switch up front does not touch the
  ! native DD 4.1.1 read at all, and only the DD 3.39.0 read is actually converted. Without
  ! that per-entry check, arming the switch for one read would corrupt the other by
  ! reapplying the map's 32 COCOS sign flips to data that never needed them.
  !
  ! The two dumps below use identical labels in identical order, so the two blocks of
  ! output can be diffed directly; where they disagree is either a documented lossy
  ! conversion (see dd-maps/equilibrium/3.39.0--4.1.1.xml and the conversion report this
  ! program prints at the end) or a bug.
  !
  ! Run from this directory:
  !   ./bin/play_equilibrium
  use ids_routines
  use iso_c_binding
  implicit none

  character(*), parameter :: FIXTURE_DD4 = '../imas-python-fixtures/fixtures/dd-4.1.1'
  character(*), parameter :: FIXTURE_DD3 = '../imas-python-fixtures/fixtures/dd-3.39.0'

  interface
     subroutine imas_mw_conversion_report() bind(C, name="imas_mw_conversion_report")
     end subroutine imas_mw_conversion_report

     function setenv(name, value, overwrite) bind(C, name="setenv")
       use, intrinsic :: iso_c_binding
       character(C_CHAR), dimension(*), intent(in) :: name, value
       integer(C_INT), value, intent(in) :: overwrite
       integer(C_INT) :: setenv
     end function setenv
  end interface

  integer(C_INT) :: ignored
  type(ids_equilibrium) :: eq4, eq3

  ! Armed before the first read: the middleware's "is conversion on at all" switch is read
  ! once via a OnceLock (convert::enabled), so setting it later would be too late. Which
  ! *entries* it actually touches is decided separately, per open, by entry_needs_conversion.
  ignored = setenv('IMAS_MW_CONVERT'//C_NULL_CHAR, '3.39.0'//C_NULL_CHAR, 0_C_INT)

  print *, 'DD version of this al-fortran build: ', trim(al_dd_version)

  call read_entry(FIXTURE_DD4, eq4)
  call read_entry(FIXTURE_DD3, eq3)

  call dump('DD 4.1.1 (native, ground truth)', eq4)
  call dump('DD 3.39.0 (through the middleware, should match)', eq3)

  call ids_deallocate(eq4)
  call ids_deallocate(eq3)

  print *
  call imas_mw_conversion_report()

  print *
  print *, 'Done.'

contains

  subroutine read_entry(fixture, eq)
    character(*), intent(in) :: fixture
    type(ids_equilibrium), intent(inout) :: eq
    integer :: idx, status
    character(:), allocatable :: retmsg

    call imas_open('imas:hdf5?path='//fixture, OPEN_PULSE, idx, status, retmsg)
    if (status /= 0) then
       print *, 'imas_open failed for ', fixture, ': ', retmsg
       stop 1
    end if
    call ids_get(idx, 'equilibrium', eq, status)
    if (status /= 0) then
       print *, 'ids_get failed for ', fixture, ', status = ', status
       call imas_close(idx)
       stop 1
    end if
    call imas_close(idx)
  end subroutine read_entry

  ! ------------------------------------------------------------------ generic printers

  ! Array components of a generated IDS type are pointers, not allocatables, so a field
  ! that was not read (or, unconverted, a renamed DD3 field with no DD4 spelling) is a
  ! null pointer rather than an empty array.
  subroutine show(label, values)
    character(*), intent(in) :: label
    real(ids_real), dimension(:), pointer, intent(in) :: values
    if (associated(values)) then
       print *, '  '//label//': ', values
    else
       print *, '  '//label//': (not read)'
    end if
  end subroutine show

  subroutine show2d(label, values)
    character(*), intent(in) :: label
    real(ids_real), dimension(:,:), pointer, intent(in) :: values
    if (associated(values)) then
       print *, '  '//label//': ', values
    else
       print *, '  '//label//': (not read)'
    end if
  end subroutine show2d

  ! The two coordinate_system tensors are 4D and large; a shape is enough to confirm the
  ! read happened without dumping a wall of numbers.
  subroutine show4_shape(label, values)
    character(*), intent(in) :: label
    real(ids_real), dimension(:,:,:,:), pointer, intent(in) :: values
    if (associated(values)) then
       print *, '  '//label//' shape: ', shape(values)
    else
       print *, '  '//label//': (not read)'
    end if
  end subroutine show4_shape

  subroutine showint(label, values)
    character(*), intent(in) :: label
    integer(ids_int), dimension(:), pointer, intent(in) :: values
    if (associated(values)) then
       print *, '  '//label//': ', values
    else
       print *, '  '//label//': (not read)'
    end if
  end subroutine showint

  ! DD strings are STR_0D-as-array-of-one: a scalar string is a pointer array of length 1.
  function strval(x) result(s)
    character(len=*), dimension(:), pointer, intent(in) :: x
    character(:), allocatable :: s
    if (associated(x)) then
       if (size(x) >= 1) then
          s = trim(x(1))
          return
       end if
    end if
    s = '(not read)'
  end function strval

  ! Identifier structures (name/index/description) recur under several distinct derived
  ! types with the same three fields; passed as individual arguments rather than the
  ! whole struct, this works for any of them.
  subroutine show_identifier(label, name, idx, descr)
    character(*), intent(in) :: label
    character(len=*), dimension(:), pointer, intent(in) :: name, descr
    integer(ids_int), intent(in) :: idx
    print *, '  '//label//' name/index/description: ', strval(name), idx, strval(descr)
  end subroutine show_identifier

  ! ------------------------------------------------------------- constraint 0D printers
  ! ids_equilibrium_constraints_0D*_v4_1_1 all carry the same seven fields under distinct
  ! type names, so each needs its own subroutine rather than one generic one.

  subroutine show_0d(label, node)
    character(*), intent(in) :: label
    type(ids_equilibrium_constraints_0D_v4_1_1), intent(in) :: node
    print *, '  '//label//' measured/reconstructed/chi_squared: ', &
         node%measured, node%reconstructed, node%chi_squared
  end subroutine show_0d

  subroutine show_0d_ip(label, node)
    character(*), intent(in) :: label
    type(ids_equilibrium_constraints_0D_ip_like_v4_1_1), intent(in) :: node
    print *, '  '//label//' measured/reconstructed/chi_squared: ', &
         node%measured, node%reconstructed, node%chi_squared
  end subroutine show_0d_ip

  subroutine show_0d_one(label, node)
    character(*), intent(in) :: label
    type(ids_equilibrium_constraints_0D_one_like_v4_1_1), intent(in) :: node
    print *, '  '//label//' measured/reconstructed/chi_squared: ', &
         node%measured, node%reconstructed, node%chi_squared
  end subroutine show_0d_one

  subroutine show_0d_b0(label, node)
    character(*), intent(in) :: label
    type(ids_equilibrium_constraints_0D_b0_like_v4_1_1), intent(in) :: node
    print *, '  '//label//' measured/reconstructed/chi_squared: ', &
         node%measured, node%reconstructed, node%chi_squared
  end subroutine show_0d_b0

  subroutine show_position(label, node)
    character(*), intent(in) :: label
    type(ids_equilibrium_constraints_0D_position_v4_1_1), intent(in) :: node
    print *, '  '//label//' measured/reconstructed/chi_squared: ', &
         node%measured, node%reconstructed, node%chi_squared
    print *, '  '//label//' position r/phi/z/rho_tor_norm/psi: ', &
         node%position%r, node%position%phi, node%position%z, &
         node%position%rho_tor_norm, node%position%psi
  end subroutine show_position

  subroutine show_pure_position(label, node)
    character(*), intent(in) :: label
    type(ids_equilibrium_constraints_pure_position_v4_1_1), intent(in) :: node
    print *, '  '//label//' position_measured r/z     : ', &
         node%position_measured%r, node%position_measured%z
    print *, '  '//label//' position_reconstructed r/z: ', &
         node%position_reconstructed%r, node%position_reconstructed%z
    print *, '  '//label//' chi_squared_r/chi_squared_z: ', &
         node%chi_squared_r, node%chi_squared_z
  end subroutine show_pure_position

  ! ------------------------------------------------------------------- ggd grid printer

  subroutine show_grid_scalar(label, q)
    character(*), intent(in) :: label
    type(ids_generic_grid_scalar_v4_1_1), dimension(:), pointer, intent(in) :: q
    if (associated(q)) then
       call show(label//'(1)%values', q(1)%values)
    else
       print *, '  '//label//': (empty)'
    end if
  end subroutine show_grid_scalar

  ! -------------------------------------------------------------------------- sections

  subroutine dump_ids_properties(ip)
    type(ids_ids_properties_v4_1_1), intent(in) :: ip
    print *, '  ids_properties%comment         : ', strval(ip%comment)
    print *, '  ids_properties%name            : ', strval(ip%name)
    print *, '  ids_properties%homogeneous_time: ', ip%homogeneous_time
    call show_identifier('ids_properties%occurrence_type', ip%occurrence_type%name, &
         ip%occurrence_type%index, ip%occurrence_type%description)
    print *, '  ids_properties%provider        : ', strval(ip%provider)
    print *, '  ids_properties%creation_date   : ', strval(ip%creation_date)
    print *, '  ids_properties%version_put%data_dictionary      : ', &
         strval(ip%version_put%data_dictionary)
    print *, '  ids_properties%version_put%access_layer         : ', &
         strval(ip%version_put%access_layer)
    print *, '  ids_properties%version_put%access_layer_language: ', &
         strval(ip%version_put%access_layer_language)
    if (associated(ip%provenance%node)) then
       print *, '  ids_properties%provenance%node: n=', size(ip%provenance%node)
       print *, '    node(1)%path: ', strval(ip%provenance%node(1)%path)
       if (associated(ip%provenance%node(1)%reference)) then
          print *, '    node(1)%reference(1)%name     : ', &
               strval(ip%provenance%node(1)%reference(1)%name)
          print *, '    node(1)%reference(1)%timestamp: ', &
               strval(ip%provenance%node(1)%reference(1)%timestamp)
       end if
    else
       print *, '  ids_properties%provenance%node: (empty)'
    end if
    if (associated(ip%plugins%node)) then
       print *, '  ids_properties%plugins%node: n=', size(ip%plugins%node)
       print *, '    node(1)%path: ', strval(ip%plugins%node(1)%path)
       if (associated(ip%plugins%node(1)%put_operation)) &
            print *, '    node(1)%put_operation(1)%name: ', &
            strval(ip%plugins%node(1)%put_operation(1)%name)
    else
       print *, '  ids_properties%plugins%node: (empty)'
    end if
    print *, '  ids_properties%plugins%infrastructure_put%name: ', &
         strval(ip%plugins%infrastructure_put%name)
    print *, '  ids_properties%plugins%infrastructure_get%name: ', &
         strval(ip%plugins%infrastructure_get%name)
  end subroutine dump_ids_properties

  subroutine dump_code(label, c)
    character(*), intent(in) :: label
    type(ids_code_v4_1_1), intent(in) :: c
    print *, '  '//label//'%name       : ', strval(c%name)
    print *, '  '//label//'%description: ', strval(c%description)
    print *, '  '//label//'%commit     : ', strval(c%commit)
    print *, '  '//label//'%version    : ', strval(c%version)
    print *, '  '//label//'%repository : ', strval(c%repository)
    print *, '  '//label//'%parameters : ', strval(c%parameters)
    call showint(label//'%output_flag', c%output_flag)
    if (associated(c%library)) then
       print *, '  '//label//'%library: n=', size(c%library)
       print *, '    library(1)%name: ', strval(c%library(1)%name)
    else
       print *, '  '//label//'%library: (empty)'
    end if
  end subroutine dump_code

  subroutine dump_grids_ggd(gg)
    type(ids_equilibrium_ggd_array_v4_1_1), dimension(:), pointer, intent(in) :: gg
    if (.not. associated(gg)) then
       print *, 'grids_ggd: (empty)'
       return
    end if
    print *, 'grids_ggd: n=', size(gg)
    print *, '  grids_ggd(1)%time: ', gg(1)%time
    if (associated(gg(1)%grid)) then
       print *, '  grids_ggd(1)%grid: n=', size(gg(1)%grid)
       call show_identifier('grids_ggd(1)%grid(1)%identifier', gg(1)%grid(1)%identifier%name, &
            gg(1)%grid(1)%identifier%index, gg(1)%grid(1)%identifier%description)
       print *, '  grids_ggd(1)%grid(1)%path: ', strval(gg(1)%grid(1)%path)
       if (associated(gg(1)%grid(1)%space)) &
            print *, '  grids_ggd(1)%grid(1)%space: n=', size(gg(1)%grid(1)%space)
       if (associated(gg(1)%grid(1)%grid_subset)) &
            print *, '  grids_ggd(1)%grid(1)%grid_subset: n=', size(gg(1)%grid(1)%grid_subset)
    end if
  end subroutine dump_grids_ggd

  subroutine dump_boundary(b)
    type(ids_equilibrium_boundary_v4_1_1), intent(in) :: b
    integer :: k
    print *, '  boundary%type                   : ', b%type
    call show('boundary%outline%r              ', b%outline%r)
    call show('boundary%outline%z              ', b%outline%z)
    print *, '  boundary%psi_norm               : ', b%psi_norm
    print *, '  boundary%psi                    : ', b%psi
    print *, '  boundary%geometric_axis r/z     : ', b%geometric_axis%r, b%geometric_axis%z
    print *, '  boundary%minor_radius           : ', b%minor_radius
    print *, '  boundary%elongation             : ', b%elongation
    print *, '  boundary%triangularity          : ', b%triangularity
    print *, '  boundary%triangularity_upper    : ', b%triangularity_upper
    print *, '  boundary%triangularity_lower    : ', b%triangularity_lower
    print *, '  boundary%squareness_upper_inner : ', b%squareness_upper_inner
    print *, '  boundary%squareness_upper_outer : ', b%squareness_upper_outer
    print *, '  boundary%squareness_lower_inner : ', b%squareness_lower_inner
    print *, '  boundary%squareness_lower_outer : ', b%squareness_lower_outer
    print *, '  boundary%closest_wall_point r/z/distance: ', &
         b%closest_wall_point%r, b%closest_wall_point%z, b%closest_wall_point%distance
    print *, '  boundary%dr_dz_zero_point r/z   : ', b%dr_dz_zero_point%r, b%dr_dz_zero_point%z
    if (associated(b%gap)) then
       print *, '  boundary%gap: n=', size(b%gap)
       do k = 1, size(b%gap)
          print *, '    gap(', k, ') name/r/z/angle/value: ', trim(strval(b%gap(k)%name)), &
               b%gap(k)%r, b%gap(k)%z, b%gap(k)%angle, b%gap(k)%value
       end do
    else
       print *, '  boundary%gap: (empty)'
    end if
    print *, '  boundary%rho_tor                : ', b%rho_tor
    print *, '  boundary%phi                    : ', b%phi
    print *, '  boundary%phi_poloidal_current   : ', b%phi_poloidal_current
  end subroutine dump_boundary

  subroutine dump_contour_tree(ct)
    type(ids_equilibrium_contour_tree_v4_1_1), intent(in) :: ct
    integer :: k
    if (associated(ct%node)) then
       print *, '  contour_tree%node: n=', size(ct%node)
       do k = 1, size(ct%node)
          print *, '    node(', k, ') critical_type/r/z/psi: ', ct%node(k)%critical_type, &
               ct%node(k)%r, ct%node(k)%z, ct%node(k)%psi
       end do
    else
       print *, '  contour_tree%node: (empty)'
    end if
    if (associated(ct%edges)) then
       print *, '  contour_tree%edges shape: ', shape(ct%edges)
    else
       print *, '  contour_tree%edges: (empty)'
    end if
  end subroutine dump_contour_tree

  subroutine dump_constraints(c)
    type(ids_equilibrium_constraints_v4_1_1), intent(in) :: c
    call show_0d('constraints%b_field_tor_vacuum_r', c%b_field_tor_vacuum_r)
    call show_0d_ip('constraints%ip', c%ip)
    call show_0d_b0('constraints%diamagnetic_flux', c%diamagnetic_flux)

    if (associated(c%b_field_pol_probe)) then
       print *, '  constraints%b_field_pol_probe: n=', size(c%b_field_pol_probe)
       call show_0d_one('constraints%b_field_pol_probe(1)', c%b_field_pol_probe(1))
    else
       print *, '  constraints%b_field_pol_probe: (empty)'
    end if

    if (associated(c%faraday_angle)) then
       print *, '  constraints%faraday_angle: n=', size(c%faraday_angle)
       call show_0d('constraints%faraday_angle(1)', c%faraday_angle(1))
    else
       print *, '  constraints%faraday_angle: (empty)'
    end if

    if (associated(c%mse_polarization_angle)) then
       print *, '  constraints%mse_polarization_angle: n=', size(c%mse_polarization_angle)
       call show_0d('constraints%mse_polarization_angle(1)', c%mse_polarization_angle(1))
    else
       print *, '  constraints%mse_polarization_angle: (empty)'
    end if

    if (associated(c%flux_loop)) then
       print *, '  constraints%flux_loop: n=', size(c%flux_loop)
       call show_0d('constraints%flux_loop(1)', c%flux_loop(1))
    else
       print *, '  constraints%flux_loop: (empty)'
    end if

    if (associated(c%n_e_line)) then
       print *, '  constraints%n_e_line: n=', size(c%n_e_line)
       call show_0d('constraints%n_e_line(1)', c%n_e_line(1))
    else
       print *, '  constraints%n_e_line: (empty)'
    end if

    if (associated(c%pf_current)) then
       print *, '  constraints%pf_current: n=', size(c%pf_current)
       call show_0d_ip('constraints%pf_current(1)', c%pf_current(1))
    else
       print *, '  constraints%pf_current: (empty)'
    end if

    if (associated(c%pf_passive_current)) then
       print *, '  constraints%pf_passive_current: n=', size(c%pf_passive_current)
       call show_0d('constraints%pf_passive_current(1)', c%pf_passive_current(1))
    else
       print *, '  constraints%pf_passive_current: (empty)'
    end if

    if (associated(c%n_e)) then
       print *, '  constraints%n_e: n=', size(c%n_e)
       call show_position('constraints%n_e(1)', c%n_e(1))
    else
       print *, '  constraints%n_e: (empty)'
    end if

    if (associated(c%pressure)) then
       print *, '  constraints%pressure: n=', size(c%pressure)
       call show_position('constraints%pressure(1)', c%pressure(1))
    else
       print *, '  constraints%pressure: (empty)'
    end if

    if (associated(c%pressure_rotational)) then
       print *, '  constraints%pressure_rotational: n=', size(c%pressure_rotational)
       call show_position('constraints%pressure_rotational(1)', c%pressure_rotational(1))
    else
       print *, '  constraints%pressure_rotational: (empty)'
    end if

    if (associated(c%q)) then
       print *, '  constraints%q: n=', size(c%q)
       call show_position('constraints%q(1)', c%q(1))
    else
       print *, '  constraints%q: (empty)'
    end if

    if (associated(c%j_phi)) then
       print *, '  constraints%j_phi: n=', size(c%j_phi)
       call show_position('constraints%j_phi(1)', c%j_phi(1))
    else
       print *, '  constraints%j_phi: (empty)'
    end if

    if (associated(c%j_parallel)) then
       print *, '  constraints%j_parallel: n=', size(c%j_parallel)
       call show_position('constraints%j_parallel(1)', c%j_parallel(1))
    else
       print *, '  constraints%j_parallel: (empty)'
    end if

    if (associated(c%iron_core_segment)) then
       print *, '  constraints%iron_core_segment: n=', size(c%iron_core_segment)
       call show_0d('constraints%iron_core_segment(1)%magnetization_r', &
            c%iron_core_segment(1)%magnetization_r)
       call show_0d('constraints%iron_core_segment(1)%magnetization_z', &
            c%iron_core_segment(1)%magnetization_z)
    else
       print *, '  constraints%iron_core_segment: (empty)'
    end if

    if (associated(c%x_point)) then
       print *, '  constraints%x_point: n=', size(c%x_point)
       call show_pure_position('constraints%x_point(1)', c%x_point(1))
    else
       print *, '  constraints%x_point: (empty)'
    end if

    if (associated(c%strike_point)) then
       print *, '  constraints%strike_point: n=', size(c%strike_point)
       call show_pure_position('constraints%strike_point(1)', c%strike_point(1))
    else
       print *, '  constraints%strike_point: (empty)'
    end if

    print *, '  constraints%chi_squared_reduced: ', c%chi_squared_reduced
    print *, '  constraints%freedom_degrees_n  : ', c%freedom_degrees_n
    print *, '  constraints%constraints_n      : ', c%constraints_n
  end subroutine dump_constraints

  subroutine dump_global_quantities(g)
    type(ids_equlibrium_global_quantities_v4_1_1), intent(in) :: g
    print *, '  gq%beta_pol             : ', g%beta_pol
    print *, '  gq%beta_tor             : ', g%beta_tor
    print *, '  gq%beta_tor_norm        : ', g%beta_tor_norm
    print *, '  gq%ip                   : ', g%ip
    print *, '  gq%li_3                 : ', g%li_3
    print *, '  gq%volume               : ', g%volume
    print *, '  gq%area                 : ', g%area
    print *, '  gq%surface              : ', g%surface
    print *, '  gq%length_pol           : ', g%length_pol
    print *, '  gq%psi_axis             : ', g%psi_axis
    print *, '  gq%psi_magnetic_axis    : ', g%psi_magnetic_axis
    print *, '  gq%psi_boundary         : ', g%psi_boundary
    print *, '  gq%rho_tor_boundary     : ', g%rho_tor_boundary
    print *, '  gq%magnetic_axis r/z/b_field_phi: ', &
         g%magnetic_axis%r, g%magnetic_axis%z, g%magnetic_axis%b_field_phi
    print *, '  gq%current_centre r/z/velocity_z: ', &
         g%current_centre%r, g%current_centre%z, g%current_centre%velocity_z
    print *, '  gq%q_axis               : ', g%q_axis
    print *, '  gq%q_95                 : ', g%q_95
    print *, '  gq%q_min value/rho_tor_norm/psi_norm/psi: ', &
         g%q_min%value, g%q_min%rho_tor_norm, g%q_min%psi_norm, g%q_min%psi
    print *, '  gq%energy_mhd           : ', g%energy_mhd
    print *, '  gq%psi_external_average : ', g%psi_external_average
    print *, '  gq%v_external           : ', g%v_external
    print *, '  gq%plasma_inductance    : ', g%plasma_inductance
    print *, '  gq%plasma_resistance    : ', g%plasma_resistance
  end subroutine dump_global_quantities

  subroutine dump_profiles_1d(p)
    type(ids_equilibrium_profiles_1d_v4_1_1), intent(in) :: p
    call show('profiles_1d%psi                  ', p%psi)
    call show('profiles_1d%psi_norm             ', p%psi_norm)
    call show('profiles_1d%phi                  ', p%phi)
    call show('profiles_1d%pressure             ', p%pressure)
    call show('profiles_1d%f                    ', p%f)
    call show('profiles_1d%dpressure_dpsi       ', p%dpressure_dpsi)
    call show('profiles_1d%f_df_dpsi            ', p%f_df_dpsi)
    call show('profiles_1d%j_phi                ', p%j_phi)
    call show('profiles_1d%j_parallel           ', p%j_parallel)
    call show('profiles_1d%q                    ', p%q)
    call show('profiles_1d%magnetic_shear       ', p%magnetic_shear)
    call show('profiles_1d%r_inboard            ', p%r_inboard)
    call show('profiles_1d%r_outboard           ', p%r_outboard)
    call show('profiles_1d%rho_tor              ', p%rho_tor)
    call show('profiles_1d%rho_tor_norm         ', p%rho_tor_norm)
    call show('profiles_1d%dpsi_drho_tor        ', p%dpsi_drho_tor)
    print *, '  profiles_1d%geometric_axis r/z  : ', p%geometric_axis%r, p%geometric_axis%z
    call show('profiles_1d%elongation           ', p%elongation)
    call show('profiles_1d%triangularity_upper  ', p%triangularity_upper)
    call show('profiles_1d%triangularity_lower  ', p%triangularity_lower)
    call show('profiles_1d%squareness_upper_inner', p%squareness_upper_inner)
    call show('profiles_1d%squareness_upper_outer', p%squareness_upper_outer)
    call show('profiles_1d%squareness_lower_inner', p%squareness_lower_inner)
    call show('profiles_1d%squareness_lower_outer', p%squareness_lower_outer)
    call show('profiles_1d%volume               ', p%volume)
    call show('profiles_1d%rho_volume_norm      ', p%rho_volume_norm)
    call show('profiles_1d%dvolume_dpsi         ', p%dvolume_dpsi)
    call show('profiles_1d%dvolume_drho_tor     ', p%dvolume_drho_tor)
    call show('profiles_1d%area                 ', p%area)
    call show('profiles_1d%darea_dpsi           ', p%darea_dpsi)
    call show('profiles_1d%darea_drho_tor       ', p%darea_drho_tor)
    call show('profiles_1d%surface              ', p%surface)
    call show('profiles_1d%trapped_fraction     ', p%trapped_fraction)
    call show('profiles_1d%gm1                  ', p%gm1)
    call show('profiles_1d%gm2                  ', p%gm2)
    call show('profiles_1d%gm3                  ', p%gm3)
    call show('profiles_1d%gm4                  ', p%gm4)
    call show('profiles_1d%gm5                  ', p%gm5)
    call show('profiles_1d%gm6                  ', p%gm6)
    call show('profiles_1d%gm7                  ', p%gm7)
    call show('profiles_1d%gm8                  ', p%gm8)
    call show('profiles_1d%gm9                  ', p%gm9)
    call show('profiles_1d%b_field_average      ', p%b_field_average)
    call show('profiles_1d%b_field_min          ', p%b_field_min)
    call show('profiles_1d%b_field_max          ', p%b_field_max)
    call show('profiles_1d%beta_pol             ', p%beta_pol)
    call show('profiles_1d%mass_density         ', p%mass_density)
  end subroutine dump_profiles_1d

  subroutine dump_profiles_2d(p)
    type(ids_equilibrium_profiles_2d_v4_1_1), intent(in) :: p
    call show_identifier('profiles_2d%type', p%type%name, p%type%index, p%type%description)
    call show_identifier('profiles_2d%grid_type', p%grid_type%name, p%grid_type%index, &
         p%grid_type%description)
    call show('profiles_2d%grid%dim1            ', p%grid%dim1)
    call show('profiles_2d%grid%dim2            ', p%grid%dim2)
    call show2d('profiles_2d%grid%volume_element  ', p%grid%volume_element)
    call show2d('profiles_2d%r                    ', p%r)
    call show2d('profiles_2d%z                    ', p%z)
    call show2d('profiles_2d%psi                  ', p%psi)
    call show2d('profiles_2d%theta                ', p%theta)
    call show2d('profiles_2d%phi                  ', p%phi)
    call show2d('profiles_2d%j_phi                ', p%j_phi)
    call show2d('profiles_2d%j_parallel           ', p%j_parallel)
    call show2d('profiles_2d%b_field_r            ', p%b_field_r)
    call show2d('profiles_2d%b_field_phi          ', p%b_field_phi)
    call show2d('profiles_2d%b_field_z            ', p%b_field_z)
  end subroutine dump_profiles_2d

  subroutine dump_ggd(ggd_arr)
    type(ids_equilibrium_ggd_v4_1_1), dimension(:), pointer, intent(in) :: ggd_arr
    if (.not. associated(ggd_arr)) then
       print *, '  ggd: (empty)'
       return
    end if
    print *, '  ggd: n=', size(ggd_arr)
    call show_grid_scalar('ggd(1)%r          ', ggd_arr(1)%r)
    call show_grid_scalar('ggd(1)%z          ', ggd_arr(1)%z)
    call show_grid_scalar('ggd(1)%psi        ', ggd_arr(1)%psi)
    call show_grid_scalar('ggd(1)%phi        ', ggd_arr(1)%phi)
    call show_grid_scalar('ggd(1)%theta      ', ggd_arr(1)%theta)
    call show_grid_scalar('ggd(1)%j_phi      ', ggd_arr(1)%j_phi)
    call show_grid_scalar('ggd(1)%j_parallel ', ggd_arr(1)%j_parallel)
    call show_grid_scalar('ggd(1)%b_field_r  ', ggd_arr(1)%b_field_r)
    call show_grid_scalar('ggd(1)%b_field_z  ', ggd_arr(1)%b_field_z)
    call show_grid_scalar('ggd(1)%b_field_phi', ggd_arr(1)%b_field_phi)
  end subroutine dump_ggd

  subroutine dump_coordinate_system(cs)
    type(ids_equilibrium_coordinate_system_v4_1_1), intent(in) :: cs
    call show_identifier('coordinate_system%grid_type', cs%grid_type%name, &
         cs%grid_type%index, cs%grid_type%description)
    call show('coordinate_system%grid%dim1      ', cs%grid%dim1)
    call show('coordinate_system%grid%dim2      ', cs%grid%dim2)
    call show2d('coordinate_system%grid%volume_element', cs%grid%volume_element)
    call show2d('coordinate_system%r               ', cs%r)
    call show2d('coordinate_system%z               ', cs%z)
    call show2d('coordinate_system%jacobian        ', cs%jacobian)
    call show4_shape('coordinate_system%tensor_covariant', cs%tensor_covariant)
    call show4_shape('coordinate_system%tensor_contravariant', cs%tensor_contravariant)
  end subroutine dump_coordinate_system

  subroutine dump_convergence(cv)
    type(ids_equilibrium_convergence_v4_1_1), intent(in) :: cv
    print *, '  convergence%iterations_n: ', cv%iterations_n
    call show_identifier('convergence%grad_shafranov_deviation_expression', &
         cv%grad_shafranov_deviation_expression%name, &
         cv%grad_shafranov_deviation_expression%index, &
         cv%grad_shafranov_deviation_expression%description)
    print *, '  convergence%grad_shafranov_deviation_value: ', cv%grad_shafranov_deviation_value
    call show_identifier('convergence%result', cv%result%name, cv%result%index, &
         cv%result%description)
  end subroutine dump_convergence

  ! ------------------------------------------------------------------------- the dump

  subroutine dump(label, eq)
    character(*), intent(in) :: label
    type(ids_equilibrium), intent(in) :: eq
    integer :: i

    print *
    print *, '================ '//label//' ================'

    call dump_ids_properties(eq%ids_properties)
    print *, 'vacuum_toroidal_field%r0: ', eq%vacuum_toroidal_field%r0
    call show('vacuum_toroidal_field%b0    ', eq%vacuum_toroidal_field%b0)
    call show('time                        ', eq%time)
    call dump_grids_ggd(eq%grids_ggd)
    call dump_code('code', eq%code)

    if (.not. associated(eq%time_slice)) then
       print *, 'time_slice: (empty) - nothing more to print'
       return
    end if

    do i = 1, size(eq%time_slice)
       print *, '--- time_slice(', i, ') t=', eq%time_slice(i)%time, ' ---'
       call dump_boundary(eq%time_slice(i)%boundary)
       call dump_contour_tree(eq%time_slice(i)%contour_tree)
       call dump_constraints(eq%time_slice(i)%constraints)
       call dump_global_quantities(eq%time_slice(i)%global_quantities)
       call dump_profiles_1d(eq%time_slice(i)%profiles_1d)
       if (associated(eq%time_slice(i)%profiles_2d)) then
          print *, '  profiles_2d: n=', size(eq%time_slice(i)%profiles_2d)
          call dump_profiles_2d(eq%time_slice(i)%profiles_2d(1))
       else
          print *, '  profiles_2d: (empty)'
       end if
       call dump_ggd(eq%time_slice(i)%ggd)
       call dump_coordinate_system(eq%time_slice(i)%coordinate_system)
       call dump_convergence(eq%time_slice(i)%convergence)
    end do
  end subroutine dump

end program play_equilibrium
