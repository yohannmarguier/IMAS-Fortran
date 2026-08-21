# playground

Scratch programs run against an **installed** al-fortran. `CMakeLists.txt` here
is a project of its own: it links a prefix rather than building one, so it is
deliberately not part of the main build and refuses to be `add_subdirectory`'d
into it.

```
cmake -B build -S .                        # defaults to ../install-shim
cmake --build build
ctest --test-dir build --output-on-failure
```

## play_eq_two_dd

Reads both `equilibrium` fixtures from `../imas-python-fixtures/fixtures` and
prints one table row per path: the DD 4.1.1 value, the DD 3.39.0 value, and what
the shim did to get the second one.

`run.sh` configures, builds and runs it in one step:

```
./run.sh                    # cross-version: full table, PARTIAL_READ
./run.sh dd-4.1.1 dd-4.1.1  # self-test: 170 rows, all "same", 0 skipped
```

The same two runs exist as tests, so `ctest` covers them without the wrapper:
`play_eq_two_dd-self` and `play_eq_two_dd-cross`.

## Current state

The cross-version read completes. The shim correctly refuses
`grids_ggd/grid/space/coordinates_type`, and the generated HLI now treats that
refusal as what it is -- a path that does not exist in the dictionary this HLI
speaks -- rather than as an error. The field is left disassociated, the path is
recorded in `al_get_policy`'s skip log, and the read carries on to `time_slice`.
`ids_get` reports `PARTIAL_READ` so the caller knows the IDS is incomplete.

Getting here took two fixes and one decision, all in
**[FINDINGS.md](FINDINGS.md)**: the refusal used to end one context twice, which
was a memory fault; then it aborted the whole read, which was clean but produced
no table; and then "must a refusal stop the read?" was answered no.

`./run.sh dd-4.1.1 dd-4.1.1` remains the check on the table logic itself: one
pulse in both columns must report `same` on every row and skip nothing, which
proves the table independently of any conversion.

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

Both variables the shim needs are injected into the ctest environment, and
exported by `run.sh` for a by-hand run, since neither has a usable default from
a build tree:

- `IMAS_CORE_LIBRARY` — which real IMAS-Core the shim `dlopen`s. Defaults to the
  one under `../cmake-build-debug/_deps/al-core-build`.
- `IMAS_MVDD_HLI_DD_VERSION` — the dictionary the calling HLI speaks, `4.1.1`
  here. The shim latches this **once per process** and compares each opened
  entry's stamp against it, so one process can read both pulses: the 4.1.1 one
  passes through, the 3.39.0 one converts.

Configure them as `IMAS_CORE_LIBRARY` and `PLAYGROUND_DD_VERSION`, or export
them for `run.sh`, which forwards them. The two prefixes are `AL_FORTRAN_PREFIX`
and `IMAS_MVDD_LOADER_PREFIX` (`PREFIX` and `SHIM` in `run.sh`).

The build refuses to proceed if `AL_FORTRAN_PREFIX`'s al-fortran does not
actually link `libimas_mvdd_loader` — a build that linked IMAS-Core directly
would compile and run fine and simply never convert anything, which is exactly
the failure `docs/adr/0001-multiversion-shim-linkage.md` warns about. The check
is `cmake/CheckShimLinkage.cmake`, run at configure time and again as the
`shim-linkage` test, because the prefix can be reinstalled in between.
