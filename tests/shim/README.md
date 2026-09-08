# The shim integration suite: how to read it, and why it is red

This suite asserts what the [IMAS-Multiversion-DD-Loader][shim] promises in
`docs/SHIM_INTEGRATION_CONTRACT.md`: a DD 4.1.1 HLI opens the checked-in
DD 3.39.0 pulse, and every conversion rule the map declares is checked through
`ids_get` and `ids_put`.

**It is expected to be red on arrival, and that is the design.** A contract
assertion states what the contract promises, not what the shim currently does.
When the two disagree the test fails, and that failure is a finding about the
shim — it is not inverted with `WILL_FAIL`, not moved out of the default run,
and not weakened to match observed behaviour. All three would leave the suite
green while proving nothing.

The cost of that decision is this file. Without a written record of which reds
are expected and why, a new contributor cannot tell an expected red from
something they just broke, and "red by design" stops being workable in
practice.

Scope decisions live in [`docs/adr/0002-shim-integration-test-suite.md`][adr2];
this file records the consequences a reader needs at the point of running the
tests.

## Running it

The suite is registered only when `AL_USE_MULTIVERSION_SHIM=ON`. With the
option off, the test list is exactly what it was.

```sh
ctest --test-dir build -L shim                 # the whole suite
ctest --test-dir build -L contract-assertion   # what the contract promises
ctest --test-dir build -L behaviour-pin        # accepted limitations, pinned
```

It needs nothing in your shell: `IMAS_CORE_LIBRARY`,
`IMAS_MVDD_HLI_DD_VERSION` and `IMAS_MVDD_LOSS_LOG_DIR` are injected per test.
Running a build-tree binary *by hand* does need them — see
`docs/adr/0001-multiversion-shim-linkage.md`.

Four tests need tooling this project does not build, and **skip registration
rather than fail** when it is missing, so a partial environment does not look
like a broken build. Watch for these lines at configure time:

- `al-fortran-test-shim-fixture-provenance` needs
  `imas-python-fixtures/.venv` and `h5diff`.
- `al-fortran-test-shim-stamp-{absent,malformed,mismatch-no-artifact}` need
  that same venv with `h5py`, to derive their stamp variants at build time.

A missing venv means those checks are skipped, never that they silently
passed — and note that red 9 below is one of them, so an environment without
the venv will report eight reds rather than nine.

Before reading any failure as a finding about conversion, confirm the library
really routes through the shim. A build that bypasses it compiles, runs, and
converts nothing:

```sh
otool -L build/libal-fortran-4.1.1.dylib | grep -E 'mvdd|libal'   # ldd on Linux
```

A genuine shim build lists `libimas_mvdd_loader` and **no** `libal`.

### The label scheme

Every test that asserts something carries `shim`, plus exactly one of:

| Label | Meaning | If it fails |
|---|---|---|
| `contract-assertion` | Taken from the contract and held whatever the shim currently does. | Either the shim disagrees with its contract, or you broke something. Check the red list below before assuming the latter. |
| `behaviour-pin` | Taken from observed behaviour the contract records as a limitation nobody intends to lift, held so a silent change fails loudly. | The limitation changed shape. That is worth knowing, but it is not a bug in the test — do not "fix" the expectation without reading why it was pinned. |

The torn write is the only behaviour pin in the suite.

The exception is the fixture-copy and loss-log-cleaning tests, which assert
nothing and exist to prepare a run. They are `FIXTURES_SETUP` for the tests
that need them, so CTest pulls them into a filtered run on its own — `ctest -L
behaviour-pin` selects two tests, the pin and the fixture copy it requires.
You never need to name them.

## Expected reds, with causes

**Nine tests are red.** With all optional tooling present `ctest -L shim`
registers 25 tests, of which 8 are fixture-setup helpers. Each entry below says
what fails, what the test prints, and why — so a failure that is *not* on this
list, or a listed test failing for a *different* reason, is a regression.

