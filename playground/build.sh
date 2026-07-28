#!/usr/bin/env bash
# Compile a single playground .f90 file against the locally installed al-fortran library.
# Usage: ./build.sh play_magnetics.f90
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
PREFIX="${IMAS_FORTRAN_PREFIX:-$REPO_ROOT/install}"
SRC="${1:?usage: build.sh <file.f90>}"
OUT="bin/$(basename "${SRC%.f90}")"

if [ ! -d "$PREFIX/include/fortran" ]; then
  echo "error: al-fortran install not found at $PREFIX" >&2
  echo "build it first, e.g.: cmake --install <build-dir> --prefix $PREFIX" >&2
  exit 1
fi

mkdir -p bin
gfortran "$SRC" \
  -I"$PREFIX/include/fortran" \
  -L"$PREFIX/lib" -lal-fortran-4.1.1 -lal \
  -Wl,-rpath,"$PREFIX/lib" \
  -o "$OUT"

echo "Built ./$OUT"
