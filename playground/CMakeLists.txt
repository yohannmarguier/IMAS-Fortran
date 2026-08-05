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

# The fixture path is a literal in the program, so the fixture this build's DD version
# needs is not necessarily the one the source reads. Checking the source rather than
# assuming keeps the two from drifting apart silently: read a fixture written by another
# DD version and the failure surfaces at run time as unexpected values, not at build
# time.
set( PLAY_EQ_FIXTURE "${CMAKE_SOURCE_DIR}/imas-python-fixtures/fixtures/dd-${DD_VERSION}" )
file( READ "${CMAKE_CURRENT_SOURCE_DIR}/play_equilibrium.f90" PLAY_EQ_SOURCE )
if( NOT PLAY_EQ_SOURCE MATCHES "fixtures/dd-${DD_VERSION}" )
  message( STATUS
    "play_equilibrium.f90 reads a fixture other than dd-${DD_VERSION} (this build's"
    " Data Dictionary version): not adding the play_equilibrium target" )
  return()
endif()
if( NOT EXISTS "${PLAY_EQ_FIXTURE}/equilibrium.h5" )
  message( STATUS
    "No checked-in equilibrium fixture for Data Dictionary ${DD_VERSION}"
    " (${PLAY_EQ_FIXTURE}): not adding the play_equilibrium target" )
  return()
endif()

add_executable( play_equilibrium play_equilibrium.f90 )
target_link_libraries( play_equilibrium al-fortran )

# The fixture path in the program is relative to this directory, so the program only
# works run from here, while a CMake-aware IDE defaults a run configuration's working
# directory to the build directory. That is the one thing about this target still to be
# set by hand, so say it at configure time rather than leaving it to be discovered as a
# failed open of a fixture.
message( STATUS
  "AL_PLAYGROUND=ON: added the play_equilibrium target (run it with"
  " ${CMAKE_CURRENT_SOURCE_DIR} as the working directory)" )
