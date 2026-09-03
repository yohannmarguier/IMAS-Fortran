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

# Each executable below compiles the suite's shared modules for itself, and
# ALSetCompilerFlags gives this whole directory a single relative
# CMAKE_Fortran_MODULE_DIRECTORY.  Left alone the targets would write the same
# .mod files to the same path and race under a parallel build -- observed as
# `Error copying Fortran module "tests/shim/include/shim_comparison.mod"` with
# three targets in play.  Every Fortran target here therefore gets a module
# directory of its own; add one for any target added later.
function( al_shim_private_module_dir target )
  set_target_properties( ${target} PROPERTIES
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/${target}"
  )
endfunction()

# The comparison oracle is tested before any pulse-based contract assertion uses
# it.  It is deliberately self-contained in this registered suite rather than
# sharing the playground's diagnostic-only table code.
add_executable( al-fortran-test-shim-comparison
  shim_comparison.f90
  test_shim_comparison.f90
)
target_link_libraries( al-fortran-test-shim-comparison PRIVATE al-fortran )
al_shim_private_module_dir( al-fortran-test-shim-comparison )
add_test( NAME al-fortran-test-shim-comparison COMMAND al-fortran-test-shim-comparison )
# Refusals and other error-shaped text are legitimate output of later shim
# tests.  A distinctive marker plus the program's non-zero exit is the pass
# condition, and the count assertion in the program prevents a no-op test from
# passing.
# This program makes no AL call today, so it would run without the shim's
# run-time environment.  It is given it anyway: it links al-fortran, and so the
# shim, and the day an assertion here touches the C ABI the missing
# IMAS_CORE_LIBRARY would surface as an unrelated-looking dlopen failure.
set_tests_properties( al-fortran-test-shim-comparison PROPERTIES
  ENVIRONMENT "${AL_CORE_TEST_ENVIRONMENT}"
  FAIL_REGULAR_EXPRESSION "COMPARISON-FAILURE"
  LABELS "shim;contract-assertion"
)

# Fixture provenance (issue #64): the checked-in pulses must be what their
# generator produces, or every assertion in this suite is against numbers
# nobody can re-derive.  verify_fixtures.sh regenerates them outside the
# checkout and compares every dataset with h5diff; registering it here is what
# turns that from a script somebody may remember to run into a criterion the
# suite enforces.
#
# It needs the fixtures' own virtualenv and h5diff, neither of which this
# project builds, so it registers only when both are present -- the same
# pattern as the linkage test above.  A missing venv means the check is
# skipped, never that it silently passes.
set(AL_SHIM_FIXTURE_VENV_PYTHON "${CMAKE_SOURCE_DIR}/imas-python-fixtures/.venv/bin/python")
find_program(AL_SHIM_H5DIFF h5diff)
if( EXISTS "${AL_SHIM_FIXTURE_VENV_PYTHON}" AND AL_SHIM_H5DIFF )
  add_test(NAME al-fortran-test-shim-fixture-provenance
    COMMAND "${CMAKE_SOURCE_DIR}/imas-python-fixtures/verify_fixtures.sh"
  )
  set_tests_properties(al-fortran-test-shim-fixture-provenance PROPERTIES
    LABELS "shim;contract-assertion"
  )
else()
  message( STATUS
    "Not registering al-fortran-test-shim-fixture-provenance: needs "
    "imas-python-fixtures/.venv (see its README) and h5diff" )
endif()

