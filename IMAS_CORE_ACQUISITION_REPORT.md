# Getting IMAS-Core into the build: today's mechanism, and what a Rust middleware could take over

Scope: **acquisition and linking of IMAS-Core**, not the C ABI it exposes. The
question this answers is: IMAS-Fortran's CMake currently downloads/builds/installs
IMAS-Core for itself — if the architecture becomes
`IMAS-Fortran -> Rust middleware -> IMAS-Core`, should the Rust side take over that
job, and what would that look like? Part 1 documents the current mechanism in
enough detail to reuse or replace it deliberately. Part 2 lays out how a Rust
crate would normally do this (the `-sys` crate pattern) and what it would need to
match. Part 3 is limits. Part 4 is a recommendation.

This is about `middleware/` the crate (`imas-middleware`, the read-path DD
conversion shim already in the repo — see `CLAUDE.md`'s "Read-path middleware"
section) only insofar as it's the existing precedent for "Rust code linked into
`al-fortran`." It is not about extending that shim; it's about the separate
question of who fetches/builds/installs IMAS-Core.

---

## Part 1 — How IMAS-Fortran acquires IMAS-Core today

### 1.1 Two independent decisions, three outcomes

Two cache options, both declared in the top-level `CMakeLists.txt` (before
`project()`, since they affect the default install prefix — see `AL_IDS_SUBSET`'s
comment at `CMakeLists.txt:24-31` for why that ordering matters):

- `AL_DOWNLOAD_DEPENDENCIES` (default `ON`) — fetch al-core from git.
- `AL_DEVELOPMENT_LAYOUT` (default `OFF`) — use a sibling checkout, `../IMAS-Core`,
  instead. Sets `AL_DOWNLOAD_DEPENDENCIES=OFF` if both are somehow on
  (`CMakeLists.txt:16-20`).

Both off is the third outcome: **not fetched at all**, resolved instead via
`pkg-config` against an already-installed system package (`al-core` — see
`ALCore.cmake:3-13`). That branch is the only one of the three that does no
download and no in-tree build; it assumes IMAS-Core was built and installed
independently (e.g. an EasyBuild module or a distro package) and just needs a
CMake target (`al`) wired up: `pkg_check_modules(al REQUIRED IMPORTED_TARGET
al-core)` then `add_library(al ALIAS PkgConfig::al)`.

### 1.2 The FetchContent path (default, non-Windows)

This is the path a fresh clone takes with no flags. Two things happen, in this
order, and both matter:

**First**, in the top-level `CMakeLists.txt` (lines 113–131), *before*
`project(al-fortran ...)` is called:

```cmake
include(FetchContent)
if( ${AL_DOWNLOAD_DEPENDENCIES} )
  FetchContent_Declare(al-core
    GIT_REPOSITORY "${AL_CORE_GIT_REPOSITORY}"
    GIT_TAG        "${AL_CORE_VERSION}")
  FetchContent_MakeAvailable( al-core )
elseif ( ${AL_DEVELOPMENT_LAYOUT} )
  FetchContent_Declare(al-core SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../IMAS-Core")
  FetchContent_MakeAvailable( al-core )
endif()
```

`FetchContent_MakeAvailable` both populates the source (clones+checks out the tag,
or just points at the sibling directory) *and* calls `add_subdirectory()` on it
automatically, because IMAS-Core's own `CMakeLists.txt` defines a `project()` and
targets. That `add_subdirectory` is what actually builds `al` — the shared library
target IMAS-Core defines — and what makes IMAS-Core's own `install()` rules
(`CMakeLists.txt:265-331` in the IMAS-Core checkout: the library, headers,
`common/`, and an `imas_print_version` binary) fire as part of *al-fortran's*
`cmake --install`. There is no separate "install IMAS-Core" step a user runs —
installing al-fortran installs IMAS-Core into the same prefix, because it was
never `EXCLUDE_FROM_ALL`.

Nothing at this point has called `project(al-fortran ...)` yet — `VERSION` isn't
even known (that's `ALDetermineVersion.cmake`, run afterwards, from `git describe`,
independent of IMAS-Core). So this first fetch doesn't feed al-fortran's own
versioning; near as I can tell it exists so IMAS-Core's `al` target and its
transitive CMake state (compiler feature checks, `find_package` results IMAS-Core
itself needs) are available early, before `ALCommonConfig`/`ALBuildDataDictionary`
run.

