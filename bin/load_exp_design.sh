#!/usr/bin/env bash

set -e

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
condensed_sdrf_file=${CONDENSED_SDRF_FILE:-$2}
sdrf_file=${SDRF_FILE:-$3}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${CONDENSED_SDRF_FILE+x} ] && echo "Env var CONDENSED_SDRF_FILE for the experiment design data needs to be defined." && exit 1
[ -z ${SDRF_FILE+x} ] && echo "Env var SDRF_FILE for column sequence of experiment design needs to be defined." && exit 1

# Reason for creating this array is to search factor value column
# In some sdrf files this column is mentioned as "Factor Value" and in some as "FactorValue"
FactorArray=( FactorValue "Factor Value" )

while IFS=$'\t' read exp_acc sample sample_type col_name annot_value annot_url
do
        if [ $sample_type == 'characteristic' ]
        then
            search_column="Characteristics[${col_name}]"
            column_order=$(awk -v val="$search_column" -F '\t' '{for (i=1; i<=NF; i++) if ($i==val) {print i} }' $sdrf_file)
        else
            for element in "${FactorArray[@]}"; do
                search_column="$element[${col_name}]"
                column_order=$(awk -v val="$search_column" -F '\t' '{for (i=1; i<=NF; i++) if ($i==val) {print i} }' $sdrf_file)
                if [[ -n "${column_order}" ]]; then
                    break
                fi
            done
        fi
        echo "INSERT INTO exp_design_column (experiment_accession, column_name, sample_type, column_order) VALUES ('$exp_acc', '$col_name', '$sample_type', '$column_order');" | psql -v ON_ERROR_STOP=1 $dbConnection
        echo "INSERT INTO exp_design (sample, annot_value, annot_ont_uri, exp_design_column_id) VALUES ('$sample', '$annot_value', '$annot_url', (SELECT id FROM exp_design_column WHERE experiment_accession='$exp_acc' AND column_name='$col_name' AND sample_type='$sample_type'));" | psql -v ON_ERROR_STOP=1 $dbConnection

done < $condensed_sdrf_file

echo "Experiment design data done loading!"