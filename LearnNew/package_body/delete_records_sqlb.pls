CREATE OR REPLACE PACKAGE BODY DELETE_RECORDS_SQL AS
----------------------------------------------------------------------------------------
-- Mod By        : Satish BN, satish.narasimhaiah@in.tesco.com
-- Mod Date      : 19-Jun-2007
-- Mod Ref       : Mod number. N21
-- Mod Details   : Modified function DEL_WH
-- Purpose:      : To delete supply chain attribute information.
----------------------------------------------------------------------------------------
--Defect NBS00004516 by bahubali.dongare@in.tesco.com
--Date: 26-Dec-07
--Changes: Changed the order of deletion of preferred packs and distibution groups associated
--with the deletion of Warehouses. Changes done in N21 Mod changes
----------------------------------------------------------------------------------------
-- Mod By        : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date      : 17-Oct-2008
-- Mod Ref       : CR162
-- Mod Details   : Modified function DEL_WH as per the new data model of supply chain
--                 attributes.
----------------------------------------------------------------------------------------
-- Defect Id : NBS00009074
-- Fixed By  : Usha Patil, usha.patil@in.tesco.com
-- Date      : 07-Oct-2008
-- Details   : Added return TRUE statement in DEL_DEAL and DEL_FIXED_DEAL functions
----------------------------------------------------------------------------------------
-- Mod By        : Raghuveer P R
-- Mod Date      : 21-Jan-2009
-- Mod Ref       : MrgNBS010972
-- Mod Details   : 3.3a to 3.3b merge
----------------------------------------------------------------------------------------
-- Defect Id  : NBS00004273
-- Fixed By   : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date       : 11-June-2009
-- Details    : Applied Oracle Patch 6909054(SR 6608713.993)
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Defect Id  : NBS00015887
-- Fixed By   : Nikhil Narang, nikhil.narang@in.tesco.com
-- Date       : 30-Dec-2009
-- Details    : Applied Oracle Patch 8484139.Added delete statement in the DEL_DEAL function
--              to delete records from DEAL_ITEM_LOC_EXPLODE when the deal is closed.
----------------------------------------------------------------------------------------
-- Mod By        : Sarayu Gouda
-- Mod Date      : 01-Feb-2010
-- Mod Ref       : MrgNBS016138
-- Mod Details   : PrdDi (Production branch) to 3.5b branches
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Mod By      : Nandini M, Nandini.Mariyappa@in.tesco.com
-- Mod Date    : 02-Mar-2010
-- Def Ref     : NBS00016468
-- Def Detail  : Modified the function DEL_SUBCLASS to delete the record from the table
--               tsl_sbcls_statmrgn_temp whenever the subclass is deleted.
----------------------------------------------------------------------------------------
-- Mod By      : Sriranjitha Bhagi,Sriranjitha.Bhagi@in.tesco.com
-- Mod Date    : 24-Sep-2012
-- Def Ref     : NBS00025392
-- Def Detail  : Modified the function DEL_DEAL to delete the record from the table
--               DEAL_COMP_PROM
----------------------------------------------------------------------------------------
-- Mod By      : Basanta Swain,Basanta Swain@in.tesco.com
-- Mod Date    : 31-Aug-2013
-- Def Ref     : NBS00026256
-- Def Detail  : Modified the function DEL_FIXED_DEAL to delete the record from the table
--               TSL_FIXED_DEAL_EX
----------------------------------------------------------------------------------------
-- Mod By      : Usha Patil, usha.patil@in.tesco.com
-- Mod Date    : 04-Apr-2014
-- Def Ref     : NBS00026954
-- Def Detail  : Modified the function DEL_SUBCLASS to delete the record from the table
--               TSL_MIN_PRICE_RULES
----------------------------------------------------------------------------------------
RECORD_LOCKED   EXCEPTION;
PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
LP_table        VARCHAR2(50);

FUNCTION DEL_DEPS(I_key_value       IN       VARCHAR2,
                  O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(50)   := 'DELETE_RECORDS_SQL.DEL_DEPS';
   L_dept        DEPS.DEPT%TYPE;
   L_domain_id   DOMAIN_DEPT.DOMAIN_ID%TYPE;


   cursor C_LOCK_MONTH_DATA_BUDGET is
      select 'x'
        from month_data_budget
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_HALF_DATA_BUDGET is
      select 'x'
        from half_data_budget
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_VAT_DEPS is
      select 'x'
        from vat_deps
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_UDA_ITEM_DEFAULTS is
      select 'x'
        from uda_item_defaults
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_SKULIST_CRITERIA is
      select 'x'
        from skulist_criteria
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_STORE_DEPT_AREA is
      select 'x'
        from store_dept_area
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_DOMAIN_DEPT is
      select domain_id
        from domain_dept
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_FORECAST_REBUILD is
      select 'x'
        from forecast_rebuild
       where exists (select domain_level
                       from system_options
                      where domain_level = 'D')
         and domain_id = L_domain_id
         and not exists (select 'x'
                           from domain_dept
                          where domain_id = L_domain_id)
         for update nowait;

   cursor C_LOCK_SUP_DATA is
      select 'x'
        from sup_data
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_SUP_MONTH is
      select 'x'
        from sup_month
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_DEPT_SALES_HIST is
      select 'x'
        from dept_sales_hist
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_DEPT_SALES_FORECAST is
      select 'x'
        from dept_sales_forecast
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
        from deal_itemloc
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_DEPS is
      select 'x'
        from deps
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_DAILY_PURGE is
      select 'x'
        from daily_purge
       where key_value = I_key_value
         and table_name = 'DEPS'
         for update nowait;

   cursor C_LOCK_STOCK_LEDGER_INSERTS is
      select 'x'
        from stock_ledger_inserts
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_STAKE_SCHEDULE is
      select 'x'
        from stake_schedule
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_PRODUCT_TAX_CODE is
      select 'x'
        from product_tax_code
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_WH_DEPT is
      select 'x'
        from wh_dept
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_CHRG_DETAIL is
      select 'x'
        from dept_chrg_detail
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_CHRG_HEAD is
      select 'x'
        from dept_chrg_head
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_SUP_BRACKET_COST is
      select 'x'
        from sup_bracket_cost
       where dept = L_dept
         for update nowait;

   cursor C_LOCK_SUP_REPL_DAY is
      select 'x'
      from sup_repl_day
     where sup_dept_seq_no in (select sup_dept_seq_no
                                 from sup_inv_mgmt
                                where dept = L_dept);

   cursor C_LOCK_SUP_INV_MGMT is
      select 'x'
        from sup_inv_mgmt
       where dept = L_dept
         for update nowait;

BEGIN
   L_dept := to_number(I_key_value);
   ---
   LP_table := 'STAKE_SCHEDULE';

   open C_LOCK_STAKE_SCHEDULE;
   close C_LOCK_STAKE_SCHEDULE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STAKE_SCHEDULE','DEPT: '||I_key_value);

   delete from stake_schedule
    where dept = L_dept;
   ---
   ---
   LP_table  := 'STOCK_LEDGER_INSERTS';

   open C_LOCK_STOCK_LEDGER_INSERTS;
   close C_LOCK_STOCK_LEDGER_INSERTS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STOCK_LEDGER_INSERTS',
                    'DEPT: '|| I_key_value);

   delete from STOCK_LEDGER_INSERTS
      where dept = L_dept;
   ---
   LP_table  := 'MONTH_DATA_BUDGET';

   open  C_LOCK_MONTH_DATA_BUDGET;
   close C_LOCK_MONTH_DATA_BUDGET;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'MONTH_DATA_BUDGET',
                    'DEPT: '||I_key_value);

   delete from MONTH_DATA_BUDGET
      where dept = L_dept;
   ---
   LP_table  := 'HALF_DATA_BUDGET';

   open C_LOCK_HALF_DATA_BUDGET;
   close C_LOCK_HALF_DATA_BUDGET;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'HALF_DATA_BUDGET',
                    'DEPT: '||I_key_value);

   delete from HALF_DATA_BUDGET
      where dept = L_dept;
   ---
   LP_table  := 'VAT_DEPS';

   open  C_LOCK_VAT_DEPS;
   close C_LOCK_VAT_DEPS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'VAT_DEPS',
                    'DEPT: '||I_key_value);

   delete from VAT_DEPS
      where dept = L_dept;
   ---
   LP_table  := 'UDA_ITEM_DEFAULTS';

   open C_LOCK_UDA_ITEM_DEFAULTS;
   close C_LOCK_UDA_ITEM_DEFAULTS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'UDA_ITEM_DEFAULTS',
                    'DEPT: '||I_key_value);

   delete from uda_item_defaults
      where dept = L_dept;
   ---
   LP_table  := 'SKULIST_CRITERIA';

   open C_LOCK_SKULIST_CRITERIA;
   close C_LOCK_SKULIST_CRITERIA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SKULIST_CRITERIA',
                    'DEPT: '||I_key_value);

   delete from skulist_criteria
      where dept = L_dept;
   ---
   LP_table  := 'STORE_DEPT_AREA';

   open C_LOCK_STORE_DEPT_AREA;
   close C_LOCK_STORE_DEPT_AREA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STORE_DEPT_AREA',
                    'DEPT: '||I_key_value);

   delete from store_dept_area
    where dept = L_dept;
   ---
   LP_table := 'DOMAIN_DEPT';

   open  C_LOCK_DOMAIN_DEPT;
   fetch C_LOCK_DOMAIN_DEPT into L_domain_id;
   close C_LOCK_DOMAIN_DEPT;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DOMAIN_DEPT',
                    'DEPT: '||I_key_value);

   delete domain_dept
    where dept = L_dept;
   ---
   LP_table := 'FORECAST_REBUILD';

   open  C_LOCK_FORECAST_REBUILD;
   close C_LOCK_FORECAST_REBUILD;
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'FORECAST_REBUILD',
                    'DEPT: '||I_key_value);

   delete forecast_rebuild
    where exists (select domain_level
                    from system_options
                   where domain_level = 'D')
         and domain_id = L_domain_id
         and not exists (select 'x'
                           from domain_dept
                          where domain_id = L_domain_id);
   ---
   LP_table := 'SUP_DATA';

   open  C_LOCK_SUP_DATA;
   close C_LOCK_SUP_DATA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUP_DATA',
                    'DEPT: '||I_key_value);

   delete sup_data
    where dept = L_dept;
   ---
   LP_table := 'SUP_MONTH';

   open  C_LOCK_SUP_MONTH;
   close C_LOCK_SUP_MONTH;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUP_MONTH',
                    'DEPT: '||I_key_value);

   delete sup_month
    where dept = L_dept;
   ---
   LP_table := 'DEPT_SALES_HIST';

   open  C_LOCK_DEPT_SALES_HIST;
   close C_LOCK_DEPT_SALES_HIST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEPT_SALES_HIST',
                    'DEPT: '||I_key_value);

   delete dept_sales_hist
    where dept = L_dept;
   ---
   LP_table := 'DEPT_SALES_FORECAST';

   open  C_LOCK_DEPT_SALES_FORECAST;
   close C_LOCK_DEPT_SALES_FORECAST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEPT_SALES_FORECAST',
                    'DEPT: '||I_key_value);

   delete dept_sales_forecast
    where dept = L_dept;
   ---
   LP_table  := 'DEAL_ITEMLOC';

   open  C_LOCK_DEAL_ITEMLOC;
   close C_LOCK_DEAL_ITEMLOC;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEAL_ITEMLOC',
                    'KEY_VALUE: '||I_key_value);

   delete from deal_itemloc
    where dept = L_dept;
   ---
   LP_table := 'PRODUCT_TAX_CODE';

   open  C_LOCK_PRODUCT_TAX_CODE;
   close C_LOCK_PRODUCT_TAX_CODE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'PRODUCT_TAX_CODE',
                    'DEPT: '||I_key_value);

   delete from PRODUCT_TAX_CODE
    where dept = L_dept;
   ---
   LP_table := 'WH_DEPT';

   open  C_LOCK_WH_DEPT;
   close C_LOCK_WH_DEPT;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'WH_DEPT',
                    'DEPT: '||I_key_value);

   delete from WH_DEPT
    where dept = L_dept;
   ---
   LP_table := 'DEPT_CHRG_DETAIL';

   open  C_LOCK_CHRG_DETAIL;
   close C_LOCK_CHRG_DETAIL;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEPT_CHRG_DETAIL',
                    'DEPT: '||I_key_value);

   delete from DEPT_CHRG_DETAIL
    where dept = L_dept;
   ---
   LP_table := 'DEPT_CHRG_HEAD';

   open  C_LOCK_CHRG_HEAD;
   close C_LOCK_CHRG_HEAD;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEPT_CHRG_HEAD',
                    'DEPT: '||I_key_value);

   delete from DEPT_CHRG_HEAD
    where dept = L_dept;
   ---
   LP_table := 'SUP_BRACKET_COST';

   open  C_LOCK_SUP_BRACKET_COST;
   close C_LOCK_SUP_BRACKET_COST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUP_BRACKET_COST',
                    'DEPT: '||I_key_value);

   delete from SUP_BRACKET_COST
    where dept = L_dept;
   ---
   LP_table := 'SUP_REPL_DAY';

   open  C_LOCK_SUP_REPL_DAY;
   close C_LOCK_SUP_REPL_DAY;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUP_REPL_DAY',
                    'DEPT: '||I_key_value);

   delete from SUP_REPL_DAY
    where sup_dept_seq_no in (select sup_dept_seq_no
                                from sup_inv_mgmt
                               where dept = L_dept);

   ---
   LP_table := 'SUP_INV_MGMT';

   open  C_LOCK_SUP_INV_MGMT;
   close C_LOCK_SUP_INV_MGMT;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUP_INV_MGMT',
                    'DEPT: '||I_key_value);

   delete from SUP_INV_MGMT
    where dept = L_dept;

   ---
   LP_table  := 'FILTER_GROUP_MERCH';

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'FILTER_GROUP_MERCH',
                    'DEPT: '||I_key_value);

   if not FILTER_GROUP_HIER_SQL.DELETE_GROUP_MERCH(O_error_message,
                                                   'P',
                                                   L_dept,
                                                   NULL,
                                                   NULL) then
      return FALSE;
   end if;
   ---
   LP_table  := 'DEPS';

   open  C_LOCK_DEPS;
   close C_LOCK_DEPS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEPS',
                    'DEPT: '||I_key_value);

   delete from DEPS
    where dept = L_dept;
   ---
   LP_table  := 'DAILY_PURGE';

   open  C_LOCK_DAILY_PURGE;
   close C_LOCK_DAILY_PURGE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DAILY_PURGE',
                    'KEY_VALUE: '||I_key_value);

   delete from daily_purge
    where key_value = I_key_value
      and table_name = 'DEPS';
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                            LP_table,
                                            I_key_value);
      return FALSE;

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            SQLCODE);
      return FALSE;
