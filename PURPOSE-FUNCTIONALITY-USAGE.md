# PURPOSE-FUNCTIONALITY-USAGE

## Executive Summary

**YaTTI KB-Query** is a comprehensive AI-powered knowledgebase system that transforms document collections into intelligent, queryable knowledge repositories. It enables semantic search and AI-generated responses from custom document sets using state-of-the-art vector databases and large language models.

---

## Purpose

### Problem Statement

Organizations face critical challenges with information management:

1. **Information Overload** - Documentation accumulates faster than it can be searched effectively
2. **Context Loss** - Keyword search fails to understand meaning and relationships
3. **Knowledge Fragmentation** - Information scattered across formats becomes inaccessible
4. **Repetitive Queries** - Experts spend time answering the same questions repeatedly

### Solution

YaTTI KB-Query provides:
- **Semantic Search** - Find content by meaning, not just keywords
- **AI-Powered Responses** - Generate contextual answers from relevant document chunks
- **Hybrid Search** - Combine vector similarity (70%) with BM25 keyword matching (30%)
- **Production-Ready API** - RESTful interface with authentication and rate limiting

### Target Users

| User Type | Use Case |
|-----------|----------|
| **Consultancy Firms** | Domain-specific knowledge retrieval (legal, business, regulatory) |
| **Customer Support** | Instant, accurate responses from FAQs and documentation |
| **Educational Institutions** | Course materials and research document querying |
| **Government Agencies** | Regulatory information and public service queries |
| **Technical Teams** | Documentation search across codebases and manuals |

### Production Example: Okusi Associates

The included `okusiassociates/` knowledgebase demonstrates a real-world implementation:
- **Domain**: Indonesian business consultancy (PMA companies, immigration, taxation)
- **Scale**: 3,651 documents, 45,230 chunks, 125.4 MB index
- **Clients**: Serves 3,000+ foreign-owned companies
- **Queries**: Company formation, work permits, tax compliance, regulatory requirements

---

## Functionality

### System Architecture

```
                                    YaTTI KB-Query System
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                                                                             │
    │  ┌─────────────┐     ┌─────────────────┐     ┌───────────────────────────┐ │
    │  │             │     │                 │     │                           │ │
    │  │  kb-query   │────▶│   PHP API       │────▶│       CustomKB            │ │
    │  │  (Bash CLI) │     │   (index.php)   │     │       (Python)            │ │
    │  │             │     │                 │     │                           │ │
    │  └─────────────┘     └─────────────────┘     │  ┌─────────────────────┐  │ │
    │        │                                     │  │ SQLite Database     │  │ │
    │        ▼                                     │  │ - Documents         │  │ │
    │  User's Terminal                             │  │ - Chunks            │  │ │
    │                                              │  │ - Metadata          │  │ │
    │                                              │  └─────────────────────┘  │ │
    │                                              │                           │ │
    │                                              │  ┌─────────────────────┐  │ │
    │                                              │  │ FAISS Vector Index  │  │ │
    │                                              │  │ - Embeddings        │  │ │
    │                                              │  │ - Similarity Search │  │ │
    │                                              │  └─────────────────────┘  │ │
    │                                              │                           │ │
    │                                              │  ┌─────────────────────┐  │ │
    │                                              │  │ BM25 Index          │  │ │
    │                                              │  │ (Optional)          │  │ │
    │                                              │  └─────────────────────┘  │ │
    │                                              │                           │ │
    │                                              └───────────────────────────┘ │
    │                                                           │                │
    │                                                           ▼                │
    │                                              ┌───────────────────────────┐ │
    │                                              │     External APIs         │ │
    │                                              │  - OpenAI (embeddings)    │ │
    │                                              │  - GPT-4/Claude (LLM)     │ │
    │                                              │  - Google Gemini          │ │
    │                                              │  - Ollama (local)         │ │
    │                                              └───────────────────────────┘ │
    │                                                                             │
    └─────────────────────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. kb-query (Bash CLI Client)

**Location**: `/ai/scripts/kb-query/kb-query`

A lightweight command-line interface for querying hosted knowledgebases.

| Feature | Description |
|---------|-------------|
| API Authentication | Bearer token support via `YATTI_API_KEY` |
| Output Formats | JSON, text, markdown |
| Field Selection | Extract specific response fields (`.query`, `.response`, etc.) |
| Context-Only Mode | Retrieve raw context without LLM processing |
| Reference Files | Include additional context in queries |
| Caching | Local cache for KB list with configurable TTL |
| History | Query history tracking in `~/.local/share/kb-query/history` |

#### 2. CustomKB (Python Backend Engine)

**Location**: `/ai/scripts/customkb/` (symlinked)

The core engine for building and managing AI-powered vector databases.

| Module | Purpose |
|--------|---------|
| `database/` | SQLite operations, document storage, chunking |
| `embedding/` | Vector generation via OpenAI/Google APIs |
| `query/` | Search processing, LLM integration, response generation |
| `config/` | Configuration management, validation |
| `utils/` | Security, logging, performance utilities |
| `mcp_server/` | MCP protocol server for AI assistant integration |

**Supported Models**:
- **Embeddings**: `text-embedding-3-small`, `text-embedding-3-large`, `gemini-embedding-001`
- **LLMs**: GPT-4, GPT-4o-mini, Claude 3 (Haiku/Sonnet/Opus), Gemini Pro, Ollama models

#### 3. PHP API Endpoint

**Location**: `/var/www/vhosts/yatti.id/html/v1/index.php`

Server-side router handling API requests with:
- Security headers (HSTS, XSS protection, CSP)
- CORS support for cross-origin requests
- Authentication middleware (API key validation)
- Rate limiting (60/min, 1000/hour, 10000/day)
- Request logging and error handling

### Key Capabilities

| Capability | Implementation |
|------------|----------------|
| **Semantic Search** | FAISS vector similarity with configurable thresholds |
| **Hybrid Search** | 70% vector + 30% BM25 keyword matching |
| **Cross-Encoder Reranking** | 20-40% accuracy improvement using `ms-marco-MiniLM` |
| **Smart Chunking** | Token-based splitting (default 500 tokens, 50 overlap) |
| **Citation Generation** | LLM-powered metadata extraction during build |
| **GPU Acceleration** | CUDA support for large-scale embedding |
| **Multi-Language** | 27+ stopword languages including Indonesian |

---

## Usage

### Installation

#### KB-Query CLI (Client)

```bash
# Prerequisites
sudo apt install git curl jq gridsite-clients

