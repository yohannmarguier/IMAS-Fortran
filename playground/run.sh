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

# A cross-version read stops at the first DD path the shim refuses, and exits
# non-zero without reaching time_slice. That is the current, intended behaviour;
# say so, so a clean stop is not mistaken for a broken fixture.
if [[ $rc -ne 0 && $rc -le 128 ]]; then
  cat >&2 <<'MSG'

================================================================================
STOPPED AT A REFUSED DD PATH -- expected, and not a fault.
================================================================================
The shim refused one DD path, correctly:

    grids_ggd/grid/space/coordinates_type

coordinates_type is INT_1D in DD 3.39.0 and an array of identifier structures in
DD 4.1.1, so no value transformation converts one into the other.

The generated HLI now propagates that refusal outward as an ordinary error, one
level at a time. grids_ggd precedes time_slice in the IDS, so the read stops
before any table data exists -- hence no table.

Whether a refusal *should* stop the whole read, rather than leaving that array
empty and continuing, is an open policy question: see playground/FINDINGS.md.

To see the table itself, run a self-test with one pulse in both columns:
    ./run.sh dd-4.1.1 dd-4.1.1
================================================================================
MSG
fi

# This used to be the normal outcome: a refused path made the generated failure
# arm end its caller's context, which the caller then ended again. Fixed in
# IDSDef2F90Routines.xsl; guarded by the playground-play_eq_two_dd-cross ctest.
if [[ $rc -gt 128 ]]; then
  cat >&2 <<'MSG'

================================================================================
KILLED BY SIGNAL -- REGRESSION of the arraystruct-refusal double-close.
================================================================================
A failed al_begin_arraystruct_action creates no context, so the failure arm must
not end the enclosing one: inside a get_struct_* routine that context is a dummy
argument, and its owner ends it itself. Generator site:
IDSDef2F90Routines.xsl:4932. See playground/FINDINGS.md.
================================================================================
MSG
fi
exit $rc
