#!/usr/bin/env bash

set -e

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
postgres_scripts_dir=$scriptDir/../postgres_routines

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}
ATLAS_SC_EXPERIMENTS=${ATLAS_SC_EXPERIMENTS:-$3}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${EXP_ID+x} ] && echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1
[ -z ${ATLAS_SC_EXPERIMENTS+x} ] && echo "Env var ATLAS_SC_EXPERIMENTS for location of SC experiment for web needs to be defined." && exit 1


# Transform experiment accession so that it can be used as a table name.
lc_exp_acc=`echo $EXP_ID | lc | sed 's/-/_/g'`
# Delete partition for experiment if already exists
sed s/<EXP-ACCESSION>/$lc_exp_acc/ postgres_scripts_dir/01-delete_existing_partition.sql.template | \
psql $dbConnection
# Create partition table.
sed s/<EXP-ACCESSION>/$lc_exp_acc/ postgres_scripts_dir/02-create_partition_table.sql.template | \
psql $dbConnection

# Create file with data
matrix_path=$ATLAS_SC_EXPERIMENTS/$EXP_ID".expression_tpm.mtx.gz"
genes_path=$ATLAS_SC_EXPERIMENTS/$EXP_ID".expression_tpm.mtx_rows.gz"
runs_path=$ATLAS_SC_EXPERIMENTS/$EXP_ID".expression_tpm.mtx_cols.gz"
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
