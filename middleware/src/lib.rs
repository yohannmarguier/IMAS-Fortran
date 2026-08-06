//! Middleware on the al-fortran read path.
//!
//! `wrapper/al_low_level_wrap.f90` used to bind straight to al-core. It now binds six
//! symbols to this crate instead — the read itself and the five calls that open and close
//! a context — and each forwards to its al-core counterpart. Every scalar and array an
//! IDS `get` pulls out of a backend passes through `imas_mw_read_data`, so this is the
//! single choke point for the whole read path.
//!
//! ## What it does
//!
//! With `IMAS_MW_CONVERT` set, it reads a DD 3.39.0 `equilibrium` entry through a library
//! built for DD 4.1.1. `dd-maps/equilibrium/3.39.0--4.1.1.xml` says how the two versions
//! differ; `map.rs` reads it in the direction this needs (a DD 4.1.1 path in, the DD
//! 3.39.0 path that holds the value out), and `report.rs` prints what the conversion cost.
//!
//! Three things happen to a read:
//!
//! - **The path is rewritten.** `constraints/b_field_pol_probe` is fetched as
//!   `constraints/bpol_probe`, `boundary/gap` as `boundary_separatrix/gap`. Paths arrive
//!   relative to an al-core context, so `ctx.rs` reconstructs the absolute path first —
//!   which is why the context calls are intercepted at all.
//! - **A merge falls back by precedence.** DD 3.39.0 is a transitional version shipping
//!   `j_phi` *and* the obsolescent `j_tor`; the modern name is tried first and the alias
//!   second, which is a thing only the caller of `al_read_data` can do.
//! - **The value is corrected or withheld.** 32 paths take the COCOS 11 → 17 sign flip.
//!   The four redefined `chi_squared` paths are overwritten with the DD invalid marker,
//!   because m → m⁻² has no inverse and the DD 3.39.0 number would be a wrong answer
//!   wearing the right units.
//!
//! Conversion is off unless `IMAS_MW_CONVERT` is set, and then applies only to the IDS the
//! map describes — that switch is the operator's call, read once through a `OnceLock`
//! (`convert::enabled`), since it sits on a path taken hundreds of thousands of times per
//! `get` and a per-call `getenv` would be the dominant cost of having a middleware at all.
//!
//! What the switch alone cannot decide is *which entries* need converting: it is latched
//! for the whole process, so a run that armed it to read a DD 3.39.0 entry would just as
//! happily mangle a native DD 4.1.1 entry opened in the same process — double-flipping its
//! 32 COCOS paths, which is exactly the bug this crate must not have. So once armed, every
//! root context opened for the map's IDS is checked once, individually, against its own
//! `ids_properties/version_put/data_dictionary` (`convert::entry_needs_conversion`):
//! conversion only actually runs for a context whose entry does not already declare the
//! library's own DD version. A missing or unreadable stamp counts as needing conversion —
//! that is what an entry written before this field existed looks like, and it is the case
//! the map exists for. This is what lets one process open both fixture halves and have
//! each read correctly, which `playground/play_equilibrium.f90` relies on.
//!
//! `IMAS_MW_TRACE=1` prints one line per read (ctx, path, datatype, dims, status, and the
//! conversion if any), read once through the same kind of `OnceLock` for the same reason.
//!
//! ## Rules this crate lives by
//!
//! - **Never unwind into Fortran.** An `extern "C"` frame that panics is an abort at
//!   best. Nothing here may panic: no `unwrap`, no indexing, no `eprintln!` (it panics
//!   if the write fails) — output goes through `write!` with the result discarded.
//! - **Forward on every path.** A fault in the middleware must degrade to a plain
//!   pass-through, never to a failed read. Every branch below ends in a call to al-core:
//!   an unparsable map, an unknown context, a path the map cannot place, a poisoned lock
//!   — all of them read exactly what they would have read without this crate.
//! - **Never skip the call.** Not even for a field that provably has no source. A scalar's
//!   destination is the caller's uninitialised stack storage and al-core is what writes
//!   the invalid marker into it, so a skipped read is garbage in the IDS, not an absence.
//! - **Borrow, never own.** The `void**` buffer al-core allocates is freed by the Fortran
//!   side (`c_free`), so this crate only reads through it — or, for a flip or a refusal,
//!   overwrites the values in place without touching the pointer.

pub mod ctx;
pub mod map;
pub mod paint;
pub mod report;
pub mod xml;

use std::ffi::{c_char, c_double, c_int, c_void, CStr, CString};
use std::io::Write;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::OnceLock;

use map::{Map, Plan, Verdict};

/// `MAX_ERR_MSG_LEN` from `al_defs.h` — mirrored, not derived. A mismatch here changes
/// the size of a struct returned by value, so `layout_matches_c_abi` pins it.
const MAX_ERR_MSG_LEN: usize = 256;

/// `DATA_TYPE_0` from `al_defs.h`; `CHAR_DATA` is the base, then INTEGER, DOUBLE, COMPLEX.
const DATA_TYPE_0: c_int = 50;
const CHAR_DATA: c_int = DATA_TYPE_0;
const INTEGER_DATA: c_int = DATA_TYPE_0 + 1;
const DOUBLE_DATA: c_int = DATA_TYPE_0 + 2;

/// `MAXDIM` from `wrapper/al_defs.f90`. The `size` out-param is a `dsize(MAXDIM)` on the
/// Fortran side, so it bounds how much of it may be read whatever `dim` claims.
const MAXDIM: c_int = 7;

/// `ids_real_invalid` / `ids_int_invalid` from the generated `ids_types.f90`. al-core
/// writes these in place of a field that is not in the entry, which is what makes an
/// absent *scalar* detectable — unlike an array, a scalar's buffer belongs to the caller
/// and comes back non-null either way.
const REAL_INVALID: f64 = -9.0e40;
const INT_INVALID: i32 = -999999999;

