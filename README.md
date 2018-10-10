# Module for Single Cell Expression Atlas database loading (v0.2.1)  

An AtlasProd module for loading scxa-* tables data to postgres 10. Release v0.2.1
was used for the September 2018 Data release of Singe Cell Expression Atlas.

For direct usage, this module requires Rscript (with tidyr), psql and node.

# `scxa_analytics` Table

## Create schema

Currently, schema for postgres scxa-* tables is stored at https://github.com/ebi-gene-expression-group/atlas/tree/dev/atlas-misc/scripts/db_updates. In time, the schema will be either consumed
from this or a dedicated repo.

## Load data

The main executable is script is `bin/load_db_scxa_analytics.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas Experiment identifier.
- `EXPERIMENT_MATRICES_PATH`: The path to the directory where the `$EXP_ID/.expression_tpm.mtx[|_cols|_rows].gz` matrix market files reside.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a postgres 10 server where the expected `scxa_analytics` table exists.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```
load_db_scxa_analytics.sh
```

## Delete data for experiment

Set the desired database connection in `dbConnection` and experiment accession in `EXP_ID` and use `delete_db_scxa_analytics.sh`:

```
export EXP_ID=TEST-EXP1
export dbConnection=...

delete_db_scxa_analytics.sh
```

# `scxa_marker_genes` Table

## Create schema

Same as in `scxa_analytics` currently.

## Load data

The main executable is `bin/load_db_scxa_marker_genes.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas Experiment identifier.
- `EXPERIMENT_MGENES_PATH`: path of marker genes files for transforming and loading.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a postgres 10 server where the expected `scxa_marker_genes` table exists.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```
load_db_scxa_marker_genes.sh
```

## Delete data for experiment

Set the desired database connection in `dbConnection` and experiment accession in `EXP_ID` and use `delete_db_scxa_marker_genes.sh`:

```
export EXP_ID=TEST-EXP1
export dbConnection=...

delete_db_scxa_marker_genes.sh
```

# `scxa_tsne` Table

## Create schema

Same as in `scxa_analytics` currently.

## Load data

The main executable is `bin/load_db_scxa_tsne.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas Experiment identifier.
- `EXPERIMENT_TSNE_PATH`: path to directory containing tsne files for loading. Files are expected to have the structure <prefix><persplexity_number><suffix> structure, with the default suffix and prefix defined in the script. These can be configured from outside through env vars.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a postgres 10 server where the expected `scxa_tsne` table exists.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```
load_db_scxa_tsne.sh
```

## Delete data for experiment

Set the desired database connection in `dbConnection` and experiment accession in `EXP_ID` and use `delete_db_scxa_tsne.sh`:

```
export EXP_ID=TEST-EXP1
export dbConnection=...

delete_db_scxa_tsne.sh
```

# `scxa_cell_clusters` Table

## Create schema

Same as in `scxa_analytics` currently.

## Load data

The main executable is `bin/load_db_scxa_cell_clusters.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas Experiment identifier.
- `EXPERIMENT_CLUSTERS_FILE`: path to the file containing the clusters in wide format (as defined by iRAP SC).
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a postgres 10 server where the expected `scxa_tsne` table exists.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```
load_db_scxa_cell_clusters.sh
```

## Delete data for experiment

Set the desired database connection in `dbConnection` and experiment accession in `EXP_ID` and use `delete_db_scxa_cell_clusters.sh`:

```
export EXP_ID=TEST-EXP1
export dbConnection=...

delete_db_scxa_cell_clusters.sh
```

# How to test it

- Start an empty postgres 10 database through a container or any other mean:

```
docker run -e POSTGRES_PASSWORD=lasdjasd -e POSTGRES_USER=user -e POSTGRES_DB=scxa-test -p 5432:5432 -d postgres:10.3-alpine
```

- Build and export the adequate `dbConnection` env variable based on the postgres database generated.
- Execute `bash tests/run_tests.sh`

Tests are also automatically executed on Travis.

# Container

The container is available for use at quay.io/ebigxa/db-scxa-module at latest or any of the tags after 0.2.0, so it could be used like this for example:

```
docker run -v /local_data:/data \
       -e dbConfig=<your-database-connection-string-for-postgres> \
       -e EXP_ID=<the-accession-of-experiment> \
       -e EXPERIMENT_CLUSTERS_FILE=<path-inside-container-for-clusters-file> \
       --entrypoint load_db_scxa_clusters.sh \
       quay.io/ebigxa/db-scxa-module:latest
```

Please note that `EXPERIMENT_CLUSTERS_FILE` needs to make sense with how you mount
data inside the container. You can change entrypoint and env variables given to use the other scripts mentioned above.
