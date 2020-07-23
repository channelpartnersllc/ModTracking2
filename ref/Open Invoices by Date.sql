            set nocount on;

			drop table if exists #phs;
            
            select distinct ph.Contract_Id, ph.Finance_Product, ph.Invoice_Number, convert(date, ph.Due_Date) 'due_date',
            convert(date, ph.Invoice_Date) 'invoice_date', convert(date, ph.Date_Paid) 'date_paid', ph.check_number, ph.invoice_description, ph.Due_Amount,
            ph.Amount_Paid, ph.Principal_Amount, ph.interest_amount, ph.contract_is_charge_off, ph.entered_by,
            case
            	when Payment_Type in ('ACH', 'Check', 'N/A') and
            		Invoice_Description in('Loan Payment', 'Loan Payoff', 'Interest Payment') then 1
            	else 0
            end 'is_valid_invoice', case
            	when Check_Number like 'Credit Memo' then 1
            	else 0
            end 'is_credit_memo', aph.is_cm_invoice, case
            	when aph.is_cm_invoice = 1 then 0
            	else ph.Amount_Paid
            end 'actual_amount_paid', case
            	when Terminated = 0 then 1
            	else 0
            end 'is_active'
            into #phs
            from Report_Aspire_Payment_History ph
            left join(
            	select aph.Contract_Id, aph.Invoice_Number, sum(
            		case
            			when Check_Number like 'Credit Memo' then 1
            			else 0
            		end
            	) as 'is_cm_invoice'
            	from Report_Aspire_Payment_History aph
            	group by aph.Contract_Id, aph.Invoice_Number
            ) as aph on aph.Contract_Id = ph.Contract_Id and aph.Invoice_Number = ph.Invoice_Number
            where ph.Contract_Id like '%-%' and
            ph.Payment_Type in ('ACH', 'Check', 'N/A') and
            ph.Invoice_Description in ('Loan Payment', 'Loan Payoff', 'Interest Payment') and
            aph.is_cm_invoice = 0 and
            ph.due_date < convert(date, getdate()) and
            ph.Contract_Id in (
            	select contract_id 
            from Opportunity_Contract_LMS as lms
            where (lms.Termination_Date is null or 
            lms.Termination_Date > '2019-12-31') and
            lms.Contract_Id like '%-%' and
            lms.Contract_Id not like '%-%S%'
            );
            
            
            drop table if exists #invoices;
            
            select distinct Contract_Id, invoice_date, Invoice_Number, min(due_date) as due_date, avg(due_amount) as due_amount,
            max(date_paid) as date_paid, sum(amount_paid) as amount_paid
            into #invoices
            from #phs
            group by Contract_Id, invoice_date, Invoice_Number;
            
            drop table if exists #open;
            
            select Contract_Id, Invoice_Number, convert(datetime, due_date) as due_date, amount_paid, due_amount, case
            	when due_amount > amount_paid then 1
            	when amount_paid is null then 1
            	else 0
            end as is_open_invoice
            from #invoices
			order by due_date
            
