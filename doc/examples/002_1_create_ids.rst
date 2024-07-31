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
            
        Dumping empty_core_profiles:
            empty_core_profiles.ids_properties.homogeneous_time: 1
            empty_core_profiles.time:                            1 2 3
            empty_core_profiles.global_quantities.ip:            1 2 3

    .. todo :: zmienic