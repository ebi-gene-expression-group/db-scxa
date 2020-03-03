#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export testsDir=$scriptDir
export PATH=$scriptDir/../bin:$scriptDir/../tests:$PATH

# For analytics loading testing
psql -v ON_ERROR_STOP=1 $dbConnection < $testsDir/01-create_parent_table.sql

create-test-matrix-market-files.R TEST-EXP1
create-test-matrix-market-files.R TEST-EXP2

export EXPERIMENT_MATRICES_PATH=$PWD

# For marker genes loading testing
psql -v ON_ERROR_STOP=1 $dbConnection < $testsDir/marker-genes/01-optional-create-table.sql
export EXPERIMENT_MGENES_PATH=$testsDir/marker-genes

# For tsne loading testing
psql -v ON_ERROR_STOP=1 $dbConnection < $testsDir/tsne/01-optional-create-table.sql
export EXPERIMENT_TSNE_PATH=$testsDir/tsne

# For cluster loading testing
export EXPERIMENT_CLUSTERS_FILE=$testsDir/marker-genes/TEST-EXP1.clusters.tsv

if [ "$#" -eq 0 ]; then
	bats --tap "$(dirname "${BASH_SOURCE[0]}")"
else
	bats "$@"
fi
