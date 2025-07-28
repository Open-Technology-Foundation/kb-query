# KB-Query CLI Usage Guide

## Overview

`kb-query` is a command-line interface for querying YaTTI CustomKB knowledgebases via the API. It provides a simple wrapper around curl commands with built-in authentication, parameter handling, and response formatting.

## Installation

### Prerequisites

- Ubuntu 24.04 LTS
- Required packages:
  ```bash
  sudo apt install git curl jq gridsite-clients
  ```

### Quick Install

```bash
cd /tmp && git clone https://github.com/Open-Technology-Foundation/kb-query.git && sudo kb-query/kb-query.install
```

### Manual Installation

```bash
git clone https://github.com/Open-Technology-Foundation/kb-query.git
cd kb-query
sudo ./kb-query.install
```

The installer:
- Copies files to `/usr/share/kb-query/`
- Creates symlink at `/usr/local/bin/kb-query`
- Sets up bash completion (if supported)

## Authentication

KB-Query requires API authentication. Set your API key using one of these methods:

### Method 1: Environment Variable (Recommended)
```bash
export YATTI_API_KEY="yatti_your_api_key_here"
```

### Method 2: Configuration File
```bash
mkdir -p ~/.config/kb-query
echo 'YATTI_API_KEY="yatti_your_api_key_here"' > ~/.config/kb-query/config
chmod 600 ~/.config/kb-query/config
```

### Method 3: Command Line
```bash
kb-query -k "yatti_your_api_key_here" appliedanthropology "your query"
```

## Basic Usage

### Query a Knowledgebase

```bash
kb-query {knowledgebase} "{query}" [fields...]
```

Examples:
```bash
# Simple query (returns response only)
kb-query appliedanthropology "What is dharma?"

# Query with specific fields
kb-query okusiassociates "How to set up a PMA company?" .query .response

# All fields
kb-query garydean "Tell me about Gary Dean" .
```

### Available Commands

```bash
# List all available knowledgebases
kb-query list

# Show help
kb-query help

# Update kb-query
kb-query update

# Show version
kb-query --version
```

## Command Options

### Query Options

| Option | Description | Example |
|--------|-------------|---------|
| `-c, --context-only` | Return context only, no LLM processing | `kb-query -c okusiassociates "PMA requirements"` |
| `-r, --reference-file FILE` | Include reference file content | `kb-query -r context.txt appliedanthropology "Explain this"` |
| `-R, --reference-str TEXT` | Include reference text | `kb-query -R "Context text" garydean "What does this mean?"` |
| `-m, --query-model MODEL` | LLM model to use | `kb-query -m gpt-4 okusiassociates "Complex question"` |
| `-t, --query-temperature NUM` | Response creativity (0-1) | `kb-query -t 0.1 appliedanthropology "Precise answer needed"` |
| `-T, --query-max-tokens NUM` | Max response tokens | `kb-query -T 4000 garydean "Long explanation"` |
| `-k, --api-key KEY` | API key (overrides env) | `kb-query -k yatti_123 list` |
| `--timeout SEC` | API timeout seconds | `kb-query --timeout 60 okusiassociates "Complex query"` |

### Query Processing Options

| Option | Description | Example |
|--------|-------------|---------|
| `-K, --query-top-k NUM` | Number of context chunks | `kb-query -K 20 appliedanthropology "Detailed topic"` |
| `-C, --query-context-scope NUM` | Context scope | `kb-query -C 5 okusiassociates "Specific question"` |
| `-F, --query-context-format FMT` | Context format (xml/json/markdown) | `kb-query -F json garydean "Query"` |
| `-p, --query-prompt-style STYLE` | Prompt style | `kb-query -p scholarly appliedanthropology "Academic question"` |
| `-P, --query-response-template TPL` | Response template | `kb-query -P analytical okusiassociates "Analysis needed"` |
| `-s, --query-system-role ROLE` | System role | `kb-query -s "Tax expert" okusiassociates "Tax question"` |

### Output Options

| Option | Description | Example |
|--------|-------------|---------|
| `--raw` | Raw JSON output | `kb-query --raw appliedanthropology "Query" \| jq .` |
| `--format FORMAT` | Output format (text/json/pretty) | `kb-query --format pretty garydean "Query"` |
| `--no-color` | Disable colored output | `kb-query --no-color list` |
| `--quiet` | Suppress non-essential output | `kb-query --quiet okusiassociates "Query" > result.txt` |

### Advanced Options

| Option | Description | Example |
|--------|-------------|---------|
| `--similarity-threshold NUM` | Similarity threshold (0-1) | `kb-query --similarity-threshold 0.5 appliedanthropology "Query"` |
| `--hybrid-search` | Enable hybrid search | `kb-query --hybrid-search okusiassociates "Complex topic"` |
| `--hybrid-search-weight NUM` | Hybrid search weight | `kb-query --hybrid-search-weight 0.8 garydean "Query"` |
| `--reranking` | Enable reranking | `kb-query --reranking appliedanthropology "Important query"` |
| `--reranking-model MODEL` | Reranking model | `kb-query --reranking-model cross-encoder/ms-marco-MiniLM-L-12-v2 okusiassociates "Query"` |
| `--embedding-prefix TEXT` | Embedding prefix | `kb-query --embedding-prefix "search_query: " appliedanthropology "Query"` |

## Response Fields

The API returns JSON with these fields:

