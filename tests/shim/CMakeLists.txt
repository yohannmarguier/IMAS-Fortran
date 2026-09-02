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
