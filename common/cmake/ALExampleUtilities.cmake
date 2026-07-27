# CMake file providing common logic to test AL examples

include( ALCTestConventions )

set( EXAMPLE_ENVIRONMENT_WITHOUT_PLUGINS
  "IMAS_AL_ENABLE_PLUGINS=FALSE"
)

if( AL_PLUGINS )
  get_target_property( PLUGIN_DIR al-plugins BINARY_DIR )
  set( EXAMPLE_ENVIRONMENT_WITH_PLUGINS 
    ${TEST_ENVIRONMENT}
    "IMAS_AL_ENABLE_PLUGINS=TRUE"
    "IMAS_AL_PLUGINS=${PLUGIN_DIR}"
  )
endif()

function( set_al_example_properties TEST DISABLED USE_PLUGINS EXTRA_ENVIRONMENT )
  # Set common properties
  set_tests_properties( ${TEST} PROPERTIES
    FAIL_REGULAR_EXPRESSION "${AL_CTEST_FAIL_REGULAR_EXPRESSION}"
    DISABLED ${DISABLED}
  )

  # Set environment variables
  if( USE_PLUGINS )
    set( P_ENV ${EXAMPLE_ENVIRONMENT_WITH_PLUGINS} )
  else()
    set( P_ENV ${EXAMPLE_ENVIRONMENT_WITHOUT_PLUGINS} )
  endif()
  set_tests_properties( ${TEST} PROPERTIES ENVIRONMENT "${P_ENV};${EXTRA_ENVIRONMENT}" )

  # Set fixtures: put/put_slice must run before get/get_slice
  string( TOLOWER ${TEST} TEST_LOWER )
  string( REGEX REPLACE "put|get" "" FIXTURE_NAME ${TEST_LOWER} )
  if( TEST_LOWER MATCHES "put" )
    set_tests_properties( ${TEST} PROPERTIES FIXTURES_SETUP ${FIXTURE_NAME} )
  elseif( TEST_LOWER MATCHES "get" )
    set_tests_properties( ${TEST} PROPERTIES FIXTURES_REQUIRED ${FIXTURE_NAME} )
  endif()
endfunction()


function( error_on_missing_tests SOURCE_EXTENSION TESTS )
  file( GLOB _SRCS "*.${SOURCE_EXTENSION}" )
  foreach( _SRC IN LISTS _SRCS )
    string( REGEX REPLACE "^.*[/\\]|[.]${SOURCE_EXTENSION}$" "" _SRC_STEM ${_SRC} )
    list( FIND TESTS ${_SRC_STEM} FOUND )
    if( FOUND EQUAL -1 )
      message( SEND_ERROR "Source file ${_SRC} found, but no corresponding test exists" )
    endif()
  endforeach()
endfunction()

