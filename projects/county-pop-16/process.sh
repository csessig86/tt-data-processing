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

# Create tables for each CSV in database
if [[ " ${params_array[*]} " != *" db "* ]]; then
	for file in "${FILES[@]}"
  do
    CSV_RAW='raw/PEP_2016_'$file'_with_ann.csv'

    echo "- Create table SQL statement"
    csvsql -i sqlite --tables "data"$file $CSV_RAW > "sql/data-create-"$file".sql"

    echo "- Create database"
    cat "sql/data-create-"$file".sql" | sqlite3 $PROJECT_NAME.db
  
    echo "- Create table called data$file with the $file data in it"
    echo ".import $CSV_RAW data"$file | sqlite3 -csv -header $PROJECT_NAME.db

    echo "Delete first row"
    echo "Delete from data$file where rowid IN (Select rowid from data$file limit 1);" > sql/delete-first-row.sql
    cat sql/delete-first-row.sql | sqlite3 -csv $PROJECT_NAME.db
  done
fi

# Can skip with the 'convert' param
if [[ " ${params_array[*]} " != *" queries "* ]]; then
  echo "Join CSVs"
  cat sql/join.sql | sqlite3 -header -csv $PROJECT_NAME.db > edits/01-county-pop-16.csv

  echo "Get top 10 fastest-growing counties"
  cat sql/top-ten.sql | sqlite3 -header -csv $PROJECT_NAME.db > output/top-ten.csv

fi