# Module for Single Cell Expression Atlas database loading (v0.1.0)  

An AtlasProd module for loading scxa-* tables data to postgres 10.

# `scxa_analytics` Table

## Create schema

Currently, schema for postgres scxa-* tables is stored at https://github.com/ebi-gene-expression-group/atlas/tree/dev/atlas-misc/scripts/db_updates. In time, the schema will be either consumed
from this or a dedicated repo.

## Load data

The main executable is script is `bin/load_db_scxa_analytics.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas Experiment identifier.
- `ATLAS_SC_EXPERIMENTS`: The path to the directory where the `$EXP_ID/.expression_tpm.mtx[|_cols|_rows].gz` matrix market files reside.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a postgres 10 server where the expected `scxa_analytics` table exists.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```
load_db_scxa_analytics.sh
```

# `scxa_marker_genes` Table

## Create schema

Same as in `scxa_analytics` currently.

## Load data

The main executable is `bin/load_db_scxa_marker_genes.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas Experiment identifier.
- `EXPERIMENT_MGENES_PATH`: path of marker genes files for transforming and loading.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a postgres 10 server where the expected `scxa_marker_genes` table exists.

# How to test it

- Start an empty postgres 10 database through a container or any other mean:

```
docker run -e POSTGRES_PASSWORD=lasdjasd -e POSTGRES_USER=user -e POSTGRES_DB=scxa-test -p 5432:5432 -d postgres:10.3-alpine
```

- Build and export the adequate `dbConnection` env variable based on the postgres database generated.
- Execute `bash tests/run_tests.sh`

Tests are also automatically executed on Travis.
