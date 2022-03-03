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

# For fixtures to be able to be writable.
cp -r /fixtures /tmp/fixtures
# Look at this
echo "Content of /tmp/fixtures/experiment_files/expdesign"
ls -l /tmp/fixtures/experiment_files/expDesign
echo "**********************"
echo "Content of /tmp/fixtures/experiment_files"
ls -l /tmp/fixtures/experiment_files 
chmod -R a+w /tmp/fixtures/experiment_files/expDesign 


if [ "$#" -eq 0 ]; then
	bats --tap "$(dirname "${BASH_SOURCE[0]}")"
else
	bats random-data-set.bats
fi
