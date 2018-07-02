@test "Check that psql is in the path" {
    run which psql
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
  run cmp --silent $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
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
  run cmp --silent $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
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
  run cmp --silent $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
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
