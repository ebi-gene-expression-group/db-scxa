#!/usr/bin/env bash

# This script receives a collection identifier, name and description
# and stores it in the
set -e

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $scriptDir/db_scxa_common.sh

dbConnection=${dbConnection:-$1}
COLL_ID=${COLL_ID:-$2}
EXP_IDS=${EXP_IDS:-$3}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${COLL_ID+x} ] && echo "Env var COLL_ID for the id of the collection needs to be defined." && exit 1
[ -z ${EXP_IDS+x} ] && echo "Env var EXP_IDS for a comma-separated list of EXP_IDs to add, name of the experiment needs to be defined." && exit 1

IFS=',' # comma is set as delimiter
read -ra EXPS <<< "$EXP_IDS" # str is read into an array as tokens

set +e
error=0
for exp_id in "${EXPS[@]}"; do
  echo "INSERT INTO experiment2collection (exp_acc, coll_id) VALUES ('${exp_id}','${COLL_ID}')" |\
    psql -v ON_ERROR_STOP=1 $dbConnection
  if [ "$?" -ne 0 ]; then
    echo "Failed to insert $exp_id into the collection $COLL_ID"
    error=1
  else
    echo "Inserted $exp_id int $COLL_ID"
  fi
done

if [ "$error" -eq 1 ]; then
  echo "Some experiments failed..."
  exit 1
fi
