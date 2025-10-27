# YaTTI CustomKB API Documentation

## Overview

The YaTTI CustomKB API provides RESTful endpoints for querying AI-powered knowledgebases. The API is accessible at `https://yatti.id/v1/index.php/` and requires authentication for most operations.

## Base URL

```
https://yatti.id/v1/index.php/
```

## Authentication

The API uses API key authentication. Include your API key in request headers using one of these methods:

### Bearer Token (Recommended)
```bash
Authorization: Bearer yatti_your_api_key_here
```

### X-API-Key Header
```bash
X-API-Key: yatti_your_api_key_here
```

### Example
```bash
curl -H "Authorization: Bearer yatti_your_api_key_here" \
     "https://yatti.id/v1/index.php/appliedanthropology?q=What%20is%20dharma"
```

## Endpoints

### 1. Query Knowledgebase

Query a specific knowledgebase with optional LLM processing.

#### Endpoint
```
GET /v1/index.php/{knowledgebase}
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | The query text (URL encoded) |
| `context_only` | boolean | No | If set, returns only context without LLM processing |
| `reference` | string | No | Additional reference text for context |
| `model` | string | No | LLM model to use (overrides default) |
| `temperature` | float | No | Response creativity (0.0-1.0) |
| `max_tokens` | integer | No | Maximum response tokens |
| `top_k` | integer | No | Number of context chunks to retrieve |
| `context_format` | string | No | Format for context (xml/json/markdown) |
| `prompt_style` | string | No | Style of prompt (default/instructive/scholarly/analytical/conversational) |
| `system_role` | string | No | Custom system role for LLM |
| `similarity_threshold` | float | No | Minimum similarity score (0.0-1.0) |
| `hybrid_search` | boolean | No | Enable hybrid search |
| `hybrid_search_weight` | float | No | Weight for hybrid search (0.0-1.0) |
| `reranking` | boolean | No | Enable result reranking |
| `embedding_prefix` | string | No | Prefix for embedding generation |

#### Request Example
```bash
curl -H "Authorization: Bearer yatti_api_key" \
     "https://yatti.id/v1/index.php/okusiassociates?q=What%20are%20PMA%20requirements&top_k=20&temperature=0.3"
