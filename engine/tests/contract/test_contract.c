/*
 * C contract test for the projection-engine ABI (IMAS-Fortran #20).
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

int main(void) {
    int failures = 0;

    failures += test_operation_lifecycle_and_input_validation();
    failures += test_projection_entry_instrumentation();
    failures += test_status_message_string_ownership_convention();

    if (failures == 0) {
        printf("contract test: all checks passed\n");
    }
    return failures;
}