# The HLI ends ids_get's root action itself, so it observes nested fidelity
# through the shim's process-local loss-log file, not the shim C ABI.  Give the
# test an isolated directory so the dynamic log filename cannot pick up a prior
# run's entries.
set(AL_SHIM_FIXTURE_ROOT "${CMAKE_SOURCE_DIR}/imas-python-fixtures/fixtures")
set(AL_SHIM_NESTED_LOSS_LOG_DIR "${CMAKE_CURRENT_BINARY_DIR}/nested-loss-log")
add_executable(al-fortran-test-shim-nested-loss test_shim_nested_loss.f90)
target_link_libraries(al-fortran-test-shim-nested-loss PRIVATE al-fortran)
al_shim_private_module_dir(al-fortran-test-shim-nested-loss)
add_test(NAME al-fortran-test-shim-nested-loss
  COMMAND ${CMAKE_COMMAND}
    -D "COMMAND_TO_RUN=$<TARGET_FILE:al-fortran-test-shim-nested-loss>;${AL_SHIM_FIXTURE_ROOT}"
    -D "LOSS_LOG_DIR=${AL_SHIM_NESTED_LOSS_LOG_DIR}"
    -D "FIXTURE_ROOT=${AL_SHIM_FIXTURE_ROOT}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/check_nested_loss_log.cmake"
)
set_tests_properties(al-fortran-test-shim-nested-loss PROPERTIES
  ENVIRONMENT "IMAS_MVDD_HLI_DD_VERSION=4.1.1;IMAS_MVDD_LOSS_LOG_DIR=${AL_SHIM_NESTED_LOSS_LOG_DIR};${AL_CORE_TEST_ENVIRONMENT}"
  LABELS "shim;contract-assertion"
)

# Structural rules (identical, renamed, moved, merged, split): each asserted
# by comparing a shim-converted read of the DD 3.39.0 fixture against a
# direct, same-version read of the DD 4.1.1 fixture, so no expected value is
# transcribed into this file by hand. See shim_rule_table.f90 for the table
# and its citations.
add_executable(al-fortran-test-shim-structural-rules
  shim_comparison.f90
  shim_rule_table.f90
  shim_rule_check.f90
  test_shim_structural_rules.f90
)
target_link_libraries(al-fortran-test-shim-structural-rules PRIVATE al-fortran)
al_shim_private_module_dir(al-fortran-test-shim-structural-rules)
add_test(NAME al-fortran-test-shim-structural-rules
  COMMAND al-fortran-test-shim-structural-rules "${AL_SHIM_FIXTURE_ROOT}"
)
set_tests_properties(al-fortran-test-shim-structural-rules PROPERTIES
  ENVIRONMENT "IMAS_MVDD_HLI_DD_VERSION=4.1.1;${AL_CORE_TEST_ENVIRONMENT}"
  LABELS "shim;contract-assertion"
  FAIL_REGULAR_EXPRESSION "STRUCTURAL-FAILURE"
)

# COCOS 11 -> 17 rules: every path the map's <cocos> block flips, each
# asserted the same way as the structural rules above. A sign flip that
# stops being applied reports 'NOFLIP', which shim_comparison gives mismatch
# severity, not warning severity, and this test's FAIL_REGULAR_EXPRESSION
# catches it exactly as it would any other rule failure. See
# shim_rule_table.f90 for the table, its citations, and why it carries 30
# entries rather than the 32 commonly quoted elsewhere.
add_executable(al-fortran-test-shim-cocos-rules
  shim_comparison.f90
  shim_rule_table.f90
  shim_rule_check.f90
  test_shim_cocos_rules.f90
)
target_link_libraries(al-fortran-test-shim-cocos-rules PRIVATE al-fortran)
al_shim_private_module_dir(al-fortran-test-shim-cocos-rules)
add_test(NAME al-fortran-test-shim-cocos-rules
  COMMAND al-fortran-test-shim-cocos-rules "${AL_SHIM_FIXTURE_ROOT}"
)
set_tests_properties(al-fortran-test-shim-cocos-rules PROPERTIES
  ENVIRONMENT "IMAS_MVDD_HLI_DD_VERSION=4.1.1;${AL_CORE_TEST_ENVIRONMENT}"
  LABELS "shim;contract-assertion"
  FAIL_REGULAR_EXPRESSION "COCOS-FAILURE"
)

