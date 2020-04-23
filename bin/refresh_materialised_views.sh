#!/usr/bin/env bash
set -e

psql -v ON_ERROR_STOP=1 $dbConnection <<EOF
SET maintenance_work_mem='2GB';
REFRESH MATERIALIZED VIEW scxa_top_5_marker_genes_per_cluster;
REFRESH MATERIALIZED VIEW scxa_marker_gene_stats;
RESET maintenance_work_mem;
EOF
