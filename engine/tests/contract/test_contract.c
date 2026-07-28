/*
 * C contract test for the projection-engine ABI (IMAS-Fortran #20, #21,
 * #22, #23, #24, #28, #31).
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
 * features 5, 6, and 7 were asserted through the ABI by issue #23 with a
 * durable, must-remain-valid verdict -- see #23's own acceptance criteria
 * on why a *durable* verdict for the six rename-bearing features (1-4, 8,
 * 9) could not be asserted by that ticket: #24/#25 legitimately reclassify
 * them once rename resolution lands, and asserting a specific resolved
 * verdict there would have made that ticket's own vectors the thing that
 * breaks. Issue #24 now activates leaf_renamed resolution for four of
 * those six (1, 4, 8, 9 -- see
 * test_projection_shared_fixture_leaf_and_successive_rename_features_resolve
 * and test_projection_shared_fixture_time_dependent_and_missing_parent_renames_resolve
 * below); the remaining two (2, 3 -- aos_renamed/structure_renamed) stay in
 * test_projection_shared_fixture_rename_bearing_fields_report_rename_pending,
 * pending issue #25.
 *
 * Note for #25: querying the OLD-side paths of features 2/3 via
 * PE_DIRECTION_STORED_TO_WORKING reports PE_STATUS_RENAME_PENDING rather
 * than a fabricated added/removed skip. FieldIndex::may_have_renamed_from
 * (src/projection.rs) recognizes exact predecessor paths, bare predecessor
 * names within their unchanged parent, and descendants of renamed
 * structures/AoSs. Do not read that conservative pending guard as rename
 * resolution: #25 still determines the actual same/rename verdict for
 * those two.
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
 * state" requirement). Uses structure_renamed rather than leaf_renamed:
 * issue #24 resolves leaf_renamed into a real verdict, so only
 * aos_renamed/structure_renamed still report PE_STATUS_RENAME_PENDING
 * pending issue #25, and this smoke test must keep exercising a kind that
 * is genuinely still pending. */
#define XML_RENAME_PENDING_SOURCE                                            \
    "<IDSs><version>30.2.0</version>"                                       \
    "<field name=\"tagged\" path=\"tagged\" data_type=\"structure\" "         \
    "change_nbc_version=\"30.2.0\" change_nbc_description=\"structure_renamed\" " \
    "change_nbc_previous_name=\"untagged\"/></IDSs>"
#define XML_RENAME_PENDING_TARGET                                            \
    "<IDSs><version>30.1.0</version>"                                       \
    "<field name=\"untagged\" path=\"untagged\" data_type=\"structure\"/></IDSs>"

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

/* Thin wrapper over pe_project_node_query for every call site that only
 * cares about the status/verdict, not the projected-path output added by
 * issue #24 -- passes NULL/0/NULL for the trailing three parameters,
 * which is exactly what that convention documents as "just tell me the
 * required length" and is harmless when no rename is expected anyway. */
static pe_status_t query(const pe_map_t *map, pe_operation_t *operation,
                          pe_direction_t direction, const char *node_path,
                          size_t node_path_len, pe_verdict_t *out_verdict) {
    return pe_project_node_query(map, operation, direction, node_path,
                                  node_path_len, out_verdict, NULL, 0, NULL);
}

/* Reads back the projected path from a PE_VERDICT_RENAME result and
 * compares it against `expected`, exercising the same query-then-fill
 * buffer convention as map_version_matches above (issue #24). */
