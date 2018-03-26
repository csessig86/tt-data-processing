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


function checkCD {
  if [ $1 != "nueces" ] && [ $1 != "victoria" ] && [ $1 != "wharton" ]; then
    echo 35
  else
    echo false
  fi
}

# Cut columns we don't want
if [[ " ${params_array[*]} " != *" block_cut "* ]]; then
  echo "Cut unnecessary columns"
  csvcut -c GISJOIN,COUNTY,COUNTYA,BLOCKA,URBRURALA,CDA,SLDUA,SLDLA,ZCTA5A,SDUNIA,H7Z001,H7Z002,H7Z003,H7Z004,H7Z005,H7Z006,H7Z007,H7Z008,H7Z009,H7Z010,H7Z011,H7Z012,H7Z013,H7Z014,H7Z015,H7Z016,H7Z017 block_level/all/nhgis0002_csv/nhgis0002_ds172_2010_block.csv > block_level/all/nhgis0002_csv/01-cut.csv
fi

# Use Agate to add necessary column
if [[ " ${params_array[*]} " != *" block_add "* ]]; then
  echo "Add necessary columns"
  python scripts/add.py
fi

# Use Agate to divide the spreadsheet by counties
# And create a spreadsheet for each county
if [[ " ${params_array[*]} " != *" block_divide "* ]]; then
  echo "Divide the spreadsheet into counties"
  python scripts/divide.py
fi

# Merge shapefile with demographic data
# Shapefiles: https://www.census.gov/cgi-bin/geo/shapefiles/index.php
# Select 2010 / Blocks
# Demographic: https://www.nhgis.org/
if [[ " ${params_array[*]} " != *" block_merge "* ]]; then
  FILE="blocks_merged"
  SIMPLIFY="100%"

  echo "Merge block data with CSV and create geojson file"
  cd block_level/counties

  for dir in $(ls)
  do
    if [[ $(checkCD $dir) == 35 ]]; then
      cd $dir

      echo "Rename shapefiles"
      CENSUS_CODE=$(echo *.shp | sed 's/(.*block10)/.shp/g')
      echo "$CENSUS_CODE" > 'census-filename.txt'

      # brew install rename
      rename 's/(.*block10)/blocks/g' *

      echo "Merge CSV, shapefile"
      ogr2ogr -sql "select blocks.*, demographics.* from blocks left join 'demographics.csv'.demographics on blocks.GEOID10 = demographics.geoid" ${dir}_merge.shp blocks.shp

      cd ../

      echo "Merge into final block file"
      if [ -f “lines/$FILE.shp” ]
      then
        echo "Creating merge shapefile"
        ogr2ogr -f 'ESRI Shapefile' -update -append $FILE.shp ${dir}/${dir}_merge.shp -nln merge
      else
        echo "Merging $I"
        ogr2ogr -f 'ESRI Shapefile' -update -append $FILE.shp ${dir}/${dir}_merge.shp
      fi
    fi
  done

  cd ../../

  echo "Convert to geojson"
  mapshaper block_level/counties/$FILE.shp -simplify dp $SIMPLIFY -o format=geojson map/geojson/$FILE.geojson

  echo "Convert to mbtiles"
  rm map/mbtiles/blocks_merged.mbtiles
  tippecanoe -o map/mbtiles/blocks_merged.mbtiles -Z 5 -z 14 -ps -pf -pk -pC map/geojson/$FILE.geojson
fi

# Use Mapshaper to simplify, convert counties
if [[ " ${params_array[*]} " != *" counties "* ]]; then
  echo "Simplify, convert counties shapefile"
  
  # File paths
  # Shapefiles downloaded from the Texas Department of Transportation
  # http://gis-txdot.opendata.arcgis.com/
  SHP='counties/Texas_County_Boundaries.shp'
  SHP_SIMPLIFIED='counties/counties-simplified.shp'
  GEOJSON='map/geojson/counties.geojson'
  SIMPLIFY='2%'

  # Simplify
  mapshaper $SHP -simplify dp $SIMPLIFY -o format=shapefile $SHP_SIMPLIFIED

  # Convert to geojson
  mapshaper $SHP -simplify dp $SIMPLIFY -o format=geojson $GEOJSON

  # Add variable in front of file
  # so it can be called in javascript
  echo 'var geo_counties = ' | cat - $GEOJSON > temp && mv temp $GEOJSON
