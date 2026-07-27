# imas-projection-engine

The same-major Data Dictionary projection-engine substrate: a Rust library
behind a narrow, stable C ABI. Full design: issue #18. This crate
implements the skeleton scoped by issue #20, the schema-pair acquisition
scoped by issue #21, the process-wide cache reuse scoped by issue #22, the
bounded LRU eviction policy on that cache scoped by issue #28, the
operation lifecycle scoped by issue #31, and the rename-metadata-free
projection classifications scoped by issue #23 — not yet real rename
resolution (issue #24/#25) or loss accumulation (issue #27).

## Scope of this slice (#20, #21, #22, #28, #31, #23)

Implemented here:
- Opaque ABI handles (`pe_operation_t`, `pe_map_t`).
- Shared status (`pe_status_t`) and projection-verdict (`pe_verdict_t`)
  vocabulary, including the `PE_STATUS_SCHEMA_IDENTITY` and
  `PE_STATUS_CROSS_MAJOR` statuses added by #21, and the
  `PE_STATUS_RENAME_PENDING` status added by #23.
- One returned-string ownership convention (caller-provided buffer +
  required-length query), demonstrated by `pe_status_message` and reused
  by `pe_map_version`.
- Deterministic reset/read projection-entry instrumentation
  (`pe_instrumentation_reset` / `pe_instrumentation_read`).
- `pe_project_node_query` (#23, `src/projection.rs`): each schema in a
  `pe_map_t` is indexed once by its `field/@path` attribute
  (`ParsedSchema::field_index`, built alongside XML parsing). Given an
  explicit `pe_direction_t` selecting which schema plays source for that
  call, the query classifies `node_path` against the reciprocal index for
  the classifications that need no rename history:
  - unchanged (same path, matching `data_type`, no rename metadata) --
    `PE_VERDICT_SAME`;
  - compiled-only, stored-only (present in source, absent from target), or
    a datatype change (present in both, differing `data_type`) -- both
    report `PE_VERDICT_SKIP`, disambiguated only by which schema
    `direction` selected as source;
  - a node whose own field, or the identically-pathed field on the other
    schema, carries automatic rename metadata (`change_nbc_description` of
    `leaf_renamed`, `aos_renamed`, or `structure_renamed`) -- the distinct
    `PE_STATUS_RENAME_PENDING`, so it is never folded into a fabricated
    added/removed/same verdict. Full resolution is issue #24 (leaf
    renames, successive history) and issue #25 (array-of-structures,
    plain-structure renames, cascade).
  - a `node_path` unknown to the selected source schema --
    `PE_STATUS_INVALID_ARGUMENT`, since a real compiled walk only ever
    queries paths it already knows belong to its own schema.
  The contract test's shared nine-feature synthetic fixture pair (see its
  own doc comment in `tests/contract/test_contract.c`) carries every
  feature #18 names, including the five rename-bearing ones this ticket
  does not activate; only the four rename-metadata-free vectors above are
  asserted here so #24/#25 remain free to give the other five real
  verdicts without breaking this ticket's own vectors.
- `pe_map_acquire` / `pe_map_release` / `pe_map_version` (#21): given
  stored and working DD XML documents plus their claimed identities,
  parses both with `roxmltree`, resolves each schema's DD version (the
  XML `<version>` element is authoritative when present; a caller-supplied
  fallback is used only when it is absent), validates the resolved
  version against the claimed identity, and refuses to build a map for a
  cross-major pair. All four input buffers are borrowed only for the
  duration of the call; the engine copies what it needs to retain (see
  `src/schema.rs`).
