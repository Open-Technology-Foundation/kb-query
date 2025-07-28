#!/bin/bash
# Deploy mandatory authentication to YaTTI server
# Run this on the server to enable authentication

set -euo pipefail

# Colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
NOCOLOR=$'\033[0m'

# Configuration
API_DIR="/var/www/vhosts/yatti.id/html/v1"
VECTORDBS="${VECTORDBS:-/var/lib/vectordbs}"
BACKUP_DIR="/var/backups/yatti-api/$(date +%Y%m%d_%H%M%S)"

echo "${GREEN}YaTTI Mandatory Authentication Deployment${NOCOLOR}"
echo "========================================="
echo

# Check if running as appropriate user
if [[ $EUID -eq 0 ]]; then
   echo "${YELLOW}Warning: Running as root. Consider running as www-data user.${NOCOLOR}"
fi

# Create backup
echo "1. Creating backup..."
mkdir -p "$BACKUP_DIR"
cp -a "$API_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
echo "   Backup created at: $BACKUP_DIR"

# Copy authentication files
echo
echo "2. Installing authentication files..."

# Check if files exist
if [[ ! -f "v1/auth.inc.php" ]]; then
    echo "${RED}Error: auth.inc.php not found. Run this from the kb-query directory.${NOCOLOR}"
    exit 1
fi

# Copy files
cp -v v1/auth.inc.php "$API_DIR/"
cp -v v1/api_keys_schema.sql "$API_DIR/"
cp -v v1/index.php.new "$API_DIR/index.php"

# Set permissions
chown www-data:www-data "$API_DIR"/*.php
chmod 644 "$API_DIR"/*.php

echo "${GREEN}✓ Authentication files installed${NOCOLOR}"

# Install management tool
echo
echo "3. Installing API key management tool..."
cp -v yatti-api-key /usr/local/bin/
chmod +x /usr/local/bin/yatti-api-key
echo "${GREEN}✓ Management tool installed${NOCOLOR}"

# Initialize database
echo
echo "4. Initializing authentication database..."
sudo -u www-data yatti-api-key list >/dev/null 2>&1 || true
echo "${GREEN}✓ Database initialized${NOCOLOR}"

# Create initial admin key
echo
echo "5. Creating initial admin API key..."
read -p "Enter admin email address: " admin_email
if [[ -n "$admin_email" ]]; then
    sudo -u www-data yatti-api-key create "$admin_email" "Admin API key - $(date +%Y-%m-%d)" "YaTTI Admin"
else
    echo "${YELLOW}Skipping admin key creation${NOCOLOR}"
fi

# Test installation
echo
echo "6. Testing installation..."
echo

# Test public endpoints
echo -n "Testing public endpoint (help)... "
if curl -s https://yatti.id/v1/help | grep -q "YaTTI Custom Knowledgebase"; then
    echo "${GREEN}✓ OK${NOCOLOR}"
else
    echo "${RED}✗ FAILED${NOCOLOR}"
fi

echo -n "Testing public endpoint (list)... "
if curl -s https://yatti.id/v1/list | jq -e '.response' >/dev/null 2>&1; then
    echo "${GREEN}✓ OK${NOCOLOR}"
else
    echo "${RED}✗ FAILED${NOCOLOR}"
fi

# Test authenticated endpoint
echo -n "Testing authenticated endpoint... "
if curl -s https://yatti.id/v1/appliedanthropology?q=test 2>&1 | grep -q "No API key provided"; then
    echo "${GREEN}✓ Authentication required (good!)${NOCOLOR}"
else
    echo "${YELLOW}⚠ Authentication may not be working${NOCOLOR}"
fi

echo
# Install schema file
echo
echo "7. Installing schema file..."
mkdir -p /usr/share/yatti
cp v1/api_keys_schema.sql /usr/share/yatti/
chmod 644 /usr/share/yatti/api_keys_schema.sql
echo "${GREEN}✓ Schema file installed${NOCOLOR}"

echo
echo "${GREEN}Deployment complete!${NOCOLOR}"
echo
echo "Next steps:"
echo "1. Test with a valid API key:"
echo "   export YATTI_API_KEY='your-key-here'"
echo "   kb-query appliedanthropology 'test query'"
echo
echo "2. Create API keys for users:"
echo "   yatti-api-key create user@example.com 'User description'"
echo
echo "3. Monitor usage:"
echo "   yatti-api-key stats yatti_prefix"
echo
echo "Backup location: $BACKUP_DIR"
echo
echo "To rollback:"
echo "  cp $BACKUP_DIR/* $API_DIR/"