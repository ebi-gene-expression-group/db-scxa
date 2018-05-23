/*
  This script creates the master table where partitions will
  be plugged in
  No indices or other constraints can be defined at this level
*/

--DROP TABLE IF EXISTS scxa_analytics CASCADE;

CREATE TABLE IF NOT EXISTS scxa_analytics
(
  experiment_accession VARCHAR(255)     NOT NULL,
  gene_id              VARCHAR(255)     NOT NULL,
  cell_id              VARCHAR(255)     NOT NULL,
  expression_level     DOUBLE PRECISION
) PARTITION BY LIST (experiment_accession);
