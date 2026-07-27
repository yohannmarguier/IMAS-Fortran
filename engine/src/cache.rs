//! Process-wide lazy cache of validated schema pairs (issue #22).
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
//! ## Lifetime and eviction
//!
//! The cache is unbounded and process-wide for the life of the program: an
//! entry is retained by its own `Arc` inside the cache map for as long as
//! the process runs, independent of how many [`crate::Map`] handles
//! referencing it a caller has acquired or released. Bounded LRU eviction
//! is issue #28's job, layered on top of this without changing the lookup
//! contract here. Because the cache itself always holds a reference,
//! releasing one caller handle can never invalidate another live handle
//! backed by the same entry -- there is always at least the cache's own
//! `Arc` keeping the data alive.
//!
//! ## Thread safety
//!
//! The cache is one process-wide `Mutex<HashMap<..>>`. Concurrent
//! acquisition from multiple threads is supported and requires no
//! synchronization from the caller: every lookup and insert takes the same
//! lock for the short, non-allocating-XML-parse duration of a map/hashmap
//! operation, and the expensive parse/validate work in
//! [`crate::acquire_map`] runs outside the lock, only re-taking it to
//! record the result. Two threads racing to acquire the same new pair may
//! both pay the parse cost, but only one insertion wins the cache slot
//! (see [`insert`]); every caller still gets back an `Arc` to the same
//! single winning entry, and both parses are equally valid since they
//! parsed identical content. This crate makes no throughput or lock
//! granularity guarantee beyond "concurrent acquisition is memory-safe and
//! observably correct" -- tuning contention under heavy concurrent load is
//! explicitly out of scope here (see issue #18 and #32's stress work).
use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};

use crate::schema::ParsedSchema;

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
    pub(crate) first: ParsedSchema,
    pub(crate) second: ParsedSchema,
}

fn store() -> &'static Mutex<HashMap<PairKey, Arc<CachedPair>>> {
    static CACHE: OnceLock<Mutex<HashMap<PairKey, Arc<CachedPair>>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(HashMap::new()))
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

/// Looks up a previously cached, validated pair by normalized identity.
/// Returns the shared pair together with whether `stored_key` corresponds
/// to its `first` slot (`true`) or `second` slot (`false`), so the caller
/// can resolve its own stored/working roles against the pair's fixed
/// internal order.
pub(crate) fn lookup(
    stored_key: &SchemaKey,
    working_key: &SchemaKey,
) -> Option<(Arc<CachedPair>, bool)> {
    let (key, stored_is_first) = normalize(stored_key, working_key);
    let cache = store().lock().unwrap();
    cache.get(&key).cloned().map(|pair| (pair, stored_is_first))
}

/// Records a freshly validated pair under its normalized identity and
/// returns the now-cached `Arc`, together with whether `stored_key` is the
/// pair's `first` slot. If another thread already inserted an entry for
/// this identity in the meantime, that entry wins and the pair built here
/// is dropped unused -- both would have held equal content, so no caller
/// observes a difference.
pub(crate) fn insert(
    stored_key: SchemaKey,
    stored: ParsedSchema,
    working_key: SchemaKey,
    working: ParsedSchema,
) -> (Arc<CachedPair>, bool) {
    let (key, stored_is_first) = normalize(&stored_key, &working_key);
    let pair = if stored_is_first {
        CachedPair {
            first: stored,
            second: working,
        }
    } else {
        CachedPair {
            first: working,
            second: stored,
        }
    };

    let mut cache = store().lock().unwrap();
    let entry = cache.entry(key).or_insert_with(|| Arc::new(pair));
    (entry.clone(), stored_is_first)
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
}
