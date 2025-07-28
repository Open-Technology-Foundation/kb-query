#!/bin/bash
# Test framework for kb-query
# Provides common testing utilities and assertions

set -euo pipefail

# Colors for output
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly NOCOLOR=$'\033[0m'

# Test counters
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0
declare -i TESTS_SKIPPED=0

# Test configuration
declare -g TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -g PROJECT_DIR="$(dirname "$TEST_DIR")"
declare -g KB_QUERY="$PROJECT_DIR/kb-query"
declare -g TEST_TEMP_DIR=""
declare -g TEST_NAME=""
declare -g TEST_OUTPUT=""
declare -g TEST_ERROR=""
declare -g TEST_EXIT_CODE=0

# Setup test environment
setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d /tmp/kb-query-test.XXXXXX)
    export HOME="$TEST_TEMP_DIR"
    export XDG_CONFIG_HOME="$TEST_TEMP_DIR/.config"
    export XDG_CACHE_HOME="$TEST_TEMP_DIR/.cache"
    export XDG_DATA_HOME="$TEST_TEMP_DIR/.local/share"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
}

# Cleanup test environment
cleanup_test_env() {
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Run a test
run_test() {
    local test_name="$1"
    TEST_NAME="$test_name"
    ((TESTS_RUN++))
    
    echo -n "  $test_name ... "
    
    # Setup clean environment for each test
    setup_test_env
    
    # Run the test function
    if $test_name >/dev/null 2>&1; then
        echo "${GREEN}PASS${NOCOLOR}"
        ((TESTS_PASSED++))
    else
        echo "${RED}FAIL${NOCOLOR}"
        ((TESTS_FAILED++))
        if [[ -n "${TEST_OUTPUT:-}" ]]; then
            echo "    Output: $TEST_OUTPUT"
        fi
        if [[ -n "${TEST_ERROR:-}" ]]; then
            echo "    Error: $TEST_ERROR"
        fi
        if [[ "${TEST_EXIT_CODE:-0}" -ne 0 ]]; then
            echo "    Exit code: $TEST_EXIT_CODE"
        fi
    fi
    
    # Cleanup after test
    cleanup_test_env
    TEST_OUTPUT=""
    TEST_ERROR=""
    TEST_EXIT_CODE=0
}

# Skip a test
skip_test() {
    local test_name="$1"
    local reason="${2:-No reason given}"
    
    echo "  $test_name ... ${YELLOW}SKIP${NOCOLOR} ($reason)"
    ((TESTS_SKIPPED++))
}

# Execute kb-query and capture output
kb_query() {
    local output_file="$TEST_TEMP_DIR/output"
    local error_file="$TEST_TEMP_DIR/error"
    
    set +e
    "$KB_QUERY" "$@" >"$output_file" 2>"$error_file"
    TEST_EXIT_CODE=$?
    set -e
    
    TEST_OUTPUT="$(cat "$output_file")"
    TEST_ERROR="$(cat "$error_file")"
    
    return $TEST_EXIT_CODE
}

# Assertions
assert_exit_code() {
    local expected=$1
    local actual=${TEST_EXIT_CODE:-0}
    
    if [[ $actual -ne $expected ]]; then
        echo "Expected exit code $expected, got $actual"
        return 1
    fi
}

assert_output_contains() {
    local expected="$1"
    
    if [[ ! "$TEST_OUTPUT" =~ $expected ]]; then
        echo "Output does not contain '$expected'"
        echo "Actual output: $TEST_OUTPUT"
        return 1
    fi
}

assert_output_not_contains() {
    local unexpected="$1"
    
    if [[ "$TEST_OUTPUT" =~ $unexpected ]]; then
        echo "Output contains unexpected '$unexpected'"
        echo "Actual output: $TEST_OUTPUT"
        return 1
    fi
}

assert_error_contains() {
    local expected="$1"
    
    if [[ ! "$TEST_ERROR" =~ $expected ]]; then
        echo "Error output does not contain '$expected'"
        echo "Actual error: $TEST_ERROR"
        return 1
    fi
}

assert_error_not_contains() {
    local unexpected="$1"
    
    if [[ "$TEST_ERROR" =~ $unexpected ]]; then
        echo "Error contains unexpected '$unexpected'"
        echo "Actual error: $TEST_ERROR"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "File does not exist: $file"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        echo "File exists but should not: $file"
        return 1
    fi
}

assert_json_valid() {
    if ! jq -e . >/dev/null 2>&1 <<<"$TEST_OUTPUT"; then
        echo "Output is not valid JSON"
        echo "Actual output: $TEST_OUTPUT"
        return 1
    fi
}

assert_json_field() {
    local field="$1"
    local expected="$2"
    
    local actual=$(jq -r "$field" <<<"$TEST_OUTPUT" 2>/dev/null)
    
    if [[ "$actual" != "$expected" ]]; then
        echo "JSON field $field: expected '$expected', got '$actual'"
        return 1
    fi
}

# Mock API responses
setup_mock_api() {
    # Create a mock kb-query that returns predefined responses
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
# Mock kb-query for testing

case "$1" in
    list)
        echo '{"response":["test-kb","appliedanthropology","mock-kb"]}'
        ;;
    help)
        echo '{"response":"Mock help text"}'
        ;;
    test-kb)
        if [[ "$2" == "test query" ]]; then
            echo '{"kb":"test-kb","query":"test query","response":"Mock response","elapsed_seconds":0.5}'
        else
            echo '{"error":"Unknown query"}'
        fi
        ;;
    *)
        echo '{"error":"Knowledgebase ['$1'] not found"}'
        exit 1
        ;;
esac
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
}

# Test suite runner
run_test_suite() {
    local suite_name="$1"
    shift
    
    echo
    echo "${BLUE}Running $suite_name${NOCOLOR}"
    echo "========================================"
    
    local test
    for test in "$@"; do
        if [[ $(type -t "$test") == "function" ]]; then
            run_test "$test"
        else
            echo "${YELLOW}Warning: Test function '$test' not found${NOCOLOR}"
        fi
    done
}

# Print test summary
print_test_summary() {
    echo
    echo "Test Summary"
    echo "============"
    echo "Total tests: $TESTS_RUN"
    echo "${GREEN}Passed: $TESTS_PASSED${NOCOLOR}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "${RED}Failed: $TESTS_FAILED${NOCOLOR}"
    else
        echo "Failed: 0"
    fi
    
    if [[ $TESTS_SKIPPED -gt 0 ]]; then
        echo "${YELLOW}Skipped: $TESTS_SKIPPED${NOCOLOR}"
    fi
    
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}All tests passed!${NOCOLOR}"
        return 0
    else
        echo "${RED}Some tests failed!${NOCOLOR}"
        return 1
    fi
}

# Trap to ensure cleanup
trap cleanup_test_env EXIT