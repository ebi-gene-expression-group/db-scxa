#!/usr/bin/env bash

# First we get 10 cluster cell group IDs and 10 inferred cell type cell group IDs

# We choose 100 cell IDs that belong in each of those groups in scxa_cell_group_membership

# We choose 5 gene IDs in the marker genes table in each of those groups in scxa_marker_genes marker_prob<0.05
# We choose 20 gene IDs in the marker genes table in each of those groups in scxa_marker_genes marker_prob>0.05

# We choose 100 genes that are expressed in those cells via analytics table

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source ${SCRIPT_DIR}/utils.sh

# Get scxa_cell_group fixture of all groups with variable two low (<30) clustering values and one cell type value
# We ensure there are marker genes (this is for inferred cell type variable) just in case
# No need to join with stats because we pick all the values from the variable
# A low k for clusters means that there will be some clustering for our sample size of 50 cells later
${SCRIPT_DIR}/01-scxa-cell-group.sh ${1} ${2} \
> scxa_cell_group.tsv

# Get three marker genes with their stats, for each group (total of 3×8=24 genes)
# We need to to do a RIGHT JOIN because some marker genes don’t have stats (bug?)
CELL_GROUP_IDS=$(join_lines "$(cut -f 1 ./scxa_cell_group.tsv)")
${SCRIPT_DIR}/02-scxa-cell-group-marker-genes-right-join-scxa-cell-group-marker-gene-stats.sh ${CELL_GROUP_IDS} \
> ./scxa-marker-genes-and-scxa-marker-gene-stats.tsv

# The same gene can appear with same probability with different stats, in different cell groups
cut -f 1,2,3,4 ./scxa-marker-genes-and-scxa-marker-gene-stats.tsv | sort | uniq \
> scxa_cell_group_marker_genes.tsv

cut -f 5,6,7,8,9,10 ./scxa-marker-genes-and-scxa-marker-gene-stats.tsv \
> scxa_cell_group_marker_gene_stats.tsv

# scxa_cell_group_membership fixture: get memberships of 50 random cell IDs
${SCRIPT_DIR}/03-scxa-cell-group-membership.sh ${CELL_GROUP_IDS} 50 1 \
> scxa_cell_group_membership.tsv

MARKER_GENE_IDS=$(join_lines "$(cut -f 2 scxa_cell_group_marker_genes.tsv | sort | uniq)" "'")
CELL_IDS=$(join_lines "$(cut -f 2 scxa_cell_group_membership.tsv | sort | uniq)" "'")
# scxa_analytics_fixture: expression of the marker genes in the cell IDs obtained above (120*24=2880 records)
# plus 5 more not in those genes per cell
${SCRIPT_DIR}/04-scxa-analytics.sh $1 ${MARKER_GENE_IDS} ${CELL_IDS} 5 \
> scxa_analytics.tsv

# scxa_dimension_reduction fixture with 10 random projections
${SCRIPT_DIR}/05-scxa-dimension-reduction.sh $1 10 > scxa_dimension_reduction.tsv

DIMENSION_REDUCTION_IDS=$(join_lines "$(cut -f 1 scxa_dimension_reduction.tsv)")
# scxa_coords fixture: coordinates of the cell IDs in the reductions above
${SCRIPT_DIR}/06-scxa-coords.sh ${CELL_IDS} ${DIMENSION_REDUCTION_IDS} \
> scxa_coords.tsv
