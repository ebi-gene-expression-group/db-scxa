#!/usr/bin/env bash

# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
# https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

# Input file has gene ID in 2nd column (e.g. output from scxa_analytics.sh)
echo "COPY (SELECT * FROM scxa_cell_group_marker_gene_stats WHERE gene_id IN(`cut -f 2 -d $'\t' $1 | ${SCRIPT_DIR}/join-lines.sh \'`)) TO STDOUT DELIMITER E'\t';" | \
psql -U ${POSTGRES_USER} -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -d ${POSTGRES_DB}