- Process-wide schema-pair caching (#22, `src/cache.rs`): `pe_map_acquire`
  reuses one validated pair for repeated acquisitions of the same
  stored/working content, including with the roles swapped, instead of
  reparsing or rebuilding it. Every acquisition still returns its own
  independent, separately releasable `pe_map_t`; releasing one never
  invalidates another live handle backed by the same cached pair, and
  distinct pairs coexist independently with no mutable global "active" or
  "working" DD version. `pe_map_cache_identity` exposes an opaque token so
  a caller can prove reuse without this ABI exposing any Rust collection
  layout. See "Thread safety" below for this cache's concurrency posture.
- Bounded LRU eviction on that cache (#28, `src/cache.rs`): the cache holds
  at most `CACHE_CAPACITY` distinct pairs (a deliberately arbitrary,
  documented, non-production-tuned bound — sizing/throughput tuning stays
  out of scope per issue #18, and is issue #32's job). Reacquiring a
  cached pair through `pe_map_acquire` marks it most-recently-used without
  rebuilding it; acquiring enough additional distinct pairs evicts the
  single least-recently-used entry. Eviction only ever drops the cache's
  own reference to the immutable pair, so it can never invalidate a live
  `pe_map_t` handle (or an `Operation` retaining one) still referencing
  that pair — exactly as releasing another handle to the same pair
  already could not (#22). Reacquiring evicted content afterwards rebuilds
  it as a fresh, independent cache entry with its own new
  `pe_map_cache_identity`, without disturbing any other live pair. Proven
  entirely through the production ABI (`pe_map_acquire`/`pe_map_release`/
  `pe_map_cache_identity`) in the contract test, plus Rust-only unit tests
  against a small, locally constructed cache instance for the underlying
  LRU mechanics (see `src/cache.rs`'s `lru_tests`) — no new ABI surface
  was needed.
- Operation lifecycle tied to a map handle (#31, `pe_operation_begin` /
  `pe_operation_reset` / `pe_operation_end` / `pe_operation_release`):
  `pe_operation_begin` now requires a currently-live `pe_map_t` and
  retains an `Arc` reference to it (an O(1) refcount bump, never a clone
  of the immutable pair data or a mutation of it). `pe_operation_reset`
  clears operation-local state back to its post-begin state and is
  repeatable while the operation is active; `pe_operation_end` finalizes
  it as a one-time transition; `pe_operation_release` frees the handle,
  whether or not `pe_operation_end` ran first. Several operations against
  one map, or against distinct maps, stay live and isolated
  simultaneously. See "Operation/map ordering" below for the rule between
  releasing a map handle and the operations begun against it.
- A C contract test (`tests/contract/test_contract.c`), registered with
  CTest, that drives every capability above through the header only.

Deliberately **not** here (see the full #18 spec and issues #24, #25,
#26/#27): real rename resolution (leaf, successive history, array-of-
structures, plain-structure cascade, missing-subtree collapsing), context-
path/timebase-path substitution, loss accumulation and enumeration,
production cache sizing/throughput tuning (issue #32), Fortran types,
IMAS-Core, backend selection, or a Python runtime dependency.

## Operation/map ordering (#31)

An operation retains its own `Arc` reference to the map it was begun
against, captured once at `pe_operation_begin` time. Because of that, this
ABI places **no ordering requirement** between releasing a map handle and
the lifetime of any operation begun against it: a caller may call
`pe_map_release` before, during, or after an operation's own
reset/end/release calls, and the operation's lifecycle remains usable
regardless — `pe_operation_reset` and `pe_operation_end` keep working
against its retained map. `pe_project_node_query` has its final `(map,
operation, ...)` ABI shape and deliberately requires the same **live** map
handle supplied to `pe_operation_begin`, so callers must retain that map
handle until their projection queries finish. Symmetrically, releasing an
operation handle only ever touches this ABI's own operation registry and
never releases or otherwise invalidates the map handle it was begun against,
or any other live operation begun against that same map (see
`ffi::pe_operation_begin`/`pe_operation_release` and the
`operation_retains_its_map_after_the_map_handle_is_released` test in
`src/ffi.rs`). Every live map/operation handle also remains independently
releasable when several operations are begun against one map, or against
distinct maps, at the same time.

## Thread safety

The schema-pair cache added by #22 and bounded by #28 (`src/cache.rs`) is
one process-wide `Mutex<Cache>` (a `HashMap` plus a recency queue).
**Concurrent acquisition from multiple threads is supported and requires
no synchronization from the caller**: `pe_map_acquire`, `pe_map_release`,
and `pe_map_version`/`pe_map_cache_identity` may all be called
simultaneously from different threads for the same or different schema
pairs. Specifically:

- A cache lookup or insert holds the lock only for the HashMap/recency
  operation itself; the expensive XML parse/validate work runs outside the
  lock. Two threads racing to acquire the same new pair may both pay the
  parse cost, but only one insertion wins the shared cache slot, and every
  caller still gets back a handle backed by that one winning entry (see
  `cache::insert`).
- The cache itself always holds its own reference to a live entry (until
  that entry is evicted under LRU pressure — #28), so releasing one
  caller's `pe_map_t` can never invalidate another live handle referring
  to the same cached pair, regardless of release order or which thread
  releases first. Symmetrically, the cache evicting its own slot for an
  entry can never invalidate a live handle either (see the "Bound and LRU
  eviction" section above): a live `Arc` clone outside the cache keeps the
  data alive regardless of what the cache's own map/recency queue does.
- Cache lookup never establishes a mutable global "active" or "working" DD
  version; multiple distinct pairs are simply independent entries in the
  same map and do not affect one another's behaviour.

This crate makes **no throughput or lock-contention guarantee** beyond
that safety — sharding, striping, or otherwise tuning the cache under
heavy concurrent load is explicitly out of scope for this slice (see issue
#18's concurrency-tuning exclusion and issue #32's stress work).

The operation registry added by #31 (`ffi::active_operations`) follows the
identical pattern: one process-wide `Mutex<HashMap<..>>` retaining an `Arc`
per live `pe_operation_t`, plus a `Mutex`-guarded `ended` flag inside each
`Operation` for its own local state. **Concurrent
begin/reset/end/release/project_node_query calls from multiple threads are
supported and require no external synchronization**, whether they target
the same operation, different operations against the same map, or
operations against different maps — the same retain-under-lock pattern
used for maps (clone the `Arc` while holding the registry lock, then use it
after releasing the lock) is what lets a concurrent release never
invalidate a call already in flight. As with the map cache, this is a
memory-safety guarantee only; this crate makes no throughput guarantee
beyond it.

Map and operation ABI handles are process-unique opaque tokens, not exposed
Rust allocation addresses. A released token is never reused for a later
handle, so use-after-release is deterministically rejected even after new
maps or operations are created; the registry entries alone own the retained
`Arc`s and are dropped on release.

## Building

The crate is built through Cargo, invoked by CMake via
[Corrosion](https://github.com/corrosion-rs/corrosion) (fetched
automatically). From the repository root:

```bash
cmake -B build -DAL_RUST_ENGINE=ON -DAL_TESTS=ON
cmake --build build
ctest --test-dir build -R projection-engine-contract-test --output-on-failure
```

`AL_RUST_ENGINE` defaults to `OFF`, so a plain configure of the rest of
the project does not require `cargo` or network access to crates.io/GitHub
for Corrosion; pass `-DAL_RUST_ENGINE=ON` explicitly to build this crate.

To iterate on the crate directly: `cd engine && cargo test`.

## MSRV

`Cargo.toml` declares `rust-version = "1.76.0"`, matching the blessed ITER
Rust 1.76.0 module (see issue #18 §8). Issue #21 adds this crate's first
dependency, `roxmltree` (declared `rust-version = "1.60"`, well under this
crate's floor); when a later slice adds a cache crate, pick one whose own
declared `rust-version` stays at or below 1.76.0 — several mature crates
have raised theirs past it in recent releases. CI enforces this floor by
building this crate with an actual 1.76.0 toolchain (see
`.github/workflows/rust-engine-msrv.yml`); that job fails if the crate's
own code or any dependency requires a newer compiler, regardless of what
`rust-version` merely declares.

## ABI conventions

See the doc comment at the top of `include/imas_projection_engine.h` for
the normative version of these rules; this is a summary.

- **Status.** Every function returns `pe_status_t`. Non-`PE_STATUS_OK`
  means the documented effect did not happen.
- **String ownership.** The caller always provides the buffer. Query the
  required length with `buffer = NULL`, allocate `required_len + 1`
  bytes, call again. There is no engine-owned string the caller must
  free.
- **Panics never cross the ABI.** Every entry point is wrapped in a
  `catch_unwind` guard (`src/ffi.rs`) that reports `PE_STATUS_INTERNAL`
  instead of unwinding.
- **Unsafe is confined to `src/ffi.rs`.** `src/lib.rs` carries
  `#![deny(unsafe_code)]`; only `ffi.rs` locally re-allows it. This is a
  compiler-enforced version of the "normal logic is safe Rust" rule from
  issue #18.

## Negative-path test-output convention

This repo's CTest harness fails a test whose stdout/stderr matches, case
insensitively, `fault`, `error` not immediately followed by `_`,
`exception`, `severe`, `abort`, `segmentation`, `dump`, `logic_error`, or
`failed` — **even when the process exits 0**
(`common/cmake/ALExampleUtilities.cmake`). This engine's contract suite is
full of deliberate negative paths (null handles, undersized buffers,
unrecognized status codes), so it follows a wording convention instead of
opting individual tests out of the regex:

- Status and verdict identifiers themselves avoid those words (e.g.
  `PE_STATUS_INTERNAL`, not `PE_STATUS_INTERNAL_ERROR`), so printing them
  verbatim in a passing test's output is always safe.
- Diagnostic text in the contract test uses neutral wording — "unexpected
  result", "rejected", "status=<code>" — never the words above.
- This only matters for output printed while the test is still passing
  (exit 0). A genuine failure can print anything; CTest already fails it
  on the nonzero exit code.

Any later slice that adds contract-test vectors should keep following
this convention rather than reaching for per-test `FAIL_REGULAR_EXPRESSION`
overrides, unless a specific vector genuinely cannot avoid one of these
words in its expected output.
