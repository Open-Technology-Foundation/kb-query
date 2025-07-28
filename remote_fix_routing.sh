#!/bin/bash
# Remote fix for v1/index.php routing on okusi3

# First, let's check what's actually on the server
echo "=== Checking okusi3 Configuration ==="

# Find the web root
WEB_ROOT="/var/www/vhosts/yatti.id/html"
if [[ ! -d "$WEB_ROOT" ]]; then
  WEB_ROOT="/var/www/html/yatti.id"
  if [[ ! -d "$WEB_ROOT" ]]; then
    echo "ERROR: Cannot find web root. Searching..."
    find /var/www -type d -name "*yatti*" 2>/dev/null
    exit 1
  fi
fi

echo "Web root found: $WEB_ROOT"

# Check v1 directory
if [[ -d "$WEB_ROOT/v1" ]]; then
  echo "✓ v1 directory exists"
  ls -la "$WEB_ROOT/v1/" | head -5
else
  echo "✗ v1 directory missing - creating it"
  mkdir -p "$WEB_ROOT/v1"
fi

# Check for index.php
if [[ -f "$WEB_ROOT/v1/index.php" ]]; then
  echo "✓ index.php exists"
  echo "File size: $(stat -c%s "$WEB_ROOT/v1/index.php") bytes"
else
  echo "✗ index.php missing in v1/"
  # Try to find it
  echo "Looking for index.php..."
  find "$WEB_ROOT" -name "index.php" -type f 2>/dev/null | grep -v "/vendor/" | head -5
fi

# Check web server
if systemctl is-active --quiet apache2; then
  echo "✓ Apache2 is running"
  WEB_SERVER="apache"
elif systemctl is-active --quiet nginx; then
  echo "✓ Nginx is running"
  WEB_SERVER="nginx"
else
  echo "✗ No web server detected"
  exit 1
fi

# Create .htaccess for Apache
if [[ "$WEB_SERVER" == "apache" ]]; then
  echo
  echo "=== Configuring Apache ==="
  
  # Create .htaccess
  cat > "$WEB_ROOT/v1/.htaccess" << 'EOF'
# Enable URL rewriting for v1/index.php routing
RewriteEngine On

# Handle index.php/path style URLs
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php/$1 [L,QSA]

# Ensure PATH_INFO works
AcceptPathInfo On

# PHP settings
php_flag display_errors off
php_value max_execution_time 30
EOF

  echo "Created $WEB_ROOT/v1/.htaccess"
  
  # Set permissions
  chown www-data:www-data "$WEB_ROOT/v1/.htaccess"
  chmod 644 "$WEB_ROOT/v1/.htaccess"
  
  # Check if mod_rewrite is enabled
  if apache2ctl -M 2>/dev/null | grep -q rewrite_module; then
    echo "✓ mod_rewrite is enabled"
  else
    echo "Enabling mod_rewrite..."
    a2enmod rewrite
    echo "⚠ Apache restart needed"
  fi
fi

# Create a simple test endpoint
echo
echo "=== Creating Test Endpoint ==="
cat > "$WEB_ROOT/v1/test.php" << 'EOF'
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'ok',
    'path_info' => $_SERVER['PATH_INFO'] ?? 'not set',
    'request_uri' => $_SERVER['REQUEST_URI'],
    'script_name' => $_SERVER['SCRIPT_NAME'],
    'php_version' => PHP_VERSION
]);
EOF

chown www-data:www-data "$WEB_ROOT/v1/test.php"
chmod 644 "$WEB_ROOT/v1/test.php"

echo "Created test endpoint"

# Test the current setup
echo
echo "=== Testing Current Setup ==="
echo "Testing: https://yatti.id/v1/test.php"
curl -s -m 5 "https://yatti.id/v1/test.php" || echo "Failed to reach test.php"

echo
echo "=== Summary ==="
echo "1. Web root: $WEB_ROOT"
echo "2. Web server: $WEB_SERVER"
echo "3. Created .htaccess for URL rewriting"
echo "4. Created test.php endpoint"
echo
echo "Next: Test these URLs:"
echo "  curl https://yatti.id/v1/test.php"
echo "  curl https://yatti.id/v1/test.php/some/path"
echo "  curl https://yatti.id/v1/index.php/help"

#fin