END DEL_DEPS;
----------------------------------------------------------------
FUNCTION DEL_CLASS(I_key_value       IN       VARCHAR2,
                   O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(50)   := 'DELETE_RECORDS_SQL.DEL_CLASS';
   L_dept        CLASS.DEPT%TYPE;
   L_class       CLASS.CLASS%TYPE;
   L_domain_id   DOMAIN_CLASS.DOMAIN_ID%TYPE;


   cursor C_LOCK_UDA_ITEM_DEFAULTS is
      select 'x'
        from uda_item_defaults
       where dept  = L_dept
         and class = L_class
         for update nowait;

   cursor C_LOCK_SKULIST_CRITERIA is
      select 'x'
        from skulist_criteria
       where dept  = L_dept
         and class = L_class
         for update nowait;

   cursor C_LOCK_DOMAIN_CLASS is
      select domain_id
        from domain_class
       where dept  = L_dept
         and class = L_class
         for update nowait;

   cursor C_LOCK_FORECAST_REBUILD is
      select 'x'
        from forecast_rebuild
       where exists (select domain_level
                       from system_options
                      where domain_level = 'C')
         and domain_id = L_domain_id
         and not exists (select 'x'
                           from domain_class
                          where domain_id = L_domain_id)
         for update nowait;

   cursor C_LOCK_CLASS_SALES_HIST is
      select 'x'
        from class_sales_hist
       where class = L_class
         for update nowait;

   cursor C_LOCK_CLASS_SALES_FORECAST is
      select 'x'
        from class_sales_forecast
       where class = L_class
         for update nowait;

   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
        from deal_itemloc
       where dept = L_dept
         and class = L_class
         for update nowait;

   cursor C_LOCK_CLASS is
      select 'x'
        from class
       where dept  = L_dept
         and class = L_class
         for update nowait;

   cursor C_LOCK_DAILY_PURGE is
      select 'x'
        from daily_purge
       where key_value  = I_key_value
         and table_name = 'CLASS'
         for update nowait;

   cursor C_LOCK_STOCK_LEDGER_INSERTS is
      select 'x'
        from stock_ledger_inserts
       where dept  = L_dept
         and class = L_class
         for update nowait;

   cursor C_LOCK_STAKE_SCHEDULE is
      select 'x'
        from stake_schedule
       where dept  = L_dept
         and class = L_class
         for update nowait;

BEGIN
   L_dept   := to_number(substr(I_key_value,1,4));
   L_class  := to_number(substr(I_key_value,6,4));
   ---
   LP_table := 'STAKE_SCHEDULE';

   open C_LOCK_STAKE_SCHEDULE;
   close C_LOCK_STAKE_SCHEDULE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STAKE_SCHEDULE',
                    'DEPT, CLASS: '||I_key_value);

   delete from stake_schedule
      where dept  = L_dept
        and class = L_class;
   ---
   LP_table  := 'STOCK_LEDGER_INSERTS';

   open C_LOCK_STOCK_LEDGER_INSERTS;
   close C_LOCK_STOCK_LEDGER_INSERTS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STOCK_LEDGER_INSERTS',
                    'DEPT,CLASS: '|| I_key_value);

   delete from STOCK_LEDGER_INSERTS
      where dept  = L_dept
        and class = L_class;

   ---
   LP_table  := 'UDA_ITEM_DEFAULTS';

   open C_LOCK_UDA_ITEM_DEFAULTS;
   close C_LOCK_UDA_ITEM_DEFAULTS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'UDA_ITEM_DEFAULTS',
                    'DEPT: '||I_key_value);

   delete from uda_item_defaults
     where dept  = L_dept
       and class = L_class;
   ---
   LP_table  := 'SKULIST_CRITERIA';

   open C_LOCK_SKULIST_CRITERIA;
   close C_LOCK_SKULIST_CRITERIA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SKULIST_CRITERIA',
                    'DEPT,CLASS: '||I_key_value);

   delete from skulist_criteria
    where dept  = L_dept
      and class = L_class;
   ---
   LP_table := 'DOMAIN_CLASS';

   open  C_LOCK_DOMAIN_CLASS;
   fetch C_LOCK_DOMAIN_CLASS into L_domain_id;
   close C_LOCK_DOMAIN_CLASS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DOMAIN_CLASS',
                    'DEPT,CLASS: '||I_key_value);

   delete domain_class
    where dept  = L_dept
      and class = L_class;
   ---
   LP_table := 'FORECAST_REBUILD';

   open  C_LOCK_FORECAST_REBUILD;
   close C_LOCK_FORECAST_REBUILD;
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'FORECAST_REBUILD',
                    'DEPT,CLASS: '||I_key_value);

   delete forecast_rebuild
    where exists (select domain_level
                    from system_options
                   where domain_level = 'C')
      and domain_id = L_domain_id
      and not exists (select 'x'
                        from domain_class
                       where domain_id = L_domain_id);
   ---
   LP_table := 'CLASS_SALES_HIST';

   open  C_LOCK_CLASS_SALES_HIST;
   close C_LOCK_CLASS_SALES_HIST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'CLASS_SALES_HIST',
                    'DEPT,CLASS: '||I_key_value);

   delete class_sales_hist
    where dept  = L_dept
      and class = L_class;
   ---
   LP_table := 'CLASS_SALES_FORECAST';

   open  C_LOCK_CLASS_SALES_FORECAST;
   close C_LOCK_CLASS_SALES_FORECAST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'CLASS_SALES_FORECAST',
                    'DEPT,CLASS: '||I_key_value);

   delete class_sales_forecast
    where dept  = L_dept
      and class = L_class;
   ---
   LP_table := 'DEAL_ITEMLOC';

   open  C_LOCK_DEAL_ITEMLOC;
   close C_LOCK_DEAL_ITEMLOC;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEAL_ITEMLOC',
                    'DEPT,CLASS: '||I_key_value);

   delete from deal_itemloc
    where dept  = L_dept
      and class = L_class;
   ---
   LP_table  := 'FILTER_GROUP_MERCH';

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'FILTER_GROUP_MERCH',
                    'DEPT,CLASS: '||I_key_value);

   if not FILTER_GROUP_HIER_SQL.DELETE_GROUP_MERCH(O_error_message,
                                                   'C',
                                                   L_dept,
                                                   L_class,
                                                   NULL) then
      return FALSE;
   end if;
   ---
   LP_table := 'CLASS';

   open  C_LOCK_CLASS;
   close C_LOCK_CLASS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'CLASS',
                    'DEPT,CLASS: '||I_key_value);

   delete from class
    where dept  = L_dept
      and class = L_class;
   ---
   LP_table  := 'DAILY_PURGE';

   open  C_LOCK_DAILY_PURGE;
   close C_LOCK_DAILY_PURGE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DAILY_PURGE',
                    'KEY_VALUE: '||I_key_value);

   delete from daily_purge
    where key_value  = I_key_value
      and table_name = 'CLASS';

   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                            LP_table,
                                            I_key_value);
         return FALSE;

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            SQLCODE);
      return FALSE;

