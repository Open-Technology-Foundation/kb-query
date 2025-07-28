# YaTTI API Key Authentication Setup Guide (Mandatory Authentication)

This guide explains how to set up and use the mandatory API key authentication system for YaTTI.

## Overview

The authentication system provides:
- **Mandatory** API key-based authentication for all knowledge base queries
- Public access only for `help` and `list` endpoints
- Per-key rate limiting
- Usage tracking and analytics
- Fine-grained permissions
- Knowledge base access control

## Installation

### 1. Server-Side Setup

#### A. Install Authentication Files

```bash
# Copy authentication files to the API directory
cp v1/auth.inc.php /var/www/vhosts/yatti.id/html/v1/
cp v1/api_keys_schema.sql /var/www/vhosts/yatti.id/html/v1/

# Replace the current index.php with the new mandatory auth version
cp v1/index.php.new /var/www/vhosts/yatti.id/html/v1/index.php

# Set proper permissions
chmod 644 /var/www/vhosts/yatti.id/html/v1/*.php
chown www-data:www-data /var/www/vhosts/yatti.id/html/v1/*.php
```

#### B. Install API Key Management Tool

```bash
# Copy the management tool
sudo cp yatti-api-key /usr/local/bin/
sudo chmod +x /usr/local/bin/yatti-api-key

# Initialize the authentication database
sudo -u www-data yatti-api-key list
```

#### C. Create Initial API Keys

```bash
# Create admin key for system management
sudo -u www-data yatti-api-key create admin@yatti.id "Admin API key" "YaTTI Admin"

# Create keys for existing users
sudo -u www-data yatti-api-key create user@example.com "User API key"
```

### 2. Client-Side Setup

Users MUST have an API key to access any knowledge base:

```bash
# Update kb-query to latest version
kb-query update

# Set API key in environment (required)
export YATTI_API_KEY="your-api-key-here"

# Or add to config file
echo 'YATTI_API_KEY="your-api-key-here"' >> ~/.config/kb-query/config
chmod 600 ~/.config/kb-query/config
```

## Public vs Authenticated Endpoints

### Public Endpoints (No API Key Required)
- `GET /v1/index.php/help` - API documentation
- `GET /v1/index.php/list` - List available knowledge bases
- `GET /v1/index.php/list.canonical` - List canonical knowledge bases
- `GET /v1/index.php/list.symlinks` - List symlinked knowledge bases
- `GET /v1/index.php/list.all` - List all knowledge bases

### Authenticated Endpoints (API Key Required)
- `GET /v1/index.php/{kb}/?q={query}` - Query a knowledge base
- `GET /v1/index.php/{kb}/config` - Get knowledge base configuration
- All other knowledge base operations

## Usage Examples

### Without Authentication (Public Endpoints)

```bash
# These work without an API key
curl https://yatti.id/v1/index.php/help
curl https://yatti.id/v1/index.php/list
```

### With Authentication (Required for KB Access)

```bash
# These REQUIRE an API key
export API_KEY="yatti_your_key_here"

# Using curl with Authorization header
curl -H "Authorization: Bearer $API_KEY" \
     "https://yatti.id/v1/index.php/appliedanthropology?q=What+is+dharma"

# Using kb-query (automatically uses YATTI_API_KEY)
export YATTI_API_KEY="$API_KEY"
kb-query appliedanthropology "What is dharma?"

# Will fail without API key
unset YATTI_API_KEY
kb-query appliedanthropology "What is dharma?"
# Error: Authentication failed - check your API key
```

## API Key Management

### Creating API Keys

```bash
# Create a new API key
yatti-api-key create user@example.com "Description" "Organization"

# The system will output:
# ✓ API Key created successfully!
# 
# API Key: yatti_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
# 
# ⚠ IMPORTANT: Save this key securely. It cannot be retrieved later.
```

### Managing Permissions

```bash
# Default permission is 'read' only
# Grant additional permissions as needed
yatti-api-key permissions yatti_012 "read,write"

# Restrict to specific knowledge bases
yatti-api-key allow-kb yatti_012 "appliedanthropology,garydean"

# Or allow all knowledge bases (default)
yatti-api-key allow-kb yatti_012 "all"
```

### Monitoring Usage

