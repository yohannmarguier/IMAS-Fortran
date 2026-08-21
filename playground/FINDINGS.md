# What a shim-linked read shows about IMAS-Fortran

Running `play_eq_two_dd` against the two fixtures surfaces one defect in this
repository. The defect is in generated code, so the fix belongs in
`IDSDef2F90Routines.xsl`, not in any `.f90`.

**Status (2026-08-21): the memory fault described below is fixed** in
`IDSDef2F90Routines.xsl`, on the read *and* write paths; see "What was changed".
The *policy* question at the end is **also answered now**: a refused path is left
unset and the read continues, so a cross-version read produces a table and
reports `PARTIAL_READ`. See "What the fix had to decide".

The sections below are kept in the present tense as a description of the defect,
because they are what the fix has to be read against.

## The trigger

The shim serves a read of the DD 3.39.0 fixture to an HLI whose **HLI DD
version** is 4.1.1. For one DD path it issues a **refusal**:

```
IMAS-MVDD: this path's container changed shape and cannot be served;
DD path: grids_ggd/grid/space/coordinates_type;
HLI DD version: 4.1.1; stored DD version: 3.39.0
```

The refusal is correct. `coordinates_type` is `INT_1D` in DD 3.39.0 and an array
of identifier structures in DD 4.1.1. No **value transformation** converts one
into the other, so the **conversion-map artifact** declares the path unservable.

This is the first thing that routinely makes `al_begin_arraystruct_action`
return a non-zero status. Against a same-version pulse that call does not fail,
so the failure arm below has had no real exercise until now.

## The defect

Generator site: `IDSDef2F90Routines.xsl:4932-4937`.

```xslt
          else
             write(*,*) "ERROR! with field "//<xsl:value-of select="$fieldpath"/>
             <xsl:if test="$structvar='IDS'">if (present(retstatus)) </xsl:if>retstatus = aosctx
             call al_end_action(<xsl:value-of select="$contextvar"/>, status)
             return
          endif
```

Two things are wrong in that arm.

**1. It returns a context identifier as a status.** `aosctx` is an *output* of
the `al_begin_arraystruct_action` that just failed, so it holds no defined
value. It must return `status`.

There is a second-order effect worth noting. The garbage value is what makes the
caller's `isErrorCritical` fire. If `aosctx` happened to hold `0`, the caller
would treat the refusal as success and continue with an unallocated array —
a silent wrong answer instead of a loud one.

**2. It ends a context it does not own.** `$contextvar` is the *enclosing*
context, not `aosctx`. The failed begin created no context, so there is nothing
to end; ending the enclosing one destroys a context the caller still holds.

## Why that becomes a memory fault

The two arms interact. Concretely, for `coordinates_type` inside `space`:

```
callee  (space struct getter, its own context is ctx)
  al_begin_arraystruct_action(ctx, "coordinates_type", ...)   -> fails
  else arm:  al_end_action(ctx, status)        <-- closes the caller's context
             retstatus = aosctx               <-- undefined, non-zero
             return

caller  (grid/space arraystruct loop, same context, named aosctx here)
  if (isErrorCritical(status, aosctx, path//"space")) then
     retstatus = status
     call al_end_action(aosctx, status)       <-- closes the SAME context again
     return
```

The observed output matches that order exactly:

```
IMAS-MVDD: this path's container changed shape and cannot be served; ...
 ERROR! with field coordinates_type
 ERROR! with field 'space'
Program received signal SIGSEGV: Segmentation fault
```

`isErrorCritical` (`IDSDef2F90Routines.xsl:5450-5465`) is pure reporting — it
accepts a context argument and ignores it. Every `al_end_action` in the chain
comes from the emitted code around it.

## Scope

One generator site produces the pattern **1115 times across 157 generated
files**; **667** of those are followed by `al_end_action(ctx, ...)`. The rest sit
at IDS level, where `$structvar='IDS'` guards the assignment with
`if (present(retstatus))`. Every arraystruct read in every IDS carries it.

## Why it blocks the whole table

`grids_ggd` precedes `time_slice` in the `equilibrium` IDS. The failure arm
returns immediately, so the read stops before any `time_slice` data is read.
`ids_get_slice` follows the same path and gives the same result — there is no
way around it through the HLI API.

## What was changed

One generator site, the `else` arm above.

