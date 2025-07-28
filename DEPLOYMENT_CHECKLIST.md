# KB-Query Deployment Checklist for okusi3

## Pre-Deployment

- [ ] Current working directory: `/ai/scripts/kb-query`
- [ ] All tests pass locally: `cd tests && ./quick_test.sh`
- [ ] Deployment scripts are executable

## Deployment Steps

### 1. Deploy to okusi3
```bash
./deploy_to_okusi3.sh
```

This script will:
- Create backups of existing files
- Deploy updated `index.php` with v1/index.php URLs
- Deploy updated `kb-query` script
- Set proper permissions
- Run basic connectivity tests

### 2. SSH to okusi3 and Verify Installation
```bash
ssh okusi3

# Check kb-query is installed
which kb-query
kb-query --version

# Check index.php was updated
grep "v1/index.php" /var/www/vhosts/yatti.id/html/v1/index.php
```

### 3. Run Production Tests

From your local machine:
```bash
./test_production.sh
```

This will test:
- Public endpoints (help, list)
- URL structure is correct
- Authentication is required
- No double index.php in URLs

### 4. Test with API Key

```bash
# Set your API key
export YATTI_API_KEY="yatti_your_actual_key_here"

# Run authenticated tests
./test_production.sh

# Manual tests
kb-query appliedanthropology "What is dharma?"
kb-query okusiassociates "PMA requirements"
kb-query -c jakartapost "latest news"
```

### 5. Verify URL Structure

Check that all URLs now use v1/index.php:

```bash
# Check help text
kb-query help | grep "https://yatti.id"

# Check with curl
curl -s https://yatti.id/v1/index.php/help | grep "curl.*https://"
curl -s https://yatti.id/v1/index.php/list
```

### 6. Test All Knowledgebases

```bash
# List all KBs
kb-query list

# Test each one
for kb in $(kb-query list | jq -r '.[]'); do
  echo "Testing $kb..."
  kb-query "$kb" "test query" | head -1
done
```

## Verification Checklist

### Public Endpoints
- [ ] `https://yatti.id/v1/index.php/help` returns help text
- [ ] `https://yatti.id/v1/index.php/list` returns KB list
- [ ] Help text shows correct v1/index.php URLs
- [ ] No "404 Not Found" errors

### Authentication
- [ ] Queries without API key return "No API key provided"
- [ ] Invalid API key returns "Invalid API key"
- [ ] Valid API key allows queries

### KB-Query CLI
- [ ] `kb-query help` works
- [ ] `kb-query list` works
- [ ] `kb-query [kb] "query"` works with API key
- [ ] No double index.php in constructed URLs

### URL Structure
- [ ] All examples show `https://yatti.id/v1/index.php/`
- [ ] No references to old `/v1/` URLs without index.php
- [ ] Debug output shows correct BASEURL

### Performance
- [ ] Response times < 2 seconds
- [ ] No timeout errors
- [ ] All knowledgebases accessible

## Rollback Procedure

If something goes wrong:

```bash
# On okusi3
cd /var/www/vhosts/yatti.id/html
tar -xzf /var/backups/kb-query/v1_backup_[TIMESTAMP].tar.gz

# Restore kb-query script
cp /var/backups/kb-query/kb-query_backup_[TIMESTAMP] /usr/local/bin/kb-query
chmod +x /usr/local/bin/kb-query
```

## Common Issues

### 1. "404 Not Found" errors
- Check Apache/Nginx routing for v1/index.php
- Verify .htaccess rules if using Apache

### 2. Help text still shows old URLs
- Clear PHP opcache: `cachetool opcache:reset`
- Reload PHP-FPM: `systemctl reload php8.3-fpm`

### 3. Authentication not working
- Verify auth.inc.php is present and readable
- Check database connection for API keys

### 4. kb-query not found
- Check PATH includes /usr/local/bin
- Verify kb-query has execute permissions

## Success Criteria

Deployment is successful when:
1. ✅ All public endpoints respond correctly
2. ✅ Authentication works as expected
3. ✅ All URLs use v1/index.php structure
4. ✅ All knowledgebases are queryable
5. ✅ No error messages in logs
6. ✅ Performance is acceptable (< 2s response)

## Post-Deployment

1. Monitor error logs:
   ```bash
   tail -f /var/log/apache2/error.log
   tail -f /var/log/php*.log
   ```

2. Update documentation if needed

3. Notify team of deployment completion

#fin