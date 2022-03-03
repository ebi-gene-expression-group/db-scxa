#!/usr/bin/env bash

export SOLR_HOST=my_solr:8983
export ZK_HOST=gxa-zk-1
export ZK_PORT=2181
export POSTGRES_HOST=postgres
export POSTGRES_DB=scxa-test
export POSTGRES_USER=scxa
export POSTGRES_PASSWORD=postgresPass
export POSTGRES_PORT=5432
export jdbc_url="jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"

docker_arch_line=""
if [ $( arch ) == "arm64" ]; then
    docker_arch_line="--platform linux/amd64"
    echo "Changing arch $docker_arch_line"
fi

dbConnection="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST/$POSTGRES_DB"
docker stop postgres && docker rm postgres
docker network rm mynet
docker network create mynet

docker run --rm --net mynet --name $ZK_HOST -d -p $ZK_PORT:$ZK_PORT -e ZOO_MY_ID=1 -e ZOO_SERVERS='server.1=0.0.0.0:2888:3888' -t zookeeper:3.5.8
docker run --rm --net mynet --name my_solr -d -p 8983:8983 -e ZK_HOST=$ZK_HOST:$ZK_PORT -t solr:7.7.1-alpine -DzkRun -Denable.runtime.lib=true -m 2g


docker run --rm --name postgres --net mynet \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_DB=$POSTGRES_DB \
  -p $POSTGRES_PORT:$POSTGRES_PORT -d postgres:10-alpine3.15

sleep 20

# migrate schemas to database
docker run --rm -i --net mynet \
  -v $( pwd )/atlas-schemas/flyway/scxa:/flyway/scxa \
  quay.io/ebigxa/atlas-schemas-base:1.0 \
  flyway migrate -url=$jdbc_url -user=$POSTGRES_USER \
  -password=$POSTGRES_PASSWORD -locations=filesystem:/flyway/scxa

# # Test load of experiments through CLI
# docker run --rm -it --net mynet -v $( pwd )/tests:/usr/local/tests:rw \
#   -v $( pwd )/fixtures:/fixtures \
#   -v $( pwd )/bin:/usr/local/bin \

#   -e ACCESSIONS=E-MTAB-2983 \
#   -e BIOENTITIES=/fixtures/ \
#   -e EXPERIMENT_FILES=/fixtures/experiment_files \
#   test/db-scxa-module load_experiment_web_cli.sh

docker build $docker_arch_line -t test/db-scxa-module .

docker run --net mynet -i $docker_arch_line \
  -v $( pwd )/tests:/usr/local/tests:rw \
  -v $( pwd )/atlas-schemas:/atlas-schemas:rw \
  -v $( pwd )/bin:/usr/local/bin:rw \
  -v $( pwd )/fixtures:/fixtures \
  -e SOLR_HOST=$SOLR_HOST -e ZK_HOST=$ZK_HOST -e ZK_PORT=$ZK_PORT \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e jdbc_username=$POSTGRES_USER \
  -e jdbc_password=$POSTGRES_PASSWORD \
  -e jdbc_url=$jdbc_url \
  -e dbConnection=$dbConnection \
  --entrypoint=/usr/local/tests/run_tests.sh test/db-scxa-module
