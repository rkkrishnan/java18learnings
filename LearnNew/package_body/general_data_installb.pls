CREATE OR REPLACE PACKAGE BODY GENERAL_DATA_INSTALL AS
--------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    15-Feb-2008
--Mod Ref:     Mod number. N113
--Mod Details: Amended script to add the column names for the subclass table
------------------------------------------------------------------------------------------------
--Mod By:      Deepak Gupta, Deepak.C.Gupta@in.tesco.com
--Mod Date:    02-08-2011
--Mod Ref:     CR431
--Mod Details: Inserted tsl_country_id in vat_codes table
------------------------------------------------------------------------------------------------

FUNCTION VAT_CODE_REGION(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into vat_region values (1000, 'Vat Region 1000', 'E');
   ---
   --ChrNBSC0431, Accenture/Deepak Gupta, Deepak.C.Gupta@in.tesco.com, 02-08-2011, Begin
   --Inserted tsl_country_id in vat_codes table
   insert into vat_codes values ('S', 'Standard', 'U');
   insert into vat_codes values ('E', 'Exempt', 'B');
   insert into vat_codes values ('C', 'Composite', 'U');
   insert into vat_codes values ('Z', 'Zero', 'U');
   --ChrNBSC0431, Accenture/Deepak Gupta, Deepak.C.Gupta@in.tesco.com, 02-08-2011, End
   ---
   insert into vat_code_rates values('S',
                                     to_date('01-JAN-1995', 'DD_MM_YYYY'),
                                     10.00,
                                     to_date('01-JAN-1995', 'DD_MM_YYYY'),
                                     'RMSDEV110');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.VAT_CODE_REGION',
                                            to_char(SQLCODE));
      return FALSE;
END VAT_CODE_REGION;
--------------------------------------------------------------------------------------------
FUNCTION SYSTEM_OPTIONS(O_error_message    IN OUT VARCHAR2,
                        I_prim_currency    IN     VARCHAR2,
                        I_multichannel_ind IN     VARCHAR2,
                        I_vat_ind          IN     VARCHAR2,
                        I_vat_class_ind    IN     VARCHAR2,
                        I_bracket_cost_ind IN     VARCHAR2,
                        I_table_owner      IN     VARCHAR2,
                        I_base_country_id  IN     VARCHAR2)
RETURN BOOLEAN IS

  L_prim_currency       VARCHAR2(3)  := upper(I_prim_currency);
  L_multichannel_ind    VARCHAR2(1)  := upper(I_multichannel_ind);
  L_vat_ind             VARCHAR2(1)  := upper(I_vat_ind);
  L_class_level_vat_ind VARCHAR2(1)  := upper(I_vat_class_ind);
  L_bracket_cost_ind    VARCHAR2(1)  := upper(I_bracket_cost_ind);
  L_table_owner         VARCHAR2(30) := upper(I_table_owner);
  L_base_country_id     VARCHAR2(30) := upper(I_base_country_id);

BEGIN

INSERT INTO SYSTEM_OPTIONS
(ADDR_CATALOG,
ALLOC_METHOD,
AIP_IND,
ARI_IND,
AUTO_APPROVE_CHILD_IND,
AUTO_EAN13_PREFIX,
BASE_COUNTRY_ID,
BILL_OF_LADING_HISTORY_MTHS,
BILL_OF_LADING_IND,
BILL_TO_LOC,
BRACKET_COSTING_IND,
BUD_SHRINK_IND,
CALENDAR_454_IND,
CD_MODULUS,
CD_WEIGHT_1,
CD_WEIGHT_2,
CD_WEIGHT_3,
CD_WEIGHT_4,
CD_WEIGHT_5,
CD_WEIGHT_6,
CD_WEIGHT_7,
CD_WEIGHT_8,
CHECK_DIGIT_IND,
CLASS_LEVEL_VAT_IND,
CLOSE_MTH_WITH_OPN_CNT_IND,
CLOSE_OPEN_SHIP_DAYS,
CONSOLIDATION_IND,
CONTRACT_IND,
CONTRACT_REPLENISH_IND,
COST_LEVEL,
COST_MONEY,
COST_OUT_STORAGE,
COST_OUT_STORAGE_MEAS,
COST_OUT_STORAGE_UOM,
COST_WH_STORAGE,
COST_WH_STORAGE_MEAS,
COST_WH_STORAGE_UOM,
CURRENCY_CODE,
CYCLE_COUNT_LAG_DAYS,
DAILY_SALES_DISC_MTHS,
DATA_LEVEL_SECURITY_IND,
DATE_ENTRY,
DBT_MEMO_SEND_DAYS,
DEAL_AGE_PRIORITY,
DEAL_HISTORY_MONTHS,
DEAL_LEAD_DAYS,
DEAL_TYPE_PRIORITY,
DEFAULT_ALLOC_CHRG_IND,
DEFAULT_CASE_NAME,
DEFAULT_DIMENSION_UOM,
DEFAULT_INNER_NAME,
DEFAULT_ORDER_TYPE,
DEFAULT_PACKING_METHOD,
DEFAULT_PALLET_NAME,
DEFAULT_STANDARD_UOM,
DEFAULT_UOP,
DEFAULT_VAT_REGION,
DEFAULT_WEIGHT_UOM,
DEPT_LEVEL_TRANSFERS,
DIFF_GROUP_MERCH_LEVEL_CODE,
DIFF_GROUP_ORG_LEVEL_CODE,
DISTRIBUTION_RULE,
DOMAIN_LEVEL,
DUMMY_CARTON_IND,
DUPLICATE_RECEIVING_IND,
EDI_COST_CHG_DAYS,
EDI_COST_OVERRIDE_IND,
EDI_DAILY_RPT_LAG,
EDI_NEW_ITEM_DAYS,
EDI_REV_DAYS,
ELC_IND,
EXT_INVC_MATCH_IND,
FINANCIAL_AP,
FOB_TITLE_PASS,
FOB_TITLE_PASS_DESC,
FORECAST_IND,
FUTURE_COST_HISTORY_DAYS,
GEN_CONSIGNMENT_INVC_FREQ,
GEN_CON_INVC_ITM_SUP_LOC_IND,
GL_ROLLUP,
GROCERY_ITEMS_IND,
IB_RESULTS_PURGE_DAYS,
IMAGE_PATH,
IMPORT_HTS_DATE,
IMPORT_IND,
INCREASE_TSF_QTY_IND,
INTERCOMPANY_TRANSFER_IND,
INTERFACE_PURGE_DAYS,
INV_HIST_LEVEL,
INVC_DBT_MAX_PCT,
INVC_MATCH_EXTR_DAYS,
INVC_MATCH_IND,
INVC_MATCH_MULT_SUP_IND,
INVC_MATCH_QTY_IND,
LATEST_SHIP_DAYS,
LC_APPLICANT,
LC_EXP_DAYS,
LC_FORM_TYPE,
LC_TYPE,
LEVEL_1_NAME,
LEVEL_2_NAME,
LEVEL_3_NAME,
LOC_ACTIVITY_IND,
LOC_CLOSE_HIST_MONTHS,
LOC_DLVRY_IND,
LOC_LIST_ORG_LEVEL_CODE,
LOC_TRAIT_ORG_LEVEL_CODE,
LOOK_AHEAD_DAYS,
MAX_SCALING_ITERATIONS,
MAX_WEEKS_SUPPLY,
MEASUREMENT_TYPE,
MERCH_HIER_AUTO_GEN_IND,
MULTI_CURRENCY_IND,
MULTICHANNEL_IND,
NOM_FLAG_1_LABEL,
NOM_FLAG_2_LABEL,
NOM_FLAG_3_LABEL,
NOM_FLAG_4_LABEL,
NOM_FLAG_5_LABEL,
NWP_IND,
NWP_RETENTION_PERIOD,
ORD_APPR_AMT_CODE,
ORD_APPR_CLOSE_DELAY,
ORD_PART_RCVD_CLOSE_DELAY,
ORD_WORKSHEET_CLEAN_UP_DELAY,
ORD_AUTO_CLOSE_PART_RCVD_IND,
ORD_PACK_COMP_HEAD_IND,
ORD_PACK_COMP_IND,
OTB_PROD_LEVEL_CODE,
OTB_SYSTEM_IND,
OTB_TIME_LEVEL_CODE,
PARTNER_ID_UNIQUE_IND,
PLAN_IND,
PRIMARY_LANG,
RAC_RTV_TSF_IND,
RCV_COST_ADJ_TYPE,
RDW_IND,
RECLASS_APPR_ORDER_IND,
RECLASS_DATE,
RECLASS_SYS_MAINT_DATE_IND,
REDIST_FACTOR,
REJECT_STORE_ORD_IND,
REPL_ORDER_DAYS,
REPL_ORDER_HISTORY_DAYS,
REPL_PACK_HIST_WKS,
REPL_RESULTS_ALL_IND,
REPL_RESULTS_PURGE_DAYS,
RETN_SCHED_UPD_DAYS,
ROUND_LVL,
ROUND_TO_CASE_PCT,
ROUND_TO_INNER_PCT,
ROUND_TO_LAYER_PCT,
ROUND_TO_PALLET_PCT,
RPM_IND,
RTV_NAD_LEAD_TIME,
SALES_AUDIT_IND,
SEASON_MERCH_LEVEL_CODE,
SEASON_ORG_LEVEL_CODE,
SECONDARY_DESC_IND,
SELF_BILL_IND,
SHIP_SCHED_HISTORY_MTHS,
SINGLE_STYLE_PO_IND,
SKULIST_ORG_LEVEL_CODE,
SOFT_CONTRACT_IND,
SOR_ITEM_IND,
SOR_MERCH_HIER_IND,
SOR_ORG_HIER_IND,
SOR_PURCHASE_ORDER_IND,
STAKE_COST_VARIANCE,
STAKE_LOCKOUT_DAYS,
STAKE_RETAIL_VARIANCE,
STAKE_REVIEW_DAYS,
STAKE_UNIT_VARIANCE,
START_OF_HALF_MONTH,
STD_AV_IND,
STKLDGR_VAT_INCL_RETL_IND,
STOCK_LEDGER_LOC_LEVEL_CODE,
STOCK_LEDGER_PROD_LEVEL_CODE,
STOCK_LEDGER_TIME_LEVEL_CODE,
STORAGE_TYPE,
STORE_ORDERS_PURGE_DAYS,
STORE_PACK_COMP_RCV_IND,
SUPP_PART_AUTO_GEN_IND,
TABLE_OWNER,
TARGET_ROI,
TICKET_OVER_PCT,
TICKET_TYPE_MERCH_LEVEL_CODE,
TICKET_TYPE_ORG_LEVEL_CODE,
TIME_DISPLAY,
TIME_ENTRY,
TRAN_DATA_RETAINED_DAYS_NO,
TSF_AUTO_CLOSE_STORE,
TSF_AUTO_CLOSE_WH,
TSF_FORCE_CLOSE_IND,
TSF_HISTORY_MTHS,
TSF_MD_STORE_TO_STORE_SND_RCV,
TSF_MD_WH_TO_STORE_SND_RCV,
TSF_MD_STORE_TO_WH_SND_RCV,
TSF_MD_WH_TO_WH_SND_RCV,
TSF_MRT_RETENTION_DAYS,
TSF_PRICE_EXCEED_WAC_IND,
UDA_MERCH_LEVEL_CODE,
UDA_ORG_LEVEL_CODE,
UNAVAIL_STKORD_INV_ADJ_IND,
UPDATE_ITEM_HTS_IND,
UPDATE_ORDER_HTS_IND,
VAT_IND,
WH_CROSS_LINK_IND,
WH_STORE_ASSIGN_HIST_DAYS,
WH_STORE_ASSIGN_TYPE,
WRONG_ST_RECEIPT_IND
)
VALUES (
'Y',                              ---(ADDR_CATALOG,
'P',                              ---ALLOC_METHOD,
'Y',                               ---AIP_IND
'N',                              ---ARI_IND,
'Y',                              ---AUTO_APPROVE_CHILD_IND,
123456,                           ---AUTO_EAN13_PREFIX,
L_base_country_id,                ---BASE_COUNTRY_ID,
 6,                               ---BILL_OF_LADING_HISTORY_MTHS,
'Y',                              ---BILL_OF_LADING_IND,
'1000',                           ---BILL_TO_LOC,
L_bracket_cost_ind,               ---BRACKET_COSTING_IND,
'N',                              ---BUD_SHRINK_IND,
'4',                              ---CALENDAR_454_IND,
11,                               ---CD_MODULUS,
2,                                ---CD_WEIGHT_1,
4,                                ---CD_WEIGHT_2,
8,                                ---CD_WEIGHT_3,
16,                               ---CD_WEIGHT_4,
32,                               ---CD_WEIGHT_5,
64,                               ---CD_WEIGHT_6,
128,                              ---CD_WEIGHT_7,
256,                              ---CD_WEIGHT_8,
'Y',                              ---CHECK_DIGIT_IND,
L_class_level_vat_ind,            ---CLASS_LEVEL_VAT_IND,
'N',                              ---CLOSE_MTH_WITH_OPN_CNT_IND,
3,                                ---CLOSE_OPEN_SHIP_DAYS,
'Y',                              ---CONSOLIDATION_IND,
'Y',                              ---CONTRACT_IND,
'N',                              ---CONTRACT_REPLENISH_IND,
'DNN',                            ---COST_LEVEL,
6.5,                              ---COST_MONEY,
null,                             ---COST_OUT_STORAGE,
'E',                              ---COST_OUT_STORAGE_MEAS,
null,                             ---COST_OUT_STORAGE_UOM,
null,                             ---COST_WH_STORAGE,
'E',                              ---COST_WH_STORAGE_MEAS,
null,                             ---COST_WH_STORAGE_UOM,
L_prim_currency,                  ---CURRENCY_CODE,
NULL,                             ---CYCLE_COUNT_LAG_DAYS,
12,                               ---DAILY_SALES_DISC_MTHS,
'Y',                              ---DATA_LEVEL_SECURITY_IND,
'MMDDRR',                         ---DATE_ENTRY,
3,                                ---DBT_MEMO_SEND_DAYS,
'O',                              ---DEAL_AGE_PRIORITY,
1,                                ---DEAL_HISTORY_MONTHS,
1,                                ---DEAL_LEAD_DAYS,
'P',                              ---DEAL_TYPE_PRIORITY,
'Y',                              ---DEFAULT_ALLOC_CHRG_IND,
'CS',                             ---DEFAULT_CASE_NAME,
'IN',                             ---DEFAULT_DIMENSION_UOM,
'INR',                            ---DEFAULT_INNER_NAME,
'AUTOMATIC',                      ---DEFAULT_ORDER_TYPE,
'HANG',                           ---DEFAULT_PACKING_METHOD,
'PAL',                            ---DEFAULT_PALLET_NAME,
'EA',                             ---DEFAULT_STANDARD_UOM,
'S',                              ---DEFAULT_UOP,
decode(L_vat_ind,'N',NULL,1000),  ---DEFAULT_VAT_REGION,
'LBS',                            ---DEFAULT_WEIGHT_UOM,
'N',                              ---DEPT_LEVEL_TRANSFERS,
'D',                              ---DIFF_GROUP_MERCH_LEVEL_CODE,
'A',                              ---DIFF_GROUP_ORG_LEVEL_CODE,
'PRORAT',                         ---DISTRIBUTION_RULE,
'D',                              ---DOMAIN_LEVEL,
'Y',                              ---DUMMY_CARTON_IND,
'N',                              ---DUPLICATE_RECEIVING_IND
7,                                ---EDI_COST_CHG_DAYS,
'Y',                              ---EDI_COST_OVERRIDE_IND,
1,                                ---EDI_DAILY_RPT_LAG,
7,                                ---EDI_NEW_ITEM_DAYS,
7,                                ---EDI_REV_DAYS,
'Y',                              ---ELC_IND,
'Y',                              ---EXT_INVC_MATCH_IND,
NULL,                             ---FINANCIAL_AP,
NULL,                             ---FOB_TITLE_PASS,
NULL,                             ---FOB_TITLE_PASS_DESC,
'Y',                              ---FORECAST_IND,
10,                               ---FUTURE_COST_HISTORY_DAYS,
'M',                              ---GEN_CONSIGNMENT_INVC_FREQ,
'I',                              ---GEN_CON_INVC_ITM_SUP_LOC_IND,
NULL,                             ---GL_ROLLUP,
'N',                              ---GROCERY_ITEMS_IND,
3,                                ---IB_RESULTS_PURGE_DAYS,
'http://www.retek.com/',          ---IMAGE_PATH,
'N',                              ---IMPORT_HTS_DATE,
'Y',                              ---IMPORT_IND,
'N',                              ---INCREASE_TSF_QTY_IND,
'Y',                              ---INTERCOMPANY_TRANSFER_IND,
3,                                ---INTERFACE_PURGE_DAYS,
'A',                              ---INV_HIST_LEVEL,
100,                              ---INVC_DBT_MAX_PCT,
NULL,                             ---INVC_MATCH_EXTR_DAYS,
'N',                              ---INVC_MATCH_IND,
'N',                              ---INVC_MATCH_MULT_SUP_IND,
'Y',                              ---INVC_MATCH_QTY_IND,
30,                               ---LATEST_SHIP_DAYS,
NULL,                             ---LC_APPLICANT,
30,                               ---LC_EXP_DAYS,
'L',                              ---LC_FORM_TYPE,
'M',                              ---LC_TYPE,
'Line',                           ---LEVEL_1_NAME,
'Line Extension',                 ---LEVEL_2_NAME,
'Variant',                        ---LEVEL_3_NAME,
'Y',                              ---LOC_ACTIVITY_IND,
11,                               ---LOC_CLOSE_HIST_MONTHS,
'Y',                              ---LOC_DLVRY_IND,
'A',                              ---LOC_LIST_ORG_LEVEL_CODE,
'C',                              ---LOC_TRAIT_ORG_LEVEL_CODE,
30,                               ---LOOK_AHEAD_DAYS,
NULL,                             ---MAX_SCALING_ITERATIONS,
26,                               ---MAX_WEEKS_SUPPLY,
'I',                              ---MEASUREMENT_TYPE,
'N',                              ---MERCH_HIER_AUTO_GEN_IND,
'Y',                              ---MULTI_CURRENCY_IND,
L_multichannel_ind,               ---MULTICHANNEL_IND,
'Nom Flag 1',                     ---NOM_FLAG_1_LABEL,
'In Duty',                        ---NOM_FLAG_2_LABEL,
'Nom Flag 3',                     ---NOM_FLAG_3_LABEL,
'In Exp',                         ---NOM_FLAG_4_LABEL,
'In ALC',                         ---NOM_FLAG_5_LABEL,
NULL,                             ---NWP_IND,
NULL,                             ---NWP_RETENTION_PERIOD,
'C',                              ---ORD_APPR_AMT_CODE,
1,                                ---ORD_APPR_CLOSE_DELAY,
1,                                ---ORD_PART_RCVD_CLOSE_DELAY,
1,                                ---ORD_WORKSHEET_CLEAN_UP_DELAY,
'N',                              ---ORD_AUTO_CLOSE_PART_RCVD_IND,
'N',                              ---ORD_PACK_COMP_HEAD_IND
'N',                              ---ORD_PACK_COMP_IND
'S',                              ---OTB_PROD_LEVEL_CODE,
'N',                              ---OTB_SYSTEM_IND,
'W',                              ---OTB_TIME_LEVEL_CODE,
'N',                              ---PARTNER_ID_UNIQUE_IND,
'Y',                              ---PLAN_IND,
1,                                ---PRIMARY_LANG,
'A',                              ---RAC_RTV_TSF_IND,
'F',                              ---RCV_COST_ADJ_TYPE,
'Y',                              ---RDW_IND,
'Y',                              ---RECLASS_APPR_ORDER_IND,
NULL,                             ---RECLASS_DATE,
'N',                              ---RECLASS_SYS_MAINT_DATE_IND,
2,                                ---REDIST_FACTOR,
'N',                              ---REJECT_STORE_ORD_IND,
3,                                ---REPL_ORDER_DAYS,
14,                               ---REPL_ORDER_HISTORY_DAYS,
12,                               ---REPL_PACK_HIST_WKS,
'Y',                              ---REPL_RESULTS_ALL_IND,
5,                                ---REPL_RESULTS_PURGE_DAYS,
1,                                ---RETN_SCHED_UPD_DAYS,
'C',                              ---ROUND_LVL,
50,                               ---ROUND_TO_CASE_PCT,
50,                               ---ROUND_TO_INNER_PCT,
50,                               ---ROUND_TO_LAYER_PCT,
50,                               ---ROUND_TO_PALLET_PCT,
'Y',                              ---RPM_IND,
1,                                ---RTV_NAD_LEAD_TIME
'Y',                              ---SALES_AUDIT_IND,
'D',                              ---SEASON_MERCH_LEVEL_CODE,
'A',                              ---SEASON_ORG_LEVEL_CODE,
'Y',                              ---SECONDARY_DESC_IND,
'N',                              ---SELF_BILL_IND,
3,                                ---SHIP_SCHED_HISTORY_MTHS,
'N',                              ---SINGLE_STYLE_PO_IND,
'A',                              ---SKULIST_ORG_LEVEL_CODE,
'Y',                              ---SOFT_CONTRACT_IND,
'Y',                              ---SOR_ITEM_IND,
'Y',                              ---SOR_MERCH_HIER_IND,
'Y',                              ---SOR_ORG_HIER_IND,
'Y',                              ---SOR_PURCHASE_ORDER_IND,
99,                               ---STAKE_COST_VARIANCE,
1,                                ---STAKE_LOCKOUT_DAYS,
9999.99,                          ---STAKE_RETAIL_VARIANCE,
3,                                ---STAKE_REVIEW_DAYS,
3,                                ---STAKE_UNIT_VARIANCE,
2,                                ---START_OF_HALF_MONTH,
'A',                              ---STD_AV_IND,
 decode(L_vat_ind,'N',NULL,'N'),  ---STKLDGR_VAT_INCL_RETL_IND,
'S',                              ---STOCK_LEDGER_LOC_LEVEL_CODE,
'S',                              ---STOCK_LEDGER_PROD_LEVEL_CODE,
'W',                              ---STOCK_LEDGER_TIME_LEVEL_CODE,
'W',                              ---STORAGE_TYPE,
7,                                ---STORE_ORDERS_PURGE_DAYS,
'Y',                              ---STORE_PACK_COMP_RCV_IND,
'N',                              ---SUPP_PART_AUTO_GEN_IND,
L_table_owner,                    ---TABLE_OWNER,
20,                               ---TARGET_ROI,
5,                                ---TICKET_OVER_PCT,
'D',                              ---TICKET_TYPE_MERCH_LEVEL_CODE,
'A',                              ---TICKET_TYPE_ORG_LEVEL_CODE,
'HH24:MI',                        ---TIME_DISPLAY,
'HH24MI',                         ---TIME_ENTRY,
30,                               ---TRAN_DATA_RETAINED_DAYS_NO,
'N',                              ---TSF_AUTO_CLOSE_STORE,
'N',                              ---TSF_AUTO_CLOSE_WH,
'NL',                             ---TSF_FORCE_CLOSE_IND,
6,                                ---TSF_HISTORY_MTHS,
'S',                              ---TSF_MD_STORE_TO_STORE_SND_RCV,
'S',                              ---TSF_MD_WH_TO_STORE_SND_RCV,
'S',                              ---TSF_MD_STORE_TO_WH_SND_RCV,
'S',                              ---TSF_MD_WH_TO_WH_SND_RCV,
1,                                ---TSF_MRT_RETENTION_DAYS,
'Y',                              ---TSF_PRICE_EXCEED_WAC_IND,
'G',                              ---UDA_MERCH_LEVEL_CODE,
'A',                              ---UDA_ORG_LEVEL_CODE,
'N',                              ---UNAVAIL_STKORD_INV_ADJ_IND,
'Y',                              ---UPDATE_ITEM_HTS_IND,
'Y',                              ---UPDATE_ORDER_HTS_IND,
L_vat_ind,                        ---VAT_IND,
'Y',                              ---WH_CROSS_LINK_IND,
365,                              ---WH_STORE_ASSIGN_HIST_DAYS,
'A',                              ---WH_STORE_ASSIGN_TYPE,
'Y'                               ---WRONG_ST_RECEIPT_IND,
);
   ---
   -- Must ensure that the exchange_rates associated with the Primary Currency are 1.
   ---
   update currency_rates
      set exchange_rate = 1
    where currency_code = upper(L_prim_currency);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.SYSTEM_OPTIONS',
                                            to_char(SQLCODE));
      return FALSE;
END SYSTEM_OPTIONS;
--------------------------------------------------------------------------------------------
FUNCTION UNIT_OPTIONS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

insert into unit_options(COMP_LIST_DAYS,
                         COMP_PRICE_MONTHS,
                         CONTRACT_INACTIVE_MONTHS,
                         DEPT_LEVEL_ORDERS,
                         EXPIRY_DELAY_PRE_ISSUE,
                         INV_ADJ_MONTHS,
                         ITEM_HISTORY_MONTHS,
                         ORDER_BEFORE_DAYS,
                         ORDER_HISTORY_MONTHS,
                         PRICE_CRITERIA_HISTORY_MONTHS,
                         RTV_ORDER_HISTORY_MONTHS,
                         RETENTION_OF_REJECTED_COST_CHG,
                         COST_PRIOR_CREATE_DAYS)
                  values('7',
                         '3',
                         '12',
                         'Y',
                         '30',
                         '18',
                         '12',
                         '5',
                         '6',
                         '3',
                         '12',
                         '3',
                         '7');
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.UNIT_OPTIONS',
                                            to_char(SQLCODE));
      return FALSE;
END UNIT_OPTIONS;
--------------------------------------------------------------------------------------------
FUNCTION SYSTEM_VARIABLES(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into system_variables(LAST_EOM_HALF_NO,
                                LAST_EOM_MONTH_NO,
                                LAST_EOM_DATE,
                                NEXT_EOM_DATE,
                                LAST_EOM_START_HALF,
                                LAST_EOM_END_HALF,
                                LAST_EOM_START_MONTH,
                                LAST_EOM_MID_MONTH,
                                LAST_EOM_NEXT_HALF_NO,
                                LAST_EOM_DAY,
                                LAST_EOM_WEEK,
                                LAST_EOM_MONTH,
                                LAST_EOM_YEAR,
                                LAST_EOM_WEEK_IN_HALF,
                                LAST_EOM_DATE_UNIT,
                                NEXT_EOM_DATE_UNIT,
                                LAST_EOW_DATE,
                                LAST_EOW_DATE_UNIT,
                                NEXT_EOW_DATE_UNIT,
                                LAST_CONT_ORDER_DATE)
                        values (20011, 						-- LAST_EOM_HALF_NO
                                1,							-- LAST_EOM_MONTH_NO
                	        to_date('18-FEB-2001', 'DD-MM-YYYY'),	-- LAST_EOM_DATE
                	        to_date('25-MAR-2001', 'DD-MM-YYYY'),	-- NEXT_EOM_DATE
                                to_date('22-JAN-2001', 'DD-MM-YYYY'),	-- LAST_EOM_START_HALF
                                to_date('29-JUL-2001', 'DD-MM-YYYY'),	-- LAST_EOM_END_HALF
                		to_date('22-JAN-2001', 'DD-MM-YYYY'),	-- LAST_EOM_START_MONTH
                                to_date('15-JAN-2001', 'DD-MM-YYYY'),	-- LAST_EOM_MID_MONTH
                		20012,						-- LAST_EOM_NEXT_HALF_NO
                                7,							-- LAST_EOM_DAY
                                4,							-- LAST_EOM_WEEK
                                2,							-- LAST_EOM_MONTH
                                2001,						-- LAST_EOM_YEAR
                                4,							-- LAST_EOM_WEEK_IN_HALF
                                to_date('18-FEB-2001', 'DD-MM-YYYY'),	-- LAST_EOM_DATE_UNIT
                                to_date('25-MAR-2001', 'DD-MM-YYYY'),	-- NEXT_EOM_DATE_UNIT
                                to_date('04-MAR-2001', 'DD-MM-YYYY'),	-- LAST_EOW_DATE
                                to_date('04-MAR-2001', 'DD-MM-YYYY'),	-- LAST_EOW_DATE_UNIT
                                to_date('11-MAR-2001', 'DD-MM-YYYY'),	-- NEXT_EOW_DATE_UNIT
                                null);                                   -- UPDATE_ZON_SEC_IND
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.SYSTEM_VARIABLES',
                                            to_char(SQLCODE));
      return FALSE;
END SYSTEM_VARIABLES;
--------------------------------------------------------------------------------------------
FUNCTION BANNER(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into banner values (1, 'Outlet Stores');
   insert into banner values (2, 'Posh Stores - 50Char Long Name Value 12345678901234');
   insert into banner values (3, 'Value Stores');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.BANNER',
                                            to_char(SQLCODE));
      return FALSE;
END BANNER;
--------------------------------------------------------------------------------------------
FUNCTION CHANNEL(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into channels values (100, 'The Marketplace',    'BANDM',  2);
   insert into channels values (110, 'ValueMart',          'BANDM',  3);
   insert into channels values (120, 'largeretailers.com', 'WEBSTR', 1);
   insert into channels values (130, 'Marketplace Catalog - Long Name Value 123456789012345678901234567890','CAT',    2);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.CHANNEL',
                                            to_char(SQLCODE));
      return FALSE;
END CHANNEL;
--------------------------------------------------------------------------------------------
FUNCTION BUYERS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into buyer values (1000,'Henry Quinton Gary Maeron Roden Xavier Elijah Stubbs III', '6125259845', '6125259800');
   insert into buyer values (1001,'Charles Bott', '6125252612', '6125259800');
   insert into buyer values (1002,'Matt Wilsman', '6125251034', '6125259800');
   insert into buyer values (1003,'Ann Woodley',  '6125252864', '6125259800');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL. BUYERS',
                                            to_char(SQLCODE));
      return FALSE;
END BUYERS;
--------------------------------------------------------------------------------------------
FUNCTION MERCHANTS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into merchant values (1000,'Craig Swanson','6124475425','6124472525');
   insert into merchant values (1001,'Paul Kohout','6124472728',null);
   insert into merchant values (1002,'Mark Smith','6124844894','6124842525');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL. MERCHANTS',
                                            to_char(SQLCODE));
      return FALSE;