static int projected_path_matches(const pe_map_t *map, pe_operation_t *operation,
                                   pe_direction_t direction, const char *node_path,
                                   size_t node_path_len, const char *expected) {
    pe_verdict_t verdict = PE_VERDICT_SAME;
    size_t required_len = 0;
    char buffer[64];

    if (pe_project_node_query(map, operation, direction, node_path, node_path_len,
                               &verdict, NULL, 0, &required_len) != PE_STATUS_OK) {
        return 0;
    }
    if (verdict != PE_VERDICT_RENAME) {
        return 0;
    }
    if (required_len >= sizeof(buffer)) {
        return 0;
    }
    verdict = PE_VERDICT_SAME;
    if (pe_project_node_query(map, operation, direction, node_path, node_path_len,
                               &verdict, buffer, sizeof(buffer), NULL) != PE_STATUS_OK) {
        return 0;
    }
    return verdict == PE_VERDICT_RENAME && strcmp(buffer, expected) == 0;
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
    CHECK(query(map, released, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
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

    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
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

    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_OK,
          "project_node_query should succeed on valid input");
    CHECK(verdict == PE_VERDICT_SAME,
          "an unchanged, identically-typed field on both sides reports PE_VERDICT_SAME");

    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_OK,
          "project_node_query should succeed on valid input");

    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 2, "counter should tick once per project_node_query call");

    /* Negative paths: rejected without incrementing the counter. */
    CHECK(query(NULL, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_NULL_HANDLE,
          "project_node_query(NULL map) should be rejected");
    CHECK(query(map, NULL, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_NULL_HANDLE,
          "project_node_query(NULL operation) should be rejected");
    CHECK(query(map, (pe_operation_t *)map, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1,
                                 &verdict) == PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(foreign operation) should be rejected");
    CHECK(acquire_shared_pair(&other_map), "acquiring a second map should succeed");
    CHECK(query(other_map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1,
                                &verdict) == PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(mismatched map) should be rejected");
    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, NULL, 1, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(NULL path) should be rejected");
    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, 0, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(zero-length path) should be rejected");
    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, NULL) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(NULL out_verdict) should be rejected");
    CHECK(query(map, operation, (pe_direction_t)9999, path, sizeof(path) - 1,
                                 &verdict) == PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(unrecognized direction) should be rejected, not coerced "
          "into a default");
    CHECK(pe_instrumentation_read(NULL) == PE_STATUS_INVALID_ARGUMENT,
          "instrumentation_read(NULL) should be rejected");

    pe_map_release(other_map);

    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 2, "rejected calls must not tick the counter");

    CHECK(pe_operation_end(operation) == PE_STATUS_OK, "end should succeed");
    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_OK,
          "project_node_query should still work against an ended-but-not-"
          "released operation");
    CHECK(pe_operation_release(operation) == PE_STATUS_OK, "release should succeed");
    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1, &verdict) ==
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
 * Bounded LRU eviction (issue #28): the cache reuse proven above never
 * evicts in this suite's other tests because none of them acquire more
 * than a handful of distinct pairs. The vectors below deliberately push
 * enough *additional*, mutually distinct pairs through the cache to force
 * real eviction, then observe the result purely through pe_map_acquire /
 * pe_map_release / pe_map_cache_identity -- the same production ABI used
 * everywhere else in this file -- without this suite ever inspecting the
 * engine's internal HashMap/LRU representation.
 *
 * EVICTION_PROOF_PAIR_COUNT is chosen to comfortably exceed CACHE_CAPACITY
 * (engine/src/cache.rs), including headroom for every other distinct pair
 * this file's other tests have already put through the same process-wide
 * cache by the time these run. If CACHE_CAPACITY ever changes, keep this
 * constant safely above it -- this is a hand-maintained cross-reference,
 * like the header/`src/ffi.rs` pairing documented at the top of this file,
 * not a generated one.
 */
#define EVICTION_PROOF_PAIR_COUNT 100

/* Builds and acquires the `index`-th of a run of mutually distinct
 * same-major synthetic pairs used only to put eviction pressure on the
 * cache; `index` must be unique across every call site in this file so
 * concurrent proof vectors cannot collide with each other's pairs. */
static int acquire_eviction_pressure_pair(int index, pe_map_t **out_map) {
    char stored_xml[128];
    char working_xml[128];
    char stored_version[32];
    char working_version[32];
    int major = 20000 + index;

    snprintf(stored_version, sizeof(stored_version), "%d.1.0", major);
    snprintf(working_version, sizeof(working_version), "%d.0.9", major);
    snprintf(stored_xml, sizeof(stored_xml), "<IDSs><version>%s</version></IDSs>",
             stored_version);
    snprintf(working_xml, sizeof(working_xml), "<IDSs><version>%s</version></IDSs>",
             working_version);

    return pe_map_acquire(stored_xml, strlen(stored_xml), stored_version,
                           strlen(stored_version), working_xml, strlen(working_xml),
                           working_version, strlen(working_version), out_map) == PE_STATUS_OK;
}

/* Acquires and immediately releases the `index`-th eviction-pressure pair
 * (see acquire_eviction_pressure_pair), applying one unit of eviction
 * pressure without needing a kept handle. Returns 0 on success, 1 on
 * failure (the same convention as every test function's CHECK-driven
 * return below); shared by both eviction-proof tests so they don't
 * duplicate this loop body. */
static int apply_one_eviction_pressure_pair(int index) {
    pe_map_t *pressure = NULL;
    CHECK(acquire_eviction_pressure_pair(index, &pressure),
          "acquiring an eviction-pressure pair should succeed");
    pe_map_release(pressure);
    return 0;
}

/* Acquiring enough distinct pairs evicts the least-recently-used entry;
 * evicting it never invalidates a live caller handle still referencing it;
 * and reacquiring the evicted content afterwards rebuilds a fresh, distinct
 * cache entry rather than reusing the evicted one. */
static int test_map_cache_eviction_evicts_the_least_recently_used_pair(void) {
    pe_map_t *kept = NULL;
    pe_map_t *reacquired = NULL;
    uint64_t identity_before = 0;
    uint64_t identity_while_live = 0;
    uint64_t identity_after_reacquire = 0;
    int i;

    CHECK(acquire_shared_pair(&kept), "acquiring the pair to keep alive should succeed");
    CHECK(pe_map_cache_identity(kept, &identity_before) == PE_STATUS_OK,
          "reading the kept pair's initial cache identity should succeed");

    /* Push enough distinct pairs through the cache, without ever touching
     * `kept` again, to force it out as the least-recently-used entry. */
    for (i = 0; i < EVICTION_PROOF_PAIR_COUNT; ++i) {
        if (apply_one_eviction_pressure_pair(i)) {
            return 1;
        }
    }

    /* Eviction must never invalidate a live caller handle: `kept` was never
     * released, so it must still resolve exactly as it did before any
     * eviction pressure was applied. */
    CHECK(pe_map_cache_identity(kept, &identity_while_live) == PE_STATUS_OK,
          "the live kept handle's cache identity should remain readable after "
          "eviction pressure");
    CHECK(identity_while_live == identity_before,
          "a live handle's own cache identity must be unaffected by its cache "
          "entry being evicted");
    CHECK(map_version_matches(kept, PE_MAP_ROLE_STORED, "3.39.0"),
          "the live kept handle should still resolve its version after eviction "
          "pressure");

    /* Reacquiring the exact same content now rebuilds a fresh entry instead
     * of reusing the (evicted) cached one, and does so safely: this new
     * acquisition succeeds and does not disturb the still-live `kept`
     * handle from above. */
    CHECK(acquire_shared_pair(&reacquired), "reacquiring the same pair should still succeed");
    CHECK(pe_map_cache_identity(reacquired, &identity_after_reacquire) == PE_STATUS_OK,
          "reading the reacquired pair's cache identity should succeed");
    CHECK(identity_after_reacquire != identity_before,
          "reacquiring an evicted pair should rebuild it as a fresh, distinct "
          "cache entry");
    CHECK(pe_map_cache_identity(kept, &identity_while_live) == PE_STATUS_OK &&
              identity_while_live == identity_before,
          "the original live handle must remain unaffected by the reacquisition "
          "that rebuilt its evicted entry");

    pe_map_release(reacquired);
    pe_map_release(kept);

    printf("map cache eviction: an untouched pair was evicted under pressure, its "
           "live handle stayed valid throughout, and reacquiring it rebuilt a fresh, "
           "independent entry\n");
    return 0;
}

/* Reusing a cached pair updates its recency without rebuilding it: a pair
 * reacquired periodically while unrelated eviction pressure is applied to
 * many other distinct pairs must never itself be evicted. */
static int test_map_cache_touching_a_pair_under_pressure_prevents_its_eviction(void) {
    pe_map_t *touched = NULL;
    uint64_t touched_identity = 0;
    uint64_t identity_now = 0;
    const int touch_every = 10;
    int i;

    CHECK(acquire_shared_pair(&touched), "acquiring the touched pair should succeed");
    CHECK(pe_map_cache_identity(touched, &touched_identity) == PE_STATUS_OK,
          "reading the touched pair's initial cache identity should succeed");
    pe_map_release(touched);
    touched = NULL;

    for (i = 0; i < EVICTION_PROOF_PAIR_COUNT; ++i) {
        /* Distinct index range from the previous test's pressure pairs so
         * the two proofs cannot collide on the same synthetic content. */
        if (apply_one_eviction_pressure_pair(EVICTION_PROOF_PAIR_COUNT + i)) {
            return 1;
        }

        if (i % touch_every == 0) {
            CHECK(acquire_shared_pair(&touched),
                  "reacquiring (touching) the pair mid-pressure should succeed");
            CHECK(pe_map_cache_identity(touched, &identity_now) == PE_STATUS_OK,
                  "reading the touched pair's cache identity should succeed");
            CHECK(identity_now == touched_identity,
                  "a pair reacquired often enough to stay recent must never be "
                  "evicted by pressure on other pairs");
            pe_map_release(touched);
            touched = NULL;
        }
    }

    CHECK(acquire_shared_pair(&touched), "final reacquire should succeed");
    CHECK(pe_map_cache_identity(touched, &identity_now) == PE_STATUS_OK,
          "reading the touched pair's final cache identity should succeed");
    CHECK(identity_now == touched_identity,
          "a periodically reacquired pair must never have been evicted");
    pe_map_release(touched);

    printf("map cache eviction: periodically reacquiring a pair kept it alive "
           "under sustained eviction pressure on other pairs\n");
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

    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
                                 sizeof(path) - 1, &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SAME,
          "an unchanged field should report PE_VERDICT_SAME with source=working");
    CHECK(query(map, operation, PE_DIRECTION_STORED_TO_WORKING, path,
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
    CHECK(query(natural, natural_op, PE_DIRECTION_WORKING_TO_STORED,
                                 added_path, sizeof(added_path) - 1,
                                 &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "a field present only in the working schema should report PE_VERDICT_SKIP");

    /* removed_only_field: present only in OLD/stored -- stored-only from
     * the reciprocal stored-to-working direction. */
    CHECK(query(natural, natural_op, PE_DIRECTION_STORED_TO_WORKING,
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

    CHECK(query(reversed, reversed_op, PE_DIRECTION_STORED_TO_WORKING,
                                 added_path, sizeof(added_path) - 1,
                                 &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "added field should still report PE_VERDICT_SKIP with roles reversed");
    CHECK(query(reversed, reversed_op, PE_DIRECTION_WORKING_TO_STORED,
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

    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
                                 sizeof(path) - 1, &verdict) == PE_STATUS_OK &&
              verdict == PE_VERDICT_SKIP,
          "a datatype change should report PE_VERDICT_SKIP with source=working");
    CHECK(query(map, operation, PE_DIRECTION_STORED_TO_WORKING, path,
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

    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
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

    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
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
 * field which carries aos_renamed/structure_renamed metadata on its own
 * `<field>` element still reports PE_STATUS_RENAME_PENDING rather than a
 * fabricated verdict, now that issue #24 has resolved the other four
 * rename-bearing features (1, 4, 8, 9 -- see
 * test_projection_shared_fixture_leaf_and_successive_rename_features_resolve
 * and
 * test_projection_shared_fixture_time_dependent_and_missing_parent_renames_resolve
 * below) into real verdicts. This test itself was updated by issue #24 per
 * its own predecessor's warning ("this test *must* be updated"): it
 * originally covered all six rename-bearing features and is narrowed here
 * to the two (2, 3) that remain pending issue #25.
 *
 * Unlike the four vectors in
 * test_projection_{unchanged_field,added_and_removed_fields,
 * datatype_changed_field}_reports_*, this test is NOT one of the vectors
 * issue #23's acceptance criteria requires to remain valid and unedited:
 * once #25 gives these two remaining features a real resolved verdict,
 * this test must be updated again the same way.
 */
static int test_projection_shared_fixture_rename_bearing_fields_report_rename_pending(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict;
    static const char *const rename_tagged_paths[] = {
        "new_struct",          /* feature 2: plain-structure rename+cascade */
        "new_aos",             /* feature 3: array-of-structures rename */
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
        CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path,
                                     path_len, &verdict) == PE_STATUS_RENAME_PENDING,
              "a rename-tagged shared-fixture field should report "
              "PE_STATUS_RENAME_PENDING rather than a fabricated verdict");
        CHECK(verdict == PE_VERDICT_SAME,
              "a PE_STATUS_RENAME_PENDING result must leave out_verdict unwritten");
    }

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: the two aos/structure-renamed fields in the shared "
           "fixture still reported PE_STATUS_RENAME_PENDING through the ABI\n");
    return 0;
}

/*
 * Issue #24 parity vector (issue #13/#18's cutoff-selection portability
 * rule), driven against a dedicated ad-hoc pair so the older-endpoint
 * cutoff and comma-separated history can be exercised at version gaps the
 * shared fixture's own fixed 20.1.0/20.2.0 pair does not cover. Both
 * endpoints share major version 70 (a same-major pair is required for
 * pe_map_acquire to succeed at all); three releases (70.10.0, 70.11.0,
 * 70.12.0) each rename the field once, and acquiring the pair at an older
 * endpoint of 70.10.5 must select the second entry (70.11.0 -> "v1_name"),
 * ignoring the first (70.10.0 -> "v0_name"), which predates this gap.
 */
#define XML_GAP_OLDER_70_10_5                                                \
    "<IDSs><version>70.10.5</version>"                                      \
    "<field name=\"v1\" path=\"v1_name\" data_type=\"STR_0D\"/></IDSs>"
#define XML_GAP_NEWER_70_13_0                                                \
    "<IDSs><version>70.13.0</version>"                                      \
    "<field name=\"v3\" path=\"v3_name\" data_type=\"STR_0D\" "               \
    "change_nbc_version=\"70.10.0,70.11.0,70.12.0\" "                       \
    "change_nbc_description=\"leaf_renamed\" "                              \
    "change_nbc_previous_name=\"v0_name,v1_name,v2_name\"/></IDSs>"

static int test_projection_successive_rename_history_resolves_across_a_multi_release_gap(void) {
    pe_map_t *natural = NULL;
    pe_map_t *reversed = NULL;
    pe_operation_t *natural_op = NULL;
    pe_operation_t *reversed_op = NULL;
    const char new_path[] = "v3_name";
    const char old_path[] = "v1_name";

    /* Natural acquisition: stored=older, working=newer. */
    CHECK(pe_map_acquire(XML_GAP_OLDER_70_10_5, STR_LEN(XML_GAP_OLDER_70_10_5), "70.10.5",
                          STR_LEN("70.10.5"), XML_GAP_NEWER_70_13_0,
                          STR_LEN(XML_GAP_NEWER_70_13_0), "70.13.0", STR_LEN("70.13.0"),
                          &natural) == PE_STATUS_OK,
          "acquiring the multi-release gap pair should succeed");
    CHECK(pe_operation_begin(natural, &natural_op) == PE_STATUS_OK, "begin should succeed");

    CHECK(projected_path_matches(natural, natural_op, PE_DIRECTION_WORKING_TO_STORED,
                                  new_path, sizeof(new_path) - 1, old_path),
          "the gap-spanning history should skip the stale 70.10.0 entry and resolve to "
          "the 70.11.0 entry's previous name");
    CHECK(projected_path_matches(natural, natural_op, PE_DIRECTION_STORED_TO_WORKING,
                                  old_path, sizeof(old_path) - 1, new_path),
          "the reciprocal bare-predecessor-name query should resolve back to the "
          "tagged field's current path");

    /* Reversed acquisition: stored=newer, working=older. The resolution
     * must not depend on which endpoint was acquired as stored/working. */
    CHECK(pe_map_acquire(XML_GAP_NEWER_70_13_0, STR_LEN(XML_GAP_NEWER_70_13_0), "70.13.0",
                          STR_LEN("70.13.0"), XML_GAP_OLDER_70_10_5,
                          STR_LEN(XML_GAP_OLDER_70_10_5), "70.10.5", STR_LEN("70.10.5"),
                          &reversed) == PE_STATUS_OK,
          "acquiring the gap pair with roles reversed should succeed");
    CHECK(pe_operation_begin(reversed, &reversed_op) == PE_STATUS_OK, "begin should succeed");

    CHECK(projected_path_matches(reversed, reversed_op, PE_DIRECTION_STORED_TO_WORKING,
                                  new_path, sizeof(new_path) - 1, old_path),
          "the same gap-spanning resolution should hold with roles reversed");
    CHECK(projected_path_matches(reversed, reversed_op, PE_DIRECTION_WORKING_TO_STORED,
                                  old_path, sizeof(old_path) - 1, new_path),
          "the reciprocal resolution should hold with roles reversed too");

    pe_operation_release(natural_op);
    pe_map_release(natural);
    pe_operation_release(reversed_op);
    pe_map_release(reversed);

    printf("project_node_query: a successive rename history spanning several releases "
           "resolved end to end, independent of caller endpoint ordering\n");
    return 0;
}

/*
 * Issue #24 parity vector (issue #13/#18's aligned-history and
 * ordering-validation portability rules): a leaf_renamed field whose
 * change_nbc_version/change_nbc_previous_name history is malformed fails
 * deterministically with PE_STATUS_RENAME_HISTORY_MALFORMED instead of
 * producing a fabricated mapping. Each sub-case uses its own dedicated,
 * otherwise-unused minor version, all sharing major version 40 with the
 * target so every acquisition stays same-major (a cross-major pair would
 * be rejected by pe_map_acquire before the malformed history is ever
 * consulted, which is not what this vector means to exercise). */
#define XML_MALFORMED_HISTORY_SHAPE_MISMATCH                                 \
    "<IDSs><version>40.2.0</version>"                                       \
    "<field name=\"n\" path=\"new_name\" data_type=\"STR_0D\" "               \
    "change_nbc_version=\"1.0.0,2.0.0\" change_nbc_description=\"leaf_renamed\" " \
    "change_nbc_previous_name=\"only_one\"/></IDSs>"
#define XML_MALFORMED_HISTORY_NON_ASCENDING                                  \
    "<IDSs><version>40.3.0</version>"                                       \
    "<field name=\"n\" path=\"new_name\" data_type=\"STR_0D\" "               \
    "change_nbc_version=\"2.0.0,1.0.0\" change_nbc_description=\"leaf_renamed\" " \
    "change_nbc_previous_name=\"ancient_name,middle_name\"/></IDSs>"
#define XML_MALFORMED_HISTORY_UNPARSEABLE_VERSION                            \
    "<IDSs><version>40.4.0</version>"                                       \
    "<field name=\"n\" path=\"new_name\" data_type=\"STR_0D\" "               \
    "change_nbc_version=\"not-a-version\" change_nbc_description=\"leaf_renamed\" " \
    "change_nbc_previous_name=\"old_name\"/></IDSs>"
#define XML_MALFORMED_HISTORY_TARGET                                         \
    "<IDSs><version>40.1.0</version>"                                       \
    "<field name=\"n\" path=\"old_name\" data_type=\"STR_0D\"/></IDSs>"

static int test_projection_malformed_rename_history_is_rejected_deterministically(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict = PE_VERDICT_SAME;
    const char path[] = "new_name";

    /* Shape mismatch: two versions, one previous name. */
    CHECK(pe_map_acquire(XML_MALFORMED_HISTORY_TARGET, STR_LEN(XML_MALFORMED_HISTORY_TARGET),
                          "40.1.0", STR_LEN("40.1.0"), XML_MALFORMED_HISTORY_SHAPE_MISMATCH,
                          STR_LEN(XML_MALFORMED_HISTORY_SHAPE_MISMATCH), "40.2.0",
                          STR_LEN("40.2.0"), &map) == PE_STATUS_OK,
          "acquiring the shape-mismatch pair should succeed (the malformed history "
          "is only checked when the field is actually queried)");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");
    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1,
                &verdict) == PE_STATUS_RENAME_HISTORY_MALFORMED,
          "unequal change_nbc_version/change_nbc_previous_name entry counts should be "
          "rejected deterministically");
    CHECK(verdict == PE_VERDICT_SAME,
          "a PE_STATUS_RENAME_HISTORY_MALFORMED result must leave out_verdict unwritten");
    pe_operation_release(operation);
    pe_map_release(map);

    /* Non-ascending version order. */
    map = NULL;
    operation = NULL;
    verdict = PE_VERDICT_SAME;
    CHECK(pe_map_acquire(XML_MALFORMED_HISTORY_TARGET, STR_LEN(XML_MALFORMED_HISTORY_TARGET),
                          "40.1.0", STR_LEN("40.1.0"), XML_MALFORMED_HISTORY_NON_ASCENDING,
                          STR_LEN(XML_MALFORMED_HISTORY_NON_ASCENDING), "40.3.0",
                          STR_LEN("40.3.0"), &map) == PE_STATUS_OK,
          "acquiring the non-ascending pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");
    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1,
                &verdict) == PE_STATUS_RENAME_HISTORY_MALFORMED,
          "out-of-order change_nbc_version entries should be rejected deterministically");
    pe_operation_release(operation);
    pe_map_release(map);

    /* Unparseable version text. */
    map = NULL;
    operation = NULL;
    verdict = PE_VERDICT_SAME;
    CHECK(pe_map_acquire(XML_MALFORMED_HISTORY_TARGET, STR_LEN(XML_MALFORMED_HISTORY_TARGET),
                          "40.1.0", STR_LEN("40.1.0"), XML_MALFORMED_HISTORY_UNPARSEABLE_VERSION,
                          STR_LEN(XML_MALFORMED_HISTORY_UNPARSEABLE_VERSION), "40.4.0",
                          STR_LEN("40.4.0"), &map) == PE_STATUS_OK,
          "acquiring the unparseable-version pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");
    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, path, sizeof(path) - 1,
                &verdict) == PE_STATUS_RENAME_HISTORY_MALFORMED,
          "an unparseable change_nbc_version entry should be rejected deterministically");
    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: malformed rename histories (shape mismatch, "
           "non-ascending order, unparseable version) were all rejected "
           "deterministically rather than producing a fabricated mapping\n");
    return 0;
}

