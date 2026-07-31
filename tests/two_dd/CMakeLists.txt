# The two-version build's acceptance test: both Data Dictionary versions read and
# written through the public front doors, against a real storage backend.
#
# Registered here, next to the generated suite, rather than in examples/: examples/ is
# force-disabled whenever AL_IDS_SUBSET is set, and the subset build is exactly the one
# this test has to run in. The registration itself follows examples/CMakeLists.txt -
# add_executable, link al-fortran, add_test, FAIL_REGULAR_EXPRESSION.
#
# The test program names equilibrium and nothing else, so it compiles in a subset build.
# Everything that could make it unbuildable or meaningless is checked below, and each
# check leaves the test unregistered rather than failing the configure: a two-version
# build that cannot run this test still configures and builds exactly as before.

if( NOT equilibrium IN_LIST IDS_NAMES )
  message( STATUS
    "AL_IDS_SUBSET excludes equilibrium: not registering al-fortran-test-two-dd-versions,"
    " which reads the checked-in equilibrium fixtures" )
  return()
endif()

# The program asserts on both sides of the DD 3 -> DD 4 renames, naming j_phi and
# beta_tor_norm through the default version and j_tor and beta_normal through the second.
# Swap the two roles and it does not compile, so the orientation is a condition for
# registering it, not a comment.
if( NOT DD_VERSION MATCHES "^4[.]" OR NOT SECOND_DD_VERSION MATCHES "^3[.]" )
  message( STATUS
    "Data Dictionary ${DD_VERSION} (default) and ${SECOND_DD_VERSION} (second) are not a"
    " DD 4 / DD 3 pair: not registering al-fortran-test-two-dd-versions, which is written"
    " against both sides of the DD 3 -> DD 4 renames" )
  return()
endif()

# The fixtures are HDF5 pulses (imas-python-fixtures/, written by equilibrium_seed.py),
# one directory per Data Dictionary version. Both versions of this build need one: it is
# the values the program asserts on.
set( TWO_DD_FIXTURES_ROOT "${CMAKE_SOURCE_DIR}/imas-python-fixtures/fixtures" )
foreach( _DD_VERSION ${DD_VERSION} ${SECOND_DD_VERSION} )
  if( NOT EXISTS "${TWO_DD_FIXTURES_ROOT}/dd-${_DD_VERSION}/equilibrium.h5" )
    message( STATUS
      "No checked-in equilibrium fixture for Data Dictionary ${_DD_VERSION}"
      " (${TWO_DD_FIXTURES_ROOT}/dd-${_DD_VERSION}): not registering"
      " al-fortran-test-two-dd-versions" )
    return()
  endif()
endforeach()

if( NOT AL_BACKEND_HDF5 )
  message( STATUS
    "AL_BACKEND_HDF5 is OFF: not registering al-fortran-test-two-dd-versions, whose"
    " fixtures are HDF5 pulses" )
  return()
endif()

# Read a copy, not the checked-in files: opening a pulse is not a promise to leave its
# directory untouched, and a test that dirties the working tree is a test nobody trusts
# twice. Copied at configure time, and re-copied when a fixture changes. Reading does
# leave the pulse byte-identical in practice, so this is about the working tree rather
# than about handing each run a fresh copy.
set( TWO_DD_FIXTURE_DEFAULT "${CMAKE_CURRENT_BINARY_DIR}/fixtures/dd-${DD_VERSION}" )
set( TWO_DD_FIXTURE_SECOND "${CMAKE_CURRENT_BINARY_DIR}/fixtures/dd-${SECOND_DD_VERSION}" )
file( COPY
    "${TWO_DD_FIXTURES_ROOT}/dd-${DD_VERSION}"
    "${TWO_DD_FIXTURES_ROOT}/dd-${SECOND_DD_VERSION}"
  DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/fixtures" )
set_property( DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  "${TWO_DD_FIXTURES_ROOT}/dd-${DD_VERSION}/equilibrium.h5"
  "${TWO_DD_FIXTURES_ROOT}/dd-${SECOND_DD_VERSION}/equilibrium.h5" )

# One data entry per version - two URIs, not two occurrences of one entry - which is what
# makes the version stamps read back from them evidence that the two halves are distinct
# on disk. Absolute paths, so the test needs no writable pulse location from the
# environment.
set( TWO_DD_ENTRY_DEFAULT "${CMAKE_CURRENT_BINARY_DIR}/written/dd-${DD_VERSION}" )
set( TWO_DD_ENTRY_SECOND "${CMAKE_CURRENT_BINARY_DIR}/written/dd-${SECOND_DD_VERSION}" )
file( MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/written" )

configure_file( two_dd_versions_test.f90.in two_dd_versions_test.f90 @ONLY )

add_executable( al-fortran-test-two-dd-versions
  ${CMAKE_CURRENT_BINARY_DIR}/two_dd_versions_test.f90 )
target_link_libraries( al-fortran-test-two-dd-versions al-fortran )
# Both versions' sources, since the program uses both front doors.
add_dependencies( al-fortran-test-two-dd-versions ${AL_SOURCE_TARGETS} )
# al-fortran-tests is the aggregate target tests/generator declares; building it must
# build this test too.
add_dependencies( al-fortran-tests al-fortran-test-two-dd-versions )

add_test( NAME al-fortran-test-two-dd-versions
  COMMAND al-fortran-test-two-dd-versions )
# The program's exit status is the test result; this only catches an error the library
# below it reports without one.
set_tests_properties( al-fortran-test-two-dd-versions PROPERTIES
  FAIL_REGULAR_EXPRESSION "[Ee][Rr][Rr][Oo][Rr]"
)
