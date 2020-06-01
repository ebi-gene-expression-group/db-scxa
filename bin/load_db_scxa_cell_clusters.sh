#!/usr/bin/env bash

# This script takes the marker genes data, normally available in an irap
# sc_bundle, which is split in different files one per k_value (number of clusters)
# and loads it into the scxa_marker_genes table of AtlasProd.
set -e

# TODO this type of function should be loaded from a common set of scripts.

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}
EXPERIMENT_CLUSTERS_FILE=${EXPERIMENT_CLUSTERS_FILE:-$3}
SCRATCH_DIR=${SCRATCH_DIR:-$(cd "$( dirname "${EXPERIMENT_CLUSTERS_FILE}" )" && pwd )}
CELL_GROUP_TYPES=${CELL_GROUP_TYPES:-"inferred cell type,authors inferred cell type"}

# Check that necessary environment variables are defined.
[ ! -z ${dbConnection+x} ] || (echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1)
[ ! -z ${EXP_ID+x} ] || (echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1)
[ ! -z ${EXPERIMENT_CLUSTERS_FILE+x} ] || (echo "Env var EXPERIMENT_MGENES_PATH for location of marker genes files for web needs to be defined." && exit 1)

clustersToLoad=$SCRATCH_DIR/clustersToLoad.csv
groupMembershipsToLoad=$SCRATCH_DIR/groupMembershipsToLoad.csv
groupsToLoad=$SCRATCH_DIR/groupsToLoad.csv
groupIds=$SCRATCH_DIR/groupIds.csv
cellGroupMemberships=$SCRATCH_DIR/cellGroupMemberships.csv

print_log() {
    local message=$1
    local level=${2:-'1'}

    echo [`date "+%m/%d/%Y %H:%M:%S"`] "$(printf '%.s ' $(seq 1 $((level * 4))))" "$message"
}

cleanup() {
    rm -f $clustersToLoad $groupsToLoad ${groupsToLoad}.tmp $groupIds ${cellGroupMemberships}.tmp ${cellGroupMemberships} $groupMembershipsToLoad
}

cleanup

print_log "Clusters: Create data file for $EXP_ID..."
wideSCCluster2longSCCluster.R -c $EXPERIMENT_CLUSTERS_FILE -e $EXP_ID -o $clustersToLoad

# Delete clusters table content for current EXP_ID
print_log "clusters table: Delete rows for $EXP_ID:"
echo "DELETE FROM scxa_cell_group_membership WHERE experiment_accession = '"$EXP_ID"'" | \
  psql -v ON_ERROR_STOP=1 $dbConnection
echo "DELETE FROM scxa_cell_clusters WHERE experiment_accession = '"$EXP_ID"'" | \
  psql -v ON_ERROR_STOP=1 $dbConnection

# Load data
print_log "Clusters: Loading data for $EXP_ID..."
set +e
printf "\copy scxa_cell_clusters (experiment_accession, cell_id, k, cluster_id) FROM '%s' DELIMITER ',' CSV HEADER;" $clustersToLoad | \
  psql -v ON_ERROR_STOP=1 $dbConnection
s=$?

# Roll back if write was unsucessful

if [ $s -ne 0 ]; then
  echo "Clusters write failed" 1>&2
  echo "DELETE FROM scxa_cell_clusters WHERE experiment_accession = '"$EXP_ID"'" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  exit 1
fi

# NEW LAYOUT: define clusterings as cell groups in the DB

print_log "Cell groups: Loading for $EXP_ID (new layout)..."

# Also use annotation-based cell groups from the condensed SDRF, to be processed alongside the clusterings

tail -n +2 $clustersToLoad | sed s/\"//g | tail -n +2 $clustersToLoad | sed s/\"//g | awk -F',' 'BEGIN { OFS = "|"; } {print $1,$2,$3,$4}' > $groupMembershipsToLoad

if [ -n "$CONDENSED_SDRF_TSV" ]; then
  IFS=, additionalCellGroupTypes=($(echo "$CELL_GROUP_TYPES"))
  for additionalCellGroupType in "${additionalCellGroupTypes[@]}"; do
    grep -m 1 "$(printf '\t')$additionalCellGroupType$(printf '\t')" $CONDENSED_SDRF_TSV >/dev/null
    if [ $? -eq 0 ]; then
        grep "$(printf '\t')$additionalCellGroupType$(printf '\t')" $CONDENSED_SDRF_TSV | awk -F'\t' 'BEGIN { OFS = "|"; } {print $1,$3,$5,$6}' >> $groupMembershipsToLoad    
        
        # Add the option of the unknown cell type
        echo "${EXP_ID}|$additionalCellGroupType|Not available" >> ${groupsToLoad}.tmp
    fi
 done
