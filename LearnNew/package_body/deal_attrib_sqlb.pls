CREATE OR REPLACE PACKAGE BODY DEAL_ATTRIB_SQL AS
-----------------------------------------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    30-Jan-2008
-- Mod Ref:     Mod number. N32
-- Mod Details: Added logic to handle Supplier group and hierarchy
-----------------------------------------------------------------------------------------------------------------
-- Mod By        : Wipro/Shaestha, shaestha.naz@in.tesco.com
-- Mod Date      : 05-Mar-2008
-- Mod Ref       : Mod number N53
-- Mod Details   : Crete new function
-- Function Name : TSL_GET_BILLING_TYPE
-- Purpose:      : This function will return the BILLING_TYPE attribute for the passed Deal ID and Deal Detail ID.
------------------------------------------------------------------------------------------------------------------
-- Mod By      : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date    : 09-May-2008
-- Mod Ref     : ModN111
-- Mod Details : Added new function TSL_GET_COMMON_DEAL_IND.This function will return the
--               TSL_COMMON_DEAL attribute for the passed Deal ID
---------------------------------------------------------------------------------------------
-- Mod By      : Sayali Bulakh sayali.bulakh@wipro.com
-- Mod Date    : 19-Mar-2008
-- Mod Ref     : ModN45
-- Mod Details : Added a new variable tsl_historical_type to the 'get_header_info' function.
---------------------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date     : 18-May-2010
-- Mod Ref      : CR316
-- Mod Details  : Added  new function TSL_DEAL_DEFAULTS
----------------------------------------------------------------------------------------
-- Mod By       : Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com
-- Mod Date     : 06-Jul-2011
-- Mod Ref      : DefNBS023196
-- Mod Details  : Added new function ACTIVE_OVERLAP_DEAL_EXISTS
-- Mod Purpose	: When the user is adding the item to a deal  a validation needs to be in place to check
--                if there exists an another deal of same billing type and with the same Deal discount value(deal threshold)
--                wherein the end date of  former deal is not same as the start date of the later and vice versa.
--                i.e  For an item a deal of particular billing type cannot start on the same date as the end date of another deal
--                on the same item, deal type and discount value.
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Mod By       : Muthukumar S, muthukumar.sathiyaseelan@in.tesco.com
-- Mod Date     : 29-mar-2011
-- Mod Ref      : DefNBS024488
-- Mod Details  : To check only active deal for the overlapping deal exists
----------------------------------------------------------------------------------------------

FUNCTION GET_HEADER_INFO(O_error_message                IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_partner_type                 IN OUT DEAL_HEAD.PARTNER_TYPE%TYPE,
                         O_partner_id                   IN OUT DEAL_HEAD.PARTNER_ID%TYPE,
                         O_supplier                     IN OUT DEAL_HEAD.SUPPLIER%TYPE,
                         O_type                         IN OUT DEAL_HEAD.TYPE%TYPE,
                         O_status                       IN OUT DEAL_HEAD.STATUS%TYPE,
                         O_currency_code                IN OUT DEAL_HEAD.CURRENCY_CODE%TYPE,
                         O_active_date                  IN OUT DEAL_HEAD.ACTIVE_DATE%TYPE,
                         O_close_date                   IN OUT DEAL_HEAD.CLOSE_DATE%TYPE,
                         O_create_id                    IN OUT DEAL_HEAD.CREATE_ID%TYPE,
                         O_ext_ref_no                   IN OUT DEAL_HEAD.EXT_REF_NO%TYPE,
                         O_order_no                     IN OUT DEAL_HEAD.ORDER_NO%TYPE,
                         O_billing_type                 IN OUT DEAL_HEAD.BILLING_TYPE%TYPE,
                         O_bill_back_period             IN OUT DEAL_HEAD.BILL_BACK_PERIOD%TYPE,
                         O_deal_appl_timing             IN OUT DEAL_HEAD.DEAL_APPL_TIMING%TYPE,
                         O_threshold_limit_type         IN OUT DEAL_HEAD.THRESHOLD_LIMIT_TYPE%TYPE,
                         O_threshold_limit_uom          IN OUT DEAL_HEAD.THRESHOLD_LIMIT_UOM%TYPE,
                         O_rebate_ind                   IN OUT DEAL_HEAD.REBATE_IND%TYPE,
                         O_rebate_calc_type             IN OUT DEAL_HEAD.REBATE_CALC_TYPE%TYPE,
                         O_growth_rebate_ind            IN OUT DEAL_HEAD.GROWTH_REBATE_IND%TYPE,
                         O_hist_comp_start_date         IN OUT DEAL_HEAD.HISTORICAL_COMP_START_DATE%TYPE,
                         O_hist_comp_end_date           IN OUT DEAL_HEAD.HISTORICAL_COMP_END_DATE%TYPE,
                         O_rebate_purch_sales_ind       IN OUT DEAL_HEAD.REBATE_PURCH_SALES_IND%TYPE,
                         O_deal_reporting_level         IN OUT DEAL_HEAD.DEAL_REPORTING_LEVEL%TYPE,
                         O_bill_back_method             IN OUT DEAL_HEAD.BILL_BACK_METHOD%TYPE,
                         O_deal_income_calc             IN OUT DEAL_HEAD.DEAL_INCOME_CALCULATION%TYPE,
                         O_invoice_proc_logic           IN OUT DEAL_HEAD.INVOICE_PROCESSING_LOGIC%TYPE,
                         O_stock_ledger_ind             IN OUT DEAL_HEAD.STOCK_LEDGER_IND%TYPE,
                         O_include_vat_ind              IN OUT DEAL_HEAD.INCLUDE_VAT_IND%TYPE,
                         O_billing_partner_type         IN OUT DEAL_HEAD.BILLING_PARTNER_TYPE%TYPE,
                         O_billing_partner_id           IN OUT DEAL_HEAD.BILLING_PARTNER_ID%TYPE,
                         O_billing_supplier_id          IN OUT DEAL_HEAD.BILLING_SUPPLIER_ID%TYPE,
                         O_growth_rate_to_date          IN OUT DEAL_HEAD.GROWTH_RATE_TO_DATE%TYPE,
                         O_turnover_to_date             IN OUT DEAL_HEAD.TURNOVER_TO_DATE%TYPE,
                         O_actual_monies_earned_to_date IN OUT DEAL_HEAD.ACTUAL_MONIES_EARNED_TO_DATE%TYPE,
                         O_security_ind                 IN OUT DEAL_HEAD.SECURITY_IND%TYPE,
                         O_est_next_invoice_date        IN OUT DEAL_HEAD.EST_NEXT_INVOICE_DATE%TYPE,
                         O_last_invoice_date            IN OUT DEAL_HEAD.LAST_INVOICE_DATE%TYPE,
                         I_deal_id                      IN     DEAL_HEAD.DEAL_ID%TYPE)

   RETURN BOOLEAN IS

   L_track_pack_level_ind         DEAL_HEAD.TRACK_PACK_LEVEL_IND%TYPE;
   L_historical_type              DEAL_HEAD.TSL_HISTORICAL_TYPE%TYPE;

BEGIN
   --- Overloaded for call from RPM_PRICE_UPDATER_SQL
   ---
    IF deal_attrib_sql.get_header_info(o_error_message,
                                       o_partner_type,
                                       o_partner_id,
                                       o_supplier,
                                       o_type,
                                       o_status,
                                       o_currency_code,
                                       o_active_date,
                                       o_close_date,
                                       o_create_id,
                                       o_ext_ref_no,
                                       o_order_no,
                                       o_billing_type,
                                       o_bill_back_period,
                                       o_deal_appl_timing,
                                       o_threshold_limit_type,
                                       o_threshold_limit_uom,
                                       o_rebate_ind,
                                       o_rebate_calc_type,
                                       -- ModN45 Sayali Bulakh sayali.bulakh@wipro.com, Begin
                                       l_historical_type,
                                       -- ModN45 Sayali Bulakh sayali.bulakh@wipro.com, End
                                       o_hist_comp_start_date,
                                       o_hist_comp_end_date,
                                       o_rebate_purch_sales_ind,
                                       o_deal_reporting_level,
                                       o_bill_back_method,
                                       o_deal_income_calc,
                                       o_invoice_proc_logic,
                                       o_stock_ledger_ind,
                                       o_include_vat_ind,
                                       o_billing_partner_type,
                                       o_billing_partner_id,
                                       o_billing_supplier_id,
                                       o_growth_rate_to_date,
                                       o_turnover_to_date,
                                       o_actual_monies_earned_to_date,
                                       o_security_ind,
                                       o_est_next_invoice_date,
                                       o_last_invoice_date,
                                       l_track_pack_level_ind,
                                       i_deal_id) = FALSE THEN
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.GET_HEADER_INFO',
         to_char(SQLCODE));
      return FALSE;

