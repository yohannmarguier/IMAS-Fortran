/*
 * C contract test for the projection-engine ABI (IMAS-Fortran #20, #21,
 * #22, #31).
 *
 * This is the highest seam this repo's later slices add vectors to: it
 * drives the engine only through imas_projection_engine.h, the same way
 * the Fortran wrapper eventually will.
 *
 * Negative-path wording convention: this repo's CTest harness fails a
 * test whose stdout/stderr matches (case-insensitively) fault, error not
 * immediately followed by '_', exception, severe, abort, segmentation,
 * dump, logic_error, or failed -- even when the process exits 0 (see
 * common/cmake/ALExampleUtilities.cmake). This suite is full of
 * deliberate negative paths (null handles, undersized buffers, unknown
 * status codes), so every print below, including on the assertion-failure
 * path, sticks to neutral wording such as "unexpected", "rejected", or
 * "status=<code>" and never the words above. Status/verdict enum names
 * were themselves chosen to avoid those words (see status.rs) so printing
 * them verbatim is always safe.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "imas_projection_engine.h"

#define CHECK(cond, what)                                                    \
    do {                                                                     \
        if (!(cond)) {                                                      \
            fprintf(stderr, "unexpected result: %s (%s:%d)\n", (what),      \
                    __FILE__, __LINE__);                                    \
            return 1;                                                       \
        }                                                                    \
    } while (0)

/* Fixtures for pe_map_acquire (issue #21). Deliberately minimal for that
 * seam's own purposes, which only care about the <version> element and
 * well-formedness -- but issue #23 gives pe_project_node_query real
 * verdicts, so a single matching, untagged, identical field is included on
 * both sides purely so the operation-lifecycle/instrumentation tests below
 * that just need *some* valid projection query keep exercising a genuine
 * PE_VERDICT_SAME rather than an unknown-path rejection. */
#define XML_STORED_3_39_0                                                    \
    "<IDSs><version>3.39.0</version>"                                       \
    "<field name=\"time\" path=\"ids/time\" data_type=\"FLT_1D\"/></IDSs>"
#define XML_WORKING_3_38_1                                                  \
    "<IDSs><version>3.38.1</version>"                                       \
    "<field name=\"time\" path=\"ids/time\" data_type=\"FLT_1D\"/></IDSs>"
#define XML_CROSS_MAJOR_4_0_0 "<IDSs><version>4.0.0</version></IDSs>"
#define XML_MALFORMED "<IDSs><version>3.39.0</version>"
#define XML_NO_VERSION_ELEMENT "<IDSs><ids/></IDSs>"

/* A second, unrelated same-major pair (issue #22, #31): used to prove that
 * a distinct pair gets a distinct cache identity from XML_STORED_3_39_0 /
 * XML_WORKING_3_38_1 above, that the two do not affect each other, and
 * (issue #31) that operations begun against distinct maps stay isolated. */
#define XML_OTHER_PAIR_STORED "<IDSs><version>5.10.0</version></IDSs>"
#define XML_OTHER_PAIR_WORKING "<IDSs><version>5.9.9</version></IDSs>"

/*
 * THE shared same-major synthetic fixture pair specified by issue #18 and
 * designed here in full by issue #23 (see #23's "What to build": "This
 * slice owns the shared fixture corpus"). It carries all nine fixture
 * features #18 names, even though only the classifications that need no
 * rename metadata are asserted below. Issues #24 and #25 add vectors
 * *activating* the remaining features against this exact pair -- they must
 * not edit the XML below or the vectors already asserted here.
 *
 * Feature -> field mapping (OLD = XML_FIXTURE_OLD_20_1_0, NEW =
 * XML_FIXTURE_NEW_20_2_0):
 *   1. leaf rename                    -- OLD old_leaf_name / NEW new_leaf_name
 *   2. plain-structure rename+cascade -- OLD old_struct/... / NEW new_struct/...
 *   3. array-of-structures rename     -- OLD old_aos/...    / NEW new_aos/...
 *   4. successive rename history      -- OLD middle_name    / NEW thrice_renamed
 *   5. added field                    -- NEW added_only_field (no OLD counterpart)
 *   6. removed field                  -- OLD removed_only_field (no NEW counterpart)
 *   7. datatype change                -- OLD/NEW retyped_field (INT_0D -> FLT_0D)
 *   8. renamed time-dependent node    -- OLD dynamic_group/legacy_signal /
 *                                         NEW dynamic_group/signal (dynamic,
 *                                         coordinate1=time, shared timebasepath)
 *   9. missing parent, reachable      -- OLD orphan_container/direct_signal /
 *      renamed descendant                NEW rescued_signal (no "orphan_container"
 *                                         field exists on the NEW side at all)
 *
 * `unchanged_leaf` (not itself one of the nine numbered features) plus
 * features 5, 6, and 7 are asserted through the ABI here with a durable,
 * must-remain-valid verdict -- see #23's own acceptance criteria on why a
 * *durable* verdict for the six rename-bearing features (1-4, 8, 9) must
 * not be asserted by this ticket: #24/#25 legitimately reclassify them once
 * rename resolution lands, and asserting a specific resolved verdict here
 * would make this ticket's own vectors the thing that breaks. Those six are
 * instead only asserted to report PE_STATUS_RENAME_PENDING for now, in
 * test_projection_shared_fixture_rename_bearing_fields_report_rename_pending
 * below -- a deliberately non-durable vector #24/#25 must update, not one
 * of the four this ticket's acceptance criteria freezes.
 *
 * Note for #24/#25: querying most of these rename-tagged OLD-side paths via
 * PE_DIRECTION_STORED_TO_WORKING reports PE_STATUS_RENAME_PENDING rather
 * than a fabricated added/removed skip. FieldIndex::may_have_renamed_from
 * (src/projection.rs) recognizes exact predecessor paths, bare predecessor
 * names within their unchanged parent, and descendants of renamed
 * structures/AoSs. Do not read that conservative pending guard as rename
 * resolution: #24/#25 still determine the actual same/rename verdict.
 */
#define XML_FIXTURE_OLD_20_1_0                                               \
    "<IDSs><version>20.1.0</version>"                                       \
    "<field name=\"unchanged_leaf\" path=\"unchanged_leaf\" data_type=\"INT_0D\"/>" \
    "<field name=\"removed_only_field\" path=\"removed_only_field\" data_type=\"INT_0D\"/>" \
    "<field name=\"retyped_field\" path=\"retyped_field\" data_type=\"INT_0D\"/>" \
    "<field name=\"old_leaf_name\" path=\"old_leaf_name\" data_type=\"STR_0D\"/>" \
    "<field name=\"old_struct\" path=\"old_struct\" data_type=\"structure\" "  \
    "structure_reference=\"generic_container\"/>"                            \
    "<field name=\"child_a\" path=\"old_struct/child_a\" data_type=\"INT_0D\"/>" \
    "<field name=\"child_b\" path=\"old_struct/child_b\" data_type=\"INT_0D\"/>" \
    "<field name=\"old_aos\" path=\"old_aos\" data_type=\"struct_array\" maxoccur=\"10\"/>" \
    "<field name=\"value\" path=\"old_aos/value\" data_type=\"FLT_1D\"/>"     \
    "<field name=\"middle_name\" path=\"middle_name\" data_type=\"STR_0D\"/>" \
    "<field name=\"legacy_signal\" path=\"dynamic_group/legacy_signal\" "     \
    "data_type=\"FLT_1D\" type=\"dynamic\" coordinate1=\"time\" "            \
    "timebasepath=\"dynamic_group/time\"/>"                                  \
    "<field name=\"time\" path=\"dynamic_group/time\" data_type=\"FLT_1D\" "  \
    "type=\"dynamic\"/>"                                                     \
    "<field name=\"direct_signal\" path=\"orphan_container/direct_signal\" " \
    "data_type=\"STR_0D\"/>"                                                 \
    "</IDSs>"