/// al-core's `al_status_t`: `{ int code; char message[256]; }`.
///
/// 260 bytes, so both the x86-64 SysV and the AArch64 AAPCS ABI return it indirectly
/// through a hidden pointer. `extern "C"` + `repr(C)` makes rustc use that same
/// convention, which is the load-bearing assumption of this whole shim.
#[repr(C)]
pub struct AlStatus {
    pub code: c_int,
    pub message: [c_char; MAX_ERR_MSG_LEN],
}

extern "C" {
    /// ```c
    /// al_status_t al_read_data(int ctxID, const char *field, const char *timebase,
    ///                         void **data, int datatype, int dim, int *size);
    /// ```
    fn al_read_data(
        ctx: c_int,
        field: *const c_char,
        timebase: *const c_char,
        data: *mut *mut c_void,
        datatype: c_int,
        dim: c_int,
        size: *mut c_int,
    ) -> AlStatus;

    fn al_begin_global_action(
        pctx: c_int,
        dataobjectname: *const c_char,
        datapath: *const c_char,
        rwmode: c_int,
        opctx: *mut c_int,
    ) -> AlStatus;

    fn al_begin_slice_action(
        pctx: c_int,
        dataobjectname: *const c_char,
        rwmode: c_int,
        time: c_double,
        interpmode: c_int,
        opctx: *mut c_int,
    ) -> AlStatus;

    fn al_begin_timerange_action(
        pctx: c_int,
        dataobjectname: *const c_char,
        rwmode: c_int,
        tmin: c_double,
        tmax: c_double,
        dtime: *mut c_void,
        dim: *mut c_void,
        interpmode: c_int,
        opctx: *mut c_int,
    ) -> AlStatus;

    fn al_begin_arraystruct_action(
        ctx: c_int,
        path: *const c_char,
        timebase: *const c_char,
        aos_size: *mut c_int,
        aosctx: *mut c_int,
    ) -> AlStatus;

    fn al_end_action(ctx: c_int) -> AlStatus;

    /// The standard C library's `free`, already linked into any process that gets this far
    /// — not a new dependency. Used the one time this crate allocates a read of its own
    /// (the version stamp `opened_root` reads to decide `convert`) rather than merely
    /// relaying a buffer al-core owns and the Fortran side frees.
    fn free(ptr: *mut c_void);
}

// ===================================================================== the read path

/// What al-fortran now calls in place of `al_read_data`.
///
/// # Safety
///
/// The contract is al-core's, unchanged: `field` and `timebase` are NUL-terminated or
/// null, `data` points to a writable `void*`, and `size` points to at least `dim`
/// `int`s or is null. Callers are generated Fortran, which always satisfies it.
#[no_mangle]
pub unsafe extern "C" fn imas_mw_read_data(
    ctx: c_int,
    field: *const c_char,
    timebase: *const c_char,
    data: *mut *mut c_void,
    datatype: c_int,
    dim: c_int,
    size: *mut c_int,
) -> AlStatus {
    let seq = READS.fetch_add(1, Ordering::Relaxed);

    let prepared = convert::plan_read(ctx, field);
    hook::before(ctx, field, datatype, dim, seq, prepared.as_ref());

    let status = match &prepared {
        Some(prepared) => {
            convert::read(prepared, ctx, field, timebase, data, datatype, dim, size)
        }
        None => al_read_data(ctx, field, timebase, data, datatype, dim, size),
    };

    hook::after(&status, data, dim, size, seq);

    status
}

/// Reads intercepted since the library was loaded. Also the trace line's sequence
/// number, which is what makes a specific read findable in a log of thousands.
static READS: AtomicU64 = AtomicU64::new(0);

/// How many reads the shim has seen. Exposed so a Fortran program can assert that the
/// middleware is actually in the path rather than inferring it from stderr.
#[no_mangle]
pub extern "C" fn imas_mw_read_count() -> u64 {
    READS.load(Ordering::Relaxed)
}

/// Whether `field` — an absolute DD 4.1.1 path relative to the IDS root, e.g.
/// `time_slice/profiles_1d/j_phi` — is one the map actually rewrites, folds, flips or
/// refuses, as opposed to a plain, unconverted pass-through. This is a static property of
/// the map itself, not of any particular read: it does not touch a context or a backend,
/// so it may be called at any time, including before or between reads.
///
/// Exported so a caller can highlight exactly which fields a conversion would touch —
/// `playground/play_equilibrium.f90` colors those rows — rather than inferring it from the
/// per-rule report, which counts hits but does not answer "would this one path convert".
/// Returns 0 whenever conversion is not armed at all (`enabled()` is `None`), since then
/// nothing is converted regardless of what the map would say about the path.
///
/// # Safety
/// `field` must be NUL-terminated or null.
#[no_mangle]
pub unsafe extern "C" fn imas_mw_path_needs_conversion(field: *const c_char) -> c_int {
    let Some(map) = convert::enabled() else {
        return 0;
    };
    let Some(path) = borrow(field) else {
        return 0;
    };
    map.resolve(path).is_some() as c_int
}

// ===================================================================== context path
//
// These five exist for one reason: `al_read_data` is handed a path relative to a context,
// so without them a field name is `profiles_1d/psi` with no way to know it belongs to
// `time_slice`. Each forwards first and records afterwards, so a context is only ever
// registered if al-core really opened it.

/// # Safety
/// al-core's contract for `al_begin_global_action`.
#[no_mangle]
pub unsafe extern "C" fn imas_mw_begin_global_action(
    pctx: c_int,
    dataobjectname: *const c_char,
    datapath: *const c_char,
    rwmode: c_int,
    opctx: *mut c_int,
) -> AlStatus {
    let status = al_begin_global_action(pctx, dataobjectname, datapath, rwmode, opctx);
    convert::opened_root(&status, dataobjectname, datapath, rwmode, opctx);
    status
}

/// # Safety
/// al-core's contract for `al_begin_slice_action`.
#[no_mangle]
pub unsafe extern "C" fn imas_mw_begin_slice_action(
    pctx: c_int,
    dataobjectname: *const c_char,
    rwmode: c_int,
    time: c_double,
    interpmode: c_int,
    opctx: *mut c_int,
) -> AlStatus {
    let status = al_begin_slice_action(pctx, dataobjectname, rwmode, time, interpmode, opctx);
    convert::opened_root(&status, dataobjectname, std::ptr::null(), rwmode, opctx);
    status
}

