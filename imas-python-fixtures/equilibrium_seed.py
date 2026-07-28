"""Write two equilibrium HDF5 fixtures, DD 3.39.0 and DD 4.1.1, built to
highlight what a DD 3 -> DD 4 conversion has to do.

Usage: python equilibrium_seed.py [output-dir]   # default: fixtures

The DD 4.1.1 fixture is the expected result of converting the DD 3.39.0 one:
same physical content, written to the renamed paths, with the COCOS 11 -> 17
sign flips applied. Both fill functions below are line-for-line aligned, so
diffing them shows the whole conversion.

Differences covered, one field each (paths relative to time_slice unless noted):

  DD 3.39.0                             DD 4.1.1                      what changes
  ids_properties/source                 provenance/node/reference/name field removed, moved into a structure
  vacuum_toroidal_field/r0              same                          nothing (control)
  vacuum_toroidal_field/b0              same                          nothing, COCOS factor +1 (control)
  profiles_1d/psi                       same                          sign flip (psi_like)
  profiles_1d/f_df_dpsi                 same                          sign flip (dodpsi_like) + units restring
                                                                        T^2.m^2/Wb -> T^2.m^2.Wb^-1
  global_quantities/ip                  same                          sign flip (ip_like)
  constraints/ip/measured               same                          sign flip (ip_like)
  profiles_1d/j_tor                     profiles_1d/j_phi             rename + sign flip (ip_like)
  global_quantities/psi_axis            global_quantities/            rename + sign flip (psi_like); psi_axis
                                          psi_magnetic_axis             still exists in DD 4 but is obsolescent,
                                                                        so it stays empty
  global_quantities/beta_normal         global_quantities/            rename only
                                          beta_tor_norm
  global_quantities/magnetic_axis/      same, b_field_phi             rename only (COCOS factor +1)
    b_field_tor
  profiles_2d/b_field_tor               profiles_2d/b_field_phi       rename only, 2D array
  constraints/bpol_probe                constraints/                  AOS rename only
                                          b_field_pol_probe
  constraints/strike_point/             same                          units m -> m^-2, value unchanged
    chi_squared_r
"""

import shutil
import sys
from pathlib import Path

import imas
from imas.ids_defs import IDS_TIME_MODE_HOMOGENEOUS

TIME = [1.0, 1.5]
R0 = 6.2
B0 = [5.3, 5.2]
GRID_DIM1 = [4.0, 5.0]  # profiles_2d R grid, coordinate of b_field_tor/b_field_phi
GRID_DIM2 = [-1.0, 0.0, 1.0]  # profiles_2d Z grid
SOURCE = "equilibrium_seed fixture"
COMMENT = "equilibrium DD 3 -> DD 4 conversion fixture"


def slice_values(i):
    """Values for time slice i, in the DD 3.39.0 (COCOS 11) sign convention."""
    return {
        "psi": [0.25 + r + 10.0 * i for r in range(4)],
        "f_df_dpsi": [-1.5 - r - 0.5 * i for r in range(4)],
        "j_tor": [1.0e6 + 1.0e5 * r + 1.0e4 * i for r in range(4)],
        "b_field_tor_2d": [[3.1 + r + 0.1 * c + i for c in range(3)] for r in range(2)],
        "ip": 15.0e6 + 1.0e5 * i,
        "ip_measured": 15.1e6 + 1.0e5 * i,
        "psi_axis": -0.75 - 0.05 * i,
        "beta_normal": 1.8 + 0.1 * i,
        "b_field_tor_axis": 5.2 + 0.1 * i,
        "bpol_probe_measured": 0.42 + 0.01 * i,
        "chi_squared_r": 0.05 + 0.01 * i,
    }


