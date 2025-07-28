# Troubleshooting Guide

This guide helps resolve common issues with YaTTI CustomKB components.

## Table of Contents

1. [KB-Query Issues](#kb-query-issues)
2. [CustomKB Issues](#customkb-issues)
3. [API Issues](#api-issues)
4. [Performance Issues](#performance-issues)
5. [Installation Issues](#installation-issues)
6. [Debugging Tools](#debugging-tools)

## KB-Query Issues

### Authentication Errors

#### Problem: "Authentication required. Please set YATTI_API_KEY"
```bash
Error: Authentication required. Please set YATTI_API_KEY or use -k option
```

**Solutions:**
1. Set environment variable:
   ```bash
   export YATTI_API_KEY="yatti_your_api_key_here"
   ```

2. Use configuration file:
   ```bash
   mkdir -p ~/.config/kb-query
   echo 'YATTI_API_KEY="yatti_your_api_key_here"' > ~/.config/kb-query/config
   chmod 600 ~/.config/kb-query/config
   ```

3. Pass directly:
   ```bash
   kb-query -k "yatti_your_api_key_here" list
   ```

#### Problem: "Invalid API key"
```bash
Error: Invalid API key. Please check your credentials.
```

**Solutions:**
- Verify key format (should start with `yatti_`)
- Check for extra spaces or quotes
- Confirm key hasn't expired
- Test with curl:
  ```bash
  curl -H "Authorization: Bearer $YATTI_API_KEY" https://yatti.id/v1/list
  ```

### Query Errors

#### Problem: "Knowledgebase not found"
```bash
Error: Knowledgebase 'myproject' not found
```

**Solutions:**
1. List available knowledgebases:
   ```bash
   kb-query list
   ```

2. Check spelling and case (knowledgebase names are case-sensitive)

3. Verify API endpoint:
   ```bash
   curl -s "https://yatti.id/v1/list" | jq -r '.knowledgebases[].name'
   ```

#### Problem: "Request timeout"
```bash
Error: Request timed out after 30 seconds
```

**Solutions:**
1. Increase timeout:
   ```bash
   kb-query --timeout 60 okusiassociates "complex query"
   ```

2. Simplify query or reduce context:
   ```bash
   kb-query -K 10 okusiassociates "query"  # Fewer chunks
   ```

3. Check network connectivity:
   ```bash
   curl -I https://yatti.id/v1/help
   ```

### Output Issues

#### Problem: "jq: command not found"
```bash
kb-query: line 185: jq: command not found
```

**Solution:**
```bash
sudo apt install jq
```

#### Problem: "urlencode: command not found"
```bash
kb-query: line 142: urlencode: command not found
```

**Solution:**
```bash
sudo apt install gridsite-clients
```

#### Problem: Garbled or no output

**Solutions:**
1. Check output format:
   ```bash
   kb-query --format json appliedanthropology "test" | jq .
   ```

2. Disable colors:
   ```bash
   kb-query --no-color list
   ```

3. Use raw output:
   ```bash
   kb-query --raw appliedanthropology "test"
   ```

## CustomKB Issues

### Embedding Generation Errors

#### Problem: "OpenAI API key not found"
```bash
Error: OpenAI API key not found. Please set OPENAI_API_KEY environment variable.
```

**Solutions:**
1. Set API key:
   ```bash
   export OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxx"
   ```

2. Check configuration:
   ```bash
   customkb config myproject | grep api_key
   ```

#### Problem: "Rate limit exceeded"
```bash
Error: Rate limit exceeded. Please try again in 20 seconds.
```

**Solutions:**
1. Reduce batch size:
   ```bash
   customkb embed myproject --batch-size 25
   ```

2. Add delay between batches:
   ```bash
   customkb config myproject --set "api_retry_delay=2"
   ```

3. Use different API key or upgrade tier

#### Problem: "Embedding dimension mismatch"
```bash
Error: Embedding dimension mismatch. Expected 1536, got 3072.
```

**Solutions:**
1. Check model consistency:
   ```bash
   customkb config myproject | grep vector_model
   ```

2. Regenerate all embeddings:
   ```bash
   customkb embed myproject --force
   ```

3. Clear index and rebuild:
   ```bash
   rm myproject.index
   customkb embed myproject
   ```

### Database Errors

#### Problem: "Database locked"
```bash
Error: database is locked
```

**Solutions:**
1. Wait for other operations to complete
2. Check for stuck processes:
   ```bash
   ps aux | grep customkb
   ```
3. Remove lock file (if safe):
   ```bash
   rm /var/lib/vectordbs/myproject/.lock
   ```

#### Problem: "No such table: documents"
```bash
Error: no such table: documents
```

**Solutions:**
1. Initialize database:
   ```bash
   customkb database myproject --init
   ```

2. Repair database:
   ```bash
   customkb repair myproject
   ```

### Memory Errors

#### Problem: "Out of memory"
```bash
Error: RuntimeError: CUDA out of memory
```

**Solutions:**
1. Reduce batch size:
   ```bash
   customkb embed myproject --batch-size 10
   ```

2. Disable GPU:
   ```bash
   customkb config myproject --set "use_gpu=false"
   ```

3. Clear GPU cache:
   ```python
   python -c "import torch; torch.cuda.empty_cache()"
   ```

4. Use CPU-only version:
   ```bash
   pip install faiss-cpu
   ```

#### Problem: "Killed" (OOM killer)
```bash
Killed
```

**Solutions:**
1. Check system memory:
   ```bash
   free -h
   dmesg | grep -i "killed process"
   ```

2. Limit memory usage:
   ```bash
   customkb optimize myproject --memory-limit 4
   ```

3. Process in smaller batches:
   ```bash
   # Split documents
   customkb database myproject docs/part1/*.md
   customkb database myproject docs/part2/*.md
   ```

### Search Issues

#### Problem: "No results found"
```bash
No relevant context found for your query.
```

**Solutions:**
1. Lower similarity threshold:
   ```bash
   customkb config myproject --set "similarity_threshold=0.2"
   ```

2. Increase top-k:
   ```bash
   customkb query myproject "question" --top-k 50
   ```

3. Enable hybrid search:
   ```bash
   customkb config myproject --set "enable_hybrid_search=true"
   customkb bm25 myproject
   ```

4. Check if documents were properly indexed:
   ```bash
   customkb verify myproject
   ```

## API Issues

### Connection Errors

#### Problem: "Connection refused"
```bash
Error: Failed to establish a new connection: [Errno 111] Connection refused
```

**Solutions:**
1. Check API status:
   ```bash
   curl -I https://yatti.id/v1/help
   ```

2. Check proxy settings:
   ```bash
   unset HTTP_PROXY HTTPS_PROXY
   # Or configure correctly:
   export HTTPS_PROXY="http://proxy:8080"
   ```

3. Check DNS:
   ```bash
   nslookup yatti.id
   ```

#### Problem: "SSL certificate verification failed"
```bash
Error: SSL: CERTIFICATE_VERIFY_FAILED
```

**Solutions:**
1. Update certificates:
   ```bash
   sudo apt update && sudo apt install ca-certificates
   ```

2. For testing only (not recommended):
   ```bash
   export CURL_CA_BUNDLE=""
   ```

### Response Errors

#### Problem: "500 Internal Server Error"
```json
{
  "error": {
    "code": "SERVER_ERROR",
    "message": "Internal server error"
  }
}
```

**Solutions:**
1. Retry request after a delay
2. Check if query contains special characters
3. Reduce query complexity
4. Contact support if persistent

#### Problem: "503 Service Unavailable"
```json
{
  "error": {
    "code": "KB_UNAVAILABLE",
    "message": "Knowledgebase temporarily unavailable"
  }
}
```

**Solutions:**
1. Wait and retry (knowledgebase may be updating)
2. Check API status page
3. Try different knowledgebase

## Performance Issues

### Slow Queries

#### Problem: Queries taking too long

**Diagnosis:**
```bash
# Time the query
time kb-query appliedanthropology "test query"

# Profile with customkb
customkb query myproject "test" --profile
```

**Solutions:**
1. Reduce context chunks:
   ```bash
   kb-query -K 10 appliedanthropology "query"
   ```

2. Use faster model:
   ```bash
   kb-query -m gpt-3.5-turbo appliedanthropology "query"
   ```

3. Enable caching:
   ```bash
   echo "CACHE_ENABLED=1" >> ~/.config/kb-query/config
   ```

4. Optimize knowledgebase:
   ```bash
   customkb optimize myproject
   ```

### Slow Embedding Generation

#### Problem: Embedding generation takes hours

**Solutions:**
1. Enable GPU:
   ```bash
   customkb config myproject --set "use_gpu=true"
   ```

2. Increase batch size:
   ```bash
   customkb embed myproject --batch-size 100
   ```

3. Use parallel processing:
   ```bash
   customkb embed myproject --parallel --num-workers 4
   ```

4. Monitor progress:
   ```bash
   customkb embed myproject --show-progress
   ```

### High Memory Usage

#### Problem: System becomes unresponsive

**Solutions:**
1. Monitor memory:
   ```bash
   watch -n 1 free -h
   ```

2. Limit memory:
   ```bash
   ulimit -v 8000000  # 8GB limit
   customkb embed myproject
   ```

3. Use disk-based index:
   ```bash
   customkb config myproject --set "index_type=ivf_flat"
   ```

## Installation Issues

### Dependency Problems

#### Problem: "No module named 'openai'"
```bash
ModuleNotFoundError: No module named 'openai'
```

**Solutions:**
1. Activate virtual environment:
   ```bash
   source /path/to/customkb/.venv/bin/activate
   ```

2. Install requirements:
   ```bash
   pip install -r requirements.txt
   ```

3. Verify installation:
   ```bash
   pip list | grep openai
   ```

#### Problem: "NLTK data not found"
```bash
LookupError: Resource punkt not found.
```

**Solutions:**
1. Run setup script:
   ```bash
   sudo ./setup/nltk_setup.py download cleanup
   ```

2. Set NLTK data path:
   ```bash
   export NLTK_DATA="$HOME/nltk_data"
   ```

### Permission Issues

#### Problem: "Permission denied"
```bash
PermissionError: [Errno 13] Permission denied: '/var/lib/vectordbs'
```

**Solutions:**
1. Check ownership:
   ```bash
   ls -la /var/lib/vectordbs
   ```

2. Fix permissions:
   ```bash
   sudo chown -R $USER:$USER /var/lib/vectordbs
   chmod -R 755 /var/lib/vectordbs
   ```

3. Use different location:
   ```bash
   export VECTORDBS="$HOME/vectordbs"
   mkdir -p $VECTORDBS
   ```

## Debugging Tools

### Enable Debug Mode

#### KB-Query
```bash
# Debug mode
kb-query -D appliedanthropology "test"

# Verbose output
kb-query -v list

# Show request details
kb-query --show-request appliedanthropology "test"
```

#### CustomKB
```bash
# Debug logging
customkb --debug query myproject "test"

# Verbose output
customkb -vvv embed myproject

# Dry run
customkb embed myproject --dry-run
```

### Check Logs

```bash
# KB-Query logs
tail -f ~/.cache/kb-query/kb-query.log

# CustomKB logs
tail -f /var/lib/vectordbs/myproject/logs/customkb.log

# System logs
journalctl -u customkb -f
dmesg | tail -20
```

### Test Components

```bash
# Test configuration
customkb test-config myproject

# Test database connection
customkb test-db myproject

# Test embeddings
customkb test-embed myproject "sample text"

# Test search
customkb test-search myproject "test query"

# Full diagnostic
customkb diagnose myproject
```

### Network Diagnostics

```bash
# Test API connectivity
curl -v https://yatti.id/v1/help

# Check DNS
dig yatti.id

# Trace route
traceroute yatti.id

# Test with different tools
wget --debug https://yatti.id/v1/list
```

### System Diagnostics

```bash
# Check Python version
python --version

# Check CUDA
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"

# Check memory
free -h
vmstat 1

# Check disk space
df -h /var/lib/vectordbs

# Check open files
lsof | grep customkb
```

## Getting Help

### Collect Diagnostic Information

```bash
# Create diagnostic bundle
customkb diagnose myproject --bundle > diagnostic.txt

# System information
uname -a >> diagnostic.txt
python --version >> diagnostic.txt
pip list >> diagnostic.txt

# Configuration
customkb config myproject >> diagnostic.txt

# Recent logs
tail -n 100 /var/lib/vectordbs/myproject/logs/customkb.log >> diagnostic.txt
```

### Report Issues

1. GitHub Issues: https://github.com/Open-Technology-Foundation/kb-query/issues
2. Include:
   - Error message and stack trace
   - Steps to reproduce
   - System information
   - Configuration (sanitize API keys)
   - Diagnostic bundle

### Community Support

- Check existing issues first
- Provide minimal reproducible example
- Be specific about versions and environment
- Follow up with additional information if requested

#fin