/*
 * Issue #24 parity vector: two leaf_renamed fields selecting the same
 * predecessor make the reverse lookup ambiguous. The engine must reject the
 * query rather than choose whichever metadata entry it happened to visit
 * first and fabricate a projected path.
 */
#define XML_AMBIGUOUS_HISTORY_OLD                                             \
    "<IDSs><version>80.1.0</version>"                                       \
    "<field name=\"n\" path=\"shared_old\" data_type=\"STR_0D\"/></IDSs>"
#define XML_AMBIGUOUS_HISTORY_NEW                                             \
    "<IDSs><version>80.2.0</version>"                                       \
    "<field name=\"n\" path=\"first_new\" data_type=\"STR_0D\" "        \
    "change_nbc_version=\"80.2.0\" change_nbc_description=\"leaf_renamed\" " \
    "change_nbc_previous_name=\"shared_old\"/>"                            \
    "<field name=\"n\" path=\"second_new\" data_type=\"STR_0D\" "       \
    "change_nbc_version=\"80.2.0\" change_nbc_description=\"leaf_renamed\" " \
    "change_nbc_previous_name=\"shared_old\"/></IDSs>"

static int test_projection_ambiguous_leaf_predecessor_is_rejected(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict = PE_VERDICT_SAME;
    const char path[] = "shared_old";

    CHECK(pe_map_acquire(XML_AMBIGUOUS_HISTORY_OLD, STR_LEN(XML_AMBIGUOUS_HISTORY_OLD),
                          "80.1.0", STR_LEN("80.1.0"), XML_AMBIGUOUS_HISTORY_NEW,
                          STR_LEN(XML_AMBIGUOUS_HISTORY_NEW), "80.2.0",
                          STR_LEN("80.2.0"), &map) == PE_STATUS_OK,
          "acquiring the ambiguous-predecessor pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");
    CHECK(query(map, operation, PE_DIRECTION_STORED_TO_WORKING, path, sizeof(path) - 1,
                &verdict) == PE_STATUS_RENAME_HISTORY_MALFORMED,
          "two leaf histories resolving to one predecessor must be rejected, not mapped");
    CHECK(verdict == PE_VERDICT_SAME,
          "an ambiguous predecessor result must leave out_verdict unwritten");
    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: ambiguous leaf predecessor was rejected deterministically\n");
    return 0;
}

