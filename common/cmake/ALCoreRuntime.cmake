# Run-time AL core for a multiversion shim build
#
# The shim mirrors AL core's public C ABI symbol for symbol but implements none of
# it: it opens AL core with the operating system's dynamic loader and forwards
# every call (the shim's docs/adr/0001-runtime-binding-not-linking.md). It carries
# no storage backend either — HDF5, MDSplus, ASCII, Memory and Flexbuffers are all
# AL core code. So a shim build links no AL core and still needs one present at
# run time.
#
# Until this module existed it had none, and the symptom named nothing that would
# lead you here: with no library to open, the shim falls back to the bare soname
# (`libal.so`, `libal.dylib`), the dynamic loader does not find it, every al_*
# call fails, and the generated suite's FAIL_REGULAR_EXPRESSION matches the
# resulting dlopen message. Every test failed, none of them for its own reason.
#
# ExternalProject rather than FetchContent, which is the whole reason this is a
# module of its own. FetchContent would add AL core as a subproject, and AL core's
# own library target is named `al` — the name ALCore.cmake has just given the
# shim. That collision is why the top-level CMakeLists.txt skips AL core
# acquisition in this mode at all. A separate CMake project cannot collide, and it
# states the relationship correctly: this AL core is never on a link line, only
# opened at run time.
#
# Two consequences of it being external, both visible below: its cache options are
# not this build's, so the backend selection is forwarded by hand; and the library
# is named by path, since there is no target to ask with $<TARGET_FILE:al>.

# Empty means "build one below". A path means an operator's own AL core — the
# module or system-package case, where a shim build should open the AL core the
# site already ships rather than compile a second copy of it.
set( AL_CORE_RUNTIME_LIBRARY "" CACHE FILEPATH
  "AL core shared library the multiversion shim opens at run time. Empty builds one."
)

if( AL_CORE_RUNTIME_LIBRARY )
  if( NOT EXISTS "${AL_CORE_RUNTIME_LIBRARY}" )
    message( FATAL_ERROR
      "AL_CORE_RUNTIME_LIBRARY is set to '${AL_CORE_RUNTIME_LIBRARY}', which does not "
      "exist. It must name the AL core shared library itself, not the directory "
      "holding it."
    )
  endif()
  message( STATUS "Run-time AL core: supplied, ${AL_CORE_RUNTIME_LIBRARY}" )
  return()
endif()

include( ExternalProject )

# The same two acquisition modes the rest of this build uses, so a shim build asks
# for its AL core the way every other mode does.
if( AL_DOWNLOAD_DEPENDENCIES )
  set( _al_core_runtime_source
    GIT_REPOSITORY "${AL_CORE_GIT_REPOSITORY}"
    GIT_TAG        "${AL_CORE_VERSION}"
  )
  message( STATUS
    "Run-time AL core: building ${AL_CORE_GIT_REPOSITORY} @ ${AL_CORE_VERSION}"
  )
elseif( AL_DEVELOPMENT_LAYOUT )
  set( _al_core_runtime_src_dir "${CMAKE_CURRENT_SOURCE_DIR}/../IMAS-Core" )
  if( NOT EXISTS "${_al_core_runtime_src_dir}/CMakeLists.txt" )
    message( FATAL_ERROR
      "AL_DEVELOPMENT_LAYOUT=ON but ${_al_core_runtime_src_dir} has no CMakeLists.txt. "
      "Clone the IMAS-Core repository next to this one, set AL_DOWNLOAD_DEPENDENCIES=ON, "
      "or point AL_CORE_RUNTIME_LIBRARY at an AL core that is already built."
    )
  endif()
  # DOWNLOAD_COMMAND is emptied so that an unset download method is no step at all
  # rather than an error about a missing URL.
  set( _al_core_runtime_source
    SOURCE_DIR       "${_al_core_runtime_src_dir}"
    DOWNLOAD_COMMAND ""
  )
  message( STATUS "Run-time AL core: building ${_al_core_runtime_src_dir}" )
else()
  message( FATAL_ERROR
    "AL_USE_MULTIVERSION_SHIM needs an AL core to open at run time, and neither "
    "acquisition mode is enabled. Set AL_DOWNLOAD_DEPENDENCIES=ON, or "
    "AL_DEVELOPMENT_LAYOUT=ON with a sibling IMAS-Core checkout, or point "
    "AL_CORE_RUNTIME_LIBRARY at an AL core that is already built."
  )
endif()

set( _al_core_runtime_args
  # The shim opens a shared library; a static AL core could not be opened at all.
  "-DBUILD_SHARED_LIBS=ON"
  # Refused at the top of ALCore.cmake's shim branch, so it cannot be on here.
  "-DAL_BACKEND_MDSPLUS=OFF"
)
foreach( _var IN ITEMS CMAKE_BUILD_TYPE CMAKE_C_COMPILER CMAKE_CXX_COMPILER )
  if( ${_var} )
    list( APPEND _al_core_runtime_args "-D${_var}=${${_var}}" )
  endif()
endforeach()
# AL core's own backend options are not declared in a shim build — ALCore.cmake
# says why — so whatever the operator passed to *this* project is forwarded to the
# run-time AL core by hand. An option left undefined here is not passed at all, so
# it keeps AL core's own default instead of being forced to an empty, false value.
foreach( _var IN ITEMS AL_BACKEND_HDF5 AL_BACKEND_UDA AL_BACKEND_UDAFAT )
  if( DEFINED ${_var} )
    list( APPEND _al_core_runtime_args "-D${_var}=${${_var}}" )
  endif()
endforeach()

set( _al_core_runtime_binary_dir "${CMAKE_BINARY_DIR}/_deps/al-core-runtime-build" )
# `al` lands in the top of its own binary directory: AL core's CMakeLists.txt
# declares it there and sets no LIBRARY_OUTPUT_DIRECTORY. That is what makes the
# path predictable without a target to interrogate.
set( _al_core_runtime_library
  "${_al_core_runtime_binary_dir}/${CMAKE_SHARED_LIBRARY_PREFIX}al${CMAKE_SHARED_LIBRARY_SUFFIX}"
)

# Left in ALL deliberately, and that is the only thing sequencing it: nothing
# links this library, so there is no dependency edge to carry the ordering, and an
# edge onto al-fortran would serialise two builds that have no reason to wait for
# each other.
ExternalProject_Add( al-core-runtime
  ${_al_core_runtime_source}
  PREFIX           "${CMAKE_BINARY_DIR}/_deps/al-core-runtime"
  BINARY_DIR       "${_al_core_runtime_binary_dir}"
  CMAKE_ARGS       ${_al_core_runtime_args}
  BUILD_BYPRODUCTS "${_al_core_runtime_library}"
  # Nothing installs it and nothing tests it from here: this build only opens the
  # library out of the build tree.
  INSTALL_COMMAND  ""
  TEST_COMMAND     ""
)

# A normal variable deliberately shadowing the cache entry declared above, which
# stays empty. Writing the built path into the cache instead would make the next
# configure take the "supplied" branch and skip building AL core at all.
set( AL_CORE_RUNTIME_LIBRARY "${_al_core_runtime_library}" )
message( STATUS "Run-time AL core: ${AL_CORE_RUNTIME_LIBRARY}" )
