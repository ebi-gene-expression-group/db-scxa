#!/usr/bin/env bash

# This script takes the matrix market format files (normally available on
# staging) for a single cell experiment and does the following steps:
# - Transforms those files into a long (melted) table of experiment id,
#   cell/run id, and expression. This takes care of avoiding large chunks of
#   data being kept in memory for long, at the expense of writing to disk (too)
#   often.
# - Loads it into a normal database table. This an alternative to the script for
#   PG10, which loads each experiment into a different partition.
set -e

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}
EXPERIMENT_MATRICES_PATH=${EXPERIMENT_MATRICES_PATH:-$3}
EXPRESSION_TYPE=${EXPRESSION_TYPE:-"expression_tpm"}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${EXP_ID+x} ] && echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1
[ -z ${EXPERIMENT_MATRICES_PATH+x} ] && echo "Env var EXPERIMENT_MATRICES_PATH for location of SC experiment for web needs to be defined." && exit 1

# Check that files are in place.
matrix_path=$EXPERIMENT_MATRICES_PATH/$EXP_ID\.$EXPRESSION_TYPE\.mtx.gz
genes_path=$EXPERIMENT_MATRICES_PATH/$EXP_ID\.$EXPRESSION_TYPE\.mtx_rows.gz
runs_path=$EXPERIMENT_MATRICES_PATH/$EXP_ID\.$EXPRESSION_TYPE\.mtx_cols.gz
for f in $matrix_path $genes_path $runs_path; do
  [ ! -e $f ] && echo "$EXP_ID: Matrix file $f missing, exiting." && exit 1
done

# Check that database connection is valid
checkDatabaseConnection $dbConnection

# Delete analytics table content for current EXP_ID
echo "analytics table: Delete rows for $EXP_ID:"
echo "DELETE FROM scxa_analytics WHERE experiment_accession = '"$EXP_ID"'" | \
  psql -v ON_ERROR_STOP=1 $dbConnection

# Create file with data
matrixMarket2csv.js -m $matrix_path \
                    -r $genes_path \
                    -c $runs_path \
                    -e $EXP_ID \
                    -s 50000 \
                    -o $EXPERIMENT_MATRICES_PATH/expression2load.csv

# Load data
echo "Analytics: Loading data for $EXP_ID..."
printf "\copy scxa_analytics (experiment_accession, gene_id, cell_id, expression_level) FROM '%s' WITH (DELIMITER ',');" $EXPERIMENT_MATRICES_PATH/expression2load.csv | \
  psql -v ON_ERROR_STOP=1 $dbConnection

rm $EXPERIMENT_MATRICES_PATH/expression2load.csv

echo "Analytics: Loading done for $EXP_ID..."