END DEL_CLASS;
---------------------------------------------------------------------
FUNCTION DEL_SUBCLASS(I_key_value       IN       VARCHAR2,
                      O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_dept        SUBCLASS.DEPT%TYPE;
   L_class       SUBCLASS.CLASS%TYPE;
   L_subclass    SUBCLASS.SUBCLASS%TYPE;
   L_domain_id   DOMAIN_SUBCLASS.DOMAIN_ID%TYPE;

   cursor C_LOCK_TRAN_DATA_HISTORY is
      select 'x'
        from tran_data_history
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_DAILY_DATA is
      select 'x'
        from daily_data
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_WEEK_DATA is
      select 'x'
        from week_data
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_MONTH_DATA is
      select 'x'
        from month_data
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_HALF_DATA is
      select 'x'
        from half_data
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_UDA_ITEM_DEFAULTS is
      select 'x'
        from uda_item_defaults
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_SKULIST_CRITERIA is
      select 'x'
        from skulist_criteria
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_DOMAIN_SUBCLASS is
      select domain_id
        from domain_subclass
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_FORECAST_REBUILD is
      select 'x'
        from forecast_rebuild
       where exists (select domain_level
                       from system_options
                      where domain_level = 'S')
         and domain_id = L_domain_id
         and not exists (select 'x'
                           from domain_subclass
                          where domain_id = L_domain_id)
         for update nowait;

   cursor C_LOCK_OTB_FWD_LIMIT is
      select 'x'
        from otb_fwd_limit
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_OTB is
      select 'x'
        from otb
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_DIFF_RATIO_DETAIL is
      select 'x'
        from diff_ratio_detail
       where diff_ratio_id in (select diff_ratio_id
                                 from diff_ratio_head
                                where dept    = L_dept
                                  and class    = L_class
                                  and subclass = L_subclass)
         for update nowait;

   cursor C_LOCK_DIFF_RATIO_HEAD is
      select 'x'
        from diff_ratio_head
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_SUBCLASS_SALES_HIST is
      select 'x'
        from subclass_sales_hist
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_SUBCLASS_SALES_FORECAST is
      select 'x'
        from subclass_sales_forecast
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_EDI_NEW_ITEM is
      select 'x'
        from edi_new_item
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
        from deal_itemloc
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_SUBCLASS is
      select 'x'
        from subclass
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_DAILY_PURGE is
      select 'x'
        from daily_purge
       where key_value  = I_key_value
         and table_name = 'SUBCLASS'
         for update nowait;

   cursor C_LOCK_STOCK_LEDGER_INSERTS is
      select 'x'
        from stock_ledger_inserts
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass
         for update nowait;

   cursor C_LOCK_STAKE_SCHEDULE is
     select 'x'
       from stake_schedule
      where dept     = L_dept
        and class    = L_class
        and subclass = L_subclass
        for update nowait;

   cursor C_LOCK_MERCH_HIER_DEFAULT is
     select 'x'
       from merch_hier_default
      where dept     = L_dept
        and class    = L_class
        and subclass = L_subclass
        for update nowait;
   --02-Mar-2010    TESCO HSC/Nandini M    NBS00016468   Begin
   cursor C_LOCK_TSL_SBCLS_STATMRGN_TEMP is
     select 'x'
       from tsl_sbcls_statmrgn_temp
      where dept     = L_dept
        and class    = L_class
        and subclass = L_subclass
        for update nowait;
   --02-Mar-2010    TESCO HSC/Nandini M    NBS00016468   End

   --04-Apr-2014    TESCO HSC/Usha Patil    NBS00026954   Begin
   cursor C_LOCK_TSL_MIN_PRICE_RULES is
     select 'x'
       from tsl_min_price_rules
      where dept     = L_dept
        and class    = L_class
        and subclass = L_subclass
        for update nowait;
   --04-Apr-2014    TESCO HSC/Usha Patil    NBS00026954   End

BEGIN
   L_dept     := to_number(substr(I_key_value,1,4));
   L_class    := to_number(substr(I_key_value,6,4));
   L_subclass := to_number(substr(I_key_value,11,4));
   ---
   LP_table := 'STAKE_SCHEDULE';

   open C_LOCK_STAKE_SCHEDULE;
   close C_LOCK_STAKE_SCHEDULE;

   SQL_LIB.SET_MARK('DELETE',NULL,'STAKE_SCHEDULE',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from stake_schedule
    where dept     = L_dept
      and class    = L_class
      and subclass = L_subclass;
   ---
   LP_table  := 'STOCK_LEDGER_INSERTS';

   open C_LOCK_STOCK_LEDGER_INSERTS;
   close C_LOCK_STOCK_LEDGER_INSERTS;

   SQL_LIB.SET_MARK('DELETE',NULL,'STOCK_LEDGER_INSERTS',
                    'DEPT,CLASS,SUBCLASS: '|| I_key_value);

   delete from STOCK_LEDGER_INSERTS
      where dept     = L_dept
        and class    = L_class
        and subclass = L_subclass;
   ---
   LP_table := 'TRAN_DATA_HISTORY';

   open  C_LOCK_TRAN_DATA_HISTORY;
   close C_LOCK_TRAN_DATA_HISTORY;

   SQL_LIB.SET_MARK('DELETE',NULL,'TRAN_DATA_HISTORY',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from tran_data_history
    where dept     = L_dept
      and class    = L_class
      and subclass = L_subclass;
   ---
   LP_table := 'DAILY_DATA';

   open  C_LOCK_DAILY_DATA;
   close C_LOCK_DAILY_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_DATA',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from daily_data
    where dept     = L_dept
      AND class    = L_class
      AND subclass = L_subclass;
   ---
   LP_table := 'WEEK_DATA';

   open  C_LOCK_WEEK_DATA;
   close C_LOCK_WEEK_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'WEEK_DATA',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);
   delete from week_data
    where dept     = L_dept
      AND class    = L_class
      AND subclass = L_subclass;
   ---
   LP_table := 'DAILY_DATA';

   open  C_LOCK_MONTH_DATA;
   close C_LOCK_MONTH_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'MONTH_DATA',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from month_data
    where dept     = L_dept
      AND class    = L_class
      AND subclass = L_subclass;
   ---
   LP_table := 'HALF_DATA';

   open  C_LOCK_HALF_DATA;
   close C_LOCK_HALF_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'HALF_DATA',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from half_data
    where dept     = L_dept
      AND class    = L_class
      AND subclass = L_subclass;
   ---
   LP_table  := 'UDA_ITEM_DEFAULTS';

   open C_LOCK_UDA_ITEM_DEFAULTS;
   close C_LOCK_UDA_ITEM_DEFAULTS;

   SQL_LIB.SET_MARK('DELETE',NULL,'UDA_ITEM_DEFAULTS','DEPT: '||I_key_value);

   delete from UDA_ITEM_DEFAULTS
    where dept     = L_dept
      AND class    = L_class
      AND subclass = L_subclass;
   ---
   LP_table  := 'SKULIST_CRITERIA';

   open C_LOCK_SKULIST_CRITERIA;
   close C_LOCK_SKULIST_CRITERIA;

   SQL_LIB.SET_MARK('DELETE',NULL,'SKULIST_CRITERIA','DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from skulist_criteria
    where dept     = L_dept
      and class    = L_class
      and subclass = L_subclass;
   ---
   LP_table := 'DOMAIN_SUBCLASS';

   open  C_LOCK_DOMAIN_SUBCLASS;
   fetch C_LOCK_DOMAIN_SUBCLASS into L_domain_id;
   close C_LOCK_DOMAIN_SUBCLASS;

   SQL_LIB.SET_MARK('DELETE',NULL,'DOMAIN_SUBCLASS',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete domain_subclass
    where dept     = L_dept
      and class    = L_class
      and subclass = L_subclass;
   ---
   LP_table := 'FORECAST_REBUILD';

   open  C_LOCK_FORECAST_REBUILD;
   close C_LOCK_FORECAST_REBUILD;
   SQL_LIB.SET_MARK('DELETE',NULL,'FORECAST_REBUILD',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete forecast_rebuild
    where exists (select domain_level
                    from system_options
                   where domain_level = 'S')
      and domain_id = L_domain_id
      and not exists (select 'x'
                        from domain_subclass
                       where domain_id = L_domain_id);
   ---
   LP_table := 'OTB_FWD_LIMIT';

   open  C_LOCK_OTB_FWD_LIMIT;
   close C_LOCK_OTB_FWD_LIMIT;

   SQL_LIB.SET_MARK('DELETE',NULL,'OTB_FWD_LIMIT',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete otb_fwd_limit
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass;
   ---
   LP_table := 'OTB';

   open  C_LOCK_OTB;
   close C_LOCK_OTB;

   SQL_LIB.SET_MARK('DELETE',NULL,'OTB',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete otb
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass;
   ---
   LP_table := 'DIFF_RATIO_DETAIL';

   open  C_LOCK_DIFF_RATIO_DETAIL;
   close C_LOCK_DIFF_RATIO_DETAIL;

   SQL_LIB.SET_MARK('DELETE',NULL,'DIFF_RATIO_DETAIL',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete diff_ratio_detail
       where diff_ratio_id in (select diff_ratio_id
                                 from diff_ratio_head
                                where dept     = L_dept
                                  and class    = L_class
                                  and subclass = L_subclass);
   ---
   LP_table := 'DIFF_RATIO_HEAD';

   open  C_LOCK_DIFF_RATIO_HEAD;
   close C_LOCK_DIFF_RATIO_HEAD;

   SQL_LIB.SET_MARK('DELETE',NULL,'DIFF_RATIO_HEAD',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete diff_ratio_head
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass;
   ---
   LP_table := 'SUBCLASS_SALES_HIST';

   open  C_LOCK_SUBCLASS_SALES_HIST;
   close C_LOCK_SUBCLASS_SALES_HIST;

   SQL_LIB.SET_MARK('DELETE',NULL,'SUBCLASS_SALES_HIST',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete subclass_sales_hist
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass;
   ---
   LP_table := 'SUBCLASS_SALES_FORECAST';

   open  C_LOCK_SUBCLASS_SALES_FORECAST;
   close C_LOCK_SUBCLASS_SALES_FORECAST;

   SQL_LIB.SET_MARK('DELETE',NULL,'SUBCLASS_SALES_FORECAST',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete subclass_sales_forecast
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass;
   ---
   LP_table := 'EDI_NEW_ITEM';

   open  C_LOCK_EDI_NEW_ITEM;
   close C_LOCK_EDI_NEW_ITEM;

   SQL_LIB.SET_MARK('DELETE',NULL,'EDI_NEW_ITEM',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete edi_new_item
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass;
   ---
   LP_table := 'DEAL_ITEMLOC';

   open  C_LOCK_DEAL_ITEMLOC;
   close C_LOCK_DEAL_ITEMLOC;

   SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_ITEMLOC',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete deal_itemloc
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass;
   ---
   LP_table := 'MERCH_HIER_DEFAULT';

   open  C_LOCK_MERCH_HIER_DEFAULT;
   close C_LOCK_MERCH_HIER_DEFAULT;

   SQL_LIB.SET_MARK('DELETE',NULL,'MERCH_HIER_DEFAULT',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

      delete from merch_hier_default
       where dept     = L_dept
         and class    = L_class
         and subclass = L_subclass;
   ---
   LP_table  := 'FILTER_GROUP_MERCH';

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'FILTER_GROUP_MERCH',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   if not FILTER_GROUP_HIER_SQL.DELETE_GROUP_MERCH(O_error_message,
                                                   'S',
                                                   L_dept,
                                                   L_class,
                                                   L_subclass) then
      return FALSE;
   end if;

   --02-Mar-2010    TESCO HSC/Nandini M    NBS00016468   Begin
   LP_table := 'TSL_SBCLS_STATMRGN_TEMP';

   open  C_LOCK_TSL_SBCLS_STATMRGN_TEMP;
   close C_LOCK_TSL_SBCLS_STATMRGN_TEMP;

   SQL_LIB.SET_MARK('DELETE',NULL,'TSL_SBCLS_STATMRGN_TEMP',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from tsl_sbcls_statmrgn_temp
    where dept     = L_dept
      and class    = L_class
      and subclass = L_subclass;
   --02-Mar-2010    TESCO HSC/Nandini M    NBS00016468   End

   --04-Apr-2014    TESCO HSC/Usha Patil    NBS00026954   Begin
   LP_table := 'TSL_MIN_PRICE_RULES';

   open  C_LOCK_TSL_MIN_PRICE_RULES;
   close C_LOCK_TSL_MIN_PRICE_RULES;

   SQL_LIB.SET_MARK('DELETE',NULL,'TSL_MIN_PRICE_RULES',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from tsl_min_price_rules
    where dept     = L_dept
      and class    = L_class
      and subclass = L_subclass;
   --04-Apr-2014    TESCO HSC/Usha Patil    NBS00026954   End

   LP_table := 'SUBCLASS';

   open  C_LOCK_SUBCLASS;
   close C_LOCK_SUBCLASS;

   SQL_LIB.SET_MARK('DELETE',NULL,'SUBCLASS',
                    'DEPT,CLASS,SUBCLASS: '||I_key_value);

   delete from subclass
    where dept     = L_dept
      and class    = L_class
      and subclass = L_subclass;
   ---
   LP_table := 'DAILY_PURGE';

   open  C_LOCK_DAILY_PURGE;
   close C_LOCK_DAILY_PURGE;

   SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_PURGE',
                    'KEY_VALUE: '||I_key_value);

   delete from daily_purge
    where key_value  = I_key_value
      and table_name = 'SUBCLASS';

   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                            LP_table,
                                            I_key_value);
         return FALSE;

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'DEL_SUBCLASS', SQLCODE);
      return FALSE;
END DEL_SUBCLASS;
-----------------------------------------------------------------------

FUNCTION DEL_STORE(I_key_value       IN       VARCHAR2,
                   O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program         VARCHAR2(50)   := 'DELETE_RECORDS_SQL.DEL_STORE';
   L_store           STORE.STORE%TYPE;
   L_zone_group_id   PRICE_ZONE.ZONE_GROUP_ID%TYPE;
   L_zone_id         PRICE_ZONE.ZONE_ID%TYPE;

   cursor C_LOCK_STORE_SHIP_DATE is
      select 'x'
        from store_ship_date
       where store = L_store
         for update nowait;

   cursor C_LOCK_DAILY_DATA is
      select 'x'
        from daily_data
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_WEEK_DATA is
      select 'x'
        from week_data
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_TRAN_DATA_HISTORY is
      select 'x'
        from tran_data_history
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_HALF_DATA is
      select 'x'
        from half_data
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_MONTH_DATA is
      select 'x'
        from month_data
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_MONTH_DATA_BUDGET is
      select 'x'
        from month_data_budget
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_HALF_DATA_BUDGET is
      select 'x'
        from half_data_budget
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_LOC_TRAITS is
      select 'x'
        from loc_traits_matrix
       where store = L_store
         for update nowait;

   cursor C_LOCK_SEC_USER_ZONE_MATRIX is
      select 'x'
       from sec_user_zone_matrix suzm
       where exists (select 'x'
                       from price_zone pz
                      where not exists (select 'x'
                                          from price_zone_group_store p
                                         where p.zone_group_id = pz.zone_group_id
                                           and p.zone_id = pz.zone_id)
                        and pz.zone_group_id = suzm.zone_group_id
                        and pz.zone_id = suzm.zone_id)
         for update nowait;

   cursor C_LOCK_PZON_GRP_STOR is
      select 'x'
        from price_zone_group_store
       where store = L_store
         for update nowait;

   cursor C_LOCK_SEC_GROUP_ZONE_MATRIX is
      select 'x' from sec_group_zone_matrix s
       where exists (select 'x'
                       from price_zone pz
                      where not exists (select 'x'
                                          from price_zone_group_store p
                                         where p.zone_group_id = pz.zone_group_id
                                           and p.zone_id = pz.zone_id)
                        and pz.zone_group_id = s.zone_group_id
                        and pz.zone_id = s.zone_id)
         for update nowait;

   cursor C_LOCK_PRICE_ZONE is
      select 'x'
        from price_zone pz
       where not exists (select 'x'
                           from price_zone_group_store p
                          where p.zone_group_id = pz.zone_group_id
                            and p.zone_id = pz.zone_id)
         for update nowait;

   cursor C_GET_CZON_GRP_LOC is
      select zone_group_id, zone_id, count(*) store_count
        from cost_zone_group_loc
       where (zone_group_id, zone_id) in (select zone_group_id, zone_id
                                            from cost_zone_group_loc
                                           where location = L_store)
    group by zone_group_id, zone_id
      having count(*) = 1;

   cursor C_LOCK_ITEM_EXP_DETAIL is
      select 'x'
        from item_exp_detail ied
       where exists
         (SELECT 'x'
            from item_exp_head ieh
           where ieh.item          = ied.item
             and ieh.supplier      = ied.supplier
             and ieh.item_exp_type = ied.item_exp_type
             and ieh.item_exp_seq  = ied.item_exp_seq
             and ieh.zone_group_id = L_zone_group_id
             and ieh.zone_id       = L_zone_id)
         for update nowait;

   cursor C_LOCK_ITEM_EXP_HEAD is
      select 'x'
        from item_exp_head
       where zone_group_id = L_zone_group_id
         and zone_id = L_zone_id
         for update nowait;

   cursor C_LOCK_EXP_PROF_DETAIL is
      select 'x'
        from exp_prof_detail d
       where exists (select 'x'
                       from exp_prof_head h
                      where h.exp_prof_key  = d.exp_prof_key
                        and h.zone_group_id = L_zone_group_id
                        and h.zone_id       = L_zone_id)
         for update nowait;

   cursor C_LOCK_EXP_PROF_HEAD is
      select 'x'
        from exp_prof_head
       where zone_group_id = L_zone_group_id
         and zone_id       = L_zone_id
         for update nowait;

   cursor C_LOCK_COST_ZONE_GROUP_LOC is
      select 'x'
        from cost_zone_group_loc
       where location = L_store
         for update nowait;

   cursor C_LOCK_COST_ZONE is
      select 'x'
        from cost_zone cz
       where not exists (select 'x'
                           from cost_zone_group_loc c
                          where c.zone_group_id = cz.zone_group_id
                            and c.zone_id       = cz.zone_id)
         for update nowait;

   cursor C_LOCK_STORE_ATTRIBUTES is
      select 'x'
        from store_attributes
       where store = L_store
         for update nowait;

   cursor C_LOCK_STORE_DEPT_AREA is
      select 'x'
        from store_dept_area
       where store = L_store
         for update nowait;

   cursor C_LOCK_STORE_GRADE_STORE is
      select 'x'
        from store_grade_store
       where store = L_store
         for update nowait;

   cursor C_LOCK_DEPT_SALES_HIST is
      select 'x'
        from dept_sales_hist
       where store = L_store
         for update nowait;

   cursor C_LOCK_DIFF_RATIO_DETAIL is
      select 'x'
        from diff_ratio_detail
       where store = L_store
         for update nowait;

   cursor C_LOCK_DSD is
      select 'x'
        from daily_sales_discount
       where store = L_store
         for update nowait;

   cursor C_LOCK_CLASS_SALES_HIST is
      select 'x'
        from class_sales_hist
       where store = L_store
         for update nowait;

   cursor C_LOCK_SUBCLASS_SALES_HIST is
      select 'x'
        from subclass_sales_hist
       where store = L_store
         for update nowait;

   cursor C_LOCK_DEPT_SALES_FORECAST is
      select 'x'
        from dept_sales_forecast
       where loc = L_store
         for update nowait;

   cursor C_LOCK_CLASS_SALES_FORECAST is
      select 'x'
        from class_sales_forecast
       where loc = L_store
         for update nowait;

   cursor C_LOCK_SUBCLASS_SALES_FORECAST is
      select 'x'
        from subclass_sales_forecast
       where loc = L_store
         for update nowait;

   cursor C_LOCK_LOAD_ERR is
      select 'x'
        from load_err
       where store = L_store
         for update nowait;

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where location = L_store
         for update nowait;

   cursor C_LOCK_EDI_DAILY_SALES is
      select 'x'
        from edi_daily_sales
       where loc = L_store
         for update nowait;

   cursor C_LOCK_COMP_STORE_LINK is
      select 'x'
        from comp_store_link
       where store = L_store
         for update nowait;

   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
        from deal_itemloc
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_SA_STORE_DATA is
      select 'x'
        from store
       where store = L_store
         for update nowait;

   cursor C_LOCK_STORE is
      select 'x'
        from store
       where store = L_store
         for update nowait;

   cursor C_LOCK_DAILY_PURGE is
      select 'x'
        from daily_purge
       where key_value  = I_key_value
         and table_name = 'STORE'
         for update nowait;

   cursor C_LOCK_STOCK_LEDGER_INSERTS is
      select 'x'
        from stock_ledger_inserts
       where location  = L_store
         and type_code = 'S'
         for update nowait;

   cursor C_LOCK_SEC_GROUP_LOC_MATRIX is
      select 'x'
        from sec_group_loc_matrix
       where store = L_store
         for update nowait;

   cursor C_LOCK_LOC_CLSF_DETAIL is
      select 'x'
        from loc_clsf_detail
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_LOC_CLSF_HEAD is
      select 'x'
        from loc_clsf_head
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_SOURCE_DLVRY_SCHED is
      select 'x'
        from source_dlvry_sched
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_SOURCE_DLVRY_SCHED_DAYS is
      select 'x'
        from source_dlvry_sched_days
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_SOURCE_DLVRY_SCHED_EXC is
      select 'x'
        from source_dlvry_sched_exc
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_COMPANY_CLOSED_EXCEP is
      select 'x'
        from company_closed_excep
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_LOCATION_CLOSED is
      select 'x'
        from location_closed
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_STAKE_SCHEDULE is
      select 'x'
        from stake_schedule
       where location = L_store
         for update nowait;

   cursor C_GEOCODE_STORE is
      select 'x'
        from geocode_store
       where store = L_store
         for update nowait;

   cursor C_POS_STORE is
      select 'x'
        from pos_store
       where store = L_store
         for update nowait;

   cursor C_LOCK_SUB_ITEMS_DETAIL is
      select 'x'
        from sub_items_detail
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_SUB_ITEMS_HEAD is
      select 'x'
        from sub_items_head
       where location = L_store
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_STORE_HIERARCHY is
      select 'x'
        from store_hierarchy
       where store = L_store
         for update nowait;

   cursor C_LOCK_TIF_EXPLODE is
      select 'x'
        from tif_explode
       where store = L_store
         for update nowait;

   cursor C_LOCK_WALK_THROUGH_STORE is
      select 'x'
        from walk_through_store
       where store = L_store
         for update nowait;

   cursor C_LOCK_ADDR is
      select 'x'
        from addr
       where key_value_1 = I_key_value
         and module      = 'ST'
         for update nowait;

BEGIN
   L_store := to_number(I_key_value);
   ---
   LP_table := 'LOC_CLSF_DETAIL';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_LOC_CLSF_DETAIL',
                    'LOC_CLSF_DETAIL',
                    'LOCATION: '||L_store);
   open C_LOCK_LOC_CLSF_DETAIL;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_LOC_CLSF_DETAIL',
                    'LOC_CLSF_DETAIL',
                    'LOCATION: '||L_store);
   close C_LOCK_LOC_CLSF_DETAIL;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'LOC_CLSF_DETAIL',
                    'LOCATION: '||I_key_value);

   delete from loc_clsf_detail
      where location = L_store
        and loc_type = 'S';

   ---
   LP_table := 'LOC_CLSF_HEAD';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_LOC_CLSF_HEAD',
                    'LOC_CLSF_HEAD',
                    'LOCATION: '||L_store);
   open C_LOCK_LOC_CLSF_HEAD;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_LOC_CLSF_HEAD',
                    'LOC_CLSF_HEAD',
                    'LOCATION: '||L_store);
   close C_LOCK_LOC_CLSF_HEAD;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'LOC_CLSF_HEAD',
                    'LOCATION: '||I_key_value);

   delete from loc_clsf_head
    where location = L_store
      and loc_type = 'S';

   ---
   LP_table := 'SOURCE_DLVRY_SCHED_EXC';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SOURCE_DLVRY_SCHED_EXC',
                    'SOURCE_DLVRY_SCHED_EXC',
                    'LOCATION: '||L_store);
   open C_LOCK_SOURCE_DLVRY_SCHED_EXC;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SOURCE_DLVRY_SCHED_EXC',
                    'SOURCE_DLVRY_SCHED_EXC',
                    'LOCATION: '||L_store);
   close C_LOCK_SOURCE_DLVRY_SCHED_EXC;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SOURCE_DLVRY_SCHED_EXC',
                    'LOCATION: '||I_key_value);

   delete from source_dlvry_sched_exc
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table := 'SOURCE_DLVRY_SCHED_DAYS';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SOURCE_DLVRY_SCHED_DAYS',
                    'SOURCE_DLVRY_SCHED_DAYS',
                    'LOCATION: '||L_store);
   open C_LOCK_SOURCE_DLVRY_SCHED_DAYS;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SOURCE_DLVRY_SCHED_DAYS',
                    'SOURCE_DLVRY_SCHED_DAYS',
                    'LOCATION: '||L_store);
   close C_LOCK_SOURCE_DLVRY_SCHED_DAYS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SOURCE_DLVRY_SCHED_DAYS',
                    'LOCATION: '||I_key_value);

   delete from source_dlvry_sched_days
    where location = L_store
      and loc_type = 'S';
   ----
   LP_table := 'SOURCE_DLVRY_SCHED';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SOURCE_DLVRY_SCHED',
                    'SOURCE_DLVRY_SCHED',
                    'LOCATION: '||L_store);
   open C_LOCK_SOURCE_DLVRY_SCHED;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SOURCE_DLVRY_SCHED',
                    'SOURCE_DLVRY_SCHED',
                    'LOCATION: '||L_store);
   close C_LOCK_SOURCE_DLVRY_SCHED;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SOURCE_DLVRY_SCHED',
                    'LOCATION: '||I_key_value);

   delete from source_dlvry_sched
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table := 'COMPANY_CLOSED_EXCEP';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_COMPANY_CLOSED_EXCEP',
                    'COMPANY_CLOSED_EXCEP',
                    'LOCATION: '||L_store);
   open C_LOCK_COMPANY_CLOSED_EXCEP;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_COMPANY_CLOSED_EXCEP',
                    'COMPANY_CLOSED_EXCEP',
                    'LOCATION: '||L_store);
   close C_LOCK_COMPANY_CLOSED_EXCEP;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'COMPANY_CLOSED_EXCEP',
                    'LOCATION: '||I_key_value);

   delete from company_closed_excep
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table := 'LOCATION_CLOSED';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_LOCATION_CLOSED',
                    'LOCATION_CLOSED',
                    'LOCATION: '||L_store);
   open C_LOCK_LOCATION_CLOSED;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_LOCATION_CLOSED',
                    'LOCATION_CLOSED',
                    'LOCATION: '||L_store);
   close C_LOCK_LOCATION_CLOSED;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'LOCATION_CLOSED',
                    'LOCATION: '||I_key_value);

   delete from location_closed
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table := 'STAKE_SCHEDULE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_STAKE_SCHEDULE',
                    'STAKE_SCHEDULE',
                    'LOCATION: '||L_store);
   open C_LOCK_STAKE_SCHEDULE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_STAKE_SCHEDULE',
                    'STAKE_SCHEDULE',
                    'LOCATION: '||L_store);
   close C_LOCK_STAKE_SCHEDULE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STAKE_SCHEDULE',
                    'LOCATION: '||I_key_value);

   delete from stake_schedule
    where location = L_store;
   ---
   LP_table  := 'STOCK_LEDGER_INSERTS';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_STOCK_LEDGER_INSERTS',
                    'STOCK_LEDGER_INSERTS',
                    'LOCATION: '||L_store);
   open C_LOCK_STOCK_LEDGER_INSERTS;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_STOCK_LEDGER_INSERTS',
                    'STOCK_LEDGER_INSERTS',
                    'LOCATION: '||L_store);
   close C_LOCK_STOCK_LEDGER_INSERTS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STOCK_LEDGER_INSERTS',
                    'STORE: '|| I_key_value);

   delete from STOCK_LEDGER_INSERTS
    where location = L_store;
   ---
   LP_table := 'STORE_SHIP_DATE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_STORE_SHIP_DATE',
                    'STORE_SHIP_DATE',
                    'STORE: '||L_store);
   open C_LOCK_STORE_SHIP_DATE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_STORE_SHIP_DATE',
                    'STORE_SHIP_DATE',
                    'STORE: '||L_store);
   close C_LOCK_STORE_SHIP_DATE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STORE_SHIP_DATE',
                    'STORE: '||I_key_value);

   delete from store_ship_date
     where store = L_store;
   ---
   LP_table := 'DAILY_DATA';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DAILY_DATA',
                    'DAILY_DATA',
                    'LOCATION: '||L_store);
   open C_LOCK_DAILY_DATA;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DAILY_DATA',
                    'DAILY_DATA',
                    'LOCATION: '||L_store);
   close C_LOCK_DAILY_DATA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DAILY_DATA',
                    'STORE: '||I_key_value);
   delete from daily_data
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table := 'WEEK_DATA';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_WEEK_DATA',
                    'WEEK_DATA',
                    'LOCATION: '||L_store);
   open C_LOCK_WEEK_DATA;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_WEEK_DATA',
                    'WEEK_DATA',
                    'LOCATION: '||L_store);
   close C_LOCK_WEEK_DATA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'WEEK_DATA',
                    'STORE: '||I_key_value);
   delete from week_data
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table  := 'TRAN_DATA_HISTORY';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_TRAN_DATA_HISTORY',
                    'TRAN_DATA_HISTORY',
                    'LOCATION: '||L_store);
   open C_LOCK_TRAN_DATA_HISTORY;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_TRAN_DATA_HISTORY',
                    'TRAN_DATA_HISTORY',
                    'LOCATION: '||L_store);
   close C_LOCK_TRAN_DATA_HISTORY;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'TRAN_DATA_HISTORY',
                    'STORE: '||I_key_value);
   delete from tran_data_history
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table  := 'HALF_DATA';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_HALF_DATA',
                    'HALF_DATA',
                    'LOCATION: '||L_store);
   open C_LOCK_HALF_DATA;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_HALF_DATA',
                    'HALF_DATA',
                    'LOCATION: '||L_store);
   close C_LOCK_HALF_DATA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'HALF_DATA',
                    'STORE: '||I_key_value);
   delete from half_data
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table  := 'MONTH_DATA';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_MONTH_DATA',
                    'MONTH_DATA',
                    'LOCATION: '||L_store);
   open C_LOCK_MONTH_DATA;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_MONTH_DATA',
                    'MONTH_DATA',
                    'LOCATION: '||L_store);
   close C_LOCK_MONTH_DATA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'MONTH_DATA',
                    'STORE: '||I_key_value);
   delete from month_data
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table  := 'MONTH_DATA_BUDGET';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_MONTH_DATA_BUDGET',
                    'MONTH_DATA_BUDGET',
                    'LOCATION: '||L_store);
   open C_LOCK_MONTH_DATA_BUDGET;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_MONTH_DATA_BUDGET',
                    'MONTH_DATA_BUDGET',
                    'LOCATION: '||L_store);
   close C_LOCK_MONTH_DATA_BUDGET;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'MONTH_DATA_BUDGET',
                    'STORE: '||I_key_value);
   delete from month_data_budget
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table  := 'HALF_DATA_BUDGET';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_HALF_DATA_BUDGET',
                    'HALF_DATA_BUDGET',
                    'LOCATION: '||L_store);
   open C_LOCK_HALF_DATA_BUDGET;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_HALF_DATA_BUDGET',
                    'HALF_DATA_BUDGET',
                    'LOCATION: '||L_store);
   close C_LOCK_HALF_DATA_BUDGET;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'HALF_DATA_BUDGET',
                    'STORE: '||I_key_value);
   delete from half_data_budget
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table  := 'LOC_TRAITS_MATRIX';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_LOC_TRAITS',
                    'LOC_TRAITS_MATRIX',
                    'STORE: '||L_store);
   open C_LOCK_LOC_TRAITS;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_LOC_TRAITS',
                    'LOC_TRAITS_MATRIX',
                    'STORE: '||L_store);
   close C_LOCK_LOC_TRAITS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'LOC_TRAITS_MATRIX',
                    'STORE: '||I_key_value);
   delete from loc_traits_matrix
    where store = L_store;

   ---
   LP_table  := 'PRICE_ZONE_GROUP_STORE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_PZON_GRP_STOR',
                    'PRICE_ZONE_GROUP_STORE',
                    'STORE: '||L_store);
   open C_LOCK_PZON_GRP_STOR;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_PZON_GRP_STOR',
                    'PRICE_ZONE_GROUP_STORE',
                    'STORE: '||L_store);
   close C_LOCK_PZON_GRP_STOR;

   SQL_LIB.SET_MARK('DELETE',NULL,'PRICE_ZONE_GROUP_STORE',
                    'STORE: '||I_key_value);
   delete from price_zone_group_store
    where store = L_store;

   ---
   LP_table := 'SEC_GROUP_ZONE_MATRIX';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SEC_GROUP_ZONE_MATRIX',
                    'SEC_GROUP_ZONE_MATRIX',
                    'STORE: '||I_key_value);
   open C_LOCK_SEC_GROUP_ZONE_MATRIX;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SEC_GROUP_ZONE_MATRIX',
                    'SEC_GROUP_ZONE_MATRIX',
                    'STORE: '||I_key_value);
   close C_LOCK_SEC_GROUP_ZONE_MATRIX;

   SQL_LIB.SET_MARK('DELETE',NULL,'SEC_GROUP_ZONE_MATRIX','STORE: '||I_key_value);
   delete from sec_group_zone_matrix s
      where exists (select 'x'
                      from price_zone pz
                     where not exists (select 'x'
                                         from price_zone_group_store p
                                        where p.zone_group_id = pz.zone_group_id
                                          and p.zone_id = pz.zone_id)
                       and pz.zone_group_id = s.zone_group_id
                       and pz.zone_id = s.zone_id);
   ---

   LP_table := 'SEC_USER_ZONE_MATRIX';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SEC_USER_ZONE_MATRIX',
                    'SEC_USER_ZONE_MATRIX',
                    'STORE: '||I_key_value);
   open C_LOCK_SEC_USER_ZONE_MATRIX;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SEC_USER_ZONE_MATRIX',
                    'SEC_USER_ZONE_MATRIX',
                    'STORE: '||I_key_value);
   close C_LOCK_SEC_USER_ZONE_MATRIX;

   SQL_LIB.SET_MARK('DELETE',NULL,'SEC_USER_ZONE_MATRIX','STORE: '||I_key_value);
   delete from sec_user_zone_matrix suzm
    where exists (select 'x'
                    from price_zone pz
                   where not exists (select 'x'
                                       from price_zone_group_store p
                                      where p.zone_group_id = pz.zone_group_id
                                        and p.zone_id = pz.zone_id)
                     and pz.zone_group_id = suzm.zone_group_id
                     and pz.zone_id = suzm.zone_id);

   ---
   LP_table  := 'PRICE_ZONE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_PRICE_ZONE',
                    'PRICE_ZONE',
                    'STORE: '||I_key_value);
   open C_LOCK_PRICE_ZONE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_PRICE_ZONE',
                    'PRICE_ZONE',
                    'STORE: '||I_key_value);
   close C_LOCK_PRICE_ZONE;

   SQL_LIB.SET_MARK('DELETE',NULL,'PRICE_ZONE',
                    'STORE: '||I_key_value);
   delete from price_zone pz
    where not exists (select 'x'
                        from price_zone_group_store p
                       where p.zone_group_id = pz.zone_group_id
                         and p.zone_id = pz.zone_id);

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CZON_GRP_LOC',
                    'COST_ZONE_GROUP_LOC',
                    'STORE: '||I_key_value);
   for c_rec in C_GET_CZON_GRP_LOC loop

      L_zone_group_id := c_rec.zone_group_id;
      L_zone_id := c_rec.zone_id;

      LP_table  := 'ITEM_EXP_DETAIL';

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ITEM_EXP_DETAIL',
                       'ITEM_EXP_DETAIL',
                       NULL);
      open C_LOCK_ITEM_EXP_DETAIL;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ITEM_EXP_DETAIL',
                       'ITEM_EXP_DETAIL',
                       NULL);
      close C_LOCK_ITEM_EXP_DETAIL;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'ITEM_EXP_DETAIL',
                       NULL);

      delete from item_exp_detail ied
       where exists
            (SELECT 'x'
               from item_exp_head ieh
              where ieh.item          = ied.item
                and ieh.supplier      = ied.supplier
                and ieh.item_exp_type = ied.item_exp_type
                and ieh.item_exp_seq  = ied.item_exp_seq
                and ieh.zone_group_id = L_zone_group_id
                and ieh.zone_id       = L_zone_id);
      ---
      LP_table  := 'ITEM_EXP_HEAD';

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ITEM_EXP_HEAD',
                       'ITEM_EXP_HEAD',
                       'ZONE GROUP ID: '||L_zone_group_id);
      open C_LOCK_ITEM_EXP_HEAD;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ITEM_EXP_HEAD',
                       'ITEM_EXP_HEAD',
                       'ZONE GROUP ID: '||L_zone_group_id);
      close C_LOCK_ITEM_EXP_HEAD;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'ITEM_EXP_HEAD',
                       NULL);

      delete from item_exp_head
       where zone_group_id = L_zone_group_id
         and zone_id = L_zone_id;
      ---
      LP_table := 'EXP_PROF_DETAIL';

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_EXP_PROF_DETAIL',
                       'EXP_PROF_DETAIL',
                       'ZONE GROUP ID: '||L_zone_group_id);
      open C_LOCK_EXP_PROF_DETAIL;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_EXP_PROF_DETAIL',
                       'EXP_PROF_DETAIL',
                       'ZONE GROUP ID: '||L_zone_group_id);
      close C_LOCK_EXP_PROF_DETAIL;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'EXP_PROF_DETAIL',
                       NULL);

      delete from exp_prof_detail d
       where exists (select 'x'
                       from exp_prof_head h
                      where h.exp_prof_key  = d.exp_prof_key
                        and h.zone_group_id = L_zone_group_id
                        and h.zone_id       = L_zone_id);
      ---
      LP_table := 'EXP_PROF_HEAD';

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_EXP_PROF_HEAD',
                       'EXP_PROF_HEAD',
                       'ZONE GROUP ID: '||L_zone_group_id);
      open C_LOCK_EXP_PROF_HEAD;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_EXP_PROF_HEAD',
                       'EXP_PROF_HEAD',
                       'ZONE GROUP ID: '||L_zone_group_id);
      close C_LOCK_EXP_PROF_HEAD;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'EXP_PROF_HEAD',
                       NULL);

      delete from exp_prof_head
       where zone_group_id = L_zone_group_id
         and zone_id = L_zone_id;

   end loop;
   ---
   LP_table  := 'COST_ZONE_GROUP_LOC';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_COST_ZONE_GROUP_LOC',
                    'COST_ZONE_GROUP_LOC',
                    'LOCATION: '||L_store);
   open C_LOCK_COST_ZONE_GROUP_LOC;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_COST_ZONE_GROUP_LOC',
                    'COST_ZONE_GROUP_LOC',
                    'LOCATION: '||L_store);
   close C_LOCK_COST_ZONE_GROUP_LOC;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'COST_ZONE_GROUP_LOC',
                    'STORE: '||i_key_value);
   delete from cost_zone_group_loc
    where location = L_store;
   ---
   LP_table  := 'COST_ZONE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_COST_ZONE',
                    'COST_ZONE',
                    'STORE: '||I_key_value);
   open C_LOCK_COST_ZONE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_COST_ZONE',
                    'COST_ZONE',
                    'STORE: '||I_key_value);
   close C_LOCK_COST_ZONE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'COST_ZONE',
                    'STORE: '||I_key_value);
   delete from cost_zone cz
    where not exists (select 'x'
                        from cost_zone_group_loc c
                       where c.zone_group_id = cz.zone_group_id
                         and c.zone_id       = cz.zone_id);
   ---
   LP_table := 'STORE_ATTRIBUTES';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_STORE_ATTRIBUTES',
                    'STORE_ATTRIBUTES',
                    'STORE: '||L_store);
   open C_LOCK_STORE_ATTRIBUTES;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_STORE_ATTRIBUTES',
                    'STORE_ATTRIBUTES',
                    'STORE: '||L_store);
   close C_LOCK_STORE_ATTRIBUTES;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STORE_ATTRIBUTES',
                    'STORE: '||I_key_value);
   delete from store_attributes
    where store = L_store;
   ---
   LP_table := 'STORE_DEPT_AREA';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_STORE_DEPT_AREA',
                    'STORE_DEPT_AREA',
                    'STORE: '||L_store);
   open C_LOCK_STORE_DEPT_AREA;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_STORE_DEPT_AREA',
                    'STORE_DEPT_AREA',
                    'STORE: '||L_store);
   close C_LOCK_STORE_DEPT_AREA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STORE_DEPT_AREA',
                    'STORE: '||I_key_value);
   delete from store_dept_area
    where store = L_store;
   ---
   LP_table := 'STORE_GRADE_STORE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_STORE_GRADE_STORE',
                    'STORE_GRADE_STORE',
                    'STORE: '||L_store);
   open C_LOCK_STORE_GRADE_STORE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_STORE_GRADE_STORE',
                    'STORE_GRADE_STORE',
                    'STORE: '||L_store);
   close C_LOCK_STORE_GRADE_STORE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STORE_GRADE_STORE',
                    'STORE: '||I_key_value);
   delete from store_grade_store
    where store = L_store;
   ---
   LP_table := 'DEPT_SALES_HIST';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEPT_SALES_HIST',
                    'DEPT_SALES_HIST',
                    'STORE: '||L_store);
   open C_LOCK_DEPT_SALES_HIST;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEPT_SALES_HIST',
                    'DEPT_SALES_HIST',
                    'STORE: '||L_store);
   close C_LOCK_DEPT_SALES_HIST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEPT_SALES_HIST',
                    'STORE: '||I_key_value);
   delete from dept_sales_hist
    where store = L_store;
   ---
   LP_table := 'DIFF_RATIO_DETAIL';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DIFF_RATIO_DETAIL',
                    'DIFF_RATIO_DETAIL',
                    'STORE: '||L_store);
   open C_LOCK_DIFF_RATIO_DETAIL;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DIFF_RATIO_DETAIL',
                    'DIFF_RATIO_DETAIL',
                    'STORE: '||L_store);
   close C_LOCK_DIFF_RATIO_DETAIL;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DIFF_RATIO_DETAIL',
                    'STORE: '||I_key_value);
   delete from diff_ratio_detail
    where store = L_store;
   ---
   LP_table := 'DAILY_SALES_DISCOUNT';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DSD',
                    'DAILY_SALES_DISCOUNT',
                    'STORE: '||L_store);
   open C_LOCK_DSD;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DSD',
                    'DAILY_SALES_DISCOUNT',
                    'STORE: '||L_store);
   close C_LOCK_DSD;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DAILY_SALES_DISCOUNT',
                    'STORE: '||I_key_value);
   delete from daily_sales_discount
    where store = L_store;
   ---
   LP_table := 'CLASS_SALES_HIST';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_CLASS_SALES_HIST',
                    'CLASS_SALES_HIST',
                    'STORE: '||L_store);
   open C_LOCK_CLASS_SALES_HIST;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_CLASS_SALES_HIST',
                    'CLASS_SALES_HIST',
                    'STORE: '||L_store);
   close C_LOCK_CLASS_SALES_HIST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'CLASS_SALES_HIST',
                    'STORE: '||I_key_value);
   delete from class_sales_hist
    where store = L_store;
   ---
   LP_table := 'SUBCLASS_SALES_HIST';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SUBCLASS_SALES_HIST',
                    'SUBCLASS_SALES_HIST',
                    'STORE: '||L_store);
   open C_LOCK_SUBCLASS_SALES_HIST;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SUBCLASS_SALES_HIST',
                    'SUBCLASS_SALES_HIST',
                    'STORE: '||L_store);
   close C_LOCK_SUBCLASS_SALES_HIST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUBCLASS_SALES_HIST',
                    'STORE: '||I_key_value);
   delete from subclass_sales_hist
    where store = L_store;
   ---
   LP_table := 'DEPT_SALES_FORECAST';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEPT_SALES_FORECAST',
                    'DEPT_SALES_FORECAST',
                    'LOCATION: '||L_store);
   open C_LOCK_DEPT_SALES_FORECAST;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEPT_SALES_FORECAST',
                    'DEPT_SALES_FORECAST',
                    'LOCATION: '||L_store);
   close C_LOCK_DEPT_SALES_FORECAST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEPT_SALES_FORECAST',
                    'STORE: '||I_key_value);
   delete from dept_sales_forecast
    where loc = L_store;
   ---
   LP_table := 'CLASS_SALES_FORECAST';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_CLASS_SALES_FORECAST',
                    'CLASS_SALES_FORECAST',
                    'LOCATION: '||L_store);
   open C_LOCK_CLASS_SALES_FORECAST;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_CLASS_SALES_FORECAST',
                    'CLASS_SALES_FORECAST',
                    'LOCATION: '||L_store);
   close C_LOCK_CLASS_SALES_FORECAST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'CLASS_SALES_FORECAST',
                    'STORE: '||I_key_value);
   delete from class_sales_forecast
    where loc = L_store;
   ---
   LP_table := 'SUBCLASS_SALES_FORECAST';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SUBCLASS_SALES_FORECAST',
                    'SUBCLASS_SALES_FORECAST',
                    'LOCATION: '||L_store);
   open C_LOCK_SUBCLASS_SALES_FORECAST;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SUBCLASS_SALES_FORECAST',
                    'SUBCLASS_SALES_FORECAST',
                    'LOCATION: '||L_store);
   close C_LOCK_SUBCLASS_SALES_FORECAST;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUBCLASS_SALES_FORECAST',
                    'STORE: '||I_key_value);
   delete from subclass_sales_forecast
    where loc = L_store;
   ---
   LP_table := 'LOAD_ERR';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_LOAD_ERR',
                    'LOAD_ERR',
                    'STORE: '||L_store);
   open C_LOCK_LOAD_ERR;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_LOAD_ERR',
                    'LOAD_ERR',
                    'STORE: '||L_store);
   close C_LOCK_LOAD_ERR;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'LOAD_ERR',
                    'STORE: '||I_key_value);
   delete from load_err
    where store = L_store;
   ---
   LP_table := 'REPL_RESULTS';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_REPL_RESULTS',
                    'REPL_RESULTS',
                    'LOCATION: '||L_store);
   open C_LOCK_REPL_RESULTS;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_REPL_RESULTS',
                    'REPL_RESULTS',
                    'LOCATION: '||L_store);
   close C_LOCK_REPL_RESULTS;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'REPL_RESULTS',
                    'STORE: '||I_key_value);
   delete from repl_results
    where location = L_store;
   ---
   LP_table := 'EDI_DAILY_SALES';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_EDI_DAILY_SALES',
                    'EDI_DAILY_SALES',
                    'LOCATION: '||L_store);
   open C_LOCK_EDI_DAILY_SALES;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_EDI_DAILY_SALES',
                    'EDI_DAILY_SALES',
                    'LOCATION: '||L_store);
   close C_LOCK_EDI_DAILY_SALES;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'EDI_DAILY_SALES',
                    'STORE: '||I_key_value);
   delete from edi_daily_sales
    where loc = L_store;
   --
   --- Added 3/30/99
   --
   LP_table := 'COMP_STORE_LINK';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_COMP_STORE_LINK',
                    'COMP_STORE_LINK',
                    'STORE: '||L_store);
   open C_LOCK_COMP_STORE_LINK;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_COMP_STORE_LINK',
                    'COMP_STORE_LINK',
                    'STORE: '||L_store);
   close C_LOCK_COMP_STORE_LINK;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'COMP_STORE_LINK',
                    'STORE: '||I_key_value);
   delete from COMP_STORE_LINK
    where store = L_store;

   ---
   LP_table := 'SEC_GROUP_LOC_MATRIX';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SEC_GROUP_LOC_MATRIX',
                    'SEC_GROUP_LOC_MATRIX',
                    'STORE: '||L_store);
   open C_LOCK_SEC_GROUP_LOC_MATRIX;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SEC_GROUP_LOC_MATRIX',
                    'SEC_GROUP_LOC_MATRIX',
                    'STORE: '||L_store);
   close C_LOCK_SEC_GROUP_LOC_MATRIX;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SEC_GROUP_LOC_MATRIX',
                    'STORE: '||I_key_value);

   delete from sec_group_loc_matrix
    where store = L_store;

   ---
   LP_table := 'DEAL_ITEMLOC';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_ITEMLOC',
                    'DEAL_ITEMLOC',
                    'LOCATION: '||L_store);
   open C_LOCK_DEAL_ITEMLOC;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_ITEMLOC',
                    'DEAL_ITEMLOC',
                    'LOCATION: '||L_store);
   close C_LOCK_DEAL_ITEMLOC;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEAL_ITEMLOC',
                    'STORE: '||I_key_value);
   delete from deal_itemloc
    where location = L_store
      and loc_type = 'S';

   ---
   LP_table := 'GEOCODE_STORE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_GEOCODE_STORE',
                    'GEOCODE_STORE',
                    'STORE: '||L_store);
   open C_GEOCODE_STORE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GEOCODE_STORE',
                    'GEOCODE_STORE',
                    'STORE: '||L_store);
   close C_GEOCODE_STORE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'GEOCODE_STORE',
                    'STORE: '||I_key_value);

   delete from GEOCODE_STORE
    where store = L_store;

