Delete from data_stack where rowid IN (Select rowid from data_stack limit 1);