#define XML_FIXTURE_NEW_20_2_0                                               \
    "<IDSs><version>20.2.0</version>"                                       \
    "<field name=\"unchanged_leaf\" path=\"unchanged_leaf\" data_type=\"INT_0D\"/>" \
    "<field name=\"added_only_field\" path=\"added_only_field\" data_type=\"INT_0D\"/>" \
    "<field name=\"retyped_field\" path=\"retyped_field\" data_type=\"FLT_0D\"/>" \
    "<field name=\"new_leaf_name\" path=\"new_leaf_name\" data_type=\"STR_0D\" " \
    "change_nbc_version=\"20.2.0\" change_nbc_description=\"leaf_renamed\" "  \
    "change_nbc_previous_name=\"old_leaf_name\"/>"                           \
    "<field name=\"new_struct\" path=\"new_struct\" data_type=\"structure\" " \
    "structure_reference=\"generic_container\" change_nbc_version=\"20.2.0\" " \
    "change_nbc_description=\"structure_renamed\" "                         \
    "change_nbc_previous_name=\"old_struct\"/>"                             \
    "<field name=\"child_a\" path=\"new_struct/child_a\" data_type=\"INT_0D\"/>" \
    "<field name=\"child_b\" path=\"new_struct/child_b\" data_type=\"INT_0D\"/>" \
    "<field name=\"new_aos\" path=\"new_aos\" data_type=\"struct_array\" "    \
    "maxoccur=\"10\" change_nbc_version=\"20.2.0\" "                        \
    "change_nbc_description=\"aos_renamed\" change_nbc_previous_name=\"old_aos\"/>" \
    "<field name=\"value\" path=\"new_aos/value\" data_type=\"FLT_1D\"/>"     \
    "<field name=\"thrice_renamed\" path=\"thrice_renamed\" data_type=\"STR_0D\" " \
    "change_nbc_version=\"19.5.0,20.2.0\" change_nbc_description=\"leaf_renamed\" " \
    "change_nbc_previous_name=\"ancient_name,middle_name\"/>"                \
    "<field name=\"signal\" path=\"dynamic_group/signal\" data_type=\"FLT_1D\" " \
    "type=\"dynamic\" coordinate1=\"time\" timebasepath=\"dynamic_group/time\" " \
    "change_nbc_version=\"20.2.0\" change_nbc_description=\"leaf_renamed\" "  \
    "change_nbc_previous_name=\"legacy_signal\"/>"                          \
    "<field name=\"time\" path=\"dynamic_group/time\" data_type=\"FLT_1D\" "  \
    "type=\"dynamic\"/>"                                                     \
    "<field name=\"rescued_signal\" path=\"rescued_signal\" data_type=\"STR_0D\" " \
    "change_nbc_version=\"20.2.0\" change_nbc_description=\"leaf_renamed\" "  \
    "change_nbc_previous_name=\"orphan_container/direct_signal\"/>"          \
    "</IDSs>"

/* A small, deliberately separate ad-hoc pair -- NOT part of the shared
 * fixture above -- used only to prove PE_STATUS_RENAME_PENDING itself
 * works end to end through the ABI (issue #23's "explicit unsupported-yet
 * state" requirement). Kept independent of the shared corpus on purpose:
 * once #24/#25 resolve rename metadata in the shared pair, every one of
 * its nine feature nodes will legitimately stop reporting
 * PE_STATUS_RENAME_PENDING, and this test must keep passing regardless. */
#define XML_RENAME_PENDING_SOURCE                                            \
    "<IDSs><version>30.2.0</version>"                                       \
    "<field name=\"tagged\" path=\"tagged\" data_type=\"STR_0D\" "            \
    "change_nbc_version=\"30.2.0\" change_nbc_description=\"leaf_renamed\" "  \
    "change_nbc_previous_name=\"untagged\"/></IDSs>"
#define XML_RENAME_PENDING_TARGET                                            \
    "<IDSs><version>30.1.0</version>"                                       \
    "<field name=\"untagged\" path=\"untagged\" data_type=\"STR_0D\"/></IDSs>"

#define STR_LEN(literal) (sizeof(literal) - 1)

/* Reads pe_map_version for `role` and compares it against `expected`,
 * exercising the same query-then-fill buffer convention already covered by
 * test_status_message_string_ownership_convention. */
static int map_version_matches(const pe_map_t *map, pe_map_role_t role,
                                const char *expected) {
    size_t required_len = 0;
    char buffer[32];

    if (pe_map_version(map, role, NULL, 0, &required_len) != PE_STATUS_OK) {
        return 0;
    }
    if (required_len >= sizeof(buffer)) {
        return 0;
    }
    if (pe_map_version(map, role, buffer, sizeof(buffer), NULL) != PE_STATUS_OK) {
        return 0;
    }
    return strcmp(buffer, expected) == 0;
}

/* Acquires the shared XML_STORED_3_39_0 / XML_WORKING_3_38_1 pair, used by
 * every operation-lifecycle test below that just needs *some* live map
 * handle to begin an operation against. */
static int acquire_shared_pair(pe_map_t **out_map) {
    return pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                           STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                           STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                           out_map) == PE_STATUS_OK;
}

