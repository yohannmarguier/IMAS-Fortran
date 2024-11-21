program test_new_examples
    ! example_001
    call open_db_entry_uri
    call create_db_entry_legacy
    call create_db_entry_uri_with_path

    ! example_002
    call creating_completly_new_ids
    call default_values_and_aos_operations
    call copying_and_validating_ids

    ! example_003
    call put_entire_ids
    call put_slice
    call put_into_non_default_occurrence

    ! example_004
    call read_entire_ids
    call read_slice

end program test_new_examples
