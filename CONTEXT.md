# IMAS-Fortran

Vocabulary for the Fortran HLI of the IMAS Access Layer, and in particular for
what the HLI tells its caller after an operation that ran against a DD-version
conversion layer. Terms shared with the shim keep the shim's own definitions
(`IMAS-Multiversion-DD-Loader/CONTEXT.md`) rather than being restated in
different words; only HLI-side concepts are defined here.

## Language

### What an operation reports

**refusal**:
A shim-originated failure carrying `IMAS_MVDD_CONVERSION_ERROR` (`-1000`),
reaching the HLI through `al_status_t` at the call site that provoked it. The
HLI sees every one of these first-hand.
_Avoid_: error, loss, skip — a refusal is none of those; it is a failure the
HLI witnessed directly.

**loss**:
A non-exact outcome of a call that **succeeded**. It never reaches the HLI
through `al_status_t`; the shim's loss log is the only channel. A loss is not
an error and not a refusal.
_Avoid_: error, failure, data corruption — the read or write it describes
returned success and may have lost nothing at all.

**tolerated refusal**:
A refusal the generated traversal declines to abort on, leaving the field unset
(read) or its value undropped-but-unstored (write) and continuing. The HLI's
own contribution to the record; see `wrapper/al_get_policy.f90` and
`wrapper/al_put_policy.f90`.
_Avoid_: skip, ignored error — "skipped" describes only the read side, and
nothing is ignored.

**partial outcome**:
An operation that completed with at least one tolerated refusal, reported as
the positive statuses `PARTIAL_READ` or `PARTIAL_PUT` rather than a C-ABI
status. Derived from refusals only: a loss never produces a partial outcome,
because the data is complete and correct as far as anything can prove.
_Avoid_: partial failure, degraded read.

**torn write**:
The state a refused write leaves behind: the leaves written before the refusal
are still on disk, and a widened array of structures stays widened, because the
generated traversal has no rollback. Tolerating the refusal makes the write run
to the end; it does not undo this.
_Avoid_: partial write, corrupt occurrence — nothing is corrupt, and "partial"
already names the outcome the caller is told about.

### Where the record lives

**operation record**:
What the HLI retains about one `ids_get`/`ids_put` family call: its tolerated
refusals, gathered at the call sites, and its losses, drained from the shim
before the root context ends. Reset at the start of each operation, so it
describes one call and not the life of the process.
_Avoid_: log, journal, report — "loss log" already names the shim's own
structure, which is one of this record's two sources.

**operation serial**:
A monotonically increasing number identifying which operation an operation
record describes. Held both by the record and by the summary an IDS carries, so
a summary can never be served entries belonging to a different operation.
_Avoid_: generation, version, token.

**IDS summary**:
The few scalars an IDS object carries describing the operation record of the
last operation performed on it — its counts and its operation serial, not its
entries. It answers "did anything happen to this IDS", and the operation record
answers "what".
_Avoid_: attribute, log, embedded log — the entries are not on the IDS.

**loss log file**:
The tab-separated file the shim writes for itself, named
`imas-mvdd-loss-<UTC>-<pid>.txt` and sited by `IMAS_MVDD_LOSS_LOG_DIR`. A
separate channel from the per-context loss exports, and the only one an HLI
binding no `imas_mvdd_*` symbol can read. Its absence is a statement: no file
means no loss.
_Avoid_: loss log — that names the shim's per-context structure, which this
file is written from but is not.

### What a test asserts

**contract assertion**:
An expectation taken from `docs/SHIM_INTEGRATION_CONTRACT.md` and held whatever
the shim currently does. It stays red while the shim disagrees, and that red is
a finding about the shim rather than a fault in the test.
_Avoid_: expected failure, xfail — both name a test that passes while the
defect stands, which is the opposite arrangement.

**verdict**:
The classification a comparison assigns to one path: the two sides agree, only
one side has a value, the shape differs, or the required COCOS flip is absent.
`NOFLIP` is the last of those, and the only verdict whose name had to be chosen
against its own mechanism — the flip is what should have happened, so naming it
after the flip read as success.
_Avoid_: FLIP, result, status — the first is the name that caused the confusion,
and the other two are already taken by the shim's fidelity and by `al_status_t`.

**behaviour pin**:
An expectation taken from observed behaviour that the contract records as a
limitation nobody intends to lift, held so that a silent change in it fails
loudly. The torn write is the one this suite pins.
_Avoid_: regression test, characterisation test — accurate but silent about the
part that matters, which is that the pinned behaviour is agreed rather than
merely current.