/*
 * Issue #24 parity vector (issue #18's "every datatype change is an
 * automatic-seam skip" rule, extended to the resolved-rename case): a
 * leaf_renamed field whose two sides also differ in data_type reports the
 * skip, not a fabricated rename -- proving no semantic type-conversion
 * callback executes even though the field was also renamed.
 */
#define XML_RENAMED_AND_RETYPED_OLD                                          \
    "<IDSs><version>50.1.0</version>"                                       \
    "<field name=\"n\" path=\"old_retyped\" data_type=\"INT_0D\"/></IDSs>"
#define XML_RENAMED_AND_RETYPED_NEW                                          \
    "<IDSs><version>50.2.0</version>"                                       \
    "<field name=\"n\" path=\"new_retyped\" data_type=\"FLT_0D\" "            \
    "change_nbc_version=\"50.2.0\" change_nbc_description=\"leaf_renamed\" "  \
    "change_nbc_previous_name=\"old_retyped\"/></IDSs>"

static int test_projection_datatype_change_after_rename_still_reports_skip(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;
    pe_verdict_t verdict;
    const char new_path[] = "new_retyped";
    const char old_path[] = "old_retyped";

    CHECK(pe_map_acquire(XML_RENAMED_AND_RETYPED_OLD, STR_LEN(XML_RENAMED_AND_RETYPED_OLD),
                          "50.1.0", STR_LEN("50.1.0"), XML_RENAMED_AND_RETYPED_NEW,
                          STR_LEN(XML_RENAMED_AND_RETYPED_NEW), "50.2.0", STR_LEN("50.2.0"),
                          &map) == PE_STATUS_OK,
          "acquiring the renamed-and-retyped pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    CHECK(query(map, operation, PE_DIRECTION_WORKING_TO_STORED, new_path,
                sizeof(new_path) - 1, &verdict) == PE_STATUS_OK && verdict == PE_VERDICT_SKIP,
          "a resolved rename whose data_type also changed should report PE_VERDICT_SKIP, "
          "not PE_VERDICT_RENAME");
    CHECK(query(map, operation, PE_DIRECTION_STORED_TO_WORKING, old_path,
                sizeof(old_path) - 1, &verdict) == PE_STATUS_OK && verdict == PE_VERDICT_SKIP,
          "the reciprocal bare-predecessor-name query should report the same skip");

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: a datatype change coinciding with a resolved rename "
           "still reported PE_VERDICT_SKIP, proving no conversion callback executed\n");
    return 0;
}

