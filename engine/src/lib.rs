//! `imas-projection-engine`: same-major DD projection-engine substrate.
//!
//! This crate started as the skeleton described by IMAS-Fortran issue #20:
//! the smallest callable Rust substrate behind a narrow C ABI. Issue #21
//! added the first real capability on top of it: acquiring a validated
//! same-major stored/working DD schema pair as an opaque, releasable
//! [`Map`] handle. Issue #22 adds process-wide reuse of that validated
//! pair (see [`cache`]): reacquiring the same pair, including with the
//! stored/working roles swapped, returns a handle backed by the one
//! cached pair instead of reparsing and revalidating it. Issue #28 bounds
//! that cache with a deterministic LRU eviction policy (see [`cache`]'s
//! "Bound and LRU eviction" documentation): eviction only ever drops the
//! cache's own reference, so a live [`Map`] handle is never invalidated by
//! it. Issue #31 adds the operation lifecycle: an [`Operation`] is begun
//! against one acquired [`Map`] handle and carries its own reset/end/
//! release lifecycle, isolated from every other live operation or map.
//! Issue #23 adds the first real per-node projection verdicts (see
//! [`projection`]): each schema is indexed by `field/@path`, and
//! [`project_node`] classifies a node relative to that reciprocal index
//! for the classifications that need no rename metadata (same, compiled-
//! only/stored-only, datatype-changed) while holding any rename-tagged
//! node in the distinct [`projection::Classification::RenamePending`]
//! state. Full rename resolution is issue #24 (leaf, successive history)
//! and issue #25 (array-of-structures, plain-structure, cascade).
//!
//! All `unsafe` code is confined to the [`ffi`] module; this module,
//! [`status`], [`schema`], [`version`], [`cache`], and [`projection`] are
//! safe Rust, enforced by `#![deny(unsafe_code)]` below (overridden
//! locally by `ffi`, the only place that needs it).
#![deny(unsafe_code)]

pub mod cache;
pub mod ffi;
pub mod projection;
pub mod schema;
pub mod status;
pub mod version;

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};

pub use projection::Classification;
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
    /// Backed by [`cache::CachedPair::id`], a monotonic counter assigned
    /// once per built pair, rather than the pair's address: issue #28's
    /// bounded LRU cache can evict and later deallocate an entry, after
    /// which a later, unrelated pair's allocation could reuse the same
    /// address. A monotonic counter cannot alias that way, so two live
    /// `Map`s only ever report equal identities when they share the same
    /// still-referenced pair, evicted or not.
    pub fn cache_identity(&self) -> u64 {
        self.pair.id
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

/// Operation-scoped state, begun against one acquired [`Map`] handle (issue
/// #31). Holds an `Arc<Map>` retained at [`Operation::new`] time rather than
/// the caller's raw `pe_map_t` pointer: cloning an `Arc` only bumps a
/// refcount, so beginning an operation neither clones nor mutates the
/// immutable pair data the map handle points to. This retained reference is
/// also what lets a live operation keep working even after its own map
/// handle is released through `pe_map_release` -- see the ordering rule
/// documented on `ffi::pe_operation_begin`.
///
/// Beyond that map reference, this holds only the `ended` flag today;
/// issues #26/#27 grow the per-operation state further (loss accumulation,
/// dead-subtree tracking) without changing the ABI shape established here.
/// The mutable state is guarded by a `Mutex` because the ABI hands callers
/// a raw pointer more than one thread could hold at once -- see
/// `ffi::pe_operation_reset`/`pe_operation_end` for the thread-safety
/// posture this supports.
#[derive(Debug)]
pub struct Operation {
    map: Arc<Map>,
    state: Mutex<OperationState>,
}

#[derive(Debug, Default)]
struct OperationState {
    ended: bool,
}

/// Why an [`Operation`] lifecycle transition was refused.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OperationError {
    /// [`Operation::end`] already ran for this operation. It may still be
    /// released, but not reset or ended again.
    AlreadyEnded,
}

impl Operation {
    pub fn new(map: Arc<Map>) -> Self {
        Operation {
            map,
            state: Mutex::new(OperationState::default()),
        }
    }

    /// The map this operation was begun against.
    pub fn map(&self) -> &Arc<Map> {
        &self.map
    }

