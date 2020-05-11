#!/usr/bin/env bash
set -e
psql -v ON_ERROR_STOP=1 $dbConnection <<EOF
SET maintenance_work_mem='2GB';
REINDEX TABLE scxa_tsne;
REINDEX TABLE scxa_marker_genes;
REINDEX TABLE scxa_cell_clusters;
REINDEX TABLE experiment;

CLUSTER scxa_tsne;
CLUSTER scxa_marker_genes;
CLUSTER scxa_cell_clusters;
CLUSTER experiment;
RESET maintenance_work_mem;
EOF