def fill_dd3(eq):
    eq.ids_properties.homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
    eq.ids_properties.comment = COMMENT
    eq.ids_properties.source = SOURCE
    eq.vacuum_toroidal_field.r0 = R0
    eq.vacuum_toroidal_field.b0 = B0
    eq.time = TIME

    eq.time_slice.resize(len(TIME))
    for i, ts in enumerate(eq.time_slice):
        v = slice_values(i)
        ts.time = TIME[i]

        ts.profiles_1d.psi = v["psi"]
        ts.profiles_1d.f_df_dpsi = v["f_df_dpsi"]
        ts.profiles_1d.j_tor = v["j_tor"]

        ts.profiles_2d.resize(1)
        ts.profiles_2d[0].grid.dim1 = GRID_DIM1
        ts.profiles_2d[0].grid.dim2 = GRID_DIM2
        ts.profiles_2d[0].b_field_tor = v["b_field_tor_2d"]

        ts.global_quantities.ip = v["ip"]
        ts.global_quantities.psi_axis = v["psi_axis"]
        ts.global_quantities.beta_normal = v["beta_normal"]
        ts.global_quantities.magnetic_axis.b_field_tor = v["b_field_tor_axis"]

        ts.constraints.ip.measured = v["ip_measured"]
        ts.constraints.bpol_probe.resize(1)
        ts.constraints.bpol_probe[0].measured = v["bpol_probe_measured"]
        ts.constraints.strike_point.resize(1)
        ts.constraints.strike_point[0].chi_squared_r = v["chi_squared_r"]


def fill_dd4(eq):
    eq.ids_properties.homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
    eq.ids_properties.comment = COMMENT
    eq.ids_properties.provenance.node.resize(1)
    eq.ids_properties.provenance.node[0].reference.resize(1)
    eq.ids_properties.provenance.node[0].reference[0].name = SOURCE
    eq.vacuum_toroidal_field.r0 = R0
    eq.vacuum_toroidal_field.b0 = B0
    eq.time = TIME

    eq.time_slice.resize(len(TIME))
    for i, ts in enumerate(eq.time_slice):
        v = slice_values(i)
        ts.time = TIME[i]

        ts.profiles_1d.psi = [-x for x in v["psi"]]
        ts.profiles_1d.f_df_dpsi = [-x for x in v["f_df_dpsi"]]
        ts.profiles_1d.j_phi = [-x for x in v["j_tor"]]

        ts.profiles_2d.resize(1)
        ts.profiles_2d[0].grid.dim1 = GRID_DIM1
        ts.profiles_2d[0].grid.dim2 = GRID_DIM2
        ts.profiles_2d[0].b_field_phi = v["b_field_tor_2d"]

        ts.global_quantities.ip = -v["ip"]
        ts.global_quantities.psi_magnetic_axis = -v["psi_axis"]
        ts.global_quantities.beta_tor_norm = v["beta_normal"]
        ts.global_quantities.magnetic_axis.b_field_phi = v["b_field_tor_axis"]

        ts.constraints.ip.measured = -v["ip_measured"]
        ts.constraints.b_field_pol_probe.resize(1)
        ts.constraints.b_field_pol_probe[0].measured = v["bpol_probe_measured"]
        ts.constraints.strike_point.resize(1)
        ts.constraints.strike_point[0].chi_squared_r = v["chi_squared_r"]


FIXTURES = [("3.39.0", fill_dd3), ("4.1.1", fill_dd4)]


def write(pulse_dir, dd_version, fill):
    entry = imas.DBEntry(f"imas:hdf5?path={pulse_dir}", "w", dd_version=dd_version)
    eq = entry.factory.new("equilibrium")
    fill(eq)
    entry.put(eq)
    entry.close()


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "fixtures")
    for dd_version, fill in FIXTURES:
        pulse_dir = out / f"dd-{dd_version}"
        shutil.rmtree(pulse_dir, ignore_errors=True)
        out.mkdir(parents=True, exist_ok=True)
        write(pulse_dir, dd_version, fill)
        print(f"wrote {pulse_dir}")
