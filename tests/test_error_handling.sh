#!/bin/bash
# Test error handling for kb-query

source "$(dirname "$0")/test_framework.sh"

# Test network connection errors
test_connection_error() {
    # Create mock that simulates connection failure
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
# Simulate curl exit code 7 (connection failed)
exit 7
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Override curl to use our mock
    cat >"$KB_QUERY" <<'EOF'
#!/bin/bash
curl() {
    exit 7
}
source "$(dirname "$0")/../kb-query"
EOF
    chmod +x "$KB_QUERY"
    
    kb_query test-kb "query" 2>&1 || true
    assert_error_contains "Failed to connect"
}

# Test timeout errors
test_timeout_error() {
    # Create wrapper that overrides curl to simulate timeout
    cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    if [[ "\$*" =~ --max-time ]]; then
        exit 28  # Timeout exit code
    fi
    /usr/bin/curl "\$@"
}
source "$PROJECT_DIR/kb-query"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
    
    kb_query test-kb "query" 2>&1 || true
    assert_exit_code 1
    assert_error_contains "timeout"
}

# Test invalid JSON response
test_invalid_json_response() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo "This is not JSON"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Create wrapper that uses mock for curl
    cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    "$TEST_TEMP_DIR/kb-query-mock"
}
source "$PROJECT_DIR/kb-query"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
    
    kb_query test-kb "query" 2>&1 || true
    assert_exit_code 1
    assert_error_contains "Invalid JSON"
}

# Test empty response
test_empty_response_error() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
# Return nothing
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Create wrapper
    cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    "$TEST_TEMP_DIR/kb-query-mock"
}
source "$PROJECT_DIR/kb-query"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
    
    kb_query test-kb "query" 2>&1 || true
    assert_exit_code 1
    assert_error_contains "Empty response"
}

# Test API error response
test_api_error_response() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"error":"Database connection failed"}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Create wrapper
    cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    "$TEST_TEMP_DIR/kb-query-mock"
}
source "$PROJECT_DIR/kb-query"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
    
    kb_query test-kb "query" 2>&1 || true
    assert_exit_code 1
    assert_error_contains "API Error"
    assert_error_contains "Database connection failed"
}

# Test non-existent knowledge base
test_nonexistent_kb_error() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"error":"Knowledgebase [nonexistent] not found"}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Create wrapper
    cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    "$TEST_TEMP_DIR/kb-query-mock"
}
source "$PROJECT_DIR/kb-query"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
    
    kb_query nonexistent "query" 2>&1 || true
    assert_exit_code 1
    assert_error_contains "Knowledgebase"
    assert_error_contains "not found"
}

# Test null response for queries
test_null_response_query() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"kb":"test","query":"q","response":null}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Create wrapper
    cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    "$TEST_TEMP_DIR/kb-query-mock"
}
source "$PROJECT_DIR/kb-query"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
    
    kb_query test "q" 2>&1 || true
    assert_exit_code 1
    assert_error_contains "no data"
}

# Test reference file errors
test_reference_file_not_found() {
    kb_query -r "/tmp/nonexistent-$$$.txt" test-kb "query"
    assert_exit_code 1
    assert_error_contains "not found"
}

# Test reference file path validation
test_reference_file_path_validation() {
    kb_query -r "../../../etc/passwd" test-kb "query"
    assert_exit_code 1
    assert_error_contains "Invalid reference file path"
}

# Test missing argument errors
test_missing_argument_errors() {
    kb_query -r
    assert_exit_code 2
    assert_error_contains "Missing argument"
    
    kb_query --timeout
    assert_exit_code 2
    assert_error_contains "Missing argument"
    
    kb_query --output-format
    assert_exit_code 2
    assert_error_contains "Missing argument"
}

# Test invalid option values
test_invalid_option_values() {
    kb_query --timeout "not-a-number" test "query"
    assert_exit_code 1
    assert_error_contains "positive integer"
    
    kb_query --output-format "invalid" test "query"
    assert_exit_code 1
    assert_error_contains "Invalid output format"
}

# Test progress indicator errors
test_progress_indicator_error() {
    # Progress indicator should appear on stderr
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
sleep 0.1
echo '{"response":"test"}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Create wrapper
    cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    "$TEST_TEMP_DIR/kb-query-mock"
}
source "$PROJECT_DIR/kb-query"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
    
    kb_query test-kb "query" 2>&1 >/dev/null
    assert_error_contains "Querying test-kb..."
}

# Test curl network error codes
test_curl_error_codes() {
    # Test various curl error codes
    local error_codes=(
        "6:resolve host"
        "35:SSL/TLS"
        "52:server reply"
    )
    
    for code_msg in "${error_codes[@]}"; do
        local code="${code_msg%%:*}"
        
        cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    exit $code
}
source "$PROJECT_DIR/kb-query"
EOF
        chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
        KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
        
        kb_query test-kb "query" 2>&1 || true
        assert_exit_code 1
        assert_error_contains "Network error"
        assert_error_contains "curl exit code: $code"
    done
}

# Test error with debug mode
test_error_with_debug() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"error":"Test error"}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Create wrapper
    cat >"$TEST_TEMP_DIR/kb-query-wrapper" <<EOF
#!/bin/bash
curl() {
    "$TEST_TEMP_DIR/kb-query-mock"
}
source "$PROJECT_DIR/kb-query"
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-wrapper"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-wrapper"
    
    kb_query -d test-kb "query" 2>&1 || true
    assert_exit_code 1
    # Debug output should show before error
    assert_error_contains "debug"
}

# Run all tests
run_test_suite "Error Handling" \
    test_connection_error \
    test_timeout_error \
    test_invalid_json_response \
    test_empty_response_error \
    test_api_error_response \
    test_nonexistent_kb_error \
    test_null_response_query \
    test_reference_file_not_found \
    test_reference_file_path_validation \
    test_missing_argument_errors \
    test_invalid_option_values \
    test_progress_indicator_error \
    test_curl_error_codes \
    test_error_with_debug

print_test_summary