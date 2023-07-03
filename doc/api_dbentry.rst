Data entry API
==============

..
    Since these subroutines are not generated, docs could be generated with autodoc.
    However, this proved a bit tricky, so choosing to document manual instead.

.. f:subroutine:: imas_open(uri, mode, pulseCtx, retstatus, retmesg)

    Open or create the Data Entry at the provided URI.

    :param character(*) uri [in]: :ref:`Data entry URI <Data entry URIs>`
    :param integer mode [in]: One of :f:var:`OPEN_PULSE`,
        :f:var:`FORCE_OPEN_PULSE`, :f:var:`CREATE_PULSE`, :f:var:`FORCE_CREATE_PULSE`
    :param integer pulseCtx [out]: Opened data entry context
    :option integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure
    :option character(:) retmesg [out]: Status message
    :example: See :ref:`Open an existing IMAS Database Entry`.

.. f:subroutine:: imas_open_env(name, shot, run, pulseCtx, user, tokamak, version, retstatus)

    Open the Data Entry defined by the provided parameters.

    :param character(*) name [in]: `Unused`
    :param integer shot [in]: Shot number
    :param integer run [in]: Run number
    :param integer pulseCtx [out]: Opened data entry context
    :param character(*) user [in]: User name
    :param character(*) tokamak [in]: Tokamak name, also known as Database name
    :param character(*) version [in]: Major version of the data dictionary, e.g. ``"3"``
    :option integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure

.. f:subroutine:: imas_create_env(name, shot, run, refShot, refRun, pulseCtx, user, tokamak, version, retstatus)

    Open the Data Entry defined by the provided parameters.

    :param character(*) name [in]: `Unused`
    :param integer shot [in]: Shot number
    :param integer run [in]: Run number
    :param integer refShot [in]: `Unused`
    :param integer refRun [in]: `Unused`
    :param integer pulseCtx [out]: Opened data entry context
    :param character(*) user [in]: User name
    :param character(*) tokamak [in]: Tokamak name, also known as Database name
    :param character(*) version [in]: Major version of the data dictionary, e.g. ``"3"``
    :option integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure
