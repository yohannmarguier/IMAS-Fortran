# Rust projection-engine substrate, built through Cargo via Corrosion.
# See README.md for scope (IMAS-Fortran issue #20) and the ABI conventions
# a C consumer must follow.

include( FetchContent )
FetchContent_Declare(
  Corrosion
  GIT_REPOSITORY "https://github.com/corrosion-rs/corrosion.git"
  GIT_TAG "v0.6.1"
)
FetchContent_MakeAvailable( Corrosion )

corrosion_import_crate( MANIFEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/Cargo.toml )

# Corrosion names its imported targets after the crate's `[lib] name`
# (`imas_projection_engine`, underscored, set explicitly in Cargo.toml),
# not the hyphenated `[package] name`. `imas_projection_engine` is
# itself Corrosion's own INTERFACE aggregator over the static/shared
# variant; wrap it in a plain target we own so include directories can be
# attached to it (CMake does not allow that on IMPORTED targets from
# outside the directory scope that created them). C consumers (including
# tests/contract below) should link against this wrapper, not Corrosion's
# target directly.
add_library( imas-projection-engine INTERFACE )
target_link_libraries( imas-projection-engine INTERFACE imas_projection_engine )
target_include_directories( imas-projection-engine INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include/engine>
)

install( DIRECTORY include/ DESTINATION include/engine )

if( AL_TESTS )
  add_subdirectory( tests/contract )
endif()
