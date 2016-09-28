CREATE OR REPLACE PACKAGE BODY COST_EXTRACT_SQL AS
------------------------------------------------------------------------------------------
-- Mod By:      Wipro Enabler / Shekar Radhakrishnan, shekar.radhakrishnan@in.tesco.com
-- Mod Date:    07-Mar-2008
-- Mod Ref:     Mod n53
-- Mod Details: Added new function TSL_UPDATE_RATIO_PACK, This function will check to see
--              if the item or a transaction level child of the passed in item is on a
--              Ratio Pack with Cost Link Active. Then it will call PACKITEM_ADD_SQL to
--              update all costs for the Ratio Pack.
--              Added new function TSL_INSERT_RP_COST_CCQ, This function inserts on the
--              RECLASS_COST_CHG_QUEUE all the non-MU Ratio Packs that will suffer
--              only a Cost Change when a Cost Change is made to one of its Component Items.
--              Modified function PROCESS_COST_CHANGE_RECS, This function is called by
--              PROCESS_DETAIL_LOC and PROCESS_DETAILS functions to process program collections.
------------------------------------------------------------------------------------------
--Defect Id :- NBS00006286
--Fixed By  :- Nitin Kumar, nitin.kumar@in.tesco.com
--Date      :- 17-Apr-2008
--Details   :- Modified the cursor C_GET_COMP_CC in the function TSL_INSERT_RP_COST_CCQ
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--Defect Id : NBS00008323
--Fixed By  : Usha Patil, usha.patil@in.tesco.com
--Date      : 19-Aug-2008
--Details   : Modified the cursor C_GET_RP_COST in the function TSL_INSERT_RP_COST_CCQ
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--Defect Id : NBS00008323/DefNBS008595
--Fixed By  : Usha Patil, usha.patil@in.tesco.com
--Date      : 28-Aug-2008
--Details   : Modified the cursor C_GET_RP_COST in the function TSL_INSERT_RP_COST_CCQ
------------------------------------------------------------------------------------------
--Defect Id : NBS00008317
--Fixed By  : Nitin Kumar, nitin.kumar@in.tesco.com
--Date      : 01-Sep-2008
--Details   : Modified the cursor C_GET_RP_COST in the function TSL_INSERT_RP_COST_CCQ
--          : Modified the function TSL_UPDATE_RATIO_PACK
------------------------------------------------------------------------------------------
--Mod By:      Murali Krishnan
--Mod Date:    23-Oct-2008
--Mod Ref:     Back Port Oracle fix(6717469,6776806)
--Mod Details: Back ported the oracle fix for Bug 6717469,6776806.Modified the functions
--               PROCESS_COST_CHANGE_RECS,PROCESS_DETAILS.
-----------------------------------------------------------------------------------------------------
--Mod By:      Raghuveer P R
--Mod Date:    20-Jan-2009
--Mod Ref:     MrgNBS010972
--Mod Details: Merge from 3.3a to 3.3b
-----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--Mod By:      Srinivasa Janga
--Mod Date:    20-Aug-2009
--Mod Ref:     NBS00014543
--Mod Details: Commetned the necessery loops for ISCL in fuction INSERT_COST_RECLASS_CCQ
--------------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 17-Mar-2010
-- Mod Ref    : PrfNBS00016594
-- Mod Details: Modified the cursor in WORKSHEET and SUBMIT functions to improve the perfomance
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Mod By     : Manikandan V, Manikandan.Varadhan@in.tesco.com
-- Mod Date   : 28-Apr-2010
-- Mod Ref    : PrfNBS00016594
-- Mod Details: Modified the function INSERT_COST_RECLASS_CCQ,TSL_INSERT_RP_COST_CCQ to improve the performance
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Mod By     : Gary Sandler
-- Mod Date   : 25-May-2010
-- Mod Ref    : PrfNBS0017474
-- Mod Details: Modified UPDATE_BASE_COST.CHANGE_COST calls and removed ELC_CALLS call to improve performance.
--------------------------------------------------------------------------------------------------------
/*-----------------------------------------------------------------------------------
Mod By     : Murali Krishnan N
Mod Date   : 18-Nov-2010
Mod Ref    : NBS00019794
Mod Details: Modified fuction TSL_INSERT_RP_COST_CCQ to correct the jin condition in the update statement.
--------------------------------------------------------------------------------------*/
-----------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 04-Oct-2011
-- Mod Ref    : PrfNBS023365
-- Mod Details: Modified UPDATE_BUYER_PACK to improve performance.
-- Moved the function call TSL_RATIO_PACK_SQL.TSL_UPDATE_SUPP_COST from TSL_UPDATE_RATIO_PACK
-- to SCCEXT post batch. And inserted the Ratio packs into temp table.
--------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 20-Oct-2011
-- Mod Ref    : PrfNBS021857
-- Mod Details: Modified TSL_INSERT_RP_COST_CCQ to improve performance. Processed only changed
-- newly added cost changes from reclass_cost_chg_queue table.
--------------------------------------------------------------------------------------

   LP_prim_curr                  SYSTEM_OPTIONS.CURRENCY_CODE%TYPE := NULL;
   LP_std_av_ind                 SYSTEM_OPTIONS.STD_AV_IND%TYPE    := NULL;
   LP_elc_ind                    SYSTEM_OPTIONS.ELC_IND%TYPE       := NULL;

   TYPE TYP_ROWID                is TABLE of ROWID                                         INDEX BY BINARY_INTEGER;
   TYPE TYP_BRACKET_VALUE        is TABLE of COST_SUSP_SUP_DETAIL.BRACKET_VALUE1%TYPE      INDEX BY BINARY_INTEGER;
   TYPE TYP_DEFAULT_BRACKET_IND  is TABLE of COST_SUSP_SUP_DETAIL.DEFAULT_BRACKET_IND%TYPE INDEX BY BINARY_INTEGER;
   TYPE TYP_SUP_DEPT_SEQ_NO      is TABLE of COST_SUSP_SUP_DETAIL.SUP_DEPT_SEQ_NO%TYPE     INDEX BY BINARY_INTEGER;
   TYPE TYP_DEPT                 is TABLE of ITEM_MASTER.DEPT%TYPE                         INDEX BY BINARY_INTEGER;
   TYPE TYP_CLASS                is TABLE of ITEM_MASTER.CLASS%TYPE                        INDEX BY BINARY_INTEGER;
   TYPE TYP_SUBCLASS             is TABLE of ITEM_MASTER.SUBCLASS%TYPE                     INDEX BY BINARY_INTEGER;
   TYPE TYP_SUPPLIER             is TABLE of ITEM_SUPP_COUNTRY.SUPPLIER%TYPE               INDEX BY BINARY_INTEGER;
   TYPE TYP_ORIGIN_COUNTRY_ID    is TABLE of ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE      INDEX BY BINARY_INTEGER;
   TYPE TYP_UNIT_RETAIL          is TABLE of ITEM_LOC.UNIT_RETAIL%TYPE                     INDEX BY BINARY_INTEGER;
   TYPE TYP_LOC_TYPE             is TABLE of ITEM_LOC.LOC_TYPE%TYPE                        INDEX BY BINARY_INTEGER;
   TYPE TYP_LOC                  is TABLE of ITEM_LOC_SOH.LOC%TYPE                         INDEX BY BINARY_INTEGER;
   TYPE TYP_STOCK_ON_HAND        is TABLE of ITEM_LOC_SOH.STOCK_ON_HAND%TYPE               INDEX BY BINARY_INTEGER;


------------------------------------------------
---PRIVATE FUNCTIONS:
------------------------------------------------
---FUNCTION NAME:CALCULATE_LOC_UNIT_COST
---Purpose: It calculates the unit cost of the children item for the cost change (SKU/Supplier/Locaton)applied
---over parent item if they are at or above tran level
-------------------------------------------------
FUNCTION CALCULATE_LOC_UNIT_COST (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_unit_cost_new    IN OUT   TYP_UNIT_COST,
                                  L_item_tbl         IN OUT   TYP_ITEM,
                                  I_supplier         IN       SUPS.SUPPLIER%TYPE,
                                  I_origin_country   IN       COUNTRY.COUNTRY_ID%TYPE,
                                  I_bracket_value1   IN       COST_SUSP_SUP_DETAIL.BRACKET_VALUE1%TYPE,
                                  I_item             IN       ITEM_MASTER.ITEM%TYPE,
                                  I_loc              IN       COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE,
                                  I_change_type      IN       COST_SUSP_SUP_DETAIL.COST_CHANGE_TYPE%TYPE,
                                  I_change_amount    IN       COST_SUSP_SUP_DETAIL.COST_CHANGE_VALUE%TYPE)
  RETURN BOOLEAN;
--------------------------------------------------------
---FUNCTION NAME:CALCULATE_UNIT_COST
---Purpose: It calculates the unit cost of the children item for the cost change (SKU/Supplier)applied
---over parent item if they are at or above tran level
-------------------------------------------------
FUNCTION CALCULATE_UNIT_COST (O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              O_unit_cost_new     IN OUT   TYP_UNIT_COST,
                              L_item_tbl          IN OUT   TYP_ITEM,
                              I_supplier          IN       SUPS.SUPPLIER%TYPE,
                              I_origin_country    IN       COUNTRY.COUNTRY_ID%TYPE,
                              I_bracket_value1    IN       COST_SUSP_SUP_DETAIL.BRACKET_VALUE1%TYPE,
                              I_item              IN       ITEM_MASTER.ITEM%TYPE,
                              I_change_type       IN       COST_SUSP_SUP_DETAIL.COST_CHANGE_TYPE%TYPE,
                              I_change_amount     IN       COST_SUSP_SUP_DETAIL.COST_CHANGE_VALUE%TYPE)
   RETURN BOOLEAN ;
--------------------------------------------------------------------------------------------------
---FUNCTION NAME: PROCESS_DETAIL_LOC
---Purpose: Called by BULK_UPDATE_COSTS function process cost change detail locs.
--------------------------------------------------------------------------------------------------
FUNCTION PROCESS_DETAIL_LOC(O_error_message   IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                            I_cost_change     IN        COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                            I_cost_reason     IN        COST_SUSP_SUP_HEAD.REASON%TYPE)
   return BOOLEAN;
--------------------------------------------------------------------------------------------------
---FUNCTION NAME: PROCESS_DETAILS
---Purpose: Called by BULK_UPDATE_COSTS function process cost change details.
--------------------------------------------------------------------------------------------------
FUNCTION PROCESS_DETAILS(O_error_message   IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                         I_cost_change     IN        COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                         I_cost_reason     IN        COST_SUSP_SUP_HEAD.REASON%TYPE)
   return BOOLEAN;
-------------------------------------------------------------------------------------------------
---FUNCTION NAME: PROCESS_COST_CHANGE_RECS
---Purpose: Called by PROCESS_DETAIL_LOC and  PROCESS_DETAILS functions to process program
---         collections.
--------------------------------------------------------------------------------------------------
FUNCTION PROCESS_COST_CHANGE_RECS(O_error_message              IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_upd_isc_rowid              IN      TYP_ROWID,
                                  I_upd_isc_unit_cost          IN      TYP_UNIT_COST,
                                  I_upd_iscl_rowid             IN      TYP_ROWID,
                                  I_upd_iscl_unit_cost         IN      TYP_UNIT_COST,
                                  I_ins_ph_item                IN      TYP_ITEM,
                                  I_ins_ph_loc                 IN      TYP_LOC,
                                  I_ins_ph_loc_type            IN      TYP_LOC_TYPE,
                                  I_ins_ph_unit_cost           IN      TYP_UNIT_COST,
                                  I_ins_ph_unit_retail         IN      TYP_UNIT_RETAIL,
                                  I_upd_ils_rowid              IN      TYP_ROWID,
                                  I_upd_ils_unit_cost          IN      TYP_UNIT_COST,
                                  I_stk_item                   IN      TYP_ITEM,
                                  I_stk_dept                   IN      TYP_DEPT,
                                  I_stk_class                  IN      TYP_CLASS,
                                  I_stk_subclass               IN      TYP_SUBCLASS,
                                  I_stk_loc                    IN      TYP_LOC,
                                  I_stk_loc_type               IN      TYP_LOC_TYPE,
                                  I_stk_soh                    IN      TYP_STOCK_ON_HAND,
                                  I_stk_total_cost             IN      TYP_UNIT_COST,
                                  I_stk_old_cost               IN      TYP_UNIT_COST,
                                  I_stk_local_cost             IN      TYP_UNIT_COST,
                                  I_isc_prim_rowid             IN      TYP_ROWID,
                                  I_isc_prim_unit_cost         IN      TYP_UNIT_COST,
                                  I_elc_item                   IN      TYP_ITEM,
                                  I_elc_supplier               IN      TYP_SUPPLIER,
                                  I_elc_origin_country_id      IN      TYP_ORIGIN_COUNTRY_ID,
                                  I_wksht_bracket1             IN      TYP_BRACKET_VALUE,
                                  I_wksht_supplier             IN      TYP_SUPPLIER,
                                  I_wksht_seq_no               IN      TYP_SUP_DEPT_SEQ_NO,
                                  I_iscbc_reset_rowid          IN      TYP_ROWID,
                                  I_upd_iscbc_rowid            IN      TYP_ROWID,
                                  I_upd_iscbc_unit_cost        IN      TYP_UNIT_COST,
                                  I_upd_iscbc_default_bracket  IN      TYP_DEFAULT_BRACKET_IND,
                                  I_upd_loc_brckt_item         IN      TYP_ITEM,
                                  I_upd_loc_brckt_supplier     IN      TYP_SUPPLIER,
                                  I_upd_loc_brckt_cntry        IN      TYP_ORIGIN_COUNTRY_ID,
                                  I_update_child               IN      VARCHAR2,
                                  I_upd_recalc_ind             IN      VARCHAR2,
                                  I_cost_change                IN      COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                                  I_buypk_item                 IN      TYP_ITEM,
                                  I_upd_ord_item               IN      ITEM_TBL,
                                  -- 23-Oct-2008 TESCO HSC/Murali 6717469 Begin
                                  I_cost_reason                IN      COST_SUSP_SUP_HEAD.REASON%TYPE)
                                  -- 23-Oct-2008 TESCO HSC/Murali 6717469 End
RETURN BOOLEAN;
-------------------------------------------------------------------------------------------------
---FUNCTION NAME: BULK_UPDATE_APPROVED_ORDERS
---Purpose: Called by PROCESS_COST_CHANGE_RECS function to process item costs in approved
---         orders
--------------------------------------------------------------------------------------------------
FUNCTION BULK_UPDATE_APPROVED_ORDERS(O_error_message IN OUT VARCHAR2,
                                     I_items         IN     ITEM_TBL)
RETURN BOOLEAN;
-------------------------------------------------------------------------------------------------
FUNCTION UPDATE_COSTS(O_error_message   IN OUT    VARCHAR2,
                      I_cost_change     IN        COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                      I_cost_reason     IN        COST_SUSP_SUP_HEAD.REASON%TYPE) return BOOLEAN IS
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.UPDATE_COSTS';
L_table               VARCHAR2(64) := 'COST_EXTRACT_SQL';
L_loc                 COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE;
L_location            COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE;
L_prev_loc            COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE;       --- Variable will contain previous location
L_item                COST_SUSP_SUP_DETAIL.ITEM%TYPE;
L_supplier            COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE;
L_country             COST_SUSP_SUP_DETAIL.ORIGIN_COUNTRY_ID%TYPE;
L_bracket1            COST_SUSP_SUP_DETAIL.BRACKET_VALUE1%TYPE;
L_bracket2            COST_SUSP_SUP_DETAIL.BRACKET_VALUE2%TYPE;
L_seq_no              COST_SUSP_SUP_DETAIL.SUP_DEPT_SEQ_NO%TYPE;
L_unit_cost           COST_SUSP_SUP_DETAIL.UNIT_COST%TYPE;
L_change_type         COST_SUSP_SUP_DETAIL.COST_CHANGE_TYPE%TYPE;
L_change_amount       COST_SUSP_SUP_DETAIL.COST_CHANGE_VALUE%TYPE;
L_recalc_ord_ind      COST_SUSP_SUP_DETAIL.RECALC_ORD_IND%TYPE;
L_prev_flag           COST_SUSP_SUP_DETAIL.RECALC_ORD_IND%TYPE;
L_item_level          ITEM_MASTER.ITEM_LEVEL%TYPE;
L_tran_level          ITEM_MASTER.TRAN_LEVEL%TYPE;
L_prev_item_level     ITEM_MASTER.ITEM_LEVEL%TYPE;
L_prev_tran_level     ITEM_MASTER.TRAN_LEVEL%TYPE;
L_dept                DEPS.DEPT%TYPE;
L_update_child        VARCHAR2(1) := 'N';
L_default_bracket     COST_SUSP_SUP_DETAIL.DEFAULT_BRACKET_IND%TYPE;
L_prev_item           ITEM_MASTER.ITEM%TYPE;
L_multiple            NUMBER;
L_loc_multiple        NUMBER;
L_bracket_level       SUPS.INV_MGMT_LVL%TYPE;
L_cost_found          VARCHAR2(1);
L_unit_cost_tbl       TYP_UNIT_COST;
L_item_tbl            TYP_ITEM;
RECORD_LOCKED         EXCEPTION;
PRAGMA                EXCEPTION_INIT(Record_Locked, -54);
----
cursor C_SUPP_LOC is
   select loc
     from item_supp_country_loc
    where item              = L_item
      and supplier          = L_supplier
      and origin_country_id = L_country;
----
cursor C_SELECT_DETAIL is
   select csd.item,
          csd.supplier,
          csd.origin_country_id,
          NULL,
          csd.bracket_value1,
          csd.bracket_value2,
          csd.unit_cost,
          csd.cost_change_type,
          csd.cost_change_value,
          csd.recalc_ord_ind,
          csd.default_bracket_ind,
          csd.dept,
          csd.sup_dept_seq_no,
          im.tran_level,
          im.item_level
     from item_master im,
          cost_susp_sup_detail csd
    where csd.item         = im.item
      and csd.cost_change  = I_cost_change
      and (im.orderable_ind = 'Y'
           or im.item_xform_ind = 'N')
    order by csd.supplier,
             im.item_level,
             csd.item;
----
cursor C_SELECT_DETAIL_LOC is
   select csdl.item,
          csdl.supplier,
          csdl.origin_country_id,
          csdl.loc,
          csdl.bracket_value1,
          csdl.bracket_value2,
          csdl.unit_cost,
          csdl.cost_change_type,
          csdl.cost_change_value,
          csdl.recalc_ord_ind,
          csdl.default_bracket_ind,
          csdl.dept,
          csdl.sup_dept_seq_no,
          im.tran_level,
          im.item_level
     from item_master im,
          cost_susp_sup_detail_loc csdl
    where csdl.item        = im.item
      and csdl.cost_change = I_cost_change
      and (im.orderable_ind = 'Y'
           or im.item_xform_ind = 'N')
    order by csdl.supplier,
             im.item_level,
             csdl.item;


cursor C_LOCK_ITEM_SUPP_COUNTRY is
   select 'x'
     from item_supp_country
    where origin_country_id = L_country
      and supplier          = L_supplier
      and item              = L_item
      for update nowait;
---
cursor C_LOCK_ISCBC_LOC is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     != L_bracket1
      and location            = L_loc
      and origin_country_id   = L_country
      and supplier            = L_supplier
      and item                = L_item;
---
cursor C_LOCK_ISCBC_LOC_CHILD is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     != L_bracket1
      and location            = L_loc
      and origin_country_id   = L_country
      and supplier            = L_supplier
      and item in (select im.item
                     from item_master im,
                          item_supp_country_bracket_cost iscbc
                    where iscbc.supplier          = L_supplier
                      and iscbc.origin_country_id = L_country
                      and iscbc.location          = L_loc
                      and (im.item_parent         = L_item or
                           im.item_grandparent    = L_item)
                      and im.item_level          <= im.tran_level
                      and iscbc.item              = im.item);
---
cursor C_LOCK_ISCBC is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     != L_bracket1
      and origin_country_id   = L_country
      and supplier            = L_supplier
      and item                = L_item;
---
cursor C_LOCK_ISCBC_CHILD is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     != L_bracket1
      and origin_country_id   = L_country
      and supplier            = L_supplier
      and item in (select im.item
                     from item_master im,
                          item_supp_country_bracket_cost iscbc
                    where iscbc.supplier          = L_supplier
                      and iscbc.origin_country_id = L_country
                      and (im.item_parent         = L_item or
                           im.item_grandparent    = L_item)
                      and im.item_level          <= im.tran_level
                      and iscbc.item              = im.item);
---
cursor C_LOCK_SUPP_CNTRY_BRKT_COST is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1    = L_bracket1
      and (location         = L_loc
       or location          is NULL)
      and origin_country_id = L_country
      and supplier          = L_supplier
      and item              = L_item
      for update nowait;
---
cursor C_LOCK_SUPP_COUNTRY_LOC is
   select 'x'
     from item_supp_country_loc
    where loc               = L_loc
      and origin_country_id = L_country
      and supplier          = L_supplier
      and item              = L_item
      for update nowait;
---
cursor C_LOCK_CNTRY_LOC_CHILDREN is
   select 'x'
     from item_supp_country_loc
    where loc               = L_loc
      and origin_country_id = L_country
      and supplier          = L_supplier
      and item in (select im.item
                     from item_master im,
                          item_supp_country_bracket_cost iscbc
                    where iscbc.supplier           = L_supplier
                      and iscbc.origin_country_id  = L_country
                      and (im.item_parent          = L_item or
                           im.item_grandparent     = L_item)
                      and im.item_level           <= im.tran_level
                      and iscbc.item               = im.item)
      for update nowait;
---
cursor C_LOCK_BRACKET_CHILD is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     = L_bracket1
      and location           is NULL
      and origin_country_id  = L_country
      and supplier           = L_supplier
      and item in (select im.item
                     from item_master im,
                          item_supp_country_bracket_cost iscbc
                    where iscbc.supplier          = L_supplier
                      and iscbc.origin_country_id = L_country
                      and (im.item_parent         = L_item or
                          im.item_grandparent     = L_item)
                      and im.item_level          <= im.tran_level
                      and iscbc.item              = im.item)
      for update nowait;
---
cursor C_LOCK_BRACKET_CHILD_LOC is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     = L_bracket1
      and location           = L_loc
      and origin_country_id  = L_country
      and supplier           = L_supplier
      and item in (select im.item
                     from item_master im,
                          item_supp_country_bracket_cost iscbc
                    where iscbc.supplier          = L_supplier
                      and iscbc.origin_country_id = L_country
                      and iscbc.location          = L_loc
                      and (im.item_parent         = L_item or
                          im.item_grandparent     = L_item)
                      and im.item_level          <= im.tran_level
                      and iscbc.item              = im.item)
      for update nowait;
---
cursor C_LOCK_ITEM_SUPP_COUNTRY_CHILD is
   select 'x'
     from item_supp_country
    where origin_country_id = L_country
      and supplier          = L_supplier
      and item in (select im.item
                     from item_master im
                    where (im.item_parent       = L_item or
                           im.item_grandparent  = L_item)
                      and im.item_level        <= im.tran_level)
      for update nowait;
