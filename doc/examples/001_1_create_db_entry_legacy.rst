=========================================================================================================
Create DBEntry from scratch using *legacy* mode
=========================================================================================================

This example focuses on creating DBEntry using **legacy** mode method.

.. seealso::

    API documentation for:
        - :f:func:`al_build_uri_from_legacy_parameters`
        - :f:func:`imas_open`
    
.. warning::

    The legacy method is deprecated from ``AL>=5.0.0``.

    It is recommended to use the **URI** approach instead.

.. literalinclude:: ../code_samples/tutorial/example_001_open_database.f90
    :start-after: !!! Routine illustrating how to open pulse file in Fortran using
    :end-before:  !!! Routine illustrating how to open pulse file (using Fortran) with
    :language: fortran

