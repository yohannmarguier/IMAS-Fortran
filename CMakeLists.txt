# CMake build configuration for the Access Layer Fortran HLI
cmake_minimum_required( VERSION 3.16 )
if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()

# Local paths for IMAS-Fortran
################################################################################
# Use full path since CMAKE_MODULE_PATH hasn't been configured yet
include(${CMAKE_CURRENT_SOURCE_DIR}/common/cmake/ALLocalPaths.cmake)

# Configuration options for common assets
################################################################################
option( AL_DOWNLOAD_DEPENDENCIES "Automatically download assets from the AL git repository" ON )
option( AL_DEVELOPMENT_LAYOUT "Use development repositories from sibling directory" OFF )
if( AL_DEVELOPMENT_LAYOUT AND AL_DOWNLOAD_DEPENDENCIES )
    message( STATUS "AL_DEVELOPMENT_LAYOUT=ON: setting AL_DOWNLOAD_DEPENDENCIES=OFF" )
    set( AL_DOWNLOAD_DEPENDENCIES OFF CACHE BOOL "Automatically download assets from the AL git
    repository" FORCE )
endif()
set( AL_CORE_GIT_REPOSITORY "https://github.com/iterorganization/IMAS-Core.git" CACHE STRING "Git repository of AL-core" )
set( AL_CORE_VERSION "main" CACHE STRING "Git commit/tag/branch of AL-core" )

# Restrict the build to a subset of the Data Dictionary's IDSs, e.g.
# `-D AL_IDS_SUBSET=equilibrium`. Empty (the default) builds every IDS.
# IDSDef.xml is pruned before any source is generated (see ALBuildDataDictionary),
# which is what makes the build shorter when iterating on the generator itself.
# Declared here rather than in ALCommonConfig because the install prefix below has
# to be chosen before the first project() call - al-core's, via FetchContent.
set( AL_IDS_SUBSET "" CACHE STRING
  "Semicolon-separated list of IDSs to build; empty builds all of them" )

# Compile a second Data Dictionary version into the same library, alongside the one
# DD_VERSION selects. Takes a filesystem path to an already-built IDSDef.xml; empty
# (the default) is today's single-version build, unchanged in every respect.
#
# This one variable is the whole opt-in: the second version's version string, the
# Fortran name suffix its modules and types carry, and the version it stamps into the
# data it writes are all derived from that file (see ALBuildDataDictionary), so the
# generated code cannot disagree with the dictionary it was generated from - which a
# separately supplied version string could.
#
# Building the file takes well under a second in a Data Dictionary checkout:
#   xsltproc.py -xsl dd_data_dictionary.xml.xsl -s dd_data_dictionary.xml.xsd \
#               -o IDSDef.xml DD_GIT_DESCRIBE=<version>
# Doing it for the user needs a second clone of the Data Dictionary and is out of
# scope here (see issue #45).
#
# Declared next to AL_IDS_SUBSET for the same reason: it moves the default install
# prefix, which has to be chosen before the first project() call - al-core's, via
# FetchContent.
set( AL_SECOND_DD_IDSDEF "" CACHE FILEPATH
  "Path to a pre-built IDSDef.xml of a second Data Dictionary version to compile into the same library; empty builds one version" )
if( AL_SECOND_DD_IDSDEF )
  # Resolve to an absolute path, against the source directory, before anything reads it.
  # A relative path would mean two different files: `if( EXISTS )` here is only
  # well-defined for a full path, and the generator commands below run with their output
  # directory as the working directory, so they would resolve it somewhere else again.
  # Written back to the cache so that what a configured build reports is the file it
  # actually read.
  get_filename_component( AL_SECOND_DD_IDSDEF "${AL_SECOND_DD_IDSDEF}" ABSOLUTE
    BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" )
  set( AL_SECOND_DD_IDSDEF "${AL_SECOND_DD_IDSDEF}" CACHE FILEPATH
    "Path to a pre-built IDSDef.xml of a second Data Dictionary version to compile into the same library; empty builds one version"
    FORCE )
  if( NOT EXISTS "${AL_SECOND_DD_IDSDEF}" )
    message( FATAL_ERROR
      "AL_SECOND_DD_IDSDEF is '${AL_SECOND_DD_IDSDEF}', which does not exist. It must "
      "be the path to an already-built IDSDef.xml of the second Data Dictionary version." )
  endif()
endif()

if( NOT DEFINED CACHE{CMAKE_INSTALL_PREFIX} )
  # Two different builds can produce a library the default prefix cannot tell apart:
  # the library is named after the DD version alone, so a subset build looks like a
  # full one and a two-version build looks like a single-version one. Neither may sit
  # in the default prefix, where it would shadow a complete installation - and
  # install() never removes stale module files, so a partial overwrite is worse than
  # a wrong-looking one.
  #
  # Both facts change what ends up installed and neither subsumes the other, so they
  # compose rather than take precedence: `-D AL_IDS_SUBSET=equilibrium
  # -D AL_SECOND_DD_IDSDEF=...` installs to install-equilibrium-two-dd, which is
  # distinct from a single-version subset build's install-equilibrium. That pair is
  # the normal configuration for this feature, not a corner case.
  set( _AL_PREFIX_TAGS "" )
  set( _AL_PREFIX_REASONS "" )
  if( AL_IDS_SUBSET )
    string( REPLACE ";" "-" _AL_SUBSET_TAG "${AL_IDS_SUBSET}" )
    list( APPEND _AL_PREFIX_TAGS "${_AL_SUBSET_TAG}" )
    list( APPEND _AL_PREFIX_REASONS "AL_IDS_SUBSET" )
    unset( _AL_SUBSET_TAG )
  endif()
  if( AL_SECOND_DD_IDSDEF )
    # A fixed tag rather than the second version's number: the version comes out of
    # the XML, which needs a Python venv that does not exist yet at this point.
    list( APPEND _AL_PREFIX_TAGS "two-dd" )
    list( APPEND _AL_PREFIX_REASONS "AL_SECOND_DD_IDSDEF" )
  endif()
  if( _AL_PREFIX_TAGS )
    list( JOIN _AL_PREFIX_TAGS "-" _AL_PREFIX_SUFFIX )
    list( JOIN _AL_PREFIX_REASONS " and " _AL_PREFIX_REASONS )
    set( CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/install-${_AL_PREFIX_SUFFIX}"
      CACHE PATH "Install path prefix" )
    message( STATUS
      "${_AL_PREFIX_REASONS} is set: default install prefix is ${CMAKE_INSTALL_PREFIX}" )
    unset( _AL_PREFIX_SUFFIX )
  endif()
  unset( _AL_PREFIX_TAGS )
  unset( _AL_PREFIX_REASONS )
endif()

include(FetchContent)

# Load dependency
################################################################################
if( ${AL_DOWNLOAD_DEPENDENCIES} )
  # Download common assets from the ITER git:
  FetchContent_Declare(
    al-core
    GIT_REPOSITORY "${AL_CORE_GIT_REPOSITORY}"
    GIT_TAG "${AL_CORE_VERSION}"
  )
  FetchContent_MakeAvailable( al-core )
elseif ( ${AL_DEVELOPMENT_LAYOUT} )
  FetchContent_Declare(
    al-core
    SOURCE_DIR      "${CMAKE_CURRENT_SOURCE_DIR}/../IMAS-Core"
  )
  FetchContent_MakeAvailable( al-core )
endif()


# Define project
################################################################################

# Set VERSION and FULL_VERSION from `git describe`:
set( GIT_ARCHIVE_DESCRIBE [[$Format:%(describe)$]] )
include( ALDetermineVersion )
project( al-fortran
  VERSION ${VERSION}
  DESCRIPTION "Fortran High Level Interface of the IMAS Access Layer"
  HOMEPAGE_URL "https://imas.iter.org/"
  LANGUAGES C CXX Fortran
)
if( NOT PROJECT_VERSION_TWEAK EQUAL 0 )
  message( "Building a development version of the Access Layer Fortran HLI" )
endif()

# Compiler settings
include( ALSetCompilerFlags )
# Common HLI options
include( ALCommonConfig )
# Data dictionary
include( ALBuildDataDictionary )
# AL core, plugins and documentation
include( ALCore )

# Stop processing when only building documentation
if( AL_DOCS_ONLY )
  return()
endif()


# Generate sources
################################################################################

# Names of routines that generate separate source files
set( ROUTINES
  copy_struct
  deallocate_struct
  delete
  get
  get_slice
  put
  put_slice
  validate
)

# Generate one Data Dictionary version's Fortran sources into its own directory.
#
# Called once per version - twice when AL_SECOND_DD_IDSDEF is set - with everything that
# differs between the two runs passed in: the dictionary to read, the version stamped
# into the data the generated code writes, the suffix its module and type names carry,
# and whether this is the default version, which is what decides who emits the shared
# ids_types module, the alias layer and the front door's procedures (see utils.xsl).
#
# Each version needs its own directory because the emitted file names carry no suffix:
# equilibrium_put.f90 is equilibrium_put.f90 in either version. That also makes the two
# versions' output easy to diff.
#
# Sets <SOURCES_VAR> to the sources it will generate and declares <TARGET> as the target
# that generates them. Every file it lists is a file the generator writes - that is what
# the list is for. The converse holds only as far as IDS_NAMES: a dictionary defining IDSs
# the primary does not would also write sources for those, and they would sit in SRC_DIR
# uncompiled. AL_IDS_SUBSET, which applies to both versions, is what keeps the two sets
# equal in practice.
#
# Note: saxonche is provided by dd_build_env (set up in ALBuildDataDictionary)
# _VENV_PYTHON points to that environment and is used for all XSLT transformations
function( al_generate_dd_version SRC_DIR )
  cmake_parse_arguments( PARSE_ARGV 1 GEN
    "" "IDSDEF;VERSION;SUFFIX;IS_DEFAULT;TARGET;SOURCES_VAR" "" )
  file( MAKE_DIRECTORY ${SRC_DIR} )

  set( _sources
    "${SRC_DIR}/ids_routines.f90"
    "${SRC_DIR}/ids_schemas.f90"
    "${SRC_DIR}/ids_utilities.f90"
    "${SRC_DIR}/utilities_copy_struct.f90"
    "${SRC_DIR}/utilities_deallocate_struct.f90"
    "${SRC_DIR}/utilities_get_struct.f90"
    "${SRC_DIR}/utilities_put_slice_struct.f90"
    "${SRC_DIR}/utilities_put_struct.f90"
    "${SRC_DIR}/utilities_validate_struct.f90"
  )
  # ids_types holds the kinds, the invalid markers and the abstract IDS base type: one
  # module for the whole library, DD-version-independent, so only the default version's
  # run emits it. Both versions' IDS types extend that one base type, which is what lets
  # shared polymorphic code accept either.
  if( GEN_IS_DEFAULT STREQUAL "yes" )
    list( APPEND _sources "${SRC_DIR}/ids_types.f90" )
  endif()
  foreach( IDS_NAME IN LISTS IDS_NAMES )
    foreach( ROUTINE IN LISTS ROUTINES )
      list( APPEND _sources "${SRC_DIR}/${IDS_NAME}_${ROUTINE}.f90" )
    endforeach()
    list( APPEND _sources "${SRC_DIR}/${IDS_NAME}_schema.f90" )
  endforeach()

  # The alias layer: bare, unsuffixed spellings of everything the suffixed sources above
  # declare, so that code written against a single-version build compiles unchanged. Both
  # generators emit it only when SUFFIX is non-empty and this is the default version -
  # with an empty suffix the sources above are already bare and an alias module would be
  # a duplicate, and the bare names can only mean one version - so this list is
  # conditional on exactly the same thing, and no file appears here that is not written.
  if( GEN_SUFFIX AND GEN_IS_DEFAULT STREQUAL "yes" )
    list( APPEND _sources
      "${SRC_DIR}/alias_ids_utilities.f90"
      "${SRC_DIR}/alias_ids_schemas.f90"
      "${SRC_DIR}/alias_ids_routines.f90"
      "${SRC_DIR}/alias_utilities_struct.f90"
    )
    foreach( IDS_NAME IN LISTS IDS_NAMES )
      list( APPEND _sources
        "${SRC_DIR}/alias_${IDS_NAME}_schema.f90"
        "${SRC_DIR}/alias_${IDS_NAME}_routines.f90"
      )
    endforeach()
  endif()

  add_custom_command(
    # Use a dummy output file: when listing all actual output files (which are
    # source files of target `al-fortran`), they would be re-created with every build.
    OUTPUT ${SRC_DIR}/dummy.txt
    # Generate routine files with IDSDef2F90Routines.xsl
    COMMAND
      ${_VENV_PYTHON} "${AL_LOCAL_XSLTPROC_SCRIPT}"
        -xsl ${CMAKE_CURRENT_SOURCE_DIR}/IDSDef2F90Routines.xsl
        -s ${GEN_IDSDEF}
        -o ${SRC_DIR}/routines_output.xml
        DD_GIT_DESCRIBE=${GEN_VERSION}
        AL_GIT_DESCRIBE=${FULL_VERSION}
        SUFFIX=${GEN_SUFFIX}
        IS_DEFAULT_VERSION=${GEN_IS_DEFAULT}
    # Generate schema files with IDSDef2F90TypeDef.xsl
    COMMAND
      ${_VENV_PYTHON} "${AL_LOCAL_XSLTPROC_SCRIPT}"
        -xsl ${CMAKE_CURRENT_SOURCE_DIR}/IDSDef2F90TypeDef.xsl
        -s ${GEN_IDSDEF}
        -o ${SRC_DIR}/schemas_output.xml
        DD_GIT_DESCRIBE=${GEN_VERSION}
        AL_GIT_DESCRIBE=${FULL_VERSION}
        SUFFIX=${GEN_SUFFIX}
        IS_DEFAULT_VERSION=${GEN_IS_DEFAULT}
    # Create/update our dummy file
    COMMAND ${CMAKE_COMMAND} -E touch ${SRC_DIR}/dummy.txt
    # utils.xsl is included by both generators (it declares SUFFIX and the shared
    # naming functions), so editing it must re-run them too.
    DEPENDS IDSDef2F90Routines.xsl IDSDef2F90TypeDef.xsl utils.xsl ${GEN_IDSDEF}
    # The routines generator reads back the utilities_validate_struct.f90 it has just
    # written, by a path relative to the working directory, so each version must run in
    # its own output directory to read its own.
    WORKING_DIRECTORY ${SRC_DIR}
  )
  add_custom_target( ${GEN_TARGET}
    COMMAND ${CMAKE_COMMAND} -E echo ""
    DEPENDS ${SRC_DIR}/dummy.txt
    # Actually these are results of the custom_command above, but with this trick
    # we don't rebuild it always (only when IDSDef.xml or the xslts have changed)
    BYPRODUCTS ${_sources}
  )

  set( ${GEN_SOURCES_VAR} ${_sources} PARENT_SCOPE )
endfunction()

set( GENERATED_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/src" )
al_generate_dd_version( ${GENERATED_SRC_DIR}
  IDSDEF ${IDSDEF}
  VERSION ${DD_VERSION}
  SUFFIX ${DD_MODULE_SUFFIX}
  IS_DEFAULT yes
  TARGET al-fortran-sources
  SOURCES_VAR GENERATED_SOURCES
)

set( SOURCES ${GENERATED_SOURCES} )
list( APPEND SOURCES
  wrapper/al_defs.f90
  wrapper/al_low_level_wrap.f90
)

# The targets that generate Fortran sources for al-fortran - one per DD version.
set( AL_SOURCE_TARGETS al-fortran-sources )

# The second Data Dictionary version, when one is configured. Its sources join the same
# library target: the dependency graph runs shared -> both versions -> shared (both
# versions' modules use ids_types and the wrapper layer, and the default version's front
# door reaches its own modules), so splitting the versions into separate targets would
# need the shared code split into further targets to break a cycle. CMake's Fortran
# module scanner orders the compilation across the two source directories unaided.
if( AL_SECOND_DD_IDSDEF )
  set( SECOND_GENERATED_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/src${SECOND_DD_MODULE_SUFFIX}" )
  al_generate_dd_version( ${SECOND_GENERATED_SRC_DIR}
    IDSDEF ${SECOND_IDSDEF}
    VERSION ${SECOND_DD_VERSION}
    SUFFIX ${SECOND_DD_MODULE_SUFFIX}
    IS_DEFAULT no
    TARGET al-fortran-sources${SECOND_DD_MODULE_SUFFIX}
    SOURCES_VAR SECOND_GENERATED_SOURCES
  )
  list( APPEND SOURCES ${SECOND_GENERATED_SOURCES} )
  list( APPEND AL_SOURCE_TARGETS al-fortran-sources${SECOND_DD_MODULE_SUFFIX} )
endif()


# Generate sources (identifiers)
################################################################################

# Note: identifiers.xsl tries to import identifiers.common.xsl
# Unfortunately, xsl:include doesn't support parameters, so we need to put them together
# in the build folder:
file( CREATE_LINK
  "${CMAKE_CURRENT_SOURCE_DIR}/common/identifiers.common.xsl" 
  "${CMAKE_CURRENT_BINARY_DIR}/identifiers.common.xsl"
  SYMBOLIC COPY_ON_ERROR
)
file( CREATE_LINK
  "${CMAKE_CURRENT_SOURCE_DIR}/identifiers.xsl" 
  "${CMAKE_CURRENT_BINARY_DIR}/identifiers.xsl"
  SYMBOLIC COPY_ON_ERROR
)
set( IDENTIFIER_SRC_DIR ${CMAKE_CURRENT_BINARY_DIR}/identifiers/src/ )
file( MAKE_DIRECTORY ${IDENTIFIER_SRC_DIR} )

set( IDENTIFIER_SOURCES )
foreach( ID_FILE IN LISTS DD_IDENTIFIER_FILES )
  # cmake_path( GET ID_FILE STEM ID_NAME)
  string( REGEX REPLACE "(^.*[/\\]|[.]xml$)" "" ID_NAME ${ID_FILE} )
  set( SOURCE_NAME "${IDENTIFIER_SRC_DIR}/${ID_NAME}.f90" )
  add_custom_command(
    OUTPUT ${SOURCE_NAME}
    COMMAND ${_VENV_PYTHON} "${AL_LOCAL_XSLTPROC_SCRIPT}"
      -xsl ${CMAKE_CURRENT_BINARY_DIR}/identifiers.xsl
      -s ${ID_FILE}
      -o ${CMAKE_CURRENT_BINARY_DIR}/${ID_NAME}_identifier_output.xml
      name=${ID_NAME}
      prefix=${IDENTIFIER_SRC_DIR}
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/identifiers.xsl
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )
  list( APPEND IDENTIFIER_SOURCES ${SOURCE_NAME} )
endforeach()


# Targets
################################################################################

add_library( al-fortran ${SOURCES} )
add_dependencies( al-fortran ${AL_SOURCE_TARGETS} )

if( CMAKE_Fortran_COMPILER_ID STREQUAL "NAG" )
  # Work around NAG compiler not wanting to link against libal.so.x.y.z
  add_dependencies( al-fortran al )
  get_target_property( AL_BINARY_DIR al BINARY_DIR )
  target_link_options( al-fortran PRIVATE -lal -L${AL_BINARY_DIR} "-Wl,-Xlinker,-rpath,-Xlinker,${AL_BINARY_DIR}" )
else()
  target_link_libraries( al-fortran al )
endif()
# Set target output library name to include the DD version
set_target_properties( al-fortran PROPERTIES LIBRARY_OUTPUT_NAME "al-fortran-${DD_VERSION}" )

target_include_directories( al-fortran PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/wrapper>
  $<BUILD_INTERFACE:${GENERATED_SRC_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
  $<INSTALL_INTERFACE:include/fortran>  # <prefix>/include/fortran
)

add_library( al-identifiers-fortran ${IDENTIFIER_SOURCES} )
add_dependencies( al-identifiers-fortran al-fortran )
target_include_directories( al-identifiers-fortran PUBLIC
  $<BUILD_INTERFACE:${IDENTIFIER_SRC_DIR}>
  $<BUILD_INTERFACE:${GENERATED_SRC_DIR}>
  $<INSTALL_INTERFACE:include/fortran>  # <prefix>/include/fortran
)


# Install
################################################################################

install( TARGETS al-fortran al-identifiers-fortran )
# Install module files
install( DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include/ DESTINATION include/fortran )

# Generate and install .pc files
configure_file( pkgconfig/al-fortran.pc.in al-fortran.pc @ONLY )
configure_file( pkgconfig/al-fortran-DD_VERSION.pc.in al-fortran-${DD_VERSION}.pc @ONLY )
configure_file( pkgconfig/al-identifiers-fortran.pc.in al-identifiers-fortran.pc @ONLY )
install( FILES
    ${CMAKE_CURRENT_BINARY_DIR}/al-fortran.pc
    ${CMAKE_CURRENT_BINARY_DIR}/al-fortran-${DD_VERSION}.pc
    ${CMAKE_CURRENT_BINARY_DIR}/al-identifiers-fortran.pc
  DESTINATION lib/pkgconfig
)
# Create backward-compatibility symlinks for imas-* pkgconfig files
install( CODE
  "execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink
      al-fortran.pc imas-fortran.pc
    WORKING_DIRECTORY \${CMAKE_INSTALL_PREFIX}/lib/pkgconfig
  )
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink
      al-fortran-${DD_VERSION}.pc imas-fortran-${DD_VERSION}.pc
    WORKING_DIRECTORY \${CMAKE_INSTALL_PREFIX}/lib/pkgconfig
  )
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink
      al-identifiers-fortran.pc imas-identifiers-fortran.pc
    WORKING_DIRECTORY \${CMAKE_INSTALL_PREFIX}/lib/pkgconfig
  )
"
)


# Tests
################################################################################

if( AL_TESTS )
  add_subdirectory( tests/generator )
  if( DD_MODULE_SUFFIX )
    # Needs both spellings of a name to exist, so it only makes sense once the generated
    # names carry a version suffix and the alias layer has restored the bare ones.
    add_subdirectory( tests/alias )
  endif()
  if( AL_SECOND_DD_IDSDEF )
    # Reads and writes both Data Dictionary versions through the public front doors, so
    # there has to be a second version to read and write.
    add_subdirectory( tests/two_dd )
  endif()
endif()

if( AL_EXAMPLES )
  add_subdirectory( examples )
endif()
