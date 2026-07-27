# Shared CTest conventions used by more than one part of the build.
#
# This repo's CTest harness fails a test whose stdout/stderr matches
# AL_CTEST_FAIL_REGULAR_EXPRESSION, case-insensitively, even when the
# process exits 0. Anything that registers a CTest test with this
# convention (currently ALExampleUtilities.cmake and engine/tests/contract)
# should reuse this single definition rather than repeating the literal.

set( AL_CTEST_FAIL_REGULAR_EXPRESSION
  # fault|error[^_]|exception|severe|abort|segmentation|fault|dump|logic_error|failed
  "[Ff][Aa][Uu][Ll][Tt]|[Ee][Rr][Rr][Oo][Rr][^_]|[Ee][Xx][Cc][Ee][Pp][Tt][Ii][Oo][Nn]|[Ss][Ee][Vv][Ee][Rr][Ee]|[Aa][Bb][Oo][Rr][Tt]|[Ss][Ee][Gg][Mm][Ee][Nn][Tt][Aa][Tt][Ii][Oo][Nn]|[Ff][Aa][Uu][Ll][Tt]|[Dd][Uu][Mm][Pp]|[Ll][Oo][Gg][Ii][Cc]_[Ee][Rr][Rr][Oo][Rr]|[Ff][Aa][Ii][Ll][Ee][Dd]"
)
