#!/bin/bash
# Bash completion for kb-query
# Install: source this file in .bashrc or copy to /etc/bash_completion.d/

_kb_query_completions() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  
  # Cache file for knowledge base list
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/kb-query"
  local cache_file="$cache_dir/kb-list"
  local cache_age=3600  # 1 hour in seconds
  
  # Function to get knowledge base list
  _get_kb_list() {
    # Create cache directory if it doesn't exist
    mkdir -p "$cache_dir"
    
    # Check if cache is fresh
    if [[ -f "$cache_file" ]] && [[ $(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) )) -lt $cache_age ]]; then
      cat "$cache_file"
    else
      # Refresh cache
      if kb-query list 2>/dev/null | jq -r '.[]' 2>/dev/null > "$cache_file.tmp"; then
        mv "$cache_file.tmp" "$cache_file"
        cat "$cache_file"
      else
        # Fallback to some common knowledge bases
        echo "appliedanthropology garydean jakartapost okusiassociates okusimail"
      fi
    fi
  }
  
  # Command options
  local commands="list help update"
  local options="-r --reference-file -R --reference-str -c --context-only --context \
                 -d --debug -h --help -v --verbose -q --quiet -V --version \
                 --query-model --query-temperature --query-max-tokens --query-top-k \
                 --query-context-scope --query-role --query-context-files \
                 --output-format --timeout"
  
  # Handle option arguments
  case "${prev}" in
    -r|--reference-file|--query-context-files)
      # File completion
      COMPREPLY=( $(compgen -f -- "${cur}") )
      return 0
      ;;
    --output-format)
      COMPREPLY=( $(compgen -W "json text markdown" -- "${cur}") )
      return 0
      ;;
    --query-model)
      COMPREPLY=( $(compgen -W "gpt-4 gpt-4o gpt-4o-mini gpt-3.5-turbo claude-3-opus claude-3-sonnet" -- "${cur}") )
      return 0
      ;;
    --query-temperature)
      COMPREPLY=( $(compgen -W "0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0" -- "${cur}") )
      return 0
      ;;
    --query-top-k)
      COMPREPLY=( $(compgen -W "5 10 15 20 25 30" -- "${cur}") )
      return 0
      ;;
    --timeout)
      COMPREPLY=( $(compgen -W "10 20 30 60 90 120" -- "${cur}") )
      return 0
      ;;
  esac
  
  # First argument - commands or knowledge bases
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    # If it starts with -, complete options
    if [[ ${cur} == -* ]]; then
      COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
    else
      # Complete with commands and knowledge bases
      local kbs=$(_get_kb_list | tr '\n' ' ')
      COMPREPLY=( $(compgen -W "${commands} ${kbs}" -- "${cur}") )
    fi
  else
    # Subsequent arguments
    if [[ ${cur} == -* ]]; then
      # Complete options
      COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
    elif [[ ${COMP_CWORD} -eq 2 ]] && [[ "${COMP_WORDS[1]}" != "list" ]] && [[ "${COMP_WORDS[1]}" != "help" ]] && [[ "${COMP_WORDS[1]}" != "update" ]]; then
      # Second argument for knowledge base queries - no completion for query text
      return 0
    else
      # Field completion (.field names)
      if [[ ${cur} == .* ]]; then
        COMPREPLY=( $(compgen -W ".kb .query .context_only .reference .response .elapsed_seconds .error" -- "${cur}") )
      fi
    fi
  fi
}

complete -F _kb_query_completions kb-query