static int test_operation_lifecycle_and_input_validation(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;

    CHECK(acquire_shared_pair(&map), "acquiring the shared pair should succeed");

    /* begin: requires a live map handle. */
    CHECK(pe_operation_begin(NULL, &operation) == PE_STATUS_NULL_HANDLE,
          "begin(NULL map) should be rejected");
    CHECK(pe_operation_begin(map, NULL) == PE_STATUS_INVALID_ARGUMENT,
          "begin(NULL out_operation) should be rejected");
    CHECK(pe_operation_begin((pe_map_t *)(uintptr_t)UINTPTR_MAX, &operation) ==
              PE_STATUS_INVALID_ARGUMENT,
          "begin against a foreign map handle should be rejected");

    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");
    CHECK(operation != NULL, "begin should hand back a non-null handle");

    /* reset: repeatable while active. */
    CHECK(pe_operation_reset(NULL) == PE_STATUS_NULL_HANDLE,
          "reset(NULL) should be rejected");
    CHECK(pe_operation_reset(operation) == PE_STATUS_OK, "reset should succeed");
    CHECK(pe_operation_reset(operation) == PE_STATUS_OK,
          "reset should remain repeatable while the operation is active");

    /* end: a one-time transition; reset/end afterwards are refused. */
    CHECK(pe_operation_end(NULL) == PE_STATUS_NULL_HANDLE,
          "end(NULL) should be rejected");
    CHECK(pe_operation_end(operation) == PE_STATUS_OK, "end should succeed");
    CHECK(pe_operation_end(operation) == PE_STATUS_INVALID_ARGUMENT,
          "ending the same handle twice should be rejected");
    CHECK(pe_operation_reset(operation) == PE_STATUS_INVALID_ARGUMENT,
          "resetting an ended operation should be rejected");

    /* release: valid on an ended operation; use-after-release rejected. */
    CHECK(pe_operation_release(NULL) == PE_STATUS_NULL_HANDLE,
          "release(NULL) should be rejected");
    CHECK(pe_operation_release(operation) == PE_STATUS_OK,
          "releasing an ended operation should succeed");
    CHECK(pe_operation_release(operation) == PE_STATUS_INVALID_ARGUMENT,
          "releasing the same handle twice should be rejected");
    CHECK(pe_operation_reset(operation) == PE_STATUS_INVALID_ARGUMENT,
          "resetting a released handle should be rejected, not dereferenced");

    pe_map_release(map);

    printf("operation lifecycle: begin/reset/end/release negative paths "
           "rejected as expected\n");
    return 0;
}

/* A released operation token must never become a newly begun operation's
 * handle, even after the registry has dropped the former operation. */
static int test_released_operation_token_never_aliases_a_new_operation(void) {
    pe_map_t *map = NULL;
    pe_operation_t *released = NULL;
    pe_operation_t *live = NULL;
    pe_verdict_t verdict;
    const char path[] = "ids/time";

    CHECK(acquire_shared_pair(&map), "acquiring the shared pair should succeed");
    CHECK(pe_operation_begin(map, &released) == PE_STATUS_OK,
          "beginning the first operation should succeed");
    CHECK(pe_operation_release(released) == PE_STATUS_OK,
          "releasing the first operation should succeed");
    CHECK(pe_operation_begin(map, &live) == PE_STATUS_OK,
          "beginning the second operation should succeed");
    CHECK(released != live, "a released token must not be reused by a later begin");

    CHECK(pe_operation_reset(released) == PE_STATUS_INVALID_ARGUMENT,
          "resetting a released token should remain rejected after another begin");
    CHECK(pe_project_node_query(map, released, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "querying with a released token should remain rejected after another begin");
    CHECK(pe_operation_release(released) == PE_STATUS_INVALID_ARGUMENT,
          "releasing a released token should not release the new operation");
    CHECK(pe_operation_reset(live) == PE_STATUS_OK,
          "the later operation should remain live after rejected stale calls");

    pe_operation_release(live);
    pe_map_release(map);

    printf("operation lifecycle: released tokens remained distinct from later begins\n");
    return 0;
}

/* Issue #31's ordering rule: an operation retains its own reference to the
 * map it was begun against, so releasing the map handle never invalidates
 * a live operation, in either release order. */
static int test_operation_survives_its_map_handle_being_released(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict;
    const char path[] = "ids/time";
    CHECK(acquire_shared_pair(&map), "acquiring the shared pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    /* Release the map before the operation. Its lifecycle remains usable:
     * the query entry itself requires a live map argument, but reset/end/
     * release use the operation's retained reference. */
    CHECK(pe_map_release(map) == PE_STATUS_OK, "releasing the map should succeed");

    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "querying after map release should require a still-live map handle");
    CHECK(pe_operation_reset(operation) == PE_STATUS_OK,
          "reset should remain usable after the map handle is released");
    CHECK(pe_operation_end(operation) == PE_STATUS_OK,
          "end should remain usable after the map handle is released");
    CHECK(pe_operation_release(operation) == PE_STATUS_OK,
          "releasing the operation should succeed");

    printf("operation lifecycle: reset/end/release survived the map handle "
           "being released first\n");
    return 0;
}

/* Several operations against one map, and operations against different
 * maps, stay live simultaneously without interfering (issue #31). */
static int test_operations_stay_isolated_across_handles(void) {
    pe_map_t *map_one = NULL;
    pe_map_t *map_two = NULL;
    pe_operation_t *first = NULL;
    pe_operation_t *second = NULL;
    pe_operation_t *third = NULL;

    CHECK(acquire_shared_pair(&map_one), "acquiring the first pair should succeed");
    CHECK(pe_map_acquire(XML_OTHER_PAIR_STORED, STR_LEN(XML_OTHER_PAIR_STORED),
                          "5.10.0", STR_LEN("5.10.0"), XML_OTHER_PAIR_WORKING,
                          STR_LEN(XML_OTHER_PAIR_WORKING), "5.9.9", STR_LEN("5.9.9"),
                          &map_two) == PE_STATUS_OK,
          "acquiring the second, unrelated pair should succeed");

    /* Two operations against the same map. */
    CHECK(pe_operation_begin(map_one, &first) == PE_STATUS_OK,
          "beginning the first operation against map_one should succeed");
    CHECK(pe_operation_begin(map_one, &second) == PE_STATUS_OK,
          "beginning a second, simultaneous operation against map_one should succeed");
    CHECK(first != second, "each begin should hand back its own independent handle");

    /* One operation against a different map. */
    CHECK(pe_operation_begin(map_two, &third) == PE_STATUS_OK,
          "beginning an operation against map_two should succeed");

    /* Ending/releasing `first` must not affect `second` (same map) or
     * `third` (different map). */
    CHECK(pe_operation_end(first) == PE_STATUS_OK, "ending the first operation should succeed");
    CHECK(pe_operation_release(first) == PE_STATUS_OK,
          "releasing the first operation should succeed");

    CHECK(pe_operation_reset(second) == PE_STATUS_OK,
          "the second operation against the same map should be unaffected");
    CHECK(pe_operation_reset(third) == PE_STATUS_OK,
          "the operation against the other map should be unaffected");

    pe_operation_release(second);
    pe_operation_release(third);
    pe_map_release(map_one);
    pe_map_release(map_two);

    printf("operation lifecycle: simultaneous operations against one map "
           "and across distinct maps stayed isolated\n");
    return 0;
}

/* Cross-handle mix-ups (issue #31): a live pe_map_t is not a live
 * pe_operation_t and vice versa, so passing one where the other is expected
 * is rejected as a foreign handle rather than being dereferenced. */
static int test_operation_and_map_handles_are_not_interchangeable(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;

    CHECK(acquire_shared_pair(&map), "acquiring the shared pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    CHECK(pe_operation_release((pe_operation_t *)map) == PE_STATUS_INVALID_ARGUMENT,
          "a live map handle should not be accepted as an operation handle");
    CHECK(pe_map_release((pe_map_t *)operation) == PE_STATUS_INVALID_ARGUMENT,
          "a live operation handle should not be accepted as a map handle");

    /* Both handles remain live and independently usable after the mix-ups
     * above were rejected. */
    CHECK(pe_operation_end(operation) == PE_STATUS_OK,
          "the operation handle should be unaffected by the rejected mix-ups");
    pe_operation_release(operation);
    CHECK(pe_map_release(map) == PE_STATUS_OK,
          "the map handle should be unaffected by the rejected mix-ups");

    printf("operation lifecycle: cross-handle mix-ups between map and "
           "operation registries were rejected\n");
    return 0;
}

static int test_projection_entry_instrumentation(void) {
    pe_map_t *map = NULL;
    pe_map_t *other_map = NULL;
    pe_operation_t *operation = NULL;
    uint64_t count = 0;
    pe_verdict_t verdict;
    const char path[] = "ids/time";

    CHECK(acquire_shared_pair(&map), "acquiring the shared pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    CHECK(pe_instrumentation_reset() == PE_STATUS_OK, "reset should succeed");
    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 0, "counter should be zero right after reset");

    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_OK,
          "project_node_query should succeed on valid input");
    CHECK(verdict == PE_VERDICT_SAME,
          "an unchanged, identically-typed field on both sides reports PE_VERDICT_SAME");

    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_OK,
          "project_node_query should succeed on valid input");

    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 2, "counter should tick once per project_node_query call");

    /* Negative paths: rejected without incrementing the counter. */
    CHECK(pe_project_node_query(NULL, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_NULL_HANDLE,
          "project_node_query(NULL map) should be rejected");
    CHECK(pe_project_node_query(map, NULL, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_NULL_HANDLE,
          "project_node_query(NULL operation) should be rejected");
    CHECK(pe_project_node_query(map, (pe_operation_t *)map, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1,
                                 &verdict) == PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(foreign operation) should be rejected");
    CHECK(acquire_shared_pair(&other_map), "acquiring a second map should succeed");
    CHECK(pe_project_node_query(other_map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1,
                                &verdict) == PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(mismatched map) should be rejected");
    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, NULL, 1, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(NULL path) should be rejected");
    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, 0, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(zero-length path) should be rejected");
    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, NULL) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(NULL out_verdict) should be rejected");
    CHECK(pe_project_node_query(map, operation, (pe_direction_t)9999, path, sizeof(path) - 1,
                                 &verdict) == PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(unrecognized direction) should be rejected, not coerced "
          "into a default");
    CHECK(pe_instrumentation_read(NULL) == PE_STATUS_INVALID_ARGUMENT,
          "instrumentation_read(NULL) should be rejected");

    pe_map_release(other_map);

    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 2, "rejected calls must not tick the counter");

    CHECK(pe_operation_end(operation) == PE_STATUS_OK, "end should succeed");
    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_OK,
          "project_node_query should still work against an ended-but-not-"
          "released operation");
    CHECK(pe_operation_release(operation) == PE_STATUS_OK, "release should succeed");
    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(released operation) should be rejected");

    pe_map_release(map);

    printf("instrumentation: reset/read deterministic, negative paths "
           "rejected without ticking the counter\n");
    return 0;
}

