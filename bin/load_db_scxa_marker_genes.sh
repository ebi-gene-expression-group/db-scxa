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
EXPERIMENT_MGENES_PATH=${EXPERIMENT_MGENES_PATH:-$3}
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

# Check that database connection is valid
checkDatabaseConnection $dbConnection

markerGenesToLoad=$markerGenesToLoad
groupIds=$SCRATCH_DIR/groupIds.csv
inferredCelltypeMarkers=$EXPERIMENT_MGENES_PATH/celltype_markers.tsv
authorsInferredCelltypeMarkers=$EXPERIMENT_MGENES_PATH/authors_celltype_markers.tsv


if [[ -z ${NUMBER_MGENES_FILES+x} || $NUMBER_MGENES_FILES -gt 0 ]]; then
  # Check that files are in place.
  [ $(ls -1 $EXPERIMENT_MGENES_PATH/$MGENES_PREFIX*$MGENES_SUFFIX | wc -l) -gt 0 ] \
    || (echo "No marker gene files could be found on $EXPERIMENT_MGENES_PATH" && exit 1)
else
  echo "WARNING No marker gene files declared on MANIFEST."
fi

# Delete marker gene table content for current EXP_ID
echo "Marker genes: Delete rows for $EXP_ID:"
echo "DELETE FROM scxa_marker_genes WHERE experiment_accession = '"$EXP_ID"'" | \
  psql -v ON_ERROR_STOP=1 $dbConnection

if [[ -z ${NUMBER_MGENES_FILES+x} || $NUMBER_MGENES_FILES -gt 0 ]]; then
  # Create file with data
  # Please note that this relies on:
  # - Column ordering on the marker genes file: clusts padj auroc feat
  # - Table ordering of columns: experiment_accession gene_id k cluster_id marker_probability
  echo "Marker genes: Create data file for $EXP_ID..."
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
  echo "Marker genes: Loading data for $EXP_ID..."
  
  set +e
  printf "\copy scxa_marker_genes (experiment_accession, gene_id, k, cluster_id, marker_probability) FROM '%s' WITH (DELIMITER ',');" $markerGenesToLoad | \
    psql -v ON_ERROR_STOP=1 $dbConnection

  s=$?

  # Roll back if write was unsucessful
  
  if [ $s -ne 0 ]; then
    echo "Marker table write failed" 1>&2
    echo "DELETE FROM scxa_marker_genes WHERE experiment_accession = '"$EXP_ID"'" | \
      psql -v ON_ERROR_STOP=1 $dbConnection
    exit 1    
  fi

  echo "Marker genes: Loading done for $EXP_ID..."

  # NEW LAYOUT: point at cell groups table, retrieving cell group integer IDs from there first 

  # Get the group keys back from the auto-increment

  echo "\copy (select concat(experiment_accession, '_', variable, '_', value), id from scxa_cell_group WHERE experiment_accession = '"$EXP_ID"' ORDER BY experiment_accession, variable, value) TO '$groupIds' CSV HEADER" | \
    psql -v ON_ERROR_STOP=1 $dbConnection

  # Get marker genes in the format 'expid_variable_value,cell_id,padj, where experiment, variable and value define the cell grouping
  # First for cluster markers (with groups like k_1 etc)

  cat $markerGenesToLoad | awk -F',' '{print "\""$1"_k_"$3"_"$4"\",\""$2"\",\""$5"\""}' > ${groupMarkerGenesToLoad}.tmp
  
  # Add in the markers from annotation sources

  if [ -e "$inferredCelltypeMarkers" ]; then
    tail -n +2 $inferredCelltypeMarkers | awk -F'\t' -v EXP_ID="$EXP_ID" -'BEGIN { OFS = ","; } { print "\""EXP_ID"_inferred_cell_type_"$1"\"", "\""$4"\"", $8 }' >> ${groupMarkerGenesToLoad}.tmp
  fi
  if [ -e "$authorsInferredCelltypeMarkers" ]; then
    tail -n +2 $authorsInferredCelltypeMarkers | awk -F'\t' -v EXP_ID="$EXP_ID" 'BEGIN { OFS = ","; } { print "\""EXP_ID"_inferred_cell_type_"$1"\"", "\""$4"\"", $8 }' >> ${groupMarkerGenesToLoad}.tmp  
  fi

  # Sort and join with the groups file to add the auto-incremented key from the groups table
  cat ${groupMarkerGenesToLoad} | sort >> ${groupMarkerGenesToLoad}.tmp.sorted && rm -f ${groupMarkerGenesToLoad}.tmp
  join -t , $groupIds ${groupMarkerGenesToLoad}.tmp.sorted | cut -d',' --complement -f1 > ${groupMarkerGenesToLoad}

  nStartingMarkers=$(wc -l${groupMarkerGenesToLoad}.tmp.sorted | wc -l)
  nFinalMarkers=$(wc -l ${groupMarkerGenesToLoad} | awk '{print $1}')

  # Sanity check that the join worked

  if [ ! "$nStartingMarkers" -eq "$nFinalMarkers" ]; then
    echo "Final list of marker values ($nFinalMarkers) not equal to input number ($nStartingMarkers) after resolving keys to cell groups table." 1>&2
    exit 1
  fi

  printf "\copy scxa_cell_group_marker_genes (gene_id, cell_group_id, marker_probability) FROM '%s' WITH (DELIMITER ',');" ${groupMarkerGenesToLoad} | \
    psql -v ON_ERROR_STOP=1 $dbConnection

  s=$?

  # Roll back if write was unsucessful
  
  if [ $s -ne 0 ]; then
    echo "Group marker table write failed" 1>&2
    echo "DELETE FROM scxa_cell_group_marker_genes WHERE cell_group_id in (select id from scxa_cell_group where experiment_accession = '"$EXP_ID"')" | \
      psql -v ON_ERROR_STOP=1 $dbConnection
    exit 1    
  fi

  echo "Group marker genes: Loading done for $EXP_ID..."
  rm -f $markerGenesToLoad $groupIds ${groupMarkerGenesToLoad}

fi