/// # Safety
/// al-core's contract for `al_begin_timerange_action`.
#[no_mangle]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn imas_mw_begin_timerange_action(
    pctx: c_int,
    dataobjectname: *const c_char,
    rwmode: c_int,
    tmin: c_double,
    tmax: c_double,
    dtime: *mut c_void,
    dim: *mut c_void,
    interpmode: c_int,
    opctx: *mut c_int,
) -> AlStatus {
    let status = al_begin_timerange_action(
        pctx,
        dataobjectname,
        rwmode,
        tmin,
        tmax,
        dtime,
        dim,
        interpmode,
        opctx,
    );
    convert::opened_root(&status, dataobjectname, std::ptr::null(), rwmode, opctx);
    status
}

/// An array-of-structure is the one place a path is rewritten *outside* `al_read_data`,
/// and it has to be: DD 4.1.1's `constraints/b_field_pol_probe` is DD 3.39.0's
/// `constraints/bpol_probe`, and opening the DD 4.1.1 name against a DD 3.39.0 entry
/// yields a zero-length array and takes the whole subtree with it.
///
/// # Safety
/// al-core's contract for `al_begin_arraystruct_action`.
#[no_mangle]
pub unsafe extern "C" fn imas_mw_begin_arraystruct_action(
    ctx: c_int,
    path: *const c_char,
    timebase: *const c_char,
    aos_size: *mut c_int,
    aosctx: *mut c_int,
) -> AlStatus {
    let rewrite = convert::plan_arraystruct(ctx, path);
    let requested = match &rewrite {
        Some(rewrite) => rewrite.c_relative.as_ptr(),
        None => path,
    };
    let status = al_begin_arraystruct_action(ctx, requested, timebase, aos_size, aosctx);
    convert::opened_child(&status, ctx, path, rewrite.as_ref(), aosctx);
    status
}

/// # Safety
/// al-core's contract for `al_end_action`.
#[no_mangle]
pub unsafe extern "C" fn imas_mw_end_action(ctx: c_int) -> AlStatus {
    let status = al_end_action(ctx);
    // Dropped whatever al-core said: al-core reuses context ids, and a frame that
    // outlived its context would answer for the next one to take the number.
    ctx::close(ctx);
    status
}

// ===================================================================== conversion

/// Running the map against a read. Everything here answers `None` — meaning "forward
/// untouched" — for any question it cannot answer with certainty.
mod convert {
    use super::*;

    /// A read the map has something to say about, resolved down to what al-core needs.
    pub(super) struct Prepared {
        plan: std::sync::Arc<Plan>,
        /// DD 3.39.0 paths relative to the open context, in precedence order. Empty means
        /// "read the path as given", which is what an absent or refused field does.
        sources: Vec<CString>,
    }

    impl Prepared {
        /// The first source, for the trace line.
        pub(super) fn shown(&self) -> &str {
            self.sources
                .first()
                .and_then(|c| c.to_str().ok())
                .unwrap_or("(unchanged)")
        }

        pub(super) fn verdict(&self) -> Verdict {
            self.plan.verdict
        }

        pub(super) fn flips(&self) -> bool {
            self.plan.flip
        }
    }

    /// An array-of-structure path the map moves or renames.
    pub(super) struct AosRewrite {
        pub(super) c_relative: CString,
        /// The same path as a `str`, to record the context's DD 3.39.0 prefix with.
        relative: String,
    }

