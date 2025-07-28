# KB-Query Test Suite

Comprehensive test suite for the kb-query command-line tool.

## Overview

This test suite provides thorough testing of all kb-query functionality including:

- Basic command functionality
- Configuration handling
- Security features
- Output formatting
- Caching mechanisms
- History tracking
- Error handling
- Integration with the YaTTI API

## Running Tests

### Run All Tests
```bash
./run_all_tests.sh
```

### Run Tests Without Internet (Skip Integration Tests)
```bash
./run_all_tests.sh --quick
```

### Run Specific Test Suite
```bash
./run_all_tests.sh --suite security
./run_all_tests.sh --suite output_formats
```

### Run With Verbose Output
```bash
./run_all_tests.sh --verbose
```

## Test Suites

### test_basic_commands.sh
Tests fundamental functionality:
- Help and version commands
- Command-line argument parsing
- Option handling
- Basic error conditions

### test_configuration.sh
Tests configuration file handling:
- Loading config from XDG directories
- Environment variable handling
- Command-line override of config values
- Invalid configuration handling

### test_security.sh
Tests security features:
- Command injection prevention
- Path traversal protection
- URL encoding
- Input validation
- Secure temp file handling

### test_output_formats.sh
Tests output formatting:
- JSON output format
- Text output format
- Markdown output format
- Field selection
- jq integration

### test_caching.sh
Tests caching functionality:
- KB list caching
- Cache expiration
- Cache invalidation
- Concurrent access handling

### test_history.sh
Tests query history:
- History file creation
- Entry formatting
- URL encoding in history
- History configuration

### test_error_handling.sh
Tests error conditions:
- Network errors
- Timeout handling
- Invalid responses
- API errors
- Missing files

### test_integration.sh
Tests real API integration:
- Actual API queries
- Full workflow testing
- Performance validation
- Multi-format queries

## Test Framework

The test framework (`test_framework.sh`) provides:

### Assertions
- `assert_exit_code` - Check command exit status
- `assert_output_contains` - Verify output contains text
- `assert_output_not_contains` - Verify output doesn't contain text
- `assert_error_contains` - Check stderr output
- `assert_file_exists` - Verify file existence
- `assert_json_valid` - Validate JSON output
- `assert_json_field` - Check JSON field values

### Test Helpers
- `kb_query` - Run kb-query and capture output/errors
- `setup_test_env` - Create isolated test environment
- `cleanup_test_env` - Clean up after tests
- `run_test` - Execute individual test
- `skip_test` - Skip test with reason

### Mock Support
- Mock API responses for offline testing
- Simulate various error conditions
- Test edge cases safely

## Writing New Tests

1. Create a new test file: `test_feature.sh`
2. Source the test framework:
   ```bash
   source "$(dirname "$0")/test_framework.sh"
   ```
3. Write test functions:
   ```bash
   test_my_feature() {
       kb_query test-kb "query"
       assert_exit_code 0
       assert_output_contains "expected text"
   }
   ```
4. Run tests:
   ```bash
   run_test_suite "Feature Name" \
       test_my_feature \
       test_another_feature
   
   print_test_summary
   ```
5. Add to `run_all_tests.sh` TEST_SUITES array

## Test Environment

Each test runs in an isolated environment with:
- Temporary HOME directory
- Separate XDG directories
- Clean configuration
- No interference between tests

## Dependencies

The test suite requires:
- bash 4.0+
- curl
- jq
- Basic Unix utilities (grep, sed, etc.)

## Continuous Integration

The test suite is designed to work in CI environments:
- Exit codes indicate success/failure
- Minimal output by default
- Verbose mode for debugging
- Quick mode for fast feedback

## Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Always clean up test artifacts
3. **Mocking**: Use mocks for external dependencies
4. **Assertions**: Use clear, specific assertions
5. **Documentation**: Document what each test verifies
6. **Performance**: Keep tests fast when possible
7. **Reliability**: Avoid flaky tests

## Troubleshooting

### Tests Fail With Permission Errors
Ensure test files are executable:
```bash
chmod +x tests/*.sh
```

### Integration Tests Timeout
The YaTTI API can be slow. Increase timeouts or use `--quick` mode.

### Mock Tests Fail
Check that the kb-query script path is correct in test_framework.sh.

### Cleanup Issues
The framework uses trap to ensure cleanup. Check for stuck temp directories in /tmp.