#!/usr/bin/env bash

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

echo "Start ZooKeeper"
docker run --rm --net mynet -d -p 2181:2181 -e ZOO_MY_ID=1 -e ZOO_SERVERS='server.1=0.0.0.0:2888:3888' -t zookeeper:3.8
echo "Start Solr"
docker run --rm --net mynet -d -p 8983:8983 -t solr:8-slim -DzkRun -Denable.runtime.lib=true -m 2g

echo "Start PostgreSQL"
docker run --rm --name postgres --net mynet \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_DB=$POSTGRES_DB \
  -p $POSTGRES_PORT:$POSTGRES_PORT -d postgres:11-alpine3.17

sleep 20

echo "Migrate schemas to database"
docker run --rm -i --net mynet $docker_arch_line \
  -v $( pwd )/atlas-schemas/flyway/scxa:/flyway/scxa \
  quay.io/ebigxa/atlas-schemas-base:1.0 \
  flyway migrate -url=$jdbc_url -user=$POSTGRES_USER \
  -password=$POSTGRES_PASSWORD -locations=filesystem:/flyway/scxa

docker build $docker_arch_line -t test/db-scxa-module .

echo "Run tests"
docker run --net mynet -i $docker_arch_line \
  -v $( pwd )/tests:/usr/local/tests:rw \
  -v $( pwd )/atlas-schemas:/atlas-schemas:rw \
  -v $( pwd )/bin:/usr/local/bin:rw \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e jdbc_username=$POSTGRES_USER \
  -e jdbc_password=$POSTGRES_PASSWORD \
  -e jdbc_url=$jdbc_url \
  -e dbConnection=$dbConnection \
  --entrypoint=/usr/local/tests/run_tests.sh test/db-scxa-module