static int test_status_message_string_ownership_convention(void) {
    size_t required_len = 0;
    char *buffer;
    char small_buffer[2];

    /* First call: query the required length without a buffer. */
    CHECK(pe_status_message(PE_STATUS_INVALID_ARGUMENT, NULL, 0,
                             &required_len) == PE_STATUS_OK,
          "querying required_len should succeed");
    CHECK(required_len > 0, "message for a known status should be non-empty");

    /* Second call: caller-owned buffer sized from the first call. */
    buffer = malloc(required_len + 1);
    CHECK(buffer != NULL, "test allocation should succeed");
    CHECK(pe_status_message(PE_STATUS_INVALID_ARGUMENT, buffer,
                             required_len + 1, NULL) == PE_STATUS_OK,
          "filling a correctly sized buffer should succeed");
    CHECK(strlen(buffer) == required_len,
          "returned text should match the previously reported length");
    free(buffer);

    /* Undersized buffer: truncated, still NUL-terminated, status says so. */
    CHECK(pe_status_message(PE_STATUS_INVALID_ARGUMENT, small_buffer,
                             sizeof(small_buffer),
                             NULL) == PE_STATUS_BUFFER_TOO_SMALL,
          "an undersized buffer should be reported, not overrun");
    CHECK(small_buffer[sizeof(small_buffer) - 1] == '\0',
          "a truncated result must still be NUL-terminated");

    /* Unknown status code: rejected, not transmuted into an invalid enum. */
    CHECK(pe_status_message((pe_status_t)9999, NULL, 0, &required_len) ==
              PE_STATUS_INVALID_ARGUMENT,
          "an unrecognized status code should be rejected");

    printf("status_message: string ownership convention verified\n");
    return 0;
}

static int test_map_acquire_valid_pair_and_lifecycle(void) {
    pe_map_t *map = NULL;

    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &map) == PE_STATUS_OK,
          "acquiring a valid same-major pair should succeed");
    CHECK(map != NULL, "a successful acquire should hand back a non-null handle");
    CHECK(map_version_matches(map, PE_MAP_ROLE_STORED, "3.39.0"),
          "stored role should resolve to its own claimed version");
    CHECK(map_version_matches(map, PE_MAP_ROLE_WORKING, "3.38.1"),
          "working role should resolve to its own claimed version");

    CHECK(pe_map_release(NULL) == PE_STATUS_NULL_HANDLE,
          "releasing NULL should be rejected");
    CHECK(pe_map_release(map) == PE_STATUS_OK, "release should succeed");
    CHECK(pe_map_release(map) == PE_STATUS_INVALID_ARGUMENT,
          "releasing the same map handle twice should be rejected");
    CHECK(pe_map_version(map, PE_MAP_ROLE_STORED, NULL, 0, NULL) ==
              PE_STATUS_INVALID_ARGUMENT,
          "querying a released handle should be rejected, not dereferenced");

    printf("map acquire/release: valid pair produced a working handle\n");
    return 0;
}

static int test_map_acquire_parses_uniformly_regardless_of_role_order(void) {
    pe_map_t *forward = NULL;
    pe_map_t *reversed = NULL;

    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &forward) == PE_STATUS_OK,
          "forward role assignment should succeed");
    CHECK(pe_map_acquire(XML_WORKING_3_38_1, STR_LEN(XML_WORKING_3_38_1), "3.38.1",
                          STR_LEN("3.38.1"), XML_STORED_3_39_0,
                          STR_LEN(XML_STORED_3_39_0), "3.39.0", STR_LEN("3.39.0"),
                          &reversed) == PE_STATUS_OK,
          "reversed role assignment should succeed identically");

    CHECK(map_version_matches(forward, PE_MAP_ROLE_STORED, "3.39.0") &&
              map_version_matches(reversed, PE_MAP_ROLE_WORKING, "3.39.0"),
          "the 3.39.0 endpoint should resolve the same regardless of its role");
    CHECK(map_version_matches(forward, PE_MAP_ROLE_WORKING, "3.38.1") &&
              map_version_matches(reversed, PE_MAP_ROLE_STORED, "3.38.1"),
          "the 3.38.1 endpoint should resolve the same regardless of its role");

    pe_map_release(forward);
    pe_map_release(reversed);

    printf("map acquire: parsing is uniform regardless of which endpoint is "
           "stored or working\n");
    return 0;
}

