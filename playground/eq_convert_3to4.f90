! equilibrium, DD 3.39.0 -> DD 4.1.1: the forward direction of
! dd-maps/equilibrium/3.39.0--4.1.1.xml, executed by hand.
!
! Every rule in that map has a counterpart here, tagged with the rule id in a
! comment, so the two can be diffed by eye. The map's three axes map onto the
! code like this:
!
!   rel="identical"   -> a plain assignment / cp* call
!   rel="renamed"     -> assignment across differently spelled fields
!   rel="moved"       -> assignment across differently placed fields
!   rel="merged"      -> mg*/pick*, first populated source by precedence
!   rel="split"       -> one source assigned to two destinations
!   rel="retyped"     -> the int_1d -> struct_array(index) reshape
!   rel="left_only"   -> nothing written; the value is dropped
!   rel="right_only"  -> nothing written; there is no DD3 source
!   <cocos><flip>     -> the FLIP factor on the copy
!   <redefine>        -> refused outright, and logged
!
! fidelity is the notification channel the map's README describes: anything
! other than exact is counted in the log, and unmappable is refused rather than
! guessed. Read the log to see what a conversion cost.
!
! Not covered, because the map does not cover it: ids_properties and code are
! filtered out of the map's inventories, so their handling here is this file's
! own (see conv_ids_properties).
module eq_convert_3_39_0_to_4_1_1

    use ids_routines_v4_1_1
    use ids_routines_v3_39_0

    implicit none
    private

    public :: convert_v3_to_v4, conversion_log, log_report

    ! COCOS 11 -> 17. Multiplying by -1 flips only the IEEE-754 sign bit, so the
    ! transform is exactly invertible and needs no direction-specific handling.
    real(ids_real), parameter :: FLIP = -1.0_ids_real
    real(ids_real), parameter :: KEEP = 1.0_ids_real

    integer, parameter :: LOG_MAX = 64
    integer, parameter :: LOG_WIDTH = 128

    ! What the conversion had to give up. `refused` counts paths the map marks
    ! unmappable, which are skipped rather than guessed; `lossy` counts paths
    ! whose value survived but whose siblings did not. Both count distinct notes,
    ! not calls, so they agree with the list printed by log_report.
    type :: conversion_log
        integer :: refused = 0
        integer :: lossy = 0
        integer :: n = 0
        character(len=LOG_WIDTH) :: line(LOG_MAX) = ''
    end type

