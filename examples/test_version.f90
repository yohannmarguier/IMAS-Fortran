program test
    use ids_routines
    implicit none

    character, pointer, dimension(:) :: al_version

    call al_get_version(al_version)

    write(*,*) 'Lowlevel version: ', al_version
    write(*,*) 'Fortran HLI version: ', al_fortran_version
    write(*,*) 'Data Dictionary version: ', al_dd_version

end program test
