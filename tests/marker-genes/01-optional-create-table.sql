/*
 Taken from https://github.com/ebi-gene-expression-group/atlas/blob/master/atlas-misc/scripts/db_updates/single-cell/20170607-create-markergenes-table.sql
*/

DROP TABLE scxa_marker_genes CASCADE;

CREATE TABLE IF NOT EXISTS scxa_marker_genes
(
    experiment_accession VARCHAR(255)     NOT NULL,
    gene_id              VARCHAR(255)     NOT NULL,
    k                    INTEGER          NOT NULL,
    cluster_id           INTEGER          NOT NULL,
    marker_probability   DOUBLE PRECISION NOT NULL,
    CONSTRAINT scxa_marker_genes_experiment_accession_gene_id_k_pk
    PRIMARY KEY (experiment_accession, gene_id, k)
);

CREATE TABLE IF NOT EXISTS scxa_top_5_marker_genes_per_cluster
(
    r integer not null,
    experiment_accession varchar(255) not null,
    gene_id varchar(255) not null,
    k integer not null,
    cluster_id integer not null,
    marker_probability double precision not null,
    constraint scxa_top_5_marker_genes_per_cluster_experiment_accession_gene_id_k_cluster_id_pk
      primary key (experiment_accession, gene_id, k, cluster_id)
);

CREATE TABLE IF NOT EXISTS scxa_marker_gene_stats
(
    experiment_accession varchar(255) not null,
    gene_id varchar(255) not null,
    k_where_marker integer not null,
    cluster_id_where_marker integer not null,
    cluster_id integer not null,
    marker_p_value double precision not null,
    mean_expression float,
    median_expression float,
    constraint scxa_marker_gene_stats_experiment_accession_k_where_marker
        primary key (experiment_accession, gene_id, k_where_marker, cluster_id_where_marker, cluster_id)
);