---
BEGIN
   ------------------------------------------------------------------------
   --- FUNCTION OVERVIEW:
   --- This function will drive all cost changes within RMS.
   --- This function will first determine if the cost change comes from
   --- COST_SUSP_SUP_DETAIL or COST_SUSP_SUP_DETAIL_LOC.
   --- IF THE COST CHANGE IS FROM COST_SUSP_SUP_DETAIL_LOC (locations present):
   --- 1.  Check to see if the cost change is a reason of 1 (new bracket
   ---     structure) or reason 2 (new bracket).  If it is, call
   ---     INSERT_BRACKET_LOC to insert brackets at the location level.
   --- 2.  If it is any other reason:
   ---
   ---     A.  (if brackets).  If it is...
   ---         - process brackets and locations on
   ---           ITEM_SUPP_COUNTRY_BRACKET_COSTS.  If the
   ---           item is above the transaction level, update the child
   ---           brackets on ITEM_SUPP_COUNTRY_BRACKET_COSTS.
   ---         - If the bracket is the default bracket, call ITEM_BRACKET_COST_SQL
   ---           to update the location costs for the default bracket and the
   ---           unit cost on ITEM_SUPP_COUNTRY with the cost at the primary
   ---           location.  Next, if the item is at the transaction level then call
   ---           UPDATE_BUYER_PACK to rebuild any pack costs.
   ---           Then update the pack costs on ITEM_SUPP_COUNTRY_LOC
   ---           and ITEM_SUPP_COUNTRY.  If the pack is on an approved order, update
   ---           the costs for the order.  If the item is above transaction level,
   ---           check to see if the item's children are in any packs.  Update costs
   ---           and orders the same as described above.
   ---     B.  if no brackets
   ---         - update costs on ITEM_SUPP_COUNTRY_LOC for the item and any children
   ---           at the locations.
   ---         - Call update_base_cost to update the unit cost on ITEM_SUPP_COUNTRY
   ---           where the location is the primary location.
   ---         - Next, if the item is at the transaction level then call
   ---           UPDATE_BUYER_PACK to rebuild any pack costs.
   ---           Then update the pack costs on ITEM_SUPP_COUNTRY_LOC
   ---           and ITEM_SUPP_COUNTRY.  If the pack is on an approved order, update
   ---           the costs for the order.  If the item is above transaction level,
   ---           check to see if the item's children are in any packs.  Update costs
   ---           and orders the same as described above.
   ---     C.  Check to see if the item on the cost chnage has changed, if it has
   ---         check to see if the item is to have an order recalculated.  If it is
   ---         at the transaction level, update the order with the new cost of the item.
   ---         If the item is above the transaction level, check to see if its children
   ---         are on any approved orders.  If they are,update the order with the new cost
   ---         of the children.
   --- IF THE COST CHANGE IS FROM COST_SUSP_SUP_DETAIL (no locations present):
   --- 1.  Check to see if the cost change is a reason of 1 (new bracket
   ---     structure) or reason 2 (new bracket).  If it is, call
   ---     INSERT_BRACKET to insert brackets at the location level.
   --- 2.  If it is any other reason:
   ---     A.  (if brackets).  If it is...
   ---         - process brackets no locations locations on
   ---           ITEM_SUPP_COUNTRY_BRACKET_COSTS.  If the
   ---           item is above the transaction level, update the child
   ---           brackets on ITEM_SUPP_COUNTRY_BRACKET_COSTS.
   ---         - If the bracket is the default bracket, call ITEM_BRACKET_COST_SQL
   ---           to update the costs for the default bracket and the
   ---           unit cost on ITEM_SUPP_COUNTRY. Update all location costs with this cost.
   ---           Next, if the item is at the transaction level then call
   ---           UPDATE_BUYER_PACK to rebuild any pack costs.
   ---           Then update the pack costs on ITEM_SUPP_COUNTRY_LOC
   ---           and ITEM_SUPP_COUNTRY.  If the pack is on an approved order, update
   ---           the costs for the order.  If the item is above transaction level,
   ---           check to see if the item's children are in any packs.  Update costs
   ---           and orders the same as described above.
   ---     B.  if no brackets
   ---         - update costs on ITEM_SUPP_COUNTRY for the item and any children.
   ---         - Call update_base_cost to update the unit cost on ITEM_SUPP_COUNTRY_LOC.
   ---         - Next, if the item is at the transaction level then call
   ---           UPDATE_BUYER_PACK to rebuild any pack costs.
   ---           Then update the pack costs on ITEM_SUPP_COUNTRY_LOC
   ---           and ITEM_SUPP_COUNTRY.  If the pack is on an approved order, update
   ---           the costs for the order.  If the item is above transaction level,
   ---           check to see if the item's children are in any packs.  Update costs
   ---           and orders the same as described above.
   ---     C.  Check to see if the item on the cost chnage has changed, if it has
   ---         check to see if the item is to have an order recalculated.  If it is
   ---         at the transaction level, update the order with the new cost of the item.
   ---         If the item is above the transaction level, check to see if its children
   ---         are on any approved orders.  If they are,update the order with the new cost
   ---         of the children.
   --- NULL value validation
   if I_cost_change is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_cost_change',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   --- COST_SUSP_SUP_DETAIL_LOC TABLE PROCESSING
   --- If the supplier is location costed, loop through all records on
   --- COST_SUSP_SUP_DETAIL_LOC....
   -------------------------------------------------------------------
   --- If the cost change reason is 1, insert new brackets
   --- If the cost change reason is 2, insert new bracket structures
   --- These inserts will be made from the COST_SUSP_SUP_DETAIL_LOC table.
   --- These cost changes will always be for brackets and therefore, we
   --- will not need to check against the COST_SUSP_SUP_DETAIL_LOC for brackets.
   --- Next, Loop through records are on COST_SUSP_SUP_DETAIL for brackets
   --------------------------------------------------------------------
   if I_cost_reason = 1 or I_cost_reason = 2 then
      if not COST_EXTRACT_SQL.INSERT_BRACKET_LOC(O_error_message,
                                                 I_cost_change,
                                                 I_cost_reason,
                                                 L_cost_found) then
         return FALSE;
      end if;
      if not COST_EXTRACT_SQL.INSERT_BRACKET(O_error_message,
                                             I_cost_change,
                                             I_cost_reason,
                                             L_cost_found) then
         return FALSE;
      end if;
   ---------------------------------------------------------------
   --- Else for cost changes of reason 3 or any other reason.....
   ----------------------------------------------------------------
   else
      --- COST_SUSP_SUP_DETAIL_LOC TABLE PROCESSING
      --- If the supplier is location costed, loop through all records on
      --- COST_SUSP_SUP_DETAIL_LOC....
      --- Set the multiple to 1 for processing
      L_loc_multiple := 1;
      SQL_LIB.SET_MARK('FETCH','C_SELECT_DETAIL_LOC','COST_SUSP_SUP_DETAIL_LOC',NULL);
      FOR rec in C_SELECT_DETAIL_LOC
      LOOP
         L_item           := rec.item;
         L_supplier       := rec.supplier;
         L_country        := rec.origin_country_id;
         L_loc            := rec.loc;
         L_bracket1       := rec.bracket_value1;
         L_bracket2       := rec.bracket_value2;
         L_unit_cost      := rec.unit_cost;
         L_change_type    := rec.cost_change_type;
         L_change_amount  := rec.cost_change_value;
         L_recalc_ord_ind := rec.recalc_ord_ind;
         L_default_bracket:= rec.default_bracket_ind;
         L_dept           := rec.dept;
         L_seq_no         := rec.sup_dept_seq_no;
         L_tran_level     := rec.tran_level;
         L_item_level     := rec.item_level;

         --- set the previous item equal to the current item for the first record
         --- of processing.  This will be used to ensure that PO logic will not be
         --- executed in the first iteration
         if L_loc_multiple = 1 then
            L_prev_item := L_item;
         end if;
         --- Check to see if the item_level is less than the transaction level.
         --- If it is, set the update child indicator to 'Y'.
         --- If it is not, set it equal to 'N'.
         if L_item_level < L_tran_level then
            L_update_child := 'Y';
            ---get the unit cost of the children if they are at transaction level
           If  not CALCULATE_LOC_UNIT_COST(O_error_message,
                                           L_unit_cost_tbl,
                                           L_item_tbl,
                                           L_supplier,
                                           L_country,
                                           L_bracket1,
                                           L_item,
                                           L_loc,
                                           L_change_type,
                                           L_change_amount) then
                    return FALSE;
           end if;
         else
            L_update_child := 'N';
         end if;
         --- Update the location brackets on ITEM_SUPP_COUNTRY_BRACKET_COST
         --- If the record has a bracket value (costed by location and bracket).
         if L_bracket1 is not null then
            --- If the cost change reason is 3 (change default bracket), reset
            --- The all brackets to 'N' for any given bracket not on the
            --- Cost change.
            if I_cost_reason = 3 then
               --- Update default bracket for any worksheet items for the supplier.
               if not COST_EXTRACT_SQL.CHANGE_WORKSHEET_DEFAULT(O_error_message,
                                                                L_bracket1,
                                                                L_supplier,
                                                                L_seq_no) then
                  return FALSE;
               end if;
               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               open C_LOCK_ISCBC_LOC;
               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               close C_LOCK_ISCBC_LOC;
               SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               update item_supp_country_bracket_cost
                  set default_bracket_ind = 'N'
                where bracket_value1     != L_bracket1
                  and location            = L_loc
                  and origin_country_id   = L_country
                  and supplier            = L_supplier
                  and item                = L_item;
            end if;  --- End if I_cost_reason = 3
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            open C_LOCK_SUPP_CNTRY_BRKT_COST;
            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            close C_LOCK_SUPP_CNTRY_BRKT_COST;
            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            update item_supp_country_bracket_cost
               set unit_cost           = L_unit_cost,
                   default_bracket_ind = L_default_bracket
             where bracket_value1      = L_bracket1
               and location            = L_loc
               and origin_country_id   = L_country
               and supplier            = L_supplier
               and item                = L_item;
            --- update child item brackets
            --- on ITEM_SUPP_COUNTRY_BRACKET_COST
            --- If the update child indicator is passed in as 'Y'
            if L_update_child = 'Y' then
               --- If the cost change reason is 3 (change default bracket), reset
               --- The all brackets to 'N' for any given bracket not on the
               --- Cost change.
               if I_cost_reason = 3 then
                  SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC_LOC_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  open C_LOCK_ISCBC_LOC_CHILD;
                  SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC_LOC_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  close C_LOCK_ISCBC_LOC_CHILD;
                  SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC_LOC_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  update item_supp_country_bracket_cost
                     set default_bracket_ind = 'N'
                   where bracket_value1     != L_bracket1
                     and location            = L_loc
                     and origin_country_id   = L_country
                     and supplier            = L_supplier
                     and item in (select im.item
                                    from item_master im,
                                         item_supp_country_bracket_cost iscbc
                                   where iscbc.supplier          = L_supplier
                                     and iscbc.origin_country_id = L_country
                                     and iscbc.location          = L_loc
                                     and (im.item_parent         = L_item or
                                          im.item_grandparent    = L_item)
                                     and im.item_level          <= im.tran_level
                                     and iscbc.item              = im.item);
               end if;  --- End if I_cost_reason = 3
               If  L_item_tbl.first is not null then
                  FOR i in L_item_tbl.first..L_item_tbl.last LOOP
                      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_BRACKET_CHILD_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                      open C_LOCK_BRACKET_CHILD_LOC;
                      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_BRACKET_CHILD_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                      close C_LOCK_BRACKET_CHILD_LOC;
                      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                      update item_supp_country_bracket_cost
                         set  unit_cost           = L_unit_cost_tbl(i),
                              default_bracket_ind = L_default_bracket
                        where bracket_value1      = L_bracket1
                          and location            = L_loc
                          and origin_country_id   = L_country
                          and supplier            = L_supplier
                          and item                = L_item_tbl(i);
                  END LOOP;
               end if;
            end if; -- end if L_update_child = 'Y';
            if L_default_bracket = 'Y' then
            --- Update the unit cost on ITEM_SUPP_COUNTRY_LOC with the
            --- unit cost of the default bracket at the passed in location.
            --- Update the records on item_supp_country with the unit
            --- cost at the primary location.If the child indicator
            --- passed is 'Y',update all child record at the
            --- the passed in location and update item_supp_country
            --- for the primary location of the child items.
            --- Item expenses and assessments will be updated in this function.
                  if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                                   L_item,
                                                                   L_supplier,
                                                                   L_country,
                                                                   L_loc,
                                                                   L_update_child) then
                       return FALSE;
                 end if;
            end if;   --- end if L_default_bracket = 'Y'
         else
            ---------------------------------------------------------
            --- If the item is costed by location but not bracket
            --- UPDATE item_supp_country_loc and item_supp_country
            --- For the current item and it's children if indicated.
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_COUNTRY_LOC', 'ITEM_SUPP_COUNTRY_LOC',NULL);
            open C_LOCK_SUPP_COUNTRY_LOC;
            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_COUNTRY_LOC', 'ITEM_SUPP_COUNTRY_LOC',NULL);
            Close C_LOCK_SUPP_COUNTRY_LOC;
            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC',NULL);
            update item_supp_country_loc
               set unit_cost            = L_unit_cost,
                   last_update_id       = user,
                   last_update_datetime = sysdate
             where loc                  = L_loc
               and origin_country_id    = L_country
               and supplier             = L_supplier
               and item                 = L_item;
            --- Update item_supp_country_loc with the unit cost
            --- the update child indicator is set to 'N'
            --- Update the records on item_supp_country with the unit
            --- cost at the primary location.
            if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                                L_item,
                                                L_supplier,
                                                L_country,
                                                L_loc,
                                                'N',
                                                'Y',
                                                I_cost_change) then
               return FALSE;
            end if;
           --- If the update child indicator is passed in as 'Y'
            if  L_update_child = 'Y' then
                SQL_LIB.SET_MARK('OPEN', 'C_LOCK_CNTRY_LOC_CHILDREN', 'ITEM_SUPP_COUNTRY_LOC',NULL);
                open C_LOCK_CNTRY_LOC_CHILDREN;
                SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_CNTRY_LOC_CHILDREN', 'ITEM_SUPP_COUNTRY_LOC',NULL);
                Close C_LOCK_CNTRY_LOC_CHILDREN;
                SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC',NULL);
                if L_item_tbl.first is not null  then
                   FOR i in L_item_tbl.first..L_item_tbl.last LOOP
                      update item_supp_country_loc
                         set unit_cost = L_unit_cost_tbl(i),
                             last_update_datetime = sysdate,
                             last_update_id = user
                        where item = L_item_tbl(i)
                          and loc = L_loc
                          and supplier = L_supplier
                          and origin_country_id = L_country;
                      if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                                          L_item_tbl(i),
                                                          L_supplier,
                                                          L_country,
                                                          L_loc,
                                                          'N',
                                                          'N',
                                                          I_cost_change) then
                         return FALSE;
                   end if;
                END LOOP;
                end if;
            end if;
         end if; --- if L_bracket1 is NULL
         --- PO COST PROCESSING AND BUYER PACK update
         --- If the current item is not the previous item
         --- then check to see if the item is a transaction level item.  If it is
         --- Check to see if it it exists on a PO.  If it does, update it with the
         --- new costs.  Also, call UPDATE_BUYER_PACk to update the costs of
         --- any packs in which this item or its children is a component
         if L_prev_item != L_item then
            if not COST_EXTRACT_SQL.UPDATE_BUYER_PACK(O_error_message,
                                                      L_prev_item) then
               return FALSE;
            end if;
            if L_prev_item_level = L_prev_tran_level and L_prev_flag = 'Y' then
               if not COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS(O_error_message,
                                                              L_prev_item,
                                                              L_unit_cost) then
                  return FALSE;
               end if;
            end if;   --- end if L_prev_item_level = L_prev_tran_level

            --- if the previous item is at above the tran level (item parent)
            --- check if any of its transaction level children are on an order.
            --- If they are, update th costs on that order.
            if L_prev_item_level < L_prev_tran_level and L_prev_flag = 'Y' then
               if not COST_EXTRACT_SQL.UPDATE_CHILD_APPROVED_ORDERS(O_error_message,
                                                                    L_item_tbl,
                                                                    L_unit_cost_tbl) then
                  return FALSE;
               end if;
            end if;  --- end if L_prev_item_level < L_prev_tran_level and L_prev_flag = 'Y'
            --- Since the item has changed, reset the recalc_ord_flag
            --- for the previous item.
            L_prev_flag := 'N';
         end if;  --- end if L_old_item != L_item
         --- Set the current item attributes to
         --- previous status
         L_prev_item       := L_item;
         L_prev_tran_level := L_tran_level;
         L_prev_item_level := L_item_level;
         --- Set a reclac_ord_flag equal to the recalc_ord_ind.
         --- This will be used to determine if a item is to be recalculated for
         --- a purchaes order.
         if L_recalc_ord_ind = 'Y' then
            L_prev_flag := L_recalc_ord_ind;
         end if;
         --- Increment the L_multiple variable
         L_loc_multiple := L_loc_multiple + 1;
      END LOOP;  --- End loop through COST_SUSP_SUP_DETAIL_LOC records

      -------------------------------------------------------------
      --- Loop through COST_SUSP_SUP_DETAIL records
      --- Set the multiple to 1 for processing
      L_multiple := 1;
      SQL_LIB.SET_MARK('FETCH','C_SELECT_DETAIL','COST_SUSP_SUP_DETAIL',NULL);
      FOR rec in C_SELECT_DETAIL
      LOOP
         L_item           := rec.item;
         L_supplier       := rec.supplier;
         L_country        := rec.origin_country_id;
         L_bracket1       := rec.bracket_value1;
         L_bracket2       := rec.bracket_value2;
         L_unit_cost      := rec.unit_cost;
         L_change_type    := rec.cost_change_type;
         L_change_amount  := rec.cost_change_value;
         L_recalc_ord_ind := rec.recalc_ord_ind;
         L_default_bracket:= rec.default_bracket_ind;
         L_dept           := rec.dept;
         L_seq_no         := rec.sup_dept_seq_no;
         L_tran_level     := rec.tran_level;
         L_item_level     := rec.item_level;
         --- set the previous item equal to the current item for the first record
         --- of processing
         if L_multiple = 1 then
            L_prev_item := L_item;
            if I_cost_reason = 3 then
               if not SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                                          L_bracket_level,
                                                          L_supplier) then
                  return FALSE;
               end if;
            end if;
         end if;
         --- Check to see if the item_level is less than the transaction level.
         --- If it is, set the update child indicator to 'Y'.
         --- If it is not, set it equal to 'N'.
         if L_item_level < L_tran_level then
            L_update_child := 'Y';
            If not CALCULATE_UNIT_COST(O_error_message,
                                       L_unit_cost_tbl,
                                       L_item_tbl,
                                       L_supplier,
                                       L_country,
                                       L_bracket1,
                                       L_item,
                                       L_change_type,
                                       L_change_amount) then

               return FALSE;
            end if;
         else
            L_update_child := 'N';
         end if;
         if L_bracket1 is NULL then
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPP_COUNTRY',
                             'item: '|| L_item || ',supplier: '||to_char(L_supplier) || ',country: ' || L_country);
            open C_LOCK_ITEM_SUPP_COUNTRY;
            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPP_COUNTRY', 'ITEM_SUPP_COUNTRY',
                             'item: '|| L_item || ',supplier: '||to_char(L_supplier)|| ',country: ' || L_country);
            close C_LOCK_ITEM_SUPP_COUNTRY;
            --- update ITEM_SUPP_COUNTRY with the new unit cost
            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',
                             'Item: '|| L_item
                             || ',Supplier: ' ||to_char(L_supplier)
                             || ',country: ' || L_country);
            update item_supp_country
               set unit_cost            = L_unit_cost,
                   last_update_id       = user,
                   last_update_datetime = sysdate
             where origin_country_id    = L_country
               and supplier             = L_supplier
               and item                 = L_item;
            --- update all ITEM_SUPP_COUNTRY_LOC records for the item
            --- with the unit cost on ITEM_SUPP_COUNTRY
            if not UPDATE_BASE_COST.CHANGE_ISC_COST(O_error_message,
                                                    L_item,
                                                    L_supplier,
                                                    L_country,
                                                    'Y')then
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('FETCH','C_SUPP_LOC','ITEM_SUPP_COUNTRY_LOC',NULL);
            FOR rec in C_SUPP_LOC
            LOOP
               L_location := rec.loc;
               /*GS change start */
               if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                                   L_item,
                                                   L_supplier,
                                                   L_country,
                                                   L_location,
                                                   'N',
                                                   'N',
                                                   I_cost_change) then
                        return FALSE;
                end if;
                /*GS change end */
            END LOOP; --- End loop through locations

            /*GS change start */
            /*   Removed call to UPDATE_BASE_COST.ELC_CALLS */
            /*GS change end */


            --- Update item_supp_country for the child items
            if L_update_child = 'Y' then
               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_SUPP_COUNTRY_CHILD', 'ITEM_SUPP_COUNTRY',NULL);
               open C_LOCK_ITEM_SUPP_COUNTRY_CHILD;
               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_SUPP_COUNTRY_CHILD', 'ITEM_SUPP_COUNTRY',NULL);
               close C_LOCK_ITEM_SUPP_COUNTRY_CHILD;
               --- update ITEM_SUPP_COUNTRY with the new unit cost
               SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',NULL);
               if L_item_tbl.first is NOT NULL then
               FOR i in L_item_tbl.first..L_item_tbl.last LOOP
                      update item_supp_country
                        set unit_cost            = L_unit_cost_tbl(i),
                            last_update_id       = user,
                            last_update_datetime = sysdate
                      where origin_country_id    = L_country
                        and supplier             = L_supplier
                        and item                 = L_item_tbl(i);

                   --- update all ITEM_SUPP_COUNTRY_LOC records for the children
                   --- with the unit cost on ITEM_SUPP_COUNTRY
                   if not UPDATE_BASE_COST.CHANGE_ISC_COST(O_error_message,
                                                           L_item_tbl(i),
                                                           L_supplier,
                                                           L_country,
                                                           'Y')then
                    return FALSE;
                   end if;
                   SQL_LIB.SET_MARK('FETCH','C_SUPP_LOC','ITEM_SUPP_COUNTRY_LOC',NULL);
                   FOR rec in C_SUPP_LOC
                   LOOP
                     L_location := rec.loc;
                     /*GS change start */
                     if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                                         L_item_tbl(i),
                                                         L_supplier,
                                                         L_country,
                                                         L_location,
                                                         'N',
                                                         'Y',
                                                         I_cost_change) then
                        return FALSE;
                     end if;
                     /*GS change end */
                   END LOOP; --- End loop through locations
                   /*GS change start */
                   /* Removed calls to UPDATE_BASE_COST.ELC_CALLS*/
                   /*GS change end */
               END LOOP;
               end if;
            end if;   --- L_update_child = 'Y'
         end if;  --- end if L_bracket1 is NULL
         --- If the item is not costed by location but costed by bracket
         --- then update the brackets where the location is null on
         --- ITEM_SUPP_COUNTRY_BRACKET_COST

         if L_bracket1 is not NULL then
            --- If the cost change reason is 3 (change default bracket), reset
            --- The all brackets to 'N' for any given bracket not on the
            --- Cost change.
            if I_cost_reason = 3 then
               --- Update default bracket for any worksheet items for the supplier.
               if not COST_EXTRACT_SQL.CHANGE_WORKSHEET_DEFAULT(O_error_message,
                                                                L_bracket1,
                                                                L_supplier,
                                                                L_seq_no) then
                  return FALSE;
               end if;
               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               open C_LOCK_ISCBC;
               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               close C_LOCK_ISCBC;
               SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               update item_supp_country_bracket_cost
                  set default_bracket_ind = 'N'
                where bracket_value1     != L_bracket1
                  and origin_country_id   = L_country
                  and supplier            = L_supplier
                  and item                = L_item;
            end if;  --- End if I_cost_reason = 3
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            open C_LOCK_SUPP_CNTRY_BRKT_COST;
            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SUPP_CNTRY_BRKT_COST', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            close C_LOCK_SUPP_CNTRY_BRKT_COST;
            SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            update item_supp_country_bracket_cost
               set unit_cost           = L_unit_cost,
                   default_bracket_ind = L_default_bracket
             where bracket_value1      = L_bracket1
               and origin_country_id   = L_country
               and supplier            = L_supplier
               and item                = L_item;
            --- update child item brackets
            --- on ITEM_SUPP_COUNTRY_BRACKET_COST
            --- If the update child indicator is passed in as 'Y'
            if L_update_child = 'Y' then
               --- If the cost change reason is 3 (change default bracket), reset
               --- The all brackets to 'N' for any given bracket not on the
               --- Cost change.
               if I_cost_reason = 3 then
                  SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  open C_LOCK_ISCBC_CHILD;
                  SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  close C_LOCK_ISCBC_CHILD;
                  SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
                  update item_supp_country_bracket_cost
                     set default_bracket_ind = 'N'
                   where bracket_value1     != L_bracket1
                     and origin_country_id   = L_country
                     and supplier            = L_supplier
                     and item in (select im.item
                                    from item_master im,
                                         item_supp_country_bracket_cost iscbc
                                   where iscbc.supplier          = L_supplier
                                     and iscbc.origin_country_id = L_country
                                     and (im.item_parent         = L_item or
                                          im.item_grandparent    = L_item)
                                     and im.item_level          <= im.tran_level
                                     and iscbc.item              = im.item);
               end if;  --- End if I_cost_reason = 3
               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_BRACKET_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               open C_LOCK_BRACKET_CHILD ;
               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_BRACKET_CHILD', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               close C_LOCK_BRACKET_CHILD ;
               SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
               If L_item_tbl.first is not null then
                  FOR i in L_item_tbl.first..L_item_tbl.last LOOP
                      update item_supp_country_bracket_cost
                        set unit_cost            = L_unit_cost_tbl(i),
                             default_bracket_ind = L_default_bracket
                       where bracket_value1      = L_bracket1
                         and origin_country_id   = L_country
                         and supplier            = L_supplier
                         and item                = L_item_tbl(i);
                  END LOOP;
               end if;
            end if; -- end if L_update_child = 'Y'
            --- if it is not location costed but bracket costed then
            --- update all location level brackets for the item.  Then update
            --- item_supp_country_loc for the default bracket.  Update the
            --- unit cost on item_supp_country for the primary location.
            --- If the update child ind is passed in as 'Y', then make the same updates
            --- to the children.
            if not ITEM_BRACKET_COST_SQL.UPDATE_ALL_LOCATION_BRACKETS(O_error_message,
                                                                      L_item,
                                                                      L_supplier,
                                                                      L_country,
                                                                      L_update_child)then
               return FALSE;
            end if;
            if L_recalc_ord_ind = 'Y' then
               update cost_susp_sup_detail
                  set recalc_ord_ind = 'Y'
                where cost_change = I_cost_change;
            end if;
         end if; --- end if L_bracket is not NULL
         --- ORDER PROCESSING AND BUYER PACK UPDATE---
         --- If the current item is not the previous item
         --- then check to see if the previous item is a transaction level item.
         --- if it was, check to see if it was on any orders.  If it exists on orders,
         --- update those orders with the new costs.
         if L_prev_item != L_item then
            if not COST_EXTRACT_SQL.UPDATE_BUYER_PACK(O_error_message,
                                                      L_prev_item) then
               return FALSE;
            end if;
            if L_prev_item_level = L_prev_tran_level and L_prev_flag = 'Y' then
               --- Update orders for the previous item.
               if not COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS(O_error_message,
                                                              L_prev_item,
                                                              L_unit_cost) then
                  return FALSE;
               end if;
            end if;   --- end if L_prev_item_level = L_prev_tran_level
            --- if the previous item is at or above the tran level (item parent)
            --- check if any of its transaction level children are on an order.
            --- If they are, update the costs on that order.
            if L_prev_item_level < L_prev_tran_level and L_prev_flag = 'Y' then
               if not COST_EXTRACT_SQL.UPDATE_CHILD_APPROVED_ORDERS(O_error_message,
                                                                    L_item_tbl,
                                                                    L_unit_cost_tbl) then
                  return FALSE;
               end if;
            end if;  --- end if L_prev_item_level < L_prev_tran_level and L_prev_flag = 'Y'
            --- Since the item has changed, reset the recalc_ord_flag
            --- for the previous item.
            L_prev_flag := 'N';
         end if;  --- end if L_old_item != L_item
         --- Set the current item attributes to
         --- previous status
         L_prev_item       := L_item;
         L_prev_tran_level := L_tran_level;
         L_prev_item_level := L_item_level;
         --- Set a reclac_ord_flag equal to the recalc_ord_ind.
         --- This will be used to determine if a item is to be recalculated for
         --- a purchaes order.
         if L_recalc_ord_ind = 'Y' then
            L_prev_flag := L_recalc_ord_ind;
         end if;
         --- Increment the L_multiple variable
         L_multiple := L_multiple + 1;
      END LOOP; --- End loop through COST_SUSP_SUP_DETAIL records

      --- Since the last item record in the loop will not be captured for purchase
      --- Order updates, check to see if the last item is at the transaction level.
      --- If it is, then update the order if the recalc ord flag is 'Y'.  Check against
      --- The previous recalc flag as well as the current flag to ensure that
      --- the item is captured correctly.  Also, update any buyer pack costs
      if not COST_EXTRACT_SQL.UPDATE_BUYER_PACK(O_error_message,
                                                L_item) then
         return FALSE;
      end if;
      if (L_tran_level = L_item_level) and
         (L_prev_flag = 'Y' or L_recalc_ord_ind = 'Y') then
         --- Update orders for the previous item.

         if not COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS(O_error_message,
                                                        L_item,
                                                        L_unit_cost) then
            return FALSE;
         end if;
      end if;   --- end if L_prev_item_level = L_prev_tran_level
      --- if the previous item is at or above the tran level (item parent)
      --- check if any of its transaction level children are on an order.
      --- If they are, update th costs on that order.
      if L_item_level < L_tran_level and
         (L_prev_flag = 'Y' or L_recalc_ord_ind = 'Y') then

         if not COST_EXTRACT_SQL.UPDATE_CHILD_APPROVED_ORDERS(O_error_message,
                                                              L_item_tbl,
                                                              L_unit_cost_tbl) then
            return FALSE;
         end if;
      end if;  --- end if L_item_level < L_tran_level and (L_prev_flag = 'Y' or L_recalc_ord_ind = 'Y')
   end if; --- end all other cost change reasons....
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                             L_table,
                                                             I_cost_change,
                                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_COSTS;
----------------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_APPROVED_ORDERS(O_error_message IN OUT VARCHAR2,
                                I_item          IN     ITEM_MASTER.ITEM%TYPE,
                                I_unit_cost     IN     COST_SUSP_SUP_DETAIL.UNIT_COST%TYPE)
   return BOOLEAN IS

   L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS';

   L_table               VARCHAR2(64) := 'COST_CHANGE_SQL';
   L_exists              VARCHAR2(1);
   L_deal_exists         VARCHAR2(1);
   L_order_no            ORDHEAD.ORDER_NO%TYPE;
   L_item                ITEM_MASTER.ITEM%TYPE := NULL;
   L_item_tmp            ITEM_MASTER.ITEM%TYPE := NULL;
   L_unit_cost_sup       COST_SUSP_SUP_DETAIL.UNIT_COST%TYPE;
   L_supplier            SUPS.SUPPLIER%TYPE;

   L_last_order_no       ORDHEAD.ORDER_NO%TYPE  := NULL;

   RECORD_LOCKED         EXCEPTION;
   PRAGMA                EXCEPTION_INIT(Record_Locked, -54);

   cursor C_FIND_APPROVED_ORDERS is
      select oh.order_no,
             os.item
        from ordhead oh,
             ordsku os
       where oh.order_no = os.order_no
         and oh.status = 'A'
         and os.item = I_item
         and exists (select 'x'
                       from ordloc ol
                      where ol.order_no = os.order_no
                        and ol.item = os.item
                        and ol.qty_received is NULL
                        and  NOT (ol.cost_source = 'MANL'))
       union
      select oh.order_no,
             os.item
        from packitem p,
             item_master im,
             ordsku os,
             ordhead oh
       where p.item = I_item
         and im.item = p.pack_no
         and im.pack_type = 'P'
         and im.item = os.item
         and os.order_no = oh.order_no
         and oh.status = 'A'
         and exists (select 'x'
                       from ordloc ol
                      where ol.order_no = os.order_no
                        and ol.item = os.item
                        and ol.qty_received IS NULL
                        and  NOT (ol.cost_source = 'MANL'))
       order by order_no,
                item;

    cursor C_EXPENSE_EXIST is
      select 'x'
        from ordloc_exp
       where order_no = L_order_no
         and item     = I_item
         and est_exp_value > 0;

   cursor C_ASSESS_EXIST is
      select 'x'
        from ordsku_hts_assess
       where order_no = L_order_no
         and est_assess_value > 0;

   cursor C_DEAL_TEMP_EXIST is
      select 'x'
        from deal_calc_queue_temp
       where order_no = L_order_no;

BEGIN

   --- This function will find all approved buyer orders for a passed in item.
   --- Next it will insert or update into deal_calc_que for the item.
   --- Then, it will update the order's unit_cost and unit_cost_init with the
   --- new unit_cost from ITEM_SUPP_COUNTRY_LOC.  Then, it will update any
   --- expenses and assessments for the item.
   --- Check for not null variables that are passed in

   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('FETCH','C_FIND_APPROVED_ORDERS','ORDHEAD',NULL);
   FOR rec in C_FIND_APPROVED_ORDERS
   LOOP
      L_order_no   := rec.order_no;
      L_item_tmp   := rec.item;
      L_item       := NULL;

      if (L_item_tmp != I_item) then
         L_item := L_item_tmp;
      end if;

      --- Check to see if records exist on DEAL_CALC_QUEUE_TEMP
      --- For the order
      if L_last_order_no is NULL or
         (L_order_no != L_last_order_no) then
         SQL_LIB.SET_MARK('OPEN', 'C_DEAL_TEMP_EXIST', 'DEAL_CALC_QUEUE_TEMP',
                          'order number : '|| to_char(L_order_no));
         open C_DEAL_TEMP_EXIST;
         SQL_LIB.SET_MARK('FETCH', 'C_DEAL_TEMP_EXIST', 'DEAL_CALC_QUEUE_TEMP',
                          'order number : '|| to_char(L_order_no));
         fetch C_DEAL_TEMP_EXIST into L_deal_exists;
         if C_DEAL_TEMP_EXIST%NOTFOUND then
            SQL_LIB.SET_MARK('INSERT',NULL,'DEAL_CALC_QUEUE_TEMP',
                             'order_no: ' || to_char(L_order_no));
            insert into deal_calc_queue_temp
                 values (L_order_no,
                        'Y',
                        'N',
                        'N');
         end if;   --- end if C_DEAL_TEMP_EXIST
         SQL_LIB.SET_MARK('CLOSE', 'C_DEAL_TEMP_EXIST', 'DEAL_CALC_QUEUE_TEMP',
                          'order number : '|| to_char(L_order_no));
         close C_DEAL_TEMP_EXIST;

         L_last_order_no := L_order_no;
      end if;

      --- Then, it will update the order's unit_cost and unit_cost_init with the
      --- new unit_cost from ITEM_SUPP_COUNTRY_LOC.

      if (L_item is null) then
         update ordloc
            set unit_cost      = I_unit_cost
          where order_no       = L_order_no
            and item           = I_item;
      else /* for buyer pack item */
         if not SUPP_ITEM_SQL.GET_PRI_SUP_COST(O_error_message,
                                               L_supplier,
                                               L_unit_cost_sup,
                                               L_item,
                                               NULL) then
            return False;
         end if;

         update ordloc
            set unit_cost      = L_unit_cost_sup
          where order_no       = L_order_no
            and item           = L_item;
      end if;

      --- See if expenses exist for the item.  If they do,
      --- Recalculate the expenses for the item.
      SQL_LIB.SET_MARK('OPEN', 'C_EXPENSE_EXIST', 'ORDLOC_EXP',
                       'order number : '|| to_char(L_order_no) || ',item : ' || I_item);
      OPEN C_EXPENSE_EXIST;
      SQL_LIB.SET_MARK('FETCH', 'C_EXPENSE_EXIST', 'ORDLOC_EXP',
                       'order number : '|| to_char(L_order_no) || ',item : ' || I_item);
      FETCH C_EXPENSE_EXIST into L_exists;
      if C_EXPENSE_EXIST%FOUND then
         --- Call package to update the Purchase order assessment
         if not ELC_CALC_SQL.CALC_COMP(O_error_message,
                                       'PE',
                                       NVL(L_item, I_item),
                                       NULL,
                                       NULL,
                                       NULL,
                                       L_order_no,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL) then
            return False;
         end if;
      end if;  --- end if C_EXPENSE_EXIST%FOUND
      SQL_LIB.SET_MARK('CLOSE', 'C_EXPENSE_EXIST', 'ORDLOC_EXP',
                       'order number : '|| to_char(L_order_no) || ',item : ' || I_item);
      CLOSE C_EXPENSE_EXIST;
      --- See if purchase order assessments exist for the order.  If they do,
      --- Recalculate the assessment for the order.
      SQL_LIB.SET_MARK('OPEN', 'C_ASSESS_EXIST', 'ORDSKU_HTS_ASSESS',
                       'order number : '|| to_char(L_order_no));
      OPEN C_ASSESS_EXIST;
      SQL_LIB.SET_MARK('FETCH', 'C_ASSESS_EXIST', 'ORDSKU_HTS_ASSESS',
                       'order number : '|| to_char(L_order_no));
      FETCH C_ASSESS_EXIST into L_exists;
      if C_ASSESS_EXIST%FOUND then
         --- Call package to update the Purchase order assessment
         if not ELC_CALC_SQL.CALC_COMP(O_error_message,
                                       'PA',
                                       NVL(L_item, I_item),
                                       NULL,
                                       NULL,
                                       NULL,
                                       L_order_no,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL) then
            return False;
         end if;
         --- Recalculate expenses again becuase expenses could be dependent
         --- on the assessment
         if not ELC_CALC_SQL.CALC_COMP(O_error_message,
                                       'PE',
                                       NVL(L_item, I_item),
                                       NULL,
                                       NULL,
                                       NULL,
                                       L_order_no,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL) then
            return False;
         end if;
      end if;  --- end if C_ASSESS_EXIST%FOUND
      SQL_LIB.SET_MARK('CLOSE', 'C_ASSESS_EXIST', 'ORDSKU_HTS_ASSESS',
                       'order number : '|| to_char(L_order_no));
      CLOSE C_ASSESS_EXIST;
   END LOOP;   --- End loop through the order number

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                             L_table,
                                                             I_item,
                                                             L_order_no);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_APPROVED_ORDERS;
--------------------------------------------------------------------------------------------------
FUNCTION UPDATE_CHILD_APPROVED_ORDERS(O_error_message   IN OUT    VARCHAR2,
                                      L_item_tbl       IN        TYP_ITEM,
                                      L_unit_cost_tbl  IN        TYP_UNIT_COST)
return BOOLEAN IS
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.UPDATE_CHILD_APPROVED_ORDERS';
L_child               ITEM_MASTER.ITEM%TYPE;
L_unit_cost           NUMBER(20,4);
---
BEGIN
   --- This function will select all transaction level children
   --- for the passed in item and call update_approved_orders to
   --- update any approved orders with the new unit costs from
   --- ITEM_SUPP_COUNTRY_LOC.
   --- Check for not null variables that are passed in
   --- Loop through all transaction level children items and update any PO's
   --- that they are on.
   If L_item_tbl.first is not null  then
      FOR i in L_item_tbl.first..L_item_tbl.last LOOP
          L_child           :=L_item_tbl(i) ;
          L_unit_cost       :=L_unit_cost_tbl(i);
          if not COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS(O_error_message,
                                                         L_child,
                                                         L_unit_cost) then
             return FALSE;
          end if;
      END LOOP;
   end if;
 return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_CHILD_APPROVED_ORDERS;
--------------------------------------------------------------------------------------------------
FUNCTION INSERT_BRACKET_LOC(O_error_message   IN OUT    VARCHAR2,
                            I_cost_change     IN        COST_SUSP_SUP_DETAIL_LOC.COST_CHANGE%TYPE,
                            I_cost_reason     IN        COST_SUSP_SUP_HEAD.REASON%TYPE,
                            O_cost_found      IN OUT    VARCHAR2)return BOOLEAN is
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.INSERT_BRACKET_LOC';
L_table               VARCHAR2(64) := 'COST_EXTRACT_SQL';
L_loc                 COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE;
L_location            COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE;
L_prev_loc            COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE;       --- Variable will contain previous location
L_item                COST_SUSP_SUP_DETAIL_LOC.ITEM%TYPE;
L_supplier            COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE;
L_country             COST_SUSP_SUP_DETAIL_LOC.ORIGIN_COUNTRY_ID%TYPE;
L_bracket1            COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE1%TYPE;
L_bracket2            COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE2%TYPE;
L_unit_cost           COST_SUSP_SUP_DETAIL_LOC.UNIT_COST%TYPE;
L_recalc_ord_ind      COST_SUSP_SUP_DETAIL_LOC.RECALC_ORD_IND%TYPE;
L_prev_flag           COST_SUSP_SUP_DETAIL_LOC.RECALC_ORD_IND%TYPE;
L_seq_no              COST_SUSP_SUP_DETAIL_LOC.SUP_DEPT_SEQ_NO%TYPE;
L_item_level          ITEM_MASTER.ITEM_LEVEL%TYPE;
L_tran_level          ITEM_MASTER.TRAN_LEVEL%TYPE;
L_prev_item_level     ITEM_MASTER.ITEM_LEVEL%TYPE;
L_prev_tran_level     ITEM_MASTER.TRAN_LEVEL%TYPE;
L_dept                DEPS.DEPT%TYPE;
L_update_child        VARCHAR2(1) := 'N';
L_default_bracket     COST_SUSP_SUP_DETAIL.DEFAULT_BRACKET_IND%TYPE;
L_prev_item           ITEM_MASTER.ITEM%TYPE;
L_multiple            NUMBER;
L_counter             NUMBER;
L_worksheet_ctr       NUMBER;
L_bracket_level       VARCHAR2(1);
L_prev_supplier       COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE;
L_prev_country        COST_SUSP_SUP_DETAIL_LOC.ORIGIN_COUNTRY_ID%TYPE;
L_prev_bracket        COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE1%TYPE;
L_bracket_counter     NUMBER :=1;
--- Cursors for all environments
cursor C_SELECT_DETAIL_LOC is
   select csdl.item,
          csdl.supplier,
          csdl.origin_country_id,
          csdl.loc,
          csdl.bracket_value1,
          csdl.bracket_value2,
          csdl.unit_cost,
          csdl.recalc_ord_ind,
          csdl.default_bracket_ind,
          csdl.dept,
          csdl.sup_dept_seq_no,
          im.tran_level,
          im.item_level
     from item_master im,
          cost_susp_sup_detail_loc csdl
    where csdl.item        = im.item
      and csdl.cost_change = I_cost_change
    order by csdl.supplier,
             im.item_level desc,
             csdl.item,
             csdl.loc;
---
cursor C_LOCK_ISCBC_LOC is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     != L_bracket1
      and location            = L_loc
      and origin_country_id   = L_country
      and supplier            = L_supplier
      and item                = L_item;
---
cursor C_SUPP_LOC is
   select loc
     from item_supp_country_loc
    where supplier          = L_supplier
      and origin_country_id = L_country
      and loc_type          = 'W';
BEGIN
   --- This function will insert new brackets into ITEM_SUPP_COUNTRY_LOC
   --- _BRACKET_COST for brackets and location on COST_SUSP_SUP_DETAIL_LOC.
   --- If the item is above the transaction level, insert into this table
   --- for the children.
   --- Update the unit_costs on ITEM_SUPP_COUNTRY_LOC with the default brackets
   --- unit cost.  If the location is the primary location, update the cost
   --- on ITEM_SUPP_COUNTRY.
   --- If the item a transaction level item in a pack, update all pack costs.
   --- If the item is above the transaction level, check to see if any of its children
   --- are in a pack. If they are, update all pack costs.
   --- If the recalc order indicator is yes for the item, and the item is a tran level item,
   --- update orders for the item.  If the item is above the transaction level,
   --- update the orders unit costs for any of the items children.
   --- NULL value validation
   if I_cost_change is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_cost_change',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   --- Set the multiple to 1 for processing
   L_multiple := 1;
   L_counter  := 1;
   L_worksheet_ctr := 1;
   O_cost_found := 'N';
   SQL_LIB.SET_MARK('FETCH','C_SELECT_DETAIL_LOC','COST_SUSP_SUP_DETAIL_LOC',NULL);
   FOR rec in C_SELECT_DETAIL_LOC
   LOOP
      L_item           := rec.item;
      L_supplier       := rec.supplier;
      L_country        := rec.origin_country_id;
      L_loc            := rec.loc;
      L_bracket1       := rec.bracket_value1;
      L_bracket2       := rec.bracket_value2;
      L_unit_cost      := rec.unit_cost;
      L_recalc_ord_ind := rec.recalc_ord_ind;
      L_default_bracket:= rec.default_bracket_ind;
      L_dept           := rec.dept;
      L_seq_no         := rec.sup_dept_seq_no;
      L_tran_level     := rec.tran_level;
      L_item_level     := rec.item_level;
      --- set the previous item equal to the current item for the first record
      --- of processing.  This will be used to ensure that PO logic will not be
      --- executed in the first iteration
      O_cost_found := 'Y';
      if L_multiple = 1 then
         L_prev_item := L_item;
         L_prev_loc  := L_loc;
         --- If the cost change is for a new bracket structure (cost reason = 2)
         --- then delete all brackets on item_supp_country_bracket_cost for
         --- the cost change.
         if I_cost_reason = 2 then
            if not COST_EXTRACT_SQL.DELETE_BRACKET(O_error_message,
                                                   'Y',
                                                   I_cost_change,
                                                   L_dept,
                                                   L_supplier) then
               return false;
            end if;
         end if;
      end if;  --- end if L_multiple = 1
      --- Check to see if the item_level is less than the transaction level.
      --- If it is, set the update child indicator to 'Y'.
      --- If it is not, set it equal to 'N'.
      if L_item_level < L_tran_level then
         L_update_child := 'Y';
      else
         L_update_child := 'N';
      end if;
      if L_counter = 1 then
         --- Find the inventory level to determine if a country level bracket
         --- should be inserted
         if not SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                                    L_bracket_level,
                                                    L_supplier) then
            return FALSE;
         end if;
      end if;  -- end if L_counter = 1
      --- In cases in which brackets were added and the new bracket became a
      --- new default bracket
      if L_default_bracket = 'Y' then
         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_LOCK_ISCBC_LOC;
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_LOCK_ISCBC_LOC;
         SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         update item_supp_country_bracket_cost
            set default_bracket_ind = 'N'
          where bracket_value1     != L_bracket1
            and location            = L_loc
            and origin_country_id   = L_country
            and supplier            = L_supplier
            and item                = L_item;
      end if;
      --- insert into ITEM_SUPP_COUNTRY_BRACKET_COST
      --- for the locations in COST_SUSP_SUP_DETAIL_LOC
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      insert into ITEM_SUPP_COUNTRY_BRACKET_COST(item,
                                                 supplier,
                                                 origin_country_id,
                                                 location,
                                                 bracket_value1,
                                                 loc_type,
                                                 default_bracket_ind,
                                                 unit_cost,
                                                 bracket_value2,
                                                 sup_dept_seq_no)
                                          values(L_item,
                                                 L_supplier,
                                                 L_country,
                                                 L_loc,
                                                 L_bracket1,
                                                 'W',
                                                 L_default_bracket,
                                                 L_unit_cost,
                                                 L_bracket2,
                                                 L_seq_no);
      if L_default_bracket = 'Y' then
         --- Update the unit cost on ITEM_SUPP_COUNTRY_LOC with the
         --- unit cost of the default bracket at the passed in location.
         --- Update the records on item_supp_country with the unit
         --- cost at the primary location.  If the child indicator
         --- is passed in as 'Y', update all child record at the
         --- the passed in location and update item_supp_country
         --- for the primary location of the child items.
         --- Item expenses and assessments will be updated in this function.
         if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                           L_item,
                                                           L_supplier,
                                                           L_country,
                                                           L_loc,
                                                           L_update_child) then
            return FALSE;
         end if;
      end if;   --- end if L_default_bracket = 'Y'
      --- PO COST PROCESSING/country level bracket creation...
      --- If the current item is not the previous item (item has changed),
      --- Create a country level bracket for the previous item.
      --- If the current item is not the previous item then insert a country
      --- level bracket if the supplier is an 'S' or 'D' level supplier.
      --- Next, check to see if the item is a transaction level item.  If it is
      --- Check to see if it it exists on a PO.  If it does, update it with the
      --- new costs.
      if L_prev_item != L_item then
         --- If the inventory level is S or D then insert a country level bracket
         --- for the item.
         if L_bracket_level in ('S', 'D') then
            if not COST_EXTRACT_SQL.INSERT_COUNTRY_BRACKET(O_error_message,
                                                           L_prev_item,
                                                           L_supplier,
                                                           L_country,
                                                           L_dept,
                                                           I_cost_change,
                                                           L_seq_no) then
               return FALSE;
            end if;
         end if;  --- end if L_bracket_level in ('S', 'D')
         if not COST_EXTRACT_SQL.UPDATE_BUYER_PACK(O_error_message,
                                                   L_prev_item) then
            return FALSE;
         end if;
         if L_prev_item_level = L_prev_tran_level and L_prev_flag = 'Y' then
            if not COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS(O_error_message,
                                                           L_prev_item,
                                                           L_unit_cost) then
               return FALSE;
            end if;
         end if;   --- end if L_prev_item_level = L_prev_tran_level;
         --- Since the item has changed, reset the recalc_ord_flag
         --- for the previous item.
         L_prev_flag := 'N';
         L_worksheet_ctr := L_worksheet_ctr + 1;
      end if;  --- end if L_old_item != L_item
      --- Set the bracket counter variable if the locations have changed
      if L_prev_loc != L_loc then
         L_bracket_counter := L_bracket_counter + 1;
      end if;  --- end if L_prev_loc != L_loc
      --- Update any worksheet items that have brackets for all
      --- warehouse locations that are found for the supplier and country
      --- Insert brackets for any worksheet items.
      if L_worksheet_ctr = 1 then
         if L_bracket_level in ('S','D') then
           --- only insert a country level bracket for the first set of location brackets
           --- on the cost change.
           if L_bracket_counter = 1 then
              if not COST_EXTRACT_SQL.INSERT_WKSHT_CNTRY_BRACKET(O_error_message,
                                                                 L_seq_no,
                                                                 L_supplier,
                                                                 L_bracket1,
                                                                 L_bracket2,
                                                                 L_default_bracket,
                                                                 L_dept,
                                                                 L_country) then
                 return FALSE;
              end if;
            end if;  --- end if L_bracket_counter = 1
         end if;  --- end if L_bracket_level in ('S','D')
         if not COST_EXTRACT_SQL.INSERT_WORKSHEET_BRACKET(O_error_message,
                                                          L_bracket_level,
                                                          L_seq_no,
                                                          L_supplier,
                                                          L_bracket1,
                                                          L_bracket2,
                                                          L_default_bracket,
                                                          L_dept,
                                                          L_loc,
                                                          L_country) then
            return FALSE;
         end if;
      end if;  --- end if L_worksheet_ctr = 1
      --- Set the current item attributes to
      --- previous status
      L_prev_item       := L_item;
      L_prev_tran_level := L_tran_level;
      L_prev_item_level := L_item_level;
      L_prev_supplier   := L_supplier;
      L_prev_country    := L_country;
      L_prev_bracket    := L_bracket1;
      L_prev_loc        := L_loc;
      --- Set a reclac_ord_flag equal to the recalc_ord_ind.
      --- This will be used to determine if a item is to be recalculated for
      --- a purchaes order.
      if L_recalc_ord_ind = 'Y' then
         L_prev_flag := L_recalc_ord_ind;
      end if;
      --- Increment the L_multiple variable
      L_multiple := L_multiple + 1;
      L_counter  := L_counter + 1;
   END LOOP;  --- End loop through COST_SUSP_SUP_DETAIL_LOC records
   --- If no cost change records are found (item is NULL)
   --- then skip over the rest of the processing
   if L_item is not NULL then
      --- If the inventory level is S or D then insert a country level bracket
      --- for the item.
      if L_bracket_level in ('S', 'D') then
         if not COST_EXTRACT_SQL.INSERT_COUNTRY_BRACKET(O_error_message,
                                                        L_item,
                                                        L_supplier,
                                                        L_country,
                                                        L_dept,
                                                        I_cost_change,
                                                        L_seq_no) then
            return FALSE;
         end if;
      end if;  --- end if L_bracket_level in ('S', 'D')
      --- LAST ITEM AND ITEM CHILD IN LOOP PO PROCESSING AND PACK UPDATE
      --- Since the last item record in the loop will not be captured for purchase
      --- Order updates, check to see if the last item is at the transaction level.
      --- If it is, then update the order if the recalc ord flag is 'Y'.  Check against
      --- The previous recalc flag as well as the current flag to ensure that
      --- the item is captured correctly.
      if not COST_EXTRACT_SQL.UPDATE_BUYER_PACK(O_error_message,
                                                L_item) then
         return FALSE;
      end if;
      if (L_tran_level = L_item_level) and
         (L_prev_flag = 'Y' or L_recalc_ord_ind = 'Y') then
         if not COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS(O_error_message,
                                                        L_item,
                                                        L_unit_cost) then
            return FALSE;
         end if;
      end if; --- if (L_tran_level = L_item_level) and (L_prev_flag = 'Y' or L_recalc_ord_ind = 'Y')
   end if;  --- end if L_item is not NULL
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_BRACKET_LOC;
----------------------------------------------------------------------------------------------------
FUNCTION INSERT_BRACKET(O_error_message   IN OUT    VARCHAR2,
                        I_cost_change     IN        COST_SUSP_SUP_DETAIL_LOC.COST_CHANGE%TYPE,
                        I_cost_reason     IN        COST_SUSP_SUP_HEAD.REASON%TYPE,
                        I_cost_found      IN        VARCHAR2)return BOOLEAN is
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.INSERT_BRACKET';
L_table               VARCHAR2(64) := 'COST_EXTRACT_SQL';
L_item                COST_SUSP_SUP_DETAIL.ITEM%TYPE;
L_supplier            COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE;
L_country             COST_SUSP_SUP_DETAIL.ORIGIN_COUNTRY_ID%TYPE;
L_bracket1            COST_SUSP_SUP_DETAIL.BRACKET_VALUE1%TYPE;
L_bracket2            COST_SUSP_SUP_DETAIL.BRACKET_VALUE2%TYPE;
L_seq_no              COST_SUSP_SUP_DETAIL.SUP_DEPT_SEQ_NO%TYPE;
L_loc                 ITEM_SUPP_COUNTRY_LOC.LOC%TYPE;
L_all_loc             ITEM_SUPP_COUNTRY_LOC.LOC%TYPE;
L_location            ITEM_SUPP_COUNTRY_LOC.LOC%TYPE;
L_unit_cost           COST_SUSP_SUP_DETAIL.UNIT_COST%TYPE;
L_recalc_ord_ind      COST_SUSP_SUP_DETAIL.RECALC_ORD_IND%TYPE;
L_prev_flag           COST_SUSP_SUP_DETAIL.RECALC_ORD_IND%TYPE;
L_item_level          ITEM_MASTER.ITEM_LEVEL%TYPE;
L_tran_level          ITEM_MASTER.TRAN_LEVEL%TYPE;
L_prev_item_level     ITEM_MASTER.ITEM_LEVEL%TYPE;
L_prev_tran_level     ITEM_MASTER.TRAN_LEVEL%TYPE;
L_pack_ind            ITEM_MASTER.PACK_IND%TYPE;
L_dept                DEPS.DEPT%TYPE;
L_update_child        VARCHAR2(1) := 'N';
L_default_bracket     COST_SUSP_SUP_DETAIL.DEFAULT_BRACKET_IND%TYPE;
L_prev_item           ITEM_MASTER.ITEM%TYPE;
L_multiple            NUMBER;
L_counter             NUMBER;
L_worksheet_ctr       NUMBER;
L_bracket_level       VARCHAR2(1);
L_prev_country        COST_SUSP_SUP_DETAIL.ORIGIN_COUNTRY_ID%TYPE;
L_prev_supplier       COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE;
cursor C_SELECT_DETAIL is
   select csd.item,
          csd.supplier,
          csd.origin_country_id,
          csd.bracket_value1,
          csd.bracket_value2,
          csd.unit_cost,
          csd.recalc_ord_ind,
          csd.default_bracket_ind,
          csd.dept,
          csd.sup_dept_seq_no,
          im.tran_level,
          im.item_level
     from item_master im,
          cost_susp_sup_detail csd
    where csd.item        = im.item
      and csd.cost_change = I_cost_change
    order by csd.supplier,
             im.item_level desc,
             csd.item;
