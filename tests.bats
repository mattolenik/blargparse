#!/usr/bin/env bats
IS_TEST=true
source args.sh

arguments=()
positionals=()

@test "test" {
  args=(-a -b --test=abc)
  parse_args handle_argument handle_positionals "${args[@]}"
  echo ${arguments[@]} 1>&2
}

handle_argument() {
  arguments+=(${1}${2}${3:-})
  echo $* &> test.out
}

handle_positionals() {
  positionals="$@"
}
