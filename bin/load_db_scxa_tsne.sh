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
EXPERIMENT_TSNE_PATH=${EXPERIMENT_TSNE_PATH:-$3}
TSNE_PREFIX=${TSNE_PREFIX:-"$EXP_ID.tsne_perp_"}
TSNE_SUFFIX=${TSNE_SUFFIX:-".tsv"}

# Check that necessary environment variables are defined.
[ ! -z ${dbConnection+x} ] || (echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1)
[ ! -z ${EXP_ID+x} ] || (echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1)
[ ! -z ${EXPERIMENT_TSNE_PATH+x} ] || (echo "Env var EXPERIMENT_TSNE_PATH for location of marker genes files for web needs to be defined." && exit 1)

# Check that files are in place.
[ $(ls -1 $EXPERIMENT_TSNE_PATH/$TSNE_PREFIX*$TSNE_SUFFIX | wc -l) -gt 0 ] \
  || (echo "No tsne tsv files could be found on $EXPERIMENT_TSNE_PATH" && exit 1)

# Check that database connection is valid
checkDatabaseConnection $dbConnection

# Delete tsne table content for current EXP_ID
echo "tsne table: Delete rows for $EXP_ID:"
echo "DELETE FROM scxa_tsne WHERE experiment_accession = '"$EXP_ID"'" | \
  psql -v ON_ERROR_STOP=1 $dbConnection

# Create file with data
# Please note that this relies on:
# - Column ordering on the marker genes file: tSNE_1 tSNE_2 Label
# - Table ordering of columns: experiment_accession cell_id x y perplexity
echo "Marker genes: Create data file for $EXP_ID..."
rm -f $EXPERIMENT_TSNE_PATH/tsneDataToLoad.csv
for f in $(ls $EXPERIMENT_TSNE_PATH/$TSNE_PREFIX*$TSNE_SUFFIX); do
  persp=$(echo $f | sed s+$EXPERIMENT_TSNE_PATH/$TSNE_PREFIX++ | sed s/$TSNE_SUFFIX// )
  tail -n +2 $f | awk -F'\t' -v EXP_ID="$EXP_ID" -v persp_value="$persp" 'BEGIN { OFS = ","; }
  { print EXP_ID, $1, $2, $3, persp_value }' >> $EXPERIMENT_TSNE_PATH/tsneDataToLoad.csv
done

# Load data
echo "TSNE: Loading data for $EXP_ID..."

set +e
printf "\copy scxa_tsne (experiment_accession, cell_id, x, y, perplexity) FROM '%s' WITH (DELIMITER ',');" $EXPERIMENT_TSNE_PATH/tsneDataToLoad.csv | \
  psql -v ON_ERROR_STOP=1 $dbConnection

s=$?

rm $EXPERIMENT_TSNE_PATH/tsneDataToLoad.csv

# Roll back if unsucessful

if [ $s -ne 0 ]; then
  echo "DELETE FROM scxa_tsne WHERE experiment_accession = '"$EXP_ID"'" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  exit 1
fi

# Write to the new generic coordinates table

for f in $(ls $EXPERIMENT_TSNE_PATH/$TSNE_PREFIX*$TSNE_SUFFIX); do
  persp=$(echo $f | sed s+$EXPERIMENT_TSNE_PATH/$TSNE_PREFIX++ | sed s/$TSNE_SUFFIX// )
  tail -n +2 $f | awk -F'\t' -v EXP_ID="$EXP_ID" -v params="perplexity=$persp"  -v method='tsne' 'BEGIN { OFS = ","; }
  { print EXP_ID, method, $1, $2, $3, params }' >> $EXPERIMENT_TSNE_PATH/tsneDataToLoad.csv
done

set +e
printf "\copy scxa_coords (experiment_accession, method, cell_id, x, y, parameterisation) FROM '%s' WITH (DELIMITER ',');" $EXPERIMENT_TSNE_PATH/tsneDataToLoad.csv | \
  psql -v ON_ERROR_STOP=1 $dbConnection

s=$?

rm $EXPERIMENT_TSNE_PATH/tsneDataToLoad.csv

# Roll back if unsucessful

if [ $s -ne 0 ]; then
  echo "DELETE FROM scxa_coords WHERE experiment_accession = '"$EXP_ID"' and method = 'tsne'" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  exit 1
fi

echo "TSNE: Loading done for $EXP_ID..."
