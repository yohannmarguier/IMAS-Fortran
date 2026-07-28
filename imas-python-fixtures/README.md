# imas-python-fixtures

Deterministic IDS fixtures generated with [imas-python](https://github.com/iterorganization/IMAS-Python)
instead of the raw Access Layer. `equilibrium_seed.py` is the Python
counterpart of `IMAS-Core/fixtures/equilibrium_seed.h`: same IDS, same
DD-4.1.1 paths, same deterministic values, same FNV-1a structural hash, so a
fixture produced by either generator hashes identically.

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

This creates an HDF5 pulse (an `imas:hdf5?path=...` URI) at the given
directory containing a single `equilibrium` IDS with:

- `vacuum_toroidal_field/r0` — static scalar
- `time` — homogeneous timebase
- `time_slice` — a 2-element AOS, each with `profiles_1d/psi`,
  `global_quantities/ip`, `constraints/ip/measured`, `constraints/ip/weight`

`--verify` reads the fixture back and checks the observed structural hash
against `expected_hash()`.

Programmatic use:

```python
import equilibrium_seed as seed

seed.write("imas:hdf5?path=./testdb")
assert seed.read_and_hash("imas:hdf5?path=./testdb") == seed.expected_hash()
```
