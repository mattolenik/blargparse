#!/usr/bin/env bash
[[ -n ${TRACE:-} ]] && set -x
set -euo pipefail
VERSION=0.1.0
fail() { printf '%s\n' "$*"; exit 1; }
NONE=@__BASH_NONE__@

print_usage() {
  echo usage goes here
}

##
# Argument parsing
##
handle_option() {
  #local dash=$1
  local name=$2
  local value=${3:-$NONE}
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
      fail "Unknown argument $1"
      ;;
  esac
}

handle_positionals() {
  echo "Positionals: $*"
}

parse_args() {
  local quot_word="\"(.*)\"|'(.*)'|(.*)"
  local single_dash_argument="^-([^[:blank:]]+)"
  local double_dash_argument="^--([^[:blank:]]+)(=|[[:blank:]]+)($quot_word)$"
  local name value
  local -a args
  local -a positionals
  args=("$@")
  positionals=()
  i=0
  while (( i < $# )); do
    arg="${args[$i]}"
    if [[ $arg =~ $double_dash_argument ]]; then
      name="${BASH_REMATCH[1]}"
      # The value will be one of the three capture groups that handle double
      # quotes, single quotes, or no quotes. Only one group can match at a
      # time, so concatenating is the easiest way to get the value for any
      # kind of quoting.
      value="${BASH_REMATCH[4]${BASH_REMATCH[5]}}${BASH_REMATCH[6]}"
      handle_option -- "$name" "$value"
    elif [[ "$arg" =~ $single_dash_argument ]]; then
      # This elif block handles single-letter args and groups of args,
      # e.g. '-o "filename"' or '-vfd' which becomes -v -f -d
      name="${BASH_REMATCH[1]}"
      if (( ${#name} > 1 )); then
        for (( i=0; i<${#name}; i++ )); do
          handle_option - "${name:$i:1}"
        done
      else
        handle_option - "$name"
      fi
    else
      positionals+=("$arg")
    fi
    i=$((i + 1))
  done
  handle_positionals "${positionals[@]}"
}

parse_args "$@"
