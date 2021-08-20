# Module for Single Cell Expression Atlas database loading (v0.2.3)

An AtlasProd module for loading scxa-* tables data to postgres >=10. Release v0.2.3 was used for the May 2020 Data release of Singe Cell Expression Atlas.

For direct usage, this module requires Rscript (with optparse, tidyr and data.table, in Ubuntu and Debian-based distributions install packages `r-cran-optparse` , `r-cran-tidyr` and `r-cran-data.table`), psql and node.

# `scxa_analytics` Table

## Create schema

Currently, schema for postgres scxa-* tables is stored at https://github.com/ebi-gene-expression-group/atlas-schemas/tree/master/flyway/scxa.

## Load data

The main executable is script is `bin/load_db_scxa_analytics.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas Experiment identifier.
- `EXPERIMENT_MATRICES_PATH`: The path to the directory where the `$EXP_ID/.expression_tpm.mtx[|_cols|_rows].gz` matrix market files reside.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a Postgres 10 server where the expected `scxa_analytics` table exists.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```bash
load_db_scxa_analytics.sh
```

## Delete data for experiment

Set the desired database connection in `dbConnection` and experiment accession in `EXP_ID` and use `delete_db_scxa_analytics.sh`:

```bash
export EXP_ID=TEST-EXP1
export dbConnection=...

delete_db_scxa_analytics.sh
```

# `scxa_coords` Table

## Create schema

Same as in `scxa_analytics` currently.

## Load data

The main executable is `bin/load_db_scxa_dimred.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas experiment identifier.
- `EXPERIMENT_DIMRED_PATH`: path to directory containing tsne and umap files for loading. Files are expected to have the structure <prefix><perplexity_number><suffix> (tsne) or <prefix><neighbors_number><suffix> (umap) with the default suffix and prefix defined in the script. These can be configured from outside through env vars.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a Postgres 10 server where the expected `scxa_coords` table exist.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```bash
load_db_scxa_dimred.sh
```

## Delete data for experiment

Set the desired database connection in `dbConnection` and experiment accession in `EXP_ID` and use `delete_db_scxa_dimred.sh`:

```bash
export EXP_ID=TEST-EXP1
export dbConnection=...

delete_db_scxa_dimred.sh
```

# `scxa_cell_clusters` Table

## Create schema

Same as in `scxa_analytics` currently.

## Load data

The main executable is `bin/load_db_scxa_cell_clusters.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas Experiment identifier.
- `EXPERIMENT_CLUSTERS_FILE`: path to the file containing the clusters in wide format (as defined by iRAP SC).
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a Postgres 10 server where the expected `scxa_cell_group`, `scxa_cell_group_membership`, `scxa_cell_clusters` and `scxa_cell_group_marker_gene_stats` tables exist.
- `CONDENSED_SDRF_TSV`: path to the condensed SDRF file of the experiment. This will be used to derive cell groups from the metadata, in addition to the clusters.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```bash
load_db_scxa_cell_clusters.sh
```

## Delete data for experiment

Set the desired database connection in `dbConnection` and experiment accession in `EXP_ID` and use `delete_db_scxa_cell_clusters.sh`:

```bash
export EXP_ID=TEST-EXP1
export dbConnection=...

delete_db_scxa_cell_clusters.sh
```

# `scxa_marker_genes` Table

The script that loads data into `scxa_marker_genes` reads the table `scxa_cell_group`. Ensure you’ve run `load_db_scxa_cell_clusters.sh` as detailed above to successfully carry out ths operation.

## Create schema

Same as in `scxa_analytics` currently.

## Load data

The main executable is `bin/load_db_scxa_marker_genes.sh`, which requires the following environment variables to be set:
- `EXP_ID`: Atlas experiment identifier.
- `EXPERIMENT_MGENES_PATH`: path of marker genes files for transforming and loading.
- `dbConnection`: A postgres db connection string of the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a Postgres 10 server where the expected `scxa_marker_genes`, `scxa_cell_group_marker_gene_stats`, `scxa_cell_group_marker_genes` and `scxa_cell_group` tables exist.
Optionally, you can set `CLUSTERS_FORMAT` and `NUMBER_MGENES_FILES`:

The `CLUSTERS_FORMAT` variable to set the format to one of the following:
- `ISL` (default)
- `SCANPY`

The `NUMBER_MGENES_FILES` variable (zero or positive integer) hints whether there are marker genes files to be loaded. If the variable is set to zero by an external process, then the script won't fail if no marker genes files are found. Currently the script only considers whether the variable is 0 (no marker genes files) or greater (there are that number of marker gene files). This is mostly to be able to fail if we expected to have marker gene files but for some reasons these were not created due to an unknown issue.

Additionally, it is recommended that `bin` directory on the root is prepended to the `PATH`. Then execute:

```bash
load_db_scxa_marker_genes.sh
```

## Delete data for experiment

Set the desired database connection in `dbConnection` and experiment accession in `EXP_ID` and use `delete_db_scxa_marker_genes.sh`:

```bash
export EXP_ID=TEST-EXP1
export dbConnection=...

delete_db_scxa_marker_genes.sh
```


# Post-loading a batch of experiments

Once a number of experiments have been loaded, tables should be re-indexed and materialised views **NEED** to be refreshed:

```
# if not set, set the dbConnection
export dbConnection=...
reindex_tables.sh
refresh_materialised_views.sh
```

# Collections: consuming icons

Icons stored in the collections table can be consumed through the `lo_export` function within a SELECT statement, for instance:

```sql
SELECT lo_export(collections.icon, '/tmp/icon.png') FROM collections
    WHERE coll_id = 'PHANTOM';
```

# How to test it

This is the preferred and most reproducible way of testing using containers. It requires docker to be installed:

```bash
bash run_tests_with_containers.sh
```

First run will be expensive due to build, subsequent runs will use your cache.
Every run will leave the postgresql container running with the structure and
some dummy data loaded in the database. You can connect to that database locally
with the following credentials:

```
dbConnection='postgresql://scxa:postgresPass@localhost:5432/scxa-test'
```

On every run of the `run_tests_with_containers.sh` the container database will be deleted and re-created.

# How to test it v2 (only db in container)

- Start an empty postgres 10 database through a container or any other mean:

```bash
docker run -e POSTGRES_PASSWORD=lasdjasd -e POSTGRES_USER=user -e POSTGRES_DB=scxa-test -p 5432:5432 -d postgres:10.3-alpine
```

- Build and export the adequate `dbConnection` env variable based on the postgres database generated.

```bash
export dbConnection=postgresql://user:lasdjasd@localhost:5432/scxa-test
```
- Execute `bash tests/run_tests.sh`

Tests are also automatically executed on Travis.

# Container

The container is available for use at quay.io/ebigxa/db-scxa-module at latest or any of the tags after 0.2.0, so it could be used like this for example:

```bash
docker run -v /local_data:/data \
       -e dbConfig=<your-database-connection-string-for-postgres> \
       -e EXP_ID=<the-accession-of-experiment> \
       -e EXPERIMENT_CLUSTERS_FILE=<path-inside-container-for-clusters-file> \
       --entrypoint load_db_scxa_clusters.sh \
       quay.io/ebigxa/db-scxa-module:latest
```

Please note that `EXPERIMENT_CLUSTERS_FILE` needs to make sense with how you mount
data inside the container. You can change entrypoint and env variables given to use the other scripts mentioned above.
