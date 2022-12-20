#!/usr/bin/env bash

# Arguments:
# List of cell group IDs separated with commas
# Number of marker genes per group (defaults to 5)
psql -q -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h ${POSTGRES_HOST} << EOF
DROP FUNCTION IF EXISTS sample_cell_group_marker_genes_by_cell_group_id;

CREATE FUNCTION sample_cell_group_marker_genes_by_cell_group_id(cell_group_ids int[], lim int)
    RETURNS TABLE (cgmg_id integer, cgmg_gene_id varchar, cgmg_cell_group_id integer, cgmg_marker_probability double precision,
                   cgmgs_gene_id varchar, cgmgs_cell_group_id integer, cgmgs_marker_id integer, cgmgs_expression_type smallint, cgmgs_mean_expression double precision, cgmgs_median_expression double precision) AS
\$\$
DECLARE
    cgi int;
BEGIN
  FOREACH cgi IN ARRAY cell_group_ids
  LOOP
    RETURN QUERY
        SELECT
            cgmg.*,
            cgmgs.*
        FROM
            scxa_cell_group_marker_genes cgmg
        RIGHT JOIN
            scxa_cell_group_marker_gene_stats cgmgs
            ON
                cgmg.id = cgmgs.marker_id
                AND
                cgmg.gene_id = cgmgs.gene_id
                AND
                cgmg.cell_group_id = cgmgs.cell_group_id
        WHERE
            cgmg.cell_group_id = cgi
            AND
            cgmg.marker_probability < 0.05
        ORDER BY random()
        LIMIT lim;
  END LOOP;
END;
\$\$ LANGUAGE plpgsql;

COPY (
    SELECT
        *
    FROM
        sample_cell_group_marker_genes_by_cell_group_id(ARRAY[${1}], ${2:-5})
    ORDER BY
        cgmg_id
) TO STDOUT DELIMITER E'\t';

DROP FUNCTION sample_cell_group_marker_genes_by_cell_group_id;
EOF
