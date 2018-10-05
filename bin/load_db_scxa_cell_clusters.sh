#!/usr/bin/env bash

# This script takes the marker genes data, normally available in an irap
# sc_bundle, which is split in different files one per k_value (number of clusters)
# and loads it into the scxa_marker_genes table of AtlasProd.
set -e

# TODO this type of function should be loaded from a common set of scripts.

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}
EXPERIMENT_CLUSTERS_FILE=${EXPERIMENT_CLUSTERS_FILE:-$3}
SCRATCH_DIR=${SCRATCH_DIR:-$(cd "$( dirname "${EXPERIMENT_CLUSTERS_FILE}" )" && pwd )}

# Check that necessary environment variables are defined.
[ ! -z ${dbConnection+x} ] || (echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1)
[ ! -z ${EXP_ID+x} ] || (echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1)
[ ! -z ${EXPERIMENT_CLUSTERS_FILE+x} ] || (echo "Env var EXPERIMENT_MGENES_PATH for location of marker genes files for web needs to be defined." && exit 1)

echo "Clusters: Create data file for $EXP_ID..."
wideSCCluster2longSCCluster.R -c $EXPERIMENT_CLUSTERS_FILE -e $EXP_ID -o $SCRATCH_DIR/clustersToLoad.csv

# Delete clusters table content for current EXP_ID
echo "clusters table: Delete rows for $EXP_ID:"
echo "DELETE FROM scxa_cell_clusters WHERE experiment_accession = '"$EXP_ID"'" | \
  psql $dbConnection

# Load data
echo "Clusters: Loading data for $EXP_ID..."
printf "\copy scxa_cell_clusters (experiment_accession, cell_id, k, cluster_id) FROM '%s' DELIMITER ',' CSV HEADER;" $SCRATCH_DIR/clustersToLoad.csv | \
  psql $dbConnection

rm $SCRATCH_DIR/clustersToLoad.csv

echo "Clusters: Loading done for $EXP_ID."