---
cursor C_SUPP_LOC is
   select loc
     from item_supp_country_loc
    where item              = L_item
      and supplier          = L_supplier
      and origin_country_id = L_country
      and loc_type          = 'W';
---
cursor C_LOCK_ISCBC is
   select 'x'
     from item_supp_country_bracket_cost
    where bracket_value1     != L_bracket1
      and origin_country_id   = L_country
      and supplier            = L_supplier
      and item                = L_item;
BEGIN
   --- This function will insert new brackets into ITEM_SUPP_COUNTRY_LOC
   --- _BRACKET_COST for brackets on COST_SUSP_SUP_DETAIL.
   --- If the item is above the transaction level, insert into this table
   --- for the children.  Insert an item level bracket first, then insert
   --- brackets for all locations on ITEM_SUPP_COUNTRY_LOC for the item.
   --- Update the unit_costs on ITEM_SUPP_COUNTRY_LOC with the default brackets
   --- unit cost.  If the location is the primary location, update the cost
   --- on ITEM_SUPP_COUNTRY.
   --- If the item a transaction level item in a pack, update all pack costs.
   --- If the item is above the transaction level, check to see if any of its children
   --- are in a pack. If they are, update all pack costs.
   --- If the recalc order indicator is yes for the item, and the item is a tran level item,
   --- update orders for the item.  If the item is above the transaction level,
   --- update the orders unit costs for any of the items children.
   --- NULL value validation
   if I_cost_change is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_cost_change',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   L_multiple := 1;
   L_counter  := 1;
   L_worksheet_ctr := 1;
   SQL_LIB.SET_MARK('FETCH','C_SELECT_DETAIL','COST_SUSP_SUP_DETAIL',NULL);
   FOR rec in C_SELECT_DETAIL
   LOOP
      L_item           := rec.item;
      L_supplier       := rec.supplier;
      L_country        := rec.origin_country_id;
      L_bracket1       := rec.bracket_value1;
      L_bracket2       := rec.bracket_value2;
      L_unit_cost      := rec.unit_cost;
      L_recalc_ord_ind := rec.recalc_ord_ind;
      L_default_bracket:= rec.default_bracket_ind;
      L_dept           := rec.dept;
      L_seq_no         := rec.sup_dept_seq_no;
      L_tran_level     := rec.tran_level;
      L_item_level     := rec.item_level;
      --- set the previous item equal to the current item for the first record
      --- of processing
      if L_multiple = 1 then
         L_prev_item := L_item;
         --- If the cost change is for a new bracket structure (cost reason = 2)
         --- then delete all brackets on item_supp_country_bracket_cost for
         --- the cost change.
         if I_cost_reason = 2 and I_cost_found = 'N' then
            if not COST_EXTRACT_SQL.DELETE_BRACKET(O_error_message,
                                                   'N',
                                                   I_cost_change,
                                                   L_dept,
                                                   L_supplier) then
               return false;
            end if;
         end if;
      end if; --- end if L_multiple = 1
      --- Check to see if the item_level is less than the transaction level.
      --- If it is, set the update child indicator to 'Y'.
      --- If it is not, set it equal to 'N'.
      if L_item_level < L_tran_level then
         L_update_child := 'Y';
      else
         L_update_child := 'N';
      end if;
      if L_counter = 1 then
         if not SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                                    L_bracket_level,
                                                    L_supplier) then
            return FALSE;
         end if;
      end if; --- end if L_counter = 1
      --- In cases in which brackets were added and the new bracket became a
      --- new default bracket
      if L_default_bracket = 'Y' then
         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_LOCK_ISCBC;
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_LOCK_ISCBC;
         SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         update item_supp_country_bracket_cost
            set default_bracket_ind = 'N'
          where bracket_value1     != L_bracket1
            and origin_country_id   = L_country
            and supplier            = L_supplier
            and item                = L_item;
      end if;
      if L_bracket_level in ('S','D') then
         --- Insert a item level brackets
         SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         insert into ITEM_SUPP_COUNTRY_BRACKET_COST(item,
                                                    supplier,
                                                    origin_country_id,
                                                    bracket_value1,
                                                    default_bracket_ind,
                                                    unit_cost,
                                                    bracket_value2,
                                                    sup_dept_seq_no)
                                             values(L_item,
                                                    L_supplier,
                                                    L_country,
                                                    L_bracket1,
                                                    L_default_bracket,
                                                    L_unit_cost,
                                                    L_bracket2,
                                                    L_seq_no);
      end if;  --- end if L_bracket_level in ('S','D')
      --- Create all location level brackets with locations in
      --- ITEM_SUPP_COUNTRY_LOC
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      insert into ITEM_SUPP_COUNTRY_BRACKET_COST(item,
                                                 supplier,
                                                 origin_country_id,
                                                 bracket_value1,
                                                 default_bracket_ind,
                                                 unit_cost,
                                                 bracket_value2,
                                                 loc_type,
                                                 location,
                                                 sup_dept_seq_no)
                                          select L_item,
                                                 L_supplier,
                                                 L_country,
                                                 L_bracket1,
                                                 L_default_bracket,
                                                 L_unit_cost,
                                                 L_bracket2,
                                                 'W',
                                                 iscl.loc,
                                                 L_seq_no
                                            from item_supp_country_loc iscl
                                           where iscl.loc_type          = 'W'
                                             and iscl.supplier          = L_supplier
                                             and iscl.origin_country_id = L_country
                                             and iscl.item              = L_item;
      if L_default_bracket = 'Y' then
         --- To send location bracket default bracket costs to
         --- ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY, loop
         --- Through all locations on ITEM_SUPP_COUNTRY_LOC
         SQL_LIB.SET_MARK('FETCH','C_SUPP_LOC','EDI_COST_LOC',NULL);
         FOR rec in C_SUPP_LOC
         LOOP
            L_loc := rec.loc;
            --- Update the unit cost on ITEM_SUPP_COUNTRY_LOC with the
            --- unit cost of the default bracket at the passed in location.
            --- Update the records on item_supp_country with the unit
            --- cost at the primary location.  If the child indicator
            --- is passed in as 'Y', update all child record at the
            --- the passed in location and update item_supp_country
            --- for the primary location of the child items.
            --- Item expenses and assessments will be updated in this function.
            if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                              L_item,
                                                              L_supplier,
                                                              L_country,
                                                              L_loc,
                                                              L_update_child) then
               return FALSE;
            end if;
         END LOOP;   --- End Loop through ITEM_SUPP_COUNTRY_LOC locations.
      end if;   --- end if L_default_bracket = 'Y'
      --- ORDER PROCESSING ---
      --- If the current item is not the previous item
      --- then check to see if the previous item is a transaction level item.
      --- if it was, check to see if it was on any orders.  If it exists on orders,
      --- update those orders with the new costs.
      if L_prev_item != L_item then
         if not COST_EXTRACT_SQL.UPDATE_BUYER_PACK(O_error_message,
                                                   L_prev_item) then
            return FALSE;
         end if;
         if L_prev_item_level = L_prev_tran_level and L_prev_flag = 'Y' then
            --- Update orders for the previous item.
            if not COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS(O_error_message,
                                                           L_prev_item,
                                                           L_unit_cost) then
               return FALSE;
            end if;
         end if;   --- end if L_prev_item_level = L_prev_tran_level
         --- Since the item has changed, reset the recalc_ord_flag
         --- for the previous item.
         L_prev_flag := 'N';
         L_worksheet_ctr := L_worksheet_ctr + 1;
      end if;  --- end if L_old_item != L_item
      --- Update any worksheet items that have brackets for all
      --- warehouse locations that are found for the supplier and country
      --- Insert brackets for any worksheet items.
      if L_worksheet_ctr = 1 and I_cost_found = 'N' then
         if L_bracket_level in ('S','D') then
            if not COST_EXTRACT_SQL.INSERT_WKSHT_CNTRY_BRACKET(O_error_message,
                                                               L_seq_no,
                                                               L_supplier,
                                                               L_bracket1,
                                                               L_bracket2,
                                                               L_default_bracket,
                                                               L_dept,
                                                               L_country) then
               return FALSE;
            end if;
         end if;  --- end if L_bracket_level in ('S','D') then
         if not COST_EXTRACT_SQL.INSERT_WORKSHEET_BRACKET(O_error_message,
                                                          L_bracket_level,
                                                          L_seq_no,
                                                          L_supplier,
                                                          L_bracket1,
                                                          L_bracket2,
                                                          L_default_bracket,
                                                          L_dept,
                                                          NULL,
                                                          L_country) then
            return FALSE;
         end if;
      end if;
      --- Set the current item attributes to
      --- previous status
      L_prev_item       := L_item;
      L_prev_tran_level := L_tran_level;
      L_prev_item_level := L_item_level;
      L_prev_supplier   := L_supplier;
      L_prev_country    := L_country;
      --- Set a reclac_ord_flag equal to the recalc_ord_ind.
      --- This will be used to determine if a item is to be recalculated for
      --- a purchaes order.
      if L_recalc_ord_ind = 'Y' then
         L_prev_flag := L_recalc_ord_ind;
      end if;
      --- Increment the L_multiple variable
      L_multiple := L_multiple + 1;
      L_counter  := L_counter  + 1;
   END LOOP; --- End loop through COST_SUSP_SUP_DETAIL records
   --- If no cost change record is found (L_item is null)
   --- then skip all processing
   if L_item is not NULL then
      --- Since the last item record in the loop will not be captured for purchase
      --- Order updates, check to see if the last item is at the transaction level.
      --- If it is, then update the order if the recalc ord flag is 'Y'.  Check against
      --- The previous recalc flag as well as the current flag to ensure that
      --- the item is captured correctly. Also, update any buyer pack costs in which this item
      --- is a component
      if not COST_EXTRACT_SQL.UPDATE_BUYER_PACK(O_error_message,
                                                L_item) then
         return FALSE;
      end if;
      if (L_tran_level = L_item_level) and
         (L_prev_flag = 'Y' or L_recalc_ord_ind = 'Y') then
         --- Update orders for the previous item.
         if not COST_EXTRACT_SQL.UPDATE_APPROVED_ORDERS(O_error_message,
                                                        L_item,
                                                        L_unit_cost) then
           return FALSE;
         end if;
      end if;   --- end if L_prev_item_level = L_prev_tran_level
   end if;  --- end if L_item is not NULL
   return TRUE;
END INSERT_BRACKET;
----------------------------------------------------------------------------------------------------------------
FUNCTION INSERT_COUNTRY_BRACKET(O_error_message   IN OUT    VARCHAR2,
                                I_item            IN        COST_SUSP_SUP_DETAIL_LOC.ITEM%TYPE,
                                I_supplier        IN        COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE,
                                I_country         IN        COST_SUSP_SUP_DETAIL_LOC.ORIGIN_COUNTRY_ID%TYPE,
                                I_dept            IN        COST_SUSP_SUP_DETAIL_LOC.DEPT%TYPE,
                                I_cost_change     IN        COST_SUSP_SUP_DETAIL_LOC.COST_CHANGE%TYPE,
                                I_seq_no          IN        COST_SUSP_SUP_DETAIL_LOC.SUP_DEPT_SEQ_NO%TYPE) return BOOLEAN is
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.INSERT_COUNTRY_BRACKET';
L_table               VARCHAR2(64) := 'COST_EXTRACT_SQL';
L_dept                COST_SUSP_SUP_DETAIL_LOC.DEPT%TYPE;
L_default_ind         VARCHAR2(1)  := 'N';
cursor C_DEPT is
   select dept
     from item_master
    where item = I_item;
cursor C_LOCK_ISCBC is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where iscbc.supplier          = I_supplier
      and iscbc.origin_country_id = I_country
      and iscbc.item              = I_item
      and iscbc.supplier          = I_supplier
      and iscbc.sup_dept_seq_no   = I_seq_no
      and iscbc.location          is NULL
      for update nowait;
cursor C_SELECT_DEFAULT is
   select 'Y'
     from cost_susp_sup_detail_loc
    where cost_change         = I_cost_change
      and item                = I_item
      and supplier            = I_supplier
      and origin_country_id   = I_country
      and sup_dept_seq_no     = I_seq_no
      and default_bracket_ind = 'Y';
BEGIN
   --- This function will insert a country level bracket(no locations) into
   --- ITEM_SUPP_COUNTRY_BRACKET_COST.
   --- NULL value validation
   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_country is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_country',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_seq_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_dept is null then
      --- Grab the department for the item
      SQL_LIB.SET_MARK('OPEN', 'C_DEPT', 'ITEM_MASTER','ITEM: ' || I_item);
      OPEN C_DEPT;
      SQL_LIB.SET_MARK('FETCH', 'C_DEPT', 'ITEM_MASTER','ITEM: ' || I_item);
      FETCH C_DEPT into L_dept;
      SQL_LIB.SET_MARK('CLOSE', 'C_DEPT', 'ITEM_MASTER','ITEM: ' || I_item);
      CLOSE C_DEPT;
   else
      L_dept := I_dept;
   end if;
   --- Check to see if the cost change for the item has a default bracket
   SQL_LIB.SET_MARK('OPEN', 'C_SELECT_DEFAULT', 'COST_SUSP_SUP_DETAIL_LOC',NULL);
   OPEN C_SELECT_DEFAULT;
   SQL_LIB.SET_MARK('FETCH', 'C_SELECT_DEFAULT', 'COST_SUSP_SUP_DETAIL_LOC',NULL);
   FETCH C_SELECT_DEFAULT into L_default_ind;
   SQL_LIB.SET_MARK('CLOSE', 'C_SELECT_DEFAULT', 'COST_SUSP_SUP_DETAIL_LOC',NULL);
   CLOSE C_SELECT_DEFAULT;
   --- if the cost change contains a new default bracket then reset all default bracket
   --- for the item to 'N'
   if L_default_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      open C_LOCK_ISCBC;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      close C_LOCK_ISCBC;
      SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      Update item_supp_country_bracket_cost iscbc
         set iscbc.default_bracket_ind = 'N'
       where iscbc.supplier          = I_supplier
         and iscbc.origin_country_id = I_country
         and iscbc.item              = I_item
         and iscbc.supplier          = I_supplier
         and iscbc.sup_dept_seq_no   = I_seq_no
         and iscbc.location          is NULL;
   end if;
   --- Insert a country level record.  Use the brackets
   --- and default_bracket_ind from SUP_BRACKET_COST
   SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
   insert into item_supp_country_bracket_cost(item,
                                              supplier,
                                              origin_country_id,
                                              location,
                                              loc_type,
                                              default_bracket_ind,
                                              bracket_value1,
                                              bracket_value2,
                                              unit_cost,
                                              sup_dept_seq_no)
                                       select I_item,
                                              I_supplier,
                                              I_country,
                                              NULL,
                                              NULL,
                                              sbc.default_bracket_ind,
                                              sbc.bracket_value1,
                                              sbc.bracket_value2,
                                              isc.unit_cost,
                                              I_seq_no
                                         from item_supp_country isc,
                                              sup_bracket_cost sbc
                                        where isc.supplier          = I_supplier
                                          and isc.origin_country_id = I_country
                                          and isc.item              = I_item
                                          and sbc.supplier          = I_supplier
                                          and sbc.sup_dept_seq_no   = I_seq_no
                                          and sbc.bracket_value1 not in (select iscbc.bracket_value1
                                                                           from item_supp_country_bracket_cost iscbc
                                                                           where iscbc.supplier          = I_supplier
                                                                             and iscbc.origin_country_id = I_country
                                                                             and iscbc.item              = I_item
                                                                             and iscbc.location          is NULL
                                                                             and iscbc.sup_dept_seq_no   = I_seq_no)
                                          and sbc.bracket_value1 in (select bracket_value1
                                                                       from cost_susp_sup_detail_loc
                                                                      where cost_change = I_cost_change);
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_COUNTRY_BRACKET;
----------------------------------------------------------------------------------------------------
FUNCTION INSERT_WORKSHEET_BRACKET(O_error_message   IN OUT    VARCHAR2,
                                  I_bracket_level   IN        SUPS.INV_MGMT_LVL%TYPE,
                                  I_seq_no          IN        COST_SUSP_SUP_DETAIL_LOC.SUP_DEPT_SEQ_NO%TYPE,
                                  I_supplier        IN        COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE,
                                  I_bracket_value1  IN        COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE1%TYPE,
                                  I_bracket_value2  IN        COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE2%TYPE,
                                  I_default_ind     IN        COST_SUSP_SUP_DETAIL_LOC.DEFAULT_BRACKET_IND%TYPE,
                                  I_dept            IN        COST_SUSP_SUP_DETAIL_LOC.DEPT%TYPE,
                                  I_location        IN        COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE,
                                  I_country         IN        COST_SUSP_SUP_DETAIL_LOC.ORIGIN_COUNTRY_ID%TYPE) return BOOLEAN is
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.INSERT_WORKSHEET_BRACKET';
L_table               VARCHAR2(64) := 'COST_EXTRACT_SQL';
L_all_loc             ITEM_LOC.LOC%TYPE;
---
cursor C_LOC_ISCBC_ALL_LOC is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where iscbc.bracket_value1  != I_bracket_value1
      and iscbc.supplier   = I_supplier
      and iscbc.item in (select im1.item
                          from item_master im1
                         where im1.status in ('S','W')
                           and (im1.pack_type not in ('B') or
                                im1.pack_type is NULL))
      and iscbc.origin_country_id = I_country
      and iscbc.location          = L_all_loc
      and (exists (select 'x'
                     from item_master im
                    where im.dept = I_dept
                      and im.item = iscbc.item
                      and im.status in ('W','S')
                      and (im.pack_type not in ('B') or
                           im.pack_type is NULL))
       or (I_dept is NULL
           and exists (select 'x'
                         from v_sim_seq_explode v,
                              item_master im
                        where v.sup_dept_seq_no = I_seq_no
                          and v.dept = im.dept
                          and im.item = iscbc.item
                          and v.wh    = iscbc.location
                          and im.status in ('W','S')
                          and (im.pack_type not in ('B') or
                               im.pack_type is NULL))));
---
cursor C_LOCK_ISCBC_LOC is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where iscbc.bracket_value1  != I_bracket_value1
      and iscbc.supplier         = I_supplier
      and iscbc.item in (select im1.item
                          from item_master im1
                         where im1.status in ('S','W')
                           and (im1.pack_type not in ('B') or
                                im1.pack_type is NULL))
      and iscbc.origin_country_id = I_country
      and iscbc.location          = I_location
      and (exists (select 'x'
                     from item_master im
                    where im.dept = I_dept
                      and im.item = iscbc.item
                      and im.status in ('W','S')
                      and (im.pack_type not in ('B') or
                           im.pack_type is NULL))
       or (I_dept is NULL
           and exists (select 'x'
                         from v_sim_seq_explode v,
                              item_master im
                        where v.sup_dept_seq_no = I_seq_no
                          and v.dept = im.dept
                          and im.item = iscbc.item
                          and v.wh    = iscbc.location
                          and im.status in ('W','S')
                          and (im.pack_type not in ('B') or
                               im.pack_type is NULL))));
---
cursor C_ALL_LOC is
   select distinct loc
     from item_supp_country_loc
    where supplier          = I_supplier
      and origin_country_id = I_country
      and loc_type          = 'W'
      and item in (select item
                     from item_master
                    where status in ('W','S')
                      and (pack_type not in ('B') or
                           pack_type is NULL));
--  This function will check to see if there are any worksheet items
--  For a supplier that undergoes a bracket change.  If there are,
--  Brackets will be inserted with a null cost for those items.
BEGIN
   --- NULL value validation
   if I_bracket_level is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_bracket_level',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_seq_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_country is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_country',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_bracket_value1 is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_bracket_value1',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_default_ind is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_default_ind',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   --- if not location is passed in, find all warehous locs on ITEM_SUPP_COUNTRY_LOC
   --- and create loc level brackets
   --- Update any worksheet items that have brackets for all
   --- warehouse locations that are found for the supplier and country
   if I_location is NULL then
      SQL_LIB.SET_MARK('FETCH','C_SUPP_LOC','EDI_COST_LOC',NULL);
      FOR rec in C_ALL_LOC
      LOOP
         L_all_loc := rec.loc;
         --- If default bracket is included, reset all other brackets to 'N'
         if I_default_ind = 'Y' then
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC_ALL_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            open C_LOC_ISCBC_ALL_LOC;
            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC_ALL_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            close C_LOC_ISCBC_ALL_LOC;
            SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC_ALL_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
            update item_supp_country_bracket_cost iscbc
              set iscbc.default_bracket_ind = 'N'
            where iscbc.bracket_value1   != I_bracket_value1
              and iscbc.supplier          = I_supplier
              and iscbc.item in (select im1.item
                                   from item_master im1
                                  where im1.status in ('S','W')
                                    and (im1.pack_type not in ('B') or
                                         im1.pack_type is NULL))
              and iscbc.origin_country_id = I_country
              and iscbc.location          = L_all_loc
              and (exists (select 'x'
                             from item_master im
                            where im.dept = I_dept
                              and im.item = iscbc.item
                              and im.status in ('W','S')
                              and (im.pack_type not in ('B') or
                                  im.pack_type is NULL))
               or (I_dept is NULL
                   and exists (select 'x'
                                 from v_sim_seq_explode v,
                                      item_master im
                                where v.sup_dept_seq_no = I_seq_no
                                  and v.dept = im.dept
                                  and im.item = iscbc.item
                                  and v.wh    = iscbc.location
                                  and im.status in ('W','S')
                                  and (im.pack_type not in ('B') or
                                       im.pack_type is NULL))));
         end if;
         SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST','Supplier: '|| to_char(I_supplier)
                          || 'Department: '|| to_char(I_dept) || 'Location: '|| to_char(L_all_loc)
                          || 'Primary Bracket Value: '|| to_char(I_bracket_value1));
         insert into item_supp_country_bracket_cost(item,
                                                    sup_dept_seq_no,
                                                    supplier,
                                                    origin_country_id,
                                                    location,
                                                    loc_type,
                                                    default_bracket_ind,
                                                    bracket_value1,
                                                    bracket_value2,
                                                    unit_cost)
                                             select distinct iscl.item,
                                                    I_seq_no,
                                                    I_supplier,
                                                    I_country,
                                                    iscl.loc,
                                                    'W',
                                                    I_default_ind,
                                                    I_bracket_value1,
                                                    I_bracket_value2,
                                                    NULL
                                               from item_supp_country_loc iscl
                                              where iscl.supplier          = I_supplier
                                                and iscl.item in (select im1.item
                                                                    from item_master im1
                                                                   where im1.status in ('S','W')
                                                                     and (im1.pack_type not in ('B') or
                                                                          im1.pack_type is NULL))
                                                and iscl.origin_country_id = I_country
                                                and iscl.loc               = L_all_loc
                                                and (exists (select 'x'
                                                               from item_master im
                                                              where im.dept = I_dept
                                                                and im.item = iscl.item
                                                                and im.status in ('W','S')
                                                                and (im.pack_type not in ('B') or
                                                                     im.pack_type is NULL))
                                                  or (I_dept is NULL
                                                     and exists (select 'x'
                                                                   from v_sim_seq_explode v,
                                                                        item_master im
                                                                  where v.sup_dept_seq_no = I_seq_no
                                                                    and v.dept = im.dept
                                                                    and im.item = iscl.item
                                                                    and v.wh    = iscl.loc
                                                                    and im.status in ('W','S')
                                                                    and (im.pack_type not in ('B') or
                                                                         im.pack_type is NULL))));
      END LOOP;
   else
      --- If the default bracket is included, reset all other brackets.
      if I_default_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_LOCK_ISCBC_LOC;
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_LOCK_ISCBC_LOC;
         SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC_LOC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         update item_supp_country_bracket_cost iscbc
            set iscbc.default_bracket_ind = 'N'
          where iscbc.bracket_value1  != I_bracket_value1
            and iscbc.supplier         = I_supplier
            and iscbc.item in (select im1.item
                                 from item_master im1
                                where im1.status in ('S','W')
                                  and (im1.pack_type not in ('B') or
                                       im1.pack_type is NULL))
           and iscbc.origin_country_id = I_country
           and iscbc.location          = I_location
           and (exists (select 'x'
                          from item_master im
                         where im.dept = I_dept
                           and im.item = iscbc.item
                           and im.status in ('W','S')
                           and (im.pack_type not in ('B') or
                                im.pack_type is NULL))
            or (I_dept is NULL
                and exists (select 'x'
                              from v_sim_seq_explode v,
                                   item_master im
                             where v.sup_dept_seq_no = I_seq_no
                               and v.dept = im.dept
                               and im.item = iscbc.item
                               and v.wh    = iscbc.location
                               and im.status in ('W','S')
                               and (im.pack_type not in ('B') or
                                    im.pack_type is NULL))));
      end if;
      --- If locations are provided, build the worksheet brackets off the
      --- passed in locations.
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST','Supplier: '|| to_char(I_supplier)
                       || 'Department: '|| to_char(I_dept) || 'Location: '|| to_char(L_all_loc)
                       || 'Primary Bracket Value: '|| to_char(I_bracket_value1));
      insert into item_supp_country_bracket_cost(item,
                                                 sup_dept_seq_no,
                                                 supplier,
                                                 origin_country_id,
                                                 location,
                                                 loc_type,
                                                 default_bracket_ind,
                                                 bracket_value1,
                                                 bracket_value2,
                                                 unit_cost)
                                          select distinct iscl.item,
                                                 I_seq_no,
                                                 I_supplier,
                                                 I_country,
                                                 iscl.loc,
                                                 'W',
                                                 I_default_ind,
                                                 I_bracket_value1,
                                                 I_bracket_value2,
                                                 NULL
                                            from item_supp_country_loc iscl
                                           where iscl.supplier          = I_supplier
                                             and iscl.item in (select im1.item
                                                                 from item_master im1
                                                                where im1.status in ('S','W')
                                                                  and (im1.pack_type not in ('B') or
                                                                       im1.pack_type is NULL))
                                             and iscl.origin_country_id = I_country
                                             and iscl.loc               = I_location
                                             and (exists (select 'x'
                                                            from item_master im
                                                           where im.dept = I_dept
                                                             and im.item = iscl.item
                                                             and im.status in ('W','S')
                                                             and (im.pack_type not in ('B') or
                                                                  im.pack_type is NULL))
                                               or (I_dept is NULL
                                                  and exists (select 'x'
                                                                from v_sim_seq_explode v,
                                                                     item_master im
                                                               where v.sup_dept_seq_no = I_seq_no
                                                                 and v.dept = im.dept
                                                                 and im.item = iscl.item
                                                                 and v.wh    = iscl.loc
                                                                 and im.status in ('W','S')
                                                                 and (im.pack_type not in ('B') or
                                                                      im.pack_type is NULL))));
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_WORKSHEET_BRACKET;
--------------------------------------------------------------------------------------------------------------------------------
FUNCTION DELETE_BRACKET(O_error_message   IN OUT    VARCHAR2,
                        I_loc_ind         IN        VARCHAR2,
                        I_cost_change     IN        COST_SUSP_SUP_DETAIL_LOC.COST_CHANGE%TYPE,
                        I_dept            IN        DEPS.DEPT%TYPE,
                        I_supplier        IN        COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE) return BOOLEAN is
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.DELETE_BRACKET';
L_table               VARCHAR2(64) := 'COST_EXTRACT_SQL';
L_bracket_level       SUPS.INV_MGMT_LVL%TYPE;
cursor C_SELECT_LOC_CC is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where (iscbc.item,
           iscbc.location,
           iscbc.origin_country_id,
           iscbc.supplier) in (select cssdl.item,
                                      cssdl.loc,
                                      cssdl.origin_country_id,
                                      cssdl.supplier
                                 from cost_susp_sup_detail_loc cssdl
                                where cssdl.cost_change = I_cost_change)
      for update nowait;
cursor C_SELECT_CNTRY is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where (iscbc.item,
           iscbc.origin_country_id,
           iscbc.supplier) in (select cssdl.item,
                                      cssdl.origin_country_id,
                                      cssdl.supplier
                                 from cost_susp_sup_detail_loc cssdl
                                where cssdl.cost_change = I_cost_change)
      and iscbc.location is NULL
      for update nowait;
cursor C_SELECT_WK_LOC is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where (iscbc.location,
           iscbc.origin_country_id,
           iscbc.supplier) in (select cssdl.loc,
                                      cssdl.origin_country_id,
                                      cssdl.supplier
                                 from cost_susp_sup_detail_loc cssdl
                                where cssdl.cost_change = I_cost_change)
      and iscbc.item in (select im.item
                           from item_master im
                          where exists (select 'x'
                                          from v_sim_seq_explode v
                                         where v.wh    = iscbc.location)
                            and im.item      = iscbc.item
                            and im.status    in ('W','S'));
cursor C_SELECT_WK_LOC_CC is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where (iscbc.location,
           iscbc.origin_country_id,
           iscbc.supplier) in (select cssdl.loc,
                                      cssdl.origin_country_id,
                                      cssdl.supplier
                                 from cost_susp_sup_detail_loc cssdl
                                where cssdl.cost_change = I_cost_change)
      and iscbc.item in (select im.item
                           from item_master im
                          where im.dept      = I_dept
                             or (I_dept       is NULL
                                 and not exists (select 'x'
                                                   from v_sim_seq_explode v
                                                  where v.dept = im.dept
                                                    and v.wh    = iscbc.location))
                            and im.item      = iscbc.item
                            and im.status    in ('W','S'))
      for update nowait;
cursor C_SELECT_CNTRY_WK is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where (iscbc.origin_country_id,
           iscbc.supplier) in (select cssdl.origin_country_id,
                                      cssdl.supplier
                                 from cost_susp_sup_detail_loc cssdl
                                where cssdl.cost_change = I_cost_change)
      and iscbc.item in (select im.item
                           from item_master im
                          where im.dept      = I_dept
                             or (I_dept       is NULL
                                and not exists (select 'x'
                                                  from v_sim_seq_explode v
                                                 where v.dept = im.dept))
                            and im.item      = iscbc.item
                            and im.status    in ('W','S'))
      and iscbc.location is NULL
      for update nowait;
cursor C_SELECT_CC is
    select 'x'
      from item_supp_country_bracket_cost iscbc
     where (iscbc.item,
            iscbc.origin_country_id,
            iscbc.supplier) in (select cssd.item,
                                       cssd.origin_country_id,
                                       cssd.supplier
                                  from cost_susp_sup_detail cssd
                                 where cssd.cost_change = I_cost_change)
       for update nowait;
cursor C_SELECT_WK_CC is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where (iscbc.origin_country_id,
           iscbc.supplier) in (select cssd.origin_country_id,
                                      cssd.supplier
                                 from cost_susp_sup_detail cssd
                                where cssd.cost_change = I_cost_change)
      and iscbc.item in (select im.item
                           from item_master im
                          where im.dept      = I_dept
                             or (I_dept       is NULL
                                 and not exists (select 'x'
                                                   from v_sim_seq_explode v
                                                  where v.dept = im.dept))
                            and im.item      = iscbc.item
                            and im.status    in ('W','S'))
      for update nowait;
