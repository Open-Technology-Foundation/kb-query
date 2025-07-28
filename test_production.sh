#!/bin/bash
# Test kb-query on production after deployment
# Run this after deploying to okusi3

set -euo pipefail

# Colors
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly NOCOLOR=$'\033[0m'

# Test counters
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0

# Configuration
readonly API_BASE="https://yatti.id/v1/index.php"
readonly TEST_KB="appliedanthropology"
readonly TEST_QUERY="What is dharma?"

# Test function
run_test() {
  local test_name="$1"
  local test_cmd="$2"
  local expected_pattern="$3"
  
  ((TESTS_RUN++))
  echo -n "Testing $test_name... "
  
  if eval "$test_cmd" 2>&1 | grep -q "$expected_pattern"; then
    echo "${GREEN}PASS${NOCOLOR}"
    ((TESTS_PASSED++))
  else
    echo "${RED}FAIL${NOCOLOR}"
    ((TESTS_FAILED++))
    echo "  Command: $test_cmd"
    echo "  Expected to find: $expected_pattern"
    echo "  Actual output:"
    eval "$test_cmd" 2>&1 | head -5 | sed 's/^/    /'
  fi
}

echo "${BLUE}=== KB-Query Production Tests ===${NOCOLOR}"
echo "API Base: $API_BASE"
echo "Date: $(date)"
echo

# Section 1: Public Endpoints (No Auth Required)
echo "${YELLOW}1. Testing Public Endpoints${NOCOLOR}"
echo "----------------------------"

run_test "Help endpoint" \
  "curl -s '$API_BASE/help'" \
  "YaTTI Custom Knowledgebase"

run_test "Help shows v1/index.php URLs" \
  "curl -s '$API_BASE/help'" \
  "v1/index.php"

run_test "List endpoint" \
  "curl -s '$API_BASE/list' | jq -r '.[]' 2>/dev/null | head -1" \
  "appliedanthropology"

run_test "List returns JSON array" \
  "curl -s '$API_BASE/list' | jq type" \
  "array"

# Section 2: Authentication Tests
echo
echo "${YELLOW}2. Testing Authentication${NOCOLOR}"
echo "-------------------------"

run_test "Query without API key fails" \
  "curl -s '$API_BASE/$TEST_KB?q=test' | jq -r '.error'" \
  "No API key provided"

run_test "Invalid API key fails" \
  "curl -s -H 'Authorization: Bearer invalid_key' '$API_BASE/$TEST_KB?q=test' | jq -r '.error'" \
  "Invalid API key"

# Section 3: KB-Query CLI Tests
echo
echo "${YELLOW}3. Testing KB-Query CLI${NOCOLOR}"
echo "-----------------------"

# Test if kb-query is installed
if command -v kb-query &> /dev/null; then
  run_test "kb-query installed" \
    "kb-query --version" \
    "0.9.14"
  
  run_test "kb-query help command" \
    "kb-query help" \
    "YaTTI Custom Knowledgebase"
  
  run_test "kb-query list command" \
    "kb-query list" \
    "appliedanthropology"
  
  # Test with API key if available
  if [[ -n "${YATTI_API_KEY:-}" ]]; then
    echo
    echo "${YELLOW}4. Testing with API Key${NOCOLOR}"
    echo "-----------------------"
    
    run_test "Query with valid API key" \
      "kb-query $TEST_KB '$TEST_QUERY' | head -1" \
      "."
    
    run_test "Context-only query" \
      "kb-query -c $TEST_KB 'dharma' | grep -c 'dharma'" \
      "[0-9]"
    
    run_test "JSON output format" \
      "kb-query --format json $TEST_KB '$TEST_QUERY' | jq -r '.response' | head -1" \
      "."
    
    # Test all knowledgebases
    echo
    echo "${YELLOW}5. Testing All Knowledgebases${NOCOLOR}"
    echo "-----------------------------"
    
    for kb in appliedanthropology garydean jakartapost okusiassociates; do
      run_test "Query $kb" \
        "kb-query $kb 'test' .response | wc -c" \
        "[0-9]"
    done
  else
    echo
    echo "${YELLOW}Skipping authenticated tests (no API key set)${NOCOLOR}"
    echo "To run full tests, set: export YATTI_API_KEY='your_key_here'"
  fi
else
  echo "${RED}kb-query not found in PATH${NOCOLOR}"
fi

# Section 4: URL Structure Verification
echo
echo "${YELLOW}6. Verifying URL Structure${NOCOLOR}"
echo "--------------------------"

run_test "No double index.php in URLs" \
  "curl -s '$API_BASE/help' | grep -c 'index.php/index.php'" \
  "^0$"

run_test "Help text uses v1/index.php" \
  "kb-query help 2>/dev/null | grep -o 'https://yatti.id/v1/index.php' | head -1" \
  "https://yatti.id/v1/index.php"

# Section 5: Performance Tests
echo
echo "${YELLOW}7. Performance Tests${NOCOLOR}"
echo "--------------------"

# Time the help endpoint
start_time=$(date +%s.%N)
curl -s "$API_BASE/help" > /dev/null
end_time=$(date +%s.%N)
response_time=$(echo "$end_time - $start_time" | bc)
echo "Help endpoint response time: ${response_time}s"

if (( $(echo "$response_time < 2" | bc -l) )); then
  echo "${GREEN}✓ Response time acceptable${NOCOLOR}"
  ((TESTS_PASSED++))
else
  echo "${RED}✗ Response time too slow${NOCOLOR}"
  ((TESTS_FAILED++))
fi
((TESTS_RUN++))

# Summary
echo
echo "${BLUE}=== Test Summary ===${NOCOLOR}"
echo "Total tests: $TESTS_RUN"
echo "Passed: ${GREEN}$TESTS_PASSED${NOCOLOR}"
echo "Failed: ${RED}$TESTS_FAILED${NOCOLOR}"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo
  echo "${GREEN}All tests passed! ✓${NOCOLOR}"
  exit 0
else
  echo
  echo "${RED}Some tests failed. Please check the output above.${NOCOLOR}"
  exit 1
fi

#fin