---
   LP_table := 'POS_STORE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_POS_STORE',
                    'POS_STORE',
                    'STORE: '||L_store);
   open C_POS_STORE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_POS_STORE',
                    'POS_STORE',
                    'STORE: '||L_store);
   close C_POS_STORE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'POS_STORE',
                    'STORE: '||I_key_value);

   delete from POS_STORE
    where store = L_store;

   ---
   LP_table := 'SUB_ITEMS_DETAIL';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SUB_ITEMS_DETAIL',
                    'SUB_ITEMS_DETAIL',
                    'LOCATION: '||L_store);
   open C_LOCK_SUB_ITEMS_DETAIL;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SUB_ITEMS_DETAIL',
                    'SUB_ITEMS_DETAIL',
                    'LOCATION: '||L_store);
   close C_LOCK_SUB_ITEMS_DETAIL;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUB_ITEMS_DETAIL',
                    'STORE: '||I_key_value);
   delete from sub_items_detail
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table := 'SUB_ITEMS_HEAD';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SUB_ITEMS_HEAD',
                    'SUB_ITEMS_HEAD',
                    'LOCATION: '||L_store);
   open C_LOCK_SUB_ITEMS_HEAD;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SUB_ITEMS_HEAD',
                    'SUB_ITEMS_HEAD',
                    'LOCATION: '||L_store);
   close C_LOCK_SUB_ITEMS_HEAD;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUB_ITEMS_HEAD',
                    'STORE: '||I_key_value);
   delete from sub_items_head
    where location = L_store
      and loc_type = 'S';
   ---
   LP_table := 'STORE_HIERARCHY';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_STORE_HIERARCHY',
                    'STORE_HIERARCHY',
                    'STORE: '||L_store);
   open C_LOCK_STORE_HIERARCHY;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_STORE_HIERARCHY',
                    'STORE_HIERARCHY',
                    'STORE: '||L_store);
   close C_LOCK_STORE_HIERARCHY;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STORE_HIERARCHY',
                    'STORE: '||I_key_value);

   delete from store_hierarchy
    where store = L_store;
   ---
   LP_table := 'TIF_EXPLODE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_TIF_EXPLODE',
                    'TIF_EXPLODE',
                    'STORE: '||L_store);
   open C_LOCK_TIF_EXPLODE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_TIF_EXPLODE',
                    'TIF_EXPLODE',
                    'STORE: '||L_store);
   close C_LOCK_TIF_EXPLODE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'TIF_EXPLODE',
                    'STORE: '||I_key_value);


   delete from tif_explode
    where store = L_store;
   ---
   LP_table := 'SA_STORE_DATA';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SA_STORE_DATA',
                    'STORE',
                    'STORE: '||L_store);
   open C_LOCK_SA_STORE_DATA;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SA_STORE_DATA',
                    'STORE',
                    'STORE: '||L_store);
   close C_LOCK_SA_STORE_DATA;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SA_STORE_DATA',
                    'STORE: '||I_key_value);

   delete from sa_store_data
    where store = I_key_value;
   ---
   LP_table := 'WALK_THROUGH_STORE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_WALK_THROUGH_STORE',
                    'WALK_THROUGH_STORE',
                    'STORE: '||L_store);
   open C_LOCK_WALK_THROUGH_STORE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_WALK_THROUGH_STORE',
                    'WALK_THROUGH_STORE',
                    'STORE: '||L_store);
   close C_LOCK_WALK_THROUGH_STORE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'WALK_THROUGH_STORE',
                    'STORE: '||I_key_value);


   delete from walk_through_store
    where store = L_store;
   ---
   LP_table := 'ADDR';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ADDR',
                    'ADDR',
                    'STORE: '||I_key_value);
   open C_LOCK_ADDR;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ADDR',
                    'ADDR',
                    'STORE: '||I_key_value);
   close C_LOCK_ADDR;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'ADDR',
                    'STORE: '||I_key_value);

   delete from addr
         where key_value_1 = I_key_value
           and module      = 'ST';
   ---
   LP_table := 'STORE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_STORE',
                    'STORE',
                    'STORE: '||L_store);
   open C_LOCK_STORE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_STORE',
                    'STORE',
                    'STORE: '||L_store);
   close C_LOCK_STORE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'STORE',
                    'STORE: '||I_key_value);
   delete from store
    where store = L_store;
   ---
   LP_table := 'DAILY_PURGE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DAILY_PURGE',
                    'DAILY_PURGE',
                    'KEY_VALUE: '||I_key_value);
   open C_LOCK_DAILY_PURGE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DAILY_PURGE',
                    'DAILY_PURGE',
                    'KEY_VALUE: '||I_key_value);
   close C_LOCK_DAILY_PURGE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DAILY_PURGE',
                    'KEY_VALUE: '||I_key_value);
   delete from daily_purge
    where key_value = I_key_value
      and table_name = 'STORE';

   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then


      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                            LP_table,
                                            I_key_value);

      return FALSE;

   when OTHERS then


      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            SQLCODE);

      return FALSE;
