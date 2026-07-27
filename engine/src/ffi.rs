//! Narrow C ABI. Every entry point here:
//! - validates its raw-pointer/length inputs and returns a [`PeStatus`]
//!   instead of assuming they are well-formed;
//! - is wrapped in [`guard`], which contains any Rust panic and turns it
//!   into `PeStatus::Internal` instead of unwinding across the FFI
//!   boundary (unwinding across an `extern "C"` boundary is undefined
//!   behaviour).
//!
//! This is the only module in the crate allowed to contain `unsafe` code
//! (see the crate-level `#![deny(unsafe_code)]` in `lib.rs`).
#![allow(unsafe_code)]

use std::os::raw::c_char;
use std::panic::{self, AssertUnwindSafe};
use std::sync::Once;

use crate::status::{PeStatus, PeVerdict};
use crate::Operation;

static INSTALL_PANIC_HOOK: Once = Once::new();

/// Installs a silent panic hook exactly once. Every entry point below
/// already turns a caught panic into `PeStatus::Internal` without
/// unwinding, but the default hook still writes a message to stderr first
/// (e.g. `assertion failed: ...`), which could contain a word this repo's
/// CTest harness treats as a failure marker even though the process
/// itself reports success. See `engine/README.md` for the full
/// negative-path wording convention.
///
/// Skipped under `cargo test`: the panic hook is process-global, and a
/// unit test deliberately triggering a panic (see `tests::
/// guard_contains_a_panic_as_internal_status` below) would otherwise
/// silence the default panic message for every other test sharing the
/// same test binary. Real ABI consumers never compile with `cfg(test)`.
fn ensure_panic_hook_installed() {
    if cfg!(test) {
        return;
    }
    INSTALL_PANIC_HOOK.call_once(|| {
        panic::set_hook(Box::new(|_info| {}));
    });
}

/// Runs `f`, containing any panic as `PeStatus::Internal`. `f` must not
/// unwind past this call in any other way.
fn guard<F>(f: F) -> PeStatus
where
    F: FnOnce() -> PeStatus,
{
    ensure_panic_hook_installed();
    panic::catch_unwind(AssertUnwindSafe(f)).unwrap_or(PeStatus::Internal)
}

/// Writes `text` into a caller-provided buffer.
///
/// This is the crate's one returned-string ownership convention, used for
/// every string the ABI hands back (today, only diagnostic status text):
/// the caller owns and provides the buffer; the engine never returns an
/// engine-owned pointer the caller must later free.
///
/// `required_len` (when non-null) is always set to the length of `text`
/// in bytes, excluding the NUL terminator, regardless of whether `buffer`
/// was large enough. Pass `buffer = NULL` or `buffer_len = 0` to query
/// `required_len` first, then call again with a buffer of at least
/// `required_len + 1` bytes. If `buffer` is non-null but too small, the
/// text is truncated and still NUL-terminated, and the status is
/// `BufferTooSmall`.
///
/// # Safety
/// `buffer` must be either null or a valid pointer to at least
/// `buffer_len` writable bytes. `required_len` must be either null or a
/// valid pointer to one writable `usize`.
unsafe fn write_str_to_buffer(
    text: &str,
    buffer: *mut c_char,
    buffer_len: usize,
    required_len: *mut usize,
) -> PeStatus {
    let bytes = text.as_bytes();
    if !required_len.is_null() {
        unsafe {
            *required_len = bytes.len();
        }
    }
    if buffer.is_null() || buffer_len == 0 {
        return PeStatus::Ok;
    }
    let copy_len = bytes.len().min(buffer_len - 1);
    let dst = buffer.cast::<u8>();
    unsafe {
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), dst, copy_len);
        *dst.add(copy_len) = 0;
    }
    if copy_len < bytes.len() {
        PeStatus::BufferTooSmall
    } else {
        PeStatus::Ok
    }
}

/// Begins operation-scoped state, foreshadowing the loss/dead-subtree
/// state issue #21 adds without changing this handle shape. Returns the
/// new handle through `out_operation`.
///
/// # Safety
/// `out_operation` must be either null or a valid pointer to one writable
/// `*mut Operation`.
#[no_mangle]
pub unsafe extern "C" fn pe_operation_begin(out_operation: *mut *mut Operation) -> PeStatus {
    guard(|| {
        if out_operation.is_null() {
            return PeStatus::InvalidArgument;
        }
        let boxed = Box::new(Operation::new());
        unsafe {
            *out_operation = Box::into_raw(boxed);
        }
        PeStatus::Ok
    })
}

