========================================================================================================================
How to run examples
========================================================================================================================

This code examples can be run using already prepared tests in

``al-fortran/doc/code_samples/tutorial/test_new_examples.f90``.

1. Change the directory to ``al-fortran/doc/code_samples/tutorial``.

.. code-block:: bash

    cd al-fortran/doc/code_samples/tutorial


2. To compile the Fortran code execute those commands:

.. code-block:: bash

    export FC=gfortran
    make



3. To **run** the code, execute the following command in ``Command Window``:

.. code-block:: bash

    ./test_new_examples