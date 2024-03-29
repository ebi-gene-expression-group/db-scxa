#!/usr/bin/env bash

# This script takes the marker genes data, normally available in an scxa
# sc_bundle, which is split in different files one per k_value (number of
# clusters) or cell annotation type and loads them into the
# scxa_cell_groups_marker_genes table of AtlasProd.
set -e

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )
source $scriptDir/common_routines.sh

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}
EXPERIMENT_MGENES_PATH=${EXPERIMENT_MGENES_PATH:-$3}
SCRATCH_DIR=${SCRATCH_DIR:-"$EXPERIMENT_MGENES_PATH"}
MGENES_PREFIX=${MGENES_PREFIX:-"$EXP_ID.marker_genes_"}
MGENES_SUFFIX=${MGENES_SUFFIX:-".tsv"}
CLUSTERS_FORMAT=${CLUSTERS_FORMAT:-"ISL"}

# Check that necessary environment variables are defined.
[ ! -z ${dbConnection+x} ] || (echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1)
[ ! -z ${EXP_ID+x} ] || (echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1)
[ ! -z ${EXPERIMENT_MGENES_PATH+x} ] || (echo "Env var EXPERIMENT_MGENES_PATH for location of marker genes files for web needs to be defined." && exit 1)

# Check that format of marker genes file is supported
if [[ ! "$CLUSTERS_FORMAT" =~ ^(ISL|SCANPY)$ ]]; then
    echo "CLUSTERS_FORMAT $CLUSTERS_FORMAT is not supported."
    exit 1
fi

print_log() {
    local message=$1
    local level=${2:-'1'}

    echo [`date "+%m/%d/%Y %H:%M:%S"`] "$(printf '%.s ' $(seq 1 $((level * 4))))" "$message"
}

# Check that database connection is valid
checkDatabaseConnection $dbConnection

# Input files may expect in the bundles
cellgroupMarkerStatsCount=$EXPERIMENT_MGENES_PATH/${EXP_ID}.marker_stats_filtered_normalised.tsv
cellgroupMarkerStatsTPM=$EXPERIMENT_MGENES_PATH/${EXP_ID}.marker_stats_tpm_filtered.tsv

# Files we'll be using (and cleaning up)
markerGenesToLoad=$SCRATCH_DIR/mgenesDataToLoad.csv
groupIds=$SCRATCH_DIR/groupIds.csv
groupMarkerIds=$SCRATCH_DIR/groupMarkerIds.csv
groupMarkerGenesToLoad=$SCRATCH_DIR/groupMarkerGenesToLoad.csv
groupMarkerStatsToLoad=$SCRATCH_DIR/groupMarkerStatsToLoad.csv
groupMarkerStatsWithIDs=$SCRATCH_DIR/groupMarkerStatsWithIDs

if [[ -z ${NUMBER_MGENES_FILES+x} || $NUMBER_MGENES_FILES -gt 0 ]]; then
  # Check that files are in place.
  [ $(ls -1 $EXPERIMENT_MGENES_PATH/$MGENES_PREFIX*$MGENES_SUFFIX | wc -l) -gt 0 ] \
    || (echo "No marker gene files could be found on $EXPERIMENT_MGENES_PATH" && exit 1)
else
  echo "WARNING No marker gene files declared on MANIFEST."
fi

