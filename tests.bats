#!/usr/bin/env bats
IS_TEST=true
source args.sh

options=()
positionals=()

@test "test" {
  test_args=(pos1 -a -b --test pos3 pos4)
  parse_args handle_options positionals "${test_args[@]}"
  echo ${options[@]} > test.out
  [[ ${options[*]} == "-a= -b= --test=pos3" ]]
  [[ ${positionals[*]} == "pos1 pos3 pos4" ]]
}

handle_options() {
  options+=(${1}${2}=${3:-})
}
