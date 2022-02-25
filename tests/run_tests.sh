#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export testsDir=$scriptDir
export PATH=$scriptDir/../bin:$scriptDir/../tests:$PATH

# flyway loding is done in run_tests_with_containers.sh

create-test-matrix-market-files.R TEST-EXP1
create-test-matrix-market-files.R TEST-EXP2

# For use within micromamba container
export SCRATCH_DIR=/tmp

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
	bats random-data-set.bats
fi
