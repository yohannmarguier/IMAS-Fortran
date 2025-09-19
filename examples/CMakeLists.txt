project( fortraninterface-ex Fortran )

include(ALExampleUtilities)

# Sources
################################################################################

set( TESTS
    test_identifiers
)
# Report an error when a .f90 source file exists without corresponding test:
error_on_missing_tests( "f90" "${TESTS}" )

# Targets
################################################################################

add_custom_target( example-fortran-all )

foreach( TEST IN LISTS TESTS )
  set( TEST_NAME "example-fortran-${TEST}")
  add_executable( ${TEST_NAME} ${TEST}.f90 )
  target_link_libraries( ${TEST_NAME} al-fortran  al-identifiers-fortran)
  add_dependencies( example-fortran-all ${TEST_NAME} )

  set( DISABLED OFF )
  if( (NOT AL_BACKEND_MDSPLUS OR NOT AL_BACKEND_HDF5) AND TEST_NAME MATCHES "get|put|create|empty|_plugin" )
    set( DISABLED ON )
  endif()

  set( TEST_ENVIRONMENT "" )
  if( AL_BACKEND_MDSPLUS )
    get_target_property( MDSPLUS_MODEL_DIR al-mdsplus-model BINARY_DIR )
    set( TEST_ENVIRONMENT "ids_path=${MDSPLUS_MODEL_DIR}" )
  endif()

  # Execute the test without plugins
  if( NOT TEST_NAME MATCHES _plugin )
    add_test( NAME ${TEST_NAME} COMMAND ${TEST_NAME} )
    set_al_example_properties( ${TEST_NAME} ${DISABLED} OFF "${TEST_ENVIRONMENT}" )
  endif()

  # Execute the test with plugins
  if( AL_PLUGINS )
    add_test( NAME ${TEST_NAME}-with-plugins COMMAND ${TEST_NAME} )
    set_al_example_properties( ${TEST_NAME}-with-plugins ${DISABLED} ON "${TEST_ENVIRONMENT}" )
  endif()
endforeach()

# FIXME: Some better thought should be given on data entries! Ideally every test
# uses a separate data entry (except for the put/get coupled tests) which would
# also allow the tests to run in parallel.
#
# These plugin tests are dependent on a data entry created by test_magnetics_put
# However, they also overwrite that data entry, so test_magnetics_get MUST run
# before it (otherwise it will segfault on missing plugins)
if( AL_PLUGINS )
  set_tests_properties(
    example-fortran-test_creation_date_plugin-with-plugins
    example-fortran-test_debug_plugin-with-plugins
    PROPERTIES FIXTURES_REQUIRED "example-fortran-test_magnetics_;example-fortran-test_magnetics_get"
  )
endif()
