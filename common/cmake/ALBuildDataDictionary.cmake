# Everything needed for building the Data Dictionary
#
# This script sets the following variables:
#   IDSDEF            Path to the generated IDSDef.xml
#   IDS_NAMES         List of IDSs that are available in the data dictionary
#   DD_VERSION        Version of the data dictionary
#   DD_SAFE_VERSION   DD version, safe to use as linker symbol
#   DD_MODULE_SUFFIX  DD version as a Fortran identifier suffix (e.g. _v4_1_1), which
#                     every generated module and derived type name carries
#
# When AL_SECOND_DD_IDSDEF names a second Data Dictionary version to compile into the
# same library, it also sets, for that version:
#   SECOND_IDSDEF            Path to its IDSDef.xml, pruned to AL_IDS_SUBSET if set
#   SECOND_DD_VERSION        Its version, read from that file
#   SECOND_DD_MODULE_SUFFIX  Its Fortran identifier suffix (e.g. _v3_39_0)
# and leaves them undefined otherwise, so `if( AL_SECOND_DD_IDSDEF )` is what decides
# whether a build has a second version.

if( AL_DOCS_ONLY )
  return()
endif()

# Find Python for the xsltproc.py program
if(WIN32)
  if(NOT Python3_FOUND AND NOT PYTHON_EXECUTABLE)
	  # Check if Python is in PATH
	  find_program(PYTHON_EXECUTABLE NAMES python3.exe python.exe python3 python DOC "Python interpreter")
	  if(NOT PYTHON_EXECUTABLE)
	    message(FATAL_ERROR "Could not find Python. Please ensure Python is installed and in PATH.")
	  endif()
  else()
	  set(PYTHON_EXECUTABLE ${Python3_EXECUTABLE})
  endif()
else()
	find_package(Python REQUIRED COMPONENTS Interpreter Development.Module)
	set(PYTHON_EXECUTABLE ${Python_EXECUTABLE})
endif()

message(STATUS "Found Python: ${PYTHON_EXECUTABLE}")

# Set up Python venv paths for saxonche (used for all XSLT transformations)
if(WIN32)
  set(_VENV_PYTHON "${CMAKE_CURRENT_BINARY_DIR}/dd_build_env/Scripts/python.exe")
  set(_VENV_PIP "${CMAKE_CURRENT_BINARY_DIR}/dd_build_env/Scripts/pip.exe")
else()
  set(_VENV_PYTHON "${CMAKE_CURRENT_BINARY_DIR}/dd_build_env/bin/python")
  set(_VENV_PIP "${CMAKE_CURRENT_BINARY_DIR}/dd_build_env/bin/pip")
endif()

