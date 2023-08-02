IMAS constants
==============


Interpolation modes
-------------------

.. f:variable:: CLOSEST_INTERP
    :attrs: parameter=1

    Interpolation method that returns the `closest` time slice in the original
    IDS (can break causality as it can return data ahead of requested time).

    .. seealso:: :f:func:`ids_get_slice`

.. f:variable:: PREVIOUS_INTERP
    :attrs: parameter=2

    Interpolation method that returns the previous time slice if the requested
    time does not exactly exist in the original IDS.

    .. seealso:: :f:func:`ids_get_slice`

.. f:variable:: LINEAR_INTERP
    :attrs: parameter=3

    Interpolation method that returns a linear interpolation between the
    existing slices before and after the requested time.

    .. seealso:: :f:func:`ids_get_slice`


Empty values
------------

.. f:variable:: IDS_INT_INVALID
    :attrs: parameter=-999999999

    Value representing an unset integer in an IDS.

.. f:variable:: IDS_REAL_INVALID
    :attrs: parameter=-9E40

    Value representing an unset floating point number in an IDS.

.. f:variable:: IDS_COMPLEX_INVALID
    :attrs: parameter=CMPLX(-9E40, -9E40)

    Value representing an unset complex number in an IDS.


Serializer protocols
--------------------

.. f:variable:: ASCII_SERIALIZER_PROTOCOL
    :attrs: parameter=60

    Identifier for the ASCII serialization protocol.

.. f:variable:: DEFAULT_SERIALIZER_PROTOCOL

    Identifier for the default serialization protocol.


Time modes
----------

.. f:variable:: IDS_TIME_MODE_HETEROGENEOUS
    :attrs: parameter=0

    Time mode indicating that dynamic nodes may be asynchronous.

    Timebases of quantities are as indicated in the "Coordinates" column of the
    Data Dictionary documentation.

.. f:variable:: IDS_TIME_MODE_HOMOGENEOUS
    :attrs: parameter=1

    Time mode indicating that dynamic nodes are synchronous.

    Timebases of quantities are the "time" node that is the child of the nearest
    parent IDS.

.. f:variable:: IDS_TIME_MODE_INDEPENDENT
    :attrs: parameter=2

    Time mode indicating that no dynamic nodes are filled in the IDS.


Backend identifiers
-------------------

.. f:variable:: ASCII_BACKEND
    :attrs: parameter=11

    :ref:`ASCII backend`

.. f:variable:: MDSPLUS_BACKEND
    :attrs: parameter=12

    :ref:`MDSPLUS backend`

.. f:variable:: HDF5_BACKEND
    :attrs: parameter=13

    :ref:`HDF5 backend`

.. f:variable:: MEMORY_BACKEND
    :attrs: parameter=14

    :ref:`MEMORY backend`

.. f:variable:: UDA_BACKEND
    :attrs: parameter=15

    :ref:`UDA backend`


Data entry open/create modes
----------------------------

.. f:variable:: OPEN_PULSE
    :attrs: parameter=40

    Opens the access to the data only if the Data Entry exists, returns error
    otherwise.

.. f:variable:: FORCE_OPEN_PULSE
    :attrs: parameter=41

    Opens access to the data, creates the Data Entry if it does not exists yet.

.. f:variable:: CREATE_PULSE
    :attrs: parameter=42

    Creates a new empty Data Entry (returns error if Data Entry already exists)
    and opens it at the same time.

.. f:variable:: FORCE_CREATE_PULSE
    :attrs: parameter=43

    Creates an empty Data Entry (overwrites if Data Entry already exists) and
    opens it at the same time.


