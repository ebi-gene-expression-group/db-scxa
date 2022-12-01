#!/usr/bin/env bash

psql -q -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h ${POSTGRES_HOST} << EOF
COPY (
    SELECT
        *
    FROM
        scxa_cell_group scg
    WHERE
        scg.experiment_accession = '${1}'
        AND
        scg.variable IN (
            (SELECT * FROM (
                SELECT
                    DISTINCT cg.variable
                FROM
                    scxa_cell_group cg
                INNER JOIN
                    scxa_cell_group_marker_genes cgmg
                    ON
                        cg.id = cgmg.cell_group_id
                WHERE
                    cg.experiment_accession='${1}'
                    AND
                    cg.variable ~ '^[12]'
                    AND
                    cgmg.marker_probability < 0.05
            ) low_clustering_with_marker_genes
            ORDER BY random()
            LIMIT 2)
            UNION
            (SELECT * FROM (
                SELECT
                    DISTINCT cg.variable
                FROM
                    scxa_cell_group cg
                INNER JOIN
                    scxa_cell_group_marker_genes cgmg
                    ON
                        cg.id = cgmg.cell_group_id
                WHERE
                    cg.experiment_accession='${1}'
                    AND
                    cg.variable ~ 'inferred cell type'
                    AND
                    cgmg.marker_probability < 0.05
            ) cell_types_with_marker_genes
            ORDER BY random()
            LIMIT 1))
) TO STDOUT DELIMITER E'\t';
EOF
