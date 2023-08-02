program imas_hello_world
    ! Make the Access Layer available
    use ids_routines
    implicit none

    CHARACTER(len=255) :: al_version

    call get_environment_variable("AL_VERSION", al_version)

    write(*,*) "Hello world!"
    write(*,*) "Using access layer version: ", al_version

end program imas_hello_world
