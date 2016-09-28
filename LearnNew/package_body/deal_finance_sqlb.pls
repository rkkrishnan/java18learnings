CREATE OR REPLACE PACKAGE BODY DEAL_FINANCE_SQL AS
-----------------------------------------------------------------------------------------------------------------------------
-- Mod By     : Manikandan V, manikandan.varadhan@in.tesco.com
-- Mod Date   : 04-Jun-2009
-- Mod Ref    : DefNBS012789
-- Mod Details: new function ADD_MONTHS_454 included to add months according to the 454 calendar.
-- 	            Modified the function CALC_NEXT_REPORT_DATE to add months correctly for billing type
--              M/Q/H/A in case of 454 calenders
-----------------------------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 01-Jul-2009
-- Mod Ref    : Oracle Patch 8596119. Modification against defect NBS00012789 has been replaced by this Oracle Patch.
-- Mod Details: New function ADD_MONTHS_454 has been added.
-----------------------------------------------------------------------------------------------------------------------------
FUNCTION VALIDATE_INVOICE_DATE(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_invoice_date    IN     DATE,
                               I_deal_id         IN     DEAL_HEAD.DEAL_ID%TYPE,
                               I_deal_start_date IN     DATE,
                               I_deal_end_date   IN     DATE)
RETURN BOOLEAN IS
   L_program                  VARCHAR2(50) := 'DEAL_FINANCE_SQL.VALIDATE_INVOICE_DATE';
   L_reporting_date           DATE;
   L_last_invoice_date        DATE;
   L_count                    NUMBER;
   cursor c_actuals is
   select min(reporting_date)
     from deal_actuals_forecast
    where deal_id = I_deal_id;

   cursor c_deal_head is
   select last_invoice_date
     from deal_head
    where deal_id = I_deal_id;

BEGIN

   --check for null parameters
   if I_invoice_date is null or I_deal_id is null or I_deal_start_date is null or I_deal_end_date is null then
      O_error_message := sql_lib.create_msg('INV_PARAM_PROG_UNIT', L_program, null, null);
      return FALSE;
   end if;

   --check invoice date is greater than the deal start date
   if I_invoice_date < I_deal_start_date then
      O_error_message := sql_lib.create_msg('INV_INVC_START_DATE', null, null, null);
      return FALSE;
   end if;

   --Check date passed in is greater than the first reporting period
    open c_actuals;
   fetch c_actuals into L_reporting_date;
   close c_actuals;

   if I_invoice_Date < L_reporting_date then
      O_error_message := sql_lib.create_msg('INV_INVC_REP_PERIOD', null, null, null);
      return FALSE;
   end if;

   --Check date passed in is greater than last invoice date
    open c_deal_head;
   fetch c_deal_head into L_last_invoice_date;
   close c_deal_head;

   if L_last_invoice_date is not null then
      if I_invoice_date < L_last_invoice_date then
         O_error_message := sql_lib.create_msg('INV_INVC_LAST_DATE', null, null, null);
         return FALSE;
      end if;
   end if;

   --Check the invoice date is after todays date
   if I_invoice_date < get_vdate then
      O_error_message := sql_lib.create_msg('INV_INVC_DATE_VDATE', null, null, null);
      return FALSE;
   end if;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALIDATE_INVOICE_DATE;

-----------------------------------------------------------------------------------------------------------------------------
FUNCTION CALC_NEXT_INVOICE_DATE(O_error_message          IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_next_invoice_date      IN OUT DATE,
                                I_deal_start_date        IN     DATE,
                                I_deal_end_date          IN     DATE,
                                I_billing_period         IN     DEAL_HEAD.BILL_BACK_PERIOD%TYPE,
                                I_current_invoice_date   IN     DATE,
                                I_last_rep_inv_date      IN     DATE DEFAULT NULL)
RETURN BOOLEAN IS
   L_program           VARCHAR2(50) := 'DEAL_FINANCE_SQL.CALC_NEXT_INVOICE_DATE';
