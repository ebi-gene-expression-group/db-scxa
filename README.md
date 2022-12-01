# Single Cell Expression Atlas database loading module (v1.0.0)

A [Single Cell Expression Atlas](https://www.ebi.ac.uk/gxa/sc) module for loading experiments to a Postgres 10 
database. Release v0.4.0 was used for [the October 2022 data release of Singe Cell Expression 
Atlas](https://www.ebi.ac.uk/gxa/sc/release-notes.html).

## Requirements
- Rscript with `optparse`, `tidyr` and `data.table` (in Ubuntu and Debian-based distributions install packages 
  `r-cran-optparse` , `r-cran-tidyr` and `r-cran-data.table`)
- PostgreSQL 11
- Node v12+

## Database schemas
Schema definitions and migrations of the database used by Single Cell Expression Atlas are managed by Flyway. They are
stored at https://github.com/ebi-gene-expression-group/atlas-schemas/tree/master/flyway/scxa. An example of how to
initialise a Docker container with Flyaway is available in[the development environment of Single Cell Expression
Atlas](https://github.com/ebi-gene-expression-group/atlas-web-single-cell/blob/develop/docker/docker-compose-postgres.yml).

## `scxa_analytics` table

### Load data
Run `bin/load_db_scxa_analytics.sh`. It requires the following environment variables:

| Variable name              | Description                                                                                                                                                                            |
|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `EXP_ID`                   | Experiment accession                                                                                                                                                                   |
| `EXPRESSION_TYPE`          | The expression type of the matrices (see next row); e.g. `aggregated_filtered_counts`; default value is `expression_tpm`                                                               |
| `EXPERIMENT_MATRICES_PATH` | Path where `$EXP_ID/$EXP_ID.$EXPRESSION_TYPE.mtx_cols_rows.gz` files are stored                                                                                                        |
| `dbConnection`             | A Postgres connection string in the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a Postgres 11 server where the expected `scxa_analytics` table exists |

It is recommended that `bin` is prepended to the `PATH`.

### Delete data
Set `dbConnection` and `EXP_ID`, then run `delete_db_scxa_analytics.sh`:
```bash
export EXP_ID=...
export dbConnection=...

delete_db_scxa_analytics.sh
```

## `scxa_coords` and `scxa_dimension_reduction` tables

### Load data
Run `bin/load_db_scxa_dimred.sh`. It requires the following environment variables:

| Variable name       | Description                                                                                                                                                                                                        |
|---------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `EXP_ID`            | Experiment accession                                                                                                                                                                                               |
| `DIMRED_TYPE`       | The dimension reduction type, such as "umap" or "tsne"; the value is arbitrary and supplied by the user                                                                                                            |
| `DIMRED_FILE_PATH`  | TSV file with the coordinates                                                                                                                                                                                      |
| `DIMRED_PARAM_JSON` | Optional array of parameters with the parameters used by the dimension reduction method (e.g. perplexity is typical for t-SNE, thus `[{"perplexity": 20}]`)                                                        |
| `dbConnection`      | A Postgres connection string in the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a Postgres 11 server where the expected `scxa_coords` and `scxa_dimension_reduction` tables exist |

It is recommended that `bin` is prepended to the `PATH`.

### Delete data
Set `dbConnection` and `EXP_ID`, then run `delete_db_scxa_dimred.sh`:
```bash
export EXP_ID=...
export dbConnection=...

delete_db_scxa_dimred.sh
```

## `scxa_cell_group` and `scxa_cell_group_membership` table

### Load data
Run `bin/load_db_scxa_cell_clusters.sh`. It requires the following environment variables:

| Variable name              | Description                                                                                                                                                                                                              |
|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `EXP_ID`                   | Experiment accession                                                                                                                                                                                                     |
| `EXPERIMENT_CLUSTERS_FILE` | Path to the file containing the clusters in wide format (as defined by iRAP SC)                                                                                                                                          |
| `CONDENSED_SDRF_TSV`       | Path to the condensed SDRF file of the experiment; it will be used to derive cell groups from the metadata, in addition to the clusters                                                                                  |
| `dbConnection`             | A Postgres connection string in the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a Postgres 11 server where the expected `scxa_cell_group` and `scxa_cell_group_membership` tables exist |

It is recommended that `bin` is prepended to the `PATH`.

### Delete data
Set `dbConnection` and `EXP_ID`, then run `delete_db_scxa_cell_clusters.sh`:

```bash
export EXP_ID=...
export dbConnection=...

delete_db_scxa_cell_clusters.sh
```

## `scxa_cell_group_marker_genes` and `scxa_cell_group_marker_gene_stats` tables
The script that loads data into `scxa_cell_group_marker_genes` and `scxa_cell_group_marker_gene_stats` reads the table 
`scxa_cell_group`. Ensure you’ve run `load_db_scxa_cell_clusters.sh` as detailed above to successfully carry out ths 
operation.

### Load data
Run `bin/load_db_scxa_marker_genes.sh`. It requires the following environment variables:

| Variable name            | Description                                                                                                                                                                                                                                  |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `EXP_ID`                 | Experiment accession                                                                                                                                                                                                                         |
| `EXPERIMENT_MGENES_PATH` | Path of marker genes files for transforming and loading                                                                                                                                                                                      |
| `CLUSTERS_FORMAT`        | `ISL` or `SCANPY`; default value is `ISL`                                                                                                                                                                                                    |
| `NUMBER_MGENES_FILES`    | Hints at whether there are marker genes files to load (zero or positive integer); this is optional                                                                                                                                           |
| `dbConnection`           | A Postgres connection string in the form `postgresql://{user}:{password}@{host:port}/{databaseName}` pointing to a Postgres 11 server where the expected `scxa_cell_group_marker_genes` and `scxa_cell_group_marker_gene_stats` tables exist |

It is recommended that `bin` is prepended to the `PATH`.

### Delete data for experiment
Set `dbConnection` and `EXP_ID`, then run `delete_db_scxa_marker_genes.sh`:

```bash
export EXP_ID=...
export dbConnection=...

delete_db_scxa_marker_genes.sh
```

## Post-loading a batch of experiments
Once a number of experiments have been loaded, tables should be re-indexed:

```bash
# if not set, set the dbConnection
export dbConnection=...
reindex_tables.sh
```

## Collections: consuming icons
Icons stored in the collections table can be consumed through the `lo_export` function within a `SELECT` statement, for instance:

```sql
SELECT lo_export(collections.icon, '/tmp/icon.png') FROM collections
    WHERE coll_id = 'PHANTOM';
```

## How to test it
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

## How to test it v2 (only db in container)
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

## Container
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