    /// The map, or `None` when conversion is off. Loaded once; the banner and any
    /// complaint about the map itself are printed at that moment, so a run says up front
    /// what it is about to do.
    pub(super) fn enabled() -> Option<&'static Map> {
        static MAP: OnceLock<Option<Map>> = OnceLock::new();
        MAP.get_or_init(|| {
            if !convert_requested() {
                return None;
            }
            let map = Map::load();
            report::notice(&map.banner());
            report::notice(&format!(
                "{} rules reachable on the read path, {} COCOS sign flips",
                map.rule_count(),
                map.flip_count()
            ));
            for complaint in &map.complaints {
                report::notice(&format!("map: {complaint}"));
            }
            Some(map)
        })
        .as_ref()
    }

    /// `IMAS_MW_CONVERT` enables the conversion. Any value is a yes except the usual ways
    /// of writing no, so `IMAS_MW_CONVERT=3.39.0` reads as well as `=1` does.
    ///
    /// This is deliberately a manual arming switch and not, by itself, the version
    /// comparison: which *map* to load — and whether this run may convert its IDS at all —
    /// stays the operator's call rather than something inferred from a stamp a run might
    /// never see (nothing here loads a map on spec, hoping to find an entry it applies to).
    /// Once armed, though, `opened_root`'s `entry_needs_conversion` *does* compare each
    /// opened entry's own version stamp against the library's, so the switch answers "is
    /// the machinery loaded" and the per-entry check answers "does this particular read
    /// need it" — see the module doc above.
    fn convert_requested() -> bool {
        match std::env::var("IMAS_MW_CONVERT") {
            Ok(value) => !matches!(
                value.trim().to_ascii_lowercase().as_str(),
                "" | "0" | "off" | "no" | "false"
            ),
            Err(_) => false,
        }
    }

    /// # Safety
    /// `field` is NUL-terminated or null.
    pub(super) unsafe fn plan_read(ctx: c_int, field: *const c_char) -> Option<Prepared> {
        let map = enabled()?;
        let request = ctx::locate(ctx, borrow(field)?, &map.ids)?;
        let plan = map.resolve(&request.right)?;

        let mut sources = Vec::with_capacity(plan.sources.len());
        for absolute in &plan.sources {
            // A value that moved out from under this context cannot be fetched through
            // it. Saying so beats handing al-core a path that means something else.
            let Some(relative) = ctx::relative(&request.left_prefix, absolute)
                .and_then(|relative| CString::new(relative).ok())
            else {
                report::unreachable(&request.right, absolute);
                return None;
            };
            sources.push(relative);
        }
        Some(Prepared { plan, sources })
    }

    /// # Safety
    /// The pointers are al-core's, under the contract `imas_mw_read_data` documents.
    #[allow(clippy::too_many_arguments)]
    pub(super) unsafe fn read(
        prepared: &Prepared,
        ctx: c_int,
        field: *const c_char,
        timebase: *const c_char,
        data: *mut *mut c_void,
        datatype: c_int,
        dim: c_int,
        size: *mut c_int,
    ) -> AlStatus {
        let plan = &prepared.plan;

        let status = if prepared.sources.is_empty() {
            al_read_data(ctx, field, timebase, data, datatype, dim, size)
        } else {
            try_sources(
                &prepared.sources,
                ctx,
                field,
                timebase,
                data,
                datatype,
                dim,
                size,
            )
        };

        let flipped = if plan.suppress {
            invalidate(data, datatype, dim, size);
            0
        } else if plan.flip && status.code == 0 {
            flip_sign(data, datatype, dim, size)
        } else {
            0
        };

        report::record(plan.verdict, &plan.key, &plan.note, flipped > 0);
        status
    }

    /// Try each DD 3.39.0 spelling in precedence order and keep the first that comes back
    /// populated. This is what a `merged` rule needs and what only the caller of
    /// `al_read_data` can do: 3.39.0 ships `j_phi` alongside the obsolescent `j_tor`, and
    /// which one an entry actually filled is not knowable in advance.
    ///
    /// # Safety
    /// As `read`.
    #[allow(clippy::too_many_arguments)]
    unsafe fn try_sources(
        sources: &[CString],
        ctx: c_int,
        field: *const c_char,
        timebase: *const c_char,
        data: *mut *mut c_void,
        datatype: c_int,
        dim: c_int,
        size: *mut c_int,
    ) -> AlStatus {
        // A scalar's destination is the *caller's* storage, passed in through `*data`; a
        // second attempt has to be handed it again, so keep it.
        let scalar_dest = if dim <= 0 && !data.is_null() {
            *data
        } else {
            std::ptr::null_mut()
        };

        let mut last: Option<AlStatus> = None;
        for source in sources {
            if !data.is_null() {
                // Arrays start from null, the way the Fortran wrapper sets them up, so an
                // absent retry cannot inherit the previous attempt's pointer.
                *data = if dim <= 0 {
                    scalar_dest
                } else {
                    std::ptr::null_mut()
                };
            }
            let status = al_read_data(ctx, source.as_ptr(), timebase, data, datatype, dim, size);
            let filled = status.code == 0 && populated(data, datatype, dim, scalar_dest);
            last = Some(status);
            if filled {
                break;
            }
        }
        match last {
            Some(status) => status,
            // Unreachable for a well-formed plan (a merge always has sources), but a plan
            // with an empty list must still produce a read.
            None => al_read_data(ctx, field, timebase, data, datatype, dim, size),
        }
    }

    /// Whether the read that just returned actually found a value.
    ///
    /// # Safety
    /// As `read`.
    pub(super) unsafe fn populated(
        data: *mut *mut c_void,
        datatype: c_int,
        dim: c_int,
        scalar_dest: *mut c_void,
    ) -> bool {
        if dim > 0 {
            // An absent array leaves the null the wrapper wrote. Deliberately *not* also
            // testing the reported dims: a non-null buffer belongs to the Fortran side to
            // free, and retrying past one would leak it.
            return !data.is_null() && !(*data).is_null();
        }
        !is_invalid(scalar_dest, datatype)
    }

    /// # Safety
    /// `ptr` is null or points to one value of `datatype`.
    unsafe fn is_invalid(ptr: *mut c_void, datatype: c_int) -> bool {
        if ptr.is_null() {
            return false;
        }
        match datatype {
            DOUBLE_DATA => (ptr as *const f64).read_unaligned() == REAL_INVALID,
            INTEGER_DATA => (ptr as *const i32).read_unaligned() == INT_INVALID,
            // An unset string is an empty one; there is no marker to compare against.
            CHAR_DATA => (ptr as *const u8).read_unaligned() == 0,
            _ => false,
        }
    }

    /// COCOS 11 → 17: multiply by -1, which touches only the IEEE-754 sign bit and so is
    /// exactly invertible. Returns how many values changed.
    ///
    /// # Safety
    /// As `read`.
    pub(super) unsafe fn flip_sign(
        data: *mut *mut c_void,
        datatype: c_int,
        dim: c_int,
        size: *mut c_int,
    ) -> usize {
        if datatype != DOUBLE_DATA {
            return 0;
        }
        let Some(buffer) = buffer(data) else {
            return 0;
        };
        let Some(count) = element_count(dim, size) else {
            return 0;
        };
        let mut flipped = 0;
        for i in 0..count {
            let slot = (buffer as *mut f64).add(i);
            let value = slot.read_unaligned();
            // Never flip the invalid marker: negated, -9e40 reads back as a plausible
            // enormous number instead of as "no value".
            if value == REAL_INVALID {
                continue;
            }
            slot.write_unaligned(-value);
            flipped += 1;
        }
        flipped
    }

    /// Overwrite a refused value with the DD invalid marker — the DD's own way of saying
    /// there is no value here. The pointer and the reported dims are left alone, so
    /// ownership of the buffer is exactly what al-core handed over.
    ///
    /// Strings and complex numbers have no marker to write, and this map refuses neither.
    ///
    /// # Safety
    /// As `read`.
    pub(super) unsafe fn invalidate(data: *mut *mut c_void, datatype: c_int, dim: c_int, size: *mut c_int) {
        let Some(buffer) = buffer(data) else {
            return;
        };
        let Some(count) = element_count(dim, size) else {
            return;
        };
        for i in 0..count {
            match datatype {
                DOUBLE_DATA => (buffer as *mut f64).add(i).write_unaligned(REAL_INVALID),
                INTEGER_DATA => (buffer as *mut i32).add(i).write_unaligned(INT_INVALID),
                _ => return,
            }
        }
    }

    /// # Safety
    /// `data` is null or points to a readable `void*`.
    unsafe fn buffer(data: *mut *mut c_void) -> Option<*mut c_void> {
        if data.is_null() || (*data).is_null() {
            return None;
        }
        Some(*data)
    }

    /// How many values the buffer holds. `None` for anything it cannot be sure of, which
    /// is what stops a wild `dim` turning into an out-of-bounds write.
    ///
    /// # Safety
    /// `size` is null or points to `min(dim, MAXDIM)` readable `int`s.
    unsafe fn element_count(dim: c_int, size: *mut c_int) -> Option<usize> {
        if dim <= 0 {
            return Some(1);
        }
        if size.is_null() || dim > MAXDIM {
            return None;
        }
        let dims = std::slice::from_raw_parts(size, dim as usize);
        let mut count: usize = 1;
        for extent in dims {
            if *extent < 0 {
                return None;
            }
            count = count.checked_mul(*extent as usize)?;
        }
        Some(count)
    }

    /// Register the context an IDS-level action just opened.
    ///
    /// # Safety
    /// The pointers are the ones al-core was handed; `opctx` is a writable `int` or null.
    pub(super) unsafe fn opened_root(
        status: &AlStatus,
        dataobjectname: *const c_char,
        datapath: *const c_char,
        rwmode: c_int,
        opctx: *mut c_int,
    ) {
        if status.code != 0 {
            return;
        }
        let Some(map) = enabled() else {
            return;
        };
        let (Some(ids), Some(id)) = (borrow(dataobjectname), opctx.as_ref().copied()) else {
            return;
        };
        let read = rwmode == ctx::READ_OP;
        // Only a read of the map's own IDS is worth the extra probe read below; a write
        // context, or a read of some other IDS, is never converted regardless.
        let convert = read && ids == map.ids && entry_needs_conversion(id, map);
        ctx::open_root(id, ids, borrow(datapath).unwrap_or(""), read, convert);
    }

    /// Whether the entry `ctx` just opened onto actually needs `map` applied at all,
    /// decided by comparing its own `ids_properties/version_put/data_dictionary` against
    /// `map.right_dd` — the DD version this library, and this map, were built for.
    ///
    /// Read directly through al-core's `al_read_data`, never through `imas_mw_read_data`:
    /// deciding whether the map applies cannot itself be run through the map. This is the
    /// one read this crate issues on its own rather than relaying, so unlike every other
    /// buffer here — which al-core allocates and the Fortran side frees — this one is
    /// freed right below.
    ///
    /// Absent or empty is treated as needing conversion: that is exactly what an entry
    /// written before this field existed looks like, and it is the case the map exists to
    /// handle. Only entries that *positively* declare the library's own version are left
    /// alone — which is what lets one process open a native DD 4.1.1 entry and a DD 3.39.0
    /// entry through the same armed map and have both read correctly.
    ///
    /// # Safety
    /// `ctx` is a context al-core just opened successfully for `map.ids`.
    unsafe fn entry_needs_conversion(ctx: c_int, map: &Map) -> bool {
        let field = b"ids_properties/version_put/data_dictionary\0";
        let timebase = b"\0";
        let mut data: *mut c_void = std::ptr::null_mut();
        let mut dims: [c_int; 1] = [0];
        let status = al_read_data(
            ctx,
            field.as_ptr() as *const c_char,
            timebase.as_ptr() as *const c_char,
            &mut data,
            CHAR_DATA,
            1,
            dims.as_mut_ptr(),
        );
        if status.code != 0 || data.is_null() {
            report::notice(&format!(
                "{}: entry has no version_put/data_dictionary stamp, converting",
                map.ids
            ));
            return true;
        }
        let len = dims[0].max(0) as usize;
        let bytes = std::slice::from_raw_parts(data as *const u8, len);
        let stamp = String::from_utf8_lossy(bytes).trim().to_string();
        free(data);

        let convert = differs(&stamp, &map.right_dd);
        report::notice(&format!(
            "{}: entry declares DD {} against a DD {} library -> {}",
            map.ids,
            if stamp.is_empty() { "?" } else { stamp.as_str() },
            map.right_dd,
            if convert { "converting" } else { "already this version, not converting" },
        ));
        convert
    }

    /// The comparison `entry_needs_conversion` makes, pulled out so it can be unit tested
    /// without a live al-core context. An empty stamp counts as differing — see that
    /// function's doc for why.
    fn differs(stamp: &str, library_dd: &str) -> bool {
        stamp.is_empty() || stamp != library_dd
    }

    /// # Safety
    /// `path` is NUL-terminated or null.
    pub(super) unsafe fn plan_arraystruct(ctx: c_int, path: *const c_char) -> Option<AosRewrite> {
        let map = enabled()?;
        let request = ctx::locate(ctx, borrow(path)?, &map.ids)?;
        let plan = map.resolve(&request.right)?;
        report::record(plan.verdict, &plan.key, &plan.note, false);

        // Precedence 1 only. An array-of-structure's length is decided when it opens and
        // every field below it is read through the resulting context, so there is no
        // second attempt to fall back to the way a scalar read has.
        let absolute = plan.sources.first()?;
        let relative = ctx::relative(&request.left_prefix, absolute)?;
        Some(AosRewrite {
            c_relative: CString::new(relative.clone()).ok()?,
            relative,
        })
    }

    /// Register the array-of-structure context, under both the path the caller asked for
    /// and the one al-core was given.
    ///
    /// # Safety
    /// As `opened_root`.
    pub(super) unsafe fn opened_child(
        status: &AlStatus,
        parent: c_int,
        path: *const c_char,
        rewrite: Option<&AosRewrite>,
        aosctx: *mut c_int,
    ) {
        if status.code != 0 || enabled().is_none() {
            return;
        }
        let (Some(right), Some(id)) = (borrow(path), aosctx.as_ref().copied()) else {
            return;
        };
        let left = rewrite.map(|rewrite| rewrite.relative.as_str()).unwrap_or(right);
        ctx::open_child(parent, id, right, left);
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        /// The one thing standing between a native DD 4.1.1 read and a double-flipped
        /// COCOS field: an entry that already declares the library's own version must
        /// compare as "no conversion needed".
        #[test]
        fn an_entry_already_at_the_library_version_does_not_differ() {
            assert!(!differs("4.1.1", "4.1.1"));
        }

        #[test]
        fn an_entry_at_a_different_version_differs() {
            assert!(differs("3.39.0", "4.1.1"));
        }

        /// A missing or unparsed stamp must default to "needs conversion" — that is
        /// exactly what an entry written before this field existed looks like.
        #[test]
        fn an_empty_stamp_counts_as_differing() {
            assert!(differs("", "4.1.1"));
        }

        /// `differs` is a raw comparison; trimming the stamp is `entry_needs_conversion`'s
        /// job, done once before calling this, not something to repeat on every call.
        #[test]
        fn differs_does_not_trim_on_its_own() {
            assert!(differs(" 4.1.1", "4.1.1"));
        }
    }
}

