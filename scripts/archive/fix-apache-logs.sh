#!/bin/bash
# Fix critical Apache log file issue for yatti.id

set -euo pipefail

# Colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
NOCOLOR=$'\033[0m'

echo "${RED}CRITICAL: Fixing Apache log file issue for yatti.id${NOCOLOR}"
echo "============================================="

# Create log directory if it doesn't exist
echo "Creating log directory..."
ok3 -rd "mkdir -p /var/www/vhosts/yatti.id/logs"

# Create log files with proper permissions
echo "Creating log files..."
ok3 -rd "touch /var/www/vhosts/yatti.id/logs/error.log"
ok3 -rd "touch /var/www/vhosts/yatti.id/logs/access.log"
ok3 -rd "ln -s logs/error.log"
ok3 -rd "ln -s logs/access.log"

# Set proper ownership
echo "Setting ownership..."
ok3 -rd "chown -R www-data:www-data /var/www/vhosts/yatti.id/logs"
ok3 -rd "chown www-data:www-data /var/www/vhosts/yatti.id/error.log"
ok3 -rd "chown www-data:www-data /var/www/vhosts/yatti.id/access.log"

# Set proper permissions
echo "Setting permissions..."
ok3 -rd "chmod 644 /var/www/vhosts/yatti.id/logs/error.log"
ok3 -rd "chmod 644 /var/www/vhosts/yatti.id/logs/access.log"

# Also fix the vectordbs log permissions issue
echo
echo "Fixing vectordbs log permissions..."
ok3 -rd "mkdir -p /var/lib/vectordbs/appliedanthropology/logs"
ok3 -rd "chown -R www-data:www-data /var/lib/vectordbs/appliedanthropology/logs"
ok3 -rd "chmod -R 755 /var/lib/vectordbs/appliedanthropology/logs"

# Re-enable the site
echo
echo "Re-enabling yatti.id site..."
ok3 -rd "a2ensite yatti.id.conf"

# Test Apache configuration
echo
echo "Testing Apache configuration..."
ok3 -rd "apache2ctl configtest"

# Reload Apache
echo
echo "Reloading Apache..."
ok3 -rd "systemctl reload apache2"

echo
echo "${GREEN}Fix complete!${NOCOLOR}"
echo
echo "The critical issue has been resolved. yatti.id should now be accessible."
echo "You can verify with: curl -s https://yatti.id/v1/list"