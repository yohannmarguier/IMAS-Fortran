"""Deterministic equilibrium-seed HDF5 fixture, generated with imas-python.

Python mirror of IMAS-Core/fixtures/equilibrium_seed.h: same IDS, same
DD-4.1.1 paths, same deterministic arithmetic progressions per role/slice, and
the same FNV-1a structural hash (ints/doubles packed little-endian to match
the C++ struct layout) -- a fixture written here and one written by the C++
generator hash identically. Change a generator function on either side and
both the records and the hash recompute; keep the two generators in sync by
hand, there is no shared source of truth between the repos.

Shape:
  - vacuum_toroidal_field/r0  (FLT_0D)              -- static scalar
  - time                      (FLT_1D)               -- homogeneous timebase
  - time_slice                (struct_array, timebasepath "time"), each with:
      * time                       (FLT_0D)
      * profiles_1d/psi            (FLT_1D)
      * global_quantities/ip       (FLT_0D)
      * constraints/ip/measured    (FLT_0D)
      * constraints/ip/weight      (FLT_0D)
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
from imas_core.imasdef import DOUBLE_DATA

IDS_NAME = "equilibrium"
SCALAR = "vacuum_toroidal_field/r0"
AOS = "time_slice"

N_SLICES = 2  # time_slice AOS elements (>1: a real AOS)
RADIAL_LEN = 4  # profiles_1d/psi grid points per slice

# Marker for the synthetic AOS-size record, so array size participates in the
# hash (never a real Access Layer datatype).
AOS_SIZE_MARKER = -1


# --- deterministic content ---------------------------------------------------
# Distinct arithmetic progressions per role and per slice, so a transposed,
# dropped, or reordered element is caught by the structural hash.
def scalar_r0() -> float:
    return 6.2


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


# --- a single observed/expected field record ---------------------------------
@dataclass(frozen=True)
class Obs:
    field: str  # canonical identity, e.g. "time_slice[1]/profiles_1d/psi"
    datatype: int  # DOUBLE_DATA, or AOS_SIZE_MARKER
    rank: int
    extents: tuple[int, ...]  # actual dims (empty for rank 0)
    values: tuple[float, ...]

    def same_structure(self, other: "Obs") -> bool:
        return (
            self.field == other.field
            and self.datatype == other.datatype
            and self.rank == other.rank
            and self.extents == other.extents
        )


def slice_field(i: int, leaf: str) -> str:
    return f"{AOS}[{i}]/{leaf}"


def expected_records() -> list[Obs]:
    records = [
        Obs(SCALAR, DOUBLE_DATA, 0, (), (scalar_r0(),)),
        Obs("time", DOUBLE_DATA, 1, (N_SLICES,), tuple(timebase_values())),
        Obs(f"{AOS}.size", AOS_SIZE_MARKER, 0, (), (float(N_SLICES),)),
    ]
    for i in range(N_SLICES):
        records.append(
            Obs(slice_field(i, "time"), DOUBLE_DATA, 0, (), (slice_time(i),))
        )
        records.append(
            Obs(
                slice_field(i, "profiles_1d/psi"),
                DOUBLE_DATA,
                1,
                (RADIAL_LEN,),
                tuple(slice_psi(i)),
            )
        )
        records.append(
            Obs(
                slice_field(i, "global_quantities/ip"),
                DOUBLE_DATA,
                0,
                (),
                (slice_ip(i),),
            )
        )
        records.append(
            Obs(
                slice_field(i, "constraints/ip/measured"),
                DOUBLE_DATA,
                0,
                (),
                (slice_measured(i),),
            )
        )
        records.append(
            Obs(
                slice_field(i, "constraints/ip/weight"),
                DOUBLE_DATA,
                0,
                (),
                (slice_weight(i),),
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
        h = _fnv1a_int(h, len(r.values))
        for v in r.values:
            h = _fnv1a_double(h, v)
    return h


def expected_hash() -> int:
    return canonical_hash(expected_records())


# --- write the seed into a fresh HDF5 pulse ----------------------------------
def write(uri: str) -> None:
    entry = imas.DBEntry(uri, "w")
    try:
        eq = entry.factory.new(IDS_NAME)
        eq.ids_properties.homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
        eq.ids_properties.comment = "equilibrium_seed fixture (imas-python-fixtures)"

        eq.vacuum_toroidal_field.r0 = scalar_r0()
        eq.time = timebase_values()

        eq.time_slice.resize(N_SLICES)
        for i in range(N_SLICES):
            ts = eq.time_slice[i]
            ts.time = slice_time(i)
            ts.profiles_1d.psi = slice_psi(i)
            ts.global_quantities.ip = slice_ip(i)
            ts.constraints.ip.measured = slice_measured(i)
            ts.constraints.ip.weight = slice_weight(i)

        entry.put(eq)
    finally:
        entry.close()


# --- read the seed back, rebuilding the observed canonical stream -----------
# Records exactly what the backend returned (real rank/extents/AOS size), so
# shape drift on read surfaces as a hash mismatch instead of silent
# reconciliation -- no assertions here, callers compare against
# expected_records()/expected_hash().
def read_back(uri: str) -> list[Obs]:
    entry = imas.DBEntry(uri, "r")
    try:
        eq = entry.get(IDS_NAME)
    finally:
        entry.close()

    def leaf(value, field_name: str) -> Obs:
        arr = np.asarray(value, dtype=float)
        return Obs(field_name, DOUBLE_DATA, arr.ndim, tuple(arr.shape), tuple(arr.flatten().tolist()))

    records = [
        leaf(eq.vacuum_toroidal_field.r0, SCALAR),
        leaf(eq.time, "time"),
    ]

    size = len(eq.time_slice)
    records.append(Obs(f"{AOS}.size", AOS_SIZE_MARKER, 0, (), (float(size),)))

    for i in range(size):
        ts = eq.time_slice[i]
        records.append(leaf(ts.time, slice_field(i, "time")))
        records.append(leaf(ts.profiles_1d.psi, slice_field(i, "profiles_1d/psi")))
        records.append(leaf(ts.global_quantities.ip, slice_field(i, "global_quantities/ip")))
        records.append(leaf(ts.constraints.ip.measured, slice_field(i, "constraints/ip/measured")))
        records.append(leaf(ts.constraints.ip.weight, slice_field(i, "constraints/ip/weight")))

    return records


def read_and_hash(uri: str) -> int:
    return canonical_hash(read_back(uri))


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        description="Generate the deterministic equilibrium-seed HDF5 fixture with imas-python."
    )
    parser.add_argument(
        "path",
        type=Path,
        help="Directory to create the HDF5 pulse in (overwritten if it exists).",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Read the fixture back and check its structural hash matches expected_hash().",
    )
    args = parser.parse_args(argv)

    if args.path.exists():
        shutil.rmtree(args.path)
    args.path.parent.mkdir(parents=True, exist_ok=True)

    uri = f"imas:hdf5?path={args.path}"
    write(uri)
    print(f"wrote {IDS_NAME} fixture to {args.path} (expected_hash=0x{expected_hash():016x})")

    if args.verify:
        observed_hash = read_and_hash(uri)
        if observed_hash != expected_hash():
            raise SystemExit(
                f"structural hash mismatch: expected 0x{expected_hash():016x}, got 0x{observed_hash:016x}"
            )
        print("verify OK: observed structural hash matches expected_hash()")


if __name__ == "__main__":
    main()
