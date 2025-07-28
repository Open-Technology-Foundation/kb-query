# Build Pipeline Guide

This guide explains the multi-stage build pipeline for creating production-ready knowledgebases, using the Okusi Associates implementation as a reference.

## Overview

The build pipeline automates the complex process of:
1. Processing thousands of documents
2. Generating metadata and citations
3. Creating optimized vector databases
4. Validating results

## Pipeline Architecture

```
Source Documents
      ↓
[Stage 0: Text Extraction]
      ↓
Processed Text Cache
      ↓
[Stage 1: Citation Generation]
      ↓
Citation Database
      ↓
[Stage 2: Citation Merging]
      ↓
Enhanced Documents
      ↓
[Stage 3: Database Import]
      ↓
SQLite Database
      ↓
[Stage 4: Embedding Generation]
      ↓
Vector Index (FAISS)
      ↓
[Stage 5: Testing & Validation]
      ↓
Production Knowledgebase
```

## Build Script Structure

### Main Build Script

The `0_build.sh` script orchestrates the entire pipeline:

```bash
#!/bin/bash
set -euo pipefail

# Load configuration
source okusiassociates.build.conf

# Define stages
declare -A STAGES=(
  [0]="Text extraction and caching"
  [1]="Citation generation"
  [2]="Citation merging"
  [3]="Database import"
  [4]="Embedding generation"
  [5]="Testing and validation"
)

# Stage execution
run_stage() {
  local stage=$1
  echo "Running Stage $stage: ${STAGES[$stage]}"
  
  case $stage in
    0) run_text_extraction ;;
    1) run_citation_generation ;;
    2) run_citation_merging ;;
    3) run_database_import ;;
    4) run_embedding_generation ;;
    5) run_testing ;;
  esac
}
```

### Configuration File

```bash
# okusiassociates.build.conf

# Processing parameters
PARALLEL_JOBS=43
BATCH_SIZE=100
MAX_RETRIES=3

# Models
CITATION_MODEL="gpt-4o-mini"
EMBEDDING_MODEL="text-embedding-3-small"
QUERY_MODEL="gpt-4"

# Paths
SOURCE_DIR="embed_data"
TEXT_CACHE_DIR="embed_data.text"
CITATIONS_DB="citations/citations.db"
KB_NAME="okusiassociates"

# Testing
TEST_QUERIES=(
  "What is a PMA company?"
  "Requirements for work permit"
  "Tax obligations for foreign companies"
)

# Features
ENABLE_CITATIONS=1
PRESERVE_TEXT_CACHE=1
ENABLE_VALIDATION=1
```

## Stage Details

### Stage 0: Text Extraction

Converts various document formats into clean text files.

#### Purpose
- Extract text from MD, HTML, PDF, etc.
- Normalize formatting
- Create cacheable text files
- Handle encoding issues

#### Implementation
```bash
run_text_extraction() {
  local source_dir="$SOURCE_DIR"
  local cache_dir="$TEXT_CACHE_DIR"
  
  echo "Creating text cache from $source_dir"
  mkdir -p "$cache_dir"
  
  # Process each file type
  find "$source_dir" -type f \( \
    -name "*.md" -o \
    -name "*.txt" -o \
    -name "*.html" -o \
    -name "*.pdf" \
  \) | parallel -j "$PARALLEL_JOBS" \
    process_document {} "$cache_dir"
}

process_document() {
  local input_file=$1
  local output_dir=$2
  local base_name=$(basename "$input_file")
  local output_file="$output_dir/${base_name}.txt"
  
  case "${input_file##*.}" in
    md|txt)
      cp "$input_file" "$output_file"
      ;;
    html|htm)
      pandoc -f html -t plain "$input_file" -o "$output_file"
      ;;
    pdf)
      pdftotext "$input_file" "$output_file"
      ;;
  esac
  
  # Normalize text
  sed -i 's/\r$//' "$output_file"  # Remove CR
  sed -i 's/[^\x00-\x7F]//g' "$output_file"  # ASCII only
}
```

#### Output
- Text files in `embed_data.text/`
- One `.txt` file per source document
- Preserved directory structure

### Stage 1: Citation Generation

Generates metadata and citations for each document using LLM.

#### Purpose
- Extract key information (title, author, date, etc.)
- Generate document summaries
- Create searchable metadata
- Build citation database

