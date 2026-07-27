//! `imas-projection-engine`: same-major DD projection-engine substrate.
//!
//! This crate started as the skeleton described by IMAS-Fortran issue #20:
//! the smallest callable Rust substrate behind a narrow C ABI. Issue #21
//! added the first real capability on top of it: acquiring a validated
//! same-major stored/working DD schema pair as an opaque, releasable
//! [`Map`] handle. Issue #22 adds process-wide reuse of that validated
//! pair (see [`cache`]): reacquiring the same pair, including with the
//! stored/working roles swapped, returns a handle backed by the one
//! cached pair instead of reparsing and revalidating it. It still does
//! not build rename maps or compute real per-node projection verdicts --
//! see issue #23 for that.
//!
//! All `unsafe` code is confined to the [`ffi`] module; this module,
//! [`status`], [`schema`], [`version`], and [`cache`] are safe Rust,
//! enforced by `#![deny(unsafe_code)]` below (overridden locally by
//! `ffi`, the only place that needs it).
#![deny(unsafe_code)]

pub mod cache;
pub mod ffi;
pub mod schema;
pub mod status;
pub mod version;

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;

pub use schema::{ParsedSchema, SchemaError};
pub use status::{PeStatus, PeVerdict};
pub use version::DdVersion;

/// A caller handle over a validated stored/working DD schema pair (issue
/// #21). Two `Map`s acquired for the same underlying pair content, even
/// with roles swapped, share the same cached `Arc<cache::CachedPair>`
/// (issue #22): each holds its own `stored_is_first` so it still resolves
/// [`Map::stored`]/[`Map::working`] to the roles its own caller asked
/// for, independent of how another handle addresses the same shared data
/// or when another handle referring to it is released.
#[derive(Debug)]
pub struct Map {
    pair: Arc<cache::CachedPair>,
    stored_is_first: bool,
}

impl Map {
    fn slot(&self, want_first: bool) -> &ParsedSchema {
        if want_first {
            &self.pair.first
        } else {
            &self.pair.second
        }
    }

    pub fn stored(&self) -> &ParsedSchema {
        self.slot(self.stored_is_first)
    }

    pub fn working(&self) -> &ParsedSchema {
        self.slot(!self.stored_is_first)
    }