--  This function will check to see if there are any worksheet items
--  For a supplier that undergoes a bracket change.  If there are,
--  Brackets will be inserted with a null cost for those items.
BEGIN
   --- NULL value validation
   if I_cost_change is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_cost_change',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc_ind is NULL or I_loc_ind not in ('Y','N') then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_cost_change',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   --- Find the correct sequence number from item_supp_country_bracket_cost
   if I_loc_ind = 'Y' then
      --- Check to see if the inv_mgmt level is 'S' or 'D' when the
      --- cost change as at the location level.  If it is, delete the country level
      --- brackets.
      if not SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                                 L_bracket_level,
                                                 I_supplier) then
         return FALSE;
      end if;
      --- Delete any country level brackets for a record on the COST_DETAIL_LOC table
      if L_bracket_level in ('S','D') then
         SQL_LIB.SET_MARK('OPEN','C_SELECT_CNTRY','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_SELECT_CNTRY;
         SQL_LIB.SET_MARK('CLOSE','C_SELECT_CNTRY','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_SELECT_CNTRY;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         delete from item_supp_country_bracket_cost iscbc
               where (iscbc.item,
                      iscbc.origin_country_id,
                      iscbc.supplier) in (select cssdl.item,
                                                 cssdl.origin_country_id,
                                                 cssdl.supplier
                                            from cost_susp_sup_detail_loc cssdl
                                           where cssdl.cost_change = I_cost_change)
                 and iscbc.location is NULL;
         SQL_LIB.SET_MARK('OPEN','C_SELECT_CNTRY_WK','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_SELECT_CNTRY_WK;
         SQL_LIB.SET_MARK('CLOSE','C_SELECT_CNTRY_WK','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_SELECT_CNTRY_WK;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         delete from item_supp_country_bracket_cost iscbc
               where (iscbc.origin_country_id,
                      iscbc.supplier) in (select cssdl.origin_country_id,
                                                 cssdl.supplier
                                            from cost_susp_sup_detail_loc cssdl
                                           where cssdl.cost_change = I_cost_change)
                 and iscbc.item in (select im.item
                                      from item_master im
                                     where im.dept      = I_dept
                                        or (I_dept      is NULL
                                            and not exists (select 'x'
                                                              from v_sim_seq_explode v
                                                             where v.dept     = im.dept))
                                       and im.item    = iscbc.item
                                       and im.status  in ('W','S'))
                 and iscbc.location is NULL;
      end if;   --- end if L_bracket_lvl in ('S','SD')
      SQL_LIB.SET_MARK('OPEN','C_SELECT_LOC_CC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      open C_SELECT_LOC_CC;
      SQL_LIB.SET_MARK('CLOSE','C_SELECT_LOC_CC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      close C_SELECT_LOC_CC;
      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      delete from item_supp_country_bracket_cost iscbc
            where (iscbc.item,
                   iscbc.location,
                   iscbc.origin_country_id,
                   iscbc.supplier) in (select cssdl.item,
                                              cssdl.loc,
                                              cssdl.origin_country_id,
                                              cssdl.supplier
                                         from cost_susp_sup_detail_loc cssdl
                                        where cssdl.cost_change = I_cost_change);
      --- Record is an S/L
      if L_bracket_level = 'L' then
         SQL_LIB.SET_MARK('OPEN','C_SELECT_WK_LOC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_SELECT_WK_LOC;
         SQL_LIB.SET_MARK('CLOSE','C_SELECT_WK_LOC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_SELECT_WK_LOC;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         delete from item_supp_country_bracket_cost iscbc
               where (iscbc.location,
                      iscbc.origin_country_id,
                      iscbc.supplier) in (select cssdl.loc,
                                                 cssdl.origin_country_id,
                                                 cssdl.supplier
                                            from cost_susp_sup_detail_loc cssdl
                                           where cssdl.cost_change = I_cost_change)
                 and iscbc.item in (select im.item
                                      from item_master im
                                     where exists (select 'x'
                                                     from v_sim_seq_explode v
                                                    where v.wh    = iscbc.location)
                                       and im.item      = iscbc.item
                                       and im.status    in ('W','S'));
      --- Record is an S/D/L
      else
         SQL_LIB.SET_MARK('OPEN','C_SELECT_WK_LOC_CC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_SELECT_WK_LOC_CC;
         SQL_LIB.SET_MARK('CLOSE','C_SELECT_WK_LOC_CC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_SELECT_WK_LOC_CC;
         SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         delete from item_supp_country_bracket_cost iscbc
               where (iscbc.location,
                      iscbc.origin_country_id,
                      iscbc.supplier) in (select cssdl.loc,
                                                 cssdl.origin_country_id,
                                                 cssdl.supplier
                                            from cost_susp_sup_detail_loc cssdl
                                           where cssdl.cost_change = I_cost_change)
                 and iscbc.item in (select im.item
                                      from item_master im
                                     where im.dept      = I_dept
                                       or (I_dept       is NULL
                                           and not exists (select 'x'
                                                              from v_sim_seq_explode v
                                                             where v.dept  = im.dept
                                                               and v.wh    = iscbc.location))
                                       and im.item      = iscbc.item
                                       and im.status    in ('W','S'));
      end if; --- if/else bracket level = 'L'
   --- Record is from COST_DETAIL (S or D level)
   else
      SQL_LIB.SET_MARK('OPEN','C_SELECT_CC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      open C_SELECT_CC;
      SQL_LIB.SET_MARK('CLOSE','C_SELECT_CC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      close C_SELECT_CC;
      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      delete from item_supp_country_bracket_cost iscbc
            where (iscbc.item,
                   iscbc.origin_country_id,
                   iscbc.supplier) in (select cssd.item,
                                              cssd.origin_country_id,
                                              cssd.supplier
                                         from cost_susp_sup_detail cssd
                                        where cssd.cost_change = I_cost_change);
      SQL_LIB.SET_MARK('OPEN','C_SELECT_WK_CC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      open C_SELECT_WK_CC;
      SQL_LIB.SET_MARK('CLOSE','C_SELECT_WK_CC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      close C_SELECT_WK_CC;
      SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      delete from item_supp_country_bracket_cost iscbc
            where (iscbc.origin_country_id,
                   iscbc.supplier) in (select cssd.origin_country_id,
                                              cssd.supplier
                                         from cost_susp_sup_detail cssd
                                        where cssd.cost_change = I_cost_change)
              and iscbc.item in (select im.item
                                   from item_master im
                                  where im.dept      = I_dept
                                     or (I_dept       is NULL
                                         and not exists (select 'x'
                                                           from v_sim_seq_explode v
                                                          where v.dept = im.dept))
                                    and im.item      = iscbc.item
                                    and im.status    in ('W','S'));
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_BRACKET;
--------------------------------------------------------------------------------------------------------------------------------
FUNCTION CHANGE_WORKSHEET_DEFAULT(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_bracket_value1 IN     SUP_BRACKET_COST.BRACKET_VALUE1%TYPE,
                                  I_supplier       IN     SUP_BRACKET_COST.SUPPLIER%TYPE,
                                  I_seq_no         IN     SUP_BRACKET_COST.SUP_DEPT_SEQ_NO%TYPE)
RETURN BOOLEAN IS
   L_program        VARCHAR2(60)  := 'COST_EXTRACT_SQL.CHANGE_WORKSHEET_DEFAULT';
   L_table          VARCHAR2(30)  := 'ITEM_SUPP_COUNTRY_BRACKET_COST';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);
   L_item_exist     BOOLEAN;
   L_items_approved BOOLEAN;
   L_return_code    VARCHAR2(5);
   cursor C_LOCK_ISCBC_N is
      select 'x'
        from item_supp_country_bracket_cost
       where sup_dept_seq_no = I_seq_no
         and bracket_value1 != I_bracket_value1
         and item in (select item
                        from item_master
                       where status in ('S','W'))
         for update nowait;
   cursor C_LOCK_ISCBC_Y is
      select 'x'
        from item_supp_country_bracket_cost
       where sup_dept_seq_no = I_seq_no
         and bracket_value1  = I_bracket_value1
         and item in (select item
                        from item_master
                       where status in ('S','W'))
         for update nowait;
   cursor C_GET_ITEMS is
      select distinct item,
                      origin_country_id,
                      location
        from item_supp_country_bracket_cost
       where sup_dept_seq_no = I_seq_no
         and location is not NULL
         and item in (select item
                        from item_master
                       where status in ('S','W'));
BEGIN
   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM',
                                           'I_seq_no',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;
   open C_LOCK_ISCBC_N;
   close C_LOCK_ISCBC_N;
   update item_supp_country_bracket_cost
      set default_bracket_ind = 'N'
    where sup_dept_seq_no     = I_seq_no
      and bracket_value1     != I_bracket_value1
      and item in (select item
                     from item_master
                    where status in ('S','W'));
   open C_LOCK_ISCBC_Y;
   close C_LOCK_ISCBC_Y;
   update item_supp_country_bracket_cost
      set default_bracket_ind = 'Y'
    where sup_dept_seq_no     = I_seq_no
      and bracket_value1      = I_bracket_value1
      and item in (select item
                     from item_master
                    where status in ('S','W'));
   for rec in C_GET_ITEMS LOOP
      if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                        rec.item,
                                                        I_supplier,
                                                        rec.origin_country_id,
                                                        rec.location,
                                                        'Y') then
         return FALSE;
      end if;
   END LOOP;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'Supplier: ' || to_char(I_supplier),
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CHANGE_WORKSHEET_DEFAULT;
--------------------------------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_BUYER_PACK(O_error_message   IN OUT    VARCHAR2,
                           I_item            IN        ITEM_MASTER.ITEM%TYPE) return BOOLEAN IS
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.UPDATE_BUYER_PACK';
L_pack                ITEM_MASTER.ITEM%TYPE;

--04-Oct-2011 Tesco HSC/Usha Patil           PrfNBS023365 Begin
--Changed item_supp_country_loc join to exists condition to improve performance.
cursor C_PACK is
   select distinct p.pack_no
      from packitem_breakout p,
           item_master im
      where im.pack_type           = 'B'
        and im.item              = p.pack_no
        and p.item                 = I_item
        and exists (select 1
                      from item_supp_country_loc iscl
                     where iscl.item = im.item)
UNION ALL
   select distinct p.pack_no
      from packitem_breakout p,
           item_master im
      where im.pack_type           = 'B'
        and im.item              = p.pack_no
        and p.item in (select im.item
                         from item_master im
                        where (im.item_parent          = I_item or
                               im.item_grandparent     = I_item)
                          and im.item_level             <= im.tran_level)
        and exists (select 1
                      from item_supp_country_loc iscl
                     where iscl.item = im.item);
--04-Oct-2011 Tesco HSC/Usha Patil           PrfNBS023365 End

BEGIN
   --- This function will update all packs with the new
   --- component costs if locations are specified.
   --- This function will check to see if any children items are in
   --- a pack. If they are, Build the pack with the new children item
   --- costs.  Update the costs on ITEM_SUPP_COUNTRY_LOC and ITEM_SUPP_COUNTRY
   --- for the new pack cost.
   --- Check for not null variables that are passed in
   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;
   --- Loop through all packs that the passed in item is contained in.
   SQL_LIB.SET_MARK('FETCH','C_PACK','PACKITEM',NULL);
   FOR rec in C_PACK
   LOOP
      L_pack           := rec.pack_no;
      --- Build the new pack cost from the updated item costs.
      --- This function will return the new pack cost to be used when updating
      --- and approved orders with pack costs.
      --- Update pack cost on ITEM_SUPP_COUNTRY_LOC for the passed in location.
      --- If the item is at the primary location, then the unit cost for the pack
      --- will be updated on ITEM_SUPP_COUNTRY.
      if not PACKITEM_ADD_SQL.UPDATE_SUPP_COST(O_error_message,
                                               L_pack) then
         return FALSE;
      end if;
   END LOOP;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_BUYER_PACK;
-----------------------------------------------------------------------------------------------
FUNCTION INSERT_WKSHT_CNTRY_BRACKET(O_error_message   IN OUT    VARCHAR2,
                                    I_seq_no          IN        COST_SUSP_SUP_DETAIL_LOC.SUP_DEPT_SEQ_NO%TYPE,
                                    I_supplier        IN        COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE,
                                    I_bracket_value1  IN        COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE1%TYPE,
                                    I_bracket_value2  IN        COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE2%TYPE,
                                    I_default_ind     IN        COST_SUSP_SUP_DETAIL_LOC.DEFAULT_BRACKET_IND%TYPE,
                                    I_dept            IN        COST_SUSP_SUP_DETAIL_LOC.DEPT%TYPE,
                                    I_country         IN        COST_SUSP_SUP_DETAIL_LOC.ORIGIN_COUNTRY_ID%TYPE) return BOOLEAN is
L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.INSERT_WKSHT_CNTRY_BRACKET';
L_table               VARCHAR2(64) := 'COST_EXTRACT_SQL';
L_all_loc             ITEM_LOC.LOC%TYPE;
cursor C_LOCK_ISCBC is
   select 'x'
     from item_supp_country_bracket_cost iscbc
    where iscbc.bracket_value1   != I_bracket_value1
      and iscbc.supplier          = I_supplier
      and iscbc.origin_country_id = I_country
      and item in (select im1.item
                     from item_master im1
                    where im1.status in ('S','W')
                      and (im1.pack_type not in ('B') or
                           im1.pack_type is NULL))
      and (exists (select 'x'
                     from item_master im
                    where im.dept = I_dept
                      and im.item = iscbc.item
                      and im.status in ('W','S')
                      and (im.pack_type not in ('B') or
                           im.pack_type is NULL))
                       or (I_dept is NULL
                           and exists (select 'x'
                                         from v_sim_seq_explode v,
                                              item_master im
                                        where v.sup_dept_seq_no = I_seq_no
                                          and v.dept            = im.dept
                                          and im.item           = iscbc.item
                                          and im.status         in ('W','S')
                                          and (im.pack_type not in ('B') or
                                               im.pack_type is NULL))))
      for update nowait;
--  This function will check to see if there are any worksheet items
--  For a supplier that undergoes a bracket change.  If there are,
--  Brackets will be inserted with a null cost for those items.
BEGIN
   --- NULL value validation
   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_seq_no',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_country is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_country',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_bracket_value1 is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_bracket_value1',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_default_ind is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_default_ind',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
      --- In cases in which brackets were added and the new bracket became a
      --- new default bracket
      if I_default_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         open C_LOCK_ISCBC;
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         close C_LOCK_ISCBC;
         SQL_LIB.SET_MARK('UPDATE', 'C_LOCK_ISCBC', 'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
         update item_supp_country_bracket_cost iscbc
            set iscbc.default_bracket_ind = 'N'
          where iscbc.bracket_value1   != I_bracket_value1
            and iscbc.supplier          = I_supplier
            and iscbc.origin_country_id = I_country
            and item in (select im1.item
                           from item_master im1
                          where im1.status in ('S','W')
                            and (im1.pack_type not in ('B') or
                                 im1.pack_type is NULL))
            and (exists (select 'x'
                           from item_master im
                          where im.dept = I_dept
                            and im.item = iscbc.item
                            and im.status in ('W','S')
                            and (im.pack_type not in ('B') or
                                 im.pack_type is NULL))
             or (I_dept is NULL
                 and exists (select 'x'
                               from v_sim_seq_explode v,
                                    item_master im
                              where v.sup_dept_seq_no = I_seq_no
                                and v.dept            = im.dept
                                and im.item           = iscbc.item
                                 and im.status         in ('W','S')
                                 and (im.pack_type not in ('B') or
                                      im.pack_type is NULL))));
      end if;  --- end if I_default_ind = 'Y'
      SQL_LIB.SET_MARK('INSERT',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST','Supplier: '|| to_char(I_supplier)
                       || 'Department: '|| to_char(I_dept) || 'Primary Bracket Value: '|| to_char(I_bracket_value1)
                       || 'Secondary Bracket Value: '|| to_char(I_bracket_value2));
      insert into item_supp_country_bracket_cost(item,
                                                 sup_dept_seq_no,
                                                 supplier,
                                                 origin_country_id,
                                                 location,
                                                 loc_type,
                                                 default_bracket_ind,
                                                 bracket_value1,
                                                 bracket_value2,
                                                 unit_cost)
                                          select isc.item,
                                                 I_seq_no,
                                                 I_supplier,
                                                 I_country,
                                                 NULL,
                                                 NULL,
                                                 I_default_ind,
                                                 I_bracket_value1,
                                                 I_bracket_value2,
                                                 NULL
                                            from item_supp_country isc
                                           where isc.supplier          = I_supplier
                                             and isc.origin_country_id = I_country
                                             and item in (select im1.item
                                                            from item_master im1
                                                           where im1.status in ('S','W')
                                                             and (im1.pack_type not in ('B') or
                                                                  im1.pack_type is NULL))
                                             and (exists (select 'x'
                                                            from item_master im
                                                           where im.dept = I_dept
                                                             and im.item = isc.item
                                                             and im.status in ('W','S')
                                                             and (im.pack_type not in ('B') or
                                                                  im.pack_type is NULL))
                                              or (I_dept is NULL
                                                  and exists (select 'x'
                                                                from v_sim_seq_explode v,
                                                                     item_master im
                                                               where v.sup_dept_seq_no = I_seq_no
                                                                 and v.dept            = im.dept
                                                                 and im.item           = isc.item
                                                                 and im.status         in ('W','S')
                                                                 and (im.pack_type not in ('B') or
                                                                      im.pack_type is NULL))));
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_WKSHT_CNTRY_BRACKET;
--------------------------------------------------------------------------------------------------------------
 FUNCTION CALCULATE_UNIT_COST      (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                    O_unit_cost_new   IN OUT   TYP_UNIT_COST,
                                    L_item_tbl        IN OUT   TYP_ITEM,
                                    I_supplier        IN       SUPS.SUPPLIER%TYPE,
                                    I_origin_country  IN       COUNTRY.COUNTRY_ID%TYPE,
                                    I_bracket_value1  IN       COST_SUSP_SUP_DETAIL.BRACKET_VALUE1%TYPE,
                                    I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                    I_change_type     IN       COST_SUSP_SUP_DETAIL.COST_CHANGE_TYPE%TYPE,
                                    I_change_amount   IN       COST_SUSP_SUP_DETAIL.COST_CHANGE_VALUE%TYPE)
   RETURN BOOLEAN IS

   TYPE supplier_tbl              is TABLE OF NUMBER(10)     INDEX BY BINARY_INTEGER;
   TYPE country_tbl               is TABLE OF VARCHAR2(3)    INDEX BY BINARY_INTEGER;
   TYPE converted_cost_tbl        is TABLE OF NUMBER(20,4)   INDEX BY BINARY_INTEGER;
   TYPE unit_cost_cuom_new_tbl    is TABLE OF NUMBER(20,4)   INDEX BY BINARY_INTEGER;

   L_program                    VARCHAR2(255) :='CALCULATE_UNIT_COST';
   L_supplier_tbl               SUPPLIER_TBL;
   L_country_tbl                COUNTRY_TBL;
   L_unit_cost_tbl              TYP_UNIT_COST;
   L_converted_cost_tbl         CONVERTED_COST_TBL;
   L_unit_cost_cuom_new_tbl     UNIT_COST_CUOM_NEW_TBL;

   NEGATIVE_AMOUNT       EXCEPTION;

   cursor C_NO_BRACKET_COST is
      select isc.supplier,
             isc.origin_country_id,
             isc.item,
             isc.unit_cost
        from item_supp_country isc,
             sups s,
             v_item_master im,
             item_supplier isp
       where isc.supplier          = s.supplier
         and isc.supplier          = NVL(I_supplier, isc.supplier)
         and isc.supplier          = isp.supplier
         and isc.item              = im.item
         and isc.item              = isp.item
         and (im.item_parent       = I_item   or
              im.item_grandparent  = I_item  )
         and s.bracket_costing_ind = 'N'
         and im.item_level        <= im.tran_level
         and (im.pack_ind          = 'N'   or
             (im.pack_ind           = 'Y' and im.pack_type = 'V'))
         and im.status             = 'A'
         and isc.origin_country_id = NVL(I_origin_country, isc.origin_country_id);


   cursor C_SUPP_DEPT_LEVEL_BRACKETS is
      select iscbc.supplier,
             iscbc.origin_country_id,
             iscbc.item,
             iscbc.unit_cost
        from sups s,
             item_supp_country_bracket_cost iscbc,
             v_item_master im,
             item_supp_country isc,
             item_supplier isp
       where s.supplier               = iscbc.supplier
         and iscbc.supplier           = NVL(I_supplier, iscbc.supplier)
         and iscbc.supplier           = isc.supplier
         and iscbc.supplier           = isp.supplier
         and iscbc.bracket_value1     = I_bracket_value1
         and iscbc.item               = im.item
         and iscbc.item               = isc.item
         and iscbc.item               = isp.item
         and (im.item_parent          = I_item  or
              im.item_grandparent     = I_item)
         and s.bracket_costing_ind    = 'Y'
         and s.inv_mgmt_lvl           in ('S', 'D')
         and iscbc.location           is NULL
         and im.item_level           <= im.tran_level
         and (im.pack_ind             = 'N'   or
             (im.pack_ind             = 'Y' and im.pack_type = 'V'))
         and im.status                = 'A'
         and iscbc.origin_country_id  = NVL(I_origin_country, iscbc.origin_country_id);


BEGIN

   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_origin_country is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_origin_country',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_NO_BRACKET_COST',
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item,NULL);
   open C_NO_BRACKET_COST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_NO_BRACKET_COST',
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item,NULL);
   fetch C_NO_BRACKET_COST BULK COLLECT into L_supplier_tbl,
                                             L_country_tbl,
                                             L_item_tbl,
                                             L_unit_cost_tbl;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_NO_BRACKET_COST',
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item,NULL);
   close C_NO_BRACKET_COST;
   if L_item_tbl.first is NOT NULL then
      FOR i in L_item_tbl.first..L_item_tbl.last LOOP
         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_unit_cost_tbl(i),
                                               L_item_tbl(i),
                                               L_supplier_tbl(i),
                                               L_country_tbl(i),
                                               'S',
                                               NULL) = FALSE then
            return FALSE;
         end if;
         L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
         if I_change_type = 'P' then
            L_unit_cost_cuom_new_tbl(i) := L_converted_cost_tbl(i) * (1 + I_change_amount/100);

         elsif I_change_type = 'A' then
               L_unit_cost_cuom_new_tbl(i)  := L_converted_cost_tbl(i)+ I_change_amount;

         elsif I_change_type = 'F' then
               L_unit_cost_cuom_new_tbl(i) := I_change_amount;
         end if;
         if (L_unit_cost_cuom_new_tbl(i) < 0) then
             raise NEGATIVE_AMOUNT;
         end if;
         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_unit_cost_cuom_new_tbl(i),
                                               L_item_tbl(i),
                                               L_supplier_tbl(i),
                                               L_country_tbl(i),
                                               'C') = FALSE then
            return FALSE;
         end if;
        O_unit_cost_new(i)     := L_unit_cost_cuom_new_tbl(i);
      END LOOP;
   else
      if I_bracket_value1 is NULL then
         O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_bracket_value1',
                                           'NULL', 'NOT NULL');
          RETURN FALSE;
      end if;
      SQL_LIB.SET_MARK('OPEN',
                       'C_SUPP_DEPT_LEVEL_BRACKETS',
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item||' Bracket_value1: '||to_char(I_bracket_value1),NULL);
      open C_SUPP_DEPT_LEVEL_BRACKETS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_SUPP_DEPT_LEVEL_BRACKETS',
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item||' Bracket_value1: '||to_char(I_bracket_value1),NULL);
      fetch C_SUPP_DEPT_LEVEL_BRACKETS BULK COLLECT into L_supplier_tbl,
                                                         L_country_tbl,
                                                         L_item_tbl,
                                                         L_unit_cost_tbl;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_SUPP_DEPT_LEVEL_BRACKETS',
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item||' Bracket_value1: '||to_char(I_bracket_value1),NULL);
      close C_SUPP_DEPT_LEVEL_BRACKETS;
      if L_item_tbl.first is NOT NULL then
         FOR i in L_item_tbl.first..L_item_tbl.last LOOP
            if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                  L_unit_cost_tbl(i),
                                                  L_item_tbl(i),
                                                  L_supplier_tbl(i),
                                                  L_country_tbl(i),
                                                  'S',
                                                  NULL) = FALSE then
               return FALSE;
            end if;
            L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
            if I_change_type = 'P' then
               L_unit_cost_cuom_new_tbl(i) := L_converted_cost_tbl(i) * (1 + I_change_amount/100);

            elsif I_change_type = 'A' then
                  L_unit_cost_cuom_new_tbl(i)  := L_converted_cost_tbl(i)+ I_change_amount;

            elsif I_change_type = 'F' then
                  L_unit_cost_cuom_new_tbl(i) := I_change_amount;

            end if;

            if (L_unit_cost_cuom_new_tbl(i) < 0) then
                raise NEGATIVE_AMOUNT;
            end if;


            if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                  L_unit_cost_cuom_new_tbl(i),
                                                  L_item_tbl(i),
                                                  L_supplier_tbl(i),
                                                  L_country_tbl(i),
                                                  'C') = FALSE then
                return FALSE;
            end if;
            O_unit_cost_new(i)     := L_unit_cost_cuom_new_tbl(i);
         END LOOP;
      end if;
   end if;
   return TRUE;
EXCEPTION
   when NEGATIVE_AMOUNT then
      O_error_message := SQL_LIB.CREATE_MSG('U/P_COST_NOT_NEG',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CALCULATE_UNIT_COST;
--------------------------------------------------------------------------------------------------------------
FUNCTION CALCULATE_LOC_UNIT_COST (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_unit_cost_new    IN OUT   TYP_UNIT_COST,
                                  L_item_tbl         IN OUT   TYP_ITEM,
                                  I_supplier         IN       SUPS.SUPPLIER%TYPE,
                                  I_origin_country   IN       COUNTRY.COUNTRY_ID%TYPE,
                                  I_bracket_value1   IN       COST_SUSP_SUP_DETAIL.BRACKET_VALUE1%TYPE,
                                  I_item             IN       ITEM_MASTER.ITEM%TYPE,
                                  I_loc              IN       COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE,
                                  I_change_type      IN       COST_SUSP_SUP_DETAIL.COST_CHANGE_TYPE%TYPE,
                                  I_change_amount    IN       COST_SUSP_SUP_DETAIL.COST_CHANGE_VALUE%TYPE)
  RETURN BOOLEAN IS


   TYPE supplier_tbl              is TABLE OF NUMBER(10)   INDEX BY BINARY_INTEGER;
   TYPE country_tbl               is TABLE OF VARCHAR2(3)  INDEX BY BINARY_INTEGER;
   TYPE converted_cost_tbl        is TABLE OF NUMBER(20,4) INDEX BY BINARY_INTEGER;
   TYPE unit_cost_cuom_new_tbl    is TABLE OF NUMBER(20,4) INDEX BY BINARY_INTEGER;


   L_supplier_tbl               SUPPLIER_TBL;
   L_country_tbl                COUNTRY_TBL;
   L_unit_cost_tbl              TYP_UNIT_COST;
   L_converted_cost_tbl         CONVERTED_COST_TBL;
   L_unit_cost_cuom_new_tbl     UNIT_COST_CUOM_NEW_TBL;


    L_program             VARCHAR2(255):='CALCULATE_LOC_UNIT_COST';
    NEGATIVE_AMOUNT       EXCEPTION;


   cursor C_FIRST_INSERT is
      select iscl.supplier,
             iscl.origin_country_id,
             iscl.item,
             iscl.unit_cost
        from item_supp_country_loc iscl,
             v_item_master im,
             item_supplier isp,
             item_supp_country isc
       where iscl.loc_type          = 'S'
         and iscl.origin_country_id = I_origin_country
         and iscl.supplier          = I_supplier
         and (im.item_parent        = I_item or
              im.item_grandparent   = I_item )
         and im.item_level<= im.tran_level
         and iscl.item              = im.item
         and im.status              = 'A'
         and iscl.supplier          = isp.supplier
         and iscl.supplier          = isc.supplier
         and iscl.item              = isp.item
         and iscl.item              = isc.item
         and iscl.origin_country_id = isc.origin_country_id
         and iscl.loc               = I_loc
         and iscl.loc in (select store
                             from v_store
                            where iscl.loc = store);
   cursor C_SECOND_INSERT is
      select distinct iscl.supplier,
                      iscl.origin_country_id,
                      iscl.item,
                      iscl.unit_cost
                 from v_wh w,
                      item_supp_country_loc iscl,
                      sups s,
                      v_item_master im,
                      item_supplier isp,
                      item_supp_country isc
                where s.supplier             = iscl.supplier
                  and s.bracket_costing_ind  = 'N'
                  and iscl.loc               = I_loc
                  and iscl.loc               = w.wh
                  and iscl.loc_type          = 'W'
                  and iscl.origin_country_id = I_origin_country
                  and iscl.supplier          = I_supplier
                  and (im.item_parent        = I_item  or
                       im.item_grandparent    = I_item )
                  and im.item_level<= im.tran_level
                  and iscl.item              = im.item
                  and im.status              = 'A'
                  and iscl.supplier          = isp.supplier
                  and iscl.supplier          = isc.supplier
                  and iscl.item              = isp.item
                  and iscl.item              = isc.item
                  and iscl.origin_country_id = isc.origin_country_id;

   cursor C_THIRD_INSERT is
      select distinct iscbc.supplier,
                      iscbc.origin_country_id,
                      iscbc.item,
                      iscbc.unit_cost
                 from v_wh w,
                      item_supp_country_bracket_cost iscbc,
                      v_item_master im,
                      item_supplier isp,
                      item_supp_country isc
                where iscbc.location          = w.wh
                  and iscbc.location          = I_loc
                  and iscbc.loc_type          = 'W'
                  and iscbc.origin_country_id = I_origin_country
                  and iscbc.supplier          = I_supplier
                  and iscbc.bracket_value1    = I_bracket_value1
                  and (im.item_parent         = I_item  or
                       im.item_grandparent    = I_item )
                  and im.item_level<= im.tran_level
                  and iscbc.item              = im.item
                  and im.status               = 'A'
                  and iscbc.supplier          = isp.supplier
                  and iscbc.supplier          = isc.supplier
                  and iscbc.item              = isp.item
                  and iscbc.item              = isc.item
                  and iscbc.origin_country_id = isc.origin_country_id;



BEGIN
   if I_item is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_item',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_supplier',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   if I_origin_country is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_origin_country',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;
   if I_loc is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_loc',
                                           'NULL', 'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_FIRST_INSERT',
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item||' Location: '||to_char(I_loc),NULL);
   open C_FIRST_INSERT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_FIRST_INSERT',
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item||' Location: '||to_char(I_loc),NULL);
   fetch C_FIRST_INSERT BULK COLLECT into L_supplier_tbl,
                                          L_country_tbl,
                                          L_item_tbl,
                                          L_unit_cost_tbl;


   SQL_LIB.SET_MARK('CLOSE',
                    'C_FIRST_INSERT',
                    ' Supplier: '||to_char(I_supplier)||
                    ' Origin Country: '||I_origin_country||
                    ' Item: '||I_item||' Location: '||to_char(I_loc),NULL);
   close C_FIRST_INSERT;

   if L_item_tbl.first is NOT NULL then
      FOR i in L_item_tbl.first..L_item_tbl.last LOOP
         if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                               L_unit_cost_tbl(i),
                                               L_item_tbl(i),
                                               L_supplier_tbl(i),
                                               L_country_tbl(i),
                                               'S',
                                               NULL) = FALSE then
                  return FALSE;
          end if;
          L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
          if I_change_type = 'P' then
             L_unit_cost_cuom_new_tbl(i) := L_converted_cost_tbl(i) * (1 + I_change_amount/100);

          elsif I_change_type = 'A' then
                L_unit_cost_cuom_new_tbl(i)  := L_converted_cost_tbl(i)+ I_change_amount;

          elsif I_change_type = 'F' then
                L_unit_cost_cuom_new_tbl(i) := I_change_amount;

          end if;

          if (L_unit_cost_cuom_new_tbl(i) < 0) then
             raise NEGATIVE_AMOUNT;
          end if;
          if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                L_unit_cost_cuom_new_tbl(i),
                                                L_item_tbl(i),
                                                L_supplier_tbl(i),
                                                L_country_tbl(i),
                                                'C') = FALSE then
             return FALSE;
          end if;
          O_unit_cost_new(i)     := L_unit_cost_cuom_new_tbl(i);
      END LOOP;
   else
   ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_SECOND_INSERT',
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item ||' Location: '||to_char(I_loc),NULL);
      open C_SECOND_INSERT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_SECOND_INSERT',
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item||' Location: '||to_char(I_loc),NULL);
      fetch C_SECOND_INSERT BULK COLLECT into L_supplier_tbl,
                                              L_country_tbl,
                                              L_item_tbl,
                                              L_unit_cost_tbl;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_SECOND_INSERT',
                       ' Supplier: '||to_char(I_supplier)||
                       ' Origin Country: '||I_origin_country||
                       ' Item: '||I_item||' Location: '||to_char(I_loc),NULL);
      close C_SECOND_INSERT;
        if L_item_tbl.first is NOT NULL then
            FOR i in L_item_tbl.first..L_item_tbl.last LOOP
               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_tbl(i),
                                                     L_item_tbl(i),
                                                     L_supplier_tbl(i),
                                                     L_country_tbl(i),
                                                     'S',
                                                     NULL) = FALSE then
                  return FALSE;
               end if;
               L_converted_cost_tbl(i):= L_unit_cost_tbl(i);

               if I_change_type = 'P' then
                  L_unit_cost_cuom_new_tbl(i) := L_converted_cost_tbl(i) * (1 + I_change_amount/100);

               elsif I_change_type = 'A' then
                     L_unit_cost_cuom_new_tbl(i)  := L_converted_cost_tbl(i)+ I_change_amount;

               elsif I_change_type = 'F' then
                     L_unit_cost_cuom_new_tbl(i) := I_change_amount;

               end if;

               if (L_unit_cost_cuom_new_tbl(i) < 0) then
                   raise NEGATIVE_AMOUNT;
               end if;

               if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                     L_unit_cost_cuom_new_tbl(i),
                                                     L_item_tbl(i),
                                                     L_supplier_tbl(i),
                                                     L_country_tbl(i),
                                                     'C') = FALSE then
                  return FALSE;
               end if;
               O_unit_cost_new(i)     := L_unit_cost_cuom_new_tbl(i);
            END LOOP;
        else
         ---
            if I_bracket_value1 is NULL then
               O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_bracket_value1',
                                                     'NULL', 'NOT NULL');
               RETURN FALSE;
            end if;
            SQL_LIB.SET_MARK('OPEN',
                             'C_THIRD_INSERT',
                             ' Supplier: '||to_char(I_supplier)||
                             ' Origin Country: '||I_origin_country||
                             ' Item: '||I_item||' Location: '||to_char(I_loc)||' Bracket_value1: '||to_char(I_bracket_value1),NULL);
            open C_THIRD_INSERT;

            SQL_LIB.SET_MARK('FETCH',
                             'C_THIRD_INSERT',
                             ' Supplier: '||to_char(I_supplier)||
                             ' Origin Country: '||I_origin_country||
                             ' Item: '||I_item||' Location: '||to_char(I_loc)||' Bracket_value1: '||to_char(I_bracket_value1),NULL);
            fetch C_THIRD_INSERT BULK COLLECT into L_supplier_tbl,
                                                   L_country_tbl,
                                                   L_item_tbl,
                                                   L_unit_cost_tbl;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_THIRD_INSERT',
                             ' Supplier: '||to_char(I_supplier)||
                             ' Origin Country: '||I_origin_country||
                             ' Item: '||I_item||' Location: '||to_char(I_loc)||' Bracket_value1: '||to_char(I_bracket_value1),NULL);
            close C_THIRD_INSERT;

            if L_item_tbl.first is NOT NULL then
               FOR i in L_item_tbl.first..L_item_tbl.last LOOP
                  if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                        L_unit_cost_tbl(i),
                                                        L_item_tbl(i),
                                                        L_supplier_tbl(i),
                                                        L_country_tbl(i),
                                                        'S',
                                                         NULL) = FALSE then
                     return FALSE;
                  end if;
                  L_converted_cost_tbl(i):= L_unit_cost_tbl(i);
                  if I_change_type = 'P' then
                     L_unit_cost_cuom_new_tbl(i) := L_converted_cost_tbl(i) * (1 + I_change_amount/100);

                  elsif I_change_type = 'A' then
                        L_unit_cost_cuom_new_tbl(i)  := L_converted_cost_tbl(i)+ I_change_amount;

                  elsif I_change_type = 'F' then
                        L_unit_cost_cuom_new_tbl(i) := I_change_amount;
                  end if;
                  if (L_unit_cost_cuom_new_tbl(i) < 0) then
                      raise NEGATIVE_AMOUNT;
                  end if;
                  if ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                        L_unit_cost_cuom_new_tbl(i),
                                                        L_item_tbl(i),
                                                        L_supplier_tbl(i),
                                                        L_country_tbl(i),
                                                        'C') = FALSE then
                     return FALSE;
                  end if;
                  O_unit_cost_new(i)     := L_unit_cost_cuom_new_tbl(i);
               END LOOP;
            end if;
        end if;
   end if;
   return TRUE;
