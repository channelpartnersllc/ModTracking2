select distinct contract_id, Customer_Name, convert(datetime, post_date) as post_date
from Report_Aspire_Contract_Modification as cm
where reason like 'Extended Covid Mod'