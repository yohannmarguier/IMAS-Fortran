# AL core and plugins
#
# This module answers one question — what does the target name `al` refer to — and
# answers it differently per acquisition mode. Everything downstream links `al`
# and does not care which mode produced it.
#
# Note that retargeting `al` has no effect on a NAG build: that branch in the
# top-level CMakeLists.txt does not link the target. The full warning is at the
# branch itself; see also docs/adr/0001-multiversion-shim-linkage.md.

if( AL_USE_MULTIVERSION_SHIM )
  # Multiversion shim: `al` refers to the IMAS-Multiversion-DD-Loader instead of to
  # AL core. The shim mirrors AL core's public C ABI symbol for symbol, so the
  # wrapper's `iso_c_binding` interfaces bind to it unchanged, and it resolves AL
  # core itself at run time through dlopen/dlsym — hence no AL core acquisition
  # here, at any point in this module.
  #
  # Point CMAKE_PREFIX_PATH (or imas-mvdd-loader_DIR) at the shim's install prefix.
  find_package( imas-mvdd-loader REQUIRED CONFIG )
  # An INTERFACE library rather than `add_library( al ALIAS <imported target> )`:
  # aliasing a non-GLOBAL imported target, which is what a config package creates,
  # needs CMake 3.18 and this project declares 3.16.
  add_library( al INTERFACE )
  target_link_libraries( al INTERFACE imas-mvdd-loader::imas-mvdd-loader )
  # File name of the shim's library, without prefix or suffix — what a dependency
  # listing of the built HLI spells. tests/shim asserts on it.
  set( AL_SHIM_LIBRARY_NAME imas_mvdd_loader )
  message( STATUS
    "AL core calls are routed through the multiversion shim "
    "(imas-mvdd-loader ${imas-mvdd-loader_VERSION}, ${imas-mvdd-loader_DIR})"
  )

  # AL core's own cache options are not declared in this mode, since AL core is not
  # part of the build. That includes AL_BACKEND_HDF5 and friends, which
  # tests/generator reads to build its backend matrix: pass them explicitly to keep
  # the generated test matrix the same as a direct build's. MDSplus is the one that
  # cannot work that way, because its model is a target AL core builds.
  if( AL_BACKEND_MDSPLUS )
    message( FATAL_ERROR
      "AL_BACKEND_MDSPLUS is not supported with AL_USE_MULTIVERSION_SHIM: the tests "
      "and examples need the al-mdsplus-model target, which AL core builds and a "
      "shim build does not add."
    )
  endif()

  # AL_CORE_VERSION is deliberately left at whatever the user configured: the shim
  # does not record which AL core it will open, and the generated
  # al-fortran-<DD>.pc keeps naming al-core in `Requires:` because that is still
  # where the run-time dependency is.

  # Stop processing: the plugin framework and the documentation build below both
  # come with AL core, the same way they are skipped in the pkg-config mode.
  return()
endif()

if( NOT AL_DOWNLOAD_DEPENDENCIES AND NOT AL_DEVELOPMENT_LAYOUT )
  # The Access Layer core should be available as a module, use PkgConfig to create a
  # target:
  find_package( PkgConfig )
  pkg_check_modules( al REQUIRED IMPORTED_TARGET al-core )
  add_library( al ALIAS PkgConfig::al )
  set( AL_CORE_VERSION ${al_VERSION} )

  # Stop processing
  return()
