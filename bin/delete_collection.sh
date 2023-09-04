#!/usr/bin/env bash

set -e

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
COLL_ID=${COLL_ID:-$2}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${COLL_ID+x} ] && echo "Env var COLL_ID for the id of the collection needs to be defined." && exit 1

echo "DELETE FROM collections WHERE coll_id='${COLL_ID}'" |\
 psql -v ON_ERROR_STOP=1 $dbConnection
