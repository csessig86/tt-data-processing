import agate
import re
from decimal import *

# set up agate
filename = 'block_level/all/nhgis0002_csv/01-cut.csv'

column_names = ['GISJOIN', 'COUNTY', 'COUNTYA', 'BLOCKA', 'URBRURALA', 'CDA', 'SLDUA', 'SLDLA', 'ZCTA5A', 'SDUNIA', 'H7Z001', 'H7Z002', 'H7Z003', 'H7Z004', 'H7Z005', 'H7Z006', 'H7Z007', 'H7Z008', 'H7Z009', 'H7Z010', 'H7Z011', 'H7Z012', 'H7Z013', 'H7Z014', 'H7Z015', 'H7Z016', 'H7Z017']

column_types = [agate.Text(), agate.Text(), agate.Number(), agate.Number(), agate.Text(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number(), agate.Number()]

# remove second row that's a second header column
table_row = agate.Table.from_csv(filename).where(lambda row: re.search('^(?!GIS Join Match Code|\\.).*', row['GISJOIN']))

# specify which columns are numbers, despite many zeros
table = agate.Table(table_row, column_names, column_types)

# use this variable to specify which column the spreadsheet
# we will be calculate the percent on
demographic = 'H7Z001'

class PercentChange(agate.Computation):
  def get_computed_data_type(self, table):
    return agate.Number()

  def run(self, table):
    new_column = []

    for row in table.rows:
      # if there are zero of this demographic, append zero
      if row['H7Z010'] == 0:
        new_column.append(0)
      # otherwise calculate percent
      else:
        percent = round(Decimal(row['H7Z010']) / Decimal(row[demographic]) * 100, 2)
        new_column.append(percent)

    return new_column

# edit the GEO id column in the spreadsheet so it lines up with
# the GEO ids in the shapefiles
class AddGEOID(agate.Computation):
  def get_computed_data_type(self, table):
    return agate.Number()

  def run(self, table):
    new_column = []

    # the shapefile GEO ids have fewer characters
    # so we're going to remove those in the spreadsheet
    for index, row in enumerate(table.rows):
      final_chars = ''

      for index_two, chars in enumerate(row['GISJOIN']):
        # these are characters missing from the shapefil GEO ids
        if index_two != 0 and index_two != 3 and index_two != 7:
          final_chars += chars

      
      new_column.append(final_chars)

    return new_column

# calculate hispanic percentage
# and 
table_add = table.compute([
  ( 'hispanic_perc', PercentChange() ),
  ( 'geoid', AddGEOID() )
])

table_add.to_csv('block_level/all/nhgis0002_csv/02-add.csv')