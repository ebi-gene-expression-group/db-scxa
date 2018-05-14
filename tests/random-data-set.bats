@test "Check that psql is in the path" {
    run which psql
    [ "$status" -eq 0 ]
}

@test "Run loading process" {
  run load_db_scxa_analytics.sh
  [ "$status" -eq 0 ]
}

@test "Query and compare loaded files" {
  psql -A $dbConnection < query_test.sql | awk -F'|' '{ print $1,$2,$3,$4 }' | sed \$d > query_results.txt
  run cmp --silent query_expected.txt query_results.txt
  [ "$status" -eq 0 ]
}
