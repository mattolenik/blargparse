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

@test "single_flags" {
  test_args=(-a -b -c)
  parse_args handle_options positionals "${test_args[@]}"
  echo ${options[@]} > test.out
  [[ ${options[*]} == "-a= -b= -c=" ]]
  [[ -z ${positionals[*]} ]]
}

@test "single_flags_group" {
  test_args=(-abc)
  parse_args handle_options positionals "${test_args[@]}"
  echo ${options[@]} > test.out
  [[ ${options[*]} == "-a= -b= -c=" ]]
  [[ -z ${positionals[*]} ]]
}

@test "single_flags_group_with_opt" {
  test_args=(-abc valC)
  parse_args handle_options_consume positionals "${test_args[@]}"
  echo ${options[@]} > test.out
  [[ ${options[*]} == "-a= -b= -c=valC" ]]
  [[ -z ${positionals[*]} ]]
}

handle_options() {
  options+=(${1}${2}=${3:-})
}

handle_options_consume() {
  options+=(${1}${2}=${3:-})
  return 1
}
