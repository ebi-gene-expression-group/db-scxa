#!/usr/bin/env bash

# Arguments:
# Experiment accession
# List of marker gene IDs, separated with commas
# List of cell IDs, separated with commas
# Number of non-marker genes to add for each cell (defaults to 10)
psql -q -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h ${POSTGRES_HOST} << EOF
DROP FUNCTION IF EXISTS sample_scxa_analytics;

CREATE FUNCTION sample_scxa_analytics(exp_id varchar, gene_ids varchar[], cell_ids varchar[], lim int)
    RETURNS TABLE (experiment_accession varchar, gene_id varchar, cell_id varchar, expression_level double precision) AS
\$\$
DECLARE
    one_gene_id varchar;
    one_cell_id varchar;
BEGIN
  FOREACH one_gene_id IN ARRAY gene_ids
  LOOP
      RETURN QUERY
          SELECT *
          FROM scxa_analytics a
          WHERE
              a.experiment_accession=exp_id
              AND
              a.gene_id = one_gene_id
              AND
              a.cell_id = ANY(cell_ids);
  END LOOP;

  FOREACH one_cell_id IN ARRAY cell_ids
  LOOP
      RETURN QUERY
          SELECT *
          FROM scxa_analytics a
          WHERE
              a.experiment_accession='${1}'
              AND
              a.cell_id = one_cell_id
              AND
              a.gene_id <> ALL(gene_ids)
          ORDER BY random()
          LIMIT lim;
  END LOOP;
END;
\$\$ LANGUAGE plpgsql;

COPY (
    SELECT
        *
    FROM
        sample_scxa_analytics('${1}', ARRAY[${2}], ARRAY[${3}], ${4:-10})
) TO STDOUT DELIMITER E'\t';

DROP FUNCTION sample_scxa_analytics;
EOF