fi

# Use Mapshaper to simplify, convert U.S. House Districts
if [[ " ${params_array[*]} " != *" districts "* ]]; then
  echo "Simplify, convert House Districts shapefile"
  for file in $(ls us_house_districts)
  do
    # If we downloaded the shapefile from the Census, rename the file
    # and save the name of the file from the Census site
    # into a new file (just in case)
    if [[ "$file" == "all_07_13" || "$file" == "all_current" ]]; then
      if [[ "$file" == "all_07_13" ]]; then
        CENSUS_CODE='gz_2010_48_500_11_500k'
      else
        CENSUS_CODE='cb_2016_us_cd115_500k'
      fi

      if [ ! -f us_house_districts/$file/$CENSUS_CODE.shp ]; then
        CENSUS_CODE='Texas_US_House_Districts'
      fi

      # Filter out just TX
      if [[ "$file" == "all_current" ]]; then
        ogr2ogr -where "STATEFP='48'" us_house_districts/$file/$CENSUS_CODE.shp us_house_districts/$file/$CENSUS_CODE.shp
      fi
      
      for shp_file in us_house_districts/$file/*
      do
        mv "$shp_file" "${shp_file/$CENSUS_CODE/Texas_US_House_Districts}" 
      done

      echo "$CENSUS_CODE" > 'us_house_districts/'$file'/census-filename.txt'
    fi

    # File paths
    SHP="us_house_districts/$file/Texas_US_House_Districts.shp"
    SHP_SIMPLIFIED="us_house_districts/$file/"$file"_simplified.shp"
    GEOJSON="map/geojson/$file.geojson"
    TOPOJSON="map/topojson/$file.topojson"
    
    # Different simplification levels for different shapefiles
    if [[ "$file" == "23" ]]; then
      SIMPLIFY='3%'
    elif [[ "$file" == "35" ]]; then
      SIMPLIFY='15%'

      mapshaper $SHP -simplify dp $SIMPLIFY -o format=geojson map/geojson/$file-simplified.geojson
      mapshaper $SHP -simplify dp $SIMPLIFY -o format=topojson map/topojson/$file-simplified.topojson

      SIMPLIFY='100%'
    elif [[ "$file" == "all_current" ]]
    then
      SIMPLIFY='15%'

      mapshaper $SHP -simplify dp $SIMPLIFY -o format=geojson map/geojson/$file-simplified.geojson
      mapshaper $SHP -simplify dp $SIMPLIFY -o format=topojson map/topojson/$file-simplified.topojson

      SIMPLIFY='30%'
    else
      SIMPLIFY='15%'
    fi

    # Simplify
    echo "Convert to shapefile, geojson, topojson"
    mapshaper $SHP -simplify dp $SIMPLIFY -o format=shapefile $SHP_SIMPLIFIED
    
    # Convert to geojson
    mapshaper $SHP -simplify dp $SIMPLIFY -o format=geojson $GEOJSON
    
    # Simplify
    echo $GEOJSON | xargs >> $GEOJSON
    sed -E 's/([0-9]+\.[0-9]{7})[0-9]+/\1/g' $GEOJSON >> map/geojson/temp.geojson
    cat map/geojson/temp.geojson > $GEOJSON
    rm map/geojson/temp.geojson

    # Convert to topojson
    mapshaper $SHP -simplify dp $SIMPLIFY -o format=topojson $TOPOJSON

    # Add variable in front of file
    # so it can be called in javascript
    echo "var geo_$file = " | sed -E 's/[-]+/_/g' | cat - $GEOJSON > temp && mv temp $GEOJSON
  done
fi

# Create files for just the outline of Texas
if [[ " ${params_array[*]} " != *" tx_outline "* ]]; then
  cd us_house_districts/all_current

  FILE="Texas_US_House_Districts"
  FINAL='all_current_one_feature'
  SIMPLIFY="30%"

  echo "create layer of just Texas"
  /usr/local/bin/ogr2ogr $FINAL.shp $FILE.shp -nln $FILE -dialect sqlite -sql "SELECT ST_Union(geometry) AS geometry FROM $FILE"

  cd ../../

  # Convert to geojson, topojson
  mapshaper us_house_districts/all_current/$FINAL.shp name=$FILE -simplify dp $SIMPLIFY -o format=geojson map/geojson/$FINAL.geojson
  mapshaper us_house_districts/all_current/$FINAL.shp name=$FILE -simplify dp $SIMPLIFY -o format=topojson map/topojson/$FINAL.topojson

  SIMPLIFY="15%"

  mapshaper us_house_districts/all_current/$FINAL.shp name=$FILE -simplify dp $SIMPLIFY -o format=geojson map/geojson/$FINAL-simplified.geojson
  mapshaper us_house_districts/all_current/$FINAL.shp name=$FILE -simplify dp $SIMPLIFY -o format=topojson map/topojson/$FINAL-simplified.topojson  
fi

if [[ " ${params_array[*]} " != *" lines "* ]]; then
  SIMPLIFY="100%"
  NAME="Texas_US_House_Districts"
  # FILES=("squiggle" "arrowhead" "north-bexar")
  FILES=("north-bexar")
  
  echo "create geojson, topojson for lines we need to highlight"
  for file in "${FILES[@]}"
  do
    # Convert to geojson, topojson
    mapshaper lines/$file-line.shp name=$NAME -simplify dp $SIMPLIFY -o format=geojson map/geojson/$file.geojson
    mapshaper lines/$file-line.shp name=$NAME -simplify dp $SIMPLIFY -o format=topojson map/topojson/$file.topojson

    # Convert to geojson, topojson
    mapshaper lines/$file-line.shp name=$NAME -simplify dp $SIMPLIFY -o format=geojson map/geojson/$file-simplified.geojson
    mapshaper lines/$file-line.shp name=$NAME -simplify dp $SIMPLIFY -o format=topojson map/topojson/$file-simplified.topojson
  done
fi

if [[ " ${params_array[*]} " != *" precincts "* ]]; then
  SIMPLIFY="100%"
  OG_FILE="precincts/tl_2010_48453_vtd10.shp"
  NAME="Texas_US_House_Districts"
  KEYS=("484530433" "484530440")
  
  # 227
  echo "Pull out precincts and convert to geojson, topojson"
  for KEY in "${KEYS[@]}"
  do
    FILE="precinct-$KEY"

    # Pull out precincts
    ogr2ogr -where "GEOID10='$KEY'" precincts/$FILE.shp $OG_FILE

    # Convert
    mapshaper precincts/$FILE.shp name=$NAME -simplify dp $SIMPLIFY -o format=geojson map/geojson/$FILE.geojson
    mapshaper precincts/$FILE.shp name=$NAME -simplify dp $SIMPLIFY -o format=topojson map/topojson/$FILE.topojson

    SIMPLIFY="100%"

    mapshaper precincts/$FILE.shp name=$NAME -simplify dp $SIMPLIFY -o format=geojson map/geojson/$FILE-simplified.geojson
    mapshaper precincts/$FILE.shp name=$NAME -simplify dp $SIMPLIFY -o format=topojson map/topojson/$FILE-simplified.topojson
  done
fi

# Pull out interstate to put on map
if [[ " ${params_array[*]} " != *" interstate "* ]]; then
  OG_FILE="lines/tl_2013_48_prisecroads.shp"
  FILE="i-35"
  NAME="Texas_US_House_Districts"
  SIMPLIFY="100%"

  # ogr2ogr -where "FULLNAME='I- 35'" lines/$FILE-whole.shp $OG_FILE

  mapshaper lines/$FILE.shp name=$NAME -simplify dp $SIMPLIFY -o format=geojson map/geojson/$FILE.geojson
    mapshaper lines/$FILE.shp name=$NAME -simplify dp $SIMPLIFY -o format=topojson map/topojson/$FILE.topojson

  SIMPLIFY="50%"

  mapshaper lines/$FILE.shp name=$NAME -simplify dp $SIMPLIFY -o format=geojson map/geojson/$FILE-simplified.geojson
    mapshaper lines/$FILE.shp name=$NAME -simplify dp $SIMPLIFY -o format=topojson map/topojson/$FILE-simplified.topojson
fi