#!/usr/bin/env bash

# Arguments:
# Experiment accession
# Number of dimension reductions to sample (defaults to 10)
psql -q -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h ${POSTGRES_HOST} << EOF
COPY (
    SELECT
        *
    FROM
        scxa_dimension_reduction
    WHERE
        experiment_accession = '${1}'
    ORDER BY
        random()
    LIMIT ${2:-10}
) TO STDOUT DELIMITER E'\t';
EOF
