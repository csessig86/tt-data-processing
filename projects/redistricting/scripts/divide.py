import agate
import re

# set up agate
filename = 'block_level/all/nhgis0002_csv/02-add.csv'

specified_types = {
  'COUNTYA': agate.Number(),
  'H7Z001': agate.Number(),
  'H7Z002': agate.Number(),
  'H7Z003': agate.Number(),
  'H7Z004': agate.Number(),
  'H7Z005': agate.Number(),
  'H7Z006': agate.Number(),
  'H7Z007': agate.Number(),
  'H7Z008': agate.Number(),
  'H7Z009': agate.Number(),
  'H7Z010': agate.Number(),
  'H7Z011': agate.Number(),
  'H7Z012': agate.Number(),
  'H7Z013': agate.Number(),
  'H7Z014': agate.Number(),
  'H7Z015': agate.Number(),
  'H7Z016': agate.Number(),
  'H7Z017': agate.Number(),
  'hispanic_perc': agate.Number()
}

counties = {
  'name': 'bastrop',
  'number': 21 
},{
  'name': 'bexar',
  'number': 29
},{
  'name': 'caldwell',
  'number': 55
},{
  'name': 'comal',
  'number': 91
},{
  'name': 'guadalupe',
  'number': 187
},{
  'name': 'hays',
  'number': 209
},{
  'name': 'nueces',
  'number': 355
},{
  'name': 'travis',
  'number': 453
},{
  'name': 'victoria',
  'number': 469
},{
  'name': 'wharton',
  'number': 481
}

# create csv for each county
for county in enumerate(counties):
  county = county[1]
  agate.Table.from_csv(filename, column_types=specified_types).where(lambda row: row['COUNTYA'] == county['number']).to_csv('counties/' + county['name'] + '/' + county['name'] + '-demographics.csv')

  # create csvt file
  csvt = open(filename + 't', "w")
  csvt.write('"String","String","Integer","String","Integer","String","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer","Integer"')
  
  csvt.close()