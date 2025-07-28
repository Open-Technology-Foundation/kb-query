# CustomKB Usage Guide

## Overview

CustomKB is a powerful Python-based tool for building and managing AI-powered vector databases. It processes documents, generates embeddings, and enables intelligent querying through various language models.

## Installation

### Prerequisites

- Ubuntu 24.04 LTS
- Python 3.12+
- 4GB+ RAM (8GB+ recommended for large datasets)
- NVIDIA GPU with CUDA support (optional, for acceleration)

### Setup

```bash
# Clone repository
git clone https://github.com/Open-Technology-Foundation/kb-query.git
cd kb-query/customkb

# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Setup NLTK data
sudo ./setup/nltk_setup.py download cleanup

# Set environment variables
export OPENAI_API_KEY="your-openai-api-key"
export VECTORDBS="/var/lib/vectordbs"
export NLTK_DATA="$HOME/nltk_data"
```

### GPU Setup (Optional)

For NVIDIA GPU acceleration:
```bash
# Install CUDA dependencies
pip install faiss-gpu-cu12

# Verify GPU availability
python -c "import torch; print(torch.cuda.is_available())"
```

## Command Structure

```bash
customkb [global-options] {command} {kb-name} [command-options]
```

### Global Options

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Enable verbose output |
| `-d, --debug` | Enable debug mode |
| `--log-level LEVEL` | Set log level (DEBUG/INFO/WARNING/ERROR) |
| `--config FILE` | Use custom config file |
| `-h, --help` | Show help |

## Core Commands

### 1. Database Management

#### Create/Update Database
```bash
customkb database {kb-name} [files...]
```

Examples:
```bash
# Create database from documents
customkb database myproject documents/*.md

# Add documents to existing database
customkb database myproject new_doc.md

# Process entire directory
customkb database myproject documents/
```

Options:
- `--chunk-size`: Token size for chunks (default: 500)
- `--chunk-overlap`: Overlap between chunks (default: 50)
- `--encoding`: Text encoding (default: utf-8)
- `--language`: Document language for processing

#### List Documents
```bash
customkb list {kb-name}
```

#### Remove Documents
```bash
customkb remove {kb-name} --doc-id {id}
```

### 2. Embedding Generation

#### Generate Embeddings
```bash
customkb embed {kb-name}
```

Options:
- `--model`: Embedding model (default: from config)
- `--batch-size`: Batch size for processing (default: 50)
- `--force`: Force regeneration of all embeddings
- `--resume`: Resume from last checkpoint

Examples:
```bash
# Basic embedding generation
customkb embed myproject

# With specific model
customkb embed myproject --model text-embedding-3-small

# Force regeneration
customkb embed myproject --force

# Large dataset with custom batch size
customkb embed largekb --batch-size 100 --resume
```

### 3. Querying

#### Query Knowledgebase
```bash
customkb query {kb-name} "{question}"
```

Options:
- `--model`: LLM model for response
- `--temperature`: Response creativity (0-1)
- `--top-k`: Number of context chunks
- `--context-only`: Return context without LLM
- `--format`: Output format (text/json/xml/markdown)

Examples:
```bash
# Simple query
customkb query myproject "What is the main topic?"

# Advanced query with options
customkb query myproject "Explain the process" \
  --model gpt-4 \
  --temperature 0.3 \
  --top-k 20

# Context-only retrieval
customkb query myproject "Find information about X" --context-only

# JSON output
customkb query myproject "Summary of features" --format json
```

### 4. Search Enhancement

#### Build BM25 Index
```bash
customkb bm25 {kb-name}
```

Enables hybrid search combining vector similarity and keyword matching.

Options:
- `--rebuild`: Force rebuild of BM25 index
- `--k1`: BM25 k1 parameter (default: 1.2)
- `--b`: BM25 b parameter (default: 0.75)

#### Rerank Results
```bash
customkb rerank {kb-name}
```

Enables cross-encoder reranking for improved accuracy.

Options:
- `--model`: Reranking model
- `--test`: Test reranking with sample query

### 5. Configuration Management

#### Edit Configuration
```bash
customkb edit {kb-name}
```

Opens configuration in default editor.

#### Show Configuration
```bash
customkb config {kb-name}
```

#### Set Configuration Value
```bash
customkb config {kb-name} --set "key=value"
```

Examples:
```bash
# View current config
customkb config myproject

# Set specific value
customkb config myproject --set "query_model=gpt-4"

# Set multiple values
customkb config myproject \
  --set "vector_model=text-embedding-3-large" \
  --set "query_temperature=0.3"
```

### 6. Optimization

#### Analyze Performance
```bash
customkb optimize {kb-name} --analyze
```

#### Apply Optimizations
```bash
customkb optimize {kb-name}
```

Options:
- `--tier`: Optimization tier (conservative/balanced/aggressive/max)
- `--gpu`: Enable GPU optimizations
- `--memory-limit`: Memory limit in GB

