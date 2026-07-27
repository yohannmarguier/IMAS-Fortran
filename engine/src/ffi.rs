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

use std::collections::{HashMap, HashSet};
use std::os::raw::c_char;
use std::panic::{self, AssertUnwindSafe};
use std::sync::{Arc, Mutex, Once, OnceLock};

use crate::status::{PeStatus, PeVerdict};
use crate::{AcquireError, Map, MapRole, Operation};

static INSTALL_PANIC_HOOK: Once = Once::new();

/// Addresses of operation handles that this ABI has issued and not yet
/// released. Keeping this registry lets `pe_operation_end` reject a stale,
/// foreign, or already-ended handle before it ever turns that address back
/// into a `Box`.
fn active_operations() -> &'static Mutex<HashSet<usize>> {
    static ACTIVE_OPERATIONS: OnceLock<Mutex<HashSet<usize>>> = OnceLock::new();
    ACTIVE_OPERATIONS.get_or_init(|| Mutex::new(HashSet::new()))
}

/// Live map handles issued by this ABI. Besides validating a raw handle
/// address, the registry keeps an `Arc` for each live handle so a reader can
/// clone it while holding the mutex, then safely use the `Map` after the
/// mutex is released even if another thread releases that handle meanwhile.
fn active_maps() -> &'static Mutex<HashMap<usize, Arc<Map>>> {
    static ACTIVE_MAPS: OnceLock<Mutex<HashMap<usize, Arc<Map>>>> = OnceLock::new();
    ACTIVE_MAPS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Retains the map addressed by a live ABI handle without dereferencing the
/// raw pointer. The retained `Arc` keeps the map live after a concurrent
/// `pe_map_release` removes the caller's handle from [`active_maps`].
fn retain_active_map(map: *const Map) -> Option<Arc<Map>> {
    active_maps().lock().unwrap().get(&(map as usize)).cloned()
}

/// Borrows `ptr`/`len` as `&str` for the duration of the caller's closure,
/// rejecting a null pointer, a zero length, or invalid UTF-8 by returning
/// `None`. Mirrors the null/zero-length convention `pe_project_node_query`
/// already established for its borrowed `node_path` parameter.
///
/// # Safety
/// `ptr` must be either null or a valid pointer to at least `len` readable
/// bytes.
unsafe fn borrow_str<'a>(ptr: *const c_char, len: usize) -> Option<&'a str> {
    if ptr.is_null() || len == 0 {
        return None;
    }
    let bytes = unsafe { std::slice::from_raw_parts(ptr.cast::<u8>(), len) };
    std::str::from_utf8(bytes).ok()
}

/// Borrows an optional claimed DD version. A zero-length value represents an
/// absent fallback identity and is passed through as an empty string so the
/// schema resolver can report `SchemaIdentity` when the XML has no
/// `<version>` element. A non-empty value follows the normal borrowed-string
/// validation rules.
///
/// # Safety
/// When `len` is non-zero, `ptr` must be a valid pointer to at least `len`
/// readable bytes. A null pointer is allowed only with a zero length.
unsafe fn borrow_claimed_version<'a>(ptr: *const c_char, len: usize) -> Option<&'a str> {
    if len == 0 {
        return Some("");
    }
    unsafe { borrow_str(ptr, len) }
}

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

/// Begins operation-scoped state, foreshadowing the projection/loss state
/// issues #26/#27 add without changing this handle shape. Returns the
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

        let mut active = active_operations().lock().unwrap();
        let operation = Box::into_raw(Box::new(Operation::new()));
        active.insert(operation as usize);
        unsafe {
            *out_operation = operation;
        }
        PeStatus::Ok
    })
}

/// Ends operation-scoped state and releases `operation`. Never evicts the
/// (not yet implemented) cached immutable map.
///
/// # Safety
/// A null handle returns [`PeStatus::NullHandle`]. A handle not currently
/// owned by this ABI, including one already passed to this function, returns
/// [`PeStatus::InvalidArgument`] without being dereferenced.
#[no_mangle]
pub unsafe extern "C" fn pe_operation_end(operation: *mut Operation) -> PeStatus {
    guard(|| {
        if operation.is_null() {
            return PeStatus::NullHandle;
        }

        let was_active = active_operations()
            .lock()
            .unwrap()
            .remove(&(operation as usize));
        if !was_active {
            return PeStatus::InvalidArgument;
        }
        unsafe {
            drop(Box::from_raw(operation));
        }
        PeStatus::Ok
    })
}