EXCEPTION
   when NEGATIVE_AMOUNT then
      O_error_message := SQL_LIB.CREATE_MSG('U/P_COST_NOT_NEG',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
 END CALCULATE_LOC_UNIT_COST;
--------------------------------------------------------------------------------------------------------------
FUNCTION BULK_UPDATE_COSTS(O_error_message   IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                           I_cost_change     IN        COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                           I_cost_reason     IN        COST_SUSP_SUP_HEAD.REASON%TYPE)
   return BOOLEAN IS

   L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.BULK_UPDATE_COSTS';
   L_cost_found          VARCHAR2(1);

BEGIN


   if LP_elc_ind IS NULL then
     if NOT SYSTEM_OPTIONS_SQL.GET_ELC_IND(O_error_message,
                                           LP_elc_ind) then
         return FALSE;
     end if;
   end if;

   if LP_std_av_ind is NULL then
      if NOT SYSTEM_OPTIONS_SQL.STD_AV_IND(O_error_message,
                                           LP_std_av_ind) then
         return FALSE;
      end if;
   end if;

   if LP_prim_curr is NULL then
      if NOT SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                               LP_prim_curr) then
         return FALSE;
      end if;
   end if;

   if I_cost_reason = 1 or I_cost_reason = 2 then
      if NOT COST_EXTRACT_SQL.INSERT_BRACKET_LOC(O_error_message,
                                                 I_cost_change,
                                                 I_cost_reason,
                                                 L_cost_found) then
         return FALSE;
      end if;
      if NOT COST_EXTRACT_SQL.INSERT_BRACKET(O_error_message,
                                             I_cost_change,
                                             I_cost_reason,
                                             L_cost_found) then
         return FALSE;
      end if;
   else
      if NOT PROCESS_DETAIL_LOC(O_error_message,
                                I_cost_change,
                                I_cost_reason) then
         return FALSE;
      end if;
      if NOT PROCESS_DETAILS(O_error_message,
                             I_cost_change,
                             I_cost_reason) then
         return FALSE;
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
END BULK_UPDATE_COSTS;
--------------------------------------------------------------------------------------------------
FUNCTION PROCESS_DETAIL_LOC(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            I_cost_change      IN       COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                            I_cost_reason      IN       COST_SUSP_SUP_HEAD.REASON%TYPE)
   return BOOLEAN IS

   L_program                      VARCHAR2(64) := 'COST_EXTRACT_SQL.PROCESS_DETAIL_LOC';
   L_table                        VARCHAR2(64) := NULL;

   -- Scalar variables
   L_update_child                 VARCHAR2(1) := 'N';
   L_upd_recalc_ind               VARCHAR2(1) := 'N';

   L_prev_isc_rowid               ROWID;
   L_prev_isc_prim_rowid          ROWID;

   L_local_cost                   ITEM_LOC_SOH.UNIT_COST%TYPE                     := NULL;
   L_child_unit_cost              ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_total_cost                   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE                := 0;

   L_prev_chld_item               COST_SUSP_SUP_DETAIL_LOC.ITEM%TYPE              := NULL;
   L_prev_chld_supplier           COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE          := NULL;
   L_prev_chld_cntry              COST_SUSP_SUP_DETAIL_LOC.ORIGIN_COUNTRY_ID%TYPE := NULL;
   L_prev_chld_loc                COST_SUSP_SUP_DETAIL_LOC.LOC%TYPE               := NULL;
   L_prev_sup_cost                COST_SUSP_SUP_DETAIL_LOC.UNIT_COST%TYPE         := NULL;
   L_prev_item                    COST_SUSP_SUP_DETAIL_LOC.ITEM%TYPE              := NULL;
   L_prev_wksht_supplier          COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE          := NULL;
   L_prev_wksht_bracket_value     COST_SUSP_SUP_DETAIL_LOC.BRACKET_VALUE1%TYPE    := NULL;
   L_prev_wksht_seq_no            COST_SUSP_SUP_DETAIL_LOC.SUP_DEPT_SEQ_NO%TYPE   := NULL;
   L_prev_loc_brkt_item           COST_SUSP_SUP_DETAIL_LOC.ITEM%TYPE              := NULL;
   L_prev_loc_brkt_sup            COST_SUSP_SUP_DETAIL_LOC.SUPPLIER%TYPE          := NULL;
   L_prev_loc_brkt_cntry          COST_SUSP_SUP_DETAIL_LOC.ORIGIN_COUNTRY_ID%TYPE := NULL;

   NEGATIVE_AMOUNT                EXCEPTION;

   -- Process collections

   -- For item_supp_country update
   TBL_upd_isc_rowid              TYP_ROWID;
   TBL_upd_isc_unit_cost          TYP_UNIT_COST;

   -- For item_supp_country_loc update
   TBL_upd_iscl_rowid             TYP_ROWID;
   TBL_upd_iscl_unit_cost         TYP_UNIT_COST;

   -- For price_hist insert
   TBL_ph_item                    TYP_ITEM;
   TBL_ph_loc                     TYP_LOC;
   TBL_ph_unit_cost               TYP_UNIT_COST;
   TBL_ph_unit_retail             TYP_UNIT_RETAIL;
   TBL_ph_loc_type                TYP_LOC_TYPE;

   -- For item_loc_soh update
   TBL_upd_ils_rowid              TYP_ROWID;
   TBL_upd_ils_unit_cost          TYP_UNIT_COST;

   -- For STKLEDGR_SQL.TRAN_DATA_INSERT call
   TBL_stk_item                   TYP_ITEM;
   TBL_stk_dept                   TYP_DEPT;
   TBL_stk_class                  TYP_CLASS;
   TBL_stk_subclass               TYP_SUBCLASS;
   TBL_stk_loc                    TYP_LOC;
   TBL_stk_loc_type               TYP_LOC_TYPE;
   TBL_stk_soh                    TYP_STOCK_ON_HAND;
   TBL_stk_total_cost             TYP_UNIT_COST;
   TBL_stk_old_cost               TYP_UNIT_COST;
   TBL_stk_local_cost             TYP_UNIT_COST;

   -- For update of item_supp_country for primary locations
   TBL_isc_prim_rowid             TYP_ROWID;
   TBL_isc_prim_unit_cost         TYP_UNIT_COST;

   -- For ELC calls
   TBL_elc_item                   TYP_ITEM;
   TBL_elc_supplier               TYP_SUPPLIER;
   TBL_elc_origin_country_id      TYP_ORIGIN_COUNTRY_ID;

   -- For Buyer pack processing
   TBL_buypk_item                 TYP_ITEM;

   -- For Order recalculation
   TBL_upd_ord_item               ITEM_TBL := ITEM_TBL();

   -- For Cost change worksheet call
   TBL_wksht_bracket1             TYP_BRACKET_VALUE;
   TBL_wksht_supplier             TYP_SUPPLIER;
   TBL_wksht_seq_no               TYP_SUP_DEPT_SEQ_NO;

   -- For item_supp_country_bracket_cost reset (reason 3)
   TBL_iscbc_reset_rowid          TYP_ROWID;

   -- For item_cupp_country_bracket_cost update
   TBL_upd_iscbc_rowid            TYP_ROWID;
   TBL_upd_iscbc_default_bracket  TYP_DEFAULT_BRACKET_IND;
   TBL_upd_iscbc_unit_cost        TYP_UNIT_COST;

   -- UPDATE location bracket
   TBL_upd_loc_brckt_item         TYP_ITEM;
   TBL_upd_loc_brckt_supplier     TYP_SUPPLIER;
   TBL_upd_loc_brckt_cntry        TYP_ORIGIN_COUNTRY_ID;

   -- Index for collections

   L_size_upd_isc                 NUMBER := 0;
   L_size_upd_iscl                NUMBER := 0;
   L_size_ph                      NUMBER := 0;
   L_size_upd_ils                 NUMBER := 0;
   L_size_stk                     NUMBER := 0;
   L_size_isc_prim                NUMBER := 0;
   L_size_elc                     NUMBER := 0;
   L_size_buypk                   NUMBER := 0;
   L_size_upd_ord                 NUMBER := 0;
   L_size_wksht                   NUMBER := 0;
   L_size_upd_iscbc               NUMBER := 0;
   L_size_upd_loc_brkt            NUMBER := 0;


   cursor C_DETAIL_LOC_NO_BRACKET is
      select c.item,
             c.supplier,
             c.origin_country_id,
             c.loc,
             c.loc_type,
             c.unit_cost,
             c.cost_change_type,
             c.cost_change_value,
             c.recalc_ord_ind,
             c.isc_rowid,
             c.isc_unit_cost,
             c.iscl_rowid,
             c.iscl_unit_cost,
             c.iscl_prim_loc_ind,
             il.unit_retail loc_retail,
             case
                when ils.primary_supp = c.supplier and
                     ils.primary_cntry = c.origin_country_id then
                   'Y'
                else
                   'N'
             end primary_ind,
             ils.rowid ils_rowid,
             NVL(ils.unit_cost, 0) loc_cost,
             NVL(ils.stock_on_hand, 0) + NVL(ils.pack_comp_soh, 0) +
                NVL(ils.in_transit_qty, 0) + NVL(ils.pack_comp_intran, 0) soh,
             c.dept,
             c.class,
             c.subclass,
             c.status,
             c.pack_ind,
             c.child_ind,
             c.tran_level_item_ind,
             c.sup_currency,
             c.loc_currency
        from cost_change_temp3 c,
             item_loc il,
             item_loc_soh ils
       where c.cost_change = I_cost_change
         and c.tran_level_item_ind = 'Y'
         and il.item = c.item
         and il.loc = c.loc
         and ils.item = c.item
         and ils.loc  = c.loc
       union all
      select c.item,
             c.supplier,
             c.origin_country_id,
             c.loc,
             c.loc_type,
             c.unit_cost,
             c.cost_change_type,
             c.cost_change_value,
             c.recalc_ord_ind,
             c.isc_rowid,
             c.isc_unit_cost,
             c.iscl_rowid,
             c.iscl_unit_cost,
             c.iscl_prim_loc_ind,
             il.unit_retail loc_retail,
             case
                when il.primary_supp = c.supplier and
                     il.primary_cntry = c.origin_country_id then
                   'Y'
                else
                   'N'
             end primary_ind,
             NULL ils_rowid,
             NULL loc_cost,
             NULL soh,
             c.dept,
             c.class,
             c.subclass,
             c.status,
             c.pack_ind,
             c.child_ind,
             c.tran_level_item_ind,
             c.sup_currency,
             c.loc_currency
        from cost_change_temp3 c,
             item_loc il
       where c.cost_change = I_cost_change
         and c.tran_level_item_ind = 'N'
         and il.item = c.item
         and il.loc = c.loc
       order by item,
                supplier,
                origin_country_id;

   cursor C_DETAIL_LOC_BRACKET is
      with csd as (select /*+ index(im pk_item_master) index(s pk_sups) */
                          d.cost_change,
                          im.item,
                          d.item dtl_item,
                          d.supplier,
                          d.origin_country_id,
                          d.loc,
                          d.loc_type,
                          d.bracket_value1,
                          d.bracket_value2,
                          d.unit_cost,
                          d.cost_change_type,
                          d.cost_change_value,
                          d.recalc_ord_ind,
                          d.default_bracket_ind,
                          d.sup_dept_seq_no,
                          d.dept,
                          'N' child_ind,
                          DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                          s.inv_mgmt_lvl
                     from cost_susp_sup_detail_loc d,
                          item_master im,
                          sups s
                    where d.cost_change = I_cost_change
                      and d.bracket_value1 is NOT NULL
                      and d.item = im.item
                      and (im.orderable_ind = 'Y'
                           or im.item_xform_ind = 'N')
                      and d.supplier = s.supplier),
            cm as (select c.*,
                          row_number()
                          over (partition by c.supplier,
                                             c.origin_country_id,
                                             c.loc,
                                             c.item
                                    order by c.child_ind) dtl_row
                    from (select *
                            from csd
                           union all
                          select csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.loc,
                                 csd.loc_type,
                                 csd.bracket_value1,
                                 csd.bracket_value2,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 csd.default_bracket_ind,
                                 csd.dept,
                                 csd.sup_dept_seq_no,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                                 csd.inv_mgmt_lvl
                            from csd,
                                 item_master im
                           where csd.item = im.item_parent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A'
                           union all
                          select /*+ ordered use_nl(csd im) */
                                 csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.loc,
                                 csd.loc_type,
                                 csd.bracket_value1,
                                 csd.bracket_value2,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 csd.default_bracket_ind,
                                 csd.dept,
                                 csd.sup_dept_seq_no,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                                 csd.inv_mgmt_lvl
                            from csd,
                                 item_master im
                           where csd.item = im.item_grandparent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A') c)
      select cm.item,
             cm.supplier,
             cm.origin_country_id,
             cm.loc,
             cm.bracket_value1,
             cm.bracket_value2,
             cm.unit_cost,
             cm.cost_change_type,
             cm.cost_change_value,
             cm.recalc_ord_ind,
             cm.default_bracket_ind,
             cm.dept,
             cm.sup_dept_seq_no,
             cm.child_ind,
             cm.tran_level_item_ind,
             iscbc.rowid iscbc_rowid,
             iscbc.unit_cost iscbc_unit_cost,
             cm.inv_mgmt_lvl
        from cm,
             item_supp_country_bracket_cost iscbc
       where cm.cost_change = I_cost_change
         and cm.dtl_row = 1
         and iscbc.item = cm.item
         and iscbc.supplier = cm.supplier
         and iscbc.origin_country_id = cm.origin_country_id
         and iscbc.location = cm.loc
         and iscbc.bracket_value1 = cm.bracket_value1
       order by cm.item,
                cm.supplier,
                cm.origin_country_id;

   cursor C_RESET_BRACKET is
      select iscbc.rowid
        from cost_susp_sup_detail_loc csdl,
             item_supp_country_bracket_cost iscbc,
             item_master im
       where csdl.cost_change = I_cost_change
         and csdl.bracket_value1 is NOT NULL
         and ((csdl.item = im.item and
               (im.orderable_ind = 'Y'
                or im.item_xform_ind = 'N')) or
              ((csdl.item = im.item_parent or
                csdl.item = im.item_grandparent) and
               (im.item_level <= im.tran_level) and
               (im.pack_ind = 'N' or
                (im.pack_ind = 'Y' and
                 im.pack_type = 'V')) and
               im.status = 'A'))
         and iscbc.item = im.item
         and iscbc.supplier = csdl.supplier
         and iscbc.origin_country_id = csdl.origin_country_id
         and iscbc.location = csdl.loc
         and csdl.bracket_value1 != iscbc.bracket_value1
         for update of iscbc.unit_cost nowait;

   -- Cursor Collections
   TYPE TYP_dtl_loc_no_brkt is TABLE of C_DETAIL_LOC_NO_BRACKET%ROWTYPE INDEX BY BINARY_INTEGER;
   TYPE TYP_dtl_loc_brkt    is TABLE of C_DETAIL_LOC_BRACKET%ROWTYPE    INDEX BY BINARY_INTEGER;

   TBL_dtl_loc_no_brkt    TYP_dtl_loc_no_brkt;
   TBL_dtl_loc_brkt       TYP_dtl_loc_brkt;

BEGIN
   --------------------------------------------------------------------------------
   -- Function Overview:
   --
   --    To maximize performance, cost_change_temp3 (global temporary table) is filled
   --    with records from cost_susp_sup_detail_loc, the corresponding child records
   --    from item_master if there are parent items under cost change, the
   --    corresponding information from item_supp_country, item_supp_country_loc, and
   --    the location currency codes from store and wh tables.
   --
   --       Note: The insert-select to the cost_change_temp3 table uses the "WITH"
   --             clause to simplify the cost_susp_sup_detail_loc + item_master
   --             (child recs).
   --
   --             To understand the query, start with the "WITH" clause. CSD represents
   --             the select statement after it. This select statement is the query
   --             to cost_susp_sup_detail_loc for all orderable items.
   --
   --             Next is the CM which uses the CSD representation. In CM, start with
   --             the innermost union-select statements. The first union set grabs all
   --             the information from CSD. This is basically the items in the cost_susp_
   --             detail_loc table. The second union set joins CSD to item_master to get
   --             the child records for items in CSD (or cost_susp_sup_detail_loc). The
   --             third union set returns grandchildren records for items in CSD.
   --
   --             Problem arises when both parent and child records having different cost
   --             change values are in the cost_sups_sup_detail_loc. The union sets will
   --             return redundant child records, one having the cost_change value from the
   --             cost_susp_sup_detail_loc table and the other inheriting the parent
   --             cost_change value. To resolve the issue without sacrificing performance,
   --             an analytic function (row_number) is used. With this, the resulting set
   --             will have dtl_row = 1 for regular items, parent items, and child items
   --             in the cost_susp_sup_detail_loc or child items queried by the union set
   --             that are not in the cost_susp_sup_detail_loc. The result set will also
   --             have dtl_row = 2 for child items queried by the union set but are in the
   --             cost_susp_sup_detail_loc. The result set is filtered to return only dtl_row
   --             = 1 in the main query
   --
   --             CM is used for the main query after the "WITH" clause. This is joined
   --             with item_supp_country, item_supp_country, sups and the union of store +
   --             wh tables to get the necessary information (rowids, supplier costs etc).
   --             The resulting set is then inserted to cost_change_temp3 and the values
   --
   --   Next is to fill the cursor collection from the C_DETAIL_LOC_NO_BRACKET cursor for
   --   cost changes that does not use bracket costing. This cursor joins cost_change_temp3 to
   --   item_loc and item_loc_soh. Due to performance constraints, the temp table is necessary
   --   to avoid joining 4 huge tables (il, ils, isc, iscl).
   --
   --   If the cursor collections contain elements, loop through each element and populate the
   --   process elements. If the item is a child item and different from the previous item,
   --   process the unit cost using the iscl unit cost and the cost change value. Otherwise
   --   use the previous value.
   --
   --   Fill the rest of the process collections for later insert/updates. For each
   --   unique item, fill the buypk collection to update buyer packs later. If the
   --   item is at the transaction level and is for order recalc, fill the ord collection
   --   for later updates.
   --
   --   Clear the cursor collections for reuse
   --
   --   If the cost change reason = 3, fill the reset collections using C_RESET_BRACKET.
   --   Bulk fetch C_DETAIL_LOC_BRACKET into the cursor collections and loop through
   --   each element if any.
   --
   --      Note:  C_DETAIL_LOC_BRACKET cursor uses the same concept as the
   --             insert-select using the "WITH" clause. However, this just a direct
   --             join of CM to item_supplier_country_bracket_cost in the main query.
   --
   --   The same procedure is done for child records and the process collections
   --   for iscbc updates external function calls are filled for later processing.
   --
   --   Finally, call PROCESS_COST_CHANGE_RECS to process all the collections.
   --------------------------------------------------------------------------------

   -- Stage records ISC, ISCL records with locations
   SQL_LIB.SET_MARK('INSERT',
                    'cost_change_temp3',
                    'COST_SUSP_SUP_DETAIL, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY, ' ||
                    'ITEM_SUPP_COUNTRY_LOC, ' ||
                    'STORE, ' ||
                    'WH, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   insert into cost_change_temp3 (cost_change,
                                item,
                                supplier,
                                origin_country_id,
                                loc,
                                loc_type,
                                unit_cost,
                                cost_change_type,
                                cost_change_value,
                                recalc_ord_ind,
                                isc_rowid,
                                isc_unit_cost,
                                iscl_rowid,
                                iscl_unit_cost,
                                iscl_prim_loc_ind,
                                dept,
                                class,
                                subclass,
                                status,
                                pack_ind,
                                child_ind,
                                tran_level_item_ind,
                                sup_currency,
                                loc_currency)
      with csd as (select d.cost_change,
                          im.item,
                          d.item dtl_item,
                          d.supplier,
                          d.origin_country_id,
                          d.loc,
                          d.unit_cost,
                          d.cost_change_type,
                          d.cost_change_value,
                          d.recalc_ord_ind,
                          im.dept,
                          im.class,
                          im.subclass,
                          im.status,
                          im.pack_ind,
                          'N' child_ind,
                          DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind
                     from cost_susp_sup_detail_loc d,
                          item_master im
                    where d.cost_change = I_cost_change
                      and d.bracket_value1 is NULL
                      and d.item = im.item
		      and (im.orderable_ind = 'Y'
                      or im.item_xform_ind = 'N')),
            cm as (select c.*,
                          row_number()
                          over (partition by c.supplier,
                                             c.origin_country_id,
                                             c.loc,
                                             c.item
                                    order by c.child_ind) dtl_row
                    from (select *
                            from csd
                           union all
                          select csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.loc,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 im.dept,
                                 im.class,
                                 im.subclass,
                                 im.status,
                                 im.pack_ind,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind
                            from csd,
                                 item_master im
                           where csd.item = im.item_parent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A'
                           union all
                          select /*+ ordered use_nl(csd im) */
                                 csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.loc,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 im.dept,
                                 im.class,
                                 im.subclass,
                                 im.status,
                                 im.pack_ind,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind
                            from csd,
                                 item_master im
                           where csd.item = im.item_grandparent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A') c)
      select cisl.cost_change,
             cisl.item,
             cisl.supplier,
             cisl.origin_country_id,
             cisl.loc,
             cisl.loc_type,
             cisl.unit_cost,
             cisl.cost_change_type,
             cisl.cost_change_value,
             cisl.recalc_ord_ind,
             cisl.isc_rowid,
             cisl.isc_unit_cost,
             cisl.iscl_rowid,
             cisl.iscl_unit_cost,
             cisl.iscl_prim_loc_ind,
             cisl.dept,
             cisl.class,
             cisl.subclass,
             cisl.status,
             cisl.pack_ind,
             cisl.child_ind,
             cisl.tran_level_item_ind,
             cisl.sup_currency,
             cisl.currency_code loc_currency
        from (select cm.*,
                     isc.rowid isc_rowid,
                     isc.unit_cost isc_unit_cost,
                     iscl.loc_type,
                     iscl.rowid iscl_rowid,
                     iscl.unit_cost iscl_unit_cost,
                     iscl.primary_loc_ind iscl_prim_loc_ind,
                     s.currency_code sup_currency,
                     l.currency_code
                from cm,
                     item_supp_country isc,
                     item_supp_country_loc iscl,
                     sups s,
		     (select store loc,
                             currency_code
                        from store
                       union all
                      select wh loc,
                             currency_code
                        from wh) l
               where cm.dtl_row = 1
	         and isc.item = cm.item
                 and isc.supplier = cm.supplier
                 and isc.origin_country_id = cm.origin_country_id
                 and iscl.item = isc.item
                 and iscl.supplier = isc.supplier
                 and iscl.origin_country_id = isc.origin_country_id
                 and iscl.loc = cm.loc
                 and s.supplier = cm.supplier
                 and iscl.loc = l.loc) cisl;

   SQL_LIB.SET_MARK('OPEN',
                    'C_DETAIL_LOC_NO_BRACKET',
                    'cost_change_temp3, ' ||
                    'ITEM_LOC, ' ||
                    'ITEM_LOC_SOH, ',
                    'Cost Change: ' || I_cost_change);
   open C_DETAIL_LOC_NO_BRACKET;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_DETAIL_LOC_NO_BRACKET',
                    'cost_change_temp3, ' ||
                    'ITEM_LOC, ' ||
                    'ITEM_LOC_SOH, ',
                    'Cost Change: ' || I_cost_change);
   fetch C_DETAIL_LOC_NO_BRACKET BULK COLLECT into TBL_dtl_loc_no_brkt;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DETAIL_LOC_NO_BRACKET',
                    'cost_change_temp3, ' ||
                    'ITEM_LOC, ' ||
                    'ITEM_LOC_SOH, ',
                    'Cost Change: ' || I_cost_change);
   close C_DETAIL_LOC_NO_BRACKET;

   if TBL_dtl_loc_no_brkt.count > 0 then
      for i in TBL_dtl_loc_no_brkt.first..TBL_dtl_loc_no_brkt.last loop
         if TBL_dtl_loc_no_brkt(i).child_ind = 'Y' then
            if L_prev_chld_item is NULL or
               (TBL_dtl_loc_no_brkt(i).item != L_prev_chld_item or
                TBL_dtl_loc_no_brkt(i).supplier != L_prev_chld_supplier or
                TBL_dtl_loc_no_brkt(i).origin_country_id != L_prev_chld_cntry or
                TBL_dtl_loc_no_brkt(i).loc != L_prev_chld_loc) then

               L_child_unit_cost := TBL_dtl_loc_no_brkt(i).iscl_unit_cost;
               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         L_child_unit_cost,
                                                         TBL_dtl_loc_no_brkt(i).item,
                                                         TBL_dtl_loc_no_brkt(i).supplier,
                                                         TBL_dtl_loc_no_brkt(i).origin_country_id,
                                                         'S',
                                                         NULL) then
                  return FALSE;
               end if;

               if TBL_dtl_loc_no_brkt(i).cost_change_type = 'P' then
                  TBL_dtl_loc_no_brkt(i).unit_cost := L_child_unit_cost * (1 + TBL_dtl_loc_no_brkt(i).cost_change_value/100);

               elsif TBL_dtl_loc_no_brkt(i).cost_change_type = 'A' then
                  TBL_dtl_loc_no_brkt(i).unit_cost  := L_child_unit_cost + TBL_dtl_loc_no_brkt(i).cost_change_value;

               elsif TBL_dtl_loc_no_brkt(i).cost_change_type = 'F' then
                  TBL_dtl_loc_no_brkt(i).unit_cost := TBL_dtl_loc_no_brkt(i).cost_change_value;
               end if;

               if (TBL_dtl_loc_no_brkt(i).unit_cost < 0) then
                  raise NEGATIVE_AMOUNT;
               end if;

               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         TBL_dtl_loc_no_brkt(i).unit_cost,
                                                         TBL_dtl_loc_no_brkt(i).item,
                                                         TBL_dtl_loc_no_brkt(i).supplier,
                                                         TBL_dtl_loc_no_brkt(i).origin_country_id,
                                                         'C') then
                  return FALSE;
               end if;
               ---
               L_prev_chld_item       := TBL_dtl_loc_no_brkt(i).item;
               L_prev_chld_supplier   := TBL_dtl_loc_no_brkt(i).supplier;
               L_prev_chld_cntry      := TBL_dtl_loc_no_brkt(i).origin_country_id;
               L_prev_chld_loc        := TBL_dtl_loc_no_brkt(i).loc;
               L_prev_sup_cost        := TBL_dtl_loc_no_brkt(i).unit_cost;
            else
               TBL_dtl_loc_no_brkt(i).unit_cost := L_prev_sup_cost;
            end if;
         end if;

         if TBL_dtl_loc_no_brkt(i).iscl_rowid is not NULL then

            L_size_upd_iscl := L_size_upd_iscl + 1;
            TBL_upd_iscl_rowid(L_size_upd_iscl)         := TBL_dtl_loc_no_brkt(i).iscl_rowid;
            TBL_upd_iscl_unit_cost(L_size_upd_iscl)     := TBL_dtl_loc_no_brkt(i).unit_cost;

            if TBL_dtl_loc_no_brkt(i).status != 'A' or TBL_dtl_loc_no_brkt(i).primary_ind = 'Y' then

               if TBL_dtl_loc_no_brkt(i).sup_currency != TBL_dtl_loc_no_brkt(i).loc_currency then
                  if NOT CURRENCY_SQL.CONVERT(O_error_message,
                                              TBL_upd_iscl_unit_cost(L_size_upd_iscl),
                                              TBL_dtl_loc_no_brkt(i).sup_currency,
                                              TBL_dtl_loc_no_brkt(i).loc_currency,
                                              L_local_cost,
                                              'C',
                                              NULL,
                                              NULL) then
                     return FALSE;
                  end if;
               else
                  L_local_cost := TBL_upd_iscl_unit_cost(L_size_upd_iscl);
               end if;

               if TBL_dtl_loc_no_brkt(i).status = 'A' then
                  -- Fill price_hist collection for insert
                  L_size_ph := L_size_ph + 1;

                  TBL_ph_item(L_size_ph)        := TBL_dtl_loc_no_brkt(i).item;
                  TBL_ph_loc(L_size_ph)         := TBL_dtl_loc_no_brkt(i).loc;
                  TBL_ph_unit_cost(L_size_ph)   := L_local_cost;
                  TBL_ph_unit_retail(L_size_ph) := TBL_dtl_loc_no_brkt(i).loc_retail;
                  TBL_ph_loc_type(L_size_ph)    := TBL_dtl_loc_no_brkt(i).loc_type;

               end if;

               if LP_elc_ind = 'N' and TBL_dtl_loc_no_brkt(i).pack_ind = 'N' then
                  -- Fill ils collection for update
                  L_size_upd_ils := L_size_upd_ils + 1;

                  TBL_upd_ils_rowid(L_size_upd_ils)     := TBL_dtl_loc_no_brkt(i).ils_rowid;
                  TBL_upd_ils_unit_cost(L_size_upd_ils) := L_local_cost;

               end if;

               if (LP_std_av_ind = 'S' and TBL_dtl_loc_no_brkt(i).soh > 0 and TBL_dtl_loc_no_brkt(i).pack_ind = 'N') then
                  L_total_cost := (TBL_dtl_loc_no_brkt(i).loc_cost - L_local_cost) * TBL_dtl_loc_no_brkt(i).soh;

                  -- Fill tran_data_insert collection
                  L_size_stk := L_size_stk + 1;

                  TBL_stk_item(L_size_stk)       := TBL_dtl_loc_no_brkt(i).item;
                  TBL_stk_dept(L_size_stk)       := TBL_dtl_loc_no_brkt(i).dept;
                  TBL_stk_class(L_size_stk)      := TBL_dtl_loc_no_brkt(i).class;
                  TBL_stk_subclass(L_size_stk)   := TBL_dtl_loc_no_brkt(i).subclass;
                  TBL_stk_loc(L_size_stk)        := TBL_dtl_loc_no_brkt(i).loc;
                  TBL_stk_loc_type(L_size_stk)   := TBL_dtl_loc_no_brkt(i).loc_type;
                  TBL_stk_soh(L_size_stk)        := TBL_dtl_loc_no_brkt(i).soh;
                  TBL_stk_total_cost(L_size_stk) := L_total_cost;
                  TBL_stk_old_cost(L_size_stk)   := TBL_dtl_loc_no_brkt(i).loc_cost;
                  TBL_stk_local_cost(L_size_stk) := L_local_cost;

               end if;
            end if;

            if TBL_dtl_loc_no_brkt(i).iscl_prim_loc_ind = 'Y' and
               (L_prev_isc_prim_rowid is NULL or
                TBL_dtl_loc_no_brkt(i).isc_rowid != L_prev_isc_prim_rowid) then
               L_size_isc_prim := L_size_isc_prim + 1;

               -- Fill ISC collection for primary location update
               TBL_isc_prim_rowid(L_size_isc_prim)     := TBL_dtl_loc_no_brkt(i).isc_rowid;
               TBL_isc_prim_unit_cost(L_size_isc_prim) := TBL_upd_iscl_unit_cost(L_size_upd_iscl);

               -- ELC calls
               if LP_elc_ind = 'Y' then

                  L_size_elc := L_size_elc + 1;

                  TBL_elc_item(L_size_elc)              := TBL_dtl_loc_no_brkt(i).item;
                  TBL_elc_supplier(L_size_elc)          := TBL_dtl_loc_no_brkt(i).supplier;
                  TBL_elc_origin_country_id(L_size_elc) := TBL_dtl_loc_no_brkt(i).origin_country_id;

               end if;

               L_prev_isc_prim_rowid         := TBL_dtl_loc_no_brkt(i).isc_rowid;
            end if;

         end if;

         if L_prev_item is NULL or
            TBL_dtl_loc_no_brkt(i).item != L_prev_item then

            L_size_buypk := L_size_buypk + 1;
            TBL_buypk_item(L_size_buypk) := TBL_dtl_loc_no_brkt(i).item;

            if TBL_dtl_loc_no_brkt(i).recalc_ord_ind = 'Y' and
               TBL_dtl_loc_no_brkt(i).tran_level_item_ind = 'Y' then
               L_size_upd_ord := L_size_upd_ord + 1;

               TBL_upd_ord_item.extend;
               TBL_upd_ord_item(TBL_upd_ord_item.count) := TBL_dtl_loc_no_brkt(i).item;
            end if;

            L_prev_item := TBL_dtl_loc_no_brkt(i).item;
         end if;
     end loop;

     TBL_dtl_loc_no_brkt.delete;

   end if;

   if I_cost_reason = 3 then
      SQL_LIB.SET_MARK('OPEN',
                       'C_RESET_BRACKET',
                       'COST_SUSP_SUP_DETAIL_LOC, ' ||
                       'ITEM_MASTER, ' ||
                       'ITEM_SUPP_COUNTRY_BRACKET_COST',
                       'Cost Change: ' || I_cost_change);
      open C_RESET_BRACKET;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_RESET_BRACKET',
                       'COST_SUSP_SUP_DETAIL_LOC, ' ||
                       'ITEM_MASTER, ' ||
                       'ITEM_SUPP_COUNTRY_BRACKET_COST',
                       'Cost Change: ' || I_cost_change);
      fetch C_RESET_BRACKET BULK COLLECT into TBL_iscbc_reset_rowid;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_RESET_BRACKET',
                       'COST_SUSP_SUP_DETAIL_LOC, ' ||
                       'ITEM_MASTER, ' ||
                       'ITEM_SUPP_COUNTRY_BRACKET_COST',
                       'Cost Change: ' || I_cost_change);
      close C_RESET_BRACKET;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_DETAIL_LOC_BRACKET',
                    'COST_SUSP_SUP_DETAIL_LOC, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY_BRACKET_COST, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   open C_DETAIL_LOC_BRACKET;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_DETAIL_LOC_BRACKET',
                    'COST_SUSP_SUP_DETAIL_LOC, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY_BRACKET_COST, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   fetch C_DETAIL_LOC_BRACKET BULK COLLECT into TBL_dtl_loc_brkt;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DETAIL_LOC_BRACKET',
                    'COST_SUSP_SUP_DETAIL_LOC, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY_BRACKET_COST, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   close C_DETAIL_LOC_BRACKET;

   L_prev_chld_item     := NULL;
   L_prev_chld_supplier := NULL;
   L_prev_chld_cntry    := NULL;
   L_prev_chld_loc      := NULL;
   L_prev_item          := NULL;

   if TBL_dtl_loc_brkt.count > 0 then
      for i in TBL_dtl_loc_brkt.first..TBL_dtl_loc_brkt.last loop
         if TBL_dtl_loc_brkt(i).child_ind = 'Y' then
            if L_prev_chld_item is NULL or
               (TBL_dtl_loc_brkt(i).item != L_prev_chld_item or
                TBL_dtl_loc_brkt(i).supplier != L_prev_chld_supplier or
                TBL_dtl_loc_brkt(i).origin_country_id != L_prev_chld_cntry or
                TBL_dtl_loc_brkt(i).loc != L_prev_chld_loc) then

               L_child_unit_cost := TBL_dtl_loc_brkt(i).iscbc_unit_cost;
               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         L_child_unit_cost,
                                                         TBL_dtl_loc_brkt(i).item,
                                                         TBL_dtl_loc_brkt(i).supplier,
                                                         TBL_dtl_loc_brkt(i).origin_country_id,
                                                         'S',
                                                         NULL) then
                  return FALSE;
               end if;

               if TBL_dtl_loc_brkt(i).cost_change_type = 'P' then
                  TBL_dtl_loc_brkt(i).unit_cost := L_child_unit_cost * (1 + TBL_dtl_loc_brkt(i).cost_change_value/100);

               elsif TBL_dtl_loc_brkt(i).cost_change_type = 'A' then
                  TBL_dtl_loc_brkt(i).unit_cost := L_child_unit_cost + TBL_dtl_loc_brkt(i).cost_change_value;

               elsif TBL_dtl_loc_brkt(i).cost_change_type = 'F' then
                  TBL_dtl_loc_brkt(i).unit_cost := TBL_dtl_loc_brkt(i).cost_change_value;
               end if;

               if (TBL_upd_isc_unit_cost(i) < 0) then
                  raise NEGATIVE_AMOUNT;
               end if;

               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         TBL_dtl_loc_brkt(i).unit_cost,
                                                         TBL_dtl_loc_brkt(i).item,
                                                         TBL_dtl_loc_brkt(i).supplier,
                                                         TBL_dtl_loc_brkt(i).origin_country_id,
                                                         'C') then
                  return FALSE;
               end if;
               ---
               L_prev_chld_item       := TBL_dtl_loc_brkt(i).item;
               L_prev_chld_supplier   := TBL_dtl_loc_brkt(i).supplier;
               L_prev_chld_cntry      := TBL_dtl_loc_brkt(i).origin_country_id;
               L_prev_chld_loc        := TBL_dtl_loc_brkt(i).loc;
               L_prev_sup_cost        := TBL_dtl_loc_brkt(i).unit_cost;

               L_update_child := 'Y';
            else
               TBL_dtl_loc_brkt(i).unit_cost := L_prev_sup_cost;
            end if;
         end if;

         if I_cost_reason = 3 then
            -- Fill worksheet default and iscbc collections
            if L_prev_wksht_supplier is NULL or
                  TBL_dtl_loc_brkt(i).bracket_value1  != L_prev_wksht_bracket_value or
                  TBL_dtl_loc_brkt(i).supplier        != L_prev_wksht_supplier or
                  TBL_dtl_loc_brkt(i).sup_dept_seq_no != L_prev_wksht_seq_no then

               L_size_wksht := L_size_wksht + 1;

               TBL_wksht_bracket1(L_size_wksht) := TBL_dtl_loc_brkt(i).bracket_value1;
               TBL_wksht_supplier(L_size_wksht) := TBL_dtl_loc_brkt(i).supplier;
               TBL_wksht_seq_no(L_size_wksht)   := TBL_dtl_loc_brkt(i).sup_dept_seq_no;

               L_prev_wksht_bracket_value := TBL_dtl_loc_brkt(i).bracket_value1;
               L_prev_wksht_supplier      := TBL_dtl_loc_brkt(i).supplier;
               L_prev_wksht_seq_no        := TBL_dtl_loc_brkt(i).sup_dept_seq_no;
            end if;
         end if;

         L_size_upd_iscbc := L_size_upd_iscbc + 1;

         TBL_upd_iscbc_rowid(L_size_upd_iscbc)            := TBL_dtl_loc_brkt(i).iscbc_rowid;
         TBL_upd_iscbc_default_bracket(L_size_upd_iscbc)  := TBL_dtl_loc_brkt(i).default_bracket_ind;
         TBL_upd_iscbc_unit_cost(L_size_upd_iscbc)        := TBL_dtl_loc_brkt(i).unit_cost;

         if L_prev_loc_brkt_item is NULL or
            TBL_dtl_loc_brkt(i).item              != L_prev_loc_brkt_item or
            TBL_dtl_loc_brkt(i).supplier          != L_prev_loc_brkt_sup or
            TBL_dtl_loc_brkt(i).origin_country_id != L_prev_loc_brkt_cntry then

            L_size_upd_loc_brkt := L_size_upd_loc_brkt + 1;

            TBL_upd_loc_brckt_item(L_size_upd_loc_brkt)     := TBL_dtl_loc_brkt(i).item;
            TBL_upd_loc_brckt_supplier(L_size_upd_loc_brkt) := TBL_dtl_loc_brkt(i).supplier;
            TBL_upd_loc_brckt_cntry(L_size_upd_loc_brkt)    := TBL_dtl_loc_brkt(i).origin_country_id;

            L_prev_loc_brkt_item  := TBL_dtl_loc_brkt(i).item;
            L_prev_loc_brkt_sup   := TBL_dtl_loc_brkt(i).supplier;
            L_prev_loc_brkt_cntry := TBL_dtl_loc_brkt(i).origin_country_id;
         end if;

         if TBL_dtl_loc_brkt(i).recalc_ord_ind = 'Y' then
            L_upd_recalc_ind := 'Y';
         end if;

         if L_prev_item IS NULL or
            TBL_dtl_loc_brkt(i).item != L_prev_item then

            L_size_buypk := L_size_buypk + 1;
            TBL_buypk_item(L_size_buypk) := TBL_dtl_loc_brkt(i).item;

            if (TBL_dtl_loc_brkt(i).recalc_ord_ind = 'Y' or
               L_upd_recalc_ind = 'Y') and
               TBL_dtl_loc_brkt(i).tran_level_item_ind = 'Y' then

               TBL_upd_ord_item.extend;
               TBL_upd_ord_item(TBL_upd_ord_item.count) := TBL_dtl_loc_brkt(i).item;
            end if;

            L_prev_item := TBL_dtl_loc_brkt(i).item;
         end if;

      end loop;

      TBL_dtl_loc_brkt.delete;

   end if;

   if NOT PROCESS_COST_CHANGE_RECS(O_error_message,
                                   TBL_upd_isc_rowid,
                                   TBL_upd_isc_unit_cost,
                                   TBL_upd_iscl_rowid,
                                   TBL_upd_iscl_unit_cost,
                                   TBL_ph_item,
                                   TBL_ph_loc,
                                   TBL_ph_loc_type,
                                   TBL_ph_unit_cost,
                                   TBL_ph_unit_retail,
                                   TBL_upd_ils_rowid,
                                   TBL_upd_ils_unit_cost,
                                   TBL_stk_item,
                                   TBL_stk_dept,
                                   TBL_stk_class,
                                   TBL_stk_subclass,
                                   TBL_stk_loc,
                                   TBL_stk_loc_type,
                                   TBL_stk_soh,
                                   TBL_stk_total_cost,
                                   TBL_stk_old_cost,
                                   TBL_stk_local_cost,
                                   TBL_isc_prim_rowid,
                                   TBL_isc_prim_unit_cost,
                                   TBL_elc_item,
                                   TBL_elc_supplier,
                                   TBL_elc_origin_country_id,
                                   TBL_wksht_bracket1,
                                   TBL_wksht_supplier,
                                   TBL_wksht_seq_no,
                                   TBL_iscbc_reset_rowid,
                                   TBL_upd_iscbc_rowid,
                                   TBL_upd_iscbc_unit_cost,
                                   TBL_upd_iscbc_default_bracket,
                                   TBL_upd_loc_brckt_item,
                                   TBL_upd_loc_brckt_supplier,
                                   TBL_upd_loc_brckt_cntry,
                                   L_update_child,
                                   L_upd_recalc_ind,
                                   I_cost_change,
                                   TBL_buypk_item,
                                   TBL_upd_ord_item,
                                   -- 23-Oct-2008 TESCO HSC/Murali 6717469 Begin
                                   I_cost_reason) then
                                   -- 23-Oct-2008 TESCO HSC/Murali 6717469 End
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
END PROCESS_DETAIL_LOC;
--------------------------------------------------------------------------------------------------
FUNCTION PROCESS_DETAILS(O_error_message   IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                         I_cost_change     IN        COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                         I_cost_reason     IN        COST_SUSP_SUP_HEAD.REASON%TYPE)
   return BOOLEAN IS

   L_program                      VARCHAR2(64) := 'COST_EXTRACT_SQL.PROCESS_DETAILS';
   L_table                        VARCHAR2(64) := NULL;

   -- Scalar variables
   L_update_child                 VARCHAR2(1) := 'N';
   L_upd_recalc_ind               VARCHAR2(1) := 'N';

   L_prev_isc_rowid               ROWID;
   L_prev_isc_prim_rowid          ROWID;

   L_local_cost                   ITEM_LOC_SOH.UNIT_COST%TYPE                 := NULL;
   L_child_unit_cost              ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_total_cost                   ITEM_SUPP_COUNTRY.UNIT_COST%TYPE            := 0;

   L_prev_chld_item               COST_SUSP_SUP_DETAIL.ITEM%TYPE              := NULL;
   L_prev_chld_supplier           COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE          := NULL;
   L_prev_chld_cntry              COST_SUSP_SUP_DETAIL.ORIGIN_COUNTRY_ID%TYPE := NULL;
   L_prev_sup_cost                COST_SUSP_SUP_DETAIL.UNIT_COST%TYPE         := NULL;
   L_prev_item                    COST_SUSP_SUP_DETAIL.ITEM%TYPE              := NULL;
   L_prev_wksht_supplier          COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE          := NULL;
   L_prev_wksht_bracket_value     COST_SUSP_SUP_DETAIL.BRACKET_VALUE1%TYPE    := NULL;
   L_prev_wksht_seq_no            COST_SUSP_SUP_DETAIL.SUP_DEPT_SEQ_NO%TYPE   := NULL;
   L_prev_loc_brkt_item           COST_SUSP_SUP_DETAIL.ITEM%TYPE              := NULL;
   L_prev_loc_brkt_sup            COST_SUSP_SUP_DETAIL.SUPPLIER%TYPE          := NULL;
   L_prev_loc_brkt_cntry          COST_SUSP_SUP_DETAIL.ORIGIN_COUNTRY_ID%TYPE := NULL;

   NEGATIVE_AMOUNT                EXCEPTION;

   -- Process collections

   -- For item_supp_country update
   TBL_upd_isc_rowid              TYP_ROWID;
   TBL_upd_isc_unit_cost          TYP_UNIT_COST;

   -- For item_supp_country_loc update
   TBL_upd_iscl_rowid             TYP_ROWID;
   TBL_upd_iscl_unit_cost         TYP_UNIT_COST;

   -- For price_hist insert
   TBL_ph_item                    TYP_ITEM;
   TBL_ph_loc                     TYP_LOC;
   TBL_ph_unit_cost               TYP_UNIT_COST;
   TBL_ph_unit_retail             TYP_UNIT_RETAIL;
   TBL_ph_loc_type                TYP_LOC_TYPE;

   -- For item_loc_soh update
   TBL_upd_ils_rowid              TYP_ROWID;
   TBL_upd_ils_unit_cost          TYP_UNIT_COST;

   -- For STKLEDGR_SQL.TRAN_DATA_INSERT call
   TBL_stk_item                   TYP_ITEM;
   TBL_stk_dept                   TYP_DEPT;
   TBL_stk_class                  TYP_CLASS;
   TBL_stk_subclass               TYP_SUBCLASS;
   TBL_stk_loc                    TYP_LOC;
   TBL_stk_loc_type               TYP_LOC_TYPE;
   TBL_stk_soh                    TYP_STOCK_ON_HAND;
   TBL_stk_total_cost             TYP_UNIT_COST;
   TBL_stk_old_cost               TYP_UNIT_COST;
   TBL_stk_local_cost             TYP_UNIT_COST;

   -- For update of item_supp_country for primary locations
   TBL_isc_prim_rowid             TYP_ROWID;
   TBL_isc_prim_unit_cost         TYP_UNIT_COST;

   -- For ELC calls
   TBL_elc_item                   TYP_ITEM;
   TBL_elc_supplier               TYP_SUPPLIER;
   TBL_elc_origin_country_id      TYP_ORIGIN_COUNTRY_ID;

   -- For Buyer pack processing
   TBL_buypk_item                 TYP_ITEM;

   -- For Order recalculation
   TBL_upd_ord_item               ITEM_TBL := ITEM_TBL();

   -- For Cost change worksheet call
   TBL_wksht_bracket1             TYP_BRACKET_VALUE;
   TBL_wksht_supplier             TYP_SUPPLIER;
   TBL_wksht_seq_no               TYP_SUP_DEPT_SEQ_NO;

   -- For item_supp_country_bracket_cost reset (reason 3)
   TBL_iscbc_reset_rowid          TYP_ROWID;

   -- For item_cupp_country_bracket_cost update
   TBL_upd_iscbc_rowid            TYP_ROWID;
   TBL_upd_iscbc_default_bracket  TYP_DEFAULT_BRACKET_IND;
   TBL_upd_iscbc_unit_cost        TYP_UNIT_COST;

   -- UPDATE location bracket
   TBL_upd_loc_brckt_item         TYP_ITEM;
   TBL_upd_loc_brckt_supplier     TYP_SUPPLIER;
   TBL_upd_loc_brckt_cntry        TYP_ORIGIN_COUNTRY_ID;

   -- Index for collections

   L_size_upd_isc                 NUMBER := 0;
   L_size_upd_iscl                NUMBER := 0;
   L_size_ph                      NUMBER := 0;
   L_size_upd_ils                 NUMBER := 0;
   L_size_stk                     NUMBER := 0;
   L_size_isc_prim                NUMBER := 0;
   L_size_elc                     NUMBER := 0;
   L_size_buypk                   NUMBER := 0;
   L_size_upd_ord                 NUMBER := 0;
   L_size_wksht                   NUMBER := 0;
   L_size_upd_iscbc               NUMBER := 0;
   L_size_upd_loc_brkt            NUMBER := 0;


   cursor C_DETAIL_NO_BRACKET is
      with csd as (select /*+ index(s pk_sups) */
                          d.cost_change,
                          im.item,
                          d.item dtl_item,
                          d.supplier,
                          d.origin_country_id,
                          d.unit_cost,
                          d.cost_change_type,
                          d.cost_change_value,
                          d.recalc_ord_ind,
                          im.dept,
                          im.class,
                          im.subclass,
                          im.status,
                          im.pack_ind,
                          'N' child_ind,
                          DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                          s.currency_code sup_currency
                     from cost_susp_sup_detail d,
                          item_master im,
                          sups s
                    where d.cost_change = I_cost_change
                      and d.bracket_value1 is NULL
                      and d.item = im.item
                      and (im.orderable_ind = 'Y'
                           or im.item_xform_ind = 'N')
                      and d.supplier = s.supplier),
            cm as (select c.*,
                          row_number()
                          over (partition by c.supplier,
                                             c.origin_country_id,
                                             c.item
                                    order by c.child_ind) dtl_row
                    from (select *
                            from csd
                           union all
                          select csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 im.dept,
                                 im.class,
                                 im.subclass,
                                 im.status,
                                 im.pack_ind,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                                 csd.sup_currency
                            from csd,
                                 item_master im
                           where csd.item = im.item_parent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A'
                           union all
                          select /*+ ordered use_nl(csd im) */
                                 csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 im.dept,
                                 im.class,
                                 im.subclass,
                                 im.status,
                                 im.pack_ind,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                                 csd.sup_currency
                            from csd,
                                 item_master im
                           where csd.item = im.item_grandparent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A') c)
      select cm.item,
             cm.supplier,
             cm.origin_country_id,
             NULL loc,
             NULL loc_type,
             cm.unit_cost,
             cm.cost_change_type,
             cm.cost_change_value,
             cm.recalc_ord_ind,
             isc.rowid isc_rowid,
             isc.unit_cost isc_unit_cost,
             NULL iscl_rowid,
             NULL iscl_unit_cost,
             NULL iscl_prim_loc_ind,
             NULL loc_retail,
             NULL primary_ind,
             NULL ils_rowid,
             NULL loc_cost,
             NULL soh,
             cm.dept,
             cm.class,
             cm.subclass,
             cm.status,
             cm.pack_ind,
             cm.child_ind,
             cm.tran_level_item_ind,
             cm.sup_currency,
             NULL loc_currency
        from cm,
             item_supp_country isc
       where cm.dtl_row = 1
         and isc.item = cm.item
         and isc.supplier = cm.supplier
         and isc.origin_country_id = cm.origin_country_id
         and NOT exists (select 'x'
                           from item_loc il
                          where il.item = cm.item)
       union all
      select c.item,
             c.supplier,
             c.origin_country_id,
             c.loc,
             c.loc_type,
             c.unit_cost,
             c.cost_change_type,
             c.cost_change_value,
             c.recalc_ord_ind,
             c.isc_rowid,
             c.isc_unit_cost,
             c.iscl_rowid,
             c.iscl_unit_cost,
             c.iscl_prim_loc_ind,
             il.unit_retail loc_retail,
             case
                when ils.primary_supp = c.supplier and
                     ils.primary_cntry = c.origin_country_id then
                   'Y'
                else
                   'N'
             end primary_ind,
             ils.rowid ils_rowid,
             NVL(ils.unit_cost, 0) loc_cost,
             NVL(ils.stock_on_hand, 0) + NVL(ils.pack_comp_soh, 0) +
                NVL(ils.in_transit_qty, 0) + NVL(ils.pack_comp_intran, 0) soh,
             c.dept,
             c.class,
             c.subclass,
             c.status,
             c.pack_ind,
             c.child_ind,
             c.tran_level_item_ind,
             c.sup_currency,
             c.loc_currency
        from cost_change_temp2 c,
             item_loc il,
             item_loc_soh ils
       where c.cost_change = I_cost_change
         and c.tran_level_item_ind = 'Y'
         and il.item = c.item
         and il.loc = c.loc
         and ils.item = c.item
         and ils.loc = c.loc
       union all
      select c.item,
             c.supplier,
             c.origin_country_id,
             c.loc,
             c.loc_type,
             c.unit_cost,
             c.cost_change_type,
             c.cost_change_value,
             c.recalc_ord_ind,
             c.isc_rowid,
             c.isc_unit_cost,
             c.iscl_rowid,
             c.iscl_unit_cost,
             c.iscl_prim_loc_ind,
             il.unit_retail loc_retail,
             case
                when il.primary_supp = c.supplier and
                     il.primary_cntry = c.origin_country_id then
                   'Y'
                else
                   'N'
             end primary_ind,
             NULL ils_rowid,
             NULL loc_cost,
             NULL soh,
             c.dept,
             c.class,
             c.subclass,
             c.status,
             c.pack_ind,
             c.child_ind,
             c.tran_level_item_ind,
             c.sup_currency,
             c.loc_currency
        from cost_change_temp2 c,
             item_loc il
       where c.cost_change = I_cost_change
         and c.tran_level_item_ind = 'N'
         and il.item = c.item
         and il.loc = c.loc
       order by item,
                supplier,
                origin_country_id;


   cursor C_DETAIL_BRACKET is
      with csd as (select d.cost_change,
                          im.item,
                          d.item dtl_item,
                          d.supplier,
                          d.origin_country_id,
                          d.bracket_value1,
                          d.bracket_value2,
                          d.unit_cost,
                          d.cost_change_type,
                          d.cost_change_value,
                          d.recalc_ord_ind,
                          d.default_bracket_ind,
                          d.sup_dept_seq_no,
                          d.dept,
                          'N' child_ind,
                          DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                          s.inv_mgmt_lvl
                     from cost_susp_sup_detail d,
                          item_master im,
                          sups s
                    where d.cost_change = I_cost_change
                      and d.bracket_value1 is NOT NULL
                      and d.item = im.item
                      and (im.orderable_ind = 'Y'
                           or im.item_xform_ind = 'N')
                      and d.supplier = s.supplier),
            cm as (select c.*,
                          row_number()
                          over (partition by c.supplier,
                                             c.origin_country_id,
                                             c.item
                                    order by c.child_ind) dtl_row
                    from (select *
                            from csd
                           union all
                          select csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.bracket_value1,
                                 csd.bracket_value2,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 csd.default_bracket_ind,
                                 csd.dept,
                                 csd.sup_dept_seq_no,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                                 csd.inv_mgmt_lvl
                            from csd,
                                 item_master im
                           where csd.item = im.item_parent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A'
                           union all
                          select /*+ ordered use_nl(csd im) */
                                 csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.bracket_value1,
                                 csd.bracket_value2,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 csd.default_bracket_ind,
                                 csd.dept,
                                 csd.sup_dept_seq_no,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind,
                                 csd.inv_mgmt_lvl
                            from csd,
                                 item_master im
                           where csd.item = im.item_grandparent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A') c)
      select cm.item,
             cm.supplier,
             cm.origin_country_id,
             cm.bracket_value1,
             cm.bracket_value2,
             cm.unit_cost,
             cm.cost_change_type,
             cm.cost_change_value,
             cm.recalc_ord_ind,
             cm.default_bracket_ind,
             cm.dept,
             cm.sup_dept_seq_no,
             cm.child_ind,
             cm.tran_level_item_ind,
             iscbc.rowid iscbc_rowid,
             iscbc.unit_cost iscbc_unit_cost,
             cm.inv_mgmt_lvl
        from cm,
             item_supp_country_bracket_cost iscbc
       where cm.cost_change = I_cost_change
         and cm.dtl_row = 1
         and iscbc.item = cm.item
         and iscbc.supplier = cm.supplier
         and iscbc.origin_country_id = cm.origin_country_id
         and iscbc.bracket_value1 = cm.bracket_value1
       order by cm.item,
                cm.supplier,
                cm.origin_country_id;

   cursor C_RESET_BRACKET is
      select iscbc.rowid
        from cost_susp_sup_detail csd,
             item_supp_country_bracket_cost iscbc,
             item_master im
       where csd.cost_change = I_cost_change
         and csd.bracket_value1 is NOT NULL
         and ((csd.item = im.item and
               (im.orderable_ind = 'Y'
                or im.item_xform_ind = 'N')) or
              ((csd.item = im.item_parent or
                csd.item = im.item_grandparent) and
               (im.item_level <= im.tran_level) and
               (im.pack_ind = 'N' or
                (im.pack_ind = 'Y' and
                 im.pack_type = 'V')) and
               im.status = 'A'))
         and iscbc.item = im.item
         and iscbc.supplier = csd.supplier
         and iscbc.origin_country_id = csd.origin_country_id
         and csd.bracket_value1 != iscbc.bracket_value1
         for update of iscbc.unit_cost nowait;

   -- Cursor Collections
   TYPE TYP_dtl_no_brkt is TABLE of C_DETAIL_NO_BRACKET%ROWTYPE INDEX BY BINARY_INTEGER;
   TYPE TYP_dtl_brkt    is TABLE of C_DETAIL_BRACKET%ROWTYPE    INDEX BY BINARY_INTEGER;

   TBL_dtl_no_brkt TYP_dtl_no_brkt;
   TBL_dtl_brkt    TYP_dtl_brkt;

BEGIN
   --------------------------------------------------------------------------------
   -- Function Overview:
   --
   --    To maximize performance, cost_change_temp2 (global temporary table) is filled
   --    with records from cost_susp_sup_detail, the corresponding child records
   --    from item_master if there are parent items under cost change, the
   --    corresponding information from item_supp_country, item_supp_country_loc, and
   --    the location currency codes from store and wh tables.
   --
   --       Note: The insert-select to the cost_change_temp2 table uses the "WITH"
   --             clause to simplify the cost_susp_sup_detail + item_master
   --             (for child recs). The temp table will contain records with location
   --             (with item_supp_country_loc/item_loc record).
   --
   --             To understand the query, start with the "WITH" clause. CSD represents
   --             the select statement after it. This select statement is the query
   --             to cost_susp_sup_detail for all orderable items.
   --
   --             Next is the CM which uses the CSD representation. In CM, start with
   --             the innermost union-select statements. The first union set grabs all
   --             the information from CSD. This is basically the items in the cost_susp_
   --             detail table. The second union set joins CSD to item_master to get
   --             the child records for items in CSD (or cost_susp_sup_detail). The
   --             third union set returns grandchildren records for items in CSD.
   --
   --             Problem arises when both parent and child records having different cost
   --             change values are in the cost_sups_sup_detail. The union sets will
   --             return redundant child records, one having the cost_change value from the
   --             cost_susp_sup_detail_loc table and the other inheriting the parent
   --             cost_change value. To resolve the issue without sacrificing performance,
   --             an analytic function (row_number) is used. With this, the resulting set
   --             will have dtl_row = 1 for regular items, parent items, and child items
   --             in the cost_susp_sup_detail_loc or child items queried by the union set
   --             that are not in the cost_susp_sup_detail_loc. The result set will have
   --             dtl_row = 2 for child items queried by the union set but are in the
   --             cost_susp_sup_detail. The result set is filtered to return only dtl_row
   --             = 1 in the main query. This eliminates the redundant child record.
   --
   --             CM is used for the main query after the "WITH" clause. This is joined
   --             with item_supp_country, item_supp_country, sups and the union of store +
   --             wh tables to get the necessary information (rowids, supplier costs etc).
   --             The resulting set is then inserted to cost_change_temp2.
   --
   --   Next is to fill the cursor collections from the C_DETAIL_NO_BRACKET cursor for
   --   cost change that does not use bracket costing.
   --
   --       Note: Again the C_DETAIL_NO_BRACKET cursor uses the "WITH" clause to get the
   --             correct cost change item data set. The main query has 2 union sections,
   --             one for cost change records that doesn't have location information and
   --             other comes from the cost_change_temp2 table containing records with loc
   --             information. Due to performance constraints, the temp table is necessary
   --             to avoid joining 4 huge tables (il, ils, isc, iscl).
   --
   --   If the cursor collections contain elements, loop through each element and populate the
   --   process elements. If the item is a child item and different from the previous item,
   --   process the unit cost using the iscl unit cost and the cost change value. Otherwise
   --   use the previous value.
   --
   --   Fill the rest of the process collections for later insert/updates. For each
   --   unique item, fill the buypk collection to update buyer packs later. If the
   --   item is at the transaction level and is for order recalc, fill the ord collection
   --   for later updates.
   --
   --   Clear the cursor collections for reuse
   --
   --   If the cost change reason = 3, fill the reset collections using C_RESET_BRACKET.
   --   Bulk fetch C_DETAIL_BRACKET into the cursor collections and loop through
   --   each element if any.
   --
   --      Note:  C_DETAIL_BRACKET cursor uses the same concept as the
   --             insert-select using the "WITH" clause. However, this just a direct
   --             join of CM to item_supplier_country_bracket_cost in the main query.
   --
   --   The same procedure is done for child records and the process collections
   --   for iscbc updates, external function calls. These are filled for later
   --   processing.
   --
   --   Finally, call PROCESS_COST_CHANGE_RECS to process all the collections.
   --------------------------------------------------------------------------------

   -- Stage records ISC, ISCL records with locations
   SQL_LIB.SET_MARK('INSERT',
                    'cost_change_temp2',
                    'COST_SUSP_SUP_DETAIL, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY, ' ||
                    'ITEM_SUPP_COUNTRY_LOC, ' ||
                    'STORE, ' ||
                    'WH, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   insert into cost_change_temp2 (cost_change,
                                item,
                                supplier,
                                origin_country_id,
                                loc,
                                loc_type,
                                unit_cost,
                                cost_change_type,
                                cost_change_value,
                                recalc_ord_ind,
                                isc_rowid,
                                isc_unit_cost,
                                iscl_rowid,
                                iscl_unit_cost,
                                iscl_prim_loc_ind,
                                dept,
                                class,
                                subclass,
                                status,
                                pack_ind,
                                child_ind,
                                tran_level_item_ind,
                                sup_currency,
                                loc_currency)
      with csd as (select d.cost_change,
                          im.item,
                          d.item dtl_item,
                          d.supplier,
                          d.origin_country_id,
                          d.unit_cost,
                          d.cost_change_type,
                          d.cost_change_value,
                          d.recalc_ord_ind,
                          im.dept,
                          im.class,
                          im.subclass,
                          im.status,
                          im.pack_ind,
                          'N' child_ind,
                          DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind
                     from cost_susp_sup_detail d,
                          item_master im
                    where d.cost_change = I_cost_change
                      and d.bracket_value1 is NULL
                      and d.item = im.item
                      and (im.orderable_ind = 'Y'
                           or im.item_xform_ind = 'N')),
            cm as (select c.*,
                          row_number()
                          over (partition by c.supplier,
                                             c.origin_country_id,
                                             c.item
                                    order by c.child_ind) dtl_row
                    from (select *
                            from csd
                           union all
                          select csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 im.dept,
                                 im.class,
                                 im.subclass,
                                 im.status,
                                 im.pack_ind,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind
                            from csd,
                                 item_master im
                           where csd.item = im.item_parent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A'
                           union all
                          select /*+ ordered use_nl(csd im) */
                                 csd.cost_change,
                                 im.item,
                                 csd.item dtl_item,
                                 csd.supplier,
                                 csd.origin_country_id,
                                 csd.unit_cost,
                                 csd.cost_change_type,
                                 csd.cost_change_value,
                                 csd.recalc_ord_ind,
                                 im.dept,
                                 im.class,
                                 im.subclass,
                                 im.status,
                                 im.pack_ind,
                                 'Y' child_ind,
                                 DECODE(im.item_level, im.tran_level, 'Y', 'N') tran_level_item_ind
                            from csd,
                                 item_master im
                           where csd.item = im.item_grandparent
                             and im.item_level <= im.tran_level
                             and (im.pack_ind = 'N' or
                                  (im.pack_ind = 'Y' and
                                   im.pack_type = 'V'))
                             and im.status = 'A') c)
      select cisl.cost_change,
             cisl.item,
             cisl.supplier,
             cisl.origin_country_id,
             cisl.loc,
             cisl.loc_type,
             cisl.unit_cost,
             cisl.cost_change_type,
             cisl.cost_change_value,
             cisl.recalc_ord_ind,
             cisl.isc_rowid,
             cisl.isc_unit_cost,
             cisl.iscl_rowid,
             cisl.iscl_unit_cost,
             cisl.iscl_prim_loc_ind,
             cisl.dept,
             cisl.class,
             cisl.subclass,
             cisl.status,
             cisl.pack_ind,
             cisl.child_ind,
             cisl.tran_level_item_ind,
             cisl.sup_currency,
             cisl.currency_code loc_currency
        from (select cm.*,
                     isc.rowid isc_rowid,
                     isc.unit_cost isc_unit_cost,
                     iscl.loc,
                     iscl.loc_type,
                     iscl.rowid iscl_rowid,
                     iscl.unit_cost iscl_unit_cost,
                     iscl.primary_loc_ind iscl_prim_loc_ind,
                     s.currency_code sup_currency,
                     l.currency_code
                from cm,
                     item_supp_country isc,
                     item_supp_country_loc iscl,
                     sups s,
                     (select store loc,
                             currency_code
                        from STORE
                       union all
                      select wh loc,
                             currency_code
                        from wh) l
               where cm.dtl_row = 1
                 and isc.item = cm.item
                 and isc.supplier = cm.supplier
                 and isc.origin_country_id = cm.origin_country_id
                 and iscl.item = isc.item
                 and iscl.supplier = isc.supplier
                 and iscl.origin_country_id = isc.origin_country_id
                 and s.supplier = cm.supplier
                 and iscl.loc = l.loc) cisl;


   SQL_LIB.SET_MARK('OPEN',
                    'C_DETAIL_NO_BRACKET',
                    'COST_SUSP_SUP_DETAIL, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY, ' ||
                    'ITEM_SUPP_COUNTRY_LOC, ' ||
                    'ITEM_LOC, ' ||
                    'ITEM_LOC_SOH, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   open C_DETAIL_NO_BRACKET;

   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_DETAIL_NO_BRACKET',
                    'COST_SUSP_SUP_DETAIL, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY, ' ||
                    'ITEM_SUPP_COUNTRY_LOC, ' ||
                    'ITEM_LOC, ' ||
                    'ITEM_LOC_SOH, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   fetch C_DETAIL_NO_BRACKET BULK COLLECT into TBL_dtl_no_brkt;

   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DETAIL_NO_BRACKET',
                    'COST_SUSP_SUP_DETAIL, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY, ' ||
                    'ITEM_SUPP_COUNTRY_LOC, ' ||
                    'ITEM_LOC, ' ||
                    'ITEM_LOC_SOH, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   close C_DETAIL_NO_BRACKET;


   if TBL_dtl_no_brkt.count > 0 then
      for i in TBL_dtl_no_brkt.first..TBL_dtl_no_brkt.last loop
         -- For child records not specified in the cost change,
         --    do additional processing to get the correct unit cost.
         -- Get the child item unit cost from the supplier unit cost
         --    TBL_dtl_brkt(i).isc_unit cost and do the conversion
         -- This conversion is done if the supplier, origin country or the item (child)
         --    changes. Otherwise use the previous value to improve performance.
         if TBL_dtl_no_brkt(i).child_ind = 'Y' then
            if L_prev_chld_item is NULL or
               (TBL_dtl_no_brkt(i).item != L_prev_chld_item or
                TBL_dtl_no_brkt(i).supplier != L_prev_chld_supplier or
                TBL_dtl_no_brkt(i).origin_country_id != L_prev_chld_cntry) then

               L_child_unit_cost := TBL_dtl_no_brkt(i).isc_unit_cost;
               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         L_child_unit_cost,
                                                         TBL_dtl_no_brkt(i).item,
                                                         TBL_dtl_no_brkt(i).supplier,
                                                         TBL_dtl_no_brkt(i).origin_country_id,
                                                         'S',
                                                         NULL) then
                  return FALSE;
               end if;

               if TBL_dtl_no_brkt(i).cost_change_type = 'P' then
                  TBL_dtl_no_brkt(i).unit_cost := L_child_unit_cost * (1 + TBL_dtl_no_brkt(i).cost_change_value/100);

               elsif TBL_dtl_no_brkt(i).cost_change_type = 'A' then
                  TBL_dtl_no_brkt(i).unit_cost := L_child_unit_cost + TBL_dtl_no_brkt(i).cost_change_value;

               elsif TBL_dtl_no_brkt(i).cost_change_type = 'F' then
                  TBL_dtl_no_brkt(i).unit_cost := TBL_dtl_no_brkt(i).cost_change_value;
               end if;

               if (TBL_dtl_no_brkt(i).unit_cost < 0) then
                  raise NEGATIVE_AMOUNT;
               end if;

               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         TBL_dtl_no_brkt(i).unit_cost,
                                                         TBL_dtl_no_brkt(i).item,
                                                         TBL_dtl_no_brkt(i).supplier,
                                                         TBL_dtl_no_brkt(i).origin_country_id,
                                                         'C') then
                  return FALSE;
               end if;
               ---
               L_prev_chld_item       := TBL_dtl_no_brkt(i).item;
               L_prev_chld_supplier   := TBL_dtl_no_brkt(i).supplier;
               L_prev_chld_cntry      := TBL_dtl_no_brkt(i).origin_country_id;
               L_prev_sup_cost        := TBL_dtl_no_brkt(i).unit_cost;
            else
               TBL_dtl_no_brkt(i).unit_cost := L_prev_sup_cost;
            end if;
         end if;

         -- Fill TBL_upd_isc* collections for each new isc record.
         -- The TBL_upd_isc* will be used later to bulk update the item_supp_country table
         if L_prev_isc_rowid is NULL or
            TBL_dtl_no_brkt(i).isc_rowid != L_prev_isc_rowid then

            L_size_upd_isc := L_size_upd_isc + 1;
            TBL_upd_isc_rowid(L_size_upd_isc)     := TBL_dtl_no_brkt(i).isc_rowid;
            TBL_upd_isc_unit_cost(L_size_upd_isc) := TBL_dtl_no_brkt(i).unit_cost;

            L_prev_isc_rowid := TBL_dtl_no_brkt(i).isc_rowid;
         end if;


         if TBL_dtl_no_brkt(i).iscl_rowid is not NULL then
            -- Fill TBL_upd_iscl* collections for each iscl record.
            -- The TBL_upd_iscl* will be used later to bulk update the item_supp_country_loc table
            L_size_upd_iscl := L_size_upd_iscl + 1;

            TBL_upd_iscl_rowid(L_size_upd_iscl)     := TBL_dtl_no_brkt(i).iscl_rowid;
            TBL_upd_iscl_unit_cost(L_size_upd_iscl) := TBL_dtl_no_brkt(i).unit_cost;

            -- Since PROCESS_DETAILS process all locations under the item/supplier/country,
            -- the case will be the same as in UPDATE_BASE_COST.CHANGE_ISC_COST.
            --
            -- The following code is the same as UPDATE_BASE_COST.CHANGE_COST and
            -- UPDATE_BASE_COST.CHG_ITEMLOC_PRIM_SUPP_CNTRY process.
            if TBL_dtl_no_brkt(i).status != 'A' or TBL_dtl_no_brkt(i).primary_ind = 'Y' then
               -- Convert the supplier unit cost to local cost
               if TBL_dtl_no_brkt(i).sup_currency != TBL_dtl_no_brkt(i).loc_currency then
                  if NOT CURRENCY_SQL.CONVERT(O_error_message,
                                              TBL_upd_iscl_unit_cost(L_size_upd_iscl),
                                              TBL_dtl_no_brkt(i).sup_currency,
                                              TBL_dtl_no_brkt(i).loc_currency,
                                              L_local_cost,
                                              'C',
                                              NULL,
                                              NULL) then
                     return FALSE;
                  end if;
               else
                  L_local_cost := TBL_upd_iscl_unit_cost(L_size_upd_iscl);
               end if;

               if TBL_dtl_no_brkt(i).status = 'A' then
                  -- If the item status is 'A' fill price_hist collection for insert
                  L_size_ph := L_size_ph + 1;

                  TBL_ph_item(L_size_ph)        := TBL_dtl_no_brkt(i).item;
                  TBL_ph_loc(L_size_ph)         := TBL_dtl_no_brkt(i).loc;
                  TBL_ph_unit_cost(L_size_ph)   := L_local_cost;
                  TBL_ph_unit_retail(L_size_ph) := TBL_dtl_no_brkt(i).loc_retail;
                  TBL_ph_loc_type(L_size_ph)    := TBL_dtl_no_brkt(i).loc_type;
               end if;
               -- 23-Oct-2008 TESCO HSC/Murali 6776806 Begin
               if TBL_dtl_no_brkt(i).pack_ind = 'N' then
               -- 23-Oct-2008 TESCO HSC/Murali 6776806 End
                  -- Fill ils collection for update
                  L_size_upd_ils := L_size_upd_ils + 1;

                  TBL_upd_ils_rowid(L_size_upd_ils)     := TBL_dtl_no_brkt(i).ils_rowid;
                  TBL_upd_ils_unit_cost(L_size_upd_ils) := L_local_cost;

               end if;

               if (LP_std_av_ind = 'S' and TBL_dtl_no_brkt(i).soh > 0 AND TBL_dtl_no_brkt(i).pack_ind = 'N') then
                  L_total_cost := (TBL_dtl_no_brkt(i).loc_cost - L_local_cost) * TBL_dtl_no_brkt(i).soh;

                  -- Fill tran_data_insert collection
                  L_size_stk := L_size_stk + 1;

                  TBL_stk_item(L_size_stk)       := TBL_dtl_no_brkt(i).item;
                  TBL_stk_dept(L_size_stk)       := TBL_dtl_no_brkt(i).dept;
                  TBL_stk_class(L_size_stk)      := TBL_dtl_no_brkt(i).class;
                  TBL_stk_subclass(L_size_stk)   := TBL_dtl_no_brkt(i).subclass;
                  TBL_stk_loc(L_size_stk)        := TBL_dtl_no_brkt(i).loc;
                  TBL_stk_loc_type(L_size_stk)   := TBL_dtl_no_brkt(i).loc_type;
                  TBL_stk_soh(L_size_stk)        := TBL_dtl_no_brkt(i).soh;
                  TBL_stk_total_cost(L_size_stk) := L_total_cost;
                  TBL_stk_old_cost(L_size_stk)   := TBL_dtl_no_brkt(i).loc_cost;
                  TBL_stk_local_cost(L_size_stk) := L_local_cost;

               end if;
            end if;

            if TBL_dtl_no_brkt(i).iscl_prim_loc_ind = 'Y' and
               (L_prev_isc_prim_rowid IS NULL or
                TBL_dtl_no_brkt(i).isc_rowid != L_prev_isc_prim_rowid) then
               L_size_isc_prim := L_size_isc_prim + 1;

               -- Fill ISC collection for primary location update
               TBL_isc_prim_rowid(L_size_isc_prim)     := TBL_dtl_no_brkt(i).isc_rowid;
               TBL_isc_prim_unit_cost(L_size_isc_prim) := TBL_upd_iscl_unit_cost(L_size_upd_iscl);

               -- ELC calls
               if LP_elc_ind = 'Y' then
                  L_size_elc := L_size_elc + 1;

                  TBL_elc_item(L_size_elc)              := TBL_dtl_no_brkt(i).item;
                  TBL_elc_supplier(L_size_elc)          := TBL_dtl_no_brkt(i).supplier;
                  TBL_elc_origin_country_id(L_size_elc) := TBL_dtl_no_brkt(i).origin_country_id;
               end if;

               L_prev_isc_prim_rowid := TBL_dtl_no_brkt(i).isc_rowid;
            end if;

         end if;

         -- For each item, fill TBL_buypk_item collection to be used
         --    later for pack item updates.
         -- Fill TBL_upd_ord* collections for items with item_level = tran_level
         if L_prev_item is NULL or
            TBL_dtl_no_brkt(i).item != L_prev_item then

            L_size_buypk := L_size_buypk + 1;
            TBL_buypk_item(L_size_buypk) := TBL_dtl_no_brkt(i).item;

            if TBL_dtl_no_brkt(i).recalc_ord_ind = 'Y' and
               TBL_dtl_no_brkt(i).tran_level_item_ind = 'Y' then

               TBL_upd_ord_item.extend;
               TBL_upd_ord_item(TBL_upd_ord_item.count) := TBL_dtl_no_brkt(i).item;
            end if;

            L_prev_item := TBL_dtl_no_brkt(i).item;
         end if;

     end loop;

     TBL_dtl_no_brkt.delete;

   end if;

   if I_cost_reason = 3 then
      SQL_LIB.SET_MARK('OPEN',
                       'C_RESET_BRACKET',
                       'COST_SUSP_SUP_DETAIL, ' ||
                       'ITEM_MASTER, ' ||
                       'ITEM_SUPP_COUNTRY_BRACKET_COST',
                       'Cost Change: ' || I_cost_change);
      open C_RESET_BRACKET;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_RESET_BRACKET',
                       'COST_SUSP_SUP_DETAIL, ' ||
                       'ITEM_MASTER, ' ||
                       'ITEM_SUPP_COUNTRY_BRACKET_COST',
                       'Cost Change: ' || I_cost_change);
      fetch C_RESET_BRACKET BULK COLLECT into TBL_iscbc_reset_rowid;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_RESET_BRACKET',
                       'COST_SUSP_SUP_DETAIL, ' ||
                       'ITEM_MASTER, ' ||
                       'ITEM_SUPP_COUNTRY_BRACKET_COST',
                       'Cost Change: ' || I_cost_change);
      close C_RESET_BRACKET;
   end if;


   SQL_LIB.SET_MARK('OPEN',
                    'C_DETAIL_BRACKET',
                    'COST_SUSP_SUP_DETAIL, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY_BRACKET_COST, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   open C_DETAIL_BRACKET;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_DETAIL_BRACKET',
                    'COST_SUSP_SUP_DETAIL, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY_BRACKET_COST, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   fetch C_DETAIL_BRACKET BULK COLLECT into TBL_dtl_brkt;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DETAIL_BRACKET',
                    'COST_SUSP_SUP_DETAIL, ' ||
                    'ITEM_MASTER, ' ||
                    'ITEM_SUPP_COUNTRY_BRACKET_COST, ' ||
                    'SUPS',
                    'Cost Change: ' || I_cost_change);
   close C_DETAIL_BRACKET;

   L_prev_chld_item     := NULL;
   L_prev_chld_supplier := NULL;
   L_prev_chld_cntry    := NULL;
   L_prev_item          := NULL;

   if TBL_dtl_brkt.count > 0 THEN
      for i in TBL_dtl_brkt.first..TBL_dtl_brkt.last loop
         if TBL_dtl_brkt(i).child_ind = 'Y' then
            if L_prev_chld_item is NULL or
               (TBL_dtl_brkt(i).item != L_prev_chld_item or
                TBL_dtl_brkt(i).supplier != L_prev_chld_supplier or
                TBL_dtl_brkt(i).origin_country_id != L_prev_chld_cntry) then

               L_child_unit_cost := TBL_dtl_brkt(i).iscbc_unit_cost;
               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         L_child_unit_cost,
                                                         TBL_dtl_brkt(i).item,
                                                         TBL_dtl_brkt(i).supplier,
                                                         TBL_dtl_brkt(i).origin_country_id,
                                                         'S',
                                                         NULL) then
                  return FALSE;
               end if;

               if TBL_dtl_brkt(i).cost_change_type = 'P' then
                  TBL_dtl_brkt(i).unit_cost := L_child_unit_cost * (1 + TBL_dtl_brkt(i).cost_change_value/100);

               elsif TBL_dtl_brkt(i).cost_change_type = 'A' then
                  TBL_dtl_brkt(i).unit_cost := L_child_unit_cost + TBL_dtl_brkt(i).cost_change_value;

               elsif TBL_dtl_brkt(i).cost_change_type = 'F' then
                  TBL_dtl_brkt(i).unit_cost := TBL_dtl_brkt(i).cost_change_value;
               end if;

               if (TBL_dtl_brkt(i).unit_cost < 0) then
                   raise NEGATIVE_AMOUNT;
               end if;

               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         TBL_dtl_brkt(i).unit_cost,
                                                         TBL_dtl_brkt(i).item,
                                                         TBL_dtl_brkt(i).supplier,
                                                         TBL_dtl_brkt(i).origin_country_id,
                                                         'C') then
                  return FALSE;
               end if;
               ---
               L_prev_chld_item     := TBL_dtl_brkt(i).item;
               L_prev_chld_supplier := TBL_dtl_brkt(i).supplier;
               L_prev_chld_cntry    := TBL_dtl_brkt(i).origin_country_id;
               L_prev_sup_cost      := TBL_dtl_brkt(i).unit_cost;

               L_update_child := 'Y';
            else
               TBL_dtl_brkt(i).unit_cost := L_prev_sup_cost;
            end if;
         end if;

         if I_cost_reason = 3 then
            -- Fill worksheet default and iscbc collections
            if L_prev_wksht_supplier is NULL or
                  TBL_dtl_brkt(i).bracket_value1  != L_prev_wksht_bracket_value or
                  TBL_dtl_brkt(i).supplier        != L_prev_wksht_supplier or
                  TBL_dtl_brkt(i).sup_dept_seq_no != L_prev_wksht_seq_no then

               L_size_wksht := L_size_wksht + 1;

               TBL_wksht_bracket1(L_size_wksht) := TBL_dtl_brkt(i).bracket_value1;
               TBL_wksht_supplier(L_size_wksht) := TBL_dtl_brkt(i).supplier;
               TBL_wksht_seq_no(L_size_wksht)   := TBL_dtl_brkt(i).sup_dept_seq_no;

               L_prev_wksht_bracket_value := TBL_dtl_brkt(i).bracket_value1;
               L_prev_wksht_supplier      := TBL_dtl_brkt(i).supplier;
               L_prev_wksht_seq_no        := TBL_dtl_brkt(i).sup_dept_seq_no;
            end if;
         end if;

         L_size_upd_iscbc := L_size_upd_iscbc + 1;

         TBL_upd_iscbc_rowid(L_size_upd_iscbc)            := TBL_dtl_brkt(i).iscbc_rowid;
         TBL_upd_iscbc_default_bracket(L_size_upd_iscbc)  := TBL_dtl_brkt(i).default_bracket_ind;
         TBL_upd_iscbc_unit_cost(L_size_upd_iscbc)        := TBL_dtl_brkt(i).unit_cost;

         if L_prev_loc_brkt_item is NULL or
            TBL_dtl_brkt(i).item              != L_prev_loc_brkt_item or
            TBL_dtl_brkt(i).supplier          != L_prev_loc_brkt_sup or
            TBL_dtl_brkt(i).origin_country_id != L_prev_loc_brkt_cntry then

            L_size_upd_loc_brkt := L_size_upd_loc_brkt + 1;

            TBL_upd_loc_brckt_item(L_size_upd_loc_brkt)     := TBL_dtl_brkt(i).item;
            TBL_upd_loc_brckt_supplier(L_size_upd_loc_brkt) := TBL_dtl_brkt(i).supplier;
            TBL_upd_loc_brckt_cntry(L_size_upd_loc_brkt)    := TBL_dtl_brkt(i).origin_country_id;

            L_prev_loc_brkt_item  := TBL_dtl_brkt(i).item;
            L_prev_loc_brkt_sup   := TBL_dtl_brkt(i).supplier;
            L_prev_loc_brkt_cntry := TBL_dtl_brkt(i).origin_country_id;
         end if;

         if TBL_dtl_brkt(i).recalc_ord_ind = 'Y' then
            L_upd_recalc_ind := 'Y';
         end if;

         if L_prev_item IS NULL or
            TBL_dtl_brkt(i).item != L_prev_item then

            L_size_buypk := L_size_buypk + 1;
            TBL_buypk_item(L_size_buypk) := TBL_dtl_brkt(i).item;

            if (TBL_dtl_brkt(i).recalc_ord_ind = 'Y' or
               L_upd_recalc_ind = 'Y') and
               TBL_dtl_brkt(i).tran_level_item_ind = 'Y' then

               TBL_upd_ord_item.extend;
               TBL_upd_ord_item(TBL_upd_ord_item.count) := TBL_dtl_brkt(i).item;
            end if;

            L_prev_item := TBL_dtl_brkt(i).item;
         end if;

      end loop;

      TBL_dtl_brkt.delete;

   end if;
   if NOT PROCESS_COST_CHANGE_RECS(O_error_message,
                                   TBL_upd_isc_rowid,
                                   TBL_upd_isc_unit_cost,
                                   TBL_upd_iscl_rowid,
                                   TBL_upd_iscl_unit_cost,
                                   TBL_ph_item,
                                   TBL_ph_loc,
                                   TBL_ph_loc_type,
                                   TBL_ph_unit_cost,
                                   TBL_ph_unit_retail,
                                   TBL_upd_ils_rowid,
                                   TBL_upd_ils_unit_cost,
                                   TBL_stk_item,
                                   TBL_stk_dept,
                                   TBL_stk_class,
                                   TBL_stk_subclass,
                                   TBL_stk_loc,
                                   TBL_stk_loc_type,
                                   TBL_stk_soh,
                                   TBL_stk_total_cost,
                                   TBL_stk_old_cost,
                                   TBL_stk_local_cost,
                                   TBL_isc_prim_rowid,
                                   TBL_isc_prim_unit_cost,
                                   TBL_elc_item,
                                   TBL_elc_supplier,
                                   TBL_elc_origin_country_id,
                                   TBL_wksht_bracket1,
                                   TBL_wksht_supplier,
                                   TBL_wksht_seq_no,
                                   TBL_iscbc_reset_rowid,
                                   TBL_upd_iscbc_rowid,
                                   TBL_upd_iscbc_unit_cost,
                                   TBL_upd_iscbc_default_bracket,
                                   TBL_upd_loc_brckt_item,
                                   TBL_upd_loc_brckt_supplier,
                                   TBL_upd_loc_brckt_cntry,
                                   L_update_child,
                                   L_upd_recalc_ind,
                                   I_cost_change,
                                   TBL_buypk_item,
                                   TBL_upd_ord_item,
                                   -- 23-Oct-2008 TESCO HSC/Murali 6717469 Begin
                                   I_cost_reason) then
                                   -- 23-Oct-2008 TESCO HSC/Murali 6717469 End
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
END PROCESS_DETAILS;
-------------------------------------------------------------------------------------------------
FUNCTION PROCESS_COST_CHANGE_RECS(O_error_message              IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_upd_isc_rowid              IN      TYP_ROWID,
                                  I_upd_isc_unit_cost          IN      TYP_UNIT_COST,
                                  I_upd_iscl_rowid             IN      TYP_ROWID,
                                  I_upd_iscl_unit_cost         IN      TYP_UNIT_COST,
                                  I_ins_ph_item                IN      TYP_ITEM,
                                  I_ins_ph_loc                 IN      TYP_LOC,
                                  I_ins_ph_loc_type            IN      TYP_LOC_TYPE,
                                  I_ins_ph_unit_cost           IN      TYP_UNIT_COST,
                                  I_ins_ph_unit_retail         IN      TYP_UNIT_RETAIL,
                                  I_upd_ils_rowid              IN      TYP_ROWID,
                                  I_upd_ils_unit_cost          IN      TYP_UNIT_COST,
                                  I_stk_item                   IN      TYP_ITEM,
                                  I_stk_dept                   IN      TYP_DEPT,
                                  I_stk_class                  IN      TYP_CLASS,
                                  I_stk_subclass               IN      TYP_SUBCLASS,
                                  I_stk_loc                    IN      TYP_LOC,
                                  I_stk_loc_type               IN      TYP_LOC_TYPE,
                                  I_stk_soh                    IN      TYP_STOCK_ON_HAND,
                                  I_stk_total_cost             IN      TYP_UNIT_COST,
                                  I_stk_old_cost               IN      TYP_UNIT_COST,
                                  I_stk_local_cost             IN      TYP_UNIT_COST,
                                  I_isc_prim_rowid             IN      TYP_ROWID,
                                  I_isc_prim_unit_cost         IN      TYP_UNIT_COST,
                                  I_elc_item                   IN      TYP_ITEM,
                                  I_elc_supplier               IN      TYP_SUPPLIER,
                                  I_elc_origin_country_id      IN      TYP_ORIGIN_COUNTRY_ID,
                                  I_wksht_bracket1             IN      TYP_BRACKET_VALUE,
                                  I_wksht_supplier             IN      TYP_SUPPLIER,
                                  I_wksht_seq_no               IN      TYP_SUP_DEPT_SEQ_NO,
                                  I_iscbc_reset_rowid          IN      TYP_ROWID,
                                  I_upd_iscbc_rowid            IN      TYP_ROWID,
                                  I_upd_iscbc_unit_cost        IN      TYP_UNIT_COST,
                                  I_upd_iscbc_default_bracket  IN      TYP_DEFAULT_BRACKET_IND,
                                  I_upd_loc_brckt_item         IN      TYP_ITEM,
                                  I_upd_loc_brckt_supplier     IN      TYP_SUPPLIER,
                                  I_upd_loc_brckt_cntry        IN      TYP_ORIGIN_COUNTRY_ID,
                                  I_update_child               IN      VARCHAR2,
                                  I_upd_recalc_ind             IN      VARCHAR2,
                                  I_cost_change                IN      COST_SUSP_SUP_HEAD.COST_CHANGE%TYPE,
                                  I_buypk_item                 IN      TYP_ITEM,
                                  I_upd_ord_item               IN      ITEM_TBL,
                                  -- 23-Oct-2008 TESCO HSC/Murali 6717469 Begin
                                  I_cost_reason                IN      COST_SUSP_SUP_HEAD.REASON%TYPE)
                                  -- 23-Oct-2008 TESCO HSC/Murali 6717469 End