// ===================================================================== tracing

/// The trace, on `IMAS_MW_TRACE=1`. Purely an observer; the conversion above is what
/// changes a read.
mod hook {
    use super::*;

    pub(super) fn before(
        ctx: c_int,
        field: *const c_char,
        datatype: c_int,
        dim: c_int,
        seq: u64,
        prepared: Option<&convert::Prepared>,
    ) {
        if !trace_enabled() {
            return;
        }
        let conversion = match prepared {
            None => String::new(),
            Some(prepared) => format!(
                " [{} -> {}{}]",
                prepared.verdict().label(),
                prepared.shown(),
                if prepared.flips() { " +flip" } else { "" },
            ),
        };
        let mut err = std::io::stderr().lock();
        let _ = writeln!(
            err,
            "[mw {seq:>6}] read  ctx={ctx} {ty}[{dim}] {path}{conversion}",
            ty = datatype_name(datatype),
            path = unsafe { cstr(field) },
        );
    }

    pub(super) fn after(
        status: &AlStatus,
        data: *mut *mut c_void,
        dim: c_int,
        size: *mut c_int,
        seq: u64,
    ) {
        if !trace_enabled() {
            return;
        }
        let mut err = std::io::stderr().lock();

        // A null `data` out-param means the field was absent from the backend, which is
        // an ordinary outcome of a `get` over a sparsely filled entry, not an error.
        let buffer = unsafe { data.as_ref() }.copied().unwrap_or(std::ptr::null_mut());
        let shape = unsafe { shape(dim, size) };

        if status.code == 0 {
            let _ = writeln!(
                err,
                "[mw {seq:>6}]   ok  shape={shape} buf={}",
                if buffer.is_null() { "absent" } else { "filled" },
            );
        } else {
            let _ = writeln!(
                err,
                "[mw {seq:>6}]  err  code={} shape={shape} {}",
                status.code,
                unsafe { cstr(status.message.as_ptr()) },
            );
        }
    }

