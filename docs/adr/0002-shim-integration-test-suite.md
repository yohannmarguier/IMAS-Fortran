# Testing the multiversion shim from this repository: one direction, one tier, red when the shim is wrong

ADR 0001 retargeted the CMake target `al` at the
[IMAS-Multiversion-DD-Loader](https://github.com/yohannmarguier/IMAS-Multiversion-DD-Loader)
and took as its success criterion that this repository's existing suite passes
**unmodified** through the shim. That proves the linkage and nothing else: at the
time it was written the shim forwarded every call untouched. Once the shim began
converting, "the suite still passes" stopped being evidence of anything, because
nothing in the suite reads a pulse held under a different Data Dictionary version.

What filled the gap was `playground/` — a standalone project built against an
installed shim, self-described as scratch, holding a 1225-line comparison program
and the only code anywhere in this repository that reaches the read path's
best-effort arm. `tests/shim/` held one linkage assertion and no behavioural test
at all. `tests/generator/test_put_policy.f90` says so in its own header: the
behavioural proof "needs a pulse held under a different Data Dictionary version
and a conversion layer to refuse a path, and lives in `playground/`".

The reference for what the shim promises is `docs/SHIM_INTEGRATION_CONTRACT.md`.

## Decision

A behavioural suite in `tests/shim/`, registered only when
`AL_USE_MULTIVERSION_SHIM=ON` and joining the main `ctest`, under four
constraints that are worth stating because each one closes a door.

**In-tree, not `playground/`.** The suite is registered with the rest of the
tests and moves with the repository. `playground/` remains scratch and becomes a
diagnostic: its comparison table is useful for a human reading a conversion, and
it is not the oracle.

**One direction: the DD 4.1.1 HLI reading and writing a DD 3.39.0 pulse.** The
reverse direction would need a from-scratch `DD_VERSION=3.39.0` build of
al-fortran, and no such build exists anywhere. The cost is exact and known: the
23 `left_only` rules are unreachable, and that is a coverage boundary rather than
an oversight.

**Tier 1 only — everything goes through `ids_get`/`ids_put`.** No tests at the C
ABI seam. Those exist in the shim's own repository, against its own harness, and
duplicating them here would test the shim's code with the shim's own assumptions
while adding a second place to keep them correct. This also has a consequence
that is not obvious: `ids_get` opens its operation context, reads, and calls
`al_end_action` internally, so the context id never escapes to the caller. The
four `imas_mvdd_context_loss_*` exports are therefore unreachable from Tier 1,
which is why the suite reads the shim's loss log *file* rather than draining the
log through its exports. No `imas_mvdd_*` symbol is bound anywhere in `wrapper/`,
and none is being added.

**A contract assertion stays red while the shim disagrees with the contract.**
The suite asserts what `SHIM_INTEGRATION_CONTRACT.md` promises, not what the
shim currently does. When the two differ, the test fails, and the failure is a
finding about the shim. It is not inverted with `WILL_FAIL`, not quarantined out
of the default run, and not softened to match observed behaviour — all three of
which would make the suite pass while the defect stands, which is the one
arrangement that teaches a reader to trust a green run that has proven nothing.
Distinguishing an expected red from a regression is handled by documentation and
`ctest` labels, not by suppression.

This is the mirror of the standing rule for the other side of the boundary:
shim-exposed defects *in this HLI* get diagnosed and highlighted rather than
repaired here. Defects in the shim get asserted against rather than accommodated.

## Considered options

**Leave the behavioural tests in `playground/`.** They already worked there, and
`playground/` can depend on an installed shim without complicating the main
build. Rejected because a standalone scratch project is not run by anyone
checking out this repository, and the one test that survived there
(`playground-play_eq_two_dd-cross`) rejects only the string `ERROR`, so it would
pass with every converted value wrong. Coverage nobody runs, asserting almost
nothing, is not coverage.

**Cover both directions.** Rejected on cost: a second full al-fortran build at a
different `DD_VERSION`, and an `.xsl` change in this repository already costs a
full regeneration. The 23 unreachable rules are recorded instead.

**Add Tier 2 tests at the C ABI.** Rejected as duplication of the shim's own
suite, which tests those seams directly and can inject failures this repository
cannot reach through `ids_get`.

**Mark the known-red assertions `WILL_FAIL`, or move them out of the default
run.** Rejected: both make the suite green today at the price of going red on the
day the shim is fixed, so someone must know to invert them. A red that turns
green when the defect is fixed needs no custodian.

**Organise the read tests by leaf.** The comparison program covers roughly 170 of
486 leaves, and completing it was the obvious next step. Rejected in favour of
organising by *rule*: the conversion map has 59 rules carrying 63 fidelity
declarations, a rule is what can actually be right or wrong, and a per-rule
expectation states what a leaf comparison only implies.

## Consequences

- The suite is expected to be red on arrival. At least the four
  `{x_point,strike_point}/chi_squared_{r,z}` paths are refused as `Unmappable`
  where the contract says they should be served. `tests/shim/README.md` carries
  the current red list with a cause for each, so a failure can be attributed
  without re-deriving it.
- Shim mode is in no CI job today, so nothing gates on these reds. If shim mode
  is ever added to CI, this decision has to be revisited *before* it is, not
  after.
- The rule table is hand-authored. The map is the authority, but the copy
  available outside the shim's own tree
  (`IMAS-Multiversion-DD-Loader/docs/3.39.0--4.1.1.xml`) has two `<include>`
  references that resolve to nothing, one of which carries the common renames —
  so generating the table from it would silently under-cover rather than fail.
  The suite therefore depends on three surfaces the shim does not yet name as
  contract: the loss log file's format, the rule set itself, and the failure mode
  of a misconfigured `IMAS_CORE_LIBRARY`. Those are recorded as asks in
  `tests/shim/README.md`.
- Fixtures are the oracle, which makes them load-bearing artefacts rather than
  test data. They are generated (`imas-python-fixtures/`) and checked in, so they
  can drift from their generator. The stamp variants the scenario checklist needs
  are therefore derived at build time rather than committed.
