CREATE OR REPLACE PACKAGE BODY DEAL_ACTUAL_FORECAST_SQL AS
-----------------------------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Gour, nitin.gour@in.tesco.com
-- Mod Date   : 06-Jul-2009
-- Mod Ref    : Oracle Patch 8596119. Entire Package body has been replaced under New version 1.1 of this object
-- Mod Details: Entire Package body has been replaced under New version 1.1
-----------------------------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 21-Jul-2009
-- Defect Ref : NBS00014069
-- Desc       : Modify CREATE_TEMLPATE Function
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- Mod By     : Murali Krishnan, murali.natarajan@in.tesco.com
-- Mod Date   : 06-Aug-2009
-- Defect Ref : NBS00014310
-- Desc       : Modify CREATE_TEMLPATE Function so that the deal_actuals_forecast is populated correctly
--              each time the DEAL INCOME button is pressed in dealmain form and undo defect NBS00014069.
-----------------------------------------------------------------------------------------------------------------------------
-- Mod By      : Satish B.N
-- Mod Date    : 10-Sep-2009
-- Mod Ref     : DefNBS013770
-- Mod Details : Added new function TSL_LOCK_DEAL_HEAD
-----------------------------------------------------------------------------------------------------------------------------
-- Mod By      : Chandrachooda, chandrachooda.hirannaiah@in.ibm.com
-- Mod Date    : 03-Sep-2010
-- Mod Ref     : Fix for incident DefNBS019045/PM001199
-- Mod Details : Added new cursor C_GET_DEAL_DETAILS
-----------------------------------------------------------------------------------------------------------------------------
FUNCTION APPLY_TOTAL(O_error_message             IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_deal_id                   IN     DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                     I_deal_detail_id            IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                     I_baseline_turnover         IN     DEAL_ACTUALS_FORECAST.BASELINE_TURNOVER%TYPE,
                     I_budget_turnover           IN     DEAL_ACTUALS_FORECAST.BUDGET_TURNOVER%TYPE,
                     I_actual_forecast_turnover  IN     DEAL_ACTUALS_FORECAST.ACTUAL_FORECAST_TURNOVER%TYPE)
RETURN BOOLEAN IS


   L_program_name                      VARCHAR2(60):= 'DEAL_ACTUALS_FORECAST.APPLY_TOTAL';
   L_baseline_actuals_total            NUMBER      := 0;
   L_budget_actuals_total              NUMBER      := 0;
   L_actual_actuals_total              NUMBER      := 0;
   L_no_of_forecast_period             NUMBER      := 0;
   L_forecast_turnover_total           NUMBER      := 0;
   L_forecast_ratio                    NUMBER      := 0;
   L_new_period_forecast               NUMBER      := 0;
   L_new_baseline_total                NUMBER      := 0;
   L_new_budget_total                  NUMBER      := 0;
   L_new_af_total                      NUMBER      := 0;
   L_old_baseline_total                NUMBER      := 0;
   L_old_budget_total                  NUMBER      := 0;
   L_old_af_total                      NUMBER      := 0;
   L_adjustment                        NUMBER      := 0;
   L_TABLE                             VARCHAR2(30):='DEAL_ACTUALS_FORECAST';
   RECORD_LOCKED                       EXCEPTION;
   PRAGMA                              EXCEPTION_INIT(Record_Locked, -54);

      cursor C_FORECAST_COUNT is
      select count('x')
        from deal_actuals_forecast
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = 'F';

      cursor C_LOCK_DEALS_ACTUALS_FORECAST is
      select 'x'
        from deal_actuals_forecast
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and actual_forecast_ind = 'F';

      cursor C_BASELINE_TOTAL (I_af_ind IN VARCHAR2) is
      select NVL(SUM(baseline_turnover),0)
        from deal_actuals_forecast
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = nvl(I_af_ind, actual_forecast_ind);

      cursor C_BASELINE_ACTUALS_TOTAL is
      select NVL(SUM(baseline_turnover),0)
        from deal_actuals_forecast
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = 'A';

      cursor C_BUDGET_TOTAL (I_af_ind IN VARCHAR2) is
      select NVL(SUM(budget_turnover),0)
        from deal_actuals_forecast
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = nvl(I_af_ind, actual_forecast_ind);

      cursor C_BUDGET_ACTUALS_TOTAL is
      select NVL(SUM(budget_turnover),0)
        from deal_actuals_forecast
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = 'A';

      cursor C_AF_TOTAL (I_af_ind IN VARCHAR2) is
      select NVL(SUM(actual_forecast_turnover),0)
        from deal_actuals_forecast
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = nvl(I_af_ind, actual_forecast_ind);

      cursor C_ACTUAL_ACTUALS_TOTAL is
      select NVL(SUM(actual_forecast_turnover),0)
        from deal_actuals_forecast
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = 'A';