    /// `IMAS_MW_TRACE=1` turns the trace on. Read once: this sits on a path taken tens of
    /// thousands of times per `get`, where a per-call `getenv` would be the dominant cost
    /// of having a middleware at all.
    fn trace_enabled() -> bool {
        static ENABLED: OnceLock<bool> = OnceLock::new();
        *ENABLED.get_or_init(|| {
            matches!(
                std::env::var("IMAS_MW_TRACE").as_deref(),
                Ok("1") | Ok("true") | Ok("yes")
            )
        })
    }
}

// ===================================================================== helpers

/// The dimensions al-core reported, as `2x65` / `scalar`. `dim` is how many entries of
/// `size` are meaningful, so a short, null or implausible `size` yields `?` rather than a
/// wild read.
///
/// # Safety
///
/// `size` must point to `min(dim, MAXDIM)` readable `int`s, or be null.
unsafe fn shape(dim: c_int, size: *mut c_int) -> String {
    if dim <= 0 {
        return "scalar".to_string();
    }
    if size.is_null() || dim > MAXDIM {
        return "?".to_string();
    }
    let dims = std::slice::from_raw_parts(size, dim as usize);
    dims.iter()
        .map(|d| d.to_string())
        .collect::<Vec<_>>()
        .join("x")
}

/// `CHAR`/`INT`/`DBL`/`CPLX` for a trace line, or the raw number if al-core grows a type
/// this shim has not been told about.
fn datatype_name(datatype: c_int) -> String {
    match datatype - DATA_TYPE_0 {
        0 => "CHAR".to_string(),
        1 => "INT".to_string(),
        2 => "DBL".to_string(),
        3 => "CPLX".to_string(),
        _ => format!("type{datatype}"),
    }
}

/// A C string as something printable, without assuming it is valid UTF-8 or non-null.
///
/// # Safety
///
/// `ptr` must be NUL-terminated or null.
unsafe fn cstr(ptr: *const c_char) -> String {
    if ptr.is_null() {
        return "(null)".to_string();
    }
    CStr::from_ptr(ptr).to_string_lossy().into_owned()
}

/// A C string borrowed as `&str`, for the map lookup — which happens per read, so it must
/// not allocate. `None` for null or non-UTF-8; DD paths are ASCII.
///
/// # Safety
///
/// `ptr` must be NUL-terminated or null, and stay alive for `'a`.
unsafe fn borrow<'a>(ptr: *const c_char) -> Option<&'a str> {
    if ptr.is_null() {
        return None;
    }
    CStr::from_ptr(ptr).to_str().ok()
}

/// Defines the al-core symbols the crate above declares, but only under `cargo test`: a
/// `staticlib` crate's unit-test binary is linked on its own, with no al-core to resolve
/// against. Standing in for it also buys the one test that matters most — that a call
/// really does travel Fortran-shaped arguments through the shim and back.
#[cfg(test)]
mod fake_core {
    use super::*;
    use std::sync::Mutex;

    /// What the next call returns, and what it saw. A single test drives these, so no
    /// lock ordering to worry about beyond the `Mutex` itself.
    pub(super) static NEXT_CODE: Mutex<c_int> = Mutex::new(0);
    pub(super) static LAST_FIELD: Mutex<String> = Mutex::new(String::new());

