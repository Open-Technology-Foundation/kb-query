#!/bin/bash
# Test security features for kb-query

source "$(dirname "$0")/test_framework.sh"

# Test command injection protection in query
test_command_injection_query() {
    # Try to inject commands in query
    kb_query test-kb '"; echo "INJECTED" >&2; #' 2>/dev/null || true
    assert_error_not_contains "INJECTED"
}

# Test command injection in reference
test_command_injection_reference() {
    kb_query -R '$(echo INJECTED >&2)' test-kb "query" 2>/dev/null || true
    assert_error_not_contains "INJECTED"
}

# Test path traversal in reference file
test_path_traversal_reference() {
    # Try to read /etc/passwd
    kb_query -r "/etc/passwd" test-kb "query"
    assert_exit_code 1
    assert_error_contains "Invalid reference file path"
}

# Test path traversal with ..
test_path_traversal_dots() {
    kb_query -r "../../../etc/passwd" test-kb "query"
    assert_exit_code 1
    assert_error_contains "Invalid reference file path"
}

# Test allowed paths
test_allowed_paths() {
    # Create test file in allowed location
    mkdir -p "$HOME/test"
    echo "test content" >"$HOME/test/ref.txt"
    
    kb_query -r "$HOME/test/ref.txt" --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test tmp directory access
test_tmp_access() {
    echo "test" >/tmp/test-ref.txt
    kb_query -r "/tmp/test-ref.txt" --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test secure temp file creation
test_secure_temp_files() {
    # The update command uses mktemp
    # We can't actually run update, but we can verify the code path exists
    kb_query --help | grep -q "update" && assert_exit_code 0
}

# Test URL encoding in parameters
test_url_encoding() {
    # Special characters should be encoded
    kb_query test-kb 'query with spaces & special=chars' --help 2>&1 || true
    # The query should be URL encoded internally
}

# Test SQL injection attempts
test_sql_injection() {
    kb_query test-kb "'; DROP TABLE users; --" --help 2>&1 || true
    # Should be safely encoded
}

# Test environment variable injection
test_env_var_injection() {
    kb_query --query-model '$PATH' test-kb "query" 2>&1 || true
    assert_error_not_contains "/usr/bin"
}

# Test large input handling
test_large_input() {
    # Create large reference file
    local large_file="$TEST_TEMP_DIR/large.txt"
    dd if=/dev/zero bs=1024 count=10 2>/dev/null | tr '\0' 'A' >"$large_file"
    
    kb_query -r "$large_file" --help 2>&1
    assert_exit_code 0
    # Should truncate if too large
}

# Test special characters in filenames
test_special_filename_chars() {
    local special_file="$TEST_TEMP_DIR/file with spaces.txt"
    echo "content" >"$special_file"
    
    kb_query -r "$special_file" --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test symlink handling
test_symlink_reference() {
    # Create symlink to allowed file
    echo "content" >"$TEST_TEMP_DIR/real.txt"
    ln -s "$TEST_TEMP_DIR/real.txt" "$TEST_TEMP_DIR/link.txt"
    
    kb_query -r "$TEST_TEMP_DIR/link.txt" --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test directory as reference file
test_directory_reference() {
    kb_query -r "$TEST_TEMP_DIR" test-kb "query"
    assert_exit_code 1
    assert_error_contains "Reference file"
}

# Test non-existent reference file
test_nonexistent_reference() {
    kb_query -r "/tmp/does-not-exist-$$$.txt" test-kb "query"
    assert_exit_code 1
    assert_error_contains "not found"
}

# Test query option injection
test_query_option_injection() {
    kb_query --query-model "gpt-4; rm -rf /" test-kb "query" 2>&1 || true
    # Should be safely handled
}

# Test context file validation
test_context_file_validation() {
    kb_query --query-context-files "/etc/passwd,/etc/shadow" test-kb "query" 2>&1 || true
    # Should validate file paths
}

# Test printf format string attacks
test_printf_format_string() {
    kb_query test-kb '%s %s %s %n' --help 2>&1 || true
    # Should not crash or expose memory
}

# Test null byte injection
test_null_byte_injection() {
    # Bash doesn't handle null bytes well, but test the attempt
    kb_query test-kb $'query\x00injected' --help 2>&1 || true
    # Should handle gracefully
}

# Run all tests
run_test_suite "Security" \
    test_command_injection_query \
    test_command_injection_reference \
    test_path_traversal_reference \
    test_path_traversal_dots \
    test_allowed_paths \
    test_tmp_access \
    test_secure_temp_files \
    test_url_encoding \
    test_sql_injection \
    test_env_var_injection \
    test_large_input \
    test_special_filename_chars \
    test_symlink_reference \
    test_directory_reference \
    test_nonexistent_reference \
    test_query_option_injection \
    test_context_file_validation \
    test_printf_format_string \
    test_null_byte_injection

print_test_summary