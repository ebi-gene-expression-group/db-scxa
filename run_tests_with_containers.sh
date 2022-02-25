#!/usr/bin/env bash
# Above ^^ will test that bash is installed

dbConnection='postgresql://scxa:postgresPass@postgres/scxa-test'
docker stop postgres && docker rm postgres
docker network rm mynet
docker network create mynet
docker run --name postgres --net mynet -e POSTGRES_PASSWORD=postgresPass -e POSTGRES_USER=scxa -e POSTGRES_DB=scxa-test -p 5432:5432 -d postgres:10.3-alpine
docker build -t test/db-scxa-module .
docker run --net mynet -i -v $( pwd )/tests:/usr/local/tests -e dbConnection=$dbConnection -v $( pwd )/atlas-schemas:/tmp/atlas-schemas --entrypoint=/usr/local/tests/run_tests.sh test/db-scxa-module
