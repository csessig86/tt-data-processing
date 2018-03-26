# Redistricting project: Congressional District 35 analysis

This is the code we ran to create the files for our project on Congressional District 35. To run the analysis, run the following bash file:
  
  process.sh

For this analysis, we downloaded block-level data for ethnicity populations from [NHGIS](https://www.nhgis.org/) and block-level shapefiles from the [U.S. Census](https://www.census.gov/cgi-bin/geo/shapefiles/index.php). We then trimmed down the ethnicity spreadsheet, ran some math using Python (all scripts are located within the scripts directory) and merged the data with the block-level shapefiles.

We then pulled out just the Census blocks that were in counties that are within Congressional 35 because we didn't want to show a Hispanic overlay over the entire state, just CD 35. Finally, we simplified and converted to geojson and topojson formats.

We also simplified and converted all the U.S. House districts to show them on the first slide. And we pulled out a few precincts and Interstate 35 and drew a few lines using QGIS to use within the walkthrough. The code for filtering, simplifying and converting this is in the file as well.

NOTE: Some of the data was too large for Github so many of files could not be uploaded.

A simple map for previewing some of the data is available within the map directory.



