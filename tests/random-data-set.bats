@test "Check that psql is in the path" {
    run which psql
    [ "$status" -eq 0 ]
}

@test "Check that load_db_scxa_analytics.sh is in the path" {
  run which load_db_scxa_analytics.sh
  [ "$status" -eq 0 ]
}

@test "Run loading process" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Query and compare loaded files" {
  export EXP_ID=TEST-EXP1
  psql -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp --silent $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Run loading process second time" {
  export EXP_ID=TEST-EXP2
  run load_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Query and compare loaded files second time" {
  export EXP_ID=TEST-EXP2
  psql -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp --silent $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Recreate data set 1 for reloading" {
  export EXP_ID=TEST-EXP1
  rm $EXP_ID.query_test.sql
  rm $EXP_ID.query_expected.txt
  run create-test-matrix-market-files.R $EXP_ID
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Reload dataset 1" {
  export EXP_ID=TEST-EXP1
  run load_db_scxa_analytics.sh
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}

@test "Query and compare reloaded data-set 1" {
  export EXP_ID=TEST-EXP1
  rm $EXP_ID.query_results.txt
  psql -A $dbConnection < $EXP_ID.query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > $EXP_ID.query_results.txt
  run cmp --silent $EXP_ID.query_expected.txt $EXP_ID.query_results.txt
  echo "output = ${output}"
  [ "$status" -eq 0 ]
}
