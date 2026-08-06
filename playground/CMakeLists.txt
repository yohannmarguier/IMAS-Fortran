# Playground programs as CMake targets, for AL_PLAYGROUND=ON only.
#
# build.sh remains the normal way to compile these against an *installed* library, and
# nothing here changes it. This file exists for the one thing build.sh cannot give an
# IDE: a target in the project model. CLion (and any other CMake-aware IDE) can run and
# debug an ordinary target with no custom build target, no external tool and no
# hand-written run configuration, whereas a binary built outside CMake has to be
# described to it by hand.
#
# Linking the in-tree al-fortran rather than an install prefix is the other reason to
# prefer this route while debugging: the library is built by the same profile as the
# program, so stepping into ids_get lands in that profile's generated sources instead of
# depending on some other build directory still being on disk.
#
# Each program guards its own preconditions and leaves its target unregistered rather
# than failing the configure, the way tests/two_dd does: a build that cannot support one
# playground program still configures exactly as before.

if( NOT equilibrium IN_LIST IDS_NAMES )
  message( STATUS
    "AL_IDS_SUBSET excludes equilibrium: not adding the play_equilibrium target,"
    " which reads the checked-in equilibrium fixture" )
  return()
endif()

# play_middleware creates its own ASCII data entry, so it is registered ahead of the
# fixture and HDF5 guards below — those return() early and would otherwise take this
# target with them.
add_executable( play_middleware play_middleware.f90 )
target_link_libraries( play_middleware al-fortran )
message( STATUS
  "AL_PLAYGROUND=ON: added the play_middleware target (asserts the Rust read-path"
  " middleware is in the path; set IMAS_MW_TRACE=1 to see every read)" )

if( NOT AL_BACKEND_HDF5 )
  message( STATUS
    "AL_BACKEND_HDF5 is OFF: not adding the play_equilibrium target, whose fixture"
    " is an HDF5 pulse" )
  return()
endif()

# play_equilibrium.f90 now reads *both* halves of the fixture pair in one run - the DD
# 4.1.1 half natively (as ground truth) and the DD 3.39.0 half through the Rust read-path
# middleware (as the conversion under test) - so unlike a single-fixture design there is no
# one version to scrape out of the source; both paths are hardcoded literals in the
# program because the map itself is a fixed 3.39.0<->4.1.1 pair (prototype scope). Its
# derived types are equally hardcoded to the DD 4.1.1 schema (field names like
# `contour_tree` or `psi_norm` that only exist from 4.1.1 on), so this target also assumes
# the library itself is built as DD 4.1.1 - said below as a STATUS, not enforced, since a
# mismatch already fails clearly at compile time rather than silently at run time.
set( PLAY_EQ_FIXTURE_DD4 "${CMAKE_SOURCE_DIR}/imas-python-fixtures/fixtures/dd-4.1.1" )
set( PLAY_EQ_FIXTURE_DD3 "${CMAKE_SOURCE_DIR}/imas-python-fixtures/fixtures/dd-3.39.0" )
if( NOT EXISTS "${PLAY_EQ_FIXTURE_DD4}/equilibrium.h5" OR
    NOT EXISTS "${PLAY_EQ_FIXTURE_DD3}/equilibrium.h5" )
  message( STATUS
    "play_equilibrium.f90 needs both ${PLAY_EQ_FIXTURE_DD4} and ${PLAY_EQ_FIXTURE_DD3}"
    " on disk and at least one is missing: not adding the play_equilibrium target" )
  return()
endif()

add_executable( play_equilibrium play_equilibrium.f90 )
target_link_libraries( play_equilibrium al-fortran )

# play_eq_mw_convert also asserts the converted read against the DD 4.1.1 half, so it
# needs exactly the same pair on disk - already established to exist above.
add_executable( play_eq_mw_convert play_eq_mw_convert.f90 )
target_link_libraries( play_eq_mw_convert al-fortran )
message( STATUS
  "AL_PLAYGROUND=ON: added the play_eq_mw_convert target (reads the dd-3.39.0 entry"
  " through the Rust middleware and checks it against the dd-4.1.1 fixture's hardcoded"
  " values); run it with ${CMAKE_CURRENT_SOURCE_DIR} as the working directory" )

# The fixture paths in the program are relative to this directory, so the program only
# works run from here, while a CMake-aware IDE defaults a run configuration's working
# directory to the build directory. That is the one thing about this target still to be
# set by hand, so say it at configure time rather than leaving it to be discovered as a
# failed open of a fixture.
if( DD_VERSION VERSION_EQUAL "4.1.1" )
  message( STATUS
    "AL_PLAYGROUND=ON: added the play_equilibrium target, reading dd-4.1.1 natively and"
    " dd-3.39.0 through the middleware; run it with ${CMAKE_CURRENT_SOURCE_DIR} as the"
    " working directory" )
else()
  message( STATUS
    "AL_PLAYGROUND=ON: added the play_equilibrium target, but this build's DD_VERSION is"
    " ${DD_VERSION}, not 4.1.1 - the program's derived types are the DD 4.1.1 schema, so"
    " this only compiles if 4.1.1 is what 'ids_equilibrium' actually aliases to; run it"
    " with ${CMAKE_CURRENT_SOURCE_DIR} as the working directory" )
endif()
