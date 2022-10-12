condensed_sdrf_file=E-PROT-15.condensed-sdrf.tsv
sdrf_file=E-PROT-15.sdrf.txt

checkDatabaseConnection() {
  pg_user=$(echo $1 | sed s+postgresql://++ | awk -F':' '{ print $1}')
  pg_host_port=$(echo $1 | awk -F':' '{ print $3}' \
           | awk -F'@' '{ print $2}' | awk -F'/' '{ print $1 }')
  pg_host=$(echo $pg_host_port  | awk -F':' '{print $1}')
  pg_port=$(echo $pg_host_port  | awk -F':' '{print $2}')
  if [ ! -z "$pg_port" ]; then
    pg_isready -U $pg_user -h $pg_host -p $pg_port || (echo "No db connection." && exit 1)
  else
    pg_isready -U $pg_user -h $pg_host || (echo "No db connection" && exit 1)
  fi
}

dbConnection=${dbConnection:-$1}

checkDatabaseConnection $dbConnection

while IFS=$'\t' read exp_acc sample sample_type col_name annot_value annot_url
do
        echo "Experiment is     : $exp_acc"
        echo "Sample is: $sample"
        echo "Sample Type is  : $sample_type"
        echo "Column name is  : $col_name"
        echo "Annotation value is  : $annot_value"
        echo "Annotation url is  : $annot_url"
        column_order=$(awk -v col="$annot" -v RS='\t' '$0 ~ col {print NR; exit}' $sdrf_file)
        echo "Column seq is : $column_order"

        echo "INSERT INTO exp_design_column (experiment_accession, column_name, sample_type, column_order) VALUES ('$exp_acc', '$col_name', '$sample_type', '$column_order');" | psql -v ON_ERROR_STOP=1 $dbConnection

        echo "INSERT INTO exp_design (sample, annot_value, annot_ont_uri) VALUES ('$sample', '$annot_value', '$annot_url');" | psql -v ON_ERROR_STOP=1 $dbConnection

done < $condensed_sdrf_file