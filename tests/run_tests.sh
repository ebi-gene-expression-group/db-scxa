#!/usr/bin/env bash

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )
export testsDir=$scriptDir
export PATH=$scriptDir/../bin:$scriptDir/../tests:$PATH

# Flyway loading is done in run_tests_with_containers.sh

create-test-matrix-market-files.R TEST-EXP1
create-test-matrix-market-files.R TEST-EXP2

# For use within micromamba container
export SCRATCH_DIR=/tmp

export EXPERIMENT_MATRICES_PATH=$PWD

# To test marker genes loading
export EXPERIMENT_MGENES_PATH=$testsDir/marker-genes

# To test t-SNE loading
export EXPERIMENT_DIMRED_PATH=$testsDir/dimred

# To test cluster loading
export EXPERIMENT_CLUSTERS_FILE=$testsDir/marker-genes/TEST-EXP1.clusters.tsv

# Make /fixtures writable
export BIOENTITIES=$testsDir
export EXPERIMENT_FILES=$testsDir/experiment_files
export EXPERIMENT_DESIGN_FILES=$SCRATCH_DIR

#cp -r /fixtures /tmp/fixtures
#chmod -R a+w /tmp/fixtures/experiment_files/expdesign


if [ "$#" -eq 0 ]; then
	bats --tap "$(dirname "${BASH_SOURCE[0]:-$0}")"
else
	bats random-data-set.bats
fi
