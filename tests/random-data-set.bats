@test "Check that psql is in the path" {
    run which psql
    [ "$status" -eq 0 ]
}

@test "Check that node is in the path" {
    run which node
    [ "$status" -eq 0 ]
}

@test "Check that Rscript is in the path" {
    run which Rscript
    [ "$status" -eq 0 ]
}

@test "Analytics: Check that load_db_scxa_analytics.sh is in the path" {
  run which load_db_scxa_analytics.sh
  [ "$status" -eq 0 ]
}

@test "Loading: Check that load_experiment_web_cli.sh is in the path" {
  run which load_experiment_web_cli.sh
  [ "$status" -eq 0 ]
}

@test "Loading: E-CURD-4 through CLI" {
  export ACCESSIONS=E-CURD-4

  run load_experiment_web_cli.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Loading: Check that E-CURD-4 was loaded" {
  export EXP_ID=E-CURD-4
  export FIELDS=species
  species=$(get_experiment_info.sh)
  run [ "$species" == "Arabidopsis thaliana" ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Loading: Update experiment design of E-CURD-4 after deleting file" {
  export ACCESSIONS=E-CURD-4

  expDesignFile=$EXPERIMENT_DESIGN_FILES/ExpDesign-${ACCESSIONS}.tsv
  rm -rf $expDesignFile

  run update_experiment_web_cli.sh

  echo "output = ${output}"
  [ "$status" -eq 0 ]
  [ -f $expDesignFile ]
}

@test "Loading: E-MTAB-2983 through CLI" {
  export ACCESSIONS=E-MTAB-2983

  run load_experiment_web_cli.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Loading: Check that E-MTAB-2983 was loaded" {
  export EXP_ID=E-MTAB-2983
  export FIELDS=species
  species=$(get_experiment_info.sh)
  run [ "$species" == "Homo sapiens" ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Loading: Update experiment design of E-MTAB-2983 after deleting file" {
  export ACCESSIONS=E-MTAB-2983

  expDesignFile=$EXPERIMENT_DESIGN_FILES/ExpDesign-${ACCESSIONS}.tsv
  rm -rf $expDesignFile

  run update_experiment_web_cli.sh

  echo "output = ${output}"
  [ "$status" -eq 0 ]
  [ -f $expDesignFile ]
}

@test "Analytics: Delete experiment data-set-1" {
  export EXP_ID=TEST-EXP1
  run delete_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_analytics WHERE experiment_accession = '"$EXP_ID"'" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Run loading process" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Expression levels of 0 TPMs (i.e. missing entries in the matrix) are skipped" {
  export EXP_ID=TEST-EXP1
  count=$(echo "SELECT COUNT(*) FROM scxa_analytics WHERE expression_level = 0" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Query and compare loaded files" {
  export EXP_ID=TEST-EXP1
  psql -v ON_ERROR_STOP=1 -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp -s $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Delete experiment data-set-2" {
  export EXP_ID=TEST-EXP2
  run delete_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_analytics WHERE experiment_accession = '"$EXP_ID"'" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Run loading process second time" {
  export EXP_ID=TEST-EXP2
  run load_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Query and compare loaded files second time" {
  export EXP_ID=TEST-EXP2
  psql -v ON_ERROR_STOP=1 -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp -s $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Recreate data set 1 for reloading" {
  export EXP_ID=TEST-EXP1
  rm $EXP_ID.query_test.sql
  rm $EXP_ID.query_expected.txt
  run create-test-matrix-market-files.R $EXP_ID
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Check that wideSCCluster2longSCCluster.R is in the path" {
  run which wideSCCluster2longSCCluster.R
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Check that column names are not mangled by R" {
  export EXP_ID=TEST-EXP1
  wideSCCluster2longSCCluster.R -c $EXP_ID.clusters_weird_names.txt -e $EXP_ID -o clustersToLoad.test.$EXP_ID.csv
  run diff <(tail -n +2 clustersToLoad.test.$EXP_ID.csv | awk -F "\"*,\"*" '{print $2}' | uniq | sort) <(sort $EXP_ID.weird_names.txt) > /dev/null
  [ "$status" -eq 0 ]
}

@test "Analytics: Delete experiment data-set-1" {
  export EXP_ID=TEST-EXP1
  run delete_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_analytics WHERE experiment_accession = '"$EXP_ID"'" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Reload dataset 1" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Query and compare reloaded data-set 1" {
  export EXP_ID=TEST-EXP1
  rm $EXP_ID.query_results.txt
  psql -v ON_ERROR_STOP=1 -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp -s $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Delete experiment data-set-1" {
  export EXP_ID=TEST-EXP1
  run delete_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_analytics WHERE experiment_accession = '"$EXP_ID"'" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Reload data-set 1 with pg9 setup" {
  # This should be backwards compatible with pg9
  export EXP_ID=TEST-EXP1
  run load_db_scxa_analytics_pg9.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Query and compare reloaded data-set 1 after pg9 type of loading" {
  export EXP_ID=TEST-EXP1
  rm $EXP_ID.query_results.txt
  psql -v ON_ERROR_STOP=1 -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp -s $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Collections: Add experiments" {
  count=$(echo "INSERT INTO experiment (accession, type, species, access_key) VALUES ('TEST-EXP1', 'SINGLE_CELL_RNASEQ_MRNA_BASELINE', 'Homo sapiens', '5770d1e1-677d-4486-96e3-1e88cea61d26'), ('TEST-EXP2', 'SINGLE_CELL_RNASEQ_MRNA_BASELINE', 'Homo sapiens', '5770d1e1-677d-4486-96e3-1e88cea61d26'), ('TEST-EXP3', 'SINGLE_CELL_RNASEQ_MRNA_BASELINE', 'Homo sapiens', '5770d1e1-677d-4486-96e3-1e88cea61d26'), ('E-TEST-1', 'SINGLE_CELL_RNASEQ_MRNA_BASELINE', 'Homo sapiens', '5770d1e1-677d-4486-96e3-1e88cea61d26'), ('E-TEST-2', 'SINGLE_CELL_RNASEQ_MRNA_BASELINE', 'Homo sapiens', '6472724a-80f6-43af-b046-4e4acb89908e');" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  status=0
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Check that load_db_scxa_clusters.sh is in the path" {
  run which load_db_scxa_cell_clusters.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Load data" {
  export EXP_ID=TEST-EXP1
  export CONDENSED_SDRF_TSV=$testsDir/marker-genes/TEST-EXP1.condensed-sdrf.tsv
  run load_db_scxa_cell_clusters.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Check that load_db_scxa_marker_genes.sh is in the path" {
  run which load_db_scxa_marker_genes.sh
  [ "$status" -eq 0 ]
}

@test "Marker genes: Load data" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_marker_genes.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Check number of loaded rows" {
  # Get third line with count of total entries in the database after our load
  count=$(echo "SELECT COUNT(*) FROM scxa_cell_group_marker_genes, scxa_cell_group where scxa_cell_group_marker_genes.cell_group_id = scxa_cell_group.id and experiment_accession='TEST-EXP1'" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 330 ]
  echo "count = $count"
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Check that k=12 was not loaded" {
  # Get third line with count of total entries in the database after our load
  count=$(echo "SELECT COUNT(*) FROM scxa_cell_group_marker_genes, scxa_cell_group where scxa_cell_group_marker_genes.cell_group_id = scxa_cell_group.id and variable='12'" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  echo "Count: "$count
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Add second dataset for deletion tests and do cell clusters" {
  cp -r $testsDir/marker-genes $SCRATCH_DIR/marker-genes

  export EXP_ID=TEST-EXP2
  export EXPERIMENT_MGENES_PATH=$SCRATCH_DIR/marker-genes
  export EXPERIMENT_CLUSTERS_FILE=$SCRATCH_DIR/marker-genes/TEST-EXP2.clusters.tsv
  run load_db_scxa_cell_clusters.sh

  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Marker genes for second dataset for deletion tests" {
  export EXP_ID=TEST-EXP2
  export EXPERIMENT_MGENES_PATH=$SCRATCH_DIR/marker-genes
  export EXPERIMENT_CLUSTERS_FILE=$SCRATCH_DIR/marker-genes/TEST-EXP2.clusters.tsv

  run load_db_scxa_marker_genes.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Delete rows for experiment" {
  countBefore=$(echo "SELECT COUNT(*) FROM scxa_cell_group_marker_genes, scxa_cell_group where scxa_cell_group_marker_genes.cell_group_id = scxa_cell_group.id" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  export EXP_ID=TEST-EXP2
  run delete_db_scxa_marker_genes.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  countAfter=$(echo "SELECT COUNT(*) FROM scxa_cell_group_marker_genes, scxa_cell_group where scxa_cell_group_marker_genes.cell_group_id = scxa_cell_group.id" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  echo "Count before: $countBefore , count after: $countAfter"
  [ $(( countBefore - countAfter )) == 274 ]
}

@test "Marker genes: Load Scanpy data" {
  export EXP_ID=TEST-EXP3
  export CLUSTERS_FORMAT="SCANPY"
  run load_db_scxa_cell_clusters.sh
  run load_db_scxa_marker_genes.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Don't load Scanpy data with hint of number of marker genes files" {
  export EXP_ID=TEST-EXP3
  export NUMBER_MGENES_FILES=0
  export CLUSTERS_FORMAT="SCANPY"
  run load_db_scxa_cell_clusters.sh
  run load_db_scxa_marker_genes.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Load Scanpy data with hint of number of marker genes files" {
  export EXP_ID=TEST-EXP3
  export NUMBER_MGENES_FILES=3
  export CLUSTERS_FORMAT="SCANPY"
  run load_db_scxa_cell_clusters.sh
  run load_db_scxa_marker_genes.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Coords: Check that load_db_scxa_dimred.sh is in the path" {
  run which load_db_scxa_dimred.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Coords: Load tSNE data" {
  export EXP_ID=TEST-EXP1
  run $testsDir/test_dimred_load.sh

  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Dimred parameters: check that JSON queries run and return expected values" {
    target_perps="1 5 10 15 20  "
    perps=$(echo "select distinct parameterisation->0->'perplexity' as perplexity from scxa_coords order by perplexity" | psql -At $dbConnection | tr '\n' ' ')
    run [ "$perps" = "$target_perps" ]
}

@test "Coords: Check number of loaded rows" {
  export EXP_ID=TEST-EXP1
  # Get third line with count of total entries in the database after our load
  count=$(echo "SELECT COUNT(*) FROM scxa_dimension_reduction d, scxa_coords c WHERE d.id = c.dimension_reduction_id and d.experiment_accession = '$EXP_ID'" | psql -qtAX -v ON_ERROR_STOP=1 $dbConnection)
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 300 ]
  echo "output = ${output}"
  echo "count = ${count}"
  [ "$status" -eq 0 ]
}

@test "Coords: Delete experiment" {
  export EXP_ID=TEST-EXP1
  run delete_db_scxa_dimred.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_dimension_reduction d, scxa_coords c WHERE d.id = c.dimension_reduction_id and d.experiment_accession = '$EXP_ID'" | psql -qtAX -v ON_ERROR_STOP=1 $dbConnection)
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Check number of loaded rows" {
  # Get third line with count of total entries in the database after our load
  count=$(echo "SELECT COUNT(*) FROM scxa_cell_group_membership" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 13930 ]
  echo "output = ${output} count = $count"
  [ "$status" -eq 0 ]
}

@test "Clusters: Delete experiment" {
  export EXP_ID=TEST-EXP1
  run delete_db_scxa_cell_clusters.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_cell_group_membership, scxa_cell_group WHERE scxa_cell_group_membership.cell_group_id=scxa_cell_group.id AND scxa_cell_group.experiment_accession = '"$EXP_ID"'" | psql -v ON_ERROR_STOP=1 $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Exp_Design: Load exp_design data E-CURD-4" {
  export CONDENSED_SDRF_FILE=${EXPERIMENT_FILES}/magetab/E-CURD-4/E-CURD-4.condensed-sdrf.tsv
  export SDRF_FILE=${EXPERIMENT_FILES}/magetab/E-CURD-4/E-CURD-4.sdrf.txt
  run load_exp_design.sh

  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Exp_Design: Load exp_design data E-MTAB-2983" {
  export CONDENSED_SDRF_FILE=${EXPERIMENT_FILES}/magetab/E-MTAB-2983/E-MTAB-2983.condensed-sdrf.tsv
  export SDRF_FILE=${EXPERIMENT_FILES}/magetab/E-MTAB-2983/E-MTAB-2983.sdrf.txt
  run load_exp_design.sh

  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Collections: Create X" {
  export COLL_ID=MYCOLLX
  export COLL_NAME="My collection X"
  run create_collection.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Collections: Put experiments in collection" {
  export COLL_ID=MYCOLLX
  export EXP_IDS=E-TEST-1,E-TEST-2
  run add_exps_to_collection.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Collections: Delete experiments from collection" {
  export COLL_ID=MYCOLLX
  export EXP_IDS=E-TEST-1
  run delete_exp_from_collection.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Collections: Create Y with icon" {
  export COLL_ID=MYCOLLY
  export COLL_NAME="My collection Y"
  export COLL_ICON_PATH=$testsDir/icon.png
  run create_collection.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Collections: Delete X" {
  export COLL_ID=MYCOLLX
  run delete_collection.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Collections: Modify collection Y" {
  export COLL_ID=MYCOLLY
  export COLL_NAME="Better Y name"
  export COLL_ICON_PATH=$testsDir/icon.png
  run modify_collection.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Post-flight: reindex and cluster" {
  run reindex_tables.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}