```

#### Response Format
```json
{
  "kb": "okusiassociates",
  "query": "What are PMA requirements",
  "context_only": false,
  "reference": null,
  "response": "A PMA (Penanaman Modal Asing) company in Indonesia requires...",
  "elapsed_seconds": 2.34,
  "error": null,
  "metadata": {
    "model_used": "gpt-4o-mini",
    "chunks_retrieved": 20,
    "chunks_used": 15,
    "total_tokens": 1250
  }
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `kb` | string | Knowledgebase name |
| `query` | string | Original query text |
| `context_only` | boolean | Whether context-only mode was used |
| `reference` | string/null | Reference text if provided |
| `response` | string | LLM response or context |
| `elapsed_seconds` | float | Processing time |
| `error` | string/null | Error message if any |
| `metadata` | object | Additional processing information |

### 2. List Knowledgebases

Get a list of all available knowledgebases.

#### Endpoint
```
GET /v1/index.php/list
```

#### Request Example
```bash
curl "https://yatti.id/v1/index.php/list"
```

#### Response Format
```json
{
  "knowledgebases": [
    {
      "name": "appliedanthropology",
      "description": "Applied Anthropology knowledgebase",
      "document_count": 245,
      "last_updated": "2024-01-15T10:30:00Z",
      "status": "active"
    },
    {
      "name": "okusiassociates",
      "description": "Indonesian business consultancy knowledge",
      "document_count": 3651,
      "last_updated": "2024-01-20T08:45:00Z",
      "status": "active"
    }
  ],
  "count": 11,
  "api_version": "1.0"
}
```

### 3. API Help

Get API documentation and usage information.

#### Endpoint
```
GET /v1/index.php/help
```

#### Request Example
```bash
curl "https://yatti.id/v1/index.php/help"
```

#### Response Format
```json
{
  "api_version": "1.0",
  "endpoints": {
    "query": {
      "method": "GET",
      "path": "/v1/index.php/{knowledgebase}",
      "description": "Query a knowledgebase",
      "parameters": {...}
    },
    "list": {
      "method": "GET",
      "path": "/v1/index.php/list",
      "description": "List available knowledgebases"
    }
  },
  "authentication": "API key required in Authorization or X-API-Key header",
  "rate_limits": {
    "requests_per_minute": 60,
    "requests_per_hour": 1000
  }
}
```

### 4. Knowledgebase Information

Get detailed information about a specific knowledgebase.

#### Endpoint
```
GET /v1/index.php/{knowledgebase}/info
```

#### Request Example
```bash
curl -H "Authorization: Bearer yatti_api_key" \
     "https://yatti.id/v1/index.php/okusiassociates/info"
```

#### Response Format
```json
{
  "name": "okusiassociates",
  "description": "Indonesian business consultancy knowledgebase",
  "statistics": {
    "document_count": 3651,
    "total_chunks": 45230,
    "index_size_mb": 125.4,
    "last_updated": "2024-01-20T08:45:00Z",
    "query_count_today": 342,
    "average_response_time": 1.8
  },
  "configuration": {
    "default_model": "gpt-4o-mini",
    "embedding_model": "text-embedding-3-small",
    "chunk_size": 500,
    "hybrid_search_enabled": true,
    "reranking_enabled": false
  },
  "supported_languages": ["en", "id"],
  "topics": [
    "Company Formation",
    "Immigration",
    "Taxation",
    "Permits & Licenses",
    "Labor Law"
  ]
}
```

## Error Handling

### Error Response Format
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": "Additional error details if available"
  },
  "kb": "knowledgebase_name",
  "query": "original_query",
  "elapsed_seconds": 0.05
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid API key |
| `FORBIDDEN` | 403 | API key lacks permission |
| `NOT_FOUND` | 404 | Knowledgebase not found |
| `INVALID_QUERY` | 400 | Query parameter missing or invalid |
| `RATE_LIMITED` | 429 | Rate limit exceeded |
| `TIMEOUT` | 504 | Request processing timeout |
| `SERVER_ERROR` | 500 | Internal server error |
| `KB_UNAVAILABLE` | 503 | Knowledgebase temporarily unavailable |

### Error Examples

#### Authentication Error
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required. Please provide a valid API key.",
    "details": "Use Authorization: Bearer yatti_your_key or X-API-Key header"
  }
}
```

#### Invalid Knowledgebase
```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Knowledgebase 'invalid_kb' not found",
    "details": "Use /v1/list to see available knowledgebases"
  }
}
```

#### Rate Limit
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded",
    "details": "Limit: 60 requests per minute. Retry after: 45 seconds"
  },
  "retry_after": 45
}
```

## Rate Limiting

The API implements rate limiting to ensure fair usage:

- **Per Minute**: 60 requests
- **Per Hour**: 1,000 requests
- **Per Day**: 10,000 requests

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1642360800
```

## Best Practices

### 1. URL Encoding
Always URL encode query parameters:
```bash
# Good
curl "https://yatti.id/v1/index.php/kb?q=What%20is%20a%20%22PMA%22%20company%3F"

# Bad
curl "https://yatti.id/v1/index.php/kb?q=What is a "PMA" company?"
```

### 2. Error Handling
Always check for errors in responses:
```python
response = requests.get(url, headers=headers)
data = response.json()

if 'error' in data:
    print(f"Error: {data['error']['message']}")
else:
    print(f"Response: {data['response']}")
```

### 3. Timeout Handling
Set appropriate timeouts for long queries:
```python
response = requests.get(url, headers=headers, timeout=30)
```

### 4. Retry Logic
Implement exponential backoff for retries:
```python
import time
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()
retry = Retry(
    total=3,
    backoff_factor=0.5,
    status_forcelist=[500, 502, 503, 504]
)
adapter = HTTPAdapter(max_retries=retry)
session.mount('https://', adapter)
```

### 5. Caching
Cache responses for repeated queries:
```python
import hashlib
import json