static int test_map_acquire_negative_identity_paths(void) {
    pe_map_t *map = NULL;

    /* Malformed XML. */
    CHECK(pe_map_acquire(XML_MALFORMED, STR_LEN(XML_MALFORMED), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &map) == PE_STATUS_SCHEMA_IDENTITY,
          "malformed XML should be rejected as a schema identity condition");
    CHECK(map == NULL, "a rejected acquire should not produce a usable handle");

    /* Missing <version> element with no valid caller-supplied fallback. */
    map = NULL;
    CHECK(pe_map_acquire(XML_NO_VERSION_ELEMENT, STR_LEN(XML_NO_VERSION_ELEMENT),
                          "not-a-version", STR_LEN("not-a-version"),
                          XML_WORKING_3_38_1, STR_LEN(XML_WORKING_3_38_1), "3.38.1",
                          STR_LEN("3.38.1"), &map) == PE_STATUS_SCHEMA_IDENTITY,
          "a missing version with no valid fallback should be rejected");
    CHECK(map == NULL, "a rejected acquire should not produce a usable handle");

    /* An absent caller-supplied fallback is still an identity condition,
     * not an ABI argument violation, when XML also lacks <version>. */
    map = NULL;
    CHECK(pe_map_acquire(XML_NO_VERSION_ELEMENT, STR_LEN(XML_NO_VERSION_ELEMENT),
                          NULL, 0, XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &map) == PE_STATUS_SCHEMA_IDENTITY,
          "a missing version with an absent fallback should be rejected as identity");
    CHECK(map == NULL, "a rejected acquire should not produce a usable handle");

    /* Supplied/parsed identity mismatch: the XML says 3.39.0, the claim
     * says otherwise. */
    map = NULL;
    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "9.9.9",
                          STR_LEN("9.9.9"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &map) == PE_STATUS_SCHEMA_IDENTITY,
          "a claimed/parsed identity mismatch should be rejected");
    CHECK(map == NULL, "a rejected acquire should not produce a usable handle");

    printf("map acquire: malformed XML, missing identity, and mismatched "
           "identity rejected as expected, no handle produced\n");
    return 0;
}

static int test_map_acquire_cross_major_pair(void) {
    pe_map_t *map = NULL;

    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_CROSS_MAJOR_4_0_0,
                          STR_LEN(XML_CROSS_MAJOR_4_0_0), "4.0.0", STR_LEN("4.0.0"),
                          &map) == PE_STATUS_CROSS_MAJOR,
          "a cross-major pair should report the distinct cross-major status");
    CHECK(map == NULL, "a cross-major refusal should not produce a usable handle");

    /* Same pair, roles swapped: the refusal must not depend on which
     * endpoint is stored vs. working. */
    map = NULL;
    CHECK(pe_map_acquire(XML_CROSS_MAJOR_4_0_0, STR_LEN(XML_CROSS_MAJOR_4_0_0),
                          "4.0.0", STR_LEN("4.0.0"), XML_STORED_3_39_0,
                          STR_LEN(XML_STORED_3_39_0), "3.39.0", STR_LEN("3.39.0"),
                          &map) == PE_STATUS_CROSS_MAJOR,
          "cross-major refusal should be symmetric in role assignment");
    CHECK(map == NULL, "a cross-major refusal should not produce a usable handle");

    printf("map acquire: cross-major pair rejected distinctly from a schema "
           "identity condition, in both role orders\n");
    return 0;
}

static int test_map_acquire_copies_inputs_rather_than_borrowing_them(void) {
    pe_map_t *map = NULL;
    char stored_xml[128];
    char stored_claim[16];
    char working_xml[128];
    char working_claim[16];

    memcpy(stored_xml, XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0));
    memcpy(stored_claim, "3.39.0", STR_LEN("3.39.0"));
    memcpy(working_xml, XML_WORKING_3_38_1, STR_LEN(XML_WORKING_3_38_1));
    memcpy(working_claim, "3.38.1", STR_LEN("3.38.1"));

    CHECK(pe_map_acquire(stored_xml, STR_LEN(XML_STORED_3_39_0), stored_claim,
                          STR_LEN("3.39.0"), working_xml,
                          STR_LEN(XML_WORKING_3_38_1), working_claim,
                          STR_LEN("3.38.1"), &map) == PE_STATUS_OK,
          "acquiring from caller-owned buffers should succeed");

    /* Overwrite every input buffer immediately after the call returns. Per
     * pe_map_acquire's documented ownership rule, none of these pointers
     * is retained past the call, so the map's own resolved data must be
     * unaffected by this. */
    memset(stored_xml, 'x', sizeof(stored_xml));
    memset(stored_claim, 'x', sizeof(stored_claim));
    memset(working_xml, 'x', sizeof(working_xml));
    memset(working_claim, 'x', sizeof(working_claim));

    CHECK(map_version_matches(map, PE_MAP_ROLE_STORED, "3.39.0"),
          "stored version should survive the input buffer being overwritten");
    CHECK(map_version_matches(map, PE_MAP_ROLE_WORKING, "3.38.1"),
          "working version should survive the input buffer being overwritten");

    pe_map_release(map);

    printf("map acquire: resolved data is unaffected by reusing input "
           "buffers after the call returns\n");
    return 0;
}

static int test_map_acquire_input_validation(void) {
    pe_map_t *map = (pe_map_t *)(uintptr_t)UINTPTR_MAX;
    /* Sentinel: must stay unwritten on rejection. */

    CHECK(pe_map_acquire(NULL, 0, "3.39.0", STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &map) == PE_STATUS_INVALID_ARGUMENT,
          "a null stored_xml pointer should be rejected");
    CHECK(pe_map_acquire(XML_STORED_3_39_0, 0, "3.39.0", STR_LEN("3.39.0"),
                          XML_WORKING_3_38_1, STR_LEN(XML_WORKING_3_38_1), "3.38.1",
                          STR_LEN("3.38.1"), &map) == PE_STATUS_INVALID_ARGUMENT,
          "a zero-length stored_xml should be rejected");
    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          NULL) == PE_STATUS_INVALID_ARGUMENT,
          "a null out_map pointer should be rejected");
    CHECK((void *)map == (void *)(uintptr_t)UINTPTR_MAX,
          "a rejected acquire must leave out_map unwritten");

    CHECK(pe_map_release((pe_map_t *)(uintptr_t)UINTPTR_MAX) == PE_STATUS_INVALID_ARGUMENT,
          "releasing a foreign handle should be rejected, not dereferenced");

    CHECK(pe_map_version(NULL, PE_MAP_ROLE_STORED, NULL, 0, NULL) ==
              PE_STATUS_NULL_HANDLE,
          "querying a null map handle should be rejected");

    printf("map acquire: null/length/handle inputs rejected as expected\n");
    return 0;
}

