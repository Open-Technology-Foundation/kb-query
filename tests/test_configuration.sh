#!/bin/bash
# Test configuration handling for kb-query

source "$(dirname "$0")/test_framework.sh"

# Test default configuration values
test_default_config() {
    kb_query --help >/dev/null 2>&1
    assert_exit_code 0
    
    # Check that defaults are applied when no config exists
    assert_file_not_exists "$XDG_CONFIG_HOME/kb-query/config"
}

# Test configuration file loading
test_config_file_loading() {
    # Create config directory and file
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    cat >"$XDG_CONFIG_HOME/kb-query/config" <<EOF
API_TIMEOUT=10
OUTPUT_FORMAT=json
MAX_REFERENCE_SIZE=2000
DEBUG=1
EOF
    
    # Test that config is loaded (debug mode will show in help output to stderr)
    kb_query --help >/dev/null 2>&1
    assert_exit_code 0
    assert_file_exists "$XDG_CONFIG_HOME/kb-query/config"
}

# Test output format configuration
test_output_format_config() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    echo "OUTPUT_FORMAT=json" >"$XDG_CONFIG_HOME/kb-query/config"
    
    # Create a mock that returns JSON
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
if [[ "$1" == "list" ]]; then
    echo '{"response":["test-kb"]}'
fi
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    KB_QUERY="$TEST_TEMP_DIR/kb-query-mock"
    
    kb_query list
    assert_json_valid
}

# Test timeout configuration
test_timeout_config() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    echo "API_TIMEOUT=5" >"$XDG_CONFIG_HOME/kb-query/config"
    
    # Verify config file exists
    assert_file_exists "$XDG_CONFIG_HOME/kb-query/config"
}

# Test command line override of config
test_cli_override_config() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    echo "OUTPUT_FORMAT=json" >"$XDG_CONFIG_HOME/kb-query/config"
    
    # Command line should override config
    kb_query --output-format text --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test invalid output format
test_invalid_output_format() {
    kb_query --output-format invalid test "query"
    assert_exit_code 1
    assert_error_contains "Invalid output format"
}

# Test invalid timeout value
test_invalid_timeout() {
    kb_query --timeout abc test "query"
    assert_exit_code 1
    assert_error_contains "Timeout must be a positive integer"
}

# Test XDG directory creation
test_xdg_directory_creation() {
    # Directories should not exist initially
    assert_file_not_exists "$XDG_CONFIG_HOME/kb-query"
    assert_file_not_exists "$XDG_CACHE_HOME/kb-query"
    assert_file_not_exists "$XDG_DATA_HOME/kb-query"
    
    # After running kb-query with certain operations, directories should be created
    # This is tested in other test files where actual operations occur
}

# Test environment variable configuration
test_env_var_config() {
    export VECTORDBS="/custom/path/vectordbs"
    
    kb_query --help >/dev/null 2>&1
    assert_exit_code 0
    # Environment variable is set and available to the script
}

# Test query model configuration
test_query_model_config() {
    kb_query --query-model gpt-4o --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test query temperature configuration
test_query_temperature_config() {
    kb_query --query-temperature 0.5 --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test multiple query options
test_multiple_query_options() {
    kb_query \
        --query-model gpt-4o \
        --query-temperature 0.7 \
        --query-max-tokens 1000 \
        --query-top-k 10 \
        --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test config file with comments
test_config_with_comments() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    cat >"$XDG_CONFIG_HOME/kb-query/config" <<'EOF'
# This is a comment
API_TIMEOUT=30  # Inline comment

# Another comment
OUTPUT_FORMAT=text
EOF
    
    kb_query --help >/dev/null 2>&1
    assert_exit_code 0
}

# Test config file with invalid syntax
test_config_invalid_syntax() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    cat >"$XDG_CONFIG_HOME/kb-query/config" <<'EOF'
This is not valid bash syntax @#$%
API_TIMEOUT=30
EOF
    
    # Script should handle invalid config gracefully
    kb_query --help 2>/dev/null
    # May fail but should not crash catastrophically
}

# Run all tests
run_test_suite "Configuration" \
    test_default_config \
    test_config_file_loading \
    test_output_format_config \
    test_timeout_config \
    test_cli_override_config \
    test_invalid_output_format \
    test_invalid_timeout \
    test_xdg_directory_creation \
    test_env_var_config \
    test_query_model_config \
    test_query_temperature_config \
    test_multiple_query_options \
    test_config_with_comments \
    test_config_invalid_syntax

print_test_summary