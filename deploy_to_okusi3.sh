#!/bin/bash
# Deploy kb-query updates to okusi3 production server
# This script deploys the updated kb-query with v1/index.php URL structure

set -euo pipefail

# Colors for output
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly NOCOLOR=$'\033[0m'

# Configuration
readonly DEPLOY_HOST="okusi3"
readonly DEPLOY_USER="root"  # Adjust if different
readonly REMOTE_PATH="/var/www/vhosts/yatti.id/html"
readonly BACKUP_DIR="/var/backups/kb-query"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "${BLUE}=== KB-Query Deployment to okusi3 ===${NOCOLOR}"
echo "Timestamp: $TIMESTAMP"
echo

# Step 1: Create backup on remote server
echo "${YELLOW}Step 1: Creating backup on okusi3...${NOCOLOR}"
ssh "${DEPLOY_USER}@${DEPLOY_HOST}" << EOF
  # Create backup directory
  mkdir -p "$BACKUP_DIR"
  
  # Backup current v1 directory
  if [[ -d "$REMOTE_PATH/v1" ]]; then
    echo "Backing up current v1 directory..."
    tar -czf "$BACKUP_DIR/v1_backup_$TIMESTAMP.tar.gz" -C "$REMOTE_PATH" v1/
    echo "Backup created: $BACKUP_DIR/v1_backup_$TIMESTAMP.tar.gz"
  else
    echo "No existing v1 directory to backup"
  fi
  
  # Backup kb-query if it exists in /usr/local/bin
  if [[ -f "/usr/local/bin/kb-query" ]]; then
    cp /usr/local/bin/kb-query "$BACKUP_DIR/kb-query_backup_$TIMESTAMP"
    echo "Backed up kb-query script"
  fi
EOF

# Step 2: Deploy updated index.php
echo
echo "${YELLOW}Step 2: Deploying updated index.php...${NOCOLOR}"
scp index.php "${DEPLOY_USER}@${DEPLOY_HOST}:$REMOTE_PATH/v1/index.php"
echo "${GREEN}✓ index.php deployed${NOCOLOR}"

# Step 3: Deploy kb-query script
echo
echo "${YELLOW}Step 3: Deploying kb-query script...${NOCOLOR}"
scp kb-query "${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/kb-query"
ssh "${DEPLOY_USER}@${DEPLOY_HOST}" << EOF
  # Install kb-query
  chmod +x /tmp/kb-query
  mv /tmp/kb-query /usr/local/bin/kb-query
  echo "kb-query installed to /usr/local/bin/"
  
  # Verify installation
  kb-query --version || echo "Warning: kb-query version check failed"
EOF
echo "${GREEN}✓ kb-query deployed${NOCOLOR}"

# Step 4: Deploy configuration example
echo
echo "${YELLOW}Step 4: Deploying configuration files...${NOCOLOR}"
scp kb-query-config.example "${DEPLOY_USER}@${DEPLOY_HOST}:/usr/share/kb-query/kb-query-config.example" || true
echo "${GREEN}✓ Configuration example deployed${NOCOLOR}"

# Step 5: Set permissions
echo
echo "${YELLOW}Step 5: Setting permissions...${NOCOLOR}"
ssh "${DEPLOY_USER}@${DEPLOY_HOST}" << EOF
  # Set proper permissions for web files
  chown www-data:www-data "$REMOTE_PATH/v1/index.php"
  chmod 644 "$REMOTE_PATH/v1/index.php"
  
  # Ensure kb-query is executable
  chmod 755 /usr/local/bin/kb-query
  
  echo "Permissions set"
EOF

# Step 6: Test deployment
echo
echo "${YELLOW}Step 6: Running deployment tests...${NOCOLOR}"

# Test 1: Check if help endpoint works
echo -n "Testing help endpoint... "
if curl -s "https://yatti.id/v1/index.php/help" | grep -q "YaTTI Custom Knowledgebase"; then
  echo "${GREEN}PASS${NOCOLOR}"
else
  echo "${RED}FAIL${NOCOLOR}"
  echo "Help endpoint not responding correctly"
fi

# Test 2: Check if list endpoint works
echo -n "Testing list endpoint... "
if curl -s "https://yatti.id/v1/index.php/list" | grep -q "appliedanthropology"; then
  echo "${GREEN}PASS${NOCOLOR}"
else
  echo "${RED}FAIL${NOCOLOR}"
  echo "List endpoint not responding correctly"
fi

# Test 3: Test authentication requirement
echo -n "Testing authentication requirement... "
response=$(curl -s "https://yatti.id/v1/index.php/appliedanthropology?q=test" | jq -r '.error' 2>/dev/null || echo "")
if [[ "$response" == "No API key provided" ]]; then
  echo "${GREEN}PASS${NOCOLOR}"
else
  echo "${RED}FAIL${NOCOLOR}"
  echo "Authentication not working correctly"
fi

# Step 7: Clear any caches
echo
echo "${YELLOW}Step 7: Clearing caches...${NOCOLOR}"
ssh "${DEPLOY_USER}@${DEPLOY_HOST}" << EOF
  # Clear PHP opcache if available
  if command -v cachetool &> /dev/null; then
    cachetool opcache:reset
    echo "PHP opcache cleared"
  fi
  
  # Restart PHP-FPM if it exists
  if systemctl is-active --quiet php8.3-fpm; then
    systemctl reload php8.3-fpm
    echo "PHP-FPM reloaded"
  elif systemctl is-active --quiet php7.4-fpm; then
    systemctl reload php7.4-fpm
    echo "PHP-FPM reloaded"
  fi
  
  # Clear any application caches
  rm -rf /tmp/kb-query-cache* 2>/dev/null || true
EOF

echo
echo "${BLUE}=== Deployment Complete ===${NOCOLOR}"
echo
echo "Next steps:"
echo "1. Test with a valid API key:"
echo "   export YATTI_API_KEY='your_key_here'"
echo "   kb-query appliedanthropology 'What is dharma?'"
echo
echo "2. Verify help text shows correct URLs:"
echo "   kb-query help | grep 'v1/index.php'"
echo
echo "3. Run integration tests:"
echo "   cd tests && ./test_integration.sh"
echo
echo "Rollback command (if needed):"
echo "   ssh ${DEPLOY_USER}@${DEPLOY_HOST} 'cd $REMOTE_PATH && tar -xzf $BACKUP_DIR/v1_backup_$TIMESTAMP.tar.gz'"

#fin