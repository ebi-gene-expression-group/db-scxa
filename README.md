# db-scxa-analytics

An AtlasProd module for loading scxa-analytics data to postgres 10.

## How to use

The main executable is script is `bin/load_db_scxa_analytics.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atas Experiment identifier.
- `ATLAS_SC_EXPERIMENTS`: The path to the directory where the `$EXP_ID/.expression_tpm.mtx[|_cols|_rows].gz` matrix market files reside.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a postgres 10 server where the expected `scxa-analytics` table exists.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```
load_db_scxa_analytics.sh
```

## How to test it

- Start an empty postgres 10 database through a container or any other mean:

```
docker run -e POSTGRES_PASSWORD=lasdjasd -e POSTGRES_USER=user -e POSTGRES_DB=scxa-test -p 5432:5432 -d postgres:10.3-alpine
```

- Build and export the adequate `dbConnection` env variable based on the postgres database generated.
- Execute `bash tests/run_tests.sh`


