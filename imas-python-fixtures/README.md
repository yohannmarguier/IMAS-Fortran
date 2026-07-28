# imas-python-fixtures

`equilibrium_seed.py` writes two `equilibrium` HDF5 fixtures with
[imas-python](https://github.com/iterorganization/IMAS-Python) — one in DD
**3.39.0**, one in DD **4.1.1** — built as a test pair for a DD 3 → DD 4
conversion program. The DD 4.1.1 fixture is the expected result of converting
the DD 3.39.0 one: same physical content, written to the renamed paths, with
the COCOS 11 → 17 sign flips applied.

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
`imas:hdf5?path=...` URI, overwritten if it exists). The generated output for
both versions is checked in under `fixtures/`.

## What the fixtures cover

Every field is there to exercise one class of DD 3 → DD 4 difference. The two
`fill_dd3` / `fill_dd4` functions in the script are line-for-line aligned, so
diffing them shows the whole conversion.

| DD 3.39.0 | DD 4.1.1 | What changes |
|---|---|---|
| `ids_properties/source` | `ids_properties/provenance/node/reference/name` | field removed, moved into a structure |
| `vacuum_toroidal_field/r0` | same | nothing (control) |
| `vacuum_toroidal_field/b0` | same | nothing, COCOS factor +1 (control) |
| `profiles_1d/psi` | same | sign flip (`psi_like`) |
| `profiles_1d/f_df_dpsi` | same | sign flip (`dodpsi_like`) + units restring `T^2.m^2/Wb` → `T^2.m^2.Wb^-1` |
| `global_quantities/ip` | same | sign flip (`ip_like`) |
| `constraints/ip/measured` | same | sign flip (`ip_like`) |
| `profiles_1d/j_tor` | `profiles_1d/j_phi` | rename + sign flip (`ip_like`) |
| `global_quantities/psi_axis` | `global_quantities/psi_magnetic_axis` | rename + sign flip (`psi_like`) |
| `global_quantities/beta_normal` | `global_quantities/beta_tor_norm` | rename only |
| `global_quantities/magnetic_axis/b_field_tor` | `…/b_field_phi` | rename only (COCOS factor +1) |
| `profiles_2d/b_field_tor` | `profiles_2d/b_field_phi` | rename only, 2D array |
| `constraints/bpol_probe` | `constraints/b_field_pol_probe` | AOS rename only |
| `constraints/strike_point/chi_squared_r` | same | units `m` → `m^-2`, value unchanged |

Paths are relative to `time_slice` unless noted. Two time slices are written,
with different values per slice, so a slice mix-up is visible.

Two traps worth knowing about, both encoded in the fixtures:

- `global_quantities/psi_axis` still **exists** in DD 4.1.1 but is marked
  `obsolescent`; the live node is `psi_magnetic_axis`. The DD 4 fixture leaves
  `psi_axis` empty — a converter that writes it instead is wrong.
- `profiles_2d/grid/dim1`/`dim2` are written in both versions because they are
  the coordinates of `b_field_tor`/`b_field_phi`; without them imas-python
  rejects the IDS on `put`.

The 11 → 17 COCOS sign flips and the renames were taken from the DD migration
guide for `equilibrium` (3.39.0 → 4.1.1), which lists 1279 actions for this IDS,
881 of them breaking: 32 sign flips plus 143 renames, the bulk of the latter
being mechanical `_tor` → `_phi` and `-isation` → `-ization` spelling changes.