BEGIN
   --check for null input parameters
   if I_deal_start_date is null or
      I_deal_end_date is null or
      I_billing_period is null or
      I_current_invoice_date is null then
      O_error_message := sql_lib.create_msg('INV_PARAM_PROG_UNIT', L_program, null, null);
      return FALSE;
   end if;

   --do nothing if the final invoice has been raised already
   if NVL(I_last_rep_inv_date, I_current_invoice_date) >= I_deal_end_date then
      return TRUE;
   end if;
   --initialise O_next_invoice_date
   O_next_invoice_date := NVL(I_last_rep_inv_date, I_current_invoice_date);
   --loop until the new invoice date is greater than vdate
   while O_next_invoice_date < get_vdate LOOP
      --for weekly invoicing add 7 days to current invoice date
      if I_billing_period = 'W' then
         O_next_invoice_date := O_next_invoice_date + 7;
      --for monthly invoicing use oracle function to add months
      elsif I_billing_period = 'M' then
         O_next_invoice_date := add_months(O_next_invoice_date, 1);
      --for quarterly add 3 months
      elsif I_billing_period = 'Q' then
         O_next_invoice_date := add_months(O_next_invoice_date, 3);
      --For half yearly add 6 months
      elsif I_billing_period = 'H' then
         O_next_invoice_date := add_months(O_next_invoice_date, 6);
      --For yearly add 12 months
      elsif I_billing_period = 'A' then
         O_next_invoice_date := add_months(O_next_invoice_date, 12);
      end if;

   end LOOP;
   --adjust for cases where deal end date is earlier than the new invoice date
   if I_billing_period in ('Q', 'H', 'A') then

      if O_next_invoice_date > I_deal_end_date then

         O_next_invoice_date := NVL(I_last_rep_inv_date, I_current_invoice_date);

         while I_deal_end_date > O_next_invoice_date LOOP

            O_next_invoice_date := add_months(O_next_invoice_date, 1);

         end LOOP;
      end if;
   end if;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END CALC_NEXT_INVOICE_DATE;

-----------------------------------------------------------------------------------------------------------------------------
FUNCTION CALC_INITIAL_INVOICE_DATE(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_invoice_date        IN OUT DATE,
                                   I_deal_start_date     IN     DATE,
                                   I_deal_end_date       IN     DATE,
                                   I_billing_period      IN     DEAL_HEAD.BILL_BACK_PERIOD%TYPE)
RETURN BOOLEAN IS
   L_program                  VARCHAR2(50)   := 'DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE';
   L_est_next_invoice_date    DATE;
   L_454_day                  NUMBER(2);
   L_454_month                NUMBER(2);
   L_454_year                 NUMBER(4);
   L_no_of_weeks              NUMBER(2);
   L_end_of_454_q1            DATE;
   L_end_of_454_q2            DATE;
   L_end_of_454_q3            DATE;
   L_end_of_454_q4            DATE;
   L_day                      VARCHAR2(2);
   L_month                    VARCHAR2(2);
   L_year                     VARCHAR2(4);
   L_start_next_year          DATE;
   L_next_year                NUMBER(4);
   L_error_code               VARCHAR2(5);
   cursor C_get_cal is
   select calendar_454_ind
     from system_options;

   c_get_cal_rec              c_get_cal%rowtype;
   cursor c_get_calendar is
   select no_of_weeks, month_454, min(first_day) first_day_of_year
     from calendar
    where year_454 = L_year
    group by no_of_weeks, month_454
    order by month_454;

   TYPE calendar_table  IS TABLE OF c_get_calendar%ROWTYPE INDEX BY BINARY_INTEGER;
   this_years_cal_table             calendar_table;

