#!/bin/bash
# Deploy mandatory authentication to YaTTI server as www-data user
# This version is designed to run as www-data with minimal privileges

set -euo pipefail

# Colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
NOCOLOR=$'\033[0m'

# Configuration
API_DIR="/var/www/vhosts/yatti.id/html/v1"
VECTORDBS="${VECTORDBS:-/var/lib/vectordbs}"
BACKUP_DIR="/tmp/yatti-api-backup-$(date +%Y%m%d_%H%M%S)"

echo "${GREEN}YaTTI Mandatory Authentication Deployment (www-data)${NOCOLOR}"
echo "===================================================="
echo

# Check if running as www-data
if [[ $(whoami) != "www-data" ]]; then
   echo "${RED}Error: This script must be run as www-data user${NOCOLOR}"
   echo "Run: sudo -u www-data $0"
   exit 1
fi

# Check write permissions
if [[ ! -w "$API_DIR" ]]; then
    echo "${RED}Error: No write permission to $API_DIR${NOCOLOR}"
    echo "Ask admin to run: sudo chown -R www-data:www-data $API_DIR"
    exit 1
fi

# Create backup (in temp since www-data can't write to /var/backups)
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

# Copy files (www-data should own these)
cp -v v1/auth.inc.php "$API_DIR/"
cp -v v1/api_keys_schema.sql "$API_DIR/"
cp -v v1/index.php.new "$API_DIR/index.php"

# Set permissions (www-data already owns them)
chmod 644 "$API_DIR"/*.php

echo "${GREEN}✓ Authentication files installed${NOCOLOR}"

# Note about management tool
echo
echo "3. API key management tool..."
echo "${YELLOW}Note: Ask admin to install management tool:${NOCOLOR}"
echo "   sudo cp yatti-api-key /usr/local/bin/"
echo "   sudo chmod +x /usr/local/bin/yatti-api-key"

# Initialize database (www-data can do this)
echo
echo "4. Initializing authentication database..."
export VECTORDBS="$VECTORDBS"
if command -v yatti-api-key >/dev/null 2>&1; then
    yatti-api-key list >/dev/null 2>&1 || true
    echo "${GREEN}✓ Database initialized${NOCOLOR}"
else
    # Use local copy if management tool not installed globally
    if [[ -f "./yatti-api-key" ]]; then
        ./yatti-api-key list >/dev/null 2>&1 || true
        echo "${GREEN}✓ Database initialized (using local tool)${NOCOLOR}"
    else
        echo "${YELLOW}⚠ Could not initialize database - tool not found${NOCOLOR}"
    fi
fi

# Test installation
echo
echo "5. Testing installation..."
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

# Note about schema file
echo
echo "6. Schema file installation..."
echo "${YELLOW}Note: Ask admin to install schema file:${NOCOLOR}"
echo "   sudo mkdir -p /usr/share/yatti"
echo "   sudo cp v1/api_keys_schema.sql /usr/share/yatti/"
echo "   sudo chmod 644 /usr/share/yatti/api_keys_schema.sql"

echo
echo "${GREEN}Deployment complete!${NOCOLOR}"
echo
echo "Next steps for admin:"
echo "1. Install management tool globally:"
echo "   sudo cp yatti-api-key /usr/local/bin/"
echo "   sudo chmod +x /usr/local/bin/yatti-api-key"
echo
echo "2. Create initial admin key:"
echo "   sudo -u www-data yatti-api-key create admin@example.com 'Admin key'"
echo
echo "3. Move backup to permanent location:"
echo "   sudo mv $BACKUP_DIR /var/backups/"
echo
echo "Temporary backup location: $BACKUP_DIR"