END GET_HEADER_INFO;
----------------------------------------------------------------------------------------
  FUNCTION get_header_info(o_error_message                IN OUT rtk_errors.rtk_text%TYPE,
                           o_partner_type                 IN OUT deal_head.partner_type%TYPE,
                           o_partner_id                   IN OUT deal_head.partner_id%TYPE,
                           o_supplier                     IN OUT deal_head.supplier%TYPE,
                           o_type                         IN OUT deal_head.TYPE%TYPE,
                           o_status                       IN OUT deal_head.status%TYPE,
                           o_currency_code                IN OUT deal_head.currency_code%TYPE,
                           o_active_date                  IN OUT deal_head.active_date%TYPE,
                           o_close_date                   IN OUT deal_head.close_date%TYPE,
                           o_create_id                    IN OUT deal_head.create_id%TYPE,
                           o_ext_ref_no                   IN OUT deal_head.ext_ref_no%TYPE,
                           o_order_no                     IN OUT deal_head.order_no%TYPE,
                           o_billing_type                 IN OUT deal_head.billing_type%TYPE,
                           o_bill_back_period             IN OUT deal_head.bill_back_period%TYPE,
                           o_deal_appl_timing             IN OUT deal_head.deal_appl_timing%TYPE,
                           o_threshold_limit_type         IN OUT deal_head.threshold_limit_type%TYPE,
                           o_threshold_limit_uom          IN OUT deal_head.threshold_limit_uom%TYPE,
                           o_rebate_ind                   IN OUT deal_head.rebate_ind%TYPE,
                           o_rebate_calc_type             IN OUT deal_head.rebate_calc_type%TYPE,
													 -- ModN45 Sayali Bulakh sayali.bulakh@wipro.com, Begin
                           o_historical_type              IN OUT deal_head.tsl_historical_type%TYPE,
                           -- ModN45 Sayali Bulakh sayali.bulakh@wipro.com, End
                           o_hist_comp_start_date         IN OUT deal_head.historical_comp_start_date%TYPE,
                           o_hist_comp_end_date           IN OUT deal_head.historical_comp_end_date%TYPE,
                           o_rebate_purch_sales_ind       IN OUT deal_head.rebate_purch_sales_ind%TYPE,
                           o_deal_reporting_level         IN OUT deal_head.deal_reporting_level%TYPE,
                           o_bill_back_method             IN OUT deal_head.bill_back_method%TYPE,
                           o_deal_income_calc             IN OUT deal_head.deal_income_calculation%TYPE,
                           o_invoice_proc_logic           IN OUT deal_head.invoice_processing_logic%TYPE,
                           o_stock_ledger_ind             IN OUT deal_head.stock_ledger_ind%TYPE,
                           o_include_vat_ind              IN OUT deal_head.include_vat_ind%TYPE,
                           o_billing_partner_type         IN OUT deal_head.billing_partner_type%TYPE,
                           o_billing_partner_id           IN OUT deal_head.billing_partner_id%TYPE,
                           o_billing_supplier_id          IN OUT deal_head.billing_supplier_id%TYPE,
                           o_growth_rate_to_date          IN OUT deal_head.growth_rate_to_date%TYPE,
                           o_turnover_to_date             IN OUT deal_head.turnover_to_date%TYPE,
                           o_actual_monies_earned_to_date IN OUT deal_head.actual_monies_earned_to_date%TYPE,
                           o_security_ind                 IN OUT deal_head.security_ind%TYPE,
                           o_est_next_invoice_date        IN OUT deal_head.est_next_invoice_date%TYPE,
                           o_last_invoice_date            IN OUT deal_head.last_invoice_date%TYPE,
                           o_track_pack_level_ind         IN OUT deal_head.track_pack_level_ind%TYPE,
                           i_deal_id                      IN deal_head.deal_id%TYPE)

   RETURN BOOLEAN IS


    CURSOR c_get_info IS
      SELECT partner_type,
             partner_id,
             supplier,
             TYPE,
             status,
             currency_code,
             active_date,
             close_date,
             create_id,
             ext_ref_no,
             order_no,
             billing_type,
             bill_back_period,
             deal_appl_timing,
             threshold_limit_type,
             threshold_limit_uom,
             rebate_ind,
             rebate_calc_type,
             -- ModN45 Sayali Bulakh sayali.bulakh@wipro.com, Begin
             tsl_historical_type,
             -- ModN45 Sayali Bulakh sayali.bulakh@wipro.com, End
             historical_comp_start_date,
             historical_comp_end_date,
             rebate_purch_sales_ind,
             deal_reporting_level,
             bill_back_method,
             deal_income_calculation,
             invoice_processing_logic,
             stock_ledger_ind,
             include_vat_ind,
             billing_partner_type,
             billing_partner_id,
             billing_supplier_id,
             growth_rate_to_date,
             turnover_to_date,
             actual_monies_earned_to_date,
             security_ind,
             est_next_invoice_date,
             last_invoice_date,
             track_pack_level_ind
        FROM deal_head
       WHERE deal_id = i_deal_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_INFO','DEAL_HEAD',to_char(I_deal_id));
   open C_GET_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_INFO','DEAL_HEAD',to_char(I_deal_id));


   fetch C_GET_INFO into O_partner_type,
                         O_partner_id,
                         O_supplier,
                         O_type,
                         O_status,
                         O_currency_code,
                         O_active_date,
                         O_close_date,
                         O_create_id,
                         O_ext_ref_no,
                         O_order_no,
                         O_billing_type,
                         O_bill_back_period,
                         O_deal_appl_timing,
                         O_threshold_limit_type,
                         O_threshold_limit_uom,
                         O_rebate_ind,
                         O_rebate_calc_type,
                         -- ModN45 Sayali Bulakh sayali.bulakh@wipro.com, Begin
												 O_historical_type,
												 -- ModN45 Sayali Bulakh sayali.bulakh@wipro.com, End
                         O_hist_comp_start_date,
                         O_hist_comp_end_date,
                         O_rebate_purch_sales_ind,
                         O_deal_reporting_level,
                         O_bill_back_method,
                         O_deal_income_calc,
                         O_invoice_proc_logic,
                         O_stock_ledger_ind,
                         O_include_vat_ind,
                         O_billing_partner_type,
                         O_billing_partner_id,
                         O_billing_supplier_id,
                         O_growth_rate_to_date,
                         O_turnover_to_date,
                         O_actual_monies_earned_to_date,
                         O_security_ind,
                         O_est_next_invoice_date,
                         O_last_invoice_date,
                         O_track_pack_level_ind;

   ---
   if C_GET_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DEAL_ID',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE','C_GET_INFO','DEAL_HEAD',to_char(I_deal_id));
      close C_GET_INFO;
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_INFO','DEAL_HEAD',to_char(I_deal_id));
   close C_GET_INFO;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.GET_HEADER_INFO',
         to_char(SQLCODE));
      return FALSE;

END GET_HEADER_INFO;
----------------------------------------------------------------------------------------
FUNCTION GET_DEAL_COMP_TYPE_DESC(O_error_message   IN OUT VARCHAR2,
                                 O_desc            IN OUT DEAL_COMP_TYPE.DEAL_COMP_TYPE_DESC%TYPE,
                                 I_deal_comp_type  IN     DEAL_COMP_TYPE.DEAL_COMP_TYPE%TYPE)
   RETURN BOOLEAN IS
   cursor C_GET_COMP_DESC is
      select deal_comp_type_desc
        from deal_comp_type
       where deal_comp_type = I_deal_comp_type;
BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_COMP_DESC','DEAL_COMP_TYPE',I_deal_comp_type);
   open C_GET_COMP_DESC;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_COMP_DESC','DEAL_COMP_TYPE',I_deal_comp_type);
   fetch C_GET_COMP_DESC into O_desc;
   ---
   if C_GET_COMP_DESC%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DEAL_COMP_TYPE',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_DESC','DEAL_COMP_TYPE',I_deal_comp_type);
      close C_GET_COMP_DESC;
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_COMP_DESC','DEAL_COMP_TYPE',I_deal_comp_type);
   close C_GET_COMP_DESC;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_desc,
                             O_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_ATTRIB_SQL.GET_DEAL_COMP_TYPE_DESC',
                                             to_char(SQLCODE));
   return FALSE;