Examples:
```bash
# Analyze current performance
customkb optimize myproject --analyze

# Apply balanced optimizations
customkb optimize myproject --tier balanced

# Aggressive optimization with GPU
customkb optimize myproject --tier aggressive --gpu
```

### 7. Maintenance

#### Verify Database
```bash
customkb verify {kb-name}
```

Checks database integrity and indexes.

#### Verify Indexes
```bash
customkb verify-indexes {kb-name}
```

#### Cleanup
```bash
customkb cleanup {kb-name}
```

Removes temporary files and optimizes storage.

#### Export/Import
```bash
# Export knowledgebase
customkb export {kb-name} --output {file}

# Import knowledgebase
customkb import {kb-name} --input {file}
```

## Configuration Files

### Basic Configuration

```ini
[DEFAULT]
# Embedding model
vector_model = text-embedding-3-small
embedding_prefix = "search_document: "

# Query model
query_model = gpt-4o-mini
query_temperature = 0.7
query_max_tokens = 2000
query_top_k = 10

# System behavior
system_role = "You are a helpful assistant with expertise in this knowledge domain."

[ALGORITHMS]
# Search configuration
enable_hybrid_search = true
hybrid_search_weight = 0.7
similarity_threshold = 0.3

# Reranking
enable_reranking = false
reranking_model = cross-encoder/ms-marco-MiniLM-L-12-v2
reranking_top_k = 20

[PERFORMANCE]
# Processing settings
batch_size = 50
max_threads = 8
chunk_cache_size = 1000

# GPU settings
use_gpu = true
gpu_memory_fraction = 0.8
```

### Model-Specific Configurations

#### OpenAI Models
```ini
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini

[OPENAI]
api_key = ${OPENAI_API_KEY}
organization = org-xxxxx
max_retries = 3
timeout = 30
```

#### Anthropic Models
```ini
[DEFAULT]
query_model = claude-3-haiku-20240307

[ANTHROPIC]
api_key = ${ANTHROPIC_API_KEY}
max_retries = 3
```

#### Google Models
```ini
[DEFAULT]
vector_model = models/embedding-001
query_model = gemini-pro

[GOOGLE]
api_key = ${GOOGLE_API_KEY}
```

#### Local Models (Ollama)
```ini
[DEFAULT]
query_model = llama2:13b

[OLLAMA]
base_url = http://localhost:11434
timeout = 120
```

## Building a Knowledgebase

### Step-by-Step Process

1. **Create directory structure**
   ```bash
   mkdir -p /var/lib/vectordbs/myproject
   cd /var/lib/vectordbs/myproject
   mkdir documents
   ```

2. **Add source documents**
   ```bash
   cp /path/to/docs/*.md documents/
   cp /path/to/docs/*.txt documents/
   ```

3. **Create configuration**
   ```bash
   cat > myproject.cfg << EOF
   [DEFAULT]
   vector_model = text-embedding-3-small
   query_model = gpt-4o-mini
   query_temperature = 0.7
   
   [ALGORITHMS]
   enable_hybrid_search = true
   hybrid_search_weight = 0.7
   EOF
   ```

4. **Process documents**
   ```bash
   customkb database myproject documents/*.md
   ```

5. **Generate embeddings**
   ```bash
   customkb embed myproject
   ```

6. **Build search indexes**
   ```bash
   customkb bm25 myproject
   ```

7. **Optimize performance**
   ```bash
   customkb optimize myproject
   ```

8. **Test queries**
   ```bash
   customkb query myproject "What are the main topics?"
   customkb query myproject "Explain the key concepts"
   ```

### Advanced Pipeline

For production deployments with citation generation:

```bash
# Stage 1: Process with citations
customkb database myproject documents/*.md \
  --generate-citations \
  --citation-model gpt-4o-mini

# Stage 2: Generate embeddings with progress
customkb embed myproject \
  --batch-size 100 \
  --show-progress

# Stage 3: Build all indexes
customkb bm25 myproject
customkb optimize myproject --tier aggressive

# Stage 4: Enable reranking
customkb config myproject --set "enable_reranking=true"
customkb rerank myproject

# Stage 5: Verify and test
customkb verify myproject
customkb test myproject --num-queries 10
```

## Query Examples

### Basic Queries
```bash
# Simple question
customkb query tech_docs "How do I install Python?"

# Detailed explanation
customkb query tech_docs "Explain the authentication process" \
  --top-k 20 --temperature 0.7
```

### Advanced Queries
```bash
# Precise technical answer
customkb query tech_docs "API error codes" \
  --model gpt-4 \
  --temperature 0.1 \
  --top-k 30 \
  --format json

# Context-only for manual analysis
customkb query legal_docs "contract termination clauses" \
  --context-only \
  --top-k 50 > context.txt

# Custom system role
customkb query medical_kb "treatment options for condition X" \
  --system-role "You are a medical professional providing evidence-based information"
```