**Second**, inside `ALCore.cmake` (included at `CMakeLists.txt:157`, i.e. *after*
`project()`), the exact same content is declared and made available **again** —
same `GIT_REPOSITORY`/`GIT_TAG` or same `SOURCE_DIR` — guarded only by the "not
both off" and "not Windows" conditions (`ALCore.cmake:54-80`, `99-102`):

```cmake
include(FetchContent)
FetchContent_Declare(al-core GIT_REPOSITORY ... GIT_TAG ...)   # or SOURCE_DIR
...
FetchContent_MakeAvailable( al-core )
get_target_property( AL_CORE_VERSION al VERSION )
```

On non-Windows this is redundant but harmless: `FetchContent_Declare` with
identical arguments is a silent no-op re-registration, and
`FetchContent_MakeAvailable` on already-populated, already-added content does
nothing further — that's documented behaviour, not something this repo relies on
by accident. It reads as leftover from an earlier version of the script (an
`AL_COMMON_PATH` variable this same block used to set, borrowing `common/` from
al-core before it was vendored into this repo, was removed at some point — see
`git log -p -- CMakeLists.txt`) rather than a deliberate two-stage design. Nothing
downstream depends on the *first* call specifically; `AL_CORE_VERSION` (the string
later reported and used to name the `.pc` file) is read from the target property
after the *second* call, inside `ALCore.cmake`.

The practical effect for someone extending this: **if you need "IMAS-Core is
available as a CMake target" earlier than `include(ALCore)`, it already is** —
just undocumented and doubled up. If you're refactoring this, the first block in
the top-level file is the one to question first; nothing currently reads what it
uniquely provides.

### 1.3 The Windows path — and a likely real bug in it

`ALCore.cmake` has a separate, `FetchContent`-free branch for `WIN32`
(`ALCore.cmake:14-53`): manual `execute_process(COMMAND git clone ...)` /
`git fetch` / `git checkout ${AL_CORE_VERSION}` into
`${CMAKE_CURRENT_BINARY_DIR}/_deps/al-core-src` (or the sibling `../IMAS-Core` for
dev layout), then later an explicit
`add_subdirectory(${al-core_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/_deps/al-core-build)`
(`ALCore.cmake:98`). The stated reason (`build.sh`'s comment, `CLAUDE.md`) is that
`al-core`'s generated `.pc` file uses a `--defsym` linker flag GNU `ld`
understands but that isn't Windows-specific — this branch predates that
explanation and looks like it's working around something else (likely
`FetchContent_MakeAvailable`'s automatic `add_subdirectory` not composing well
with something IMAS-Core's CMake does on Windows, e.g. vcpkg toolchain wiring —
see the vcpkg-specific block right after, `ALCore.cmake:85-97`, which only exists
for Windows).

The problem: **the top-level `CMakeLists.txt` fetch block (§1.2) has no `WIN32`
guard.** On Windows it still runs `FetchContent_Declare` + `FetchContent_MakeAvailable`
for `al-core` unconditionally, which — same as on Linux/macOS — populates
`_deps/al-core-src` *and calls `add_subdirectory()` on it automatically*, defining
target `al` and building into the default `_deps/al-core-build`. Then
`ALCore.cmake`'s `WIN32` branch runs its own manual clone into the very same
default path (`_deps/al-core-src`, explicitly hardcoded at `ALCore.cmake:17`) and
calls `add_subdirectory()` on it *again*, into the same default build directory
(`ALCore.cmake:98`). CMake rejects re-using a binary directory for a second
`add_subdirectory()` of the same (or any) source — this should hit a configure-time
error ("... is already used to build a source directory"), or at best a duplicate
`al` target definition error, before ever reaching the `al` target consumers need.

I have not run a Windows configure to confirm this fires in practice — CI only
builds Ubuntu (`CLAUDE.md`, `.github/workflows/build-and-test.yml`), which is
presumably why it's unnoticed. But the code paths are unambiguous enough that I'd
flag this to whoever last touched Windows support before building anything new on
top of it, especially if a Rust acquisition layer is meant to be cross-platform:
inheriting this exact double-fetch shape into Rust would double the bug rather
than fix it.

