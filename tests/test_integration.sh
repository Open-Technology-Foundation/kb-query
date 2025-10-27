#!/bin/bash
# Integration tests for kb-query

source "$(dirname "$0")/test_framework.sh"

# Check if we have internet connectivity
check_internet() {
    curl -s --connect-timeout 2 https://yatti.id >/dev/null 2>&1
}

# Test real API list command
test_real_api_list() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    kb_query --timeout 60 list
    assert_exit_code 0
    assert_output_contains "appliedanthropology"
    assert_json_valid
}

# Test real API help command
test_real_api_help() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    kb_query --timeout 60 help
    assert_exit_code 0
    assert_output_contains "CustomKB"
}

# Test real knowledgebase query
test_real_kb_query() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    kb_query --timeout 120 appliedanthropology "What is dharma?"
    assert_exit_code 0
    assert_output_contains "dharma"
}

# Test real query with JSON output
test_real_json_output() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    kb_query --output-format json --timeout 120 appliedanthropology "test"
    assert_exit_code 0
    assert_json_valid
    # Should have expected fields
    jq -e '.kb' >/dev/null 2>&1 <<<"$TEST_OUTPUT" || \
        (echo "Missing 'kb' field in JSON" && return 1)
    jq -e '.response' >/dev/null 2>&1 <<<"$TEST_OUTPUT" || \
        (echo "Missing 'response' field in JSON" && return 1)
}

# Test real context-only query
test_real_context_only() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    kb_query -c --timeout 120 appliedanthropology "ubuntu philosophy"
    assert_exit_code 0
    # Should return context without LLM processing
}

# Test complete workflow
test_complete_workflow() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    # 1. List knowledgebases
    kb_query list >/dev/null 2>&1
    assert_exit_code 0
    
    # 2. Check cache was created
    assert_file_exists "$XDG_CACHE_HOME/kb-query/kb-list"
    
    # 3. Query a knowledgebase
    kb_query --timeout 120 appliedanthropology "What is mindfulness?" >/dev/null 2>&1
    assert_exit_code 0
    
    # 4. Check history was saved
    assert_file_exists "$XDG_DATA_HOME/kb-query/history"
    grep -q "mindfulness" "$XDG_DATA_HOME/kb-query/history" || \
        (echo "Query not saved to history" && return 1)
    
    # 5. Use cached list (should be fast)
    local start_time=$(date +%s)
    kb_query list >/dev/null 2>&1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Cached query should be very fast (< 1 second)
    [[ $duration -lt 1 ]] || \
        (echo "Cache doesn't seem to be working (took ${duration}s)" && return 1)
}

# Test configuration with real API
test_config_integration() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    # Create config with short timeout
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    cat >"$XDG_CONFIG_HOME/kb-query/config" <<EOF
API_TIMEOUT=5
OUTPUT_FORMAT=json
EOF
    
    # Query should timeout
    kb_query appliedanthropology "complex philosophical question" 2>&1 || true
    assert_exit_code 1
    assert_error_contains "timeout"
}

# Test multiple output formats
test_output_format_integration() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    # Test text format
    kb_query --output-format text --timeout 120 appliedanthropology "test" >/dev/null 2>&1
    assert_exit_code 0
    
    # Test JSON format
    kb_query --output-format json --timeout 120 appliedanthropology "test" >/dev/null 2>&1
    assert_exit_code 0
    assert_json_valid
    
    # Test markdown format
    kb_query --output-format markdown --timeout 120 appliedanthropology "test" >/dev/null 2>&1
    assert_exit_code 0
    assert_output_contains "## Query Response"
}

# Test error handling with real API
test_error_handling_integration() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    # Test non-existent knowledgebase
    kb_query nonexistent-kb-$$ "test" 2>&1 || true
    assert_exit_code 1
    assert_error_contains "not found"
}

# Test query with reference
test_reference_integration() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    # Create reference file
    cat >"$TEST_TEMP_DIR/reference.txt" <<EOF
Previously we discussed the concept of dharma.
EOF
    
    kb_query -r "$TEST_TEMP_DIR/reference.txt" --timeout 120 \
        appliedanthropology "Tell me more about dharma" >/dev/null 2>&1
    assert_exit_code 0
}

# Test custom query parameters
test_query_params_integration() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    kb_query \
        --query-model gpt-4o-mini \
        --query-temperature 0.3 \
        --query-max-tokens 500 \
        --timeout 120 \
        appliedanthropology "Define karma briefly" >/dev/null 2>&1
    
    assert_exit_code 0
}

# Test batch operations
test_batch_operations() {
    if ! check_internet; then
        skip_test "${FUNCNAME[0]}" "No internet connection"
        return
    fi
    
    # Run multiple queries in sequence
    local queries=(
        "What is dharma?"
        "What is karma?"
        "What is ubuntu?"
    )
    
    for query in "${queries[@]}"; do
        kb_query --timeout 120 appliedanthropology "$query" >/dev/null 2>&1
        assert_exit_code 0
    done
    
    # Check all queries in history
    for query in "${queries[@]}"; do
        grep -q "$(echo "$query" | sed 's/ /%20/g')" "$XDG_DATA_HOME/kb-query/history" || \
            (echo "Query '$query' not found in history" && return 1)
    done
}

# Run all tests
echo
echo "Note: Integration tests require internet connectivity to https://yatti.id"
echo "Some tests may take longer due to API response times."
echo

run_test_suite "Integration Tests" \
    test_real_api_list \
    test_real_api_help \
    test_real_kb_query \
    test_real_json_output \
    test_real_context_only \
    test_complete_workflow \
    test_config_integration \
    test_output_format_integration \
    test_error_handling_integration \
    test_reference_integration \
    test_query_params_integration \
    test_batch_operations

print_test_summary