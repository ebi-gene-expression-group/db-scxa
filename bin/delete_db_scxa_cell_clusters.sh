#!/usr/bin/env bash
set -e

[ -z ${EXP_ID+x} ] && echo "EXP_ID env var is needed." && exit 1

dbConnection=${dbConnection:-$1}
EXP_ID=${EXP_ID:-$2}

echo "DELETE FROM scxa_cell_clusters WHERE experiment_accession = '"$EXP_ID"'" | psql -v ON_ERROR_STOP=1 $dbConnection
echo "DELETE FROM scxa_cell_group WHERE experiment_accession = '"$EXP_ID"'" | psql -v ON_ERROR_STOP=1 $dbConnection
