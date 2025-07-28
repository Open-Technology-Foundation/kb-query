#!/bin/bash
# Run all kb-query tests

set -euo pipefail

# Get the directory of this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
readonly GREEN=$'\033[0;32m'
readonly RED=$'\033[0;31m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly NOCOLOR=$'\033[0m'

# Test categories
declare -a TEST_SUITES=(
    "test_basic_commands.sh"
    "test_configuration.sh"
    "test_security.sh"
    "test_output_formats.sh"
    "test_caching.sh"
    "test_history.sh"
    "test_error_handling.sh"
    "test_integration.sh"
)

# Counters
declare -i TOTAL_SUITES=0
declare -i PASSED_SUITES=0
declare -i FAILED_SUITES=0

# Parse command line arguments
VERBOSE=0
RUN_INTEGRATION=1
SPECIFIC_SUITE=""

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Run all kb-query test suites.

Options:
    -h, --help          Show this help message
    -v, --verbose       Show detailed test output
    -q, --quick         Skip integration tests (no internet required)
    -s, --suite SUITE   Run only a specific test suite

Examples:
    $0                  Run all tests
    $0 --quick          Run all tests except integration
    $0 --suite security Run only security tests
    $0 -v              Run all tests with verbose output

Available test suites:
EOF
    for suite in "${TEST_SUITES[@]}"; do
        echo "    ${suite%.sh}"
    done
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -q|--quick)
            RUN_INTEGRATION=0
            shift
            ;;
        -s|--suite)
            SPECIFIC_SUITE="test_$2.sh"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Header
echo
echo "${BLUE}KB-Query Test Suite Runner${NOCOLOR}"
echo "=========================="
echo
echo "Test directory: $TEST_DIR"
echo "Running tests: $([ "$SPECIFIC_SUITE" ] && echo "$SPECIFIC_SUITE" || echo "all")"
echo "Integration tests: $([ $RUN_INTEGRATION -eq 1 ] && echo "enabled" || echo "disabled")"
echo "Verbose mode: $([ $VERBOSE -eq 1 ] && echo "on" || echo "off")"
echo

# Check if kb-query exists
if [[ ! -f "$TEST_DIR/../kb-query" ]]; then
    echo "${RED}Error: kb-query not found at $TEST_DIR/../kb-query${NOCOLOR}"
    exit 1
fi

# Make test scripts executable
chmod +x "$TEST_DIR"/*.sh

# Function to run a test suite
run_suite() {
    local suite="$1"
    local suite_name="${suite%.sh}"
    
    echo
    echo "${BLUE}Running $suite_name tests...${NOCOLOR}"
    echo "----------------------------------------"
    
    ((TOTAL_SUITES++))
    
    if [[ $VERBOSE -eq 1 ]]; then
        if bash "$TEST_DIR/$suite"; then
            echo "${GREEN}✓ $suite_name passed${NOCOLOR}"
            ((PASSED_SUITES++))
        else
            echo "${RED}✗ $suite_name failed${NOCOLOR}"
            ((FAILED_SUITES++))
        fi
    else
        # Capture output for summary
        local output_file=$(mktemp)
        if bash "$TEST_DIR/$suite" >"$output_file" 2>&1; then
            echo "${GREEN}✓ $suite_name passed${NOCOLOR}"
            ((PASSED_SUITES++))
            # Show summary line from output
            grep -E "(Total tests:|All tests passed)" "$output_file" | tail -1 || true
        else
            echo "${RED}✗ $suite_name failed${NOCOLOR}"
            ((FAILED_SUITES++))
            # Show error summary
            echo "  Error output:"
            grep -E "(Failed:|FAIL|Error)" "$output_file" | head -5 || true
            echo "  Run with -v for full output"
        fi
        rm -f "$output_file"
    fi
}

# Run tests
if [[ -n "$SPECIFIC_SUITE" ]]; then
    # Run specific suite
    if [[ -f "$TEST_DIR/$SPECIFIC_SUITE" ]]; then
        run_suite "$SPECIFIC_SUITE"
    else
        echo "${RED}Error: Test suite $SPECIFIC_SUITE not found${NOCOLOR}"
        exit 1
    fi
else
    # Run all suites
    for suite in "${TEST_SUITES[@]}"; do
        # Skip integration tests if requested
        if [[ "$suite" == "test_integration.sh" ]] && [[ $RUN_INTEGRATION -eq 0 ]]; then
            echo
            echo "${YELLOW}Skipping integration tests (use without --quick to run)${NOCOLOR}"
            continue
        fi
        
        run_suite "$suite"
    done
fi

# Summary
echo
echo
echo "Test Suite Summary"
echo "=================="
echo "Total suites run: $TOTAL_SUITES"
echo "${GREEN}Passed: $PASSED_SUITES${NOCOLOR}"
if [[ $FAILED_SUITES -gt 0 ]]; then
    echo "${RED}Failed: $FAILED_SUITES${NOCOLOR}"
else
    echo "Failed: 0"
fi

echo
if [[ $FAILED_SUITES -eq 0 ]]; then
    echo "${GREEN}All test suites passed!${NOCOLOR}"
    exit 0
else
    echo "${RED}Some test suites failed!${NOCOLOR}"
    exit 1
fi