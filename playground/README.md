# Playground

Scratch space for trying out `al-fortran` (IMAS-Fortran) interactively, against a
locally built copy of the library.

## One-time setup

Build the library from the repo root, then install it to a local prefix:

```bash
cmake -B build
cmake --build build -j
cmake --install build --prefix ./install
```

A project-local install keeps each worktree/checkout self-contained, which
matters here since several parallel worktrees of this repo may build
different versions of the library at once — a shared install location (e.g.
`~/.local/imas-fortran`) would have them overwrite each other.

## Choosing which build to play against

`build.sh` links against `<repo root>/install` by default. Point
`IMAS_FORTRAN_PREFIX` at another prefix to use a different build; a bare name
resolves against the repo root, so the prefixes CMake picks by default can be
named as-is:

```bash
IMAS_FORTRAN_PREFIX=install-equilibrium-two-dd ./build.sh play_equilibrium.f90
```

Those defaults are what `AL_IDS_SUBSET` / `AL_SECOND_DD_IDSDEF` builds install
to (see the root `CMakeLists.txt` — a subset or two-version library is
indistinguishable by name from a full one, so it may not share the default
prefix):

| Build | Prefix |
| --- | --- |
| full, one DD version | `install` |
| `-D AL_IDS_SUBSET=equilibrium` | `install-equilibrium` |
| `-D AL_IDS_SUBSET=equilibrium -D AL_SECOND_DD_IDSDEF=...` | `install-equilibrium-two-dd` |

`build.sh` reads the library name (`al-fortran-<DD version>`) back off the
prefix instead of pinning one, so a build of a different `DD_VERSION` links
without editing the script. With a wrong or unbuilt prefix it lists the
prefixes it can find under the repo root.

## Playing with a two-DD-version build

A two-version build is still a single library — the second DD version adds
modules, not a second `.so` — so nothing changes about linking. In the source,
`use` both front doors and pick a version by the *type* you declare:

```fortran
use ids_routines           ! default version, bare spellings
use ids_routines_v3_39_0   ! second version

type(ids_equilibrium)         :: eq_default
type(ids_equilibrium_v3_39_0) :: eq_second
```

`ids_put` / `ids_get` / `ids_deallocate` are one generic each and dispatch on
the argument's type, and each version's put path stamps its own DD version into
the data. Substitute the actual second version's suffix for `_v3_39_0`
(the `SECOND_DD_MODULE_SUFFIX` the configure step reports).

Two limits worth knowing before chasing a bug that is a known gap:
`ids_serialize` works for the default version only, and the identifier modules
are default version only. `tests/two_dd/` is the worked example of exercising
both versions end to end.

## Usage

```bash
cd playground
./build.sh play_magnetics.f90
./bin/play_magnetics
```

`play_equilibrium.f90` reads the checked-in DD 4.1.1 equilibrium fixture
(`imas-python-fixtures/fixtures/dd-4.1.1`, HDF5 backend) and prints every field
`equilibrium_seed.py` writes — it needs an install built with `DD_VERSION=4.1.1`
and `AL_BACKEND_HDF5=ON`, and must be run from `playground/` since the fixture
path is relative.

Add new `.f90` files here and build them the same way. `ids_routines` is the
main module to `use`; see `examples/` at the repo root for more usage patterns
(put/get, slices, validation, identifiers, ...).

Note: the generated `al-fortran.pc` pkg-config file includes a `--defsym`
linker flag that GNU ld understands but macOS's `ld64` does not, so
`build.sh` links directly instead of going through `pkg-config`.
