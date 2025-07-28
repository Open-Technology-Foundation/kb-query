#!/bin/bash
# Quick test to verify kb-query functionality

set -euo pipefail

KB_QUERY="../kb-query"

echo "Quick KB-Query Tests"
echo "==================="
echo

# Test 1: Help command
echo -n "Test 1: Help command... "
if $KB_QUERY --help >/dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
fi

# Test 2: Version command
echo -n "Test 2: Version command... "
if $KB_QUERY --version | grep -q "kb-query"; then
    echo "PASS"
else
    echo "FAIL"
fi

# Test 3: Invalid option
echo -n "Test 3: Invalid option handling... "
if ! $KB_QUERY --invalid-option 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
fi

# Test 4: Output format validation
echo -n "Test 4: Output format validation... "
if ! $KB_QUERY --output-format invalid test query 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
fi

# Test 5: Configuration loading
echo -n "Test 5: Configuration test... "
export HOME=$(mktemp -d)
mkdir -p "$HOME/.config/kb-query"
echo "API_TIMEOUT=10" > "$HOME/.config/kb-query/config"
if $KB_QUERY --help >/dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
fi
rm -rf "$HOME"

# Test 6: Reference file validation
echo -n "Test 6: Reference file security... "
if ! $KB_QUERY -r /etc/passwd test query 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
fi

echo
echo "Quick tests completed!"