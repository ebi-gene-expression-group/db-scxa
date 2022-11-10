#!/usr/bin/env bash

set -e

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
COLL_ID=${COLL_ID:-$2}
COLL_NAME=${COLL_NAME:-$3}
COLL_DESC=${COLL_DESC:-$4}
COLL_ICON_PATH=${COLL_ICON_PATH:-$5}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${COLL_ID+x} ] && echo "Env var COLL_ID for the id of the collection needs to be defined." && exit 1
[ -z ${COLL_NAME+x} ] && echo "Env var COLL_NAME for the name of the experiment needs to be defined." && exit 1

ICON_IMPORT=""
ICON_INSERT_FIELD=""
ICON_INSERT_VALUE=""
if [ -f "$COLL_ICON_PATH" ]; then
  # \\ is the separator for multiple commands when passing queries through stdin for psql
  ICON_IMPORT="\lo_import '${COLL_ICON_PATH}' \\\\ "
  ICON_INSERT_FIELD=", icon"
  ICON_INSERT_VALUE=", lo_get(:LASTOID)"
fi
echo "$ICON_IMPORT INSERT INTO collections (coll_id, name, description $ICON_INSERT_FIELD) VALUES ('${COLL_ID}','${COLL_NAME}', '${COLL_DESC}' $ICON_INSERT_VALUE)" |\
 psql -v ON_ERROR_STOP=1 $dbConnection