END DEL_STORE;
-----------------------------------------------------------------------
-- Mod By:      Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date:    17-Oct-2008
-- Mod Ref:     CR162
-- Mod Details: Modified the function DEL_WH as per the new data model of Supply Chain Attributes
---------------------------------------------------------------------------------------------------
FUNCTION DEL_WH(I_key_value   IN     VARCHAR2,
                O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE) RETURN BOOLEAN IS

   L_wh               WH.WH%TYPE;
   L_zone_group_id    price_zone.zone_group_id%TYPE;
   L_zone_id          price_zone.zone_id%TYPE;

----------------------------------------------------------------------------------------

-- 18-Jun-2007 Satish BN, satish.narasimhaiah@in.tesco.com  Mod N21               Begin
   CURSOR C_LOCK_SCA_DIST_GROUP_DETAIL is
      select 'x'
   --CR162, Nitin Kumar, nitin.kumar@in.tesco.com, 16-Oct-2008, Begin
        from tsl_sca_wh_dist_group_detail
   --CR162, Nitin Kumar, nitin.kumar@in.tesco.com, 16-Oct-2008, End
       where wh = L_wh
         for update nowait;

   CURSOR C_LOCK_SCA_WH_ORDER_PREF_PACK is
      select 'x'
        from tsl_sca_wh_order_pref_pack
       where wh = L_wh
         for update nowait;

