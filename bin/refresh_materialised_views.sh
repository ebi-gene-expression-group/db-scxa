#!/usr/bin/env bash

echo "REFRESH MATERIALIZED VIEW scxa_top_5_marker_genes_per_cluster;" | psql $dbConnection
echo "REFRESH MATERIALIZED VIEW scxa_marker_gene_stats;" | psql $dbConnection
