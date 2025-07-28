# KB-Query Examples

This directory contains practical examples for using YaTTI CustomKB components.

## Directory Structure

```
examples/
├── README.md                    # This file
├── basic-queries/              # Simple query examples
├── advanced-queries/           # Complex query patterns
├── building-kb/               # Knowledgebase creation examples
├── api-integration/           # API usage in various languages
├── configuration/             # Configuration examples
└── scripts/                   # Automation scripts
```

## Quick Examples

### 1. Basic Query
```bash
kb-query appliedanthropology "What is dharma?"
```

### 2. Build Simple KB
```bash
cd building-kb/simple-kb
./build.sh
```

### 3. API Integration
```python
# Python example
from examples.api_integration.python import YaTTIClient

client = YaTTIClient("yatti_your_key")
response = client.query("okusiassociates", "PMA requirements")
print(response)
```

## Available Examples

### Basic Queries
- Simple questions
- Context-only retrieval
- Field selection
- Output formatting

### Advanced Queries
- Multi-parameter queries
- Reference integration
- Custom models
- Hybrid search

### Building Knowledgebases
- Minimal KB setup
- Production KB with citations
- Multi-language KB
- Domain-specific configurations

### API Integration
- Python client
- Node.js/JavaScript
- Shell scripts
- PHP integration

### Configuration
- Development setup
- Production optimization
- Multi-model configs
- Security hardening

### Scripts
- Batch processing
- Monitoring
- Backup/restore
- Performance testing

## Getting Started

1. Clone the repository
2. Navigate to examples directory
3. Choose an example that matches your use case
4. Follow the README in that subdirectory

Each example includes:
- Complete working code
- Configuration files
- Sample data (where applicable)
- Step-by-step instructions
- Expected output

#fin