# The right_only rules: paths DD 4 introduced with no DD 3 source, where the
# expected verdict is a value on the DD 4 side only rather than agreement.
# Same two reads as the structural rules, compared the other way round -- the
# DD 4 oracle first, the shim-served side second -- which is what makes a
# served-nothing reading report `only4`; test_shim_right_only_rules.f90 says
# why at length.
add_executable(al-fortran-test-shim-right-only-rules
  shim_comparison.f90
  shim_rule_table.f90
  shim_rule_check.f90
  test_shim_right_only_rules.f90
)
target_link_libraries(al-fortran-test-shim-right-only-rules PRIVATE al-fortran)
al_shim_private_module_dir(al-fortran-test-shim-right-only-rules)
add_test(NAME al-fortran-test-shim-right-only-rules
  COMMAND al-fortran-test-shim-right-only-rules "${AL_SHIM_FIXTURE_ROOT}"
)
# This read refuses paths, so it is a run with a non-exact outcome, and
# docs/SHIM_INTEGRATION_CONTRACT.md section 7 says such a run writes a loss
# file into IMAS_MVDD_LOSS_LOG_DIR -- or into the working directory when that
# is unset, which would drop it in the build tree and leave it for whichever
# test looks there next. This test asserts nothing about the loss log; it
# points it somewhere private purely so it cannot be mistaken for another
# test's artifact. The directory has to exist before the run, hence
# file(MAKE_DIRECTORY) at configure time.
set(AL_SHIM_RIGHT_ONLY_LOSS_LOG_DIR "${CMAKE_CURRENT_BINARY_DIR}/right-only-loss-log")
file(MAKE_DIRECTORY "${AL_SHIM_RIGHT_ONLY_LOSS_LOG_DIR}")
set_tests_properties(al-fortran-test-shim-right-only-rules PROPERTIES
  ENVIRONMENT "IMAS_MVDD_HLI_DD_VERSION=4.1.1;IMAS_MVDD_LOSS_LOG_DIR=${AL_SHIM_RIGHT_ONLY_LOSS_LOG_DIR};${AL_CORE_TEST_ENVIRONMENT}"
  LABELS "shim;contract-assertion"
  FAIL_REGULAR_EXPRESSION "RIGHT-ONLY-FAILURE"
)

# The rules the map refuses: the one `retyped` rule and the four unit
# `redefine` globs.  Same two reads as the structural rules, asserted the
# other way round -- the two sides must not agree -- and paired with the
# read-side skip log, because for a redefinition both fixtures hold the same
# number and only the skip log tells a refusal from a passthrough.
#
# This test asserts the Fortran-side skip log, which is a different channel
# from the shim's loss log file, but it still needs its own loss-log
# directory: leaving IMAS_MVDD_LOSS_LOG_DIR unset is not neutral, because the
# shim then writes the loss log into the current working directory.  Giving
# it a directory of its own -- rather than the empty value the shim reads as
# "disable" -- keeps the suite parallel-safe and leaves the channel there for
# a later test to assert.  It is not cleaned before the run because nothing
# here reads it; the test that does own that (al-fortran-test-shim-nested-loss)
# cleans its own through a CMake wrapper.
set(AL_SHIM_REFUSAL_LOSS_LOG_DIR "${CMAKE_CURRENT_BINARY_DIR}/refusal-loss-log")
file(MAKE_DIRECTORY "${AL_SHIM_REFUSAL_LOSS_LOG_DIR}")
add_executable(al-fortran-test-shim-refusal-rules
  shim_comparison.f90
  shim_rule_table.f90
  shim_rule_check.f90
  test_shim_refusal_rules.f90
)
target_link_libraries(al-fortran-test-shim-refusal-rules PRIVATE al-fortran)
al_shim_private_module_dir(al-fortran-test-shim-refusal-rules)
add_test(NAME al-fortran-test-shim-refusal-rules
  COMMAND al-fortran-test-shim-refusal-rules "${AL_SHIM_FIXTURE_ROOT}"
)
# The program prints refusal- and error-shaped text as expected output, so the
# pass condition is its own marker plus a zero exit, never the absence of the
# word "error".
set_tests_properties(al-fortran-test-shim-refusal-rules PROPERTIES
  ENVIRONMENT "IMAS_MVDD_HLI_DD_VERSION=4.1.1;IMAS_MVDD_LOSS_LOG_DIR=${AL_SHIM_REFUSAL_LOSS_LOG_DIR};${AL_CORE_TEST_ENVIRONMENT}"
  LABELS "shim;contract-assertion"
  FAIL_REGULAR_EXPRESSION "REFUSAL-FAILURE"
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
