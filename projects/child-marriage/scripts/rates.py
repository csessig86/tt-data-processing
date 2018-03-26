import agate
import re

years = ['2006', '2011']

# All numerical columns
all_columns = ['004', '066', '081', '097', '159', '174', '020', '036', '051', '113', '129', '144']

# The columns we'll use to find the number of marriages
marriage_columns = ['020', '036', '051', '113', '129', '144']

class CalculateChildren(agate.Computation):
  def get_computed_data_type(self, table):
    return agate.Number()

  def run(self, table):
    new_column = []

    for index, row in enumerate(table.rows):
      total = 0

      for i in range(len(all_columns)):
        total += row[code + all_columns[i]]

      new_column.append(total)

    return new_column

class CalculateMarriages(agate.Computation):
  def get_computed_data_type(self, table):
    return agate.Number()

  def run(self, table):
    new_column = []

    for index, row in enumerate(table.rows):
      total = 0

      for i in range(len(marriage_columns)):
        total += row[code + marriage_columns[i]]

      new_column.append(total)

    return new_column

class CalculateRates(agate.Computation):
  def get_computed_data_type(self, table):
    return agate.Number()

  def run(self, table):
    new_column = []

    for index, row in enumerate(table.rows):
      total = 0
      marriage_total = 0

      for i in range(len(all_columns)):
        total += row[code + all_columns[i]]

      for i in range(len(marriage_columns)):
        marriage_total += row[code + marriage_columns[i]]

      rate = (marriage_total / total) * 1000
      new_column.append( round(rate, 1) )

    return new_column


for year in years:
  print 'Getting rates for ' + year

  file = 'edits/01-cut-' + year + '.csv'
  output = 'edits/02-rates-' + year + '.csv'

  if year == '2006':
    code = 'ABQAE'
  else:
    code = 'ADZEE'

  table = agate.Table.from_csv(file)

  table_add = table.compute([
    ( 'children_%s' % year, CalculateChildren() ),
    ( 'marriages_%s' % year, CalculateMarriages() ),
    ( 'rate_%s' % year, CalculateRates() )
  ])

  table_add.order_by('rate_%s' % year, reverse=True).to_csv(output)