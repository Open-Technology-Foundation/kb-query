# YaTTI Custom Knowledgebase System

YaTTI builds and maintains knowledgebases in various focussed fields.

Available knowledgebases at the moment are:

appliedanthropology
    garydean
    jakartapost
    motivation.se
    okusiassociates
    prosocial.world
    seculardharma
    wayang.net
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

Available API commands are 'list' and 'help'.

```bash
curl -s "https://yatti.id/v1/help"
curl -s "https://yatti.id/v1/list"
```

'list' will list all available YaTTI knowledgebases.

---

## `kb-query` - YaTTI CustomKB API interface script

The `kb-query` script is a simplified command-line interface into the customKB knowledgebase API. It is essentially a wrapper for a `curl` command.

```
kb-query 0.1.10 - Interface into YaTTI CustomKB knowledgebase API

Requires:

    sudo apt install git curl jq gridsite-clients

Installation:

    git clone https://github.com/Open-Technology-Foundation/kb-query.git && sudo kb-query/kb-query.install

json Return Fields:

   ( kb query context_only reference response elapsed_seconds error )

Usage:

  kb-query {command} [.field1 [.field2 ...]]

    command         list | help | update

  kb-query [OPTIONS] {knowledgebase} {query} [.field1 [.field2 ...]]

    knowledgebase   name of customKB knowledgebase

    query           query string for LLM

    .field{1...}    fields to output, default is all.

Options:
  -r, --reference-file FILE
                    Reference filename
                    reference_file=""
  -R, --reference-str TEXT
                    Reference string
                    reference_text=""
  -c, --context-only
                    Return entire context reference only,
                    do not send to LLM.
                    context_only="0"

  --query-model LLM
                    LLM to use for query (if not context_only)
  --query-temperature TEMP
                    LLM Query Temperature
  --query-max-tokens
                    LLM max tokens allowed

  --query-top-k SEGMENTS
                    Number of SEGMENTS to return
  --query-context-scope SCOPE
                    Number of SEGMENTS above/below to return
                    ("aperture")
                    Eg,
                      A SCOPE of 1 only returns the match segment.
                      A SCOPE of 2 returns the match segment and the next segment.
                      A SCOPE of 3 returns the match segment, the previous segment, and the next segment.
                      A SCOPE of 4 returns the match segment, the previous segment, and the next 2 segments.
  --query-role ROLE
                    System ROLE
  --query-context-files FILE[,FILE...]
                    Context files

  -v, --verbose         Increase output verbosity
  -q, --quiet           Suppress non-error messages
                        VERBOSE="1"
  -d, --debug           Print debug messages
                        DEBUG="0"
  -V, --version         Print version and exit
                        VERSION="0.1.10"
  -h, --help            Display this help

Examples:

  # Help for kb-query utility

    kb-query --help

  # Overview YaTTI knowledgebase

    kb-query help

  # List YaTTI knowledgebases

    kb-query list

  # Query knowledgebase

    kb-query appliedanthropology "Concisely define 'applied anthropology'."

  # Query knowledgebase and output fields .query and .response

    kb-query appliedanthropology "Concisely define 'applied anthropology'." .query .response

  # Query knowledgebase for context only, with context reference

    kb-query appliedanthropology -c -r previouscontext.txt "Concisely define 'applied anthropology'."

  # Update to latest version

    kb-query update
```

