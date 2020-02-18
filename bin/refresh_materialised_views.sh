#!/usr/bin/env bash
set -e
echo "REFRESH MATERIALIZED VIEW scxa_top_5_marker_genes_per_cluster;" | psql -v ON_ERROR_STOP=1 $dbConnection
echo "REFRESH MATERIALIZED VIEW scxa_marker_gene_stats;" | psql -v ON_ERROR_STOP=1 $dbConnection
