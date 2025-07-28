# PURPOSE-FUNCTIONALITY-USAGE

## Project Overview

The YaTTI Knowledge Base System is a comprehensive AI-powered platform for creating, managing, and querying intelligent knowledge repositories. It combines advanced natural language processing, vector databases, and large language models to transform document collections into searchable, context-aware knowledge bases that provide accurate, relevant answers.

## Purpose

### What Problem Does It Solve?

1. **Information Overload**: Organizations accumulate vast amounts of documentation, making it difficult to find specific information quickly
2. **Context Loss**: Traditional search returns keyword matches without understanding meaning or context
3. **Knowledge Silos**: Information scattered across multiple documents and formats becomes inaccessible
4. **Manual Query Processing**: Human experts spend time answering repetitive questions about documented topics

### Who Is It For?

- **Organizations** with extensive documentation (technical manuals, FAQs, regulations, guides)
- **Customer Support Teams** needing instant access to accurate information
- **Consultancy Firms** requiring quick retrieval of domain-specific knowledge
- **Educational Institutions** managing course materials and research documents
- **Government Agencies** handling regulatory information and public queries
- **Any Entity** needing to transform static documents into interactive knowledge systems

### Real-World Application

The included example, Okusi Associates, demonstrates a production implementation for an Indonesian business consultancy that:
- Serves 3,000+ foreign-owned companies
- Answers queries about Indonesian business regulations, immigration, and taxation
- Processes 3,651 documents covering company formation, permits, and compliance
- Provides instant, accurate responses to complex regulatory questions

## Functionality

### Core Components

#### 1. kb-query CLI (v0.9.14)
A lightweight command-line interface for querying hosted knowledge bases via the YaTTI API.

**Key Features:**
- Simple query interface with URL-encoded API calls
- Multiple output format support (JSON fields)
- Context-only retrieval mode (no LLM processing)
- Reference file integration for contextual queries
- Configurable query parameters (model, temperature, tokens)
- Built-in commands: list, help, update

#### 2. CustomKB Engine (v0.8.0)
A sophisticated Python tool for building and managing AI-powered vector databases.

**Key Features:**
- **Document Processing**: Supports Markdown, HTML, code files, plain text
- **Smart Chunking**: Token-based segmentation preserving context
- **Multiple Embeddings**: OpenAI (text-embedding-3-*), Google (gemini-embedding-001)
- **Hybrid Search**: Combines vector similarity (FAISS) with BM25 keyword matching
- **LLM Integration**: GPT-4, Claude, Gemini, local models via Ollama
- **Cross-Encoder Reranking**: 20-40% accuracy improvement
- **Performance Optimization**: GPU acceleration, batch processing, caching
- **Enterprise Security**: Input validation, API key protection, SQL injection prevention

#### 3. PHP API Endpoint
Server-side handler that bridges kb-query requests to CustomKB instances.

**Key Features:**
- Routes queries to appropriate knowledge bases
- Executes CustomKB commands server-side
- Rate limiting and authentication
- JSON response formatting with timing metrics

### Technical Capabilities

#### Document Processing Pipeline
1. **Ingestion**: Multi-format file processing with metadata extraction
2. **Normalization**: Language detection, stopword filtering (27+ languages)
3. **Chunking**: Configurable token-based splitting (default: 500 tokens)
4. **Citation Generation**: Automated metadata extraction using LLMs
5. **Embedding**: Vector generation via OpenAI/Google APIs
6. **Indexing**: FAISS vector index + optional BM25 text search

#### Search & Retrieval
- **Semantic Search**: Find content by meaning, not just keywords
- **Hybrid Search**: 70% vector + 30% keyword matching (configurable)
- **Relevance Scoring**: Similarity thresholds and context-aware ranking
- **Reranking**: Advanced models improve result accuracy
- **Context Management**: XML/JSON/Markdown formatted references

#### AI Response Generation
- **Multi-Model Support**: 15+ LLM models supported
- **Prompt Templates**: Instructive, scholarly, analytical, conversational styles
- **Temperature Control**: Fine-tune response creativity
- **Token Management**: Configurable limits for responses
- **System Roles**: Customizable AI personas

### Dependencies

