/*
 Taken from https://github.com/ebi-gene-expression-group/atlas/blob/700ab1f2faff5361c953ec656ef5ae79c522006a/atlas-misc/scripts/db_updates/single-cell/20180130-create-tsne-table.sql
*/

DROP TABLE IF EXISTS scxa_tsne;

CREATE TABLE scxa_tsne
(
  experiment_accession VARCHAR(255) NOT NULL,
  cell_id              VARCHAR(255) NOT NULL,
  x                    DOUBLE PRECISION,
  y                    DOUBLE PRECISION,
  perplexity           INTEGER      NOT NULL,
  CONSTRAINT scxa_tsne_experiment_accession_cell_id_perplexity_pk
  PRIMARY KEY (experiment_accession, cell_id, perplexity)
);
