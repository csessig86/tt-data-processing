import agate
import re
from decimal import *
import sys

param = sys.argv[1]

filename = 'edits/' + param + '/buckets/pip_count.csv'
table = agate.Table.from_csv(filename)

# Global function
# Use variables to change output
class Percent(agate.Computation):
  def get_computed_data_type(self, table):
    return agate.Number()

  def run(self, table):
    total = 0
    new_column = []

    for row in table.rows:
      total += row[column]

    for row in table.rows:
      percent = round(Decimal(row[column]) / Decimal(total) * 100, 2)
      
      new_column.append(percent)

    return new_column

# Add percent of polgons in points extent
column = 'polygons_in_points_extent';

table_add = table.compute([
  ( 'percent_in_extent', Percent() )
])

# Add percent of points in polgon
column = 'points_in_polgon'

table_add_two = table_add.compute([
  ( 'percent_pip', Percent() )
])

# Output
table_add_two.to_csv('output/' + param + '-pip-calculate.csv')