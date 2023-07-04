program imas_hello_world
    ! Make the Access Layer available
    use ids_routines
    implicit none

    CHARACTER(len=255) :: ual_version

    call get_environment_variable("UAL_VERSION", ual_version)

    write(*,*) "Hello world!"
    write(*,*) "Using access layer version: ", ual_version

end program imas_hello_world
