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

# Convert the responses SS and put into the DB
if [[ " ${params_array[*]} " != *" responses "* ]]; then
  XLS_RAW='raw/responses.xlsx'
  CSV_RAW='raw/responses.csv'
  RESPONSES="responses"

  # echo "- Convert Excel file to CSV"
  # in2csv $XLS_RAW > $CSV_RAW

  echo "- Create table SQL statement"
  csvsql -i sqlite --tables "data"$RESPONSES $CSV_RAW > "sql/data-create-"$RESPONSES".sql"
fi

# Create tables for each CSV in database
if [[ " ${params_array[*]} " != *" db "* ]]; then
  for file in "${FILES[@]}"
  do
    CSV_RAW='raw/addresses/addresses_'$file'.csv'
    CSV_RESPONSES="raw/responses.csv"
    DB="db/db_$file.db"

    # echo "- Create table SQL statement"
    # csvsql -i sqlite --tables "data" $CSV_RAW > "sql/data-create-emails.sql"

    echo "- Remove database if it exists"
    if [ -f $DB ] ; then
      rm $DB
    fi

    echo "- Create table called data_emails"
    cat "sql/data-create-emails.sql" | sqlite3 $DB
  
    echo "- Import $file data"
    echo ".import $CSV_RAW data_emails" | sqlite3 -csv -header $DB

    echo "- Delete first row"
    echo "Delete from data_emails where rowid IN (Select rowid from data_emails limit 1);" > sql/delete-first-row.sql
    cat sql/delete-first-row.sql | sqlite3 -csv $DB

    echo "- Create table called data_responses"
    cat "sql/data-create-responses.sql" | sqlite3 $DB

    echo "- Import responses data"
    echo ".import $CSV_RESPONSES data_responses"| sqlite3 -csv -header $DB

    echo "- Delete first row"
    echo "Delete from data_responses where rowid IN (Select rowid from data_responses limit 1);" > sql/delete-first-row.sql
    cat sql/delete-first-row.sql | sqlite3 -csv $DB
  done
fi

# Join all the CSVs into one
if [[ " ${params_array[*]} " != *" join "* ]]; then
  for file in "${FILES[@]}"
  do
    DB="db/db_$file.db"

    echo "- Join CSVs: $file"
    cat sql/join.sql | sqlite3 -header -csv $DB > edits/01-join-"$file".csv
  done
fi

# Append CSV files to one another
if [[ " ${params_array[*]} " != *" stack "* ]]; then
  CSV_STACK=edits/02-join-stack.csv
  DB="db/db_stack.db"

  echo "- Stack our CSV files into one"
  csvstack edits/01-join-428_1490.csv edits/01-join-1491_2233.csv edits/01-join-2234_2274.csv edits/01-join-2275_12355.csv edits/01-join-12356_15833.csv edits/01-join-15834_20874.csv edits/01-join-20875_21194.csv edits/01-join-21195_26997.csv edits/01-join-26998_31455.csv edits/01-join-31456_58432.csv edits/01-join-58432_62594.csv edits/01-join-62595_64169.csv edits/01-join-64170_72527.csv edits/01-join-72528_72657.csv edits/01-join-72657_85963.csv edits/01-join-85963_90105.csv edits/01-join-90106_92721.csv > $CSV_STACK

  echo "- Remove database if it exists"
  if [ -f $DB ] ; then
    rm $DB
  fi

  # echo "- Create table SQL statement"
  # csvsql -i sqlite --tables "data_stack" $CSV_STACK > "sql/data-create-stack.sql"

  echo "- Create table called data_stack"
  cat "sql/data-create-stack.sql" | sqlite3 $DB

  echo "- Import stack data"
  echo ".import $CSV_STACK data_stack"| sqlite3 -csv -header $DB

  echo "- Delete first row"
  echo "Delete from data_stack where rowid IN (Select rowid from data_stack limit 1);" > sql/delete-first-row.sql
  cat sql/delete-first-row.sql | sqlite3 -csv $DB
fi

if [[ " ${params_array[*]} " != *" distinct "* ]]; then
  DB="db/db_stack.db"

  cat sql/distinct.sql | sqlite3 -header -csv $DB > output/matching-emails.csv
fi

if [[ " ${params_array[*]} " != *" count "* ]]; then
  for file in "${FILES[@]}"
  do
    DB="db/db_$file.db"

    echo "- Get unique emails and count in the $file csv"
    cat sql/unique-count.sql | sqlite3 -header -csv $DB > edits/03-unique-count-"$file".csv
  done

  CSV_STACK=edits/03-unique-count-stack.csv
  DB="db/db_count.db"

  echo "- Stack our CSV files into one"
  csvstack edits/03-unique-count-428_1490.csv edits/03-unique-count-1491_2233.csv edits/03-unique-count-2234_2274.csv edits/03-unique-count-2275_12355.csv edits/03-unique-count-12356_15833.csv edits/03-unique-count-15834_20874.csv edits/03-unique-count-20875_21194.csv edits/03-unique-count-21195_26997.csv edits/03-unique-count-26998_31455.csv edits/03-unique-count-31456_58432.csv edits/03-unique-count-58432_62594.csv edits/03-unique-count-62595_64169 64170_72527.csv edits/03-unique-count-72528_72657.csv edits/03-unique-count-72657_85963.csv edits/03-unique-count-85963_90105.csv edits/03-unique-count-90106_92721.csv > $CSV_STACK

  echo "- Create table SQL statement"
  csvsql -i sqlite --tables "data_emails" $CSV_STACK > "sql/data-create-unique-count.sql"

  echo "- Create table called data_emails"
  cat "sql/data-create-unique-count.sql" | sqlite3 $DB

  echo "- Import stack data"
  echo ".import $CSV_STACK data_emails"| sqlite3 -csv -header $DB

  echo "- Delete first row"
  echo "Delete from data_emails where rowid IN (Select rowid from data_emails limit 1);" > sql/delete-first-row.sql
  cat sql/delete-first-row.sql | sqlite3 -csv $DB

  # Queries
  echo "- Get unique emails and count in the stacked csv"
  echo cat sql/unique-count.sql | sqlite3 -header -csv $DB > edits/04-unique-count.csv

  echo "- Get count of emails"
  echo cat sql/count.sql | sqlite3 -header -csv $DB > output/email-database-count.csv
fi