BEGIN

   --check for null inputs
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                             L_program_name,
                                             NULL);
      return FALSE;
   elsif I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_detail_id',
                                             L_program_name,
                                             NULL);
      return FALSE;

   end if;

   open C_FORECAST_COUNT;
   fetch C_FORECAST_COUNT into L_no_of_forecast_period;
   close C_FORECAST_COUNT;

   --if baseline turnover is not null the update table
   if I_baseline_turnover is not NULL and
      L_no_of_forecast_period > 0 then

      open C_BASELINE_TOTAL ('F');
      fetch C_BASELINE_TOTAL into L_old_baseline_total;
      close C_BASELINE_TOTAL;

      open C_BASELINE_ACTUALS_TOTAL;
      fetch C_BASELINE_ACTUALS_TOTAL into L_baseline_actuals_total;
      close C_BASELINE_ACTUALS_TOTAL;

      if L_old_baseline_total = 0 then
         L_new_period_forecast := (I_baseline_turnover - L_baseline_actuals_total) /
                                  L_no_of_forecast_period;
      else
         L_forecast_turnover_total := I_baseline_turnover - L_baseline_actuals_total;
         L_forecast_ratio := L_forecast_turnover_total / L_old_baseline_total;
      end if;

      --get a lock on the table
      open C_LOCK_DEALS_ACTUALS_FORECAST;
      close C_LOCK_DEALS_ACTUALS_FORECAST;

      update deal_actuals_forecast
         set baseline_turnover = DECODE(L_old_baseline_total,
                                                0,L_new_period_forecast,
                                                  (baseline_turnover * L_forecast_ratio))
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = 'F';

      open C_BASELINE_TOTAL (NULL);
      fetch C_BASELINE_TOTAL into L_new_baseline_total;
      close C_BASELINE_TOTAL;

      -- If the total does not equal the summed total then we need to
      -- adjust the last period to ensure they match (this will be caused by
      -- rounding errors during the period updates)
      L_adjustment := L_new_baseline_total - I_baseline_turnover;

      if L_adjustment != 0 then

         -- Calculate the adjustment required (Will work for -ve and +ve)
         update deal_actuals_forecast daf
            set baseline_turnover = baseline_turnover - L_adjustment
          where daf.deal_id             = I_deal_id
            and daf.deal_detail_id      = I_deal_detail_id
            and daf.actual_forecast_ind = 'F'
            and daf.reporting_date      = (select MAX(reporting_date)
                                             from deal_actuals_forecast daf2
                                            where daf2.deal_id             = daf.deal_id
                                              and daf2.actual_forecast_ind = daf.actual_forecast_ind
                                              and daf2.deal_detail_id      = daf.deal_detail_id);
      end if;

   end if;

   --if budget turnover is not null then update the table
   if I_budget_turnover is not NULL and
      L_no_of_forecast_period > 0 then

      open C_BUDGET_TOTAL ('F');
      fetch C_BUDGET_TOTAL into L_old_budget_total;
      close C_BUDGET_TOTAL;

      open C_BUDGET_ACTUALS_TOTAL;
      fetch C_BUDGET_ACTUALS_TOTAL into L_budget_actuals_total;
      close C_BUDGET_ACTUALS_TOTAL;

      if L_old_budget_total = 0 then
         L_new_period_forecast := (I_budget_turnover - L_budget_actuals_total) /
                                  L_no_of_forecast_period;
      else
         L_forecast_turnover_total := I_budget_turnover - L_budget_actuals_total;
         L_forecast_ratio := L_forecast_turnover_total / L_old_budget_total;
      end if;

      --get a lock on the table
      open C_LOCK_DEALS_ACTUALS_FORECAST;
      close C_LOCK_DEALS_ACTUALS_FORECAST;

      update deal_actuals_forecast
         set budget_turnover = DECODE(L_old_budget_total,
                                      0,L_new_period_forecast,
                                      (budget_turnover * L_forecast_ratio))
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = 'F';

      open C_BUDGET_TOTAL (NULL);
      fetch C_BUDGET_TOTAL into L_new_budget_total;
      close C_BUDGET_TOTAL;

      -- If the total does not equal the summed total then we need to
      -- adjust the last period to ensure they match (this will be caused by
      -- rounding errors during the period updates)
      L_adjustment := L_new_budget_total - I_budget_turnover;

      if L_adjustment != 0 then

         -- Calculate the adjustment required (Will work for -ve and +ve)
         UPDATE deal_actuals_forecast daf
            SET budget_turnover = budget_turnover - L_adjustment
          WHERE daf.deal_id             = I_deal_id
            AND daf.deal_detail_id      = I_deal_detail_id
            AND daf.actual_forecast_ind = 'F'
            AND daf.reporting_date      = (SELECT MAX(reporting_date)
                                             FROM deal_actuals_forecast daf2
                                            WHERE daf2.deal_id             = daf.deal_id
                                              AND daf2.actual_forecast_ind = daf.actual_forecast_ind
                                              AND daf2.deal_detail_id      = daf.deal_detail_id);
      end if;

   end if;

   --if actual forecast turnover is not null then update the table
   if I_actual_forecast_turnover is not NULL and
      L_no_of_forecast_period > 0 then

      open C_AF_TOTAL ('F');
      fetch C_AF_TOTAL into L_old_af_total;
      close C_AF_TOTAL;

      open C_ACTUAL_ACTUALS_TOTAL;
      fetch C_ACTUAL_ACTUALS_TOTAL into L_actual_actuals_total;
      close C_ACTUAL_ACTUALS_TOTAL;

      if L_old_af_total = 0 then
         L_new_period_forecast := (I_actual_forecast_turnover - L_actual_actuals_total) /
                                   L_no_of_forecast_period;
      else
         L_forecast_turnover_total := I_actual_forecast_turnover - L_actual_actuals_total;
         L_forecast_ratio := L_forecast_turnover_total / L_old_af_total;
      end if;

      --get a lock on the table
      open C_LOCK_DEALS_ACTUALS_FORECAST;
      close C_LOCK_DEALS_ACTUALS_FORECAST;

      update deal_actuals_forecast
         set actual_forecast_turnover = DECODE(L_old_af_total,
                                               0,L_new_period_forecast,
                                               (actual_forecast_turnover * L_forecast_ratio))
       where deal_id             = I_deal_id
         and deal_detail_id      = I_deal_detail_id
         and actual_forecast_ind = 'F';

      open C_AF_TOTAL (NULL);
      fetch C_AF_TOTAL into L_new_af_total;
      close C_AF_TOTAL;

      -- If the total does not equal the summed total then we need to
      -- adjust the last period to ensure they match (this will be caused by
      -- rounding errors during the period updates)
      L_adjustment := L_new_af_total - I_actual_forecast_turnover;

      if L_adjustment != 0 then

         -- Calculate the adjustment required (Will work for -ve and +ve)
         UPDATE deal_actuals_forecast daf
            SET actual_forecast_turnover = actual_forecast_turnover - L_adjustment
          WHERE daf.deal_id             = I_deal_id
            AND daf.deal_detail_id      = I_deal_detail_id
            AND daf.actual_forecast_ind = 'F'
            AND daf.reporting_date      = (SELECT MAX(reporting_date)
                                             FROM deal_actuals_forecast daf2
                                            WHERE daf2.deal_id             = daf.deal_id
                                              AND daf2.actual_forecast_ind = daf.actual_forecast_ind
                                              AND daf2.deal_detail_id      = daf.deal_detail_id);
      end if;

   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_deal_id),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
      return FALSE;
