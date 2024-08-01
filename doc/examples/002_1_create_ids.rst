=========================================================================================================
Create IDS with Arrays of Structures (AoS)
=========================================================================================================

.. seealso::

    API documentation for :f:func:`ids_deallocate`

This example focuses on creating empty IDS and allocating arrays inside IDS structure.

.. literalinclude:: ../code_samples/tutorial/example_002_fill_data_in_ids.f90
    :start-after: !!! This example focuses on creating empty IDS and allocating arrays inside IDS structure
    :end-before: !!! This example focuses on handling arrays of structures and default values
    :language: fortran
    

.. output::

    .. code-block:: bash    
            
        printing empty_core_profiles%time from creating_completly_new_ids() function
        1.00
        2.00
        3.00
