program play_equilibrium
  ! Read a checked-in equilibrium fixture (imas-python-fixtures/) and print the fields
  ! that equilibrium_seed.py writes.
  !
  ! FIXTURE below names a DD 3.39.0 entry while the library is DD 4.1.1, so run it both
  ! ways to see what the Rust read-path middleware does:
  !
  !   ./bin/play_equilibrium                       # raw: DD4 names against a DD3 entry
  !   IMAS_MW_CONVERT=1 ./bin/play_equilibrium     # converted, with the losses on stderr
  !
  ! Raw, the fields DD 4 renamed come back as ids_*_invalid and the renamed arrays of
  ! structures come back empty, which is why every array below is checked with
  ! `associated` before it is indexed. play_eq_mw_convert.f90 is the same read with
  ! assertions instead of prints.
  use ids_routines
  implicit none

  character(*), parameter :: FIXTURE = '../imas-python-fixtures/fixtures/dd-3.39.0'
  integer :: idx, status, i
  character(:), allocatable :: retmsg
  type(ids_equilibrium) :: eq

  print *, 'DD version of this al-fortran build: ', trim(al_dd_version)

  call imas_open('imas:hdf5?path='//FIXTURE, OPEN_PULSE, idx, status, retmsg)
  if (status /= 0) then
     print *, 'imas_open failed: ', retmsg
     stop 1
  end if

  call ids_get(idx, 'equilibrium', eq, status)
  if (status /= 0) then
     print *, 'ids_get failed, status = ', status
     call imas_close(idx)
     stop 1
  end if

  if (associated(eq%ids_properties%comment)) then
     print *, 'comment            : ', trim(eq%ids_properties%comment(1))
  end if
  if (associated(eq%ids_properties%provenance%node)) then
     !print *, 'provenance ref name: ', &
     !     trim(eq%ids_properties%provenance%node(1)%reference(1)%name(1))
  end if
  print *, 'vacuum r0          : ', eq%vacuum_toroidal_field%r0
  print *, 'vacuum b0          : ', eq%vacuum_toroidal_field%b0
  print *, 'time               : ', eq%time

  if (.not. associated(eq%time_slice)) then
     print *, 'time_slice is empty - nothing more to print'
     call ids_deallocate(eq)
     call imas_close(idx)
     stop 1
  end if

  do i = 1, size(eq%time_slice)
     print *, '--- time_slice(', i, ') t =', eq%time_slice(i)%time
     call show('profiles_1d%psi            ', eq%time_slice(i)%profiles_1d%psi)
     call show('profiles_1d%f_df_dpsi      ', eq%time_slice(i)%profiles_1d%f_df_dpsi)
     call show('profiles_1d%j_phi          ', eq%time_slice(i)%profiles_1d%j_phi)
     if (associated(eq%time_slice(i)%profiles_2d)) then
        call show('profiles_2d(1)%grid%dim1   ', eq%time_slice(i)%profiles_2d(1)%grid%dim1)
        call show('profiles_2d(1)%grid%dim2   ', eq%time_slice(i)%profiles_2d(1)%grid%dim2)
     else
        print *, '  profiles_2d               : (empty)'
     end if
     print *, '  gq%ip                      : ', eq%time_slice(i)%global_quantities%ip
     print *, '  gq%psi_magnetic_axis       : ', eq%time_slice(i)%global_quantities%psi_magnetic_axis
     print *, '  gq%beta_tor_norm           : ', eq%time_slice(i)%global_quantities%beta_tor_norm
     print *, '  gq%magnetic_axis%b_field_phi: ', &
          eq%time_slice(i)%global_quantities%magnetic_axis%b_field_phi
     print *, '  constraints%ip%measured    : ', eq%time_slice(i)%constraints%ip%measured
     ! bpol_probe in DD 3, b_field_pol_probe in DD 4, and an array of structures - so
     ! without the middleware's path rewrite this one is empty, not merely invalid.
     if (associated(eq%time_slice(i)%constraints%b_field_pol_probe)) then
        print *, '  constraints%b_field_pol_probe(1)%measured: ', &
             eq%time_slice(i)%constraints%b_field_pol_probe(1)%measured
     else
        print *, '  constraints%b_field_pol_probe: (empty)'
     end if
     if (associated(eq%time_slice(i)%constraints%strike_point)) then
        print *, '  constraints%strike_point(1)%chi_squared_r: ', &
             eq%time_slice(i)%constraints%strike_point(1)%chi_squared_r
     else
        print *, '  constraints%strike_point   : (empty)'
     end if
  end do

  call ids_deallocate(eq)
  call imas_close(idx)

  print *, 'Done.'

contains

  ! Array components of a generated IDS type are pointers, not allocatables, so a field
  ! that was not read is a null pointer. Printing one is undefined behaviour, and against
  ! a cross-version entry it is the common case, not the exception.
  subroutine show(label, values)
    character(*), intent(in) :: label
    real(ids_real), dimension(:), pointer, intent(in) :: values
    if (associated(values)) then
       print *, '  '//label//': ', values
    else
       print *, '  '//label//': (not read)'
    end if
  end subroutine show

end program play_equilibrium
