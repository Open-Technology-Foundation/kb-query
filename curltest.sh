#!/bin/bash
set -euo pipefail
# Force unbuffered output
exec 1>/dev/stdout

baseurl=https://yatti.id.local/v1
kb=appliedanthropology
query="Create a detailed summary of Christopher Boehm’s Hierarchy in the Forest: The Evolution of Egalitarian Behavior."
reference="&reference=$(urlencode 'the quick brown fox jumped over the lazy dog.')"
context_only='' #'&context_only'

tmpfile="/tmp/$$-$RANDOM"


#---
echo "+++ TEST kb-query"
declare -p baseurl kb query reference context_only

#---
printline
echo -e "+++ TEST GET KB CONFIG"
curl -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -s "$baseurl/$kb/?q=/config" \
  >"$tmpfile"
jq -r .response "$tmpfile"

#---
printline
echo "+++ TEST GET KB LIST"
curl -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -s "$baseurl/list" \
  >"$tmpfile"
jq -r .response "$tmpfile"

#---
printline
echo "+++ TEST QUERY kb-query"
curl -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -s "$baseurl/$kb/?q=$(urlencode "$query")${context_only}${reference}" \
  >"$tmpfile"
jq . "$tmpfile"

#---
printline
echo "+++ TEST kb-query PRINT .response ONLY"
jq -r .response "$tmpfile"

#---
printline
echo "+++ TEST GET HELP kb-query"
curl -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -s "$baseurl/help" \
  >"$tmpfile"
jq -r .response "$tmpfile"


rm -f "$tmpfile"
#fin
