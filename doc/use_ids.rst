
.. highlight:: fortran

.. include:: ../../doc_common/use_ids.rst

.. |lang| replace:: Fortran

.. |create_ids_text| replace:: creating a new variable with :code:`type(ids_<ids name>)`, for example :code:`type(ids_core_profiles) :: cp`
.. |copy_ids| replace:: by calling :f:func:`ids_copy`
.. |deallocate_ids_text| replace:: You can call :f:func:`ids_deallocate` to deallocate an IDS.

.. |structures_type| replace:: derived type
.. |structures_child_attribute| replace:: data members
.. |aos_type| replace:: a :code:`pointer (:)` to a derived type
.. |aos_default| replace:: `not associated` (:code:`associated(node) .eq. .false.`)
.. |aos_resize_meth| replace:: :code:`deallocate(node); allocate(node(n))`
.. |aos_resize_keep_meth| replace:: a temporary variable (as in below example)

.. |str_type| replace:: :code:`character(len=132), dimension(:), pointer`: ``STR_0D`` is implemented as a vector of strings of length 132 characters, allowing arbitrary long strings
.. |str_1d_type| replace:: :code:`character(len=132), dimension(:), pointer`: ``STR1D`` implementation is for the moment limited to a vector of 132 character strings
.. |int_type| replace:: :code:`integer(ids_int)`
.. |int_nd_type| replace:: N-dimensional :code:`integer(ids_int), pointer`
.. |double_type| replace:: :code:`real(ids_real)`
.. |double_nd_type| replace:: N-dimensional :code:`real(ids_real), pointer`
.. |complex_type| replace:: :code:`complex(ids_real)`
.. |complex_nd_type| replace:: N-dimensional :code:`complex(ids_real), pointer`

.. |str_default| replace:: not associated
.. |str_1D_default| replace:: not associated
.. |int_default| replace:: :code:`-999_999_999`, :f:var:`IDS_INT_INVALID`
.. |double_default| replace:: :code:`-9e40`, :f:var:`IDS_REAL_INVALID`
.. |complex_default| replace:: :code:`-9e40 -9e40i`, :f:var:`IDS_COMPLEX_INVALID`
.. |ND_default| replace:: not associated

.. |isFieldValid| replace:: You may use :f:func:`ids_is_valid` to test if a data node is not empty or unset.

.. |tm_homogeneous| replace:: :f:var:`IDS_TIME_MODE_HOMOGENEOUS`
.. |tm_heterogeneous| replace:: :f:var:`IDS_TIME_MODE_HETEROGENEOUS`
.. |tm_independent| replace:: :f:var:`IDS_TIME_MODE_INDEPENDENT`

.. |ids_validate| replace:: by calling :f:func:`ids_validate`
.. |validate_error| replace:: returns a nonzero status and error message
