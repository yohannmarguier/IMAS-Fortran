# imas-python-fixtures

Deterministic IDS fixtures generated with [imas-python](https://github.com/iterorganization/IMAS-Python)
instead of the raw Access Layer. `equilibrium_seed.py` writes the same
`equilibrium` IDS content under two DD versions — 3.39.0 and 4.1.1 — chosen to
straddle DD 4.0.0's restructuring so the pair of fixtures covers every kind of
path difference a DD-version migration can introduce: a rename (`j_tor` ->
`j_phi`, `b_field_tor` -> `b_field_phi`), a spelling rename
(`mse_polarisation_angle` -> `mse_polarization_angle`), a removal
(`ids_properties/source`, DD 3.39.0 only), and an addition
(`global_quantities/rho_tor_boundary`, DD 4.1.1 only). Everything else is
written identically across both versions.

## Setup

```
pip install -r requirements.txt
```

`imas` must be importable (`python -c "import imas"`) before running the
generator; it pulls in `imas_core` and the Data Dictionary as dependencies.

## Usage

```
python equilibrium_seed.py /path/to/pulse-dir
python equilibrium_seed.py /path/to/pulse-dir --verify
```

This creates one HDF5 pulse per DD version (an `imas:hdf5?path=...` URI) in
`<pulse-dir>/3.39.0` and `<pulse-dir>/4.1.1`, each containing a single
`equilibrium` IDS with:

- `vacuum_toroidal_field/r0` — static scalar
- `ids_properties/source` — DD 3.39.0 only
- `time` — homogeneous timebase
- `time_slice` — a 2-element AOS, each with `profiles_1d/psi`,
  `profiles_1d/{j_tor,j_phi}`, `global_quantities/ip`,
  `global_quantities/magnetic_axis/{b_field_tor,b_field_phi}`,
  `global_quantities/rho_tor_boundary` (DD 4.1.1 only),
  `constraints/ip/measured`, `constraints/ip/weight`,
  `constraints/{mse_polarisation_angle,mse_polarization_angle}[0]/measured`

`--verify` reads each fixture back and checks its observed structural hash
against `expected_hash()`.

Programmatic use:

```python
import equilibrium_seed as seed

for dd_version, schema in seed.SCHEMAS.items():
    uri = f"imas:hdf5?path=./testdb/{dd_version}"
    seed.write(uri, schema)
    assert seed.read_and_hash(uri, schema) == seed.expected_hash(schema)
```
