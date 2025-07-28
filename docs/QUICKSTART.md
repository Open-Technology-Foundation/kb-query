# YaTTI CustomKB Quick Start Guide

Get up and running with YaTTI CustomKB in 15 minutes!

## What You'll Learn

- Query existing knowledgebases in 2 minutes
- Build your first knowledgebase in 10 minutes
- Make your first API calls

## Prerequisites

- Ubuntu 24.04 LTS
- 10 minutes of time
- OpenAI API key (for building knowledgebases)

## Part 1: Query Existing Knowledgebases (2 minutes)

### 1. Install KB-Query

```bash
# Install dependencies
sudo apt update
sudo apt install -y git curl jq gridsite-clients

# Install kb-query
cd /tmp && git clone https://github.com/Open-Technology-Foundation/kb-query.git && sudo kb-query/kb-query.install
```

### 2. Get an API Key

Contact the administrator to obtain a YaTTI API key.

### 3. Set Your API Key

```bash
export YATTI_API_KEY="yatti_your_api_key_here"
```

### 4. Make Your First Query!

```bash
# List available knowledgebases
kb-query list

# Query a knowledgebase
kb-query appliedanthropology "What is dharma?"

# Try another one
kb-query okusiassociates "How do I start a company in Indonesia?"
```

That's it! You're now querying AI-powered knowledgebases.

## Part 2: Build Your Own Knowledgebase (10 minutes)

### 1. Install CustomKB

```bash
# Navigate to customkb directory
cd /tmp/kb-query/customkb

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Setup NLTK data
sudo ./setup/nltk_setup.py download cleanup
```

### 2. Set Environment Variables

```bash
# Required: OpenAI API key
export OPENAI_API_KEY="sk-your-openai-api-key"

# Set knowledgebase storage location
export VECTORDBS="/tmp/my_knowledgebases"
mkdir -p $VECTORDBS
```

### 3. Create Your First Knowledgebase

```bash
# Create a test knowledgebase directory
mkdir -p $VECTORDBS/quickstart
cd $VECTORDBS/quickstart

# Create a sample document
cat > documents.md << 'EOF'
# Welcome to QuickStart KB

This is a demonstration knowledgebase for the YaTTI CustomKB system.

## About YaTTI

YaTTI (Yet another Text-To-Intelligence) is an AI-powered system that transforms documents into intelligent, queryable knowledgebases.

## Features

- **Smart Search**: Find information by meaning, not just keywords
- **AI Responses**: Get intelligent answers to your questions
- **Fast Setup**: Build a knowledgebase in minutes
- **Scalable**: Handle thousands of documents

## Use Cases

1. **Documentation**: Convert technical docs into Q&A systems
2. **Customer Support**: Instant answers from FAQs and guides
3. **Research**: Query academic papers and reports
4. **Compliance**: Navigate regulations and policies

## Getting Help

For more information, visit the full documentation or contact support.
EOF

# Create configuration
cat > quickstart.cfg << 'EOF'
[DEFAULT]
vector_model = text-embedding-3-small
query_model = gpt-4o-mini
query_temperature = 0.7

[ALGORITHMS]
enable_hybrid_search = false
similarity_threshold = 0.3
EOF
```

### 4. Build the Knowledgebase

```bash
# Process the document
customkb database quickstart documents.md

# Generate embeddings
customkb embed quickstart

# Your knowledgebase is ready!
```

### 5. Query Your Knowledgebase

```bash
# Ask questions about your content
customkb query quickstart "What is YaTTI?"
customkb query quickstart "What are the main features?"
customkb query quickstart "How can I use this for customer support?"
```

## Part 3: Advanced Examples (3 minutes)

### Multiple Documents

```bash
# Add more documents
cat > features.md << 'EOF'
# Advanced Features

## Hybrid Search
Combines vector similarity with keyword matching for better results.

## Multi-Model Support
- OpenAI: GPT-4, GPT-3.5
- Anthropic: Claude models
- Google: Gemini models
- Local: Ollama integration

## Performance Optimization
- GPU acceleration
- Batch processing
- Intelligent caching
EOF

# Update the database
customkb database quickstart features.md

# Regenerate embeddings for new content
customkb embed quickstart

# Query the expanded knowledge
customkb query quickstart "What models are supported?"
```

### Different Query Styles

```bash
# Precise factual answer
customkb query quickstart "List all supported AI models" \
  --temperature 0.1 --top-k 10

# Creative explanation
customkb query quickstart "Explain hybrid search like I'm five" \
  --temperature 0.9

# Just get the context
customkb query quickstart "GPU acceleration" --context-only
```

### Using the API

```bash
# Direct API call
curl -H "Authorization: Bearer $YATTI_API_KEY" \
     "https://yatti.id/v1/index.php/appliedanthropology?q=What%20is%20karma"

# With kb-query wrapper
kb-query appliedanthropology "What is karma?" .response
```

## Quick Tips

### 1. Choosing Models

**For Most Cases:**
- Embedding: `text-embedding-3-small` (fast, accurate)
- Query: `gpt-4o-mini` (good balance of speed/quality)

**For Best Quality:**
- Embedding: `text-embedding-3-large`
- Query: `gpt-4` or `claude-3-opus`

### 2. Document Preparation

Good documents have:
- Clear headings and structure
- Descriptive content
- Consistent formatting

### 3. Testing Queries

Always test with various question types:
- Factual: "What is X?"
- Procedural: "How do I Y?"
- Analytical: "Why does Z happen?"
- Comparative: "Difference between A and B?"

## Next Steps

Now that you've got the basics:

1. **Read the full documentation:**
   - [KB-Query Usage Guide](./KB-QUERY-USAGE.md) - Advanced CLI usage
   - [CustomKB Usage Guide](./CUSTOMKB-USAGE.md) - Building production KBs
   - [API Documentation](./API-DOCUMENTATION.md) - Direct API integration

2. **Explore real examples:**
   - Check out `/ai/scripts/kb-query/okusiassociates/` for a production KB
   - See configuration examples in `customkb/config/`

3. **Build something real:**
   - Convert your documentation
   - Create a support bot
   - Build a research assistant

## Common Issues

### "API key not set"
```bash
export YATTI_API_KEY="yatti_your_key_here"
# Or for CustomKB:
export OPENAI_API_KEY="sk-your-key"
```

### "Command not found"
```bash
# Make sure kb-query is in PATH
which kb-query
# If not found, check installation:
ls -la /usr/local/bin/kb-query
```

### "No module named 'openai'"
```bash
# Activate virtual environment
source /tmp/kb-query/customkb/.venv/bin/activate
# Verify installation
pip list | grep openai
```

### Slow embedding generation
- Normal for first run
- Use `--batch-size 100` for larger datasets
- Consider GPU acceleration for production

## Getting Help

- **Issues/Bugs**: https://github.com/Open-Technology-Foundation/kb-query/issues
- **Documentation**: See `/ai/scripts/kb-query/docs/`
- **Examples**: Check `okusiassociates/` directory

---

**Congratulations!** 🎉 You've successfully:
- ✅ Queried existing knowledgebases
- ✅ Built your own knowledgebase
- ✅ Made API calls
- ✅ Learned the basics of YaTTI CustomKB

Happy knowledge building!

#fin