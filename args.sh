#!/usr/bin/env bash
[[ -n ${TRACE:-} ]] && set -x
[[ -z ${IS_TEST:-} ]] && set -euo pipefail

##
# Parses command-line arguments
# Parameters:
# $1  name of the function to handle options
# $2  name of the function to handle positionals
# ..  remaining are the arguments to parse
parse_args() {
  local handle_option=$1 handle_positionals=$2
  shift 2
  local quot_word="\"(.*)\"|'(.*)'|(.*)"
  # Matches single char opts e.g. -a or groups of opts e.g. -abx
  local single_dash_option="^-([^[:blank:]]+)$"
  # Matches a double dash option that may or may not have a value
  local double_dash_option="^--([^[:blank:]=]+)($|=)($quot_word)?"
  local name next_arg opt value
  local args=("$@") positionals=()
  local i=0
  while (( i < $# )); do
    opt="${args[$i]}"
    next_arg="${args[$i+1]:-}"
    if [[ $opt =~ $double_dash_option ]]; then
      # This if block handles the case of double-dash options with an equals
      # sign, e.g. --output=filename. It handles quotes around the option.
      name="${BASH_REMATCH[1]}"
      if [[ -n ${BASH_REMATCH[2]} ]]; then
        # The value of the quoted/unquoted string ends up in one of three groups
        value="${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
        $handle_option -- "$name" "$value"
      else
        # If the next option isn't another option (doesn't begin with
        # a dash), treat it as the value for the current option.
        if (( i + 1 == $# )) || [[ $next_arg == -* ]]; then
          $handle_option -- "$name"
        else
          $handle_option -- "$name" "${args[@]:1}"
          i=$((i + $?))
        fi
      fi
    elif [[ "$opt" =~ $single_dash_option ]]; then
      # This elif block handles single-letter opts and groups of opts,
      # e.g. '-o "filename"' or '-vfd' which becomes -v -f -d
      name="${BASH_REMATCH[1]}"
      # Groups of options can't have values, except for the last one.
      for (( k=0; k < ${#name} - 1; k++ )); do
        $handle_option - "${name:$k:1}"
      done
      # Don't pass a value if on the last opt or if the next opt is an option
      if (( i + 1 == $# )) || [[ $next_arg == -* ]]; then
        $handle_option - "${name: -1}"
      else
        $handle_option - "${name: -1}" "${args[@]:1}"
        i=$((i + $?))
      fi
    else
      positionals+=("$opt")
    fi
    i=$((i + 1))
  done
  $handle_positionals "${positionals[@]}"
}