BEGIN

   --check for null inputs
   if I_deal_start_date is null or
      I_deal_end_date is null or
      I_billing_period is null then
      O_error_message := sql_lib.create_msg('INV_PARAM_PROG_UNIT', L_program, null, null);
      return FALSE;
   end if;

   --check billing period holds a valid value
   if I_billing_period not in ('W', 'M', 'Q', 'H', 'A') then
      O_error_message := sql_lib.create_msg('INV_BILL_PERIOD', null, null, null);
      return FALSE;
   end if;
   --set local variables
   L_day       := to_number(substr(to_char(I_deal_start_date, 'DDMMYYYY'), 1, 2));
   L_month     := to_number(substr(to_char(I_deal_start_date, 'DDMMYYYY'), 3, 2));
   L_year      := to_number(substr(to_char(I_deal_start_date, 'DDMMYYYY'), 5, 4));
   L_next_year := L_year + 1;
   --open system options cursor
    open c_get_cal;
   fetch c_get_cal
    into c_get_cal_rec;
   close c_get_cal;

   if c_get_cal_rec.calendar_454_ind = '4' then
      --if billing weekly then call function to get last day of the week
      if I_billing_period = 'W' then
         CAL_TO_454_LDOW (L_day,
                          L_month,
                          L_year,
                          L_454_day,
                          L_454_month,
                          L_454_year,
                          L_error_code,
                          O_error_message);

         if L_error_code = 'FALSE' then
            return FALSE;
         end if;
         --put variables together to get out parameter
         O_invoice_date := to_date((L_454_day||'/'||L_454_month||'/'||L_454_year),'DD/MM/RRRR');

      --if billing monthly then call function to get last day of the month
      elsif I_billing_period = 'M' then
         CAL_TO_454_LDOM (L_day,
                          L_month,
                          L_year,
                          L_454_day,
                          L_454_month,
                          L_454_year,
                          L_error_code,
                          O_error_message);

         if L_error_code = 'FALSE' then
            return FALSE;
         end if;

         --put variables together to get out parameter
         O_invoice_date := to_date((L_454_day||'/'||L_454_month||'/'||L_454_year),'DD/MM/RRRR');

      --if billing quarterly, half yearly or anually
      elsif I_billing_period in ('Q', 'H', 'A') then
          --calculate the end of quarters
          open c_get_calendar;
         fetch c_get_calendar BULK COLLECT INTO this_years_cal_table;
         close c_get_calendar;

         L_no_of_weeks := 0;

         for i in 1..12 LOOP
            L_no_of_weeks := L_no_of_weeks + this_years_cal_table(i).no_of_weeks;
             if i = 3 then
                L_end_of_454_q1:=this_years_cal_table(1).first_day_of_year+(L_no_of_weeks*7);
             elsif i = 6 then
                L_end_of_454_q2:=this_years_cal_table(1).first_day_of_year+(L_no_of_weeks*7);
             elsif i = 9 then
                L_end_of_454_q3:=this_years_cal_table(1).first_day_of_year+(L_no_of_weeks*7);
             elsif i = 12 then
                L_end_of_454_q4:=this_years_cal_table(1).first_day_of_year+(L_no_of_weeks*7);
             end if;

         end LOOP;

         --for 'Q' billing evaluate which quarter the deal starts in then
         --assign the out parameter
         if I_billing_period = 'Q' then
            if I_deal_start_date < L_end_of_454_q1 then
               O_invoice_date := L_end_of_454_q1 - 1;
            elsif I_deal_start_date < L_end_of_454_q2 then
               O_invoice_date := L_end_of_454_q2 - 1;
            elsif I_deal_start_date < L_end_of_454_q3 then
               O_invoice_date := L_end_of_454_q3 - 1;
            -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
            elsif I_deal_start_date < L_end_of_454_q4 then
            -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
               O_invoice_date := L_end_of_454_q4 - 1;
            -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
            else
               if ADD_MONTHS_454(O_error_message,
                                 O_invoice_date,
                                 3,
                                 L_end_of_454_q4) = FALSE then
                  return FALSE;
               end if;
               O_invoice_date := O_invoice_date - 1;
            -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
         end if;
         --for 'H' billing then evaluate which half the deal starts in then
         --assign the out parameter
         elsif I_billing_period = 'H' then
            if I_deal_start_date < L_end_of_454_q2 then
               O_invoice_date := L_end_of_454_q2 - 1;
            -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
            elsif I_deal_start_date < L_end_of_454_q4 then
            -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
               O_invoice_date := L_end_of_454_q4 - 1;
            -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
            else
               if ADD_MONTHS_454(O_error_message,
                                 O_invoice_date,
                                 6,
                                 L_end_of_454_q4) = FALSE then
                  return FALSE;
               end if;
               O_invoice_date := O_invoice_date - 1;
            -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
            end if;
         --for 'A' billing then assign out parameter
         -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
         elsif I_deal_start_date < L_end_of_454_q4 then
         -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
            O_invoice_date :=   L_end_of_454_q4 - 1;
         -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
         else
            if ADD_MONTHS_454(O_error_message,
                              O_invoice_date,
                              12,
                              L_end_of_454_q4) = FALSE then
               return FALSE;
            end if;
            O_invoice_date := O_invoice_date - 1;
         -- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
         end if;
      end if;
      --if o_invoice_date from above is greater than the deal end date then
      --need to re-calculate o_invoice_date based on the deal_start_date
	  If I_billing_period not in ('M','W') then
			  if O_invoice_date > I_deal_end_date then
		      		 O_invoice_date := I_deal_start_date;
		         	while O_invoice_date < I_deal_end_date LOOP
		            CAL_TO_454_LDOM (L_day,
		                             L_month,
		                             L_year,
		                             L_454_day,
		                             L_454_month,
		                             L_454_year,
		                             L_error_code,
		                             O_error_message);

		            if L_error_code = 'FALSE' then
		               return FALSE;
		            end if;

		            O_invoice_date := to_date((L_454_day||'/' ||L_454_month||'/' ||L_454_year), 'DD/MM/RRRR');
		            L_month := L_month + 1;
		         end LOOP;
		      end if;
       End if;
   else
      --for GREGORIAN calendar billing period can not be 'W''
      if I_billing_period = 'W' then
         O_error_message := sql_lib.create_msg('INV_BILL_GREG', null, null, null);
         return FALSE;
      end if;
      --for 'M' get last day of the month
      if I_billing_period = 'M' then
         O_invoice_date:= last_day(I_deal_start_date);
      --for 'Q' billing which quarter deal is in and assign out parameter
      elsif I_billing_period = 'Q' then
         if L_month <= 3 then
            O_invoice_date := to_date(('31/03/'||L_year), 'DD/MM/RRRR');
         elsif L_month <= 6 then
            O_invoice_date := to_date(('30/06/'||L_year), 'DD/MM/RRRR');
         elsif L_month <= 9 then
            O_invoice_date := to_date(('30/09/'||L_year), 'DD/MM/RRRR');
         else
            O_invoice_date := to_date(('31/12/'||L_year), 'DD/MM/RRRR');
         end if;
      --for 'H' billing determine which half and then assign out parameter
      elsif I_billing_period = 'H' then
         if L_month <= 6 then
            O_invoice_date := to_date(('30/06/'||L_year), 'DD/MM/RRRR');
         else
            O_invoice_date := to_date(('31/12/'||L_year), 'DD/MM/RRRR');
         end if;
      --for 'A' billing assign out parameter
      else
         O_invoice_date := to_date(('31/12/'||L_year), 'DD/MM/RRRR');
      end if;

      --if o_invoice_date from above is greater than the deal end date then
      --need to re-calculate o_invoice_date based on the deal_start_date
	  If I_billing_period not in ('M','W') then
	      if O_invoice_date > I_deal_end_date then
	         O_invoice_date := I_deal_start_date;
	         while O_invoice_date < I_deal_end_date LOOP
	            O_invoice_date := add_months(O_invoice_date, 1);
	         end LOOP;
	      end if;
      End if;
   end if;

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;

