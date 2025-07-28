#!/bin/bash
# Advanced KB-Query Examples

export YATTI_API_KEY="yatti_your_api_key_here"

echo "=== Advanced KB-Query Examples ==="
echo

# 1. Query with reference file
echo "1. Query with reference file:"
cat > context.txt << EOF
Our company has:
- 5 foreign shareholders (60% ownership)
- 2 local shareholders (40% ownership)
- Capital of USD 1 million
- Plan to operate in Jakarta
EOF

kb-query -r context.txt okusiassociates \
  "What type of company should we establish and what are the requirements?"
rm context.txt
echo

# 2. Query with inline reference
echo "2. Query with inline reference:"
kb-query -R "We need to import medical equipment and devices from Germany" \
  okusiassociates "What licenses and permits do we need?"
echo

# 3. Multi-parameter advanced query
echo "3. Advanced multi-parameter query:"
kb-query \
  --query-model gpt-4 \
  --query-temperature 0.2 \
  --query-top-k 50 \
  --query-context-format xml \
  --similarity-threshold 0.4 \
  okusiassociates \
  "Provide a detailed analysis of tax obligations for PMA companies"
echo

# 4. Hybrid search query
echo "4. Hybrid search with custom weights:"
kb-query \
  --hybrid-search \
  --hybrid-search-weight 0.8 \
  okusiassociates \
  "foreign investment negative list 2024"
echo

# 5. Query with reranking
echo "5. Query with reranking for better accuracy:"
kb-query \
  --reranking \
  --reranking-model cross-encoder/ms-marco-MiniLM-L-12-v2 \
  appliedanthropology \
  "Compare Theravada and Mahayana Buddhist meditation practices"
echo

# 6. Custom system role query
echo "6. Query with custom system role:"
kb-query \
  --query-system-role "You are a tax expert specializing in Indonesian corporate taxation" \
  --query-temperature 0.3 \
  okusiassociates \
  "Explain the tax implications of dividend distribution from PMA to foreign shareholders"
echo

# 7. Analytical query with specific format
echo "7. Analytical query with custom prompt style:"
kb-query \
  --query-prompt-style analytical \
  --query-response-template "Provide a structured analysis with pros, cons, and recommendations" \
  okusiassociates \
  "Should we establish a PMA or Representative Office?"
echo

# 8. Batch processing with different models
echo "8. Comparing responses from different models:"
for model in "gpt-4o-mini" "gpt-4" "claude-3-haiku-20240307"; do
  echo "Model: $model"
  kb-query -m "$model" okusiassociates \
    "What is the minimum capital requirement for PMA?" .response | head -2
  echo
done

# 9. Performance testing query
echo "9. Performance test with timing:"
time kb-query \
  --timeout 60 \
  --query-top-k 100 \
  --context-only \
  okusiassociates \
  "comprehensive information about Indonesian business regulations" > /dev/null
echo

# 10. Complex JSON processing
echo "10. Complex JSON output processing:"
kb-query --format json okusiassociates "PMA vs PT comparison" | \
  jq '{
    query: .query,
    model: .metadata.model_used,
    chunks: .metadata.chunks_retrieved,
    summary: (.response | split("\n")[0]),
    time: .elapsed_seconds
  }'

#fin