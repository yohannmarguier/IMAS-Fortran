//! Middleware on the al-fortran read path.
//!
//! `wrapper/al_low_level_wrap.f90` used to bind `c_al_read_data` straight to al-core's
//! `al_read_data`. It now binds to `imas_mw_read_data`, defined here, which forwards to
//! the real `al_read_data`. Every scalar and array an IDS `get` pulls out of a backend
//! passes through this function — all ~29 call sites in the wrapper funnel through the
//! one interface block, so this is the single choke point for the whole read path.
//!
//! This version observes and forwards unchanged. `hook::before` / `hook::after` are the
//! seams where a future version rewrites the requested DD path or post-processes the
//! returned buffer; they are deliberately the only places that would need to change.
//!
//! ## Rules this file lives by
//!
//! - **Never unwind into Fortran.** An `extern "C"` frame that panics is an abort at
//!   best. Nothing here may panic: no `unwrap`, no indexing, no `eprintln!` (it panics
//!   if the write fails) — tracing goes through `write!` with the result discarded.
//! - **Forward on every path.** A fault in the middleware must degrade to a plain
//!   pass-through, never to a failed read. There is no early return that skips the
//!   call to `al_read_data`.
//! - **Borrow, never own.** The `void**` buffer al-core allocates is freed by the
//!   Fortran side (`c_free`), so the shim only ever reads through it.

use std::ffi::{c_char, c_int, c_void, CStr};
use std::io::Write;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::OnceLock;

/// `MAX_ERR_MSG_LEN` from `al_defs.h` — mirrored, not derived. A mismatch here changes
/// the size of a struct returned by value, so `layout_matches_c_abi` pins it.
const MAX_ERR_MSG_LEN: usize = 256;

/// `DATA_TYPE_0` from `al_defs.h`; `CHAR_DATA` is the base, then INTEGER, DOUBLE, COMPLEX.
const DATA_TYPE_0: c_int = 50;

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
    /// The real thing, from al-core:
    ///
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
}

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

    hook::before(ctx, field, datatype, dim, seq);

    let status = al_read_data(ctx, field, timebase, data, datatype, dim, size);

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

/// The interception seams. Today both are observers; a path rewrite belongs in
/// `before` (returning a replacement `field`) and a value transform in `after`.
mod hook {
    use super::*;

    pub(super) fn before(ctx: c_int, field: *const c_char, datatype: c_int, dim: c_int, seq: u64) {
        if !trace_enabled() {
            return;
        }
        let mut err = std::io::stderr().lock();
        let _ = writeln!(
            err,
            "[mw {seq:>6}] read  ctx={ctx} {ty}[{dim}] {path}",
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

/// The dimensions al-core reported, as `2x65` / `scalar`. `dim` is how many entries of
/// `size` are meaningful, so a short or null `size` yields `?` rather than a wild read.
///
/// # Safety
///
/// `size` must point to `dim` readable `int`s, or be null.
unsafe fn shape(dim: c_int, size: *mut c_int) -> String {
    if dim <= 0 {
        return "scalar".to_string();
    }
    if size.is_null() {
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

/// Defines the `al_read_data` symbol the crate above declares, but only under `cargo
/// test`: a `staticlib` crate's unit-test binary is linked on its own, with no al-core
/// to resolve against. Standing in for it also buys the one test that matters most —
/// that a call really does travel Fortran-shaped arguments through the shim and back.
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
        }
    }

    /// The shim's actual job: pass the arguments through untouched, hand back the status
    /// it was given, and count the call. Runs with tracing on so both trace branches —
    /// success and failure — are executed rather than merely compiled; the only test that
    /// touches `IMAS_MW_TRACE`, so initialising the `OnceLock` here races with nothing.
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
                DATA_TYPE_0 + 2,
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
    }
}
