select a.emails as EmailDatabase, b.Email, b.FirstName, b.LastName, b.Address, b.City, b.State, b.Zip, b.IP, b.DTStamp, b.Paragraph1, b.Paragraph2, b.Closing, b.District, b.Title, b.RepFirstName, b.RepLastName, b.RepAddr1, b.RepAddr2, b.RepCity,   b.RepState, b.RepZip, b.StateVoterID, b."Calc Party " as CalParty
from data_emails a
inner join data_responses b
on a.emails = replace(b.Email, '@', '-');