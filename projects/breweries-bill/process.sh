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

RAW_NUMS=('00015672' '00015767')

# Cut out the unnecessary columns
if [[ " ${params_array[*]} " != *" cut "* ]]; then

  for num in "${RAW_NUMS[@]}"
  do
    FILEPATH='raw/expends-'$num'.csv'

    csvcut -c formtypecd,reportinfoident,receiveddt,filerident,filername,expenddt,expendamount,expenddescr,expendcatcd,payeepersenttypecd,payeenameorganization,payeenamelast,payeenamefirst,payeestreetaddr1,payeestreetaddr2,payeestreetcity,payeestreetstatecd,payeestreetpostalcode,id $FILEPATH > edits/01-$num-cut.csv

  done
fi

# Find just the campaign contributions
if [[ " ${params_array[*]} " != *" filter "* ]]; then

  for num in "${RAW_NUMS[@]}"
  do
    FILEPATH='edits/01-'$num'-cut.csv'

    csvgrep -c expendcatcd -m 'DONATIONS' $FILEPATH > edits/02-$num-filter.csv
  done
fi

# Stack the spreadsheets into one
if [[ " ${params_array[*]} " != *" date "* ]]; then
  for num in "${RAW_NUMS[@]}"
  do
    FILEPATH='edits/02-'$num'-filter.csv'

    csvgrep -c expenddt -r "[0-1][0-9]/[0-3][0-9]/201[5-7]" $FILEPATH > edits/03-$num-date.csv
  done
fi

# Stack the spreadsheets into one
if [[ " ${params_array[*]} " != *" stack "* ]]; then

  csvstack 'edits/03-'${RAW_NUMS[0]}'-date.csv' 'edits/03-'${RAW_NUMS[1]}'-date.csv' > 'edits/04-stack.csv'
fi

#
if [[ " ${params_array[*]} " != *" stats "* ]]; then
  python scripts/stats.py
fi