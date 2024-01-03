# CMake build configuration for the Access Layer Fortran HLI
cmake_minimum_required( VERSION 3.16 )

# Configuration options for common assets
################################################################################
option( AL_DOWNLOAD_DEPENDENCIES "Automatically download common assets from the AL git repository" OFF )
# option( AL_COMMON_GIT_REPOSITORY "Git repository of AL-common" "ssh://git@git.iter.org/imas/al-common.git")

include(FetchContent)

# Load common assets
################################################################################
if( ${AL_DOWNLOAD_DEPENDENCIES} )
  # Download common assets from the ITER git:
  message( FATAL_ERROR "Not implemented yet" )
else()
  # Look in ../al-common for common files
  FetchContent_Declare(
    al-common
    SOURCE_DIR      ${CMAKE_CURRENT_SOURCE_DIR}/../al-common
  )
endif()
FetchContent_MakeAvailable( al-common )


# Define project
################################################################################

# Set VERSION and FULL_VERSION from `git describe`:
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
# AL lowlevel and plugins
include( ALLowlevel )


# Generate sources
################################################################################

set( GENERATED_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/src" )
file( MAKE_DIRECTORY ${GENERATED_SRC_DIR} )

# Generated source files
set( GENERATED_SOURCES
  "${GENERATED_SRC_DIR}/ids_routines.f90"
  "${GENERATED_SRC_DIR}/ids_schemas.f90"
  "${GENERATED_SRC_DIR}/ids_types.f90"
  "${GENERATED_SRC_DIR}/ids_utilities.f90"
  "${GENERATED_SRC_DIR}/utilities_copy_struct.f90"
  "${GENERATED_SRC_DIR}/utilities_deallocate_struct.f90"
  "${GENERATED_SRC_DIR}/utilities_get_struct.f90"
  "${GENERATED_SRC_DIR}/utilities_put_slice_struct.f90"
  "${GENERATED_SRC_DIR}/utilities_put_struct.f90"
  "${GENERATED_SRC_DIR}/utilities_validate_struct.f90"
)
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
foreach( IDS_NAME IN LISTS IDS_NAMES )
  foreach( ROUTINE IN LISTS ROUTINES )
      list( APPEND GENERATED_SOURCES "${GENERATED_SRC_DIR}/${IDS_NAME}_${ROUTINE}.f90" )
  endforeach()
  list( APPEND GENERATED_SOURCES "${GENERATED_SRC_DIR}/${IDS_NAME}_schema.f90" )
endforeach()

find_package( SaxonHE )
add_custom_command(
  # Use a dummy output file: when listing all actual output files (which are
  # source files of target `al-fortran`), they would be re-created with every build.
  OUTPUT ${GENERATED_SRC_DIR}/dummy.txt
  # Generate routine files with IDSDef2F90Routines.xsl
  COMMAND 
    java -cp ${SaxonHE_CLASSPATH}
      net.sf.saxon.Transform -t -warnings:fatal
      "-xsl:${CMAKE_CURRENT_SOURCE_DIR}/IDSDef2F90Routines.xsl"
      "-s:${IDSDEF}"
      DD_GIT_DESCRIBE=${DD_VERSION}
      AL_GIT_DESCRIBE=${FULL_VERSION}
  # Generate schema files with IDSDef2F90TypeDef.xsl
  COMMAND 
    java -cp ${SaxonHE_CLASSPATH}
      net.sf.saxon.Transform -t -warnings:fatal
      "-xsl:${CMAKE_CURRENT_SOURCE_DIR}/IDSDef2F90TypeDef.xsl"
      "-s:${IDSDEF}"
      DD_GIT_DESCRIBE=${DD_VERSION}
      AL_GIT_DESCRIBE=${FULL_VERSION}
  # Create/update our dummy file
  COMMAND ${CMAKE_COMMAND} -E touch ${GENERATED_SRC_DIR}/dummy.txt
  DEPENDS IDSDef2F90Routines.xsl IDSDef2F90TypeDef.xsl ${IDSDEF}
  WORKING_DIRECTORY ${GENERATED_SRC_DIR}
)
add_custom_target( al-fortran-sources
  COMMAND ${CMAKE_COMMAND} -E echo ""
  DEPENDS ${GENERATED_SRC_DIR}/dummy.txt
  # Actually these are results of the custom_command above, but with this trick
  # we don't rebuild it always (only when IDSDef.xml or the xslts have changed)
  BYPRODUCTS ${GENERATED_SOURCES}
)

set( SOURCES ${GENERATED_SOURCES} )
list( APPEND SOURCES 
  wrapper/al_defs.f90
  wrapper/al_low_level_wrap.f90
)


# Generate sources (identifiers)
################################################################################

set( IDENTIFIER_SRC_DIR ${CMAKE_CURRENT_BINARY_DIR}/identifiers/src/ )
file( GLOB ID_FILES ${data-dictionary_SOURCE_DIR}/*/*_identifier.xml )

set( IDENTIFIER_SOURCES )
foreach( ID_FILE IN LISTS ID_FILES )
  # cmake_path( GET ID_FILE STEM ID_NAME)
  string( REGEX REPLACE "(^.*[/\\]|[.]xml$)" "" ID_NAME ${ID_FILE} )
  set( SOURCE_NAME "${IDENTIFIER_SRC_DIR}/${ID_NAME}.f90" )
  add_custom_command(
    OUTPUT ${SOURCE_NAME}
    COMMAND ${LIBXSLT_XSLTPROC_EXECUTABLE}
      --stringparam name ${ID_NAME}
      --stringparam prefix ${IDENTIFIER_SRC_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/identifiers.xsl
      ${ID_FILE}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/identifiers.xsl
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )
  list( APPEND IDENTIFIER_SOURCES ${SOURCE_NAME} )
endforeach()


# Targets
################################################################################

add_library( al-fortran ${SOURCES} )
add_dependencies( al-fortran al-fortran-sources )
target_link_libraries( al-fortran al )
# Set target output library name to include the DD version
set_target_properties( al-fortran PROPERTIES LIBRARY_OUTPUT_NAME "al-fortran-${DD_VERSION}" )

target_include_directories( al-fortran PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/wrapper>
  $<BUILD_INTERFACE:${GENERATED_SRC_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
  $<INSTALL_INTERFACE:include/fortran>  # <prefix>/include/fortran
)

add_library( al-identifiers-fortran ${IDENTIFIER_SOURCES} )
target_include_directories( al-identifiers-fortran PUBLIC
  $<BUILD_INTERFACE:${IDENTIFIER_SRC_DIR}>
  $<INSTALL_INTERFACE:include/fortran>  # <prefix>/include/fortran
)


# Install
################################################################################

install( TARGETS al-fortran al-identifiers-fortran )
# Install module files
install( DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include/ DESTINATION include/fortran )

# Generate and install .pc files
configure_file( al-fortran.pc.in al-fortran.pc @ONLY )
configure_file( al-fortran-DD_VERSION.pc.in al-fortran-${DD_VERSION}.pc @ONLY )
configure_file( al-identifiers-fortran.pc.in al-identifiers-fortran.pc @ONLY )
install( FILES
    ${CMAKE_CURRENT_BINARY_DIR}/al-fortran.pc
    ${CMAKE_CURRENT_BINARY_DIR}/al-fortran-${DD_VERSION}.pc
    ${CMAKE_CURRENT_BINARY_DIR}/al-identifiers-fortran.pc
  DESTINATION lib/pkgconfig
)


# Tests
################################################################################

if( AL_TESTS )
  add_subdirectory( tests/generator )
endif()