END APPLY_TOTAL;
-----------------------------------------------------------------------------------------------------------------------------
-- Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date   : 21-Jul-2009
-- Defect Ref : NBS00014069
-- Desc       : Modify CREATE_TEMLPATE Function
-----------------------------------------------------------------------------------------------------------------
FUNCTION CREATE_TEMPLATE(O_error_message        IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         I_deal_id              IN     DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                         I_active_date          IN     DEAL_HEAD.ACTIVE_DATE%TYPE,
                         I_close_date           IN     DEAL_HEAD.CLOSE_DATE%TYPE,
                         I_deal_detail_id       IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                         I_deal_reporting_level IN     DEAL_HEAD.DEAL_REPORTING_LEVEL%TYPE)

RETURN BOOLEAN IS

   L_last_rep_date                      DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE           := NULL;
   L_initial_rep_date                   DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE           := NULL;
   L_next_rep_date                      DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE           := NULL;
   L_calc_rep_date                      DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE           := NULL;
   L_intl_rep_date                      DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE           := NULL;
   L_max_rep_date                       DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE           := NULL;
   L_sec_max_rep_date                       DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE           := NULL;
   L_min_rep_date                       DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE           := NULL;
   L_tot_bud_turnover                   DEAL_ACTUALS_FORECAST.BUDGET_TURNOVER%TYPE          := 0.0;
   L_tot_act_for_turnover               DEAL_ACTUALS_FORECAST.ACTUAL_FORECAST_TURNOVER%TYPE := 0.0;
   L_tot_baseline_turnover              DEAL_ACTUALS_FORECAST.BASELINE_TURNOVER%TYPE        := 0.0;
   L_tot_daf_bud_turnover               DEAL_ACTUALS_FORECAST.BUDGET_TURNOVER%TYPE          := 0.0;
   L_tot_daf_act_for_turnover           DEAL_ACTUALS_FORECAST.ACTUAL_FORECAST_TURNOVER%TYPE := 0.0;
   L_tot_daf_baseline_turnover          DEAL_ACTUALS_FORECAST.BASELINE_TURNOVER%TYPE        := 0.0;
   L_tot_dd_bud_turnover                DEAL_DETAIL.TOTAL_BUDGET_TURNOVER%TYPE              := 0.0;
   L_tot_dd_act_for_turnover            DEAL_DETAIL.TOTAL_ACTUAL_FORECAST_TURNOVER%TYPE     := 0.0;
   L_tot_dd_bud_fixed_ind               DEAL_DETAIL.TOTAL_BUDGET_FIXED_IND%TYPE             := 0.0;
   L_tot_dd_act_fixed_ind               DEAL_DETAIL.TOTAL_ACTUAL_FIXED_IND%TYPE             := 0.0;
   L_old_period_turnover                VARCHAR2(30)                                        :='0.0';
   L_new_period_turnover                VARCHAR2(30)                                        :='0.0';
   L_amt_per_unit                       VARCHAR2(30)                                        :='0.0';
   L_table                              VARCHAR2(30):='DEAL_ACTUALS_FORECAST';
   L_counter                            NUMBER := 0;
   --DefNBS019045/PM001199, 03-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, begin
   L_baseline_turnover									DEAL_ACTUALS_FORECAST.BASELINE_TURNOVER%TYPE 				:= 0.0;
	 L_budget_turnover										DEAL_ACTUALS_FORECAST.BUDGET_TURNOVER%TYPE 					:= 0.0;
	 L_budget_income											DEAL_ACTUALS_FORECAST.BUDGET_INCOME%TYPE 						:= 0.0;
	 L_act_forecast_turnover							DEAL_ACTUALS_FORECAST.ACTUAL_FORECAST_TURNOVER%TYPE := 0.0;
	 L_act_forecast_income								DEAL_ACTUALS_FORECAST.ACTUAL_FORECAST_INCOME%TYPE 	:= 0.0;
   L_act_forecast_trend_turnover				DEAL_ACTUALS_FORECAST.ACTUAL_FORECAST_TREND_TURNOVER%TYPE := 0.0;
   L_act_forecast_trend_income					DEAL_ACTUALS_FORECAST.ACTUAL_FORECAST_TREND_INCOME%TYPE 	:= 0.0;
   L_act_income													DEAL_ACTUALS_FORECAST.ACTUAL_INCOME%TYPE 						:= 0.0;
   --DefNBS019045/PM001199, 03-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, end
   RECORD_LOCKED                        EXCEPTION;
   PRAGMA                               EXCEPTION_INIT(Record_Locked, -54);

   L_program_name     VARCHAR2(50) := 'DEAL_ACTUAL_FORECAST_SQL.CREATE_TEMPLATE';

   cursor C_DEAL_ACTUALS is
      select min(reporting_date),
             max(reporting_date)
        from deal_actuals_forecast
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id;

   cursor C_LOCK_DEAL_ACTUALS_FORECAST is
      select 'x'
        from deal_actuals_forecast
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         for update nowait;

   cursor C_GET_DETAILS is
      select NVL(total_budget_turnover,0.0),
             NVL(total_actual_forecast_turnover,0.0),
             NVL(total_budget_fixed_ind,'N'),
             NVL(total_actual_fixed_ind,'N')
        from deal_detail
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id;

   cursor C_GET_SUM is
      select NVL(SUM(NVL(budget_turnover,0.0)),0.0),
             NVL(SUM(NVL(actual_forecast_turnover,0.0)),0.0),
             NVL(SUM(NVL(baseline_turnover,0.0)),0.0)
        from deal_actuals_forecast
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id;

   cursor C_LOCK_DEAL_DETAIL is
      select 'x'
        from deal_detail
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         for update nowait;

   cursor C_GET_SEC_MAX_REP_DATE is
      select max(reporting_date)
        from deal_actuals_forecast
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         -- Def-NBS00014310,  Murali, Murali.natarajan@in.tesco.com , 06-Aug-2009, Begin
         and reporting_date < I_close_date;
         -- Def-NBS00014310,  Murali, Murali.natarajan@in.tesco.com , 06-Aug-2009, End

   --DefNBS019045/PM001199, 03-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, begin
   cursor C_GET_DEAL_DETAILS is
      select NVL(baseline_turnover,0) baseline_turnover,
             NVL(budget_turnover,0) budget_turnover,
             NVL(budget_income,0) budget_income,
             NVL(actual_forecast_turnover,0) actual_forecast_turnover,
             NVL(actual_forecast_income,0) actual_forecast_income,
             NVL(actual_forecast_trend_turnover,0) actual_forecast_trend_turnover,
             NVL(actual_forecast_trend_income,0) actual_forecast_trend_income,
             NVL(actual_income,0) actual_income
        from deal_actuals_forecast
       where deal_id         = I_deal_id
         and deal_detail_id  = I_deal_detail_id
         and reporting_date  > I_close_date;
   --DefNBS019045/PM001199, 03-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, end