-- 18-Jun-2007 Satish BN, satish.narasimhaiah@in.tesco.com  Mod N21                End
----------------------------------------------------------------------------------------
   cursor C_LOCK_STORE_SHIP_DATE is
      select 'x'
        from store_ship_date
       where wh = L_wh
         for update nowait;

   cursor C_LOCK_REPL_RESULTS is
      select 'x'
        from repl_results
       where location = L_wh
         for update nowait;

   cursor C_LOCK_IB_RESULTS is
      select 'x'
        from ib_results
       where location = L_wh
         for update nowait;

   cursor C_LOCK_WEEK_DATA is
      select 'x'
        from week_data
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_TRAN_DATA_HISTORY is
      select 'x'
        from tran_data_history
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_HALF_DATA is
      select 'x'
        from half_data
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_MONTH_DATA_BUDGET is
      select 'x'
        from month_data_budget
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_HALF_DATA_BUDGET is
      select 'x'
        from half_data_budget
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_DAILY_DATA is
      select 'x'
        from daily_data
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_MONTH_DATA is
      select 'x'
        from month_data
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_GET_CZON_GRP_LOC is
      select zone_group_id, zone_id, count(*) store_count
        from cost_zone_group_loc
       where (zone_group_id, zone_id) in (select zone_group_id, zone_id
                                            from cost_zone_group_loc
                                           where location = L_wh)
    group by zone_group_id, zone_id
      having count(*) = 1;

   cursor C_LOCK_ITEM_EXP_DETAIL is
      select 'x'
        from item_exp_detail ied
       where exists
         (SELECT 'x'
            from item_exp_head ieh
           where ieh.item          = ied.item
             and ieh.supplier      = ied.supplier
             and ieh.item_exp_type = ied.item_exp_type
             and ieh.item_exp_seq  = ied.item_exp_seq
             and ieh.zone_group_id = L_zone_group_id
             and ieh.zone_id       = L_zone_id)
         for update nowait;

   cursor C_LOCK_ITEM_EXP_HEAD is
      select 'x'
        from item_exp_head
       where zone_group_id = L_zone_group_id
         and zone_id = L_zone_id
         for update nowait;

   cursor C_LOCK_EXP_PROF_DETAIL is
      select 'x'
        from exp_prof_detail d
       where exists (select 'x'
                       from exp_prof_head h
                      where h.exp_prof_key = d.exp_prof_key
                        and h.zone_group_id = L_zone_group_id
                        and h.zone_id = L_zone_id)
         for update nowait;

   cursor C_LOCK_EXP_PROF_HEAD is
      select 'x'
        from exp_prof_head
       where zone_group_id = L_zone_group_id
         and zone_id = L_zone_id
         for update nowait;

   cursor C_LOCK_COST_ZONE_GROUP_LOC is
      select 'x'
        from cost_zone_group_loc
       where location = L_wh
         for update nowait;

   cursor C_LOCK_COST_ZONE is
      select 'x'
        from cost_zone cz
       where not exists (select 'x'
                           from cost_zone_group_loc c
                          where c.zone_group_id = cz.zone_group_id
                            and c.zone_id = cz.zone_id)
          for update nowait;

   cursor C_LOCK_WH_ATTRIBUTES is
      select 'x'
        from wh_attributes
       where wh = L_wh
         for update nowait;

   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
        from deal_itemloc
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_WH is
      select 'x'
        from wh
       where wh = L_wh
         for update nowait;

  cursor C_LOCK_DAILY_PURGE is
      select 'x'
        from daily_purge
       where key_value = I_key_value
         and table_name = 'WH'
         for update nowait;

   cursor C_LOCK_STOCK_LEDGER_INSERTS is
      select 'x'
        from stock_ledger_inserts
       where location = L_wh
         and type_code = 'W'
         for update nowait;

   cursor C_LOCK_SEC_GROUP_LOC_MATRIX is
      select 'x'
        from sec_group_loc_matrix
       where wh = L_wh
         for update nowait;

   cursor C_LOCK_LOC_CLSF_DETAIL is
      select 'x'
        from loc_clsf_detail
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_LOC_CLSF_HEAD is
      select 'x'
       from loc_clsf_head
      where location = L_wh
        and loc_type = 'W'
        for update nowait;

   cursor C_LOCK_SOURCE_DLVRY_SCHED_EXC is
      select 'x'
        from source_dlvry_sched_exc
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_SOURCE_DLVRY_SCHED_DAYS is
      select 'x'
        from source_dlvry_sched_days
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_SOURCE_DLVRY_SCHED is
      select 'x'
        from source_dlvry_sched
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_COMPANY_CLOSED_EXCEP is
      select 'x'
        from company_closed_excep
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_LOCATION_CLOSED is
      select 'x'
        from location_closed
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_STAKE_SCHEDULE is
      select 'x'
        from stake_schedule
       where location = L_wh
         for update nowait;

   cursor C_LOCK_WH_DEPT is
      select 'x'
        from wh_dept
       where wh = L_wh
         for update nowait;

   cursor C_LOCK_SUB_ITEMS_DETAIL is
      select 'x'
        from sub_items_detail
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_SUB_ITEMS_HEAD is
      select 'x'
        from sub_items_head
       where location = L_wh
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_WH_ADD is
      select 'x'
        from wh_add
       where wh = L_wh
         for update nowait;

   cursor C_LOCK_PZGS is
      select 'x'
        from price_zone_group_store
       where store = L_wh
          or zone_id = L_wh
         for update nowait;

   cursor C_LOCK_PZ is
      select 'x'
        from price_zone
       where zone_id = L_wh
         for update nowait;

   cursor C_LOCK_ADDR is
      select 'x'
        from addr
       where key_value_1 = I_key_value
         and module      = 'WH'
         for update nowait;

   cursor C_LOCK_WH_PUB_INFO is
      select 'x'
        from wh_pub_info
       where wh = L_wh
         and published = 'N'
         for update nowait;

   cursor C_LOCK_WH_MFQ is
      select 'x'
        from wh_mfqueue
       where wh = L_wh
         and wh in (select wh
                      from wh_pub_info
                     where published = 'N')
         for update nowait;

BEGIN
   L_wh := to_number(I_key_value);
   ---
----------------------------------------------------------------------------------------
-- 18-Jun-2007 Satish BN, satish.narasimhaiah@in.tesco.com  Mod N21               Begin
   LP_table := 'TSL_SCA_WH_ORDER_PREF_PACK';
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SCA_WH_ORDER_PREF_PACK',
                    'TSL_SCA_WH_ORDER_PREF_PACK',
                    'WH:'||I_key_value);

   open C_LOCK_SCA_WH_ORDER_PREF_PACK;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SCA_WH_ORDER_PREF_PACK',
                    'TSL_SCA_WH_ORDER_PREF_PACK',
                    'WH:'||I_key_value);

   close C_LOCK_SCA_WH_ORDER_PREF_PACK;
   delete from tsl_sca_wh_order_pref_pack
         where wh = I_key_value;

   --CR162, Nitin Kumar, nitin.kumar@in.tesco.com, 16-Oct-2008, Begin
   LP_table := 'TSL_SCA_WH_DIST_GROUP_DETAIL';
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SCA_DIST_GROUP_DETAIL',
                    'TSL_SCA_WH_DIST_GROUP_DETAIL',
                    'WH:'||I_key_value);
   open C_LOCK_SCA_DIST_GROUP_DETAIL;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SCA_DIST_GROUP_DETAIL',
                    'TSL_SCA_WH_DIST_GROUP_DETAIL',
                    'WH:'||I_key_value);
   close C_LOCK_SCA_DIST_GROUP_DETAIL;
   delete from tsl_sca_wh_dist_group_detail
         where wh = I_key_value;
   --CR162, Nitin Kumar, nitin.kumar@in.tesco.com, 16-Oct-2008, End
