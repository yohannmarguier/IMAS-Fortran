"""Write a minimal equilibrium HDF5 fixture, once per DD version.

Usage: python equilibrium_seed.py [output-dir]   (default: fixtures)

Creates one pulse per version in <output-dir>/dd-<version>. All the paths
below exist in both DD 3 and DD 4, so the content is identical and only the
DD version stamped into the pulse differs.
"""

import shutil
import sys
from pathlib import Path

import imas
from imas.ids_defs import IDS_TIME_MODE_HOMOGENEOUS

DD_VERSIONS = ["3.39.0", "4.1.1"]


def write(pulse_dir, dd_version):
    entry = imas.DBEntry(f"imas:hdf5?path={pulse_dir}", "w", dd_version=dd_version)

    eq = entry.factory.new("equilibrium")
    eq.ids_properties.homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
    eq.ids_properties.comment = f"equilibrium fixture (DD {dd_version})"
    eq.vacuum_toroidal_field.r0 = 6.2
    eq.time = [1.0, 1.5]

    eq.time_slice.resize(len(eq.time))
    for i, slice_ in enumerate(eq.time_slice):
        slice_.time = eq.time[i]
        slice_.profiles_1d.psi = [10.0 * i + r + 0.25 for r in range(4)]
        slice_.global_quantities.ip = 100.0 + 7.0 * i
        slice_.constraints.ip.measured = 200.0 + 3.0 * i
        slice_.constraints.ip.weight = 0.5 + 0.1 * i

    entry.put(eq)
    entry.close()


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "fixtures")
    for dd_version in DD_VERSIONS:
        pulse_dir = out / f"dd-{dd_version}"
        shutil.rmtree(pulse_dir, ignore_errors=True)
        out.mkdir(parents=True, exist_ok=True)
        write(pulse_dir, dd_version)
        print(f"wrote {pulse_dir}")