endif()
if(WIN32)
  if( AL_DOWNLOAD_DEPENDENCIES )
    # Download the AL core from the ITER git using direct git commands:
    set( al-core_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/al-core-src" )
    if( NOT EXISTS "${al-core_SOURCE_DIR}/.git" )
      message( STATUS "Cloning al-core from ${AL_CORE_GIT_REPOSITORY}" )
      execute_process(
        COMMAND git clone "${AL_CORE_GIT_REPOSITORY}" "${al-core_SOURCE_DIR}"
        RESULT_VARIABLE _GIT_CLONE_RESULT
        ERROR_VARIABLE _GIT_CLONE_ERROR
      )
      if( _GIT_CLONE_RESULT )
        message( FATAL_ERROR "Failed to clone al-core: ${_GIT_CLONE_ERROR}" )
      endif()
    endif()
    # Checkout the specified version
    execute_process(
      COMMAND git fetch origin
      WORKING_DIRECTORY "${al-core_SOURCE_DIR}"
      RESULT_VARIABLE _GIT_FETCH_RESULT
    )
    execute_process(
      COMMAND git checkout "${AL_CORE_VERSION}"
      WORKING_DIRECTORY "${al-core_SOURCE_DIR}"
      RESULT_VARIABLE _GIT_CHECKOUT_RESULT
      ERROR_VARIABLE _GIT_CHECKOUT_ERROR
    )
    if( _GIT_CHECKOUT_RESULT )
      message( FATAL_ERROR "Failed to checkout ${AL_CORE_VERSION}: ${_GIT_CHECKOUT_ERROR}" )
    endif()
  else()
    # Look in ../IMAS-Core
    set( al-core_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../IMAS-Core )
    if( NOT IS_DIRECTORY ${al-core_SOURCE_DIR} )
      message( FATAL_ERROR
        "${al-core_SOURCE_DIR} does not exist. Please clone the "
        "IMAS-Core repository or set AL_DOWNLOAD_DEPENDENCIES=ON."
      )
    endif()
  endif()
else()
  include(FetchContent)

  if( AL_DOWNLOAD_DEPENDENCIES )
    # Download the AL core from the ITER git:
    FetchContent_Declare(
      al-core
      GIT_REPOSITORY  ${AL_CORE_GIT_REPOSITORY}
      GIT_TAG         ${AL_CORE_VERSION}
    )
  else()
    # Look in ../IMAS-Core
    set( AL_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../IMAS-Core )
    if( NOT IS_DIRECTORY ${AL_SOURCE_DIRECTORY} )
      message( FATAL_ERROR
        "${AL_SOURCE_DIRECTORY} does not exist. Please clone the "
        "IMAS-Core repository or set AL_DOWNLOAD_DEPENDENCIES=ON."
      )
    endif()

    FetchContent_Declare(
      al-core
      SOURCE_DIR      ${AL_SOURCE_DIRECTORY}
    )
    set( AL_SOURCE_DIRECTORY )  # unset temporary var
  endif()
endif()

# Don't load the AL core when only building documentation
if( NOT AL_DOCS_ONLY )
  # Ensure vcpkg packages are found in the subdirectory
  if(WIN32)
    # On Windows, ensure vcpkg packages are available to the subdirectory
    if(DEFINED VCPKG_INSTALLED_DIR AND DEFINED VCPKG_TARGET_TRIPLET)
      # Add vcpkg installed directory to CMAKE_PREFIX_PATH for the subdirectory
      set(CMAKE_PREFIX_PATH "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET};${CMAKE_PREFIX_PATH}")
      # Pass vcpkg variables to subdirectory by setting them in parent scope
      set(VCPKG_INSTALLED_DIR "${VCPKG_INSTALLED_DIR}" CACHE STRING "vcpkg installed dir" FORCE)
      set(VCPKG_TARGET_TRIPLET "${VCPKG_TARGET_TRIPLET}" CACHE STRING "vcpkg triplet" FORCE)
      message(STATUS "ALCore: Passing vcpkg paths to al-core subdirectory")
      message(STATUS "  VCPKG_INSTALLED_DIR: ${VCPKG_INSTALLED_DIR}")
      message(STATUS "  VCPKG_TARGET_TRIPLET: ${VCPKG_TARGET_TRIPLET}")
      message(STATUS "  CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")
    endif()
    add_subdirectory( ${al-core_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/_deps/al-core-build )
  else()
    FetchContent_MakeAvailable( al-core )
  endif()
  get_target_property( AL_CORE_VERSION al VERSION )
endif()


if( ${AL_PLUGINS} )
  if(WIN32)
    if( ${AL_DOWNLOAD_DEPENDENCIES} )
      # Download the AL plugins from the ITER git using direct git commands:
      set( al-plugins_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/al-plugins-src" )
      if( NOT EXISTS "${al-plugins_SOURCE_DIR}/.git" )
        message( STATUS "Cloning al-plugins from ${AL_PLUGINS_GIT_REPOSITORY}" )
        execute_process(
          COMMAND git clone "${AL_PLUGINS_GIT_REPOSITORY}" "${al-plugins_SOURCE_DIR}"
          RESULT_VARIABLE _GIT_CLONE_RESULT
          ERROR_VARIABLE _GIT_CLONE_ERROR
        )
        if( _GIT_CLONE_RESULT )
          message( FATAL_ERROR "Failed to clone al-plugins: ${_GIT_CLONE_ERROR}" )
        endif()
      endif()
      # Checkout the specified version
      execute_process(
        COMMAND git fetch origin
        WORKING_DIRECTORY "${al-plugins_SOURCE_DIR}"
        RESULT_VARIABLE _GIT_FETCH_RESULT
      )
      execute_process(
        COMMAND git checkout "${AL_PLUGINS_VERSION}"
        WORKING_DIRECTORY "${al-plugins_SOURCE_DIR}"
        RESULT_VARIABLE _GIT_CHECKOUT_RESULT
        ERROR_VARIABLE _GIT_CHECKOUT_ERROR
      )
      if( _GIT_CHECKOUT_RESULT )
        message( FATAL_ERROR "Failed to checkout ${AL_PLUGINS_VERSION}: ${_GIT_CHECKOUT_ERROR}" )
      endif()
    else()
      # Look in ../IMAS-Core-Plugins
      set( al-plugins_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../IMAS-Core-Plugins )
      if( NOT IS_DIRECTORY ${al-plugins_SOURCE_DIR} )
        message( FATAL_ERROR
          "${al-plugins_SOURCE_DIR} does not exist. Please clone the "
          "IMAS-Core-Plugins repository or set AL_DOWNLOAD_DEPENDENCIES=ON."
        )
      endif()
    endif()

  else()
    if( ${AL_DOWNLOAD_DEPENDENCIES} )
      # Download the AL plugins from the ITER git:
      FetchContent_Declare(
        al-plugins
        GIT_REPOSITORY  ${AL_PLUGINS_GIT_REPOSITORY}
        GIT_TAG         ${AL_PLUGINS_VERSION}
      )
    else()
      # Look in ../plugins
      set( PLUGINS_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../IMAS-Core-Plugins )
      if( NOT IS_DIRECTORY ${PLUGINS_SOURCE_DIRECTORY} )
        message( FATAL_ERROR
          "${PLUGINS_SOURCE_DIRECTORY} does not exist. Please clone the "
          "IMAS-Core-Plugins repository or set AL_DOWNLOAD_DEPENDENCIES=ON."
        )
      endif()

      FetchContent_Declare(
        al-plugins
        SOURCE_DIR      ${PLUGINS_SOURCE_DIRECTORY}
      )
      set( PLUGINS_SOURCE_DIRECTORY )  # unset temporary var
    endif()
    FetchContent_MakeAvailable( al-plugins )
  endif()
endif()

if( AL_HLI_DOCS )
  include( ALBuildDocumentation )
endif()

