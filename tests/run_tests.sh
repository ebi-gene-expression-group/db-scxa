#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
testsDir=$scriptDir
export PATH=$scriptDir/../bin:$scriptDir/../tests:$PATH

psql $dbConnection < $testsDir/01-create_parent_table.sql

create-test-matrix-market-files.R TEST-EXP1
create-test-matrix-market-files.R TEST-EXP2

export EXPERIMENT_MATRICES_PATH=$PWD


if [ "$#" -eq 0 ]; then
	bats --tap "$(dirname "${BASH_SOURCE[0]}")"
else
	bats "$@"
fi
