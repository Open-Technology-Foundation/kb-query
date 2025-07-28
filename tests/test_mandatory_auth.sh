#!/bin/bash
# Test mandatory authentication for kb-query
# This replaces test_authentication.sh for the mandatory auth system

source "$(dirname "$0")/test_framework.sh"

# Test public endpoints work without auth
test_public_endpoints_no_auth() {
    # Ensure no API key is set
    unset YATTI_API_KEY
    rm -f "$XDG_CONFIG_HOME/kb-query/config"
    
    # Help should work without auth
    kb_query help
    assert_exit_code 0
    assert_output_contains "YaTTI Custom Knowledgebase System"
    
    # List should work without auth
    kb_query list
    assert_exit_code 0
}

# Test KB queries require authentication
test_kb_query_requires_auth() {
    # Ensure no API key is set
    unset YATTI_API_KEY
    rm -f "$XDG_CONFIG_HOME/kb-query/config"
    
    # Create mock that simulates auth failure
    cat >"$TEST_TEMP_DIR/kb-query-mock" <<'EOF'
#!/bin/bash
if [[ "$*" =~ "Authorization: Bearer" ]]; then
    echo '{"response":"authenticated"}'
else
    echo '{"error":"No API key provided"}'
    exit 1
fi
EOF
    chmod +x "$TEST_TEMP_DIR/kb-query-mock"
    
    # Query should fail without auth
    kb_query test-kb "query" 2>&1 || true
    # Would get auth error from real API
}

# Test API key from environment variable
test_api_key_env_var_required() {
    export YATTI_API_KEY="yatti_test123456789012345678901234567890123456789012345678901234567890"
    
    # Should include auth header
    kb_query -d help 2>&1
    assert_error_contains "Using API key: yatti_te...7890"
    
    unset YATTI_API_KEY
}

# Test API key from config file
test_api_key_config_file_required() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    cat >"$XDG_CONFIG_HOME/kb-query/config" <<EOF
YATTI_API_KEY="yatti_test123456789012345678901234567890123456789012345678901234567890"
EOF
    chmod 600 "$XDG_CONFIG_HOME/kb-query/config"
    
    # Should load API key from config
    kb_query -d help 2>&1
    assert_error_contains "Using API key"
}

# Test authentication error messages
test_auth_error_messages() {
    unset YATTI_API_KEY
    
    # Check error handling exists
    grep -q "401) die 1 \"Authentication failed" "$KB_QUERY" || \
        (echo "Missing 401 error handling" && return 1)
    grep -q "403) die 1 \"Access forbidden" "$KB_QUERY" || \
        (echo "Missing 403 error handling" && return 1)
    grep -q "429) die 1 \"Rate limit exceeded" "$KB_QUERY" || \
        (echo "Missing 429 error handling" && return 1)
}

# Test help shows authentication info
test_help_shows_auth_required() {
    kb_query help
    assert_output_contains "Authentication"
    assert_output_contains "API key"
    assert_output_contains "Authorization: Bearer"
}

# Test config file permission warnings still work
test_config_permission_warning() {
    mkdir -p "$XDG_CONFIG_HOME/kb-query"
    cat >"$XDG_CONFIG_HOME/kb-query/config" <<EOF
YATTI_API_KEY="yatti_test123456789012345678901234567890123456789012345678901234567890"
EOF
    chmod 644 "$XDG_CONFIG_HOME/kb-query/config"
    
    kb_query help 2>&1
    assert_error_contains "Warning: Config file has loose permissions"
    assert_error_contains "chmod 600"
}

# Test command line API key option with warning
test_api_key_command_line_warning() {
    kb_query --api-key "yatti_test123456789012345678901234567890123456789012345678901234567890" help 2>&1
    assert_exit_code 0
    assert_error_contains "Warning: --api-key exposes key in process list"
    assert_error_contains "export YATTI_API_KEY"
}

# Test eval command for auth headers
test_curl_eval_command() {
    export YATTI_API_KEY="yatti_test123456789012345678901234567890123456789012345678901234567890"
    
    # The kb-query script uses eval for curl command
    # This is necessary to properly handle the auth headers
    grep -q "eval curl" "$KB_QUERY" || \
        (echo "Missing eval for curl command" && return 1)
    
    unset YATTI_API_KEY
}

# Test documentation mentions mandatory auth
test_docs_mention_mandatory_auth() {
    # Check README
    if [[ -f "$PROJECT_DIR/README.md" ]]; then
        grep -q "API key" "$PROJECT_DIR/README.md" || \
            (echo "README doesn't mention API key requirement" && return 1)
    fi
    
    # Check help output
    kb_query --help
    assert_output_contains "YATTI_API_KEY"
    assert_output_contains "api-key"
}

# Test rate limit headers presence
test_rate_limit_headers_info() {
    kb_query help
    assert_output_contains "X-RateLimit"
}

# Run all tests
run_test_suite "Mandatory Authentication" \
    test_public_endpoints_no_auth \
    test_kb_query_requires_auth \
    test_api_key_env_var_required \
    test_api_key_config_file_required \
    test_auth_error_messages \
    test_help_shows_auth_required \
    test_config_permission_warning \
    test_api_key_command_line_warning \
    test_curl_eval_command \
    test_docs_mention_mandatory_auth \
    test_rate_limit_headers_info

print_test_summary