#!/usr/bin/env bash
# Compile a playground program against a locally installed al-fortran library.
# Usage: ./build.sh play_magnetics.f90
#        ./build.sh play_eq_two_dd.f90 eq_convert_3to4.f90
#        IMAS_FORTRAN_PREFIX=install-equilibrium-two-dd ./build.sh play_magnetics.f90
#
# The first argument is the program and names the binary; any further arguments
# are modules it uses. They are compiled ahead of it, in the order given, so a
# module's .mod exists by the time the program's `use` line is read.
#
# Programs are always built debuggable (-g -O0), since the point of the playground
# is to poke at the library interactively; IMAS_FORTRAN_FFLAGS appends flags, e.g.
# IMAS_FORTRAN_FFLAGS='-fcheck=all -ffpe-trap=invalid,zero' ./build.sh play.f90
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"

# $FC if set, else gfortran off PATH, else the two places Homebrew puts it. The
# fallback is what makes this script work when it is run by a GUI app rather than
# a login shell — an IDE launched from Finder/Dock inherits a bare PATH
# (/usr/bin:/bin:/usr/sbin:/sbin) with no /opt/homebrew/bin in it.
if [ -n "${FC:-}" ]; then
  :
elif command -v gfortran >/dev/null 2>&1; then
  FC=gfortran
else
  for candidate in /opt/homebrew/bin/gfortran /usr/local/bin/gfortran; do
    [ -x "$candidate" ] && FC="$candidate" && break
  done
fi
if [ -z "${FC:-}" ] || ! command -v "$FC" >/dev/null 2>&1; then
  echo "error: no Fortran compiler found (looked for \$FC, gfortran on PATH," >&2
  echo "       /opt/homebrew/bin/gfortran, /usr/local/bin/gfortran)" >&2
  echo "       set FC=/path/to/gfortran, or add it to PATH" >&2
  exit 1
fi
SRC="${1:?usage: build.sh <program.f90> [module.f90 ...]}"
shift
DEPS=("$@")
OUT="bin/$(basename "${SRC%.f90}")"

# A bare name (install-equilibrium-two-dd) resolves against the repo root, not the
# current directory: the interesting prefixes are all siblings of playground/, and
# build.sh is meant to be run from inside it.
PREFIX="${IMAS_FORTRAN_PREFIX:-install}"
case "$PREFIX" in
  /*) ;;
  *) PREFIX="$REPO_ROOT/$PREFIX" ;;
esac

if [ ! -d "$PREFIX/include/fortran" ]; then
  echo "error: al-fortran install not found at $PREFIX" >&2
  echo "build it first, e.g.: cmake --install <build-dir> --prefix $PREFIX" >&2
  echo "prefixes found under $REPO_ROOT:" >&2
  find "$REPO_ROOT" -maxdepth 3 -type d -path '*/include/fortran' 2>/dev/null \
    | sed -e 's|/include/fortran$||' -e "s|^$REPO_ROOT/|  |" >&2 || true
  exit 1
fi

# The library is named after the DD version the build selected (al-fortran-4.1.1),
# so read it back off the install rather than pinning one version here. A two-version
# build is still one library: the second DD version adds modules, not a second .so.
LIBS="$(find "$PREFIX/lib" -maxdepth 1 \
  \( -name 'libal-fortran-*.dylib' -o -name 'libal-fortran-*.so' -o -name 'libal-fortran-*.a' \) \
  -exec basename {} \; | sed -E 's/^lib(al-fortran-.*)\.(dylib|so|a)$/\1/' | sort -u)"
if [ "$(printf '%s\n' "$LIBS" | grep -c .)" -ne 1 ]; then
  echo "error: expected exactly one al-fortran library in $PREFIX/lib, found:" >&2
  printf '%s\n' "$LIBS" | sed 's|^|  |' >&2
  exit 1
fi
LIB="$LIBS"

mkdir -p bin
# -g -O0 so a debugger can step the program line by line and read locals: -O0 is
# gfortran's default already, but naming it keeps an inherited FFLAGS from turning
# stepping into a guessing game. -fbacktrace makes an unattended crash locatable
# without a debugger. The installed library is a separate build's product, so
# stepping *into* al-fortran needs that build configured with debug info
# (RelWithDebInfo or Debug) and its <build>/src still on disk.
FFLAGS=(-g -O0 -fbacktrace)
read -r -a EXTRA_FFLAGS <<< "${IMAS_FORTRAN_FFLAGS:-}"

# -J keeps the .mod files generated for the dependency modules out of the source
# tree, next to the binary they belong to.
#
# ${DEPS[@]+"${DEPS[@]}"} rather than "${DEPS[@]}": macOS ships bash 3.2, where
# expanding an empty array under `set -u` is an unbound-variable error. The outer
# ${x+...} tests whether the array is set at all, so the no-deps case expands to
# nothing instead of aborting.
"$FC" "${FFLAGS[@]}" ${EXTRA_FFLAGS[@]+"${EXTRA_FFLAGS[@]}"} \
  ${DEPS[@]+"${DEPS[@]}"} "$SRC" \
  -I"$PREFIX/include/fortran" -J bin \
  -L"$PREFIX/lib" -l"$LIB" -lal \
  -Wl,-rpath,"$PREFIX/lib" \
  -o "$OUT"

if [ "${#DEPS[@]}" -gt 0 ] 2>/dev/null; then
  echo "Built ./$OUT against $PREFIX (-l$LIB) with ${DEPS[*]}"
else
  echo "Built ./$OUT against $PREFIX (-l$LIB)"
fi
