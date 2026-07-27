//! Process-wide lazy cache of validated schema pairs (issue #22), bounded
//! by a deterministic LRU eviction policy (issue #28).
//!
//! [`crate::acquire_map`] already parses and identity-validates both
//! schemas and refuses a cross-major pair (issue #21). This module adds
//! reuse on top of that: a pair that has already been validated once is
//! never reparsed or rebuilt for a later acquisition of the same pair,
//! including one where the caller swaps which endpoint plays the stored
//! vs. working role.
//!
//! ## Identity and normalization
//!
//! A schema's cache identity is its exact input content: the XML source
//! together with the claimed version string passed alongside it (the same
//! two values [`crate::schema::parse_and_resolve`] takes). Two acquisitions
//! whose stored/working content is identical, in either role order, are the
//! same pair. The pair key is built by sorting the two schema keys into a
//! canonical order, so `(stored=X, working=Y)` and `(stored=Y, working=X)`
//! produce the identical [`PairKey`] and therefore hit the same cache
//! entry. `PairKey` and `SchemaKey` derive real `Eq`, so lookup is exact
//! content equality -- there is no hash-collision correctness risk in
//! collapsing distinct content to the same entry.
//!
//! The stored/working role is not part of the cache identity: it is
//! caller-facing bookkeeping the [`crate::Map`] handle keeps separately
//! (`stored_is_first`, alongside the shared [`CachedPair`]) so a caller
//! still observes its own requested roles even though the underlying pair
//! is shared and its internal slot order is normalized.
//!
//! ## What is cached, and what is not
//!
//! Only a pair that fully validates -- both schemas parse, both resolve an
//! identity that agrees with their claim, and the pair is same-major -- is
//! ever inserted. A malformed, misidentified, or cross-major input is
//! rejected the same way whether or not its content happens to match a
//! prior failed attempt; failures are never cached, so a caller cannot
//! observe a stale bad result and there is nothing to invalidate for them.
//!
//! ## Bound and LRU eviction (issue #28)
//!
//! The cache holds at most [`CACHE_CAPACITY`] entries. `CACHE_CAPACITY` is
//! a deliberately arbitrary, deterministic bound, not a production-tuned
//! one -- issue #18 puts sizing/throughput tuning out of scope for this
//! slice, and issue #32 is where real stress work lives. Reusing a cached
//! pair through [`lookup`] marks it as most-recently-used without
//! rebuilding it. Inserting a pair not already present that would push the
//! cache past `CACHE_CAPACITY` evicts the single least-recently-used entry
//! first (see `Cache::evict_overflow`).
//!
//! Eviction only ever drops the cache's own `Arc` reference to a
//! [`CachedPair`]; it never touches a [`crate::Map`] handle, a
//! [`crate::Operation`], or any process-wide "active" DD version, because
//! none of those live here. A `CachedPair` still referenced by a live `Map`
//! handle (or an `Operation` retaining one) survives eviction exactly as it
//! survives any other caller releasing their own handle: the cache
//! dropping its slot only decrements the `Arc` refcount, and the data stays
//! alive as long as any other `Arc` clone does. Reacquiring an evicted
//! pair's identity is indistinguishable from a cold cache: it reparses,
//! revalidates, and is inserted as a fresh entry with its own new
//! [`CachedPair::id`] (see [`crate::Map::cache_identity`]), independent of
//! every other live pair.
//!
//! ## Thread safety
//!
//! The cache is one process-wide `Mutex<Cache>`. Concurrent acquisition
//! from multiple threads is supported and requires no synchronization from
//! the caller: every lookup and insert takes the same lock for the short,
//! non-allocating-XML-parse duration of a map/hashmap operation, and the
//! expensive parse/validate work in [`crate::acquire_map`] runs outside the
//! lock, only re-taking it to record the result. Two threads racing to
//! acquire the same new pair may both pay the parse cost, but only one
//! insertion wins the cache slot (see [`insert`]); every caller still gets
//! back an `Arc` to the same single winning entry, and both parses are
//! equally valid since they parsed identical content. This crate makes no
//! throughput or lock granularity guarantee beyond "concurrent acquisition
//! is memory-safe and observably correct" -- tuning contention under heavy
//! concurrent load is explicitly out of scope here (see issue #18 and
//! #32's stress work).
use std::collections::{HashMap, VecDeque};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};

