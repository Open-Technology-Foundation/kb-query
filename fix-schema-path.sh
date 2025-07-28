#!/bin/bash
# Quick fix for schema file path issue

set -euo pipefail

# Colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
NOCOLOR=$'\033[0m'

echo "${YELLOW}Fixing schema file path issue...${NOCOLOR}"

# Create directory and copy schema file
sudo mkdir -p /usr/share/yatti
sudo cp v1/api_keys_schema.sql /usr/share/yatti/
sudo chmod 644 /usr/share/yatti/api_keys_schema.sql

echo "${GREEN}✓ Schema file installed to /usr/share/yatti/${NOCOLOR}"

# Update yatti-api-key script if it's installed
if [[ -f /usr/local/bin/yatti-api-key ]]; then
    echo "Updating installed yatti-api-key script..."
    sudo cp yatti-api-key /usr/local/bin/
    sudo chmod +x /usr/local/bin/yatti-api-key
    echo "${GREEN}✓ Management tool updated${NOCOLOR}"
fi

echo
echo "${GREEN}Fix complete!${NOCOLOR}"
echo
echo "You can now create API keys with:"
echo "  sudo -u www-data yatti-api-key create admin@yatti.id \"Admin API key\" \"YaTTI Admin\""