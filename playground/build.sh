#!/usr/bin/env bash
# Compile a single playground .f90 file against a locally installed al-fortran library.
# Usage: ./build.sh play_magnetics.f90
#        IMAS_FORTRAN_PREFIX=install-equilibrium-two-dd ./build.sh play_magnetics.f90
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
SRC="${1:?usage: build.sh <file.f90>}"
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
gfortran "$SRC" \
  -I"$PREFIX/include/fortran" \
  -L"$PREFIX/lib" -l"$LIB" -lal \
  -Wl,-rpath,"$PREFIX/lib" \
  -o "$OUT"

echo "Built ./$OUT against $PREFIX (-l$LIB)"
