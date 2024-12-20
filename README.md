# YaTTI Custom Knowledgebase System (`kb-query`)

YaTTI builds and maintains knowledgebases in various focussed fields.

Available knowledgebases at the moment are:

    appliedanthropology
    garydean
    jakartapost
    motivation.se
    okusiassociates
    prosocial.world

The YaTTI API point is at `https://yatti.id/v1`

Requirements:

Requires Ubuntu 24.04, `curl`, `urlencode` and `jq`.

    sudo apt install gridsite-clients curl jq

Installation One-liner:

    sudo sh -c 'cd /usr/share && [ ! -d kb-query ] && git clone https://github.com/Open-Technology-Foundation/kb-query.git && ln -sf /usr/share/kb-query/kb-query /usr/local/bin/ && sudo apt install gridsite-clients curl jq'


To query a knowledgebase, syntax is in this general form:

    curl -s "https://yatti.id/v1/{knowledgebase}?q={query}&{context_only}"

There are two parameters; `q` and `context_only`.

The `q` parameter is the text of your query. In `curl`, you must ensure the text is url encoded.

If `context_only` is set, then only the context is returned by the API; no LLM query is performed.

`context_only` is optional. If not set, then the API returns the contents of a query that has used context from the knowledgebase.

```bash
kb=appliedanthropology
query="Define 'dharma'."
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
#!/bin/bash
# These are the essentials for accessing
# YaTTI CustomKB knowledgebases using simple
# curl directives to https://yatti.id/v1/

# This is the knowledgebase to access
kb=appliedanthropology

# This is the user/system query.
query="What is a 'dharma'."

# If context_only is set to 'context_only' then
# only the text segments from the knowledgebase
# are returned.
context_only=''

# To break up the json output into separate fields
# you need to specify the fields you wish to see.
# '.response' is usually the best default.
# Other fieldnames are: kb, query, context_only,
# elapsed_seconds, error, and '.'.
fields=.response

# Call the YaTTI CustomKB API
curl -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -s "https://yatti.id.local/v1/$kb/?q=$(urlencode "$query")&$context_only" \
     | jq -r $fields

#fin
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

The `kb-query` Bash script is a simplified command-line interface into the customKB knowledgebase API. It is essentially a wrapper for a `curl` command.

<details>
  <summary>Full `kb-query` script</summary>

```
kb-query 1.0.0 - Interface into YaTTI CustomKB knowledgebase API

Requires:

  curl urlencode jq

json Fields:

   kb query context_only response elapsed_seconds error

Usage:
  kb-query {command} [.field1 [.field2 ...]]

  kb-query {-c} {knowledgebase} {query} [.field1 [.field2 ...]]

  command         list||help

  knowledgebase   name of customKB knowledgebase

  query           query string for LLM

  .field{1...}    fields to output, default is all.

Options:
  -c, --context-only    Return entire context reference only,
                        do not send to LLM.
                        context_only="0"
  -v, --verbose         Increase output verbosity
  -q, --quiet           Suppress non-error messages
                        VERBOSE="1"
  -V, --version         Print version and exit
                        VERSION="1.0.0"
  -h, --help            Display this help

Examples:
  kb-query help

  kb-query list
  kb-query list.canonical
  kb-query list.symlinks
  kb-query list.all

  # Process query+knowledgebase to LLM
  kb-query appliedanthropology "Concisely define 'dharma'."

  # Return knowledgebase context only; print fields .query and .response
  kb-query -c appliedanthropology "Concisely define 'dharma'." .query .response
```

</details>


[?25h