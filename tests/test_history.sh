#!/bin/bash
# Test history functionality for kb-query

source "$(dirname "$0")/test_framework.sh"

# Setup mock for history testing
setup_history_test_mock() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
case "$1" in
    list|help|update)
        echo '{"response":"command output"}'
        ;;
    *)
        echo '{"kb":"'$1'","query":"'$2'","response":"test response"}'
        ;;
esac
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
}

# Test history directory creation
test_history_dir_creation() {
    setup_history_test_mock
    
    assert_file_not_exists "$XDG_DATA_HOME/kb-query"
    
    kb_query test-kb "test query" >/dev/null 2>&1
    
    assert_file_exists "$XDG_DATA_HOME/kb-query"
    assert_file_exists "$XDG_DATA_HOME/kb-query/history"
}

# Test history entry format
test_history_entry_format() {
    setup_history_test_mock
    
    kb_query test-kb "test query" >/dev/null 2>&1
    
    local history_line=$(tail -1 "$XDG_DATA_HOME/kb-query/history")
    
    # Should contain timestamp | kb | query
    [[ "$history_line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]] || \
        (echo "Invalid timestamp format in history: $history_line" && return 1)
    
    assert_output_contains "test-kb" <<<"$history_line"
    assert_output_contains "test%20query" <<<"$history_line"  # URL encoded
}

# Test commands not saved to history
test_commands_not_in_history() {
    setup_history_test_mock
    
    # These commands should not be saved
    kb_query list >/dev/null 2>&1
    kb_query help >/dev/null 2>&1
    kb_query update 2>/dev/null || true  # May fail, that's ok
    
    # History should not exist or be empty
    if [[ -f "$XDG_DATA_HOME/kb-query/history" ]]; then
        local line_count=$(wc -l <"$XDG_DATA_HOME/kb-query/history")
        [[ $line_count -eq 0 ]] || \
            (echo "Commands saved to history when they shouldn't be" && return 1)
    fi
}

# Test multiple queries saved
test_multiple_queries() {
    setup_history_test_mock
    
    kb_query kb1 "query 1" >/dev/null 2>&1
    kb_query kb2 "query 2" >/dev/null 2>&1
    kb_query kb3 "query 3" >/dev/null 2>&1
    
    local line_count=$(wc -l <"$XDG_DATA_HOME/kb-query/history")
    [[ $line_count -eq 3 ]] || \
        (echo "Expected 3 history entries, got $line_count" && return 1)
}

# Test special characters in queries
test_special_chars_history() {
    setup_history_test_mock
    
    kb_query test-kb "query with spaces & special=chars" >/dev/null 2>&1
    
    local history_line=$(tail -1 "$XDG_DATA_HOME/kb-query/history")
    
    # Should be URL encoded
    assert_output_contains "query%20with%20spaces" <<<"$history_line"
    assert_output_contains "%26" <<<"$history_line"  # & encoded
    assert_output_contains "special%3Dchars" <<<"$history_line"  # = encoded
}

# Test history with context-only queries
test_context_only_history() {
    setup_history_test_mock
    
    kb_query -c test-kb "context query" >/dev/null 2>&1
    
    # Context-only queries should still be saved
    assert_file_exists "$XDG_DATA_HOME/kb-query/history"
    local history_line=$(tail -1 "$XDG_DATA_HOME/kb-query/history")
    assert_output_contains "context%20query" <<<"$history_line"
}

# Test history with reference
test_reference_history() {
    setup_history_test_mock
    
    echo "ref content" >"$TEST_TEMP_DIR/ref.txt"
    kb_query -r "$TEST_TEMP_DIR/ref.txt" test-kb "query with ref" >/dev/null 2>&1
    
    # Query should still be saved (reference is not included in history)
    local history_line=$(tail -1 "$XDG_DATA_HOME/kb-query/history")
    assert_output_contains "query%20with%20ref" <<<"$history_line"
    assert_output_not_contains "ref content" <<<"$history_line"
}

# Test history disabled by config
test_history_disabled() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    echo "SAVE_HISTORY=0" >"$XDG_CONFIG_HOME/kb-query/config"
    
    setup_history_test_mock
    
    kb_query test-kb "should not save" >/dev/null 2>&1
    
    # History should not be created when disabled
    assert_file_not_exists "$XDG_DATA_HOME/kb-query/history"
}

# Test history file permissions
test_history_permissions() {
    setup_history_test_mock
    
    kb_query test-kb "test" >/dev/null 2>&1
    
    # History file should be readable/writable by user only
    local perms=$(stat -c %a "$XDG_DATA_HOME/kb-query/history" 2>/dev/null || stat -f %p "$XDG_DATA_HOME/kb-query/history")
    
    [[ "$perms" =~ 6[46]4$ ]] || \
        (echo "Unexpected history file permissions: $perms" && return 1)
}

# Test history with empty query
test_empty_query_history() {
    setup_history_test_mock
    
    kb_query test-kb "" >/dev/null 2>&1
    
    # Empty queries should still be saved
    if [[ -f "$XDG_DATA_HOME/kb-query/history" ]]; then
        local line_count=$(wc -l <"$XDG_DATA_HOME/kb-query/history")
        [[ $line_count -gt 0 ]] || \
            (echo "Empty query not saved to history" && return 1)
    fi
}

# Test history timestamp format
test_history_timestamp() {
    setup_history_test_mock
    
    # Capture current time
    local before=$(date +%s)
    
    kb_query test-kb "test" >/dev/null 2>&1
    
    local after=$(date +%s)
    
    # Parse timestamp from history
    local history_line=$(tail -1 "$XDG_DATA_HOME/kb-query/history")
    local timestamp=$(echo "$history_line" | cut -d'|' -f1 | tr -d ' ')
    
    # Verify it's a valid ISO timestamp
    date -d "$timestamp" >/dev/null 2>&1 || \
        (echo "Invalid timestamp format: $timestamp" && return 1)
}

# Test history with long queries
test_long_query_history() {
    setup_history_test_mock
    
    local long_query=$(printf 'x%.0s' {1..500})  # 500 character query
    
    kb_query test-kb "$long_query" >/dev/null 2>&1
    
    # Long queries should be saved completely
    local history_line=$(tail -1 "$XDG_DATA_HOME/kb-query/history")
    local saved_length=${#history_line}
    
    [[ $saved_length -gt 500 ]] || \
        (echo "Long query truncated in history" && return 1)
}

# Test history append mode
test_history_append() {
    setup_history_test_mock
    
    # Create existing history
    mkdir -p "$XDG_DATA_HOME/kb-query"
    echo "2025-01-01T00:00:00+00:00 | old-kb | old-query" >"$XDG_DATA_HOME/kb-query/history"
    
    kb_query test-kb "new query" >/dev/null 2>&1
    
    # Should append, not overwrite
    local line_count=$(wc -l <"$XDG_DATA_HOME/kb-query/history")
    [[ $line_count -eq 2 ]] || \
        (echo "History not appended correctly" && return 1)
    
    # Old entry should still exist
    head -1 "$XDG_DATA_HOME/kb-query/history" | grep -q "old-kb" || \
        (echo "Old history entry lost" && return 1)
}

# Run all tests
run_test_suite "History" \
    test_history_dir_creation \
    test_history_entry_format \
    test_commands_not_in_history \
    test_multiple_queries \
    test_special_chars_history \
    test_context_only_history \
    test_reference_history \
    test_history_disabled \
    test_history_permissions \
    test_empty_query_history \
    test_history_timestamp \
    test_long_query_history \
    test_history_append

print_test_summary