    /// Clears operation-local state back to its post-begin state
    /// deterministically, without evicting the cached immutable map behind
    /// [`Operation::map`]. Today there is no per-operation state besides
    /// the `ended` flag, which reset leaves untouched; this exists so an
    /// operation can be reused for a fresh conversion once #26/#27 add real
    /// loss/dead-subtree state to clear. Repeatable while the operation is
    /// still active; refused once [`Operation::end`] has run.
    pub fn reset(&self) -> Result<(), OperationError> {
        let mut state = self.state.lock().unwrap();
        if state.ended {
            return Err(OperationError::AlreadyEnded);
        }
        *state = OperationState::default();
        Ok(())
    }

    /// Finalizes operation-local state, without evicting the cached
    /// immutable map behind [`Operation::map`]. A one-time transition: an
    /// already-ended operation refuses a second `end`, mirroring how a
    /// [`Map`] handle refuses a second release. An ended operation may
    /// still be released.
    pub fn end(&self) -> Result<(), OperationError> {
        let mut state = self.state.lock().unwrap();
        if state.ended {
            return Err(OperationError::AlreadyEnded);
        }
        state.ended = true;
        Ok(())
    }
}

/// Which schema in a [`Map`] pair plays the query's source for one
/// [`project_node`] call, so reciprocal behaviour is drivable through the
/// ABI rather than only inferable from which endpoint was acquired as
/// stored vs. working (issue #23). During real `get`/`put`, the compiled
/// working version always drives the walk, so production callers always
/// use `WorkingToStored`; `StoredToWorking` exists so either endpoint can
/// be exercised as source for direct contract testing (see #18's "Context
/// model and query semantics"). Crosses the ABI as a raw `i32` and is
/// validated the same way as [`MapRole`]/[`PeStatus`]: an out-of-range
/// value is rejected instead of being transmuted into an invalid enum.
#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeDirection {
    WorkingToStored = 0,
    StoredToWorking = 1,
}

impl PeDirection {
    pub fn from_raw(raw: i32) -> Option<Self> {
        match raw {
            0 => Some(PeDirection::WorkingToStored),
            1 => Some(PeDirection::StoredToWorking),
            _ => None,
        }
    }
}

/// Process-wide counter of projection-node entries, reset/read through the
/// ABI so a same-version Fortran I/O path can prove the engine was never
/// entered (see #18 user story 16).
static PROJECTION_ENTRY_COUNT: AtomicU64 = AtomicU64::new(0);