use crate::schema::ParsedSchema;

/// Deterministic, arbitrary bound on the number of distinct schema pairs
/// the process-wide cache retains at once. See the module-level "Bound and
/// LRU eviction" documentation above: this is not a production sizing
/// decision, just a fixed, documented cap so eviction behavior is
/// deterministic and testable.
pub(crate) const CACHE_CAPACITY: usize = 64;

/// The exact input content identifying one schema: its claimed version
/// string and its XML source, both owned so the key outlives the
/// caller's borrowed buffers. Two schemas with equal `SchemaKey`s are
/// treated as the same schema without re-parsing either.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub(crate) struct SchemaKey {
    claimed_version: String,
    xml: String,
}

impl SchemaKey {
    pub(crate) fn new(claimed_version: &str, xml: &str) -> Self {
        SchemaKey {
            claimed_version: claimed_version.to_string(),
            xml: xml.to_string(),
        }
    }
}

/// A normalized, order-independent identity for one schema pair: the two
/// [`SchemaKey`]s sorted into a canonical order regardless of which one
/// the caller assigned to the stored vs. working role.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct PairKey(SchemaKey, SchemaKey);

/// One validated, immutable schema pair, shared by every [`crate::Map`]
/// handle acquired for the same underlying content. `first`/`second` are
/// the pair's own canonical slot order (sorted by [`SchemaKey`]), not the
/// caller's stored/working roles -- see the module documentation.
#[derive(Debug)]
pub(crate) struct CachedPair {
    /// A process-lifetime-unique identity, assigned when this pair is
    /// built (see [`next_pair_id`]). Backs [`crate::Map::cache_identity`].
    /// A monotonic counter rather than this struct's own address is
    /// required specifically because entries can now be evicted and later
    /// reacquired (issue #28): a freed `Arc<CachedPair>`'s allocation can
    /// be reused by a later, unrelated entry, so an address-based identity
    /// could alias across an evict/reinsert cycle. A counter cannot.
    pub(crate) id: u64,
    pub(crate) first: ParsedSchema,
    pub(crate) second: ParsedSchema,
}

/// Process-lifetime-unique [`CachedPair::id`] source. Never reset, and
/// never reused even after the pair it was assigned to is evicted.
static NEXT_PAIR_ID: AtomicU64 = AtomicU64::new(1);

fn next_pair_id() -> u64 {
    NEXT_PAIR_ID.fetch_add(1, Ordering::Relaxed)
}

/// A bounded, least-recently-used cache of validated schema pairs, keyed by
/// normalized pair identity. Kept as its own type, independent of the
/// process-wide [`store`] static, so its eviction/recency logic can be
/// exercised directly against a small, freshly constructed instance in
/// tests without touching global state shared with every other test in
/// this crate (see the `lru_tests` module below).
struct Cache {
    capacity: usize,
    entries: HashMap<PairKey, Arc<CachedPair>>,
    /// Recency order, oldest (least-recently-used) at the front, newest
    /// (most-recently-used) at the back. Kept as a separate structure
    /// rather than an ordered map because plain `HashMap` lookup/insert
    /// stays O(1); `touch`/`evict_overflow` are O(n) in the number of
    /// cached entries, which is acceptable since this cache is bounded by
    /// [`CACHE_CAPACITY`] and throughput tuning is explicitly out of scope
    /// (see the module-level "Thread safety" documentation).
    recency: VecDeque<PairKey>,
}

impl Cache {
    fn new(capacity: usize) -> Self {
        Cache {
            capacity,
            entries: HashMap::new(),
            recency: VecDeque::new(),
        }
    }

    /// Marks `key` as most-recently-used. A no-op if `key` is not
    /// currently tracked (nothing to touch).
    fn touch(&mut self, key: &PairKey) {
        if let Some(pos) = self.recency.iter().position(|tracked| tracked == key) {
            let key = self.recency.remove(pos).expect("position was just found");
            self.recency.push_back(key);
        }
    }

    /// Looks up `key`, marking it most-recently-used on a hit.
    fn get(&mut self, key: &PairKey) -> Option<Arc<CachedPair>> {
        let hit = self.entries.get(key).cloned();
        if hit.is_some() {
            self.touch(key);
        }
        hit
    }

