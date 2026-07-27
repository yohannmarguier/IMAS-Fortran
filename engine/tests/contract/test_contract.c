/*
 * C contract test for the projection-engine ABI (IMAS-Fortran #20, #21).
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

static int test_operation_lifecycle_and_input_validation(void) {
    pe_operation_t *operation = NULL;

    CHECK(pe_operation_begin(NULL) == PE_STATUS_INVALID_ARGUMENT,
          "begin(NULL) should be rejected");

    CHECK(pe_operation_begin(&operation) == PE_STATUS_OK, "begin should succeed");
    CHECK(operation != NULL, "begin should hand back a non-null handle");

    CHECK(pe_operation_end(NULL) == PE_STATUS_NULL_HANDLE,
          "end(NULL) should be rejected");
    CHECK(pe_operation_end(operation) == PE_STATUS_OK, "end should succeed");
    CHECK(pe_operation_end(operation) == PE_STATUS_INVALID_ARGUMENT,
          "ending the same handle twice should be rejected");

    printf("operation lifecycle: negative paths rejected as expected\n");
    return 0;
}

static int test_projection_entry_instrumentation(void) {
    pe_operation_t *operation = NULL;
    uint64_t count = 0;
    pe_verdict_t verdict;
    const char path[] = "ids/time";

    CHECK(pe_operation_begin(&operation) == PE_STATUS_OK, "begin should succeed");

    CHECK(pe_instrumentation_reset() == PE_STATUS_OK, "reset should succeed");
    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 0, "counter should be zero right after reset");

    CHECK(pe_project_node_query(operation, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_OK,
          "project_node_query should succeed on valid input");
    CHECK(verdict == PE_VERDICT_SAME,
          "this skeleton always reports the same verdict");

    CHECK(pe_project_node_query(operation, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_OK,
          "project_node_query should succeed on valid input");

    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 2, "counter should tick once per project_node_query call");

    /* Negative paths: rejected without incrementing the counter. */
    CHECK(pe_project_node_query(NULL, path, sizeof(path) - 1, &verdict) ==
              PE_STATUS_NULL_HANDLE,
          "project_node_query(NULL operation) should be rejected");
    CHECK(pe_project_node_query(operation, NULL, 1, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(NULL path) should be rejected");
    CHECK(pe_project_node_query(operation, path, 0, &verdict) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(zero-length path) should be rejected");
    CHECK(pe_project_node_query(operation, path, sizeof(path) - 1, NULL) ==
              PE_STATUS_INVALID_ARGUMENT,
          "project_node_query(NULL out_verdict) should be rejected");
    CHECK(pe_instrumentation_read(NULL) == PE_STATUS_INVALID_ARGUMENT,
          "instrumentation_read(NULL) should be rejected");

    CHECK(pe_instrumentation_read(&count) == PE_STATUS_OK, "read should succeed");
    CHECK(count == 2, "rejected calls must not tick the counter");

    CHECK(pe_operation_end(operation) == PE_STATUS_OK, "end should succeed");

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

/* Fixtures for pe_map_acquire (issue #21). Deliberately minimal -- field
 * content and the real path index are out of scope here (issue #23); only
 * the <version> element and well-formedness matter to this seam. */
#define XML_STORED_3_39_0 "<IDSs><version>3.39.0</version></IDSs>"
#define XML_WORKING_3_38_1 "<IDSs><version>3.38.1</version></IDSs>"
#define XML_CROSS_MAJOR_4_0_0 "<IDSs><version>4.0.0</version></IDSs>"
#define XML_MALFORMED "<IDSs><version>3.39.0</version>"
#define XML_NO_VERSION_ELEMENT "<IDSs><ids/></IDSs>"

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
    char stored_xml[64];
    char stored_claim[16];
    char working_xml[64];
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
    pe_map_t *map = (pe_map_t *)1; /* sentinel: must stay unwritten on rejection */

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
    CHECK((void *)map == (void *)1, "a rejected acquire must leave out_map unwritten");

    CHECK(pe_map_release((pe_map_t *)1) == PE_STATUS_INVALID_ARGUMENT,
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

int main(void) {
    int failures = 0;

    failures += test_operation_lifecycle_and_input_validation();
    failures += test_projection_entry_instrumentation();
    failures += test_status_message_string_ownership_convention();
    failures += test_map_acquire_valid_pair_and_lifecycle();
    failures += test_map_acquire_parses_uniformly_regardless_of_role_order();
    failures += test_map_acquire_negative_identity_paths();
    failures += test_map_acquire_cross_major_pair();
    failures += test_map_acquire_copies_inputs_rather_than_borrowing_them();
    failures += test_map_acquire_input_validation();
    failures += test_map_version_rejects_unrecognized_role();

    if (failures == 0) {
        printf("contract test: all checks passed\n");
    }
    return failures;
}
