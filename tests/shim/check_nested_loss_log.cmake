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
string(REPLACE "\n" ";" _lines "${_contents}")

# These two lines are a versioned interface, not incidental diagnostics.  In
# particular, reading data below without first pinning this marker could make a
# format change look like a test with no losses.
list(GET _lines 0 _format_marker)
if( NOT _format_marker STREQUAL "# imas-mvdd loss log format 1" )
  message(FATAL_ERROR "unexpected loss-log format marker: ${_format_marker}")
endif()

# The header is tab-separated data, not a comment.  Skip it by its fixed
# position after the four-line preamble; filtering comment-prefixed lines would
# incorrectly feed the header to the loss-entry parser.
list(GET _lines 4 _header)
if( NOT _header STREQUAL "uri${_tab}ids${_tab}stored-dd${_tab}hli-dd${_tab}operation${_tab}fidelity${_tab}path" )
  message(FATAL_ERROR "unexpected loss-log column header: ${_header}")
endif()
list(SUBLIST _lines 5 -1 _records)

set(_expected_records
  "read${_tab}LOSSY${_tab}time_slice/boundary/rho_tor"
  "read${_tab}LOSSY${_tab}time_slice/boundary/phi"
  "read${_tab}LOSSY${_tab}time_slice/boundary/phi_poloidal_current"
  "read${_tab}LOSSY${_tab}time_slice/contour_tree/edges"
  "read${_tab}UNMAPPABLE${_tab}time_slice/constraints/x_point/chi_squared_r"
  "read${_tab}UNMAPPABLE${_tab}time_slice/constraints/x_point/chi_squared_z"
  "read${_tab}UNMAPPABLE${_tab}time_slice/constraints/strike_point/chi_squared_r"
  "read${_tab}UNMAPPABLE${_tab}time_slice/constraints/strike_point/chi_squared_z"
  "read${_tab}LOSSY${_tab}time_slice/constraints/chi_squared_reduced"
  "read${_tab}LOSSY${_tab}time_slice/constraints/freedom_degrees_n"
  "read${_tab}LOSSY${_tab}time_slice/constraints/constraints_n"
  "read${_tab}LOSSY${_tab}time_slice/global_quantities/rho_tor_boundary"
  "read${_tab}LOSSY${_tab}time_slice/global_quantities/q_min/psi_norm"
  "read${_tab}LOSSY${_tab}time_slice/global_quantities/q_min/psi"
  "read${_tab}LOSSY${_tab}time_slice/profiles_1d/psi_norm"
  "read${_tab}LOSSY${_tab}time_slice/convergence/result/name"
  "read${_tab}LOSSY${_tab}time_slice/convergence/result/index"
  "read${_tab}LOSSY${_tab}time_slice/convergence/result/description"
)
set(_actual_records)
foreach(_record IN LISTS _records)
  if( _record STREQUAL "" )
    continue()
  endif()
  string(REPLACE "${_tab}" ";" _columns "${_record}")
  list(LENGTH _columns _column_count)
  if( NOT _column_count EQUAL 7 )
    message(FATAL_ERROR "loss-log entry has ${_column_count} columns: ${_record}")
  endif()
  list(GET _columns 4 _operation)
  list(GET _columns 5 _fidelity)
  list(GET _columns 6 _path)
  list(APPEND _actual_records "${_operation}${_tab}${_fidelity}${_tab}${_path}")
endforeach()
list(SORT _expected_records)
list(SORT _actual_records)
if( NOT _actual_records STREQUAL _expected_records )
  list(JOIN _expected_records "\n" _expected_display)
  list(JOIN _actual_records "\n" _actual_display)
  message(FATAL_ERROR "unexpected operation-fidelity-path set\nexpected:\n${_expected_display}\nactual:\n${_actual_display}")
endif()
