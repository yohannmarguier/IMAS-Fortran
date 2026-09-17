#!/usr/bin/env bash
# Configure the CMake build tree.
#
# Extracted from the workflow's inline step so the build step can call it again
# after discarding a cached build tree that turned out to be unusable. Every
# input arrives as an environment variable set by the workflow; nothing here
# reads the matrix directly.
set -euo pipefail

: "${MATRIX_CC:?}" "${MATRIX_CXX:?}" "${MATRIX_FC:?}"
: "${BACKEND_HDF5:?}" "${BACKEND_MDSPLUS:?}" "${BACKEND_UDA:?}"
: "${USE_SYSTEM_PACKAGES:?}"

if [ "${USE_SYSTEM_PACKAGES}" = "true" ]; then
  BOOST_OPTS=()
  HDF5_OPTS=()
  PREFIX_PATH=()
else
  BOOST_OPTS=( -DBoost_NO_BOOST_CMAKE=ON -DBOOST_ROOT="$HOME/boost" -DBoost_INCLUDE_DIR="$HOME/boost/include" )
  HDF5_OPTS=( -DHDF5_ROOT="$HOME/hdf5" )
  PREFIX_PATH=( -DCMAKE_PREFIX_PATH="$HOME/boost;$HOME/hdf5" )
fi

# Retry: the configure step clones IMAS-Core and the Data Dictionary, so a
# transient network failure is the usual cause. A failed attempt may also leave
# a half-written build tree — including one restored from cache — so each retry
# starts from scratch.
export GIT_CURL_VERBOSE=1
for attempt in 1 2 3; do
  echo "CMake configuration attempt $attempt..."
  if cmake -B build \
      -DCMAKE_INSTALL_PREFIX="$PWD/install" \
      -DCMAKE_C_COMPILER="${MATRIX_CC}" \
      -DCMAKE_CXX_COMPILER="${MATRIX_CXX}" \
      -DCMAKE_Fortran_COMPILER="${MATRIX_FC}" \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      "${PREFIX_PATH[@]}" \
      -DAL_BACKEND_HDF5="${BACKEND_HDF5}" \
      -DAL_BACKEND_MDSPLUS="${BACKEND_MDSPLUS}" \
      -DAL_BACKEND_UDA="${BACKEND_UDA}" \
      -DAL_BUILD_MDSPLUS_MODELS=OFF \
      -DAL_DOWNLOAD_DEPENDENCIES=ON \
      -DAL_CORE_GIT_REPOSITORY=https://github.com/iterorganization/IMAS-Core.git \
      -DDD_GIT_REPOSITORY=https://github.com/iterorganization/IMAS-Data-Dictionary.git \
      -DAL_CORE_VERSION=develop \
      -DDD_VERSION=main \
      -DAL_EXAMPLES=ON \
      -DAL_TESTS=ON \
      -DAL_PLUGINS=OFF \
      -DAL_HLI_DOCS=OFF \
      "${BOOST_OPTS[@]}" \
      "${HDF5_OPTS[@]}"; then
    exit 0
  fi

  if [ "$attempt" -lt 3 ]; then
    echo "CMake configuration failed, retrying in 10 seconds..."
    rm -rf build
    sleep 10
  fi
done

echo "CMake configuration failed after 3 attempts"
exit 1