# Install
cd /tmp && git clone https://github.com/Open-Technology-Foundation/kb-query.git && sudo kb-query/kb-query.install

# Configure authentication
export YATTI_API_KEY="yatti_your_api_key_here"
```

#### CustomKB Engine (Server/Builder)

```bash
# Navigate to customkb
cd /ai/scripts/customkb

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Setup NLTK data
sudo ./setup/nltk_setup.py download cleanup

# Set environment
export OPENAI_API_KEY="your-openai-api-key"
export VECTORDBS="/var/lib/vectordbs"
```

### Common Workflows

#### Workflow 1: Query Existing Knowledgebase

```bash
# List available knowledgebases
kb-query list

# Simple query
kb-query appliedanthropology "What is dharma?"

# Query with specific fields
kb-query okusiassociates "What is a PMA company?" .query .response

# Context-only (no LLM processing)
kb-query -c jakartapost "latest technology news"

# Advanced query with parameters
kb-query okusiassociates "Tax obligations for foreign companies" \
  --query-model gpt-4 \
  --query-temperature 0.1 \
  --query-top-k 30
```

#### Workflow 2: Build New Knowledgebase

```bash
# 1. Create directory structure
mkdir -p /var/lib/vectordbs/myproject/documents
cd /var/lib/vectordbs/myproject