END GET_DEAL_COMP_TYPE_DESC;
-------------------------------------------------------------------------------------------
FUNCTION GET_MERCH_HIER(O_error_message    IN OUT VARCHAR2,
                        O_division         IN OUT DIVISION.DIVISION%TYPE,
                        O_division_name    IN OUT DIVISION.DIV_NAME%TYPE,
                        O_group_no         IN OUT GROUPS.GROUP_NO%TYPE,
                        O_group_name       IN OUT GROUPS.GROUP_NAME%TYPE,
                        O_dept             IN OUT DEPS.DEPT%TYPE,
                        O_dept_name        IN OUT DEPS.DEPT_NAME%TYPE,
                        O_class            IN OUT CLASS.CLASS%TYPE,
                        O_class_name       IN OUT CLASS.CLASS_NAME%TYPE,
                        O_subclass         IN OUT SUBCLASS.SUBCLASS%TYPE,
                        O_subclass_name    IN OUT SUBCLASS.SUB_NAME%TYPE,
                        O_item_grandparent IN OUT ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                        O_item_gp_desc     IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                        O_item_parent      IN OUT ITEM_MASTER.ITEM_PARENT%TYPE,
                        O_item_p_desc      IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                        O_diff_1           IN OUT ITEM_MASTER.DIFF_1%TYPE,
                        O_diff_1_desc      IN OUT DIFF_IDS.DIFF_DESC%TYPE,
                        O_diff_2           IN OUT ITEM_MASTER.DIFF_2%TYPE,
                        O_diff_2_desc      IN OUT DIFF_IDS.DIFF_DESC%TYPE,
                        O_diff_3           IN OUT ITEM_MASTER.DIFF_3%TYPE,
                        O_diff_3_desc      IN OUT DIFF_IDS.DIFF_DESC%TYPE,
                        O_diff_4           IN OUT ITEM_MASTER.DIFF_4%TYPE,
                        O_diff_4_desc      IN OUT DIFF_IDS.DIFF_DESC%TYPE,
                        I_merch_level      IN     VARCHAR2,
                        I_merch_value      IN     VARCHAR2,
                        I_get_descs        IN     BOOLEAN)
/* Definition of merch levels:
merch level 1      Company
merch level 2      @MH2 - Division
merch level 3      @MH3 - Group
merch level 4      @MH4 - Dept
merch level 5      @MH5 - Class
merch level 6      @MH6 - Subclass
merch level 7      Item Parent/Grandparent
merch level 8      Item Parent - Grandparent/Diff 1
merch level 9      Item Parent - Grandparent/Diff 2
merch level 10     Item Parent - Grandparent/Diff 3
merch level 11     Item Parent - Grandparent/Diff 4
merch level 12     Item
*/
   RETURN BOOLEAN IS
/*The following variables are used as dummies for the call to item_attrib_sql.get_info
  and item_attrib_sql.get_parent_info*/
   L_item_desc             ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_level            ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level            ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_status                ITEM_MASTER.STATUS%TYPE;
   L_pack_ind              ITEM_MASTER.PACK_IND%TYPE;
   L_retail_zone_group_id  ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE;
   L_sellable_ind          ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind         ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type             ITEM_MASTER.PACK_TYPE%TYPE;
   L_simple_pack_ind       ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_waste_type            ITEM_MASTER.WASTE_TYPE%TYPE;
   L_short_desc            ITEM_MASTER.SHORT_DESC%TYPE;
   L_waste_pct             ITEM_MASTER.WASTE_PCT%TYPE;
   L_default_waste_pct     ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;
   L_item_number_type      ITEM_MASTER.ITEM_NUMBER_TYPE%TYPE;
   L_order_as_type         ITEM_MASTER.ORDER_AS_TYPE%TYPE;
   L_format_id             ITEM_MASTER.FORMAT_ID%TYPE;
   L_prefix                ITEM_MASTER.PREFIX%TYPE;
   L_store_ord_mult        ITEM_MASTER.STORE_ORD_MULT%TYPE;
   L_contains_inner_ind    ITEM_MASTER.CONTAINS_INNER_IND%TYPE;
   L_diff_1_type           V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_1_id_group_ind   V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_2_type           V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_2_id_group_ind   V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_3_type           V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_3_id_group_ind   V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_diff_4_type           V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE;
   L_diff_4_id_group_ind   V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE;
   L_dummy_item            ITEM_MASTER.ITEM%TYPE;
/*The following variables are used functionally*/
   L_dept                     DEPS.DEPT%TYPE                    := NULL;
   L_dept_name                DEPS.DEPT_NAME%TYPE               := NULL;
   L_class                    CLASS.CLASS%TYPE                  := NULL;
   L_class_name               CLASS.CLASS_NAME%TYPE             := NULL;
   L_subclass                 SUBCLASS.SUBCLASS%TYPE            := NULL;
   L_subclass_name            SUBCLASS.SUB_NAME%TYPE            := NULL;
   L_division                 DIVISION.DIVISION%TYPE            := NULL;
   L_division_name            DIVISION.DIV_NAME%TYPE            := NULL;
   L_group_no                 GROUPS.GROUP_NO%TYPE              := NULL;
   L_group_name               GROUPS.GROUP_NAME%TYPE            := NULL;
   L_item_grandparent         ITEM_MASTER.ITEM_GRANDPARENT%TYPE := NULL;
   L_item_gp_desc             ITEM_MASTER.ITEM_DESC%TYPE        := NULL;
   L_item_parent              ITEM_MASTER.ITEM_PARENT%TYPE      := NULL;
   L_item_p_desc              ITEM_MASTER.ITEM_DESC%TYPE        := NULL;
   L_diff_1                   ITEM_MASTER.DIFF_1%TYPE           := NULL;
   L_diff_1_desc              DIFF_IDS.DIFF_DESC%TYPE           := NULL;
   L_diff_2                   ITEM_MASTER.DIFF_2%TYPE           := NULL;
   L_diff_2_desc              DIFF_IDS.DIFF_DESC%TYPE           := NULL;
   L_diff_3                   ITEM_MASTER.DIFF_3%TYPE           := NULL;
   L_diff_3_desc              DIFF_IDS.DIFF_DESC%TYPE           := NULL;
   L_diff_4                   ITEM_MASTER.DIFF_4%TYPE           := NULL;
   L_diff_4_desc              DIFF_IDS.DIFF_DESC%TYPE           := NULL;
