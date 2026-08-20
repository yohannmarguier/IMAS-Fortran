# playground

Scratch programs run against an **installed** al-fortran, outside the CMake
build. Nothing here is a ctest test; nothing here is built by the main build.

## play_eq_two_dd

Reads both `equilibrium` fixtures from `../imas-python-fixtures/fixtures` and
prints one table row per path: the DD 4.1.1 value, the DD 3.39.0 value, and what
the shim did to get the second one.

```
./run.sh                    # cross-version: dies in the HLI, see below
./run.sh dd-4.1.1 dd-4.1.1  # self-test: 170 rows, all "same"
```

## Current state

The cross-version read does not complete. The shim correctly refuses
`grids_ggd/grid/space/coordinates_type`, and the generated HLI mishandles that
refusal by ending one context twice, which is a memory fault. `grids_ggd`
precedes `time_slice`, so the read dies before any table data exists.

That defect is the point of the exercise, not an obstacle to it: it is what a
shim-linked read shows about this repository. **[FINDINGS.md](FINDINGS.md)** has
the diagnosis, the generator site, and the scope. Nothing is fixed.

Until it is, `./run.sh dd-4.1.1 dd-4.1.1` is what exercises the table: one pulse
in both columns must report `same` on every row, which proves the table logic
independently of any conversion.

The program is compiled against **one** dictionary — the DD 4.1.1 al-fortran in
`../install-shim` — so both pulses are read into the same DD 4.1.1 derived type.
That is the whole demonstration: the 3.39.0 pulse is a *different* dictionary,
and the shim converts it on the way in. It discovers the stored version from the
occurrence's own `ids_properties/version_put/data_dictionary` stamp, translates
the paths `al_read_data` asks for, applies the COCOS 11 → 17 sign flips, and
refuses the paths its map declares unservable.

Verdict column:

| | |
|---|---|
| `same` | both dictionaries gave the same number |
| `FLIP` | equal up to sign — a COCOS 11 → 17 flip |
| `DIFF` | both present, and they disagree |
| `only4` | 4.1.1 has it, the 3.39.0 read produced nothing |
| `only3` | the 3.39.0 read produced it, 4.1.1 has nothing |
| `SHAPE` | both present, different extents |
| `--` | neither side has it |

Arrays print element 1 as a sample, with their extent in the path column. The
verdict is computed over the **whole** array, not over the printed sample, so a
`same` on a `[65]` row means all 65 agreed.

### Coverage, stated honestly

The table is not all 486 leaves of the IDS. It is every scalar and array leaf
reachable without descending into a nested array of structures, plus a first
element of each AOS that the conversion map has a rule for — about 170 rows,
covering every category in `../imas-python-fixtures/README.md`: renames, folds,
the `psi_axis` split, the moved `boundary_separatrix` children, DD-4-only
`contour_tree`, the dropped `coordinate_system/g_ij`, and the `chi_squared_r/z`
unit redefinition the map refuses.

What it does **not** enumerate: the interior of the GGD grid description
(`grids_ggd/grid/space/objects_per_dimension/object/...`), which is many levels
of nested AOS, and elements beyond the first of every AOS. A row there needs a
loop nest per path, and Fortran cannot name a component indirectly, so covering
them exhaustively means generating this file from `IDSDef.xml` rather than
writing it — the same trick `IDSDef2F90Routines.xsl` already plays for the
library. If the full 486 matter, that is the way to get them, not a longer
hand-written list.

### Environment

`run.sh` sets both variables the shim needs, since neither has a usable default
from a build tree:

- `IMAS_CORE_LIBRARY` — which real IMAS-Core the shim `dlopen`s. Defaults to the
  one under `../cmake-build-debug/_deps/al-core-build`.
- `IMAS_MVDD_HLI_DD_VERSION` — the dictionary the calling HLI speaks, `4.1.1`
  here. The shim latches this **once per process** and compares each opened
  entry's stamp against it, so one process can read both pulses: the 4.1.1 one
  passes through, the 3.39.0 one converts.

Override either by exporting it before running. `PREFIX` and `SHIM` point at the
al-fortran install and the loader install respectively.

`run.sh` refuses to run if `$PREFIX`'s al-fortran does not actually link
`libimas_mvdd_loader` — a build that linked IMAS-Core directly would compile and
run fine and simply never convert anything, which is exactly the failure
`docs/adr/0001-multiversion-shim-linkage.md` warns about.
