Getting Started with IMAS-Fortran
=================================

Welcome! This 5-minute guide will get you up and running with the IMAS-Fortran Access Layer.

**What is IMAS-Fortran?**

IMAS-Fortran is the IMAS data access library (formerly known as the Access Layer) for Fortran users/developers. It provides a high-level interface to read, write, and manipulate IMAS data structures.


Load the IMAS-Fortran Module
-------------------------------

On the ITER SDCC (supercomputing cluster), make the Access Layer available:

.. code-block:: bash

    module load IMAS-Fortran

To see available versions:

.. code-block:: bash

    module avail IMAS-Fortran

If you have a local installation, source the environment file instead:

.. code-block:: bash

    source <install_dir>/bin/al_env.sh


Connect to Data
-------------------------------------------

Start by opening a database entry using an IMAS URI. A URI tells the Access Layer 
where your data is stored and in what format.

.. code-block:: fortran

    use ids_ids
    use imas_al
    implicit none
    
    integer :: ctx
    character(len=256) :: uri
    
    ! Open a database entry
    uri = 'imas:hdf5?path=/path/to/data'
    ctx = imas_open(uri, 40)
    
    if (ctx < 0) then
        error stop 'Unable to open database'
    end if

**What's an IMAS URI?**

URIs follow the format: ``imas:backend?query_options``

For example:
- ``imas:hdf5?path=/path/to/data`` – Read from HDF5 files
- ``imas:mdsplus?path=./test_db`` – Read from MDSplus
- ``imas:uda?backend=...`` – Read from UDA backend

Learn more: :ref:`Data entry URIs`


Load and Display Data
------------------------

Fetch an IDS from your database entry:

.. code-block:: fortran

    use ids_magnetics_mod
    implicit none
    
    type(magnetics_type) :: magnetics
    integer :: ios
    
    ! Load the magnetics IDS (occurrence 0)
    call ids_get(ctx, magnetics, ios)
    
    if (ios /= 0) then
        error stop 'Failed to load magnetics'
    end if
    
    ! Explore the data
    print *, 'Time points:', magnetics%time
    print *, 'Number of flux loops:', size(magnetics%flux_loop)
    print *, 'Flux data:', magnetics%flux_loop(1)%flux%data


Modify and Store Data
------------------------

You can create new data, modify existing data, and store it back:

.. code-block:: fortran

    use ids_equilibrium_mod
    implicit none
    
    type(equilibrium_type) :: equilibrium
    integer :: ios
    
    ! Create a new IDS
    call ids_init(equilibrium)
    
    ! Modify data
    allocate(equilibrium%time(4))
    equilibrium%time = [0.0_dp, 1.0_dp, 2.0_dp, 3.0_dp]
    
    allocate(equilibrium%q_profile%value%data(4))
    equilibrium%q_profile%value%data = [1.0_dp, 2.0_dp, 3.0_dp, 4.0_dp]
    
    ! Store it to the database
    call ids_put(ctx, equilibrium, ios)
    
    if (ios /= 0) then
        error stop 'Failed to store equilibrium'
    end if


Clean Up
-----------

Always close the database entry when you're done:

.. code-block:: fortran

    integer :: ios
    
    call imas_close(ctx, ios)
    if (ios /= 0) then
        print *, 'Warning: error closing database'
    end if


Key Subroutines Reference
--------------------------

+=============================================+====================================================+
| Subroutine                                  | Purpose                                            |
+=============================================+====================================================+
| ``imas_open(uri, version, ctx)``            | Open a database entry at the given URI             |
+---------------------------------------------+----------------------------------------------------+
| ``imas_close(ctx, status)``                 | Close the database entry                           |
+---------------------------------------------+----------------------------------------------------+
| ``ids_get(ctx, ids_obj, status)``           | Load an entire IDS                                 |
+---------------------------------------------+----------------------------------------------------+
| ``ids_put(ctx, ids_obj, status)``           | Store an IDS to disk                               |
+---------------------------------------------+----------------------------------------------------+
| ``ids_init(ids_obj)``                       | Initialize a new IDS structure                     |
+---------------------------------------------+----------------------------------------------------+
| ``ids_get_slice(ctx, ids_obj, time, status)`` | Load a specific time slice                        |
+=============================================+====================================================+


Common Use Cases
----------------

**Load data and extract a single time slice:**

.. code-block:: fortran

    use ids_equilibrium_mod
    implicit none
    
    type(equilibrium_type) :: equilibrium
    integer :: ios
    
    ! Use CLOSEST interpolation
    call ids_get_slice(ctx, equilibrium, 2.5_dp, ios)


**Check if data is defined:**

.. code-block:: fortran

    if (ids_isdefined(magnetics%flux_loop(1)%flux)) then
        print *, 'Flux data is defined'
    end if


**Access Fortran examples:**

The repository contains several example programs in the ``examples/`` directory:
- ``test_magnetics_get.f90`` – Load and display magnetics data
- ``test_magnetics_put.f90`` – Store new data
- ``test_core_profiles_put.f90`` – Practical core profiles example


Complete Example Program
------------------------

.. code-block:: fortran

    program example_imas_usage
        use imas_al
        use ids_magnetics_mod
        implicit none
        
        integer :: ctx, ios
        type(magnetics_type) :: magnetics
        character(len=256) :: uri
        
        ! Open database
        uri = 'imas:hdf5?path=/data/example.h5'
        ctx = imas_open(uri, 3)
        
        if (ctx < 0) then
            error stop 'Failed to open database'
        end if
        
        ! Load magnetics data
        call ids_get(ctx, magnetics, ios)
        
        if (ios == 0) then
            print *, 'Successfully loaded magnetics'
            print *, 'Time points:', size(magnetics%time)
        else
            print *, 'Error loading magnetics:', ios
        end if
        
        ! Close database
        call imas_close(ctx, ios)
        
    end program example_imas_usage
