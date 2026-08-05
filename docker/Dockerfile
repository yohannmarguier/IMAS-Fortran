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

# Rust, for the read-path middleware in middleware/. Not optional: the wrapper binds
# c_al_read_data to imas_mw_read_data, so a configure without cargo is a FATAL_ERROR and
# a build without it has no al_read_data path at all.
#
# Pinned to 1.76.0 rather than stable, for two reasons. It is the crate's declared floor
# (and the blessed ITER toolchain), so building in this image enforces the MSRV that no
# CI job checks — the failure mode being a 1.77+ feature shipping unnoticed. And it is
# the toolchain that pairs with this image's GCC 13, matching the cluster's
# Rust/1.76.0-GCCcore-13.2.0 module rather than inventing a third combination.
# `rustup toolchain install stable` inside the container adds stable alongside it.
#
# System-wide under /opt/rust with the directory left group/other-writable: CLion may run
# the container as root or as a mapped host user, and cargo writes to CARGO_HOME
# regardless of the crate having no dependencies to fetch. CARGO_HOME/bin is also where
# CMakeLists.txt looks when PATH is bare.
ENV RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo \
    PATH=/opt/rust/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path --profile minimal --default-toolchain 1.76.0 \
    && chmod -R a+rwX /opt/rust \
    && rustc --version && cargo --version

# Rust's gdb pretty-printers, so a &str or a String in a middleware frame prints as its
# value instead of as a pointer-and-length pair. rustup ships them with the toolchain and
# a `rust-gdb` wrapper that loads them, but CLion drives plain gdb, so wire them into the
# system gdbinit instead of relying on the wrapper being used.
#
# Three settings, each fixing something observed rather than added on principle:
#
# - breakpoint pending on: the shim lives in libal-fortran.so, which is not loaded when
#   gdb starts, so `break imas_mw_read_data` finds no symbol yet. Interactively gdb asks
#   whether to make the breakpoint pending; batch mode and some IDE paths answer no and
#   the breakpoint is dropped with only a line of output to say so.
# - source: registers the printers globally, which is what actually makes them work.
# - auto-load python-scripts off: rustc embeds a .debug_gdb_scripts section naming
#   gdb_load_rust_pretty_printers.py, which gdb then fails to resolve, opening every
#   single run with "Missing auto-load script at offset 0 in section .debug_gdb_scripts"
#   (setting scripts-directory and safe-path to point straight at it does not help —
#   `info auto-load python-scripts` still reports it as not loaded). Since the line above
#   has already loaded the printers by hand, the auto-load path has nothing left to
#   contribute except that warning, so it is turned off. Verified: printers still
#   register (StdString, StdStr, StdVec, ...), console is clean.
RUN SYSROOT="$(rustc --print sysroot)" \
    && test -f "$SYSROOT/lib/rustlib/etc/gdb_load_rust_pretty_printers.py" \
    && mkdir -p /etc/gdb \
    && { echo "set breakpoint pending on"; \
         echo "set auto-load python-scripts off"; \
         echo "source $SYSROOT/lib/rustlib/etc/gdb_load_rust_pretty_printers.py"; \
       } >> /etc/gdb/gdbinit

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

# Running this by hand rather than through the IDE's toolchain needs ptrace allowed, or
# gdb attaches to nothing:
#
#   docker build -t imas-fortran-dev -f docker/Dockerfile docker/
#   docker run --rm -it --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
#     -v "$PWD:/work" imas-fortran-dev
#
# A CLion Docker toolchain passes those two itself. Configure with
# -DCMAKE_BUILD_TYPE=Debug to get the middleware's inspectable dev profile.
WORKDIR /work
