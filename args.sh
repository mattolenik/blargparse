#!/usr/bin/env bash
[[ -n ${TRACE:-} ]] && set -x
set -euo pipefail
VERSION=0.1.0
fail() { printf '%s\n' "$*"; exit 1; }
NONE=$'\31'NONE

print_usage() {
  echo usage goes here
}

##
# Argument parsing
##
handle_argument() {
  local dash=$1
  local name=$2
  local value=${3:-}
  case $name in
    o|oops)
      echo "oopies $value!"
      ;;
    h|help)
      print_usage
      exit 0
      ;;
    v|version)
      echo "$VERSION"
      exit 0
      ;;
    *)
      print_usage 1>&2
      fail "Unknown argument $dash$name"
      ;;
  esac
}

handle_positionals() {
  echo "Positionals: $*"
}

parse_args() {
  local quot_word="\"(.*)\"|'(.*)'|(.*)"
  local single_dash_argument="^-([^[:blank:]]+)$"
  local double_dash_argument="^--([^[:blank:]=]+)($|=)($quot_word)?"
  local arg name next_arg value
  local args=("$@")
  local positionals=()
  i=0
  while (( i < $# )); do
    arg="${args[$i]}"
    next_arg="${args[$i+1]:-}"
    if [[ $arg =~ $double_dash_argument ]]; then
      # This if block handles the case of double-dash arguments with an equals
      # sign, e.g. --output=filename. It handles quotes around the argument.
      name="${BASH_REMATCH[1]}"
      if [[ -n ${BASH_REMATCH[2]} ]]; then
        # The value will be one of the three capture groups that handle double
        # quotes, single quotes, or no quotes. Only one group can match at a
        # time, so concatenating is the easiest way to get the value for any
        # kind of quoting.
        value="${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
        handle_argument -- "$name" "$value"
      else
        # If the next argument isn't another argument (doesn't begin with
        # a dash), treat it as the value for the current argument.
        if (( i + 1 == $# )) || [[ $next_arg == -* ]]; then
          handle_argument -- "$name"
        else
          handle_argument -- "$name" "$next_arg"
        fi
      fi
    elif [[ "$arg" =~ $single_dash_argument ]]; then
      # This elif block handles single-letter args and groups of args,
      # e.g. '-o "filename"' or '-vfd' which becomes -v -f -d
      name="${BASH_REMATCH[1]}"
      # Groupings of options are always flags without values
      if (( ${#name} > 1 )); then
        for (( k=0; k<${#name}; k++ )); do
          handle_argument - "${name:$k:1}"
        done
      else
        if (( i + 1 == $# )) || [[ $next_arg == -* ]]; then
          handle_argument - "$name"
        else
          handle_argument - "$name" "$next_arg"
        fi
      fi
    else
      positionals+=("$arg")
    fi
    i=$((i + 1))
  done
  handle_positionals "${positionals[@]}"
}

parse_args "$@"