BEGIN

   --check for null inputs
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'Deal_id' ,L_program_name, null);
      return FALSE;
   end if;
   ---
   if I_active_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'Active_date' ,L_program_name, null);
      return FALSE;
   end if;
   ---
   if I_close_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'Close_date' ,L_program_name, null);
      return FALSE;
   end if;
   ---
   if I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'Deal_detail_id' ,L_program_name, null);
      return FALSE;
   end if;
   ---
   if I_deal_reporting_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'Deal_reporting_level' ,L_program_name, null);
      return FALSE;
   end if;
   ---
   --check if deal record already exists

   SQL_LIB.SET_MARK('OPEN',
                    'C_DEAL_ACTUALS',
                    'DEAL_ACTUALS_FORECAST',
                    'DEAL ID: '||to_char(I_deal_id));
   open C_DEAL_ACTUALS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DEAL_ACTUALS',
                    'DEAL_ACTUALS_FORECAST',
                    'DEAL ID: '||to_char(I_deal_id));
   fetch C_DEAL_ACTUALS into L_min_rep_date, L_max_rep_date;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DEAL_ACTUALS',
                    'DEAL_ACTUALS_FORECAST',
                    'DEAL ID: '||to_char(I_deal_id));
   close C_DEAL_ACTUALS;

   --For I_close_date < L_max_rep_date

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_SEC_MAX_REP_DATE',
                    'DEAL_ACTUALS_FORECAST',
                    'DEAL ID: '||to_char(I_deal_id));
   open C_GET_SEC_MAX_REP_DATE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_SEC_MAX_REP_DATE',
                    'DEAL_ACTUALS_FORECAST',
                    'DEAL ID: '||to_char(I_deal_id));
   fetch C_GET_SEC_MAX_REP_DATE into L_sec_max_rep_date;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_SEC_MAX_REP_DATE',
                    'DEAL_ACTUALS_FORECAST',
                    'DEAL ID: '||to_char(I_deal_id));
   close C_GET_SEC_MAX_REP_DATE;

   --if no record exits then create a new inital record
   if L_min_rep_date is NULL then

      --call function to get the first reporting date,
      --this function accounts for gregorian and 454 calendars
      if DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE(O_error_message,
                                                    L_initial_rep_date,
                                                    I_active_date,
                                                    I_close_date,
                                                    I_deal_reporting_level) = FALSE then
         return FALSE;
      end if;

      insert into deal_actuals_forecast (deal_id,
                                         deal_detail_id,
                                         reporting_date,
                                         actual_forecast_ind,
                                         baseline_turnover,
                                         budget_turnover,
                                         budget_income,
                                         actual_forecast_turnover,
                                         actual_forecast_income,
                                         actual_forecast_trend_turnover,
                                         actual_forecast_trend_income,
                                         actual_income)
                                 values (I_deal_id,
                                         I_deal_detail_id,
                                         L_initial_rep_date,
                                         'F',
                                         0,
                                         0,
                                         0,
                                         0,
                                         0,
                                         0,
                                         0,
                                         NULL);

      --create as many template records as possible given the reporting period, deal active and deal close dates
      if I_deal_reporting_level in ( 'Q','H') then
         L_last_rep_date := L_initial_rep_date;
         if DEAL_FINANCE_SQL.ADD_MONTHS_454(O_error_message,
                                            L_calc_rep_date,
                                            1,
                                            L_initial_rep_date) = FALSE then
            return FALSE;
         end if;
      else
         L_last_rep_date := L_initial_rep_date;
         L_calc_rep_date := L_initial_rep_date + 1;
      end if;

      while L_last_rep_date <= I_close_date LOOP
         if L_calc_rep_date > I_close_date then
            L_calc_rep_date := I_close_date - 1;
         end if;
         ---
         --call function again to get the next reporting date,
         --this function accounts for gregorian and 454 calendars

         if DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE(O_error_message,
                                                       L_next_rep_date,
                                                       L_calc_rep_date,
                                                       I_close_date,
                                                       I_deal_reporting_level) = FALSE then
            return FALSE;
         end if;
         --

         if L_last_rep_date = L_next_rep_date then
            Exit;
         end if;
         --
         insert into deal_actuals_forecast (deal_id,
                                            deal_detail_id,
                                            reporting_date,
                                            actual_forecast_ind,
                                            baseline_turnover,
                                            budget_turnover,
                                            budget_income,
                                            actual_forecast_turnover,
                                            actual_forecast_income,
                                            actual_forecast_trend_turnover,
                                            actual_forecast_trend_income,
                                            actual_income)
                                    values (I_deal_id,
                                            I_deal_detail_id,
                                            L_next_rep_date,
                                            'F',
                                            0,
                                            0,
                                            0,
                                            0,
                                            0,
                                            0,
                                            0,
                                            NULL);
         --
         L_last_rep_date := L_next_rep_date;
         --
         if I_deal_reporting_level in ( 'Q','H') then
            if DEAL_FINANCE_SQL.ADD_MONTHS_454(O_error_message,
                                               L_calc_rep_date,
                                               1,
                                               L_next_rep_date) = FALSE then
               return FALSE;
            end if;
         else
            L_calc_rep_date := L_next_rep_date + 1;
         end if;

      end LOOP;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DEAL_ACTUALS_FORECAST',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(I_deal_id));
      open C_LOCK_DEAL_ACTUALS_FORECAST;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DEAL_ACTUALS_FORECAST',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(I_deal_id));
      close C_LOCK_DEAL_ACTUALS_FORECAST;

      if I_active_date > L_min_rep_date then

         delete from deal_actuals_forecast
          where deal_id         = I_deal_id
            and deal_detail_id  = I_deal_detail_id
            and reporting_date  < I_active_date;

      end if;

      if I_active_date < L_min_rep_date then
         if DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE(O_error_message,
                                                       L_initial_rep_date,
                                                       I_active_date,
                                                       L_min_rep_date,
                                                       I_deal_reporting_level) = FALSE then
            return FALSE;
         end if;

         if I_deal_reporting_level in ( 'Q','H') then
            L_last_rep_date := L_initial_rep_date;
            if DEAL_FINANCE_SQL.ADD_MONTHS_454(O_error_message,
                                               L_calc_rep_date,
                                               1,
                                               L_initial_rep_date) = FALSE then
               return FALSE;
            end if;
         else
            L_last_rep_date := L_initial_rep_date;
            L_calc_rep_date := L_initial_rep_date + 1;
         end if;

         while L_last_rep_date <= L_min_rep_date LOOP

            if L_calc_rep_date > L_min_rep_date then
               L_calc_rep_date := L_min_rep_date - 1;
            end if;

            L_counter := L_counter + 1;

            if DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE(O_error_message,
                                                          L_next_rep_date,
                                                          L_calc_rep_date,
                                                          L_min_rep_date,
                                                          I_deal_reporting_level) = FALSE then
               return FALSE;
            end if;
            --
            if L_last_rep_date = L_next_rep_date then
               Exit;
            end if;
            --
            if L_last_rep_date = L_initial_rep_date and L_counter = 1 then
               insert into deal_actuals_forecast (deal_id,
                                                  deal_detail_id,
                                                  reporting_date,
                                                  actual_forecast_ind,
                                                  baseline_turnover,
                                                  budget_turnover,
                                                  budget_income,
                                                  actual_forecast_turnover,
                                                  actual_forecast_income,
                                                  actual_forecast_trend_turnover,
                                                  actual_forecast_trend_income,
                                                  actual_income)
                                          values (I_deal_id,
                                                  I_deal_detail_id,
                                                  L_initial_rep_date,
                                                  'F',
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  NULL);
            end if;
            --
            if L_next_rep_date != L_min_rep_date then
               insert into deal_actuals_forecast (deal_id,
                                                  deal_detail_id,
                                                  reporting_date,
                                                  actual_forecast_ind,
                                                  baseline_turnover,
                                                  budget_turnover,
                                                  budget_income,
                                                  actual_forecast_turnover,
                                                  actual_forecast_income,
                                                  actual_forecast_trend_turnover,
                                                  actual_forecast_trend_income,
                                                  actual_income)
                                          values (I_deal_id,
                                                  I_deal_detail_id,
                                                  L_next_rep_date,
                                                  'F',
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  NULL);
            end if;
            --
            L_last_rep_date := L_next_rep_date;
            --
            if I_deal_reporting_level in ( 'Q','H') then
               if DEAL_FINANCE_SQL.ADD_MONTHS_454(O_error_message,
                                                  L_calc_rep_date,
                                                  1,
                                                  L_next_rep_date) = FALSE then
                  return FALSE;
               end if;
            else
               L_calc_rep_date := L_next_rep_date + 1;
            end if;
         end LOOP;
      end if;

      if I_close_date < L_max_rep_date then

	       --DefNBS019045/PM001199, 03-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, begin
				 SQL_LIB.SET_MARK('OPEN',
				                  'C_GET_DEAL_DETAILS',
				                  'DEAL_ACTUALS_FORECAST',
				                  'DEAL ID: '||to_char(I_deal_id));
				 open C_GET_DEAL_DETAILS;

				 SQL_LIB.SET_MARK('FETCH',
				                  'C_GET_DEAL_DETAILS',
				                  'DEAL_ACTUALS_FORECAST',
				                  'DEAL ID: '||to_char(I_deal_id));

				 fetch C_GET_DEAL_DETAILS into L_baseline_turnover,
				                               L_budget_turnover,
				                               L_budget_income,
				                               L_act_forecast_turnover,
				                               L_act_forecast_income,
				                               L_act_forecast_trend_turnover,
				                               L_act_forecast_trend_income,
				                               L_act_income;

				 SQL_LIB.SET_MARK('CLOSE',
				                  'C_GET_DEAL_DETAILS',
				                   'DEAL_ACTUALS_FORECAST',
				                    'DEAL ID: '||to_char(I_deal_id));
				 close C_GET_DEAL_DETAILS;
	       --DefNBS019045/PM001199, 03-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, end

       delete from deal_actuals_forecast
          where deal_id         = I_deal_id
            and deal_detail_id  = I_deal_detail_id
            and reporting_date  > I_close_date;

         -- Def-NBS00014310,  Murali, Murali.natarajan@in.tesco.com , 06-Aug-2009, Begin
         if L_sec_max_rep_date is null or L_sec_max_rep_date > I_close_date then
            L_sec_max_rep_date := I_close_date -1;
         end if;
         -- Def-NBS00014310,  Murali, Murali.natarajan@in.tesco.com , 06-Aug-2009, End

         if I_deal_reporting_level in ( 'Q','H') then
            if DEAL_FINANCE_SQL.ADD_MONTHS_454(O_error_message,
                                               L_calc_rep_date,
                                               1,
                                               L_sec_max_rep_date) = FALSE then
               return FALSE;
            end if;
         else
            L_calc_rep_date := L_sec_max_rep_date + 1;
         end if;
         if DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE(O_error_message,
                                                       L_next_rep_date,
                                                       L_calc_rep_date,
                                                       I_close_date,
                                                       I_deal_reporting_level) = FALSE then
            return FALSE;
         end if;

         insert into deal_actuals_forecast (deal_id,
                                            deal_detail_id,
                                            reporting_date,
                                            actual_forecast_ind,
                                            baseline_turnover,
                                            budget_turnover,
                                            budget_income,
                                            actual_forecast_turnover,
                                            actual_forecast_income,
                                            actual_forecast_trend_turnover,
                                            actual_forecast_trend_income,
                                            actual_income)
                                    values (I_deal_id,
                                            I_deal_detail_id,
                                            L_next_rep_date,
                                            'F',
                                            --DefNBS019045/PM001199, 03-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, begin
                                            --0,
                                            --0,
                                            --0,
                                            --0,
                                            --0,
                                            --0,
                                            --0,
                                            --NULL
                                            L_baseline_turnover,
                                            L_budget_turnover,
                                            L_budget_income,
                                            L_act_forecast_turnover,
                                            L_act_forecast_income,
                                            L_act_forecast_trend_turnover,
                                            L_act_forecast_trend_income,
                                            L_act_income);
                                            --DefNBS019045/PM001199, 03-Sep-2010, chandrachooda.hirannaiah@in.tesco.com, end
      else
         delete from deal_actuals_forecast
          where deal_id         = I_deal_id
            and deal_detail_id  = I_deal_detail_id
            and reporting_date  = L_max_rep_date;

         if DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE(O_error_message,
                                                       L_intl_rep_date,
                                                       L_max_rep_date,
                                                       I_close_date,
                                                       I_deal_reporting_level) = FALSE then
            return FALSE;
         end if;

         insert into deal_actuals_forecast (deal_id,
                                            deal_detail_id,
                                            reporting_date,
                                            actual_forecast_ind,
                                            baseline_turnover,
                                            budget_turnover,
                                            budget_income,
                                            actual_forecast_turnover,
                                            actual_forecast_income,
                                            actual_forecast_trend_turnover,
                                            actual_forecast_trend_income,
                                            actual_income)
                                    values (I_deal_id,
                                            I_deal_detail_id,
                                            L_intl_rep_date,
                                            'F',
                                            0,
                                            0,
                                            0,
                                            0,
                                            0,
                                            0,
                                            0,
                                            NULL);

         if I_deal_reporting_level in ( 'Q','H') then
            L_last_rep_date := L_intl_rep_date;
            if DEAL_FINANCE_SQL.ADD_MONTHS_454(O_error_message,
                                               L_calc_rep_date,
                                               1,
                                               L_intl_rep_date) = FALSE then
               return FALSE;
            end if;
         else
            L_last_rep_date := L_intl_rep_date;
            L_calc_rep_date := L_intl_rep_date + 1;
         end if;

         while L_last_rep_date <= I_close_date LOOP
            if L_calc_rep_date > I_close_date then
               L_calc_rep_date := I_close_date - 1;
            end if;

            if DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE(O_error_message,
                                                          L_next_rep_date,
                                                          L_calc_rep_date,
                                                          I_close_date,
                                                          I_deal_reporting_level) = FALSE then
               return FALSE;
            end if;
            --
            if L_last_rep_date = L_next_rep_date then
               Exit;
            end if;
            --
            insert into deal_actuals_forecast (deal_id,
                                               deal_detail_id,
                                               reporting_date,
                                               actual_forecast_ind,
                                               baseline_turnover,
                                               budget_turnover,
                                               budget_income,
                                               actual_forecast_turnover,
                                               actual_forecast_income,
                                               actual_forecast_trend_turnover,
                                               actual_forecast_trend_income,
                                               actual_income)
                                       values (I_deal_id,
                                               I_deal_detail_id,
                                               L_next_rep_date,
                                               'F',
                                               0,
                                               0,
                                               0,
                                               0,
                                               0,
                                               0,
                                               0,
                                               NULL);
            --
            L_last_rep_date := L_next_rep_date;
            --
            if I_deal_reporting_level in ( 'Q','H') then
               if DEAL_FINANCE_SQL.ADD_MONTHS_454(O_error_message,
                                                  L_calc_rep_date,
                                                  1,
                                                  L_next_rep_date) = FALSE then
                  return FALSE;
               end if;
            else
               L_calc_rep_date := L_next_rep_date + 1;
            end if;
         end LOOP;
      end if;
   end if;

   /* Update the budget turnover, actual forecast turnover, total budget turnover,  */
   /* and total actual forecast turnover accordingly from the changes in periods.   */
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_DETAILS',
                    'DEAL_DETAIL',
                    'deal id: '||to_char(I_deal_id)||', deal detail id: '||to_char(I_deal_detail_id));
   open C_GET_DETAILS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_DETAILS',
                    'DEAL_DETAIL',
                    'deal id: '||to_char(I_deal_id)||', deal detail id: '||to_char(I_deal_detail_id));
   fetch C_GET_DETAILS into L_tot_dd_bud_turnover,
                            L_tot_dd_act_for_turnover,
                            L_tot_dd_bud_fixed_ind,
                            L_tot_dd_act_fixed_ind;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_DETAILS',
                    'DEAL_DETAIL',
                    'deal id: '||to_char(I_deal_id)||', deal detail id: '||to_char(I_deal_detail_id));
   close C_GET_DETAILS;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_SUM',
                    'DEAL_DETAIL',
                    'deal id: '||to_char(I_deal_id)||', deal detail id: '||to_char(I_deal_detail_id));
   open C_GET_SUM;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_SUM',
                    'DEAL_DETAIL',
                    'deal id: '||to_char(I_deal_id)||', deal detail id: '||to_char(I_deal_detail_id));
   fetch C_GET_SUM into L_tot_daf_bud_turnover,
                        L_tot_daf_act_for_turnover,
                        L_tot_daf_baseline_turnover;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_SUM',
                    'DEAL_DETAIL',
                    'deal id: '||to_char(I_deal_id)||', deal detail id: '||to_char(I_deal_detail_id));
   close C_GET_SUM;

   if L_tot_dd_bud_fixed_ind = 'Y' then
      L_tot_bud_turnover := L_tot_dd_bud_turnover;
   else
      L_tot_bud_turnover := L_tot_daf_bud_turnover;
   end if;

   if L_tot_dd_act_fixed_ind = 'Y' then
      L_tot_act_for_turnover := L_tot_dd_act_for_turnover;
   else
      L_tot_act_for_turnover := L_tot_daf_act_for_turnover;
   end if;

   if DEAL_ACTUAL_FORECAST_SQL.APPLY_TOTAL(O_error_message,
                                           I_deal_id,
                                           I_deal_detail_id,
                                           L_tot_daf_baseline_turnover,
                                           L_tot_bud_turnover,
                                           L_tot_act_for_turnover) = FALSE then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_DETAIL',
                    'DEAL_DETAIL',
                    'deal id: '||to_char(I_deal_id)||', deal detail id: '||to_char(I_deal_detail_id));
   open C_LOCK_DEAL_DETAIL;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_DETAIL',
                    'DEAL_DETAIL',
                    'deal id: '||to_char(I_deal_id)||', deal detail id: '||to_char(I_deal_detail_id));
   close C_LOCK_DEAL_DETAIL;

   update deal_detail
      set total_budget_turnover          = L_tot_bud_turnover,
          total_actual_forecast_turnover = L_tot_act_for_turnover
    where deal_id = I_deal_id
      and deal_detail_id = I_deal_detail_id;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_deal_id,
                                            NULL);
      --10-Sep-2009 Tesco HSC/Satish B.N DefNBS013770 Begin
      return FALSE;
      --10-Sep-2009 Tesco HSC/Satish B.N DefNBS013770 End
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
   return FALSE;

