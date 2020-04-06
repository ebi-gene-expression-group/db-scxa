#!/usr/bin/env bash

# This script receives a collection identifier, name and description
# and stores it in the
set -e

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
COLL_ID=${COLL_ID:-$2}
COLL_NAME=${COLL_NAME:-$3}
COLL_DESC=${COLL_DESC:-$4}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${COLL_ID+x} ] && echo "Env var COLL_ID for the id of the collection needs to be defined." && exit 1
[ -z ${COLL_NAME+x} ] && echo "Env var COLL_NAME for the name of the experiment needs to be defined." && exit 1

echo "INSERT INTO collections (coll_id, name, description) VALUES ('${COLL_ID}','${COLL_NAME}', '${COLL_DESC}')" |\
 psql -v ON_ERROR_STOP=1 $dbConnection
