#!/usr/bin/env bash

# Arguments:
# List of cell group IDs separated with commas
# Number of cell IDs per group (defaults to 10)
psql -q -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h ${POSTGRES_HOST} << EOF
COPY (
    SELECT
        *
    FROM
        scxa_cell_group_membership
    WHERE
        cell_group_id = ANY(ARRAY[${1}])
        AND
        cell_id = ANY(
            SELECT * FROM (
                SELECT
                    DISTINCT(cgm.cell_id)
                FROM
                    scxa_cell_group_membership cgm
                WHERE
                    cgm.cell_group_id = ANY(ARRAY[${1}])
                ) cell_ids
            ORDER BY RANDOM()
            LIMIT ${2:-10})
) TO STDOUT DELIMITER E'\t';
EOF