/// Ends operation-scoped state and releases `operation`. Never evicts the
/// (not yet implemented) cached immutable map.
///
/// # Safety
/// `operation` must be either null or a handle previously returned by
/// [`pe_operation_begin`] that has not already been passed to this
/// function.
#[no_mangle]
pub unsafe extern "C" fn pe_operation_end(operation: *mut Operation) -> PeStatus {
    guard(|| {
        if operation.is_null() {
            return PeStatus::NullHandle;
        }
        unsafe {
            drop(Box::from_raw(operation));
        }
        PeStatus::Ok
    })
}

/// Representative "project node" entry point. This is a placeholder: it
/// validates its inputs, records one projection-entry instrumentation
/// tick, and always reports `PeVerdict::Same`. Issue #21 replaces the
/// verdict computation with real rename/skip map lookups; the ABI shape
/// (handle, borrowed path, out-verdict) does not need to change to do so.
///
/// `node_path` is borrowed for the duration of this call only; it need
/// not be NUL-terminated since its length is given explicitly.
///
/// # Safety
/// `node_path` must be either null or a valid pointer to at least
/// `node_path_len` readable bytes. `out_verdict` must be either null or a
/// valid pointer to one writable `PeVerdict`.
#[no_mangle]
pub unsafe extern "C" fn pe_project_node_query(
    operation: *mut Operation,
    node_path: *const c_char,
    node_path_len: usize,
    out_verdict: *mut PeVerdict,
) -> PeStatus {
    guard(|| {
        if operation.is_null() {
            return PeStatus::NullHandle;
        }
        if node_path.is_null() || node_path_len == 0 {
            return PeStatus::InvalidArgument;
        }
        if out_verdict.is_null() {
            return PeStatus::InvalidArgument;
        }
        let verdict = crate::project_node_entry();
        unsafe {
            *out_verdict = verdict;
        }
        PeStatus::Ok
    })
}

/// Zeroes the process-wide projection-entry counter.
#[no_mangle]
pub extern "C" fn pe_instrumentation_reset() -> PeStatus {
    guard(|| {
        crate::instrumentation_reset();
        PeStatus::Ok
    })
}

/// Reads the process-wide projection-entry counter.
///
/// # Safety
/// `out_count` must be either null or a valid pointer to one writable
/// `u64`.
#[no_mangle]
pub unsafe extern "C" fn pe_instrumentation_read(out_count: *mut u64) -> PeStatus {
    guard(|| {
        if out_count.is_null() {
            return PeStatus::InvalidArgument;
        }
        let count = crate::instrumentation_read();
        unsafe {
            *out_count = count;
        }
        PeStatus::Ok
    })
}

/// Returns stable diagnostic text for `status` via the buffer convention
/// documented on [`write_str_to_buffer`]. This is the crate's
/// representative diagnostic call.
///
/// `status` is accepted as a raw `i32` rather than `PeStatus` on purpose:
/// a C caller can pass any integer as a `pe_status_t`, and transmuting an
/// out-of-range value directly into a Rust enum is undefined behaviour
/// even though both are declared `#[repr(i32)]`. An unrecognized value is
/// rejected here as `PeStatus::InvalidArgument` instead.
///
/// # Safety
/// `buffer` must be either null or a valid pointer to at least
/// `buffer_len` writable bytes. `required_len` must be either null or a
/// valid pointer to one writable `usize`.
#[no_mangle]
pub unsafe extern "C" fn pe_status_message(
    status: i32,
    buffer: *mut c_char,
    buffer_len: usize,
    required_len: *mut usize,
) -> PeStatus {
    guard(|| {
        let known = match PeStatus::from_raw(status) {
            Some(known) => known,
            None => return PeStatus::InvalidArgument,
        };
        unsafe { write_str_to_buffer(known.message(), buffer, buffer_len, required_len) }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Proves the containment `guard()` provides for every ABI entry above:
    /// a genuine Rust panic must come back as `PeStatus::Internal`, not
    /// unwind out of the call. This is what makes it safe for every
    /// `extern "C"` function here to state that guarantee in its doc
    /// comment without a C-level test having to induce a real panic.
    #[test]
    fn guard_contains_a_panic_as_internal_status() {
        let status = guard(|| panic!("deliberate panic for containment test"));
        assert_eq!(status, PeStatus::Internal);
    }

    #[test]
    fn guard_passes_through_a_normal_status() {
        let status = guard(|| PeStatus::Ok);
        assert_eq!(status, PeStatus::Ok);
    }
}