    /// One `int` for the fake buffer to point at, so `data` comes back non-null the way
    /// a filled field's would.
    static BUFFER: c_int = 42;

    #[no_mangle]
    unsafe extern "C" fn al_read_data(
        _ctx: c_int,
        field: *const c_char,
        _timebase: *const c_char,
        data: *mut *mut c_void,
        _datatype: c_int,
        dim: c_int,
        size: *mut c_int,
    ) -> AlStatus {
        if let Ok(mut last) = LAST_FIELD.lock() {
            *last = cstr(field);
        }
        if !data.is_null() {
            *data = &BUFFER as *const c_int as *mut c_void;
        }
        // Fill the dims al-core would report: 2, 65, 3, ... for as many as `dim` asks.
        if !size.is_null() {
            let dims = [2, 65, 3];
            for i in 0..(dim.max(0) as usize) {
                *size.add(i) = dims.get(i).copied().unwrap_or(1);
            }
        }
        let code = NEXT_CODE.lock().map(|c| *c).unwrap_or(0);
        let mut status = AlStatus { code, message: [0; MAX_ERR_MSG_LEN] };
        for (slot, byte) in status.message.iter_mut().zip(b"fake failure\0") {
            *slot = *byte as c_char;
        }
        status
    }

    /// The context calls are forwarded, never inspected, so standing in for them only
    /// needs to satisfy the linker and hand back success.
    fn ok() -> AlStatus {
        AlStatus { code: 0, message: [0; MAX_ERR_MSG_LEN] }
    }

    #[no_mangle]
    unsafe extern "C" fn al_begin_global_action(
        _pctx: c_int,
        _dataobjectname: *const c_char,
        _datapath: *const c_char,
        _rwmode: c_int,
        _opctx: *mut c_int,
    ) -> AlStatus {
        ok()
    }

    #[no_mangle]
    unsafe extern "C" fn al_begin_slice_action(
        _pctx: c_int,
        _dataobjectname: *const c_char,
        _rwmode: c_int,
        _time: c_double,
        _interpmode: c_int,
        _opctx: *mut c_int,
    ) -> AlStatus {
        ok()
    }

    #[no_mangle]
    #[allow(clippy::too_many_arguments)]
    unsafe extern "C" fn al_begin_timerange_action(
        _pctx: c_int,
        _dataobjectname: *const c_char,
        _rwmode: c_int,
        _tmin: c_double,
        _tmax: c_double,
        _dtime: *mut c_void,
        _dim: *mut c_void,
        _interpmode: c_int,
        _opctx: *mut c_int,
    ) -> AlStatus {
        ok()
    }

    #[no_mangle]
    unsafe extern "C" fn al_begin_arraystruct_action(
        _ctx: c_int,
        path: *const c_char,
        _timebase: *const c_char,
        _aos_size: *mut c_int,
        _aosctx: *mut c_int,
    ) -> AlStatus {
        if let Ok(mut last) = LAST_FIELD.lock() {
            *last = cstr(path);
        }
        ok()
    }

