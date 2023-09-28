#!/usr/bin/env bash
set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/common_routines.sh"

# Alfonso is bothered about dbConnection, it shouldn’t be camelCased because:
# 1. It’s a constant, it should be DB_CONNECTION
# 2. We use snake_case for Bash variables
dbConnection=${dbConnection:-$1}
CONDENSED_SDRF_FILE=${CONDENSED_SDRF_FILE:-$2}
SDRF_FILE=${SDRF_FILE:-$3}

# Check that necessary environment variables are defined
require_env_var "dbConnection"
require_env_var "CONDENSED_SDRF_FILE"
require_env_var "SDRF_FILE"
checkDatabaseConnection "${dbConnection}"

EXPERIMENT_ACCESSION=$(head -1 "${CONDENSED_SDRF_FILE}" | cut -f 1)
DESTINATION_FILE=${SCRIPT_DIR}/${EXPERIMENT_ACCESSION}-exp-design.sql
# Remove DESTINATION_FILE if it exists
rm -f ${DESTINATION_FILE}

# Create the file and enclose all INSERT statements in a transaction
echo "BEGIN;" >> ${DESTINATION_FILE}

# In the experiment design column table we use the experiment accession, column name and sample type as the primary key
cut -f 1,4,5 "${CONDENSED_SDRF_FILE}" | sort | uniq | while read experiment_accession sample_type column_name; do
  if [ "$sample_type" == 'characteristic' ]; then
    sdrf_column_index=$(awk -F '\t' -v pattern="^Characteristics ?\\\[${column_name}\\\]$" -f ./load_exp_design.awk ${SDRF_FILE})
  else
    sdrf_column_index=$(awk -F '\t' -v pattern="^Factor ?Value ?\\\[${column_name}\\\]$" -f ./load_exp_design.awk ${SDRF_FILE})
  fi
  sql_statement="INSERT INTO exp_design_column (experiment_accession, sample_type, column_name, column_order) VALUES ('${experiment_accession}', '${sample_type}', '${column_name}', '${sdrf_column_index}');"
  echo "${sql_statement}" >> ${DESTINATION_FILE}
done

# Add the columns from the condensed SDRF file.
# Fields in the condensed SDRF that aren’t in the SDRF are assigned a column_order value of 0 by the AWK script.
# We need to assign them a value that is greater than the maximum column_order value for the experiment.
# The column_order value is used to order the columns in the UI and is not used for the primary key, so it’s ok to have
# duplicates; we can order the fields with the same column_order by name if necessary.
sql_statement="UPDATE exp_design_column SET column_order=(SELECT MAX(column_order) FROM exp_design_column WHERE experiment_accession='${EXPERIMENT_ACCESSION}')+1 WHERE column_order=0 AND experiment_accession='${EXPERIMENT_ACCESSION}';"
echo "${sql_statement}" >> ${DESTINATION_FILE}

# Insert the experiment design data.
while IFS=$'\t' read -r experiment_accession sample sample_type column_name annotation_value annotation_url; do
  sql_statement="INSERT INTO exp_design (sample, annot_value, annot_ont_uri, exp_design_column_id) VALUES ('${sample}', '${annotation_value}', '${annotation_url}', (SELECT id FROM exp_design_column WHERE experiment_accession='${experiment_accession}' AND column_name='${column_name}' AND sample_type='${sample_type}'));"
  echo "${sql_statement}" >> ${DESTINATION_FILE}
done < "$CONDENSED_SDRF_FILE"

# Finish the transaction
echo "COMMIT;" >> ${DESTINATION_FILE}

PSQL_CMD="psql -qv ON_ERROR_STOP=1 ${dbConnection} -f ${DESTINATION_FILE}"
echo ${PSQL_CMD}
eval ${PSQL_CMD}

echo "$CONDENSED_SDRF_FILE: finished loading experiment design"
