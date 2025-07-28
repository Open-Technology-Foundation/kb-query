#!/bin/bash
# Test caching functionality for kb-query

source "$(dirname "$0")/test_framework.sh"

# Setup mock that tracks calls
setup_cache_test_mock() {
    local call_log="$TEST_TEMP_DIR/calls.log"
    
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<EOF
#!/bin/bash
echo "\$1" >> "$call_log"

case "\$1" in
    list)
        echo '{"response":["kb1","kb2","kb3"]}'
        ;;
    *)
        echo '{"response":"test"}'
        ;;
esac
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    # Clear call log
    : >"$call_log"
}

# Test cache directory creation
test_cache_dir_creation() {
    assert_file_not_exists "$XDG_CACHE_HOME/kb-query"
    
    setup_cache_test_mock
    kb_query list >/dev/null 2>&1
    
    assert_file_exists "$XDG_CACHE_HOME/kb-query"
}

# Test KB list caching
test_kb_list_cache() {
    setup_cache_test_mock
    local call_log="$TEST_TEMP_DIR/calls.log"
    
    # First call should hit the API
    kb_query list >/dev/null 2>&1
    assert_file_exists "$XDG_CACHE_HOME/kb-query/kb-list"
    
    local first_call_count=$(wc -l <"$call_log")
    
    # Second call should use cache
    kb_query list >/dev/null 2>&1
    
    local second_call_count=$(wc -l <"$call_log")
    
    # Call count should be the same (cache was used)
    [[ $first_call_count -eq $second_call_count ]] || \
        (echo "Cache not used: $first_call_count != $second_call_count" && return 1)
}

# Test cache expiration
test_cache_expiration() {
    setup_cache_test_mock
    
    # Create expired cache (2 hours old)
    mkdir -p "$XDG_CACHE_HOME/kb-query"
    echo '{"response":["old-kb"]}' >"$XDG_CACHE_HOME/kb-query/kb-list"
    touch -t $(date -d '2 hours ago' +%Y%m%d%H%M) "$XDG_CACHE_HOME/kb-query/kb-list"
    
    kb_query list
    assert_output_contains "kb1"  # Should get fresh data, not "old-kb"
}

# Test cache TTL from config
test_cache_ttl_config() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    echo "KB_LIST_CACHE_TTL=10" >"$XDG_CONFIG_HOME/kb-query/config"
    
    setup_cache_test_mock
    
    # Create cache that's 15 seconds old (older than TTL)
    mkdir -p "$XDG_CACHE_HOME/kb-query"
    echo '{"response":["old-kb"]}' >"$XDG_CACHE_HOME/kb-query/kb-list"
    touch -t $(date -d '15 seconds ago' +%Y%m%d%H%M.%S) "$XDG_CACHE_HOME/kb-query/kb-list" 2>/dev/null || \
        touch -t $(date -d '1 minute ago' +%Y%m%d%H%M) "$XDG_CACHE_HOME/kb-query/kb-list"
    
    kb_query list
    assert_output_contains "kb1"  # Should refresh due to short TTL
}

# Test cache with debug mode
test_cache_debug_output() {
    setup_cache_test_mock
    
    # Prime the cache
    kb_query list >/dev/null 2>&1
    
    # Second call with debug should show cache usage
    kb_query -d list 2>&1 >/dev/null
    assert_error_contains "Using cached KB list"
}

# Test cache file format
test_cache_file_format() {
    setup_cache_test_mock
    
    kb_query list >/dev/null 2>&1
    
    # Cache file should contain valid JSON
    local cache_content=$(cat "$XDG_CACHE_HOME/kb-query/kb-list")
    echo "$cache_content" | jq -e . >/dev/null 2>&1 || \
        (echo "Invalid JSON in cache: $cache_content" && return 1)
}

# Test cache with list subcommands
test_cache_list_subcommands() {
    setup_cache_test_mock
    
    # Prime cache
    kb_query list >/dev/null 2>&1
    
    # list.canonical should also use cache
    local call_log="$TEST_TEMP_DIR/calls.log"
    local before_count=$(wc -l <"$call_log")
    
    kb_query list.canonical >/dev/null 2>&1
    
    local after_count=$(wc -l <"$call_log")
    [[ $before_count -eq $after_count ]] || \
        (echo "list.canonical didn't use cache" && return 1)
}

# Test non-list commands don't cache
test_non_list_no_cache() {
    setup_cache_test_mock
    
    kb_query test-kb "query" >/dev/null 2>&1
    
    # Should not create cache for non-list commands
    [[ -f "$XDG_CACHE_HOME/kb-query/kb-list" ]] && \
        (echo "Cache created for non-list command" && return 1)
    
    return 0
}

# Test cache permissions
test_cache_permissions() {
    setup_cache_test_mock
    
    kb_query list >/dev/null 2>&1
    
    # Cache directory and file should have appropriate permissions
    local dir_perms=$(stat -c %a "$XDG_CACHE_HOME/kb-query" 2>/dev/null || stat -f %p "$XDG_CACHE_HOME/kb-query")
    local file_perms=$(stat -c %a "$XDG_CACHE_HOME/kb-query/kb-list" 2>/dev/null || stat -f %p "$XDG_CACHE_HOME/kb-query/kb-list")
    
    # Directory should be 755 or 775
    [[ "$dir_perms" =~ 7[57]5$ ]] || \
        (echo "Unexpected cache dir permissions: $dir_perms" && return 1)
}

# Test cache with concurrent access
test_cache_concurrent() {
    setup_cache_test_mock
    
    # Run multiple list commands in parallel
    (
        kb_query list >/dev/null 2>&1 &
        kb_query list >/dev/null 2>&1 &
        kb_query list >/dev/null 2>&1 &
        wait
    )
    
    # Cache should still be valid
    assert_file_exists "$XDG_CACHE_HOME/kb-query/kb-list"
}

# Test cache invalidation on error
test_cache_error_handling() {
    # Create mock that fails
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    # Try to cache (should fail)
    kb_query list 2>/dev/null || true
    
    # Cache file should not exist on error
    assert_file_not_exists "$XDG_CACHE_HOME/kb-query/kb-list"
}

# Test cache with empty response
test_cache_empty_response() {
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
echo '{"response":[]}'
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    kb_query list >/dev/null 2>&1
    
    # Empty response should still be cached
    assert_file_exists "$XDG_CACHE_HOME/kb-query/kb-list"
}

# Run all tests
run_test_suite "Caching" \
    test_cache_dir_creation \
    test_kb_list_cache \
    test_cache_expiration \
    test_cache_ttl_config \
    test_cache_debug_output \
    test_cache_file_format \
    test_cache_list_subcommands \
    test_non_list_no_cache \
    test_cache_permissions \
    test_cache_concurrent \
    test_cache_error_handling \
    test_cache_empty_response

print_test_summary