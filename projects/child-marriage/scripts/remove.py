import agate
import re

file = 'edits/04-merge.csv'
output = 'outputs/tx-child-marriage-rates.csv'

include_columns = ['STATE', 'GISJOIN', 'children_2006', 'marriages_2006', 'rate_2006', 'children_2011', 'marriages_2011', 'rate_2011']

table = agate.Table.from_csv(file)
new_table = table.select(include_columns)

new_table.order_by('rate_2011', reverse=True).to_csv(output)