#!/bin/bash
# source `which virtualenvwrapper.sh`
source globals.sh

# We can use parameters to skip certain tasks within this script
# Example:
# sh process.sh --skip=convert

# Pull out parameters and make them an array
# Called params_array
params=$1
prefix="--skip="
param=${params#$prefix}
IFS=', ' read -r -a params_array <<< ${param}


# Convert Excel to CSV
if [[ " ${params_array[*]} " != *" convert "* ]]; then
	mkdir raw/csv

  for file in "${FILES[@]}"
  do
    echo "- Converting for $file"
    in2csv 'raw/'$file'-yearly.xlsx' > 'raw/csv/'$file'-yearly.csv'
  done
fi

# Create DB
if [[ " ${params_array[*]} " != *" db "* ]]; then
  echo "- Remove old DB"
  rm $PROJECT_NAME.db

  for file in "${FILES[@]}"
  do
    CSV='raw/csv/'$file'-yearly.csv'

    # echo "- Create table SQL statement"
    # csvsql -i sqlite --tables "data"$file $CSV > "sql/data-create-"$file".sql"

    echo "- Create database"
    cat "sql/data-create-"$file".sql" | sqlite3 $PROJECT_NAME.db
  
    echo "- Create table called data_$file with the $file data in it"
    echo ".import $CSV data_"$file | sqlite3 -csv -header $PROJECT_NAME.db

    echo "Delete first row"
    echo "Delete from data_$file where rowid IN (Select rowid from data_$file limit 1);" > sql/delete-first-row.sql
    cat sql/delete-first-row.sql | sqlite3 -csv $PROJECT_NAME.db
  done
fi

# Query the DB
if [[ " ${params_array[*]} " != *" query "* ]]; then
  cat sql/join.sql | sqlite3 -header -csv $PROJECT_NAME.db > output/asatar-recapture-join.csv
fi