/// Records one projection-node entry and classifies `node_path` relative
/// to `map`'s two field indices, read in the order `direction` selects
/// (issue #23). Returns `None` when `node_path` is not known to the
/// selected source schema at all; `ffi::pe_project_node_query` treats that
/// as an invalid argument. The counter increments regardless of whether a
/// classification is found, matching "entered" rather than "resolved" --
/// the same gate the skeleton this replaces already used.
pub fn project_node(map: &Map, direction: PeDirection, node_path: &str) -> Option<Classification> {
    PROJECTION_ENTRY_COUNT.fetch_add(1, Ordering::SeqCst);
    let (source, target) = match direction {
        PeDirection::WorkingToStored => (map.working(), map.stored()),
        PeDirection::StoredToWorking => (map.stored(), map.working()),
    };
    projection::classify(source.field_index(), target.field_index(), node_path)
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

    const V_INSTR_STORED: &str =
        "<IDSs><version>50.1.0</version><field name=\"a\" path=\"a\" data_type=\"INT_0D\"/></IDSs>";
    const V_INSTR_WORKING: &str =
        "<IDSs><version>50.0.9</version><field name=\"a\" path=\"a\" data_type=\"INT_0D\"/></IDSs>";

    #[test]
    fn entry_increments_and_reset_zeroes_the_counter() {
        let _guard = SEQUENTIAL.lock().unwrap();
        let map = acquire_map(V_INSTR_STORED, "50.1.0", V_INSTR_WORKING, "50.0.9").unwrap();
        instrumentation_reset();
        assert_eq!(instrumentation_read(), 0);
        assert_eq!(
            project_node(&map, PeDirection::WorkingToStored, "a"),
            Some(Classification::Same)
        );
        assert_eq!(
            project_node(&map, PeDirection::WorkingToStored, "a"),
            Some(Classification::Same)
        );
        assert_eq!(instrumentation_read(), 2);
        instrumentation_reset();
        assert_eq!(instrumentation_read(), 0);
    }

    #[test]
    fn entry_still_increments_when_the_path_is_unknown_to_the_source_schema() {
        let _guard = SEQUENTIAL.lock().unwrap();
        let map = acquire_map(V_INSTR_STORED, "50.1.0", V_INSTR_WORKING, "50.0.9").unwrap();
        instrumentation_reset();
        assert_eq!(
            project_node(&map, PeDirection::WorkingToStored, "does/not/exist"),
            None
        );
        assert_eq!(instrumentation_read(), 1);
        instrumentation_reset();
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

/// [`Operation`] lifecycle tests (issue #31's acceptance criteria) below
/// the ABI: begin ties an operation to one map without touching its
/// immutable data, reset/end/release follow the documented state machine,
/// and simultaneous operations against the same or different maps stay
/// isolated.
#[cfg(test)]
mod operation_tests {
    use super::*;

    const V10_1_0: &str = "<IDSs><version>10.1.0</version></IDSs>";
    const V10_0_9: &str = "<IDSs><version>10.0.9</version></IDSs>";
    const V11_1_0: &str = "<IDSs><version>11.1.0</version></IDSs>";
    const V11_0_9: &str = "<IDSs><version>11.0.9</version></IDSs>";

    #[test]
    fn begin_retains_the_map_it_was_begun_against() {
        let map = acquire_map(V10_1_0, "10.1.0", V10_0_9, "10.0.9").unwrap();
        let identity = map.cache_identity();
        let operation = Operation::new(Arc::new(map));
        assert_eq!(operation.map().cache_identity(), identity);
    }

    #[test]
    fn reset_is_repeatable_while_active() {
        let map = acquire_map(V10_1_0, "10.1.0", V10_0_9, "10.0.9").unwrap();
        let operation = Operation::new(Arc::new(map));
        assert_eq!(operation.reset(), Ok(()));
        assert_eq!(operation.reset(), Ok(()));
    }

    #[test]
    fn end_is_a_one_time_transition() {
        let map = acquire_map(V10_1_0, "10.1.0", V10_0_9, "10.0.9").unwrap();
        let operation = Operation::new(Arc::new(map));
        assert_eq!(operation.end(), Ok(()));
        assert_eq!(operation.end(), Err(OperationError::AlreadyEnded));
    }

    #[test]
    fn reset_after_end_is_refused() {
        let map = acquire_map(V10_1_0, "10.1.0", V10_0_9, "10.0.9").unwrap();
        let operation = Operation::new(Arc::new(map));
        operation.end().unwrap();
        assert_eq!(operation.reset(), Err(OperationError::AlreadyEnded));
    }

    #[test]
    fn several_operations_against_one_map_stay_independent() {
        let map = Arc::new(acquire_map(V10_1_0, "10.1.0", V10_0_9, "10.0.9").unwrap());
        let first = Operation::new(map.clone());
        let second = Operation::new(map.clone());

        first.end().unwrap();

        // Ending `first` must not affect `second`'s independent state.
        assert_eq!(second.reset(), Ok(()));
        assert_eq!(second.end(), Ok(()));
    }

    #[test]
    fn operations_against_different_maps_stay_independent() {
        let map_one = Arc::new(acquire_map(V10_1_0, "10.1.0", V10_0_9, "10.0.9").unwrap());
        let map_two = Arc::new(acquire_map(V11_1_0, "11.1.0", V11_0_9, "11.0.9").unwrap());
        let one = Operation::new(map_one.clone());
        let two = Operation::new(map_two.clone());

        assert_ne!(one.map().cache_identity(), two.map().cache_identity());

        one.end().unwrap();
        assert_eq!(two.reset(), Ok(()));
    }

    #[test]
    fn an_operation_keeps_its_map_alive_after_the_only_other_handle_is_dropped() {
        let map = acquire_map(V11_1_0, "11.1.0", V11_0_9, "11.0.9").unwrap();
        let identity = map.cache_identity();
        let operation = Operation::new(Arc::new(map));

        // No other live `Map` handle remains, mirroring `pe_map_release`
        // removing the ABI's own registry entry: the operation's retained
        // `Arc<Map>` is the only thing keeping the pair alive, and it must
        // still resolve correctly.
        assert_eq!(operation.map().cache_identity(), identity);
        assert_eq!(
            operation.map().stored().version(),
            DdVersion::parse("11.1.0").unwrap()
        );
    }
}
