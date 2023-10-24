Plugins API
===========


.. f:subroutine:: al_register_plugin(plugin_name, retstatus)

    Register an Access Layer plugin.

    Plugins extend the functionality of the Access Layer. Plugins must be
    registered before they can be activated with :func:`al_bind_plugin()`.

    The environment variable ``IMAS_AL_PLUGINS`` indicates the folder where the
    compiled plugin(s) are located. If this environment variable is unset, or no
    shared library with the name ``<plugin_name>_plugin.so`` can be found, an
    exception status is returned.

    :param character(*) plugin_name [in]: Name of the plugin to register
    :param integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure

    .. rubric:: Example

    .. code-block:: fortran

        integer :: status

        call al_register_plugin("debug", status)
        if status .neq. 0
            error stop
        endif


.. f:subroutine:: al_unregister_plugin(plugin_name, retstatus)

    Unregister a previously registered Access Layer plugin.

    :param character(*) plugin_name [in]: Name of the plugin to register
    :param integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure


.. f:subroutine:: al_bind_plugin(path, plugin_name, retstatus)

    Activate an Access Layer plugin.

    Plugins are inactive until activated with bind_plugin. After activation,
    plugins can modify the data on the path(s) they are activated on during a
    :func:`ids_put()`, :func:`ids_put_slice()`,
    :func:`ids_get()` or :func:`ids_get_slice()`.

    :param character(*) path [in]: The path that the plugin is allowed to
        operate on: ``<ids_name>:<occurrence>/<path_in_ids>``.
    :param character(*) plugin_name [in]: Name of the plugin. The plugin must
        have been registered with a call to :func:`al_register_plugin()`.
    :param integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure

    .. rubric:: Example
    
    .. code-block:: fortran

        integer :: status

        call al_register_plugin("debug", status)
        if status .neq. 0
            error stop
        endif
        call al_bind_plugin ('magnetics:0/ids_properties/version_put/access_layer', 'debug', status)
        call al_bind_plugin ('magnetics:0/flux_loop', 'debug', status)


.. f:subroutine:: al_unbind_plugin(path, plugin_name, retstatus)

    Unbind a plugin on a previously bound path.

    Arguments are the same as for :func:`al_bind_plugin()`.


.. f:subroutine:: al_setvalue_parameter_plugin(parameter_name, datatype, dim, size, parameter_data, plugin_name, retstatus)

    Set a plugin parameter value.

    See the documentation of your specific plugin for more details.

    :param character(*) parameter_name [in]: Name of the parameter to set
    :param integer datatype [in]: Type of data (one of ``CHAR_DATA``,
        ``INTEGER_DATA``, ``DOUBLE_DATA`` or ``COMPLEX_DATA``)
    :param integer dim [in]: Dimension of the data
    :param type(C_PTR) size [in]: Pointer to array specifying the shape of the
        array (must have ``dim`` elements)
    :param type(C_PTR) data: Pointer to the data
    :param character(*) plugin_name [in]: Name of the plugin. The plugin must
        have been registered with a call to :func:`al_register_plugin()`.
    :param integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure


.. f:subroutine:: al_setvalue_int_scalar_parameter_plugin(parameter_name, parameter_value, plugin_name, retstatus)
    
    Convenience method to set a plugin parameter value to a scalar integer.

    See the documentation of your specific plugin for more details.

    :param character(*) parameter_name [in]: Name of the parameter to set
    :param integer parameter_value [int]: Value to set the parameter to
    :param character(*) plugin_name [in]: Name of the plugin. The plugin must
        have been registered with a call to :func:`al_register_plugin()`.
    :param integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure


.. f:subroutine:: al_setvalue_int_scalar_parameter_plugin(parameter_name, parameter_value, plugin_name, retstatus)
    
    Convenience method to set a plugin parameter value to a scalar real.

    See the documentation of your specific plugin for more details.

    :param character(*) parameter_name [in]: Name of the parameter to set
    :param real parameter_value [int]: Value to set the parameter to
    :param character(*) plugin_name [in]: Name of the plugin. The plugin must
        have been registered with a call to :func:`al_register_plugin()`.
    :param integer retstatus [out]: Status code: ``0`` on success, ``<0`` on failure