def get_cache_key(kb, query):
    return hashlib.md5(f"{kb}:{query}".encode()).hexdigest()

cache = {}
cache_key = get_cache_key("okusiassociates", "PMA requirements")

if cache_key in cache:
    return cache[cache_key]
else:
    response = make_api_request(kb, query)
    cache[cache_key] = response
    return response
```

## Code Examples

### Python
```python
import requests
import urllib.parse

class YaTTIClient:
    def __init__(self, api_key):
        self.api_key = api_key
        self.base_url = "https://yatti.id/v1/index.php"
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Accept": "application/json"
        }
    
    def query(self, kb, question, **kwargs):
        params = {"q": question}
        params.update(kwargs)
        
        url = f"{self.base_url}/{kb}"
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        
        return response.json()
    
    def list_knowledgebases(self):
        response = requests.get(f"{self.base_url}/list")
        response.raise_for_status()
        return response.json()

# Usage
client = YaTTIClient("yatti_your_api_key")
result = client.query(
    "okusiassociates", 
    "What are PMA requirements?",
    top_k=20,
    temperature=0.3
)
print(result["response"])
```

### JavaScript/Node.js
```javascript
const axios = require('axios');

class YaTTIClient {
    constructor(apiKey) {
        this.apiKey = apiKey;
        this.baseUrl = 'https://yatti.id/v1/index.php';
    }
    
    async query(kb, question, options = {}) {
        const params = new URLSearchParams({ q: question, ...options });
        const response = await axios.get(
            `${this.baseUrl}/${kb}?${params}`,
            {
                headers: {
                    'Authorization': `Bearer ${this.apiKey}`,
                    'Accept': 'application/json'
                }
            }
        );
        return response.data;
    }
    
    async listKnowledgebases() {
        const response = await axios.get(`${this.baseUrl}/list`);
        return response.data;
    }
}

// Usage
const client = new YaTTIClient('yatti_your_api_key');
client.query('okusiassociates', 'PMA requirements', { top_k: 20 })
    .then(result => console.log(result.response))
    .catch(err => console.error(err));
```

### cURL Examples

#### Basic Query
```bash
curl -H "Authorization: Bearer yatti_api_key" \
     "https://yatti.id/v1/index.php/appliedanthropology?q=What%20is%20dharma"
```

#### Query with Options
```bash
curl -H "Authorization: Bearer yatti_api_key" \
     "https://yatti.id/v1/index.php/okusiassociates?q=Company%20formation%20process&top_k=30&temperature=0.2&model=gpt-4"
```

#### Context-Only Query
```bash
curl -H "Authorization: Bearer yatti_api_key" \
     "https://yatti.id/v1/index.php/jakartapost?q=Latest%20technology%20news&context_only=true"
```

#### With Reference Text
```bash
curl -H "Authorization: Bearer yatti_api_key" \
     -G "https://yatti.id/v1/index.php/okusiassociates" \
     --data-urlencode "q=Can this company structure work?" \
     --data-urlencode "reference=We have 3 foreign and 2 local shareholders"
```

## Webhooks (Future)

Webhook support is planned for asynchronous processing of long-running queries:

```json
{
  "webhook_url": "https://your-server.com/webhook",
  "query": "Complex analysis request",
  "kb": "okusiassociates"
}
```

## Changelog

### Version 1.0 (Current)
- Initial API release
- Support for 11 knowledgebases
- Query and list endpoints
- API key authentication
- Rate limiting

### Planned Features
- Webhook support
- Batch query processing
- Knowledgebase search
- Document upload API
- User-specific knowledgebases

## Support

For API support and questions:
- GitHub Issues: https://github.com/Open-Technology-Foundation/kb-query/issues
- Email: support@yatti.id

#fin