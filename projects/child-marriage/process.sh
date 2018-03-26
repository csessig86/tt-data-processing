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

CSV_THREE="edits/02-rates.csv"

# Cut out columns we don't need
if [[ " ${params_array[*]} " != *" cut "* ]]; then
	YEARS=("2006" "2011")
  
  for year in ${YEARS[@]}
  do
    echo "Cutting $year data"
    if [[ "$year" == "2006" ]]; then
      CODE="ABQAE"
      CSV_ONE="raw/2006-10/nhgis0008_ds207_20145_2014_state.csv"
    else
      CODE="ADZEE"
      CSV_ONE="raw/2011-15/nhgis0007_ds216_20155_2015_state.csv"
    fi

    CSV_TWO="edits/01-cut-"$year".csv"

    csvcut -c 'GISJOIN,STATE,STATEA,'$CODE'004,'$CODE'066,'$CODE'081,'$CODE'097,'$CODE'159,'$CODE'174,'$CODE'020,'$CODE'036,'$CODE'051,'$CODE'113,'$CODE'129,'$CODE'144' $CSV_ONE > $CSV_TWO
  done
fi

# Calculate rates
if [[ " ${params_array[*]} " != *" rates "* ]]; then
  python scripts/rates.py
fi

# Trim spreadsheet for output
if [[ " ${params_array[*]} " != *" trim "* ]]; then
  YEARS=("2006" "2011")

  for year in ${YEARS[@]}
  do
    echo "Trimming $year data"
    CSV_THREE="edits/02-rates-"$year".csv"
    CSV_FOUR="edits/03-trim-"$year".csv"
    
    csvcut -c "STATE,GISJOIN,children_$year,marriages_$year,rate_$year" $CSV_THREE > $CSV_FOUR
  done
fi

# Join 2006, 2011 spreadsheets
if [[ " ${params_array[*]} " != *" join "* ]]; then
  csvjoin edits/03-trim-2006.csv edits/03-trim-2011.csv -c "GISJOIN" > edits/04-merge.csv
fi

# Remove duplicate columns
if [[ " ${params_array[*]} " != *" remove "* ]]; then
  python scripts/remove.py
fi