### 1.4 What "install" actually deposits

`cmake --install build --prefix ./install` installs, into one prefix:

- `al-fortran` + `al-identifiers-fortran` (this repo's targets, `CMakeLists.txt:524`)
- IMAS-Core's own `install()` targets — the `al` shared library, its headers, its
  `common/` data, `imas_print_version` — because they were pulled in via
  `add_subdirectory`, not `EXCLUDE_FROM_ALL`
- Three sets of generated `.pc` files (`al-fortran`, `al-fortran-<DD_VERSION>`,
  `al-identifiers-fortran`) plus `imas-*` symlink aliases for backward
  compatibility (`CMakeLists.txt:528-556`)

There's no separate "install IMAS-Core" step to intercept or replace in
isolation — it's structurally the same `cmake --install` invocation. Anything
that wants to *skip* installing IMAS-Core (e.g. because a Rust-managed IMAS-Core
was installed independently and should not be duplicated) would need
`EXCLUDE_FROM_ALL` on the `FetchContent_Declare` or on the `add_subdirectory`, or
a `pkg-config`-only path (§1.1's third outcome) so the "install" step never
touches an IMAS-Core built elsewhere.

### 1.5 What the *existing* Rust middleware needs from IMAS-Core — nothing

This is the load-bearing fact for Part 2. `middleware/src/lib.rs` declares
`extern "C" { fn al_read_data(...); fn al_begin_global_action(...); ... }` with no
`#[link(name = "al")]` and no build script (`middleware/Cargo.toml` — no
`build.rs`, no dependencies at all, `cargo build --locked --offline` per
`CLAUDE.md`). Those symbols are left unresolved by `cargo build` (`libimas_middleware.a`
is a `staticlib`, and a `staticlib`'s undefined externs are fine — they're not an
error until something actually links an executable/shared library from it). CMake
links `libal-fortran.so` from `libimas_middleware.a` *and* `al` on the same command
(`CMakeLists.txt:492,500`), so resolution happens once, at the very end, using
whatever `al` CMake already fetched. The crate never sees IMAS-Core's source,
headers, or build directory — not even a `-I` path. `cargo test` only works
because it separately stubs all six symbols under `#[cfg(test)]`
(`mod fake_core`, per `CLAUDE.md`).

So today, "Rust middleware" and "acquire IMAS-Core" are **already fully
decoupled** — not by an explicit design decision documented anywhere, but as a
side effect of the shim only ever calling C ABI functions by name and letting the
final link (owned entirely by CMake) supply them. Anyone proposing the Rust side
take over acquisition is proposing something genuinely new, not formalizing
something implicit.

---

## Part 2 — What a Rust-owned acquisition path would look like

If the Rust middleware (or a new crate alongside it) is meant to fetch/build/link
IMAS-Core itself — e.g. so the middleware can be built and tested as a standalone
Rust artifact outside al-fortran's CMake, or so a future non-Fortran consumer
(Python, a CLI) can reuse it — the standard shape for this in the Rust ecosystem
is a **`-sys` crate**: a thin crate (conventionally `imas-core-sys`) whose only
job is "make IMAS-Core's C ABI linkable from Rust," separate from the crate with
actual logic (`imas-middleware` here, analogous to `openssl-sys` vs `openssl`,
or `librocksdb-sys` vs `rocksdb`). A `build.rs` in that crate would need to
reproduce, in order, the same three-way decision §1.1 makes in CMake:

1. **Try `pkg-config` first** — the `pkg-config` crate (`pkg_config::Config::new().probe("al-core")`)
   mirrors `ALCore.cmake`'s system-install branch exactly: if IMAS-Core is already
   installed (module system, distro package, or a prior CMake install of this
   same repo), reuse it and emit nothing more than
   `cargo:rustc-link-lib`/`cargo:rustc-link-search`. Cheapest, most correct option
   when available, and the only one of the three that needs no build tool beyond
   the linker.
2. **Respect a "development layout" escape hatch** — an env var
   (e.g. `IMAS_CORE_SOURCE_DIR`, mirroring `AL_DEVELOPMENT_LAYOUT`'s
   `../IMAS-Core`) pointing at an already-built or buildable checkout, for the
   same reason CMake has one: local multi-repo development shouldn't require a
   fresh clone every time.
3. **Fetch and build from git otherwise** — clone at a pinned rev
   (`IMAS_CORE_GIT_REPOSITORY`/`IMAS_CORE_VERSION`, mirroring
   `AL_CORE_GIT_REPOSITORY`/`AL_CORE_VERSION`) into `$OUT_DIR`, then build with
   the `cmake` crate (`cmake::Config::new(path).build()`), which is a thin wrapper
   that still shells out to a real `cmake` binary — it does not remove CMake as a
   dependency, it just calls it from `build.rs` instead of from a parent
   `CMakeLists.txt`. Emit `cargo:rustc-link-lib=dylib=al` and
   `cargo:rustc-link-search=native=<cmake build dir>/lib` (or wherever IMAS-Core's
   `install()` puts it) after the build.

`bindgen` is not needed here the way it would be for a typical `-sys` crate,
since the middleware doesn't call into an IMAS-Core header — it only needs
symbol names and hand-written `extern "C"` signatures (already written, §1.5).
So this `-sys` crate's job is narrower than most: **link resolution and
acquisition only**, no FFI signature generation.

### What this buys that the current design doesn't have

- A `cargo build` (or `cargo test` with a *real*, non-fake `al-core`) that
  succeeds without CMake ever running — useful if the middleware, or logic that
  grows out of it, needs to be exercised or shipped independent of al-fortran's
  build.
- A place to put IMAS-Core version pinning that a pure-Rust consumer can read
  (`Cargo.toml`/env var) without parsing CMake cache variables.

### What it does not buy

- It does not remove CMake from the dependency chain — IMAS-Core is a CMake C/C++
  project; the `cmake` crate's `Config::build()` is calling the same `cmake`
  binary `FetchContent_MakeAvailable`'s `add_subdirectory` already drives, just
  from a different orchestrator.
- It does not by itself make the shim's ABI assumptions (`al_status_t` is 260
  bytes, returned indirectly — `CLAUDE.md`'s x86-64 ABI note) any more or less
  correct; that verification is orthogonal to who fetches the library.

---

## Part 3 — Limits

- **Two acquisition paths for one dependency is a correctness risk, not just
  duplicated effort.** If CMake fetches/builds IMAS-Core for `al-fortran` *and*
  a `-sys` crate independently fetches/builds IMAS-Core for the middleware, a
  build that links both (which is exactly the target architecture,
  `IMAS-Fortran -> Rust middleware -> IMAS-Core`) can end up with two different
  revisions of IMAS-Core in memory at once, or duplicate-symbol link errors, or —
  worse — silently link the CMake-built one everywhere via the final link line
  regardless of what the `-sys` crate fetched, quietly making its acquisition
  logic dead code. Anything built here needs a **single source of truth** for
  "which IMAS-Core revision," not two independently-configured ones that happen
  to agree today. The cheapest way to get that: have CMake pass its own
  `AL_CORE_VERSION`/`AL_CORE_GIT_REPOSITORY` into the `cargo build` environment
  it already invokes (`CMakeLists.txt:433-442`), and have the `-sys` crate's
  `build.rs` read those env vars rather than carrying its own separately-pinned
  defaults.
- **This breaks the middleware crate's current `--locked --offline` invariant**
  (`CMakeLists.txt:423-425`, `CLAUDE.md`) if added to `imas-middleware` directly.
  That invariant exists so a compute node with no outbound network gets a clear
  cargo error instead of a hang, and so `Cargo.lock` fully pins a *dependency-free*
  crate. A `-sys` crate that clones git repositories and shells out to `cmake`
  from `build.rs` is a fundamentally different offline story — it needs its own
  vendoring/pre-fetch strategy (e.g. require the source already present via
  `IMAS_CORE_SOURCE_DIR`, or a pre-populated `$CARGO_HOME` vendor directory) to
  keep the same guarantee, or the invariant has to be explicitly given up for
  that crate while the guidance in `CLAUDE.md` is updated to say so.
- **The Windows double-`add_subdirectory` issue (§1.3) is upstream of anything
  Rust does.** If cross-platform matters for the new architecture, it needs
  fixing (or at least confirming) independent of any Rust work, or a Rust-side
  fetch will just be layered on top of an already-broken Windows CMake
  configure.
- **`pkg-config` reuse on macOS has a known sharp edge already documented for
  this repo**: `playground/build.sh` links directly rather than via `pkg-config`
  specifically because the generated `.pc` file's `--defsym` linker flag is
  GNU-`ld`-only and macOS's `ld64` rejects it (`CLAUDE.md`, "playground/" section).
  A `-sys` crate's `pkg_config::probe()` call on macOS would hit the same flag if
  it parses `al-core.pc` (not `al-fortran.pc`, but worth checking IMAS-Core's own
  `.pc` for the same pattern before relying on it there) — this needs checking,
  not assuming, before leaning on `pkg-config` as the "cheap" option on macOS.
- **CI doesn't test any of this.** `.github/workflows/build-and-test.yml` builds
  Ubuntu/gfortran-14/HDF5 only. A `-sys` crate's git-fetch-and-cmake-build path is
  new surface with zero existing coverage; it would need its own CI job (and its
  own `--locked --offline` compute-node story) rather than inheriting the
  Fortran build's.
- **Versioning has to reconcile two build systems' idea of "the version."**
  `al-fortran`'s reported version (`ALDetermineVersion.cmake`, `git describe`) is
  independent of IMAS-Core's; the `.pc` files and generated code stamp DD/AL
  versions that come from CMake cache variables. A `-sys`-crate-driven IMAS-Core
  acquisition introduces a *third* version identity (whatever the crate fetched)
  that has no automatic path into what CMake reports installed. Divergence here
  is exactly the kind of silent-lie-about-what-was-built failure this repo is
  already careful about elsewhere (see `CLAUDE.md`'s two-DD-version section on
  why there's no free-text version override for the second `IDSDef.xml` — the
  same argument applies to a second, Rust-chosen IMAS-Core revision).

---

## Part 4 — Recommendation

**Don't move acquisition into Rust unless there's a concrete consumer that needs
IMAS-Core linkable without going through al-fortran's CMake.** The current
decoupling (§1.5) — the middleware never touches IMAS-Core acquisition at all,
CMake fetches/builds/installs it once, the final link resolves the shim's
`extern "C"` symbols against whatever CMake produced — is not an accident worth
undoing; it's the simplest correct answer to "how does Rust code get IMAS-Core,"
and it composes for free with every acquisition mode CMake already supports
(download, dev layout, system pkg-config, and whatever the Windows fix ends up
being). Duplicating that logic in a `-sys` crate only pays for itself if
something *outside* the CMake build needs to link IMAS-Core from Rust directly.

If that consumer exists (or is imminent) — e.g. a standalone Rust test harness
against a real IMAS-Core instead of `fake_core`, or a future non-Fortran binding
reusing the middleware's conversion logic — then:

1. **Put it in a separate `imas-core-sys` crate**, not in `imas-middleware`
   itself, so the existing shim keeps its `--locked --offline`, zero-dependency
   posture unchanged and its own CI story doesn't inherit a new network
   dependency.
2. **Make CMake the single source of truth for version/repository**, by having
   `CMakeLists.txt`'s existing `cargo build` invocation
   (`CMakeLists.txt:433-442`) pass `AL_CORE_VERSION`/`AL_CORE_GIT_REPOSITORY`
   through as environment variables the `-sys` crate's `build.rs` prefers over
   its own defaults, so a build driven by CMake never disagrees with itself about
   which IMAS-Core it linked.
3. **Try `pkg-config` first, unconditionally** — it's the one acquisition mode
   that adds no new fetch/build logic at all, matches `ALCore.cmake`'s own
   preference order, and sidesteps the macOS `.pc`/`ld64` question entirely if
   IMAS-Core's own `.pc` doesn't carry the problematic flag (worth a five-minute
   check before writing any `cmake`-crate code).
4. **Fix or confirm the Windows double-fetch (§1.3) before extending the pattern
   to a fourth acquisition path.** A `-sys` crate that also needs Windows support
   will otherwise be built and tested against a CMake baseline that may not even
   configure there.
5. **Treat the top-level `CMakeLists.txt` fetch block (§1.2) as a cleanup
   candidate regardless of what Rust does.** Nothing downstream reads what it
   uniquely provides over `ALCore.cmake`'s own fetch; removing the earlier one
   (or documenting why it must stay) removes one of the two things a new,
   Rust-side acquisition path would otherwise have to reconcile with.
