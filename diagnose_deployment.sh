#!/bin/bash
# Diagnose deployment issues on okusi3

set -euo pipefail

# Colors
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly NOCOLOR=$'\033[0m'

# Configuration
readonly DEPLOY_HOST="okusi3"
readonly DEPLOY_USER="${DEPLOY_USER:-root}"
readonly REMOTE_PATH="/var/www/vhosts/yatti.id/html"

echo "${BLUE}=== Deployment Diagnostics for okusi3 ===${NOCOLOR}"
echo

# Test 1: SSH Connection
echo "${YELLOW}1. Testing SSH connection...${NOCOLOR}"
if ssh -o ConnectTimeout=5 "${DEPLOY_USER}@${DEPLOY_HOST}" "echo 'SSH connection successful'"; then
  echo "${GREEN}✓ SSH connection works${NOCOLOR}"
else
  echo "${RED}✗ SSH connection failed${NOCOLOR}"
  echo "Please check:"
  echo "  - SSH key is configured"
  echo "  - User '$DEPLOY_USER' exists on okusi3"
  echo "  - Network connectivity"
  exit 1
fi

# Test 2: Check remote paths
echo
echo "${YELLOW}2. Checking remote paths...${NOCOLOR}"
ssh "${DEPLOY_USER}@${DEPLOY_HOST}" << 'EOF'
  # Check web root
  if [[ -d "/var/www/vhosts/yatti.id/html" ]]; then
    echo "✓ Web root exists: /var/www/vhosts/yatti.id/html"
    ls -la /var/www/vhosts/yatti.id/html/ | head -5
  else
    echo "✗ Web root not found: /var/www/vhosts/yatti.id/html"
    echo "Searching for yatti.id directory..."
    find /var/www -name "*yatti*" -type d 2>/dev/null | head -10
    
    # Check alternative paths
    for path in /var/www/html /var/www/yatti.id /home/yatti/public_html; do
      if [[ -d "$path" ]]; then
        echo "Found alternative path: $path"
      fi
    done
  fi
  
  # Check v1 directory
  echo
  if [[ -d "/var/www/vhosts/yatti.id/html/v1" ]]; then
    echo "✓ v1 directory exists"
    ls -la /var/www/vhosts/yatti.id/html/v1/ | head -5
  else
    echo "✗ v1 directory not found"
    echo "Searching for v1 directory..."
    find /var/www -name "v1" -type d 2>/dev/null | grep -i yatti | head -5
  fi
  
  # Check current index.php
  echo
  if [[ -f "/var/www/vhosts/yatti.id/html/v1/index.php" ]]; then
    echo "✓ index.php exists"
    echo "File info:"
    ls -la /var/www/vhosts/yatti.id/html/v1/index.php
    echo "First few lines:"
    head -3 /var/www/vhosts/yatti.id/html/v1/index.php
  else
    echo "✗ index.php not found"
  fi
EOF

# Test 3: Check permissions
echo
echo "${YELLOW}3. Checking permissions...${NOCOLOR}"
ssh "${DEPLOY_USER}@${DEPLOY_HOST}" << 'EOF'
  # Check who we are
  echo "Current user: $(whoami)"
  echo "User groups: $(groups)"
  
  # Check web directory ownership
  echo
  echo "Web directory ownership:"
  stat -c "%U:%G %a %n" /var/www/vhosts/yatti.id/html 2>/dev/null || echo "Cannot stat web directory"
  
  # Check if we can write
  if touch /var/www/vhosts/yatti.id/html/v1/test_write_$$ 2>/dev/null; then
    echo "✓ Can write to v1 directory"
    rm -f /var/www/vhosts/yatti.id/html/v1/test_write_$$
  else
    echo "✗ Cannot write to v1 directory"
    echo "You may need to:"
    echo "  - Use sudo"
    echo "  - Change ownership: sudo chown -R www-data:www-data /var/www/vhosts/yatti.id/html/v1"
    echo "  - Adjust permissions: sudo chmod 755 /var/www/vhosts/yatti.id/html/v1"
  fi
EOF

# Test 4: Check web server
echo
echo "${YELLOW}4. Checking web server...${NOCOLOR}"
ssh "${DEPLOY_USER}@${DEPLOY_HOST}" << 'EOF'
  # Check Apache
  if systemctl is-active --quiet apache2; then
    echo "✓ Apache2 is running"
    # Check virtual host
    if [[ -f "/etc/apache2/sites-enabled/yatti.id.conf" ]]; then
      echo "✓ yatti.id virtual host found"
      grep -E "DocumentRoot|Directory" /etc/apache2/sites-enabled/yatti.id.conf | head -5
    fi
  elif systemctl is-active --quiet nginx; then
    echo "✓ Nginx is running"
    # Check nginx config
    if [[ -f "/etc/nginx/sites-enabled/yatti.id" ]]; then
      echo "✓ yatti.id site config found"
      grep root /etc/nginx/sites-enabled/yatti.id | head -2
    fi
  else
    echo "✗ No web server running?"
  fi
  
  # Check PHP
  echo
  if command -v php &> /dev/null; then
    echo "PHP version: $(php -v | head -1)"
  fi
EOF

# Test 5: Test current API
echo
echo "${YELLOW}5. Testing current API endpoints...${NOCOLOR}"
echo -n "Testing https://yatti.id/v1/help ... "
if curl -s -m 5 "https://yatti.id/v1/help" | grep -q "YaTTI"; then
  echo "${GREEN}Works${NOCOLOR}"
else
  echo "${RED}Failed${NOCOLOR}"
fi

echo -n "Testing https://yatti.id/v1/index.php/help ... "
if curl -s -m 5 "https://yatti.id/v1/index.php/help" | grep -q "YaTTI"; then
  echo "${GREEN}Works${NOCOLOR}"
else
  echo "${RED}Failed${NOCOLOR}"
fi

# Suggest fixes
echo
echo "${BLUE}=== Suggested Fixes ===${NOCOLOR}"
echo
echo "If Step 2 (deploying index.php) failed, try:"
echo
echo "1. Manual deployment with sudo:"
echo "   scp index.php ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/"
echo "   ssh ${DEPLOY_USER}@${DEPLOY_HOST} 'sudo cp /tmp/index.php /var/www/vhosts/yatti.id/html/v1/'"
echo
echo "2. Check the actual path:"
echo "   ssh ${DEPLOY_USER}@${DEPLOY_HOST} 'find /var/www -name index.php | grep -i yatti'"
echo
echo "3. Create v1 directory if missing:"
echo "   ssh ${DEPLOY_USER}@${DEPLOY_HOST} 'sudo mkdir -p /var/www/vhosts/yatti.id/html/v1'"
echo
echo "4. Fix permissions:"
echo "   ssh ${DEPLOY_USER}@${DEPLOY_HOST} 'sudo chown -R www-data:www-data /var/www/vhosts/yatti.id/html/v1'"

#fin