#!/usr/bin/env bash
set -e
psql -v ON_ERROR_STOP=1 $dbConnection <<EOF
SET maintenance_work_mem='2GB';
REINDEX TABLE scxa_coords;
REINDEX TABLE scxa_cell_group;
REINDEX TABLE scxa_cell_group_membership;
REINDEX TABLE scxa_cell_group_marker_genes;
REINDEX TABLE scxa_cell_group_marker_gene_stats; 
REINDEX TABLE experiment;

RESET maintenance_work_mem;
EOF