if [[ -z ${NUMBER_MGENES_FILES+x} || $NUMBER_MGENES_FILES -gt 0 ]]; then
  # Create file with data
  # Please note that this relies on:
  # - Column ordering on the marker genes file: clusts padj auroc feat
  # - Table ordering of columns: experiment_accession gene_id k cluster_id marker_probability
  print_log "Marker genes: Create data file for $EXP_ID..."
  rm -f $markerGenesToLoad
  for f in $(ls $EXPERIMENT_MGENES_PATH/$MGENES_PREFIX*$MGENES_SUFFIX); do
    k=$(echo $f | sed s+$EXPERIMENT_MGENES_PATH/$MGENES_PREFIX++ | sed s/$MGENES_SUFFIX// )
    if [ -e $EXPERIMENT_MGENES_PATH/$EXP_ID.clusters.tsv ]; then
      # check that k is present in the second column of $EXP_ID.clusters.tsv,
      # if such a file exists.
      if ! awk '{ print $2 }' $EXPERIMENT_MGENES_PATH/$EXP_ID.clusters.tsv | tail -n +2 | grep -q ^$k$; then
        echo "Skipping k=$k as it is not available in $EXP_ID.clusters.tsv file."
        continue
      fi
    fi
    if [ "$CLUSTERS_FORMAT" == "ISL" ]; then
      # ISL produces marker genes with the following fields:
      # clusts  padj    auroc   feat
      tail -n +2 $f | awk -F'\t' -v EXP_ID="$EXP_ID" -v k_value="$k" 'BEGIN { OFS = ","; }
      { print EXP_ID, $4, k_value, $1, $2 }' >> $markerGenesToLoad
    elif [ "$CLUSTERS_FORMAT" == "SCANPY" ]; then
      # Scanpy produces marker genes with the following fields with value like:
      #
      # cluster	ref	rank	genes	scores	logfoldchanges	pvals	pvals_adj
      # 0	rest	0	FBgn0003448	20.580915	6.0675416	2.3605626738867564e-47	1.1128872726039114e-43
      tail -n +2 $f | awk -F'\t' -v EXP_ID="$EXP_ID" -v k_value="$k" 'BEGIN { OFS = ","; }
      { print EXP_ID, $4, k_value, $1, $8 }' >> $markerGenesToLoad
    else
      echo "ERROR: unrecognized CLUSTERS_FORMAT '"$CLUSTERS_FORMAT"', aborting load."
      echo "ERROR: this point should not have been reached..."
      exit 1
    fi
  done

  # Load data
  print_log "Marker genes: Loading data for $EXP_ID..."

  set +e
  print_log "## Loading Marker genes for $EXP_ID."

  # NEW LAYOUT: point at cell groups table, retrieving cell group integer IDs from there first

  print_log "## Cleaning pre-existing marker genes for $EXP_ID (new layout)."
  echo "DELETE FROM scxa_cell_group_marker_gene_stats WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"')" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  echo "DELETE FROM scxa_cell_group_marker_genes WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"')" | \
    psql -v ON_ERROR_STOP=1 $dbConnection
  print_log "## Done cleaning pre-existing marker genes for $EXP_ID (new layout)."

  # Get the group keys back from the auto-increment

  echo "\copy (select concat(experiment_accession, '_', variable, '_', value), id from scxa_cell_group WHERE experiment_accession = '"$EXP_ID"' ORDER BY experiment_accession, variable, value) TO '$groupIds' DELIMITER '|' CSV HEADER" | \
    psql -v ON_ERROR_STOP=1 $dbConnection

  # The join we need later is particular about sort order
  tail -n +2 $groupIds | sort -t'|' -k 1,1 > ${groupIds}.tmp && mv ${groupIds}.tmp ${groupIds}

  # Get marker genes in the format 'expid_variable_value,cell_id,padj, where experiment, variable and value define the cell grouping
  # First for cluster markers (with groups like k_1 etc)

  cat $markerGenesToLoad | awk -F',' 'BEGIN { OFS = "|"; } {print $1"_"$3"_"$4, $2, $5}' > ${groupMarkerGenesToLoad}.tmp

  # Add in the markers from annotation source- basically match any non-numeric
  # field in the file name

  re='^[0-9]+$'

  for markerGenesFile in $(ls $EXPERIMENT_MGENES_PATH/${EXP_ID}.marker_genes*.tsv); do
    markerType=$(basename $markerGenesFile | sed 's/.*.marker_genes_//' | sed 's/.tsv//')

    if ! [[ "$markerType" =~ $re ]] ; then
        spacedCellGroupType=$(echo -e "$markerType" | sed 's/_/ /g')
        tail -n +2 $markerGenesFile | awk -F'\t' -v EXP_ID="$EXP_ID" -v CELL_GROUP_TYPE="$spacedCellGroupType" 'BEGIN { OFS = "|"; } { gsub("^nan$","Not available",$1); print EXP_ID"_"CELL_GROUP_TYPE"_"$1, $4, $8 }' >> ${groupMarkerGenesToLoad}.tmp
    fi
  done

  # Sort and join with the groups file to add the auto-incremented key from the groups table
  cat ${groupMarkerGenesToLoad}.tmp |  sort -t'|' -k 1,1 > ${groupMarkerGenesToLoad}.tmp.sorted && rm -f ${groupMarkerGenesToLoad}.tmp

  join -t '|' $groupIds ${groupMarkerGenesToLoad}.tmp.sorted | awk -F'|' 'BEGIN { OFS = "|"; } {print $3,$2,$4}' > ${groupMarkerGenesToLoad}

  nStartingMarkers=$(wc -l ${groupMarkerGenesToLoad}.tmp.sorted | awk '{print $1}')
  nFinalMarkers=$(wc -l ${groupMarkerGenesToLoad} | awk '{print $1}')

  # Sanity check that the join worked

  if [ ! "$nStartingMarkers" -eq "$nFinalMarkers" ]; then
    echo "Final list of marker values in ${groupMarkerGenesToLoad} ($nFinalMarkers) not equal to input number from ${groupMarkerGenesToLoad}.tmp.sorted ($nStartingMarkers) after resolving keys to cell groups table." 1>&2
    exit 1
  fi

  printf "\copy scxa_cell_group_marker_genes (gene_id, cell_group_id, marker_probability) FROM '%s' WITH (DELIMITER '|');" ${groupMarkerGenesToLoad} | \
    psql -v ON_ERROR_STOP=1 $dbConnection

  s=$?

  # Roll back if write was unsucessful

  if [ $s -ne 0 ]; then
    echo "Group marker table write failed" 1>&2
    echo "DELETE FROM scxa_cell_group_marker_genes WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"')" | \
      psql -v ON_ERROR_STOP=1 $dbConnection
    exit 1
  fi

  print_log "## Group marker genes (new layout): Loading done for $EXP_ID..."
  print_log "## Loading maker statistics for $EXP_ID"

  # The marker stats table has two foreign keys- one to the cell group table,
  # one to the marker genes table. We already downloaded the cell groups, now
  # we also need the integer primary keys of the markers

  echo "DELETE FROM scxa_cell_group_marker_gene_stats WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"')" | \
    psql -v ON_ERROR_STOP=1 $dbConnection

  echo "\copy (select concat(gene_id, '_', cell_group_id), id from scxa_cell_group_marker_genes WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"') ORDER BY gene_id, cell_group_id) TO '$groupMarkerIds' DELIMITER '|' CSV HEADER" | \
    psql -v ON_ERROR_STOP=1 $dbConnection

  # The join we need later is particular about sort order
  tail -n +2 $groupMarkerIds | sort -t'|' -k 1,1 > ${groupMarkerIds}.tmp && mv ${groupMarkerIds}.tmp ${groupMarkerIds}

  for expressionType in counts tpm; do

    if [ "$expressionType" == 'counts' ]; then
        cellgroupMarkerStats=$cellgroupMarkerStatsCount
        typeCode=0
    elif [ "$expressionType" == 'tpm' ]; then
        cellgroupMarkerStats=$cellgroupMarkerStatsTPM
        typeCode=1
    fi

    if [ ! -e "$cellgroupMarkerStats" ]; then
        echo "$cellgroupMarkerStats not found, not loading TPM stats (probably droplet experiment)" 1>&2
        if [ $expressionType = 'counts' ]; then
            exit 1
        else
            continue
        fi
    fi

    # The following nested joins get two group identifiers (one for the cell
    # group, one for the cell group for which the marker was identified), the
    # latter of which is then used to find the marker identifier.
    #
    # The complex seds here sort out commas used as delimiters from those used
    # as part the cell type field. In retrospect we shouln't have used commas,
    # and this can be addressed at a later date.

    join -t '|' \
      $groupIds \
      <(join -t '|' \
        $groupIds \
        <(tail -n +2 "${cellgroupMarkerStats}" | sed 's/, /REALCOMMA/g' | sed s/\"//g | sed s/,/\|/g | sed 's/REALCOMMA/, /g' |awk -F'|' -v EXP_ID="$EXP_ID" 'BEGIN { OFS = "|"; } {gsub("_", " ", $2); gsub("^None$","Not available",$3); gsub("^None$","Not available",$4); print EXP_ID"_"$2"_"$4,EXP_ID"_"$2"_"$3,$1,$2,$3,$4,$6,$7 }' | sort -t'|' -k 1,1) | \
        awk -F'|' 'BEGIN { OFS = "|"; } { print $3,$2,$4,$5,$6,$7,$8,$9 }' | sort -t'|' -k 1,1
      ) | awk -F'|' 'BEGIN { OFS = "|"; } { print $4"_"$2,$3,$2,$4,$5,$6,$7,$8,$9 }' | sort -t'|' -k 1,1 > $groupMarkerStatsWithIDs


    join -t '|' $groupMarkerIds $groupMarkerStatsWithIDs | awk -F'|' -v TYPE_CODE=$typeCode 'BEGIN { OFS = "|"; } {print $5, $3, $2, TYPE_CODE, $9, $10 }' > $groupMarkerStatsToLoad

    nStartingStats=$(tail -n +2 $cellgroupMarkerStats | wc -l)
    nFinalStats=$(wc -l ${groupMarkerStatsToLoad} | awk '{print $1}')

    # Sanity check that the join worked

    if [ ! "$nStartingStats" -eq "$nFinalStats" ]; then
      echo "Final list of marker stats values ($nFinalStats) from ${groupMarkerStatsToLoad}, derived from ${cellgroupMarkerStats}, not equal to input number ($nStartingStats) from $cellgroupMarkerStats after resolving keys to cell groups table." 1>&2
      echo "This list of markers comes from a join between files coming from the metadata (groupMarkerIDs) and from the analysis (the markers file)." 1>&2
      echo "In the past, this error has been traced to differences between the cells.txt metadata file (curators SCXA Metadata gitlab repo) and the Scanpy analysis results, containing different cell type categories." 1>&2
      echo "This can be checked by looking at the condensed SDRF or the SDRF file inferred cell type, and comparing it with the <accession>.marker_genes_inferred_cell_type_-_ontology_labels.tsv file, derived from the tertiary analysis." 1>&2
      exit 1
    fi

    # Try the DB load
    print_log "Loading $groupMarkerStatsToLoad"
    printf "\copy scxa_cell_group_marker_gene_stats (gene_id, cell_group_id, marker_id, expression_type,  mean_expression, median_expression) FROM '%s' WITH (DELIMITER '|');" ${groupMarkerStatsToLoad} | \
      psql -v ON_ERROR_STOP=1 $dbConnection

    s=$?

    # Roll back if write was unsucessful

    if [ $s -ne 0 ]; then
      echo "Group marker table write failed" 1>&2
      echo "DELETE FROM scxa_cell_group_marker_gene_stats WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"') and expression_type = $typeCode" | \
        psql -v ON_ERROR_STOP=1 $dbConnection
      exit 1
    fi
    rm -f ${groupMarkerStatsToLoad}
 done

 print_log "## Group marker gene statistics: Loading done for $EXP_ID..."

 # Clean up
 rm -f $markerGenesToLoad $groupIds ${groupMarkerGenesToLoad} ${groupMarkerGenesToLoad}.tmp.sorted $groupMarkerIds

fi
