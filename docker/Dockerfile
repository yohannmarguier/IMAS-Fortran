# A Linux build environment for this repository, for use as a CLion Docker toolchain.
#
# Why this exists: on macOS/arm64 there is no working Fortran debugger. LLDB has no
# Fortran type system (`frame variable` returns nothing, whatever the IDE does), and GDB
# - bundled or from Homebrew, both arm64 builds - can neither read gfortran's debug info
# through Apple's debug map nor start a process (`help target` lists no native target,
# so codesigning is beside the point). On Linux both work normally, so a container is
# the shortest route to inspecting a Fortran variable in an IDE.
#
# Deliberately not a production or CI image: it is a development environment, and CI
# (.github/workflows/build-and-test.yml) stays the reference for a supported build.
FROM ubuntu:24.04

# gfortran/g++ and the two libraries al-core needs (Boost filesystem, and HDF5 for the
# one backend this image enables). Distribution packages rather than CI's from-source
# Boost and HDF5: a debugging environment wants to be quick to rebuild, and no test here
# depends on those exact versions.
#
# gdb is the entire point of the image. cmake/ninja/git/python3-venv are the build
# itself - CMake fetches al-core and the Data Dictionary at configure time (so the
# container needs network then), and the Data Dictionary transforms run from a Python
# venv the build creates, which needs pip and the venv module. python3-dev is not
# optional either: ALBuildDataDictionary asks for Python's Development.Module component,
# so a configure without the headers fails at find_package rather than at build time.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      gfortran \
      gdb \
      cmake \
      ninja-build \
      git \
      ca-certificates \
      curl \
      pkg-config \
      python3 \
      python3-pip \
      python3-venv \
      python3-dev \
      libboost-filesystem-dev \
      libhdf5-dev \
    && rm -rf /var/lib/apt/lists/*

# The build reads the version out of the checked-out repository with git, and the
# repository is bind-mounted from the host, so it belongs to a different user than the
# one in the container. Without this git refuses it as "dubious ownership" and the
# version lookup fails at configure time. Safe here because the image only ever sees a
# directory its user already chose to mount.
RUN git config --system --add safe.directory '*'

# The generated tests and examples want a writable pulse location; playground programs
# do not, but a shell in this image is also a place to run ctest.
ENV USER=/tmp/testdb
RUN mkdir -p /tmp/testdb

WORKDIR /work
