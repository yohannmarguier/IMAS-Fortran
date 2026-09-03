# Run an HLI-side scenario with a private loss-log directory and prove the
# shim left no log behind.  No log is the Tier-1 observable for no loss.
if( NOT DEFINED COMMAND_TO_RUN OR NOT DEFINED LOSS_LOG_DIR )
  message(FATAL_ERROR "COMMAND_TO_RUN and LOSS_LOG_DIR are required")
endif()

file(MAKE_DIRECTORY "${LOSS_LOG_DIR}")
file(GLOB _old_logs "${LOSS_LOG_DIR}/imas-mvdd-loss-*.txt")
if( _old_logs )
  file(REMOVE ${_old_logs})
endif()

execute_process(
  COMMAND ${COMMAND_TO_RUN}
  RESULT_VARIABLE _result
  OUTPUT_VARIABLE _stdout
  ERROR_VARIABLE _stderr
)
if( NOT _result EQUAL 0 )
  message(FATAL_ERROR "stamp scenario failed (${_result})\nstdout:\n${_stdout}\nstderr:\n${_stderr}")
endif()

file(GLOB _logs "${LOSS_LOG_DIR}/imas-mvdd-loss-*.txt")
list(LENGTH _logs _log_count)
if( NOT _log_count EQUAL 0 )
  message(FATAL_ERROR "stamp scenario logged loss despite plain forwarding/refusal: ${_logs}")
endif()
