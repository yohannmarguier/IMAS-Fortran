# Runs a command and fails only if it was killed by a signal.
#
# This is a regression guard for the arraystruct-refusal double-close fixed in
# IDSDef2F90Routines.xsl: a refused al_begin_arraystruct_action used to make the
# generated failure arm end its caller's context, which the caller then ended a
# second time, and IMAS-Core's delLLenv has no released-slot guard. The symptom
# was always a signal, never a status.
#
# The signal guard is unconditional and is the reason this wrapper exists.
#
# EXPECT_STATUS is optional. It was left out while "must a refusal stop the whole
# read?" was open, because pinning the exit code would have made this test fail
# the moment that question was answered. It has been answered -- a refusal is
# tolerated and the read completes -- so the cross-version test now pins 0.
# Omitting EXPECT_STATUS keeps the old indifferent behaviour.
#
# stdout and stderr are echoed so ctest's PASS_REGULAR_EXPRESSION /
# FAIL_REGULAR_EXPRESSION can see the program's own output; execute_process
# captures it, so without this it would be invisible.
#
# Invoked by playground/CMakeLists.txt.

foreach( _var COMMAND_TO_RUN )
  if( NOT DEFINED ${_var} )
    message( FATAL_ERROR "check_no_signal.cmake: -D ${_var}=... is required" )
  endif()
endforeach()

# A ;-separated list arrives as one -D value; COMMAND takes it as an argv.
execute_process(
  COMMAND ${COMMAND_TO_RUN}
  RESULT_VARIABLE _result
  OUTPUT_VARIABLE _stdout
  ERROR_VARIABLE _stderr
)

# execute_process reports a signal either as a number above 128 or, on some
# platforms, as a descriptive string ("Segmentation fault"). Neither is an
# ordinary exit status, so both are failures here.
set( _killed OFF )
if( _result MATCHES "^[0-9]+$" )
  if( _result GREATER_EQUAL 128 )
    set( _killed ON )
  endif()
else()
  set( _killed ON )
endif()

if( _killed )
  message( FATAL_ERROR
    "Killed by a signal (${_result}) instead of returning a status. This is the "
    "arraystruct-refusal double-close: a failed al_begin_arraystruct_action must "
    "leave the enclosing context alone, because its owner ends it.\n"
    "--- stdout ---\n${_stdout}\n--- stderr ---\n${_stderr}"
  )
endif()

message( STATUS "Exited with status ${_result}; not killed by a signal." )

# Echo before any status check, so a failure report carries the output too.
if( _stdout )
  message( "${_stdout}" )
endif()
if( _stderr )
  message( "${_stderr}" )
endif()

if( DEFINED EXPECT_STATUS AND ( NOT _result STREQUAL EXPECT_STATUS ) )
  message( FATAL_ERROR
    "Expected exit status ${EXPECT_STATUS}, got ${_result}."
  )
endif()
