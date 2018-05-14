#!/usr/bin/env bash

# This script takes the matrix market format files (normally available on
# staging) for a single cell experiment and does the following steps:
# - Transforms those files into a long (melted) table of experiment id,
#   cell/run id, and expression. This takes care of avoiding large chunks of
#   data being kept in memory for long, at the expense of writing to disk (too)
#   often. TODO improve on this ratio.
# - Creates a partition table on postgres (requires postgres 10) for the
#   experiment (deleting previous partitions for the experiment.)
# - Loads transformed data into the partition table.
# - Postprocess table and attach it to the main scxa-analytics table.
set -e

# TODO this type of function should be loaded from a common set of scripts.
checkExecutableInPath() {
  [[ ! $(type -P $1) ]] && echo "$1 binaries not in the path." && exit 1
  [[ ! -x `type -P $1` ]] && echo "$1 is not executable." && exit 1
}


scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
postgres_scripts_dir=$scriptDir/../postgres_routines

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}
ATLAS_SC_EXPERIMENTS=${ATLAS_SC_EXPERIMENTS:-$3}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${EXP_ID+x} ] && echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1
[ -z ${ATLAS_SC_EXPERIMENTS+x} ] && echo "Env var ATLAS_SC_EXPERIMENTS for location of SC experiment for web needs to be defined." && exit 1

# Check that files are in place.
matrix_path=$ATLAS_SC_EXPERIMENTS/$EXP_ID".expression_tpm.mtx.gz"
genes_path=$ATLAS_SC_EXPERIMENTS/$EXP_ID".expression_tpm.mtx_rows.gz"
runs_path=$ATLAS_SC_EXPERIMENTS/$EXP_ID".expression_tpm.mtx_cols.gz"
for f in $matrix_path, $genes_path, $runs_path; do
  [ ! -e $f ] && echo "$EXP_ID: Matrix file $f missing, exiting." && exit 1
done

# Check that executables are in path
for e in pg_isready, sed, psql, matrixMarket2csv.R; do
  checkExecutableInPath $e
done

# Check that database connection is valid
pg_isready $dbConnection

# Transform experiment accession so that it can be used as a table name.
lc_exp_acc=`echo $EXP_ID | lc | sed 's/-/_/g'`
# Delete partition for experiment if already exists
sed s/<EXP-ACCESSION>/$lc_exp_acc/ postgres_scripts_dir/01-delete_existing_partition.sql.template | \
psql $dbConnection
# Create partition table.
sed s/<EXP-ACCESSION>/$lc_exp_acc/ postgres_scripts_dir/02-create_partition_table.sql.template | \
psql $dbConnection

# Create file with data
matrixMarket2csv.R -m $matrix_path -g $genes_path -r $runs_path -s 10000 -o $ATLAS_SC_EXPERIMENTS/expression2load.csv

# Load data into partition table
sed s/<EXP-ACCESSION>/$lc_exp_acc/ postgres_scripts_dir/03-load_data.sql.template | \
    sed s+<PATH-TO-DATA>+$ATLAS_SC_EXPERIMENTS/expression2load.csv+ | \
    psql $dbConnection

rm $ATLAS_SC_EXPERIMENTS/expression2load.csv

# Create primary key.
sed s/<EXP-ACCESSION>/$lc_exp_acc/g postgres_scripts_dir/04-build_pk.sql.template | \
    psql $dbConnection

# Post-process partition table
sed s/<EXP-ACCESSION>/$lc_exp_acc/g postgres_scripts_dir/05-post_processing.sql.template | \
    sed s/<EXP-ACC-UC>/$EXP_ID/g | \
    psql $dbConnection

# Attach partition
sed s/<EXP-ACCESSION>/$lc_exp_acc/g postgres_scripts_dir/06-attach_partition.sql.template | \
    sed s/<EXP-ACC-UC>/$EXP_ID/g | \
    psql $dbConnection

echo "Partition table loaded for experiment $EXP_ID succesfully."