BEGIN
   if I_merch_level is NULL or I_merch_value is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.GET_MERCH_HIER',NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_merch_level = '12' then
      if ITEM_ATTRIB_SQL.GET_INFO (O_error_message,
                                   L_item_desc,
                                   L_item_level,
                                   L_tran_level,
                                   L_status,
                                   L_pack_ind,
                                   L_dept,
                                   L_dept_name,
                                   L_class,
                                   L_class_name,
                                   L_subclass,
                                   L_subclass_name,
                                   L_retail_zone_group_id,
                                   L_sellable_ind,
                                   L_orderable_ind,
                                   L_pack_type,
                                   L_simple_pack_ind,
                                   L_waste_type,
                                   L_item_parent,
                                   L_item_grandparent,
                                   L_short_desc,
                                   L_waste_pct,
                                   L_default_waste_pct,
                                   L_item_number_type,
                                   O_diff_1,
                                   O_diff_1_desc,
                                   L_diff_1_type,
                                   L_diff_1_id_group_ind,
                                   O_diff_2,
                                   O_diff_2_desc,
                                   L_diff_2_type,
                                   L_diff_2_id_group_ind,
                                   O_diff_3,
                                   O_diff_3_desc,
                                   L_diff_3_type,
                                   L_diff_3_id_group_ind,
                                   O_diff_4,
                                   O_diff_4_desc,
                                   L_diff_4_type,
                                   L_diff_4_id_group_ind,
                                   L_order_as_type,
                                   L_format_id,
                                   L_prefix,
                                   L_store_ord_mult,
                                   L_contains_inner_ind,
                                   I_merch_value) = FALSE then
          return FALSE;
      end if;
      ---
   end if;
   ---
   if I_merch_level >= 7 then
      ---
      --If the level is 7, 8, 9, 10, or 11, the item is an item parent.
      --If the item parent has a parent (i.e. the item family has a tran level of 3)
      --we need to retrieve the item_granparent value.
      ---
      if I_merch_level != 12 then
         L_item_parent := I_merch_value;
         --- if the merch value is an item parent, get the item grandparent value
         if ITEM_ATTRIB_SQL.GET_PARENT_INFO  (O_error_message,
                                              L_item_grandparent,
                                              L_item_gp_desc,
                                              L_dummy_item,
                                              L_item_desc,
                                              L_item_parent) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      if I_get_descs = TRUE then
         if L_item_grandparent is not NULL then
            if ITEM_ATTRIB_SQL.GET_DESC (O_error_message,
                                         L_item_gp_desc,
                                         L_item_grandparent) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         if L_item_parent is not NULL then
            if ITEM_ATTRIB_SQL.GET_DESC (O_error_message,
                                         L_item_p_desc,
                                         L_item_parent) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      ---
      O_item_grandparent      := L_item_grandparent;
      O_item_gp_desc          := L_item_gp_desc;
      O_item_parent           := L_item_parent;
      O_item_p_desc           := L_item_p_desc;
      ---
      if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                        I_merch_value,
                                        L_dept,
                                        L_class,
                                        L_subclass) = FALSE then
         return FALSE;
      end if;
      ---
      if I_get_descs then
         if MERCH_ATTRIB_SQL.GET_MERCH_HIER_NAMES(O_error_message,
                                                  L_dept_name,
                                                  L_class_name,
                                                  L_subclass_name,
                                                  L_dept,
                                                  L_class,
                                                  L_subclass) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      O_dept          := L_dept;
      O_dept_name     := L_dept_name;
      O_class         := L_class;
      O_class_name    := L_class_name;
      O_subclass      := L_subclass;
      O_subclass_name := L_subclass_name;
   end if;
   ---
   if I_merch_level >= 4 then
      if I_merch_level in (4,5,6) then
         L_dept := to_number(I_merch_value);
      end if;
      if DEPT_ATTRIB_SQL.GET_DEPT_HIER(O_error_message,
                                       L_group_no,
                                       L_division,
                                       L_dept) = FALSE then
         return FALSE;
      end if;
      ---
      if I_get_descs then
         if MERCH_ATTRIB_SQL.DIVISION_NAME(O_error_message,
                                           L_division,
                                           L_division_name) = FALSE then
            return FALSE;
         end if;
         ---
         if MERCH_ATTRIB_SQL.GROUP_NAME(O_error_message,
                                        L_group_no,
                                        L_group_name) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      O_division      := L_division;
      O_division_name := L_division_name;
      O_group_no      := L_group_no;
      O_group_name    := L_group_name;
   end if;
   ---
   if I_merch_level = '3' then
      if MERCH_ATTRIB_SQL.GET_GROUP_DIVISION(O_error_message,
                                             L_division,
                                             to_number(I_merch_value)) = FALSE then
         return FALSE;
      end if;
      if I_get_descs then
         if MERCH_ATTRIB_SQL.DIVISION_NAME(O_error_message,
                                           L_division,
                                           L_division_name) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      O_division      := L_division;
      O_division_name := L_division_name;
   end if;
   ---
   if I_merch_level = '2' then
      if MERCH_ATTRIB_SQL.DIVISION_NAME(O_error_message,
                                        to_number(I_merch_value),
                                        L_division_name) = FALSE then
            return FALSE;
      end if;
      if I_get_descs then
         O_division_name := L_division_name;
      end if;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.GET_MERCH_HIER',
         to_char(SQLCODE));
   return FALSE;
END GET_MERCH_HIER;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ORG_HIER(O_error_message   IN OUT VARCHAR2,
                      O_chain             IN OUT CHAIN.CHAIN%TYPE,
                      O_chain_name        IN OUT CHAIN.CHAIN_NAME%TYPE,
                      O_area              IN OUT AREA.AREA%TYPE,
                      O_area_name         IN OUT AREA.AREA_NAME%TYPE,
                      O_region            IN OUT REGION.REGION%TYPE,
                      O_region_name       IN OUT REGION.REGION_NAME%TYPE,
                      O_district          IN OUT DISTRICT.DISTRICT%TYPE,
                      O_district_name     IN OUT DISTRICT.DISTRICT_NAME%TYPE,
                      I_org_level         IN     VARCHAR2,
                      I_org_value         IN     NUMBER,
                      I_get_descs         IN     BOOLEAN)
   RETURN BOOLEAN IS
   L_chain              CHAIN.CHAIN%TYPE;
   L_chain_name         CHAIN.CHAIN_NAME%TYPE;
   L_area               AREA.AREA%TYPE;
   L_area_name          AREA.AREA_NAME%TYPE;
   L_region             REGION.REGION%TYPE;
   L_region_name        REGION.REGION_NAME%TYPE;
   L_district           DISTRICT.DISTRICT%TYPE;
   L_district_name      DISTRICT.DISTRICT_NAME%TYPE;
BEGIN
   if I_org_level is NULL or I_org_value is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.GET_ORG_HIER',NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_org_level = '5' then
      if STORE_ATTRIB_SQL.GET_STORE_DISTRICT(O_error_message,
          L_district,
          I_org_value) = FALSE then
         return FALSE;
      end if;
      ---
      if I_get_descs then
         if ORGANIZATION_ATTRIB_SQL.DISTRICT_NAME(O_error_message,
               L_district,
               L_district_name) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      O_district      := L_district;
      O_district_name := L_district_name;
   end if;
   ---
   if I_org_level in ('4','5') then
      if I_org_level = '4' then
         L_district := I_org_value;
      end if;
      ---
      if ORGANIZATION_ATTRIB_SQL.GET_DISTRICT_REGION(O_error_message,
                  L_region,
                  L_district) = FALSE then
         return FALSE;
      end if;
      ---
      if I_get_descs then
         if ORGANIZATION_ATTRIB_SQL.REGION_NAME(O_error_message,
             L_region,
             L_region_name) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      O_region      := L_region;
      O_region_name := L_region_name;
   end if;
   ---
   if I_org_level in ('3','4','5') then
      if I_org_level = '3' then
         L_region := I_org_value;
      end if;
      ---
      if ORGANIZATION_ATTRIB_SQL.GET_REGION_AREA(O_error_message,
              L_area_name,
              L_area,
              L_region) = FALSE then
         return FALSE;
      end if;
      ---
      O_area := L_area;
      O_area_name := L_area_name;
   end if;
   ---
   if I_org_level in ('2','3','4','5') then
      if I_org_level = '2' then
         L_area := I_org_value;
      end if;
      ---
      if ORGANIZATION_ATTRIB_SQL.GET_AREA_CHAIN(O_error_message,
             L_chain_name,
             L_chain,
             L_area) = FALSE then
         return FALSE;
      end if;
      ---
      O_chain      := L_chain;
      O_chain_name := L_chain_name;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.GET_ORG_HIER',
         to_char(SQLCODE));
   return FALSE;
END GET_ORG_HIER;
---------------------------------------------------------------------------------------------------
FUNCTION GET_NEXT_DEAL_ID(O_error_message  IN OUT VARCHAR2,
                          O_deal_id        IN OUT DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS
   L_deal_sequence      DEAL_HEAD.DEAL_ID%TYPE;
   L_wrap_sequence_no   DEAL_HEAD.DEAL_ID%TYPE;
   L_first_time         VARCHAR2(3) := 'Y';
   L_dummy              VARCHAR2(1);
   cursor C_DEALHEAD_EXISTS is
      select 'x'
        from deal_head
       where deal_id = O_deal_id;
BEGIN
   LOOP
      select deal_sequence.NEXTVAL
        into L_deal_sequence
        from sys.dual;
      ---
      if L_first_time = 'Y' then
         L_wrap_sequence_no := L_deal_sequence;
         L_first_time := 'N';
      elsif L_deal_sequence = L_wrap_sequence_no then
         O_error_message := SQL_LIB.CREATE_MSG('NO_DEAL_ID',NULL,NULL,NULL);
         return FALSE;
      end if;
      ---
      O_deal_id := L_deal_sequence;
      ---
      SQL_LIB.SET_MARK('OPEN','C_DEALHEAD_EXISTS','DEAL_HEAD',to_char(O_deal_id));
      open C_DEALHEAD_EXISTS;
      ---
      SQL_LIB.SET_MARK('FETCH','C_DEALHEAD_EXISTS','DEAL_HEAD',to_char(O_deal_id));
      fetch C_DEALHEAD_EXISTS into L_dummy;
      ---
      if C_DEALHEAD_EXISTS%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_DEALHEAD_EXISTS','DEAL_HEAD',to_char(O_deal_id));
         close C_DEALHEAD_EXISTS;
         exit;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_DEALHEAD_EXISTS','DEAL_HEAD',to_char(O_deal_id));
      close C_DEALHEAD_EXISTS;
      ---
   END LOOP;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.GET_NEXT_DEAL_ID',
         to_char(SQLCODE));
   return FALSE;
