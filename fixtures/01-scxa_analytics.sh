#!/usr/bin/env bash

# 01-scxa_analytics.sh EXPERIMENT_ACCESSION [LIMIT]
#
# 01-scxa-analytics.sh E-EHCA-2
# 01-scxa-analytics.sh E-MTAB-5061 200

POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
# Default limit is 10
LIMIT=${2:-10}

# Get a sample of unique cell/gene IDs from table scxa_analytics; the values
# are distinct between and within columns (unlike `DISTINCT gene_id, cell_id`)
SUBQUERY="SELECT DISTINCT ON(cell_id) * FROM (SELECT DISTINCT ON(gene_id) * FROM scxa_analytics WHERE experiment_accession='${1}') AS foo"

echo "COPY (SELECT * FROM (${SUBQUERY}) AS bar ORDER BY RANDOM() LIMIT ${LIMIT}) TO STDOUT DELIMITER E'\t';" | \
psql -U ${POSTGRES_USER} -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -d ${POSTGRES_DB}
