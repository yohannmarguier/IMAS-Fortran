# imas-python-fixtures

`equilibrium_seed.py` writes a minimal `equilibrium` HDF5 fixture with
[imas-python](https://github.com/iterorganization/IMAS-Python), once per Data
Dictionary version in `DD_VERSIONS` (currently 3.39.0 and 4.1.1).

## Setup

```
pip install -r requirements.txt
```

`imas` must be importable (`python -c "import imas"`); it pulls in `imas_core`
and the Data Dictionary as dependencies.

## Usage

```
python equilibrium_seed.py [output-dir]   # default: fixtures
```

One HDF5 pulse per version is created in `<output-dir>/dd-<version>` (an
`imas:hdf5?path=...` URI, overwritten if it exists), each holding a single
`equilibrium` IDS with:

- `vacuum_toroidal_field/r0` — static scalar
- `time` — homogeneous timebase
- `time_slice` — a 2-element AOS, each with `time`, `profiles_1d/psi`,
  `global_quantities/ip`, `constraints/ip/measured`, `constraints/ip/weight`

All those paths exist in both DD 3 and DD 4, so the content is identical
between the two fixtures; only the DD version stamped into the pulse differs.
The generated output for both versions is checked in under `fixtures/`.
