#!/usr/bin/env bash

# This script takes the dimension reduction coordinate data, normally available
# in an SCXA sc_bundle, which is split in different methods and
# parameterisations, and loads it into the scxa_coords table of AtlasProd.
set -e

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}
DIMRED_TYPE=${DIMRED_TYPE:-$3}
DIMRED_FILE_PATH=${DIMRED_FILE_PATH:-$4}
DIMRED_PARAM_JSON=${DIMRED_PARAM_JSON:-$5}
SCRATCH_DIR=${SCRATCH_DIR:-"$(dirname ${DIMRED_FILE_PATH})"}

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

# Insert a new row into the dimension reductions table
echo "INSERT INTO scxa_dimension_reduction (experiment_accession, method, parameterisation) VALUES ('$EXP_ID', '$DIMRED_TYPE', '$DIMRED_PARAM_JSON');" | psql -v ON_ERROR_STOP=1 $dbConnection
drid=$(echo "SELECT id FROM scxa_dimension_reduction WHERE experiment_accession = '$EXP_ID' AND method = '$DIMRED_TYPE' AND parameterisation = '$DIMRED_PARAM_JSON';" | psql -qtAX -v ON_ERROR_STOP=1 $dbConnection)

# Transform the TSV coords into the DB table structure
tail -n +2 $DIMRED_FILE_PATH | awk -F'\t' -v drid="$drid" 'BEGIN { OFS = ","; }
{ print drid, $1, $2, $3 }' >> $SCRATCH_DIR/dimredDataToLoad.csv

# Load data
echo "coords: Loading data for $EXP_ID..."

set +e
printf "\copy scxa_coords (dimension_reduction_id, cell_id, x, y) FROM '%s' WITH (DELIMITER ',');" $SCRATCH_DIR/dimredDataToLoad.csv | \
  psql -v ON_ERROR_STOP=1 $dbConnection

s=$?

rm $SCRATCH_DIR/dimredDataToLoad.csv

# Roll back if unsucessful

if [ $s -ne 0 ]; then
  echo "DELETE FROM scxa_dimension_reduction WHERE experiment_accession = '"$EXP_ID"' and method = '$DIMRED_TYPE' and parameterisation = '$DIMRED_PARAM_JSON'" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  exit 1
fi

echo "Dimension reductions (new layout): Loading done for $EXP_ID..."
