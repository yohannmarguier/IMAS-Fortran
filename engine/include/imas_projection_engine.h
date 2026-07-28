/*
 * C ABI for the IMAS projection-engine substrate (IMAS-Fortran #18/#20/#21).
 *
 * Scope: issue #20 established opaque handles, the shared status/verdict
 * vocabulary, one string ownership convention, and deterministic
 * projection-entry instrumentation. Issue #21 added the first real
 * capability on top of that skeleton: acquiring a validated same-major
 * stored/working DD schema pair as an opaque, releasable pe_map_t handle.
 * Issue #22 adds process-wide reuse of that validated pair: reacquiring
 * the same pair, including with the stored/working roles swapped, reuses
 * one cached immutable pair instead of reparsing or rebuilding it, while
 * still handing back an independent, separately releasable pe_map_t per
 * acquisition. Issue #31 ties pe_operation_t to an acquired pe_map_t:
 * pe_operation_begin now requires a live map handle, an operation retains
 * its own reference to that map so releasing the map handle never
 * invalidates a live operation begun against it, and the lifecycle grows
 * an explicit pe_operation_reset and pe_operation_release alongside
 * pe_operation_end. Issue #23 indexes both schemas in a pe_map_t by
 * field/@path and gives pe_project_node_query its first real verdicts, for
 * the classifications that need no rename metadata: same, compiled-only/
 * stored-only (both pe_direction_t-relative), and datatype-changed. A
 * query now also takes an explicit pe_direction_t so either schema can
 * play source without re-acquiring the pair with roles swapped. A node
 * whose own field, or the identically-pathed field on the other schema,
 * carries automatic rename metadata is deliberately held in the distinct
 * PE_STATUS_RENAME_PENDING state rather than being folded into an added/
 * removed verdict. Issue #24 resolves change_nbc_description=leaf_renamed
 * metadata into a real PE_VERDICT_RENAME, including a comma-separated
 * successive history and the version-cutoff selection rule researched
 * from IMAS-Python in issue #13; pe_project_node_query grows three
 * trailing parameters carrying the projected path on the other schema,
 * following the same caller-provided-buffer convention as every other
 * returned string. A malformed leaf-rename history reports the distinct
 * PE_STATUS_RENAME_HISTORY_MALFORMED rather than fabricating a mapping.
 * aos_renamed/structure_renamed resolution remains issue #25's
 * (array-of-structures, plain-structure renames, cascade).
 *
 * Hand-maintained, not generated: every declaration here must be kept in
 * sync with its `#[no_mangle] extern "C"` definition in `src/ffi.rs`.
 *
 * Conventions:
 *
 * 1. Status. Every function returns a `pe_status_t`. A non-`PE_STATUS_OK`
 *    return means the call did not perform its documented effect; out
 *    parameters are left unset (implementation detail: they are simply
 *    never written, not zeroed).
 *
 * 2. Ownership of returned strings. This ABI has exactly one convention
 *    for every string it returns: the CALLER provides the buffer. The
 *    engine never returns an engine-owned pointer the caller must later
 *    free. Call once with `buffer = NULL` (or `buffer_len = 0`) to learn
 *    the required length, allocate `required_len + 1` bytes, then call
 *    again with that buffer. If the supplied buffer is non-null but too
 *    small, the text is truncated and still NUL-terminated, and the
 *    status is `PE_STATUS_BUFFER_TOO_SMALL`. `pe_status_message` is the
 *    representative call demonstrating this convention.
 *
 * 3. Panics never cross this boundary. Every entry point contains any
 *    internal Rust panic and reports `PE_STATUS_INTERNAL` instead of
 *    unwinding across the ABI.
 *
 * 4. Input validation. Every entry point validates null pointers and
 *    lengths before using them and returns a status rather than trusting
 *    the caller.
 */

#ifndef IMAS_PROJECTION_ENGINE_H
#define IMAS_PROJECTION_ENGINE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Stable status vocabulary. Discriminants are part of the ABI: never
 * renumber existing values. */