/*
 * Issue #24: leaf_renamed resolution verified through the C ABI against a
 * dedicated ad-hoc pair (feature-1-shaped, but independent of the shared
 * fixture so this vector's own acquisition endpoints can be chosen freely).
 * Both directions, and both caller endpoint orderings, must agree.
 */
#define XML_LEAF_OLD "<IDSs><version>60.1.0</version>" \
    "<field name=\"n\" path=\"old_leaf\" data_type=\"STR_0D\"/></IDSs>"
#define XML_LEAF_NEW                                                         \
    "<IDSs><version>60.2.0</version>"                                       \
    "<field name=\"n\" path=\"new_leaf\" data_type=\"STR_0D\" "               \
    "change_nbc_version=\"60.2.0\" change_nbc_description=\"leaf_renamed\" "  \
    "change_nbc_previous_name=\"old_leaf\"/></IDSs>"

static int test_projection_single_leaf_rename_resolves_in_both_directions(void) {
    pe_map_t *natural = NULL;
    pe_map_t *reversed = NULL;
    pe_operation_t *natural_op = NULL;
    pe_operation_t *reversed_op = NULL;
    const char new_path[] = "new_leaf";
    const char old_path[] = "old_leaf";

    CHECK(pe_map_acquire(XML_LEAF_OLD, STR_LEN(XML_LEAF_OLD), "60.1.0", STR_LEN("60.1.0"),
                          XML_LEAF_NEW, STR_LEN(XML_LEAF_NEW), "60.2.0", STR_LEN("60.2.0"),
                          &natural) == PE_STATUS_OK,
          "acquiring the single-leaf-rename pair should succeed");
    CHECK(pe_operation_begin(natural, &natural_op) == PE_STATUS_OK, "begin should succeed");

    CHECK(projected_path_matches(natural, natural_op, PE_DIRECTION_WORKING_TO_STORED,
                                  new_path, sizeof(new_path) - 1, old_path),
          "querying the tagged (post-rename) path should resolve to the previous name");
    CHECK(projected_path_matches(natural, natural_op, PE_DIRECTION_STORED_TO_WORKING,
                                  old_path, sizeof(old_path) - 1, new_path),
          "querying the bare predecessor path should resolve to the tagged field's "
          "current path");

    CHECK(pe_map_acquire(XML_LEAF_NEW, STR_LEN(XML_LEAF_NEW), "60.2.0", STR_LEN("60.2.0"),
                          XML_LEAF_OLD, STR_LEN(XML_LEAF_OLD), "60.1.0", STR_LEN("60.1.0"),
                          &reversed) == PE_STATUS_OK,
          "acquiring the same pair with roles reversed should succeed");
    CHECK(pe_operation_begin(reversed, &reversed_op) == PE_STATUS_OK, "begin should succeed");

    CHECK(projected_path_matches(reversed, reversed_op, PE_DIRECTION_STORED_TO_WORKING,
                                  new_path, sizeof(new_path) - 1, old_path),
          "resolution should be unaffected by which endpoint was acquired as stored "
          "vs. working");
    CHECK(projected_path_matches(reversed, reversed_op, PE_DIRECTION_WORKING_TO_STORED,
                                  old_path, sizeof(old_path) - 1, new_path),
          "the reciprocal resolution should hold with roles reversed too");

    pe_operation_release(natural_op);
    pe_map_release(natural);
    pe_operation_release(reversed_op);
    pe_map_release(reversed);

    printf("project_node_query: a single leaf_renamed field resolved correctly in both "
           "directions, independent of caller endpoint ordering\n");
    return 0;
}

