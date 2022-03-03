#!/usr/bin/env bash
# Above ^^ will test that bash is installed

docker_arch_line=""
if [ $( arch ) == "arm64" ]; then
    docker_arch_line="--platform linux/amd64"
    echo "Changing arch $docker_arch_line"
fi

dbConnection='postgresql://scxa:postgresPass@postgres/scxa-test'
docker stop postgres && docker rm postgres
docker network rm mynet
docker network create mynet
docker run --name postgres --net mynet -e POSTGRES_PASSWORD=postgresPass -e POSTGRES_USER=scxa -e POSTGRES_DB=scxa-test -p 5432:5432 -d postgres:10-alpine3.15
docker build $docker_arch_line -t test/db-scxa-module .
docker run $docker_arch_line --net mynet -i -v $( pwd )/tests:/usr/local/tests:rw -e dbConnection=$dbConnection -v $( pwd )/atlas-schemas:/tmp/atlas-schemas:rw --entrypoint=/usr/local/tests/run_tests.sh test/db-scxa-module