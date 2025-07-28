# YaTTI Custom Knowledgebase System

YaTTI builds and maintains knowledgebases in various focussed fields.

Available knowledgebases at the moment are:

    appliedanthropology
    garydean
    jakartapost
    okusiassociates
    okusimail
    okusiresearch
    peraturan.go.id
    prosocial.world
    seculardharma
    uv
    wayang.net

The YaTTI API endpoint is `https://yatti.id/v1`

### Authentication

This API requires authentication using an API key. Include your API key in the request headers:

```bash
# Using Authorization header (recommended)
curl -H "Authorization: Bearer yatti_your_api_key_here" ...

# Using X-API-Key header
curl -H "X-API-Key: yatti_your_api_key_here" ...

# With kb-query tool
export YATTI_API_KEY="yatti_your_api_key_here"
kb-query appliedanthropology "your query"
```

To obtain an API key, contact the administrator.

### Requirements:

Requires Ubuntu 24.04, `git`, `curl`, `urlencode` and `jq`.

    sudo apt install gridsite-clients curl jq git

### Installation One-liner:

    cd /tmp && git clone https://github.com/Open-Technology-Foundation/kb-query.git && sudo kb-query/kb-query.install

### Query API

To query a knowledgebase, syntax is in this general form:

    curl -s -H "Authorization: Bearer $API_KEY" "https://yatti.id/v1/{knowledgebase}?q={query}&{context_only}"

There are two parameters; `q` and `context_only`.

The `q` parameter is the text of your query. In `curl`, you must ensure the text is url encoded.

If `context_only` is set, then only the context is returned by the API; no LLM query is performed.

`context_only` is optional. If not set, then the API returns the contents of a query that has used context from the knowledgebase.

```bash
kb=appliedanthropology
query="What is a dharma?"
fields=.response
context_only=''
api_key="yatti_your_api_key_here"

curl -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $api_key" \
     -s "https://yatti.id/v1/$kb/?q=\$(urlencode "$query")&$context_only" \
     | jq -r $fields
```

#### Test Script `kb-query.test`

<details>
  <summary>`kb-query.test` is a full test script with explanations:</summary>

```bash
#!/bin/bash
## !/usr/env /usr/local/bin/scripttour
# These are the essentials for accessing
# YaTTI CustomKB knowledgebases using simple
# curl directives to https://yatti.id/v1/

# This is the knowledgebase to access:
kb=appliedanthropology

# This is the user/system query:
query="What is a 'dharma'?"

# If context_only is set to 'context_only' then
# only the text segments from the knowledgebase
# are returned.
#context_only='context_only'
context_only=''

# To break up the json output into separate fields
# you need to specify the fields you wish to see.
# '.response' is usually the best default.
#
# The other fieldnames are: kb, query, context_only,
# elapsed_seconds, error, and '.'.
#
# Use '.' to return all fields.
#
# If no fields are specified, then kb-query prints
# out the value of .response.
#
fields=( .query .response )

# Call the YaTTI Knowledgebase API using 'kb-query'
kb-query "$kb" "$query" "${fields[@]}"

# Or you can use 'curl' directly
#curl -H "Accept: application/json" \
#     -H "Content-Type: application/json" \
#     -s "https://yatti.id/v1/$kb/?q=$(urlencode "$query")&$context_only" \
#     | jq -r $fields
#fin
```

</details>

### API Commands

Available API commands are 'list' and 'help' (no authentication required).

```bash
curl -s "https://yatti.id/v1/help"
curl -s "https://yatti.id/v1/list"
```

'list' will list all available YaTTI knowledgebases.

---

## `kb-query` - YaTTI CustomKB API interface script

The `kb-query` script is a simplified command-line interface into the customKB knowledgebase API. It is essentially a wrapper for a `curl` command.

```

```