#### Implementation
```bash
run_citation_generation() {
  local text_dir="$TEXT_CACHE_DIR"
  local citations_dir="citations"
  
  echo "Generating citations for documents in $text_dir"
  
  # Initialize citation database
  sqlite3 "$CITATIONS_DB" < citations/schema.sql
  
  # Process in parallel batches
  find "$text_dir" -name "*.txt" | \
    split -n l/"$PARALLEL_JOBS" | \
    parallel -j "$PARALLEL_JOBS" \
      process_citation_batch
}

process_citation_batch() {
  while IFS= read -r file; do
    generate_citation "$file"
  done
}

generate_citation() {
  local file=$1
  local content=$(head -c 2000 "$file")  # First 2000 chars
  
  # Call LLM for citation
  local citation=$(
    curl -s -X POST https://api.openai.com/v1/chat/completions \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d @- << EOF
{
  "model": "$CITATION_MODEL",
  "messages": [{
    "role": "system",
    "content": "Extract citation metadata from the document."
  }, {
    "role": "user",
    "content": "Document excerpt:\n\n$content\n\nExtract: title, author, date, type, summary"
  }],
  "temperature": 0.3,
  "max_tokens": 500
}
EOF
  )
  
  # Store in database
  store_citation "$file" "$citation"
}
```

#### Citation Schema
```sql
CREATE TABLE citations (
  id INTEGER PRIMARY KEY,
  file_path TEXT UNIQUE,
  title TEXT,
  author TEXT,
  date TEXT,
  document_type TEXT,
  summary TEXT,
  keywords TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Output
- SQLite database with citations
- JSON export of all citations
- Citation statistics report

### Stage 2: Citation Merging

Merges generated citations back into documents.

#### Purpose
- Enhance documents with metadata
- Add front matter to documents
- Prepare for database import
- Validate citation quality

#### Implementation
```bash
run_citation_merging() {
  echo "Merging citations into documents"
  
  # Export citations
  sqlite3 "$CITATIONS_DB" \
    "SELECT file_path, title, author, date, summary FROM citations" \
    > citations_export.tsv
  
  # Merge with documents
  while IFS=$'\t' read -r file title author date summary; do
    merge_citation "$file" "$title" "$author" "$date" "$summary"
  done < citations_export.tsv
  
  # Validate results
  validate_merged_documents
}

