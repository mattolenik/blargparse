# shellcheck shell=bash
[[ -n "${__ARGS_SH__:-}" ]] && return || __ARGS_SH__=1 # multiple source guard

##
# Parses command-line arguments
# Parameters:
# $1  name of the function to handle options
# $2  name of the variable to contain array of positionals
# ..  remaining are the arguments to parse
parse_args() {
  local _handle_option=$1 _positionals_var_name=$2
  shift 2
  local _quot_word="\"(.*)\"|'(.*)'|(.*)"
  # Matches single char opts e.g. -a or groups of opts e.g. -abx
  local _single_dash_option="^-([^[:blank:]]+)$"
  # Matches a double dash option that may or may not have a value
  local _double_dash_option="^--([^[:blank:]=]+)($|=)($_quot_word)?"
  local _name _next_arg _arg _value
  local _args=("$@") __i=0 __k=0
  declare -a -g "$_positionals_var_name"
  while (( __i < $# )); do
    _arg="${_args[$__i]}"
    _next_arg="${_args[$__i+1]:-}"
    if [[ $_arg =~ $_double_dash_option ]]; then
      # This if block handles the case of double-dash options with an equals
      # sign, e.g. --output=filename. It handles quotes around the option.
      _name="${BASH_REMATCH[1]}"
      if [[ -n ${BASH_REMATCH[2]} ]]; then
        # The value of the quoted/unquoted string ends up in one of three groups
        _value="${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
        $_handle_option -- "$_name" "$_value" || true
      else
        # If the next option isn't another option (doesn't begin with
        # a dash), treat it as the value for the current option.
        if (( __i + 1 == $# )) || [[ $_next_arg == -* ]]; then
          $_handle_option -- "$_name" || true
        else
          $_handle_option -- "$_name" "${_args[@]:$__i+1:1}" || __i=$((__i + $?))
        fi
      fi
    elif [[ "$_arg" =~ $_single_dash_option ]]; then
      # This elif block handles single-letter opts and groups of opts,
      # e.g. '-o "filename"' or '-vfd' which becomes -v -f -d
      _name="${BASH_REMATCH[1]}"
      # Groups of options can't have values, except for the last one.
      for (( __k=0; __k < ${#_name} - 1; __k++ )); do
        $_handle_option - "${_name:$__k:1}" || true
      done
      # Don't pass a value if on the last arg or if the next arg is an option
      if (( __i + 1 == $# )) || [[ $_next_arg == -* ]]; then
        $_handle_option - "${_name: -1}" || true
      else
        $_handle_option - "${_name: -1}" "${_args[@]:$__i+1:1}" || __i=$((__i + $?))
      fi
    else
      eval "$_positionals_var_name+=(\"$_arg\")"
    fi
    __i=$((__i + 1))
  done
}

##
# Checks if an option exists, and optionally if it matches a regex
# $1 - Argument name
# $2 - Argument value
# $3 - (optional) if provided, validation will be done against this regex pattern.
# $4 - (optional) error message to print when regex validation fails
##
check_opt() {
  [[ -z $2 ]] && echo "Option $1 expects a value" 1>&2 && return 1
  if  [[ -n ${3:-} ]]; then
    [[ $2 =~ $3 ]] || echo "${4:-The value provided for option $2 is not valid}" 1>&2 && return 2
  fi
}

##
# Prompt the user and wait for an answer. An optional default value
# can be returned when the user skips the question by pressing ENTER.
##
# $1 - Output variable that will contain the result
# $2 - Question string, without indicating options yourself. For example,
#      don't pass in "Question? (y/n)", just "Question?". The options will be
#      added automatically.
# $3 - Options for the prompt, as a space-separated list. Use * for freeform
#      input. Options are automatically lowercase only.
# $4 - Default value, optional
##
ask() {
  # Var names are somewhat obfuscated to reduce collision with out var name
  local _question_arg_="2"
  local _options_arg_="3"
  local _default_var_="4"
  local _answer_

  # If AUTO_APPROVE is set, just return the default.
  if [[ -n ${AUTO_APPROVE:-} ]]; then
    read -r "$1" <<< "${!_default_var_:-}"
    return
  fi

  local _choices_="${!_options_arg_+${!_options_arg_// /\/} }"
  # If default is set and not empty
  if [[ -n "${!_default_var_:-}" ]]; then
    if [[ ${!_options_arg_:-*} == * ]]; then
      _choices_="[${!_default_var_}] "
    elif [[ $_choices_ != *"${!_default_var_}"* ]]; then
      echo "Default value does not appear in the options list" && return 3
    else
      # Make the default option appear in uppercase
      _choices_="(${_choices_/${!_default_var_}/${!_default_var_^^}})"
    fi
  fi

  # Loop until valid input is received
  while true; do
    read -rp "${!_question_arg_} ${_choices_:-}" _answer_
    _answer_="${_answer_:-${!_default_var_:-}}"
    if [[ ${!_options_arg_:-*} == "*" ]]; then
      # Populate the user-passed in variable
      read -r "$1" <<< "$_answer_"
      return
    fi
    # Trim and collapse whitespace and convert to lowercase
    local normal_opts
    normal_opts="$(printf %s "${!_options_arg_}" | xargs echo -n | awk '{print tolower($0)}')"
    local opt_pattern='^('"${normal_opts// /|}"')$'
    if [[ $_answer_ =~ $opt_pattern ]]; then
      read -r "$1" <<< "$_answer_"
      return
    else
      echo "ERROR: Invalid option, must be one of: ${normal_opts// /, }"
    fi
  done
}
