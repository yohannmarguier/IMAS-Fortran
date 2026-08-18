# Routing the Fortran HLI through the multiversion shim by retargeting `al`

[IMAS-Multiversion-DD-Loader](https://github.com/yohannmarguier/IMAS-Multiversion-DD-Loader)
re-exports IMAS-Core's public C ABI symbol for symbol and resolves the real
IMAS-Core at run time through `dlopen`/`dlsym` (see that project's
`docs/adr/0001-runtime-binding-not-linking.md`). For this HLI to route through it,
something in this build has to stop handing the wrapper's `iso_c_binding`
interfaces to IMAS-Core and hand them to the shim instead — without the wrapper,
the generated sources or the link line knowing that anything changed.

`common/cmake/ALCore.cmake` already owns exactly that question. It answers "what
does the target name `al` refer to" differently per acquisition mode: a
`PkgConfig::al` alias for an installed IMAS-Core, a real target from a fetched or
sibling checkout added as a subproject. Everything downstream links `al`.

## Decision

A fourth acquisition mode, behind `AL_USE_MULTIVERSION_SHIM` (default `OFF`):
`find_package(imas-mvdd-loader CONFIG)`, an `INTERFACE` library named `al` that
links the shim's imported target, then return without acquiring IMAS-Core at all.
The shim is discovered through its installed CMake package, the same way the
pkg-config mode discovers an installed IMAS-Core.

The `INTERFACE` library rather than `add_library(al ALIAS
imas-mvdd-loader::imas-mvdd-loader)` — which is the shape the pkg-config mode uses
— is a portability detail, not a design difference: aliasing a *non-`GLOBAL`*
imported target, which is what a config package creates, requires CMake 3.18, and
this project declares `cmake_minimum_required(VERSION 3.16)`.

`target_link_libraries( al-fortran al )` in the top-level `CMakeLists.txt` is
unchanged, which is the property that makes the other acquisition modes provably
unaffected: with the option off, not one line of the previous behaviour is
reached.

Because the shim forwards every call unchanged at this point, the success criterion
is exact — this repository's existing test suite must pass **unmodified** through
it. It does (see the Consequences below for what "unmodified" does and does not
cover), which proves the linkage before any DD path is ever rewritten.

## Considered options

- **Ship the shim under IMAS-Core's own library name** (`libal.so`), so an
  unmodified HLI build links it by accident of naming. Rejected on four counts,
  the first two decisive:
  - It makes the shim's own design impossible. The shim must open the *real*
    IMAS-Core at run time. If the shim is itself `libal`, the loader's search for
    IMAS-Core can find the shim, and the shim's outbound `al_read_data` can bind
    back to its own export — the unbounded recursion the shim rejected link-time
    binding to avoid.
  - It makes the substitution invisible. Two different libraries sharing one name
    means no dependency listing, `.pc` file, or built artefact can say which of
    them is in the call path. That is precisely the diagnostic this ticket needs
    to preserve, and the NAG hazard below shows why.
  - It is a system-wide substitution, not a per-build choice: no way to keep a
    converting build and a direct build side by side on one machine.
  - It collides with IMAS-Core's own packaging — same soname, same `.pc` name.
- **Link the shim in addition to `al`.** Rejected: every mirrored `al_*` symbol
  would then have two definitions on the link line and load-order would decide
  which one wins, per platform and per build.
- **`LD_PRELOAD`-style interposition.** Rejected for the same reason the shim
  itself rejected it: nothing in the HLI's build would record that interposition
  is happening, and it is platform-specific.
- **Retargeting the `al` target name — chosen.** One branch in the module that
  already owns the question, no change to the link line, no change to any source
  file, and the substitution is visible in the built library's dependencies.

## Consequences

- **The shim must be installed and found.** Point `CMAKE_PREFIX_PATH` (or
  `imas-mvdd-loader_DIR`) at its install prefix. `find_package` is `REQUIRED`, so a
  missing shim fails at configure time rather than silently falling back.
- **No IMAS-Core is *linked into* a shim build, but one is still acquired.** The
  shim carries no link-time dependency on it, so nothing links it — and the first
  version of this decision concluded from that that nothing needed to acquire it
  either. That was wrong, and it was wrong in the one way a build system can be:
  the shim mirrors IMAS-Core's ABI and implements none of it, so with no IMAS-Core
  present it fell back to the bare soname, the dynamic loader found nothing, and
  every test in the suite failed at its first `al_*` call. A shim build now builds
  an IMAS-Core it never links, in `common/cmake/ALCoreRuntime.cmake`, as a separate
  CMake project — a subproject would define the target name `al`, which is the name
  this decision gives the shim. Three things still follow from IMAS-Core not being
  a *subproject*, all of them matching how the existing pkg-config mode behaves:
  - The plugin framework (`AL_PLUGINS`) is not acquired; it is fetched alongside
    IMAS-Core. The `-with-plugins` example variants therefore cannot run in a shim
    build, so the acceptance run below covers the suite without them.
  - The Sphinx documentation build (`AL_HLI_DOCS`) is likewise not reached, for the
    same reason and with the same precedent.
  - IMAS-Core's own cache options are not declared — notably `AL_BACKEND_HDF5` and
    friends, which `tests/generator/CMakeLists.txt` reads to build its backend
    matrix. Pass them explicitly to keep the generated test matrix the same as a
    direct build's; otherwise the suite still passes, but over fewer backends.
    `ALCoreRuntime.cmake` forwards the same values to the IMAS-Core it builds, so
    one spelling covers both the matrix and the library that has to serve it. This
    is the one place where "the suite passes unmodified" rests on an option the
    operator re-passes rather than on construction — declaring IMAS-Core's backend
    defaults here would be this build asserting support it cannot verify.
    `AL_BACKEND_MDSPLUS` is the exception that cannot be re-passed at all: the tests
    and examples need the `al-mdsplus-model` target, which IMAS-Core builds, so a
    shim build rejects it at configure time rather than failing obscurely later.
  - `AL_CORE_VERSION` is left at whatever was configured, and the generated
    `al-fortran-<DD>.pc` still names `al-core` in `Requires:` — which is where the
    dependency still is, since the shim opens IMAS-Core at run time. Naming the
    shim there as well is deferred until installing a shim build is in scope.
- **The linkage is inspectable, and a test pins it.**
  `al-fortran-test-shim-linkage` (`tests/shim/`, registered only in a shim build)
  fails unless `libal-fortran` records the shim as a dynamic dependency. A build
  whose link line was bypassed would pass every functional test while showing
  nothing there. It is the one test a shim build has that a direct build does not,
  which is a deliberate exception to "the suite is unmodified": it asserts a
  property that only exists in this mode.
- **A NAG build silently defeats this.** The NAG branch in the top-level
  `CMakeLists.txt` does not link the `al` target; it hardcodes `-lal` and a search
  path. Retargeting `al` therefore has no effect on it, and a NAG build links
  IMAS-Core directly with no error and no warning — once the shim carries
  conversion logic, the only symptom is data that was never translated. This is
  documented at that branch rather than fixed: any fix has to be verified with a
  NAG toolchain, which this project does not have, and an unexercised guard is
  not an improvement over a loud comment.
- **The other four HLIs are expected to follow this pattern.** Each has a build
  that names IMAS-Core somewhere; the pattern is to retarget that name behind an
  equivalent default-off option, leaving the link line alone, rather than to teach
  each HLI about the shim. Concentrating the integration in the name-resolution
  step is what keeps the cost at one branch per HLI.