fi

# Cell groups correspond of:
# 1. An experiment identifier
# 2. the cell grouping variable (e.g. a k-clustering or a variable from the
#    cell annoation)
# 3. The value that variable takes for a given cell group (e.g. cell type A,
#    cluster 2)
#
# We get the unique cell groups by just stripping out the atual cell ID from
# the row and uniqueifying

awk -F'|' 'BEGIN { OFS = "|"; } {print $1,$3,$4}' $groupMembershipsToLoad >> ${groupsToLoad}.tmp
cat ${groupsToLoad}.tmp | sort -t$'|' -k 1,1 | uniq > $groupsToLoad

# Delete existing content- including via FKs (though this should really cascade now)
print_log "Deleting existing grouping data..."
echo "DELETE FROM scxa_cell_group_marker_gene_stats WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"')" | \
  psql -v ON_ERROR_STOP=1 $dbConnection
echo "DELETE FROM scxa_cell_group_marker_genes WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"')" | \
  psql -v ON_ERROR_STOP=1 $dbConnection
echo "DELETE FROM scxa_cell_group WHERE experiment_accession = '"$EXP_ID"'" | \
  psql -v ON_ERROR_STOP=1 $dbConnection
print_log "Copying cell groups data to the db..."
printf "\copy scxa_cell_group (experiment_accession, variable, value) FROM '%s' DELIMITER '|' CSV;" $groupsToLoad | \
  psql -v ON_ERROR_STOP=1 $dbConnection
s=$?

# Roll back if write was unsucessful

if [ $s -ne 0 ]; then
  echo "Cell groups  write failed" 1>&2
  echo "DELETE FROM scxa_cell_group WHERE experiment_accession = '"$EXP_ID"'" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  exit 1
fi

# Get the group keys back from the auto-increment

echo "\copy (select concat(experiment_accession, '_', variable, '_', value), id from scxa_cell_group WHERE experiment_accession = '"$EXP_ID"' ORDER BY experiment_accession, variable, value) TO '$groupIds' DELIMITER '|' CSV" | \
  psql -v ON_ERROR_STOP=1 $dbConnection

# The join we need later is particular about sort order
cat $groupIds | sort -t$'|' -k 1,1 > ${groupIds}.tmp && mv ${groupIds}.tmp ${groupIds}

# Get the cell group memberships with a concatenated field to match the db
# query. We're converting the delimited 'experiment_variable_value' to the
# integer auto-increment ID from the cell groups table. The group membership is
# just the experiment ID, the cell ID, and the integer cell group ID

cat $groupMembershipsToLoad | awk -F'|' 'BEGIN { OFS = "|"; } {print $1"_"$3"_"$4,$1,$2}' |  sort -t'|' -k 1,1 > ${cellGroupMemberships}.tmp

# Join the cell group IDs to the cell cluster memberships
join -t '|' $groupIds ${cellGroupMemberships}.tmp | awk -F'|' 'BEGIN { OFS = "|"; } {print $2,$3,$4}' > ${cellGroupMemberships}

nStartingClusterMemberships=$(wc -l $groupMembershipsToLoad | awk '{print $1}')
nFinalClusterMemberships=$(wc -l ${cellGroupMemberships} | awk '{print $1}')

if [ ! "$nStartingClusterMemberships" -eq "$nFinalClusterMemberships" ]; then
    echo "Final list of cluster memberships from ${cellGroupMemberships} ($nFinalClusterMemberships) not equal to input number from $clustersToLoad ($nStartingClusterMemberships) after resolving keys to cell groups table." 1>&2
    exit 1
fi

echo "DELETE FROM scxa_cell_group_membership WHERE experiment_accession = '"$EXP_ID"'" | \
  psql -v ON_ERROR_STOP=1 $dbConnection
printf "\copy scxa_cell_group_membership (cell_group_id, experiment_accession, cell_id) FROM '%s' DELIMITER '|' CSV;" ${cellGroupMemberships} | \
  psql -v ON_ERROR_STOP=1 $dbConnection
s=$?

# Roll back if write was unsucessful

if [ $s -ne 0 ]; then
  echo "Cell group memberships write failed" 1>&2
  echo "DELETE FROM scxa_cell_group_membership WHERE experiment_accession = '"$EXP_ID"'" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  exit 1
fi

# Clean up

cleanup

print_log "Clusters: Loading done for $EXP_ID."