END CALC_INITIAL_INVOICE_DATE;
-----------------------------------------------------------------------------------------------------------------------------
FUNCTION CALC_NEXT_REPORT_DATE(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_next_report_date  IN OUT DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE,
                               I_deal_end_date     IN     DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE,
                               I_billing_period    IN     DEAL_HEAD.BILL_BACK_PERIOD%TYPE,
                               I_last_report_date  IN     DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE)
RETURN BOOLEAN IS
----04-Jun-2009 Tesco HSC/Manikandan Varadhan           Defect#:DefNBS012789   Begin
   L_454_day                  NUMBER(2);
   L_454_week                 NUMBER(2);
   L_454_month                NUMBER(2);
   L_454_year                 NUMBER(4);
   L_no_of_months             NUMBER(2);
   L_day                      VARCHAR2(2);
   L_month                    VARCHAR2(2);
   L_year                     VARCHAR2(4);
   L_error_code               VARCHAR2(5);
----04-Jun-2009 Tesco HSC/Manikandan Varadhan           Defect#:DefNBS012789   End

   L_program           VARCHAR2(50) := 'DEAL_FINANCE_SQL.CALC_NEXT_REPORT_DATE';
----04-Jun-2009 Tesco HSC/Manikandan Varadhan           Defect#:DefNBS012789   Begin
   cursor c_get_cal is
   select calendar_454_ind
     from system_options;
   c_get_cal_rec              c_get_cal%rowtype;
----04-Jun-2009 Tesco HSC/Manikandan Varadhan           Defect#:DefNBS012789  End
BEGIN

   --check for null input parameters
   if I_deal_end_date is null or
      I_billing_period is null then
      O_error_message := sql_lib.create_msg('INV_PARAM_PROG_UNIT', L_program, null, null);
      return FALSE;
   end if;
----04-Jun-2009 Tesco HSC/Manikandan Varadhan           Defect#:DefNBS012789   Begin
----Removed one assignment statement
  	if I_last_report_date >= I_deal_end_date then
      O_next_report_date := null;
      return TRUE;
   end if;
----04-Jun-2009 Tesco HSC/Manikandan Varadhan           Defect#:DefNBS012789   End
   -- for weekly invoicing add 7 days to current invoice date
   if I_billing_period = 'W' then