    /// Records `pair` under `key` as the most-recently-used entry, unless
    /// `key` is already present -- in which case the existing entry wins
    /// (see [`insert`]'s doc comment on the concurrent-insert race this
    /// guards) and is itself marked most-recently-used instead. Evicts the
    /// least-recently-used entry first if inserting a new key would push
    /// the cache past its capacity.
    fn insert(&mut self, key: PairKey, pair: Arc<CachedPair>) -> Arc<CachedPair> {
        if let Some(existing) = self.entries.get(&key) {
            let existing = existing.clone();
            self.touch(&key);
            return existing;
        }
        self.entries.insert(key.clone(), pair.clone());
        self.recency.push_back(key);
        self.evict_overflow();
        pair
    }

    /// Evicts least-recently-used entries until the cache is back at or
    /// under capacity. Only ever removes the cache's own `Arc` reference;
    /// see the module-level "Bound and LRU eviction" documentation for why
    /// that alone can never invalidate a live caller handle.
    fn evict_overflow(&mut self) {
        while self.entries.len() > self.capacity {
            match self.recency.pop_front() {
                Some(oldest) => {
                    self.entries.remove(&oldest);
                }
                None => break,
            }
        }
    }

    #[cfg(test)]
    fn len(&self) -> usize {
        self.entries.len()
    }
}

fn store() -> &'static Mutex<Cache> {
    static CACHE: OnceLock<Mutex<Cache>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(Cache::new(CACHE_CAPACITY)))
}

/// Builds the normalized pair key for `(a, b)` and reports whether `a`
/// landed in the `first` slot (`true`) or the `second` slot (`false`).
fn normalize(a: &SchemaKey, b: &SchemaKey) -> (PairKey, bool) {
    if a <= b {
        (PairKey(a.clone(), b.clone()), true)
    } else {
        (PairKey(b.clone(), a.clone()), false)
    }
}

/// Looks up a previously cached, validated pair by normalized identity,
/// marking it most-recently-used on a hit without rebuilding it. Returns
/// the shared pair together with whether `stored_key` corresponds to its
/// `first` slot (`true`) or `second` slot (`false`), so the caller can
/// resolve its own stored/working roles against the pair's fixed internal
/// order.
pub(crate) fn lookup(
    stored_key: &SchemaKey,
    working_key: &SchemaKey,
) -> Option<(Arc<CachedPair>, bool)> {
    let (key, stored_is_first) = normalize(stored_key, working_key);
    let mut cache = store().lock().unwrap();
    cache.get(&key).map(|pair| (pair, stored_is_first))
}

