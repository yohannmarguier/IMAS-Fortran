# imas-projection-engine

The same-major Data Dictionary projection-engine substrate: a Rust library
behind a narrow, stable C ABI. Full design: issue #18. This crate currently
implements the skeleton scoped by issue #20 — the smallest callable
substrate, not the real projection logic.

## Scope of this slice (#20)

Implemented here:
- Opaque ABI handle (`pe_operation_t`).
- Shared status (`pe_status_t`) and projection-verdict (`pe_verdict_t`)
  vocabulary.
- One returned-string ownership convention (caller-provided buffer +
  required-length query), demonstrated by `pe_status_message`.
- Deterministic reset/read projection-entry instrumentation
  (`pe_instrumentation_reset` / `pe_instrumentation_read`).
- A representative entry point, `pe_project_node_query`, that validates
  its inputs and ticks the instrumentation counter but always reports
  `PE_VERDICT_SAME` — the real rename/skip computation is out of scope
  here.
- A C contract test (`tests/contract/test_contract.c`), registered with
  CTest, that drives every capability above through the header only.

Deliberately **not** here (see issue #21 and the full #18 spec): XML
parsing, rename-map construction/caching, real projection verdicts, loss
accumulation, Fortran types, IMAS-Core, backend selection, or a Python
runtime dependency.

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
Rust 1.76.0 module (see issue #18 §8). This crate has no dependencies yet;
when issue #21 adds XML/cache crates, pick versions whose own declared
`rust-version` stays at or below 1.76.0 — several mature XML/LRU crates
have raised theirs past it in recent releases. CI enforces this floor by
building this crate with an actual 1.76.0 toolchain (see
`.github/workflows/rust-engine-msrv.yml`); that job fails if the crate's
own code or any (future) dependency requires a newer compiler, regardless
of what `rust-version` merely declares.

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
