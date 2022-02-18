#!/usr/bin/env bash

# Grab lines from STDIN, wrap them in the string passed as first and only
# argument, and join them with commas. Useful to transform a list of SQL string
# results into a form that can be reused in other SQL queries.
# I know there are sed/awk one-line alternatives to do this, but Bash, although
# procedural and more verbose, seemed easier to understand.

ARR=()
WRAP_CHAR=${1:-}
for ELEMENT in $(</dev/stdin)
do
  ARR+=("${WRAP_CHAR}${ELEMENT}${WRAP_CHAR}")
done
# Use comma as separator unless a character is specified in the first argument
IFS=,
echo "${ARR[*]}"
