#!/usr/bin/env bash

# Arguments:
# List of cell IDs, separated with commas
# List of dimension reduction IDs, separated with commas
psql -q -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h ${POSTGRES_HOST} << EOF
COPY (
    SELECT
        *
    FROM
        scxa_coords
    WHERE
        cell_id = ANY(ARRAY[${1}])
        AND
        dimension_reduction_id = ANY(ARRAY[${2}])
) TO STDOUT DELIMITER E'\t';
EOF
