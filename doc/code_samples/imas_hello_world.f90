program imas_hello_world
    ! Make the Access Layer available
    use ids_routines
    implicit none

    CHARACTER(len=255) :: imas_version

    call get_environment_variable("IMAS_VERSION", imas_version)

    write(*,*) "Hello world!"
    write(*,*) "Using access layer version: ", imas_version

end program imas_hello_world