# 2. Add source documents
cp /path/to/docs/*.md documents/

# 3. Create configuration
cat > myproject.cfg << 'EOF'
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
query_temperature = 0.7

[ALGORITHMS]
enable_hybrid_search = true
hybrid_search_weight = 0.7
EOF

# 4. Process documents into database
customkb database myproject documents/*.md

# 5. Generate embeddings
customkb embed myproject

# 6. Build BM25 index (optional, for hybrid search)
customkb bm25 myproject

# 7. Optimize performance
customkb optimize myproject

# 8. Test query
customkb query myproject "What are the main topics covered?"
```

#### Workflow 3: Production Build Pipeline

For large-scale knowledgebases with citation generation:

```bash
cd /var/lib/vectordbs/okusiassociates

# Full automated build (all 6 stages)
./0_build.sh -a -y

# Or run individual stages:
./0_build.sh -0    # Stage 0: Text extraction/caching
./0_build.sh -1    # Stage 1: Citation generation (LLM)
./0_build.sh -2    # Stage 2: Citation merging
./0_build.sh -3    # Stage 3: Database import
./0_build.sh -4    # Stage 4: Embedding generation
./0_build.sh -5    # Stage 5: Testing & validation
```

### API Integration

#### Direct API Calls

```bash
# Basic query
curl -H "Authorization: Bearer $YATTI_API_KEY" \
     "https://yatti.id/v1/index.php/appliedanthropology?q=What%20is%20dharma"

# Context-only
curl -H "Authorization: Bearer $YATTI_API_KEY" \
     "https://yatti.id/v1/index.php/okusiassociates?q=PMA%20requirements&context_only=true"

# With parameters
curl -H "Authorization: Bearer $YATTI_API_KEY" \
     "https://yatti.id/v1/index.php/okusiassociates?q=Company%20formation&top_k=30&temperature=0.2"
```

#### Python Client

```python
import requests

class YaTTIClient:
    def __init__(self, api_key):
        self.api_key = api_key
        self.base_url = "https://yatti.id/v1/index.php"
        self.headers = {"Authorization": f"Bearer {api_key}"}

    def query(self, kb, question, **kwargs):
        params = {"q": question, **kwargs}
        response = requests.get(
            f"{self.base_url}/{kb}",
            headers=self.headers,
            params=params
        )
        return response.json()

# Usage
client = YaTTIClient("yatti_your_api_key")
result = client.query("okusiassociates", "What is a PMA company?", top_k=20)
print(result["response"])
```

### Configuration Reference

#### KB Configuration (`{kb_name}.cfg`)

```ini
[DEFAULT]
vector_model = text-embedding-3-small
vector_dimensions = 1024
vector_chunks = 500
query_model = gpt-4o-mini
query_temperature = 0.7
query_max_tokens = 2000
query_top_k = 10
query_context_scope = 3

[ALGORITHMS]
enable_hybrid_search = true
hybrid_search_weight = 0.7
similarity_threshold = 0.3
enable_reranking = true
reranking_model = cross-encoder/ms-marco-MiniLM-L-6-v2

[PERFORMANCE]
batch_size = 50
max_threads = 8
use_gpu = true
```

#### Build Configuration (`{kb_name}.build.conf`)

```bash
PARALLEL_JOBS=43
CITATION_MODEL="gpt-4o-mini"
EMBEDDING_MODEL="text-embedding-3-small"
QUERY_MODEL="gpt-4"
TEST_QUERIES=(
  "What is a PMA company?"
  "Requirements for work permit"
  "Tax obligations for foreign companies"
)
ENABLE_CITATIONS=1
PRESERVE_TEXT_CACHE=1
```

### Testing

```bash
# KB-Query API tests
cd /ai/scripts/kb-query/tests
./run_all_tests.sh           # Full test suite
./run_all_tests.sh --quick   # Skip integration tests
./quick_test.sh              # Minimal smoke test

# CustomKB unit tests
cd /ai/scripts/customkb
source .venv/bin/activate
./run_tests.py --safe        # Safe tests only (no API calls)
./run_tests.py               # Full test suite
```

---

## Directory Structure

```
/ai/scripts/kb-query/
├── kb-query                 # Main CLI script (Bash)
├── kb-query.test            # CLI test script
├── kb-query-completion.bash # Bash completion
├── kb-query-config.example  # Example configuration
├── index.php -> ...         # Symlink to API endpoint
├── customkb -> ...          # Symlink to CustomKB engine
├── okusiassociates -> ...   # Symlink to example KB
├── docs/                    # Documentation
│   ├── KB-QUERY-USAGE.md
│   ├── CUSTOMKB-USAGE.md
│   ├── API-DOCUMENTATION.md
│   ├── BUILD-PIPELINE.md
│   ├── QUICKSTART.md
│   └── TROUBLESHOOTING.md
├── examples/                # Usage examples
│   ├── basic-queries/
│   ├── advanced-queries/
│   ├── building-kb/
│   └── api-integration/
├── tests/                   # Test suite
│   ├── test_framework.sh
│   ├── test_basic_commands.sh
│   ├── test_security.sh
│   └── run_all_tests.sh
└── scripts/                 # Utility scripts

/ai/scripts/customkb/
├── customkb.py              # Main entry point
├── customkb                  # CLI wrapper
├── database/                # SQLite operations
├── embedding/               # Vector generation
├── query/                   # Search & LLM integration
├── config/                  # Configuration management
├── utils/                   # Utilities & security
├── mcp_server/              # MCP protocol server
├── tests/                   # Python test suite
├── requirements.txt         # Python dependencies
└── .venv/                   # Virtual environment
```

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `YATTI_API_KEY` | Yes | API authentication key for kb-query |
| `OPENAI_API_KEY` | Yes | OpenAI API key for embeddings/LLM |
| `VECTORDBS` | No | KB storage directory (default: `/var/lib/vectordbs`) |
| `ANTHROPIC_API_KEY` | No | For Claude models |
| `GOOGLE_API_KEY` | No | For Gemini models |
| `NLTK_DATA` | No | NLTK data directory |

---

## Important Notes

1. **API Keys**: Store securely; never commit to version control
2. **Storage**: All knowledgebases reside in `/var/lib/vectordbs/`
3. **Logs**: Debug logs in `/var/lib/vectordbs/{kb}/logs/`
4. **Security**: Input validation, SQL injection prevention, path traversal protection
5. **Rate Limits**: 60 requests/minute, 1000/hour, 10000/day
6. **Backups**: Use `checkpoint -q` for code backups to `/var/backups/`

---

## Summary

YaTTI KB-Query is a production-ready knowledge management system that:

- Transforms document collections into intelligent, queryable repositories
- Combines semantic vector search with keyword matching for optimal results
- Supports multiple LLM providers (OpenAI, Anthropic, Google, local)
- Provides simple CLI and RESTful API interfaces
- Scales from small documentation sets to enterprise-level deployments
- Includes comprehensive tooling for building, testing, and optimizing knowledgebases

The system demonstrates practical AI application for information retrieval, making organizational knowledge accessible through natural language queries with contextually accurate responses.

#fin
