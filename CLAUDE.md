# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Coding Principles
- K.I.S.S.
- "The best process is no process"
- "Everything should be made as simple as possible, but not simpler."

## Overview

YaTTI KB-Query is a comprehensive knowledgebase system with two main components:
1. **kb-query** - CLI interface for querying YaTTI's custom knowledgebase API
2. **customkb** - Python-based tool for building and managing AI-powered vector databases

The system enables creation, management, and intelligent querying of specialized knowledge repositories using state-of-the-art NLP and vector search technologies.

## Repository Structure

```
/ai/scripts/kb-query/
├── kb-query              # Main CLI script for API queries
├── kb-query.test         # Test script for API functionality
├── index.php             # PHP API endpoint handler
├── customkb/             # CustomKB vector database tool
│   ├── customkb.py       # Main entry point
│   ├── config/           # Configuration management
│   ├── database/         # SQLite database operations
│   ├── embedding/        # Vector embedding generation
│   ├── query/            # Query processing and LLM integration
│   └── utils/            # Utility functions and security
└── okusiassociates/      # Example knowledgebase implementation
    ├── 0_build.sh        # Multi-stage build pipeline
    ├── embed_data/       # Source documents
    └── embed_data.text/  # Processed text cache
```

## Installation & Setup

### KB-Query Installation

Dependencies (Ubuntu 24.04):
```bash
sudo apt install git curl jq gridsite-clients
```

Installation:
```bash
cd /tmp && git clone https://github.com/Open-Technology-Foundation/kb-query.git && sudo kb-query/kb-query.install
```

The installer creates `/usr/share/kb-query` and symlinks the main script to `/usr/local/bin/kb-query`.

### CustomKB Setup

```bash
cd customkb
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
sudo ./setup/nltk_setup.py download cleanup
```

Set environment variables:
```bash
export OPENAI_API_KEY="your-key"
export VECTORDBS="/var/lib/vectordbs"
export NLTK_DATA="$HOME/nltk_data"
```

## Testing

**KB-Query API Test:**
```bash
./kb-query.test
```

**CustomKB Tests:**
```bash
source customkb/.venv/bin/activate
./customkb/run_tests.py --safe
```

## Architecture Overview

### System Flow

1. **Document Ingestion** → CustomKB processes source files into chunks
2. **Embedding Generation** → Vector embeddings created via OpenAI/Google APIs
3. **Index Building** → FAISS vector index + optional BM25 text search
4. **Query Processing** → Hybrid search finds relevant context
5. **AI Response** → LLM generates answers based on retrieved context
6. **API Access** → KB-Query provides simple CLI interface to query KBs

### Key Components

#### 1. KB-Query (Bash CLI)
- Wraps curl commands for API access
- Handles parameter parsing and validation
- Manages HTTP headers and authentication
- Formats JSON responses using jq
- Supports multiple output fields and context-only queries

#### 2. CustomKB (Python)
- **Database Management**: SQLite for metadata, FAISS for vectors
- **Embedding Models**: OpenAI (ada-002, text-embedding-3-*), Google (gemini-embedding-001)
- **LLM Support**: GPT-4, Claude, Gemini, local models via Ollama
- **Search Methods**: Vector similarity, BM25 keyword, hybrid search
- **Performance**: GPU acceleration, batch processing, caching

#### 3. PHP API Endpoint
- Routes requests to appropriate knowledgebases
- Executes customkb query commands
- Manages rate limiting and authentication
- Returns JSON responses with timing metrics

### Configuration Files

**KB Configuration** (`{kb_name}.cfg`):
```ini
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
query_temperature = 0.1

[ALGORITHMS]
enable_hybrid_search = true
hybrid_search_weight = 0.7

[PERFORMANCE]
batch_size = 50
max_threads = 8
```

**Build Configuration** (`{kb_name}.build.conf`):
```bash
PARALLEL_JOBS=43
CITATION_MODEL="gpt-4.1-mini"
TEST_QUERIES=("What is a PMA company?")
```

## Common Development Tasks

### Building a New Knowledgebase

```bash
# 1. Create KB directory
mkdir -p /var/lib/vectordbs/mynewkb
cd /var/lib/vectordbs/mynewkb

# 2. Add source documents
mkdir embed_data
cp /path/to/docs/*.md embed_data/

# 3. Create configuration
cat > mynewkb.cfg << EOF
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
EOF

# 4. Process documents
customkb database mynewkb embed_data/*.md
customkb embed mynewkb

# 5. Test query
customkb query mynewkb "What is the main topic?"
```

### Using the Build Pipeline (Advanced)

For complex knowledgebases like okusiassociates:
```bash
cd okusiassociates
./0_build.sh -a -y  # Full non-interactive build
```

