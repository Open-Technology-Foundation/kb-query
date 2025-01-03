# YaTTI Custom Knowledgebase System

YaTTI builds and maintains knowledgebases in various focussed fields.

Available knowledgebases at the moment are:


The YaTTI API endpoint is `https://yatti.id/v1`

### Requirements:

Requires Ubuntu 24.04, `git`, `curl`, `urlencode` and `jq`.

    sudo apt install gridsite-clients curl jq git

### Installation One-liner:

    cd /tmp && git clone https://github.com/Open-Technology-Foundation/kb-query.git && sudo kb-query/kb-query.install

### Query API

To query a knowledgebase, syntax is in this general form:

    curl -s "https://yatti.id/v1/{knowledgebase}?q={query}&{context_only}"

There are two parameters; `q` and `context_only`.

The `q` parameter is the text of your query. In `curl`, you must ensure the text is url encoded.

If `context_only` is set, then only the context is returned by the API; no LLM query is performed.

`context_only` is optional. If not set, then the API returns the contents of a query that has used context from the knowledgebase.

```bash
kb=appliedanthropology
query="What is a dharma?"
fields=.response
context_only=''

curl -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -s "https://yatti.id/v1/$kb/?q=\$(urlencode "$query")&$context_only" \
     | jq -r $fields
```

#### Test Script `kb-query.test`

<details>
  <summary>`kb-query.test` is a full test script with explanations:</summary>

```bash

```

</details>

### API Commands

Available API commands are 'list' and 'help'.

```bash
curl -s "https://yatti.id/v1/help"
curl -s "https://yatti.id/v1/list"
```

'list' will list all available YaTTI knowledgebases.

---

## `kb-query` - YaTTI CustomKB API interface script

The `kb-query` script is a simplified command-line interface into the customKB knowledgebase API. It is essentially a wrapper for a `curl` command.

<details>
  <summary>Full `kb-query` help</summary>

```

```

</details>


[?25h