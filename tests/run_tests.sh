#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
testsDir=$scriptDir
export PATH=$scriptDir/../bin:$scriptDir/../tests:$PATH


create-test-matrix-market-files.R

psql $dbConnection < $testsDir/01-create_parent_table.sql

export EXP_ID=TEST-EXP
export ATLAS_SC_EXPERIMENTS=$PWD

if [ "$#" -eq 0 ]; then
	bats --tap "$(dirname "${BASH_SOURCE[0]}")"
else
	bats "$@"
fi
