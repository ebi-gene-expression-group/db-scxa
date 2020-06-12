#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export testsDir=$scriptDir
export PATH=$scriptDir/../bin:$scriptDir/../tests:$PATH

# For analytics loading testing
USER=$(echo $dbConnection | sed s+postgresql://++ | sed 's+:.*++')
PASS=$(echo $dbConnection | sed s+postgresql://++ | sed 's+.*:\(.*\)\@.*+\1+')
HOST=$(echo $dbConnection | sed 's+.*\@\(.*\)/.*+\1+')
DB=$(echo $dbConnection | sed 's+.*/\(.*\)+\1+')
flyway migrate -url=jdbc:postgresql://${HOST}:5432/${DB} -user=${USER} -password=${PASS} -locations=filesystem:$( pwd )/atlas-schemas/flyway/scxa

create-test-matrix-market-files.R TEST-EXP1
create-test-matrix-market-files.R TEST-EXP2

export EXPERIMENT_MATRICES_PATH=$PWD

# For marker genes loading testing
export EXPERIMENT_MGENES_PATH=$testsDir/marker-genes

# For tsne loading testing
export EXPERIMENT_DIMRED_PATH=$testsDir/dimred

# For cluster loading testing
export EXPERIMENT_CLUSTERS_FILE=$testsDir/marker-genes/TEST-EXP1.clusters.tsv

if [ "$#" -eq 0 ]; then
	bats --tap "$(dirname "${BASH_SOURCE[0]}")"
else
	bats "$@"
fi