merge_citation() {
  local file=$1
  local title=$2
  local author=$3
  local date=$4
  local summary=$5
  
  # Create enhanced document
  cat > "${file}.enhanced" << EOF
---
title: $title
author: $author
date: $date
summary: $summary
source_file: $(basename "$file")
---

$(cat "$file")
EOF
}
```

#### Output
- Enhanced documents with metadata
- Validation report
- Failed merges log

### Stage 3: Database Import

Imports documents into CustomKB database.

#### Purpose
- Create SQLite database
- Chunk documents intelligently
- Store document metadata
- Prepare for embedding

#### Implementation
```bash
run_database_import() {
  echo "Importing documents to database"
  
  # Clear existing database
  rm -f "${KB_NAME}.db"
  
  # Import enhanced documents
  customkb database "$KB_NAME" \
    "$TEXT_CACHE_DIR"/*.txt.enhanced \
    --chunk-size 500 \
    --chunk-overlap 50 \
    --batch-size "$BATCH_SIZE"
  
  # Verify import
  local doc_count=$(
    sqlite3 "${KB_NAME}.db" \
      "SELECT COUNT(*) FROM documents"
  )
  echo "Imported $doc_count documents"
  
  # Generate statistics
  generate_import_stats
}

generate_import_stats() {
  sqlite3 "${KB_NAME}.db" << EOF
.mode column
.headers on

SELECT 
  COUNT(*) as total_documents,
  COUNT(DISTINCT author) as unique_authors,
  COUNT(DISTINCT document_type) as document_types,
  AVG(LENGTH(content)) as avg_doc_length,
  SUM(LENGTH(content)) as total_content_size
FROM documents;

SELECT 
  document_type,
  COUNT(*) as count
FROM documents
GROUP BY document_type
ORDER BY count DESC
LIMIT 10;
EOF
}
```

#### Output
- SQLite database with documents
- Chunk statistics
- Import report

### Stage 4: Embedding Generation

Creates vector embeddings for all document chunks.

#### Purpose
- Generate embeddings via OpenAI
- Build FAISS vector index
- Enable similarity search
- Optimize for production

#### Implementation
```bash
run_embedding_generation() {
  echo "Generating embeddings"
  
  # Configure for production
  customkb config "$KB_NAME" \
    --set "vector_model=$EMBEDDING_MODEL" \
    --set "batch_size=$BATCH_SIZE" \
    --set "use_gpu=true"
  
  # Generate embeddings with progress
  customkb embed "$KB_NAME" \
    --show-progress \
    --resume \
    --checkpoint-interval 1000
  
  # Build BM25 index for hybrid search
  if [[ "$ENABLE_HYBRID_SEARCH" == "1" ]]; then
    customkb bm25 "$KB_NAME"
  fi
  
  # Optimize index
  customkb optimize "$KB_NAME" \
    --tier aggressive \
    --compress-index
  
  # Verify embeddings
  verify_embeddings
}

verify_embeddings() {
  local total_chunks=$(
    sqlite3 "${KB_NAME}.db" \
      "SELECT COUNT(*) FROM chunks"
  )
  
  local embedded_chunks=$(
    sqlite3 "${KB_NAME}.db" \
      "SELECT COUNT(*) FROM chunks WHERE embedding_id IS NOT NULL"
  )
  
  echo "Embedded $embedded_chunks of $total_chunks chunks"
  
  if [[ $embedded_chunks -ne $total_chunks ]]; then
    echo "WARNING: Not all chunks have embeddings!"
    return 1
  fi
}
```

#### Output
- FAISS index file
- BM25 index (optional)
- Embedding statistics
- Performance metrics

### Stage 5: Testing & Validation

Validates the knowledgebase with test queries.

#### Purpose
- Test query accuracy
- Measure response times
- Validate content coverage
- Generate quality report

#### Implementation
```bash
run_testing() {
  echo "Running validation tests"
  
  # Create test results directory
  mkdir -p test_results
  
  # Run test queries
  local test_num=0
  for query in "${TEST_QUERIES[@]}"; do
    ((test_num++))
    test_query "$test_num" "$query"
  done
  
  # Run coverage tests
  test_coverage
  
  # Performance benchmarks
  run_benchmarks
  
  # Generate report
  generate_test_report
}

test_query() {
  local num=$1
  local query=$2
  local output="test_results/test_${num}.json"
  
  echo "Test $num: $query"
  
  # Time the query
  local start_time=$(date +%s.%N)
  
  customkb query "$KB_NAME" "$query" \
    --format json \
    --top-k 20 \
    > "$output"
  
  local end_time=$(date +%s.%N)
  local elapsed=$(echo "$end_time - $start_time" | bc)
  
  # Validate response
  local response=$(jq -r .response "$output")
  local score=$(calculate_quality_score "$response" "$query")
  
  echo "Elapsed: ${elapsed}s, Score: $score"
  
  # Store results
  jq --arg elapsed "$elapsed" \
     --arg score "$score" \
     '. + {elapsed: $elapsed, score: $score}' \
     "$output" > "${output}.tmp" && \
     mv "${output}.tmp" "$output"
}

test_coverage() {
  echo "Testing knowledge coverage"
  
  # Test document types
  for doc_type in "Company Formation" "Immigration" "Taxation"; do
    local count=$(
      customkb query "$KB_NAME" \
        "information about $doc_type" \
        --context-only | \
        grep -c "$doc_type"
    )
    echo "$doc_type coverage: $count references"
  done
}

run_benchmarks() {
  echo "Running performance benchmarks"
  
  # Concurrent queries
  seq 1 10 | parallel -j 10 \
    "customkb query $KB_NAME 'test query {}' > /dev/null"
  
  # Large context retrieval
  time customkb query "$KB_NAME" \
    "comprehensive overview" \
    --top-k 100 \
    --context-only > /dev/null
}
```

#### Test Report
```markdown
# Knowledgebase Validation Report

## Summary
- Total documents: 3,651
- Total chunks: 45,230
- Index size: 125.4 MB
- Build time: 2h 35m

## Test Results

### Query Tests
1. "What is a PMA company?" - 0.92/1.0 (1.3s)
2. "Requirements for work permit" - 0.88/1.0 (1.5s)
3. "Tax obligations" - 0.91/1.0 (1.4s)

### Coverage Tests
- Company Formation: 847 references
- Immigration: 623 references
- Taxation: 492 references

### Performance
- Average query time: 1.4s
- 95th percentile: 2.1s
- Concurrent capacity: 50 qps
```

## Running the Pipeline

### Full Build

```bash
# Run all stages
./0_build.sh -a -y

# Run with custom config
./0_build.sh -c custom.build.conf -a

# Verbose output
./0_build.sh -v -a
```

### Individual Stages

```bash
# Run specific stage
./0_build.sh -0  # Text extraction only
./0_build.sh -4  # Embeddings only

# Skip stages
./0_build.sh -a --skip 1,2  # Skip citation stages

# Force re-run
./0_build.sh -4 --force  # Force embedding regeneration
```

### Options

```bash
Usage: ./0_build.sh [OPTIONS]

Options:
  -0 to -5    Run specific stage
  -a          Run all stages
  -y          Non-interactive mode
  -v          Verbose output
  -c FILE     Use custom config
  --skip N,M  Skip stages N,M
  --force     Force re-run
  --dry-run   Show what would be done
  -h          Show help
```

## Monitoring Progress

### Log Files

```bash
# Main build log
tail -f logs/build_$(date +%Y%m%d).log

# Stage-specific logs
tail -f logs/stage_1_citations.log
tail -f logs/stage_4_embeddings.log

# Error log
tail -f logs/errors.log
```

### Progress Indicators

```bash
# Citation progress
watch -n 1 'sqlite3 citations.db "SELECT COUNT(*) FROM citations"'

# Embedding progress
watch -n 1 'customkb stats okusiassociates | grep Embedded'

# Disk usage
watch -n 1 'du -sh embed_data.text citations *.db *.index'
```

## Error Recovery

### Resuming Failed Builds

```bash
# Check last completed stage
cat .build_state

# Resume from last stage
./0_build.sh --resume

# Resume specific stage
./0_build.sh -4 --resume
```

### Handling Failures

```bash
# Retry failed citations
./retry_failed_citations.sh

# Fix corrupted index
customkb repair okusiassociates

# Rebuild from checkpoint
./0_build.sh --from-checkpoint
```

## Optimization Tips

### Parallel Processing

```bash
# Optimize for CPU cores
PARALLEL_JOBS=$(nproc --all)

# Monitor CPU usage
htop

# Adjust batch size
BATCH_SIZE=$(($(nproc) * 10))
```

### Memory Management

```bash
# Monitor memory
watch -n 1 free -h

# Limit memory usage
ulimit -v 16000000  # 16GB

# Use swap for large builds
sudo swapon /swapfile
```

### Disk I/O

```bash
# Use fast storage
VECTORDBS="/ssd/vectordbs"

# Monitor I/O
iotop

# Compress intermediate files
gzip embed_data.text/*.txt
```

## Production Deployment

### Pre-deployment Checklist

```bash
#!/bin/bash
# pre_deploy_check.sh

echo "Pre-deployment checklist:"

# Size checks
echo -n "Database size: "
du -h okusiassociates.db

echo -n "Index size: "
du -h okusiassociates.index

# Quality checks
echo -n "Document count: "
sqlite3 okusiassociates.db "SELECT COUNT(*) FROM documents"

echo -n "Embedding coverage: "
customkb verify okusiassociates

# Performance test
echo "Query performance:"
time customkb query okusiassociates "test query"

# Security check
echo "Checking permissions:"
ls -la okusiassociates.*
```

### Deployment Script

```bash
#!/bin/bash
# deploy.sh

PROD_HOST="production.server"
PROD_PATH="/var/lib/vectordbs"

# Sync knowledgebase
rsync -avz --progress \
  okusiassociates.db \
  okusiassociates.index \
  okusiassociates.cfg \
  $PROD_HOST:$PROD_PATH/

# Verify deployment
ssh $PROD_HOST "customkb verify okusiassociates"

# Update API
ssh $PROD_HOST "systemctl restart kb-api"
```

## Best Practices

1. **Always test locally first**
   - Use subset of documents
   - Validate each stage output
   - Check resource usage

2. **Monitor resource usage**
   - CPU, memory, disk I/O
   - API rate limits
   - Cost tracking

3. **Implement checkpoints**
   - Save state between stages
   - Enable resume capability
   - Regular backups

4. **Validate thoroughly**
   - Test diverse queries
   - Check edge cases
   - Measure performance

5. **Document everything**
   - Configuration choices
   - Custom modifications
   - Known issues

## Troubleshooting

See [Troubleshooting Guide](./TROUBLESHOOTING.md) for common issues.

Key areas:
- Citation generation failures
- Embedding API errors
- Memory/disk issues
- Index corruption
- Performance problems

#fin