# Playground

Scratch space for trying out `al-fortran` (IMAS-Fortran) interactively, against a
locally built copy of the library.

## One-time setup

Build the library from the repo root, then install it to a local prefix
(default `<repo root>/install`, override with `IMAS_FORTRAN_PREFIX`):

```bash
cmake -B build
cmake --build build -j
cmake --install build --prefix ./install
```

A project-local install keeps each worktree/checkout self-contained, which
matters here since several parallel worktrees of this repo may build
different versions of the library at once — a shared install location (e.g.
`~/.local/imas-fortran`) would have them overwrite each other.

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