**`retstatus = aosctx` became `retstatus = status`**, at all 1115 sites.

**The `al_end_action` is now emitted only when `$structvar='IDS'`.** That test is
exactly the "does this routine own the enclosing context" predicate, which is why
the split is clean rather than a heuristic:

| | routine | `$contextvar` | owner | close |
|---|---|---|---|---|
| 448 sites | `$structvar='IDS'` | `opctx` | opened by `al_begin_global_action` in *this* routine, closed by it on success | **kept** — dropping it would leak the operation context |
| 667 sites | `$structvar='struct'` | `ctx` | a dummy argument; the caller ends it in its own `isErrorCritical` arm | **removed** — this was the double-close |

Measured on the generated tree, that predicate never disagrees with the variable
name: every `present(retstatus)` arm closes `opctx`, every other arm closes `ctx`.
Note that per-IDS `<ids>_get.f90` files contain *both* kinds of routine, so "root"
means the `$structvar` test, not the file.

Verified against a full-DD shim build (DD 4.1.1, gfortran 15.2, Debug):

- cross-version read: **exit 139 (SIGSEGV) before, exit 1 after**
- same-version control: exit 0, 428 rows, unchanged
- `ctest`: 85/85 pass. This shows *no regression*; it does not exercise the arm,
  since a same-version round trip never makes `al_begin_arraystruct_action` fail.
  The guard for the arm itself is `playground-play_eq_two_dd-cross`, which is no
  longer `DISABLED` and now fails only on a signal (`check_no_signal.cmake`).

### The write path, fixed the same way

The `PUT_FIELD` template had the same shape at `IDSDef2F90Routines.xsl:4379`:

```xslt
       else
          write(*,*) "ERROR! with field "//<xsl:value-of select="$fieldpath"/>
          call al_end_action(<xsl:value-of select="$contextvar"/>, status)
          return
       endif
```

Same failed begin, same close of a context the routine may not own: **1254 nested
sites** (243 of them in `utilities_put_struct.f90`, the rest in the nested
`put_struct_ids_<ids>_*(ctx, ...)` routines inside the per-IDS `<ids>_put.f90`
files), against **277** IDS-level sites where `opctx` is owned and the close is
kept.

The write arm carried a *second* defect the read arm did not. It never assigned
`retstatus` at all, and a caller passes its own `status` variable as that
argument:

```fortran
call put_struct_ids_equilibrium_tim724(aosctx, name, '', IDS%time_slice(i), &
                                       timemode, timedparent.or..true., status)
if (isErrorCritical(status, aosctx, path//"time_slice")) then
```

