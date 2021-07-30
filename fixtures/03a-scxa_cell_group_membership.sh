#!/usr/bin/env bash

# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
# https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

# Input file has cell ID in 3rd column (e.g. output of scxa_analytics.sh)
SUBQUERY="SELECT * FROM scxa_cell_group_membership WHERE cell_id IN(`cut -f 3 -d $'\t' $1 | ${SCRIPT_DIR}/join-lines.sh \'`)";

echo "COPY (SELECT * FROM (${SUBQUERY}) AS foobar ORDER BY experiment_accession) TO STDOUT DELIMITER E'\t';" | \
psql -U ${POSTGRES_USER} -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -d ${POSTGRES_DB}
