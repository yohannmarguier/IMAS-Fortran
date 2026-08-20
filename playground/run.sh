#!/usr/bin/env bash
# Compile play_eq_two_dd against the shim-linked al-fortran in ../install-shim
# and run it over the two fixtures.
#
# Two things have to be told to the process, both because nothing in a build tree
# is on a default search path:
#   IMAS_CORE_LIBRARY        which real IMAS-Core the shim should dlopen
#   IMAS_MVDD_HLI_DD_VERSION which dictionary the *calling HLI* speaks; the shim
#                            latches it once per process, and compares each
#                            opened entry's own version_put stamp against it to
#                            decide whether that entry needs converting
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"

PREFIX="${PREFIX:-$repo/install-shim}"
SHIM="${SHIM:-$repo/../IMAS-Multiversion-DD-Loader/install}"
: "${IMAS_CORE_LIBRARY:=$repo/cmake-build-debug/_deps/al-core-build/libal.dylib}"
: "${IMAS_MVDD_HLI_DD_VERSION:=4.1.1}"
export IMAS_CORE_LIBRARY IMAS_MVDD_HLI_DD_VERSION

for f in "$PREFIX/lib/libal-fortran-4.1.1.dylib" "$IMAS_CORE_LIBRARY"; do
  [[ -e $f ]] || { echo "missing: $f" >&2; exit 1; }
done

# The whole point of this playground is that calls reach the shim. A link line
# that resolved al_* against IMAS-Core instead would still build and still run,
# and the only symptom would be data that was never converted -- so fail loudly
# rather than silently measure nothing.
if ! otool -L "$PREFIX/lib/libal-fortran-4.1.1.dylib" | grep -q imas_mvdd_loader; then
  echo "ERROR: $PREFIX bypasses the shim -- its al-fortran links IMAS-Core directly." >&2
  echo "Rebuild with -D AL_USE_MULTIVERSION_SHIM=ON and reinstall." >&2
  exit 1
fi

gfortran -O1 -g -o "$here/play_eq_two_dd" "$here/play_eq_two_dd.f90" \
  -I"$PREFIX/include/fortran" \
  -L"$PREFIX/lib" -lal-fortran-4.1.1 \
  -L"$SHIM/lib" -limas_mvdd_loader \
  -Wl,-rpath,"$PREFIX/lib" -Wl,-rpath,"$SHIM/lib"

cd "$repo"
set +e
"$here/play_eq_two_dd" "$repo/imas-python-fixtures/fixtures" "${1:-dd-4.1.1}" "${2:-dd-3.39.0}"
rc=$?
set -e

# A cross-version read currently dies inside the generated HLI, not inside the
# shim. Say so where it happens, so the signal is not mistaken for a shim fault
# or for a broken fixture. FINDINGS.md carries the full diagnosis.
if [[ $rc -gt 128 ]]; then
  cat >&2 <<'MSG'

================================================================================
KILLED BY SIGNAL -- this is the known IMAS-Fortran defect, not a shim fault.
================================================================================
The shim refused one DD path, correctly:

    grids_ggd/grid/space/coordinates_type

The generated HLI mishandles that refusal and ends one context twice:

  1. utilities_get_struct.f90, the "else" arm of the coordinates_type
     arraystruct block, ends its ENCLOSING context and returns the never-set
     aosctx as a status.
  2. the caller's isErrorCritical block ends that SAME context again.

grids_ggd precedes time_slice in the IDS, so the read dies before any table
data exists. Generator site: IDSDef2F90Routines.xsl:4932-4937.
See playground/FINDINGS.md.

To see the table itself, run a self-test with one pulse in both columns:
    ./run.sh dd-4.1.1 dd-4.1.1
================================================================================
MSG
fi
exit $rc
