#!/usr/bin/env bash

jar_dir=$CONDA_PREFIX/share/atlas-cli

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $scriptDir/common_routines.sh

echo "CONDA_PREFIX: $CONDA_PREFIX"

require_env_var "SOLR_HOST"
require_env_var "ZK_HOST"
require_env_var "ZK_PORT"
require_env_var "BIOENTITIES"
require_env_var "EXPERIMENT_FILES"
require_env_var "jdbc_url"
require_env_var "jdbc_username"
require_env_var "jdbc_password"

# Either ACCESSIONS or PRIVATE_ACCESSIONS need to be provided
#require_env_var "ACCESSIONS"

SOLR_PORT=$(get_port_from_hostport $SOLR_HOST)
SOLR_HOST=$(get_host_from_hostport $SOLR_HOST)

require_env_var "SOLR_PORT"

java_opts="-Dsolr.host=$SOLR_HOST"
java_opts="$java_opts -Dsolr.port=$SOLR_PORT"
java_opts="$java_opts -Dzk.host=$ZK_HOST"
java_opts="$java_opts -Dzk.port=$ZK_PORT"
java_opts="$java_opts -Ddata.files.location=$BIOENTITIES"
java_opts="$java_opts -Dexperiment.files.location=$EXPERIMENT_FILES"
java_opts="$java_opts -Djdbc.url=$jdbc_url"
java_opts="$java_opts -Djdbc.username=$jdbc_username"
java_opts="$java_opts -Djdbc.password=$jdbc_password"
java_opts="$java_opts -Djdbc.max_pool_size=2"
java_opts="$java_opts -Dserver.port=8888"
# This turns off some extensions for large vector calculations
# which are bit irrelevant to the current task and give issues on
# running this through an emulated container on M1
java_opts="$java_opts -XX:UseAVX=0"

# Generate JSONL files from bulk experiments
echo "PATH: "$PATH

cmd="java $java_opts -jar $jar_dir/atlas-cli-sc.jar"
cmd=$cmd" create-update-experiment"

if [ ! -z ${failed_accessions_output+x} ]; then
  cmd="$cmd -f $failed_accessions_output"
fi

if [ ! -z ${PRIVATE_ACCESSIONS+x} ]; then
  cmd="$cmd -p $PRIVATE_ACCESSIONS"
fi

if [ ! -z ${ACCESSIONS+x} ]; then
  cmd="$cmd -e $ACCESSIONS"
fi
echo "$cmd"
$cmd

status=$?

exit $status
