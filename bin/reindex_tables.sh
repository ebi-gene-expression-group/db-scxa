#!/usr/bin/env bash

psql $dbConnection <<EOF
REINDEX TABLE scxa_tsne;
REINDEX TABLE scxa_marker_genes;
REINDEX TABLE scxa_cell_clusters;
REINDEX TABLE scxa_analytics;
REINDEX TABLE experiment;
REINDEX TABLE scxa_top_5_marker_genes_per_cluster;
REINDEX TABLE scxa_marker_gene_stats;

CLUSTER;
EOF
