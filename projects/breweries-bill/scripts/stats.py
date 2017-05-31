import agate

# set up agate
filename = 'edits/04-stack.csv'
table = agate.Table.from_csv(filename)

# CONTRIBUTIONS BY DISTRIBUTOR
filer_id = 'filerident'
expend_amount = 'expendamount'

# pivot by distributor ID and their name
table_pivot_name = table.select([filer_id, 'filername']).distinct()
# count how many contributions they made
table_pivot_count = table.pivot(filer_id)
# and sum their contribution amounts
table_pivot_sum = table.pivot(filer_id, aggregation=agate.Sum(expend_amount))

# join our tables
table_join_one = table_pivot_name.join(table_pivot_count, filer_id, filer_id)
table_join_final = table_join_one.join(table_pivot_sum, filer_id, filer_id, inner=True)
table_join_distinct = table_join_final.distinct(filer_id)

# save to CSV
table_join_distinct.to_csv('output/distributor-contributions.csv')


# CONTRIBUTIONS BY POLITICIAN
last_name = 'payeenamelast'
first_name = 'payeenamefirst'

# pivot by politician
table_pivot_count = table.pivot([last_name, first_name])
table_pivot_sum = table.pivot(last_name, aggregation=agate.Sum(expend_amount))

table_join = table_pivot_count.join(table_pivot_sum, last_name, last_name).order_by('Sum', reverse=True)

# save to CSV
table_join.to_csv('output/politician-contributions.csv')