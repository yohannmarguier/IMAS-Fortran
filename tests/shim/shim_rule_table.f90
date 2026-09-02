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
! the shim's implementation. This module carries two tables:
!
!   - `structural_rules`, the kinds whose verdict is "the two sides agree"
!     and whose subject matter is structural: identical, renamed, moved,
!     merged (the eight folds where both DD3 spellings carry real data) and
!     split;
!   - `right_only_rules`, the kind whose verdict is "a value on the DD 4 side
!     only" — the paths DD 4 introduced with nothing on the DD 3 side to
!     build them from, so the shim correctly serves nothing at all.
!
! Retyped and the COCOS-transform paths have their own verdicts and belong to
! later tickets (#68, #70, #72).
!
! Five further `merged` rules exist in the map (fold-constraints-j,
! fold-ggd-j, fold-ggd-bfield, fold-p1d-j, fold-p2d-j) whose only real DD3
! source is the deprecated `_tor` alias — imas-python-fixtures/README.md's
! own "Renames" table lists their targets alongside true renames for that
! reason. Two of those five targets (profiles_1d/j_phi, profiles_2d/j_phi)
! are themselves COCOS paths and so are asserted by ticket #68; the remaining
! three are not claimed by any rule-table ticket today. That gap is noted
! here rather than silently widening this table's scope to cover it.
module shim_rule_table
  implicit none
  private

  integer, parameter, public :: rule_kind_identical = 1
  integer, parameter, public :: rule_kind_renamed   = 2
  integer, parameter, public :: rule_kind_moved     = 3
  integer, parameter, public :: rule_kind_merged    = 4
  integer, parameter, public :: rule_kind_split     = 5
  integer, parameter, public :: rule_kind_right_only = 6

  type, public :: rule_entry
    ! Wide enough for the longest map rule id in either table
    ! ("new-global-quantities-rho-tor-boundary", 38). A structure constructor
    ! truncates silently, and a truncated id simply stops matching the name a
    ! test looks it up by, so this has headroom on purpose.
    character(len=48)  :: id
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

  ! The map's section 6, "DD4-only: nothing on the left to build these from",
  ! carries thirteen `right_only` rules, every one of them rooted under
  ! `time_slice`. Three are subtrees — `contour_tree` (10 paths),
  ! `constraints/j_parallel` (13 paths) and `convergence/result` (2 paths) —
  ! and the remaining ten are single leaves. Issue #63's rule/verdict table
  ! names this set "contour_tree/* and the 13 under time_slice"; the count of
  ! rules is thirteen with `contour_tree` among them, not alongside them.
  !
  ! Nothing here is a shim defect: the DD 3.39.0 pulse genuinely has no source
  ! for any of these, so serving nothing is the correct behaviour and this
  ! table asserts it. What the assertion buys is the other direction — the DD
  ! 4.1.1 fixture fills every one of them (imas-python-fixtures/README.md,
  ! "One reality, not two": a one-sided field is filled with a value belonging
  ! to this equilibrium, never a placeholder), so a `only4` verdict proves the
  ! oracle holds a real value that the shim did not invent.
  !
  ! ------------------------------------------------------------------------
  ! Expected reds on arrival: five entries return a value where nothing at all
  ! should arrive (contract assertions, not inverted or weakened - docs/adr/0002
  ! and issue #63's "Red by design").
  !
  !   new-boundary-rho-tor, new-constraints-chi-squared-reduced,
  !   new-constraints-freedom-degrees-n, new-constraints-constraints-n and
  !   new-convergence-result
  !
  ! come back `DIFF` rather than `only4`: the cross-version read reports a
  ! value present. It is not stored data - `h5ls -r` on the checked-in DD
  ! 3.39.0 pulse shows no dataset for any of the five - and it is not the
  ! invalid sentinel either. It is uninitialised memory, and it reads as such:
  ! both affected reals come back as the same 6.0135E-154, both affected
  ! integers as the same -932149305, and convergence/result/index as
  ! 538976288, which is 0x20202020 - four ASCII spaces, a blank-padded string
  ! buffer landing on an integer field.
  !
  ! That is worse than the failure mode issue #63's user story 37 asks the
  ! suite to catch. A refused field arriving as a default value would at least
  ! be a recognisable number; arriving as uninitialised memory means a caller
  ! testing `/= ids_real_invalid` concludes the field was served.
  !
  ! One correlation is worth recording for whoever chases it, offered as an
  ! observation and not as a root cause: each of the five sits immediately
  ! after an array of structures in its containing derived type, and the three
  ! `constraints` leaves follow `strike_point(:)` - the very array whose
  ! chi_squared_{r,z} the shim refuses during this same read, printing SKIPPED
  ! twice before these fields are filled. It is not the arraystruct-refusal
  ! double close: that fix is already in this branch. Not chased here, in
  ! keeping with the standing rule that a defect this suite exposes is
  ! diagnosed and asserted against rather than repaired from inside the test
  ! tree.
  ! ------------------------------------------------------------------------
  integer, parameter, public :: right_only_rule_count = 13

  type(rule_entry), parameter, public :: right_only_rules(right_only_rule_count) = [ &
    ! -- subtrees: DD 4 containers with no DD 3 counterpart at all --
    rule_entry('new-contour-tree', rule_kind_right_only, &
      'time_slice/contour_tree', &
      'map rule "new-contour-tree" (subtree, 10 paths); fixtures README change table row "- | contour_tree | new" and its "One reality, not two" bullet'), &
    rule_entry('new-constraints-j-parallel', rule_kind_right_only, &
      'time_slice/constraints/j_parallel', &
      'map rule "new-constraints-j-parallel" (subtree, 13 paths; added in DD 3.40.0); DD3 constraints has j_phi/j_tor and no j_parallel entry at all'), &
    ! Known red on arrival; see "Expected reds on arrival" above.
    rule_entry('new-convergence-result', rule_kind_right_only, &
      'time_slice/convergence/result', &
      'map rule "new-convergence-result" (subtree, 2 paths: result and result/index; added in DD 3.41.0)'), &
    ! -- boundary: three leaves DD 4 added to the selected-boundary struct --
    ! Known red on arrival; see "Expected reds on arrival" above.
    rule_entry('new-boundary-rho-tor', rule_kind_right_only, &
      'time_slice/boundary/rho_tor', &
      'map rule "new-boundary-rho-tor"; fixtures README "One reality, not two" bullet "boundary/rho_tor (DD 4 only)"'), &
    rule_entry('new-boundary-phi', rule_kind_right_only, &
      'time_slice/boundary/phi', &
      'map rule "new-boundary-phi"; equilibrium_v4_1_1.py _boundary, "New in DD 4 (rules new-boundary-rho-tor / -phi / -phi-poloidal-current)"'), &
    rule_entry('new-boundary-phi-poloidal-current', rule_kind_right_only, &
      'time_slice/boundary/phi_poloidal_current', &
      'map rule "new-boundary-phi-poloidal-current"; equilibrium_v4_1_1.py _boundary, same "New in DD 4" block'), &
    ! -- global_quantities: leaves added in DD 3.40.0, so absent from 3.39.0 --
    rule_entry('new-q-min-psi', rule_kind_right_only, &
      'time_slice/global_quantities/q_min/psi', &
      'map rule "new-q-min-psi" (added in DD 3.40.0, no counterpart in 3.39.0); equilibrium_v4_1_1.py "g.q_min.psi = flip(...) # DD 4 only, COCOS"'), &
    rule_entry('new-q-min-psi-norm', rule_kind_right_only, &
      'time_slice/global_quantities/q_min/psi_norm', &
      'map rule "new-q-min-psi-norm" (added in DD 3.40.0); equilibrium_v4_1_1.py "g.q_min.psi_norm = ... # DD 4 only"'), &
    rule_entry('new-global-quantities-rho-tor-boundary', rule_kind_right_only, &
      'time_slice/global_quantities/rho_tor_boundary', &
      'map rule "new-global-quantities-rho-tor-boundary" (added in DD 3.40.0); equilibrium_v4_1_1.py "g.rho_tor_boundary = ... # DD 4 only"'), &
    ! -- constraints: the DD 4 goodness-of-fit summary of the reconstruction.
    !    All three are known red on arrival; see "Expected reds on arrival"
    !    above. All three sit immediately after strike_point(:) in the
    !    generated constraints type, which is where that note starts. --
    rule_entry('new-constraints-chi-squared-reduced', rule_kind_right_only, &
      'time_slice/constraints/chi_squared_reduced', &
      'map rule "new-constraints-chi-squared-reduced" (added in DD 3.40.0); equilibrium_v4_1_1.py _constraints, "New in DD 4" block'), &
    rule_entry('new-constraints-freedom-degrees-n', rule_kind_right_only, &
      'time_slice/constraints/freedom_degrees_n', &
      'map rule "new-constraints-freedom-degrees-n" (added in DD 3.40.0); equilibrium_v4_1_1.py _constraints, "New in DD 4" block'), &
    rule_entry('new-constraints-constraints-n', rule_kind_right_only, &
      'time_slice/constraints/constraints_n', &
      'map rule "new-constraints-constraints-n" (added in DD 3.40.0); equilibrium_v4_1_1.py _constraints, "New in DD 4" block'), &
    ! -- profiles_1d: a normalised flux coordinate DD 4 stores explicitly --
    rule_entry('new-profiles-1d-psi-norm', rule_kind_right_only, &
      'time_slice/profiles_1d/psi_norm', &
      'map rule "new-profiles-1d-psi-norm" (added in DD 3.40.0); equilibrium_v4_1_1.py "p.psi_norm = ... # DD 4 only; a ratio, so no flip"') &
  ]

  public :: expected_verdict_for_kind, kind_name

contains

  ! Kind-to-verdict is fixed and stated once, here, rather than per entry.
  !
  ! `only4` is a verdict about argument order as much as about the data: the
  ! comparison primitives take the DD 4 side first and the shim-served side
  ! second, so `only4` means "the DD 4 oracle has a value and the shim served
  ! nothing". Callers asserting a right_only rule must pass the two reads in
  ! that order; the reverse order would report `only3` for the same reading.
  function expected_verdict_for_kind(kind) result(verdict)
    integer, intent(in) :: kind
    character(len=6) :: verdict

    select case (kind)
    case (rule_kind_identical, rule_kind_renamed, rule_kind_moved, rule_kind_merged, rule_kind_split)
      verdict = 'same'
    case (rule_kind_right_only)
      verdict = 'only4'
    case default
      error stop 'shim_rule_table: unhandled rule kind'
    end select
  end function expected_verdict_for_kind

  function kind_name(kind) result(name)
    integer, intent(in) :: kind
    character(len=10) :: name

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
    case (rule_kind_right_only)
      name = 'right_only'
    case default
      name = 'unknown'
    end select
  end function kind_name

end module shim_rule_table
