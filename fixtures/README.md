# Fixture utilities
Set of scripts to create database test fixtures for the
[Single Cell Expression Atlas web app](https://github.com/ebi-gene-expression-group/atlas-web-single-cell).
They are stored in
[the corresponding `test/resources` directory](https://github.com/ebi-gene-expression-group/atlas-web-single-cell/tree/develop/app/src/test/resources/fixtures),
and they are used to initialise the testing Postgres database to a known state
before running any tests.

The scripts pick an appropriate set of cell groups, then a set of five marker genes per group and a random set of 
fifty cells, from which we get the expression and coordinate fixtures.

Besides the *k* value given as an argument, the scripts will pick a set of three cell group variables:
- two *k* values smaller than 30
- one cell type variable, that is, one that starts with “inferred cell type”

The reason for picking a “small” *k* is that we are going to later sample 50 cell IDs randomly. This way we ensure 
there will be some actual clustering, rather than many clusters with one cell, or even empty clusters. Raising the
number of cell IDs solves this issue but incurs in bigger fixtures.

It may happen that the selected *k* passed as an argument to the script is also selected randomly. In that case the
fixture will have a total of three cell group variables, otherwise it will contain four.

The script then selects all cell group values that match the argument *k* plus the randomly selected variables 
described above.  

A TSV file will be written for each table. As a last step the TSV files are transformed to SQL files with `sed`.

**Changes in the schema will require modification of these scripts.**

## Usage
```bash
[POSTGRES_HOST=...] [POSTGRES_PORT=...] POSTGRES_USER=... POSTGRES_DB=... \
generate-fixtures.sh 'EXPERIMENT_ACCESSION K_VALUE' '[EXPERIMENT_ACCESSION K_VALUE]...'
```

Please note the usage of single quotes to pass experiment accessions together with their preferred *k* value.

By default, the script will try to connect to `localhost:5432`; `POSTGRES_USER` and `POSTGRES_DB` are mandatory.

Example:
```bash
POSTGRES_USER=atlasprd3 \
POSTGRES_DB=gxpscxadev \
generate-fixtures.sh \
'E-CURD-4 17' \
'E-EHCA-2 24' \
'E-GEOD-71585 19' \
'E-GEOD-81547 24' \
'E-GEOD-99058 7' \
'E-MTAB-5061 25' \
'E-ENAD-53 14'
```

The *k* value passed together with the experiment accession should be either the preferred K field in the IDF file or
the `sel.K` value tagged as `TRUE` in the clusters TSV file.

The script can be called from any directory. All files will be written to $PWD.

# TODO
- Run in a container