/// Acquires a validated same-major stored/working DD schema pair as an
/// opaque, releasable [`Map`] handle (issue #21).
///
/// `stored_xml`/`working_xml` are each parsed as UTF-8 XML; the XML
/// `<version>` element is authoritative when present, and must then agree
/// with the corresponding `*_claimed_version` string. When the element is
/// absent, `*_claimed_version` is used as the schema's version directly.
/// An invalid or fabricated identity never produces a usable handle:
/// malformed XML, a missing version with no valid fallback, or a
/// claimed/parsed mismatch on either schema all return
/// `PE_STATUS_SCHEMA_IDENTITY`. A pair that individually validates but
/// disagrees on major version returns the distinct `PE_STATUS_CROSS_MAJOR`.
/// Neither failure writes `out_map`.
///
/// `stored`/`working` are caller-assigned roles, not an ordering by DD
/// version: the same parsing and validation runs for both regardless of
/// which one is semantically older or curated.
///
/// Input ownership: all four input buffers are borrowed for the duration
/// of this call only. On success, the engine copies the bytes it needs
/// (the resolved version and a copy of each schema's XML source) into the
/// returned `Map`; none of the four input pointers is retained past this
/// call returning, and the caller may free or overwrite them immediately
/// afterwards.
///
/// # Safety
/// `stored_xml`, `stored_claimed_version`, `working_xml`, and
/// `working_claimed_version` must each be either null or a valid pointer
/// to at least their respective `*_len` readable bytes; none need be
/// NUL-terminated. `out_map` must be either null or a valid pointer to one
/// writable `*mut Map`.
#[no_mangle]
pub unsafe extern "C" fn pe_map_acquire(
    stored_xml: *const c_char,
    stored_xml_len: usize,
    stored_claimed_version: *const c_char,
    stored_claimed_version_len: usize,
    working_xml: *const c_char,
    working_xml_len: usize,
    working_claimed_version: *const c_char,
    working_claimed_version_len: usize,
    out_map: *mut *mut Map,
) -> PeStatus {
    guard(|| {
        if out_map.is_null() {
            return PeStatus::InvalidArgument;
        }
        let stored_xml = match unsafe { borrow_str(stored_xml, stored_xml_len) } {
            Some(s) => s,
            None => return PeStatus::InvalidArgument,
        };
        let stored_claimed_version = match unsafe {
            borrow_claimed_version(stored_claimed_version, stored_claimed_version_len)
        } {
            Some(s) => s,
            None => return PeStatus::InvalidArgument,
        };
        let working_xml = match unsafe { borrow_str(working_xml, working_xml_len) } {
            Some(s) => s,
            None => return PeStatus::InvalidArgument,
        };
        let working_claimed_version = match unsafe {
            borrow_claimed_version(working_claimed_version, working_claimed_version_len)
        } {
            Some(s) => s,
            None => return PeStatus::InvalidArgument,
        };

        match crate::acquire_map(
            stored_xml,
            stored_claimed_version,
            working_xml,
            working_claimed_version,
        ) {
            Ok(map) => {
                let mut active = active_maps().lock().unwrap();
                let map = Arc::new(map);
                let raw_map = Arc::into_raw(map.clone()) as *mut Map;
                active.insert(raw_map as usize, map);
                unsafe {
                    *out_map = raw_map;
                }
                PeStatus::Ok
            }
            Err(AcquireError::Identity) => PeStatus::SchemaIdentity,
            Err(AcquireError::CrossMajor) => PeStatus::CrossMajor,
        }
    })
}

/// Releases a map handle returned by [`pe_map_acquire`].
///
/// # Safety
/// A null handle returns [`PeStatus::NullHandle`]. A handle not currently
/// owned by this ABI, including one already passed to this function,
/// returns [`PeStatus::InvalidArgument`] without being dereferenced.
#[no_mangle]
pub unsafe extern "C" fn pe_map_release(map: *mut Map) -> PeStatus {
    guard(|| {
        if map.is_null() {
            return PeStatus::NullHandle;
        }

        let retained = active_maps().lock().unwrap().remove(&(map as usize));
        if retained.is_none() {
            return PeStatus::InvalidArgument;
        }
        unsafe {
            Arc::decrement_strong_count(map as *const Map);
        }
        PeStatus::Ok
    })
}

