#!/bin/bash

# Pull out parameters and make them an array
# Called params_array
params=$1
prefix="--skip="
param=${params#$prefix}
IFS=', ' read -r -a params_array <<< ${param}

params_two=$2
prefix_data="--data="
param_data=${params_two#$prefix_data}
IFS='_' read -r -a param_data_array <<< "$param_data"

# Create some globals about our files
function getVariables {
  if [ $1 == "hispanic" ]; then
    RAW_FILE="nhgis0010_ds215_20155_2015_blck_grp"
    TOTAL_CODE="ADK5E001"
    DEMO_CODE="ADK5E012"
  elif [ $1 == "poverty" ]; then
    RAW_FILE="nhgis0013_ds215_20155_2015_blck_grp"
    TOTAL_CODE="ADNHE001"
    DEMO_CODE="ADNHE002"
  fi
}

# WHAT YOU CAN RUN:
# --data=svi_femaextent
# --data=svi_COUNTYNAME
# i.e: --data=svi_harris
# --data=demo_COUNTYNAME_DEMOGRAPHIC
# i.e: --data=demo_harris_hispanic

# Run tasks that get the data set up for processing
if [[ " ${params_array[*]} " != *" pre "* ]]; then
  PREFIX_PARAM="${param_data_array[0]}"
  EXTENT_PARAM="${param_data_array[1]}"
  DEMO_PARAM="${param_data_array[2]}"
  RAW_POINTS="../../../raw/FEMA_damage_assessments/FEMA_Damage_Assessments_Harvey_Public_0829"
  RAW_COUNTIES_OG="../../../raw/tx_counties/txdot-2015-county-generalized_tx"
  RAW_POLYGONS="pre_raw_polygons"
  DIR="edits/$param_data/buckets"
  A_SHP="pre_fema_assessments"
  B_EXTENT="pre_"$EXTENT_PARAM

  # Social vulnerability index
  if [[ $param_data == *"svi"* ]]; then
    RAW_POLYGONS_OG="../../../raw/social-vulnerability-index/shape/TEXAS"
  # Demographics
  elif [[ $param_data == *"demo"* ]]; then
    getVariables $DEMO_PARAM
    RAW_POLYGONS_OG="../../../raw/tx_block_groups_2015/tl_2015_48_bg"
    RAW_DEMO_OG="../../../raw/tx_block_groups_"$DEMO_PARAM"_2015/"$RAW_FILE
    RAW_DEMO="pre_tx_"$DEMO_PARAM
    C_MERGE="pre_"$EXTENT_PARAM"_"$DEMO_PARAM
  fi

  echo "Remove files we're going to create"
  rm -r $DIR/*pre_*

  echo "make dir, then cd into it"
  mkdir -p edits/$param_data
  mkdir -p $DIR
  mkdir -p $DIR-backup
  cd $DIR

  echo "Convert points gdb to shapefile"
  ogr2ogr -f "ESRI Shapefile" $A_SHP.shp $RAW_POINTS.gdb

  echo "Move polygons into local dir"
  ogr2ogr -f "ESRI Shapefile" $RAW_POLYGONS.shp $RAW_POLYGONS_OG.shp

  # Social vulnerability index: Entire damage area
  if [[ " $param_data " == *"femaextent"* ]]; then
    echo "Get extent of points"
    ogr2ogr $B_EXTENT.shp $A_SHP.shp -dialect sqlite -sql "select extent(geometry) from $A_SHP"
  # Social vulnerability index: Specific (i.e. Harris County only)
  else
    # brew install --default-names gnu-sed
    TITLE=$(echo "$EXTENT_PARAM" | sed -e 's/.*/\L&/; s/[a-z]*/\u&/g')

    echo "Pull $EXTENT_PARAM boundary out of state file"
    ogr2ogr -where "CNTY_NM='$TITLE'" $B_EXTENT.shp $RAW_COUNTIES_OG.shp
  # Demographics
  fi

  if [[ $param_data == *"demo"* ]]; then
    echo "Move demographics to local dir"
    cp $RAW_DEMO_OG.csv $RAW_DEMO.csv
  fi

  cd ../../../
fi

# Process the data
# By breaking up shapefile buckets
# Calculating points in polygon, etc.
if [[ " ${params_array[*]} " != *" process "* ]]; then
  PREFIX_PARAM="${param_data_array[0]}"
  EXTENT_PARAM="${param_data_array[1]}"
  DEMO_PARAM="${param_data_array[2]}"
  MAX_BUCKET_PARAM="${param_data_array[3]}"
  DIR="edits/$param_data"
  PIP_COUNT="pip_count"
  BUCKETS=10
  RAW_POLYGONS="pre_raw_polygons"
  RAW_POINTS="pre_fema_assessments"
  BOUNDARY_EXTENT="pre_"$EXTENT_PARAM
  RAW_POLYGONS_EXTENT=$PREFIX_PARAM"_polygons_within_"$EXTENT_PARAM

  # Social vulnerability index
  if [[ $param_data == *"svi"* ]]; then
    COLUMN="RPL_THEMES"
    DISSOLVE_COLUMN="STATE"
  # Demographics
  elif [[ $param_data == *"demo"* ]]; then
    getVariables $DEMO_PARAM
    RAW_DEMO="pre_tx_"$DEMO_PARAM
    DISSOLVE_COLUMN="STATEFP"
  fi

  echo "cd into dir"
  cd $DIR

  echo "Make backup of buckets dir before clearing"
  rm -r buckets-backup/*
  cp -R buckets/* buckets-backup
  rm -r buckets/*$PREFIX_PARAM*

  echo "cd into buckets dir"
  cd buckets

  echo "Open vrt file and append info for raw shapefiles"
  FILES=($RAW_POLYGONS $BOUNDARY_EXTENT)

  echo "Create vrt file with shapefile info"
  >raw.vrt
  echo '<OGRVRTDataSource>' >> raw.vrt
  for file in ${FILES[@]}
  do
    echo "<OGRVRTLayer name='$file'>" >> raw.vrt
    echo "<SrcDataSource>"$file".shp</SrcDataSource>" >> raw.vrt
    echo "</OGRVRTLayer>" >> raw.vrt
  done
  echo '</OGRVRTDataSource>' >> raw.vrt

  echo "Get $PREFIX_PARAM polygons within $EXTENT_PARAM"
  ogr2ogr -f "ESRI Shapefile" $RAW_POLYGONS_EXTENT.shp raw.vrt -dialect sqlite -sql "SELECT * FROM $RAW_POLYGONS, $BOUNDARY_EXTENT WHERE ST_Intersects($RAW_POLYGONS.geometry, $BOUNDARY_EXTENT.geometry)"

  if [[ $param_data == *"demo"* ]]; then
    RAW_POLYGONS_EXTENT_MERGE=$param_data"_polygons"
    SPATIAL_CODE="STATEFP"

    echo "Add columns to demographics csv"
    python ../../../scripts/add_columns.py $RAW_DEMO $TOTAL_CODE $DEMO_CODE
    
    RAW_DEMO=$RAW_DEMO"_add"
    COLUMN='PERCENT'

    echo "Merge demographics with shapefile"
    ogr2ogr -mapFieldType String=Integer -sql "select * from $RAW_POLYGONS_EXTENT left join '$RAW_DEMO.csv'.$RAW_DEMO on $RAW_POLYGONS_EXTENT.GEOID = $RAW_DEMO.GEOID" $RAW_POLYGONS_EXTENT_MERGE.shp $RAW_POLYGONS_EXTENT.shp

    RAW_POLYGONS_EXTENT="$RAW_POLYGONS_EXTENT_MERGE"

    if [[ $MAX_BUCKET_PARAM ]]; then
      echo "Use max demographic in parameters"
      MAX_DEMO=$MAX_BUCKET_PARAM
    else
      echo "Max demo will be 100, because it's broken into percent"
      MAX_DEMO=100

      echo "Get max demographic using sql and write to file"
      >max_demo.txt
      ogrinfo -q $RAW_POLYGONS_EXTENT.shp -dialect sqlite -sql "SELECT MAX($COLUMN) FROM $RAW_POLYGONS_EXTENT" >> max_demo.txt

      # while IFS= read -r line
      # do
      #   if [[ $line == *"MAX"* ]]; then
      #     MAX_DEMO=${line/*[^0-9]/}
      #   fi
      # done < max_demo.txt
    fi
  elif [[ $param_data == *"svi"* ]]; then
    SPATIAL_CODE="FIPS"
  fi


  echo "Clear pip count file"
  >$PIP_COUNT.txt
  >$PIP_COUNT.csv

  for i in $(seq 1 $BUCKETS);
  do
    if [[ $param_data == *"svi"* ]]; then
      # Break SVI into buckets based on overall score. Example:
      # 0.1 - 0.2
      # and
      # 0.2 - 0.3
      PREV=$(($i - 1))
      PREV="0."$PREV
      if [ $i -lt 10 ]; then
        CUR="0."$i
      else
        MINUS=$(($i - 10))
        CUR="1."$MINUS
      fi
      PREV_PRETTY=${PREV//.}
    CUR_PRETTY=${CUR//.}
    elif [[ $param_data == *"demo"* ]]; then
      INCREMENT=$(($MAX_DEMO  / $BUCKETS))

      PREV=$(( ($INCREMENT * $i) - $INCREMENT))
      PREV_PRETTY=$PREV
      CUR=$(( $INCREMENT * $i))
      CUR_PRETTY=$CUR
    fi

    A_FILTER_FILE="a_"$PREFIX_PARAM"_$PREV_PRETTY"_"$CUR_PRETTY"
    B_DISSOLVE_FILE="b_"$A_FILTER_FILE"_dissolve"
    C_PIP_FILE="c_"$A_FILTER_FILE"_pip"
    D_SPATIAL_JOIN="d_"$A_FILTER_FILE"_spatial"

    echo "---"
    echo "WORKING ON: >= $PREV AND < $CUR"

    echo "Create file with bucket"
    ogr2ogr -where "$COLUMN >= '$PREV' AND $COLUMN < '$CUR'" $A_FILTER_FILE.shp $RAW_POLYGONS_EXTENT.shp

    echo "Append info for edited shapefiles to vrt file"
    FILES=($A_FILTER_FILE $B_DISSOLVE_FILE $RAW_POINTS $C_PIP_FILE)

    >$A_FILTER_FILE.vrt
    echo '<OGRVRTDataSource>' >> $A_FILTER_FILE.vrt
    for file in ${FILES[@]}
    do
      echo "<OGRVRTLayer name='$file'>" >> $A_FILTER_FILE.vrt
      echo "<SrcDataSource>"$file".shp</SrcDataSource>" >> $A_FILTER_FILE.vrt
      echo "</OGRVRTLayer>" >> $A_FILTER_FILE.vrt
    done
    echo '</OGRVRTDataSource>' >> $A_FILTER_FILE.vrt

    echo "Dissolve into one shapfile"
    ogr2ogr $B_DISSOLVE_FILE.shp $A_FILTER_FILE.vrt -dialect sqlite -sql "SELECT ST_Union(geometry), $DISSOLVE_COLUMN FROM $A_FILTER_FILE GROUP BY $DISSOLVE_COLUMN"
    
    echo "Count polygons in points extent and output to text file"
    echo "CURRENTFILE: $A_FILTER_FILE" >> $PIP_COUNT.txt
    ogrinfo $A_FILTER_FILE.vrt -dialect sqlite -sql "SELECT COUNT(*) as polygons_in_points_extent FROM $A_FILTER_FILE" >> $PIP_COUNT.txt

    echo "Count points in polgons and output to text file"
    if [ ! -f $B_DISSOLVE_FILE.shp ]; then
      echo "points_in_polgon (Integer) = 0" >> $PIP_COUNT.txt
    else
      ogrinfo $A_FILTER_FILE.vrt -dialect sqlite -sql "SELECT COUNT(*) as points_in_polgon FROM $B_DISSOLVE_FILE, $RAW_POINTS WHERE ST_Intersects($B_DISSOLVE_FILE.geometry, $RAW_POINTS.geometry) GROUP BY $B_DISSOLVE_FILE.$DISSOLVE_COLUMN" >> $PIP_COUNT.txt
    fi
    echo '---' >> $PIP_COUNT.txt

    echo "Convert text file csv"
    >$PIP_COUNT.csv
    printf "polygons,polygons_in_points_extent,points_in_polgon\n" >> $PIP_COUNT.csv
    while IFS= read -r line
    do
      # Filename
      if [[ $line == *"CURRENTFILE"* ]]; then
        FILE=${line/*[CURRENTFILE: ]/}
        FILE_EDIT="${FILE:2}"

        printf "$FILE_EDIT," >> $PIP_COUNT.csv
      # If we have zero polygons in points extent
      elif [[ $line == *"polygons_in_points_extent: String"* ]]; then
        printf "0," >> $PIP_COUNT.csv
      # If we have more than zero polygons in points extent
      elif [[ $line == *"polygons_in_points_extent (Integer)"* ]]; then
        NUM=${line/*[^0-9]/}
        if [[ $NUM == "" ]]; then
          NUM="0"
        fi

        printf "$NUM," >> $PIP_COUNT.csv
      # If we have zero pip
      elif [[ $line == *"points_in_polgon: String"* ]]; then
        printf "0\n" >> $PIP_COUNT.csv
      # If we have more than zero pip
      elif [[ $line == *"points_in_polgon (Integer)"* ]]; then
        NUM=${line/*[^0-9]/}
        if [[ $NUM == "" ]]; then
          NUM="0"
        fi

        printf "$NUM\n" >> $PIP_COUNT.csv
      fi
    done < $PIP_COUNT.txt

    echo "Output points inside polygons"
    ogr2ogr -f "ESRI Shapefile" $C_PIP_FILE.shp $A_FILTER_FILE.vrt -dialect sqlite -sql "SELECT $RAW_POINTS.geometry, $RAW_POINTS.DMG_LEVEL, $RAW_POINTS.COUNTY, $RAW_POINTS.FIPS, $RAW_POINTS.PROD_DATE, $RAW_POINTS.LONGITUDE, $RAW_POINTS.LATITUDE FROM $B_DISSOLVE_FILE, $RAW_POINTS WHERE ST_Intersects($B_DISSOLVE_FILE.geometry, $RAW_POINTS.geometry)"

    echo "Output polygons with $PREFIX_PARAM, point counts"
    ogr2ogr -f "ESRI Shapefile" $D_SPATIAL_JOIN.shp $A_FILTER_FILE.vrt -dialect sqlite -sql "SELECT $A_FILTER_FILE.geometry, $A_FILTER_FILE.GEOID, $A_FILTER_FILE.$COLUMN, COUNT(*) as count FROM $A_FILTER_FILE, $C_PIP_FILE WHERE ST_Contains($A_FILTER_FILE.geometry, $C_PIP_FILE.geometry) GROUP BY $A_FILTER_FILE.GEOID"
  done

  cd ../../../
fi

# Use Agate to run calculations
if [[ " ${params_array[*]} " != *" calculate "* ]]; then
  echo "Do some calculations with the pip data"
  python scripts/pip.py $param_data
fi