/*
 * Issue #24: verifies, through the ABI, that the real shared nine-feature
 * fixture's own feature 1 (leaf rename: old_leaf_name/new_leaf_name) and
 * feature 4 (successive history: middle_name/thrice_renamed) now resolve
 * to PE_VERDICT_RENAME with the projected path called for by #18's cutoff
 * rule -- the same shared corpus test_projection_shared_fixture_rename_bearing_fields_report_rename_pending
 * used to cover these two paths before this ticket activated them (see
 * that fixture's own doc comment for the feature -> field mapping and the
 * durability rule governing #23's still-frozen four vectors).
 */
static int test_projection_shared_fixture_leaf_and_successive_rename_features_resolve(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;

    CHECK(pe_map_acquire(XML_FIXTURE_OLD_20_1_0, STR_LEN(XML_FIXTURE_OLD_20_1_0), "20.1.0",
                          STR_LEN("20.1.0"), XML_FIXTURE_NEW_20_2_0,
                          STR_LEN(XML_FIXTURE_NEW_20_2_0), "20.2.0", STR_LEN("20.2.0"),
                          &map) == PE_STATUS_OK,
          "acquiring the shared fixture pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    /* Feature 1: leaf rename. */
    CHECK(projected_path_matches(map, operation, PE_DIRECTION_WORKING_TO_STORED,
                                  "new_leaf_name", STR_LEN("new_leaf_name"), "old_leaf_name"),
          "feature 1 (leaf rename) should resolve to its OLD-side previous name");
    CHECK(projected_path_matches(map, operation, PE_DIRECTION_STORED_TO_WORKING,
                                  "old_leaf_name", STR_LEN("old_leaf_name"), "new_leaf_name"),
          "feature 1 should resolve reciprocally from its OLD-side bare name");

    /* Feature 4: successive rename history. The shared fixture's older
     * endpoint (20.1.0) is the first version greater than 19.5.0 but not
     * greater than 20.2.0, so the cutoff selects the "middle_name" entry --
     * exactly the OLD side's own literal field name. */
    CHECK(projected_path_matches(map, operation, PE_DIRECTION_WORKING_TO_STORED,
                                  "thrice_renamed", STR_LEN("thrice_renamed"), "middle_name"),
          "feature 4 (successive history) should select the cutoff-appropriate "
          "previous name, not the stale \"ancient_name\" entry");
    CHECK(projected_path_matches(map, operation, PE_DIRECTION_STORED_TO_WORKING,
                                  "middle_name", STR_LEN("middle_name"), "thrice_renamed"),
          "feature 4 should resolve reciprocally from its OLD-side bare name");

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: the shared fixture's leaf-rename and successive-history "
           "features resolved to PE_VERDICT_RENAME with the expected projected path\n");
    return 0;
}