    #[no_mangle]
    unsafe extern "C" fn al_end_action(_ctx: c_int) -> AlStatus {
        ok()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The one thing a unit test can check that a linker cannot: that `AlStatus` is the
    /// 260-byte, 4-aligned struct al-core returns. If this drifts, every read comes back
    /// with a garbage status through a silently mismatched return convention. Under
    /// `repr(C)` an `int` followed by a `char` array can only be laid out one way, so
    /// size and alignment together pin it — no `offset_of!`, which would raise the MSRV.
    #[test]
    fn layout_matches_c_abi() {
        assert_eq!(std::mem::size_of::<AlStatus>(), 4 + MAX_ERR_MSG_LEN);
        assert_eq!(std::mem::align_of::<AlStatus>(), std::mem::align_of::<c_int>());
    }

    #[test]
    fn shape_renders_dims_and_degenerate_cases() {
        let dims: [c_int; 2] = [2, 65];
        unsafe {
            assert_eq!(shape(2, dims.as_ptr() as *mut c_int), "2x65");
            assert_eq!(shape(1, dims.as_ptr() as *mut c_int), "2");
            assert_eq!(shape(0, dims.as_ptr() as *mut c_int), "scalar");
            // A null size array must not be dereferenced even when dim says otherwise.
            assert_eq!(shape(3, std::ptr::null_mut()), "?");
            // Nor may a dim beyond the Fortran side's dsize(MAXDIM).
            assert_eq!(shape(64, dims.as_ptr() as *mut c_int), "?");
        }
    }

    #[test]
    fn datatype_names_cover_the_al_defs_range() {
        assert_eq!(datatype_name(DATA_TYPE_0), "CHAR");
        assert_eq!(datatype_name(DATA_TYPE_0 + 2), "DBL");
        assert_eq!(datatype_name(DATA_TYPE_0 + 3), "CPLX");
        assert_eq!(datatype_name(99), "type99");
    }

    #[test]
    fn cstr_tolerates_null_and_non_utf8() {
        unsafe {
            assert_eq!(cstr(std::ptr::null()), "(null)");
            let bytes = b"equilibrium/time\0";
            assert_eq!(cstr(bytes.as_ptr() as *const c_char), "equilibrium/time");
            assert_eq!(borrow(std::ptr::null()), None);
            assert_eq!(borrow(bytes.as_ptr() as *const c_char), Some("equilibrium/time"));
        }
    }

    /// The shim's actual job with conversion off: pass the arguments through untouched,
    /// hand back the status it was given, and count the call. Runs with tracing on so both
    /// trace branches — success and failure — are executed rather than merely compiled;
    /// the only test that touches `IMAS_MW_TRACE`, so initialising the `OnceLock` here
    /// races with nothing.
    #[test]
    fn forwards_arguments_and_status_unchanged() {
        std::env::set_var("IMAS_MW_TRACE", "1");

        let field = b"equilibrium/time_slice(1)/profiles_1d/psi\0";
        let timebase = b"equilibrium/time\0";
        let mut data: *mut c_void = std::ptr::null_mut();
        let mut size: [c_int; 3] = [0; 3];

        let before = imas_mw_read_count();
        let status = unsafe {
            imas_mw_read_data(
                7,
                field.as_ptr() as *const c_char,
                timebase.as_ptr() as *const c_char,
                &mut data,
                DOUBLE_DATA,
                2,
                size.as_mut_ptr(),
            )
        };

        assert_eq!(status.code, 0);
        assert_eq!(imas_mw_read_count(), before + 1, "the read was not counted");
        assert_eq!(
            *fake_core::LAST_FIELD.lock().unwrap(),
            "equilibrium/time_slice(1)/profiles_1d/psi",
            "the field path reached al-core altered"
        );
        assert!(!data.is_null(), "the out-param buffer did not survive the shim");
        assert_eq!(&size[..2], &[2, 65], "the dims al-core wrote did not survive");

        // And an error status comes back with its code and message intact.
        *fake_core::NEXT_CODE.lock().unwrap() = -7;
        let status = unsafe {
            imas_mw_read_data(
                7,
                field.as_ptr() as *const c_char,
                timebase.as_ptr() as *const c_char,
                &mut data,
                DATA_TYPE_0,
                0,
                std::ptr::null_mut(),
            )
        };
        assert_eq!(status.code, -7);
        assert_eq!(unsafe { cstr(status.message.as_ptr()) }, "fake failure");
        *fake_core::NEXT_CODE.lock().unwrap() = 0;
    }

    /// The value transforms, driven directly rather than through the env-gated map: they
    /// are the two places this crate writes into a buffer al-core handed over, so the
    /// bounds and the invalid-marker exemption are worth pinning on their own.
    #[test]
    fn a_flip_negates_every_value_but_the_invalid_marker() {
        let mut values: [f64; 4] = [1.5, -2.5, REAL_INVALID, 0.0];
        let mut buffer = values.as_mut_ptr() as *mut c_void;
        let mut size: [c_int; 1] = [4];

        let flipped = unsafe {
            convert::flip_sign(
                &mut buffer,
                DOUBLE_DATA,
                1,
                size.as_mut_ptr(),
            )
        };
        assert_eq!(flipped, 3, "the invalid marker must be left alone");
        assert_eq!(values[0], -1.5);
        assert_eq!(values[1], 2.5);
        assert_eq!(values[2], REAL_INVALID);
        assert_eq!(values[3], 0.0);

        // Integers and strings carry no sign convention, and an implausible dim is
        // refused rather than trusted.
        let mut ints: [i32; 2] = [3, 4];
        let mut int_buffer = ints.as_mut_ptr() as *mut c_void;
        assert_eq!(
            unsafe {
                convert::flip_sign(
                    &mut int_buffer,
                    INTEGER_DATA,
                    1,
                    size.as_mut_ptr(),
                )
            },
            0
        );
        assert_eq!(
            unsafe {
                convert::flip_sign(
                    &mut buffer,
                    DOUBLE_DATA,
                    64,
                    size.as_mut_ptr(),
                )
            },
            0,
            "a dim beyond MAXDIM must not be used to size a write"
        );
    }

    #[test]
    fn a_refusal_writes_the_dd_invalid_marker() {
        let mut values: [f64; 2] = [1.5, 2.5];
        let mut buffer = values.as_mut_ptr() as *mut c_void;
        let mut size: [c_int; 1] = [2];
        unsafe {
            convert::invalidate(
                &mut buffer,
                DOUBLE_DATA,
                1,
                size.as_mut_ptr(),
            )
        };
        assert_eq!(values, [REAL_INVALID, REAL_INVALID]);

        let mut scalar: f64 = 7.0;
        let mut scalar_buffer = (&mut scalar) as *mut f64 as *mut c_void;
        unsafe {
            convert::invalidate(
                &mut scalar_buffer,
                DOUBLE_DATA,
                0,
                std::ptr::null_mut(),
            )
        };
        assert_eq!(scalar, REAL_INVALID, "a scalar has one element and no dims");

        let mut int_scalar: i32 = 7;
        let mut int_buffer = (&mut int_scalar) as *mut i32 as *mut c_void;
        unsafe {
            convert::invalidate(
                &mut int_buffer,
                INTEGER_DATA,
                0,
                std::ptr::null_mut(),
            )
        };
        assert_eq!(int_scalar, INT_INVALID);
    }

    /// Absence is what a `merged` rule's fallback keys on, and it is reported differently
    /// by shape: an array comes back as a null buffer, a scalar as the invalid marker in
    /// storage that was never null to begin with.
    #[test]
    fn absence_is_detected_per_shape() {
        unsafe {
            let mut null_buffer: *mut c_void = std::ptr::null_mut();
            assert!(!convert::populated(
                &mut null_buffer,
                DOUBLE_DATA,
                1,
                std::ptr::null_mut()
            ));

            let mut value = 1.0f64;
            let mut buffer = (&mut value) as *mut f64 as *mut c_void;
            assert!(convert::populated(
                &mut buffer,
                DOUBLE_DATA,
                1,
                std::ptr::null_mut()
            ));

            // Scalars: the destination is the caller's, so the marker is the only signal.
            let mut absent = REAL_INVALID;
            let absent_dest = (&mut absent) as *mut f64 as *mut c_void;
            let mut ignored: *mut c_void = std::ptr::null_mut();
            assert!(!convert::populated(
                &mut ignored,
                DOUBLE_DATA,
                0,
                absent_dest
            ));

            let mut present = 3.5f64;
            let present_dest = (&mut present) as *mut f64 as *mut c_void;
            assert!(convert::populated(
                &mut ignored,
                DOUBLE_DATA,
                0,
                present_dest
            ));

            let mut absent_int = INT_INVALID;
            let absent_int_dest = (&mut absent_int) as *mut i32 as *mut c_void;
            assert!(!convert::populated(
                &mut ignored,
                INTEGER_DATA,
                0,
                absent_int_dest
            ));
        }
    }
}
