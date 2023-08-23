#!/usr/bin/env bash

set -e

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

postgres_scripts_dir=$scriptDir/../postgres_routines

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}
FIELDS=${FIELDS:-$3}

# Check that necessary environment variables are defined.
[ -z ${dbConnection+x} ] && echo "Env var dbConnection for the database connection needs to be defined. This includes the database name." && exit 1
[ -z ${EXP_ID+x} ] && echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1
[ -z ${FIELDS+x} ] && echo "Env var FIELDS for fields (comma separated) from the experiment table to retrieve needs to be defined." && exit 1

fields=$(echo $FIELDS | sed 's/,/, /' )
echo "SELECT $fields FROM experiment WHERE accession='"${EXP_ID}"'" | \
    psql -v ON_ERROR_STOP=1 -F ',' -A $dbConnection | awk 'NR == 2'
