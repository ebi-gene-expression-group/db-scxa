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
DIMRED_TYPE=${DIMRED_TYPE:-$3}
DIMRED_FILE_PATH=${DIMRED_FILE_PATH:-$4}
DIMRED_PARAM_JSON=${DIMRED_PARAM_JSON:-$5}

# Check that necessary environment variables are defined.
[ -n ${dbConnection+x} ] || (echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1)
[ -n ${EXP_ID+x} ] || (echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1)
[ -n ${DIMRED_TYPE+x} ] || (echo "Env var DIMRED_TYPE for the dimension reduction type needs to be defined." && exit 1)
[ -n ${DIMRED_FILE_PATH+x} ] || (echo "Env var DIMRED_FILE_PATH for location of a TSV-format coordinates file for a dimension reduction needs to be defined." && exit 1)
[ -n ${DIMRED_PARAM_JSON+x} ] || (echo "Env var DIMRED_PARAM_JSON, holding JSON-format parameters for dimension reduction, needs to be defined." && exit 1)

# Check that files are in place.
if [ ! -s "$DIMRED_FILE_PATH" ]; then
    echo "No valid file found at $DIMRED_FILE_PATH" && exit 1
fi

# Check that database connection is valid
checkDatabaseConnection $dbConnection

# Write to the new generic coordinates table

echo "Dimension reductions: Loading data for $EXP_ID (new layout)..."
rm -f $SCRATCH_DIR/dimredDataToLoad.csv


# Transform the TSV coords into the DB table structure
tail -n +2 $DIMRED_FILE_PATH | awk -F'\t' -v EXP_ID="$EXP_ID" -v params="$DIMRED_PARAM_JSON" -v method="$DIMRED_TYPE" 'BEGIN { OFS = ","; }
{ print EXP_ID, method, $1, $2, $3, params }' >> $SCRATCH_DIR/dimredDataToLoad.csv

# Load data
echo "coords: Loading data for $EXP_ID..."

set +e
printf "\copy scxa_coords (experiment_accession, method, cell_id, x, y, parameterisation) FROM '%s' WITH (DELIMITER ',');" $SCRATCH_DIR/dimredDataToLoad.csv | \
  psql -v ON_ERROR_STOP=1 $dbConnection

s=$?

rm $SCRATCH_DIR/dimredDataToLoad.csv

# Roll back if unsucessful

if [ $s -ne 0 ]; then
  echo "DELETE FROM scxa_coords WHERE experiment_accession = '"$EXP_ID"' and method = 'tsne'" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  exit 1
fi

echo "Dimension reductions (new layout): Loading done for $EXP_ID..."
