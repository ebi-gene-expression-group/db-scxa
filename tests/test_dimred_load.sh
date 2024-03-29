#!/usr/bin/env bash

delete_db_scxa_dimred.sh 

# Normally we won't be extracting parameter values from file names, but we'll
# do it just for testing

ls ${EXPERIMENT_DIMRED_PATH}/${EXP_ID}.tsne*.tsv | while read -r l; do
  export DIMRED_TYPE=t-SNE
  export DIMRED_FILE_PATH=$l
  paramval=$(echo "$l" | sed 's/.*[^0-9]\([0-9]*\).tsv/\1/g')
  export DIMRED_PARAM_JSON='[{"perplexity": '$paramval'}]'
  load_db_scxa_dimred.sh
done

ls ${EXPERIMENT_DIMRED_PATH}/${EXP_ID}.umap*.tsv | while read -r l; do
  export DIMRED_TYPE=UMAP
  export DIMRED_FILE_PATH=$l
  paramval=$(echo "$l" | sed 's/.*[^0-9]\([0-9]*\).tsv/\1/g')
  export DIMRED_PARAM_JSON='[{"n_neighbors": '$paramval'}]'
  load_db_scxa_dimred.sh
done