END GET_NEXT_DEAL_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_NEXT_DEAL_DETAIL_ID(O_error_message   IN OUT VARCHAR2,
                                 O_deal_detail_id  IN OUT DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                                 I_deal_id         IN     DEAL_ITEMLOC.DEAL_ID%TYPE)
   RETURN BOOLEAN IS
   cursor C_GET_MAX_DETAIL_ID is
      select nvl(MAX(deal_detail_id),0) + 1
        from deal_detail
       where deal_id = I_deal_id;
BEGIN
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.GET_NEXT_DEAL_DETAIL_ID',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_MAX_DETAIL_ID','DEAL_DETAIL',to_char(I_deal_id));
   open C_GET_MAX_DETAIL_ID;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_MAX_DETAIL_ID','DEAL_DETAIL',to_char(I_deal_id));
   fetch C_GET_MAX_DETAIL_ID into O_deal_detail_id;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_MAX_DETAIL_ID','DEAL_DETAIL',to_char(I_deal_id));
   close C_GET_MAX_DETAIL_ID;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.GET_NEXT_DEAL_DETAIL_ID',
         to_char(SQLCODE));
   return FALSE;
END GET_NEXT_DEAL_DETAIL_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_NEXT_DEALITLC_SEQ(O_error_message   IN OUT VARCHAR2,
                               O_seq_no          IN OUT DEAL_ITEMLOC.SEQ_NO%TYPE,
                               I_deal_id         IN     DEAL_ITEMLOC.DEAL_ID%TYPE,
                               I_deal_detail_id  IN     DEAL_ITEMLOC.DEAL_DETAIL_ID%TYPE)
   RETURN BOOLEAN IS
   cursor C_GET_MAX_SEQ_NO is
      select nvl(MAX(seq_no),0) + 1
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;
BEGIN
   if I_deal_id is NULL or I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.GET_NEXT_DEALITLC_SEQ',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_MAX_SEQ_NO','DEAL_ITEMLOC',to_char(I_deal_id));
   open C_GET_MAX_SEQ_NO;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_MAX_SEQ_NO','DEAL_ITEMLOC',to_char(I_deal_id));
   fetch C_GET_MAX_SEQ_NO into O_seq_no;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_MAX_SEQ_NO','DEAL_ITEMLOC',to_char(I_deal_id));
   close C_GET_MAX_SEQ_NO;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.GET_NEXT_DEALITLC_SEQ',
         to_char(SQLCODE));
   return FALSE;
END GET_NEXT_DEALITLC_SEQ;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ROOT_ITEMLOC_LEVEL(O_error_message      IN OUT VARCHAR2,
                                O_exists             IN OUT BOOLEAN,
                                O_merch_level        IN OUT DEAL_ITEMLOC.MERCH_LEVEL%TYPE,
                                O_org_level          IN OUT DEAL_ITEMLOC.ORG_LEVEL%TYPE,
                                O_origin_country_id  IN OUT DEAL_ITEMLOC.ORIGIN_COUNTRY_ID%TYPE,
                                I_deal_id            IN     DEAL_HEAD.DEAL_ID%TYPE,
                                I_deal_detail_id     IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE)
   RETURN BOOLEAN IS
   L_merch_level        DEAL_ITEMLOC.MERCH_LEVEL%TYPE;
   L_org_level          DEAL_ITEMLOC.ORG_LEVEL%TYPE;
   L_origin_country_id  DEAL_ITEMLOC.ORIGIN_COUNTRY_ID%TYPE;
   cursor C_GET_ROOT_ITEMLOC is
      select merch_level,
             org_level,
             origin_country_id
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and excl_ind = 'N';
BEGIN
   if I_deal_id is NULL or I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.GET_ROOT_ITEMLOC_LEVEL',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_ROOT_ITEMLOC','DEAL_ITEMLOC',to_char(I_deal_id));
   open C_GET_ROOT_ITEMLOC;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_ROOT_ITEMLOC','DEAL_ITEMLOC',to_char(I_deal_id));
   fetch C_GET_ROOT_ITEMLOC into L_merch_level,
                                 L_org_level,
                                 L_origin_country_id;
   ---
   if C_GET_ROOT_ITEMLOC%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
      O_merch_level       := L_merch_level;
      O_org_level         := L_org_level;
      O_origin_country_id := L_origin_country_id;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_ROOT_ITEMLOC','DEAL_ITEMLOC',to_char(I_deal_id));
   close C_GET_ROOT_ITEMLOC;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.GET_ROOT_ITEMLOC_LEVEL',
         to_char(SQLCODE));
   return FALSE;
END GET_ROOT_ITEMLOC_LEVEL;
---------------------------------------------------------------------------------------------------
FUNCTION ACTIVE_ANNUAL_DEAL_EXISTS(O_error_message    IN OUT VARCHAR2,
                                   O_exists           IN OUT BOOLEAN,
                                   O_close_date       IN OUT DEAL_HEAD.CLOSE_DATE%TYPE,
                                   O_deal_id          IN OUT DEAL_HEAD.DEAL_ID%TYPE,
                                   I_partner_type     IN     DEAL_HEAD.PARTNER_TYPE%TYPE,
                                   I_partner_id       IN     DEAL_HEAD.PARTNER_ID%TYPE,
                                   I_supplier         IN     DEAL_HEAD.SUPPLIER%TYPE)
   RETURN BOOLEAN IS
   L_deal_id         DEAL_HEAD.DEAL_ID%TYPE;
   L_close_date      DEAL_HEAD.CLOSE_DATE%TYPE;
   cursor C_CHECK_ACTIVE_DEAL is
      select dh.deal_id, dh.close_date
        from deal_head dh,
             period p
       where dh.status = 'A'
         and (dh.active_date <= p.vdate
              and ((dh.close_date >= p.vdate and dh.close_date is not NULL)
              or dh.close_date is NULL))
         and dh.type = 'A'
         and ((dh.partner_id = I_partner_id and I_partner_id is not NULL and dh.partner_type = I_partner_type)
              or (dh.supplier = I_supplier and I_supplier is not NULL));
BEGIN
   if I_partner_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.ACTIVE_ANNUAL_DEAL_EXISTS',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_partner_type = 'S' and I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.ACTIVE_ANNUAL_DEAL_EXISTS',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   /*  30-Jan-2008   Wipro/Jk  Mod N32 Begin */
   if I_partner_type in ('S1','S2','S3', 'SG', 'SH') and I_partner_id is NULL then
   /*  30-Jan-2008   Wipro/Jk  Mod N32 End   */
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.ACTIVE_ANNUAL_DEAL_EXISTS',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_ACTIVE_DEAL','DEAL_HEAD',to_char(O_deal_id));
   open C_CHECK_ACTIVE_DEAL;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ACTIVE_DEAL','DEAL_HEAD',to_char(O_deal_id));
   fetch C_CHECK_ACTIVE_DEAL into L_deal_id,
                                  L_close_date;
   ---
   if C_CHECK_ACTIVE_DEAL%FOUND then
      O_exists := TRUE;
      O_deal_id := L_deal_id;
      O_close_date := L_close_date;
   else
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ACTIVE_DEAL','DEAL_HEAD',to_char(O_deal_id));
   close C_CHECK_ACTIVE_DEAL;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.ACTIVE_ANNUAL_DEAL_EXISTS',
         to_char(SQLCODE));
   return FALSE;
