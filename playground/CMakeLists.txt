# play_eq_two_dd, buildable two ways.
#
#   standalone   cmake -B playground/build -S playground
#                Links an *installed* al-fortran prefix (../install-shim by
#                default). This is the honest consumer configuration: the
#                library is a black box, found the way anyone else finds it.
#
#   in-tree      cmake -B <dir> -D AL_PLAYGROUND=ON  (root project)
#                Links the `al-fortran` target of that build. This is the one to
#                debug: the generated HLI sources under <dir>/src are compiled
#                into the same build with the same flags, so a breakpoint in
#                utilities_get_struct.f90 resolves, and CLion picks the target
#                up as a run/debug configuration on its own.
#
# Both modes build the same source and take the same arguments; only where
# al-fortran comes from differs.

if( CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR )
  set( PLAYGROUND_STANDALONE ON )
  cmake_minimum_required( VERSION 3.16 )
  project( imas-fortran-playground LANGUAGES Fortran )
else()
  set( PLAYGROUND_STANDALONE OFF )
endif()

set( PLAYGROUND_FIXTURES "${CMAKE_CURRENT_SOURCE_DIR}/../imas-python-fixtures/fixtures" CACHE PATH
     "Directory holding the dd-*/ equilibrium pulses" )

# The program names DD 4.1.1 paths outright, so it cannot compile against a
# DD 3 dictionary -- that asymmetry is the whole point of it.
if( NOT PLAYGROUND_STANDALONE AND NOT DD_VERSION MATCHES "^4\\." )
  message( STATUS "Not building play_eq_two_dd: it is written against DD 4 paths (DD_VERSION=${DD_VERSION})" )
  return()
endif()

# Where al-fortran comes from
################################################################################

if( PLAYGROUND_STANDALONE )

  set( PLAYGROUND_DD_VERSION "4.1.1" CACHE STRING
       "DD version of the installed al-fortran to link (also the HLI version the shim latches)" )
  set( AL_FORTRAN_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/../install-shim" CACHE PATH
       "Install prefix of the shim-linked al-fortran to compile against" )
  set( IMAS_MVDD_LOADER_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/../../IMAS-Multiversion-DD-Loader/install" CACHE PATH
       "Install prefix of the IMAS-Multiversion-DD-Loader" )
  set( IMAS_CORE_LIBRARY
       "${CMAKE_CURRENT_SOURCE_DIR}/../cmake-build-debug/_deps/al-core-build/libal${CMAKE_SHARED_LIBRARY_SUFFIX}"
       CACHE FILEPATH "Real IMAS-Core the shim dlopens -- run time only, never linked" )

  # Not found through its .pc file on purpose: that file carries
  # `Requires: al-core`, which a shim install does not provide, and a
  # GNU-ld-only --defsym that Apple's linker rejects.
  find_library( AL_FORTRAN_LIBRARY
    NAMES al-fortran-${PLAYGROUND_DD_VERSION}
    HINTS "${AL_FORTRAN_PREFIX}/lib"
    NO_DEFAULT_PATH
    REQUIRED
    DOC "libal-fortran-${PLAYGROUND_DD_VERSION} under AL_FORTRAN_PREFIX" )
  find_path( AL_FORTRAN_MODULE_DIR
    NAMES ids_routines.mod
    HINTS "${AL_FORTRAN_PREFIX}/include/fortran"
    NO_DEFAULT_PATH
    REQUIRED
    DOC "Directory holding the installed al-fortran .mod files" )

  add_library( al-fortran SHARED IMPORTED )
  set_target_properties( al-fortran PROPERTIES
    IMPORTED_LOCATION "${AL_FORTRAN_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${AL_FORTRAN_MODULE_DIR}" )

  # The installed al-fortran already records the loader as a dependency, so this
  # is not what makes the shim reachable -- it keeps the dependency stated where
  # a reader looks for it.
  find_package( imas-mvdd-loader CONFIG REQUIRED
    PATHS "${IMAS_MVDD_LOADER_PREFIX}"
    NO_DEFAULT_PATH )

  set( PLAYGROUND_LIBRARIES al-fortran imas-mvdd-loader::imas-mvdd-loader )
  set( PLAYGROUND_RPATH "${AL_FORTRAN_PREFIX}/lib;${IMAS_MVDD_LOADER_PREFIX}/lib" )
  set( PLAYGROUND_ENVIRONMENT
       "IMAS_CORE_LIBRARY=${IMAS_CORE_LIBRARY};IMAS_MVDD_HLI_DD_VERSION=${PLAYGROUND_DD_VERSION}" )