typedef enum pe_status {
    PE_STATUS_OK = 0,
    PE_STATUS_INVALID_ARGUMENT = 1,
    PE_STATUS_NULL_HANDLE = 2,
    PE_STATUS_BUFFER_TOO_SMALL = 3,
    PE_STATUS_INTERNAL = 4,
    /* Malformed XML, a missing DD version with no valid caller-supplied
     * fallback, or a caller-claimed identity that disagrees with the
     * parsed <version> element. Covers every pe_map_acquire failure that
     * is not the distinct cross-major refusal below. */
    PE_STATUS_SCHEMA_IDENTITY = 5,
    /* The stored and working schemas each parsed and validated, but their
     * major DD versions differ; automatic same-major projection refuses
     * to build a map for this pair. */
    PE_STATUS_CROSS_MAJOR = 6,
    /* The queried node's own field, or the identically-pathed field on
     * the other schema, carries aos_renamed or structure_renamed metadata
     * (change_nbc_description) that this engine does not yet resolve into
     * a real verdict (issue #25). pe_project_node_query leaves out_verdict
     * and the projected-path output unwritten when it returns this
     * status, exactly as for any other non-PE_STATUS_OK result. No longer
     * reported for leaf_renamed metadata, which issue #24 resolves into a
     * real PE_VERDICT_RENAME instead. */
    PE_STATUS_RENAME_PENDING = 7,
    /* A leaf_renamed field's change_nbc_version/change_nbc_previous_name
     * history is malformed or ambiguous -- unequal entry counts, an
     * unparseable version, entries out of semantic order, or more than one
     * leaf field resolving to the same predecessor (issue #24). The engine
     * refuses to guess a resolution in these cases rather than fabricate a
     * mapping; out_verdict and the projected-path output are left
     * unwritten. */
    PE_STATUS_RENAME_HISTORY_MALFORMED = 8,
} pe_status_t;

/* Shared projection-verdict vocabulary. Issue #23 gives
 * pe_project_node_query its first real verdicts for the classifications
 * that need no rename metadata: an unchanged node reports PE_VERDICT_SAME;
 * a compiled-only, stored-only, or datatype-changed node reports
 * PE_VERDICT_SKIP. Issue #24 gives it its first real PE_VERDICT_RENAME, for
 * a resolved leaf_renamed field. A node awaiting aos_renamed/
 * structure_renamed resolution (issue #25) reports the distinct
 * PE_STATUS_RENAME_PENDING status instead of a verdict (see pe_status_t). */
typedef enum pe_verdict {
    PE_VERDICT_SAME = 0,
    PE_VERDICT_RENAME = 1,
    PE_VERDICT_SKIP = 2,
} pe_verdict_t;

/* Opaque handle for one validated stored/working DD schema pair (issue
 * #21). Never dereference or inspect its layout from C. Distinct pe_map_t
 * handles may share the same underlying cached pair (issue #22); each is
 * still independently releasable, and releasing one never invalidates
 * another live handle referring to the same cached pair. Forward-declared
 * here (ahead of pe_map_acquire below) so pe_operation_begin can already
 * reference it. */
typedef struct pe_map pe_map_t;

/* Opaque operation-scoped handle. Never dereference or inspect its
 * layout from C; it may grow fields in a later slice without notice. */
typedef struct pe_operation pe_operation_t;

/* Begins operation-scoped state against `map` and returns the new handle
 * through `out_operation` (issue #31). `map` must be a currently-live
 * handle returned by pe_map_acquire and not yet released; a null `map`
 * returns PE_STATUS_NULL_HANDLE, and a foreign or already-released `map`
 * returns PE_STATUS_INVALID_ARGUMENT, in both cases leaving
 * `out_operation` unwritten.
 *
 * Beginning an operation only retains a reference to the map's already-
 * validated pair data; it neither clones nor mutates that immutable data.
 * That retained reference also means a live operation keeps working even
 * after `map` itself is later passed to pe_map_release: releasing a map
 * handle never invalidates an operation begun against it, and this ABI
 * places no ordering requirement between the two -- a map may be released
 * before, during, or after the lifetime of any operation begun against it.
 * Several operations may be begun against the same map, or against
 * distinct maps, and remain simultaneously live without interfering with
 * one another.
 *
 * Reserved for the projection/loss state issues #26/#27 add without
 * changing this handle shape. */
pe_status_t pe_operation_begin(const pe_map_t *map, pe_operation_t **out_operation);

/* Clears `operation`'s local state back to its post-begin state
 * deterministically, without evicting the cached immutable map it was
 * begun against or releasing the handle itself (issue #31). Passing NULL
 * returns PE_STATUS_NULL_HANDLE; a foreign handle, or one already ended via
 * pe_operation_end, returns PE_STATUS_INVALID_ARGUMENT. Repeatable while
 * `operation` remains active. */
pe_status_t pe_operation_reset(pe_operation_t *operation);

/* Finalizes `operation`'s local state, without evicting the cached
 * immutable map it was begun against or releasing the handle itself (issue
 * #31). Passing NULL returns PE_STATUS_NULL_HANDLE; a foreign or
 * already-ended handle returns PE_STATUS_INVALID_ARGUMENT. An ended
 * operation must still be passed to pe_operation_release to free it, and
 * remains valid for that call. */
pe_status_t pe_operation_end(pe_operation_t *operation);