END CREATE_TEMPLATE;
---------------------------------------------------------------------------------------------
FUNCTION GET_ATTRIB(O_error_message                 IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                    O_exists                        IN OUT BOOLEAN,
                    O_deal_actuals_forecast_rec     IN OUT DEAL_ACTUALS_FORECAST%ROWTYPE,
                    I_deal_id                       IN DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                    I_deal_detail_id                IN DEAL_ACTUALS_FORECAST.DEAL_DETAIL_ID%TYPE,
                    I_reporting_date                IN DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE)

RETURN BOOLEAN IS

   L_program VARCHAR2(50):='DEAL_ACTUALS_FORECAST_SQL.GET_ATTRIB';
   cursor C_DEAL_ACTUALS_FORECAST is
      select *
        from deal_actuals_forecast
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and reporting_date = I_reporting_date;
BEGIN

   O_exists:=FALSE;
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_detail_id',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_reporting_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_reporting_date',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   Open C_DEAL_ACTUALS_FORECAST;
   fetch C_DEAL_ACTUALS_FORECAST into O_deal_actuals_forecast_rec;
   close C_DEAL_ACTUALS_FORECAST;

   if O_deal_actuals_forecast_rec.deal_id is not NULL then
      O_exists:= TRUE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
   O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
   return FALSE;