END ACTIVE_ANNUAL_DEAL_EXISTS;
---------------------------------------------------------------------------------------------------
FUNCTION PENDING_ANNUAL_DEAL_EXISTS(O_error_message    IN OUT VARCHAR2,
                                    O_exists           IN OUT BOOLEAN,
                                    O_active_date      IN OUT DEAL_HEAD.ACTIVE_DATE%TYPE,
                                    O_close_date       IN OUT DEAL_HEAD.CLOSE_DATE%TYPE,
                                    O_deal_id          IN OUT DEAL_HEAD.DEAL_ID%TYPE,
                                    I_active_date      IN     DEAL_HEAD.ACTIVE_DATE%TYPE,
                                    I_close_date       IN     DEAL_HEAD.CLOSE_DATE%TYPE,
                                    I_partner_type     IN     DEAL_HEAD.PARTNER_TYPE%TYPE,
                                    I_partner_id       IN     DEAL_HEAD.PARTNER_ID%TYPE,
                                    I_supplier         IN     DEAL_HEAD.SUPPLIER%TYPE,
                                    I_deal_id          IN     DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS
   L_deal_id         DEAL_HEAD.DEAL_ID%TYPE;
   L_active_date     DEAL_HEAD.ACTIVE_DATE%TYPE;
   L_close_date      DEAL_HEAD.CLOSE_DATE%TYPE;
   cursor C_CHECK_PENDING_DEAL is
      select dh.deal_id, dh.active_date, dh.close_date
        from deal_head dh
       where dh.status = 'A'
         and dh.type = 'A'
         and ((dh.active_date < I_active_date and (dh.close_date >= I_active_date and dh.close_date is not NULL)
              or (dh.close_date is NULL and dh.active_date <= I_close_date))
              or (dh.active_date >= I_active_date and (I_close_date is NULL or (I_close_date is not NULL and
                  dh.active_date <= I_close_date)))
              or dh.close_date is NULL and I_close_date is NULL)
         and ((dh.partner_id = I_partner_id and I_partner_id is not NULL and dh.partner_type = I_partner_type)
              or (dh.supplier = I_supplier and I_supplier is not NULL))
         and dh.deal_id != I_deal_id
    order by active_date;
BEGIN
   if I_partner_type is NULL or I_active_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.PENDING_ANNUAL_DEAL_EXISTS',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_partner_type = 'S' and I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.PENDING_ANNUAL_DEAL_EXISTS',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   /*  30-Jan-2008   Wipro/Jk  Mod N32 Begin */
   if I_partner_type in ('S1','S2','S3', 'SG', 'SH') and I_partner_id is NULL then
   /*  30-Jan-2008   Wipro/Jk  Mod N32 End   */
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.PENDING_ANNUAL_DEAL_EXISTS',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.PENDING_ANNUAL_DEAL_EXISTS',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_PENDING_DEAL','DEAL_HEAD',to_char(O_deal_id));
   open C_CHECK_PENDING_DEAL;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_PENDING_DEAL','DEAL_HEAD',to_char(O_deal_id));
   fetch C_CHECK_PENDING_DEAL into L_deal_id,
                                   L_active_date,
                                   L_close_date;
   ---
   if C_CHECK_PENDING_DEAL%FOUND then
      O_exists := TRUE;
      O_deal_id := L_deal_id;
      O_active_date := L_active_date;
      O_close_date := L_close_date;
   else
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_PENDING_DEAL','DEAL_HEAD',to_char(O_deal_id));
   close C_CHECK_PENDING_DEAL;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
         SQLERRM,
         'DEAL_ATTRIB_SQL.PENDING_ANNUAL_DEAL_EXISTS',
         to_char(SQLCODE));
   return FALSE;
END PENDING_ANNUAL_DEAL_EXISTS;


---------------------------------------------------------------------------------------------------
FUNCTION DEAL_DETAIL_INFO(O_error_message                  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          O_deal_comp_type                 IN OUT   DEAL_DETAIL.DEAL_COMP_TYPE%TYPE,
                          O_application_order              IN OUT   DEAL_DETAIL.APPLICATION_ORDER%TYPE,
                          O_collect_start_date             IN OUT   DEAL_DETAIL.COLLECT_START_DATE%TYPE,
                          O_collect_end_date               IN OUT   DEAL_DETAIL.COLLECT_END_DATE%TYPE,
                          O_cost_appl_ind                  IN OUT   DEAL_DETAIL.COST_APPL_IND%TYPE,
                          O_deal_class                     IN OUT   DEAL_DETAIL.DEAL_CLASS%TYPE,
                          O_tran_discount_ind              IN OUT   DEAL_DETAIL.TRAN_DISCOUNT_IND%TYPE,
                          O_calc_to_zero_ind               IN OUT   DEAL_DETAIL.CALC_TO_ZERO_IND%TYPE,
                          O_tal_forecast_units             IN OUT   DEAL_DETAIL.TOTAL_FORECAST_UNITS%TYPE,
                          O_tal_forecast_revenue           IN OUT   DEAL_DETAIL.TOTAL_FORECAST_REVENUE%TYPE,
                          O_tal_budget_turnover            IN OUT   DEAL_DETAIL.TOTAL_BUDGET_TURNOVER%TYPE,
                          O_tal_actual_forecast_turnover   IN OUT   DEAL_DETAIL.TOTAL_ACTUAL_FORECAST_TURNOVER%TYPE,
                          O_tal_baseline_growth_budget     IN OUT   DEAL_DETAIL.TOTAL_BASELINE_GROWTH_BUDGET%TYPE,
                          O_tal_baseline_growth_act_for    IN OUT   DEAL_DETAIL.TOTAL_BASELINE_GROWTH_ACT_FOR%TYPE,
                          I_deal_id                        IN       DEAL_DETAIL.DEAL_ID%TYPE,
                          I_deal_detail_id                 IN       DEAL_DETAIL.DEAL_DETAIL_ID%TYPE)

   RETURN BOOLEAN IS


   cursor C_GET_DETAIL_INFO is
      select deal_comp_type,
             application_order,
             collect_start_date,
             collect_end_date,
             cost_appl_ind,
             deal_class,
             tran_discount_ind,
             calc_to_zero_ind,
             total_forecast_units,
             total_forecast_revenue,
             total_budget_turnover,
             total_actual_forecast_turnover,
             total_baseline_growth_budget,
             total_baseline_growth_act_for
        from deal_detail
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;

BEGIN
   if I_deal_id is NULL or I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_ATTRIB_SQL.DEAL_DETAIL_INFO',
          NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_DETAIL_INFO','DEAL_DETAIL',to_char(I_deal_id));
   open C_GET_DETAIL_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_DETAIL_INFO','DEAL_DETAIL',to_char(I_deal_id));


   fetch C_GET_DETAIL_INFO into O_deal_comp_type,
                                O_application_order,
                                O_collect_start_date,
                                O_collect_end_date,
                                O_cost_appl_ind,
                                O_deal_class,
                                O_tran_discount_ind,
                                O_calc_to_zero_ind,
                                O_tal_forecast_units,
                                O_tal_forecast_revenue,
                                O_tal_budget_turnover,
                                O_tal_actual_forecast_turnover,
                                O_tal_baseline_growth_budget,
                                O_tal_baseline_growth_act_for;

   ---
   if C_GET_DETAIL_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_DEAL_COMP',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE','C_GET_DETAIL_INFO','DEAL_DETAIL',to_char(I_deal_id));
      close C_GET_DETAIL_INFO;
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_DETAIL_INFO','DEAL_DETAIL',to_char(I_deal_id));
   close C_GET_DETAIL_INFO;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DEAL_ATTRIB_SQL.DEAL_DETAIL_INFO',
                                             to_char(SQLCODE));
      return FALSE;