/* Releases an operation handle returned by pe_operation_begin, whether or
 * not pe_operation_end was called for it first (issue #31). Passing NULL
 * returns PE_STATUS_NULL_HANDLE; a foreign or already-released handle,
 * including a live pe_map_t passed by mistake, returns
 * PE_STATUS_INVALID_ARGUMENT. Never releases or invalidates the map handle
 * `operation` was begun against, and never affects another live operation
 * begun against the same map. */
pe_status_t pe_operation_release(pe_operation_t *operation);

/* Selects which schema in a pe_map_t pair a query addresses. */
typedef enum pe_map_role {
    PE_MAP_ROLE_STORED = 0,
    PE_MAP_ROLE_WORKING = 1,
} pe_map_role_t;

/* Acquires a validated same-major stored/working DD schema pair as an
 * opaque, releasable pe_map_t handle (issue #21).
 *
 * `stored_xml`/`working_xml` are each parsed as UTF-8 XML; neither needs
 * to be NUL-terminated since its length is given explicitly. The XML
 * <version> element is authoritative when present, and must then agree
 * with the corresponding `*_claimed_version` string. When the element is
 * absent, `*_claimed_version` is used as the schema's version directly.
 * An invalid or fabricated identity never produces a usable handle:
 * malformed XML, a missing version with no valid fallback, or a
 * claimed/parsed mismatch on either schema all return
 * PE_STATUS_SCHEMA_IDENTITY and leave `out_map` unwritten. A pair that
 * individually validates but disagrees on major version returns the
 * distinct PE_STATUS_CROSS_MAJOR, also without writing `out_map`.
 *
 * `stored`/`working` are caller-assigned roles, not an ordering by DD
 * version: the same parsing and validation runs for both regardless of
 * which one is semantically older or curated.
 *
 * Reacquiring the same stored/working content, including with the roles
 * swapped, reuses the process-wide cached pair from a prior successful
 * acquisition instead of reparsing or rebuilding it (issue #22); every
 * acquisition still returns its own independent, separately releasable
 * pe_map_t. Cache lookup never creates or depends on a mutable global
 * "active" or "working" DD version, and several distinct pairs may be
 * live at once. Concurrent calls to pe_map_acquire from multiple threads
 * are safe and require no external synchronization (see pe_map_cache_
 * identity below and engine/README.md's thread-safety section); this
 * library makes no throughput guarantee beyond that safety.
 *
 * Input ownership: all four input buffers are borrowed for the duration
 * of this call only. On success the engine copies the bytes it needs (the
 * resolved version and a copy of each schema's XML source); none of the
 * four input pointers is retained past this call returning, and the
 * caller may free or overwrite them immediately afterwards. */
pe_status_t pe_map_acquire(
    const char *stored_xml,
    size_t stored_xml_len,
    const char *stored_claimed_version,
    size_t stored_claimed_version_len,
    const char *working_xml,
    size_t working_xml_len,
    const char *working_claimed_version,
    size_t working_claimed_version_len,
    pe_map_t **out_map);

/* Releases a map handle returned by pe_map_acquire. Passing NULL returns
 * PE_STATUS_NULL_HANDLE; a foreign or already-released handle returns
 * PE_STATUS_INVALID_ARGUMENT. */
pe_status_t pe_map_release(pe_map_t *map);

/* Reads back the resolved version string ("major.minor.patch") of one
 * schema in `map` for `role`, following the string ownership convention
 * documented above. Exists so a caller can observe that acquisition
 * resolved and retained each schema's version correctly and independently
 * of the input buffers passed to pe_map_acquire. An unrecognized `role`
 * returns PE_STATUS_INVALID_ARGUMENT rather than being coerced into a
 * default. */
pe_status_t pe_map_version(
    const pe_map_t *map,
    pe_map_role_t role,
    char *buffer,
    size_t buffer_len,
    size_t *required_len);

/* Reads back the opaque cache identity of the validated pair backing
 * `map` into `out_identity` (issue #22). pe_map_acquire reuses one
 * process-wide cached pair for repeated acquisitions of the same
 * stored/working schema-pair content, including with the roles swapped,
 * instead of reparsing or rebuilding it; two independently acquired
 * pe_map_t handles backed by that same cached pair report an equal
 * identity here, while handles backed by distinct pairs report different
 * identities. This is the mechanism by which a caller -- including this
 * library's own contract test -- can prove cache reuse without this ABI
 * exposing any Rust collection layout to do so. The value carries no
 * meaning beyond equality comparison: it must not be interpreted as a
 * real memory address, persisted across process runs, or used to look
 * anything up directly. */
pe_status_t pe_map_cache_identity(const pe_map_t *map, uint64_t *out_identity);