/*
 * Issue #24: verifies, through the ABI, that the real shared fixture's
 * feature 8 (renamed time-dependent node: dynamic_group/legacy_signal ->
 * dynamic_group/signal, a bare previous name expanded against the renamed
 * field's own unchanged parent) and feature 9 (missing parent with a
 * reachable renamed descendant: orphan_container/direct_signal ->
 * rescued_signal, a full-path previous name) now resolve to
 * PE_VERDICT_RENAME. Both are mechanically leaf_renamed fields; feature 9's
 * "missing parent" framing describes why the fixture has no literal
 * "orphan_container" field, not a different resolution mechanism.
 */
static int test_projection_shared_fixture_time_dependent_and_missing_parent_renames_resolve(void) {
    pe_map_t *map = NULL;
    pe_operation_t *operation = NULL;

    CHECK(pe_map_acquire(XML_FIXTURE_OLD_20_1_0, STR_LEN(XML_FIXTURE_OLD_20_1_0), "20.1.0",
                          STR_LEN("20.1.0"), XML_FIXTURE_NEW_20_2_0,
                          STR_LEN(XML_FIXTURE_NEW_20_2_0), "20.2.0", STR_LEN("20.2.0"),
                          &map) == PE_STATUS_OK,
          "acquiring the shared fixture pair should succeed");
    CHECK(pe_operation_begin(map, &operation) == PE_STATUS_OK, "begin should succeed");

    /* Feature 8: bare previous name expanded against the unchanged parent
     * "dynamic_group". */
    CHECK(projected_path_matches(map, operation, PE_DIRECTION_WORKING_TO_STORED,
                                  "dynamic_group/signal", STR_LEN("dynamic_group/signal"),
                                  "dynamic_group/legacy_signal"),
          "feature 8 (renamed time-dependent node) should resolve to its full OLD-side "
          "path via the unchanged parent");
    CHECK(projected_path_matches(map, operation, PE_DIRECTION_STORED_TO_WORKING,
                                  "dynamic_group/legacy_signal",
                                  STR_LEN("dynamic_group/legacy_signal"), "dynamic_group/signal"),
          "feature 8 should resolve reciprocally from its OLD-side path");

    /* Feature 9: full-path previous name, used verbatim. */
    CHECK(projected_path_matches(map, operation, PE_DIRECTION_WORKING_TO_STORED,
                                  "rescued_signal", STR_LEN("rescued_signal"),
                                  "orphan_container/direct_signal"),
          "feature 9 (missing parent, reachable descendant) should resolve to its "
          "full OLD-side path even though no \"orphan_container\" field itself exists");
    CHECK(projected_path_matches(map, operation, PE_DIRECTION_STORED_TO_WORKING,
                                  "orphan_container/direct_signal",
                                  STR_LEN("orphan_container/direct_signal"), "rescued_signal"),
          "feature 9 should resolve reciprocally from its OLD-side path");

    pe_operation_release(operation);
    pe_map_release(map);

    printf("project_node_query: the shared fixture's time-dependent-node and "
           "missing-parent rename features resolved to PE_VERDICT_RENAME with the "
           "expected projected path\n");
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
    failures += test_map_cache_eviction_evicts_the_least_recently_used_pair();
    failures += test_map_cache_touching_a_pair_under_pressure_prevents_its_eviction();
    failures += test_projection_unchanged_field_reports_same_in_both_directions();
    failures += test_projection_added_and_removed_fields_report_skip_in_both_directions();
    failures += test_projection_datatype_changed_field_reports_skip_in_both_directions();
    failures += test_projection_unknown_path_is_rejected();
    failures += test_projection_rename_tagged_node_reports_rename_pending();
    failures += test_projection_shared_fixture_rename_bearing_fields_report_rename_pending();
    failures += test_projection_successive_rename_history_resolves_across_a_multi_release_gap();
    failures += test_projection_malformed_rename_history_is_rejected_deterministically();
    failures += test_projection_ambiguous_leaf_predecessor_is_rejected();
    failures += test_projection_datatype_change_after_rename_still_reports_skip();
    failures += test_projection_single_leaf_rename_resolves_in_both_directions();
    failures += test_projection_shared_fixture_leaf_and_successive_rename_features_resolve();
    failures += test_projection_shared_fixture_time_dependent_and_missing_parent_renames_resolve();

    if (failures == 0) {
        printf("contract test: all checks passed\n");
    }
    return failures;
}