if( NOT AL_DOWNLOAD_DEPENDENCIES AND NOT AL_DEVELOPMENT_LAYOUT )
  if(DEFINED DD_VERSION)
    if(WIN32)
      set(_IDSINFO_COMMAND "${CMAKE_CURRENT_BINARY_DIR}/dd_build_env/Scripts/idsinfo.exe")
    else()
      set(_IDSINFO_COMMAND "${CMAKE_CURRENT_BINARY_DIR}/dd_build_env/bin/idsinfo")
    endif()
  else()
    if(WIN32)
      set(_IDSINFO_COMMAND "idsinfo.exe")
    else()
      set(_IDSINFO_COMMAND "idsinfo")
    endif()
  endif()

  if(NOT EXISTS "${_VENV_PYTHON}")
    execute_process(
      COMMAND ${PYTHON_EXECUTABLE} -m venv dd_build_env
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      RESULT_VARIABLE _VENV_EXITCODE
      OUTPUT_VARIABLE _VENV_OUTPUT
      ERROR_VARIABLE _VENV_ERROR
    )
    
    if(_VENV_EXITCODE)
      message(STATUS "venv stdout: ${_VENV_OUTPUT}")
      message(STATUS "venv stderr: ${_VENV_ERROR}")
      message(FATAL_ERROR "Failed to create venv (exit code: ${_VENV_EXITCODE}). Ensure Python has venv module installed: python -m venv --help")
    endif()
    
    if(DEFINED DD_VERSION)
      execute_process(
        COMMAND ${_VENV_PIP} install imas_data_dictionary==${DD_VERSION}
        RESULT_VARIABLE _PIP_EXITCODE
        OUTPUT_VARIABLE _PIP_OUTPUT
        ERROR_VARIABLE _PIP_ERROR
      )
      if(_PIP_EXITCODE)
        message(STATUS "imas_data_dictionary pip output: ${_PIP_OUTPUT}")
        message(STATUS "imas_data_dictionary pip error: ${_PIP_ERROR}")
        message(FATAL_ERROR "Failed to install imas_data_dictionary dependency (exit code: ${_PIP_EXITCODE}). Check network connectivity and Python wheel compatibility.")
      endif()
    endif()

    # install saxonche dependency
    execute_process(
      COMMAND ${_VENV_PIP} install saxonche
      RESULT_VARIABLE _PIP_EXITCODE
      OUTPUT_VARIABLE _PIP_OUTPUT
      ERROR_VARIABLE _PIP_ERROR
    )
    
    if(_PIP_EXITCODE)
      message(STATUS "saxonche pip output: ${_PIP_OUTPUT}")
      message(STATUS "saxonche pip error: ${_PIP_ERROR}")
      message(FATAL_ERROR "Failed to install saxonche dependency (exit code: ${_PIP_EXITCODE}). Check network connectivity and Python wheel compatibility.")
    endif()
  endif()

  # Use idsinfo idspath command from venv to get the path to IDSDef.xml or data_dictionary.xml
  execute_process(
    COMMAND ${_IDSINFO_COMMAND} idspath
    OUTPUT_VARIABLE IDSDEF
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _IDSINFO_EXITCODE
  )
  
  if( _IDSINFO_EXITCODE )
    message( FATAL_ERROR 
      "Failed to run 'idsinfo idspath' command. "
      "Please ensure IMAS-Data-Dictionary module is loaded."
    )
  endif()
  
  if( NOT EXISTS "${IDSDEF}" )
    message( FATAL_ERROR 
      "idsinfo idspath returned '${IDSDEF}' but file does not exist. "
      "Please ensure IMAS-Data-Dictionary module is properly loaded."
    )
  endif()
  
  message( STATUS "Found Data Dictionary: ${IDSDEF}" )

  # Populate identifier source xmls based on the IDSDEF location 
  get_filename_component( DD_BASE_DIR "${IDSDEF}" DIRECTORY )
  
  if( DD_BASE_DIR MATCHES "schemas$" )
    # DD 4.1.0+ layout: resources/schemas/<ids_name>/*_identifier.xml
    file( GLOB DD_IDENTIFIER_FILES "${DD_BASE_DIR}/*/*_identifier.xml" )
  else()
    # DD 3.x/4.0.0 layout: dd_x.y.z/include/<ids_name>/*_identifier.xml
    file( GLOB DD_IDENTIFIER_FILES "${DD_BASE_DIR}/*/*_identifier.xml" )
  endif()
  
  if( NOT DD_IDENTIFIER_FILES )
    message( WARNING "No identifier XML files found in Data Dictionary at: ${IDSDEF}" )
  endif()
