/*
 * C ABI for the IMAS projection-engine substrate (IMAS-Fortran #18/#20).
 *
 * Scope: this header is the skeleton contract for issue #20. It exposes
 * opaque handles, the shared status/verdict vocabulary, one string
 * ownership convention, and deterministic projection-entry
 * instrumentation. It does not yet expose XML/schema acquisition or real
 * rename-map lookups; those land behind this same handle shape in a later
 * slice (issue #21) without breaking this contract.
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
} pe_status_t;

/* Shared projection-verdict vocabulary. Until issue #21 lands real
 * rename-map lookups, every function that reports a verdict always
 * reports PE_VERDICT_SAME. */
typedef enum pe_verdict {
    PE_VERDICT_SAME = 0,
    PE_VERDICT_RENAME = 1,
    PE_VERDICT_SKIP = 2,
} pe_verdict_t;

/* Opaque operation-scoped handle. Never dereference or inspect its
 * layout from C; it may grow fields in a later slice without notice. */
typedef struct pe_operation pe_operation_t;

/* Begins operation-scoped state and returns the new handle through
 * `out_operation`. Reserved for the loss/dead-subtree state issue #21
 * adds without changing this handle shape. */
pe_status_t pe_operation_begin(pe_operation_t **out_operation);

/* Ends operation-scoped state and releases `operation`. Passing NULL returns
 * PE_STATUS_NULL_HANDLE; a foreign or already-ended handle returns
 * PE_STATUS_INVALID_ARGUMENT. Does not evict any cached immutable map
 * (there is none yet in this skeleton). */
pe_status_t pe_operation_end(pe_operation_t *operation);

/* Representative "project node" entry point. Placeholder: validates its
 * inputs, records one projection-entry instrumentation tick, and always
 * reports PE_VERDICT_SAME through `out_verdict`. `node_path` is borrowed
 * for the duration of this call only and need not be NUL-terminated;
 * `node_path_len` gives its length in bytes. */
pe_status_t pe_project_node_query(
    pe_operation_t *operation,
    const char *node_path,
    size_t node_path_len,
    pe_verdict_t *out_verdict);

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