**System Requirements:**
- Ubuntu 24.04 LTS
- Python 3.12+
- SQLite 3.45+
- 4GB+ RAM (8GB+ recommended)
- NVIDIA GPU with CUDA (optional)

**Python Libraries:**
- faiss-gpu-cu12: Vector similarity search
- sentence-transformers: Cross-encoder reranking
- langchain_text_splitters: Document chunking
- openai/anthropic/google-genai: LLM APIs
- rank-bm25: Keyword search
- nltk/spacy: NLP processing

## Usage

### Common Workflows

#### 1. Quick Query of Existing Knowledge Base
```bash
# List available knowledge bases
kb-query list

# Query a knowledge base
kb-query appliedanthropology "What is dharma?"

# Get detailed response with specific fields
kb-query okusiassociates "How to set up a PMA company?" .query .response
```

#### 2. Building a New Knowledge Base
```bash
# Set up environment
cd customkb
source .venv/bin/activate

# Create KB directory
mkdir -p /var/lib/vectordbs/myproject
cd /var/lib/vectordbs/myproject

# Add documents
mkdir documents
cp /path/to/*.md documents/

# Create configuration
cat > myproject.cfg << EOF
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
query_temperature = 0.7
EOF

# Process pipeline
customkb database myproject documents/*.md
customkb embed myproject
customkb optimize myproject

# Test query
customkb query myproject "What are the main topics?"
```

#### 3. Production Build Pipeline (Advanced)
```bash
cd okusiassociates

# Full automated build (6 stages)
./0_build.sh -a -y

# Individual stages
./0_build.sh -0    # Create text cache
./0_build.sh -1    # Generate citations
./0_build.sh -2    # Merge citations
./0_build.sh -3    # Import to database
./0_build.sh -4    # Generate embeddings
./0_build.sh -5    # Test queries
```

### Configuration Examples

#### Basic Knowledge Base Config
```ini
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
query_temperature = 0.7
query_max_tokens = 2000

[ALGORITHMS]
enable_hybrid_search = true
hybrid_search_weight = 0.7
similarity_threshold = 0.3

[PERFORMANCE]
batch_size = 50
max_threads = 8
```

#### Build Pipeline Config
```bash
# okusiassociates.build.conf
PARALLEL_JOBS=43
CITATION_MODEL="gpt-4.1-mini"
TEST_QUERIES=("What is a PMA company?" "Visa requirements for foreign workers")
PRESERVE_EMBED_DATA_TEXT=1
```

### API Integration

#### Direct API Calls
```bash
# Basic query
curl -s "https://yatti.id/v1/appliedanthropology?q=$(urlencode 'What is dharma?')"

# Context-only retrieval
curl -s "https://yatti.id/v1/okusiassociates?q=$(urlencode 'PMA requirements')&context_only"
```

#### Using kb-query Wrapper
```bash
# With custom parameters
kb-query okusiassociates "Complex question" \
  --query-model gpt-4 \
  --query-temperature 0.1 \
  --query-top-k 30 \
  --query-context-scope 5
```

### Performance Optimization

```bash
# Analyze current configuration
customkb optimize myproject --analyze

# Apply optimizations based on system resources
customkb optimize myproject

# Enable hybrid search for better accuracy
customkb edit myproject  # Set enable_hybrid_search = true
customkb bm25 myproject

# Verify database indexes
customkb verify-indexes myproject
```

## Important Notes

1. **API Keys Required**: OpenAI API key is mandatory; Anthropic/Google keys optional
2. **Storage Location**: All knowledge bases stored in `/var/lib/vectordbs/`
3. **Security**: All inputs validated, API keys protected, SQL injection prevented
4. **Performance**: Use optimization commands for large datasets
5. **Logs**: Check `/var/lib/vectordbs/{kb}/logs/` for debugging
6. **Backups**: Use `checkpoint -q` for code backups (stored in `/var/backups/`)

## Summary

The YaTTI Knowledge Base System provides a complete solution for organizations needing to transform static documentation into intelligent, queryable knowledge repositories. It combines enterprise-grade security, state-of-the-art AI models, and flexible configuration options to deliver accurate, contextual answers at scale. Whether serving customer queries, supporting internal teams, or managing regulatory compliance, the system adapts to various use cases while maintaining high performance and accuracy.