/* Selects which schema in a pe_map_t pair plays a pe_project_node_query
 * call's source, so reciprocal behaviour is drivable through the ABI
 * rather than only inferable from which endpoint was acquired as stored
 * vs. working (issue #23). During real get/put, the compiled working
 * version always drives the walk, so production callers always pass
 * PE_DIRECTION_WORKING_TO_STORED; PE_DIRECTION_STORED_TO_WORKING exists so
 * either endpoint can be exercised as source for direct contract testing. */
typedef enum pe_direction {
    PE_DIRECTION_WORKING_TO_STORED = 0,
    PE_DIRECTION_STORED_TO_WORKING = 1,
} pe_direction_t;

/* Projects `node_path`, read from whichever schema `direction` selects as
 * source, against the other schema in `map` (issues #23, #24). `map` must
 * be the same currently-live handle passed to pe_operation_begin for
 * `operation`, and `operation` must also still be live. A null handle
 * returns PE_STATUS_NULL_HANDLE; a foreign, released, or mismatched handle
 * returns PE_STATUS_INVALID_ARGUMENT without either opaque handle being
 * dereferenced (issue #31). An unrecognized `direction` returns
 * PE_STATUS_INVALID_ARGUMENT, the same way an unrecognized pe_map_role_t
 * does. `node_path` is borrowed for the duration of this call only and
 * need not be NUL-terminated; `node_path_len` gives its length in bytes.
 *
 * Reports through `out_verdict`/`projected_path_*`/the return status:
 *  - unchanged (present in both schemas, matching data_type, no rename
 *    metadata applies) -- PE_STATUS_OK, PE_VERDICT_SAME,
 *    `projected_path_*` left untouched (no replacement string is needed);
 *  - compiled-only, stored-only (present in source, absent from target,
 *    no rename metadata resolves to it), or datatype-changed (present in
 *    both, directly or via a resolved rename, with differing data_type)
 *    -- PE_STATUS_OK, PE_VERDICT_SKIP, `projected_path_*` left untouched;
 *  - a resolved leaf_renamed field (issue #24) -- PE_STATUS_OK,
 *    PE_VERDICT_RENAME, with the projected path on the other schema
 *    written to `projected_path_buffer` following the same
 *    caller-provided-buffer convention documented above for every other
 *    returned string (an undersized buffer reports the distinct
 *    PE_STATUS_BUFFER_TOO_SMALL, with `out_verdict` still written since
 *    the classification itself is not in question, only the buffer size);
 *  - a node whose own field, or the identically-pathed field on the other
 *    schema, carries aos_renamed/structure_renamed metadata not yet
 *    resolved by issue #25 -- PE_STATUS_RENAME_PENDING, `out_verdict` and
 *    `projected_path_*` left untouched;
 *  - a leaf_renamed field whose change_nbc_version/change_nbc_previous_name
 *    history is malformed or ambiguous (issue #24) -- the distinct
 *    PE_STATUS_RENAME_HISTORY_MALFORMED, `out_verdict` and
 *    `projected_path_*` left untouched;
 *  - a `node_path` unknown to the selected source schema -- rejected as
 *    PE_STATUS_INVALID_ARGUMENT, `out_verdict` and `projected_path_*` left
 *    untouched, since a real compiled walk only ever queries paths it
 *    already knows belong to its own schema.
 *
 * `projected_path_buffer`/`projected_path_buffer_len`/
 * `projected_path_required_len` follow the string ownership convention
 * documented above; pass `projected_path_buffer = NULL` (or
 * `projected_path_buffer_len = 0`) to learn the required length first, as
 * with any other returned string.
 *
 * Releasing a map does not invalidate its operation's own lifecycle, but
 * this entry requires the caller to retain the map handle for each query. */
pe_status_t pe_project_node_query(
    const pe_map_t *map,
    pe_operation_t *operation,
    pe_direction_t direction,
    const char *node_path,
    size_t node_path_len,
    pe_verdict_t *out_verdict,
    char *projected_path_buffer,
    size_t projected_path_buffer_len,
    size_t *projected_path_required_len);

/* Zeroes the process-wide projection-entry counter. */
pe_status_t pe_instrumentation_reset(void);

/* Reads the process-wide projection-entry counter into `out_count`. */
pe_status_t pe_instrumentation_read(uint64_t *out_count);

/* Returns stable diagnostic text for `status` following the string
 * ownership convention documented above. Accepts any int value (not just
 * a valid pe_status_t) and reports PE_STATUS_INVALID_ARGUMENT for an
 * unrecognized one instead of producing undefined behaviour. */
pe_status_t pe_status_message(
    pe_status_t status,
    char *buffer,
    size_t buffer_len,
    size_t *required_len);

#ifdef __cplusplus
}
#endif

#endif /* IMAS_PROJECTION_ENGINE_H */