static int test_map_version_rejects_unrecognized_role(void) {
    pe_map_t *map = NULL;

    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &map) == PE_STATUS_OK,
          "acquiring a valid pair should succeed");

    CHECK(pe_map_version(map, (pe_map_role_t)9999, NULL, 0, NULL) ==
              PE_STATUS_INVALID_ARGUMENT,
          "an unrecognized role should be rejected, not coerced into a default");

    pe_map_release(map);

    printf("map_version: unrecognized role rejected as expected\n");
    return 0;
}

/* pe_map_cache_identity (issue #22): proves that pe_map_acquire reuses a
 * process-wide cached pair across reacquisitions -- including with roles
 * reversed -- without this ABI exposing any Rust collection layout to do
 * so; the identity is an opaque token, compared only for equality. */

static int test_map_cache_identity_reuse_across_reacquire(void) {
    pe_map_t *first = NULL;
    pe_map_t *second = NULL;
    uint64_t first_identity = 0;
    uint64_t second_identity = 0;

    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &first) == PE_STATUS_OK,
          "first acquire of a pair should succeed");
    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &second) == PE_STATUS_OK,
          "reacquiring the same pair should succeed");
    CHECK(first != second,
          "each acquisition should still return its own independent handle");

    CHECK(pe_map_cache_identity(first, &first_identity) == PE_STATUS_OK,
          "cache identity of the first handle should be readable");
    CHECK(pe_map_cache_identity(second, &second_identity) == PE_STATUS_OK,
          "cache identity of the second handle should be readable");
    CHECK(first_identity == second_identity,
          "reacquiring the same pair should reuse the cached entry");

    /* Releasing one handle must not invalidate another live handle
     * referring to the same cached pair. */
    CHECK(pe_map_release(first) == PE_STATUS_OK, "releasing the first handle should succeed");
    CHECK(map_version_matches(second, PE_MAP_ROLE_STORED, "3.39.0"),
          "the second handle should remain usable after the first was released");
    CHECK(pe_map_cache_identity(second, &second_identity) == PE_STATUS_OK,
          "the second handle's cache identity should remain readable after the first "
          "was released");

    pe_map_release(second);

    printf("map cache identity: reacquiring the same pair reused one cached entry, and "
           "releasing one handle left the other independently live\n");
    return 0;
}

static int test_map_cache_identity_reuse_with_reversed_roles(void) {
    pe_map_t *forward = NULL;
    pe_map_t *reversed = NULL;
    uint64_t forward_identity = 0;
    uint64_t reversed_identity = 0;

    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &forward) == PE_STATUS_OK,
          "forward role assignment should succeed");
    CHECK(pe_map_acquire(XML_WORKING_3_38_1, STR_LEN(XML_WORKING_3_38_1), "3.38.1",
                          STR_LEN("3.38.1"), XML_STORED_3_39_0,
                          STR_LEN(XML_STORED_3_39_0), "3.39.0", STR_LEN("3.39.0"),
                          &reversed) == PE_STATUS_OK,
          "reversed role assignment should succeed");

    CHECK(pe_map_cache_identity(forward, &forward_identity) == PE_STATUS_OK,
          "the forward handle's cache identity should be readable");
    CHECK(pe_map_cache_identity(reversed, &reversed_identity) == PE_STATUS_OK,
          "the reversed handle's cache identity should be readable");
    CHECK(forward_identity == reversed_identity,
          "reversed caller endpoint ordering should still reuse the same cached pair");

    /* Stored/working roles must still resolve correctly per handle even
     * though the underlying cached pair's identity is normalized. */
    CHECK(map_version_matches(forward, PE_MAP_ROLE_STORED, "3.39.0") &&
              map_version_matches(reversed, PE_MAP_ROLE_WORKING, "3.39.0"),
          "each handle should resolve the 3.39.0 endpoint under its own requested role");
    CHECK(map_version_matches(forward, PE_MAP_ROLE_WORKING, "3.38.1") &&
              map_version_matches(reversed, PE_MAP_ROLE_STORED, "3.38.1"),
          "each handle should resolve the 3.38.1 endpoint under its own requested role");

    pe_map_release(forward);
    pe_map_release(reversed);

    printf("map cache identity: reversed role order reused the same cached pair while "
           "each handle kept its own roles correct\n");
    return 0;
}

static int test_map_cache_identity_distinguishes_different_pairs(void) {
    pe_map_t *pair_one = NULL;
    pe_map_t *pair_two = NULL;
    uint64_t identity_one = 0;
    uint64_t identity_two = 0;

    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &pair_one) == PE_STATUS_OK,
          "acquiring the first pair should succeed");
    CHECK(pe_map_acquire(XML_OTHER_PAIR_STORED, STR_LEN(XML_OTHER_PAIR_STORED), "5.10.0",
                          STR_LEN("5.10.0"), XML_OTHER_PAIR_WORKING,
                          STR_LEN(XML_OTHER_PAIR_WORKING), "5.9.9", STR_LEN("5.9.9"),
                          &pair_two) == PE_STATUS_OK,
          "acquiring a distinct pair should succeed");

    CHECK(pe_map_cache_identity(pair_one, &identity_one) == PE_STATUS_OK,
          "the first pair's cache identity should be readable");
    CHECK(pe_map_cache_identity(pair_two, &identity_two) == PE_STATUS_OK,
          "the second pair's cache identity should be readable");
    CHECK(identity_one != identity_two,
          "distinct schema pairs should not share a cache identity");

    /* Releasing the first pair's handle must not disturb the second,
     * unrelated live pair. */
    CHECK(pe_map_release(pair_one) == PE_STATUS_OK, "releasing the first pair should succeed");
    CHECK(map_version_matches(pair_two, PE_MAP_ROLE_STORED, "5.10.0"),
          "the second pair should be unaffected by releasing the first pair's handle");

    pe_map_release(pair_two);

    printf("map cache identity: distinct schema pairs reported distinct cache "
           "identities and did not affect each other\n");
    return 0;
}

static int test_map_cache_identity_input_validation(void) {
    pe_map_t *map = NULL;
    uint64_t identity = 0;

    CHECK(pe_map_cache_identity(NULL, &identity) == PE_STATUS_NULL_HANDLE,
          "a null map handle should be rejected");

    CHECK(pe_map_acquire(XML_STORED_3_39_0, STR_LEN(XML_STORED_3_39_0), "3.39.0",
                          STR_LEN("3.39.0"), XML_WORKING_3_38_1,
                          STR_LEN(XML_WORKING_3_38_1), "3.38.1", STR_LEN("3.38.1"),
                          &map) == PE_STATUS_OK,
          "acquiring a valid pair should succeed");

    CHECK(pe_map_cache_identity(map, NULL) == PE_STATUS_INVALID_ARGUMENT,
          "a null out_identity pointer should be rejected");

    CHECK(pe_map_release(map) == PE_STATUS_OK, "release should succeed");
    CHECK(pe_map_cache_identity(map, &identity) == PE_STATUS_INVALID_ARGUMENT,
          "querying a released handle should be rejected, not dereferenced");

    printf("map cache identity: null/foreign/released handle inputs rejected as "
           "expected\n");
    return 0;
}

