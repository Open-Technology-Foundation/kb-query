#!/bin/bash
# Fix routing on okusi3 for v1/index.php structure

echo "=== Fixing v1/index.php Routing on okusi3 ==="
echo
echo "Run this script ON okusi3 as root"
echo

# Check if we're on okusi3
if [[ "$(hostname)" != "okusi3" ]]; then
  echo "WARNING: This script should be run on okusi3"
  echo "Copy it to okusi3 and run there:"
  echo "  scp fix_okusi3_routing.sh root@okusi3:/tmp/"
  echo "  ssh root@okusi3 'bash /tmp/fix_okusi3_routing.sh'"
  exit 1
fi

# Find the web root
WEB_ROOT="/var/www/vhosts/yatti.id/html"
if [[ ! -d "$WEB_ROOT" ]]; then
  echo "Searching for web root..."
  WEB_ROOT=$(find /var/www -name "index.php" -path "*yatti*" -exec dirname {} \; | head -1)
  if [[ -z "$WEB_ROOT" ]]; then
    echo "ERROR: Cannot find yatti.id web root"
    exit 1
  fi
fi

echo "Web root: $WEB_ROOT"

# Check if v1 directory exists
if [[ ! -d "$WEB_ROOT/v1" ]]; then
  echo "Creating v1 directory..."
  mkdir -p "$WEB_ROOT/v1"
fi

# Check current index.php
if [[ -f "$WEB_ROOT/v1/index.php" ]]; then
  echo "index.php exists in v1/"
  echo "Checking if it uses PATH_INFO..."
  if grep -q 'PATH_INFO' "$WEB_ROOT/v1/index.php"; then
    echo "✓ index.php appears to handle PATH_INFO"
  else
    echo "⚠ index.php might not handle PATH_INFO correctly"
  fi
else
  echo "ERROR: No index.php in v1/"
  exit 1
fi

# Create/update .htaccess for Apache
if [[ -d "/etc/apache2" ]]; then
  echo
  echo "Configuring Apache..."
  
  # Create .htaccess in v1 directory
  cat > "$WEB_ROOT/v1/.htaccess" << 'EOF'
# Enable URL rewriting
RewriteEngine On

# If the request is for index.php/something, handle it
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php/$1 [L,QSA]

# Ensure PATH_INFO is available
AcceptPathInfo On
EOF
  
  echo "Created $WEB_ROOT/v1/.htaccess"
  
  # Ensure .htaccess is allowed
  VHOST_CONF=$(find /etc/apache2/sites-enabled -name "*yatti*" | head -1)
  if [[ -n "$VHOST_CONF" ]]; then
    echo "Checking Apache vhost config: $VHOST_CONF"
    if ! grep -q "AllowOverride All" "$VHOST_CONF"; then
      echo "WARNING: You may need to add 'AllowOverride All' to the <Directory> section for $WEB_ROOT/v1"
      echo "Edit $VHOST_CONF and add:"
      echo "  <Directory $WEB_ROOT/v1>"
      echo "    AllowOverride All"
      echo "  </Directory>"
    fi
  fi
  
  # Enable mod_rewrite if not already
  if ! apache2ctl -M 2>/dev/null | grep -q rewrite_module; then
    echo "Enabling mod_rewrite..."
    a2enmod rewrite
    RESTART_APACHE=1
  fi
  
  # Set permissions
  chown www-data:www-data "$WEB_ROOT/v1/.htaccess"
  chmod 644 "$WEB_ROOT/v1/.htaccess"
fi

# Configure for Nginx
if [[ -d "/etc/nginx" ]]; then
  echo
  echo "Configuring Nginx..."
  
  NGINX_CONF=$(find /etc/nginx/sites-enabled -name "*yatti*" | head -1)
  if [[ -n "$NGINX_CONF" ]]; then
    echo "Found Nginx config: $NGINX_CONF"
    echo
    echo "Add this to the server block for yatti.id:"
    cat << 'EOF'

    location /v1/ {
        try_files $uri $uri/ /v1/index.php?$args;
    }
    
    location ~ ^/v1/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
EOF
    echo
    echo "Then reload Nginx: systemctl reload nginx"
  fi
fi

# Test the configuration
echo
echo "Testing configuration..."

# Test if PHP is working
if php -r 'echo "PHP is working\n";' >/dev/null 2>&1; then
  echo "✓ PHP CLI works"
fi

# Create a test script
cat > "$WEB_ROOT/v1/test_routing.php" << 'EOF'
<?php
header('Content-Type: text/plain');
echo "Test Routing Script\n";
echo "REQUEST_URI: " . $_SERVER['REQUEST_URI'] . "\n";
echo "PATH_INFO: " . ($_SERVER['PATH_INFO'] ?? 'not set') . "\n";
echo "SCRIPT_NAME: " . $_SERVER['SCRIPT_NAME'] . "\n";
echo "If you see this, PHP is working!\n";
EOF

chown www-data:www-data "$WEB_ROOT/v1/test_routing.php"

echo
echo "Created test script. Try accessing:"
echo "  https://yatti.id/v1/test_routing.php"
echo "  https://yatti.id/v1/test_routing.php/test/path"
echo

# Restart services if needed
if [[ "${RESTART_APACHE:-0}" == "1" ]]; then
  echo "Restarting Apache..."
  systemctl restart apache2
fi

echo
echo "=== Next Steps ==="
echo "1. Test the endpoints:"
echo "   curl https://yatti.id/v1/index.php/help"
echo "   curl https://yatti.id/v1/test_routing.php/test"
echo
echo "2. Check error logs:"
echo "   tail -f /var/log/apache2/error.log"
echo "   tail -f /var/log/nginx/error.log"
echo
echo "3. If still not working, check:"
echo "   - PHP-FPM is running: systemctl status php*-fpm"
echo "   - File permissions: ls -la $WEB_ROOT/v1/"
echo "   - Apache/Nginx config syntax"

#fin