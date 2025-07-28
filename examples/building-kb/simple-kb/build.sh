#!/bin/bash
# Build a Simple Knowledgebase Example

set -euo pipefail

KB_NAME="example_kb"
KB_DIR="/tmp/vectordbs/$KB_NAME"

echo "=== Building Simple Knowledgebase: $KB_NAME ==="
echo

# Check prerequisites
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "Error: OPENAI_API_KEY not set"
  echo "Please run: export OPENAI_API_KEY='your-key'"
  exit 1
fi

# Setup environment
echo "1. Setting up environment..."
export VECTORDBS="/tmp/vectordbs"
mkdir -p "$KB_DIR"
cd "$KB_DIR"

# Create sample documents
echo "2. Creating sample documents..."
mkdir -p documents

cat > documents/introduction.md << 'EOF'
# Example Knowledgebase

This is a demonstration knowledgebase showing how to build and query a custom knowledge repository using YaTTI CustomKB.

## Overview

YaTTI CustomKB allows you to:
- Convert documents into searchable knowledge
- Use AI to answer questions about your content
- Build domain-specific expertise systems

## Key Features

### Document Processing
- Supports multiple formats (MD, TXT, HTML, PDF)
- Intelligent text chunking
- Metadata extraction

### AI-Powered Search
- Semantic search using embeddings
- Context-aware responses
- Multiple language model support

### Performance
- Fast query response times
- Scalable to thousands of documents
- GPU acceleration available
EOF

cat > documents/setup_guide.md << 'EOF'
# Setup Guide

## Requirements

- Ubuntu 24.04 LTS
- Python 3.12+
- OpenAI API key

## Installation Steps

1. Install dependencies:
   ```bash
   sudo apt install python3-pip python3-venv
   ```

2. Create virtual environment:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. Install CustomKB:
   ```bash
   pip install -r requirements.txt
   ```

## Configuration

Create a configuration file with your preferences:
- Embedding model selection
- Query model selection
- Performance settings

## Building Your First KB

1. Prepare your documents
2. Create configuration
3. Process documents
4. Generate embeddings
5. Start querying!
EOF

cat > documents/best_practices.md << 'EOF'
# Best Practices

## Document Preparation

### Structure
- Use clear headings
- Break content into logical sections
- Include metadata where possible

### Content Quality
- Be specific and detailed
- Avoid ambiguous language
- Include examples

## Configuration Tips

### Model Selection
- **Embeddings**: Use text-embedding-3-small for most cases
- **Queries**: GPT-4 for complex reasoning, GPT-3.5 for speed

### Performance Optimization
- Enable GPU if available
- Adjust batch sizes based on memory
- Use hybrid search for technical content

## Query Strategies

### Effective Queries
- Be specific in your questions
- Provide context when needed
- Use appropriate temperature settings

### Testing
- Test with various question types
- Verify accuracy of responses
- Monitor performance metrics
EOF

# Create configuration
echo "3. Creating configuration..."
cat > "$KB_NAME.cfg" << 'EOF'
[DEFAULT]
# Model settings
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
query_temperature = 0.7
query_max_tokens = 1500

# Search settings
query_top_k = 10
similarity_threshold = 0.3

[ALGORITHMS]
# Enable hybrid search for better accuracy
enable_hybrid_search = false  # Set to true after BM25 index
similarity_metric = cosine

[PERFORMANCE]
# Processing settings
batch_size = 50
chunk_size = 500
chunk_overlap = 50

# Resource settings
use_gpu = false
max_threads = 4

[STORAGE]
# Logging
log_level = INFO
cache_enabled = true
EOF

# Activate CustomKB environment
echo "4. Activating CustomKB environment..."
CUSTOMKB_PATH="/ai/scripts/kb-query/customkb"
cd "$CUSTOMKB_PATH"
source .venv/bin/activate
cd "$KB_DIR"

# Process documents
echo "5. Processing documents..."
customkb database "$KB_NAME" documents/*.md

# Show statistics
echo
echo "Document statistics:"
sqlite3 "${KB_NAME}.db" "SELECT COUNT(*) || ' documents imported' FROM documents;"
sqlite3 "${KB_NAME}.db" "SELECT COUNT(*) || ' chunks created' FROM chunks;"

# Generate embeddings
echo
echo "6. Generating embeddings..."
customkb embed "$KB_NAME" --show-progress

# Optional: Build BM25 index
echo
echo "7. Building BM25 index for hybrid search..."
customkb bm25 "$KB_NAME"

# Update config to enable hybrid search
sed -i 's/enable_hybrid_search = false/enable_hybrid_search = true/' "$KB_NAME.cfg"

# Test queries
echo
echo "8. Testing the knowledgebase..."
echo

echo "Test 1: Basic question"
customkb query "$KB_NAME" "What is YaTTI CustomKB?"
echo

echo "Test 2: Specific information"
customkb query "$KB_NAME" "What are the installation requirements?"
echo

echo "Test 3: Best practices"
customkb query "$KB_NAME" "What model should I use for embeddings?"
echo

# Show how to query
echo
echo "=== Knowledgebase Ready! ==="
echo
echo "Your knowledgebase is built and ready at: $KB_DIR"
echo
echo "To query your knowledgebase:"
echo "  cd $CUSTOMKB_PATH && source .venv/bin/activate"
echo "  customkb query $KB_NAME \"your question here\""
echo
echo "To use with kb-query API (requires deployment):"
echo "  kb-query $KB_NAME \"your question here\""
echo

# Save example queries
cat > example_queries.txt << 'EOF'
# Example queries for your knowledgebase

customkb query example_kb "What is YaTTI CustomKB?"
customkb query example_kb "How do I install CustomKB?"
customkb query example_kb "What are the best practices for document preparation?"
customkb query example_kb "Which embedding model should I use?"
customkb query example_kb "How can I optimize query performance?"
customkb query example_kb "What are the configuration options?"

# Advanced queries
customkb query example_kb "Compare different language models" --temperature 0.3
customkb query example_kb "Explain the document processing pipeline" --top-k 20
customkb query example_kb "List all supported features" --context-only
EOF

echo "Example queries saved to: $KB_DIR/example_queries.txt"

#fin