/*
 * pe_project_node_query real classifications (issue #23): the four
 * rename-metadata-free vectors -- unchanged, compiled-only/stored-only
 * (both are the same SourceOnly classification, disambiguated only by
 * which schema `direction` selects as source), and datatype-changed --
 * driven through the shared nine-feature fixture pair above. Per that
 * fixture's own doc comment, none of the other five feature nodes are
 * asserted here; only #24/#25 may add vectors for those, against fields
 * this ticket does not touch.
 */

static int test_projection_unchanged_field_reports_same_in_both_directions(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict;
    const char path[] = "unchanged_leaf";

    CHECK(pe_map_acquire(XML_FIXTURE_OLD_20_1_0, STR_LEN(XML_FIXTURE_OLD_20_1_0), "20.1.0",
                          STR_LEN("20.1.0"), XML_FIXTURE_NEW_20_2_0,
                          STR_LEN(XML_FIXTURE_NEW_20_2_0), "20.2.0", STR_LEN("20.2.0"),
                          &map) == PE_STATUS_OK,
          "acquiring the shared fixture pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
                                 sizeof(path) - 1, &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SAME,
          "an unchanged field should report PE_VERDICT_SAME with source=working");
    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_STORED_TO_WORKING, path,
                                 sizeof(path) - 1, &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SAME,
          "an unchanged field should report PE_VERDICT_SAME with source=stored too");

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: unchanged field reported PE_VERDICT_SAME in both "
           "directions\n");
    return 0;
}

static int test_projection_added_and_removed_fields_report_skip_in_both_directions(void) {
    pe_map_t *natural = NULL;
    pe_map_t *reversed = NULL;
    pe_operation_t *natural_op = NULL;
    pe_operation_t *reversed_op = NULL;
    pe_verdict_t verdict;
    const char added_path[] = "added_only_field";
    const char removed_path[] = "removed_only_field";

    /* Natural acquisition: stored=OLD, working=NEW. */
    CHECK(pe_map_acquire(XML_FIXTURE_OLD_20_1_0, STR_LEN(XML_FIXTURE_OLD_20_1_0), "20.1.0",
                          STR_LEN("20.1.0"), XML_FIXTURE_NEW_20_2_0,
                          STR_LEN(XML_FIXTURE_NEW_20_2_0), "20.2.0", STR_LEN("20.2.0"),
                          &natural) == PE_STATUS_OK,
          "acquiring the shared fixture pair should succeed");
    CHECK(pe_operation_begin(natural, &natural_op) == PE_STATUS_OK, "begin should succeed");

    /* added_only_field: present only in NEW/working -- compiled-only from
     * the natural working-to-stored direction. */
    CHECK(pe_project_node_query(natural, natural_op, PE_DIRECTION_WORKING_TO_STORED,
                                 added_path, sizeof(added_path) - 1,
                                 &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "a field present only in the working schema should report PE_VERDICT_SKIP");

    /* removed_only_field: present only in OLD/stored -- stored-only from
     * the reciprocal stored-to-working direction. */
    CHECK(pe_project_node_query(natural, natural_op, PE_DIRECTION_STORED_TO_WORKING,
                                 removed_path, sizeof(removed_path) - 1,
                                 &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "a field present only in the stored schema should report PE_VERDICT_SKIP");

    /* Reversed acquisition: stored=NEW, working=OLD. Proves the verdict is
     * driven purely by `direction`, not by which literal endpoint was
     * labelled stored/working at acquire time. */
    CHECK(pe_map_acquire(XML_FIXTURE_NEW_20_2_0, STR_LEN(XML_FIXTURE_NEW_20_2_0), "20.2.0",
                          STR_LEN("20.2.0"), XML_FIXTURE_OLD_20_1_0,
                          STR_LEN(XML_FIXTURE_OLD_20_1_0), "20.1.0", STR_LEN("20.1.0"),
                          &reversed) == PE_STATUS_OK,
          "acquiring the fixture pair with roles reversed should succeed");
    CHECK(pe_operation_begin(reversed, &reversed_op) == PE_STATUS_OK, "begin should succeed");

    CHECK(pe_project_node_query(reversed, reversed_op, PE_DIRECTION_STORED_TO_WORKING,
                                 added_path, sizeof(added_path) - 1,
                                 &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "added field should still report PE_VERDICT_SKIP with roles reversed");
    CHECK(pe_project_node_query(reversed, reversed_op, PE_DIRECTION_WORKING_TO_STORED,
                                 removed_path, sizeof(removed_path) - 1,
                                 &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "removed field should still report PE_VERDICT_SKIP with roles reversed");

    pe_operation_release(natural_op);
    pe_map_release(natural);
    pe_operation_release(reversed_op);
    pe_map_release(reversed);

    printf("project_node_query: added/removed fields reported PE_VERDICT_SKIP "
           "regardless of caller endpoint ordering\n");
    return 0;
}

static int test_projection_datatype_changed_field_reports_skip_in_both_directions(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict;
    const char path[] = "retyped_field";

    CHECK(pe_map_acquire(XML_FIXTURE_OLD_20_1_0, STR_LEN(XML_FIXTURE_OLD_20_1_0), "20.1.0",
                          STR_LEN("20.1.0"), XML_FIXTURE_NEW_20_2_0,
                          STR_LEN(XML_FIXTURE_NEW_20_2_0), "20.2.0", STR_LEN("20.2.0"),
                          &map) == PE_STATUS_OK,
          "acquiring the shared fixture pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
                                 sizeof(path) - 1, &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "a datatype change should report PE_VERDICT_SKIP with source=working");
    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_STORED_TO_WORKING, path,
                                 sizeof(path) - 1, &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "a datatype change should report PE_VERDICT_SKIP with source=stored too");

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: datatype-changed field reported PE_VERDICT_SKIP in "
           "both directions\n");
    return 0;
}

static int test_projection_unknown_path_is_rejected(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict = PE_VERDICT_SAME;
    uint64_t count = 0;
    const char path[] = "does/not/exist";

    CHECK(pe_map_acquire(XML_FIXTURE_OLD_20_1_0, STR_LEN(XML_FIXTURE_OLD_20_1_0), "20.1.0",
                          STR_LEN("20.1.0"), XML_FIXTURE_NEW_20_2_0,
                          STR_LEN(XML_FIXTURE_NEW_20_2_0), "20.2.0", STR_LEN("20.2.0"),
                          &map) == PE_STATUS_OK,
          "acquiring the shared fixture pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    CHECK(pe_instrumentation_reset() == PE_STATUS_OK, "reset should succeed");

    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
                                 sizeof(path) - 1, &verdict) == PE_STATUS_INVALID_ARGUMENT,
          "a path unknown to the source schema should be rejected");
    CHECK(verdict == PE_VERDICT_SAME, "a rejected query must leave out_verdict unwritten");

    /* The counter tracks "entered", not "resolved": an unknown path still
     * reaches project_node (unlike the null-handle/bad-direction negative
     * paths in test_projection_entry_instrumentation, which are rejected
     * before entry and correctly do not tick it). */
    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 1,
          "a query unknown to the source schema still counts as an entry");

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: a path unknown to the source schema was rejected, and "
           "still counted as a projection entry\n");
    return 0;
}

