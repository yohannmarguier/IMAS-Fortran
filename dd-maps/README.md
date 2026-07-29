# DD conversion maps

Machine-readable maps describing how one IDS differs between two Data Dictionary
versions, in a form a bidirectional conversion engine can execute directly.

Prototype scope: **equilibrium, DD 3.39.0 ↔ 4.1.1**. The format is designed for
all 84 IDSs and all 35 DD versions; see [Scaling](#scaling) for how that works
without an O(n²) explosion of files.

```
dd-maps/
  schema/ids-map.xsd              grammar + closed vocabularies
  common/                         rule sets shared by every IDS
    error-model-3to4.xml          DD4 dropped the per-node error triplet
    naming-3to4.xml               spelling and component renames
  equilibrium/
    3.39.0--4.1.1.xml             the map
  inventory/                      path lists per (IDS, version), from imas-dd
  validate.py                     grammar + coverage + consistency checks
```

```bash
python3 dd-maps/validate.py dd-maps/equilibrium/3.39.0--4.1.1.xml
python3 dd-maps/validate.py dd-maps/equilibrium/3.39.0--4.1.1.xml --write-coverage
```

## Why XML

The whole repo is an XSLT pipeline over `IDSDef.xml` driven by `saxonche`. If the
conversion engine is generated Fortran — a stylesheet alongside
`IDSDef2F90Routines.xsl` — then a map in XML is consumable with zero new
dependencies: `document()` reads it, and `xsl:key` indexes it for O(1) lookup in
both directions (one key on `@left`, one on `@right`). An XSD also gives real
enforcement of the closed vocabularies, checked by `xmllint`, which is already
present.

## The three axes

A rule answers three independent questions. Keeping them separate is what makes
the map easy for an engine to consume.

| Axis | Where it lives | Values |
|---|---|---|
| **Structure** — where does the value go? | `<rule rel="…">` | `identical`, `renamed`, `moved`, `merged`, `split`, `retyped`, `redefined`, `left_only`, `right_only` |
| **Value** — how does the number change? | `<transforms>` | `<cocos><flip>`, `<scale factor="…">`, `<redefine>` |
| **Fidelity** — can it be trusted? | `<fidelity forward reverse>` | `exact`, `approximate`, `lossy`, `unmappable` |

Transforms are keyed on the **right-side** path, so a structural rule and a
transform never compete to claim the same path.

## Direction neutrality

The two versions are `left` and `right`, never `from`/`to`, and the `rel`
vocabulary names relationships rather than actions. One document therefore drives
both directions; the engine derives the action from `rel` + direction:

| `rel` | left → right | right → left |
|---|---|---|
| `identical` | copy | copy |
| `renamed` / `moved` | relocate | relocate back |
| `merged` | n→1, by `<from precedence>` | 1→n, highest precedence only |
| `split` | 1→n | n→1 |
| `retyped` | change container | change back |
| `left_only` | drop | cannot synthesise |
| `right_only` | cannot synthesise | drop |

`fidelity` is stated **per direction** because asymmetry is the norm, and it is
the notification channel: anything other than `exact` means the engine must warn,
and `unmappable` means it must refuse that path rather than guess.

The engine loop is then trivial:

```
rule = lookup(path, direction)
if rule.fidelity[direction] == "unmappable":  report, skip
apply rule.rel using the transform for the right-side path
if rule.fidelity[direction] != "exact":       warn
```

## Coverage

`<coverage>` is **generated** by `validate.py --write-coverage`, never
hand-edited — a hand-typed summary drifts from the rules it summarises and the
engine would then trust a stale promise. It reports the worst fidelity per
subtree at depth 1 and 2, so a caller can convert `profiles_1d` cleanly while
refusing only `boundary`, instead of being told the whole IDS is lossy.

`validate.py` proves that **every** path in both inventories is claimed by
exactly one rule. Rules may overlap textually; the most specific (longest
matched prefix) wins, and a genuine tie is an error. Paths present in both
versions and unclaimed fall through to `<default rel="identical"/>`.

Current state for equilibrium: 53 rules (7 from includes) covering 585 left and
455 right paths, 32 COCOS sign flips, 4 redefinitions. Two rules are flagged
`decision="yes"` and need a physicist — `validate.py` prints them.

## What the imas-dd MCP server does and does not give you

The map was derived from the MCP path sets, not from its migration guide. The
guide is a grep recipe for humans, and using it directly would corrupt data:

- It reports **0 renames and 0 additions** for equilibrium, emitting 834
  `path_removed` entries instead. Real renames arrive as unpaired removals.
- Its removal set **mixes both namespaces**: `constraints/j_tor/measured` (a DD3
  name, gone by folding) sits beside `constraints/j_phi/measured_error_index` (a
  DD4 name, gone by the error-model change). A consumer assuming "removed ⇒ DD3
  path" gets it wrong.
- 630 of those 834 are the error triplet — one decision, not 630 facts.
- It lists `profiles_{1d,2d}/psi` **twice**, as both `cocos_sign_flip` and
  `definition_change (sign_convention)`. Applying both flips the sign twice. The
  XSD `uniqueFlip` constraint and `validate.py` both guard against this.
- Its 12 `unit_change` entries are **m → m⁻²** on `constraints/{strike_point,
  x_point}/chi_squared_{r,z}`. That is a dimensional redefinition (chi-squared
  normalised by variance), not a rescale — no factor inverts it. They are
  `<redefine>` with `unmappable` both ways, not `<scale>`.

Deriving instead from the path sets gives the honest picture: 399 identical,
186 left-only, 56 right-only.

One structural finding worth knowing: **DD 3.39.0 is a transitional version that
ships old and new names side by side** (`j_tor` *and* `j_phi`, `b_tor` *and*
`b_field_tor` *and* `b_field_phi`), with the old marked obsolescent. So these are
not renames in this step — they are **merges**, lossy forward whenever both DD3
names hold different values.

The inventories under `inventory/` come from the MCP server, which excludes error
metadata and `ids_properties`/`code` subtrees. The `error-model-3to4.xml` rules
therefore cannot be checked against them; they are carried for the engine, which
does see those nodes in real data.

## Scaling

Direct pair maps are O(n²): 595 version pairs × 84 IDSs ≈ 50,000 files. The DD
version chain is linear (3.22.0 → … → 4.1.1, 34 steps), so the scalable form is
one map per **adjacent step** per IDS, composed on demand. Two properties of this
format keep that door open:

1. **Versions are data**, declared in `<side>`. Nothing in the XSD, the
   validator, or a future engine hard-codes 3.39.0 or 4.1.1.
2. **Rules are stateless and independently applicable**, so composition folds
   them pairwise: `renamed ∘ renamed = renamed`, `scale ∘ scale =
   scale(product)`, and `anything ∘ lossy = lossy`. Fidelity degradation
   propagates automatically — the worst link sets the verdict for the chain.

`common/` is what makes the per-IDS files small: the error-model change alone
accounts for 630 of equilibrium's removals and applies to all 84 IDSs, so it is
written once and included, not copied 84 times.

The composer itself is deliberately **not** built yet — a prototype covering one
version pair does not need it, and building it now would be guessing at
requirements the second and third maps will reveal.
