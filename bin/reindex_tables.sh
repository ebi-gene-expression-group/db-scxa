#!/usr/bin/env bash
set -e
psql -v ON_ERROR_STOP=1 $dbConnection <<EOF
SET maintenance_work_mem='2GB';
REINDEX TABLE scxa_coords;
REINDEX TABLE scxa_marker_genes;
REINDEX TABLE scxa_cell_clusters;
REINDEX TABLE experiment;

CLUSTER scxa_marker_genes USING scxa_marker_genes_experiment_accession_gene_id_k_cluster_id_pk;
CLUSTER scxa_cell_clusters USING scxa_cell_clusters_experiment_accession_cell_id_k_pk;
RESET maintenance_work_mem;
EOF
