#!/bin/bash
# Simple KB-Query Examples

# Set your API key
export YATTI_API_KEY="yatti_your_api_key_here"

echo "=== Basic KB-Query Examples ==="
echo

# 1. Simple query
echo "1. Simple query:"
kb-query appliedanthropology "What is dharma?"
echo

# 2. Query with specific fields
echo "2. Query with specific fields:"
kb-query okusiassociates "What is a PMA company?" .query .response
echo

# 3. Context-only query
echo "3. Context-only retrieval:"
kb-query -c jakartapost "latest technology news"
echo

# 4. List available knowledgebases
echo "4. Available knowledgebases:"
kb-query list
echo

# 5. Query with all fields
echo "5. All response fields:"
kb-query garydean "Tell me about Gary Dean" .
echo

# 6. Query with custom temperature
echo "6. Precise answer (low temperature):"
kb-query -t 0.1 okusiassociates "What are the exact requirements for a work permit?"
echo

# 7. Query with more context
echo "7. Query with more context chunks:"
kb-query -K 30 appliedanthropology "Explain Buddhist philosophy in detail"
echo

# 8. Quick fact checking
echo "8. Quick fact check:"
kb-query okusiassociates "Can foreigners own land in Indonesia?" .response
echo

# 9. Multiple queries in sequence
echo "9. Multiple related queries:"
for topic in "PMA company" "work permit" "taxation"; do
  echo "Topic: $topic"
  kb-query okusiassociates "Requirements for $topic" .response | head -3
  echo "..."
  echo
done

# 10. Save response to file
echo "10. Saving response to file:"
kb-query appliedanthropology "Comprehensive explanation of karma" > karma_explanation.txt
echo "Response saved to karma_explanation.txt"

#fin