else()
  if(WIN32)
    # Build the DD from source using direct git commands:
    if( AL_DOWNLOAD_DEPENDENCIES )
      # Download the Data Dictionary from the ITER git:
      set( data-dictionary_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/data-dictionary-src" )
      if( NOT EXISTS "${data-dictionary_SOURCE_DIR}/.git" )
        message( STATUS "Cloning data-dictionary from ${DD_GIT_REPOSITORY}" )
        execute_process(
          COMMAND git clone "${DD_GIT_REPOSITORY}" "${data-dictionary_SOURCE_DIR}"
          RESULT_VARIABLE _GIT_CLONE_RESULT
          ERROR_VARIABLE _GIT_CLONE_ERROR
        )
        if( _GIT_CLONE_RESULT )
          message( FATAL_ERROR "Failed to clone data-dictionary: ${_GIT_CLONE_ERROR}" )
        endif()
      endif()
      # Checkout the specified version
      execute_process(
        COMMAND git fetch origin
        WORKING_DIRECTORY "${data-dictionary_SOURCE_DIR}"
        RESULT_VARIABLE _GIT_FETCH_RESULT
      )
      execute_process(
        COMMAND git checkout "${DD_VERSION}"
        WORKING_DIRECTORY "${data-dictionary_SOURCE_DIR}"
        RESULT_VARIABLE _GIT_CHECKOUT_RESULT
        ERROR_VARIABLE _GIT_CHECKOUT_ERROR
      )
      if( _GIT_CHECKOUT_RESULT )
        message( FATAL_ERROR "Failed to checkout ${DD_VERSION}: ${_GIT_CHECKOUT_ERROR}" )
      endif()
    else()
      # Look in ../data-dictionary for the data dictionary
      if( NOT( AL_PARENT_FOLDER ) )
        set( AL_PARENT_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/.. )
      endif()
      set( data-dictionary_SOURCE_DIR ${AL_PARENT_FOLDER}/IMAS-Data-Dictionary )
      if( NOT IS_DIRECTORY ${data-dictionary_SOURCE_DIR} )
        message( FATAL_ERROR
          "${data-dictionary_SOURCE_DIR} does not exist. Please clone the "
          "data-dictionary repository or set AL_DOWNLOAD_DEPENDENCIES=ON."
        )
      endif()
    endif() 
  else()
    # Build the DD from source:
    include(FetchContent)

    if( AL_DOWNLOAD_DEPENDENCIES )
      # Download the Data Dictionary from the ITER git:
      FetchContent_Declare(
        data-dictionary
        GIT_REPOSITORY  ${DD_GIT_REPOSITORY}
        GIT_TAG         ${DD_VERSION}
      )
    else()
      # Look in ../data-dictionary for the data dictionary
      if( NOT( AL_PARENT_FOLDER ) )
        set( AL_PARENT_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/.. )
      endif()
      set( DD_SOURCE_DIRECTORY ${AL_PARENT_FOLDER}/IMAS-Data-Dictionary )
      if( NOT IS_DIRECTORY ${DD_SOURCE_DIRECTORY} )
        message( FATAL_ERROR
          "${DD_SOURCE_DIRECTORY} does not exist. Please clone the "
          "IMAS-Data-Dictionary repository or set AL_DOWNLOAD_DEPENDENCIES=ON."
        )
      endif()

      FetchContent_Declare(
        data-dictionary
        SOURCE_DIR      ${DD_SOURCE_DIRECTORY}
      )
      set( DD_SOURCE_DIRECTORY )  # unset temporary var
    endif()
    FetchContent_MakeAvailable( data-dictionary )
  endif()


  # get version of the data dictionary
  execute_process(
    COMMAND git describe --tags --always --dirty
    WORKING_DIRECTORY ${data-dictionary_SOURCE_DIR}
    OUTPUT_VARIABLE DD_GIT_DESCRIBE
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _GIT_RESULT
  )
  if(_GIT_RESULT)
    execute_process(
      COMMAND git rev-parse --short HEAD
      WORKING_DIRECTORY ${data-dictionary_SOURCE_DIR}
      OUTPUT_VARIABLE DD_GIT_DESCRIBE
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  endif()

  # We need the IDSDef.xml at configure time, ensure it is built
  # Create Python venv and install saxonche if not already done
  if(NOT EXISTS "${_VENV_PYTHON}")
    execute_process(
      COMMAND ${PYTHON_EXECUTABLE} -m venv dd_build_env
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      RESULT_VARIABLE _VENV_EXITCODE
      OUTPUT_VARIABLE _VENV_OUTPUT
      ERROR_VARIABLE _VENV_ERROR
    )
    
    if(_VENV_EXITCODE)
      message(STATUS "venv stdout: ${_VENV_OUTPUT}")
      message(STATUS "venv stderr: ${_VENV_ERROR}")
      message(FATAL_ERROR "Failed to create venv (exit code: ${_VENV_EXITCODE}). Ensure Python has venv module installed: python -m venv --help")
    endif()

    execute_process(
      COMMAND ${_VENV_PIP} install saxonche
      RESULT_VARIABLE _PIP_EXITCODE
      OUTPUT_VARIABLE _PIP_OUTPUT
      ERROR_VARIABLE _PIP_ERROR
    )
    
    if(_PIP_EXITCODE)
      message(STATUS "saxonche pip output: ${_PIP_OUTPUT}")
      message(STATUS "saxonche pip error: ${_PIP_ERROR}")
      message(FATAL_ERROR "Failed to install saxonche dependency (exit code: ${_PIP_EXITCODE}). Check network connectivity and Python wheel compatibility.")
    endif()
  endif()
  
  execute_process(
    COMMAND ${_VENV_PYTHON} "${AL_LOCAL_XSLTPROC_SCRIPT}"
      -xsl "dd_data_dictionary.xml.xsl"
      -o "IDSDef.xml"
      -s "dd_data_dictionary.xml.xsd"
      DD_GIT_DESCRIBE=${DD_GIT_DESCRIBE}
    WORKING_DIRECTORY ${data-dictionary_SOURCE_DIR}
    RESULT_VARIABLE _MAKE_DD_EXITCODE
    OUTPUT_VARIABLE _MAKE_DD_OUTPUT
    ERROR_VARIABLE _MAKE_DD_ERROR
  )

  if( _MAKE_DD_EXITCODE )
    message(STATUS "xsltproc.py output: ${_MAKE_DD_OUTPUT}")
    message(STATUS "xsltproc.py error: ${_MAKE_DD_ERROR}")
    message(FATAL_ERROR "Error while building the Data Dictionary (exit code: ${_MAKE_DD_EXITCODE}). Check paths and Saxon-HE configuration.")
  endif()

  # Populate IDSDEF filename
  set( IDSDEF "${data-dictionary_SOURCE_DIR}/IDSDef.xml" )

  # IDSDEF is installed below, once AL_IDS_SUBSET has had a chance to replace it
  set( _INSTALL_IDSDEF TRUE )

  # Populate identifier source xmls
  file( GLOB DD_IDENTIFIER_FILES "${data-dictionary_SOURCE_DIR}/*/*_identifier.xml" "${data-dictionary_SOURCE_DIR}/schemas/*/*_identifier.xml" )
endif()

# Reading facts out of an IDSDef.xml, and pruning one
#
# Written as functions because the build does each of these twice as soon as
# AL_SECOND_DD_IDSDEF is set: once for the version DD_VERSION selects and once for the
# supplied file. The second version's identity has to be derived by exactly the same
# stylesheets and the same sanitizer as the first's, or the two could disagree about
# what a version string means.

# Run one of the small XSLT queries over an IDSDef.xml and return its output as a
# stripped string. WHAT names what is being read, for the error message; any further
# arguments are passed to the stylesheet as parameters.
function( al_query_idsdef OUT_VAR WHAT XSL IDSDEF_PATH )
  set( _tmpfile "${CMAKE_CURRENT_BINARY_DIR}/al_query_idsdef_tmp.txt" )
  file( REMOVE ${_tmpfile} )
  execute_process( COMMAND
    ${_VENV_PYTHON} "${AL_LOCAL_XSLTPROC_SCRIPT}"
      -xsl ${XSL}
      -s ${IDSDEF_PATH}
      -o ${_tmpfile}
      ${ARGN}
    RESULT_VARIABLE _result
    ERROR_VARIABLE _error
  )
  if( _result OR NOT EXISTS ${_tmpfile} )
    message( FATAL_ERROR "Failed to read ${WHAT} from ${IDSDEF_PATH}: ${_error}" )
  endif()
  file( READ ${_tmpfile} _value )
  string( STRIP "${_value}" _value )
  file( REMOVE ${_tmpfile} )
  set( ${OUT_VAR} "${_value}" PARENT_SCOPE )
endfunction()

# The IDSs an IDSDef.xml defines.
function( al_dd_ids_names OUT_VAR IDSDEF_PATH )
  al_query_idsdef( _names "the IDS names"
    ${CMAKE_SOURCE_DIR}/common/list_idss.xsl "${IDSDEF_PATH}" )
  set( ${OUT_VAR} "${_names}" PARENT_SCOPE )
endfunction()

# The Data Dictionary version an IDSDef.xml declares. The file is the only authority on
# this: it is what the generators read, so it is what the generated code will describe.
function( al_dd_version OUT_VAR IDSDEF_PATH )
  al_query_idsdef( _version "the Data Dictionary version"
    ${CMAKE_SOURCE_DIR}/common/dd_version.xsl "${IDSDEF_PATH}" )
  set( ${OUT_VAR} "${_version}" PARENT_SCOPE )
endfunction()

# The Fortran module/type suffix naming a DD version: 4.1.1 -> _v4_1_1,
# 4.1.2.dev22+gbae60dd5f -> _v4_1_2_dev22_gbae60dd5f, 3.39.0 -> _v3_39_0.
#
# DD_SAFE_VERSION (below) is not usable for this: it only replaces + and -, so its dots
# survive and the result is not a legal Fortran identifier. Replace every character that
# cannot appear in one, and lead with 'v' so the suffix cannot start the identifier with
# a digit if it is ever used on its own.
function( al_dd_module_suffix OUT_VAR DD_VERSION_STRING IDSDEF_PATH )
  string( REGEX REPLACE "[^A-Za-z0-9]+" "_" _suffix "${DD_VERSION_STRING}" )
  string( REGEX REPLACE "^_+|_+$" "" _suffix "${_suffix}" )
  if( NOT _suffix )
    message( FATAL_ERROR
      "Could not derive a Fortran identifier suffix from the Data Dictionary version "
      "'${DD_VERSION_STRING}' extracted from ${IDSDEF_PATH}." )
  endif()
  set( ${OUT_VAR} "_v${_suffix}" PARENT_SCOPE )
endfunction()

# Reduce an IDSDef.xml to AL_IDS_SUBSET, writing the result to OUTPUT_PATH.
function( al_filter_idss IDSDEF_PATH OUTPUT_PATH )
  # Pass the list as one comma-separated argument: CMake would split a
  # semicolon-separated string into separate command line arguments.
  string( REPLACE ";" "," _keep "${AL_IDS_SUBSET}" )
  execute_process( COMMAND
    ${_VENV_PYTHON} "${AL_LOCAL_XSLTPROC_SCRIPT}"
      -xsl ${CMAKE_SOURCE_DIR}/common/filter_idss.xsl
      -s ${IDSDEF_PATH}
      -o ${OUTPUT_PATH}
      keep=${_keep}
    RESULT_VARIABLE _result
    ERROR_VARIABLE _error
  )
  if( _result )
    message( FATAL_ERROR
      "Failed to reduce the Data Dictionary ${IDSDEF_PATH} to '${_keep}': ${_error}" )
  endif()
  message( STATUS "Reduced Data Dictionary written to ${OUTPUT_PATH}" )
endfunction()


# Optionally reduce the Data Dictionary to a subset of its IDSs (AL_IDS_SUBSET).
# Done here, on the XML, so that everything downstream follows automatically:
# IDS_NAMES, both generators, the generated test suite and the installed IDSDef.xml
# all read IDSDEF.

if( AL_IDS_SUBSET )
  set( _FULL_IDSDEF "${IDSDEF}" )
  set( IDSDEF "${CMAKE_CURRENT_BINARY_DIR}/IDSDef-subset.xml" )
  al_filter_idss( "${_FULL_IDSDEF}" "${IDSDEF}" )
endif()

if( _INSTALL_IDSDEF )
  # Install IDSDEF (needed for some applications and for UDA backend)
  get_filename_component( REAL_IDSDEF ${IDSDEF} REALPATH )
  install( FILES ${REAL_IDSDEF} DESTINATION include RENAME IDSDef.xml )
endif()

# Find out which IDSs exist and populate IDS_NAMES

set_property( DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/common/list_idss.xsl" "${IDSDEF}" )
al_dd_ids_names( IDS_NAMES "${IDSDEF}" )

# Catch a misspelled AL_IDS_SUBSET here rather than as a confusing missing-module
# error thousands of lines into the Fortran compilation.
if( AL_IDS_SUBSET )
  foreach( _WANTED_IDS IN LISTS AL_IDS_SUBSET )
    if( NOT _WANTED_IDS IN_LIST IDS_NAMES )
      message( FATAL_ERROR
        "AL_IDS_SUBSET requests '${_WANTED_IDS}', which is not an IDS of this "
        "Data Dictionary (${_FULL_IDSDEF})." )
    endif()
  endforeach()
  list( LENGTH IDS_NAMES _N_IDSS )
  message( STATUS "Building ${_N_IDSS} of the Data Dictionary's IDSs: ${IDS_NAMES}" )
  unset( _WANTED_IDS )
  unset( _N_IDSS )
endif()

# DD version
al_dd_version( DD_VERSION "${IDSDEF}" )
string( REGEX REPLACE "[+-]" "_" DD_SAFE_VERSION "${DD_VERSION}" )
al_dd_module_suffix( DD_MODULE_SUFFIX "${DD_VERSION}" "${IDSDEF}" )
message( STATUS "Data Dictionary ${DD_VERSION}: generated names carry the suffix ${DD_MODULE_SUFFIX}" )


# The second Data Dictionary version (AL_SECOND_DD_IDSDEF)
#
# Everything above describes the version this build's bare names mean - the default
# version. This block adds one more, from a file the user supplies, and derives its
# identity from that file alone.
#
# Scalar on purpose: exactly one extra version. Everything downstream keys off
# SECOND_DD_VERSION and SECOND_DD_MODULE_SUFFIX rather than off "the second one", so
# growing to a list later is a contained change.

if( AL_SECOND_DD_IDSDEF )
  # One subset list, one IDS set, both versions. The generated source lists are built
  # from IDS_NAMES for both versions, so pruning only one of the two dictionaries would
  # leave the other generating files nothing compiles - or not generating files
  # something does.
  set( SECOND_IDSDEF "${AL_SECOND_DD_IDSDEF}" )
  if( AL_IDS_SUBSET )
    set( SECOND_IDSDEF "${CMAKE_CURRENT_BINARY_DIR}/IDSDef-second-subset.xml" )
    al_filter_idss( "${AL_SECOND_DD_IDSDEF}" "${SECOND_IDSDEF}" )
  endif()
  # Re-read the supplied dictionary's identity when the file itself changes: replacing it
  # with a different version must not leave SECOND_DD_VERSION and the suffix stale.
  set_property( DIRECTORY APPEND PROPERTY
    CMAKE_CONFIGURE_DEPENDS "${AL_SECOND_DD_IDSDEF}" )

  al_dd_version( SECOND_DD_VERSION "${SECOND_IDSDEF}" )
  if( SECOND_DD_VERSION STREQUAL "${DD_VERSION}" )
    # Both versions would carry the same suffix, so every module of the second would
    # have the same name as one of the first's. Say so here rather than let the Fortran
    # compiler report a duplicate module thousands of lines in.
    message( FATAL_ERROR
      "AL_SECOND_DD_IDSDEF (${AL_SECOND_DD_IDSDEF}) is Data Dictionary version "
      "${SECOND_DD_VERSION}, which is also the version of the Data Dictionary this "
      "build already uses. Supply a different version, or leave AL_SECOND_DD_IDSDEF "
      "empty for a single-version build." )
  endif()
  al_dd_module_suffix( SECOND_DD_MODULE_SUFFIX "${SECOND_DD_VERSION}" "${SECOND_IDSDEF}" )
  if( SECOND_DD_MODULE_SUFFIX STREQUAL "${DD_MODULE_SUFFIX}" )
    # Distinct version strings that sanitize to one Fortran suffix (4.1.1 and 4-1-1, or
    # 4.1.2+g1 and 4.1.2_g1) reach the same duplicate-module error as equal versions do.
    # The suffix is what the module names are built from, so it is what has to differ.
    message( FATAL_ERROR
      "Data Dictionary versions ${DD_VERSION} and ${SECOND_DD_VERSION} "
      "(AL_SECOND_DD_IDSDEF: ${AL_SECOND_DD_IDSDEF}) both name their generated modules "
      "with the suffix ${SECOND_DD_MODULE_SUFFIX}, so every module of one would have the "
      "same name as a module of the other. Supply a version whose Fortran identifier "
      "suffix differs." )
  endif()

  # An IDS the second dictionary does not define would silently generate no source for
  # itself, and the missing modules would surface as a link error at best.
  al_dd_ids_names( SECOND_IDS_NAMES "${SECOND_IDSDEF}" )
  set( _MISSING_IDSS "" )
  foreach( _IDS_NAME IN LISTS IDS_NAMES )
    if( NOT _IDS_NAME IN_LIST SECOND_IDS_NAMES )
      list( APPEND _MISSING_IDSS "${_IDS_NAME}" )
    endif()
  endforeach()
  if( _MISSING_IDSS )
    message( FATAL_ERROR
      "Data Dictionary ${SECOND_DD_VERSION} (${AL_SECOND_DD_IDSDEF}) does not define "
      "these IDSs, which Data Dictionary ${DD_VERSION} does: ${_MISSING_IDSS}. Both "
      "versions build the same set of IDSs, so restrict the build to IDSs both "
      "versions define, e.g. -D AL_IDS_SUBSET=equilibrium." )
  endif()
  unset( _MISSING_IDSS )
  unset( _IDS_NAME )

  message( STATUS
    "Data Dictionary ${SECOND_DD_VERSION} is compiled in alongside ${DD_VERSION}: "
    "its generated names carry the suffix ${SECOND_DD_MODULE_SUFFIX}" )
endif()