-- 18-Jun-2007 Satish BN, satish.narasimhaiah@in.tesco.com  Mod N21                 End
----------------------------------------------------------------------------------------

   ---
     LP_table := 'LOC_CLSF_DETAIL';

   open C_LOCK_LOC_CLSF_DETAIL;
   close C_LOCK_LOC_CLSF_DETAIL;

   SQL_LIB.SET_MARK('DELETE', NULL, 'LOC_CLSF_DETAIL',
                    'LOCATION: '||I_key_value);

   delete from loc_clsf_detail
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'LOC_CLSF_HEAD';

   open C_LOCK_LOC_CLSF_HEAD;
   close C_LOCK_LOC_CLSF_HEAD;

   SQL_LIB.SET_MARK('DELETE', NULL, 'LOC_CLSF_HEAD',
                    'LOCATION: '||I_key_value);

   delete from loc_clsf_head
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'SOURCE_DLVRY_SCHED_EXC';

   open C_LOCK_SOURCE_DLVRY_SCHED_EXC;
   close C_LOCK_SOURCE_DLVRY_SCHED_EXC;

   SQL_LIB.SET_MARK('DELETE', NULL, 'SOURCE_DLVRY_SCHED_EXC',
                    'LOCATION: '||I_key_value);

   delete from source_dlvry_sched_exc
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'SOURCE_DLVRY_SCHED_DAYS';

   open C_LOCK_SOURCE_DLVRY_SCHED_DAYS;
   close C_LOCK_SOURCE_DLVRY_SCHED_DAYS;

   SQL_LIB.SET_MARK('DELETE', NULL,'SOURCE_DLVRY_SCHED_DAYS',
                    'LOCATION: '||I_key_value);

   delete from source_dlvry_sched_days
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'SOURCE_DLVRY_SCHED';

   open C_LOCK_SOURCE_DLVRY_SCHED;
   close C_LOCK_SOURCE_DLVRY_SCHED;

   SQL_LIB.SET_MARK('DELETE', NULL, 'SOURCE_DLVRY_SCHED',
                    'LOCATION: '||I_key_value);

   delete from source_dlvry_sched
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'COMPANY_CLOSED_EXCEP';

   open C_LOCK_COMPANY_CLOSED_EXCEP;
   close C_LOCK_COMPANY_CLOSED_EXCEP;

   SQL_LIB.SET_MARK('DELETE', NULL, 'COMPANY_CLOSED_EXCEP', 'LOCATION: '||I_key_value);

   delete from company_closed_excep
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'LOCATION_CLOSED';

   open C_LOCK_LOCATION_CLOSED;
   close C_LOCK_LOCATION_CLOSED;

   SQL_LIB.SET_MARK('DELETE', NULL, 'LOCATION_CLOSED', 'LOCATION: '||I_key_value);

   delete from location_closed
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'STAKE_SCHEDULE';

   open C_LOCK_STAKE_SCHEDULE;
   close C_LOCK_STAKE_SCHEDULE;

   SQL_LIB.SET_MARK('DELETE', NULL, 'STAKE_SCHEDULE',
                    'LOCATION: '||I_key_value);

   delete from stake_schedule
    where location = L_wh;
   ---

   ---
   LP_table  := 'STOCK_LEDGER_INSERTS';

   open C_LOCK_STOCK_LEDGER_INSERTS;
   close C_LOCK_STOCK_LEDGER_INSERTS;

   SQL_LIB.SET_MARK('DELETE',NULL,'STOCK_LEDGER_INSERTS',
                    'WH: '|| I_key_value);

   delete from STOCK_LEDGER_INSERTS
      where location = L_wh;
   ---

   LP_table := 'STORE_SHIP_DATE';

    open C_LOCK_STORE_SHIP_DATE;
   close C_LOCK_STORE_SHIP_DATE;

   SQL_LIB.SET_MARK('DELETE',NULL,'STORE_SHIP_DATE',
                    'WAREHOUSE: '||I_key_value);
   delete from store_ship_date
     where wh = L_wh;
   ---
   LP_table := 'REPL_RESULTS';

   open  C_LOCK_REPL_RESULTS;
   close C_LOCK_REPL_RESULTS;

   SQL_LIB.SET_MARK('DELETE',NULL,'REPL_RESULTS',
                                  'WH: '||I_key_value);
   delete from repl_results
    where location = L_wh;
   ---
   LP_table := 'IB_RESULTS';

   open  C_LOCK_IB_RESULTS;
   close C_LOCK_IB_RESULTS;

   SQL_LIB.SET_MARK('DELETE',NULL,'IB_RESULTS',
                                  'WH: '||I_key_value);
   delete from ib_results
    where location = L_wh;
   ---
   LP_table := 'WEEK_DATA';

   open  C_LOCK_WEEK_DATA;
   close C_LOCK_WEEK_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'WEEK_DATA',
                    'WH: '||I_key_value);
   delete from week_data
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table  := 'TRAN_DATA_HISTORY';

   open  C_LOCK_TRAN_DATA_HISTORY;
   close C_LOCK_TRAN_DATA_HISTORY;

   SQL_LIB.SET_MARK('DELETE',NULL,'TRAN_DATA_HISTORY',
                    'WH: '||I_key_value);
   delete from tran_data_history
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'HALF_DATA';

   open  C_LOCK_HALF_DATA;
   close C_LOCK_HALF_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'HALF_DATA',
                    'WH: '||I_key_value);
   delete from half_data
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'MONTH_DATA';

   open  C_LOCK_MONTH_DATA_BUDGET;
   close C_LOCK_MONTH_DATA_BUDGET;

   SQL_LIB.SET_MARK('DELETE',NULL,'MONTH_DATA_BUDGET',
                    'WH: '||I_key_value);
   delete from month_data_budget
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'HALF_DATA_BUDGET';

   open  C_LOCK_HALF_DATA_BUDGET;
   close C_LOCK_HALF_DATA_BUDGET;

   SQL_LIB.SET_MARK('DELETE',NULL,'HALF_DATA_BUDGET',
                    'WH: '||I_key_value);
   delete from half_data_budget
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'DAILY_DATA';

   open  C_LOCK_DAILY_DATA;
   close C_LOCK_DAILY_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_DATA',
                    'WH: '||I_key_value);
   delete from daily_data
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'MONTH_DATA';

   open  C_LOCK_MONTH_DATA;
   close C_LOCK_MONTH_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'MONTH_DATA',
                    'WH: '||I_key_value);
   delete from month_data
    where location = L_wh
      and loc_type = 'W';
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_CZON_GRP_LOC','COST_ZONE_GROUP_LOC',
                    'WAREHOUSE: '||I_key_value);
   for c_rec in C_GET_CZON_GRP_LOC loop

      L_zone_group_id := c_rec.zone_group_id;
      L_zone_id := c_rec.zone_id;

      LP_table  := 'ITEM_EXP_DETAIL';

      open  C_LOCK_ITEM_EXP_DETAIL;
      close C_LOCK_ITEM_EXP_DETAIL;

      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_EXP_DETAIL',NULL);

      delete from item_exp_detail ied
       where exists
            (SELECT 'x'
               from item_exp_head ieh
              where ieh.item          = ied.item
                and ieh.supplier      = ied.supplier
                and ieh.item_exp_type = ied.item_exp_type
                and ieh.item_exp_seq  = ied.item_exp_seq
                and ieh.zone_group_id = L_zone_group_id
                and ieh.zone_id       = L_zone_id);
      ---
      LP_table  := 'ITEM_EXP_HEAD';

      open  C_LOCK_ITEM_EXP_HEAD;
      close C_LOCK_ITEM_EXP_HEAD;

      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_EXP_HEAD',NULL);

      delete from item_exp_head
       where zone_group_id = L_zone_group_id
         and zone_id = L_zone_id;
      ---
      LP_table := 'EXP_PROF_DETAIL';

      open C_LOCK_EXP_PROF_DETAIL;
      close C_LOCK_EXP_PROF_DETAIL;

      SQL_LIB.SET_MARK('DELETE',NULL,'EXP_PROF_DETAIL',NULL);

      delete from exp_prof_detail d
       where exists (select 'x'
                       from exp_prof_head h
                      where h.exp_prof_key = d.exp_prof_key
                        and h.zone_group_id = L_zone_group_id
                        and h.zone_id = L_zone_id);
      ---
      LP_table := 'EXP_PROF_HEAD';

      open C_LOCK_EXP_PROF_HEAD;
      close C_LOCK_EXP_PROF_HEAD;

      SQL_LIB.SET_MARK('DELETE',NULL,'EXP_PROF_HEAD',NULL);

      delete from exp_prof_head
       where zone_group_id = L_zone_group_id
         and zone_id = L_zone_id;

   end loop;
   ---
   LP_table  := 'COST_ZONE_GROUP_LOC';

   open  C_LOCK_COST_ZONE_GROUP_LOC;
   close C_LOCK_COST_ZONE_GROUP_LOC;

   SQL_LIB.SET_MARK('DELETE',NULL,'COST_ZONE_GROUP_LOC',
                    'WH: '||I_key_value);
   delete from cost_zone_group_loc
       where location = L_wh;
   ---
   LP_table  := 'COST_ZONE';

   open  C_LOCK_COST_ZONE;
   close C_LOCK_COST_ZONE;

   SQL_LIB.SET_MARK('DELETE',NULL,'COST_ZONE',
                    'WH: '||I_key_value);
   delete from cost_zone cz
    where not exists (select 'x'
                        from cost_zone_group_loc c
                       where c.zone_group_id = cz.zone_group_id
                         and c.zone_id = cz.zone_id);
   ---
   LP_table := 'WH_ATTRIBUTES';

    open C_LOCK_WH_ATTRIBUTES;
   close C_LOCK_WH_ATTRIBUTES;

   SQL_LIB.SET_MARK('DELETE',NULL,'WH_ATTRIBUTES',
                    'WH: '||I_key_value);
   delete from wh_attributes
    where wh = L_wh;
   ---
   LP_table := 'SEC_GROUP_LOC_MATRIX';

   open  C_LOCK_SEC_GROUP_LOC_MATRIX;
   close C_LOCK_SEC_GROUP_LOC_MATRIX;

   SQL_LIB.SET_MARK('DELETE',NULL,'SEC_GROUP_LOC_MATRIX',
                    'WH: '||I_key_value);

   delete from sec_group_loc_matrix
    where wh = L_wh;

   ---
   LP_table := 'DEAL_ITEMLOC';

    open C_LOCK_DEAL_ITEMLOC;
   close C_LOCK_DEAL_ITEMLOC;

   SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_ITEMLOC',
                    'WH: '||I_key_value);
   delete from deal_itemloc
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'WH_DEPT';

    open C_LOCK_WH_DEPT;
   close C_LOCK_WH_DEPT;

   SQL_LIB.SET_MARK('DELETE',NULL,'WH_DEPT',
                    'WH: '||I_key_value);
   delete from wh_dept
    where wh = L_wh;
   ---
   LP_table := 'SUB_ITEMS_DETAIL';

    open C_LOCK_SUB_ITEMS_DETAIL;
   close C_LOCK_SUB_ITEMS_DETAIL;

   SQL_LIB.SET_MARK('DELETE',NULL,'SUB_ITEMS_DETAIL',
                    'WH: '||I_key_value);
   delete from sub_items_detail
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table := 'SUB_ITEMS_HEAD';

    open C_LOCK_SUB_ITEMS_HEAD;
   close C_LOCK_SUB_ITEMS_HEAD;

   SQL_LIB.SET_MARK('DELETE',NULL,'SUB_ITEMS_HEAD',
                    'WH: '||I_key_value);
   delete from sub_items_head
    where location = L_wh
      and loc_type = 'W';
   ---
   LP_table  := 'FILTER_GROUP_ORG';

   SQL_LIB.SET_MARK('DELETE',NULL,'FILTER_GROUP_ORG',
                    'WH: '||I_key_value);

   if not FILTER_GROUP_HIER_SQL.DELETE_GROUP_ORG(O_error_message,
                                                 'W',
                                                 L_wh) then
      return FALSE;
   end if;

   ---
   LP_table := 'PRICE_ZONE_GROUP_STORE';

    open C_LOCK_PZGS;
   close C_LOCK_PZGS;

   SQL_LIB.SET_MARK('DELETE', NULL, LP_table, 'ZONE_ID or STORE: '||I_key_value);

   delete from PRICE_ZONE_GROUP_STORE
         where zone_id = L_wh
            or store = L_wh;
   ---
   LP_table := 'PRICE_ZONE';

    open C_LOCK_PZ;
   close C_LOCK_PZ;

   SQL_LIB.SET_MARK('DELETE', NULL, LP_table, 'ZONE_ID: '||I_key_value);

   delete from PRICE_ZONE
         where zone_id = L_wh;
   ---
   LP_table  := 'WH_ADD';

    open C_LOCK_WH_ADD;
   close C_LOCK_WH_ADD;

   SQL_LIB.SET_MARK('DELETE',NULL,'WH_ADD',
                    'WH: '|| I_key_value);

   delete from WH_ADD
      where wh = L_wh;
   ---
   LP_table := 'ADDR';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ADDR',
                    'ADDR',
                    'WH: '||I_key_value);
   open C_LOCK_ADDR;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ADDR',
                    'ADDR',
                    'WH: '||I_key_value);
   close C_LOCK_ADDR;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'ADDR',
                    'WH: '||I_key_value);

   delete from addr
         where key_value_1 = I_key_value
           and module      = 'WH';
   ---
   LP_table := 'WH';

    open C_LOCK_WH;
   close C_LOCK_WH;

   SQL_LIB.SET_MARK('DELETE',NULL,'WH',
                    'WH: '||I_key_value);
   delete from wh
    where wh = L_wh;
   ---
   LP_table := 'WH_MFQUEUE';

   open C_LOCK_WH_MFQ;
   close C_LOCK_WH_MFQ;

   SQL_LIB.SET_MARK('DELETE',NULL,'WH_MFQUEUE',
                    'WH: '|| I_key_value);

   delete from WH_MFQUEUE
    where wh = L_wh
      and wh in (select wh
                   from wh_pub_info
                  where published = 'N');
   ---
   LP_table := 'WH_PUB_INFO';

   open C_LOCK_WH_PUB_INFO;
   close C_LOCK_WH_PUB_INFO;

   SQL_LIB.SET_MARK('DELETE',NULL,'WH_PUB_INFO',
                    'WH: '|| I_key_value);

   delete from WH_PUB_INFO
    where wh = L_wh
      and published = 'N';
   ---
   LP_table := 'DAILY_PURGE';

    open C_LOCK_DAILY_PURGE;
   close C_LOCK_DAILY_PURGE;

   SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_PURGE',
                    'KEY_VALUE: '||I_key_value);
   delete from daily_purge
    where key_value = I_key_value
      and table_name = 'WH';
   ---

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                           LP_table,
                                           I_key_value);
      return FALSE;

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'DEL_WH', SQLCODE);
      return FALSE;
END;
------------------------------------------------------------------

FUNCTION DEL_COST_ZONE_GROUP(I_key_value   IN     VARCHAR2,
                             error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_LOCK_COST_ZONE_GROUP_LOC is
      select 'x'
        from cost_zone_group_loc
       where zone_group_id = to_number(I_key_value)
         for update nowait;

   cursor C_LOCK_COST_ZONE is
      select 'x'
        from cost_zone
       where zone_group_id = to_number(I_key_value)
         for update nowait;

   cursor C_LOCK_COST_ZONE_GROUP is
      select 'x'
        from cost_zone_group
       where zone_group_id = to_number(I_key_value)
         for update nowait;

   cursor C_LOCK_DAILY_PURGE is
      select 'x'
        from daily_purge
       where key_value = I_key_value
         and table_name = 'COST_ZONE_GROUP'
         for update nowait;

BEGIN
   LP_table := 'COST_ZONE_GROUP_LOC';

   open  C_LOCK_COST_ZONE_GROUP_LOC;
   close C_LOCK_COST_ZONE_GROUP_LOC;

   SQL_LIB.SET_MARK('DELETE',NULL,'COST_ZONE_GROUP_LOC',
                  'ZONE_GROUP:  '||I_key_value);
   delete from cost_zone_group_loc
    where zone_group_id = to_number(I_key_value);

   LP_table := 'COST_ZONE';

   open  C_LOCK_COST_ZONE;
   close C_LOCK_COST_ZONE;

   SQL_LIB.SET_MARK('DELETE',NULL,'COST_ZONE',
                  'ZONE_GROUP:  '||I_key_value);
   delete from cost_zone
    where zone_group_id = to_number(I_key_value);

   LP_table := 'COST_ZONE_GROUP';

   open  C_LOCK_COST_ZONE_GROUP;
   close C_LOCK_COST_ZONE_GROUP;

   SQL_LIB.SET_MARK('DELETE',NULL,'COST_ZONE_GROUP',
                  'ZONE_GROUP:  '||I_key_value);
   delete from cost_zone_group
    where zone_group_id = to_number(I_key_value);

   LP_table := 'DAILY_PURGE';

   open  C_LOCK_DAILY_PURGE;
   close C_LOCK_DAILY_PURGE;

   SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_PURGE',
                  'KEY_VALUE:  '||I_key_value);
   delete from daily_purge
    where key_value = I_key_value
      and table_name = 'COST_ZONE_GROUP';

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                          LP_table,
                                          I_key_value);
      return FALSE;

   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'DEL_COST_ZONE_GROUP', SQLCODE);
      return FALSE;
END;
------------------------------------------------------------------


------------------------------------------------------------------
FUNCTION DEL_SHIPMENT(I_key_value   IN     VARCHAR2,
                      error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   cursor C_LOCK_SHIPMENT is
      select 'x'
        from shipment
       where shipment = to_number(I_key_value)
         for update nowait;

   cursor C_LOCK_DAILY_PURGE is
      select 'x'
        from daily_purge
       where key_value = I_key_value
         and table_name = 'SHIPMENT'
         for update nowait;

BEGIN
   LP_table := 'SHIPMENT';

   open  C_LOCK_SHIPMENT;
   close C_LOCK_SHIPMENT;

   SQL_LIB.SET_MARK('DELETE',NULL,'SHIPMENT',
                  'SHIPMENT:  '||I_key_value);

   delete from shipment
    where shipment = to_number(I_key_value);

   LP_table := 'DAILY_PURGE';

   open  C_LOCK_DAILY_PURGE;
   close C_LOCK_DAILY_PURGE;

   SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_PURGE',
                  'KEY_VALUE:  '||I_key_value);
   delete from daily_purge
    where key_value = I_key_value
      and table_name = 'SHIPMENT';

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                          LP_table,
                                          I_key_value);
      return FALSE;

   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'DEL_SHIPMENT', SQLCODE);
      return FALSE;

END;
------------------------------------------------------------------
FUNCTION DEL_MRT (O_SQLCODE     OUT VARCHAR2,
                  O_TABLE       OUT VARCHAR2,
                  O_ERR_DATA    OUT VARCHAR2,
                  I_TSF_NO      IN  NUMBER) RETURN BOOLEAN IS
BEGIN
   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
   O_TABLE := 'ordcust';
   DELETE
     FROM ordcust
    WHERE ordcust.tsf_no = I_TSF_NO;

   O_TABLE := 'tsfdetail_chrg';
   DELETE
     FROM tsfdetail_chrg
    WHERE tsf_no = I_TSF_NO;

   O_TABLE := 'tsf_wo_detail';
   DELETE
     FROM tsf_wo_detail
    WHERE tsf_wo_id in (SELECT tsf_wo_id
                          FROM tsf_wo_head
                         WHERE tsf_no = I_TSF_NO);

   O_TABLE := 'tsf_wo_head';
   DELETE tsf_wo_head
    WHERE tsf_no = I_TSF_NO;

   O_TABLE := 'tsf_xform_detail';
   DELETE tsf_xform_detail
    WHERE tsf_xform_id in (SELECT tsf_xform_id
                             FROM tsf_xform
                            WHERE tsf_no = I_TSF_NO);

   O_TABLE := 'tsf_xform';
   DELETE tsf_xform
    WHERE tsf_no = I_TSF_NO;

   O_TABLE := 'tsf_packing_detail';
   DELETE
     FROM TSF_PACKING_DETAIL
    WHERE tsf_packing_id in (SELECT tsf_packing_id
                               FROM tsf_packing
                              WHERE tsf_no = I_TSF_NO);

   O_TABLE := 'tsf_packing';
   DELETE tsf_packing
    WHERE tsf_no = I_TSF_NO;

   O_TABLE := 'tsf_item_wo_cost';
   DELETE tsf_item_wo_cost
    WHERE tsf_item_cost_id in (SELECT tsf_item_cost_id
                                 FROM tsf_item_cost
                                WHERE tsf_no = I_TSF_NO);

   O_TABLE := 'tsf_item_cost';
   DELETE tsf_item_cost
    WHERE tsf_no = I_TSF_NO;

   O_TABLE := 'tsfdetail';
   DELETE tsfdetail
    WHERE tsf_no = I_TSF_NO;

   O_TABLE := 'tsfhead';
   DELETE tsfhead
    WHERE tsf_no = I_TSF_NO;

   return TRUE;
   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End

   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
   /*Begin
      O_TABLE := 'ordcust';
      DELETE
        FROM ordcust
       WHERE ordcust.tsf_no = I_TSF_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsfdetail_chrg';
      DELETE
        FROM tsfdetail_chrg
       WHERE tsf_no = I_TSF_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsf_wo_detail';
      DELETE
        FROM tsf_wo_detail
       WHERE tsf_wo_id in (SELECT tsf_wo_id
                             FROM tsf_wo_head
                            WHERE tsf_no = I_TSF_NO);
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsf_wo_head';
      DELETE tsf_wo_head
       WHERE tsf_no = I_TSF_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsf_xform_detail';
      DELETE tsf_xform_detail
       WHERE tsf_xform_id in (SELECT tsf_xform_id
                                 FROM tsf_xform
                                WHERE tsf_no = I_TSF_NO);
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsf_xform';
      DELETE tsf_xform
       WHERE tsf_no = I_TSF_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsf_packing_detail';
      DELETE
        FROM TSF_PACKING_DETAIL
       WHERE tsf_packing_id in (SELECT tsf_packing_id
                                  FROM tsf_packing
                                 WHERE tsf_no = I_TSF_NO);
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsf_packing';
      DELETE tsf_packing
       WHERE tsf_no = I_TSF_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsf_item_wo_cost';
      DELETE tsf_item_wo_cost
       WHERE tsf_item_cost_id in (SELECT tsf_item_cost_id
                                    FROM tsf_item_cost
                                   WHERE tsf_no = I_TSF_NO);
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsf_item_cost';
      DELETE tsf_item_cost
       WHERE tsf_no = I_TSF_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsfdetail';
      DELETE tsfdetail
       WHERE tsf_no = I_TSF_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'tsfhead';
      DELETE tsfhead
       WHERE tsf_no = I_TSF_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
   End;

   return TRUE;*/
   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End

