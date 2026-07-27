//! `imas-projection-engine`: same-major DD projection-engine substrate.
//!
//! This crate started as the skeleton described by IMAS-Fortran issue #20:
//! the smallest callable Rust substrate behind a narrow C ABI. Issue #21
//! adds the first real capability on top of it: acquiring a validated
//! same-major stored/working DD schema pair as an opaque, releasable
//! [`Map`] handle. It still does not build rename maps, compute real
//! per-node projection verdicts, or cache maps across acquisitions -- see
//! issues #22 and #23 for those.
//!
//! All `unsafe` code is confined to the [`ffi`] module; this module,
//! [`status`], [`schema`], and [`version`] are safe Rust, enforced by
//! `#![deny(unsafe_code)]` below (overridden locally by `ffi`, the only
//! place that needs it).
#![deny(unsafe_code)]

pub mod ffi;
pub mod schema;
pub mod status;
pub mod version;

use std::sync::atomic::{AtomicU64, Ordering};

pub use schema::{ParsedSchema, SchemaError};
pub use status::{PeStatus, PeVerdict};
pub use version::DdVersion;

/// A validated stored/working DD schema pair (issue #21). Reusing this
/// across acquisitions for the same pair identity instead of rebuilding it
/// is issue #22's job; this slice always builds a fresh `Map`.
#[derive(Debug)]
pub struct Map {
    stored: ParsedSchema,
    working: ParsedSchema,
}

impl Map {
    pub fn stored(&self) -> &ParsedSchema {
        &self.stored
    }

    pub fn working(&self) -> &ParsedSchema {
        &self.working
    }
}

/// Which schema in a [`Map`] pair to address. Crosses the ABI as a raw
/// `i32` and is validated the same way as [`PeStatus`] (see
/// [`PeStatus::from_raw`]): an out-of-range value is rejected instead of
/// being transmuted into an invalid enum.
#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MapRole {
    Stored = 0,
    Working = 1,
}

impl MapRole {
    pub fn from_raw(raw: i32) -> Option<Self> {
        match raw {
            0 => Some(MapRole::Stored),
            1 => Some(MapRole::Working),
            _ => None,
        }
    }
}

/// Why [`acquire_map`] refused to build a [`Map`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AcquireError {
    /// One or both schemas failed to parse or validate identity. See
    /// [`SchemaError`] for the specific cause; it is not distinguished
    /// further here because the ABI maps both endpoints' failures to the
    /// same `PeStatus::SchemaIdentity`.
    Identity,
    /// Both schemas parsed and validated individually, but their major DD
    /// versions differ; automatic same-major projection refuses the pair.
    CrossMajor,
}

/// Parses and identity-validates both schemas, then refuses to build a
/// [`Map`] for a cross-major pair.
///
/// `stored`/`working` are caller-assigned roles, not an ordering by DD
/// version: both are parsed through the identical
/// [`schema::parse_and_resolve`] path regardless of which one is
/// semantically older or curated, so the algorithm is uniform regardless
/// of which endpoint plays which role (see issue #21's acceptance
/// criteria).
pub fn acquire_map(
    stored_xml: &str,
    stored_claimed_version: &str,
    working_xml: &str,
    working_claimed_version: &str,
) -> Result<Map, AcquireError> {
    let stored = schema::parse_and_resolve(stored_xml, stored_claimed_version)
        .map_err(|_| AcquireError::Identity)?;
    let working = schema::parse_and_resolve(working_xml, working_claimed_version)
        .map_err(|_| AcquireError::Identity)?;

    if stored.version().major() != working.version().major() {
        return Err(AcquireError::CrossMajor);
    }

    Ok(Map { stored, working })
}

/// Operation-scoped state. Empty today; issues #26/#27 grow this to hold
/// per-operation projection/loss tracking without changing the ABI shape
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

#[cfg(test)]
mod acquire_map_tests {
    use super::*;

    const V3_39_0: &str = "<IDSs><version>3.39.0</version></IDSs>";
    const V3_38_1: &str = "<IDSs><version>3.38.1</version></IDSs>";
    const V4_0_0: &str = "<IDSs><version>4.0.0</version></IDSs>";

    #[test]
    fn valid_same_major_pair_builds_a_map() {
        let map = acquire_map(V3_39_0, "3.39.0", V3_38_1, "3.38.1").unwrap();
        assert_eq!(map.stored().version(), DdVersion::parse("3.39.0").unwrap());
        assert_eq!(map.working().version(), DdVersion::parse("3.38.1").unwrap());
    }

    #[test]
    fn parsing_is_uniform_regardless_of_which_role_is_older() {
        // Same two documents, roles swapped: both directions must succeed
        // and resolve the same two versions under their new roles.
        let forward = acquire_map(V3_39_0, "3.39.0", V3_38_1, "3.38.1").unwrap();
        let reversed = acquire_map(V3_38_1, "3.38.1", V3_39_0, "3.39.0").unwrap();
        assert_eq!(forward.stored().version(), reversed.working().version());
        assert_eq!(forward.working().version(), reversed.stored().version());
    }

    #[test]
    fn malformed_xml_is_an_identity_failure() {
        let err = acquire_map(
            "<IDSs><version>3.39.0</version>",
            "3.39.0",
            V3_38_1,
            "3.38.1",
        )
        .unwrap_err();
        assert_eq!(err, AcquireError::Identity);
    }

    #[test]
    fn missing_version_with_no_valid_fallback_is_an_identity_failure() {
        let err = acquire_map("<IDSs/>", "not-a-version", V3_38_1, "3.38.1").unwrap_err();
        assert_eq!(err, AcquireError::Identity);
    }

    #[test]
    fn claimed_identity_mismatch_is_an_identity_failure() {
        let err = acquire_map(V3_39_0, "9.9.9", V3_38_1, "3.38.1").unwrap_err();
        assert_eq!(err, AcquireError::Identity);
    }

    #[test]
    fn cross_major_pair_is_rejected_distinctly_from_an_identity_failure() {
        let err = acquire_map(V3_39_0, "3.39.0", V4_0_0, "4.0.0").unwrap_err();
        assert_eq!(err, AcquireError::CrossMajor);
    }

    #[test]
    fn cross_major_check_does_not_depend_on_which_role_is_newer() {
        let err = acquire_map(V4_0_0, "4.0.0", V3_39_0, "3.39.0").unwrap_err();
        assert_eq!(err, AcquireError::CrossMajor);
    }
}
