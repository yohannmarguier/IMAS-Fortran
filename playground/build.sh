#!/usr/bin/env bash
# Compile a single playground .f90 file against the locally installed al-fortran library.
# Usage: ./build.sh play_magnetics.f90
set -euo pipefail

PREFIX="${IMAS_FORTRAN_PREFIX:-$HOME/.local/imas-fortran}"
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
