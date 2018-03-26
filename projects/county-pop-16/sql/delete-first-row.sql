Delete from dataPEPTCOMP where rowid IN (Select rowid from dataPEPTCOMP limit 1);
