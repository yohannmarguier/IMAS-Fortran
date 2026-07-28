"""Deterministic equilibrium-seed HDF5 fixtures, generated with imas-python.

Writes one `equilibrium` IDS fixture per DD version in DD_VERSIONS, deliberately
picked to span DD 4.0.0's restructuring of the equilibrium IDS so the two
fixtures exercise every kind of path difference a DD-version migration can
introduce:

  - renamed (tor -> phi):        time_slice/profiles_1d/j_tor -> j_phi
                                  time_slice/global_quantities/magnetic_axis/
                                  b_field_tor -> b_field_phi
  - renamed (spelling):          time_slice/constraints/mse_polarisation_angle
                                  -> mse_polarization_angle
  - removed (no replacement):    ids_properties/source (DD 3.39.0 only;
                                  superseded by ids_properties/provenance)
  - added (no prior path):       time_slice/global_quantities/rho_tor_boundary
                                  (DD 4.1.1 only; introduced at DD 3.40.0)

Everything else (vacuum_toroidal_field/r0, time, time_slice/time,
profiles_1d/psi, global_quantities/ip, constraints/ip/measured,
constraints/ip/weight) is stable across the whole DD history and is written
identically for both versions.

Shape (per DD version), each `equilibrium` IDS has:
  - vacuum_toroidal_field/r0  (FLT_0D)              -- static scalar
  - ids_properties/source     (STR_0D)               -- DD 3.39.0 only
  - time                      (FLT_1D)               -- homogeneous timebase
  - time_slice                (struct_array, timebasepath "time"), each with:
      * time                                              (FLT_0D)
      * profiles_1d/psi                                   (FLT_1D)
      * profiles_1d/{j_tor,j_phi}                         (FLT_1D)
      * global_quantities/ip                              (FLT_0D)
      * global_quantities/magnetic_axis/{b_field_tor,b_field_phi} (FLT_0D)
      * global_quantities/rho_tor_boundary                (FLT_0D, DD 4.1.1 only)
      * constraints/ip/measured                           (FLT_0D)
      * constraints/ip/weight                             (FLT_0D)
      * constraints/{mse_polarisation_angle,mse_polarization_angle}[0]/measured (FLT_0D)
"""

from __future__ import annotations

import argparse
import shutil
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

import numpy as np

import imas
from imas.ids_defs import IDS_TIME_MODE_HOMOGENEOUS
from imas_core.imasdef import CHAR_DATA, DOUBLE_DATA

IDS_NAME = "equilibrium"
SCALAR = "vacuum_toroidal_field/r0"
AOS = "time_slice"

N_SLICES = 2  # time_slice AOS elements (>1: a real AOS)
RADIAL_LEN = 4  # profiles_1d/psi, profiles_1d/j_{tor,phi} grid points per slice

# Marker for the synthetic AOS-size record, so array size participates in the
# hash (never a real Access Layer datatype).
AOS_SIZE_MARKER = -1


# --- per-DD-version schema ---------------------------------------------------
@dataclass(frozen=True)
class VersionSchema:
    dd_version: str
    j_field: str  # profiles_1d leaf: renamed j_tor -> j_phi at DD 4.0.0
    b_field_axis_field: str  # global_quantities/magnetic_axis leaf: renamed at DD 4.0.0
    mse_field: str  # constraints AOS name: renamed (spelling) at DD 4.0.0
    has_source: bool  # ids_properties/source: removed at DD 4.0.0
    has_rho_tor_boundary: bool  # global_quantities/rho_tor_boundary: added at DD 3.40.0


SCHEMAS: dict[str, VersionSchema] = {
    "3.39.0": VersionSchema(
        dd_version="3.39.0",
        j_field="j_tor",
        b_field_axis_field="b_field_tor",
        mse_field="mse_polarisation_angle",
        has_source=True,
        has_rho_tor_boundary=False,
    ),
    "4.1.1": VersionSchema(
        dd_version="4.1.1",
        j_field="j_phi",
        b_field_axis_field="b_field_phi",
        mse_field="mse_polarization_angle",
        has_source=False,
        has_rho_tor_boundary=True,
    ),
}
DD_VERSIONS: tuple[str, ...] = tuple(SCHEMAS)


