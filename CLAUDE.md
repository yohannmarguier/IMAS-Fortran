# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The Fortran High Level Interface (HLI) of the IMAS Access Layer. It exposes Fortran
derived types and `ids_get`/`ids_put`-style routines for every IDS in the
[IMAS Data Dictionary](https://github.com/iterorganization/IMAS-Data-Dictionary), and
delegates all I/O to [IMAS-Core](https://github.com/iterorganization/IMAS-Core)
(the "AL core") through a C ABI.

**Almost none of the library is checked in.** Roughly 10 hand-written Fortran files
plus a set of XSLT stylesheets generate hundreds of thousands of lines of Fortran at
configure/build time from the DD's `IDSDef.xml`. Fixing a bug in the library almost
always means editing an `.xsl`, not a `.f90`.

## Build and test

```bash
# Configure (fetches IMAS-Core + DD from GitHub over SSH by default)
cmake -B build -D CMAKE_INSTALL_PREFIX=$PWD/test-install
cmake -B build --preset=https        # same, but HTTPS clone URLs

cmake --build build -j8              # or: make -C build -j8 all
ctest --test-dir build --output-on-failure
cmake --install build
```

Compilers are picked up from `CC`/`CXX`/`FC` **at first configure only** — to change
them, delete the build directory. Default `CMAKE_BUILD_TYPE` is `RelWithDebInfo`.

Running a subset of tests:

```bash
ctest --test-dir build -R al-fortran-test-equilibrium   # one generated IDS test
ctest --test-dir build -R example-fortran-              # the hand-written examples
ctest --test-dir build -R shim-linkage
```

The suite writes into a pulse database keyed off `$USER`; CI points `USER` at a
throwaway directory (`export USER="$(pwd)/testdb"`) so tests don't pollute the real
one. Do the same locally when running the full suite.

`ci/build_and_test.sh` is the reference invocation (ITER Bamboo, module-based);
`.github/workflows/build-and-test.yml` is the Ubuntu/GCC-14 HDF5-only equivalent.

### Where dependencies come from

Four mutually exclusive acquisition modes, all resolved in `common/cmake/ALCore.cmake`,
which exists to answer one question — *what does the CMake target name `al` refer to*:

| Mode | Option | `al` is |
|---|---|---|
| Download (default) | `AL_DOWNLOAD_DEPENDENCIES=ON` | IMAS-Core fetched by `FetchContent` and added as a subproject |
| Development layout | `AL_DEVELOPMENT_LAYOUT=ON` | sibling `../IMAS-Core` checkout as a subproject |
| Installed | both `OFF` | `PkgConfig::al` from an installed `al-core` module |
| Shim | `AL_USE_MULTIVERSION_SHIM=ON` | the IMAS-Multiversion-DD-Loader, found via `find_package(imas-mvdd-loader CONFIG)` |

`AL_DEVELOPMENT_LAYOUT=ON` force-disables `AL_DOWNLOAD_DEPENDENCIES`. The recommended
dev layout clones `IMAS-Core`, `IMAS-Data-Dictionary`, `IMAS-Core-Plugins` and this
repo as siblings.

Other frequently used options: `AL_TESTS`, `AL_EXAMPLES` (both `ON`), `AL_PLUGINS`
(`OFF`), `AL_HLI_DOCS` / `AL_DOCS_ONLY`, `AL_BACKEND_HDF5` / `AL_BACKEND_MDSPLUS` /
`AL_BACKEND_UDA`, `DD_VERSION`, `AL_CORE_VERSION`.

## Code generation pipeline

Everything runs through `common/xsltproc.py` (a Saxon-HE CLI clone using `saxonche`,
pip-installed into a `build/dd_build_env` venv that `ALBuildDataDictionary.cmake`
creates at configure time).

- `common/cmake/ALBuildDataDictionary.cmake` acquires the DD and produces `IDSDEF`
  (path to `IDSDef.xml`), `IDS_NAMES`, `DD_VERSION`, `DD_SAFE_VERSION` — used
  *at configure time*, so changing the DD version means re-configuring.
- `IDSDef2F90Routines.xsl` → `ids_routines.f90`, `ids_utilities.f90`, the
  `utilities_*_struct.f90` files, and per-IDS `<ids>_{get,put,put_slice,get_slice,
  delete,copy_struct,deallocate_struct,validate}.f90`.
- `IDSDef2F90TypeDef.xsl` → `ids_types.f90`, `ids_schemas.f90`, `<ids>_schema.f90`.
- `identifiers.xsl` (+ `common/identifiers.common.xsl`) → one module per
  `*_identifier.xml` in the DD, built into the separate `al-identifiers-fortran`
  library.
- `tests/generator/IDSDef2TestSuite.xsl` → a full round-trip test program per IDS.

Both generation steps use the dummy-output-file trick (`src/dummy.txt` + `BYPRODUCTS`)
so the hundreds of generated sources aren't regenerated on every build. They *are*
regenerated whenever `IDSDef.xml` or an `.xsl` changes.

Generated output lands in `build/src/`, `build/identifiers/src/`,
`build/tests/generator/src/` — read those to see what an XSL change actually produced.

## Hand-written code

- `wrapper/al_low_level_wrap.f90` — the only place the C ABI is declared:
  `iso_c_binding` interfaces to `al_*` from `al_lowlevel.h`, plus the
  Fortran↔`c_ptr` marshalling the generated code calls. Adding or changing an
  AL core entry point starts here.
- `wrapper/al_defs.f90` — backend IDs, operation/interpolation/pulse-access
  constants, error codes, `MAXDIM`.
- `tests/generator/{comparator,generator,helper,setter}.f90` — the fill/compare
  helpers the generated per-IDS tests link against.
- `examples/*.f90` — hand-written scenario programs, also registered as ctest tests.
- `common/` is a copy of assets shared across the traditional HLIs (cmake modules,
  `xsltproc.py`, common XSL, common docs); changes there generally belong upstream too.

## Targets and artefacts

`al-fortran` (library name `al-fortran-<DD_VERSION>`, so several DD versions can be
installed side by side), `al-identifiers-fortran`, plus `.pc` files with
`imas-*.pc` backward-compatibility symlinks. Module files install to
`include/fortran`. `al_env.sh` is installed for consumers to source.

## Multiversion shim mode

`-D AL_USE_MULTIVERSION_SHIM=ON` retargets `al` at the
[IMAS-Multiversion-DD-Loader](https://github.com/yohannmarguier/IMAS-Multiversion-DD-Loader),
which mirrors IMAS-Core's C ABI symbol for symbol and `dlopen`s the real IMAS-Core at
run time. No source and no link line in this repository changes; the whole test suite
must pass unmodified through it. Rationale in
`docs/adr/0001-multiversion-shim-linkage.md`. Things that bite:

- **A NAG build silently bypasses the shim.** The NAG branch in `CMakeLists.txt`
  hardcodes `-lal -L<dir>` instead of linking the `al` target, so it links IMAS-Core
  regardless of the option, with no error. Once the shim converts data, the only
  symptom is data that was never converted.
- IMAS-Core is still needed *at run time*. `common/cmake/ALCoreRuntime.cmake` builds
  one as an `ExternalProject` under `build/_deps/al-core-runtime-build` (it must be an
  ExternalProject, not FetchContent: IMAS-Core's own target is also called `al`), or
  point `-D AL_CORE_RUNTIME_LIBRARY=/path/to/libal.so` at an existing one.
- ctest gets `IMAS_CORE_LIBRARY` injected via `AL_CORE_TEST_ENVIRONMENT`, so the suite
  needs nothing in the shell. **Running a build-tree binary by hand does** — export
  `IMAS_CORE_LIBRARY` yourself or the loader won't find IMAS-Core.
- `AL_BACKEND_MDSPLUS` is a hard error in this mode (the MDSplus model is a target
  IMAS-Core builds as a subproject). Backend options must be passed explicitly since
  IMAS-Core's cache options aren't declared; they are forwarded to the run-time core.

## Test conventions worth knowing

- Generated tests pass by *not printing* — `FAIL_REGULAR_EXPRESSION "[Ee][Rr]..."`. A
  test that produces no output and does nothing still passes; check that a test is
  actually exercising what you think.
- Examples are ordered with ctest fixtures: `*put*` tests are `FIXTURES_SETUP` for the
  matching `*get*` tests, and the plugin tests depend on `test_magnetics_get`. Tests
  share data entries, so the example suite is **not** parallel-safe.
- Examples matching `get|put|create|empty|_plugin` are auto-`DISABLED` unless both
  HDF5 and MDSplus backends are on.
- `error_on_missing_tests` makes a new `examples/*.f90` a configure error until it is
  added to the `TESTS` list in `examples/CMakeLists.txt`.
- Generated tests run with `IMAS_AL_DISABLE_VALIDATE=1` and
  `IMAS_AL_DISABLE_OBSOLESCENT_WARNING=1`.

## Auxiliary

`imas-python-fixtures/` builds two fully-populated `equilibrium` HDF5 pulses — DD
3.39.0 and DD 4.1.1 — from a single set of values, so the 4.1.1 fixture is an
independently derived expected result for a 3→4 conversion (including COCOS 11→17 sign
flips). `python equilibrium_seed.py` regenerates them; see its README.

Contributions go through a fork + feature branch off `develop`, with an issue opened
first (see `CONTRIBUTING.md`).