| Field | Description |
|-------|-------------|
| `.kb` | Knowledgebase name |
| `.query` | Original query text |
| `.context_only` | Whether context-only mode was used |
| `.reference` | Reference text (if provided) |
| `.response` | LLM response (main output) |
| `.elapsed_seconds` | Processing time |
| `.error` | Error message (if any) |

## Configuration

### Configuration File Location

- User config: `~/.config/kb-query/config`
- System config: `/etc/kb-query/config`

### Configuration Options

```bash
# ~/.config/kb-query/config
YATTI_API_KEY="yatti_your_api_key_here"
API_TIMEOUT=30
OUTPUT_FORMAT=text
MAX_REFERENCE_SIZE=4000
DEFAULT_QUERY_MODEL="gpt-4o-mini"
DEFAULT_QUERY_TEMPERATURE=0.7
```

### Cache and Data Directories

- Cache: `~/.cache/kb-query/`
- Data: `~/.local/share/kb-query/`
- History: `~/.local/share/kb-query/history`

## Examples

### Basic Queries

```bash
# Simple question
kb-query appliedanthropology "What is dharma?"

# Business inquiry
kb-query okusiassociates "What are the requirements for a PMA company?"

# Context-only search
kb-query -c jakartapost "Latest news about technology"
```

### Advanced Queries

```bash
# Precise technical answer with GPT-4
kb-query -m gpt-4 -t 0.1 -K 30 okusiassociates \
  "Detailed requirements for work permit application"

# Academic response with context
kb-query -p scholarly -F xml appliedanthropology \
  "Compare Buddhist and Hindu concepts of dharma" .response .context

# Analysis with custom system role
kb-query -s "Legal expert" -P analytical okusiassociates \
  "Tax implications of PMA vs PT companies"
```

### Working with References

```bash
# Query with file reference
echo "Our company has 5 foreign shareholders" > context.txt
kb-query -r context.txt okusiassociates \
  "What type of company should we establish?"

# Query with inline reference
kb-query -R "We need to import medical equipment" okusiassociates \
  "What licenses are required?"
```

### Batch Processing

```bash
# Process multiple queries
while IFS= read -r query; do
  kb-query okusiassociates "$query" .response >> answers.txt
done < questions.txt

# Extract specific information
kb-query --format json appliedanthropology "Buddhism concepts" | \
  jq -r '.response' | grep -i "meditation"
```

## Error Handling

Common errors and solutions:

### Authentication Error
```
Error: Authentication required. Please set YATTI_API_KEY
```
Solution: Set your API key as shown in Authentication section

### Invalid Knowledgebase
```
Error: Knowledgebase 'xyz' not found
```
Solution: Use `kb-query list` to see available knowledgebases

### Timeout Error
```
Error: Request timed out
```
Solution: Increase timeout with `--timeout 60`

### Large Reference File
```
Error: Reference file too large (max 4000 characters)
```
Solution: Reduce file size or adjust MAX_REFERENCE_SIZE in config

## Performance Tips

1. **Use context-only mode** for faster responses when you don't need LLM processing:
   ```bash
   kb-query -c okusiassociates "visa requirements"
   ```

2. **Adjust top-k** for better results vs speed:
   ```bash
   kb-query -K 10 appliedanthropology "quick answer"  # Faster
   kb-query -K 50 appliedanthropology "detailed answer"  # More thorough
   ```

3. **Cache responses** for repeated queries:
   ```bash
   kb-query okusiassociates "common question" > cached_answer.txt
   ```

4. **Use appropriate models**:
   - `gpt-4o-mini`: Fast, good for simple queries
   - `gpt-4`: Best quality, slower
   - `claude-3-haiku`: Fast alternative
   - `claude-3-opus`: High quality alternative

## Troubleshooting

### Enable Debug Mode
```bash
kb-query -D appliedanthropology "test query"
```

### Check Configuration
```bash
kb-query config
```

### Test API Connection
```bash
kb-query test
```

### Common Issues

1. **SSL Certificate errors**: Update ca-certificates
   ```bash
   sudo apt update && sudo apt install ca-certificates
   ```

2. **JSON parsing errors**: Ensure jq is installed
   ```bash
   sudo apt install jq
   ```

3. **Permission denied**: Check file permissions
   ```bash
   chmod 600 ~/.config/kb-query/config
   ```

## Integration

### Shell Scripts
```bash
#!/bin/bash
# Query and process response
response=$(kb-query appliedanthropology "What is karma?" .response)
echo "Answer: $response"
```

### Python Integration
```python
import subprocess
import json

def query_kb(kb, question):
    cmd = ['kb-query', '--format', 'json', kb, question]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(result.stdout)

answer = query_kb('okusiassociates', 'PMA requirements')
print(answer['response'])
```

### Cron Jobs
```bash
# Daily report generation
0 9 * * * kb-query okusiassociates "Daily compliance checklist" > /var/reports/daily_$(date +\%Y\%m\%d).txt
```

## Best Practices

1. **Always quote queries** to handle spaces and special characters
2. **Use appropriate temperature** - Lower (0.1-0.3) for facts, higher (0.7-0.9) for creative responses
3. **Select specific fields** to reduce output size and processing
4. **Handle errors gracefully** in scripts with proper exit code checking
5. **Respect rate limits** - Avoid excessive concurrent requests
6. **Secure your API key** - Never commit to version control

## See Also

- [CustomKB Usage Guide](./CUSTOMKB-USAGE.md) - Building knowledgebases
- [API Documentation](./API-DOCUMENTATION.md) - Direct API usage
- [Configuration Guide](./CONFIGURATION-GUIDE.md) - Detailed config options

#fin