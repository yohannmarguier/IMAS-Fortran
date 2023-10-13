program imas_hello_world
    ! Make the Access Layer available
    use ids_routines
    implicit none

    character, pointer, dimension(:) :: al_version

    call al_get_version(al_version)

    write(*,*) 'Hello world!'
    write(*,*) 'Access Layer version info:'
    write(*,*) '  Low level version: ', al_version
    write(*,*) '  Data Dictionary version: ', al_dd_version
    write(*,*) '  Fortran HLI version: ', al_fortran_version

end program imas_hello_world
