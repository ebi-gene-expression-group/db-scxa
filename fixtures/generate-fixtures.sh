#!/usr/bin/env bash

# generate-fixtures.sh 'EXPERIMENT_ACCESSION [EXPERIMENT_ACCESSION]...'
#
# Generate database fixtures of one or more experiments in TSV and SQL format.
#
# POSTGRES_USER=atlasprd3 \
# POSTGRES_DB=gxpscxadev \
# generate-fixtures.sh \
# 'E-CURD-4 E-EHCA-2 E-GEOD-71585 E-GEOD-81547 E-GEOD-99058 E-MTAB-5061'
#
# A TSV and equivalent SQL file are written, a pair for each of the following
# tables:
# - scxa_analytics
# - scxa_coords
# - scxa_cell_group
# - scxa_cell_group_membership
# - scxa_cell_croup_marker_genes
# - scxa_cell_group_marker_gene_stats


# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
# https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

export POSTGRES_HOST=${POSTGRES_HOST:-localhost}
export POSTGRES_PORT=${POSTGRES_PORT:-5432}


# Query DB and export data to TSV files, remember to pass argument as a string!
for EXP_ID in $1
do
  ${SCRIPT_DIR}/01-sample-scxa_analytics.sh ${EXP_ID} 100 >> ./scxa_analytics.tsv
done

${SCRIPT_DIR}/02-scxa_coords.sh ./scxa_analytics.tsv > ./scxa_coords.tsv

# Rather than defining the cell groups we go in reverse: we pick up the cell group IDs for the selected cells
${SCRIPT_DIR}/03a-scxa_cell_group_membership.sh ./scxa_analytics.tsv > ./scxa_cell_group_membership.tsv
${SCRIPT_DIR}/03b-scxa_cell_group.sh ./scxa_cell_group_membership.tsv > ./scxa_cell_group.tsv

${SCRIPT_DIR}/04-scxa_cell_group_marker_genes.sh ./scxa_analytics.tsv > ./scxa_cell_group_marker_genes.tsv

${SCRIPT_DIR}/05-scxa_cell_group_marker_gene_stats.sh ./scxa_analytics.tsv > ./scxa_cell_group_marker_gene_stats.tsv


# Transform TSV files to SQL INSERTs
sed -En "s/(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_analytics(experiment_accession, gene_id, cell_id, expression_level) VALUES ('\1', '\2', '\3', \4);/p" scxa_analytics.tsv > scxa_analytics.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_coords(experiment_accession, method, cell_id, x, y, parameterisation) VALUES ('\1', '\2', '\3', \4, \5, '\6');/p" scxa_coords.tsv > scxa_coords.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_cell_group(id, experiment_accession, variable, value) VALUES (\1, '\2', '\3', '\4');/p" scxa_cell_group.tsv > scxa_cell_group.sql

sed -En "s/(.+)\t(.+)\t(.+)/INSERT INTO scxa_cell_group_membership(experiment_accession, cell_id, cell_group_id) VALUES ('\1', '\2', \3);/p" scxa_cell_group_membership.tsv > scxa_cell_group_membership.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_cell_group_marker_genes(id, gene_id, cell_group_id, marker_probability) VALUES (\1, '\2', \3, \4);/p" scxa_cell_group_marker_genes.tsv > scxa_cell_group_marker_genes.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_cell_group_marker_gene_stats(gene_id, cell_group_id, marker_id, expression_type, mean_expression, median_expression) VALUES ('\1', \2, \3, \4, \5, \6);/p" scxa_cell_group_marker_gene_stats.tsv > scxa_cell_group_marker_gene_stats.sql
