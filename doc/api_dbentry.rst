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

..
    ###########################################################################

.. cpp:class:: IDS

    .. cpp:function:: int openEnv(const char *user, const char *tokamak, const char *version, const char *option)

        Open the Data Entry defined by ``shot``, ``run`` (see
        :cpp:func:`IDS::IDS() <void IDS::IDS(int,int,int,int)>`)
        and the provided parameters.

        :param user: 
        :param : 
        :param version: 
        :param option: Options to pass to the backend
        :returns: Status code: ``0`` on success, ``<0`` on failure
        :example: See :ref:`Open an existing IMAS Database Entry`.

    .. cpp:function:: int create(const char *uri, int mode)

        Create the Data Entry at the provided URI.

        :param uri: :ref:`Data entry URI <Data entry URIs>`
        :param mode: One of :cpp:expr:`CREATE_PULSE`, :cpp:expr:`FORCE_CREATE_PULSE`
        :returns: Status code: ``0`` on success, ``<0`` on failure
        :example: See :ref:`Create a new IMAS Database Entry`.

    .. cpp:function:: int createEnv(const char *user, const char *tokamak, const char *version, const char *option)

        Create the Data Entry defined by ``shot``, ``run`` (see
        :cpp:func:`IDS::IDS() <void IDS::IDS(int,int,int,int)>`)
        and the provided parameters.

        :param user: User name
        :param tokamak: Tokamak name, also known as Database name
        :param version: Major version of the data dictionary, e.g. ``"3"``
        :param option: Options to pass to the backend
        :returns: Status code: ``0`` on success, ``<0`` on failure

    .. cpp:function:: void setBackend(BACKEND inBackend)

        Use the specified backend instead of the default one. Must be set before
        a call to :cpp:func:`openEnv` or :cpp:func:`createEnv`.

        :param inBackend: The backend to use
    
    .. cpp:function:: int getPulseCtx()

        Get the pulse context ID opened/created by this Data Entry.

        :returns: Pulse context ID.

        .. seealso::
            :cpp:expr:`Ids::setPulseCtx()`
