select a.district_name, a.district_id, b.District, a."2007", a."2008", a."2009", a."2010", a."2011", a."2012", a."2013", a."2014", a."2015", a."2016", b."2007 Total Recapture", b."2008 Total Recapture", b."2009 Total Recapture", b."2010 Total Recapture", b."2011 Total Recapture", b."2012 Total Recapture", b."2013 Total Recapture", b."2014 Total Recapture", b."2015 Total Recapture", b."2016 Total Recapture" 
from data_asatar a
inner join data_recapture b
on a.district_id = b.District;