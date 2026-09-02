# Run a cross-DD HLI read and inspect its Tier-1 loss-log file.  This stays at
# the HLI boundary: direct imas_mvdd_context_loss_* calls are a shim-repository
# concern (ADR 0002), while the file is the only loss channel this binding owns.
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
  message(FATAL_ERROR "nested loss reader failed (${_result})\nstdout:\n${_stdout}\nstderr:\n${_stderr}")
endif()

file(GLOB _logs "${LOSS_LOG_DIR}/imas-mvdd-loss-*.txt")
list(LENGTH _logs _log_count)
if( NOT _log_count EQUAL 1 )
  message(FATAL_ERROR "expected one isolated loss log, found ${_log_count} in ${LOSS_LOG_DIR}")
endif()
list(GET _logs 0 _log)
file(READ "${_log}" _contents)
string(ASCII 9 _tab)
string(REPLACE "\n" ";" _records "${_contents}")

function(require_record fidelity path)
  foreach(_record IN LISTS _records)
    string(REPLACE "${_tab}" ";" _columns "${_record}")
    list(LENGTH _columns _column_count)
    if( _column_count LESS 7 )
      continue()
    endif()
    list(GET _columns 4 _operation)
    list(GET _columns 5 _fidelity)
    list(GET _columns 6 _path)
    if( _operation STREQUAL "read" AND _fidelity STREQUAL "${fidelity}" AND _path STREQUAL "${path}" )
      return()
    endif()
  endforeach()
  message(FATAL_ERROR "missing read loss record: ${fidelity} ${path}\nlog:\n${_contents}")
endfunction()

function(require_no_record path)
  foreach(_record IN LISTS _records)
    string(REPLACE "${_tab}" ";" _columns "${_record}")
    list(LENGTH _columns _column_count)
    if( _column_count LESS 7 )
      continue()
    endif()
    list(GET _columns 6 _path)
    if( _path STREQUAL "${path}" )
      message(FATAL_ERROR "unexpected loss record: ${path}\nlog:\n${_contents}")
    endif()
  endforeach()
endfunction()

# Both paths are beneath arraystruct contexts.  The paths must remain the HLI
# spellings requested by generated getters, rather than a translated stored-DD
# candidate or a child-relative suffix.
require_record("LOSSY" "time_slice/boundary/rho_tor")
require_record("UNMAPPABLE" "time_slice/constraints/x_point/chi_squared_r")

# An exact nested field is traversed in the same ids_get but must not create a
# loss entry merely because its root is version-mismatched.
require_no_record("time_slice/global_quantities/ip")
