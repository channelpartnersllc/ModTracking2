select lms.Contract_Id, convert(datetime, lms.Termination_Date) as termination_date, case
	when na.non_accrual_date is not null then 1
	else 0
end as is_non_accrual, na.non_accrual_date
from Opportunity_Contract_LMS as lms
left join (
	select Contract_Id, convert(datetime, min(post_date)) 'non_accrual_date'
	from Report_Aspire_Contract_Modification
	where Reason like 'Non-Accrual' or
	Contract_Id in ('40517-BW', '42192-1W') or
	(
		Reason like 'N/A' and
		Type like 'Contract Modification'
	)
	group by Contract_Id
) as na on na.Contract_Id = lms.Contract_Id
where lms.Contract_Id like '%-%' and
lms.contract_id not like '%-%S' and
lms.Contract_Id not like '%OFEE' and
lms.Contract_Id not like '%TEST' and
lms.Contract_Id not like '%CP' and
lms.Contract_Id not like '%AM' and
lms.Contract_Id not like '%T%' and
lms.Contract_Id not like '%-10' and
lms.Contract_Id not like '%-20' and
year(lms.created_on_date) >= 2017