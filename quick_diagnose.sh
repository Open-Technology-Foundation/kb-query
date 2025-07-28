#!/bin/bash
# Quick diagnostic for API endpoints

echo "=== Quick API Diagnostic ==="
echo "Date: $(date)"
echo

# Test 1: Basic connectivity
echo "1. Testing basic connectivity to yatti.id..."
if ping -c 1 -W 2 yatti.id >/dev/null 2>&1; then
  echo "✓ yatti.id is reachable"
else
  echo "✗ Cannot reach yatti.id"
fi

# Test 2: Test old endpoint
echo
echo "2. Testing OLD endpoint (v1)..."
echo "   URL: https://yatti.id/v1/help"
if curl -s -m 5 "https://yatti.id/v1/help" | head -1 | grep -q "YaTTI\|<"; then
  echo "✓ Old endpoint responds"
else
  echo "✗ Old endpoint not responding"
fi

# Test 3: Test new endpoint  
echo
echo "3. Testing NEW endpoint (v1/index.php)..."
echo "   URL: https://yatti.id/v1/index.php/help"
response=$(curl -s -m 5 -w "\nHTTP_CODE:%{http_code}" "https://yatti.id/v1/index.php/help")
http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
echo "   HTTP Status: $http_code"

if [[ "$http_code" == "200" ]]; then
  echo "✓ New endpoint returns 200 OK"
elif [[ "$http_code" == "404" ]]; then
  echo "✗ New endpoint returns 404 Not Found"
  echo "   The v1/index.php path may not be configured on the server"
elif [[ "$http_code" == "500" ]]; then
  echo "✗ New endpoint returns 500 Internal Server Error"
  echo "   Check PHP error logs on okusi3"
else
  echo "✗ New endpoint not responding properly (code: $http_code)"
fi

# Test 4: Check what's actually there
echo
echo "4. Checking actual response from v1..."
echo "First 5 lines of response:"
curl -s -m 5 "https://yatti.id/v1/" 2>&1 | head -5

# Test 5: Try direct index.php access
echo
echo "5. Testing direct index.php access..."
echo "   URL: https://yatti.id/v1/index.php"
curl -s -m 5 -I "https://yatti.id/v1/index.php" | head -5

# Summary
echo
echo "=== Summary ==="
echo "It appears the server may not be configured to route v1/index.php properly."
echo
echo "On okusi3, check:"
echo "1. Apache/Nginx configuration for the v1 directory"
echo "2. Whether .htaccess or rewrite rules need updating"
echo "3. If index.php exists in /var/www/vhosts/yatti.id/html/v1/"
echo
echo "Quick fix - try creating a .htaccess file in v1 directory:"
echo 'RewriteEngine On'
echo 'RewriteRule ^index\.php/(.*)$ index.php?/$1 [L,QSA]'

#fin