END MERCHANTS;
--------------------------------------------------------------------------------------------
FUNCTION COMPHEAD(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into comphead (select 1,'Large Retailers Ltd','801 Nicollet Mall',
                                null,null,'Minneapolis','MN',base_country_id,'55402'
                           from system_options);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL. COMPHEAD',
                                            to_char(SQLCODE));
      return FALSE;
END COMPHEAD;
--------------------------------------------------------------------------------------------
FUNCTION LOCHIER(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   --*********************************** CHAINS *******
   insert into chain values (1000, 'The Marketplace', 'Ann Williams',   'USD');
   insert into chain values (1001, 'ValueMart',       'Robert Simpson', 'USD');
   insert into chain values (1002, 'AussieMart',      'Robert Simpson', 'AUD');
   insert into chain values (1003, 'Outpost-A.detachment of troops stationed at a distance from a main force to guard against surprise attacks.',         'Robert Simpson', 'CAD');
   --************************************ AREAS *******
   insert into area values (1000, 'US - Marketplace',     'Kelly Grubb',  1000, 'USD');
   insert into area values (1001, 'US - ValueMart',       'Raymond Pike', 1000, 'USD');
   insert into area values (1002, 'Australia-AussieMart', 'Raymond Pike', 1002, 'AUD');
   insert into area values (1003, 'Canada - Outpost',     'Kelly Grubb',  1003, 'CAD');
   --************************************ REGIONS *******
   insert into region values (1000, 'Northeast', 'Steve Johnson',    1000, 'USD');
   insert into region values (1001, 'Southeast', 'Wendy Huber',      1000, 'USD');
   insert into region values (1002, 'Midwest',   'Heidi Lewis',      1000, 'USD');
   insert into region values (1003, 'Northwest', 'Sarah Larson',     1000, 'USD');
   insert into region values (1004, 'Southwest', 'Jason Vork',       1000, 'USD');
   insert into region values (1005, 'Northeast', 'Kim Anderson',     1001, 'USD');
   insert into region values (1006, 'Southeast', 'Bob Meier',        1001, 'USD');
   insert into region values (1007, 'Midwest',   'Caroline Carlson', 1001, 'USD');
   insert into region values (1008, 'Australia', 'Caroline Carlson', 1002, 'AUD');
   insert into region values (1009, 'Canada',    'Bob Meier',        1003, 'CAD');
   --**************************************** DISTRICTS *******
   insert into district values (1000, 'New England',     'Kari Bittner',     1000, 'USD');
   insert into district values (1001, 'New York',        'Todd Phillips ',   1000, 'USD');
   insert into district values (1002, 'Washington',      'Robert Clinton',   1000, 'USD');
   insert into district values (1003, 'Georgia',         'Lisa Martin',      1001, 'USD');
   insert into district values (1004, 'Carolinas',       'Jesse Shrick',     1001, 'USD');
   insert into district values (1005, 'Florida',         'Beth James',       1001, 'USD');
   insert into district values (1006, 'Dakotas',         'Kevin Zollar',     1002, 'USD');
   insert into district values (1007, 'Minnesota',       'George Fisher',    1002, 'USD');
   insert into district values (1008, 'Wisconsin',       'Judy Drummond',    1002, 'USD');
   insert into district values (1009, 'Heartland',       'Keith Opal',       1002, 'USD');
   insert into district values (1010, 'Washington',      'Amy Harris',       1003, 'USD');
   insert into district values (1011, 'Northern Calif. - Longer Description Value 123456789012345678901234567890', 'Joe Todd',         1003, 'USD');
   insert into district values (1012, 'Rockies',         'Alex Crawford',    1003, 'USD');
   insert into district values (1013, 'Southern Calif.', 'Bob Jacob',        1004, 'USD');
   insert into district values (1014, 'Nevada',          'Frank Hart',       1004, 'USD');
   insert into district values (1015, 'Rio Grande',      'Philip Marsh',     1004, 'USD');
   insert into district values (1016, 'New England',     'Kristi Gange',     1005, 'USD');
   insert into district values (1017, 'New York',        'Neal Vanstrom',    1005, 'USD');
   insert into district values (1018, 'Washington',      'Jody Duncan',      1005, 'USD');
   insert into district values (1019, 'Georgia',         'Darrin Hansen',    1006, 'USD');
   insert into district values (1020, 'Carolinas',       'Kyle Freeman',     1006, 'USD');
   insert into district values (1021, 'Florida',         'Emily Nothacker',  1006, 'USD');
   insert into district values (1022, 'Dakotas',         'Brian Reed',       1007, 'USD');
   insert into district values (1023, 'Minnesota',       'Brent Herspiegel', 1007, 'USD');
   insert into district values (1024, 'Australia',       'Brent Herspiegel', 1008, 'AUD');
   insert into district values (1025, 'Canada',          'Brian Reed',       1009, 'CAD');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL. LOCHIER',
                                            to_char(SQLCODE));
      return FALSE;
END LOCHIER;

--------------------------------------------------------------------------------------------
FUNCTION ADD_TYPE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

-- Define a record type to store all of the values will be inserted

TYPE address_type_rectype IS RECORD(address_type      VARCHAR2(2),
                                    address_type_desc VARCHAR2(40),
                                    external_addr_ind VARCHAR2(1));

-- Define a table type based upon the record type defined above.

TYPE address_type_tabletype IS TABLE OF address_type_rectype
   INDEX BY BINARY_INTEGER;

address_type_list   address_type_tabletype;

BEGIN

/* Fill the table.  If you need to add a new address type, add a new record to the table below*/

   address_type_list(1).address_type := '01';
   address_type_list(1).address_type_desc := 'Business';
   address_type_list(1).external_addr_ind := 'N';

   address_type_list(2).address_type := '02';
   address_type_list(2).address_type_desc := 'Postal';
   address_type_list(2).external_addr_ind := 'N';

   address_type_list(3).address_type := '03';
   address_type_list(3).address_type_desc := 'Returns';
   address_type_list(3).external_addr_ind := 'N';

   address_type_list(4).address_type := '04';
   address_type_list(4).address_type_desc := 'Order';
   address_type_list(4).external_addr_ind := 'N';

   address_type_list(5).address_type := '05';
   address_type_list(5).address_type_desc := 'Invoice';
   address_type_list(5).external_addr_ind := 'N';

   address_type_list(6).address_type := '06';
   address_type_list(6).address_type_desc := 'Remittance';
   address_type_list(6).external_addr_ind := 'N';

   FOR i in 1..address_type_list.COUNT
   LOOP

         insert into add_type (address_type,
                               type_desc,
                               external_addr_ind)
                       values (address_type_list(i).address_type,
                               address_type_list(i).address_type_desc,
                               address_type_list(i).external_addr_ind);

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.ADD_TYPE',
                                            to_char(SQLCODE));
      return FALSE;
END ADD_TYPE;
--------------------------------------------------------------------------------------------
FUNCTION ADD_TYPE_MODULE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   --this functions should be incorporated with ext_invc_match_ind; if ext_invc_match_ind is 'Y'
   --then the mandatory_ind for add_type '05' for suppliers needs to be 'Y'
   --suppliers
   insert into add_type_module values ('01', 'SUPP', 'Y', 'Y');
   insert into add_type_module values ('02', 'SUPP', 'N', 'N');
   insert into add_type_module values ('03', 'SUPP', 'N', 'Y');
   insert into add_type_module values ('04', 'SUPP', 'N', 'Y');
   insert into add_type_module values ('05', 'SUPP', 'N', 'Y');
   insert into add_type_module values ('06', 'SUPP', 'N', 'N');
   --partners
   insert into add_type_module values ('01', 'PTNR', 'N', 'N');
   insert into add_type_module values ('02', 'PTNR', 'N', 'N');
   insert into add_type_module values ('03', 'PTNR', 'N', 'N');
   insert into add_type_module values ('04', 'PTNR', 'N', 'N');
   insert into add_type_module values ('05', 'PTNR', 'N', 'N');
   insert into add_type_module values ('06', 'PTNR', 'N', 'N');
   --locations
   insert into add_type_module values ('01', 'WH', 'Y', 'Y');
   insert into add_type_module values ('02', 'WH', 'N', 'Y');
   insert into add_type_module values ('01', 'ST', 'Y', 'Y');
   insert into add_type_module values ('02', 'ST', 'N', 'Y');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.ADD_TYPE_MODULE',
                                            to_char(SQLCODE));
      return FALSE;
END ADD_TYPE_MODULE;
--------------------------------------------------------------------------------------------
FUNCTION TSF_ZONE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into tsfzone values (1000, 'Transfer Zone 1');
   insert into tsfzone values (1001, 'Transfer Zone 2');
   insert into tsfzone values (1002, 'Transfer Zone 3');
   insert into tsfzone values (1003, 'Transfer Zone 4');
   insert into tsfzone values (1004, 'Transfer Zone 5 - Longer Description Value 12345678901234567890');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.TSF_ZONE',
                                            to_char(SQLCODE));
      return FALSE;
END TSF_ZONE;
--------------------------------------------------------------------------------------------
FUNCTION TSF_ENTITY(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into tsf_entity (tsf_entity_id, tsf_entity_desc) values (1000, 'Tsf Entity 1000');
   insert into tsf_entity (tsf_entity_id, tsf_entity_desc) values (1001, 'Tsf Entity 1001');
   insert into tsf_entity (tsf_entity_id, tsf_entity_desc) values (1002, 'Tsf Entity 1002 Longer Description Value 123456789012345678901234567890');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.TSF_ENTITY',
                                            to_char(SQLCODE));
      return FALSE;
END TSF_ENTITY;
--------------------------------------------------------------------------------------------
FUNCTION STORE_FORMAT(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into store_format values (1000,'Strip Mall');
   insert into store_format values (1001,'Standalone');
   insert into store_format values (1002,'Shopping Mall');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.STORE_FORMAT',
                                            to_char(SQLCODE));
      return FALSE;
END STORE_FORMAT;
--------------------------------------------------------------------------------------------
FUNCTION WHS(O_error_message    IN OUT VARCHAR2,
             I_multichannel_ind IN     VARCHAR2,
             I_vat_ind          IN     VARCHAR2)
RETURN BOOLEAN IS

   L_vat_region            WH.VAT_REGION%TYPE       := NULL;
   L_phys_stockholding_ind WH.STOCKHOLDING_IND%TYPE := NULL;

 L_country_id          COUNTRY.COUNTRY_ID%TYPE;

   cursor C_GET_CANADA_COUNTRY_ID is
      select decode(length(base_country_id), 2, 'CA','CAN')
        from system_options;
BEGIN
   open C_GET_CANADA_COUNTRY_ID;
   fetch C_GET_CANADA_COUNTRY_ID into L_country_id;
   close C_GET_CANADA_COUNTRY_ID;
   ---


INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (2222222222,
 'Western Physical WH - Including Long Description Value 1234567890123456789012345678901234567890123456789',
 'Western Physical WH Secondary - Including Long Description Value 1234567890123456789012345678901234567890123456789',
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 2222222222,
 null,
 NULL,
 'N',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'Y',
 NULL,
 NULL,
 1000,
 'N',
 1);


INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 ( 1111111111,
 'Central Physical WH',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 NULL,
 'N',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'Y',
 NULL,
 NULL,
 1000,
 'N',
 1);
