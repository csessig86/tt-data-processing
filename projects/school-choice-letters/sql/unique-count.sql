select emails, count(emails) as count
from data_emails
where emails not like '%"%' and emails like "%.%"
group by emails;