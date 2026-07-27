# C-level contract test for the projection-engine ABI (see engine/README.md).
# This is the seam every later slice of the engine adds vectors to.

include( ALCTestConventions )

add_executable( projection-engine-contract-test test_contract.c )
target_link_libraries( projection-engine-contract-test PRIVATE imas-projection-engine )

add_test( NAME projection-engine-contract-test COMMAND projection-engine-contract-test )
set_tests_properties( projection-engine-contract-test PROPERTIES
  # See engine/README.md for how this test's deliberate negative paths
  # avoid AL_CTEST_FAIL_REGULAR_EXPRESSION.
  FAIL_REGULAR_EXPRESSION "${AL_CTEST_FAIL_REGULAR_EXPRESSION}"
)
