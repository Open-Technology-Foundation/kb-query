# Configuration Guide

This guide covers all configuration options for YaTTI CustomKB components.

## Table of Contents

1. [KB-Query Configuration](#kb-query-configuration)
2. [CustomKB Configuration](#customkb-configuration)
3. [Build Pipeline Configuration](#build-pipeline-configuration)
4. [Environment Variables](#environment-variables)
5. [Security Best Practices](#security-best-practices)

## KB-Query Configuration

### Configuration File Locations

KB-Query checks these locations in order:
1. `~/.config/kb-query/config` (user-specific)
2. `/etc/kb-query/config` (system-wide)
3. Environment variables (highest priority)

### Configuration Format

```bash
# ~/.config/kb-query/config
# YaTTI KB-Query Configuration

# API Authentication
YATTI_API_KEY="yatti_your_api_key_here"

# API Settings
API_TIMEOUT=30                    # Request timeout in seconds
API_BASE_URL="https://yatti.id/v1"  # API endpoint

# Output Settings
OUTPUT_FORMAT="text"              # text, json, pretty
NO_COLOR=0                        # 1 to disable colors
QUIET_MODE=0                      # 1 for minimal output

# Query Defaults
DEFAULT_QUERY_MODEL="gpt-4o-mini"
DEFAULT_QUERY_TEMPERATURE=0.7
DEFAULT_QUERY_TOP_K=10
DEFAULT_QUERY_MAX_TOKENS=2000

# Cache Settings
CACHE_DIR="$HOME/.cache/kb-query"
CACHE_ENABLED=1
CACHE_TTL=3600                    # Cache TTL in seconds

# History Settings
HISTORY_FILE="$HOME/.local/share/kb-query/history"
HISTORY_ENABLED=1
HISTORY_MAX_SIZE=10000            # Max history entries

# Reference Settings
MAX_REFERENCE_SIZE=4000           # Max reference text size

# Advanced Settings
VECTORDBS="/var/lib/vectordbs"    # KB storage location
DEBUG=0                           # Enable debug output
VERBOSE=0                         # Enable verbose output
```

### Command-Line Override

All configuration options can be overridden via command line:

```bash
# Override API key
kb-query -k "yatti_different_key" list

# Override timeout
kb-query --timeout 60 appliedanthropology "complex query"

# Override output format
kb-query --format json okusiassociates "query" | jq .
```

## CustomKB Configuration

### Configuration File Structure

CustomKB uses INI-format configuration files:

```ini
# {knowledgebase}.cfg

[DEFAULT]
# Core settings
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
system_role = You are a helpful assistant.

# Model parameters
query_temperature = 0.7
query_max_tokens = 2000
query_top_k = 10
query_top_p = 1.0
query_frequency_penalty = 0.0
query_presence_penalty = 0.0

# Embedding settings
embedding_prefix = "search_document: "
embedding_batch_size = 50
chunk_size = 500
chunk_overlap = 50

[ALGORITHMS]
# Search algorithms
enable_hybrid_search = true
hybrid_search_weight = 0.7  # 0.7 = 70% vector, 30% keyword
similarity_threshold = 0.3
similarity_metric = cosine  # cosine, euclidean, inner_product

# Reranking
enable_reranking = false
reranking_model = cross-encoder/ms-marco-MiniLM-L-12-v2
reranking_top_k = 20
reranking_batch_size = 32

# BM25 settings
bm25_k1 = 1.2
bm25_b = 0.75
bm25_epsilon = 0.25

[PERFORMANCE]
# Processing performance
batch_size = 50
max_threads = 8
use_multiprocessing = true
chunk_cache_size = 1000

# GPU settings
use_gpu = true
gpu_device = 0  # CUDA device ID
gpu_memory_fraction = 0.8
gpu_batch_size = 100

# Index settings
index_type = flat  # flat, ivf_flat, ivf_pq, hnsw
index_nlist = 100  # For IVF indexes
index_nprobe = 10  # For IVF search
index_m = 32       # For HNSW
index_ef_construction = 200  # For HNSW
index_ef_search = 50        # For HNSW

[STORAGE]
# Database settings
db_path = {kb_name}.db
index_path = {kb_name}.index
cache_enabled = true
cache_size_mb = 100

# Logging
log_level = INFO
log_file = logs/{kb_name}.log
log_rotation = daily
log_retention_days = 30

[API_KEYS]
# API key settings (can use environment variables)
openai_api_key = ${OPENAI_API_KEY}
anthropic_api_key = ${ANTHROPIC_API_KEY}
google_api_key = ${GOOGLE_API_KEY}

[OPENAI]
# OpenAI-specific settings
organization = 
api_base = 
api_version = 
max_retries = 3
timeout = 30
request_timeout = 600

[ANTHROPIC]
# Anthropic-specific settings
max_retries = 3
timeout = 30

[GOOGLE]
# Google-specific settings
project_id = 
location = us-central1

[OLLAMA]
# Local model settings
base_url = http://localhost:11434
timeout = 120
keep_alive = 5m

[PROMPTS]
# Custom prompt templates
query_prompt_template = """
Based on the following context, please answer the question.

Context:
{context}

Question: {question}

Answer:"""

system_prompt = "You are an expert assistant with deep knowledge in this domain."

[FILTERS]
# Document filtering
file_extensions = .md,.txt,.pdf,.html,.htm,.json
exclude_patterns = *_test.*,*.tmp,*.log
min_chunk_length = 50
max_chunk_length = 2000

[EXPERIMENTAL]
# Experimental features
enable_semantic_chunking = false
enable_dynamic_batching = false
enable_query_expansion = false
query_expansion_model = 
enable_answer_validation = false
```

### Model-Specific Configurations

#### OpenAI Configuration
```ini
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini

[OPENAI]
api_key = ${OPENAI_API_KEY}
organization = org-xxxxxxxxxxxx
max_retries = 3
timeout = 30

# Model-specific parameters
embedding_dimensions = 1536  # For ada-002
max_tokens_per_request = 8191

# Rate limiting
requests_per_minute = 3000
tokens_per_minute = 1000000
```

#### Anthropic Configuration
```ini
[DEFAULT]
query_model = claude-3-haiku-20240307

[ANTHROPIC]
api_key = ${ANTHROPIC_API_KEY}
max_retries = 3
timeout = 30
anthropic_version = 2023-06-01

# Claude-specific settings
max_tokens = 4096
stop_sequences = ["\n\nHuman:", "\n\nAssistant:"]
```

#### Google Configuration
```ini
[DEFAULT]
vector_model = models/embedding-001
query_model = gemini-pro

[GOOGLE]
api_key = ${GOOGLE_API_KEY}
project_id = my-project-id
location = us-central1

# Gemini-specific settings
safety_settings = [
    {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
    {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"}
]
```

#### Local Models (Ollama)
```ini
[DEFAULT]
query_model = llama2:13b

[OLLAMA]
base_url = http://localhost:11434
timeout = 120
keep_alive = 5m

# Model loading
num_gpu = 1
num_thread = 8
```

### Performance Optimization Profiles

#### Conservative (Low Resource)
```ini
[PERFORMANCE]
batch_size = 10
max_threads = 2
use_gpu = false
chunk_cache_size = 100
index_type = flat

[ALGORITHMS]
enable_hybrid_search = false
enable_reranking = false
```

#### Balanced (Default)
```ini
[PERFORMANCE]
batch_size = 50
max_threads = 4
use_gpu = true
gpu_memory_fraction = 0.5
chunk_cache_size = 500
index_type = ivf_flat
index_nlist = 100

[ALGORITHMS]
enable_hybrid_search = true
hybrid_search_weight = 0.7
enable_reranking = false
```

#### Aggressive (High Performance)
```ini
[PERFORMANCE]
batch_size = 100
max_threads = 8
use_gpu = true
gpu_memory_fraction = 0.8
chunk_cache_size = 2000
index_type = hnsw
index_m = 48
index_ef_construction = 400

[ALGORITHMS]
enable_hybrid_search = true
hybrid_search_weight = 0.7
enable_reranking = true
reranking_top_k = 50
```

#### Maximum (Best Quality)
```ini
[DEFAULT]
vector_model = text-embedding-3-large
query_model = gpt-4

[PERFORMANCE]
batch_size = 200
max_threads = 16
use_gpu = true
gpu_memory_fraction = 0.9
chunk_cache_size = 5000
index_type = hnsw
index_m = 64
index_ef_construction = 500
index_ef_search = 200

[ALGORITHMS]
enable_hybrid_search = true
hybrid_search_weight = 0.6
enable_reranking = true
reranking_model = cross-encoder/ms-marco-TinyBERT-L-6
reranking_top_k = 100
similarity_threshold = 0.2
```

## Build Pipeline Configuration

### Build Configuration File

```bash
# {knowledgebase}.build.conf

# Build parameters
PARALLEL_JOBS=43                    # Number of parallel jobs
MAX_RETRIES=3                       # Max retries for failed operations
RETRY_DELAY=5                       # Delay between retries (seconds)

# Citation generation
ENABLE_CITATIONS=1                  # Enable citation generation
CITATION_MODEL="gpt-4o-mini"        # Model for citations
CITATION_BATCH_SIZE=10              # Citations per batch
CITATION_MAX_TOKENS=500             # Max tokens per citation

# Document processing
PRESERVE_ORIGINALS=1                # Keep original documents
PRESERVE_EMBED_DATA_TEXT=1          # Keep processed text cache
TEXT_PREPROCESSING=1                # Enable text preprocessing
LANGUAGE_DETECTION=1                # Auto-detect languages

# Validation
ENABLE_VALIDATION=1                 # Validate after each stage
MIN_CHUNK_LENGTH=50                 # Minimum valid chunk size
MAX_CHUNK_LENGTH=2000              # Maximum chunk size

# Testing
RUN_TESTS=1                        # Run tests after build
TEST_QUERIES=(                     # Test queries to validate
    "What is the main purpose?"
    "How does this work?"
    "What are the key features?"
)
TEST_MIN_SCORE=0.7                # Minimum acceptable score

# Paths
SOURCE_DIR="embed_data"            # Source documents directory
TEXT_CACHE_DIR="embed_data.text"   # Processed text cache
CITATIONS_DIR="citations"          # Citations output
LOGS_DIR="logs"                   # Build logs

# Stage control
SKIP_STAGES=""                    # Comma-separated stages to skip
FORCE_STAGES=""                   # Force re-run of stages
CHECKPOINT_INTERVAL=100           # Checkpoint every N operations

# Resource limits
MAX_MEMORY_GB=16                  # Maximum memory usage
MAX_DISK_GB=50                   # Maximum disk usage
TIMEOUT_MINUTES=120              # Overall build timeout

# Notifications (optional)
NOTIFY_EMAIL=""                  # Email for notifications
NOTIFY_WEBHOOK=""                # Webhook URL for status
```

### Stage-Specific Settings

```bash
# Stage 0: Text extraction
STAGE0_ENABLED=1
STAGE0_FILE_TYPES="md,txt,pdf,html,htm,json"
STAGE0_ENCODING="utf-8"
STAGE0_CLEAN_HTML=1

# Stage 1: Citation generation
STAGE1_ENABLED=1
STAGE1_PARALLEL=1
STAGE1_TIMEOUT=30

# Stage 2: Citation merging
STAGE2_ENABLED=1
STAGE2_VALIDATE=1

# Stage 3: Database import
STAGE3_ENABLED=1
STAGE3_CHUNK_SIZE=500
STAGE3_CHUNK_OVERLAP=50

# Stage 4: Embedding generation
STAGE4_ENABLED=1
STAGE4_BATCH_SIZE=100
STAGE4_USE_GPU=1

# Stage 5: Testing
STAGE5_ENABLED=1
STAGE5_NUM_TESTS=10
STAGE5_SAVE_RESULTS=1
```

## Environment Variables

### Required Variables

```bash
# API Keys (at least one required for CustomKB)
export OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxxxxxxxxxx"
export ANTHROPIC_API_KEY="sk-ant-xxxxxxxxxxxxxxxx"
export GOOGLE_API_KEY="AIzaxxxxxxxxxxxxxxxxxxxxx"

# YaTTI API (for kb-query)
export YATTI_API_KEY="yatti_xxxxxxxxxxxxxxxx"
```

### Optional Variables

```bash
# Paths
export VECTORDBS="/var/lib/vectordbs"        # KB storage location
export NLTK_DATA="$HOME/nltk_data"           # NLTK data directory
export CUDA_HOME="/usr/local/cuda"           # CUDA installation

# Logging
export LOG_LEVEL="INFO"                      # DEBUG, INFO, WARNING, ERROR
export LOG_FILE="/var/log/customkb.log"      # Log file location

# Performance
export OMP_NUM_THREADS=8                     # OpenMP threads
export MKL_NUM_THREADS=8                     # MKL threads
export CUDA_VISIBLE_DEVICES="0"              # GPU device selection

# Network
export HTTP_PROXY="http://proxy:8080"        # HTTP proxy
export HTTPS_PROXY="http://proxy:8080"       # HTTPS proxy
export NO_PROXY="localhost,127.0.0.1"        # Proxy exceptions

# Development
export CUSTOMKB_DEBUG=1                      # Enable debug mode
export CUSTOMKB_PROFILE=1                    # Enable profiling
export CUSTOMKB_TEST_MODE=1                  # Test mode (no API calls)
```

### Model-Specific Variables

```bash
# OpenAI
export OPENAI_API_KEY="sk-xxxxxxxx"
export OPENAI_ORG_ID="org-xxxxxxxx"
export OPENAI_API_BASE="https://api.openai.com/v1"

# Anthropic
export ANTHROPIC_API_KEY="sk-ant-xxxxxxxx"
export ANTHROPIC_API_URL="https://api.anthropic.com"

# Google
export GOOGLE_API_KEY="AIzaxxxxxxxx"
export GOOGLE_CLOUD_PROJECT="my-project"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/credentials.json"

# Ollama
export OLLAMA_HOST="http://localhost:11434"
export OLLAMA_KEEP_ALIVE="5m"
```

## Security Best Practices

### API Key Management

1. **Never commit API keys to version control**
   ```bash
   # .gitignore
   *.cfg
   .env
   *_api_key*
   ```

2. **Use environment variables for sensitive data**
   ```ini
   # Good - reference environment variable
   [DEFAULT]
   api_key = ${OPENAI_API_KEY}
   
   # Bad - hardcoded key
   [DEFAULT]
   api_key = sk-xxxxxxxxxxxxxxxx
   ```

3. **Restrict file permissions**
   ```bash
   # Configuration files
   chmod 600 ~/.config/kb-query/config
   chmod 600 /var/lib/vectordbs/*/[!.]*.cfg
   
   # API key files
   chmod 600 ~/.openai_api_key
   ```

4. **Use separate keys for environments**
   ```bash
   # Development
   export OPENAI_API_KEY="sk-dev-xxxxxxxx"
   
   # Production
   export OPENAI_API_KEY="sk-prod-xxxxxxxx"
   ```

### Directory Permissions

```bash
# Knowledgebase directories
chmod 750 /var/lib/vectordbs
chmod 750 /var/lib/vectordbs/*

# Log directories
chmod 755 /var/log/customkb
chmod 644 /var/log/customkb/*.log

# Cache directories
chmod 700 ~/.cache/kb-query
```

### Network Security

```ini
# Enforce HTTPS
[DEFAULT]
api_verify_ssl = true
api_ssl_ca_cert = /etc/ssl/certs/ca-certificates.crt

# Timeouts to prevent hanging
[OPENAI]
timeout = 30
max_retries = 3

# Rate limiting
[PERFORMANCE]
api_rate_limit = 60  # requests per minute
api_burst_limit = 10  # burst allowance
```

### Input Validation

```ini
[SECURITY]
# Query validation
max_query_length = 1000
allowed_characters = "a-zA-Z0-9 .,?!-'"
block_patterns = ["<script", "javascript:", "onclick"]

# File validation
allowed_extensions = .md,.txt,.pdf
max_file_size_mb = 100
scan_for_malware = true
```

## Configuration Examples

### Minimal Configuration
```ini
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
```

### Production Configuration
```ini
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
system_role = Professional assistant providing accurate information.

[ALGORITHMS]
enable_hybrid_search = true
hybrid_search_weight = 0.7
enable_reranking = true
similarity_threshold = 0.35

[PERFORMANCE]
batch_size = 100
use_gpu = true
gpu_memory_fraction = 0.7
index_type = hnsw

[STORAGE]
cache_enabled = true
log_level = INFO
log_rotation = daily

[SECURITY]
api_verify_ssl = true
max_query_length = 1000
```

### Development Configuration
```ini
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini

[PERFORMANCE]
batch_size = 10
use_gpu = false

[STORAGE]
log_level = DEBUG
cache_enabled = false

[EXPERIMENTAL]
enable_semantic_chunking = true
enable_query_expansion = true
```

## Validation and Testing

### Validate Configuration
```bash
# Check configuration syntax
customkb config myproject --validate

# Test configuration
customkb test-config myproject

# Dry run with configuration
customkb query myproject "test" --dry-run
```

### Configuration Debugging
```bash
# Show effective configuration
customkb config myproject --show-effective

# Show configuration sources
customkb config myproject --show-sources

# Explain configuration option
customkb config --explain query_temperature
```

## Migration Guide

### Upgrading from v0.7.x to v0.8.x
```bash
# Backup old configuration
cp myproject.cfg myproject.cfg.backup

# Update configuration format
customkb migrate-config myproject.cfg

# Verify migration
customkb config myproject --validate
```

### Common Migration Issues

1. **Deprecated options**
   - `enable_cross_encoder` → `enable_reranking`
   - `vector_dimension` → (auto-detected)
   - `chunk_method` → (removed, always token-based)

2. **New required options**
   - `similarity_metric` (default: cosine)
   - `embedding_prefix` (model-specific)

3. **Changed defaults**
   - `chunk_size`: 1000 → 500
   - `batch_size`: 32 → 50
   - `hybrid_search_weight`: 0.5 → 0.7

#fin