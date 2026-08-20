#!/usr/bin/env bash
# Build play_eq_two_dd through playground/CMakeLists.txt and run it over the two
# fixtures.
#
# Compilation, and the check that the al-fortran being linked actually reaches
# the shim, both live in CMakeLists.txt now; this script only configures, builds
# and runs. To build without running:
#
#   cmake -B playground/build -S playground && cmake --build playground/build
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
BUILD="${BUILD:-$here/build}"
: "${IMAS_CORE_LIBRARY:=$repo/cmake-build-debug/_deps/al-core-build/libal.dylib}"
: "${IMAS_MVDD_HLI_DD_VERSION:=4.1.1}"
export IMAS_CORE_LIBRARY IMAS_MVDD_HLI_DD_VERSION

[[ -e $IMAS_CORE_LIBRARY ]] || { echo "missing: $IMAS_CORE_LIBRARY" >&2; exit 1; }

cmake -B "$BUILD" -S "$here" \
  -D AL_FORTRAN_PREFIX="$PREFIX" \
  -D IMAS_MVDD_LOADER_PREFIX="$SHIM" \
  -D IMAS_CORE_LIBRARY="$IMAS_CORE_LIBRARY" \
  -D PLAYGROUND_DD_VERSION="$IMAS_MVDD_HLI_DD_VERSION"
cmake --build "$BUILD"

cd "$repo"
set +e
"$BUILD/play_eq_two_dd" "$repo/imas-python-fixtures/fixtures" "${1:-dd-4.1.1}" "${2:-dd-3.39.0}"
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
