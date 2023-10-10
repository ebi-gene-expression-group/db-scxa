#!/usr/bin/env bash

# generate-fixtures.sh 'EXPERIMENT_ACCESSION [EXPERIMENT_ACCESSION]...'
#
# Generate database fixtures of one or more experiments in TSV and SQL format.
#
# POSTGRES_USER=atlasprd3 \
# POSTGRES_DB=gxpscxadev \
# generate-fixtures.sh \
# 'E-CURD-4 17' 'E-EHCA-2 24' 'E-GEOD-71585 19' 'E-GEOD-81547 24' 'E-GEOD-99058 7' 'E-MTAB-5061 25' 'E-ENAD-53 14'
#
# An aggregate SQL file is written for all experiments:
# - scxa_analytics.sql
# - scxa_dimension_reduction.sql
# - scxa_coords.sql
# - scxa_cell_group_membership.sql
# - scxa_cell_group_marker_genes.sql
# - scxa_cell_group_marker_gene_stats.sql
# - scxa_cell_group.sql
# A directory with the suffix -fixture (e.g. E-MTAB-5061-fixture) is created for each experiment accession passed as an
# argument, where the TSV files are stored for reference.

# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
# https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )"

export POSTGRES_HOST=${POSTGRES_HOST:-localhost}
export POSTGRES_PORT=${POSTGRES_PORT:-5432}


# Query DB and export data to TSV files, remember to pass argument as a string!
for EXP_ID_K in "${@:1}"
do
  ARG_ARRAY=(${EXP_ID_K})
  EXP_ID=${ARG_ARRAY[0]}
  SEL_K=${ARG_ARRAY[1]}
  ${SCRIPT_DIR}/generate-tsv-fixture.sh ${EXP_ID} ${SEL_K}
  ${SCRIPT_DIR}/transform-tsv-to-sql-insert.sh
  TSV_FIXTURE_TARGET_DIR=${EXP_ID}-fixture
  mkdir ${TSV_FIXTURE_TARGET_DIR}
  mv *.tsv ${TSV_FIXTURE_TARGET_DIR}
done
