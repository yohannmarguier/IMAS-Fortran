# Playground

Scratch space for trying out `al-fortran` (IMAS-Fortran) interactively, against a
locally built copy of the library.

## One-time setup

Build the library from the repo root, then install it to a local prefix
(default `~/.local/imas-fortran`, override with `IMAS_FORTRAN_PREFIX`):

```bash
cmake -B build
cmake --build build -j
cmake --install build --prefix ~/.local/imas-fortran
```

## Usage

```bash
cd playground
./build.sh play_magnetics.f90
./bin/play_magnetics
```

Add new `.f90` files here and build them the same way. `ids_routines` is the
main module to `use`; see `examples/` at the repo root for more usage patterns
(put/get, slices, validation, identifiers, ...).

Note: the generated `al-fortran.pc` pkg-config file includes a `--defsym`
linker flag that GNU ld understands but macOS's `ld64` does not, so
`build.sh` links directly instead of going through `pkg-config`.