if I_multichannel_ind = 'Y' then
INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES (
1,
 'Central V WH2',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 null,
 NULL,
 'N',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'Y',
 NULL,
 NULL,
 1000,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 ( 2,
 'Western V WH2',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 2222222222,
 null,
 NULL,
 'N',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'Y',
 NULL,
 NULL,
 1000,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 ( 3,
 'Cent. Mkpl VWH3 - Long Description Value 1234567890123456789012345678901234567890123456789012345678901234567890',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 100,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1000,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 ( 4,
 'Cent. Web VWH4',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 120,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1002,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (5,
 'Cent. Catalog VWH5',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 130,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1002,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 ( 6,
 'Cent. ValueMart VWH6',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 110,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1001,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (7,
 'W. ValueMart VWH3',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 2222222222,
 NULL,
 110,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1001,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (8,
 'W. Web VWH4',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 2222222222,
 NULL,
 120,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1002,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 ( 9,
 'W. Catalog VWH5',
 'W. Catalog VWH5 Secondary',
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 2222222222,
 NULL,
 130,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1002,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (10,
 'Central V WH6',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 null,
 NULL,
 'N',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'Y',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'Y',
 NULL,
 NULL,
 1000,
 'N',
 1);




INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (1111111112,
 'Cent. Mrkt VWH 7 - Longer Name Addition 0132456789012345678901234567890',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 100,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1000,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (1111111113,
 'Cent. Web VWH 8',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 120,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1002,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (1111111114,
 'Cent. Catalog VWH 9',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 130,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1002,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (1111111115,
 'Cent. VM VWH 10',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 1111111111,
 NULL,
 110,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1001,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 (2222222223,
 'W. ValueMart VWH 11',
 NULL,
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 2222222222,
 NULL,
 110,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1001,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 ( 2222222224,
 'W. Web VWH 12',
 'W. Web VWH 12 Secondary Name',
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 2222222222,
 NULL,
 120,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1002,
 'N',
 1);

INSERT INTO WH
(WH,
 WH_NAME,
 WH_NAME_SECONDARY,
 EMAIL,
 VAT_REGION,
 ORG_HIER_TYPE,
 ORG_HIER_VALUE,
 CURRENCY_CODE,
 PHYSICAL_WH,
 PRIMARY_VWH,
 CHANNEL_ID,
 STOCKHOLDING_IND,
 BREAK_PACK_IND,
 REDIST_WH_IND,
 DELIVERY_POLICY,
 RESTRICTED_IND,
 PROTECTED_IND,
 FORECAST_WH_IND,
 ROUNDING_SEQ,
 REPL_IND,
 REPL_WH_LINK,
 REPL_SRC_ORD,
 IB_IND,
 IB_WH_LINK,
 AUTO_IB_CLEAR,
 DUNS_NUMBER,
 DUNS_LOC,
 TSF_ENTITY_ID,
 FINISHER_IND,
 INBOUND_HANDLING_DAYS)
 VALUES
 ( 2222222225,
 'W. Catalog VWH 13',
 'W. Catalog VWH 13 Secondary Name',
 NULL,
 decode(I_vat_ind,'N',NULL,1000),
 NULL,
 NULL,
 'USD',
 2222222222,
 NULL,
 130,
 'Y',
 'Y',
 'N',
 'NEXT',
 'N',
 'N',
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 'N',
 NULL,
 'N',
 NULL,
 NULL,
 1002,
 'N',
 1);

update wh set primary_vwh =  1111111112 where physical_wh =  1111111111;
update wh set primary_vwh =  2222222223 where physical_wh =  2222222222;

end if;  --ends if multi-channel = 'Y'
---
INSERT INTO ADDR
(ADDR_KEY,
 MODULE,
 KEY_VALUE_1,
 KEY_VALUE_2,
 SEQ_NO,
 ADDR_TYPE,
 PRIMARY_ADDR_IND,
 ADD_1,
 ADD_2,
 ADD_3,
 CITY,
 STATE,
 COUNTRY_ID,
 POST,
 CONTACT_NAME,
 CONTACT_PHONE,
 CONTACT_TELEX,
 CONTACT_FAX,
 CONTACT_EMAIL,
 ORACLE_VENDOR_SITE_ID,
 EDI_ADDR_CHG,
 COUNTY,
 PUBLISH_IND )
 (select addr_sequence.nextval,
 'WH',
 wh,
 NULL,
  1,
 '01',
 'Y',
 '123 Street',
 'Anytown',
 NULL,
 'Anycity',
 'MN',
 L_country_id,
 '50250',
 'Sue Glass',
 '3122222473',
 '3122222525',
 NULL,
 NULL,
 NULL,
 NULL,
 NULL,
 'N'
 from
 wh where physical_wh = wh);


 INSERT INTO ADDR
 (ADDR_KEY,
  MODULE,
  KEY_VALUE_1,
  KEY_VALUE_2,
  SEQ_NO,
  ADDR_TYPE,
  PRIMARY_ADDR_IND,
  ADD_1,
  ADD_2,
  ADD_3,
  CITY,
  STATE,
  COUNTRY_ID,
  POST,
  CONTACT_NAME,
  CONTACT_PHONE,
  CONTACT_TELEX,
  CONTACT_FAX,
  CONTACT_EMAIL,
  ORACLE_VENDOR_SITE_ID,
  EDI_ADDR_CHG,
  COUNTY,
  PUBLISH_IND )
  (select addr_sequence.nextval,
  'WH',
  wh,
  NULL,
   1,
  '02',
  'Y',
  '123 Street',
  'Anytown',
  NULL,
  'Anycity',
  'MN',
  L_country_id,
  '50250',
  'Sue Glass',
  '3122222473',
  '3122222525',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  'N'
  from
 wh where physical_wh = wh);
   ---
   if I_multichannel_ind = 'Y' then
      insert into stock_ledger_inserts (type_code,
                                        dept,
                                        class,
                                        subclass,
                                        location)
                                             (select 'W',
                                              NULL,
                                              NULL,
                                              NULL,
                                              wh
                                         from wh
                                        where physical_wh != wh);


      ---
   else
      insert into stock_ledger_inserts (type_code,
                                        dept,
                                        class,
                                        subclass,
                                        location)
                                        (select 'W',
                                              NULL,
                                              NULL,
                                              NULL,
                                              wh
                                         from wh
                                        where physical_wh = wh);

   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL. WHS',
                                            to_char(SQLCODE));
      return FALSE;
END WHS;
-------------------------------------------------------------------------------------------
FUNCTION STORES(O_error_message    IN OUT VARCHAR2,
                I_multichannel_ind IN     VARCHAR2,
                I_vat_ind          IN     VARCHAR2)
RETURN BOOLEAN IS

   L_channel1    CHANNELS.CHANNEL_ID%TYPE    := NULL;
   L_channel2    CHANNELS.CHANNEL_ID%TYPE    := NULL;
   L_channel3    CHANNELS.CHANNEL_ID%TYPE    := NULL;
   L_channel4    CHANNELS.CHANNEL_ID%TYPE    := NULL;
   L_vat_region  VAT_REGION.VAT_REGION%TYPE;
   L_default_wh1 WH.WH%TYPE;
   L_default_wh2 WH.WH%TYPE;
   ---
   PROGRAM_ERROR EXCEPTION;

   L_country_id          COUNTRY.COUNTRY_ID%TYPE;

   cursor C_GET_CANADA_COUNTRY_ID is
      select decode(length(base_country_id), 2, 'CA','CAN')
        from system_options;
BEGIN
   open C_GET_CANADA_COUNTRY_ID;
   fetch C_GET_CANADA_COUNTRY_ID into L_country_id;
   close C_GET_CANADA_COUNTRY_ID;
   ---
   if I_multichannel_ind = 'Y' then
      L_channel1 := 100;
      L_channel2 := 110;
      L_channel3 := 120;
      L_channel4 := 130;
   end if;
   ---
   if I_multichannel_ind = 'Y' then
      L_default_wh1 := 1111111112;
      L_default_wh2 := 2222222223;
   else
      L_default_wh1 := 1111111111;
      L_default_wh2 := 2222222222;
   end if;
   ---
   if I_vat_ind = 'Y' then
      L_vat_region := 1000;
   end if;
   ---
---Stores

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
( 1000001000,
'Edina',
'Edina Secondary Name',
'Edina',
'EDN',
'B',
'Keith Patterson',
TO_Date( '01/01/1995 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
NULL,
NULL,
NULL,
'6123348750',
'6123348700',
NULL,
100000,
750000,
NULL,
L_vat_region,
'N',
'Y',
L_channel2,
1001,
NULL,
1006,
1001,
L_default_wh1,
NULL,
7,
'USD',
1,
'S',
'N',
'USD',
NULL,
NULL,
NULL,
1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000000,
'Fargo',
'Fargo Secondary Name',
'Fargo',
'Far',
'A',
'Kurt Roots',
 TO_Date('01/01/1995 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '7017228725',
 '7017228700',
 NULL,
 500000,
 450000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel2,
 1000,
 'Ridgehaven',
 1005,
 1002,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000001,
 'Minneapolis',
 'Minneapolis Secondary Name',
 'Mpls',
 'MPL',
 'B',
 'Jeff Warren',
  TO_Date( '01/01/1995 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '6123348750',
 '6123348700',
 NULL,
 100000,
 750000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel2,
 1001,
 NULL,
 1006,
 1001,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000002,
 'Madison - Including Longer Name Value 01234567890123456789012345678901234567890123457890123456789',
 'Madison Secondary Name - Including Longer Value 0123456789012345678901234567890123456789012345789',
 'Madison',
 'MAD',
 'C',
 'Alyssa Kunau',
  TO_Date( '12/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '6087309320',
 '6087309310',
 NULL,
 750000,
 500000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1002,
 'Galleria',
 1007,
 1002,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);


INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000003,
 'Peoria',
 'Peoria',
 'Peoria',
 'PEO',
 'A',
 'Amy Lackas',
  TO_Date( '12/01/1992 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '3094541213',
 '3094541212',
 NULL,
 250000,
 100000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1002,
 'Peoria Square',
 1008,
 1001,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES (
1000000004,
'Sioux Falls',
'Sioux Falls',
'Sioux F',
'SUX',
'B',
'Michael Woodbury',
 TO_Date( '01/01/1993 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '6055555678',
 '6055555678',
 NULL,
 175000,
 150000,
 NULL,
 L_vat_region,
 'N',
'Y',
 L_channel1,
1001,
NULL,
1007,
1000,
L_default_wh1,
NULL,
7,
'USD',
1,
'S',
'N',
'USD',
NULL,
NULL,
NULL,
1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000005,
'Oakland',
'Oakland',
'Oakland',
'OAK',
'A',
'Kevin Hearnen',
TO_Date( '11/01/1993 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
NULL,
NULL,
NULL,
'5105305455',
'5105305450',
NULL,
90000,
75000,
NULL,
L_vat_region,
'N',
'Y',
 L_channel1,
1000,
'Crosstown Plaza',
1010,
1001,
L_default_wh2,
NULL,
7,
'USD',
1,
'S',
'N',
'USD',
NULL,
NULL,
NULL,
1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000006,
'Hermosa Beach',
'Hermosa Beach',
'Hermosa',
'HMB',
'A',
'Eric Hendrickson',
 TO_Date( '01/01/1992 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '3107982510',
 '3107982540',
 NULL,
 150000,
 125000,
 NULL,
 L_vat_region,
 'N',
 'Y',
  L_channel1,
 1000,
 'Shoppers City Plaza',
 1012,
 1003,
 L_default_wh1,
 NULL,
 7,
'USD',
 1,
'S',
'N',
'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000007,
 'Fresno',
 'Fresno',
 'Fresno',
 'FRS',
 'B',
 'Renata Scholtz',
  TO_Date( '06/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '3107982510',
 '3107982540',
 NULL,
 150000,
 125000,
 NULL,
 L_vat_region,
 'N',
 'Y',
  L_channel1,
 1001,
 NULL,
 1010,
 1002,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000008,
'Boston - largeretailers.com',
'Boston - largeretailers.com',
'Boston',
'BOS',
'A',
'Ila Rimando',
 TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '6173208500',
 '6173208520',
 NULL,
 NULL,
 NULL,
 NULL,
 L_vat_region,
 'N',
 'N',
  L_channel3,
 1000,
 'Boston Square Plaza',
 1000,
 1003,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000009,
 'Atlanta Catalog',
 'Atlanta Catalog',
 'Atlanta',
 'ATL',
 'A',
 'Geraldine Tan',
  TO_Date( '02/05/1992 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 TO_Date( '06/10/0094 12:00:00 AM',
 'MM/DD/YYYY HH:MI:SS AM'),
 '4046331000',
 '4046337410',
 NULL,
 NULL,
 NULL,
 NULL,
 L_vat_region,
 'N',
 'N',
 L_channel3,
 1000,
 'Shoppers Center',
 1003,
 1002,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
 (1000000011,
 'lr.com WebStore - Including Longer Name Value 01234567890123456748901234567489012345678901234567890',
 'lr.com WebStore',
 'Hartford',
 'HAR',
 'A',
 'Debbie George',
  TO_Date( '05/01/1993 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '4568482745',
 '4568484662',
 NULL,
 NULL,
 NULL,
 NULL,
 L_vat_region,
 'N',
 'N',
 L_channel3,
 1001,
 NULL,
 1000,
 1002,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000015,
 'Washington DC',
 'Washington DC',
 'Washington',
 'WSH',
 'A',
 'Stacey Dornquast',
  TO_Date( '01/01/1993 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '2084760000',
 '2084764000',
 NULL,
 NULL,
 NULL,
 NULL,
 L_vat_region,
 'N',
 'N',
 L_channel4,
 1001,
 NULL,
 1002,
 1001,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1001);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000010,
 'Houston',
 'Houston',
 'Houston',
 'HOU',
 'A',
 'Chad Timm',
  TO_Date( '04/01/1992 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '7137352510',
 '7137352500',
 NULL,
 90000,
 75000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel3,
 1001,
 NULL,
 1014,
 1004,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1001);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000012,
 'New York City',
 'New York City Secondary Name',
 'New York',
 'NYC',
 'A',
 'Steven Gooijer',
  TO_Date( '01/01/1993 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '2019854384',
 '2019854931',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1001,
 1000,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1001);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000013,
 'Buffalo - Including Longer Name Value 0123456789012345678901234567890',
 'Buffalo',
 'Buffalo',
 'BUF',
 'A',
 'Diana Eisert',
  TO_Date( '01/01/1992 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '2088760000',
 '2088761111',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1001,
 1000,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000014,
 'Baltimore',
 'Baltimore',
 'Baltimore',
 'BLT',
 'A',
 'Peter Welsh',
  TO_Date( '01/01/1993 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '2044650000',
 '204651000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1002,
 1004,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1002);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000016,
 'Savannah',
 'Savannah',
 'Savannah',
 'SAV',
 'A',
 'Lisa Schoolcraft',
  TO_Date( '01/01/1993 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '2034760000',
 '2034764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1000,
 'Cliifview Mall',
 1003,
 1003,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000017,
 'Charlotte',
 'Charlotte',
 'Charlotte',
 'CHA',
 'A',
 'David Gahan',
  TO_Date( '01/01/1992 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '5034761000',
 '5034764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1004,
 1003,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1002);


INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000018,
 'Charleston',
 'Charleston',
 'Charleston',
 'CHR',
 'A',
 'Cheryl Hansen',
  TO_Date( '01/01/1992 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '7654761000',
 '7654764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1004,
 1003,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000019,
 'Jacksonville',
 'Jacksonville',
 'Jacksonvil',
 'JCK',
 'A',
 'Amanda Hubert',
  TO_Date( '01/01/1994 12:00:00 AM',
 'MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '4054761000',
 '4054764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1002,
 'Jacksonville Center',
 1005,
 1002,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000020,
 'Orlando',
 'Orlando Secondary Name',
 'Orlando',
 'ORL',
 'A',
 'William Fries',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '4054761000',
 '4054764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1005,
 1002,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000021,
 'Duluth',
 'Duluth',
 'Duluth',
 'DUL',
 'A',
 'Debby Chapman',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '2184761000',
 '2184764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1002,
 'Village Mall',
 1006,
 1002,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000022,
 'Omaha',
 'Omaha',
 'Omaha',
 'OMA',
 'A',
 'Charles Koenig',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '5644761000',
 '5644764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1008,
 1002,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000023,
 'Seattle',
 'Seattle',
 'Seattle',
 'SEA',
 'C',
 'Helen Trucker',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '9564761000',
 '95644764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1009,
 1002,
 L_default_wh2,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1000);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000024,
 'Denver',
 'Denver',
 'Denver',
 'DNV',
 'C',
 'David Bernard',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '7644761000',
 '7644764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1011,
 1004,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1002);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000025,
 'Las Vegas',
 'Las Vegas',
 'Las Vegas',
 'LVG',
 'A',
 'Laura Dotseth',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '8044761000',
 '8044764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1013,
 1002,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1002);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000026,
 'Perth',
 'Perth',
 'Perth',
 'PTH',
 'A',
 'Mike Foley',
  TO_Date( '01/01/1994 12:00:00 AM',
 'MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '8044761000',
 '8044764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1024,
 1002,
 L_default_wh2,
 NULL,
 7,
 'AUD',
 1,
 'S',
 'N',
 'AUD',
 NULL,
 NULL,
 NULL,
 1001);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000027,
 'Sydney',
 'Sydney',
 'Sydney',
 'SYD',
 'A',
 'Sandi Stowe',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '8044761000',
 '8044764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1024,
 1002,
 L_default_wh2,
 NULL,
 7,
 'AUD',
 1,
 'S',
 'N',
 'AUD',
 NULL,
 NULL,
 NULL,
 1001);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000028,
 'Melbourne',
 'Melbourne',
 'Melbourne',
 'MEL',
 'A',
 'Pat Repinski',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '8044761000',
 '8044764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1024,
 1002,
 L_default_wh2,
 NULL,
 7,
 'AUD',
 1,
 'S',
 'N',
 'AUD',
 NULL,
 NULL,
 NULL,
 1001);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000029,
 'Toronto',
 'Toronto',
 'Toronto',
 'TOR',
 'A',
 'Michael Hunck',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '8044761000',
 '8044764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1025,
 1002,
 L_default_wh1,
 NULL,
 7,
 'CAD',
 1,
 'S',
 'N',
 'CAD',
 NULL,
 NULL,
 NULL,
 1002);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000030,
 'Yellowknife',
 'Yellowknife Secondary Name Value',
 'Ylwknife',
 'YLW',
 'A',
 'Jen Mossip Scott',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '8044761000',
 '8044764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel1,
 1001,
 NULL,
 1025,
 1002,
 L_default_wh2,
 NULL,
 7,
 'CAD',
 1,
 'S',
 'N',
 'CAD',
 NULL,
 NULL,
 NULL,
 1002);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000000031,
 'Halifax',
 'Halifax',
 'Halifax',
 'HLX',
 'A',
 'Morgan Day',
  TO_Date( '01/01/1994 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '8044761000',
 '8044764000',
 NULL,
 100000,
 80000,
 NULL,
 L_vat_region,
 'N',
 'Y',
 L_channel4,
 1001,
 NULL,
 1025,
 1002,
 L_default_wh1,
 NULL,
 7,
 'CAD',
 1,
 'S',
 'N',
 'CAD',
 NULL,
 NULL,
 NULL,
 1002);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000001001,
 'Eagan',
 'Eagan',
 'Eagan',
 'EAG',
 'B',
 'Judy Kramer',
  TO_Date( '01/01/1995 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '6123348750',
 '6123348700',
 NULL,
 100000,
 750000,
 NULL,
 L_vat_region,
 'N',
 'Y',
  L_channel4,
 1001,
 NULL,
 1006,
 1001,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1002);

INSERT INTO STORE
(STORE,
STORE_NAME,
STORE_NAME_SECONDARY,
STORE_NAME10,
STORE_NAME3,
STORE_CLASS,
STORE_MGR_NAME,
STORE_OPEN_DATE,
STORE_CLOSE_DATE,
ACQUIRED_DATE,
REMODEL_DATE,
FAX_NUMBER,
PHONE_NUMBER,
EMAIL,
TOTAL_SQUARE_FT,
SELLING_SQUARE_FT,
LINEAR_DISTANCE,
VAT_REGION,
VAT_INCLUDE_IND,
STOCKHOLDING_IND,
CHANNEL_ID,
STORE_FORMAT,
MALL_NAME,
DISTRICT,
TRANSFER_ZONE,
DEFAULT_WH,
STOP_ORDER_DAYS,
START_ORDER_DAYS,
CURRENCY_CODE,
LANG,
TRAN_NO_GENERATED,
INTEGRATED_POS_IND,
ORIG_CURRENCY_CODE,
DUNS_NUMBER,
DUNS_LOC,
SISTER_STORE,
TSF_ENTITY_ID )
VALUES
(1000001002,
 'Mall of America',
 'Mall of America',
 'MallAmer',
 'MOA',
 'B',
 'Tom Schone',
  TO_Date( '01/01/1995 12:00:00 AM','MM/DD/YYYY HH:MI:SS AM'),
 NULL,
 NULL,
 NULL,
 '6123348750',
 '6123348700',
 NULL,
 100000,
 750000,
 NULL,
 L_vat_region,
 'N',
 'Y',
  L_channel4,
 1001,
 NULL,
 1006,
 1001,
 L_default_wh1,
 NULL,
 7,
 'USD',
 1,
 'S',
 'N',
 'USD',
 NULL,
 NULL,
 NULL,
 1001);


 INSERT INTO ADDR
 (ADDR_KEY,
  MODULE,
  KEY_VALUE_1,
  KEY_VALUE_2,
  SEQ_NO,
  ADDR_TYPE,
  PRIMARY_ADDR_IND,
  ADD_1,
  ADD_2,
  ADD_3,
  CITY,
  STATE,
  COUNTRY_ID,
  POST,
  CONTACT_NAME,
  CONTACT_PHONE,
  CONTACT_TELEX,
  CONTACT_FAX,
  CONTACT_EMAIL,
  ORACLE_VENDOR_SITE_ID,
  EDI_ADDR_CHG,
  COUNTY,
  PUBLISH_IND )
  (select addr_sequence.nextval,
  'ST',
  store,
  NULL,
   1,
  '01',
  'Y',
  '123 Street',
  'Anytown',
  NULL,
  'Anycity',
  'MN',
  L_country_id,
  '50250',
  'Sue Glass',
  '3122222473',
  '3122222525',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  'N'
  from
  store);


  INSERT INTO ADDR
  (ADDR_KEY,
   MODULE,
   KEY_VALUE_1,
   KEY_VALUE_2,
   SEQ_NO,
   ADDR_TYPE,
   PRIMARY_ADDR_IND,
   ADD_1,
   ADD_2,
   ADD_3,
   CITY,
   STATE,
   COUNTRY_ID,
   POST,
   CONTACT_NAME,
   CONTACT_PHONE,
   CONTACT_TELEX,
   CONTACT_FAX,
   CONTACT_EMAIL,
   ORACLE_VENDOR_SITE_ID,
   EDI_ADDR_CHG,
   COUNTY,
   PUBLISH_IND )
   (select addr_sequence.nextval,
   'ST',
   store,
   NULL,
    1,
   '02',
   'Y',
   '123 Street',
   'Anytown',
   NULL,
   'Anycity',
   'MN',
   L_country_id,
   '50250',
   'Sue Glass',
   '3122222473',
   '3122222525',
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   'N'
   from
  store);


   insert into store_hierarchy (select company,
                                ar.chain,
                                re.area,
                                di.region,
                                st.district,
                                st.store
                           from comphead,
                                area ar,
                                region re,
                                district di,
                                store st
                          where st.district = di.district
                            and di.region = re.region
                            and re.area = ar.area);

   ---
   -- Create stock ledger inserts records.
   ---
   insert into stock_ledger_inserts (type_code,
                                     dept,
                                     class,
                                     subclass,
                                     location)
                              select 'S',
                                     NULL,
                                     NULL,
                                     NULL,
                                     store
                                from store;


   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.STORES',
                                            to_char(SQLCODE));
      return FALSE;
END STORES;
--------------------------------------------------------------------------------------------
FUNCTION SUPS_ADDR(O_error_message       IN OUT VARCHAR2,
                   I_vat_ind             IN     VARCHAR2,
                   I_bracket_costing_ind IN     VARCHAR2)
RETURN BOOLEAN IS

   L_vat_region          NUMBER;
   L_bracket_costing_ind VARCHAR2(1) := I_bracket_costing_ind;
   L_country_id          COUNTRY.COUNTRY_ID%TYPE;

   cursor C_GET_CANADA_COUNTRY_ID is
      select decode(length(base_country_id), 2, 'CA','CAN')
        from system_options;
BEGIN
   open C_GET_CANADA_COUNTRY_ID;
   fetch C_GET_CANADA_COUNTRY_ID into L_country_id;
   close C_GET_CANADA_COUNTRY_ID;
   ---
   if I_vat_ind = 'Y' then
      L_vat_region := 1000;
   end if;
   ---
   --********************** SUPPLIER = 1212120000 ****
   insert into sups (SUPPLIER  ,
                     SUP_NAME                       ,
                     SUP_NAME_SECONDARY             ,
                     CONTACT_NAME                   ,
                     CONTACT_PHONE                  ,
                     CONTACT_FAX                    ,
                     CONTACT_PAGER                  ,
                     SUP_STATUS                     ,
                     QC_IND                         ,
                     QC_PCT                         ,
                     QC_FREQ                        ,
                     VC_IND                         ,
                     VC_PCT                         ,
                     VC_FREQ                        ,
                     CURRENCY_CODE                  ,
                     LANG                           ,
                     TERMS                          ,
                     FREIGHT_TERMS                  ,
                     RET_ALLOW_IND                  ,
                     RET_AUTH_REQ                   ,
                     RET_MIN_DOL_AMT                ,
                     RET_COURIER                    ,
                     HANDLING_PCT                   ,
                     EDI_PO_IND                     ,
                     EDI_PO_CHG                     ,
                     EDI_PO_CONFIRM                 ,
                     EDI_ASN                        ,
                     EDI_SALES_RPT_FREQ             ,
                     EDI_SUPP_AVAILABLE_IND         ,
                     EDI_CONTRACT_IND               ,
                     EDI_INVC_IND                   ,
                     EDI_CHANNEL_ID                 ,
                     COST_CHG_PCT_VAR               ,
                     COST_CHG_AMT_VAR               ,
                     REPLEN_APPROVAL_IND            ,
                     SHIP_METHOD                    ,
                     PAYMENT_METHOD                 ,
                     CONTACT_TELEX                  ,
                     CONTACT_EMAIL                  ,
                     SETTLEMENT_CODE                ,
                     PRE_MARK_IND                   ,
                     AUTO_APPR_INVC_IND             ,
                     DBT_MEMO_CODE                  ,
                     FREIGHT_CHARGE_IND             ,
                     AUTO_APPR_DBT_MEMO_IND         ,
                     PREPAY_INVC_IND                ,
                     BACKORDER_IND                  ,
                     VAT_REGION                     ,
                     INV_MGMT_LVL                   ,
                     SERVICE_PERF_REQ_IND           ,
                     INVC_PAY_LOC                   ,
                     INVC_RECEIVE_LOC               ,
                     ADDINVC_GROSS_NET              ,
                     DELIVERY_POLICY                ,
                     COMMENT_DESC                   ,
                     DEFAULT_ITEM_LEAD_TIME         ,
                     DUNS_NUMBER                    ,
                     DUNS_LOC                       ,
                     BRACKET_COSTING_IND            ,
                     VMI_ORDER_STATUS               ,
                     DSD_IND)
                    values (1212120000,
                            'Glassware Products Ltd.',
                            'Glassware Products Ltd. Secondary Name',
                            'Sue Glass',
                            '3122222473',
                            '3122222525',
                            '3122222672',
                            'A',
                            'Y', 10, 5,
                		'Y', 10, 5,
                            'USD',
                            NULL,
                            '02',
                            '01',
                            'Y', 'Y', 100.00, NULL, NULL, 'Y', 'Y', 'N', 'Y', 'D','N',
                            'N', 'Y',
                            NULL, NULL, NULL, 'N', NULL,
                            NULL, NULL, NULL,
                            'N' , 'N', 'N', NULL, 'N', 'N', 'N', 'N', L_vat_region ,'S','N',
                            'C','S','N','NEXT',NULL, 2, NULL, NULL, L_bracket_costing_ind, NULL,'N');
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1212120000', NULL, 1,
            '01', 'Y', '358 Findon Road', 'Kidman Park', NULL,
            'Adelaide', 'NV', L_country_id, '50250', 'Sue Glass',
            '3122222473', '3122222525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1212120000', NULL, 1,
            '02', 'Y', '358 Findon Road', 'Kidman Park', NULL,
            'Adelaide', 'NV', L_country_id, '50250', 'Sue Glass',
            '3122222473', '3122222525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);

   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1212120000', NULL, 1,
            '03', 'Y', '358 Findon Road', 'Kidman Park', NULL,
            'Adelaide', 'NV', L_country_id, '50250', 'Sue Glass',
            '3122222473', '3122222525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);

   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1212120000', NULL, 1,
            '04', 'Y', '358 Findon Road', 'Kidman Park', NULL,
            'Adelaide', 'NV', L_country_id, '50250', 'Sue Glass',
            '3122222473', '3122222525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);

   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1212120000', NULL, 1,
            '05', 'Y', '358 Findon Road', 'Kidman Park', NULL,
            'Adelaide', 'NV', L_country_id, '50250', 'Sue Glass',
            '3122222473', '3122222525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   --************************** SUPPLIER = 1313130000 ****
   ---
   insert into sups (SUPPLIER  ,
                     SUP_NAME                       ,
                     SUP_NAME_SECONDARY             ,
                     CONTACT_NAME                   ,
                     CONTACT_PHONE                  ,
                     CONTACT_FAX                    ,
                     CONTACT_PAGER                  ,
                     SUP_STATUS                     ,
                     QC_IND                         ,
                     QC_PCT                         ,
                     QC_FREQ                        ,
                     VC_IND                         ,
                     VC_PCT                         ,
                     VC_FREQ                        ,
                     CURRENCY_CODE                  ,
                     LANG                           ,
                     TERMS                          ,
                     FREIGHT_TERMS                  ,
                     RET_ALLOW_IND                  ,
                     RET_AUTH_REQ                   ,
                     RET_MIN_DOL_AMT                ,
                     RET_COURIER                    ,
                     HANDLING_PCT                   ,
                     EDI_PO_IND                     ,
                     EDI_PO_CHG                     ,
                     EDI_PO_CONFIRM                 ,
                     EDI_ASN                        ,
                     EDI_SALES_RPT_FREQ             ,
                     EDI_SUPP_AVAILABLE_IND         ,
                     EDI_CONTRACT_IND               ,
                     EDI_INVC_IND                   ,
                     EDI_CHANNEL_ID                 ,
                     COST_CHG_PCT_VAR               ,
                     COST_CHG_AMT_VAR               ,
                     REPLEN_APPROVAL_IND            ,
                     SHIP_METHOD                    ,
                     PAYMENT_METHOD                 ,
                     CONTACT_TELEX                  ,
                     CONTACT_EMAIL                  ,
                     SETTLEMENT_CODE                ,
                     PRE_MARK_IND                   ,
                     AUTO_APPR_INVC_IND             ,
                     DBT_MEMO_CODE                  ,
                     FREIGHT_CHARGE_IND             ,
                     AUTO_APPR_DBT_MEMO_IND         ,
                     PREPAY_INVC_IND                ,
                     BACKORDER_IND                  ,
                     VAT_REGION                     ,
                     INV_MGMT_LVL                   ,
                     SERVICE_PERF_REQ_IND           ,
                     INVC_PAY_LOC                   ,
                     INVC_RECEIVE_LOC               ,
                     ADDINVC_GROSS_NET              ,
                     DELIVERY_POLICY                ,
                     COMMENT_DESC                   ,
                     DEFAULT_ITEM_LEAD_TIME         ,
                     DUNS_NUMBER                    ,
                     DUNS_LOC                       ,
                     BRACKET_COSTING_IND            ,
                     VMI_ORDER_STATUS               ,
                     DSD_IND)
                     values (1313130000,
                            'Long March Shoe Company - Including Longer Description Value 012345678901234567890123456789012345678901234567890123456789012345678901234567980123456789012345678901234567980',
                            'Long March Shoe Company Secondary - Including Longer Description Value 012345678901234567890123456789012345678901234567890123456789012345678901234567980123456789012345678901234567980',
                            'Dennis S. March',
                            '2128355555',
                            '2128352525',
                            '2128355252',
                            'A',
                            'Y', 10, 5,
                            'Y', 10, 5,
                            'USD',
                            NULL,
                            '02',
                            '01',
                            'Y', 'Y', 100.00, NULL, NULL, 'Y', 'Y', 'N', 'Y', 'D','N',
                            'N', 'Y',
                            NULL, NULL, NULL, 'N', NULL,
                            NULL, NULL, NULL,
                            'N' , 'N', 'N', NULL, 'N', 'N', 'N', 'Y', L_vat_region , 'S', 'N',
                            'C','S','N','NEXT',NULL, 2, NULL, NULL, L_bracket_costing_ind, 'W','N');
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1313130000', NULL, 1,
            '01', 'Y', '305 Main Street', 'Suite 2605', NULL,
            'New York City', 'NY', L_country_id, '50250', 'Dennis S. March',
            '2128355555', '2128352525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1313130000', NULL, 1,
            '02', 'Y', '305 Main Street', 'Suite 2605', NULL,
            'New York City', 'NY', L_country_id, '50250', 'Dennis S. March',
            '2128355555', '2128352525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1313130000', NULL, 1,
            '03', 'Y', '305 Main Street', 'Suite 2605', NULL,
            'New York City', 'NY', L_country_id, '50250', 'Dennis S. March',
            '2128355555', '2128352525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1313130000', NULL, 1,
            '04', 'Y', '305 Main Street', 'Suite 2605', NULL,
            'New York City', 'NY', L_country_id, '50250', 'Dennis S. March',
            '2128355555', '2128352525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1313130000', NULL, 1,
            '05', 'Y', '305 Main Street', 'Suite 2605', NULL,
            'New York City', 'NY', L_country_id, '50250', 'Dennis S. March',
            '2128355555', '2128352525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   --*********************** SUPPLIER = 1234560000 ****
   ---
insert into sups (SUPPLIER  ,
                     SUP_NAME                       ,
                     SUP_NAME_SECONDARY             ,
                     CONTACT_NAME                   ,
                     CONTACT_PHONE                  ,
                     CONTACT_FAX                    ,
                     CONTACT_PAGER                  ,
                     SUP_STATUS                     ,
                     QC_IND                         ,
                     QC_PCT                         ,
                     QC_FREQ                        ,
                     VC_IND                         ,
                     VC_PCT                         ,
                     VC_FREQ                        ,
                     CURRENCY_CODE                  ,
                     LANG                           ,
                     TERMS                          ,
                     FREIGHT_TERMS                  ,
                     RET_ALLOW_IND                  ,
                     RET_AUTH_REQ                   ,
                     RET_MIN_DOL_AMT                ,
                     RET_COURIER                    ,
                     HANDLING_PCT                   ,
                     EDI_PO_IND                     ,
                     EDI_PO_CHG                     ,
                     EDI_PO_CONFIRM                 ,
                     EDI_ASN                        ,
                     EDI_SALES_RPT_FREQ             ,
                     EDI_SUPP_AVAILABLE_IND         ,
                     EDI_CONTRACT_IND               ,
                     EDI_INVC_IND                   ,
                     EDI_CHANNEL_ID                 ,
                     COST_CHG_PCT_VAR               ,
                     COST_CHG_AMT_VAR               ,
                     REPLEN_APPROVAL_IND            ,
                     SHIP_METHOD                    ,
                     PAYMENT_METHOD                 ,
                     CONTACT_TELEX                  ,
                     CONTACT_EMAIL                  ,
                     SETTLEMENT_CODE                ,
                     PRE_MARK_IND                   ,
                     AUTO_APPR_INVC_IND             ,
                     DBT_MEMO_CODE                  ,
                     FREIGHT_CHARGE_IND             ,
                     AUTO_APPR_DBT_MEMO_IND         ,
                     PREPAY_INVC_IND                ,
                     BACKORDER_IND                  ,
                     VAT_REGION                     ,
                     INV_MGMT_LVL                   ,
                     SERVICE_PERF_REQ_IND           ,
                     INVC_PAY_LOC                   ,
                     INVC_RECEIVE_LOC               ,
                     ADDINVC_GROSS_NET              ,
                     DELIVERY_POLICY                ,
                     COMMENT_DESC                   ,
                     DEFAULT_ITEM_LEAD_TIME         ,
                     DUNS_NUMBER                    ,
                     DUNS_LOC                       ,
                     BRACKET_COSTING_IND            ,
                     VMI_ORDER_STATUS               ,
                     DSD_IND)
                     values (1234560000,
                            'Max Brown Wholesales',
                            'Max Brown Wholesales Secondary Name',
                            'Max Brown Jr.',
                            '2024554676',
                            '2024552525',
                            '2024555252',
                            'A',
                            'Y', 10, 5,
                            'Y', 10, 5,
                            'USD',
                            NULL,
                            '02',
                            '01',
                            'Y', 'Y', 100.00, NULL, NULL, 'Y', 'Y', 'N', 'Y', 'D','N',
                            'N', 'Y',
                            NULL, NULL, NULL, 'N', NULL,
                            NULL, NULL, NULL,
                            'N' , 'N', 'N', NULL, 'N', 'N', 'N', 'N', L_vat_region, 'S', 'N',
                            'C','S','N','NEXT',NULL, 2, NULL, NULL, 'N', 'A','N');
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1234560000', NULL, 1,
            '01', 'Y', '4 Angas St.', NULL, NULL, 'Kent Town',
            'NE', L_country_id, '64035', 'Max Brown Jr.', '2024554676',
             '2024552525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1234560000', NULL, 1,
            '02', 'Y', '4 Angas St.', NULL, NULL, 'Kent Town',
            'NE', L_country_id, '64035', 'Max Brown Jr.', '2024554676',
             '2024552525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1234560000', NULL, 1,
            '03', 'Y', '4 Angas St.', NULL, NULL, 'Kent Town',
            'NE', L_country_id, '64035', 'Max Brown Jr.', '2024554676',
             '2024552525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1234560000', NULL, 1,
            '04', 'Y', '4 Angas St.', NULL, NULL, 'Kent Town',
            'NE', base_country_id, '64035', 'Max Brown Jr.', '2024554676',
             '2024552525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '1234560000', NULL, 1,
            '05', 'Y', '4 Angas St.', NULL, NULL, 'Kent Town',
            'NE', L_country_id, '64035', 'Max Brown Jr.', '2024554676',
             '2024552525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   -- Supplier name and address, and postal address to appear on Orders
   -- and as report headings.
   ---
   -- ********************* SUPPLIER = 5678900000 ****
   ---
   insert into sups (SUPPLIER  ,
                     SUP_NAME                       ,
                     SUP_NAME_SECONDARY             ,
                     CONTACT_NAME                   ,
                     CONTACT_PHONE                  ,
                     CONTACT_FAX                    ,
                     CONTACT_PAGER                  ,
                     SUP_STATUS                     ,
                     QC_IND                         ,
                     QC_PCT                         ,
                     QC_FREQ                        ,
                     VC_IND                         ,
                     VC_PCT                         ,
                     VC_FREQ                        ,
                     CURRENCY_CODE                  ,
                     LANG                           ,
                     TERMS                          ,
                     FREIGHT_TERMS                  ,
                     RET_ALLOW_IND                  ,
                     RET_AUTH_REQ                   ,
                     RET_MIN_DOL_AMT                ,
                     RET_COURIER                    ,
                     HANDLING_PCT                   ,
                     EDI_PO_IND                     ,
                     EDI_PO_CHG                     ,
                     EDI_PO_CONFIRM                 ,
                     EDI_ASN                        ,
                     EDI_SALES_RPT_FREQ             ,
                     EDI_SUPP_AVAILABLE_IND         ,
                     EDI_CONTRACT_IND               ,
                     EDI_INVC_IND                   ,
                     EDI_CHANNEL_ID                 ,
                     COST_CHG_PCT_VAR               ,
                     COST_CHG_AMT_VAR               ,
                     REPLEN_APPROVAL_IND            ,
                     SHIP_METHOD                    ,
                     PAYMENT_METHOD                 ,
                     CONTACT_TELEX                  ,
                     CONTACT_EMAIL                  ,
                     SETTLEMENT_CODE                ,
                     PRE_MARK_IND                   ,
                     AUTO_APPR_INVC_IND             ,
                     DBT_MEMO_CODE                  ,
                     FREIGHT_CHARGE_IND             ,
                     AUTO_APPR_DBT_MEMO_IND         ,
                     PREPAY_INVC_IND                ,
                     BACKORDER_IND                  ,
                     VAT_REGION                     ,
                     INV_MGMT_LVL                   ,
                     SERVICE_PERF_REQ_IND           ,
                     INVC_PAY_LOC                   ,
                     INVC_RECEIVE_LOC               ,
                     ADDINVC_GROSS_NET              ,
                     DELIVERY_POLICY                ,
                     COMMENT_DESC                   ,
                     DEFAULT_ITEM_LEAD_TIME         ,
                     DUNS_NUMBER                    ,
                     DUNS_LOC                       ,
                     BRACKET_COSTING_IND            ,
                     VMI_ORDER_STATUS               ,
                     DSD_IND)
                     values (5678900000,
                            'The Furniture Company P/L',
                            'The Furniture Company P/L',
                            'Sam Couch',
                            '5552340909',
                            '5552342525',
                            '5552345252',
                            'A',
                            'Y', 10, 5,
                            'Y', 10, 5,
                            'USD',
                            NULL,
                            '02',
                            '01',
                            'Y', 'Y', 100.00, NULL, NULL, 'Y', 'Y', 'N', 'Y', 'D','N',
                            'N', 'Y',
                            NULL, NULL, NULL, 'N', NULL,
                            NULL, NULL, NULL,
                            'N' , 'N', 'N', NULL, 'N', 'N', 'N', 'Y', L_vat_region, 'S', 'N',
                            'C','S','N','NEXT',NULL, 2, NULL, NULL, 'N', NULL,'N');
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '5678900000', NULL, 1,
            '01', 'Y', 'Industrial Park', '432 Main Road',
            'Suite 102', 'Smithfield', 'IL', L_country_id, '45048', 'Sam Couch',
            '5552340909', '5552342525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '5678900000', NULL, 1,
            '02', 'Y', 'Industrial Park', '432 Main Road',
            'Suite 102', 'Smithfield', 'IL', L_country_id, '45048', 'Sam Couch',
            '5552340909', '5552342525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '5678900000', NULL, 1,
            '03', 'Y', 'Industrial Park', '432 Main Road',
            'Suite 102', 'Smithfield', 'IL', L_country_id, '45048', 'Sam Couch',
            '5552340909', '5552342525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '5678900000', NULL, 1,
            '04', 'Y', 'Industrial Park', '432 Main Road',
            'Suite 102', 'Smithfield', 'IL', L_country_id, '45048', 'Sam Couch',
            '5552340909', '5552342525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '5678900000', NULL, 1,
            '05', 'Y', 'Industrial Park', '432 Main Road',
            'Suite 102', 'Smithfield', 'IL', L_country_id, '45048', 'Sam Couch',
            '5552340909', '5552342525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   -- Supplier name and address, and postal address to appear on Orders
   -- and as report headings.
   ---
   -- ************************ SUPPLIER = 2345670000 ***
   ---
   insert into sups (SUPPLIER  ,
                     SUP_NAME                       ,
                     SUP_NAME_SECONDARY             ,
                     CONTACT_NAME                   ,
                     CONTACT_PHONE                  ,
                     CONTACT_FAX                    ,
                     CONTACT_PAGER                  ,
                     SUP_STATUS                     ,
                     QC_IND                         ,
                     QC_PCT                         ,
                     QC_FREQ                        ,
                     VC_IND                         ,
                     VC_PCT                         ,
                     VC_FREQ                        ,
                     CURRENCY_CODE                  ,
                     LANG                           ,
                     TERMS                          ,
                     FREIGHT_TERMS                  ,
                     RET_ALLOW_IND                  ,
                     RET_AUTH_REQ                   ,
                     RET_MIN_DOL_AMT                ,
                     RET_COURIER                    ,
                     HANDLING_PCT                   ,
                     EDI_PO_IND                     ,
                     EDI_PO_CHG                     ,
                     EDI_PO_CONFIRM                 ,
                     EDI_ASN                        ,
                     EDI_SALES_RPT_FREQ             ,
                     EDI_SUPP_AVAILABLE_IND         ,
                     EDI_CONTRACT_IND               ,
                     EDI_INVC_IND                   ,
                     EDI_CHANNEL_ID                 ,
                     COST_CHG_PCT_VAR               ,
                     COST_CHG_AMT_VAR               ,
                     REPLEN_APPROVAL_IND            ,
                     SHIP_METHOD                    ,
                     PAYMENT_METHOD                 ,
                     CONTACT_TELEX                  ,
                     CONTACT_EMAIL                  ,
                     SETTLEMENT_CODE                ,
                     PRE_MARK_IND                   ,
                     AUTO_APPR_INVC_IND             ,
                     DBT_MEMO_CODE                  ,
                     FREIGHT_CHARGE_IND             ,
                     AUTO_APPR_DBT_MEMO_IND         ,
                     PREPAY_INVC_IND                ,
                     BACKORDER_IND                  ,
                     VAT_REGION                     ,
                     INV_MGMT_LVL                   ,
                     SERVICE_PERF_REQ_IND           ,
                     INVC_PAY_LOC                   ,
                     INVC_RECEIVE_LOC               ,
                     ADDINVC_GROSS_NET              ,
                     DELIVERY_POLICY                ,
                     COMMENT_DESC                   ,
                     DEFAULT_ITEM_LEAD_TIME         ,
                     DUNS_NUMBER                    ,
                     DUNS_LOC                       ,
                     BRACKET_COSTING_IND            ,
                     VMI_ORDER_STATUS               ,
                     DSD_IND)
                     values (2345670000,
                            'David Fashion Creations P/L',
                            'David Fashion Creations P/L Secondary Name',
                            'David Vogue',
                            '8087874312',
                            '8087872525',
                            '8087875252',
                            'A',
                            'Y', 10, 5,
                            'Y', 10, 5,
                            'USD',
                            NULL,
                            '02',
                            '01',
                            'Y', 'Y', 100.00, NULL, NULL, 'Y', 'Y', 'N', 'Y', 'D','N',
                            'N', 'Y',
                            NULL, NULL, NULL, 'N', NULL,
                            NULL, NULL, NULL,
                            'N' , 'N', 'N', NULL, 'N', 'N', 'N', 'N', L_vat_region, 'S','N',
                            'C','S','N','NEXT',NULL, 2, NULL, NULL, 'N', 'W','N');
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2345670000', NULL, 1,
            '01', 'Y', 'Wholesale Division', '109 Ackland St.',
            NULL, 'St. Kilda', 'VA', L_country_id, '30280', 'David Vogue',
            '8087874312', '8087872525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2345670000', NULL, 1,
            '02', 'Y', 'Wholesale Division', '109 Ackland St.',
            NULL, 'St. Kilda', 'VA', L_country_id, '30280', 'David Vogue',
            '8087874312', '8087872525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2345670000', NULL, 1,
            '03', 'Y', 'Wholesale Division', '109 Ackland St.',
            NULL, 'St. Kilda', 'VA', L_country_id, '30280', 'David Vogue',
            '8087874312', '8087872525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2345670000', NULL, 1,
            '04', 'Y', 'Wholesale Division', '109 Ackland St.',
            NULL, 'St. Kilda', 'VA', L_country_id, '30280', 'David Vogue',
            '8087874312', '8087872525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2345670000', NULL, 1,
            '05', 'Y', 'Wholesale Division', '109 Ackland St.',
            NULL, 'St. Kilda', 'VA', L_country_id, '30280', 'David Vogue',
            '8087874312', '8087872525',NULL,NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   -- Supplier name and address, and postal address to appear on Orders
   -- and as report headings
   ---
   -- ************************* SUPPLIER = 2222220000 ***
   ---
   insert into sups (SUPPLIER  ,
                     SUP_NAME                       ,
                     SUP_NAME_SECONDARY             ,
                     CONTACT_NAME                   ,
                     CONTACT_PHONE                  ,
                     CONTACT_FAX                    ,
                     CONTACT_PAGER                  ,
                     SUP_STATUS                     ,
                     QC_IND                         ,
                     QC_PCT                         ,
                     QC_FREQ                        ,
                     VC_IND                         ,
                     VC_PCT                         ,
                     VC_FREQ                        ,
                     CURRENCY_CODE                  ,
                     LANG                           ,
                     TERMS                          ,
                     FREIGHT_TERMS                  ,
                     RET_ALLOW_IND                  ,
                     RET_AUTH_REQ                   ,
                     RET_MIN_DOL_AMT                ,
                     RET_COURIER                    ,
                     HANDLING_PCT                   ,
                     EDI_PO_IND                     ,
                     EDI_PO_CHG                     ,
                     EDI_PO_CONFIRM                 ,
                     EDI_ASN                        ,
                     EDI_SALES_RPT_FREQ             ,
                     EDI_SUPP_AVAILABLE_IND         ,
                     EDI_CONTRACT_IND               ,
                     EDI_INVC_IND                   ,
                     EDI_CHANNEL_ID                 ,
                     COST_CHG_PCT_VAR               ,
                     COST_CHG_AMT_VAR               ,
                     REPLEN_APPROVAL_IND            ,
                     SHIP_METHOD                    ,
                     PAYMENT_METHOD                 ,
                     CONTACT_TELEX                  ,
                     CONTACT_EMAIL                  ,
                     SETTLEMENT_CODE                ,
                     PRE_MARK_IND                   ,
                     AUTO_APPR_INVC_IND             ,
                     DBT_MEMO_CODE                  ,
                     FREIGHT_CHARGE_IND             ,
                     AUTO_APPR_DBT_MEMO_IND         ,
                     PREPAY_INVC_IND                ,
                     BACKORDER_IND                  ,
                     VAT_REGION                     ,
                     INV_MGMT_LVL                   ,
                     SERVICE_PERF_REQ_IND           ,
                     INVC_PAY_LOC                   ,
                     INVC_RECEIVE_LOC               ,
                     ADDINVC_GROSS_NET              ,
                     DELIVERY_POLICY                ,
                     COMMENT_DESC                   ,
                     DEFAULT_ITEM_LEAD_TIME         ,
                     DUNS_NUMBER                    ,
                     DUNS_LOC                       ,
                     BRACKET_COSTING_IND            ,
                     VMI_ORDER_STATUS               ,
                     DSD_IND)
                     values (2222220000,
                            'Levi Strauss Pty Ltd',
                            'Levi Strauss Pty Ltd',
                            'Mel Bluejean',
                            '2124558989',
                            '2124552525',
                            '2124555252',
                            'A',
                            'Y', 10, 5,
                            'Y', 10, 5,
                            'USD',
                            NULL,
                            '02',
                            '01',
                            'Y', 'Y', 100.00, NULL, NULL, 'Y', 'Y', 'N', 'Y', 'D','N',
                            'N', 'Y',
                            NULL, NULL, NULL, 'N', NULL,
                            NULL, NULL, NULL,
                            'N' , 'N', 'N', NULL, 'N', 'N', 'N', 'N', L_vat_region, 'S', 'N',
                            'C','S','N','NEXT',NULL, 2, NULL, NULL, 'N', 'A','N');
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2222220000', NULL, 1,
            '01', 'Y', 'Wholesale Division', '36 Northeast Road',
            'Suite 458', 'Kent Town', 'NE', L_country_id, '50310',
            'Mel Bluejean','2124558989', '2124552525',NULL,
             NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2222220000', NULL, 1,
            '02', 'Y', 'Wholesale Division', '36 Northeast Road',
            'Suite 458', 'Kent Town', 'NE', L_country_id, '50310',
            'Mel Bluejean','2124558989', '2124552525',NULL,
             NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2222220000', NULL, 1,
            '03', 'Y', 'Wholesale Division', '36 Northeast Road',
            'Suite 458', 'Kent Town', 'NE', L_country_id, '50310',
            'Mel Bluejean','2124558989', '2124552525',NULL,
             NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2222220000', NULL, 1,
            '04', 'Y', 'Wholesale Division', '36 Northeast Road',
            'Suite 458', 'Kent Town', 'NE', L_country_id, '50310',
            'Mel Bluejean','2124558989', '2124552525',NULL,
             NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   insert into addr (select addr_sequence.nextval, 'SUPP', '2222220000', NULL, 1,
            '05', 'Y', 'Wholesale Division', '36 Northeast Road',
            'Suite 458', 'Kent Town', 'NE', L_country_id, '50310',
            'Mel Bluejean','2124558989', '2124552525',NULL,
             NULL,NULL,NULL,NULL,'N' from system_options);
   ---
   -- Supplier name and address, and postal address to appear on Orders
   -- and as report headings
   ---
   -- ************************ SUPPLIER = 1234500000 ****
   ---
      insert into sups (SUPPLIER  ,
                     SUP_NAME                       ,
                     SUP_NAME_SECONDARY             ,
                     CONTACT_NAME                   ,
                     CONTACT_PHONE                  ,
                     CONTACT_FAX                    ,
                     CONTACT_PAGER                  ,
                     SUP_STATUS                     ,
                     QC_IND                         ,
                     QC_PCT                         ,
                     QC_FREQ                        ,
                     VC_IND                         ,
                     VC_PCT                         ,
                     VC_FREQ                        ,
                     CURRENCY_CODE                  ,
                     LANG                           ,
                     TERMS                          ,
                     FREIGHT_TERMS                  ,
                     RET_ALLOW_IND                  ,
                     RET_AUTH_REQ                   ,
                     RET_MIN_DOL_AMT                ,
                     RET_COURIER                    ,
                     HANDLING_PCT                   ,
                     EDI_PO_IND                     ,
                     EDI_PO_CHG                     ,
                     EDI_PO_CONFIRM                 ,
                     EDI_ASN                        ,
                     EDI_SALES_RPT_FREQ             ,
                     EDI_SUPP_AVAILABLE_IND         ,
                     EDI_CONTRACT_IND               ,
                     EDI_INVC_IND                   ,
                     EDI_CHANNEL_ID                 ,
                     COST_CHG_PCT_VAR               ,
                     COST_CHG_AMT_VAR               ,
                     REPLEN_APPROVAL_IND            ,
                     SHIP_METHOD                    ,
                     PAYMENT_METHOD                 ,
                     CONTACT_TELEX                  ,
                     CONTACT_EMAIL                  ,
                     SETTLEMENT_CODE                ,
                     PRE_MARK_IND                   ,
                     AUTO_APPR_INVC_IND             ,
                     DBT_MEMO_CODE                  ,
                     FREIGHT_CHARGE_IND             ,
                     AUTO_APPR_DBT_MEMO_IND         ,
                     PREPAY_INVC_IND                ,
                     BACKORDER_IND                  ,
                     VAT_REGION                     ,
                     INV_MGMT_LVL                   ,
                     SERVICE_PERF_REQ_IND           ,
                     INVC_PAY_LOC                   ,
                     INVC_RECEIVE_LOC               ,
                     ADDINVC_GROSS_NET              ,
                     DELIVERY_POLICY                ,
                     COMMENT_DESC                   ,
                     DEFAULT_ITEM_LEAD_TIME         ,
                     DUNS_NUMBER                    ,
                     DUNS_LOC                       ,
                     BRACKET_COSTING_IND            ,
                     VMI_ORDER_STATUS               ,
                     DSD_IND)
                     values (1234500000,
                            'James Hardie Industries Ltd',
                            'James Hardie Industries Ltd',
                            'Joe Schmoe',
                            '2033339090',
                            '2033332525',
                            '2033335252',
                            'A',
                            'Y', 10, 5,
                            'Y', 10, 5,
                            'CAD',
                            NULL,
                            '02',
                            '01',
                            'Y', 'Y', 100.00, NULL, NULL, 'Y', 'Y', 'N', 'Y', 'D','N',
                            'N', 'Y',
                            NULL, NULL, NULL, 'N', NULL,
                            NULL, NULL, NULL,
                            'N' , 'N', 'N', NULL, 'N', 'N', 'N', 'Y', L_vat_region, 'S', 'N',
                            'C','S','N','NEXT',NULL, 2, NULL, NULL, L_bracket_costing_ind, NULL,'N');
   ---
   -- If the client is running with 2 character country codes then need to use 'CA' for Canada
   -- otherwise use 'CAN' for Canada.
   ---
   open C_GET_CANADA_COUNTRY_ID;
   fetch C_GET_CANADA_COUNTRY_ID into L_country_id;
   close C_GET_CANADA_COUNTRY_ID;
   ---
   insert into addr values (addr_sequence.nextval, 'SUPP', '1234500000', NULL, 1,
            '01', 'Y', '(Wholesale Division)', '1123 South Rd.',
            NULL, 'Clovelley Park', 'PE', L_country_id, '50490', 'Joe Schmoe',
            '2033339090', '2033332525',NULL,NULL,NULL,NULL,NULL,'N');
   ---
   insert into addr values (addr_sequence.nextval, 'SUPP', '1234500000', NULL, 1,
            '02', 'Y', '(Wholesale Division)', '1123 South Rd.',
            NULL, 'Clovelley Park', 'PE', L_country_id, '50490', 'Joe Schmoe',
            '2033339090', '2033332525',NULL,NULL,NULL,NULL,NULL,'N');
   ---
   insert into addr values (addr_sequence.nextval, 'SUPP', '1234500000', NULL, 1,
            '03', 'Y', '(Wholesale Division)', '1123 South Rd.',
            NULL, 'Clovelley Park', 'PE', L_country_id, '50490', 'Joe Schmoe',
            '2033339090', '2033332525',NULL,NULL,NULL,NULL,NULL,'N');
   ---
   insert into addr values (addr_sequence.nextval, 'SUPP', '1234500000', NULL, 1,
            '04', 'Y', '(Wholesale Division)', '1123 South Rd.',
            NULL, 'Clovelley Park', 'PE', L_country_id, '50490', 'Joe Schmoe',
            '2033339090', '2033332525',NULL,NULL,NULL,NULL,NULL,'N');
   ---
   insert into addr values (addr_sequence.nextval, 'SUPP', '1234500000', NULL, 1,
            '05', 'Y', '(Wholesale Division)', '1123 South Rd.',
            NULL, 'Clovelley Park', 'PE', L_country_id, '50490', 'Joe Schmoe',
            '2033339090', '2033332525',NULL,NULL,NULL,NULL,NULL,'N');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.SUPS_ADDR',
                                            to_char(SQLCODE));
      return FALSE;
END SUPS_ADDR;
--------------------------------------------------------------------------------------------
FUNCTION CAL454(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   -- Note - to change the date in the system, do not hard update the values
   -- on the period table - instead, run the batch program dtesys.pc
   ---
   insert into PERIOD values (1,
                              to_date('09-MAR-2001', 'DD-MM-YYYY'),
                              to_date('22-JAN-2001', 'DD-MM-YYYY'),
                              to_date('29-JUL-2001', 'DD-MM-YYYY'),
                              to_date('19-FEB-2001', 'DD-MM-YYYY'),
                              to_date('15-FEB-2001', 'DD-MM-YYYY'),
                              to_date('25-MAR-2001', 'DD-MM-YYYY'),
                              20011,
                              20012,
                              5,
                              3,
                              3,
                              2001,
                              2,
                              7);
   ---
   insert into calendar values(to_date('27-DEC-1993', 'DD-MON-YYYY'), 1994, 1, 4);
   insert into calendar values(to_date('24-JAN-1994', 'DD-MON-YYYY'), 1994, 2, 4);
   insert into calendar values(to_date('21-FEB-1994', 'DD-MON-YYYY'), 1994, 3, 5);
   insert into calendar values(to_date('28-MAR-1994', 'DD-MON-YYYY'), 1994, 4, 4);
   insert into calendar values(to_date('25-APR-1994', 'DD-MON-YYYY'), 1994, 5, 4);
   insert into calendar values(to_date('23-MAY-1994', 'DD-MON-YYYY'), 1994, 6, 5);
   insert into calendar values(to_date('27-JUN-1994', 'DD-MON-YYYY'), 1994, 7, 5);
   insert into calendar values(to_date('01-AUG-1994', 'DD-MON-YYYY'), 1994, 8, 4);
   insert into calendar values(to_date('29-AUG-1994', 'DD-MON-YYYY'), 1994, 9, 5);
   insert into calendar values(to_date('03-OCT-1994', 'DD-MON-YYYY'), 1994, 10, 4);
   insert into calendar values(to_date('31-OCT-1994', 'DD-MON-YYYY'), 1994, 11, 4);
   insert into calendar values(to_date('28-NOV-1994', 'DD-MON-YYYY'), 1994, 12, 5);
   insert into calendar values(to_date('02-JAN-1995', 'DD-MON-YYYY'), 1995, 1, 4);
   insert into calendar values(to_date('30-JAN-1995', 'DD-MON-YYYY'), 1995, 2, 4);
   insert into calendar values(to_date('27-FEB-1995', 'DD-MON-YYYY'), 1995, 3, 5);
   insert into calendar values(to_date('03-APR-1995', 'DD-MON-YYYY'), 1995, 4, 4);
   insert into calendar values(to_date('01-MAY-1995', 'DD-MON-YYYY'), 1995, 5, 4);
   insert into calendar values(to_date('29-MAY-1995', 'DD-MON-YYYY'), 1995, 6, 5);
   insert into calendar values(to_date('03-JUL-1995', 'DD-MON-YYYY'), 1995, 7, 4);
   insert into calendar values(to_date('31-JUL-1995', 'DD-MON-YYYY'), 1995, 8, 4);
   insert into calendar values(to_date('28-AUG-1995', 'DD-MON-YYYY'), 1995, 9, 5);
   insert into calendar values(to_date('02-OCT-1995', 'DD-MON-YYYY'), 1995, 10, 4);
   insert into calendar values(to_date('30-OCT-1995', 'DD-MON-YYYY'), 1995, 11, 4);
   insert into calendar values(to_date('27-NOV-1995', 'DD-MON-YYYY'), 1995, 12, 5);
   insert into calendar values(to_date('01-JAN-1996', 'DD-MON-YYYY'), 1996, 1, 4);
   insert into calendar values(to_date('29-JAN-1996', 'DD-MON-YYYY'), 1996, 2, 4);
   insert into calendar values(to_date('26-FEB-1996', 'DD-MON-YYYY'), 1996, 3, 5);
   insert into calendar values(to_date('01-APR-1996', 'DD-MON-YYYY'), 1996, 4, 4);
   insert into calendar values(to_date('29-APR-1996', 'DD-MON-YYYY'), 1996, 5, 4);
   insert into calendar values(to_date('27-MAY-1996', 'DD-MON-YYYY'), 1996, 6, 5);
   insert into calendar values(to_date('01-JUL-1996', 'DD-MON-YYYY'), 1996, 7, 4);
   insert into calendar values(to_date('29-JUL-1996', 'DD-MON-YYYY'), 1996, 8, 4);
   insert into calendar values(to_date('26-AUG-1996', 'DD-MON-YYYY'), 1996, 9, 5);
   insert into calendar values(to_date('30-SEP-1996', 'DD-MON-YYYY'), 1996, 10, 4);
   insert into calendar values(to_date('28-OCT-1996', 'DD-MON-YYYY'), 1996, 11, 4);
   insert into calendar values(to_date('25-NOV-1996', 'DD-MON-YYYY'), 1996, 12, 5);
   insert into calendar values(to_date('30-DEC-1996', 'DD-MON-YYYY'), 1997, 1, 4);
   insert into calendar values(to_date('27-JAN-1997', 'DD-MON-YYYY'), 1997, 2, 4);
   insert into calendar values(to_date('24-FEB-1997', 'DD-MON-YYYY'), 1997, 3, 5);
   insert into calendar values(to_date('31-MAR-1997', 'DD-MON-YYYY'), 1997, 4, 4);
   insert into calendar values(to_date('28-APR-1997', 'DD-MON-YYYY'), 1997, 5, 4);
   insert into calendar values(to_date('26-MAY-1997', 'DD-MON-YYYY'), 1997, 6, 5);
   insert into calendar values(to_date('30-JUN-1997', 'DD-MON-YYYY'), 1997, 7, 4);
   insert into calendar values(to_date('28-JUL-1997', 'DD-MON-YYYY'), 1997, 8, 4);
   insert into calendar values(to_date('25-AUG-1997', 'DD-MON-YYYY'), 1997, 9, 5);
   insert into calendar values(to_date('29-SEP-1997', 'DD-MON-YYYY'), 1997, 10, 4);
   insert into calendar values(to_date('27-OCT-1997', 'DD-MON-YYYY'), 1997, 11, 4);
   insert into calendar values(to_date('24-NOV-1997', 'DD-MON-YYYY'), 1997, 12, 5);
   insert into calendar values(to_date('29-DEC-1997', 'DD-MON-YYYY'), 1998, 1, 4);
   insert into calendar values(to_date('26-JAN-1998', 'DD-MON-YYYY'), 1998, 2, 4);
   insert into calendar values(to_date('23-FEB-1998', 'DD-MON-YYYY'), 1998, 3, 5);
   insert into calendar values(to_date('30-MAR-1998', 'DD-MON-YYYY'), 1998, 4, 4);
   insert into calendar values(to_date('27-APR-1998', 'DD-MON-YYYY'), 1998, 5, 4);
   insert into calendar values(to_date('25-MAY-1998', 'DD-MON-YYYY'), 1998, 6, 5);
   insert into calendar values(to_date('29-JUN-1998', 'DD-MON-YYYY'), 1998, 7, 4);
   insert into calendar values(to_date('27-JUL-1998', 'DD-MON-YYYY'), 1998, 8, 4);
   insert into calendar values(to_date('24-AUG-1998', 'DD-MON-YYYY'), 1998, 9, 5);
   insert into calendar values(to_date('28-SEP-1998', 'DD-MON-YYYY'), 1998, 10, 4);
   insert into calendar values(to_date('26-OCT-1998', 'DD-MON-YYYY'), 1998, 11, 4);
   insert into calendar values(to_date('23-NOV-1998', 'DD-MON-YYYY'), 1998, 12, 5);
   insert into calendar values(to_date('28-DEC-1998', 'DD-MON-YYYY'), 1999, 1, 4);
   insert into calendar values(to_date('25-JAN-1999', 'DD-MON-YYYY'), 1999, 2, 4);
   insert into calendar values(to_date('22-FEB-1999', 'DD-MON-YYYY'), 1999, 3, 5);
   insert into calendar values(to_date('29-MAR-1999', 'DD-MON-YYYY'), 1999, 4, 4);
   insert into calendar values(to_date('26-APR-1999', 'DD-MON-YYYY'), 1999, 5, 4);
   insert into calendar values(to_date('24-MAY-1999', 'DD-MON-YYYY'), 1999, 6, 5);
   insert into calendar values(to_date('28-JUN-1999', 'DD-MON-YYYY'), 1999, 7, 4);
   insert into calendar values(to_date('26-JUL-1999', 'DD-MON-YYYY'), 1999, 8, 4);
   insert into calendar values(to_date('23-AUG-1999', 'DD-MON-YYYY'), 1999, 9, 5);
   insert into calendar values(to_date('27-SEP-1999', 'DD-MON-YYYY'), 1999, 10, 4);
   insert into calendar values(to_date('25-OCT-1999', 'DD-MON-YYYY'), 1999, 11, 4);
   insert into calendar values(to_date('22-NOV-1999', 'DD-MON-YYYY'), 1999, 12, 5);
   insert into calendar values(to_date('27-DEC-1999', 'DD-MON-YYYY'), 2000, 1, 4);
   insert into calendar values(to_date('24-JAN-2000', 'DD-MON-YYYY'), 2000, 2, 4);
   insert into calendar values(to_date('21-FEB-2000', 'DD-MON-YYYY'), 2000, 3, 5);
   insert into calendar values(to_date('27-MAR-2000', 'DD-MON-YYYY'), 2000, 4, 4);
   insert into calendar values(to_date('24-APR-2000', 'DD-MON-YYYY'), 2000, 5, 4);
   insert into calendar values(to_date('22-MAY-2000', 'DD-MON-YYYY'), 2000, 6, 5);
   insert into calendar values(to_date('26-JUN-2000', 'DD-MON-YYYY'), 2000, 7, 4);
   insert into calendar values(to_date('24-JUL-2000', 'DD-MON-YYYY'), 2000, 8, 4);
   insert into calendar values(to_date('21-AUG-2000', 'DD-MON-YYYY'), 2000, 9, 5);
   insert into calendar values(to_date('25-SEP-2000', 'DD-MON-YYYY'), 2000, 10, 4);
   insert into calendar values(to_date('23-OCT-2000', 'DD-MON-YYYY'), 2000, 11, 4);
   insert into calendar values(to_date('20-NOV-2000', 'DD-MON-YYYY'), 2000, 12, 5);
   insert into calendar values(to_date('25-DEC-2000', 'DD-MON-YYYY'), 2001, 1, 4);
   insert into calendar values(to_date('22-JAN-2001', 'DD-MON-YYYY'), 2001, 2, 4);
   insert into calendar values(to_date('19-FEB-2001', 'DD-MON-YYYY'), 2001, 3, 5);
   insert into calendar values(to_date('26-MAR-2001', 'DD-MON-YYYY'), 2001, 4, 4);
   insert into calendar values(to_date('23-APR-2001', 'DD-MON-YYYY'), 2001, 5, 4);
   insert into calendar values(to_date('21-MAY-2001', 'DD-MON-YYYY'), 2001, 6, 5);
   insert into calendar values(to_date('25-JUN-2001', 'DD-MON-YYYY'), 2001, 7, 5);
   insert into calendar values(to_date('30-JUL-2001', 'DD-MON-YYYY'), 2001, 8, 4);
   insert into calendar values(to_date('27-AUG-2001', 'DD-MON-YYYY'), 2001, 9, 5);
   insert into calendar values(to_date('01-OCT-2001', 'DD-MON-YYYY'), 2001, 10, 4);
   insert into calendar values(to_date('29-OCT-2001', 'DD-MON-YYYY'), 2001, 11, 4);
   insert into calendar values(to_date('26-NOV-2001', 'DD-MON-YYYY'), 2001, 12, 5);
   insert into calendar values(to_date('31-DEC-2001', 'DD-MON-YYYY'), 2002, 1, 4);
   insert into calendar values(to_date('28-JAN-2002', 'DD-MON-YYYY'), 2002, 2, 4);
   insert into calendar values(to_date('25-FEB-2002', 'DD-MON-YYYY'), 2002, 3, 5);
   insert into calendar values(to_date('01-APR-2002', 'DD-MON-YYYY'), 2002, 4, 4);
   insert into calendar values(to_date('29-APR-2002', 'DD-MON-YYYY'), 2002, 5, 4);
   insert into calendar values(to_date('27-MAY-2002', 'DD-MON-YYYY'), 2002, 6, 5);
   insert into calendar values(to_date('01-JUL-2002', 'DD-MON-YYYY'), 2002, 7, 4);
   insert into calendar values(to_date('29-JUL-2002', 'DD-MON-YYYY'), 2002, 8, 4);
   insert into calendar values(to_date('26-AUG-2002', 'DD-MON-YYYY'), 2002, 9, 5);
   insert into calendar values(to_date('30-SEP-2002', 'DD-MON-YYYY'), 2002, 10, 4);
   insert into calendar values(to_date('28-OCT-2002', 'DD-MON-YYYY'), 2002, 11, 4);
   insert into calendar values(to_date('25-NOV-2002', 'DD-MON-YYYY'), 2002, 12, 5);
   insert into calendar values(to_date('30-DEC-2002', 'DD-MON-YYYY'), 2003, 1, 4);
   insert into calendar values(to_date('27-JAN-2003', 'DD-MON-YYYY'), 2003, 2, 4);
   insert into calendar values(to_date('24-FEB-2003', 'DD-MON-YYYY'), 2003, 3, 5);
   insert into calendar values(to_date('31-MAR-2003', 'DD-MON-YYYY'), 2003, 4, 4);
   insert into calendar values(to_date('28-APR-2003', 'DD-MON-YYYY'), 2003, 5, 4);
   insert into calendar values(to_date('26-MAY-2003', 'DD-MON-YYYY'), 2003, 6, 5);
   insert into calendar values(to_date('30-JUN-2003', 'DD-MON-YYYY'), 2003, 7, 4);
   insert into calendar values(to_date('28-JUL-2003', 'DD-MON-YYYY'), 2003, 8, 4);
   insert into calendar values(to_date('25-AUG-2003', 'DD-MON-YYYY'), 2003, 9, 5);
   insert into calendar values(to_date('29-SEP-2003', 'DD-MON-YYYY'), 2003, 10, 4);
   insert into calendar values(to_date('27-OCT-2003', 'DD-MON-YYYY'), 2003, 11, 4);
   insert into calendar values(to_date('24-NOV-2003', 'DD-MON-YYYY'), 2003, 12, 5);
   insert into calendar values(to_date('29-DEC-2003', 'DD-MON-YYYY'), 2004, 1, 4);
   ---
   insert into half values (19941, 'Summer 1994', 'Feb 1994 to Jul 1994');
   insert into half values (19942, 'Winter 1994', 'Aug 1994 to Jan 1995');
   insert into half values (19951, 'Summer 1995', 'Feb 1995 to Jul 1995');
   insert into half values (19952, 'Winter 1995', 'Aug 1995 to Jan 1996');
   insert into half values (19961, 'Summer 1996', 'Feb 1996 to Jul 1996');
   insert into half values (19962, 'Winter 1996', 'Aug 1996 to Jan 1997');
   insert into half values (19971, 'Summer 1997', 'Feb 1997 to Jul 1997');
   insert into half values (19972, 'Winter 1997', 'Aug 1997 to Jan 1998');
   insert into half values (19981, 'Summer 1998', 'Feb 1998 to Jul 1998');
   insert into half values (19982, 'Winter 1998', 'Aug 1998 to Jan 1999');
   insert into half values (19991, 'Summer 1999', 'Feb 1999 to Jul 1999');
   insert into half values (19992, 'Winter 1999', 'Aug 1999 to Jan 2000');
   insert into half values (20001, 'Summer 2000', 'Feb 2000 to Jul 2000');
   insert into half values (20002, 'Winter 2000', 'Aug 2000 to Jan 2001');
   insert into half values (20011, 'Summer 2001', 'Feb 2001 to Jul 2001');
   insert into half values (20012, 'Winter 2001', 'Aug 2001 to Jan 2002');
   insert into half values (20021, 'Summer 2002', 'Feb 2002 to Jul 2002');
   insert into half values (20022, 'Winter 2002', 'Aug 2002 to Jan 2003');
   insert into half values (20031, 'Summer 2003', 'Feb 2003 to Jul 2003');
   insert into half values (20032, 'Winter 2003', 'Aug 2003 to Jan 2004');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.CAL454',
                                            to_char(SQLCODE));
      return FALSE;
END CAL454;
--------------------------------------------------------------------------------------------
FUNCTION UDAS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   insert into UDA (DATA_LENGTH,
                    DATA_TYPE,
                    DISPLAY_TYPE,
                    MODULE,
                    SINGLE_VALUE_IND,
                    UDA_DESC,
                    UDA_ID)
             values('',
                    'ALPHA',
		    'LV',
                    'ITEM',
                    'N',
                    'Fabric Content',
                    '5232');
   ---
   insert into UDA (DATA_LENGTH,
                    DATA_TYPE,
                    DISPLAY_TYPE,
                    MODULE,
                    SINGLE_VALUE_IND,
                    UDA_DESC,
                    UDA_ID)
             values('',
                    'ALPHA',
		    'LV',
                    'ITEM',
                    'Y',
                    'Care Instructions',
                    '5233');
   ---
   insert into UDA (DATA_LENGTH,
                    DATA_TYPE,
                    DISPLAY_TYPE,
                    MODULE,
                    SINGLE_VALUE_IND,
                    UDA_DESC,
                    UDA_ID)
             values('250',
                    'ALPHA',
                    'FF',
                    'ITEM',
                    'N',
                    'Buyer Notes',
                    '5234');
   ---
   insert into UDA (DATA_LENGTH,
                    DATA_TYPE,
                    DISPLAY_TYPE,
                    MODULE,
                    SINGLE_VALUE_IND,
                    UDA_DESC,
                    UDA_ID)
             values('',
                    'DATE',
                    'DT',
                    'ITEM',
                    'Y',
                    'Estimated In Store Date',
                    '5235');
-----------------------------------------
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '1',
                          '100%cotton');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '2',
                          '100% wool');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '3',
                          '100% rayon');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '4',
                          '75 % cotton');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '5',
                          '75% wool');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '6',
                          '75% rayon');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '8',
                          '50% cotton');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '9',
                          '50% wool');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '10',
                          '50% rayon');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '11',
                          '25% cotton');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '12',
                          '25% wool');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5232',
                          '13',
                          '25% rayon');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5233',
                          '1',
                          'Dry Clean Only');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5233',
                          '2',
                          'Hand Wash, Line Dry');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5233',
                          '3',
                          'Machine wash warm with like colors, tumble dry low, low iron if needed');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5233',
                          '4',
                          'Machine wash cold with like colors, tumble dry low, low iron if needed');
   ---
   insert into UDA_values(UDA_ID,
                          UDA_VALUE,
                          UDA_VALUE_DESC)
                   values('5233',
                          '5',
                          'Machine was hot with like colors, tumble dry low, low iron if needed');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.UDAS',
                                            to_char(SQLCODE));
      return FALSE;
END UDAS;
--------------------------------------------------------------------------------------------
FUNCTION DIFFS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
---DIFF TYPES
---S = Size
---C = Color
---F = Flavor
---E = Scent
---P = Pattern


insert into diff_type values ('S',
                              'Size');

insert into diff_type values ('C',
                              'Color');

insert into diff_type values ('F',
                              'Flavor');

insert into diff_type values ('E',
                              'Scent');

insert into diff_type values ('P',
                              'Pattern');



---COLORS

   insert into diff_ids values ('COLOR 00', 'C', 'Assorted colour pack', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 01', 'C', 'Black', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 02', 'C', 'Oxford', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 03', 'C', 'Charcol', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 04', 'C', 'Grey', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 05', 'C', 'Dark Grey', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 06', 'C', 'Light Grey', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 07', 'C', 'Silver', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 08', 'C', 'Grey Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 09', 'C', 'Black Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 10', 'C', 'White', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 11', 'C', 'Ivory-Bone', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 12', 'C', 'Cream', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 13', 'C', 'Flesh-Nude', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 14', 'C', 'Neutral', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 15', 'C', 'Neutral Pattern', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 16', 'C', 'Sand', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 17', 'C', 'Pearl', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 18', 'C', 'White and Black', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 19', 'C', 'White Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 20', 'C', 'Brown', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 21', 'C', 'Dark Brown', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 22', 'C', 'Medium Brown', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 23', 'C', 'Light Brown-Taupe', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 24', 'C', 'Tan-Beige-Fawn', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 25', 'C', 'Honey-Camel', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 26', 'C', 'Toast', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 27', 'C', 'Bronze-Amber', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 28', 'C', 'Copper-Rust', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 29', 'C', 'Brown Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 30', 'C', 'Green', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 31', 'C', 'Dark Green-Moss-Olive', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 32', 'C', 'Medium Green-Holey', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 33', 'C', 'Bright Green-Emerald', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 34', 'C', 'Light Green-Lime', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 35', 'C', 'Chartreuse', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 36', 'C', 'Jute/Grass', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 39', 'C', 'Green Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 40', 'C', 'Blue', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 41', 'C', 'Navy', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 42', 'C', 'Dark Blue', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 43', 'C', 'Royal Blue-Sapphire', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 44', 'C', 'Medium Blue-Slate/Baby', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 45', 'C', 'Light Blue-Powder Blue', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 46', 'C', 'Teal-Turquoise-Aqua', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 47', 'C', 'Denim', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 49', 'C', 'Blue Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 50', 'C', 'Purple', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 51', 'C', 'Dark Purple', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 52', 'C', 'Medium Purple-Plum', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 53', 'C', 'Light Purple', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 54', 'C', 'Mauve', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 55', 'C', 'Lilac', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 56', 'C', 'Violet', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 59', 'C', 'Purple Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 60', 'C', 'Red', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 61', 'C', 'Dark Red-Wine-Ruby', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 62', 'C', 'Medium Red-Raspberry', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 63', 'C', 'Bright Red-Scarlet', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 64', 'C', 'Light Red', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 65', 'C', 'Rose', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 66', 'C', 'Pink', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 67', 'C', 'Peach', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 68', 'C', 'Medium Pink', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 69', 'C', 'Red Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 70', 'C', 'Gold-Yellow', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 71', 'C', 'Dark Yellow', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 72', 'C', 'Medium Yellow', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 73', 'C', 'Bright Yellow-Canary', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 74', 'C', 'Light Yellow-Maize', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 79', 'C', 'Yellow Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 80', 'C', 'Orange', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 81', 'C', 'Dark Orange', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 82', 'C', 'Medium Orange', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 83', 'C', 'Light Orange', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 84', 'C', 'Tangerine', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 85', 'C', 'Coral', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 89', 'C', 'Orange Patterned', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 90', 'C', 'Novelty', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 91', 'C', 'Red Fox/Nat', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 92', 'C', 'Red Freak', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 93', 'C', 'Watson', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 95', 'C', 'Noisette', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('COLOR 96', 'C', 'Dyed Fox', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));


---SIZES

INSERT into DIFF_IDS (CREATE_DATETIME, DIFF_DESC, DIFF_ID, DIFF_TYPE, INDUSTRY_CODE, INDUSTRY_SUBGROUP, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'32 Waist X30 Inseam'
                ,'32X30'
                ,'S'
                ,''
                ,''
                ,'27-JAN-02'
                ,'MMDEMO'
                );

INSERT into DIFF_IDS (CREATE_DATETIME, DIFF_DESC, DIFF_ID, DIFF_TYPE, INDUSTRY_CODE, INDUSTRY_SUBGROUP, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'32  Waist X32 Inseam'
                ,'32X32'
                ,'S'
                ,''
                ,''
                ,'27-JAN-02'
                ,'MMDEMO'
                );

INSERT into DIFF_IDS (CREATE_DATETIME, DIFF_DESC, DIFF_ID, DIFF_TYPE, INDUSTRY_CODE, INDUSTRY_SUBGROUP, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'34 Waist X30 Inseam'
                ,'34X30'
                ,'S'
                ,''
                ,''
                ,'27-JAN-02'
                ,'MMDEMO'
                );

INSERT into DIFF_IDS (CREATE_DATETIME, DIFF_DESC, DIFF_ID, DIFF_TYPE, INDUSTRY_CODE, INDUSTRY_SUBGROUP, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'34 Waist X32 Inseam'
                ,'34X32'
                ,'S'
                ,''
                ,''
                ,'27-JAN-02'
                ,'MMDEMO'
                );

INSERT into DIFF_IDS (CREATE_DATETIME, DIFF_DESC, DIFF_ID, DIFF_TYPE, INDUSTRY_CODE, INDUSTRY_SUBGROUP, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'34 Waist X34 Inseam'
                ,'34X34'
                ,'S'
                ,''
                ,''
                ,'27-JAN-02'
                ,'MMDEMO'
                );

INSERT into DIFF_IDS (CREATE_DATETIME, DIFF_DESC, DIFF_ID, DIFF_TYPE, INDUSTRY_CODE, INDUSTRY_SUBGROUP, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '20-NOV-01'
                ,'32 Waist X 34 Inseam'
                ,'32X34'
                ,'S'
                ,''
                ,''
                ,'27-JAN-02'
                ,'MMDEMO'
                );


   insert into diff_ids values ('SZ SMALL', 'S', 'Small', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ MEDIUM', 'S', 'Medium', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ LARGE', 'S', 'Large', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
    insert into diff_ids values ('SZ 02', 'S', '02', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ 04', 'S', '04', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ 06', 'S', '06', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ 08', 'S', '08', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ 10', 'S', '10', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ 12', 'S', '12', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ 14', 'S', '14', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ 16', 'S', '16', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SZ 18', 'S', '18', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));


---FLAVORS

   insert into diff_ids values ('FLAVOR 01', 'F', 'Vanilla', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('FLAVOR 02', 'F', 'Blueberry', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('FLAVOR 03', 'F', 'Strawberry', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('FLAVOR 04', 'F', 'Raspberry', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('FLAVOR 05', 'F', 'Mango', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('FLAVOR 06', 'F', 'Lime', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('FLAVOR 07', 'F', 'Lemon', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('FLAVOR 08', 'F', 'Orange', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('FLAVOR 09', 'F', 'Chocolate', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));


---SCENTS

   insert into diff_ids values ('SCENT 01', 'E', 'Spring Fresh', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SCENT 02', 'E', 'Summer Breeze', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SCENT 03', 'E', 'New Car', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SCENT 04', 'E', 'Classic Fresh', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('SCENT 05', 'E', 'Mountain Air', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));

---PATTERNS

   insert into diff_ids values ('PAT 01', 'P', 'Plaid', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('PAT 02', 'P', 'Polka Dot', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('PAT 03', 'P', 'Striped', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('PAT 04', 'P', 'Paisley', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));
   insert into diff_ids values ('PAT 05', 'P', 'Leopard', NULL, NULL,to_date('15-Jan-1995', 'DD_MM_YYYY'), 'MMDEMO', to_date('15-Jan-1995', 'DD_MM_YYYY'));

---DIFF GROUPS

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Men''s Pant Sizes'
                ,'MENS PANT'
                ,'S'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Women''s Basic Sizes'
                ,'WOMENS'
                ,'S'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Unisex Sizes'
                ,'UNISEX'
                ,'S'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Bright Colors'
                ,'BRIGHTS'
                ,'C'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Medium Colors'
                ,'MEDIUM'
                ,'C'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Light Colors'
                ,'LIGHTS'
                ,'C'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Basic Colors'
                ,'BASICS'
                ,'C'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Dark Colors'
                ,'DARKS'
                ,'C'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Fruit Flavors'
                ,'FRUIT'
                ,'F'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Standard Flavors'
                ,'STANDARD'
                ,'F'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Basic Scents'
                ,'BASICSCENT'
                ,'E'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_HEAD (CREATE_DATETIME, DIFF_GROUP_DESC, DIFF_GROUP_ID, DIFF_TYPE, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '27-JAN-02'
                ,'Basic Patterns'
                ,'BASICPAT'
                ,'P'
                ,'27-JAN-02'
                ,'MMDEMO'
                );



   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MENS PANT'
                ,'32X32'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MENS PANT'
                ,'32X34'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MENS PANT'
                ,'32X30'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MENS PANT'
                ,'34X30'
                ,'4'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MENS PANT'
                ,'34X32'
                ,'5'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MENS PANT'
                ,'34X34'
                ,'6'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 02'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 04'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 06'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 08'
                ,'4'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 10'
                ,'5'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 12'
                ,'6'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 14'
                ,'7'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 16'
                ,'8'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'WOMENS'
                ,'SZ 18'
                ,'9'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'UNISEX'
                ,'SZ SMALL'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'UNISEX'
                ,'SZ MEDIUM'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'UNISEX'
                ,'SZ LARGE'
                ,'3'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BRIGHTS'
                ,'COLOR 33'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BRIGHTS'
                ,'COLOR 63'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BRIGHTS'
                ,'COLOR 73'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MEDIUM'
                ,'COLOR 44'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MEDIUM'
                ,'COLOR 22'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MEDIUM'
                ,'COLOR 32'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MEDIUM'
                ,'COLOR 82'
                ,'4'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MEDIUM'
                ,'COLOR 68'
                ,'5'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MEDIUM'
                ,'COLOR 52'
                ,'6'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MEDIUM'
                ,'COLOR 62'
                ,'7'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'MEDIUM'
                ,'COLOR 72'
                ,'8'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'LIGHTS'
                ,'COLOR 45'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'LIGHTS'
                ,'COLOR 23'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'LIGHTS'
                ,'COLOR 34'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'LIGHTS'
                ,'COLOR 06'
                ,'4'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'LIGHTS'
                ,'COLOR 83'
                ,'5'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'LIGHTS'
                ,'COLOR 53'
                ,'6'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'LIGHTS'
                ,'COLOR 64'
                ,'7'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'LIGHTS'
                ,'COLOR 74'
                ,'8'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICS'
                ,'COLOR 01'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICS'
                ,'COLOR 10'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICS'
                ,'COLOR 60'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICS'
                ,'COLOR 41'
                ,'4'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICS'
                ,'COLOR 24'
                ,'5'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICS'
                ,'COLOR 03'
                ,'6'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICS'
                ,'COLOR 04'
                ,'7'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'DARKS'
                ,'COLOR 42'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'DARKS'
                ,'COLOR 21'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'DARKS'
                ,'COLOR 31'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'DARKS'
                ,'COLOR 05'
                ,'4'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'DARKS'
                ,'COLOR 81'
                ,'5'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'DARKS'
                ,'COLOR 51'
                ,'6'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'DARKS'
                ,'COLOR 61'
                ,'7'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'DARKS'
                ,'COLOR 71'
                ,'8'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'FRUIT'
                ,'FLAVOR 02'
                ,'4'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'FRUIT'
                ,'FLAVOR 07'
                ,'5'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'FRUIT'
                ,'FLAVOR 06'
                ,'6'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'FRUIT'
                ,'FLAVOR 05'
                ,'7'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'FRUIT'
                ,'FLAVOR 08'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'FRUIT'
                ,'FLAVOR 04'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'FRUIT'
                ,'FLAVOR 03'
                ,'1'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'STANDARD'
                ,'FLAVOR 01'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'STANDARD'
                ,'FLAVOR 09'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'STANDARD'
                ,'FLAVOR 03'
                ,'3'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICSCENT'
                ,'SCENT 04'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICSCENT'
                ,'SCENT 01'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICSCENT'
                ,'SCENT 02'
                ,'3'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICPAT'
                ,'PAT 05'
                ,'1'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICPAT'
                ,'PAT 01'
                ,'2'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICPAT'
                ,'PAT 04'
                ,'3'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICPAT'
                ,'PAT 02'
                ,'4'
                ,'27-JAN-02'
                ,'MMDEMO'
                );

   insert into DIFF_GROUP_DETAIL (CREATE_DATETIME, DIFF_GROUP_ID, DIFF_ID, DISPLAY_SEQ, LAST_UPDATE_DATETIME, LAST_UPDATE_ID)
values          (
                 '09-MAR-01'
                ,'BASICPAT'
                ,'PAT 03'
                ,'5'
                ,'09-MAR-01'
                ,'MMDEMO'
                );

RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.DIFFS',
                                            to_char(SQLCODE));
      RETURN FALSE;
END DIFFS;
--------------------------------------------------------------------------------------------
FUNCTION DEAL_COMP_TYPE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into DEAL_COMP_TYPE(DEAL_COMP_TYPE,
                              DEAL_COMP_TYPE_DESC)
                       values('VFC',
                              'Vendor Funded Coupon');
   ---
   insert into DEAL_COMP_TYPE(DEAL_COMP_TYPE,
                              DEAL_COMP_TYPE_DESC)
                       values('VOL',
                              'Volume Rebate');
   ---
   insert into DEAL_COMP_TYPE(DEAL_COMP_TYPE,
                              DEAL_COMP_TYPE_DESC)
                       values('TP',
                              'Temporary Deal');
   ---
   insert into DEAL_COMP_TYPE(DEAL_COMP_TYPE,
                              DEAL_COMP_TYPE_DESC)
                       values('OTHER',
                              'Other Deal Component Type');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.DEAL_COMP_TYPE',
                                            to_char(SQLCODE));
      return FALSE;
END DEAL_COMP_TYPE;
--------------------------------------------------------------------------------------------
FUNCTION DIVISION(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into division values (1000,'Homewares',1000,1000,25000);
   insert into division values (1001,'Fashion',  1001,1001,30000);
   insert into division values (1002,'Furniture',1002,1002,20000);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.DIVISION',
                                            to_char(SQLCODE));
      return FALSE;
END DIVISION;
--------------------------------------------------------------------------------------------
FUNCTION GROUPS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into groups values (1000,'Homewares', 1000,1000,1000);
   insert into groups values (1001,'Fashion',   1001,1001,1001);
   insert into groups values (1002,'Furniture', 1002,1002,1002);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.GROUPS',
                                            to_char(SQLCODE));
      return FALSE;
END GROUPS;
--------------------------------------------------------------------------------------------
FUNCTION DEPT(O_error_message IN OUT VARCHAR2,
              I_vat_ind       IN     VARCHAR2,
              I_vat_class_ind IN     VARCHAR2)
RETURN BOOLEAN IS
   L_dept_vat_incl_ind     DEPS.DEPT_VAT_INCL_IND%TYPE;

BEGIN
   if I_vat_ind = 'Y' then
      if I_vat_class_ind = 'Y' then
         L_dept_vat_incl_ind := 'N';
      else
         L_dept_vat_incl_ind := 'Y';
      end if;
   else
      L_dept_vat_incl_ind := 'N';
   end if;

  --************************** DEPARTMENT = 1221 *
   insert into deps
     (DEPT,
     DEPT_NAME,
     BUYER,
     MERCH,
     PROFIT_CALC_TYPE,
     PURCHASE_TYPE,
     GROUP_NO,
     BUD_INT,
     BUD_MKUP,
     TOTAL_MARKET_AMT,
     MARKUP_CALC_TYPE,
     OTB_CALC_TYPE,
     MAX_AVG_COUNTER,
     AVG_TOLERANCE_PCT,
  DEPT_VAT_INCL_IND)
       values (1221,
               'Kitchenware',
               1001,
               1002,
               2,
               0,
               1000,
               40.5,
               68.07,
               25000, 'R', 'R', 20, 70,
               L_dept_vat_incl_ind);

   --*************************** DEPARTMENT = 1234 ****
   insert into deps
     (DEPT,
     DEPT_NAME,
     BUYER,
     MERCH,
     PROFIT_CALC_TYPE,
     PURCHASE_TYPE,
     GROUP_NO,
     BUD_INT,
     BUD_MKUP,
     TOTAL_MARKET_AMT,
     MARKUP_CALC_TYPE,
     OTB_CALC_TYPE,
     MAX_AVG_COUNTER,
     AVG_TOLERANCE_PCT,
     DEPT_VAT_INCL_IND)
       values (1234,
               'Glassware',
               1000,
               1000,
               2,
               0,
               1000,
               38.0,
               61.29,
               25000, 'R', 'R', 20, 70,
               L_dept_vat_incl_ind);

   --***************************** DEPARTMENT = 2345 ****
   insert into deps
     (DEPT,
     DEPT_NAME,
     BUYER,
     MERCH,
     PROFIT_CALC_TYPE,
     PURCHASE_TYPE,
     GROUP_NO,
     BUD_INT,
     BUD_MKUP,
     TOTAL_MARKET_AMT,
     MARKUP_CALC_TYPE,
     OTB_CALC_TYPE,
     MAX_AVG_COUNTER,
     AVG_TOLERANCE_PCT,
     DEPT_VAT_INCL_IND)
       values (2345,
               'Small Appliances',
               1000,
               1000,
               2,
               0,
               1000,
               37.5,
               60.00,
               25000, 'R', 'R', 20, 70,
               L_dept_vat_incl_ind);
   --****************************** DEPARTMENT = 3456 ****
   insert into deps
     (DEPT,
     DEPT_NAME,
     BUYER,
     MERCH,
     PROFIT_CALC_TYPE,
     PURCHASE_TYPE,
     GROUP_NO,
     BUD_INT,
     BUD_MKUP,
     TOTAL_MARKET_AMT,
     MARKUP_CALC_TYPE,
     OTB_CALC_TYPE,
     MAX_AVG_COUNTER,
     AVG_TOLERANCE_PCT,
     DEPT_VAT_INCL_IND)
       values (3456,
               'Sportswear',
               1000,
               1000,
               2,
               0,
               1001,
               55.0,
               122.22,
               25000, 'R', 'R', 20, 70,
               L_dept_vat_incl_ind);
   --****************************** DEPARTMENT = 4567 ****
   insert into deps
     (DEPT,
     DEPT_NAME,
     BUYER,
     MERCH,
     PROFIT_CALC_TYPE,
     PURCHASE_TYPE,
     GROUP_NO,
     BUD_INT,
     BUD_MKUP,
     TOTAL_MARKET_AMT,
     MARKUP_CALC_TYPE,
     OTB_CALC_TYPE,
     MAX_AVG_COUNTER,
     AVG_TOLERANCE_PCT,
     DEPT_VAT_INCL_IND)
       values (4567,
               'Womens shoes',
               1001,
               1001,
               2,
               0,
               1002,
               55.0,
               122.22,
               25000, 'R', 'R', 20, 70,
               L_dept_vat_incl_ind);
   --****************************** DEPARTMENT = 5678 ****
   insert into deps
     (DEPT,
     DEPT_NAME,
     BUYER,
     MERCH,
     PROFIT_CALC_TYPE,
     PURCHASE_TYPE,
     GROUP_NO,
     BUD_INT,
     BUD_MKUP,
     TOTAL_MARKET_AMT,
     MARKUP_CALC_TYPE,
     OTB_CALC_TYPE,
     MAX_AVG_COUNTER,
     AVG_TOLERANCE_PCT,
     DEPT_VAT_INCL_IND)
       values (5678,
               'Furniture',
               1001,
               1001,
               2,
               0,
               1002,
               27.0,
               42.86,
               25000, 'R', 'R', 20, 70,
               L_dept_vat_incl_ind);
   --******************************* DEPARTMENT = 1313 *
   insert into deps
     (DEPT,
     DEPT_NAME,
     BUYER,
     MERCH,
     PROFIT_CALC_TYPE,
     PURCHASE_TYPE,
     GROUP_NO,
     BUD_INT,
     BUD_MKUP,
     TOTAL_MARKET_AMT,
     MARKUP_CALC_TYPE,
     OTB_CALC_TYPE,
     MAX_AVG_COUNTER,
     AVG_TOLERANCE_PCT,
     DEPT_VAT_INCL_IND)
       values (1313,
               'Outerware',
               1002,
               1002,
               2,
               0,
               1002,
               38,
               61.29,
               25000, 'R', 'R', 20, 70,
               L_dept_vat_incl_ind);
   --****************************** DEPARTMENT = 1414 *
   insert into deps
     (DEPT,
     DEPT_NAME,
     BUYER,
     MERCH,
     PROFIT_CALC_TYPE,
     PURCHASE_TYPE,
     GROUP_NO,
     BUD_INT,
     BUD_MKUP,
     TOTAL_MARKET_AMT,
     MARKUP_CALC_TYPE,
     OTB_CALC_TYPE,
     MAX_AVG_COUNTER,
     AVG_TOLERANCE_PCT,
     DEPT_VAT_INCL_IND)
       values (1414,
               'Activewear',
               1000,
               1000,
               2,
               0,
               1002,
               55,
               122.22,
               25000, 'R', 'R', 10, 40,
               L_dept_vat_incl_ind);
   ---
   if I_vat_ind = 'Y' then
      insert into vat_deps(select 1000,
                                  dept,
                                  'B',
                                  'S'
                             from deps);

   end if;
   ---
   insert into stock_ledger_inserts(select 'D',
                                           dept,
                                           null,
                                           null,
                                           null from deps);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.DEPT',
                                            to_char(SQLCODE));
      return FALSE;
END DEPT;
--------------------------------------------------------------------------------------------
FUNCTION CLASS_SUBCLASS(O_error_message IN OUT VARCHAR2,
                        I_vat_ind       IN     VARCHAR2,
                        I_vat_class_ind IN     VARCHAR2)
RETURN BOOLEAN IS
   L_class_vat_ind     CLASS.CLASS_VAT_IND%TYPE;

BEGIN
   if I_vat_ind = 'Y' then
      if I_vat_class_ind = 'Y' then
         L_class_vat_ind := 'N';
      else
         L_class_vat_ind := 'Y';
      end if;
   else
      L_class_vat_ind := 'N';
   end if;

   --*************************Dept 1221  Classes/Subclasses
   insert into class values (1221,1000,'Utensils',L_class_vat_ind);
   --15-Feb-2008 WiproEnabler/Ramasamy - Modified to insert the columns names before inserting the values to subclass table- Mod N113 -Begin
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1221,1000,1000,'Gadgets');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1221,1000,1001,'Can Openers');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1221,1000,1002,'Strainers');
   --*************************Dept 1234  Classes/Subclasses
   insert into class values (1234,1000,'Dining',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1000,'Bowls');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1001,'Plates');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1002,'Imported Glasses');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1003,'Wine');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1004,'Champagne');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1005,'Spirits');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1006,'Sherrys');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1007,'Liqueur');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1008,'Budget Glasses');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1009,'Decanters');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1000, 1010,'Crown Corning');
   ---
   insert into class values (1234,1001,'Decoration',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1001,1000,'Jugs');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1001,1001,'Vases');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1001,1002,'Boda');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1001,1003,'Orrefors');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1001,1004,'Ornaments');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1234,1001,1005,'Gifts');
   --*****************Dept 2345  Classes/Subclasses
   insert into class values (2345,1000,'Kitchen Appliances',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (2345,1000,1000,'Coffee Pots');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (2345,1000,1001,'Blenders');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (2345,1000,1002,'Food Processers');
   ---
   insert into class values (2345,1001,'Bathroom Appliances',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (2345,1001,1000,'Mens Shavers');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (2345,1001,1001,'Ladies Shavers');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (2345,1001,1002,'Hair Dryers');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (2345,1001,1003,'Curling Irons');
   --********************Dept 3456  Classes/Subclasses
   insert into class values (3456,1000,'Casual',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (3456,1000,1000,'Skirts');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (3456,1000,1001,'Basic Blouses');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (3456,1000,1002,'Jeans');
   ---
   insert into class values (3456,1001,'Business',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (3456,1001,1000,'Skirts');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (3456,1001,1001,'Pants');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (3456,1001,1002,'Better Blouses');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (3456,1001,1003,'Jackets');
   --*******************Dept 4567  Classes/Subclasses
   insert into class values (4567,1000,'Business',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (4567,1000,1000,'Pumps');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (4567,1000,1001,'Flats');
   ---
   insert into class values (4567,1001,'Casual',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (4567,1001,1000,'Slingbacks');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (4567,1001,1001,'Sandals');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (4567,1001,1002,'Boots');
   ---
   insert into class values (4567,1002,'Sport',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (4567,1002,1000,'Cross Trainers');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (4567,1002,1001,'Running Shoes');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (4567,1002,1002,'Tennis Shoes');
   --************************Dept 5678  Classes/Subclasses
   insert into class values (5678,1000,'Lounge Suites',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (5678,1000,1000,'Leather');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (5678,1000,1001,'Cotton');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (5678,1000,1002,'Wool/Woolmix');
   ---
   insert into class values (5678,1001,'Dining Sets',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (5678,1001,1000,'Formal Dining');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (5678,1001,1001,'Kitchen Dinette');
   ---
   insert into class values (5678,1002,'Bedroom Sets',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (5678,1002,1000,'Childrens Bedrooms');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (5678,1002,1001,'Single Beds');
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (5678,1002,1002,'Double/Queen Beds');
   --**********************Dept 1414  Classes/Subclasses
   insert into class values (1414,1000,'Sports Clothes',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1414,1000,1000,'Mens Sports Clothes');
   --***********************Dept 1313  Classes/Subclasses
   insert into class values (1313,1000,'Cold Weather',L_class_vat_ind);
   insert into subclass (DEPT,CLASS,SUBCLASS,SUB_NAME) values (1313,1000,1000,'Cold Weather - Women');
      --15-Feb-2008 WiproEnabler/Ramasamy - Modified to insert the columns names before inserting the values to subclass table- Mod N113 -End

   ---
   -- Create stock ledger inserts records.
   ---
   insert into stock_ledger_inserts(type_code,
                                    dept,
                                    class,
                                    subclass,
                                    location)
                             select 'B',
                                    dept,
                                    class,
                                    subclass,
                                    NULL
                               from subclass;


   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.CLASS_SUBCLASS',
                                            to_char(SQLCODE));
      return FALSE;
END CLASS_SUBCLASS;
--------------------------------------------------------------------------------------------
FUNCTION RPM_MERCH_HIER(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_zone_group_id    rpm_zone_group.zone_group_id%type := null;
   L_zone_id          rpm_zone.zone_id%type             := null;

BEGIN

   select rpm_zone_group_seq.nextval into L_zone_group_id from dual;

   insert into RPM_ZONE_GROUP(ZONE_GROUP_ID,
                              ZONE_GROUP_DISPLAY_ID,
                              NAME,
                              LOCK_VERSION)
                      values (L_zone_group_id,
                              L_zone_group_id,
                              'All Locations',
                              NULL);
   ---
   insert into RPM_ZONE_GROUP_TYPE(ZONE_GROUP_ID,
                                   TYPE,
                                   LOCK_VERSION)
                           values (L_zone_group_id,
                                   2,
                                   NULL);
   ---
   --- USD zone
   select rpm_zone_seq.nextval into L_zone_id from dual;
   insert into RPM_ZONE(ZONE_ID,
                        ZONE_DISPLAY_ID,
                        ZONE_GROUP_ID,
                        NAME,
                        CURRENCY_CODE,
                        BASE_IND,
                        LOCK_VERSION)
                values (L_zone_id,
                        L_zone_id,
                        L_zone_group_id,
                        'USD locations',
                        'USD',
                        1,
                        NULL);
   ---
   insert into RPM_ZONE_LOCATION(ZONE_LOCATION_ID,
                                 ZONE_ID,
                                 LOCATION,
                                 LOC_TYPE,
                                 LOCK_VERSION)
                          select rpm_zone_location_seq.nextval,
                                 L_zone_id,
                                 store,
                                 0,
                                 NULL
                            from store
                           where currency_code = 'USD';
   ---
   insert into RPM_ZONE_LOCATION(ZONE_LOCATION_ID,
                                 ZONE_ID,
                                 LOCATION,
                                 LOC_TYPE,
                                 LOCK_VERSION)
                          select rpm_zone_location_seq.nextval,
                                 L_zone_id,
                                 wh,
                                 1,
                                 NULL
                            from wh
                           where currency_code = 'USD'
                             and stockholding_ind  = 'Y';
   ---
   --- CAD zone
   select rpm_zone_seq.nextval into L_zone_id from dual;
   insert into RPM_ZONE(ZONE_ID,
                        ZONE_DISPLAY_ID,
                        ZONE_GROUP_ID,
                        NAME,
                        CURRENCY_CODE,
                        BASE_IND,
                        LOCK_VERSION)
                values (L_zone_id,
                        L_zone_id,
                        L_zone_group_id,
                        'CAD locations',
                        'CAD',
                        0,
                        NULL);
   ---
   insert into RPM_ZONE_LOCATION(ZONE_LOCATION_ID,
                                 ZONE_ID,
                                 LOCATION,
                                 LOC_TYPE,
                                 LOCK_VERSION)
                          select rpm_zone_location_seq.nextval,
                                 L_zone_id,
                                 store,
                                 0,
                                 NULL
                            from store
                           where currency_code = 'CAD';
   ---
   insert into RPM_ZONE_LOCATION(ZONE_LOCATION_ID,
                                 ZONE_ID,
                                 LOCATION,
                                 LOC_TYPE,
                                 LOCK_VERSION)
                          select rpm_zone_location_seq.nextval,
                                 L_zone_id,
                                 wh,
                                 1,
                                 NULL
                            from wh
                           where currency_code = 'CAD'
                             and stockholding_ind  = 'Y';
   ---
   --- AUD zone
   select rpm_zone_seq.nextval into L_zone_id from dual;
   insert into RPM_ZONE(ZONE_ID,
                        ZONE_DISPLAY_ID,
                        ZONE_GROUP_ID,
                        NAME,
                        CURRENCY_CODE,
                        BASE_IND,
                        LOCK_VERSION)
                values (L_zone_id,
                        L_zone_id,
                        L_zone_group_id,
                        'AUD locations',
                        'AUD',
                        0,
                        NULL);
   ---
   insert into RPM_ZONE_LOCATION(ZONE_LOCATION_ID,
                                 ZONE_ID,
                                 LOCATION,
                                 LOC_TYPE,
                                 LOCK_VERSION)
                          select rpm_zone_location_seq.nextval,
                                 L_zone_id,
                                 store,
                                 0,
                                 NULL
                            from store
                           where currency_code = 'AUD';
   ---
   insert into RPM_ZONE_LOCATION(ZONE_LOCATION_ID,
                                 ZONE_ID,
                                 LOCATION,
                                 LOC_TYPE,
                                 LOCK_VERSION)
                          select rpm_zone_location_seq.nextval,
                                 L_zone_id,
                                 wh,
                                 1,
                                 NULL
                            from wh
                           where currency_code = 'AUD'
                             and stockholding_ind  = 'Y';
   ---

      insert into RPM_MERCH_RETAIL_DEF (MERCH_RETAIL_DEF_ID,
                                        MERCH_TYPE,
                                        DEPT,
                                        CLASS,
                                        SUBCLASS,
                                        REGULAR_ZONE_GROUP,
                                        CLEARANCE_ZONE_GROUP,
                                        MARKUP_CALC_TYPE,
                                        MARKUP_PERCENT,
                                        LOCK_VERSION)
      select RPM_MERCH_RETAIL_DEF_seq.nextval,
             3,
             d.dept, null, null,
             L_zone_group_id, null, 1, 46, 0
        from deps d;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.RPM_MERCH_HIER',
                                            to_char(SQLCODE));
      return FALSE;
END RPM_MERCH_HIER;
--------------------------------------------------------------------------------------------
FUNCTION PO_TYPE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into PO_TYPE(PO_TYPE,
                       PO_TYPE_DESC)
                values('1000',
                       'Valentine''s Day Sales');
   ---
   insert into PO_TYPE(PO_TYPE,
                       PO_TYPE_DESC)
                values('2000',
                       'Christmas Sales');
   ---
   insert into PO_TYPE(PO_TYPE,
                       PO_TYPE_DESC)
                values('3000',
                       'Father''s Day Sale');
   ---
   insert into PO_TYPE(PO_TYPE,
                       PO_TYPE_DESC)
                values('4000',
                       'Back to School');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.PO_TYPE',
                                            to_char(SQLCODE));
      return FALSE;
END PO_TYPE;
--------------------------------------------------------------------------------------------
FUNCTION PRICE_ZONE(O_error_message     IN OUT VARCHAR2,
                    I_multichannel_ind  IN     VARCHAR2)
RETURN BOOLEAN IS


   L_primary_zone_group       STORE.STORE%TYPE;

   cursor GET_STORE_FOR_PRIMARY is
   select min(store)
     from store;

BEGIN

   ---
   insert into price_zone (select 1,
                                  store,
                                  'N',
                                  store_name,
                                  currency_code
                             from store);
   ---
   if I_multichannel_ind = 'Y' then
      insert into price_zone(zone_group_id,
                             zone_id,
                             base_retail_ind,
                             description,
                             currency_code)
                            (select 1,
                                   wh,
                                   'N',
                                   wh_name,
                                   currency_code
                              from wh
                                   where physical_wh != wh);

      ---
   else
       insert into price_zone(zone_group_id,
                             zone_id,
                             base_retail_ind,
                             description,
                             currency_code)
                            (select 1,
                                   wh,
                                   'N',
                                   wh_name,
                                   currency_code
                              from wh
                                   where physical_wh = wh);
   end if;
   ---
   open GET_STORE_FOR_PRIMARY;
   fetch GET_STORE_FOR_PRIMARY into L_primary_zone_group;
   close GET_STORE_FOR_PRIMARY;
   ---
   update price_zone
      set base_retail_ind = 'Y'
    where zone_group_id   = 1
      and zone_id         = L_primary_zone_group;
   ---
   ---
   --Create price_zone and price_zone_group_store records
   ---
   insert into price_zone_group_store(zone_group_id,
                                      store,
                                      zone_id,
                                      primary_ind,
                                      publish_ind)
                                      (select 1,
                                       store,
                                       store,
                                       'Y',
                                       'N' from store);
   if I_multichannel_ind = 'Y' then
      ---
      --Stockholding virtual whs should also be on the price_zone_group_store table
      ---
      insert into price_zone_group_store(zone_group_id,
                                         store,
                                         zone_id,
                                         primary_ind,
                                         publish_ind)
                                        (select 1,
                                                wh,
                                                wh,
                                                'Y',
                                                'N'
                                           from wh
                                          where wh != physical_wh
                                            and stockholding_ind = 'Y');
   else
        insert into price_zone_group_store(zone_group_id,
                                            store,
                                            zone_id,
                                            primary_ind,
                                            publish_ind)
                                           (select 1,
                                                   wh,
                                                   wh,
                                                   'Y',
                                                   'N'
                                              from wh);
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.PRICE_ZONE',
                                            to_char(SQLCODE));
      return FALSE;
END PRICE_ZONE;
--------------------------------------------------------------------------------------------
FUNCTION COST_ZONE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_primary_zone_group       STORE.STORE%TYPE;

   cursor GET_STORE_FOR_PRIMARY is
   select min(store)
     from store;

BEGIN
   insert into cost_zone_group values (1000,
                                       'L',
                                       'Location Zone Group');
   ---
   insert into cost_zone (select 1000,
                                 store,
                                 store_name,
                                 currency_code,
                                 'N'
                            from store);

   insert into cost_zone (select 1000,
                                 wh,
                                 wh_name,
                                 currency_code,
                                 'N'
                            from wh
                           where wh = physical_wh);
   ---
   update cost_zone
      set base_cost_ind = 'Y'
    where zone_group_id = 1000
      and zone_id       = 1000000000;
   ---
   insert into cost_zone_group_loc (select 1000,
                                           store,
                                           'S',
                                           store
                                      from store);
   ---
   insert into cost_zone_group_loc (select 1000,
                                           wh,
                                           'W',
                                           physical_wh
                                      from wh,
                                           cost_zone cz
                                     where wh.physical_wh = cz.zone_id);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.COST_ZONE',
                                            to_char(SQLCODE));
      return FALSE;
END COST_ZONE;
--------------------------------------------------------------------------------------------
FUNCTION OUTLOC(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into OUTLOC(CONTACT_EMAIL,
                      CONTACT_FAX,
                      CONTACT_NAME,
                      CONTACT_PHONE,
                      CONTACT_TELEX,
                      OUTLOC_ADD1,
                      OUTLOC_ADD2,
                      OUTLOC_CITY,
                      OUTLOC_COUNTRY_ID,
                      OUTLOC_CURRENCY,
                      OUTLOC_DESC,
                      OUTLOC_ID,
                      OUTLOC_POST,
                      OUTLOC_STATE,
                      OUTLOC_TYPE,
                      OUTLOC_VAT_REGION)
               select '','','','','','','','',
                      base_country_id,
                      'USD',
                      'Default Bill to Location',
                      '1000','','','BT',''
                 from system_options;
   ---
   insert into OUTLOC(CONTACT_EMAIL,
                      CONTACT_FAX,
                      CONTACT_NAME,
                      CONTACT_PHONE,
                      CONTACT_TELEX,
                      OUTLOC_ADD1,
                      OUTLOC_ADD2,
                      OUTLOC_CITY,
                      OUTLOC_COUNTRY_ID,
                      OUTLOC_CURRENCY,
                      OUTLOC_DESC,
                      OUTLOC_ID,
                      OUTLOC_POST,
                      OUTLOC_STATE,
                      OUTLOC_TYPE,
                      OUTLOC_VAT_REGION)
               select '','','','','',
                      '7899 Ocean Drive','',
                      'Punta Cana',
                      base_country_id,
                      'DOP','Punta Cana',
                      '479','','','DP',''
                 from system_options;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.OUTLOC',
                                            to_char(SQLCODE));
      return FALSE;
END OUTLOC;
--------------------------------------------------------------------------------------------
FUNCTION RTK_ROLE_PRIVS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into RTK_ROLE_PRIVS(ORD_APPR_AMT,
                              ROLE,
                              TSF_APPR_IND)
                       values('99999999999',
                              'RETEK_DEVELOPER',
                              'Y');
   ---
   insert into RTK_ROLE_PRIVS(ORD_APPR_AMT,
                              ROLE,
                              TSF_APPR_IND)
                       values('99999999999',
                              'DEVELOPER',
                              'Y');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.RTK_ROLE_PRIVS',
                                            to_char(SQLCODE));
      return FALSE;
END RTK_ROLE_PRIVS;
-----------------------------------------------------------------
FUNCTION ELC_COMP_EXPENSES(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_elc_ind   VARCHAR2(1) := 'N';

   cursor C_ELC_IND is
      select elc_ind
        from system_options;

BEGIN
   open c_ELC_IND;
   fetch C_ELC_IND into L_elc_ind;
   close C_ELC_IND;
   ---
   if L_elc_ind = 'Y' then
      insert into elc_comp (comp_id,
                            comp_desc,
                            comp_type,
                            assess_type,
                            import_country_id,
                            expense_type,
                            cvb_code,
                            calc_basis,
                            cost_basis,
                            exp_category,
                            comp_rate,
                            comp_level,
                            display_order,
                            always_default_ind,
                            comp_currency,
                            per_count,
                            per_count_uom,
                            nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                    values ('AGCOMM',
                            'Agent Commission',
                            'E',
                            NULL,
                            NULL,
                            'C',
                            NULL,
                            'V',
                            'O',
                            'M',
                            2.5,
                            1,
                            1,
                            'N',
                            'USD',
                            NULL,
                            NULL,
                            'N','N','N','+','N');
      ---
      insert into elc_comp (comp_id,
                            comp_desc,
                            comp_type,
                            assess_type,
                            import_country_id,
                            expense_type,
                            cvb_code,
                            calc_basis,
                            cost_basis,
                            exp_category,
                            comp_rate,
                            comp_level,
                            display_order,
                            always_default_ind,
                            comp_currency,
                            per_count,
                            per_count_uom,
                            nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                    values ('ILFRT',
                            'Inland Freight',
                            'E',
                            NULL,
                            NULL,
                            'Z',
                            NULL,
                            'S',
                            NULL,
                            'M',
                            .75,
                            1,
                            1,
                            'N',
                            'USD',
                            1,
                            'EA',
                            'N','N','N','+','N');
      ---
      insert into elc_comp (comp_id,
                            comp_desc,
                            comp_type,
                            assess_type,
                            import_country_id,
                            expense_type,
                            cvb_code,
                            calc_basis,
                            cost_basis,
                            exp_category,
                            comp_rate,
                            comp_level,
                            display_order,
                            always_default_ind,
                            comp_currency,
                            per_count,
                            per_count_uom,
                            nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                    values ('BUYCOMM',
                            'Buyer Commission',
                            'E',
                            NULL,
                            NULL,
                            'C',
                            NULL,
                            'V',
                            'O',
                            'M',
                            1.5,
                            1,
                            1,
                            'N',
                            'USD',
                            NULL,
                            NULL,
                            'N','N','N','+','N');
      ---
      insert into elc_comp (comp_id,
                            comp_desc,
                            comp_type,
                            assess_type,
                            import_country_id,
                            expense_type,
                            cvb_code,
                            calc_basis,
                            cost_basis,
                            exp_category,
                            comp_rate,
                            comp_level,
                            display_order,
                            always_default_ind,
                            comp_currency,
                            per_count,
                            per_count_uom,
                            nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                    values ('OCFRT',
                            'Ocean Freight',
                            'E',
                            NULL,
                            NULL,
                            'C',
                            NULL,
                            'S',
                            NULL,
                            'M',
                            1.75,
                            1,
                            1,
                            'N',
                            'USD',
                            1,
                            'EA',
                            'N','N','N','+','N');
      ---
      insert into elc_comp (comp_id,
                            comp_desc,
                            comp_type,
                            assess_type,
                            import_country_id,
                            expense_type,
                            cvb_code,
                            calc_basis,
                            cost_basis,
                            exp_category,
                            comp_rate,
                            comp_level,
                            display_order,
                            always_default_ind,
                            comp_currency,
                            per_count,
                            per_count_uom,
                            nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                    values ('INSUR',
                            'Insurance',
                            'E',
                            NULL,
                            NULL,
                            'Z',
                            NULL,
                            'V',
                            'O',
                            'M',
                            3.2,
                            1,
                            1,
                            'N',
                            'USD',
                            NULL,
                            NULL,
                            'N','N','N','+','N');
      ---
      insert into cvb_head (cvb_code,
                            cvb_desc,
                            nom_flag_1,
                            nom_flag_2,
                            nom_flag_3,
                            nom_flag_4,
                            nom_flag_5)
                    values ('SELLCOMM',
                            'Seller Commission CVB',
                            'N','N','N','N','N');
      ---
      insert into cvb_detail (cvb_code,
                              comp_id,
                              combo_oper)
                       select 'SELLCOMM',
                              'ORDCST',
                              '+'
                         from elc_comp
                        where comp_id = 'ORDCST';
      ---
      insert into cvb_detail (cvb_code,
                              comp_id,
                              combo_oper)
                      values ('SELLCOMM',
                              'OCFRT',
                              '+');
      ---
      insert into cvb_detail (cvb_code,
                              comp_id,
                              combo_oper)
                      values ('SELLCOMM',
                              'INSUR',
                              '+');
      ---
      insert into elc_comp (comp_id,
                            comp_desc,
                            comp_type,
                            assess_type,
                            import_country_id,
                            expense_type,
                            cvb_code,
                            calc_basis,
                            cost_basis,
                            exp_category,
                            comp_rate,
                            comp_level,
                            display_order,
                            always_default_ind,
                            comp_currency,
                            per_count,
                            per_count_uom,
                            nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                    values ('SELLCOMM',
                            'Seller Commission',
                            'E',
                            NULL,
                            NULL,
                            'C',
                            'SELLCOMM',
                            'V',
                            NULL,
                            'M',
                            10,
                            3,
                            2,
                            'N',
                            'USD',
                            NULL,
                            NULL,
                            'N','N','N','+','N');
      ---
      update elc_comp set comp_rate = .21  where comp_id like 'MPF%';
      update elc_comp set comp_rate = .125 where comp_id like 'HMF%';
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.ELC_COMP_EXPENSES',
                                            to_char(SQLCODE));
      return FALSE;
END ELC_COMP_EXPENSES;
--------------------------------------------------------------------------------------------
FUNCTION BACKHAUL_ALLOWANCE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'BAPAL',
                        'Backhaul Allowance per Pallet',
                        'E',
                        NULL,
                        NULL,
                        'Z',
                        NULL,
                        'S',
                        NULL,
                        'B',
                        50,
                        1,
                        1,
                        'N',
                        'USD',
                        1,
                        'PAL',
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'BACWT',
                        'Backhaul Allowance per Hundred Weight',
                        'E',
                        NULL,
                        NULL,
                        'Z',
                        NULL,
                        'S',
                        NULL,
                        'B',
                        2,
                        1,
                        1,
                        'N',
                        'USD',
                        100,
                        'LBS',
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'BAEA',
                        'Backhaul Allowance per Each',
                        'E',
                        NULL,
                        NULL,
                        'Z',
                        NULL,
                        'S',
                        NULL,
                        'B',
                        .1,
                        1,
                        1,
                        'N',
                        'USD',
                        1,
                        'EA',
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'BACS',
                        'Backhaul Allowance per Case',
                        'E',
                        NULL,
                        NULL,
                        'Z',
                        NULL,
                        'S',
                        NULL,
                        'B',
                        .5,1,
                        1,
                        'N',
                        'USD',
                        1,
                        'CS',
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'BACFT',
                        'Backhaul Allowance per Cubic Feet',
                        'E',
                        NULL,
                        NULL,
                        'Z',
                        NULL,
                        'S',
                        NULL,
                        'B',
                        2,
                        1,
                        1,
                        'N',
                        'USD',
                        1,
                        'CFT',
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.BACKHAUL_ALLOWANCE',
                                            to_char(SQLCODE));
      return FALSE;
END BACKHAUL_ALLOWANCE;
--------------------------------------------------------------------------------------------
FUNCTION UP_CHARGE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        up_chrg_type,
                        up_chrg_group,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'TSFFRGHT',
                        'Transfer Freight',
                        'U',
                        NULL,
                        NULL,
                        NULL,
                        'E',
                        'F',
                        NULL,
                        'V',
                        NULL,
                        NULL,
                        2.5,
                        1,
                        1,
                        'N',
                        'USD',
                        NULL,
                        NULL,
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        up_chrg_type,
                        up_chrg_group,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'TSFINSUR',
                        'Transfer Insurance',
                        'U',
                        NULL,
                        NULL,
                        NULL,
                        'E',
                        'M',
                        NULL,
                        'V',
                        NULL,
                        NULL,
                        1.5,
                        1,
                        1,
                        'N',
                        'USD',
                        NULL,
                        NULL,
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        up_chrg_type,
                        up_chrg_group,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'WHFEE',
                        'Warehouse Storage Fee',
                        'U',
                        NULL,
                        NULL,
                        NULL,
                        'P',
                        'A',
                        NULL,
                        'S',
                        NULL,
                        NULL,
                        10,
                        1,
                        1,
                        'N',
                        'USD',
                        1,
                        'CBM',
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   insert into elc_comp(comp_id,
                        comp_desc,
                        comp_type,
                        assess_type,
                        import_country_id,
                        expense_type,
                        up_chrg_type,
                        up_chrg_group,
                        cvb_code,
                        calc_basis,
                        cost_basis,
                        exp_category,
                        comp_rate,
                        comp_level,
                        display_order,
                        always_default_ind,
                        comp_currency,
                        per_count,
                        per_count_uom,
                        nom_flag_1,nom_flag_2,nom_flag_3,nom_flag_4,nom_flag_5)
                 select 'WHPROC',
                        'Warehouse Processing Fee',
                        'U',
                        NULL,
                        NULL,
                        NULL,
                        'P',
                        'A',
                        NULL,
                        'V',
                        NULL,
                        NULL,
                        3,
                        1,
                        1,
                        'N',
                        'USD',
                        NULL,
                        NULL,
                        'N','N','N','N','N'
                   from system_options
                  where elc_ind = 'Y';
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.UP_CHARGE',
                                            to_char(SQLCODE));
      return FALSE;
END UP_CHARGE;
--------------------------------------------------------------------------------------------
FUNCTION FREIGHT_TYPE_SIZE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into freight_size(freight_size,
                            freight_size_desc)
                     values('20',
                            '20 Foot Container');
   ---
   insert into freight_size(freight_size,
                            freight_size_desc)
                     values('40',
                            '40 Foot Container');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.FREIGHT_TYPE_SIZE',
                                            to_char(SQLCODE));
      return FALSE;
END FREIGHT_TYPE_SIZE;
--------------------------------------------------------------------------------------------
FUNCTION DOC(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   insert into doc (doc_id,
                    doc_desc,
                    doc_type,
                    lc_ind,
                    swift_tag,
                    seq_no,
                    text)
             values(1,
                    'Required Document',
                    'REQ',
                    'Y',
                    '46B',
                    1,
                    'Forwarder'||'''s cargo receipt and one copy issued by union transport evidencing receipt of merchandise for shipment to the Cato Corp., 8100 Denmark Road, Charlotte, NC 28273, marked notify same, and stating that one complete set of original documents and 4 complete sets of copies of documents have been received from the beneficiary.');
   ---
   insert into doc (doc_id,
                    doc_desc,
                    doc_type,
                    lc_ind,
                    swift_tag,
                    seq_no,
                    text)
             values(2,
                    'Additional Instructions',
                    'AI',
                    'Y',
                    '47B',
                    2,
                    'Inspection certificate signed by a rep of Excel Handbags.');
   ---
   insert into doc (doc_id,
                    doc_desc,
                    doc_type,
                    lc_ind,
                    swift_tag,
                    seq_no,
                    text)
             values(3,
                    'Sender Instructions',
                    'SI',
                    'Y',
                    '72',
                    3,
                    'Commercial Invoice in triplicate. Packing List in original plus one copy. Packing List must state that no solid wood packing material has been used.');
   ---
   insert into doc (doc_id,
                    doc_desc,
                    doc_type,
                    lc_ind,
                    swift_tag,
                    seq_no,
                    text)
             values(4,
                    'Charges',
                    'AI',
                    'Y',
                    '71B',
                    4,
                    'All banking charges except the Issuing Bank'||'''s charges are for account of Beneficiary.');
   ---
   insert into doc (doc_id,
                    doc_desc,
                    doc_type,
                    lc_ind,
                    swift_tag,
                    seq_no,
                    text)
             values(5,
                    'Bank Instructions',
                    'BI',
                    'Y',
                    '78',
                    5,
                    'Single or Multi-currency textile declaration of origin when required.');
   ---
   -- Insert additional DOC_LINK records
   ---
   insert into doc_link values ('LC',  'AI');
   insert into doc_link values ('LCA', 'AI');
   insert into doc_link values ('IT',  'AI');
   insert into doc_link values ('PO',  'AI');
   insert into doc_link values ('POIT','AI');
   insert into doc_link values ('LC',  'BI');
   insert into doc_link values ('LCA', 'BI');
   insert into doc_link values ('IT',  'BI');
   insert into doc_link values ('PO',  'BI');
   insert into doc_link values ('POIT','BI');
   insert into doc_link values ('LC',  'CS');
   insert into doc_link values ('LCA', 'CS');
   insert into doc_link values ('IT',  'CS');
   insert into doc_link values ('PO',  'CS');
   insert into doc_link values ('POIT','CS');
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.DOC',
                                            to_char(SQLCODE));
      return FALSE;
END DOC;
-------------------------------------------------------------------------------------------------------
FUNCTION TERMS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'01', 'Term 1', '2.5% 30 Days', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'02', 'Term 2', '1.5% 30 Days', 2);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'03', 'Term 3', '3.5% 15 Days', 3);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'04', 'Term 4', 'Net 30 Days', 4);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'05', 'Term 5', '2.5% Monthly', 5);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'06', 'Term 6', '1.5% Monthly', 6);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'07', 'Term 7', 'Net Monthly', 7);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'42', '42', '01 003.00% 015 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'114', '114', '01 003.00% 015 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'124', '124', '01 003.00% 020 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'2', '2', '01 003.00% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'82', '82', '01 003.00% 030 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'7', '7', '01 003.00% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'83', '83', '01 003.00% 045 046', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'144', '144', '01 003.00% 060 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'84', '84', '01 004.00% 010 090', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'93', '93', '01 004.00% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'9', '9', '01 004.00% 045 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'80', '80', '01 005.00% 010 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'11', '11', '01 005.00% 025 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'76', '76', '01 005.00% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'46', '46', '01 005.00% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'145', '145', '01 005.00% 030 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'50', '50', '01 005.00% 030 061', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'24', '24', '01 005.00% 060 061', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'19', '19', '01 006.00% 020 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'20', '20', '01 007.00% 000 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'85', '85', '01 010.00% 010 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'77', '77', '01 015.00% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'13', '13', '00 000.00% 000 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'48', '48', '01 000.00% 000 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'146', '146', '02 000.00% 000 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'149', '149', '09 Accept Invoice Terms', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'162', '162', '01 000.00% 000 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'107', '107', '02 000.00% 001 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'60', '60', '01 000.00% 005 005', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'122', '122', '01 000.00% 007 007', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'8', '8', '02 000.00% 010 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'29', '29', '03 000.00% 010 010', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'49', '49', '01 000.00% 010 010', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'30', '30', '03 000.00% 010 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'113', '113', '01 000.00% 014 014', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'129', '129', '02 000.00% 015 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'68', '68', '01 000.00% 015 015', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'58', '58', '01 000.00% 020 020', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'34', '34', '01 000.00% 021 021', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'40', '40', '01 000.00% 025 025', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'86', '86', '01 000.00% 028 028', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'147', '147', '02 000.00% 030 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'3', '3', '01 000.00% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'78', '78', '03 000.00% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'54', '54', '01 000.00% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'74', '74', '01 000.00% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'164', '164', '01 000.00% 030 300', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'57', '57', '01 000.00% 035 035', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'64', '64', '01 000.00% 040 040', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'79', '79', '01 000.00% 042 042', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'132', '132', '01 000.00% 045 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'5', '5', '01 000.00% 045 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'130', '130', '01 000.00% 050 050', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'26', '26', '01 000.00% 055 055', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'6', '6', '01 000.00% 060 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'133', '133', '01 000.00% 060 061', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'4', '4', '01 000.00% 075 075', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'36', '36', '01 000.00% 080 080', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'150', '150', '01 000.00% 085 085', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'21', '21', '01 000.00% 090 090', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'23', '23', '01 000.00% 105 105', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'103', '103', '01 000.00% 120 120', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'155', '155', '01 000.00% 180 180', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'131', '131', '01 000.00% 730 730', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'134', '134', '01 000.10% 090 090', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'18', '18', '01 000.25% 025 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'135', '135', '01 000.25% 045 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'53', '53', '01 000.50% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'105', '105', '01 000.50% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'109', '109', '01 000.67% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'110', '110', '01 000.83% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'136', '136', '01 000.87% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'137', '137', '01 000.87% 060 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'108', '108', '02 001.00% 010 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'102', '102', '01 001.00% 010 020', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'69', '69', '01 001.00% 010 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'89', '89', '01 001.00% 010 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'95', '95', '01 001.00% 010 090', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'71', '71', '01 001.00% 015 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'56', '56', '01 001.00% 015 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'111', '111', '01 001.00% 015 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'65', '65', '01 001.00% 020 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'126', '126', '01 001.00% 020 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'66', '66', '01 001.00% 020 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'156', '156', '01 001.00% 025 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'91', '91', '01 001.00% 029 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'116', '116', '01 001.00% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'38', '38', '01 001.00% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'14', '14', '01 001.00% 030 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'35', '35', '01 001.00% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'163', '163', '01 001.00% 045 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'97', '97', '01 001.00% 045 046', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'94', '94', '01 001.00% 045 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'90', '90', '01 001.00% 060 061', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'92', '92', '01 001.00% 060 070', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'158', '158', '01 001.10% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'157', '157', '01 001.10% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'119', '119', '01 001.25% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'100', '100', '01 001.42% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'101', '101', '01 001.45% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'106', '106', '02 001.48% 010 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'81', '81', '01 001.50% 010 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'123', '123', '01 001.50% 015 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'104', '104', '01 001.50% 015 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'37', '37', '01 001.50% 020 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'138', '138', '01 001.50% 025 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'63', '63', '01 001.50% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'161', '161', '01 001.50% 030 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'153', '153', '01 001.50% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'127', '127', '01 001.50% 045 046', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'139', '139', '01 001.50% 060 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'27', '27', '01 001.51% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'140', '140', '01 001.53% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'125', '125', '02 001.75% 010 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'159', '159', '02 001.75% 015 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'99', '99', '01 001.90% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'39', '39', '02 002.00% 010 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'75', '75', '03 002.00% 010 010', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'51', '51', '01 002.00% 010 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'70', '70', '01 002.00% 010 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'52', '52', '01 002.00% 010 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'118', '118', '01 002.00% 014 015', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'44', '44', '02 002.00% 015 000', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'73', '73', '01 002.00% 015 015', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'72', '72', '01 002.00% 015 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'59', '59', '01 002.00% 015 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'55', '55', '01 002.00% 015 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'128', '128', '01 002.00% 017 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'22', '22', '01 002.00% 020 021', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'33', '33', '01 002.00% 020 035', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'32', '32', '01 002.00% 020 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'117', '117', '01 002.00% 020 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'152', '152', '01 002.00% 025 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'151', '151', '01 002.00% 025 035', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'141', '141', '01 002.00% 025 040', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'67', '67', '01 002.00% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'17', '17', '01 002.00% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'98', '98', '01 002.00% 030 040', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'16', '16', '01 002.00% 030 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'31', '31', '01 002.00% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'45', '45', '01 002.00% 030 090', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'28', '28', '01 002.00% 033 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'115', '115', '01 002.00% 035 036', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'154', '154', '01 002.00% 044 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'62', '62', '01 002.00% 045 045', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'15', '15', '01 002.00% 045 046', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'47', '47', '01 002.00% 045 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'112', '112', '01 002.00% 045 090', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'43', '43', '01 002.00% 060 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'41', '41', '01 002.00% 060 061', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'88', '88', '01 002.00% 060 090', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'87', '87', '01 002.00% 090 090', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'96', '96', '01 002.00% 120 121', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'121', '121', '01 002.00% 365 365', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'120', '120', '01 002.02% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'12', '12', '01 002.05% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'142', '142', '01 002.10% 030 031', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'61', '61', '01 002.15% 030 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'10', '10', '01 002.38% 024 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'160', '160', '01 002.38% 060 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'143', '143', '01 002.48% 024 030', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'1', '1', '01 002.50% 030 060', 1);
INSERT INTO TERMS_HEAD ( TERMS, TERMS_CODE, TERMS_DESC, RANK ) VALUES (
'25', '25', '01 003.00% 010 030', 1);
---

INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'01', 1, 30, 1000000, 1, 12, 0, 2.5, 2, 11, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'02', 1, 30, 1000000, 1, 12, 0, 1.5, 2, 11, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'03', 1, 15, 1000000, 1, 12, 0, 3.5, 2, 11, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'04', 1, 30, 1000000, 1, 12, 0, 0, 2, 11, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'05', 1, 30, 1000000, 1, 12, 0, 2.5, 2, 11, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'06', 1, 30, 1000000, 1, 12, 0, 1.5, 2, 11, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'07', 1, 30, 1000000, 1, 12, 0, 0, 2, 11, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'05', 2, 30, 1, 1, 1, 30, 2.5, 1, 1, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'06', 3, 30, 1, 1, 1, 30, 1.5, 1, 1, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'07', 4, 30, 1, 1, 1, 30, 0, 1, 1, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'42', 5, 30, 1, 1, 1, 15, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'114', 6, 60, 1, 1, 1, 15, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'124', 7, 45, 1, 1, 1, 20, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'2', 8, 31, 1, 1, 1, 30, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'82', 9, 45, 1, 1, 1, 30, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'7', 10, 60, 1, 1, 1, 30, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'83', 11, 46, 1, 1, 1, 45, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'144', 12, 60, 1, 1, 1, 60, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'84', 13, 90, 1, 1, 1, 10, 4, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'93', 14, 60, 1, 1, 1, 30, 4, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'9', 15, 45, 1, 1, 1, 45, 4, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'80', 16, 30, 1, 1, 1, 10, 5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'11', 17, 30, 1, 1, 1, 25, 5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'76', 18, 30, 1, 1, 1, 30, 5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'46', 19, 31, 1, 1, 1, 30, 5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'145', 20, 45, 1, 1, 1, 30, 5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'50', 21, 61, 1, 1, 1, 30, 5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'24', 22, 61, 1, 1, 1, 60, 5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'19', 23, 60, 1, 1, 1, 20, 6, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'20', 24, 0, 1, 1, 1, 0, 7, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'85', 25, 30, 1, 1, 1, 10, 10, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'77', 26, 31, 1, 1, 1, 30, 15, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'13', 27, 0, 1, 1, 1, 0, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'48', 28, 0, 1, 1, 1, 0, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'146', 29, 0, 1, 1, 1, 0, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'149', 30, 0, 1, 1, 1, 0, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'162', 31, 60, 1, 1, 1, 0, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'107', 32, 0, 1, 1, 1, 1, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'60', 33, 5, 1, 1, 1, 5, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'122', 34, 7, 1, 1, 1, 7, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'8', 35, 0, 1, 1, 1, 10, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'29', 36, 10, 1, 1, 1, 10, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'49', 37, 10, 1, 1, 1, 10, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'30', 38, 30, 1, 1, 1, 10, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'113', 39, 14, 1, 1, 1, 14, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'129', 40, 0, 1, 1, 1, 15, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'68', 41, 15, 1, 1, 1, 15, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'58', 42, 20, 1, 1, 1, 20, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'34', 43, 21, 1, 1, 1, 21, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'40', 44, 25, 1, 1, 1, 25, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'86', 45, 28, 1, 1, 1, 28, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'147', 46, 0, 1, 1, 1, 30, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'3', 47, 30, 1, 1, 1, 30, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'78', 48, 30, 1, 1, 1, 30, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'54', 49, 31, 1, 1, 1, 30, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'74', 50, 60, 1, 1, 1, 30, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'164', 51, 300, 1, 1, 1, 30, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'57', 52, 35, 1, 1, 1, 35, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'64', 53, 40, 1, 1, 1, 40, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'79', 54, 42, 1, 1, 1, 42, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'132', 55, 0, 1, 1, 1, 45, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'5', 56, 45, 1, 1, 1, 45, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'130', 57, 50, 1, 1, 1, 50, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'26', 58, 55, 1, 1, 1, 55, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'6', 59, 60, 1, 1, 1, 60, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'133', 60, 61, 1, 1, 1, 60, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'4', 61, 75, 1, 1, 1, 75, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'36', 62, 80, 1, 1, 1, 80, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'150', 63, 85, 1, 1, 1, 85, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'21', 64, 90, 1, 1, 1, 90, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'23', 65, 105, 1, 1, 1, 105, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'103', 66, 120, 1, 1, 1, 120, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'155', 67, 180, 1, 1, 1, 180, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'131', 68, 730, 1, 1, 1, 730, 0, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'134', 69, 90, 1, 1, 1, 90, 0.1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'18', 70, 30, 1, 1, 1, 25, 0.25, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'135', 71, 45, 1, 1, 1, 45, 0.25, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'53', 72, 30, 1, 1, 1, 30, 0.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'105', 73, 31, 1, 1, 1, 30, 0.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'109', 74, 30, 1, 1, 1, 30, 0.67, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'110', 75, 30, 1, 1, 1, 30, 0.83, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'136', 76, 30, 1, 1, 1, 30, 0.87, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'137', 77, 60, 1, 1, 1, 60, 0.87, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'108', 78, 0, 1, 1, 1, 10, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'102', 79, 20, 1, 1, 1, 10, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'69', 80, 30, 1, 1, 1, 10, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'89', 81, 60, 1, 1, 1, 10, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'95', 82, 90, 1, 1, 1, 10, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'71', 83, 30, 1, 1, 1, 15, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'56', 84, 45, 1, 1, 1, 15, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'111', 85, 60, 1, 1, 1, 15, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'65', 86, 30, 1, 1, 1, 20, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'126', 87, 45, 1, 1, 1, 20, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'66', 88, 60, 1, 1, 1, 20, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'156', 89, 45, 1, 1, 1, 25, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'91', 90, 30, 1, 1, 1, 29, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'116', 91, 30, 1, 1, 1, 30, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'38', 92, 31, 1, 1, 1, 30, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'14', 93, 45, 1, 1, 1, 30, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'35', 94, 60, 1, 1, 1, 30, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'163', 95, 45, 1, 1, 1, 45, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'97', 96, 46, 1, 1, 1, 45, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'94', 97, 60, 1, 1, 1, 45, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'90', 98, 61, 1, 1, 1, 60, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'92', 99, 70, 1, 1, 1, 60, 1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'158', 100, 30, 1, 1, 1, 30, 1.1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'157', 101, 31, 1, 1, 1, 30, 1.1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'119', 102, 31, 1, 1, 1, 30, 1.25, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'100', 103, 60, 1, 1, 1, 30, 1.42, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'101', 104, 60, 1, 1, 1, 30, 1.45, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'106', 105, 0, 1, 1, 1, 10, 1.48, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'81', 106, 45, 1, 1, 1, 10, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'123', 107, 30, 1, 1, 1, 15, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'104', 108, 45, 1, 1, 1, 15, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'37', 109, 60, 1, 1, 1, 20, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'138', 110, 60, 1, 1, 1, 25, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'63', 111, 30, 1, 1, 1, 30, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'161', 112, 45, 1, 1, 1, 30, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'153', 113, 60, 1, 1, 1, 30, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'127', 114, 46, 1, 1, 1, 45, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'139', 115, 60, 1, 1, 1, 60, 1.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'27', 116, 30, 1, 1, 1, 30, 1.51, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'140', 117, 30, 1, 1, 1, 30, 1.53, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'125', 118, 0, 1, 1, 1, 10, 1.75, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'159', 119, 0, 1, 1, 1, 15, 1.75, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'99', 120, 31, 1, 1, 1, 30, 1.9, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'39', 121, 0, 1, 1, 1, 10, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'75', 122, 10, 1, 1, 1, 10, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'51', 123, 30, 1, 1, 1, 10, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'70', 124, 45, 1, 1, 1, 10, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'52', 125, 60, 1, 1, 1, 10, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'118', 126, 15, 1, 1, 1, 14, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'44', 127, 0, 1, 1, 1, 15, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'73', 128, 15, 1, 1, 1, 15, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'72', 129, 30, 1, 1, 1, 15, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'59', 130, 45, 1, 1, 1, 15, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'55', 131, 60, 1, 1, 1, 15, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'128', 132, 30, 1, 1, 1, 17, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'22', 133, 21, 1, 1, 1, 20, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'33', 134, 35, 1, 1, 1, 20, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'32', 135, 45, 1, 1, 1, 20, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'117', 136, 60, 1, 1, 1, 20, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'152', 137, 30, 1, 1, 1, 25, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'151', 138, 35, 1, 1, 1, 25, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'141', 139, 40, 1, 1, 1, 25, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'67', 140, 30, 1, 1, 1, 30, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'17', 141, 31, 1, 1, 1, 30, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'98', 142, 40, 1, 1, 1, 30, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'16', 143, 45, 1, 1, 1, 30, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'31', 144, 60, 1, 1, 1, 30, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'45', 145, 90, 1, 1, 1, 30, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'28', 146, 60, 1, 1, 1, 33, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'115', 147, 36, 1, 1, 1, 35, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'154', 148, 45, 1, 1, 1, 44, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'62', 149, 45, 1, 1, 1, 45, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'15', 150, 46, 1, 1, 1, 45, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'47', 151, 60, 1, 1, 1, 45, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'112', 152, 90, 1, 1, 1, 45, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'43', 153, 60, 1, 1, 1, 60, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'41', 154, 61, 1, 1, 1, 60, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'88', 155, 90, 1, 1, 1, 60, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'87', 156, 90, 1, 1, 1, 90, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'96', 157, 121, 1, 1, 1, 120, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'121', 158, 365, 1, 1, 1, 365, 2, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'120', 159, 31, 1, 1, 1, 30, 2.02, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'12', 160, 31, 1, 1, 1, 30, 2.05, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'142', 161, 31, 1, 1, 1, 30, 2.1, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'61', 162, 30, 1, 1, 1, 30, 2.15, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'10', 163, 30, 1, 1, 1, 24, 2.38, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'160', 164, 60, 1, 1, 1, 60, 2.38, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'143', 165, 30, 1, 1, 1, 24, 2.48, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'1', 166, 60, 1, 1, 1, 30, 2.5, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'25', 167, 30, 1, 1, 1, 10, 3, 1, 1, NULL, 'Y',  TO_Date( '01/10/1995 12:00:00 AM', 'MM/DD/YYYY HH:MI:SS AM')
, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'01', 168, 30, 1, 1, 1, 0, 2.5, 1, 1, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'02', 169, 30, 1, 1, 1, 0, 1.5, 1, 1, NULL, 'N', NULL, NULL, 1);
INSERT INTO TERMS_DETAIL ( TERMS, TERMS_SEQ, DUEDAYS, DUE_MAX_AMOUNT, DUE_DOM, DUE_MM_FWD, DISCDAYS,
PERCENT, DISC_DOM, DISC_MM_FWD, FIXED_DATE, ENABLED_FLAG, START_DATE_ACTIVE, END_DATE_ACTIVE,
CUTOFF_DAY ) VALUES (
'03', 170, 15, 1, 1, 1, 0, 3.5, 1, 1, NULL, 'N', NULL, NULL, 1);
---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.terms',
                                            to_char(SQLCODE));
      return FALSE;
END TERMS;
--------------------------------------------------------------------------------------------
FUNCTION FREIGHT_TERMS(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

INSERT INTO freight_terms VALUES ('01', '2% Total Cost', NULL, NULL, 'N');
INSERT INTO freight_terms VALUES ('02', '$50 Flat Fee', NULL, NULL, 'N');
INSERT INTO freight_terms VALUES ('03', 'Free', NULL, NULL, 'N');
INSERT INTO freight_terms VALUES ('04', '3% Add to Invoice', NULL, NULL, 'N');


return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.freight_terms',
                                            to_char(SQLCODE));
      return FALSE;
END FREIGHT_TERMS;
--------------------------------------------------------------------------------------------
FUNCTION INV_ADJ_REASON(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN


INSERT INTO inv_adj_reason VALUES (1, 'Shrinkage', 'N');
INSERT INTO inv_adj_reason VALUES (2, '(+/-) due to outbound audit', 'N');
INSERT INTO inv_adj_reason VALUES (10, '(+) due to inventory conversion', 'N');
INSERT INTO inv_adj_reason VALUES (20, '(+/-) due to item transfer', 'N');
INSERT INTO inv_adj_reason VALUES (30, '(+/-) due to Unit Pick System', 'N');
INSERT INTO inv_adj_reason VALUES (31, 'PTS Concealed', 'N');
INSERT INTO inv_adj_reason VALUES (42, '(+/-) due to cycle count', 'N');
INSERT INTO inv_adj_reason VALUES (48, '(+/-) due to pack wave split', 'N');
INSERT INTO inv_adj_reason VALUES (49, '(+/-) due to order consolidation', 'N');
INSERT INTO inv_adj_reason VALUES (50, '(+/-) due to Multi-SKU put', 'N');
INSERT INTO inv_adj_reason VALUES (55, '(+/-) due to paper unit picking', 'N');
INSERT INTO inv_adj_reason VALUES (60, '+ due to Customer Return', 'N');
INSERT INTO inv_adj_reason VALUES (70, '+ due to kitting disassemble', 'N');
INSERT INTO inv_adj_reason VALUES (99, '(+/-) due to general adjustment', 'N');

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.DOC',
                                            to_char(SQLCODE));
      return FALSE;
END INV_ADJ_REASON;
---------------------------------------------------------------------------------------------
FUNCTION POS_TENDER_TYPE(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS


-- Define a record type to store all of the values will be inserted
TYPE pos_tender_type_head_rectype is RECORD (tender_type_id             NUMBER(6),
                                             tender_type_desc           VARCHAR2(40),
                                             tender_type_group          VARCHAR2(6),
                                             effective_date             DATE,
                                             open_drawer_ind            VARCHAR2(1),
                                             exact_change_ind           VARCHAR2(1),
                                             accumulate_cash_intake_ind VARCHAR2(1),
                                             next_dollar_ind            VARCHAR2(1),
                                             deposit_in_bank_ind        VARCHAR2(1),
                                             deposit_override_ind       VARCHAR2(1),
                                             automatic_deposit_ind      VARCHAR2(1),
                                             pay_in_deposit_ind         VARCHAR2(1),
                                             ask_for_invoice_ind        VARCHAR2(1),
                                             imprint_ind                VARCHAR2(1),
                                             show_in_breakdown_ind      VARCHAR2(1),
                                             display_ind                VARCHAR2(1),
                                             processor_type             VARCHAR2(6),
                                             create_id                  VARCHAR2(30),
                                             create_date                DATE,
                                             export_code                VARCHAR2(6),
                                             profit_center              VARCHAR2(6),
                                             phone_authorize_type       VARCHAR2(6),
                                             currency_code              VARCHAR2(3),
                                             preset_amt                 NUMBER(20,4),
                                             authorize_min_amt          NUMBER(20,4),
                                             extract_req_ind            VARCHAR2(1),
                                             system_req_ind             VARCHAR2(1),
                                             cash_equiv_ind             VARCHAR2(1));


-- Define a table type based upon the record type defined above.
TYPE pos_tender_type_head_tabletype IS TABLE OF pos_tender_type_head_rectype
   INDEX BY BINARY_INTEGER;

pos_tender_type_head_list   pos_tender_type_head_tabletype;

BEGIN

   /* Fill the table.  If you need to add a new tender type ID, add a new record to the table below*/

   pos_tender_type_head_list(1).tender_type_id             := 1000;
   pos_tender_type_head_list(1).tender_type_desc           := 'Cash - Primary Currency';
   pos_tender_type_head_list(1).tender_type_group          := 'CASH';
   pos_tender_type_head_list(1).effective_date             := SYSDATE;
   pos_tender_type_head_list(1).open_drawer_ind            := 'N';
   pos_tender_type_head_list(1).exact_change_ind           := 'N';
   pos_tender_type_head_list(1).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(1).next_dollar_ind            := 'N';
   pos_tender_type_head_list(1).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(1).deposit_override_ind       := 'N';
   pos_tender_type_head_list(1).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(1).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(1).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(1).imprint_ind                := 'N';
   pos_tender_type_head_list(1).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(1).display_ind                := 'N';
   pos_tender_type_head_list(1).processor_type             := 'NONE';
   pos_tender_type_head_list(1).create_id                  := USER;
   pos_tender_type_head_list(1).create_date                := SYSDATE;
   pos_tender_type_head_list(1).export_code                := 'NONE';
   pos_tender_type_head_list(1).profit_center              := 'NONE';
   pos_tender_type_head_list(1).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(1).currency_code              := 'USD';
   pos_tender_type_head_list(1).preset_amt                 := 0.00;
   pos_tender_type_head_list(1).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(1).extract_req_ind            := 'N';
   pos_tender_type_head_list(1).system_req_ind             := 'N';
   pos_tender_type_head_list(1).cash_equiv_ind             := 'Y';

   pos_tender_type_head_list(2).tender_type_id             := 2000;
   pos_tender_type_head_list(2).tender_type_desc           := 'Personal Check';
   pos_tender_type_head_list(2).tender_type_group          := 'CHECK';
   pos_tender_type_head_list(2).effective_date             := SYSDATE;
   pos_tender_type_head_list(2).open_drawer_ind            := 'N';
   pos_tender_type_head_list(2).exact_change_ind           := 'N';
   pos_tender_type_head_list(2).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(2).next_dollar_ind            := 'N';
   pos_tender_type_head_list(2).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(2).deposit_override_ind       := 'N';
   pos_tender_type_head_list(2).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(2).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(2).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(2).imprint_ind                := 'N';
   pos_tender_type_head_list(2).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(2).display_ind                := 'N';
   pos_tender_type_head_list(2).processor_type             := 'NONE';
   pos_tender_type_head_list(2).create_id                  := USER;
   pos_tender_type_head_list(2).create_date                := SYSDATE;
   pos_tender_type_head_list(2).export_code                := 'NONE';
   pos_tender_type_head_list(2).profit_center              := 'NONE';
   pos_tender_type_head_list(2).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(2).currency_code              := 'USD';
   pos_tender_type_head_list(2).preset_amt                 := 0.00;
   pos_tender_type_head_list(2).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(2).extract_req_ind            := 'N';
   pos_tender_type_head_list(2).system_req_ind             := 'N';
   pos_tender_type_head_list(2).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(3).tender_type_id             := 2010;
   pos_tender_type_head_list(3).tender_type_desc           := 'Cashier Check';
   pos_tender_type_head_list(3).tender_type_group          := 'CHECK';
   pos_tender_type_head_list(3).effective_date             := SYSDATE;
   pos_tender_type_head_list(3).open_drawer_ind            := 'N';
   pos_tender_type_head_list(3).exact_change_ind           := 'N';
   pos_tender_type_head_list(3).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(3).next_dollar_ind            := 'N';
   pos_tender_type_head_list(3).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(3).deposit_override_ind       := 'N';
   pos_tender_type_head_list(3).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(3).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(3).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(3).imprint_ind                := 'N';
   pos_tender_type_head_list(3).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(3).display_ind                := 'N';
   pos_tender_type_head_list(3).processor_type             := 'NONE';
   pos_tender_type_head_list(3).create_id                  := USER;
   pos_tender_type_head_list(3).create_date                := SYSDATE;
   pos_tender_type_head_list(3).export_code                := 'NONE';
   pos_tender_type_head_list(3).profit_center              := 'NONE';
   pos_tender_type_head_list(3).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(3).currency_code              := 'USD';
   pos_tender_type_head_list(3).preset_amt                 := 0.00;
   pos_tender_type_head_list(3).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(3).extract_req_ind            := 'N';
   pos_tender_type_head_list(3).system_req_ind             := 'N';
   pos_tender_type_head_list(3).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(4).tender_type_id             := 2020;
   pos_tender_type_head_list(4).tender_type_desc           := 'Traveler Check';
   pos_tender_type_head_list(4).tender_type_group          := 'CHECK';
   pos_tender_type_head_list(4).effective_date             := SYSDATE;
   pos_tender_type_head_list(4).open_drawer_ind            := 'N';
   pos_tender_type_head_list(4).exact_change_ind           := 'N';
   pos_tender_type_head_list(4).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(4).next_dollar_ind            := 'N';
   pos_tender_type_head_list(4).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(4).deposit_override_ind       := 'N';
   pos_tender_type_head_list(4).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(4).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(4).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(4).imprint_ind                := 'N';
   pos_tender_type_head_list(4).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(4).display_ind                := 'N';
   pos_tender_type_head_list(4).processor_type             := 'NONE';
   pos_tender_type_head_list(4).create_id                  := USER;
   pos_tender_type_head_list(4).create_date                := SYSDATE;
   pos_tender_type_head_list(4).export_code                := 'NONE';
   pos_tender_type_head_list(4).profit_center              := 'NONE';
   pos_tender_type_head_list(4).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(4).currency_code              := 'USD';
   pos_tender_type_head_list(4).preset_amt                 := 0.00;
   pos_tender_type_head_list(4).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(4).extract_req_ind            := 'N';
   pos_tender_type_head_list(4).system_req_ind             := 'N';
   pos_tender_type_head_list(4).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(5).tender_type_id             := 3000;
   pos_tender_type_head_list(5).tender_type_desc           := 'Visa';
   pos_tender_type_head_list(5).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(5).effective_date             := SYSDATE;
   pos_tender_type_head_list(5).open_drawer_ind            := 'N';
   pos_tender_type_head_list(5).exact_change_ind           := 'N';
   pos_tender_type_head_list(5).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(5).next_dollar_ind            := 'N';
   pos_tender_type_head_list(5).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(5).deposit_override_ind       := 'N';
   pos_tender_type_head_list(5).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(5).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(5).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(5).imprint_ind                := 'N';
   pos_tender_type_head_list(5).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(5).display_ind                := 'N';
   pos_tender_type_head_list(5).processor_type             := 'NONE';
   pos_tender_type_head_list(5).create_id                  := USER;
   pos_tender_type_head_list(5).create_date                := SYSDATE;
   pos_tender_type_head_list(5).export_code                := 'NONE';
   pos_tender_type_head_list(5).profit_center              := 'NONE';
   pos_tender_type_head_list(5).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(5).currency_code              := 'USD';
   pos_tender_type_head_list(5).preset_amt                 := 0.00;
   pos_tender_type_head_list(5).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(5).extract_req_ind            := 'N';
   pos_tender_type_head_list(5).system_req_ind             := 'N';
   pos_tender_type_head_list(5).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(6).tender_type_id             := 3010;
   pos_tender_type_head_list(6).tender_type_desc           := 'Mastercard';
   pos_tender_type_head_list(6).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(6).effective_date             := SYSDATE;
   pos_tender_type_head_list(6).open_drawer_ind            := 'N';
   pos_tender_type_head_list(6).exact_change_ind           := 'N';
   pos_tender_type_head_list(6).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(6).next_dollar_ind            := 'N';
   pos_tender_type_head_list(6).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(6).deposit_override_ind       := 'N';
   pos_tender_type_head_list(6).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(6).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(6).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(6).imprint_ind                := 'N';
   pos_tender_type_head_list(6).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(6).display_ind                := 'N';
   pos_tender_type_head_list(6).processor_type             := 'NONE';
   pos_tender_type_head_list(6).create_id                  := USER;
   pos_tender_type_head_list(6).create_date                := SYSDATE;
   pos_tender_type_head_list(6).export_code                := 'NONE';
   pos_tender_type_head_list(6).profit_center              := 'NONE';
   pos_tender_type_head_list(6).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(6).currency_code              := 'USD';
   pos_tender_type_head_list(6).preset_amt                 := 0.00;
   pos_tender_type_head_list(6).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(6).extract_req_ind            := 'N';
   pos_tender_type_head_list(6).system_req_ind             := 'N';
   pos_tender_type_head_list(6).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(7).tender_type_id             := 3020;
   pos_tender_type_head_list(7).tender_type_desc           := 'American Express';
   pos_tender_type_head_list(7).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(7).effective_date             := SYSDATE;
   pos_tender_type_head_list(7).open_drawer_ind            := 'N';
   pos_tender_type_head_list(7).exact_change_ind           := 'N';
   pos_tender_type_head_list(7).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(7).next_dollar_ind            := 'N';
   pos_tender_type_head_list(7).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(7).deposit_override_ind       := 'N';
   pos_tender_type_head_list(7).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(7).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(7).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(7).imprint_ind                := 'N';
   pos_tender_type_head_list(7).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(7).display_ind                := 'N';
   pos_tender_type_head_list(7).processor_type             := 'NONE';
   pos_tender_type_head_list(7).create_id                  := USER;
   pos_tender_type_head_list(7).create_date                := SYSDATE;
   pos_tender_type_head_list(7).export_code                := 'NONE';
   pos_tender_type_head_list(7).profit_center              := 'NONE';
   pos_tender_type_head_list(7).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(7).currency_code              := 'USD';
   pos_tender_type_head_list(7).preset_amt                 := 0.00;
   pos_tender_type_head_list(7).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(7).extract_req_ind            := 'N';
   pos_tender_type_head_list(7).system_req_ind             := 'N';
   pos_tender_type_head_list(7).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(8).tender_type_id             := 3030;
   pos_tender_type_head_list(8).tender_type_desc           := 'Discover';
   pos_tender_type_head_list(8).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(8).effective_date             := SYSDATE;
   pos_tender_type_head_list(8).open_drawer_ind            := 'N';
   pos_tender_type_head_list(8).exact_change_ind           := 'N';
   pos_tender_type_head_list(8).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(8).next_dollar_ind            := 'N';
   pos_tender_type_head_list(8).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(8).deposit_override_ind       := 'N';
   pos_tender_type_head_list(8).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(8).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(8).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(8).imprint_ind                := 'N';
   pos_tender_type_head_list(8).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(8).display_ind                := 'N';
   pos_tender_type_head_list(8).processor_type             := 'NONE';
   pos_tender_type_head_list(8).create_id                  := USER;
   pos_tender_type_head_list(8).create_date                := SYSDATE;
   pos_tender_type_head_list(8).export_code                := 'NONE';
   pos_tender_type_head_list(8).profit_center              := 'NONE';
   pos_tender_type_head_list(8).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(8).currency_code              := 'USD';
   pos_tender_type_head_list(8).preset_amt                 := 0.00;
   pos_tender_type_head_list(8).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(8).extract_req_ind            := 'N';
   pos_tender_type_head_list(8).system_req_ind             := 'N';
   pos_tender_type_head_list(8).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(9).tender_type_id             := 3040;
   pos_tender_type_head_list(9).tender_type_desc           := 'Diners Club - N. America';
   pos_tender_type_head_list(9).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(9).effective_date             := SYSDATE;
   pos_tender_type_head_list(9).open_drawer_ind            := 'N';
   pos_tender_type_head_list(9).exact_change_ind           := 'N';
   pos_tender_type_head_list(9).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(9).next_dollar_ind            := 'N';
   pos_tender_type_head_list(9).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(9).deposit_override_ind       := 'N';
   pos_tender_type_head_list(9).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(9).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(9).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(9).imprint_ind                := 'N';
   pos_tender_type_head_list(9).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(9).display_ind                := 'N';
   pos_tender_type_head_list(9).processor_type             := 'NONE';
   pos_tender_type_head_list(9).create_id                  := USER;
   pos_tender_type_head_list(9).create_date                := SYSDATE;
   pos_tender_type_head_list(9).export_code                := 'NONE';
   pos_tender_type_head_list(9).profit_center              := 'NONE';
   pos_tender_type_head_list(9).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(9).currency_code              := 'USD';
   pos_tender_type_head_list(9).preset_amt                 := 0.00;
   pos_tender_type_head_list(9).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(9).extract_req_ind            := 'N';
   pos_tender_type_head_list(9).system_req_ind             := 'N';
   pos_tender_type_head_list(9).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(10).tender_type_id             := 3045;
   pos_tender_type_head_list(10).tender_type_desc           := 'Diners Club - Non-N. America';
   pos_tender_type_head_list(10).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(10).effective_date             := SYSDATE;
   pos_tender_type_head_list(10).open_drawer_ind            := 'N';
   pos_tender_type_head_list(10).exact_change_ind           := 'N';
   pos_tender_type_head_list(10).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(10).next_dollar_ind            := 'N';
   pos_tender_type_head_list(10).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(10).deposit_override_ind       := 'N';
   pos_tender_type_head_list(10).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(10).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(10).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(10).imprint_ind                := 'N';
   pos_tender_type_head_list(10).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(10).display_ind                := 'N';
   pos_tender_type_head_list(10).processor_type             := 'NONE';
   pos_tender_type_head_list(10).create_id                  := USER;
   pos_tender_type_head_list(10).create_date                := SYSDATE;
   pos_tender_type_head_list(10).export_code                := 'NONE';
   pos_tender_type_head_list(10).profit_center              := 'NONE';
   pos_tender_type_head_list(10).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(10).currency_code              := 'USD';
   pos_tender_type_head_list(10).preset_amt                 := 0.00;
   pos_tender_type_head_list(10).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(10).extract_req_ind            := 'N';
   pos_tender_type_head_list(10).system_req_ind             := 'N';
   pos_tender_type_head_list(10).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(11).tender_type_id             := 3049;
   pos_tender_type_head_list(11).tender_type_desc           := 'Diners Club - Ancillary';
   pos_tender_type_head_list(11).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(11).effective_date             := SYSDATE;
   pos_tender_type_head_list(11).open_drawer_ind            := 'N';
   pos_tender_type_head_list(11).exact_change_ind           := 'N';
   pos_tender_type_head_list(11).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(11).next_dollar_ind            := 'N';
   pos_tender_type_head_list(11).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(11).deposit_override_ind       := 'N';
   pos_tender_type_head_list(11).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(11).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(11).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(11).imprint_ind                := 'N';
   pos_tender_type_head_list(11).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(11).display_ind                := 'N';
   pos_tender_type_head_list(11).processor_type             := 'NONE';
   pos_tender_type_head_list(11).create_id                  := USER;
   pos_tender_type_head_list(11).create_date                := SYSDATE;
   pos_tender_type_head_list(11).export_code                := 'NONE';
   pos_tender_type_head_list(11).profit_center              := 'NONE';
   pos_tender_type_head_list(11).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(11).currency_code              := 'USD';
   pos_tender_type_head_list(11).preset_amt                 := 0.00;
   pos_tender_type_head_list(11).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(11).extract_req_ind            := 'N';
   pos_tender_type_head_list(11).system_req_ind             := 'N';
   pos_tender_type_head_list(11).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(12).tender_type_id             := 3050;
   pos_tender_type_head_list(12).tender_type_desc           := 'WEX';
   pos_tender_type_head_list(12).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(12).effective_date             := SYSDATE;
   pos_tender_type_head_list(12).open_drawer_ind            := 'N';
   pos_tender_type_head_list(12).exact_change_ind           := 'N';
   pos_tender_type_head_list(12).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(12).next_dollar_ind            := 'N';
   pos_tender_type_head_list(12).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(12).deposit_override_ind       := 'N';
   pos_tender_type_head_list(12).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(12).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(12).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(12).imprint_ind                := 'N';
   pos_tender_type_head_list(12).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(12).display_ind                := 'N';
   pos_tender_type_head_list(12).processor_type             := 'NONE';
   pos_tender_type_head_list(12).create_id                  := USER;
   pos_tender_type_head_list(12).create_date                := SYSDATE;
   pos_tender_type_head_list(12).export_code                := 'NONE';
   pos_tender_type_head_list(12).profit_center              := 'NONE';
   pos_tender_type_head_list(12).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(12).currency_code              := 'USD';
   pos_tender_type_head_list(12).preset_amt                 := 0.00;
   pos_tender_type_head_list(12).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(12).extract_req_ind            := 'N';
   pos_tender_type_head_list(12).system_req_ind             := 'N';
   pos_tender_type_head_list(12).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(13).tender_type_id             := 3060;
   pos_tender_type_head_list(13).tender_type_desc           := 'Voyageur';
   pos_tender_type_head_list(13).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(13).effective_date             := SYSDATE;
   pos_tender_type_head_list(13).open_drawer_ind            := 'N';
   pos_tender_type_head_list(13).exact_change_ind           := 'N';
   pos_tender_type_head_list(13).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(13).next_dollar_ind            := 'N';
   pos_tender_type_head_list(13).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(13).deposit_override_ind       := 'N';
   pos_tender_type_head_list(13).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(13).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(13).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(13).imprint_ind                := 'N';
   pos_tender_type_head_list(13).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(13).display_ind                := 'N';
   pos_tender_type_head_list(13).processor_type             := 'NONE';
   pos_tender_type_head_list(13).create_id                  := USER;
   pos_tender_type_head_list(13).create_date                := SYSDATE;
   pos_tender_type_head_list(13).export_code                := 'NONE';
   pos_tender_type_head_list(13).profit_center              := 'NONE';
   pos_tender_type_head_list(13).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(13).currency_code              := 'USD';
   pos_tender_type_head_list(13).preset_amt                 := 0.00;
   pos_tender_type_head_list(13).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(13).extract_req_ind            := 'N';
   pos_tender_type_head_list(13).system_req_ind             := 'N';
   pos_tender_type_head_list(13).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(14).tender_type_id             := 3070;
   pos_tender_type_head_list(14).tender_type_desc           := 'Unocal';
   pos_tender_type_head_list(14).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(14).effective_date             := SYSDATE;
   pos_tender_type_head_list(14).open_drawer_ind            := 'N';
   pos_tender_type_head_list(14).exact_change_ind           := 'N';
   pos_tender_type_head_list(14).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(14).next_dollar_ind            := 'N';
   pos_tender_type_head_list(14).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(14).deposit_override_ind       := 'N';
   pos_tender_type_head_list(14).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(14).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(14).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(14).imprint_ind                := 'N';
   pos_tender_type_head_list(14).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(14).display_ind                := 'N';
   pos_tender_type_head_list(14).processor_type             := 'NONE';
   pos_tender_type_head_list(14).create_id                  := USER;
   pos_tender_type_head_list(14).create_date                := SYSDATE;
   pos_tender_type_head_list(14).export_code                := 'NONE';
   pos_tender_type_head_list(14).profit_center              := 'NONE';
   pos_tender_type_head_list(14).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(14).currency_code              := 'USD';
   pos_tender_type_head_list(14).preset_amt                 := 0.00;
   pos_tender_type_head_list(14).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(14).extract_req_ind            := 'N';
   pos_tender_type_head_list(14).system_req_ind             := 'N';
   pos_tender_type_head_list(14).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(15).tender_type_id             := 3080;
   pos_tender_type_head_list(15).tender_type_desc           := 'enRoute';
   pos_tender_type_head_list(15).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(15).effective_date             := SYSDATE;
   pos_tender_type_head_list(15).open_drawer_ind            := 'N';
   pos_tender_type_head_list(15).exact_change_ind           := 'N';
   pos_tender_type_head_list(15).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(15).next_dollar_ind            := 'N';
   pos_tender_type_head_list(15).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(15).deposit_override_ind       := 'N';
   pos_tender_type_head_list(15).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(15).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(15).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(15).imprint_ind                := 'N';
   pos_tender_type_head_list(15).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(15).display_ind                := 'N';
   pos_tender_type_head_list(15).processor_type             := 'NONE';
   pos_tender_type_head_list(15).create_id                  := USER;
   pos_tender_type_head_list(15).create_date                := SYSDATE;
   pos_tender_type_head_list(15).export_code                := 'NONE';
   pos_tender_type_head_list(15).profit_center              := 'NONE';
   pos_tender_type_head_list(15).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(15).currency_code              := 'USD';
   pos_tender_type_head_list(15).preset_amt                 := 0.00;
   pos_tender_type_head_list(15).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(15).extract_req_ind            := 'N';
   pos_tender_type_head_list(15).system_req_ind             := 'N';
   pos_tender_type_head_list(15).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(16).tender_type_id             := 3090;
   pos_tender_type_head_list(16).tender_type_desc           := 'Japanese Credit Bureau';
   pos_tender_type_head_list(16).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(16).effective_date             := SYSDATE;
   pos_tender_type_head_list(16).open_drawer_ind            := 'N';
   pos_tender_type_head_list(16).exact_change_ind           := 'N';
   pos_tender_type_head_list(16).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(16).next_dollar_ind            := 'N';
   pos_tender_type_head_list(16).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(16).deposit_override_ind       := 'N';
   pos_tender_type_head_list(16).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(16).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(16).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(16).imprint_ind                := 'N';
   pos_tender_type_head_list(16).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(16).display_ind                := 'N';
   pos_tender_type_head_list(16).processor_type             := 'NONE';
   pos_tender_type_head_list(16).create_id                  := USER;
   pos_tender_type_head_list(16).create_date                := SYSDATE;
   pos_tender_type_head_list(16).export_code                := 'NONE';
   pos_tender_type_head_list(16).profit_center              := 'NONE';
   pos_tender_type_head_list(16).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(16).currency_code              := 'USD';
   pos_tender_type_head_list(16).preset_amt                 := 0.00;
   pos_tender_type_head_list(16).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(16).extract_req_ind            := 'N';
   pos_tender_type_head_list(16).system_req_ind             := 'N';
   pos_tender_type_head_list(16).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(17).tender_type_id             := 3100;
   pos_tender_type_head_list(17).tender_type_desc           := 'Australian Bank Card';
   pos_tender_type_head_list(17).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(17).effective_date             := SYSDATE;
   pos_tender_type_head_list(17).open_drawer_ind            := 'N';
   pos_tender_type_head_list(17).exact_change_ind           := 'N';
   pos_tender_type_head_list(17).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(17).next_dollar_ind            := 'N';
   pos_tender_type_head_list(17).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(17).deposit_override_ind       := 'N';
   pos_tender_type_head_list(17).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(17).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(17).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(17).imprint_ind                := 'N';
   pos_tender_type_head_list(17).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(17).display_ind                := 'N';
   pos_tender_type_head_list(17).processor_type             := 'NONE';
   pos_tender_type_head_list(17).create_id                  := USER;
   pos_tender_type_head_list(17).create_date                := SYSDATE;
   pos_tender_type_head_list(17).export_code                := 'NONE';
   pos_tender_type_head_list(17).profit_center              := 'NONE';
   pos_tender_type_head_list(17).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(17).currency_code              := 'USD';
   pos_tender_type_head_list(17).preset_amt                 := 0.00;
   pos_tender_type_head_list(17).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(17).extract_req_ind            := 'N';
   pos_tender_type_head_list(17).system_req_ind             := 'N';
   pos_tender_type_head_list(17).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(18).tender_type_id             := 3110;
   pos_tender_type_head_list(18).tender_type_desc           := 'Carte Blanche - N. America';
   pos_tender_type_head_list(18).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(18).effective_date             := SYSDATE;
   pos_tender_type_head_list(18).open_drawer_ind            := 'N';
   pos_tender_type_head_list(18).exact_change_ind           := 'N';
   pos_tender_type_head_list(18).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(18).next_dollar_ind            := 'N';
   pos_tender_type_head_list(18).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(18).deposit_override_ind       := 'N';
   pos_tender_type_head_list(18).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(18).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(18).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(18).imprint_ind                := 'N';
   pos_tender_type_head_list(18).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(18).display_ind                := 'N';
   pos_tender_type_head_list(18).processor_type             := 'NONE';
   pos_tender_type_head_list(18).create_id                  := USER;
   pos_tender_type_head_list(18).create_date                := SYSDATE;
   pos_tender_type_head_list(18).export_code                := 'NONE';
   pos_tender_type_head_list(18).profit_center              := 'NONE';
   pos_tender_type_head_list(18).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(18).currency_code              := 'USD';
   pos_tender_type_head_list(18).preset_amt                 := 0.00;
   pos_tender_type_head_list(18).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(18).extract_req_ind            := 'N';
   pos_tender_type_head_list(18).system_req_ind             := 'N';
   pos_tender_type_head_list(18).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(19).tender_type_id             := 3115;
   pos_tender_type_head_list(19).tender_type_desc           := 'Carte Blanche - Non-N. America';
   pos_tender_type_head_list(19).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(19).effective_date             := SYSDATE;
   pos_tender_type_head_list(19).open_drawer_ind            := 'N';
   pos_tender_type_head_list(19).exact_change_ind           := 'N';
   pos_tender_type_head_list(19).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(19).next_dollar_ind            := 'N';
   pos_tender_type_head_list(19).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(19).deposit_override_ind       := 'N';
   pos_tender_type_head_list(19).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(19).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(19).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(19).imprint_ind                := 'N';
   pos_tender_type_head_list(19).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(19).display_ind                := 'N';
   pos_tender_type_head_list(19).processor_type             := 'NONE';
   pos_tender_type_head_list(19).create_id                  := USER;
   pos_tender_type_head_list(19).create_date                := SYSDATE;
   pos_tender_type_head_list(19).export_code                := 'NONE';
   pos_tender_type_head_list(19).profit_center              := 'NONE';
   pos_tender_type_head_list(19).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(19).currency_code              := 'USD';
   pos_tender_type_head_list(19).preset_amt                 := 0.00;
   pos_tender_type_head_list(19).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(19).extract_req_ind            := 'N';
   pos_tender_type_head_list(19).system_req_ind             := 'N';
   pos_tender_type_head_list(19).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(20).tender_type_id             := 3120;
   pos_tender_type_head_list(20).tender_type_desc           := 'House Card';
   pos_tender_type_head_list(20).tender_type_group          := 'CCARD';
   pos_tender_type_head_list(20).effective_date             := SYSDATE;
   pos_tender_type_head_list(20).open_drawer_ind            := 'N';
   pos_tender_type_head_list(20).exact_change_ind           := 'N';
   pos_tender_type_head_list(20).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(20).next_dollar_ind            := 'N';
   pos_tender_type_head_list(20).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(20).deposit_override_ind       := 'N';
   pos_tender_type_head_list(20).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(20).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(20).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(20).imprint_ind                := 'N';
   pos_tender_type_head_list(20).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(20).display_ind                := 'N';
   pos_tender_type_head_list(20).processor_type             := 'NONE';
   pos_tender_type_head_list(20).create_id                  := USER;
   pos_tender_type_head_list(20).create_date                := SYSDATE;
   pos_tender_type_head_list(20).export_code                := 'NONE';
   pos_tender_type_head_list(20).profit_center              := 'NONE';
   pos_tender_type_head_list(20).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(20).currency_code              := 'USD';
   pos_tender_type_head_list(20).preset_amt                 := 0.00;
   pos_tender_type_head_list(20).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(20).extract_req_ind            := 'N';
   pos_tender_type_head_list(20).system_req_ind             := 'N';
   pos_tender_type_head_list(20).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(21).tender_type_id             := 4000;
   pos_tender_type_head_list(21).tender_type_desc           := 'Credit Voucher';
   pos_tender_type_head_list(21).tender_type_group          := 'VOUCH';
   pos_tender_type_head_list(21).effective_date             := SYSDATE;
   pos_tender_type_head_list(21).open_drawer_ind            := 'N';
   pos_tender_type_head_list(21).exact_change_ind           := 'N';
   pos_tender_type_head_list(21).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(21).next_dollar_ind            := 'N';
   pos_tender_type_head_list(21).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(21).deposit_override_ind       := 'N';
   pos_tender_type_head_list(21).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(21).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(21).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(21).imprint_ind                := 'N';
   pos_tender_type_head_list(21).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(21).display_ind                := 'N';
   pos_tender_type_head_list(21).processor_type             := 'NONE';
   pos_tender_type_head_list(21).create_id                  := USER;
   pos_tender_type_head_list(21).create_date                := SYSDATE;
   pos_tender_type_head_list(21).export_code                := 'NONE';
   pos_tender_type_head_list(21).profit_center              := 'NONE';
   pos_tender_type_head_list(21).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(21).currency_code              := 'USD';
   pos_tender_type_head_list(21).preset_amt                 := 0.00;
   pos_tender_type_head_list(21).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(21).extract_req_ind            := 'N';
   pos_tender_type_head_list(21).system_req_ind             := 'N';
   pos_tender_type_head_list(21).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(22).tender_type_id             := 4010;
   pos_tender_type_head_list(22).tender_type_desc           := 'Manual Credit';
   pos_tender_type_head_list(22).tender_type_group          := 'VOUCH';
   pos_tender_type_head_list(22).effective_date             := SYSDATE;
   pos_tender_type_head_list(22).open_drawer_ind            := 'N';
   pos_tender_type_head_list(22).exact_change_ind           := 'N';
   pos_tender_type_head_list(22).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(22).next_dollar_ind            := 'N';
   pos_tender_type_head_list(22).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(22).deposit_override_ind       := 'N';
   pos_tender_type_head_list(22).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(22).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(22).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(22).imprint_ind                := 'N';
   pos_tender_type_head_list(22).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(22).display_ind                := 'N';
   pos_tender_type_head_list(22).processor_type             := 'NONE';
   pos_tender_type_head_list(22).create_id                  := USER;
   pos_tender_type_head_list(22).create_date                := SYSDATE;
   pos_tender_type_head_list(22).export_code                := 'NONE';
   pos_tender_type_head_list(22).profit_center              := 'NONE';
   pos_tender_type_head_list(22).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(22).currency_code              := 'USD';
   pos_tender_type_head_list(22).preset_amt                 := 0.00;
   pos_tender_type_head_list(22).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(22).extract_req_ind            := 'N';
   pos_tender_type_head_list(22).system_req_ind             := 'N';
   pos_tender_type_head_list(22).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(23).tender_type_id             := 4020;
   pos_tender_type_head_list(23).tender_type_desc           := 'Manual Imprint';
   pos_tender_type_head_list(23).tender_type_group          := 'VOUCH';
   pos_tender_type_head_list(23).effective_date             := SYSDATE;
   pos_tender_type_head_list(23).open_drawer_ind            := 'N';
   pos_tender_type_head_list(23).exact_change_ind           := 'N';
   pos_tender_type_head_list(23).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(23).next_dollar_ind            := 'N';
   pos_tender_type_head_list(23).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(23).deposit_override_ind       := 'N';
   pos_tender_type_head_list(23).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(23).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(23).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(23).imprint_ind                := 'N';
   pos_tender_type_head_list(23).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(23).display_ind                := 'N';
   pos_tender_type_head_list(23).processor_type             := 'NONE';
   pos_tender_type_head_list(23).create_id                  := USER;
   pos_tender_type_head_list(23).create_date                := SYSDATE;
   pos_tender_type_head_list(23).export_code                := 'NONE';
   pos_tender_type_head_list(23).profit_center              := 'NONE';
   pos_tender_type_head_list(23).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(23).currency_code              := 'USD';
   pos_tender_type_head_list(23).preset_amt                 := 0.00;
   pos_tender_type_head_list(23).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(23).extract_req_ind            := 'N';
   pos_tender_type_head_list(23).system_req_ind             := 'N';
   pos_tender_type_head_list(23).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(24).tender_type_id             := 4030;
   pos_tender_type_head_list(24).tender_type_desc           := 'Gift Certificate';
   pos_tender_type_head_list(24).tender_type_group          := 'VOUCH';
   pos_tender_type_head_list(24).effective_date             := SYSDATE;
   pos_tender_type_head_list(24).open_drawer_ind            := 'N';
   pos_tender_type_head_list(24).exact_change_ind           := 'N';
   pos_tender_type_head_list(24).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(24).next_dollar_ind            := 'N';
   pos_tender_type_head_list(24).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(24).deposit_override_ind       := 'N';
   pos_tender_type_head_list(24).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(24).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(24).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(24).imprint_ind                := 'N';
   pos_tender_type_head_list(24).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(24).display_ind                := 'N';
   pos_tender_type_head_list(24).processor_type             := 'NONE';
   pos_tender_type_head_list(24).create_id                  := USER;
   pos_tender_type_head_list(24).create_date                := SYSDATE;
   pos_tender_type_head_list(24).export_code                := 'NONE';
   pos_tender_type_head_list(24).profit_center              := 'NONE';
   pos_tender_type_head_list(24).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(24).currency_code              := 'USD';
   pos_tender_type_head_list(24).preset_amt                 := 0.00;
   pos_tender_type_head_list(24).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(24).extract_req_ind            := 'N';
   pos_tender_type_head_list(24).system_req_ind             := 'N';
   pos_tender_type_head_list(24).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(25).tender_type_id             := 5000;
   pos_tender_type_head_list(25).tender_type_desc           := 'Manufacturers Coupons';
   pos_tender_type_head_list(25).tender_type_group          := 'COUPON';
   pos_tender_type_head_list(25).effective_date             := SYSDATE;
   pos_tender_type_head_list(25).open_drawer_ind            := 'N';
   pos_tender_type_head_list(25).exact_change_ind           := 'N';
   pos_tender_type_head_list(25).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(25).next_dollar_ind            := 'N';
   pos_tender_type_head_list(25).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(25).deposit_override_ind       := 'N';
   pos_tender_type_head_list(25).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(25).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(25).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(25).imprint_ind                := 'N';
   pos_tender_type_head_list(25).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(25).display_ind                := 'N';
   pos_tender_type_head_list(25).processor_type             := 'NONE';
   pos_tender_type_head_list(25).create_id                  := USER;
   pos_tender_type_head_list(25).create_date                := SYSDATE;
   pos_tender_type_head_list(25).export_code                := 'NONE';
   pos_tender_type_head_list(25).profit_center              := 'NONE';
   pos_tender_type_head_list(25).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(25).currency_code              := 'USD';
   pos_tender_type_head_list(25).preset_amt                 := 0.00;
   pos_tender_type_head_list(25).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(25).extract_req_ind            := 'N';
   pos_tender_type_head_list(25).system_req_ind             := 'N';
   pos_tender_type_head_list(25).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(26).tender_type_id             := 6000;
   pos_tender_type_head_list(26).tender_type_desc           := 'Money Orders';
   pos_tender_type_head_list(26).tender_type_group          := 'MORDER';
   pos_tender_type_head_list(26).effective_date             := SYSDATE;
   pos_tender_type_head_list(26).open_drawer_ind            := 'N';
   pos_tender_type_head_list(26).exact_change_ind           := 'N';
   pos_tender_type_head_list(26).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(26).next_dollar_ind            := 'N';
   pos_tender_type_head_list(26).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(26).deposit_override_ind       := 'N';
   pos_tender_type_head_list(26).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(26).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(26).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(26).imprint_ind                := 'N';
   pos_tender_type_head_list(26).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(26).display_ind                := 'N';
   pos_tender_type_head_list(26).processor_type             := 'NONE';
   pos_tender_type_head_list(26).create_id                  := USER;
   pos_tender_type_head_list(26).create_date                := SYSDATE;
   pos_tender_type_head_list(26).export_code                := 'NONE';
   pos_tender_type_head_list(26).profit_center              := 'NONE';
   pos_tender_type_head_list(26).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(26).currency_code              := 'USD';
   pos_tender_type_head_list(26).preset_amt                 := 0.00;
   pos_tender_type_head_list(26).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(26).extract_req_ind            := 'N';
   pos_tender_type_head_list(26).system_req_ind             := 'N';
   pos_tender_type_head_list(26).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(27).tender_type_id             := 7000;
   pos_tender_type_head_list(27).tender_type_desc           := 'Food Stamps';
   pos_tender_type_head_list(27).tender_type_group          := 'SOCASS';
   pos_tender_type_head_list(27).effective_date             := SYSDATE;
   pos_tender_type_head_list(27).open_drawer_ind            := 'N';
   pos_tender_type_head_list(27).exact_change_ind           := 'N';
   pos_tender_type_head_list(27).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(27).next_dollar_ind            := 'N';
   pos_tender_type_head_list(27).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(27).deposit_override_ind       := 'N';
   pos_tender_type_head_list(27).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(27).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(27).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(27).imprint_ind                := 'N';
   pos_tender_type_head_list(27).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(27).display_ind                := 'N';
   pos_tender_type_head_list(27).processor_type             := 'NONE';
   pos_tender_type_head_list(27).create_id                  := USER;
   pos_tender_type_head_list(27).create_date                := SYSDATE;
   pos_tender_type_head_list(27).export_code                := 'NONE';
   pos_tender_type_head_list(27).profit_center              := 'NONE';
   pos_tender_type_head_list(27).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(27).currency_code              := 'USD';
   pos_tender_type_head_list(27).preset_amt                 := 0.00;
   pos_tender_type_head_list(27).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(27).extract_req_ind            := 'N';
   pos_tender_type_head_list(27).system_req_ind             := 'N';
   pos_tender_type_head_list(27).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(28).tender_type_id             := 7010;
   pos_tender_type_head_list(28).tender_type_desc           := 'Electronic Benefits System -EBS';
   pos_tender_type_head_list(28).tender_type_group          := 'SOCASS';
   pos_tender_type_head_list(28).effective_date             := SYSDATE;
   pos_tender_type_head_list(28).open_drawer_ind            := 'N';
   pos_tender_type_head_list(28).exact_change_ind           := 'N';
   pos_tender_type_head_list(28).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(28).next_dollar_ind            := 'N';
   pos_tender_type_head_list(28).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(28).deposit_override_ind       := 'N';
   pos_tender_type_head_list(28).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(28).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(28).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(28).imprint_ind                := 'N';
   pos_tender_type_head_list(28).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(28).display_ind                := 'N';
   pos_tender_type_head_list(28).processor_type             := 'NONE';
   pos_tender_type_head_list(28).create_id                  := USER;
   pos_tender_type_head_list(28).create_date                := SYSDATE;
   pos_tender_type_head_list(28).export_code                := 'NONE';
   pos_tender_type_head_list(28).profit_center              := 'NONE';
   pos_tender_type_head_list(28).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(28).currency_code              := 'USD';
   pos_tender_type_head_list(28).preset_amt                 := 0.00;
   pos_tender_type_head_list(28).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(28).extract_req_ind            := 'N';
   pos_tender_type_head_list(28).system_req_ind             := 'N';
   pos_tender_type_head_list(28).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(29).tender_type_id             := 8000;
   pos_tender_type_head_list(29).tender_type_desc           := 'Debit Card';
   pos_tender_type_head_list(29).tender_type_group          := 'DCARD';
   pos_tender_type_head_list(29).effective_date             := SYSDATE;
   pos_tender_type_head_list(29).open_drawer_ind            := 'N';
   pos_tender_type_head_list(29).exact_change_ind           := 'N';
   pos_tender_type_head_list(29).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(29).next_dollar_ind            := 'N';
   pos_tender_type_head_list(29).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(29).deposit_override_ind       := 'N';
   pos_tender_type_head_list(29).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(29).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(29).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(29).imprint_ind                := 'N';
   pos_tender_type_head_list(29).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(29).display_ind                := 'N';
   pos_tender_type_head_list(29).processor_type             := 'NONE';
   pos_tender_type_head_list(29).create_id                  := USER;
   pos_tender_type_head_list(29).create_date                := SYSDATE;
   pos_tender_type_head_list(29).export_code                := 'NONE';
   pos_tender_type_head_list(29).profit_center              := 'NONE';
   pos_tender_type_head_list(29).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(29).currency_code              := 'USD';
   pos_tender_type_head_list(29).preset_amt                 := 0.00;
   pos_tender_type_head_list(29).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(29).extract_req_ind            := 'N';
   pos_tender_type_head_list(29).system_req_ind             := 'N';
   pos_tender_type_head_list(29).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(30).tender_type_id             := 9000;
   pos_tender_type_head_list(30).tender_type_desc           := 'Fuel Drive Off';
   pos_tender_type_head_list(30).tender_type_group          := 'DRIVEO';
   pos_tender_type_head_list(30).effective_date             := SYSDATE;
   pos_tender_type_head_list(30).open_drawer_ind            := 'N';
   pos_tender_type_head_list(30).exact_change_ind           := 'N';
   pos_tender_type_head_list(30).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(30).next_dollar_ind            := 'N';
   pos_tender_type_head_list(30).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(30).deposit_override_ind       := 'N';
   pos_tender_type_head_list(30).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(30).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(30).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(30).imprint_ind                := 'N';
   pos_tender_type_head_list(30).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(30).display_ind                := 'N';
   pos_tender_type_head_list(30).processor_type             := 'NONE';
   pos_tender_type_head_list(30).create_id                  := USER;
   pos_tender_type_head_list(30).create_date                := SYSDATE;
   pos_tender_type_head_list(30).export_code                := 'NONE';
   pos_tender_type_head_list(30).profit_center              := 'NONE';
   pos_tender_type_head_list(30).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(30).currency_code              := 'USD';
   pos_tender_type_head_list(30).preset_amt                 := 0.00;
   pos_tender_type_head_list(30).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(30).extract_req_ind            := 'N';
   pos_tender_type_head_list(30).system_req_ind             := 'N';
   pos_tender_type_head_list(30).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(31).tender_type_id             := 2030;
   pos_tender_type_head_list(31).tender_type_desc           := 'Electronic Check';
   pos_tender_type_head_list(31).tender_type_group          := 'CHECK';
   pos_tender_type_head_list(31).effective_date             := SYSDATE;
   pos_tender_type_head_list(31).open_drawer_ind            := 'N';
   pos_tender_type_head_list(31).exact_change_ind           := 'N';
   pos_tender_type_head_list(31).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(31).next_dollar_ind            := 'N';
   pos_tender_type_head_list(31).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(31).deposit_override_ind       := 'N';
   pos_tender_type_head_list(31).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(31).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(31).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(31).imprint_ind                := 'N';
   pos_tender_type_head_list(31).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(31).display_ind                := 'N';
   pos_tender_type_head_list(31).processor_type             := 'NONE';
   pos_tender_type_head_list(31).create_id                  := USER;
   pos_tender_type_head_list(31).create_date                := SYSDATE;
   pos_tender_type_head_list(31).export_code                := 'NONE';
   pos_tender_type_head_list(31).profit_center              := 'NONE';
   pos_tender_type_head_list(31).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(31).currency_code              := 'USD';
   pos_tender_type_head_list(31).preset_amt                 := 0.00;
   pos_tender_type_head_list(31).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(31).extract_req_ind            := 'N';
   pos_tender_type_head_list(31).system_req_ind             := 'N';
   pos_tender_type_head_list(31).cash_equiv_ind             := 'N';

   pos_tender_type_head_list(32).tender_type_id             := 4040;
   pos_tender_type_head_list(32).tender_type_desc           := 'Adjustment';
   pos_tender_type_head_list(32).tender_type_group          := 'VOUCH';
   pos_tender_type_head_list(32).effective_date             := SYSDATE;
   pos_tender_type_head_list(32).open_drawer_ind            := 'N';
   pos_tender_type_head_list(32).exact_change_ind           := 'N';
   pos_tender_type_head_list(32).accumulate_cash_intake_ind := 'N';
   pos_tender_type_head_list(32).next_dollar_ind            := 'N';
   pos_tender_type_head_list(32).deposit_in_bank_ind        := 'N';
   pos_tender_type_head_list(32).deposit_override_ind       := 'N';
   pos_tender_type_head_list(32).automatic_deposit_ind      := 'N';
   pos_tender_type_head_list(32).pay_in_deposit_ind         := 'N';
   pos_tender_type_head_list(32).ask_for_invoice_ind        := 'N';
   pos_tender_type_head_list(32).imprint_ind                := 'N';
   pos_tender_type_head_list(32).show_in_breakdown_ind      := 'N';
   pos_tender_type_head_list(32).display_ind                := 'N';
   pos_tender_type_head_list(32).processor_type             := 'NONE';
   pos_tender_type_head_list(32).create_id                  := USER;
   pos_tender_type_head_list(32).create_date                := SYSDATE;
   pos_tender_type_head_list(32).export_code                := 'NONE';
   pos_tender_type_head_list(32).profit_center              := 'NONE';
   pos_tender_type_head_list(32).phone_authorize_type       := 'NONE';
   pos_tender_type_head_list(32).currency_code              := 'USD';
   pos_tender_type_head_list(32).preset_amt                 := 0.00;
   pos_tender_type_head_list(32).authorize_min_amt          := 0.00;
   pos_tender_type_head_list(32).extract_req_ind            := 'N';
   pos_tender_type_head_list(32).system_req_ind             := 'N';
   pos_tender_type_head_list(32).cash_equiv_ind             := 'N';

 FOR i in 1..pos_tender_type_head_list.COUNT
   LOOP
      insert into pos_tender_type_head
               (tender_type_id,
                tender_type_desc,
                tender_type_group,
                effective_date,
                open_drawer_ind,
                exact_change_ind,
                accumulate_cash_intake_ind,
                next_dollar_ind,
                deposit_in_bank_ind,
                deposit_override_ind,
                automatic_deposit_ind,
                pay_in_deposit_ind,
                ask_for_invoice_ind,
                imprint_ind,
                show_in_breakdown_ind,
                display_ind,
                processor_type,
                create_id,
                create_date,
                export_code,
                profit_center,
                phone_authorize_type,
                currency_code,
                preset_amt,
                authorize_min_amt,
                extract_req_ind,
                system_req_ind,
                cash_equiv_ind)
         values(pos_tender_type_head_list(i).tender_type_id,
                pos_tender_type_head_list(i).tender_type_desc,
                pos_tender_type_head_list(i).tender_type_group,
                pos_tender_type_head_list(i).effective_date,
                pos_tender_type_head_list(i).open_drawer_ind,
                pos_tender_type_head_list(i).exact_change_ind,
                pos_tender_type_head_list(i).accumulate_cash_intake_ind,
                pos_tender_type_head_list(i).next_dollar_ind,
                pos_tender_type_head_list(i).deposit_in_bank_ind,
                pos_tender_type_head_list(i).deposit_override_ind,
                pos_tender_type_head_list(i).automatic_deposit_ind,
                pos_tender_type_head_list(i).pay_in_deposit_ind,
                pos_tender_type_head_list(i).ask_for_invoice_ind,
                pos_tender_type_head_list(i).imprint_ind,
                pos_tender_type_head_list(i).show_in_breakdown_ind,
                pos_tender_type_head_list(i).display_ind,
                pos_tender_type_head_list(i).processor_type,
                pos_tender_type_head_list(i).create_id,
                pos_tender_type_head_list(i).create_date,
                pos_tender_type_head_list(i).export_code,
                pos_tender_type_head_list(i).profit_center,
                pos_tender_type_head_list(i).phone_authorize_type,
                pos_tender_type_head_list(i).currency_code,
                pos_tender_type_head_list(i).preset_amt,
                pos_tender_type_head_list(i).authorize_min_amt,
                pos_tender_type_head_list(i).extract_req_ind,
                pos_tender_type_head_list(i).system_req_ind,
                pos_tender_type_head_list(i).cash_equiv_ind);
   END LOOP;

  return TRUE;

EXCEPTION
  when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.POS_TENDER_TYPE',
                                            to_char(SQLCODE));
END POS_TENDER_TYPE;
---------------------------------------------------------------------------------------------
FUNCTION NON_MERCH_CODES(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'A', 'Ancillary Services', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'B', 'Banded Premium', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'E', 'Extraneous Items', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'F', 'Freight Code', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'I', 'Indirect Expense', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'K', 'Kanban', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'M', 'Miscellaneous', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'R', 'Repacking', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'S', 'Sales Tax', 'N');

INSERT INTO NON_MERCH_CODE_HEAD ( NON_MERCH_CODE, NON_MERCH_CODE_DESC,
SERVICE_IND ) VALUES (
'T', 'Ticketing', 'N');

return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.NON_MERCH_CODES',
                                            to_char(SQLCODE));
      return FALSE;
END NON_MERCH_CODES;
--------------------------------------------------------------------------------------------
FUNCTION FIF_GL_XREF(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

BEGIN

insert into fif_line_type_xref(rms_line_type,
                               rms_line_type_desc,
                               fif_line_type)
                        values('ITEM',
                               'Item',
                               'ITEM');

insert into fif_line_type_xref(rms_line_type,
                               rms_line_type_desc,
                               fif_line_type)
                        values('FRGHT',
                               'Freight',
                               'FREIGHT');

insert into fif_line_type_xref(rms_line_type,
                               rms_line_type_desc,
                               fif_line_type)
                        values('TAX',
                               'Tax',
                               'TAX');

insert into fif_line_type_xref(rms_line_type,
                               rms_line_type_desc,
                               fif_line_type)
                        values('MISC',
                               'Miscellaneous',
                               'MISCELLANEOUS');


return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GENERAL_DATA_INSTALL.FIF_GL_XREF',
                                            to_char(SQLCODE));
      return FALSE;
END FIF_GL_XREF;
-----------------------------------------------------------------
END GENERAL_DATA_INSTALL;
/

