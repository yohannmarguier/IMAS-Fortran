# The alias layer's own test: that a bare name and its version-suffixed spelling denote
# one entity, and that either front door on its own is a complete way in.
#
# The bulk of the alias layer is tested far more thoroughly than this by the pre-existing
# consumers that compile against it - the generated per-IDS test suite and the 63
# identifier modules reach the library entirely through bare names, so a hole in the
# layer breaks the build before any test runs. What they cannot show is that the bare
# name is the *same* type rather than a second one that looks like it; that is what this
# program is for.

# The test names one IDS. Any will do - it is the naming that is under test, not the IDS -
# so take the first one this build has, which keeps the test working under AL_IDS_SUBSET.
list( GET IDS_NAMES 0 ALIAS_TEST_IDS )

configure_file( alias_test.f90.in alias_test.f90 @ONLY )

add_executable( al-fortran-test-alias ${CMAKE_CURRENT_BINARY_DIR}/alias_test.f90 )
target_link_libraries( al-fortran-test-alias al-fortran )
add_dependencies( al-fortran-test-alias al-fortran-sources )
# al-fortran-tests is the aggregate target tests/generator declares; building it must
# build this test too.
add_dependencies( al-fortran-tests al-fortran-test-alias )

add_test( NAME al-fortran-test-alias COMMAND al-fortran-test-alias )
set_tests_properties( al-fortran-test-alias PROPERTIES
  FAIL_REGULAR_EXPRESSION "[Ee][Rr][Rr][Oo][Rr]"
)