contains

    ! ===================================================================== top

    subroutine convert_v3_to_v4(src, dst, log)
        type(ids_equilibrium_v3_39_0), intent(in) :: src
        type(ids_equilibrium_v4_1_1), intent(inout) :: dst
        type(conversion_log), intent(out), optional :: log

        type(conversion_log) :: lg
        integer :: i

        ! left_only err-index / err-upper / err-lower (common/error-model-3to4.xml).
        ! DD4 dropped the per-node error triplet: 630 of equilibrium's 834 removed
        ! paths are this one decision. It is applied by never writing an
        ! *_error_{index,upper,lower} field anywhere below, so it has no code of
        ! its own - which is exactly why it is worth saying out loud.
        call lossy(lg, 'every *_error_{index,upper,lower} dropped: 630 paths, DD4 error model')

        call conv_ids_properties(src%ids_properties, dst%ids_properties, lg)

        ! identical: vacuum_toroidal_field/{r0,b0}. b0 is COCOS b0_like, factor +1.
        dst%vacuum_toroidal_field%r0 = src%vacuum_toroidal_field%r0
        call cp1(src%vacuum_toroidal_field%b0, dst%vacuum_toroidal_field%b0)

        ! identical: time
        call cp1(src%time, dst%time)

        ! identical: grids_ggd (scope grids_ggd, forward=exact), carrying
        ! retype-coordinates-type inside.
        if (associated(src%grids_ggd)) then
            allocate(dst%grids_ggd(size(src%grids_ggd)))
            do i = 1, size(src%grids_ggd)
                call conv_grids_ggd(src%grids_ggd(i), dst%grids_ggd(i), lg)
            end do
        end if

        if (associated(src%time_slice)) then
            allocate(dst%time_slice(size(src%time_slice)))
            do i = 1, size(src%time_slice)
                call conv_time_slice(src%time_slice(i), dst%time_slice(i), lg)
            end do
        end if

        ! code/ is outside the map (filtered from both inventories) and carries
        ! the identity of the program that produced the DD3 data, which is not
        ! the program producing the DD4 data. Deliberately not copied.

        if (present(log)) log = lg
    end subroutine

    ! ids_properties is NOT in the map: the inventories filter the subtree out,
    ! so validate.py's coverage proof says nothing about it. It is not empty of
    ! 3->4 change, though - `source` and `provenance/node/sources` are both gone
    ! in DD 4.1.1 - so the two moves below are this file's own reading, not the
    ! map's. They are the gap that a common/ids-properties-3to4.xml would close.
    subroutine conv_ids_properties(s, d, lg)
        type(ids_ids_properties_v3_39_0), intent(in) :: s
        type(ids_ids_properties_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg
        integer :: i, j, n, k

        call cps(s%comment, d%comment)
        d%homogeneous_time = s%homogeneous_time
        call cps(s%provider, d%provider)
        call cps(s%creation_date, d%creation_date)

        ! version_put is deliberately not copied: it records which dictionary
        ! wrote the data. Carrying DD3's stamp onto a DD4 IDS would produce data
        ! whose stamp lies about its own contents. The put path stamps it.

        ! moved (not in the map): ids_properties/source
        !                      -> ids_properties/provenance/node/reference/name
        n = 0
        if (associated(s%source)) n = n + 1
        if (associated(s%provenance%node)) n = n + size(s%provenance%node)
        if (n > 0) then
            allocate(d%provenance%node(n))
            k = 0
            if (associated(s%source)) then
                k = k + 1
                allocate(d%provenance%node(k)%reference(1))
                call cps(s%source, d%provenance%node(k)%reference(1)%name)
            end if
            if (associated(s%provenance%node)) then
                do i = 1, size(s%provenance%node)
                    k = k + 1
                    call cps(s%provenance%node(i)%path, d%provenance%node(k)%path)
                    ! moved (not in the map): provenance/node/sources
                    !                      -> provenance/node/reference/name
                    if (associated(s%provenance%node(i)%sources)) then
                        allocate(d%provenance%node(k)%reference( &
                                 size(s%provenance%node(i)%sources)))
                        do j = 1, size(s%provenance%node(i)%sources)
                            call set1(d%provenance%node(k)%reference(j)%name, &
                                      s%provenance%node(i)%sources(j))
                        end do
                    end if
                end do
            end if
        end if
        call lossy(lg, 'ids_properties/version_put not carried (DD4 put restamps it)')
    end subroutine

    ! ============================================================== grids_ggd

    subroutine conv_grids_ggd(s, d, lg)
        type(ids_equilibrium_ggd_array_v3_39_0), intent(in) :: s
        type(ids_equilibrium_ggd_array_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg
        integer :: i

        if (associated(s%grid)) then
            allocate(d%grid(size(s%grid)))
            do i = 1, size(s%grid)
                call conv_grid(s%grid(i), d%grid(i), lg)
            end do
        end if
        d%time = s%time
    end subroutine

    subroutine conv_grid(s, d, lg)
        type(ids_generic_grid_dynamic_v3_39_0), intent(in) :: s
        type(ids_generic_grid_dynamic_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg
        integer :: i, j, k

        call conv_identifier(s%identifier, d%identifier)
        call cps(s%path, d%path)

        if (associated(s%space)) then
            allocate(d%space(size(s%space)))
            do i = 1, size(s%space)
                call conv_identifier(s%space(i)%identifier, d%space(i)%identifier)
                call conv_identifier(s%space(i)%geometry_type, d%space(i)%geometry_type)

                ! retype-coordinates-type: DD3 stores a flat INT_1D of coordinate
                ! codes, DD4 an array of identifier structures whose `index` holds
                ! the same integers. Shape only, exact both ways.
                if (associated(s%space(i)%coordinates_type)) then
                    allocate(d%space(i)%coordinates_type(size(s%space(i)%coordinates_type)))
                    do j = 1, size(s%space(i)%coordinates_type)
                        d%space(i)%coordinates_type(j)%index = s%space(i)%coordinates_type(j)
                    end do
                end if

                if (associated(s%space(i)%objects_per_dimension)) then
                    allocate(d%space(i)%objects_per_dimension( &
                             size(s%space(i)%objects_per_dimension)))
                    do j = 1, size(s%space(i)%objects_per_dimension)
                        call conv_identifier( &
                            s%space(i)%objects_per_dimension(j)%geometry_content, &
                            d%space(i)%objects_per_dimension(j)%geometry_content)
                        if (associated(s%space(i)%objects_per_dimension(j)%object)) then
                            allocate(d%space(i)%objects_per_dimension(j)%object( &
                                     size(s%space(i)%objects_per_dimension(j)%object)))
                            do k = 1, size(s%space(i)%objects_per_dimension(j)%object)
                                call conv_object( &
                                    s%space(i)%objects_per_dimension(j)%object(k), &
                                    d%space(i)%objects_per_dimension(j)%object(k))
                            end do
                        end if
                    end do
                end if
            end do
        end if

        if (associated(s%grid_subset)) then
            allocate(d%grid_subset(size(s%grid_subset)))
            do i = 1, size(s%grid_subset)
                call conv_grid_subset(s%grid_subset(i), d%grid_subset(i))
            end do
        end if
    end subroutine

    subroutine conv_object(s, d)
        type(ids_generic_grid_dynamic_space_dimension_object_v3_39_0), intent(in) :: s
        type(ids_generic_grid_dynamic_space_dimension_object_v4_1_1), intent(inout) :: d
        integer :: i

        ! The DD3 type name is truncated by the generator to ..._object__undary;
        ! the DD4 one is not. Same two members either way.
        if (associated(s%boundary)) then
            allocate(d%boundary(size(s%boundary)))
            do i = 1, size(s%boundary)
                d%boundary(i)%index = s%boundary(i)%index
                call cpi1(s%boundary(i)%neighbours, d%boundary(i)%neighbours)
            end do
        end if
        call cp1(s%geometry, d%geometry)
        call cpi1(s%nodes, d%nodes)
        d%measure = s%measure
        call cp2(s%geometry_2d, d%geometry_2d)
    end subroutine

    subroutine conv_grid_subset(s, d)
        type(ids_generic_grid_dynamic_grid_subset_v3_39_0), intent(in) :: s
        type(ids_generic_grid_dynamic_grid_subset_v4_1_1), intent(inout) :: d
        integer :: i, j

        call conv_identifier(s%identifier, d%identifier)
        d%dimension = s%dimension
        if (associated(s%element)) then
            allocate(d%element(size(s%element)))
            do i = 1, size(s%element)
                if (.not. associated(s%element(i)%object)) cycle
                allocate(d%element(i)%object(size(s%element(i)%object)))
                do j = 1, size(s%element(i)%object)
                    d%element(i)%object(j)%space = s%element(i)%object(j)%space
                    d%element(i)%object(j)%dimension = s%element(i)%object(j)%dimension
                    d%element(i)%object(j)%index = s%element(i)%object(j)%index
                end do
            end do
        end if
        if (associated(s%base)) then
            allocate(d%base(size(s%base)))
            do i = 1, size(s%base)
                call conv_metric(s%base(i), d%base(i))
            end do
        end if
        call conv_metric(s%metric, d%metric)
    end subroutine

    subroutine conv_metric(s, d)
        type(ids_generic_grid_dynamic_grid_subset_metric_v3_39_0), intent(in) :: s
        type(ids_generic_grid_dynamic_grid_subset_metric_v4_1_1), intent(inout) :: d
        call cp1(s%jacobian, d%jacobian)
        call cp3(s%tensor_covariant, d%tensor_covariant)
        call cp3(s%tensor_contravariant, d%tensor_contravariant)
    end subroutine

    ! ============================================================= time_slice

    subroutine conv_time_slice(s, d, lg)
        type(ids_equilibrium_time_slice_v3_39_0), intent(in) :: s
        type(ids_equilibrium_time_slice_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg
        integer :: i

        call conv_boundary(s%boundary, s%boundary_separatrix, d%boundary, lg)

        ! left_only drop-boundary-separatrix (decision="yes"): everything under
        ! boundary_separatrix other than the three moved nodes is dropped. The
        ! map flags this for a physicist - DD4's `boundary` may well BE the
        ! separatrix, in which case these values should win over boundary/*.
        call lossy(lg, 'time_slice/boundary_separatrix dropped [DECISION: needs a physicist]')
        ! left_only drop-boundary-secondary-separatrix
        call lossy(lg, 'time_slice/boundary_secondary_separatrix dropped (no DD4 container)')

        ! right_only new-contour-tree: 10 DD4 paths with no DD3 source.
        call refuse(lg, 'time_slice/contour_tree not synthesised (new in DD4)')

        call conv_constraints(s%constraints, d%constraints, lg)
        call conv_global_quantities(s%global_quantities, d%global_quantities, lg)
        call conv_profiles_1d(s%profiles_1d, d%profiles_1d, lg)

        if (associated(s%profiles_2d)) then
            allocate(d%profiles_2d(size(s%profiles_2d)))
            do i = 1, size(s%profiles_2d)
                call conv_profiles_2d(s%profiles_2d(i), d%profiles_2d(i), lg)
            end do
        end if

        if (associated(s%ggd)) then
            allocate(d%ggd(size(s%ggd)))
            do i = 1, size(s%ggd)
                call conv_ggd(s%ggd(i), d%ggd(i), lg)
            end do
        end if

        call conv_coordinate_system(s%coordinate_system, d%coordinate_system, lg)

        ! identical: convergence (scope time_slice/convergence, exact both ways)
        d%convergence%iterations_n = s%convergence%iterations_n
        call conv_identifier(s%convergence%grad_shafranov_deviation_expression, &
                             d%convergence%grad_shafranov_deviation_expression)
        d%convergence%grad_shafranov_deviation_value = &
            s%convergence%grad_shafranov_deviation_value
        ! right_only: convergence/result was added in DD 3.41.0, so it has no
        ! 3.39.0 source. Declared via new-convergence-result.
        call refuse(lg, 'time_slice/convergence/result not synthesised (DD4-only, added in DD 3.41.0)')

        d%time = s%time
    end subroutine

    ! =============================================================== boundary
    !
    ! DD4's `boundary` absorbed three nodes from DD3's `boundary_separatrix`, so
    ! this one routine reads two DD3 structures.

    subroutine conv_boundary(s, sep, d, lg)
        type(ids_equilibrium_boundary_v3_39_0), intent(in) :: s
        type(ids_equilibrium_boundary_separatrix_v3_39_0), intent(in) :: sep
        type(ids_equilibrium_boundary_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg
        integer :: i

        ! identical
        d%type = s%type
        call conv_rz1d(s%outline, d%outline)
        d%psi_norm = s%psi_norm
        ! cocos flip: time_slice/boundary/psi
        d%psi = flipped(s%psi)
        call conv_rz0d(s%geometric_axis, d%geometric_axis)
        d%minor_radius = s%minor_radius
        d%elongation = s%elongation
        d%triangularity = s%triangularity
        d%triangularity_upper = s%triangularity_upper
        d%triangularity_lower = s%triangularity_lower
        d%squareness_upper_inner = s%squareness_upper_inner
        d%squareness_upper_outer = s%squareness_upper_outer
        d%squareness_lower_inner = s%squareness_lower_inner
        d%squareness_lower_outer = s%squareness_lower_outer

        ! moved move-closest-wall-point
        d%closest_wall_point%r = sep%closest_wall_point%r
        d%closest_wall_point%z = sep%closest_wall_point%z
        d%closest_wall_point%distance = sep%closest_wall_point%distance

        ! moved move-dr-dz-zero-point
        call conv_rz0d(sep%dr_dz_zero_point, d%dr_dz_zero_point)

        ! moved move-gap (forward lossy: gap/identifier has no DD4 counterpart)
        if (associated(sep%gap)) then
            allocate(d%gap(size(sep%gap)))
            do i = 1, size(sep%gap)
                call cps(sep%gap(i)%name, d%gap(i)%name)
                d%gap(i)%r = sep%gap(i)%r
                d%gap(i)%z = sep%gap(i)%z
                d%gap(i)%angle = sep%gap(i)%angle
                d%gap(i)%value = sep%gap(i)%value
                ! left_only drop-gap-identifier
            end do
            call lossy(lg, 'boundary/gap/identifier dropped (drop-gap-identifier)')
        end if

        ! left_only, all forward lossy: drop-lcfs, drop-b-flux-pol-norm,
        ! drop-boundary-elongation-upper, drop-boundary-elongation-lower
        call lossy(lg, 'boundary/{lcfs,b_flux_pol_norm,elongation_upper,elongation_lower} dropped')
        ! left_only drop-boundary-x-point, drop-boundary-strike-point,
        ! drop-boundary-active-limiter
        call lossy(lg, 'boundary/{x_point,strike_point,active_limiter_point} dropped')

        ! right_only new-boundary-phi, new-boundary-rho-tor,
        ! new-boundary-phi-poloidal-current
        call refuse(lg, 'boundary/{phi,rho_tor,phi_poloidal_current} not synthesised (new in DD4)')
    end subroutine

    ! ============================================================ constraints

    subroutine conv_constraints(s, d, lg)
        type(ids_equilibrium_constraints_v3_39_0), intent(in) :: s
        type(ids_equilibrium_constraints_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg
        integer :: i

        ! identical
        call conv_c0d(s%b_field_tor_vacuum_r, d%b_field_tor_vacuum_r, KEEP)

        ! renamed rename-bpol-probe: bpol_probe -> b_field_pol_probe.
        ! COCOS b_field_pol_probe/{measured,reconstructed} is factor +1.
        if (associated(s%bpol_probe)) then
            allocate(d%b_field_pol_probe(size(s%bpol_probe)))
            do i = 1, size(s%bpol_probe)
                call conv_c0d_one(s%bpol_probe(i), d%b_field_pol_probe(i), KEEP)
            end do
        end if

        ! identical, COCOS factor +1
        call conv_c0d_b0(s%diamagnetic_flux, d%diamagnetic_flux, KEEP)

        ! identical
        if (associated(s%faraday_angle)) then
            allocate(d%faraday_angle(size(s%faraday_angle)))
            do i = 1, size(s%faraday_angle)
                call conv_c0d(s%faraday_angle(i), d%faraday_angle(i), KEEP)
            end do
        end if

        ! renamed spell-polarisation: mse_polarisation_angle -> mse_polarization_angle
        if (associated(s%mse_polarisation_angle)) then
            allocate(d%mse_polarization_angle(size(s%mse_polarisation_angle)))
            do i = 1, size(s%mse_polarisation_angle)
                call conv_c0d(s%mse_polarisation_angle(i), d%mse_polarization_angle(i), KEEP)
            end do
        end if

        ! identical, but the DD3 type is constraints_0D_psi_like and the DD4 one
        ! plain constraints_0D. Same members.
        ! cocos flip: constraints/flux_loop/{measured,reconstructed}
        if (associated(s%flux_loop)) then
            allocate(d%flux_loop(size(s%flux_loop)))
            do i = 1, size(s%flux_loop)
                call conv_c0d_psi(s%flux_loop(i), d%flux_loop(i), FLIP)
            end do
        end if

        ! identical; cocos flip: constraints/ip/{measured,reconstructed}
        call conv_c0d_ip(s%ip, d%ip, FLIP)

        ! renamed spell-magnetisation / spell-magnetisation-z
        if (associated(s%iron_core_segment)) then
            allocate(d%iron_core_segment(size(s%iron_core_segment)))
            do i = 1, size(s%iron_core_segment)
                call conv_c0d(s%iron_core_segment(i)%magnetisation_r, &
                              d%iron_core_segment(i)%magnetization_r, KEEP)
                call conv_c0d(s%iron_core_segment(i)%magnetisation_z, &
                              d%iron_core_segment(i)%magnetization_z, KEEP)
            end do
        end if

        ! identical; cocos flip on .../position/psi only, not on measured
        if (associated(s%n_e)) then
            allocate(d%n_e(size(s%n_e)))
            do i = 1, size(s%n_e)
                call conv_c0d_pos(s%n_e(i), d%n_e(i), KEEP)
            end do
        end if

        ! identical
        if (associated(s%n_e_line)) then
            allocate(d%n_e_line(size(s%n_e_line)))
            do i = 1, size(s%n_e_line)
                call conv_c0d(s%n_e_line(i), d%n_e_line(i), KEEP)
            end do
        end if

        ! identical; cocos flip: constraints/pf_current/{measured,reconstructed}
        if (associated(s%pf_current)) then
            allocate(d%pf_current(size(s%pf_current)))
            do i = 1, size(s%pf_current)
                call conv_c0d_ip(s%pf_current(i), d%pf_current(i), FLIP)
            end do
        end if

        ! identical
        if (associated(s%pf_passive_current)) then
            allocate(d%pf_passive_current(size(s%pf_passive_current)))
            do i = 1, size(s%pf_passive_current)
                call conv_c0d(s%pf_passive_current(i), d%pf_passive_current(i), KEEP)
            end do
        end if

        ! identical; cocos flip on position/psi
        if (associated(s%pressure)) then
            allocate(d%pressure(size(s%pressure)))
            do i = 1, size(s%pressure)
                call conv_c0d_pos(s%pressure(i), d%pressure(i), KEEP)
            end do
        end if
        if (associated(s%pressure_rotational)) then
            allocate(d%pressure_rotational(size(s%pressure_rotational)))
            do i = 1, size(s%pressure_rotational)
                call conv_c0d_pos(s%pressure_rotational(i), d%pressure_rotational(i), KEEP)
            end do
        end if
        if (associated(s%q)) then
            allocate(d%q(size(s%q)))
            do i = 1, size(s%q)
                call conv_c0d_pos(s%q(i), d%q(i), KEEP)
            end do
        end if

        ! merged fold-constraints-j -> constraints/j_phi.
        ! The map gives j_phi precedence 1 and j_tor precedence 2, on the reading
        ! that DD 3.39.0 ships both spellings. It does not: the generated DD
        ! 3.39.0 type has j_tor only, so the merge degenerates to a rename and
        ! the forward direction is exact, not lossy. Same for every other
        ! _tor -> _phi fold below.
        if (associated(s%j_tor)) then
            allocate(d%j_phi(size(s%j_tor)))
            do i = 1, size(s%j_tor)
                call conv_c0d_pos(s%j_tor(i), d%j_phi(i), KEEP)
            end do
        end if

        ! right_only: constraints/j_parallel was added in DD 3.40.0, so it has
        ! no 3.39.0 source (DD 3.39.0's constraints only ever had j_phi/j_tor).
        ! Declared via new-constraints-j-parallel; the dead COCOS flip this map
        ! used to carry on constraints/j_parallel/position/psi is gone too.
        call refuse(lg, 'constraints/j_parallel not synthesised (DD4-only, added in DD 3.40.0)')

        ! identical, except the two chi_squared refusals inside
        if (associated(s%x_point)) then
            allocate(d%x_point(size(s%x_point)))
            do i = 1, size(s%x_point)
                call conv_c0d_pure(s%x_point(i), d%x_point(i))
            end do
            call refuse(lg, 'constraints/x_point/chi_squared_{r,z} refused (m -> m^-2 redefine)')
        end if
        if (associated(s%strike_point)) then
            allocate(d%strike_point(size(s%strike_point)))
            do i = 1, size(s%strike_point)
                call conv_c0d_pure(s%strike_point(i), d%strike_point(i))
            end do
            call refuse(lg, 'constraints/strike_point/chi_squared_{r,z} refused (m -> m^-2 redefine)')
        end if

        ! right_only: three DD4-only scalars, all added in DD 3.40.0. Declared
        ! via new-constraints-chi-squared-reduced / -freedom-degrees-n /
        ! -constraints-n.
        call refuse(lg, 'constraints/{chi_squared_reduced,freedom_degrees_n,constraints_n}'// &
                        ' not synthesised (DD4-only, added in DD 3.40.0)')
    end subroutine

    ! ------------------------------------------- the constraints_0D_* family
    !
    ! Five DD3 types with identical members map onto four DD4 ones. Fortran has
    ! no generic over derived types, so each pair gets its own routine. `sgn` is
    ! the COCOS factor for measured/reconstructed; position/psi always flips.

    subroutine conv_c0d(s, d, sgn)
        type(ids_equilibrium_constraints_0D_v3_39_0), intent(in) :: s
        type(ids_equilibrium_constraints_0D_v4_1_1), intent(inout) :: d
        real(ids_real), intent(in) :: sgn
        d%measured = scaled(s%measured, sgn)
        call cps(s%source, d%source)
        d%time_measurement = s%time_measurement
        d%exact = s%exact
        d%weight = s%weight
        d%reconstructed = scaled(s%reconstructed, sgn)
        d%chi_squared = s%chi_squared
    end subroutine

    subroutine conv_c0d_psi(s, d, sgn)
        type(ids_equilibrium_constraints_0D_psi_like_v3_39_0), intent(in) :: s
        type(ids_equilibrium_constraints_0D_v4_1_1), intent(inout) :: d
        real(ids_real), intent(in) :: sgn
        d%measured = scaled(s%measured, sgn)
        call cps(s%source, d%source)
        d%time_measurement = s%time_measurement
        d%exact = s%exact
        d%weight = s%weight
        d%reconstructed = scaled(s%reconstructed, sgn)
        d%chi_squared = s%chi_squared
    end subroutine

    subroutine conv_c0d_one(s, d, sgn)
        type(ids_equilibrium_constraints_0D_one_like_v3_39_0), intent(in) :: s
        type(ids_equilibrium_constraints_0D_one_like_v4_1_1), intent(inout) :: d
        real(ids_real), intent(in) :: sgn
        d%measured = scaled(s%measured, sgn)
        call cps(s%source, d%source)
        d%time_measurement = s%time_measurement
        d%exact = s%exact
        d%weight = s%weight
        d%reconstructed = scaled(s%reconstructed, sgn)
        d%chi_squared = s%chi_squared
    end subroutine

    subroutine conv_c0d_b0(s, d, sgn)
        type(ids_equilibrium_constraints_0D_b0_like_v3_39_0), intent(in) :: s
        type(ids_equilibrium_constraints_0D_b0_like_v4_1_1), intent(inout) :: d
        real(ids_real), intent(in) :: sgn
        d%measured = scaled(s%measured, sgn)
        call cps(s%source, d%source)
        d%time_measurement = s%time_measurement
        d%exact = s%exact
        d%weight = s%weight
        d%reconstructed = scaled(s%reconstructed, sgn)
        d%chi_squared = s%chi_squared
    end subroutine

    subroutine conv_c0d_ip(s, d, sgn)
        type(ids_equilibrium_constraints_0D_ip_like_v3_39_0), intent(in) :: s
        type(ids_equilibrium_constraints_0D_ip_like_v4_1_1), intent(inout) :: d
        real(ids_real), intent(in) :: sgn
        d%measured = scaled(s%measured, sgn)
        call cps(s%source, d%source)
        d%time_measurement = s%time_measurement
        d%exact = s%exact
        d%weight = s%weight
        d%reconstructed = scaled(s%reconstructed, sgn)
        d%chi_squared = s%chi_squared
    end subroutine

    subroutine conv_c0d_pos(s, d, sgn)
        type(ids_equilibrium_constraints_0D_position_v3_39_0), intent(in) :: s
        type(ids_equilibrium_constraints_0D_position_v4_1_1), intent(inout) :: d
        real(ids_real), intent(in) :: sgn
        d%measured = scaled(s%measured, sgn)
        ! The DD3 type is rzphipsirho0d_dynamic_aos3, the DD4 one
        ! rphizpsirho0d_dynamic_aos3: same five members, declared in a different
        ! order. A member-by-member copy is exact.
        d%position%r = s%position%r
        d%position%z = s%position%z
        d%position%phi = s%position%phi
        d%position%rho_tor_norm = s%position%rho_tor_norm
        ! cocos flip: constraints/<x>/position/psi
        d%position%psi = flipped(s%position%psi)
        call cps(s%source, d%source)
        d%time_measurement = s%time_measurement
        d%exact = s%exact
        d%weight = s%weight
        d%reconstructed = scaled(s%reconstructed, sgn)
        d%chi_squared = s%chi_squared
    end subroutine

    subroutine conv_c0d_pure(s, d)
        type(ids_equilibrium_constraints_pure_position_v3_39_0), intent(in) :: s
        type(ids_equilibrium_constraints_pure_position_v4_1_1), intent(inout) :: d
        call conv_rz0d(s%position_measured, d%position_measured)
        call cps(s%source, d%source)
        d%time_measurement = s%time_measurement
        d%exact = s%exact
        d%weight = s%weight
        call conv_rz0d(s%position_reconstructed, d%position_reconstructed)
        ! <redefine> chi_squared_{r,z}: m -> m^-2 is a dimensional
        ! redefinition, not a rescale - chi-squared is now normalised by the
        ! measurement variance, and no factor inverts that without the variance
        ! used at reconstruction time. fidelity is unmappable both ways, so the
        ! map says refuse rather than guess: both are left at the invalid marker.
    end subroutine

    ! ====================================================== global_quantities

    subroutine conv_global_quantities(s, d, lg)
        type(ids_equlibrium_global_quantities_v3_39_0), intent(in) :: s
        type(ids_equlibrium_global_quantities_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg

        ! identical
        d%beta_pol = s%beta_pol
        d%beta_tor = s%beta_tor
        ! renamed rename-beta-normal: beta_normal -> beta_tor_norm
        d%beta_tor_norm = s%beta_normal
        ! cocos flip: global_quantities/ip
        d%ip = flipped(s%ip)
        d%li_3 = s%li_3
        d%volume = s%volume
        d%area = s%area
        d%surface = s%surface
        d%length_pol = s%length_pol

        ! split split-psi-axis (decision="yes"): the DD3 value feeds BOTH DD4
        ! paths, on the assumption that psi_magnetic_axis is the same quantity as
        ! psi_axis. Both targets take the COCOS flip.
        !
        ! Note this is where the map and the checked-in DD 4.1.1 fixture part
        ! company: the fixture leaves psi_axis empty (it is obsolescent in DD4
        ! and nothing writes it) and fills psi_magnetic_axis alone. Following the
        ! map fills both, so the report's TRAP row shows a value where the 4.1.1
        ! column shows <empty>. Which of the two is right is exactly the question
        ! validate.py flags for a physicist.
        d%psi_axis = flipped(s%psi_axis)
        d%psi_magnetic_axis = flipped(s%psi_axis)

        ! cocos flip: global_quantities/psi_boundary
        d%psi_boundary = flipped(s%psi_boundary)

        ! right_only: rho_tor_boundary was added in DD 3.40.0. Declared via
        ! new-global-quantities-rho-tor-boundary.
        call refuse(lg, 'global_quantities/rho_tor_boundary not synthesised'// &
                        ' (DD4-only, added in DD 3.40.0)')

        ! identical
        d%magnetic_axis%r = s%magnetic_axis%r
        d%magnetic_axis%z = s%magnetic_axis%z
        ! merged fold-axis-bphi -> magnetic_axis/b_field_phi. The map declares a
        ! three-way merge (b_field_phi, b_field_tor, b_tor); DD 3.39.0 has only
        ! the latter two, so precedence 2 then 3.
        d%magnetic_axis%b_field_phi = pick2(s%magnetic_axis%b_field_tor, &
                                            s%magnetic_axis%b_tor)
        if (defined(s%magnetic_axis%b_field_tor) .and. defined(s%magnetic_axis%b_tor)) &
            call lossy(lg, 'magnetic_axis: both b_field_tor and b_tor set, b_tor discarded')

        ! identical
        d%current_centre%r = s%current_centre%r
        d%current_centre%z = s%current_centre%z
        d%current_centre%velocity_z = s%current_centre%velocity_z
        d%q_axis = s%q_axis
        d%q_95 = s%q_95
        d%q_min%value = s%q_min%value
        d%q_min%rho_tor_norm = s%q_min%rho_tor_norm

        ! right_only: q_min/{psi,psi_norm} were added to the DD in 3.40.0, so
        ! they have no 3.39.0 source. The map declares this via new-q-min-psi /
        ! new-q-min-psi-norm (it previously omitted this - the 3.39.0 inventory
        ! wrongly listed both paths as present, and the map carried a COCOS
        ! flip for q_min/psi that had nothing to act on).
        call refuse(lg, 'global_quantities/q_min/{psi,psi_norm} not synthesised'// &
                        ' (DD4-only, added in DD 3.40.0)')

        ! merged fold-energy-mhd: energy_mhd (precedence 1) then w_mhd
        ! (precedence 2, obsolescent). Both do exist in DD 3.39.0, so this is a
        ! genuine merge and genuinely lossy when the two disagree.
        d%energy_mhd = pick2(s%energy_mhd, s%w_mhd)
        if (defined(s%energy_mhd) .and. defined(s%w_mhd)) &
            call lossy(lg, 'global_quantities: both energy_mhd and w_mhd set, w_mhd discarded')

        ! cocos flip: psi_external_average, v_external
        d%psi_external_average = flipped(s%psi_external_average)
        d%v_external = flipped(s%v_external)
        ! identical
        d%plasma_inductance = s%plasma_inductance
        d%plasma_resistance = s%plasma_resistance
    end subroutine

    ! =========================================================== profiles_1d

    subroutine conv_profiles_1d(s, d, lg)
        type(ids_equilibrium_profiles_1d_v3_39_0), intent(in) :: s
        type(ids_equilibrium_profiles_1d_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg

        ! cocos flip: profiles_1d/psi. The imas-dd guide reports this path twice,
        ! as cocos_sign_flip and again as definition_change(sign_convention);
        ! that is one physical fact, so it is flipped once.
        call cp1(s%psi, d%psi, FLIP)

        ! right_only: profiles_1d/psi_norm was added in DD 3.40.0. Declared
        ! via new-profiles-1d-psi-norm.
        call refuse(lg, 'profiles_1d/psi_norm not synthesised (DD4-only, added in DD 3.40.0)')

        ! identical
        call cp1(s%phi, d%phi)
        call cp1(s%pressure, d%pressure)
        call cp1(s%f, d%f)
        ! cocos flip: dpressure_dpsi, f_df_dpsi (dodpsi_like)
        call cp1(s%dpressure_dpsi, d%dpressure_dpsi, FLIP)
        call cp1(s%f_df_dpsi, d%f_df_dpsi, FLIP)
        ! merged fold-p1d-j -> j_phi; DD 3.39.0 has j_tor only. cocos flip (ip_like)
        call cp1(s%j_tor, d%j_phi, FLIP)
        ! cocos flip: j_parallel
        call cp1(s%j_parallel, d%j_parallel, FLIP)
        ! identical
        call cp1(s%q, d%q)
        call cp1(s%magnetic_shear, d%magnetic_shear)
        call cp1(s%r_inboard, d%r_inboard)
        call cp1(s%r_outboard, d%r_outboard)
        call cp1(s%rho_tor, d%rho_tor)
        call cp1(s%rho_tor_norm, d%rho_tor_norm)
        ! cocos flip: dpsi_drho_tor
        call cp1(s%dpsi_drho_tor, d%dpsi_drho_tor, FLIP)
        ! identical
        call cp1(s%geometric_axis%r, d%geometric_axis%r)
        call cp1(s%geometric_axis%z, d%geometric_axis%z)
        call cp1(s%elongation, d%elongation)
        call cp1(s%triangularity_upper, d%triangularity_upper)
        call cp1(s%triangularity_lower, d%triangularity_lower)
        call cp1(s%squareness_upper_inner, d%squareness_upper_inner)
        call cp1(s%squareness_upper_outer, d%squareness_upper_outer)
        call cp1(s%squareness_lower_inner, d%squareness_lower_inner)
        call cp1(s%squareness_lower_outer, d%squareness_lower_outer)
        call cp1(s%volume, d%volume)
        call cp1(s%rho_volume_norm, d%rho_volume_norm)
        ! cocos flip: dvolume_dpsi
        call cp1(s%dvolume_dpsi, d%dvolume_dpsi, FLIP)
        ! identical
        call cp1(s%dvolume_drho_tor, d%dvolume_drho_tor)
        call cp1(s%area, d%area)
        ! cocos flip: darea_dpsi
        call cp1(s%darea_dpsi, d%darea_dpsi, FLIP)
        ! identical
        call cp1(s%darea_drho_tor, d%darea_drho_tor)
        call cp1(s%surface, d%surface)
        call cp1(s%trapped_fraction, d%trapped_fraction)
        call cp1(s%gm1, d%gm1)
        call cp1(s%gm2, d%gm2)
        call cp1(s%gm3, d%gm3)
        call cp1(s%gm4, d%gm4)
        call cp1(s%gm5, d%gm5)
        call cp1(s%gm6, d%gm6)
        call cp1(s%gm7, d%gm7)
        call cp1(s%gm8, d%gm8)
        call cp1(s%gm9, d%gm9)

        ! merged fold-p1d-baverage, fold-p1d-bmin, fold-p1d-bmax. Here DD 3.39.0
        ! really does ship both spellings, so these are genuine merges: forward
        ! lossy whenever the two disagree.
        call mg1(s%b_field_average, s%b_average, d%b_field_average, lg, 'profiles_1d/b_average')
        call mg1(s%b_field_min, s%b_min, d%b_field_min, lg, 'profiles_1d/b_min')
        call mg1(s%b_field_max, s%b_max, d%b_field_max, lg, 'profiles_1d/b_max')

        ! identical
        call cp1(s%beta_pol, d%beta_pol)
        call cp1(s%mass_density, d%mass_density)
    end subroutine

    ! =========================================================== profiles_2d

    subroutine conv_profiles_2d(s, d, lg)
        type(ids_equilibrium_profiles_2d_v3_39_0), intent(in) :: s
        type(ids_equilibrium_profiles_2d_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg

        ! identical
        call conv_identifier(s%type, d%type)
        call conv_identifier(s%grid_type, d%grid_type)
        call cp1(s%grid%dim1, d%grid%dim1)
        call cp1(s%grid%dim2, d%grid%dim2)
        call cp2(s%grid%volume_element, d%grid%volume_element)
        call cp2(s%r, d%r)
        call cp2(s%z, d%z)
        ! cocos flip: profiles_2d/psi (reported twice by imas-dd, flipped once)
        call cp2(s%psi, d%psi, FLIP)
        ! identical. profiles_2d/theta carries a DD4 coordinate_convention
        ! clarification (the poloidal angle is now pinned to a right-handed
        ! (grad rho_tor_norm, grad theta, grad phi) set) that the map does not
        ! record. COCOS factor is +1, so there is nothing to apply - but DD3 data
        ! written with the opposite handedness converts to a wrong sign silently.
        call cp2(s%theta, d%theta)
        if (associated(s%theta)) call lossy(lg, &
            'profiles_2d/theta copied unchanged; DD4 pins the poloidal-angle'// &
            ' handedness (not in map)')
        call cp2(s%phi, d%phi)
        ! merged fold-p2d-j -> j_phi; DD 3.39.0 has j_tor only. cocos flip
        call cp2(s%j_tor, d%j_phi, FLIP)
        ! cocos flip: profiles_2d/j_parallel
        call cp2(s%j_parallel, d%j_parallel, FLIP)
        ! merged fold-p2d-br, fold-p2d-bz: both spellings really are in DD 3.39.0
        call mg2(s%b_field_r, s%b_r, d%b_field_r, lg, 'profiles_2d/b_r')
        call mg2(s%b_field_z, s%b_z, d%b_field_z, lg, 'profiles_2d/b_z')
        ! merged fold-p2d-bphi: the map declares a three-way merge
        ! (b_field_phi, b_field_tor, b_tor); DD 3.39.0 has the latter two.
        call mg2(s%b_field_tor, s%b_tor, d%b_field_phi, lg, 'profiles_2d/b_tor')
    end subroutine

    ! ==================================================================== ggd

    subroutine conv_ggd(s, d, lg)
        type(ids_equilibrium_ggd_v3_39_0), intent(in) :: s
        type(ids_equilibrium_ggd_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg

        ! left_only drop-timeslice-ggd-grid: DD3 embedded a whole GGD grid
        ! description in every time slice (48 paths). DD4 references the
        ! IDS-level grids_ggd through ggd/*/grid_index instead.
        call lossy(lg, 'time_slice/ggd/grid dropped; DD4 references grids_ggd by grid_index')

        ! identical
        call cp_scalar_aos(s%r, d%r, KEEP)
        call cp_scalar_aos(s%z, d%z, KEEP)
        ! cocos flip: time_slice/ggd/psi/values
        call cp_scalar_aos(s%psi, d%psi, FLIP)
        call cp_scalar_aos(s%phi, d%phi, KEEP)
        ! see the profiles_2d/theta note above
        call cp_scalar_aos(s%theta, d%theta, KEEP)
        ! merged fold-ggd-j -> ggd/j_phi; DD 3.39.0 has j_tor only
        call cp_scalar_aos(s%j_tor, d%j_phi, KEEP)
        call cp_scalar_aos(s%j_parallel, d%j_parallel, KEEP)
        call cp_scalar_aos(s%b_field_r, d%b_field_r, KEEP)
        ! merged fold-ggd-bfield -> ggd/b_field_phi; DD 3.39.0 has b_field_tor only
        call cp_scalar_aos(s%b_field_tor, d%b_field_phi, KEEP)
        call cp_scalar_aos(s%b_field_z, d%b_field_z, KEEP)
    end subroutine

    subroutine cp_scalar_aos(s, d, sgn)
        type(ids_generic_grid_scalar_v3_39_0), pointer, intent(in) :: s(:)
        type(ids_generic_grid_scalar_v4_1_1), pointer, intent(inout) :: d(:)
        real(ids_real), intent(in) :: sgn
        integer :: i
        if (.not. associated(s)) return
        allocate(d(size(s)))
        do i = 1, size(s)
            d(i)%grid_index = s(i)%grid_index
            d(i)%grid_subset_index = s(i)%grid_subset_index
            call cp1(s(i)%values, d(i)%values, sgn)
            call cp2(s(i)%coefficients, d(i)%coefficients, sgn)
        end do
    end subroutine

    ! ====================================================== coordinate_system

    subroutine conv_coordinate_system(s, d, lg)
        type(ids_equilibrium_coordinate_system_v3_39_0), intent(in) :: s
        type(ids_equilibrium_coordinate_system_v4_1_1), intent(inout) :: d
        type(conversion_log), intent(inout) :: lg

        ! identical
        call conv_identifier(s%grid_type, d%grid_type)
        call cp1(s%grid%dim1, d%grid%dim1)
        call cp1(s%grid%dim2, d%grid%dim2)
        call cp2(s%grid%volume_element, d%grid%volume_element)
        call cp2(s%r, d%r)
        call cp2(s%z, d%z)
        call cp2(s%jacobian, d%jacobian)
        call cp4(s%tensor_covariant, d%tensor_covariant)
        call cp4(s%tensor_contravariant, d%tensor_contravariant)

        ! left_only, twelve rules, one per component:
        !   drop-g11-cov  drop-g11-contra  drop-g12-cov  drop-g12-contra
        !   drop-g13-cov  drop-g13-contra  drop-g22-cov  drop-g22-contra
        !   drop-g23-cov  drop-g23-contra  drop-g33-cov  drop-g33-contra
        ! They were already obsolescent in 3.39.0 and DD4 carries the metric
        ! through tensor_covariant / tensor_contravariant above, which are
        ! identical on both sides. Nothing is reconstructed from them.
        if (associated(s%g11_covariant) .or. associated(s%g11_contravariant)) &
            call lossy(lg, 'coordinate_system/g*_{co,contra}variant dropped'// &
                           ' (obsolescent in DD3; use tensor_*variant)')
    end subroutine

    ! ================================================================ helpers

    subroutine conv_identifier(s, d)
        type(ids_identifier_dynamic_aos3_v3_39_0), intent(in) :: s
        type(ids_identifier_dynamic_aos3_v4_1_1), intent(inout) :: d
        call cps(s%name, d%name)
        d%index = s%index
        call cps(s%description, d%description)
    end subroutine

    subroutine conv_rz1d(s, d)
        type(ids_rz1d_dynamic_aos_v3_39_0), intent(in) :: s
        type(ids_rz1d_dynamic_aos_v4_1_1), intent(inout) :: d
        call cp1(s%r, d%r)
        call cp1(s%z, d%z)
    end subroutine

    subroutine conv_rz0d(s, d)
        type(ids_rz0d_dynamic_aos_v3_39_0), intent(in) :: s
        type(ids_rz0d_dynamic_aos_v4_1_1), intent(inout) :: d
        d%r = s%r
        d%z = s%z
    end subroutine

    ! -- scalars ---------------------------------------------------------------

    logical function defined(x)
        real(ids_real), intent(in) :: x
        defined = (x /= ids_real_invalid)
    end function

    ! An unset node holds the invalid marker, so the flip must not turn it into
    ! its negative - that would fabricate a value out of absence.
    real(ids_real) function scaled(x, sgn)
        real(ids_real), intent(in) :: x
        real(ids_real), intent(in) :: sgn
        scaled = x
        if (defined(x)) scaled = sgn * x
    end function

    real(ids_real) function flipped(x)
        real(ids_real), intent(in) :: x
        flipped = scaled(x, FLIP)
    end function

    ! merged, scalar: highest precedence source that actually holds a value.
    real(ids_real) function pick2(a, b)
        real(ids_real), intent(in) :: a, b
        pick2 = a
        if (.not. defined(a)) pick2 = b
    end function

    ! -- arrays ----------------------------------------------------------------

    subroutine cp1(s, d, sgn)
        real(ids_real), pointer, intent(in) :: s(:)
        real(ids_real), pointer, intent(inout) :: d(:)
        real(ids_real), intent(in), optional :: sgn
        if (.not. associated(s)) return
        allocate(d(size(s)))
        if (present(sgn)) then
            d = sgn * s
        else
            d = s
        end if
    end subroutine

    subroutine cp2(s, d, sgn)
        real(ids_real), pointer, intent(in) :: s(:,:)
        real(ids_real), pointer, intent(inout) :: d(:,:)
        real(ids_real), intent(in), optional :: sgn
        if (.not. associated(s)) return
        allocate(d(size(s,1), size(s,2)))
        if (present(sgn)) then
            d = sgn * s
        else
            d = s
        end if
    end subroutine

    subroutine cp3(s, d)
        real(ids_real), pointer, intent(in) :: s(:,:,:)
        real(ids_real), pointer, intent(inout) :: d(:,:,:)
        if (.not. associated(s)) return
        allocate(d(size(s,1), size(s,2), size(s,3)))
        d = s
    end subroutine

    subroutine cp4(s, d)
        real(ids_real), pointer, intent(in) :: s(:,:,:,:)
        real(ids_real), pointer, intent(inout) :: d(:,:,:,:)
        if (.not. associated(s)) return
        allocate(d(size(s,1), size(s,2), size(s,3), size(s,4)))
        d = s
    end subroutine

    subroutine cpi1(s, d)
        integer(ids_int), pointer, intent(in) :: s(:)
        integer(ids_int), pointer, intent(inout) :: d(:)
        if (.not. associated(s)) return
        allocate(d(size(s)))
        d = s
    end subroutine

    subroutine cps(s, d)
        character(len=ids_string_length), dimension(:), pointer, intent(in) :: s
        character(len=ids_string_length), dimension(:), pointer, intent(inout) :: d
        if (.not. associated(s)) return
        allocate(d(size(s)))
        d = s
    end subroutine

    subroutine set1(d, text)
        character(len=ids_string_length), dimension(:), pointer, intent(inout) :: d
        character(len=*), intent(in) :: text
        allocate(d(1))
        d(1) = text
    end subroutine

    ! merged, 1D: precedence 1 wins; if both are populated the second is
    ! discarded, which is the map's forward="lossy".
    subroutine mg1(a, b, d, lg, dropped)
        real(ids_real), pointer, intent(in) :: a(:), b(:)
        real(ids_real), pointer, intent(inout) :: d(:)
        type(conversion_log), intent(inout) :: lg
        character(len=*), intent(in) :: dropped
        if (associated(a)) then
            call cp1(a, d)
            if (associated(b)) call lossy(lg, 'merged: '//dropped//' discarded, modern name won')
        else
            call cp1(b, d)
        end if
    end subroutine

    subroutine mg2(a, b, d, lg, dropped)
        real(ids_real), pointer, intent(in) :: a(:,:), b(:,:)
        real(ids_real), pointer, intent(inout) :: d(:,:)
        type(conversion_log), intent(inout) :: lg
        character(len=*), intent(in) :: dropped
        if (associated(a)) then
            call cp2(a, d)
            if (associated(b)) call lossy(lg, 'merged: '//dropped//' discarded, modern name won')
        else
            call cp2(b, d)
        end if
    end subroutine

    ! -- the log ---------------------------------------------------------------

    subroutine lossy(lg, text)
        type(conversion_log), intent(inout) :: lg
        character(len=*), intent(in) :: text
        if (add(lg, 'lossy   ', text)) lg%lossy = lg%lossy + 1
    end subroutine

    subroutine refuse(lg, text)
        type(conversion_log), intent(inout) :: lg
        character(len=*), intent(in) :: text
        if (add(lg, 'refused ', text)) lg%refused = lg%refused + 1
    end subroutine

    ! Deduplicated, returning .true. only when the note was new: every note here
    ! fires once per time slice (or once per array element), and the same fact
    ! repeated twelve times would drown the ones that fired only once.
    logical function add(lg, kind, text)
        type(conversion_log), intent(inout) :: lg
        character(len=*), intent(in) :: kind, text
        character(len=LOG_WIDTH) :: entry
        integer :: i
        add = .false.
        entry = kind//text
        do i = 1, lg%n
            if (lg%line(i) == entry) return
        end do
        if (lg%n >= LOG_MAX) return
        lg%n = lg%n + 1
        lg%line(lg%n) = entry
        add = .true.
    end function

    subroutine log_report(lg)
        type(conversion_log), intent(in) :: lg
        integer :: i
        write(*,'(/,a)') ' conversion log: distinct facts the map could not carry across'
        write(*,'(a,i0,a,i0,a)') '   ', lg%refused, ' refused (unmappable, left empty), ', &
             lg%lossy, ' lossy (something was dropped)'
        do i = 1, lg%n
            write(*,'(4x,a)') trim(lg%line(i))
        end do
    end subroutine

end module
