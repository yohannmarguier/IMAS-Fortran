# Linkage test for the multiversion shim
#
# Registered only in a shim build: with AL_USE_MULTIVERSION_SHIM off there is
# nothing to assert and the test list stays exactly what it was.

if( WIN32 )
  # The shim resolves AL core through dlopen/dlsym, so a shim build is POSIX-only.
  message( STATUS "Not registering al-fortran-test-shim-linkage: not supported on Windows" )
  return()
endif()

# otool and objdump report a shared library's dependencies in different formats,
# but both spell the dependency's file name, which is all this test looks for.
if( APPLE )
  find_program( AL_SHIM_INSPECT_TOOL otool )
  set( AL_SHIM_INSPECT_ARGS -L )
elseif( CMAKE_OBJDUMP )
  # What CMake itself uses for dependency inspection.
  set( AL_SHIM_INSPECT_TOOL ${CMAKE_OBJDUMP} )
  set( AL_SHIM_INSPECT_ARGS -p )
else()
  find_program( AL_SHIM_INSPECT_TOOL objdump )
  set( AL_SHIM_INSPECT_ARGS -p )
endif()

if( NOT AL_SHIM_INSPECT_TOOL )
  message( STATUS "Not registering al-fortran-test-shim-linkage: no dependency inspection tool found" )
  return()
endif()

add_test( NAME al-fortran-test-shim-linkage
  COMMAND ${CMAKE_COMMAND}
    -D "LIBRARY=$<TARGET_FILE:al-fortran>"
    -D "INSPECT_TOOL=${AL_SHIM_INSPECT_TOOL}"
    -D "INSPECT_ARGS=${AL_SHIM_INSPECT_ARGS}"
    -D "SHIM_LIBRARY_NAME=${AL_SHIM_LIBRARY_NAME}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/check_shim_linkage.cmake"
)

# The comparison oracle is tested before any pulse-based contract assertion uses
# it.  It is deliberately self-contained in this registered suite rather than
# sharing the playground's diagnostic-only table code.
add_executable( al-fortran-test-shim-comparison
  shim_comparison.f90
  test_shim_comparison.f90
)
target_link_libraries( al-fortran-test-shim-comparison PRIVATE al-fortran )
add_test( NAME al-fortran-test-shim-comparison COMMAND al-fortran-test-shim-comparison )
# Refusals and other error-shaped text are legitimate output of later shim
# tests.  A distinctive marker plus the program's non-zero exit is the pass
# condition, and the count assertion in the program prevents a no-op test from
# passing.
set_tests_properties( al-fortran-test-shim-comparison PROPERTIES
  FAIL_REGULAR_EXPRESSION "COMPARISON-FAILURE"
  LABELS "shim;contract-assertion"
)

# The HLI ends ids_get's root action itself, so it observes nested fidelity
# through the shim's process-local loss-log file, not the shim C ABI.  Give the
# test an isolated directory so the dynamic log filename cannot pick up a prior
# run's entries.
set(AL_SHIM_FIXTURE_ROOT "${CMAKE_SOURCE_DIR}/imas-python-fixtures/fixtures")
set(AL_SHIM_NESTED_LOSS_LOG_DIR "${CMAKE_CURRENT_BINARY_DIR}/nested-loss-log")
add_executable(al-fortran-test-shim-nested-loss test_shim_nested_loss.f90)
target_link_libraries(al-fortran-test-shim-nested-loss PRIVATE al-fortran)
add_test(NAME al-fortran-test-shim-nested-loss
  COMMAND ${CMAKE_COMMAND}
    -D "COMMAND_TO_RUN=$<TARGET_FILE:al-fortran-test-shim-nested-loss>;${AL_SHIM_FIXTURE_ROOT}"
    -D "LOSS_LOG_DIR=${AL_SHIM_NESTED_LOSS_LOG_DIR}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/check_nested_loss_log.cmake"
)
set_tests_properties(al-fortran-test-shim-nested-loss PROPERTIES
  ENVIRONMENT "IMAS_MVDD_HLI_DD_VERSION=4.1.1;IMAS_MVDD_LOSS_LOG_DIR=${AL_SHIM_NESTED_LOSS_LOG_DIR};${AL_CORE_TEST_ENVIRONMENT}"
  LABELS "shim;contract-assertion"
)

# The write tests must mutate only private fixture copies.  Each setup test is
# a CTest fixture, so a selected scenario is prepared too and parallel runs do
# not share a pulse directory.
add_executable(al-fortran-test-shim-roundtrip test_shim_roundtrip.f90)
target_link_libraries(al-fortran-test-shim-roundtrip PRIVATE al-fortran)

function(add_shim_roundtrip_test name fixture read_control)
  set(copy_test "al-fortran-test-shim-${name}-fixture")
  set(test_name "al-fortran-test-shim-${name}")
  set(fixture_copy "${CMAKE_CURRENT_BINARY_DIR}/${name}-fixture")

  add_test(NAME ${copy_test}
    COMMAND ${CMAKE_COMMAND}
      -D "SOURCE=${AL_SHIM_FIXTURE_ROOT}/${fixture}"
      -D "DESTINATION=${fixture_copy}"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/copy_fixture.cmake"
  )
  set_tests_properties(${copy_test} PROPERTIES FIXTURES_SETUP ${test_name})

  add_test(NAME ${test_name}
    COMMAND al-fortran-test-shim-roundtrip ${fixture_copy} ${read_control}
  )
  set_tests_properties(${test_name} PROPERTIES
    FIXTURES_REQUIRED ${test_name}
    ENVIRONMENT "IMAS_MVDD_HLI_DD_VERSION=4.1.1;${AL_CORE_TEST_ENVIRONMENT}"
    LABELS "shim;contract-assertion"
  )
endfunction()

# This pair is one argument: only the DD 3 pulse exercises the map, and the
# DD 4 control rules out a vacuous roundtrip that succeeds without conversion.
add_shim_roundtrip_test(roundtrip-cross-dd dd-3.39.0 partial-read-allowed)
add_shim_roundtrip_test(roundtrip-same-dd dd-4.1.1 clean-read)
