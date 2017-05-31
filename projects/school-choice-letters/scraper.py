from bs4 import BeautifulSoup
import requests
import csv

# Create CSV that we will write emails into
writer = csv.writer( open("raw/addresses/addresses.csv", 'w') )
writer.writerow(['emails'])

# Loop through every one of their pages
# Numbered 428 to 92721
for num in range(1,92721):
  # URL
  url = "http://www.email-database.info/email-list/Email-list-free-" + str(num) + "/" + str(num) + ".html"
  request  = requests.get(url)

  print "Scraping: " + url

  # Request URL
  data = request.text

  # Parse with BS
  soup = BeautifulSoup(data, "html.parser")

  # The div with the emails in it
  table_div = soup.select('#main-border table table table table div')

  for br in soup.find_all('br'):
    email = br.nextSibling
    if email != None and email != "":
      email = email.encode('utf-8').strip()

      writer.writerow([email])

