Delete from data_recapture where rowid IN (Select rowid from data_recapture limit 1);
