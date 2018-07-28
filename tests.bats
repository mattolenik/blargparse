#!/usr/bin/env bats
IS_TEST=true
source args.sh

options=()
positionals=()

@test "test" {
  test_args=(-a -b --test=abc pos1 pos2)
  parse_args handle_options positionals "${test_args[@]}"
  [[ ${options[*]} == "-a= -b= --test=abc" ]]
  [[ ${positionals[*]} == "pos1 pos2" ]]
}

handle_options() {
  options+=(${1}${2}=${3:-})
}
