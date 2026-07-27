//! `imas-projection-engine`: same-major DD projection-engine substrate.
//!
//! This crate is the skeleton described by IMAS-Fortran issue #20: the
//! smallest callable Rust substrate behind a narrow C ABI. It establishes
//! the opaque handle, status/verdict vocabulary, string-ownership
//! convention, and projection-entry instrumentation that later slices
//! (issue #21 and the full #18 design) build on. It deliberately does not
//! parse XML, build rename maps, or compute real projection verdicts yet.
//!
//! All `unsafe` code is confined to the [`ffi`] module; this module and
//! [`status`] are safe Rust, enforced by `#![deny(unsafe_code)]` below
//! (overridden locally by `ffi`, the only place that needs it).
#![deny(unsafe_code)]

pub mod ffi;
pub mod status;

use std::sync::atomic::{AtomicU64, Ordering};

pub use status::{PeStatus, PeVerdict};

/// Operation-scoped state. Empty today; issue #21 grows this to hold
/// per-operation loss/dead-subtree tracking without changing the ABI shape
/// established here (an opaque pointer the caller begins/ends).
#[derive(Debug, Default)]
pub struct Operation {
    _private: (),
}

impl Operation {
    pub fn new() -> Self {
        Operation { _private: () }
    }
}

/// Process-wide counter of projection-node entries, reset/read through the
/// ABI so a same-version Fortran I/O path can prove the engine was never
/// entered (see #18 user story 16).
static PROJECTION_ENTRY_COUNT: AtomicU64 = AtomicU64::new(0);

/// Records one projection-node entry and returns the placeholder verdict.
/// Real rename/skip logic replaces this body in a later slice; the
/// counter semantics established here do not change.
pub fn project_node_entry() -> PeVerdict {
    PROJECTION_ENTRY_COUNT.fetch_add(1, Ordering::SeqCst);
    PeVerdict::Same
}

pub fn instrumentation_reset() {
    PROJECTION_ENTRY_COUNT.store(0, Ordering::SeqCst);
}

pub fn instrumentation_read() -> u64 {
    PROJECTION_ENTRY_COUNT.load(Ordering::SeqCst)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test_helper::SEQUENTIAL;

    #[test]
    fn entry_increments_and_reset_zeroes_the_counter() {
        let _guard = SEQUENTIAL.lock().unwrap();
        instrumentation_reset();
        assert_eq!(instrumentation_read(), 0);
        assert_eq!(project_node_entry(), PeVerdict::Same);
        assert_eq!(project_node_entry(), PeVerdict::Same);
        assert_eq!(instrumentation_read(), 2);
        instrumentation_reset();
        assert_eq!(instrumentation_read(), 0);
    }

    /// The counter is a process-wide `static`, so tests that touch it must
    /// not interleave; `cargo test` runs unit tests on multiple threads by
    /// default.
    mod serial_test_helper {
        use std::sync::Mutex;
        pub static SEQUENTIAL: Mutex<()> = Mutex::new(());
    }
}