```bash
# View usage statistics
yatti-api-key stats yatti_012

# List all active keys
yatti-api-key list

# Check rate limit status (included in response headers)
curl -I -H "Authorization: Bearer $API_KEY" \
     "https://yatti.id/v1/index.php/appliedanthropology?q=test"
# Look for:
# X-RateLimit-Limit: 1000
# X-RateLimit-Remaining: 999
# X-RateLimit-Reset: 1635360000
```

## Error Messages

### Authentication Errors

1. **No API Key Provided**
   ```
   {"error":"No API key provided"}
   ```
   Solution: Set `YATTI_API_KEY` environment variable or use `--api-key` option

2. **Invalid API Key**
   ```
   {"error":"Invalid API key"}
   ```
   Solution: Check your API key format (should start with `yatti_`)

3. **API Key Revoked**
   ```
   {"error":"API key has been revoked"}
   ```
   Solution: Contact administrator for a new key

4. **Rate Limit Exceeded**
   ```
   {"error":"Rate limit exceeded. Try again later."}
   ```
   Solution: Wait for rate limit reset or request higher limit

5. **Insufficient Permissions**
   ```
   {"error":"Insufficient permissions"}
   ```
   Solution: Your key may be read-only or restricted

6. **KB Access Denied**
   ```
   {"error":"Access to knowledge base 'private-kb' is not allowed"}
   ```
   Solution: Your key doesn't have access to this KB

## Security Best Practices

1. **Protect Your API Keys**
   - Never share API keys
   - Never commit to version control
   - Use environment variables or secure config files
   - Rotate keys regularly

2. **Secure Storage**
   ```bash
   # For config files
   chmod 600 ~/.config/kb-query/config
   
   # For shell scripts
   # Use environment variables instead of hardcoding
   ```

3. **Key Rotation**
   ```bash
   # Create new key
   yatti-api-key create user@example.com "New key - $(date +%Y%m)"
   
   # Update your applications
   export YATTI_API_KEY="new_key_here"
   
   # Revoke old key
   yatti-api-key revoke yatti_old
   ```

## Migration Guide for Existing Users

### Before Migration
```bash
# This used to work without authentication
kb-query appliedanthropology "What is dharma?"
```

### After Migration
```bash
# Now requires API key
export YATTI_API_KEY="yatti_your_key_here"
kb-query appliedanthropology "What is dharma?"
```

### Quick Setup for Users
1. Contact administrator to get your API key
2. Add to your shell profile:
   ```bash
   echo 'export YATTI_API_KEY="yatti_your_key_here"' >> ~/.bashrc
   source ~/.bashrc
   ```
3. Or use config file:
   ```bash
   mkdir -p ~/.config/kb-query
   echo 'YATTI_API_KEY="yatti_your_key_here"' > ~/.config/kb-query/config
   chmod 600 ~/.config/kb-query/config
   ```

## Troubleshooting

### Debug Authentication Issues

```bash
# Enable debug mode to see authentication details
kb-query -d list 2>&1 | grep -i auth

# Test with curl to see raw response
curl -v -H "Authorization: Bearer $YATTI_API_KEY" \
     "https://yatti.id/v1/index.php/appliedanthropology?q=test"

# Check if API key is set
echo "API Key: ${YATTI_API_KEY:0:16}..."
```

### Common Issues

1. **"command not found: kb-query"**
   - Install kb-query: See installation instructions

2. **Works with curl but not kb-query**
   - Check YATTI_API_KEY is exported: `export YATTI_API_KEY="..."`
   - Update kb-query: `kb-query update`

3. **Intermittent failures**
   - Check rate limits: Look at X-RateLimit-Remaining header
   - Network issues: Test with `curl https://yatti.id/v1/index.php/help`

## API Response Headers

All authenticated responses include:

```
X-RateLimit-Limit: 1000        # Your hourly limit
X-RateLimit-Remaining: 999     # Requests remaining this hour
X-RateLimit-Reset: 1635360000  # Unix timestamp when limit resets
```

## Support

For API key issues or access requests:
1. Check public endpoints work: `curl https://yatti.id/v1/index.php/help`
2. Verify your API key is active: Contact administrator
3. Report issues with your key prefix (first 8 chars only)