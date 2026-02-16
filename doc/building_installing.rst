Building and installing the IMAS-Fortran
==========================================

This page describes how to build and install the IMAS-Fortran High Level Interface.

Documentation for developers wishing to contribute to the IMAS-Fortran can be found in
the :doc:`dev_guide`. Please refer to that guide if you wish to set
up a development environment.

For more information about related components, see:

-   `IMAS Core Documentation <https://imas-core.readthedocs.io/en/latest/>`__
-   `IMAS Data Dictionary Documentation <https://imas-data-dictionary.readthedocs.io/en/latest/>`__


.. _`build prerequisites`:

Prerequisites
-------------

To build the IMAS-Fortran you need:

-   Git
-   A Fortran compiler (gfortran 10.0 or later, ifort 2020 or later, NAGfor 6.2 or later)
-   CMake 3.16 or later
-   Boost 1.70 or later (with system, filesystem, log, thread libraries)
-   HDF5 1.10 or later (with Fortran support) - required for HDF5 backend
-   MDSplus 7.0 or later - optional, required for MDSplus backend
-   UDA - optional, required for UDA backend

**On Linux (recommended)**

Install build tools and dependencies via package manager:

.. code-block:: bash

    # Ubuntu/Debian
    sudo apt-get install cmake gfortran libboost-all-dev libhdf5-dev pkg-config

    # CentOS/RHEL
    sudo yum install cmake gcc-gfortran boost-devel hdf5-devel pkgconfig

**On macOS**

Use Homebrew:

.. code-block:: bash

    brew install cmake boost hdf5 open-mpi


Building
--------

Clone the repository and configure with CMake:

.. code-block:: bash

    git clone https://github.com/iterorganization/IMAS-Fortran.git
    cd IMAS-Fortran
    mkdir build && cd build

    cmake ..
    make -j$(nproc)
    make test    # optional: run tests
    make install


Installation
------------

After building, install the library and module files:

.. code-block:: bash

    make install

The default installation prefix is ``/usr/local``. To install in a custom location:

.. code-block:: bash

    cmake -DCMAKE_INSTALL_PREFIX=/path/to/install ..


Usage
-----

After installation, use the installed IMAS-Fortran library in your projects:

.. code-block:: bash

    # Compile your program with pkg-config
    gfortran your_program.f90 $(pkg-config --cflags --libs al-fortran)

Or manually specify the include and library paths:

.. code-block:: bash

    gfortran your_program.f90 \
        -I/path/to/install/include/fortran \
        -L/path/to/install/lib \
        -lal-fortran-<version>


Environment Setup
-----------------

The installation includes an environment setup script:

.. code-block:: bash

    source /path/to/install/bin/al_env.sh

This script sets up ``PATH``, ``LD_LIBRARY_PATH``, and ``PKG_CONFIG_PATH`` for you.