----04-Jun-2009 Tesco HSC/Manikandan Varadhan           Defect#:DefNBS012789   Begin
-- The existing code has modified

            O_next_report_date := I_last_report_date + 7;
   else
      open c_get_cal;
      fetch c_get_cal    into c_get_cal_rec;
      close c_get_cal;

      if I_billing_period = 'M' then
         L_no_of_months := 1;
      elsif I_billing_period = 'Q' then
         -- for quarterly add 3 months
         L_no_of_months := 3;
      elsif I_billing_period = 'H' then
         -- for half yearly add 6 months
         L_no_of_months := 6;
      elsif I_billing_period = 'A' then
         -- for yearly add 12 months
         L_no_of_months := 12;
      end if;
      if c_get_cal_rec.calendar_454_ind = '4' then -- 454 Calender

         if ADD_MONTHS_454(O_error_message,
                           O_next_report_date,
                           L_no_of_months,
                           I_last_report_date) = FALSE then
            return FALSE;
         end if;
      else
         --for GREGORIAN calendar
         O_next_report_date := add_months(I_last_report_date, L_no_of_months);
      end if;

      -- adjust for cases where deal end date is earlier than the next report date
      if I_billing_period in ('Q','H','A') then
         if O_next_report_date > I_deal_end_date then

            O_next_report_date := I_last_report_date;

            while I_deal_end_date > O_next_report_date LOOP

               if c_get_cal_rec.calendar_454_ind = '4' then -- 454 Calender
                  if ADD_MONTHS_454(O_error_message,
                                    O_next_report_date,
                                    1,
                                    O_next_report_date) = FALSE then
                     return FALSE;
                  end if;
               else
                  O_next_report_date := add_months(O_next_report_date, 1);
               end if;

            end loop;
         end if;   -- End of O_next_report_date > I_deal_end_date
      end if;  -- End of I_billing_period in ('Q','H','A')
   end if; -- End of I_billing_period in ('M','Q','H','A')
----04-Jun-2009 Tesco HSC/Manikandan Varadhan           Defect#:DefNBS012789   End
   return TRUE;


EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END CALC_NEXT_REPORT_DATE;
-----------------------------------------------------------------------------------------------------------------------------
-- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
FUNCTION ADD_MONTHS_454(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_next_report_date  IN OUT DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE,
                        I_no_of_months      IN     NUMBER,
                        I_last_report_date  IN     DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE)
RETURN BOOLEAN IS
   L_454_day                  NUMBER(2);
   L_454_week                 NUMBER(2);
   L_454_week_new             NUMBER(2);
   L_454_month                NUMBER(2);
   L_454_year                 NUMBER(4);
   L_day                      VARCHAR2(2);
   L_month                    VARCHAR2(2);
   L_year                     VARCHAR2(4);
   L_error_code               VARCHAR2(5);
   L_program           VARCHAR2(50) := 'DEAL_FINANCE_SQL.ADD_MONTHS_454';

BEGIN

   --set local variables
   --use report date +1/-1 so that if the EOM date is input, the result will still be an EOM date.
   L_day       := to_number(substr(to_char(I_last_report_date + 1, 'DDMMYYYY'), 1, 2));
   L_month     := to_number(substr(to_char(I_last_report_date + 1, 'DDMMYYYY'), 3, 2));
   L_year      := to_number(substr(to_char(I_last_report_date + 1, 'DDMMYYYY'), 5, 4));
   CAL_TO_454 (L_day,
               L_month,
               L_year,
               L_454_day,
               L_454_week,
               L_454_month,
               L_454_year,
               L_error_code,
               O_error_message);
   --
   L_454_month := L_454_month + I_no_of_months;
   if L_454_month > 12 then
      L_454_month := L_454_month - 12;
      L_454_year  := L_454_year + 1;
   end if;

   -- Finding out no. of weeks in new month/year.
   select no_of_weeks
       into L_454_week_new
       from calendar
       where month_454 = L_454_month
       and year_454 = L_454_year;

   if L_454_week > L_454_week_new then

      L_454_week := L_454_week_new;

   end if;

   C454_TO_CAL (L_454_day,
                L_454_week,
                L_454_month,
                L_454_year,
                L_day,
                L_month,
                L_year,
                L_error_code,
                O_error_message);
   O_next_report_date := to_date((L_day||'/'||L_month||'/'||L_year),'DD/MM/RRRR') - 1;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END ADD_MONTHS_454;
-- Oracle Patch 8596119, 01-Jul-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
-----------------------------------------------------------------------------------------------------------------------------
END DEAL_FINANCE_SQL;
/