END DEAL_DETAIL_INFO;
-------------------------------------------------------------------------------------------
FUNCTION GET_DEAL_ITEM_LOC_INFO(O_error_message      IN OUT VARCHAR2,
                                O_merch_level        IN OUT DEAL_ITEMLOC.MERCH_LEVEL%TYPE,
                                O_merch_value_1      IN OUT DEAL_ITEMLOC.ITEM%TYPE,
                                O_merch_value_2      IN OUT DEAL_ITEMLOC.ITEM%TYPE,
                                O_merch_value_3      IN OUT DEAL_ITEMLOC.ITEM%TYPE,
                                O_org_level          IN OUT DEAL_ITEMLOC.ORG_LEVEL%TYPE,
                                O_org_value          IN OUT DEAL_ITEMLOC.LOCATION%TYPE,
                                O_loc_type           IN OUT DEAL_ITEMLOC.LOC_TYPE%TYPE,
                                I_deal_id            IN     DEAL_ITEMLOC.DEAL_ID%TYPE,
                                I_deal_detail_id     IN     DEAL_ITEMLOC.DEAL_DETAIL_ID%TYPE,
                                I_seq_no             IN     DEAL_ITEMLOC.SEQ_NO%TYPE)
   RETURN BOOLEAN IS
   L_company_ind      DEAL_ITEMLOC.COMPANY_IND%TYPE;
   L_division         DEAL_ITEMLOC.DIVISION%TYPE;
   L_group_no         DEAL_ITEMLOC.GROUP_NO%TYPE;
   L_dept             DEAL_ITEMLOC.DEPT%TYPE;
   L_class            DEAL_ITEMLOC.CLASS%TYPE;
   L_subclass         DEAL_ITEMLOC.SUBCLASS%TYPE;
   L_item_parent      DEAL_ITEMLOC.ITEM_PARENT%TYPE;
   L_item_grandparent DEAL_ITEMLOC.ITEM_GRANDPARENT%TYPE;
   L_diff_1           DEAL_ITEMLOC.DIFF_1%TYPE;
   L_diff_2           DEAL_ITEMLOC.DIFF_2%TYPE;
   L_diff_3           DEAL_ITEMLOC.DIFF_3%TYPE;
   L_diff_4           DEAL_ITEMLOC.DIFF_4%TYPE;
   L_chain            DEAL_ITEMLOC.CHAIN%TYPE;
   L_area             DEAL_ITEMLOC.AREA%TYPE;
   L_region           DEAL_ITEMLOC.REGION%TYPE;
   L_district         DEAL_ITEMLOC.DISTRICT%TYPE;
   L_location         DEAL_ITEMLOC.LOCATION%TYPE;
   L_loc_type         DEAL_ITEMLOC.LOC_TYPE%TYPE;
   L_item             DEAL_ITEMLOC.ITEM%TYPE;
   cursor C_GET_DEAL_ITEM_LOC_INFO is
      select merch_level,
             company_ind,
             division,
             group_no,
             dept,
             class,
             subclass,
             item_parent,
             item_grandparent,
             diff_1,
             diff_2,
             diff_3,
             diff_4,
             org_level,
             chain,
             area,
             region,
             district,
             location,
             loc_type,
             item
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and seq_no = I_seq_no;
BEGIN
   open C_GET_DEAL_ITEM_LOC_INFO;
   fetch  C_GET_DEAL_ITEM_LOC_INFO into O_merch_level,
                                        L_company_ind,
                                        L_division,
                                        L_group_no,
                                        L_dept,
                                        L_class,
                                        L_subclass,
                                        L_item_parent,
                                        L_item_grandparent,
                                        L_diff_1,
                                        L_diff_2,
                                        L_diff_3,
                                        L_diff_4,
                                        O_org_level,
                                        L_chain,
                                        L_area,
                                        L_region,
                                        L_district,
                                        L_location,
                                        L_loc_type,
                                        L_item;
   close C_GET_DEAL_ITEM_LOC_INFO;
   ---
   if O_merch_level = 1 then
      O_merch_value_1 := NULL;
      O_merch_value_2 := NULL;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 2 then
      O_merch_value_1 := L_division;
      O_merch_value_2 := NULL;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 3 then
      O_merch_value_1 := L_group_no;
      O_merch_value_2 := NULL;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 4 then
      O_merch_value_1 := L_dept;
      O_merch_value_2 := NULL;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 5 then
      O_merch_value_1 := L_dept;
      O_merch_value_2 := L_class;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 6 then
      O_merch_value_1 := L_dept;
      O_merch_value_2 := L_class;
      O_merch_value_3 := L_subclass;
   elsif O_merch_level = 7 then
      O_merch_value_1 := nvl(L_item_parent, L_item_grandparent);
      O_merch_value_2 := NULL;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 8 then
      O_merch_value_1 := nvl(L_item_parent, L_item_grandparent);
      O_merch_value_2 := L_diff_1;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 9 then
      O_merch_value_1 := nvl(L_item_parent, L_item_grandparent);
      O_merch_value_2 := L_diff_2;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 10 then
      O_merch_value_1 := nvl(L_item_parent, L_item_grandparent);
      O_merch_value_2 := L_diff_3;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 11 then
      O_merch_value_1 := nvl(L_item_parent, L_item_grandparent);
      O_merch_value_2 := L_diff_4;
      O_merch_value_3 := NULL;
   elsif O_merch_level = 12 then
      O_merch_value_1 := L_item;
      O_merch_value_2 := NULL;
      O_merch_value_3 := NULL;
   end if;
   ---
   if O_org_level = 1 then
      O_org_value := L_chain;
      O_loc_type := NULL;
   elsif O_org_level = 2 then
      O_org_value := L_area;
      O_loc_type := NULL;
   elsif O_org_level = 3 then
      O_org_value := L_region;
      O_loc_type := NULL;
   elsif O_org_level = 4 then
      O_org_value := L_district;
      O_loc_type := NULL;
   elsif O_org_level = 5 then
      O_org_value := L_location;
      O_loc_type := L_loc_type;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DEAL_ATTRIB_SQL.GET_DEAL_ITEM_LOC_INFO',
                                             to_char(SQLCODE));
      return FALSE;
END GET_DEAL_ITEM_LOC_INFO;
--------------------------------------------------------------------------------------------
FUNCTION DEAL_QUEUE_EXISTS(O_error_message         IN OUT VARCHAR2,
                           O_exists                IN OUT BOOLEAN,
                           I_deal_id               IN     DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS
   L_dummy      VARCHAR2(1);
   cursor C_EXISTS is
      select 'x'
        from deal_queue
       where deal_id = I_deal_id;
BEGIN
   SQL_LIB.SET_MARK('OPEN','C_EXISTS',NULL,NULL);
   open C_EXISTS;
   ---
   SQL_LIB.SET_MARK('FECTH','C_EXISTS',NULL,NULL);
   fetch C_EXISTS into L_dummy;
   ---
   if C_EXISTS%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS',NULL,NULL);
   close C_EXISTS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_ATTRIB_SQL.DEAL_QUEUE_EXISTS',
                                             to_char(SQLCODE));
      return FALSE;
END DEAL_QUEUE_EXISTS;

--------------------------------------------------------------------------------------------
FUNCTION GET_DEAL_PROM_ID(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          O_deal_prom_id    IN OUT   DEAL_PROM.DEAL_PROM_ID%TYPE)
   RETURN BOOLEAN IS

   L_program        VARCHAR2(64) := 'DEAL_ATTRIB_SQL.GET_DEAL_PROM_ID';
   L_deal_prom_id   DEAL_PROM.DEAL_PROM_ID%TYPE;
   L_wrap_seq_no    DEAL_PROM.DEAL_PROM_ID%TYPE;
   L_first_time     VARCHAR2(1)  := 'Y';
   L_exists         VARCHAR2(1)  := 'N';

   cursor C_DEAL_PROM_ID_EXISTS is
      select 'Y'
        from deal_prom
       where deal_prom_id = L_deal_prom_id
         and rownum       = 1;

   cursor C_DEAL_PROM_SEQ is
      select deal_prom_seq.nextval
        from dual;

BEGIN
   LOOP
      SQL_LIB.SET_MARK('OPEN',
                       'C_DEAL_PROM_SEQ',
                       'DUAL',
                       NULL);
      open C_DEAL_PROM_SEQ;

      SQL_LIB.SET_MARK('FETCH',
                       'C_DEAL_PROM_SEQ',
                       'DUAL',
                       NULL);
      fetch C_DEAL_PROM_SEQ INTO L_deal_prom_id;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DEAL_PROM_SEQ',
                       'DUAL',
                       NULL);
      close C_DEAL_PROM_SEQ;

      ---
      if L_first_time = 'Y' then
         L_wrap_seq_no := L_deal_prom_id;
         L_first_time  := 'N';
      elsif L_deal_prom_id = L_wrap_seq_no then
         O_error_message := SQL_LIB.CREATE_MSG('NO_SEQ_NO_AVAIL',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_DEAL_PROM_ID_EXISTS',
                       'deal_prom',
                       'DEAL_PROM_ID: ' || TO_CHAR( O_deal_prom_id));
      open C_DEAL_PROM_ID_EXISTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_DEAL_PROM_ID_EXISTS',
                       'deal_prom',
                       'DEAL_PROM_ID: ' || TO_CHAR( O_deal_prom_id));
      fetch C_DEAL_PROM_ID_EXISTS INTO L_exists;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DEAL_PROM_ID_EXISTS',
                       'deal_prom',
                       'DEAL_PROM_ID: ' || TO_CHAR( O_deal_prom_id));
      close C_DEAL_PROM_ID_EXISTS;
      ---
      if L_exists = 'N' then
         O_deal_prom_id := L_deal_prom_id;
         return TRUE;
      else
         L_exists := 'N';
      end if;

   END LOOP;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END GET_DEAL_PROM_ID;
---------------------------------------------------------------------------------------------
-- 05-Mar-2008 Wipro/Shaestha   ModN53  Begin
-----------------------------------------------------------------------------------------------------------------
-- Mod By        : Wipro/Shaestha, shaestha.naz@in.tesco.com
-- Mod Date      : 05-Mar-2008
-- Mod Ref       : Mod number N53
-- Mod Details   : Crete new function
-- Function Name : TSL_GET_BILLING_TYPE
-- Purpose:      : This function will return the BILLING_TYPE attribute for the passed Deal ID and Deal Detail ID.
------------------------------------------------------------------------------------------------------------------

FUNCTION TSL_GET_BILLING_TYPE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              O_billing_type    IN OUT   DEAL_HEAD.BILLING_TYPE%TYPE,
                              I_deal_id         IN       DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS

    L_program        VARCHAR2(64) := 'DEAL_ATTRIB_SQL.TSL_GET_BILLING_TYPE';

    CURSOR C_GET_BILLING_TYPE is
    select dh.billing_type
      from deal_head dh
     where deal_id = I_deal_id;