Observed on this branch against imas-mvdd-loader 0.1.0, with linkage confirmed
by `otool` (`libimas_mvdd_loader` present, no `libal`) so that these are
findings about conversion and not about a build that bypassed the shim.

Reading the verdicts: `same` means the two sides agree, `only3` / `only4` name
which side held a value alone, and `DIFF` means both held one and they differ.
Argument order differs per test, so trust the printed `expected=` rather than
inferring direction from the name.

### 1. `al-fortran-test-shim-refusal-rules` — `contract-assertion`

`REFUSAL-FAILURE: 8 refusal expectation(s) failed` — two failures for each of
the four `time_slice/constraints/{x_point,strike_point}/chi_squared_{r,z}`
paths, which the suite asserts are **served** and the shim refuses:

- `verdict=only4 expected=same` — no value arrives.
- `no unit-redefinition refusal is recorded for <path>` — this expectation
  states the *desired* condition, so it fails because a refusal **is** present.
  The shim logs `this path's unit was redefined and cannot be converted`.

They are marked `fidelity="unmappable"` in the conversion map's `<redefine>`
globs and refused at every seam. **That marking is itself the defect.** Both
fixtures hold the same number for these paths by construction, so there is
nothing a redefinition needs to apply and nothing to refuse. The assertion
says the two sides agree and stays red until the shim serves them
(tracked as issue #72).

Three artifacts in this repository describe the *current, defective* behaviour
and read like the contract if taken at face value — the map's `unmappable`
fidelity, contract §8.2's refusal-reason row "this path's unit was redefined
and cannot be converted", and `imas-python-fixtures/README.md`'s
"Redefinitions the map refuses". Do not take any of them as licence to invert
this assertion.

The one *genuine* refusal in this area is the `retyped` rule
(`grids_ggd/grid/space/coordinates_type`): an `INT_1D` cannot be reshaped into
an identifier struct array, so refusing it is correct, and that part of the
test passes.

### 2. `al-fortran-test-shim-nested-loss` — `contract-assertion`

`SCENARIO-FAILURE: expected one isolated loss log file, found 0` — the shim
writes no loss log file at all in this configuration.

Everything downstream of that check — the format marker, the column header,
the expected set of operation-fidelity-path rows — is therefore unreached
rather than disagreeing. When the shim starts writing the file, expect this
test to move on to those assertions rather than to pass outright.

Note that `check_nested_loss_log.cmake` deliberately does **not** list the four
`chi_squared` paths among the rows it expects, even though the shim emits them
as `UNMAPPABLE` today. Listing them would make the defect the expected result —
the test would pass for exactly as long as the shim refuses those paths, and go
red the day it starts serving them. They sit in a named known-defect set
instead, so both this test and the refusal-rules test fail on the defect and
both pass once it is fixed.

### 3. `al-fortran-test-shim-right-only-rules` — `contract-assertion`

`RIGHT-ONLY-FAILURE: 5 right_only rule(s) failed`, each `verdict=DIFF
expected=only4`:

| Rule | Path |
|---|---|
| `new-boundary-rho-tor` | `time_slice/boundary/rho_tor` |
| `new-constraints-chi-squared-reduced` | `time_slice/constraints/chi_squared_reduced` |
| `new-constraints-constraints-n` | `time_slice/constraints/constraints_n` |
| `new-constraints-freedom-degrees-n` | `time_slice/constraints/freedom_degrees_n` |
| `new-convergence-result` | `time_slice/convergence/result` |

These are DD-4-only quantities, so the expectation is that the DD 4 oracle
holds a value and the cross-version read serves nothing. Instead the shim
serves a value too, and it differs from the oracle's.

**This one needs a maintainer's decision rather than a shim fix, because the
suite currently contradicts itself about these five paths.**
`check_nested_loss_log.cmake` expects the shim to report every one of them as
`LOSSY` — that is, *served but degraded* — covering `time_slice/boundary/rho_tor`,
the three `time_slice/constraints/*` scalars, and `convergence/result` through
its `name`, `index` and `description` leaves. A rule table saying "DD 4 only"
and a loss-log expectation saying "served, lossily" cannot both be satisfied.
Either the rule table's `right_only` classification is wrong for them, or the
loss-log expectation is. Resolve which before treating this red as a shim
defect.

### 4. `al-fortran-test-shim-cocos-rules` — `contract-assertion`

`COCOS-FAILURE: 1 cocos rule(s) failed` — `cocos-j-phi-position-psi` on
`time_slice/constraints/j_phi/position/psi`, `verdict=only3 expected=same`:
the shim serves nothing.

The cause is one level up. The shim refuses the enclosing `j_phi`
arraystruct — `this path is served by several stored candidates, and only a
data read can try them in turn; DD path: time_slice/constraints/j_phi` — so no
leaf beneath it can arrive. The same message appears for `time_slice/ggd/j_phi`
and `time_slice/ggd/b_field_phi`.

The other COCOS paths in the table agree, so the sign-flip machinery itself is
working; this is a reachability failure, not a physics one.

### 5. `al-fortran-test-shim-structural-rules` — `contract-assertion`

`STRUCTURAL-FAILURE: 1 structural rule(s) failed` — `fold-axis-bphi` on
`time_slice/global_quantities/magnetic_axis/b_field_phi`, `verdict=only3
expected=same`: the shim serves nothing for this `merged` fold, and unlike
the COCOS failure above it logs **no refusal for that path at all**. It is
silent, which makes it the one red here that a value comparison is the only
witness to.

### 6. `al-fortran-test-shim-roundtrip-cross-dd` — `contract-assertion`

`SCENARIO-FAILURE: roundtrip changed the curated plasma current`. A curated
slice is written into a copy of the DD 3.39.0 pulse and read back; `ip` does
not survive the trip.

`al-fortran-test-shim-roundtrip-same-dd` — the identical slice into a copy of
the DD 4.1.1 pulse — **passes**. That control is what makes this red
meaningful: the roundtrip mechanics are sound, so the difference is conversion.

### 7. `al-fortran-test-shim-full-put-stamp` — `contract-assertion`

`SCENARIO-FAILURE: full put did not report the tolerated stamp refusal`. The
expected `REFUSED WRITE: 'ids_properties/version_put/data_dictionary'` line is
never printed and the put returns `0` rather than `PARTIAL_PUT`.

### 8. `al-fortran-test-shim-torn-write` — `behaviour-pin`

`TORN-WRITE-FAILURE: right_only write status was 0`, then
`SCENARIO-FAILURE: right_only write did not report PARTIAL_PUT`.

**Reds 7 and 8 share one underlying cause:** the shim refuses the write but
reports no status the HLI can see. Read-side refusals *are* reported — the
`IMAS-MVDD: …` refusal lines are plentiful on the read path — so this is
specifically the write path. Fixing one should turn both green.

### 9. `al-fortran-test-shim-stamp-malformed` — `contract-assertion`

`SCENARIO-FAILURE: malformed stamp did not refuse at open`. The contract
requires a malformed stored version stamp to be refused at open, before any
data seam is reached; the shim forwards instead.

`al-fortran-test-shim-stamp-absent` passes, and it asserts plain forwarding.
So the two are being **conflated** today: a malformed stamp is being treated
like an absent one. Keeping the two scenarios separate is what makes that
visible, and it is why they are registered as two tests rather than one.

---

Per standing project policy, defects the shim exposes in this HLI are
diagnosed and highlighted, not repaired here.

## Coverage boundaries

These are accepted gaps, not oversights.

### One direction only

The suite covers a DD 4.1.1 HLI reading and writing a DD 3.39.0 pulse, and
only that.

The reverse — a DD 3.39.0 HLI reading a DD 4.1.1 pulse — needs a from-scratch
build of this library at a different DD version, and no such build exists.
This is not a matter of adding a test; it is a second full build of
`al-fortran`, which is why the gap is recorded rather than filled.

**The cost is that the map's 23 `left_only` rules are unreachable.** They are
the rules for quantities DD 3 has and DD 4 does not, so only a DD 3 caller can
ask for them:

| Rule | Path |
|---|---|
| `drop-lcfs` | `time_slice/boundary/lcfs` |
| `drop-b-flux-pol-norm` | `time_slice/boundary/b_flux_pol_norm` |
| `drop-boundary-active-limiter` | `time_slice/boundary/active_limiter_point` |
| `drop-boundary-strike-point` | `time_slice/boundary/strike_point` |
| `drop-boundary-x-point` | `time_slice/boundary/x_point` |
| `drop-boundary-elongation-lower` | `time_slice/boundary/elongation_lower` |
| `drop-boundary-elongation-upper` | `time_slice/boundary/elongation_upper` |
| `drop-boundary-separatrix` | `time_slice/boundary_separatrix` |
| `drop-boundary-secondary-separatrix` | `time_slice/boundary_secondary_separatrix` |
| `drop-gap-identifier` | `time_slice/boundary_separatrix/gap/identifier` |
| `drop-timeslice-ggd-grid` | `time_slice/ggd/grid` |
| `drop-g11-cov` | `time_slice/coordinate_system/g11_covariant` |
| `drop-g11-contra` | `time_slice/coordinate_system/g11_contravariant` |
| `drop-g12-cov` | `time_slice/coordinate_system/g12_covariant` |
| `drop-g12-contra` | `time_slice/coordinate_system/g12_contravariant` |
| `drop-g13-cov` | `time_slice/coordinate_system/g13_covariant` |
| `drop-g13-contra` | `time_slice/coordinate_system/g13_contravariant` |
| `drop-g22-cov` | `time_slice/coordinate_system/g22_covariant` |
| `drop-g22-contra` | `time_slice/coordinate_system/g22_contravariant` |
| `drop-g23-cov` | `time_slice/coordinate_system/g23_covariant` |
| `drop-g23-contra` | `time_slice/coordinate_system/g23_contravariant` |
| `drop-g33-cov` | `time_slice/coordinate_system/g33_covariant` |
| `drop-g33-contra` | `time_slice/coordinate_system/g33_contravariant` |

**The condition that lifts this boundary** is the two-version-library track:
if `al-fortran` gains the ability to hold two Data Dictionary versions at once,
a DD 3.39.0 caller becomes available in-process and these 23 rules become
assertable. Until then, adding "the other direction" is not a small change.

### No tests at the C ABI

Everything goes through the `ids_get` / `ids_get_slice` / `ids_put` /
`ids_put_slice` front doors. No test binds to any `imas_mvdd_*` symbol, so a
non-shim build is provably unaffected.

The shim's own repository tests those seams against its own harness, and can
inject failures that are unreachable through the front doors. Duplicating them
here would test the shim's internals from the wrong side of the boundary while
proving nothing extra about what an HLI user experiences.

This has one non-obvious consequence. `ids_get` opens its operation context,
reads, and ends the action internally, so the context identifier never escapes
to the caller and the shim's per-context loss exports
(`imas_mvdd_context_loss_*`) are unreachable from this tier. The suite reads
the shim's **loss log file** instead.

### Others

[ADR 0002][adr2] records the remaining boundaries: subtree rules are asserted
on a sample of their paths (`new-contour-tree` on four of ten,
`new-constraints-j-parallel` on three of thirteen), so a shim serving *part* of
such a subtree would not be caught; and three `merged` folds
(`fold-constraints-j`, `fold-ggd-j`, `fold-ggd-bfield`) are asserted nowhere.

## Two refusal channels, and why you need both

The read-side skip log and the loss log file are **complementary, not
redundant**, and neither is a subset of the other. A consumer that reads only
one will miss things.

| | Read-side skip log | Loss log file |
|---|---|---|
| Where | `al_get_policy`, in-process, this HLI | `imas-mvdd-loss-<UTC>-<pid>.txt`, written by the shim |
| Records | **refusals** — paths the shim declined to serve (`status -1000`) | **fidelity outcomes** of a converting operation |
| Today's cross-version read | 24 entries, over 10 distinct DD paths | 14 `LOSSY` rows expected — and **0 written**, see red 2 |
| Capacity | first 64 entries retained, true total still reported | unbounded |

The divergence is structural, and sharper than "the two overlap imperfectly":
**the two sets are disjoint.** Not one of the 10 distinct paths the skip log
names appears among the 14 rows the loss file is expected to carry.

That follows from what each channel is for. A `LOSSY` path was *served*, in
degraded form, so there was nothing to skip — `time_slice/boundary/rho_tor` is
delivered, and a caller reading only the skip log never learns its fidelity was
reduced. A refused path was never served, so there is no fidelity outcome to
record — `grids_ggd/grid/space/coordinates_type` is named in the skip log and is
not among the loss file's rows.

A consumer that watches one channel is therefore blind to an entire class of
outcome, not merely to some of it.

Treat "was anything refused?" and "was anything degraded?" as two different
questions with two different sources.

## Asks of the shim

Three surfaces this suite depends on are not named by the contract. Each is a
place where a shim change could quietly break a downstream test, so each should
be promoted to a named surface rather than left as observed behaviour.

1. **The loss log file.** The suite asserts its format marker
   and its column header verbatim. Those are the **first and fifth lines of one
   five-line preamble**, not seven lines: line 1 is
   `# imas-mvdd loss log format 1`, lines 2–4 carry the write time, pid and HLI
   DD version, and line 5 is the tab-separated header
   `uri ids stored-dd hli-dd operation fidelity path`. (`check_nested_loss_log.cmake`
   calls it a "four-line preamble" and then reads the header at index 4 —
   counting the header separately. It reads the right line; the wording is what
   differs, and pinning the count is part of this ask.) It also asserts
   the seven-column row shape, and the directory semantics of
   `IMAS_MVDD_LOSS_LOG_DIR` — one file per recording process, the directory
   must already exist, and an empty directory means no loss. The contract
   describes the file, but as placement and format rather than as a frozen
   interface with a compatibility promise. Note for implementers: the header is
   a tab-separated *data* row, not a comment, so it must be skipped by
   position; a comment-prefix filter leaves it in and it is ingested as a loss
   entry.

2. **A flattened, machine-readable rule manifest.** `shim_rule_table.f90` is
   hand-authored, which is a liability: it can drift from the map without
   anything noticing. It is hand-authored because the map copy reachable outside
   the shim's own tree cannot be used — `docs/3.39.0--4.1.1.xml` carries two
   `<include href="../common/…"/>` references that resolve to nothing (the
   `common/` directory is absent from the published checkout), one of which
   carries the common renames. Generating from it would silently *under-cover*
   rather than fail, which is worse than authoring by hand. A flattened
   manifest — every rule resolved, no includes — would let the table be
   generated and drift be detected.

3. **A preflight check.** A dynamic-loading failure or an ABI mismatch surfaces
   as a generic error indistinguishable from an ordinary unknown failure. A
   misconfigured `IMAS_CORE_LIBRARY` therefore looks exactly like a contract
   violation, and in a suite that is deliberately red this is a real hazard: a
   reader can spend a long time investigating "the shim broke its contract"
   when the answer is that it never loaded a core at all. A cheap
   "am I wired up correctly" entry point would separate the two.

## This suite is in no CI job

**Shim mode runs in no CI job today, so these reds gate nothing.** Neither
`ci/build_and_test.sh` nor `.github/workflows/build-and-test.yml` sets
`AL_USE_MULTIVERSION_SHIM`.

That is deliberate, and wiring it up is a decision to take knowingly rather
than a default to fall into: the suite starts red, so adding it to CI as-is
turns the pipeline red on arrival. The options are to fix the reds above in the
shim first, or to gate the job on the subsets that are green while the
contract assertions are outstanding. Revisit [ADR 0002][adr2] before choosing —
it is where the decision belongs.

[shim]: https://github.com/yohannmarguier/IMAS-Multiversion-DD-Loader
[adr2]: ../../docs/adr/0002-shim-integration-test-suite.md