END GET_ATTRIB;
----------------------------------------------------------------------------------------------------------------
FUNCTION DELETE_RECORD(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       I_deal_id         IN DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                       I_deal_detail_id  IN DEAL_ACTUALS_FORECAST.DEAL_DETAIL_ID%TYPE DEFAULT NULL)

RETURN BOOLEAN IS

   L_program      VARCHAR2(40):='DEAL_ACTUALS_FORECAST_SQL.DELETE_RECORD';
   L_table        VARCHAR2(30):='DEAL_ACTUALS_FORECAST';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked,-54);
   cursor C_LOCK_DEAL_ACTUALS_FORECAST is
      select 'x'
        from deal_actuals_forecast
       where deal_id = I_deal_id
         and deal_detail_id = nvl(I_deal_detail_id, deal_detail_id)
         for update nowait;

   cursor C_LOCK_DEAL_ACTUALS_ITEM_LOC is
      select 'x'
        from deal_actuals_item_loc
       where deal_id = I_deal_id
         and deal_detail_id = nvl(I_deal_detail_id, deal_detail_id)
         for update nowait;

BEGIN

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            L_program,
                                            NULL);

      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_ACTUALS_ITEM_LOC','DEAL_ACTUALS_ITEM_LOC','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_ACTUALS_ITEM_LOC;

   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_ACTUALS_ITEM_LOC','DEAL_ACTUALS_ITEM_LOC','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_ACTUALS_ITEM_LOC;
   SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_ACTUALS_ITEM_LOC','DEAL ID: '||TO_CHAR(I_deal_id));
   delete from deal_actuals_item_loc
    where deal_id = I_deal_id;

   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_ACTUALS_FORECAST','DEAL_ACTUALS_FORECAST','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_ACTUALS_FORECAST;

   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_ACTUALS_FORECAST','DEAL_ACTUALS_FORECAST','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_ACTUALS_FORECAST;
   SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_ACTUALS_FORECAST','DEAL ID: '||TO_CHAR(I_deal_id));
   delete from deal_actuals_forecast
    where deal_id = I_deal_id;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
   O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                         L_table,
                                         I_deal_id,
                                         NULL);

   --10-Sep-2009 Tesco HSC/Satish B.N DefNBS013770 Begin
   return FALSE;
   --10-Sep-2009 Tesco HSC/Satish B.N DefNBS013770 End
   when OTHERS then
   O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                          SQLERRM,
                                          L_program,
                                          to_char(SQLCODE));

   --10-Sep-2009 Tesco HSC/Satish B.N DefNBS013770 Begin
   return FALSE;
   --10-Sep-2009 Tesco HSC/Satish B.N DefNBS013770 End
