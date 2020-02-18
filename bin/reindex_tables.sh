#!/usr/bin/env bash
set -e
psql -v ON_ERROR_STOP=1 $dbConnection <<EOF
REINDEX TABLE scxa_tsne;
REINDEX TABLE scxa_marker_genes;
REINDEX TABLE scxa_cell_clusters;
REINDEX TABLE scxa_analytics;
REINDEX TABLE experiment;

CLUSTER;
EOF