### Batch Processing
```bash
# Process multiple queries
while IFS= read -r question; do
  echo "Q: $question"
  customkb query myproject "$question" --format json | jq -r .response
  echo "---"
done < questions.txt > answers.txt

# Parallel processing
cat questions.txt | parallel -j 4 \
  'customkb query myproject {} --format json > results/{#}.json'
```

## Performance Tuning

### Memory Management
```bash
# Check memory usage
customkb stats myproject --memory

# Limit memory usage
customkb optimize myproject --memory-limit 4
```

### GPU Optimization
```bash
# Enable GPU acceleration
customkb config myproject --set "use_gpu=true"

# Monitor GPU usage
customkb monitor myproject --gpu

# Benchmark performance
customkb benchmark myproject --gpu
```

### Large Dataset Handling
```bash
# Process in chunks
customkb database large_kb documents/ \
  --chunk-size 300 \
  --batch-process

# Resume interrupted embedding
customkb embed large_kb \
  --batch-size 200 \
  --resume \
  --checkpoint-interval 1000

# Optimize for size
customkb optimize large_kb \
  --tier max \
  --compress-index
```

## Troubleshooting

### Common Issues

1. **Out of Memory**
   ```bash
   # Reduce batch size
   customkb embed myproject --batch-size 25
   
   # Use disk-based index
   customkb config myproject --set "index_type=ivf_flat"
   ```

2. **Slow Queries**
   ```bash
   # Analyze query performance
   customkb analyze-query myproject "slow query" --profile
   
   # Optimize index
   customkb optimize myproject --rebuild-index
   ```

3. **GPU Errors**
   ```bash
   # Disable GPU
   customkb config myproject --set "use_gpu=false"
   
   # Clear GPU cache
   python -c "import torch; torch.cuda.empty_cache()"
   ```

4. **Embedding Failures**
   ```bash
   # Check failed chunks
   customkb verify myproject --check-embeddings
   
   # Retry failed embeddings
   customkb embed myproject --retry-failed
   ```

### Debug Mode
```bash
# Enable debug logging
customkb --debug query myproject "test query"

# Verbose output
customkb -v embed myproject

# Check logs
tail -f /var/lib/vectordbs/myproject/logs/customkb.log
```

## Best Practices

1. **Document Preparation**
   - Use consistent formatting
   - Include metadata in frontmatter
   - Chunk size: 300-500 tokens typically optimal
   - Clean text of special characters if needed

2. **Model Selection**
   - Embedding: `text-embedding-3-small` for most cases
   - Query: `gpt-4o-mini` for cost/performance balance
   - Use `gpt-4` for complex reasoning tasks

3. **Search Configuration**
   - Enable hybrid search for technical content
   - Adjust similarity threshold based on domain
   - Use reranking for critical applications

4. **Performance**
   - Batch process large datasets
   - Use GPU for datasets > 100k chunks
   - Monitor memory usage during embedding
   - Regular optimization for query speed

5. **Security**
   - Store API keys in environment variables
   - Restrict knowledgebase directory permissions
   - Validate all user inputs
   - Regular backups of vector databases

## Integration Examples

### Python Script
```python
import subprocess
import json

class CustomKBClient:
    def __init__(self, kb_name):
        self.kb_name = kb_name
    
    def query(self, question, **kwargs):
        cmd = ['customkb', 'query', self.kb_name, question, '--format', 'json']
        for key, value in kwargs.items():
            cmd.extend([f'--{key}', str(value)])
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout)

# Usage
kb = CustomKBClient('myproject')
response = kb.query("What is the main feature?", temperature=0.5, top_k=15)
print(response['response'])
```

### Shell Script Automation
```bash
#!/bin/bash
# Daily knowledge base update

KB_NAME="company_docs"
DOCS_DIR="/shared/documents"
LOG_FILE="/var/log/kb_update.log"

echo "$(date): Starting KB update" >> "$LOG_FILE"

# Add new documents
customkb database "$KB_NAME" "$DOCS_DIR"/*.md \
  --since "1 day ago" >> "$LOG_FILE" 2>&1

# Regenerate embeddings for new docs
customkb embed "$KB_NAME" --new-only >> "$LOG_FILE" 2>&1

# Optimize if needed
if [ $(date +%w) -eq 0 ]; then  # Sunday
  customkb optimize "$KB_NAME" >> "$LOG_FILE" 2>&1
fi

echo "$(date): KB update complete" >> "$LOG_FILE"
```

## See Also

- [KB-Query Usage Guide](./KB-QUERY-USAGE.md) - CLI interface for queries
- [API Documentation](./API-DOCUMENTATION.md) - Direct API access
- [Build Pipeline Guide](./BUILD-PIPELINE.md) - Production build processes
- [Configuration Guide](./CONFIGURATION-GUIDE.md) - Detailed config options

#fin