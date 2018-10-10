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


@test "Analytics: Run loading process" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Query and compare loaded files" {
  export EXP_ID=TEST-EXP1
  psql -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp -s $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
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
  psql -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
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

@test "Analytics: Reload dataset 1" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Query and compare reloaded data-set 1" {
  export EXP_ID=TEST-EXP1
  rm $EXP_ID.query_results.txt
  psql -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp -s $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Analytics: Delete experiment" {
  export EXP_ID=TEST-EXP1
  run delete_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_analytics WHERE experiment_accession = '"$EXP_ID"'" | psql $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Check that load_db_scxa_marker_genes.sh is in the path" {
  run which load_db_scxa_marker_genes.sh
  [ "$status" -eq 0 ]
}

@test "Marker genes: Create table" {
  run psql $dbConnection < $testsDir/marker-genes/01-optional-create-table.sql
  echo "output = ${output}"
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
  count=$(echo "SELECT COUNT(*) FROM scxa_marker_genes" | psql $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 274 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Check that k=12 was not loaded" {
  # Get third line with count of total entries in the database after our load
  count=$(echo "SELECT COUNT(*) FROM scxa_marker_genes WHERE k = 12" | psql $dbConnection | awk 'NR==3')
  echo "Count: "$count
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Add second dataset for deletion tests" {
  cp $testsDir/marker-genes/TEST-EXP1.clusters.tsv $testsDir/marker-genes/TEST-EXP2.clusters.tsv
  cp $testsDir/marker-genes/TEST-EXP1.marker_genes_9.tsv $testsDir/marker-genes/TEST-EXP2.marker_genes_9.tsv
  cp $testsDir/marker-genes/TEST-EXP1.marker_genes_10.tsv $testsDir/marker-genes/TEST-EXP2.marker_genes_10.tsv
  cp $testsDir/marker-genes/TEST-EXP1.marker_genes_11.tsv $testsDir/marker-genes/TEST-EXP2.marker_genes_11.tsv
  export EXP_ID=TEST-EXP2
  run load_db_scxa_marker_genes.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Marker genes: Delete rows for experiment" {
  countBefore=$(echo "SELECT COUNT(*) FROM scxa_marker_genes" | psql $dbConnection | awk 'NR==3')
  export EXP_ID=TEST-EXP2
  run delete_db_scxa_marker_genes.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  countAfter=$(echo "SELECT COUNT(*) FROM scxa_marker_genes" | psql $dbConnection | awk 'NR==3')
  [ $(( countBefore - countAfter )) == 274 ]
}


@test "TSNE: Check that load_db_scxa_tsne.sh is in the path" {
  run which load_db_scxa_tsne.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "TSNE: Create table" {
  run psql $dbConnection < $testsDir/tsne/01-optional-create-table.sql
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "TSNE: Load data" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_tsne.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "TSNE: Check number of loaded rows" {
  # Get third line with count of total entries in the database after our load
  count=$(echo "SELECT COUNT(*) FROM scxa_tsne" | psql $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 250 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "TSNE: Delete experiment" {
  export EXP_ID=TEST-EXP1
  run delete_db_scxa_tsne.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_tsne WHERE experiment_accession = '"$EXP_ID"'" | psql $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Check that load_db_scxa_clusters.sh is in the path" {
  run which load_db_scxa_cell_clusters.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Create table" {
  run psql $dbConnection < $testsDir/cell_clusters/01-optional-create-table.sql
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Load data" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_cell_clusters.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Check number of loaded rows" {
  # Get third line with count of total entries in the database after our load
  count=$(echo "SELECT COUNT(*) FROM scxa_cell_clusters" | psql $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 4179 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Clusters: Delete experiment" {
  export EXP_ID=TEST-EXP1
  run delete_db_scxa_cell_clusters.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
  count=$(echo "SELECT COUNT(*) FROM scxa_cell_clusters WHERE experiment_accession = '"$EXP_ID"'" | psql $dbConnection | awk 'NR==3')
  # TODO improve, highly dependent on test files we have, but in a hurry for now.
  run [ $count -eq 0 ]
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}