# --- deterministic content ---------------------------------------------------
# Distinct arithmetic progressions per role and per slice, so a transposed,
# dropped, or reordered element is caught by the structural hash.
def scalar_r0() -> float:
    return 6.2


def ids_source_value() -> str:
    return "equilibrium_seed fixture (imas-python-fixtures, DD 3.39.0)"


def timebase_values() -> list[float]:
    return [1.0 + 0.5 * i for i in range(N_SLICES)]


def slice_time(i: int) -> float:
    return 1.0 + 0.5 * i


def slice_ip(i: int) -> float:
    return 100.0 + 7.0 * i


def slice_measured(i: int) -> float:
    return 200.0 + 3.0 * i


def slice_weight(i: int) -> float:
    return 0.5 + 0.1 * i


def slice_psi(i: int) -> list[float]:
    return [10.0 * i + r + 0.25 for r in range(RADIAL_LEN)]


def slice_j(i: int) -> list[float]:
    return [5.0 * i + r + 0.75 for r in range(RADIAL_LEN)]


def slice_b_field_axis(i: int) -> float:
    return 3.0 + 0.2 * i


def slice_rho_tor_boundary(i: int) -> float:
    return 2.0 + 0.15 * i


def slice_mse_measured(i: int) -> float:
    return 0.1 + 0.05 * i


# --- a single observed/expected field record ---------------------------------
@dataclass(frozen=True)
class Obs:
    field: str  # canonical identity, e.g. "time_slice[1]/profiles_1d/psi"
    datatype: int  # DOUBLE_DATA, CHAR_DATA, or AOS_SIZE_MARKER
    rank: int
    extents: tuple[int, ...]  # actual dims (empty for rank 0)
    values: tuple[float, ...] = ()  # for DOUBLE_DATA / AOS_SIZE_MARKER
    text: str = ""  # for CHAR_DATA

    def same_structure(self, other: "Obs") -> bool:
        return (
            self.field == other.field
            and self.datatype == other.datatype
            and self.rank == other.rank
            and self.extents == other.extents
        )


def slice_field(i: int, leaf: str) -> str:
    return f"{AOS}[{i}]/{leaf}"


def expected_records(schema: VersionSchema) -> list[Obs]:
    records = [
        Obs(SCALAR, DOUBLE_DATA, 0, (), values=(scalar_r0(),)),
        Obs("time", DOUBLE_DATA, 1, (N_SLICES,), values=tuple(timebase_values())),
        Obs(f"{AOS}.size", AOS_SIZE_MARKER, 0, (), values=(float(N_SLICES),)),
    ]
    if schema.has_source:
        records.append(
            Obs("ids_properties/source", CHAR_DATA, 0, (), text=ids_source_value())
        )
    for i in range(N_SLICES):
        records.append(
            Obs(slice_field(i, "time"), DOUBLE_DATA, 0, (), values=(slice_time(i),))
        )
        records.append(
            Obs(
                slice_field(i, "profiles_1d/psi"),
                DOUBLE_DATA,
                1,
                (RADIAL_LEN,),
                values=tuple(slice_psi(i)),
            )
        )
        records.append(
            Obs(
                slice_field(i, f"profiles_1d/{schema.j_field}"),
                DOUBLE_DATA,
                1,
                (RADIAL_LEN,),
                values=tuple(slice_j(i)),
            )
        )
        records.append(
            Obs(
                slice_field(i, "global_quantities/ip"),
                DOUBLE_DATA,
                0,
                (),
                values=(slice_ip(i),),
            )
        )
        records.append(
            Obs(
                slice_field(
                    i, f"global_quantities/magnetic_axis/{schema.b_field_axis_field}"
                ),
                DOUBLE_DATA,
                0,
                (),
                values=(slice_b_field_axis(i),),
            )
        )
        if schema.has_rho_tor_boundary:
            records.append(
                Obs(
                    slice_field(i, "global_quantities/rho_tor_boundary"),
                    DOUBLE_DATA,
                    0,
                    (),
                    values=(slice_rho_tor_boundary(i),),
                )
            )
        records.append(
            Obs(
                slice_field(i, "constraints/ip/measured"),
                DOUBLE_DATA,
                0,
                (),
                values=(slice_measured(i),),
            )
        )
        records.append(
            Obs(
                slice_field(i, "constraints/ip/weight"),
                DOUBLE_DATA,
                0,
                (),
                values=(slice_weight(i),),
            )
        )
        records.append(
            Obs(
                slice_field(i, f"constraints/{schema.mse_field}.size"),
                AOS_SIZE_MARKER,
                0,
                (),
                values=(1.0,),
            )
        )
        records.append(
            Obs(
                slice_field(i, f"constraints/{schema.mse_field}[0]/measured"),
                DOUBLE_DATA,
                0,
                (),
                values=(slice_mse_measured(i),),
            )
        )
    return records


