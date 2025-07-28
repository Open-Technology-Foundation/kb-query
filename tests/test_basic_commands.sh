#!/bin/bash
# Test basic commands for kb-query

source "$(dirname "$0")/test_framework.sh"

# Test help command
test_help_command() {
    kb_query --help
    assert_exit_code 0
    assert_output_contains "kb-query"
    assert_output_contains "Usage:"
    assert_output_contains "Options:"
    assert_output_contains "Examples:"
}

# Test version command
test_version_command() {
    kb_query --version
    assert_exit_code 0
    assert_output_contains "kb-query"
    assert_output_contains "[0-9]+\.[0-9]+\.[0-9]+"
}

# Test version short form
test_version_short_command() {
    kb_query -V
    assert_exit_code 0
    assert_output_contains "kb-query"
}

# Test help short form
test_help_short_command() {
    kb_query -h
    assert_exit_code 0
    assert_output_contains "Usage:"
}

# Test no arguments
test_no_arguments() {
    kb_query
    assert_exit_code 1
    assert_error_contains "Usage:"
}

# Test invalid option
test_invalid_option() {
    kb_query --invalid-option
    assert_exit_code 22
    assert_error_contains "Invalid option"
}

# Test invalid environment variable
test_invalid_env_var() {
    kb_query --invalid-env test "query"
    assert_exit_code 1
    assert_error_contains "Invalid EnvVar"
}

# Test missing argument for option
test_missing_option_argument() {
    kb_query -r
    assert_exit_code 2
    assert_error_contains "Missing argument for option"
}

# Test combined short options
test_combined_short_options() {
    kb_query -dv --help
    assert_exit_code 0
    assert_output_contains "Usage:"
    # Debug and verbose should be enabled
}

# Test quiet mode
test_quiet_mode() {
    # Create a mock that simulates a successful query
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
if [[ "$1" == "test-kb" ]]; then
    >&2 echo "Querying test-kb... done"
    echo "Mock response"
fi
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    kb_query -q test-kb "query"
    assert_output_contains "Mock response"
    assert_error_not_contains "Querying"
}

# Test debug mode
test_debug_mode() {
    kb_query -d --help >/dev/null 2>&1
    assert_exit_code 0
    # Debug mode is set but doesn't affect help output
}

# Test verbose mode
test_verbose_mode() {
    kb_query -v --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test multiple verbose flags
test_multiple_verbose() {
    kb_query -vvv --help >/dev/null 2>&1
    assert_exit_code 0
}

# Run all tests
run_test_suite "Basic Commands" \
    test_help_command \
    test_version_command \
    test_version_short_command \
    test_help_short_command \
    test_no_arguments \
    test_invalid_option \
    test_invalid_env_var \
    test_missing_option_argument \
    test_combined_short_options \
    test_quiet_mode \
    test_debug_mode \
    test_verbose_mode \
    test_multiple_verbose

# Skip API-dependent tests if offline
if ! curl -s --connect-timeout 2 https://yatti.id >/dev/null 2>&1; then
    skip_test "test_api_commands" "No internet connection"
fi

print_test_summary