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
EXPERIMENT_DIMRED_PATH=${EXPERIMENT_DIMRED_PATH:-$3}
SCRATCH_DIR=${SCRATCH_DIR:-"$EXPERIMENT_DIMRED_PATH"}
TSNE_PREFIX=${TSNE_PREFIX:-"$EXP_ID.tsne_perp_"}
UMAP_PREFIX=${UMAP_PREFIX:-"$EXP_ID.umap_neigh_"}
DIMRED_SUFFIX=${DIMRED_SUFFIX:-".tsv"}

# Check that necessary environment variables are defined.
[ ! -z ${dbConnection+x} ] || (echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1)
[ ! -z ${EXP_ID+x} ] || (echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1)
[ ! -z ${EXPERIMENT_DIMRED_PATH+x} ] || (echo "Env var EXPERIMENT_DIMRED_PATH for location of marker genes files for web needs to be defined." && exit 1)

# Check that files are in place.
[ $(ls -1 $EXPERIMENT_DIMRED_PATH/$TSNE_PREFIX*$DIMRED_SUFFIX | wc -l) -gt 0 ] \
  || (echo "No tsne tsv files could be found on $EXPERIMENT_DIMRED_PATH" && exit 1)

# Check that database connection is valid
checkDatabaseConnection $dbConnection


# Write to the new generic coordinates table

echo "Dimension reductions: Loading data for $EXP_ID (new layout)..."
rm -f $SCRATCH_DIR/dimredDataToLoad.csv

# Delete table content for current EXP_ID
echo "coords table: Delete rows for $EXP_ID:"
echo "DELETE FROM scxa_coords WHERE experiment_accession = '"$EXP_ID"'" | \
  psql -v ON_ERROR_STOP=1 $dbConnection

for dimred_type in tsne umap; do
  dimred_prefix=$TSNE_PREFIX
  dimred_type_name='t-SNE'
  dimred_param=perplexity

  if [ "$dimred_type" = 'umap' ]; then
    dimred_prefix=$UMAP_PREFIX
    dimred_param=n_neighbors
    dimred_type_name='UMAP'
  fi  

  for f in $(ls $EXPERIMENT_DIMRED_PATH/$dimred_prefix*$DIMRED_SUFFIX); do
    paramval=$(echo $f | sed s+$EXPERIMENT_DIMRED_PATH/$dimred_prefix++ | sed s/$DIMRED_SUFFIX// )
    tail -n +2 $f | awk -F'\t' -v EXP_ID="$EXP_ID" -v params="[{\"$dimred_param\": $paramval}]" -v method="$dimred_type_name" 'BEGIN { OFS = ","; }
    { print EXP_ID, method, $1, $2, $3, params }' >> $SCRATCH_DIR/dimredDataToLoad.csv
  done
done

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