else()

  # In-tree: al-fortran is a target here, and whether it reaches the shim is
  # AL_USE_MULTIVERSION_SHIM's business, already asserted by
  # tests/shim/CMakeLists.txt. AL_CORE_TEST_ENVIRONMENT carries IMAS_CORE_LIBRARY
  # in a shim build and is empty otherwise.
  if( NOT AL_USE_MULTIVERSION_SHIM )
    message( STATUS
      "play_eq_two_dd: AL_USE_MULTIVERSION_SHIM is off, so nothing converts -- "
      "the dd-3.39.0 column will read as a DD 3 pulse fed to a DD 4 type" )
  endif()
  set( PLAYGROUND_LIBRARIES al-fortran )
  set( PLAYGROUND_RPATH "" )
  set( PLAYGROUND_ENVIRONMENT
       "IMAS_MVDD_HLI_DD_VERSION=${DD_VERSION};${AL_CORE_TEST_ENVIRONMENT}" )

endif()

# Target
################################################################################

add_executable( play_eq_two_dd play_eq_two_dd.f90 )
target_link_libraries( play_eq_two_dd PRIVATE ${PLAYGROUND_LIBRARIES} )

set_target_properties( play_eq_two_dd PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/modules" )
if( PLAYGROUND_RPATH )
  set_target_properties( play_eq_two_dd PROPERTIES BUILD_RPATH "${PLAYGROUND_RPATH}" )
endif()

# The defect this program demonstrates is a memory fault, so the optimisation
# level is not a free knob: -O1 is what it was first seen at. A debug build is
# left alone -- stepping through the generated HLI is the point of one.
if( NOT CMAKE_BUILD_TYPE STREQUAL "Debug" )
  target_compile_options( play_eq_two_dd PRIVATE -O1 -g )
endif()

# Tests
################################################################################

if( PLAYGROUND_STANDALONE )
  enable_testing()
  set( PLAYGROUND_TEST_PREFIX "" )

  # Refuse a prefix whose al-fortran never reaches the shim: a build that linked
  # IMAS-Core directly would compile and run fine and simply never convert
  # anything. Same script the in-tree suite uses, so there is one definition of
  # this check; the tool selection below mirrors tests/shim/CMakeLists.txt.
  if( APPLE )
    find_program( PLAYGROUND_INSPECT_TOOL otool )
    set( PLAYGROUND_INSPECT_ARGS -L )
  else()
    find_program( PLAYGROUND_INSPECT_TOOL NAMES ${CMAKE_OBJDUMP} objdump )
    set( PLAYGROUND_INSPECT_ARGS -p )
  endif()
  if( PLAYGROUND_INSPECT_TOOL )
    add_test( NAME shim-linkage
      COMMAND ${CMAKE_COMMAND}
        -D "LIBRARY=${AL_FORTRAN_LIBRARY}"
        -D "INSPECT_TOOL=${PLAYGROUND_INSPECT_TOOL}"
        -D "INSPECT_ARGS=${PLAYGROUND_INSPECT_ARGS}"
        -D "SHIM_LIBRARY_NAME=imas_mvdd_loader"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/../tests/shim/check_shim_linkage.cmake" )
  else()
    message( STATUS "Not registering shim-linkage: no dependency inspection tool found" )
  endif()
else()
  set( PLAYGROUND_TEST_PREFIX "playground-" )
endif()

# One pulse in both columns: no conversion is involved, so every row must read
# 'same'. This is what checks the table logic itself.
add_test( NAME ${PLAYGROUND_TEST_PREFIX}play_eq_two_dd-self
  COMMAND play_eq_two_dd "${PLAYGROUND_FIXTURES}" dd-4.1.1 dd-4.1.1 )
set_tests_properties( ${PLAYGROUND_TEST_PREFIX}play_eq_two_dd-self PROPERTIES
  ENVIRONMENT "${PLAYGROUND_ENVIRONMENT}"
  FAIL_REGULAR_EXPRESSION "DIFF|FLIP|SHAPE|only3|only4|ERROR" )

# The cross-version read, the actual exercise. DISABLED because it currently
# dies by signal inside the generated HLI -- a known IMAS-Fortran defect, not a
# shim fault; see FINDINGS.md. Run it under the debugger, or through run.sh;
# drop the DISABLED property once the defect is fixed.
add_test( NAME ${PLAYGROUND_TEST_PREFIX}play_eq_two_dd-cross
  COMMAND play_eq_two_dd "${PLAYGROUND_FIXTURES}" dd-4.1.1 dd-3.39.0 )
set_tests_properties( ${PLAYGROUND_TEST_PREFIX}play_eq_two_dd-cross PROPERTIES
  ENVIRONMENT "${PLAYGROUND_ENVIRONMENT}"
  DISABLED TRUE )