# --- FNV-1a over the canonical structural stream -----------------------------
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
_MASK64 = (1 << 64) - 1


def _fnv1a_bytes(h: int, data: bytes) -> int:
    for b in data:
        h ^= b
        h = (h * FNV_PRIME) & _MASK64
    return h


def _fnv1a_int(h: int, v: int) -> int:
    # 4-byte little-endian, matching the C++ `int` layout the oracle hashes.
    return _fnv1a_bytes(h, struct.pack("<i", v))


def _fnv1a_double(h: int, v: float) -> int:
    # 8-byte IEEE-754 little-endian, matching the C++ `double` layout.
    return _fnv1a_bytes(h, struct.pack("<d", v))


def canonical_hash(records: Sequence[Obs]) -> int:
    h = FNV_OFFSET_BASIS
    h = _fnv1a_int(h, len(records))
    for r in records:
        h = _fnv1a_int(h, len(r.field))
        h = _fnv1a_bytes(h, r.field.encode("utf-8"))
        h = _fnv1a_int(h, r.datatype)
        h = _fnv1a_int(h, r.rank)
        h = _fnv1a_int(h, len(r.extents))
        for e in r.extents:
            h = _fnv1a_int(h, e)
        if r.datatype == CHAR_DATA:
            h = _fnv1a_int(h, len(r.text))
            h = _fnv1a_bytes(h, r.text.encode("utf-8"))
        else:
            h = _fnv1a_int(h, len(r.values))
            for v in r.values:
                h = _fnv1a_double(h, v)
    return h


def expected_hash(schema: VersionSchema) -> int:
    return canonical_hash(expected_records(schema))


# --- write the seed into a fresh HDF5 pulse ----------------------------------
def write(uri: str, schema: VersionSchema) -> None:
    entry = imas.DBEntry(uri, "w", dd_version=schema.dd_version)
    try:
        eq = entry.factory.new(IDS_NAME)
        eq.ids_properties.homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
        eq.ids_properties.comment = (
            f"equilibrium_seed fixture (imas-python-fixtures, DD {schema.dd_version})"
        )
        if schema.has_source:
            eq.ids_properties.source = ids_source_value()

        eq.vacuum_toroidal_field.r0 = scalar_r0()
        eq.time = timebase_values()

        eq.time_slice.resize(N_SLICES)
        for i in range(N_SLICES):
            ts = eq.time_slice[i]
            ts.time = slice_time(i)
            ts.profiles_1d.psi = slice_psi(i)
            setattr(ts.profiles_1d, schema.j_field, slice_j(i))
            ts.global_quantities.ip = slice_ip(i)
            setattr(
                ts.global_quantities.magnetic_axis,
                schema.b_field_axis_field,
                slice_b_field_axis(i),
            )
            if schema.has_rho_tor_boundary:
                ts.global_quantities.rho_tor_boundary = slice_rho_tor_boundary(i)
            ts.constraints.ip.measured = slice_measured(i)
            ts.constraints.ip.weight = slice_weight(i)
            mse = getattr(ts.constraints, schema.mse_field)
            mse.resize(1)
            mse[0].measured = slice_mse_measured(i)

        entry.put(eq)
    finally:
        entry.close()