/* Proves PE_STATUS_RENAME_PENDING itself works end to end through the ABI,
 * using the small ad-hoc pair kept deliberately separate from the shared
 * nine-feature fixture (see that pair's own doc comment for why). */
static int test_projection_rename_tagged_node_reports_rename_pending(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict = PE_VERDICT_SAME;
    const char path[] = "tagged";

    CHECK(pe_map_acquire(XML_RENAME_PENDING_TARGET, STR_LEN(XML_RENAME_PENDING_TARGET),
                          "30.1.0", STR_LEN("30.1.0"), XML_RENAME_PENDING_SOURCE,
                          STR_LEN(XML_RENAME_PENDING_SOURCE), "30.2.0", STR_LEN("30.2.0"),
                          &map) == PE_STATUS_OK,
          "acquiring the rename-pending smoke pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
                                 sizeof(path) - 1, &verdict) == PE_STATUS_RENAME_PENDING,
          "a node carrying automatic rename metadata should report "
          "PE_STATUS_RENAME_PENDING rather than a fabricated verdict");
    CHECK(verdict == PE_VERDICT_SAME,
          "a PE_STATUS_RENAME_PENDING result must leave out_verdict unwritten");

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: a rename-tagged node reported PE_STATUS_RENAME_PENDING "
           "instead of a fabricated verdict\n");
    return 0;
}

/*
 * Proves, through the ABI and against the real shared nine-feature fixture
 * (not just the deliberately-separate ad-hoc pair above), that querying a
 * field which carries automatic rename metadata on its own `<field>`
 * element reports PE_STATUS_RENAME_PENDING rather than a fabricated verdict.
 * This covers the NEW-side name of each of the six rename-bearing features
 * (1-4, 8, 9) via the natural PE_DIRECTION_WORKING_TO_STORED direction,
 * where the classification depends only on the field's own tag -- not on
 * FieldIndex::mentions_as_previous_name's exact-path heuristic, which this
 * ticket's own fixture comment already documents as incomplete for some of
 * these paths in the reverse direction.
 *
 * Unlike the four vectors in
 * test_projection_{unchanged_field,added_and_removed_fields,
 * datatype_changed_field}_reports_*, this test is NOT one of the vectors
 * issue #23's acceptance criteria requires to remain valid and unedited:
 * once #24/#25 give these specific features a real resolved verdict, this
 * test *must* be updated (paths it activates removed from here, mirroring
 * the durable-vector comment's own warning). It exists only to prove the
 * "not silently reclassified as add/remove" guarantee against the actual
 * shared corpus through the ABI seam, rather than solely through
 * `projection.rs`'s Rust-internal unit tests, which use different literal
 * XML.
 */
static int test_projection_shared_fixture_rename_bearing_fields_report_rename_pending(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict;
    static const char *const rename_tagged_paths[] = {
        "new_leaf_name",       /* feature 1: leaf rename */
        "new_struct",          /* feature 2: plain-structure rename+cascade */
        "new_aos",             /* feature 3: array-of-structures rename */
        "thrice_renamed",      /* feature 4: successive rename history */
        "dynamic_group/signal", /* feature 8: renamed time-dependent node */
        "rescued_signal",      /* feature 9: missing parent, reachable descendant */
    };
    size_t i;

    CHECK(pe_map_acquire(XML_FIXTURE_OLD_20_1_0, STR_LEN(XML_FIXTURE_OLD_20_1_0), "20.1.0",
                          STR_LEN("20.1.0"), XML_FIXTURE_NEW_20_2_0,
                          STR_LEN(XML_FIXTURE_NEW_20_2_0), "20.2.0", STR_LEN("20.2.0"),
                          &map) == PE_STATUS_OK,
          "acquiring the shared fixture pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    for (i = 0; i < sizeof(rename_tagged_paths) / sizeof(rename_tagged_paths[0]); ++i) {
        const char *path = rename_tagged_paths[i];
        size_t path_len = strlen(path);

        verdict = PE_VERDICT_SAME;
        CHECK(pe_project_node_query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
                                     path_len, &verdict) == PE_STATUS_RENAME_PENDING,
              "a rename-tagged shared-fixture field should report "
              "PE_STATUS_RENAME_PENDING rather than a fabricated verdict");
        CHECK(verdict == PE_VERDICT_SAME,
              "a PE_STATUS_RENAME_PENDING result must leave out_verdict unwritten");
    }

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: every rename-bearing field in the shared fixture "
           "reported PE_STATUS_RENAME_PENDING through the ABI\n");
    return 0;
}

int main(void) {
    int failures = 0;

    failures += test_operation_lifecycle_and_input_validation();
    failures += test_released_operation_token_never_aliases_a_new_operation();
    failures += test_operation_survives_its_map_handle_being_released();
    failures += test_operations_stay_isolated_across_handles();
    failures += test_operation_and_map_handles_are_not_interchangeable();
    failures += test_projection_entry_instrumentation();
    failures += test_status_message_string_ownership_convention();
    failures += test_map_acquire_valid_pair_and_lifecycle();
    failures += test_map_acquire_parses_uniformly_regardless_of_role_order();
    failures += test_map_acquire_negative_identity_paths();
    failures += test_map_acquire_cross_major_pair();
    failures += test_map_acquire_copies_inputs_rather_than_borrowing_them();
    failures += test_map_acquire_input_validation();
    failures += test_map_version_rejects_unrecognized_role();
    failures += test_map_cache_identity_reuse_across_reacquire();
    failures += test_map_cache_identity_reuse_with_reversed_roles();
    failures += test_map_cache_identity_distinguishes_different_pairs();
    failures += test_map_cache_identity_input_validation();
    failures += test_projection_unchanged_field_reports_same_in_both_directions();
    failures += test_projection_added_and_removed_fields_report_skip_in_both_directions();
    failures += test_projection_datatype_changed_field_reports_skip_in_both_directions();
    failures += test_projection_unknown_path_is_rejected();
    failures += test_projection_rename_tagged_node_reports_rename_pending();
    failures += test_projection_shared_fixture_rename_bearing_fields_report_rename_pending();

    if (failures == 0) {
        printf("contract test: all checks passed\n");
    }
    return failures;
}