RETURN BOOLEAN IS

   L_program                      VARCHAR2(64)             := 'COST_EXTRACT_SQL.PROCESS_COST_CHANGE_RECS';
   L_program_main                 VARCHAR2(64)             := 'COST_EXTRACT_SQL.BULK_UPDATE_COSTS';
   L_table                        VARCHAR2(64)             := NULL;
   L_tran_code                    TRAN_DATA.TRAN_CODE%TYPE := 70;
   L_total_cost                   TRAN_DATA.TOTAL_COST%TYPE;
   L_active_date                  DATE                     := DATES_SQL.GET_VDATE + 1;

   RECORD_LOCKED                  EXCEPTION;
   PRAGMA                         EXCEPTION_INIT(Record_Locked, -54);

   TBL_isc_rowid_char             ROWID_CHAR_TBL := ROWID_CHAR_TBL();
   TBL_iscl_rowid_char            ROWID_CHAR_TBL := ROWID_CHAR_TBL();
   TBL_iscbc_reset_rowid_char     ROWID_CHAR_TBL := ROWID_CHAR_TBL();
   TBL_iscbc_rowid_char           ROWID_CHAR_TBL := ROWID_CHAR_TBL();
   TBL_ils_rowid_char             ROWID_CHAR_TBL := ROWID_CHAR_TBL();
   TBL_isc_prim_rowid_char        ROWID_CHAR_TBL := ROWID_CHAR_TBL();

   -- Locking cursors
   cursor C_LOCK_ISC is
      select 'x'
        from item_supp_country isc,
             TABLE(CAST(TBL_isc_rowid_char AS ROWID_CHAR_TBL)) row_id
       where isc.rowid = CHARTOROWID(value(row_id))
         --20-Oct-2011 Tesco HSC/Usha Patil    PrfNBS023365 Begin
       --Uncommented the below code
         for update of isc.unit_cost NOWAIT;
      --20-Oct-2011 Tesco HSC/Usha Patil    PrfNBS023365 End
         --for update of isc.item NOWAIT;

   cursor C_LOCK_ISCL is
      select 'x'
        from item_supp_country_loc iscl,
             TABLE(CAST(TBL_iscl_rowid_char AS ROWID_CHAR_TBL)) row_id
       where iscl.rowid = CHARTOROWID(value(row_id))
         for update of iscl.unit_cost NOWAIT;

   cursor C_LOCK_ISCBC is
      select 'x'
        from item_supp_country_bracket_cost iscbc,
             TABLE(CAST(TBL_iscbc_rowid_char AS ROWID_CHAR_TBL)) row_id
       where iscbc.rowid = CHARTOROWID(value(row_id))
         for update of iscbc.unit_cost NOWAIT;

   cursor C_LOCK_RESET_ISCBC is
      select 'x'
        from item_supp_country_bracket_cost iscbc,
             TABLE(CAST(TBL_iscbc_reset_rowid_char AS ROWID_CHAR_TBL)) row_id
       where iscbc.rowid = CHARTOROWID(value(row_id))
         for update of iscbc.default_bracket_ind NOWAIT;

   cursor C_LOCK_ILS is
      select 'x'
        from item_loc_soh ils,
             TABLE(CAST(TBL_ils_rowid_char AS ROWID_CHAR_TBL)) row_id
       where ils.rowid = CHARTOROWID(value(row_id))
         for update of ils.unit_cost NOWAIT;

   cursor C_LOCK_CSD is
      select 'x'
        from cost_susp_sup_detail csd
       where csd.cost_change = I_cost_change
         for update of csd.recalc_ord_ind NOWAIT;

