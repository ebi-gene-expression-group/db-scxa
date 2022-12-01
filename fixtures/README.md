# Fixture utilities
Set of scripts to create database test fixtures for the
[Single Cell Expression Atlas web app](https://github.com/ebi-gene-expression-group/atlas-web-single-cell).
They are stored in
[the corresponding `test/resources` directory](https://github.com/ebi-gene-expression-group/atlas-web-single-cell/tree/develop/app/src/tes/tresources/fixtures),
and they are used to initialise the testing Postgres database to a known state
before running any tests.

The scripts will pick a set of three cell group variables:
- two *k* values smaller than 30
- one cell type variable, that is, one that starts with “inferred cell type”

The reason for picking a “small” *k* is that we are going to later sample 50 cell IDs randomly. In this way we ensure
that there will be some actual clustering, rather than many clusters with one cell or even empty clusters. Raising the
number of cell IDs solves this issue but incurs in bigger fixtures.

From the cell group variables we select a full coverage of all the values that will become the cell group fixture.  

- gene IDs and 100 cell IDs from each
experiment, and then they will get all rows from the remaining tables that
reference those genes/cells. A TSV file will be written for each table and
as a last step the TSV files are transformed to SQL files with `sed`.

**Changes in the schema will require modification of these scripts.**

# Usage
```bash
[POSTGRES_HOST=...] [POSTGRES_PORT=...] POSTGRES_USER=... POSTGRES_DB=... generate-fixtures.sh 'EXPERIMENT_ACCESSION [EXPERIMENT_ACCESSION]...'
```

By default, the script will try to connect to `localhost:5432`; `POSTGRES_USER`
and `POSTGRES_DB` are mandatory.

Example:
```bash
POSTGRES_USER=atlasprd3 \
POSTGRES_DB=gxpscxadev \
generate-fixtures.sh \
'E-CURD-4 E-EHCA-2 E-GEOD-71585 E-GEOD-81547 E-GEOD-99058 E-MTAB-5061'
```

The script can be called from any directory. All files will be written to $PWD.

# TODO
- Run from a container
