#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export testsDir=$scriptDir
export PATH=$scriptDir/../bin:$scriptDir/../tests:$PATH

# For analytics loading testing
psql $dbConnection < $testsDir/01-create_parent_table.sql

create-test-matrix-market-files.R TEST-EXP1
create-test-matrix-market-files.R TEST-EXP2

export EXPERIMENT_MATRICES_PATH=$PWD

# For marker genes loading testing
psql $dbConnection < $testsDir/marker-genes/01-optional-create-table.sql
export EXPERIMENT_MGENES_PATH=$testsDir/marker-genes

if [ "$#" -eq 0 ]; then
	bats --tap "$(dirname "${BASH_SOURCE[0]}")"
else
	bats "$@"
fi