/// Records a freshly validated pair under its normalized identity and
/// returns the now-cached `Arc`, together with whether `stored_key` is the
/// pair's `first` slot. If another thread already inserted an entry for
/// this identity in the meantime, that entry wins and the pair built here
/// is dropped unused -- both would have held equal content, so no caller
/// observes a difference. If inserting a genuinely new pair pushes the
/// cache past [`CACHE_CAPACITY`], the least-recently-used existing entry is
/// evicted first (see the module-level "Bound and LRU eviction"
/// documentation).
pub(crate) fn insert(
    stored_key: SchemaKey,
    stored: ParsedSchema,
    working_key: SchemaKey,
    working: ParsedSchema,
) -> (Arc<CachedPair>, bool) {
    let (key, stored_is_first) = normalize(&stored_key, &working_key);
    let id = next_pair_id();
    let pair = if stored_is_first {
        CachedPair {
            id,
            first: stored,
            second: working,
        }
    } else {
        CachedPair {
            id,
            first: working,
            second: stored,
        }
    };

    let mut cache = store().lock().unwrap();
    let entry = cache.insert(key, Arc::new(pair));
    (entry, stored_is_first)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::schema::parse_and_resolve;

    /// Builds a minimal validated schema for `version`, e.g. `"5.2.0"`.
    /// Each test in this module picks its own unused version range so
    /// running in parallel with other test threads sharing the same
    /// process-wide cache cannot cause cross-test interference.
    fn schema(version: &str) -> ParsedSchema {
        let xml = format!("<IDSs><version>{version}</version></IDSs>");
        parse_and_resolve(&xml, version).unwrap()
    }

    #[test]
    fn normalize_is_symmetric_regardless_of_argument_order() {
        let a = SchemaKey::new("5.1.0", "<a/>");
        let b = SchemaKey::new("5.0.9", "<b/>");
        let (key_ab, a_is_first_ab) = normalize(&a, &b);
        let (key_ba, a_is_first_ba) = normalize(&b, &a);
        assert_eq!(key_ab, key_ba);
        assert_ne!(a_is_first_ab, a_is_first_ba);
    }

    #[test]
    fn insert_then_lookup_reuses_the_same_arc() {
        let stored_key = SchemaKey::new("5.2.0", "<IDSs><version>5.2.0</version></IDSs>");
        let working_key = SchemaKey::new("5.1.9", "<IDSs><version>5.1.9</version></IDSs>");

        let (inserted, stored_is_first) = insert(
            stored_key.clone(),
            schema("5.2.0"),
            working_key.clone(),
            schema("5.1.9"),
        );

        let (looked_up, stored_is_first_again) = lookup(&stored_key, &working_key).unwrap();
        assert!(Arc::ptr_eq(&inserted, &looked_up));
        assert_eq!(stored_is_first, stored_is_first_again);
    }

    #[test]
    fn lookup_hits_regardless_of_reversed_role_order() {
        let stored_key = SchemaKey::new("5.3.0", "<IDSs><version>5.3.0</version></IDSs>");
        let working_key = SchemaKey::new("5.2.9", "<IDSs><version>5.2.9</version></IDSs>");
        let (inserted, _) = insert(
            stored_key.clone(),
            schema("5.3.0"),
            working_key.clone(),
            schema("5.2.9"),
        );

        // Same two schemas, roles swapped: still a cache hit on one entry.
        let (looked_up, working_is_first) = lookup(&working_key, &stored_key).unwrap();
        assert!(Arc::ptr_eq(&inserted, &looked_up));
        // `working_key` ("5.2.9") sorts before `stored_key` ("5.3.0"), so
        // passed in the first (`stored`) position here it lands in the
        // pair's `first` slot.
        assert!(working_is_first);
    }

    #[test]
    fn distinct_pairs_get_distinct_entries() {
        let (pair_one, _) = insert(
            SchemaKey::new("5.5.0", "<IDSs><version>5.5.0</version></IDSs>"),
            schema("5.5.0"),
            SchemaKey::new("5.4.9", "<IDSs><version>5.4.9</version></IDSs>"),
            schema("5.4.9"),
        );
        let (pair_two, _) = insert(
            SchemaKey::new("5.6.0", "<IDSs><version>5.6.0</version></IDSs>"),
            schema("5.6.0"),
            SchemaKey::new("5.5.9", "<IDSs><version>5.5.9</version></IDSs>"),
            schema("5.5.9"),
        );
        assert!(!Arc::ptr_eq(&pair_one, &pair_two));
        assert_ne!(pair_one.id, pair_two.id);
    }

    #[test]
    fn concurrent_insert_race_for_the_same_identity_converges_on_one_winner() {
        let stored_key = SchemaKey::new("5.4.0", "<IDSs><version>5.4.0</version></IDSs>");
        let working_key = SchemaKey::new("5.3.9", "<IDSs><version>5.3.9</version></IDSs>");

        let handles: Vec<_> = (0..8)
            .map(|_| {
                let stored_key = stored_key.clone();
                let working_key = working_key.clone();
                std::thread::spawn(move || {
                    insert(stored_key, schema("5.4.0"), working_key, schema("5.3.9")).0
                })
            })
            .collect();

        let results: Vec<Arc<CachedPair>> =
            handles.into_iter().map(|h| h.join().unwrap()).collect();
        for other in &results[1..] {
            assert!(Arc::ptr_eq(&results[0], other));
        }
    }

    /// LRU mechanics (issue #28), exercised against a small, freshly
    /// constructed [`Cache`] rather than the process-wide [`store`]:
    /// isolating these tests from every other test's use of the shared
    /// static cache is what makes a *small* capacity (needed to trigger
    /// eviction cheaply and deterministically) safe to use here at all --
    /// a small capacity on the shared static would make unrelated
    /// concurrent tests spuriously evict each other's entries.
    mod lru_tests {
        use super::*;

        /// Builds the normalized [`PairKey`] for a logical test pair
        /// `(version_a, version_b)`, matching how [`insert`]/[`lookup`]
        /// derive their own key from the same two version strings.
        fn pair_key(version_a: &str, version_b: &str) -> PairKey {
            let a = SchemaKey::new(
                version_a,
                &format!("<IDSs><version>{version_a}</version></IDSs>"),
            );
            let b = SchemaKey::new(
                version_b,
                &format!("<IDSs><version>{version_b}</version></IDSs>"),
            );
            normalize(&a, &b).0
        }

        fn pair(version_a: &str, version_b: &str) -> Arc<CachedPair> {
            Arc::new(CachedPair {
                id: next_pair_id(),
                first: schema(version_a),
                second: schema(version_b),
            })
        }

        #[test]
        fn touch_moves_a_key_to_most_recently_used() {
            let mut cache = Cache::new(2);
            let k1 = pair_key("100.0.0", "100.0.1");
            let k2 = pair_key("100.1.0", "100.1.1");
            cache.insert(k1.clone(), pair("100.0.0", "100.0.1"));
            cache.insert(k2.clone(), pair("100.1.0", "100.1.1"));

            // Touching k1 makes k2 the least-recently-used entry.
            assert!(cache.get(&k1).is_some());

            let k3 = pair_key("100.2.0", "100.2.1");
            cache.insert(k3.clone(), pair("100.2.0", "100.2.1"));

            assert!(cache.get(&k2).is_none(), "k2 should have been evicted");
            assert!(cache.get(&k1).is_some(), "k1 was touched, should survive");
            assert!(cache.get(&k3).is_some(), "k3 was just inserted");
        }

        #[test]
        fn inserting_past_capacity_evicts_only_the_least_recently_used_entry() {
            let mut cache = Cache::new(2);
            let k1 = pair_key("101.0.0", "101.0.1");
            let k2 = pair_key("101.1.0", "101.1.1");
            let k3 = pair_key("101.2.0", "101.2.1");

            cache.insert(k1.clone(), pair("101.0.0", "101.0.1"));
            cache.insert(k2.clone(), pair("101.1.0", "101.1.1"));
            assert_eq!(cache.len(), 2);

            cache.insert(k3.clone(), pair("101.2.0", "101.2.1"));

            assert_eq!(cache.len(), 2, "cache must never exceed its capacity");
            assert!(
                cache.get(&k1).is_none(),
                "k1 is the least-recently-used entry"
            );
            assert!(
                cache.get(&k2).is_some(),
                "k2 must be unaffected by k1's eviction"
            );
            assert!(cache.get(&k3).is_some());
        }

        #[test]
        fn evicting_an_entry_does_not_invalidate_a_handle_still_held_elsewhere() {
            let mut cache = Cache::new(1);
            let k1 = pair_key("102.0.0", "102.0.1");
            let held = cache.insert(k1.clone(), pair("102.0.0", "102.0.1"));

            // Simulates a live `crate::Map` handle retaining its own `Arc`
            // clone independent of the cache's own slot.
            let held_clone = held.clone();

            let k2 = pair_key("102.1.0", "102.1.1");
            cache.insert(k2.clone(), pair("102.1.0", "102.1.1"));

            assert!(cache.get(&k1).is_none(), "k1 should have been evicted");
            // The externally retained clone must remain fully usable: its
            // data was never freed, only the cache's own reference to it
            // was dropped.
            assert_eq!(
                held_clone.first.version(),
                crate::DdVersion::parse("102.0.0").unwrap()
            );
            assert_eq!(held_clone.id, held.id);
        }

        #[test]
        fn reacquiring_an_evicted_key_rebuilds_a_distinct_fresh_entry() {
            let mut cache = Cache::new(1);
            let k1 = pair_key("103.0.0", "103.0.1");
            let first_pair = cache.insert(k1.clone(), pair("103.0.0", "103.0.1"));

            let k2 = pair_key("103.1.0", "103.1.1");
            cache.insert(k2, pair("103.1.0", "103.1.1"));
            assert!(cache.get(&k1).is_none(), "k1 should have been evicted");

            // "Reacquiring" k1 looks exactly like a cold-cache insert: a
            // fresh pair, built independently, inserted under the same key.
            let second_pair = cache.insert(k1.clone(), pair("103.0.0", "103.0.1"));

            assert!(
                !Arc::ptr_eq(&first_pair, &second_pair),
                "an evicted-then-reacquired pair must be a distinct allocation"
            );
            assert_ne!(
                first_pair.id, second_pair.id,
                "a rebuilt pair must get its own new identity, not reuse the evicted one's"
            );
            assert!(cache.get(&k1).is_some());
        }
    }
}
