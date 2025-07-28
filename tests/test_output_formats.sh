#!/bin/bash
# Test output format handling for kb-query

source "$(dirname "$0")/test_framework.sh"

# Setup mock API for consistent testing
setup_format_test_mock() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
case "$1" in
    list)
        echo '{"response":["kb1","kb2","kb3"]}'
        ;;
    test-kb)
        echo '{
            "kb": "test-kb",
            "query": "test query",
            "response": "This is a test response.\nWith multiple lines.",
            "elapsed_seconds": 1.234,
            "context_only": false,
            "reference": null
        }'
        ;;
    *)
        echo '{"error":"Unknown command"}'
        exit 1
        ;;
esac
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
}

# Test default text output format
test_default_text_format() {
    setup_format_test_mock
    
    kb_query test-kb "test query"
    assert_exit_code 0
    assert_output_contains "This is a test response"
    assert_output_contains "With multiple lines"
    assert_output_not_contains '"response":'  # Should not be JSON
}

# Test JSON output format
test_json_format() {
    setup_format_test_mock
    
    kb_query --output-format json test-kb "test query"
    assert_exit_code 0
    assert_json_valid
    assert_json_field ".kb" "test-kb"
    assert_json_field ".query" "test query"
    assert_json_field ".elapsed_seconds" "1.234"
}

# Test markdown output format
test_markdown_format() {
    setup_format_test_mock
    
    kb_query --output-format markdown test-kb "test query"
    assert_exit_code 0
    assert_output_contains "## Query Response"
    assert_output_contains "This is a test response"
    assert_output_contains "---"
    assert_output_contains "*Knowledge Base: test-kb*"
    assert_output_contains "*Query Time: 1.234 seconds*"
}

# Test field selection with default format
test_field_selection_default() {
    setup_format_test_mock
    
    kb_query test-kb "test query" .response
    assert_exit_code 0
    assert_output_contains "This is a test response"
    assert_output_not_contains "test-kb"  # Should not include other fields
}

# Test multiple field selection
test_multiple_field_selection() {
    setup_format_test_mock
    
    kb_query test-kb "test query" .kb .elapsed_seconds
    assert_exit_code 0
    assert_output_contains "test-kb"
    assert_output_contains "1.234"
    assert_output_not_contains "This is a test response"  # Should not include response
}

# Test list command output
test_list_output_default() {
    setup_format_test_mock
    
    kb_query list
    assert_exit_code 0
    assert_output_contains "kb1"
    assert_output_contains "kb2"
    assert_output_contains "kb3"
}

# Test list command with JSON format
test_list_json_format() {
    setup_format_test_mock
    
    kb_query --output-format json list
    assert_exit_code 0
    assert_json_valid
}

# Test empty response handling
test_empty_response() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"kb":"test","query":"q","response":"","elapsed_seconds":0.1}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    kb_query test "q"
    assert_exit_code 0
    # Empty response should still work
}

# Test null response handling
test_null_response() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"kb":"test","query":"q","response":null,"elapsed_seconds":0.1}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    kb_query test "q"
    assert_exit_code 0
}

# Test special characters in output
test_special_chars_output() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"response":"Special chars: \"quotes\" \n\t<tags> & symbols"}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    kb_query test "q"
    assert_exit_code 0
    assert_output_contains "Special chars"
}

# Test markdown format with special fields
test_markdown_special_fields() {
    setup_format_test_mock
    
    kb_query --output-format markdown test-kb "test query" .kb .query
    assert_exit_code 0
    # When specific fields are requested, markdown format should be bypassed
    assert_output_contains "test-kb"
    assert_output_contains "test query"
    assert_output_not_contains "## Query Response"
}

# Test invalid JSON field selection
test_invalid_field_selection() {
    setup_format_test_mock
    
    kb_query test-kb "test query" .nonexistent
    assert_exit_code 0
    assert_output_contains "null"  # jq returns null for non-existent fields
}

# Test nested field selection
test_nested_field_selection() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"data":{"nested":{"value":"deep value"}}}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    kb_query test "q" .data.nested.value
    assert_exit_code 0
    assert_output_contains "deep value"
}

# Test array field selection
test_array_field_selection() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"items":["first","second","third"]}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    kb_query test "q" '.items[1]'
    assert_exit_code 0
    assert_output_contains "second"
}

# Test output format from config
test_format_from_config() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    echo "OUTPUT_FORMAT=json" >"$XDG_CONFIG_HOME/kb-query/config"
    
    setup_format_test_mock
    
    kb_query test-kb "test query"
    assert_exit_code 0
    assert_json_valid  # Should use JSON format from config
}

# Run all tests
run_test_suite "Output Formats" \
    test_default_text_format \
    test_json_format \
    test_markdown_format \
    test_field_selection_default \
    test_multiple_field_selection \
    test_list_output_default \
    test_list_json_format \
    test_empty_response \
    test_null_response \
    test_special_chars_output \
    test_markdown_special_fields \
    test_invalid_field_selection \
    test_nested_field_selection \
    test_array_field_selection \
    test_format_from_config

print_test_summary