# --- read the seed back, rebuilding the observed canonical stream -----------
# Records exactly what the backend returned (real rank/extents/AOS size), so
# shape drift on read surfaces as a hash mismatch instead of silent
# reconciliation -- no assertions here, callers compare against
# expected_records()/expected_hash().
def read_back(uri: str, schema: VersionSchema) -> list[Obs]:
    entry = imas.DBEntry(uri, "r", dd_version=schema.dd_version)
    try:
        eq = entry.get(IDS_NAME)
    finally:
        entry.close()

    def leaf(value, field_name: str) -> Obs:
        arr = np.asarray(value, dtype=float)
        return Obs(
            field_name,
            DOUBLE_DATA,
            arr.ndim,
            tuple(arr.shape),
            values=tuple(arr.flatten().tolist()),
        )

    records = [
        leaf(eq.vacuum_toroidal_field.r0, SCALAR),
        leaf(eq.time, "time"),
    ]

    size = len(eq.time_slice)
    records.append(Obs(f"{AOS}.size", AOS_SIZE_MARKER, 0, (), values=(float(size),)))

    if schema.has_source:
        records.append(
            Obs(
                "ids_properties/source",
                CHAR_DATA,
                0,
                (),
                text=str(eq.ids_properties.source),
            )
        )

    for i in range(size):
        ts = eq.time_slice[i]
        records.append(leaf(ts.time, slice_field(i, "time")))
        records.append(leaf(ts.profiles_1d.psi, slice_field(i, "profiles_1d/psi")))
        records.append(
            leaf(
                getattr(ts.profiles_1d, schema.j_field),
                slice_field(i, f"profiles_1d/{schema.j_field}"),
            )
        )
        records.append(
            leaf(ts.global_quantities.ip, slice_field(i, "global_quantities/ip"))
        )
        records.append(
            leaf(
                getattr(ts.global_quantities.magnetic_axis, schema.b_field_axis_field),
                slice_field(
                    i, f"global_quantities/magnetic_axis/{schema.b_field_axis_field}"
                ),
            )
        )
        if schema.has_rho_tor_boundary:
            records.append(
                leaf(
                    ts.global_quantities.rho_tor_boundary,
                    slice_field(i, "global_quantities/rho_tor_boundary"),
                )
            )
        records.append(
            leaf(
                ts.constraints.ip.measured,
                slice_field(i, "constraints/ip/measured"),
            )
        )
        records.append(
            leaf(
                ts.constraints.ip.weight,
                slice_field(i, "constraints/ip/weight"),
            )
        )
        mse = getattr(ts.constraints, schema.mse_field)
        records.append(
            Obs(
                slice_field(i, f"constraints/{schema.mse_field}.size"),
                AOS_SIZE_MARKER,
                0,
                (),
                values=(float(len(mse)),),
            )
        )
        records.append(
            leaf(
                mse[0].measured,
                slice_field(i, f"constraints/{schema.mse_field}[0]/measured"),
            )
        )

    return records


def read_and_hash(uri: str, schema: VersionSchema) -> int:
    return canonical_hash(read_back(uri, schema))


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Generate deterministic equilibrium-seed HDF5 fixtures with "
            "imas-python, one per DD version in DD_VERSIONS."
        )
    )
    parser.add_argument(
        "path",
        type=Path,
        help=(
            "Directory to create the per-DD-version HDF5 pulses in "
            "(a subdirectory per version, e.g. <path>/3.39.0, is created "
            "and overwritten if it exists)."
        ),
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Read each fixture back and check its structural hash matches expected_hash().",
    )
    args = parser.parse_args(argv)

    for dd_version, schema in SCHEMAS.items():
        version_path = args.path / dd_version
        if version_path.exists():
            shutil.rmtree(version_path)
        version_path.parent.mkdir(parents=True, exist_ok=True)

        uri = f"imas:hdf5?path={version_path}"
        write(uri, schema)
        print(
            f"wrote {IDS_NAME} fixture (DD {dd_version}) to {version_path} "
            f"(expected_hash=0x{expected_hash(schema):016x})"
        )

        if args.verify:
            observed_hash = read_and_hash(uri, schema)
            if observed_hash != expected_hash(schema):
                raise SystemExit(
                    f"DD {dd_version}: structural hash mismatch: "
                    f"expected 0x{expected_hash(schema):016x}, got 0x{observed_hash:016x}"
                )
            print(f"verify OK (DD {dd_version}): observed structural hash matches expected_hash()")


if __name__ == "__main__":
    main()