Build stages:
- Stage 0: Text cache creation
- Stage 1: Citation generation
- Stage 2: Citation merging
- Stage 3: Database import
- Stage 4: Embedding generation
- Stage 5: Query testing

### Optimizing Performance

```bash
# Analyze and optimize a KB
customkb optimize mynewkb --analyze
customkb optimize mynewkb

# Enable hybrid search
customkb edit mynewkb
# Set: enable_hybrid_search = true
customkb bm25 mynewkb
```

### API Query Examples

**Direct API call:**
```bash
curl -s "https://yatti.id/v1/index.php/appliedanthropology?q=$(urlencode 'What is dharma?')"
```

**Using kb-query CLI:**
```bash
kb-query appliedanthropology "What is dharma?" .response
kb-query okusiassociates -c "PMA company requirements"  # Context only
```

## Key API Endpoints

- `https://yatti.id/v1/index.php/{knowledgebase}?q={query}` - Query with LLM response
- `https://yatti.id/v1/index.php/{knowledgebase}?q={query}&context_only` - Context only
- `https://yatti.id/v1/index.php/list` - List available knowledgebases
- `https://yatti.id/v1/index.php/help` - API documentation

## Environment Variables

```bash
# Required for CustomKB
OPENAI_API_KEY       # OpenAI API key
VECTORDBS           # KB storage directory (default: /var/lib/vectordbs)
NLTK_DATA           # NLTK data directory

# Optional
ANTHROPIC_API_KEY   # For Claude models
GOOGLE_API_KEY      # For Gemini models
VECTOR_MODEL        # Override default embedding model
QUERY_MODEL         # Override default query model
```

## Security Considerations

- All file paths are validated against traversal attacks
- API keys must meet minimum length requirements
- Input sanitization for SQL injection prevention
- Rate limiting on API endpoints
- Separate read/write permissions for KB directories

## Performance Tips

1. **Use optimization command** for large KBs: `customkb optimize`
2. **Enable hybrid search** for better accuracy with technical content
3. **Batch document processing** to reduce API calls
4. **Monitor logs** in `/var/lib/vectordbs/{kb}/logs/`
5. **Use appropriate chunk sizes** based on content type (default: 500 tokens)

## Code Style

### Python
- Import order: standard lib, third-party, local modules
- Constants: Define at top of files, use UPPER_CASE
- Use descriptive function and variable names
- Docstrings for functions; comment complex logic sections
- Always end scripts with '\n#fin\n' to indicate the end of script
- **CustomKB specific**: Use 2-space indentation (not 4!)

### Shell Scripts
- Shebang `#!/usr/bin/env bash`
- Always `set -euo pipefail` at start for error handling
- 2-space indentation !!important
- Always declare variables before use; use local within functions
- Use descriptive variable names with `declare` or `local` statements
- Prefer `[[` over `[` for conditionals
- Prefer `((...)) && ...` or `[[...]] && ...` for simple conditionals over `if...then`
- Use integer values where appropriate, and always declare with `-i`
- Always end scripts with line '#fin' to indicate end of script

### PHP
- Always use 2-space indent
- Always use <?=...?> where possible for simple output; never <?php echo ...?>
- Follow PSR-12 coding standards
- Use prepared statements for all database queries
- Always check array keys with isset() before accessing
- Filter user inputs with filter_input() functions
- Sanitize output with htmlspecialchars() or similar
- Always check file operations for errors
- Use proper HTTP status codes for errors

### JavaScript
- Use ES6+ syntax and features
- Avoid jQuery where possible, use modern DOM APIs
- Follow Bootstrap patterns for UI components
- Always sanitize dynamic content before insertion
- Use strict mode ('use strict')

### Error Handling
- Python: Use try/except with logging
- Shell: Use proper exit codes and error messages

### Environment
- Python venvs: Activate with `source <dir>/.venv/bin/activate`
- Use MySQL or SQLite3 database for data storage, as appropriate

## Developer Tech Stack
- Ubuntu 24.04.2
- Bash 5.2.21
- Python 3.12.3
- Apache2 2.4.58
- PHP 8.3.6
- MySQL 8.0.42
- sqlite3 3.45.1
- Bootstrap 5.3
- FontAwesome

## Hardware
- Development Machine (hostname 'okusi'):
  - model: Lenovo Legion i9
  - gpu: GEForce RTX
  - system memory: 32GB

- Production Machine (hostname 'okusi3'):
  - model: Intel Xeon Silver 4410Y, 2 cpu
  - gpu: NVIDIA L4
  - system memory: 256GiB

## Backups and Code Checkpoints
- Use `checkpoint -q` for checkpoint backups
- Checkpoint backups are located in /var/backups/{codebase_dir}/{YYYYMMDD_hhmmss}/
- .gudang directories should normally be ignored