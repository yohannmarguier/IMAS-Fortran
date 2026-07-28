program play_equilibrium
  ! Read the checked-in DD 4.1.1 equilibrium fixture (imas-python-fixtures/) and
  ! print the fields that equilibrium_seed.py writes.
  use ids_routines
  implicit none

  character(*), parameter :: FIXTURE = '../imas-python-fixtures/fixtures/dd-4.1.1'
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
     print *, 'provenance ref name: ', &
          trim(eq%ids_properties%provenance%node(1)%reference(1)%name(1))
  end if
  print *, 'vacuum r0          : ', eq%vacuum_toroidal_field%r0
  print *, 'vacuum b0          : ', eq%vacuum_toroidal_field%b0
  print *, 'time               : ', eq%time

  do i = 1, size(eq%time_slice)
     print *, '--- time_slice(', i, ') t =', eq%time_slice(i)%time
     print *, '  profiles_1d%psi            : ', eq%time_slice(i)%profiles_1d%psi
     print *, '  profiles_1d%f_df_dpsi      : ', eq%time_slice(i)%profiles_1d%f_df_dpsi
     print *, '  profiles_1d%j_phi          : ', eq%time_slice(i)%profiles_1d%j_phi
     print *, '  profiles_2d(1)%grid%dim1   : ', eq%time_slice(i)%profiles_2d(1)%grid%dim1
     print *, '  profiles_2d(1)%grid%dim2   : ', eq%time_slice(i)%profiles_2d(1)%grid%dim2
     print *, '  profiles_2d(1)%b_field_phi : ', eq%time_slice(i)%profiles_2d(1)%b_field_phi
     print *, '  gq%ip                      : ', eq%time_slice(i)%global_quantities%ip
     print *, '  gq%psi_magnetic_axis       : ', eq%time_slice(i)%global_quantities%psi_magnetic_axis
     print *, '  gq%beta_tor_norm           : ', eq%time_slice(i)%global_quantities%beta_tor_norm
     print *, '  gq%magnetic_axis%b_field_phi: ', &
          eq%time_slice(i)%global_quantities%magnetic_axis%b_field_phi
     print *, '  constraints%ip%measured    : ', eq%time_slice(i)%constraints%ip%measured
     print *, '  constraints%b_field_pol_probe(1)%measured: ', &
          eq%time_slice(i)%constraints%b_field_pol_probe(1)%measured
     print *, '  constraints%strike_point(1)%chi_squared_r: ', &
          eq%time_slice(i)%constraints%strike_point(1)%chi_squared_r
  end do

  call ids_deallocate(eq)
  call imas_close(idx)

  print *, 'Done.'
end program play_equilibrium