BEGIN
   if I_upd_isc_rowid.count > 0 then
      -- Fill TBL_isc_rowid_char with converted values of I_upd_isc_rowid
      for i in I_upd_isc_rowid.first..I_upd_isc_rowid.last loop
         TBL_isc_rowid_char.extend;
         TBL_isc_rowid_char(i) := ROWIDTOCHAR(I_upd_isc_rowid(i));
      end loop;

      L_table := 'ITEM_SUPP_COUNTRY';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISC','ITEM_SUPP_COUNTRY',NULL);
      open C_LOCK_ISC;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISC','ITEM_SUPP_COUNTRY',NULL);
      close C_LOCK_ISC;

      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',NULL);
      FORALL i in I_upd_isc_rowid.first..I_upd_isc_rowid.last
         update item_supp_country isc
            set unit_cost = I_upd_isc_unit_cost(i),
                last_update_id = USER,
                last_update_datetime = SYSDATE
          where isc.rowid = I_upd_isc_rowid(i);
   end if;
   if I_upd_iscl_rowid.COUNT > 0 THEN
      -- Fill TBL_iscl_rowid_char with converted values of I_upd_iscl_rowid
      for i in I_upd_iscl_rowid.first..I_upd_iscl_rowid.last loop
         TBL_iscl_rowid_char.extend;
         TBL_iscl_rowid_char(i) := ROWIDTOCHAR(I_upd_iscl_rowid(i));
      end loop;

      L_table := 'ITEM_SUPP_COUNTRY_LOC';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISCL','ITEM_SUPP_COUNTRY_LOC',NULL);
      open C_LOCK_ISCL;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISCL','ITEM_SUPP_COUNTRY_LOC',NULL);
      close C_LOCK_ISCL;

      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_LOC',NULL);
      FORALL i in I_upd_iscl_rowid.first..I_upd_iscl_rowid.last
         update item_supp_country_loc iscl
            set unit_cost = I_upd_iscl_unit_cost(i),
                last_update_id = USER,
                last_update_datetime = SYSDATE
          where iscl.rowid = I_upd_iscl_rowid(i);
   end if;
   -- insert into PH
   if I_ins_ph_item.count > 0 then
      SQL_LIB.SET_MARK('INSERT',NULL,'PRICE_HIST',NULL);
      FORALL i in  I_ins_ph_item.first..I_ins_ph_item.last
         insert into price_hist(tran_type,
                                reason,
                                event,
                                item,
                                loc,
                                unit_cost,
                                unit_retail,
                                action_date,
                                multi_units,
                                multi_unit_retail,
                                selling_unit_retail,
                                selling_uom,
                                multi_selling_uom,
                                loc_type)
            values(02,
                   -- 23-Oct-2008 TESCO HSC/Murali 6717469 Begin
                   I_cost_reason,
                   -- 23-Oct-2008 TESCO HSC/Murali 6717469 End
                   NULL,
                   I_ins_ph_item(i),
                   I_ins_ph_loc(i),
                   I_ins_ph_unit_cost(i),
                   I_ins_ph_unit_retail(i),
                   L_active_date,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   I_ins_ph_loc_type(i));

   end if;
   -- update ils
   if I_upd_ils_rowid.count > 0 then
      -- Fill TBL_isc_rowid_char with converted values of I_upd_ils_rowid
      for i in I_upd_ils_rowid.first..I_upd_ils_rowid.last loop
         TBL_ils_rowid_char.extend;
         TBL_ils_rowid_char(i) := ROWIDTOCHAR(I_upd_ils_rowid(i));
      end loop;

      L_table := 'ITEM_LOC_SOH';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ILS','ITEM_LOC_SOH',NULL);
      open C_LOCK_ILS;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ILS','ITEM_LOC_SOH',NULL);
      close C_LOCK_ILS;

      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_LOC_SOH',NULL);
      FORALL i in I_upd_ils_rowid.first..I_upd_ils_rowid.last
         update item_loc_soh ils
            set unit_cost = I_upd_ils_unit_cost(i),
                last_update_datetime = SYSDATE,
                last_update_id       = USER
          where ils.ROWID = I_upd_ils_rowid(i);
   end if;

   if I_stk_item.count > 0 then
      for i in I_stk_item.first..I_stk_item.last loop
         L_total_cost := I_stk_total_cost(i);
         if NOT STKLEDGR_SQL.TRAN_DATA_INSERT(O_error_message,
                                              I_stk_item(i),
                                              I_stk_dept(i),
                                              I_stk_class(i),
                                              I_stk_subclass(i),
                                              I_stk_loc(i),
                                              I_stk_loc_type(i),
                                              L_active_date,
                                              L_tran_code,
                                              NULL,
                                              I_stk_soh(i),
                                              L_total_cost,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_stk_old_cost(i),
                                              I_stk_local_cost(i),
                                              I_stk_dept(i),
                                              I_stk_class(i),
                                              I_stk_subclass(i),
                                              L_program_main) then
            return FALSE;
         end if;
      end loop;
   end if;
   if I_isc_prim_rowid is NOT NULL and I_isc_prim_rowid.count > 0 then
      -- Reuse TBL_isc_rowid_char collection
      -- Fill TBL_isc_rowid_char with converted values of I_isc_prim_rowid
      TBL_isc_rowid_char.delete;
      for i in I_isc_prim_rowid.first..I_isc_prim_rowid.last loop
         TBL_isc_rowid_char.extend;
         TBL_isc_rowid_char(i) := ROWIDTOCHAR(I_isc_prim_rowid(i));
      end loop;

      L_table := 'ITEM_SUPP_COUNTRY';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISC','ITEM_SUPP_COUNTRY',NULL);
      open C_LOCK_ISC;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISC','ITEM_SUPP_COUNTRY',NULL);
      close C_LOCK_ISC;

      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',NULL);
      FORALL i in I_isc_prim_rowid.first..I_isc_prim_rowid.last
         update item_supp_country isc
            set unit_cost = I_isc_prim_unit_cost(i),
                last_update_id = USER,
                last_update_datetime = SYSDATE
          where isc.rowid = I_isc_prim_rowid(i);
   end if;
   if LP_elc_ind = 'Y' AND I_elc_item.count > 0 then
      for i in I_elc_item.first..I_elc_item.last loop
         -- call package to update item expenses
         if NOT ELC_CALC_SQL.CALC_COMP(O_error_message,
                                       'IE',        -- calc_type
                                       I_elc_item(i),
                                       I_elc_supplier(i),
                                       NULL,        -- item_exp_type
                                       NULL,        -- item_exp_seq
                                       NULL,        -- order_no
                                       NULL,        -- ord_seq_no
                                       NULL,        -- pack_item
                                       NULL,        -- zone_id
                                       NULL,        -- hts
                                       NULL,        -- import_origin_country
                                       I_elc_origin_country_id(i),
                                       NULL,        -- effect_from
                                       NULL) then   -- effect_to
            return FALSE;
         end if;

         --  call package to update item assessments
         if NOT ELC_CALC_SQL.CALC_COMP(O_error_message,
                                       'IA',        -- calc_type
                                       I_elc_item(i),
                                       I_elc_supplier(i),
                                       NULL,        -- item_exp_type
                                       NULL,        -- item_exp_seq
                                       NULL,        -- order_no
                                       NULL,        -- ord_seq_no
                                       NULL,        -- pack_item
                                       NULL,        -- zone_id
                                       NULL,        -- hts
                                       NULL,        -- import_origin_country
                                       I_elc_origin_country_id(i),
                                       NULL,        -- effect_from
                                       NULL) then   -- effect_to
            return FALSE;
         end if;

         --  call package to update item expenses again because there may be some expenses that
         --  are dependent on the updated assessments
         if NOT ELC_CALC_SQL.CALC_COMP(O_error_message,
                                       'IE',        -- calc_type
                                       I_elc_item(i),
                                       I_elc_supplier(i),
                                       NULL,        -- item_exp_type
                                       NULL,        -- item_exp_seq
                                       NULL,        -- order_no
                                       NULL,        -- ord_seq_no
                                       NULL,        -- pack_item
                                       NULL,        -- zone_id
                                       NULL,        -- hts
                                       NULL,        -- import_origin_country
                                       I_elc_origin_country_id(i),
                                       NULL,        -- effect_from
                                       NULL) then   -- effect_to
            return FALSE;
         end if;
      end loop;
   end if;
   if I_wksht_bracket1.count > 0 then
      for i in I_wksht_bracket1.first..I_wksht_bracket1.last loop
         if NOT COST_EXTRACT_SQL.CHANGE_WORKSHEET_DEFAULT(O_error_message,
                                                          I_wksht_bracket1(i),
                                                          I_wksht_supplier(i),
                                                          I_wksht_seq_no(i)) then
            return FALSE;
         end if;

      end loop;
   end if;

   if I_iscbc_reset_rowid.count > 0 then
      -- Fill TBL_iscbc_reset_rowid_char with converted values of I_isc_prim_rowid
      for i in I_iscbc_reset_rowid.first..I_iscbc_reset_rowid.last loop
         TBL_iscbc_reset_rowid_char.extend;
         TBL_iscbc_reset_rowid_char(TBL_iscbc_reset_rowid_char.count) := ROWIDTOCHAR(I_iscbc_reset_rowid(i));
      end loop;

      L_table := 'ITEM_SUPP_COUNTRY_BRACKET_COST';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_RESET_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      open C_LOCK_RESET_ISCBC;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_RESET_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      close C_LOCK_RESET_ISCBC;

      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      FORALL i in I_iscbc_reset_rowid.first..I_iscbc_reset_rowid.last
         update item_supp_country_bracket_cost iscbc
            set default_bracket_ind = 'N'
          where iscbc.rowid = I_iscbc_reset_rowid(i);
   end if;

   if I_upd_iscbc_rowid.count > 0 then
      -- Fill TBL_iscbc_reset_rowid_char with converted values of I_isc_prim_rowid
      for i in I_upd_iscbc_rowid.first..I_upd_iscbc_rowid.last loop
         TBL_iscbc_rowid_char.extend;
         TBL_iscbc_rowid_char(TBL_iscbc_rowid_char.count) := ROWIDTOCHAR(I_upd_iscbc_rowid(i));
      end loop;

      L_table := 'ITEM_SUPP_COUNTRY_BRACKET_COST';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      open C_LOCK_ISCBC;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      close C_LOCK_ISCBC;

      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY_BRACKET_COST',NULL);
      FORALL i in I_upd_iscbc_rowid.first..I_upd_iscbc_rowid.last
         update item_supp_country_bracket_cost iscbc
            set unit_cost = I_upd_iscbc_unit_cost(i),
                default_bracket_ind = I_upd_iscbc_default_bracket(i)
          where rowid = I_upd_iscbc_rowid(i);
   end if;

   if I_upd_loc_brckt_item.count > 0 then
      for i in I_upd_loc_brckt_item.first..I_upd_loc_brckt_item.last loop
         if NOT ITEM_BRACKET_COST_SQL.UPDATE_ALL_LOCATION_BRACKETS(O_error_message,
                                                                   I_upd_loc_brckt_item(i),
                                                                   I_upd_loc_brckt_supplier(i),
                                                                   I_upd_loc_brckt_cntry(i),
                                                                   I_update_child)then
            return FALSE;
         end if;
      end loop;
   end if;

   if I_upd_recalc_ind = 'Y' then
      L_table := 'COST_SUSP_SUP_DETAIL';

      SQL_LIB.SET_MARK('OPEN','C_LOCK_CSD','COST_SUSP_SUP_DETAIL','Cost Change: ' || I_cost_change);
      open C_LOCK_CSD;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_CSD','COST_SUSP_SUP_DETAIL','Cost Change: ' || I_cost_change);
      close C_LOCK_CSD;

      SQL_LIB.SET_MARK('UPDATE',NULL,'COST_SUSP_SUP_DETAIL','Cost Change: ' || I_cost_change);
      update cost_susp_sup_detail
         set recalc_ord_ind = 'Y'
       where cost_change = I_cost_change;

   end if;

   -- Pack processing
   if I_buypk_item.count > 0 then
      for i in I_buypk_item.first..I_buypk_item.last loop
         if NOT COST_EXTRACT_SQL.UPDATE_BUYER_PACK(O_error_message,
                                                   I_buypk_item(i)) then
            return FALSE;
         end if;
         -- Begin: Wipro Enabler / Shekar Radhakrishnan, Mod n53, 07-03-2008
         if NOT COST_EXTRACT_SQL.TSL_UPDATE_RATIO_PACK(O_error_message,
                                                       I_buypk_item(i)) then
            return FALSE;
         end if;
         -- End  : Wipro Enabler / Shekar Radhakrishnan, Mod n53, 07-03-2008
      end loop;
   end if;
   -- Order processing
   if I_upd_ord_item is NOT NULL and I_upd_ord_item.count > 0 then
      if NOT COST_EXTRACT_SQL.BULK_UPDATE_APPROVED_ORDERS(O_error_message,
                                                          I_upd_ord_item) then
            return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := O_error_message || SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                               L_table,
                                                               NULL,
                                                               NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END PROCESS_COST_CHANGE_RECS;
-------------------------------------------------------------------------------------------------
FUNCTION BULK_UPDATE_APPROVED_ORDERS(O_error_message IN OUT VARCHAR2,
                                     I_items         IN     ITEM_TBL)
   return BOOLEAN IS

   TYPE TYP_order_no     is TABLE of ORDHEAD.ORDER_NO%TYPE INDEX BY BINARY_INTEGER;

   TBL_upd_ol_rowid      TYP_ROWID;
   TBL_upd_ol_unit_cost  TYP_UNIT_COST;
   TBL_queue_order_no    TYP_ORDER_NO;
   TBL_exp_order_no      TYP_ORDER_NO;
   TBL_exp_item          TYP_ITEM;
   TBL_assess_order_no   TYP_ORDER_NO;
   TBL_assess_item       TYP_ITEM;

   TBL_ol_rowid_char     ROWID_CHAR_TBL := ROWID_CHAR_TBL();

   L_ol_size             NUMBER := 0;
   L_queue_size          NUMBER := 0;
   L_exp_size            NUMBER := 0;
   L_assess_size         NUMBER := 0;

   L_program             VARCHAR2(64) := 'COST_EXTRACT_SQL.BULK_UPDATE_APPROVED_ORDERS';

   L_table               VARCHAR2(64) := NULL;
   L_exists              VARCHAR2(1);

   L_order_no            ORDHEAD.ORDER_NO%TYPE;
   L_item                ITEM_MASTER.ITEM%TYPE := NULL;

   L_prev_order_no       ORDHEAD.ORDER_NO%TYPE;

   L_prev_exp_ord        ORDHEAD.ORDER_NO%TYPE := NULL;
   L_prev_exp_item       ITEM_MASTER.ITEM%TYPE := NULL;

   RECORD_LOCKED         EXCEPTION;
   PRAGMA                EXCEPTION_INIT(Record_Locked, -54);

   cursor C_FIND_APPROVED_ORDERS IS
      select /*+ ordered use_nl(itm os oh ol) */
             oh.order_no,
             os.item,
             iscl.unit_cost,
             ol.ROWID ol_rowid
        from TABLE(CAST(I_items AS ITEM_TBL)) itm,
             ordsku os,
             ordhead oh,
             ordloc ol,
             item_supp_country_loc iscl
       where os.item = value(itm)
         and os.order_no = oh.order_no
         and oh.status = 'A'
         and oh.order_no = ol.order_no
         and ol.item = os.item
         and iscl.item = ol.item
         and iscl.supplier = oh.supplier
         and iscl.origin_country_id = os.origin_country_id
         and iscl.loc = ol.location
         and ol.qty_received is NULL
         and  NOT (ol.cost_source = 'MANL')
       union all
      select /*+ ordered use_nl (itm p im os oh ol isc) */ distinct
             oh.order_no,
             value(itm) item,
             isc.unit_cost,
             ol.rowid ol_rowid
        from TABLE(CAST(I_items AS ITEM_TBL)) itm,
             packitem_breakout p,
             item_master im,
             ordsku os,
             ordhead oh,
             ordloc ol,
             item_supp_country isc
       where (p.item = value(itm)
           or p.item in (select im.item
                     from item_master im
                     where (im.item_parent = value(itm)
                         or im.item_grandparent = value(itm))
                     and im.item_level <= im.tran_level))
         and im.item = p.pack_no
         and im.pack_type = 'B'
         and im.item = os.item
         and os.order_no = oh.order_no
         and oh.status = 'A'
         and ol.order_no = os.order_no
         and ol.item = os.item
         and isc.item = ol.item
         and isc.primary_supp_ind  = 'Y'
         and isc.primary_country_ind = 'Y'
         and ol.qty_received IS NULL
         and  NOT (ol.cost_source = 'MANL')
       order by order_no,
                item;

   TYPE TYP_ord_info IS TABLE OF C_FIND_APPROVED_ORDERS%ROWTYPE INDEX BY BINARY_INTEGER;
   TBL_ord_info TYP_ord_info;


   cursor C_EXPENSE_EXIST is
      select 'x'
        from ordloc_exp
       where order_no = L_order_no
         and item     = L_item
         and est_exp_value > 0;

   cursor C_ASSESS_EXIST is
      select 'x'
        from ordsku_hts_assess
       where order_no = L_order_no
         and est_assess_value > 0;

   cursor C_LOCK_ORDLOC is
      select 'x'
        from ordloc ol,
             TABLE(CAST(TBL_ol_rowid_char AS ROWID_CHAR_TBL)) row_id
       where ol.rowid = CHARTOROWID(value(row_id))
         for update of ol.unit_cost NOWAIT;


BEGIN

   --- This function will find all approved buyer orders for a passed in item.
   --- Next it will insert or update into deal_calc_que for the item.
   --- Then, it will update the order's unit_cost and unit_cost_init with the
   --- new unit_cost from ITEM_SUPP_COUNTRY_LOC.  Then, it will update any
   --- expenses and assessments for the item.
   --- Check for not null variables that are passed in

   if I_items is NULL then
      O_error_message:= SQL_LIB.create_msg('INVALID_PARM', 'I_items',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_FIND_APPROVED_ORDERS',
                    'ORDHEAD',
                    NULL);
   open C_FIND_APPROVED_ORDERS;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_FIND_APPROVED_ORDERS',
                    'ORDHEAD',
                    NULL);
   fetch C_FIND_APPROVED_ORDERS BULK COLLECT into TBL_ord_info;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_FIND_APPROVED_ORDERS',
                    'ORDHEAD',
                    NULL);
   close C_FIND_APPROVED_ORDERS;

   if TBL_ord_info.count > 0 then
      for i IN TBL_ord_info.first..TBL_ord_info.last loop
         L_order_no := TBL_ord_info(i).order_no;
         L_item     := TBL_ord_info(i).item;

         -- Fill ordloc update collections
         L_ol_size := L_ol_size + 1;

         TBL_upd_ol_rowid(L_ol_size) :=  TBL_ord_info(i).ol_rowid;
         TBL_upd_ol_unit_cost(L_ol_size) := TBL_ord_info(i).unit_cost;

         if L_prev_order_no is NULL or
            (L_order_no != L_prev_order_no) then
            L_queue_size := L_queue_size + 1;

            TBL_queue_order_no(L_queue_size) := L_order_no;

            L_prev_order_no := L_order_no;
         end if;

         if L_prev_exp_ord is NULL or
            L_order_no != L_prev_exp_ord or
            L_item != L_prev_exp_item then

            dbms_output.put_line('in logic: ' || i);

            -- Check if purchase order expense exists. If so fill the exp collections
            SQL_LIB.SET_MARK('OPEN',
                             'C_EXPENSE_EXIST',
                             'ORDLOC_EXP',
                             'Order No: '|| TO_CHAR(L_order_no) ||
                             ', Item : ' || L_item);
            open C_EXPENSE_EXIST;
            ---
            SQL_LIB.SET_MARK('FETCH',
                             'C_EXPENSE_EXIST',
                             'ORDLOC_EXP',
                             'Order No: '|| TO_CHAR(L_order_no) ||
                             ', Item : ' || L_item);
            fetch C_EXPENSE_EXIST into L_exists;
            ---
            if C_EXPENSE_EXIST%FOUND then
               L_exp_size := L_exp_size + 1;

               TBL_exp_order_no(L_exp_size) := L_order_no;
               TBL_exp_item(L_exp_size)     := L_item;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE',
                             'C_EXPENSE_EXIST',
                             'ORDLOC_EXP',
                             'Order No: '|| TO_CHAR(L_order_no) ||
                             ', Item : ' || L_item);
            close C_EXPENSE_EXIST;

            --- See if purchase order assessments exist for the order.  If they do,
            --- populate the assess collections.
            SQL_LIB.SET_MARK('OPEN',
                             'C_ASSESS_EXIST',
                             'ORDSKU_HTS_ASSESS',
                             'Order No: '|| TO_CHAR(L_order_no));
            open C_ASSESS_EXIST;
            ---
            SQL_LIB.SET_MARK('FETCH',
                             'C_ASSESS_EXIST',
                             'ORDSKU_HTS_ASSESS',
                             'Order No: '|| TO_CHAR(L_order_no));
            fetch C_ASSESS_EXIST into L_exists;
            ---
            if C_ASSESS_EXIST%FOUND then
               L_assess_size := L_exp_size + 1;

               TBL_assess_order_no(L_assess_size) := L_order_no;
               TBL_assess_item(L_assess_size)     := L_item;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE',
                             'C_ASSESS_EXIST',
                             'ORDSKU_HTS_ASSESS',
                             'Order No: '|| TO_CHAR(L_order_no));
            close C_ASSESS_EXIST;

            L_prev_exp_ord  := L_order_no;
            L_prev_exp_item := L_item;

         end if;
      end loop;

      TBL_ord_info.delete;

      -- insert into deal_calc_queue_temp
      if TBL_queue_order_no.count > 0 then
         SQL_LIB.SET_MARK('INSERT', NULL, 'DEAL_CALC_QUEUE_TEMP', NULL);
         forall i in TBL_queue_order_no.first..TBL_queue_order_no.last
            insert into deal_calc_queue_temp(order_no,
                                             recalc_all_ind,
                                             override_manual_ind,
                                             order_appr_ind)
               select TBL_queue_order_no(i),
                      'Y',
                      'N',
                      'N'
                 from dual
                where not exists (select 'x'
                                    from deal_calc_queue
                                   where order_no = TBL_queue_order_no(i))
                  and not exists (select 'x'
                                    from deal_calc_queue_temp
                                   where order_no = TBL_queue_order_no(i));

         TBL_queue_order_no.delete;
      end if;

      -- update ordloc
      if TBL_upd_ol_rowid.count > 0 then
         for i in TBL_upd_ol_rowid.first..TBL_upd_ol_rowid.last loop
            TBL_ol_rowid_char.extend;
            TBL_ol_rowid_char(i) := ROWIDTOCHAR(TBL_upd_ol_rowid(i));
         end loop;

         L_table := 'ORDLOC';

         SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDLOC','ORDLOC',NULL);
         open C_LOCK_ORDLOC;

         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDLOC','ORDLOC',NULL);
         close C_LOCK_ORDLOC;

         SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_SUPP_COUNTRY',NULL);
         FORALL i in TBL_upd_ol_rowid.first..TBL_upd_ol_rowid.last
            update ordloc ol
               set unit_cost = TBL_upd_ol_unit_cost(i)
             where ol.rowid = TBL_upd_ol_rowid(i);

         TBL_upd_ol_rowid.delete;
         TBL_upd_ol_unit_cost.delete;
         TBL_ol_rowid_char.delete;
       end if;

       -- calculate purchase order expense
       if TBL_exp_order_no.count > 0 then
          for i in TBL_exp_order_no.first..TBL_exp_order_no.last loop
             if NOT ELC_CALC_SQL.CALC_COMP(O_error_message,
                                           'PE',
                                           TBL_exp_item(i),
                                           NULL,
                                           NULL,
                                           NULL,
                                           TBL_exp_order_no(i),
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL) then
                 return FALSE;
             end if;
          end loop;

          TBL_exp_order_no.delete;
          TBL_exp_item.delete;
       end if;

       -- calculate purchase order assesments
       if TBL_assess_order_no.count > 0 then
          for i in TBL_assess_order_no.first..TBL_assess_order_no.last loop
             --- Call package to update the Purchase order assessment
             if NOT ELC_CALC_SQL.CALC_COMP(O_error_message,
                                           'PA',
                                           TBL_assess_item(i),
                                           NULL,
                                           NULL,
                                           NULL,
                                           TBL_assess_order_no(i),
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL) then
                 return FALSE;
             end if;
             --- Recalculate expenses again becuase expenses could be dependent
             --- on the assessment
             if NOT ELC_CALC_SQL.CALC_COMP(O_error_message,
                                           'PE',
                                           TBL_assess_item(i),
                                           NULL,
                                           NULL,
                                           NULL,
                                           TBL_assess_order_no(i),
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL) then
                 return FALSE;
             end if;

          end loop;

          TBL_assess_order_no.delete;
          TBL_assess_item.delete;

       end if;
   end if;

   return TRUE;