So a failed arraystruct put returned with the caller's `status` still holding its
previous value -- normally `0` -- and `isErrorCritical` did not fire: the write
failed and the caller carried on as though it had succeeded. Silent data loss on
the write path, where the read path was merely loud and wrong. Both arms now
assign `retstatus = status`, which is what `b920619` ("Add missing error
propagation for some AoS cases") set out to do and applied only to `GET_FIELD`.

Unlike the read fix this one has no behavioural red/green here, because nothing
in this repository makes an arraystruct *write* fail -- the playground only reads.
It is verified by inspecting the generated code and by the suite not regressing
(85/85), which also shows no existing test depended on a swallowed put error.

## What the fix had to decide -- decided: best effort

Correcting the two defects above stops the memory fault and yields a clean
error. It does **not** produce a table: the read still aborted at `grids_ggd`, so
every `time_slice` path stayed empty. The refusal propagated outward one level at
a time, each routine ending only its own context:

```
IMAS-MVDD: this path's container changed shape and cannot be served; ...
 ERROR! with field coordinates_type
 ERROR! with field 'space'
 ERROR! with field 'grid'
 ERROR! with field 'grids_ggd'
ERROR: a pulse came back with no time_slice          <- play_eq_two_dd, exit 1
```

So the open question was: **must a refusal stop the whole read?** It now does
not. A refused path is left unset and the read continues.

### Why a refusal is not an error

The refused path does not exist in the dictionary this HLI speaks. No retry
produces it, no backend holds it, and the conversion map has already decided it
is unservable. Aborting therefore buys nothing and costs every remaining field
in the IDS -- here, all of `time_slice`, because `grids_ggd` happens to come
first. Continuing is strictly more useful, and the field is left in exactly the
state an absent field would be in.

### Why this is decidable rather than a guess

The conversion layer answers a refusal with `IMAS_MVDD_CONVERSION_ERROR = -1000`,
inside a band `-1000..-1099` it reserves. IMAS-Core's entire error family is
`-1..-5` (`wrapper/al_defs.f90`). The two cannot collide, so "tolerate a refusal,
never tolerate an I/O error" is a test, not a heuristic -- and **a build that
links IMAS-Core directly can never produce a tolerable status**, which is why
this needs no opt-in switch and changes nothing for an existing user.

### Where the decision is applied, and where it must not be

Tolerance lives at exactly two generator sites, both per-field:

- `isCriticalFuncCtx` -- but only the `utilities_get_struct` emission. Every leaf
  read and every nested struct/AoS-element call in the read path funnels through
  the resulting `isErrorCritical`, and all 82 IDSs inherit it through
  `use utilities_get_struct`. The `put` and `put_slice` emissions are unchanged:
  a swallowed write is silent data loss, which is a different and worse thing
  than a partial read.
- the `else` arm of `al_begin_arraystruct_action` in `mode="GET_FIELD"`, the one
  path that does not reach `isErrorCritical` on its own. It now calls it.

**Node locality is the invariant.** The same `-1000` comes back from
`al_begin_global_action` and the data-entry seams, for a malformed version stamp
or a version-latch conflict. Tolerating one of those would sail past an IDS that
was never opened and report success over an empty structure. The band test must
never be moved to those sites.

Both halves had to ship together. Tolerating at a leaf while the enclosing
routine still aborts only moves the truncation up one level: `space` would
survive `coordinates_type` but never reach `objects_per_dimension`.

### What the caller is told

- `ids_get`, `ids_get_slice` and `ids_get_sample` return **`PARTIAL_READ`** (`1`,
  in `al_defs`) when the read completed but left something unset. Positive, so it
  can never be confused with a C-ABI status, and still non-zero, so a caller
  already writing `if (status /= 0)` notices. A caller testing `status < 0` will
  not -- that is the one behaviour change to be aware of.
- **`al_get_policy`** holds a per-operation skip log: `al_get_skipped_count()`,
  `al_get_skipped_path(i, path, code, message, found)`,
  `al_report_skipped_paths(unit)`. It is reset at the start of each GET, so read
  it before issuing the next one. The `message` is the conversion layer's own
  explanation, retained by `fstatus` -- which is why `fstatus` is no longer
  `pure`.
- Each skip also prints a `SKIPPED:` line.

Two hazards this creates, both documented rather than solved:

- A skipped array is left **disassociated**, not empty. Every array component is
  `pointer :: x(:) => null()`, so consumers must test `associated()`. That is
  byte-for-byte what an absent path looks like, which is the point.
- **Reusing an IDS is now dangerous.** Passing an `ids_equilibrium` that a
  previous `ids_get` filled and never `ids_deallocate`'d leaves *stale* pointers,
  not null ones, so a skipped subtree reads back as previously-fetched data.
  `set_c_data(IDS,.true.)` only flips a flag. The skip log is what lets a caller
  tell the difference.
- The log is process-global and not thread-safe. So is the generated code
  already: the IDS-level routines declare `integer(ids_int) :: status = 0`, whose
  initialiser implies `SAVE`. The contract is one GET at a time per process.

### One new failure mode, handled

`al_iterate_over_arraystruct`'s status was never checked. That was harmless only
because a failed element returned immediately, so a second iteration was
unreachable. Now that a refused element is tolerated, the loop really does run to
`aoslen`, and a wedged cursor would be iterated against silently on every
remaining turn. It is now checked, and treated as **fatal** -- advancing the
cursor is the loop, not one field, so it is not node-local.

### What best effort uncovered: an uninitialised extent in the wrapper

Tolerating the first refusal is what made the next defect reachable. With the
read no longer stopping at `grids_ggd`, the cross-version run died in
`al_low_level_wrap.f90`:

```
malloc: *** error for object 0x16fdfd3f0: pointer being freed was not allocated
frame #4: libal-fortran`__al_low_level_wrap_MOD_get_string at al_low_level_wrap.f90:1923
frame #5: __utilities_get_struct_MOD_get_struct_ids_identifier_dyna782
frame #6: __equilibrium_get_struct_MOD_get_struct_ids_equilibrium_con847
```

`0x16fdfd3f0` is a stack address, so this was a `free()` of something never
`malloc`'d. The cause is in hand-written code, not generated code, and it is
independent of the conversion layer:

```fortran
integer(C_INT), target :: dsize(MAXDIM)     ! never initialised
csize = C_LOC(dsize(1))
cptr  = C_NULL_PTR
status = fstatus(c_al_read_data(..., cptr, CHAR_DATA, 1, csize))
if (status%code.eq.0) then
   if (C_ASSOCIATED(cptr)) then
      call C_F_POINTER(cptr, data, dsize(1:1))
   end if
   dim1 = dsize(1)                          ! <-- uninitialised if cptr was null
end if
```

A read that **succeeds and returns nothing** leaves `cptr` null, so
`C_F_POINTER` is skipped and the caller's pointer stays undefined -- and `dsize`
was never written by anyone, so `dim1` is whatever the stack held. `get_string`
then trusted that extent:

```fortran
if (retstatus.eq.0) then
   do i=1,size                              ! reads through an unset pointer
      data(i:i) = tmpdata(i)
   end do
   if (size.gt.0) call c_free(C_LOC(tmpdata(1)))   ! frees it
```

All **23 read wrappers** share the uninitialised `dsize`. They now zero it, so a
successful-but-empty read reports extent `0` -- which every caller already
handles, because that is what an absent field looks like. The put wrappers are
deliberately untouched: there `dsize` carries the data's extents *into* the call,
and zeroing it would corrupt writes. `cptr = C_NULL_PTR` is what distinguishes a
read, which is why the change is anchored on it rather than on the declaration.

`get_string` additionally tests `associated(tmpdata)` rather than trusting the
extent, and bounds the copy by `len(data)`.

This was always latent. It needed a read that succeeds while returning nothing,
which an ordinary same-version round trip does not produce -- and which a
cross-version read could not reach either, while the first refusal was fatal.

Note also what the log shows about paths: the entry records the path as the
generated code knows it, which inside a nested getter is *relative*
(`chi_squared_r`, not `time_slice/constraints/x_point/chi_squared_r`). The full
DD path is in the message, which is why the two are reported together.

### Not the shim's loss log, and why

The conversion layer already exports a per-context loss log
(`imas_mvdd_context_loss_count` / `_loss_at`, with fidelity verdicts), which is
the better channel: per-context, no globals, no thread-safety question. It is
blocked twice today.

1. `al-fortran` links IMAS-Core *or* the shim, so calling `imas_mvdd_*` from the
   wrapper is an undefined symbol in a core build. It would need `dlsym` or weak
   binding -- a new mechanism in a repository that has none.
2. **The shim does not log this event.** `begin_arraystruct_action_impl`
   (`src/interpose.rs`) returns its refusal without calling
   `record_read_loss_at_root`; only `finish_read` writes the log. So
   `imas_mvdd_context_loss_count` reports `0` for the very refusal that started
   this investigation. Worth an issue upstream; once fixed, the Fortran-side log
   becomes a fallback rather than the source of truth.

## Reproducing

```sh
./run.sh                    # cross-version: full table, PARTIAL_READ, exit 0
./run.sh dd-4.1.1 dd-4.1.1  # self-test: full table, all "same", 0 skipped
```

Observed on DD 4.1.1 / gfortran 15.2, cross-version:

```
Paths left unset because they could not be served:          24
   coordinates_type (status -1000) IMAS-MVDD: this path's container changed shape
     and cannot be served; DD path: grids_ggd/grid/space/coordinates_type; ...
   chi_squared_r (status -1000) IMAS-MVDD: this path's unit was redefined and
     cannot be converted; DD path: time_slice/constraints/x_point/chi_squared_r; ...
   ...
column 1 read    : status 0, 0 path(s) skipped
column 2 read    : status 1, 24 path(s) skipped        <- 1 is PARTIAL_READ
```

followed by the whole table, `time_slice` included. Before, this run stopped at
the first line of that log.

Both are ctest tests (`playground-play_eq_two_dd-self` / `-cross`). To see the
original memory fault, revert the `else` arm of `al_begin_arraystruct_action` in
`mode="GET_FIELD"` and rebuild -- the whole library regenerates, so this is a
full rebuild.
