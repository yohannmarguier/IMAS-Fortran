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

# The fixture path is a literal in the program, so read it back out of the source rather
# than assuming it is this build's DD version - the two drift, and the program is the one
# that decides.
#
# A fixture from a *different* DD version than the build is explicitly allowed, and used
# to be the reason this target was skipped. Reading a dd-3.39.0 entry with a 4.1.1 library
# is the cross-version case the Rust read-path middleware exists to handle, so it is the
# scenario to run under a debugger, not one to withhold a target from. What is still worth
# refusing is a fixture that is not on disk at all, since that fails at run time as an
# unhelpful open error.
file( READ "${CMAKE_CURRENT_SOURCE_DIR}/play_equilibrium.f90" PLAY_EQ_SOURCE )
if( NOT PLAY_EQ_SOURCE MATCHES "fixtures/dd-([0-9][0-9.]*)" )
  message( STATUS
    "play_equilibrium.f90 names no dd-<version> fixture directory:"
    " not adding the play_equilibrium target" )
  return()
endif()
set( PLAY_EQ_FIXTURE_VERSION "${CMAKE_MATCH_1}" )
set( PLAY_EQ_FIXTURE
  "${CMAKE_SOURCE_DIR}/imas-python-fixtures/fixtures/dd-${PLAY_EQ_FIXTURE_VERSION}" )
if( NOT EXISTS "${PLAY_EQ_FIXTURE}/equilibrium.h5" )
  message( STATUS
    "play_equilibrium.f90 reads ${PLAY_EQ_FIXTURE}, which does not exist:"
    " not adding the play_equilibrium target" )
  return()
endif()

add_executable( play_equilibrium play_equilibrium.f90 )
target_link_libraries( play_equilibrium al-fortran )

# play_eq_mw_convert asserts the *converted* read against the DD 4.1.1 half of the same
# fixture pair, so it needs both halves on disk where play_equilibrium needs only one.
if( EXISTS "${CMAKE_SOURCE_DIR}/imas-python-fixtures/fixtures/dd-4.1.1/equilibrium.h5" )
  add_executable( play_eq_mw_convert play_eq_mw_convert.f90 )
  target_link_libraries( play_eq_mw_convert al-fortran )
  message( STATUS
    "AL_PLAYGROUND=ON: added the play_eq_mw_convert target (reads the dd-"
    "${PLAY_EQ_FIXTURE_VERSION} entry through the Rust middleware and checks it against"
    " the dd-4.1.1 fixture's values); run it with ${CMAKE_CURRENT_SOURCE_DIR} as the"
    " working directory" )
else()
  message( STATUS
    "no dd-4.1.1 fixture to check against: not adding the play_eq_mw_convert target" )
endif()

# The fixture path in the program is relative to this directory, so the program only
# works run from here, while a CMake-aware IDE defaults a run configuration's working
# directory to the build directory. That is the one thing about this target still to be
# set by hand, so say it at configure time rather than leaving it to be discovered as a
# failed open of a fixture.
if( PLAY_EQ_FIXTURE_VERSION VERSION_EQUAL DD_VERSION )
  message( STATUS
    "AL_PLAYGROUND=ON: added the play_equilibrium target, reading its own DD version's"
    " fixture (dd-${PLAY_EQ_FIXTURE_VERSION}); run it with"
    " ${CMAKE_CURRENT_SOURCE_DIR} as the working directory" )
else()
  # Not a warning: this is the read-path middleware's whole subject. Said out loud
  # because it explains values that otherwise look like bugs - fields absent from the
  # older entry come back as ids_*_invalid, and sign conventions differ between DD 3
  # and DD 4.
  message( STATUS
    "AL_PLAYGROUND=ON: added the play_equilibrium target, reading a dd-"
    "${PLAY_EQ_FIXTURE_VERSION} fixture with a DD ${DD_VERSION} library - the"
    " cross-version read the middleware handles; run it with"
    " ${CMAKE_CURRENT_SOURCE_DIR} as the working directory" )
endif()