BEGIN
      if I_deal_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('DEAL_ID_REQUIRED',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
   ---
      else
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_BILLING_TYPE',
                          'DEAL_HEAD',
                          TO_CHAR(I_deal_id));
         open C_GET_BILLING_TYPE;
   ---
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_BILLING_TYPE',
                          'DEAL_HEAD',
                          TO_CHAR(I_deal_id));
         fetch C_GET_BILLING_TYPE into O_billing_type;
   ---
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_BILLING_TYPE',
                          'DEAL_HEAD',
                          TO_CHAR(I_deal_id));
         close C_GET_BILLING_TYPE;
      end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      --To check whether the cursor is closed or not
      if C_GET_BILLING_TYPE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_BILLING_TYPE',
                          'DEAL_HEAD',
                          TO_CHAR(I_deal_id));
         close C_GET_BILLING_TYPE;
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END TSL_GET_BILLING_TYPE;
 -- 05-Mar-2008 Wipro/Shaestha   ModN53  End

---------------------------------------------------------------------------------------------
-- 09-May-2008 Nitin Kumar, nitin.kumar@in.tesco.com Mod N111 Begin
---------------------------------------------------------------------------------------------
-- Mod By      : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date    : 09-May-2008
-- Mod Ref     : ModN111
-- Mod Details : Added new function TSL_GET_COMMON_DEAL_IND.This function will return the
--               TSL_COMMON_DEAL attribute for the passed Deal ID
----------------------------------------------------------------------------------------------
FUNCTION TSL_GET_COMMON_DEAL_IND(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_common_deal     IN OUT   DEAL_HEAD.TSL_COMMON_DEAL%TYPE,
                                 I_deal_id         IN       DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN is

    --
    L_program       VARCHAR2(100) := 'DEAL_ATTRIB_SQL.TSL_GET_COMMON_DEAL_IND';
    --

    --This cursor will return the TSL_COMMON_DEAL for the passed Deal Id
    CURSOR C_GET_COMMON_DEAL is
    select dh.tsl_common_deal
      from deal_head dh
     where dh.deal_id    = I_deal_id;

BEGIN
   -- Check if input parameter is NULL
   if I_deal_id is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                                NULL,
                                                L_program,
                                                NULL);
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COMMON_DEAL',
                    'DEAL_HEAD',
                    'DEAL ID: ' ||TO_CHAR( I_deal_id));
   open C_GET_COMMON_DEAL;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COMMON_DEAL',
                    'DEAL_HEAD',
                    'DEAL ID: ' ||TO_CHAR( I_deal_id));
   fetch C_GET_COMMON_DEAL into O_common_deal;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COMMON_DEAL',
                    'DEAL_HEAD',
                    'DEAL ID: ' ||TO_CHAR( I_deal_id));
   close C_GET_COMMON_DEAL;

   return TRUE;

EXCEPTION
    when OTHERS then
       if C_GET_COMMON_DEAL%ISOPEN then
          SQL_LIB.SET_MARK('CLOSE',
                           'C_GET_COMMON_DEAL',
                           'DEAL_HEAD',
                           'DEAL ID: ' ||TO_CHAR( I_deal_id));
          close C_GET_COMMON_DEAL;
       end if;
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              TO_CHAR(SQLCODE));
          return FALSE;

END TSL_GET_COMMON_DEAL_IND;
-- 09-May-2008 Nitin Kumar, nitin.kumar@in.tesco.com Mod N111 End
----------------------------------------------------------------------------------------------
-- CR316 18-May-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com Begin
----------------------------------------------------------------------------------------------
FUNCTION TSL_DEAL_DEFAULTS(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_tsl_deal_dflt_row  IN OUT   tsl_deal_default%ROWTYPE)
   RETURN BOOLEAN is
   --
   L_program       VARCHAR2(100) := 'DEAL_ATTRIB_SQL.TSL_DEAL_DEFAULTS';
   --

    -- This cursor will return the TSL_COMMON_DEAL for the passed Deal Id
   CURSOR C_DEAL_DEFAULTS is
   select *
     from tsl_deal_default;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DEAL_DEFAULTS',
                    'tsl_deal_default',
                    NULL);
   open C_DEAL_DEFAULTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DEAL_DEFAULTS',
                    'tsl_deal_default',
                    NULL);
   fetch C_DEAL_DEFAULTS into O_tsl_deal_dflt_row;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DEAL_DEFAULTS',
                    'tsl_deal_default',
                    NULL);
   close C_DEAL_DEFAULTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_DEAL_DEFAULTS;
----------------------------------------------------------------------------------------------
-- CR316 18-May-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com End
----------------------------------------------------------------------------------------------
-- DefNBS023196, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com, 06-Jul-2011, Begin
----------------------------------------------------------------------------------------------
FUNCTION ACTIVE_OVERLAP_DEAL_EXISTS(O_error_message    IN OUT  VARCHAR2,
                                    O_exists           IN OUT  BOOLEAN,
                                    I_active_date      IN      DEAL_HEAD.ACTIVE_DATE%TYPE,
                                    I_close_date       IN      DEAL_HEAD.CLOSE_DATE%TYPE,
                                    I_billing_type     IN      DEAL_HEAD.BILLING_TYPE%TYPE,
                                    I_supplier         IN      DEAL_HEAD.SUPPLIER%TYPE,
                                    I_item             IN      DEAL_ITEMLOC.ITEM%TYPE,
                                    I_value            IN      DEAL_THRESHOLD.VALUE%TYPE)

   RETURN BOOLEAN is

   L_program         VARCHAR2(100) := 'DEAL_ATTRIB_SQL.ACTIVE_OVERLAP_DEAL_EXISTS';
   L_count_deal      PLS_INTEGER   := 0;

   CURSOR C_CHECK_ACTIVE_OVERLAP_DEAL is
   select COUNT(1)
     from deal_head       dh,
          deal_threshold  dt,
          deal_itemloc    dil
    where ((dh.active_date  = I_close_date and dh.active_date is NOT NULL)
          or (dh.close_date = I_active_date and dh.close_date is NOT NULL))
      and dt.value = NVL(I_value, 0)
      and dil.item = I_item
      and (dh.supplier = I_supplier and I_supplier is NOT NULL)
      and dh.billing_type = I_billing_type
      and dh.billing_type IN ('MBB', 'MOI')
      and dt.deal_detail_id = dil.deal_detail_id
      and dt.deal_id = dil.deal_id
      and dh.deal_id = dt.deal_id
-- DefNBS024488, Muthukumar S, muthukumar.sathiyaseelan@in.tesco.com, 29-MAR-2012, Begin
      and dh.status='A';
-- DefNBS024488, Muthukumar S, muthukumar.sathiyaseelan@in.tesco.com, 29-Mar-2012, End

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_CHECK_ACTIVE_OVERLAP_DEAL','DEAL_HEAD DEAL_THRESHOLD DEAL_ITEMLOC',I_item);
   open C_CHECK_ACTIVE_OVERLAP_DEAL;

   SQL_LIB.SET_MARK('FETCH','C_CHECK_ACTIVE_OVERLAP_DEAL','DEAL_HEAD DEAL_THRESHOLD DEAL_ITEMLOC',I_item);
   fetch C_CHECK_ACTIVE_OVERLAP_DEAL into L_count_deal;

   if L_count_deal = 0 then
      O_exists := TRUE;
   else
      O_error_message := SQL_LIB.CREATE_MSG('TSL_DATE_RANGE_DISCOUNT',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ACTIVE_OVERLAP_DEAL','DEAL_HEAD DEAL_THRESHOLD DEAL_ITEMLOC',I_item);
      close C_CHECK_ACTIVE_OVERLAP_DEAL;
      O_exists := FALSE;
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ACTIVE_OVERLAP_DEAL','DEAL_HEAD DEAL_THRESHOLD DEAL_ITEMLOC',I_item);
   close C_CHECK_ACTIVE_OVERLAP_DEAL;

   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_ATTRIB_SQL.ACTIVE_OVERLAP_DEAL_EXISTS',
                                            TO_CHAR(SQLCODE));
      RETURN FALSE;
END ACTIVE_OVERLAP_DEAL_EXISTS;
----------------------------------------------------------------------------------------------
-- DefNBS023196, Accenture/Deepak Kumar, Deepak.Kumar@in.tesco.com,  06-Jul-2011, End
----------------------------------------------------------------------------------------------
END DEAL_ATTRIB_SQL;
/