EXCEPTION

   WHEN RECORD_LOCKED THEN
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                            L_order_no);
      return FALSE;

   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END BULK_UPDATE_APPROVED_ORDERS;
----------------------------------------------------------------------------------------------------------------
FUNCTION INSERT_COST_RECLASS_CCQ (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
   RETURN BOOLEAN IS

   -- PrfNBS016594, 28-Apr-2010, Manikandan V , Begin
   -- The following select statements are commented as part of defect fix to improve the performance.
   -- These some part of the select statements will never fetches the records as per Tesco business scenario. These statments are removed.
   -- The select statments which is used for the TESCO business, included in below as INSERT/SELECT statement
   -- PrfNBS016594, 28-Apr-2010, Manikandan V , End

   L_program   VARCHAR2(255)        := 'INSERT_COST_RECLASS_CCQ' ;



   NEGATIVE_AMOUNT                EXCEPTION;

BEGIN

	 -- PrfNBS016594, 28-Apr-2010, Manikandan V , Begin
	 -- The following statments are never used in TESCO Business. These codes are commented for improve the performance
  /* OPEN c_reclass_item;
   FETCH c_reclass_item  BULK COLLECT into TBL_reclass_item;
   CLOSE c_reclass_item;

      if TBL_reclass_item.count > 0 then
      for i in TBL_reclass_item.first..TBL_reclass_item.last loop
         if TBL_reclass_item(i).child_ind = 'Y' then
            if L_prev_chld_item is NULL or
               (TBL_reclass_item(i).item != L_prev_chld_item or
                TBL_reclass_item(i).supplier != L_prev_chld_supplier or
                TBL_reclass_item(i).origin_country_id != L_prev_chld_cntry or
                TBL_reclass_item(i).loc != L_prev_chld_loc) then

               L_child_unit_cost := TBL_reclass_item(i).unit_cost;
               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         L_child_unit_cost,
                                                         TBL_reclass_item(i).item,
                                                         TBL_reclass_item(i).supplier,
                                                         TBL_reclass_item(i).origin_country_id,
                                                         'S',
                                                         NULL) then
                  return FALSE;
               end if;

               if TBL_reclass_item(i).cost_change_type = 'P' then
                  TBL_reclass_item(i).unit_cost := L_child_unit_cost * (1 + TBL_reclass_item(i).cost_change_value/100);

               elsif TBL_reclass_item(i).cost_change_type = 'A' then
                  TBL_reclass_item(i).unit_cost  := L_child_unit_cost + TBL_reclass_item(i).cost_change_value;

               elsif TBL_reclass_item(i).cost_change_type = 'F' then
                  TBL_reclass_item(i).unit_cost := TBL_reclass_item(i).cost_change_value;
               end if;

               if (TBL_reclass_item(i).unit_cost < 0) then
                  raise NEGATIVE_AMOUNT;
               end if;

               if NOT ITEM_SUPP_COUNTRY_SQL.CONVERT_COST(O_error_message,
                                                         TBL_reclass_item(i).unit_cost,
                                                         TBL_reclass_item(i).item,
                                                         TBL_reclass_item(i).supplier,
                                                         TBL_reclass_item(i).origin_country_id,
                                                         'C') then
                  return FALSE;
               end if;
               ---
               L_prev_chld_item       := TBL_reclass_item(i).item;
               L_prev_chld_supplier   := TBL_reclass_item(i).supplier;
               L_prev_chld_cntry      := TBL_reclass_item(i).origin_country_id;
               L_prev_chld_loc        := TBL_reclass_item(i).loc;
               L_prev_sup_cost        := TBL_reclass_item(i).unit_cost;
            else
               TBL_reclass_item(i).unit_cost := L_prev_sup_cost;
            end if;
         end if;
          INSERT INTO reclass_cost_chg_queue(
                                             item,
                                             supplier,
                                             origin_country_id,
                                             start_date,
                                             unit_cost,
                                             division,
                                             group_no,
                                             dept,
                                             class,
                                             subclass,
                                             location,
                                             loc_type,
                                             rec_type,
                                             process_flag)
                                     VALUES( TBL_reclass_item(i).item,
                                             TBL_reclass_item(i).supplier,
                                             TBL_reclass_item(i).origin_country_id,
                                             TBL_reclass_item(i).active_date,
                                             TBL_reclass_item(i).unit_cost,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             TBL_reclass_item(i).loc,
                                             TBL_reclass_item(i).loc_type,
                                             'C',
                                             'N');





         END LOOP;
         end if;  */

         INSERT INTO reclass_cost_chg_queue(item,
                                             supplier,
                                             origin_country_id,
                                             start_date,
                                             unit_cost,
                                             location,
                                             loc_type,
                                             rec_type,
                                             process_flag)
            SELECT /*+index(CT) index(iscl)*/
                   ct.item, /*  new cost is specified for tran level item.  */
                   ct.supplier, /*  If loc is specified, cost applies only to   */
                   ct.origin_country_id, /*  that loc. Otherwise, cost applies to all    */
                   ct.active_date, /*  locs for the i/s/c.                         */
                   ct.unit_cost,
                   iscl.loc,
                   iscl.loc_type,
                   'C' as rec_type,
                   'N' as pro_flag
              FROM cost_change_trigger_temp ct,
                   item_master im,
                   item_supp_country_loc iscl,
                   item_supp_country isc
             WHERE im.item = ct.item
               AND im.item_level = im.tran_level
               AND iscl.item = ct.item
               AND iscl.supplier = ct.supplier
               AND iscl.item = isc.item
               AND iscl.supplier = isc.supplier
               AND iscl.origin_country_id = isc.origin_country_id
               AND iscl.origin_country_id = ct.origin_country_id
               AND ((iscl.loc = ct.loc AND ct.loc IS NOT NULL) OR ct.loc IS NULL)
               AND ct.unit_cost IS NOT NULL                           /* indicates cost change was Approved */
               AND NOT EXISTS
                  (SELECT 'x'                                                 /*  if current ct record's   */
                     FROM cost_change_trigger_temp ct2                        /*  loc is NULL (applies to  */
                    WHERE ct2.item = ct.item                                  /*  all locs for i/s/c)      */
                      AND ct2.supplier = ct.supplier                          /*  ensure that overriding   */
                      AND ct2.origin_country_id = ct.origin_country_id        /*  item/loc record doesn't  */
                      AND ct2.loc = DECODE(ct.loc, NULL, iscl.loc, -999)      /*  exist.                   */
                      AND ct2.active_date = ct.active_date)
                      AND NOT EXISTS
                         (SELECT 'x'                                                 /*  ensure the item isn't     */
                            FROM reclass_cost_chg_queue rc3                          /*  on reclass_cost_chg_queue */
                           WHERE rc3.item = ct.item                                  /*  if cost change was        */
                             AND rc3.supplier = ct.supplier                          /*  edited.                   */
                             AND rc3.origin_country_id = ct.origin_country_id
                             AND rc3.location = NVL(ct.loc, iscl.loc)
                             AND rc3.start_date = ct.active_date
                       AND rc3.rec_type = 'C');

         -- PrfNBS016594, 28-Apr-2010, Manikandan V , End
  return TRUE;
EXCEPTION
   when NEGATIVE_AMOUNT then
      O_error_message := SQL_LIB.CREATE_MSG('U/P_COST_NOT_NEG',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END;
---------------------------------------------------------------------------------------------------------------
---07-Mar-2008 Wipro Enabler / Shekar Radhakrishnan - Mod:n53 - Begin
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---FUNCTION NAME : TSL_UPDATE_RATIO_PACK
---Purpose       : This function will check to see if the item or a transaction level child of the passed in
---                item is on a Ratio Pack with Cost Link Active. Then it will call PACKITEM_ADD_SQL to update
---                all costs for the Ratio Pack.
---------------------------------------------------------------------------------------------------------------
--Defect Id : NBS00008317
--Fixed By  : Nitin Kumar, nitin.kumar@in.tesco.com
--Date      : 01-Sep-2008
--Details   : Modified the function TSL_UPDATE_RATIO_PACK
------------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_RATIO_PACK(O_error_message   IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item            IN        ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
---
   L_program VARCHAR2(64) := 'COST_EXTRACT_SQL.TSL_UPDATE_RATIO_PACK';
   L_pack_no PACKITEM.PACK_NO%TYPE;
---
--- C_PACK Purpose: This cursor will return every Ratio Packs with Cost Link Active,
---                 associated to the passed Item
   CURSOR C_PACK is
   select distinct pi.pack_no
     from packitem pi,
          item_master im
    where pi.item            = I_item
      and im.item            = pi.pack_no
      and im.pack_type       = 'V'
      and im.simple_pack_ind = 'N'
      and im.orderable_ind   = 'Y'
      and im.tsl_mu_ind      = 'N'
      and im.pack_ind        = 'Y'
    union
   select distinct pi.pack_no
     from packitem pi,
          item_master im
    where pi.item in (select im2.item
                        from item_master im2
                       where (im2.item_parent     =  I_item
                          or im2.item_grandparent =  I_item)
                         and im2.item_level       <= im2.tran_level)
      and im.item            = pi.pack_no
      and im.pack_type       = 'V'
      and im.simple_pack_ind = 'N'
      and im.orderable_ind   = 'Y'
      and im.tsl_mu_ind      = 'N'
      and im.pack_ind        = 'Y';
BEGIN
---

  if I_item is NULL then
     O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_item',
                                           L_program,
                                           NULL);
     return FALSE;
  end if;
---

   SQL_LIB.SET_MARK('OPEN',
                    'C_PACK',
                    'PACKITEM, ITEM_MASTER',
                    'Item : ' || I_item);
   FOR C_rec in C_PACK
   LOOP
      L_pack_no := C_rec.pack_no;
      --14-Oct-2011 Tesco HSC/Usha Patil       CR449/PrfNBS023365 Begin
      --Removed the function call TSL_RATIO_PACK_SQL.TSL_UPDATE_SUPP_COST and
      --inserted data into temp table. Called the removed func in SCCEXT POST batch.

      insert into tsl_cost_chg_rp_temp values (L_pack_no);
      --14-Oct-2011 Tesco HSC/Usha Patil       CR449/PrfNBS023365 End
   END LOOP;
---

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END TSL_UPDATE_RATIO_PACK;
---------------------------------------------------------------------------------------------------------------
---FUNCTION NAME : TSL_INSERT_RP_COST_CCQ
---Purpose       : This function inserts on the RECLASS_COST_CHG_QUEUE all the non-MU Ratio Packs that will
---                suffer only a Cost Change when a Cost Change is made to one of its Component Items.
---------------------------------------------------------------------------------------------------------------
--Defect Id :- NBS00006286
--Fixed By  :- Nitin Kumar, nitin.kumar@in.tesco.com
--Date      :- 17-Apr-2008
--Details   :- Modified the cursor C_GET_COMP_CC in the function TSL_INSERT_RP_COST_CCQ
---------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Defect Id : NBS00008323
--Fixed By  : Usha Patil, usha.patil@in.tesco.com
--Date      : 19-Aug-2008
--Details   : Modified the cursor C_GET_RP_COST in the function TSL_INSERT_RP_COST_CCQ
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Defect Id : NBS00008323/DefNBS008595
--Fixed By  : Usha Patil, usha.patil@in.tesco.com
--Date      : 28-Aug-2008
--Details   : Modified the cursor C_GET_RP_COST in the function TSL_INSERT_RP_COST_CCQ
------------------------------------------------------------------------------------------------
--Defect Id : NBS00008317
--Fixed By  : Nitin Kumar, nitin.kumar@in.tesco.com
--Date      : 01-Sep-2008
--Details   : Modified the cursor C_GET_RP_COST in the function TSL_INSERT_RP_COST_CCQ
------------------------------------------------------------------------------------------
FUNCTION TSL_INSERT_RP_COST_CCQ(O_error_message   IN OUT    RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS
---
   L_program        VARCHAR2(64) := 'COST_EXTRACT_SQL.TSL_INSERT_RP_COST_CCQ';
   L_apply_rp_link  SYSTEM_OPTIONS.TSL_APPLY_RP_LINK%TYPE;
   L_rp_cost        ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE;
   L_dummy          VARCHAR2(1);
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);
---
--- C_GET_COMP_CC Purpose: This cursor will return the information of any exists Component Items of a
---                        non-MU Ratio Pack that will suffer a Cost Change
   CURSOR C_GET_COMP_CC is
   select distinct pi.pack_no,
          rcc.supplier,
          rcc.origin_country_id,
          rcc.location,
          rcc.loc_type,
          rcc.start_date
     from item_master im,
          item_supp_country_loc iscl,
          packitem pi,
          reclass_cost_chg_queue rcc
    where im.simple_pack_ind     = 'N'
      and im.pack_ind            = 'Y'
      and im.pack_type           = 'V'
      and im.orderable_ind       = 'Y'
      and im.tsl_mu_ind          = 'N'
      and im.item                = pi.pack_no
      and im.item                = iscl.item
      --Defect Id :- NBS00006286, Nitin Kumar, nitin.kumar@in.tesco.com, Begin
      and pi.item                = rcc.item
      --Defect Id :- NBS00006286, Nitin Kumar, nitin.kumar@in.tesco.com, End
      and iscl.supplier          = rcc.supplier
      and iscl.origin_country_id = rcc.origin_country_id
      and iscl.loc               = rcc.location
      and iscl.loc_type          = rcc.loc_type
      and rcc.rec_type           = 'C'
      --20-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 Begin
      and rcc.process_flag       = 'N';
      --20-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 End

--- C_GET_RP_COST Purpose: This cursor will return the unit cost for the passed non-MU Ratio Pack/Supplier/
---                        Origin Country/Location/Start Date
   CURSOR C_GET_RP_COST(Cp_pack_no            PACKITEM.PACK_NO%TYPE,
                        Cp_supplier	          RECLASS_COST_CHG_QUEUE.SUPPLIER%TYPE,
                        Cp_origin_country_id	RECLASS_COST_CHG_QUEUE.ORIGIN_COUNTRY_ID%TYPE,
                        Cp_location	          RECLASS_COST_CHG_QUEUE.LOCATION%TYPE,
                        Cp_loc_type	          RECLASS_COST_CHG_QUEUE.LOC_TYPE%TYPE,
                        Cp_start_date	        DATE) is
   --Defect Id:NBS00008323    Tesco HSC/Usha Patil        Begin
   --multiplied unit_cost with pack_qty
   select SUM(DECODE(rcc.unit_cost, NULL, iscl.unit_cost*pi.pack_qty, rcc.unit_cost*pi.pack_qty))
   --Defect Id:NBS00008323    Tesco HSC/Usha Patil        End
     from item_supp_country_loc iscl,
          reclass_cost_chg_queue rcc,
          packitem pi
    where iscl.item              = pi.item
      and pi.pack_no             = Cp_pack_no
      and iscl.supplier          = Cp_supplier
      and iscl.origin_country_id = Cp_origin_country_id
      and iscl.loc               = Cp_location
      and iscl.loc_type          = Cp_loc_type
      and iscl.item              = rcc.item(+)
      and iscl.supplier          = rcc.supplier(+)
      and iscl.origin_country_id = rcc.origin_country_id(+)
      and iscl.loc               = rcc.location(+)
      and iscl.loc_type          = rcc.loc_type(+)
     --Defect Id:NBS00008323/DefNBS008595    Tesco HSC/Usha Patil        Begin
     --Defect Id:NBS00008317    Tesco HSC/Nitin Kumar        Begin
      and (rcc.rec_type in ('C','N') or rcc.rec_type is NULL)
     --Defect Id:NBS00008317    Tesco HSC/Nitin Kumar        End
     --Defect Id:NBS00008323/DefNBS008595    Tesco HSC/Usha Patil        End
      and ((rcc.item is NOT NULL and rcc.start_date  = (select MAX(rcc2.start_date)
                                                          from reclass_cost_chg_queue rcc2
                                                         where rcc2.item              = iscl.item
                                                           and rcc2.supplier          = iscl.supplier
                                                           and rcc2.origin_country_id = iscl.origin_country_id
                                                           and rcc2.location          = iscl.loc
                                                           and rcc2.loc_type          = iscl.loc_type
                                             --Defect Id:NBS00008323/DefNBS008595    Tesco HSC/Usha Patil        Begin
                                             --Defect Id:NBS00008317    Tesco HSC/Nitin Kumar        Begin
                                                           and (rcc.rec_type in ('C','N') or rcc.rec_type is NULL)
                                             --Defect Id:NBS00008317    Tesco HSC/Nitin Kumar        End
                                             --Defect Id:NBS00008323/DefNBS008595    Tesco HSC/Usha Patil        End
                                                           and rcc2.start_date        <= Cp_start_date))
       or rcc.item is NULL);
--- C_RP_REC_EXISTS Purpose: This cursor will validate if already exists a record for the passed
---                          non-MU Ratio Pack/Supplier/Origin Country/Location/Start Date.
   CURSOR C_RP_REC_EXISTS(Cp_item	              PACKITEM.PACK_NO%TYPE,
                          Cp_supplier	          RECLASS_COST_CHG_QUEUE.SUPPLIER%TYPE,
                          Cp_origin_country_id	RECLASS_COST_CHG_QUEUE.ORIGIN_COUNTRY_ID%TYPE,
                          Cp_location	          RECLASS_COST_CHG_QUEUE.LOCATION%TYPE,
                          Cp_loc_type	          RECLASS_COST_CHG_QUEUE.LOC_TYPE%TYPE,
                          Cp_start_date	        DATE) is
   select 'X'
     from reclass_cost_chg_queue rcc
    where rcc.item              = Cp_item
      and rcc.supplier          = Cp_supplier
      and rcc.origin_country_id = Cp_origin_country_id
      and rcc.location          = Cp_location
      and rcc.loc_type          = Cp_loc_type
      and rcc.start_date        = Cp_start_date
      and rcc.rec_type          = 'C';
--- C_LOCK_RECLASS_COST_CHG_QUEUE1 Purpose: This cursor will lock the rows for update
    CURSOR C_lock_reclass_cost_chg_queue1 (Cp_item	              PACKITEM.PACK_NO%TYPE,
                                           Cp_supplier	          RECLASS_COST_CHG_QUEUE.SUPPLIER%TYPE,
                                           Cp_origin_country_id	  RECLASS_COST_CHG_QUEUE.ORIGIN_COUNTRY_ID%TYPE,
                                           Cp_location	          RECLASS_COST_CHG_QUEUE.LOCATION%TYPE,
                                           Cp_loc_type	          RECLASS_COST_CHG_QUEUE.LOC_TYPE%TYPE,
                                           Cp_start_date	        DATE) is
    select 'X'
      from reclass_cost_chg_queue rcc
     where rcc.item              = Cp_item
       and rcc.supplier          = Cp_supplier
       and rcc.origin_country_id = Cp_origin_country_id
       and rcc.location          = Cp_location
       and rcc.loc_type          = Cp_loc_type
       and rcc.start_date        = Cp_start_date
       and rcc.rec_type          = 'C'
       for update nowait;
--- C_LOCK_RECLASS_COST_CHG_QUEUE2 Purpose: This cursor will lock the rows for update
  --20-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 Begin
  --Modified to improve performance. cost_change_trigger_temp will always hold only packs
  -- so removed the OR conditions with item_parent and item_grandparent and re-wrote the condition
    CURSOR C_lock_reclass_cost_chg_queue2 is
    select 'X'
      from reclass_cost_chg_queue rcc
     where rcc.rec_type     = 'C'
     -- MrgNBS010972 20-Jan-09, Merge from 3.3a to 3.3b - Begin
       --DefNBS010565 24-Dec-08 Chandru Begin
       and exists (
            select 'X'
              from --item_master imc,
                   packitem pi,
                   cost_change_trigger_temp ct,
                   item_master imp
             where
               --20-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 Begin
               --imc.item            = pi.item
               --and (ct.item            = imc.item
               --  or ct.item             = imc.item_parent
               --  or ct.item             = imc.item_grandparent
               --  or pi.pack_no          = imp.item)
               --
                   pi.item  = ct.item
               and imp.item    = pi.pack_no
               --20-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 End
               and imp.item             = rcc.item
               and ct.supplier          = rcc.supplier
               and ct.origin_country_id = rcc.origin_country_id
               and ct.active_date       = rcc.start_date
       -- DefNBS010565 24-Dec-08 Chandru End
       -- MrgNBS010972 20-Jan-09, Merge from 3.3a to 3.3b - End
               and imp.simple_pack_ind = 'N'
               and imp.pack_ind        = 'Y'
               and imp.pack_type       = 'V'
               and imp.orderable_ind   = 'Y'
               and imp.tsl_mu_ind      = 'N'
               and ct.unit_cost        is NULL
               and NOT exists (select 'X'
                                 from item_master im2,
                                      packitem pi2,
                                      cost_change_trigger_temp ct2
                                where pi2.pack_no           = pi.pack_no
                                  and ct2.supplier          = ct.supplier
                                  and ct2.origin_country_id = ct.origin_country_id
                                  and ct2.active_date       = ct.active_date
                                  and im2.item              = pi2.item
                                  and ct2.item             = im2.item
                                  --20-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 Begin
                                   --or ct2.item              = im2.item_parent
                                  -- or ct2.item              = im2.item_grandparent)
                                   --20-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 End
                                  and ct2.unit_cost         is NOT NULL))
       for update nowait;
---
BEGIN
---
   if SYSTEM_OPTIONS_SQL.TSL_GET_APPLY_RP_LINK(O_error_message,
                                               L_apply_rp_link) = FALSE then
      return FALSE;
   end if;
---
   if L_apply_rp_link = 'Y' then
   ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_COMP_CC',
                       'ITEM_MASTER, ITEM_SUPP_COUNTRY_LOC, PACKITEM ,RECLASS_COST_CHG_QUEUE',
                       NULL);
      FOR C_rec in C_GET_COMP_CC
      LOOP
      ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_RP_COST',
                          'ITEM_SUPP_COUNTRY_LOC, RECLASS_COST_CHG_QUEUE, PACKITEM',
                          'Pack No: ' || C_rec.pack_no);
         open C_GET_RP_COST(C_rec.pack_no,
                            C_rec.supplier,
                            C_rec.origin_country_id,
                            C_rec.location,
                            C_rec.loc_type,
                            C_rec.start_date);
      ---
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_RP_COST',
                          'ITEM_SUPP_COUNTRY_LOC, RECLASS_COST_CHG_QUEUE, PACKITEM',
                          'Pack No: ' || C_rec.pack_no);
         fetch C_GET_RP_COST into L_rp_cost;
      ---
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_RP_COST',
                          'ITEM_SUPP_COUNTRY_LOC, RECLASS_COST_CHG_QUEUE, PACKITEM',
                          'Pack No: ' || C_rec.pack_no);
         close C_GET_RP_COST;
      ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_RP_REC_EXISTS',
                          'RECLASS_COST_CHG_QUEUE',
                          'Pack No: ' || C_rec.pack_no);
         open C_RP_REC_EXISTS(C_rec.pack_no,
                              C_rec.supplier,
                              C_rec.origin_country_id,
                              C_rec.location,
                              C_rec.loc_type,
                              C_rec.start_date);
      ---
         SQL_LIB.SET_MARK('FETCH',
                          'C_RP_REC_EXISTS',
                          'RECLASS_COST_CHG_QUEUE',
                          'Pack No: ' || C_rec.pack_no);
         fetch C_RP_REC_EXISTS into L_dummy;
      ---
         if C_RP_REC_EXISTS%NOTFOUND then
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'RECLASS_COST_CHG_QUEUE',
                             'Item : ' || C_REC.PACK_NO);
            insert into reclass_cost_chg_queue(item,
                                               supplier,
                                               origin_country_id,
                                               start_date,
                                               unit_cost,
                                               division,
                                               group_no,
                                               dept,
                                               class,
                                               subclass,
                                               location,
                                               loc_type,
                                               rec_type,
                                               process_flag)
                                        values(C_rec.pack_no,
                                               C_rec.supplier,
                                               C_rec.origin_country_id,
                                               C_rec.start_date,
                                               L_rp_cost,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               C_rec.location,
                                               C_rec.loc_type,
                                               'C',
                                               'N');
         else
         ---
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_RECLASS_COST_CHG_QUEUE1',
                             'RECLASS_COST_CHG_QUEUE',
                             'Item : ' || C_REC.PACK_NO);
            open C_LOCK_RECLASS_COST_CHG_QUEUE1(C_rec.pack_no,
                                                C_rec.supplier,
                                                C_rec.origin_country_id,
                                                C_rec.location,
                                                C_rec.loc_type,
                                                C_rec.start_date);
         ---
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_RECLASS_COST_CHG_QUEUE1',
                             'RECLASS_COST_CHG_QUEUE',
                             'Item : ' || C_REC.PACK_NO);
            close C_LOCK_RECLASS_COST_CHG_QUEUE1;
         ---
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'RECLASS_COST_CHG_QUEUE',
                             'Item : ' || C_REC.PACK_NO);
            update reclass_cost_chg_queue rcc
               set rcc.unit_cost         = L_rp_cost,
                   rcc.process_flag      = 'N'
             where rcc.item              = C_rec.pack_no
               and rcc.supplier          = C_rec.supplier
               and rcc.origin_country_id = C_rec.origin_country_id
               and rcc.location          = C_rec.location
               and rcc.loc_type          = C_rec.loc_type
               and rcc.start_date        = C_rec.start_date
               and rcc.rec_type          = 'C';
         end if;
      ---
         SQL_LIB.SET_MARK('CLOSE',
                          'C_RP_REC_EXISTS',
                          'RECLASS_COST_CHG_QUEUE',
                          'Pack No: ' || C_rec.pack_no);
         close C_RP_REC_EXISTS;
      ---
      END LOOP;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_RECLASS_COST_CHG_QUEUE2',
                       'RECLASS_COST_CHG_QUEUE',
                       NULL);
      open C_LOCK_RECLASS_COST_CHG_QUEUE2;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_RECLASS_COST_CHG_QUEUE2',
                       'RECLASS_COST_CHG_QUEUE',
                       NULL);
      close C_LOCK_RECLASS_COST_CHG_QUEUE2;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'RECLASS_COST_CHG_QUEUE',
                       NULL);
      update reclass_cost_chg_queue rcc
         set rcc.unit_cost    = NULL,
             rcc.division     = NULL,
             rcc.group_no     = NULL,
             rcc.dept         = NULL,
             rcc.class        = NULL,
             rcc.subclass     = NULL,
             rcc.rec_type     = 'G',
             rcc.process_flag = 'N'
       where rcc.rec_type     = 'C'
         -- MrgNBS010972 20-Jan-09, Merge from 3.3a to 3.3b - Begin
         -- DefNBS010565 24-Dec-08 Chandru Begin
         and exists (
              select 'X'
                from --item_master imc,
                     packitem pi,
                     cost_change_trigger_temp ct,
                     item_master imp
               where
                --21-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 Begin
                --imc.item            = pi.item
                -- and (ct.item            = imc.item
                -- or ct.item             = imc.item_parent
                  /* 18-Nov-2010 Murali N   NBS00019794 Begin */
                --  or ct.item             = imc.item_grandparent)
                -- and pi.pack_no          = imp.item
                  /* 18-Nov-2010 Murali N   NBS00019794 End */
                 --
                     pi.item  = ct.item
                 and imp.item    = pi.pack_no
                 --21-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 End
                 and imp.item             = rcc.item
                 and ct.supplier          = rcc.supplier
                 and ct.origin_country_id = rcc.origin_country_id
                 and ct.active_date       = rcc.start_date
         -- DefNBS010565 24-Dec-08 Chandru End
         -- MrgNBS010972 20-Jan-09, Merge from 3.3a to 3.3b - End
                 and imp.simple_pack_ind = 'N'
                 and imp.pack_ind        = 'Y'
                 and imp.pack_type       = 'V'
                 and imp.orderable_ind   = 'Y'
                 and imp.tsl_mu_ind      = 'N'
                 and ct.unit_cost        is NULL
                 and NOT exists (select 'X'
                                   from item_master im2,
                                        packitem pi2,
                                        cost_change_trigger_temp ct2
                                  where pi2.pack_no           = pi.pack_no
                                    and ct2.supplier          = ct.supplier
                                    and ct2.origin_country_id = ct.origin_country_id
                                    and ct2.active_date       = ct.active_date
                                    and im2.item              = pi2.item
                                    and ct2.item             = im2.item
                                    --21-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 Begin
                                    -- or ct2.item              = im2.item_parent
                                    -- or ct2.item              = im2.item_grandparent)
                                    --21-Oct-2011 Tesco HSC/Usha Patil        PrfNBS021857 End
                                    and ct2.unit_cost         is NOT NULL));
   end if;
---------------------------------------------------------
   -- PrfNBS016594, 28-Apr-2010, Manikandan V , Begin
   -- Below queries are included from the function of precostcalc_pre in the prepost batch

   SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'RECLASS_COST_CHG_QUEUE',
                             NULL);
   INSERT INTO
   reclass_cost_chg_queue (item,
                           supplier,
                           origin_country_id,
                           start_date,
                           unit_cost,
                           division,
                           group_no,
                           dept,
                           class,
                           subclass,
                           location,
                           loc_type,
                           rec_type,
                           process_flag)
                    SELECT im.item,
                           isc.supplier,
                           isc.origin_country_id,
                           rt.reclass_date,
                           NULL,
                           g.division,
                           d.group_no,
                           rt.dept,
                           rt.class,
                           rt.subclass,
                           -1,
                           NULL,
                           'R',
                           'N'
                      FROM reclass_trigger_temp rt,
                           item_master im,
                           item_supp_country isc,
                           groups g,
                           deps d
                     WHERE (im.item = rt.item
                            OR im.item_parent = rt.item
                            OR im.item_grandparent = rt.item)
                       AND im.item_level = im.tran_level
                       AND isc.item = rt.item
                       AND d.dept = rt.dept
                       AND d.group_no = g.group_no
                       AND rt.dept IS NOT NULL        /* values in the d/c/s columns */
                       AND rt.class IS NOT NULL       /* indicate that the item was  */
                       AND rt.subclass IS NOT NULL    /* added to a reclassification */
                       AND NOT EXISTS(SELECT 'X'
                                        FROM reclass_cost_chg_queue rccq
                                       WHERE (im.item = rccq.item
                                          OR im.item_parent = rccq.item
                                          OR im.item_grandparent = rccq.item)
                                         AND isc.item = rt.item
                                         AND isc.supplier = rccq.supplier
                                         AND isc.origin_country_id = rccq.origin_country_id
                                         AND rt.reclass_date = rccq.start_date
                                         AND rccq.location = '-1'
                                         AND rccq.rec_type = 'R');

   SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'RECLASS_COST_CHG_QUEUE',
                             NULL);

   INSERT INTO
   reclass_cost_chg_queue (item,
                           supplier,
                           origin_country_id,
                           start_date,
                           unit_cost,
                           division,
                           group_no,
                           dept,
                           class,
                           subclass,
                           location,
                           loc_type,
                           rec_type,
                           process_flag)
                    SELECT im.item,
                           isc.supplier,
                           isc.origin_country_id,
                           rt.reclass_date,
                           NULL,
                           g.division,
                           d.group_no,
                           rt.dept,
                           rt.class,
                           rt.subclass,
                           -1,
                           NULL,
                           'R',
                           'N'
                      FROM reclass_trigger_temp rt,
                           item_master im,
                           (select pib.pack_no,
                                   rt.item
                              from item_master im,
                                   packitem_breakout pib,
                                   reclass_trigger_temp rt
                             where (im.item = rt.item
                                    OR im.item_parent = rt.item
                                    OR im.item_grandparent = rt.item)
                               --20-Oct-2011 Tesco HSC/Usha Patil       PrfNBS021857 Begin
                               AND rt.dept IS NOT NULL        /* values in the d/c/s columns */
                               AND rt.class IS NOT NULL       /* indicate that the item was  */
                               AND rt.subclass IS NOT NULL    /* added to a reclassification */
                               --20-Oct-2011 Tesco HSC/Usha Patil       PrfNBS021857 End
                               AND pib.item = im.item) pib,
                           item_supp_country isc,
                           groups g,
                           deps d
                     WHERE im.item = pib.pack_no
                       and rt.item = pib.item
                       AND im.item_level = im.tran_level
                       AND im.simple_pack_ind = 'Y'
                       AND im.status = 'A'
                       AND isc.item = pib.pack_no
                       AND d.dept = rt.dept
                       AND d.group_no = g.group_no
                       AND rt.dept IS NOT NULL        /* values in the d/c/s columns */
                       AND rt.class IS NOT NULL       /* indicate that the item was  */
                       AND rt.subclass IS NOT NULL    /* added to a reclassification */
                       AND NOT EXISTS(SELECT 'X'
                                        FROM reclass_cost_chg_queue rccq
                                       WHERE im.item = rccq.item
                                         AND isc.supplier = rccq.supplier
                                         AND isc.origin_country_id = rccq.origin_country_id
                                         AND rt.reclass_date = rccq.start_date
                                         AND rccq.location = '-1'
                                         AND rccq.rec_type = 'R');

     SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'RECLASS_COST_CHG_QUEUE',
                             NULL);
     UPDATE reclass_cost_chg_queue rq
               SET rq.division = NULL,
                   rq.group_no = NULL,
                   rq.dept = NULL,
                   rq.class = NULL,
                   rq.subclass = NULL,
                   rq.rec_type = 'G',
                   rq.process_flag = 'N'
             WHERE rq.rec_type = 'R'
               AND EXISTS (SELECT 'x'
                             FROM reclass_trigger_temp rt,
                                  item_master im
                            WHERE (rt.item = im.item
                                   OR rt.item = im.item_parent
                                   OR rt.item = im.item_grandparent)
                              AND im.item_level = im.tran_level
                              AND im.item = rq.item
                              AND rt.reclass_date = rq.start_date
                              AND rt.dept IS NULL                  /* NULL values in d/c/s columns indicate */
                              AND rt.class IS NULL                 /* that the item was removed from an     */
                              AND rt.subclass IS NULL);            /* existing reclassification             */

   SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'RECLASS_COST_CHG_QUEUE',
                             NULL);

   UPDATE reclass_cost_chg_queue rq
               SET rq.division = NULL,
                   rq.group_no = NULL,
                   rq.dept = NULL,
                   rq.class = NULL,
                   rq.subclass = NULL,
                   rq.rec_type = 'G',
                   rq.process_flag = 'N'
             WHERE rq.rec_type = 'R'
               AND EXISTS (SELECT 'x'
                             FROM reclass_trigger_temp rt,
                                  packitem_breakout pib,
                                  item_master im
                            WHERE im.item = pib.pack_no
                              AND EXISTS (SELECT 'x'
                                            FROM item_master im1
                                           WHERE pib.item = im1.item
                                             AND im1.item_level = im1.tran_level
                                             AND (rt.item = im1.item
                                                  OR rt.item = im1.item_parent
                                                  OR rt.item = im1.item_grandparent))
                              AND im.pack_ind = 'Y'
                              AND im.status = 'A'
                              AND im.item_level = im.tran_level
                              AND im.item = rq.item
                              AND rt.reclass_date = rq.start_date
                              AND rt.dept IS NULL                  /* NULL values in d/c/s columns indicate */
                              AND rt.class IS NULL                 /* that the item was removed from an     */
                              AND rt.subclass IS NULL);            /* existing reclassification             */

   -- PrfNBS016594, 28-Apr-2010, Manikandan V , End
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                           'RECLASS_COST_CHG_QUEUE',
                                           L_program,
                                           NULL);
      return FALSE;
   when OTHERS then
      if C_GET_COMP_CC%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_COMP_CC',
                          'ITEM_MASTER, ITEM_SUPP_COUNTRY_LOC, PACKITEM ,RECLASS_COST_CHG_QUEUE',
                          NULL);
      end if;
      if C_GET_RP_COST%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_RP_COST',
                          'ITEM_SUPP_COUNTRY_LOC, RECLASS_COST_CHG_QUEUE, PACKITEM',
                          NULL);
      end if;
      if C_RP_REC_EXISTS%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_RP_REC_EXISTS',
                          'RECLASS_COST_CHG_QUEUE',
                          NULL);
      end if;
      if C_LOCK_RECLASS_COST_CHG_QUEUE1%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_RECLASS_COST_CHG_QUEUE1',
                          'RECLASS_COST_CHG_QUEUE',
                           NULL);
      end if;
      if C_LOCK_RECLASS_COST_CHG_QUEUE2%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_RECLASS_COST_CHG_QUEUE2',
                           'RECLASS_COST_CHG_QUEUE',
                           NULL);
      end if;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END TSL_INSERT_RP_COST_CCQ;
---------------------------------------------------------------------------------------------------------------
---10-Mar-2008 Wipro Enabler / Shekar Radhakrishnan - Mod:n53 - End
---------------------------------------------------------------------------------------------------------------
END COST_EXTRACT_SQL ;
/