END DELETE_RECORD;
-------------------------------------------------------------------------------------------------------------------
FUNCTION PERC_UPLIFT(O_error_message                 IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_deal_id                       IN DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                     I_deal_detail_id                IN DEAL_ACTUALS_FORECAST.DEAL_DETAIL_ID%TYPE,
                     I_target_baseline_growth_rate   IN NUMBER)

RETURN BOOLEAN IS

   L_table                                            VARCHAR2(30):='DEAL_ACTUALS_FORECAST';
   L_program                                          VARCHAR2(40):='DEAL_ACTUALS_FORECAST_SQL.PERC_UPLIFT';
   RECORD_LOCKED                                      EXCEPTION;
   PRAGMA                                             EXCEPTION_INIT(Record_Locked,-54);
   cursor C_LOCK_DEAL_ACTUALS_FORECAST is
      select 'x'
        from deal_actuals_forecast
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id
         for update nowait;

BEGIN
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_Deal_Id',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_detail_id',
                                            L_program,
                                            NULL);
      return FALSE;
     elsif I_target_baseline_growth_rate is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_Target_baseline_growth_rate',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   open C_LOCK_DEAL_ACTUALS_FORECAST;
   close C_LOCK_DEAL_ACTUALS_FORECAST;

   update deal_actuals_forecast
      set budget_turnover = baseline_turnover*(1+(i_target_baseline_growth_rate / 100))
    where deal_id         = I_deal_id
      and deal_detail_id  = I_deal_detail_id;


   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
   O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                         L_table,
                                         I_deal_id,
                                         NULL);
   return FALSE;

   when OTHERS then
   O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                          SQLERRM,
                                          L_program,
                                          to_char(SQLCODE));
   return False;
