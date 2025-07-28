#!/bin/bash
# Batch Query Processor
# Process multiple queries from a file and generate a report

set -euo pipefail

# Configuration
YATTI_API_KEY="${YATTI_API_KEY:-}"
KB_NAME="${1:-okusiassociates}"
QUERY_FILE="${2:-queries.txt}"
OUTPUT_DIR="batch_results_$(date +%Y%m%d_%H%M%S)"
PARALLEL_JOBS=5
DELAY_BETWEEN_QUERIES=0.5

# Check prerequisites
if [[ -z "$YATTI_API_KEY" ]]; then
    echo "Error: YATTI_API_KEY not set"
    exit 1
fi

if [[ ! -f "$QUERY_FILE" ]]; then
    echo "Error: Query file '$QUERY_FILE' not found"
    echo "Usage: $0 [knowledgebase] [query_file]"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create sample queries if none exist
if [[ ! -f "queries.txt" ]]; then
    cat > queries.txt << 'EOF'
What is a PMA company?
What are the requirements for a work permit?
Can foreigners own property in Indonesia?
What are the tax rates for companies?
How to register a business in Jakarta?
What licenses are needed for import/export?
What is the minimum wage regulation?
How to hire foreign employees?
What are the VAT regulations?
What is the company establishment timeline?
EOF
    echo "Created sample queries.txt"
fi

echo "=== Batch Query Processor ==="
echo "Knowledgebase: $KB_NAME"
echo "Query file: $QUERY_FILE"
echo "Output directory: $OUTPUT_DIR"
echo "Total queries: $(wc -l < "$QUERY_FILE")"
echo

# Function to process a single query
process_query() {
    local query="$1"
    local index="$2"
    local output_file="$OUTPUT_DIR/query_${index}.json"
    
    echo "[$(date +%H:%M:%S)] Processing query $index: ${query:0:50}..."
    
    # Execute query and save result
    if kb-query --format json "$KB_NAME" "$query" > "$output_file" 2>&1; then
        echo "[$(date +%H:%M:%S)] ✓ Query $index completed"
    else
        echo "[$(date +%H:%M:%S)] ✗ Query $index failed"
    fi
    
    # Rate limiting
    sleep "$DELAY_BETWEEN_QUERIES"
}

# Process queries in parallel
export -f process_query
export KB_NAME OUTPUT_DIR DELAY_BETWEEN_QUERIES

cat -n "$QUERY_FILE" | while IFS=$'\t' read -r index query; do
    # Trim whitespace
    query=$(echo "$query" | xargs)
    if [[ -n "$query" ]]; then
        echo "$index|$query"
    fi
done | parallel -j "$PARALLEL_JOBS" --colsep '|' process_query {2} {1}

echo
echo "=== Generating Report ==="

# Generate summary report
cat > "$OUTPUT_DIR/summary_report.md" << EOF
# Batch Query Report

**Date**: $(date)  
**Knowledgebase**: $KB_NAME  
**Total Queries**: $(wc -l < "$QUERY_FILE")  

## Query Results

| # | Query | Response Time | Status | Summary |
|---|-------|---------------|--------|---------|
EOF

# Process results
index=1
while IFS= read -r query; do
    query=$(echo "$query" | xargs)  # Trim whitespace
    if [[ -z "$query" ]]; then
        continue
    fi
    
    result_file="$OUTPUT_DIR/query_${index}.json"
    
    if [[ -f "$result_file" ]]; then
        # Extract data from JSON
        elapsed=$(jq -r '.elapsed_seconds // "N/A"' "$result_file" 2>/dev/null || echo "N/A")
        error=$(jq -r '.error // null' "$result_file" 2>/dev/null || echo "null")
        response=$(jq -r '.response // ""' "$result_file" 2>/dev/null || echo "")
        
        # Determine status
        if [[ "$error" != "null" ]]; then
            status="❌ Failed"
            summary="Error: $error"
        else
            status="✅ Success"
            # Get first line of response as summary
            summary=$(echo "$response" | head -1 | cut -c1-50)
            if [[ ${#summary} -eq 50 ]]; then
                summary="${summary}..."
            fi
        fi
        
        # Add to report
        echo "| $index | ${query:0:50}... | ${elapsed}s | $status | $summary |" >> "$OUTPUT_DIR/summary_report.md"
    else
        echo "| $index | ${query:0:50}... | N/A | ❌ Missing | No result file |" >> "$OUTPUT_DIR/summary_report.md"
    fi
    
    ((index++))
done < "$QUERY_FILE"

# Add statistics
cat >> "$OUTPUT_DIR/summary_report.md" << EOF

## Statistics

EOF

# Calculate statistics
total_queries=$(wc -l < "$QUERY_FILE")
successful=$(find "$OUTPUT_DIR" -name "query_*.json" -exec grep -L '"error"' {} \; | wc -l)
failed=$((total_queries - successful))
avg_time=$(find "$OUTPUT_DIR" -name "query_*.json" -exec jq -r '.elapsed_seconds // 0' {} \; | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')

cat >> "$OUTPUT_DIR/summary_report.md" << EOF
- **Total Queries**: $total_queries
- **Successful**: $successful
- **Failed**: $failed
- **Success Rate**: $(awk "BEGIN {printf \"%.1f\", $successful/$total_queries*100}")%
- **Average Response Time**: ${avg_time}s

## Detailed Results

Individual query results are available in:
- JSON format: \`$OUTPUT_DIR/query_*.json\`
- This summary: \`$OUTPUT_DIR/summary_report.md\`
EOF

# Generate CSV for analysis
echo "query_id,query_text,response_time,status,response_length" > "$OUTPUT_DIR/results.csv"

index=1
while IFS= read -r query; do
    query=$(echo "$query" | xargs)
    if [[ -z "$query" ]]; then
        continue
    fi
    
    result_file="$OUTPUT_DIR/query_${index}.json"
    if [[ -f "$result_file" ]]; then
        elapsed=$(jq -r '.elapsed_seconds // 0' "$result_file" 2>/dev/null || echo "0")
        error=$(jq -r '.error // null' "$result_file" 2>/dev/null || echo "null")
        response_length=$(jq -r '.response // "" | length' "$result_file" 2>/dev/null || echo "0")
        status=$([[ "$error" == "null" ]] && echo "success" || echo "failed")
        
        echo "$index,\"$query\",$elapsed,$status,$response_length" >> "$OUTPUT_DIR/results.csv"
    fi
    
    ((index++))
done < "$QUERY_FILE"

# Show summary
echo
echo "=== Processing Complete ==="
echo "Results saved to: $OUTPUT_DIR/"
echo
echo "Files generated:"
echo "  - summary_report.md : Human-readable report"
echo "  - results.csv       : CSV for analysis"
echo "  - query_*.json      : Individual query results"
echo
echo "Quick stats:"
echo "  - Success rate: $(awk "BEGIN {printf \"%.1f\", $successful/$total_queries*100}")%"
echo "  - Average time: ${avg_time}s"
echo "  - Total time: $(find "$OUTPUT_DIR" -name "query_*.json" -exec jq -r '.elapsed_seconds // 0' {} \; | awk '{sum+=$1} END {printf "%.1f", sum}')s"

# Display report preview
echo
echo "=== Report Preview ==="
head -20 "$OUTPUT_DIR/summary_report.md"
echo "..."
echo
echo "View full report: less $OUTPUT_DIR/summary_report.md"

#fin