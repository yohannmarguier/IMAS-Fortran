# What a shim-linked read shows about IMAS-Fortran

Running `play_eq_two_dd` against the two fixtures surfaces one defect in this
repository. The defect is in generated code, so the fix belongs in
`IDSDef2F90Routines.xsl`, not in any `.f90`.

Nothing here is fixed. This document exists to make the defect precise.

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

## What the fix has to decide

Correcting the two defects above stops the memory fault and yields a clean
error. It does **not** produce a table: the read still aborts at `grids_ggd`, so
every `time_slice` path stays empty.

A table needs a policy decision as well: **must a refusal stop the whole read?**
A best-effort read would leave the refused array empty and continue. That
changes generated read behaviour for all 82 IDSs, and it is the point at which a
**fidelity verdict** and the shim's **loss log** become the right channel for
telling the caller what was skipped — rather than a `write(*,*)` and a return.

## Reproducing

```sh
./run.sh                    # cross-version: dies, with the banner above
./run.sh dd-4.1.1 dd-4.1.1  # self-test: 170 rows, all "same"
```

The self-test is what proves the table logic independently of the shim, since
the cross-version read cannot currently reach it.