END PERC_UPLIFT;
----------------------------------------------------------------------------------------------------------------------
FUNCTION COPY_BUDGET(O_error_message                 IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_deal_id                       IN DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                     I_deal_detail_id                IN DEAL_ACTUALS_FORECAST.DEAL_DETAIL_ID%TYPE)

RETURN BOOLEAN IS

   L_program                                        VARCHAR2(40):='DEAL_ACTUALS_FORECAST_SQL.COPY_BUDGET';
   L_table                                          VARCHAR2(30):='DEAL_ACTUALS_FORECAST';

   RECORD_LOCKED                                    EXCEPTION;
   PRAGMA                                           EXCEPTION_INIT(Record_Locked,-54);

   cursor C_LOCK_DEAL_ACTUALS_FORECAST is
      select 'x'
        from deal_actuals_forecast
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         for update nowait;
BEGIN

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_Deal_Id',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_Deal_detail_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   open C_LOCK_DEAL_ACTUALS_FORECAST;
  close C_LOCK_DEAL_ACTUALS_FORECAST;

   update deal_actuals_forecast
      set actual_forecast_turnover = budget_turnover,
          actual_forecast_income   = budget_income
    where deal_id                  = I_deal_id
      and deal_detail_id           = I_deal_detail_id;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
   O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                         L_table,
                                         I_deal_id,
                                         NULL);
   return FALSE;
   when OTHERS then
   O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                         SQLERRM,
                                         L_program,
                                         to_char(SQLCODE));
   return FALSE;
END COPY_BUDGET;
-------------------------------------------------------------------------------------------------------------------
FUNCTION ACTUALS_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_exists        IN OUT BOOLEAN,
                       I_deal_id       IN DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE)

RETURN BOOLEAN IS

   L_program   VARCHAR2(50):='DEAL_ACTUALS_FORECAST_SQL.ACTUALS_EXIST';

   L_found     VARCHAR2(1) := 'N';
   cursor C_DEAL_ACTUALS_EXIST is
      select 'Y'
        from deal_actuals_forecast
       where deal_id = I_deal_id
         and actual_forecast_ind = 'A'
         and rownum = 1;

BEGIN

   O_exists := FALSE;

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            L_program,
                                            NULL);
      return FALSE;

   end if;

   Open C_DEAL_ACTUALS_EXIST;
   fetch C_DEAL_ACTUALS_EXIST into L_found;
   close C_DEAL_ACTUALS_EXIST;

   if L_found = 'Y' then
      O_exists:= TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
   O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
   return FALSE;
END ACTUALS_EXIST;
-------------------------------------------------------------------------------------------------------------------
FUNCTION GET_ACTUALS_TOTAL(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_total          IN OUT NUMBER,
                           I_deal_id        IN DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                           I_deal_detail_id IN DEAL_ACTUALS_FORECAST.DEAL_DETAIL_ID%TYPE)

RETURN BOOLEAN IS

   L_program   VARCHAR2(50):='DEAL_ACTUALS_FORECAST_SQL.GET_ACTUALS_TOTAL';

   cursor C_DEAL_ACTUALS_FORECAST is
      select actual_forecast_turnover
        from deal_actuals_forecast
       where deal_id = I_deal_id
         and actual_forecast_ind = 'A'
         and deal_detail_id = I_deal_detail_id;

BEGIN

   O_total := 0;

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            L_program,
                                            NULL);
      return FALSE;

   end if;

   if I_deal_detail_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                               'I_deal_id',
                                               L_program,
                                               NULL);
         return FALSE;

   end if;

   for rec in C_DEAL_ACTUALS_FORECAST LOOP
      O_total := nvl(O_total, 0) + nvl(rec.actual_forecast_turnover, 0);

   end LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
   O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
   return FALSE;
END GET_ACTUALS_TOTAL;
-------------------------------------------------------------------------------------------------------------------
FUNCTION TSL_LOCK_DEAL_HEAD(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            I_deal_id         IN    DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DEAL_ACTUAL_FORECAST_SQL.TSL_LOCK_DEAL_HEAD';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   CURSOR C_LOCK_DEAL_HEAD IS
      select 'x'
        from deal_head
       where deal_id = I_deal_id
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_DEAL_HEAD', 'DEAL_HEAD','deal_id: '||I_deal_id);
   open C_LOCK_DEAL_HEAD ;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_DEAL_HEAD', 'DEAL_HEAD','deal_id: '||I_deal_id);
   close C_LOCK_DEAL_HEAD;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'DEAL_HEAD',
                                            I_deal_id,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END TSL_LOCK_DEAL_HEAD;
-------------------------------------------------------------------------------------------------------------------
END DEAL_ACTUAL_FORECAST_SQL;
/

