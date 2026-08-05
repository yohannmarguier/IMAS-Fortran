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

## Debugging in CLion

Programs are always compiled `-g -O0 -fbacktrace`, so any playground binary can be
run under a debugger as built. `IMAS_FORTRAN_FFLAGS` appends to that:

```bash
IMAS_FORTRAN_FFLAGS='-fcheck=all -ffpe-trap=invalid,zero' ./build.sh play_equilibrium.f90
```

That is enough for `lldb ./bin/play_equilibrium` from a terminal. For an IDE,
`build.sh` has one shortcoming it cannot fix: a binary built outside CMake is
invisible to the project model, so the IDE has to be told about it by hand — a
custom build target, an external tool, a run configuration whose executable is a
literal path. `-D AL_PLAYGROUND=ON` avoids all of that by building the programs
here as ordinary CMake targets:

```bash
cmake -B build-eq -D AL_IDS_SUBSET=equilibrium -D AL_PLAYGROUND=ON
cmake --build build-eq --target play_equilibrium -j
( cd playground && ../build-eq/playground/play_equilibrium )
```

In CLion: add `-D AL_PLAYGROUND=ON` to the CMake profile (Settings → Build,
Execution, Deployment → CMake → *CMake options*), reload, and `play_equilibrium`
appears as a target with a run configuration CLion generates itself — Run and Debug
both work with nothing hand-written. **Set the configuration's working directory to
`playground/`**: the fixture path in `play_equilibrium.f90` is relative, an IDE
defaults to the build directory, and the program exits 1 from anywhere else. That is
the one setting the configure step cannot make for you, which is why it says so at
configure time.

The option is `OFF` by default, so it changes nothing about a normal build, and each
program leaves its target unregistered (with a `STATUS` message) rather than failing
the configure when the build cannot support it — no `equilibrium` in `AL_IDS_SUBSET`,
no HDF5 backend, or no checked-in fixture for this build's DD version.

This route also links the *in-tree* `al-fortran` rather than an install prefix, so
stepping *into* `ids_get` or `imas_open` lands in the same profile's generated
sources. Building against an install prefix with `build.sh` can do that too, but only
while the build directory that produced the prefix is still on disk and was
configured with debug info (`RelWithDebInfo` or `Debug`) — for `install-equilibrium`
from `cmake -B build-eq`, stepping resolves into `build-eq/src/*.f90`.

### Seeing variables: use Linux

On macOS/arm64 breakpoints, stepping and stack frames work, but **variable values do
not**, and no setting fixes it:

- LLDB has no Fortran type system. Both Apple's LLDB and CLion's bundled JetBrains
  LLDB 21 report `no plugin for the language "fortran95"`; `frame variable` returns
  nothing and `frame variable -r .` matches nothing. The JetBrains Fortran plugin adds
  breakpoint file types and an expression editor, not a type system.
- GDB cannot substitute. Both CLion's bundled gdb 16.3 and Homebrew's gdb 17.2 are arm64
  builds, and both fail on a five-line gfortran program: `DWARF Error: DW_FORM_line_strp
  used without required section` (gdb does not read debug info through Apple's debug map,
  with or without `dsymutil`, `-gdwarf-4` included), then `Don't know how to run`, because
  `help target` lists no native target at all. That last point also means codesigning gdb
  is beside the point - the missing piece is process control, not permission.

`docker/Dockerfile` is the way out: Ubuntu with gfortran, gdb and the libraries al-core
needs, meant to be used as a CLion **Docker toolchain**. On Linux gdb reads Fortran
properly - derived types, nested arrays of derived types, allocatables, the versioned
type names:

```
(gdb) print status
$1 = 0
(gdb) print eq%vacuum_toroidal_field%r0
$2 = 6.2000000000000002
(gdb) print eq%time_slice(1)%global_quantities%ip
$3 = -15000000
(gdb) print eq%time_slice(1)%profiles_1d%psi
$4 = (-0.25, -1.25, -2.25, -3.25)
(gdb) whatis eq
type = Type ids_equilibrium_v4_1_1
```

From a terminal:

```bash
docker build -t imas-fortran-dev:latest docker/
docker run --rm -v "$PWD":/work -w /work imas-fortran-dev:latest \
  bash -c 'cmake -S /work -B /work/build-linux -G Ninja -D CMAKE_BUILD_TYPE=Debug \
             -D AL_IDS_SUBSET=equilibrium -D AL_PLAYGROUND=ON &&
           cmake --build /work/build-linux --target play_equilibrium -j 4'
docker run --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  -v "$PWD":/work -w /work/playground imas-fortran-dev:latest \
  gdb /work/build-linux/playground/play_equilibrium
```

**`-j 4`, not `-j`**: the `utilities_*_struct.f90` sources are the ~6.8 MB `<utilities>`
blob, which survives `AL_IDS_SUBSET` pruning whole, and compiling several of them with
`-g` at once exhausts a default Docker Desktop VM (7.9 GB against 18 CPUs here). Full
parallelism fails reproducibly at ~step 66 of 85 with `gfortran: fatal error: Killed
signal terminated program f951` - the OOM killer, not a code error. `-j 4` builds clean
from scratch. In CLion, set **Build options** to `-j 4` in the Docker CMake profile, or
raise the VM's memory in Docker Desktop → Settings → Resources.

`--cap-add=SYS_PTRACE --security-opt seccomp=unconfined` is what lets gdb control a
process inside a container; CLion passes the equivalent for a Docker toolchain itself.
Use a Linux-only build directory (`build-linux`, already git-ignored by `/build-*`) - a
build tree is not portable between the host and the container.

In CLion:

1. Settings → Build, Execution, Deployment → **Toolchains** → **+** → **Docker**, image
   `imas-fortran-dev:latest`. CLion detects cmake, gdb and the compilers in the image.
2. Settings → **CMake** → **+** for a new profile: toolchain *Docker*, build type
   *Debug*, CMake options `-D AL_IDS_SUBSET=equilibrium -D AL_PLAYGROUND=ON`, build
   options `-j 4` (see above).
3. Select that profile in the `play_equilibrium` run configuration, keeping
   `$PROJECT_DIR$/playground` as the working directory - CLion maps it into the
   container.

The image holds only the toolchain; the sources are bind-mounted, so editing code never
means rebuilding the image. Note that running the program writes to the checked-in
fixture (`master.h5`), on the host or in the container alike, since `OPEN_PULSE` is not
read-only.

Debugging Fortran on the *macOS* side needs the JetBrains **Fortran** plugin installed
(it supplies the value renderers); a stock LLDB without it reports `no plugin for the
language "fortran95"` and will show line positions but not locals. Even with it, the
limitation above stands.

If a CMake run configuration shows a red cross reading `<target> (al-fortran) not
found`, the target is missing from CLion's *loaded* model rather than from the build:
**File → Reload CMake Project**. A stale model invalidates every CMake-typed
configuration at once, so the giveaway is that the auto-generated per-test
configurations are red too.

Add new `.f90` files here and build them the same way. `ids_routines` is the
main module to `use`; see `examples/` at the repo root for more usage patterns
(put/get, slices, validation, identifiers, ...).

Note: the generated `al-fortran.pc` pkg-config file includes a `--defsym`
linker flag that GNU ld understands but macOS's `ld64` does not, so
`build.sh` links directly instead of going through `pkg-config`.