--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
EXCEPTION
   WHEN OTHERS THEN
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'ARRAY DELETE: tsf_no = ' || to_char(I_TSF_NO);
      return FALSE;
--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End
END;
------------------------------------------------------------------
FUNCTION DEL_DEAL (O_SQLCODE   OUT VARCHAR2,
                   O_TABLE     OUT VARCHAR2,
                   O_ERR_DATA  OUT VARCHAR2,
                   I_DEAL_NO   IN  NUMBER) RETURN BOOLEAN IS
BEGIN
   ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 Begin
   --30-Dec-2009 Tesco HSC/Nikhil Narang,Defect-NBS00015887,Oracle Patch:8484139 Begin
   O_TABLE := 'deal_item_loc_explode';
   DELETE
     FROM deal_item_loc_explode
    WHERE deal_id = I_DEAL_NO;
   --30-Dec-2009 Tesco HSC/Nikhil Narang,Defect-NBS00015887,Oracle Patch:8484139 End
   ---MrgNBS016138  ,Sarayu Gouda ,sarayu.gouda@in.tesco.com ,01-FEB-2010 End
--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
   O_TABLE := 'deal_actuals_forecast';
   DELETE
     FROM deal_actuals_forecast
    WHERE deal_id = I_DEAL_NO;

   O_TABLE := 'deal_prom';
   DELETE
     FROM deal_prom
    WHERE deal_id = I_DEAL_NO;

   --24-Sep-2012 Sriranjitha Bhagi,Sriranjitha.Bhagi@in.tesco.com ,NBS00025392 Begin
     O_TABLE := 'deal_comp_prom';
   DELETE
     FROM deal_comp_prom
    WHERE deal_id = I_DEAL_NO;
   --24-Sep-2012 Sriranjitha Bhagi,Sriranjitha.Bhagi@in.tesco.com ,NBS00025392 End

   O_TABLE := 'deal_threshold_rev';
   DELETE
     FROM deal_threshold_rev
    WHERE deal_id = I_DEAL_NO;

   O_TABLE := 'deal_queue';
   DELETE
     FROM deal_queue
    WHERE deal_id = I_DEAL_NO;

   O_TABLE := 'deal_itemloc';
   DELETE
     FROM deal_itemloc
    WHERE deal_id = I_DEAL_NO;

   O_TABLE := 'deal_threshold';
   DELETE
     FROM deal_threshold
    WHERE deal_id = I_DEAL_NO;

   O_TABLE := 'pop_terms_fulfillment';
   DELETE
     FROM pop_terms_fulfillment
    WHERE pop_def_seq_no in (SELECT pop_def_seq_no
                   FROM pop_terms_def
                  WHERE deal_id = I_DEAL_NO);

   O_TABLE := 'pop_terms_def';
   DELETE
     FROM pop_terms_def
    WHERE deal_id = I_DEAL_NO;

   O_TABLE := 'deal_detail';
   DELETE
     FROM deal_detail
    WHERE deal_id = I_DEAL_NO;

   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273 Begin
  O_TABLE := 'tsl_deal_pub_info';
  DELETE
     FROM tsl_deal_pub_info
    WHERE deal_id = I_DEAL_NO;
  --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273 End

   O_TABLE := 'deal_head';
   DELETE
     FROM deal_head
    WHERE deal_id = I_DEAL_NO;

   return TRUE;
--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End

--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
   /*
      Begin
      O_TABLE := 'deal_actuals_forecast';
      DELETE
        FROM deal_actuals_forecast
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'deal_prom';
      DELETE
        FROM deal_prom
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'deal_threshold_rev';
      DELETE
        FROM deal_threshold_rev
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'deal_queue';
      DELETE
        FROM deal_queue
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'deal_itemloc';
      DELETE
        FROM deal_itemloc
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'deal_threshold';
      DELETE
        FROM deal_threshold
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'pop_terms_fulfillment';
      DELETE
        FROM pop_terms_fulfillment
       WHERE pop_def_seq_no in (SELECT pop_def_seq_no
                                  FROM pop_terms_def
                                 WHERE deal_id = I_DEAL_NO);
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'pop_terms_def';
      DELETE
        FROM pop_terms_def
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'deal_detail';
      DELETE
        FROM deal_detail
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'deal_head';
      DELETE
        FROM deal_head
       WHERE deal_id = I_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
   End;
   --MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin
   --07-Oct-2008 Tesco HSC/Usha Patil        Defect id :NBS00009074 Begin
   --return TRUE;
   --07-Oct-2008 Tesco HSC/Usha Patil        Defect id :NBS00009074 End
   --MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End
   */
--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End

--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
EXCEPTION
   WHEN OTHERS THEN
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: deal_no = ' || to_char(I_DEAL_NO);
      return FALSE;
--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End
END;
------------------------------------------------------------------
FUNCTION DEL_FIXED_DEAL (O_SQLCODE       OUT VARCHAR2,
                         O_TABLE         OUT VARCHAR2,
                         O_ERR_DATA      OUT VARCHAR2,
                         I_FIXED_DEAL_NO IN  NUMBER) RETURN BOOLEAN IS
BEGIN
   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
   O_TABLE := 'fixed_deal_merch_loc';
   DELETE
     FROM fixed_deal_merch_loc
    WHERE deal_no = I_FIXED_DEAL_NO;

   O_TABLE := 'fixed_deal_merch';
   DELETE
     FROM fixed_deal_merch
    WHERE deal_no = I_FIXED_DEAL_NO;

   O_TABLE := 'fixed_deal_dates';
   DELETE
     FROM fixed_deal_dates
    WHERE deal_no = I_FIXED_DEAL_NO;

    --31-Aug-2013 Tesco HSC/ Basanta Swain, Defect-CR488  Begin
   --O_TABLE := 'tsl_fixed_deal_ex';
   --DELETE
     --FROM tsl_fixed_deal_ex
    --WHERE deal_no = I_FIXED_DEAL_NO;
   --31-Aug-2013 Tesco HSC/ Basanta Swain, Defect-CR488  End

   O_TABLE := 'fixed_deal';
   DELETE
     FROM fixed_deal
    WHERE deal_no = I_FIXED_DEAL_NO;


   return TRUE;
   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End

   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
   /*
   Begin
      O_TABLE := 'fixed_deal_merch_loc';
      DELETE
        FROM fixed_deal_merch_loc
       WHERE deal_no = I_FIXED_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: fixed_deal_no = ' || to_char(I_FIXED_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'fixed_deal_merch';
      DELETE
        FROM fixed_deal_merch
       WHERE deal_no = I_FIXED_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: fixed_deal_no = ' || to_char(I_FIXED_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'fixed_deal_dates';
      DELETE
        FROM fixed_deal_dates
       WHERE deal_no = I_FIXED_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: fixed_deal_no = ' || to_char(I_FIXED_DEAL_NO);
      return FALSE;
   End;

   Begin
      O_TABLE := 'fixed_deal';
      DELETE
        FROM fixed_deal
       WHERE deal_no = I_FIXED_DEAL_NO;
   Exception When OTHERS then
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: fixed_deal_no = ' || to_char(I_FIXED_DEAL_NO);
      return FALSE;
   End;


   --MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - Begin
   --07-Oct-2008 Tesco HSC/Usha Patil        Defect id :NBS00009074 Begin
   --return TRUE;
   --07-Oct-2008 Tesco HSC/Usha Patil        Defect id :NBS00009074 End
   --MrgNBS010972 Raghuveer P R 21-Jan-2009 3.3a to 3.3b merge - End
   --11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End
   */

--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) Begin
Exception
   WHEN OTHERS THEN
      O_SQLCODE := SQLERRM;
      O_ERR_DATA := 'DELETE: fixed_deal_no = ' || to_char(I_FIXED_DEAL_NO);
      return FALSE;
--11-June-2009 Tesco HSC/Nitin Kumar,Defect-NBS00004273,Patch-6909054(SR 6608713.993) End
END;
------------------------------------------------------------------
FUNCTION DEL_EXTERNAL_FINISHER(I_key_value   IN     VARCHAR2,
                               error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   L_external_finisher  PARTNER.PARTNER_ID%TYPE;

   cursor C_LOCK_STAKE_SCHEDULE is
      select 'x'
        from stake_schedule
       where location = L_external_finisher
         for update nowait;

   cursor C_LOCK_STOCK_LEDGER_INSERTS is
      select 'x'
        from stock_ledger_inserts
       where location = L_external_finisher
         and type_code = 'E'
         for update nowait;

   cursor C_LOCK_IB_RESULTS is
      select 'x'
        from ib_results
       where location = L_external_finisher
         for update nowait;

   cursor C_LOCK_WEEK_DATA is
      select 'x'
        from week_data
       where location = L_external_finisher
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_TRAN_DATA_HISTORY is
      select 'x'
        from tran_data_history
       where location = L_external_finisher
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_HALF_DATA is
      select 'x'
        from half_data
       where location = L_external_finisher
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_MONTH_DATA_BUDGET is
      select 'x'
        from month_data_budget
       where location = L_external_finisher
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_HALF_DATA_BUDGET is
      select 'x'
        from half_data_budget
       where location = L_external_finisher
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_DAILY_DATA is
      select 'x'
        from daily_data
       where location = L_external_finisher
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_MONTH_DATA is
      select 'x'
        from month_data
       where location = L_external_finisher
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
        from deal_itemloc
       where location = L_external_finisher
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_PARTNER is
      select 'x'
        from partner
       where partner_id = L_external_finisher
         for update nowait;

   cursor C_LOCK_DAILY_PURGE is
      select 'x'
        from daily_purge
       where key_value = I_key_value
         and table_name = 'PARTNER'
         for update nowait;

BEGIN
   L_external_finisher := to_number(I_key_value);
   ---
   LP_table := 'STAKE_SCHEDULE';

   open C_LOCK_STAKE_SCHEDULE;
   close C_LOCK_STAKE_SCHEDULE;

   SQL_LIB.SET_MARK('DELETE', NULL, 'STAKE_SCHEDULE',
                    'LOCATION: '||I_key_value);

   delete from stake_schedule
    where location = L_external_finisher;
   ---
   LP_table  := 'STOCK_LEDGER_INSERTS';

   open C_LOCK_STOCK_LEDGER_INSERTS;
   close C_LOCK_STOCK_LEDGER_INSERTS;

   SQL_LIB.SET_MARK('DELETE',NULL,'STOCK_LEDGER_INSERTS',
                    'LOCATION: '|| I_key_value);

   delete from STOCK_LEDGER_INSERTS
      where location = L_external_finisher;
   ---
   LP_table := 'IB_RESULTS';

   open  C_LOCK_IB_RESULTS;
   close C_LOCK_IB_RESULTS;

   SQL_LIB.SET_MARK('DELETE',NULL,'IB_RESULTS',
                                  'LOCATION: '||I_key_value);
   delete from ib_results
    where location = L_external_finisher;
   ---
   LP_table := 'WEEK_DATA';

   open  C_LOCK_WEEK_DATA;
   close C_LOCK_WEEK_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'WEEK_DATA',
                    'LOCATION: '||I_key_value);
   delete from week_data
    where location = L_external_finisher
      and loc_type = 'E';
   ---
   LP_table  := 'TRAN_DATA_HISTORY';

   open  C_LOCK_TRAN_DATA_HISTORY;
   close C_LOCK_TRAN_DATA_HISTORY;

   SQL_LIB.SET_MARK('DELETE',NULL,'TRAN_DATA_HISTORY',
                    'LOCATION: '||I_key_value);
   delete from tran_data_history
    where location = L_external_finisher
      and loc_type = 'E';
   ---
   LP_table := 'HALF_DATA';

   open  C_LOCK_HALF_DATA;
   close C_LOCK_HALF_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'HALF_DATA',
                    'LOCATION: '||I_key_value);
   delete from half_data
    where location = L_external_finisher
      and loc_type = 'E';
   ---
   LP_table := 'MONTH_DATA';

   open  C_LOCK_MONTH_DATA_BUDGET;
   close C_LOCK_MONTH_DATA_BUDGET;

   SQL_LIB.SET_MARK('DELETE',NULL,'MONTH_DATA_BUDGET',
                    'LOCATION: '||I_key_value);
   delete from month_data_budget
    where location = L_external_finisher
      and loc_type = 'E';
   ---
   LP_table := 'HALF_DATA_BUDGET';

   open  C_LOCK_HALF_DATA_BUDGET;
   close C_LOCK_HALF_DATA_BUDGET;

   SQL_LIB.SET_MARK('DELETE',NULL,'HALF_DATA_BUDGET',
                    'LOCATION: '||I_key_value);
   delete from half_data_budget
    where location = L_external_finisher
      and loc_type = 'E';
   ---
   LP_table := 'DAILY_DATA';

   open  C_LOCK_DAILY_DATA;
   close C_LOCK_DAILY_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_DATA',
                    'LOCATION: '||I_key_value);
   delete from daily_data
    where location = L_external_finisher
      and loc_type = 'E';
   ---
   LP_table := 'MONTH_DATA';

   open  C_LOCK_MONTH_DATA;
   close C_LOCK_MONTH_DATA;

   SQL_LIB.SET_MARK('DELETE',NULL,'MONTH_DATA',
                    'LOCATION: '||I_key_value);
   delete from month_data
    where location = L_external_finisher
      and loc_type = 'E';
   ---
   LP_table := 'DEAL_ITEMLOC';

    open C_LOCK_DEAL_ITEMLOC;
   close C_LOCK_DEAL_ITEMLOC;

   SQL_LIB.SET_MARK('DELETE',NULL,'DEAL_ITEMLOC',
                    'LOCATION: '||I_key_value);
   delete from deal_itemloc
    where location = L_external_finisher
      and loc_type = 'E';
   ---
   LP_table := 'PARTNER';

    open C_LOCK_PARTNER;
   close C_LOCK_PARTNER;

   SQL_LIB.SET_MARK('DELETE',NULL,'PARTNER',
                    'PARTNER_ID: '||I_key_value);
   delete from partner
    where partner_id = L_external_finisher;
   ---
   LP_table := 'DAILY_PURGE';

    open C_LOCK_DAILY_PURGE;
   close C_LOCK_DAILY_PURGE;

   SQL_LIB.SET_MARK('DELETE',NULL,'DAILY_PURGE',
                    'KEY_VALUE: '||I_key_value);
   delete from daily_purge
    where key_value = I_key_value
      and table_name = 'PARTNER';
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                           LP_table,
                                           I_key_value);
      return FALSE;

   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                          'DEL_EXTERNAL_FINISHER', SQLCODE);
      return FALSE;
END;
------------------------------------------------------------------
END;
/