/// Reads back the resolved version string of one schema in `map`, following
/// the buffer convention documented on [`write_str_to_buffer`]. Exists so a
/// caller (including this crate's own contract test) can observe that
/// acquisition resolved and retained each schema's version correctly and
/// independently of the input buffers passed to [`pe_map_acquire`].
///
/// `role` is accepted as a raw `i32` for the same reason `pe_status_message`
/// accepts a raw status: transmuting an out-of-range value directly into a
/// Rust enum is undefined behaviour even though both are `#[repr(i32)]`. An
/// unrecognized value is rejected as `PeStatus::InvalidArgument`.
///
/// # Safety
/// `map` must be either null or a valid, still-live handle returned by
/// `pe_map_acquire`. `buffer` must be either null or a valid pointer to at
/// least `buffer_len` writable bytes. `required_len` must be either null or
/// a valid pointer to one writable `usize`.
#[no_mangle]
pub unsafe extern "C" fn pe_map_version(
    map: *const Map,
    role: i32,
    buffer: *mut c_char,
    buffer_len: usize,
    required_len: *mut usize,
) -> PeStatus {
    guard(|| {
        if map.is_null() {
            return PeStatus::NullHandle;
        }
        let map = match retain_active_map(map) {
            Some(map) => map,
            None => return PeStatus::InvalidArgument,
        };
        let role = match MapRole::from_raw(role) {
            Some(role) => role,
            None => return PeStatus::InvalidArgument,
        };

        let schema = match role {
            MapRole::Stored => map.stored(),
            MapRole::Working => map.working(),
        };
        let text = schema.version().to_string();
        unsafe { write_str_to_buffer(&text, buffer, buffer_len, required_len) }
    })
}

/// Reads back the opaque cache identity of the pair backing `map` (issue
/// #22): a numeric token equal for any two live `pe_map_t` handles
/// acquired for the same underlying stored/working schema-pair content
/// (regardless of which endpoint played which role), and different across
/// handles backed by distinct pairs. Lets a caller -- including this
/// crate's own contract test -- prove that reacquiring the same pair
/// reused the process-wide cache instead of rebuilding it, without this
/// ABI exposing any Rust `HashMap`/collection layout to do so. The value
/// carries no meaning beyond equality comparison and must not be
/// interpreted as a real memory address.
///
/// # Safety
/// `map` must be either null or a valid, still-live handle returned by
/// `pe_map_acquire`. `out_identity` must be either null or a valid
/// pointer to one writable `u64`.
#[no_mangle]
pub unsafe extern "C" fn pe_map_cache_identity(
    map: *const Map,
    out_identity: *mut u64,
) -> PeStatus {
    guard(|| {
        if map.is_null() {
            return PeStatus::NullHandle;
        }
        let map = match retain_active_map(map) {
            Some(map) => map,
            None => return PeStatus::InvalidArgument,
        };
        if out_identity.is_null() {
            return PeStatus::InvalidArgument;
        }

        unsafe {
            *out_identity = map.cache_identity();
        }
        PeStatus::Ok
    })
}

/// Representative "project node" entry point. This is a placeholder: it
/// validates its inputs, records one projection-entry instrumentation
/// tick, and always reports `PeVerdict::Same`. Issue #23 replaces the
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

    #[test]
    fn retained_map_stays_live_after_release_removes_its_raw_handle() {
        const STORED: &str = "<IDSs><version>12.1.0</version></IDSs>";
        const WORKING: &str = "<IDSs><version>12.0.9</version></IDSs>";

        let mut raw_map = std::ptr::null_mut();
        assert_eq!(
            unsafe {
                pe_map_acquire(
                    STORED.as_ptr().cast(),
                    STORED.len(),
                    c"12.1.0".as_ptr(),
                    "12.1.0".len(),
                    WORKING.as_ptr().cast(),
                    WORKING.len(),
                    c"12.0.9".as_ptr(),
                    "12.0.9".len(),
                    &mut raw_map,
                )
            },
            PeStatus::Ok
        );

        let retained = retain_active_map(raw_map).expect("new map should be live");
        assert_eq!(unsafe { pe_map_release(raw_map) }, PeStatus::Ok);
        assert!(retain_active_map(raw_map).is_none());
        assert_eq!(retained.stored().version().to_string(), "12.1.0");
    }
}
