import sys
import agate
import re
from decimal import *

param_file = sys.argv[1]
param_total_code = sys.argv[2]
param_demo_code = sys.argv[3]

table = agate.Table.from_csv(param_file + '.csv')

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

# edit the GEO id column in the spreadsheet so it lines up with
# the GEO ids in the shapefiles
class AddPercent(agate.Computation):
  def get_computed_data_type(self, table):
    return agate.Number()

  def run(self, table):
    new_column = []

    for row in table.rows:
      # if there are zero of this demographic, append zero
      if row[param_demo_code] == 0:
        new_column.append(0)
      # otherwise calculate percent
      else:
        print row[param_demo_code]
        print row[param_total_code]

        percent = round(Decimal(row[param_demo_code]) / Decimal(row[param_total_code]) * 100, 2)
        new_column.append(percent)

    return new_column

# add geoid 
table_add = table.compute([
  ( 'GEOID', AddGEOID() ),
  ( 'PERCENT', AddPercent() )
])

table_add.to_csv(param_file + '_add.csv')