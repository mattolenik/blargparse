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
  local pa_handle_option=$1 pa_positionals_var_name=$2
  shift 2
  local pa_quot_word="\"(.*)\"|'(.*)'|(.*)"
  # Matches single char opts e.g. -a or groups of opts e.g. -abx
  local pa_single_dash_option="^-([^[:blank:]]+)$"
  # Matches a double dash option that may or may not have a value
  local pa_double_dash_option="^--([^[:blank:]=]+)($|=)($pa_quot_word)?"
  local pa_name pa_next_arg pa_opt pa_value
  local pa_args=("$@")
  eval "declare -a -g $pa_positionals_var_name"
  local i=0
  while (( i < $# )); do
    pa_opt="${pa_args[$i]}"
    pa_next_arg="${pa_args[$i+1]:-}"
    if [[ $pa_opt =~ $pa_double_dash_option ]]; then
      # This if block handles the case of double-dash options with an equals
      # sign, e.g. --output=filename. It handles quotes around the option.
      pa_name="${BASH_REMATCH[1]}"
      if [[ -n ${BASH_REMATCH[2]} ]]; then
        # The value of the quoted/unquoted string ends up in one of three groups
        pa_value="${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
        $pa_handle_option -- "$pa_name" "$pa_value"
      else
        # If the next option isn't another option (doesn't begin with
        # a dash), treat it as the value for the current option.
        if (( i + 1 == $# )) || [[ $pa_next_arg == -* ]]; then
          $pa_handle_option -- "$pa_name"
        else
          $pa_handle_option -- "$pa_name" "${pa_args[@]:1}"
          i=$((i + $?))
        fi
      fi
    elif [[ "$pa_opt" =~ $pa_single_dash_option ]]; then
      # This elif block handles single-letter opts and groups of opts,
      # e.g. '-o "filename"' or '-vfd' which becomes -v -f -d
      pa_name="${BASH_REMATCH[1]}"
      # Groups of options can't have values, except for the last one.
      for (( k=0; k < ${#pa_name} - 1; k++ )); do
        $pa_handle_option - "${pa_name:$k:1}"
      done
      # Don't pass a value if on the last opt or if the next opt is an option
      if (( i + 1 == $# )) || [[ $pa_next_arg == -* ]]; then
        $pa_handle_option - "${pa_name: -1}"
      else
        $pa_handle_option - "${pa_name: -1}" "${pa_args[@]:1}"
        i=$((i + $?))
      fi
    else
      eval "$pa_positionals_var_name+=(\"$pa_opt\")"
    fi
    i=$((i + 1))
  done
  # shellcheck disable=SC2145
  eval "$pa_positionals_var_name=(\"${positionals[@]}\")"
}
