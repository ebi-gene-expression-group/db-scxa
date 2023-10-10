#!/usr/bin/env bash

set -e

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
condensed_sdrf_file=${CONDENSED_SDRF_FILE:-$2}
sdrf_file=${SDRF_FILE:-$3}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${CONDENSED_SDRF_FILE+x} ] && echo "Env var CONDENSED_SDRF_FILE for the experiment design data needs to be defined." && exit 1
[ -z ${SDRF_FILE+x} ] && echo "Env var SDRF_FILE for column sequence of experiment design needs to be defined." && exit 1

# for experiment design column table, we need to have a unique experiment accession, column name, and sample type
# as they are the primary key for the table, and we don't want to insert duplicate rows
cut -f 1,4,5 "$condensed_sdrf_file" | sort | uniq | while read exp_acc sample_type col_name; do
  if [ "$sample_type" == 'characteristic' ]; then
    column_order=$(awk -v val="$search_column" -v pattern="^Characteristics ?\\[${col_name}]$" -F '\t' '{for (i=1; i<=NF; i++) if ($i ~ pattern) {print i} }' "$sdrf_file")
  else
    column_order=$(awk -v val="$search_column" -v pattern="^Factor ?Value ?\\[${col_name}]$" -F '\t' '{for (i=1; i<=NF; i++) if ($i ~ pattern) {print i} }' "$sdrf_file")
  fi
  echo "INSERT INTO exp_design_column (experiment_accession, column_name, sample_type, column_order) VALUES ('$exp_acc', '$col_name', '$sample_type', '$column_order');" | psql -v ON_ERROR_STOP=1 "$dbConnection"
done

while IFS=$'\t' read -r exp_acc sample sample_type col_name annot_value annot_url; do
  echo "INSERT INTO exp_design (sample, annot_value, annot_ont_uri, exp_design_column_id) VALUES ('$sample', '$annot_value', '$annot_url', (SELECT id FROM exp_design_column WHERE experiment_accession='$exp_acc' AND column_name='$col_name' AND sample_type='$sample_type'));" | psql -v ON_ERROR_STOP=1 "$dbConnection"
done < "$condensed_sdrf_file"

echo "Experiment design data done loading for $condensed_sdrf_file"
