#!/usr/bin/env bash

set -e

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )

dbConnection=${dbConnection:-$1}
COLL_ID=${COLL_ID:-$2}
COLL_NAME=${COLL_NAME:-$3}
COLL_DESC=${COLL_DESC:-$4}
COLL_ICON_PATH=${COLL_ICON_PATH:-$5}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${COLL_ID+x} ] && echo "Env var COLL_ID for the id of the collection needs to be defined." && exit 1

update_column_value=()
#update_values=()
ICON_IMPORT=""

if [ -n "$COLL_NAME" ]; then
  #update_columns+=("name")
  #update_values+=("'$COLL_NAME'")
  update_column_value+=(" name = '$COLL_NAME'")
fi

if [ -n "$COLL_DESC" ]; then
  #update_columns+=("description")
  #update_values+=("'$COLL_DESC'")
  update_column_value+=(" description = '$COLL_DESC'")
fi

if [ -f "$COLL_ICON_PATH" ]; then
  ICON_IMPORT="\lo_import '${COLL_ICON_PATH}' \\\\ "
  #update_columns+=("icon")
  #update_values+=("lo_get(:LASTOID)")
  update_column_value+=(" icon = lo_get(:LASTOID)")
fi

function join_by { local IFS="$1"; shift; echo "$*"; }

if [ ${#update_column_value[@]} -gt 0 ]; then
  columns_values=$(join_by , "${update_column_value[@]}")
  update_query="$ICON_IMPORT UPDATE collections SET $columns_values WHERE coll_id = '$COLL_ID'"
  echo $update_query
  echo $update_query |\
    psql -v ON_ERROR_STOP=1 $dbConnection
else
  echo "Nothing given to update!"
  echo "Env var COLL_NAME for the new name of the collection can be defined."
  echo "Env var COLL_DESC for the new description of the collection can be defined."
  echo "Env var COLL_ICON_PATH for the new icon of the collection can be defined."
  exit 1
fi