    /// An opaque numeric identity for the cached pair backing this
    /// handle: equal for any two `Map`s acquired for the same underlying
    /// schema-pair content (regardless of caller role order), and
    /// different across distinct pairs. Exists so cache reuse can be
    /// proven at the C ABI (`pe_map_cache_identity`) without exposing any
    /// Rust collection layout -- it carries no meaning beyond equality
    /// comparison and must not be interpreted as a real address by a
    /// caller.
    ///
    /// Implementation note: today this is literally `Arc::as_ptr`, sound
    /// only because this slice's cache never evicts or deallocates an
    /// entry once inserted (see `cache`'s module docs), so two live `Arc`s
    /// can never disagree on equality due to address reuse. Issue #28's
    /// bounded LRU eviction changes that precondition -- a future
    /// implementation backing this method must keep identities unique
    /// for the process lifetime (e.g. a monotonic per-entry counter
    /// stored alongside the pair) rather than relying on the pointer
    /// once entries can be freed and reallocated.
    pub fn cache_identity(&self) -> u64 {
        Arc::as_ptr(&self.pair) as u64
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

/// Acquires a [`Map`] for `stored`/`working`, reusing the process-wide
/// cached pair for this identity (issue #22) when one already exists.
///
/// On a cache hit, neither schema is reparsed or revalidated: the cached,
/// previously validated pair is shared as-is, and `stored`/`working` here
/// resolve purely by matching this call's content against the cached
/// pair's normalized slots (see [`cache::lookup`]). On a miss, both
/// schemas are parsed and identity-validated as before, the pair is
/// rejected for disagreeing major versions exactly as before, and only a
/// pair that fully validates is inserted into the cache.
///
/// `stored`/`working` are caller-assigned roles, not an ordering by DD
/// version: both are parsed through the identical
/// [`schema::parse_and_resolve`] path regardless of which one is
/// semantically older or curated, so the algorithm is uniform regardless
/// of which endpoint plays which role (see issue #21's acceptance
/// criteria). Reversing the roles across two calls for otherwise-identical
/// content reuses the same cached pair (see issue #22's acceptance
/// criteria).
pub fn acquire_map(
    stored_xml: &str,
    stored_claimed_version: &str,
    working_xml: &str,
    working_claimed_version: &str,
) -> Result<Map, AcquireError> {
    let stored_key = cache::SchemaKey::new(stored_claimed_version, stored_xml);
    let working_key = cache::SchemaKey::new(working_claimed_version, working_xml);

    if let Some((pair, stored_is_first)) = cache::lookup(&stored_key, &working_key) {
        return Ok(Map {
            pair,
            stored_is_first,
        });
    }

    let stored = schema::parse_and_resolve(stored_xml, stored_claimed_version)
        .map_err(|_| AcquireError::Identity)?;
    let working = schema::parse_and_resolve(working_xml, working_claimed_version)
        .map_err(|_| AcquireError::Identity)?;

    if stored.version().major() != working.version().major() {
        return Err(AcquireError::CrossMajor);
    }

    let (pair, stored_is_first) = cache::insert(stored_key, stored, working_key, working);
    Ok(Map {
        pair,
        stored_is_first,
    })
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

/// End-to-end cache-reuse tests through the public `acquire_map` API
/// (issue #22's acceptance criteria). Each test uses its own dedicated
/// version range so it cannot collide with `acquire_map_tests` above or
/// with another test in this module running concurrently against the
/// same process-wide cache.
#[cfg(test)]
mod cache_reuse_tests {
    use super::*;

    const V6_1_0: &str = "<IDSs><version>6.1.0</version></IDSs>";
    const V6_0_9: &str = "<IDSs><version>6.0.9</version></IDSs>";
    const V6_2_0: &str = "<IDSs><version>6.2.0</version></IDSs>";
    const V6_1_9: &str = "<IDSs><version>6.1.9</version></IDSs>";

    #[test]
    fn reacquiring_the_same_pair_reuses_the_cached_entry() {
        let first = acquire_map(V6_1_0, "6.1.0", V6_0_9, "6.0.9").unwrap();
        let second = acquire_map(V6_1_0, "6.1.0", V6_0_9, "6.0.9").unwrap();
        assert_eq!(first.cache_identity(), second.cache_identity());
    }

    #[test]
    fn reacquiring_with_reversed_roles_reuses_the_cached_entry_and_keeps_roles_correct() {
        let forward = acquire_map(V6_2_0, "6.2.0", V6_1_9, "6.1.9").unwrap();
        let reversed = acquire_map(V6_1_9, "6.1.9", V6_2_0, "6.2.0").unwrap();

        assert_eq!(forward.cache_identity(), reversed.cache_identity());
        assert_eq!(forward.stored().version(), reversed.working().version());
        assert_eq!(forward.working().version(), reversed.stored().version());
    }

    #[test]
    fn different_pairs_get_different_cache_identities_and_do_not_affect_each_other() {
        const V7_1_0: &str = "<IDSs><version>7.1.0</version></IDSs>";
        const V7_0_9: &str = "<IDSs><version>7.0.9</version></IDSs>";
        const V7_2_0: &str = "<IDSs><version>7.2.0</version></IDSs>";
        const V7_1_9: &str = "<IDSs><version>7.1.9</version></IDSs>";

        let pair_one = acquire_map(V7_1_0, "7.1.0", V7_0_9, "7.0.9").unwrap();
        let pair_two = acquire_map(V7_2_0, "7.2.0", V7_1_9, "7.1.9").unwrap();

        assert_ne!(pair_one.cache_identity(), pair_two.cache_identity());
        assert_eq!(
            pair_one.stored().version(),
            DdVersion::parse("7.1.0").unwrap()
        );
        assert_eq!(
            pair_two.stored().version(),
            DdVersion::parse("7.2.0").unwrap()
        );
    }

    #[test]
    fn dropping_one_handle_does_not_invalidate_another_live_handle_to_the_same_pair() {
        const V8_1_0: &str = "<IDSs><version>8.1.0</version></IDSs>";
        const V8_0_9: &str = "<IDSs><version>8.0.9</version></IDSs>";

        let kept = acquire_map(V8_1_0, "8.1.0", V8_0_9, "8.0.9").unwrap();
        let transient = acquire_map(V8_1_0, "8.1.0", V8_0_9, "8.0.9").unwrap();
        let transient_identity = transient.cache_identity();
        drop(transient);

        assert_eq!(kept.cache_identity(), transient_identity);
        assert_eq!(kept.stored().version(), DdVersion::parse("8.1.0").unwrap());
        assert_eq!(kept.working().version(), DdVersion::parse("8.0.9").unwrap());
    }

    #[test]
    fn concurrent_acquisition_of_the_same_pair_from_multiple_threads_converges_on_one_entry() {
        const V9_1_0: &str = "<IDSs><version>9.1.0</version></IDSs>";
        const V9_0_9: &str = "<IDSs><version>9.0.9</version></IDSs>";

        let handles: Vec<_> = (0..8)
            .map(|_| std::thread::spawn(|| acquire_map(V9_1_0, "9.1.0", V9_0_9, "9.0.9").unwrap()))
            .collect();

        let maps: Vec<Map> = handles.into_iter().map(|h| h.join().unwrap()).collect();
        let identity = maps[0].cache_identity();
        for map in &maps[1..] {
            assert_eq!(map.cache_identity(), identity);
        }
    }
}
