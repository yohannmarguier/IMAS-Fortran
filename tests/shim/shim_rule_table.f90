! The hand-authored rule table for the shim contract suite's structural rules.
!
! The conversion map this table transcribes lives in the shim's own repository
! at docs/3.39.0--4.1.1.xml (IMAS-Multiversion-DD-Loader), not in this one. It
! is hand-authored here rather than generated from that file because the map
! itself says why generation would silently under-cover: it opens with
!
!   <include href="../common/error-model-3to4.xml"/>
!   <include href="../common/naming-3to4.xml"/>
!
! and neither `common/error-model-3to4.xml` nor `common/naming-3to4.xml`
! exists anywhere the map is reachable from outside the shim's own tree. The
! second one is the one that matters here: it is the include the map's own
! comments say carries the common cross-IDS renames, so a generator walking
! only what resolves would produce a table that looks complete while quietly
! missing an entire rename family. A hand-authored table fails to compile
! instead of failing to notice.
!
! Promoting a flattened, machine-readable rule manifest — so a table like this
! one could be generated and checked against it instead of merely trusted —
! is recorded here as an ask of the shim, alongside the loss-log-format ask
! docs/adr/0002 already names; both are to be gathered into the suite's own
! README (#78) once it lands.
!
! Every entry below cites either a rule id from that map or a section of
! imas-python-fixtures/README.md, so an entry can be checked without reading
! the shim's implementation. This module carries the kinds whose verdict is
! "the two sides agree" and whose subject matter is structural: identical,
! renamed, moved, merged (the eight folds where both DD3 spellings carry
! real data) and split — plus, per ticket #68, every COCOS 11 -> 17 sign
! flip the map declares. Right_only and retyped have their own verdicts and
! belong to later tickets (#69, #70, #72).
!
! Five further `merged` rules exist in the map (fold-constraints-j,
! fold-ggd-j, fold-ggd-bfield, fold-p1d-j, fold-p2d-j) whose only real DD3
! source is the deprecated `_tor` alias — imas-python-fixtures/README.md's
! own "Renames" table lists their targets alongside true renames for that
! reason. Two of those five targets (profiles_1d/j_phi, profiles_2d/j_phi)
! are themselves COCOS paths and are carried below as cocos rules, each
! noting the fold it also rides on; the remaining three are not claimed by
! any rule-table ticket today. That gap is noted here rather than silently
! widening this table's scope to cover it.
!
! ------------------------------------------------------------ COCOS 11 -> 17
!
! Source of truth: IMAS-Multiversion-DD-Loader's docs/3.39.0--4.1.1.xml,
! <transforms><cocos from="11" to="17">...</cocos></transforms>. That block
! lists exactly 30 <flip path="..."/> entries today, each transcribed below
! citing its own path — not 32. imas-python-fixtures/README.md's "COCOS 11 ->
! 17" section and this repository's parent spec (issue #63) both say "32
! paths in the map's <cocos> block"; every commit that has ever touched that
! file (c0beaaf, 333996f, 6a87941, 2022a17) carries the same 30, so 32 looks
! like a stale count rather than a moving target. This table follows the map
! itself rather than the stale count, per this suite's own design principle:
! a hand-authored table fails to compile instead of failing to notice, and
! silently padding it to 32 would be worse than either — it would assert
! agreement on a path nobody's fixture or map actually flips.
!
! Two paths outside the <cocos> block are deliberately not carried here even
! though they are also negated:
!
!   - `time_slice/constraints/j_parallel/position/psi` — flipped by
!     equilibrium_v4_1_1.py for the fixture's own physical self-consistency,
!     but the whole `constraints/j_parallel` subtree is `right_only` (rule
!     "new-constraints-j-parallel": DD3 has no j_parallel constraint at all),
!     so the shim never converts a DD3 value into it. It belongs to the
!     right_only rule kind, not this one.
!   - `time_slice/contour_tree/node/psi` — the fixtures README's own "COCOS
!     11 -> 17" section names this as one quantity outside the map that is
!     "also negated", since `contour_tree` has no DD3 source at all
!     (`new-contour-tree`, right_only). Same reasoning as above.
!
! `global_quantities/psi_magnetic_axis` is both a cocos rule here and the
! split-psi-axis structural rule above: the map's own <flip> entry for it
! carries `note="target of split-psi-axis"`, and both are worth asserting
! independently rather than assuming one implies the other.
! `profiles_1d/j_phi` and `profiles_2d/j_phi` are similarly both a cocos rule
! here and (per the note above) an obsolescent-alias fold not otherwise
! claimed by the structural table.
module shim_rule_table
  implicit none
  private

  integer, parameter, public :: rule_kind_identical = 1
  integer, parameter, public :: rule_kind_renamed   = 2
  integer, parameter, public :: rule_kind_moved     = 3
  integer, parameter, public :: rule_kind_merged    = 4
  integer, parameter, public :: rule_kind_split     = 5
  integer, parameter, public :: rule_kind_cocos     = 6

  type, public :: rule_entry
    character(len=32)  :: id
    integer             :: kind
    character(len=96)   :: hli_path
    character(len=200)  :: source
  end type rule_entry

  integer, parameter, public :: structural_rule_count = 20

  type(rule_entry), parameter, public :: structural_rules(structural_rule_count) = [ &
    ! -- identical: unclaimed paths falling through the map's own default rule --
    rule_entry('identical-vacuum-r0', rule_kind_identical, &
      'vacuum_toroidal_field/r0', &
      'map <default rel="identical"/>, confirmed by <coverage scope="vacuum_toroidal_field" forward="exact" reverse="exact"/>'), &
    rule_entry('identical-time', rule_kind_identical, &
      'time', &
      'map <default rel="identical"/>, confirmed by <coverage scope="time" forward="exact" reverse="exact"/>'), &
    rule_entry('identical-beta-pol', rule_kind_identical, &
      'time_slice/global_quantities/beta_pol', &
      'map <default rel="identical"/>; unclaimed by any explicit rule'), &
    ! -- renamed: five rules, one DD3 name replaced by one DD4 name --
    rule_entry('rename-beta-normal', rule_kind_renamed, &
      'time_slice/global_quantities/beta_tor_norm', &
      'map rule "rename-beta-normal"; fixtures README Renames row "global_quantities/beta_normal"'), &
    rule_entry('rename-bpol-probe', rule_kind_renamed, &
      'time_slice/constraints/b_field_pol_probe/measured', &
      'map rule "rename-bpol-probe"; fixtures README Renames row "constraints/bpol_probe"'), &
    rule_entry('rename-mse-polarisation-angle', rule_kind_renamed, &
      'time_slice/constraints/mse_polarization_angle/measured', &
      'map rule "rename-mse-polarisation-angle"; fixtures README Renames row "constraints/mse_polarisation_angle"'), &
    rule_entry('rename-magnetisation-r', rule_kind_renamed, &
      'time_slice/constraints/iron_core_segment/magnetization_r/measured', &
      'map rule "rename-magnetisation-r"; fixtures README Renames row "iron_core_segment/magnetisation_r"'), &
    rule_entry('rename-magnetisation-z', rule_kind_renamed, &
      'time_slice/constraints/iron_core_segment/magnetization_z/measured', &
      'map rule "rename-magnetisation-z"; fixtures README Renames row "iron_core_segment/magnetisation_z"'), &
    ! -- moved: three rules, a subtree relocated from boundary_separatrix to boundary --
    rule_entry('move-closest-wall-point', rule_kind_moved, &
      'time_slice/boundary/closest_wall_point', &
      'map rule "move-closest-wall-point"; fixtures README "Container and structure changes" row "boundary_separatrix/{closest_wall_point,...}"'), &
    rule_entry('move-dr-dz-zero-point', rule_kind_moved, &
      'time_slice/boundary/dr_dz_zero_point', &
      'map rule "move-dr-dz-zero-point"; fixtures README "Container and structure changes" row "boundary_separatrix/{...,dr_dz_zero_point,...}"'), &
    rule_entry('move-gap', rule_kind_moved, &
      'time_slice/boundary/gap', &
      'map rule "move-gap"; fixtures README "Container and structure changes" row "boundary_separatrix/{...,gap}"'), &
    ! -- merged: the eight folds where both DD3 spellings carry real data --
    rule_entry('fold-p2d-br', rule_kind_merged, &
      'time_slice/profiles_2d/b_field_r', &
      'map rule "fold-p2d-br"; fixtures README Folds "profiles_2d/b_r+b_field_r"'), &
    rule_entry('fold-p2d-bz', rule_kind_merged, &
      'time_slice/profiles_2d/b_field_z', &
      'map rule "fold-p2d-bz"; fixtures README Folds "profiles_2d/...b_z+b_field_z"'), &
    rule_entry('fold-p2d-bphi', rule_kind_merged, &
      'time_slice/profiles_2d/b_field_phi', &
      'map rule "fold-p2d-bphi"; fixtures README Folds "profiles_2d/...b_tor+b_field_tor"'), &
    ! Known red on arrival (contract assertion, not inverted or weakened —
    ! see docs/adr/0002): the DD 3.39.0 fixture holds a real value at
    ! precedence-2 (`global_quantities/magnetic_axis/b_field_tor`, confirmed
    ! on disk), but the shim's cross-version read of this path comes back
    ! not-found rather than falling back to it. The structurally identical
    ! 3-way merge fold-p2d-bphi, one struct level shallower (a profiles_2d
    ! array element rather than the scalar global_quantities/magnetic_axis
    ! sub-struct), resolves correctly, which narrows this to something about
    ! candidate fallback at this particular nesting shape. Not chased here —
    ! that is shim work.
    rule_entry('fold-axis-bphi', rule_kind_merged, &
      'time_slice/global_quantities/magnetic_axis/b_field_phi', &
      'map rule "fold-axis-bphi"; fixtures README Folds "magnetic_axis/b_tor+b_field_tor"'), &
    rule_entry('fold-p1d-baverage', rule_kind_merged, &
      'time_slice/profiles_1d/b_field_average', &
      'map rule "fold-p1d-baverage"; fixtures README Folds "profiles_1d/b_average+b_field_average"'), &
    rule_entry('fold-p1d-bmax', rule_kind_merged, &
      'time_slice/profiles_1d/b_field_max', &
      'map rule "fold-p1d-bmax"; fixtures README Folds "profiles_1d/...b_max+b_field_max"'), &
    rule_entry('fold-p1d-bmin', rule_kind_merged, &
      'time_slice/profiles_1d/b_field_min', &
      'map rule "fold-p1d-bmin"; fixtures README Folds "profiles_1d/...b_min+b_field_min"'), &
    rule_entry('fold-energy-mhd', rule_kind_merged, &
      'time_slice/global_quantities/energy_mhd', &
      'map rule "fold-energy-mhd"; fixtures README Folds "global_quantities/w_mhd+energy_mhd"'), &
    ! -- split: one rule, one DD3 source feeding two DD4 targets --
    rule_entry('split-psi-axis', rule_kind_split, &
      'time_slice/global_quantities/{psi_axis,psi_magnetic_axis}', &
      'map rule "split-psi-axis"; fixtures README "Container and structure changes" row "global_quantities/psi_axis"') &
  ]

  integer, parameter, public :: cocos_rule_count = 30

  ! Every entry cites the exact <flip path="..."/> line in the map's
  ! <transforms><cocos from="11" to="17"> block (see the module header for
  ! why this is 30 entries, not the 32 commonly quoted elsewhere) plus the
  ! fixtures README's "COCOS 11 -> 17" section, which is where
  ! equilibrium_v4_1_1.py's independently-authored oracle applies the same
  ! flip at the point of use.
  type(rule_entry), parameter, public :: cocos_rules(cocos_rule_count) = [ &
    rule_entry('cocos-boundary-psi', rule_kind_cocos, &
      'time_slice/boundary/psi', &
      'map <cocos> flip path="time_slice/boundary/psi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-flux-loop-measured', rule_kind_cocos, &
      'time_slice/constraints/flux_loop/measured', &
      'map <cocos> flip path="time_slice/constraints/flux_loop/measured"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-flux-loop-reconstructed', rule_kind_cocos, &
      'time_slice/constraints/flux_loop/reconstructed', &
      'map <cocos> flip path="time_slice/constraints/flux_loop/reconstructed"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-ip-measured', rule_kind_cocos, &
      'time_slice/constraints/ip/measured', &
      'map <cocos> flip path="time_slice/constraints/ip/measured"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-ip-reconstructed', rule_kind_cocos, &
      'time_slice/constraints/ip/reconstructed', &
      'map <cocos> flip path="time_slice/constraints/ip/reconstructed"; fixtures README "COCOS 11 -> 17"'), &
    ! Known red on arrival (contract assertion, not inverted or weakened —
    ! see docs/adr/0002): the shim refuses the whole `constraints/j_phi`
    ! subtree on the cross-version read rather than serving it, reason
    ! "this path is served by several stored candidates, and only a data
    ! read can try them in turn" — DD3 offers it two ways (`j_phi` itself
    ! and the obsolescent `j_tor` alias the fold-constraints-j merge folds
    ! in), and the shim's path-level resolution won't pick between them the
    ! way it does for a plain scalar fold such as fold-p2d-bphi. This
    ! leaves the AOS unassociated (not merely empty) on the cross side, so
    ! this rule's DD4-only verdict is a real, reproducible finding, not a
    ! flaky read — confirmed with a bounds- and pointer-checked build.
    ! Cousin of fold-axis-bphi above: both are candidate-fallback gaps at
    ! particular nesting/cardinality shapes, not this suite's to fix.
    rule_entry('cocos-j-phi-position-psi', rule_kind_cocos, &
      'time_slice/constraints/j_phi/position/psi', &
      'map <cocos> flip path="time_slice/constraints/j_phi/position/psi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-n-e-position-psi', rule_kind_cocos, &
      'time_slice/constraints/n_e/position/psi', &
      'map <cocos> flip path="time_slice/constraints/n_e/position/psi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-pf-current-measured', rule_kind_cocos, &
      'time_slice/constraints/pf_current/measured', &
      'map <cocos> flip path="time_slice/constraints/pf_current/measured"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-pf-current-reconstructed', rule_kind_cocos, &
      'time_slice/constraints/pf_current/reconstructed', &
      'map <cocos> flip path="time_slice/constraints/pf_current/reconstructed"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-pressure-position-psi', rule_kind_cocos, &
      'time_slice/constraints/pressure/position/psi', &
      'map <cocos> flip path="time_slice/constraints/pressure/position/psi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-pressure-rot-position-psi', rule_kind_cocos, &
      'time_slice/constraints/pressure_rotational/position/psi', &
      'map <cocos> flip path="time_slice/constraints/pressure_rotational/position/psi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-q-position-psi', rule_kind_cocos, &
      'time_slice/constraints/q/position/psi', &
      'map <cocos> flip path="time_slice/constraints/q/position/psi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-ggd-psi-values', rule_kind_cocos, &
      'time_slice/ggd/psi/values', &
      'map <cocos> flip path="time_slice/ggd/psi/values"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-gq-ip', rule_kind_cocos, &
      'time_slice/global_quantities/ip', &
      'map <cocos> flip path="time_slice/global_quantities/ip"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-psi-axis', rule_kind_cocos, &
      'time_slice/global_quantities/psi_axis', &
      'map <cocos> flip path="time_slice/global_quantities/psi_axis"; fixtures README "COCOS 11 -> 17"'), &
    ! Also the split-psi-axis structural rule's second target; the map's own
    ! <flip> entry for this path carries note="target of split-psi-axis".
    rule_entry('cocos-psi-magnetic-axis', rule_kind_cocos, &
      'time_slice/global_quantities/psi_magnetic_axis', &
      'map <cocos> flip path="time_slice/global_quantities/psi_magnetic_axis" note="target of split-psi-axis"; also rule "split-psi-axis"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-psi-boundary', rule_kind_cocos, &
      'time_slice/global_quantities/psi_boundary', &
      'map <cocos> flip path="time_slice/global_quantities/psi_boundary"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-psi-external-average', rule_kind_cocos, &
      'time_slice/global_quantities/psi_external_average', &
      'map <cocos> flip path="time_slice/global_quantities/psi_external_average"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-v-external', rule_kind_cocos, &
      'time_slice/global_quantities/v_external', &
      'map <cocos> flip path="time_slice/global_quantities/v_external"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-p1d-darea-dpsi', rule_kind_cocos, &
      'time_slice/profiles_1d/darea_dpsi', &
      'map <cocos> flip path="time_slice/profiles_1d/darea_dpsi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-p1d-dpressure-dpsi', rule_kind_cocos, &
      'time_slice/profiles_1d/dpressure_dpsi', &
      'map <cocos> flip path="time_slice/profiles_1d/dpressure_dpsi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-p1d-dpsi-drho-tor', rule_kind_cocos, &
      'time_slice/profiles_1d/dpsi_drho_tor', &
      'map <cocos> flip path="time_slice/profiles_1d/dpsi_drho_tor"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-p1d-dvolume-dpsi', rule_kind_cocos, &
      'time_slice/profiles_1d/dvolume_dpsi', &
      'map <cocos> flip path="time_slice/profiles_1d/dvolume_dpsi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-p1d-f-df-dpsi', rule_kind_cocos, &
      'time_slice/profiles_1d/f_df_dpsi', &
      'map <cocos> flip path="time_slice/profiles_1d/f_df_dpsi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-p1d-j-parallel', rule_kind_cocos, &
      'time_slice/profiles_1d/j_parallel', &
      'map <cocos> flip path="time_slice/profiles_1d/j_parallel"; fixtures README "COCOS 11 -> 17"'), &
    ! Also rides the fold-p1d-j obsolescent-alias merge (DD3 has only
    ! `j_tor`/`j_phi` aliases collapsing here; see the module header).
    rule_entry('cocos-p1d-j-phi', rule_kind_cocos, &
      'time_slice/profiles_1d/j_phi', &
      'map <cocos> flip path="time_slice/profiles_1d/j_phi"; also rule "fold-p1d-j"; fixtures README "COCOS 11 -> 17" and Renames'), &
    rule_entry('cocos-p1d-psi', rule_kind_cocos, &
      'time_slice/profiles_1d/psi', &
      'map <cocos> flip path="time_slice/profiles_1d/psi"; fixtures README "COCOS 11 -> 17"'), &
    rule_entry('cocos-p2d-j-parallel', rule_kind_cocos, &
      'time_slice/profiles_2d/j_parallel', &
      'map <cocos> flip path="time_slice/profiles_2d/j_parallel"; fixtures README "COCOS 11 -> 17"'), &
    ! Also rides the fold-p2d-j obsolescent-alias merge; see cocos-p1d-j-phi.
    rule_entry('cocos-p2d-j-phi', rule_kind_cocos, &
      'time_slice/profiles_2d/j_phi', &
      'map <cocos> flip path="time_slice/profiles_2d/j_phi"; also rule "fold-p2d-j"; fixtures README "COCOS 11 -> 17" and Renames'), &
    rule_entry('cocos-p2d-psi', rule_kind_cocos, &
      'time_slice/profiles_2d/psi', &
      'map <cocos> flip path="time_slice/profiles_2d/psi"; fixtures README "COCOS 11 -> 17"') &
  ]

  public :: expected_verdict_for_kind, kind_name

contains

  ! Kind-to-verdict is fixed and stated once, here, rather than per entry:
  ! every kind this table carries expects the two sides to agree.
  function expected_verdict_for_kind(kind) result(verdict)
    integer, intent(in) :: kind
    character(len=6) :: verdict

    select case (kind)
    case (rule_kind_identical, rule_kind_renamed, rule_kind_moved, rule_kind_merged, rule_kind_split, rule_kind_cocos)
      verdict = 'same'
    case default
      error stop 'shim_rule_table: unhandled rule kind'
    end select
  end function expected_verdict_for_kind

  function kind_name(kind) result(name)
    integer, intent(in) :: kind
    character(len=9) :: name

    select case (kind)
    case (rule_kind_identical)
      name = 'identical'
    case (rule_kind_renamed)
      name = 'renamed'
    case (rule_kind_moved)
      name = 'moved'
    case (rule_kind_merged)
      name = 'merged'
    case (rule_kind_split)
      name = 'split'
    case (rule_kind_cocos)
      name = 'cocos'
    case default
      name = 'unknown'
    end select
  end function kind_name

end module shim_rule_table
