CREATE OR REPLACE PACKAGE BODY INVADJ_SQL AS
---------------------------------------------------------------------------------------------
-- Mod By     : Vipindas Thekke Purakkal, vipindas.thekkepurakkal@in.tesco.com
-- Mod Date   : 25-Oct-2007
-- Mod Ref    : Mod N108
-- Mod Details: Added a new parameter I_ref_no_2 in function BUILD_ADJ_TRAN_DATA
---------------------------------------------------------------------------------------------
-- Mod By     : Vipindas Thekke Purakkal, vipindas.thekkepurakkal@in.tesco.com
-- Mod Date   : 10-Jan-2008
-- Mod Ref    : DefNBS004437
-- Mod Details: In function BUILD_ADJ_TRAN_DATA, modified the call to STKLEDGR_SQL.BUILD_TRAN_DATA_INSERT
--              to pass value instead of NULL to ref_no_2 parameter
---------------------------------------------------------------------------------------------
--Mod By:      Murali Krishnan
--Mod Date:    28-Oct-2008
--Mod Ref:     Back Port Oracle fix(6330821,6907185,6840037)
--Mod Details: Back ported the oracle fix for Bug 6330821,6907185,6840037.Modified the function BUILD_ADJ_TRAN_DATA,
--             BUILD_ADJ_STOCK_ON_HAND,FLUSH_SOH_UPDATE.
---------------------------------------------------------------------------------------------
-- Mod By     : Nandini Mariyappa,Nandini.Mariyappa@in.tesco.com
-- Mod Date   : 06-Jan-2009
-- Def Ref    : PrfNBS010460 and NBS00010460
-- Def Details: Code has modified for performance related issues in RIB.
---------------------------------------------------------------------------------------------
--- Global cache for item_loc_soh update
TYPE ilsoh_item_TBL              is table of ITEM_LOC_SOH.ITEM%TYPE              INDEX BY BINARY_INTEGER;
TYPE ilsoh_loc_TBL               is table of ITEM_LOC_SOH.LOC%TYPE               INDEX BY BINARY_INTEGER;
TYPE ilsoh_qty_TBL               is table of ITEM_LOC_SOH.STOCK_ON_HAND%TYPE     INDEX BY BINARY_INTEGER;
TYPE ilsoh_pcsoh_TBL             is table of ITEM_LOC_SOH.PACK_COMP_SOH%TYPE     INDEX BY BINARY_INTEGER;
TYPE ilsoh_non_sell_qty_TBL      is table of ITEM_LOC_SOH.NON_SELLABLE_QTY%TYPE  INDEX BY BINARY_INTEGER;
TYPE pack_qty_TBL                is table of V_PACKSKU_QTY.QTY%TYPE              INDEX BY BINARY_INTEGER;
TYPE ilsoh_avg_wgt_TBL           is table of ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE    INDEX BY BINARY_INTEGER;
TYPE ilsoh_date_TBL              is table of ITEM_LOC_SOH.CREATE_DATETIME%TYPE   INDEX BY BINARY_INTEGER;
TYPE ilsoh_user_TBL              is table of ITEM_LOC_SOH.LAST_UPDATE_ID%TYPE    INDEX BY BINARY_INTEGER;

TYPE isq_item_TBL                is table of INV_STATUS_QTY.ITEM%TYPE            INDEX BY BINARY_INTEGER;
TYPE isq_status_TBL              is table of INV_STATUS_QTY.INV_STATUS%TYPE      INDEX BY BINARY_INTEGER;
TYPE isq_loc_type_TBL            is table of INV_STATUS_QTY.LOC_TYPE%TYPE        INDEX BY BINARY_INTEGER;
TYPE isq_loc_TBL                 is table of INV_STATUS_QTY.LOCATION%TYPE        INDEX BY BINARY_INTEGER;
TYPE isq_qty_TBL                 is table of INV_STATUS_QTY.QTY%TYPE             INDEX BY BINARY_INTEGER;
TYPE isq_date_TBL                is table of INV_STATUS_QTY.CREATE_DATETIME%TYPE INDEX BY BINARY_INTEGER;
TYPE isq_user_TBL                is table of INV_STATUS_QTY.LAST_UPDATE_ID%TYPE  INDEX BY BINARY_INTEGER;

TYPE isq_ind_TBL                 is table of VARCHAR2(1)                         INDEX BY BINARY_INTEGER;

TYPE ia_item_TBL                is table of INV_ADJ.ITEM%TYPE          INDEX BY BINARY_INTEGER;
TYPE ia_status_TBL              is table of INV_ADJ.INV_STATUS%TYPE    INDEX BY BINARY_INTEGER;
TYPE ia_loc_type_TBL            is table of INV_ADJ.LOC_TYPE%TYPE      INDEX BY BINARY_INTEGER;
TYPE ia_loc_TBL                 is table of INV_ADJ.LOCATION%TYPE      INDEX BY BINARY_INTEGER;
TYPE ia_qty_TBL                 is table of INV_ADJ.ADJ_QTY%TYPE       INDEX BY BINARY_INTEGER;
TYPE ia_reason_TBL              is table of INV_ADJ.REASON%TYPE        INDEX BY BINARY_INTEGER;
TYPE ia_date_TBL                is table of INV_ADJ.ADJ_DATE%TYPE      INDEX BY BINARY_INTEGER;
TYPE ia_prev_qty_TBL            is table of INV_ADJ.PREV_QTY%TYPE      INDEX BY BINARY_INTEGER;
TYPE ia_user_TBL                is table of INV_ADJ.USER_ID%TYPE       INDEX BY BINARY_INTEGER;

TYPE inv_status_codes_TBL is table of inv_status_codes%ROWTYPE;
TYPE inv_status_types_TBL is table of inv_status_types%ROWTYPE;

LP_inv_status_codes       inv_status_codes_TBL;
LP_inv_status_types       inv_status_types_TBL;

---
LP_prev_item              ITEM_MASTER.ITEM%TYPE;
LP_item_parent            ITEM_MASTER.ITEM_PARENT%TYPE;
LP_tran_level             ITEM_MASTER.TRAN_LEVEL%TYPE;
LP_item_level             ITEM_MASTER.ITEM_LEVEL%TYPE;
LP_pack_ind               ITEM_MASTER.PACK_IND%TYPE;
LP_simple_pack_ind        ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
LP_catch_weight_ind       ITEM_MASTER.CATCH_WEIGHT_IND%TYPE;

LP_userid                 INV_ADJ.USER_ID%TYPE := user;
LP_vdate                  PERIOD.VDATE%TYPE := GET_VDATE;

P_ia_item                 ia_item_TBL;
P_ia_status               ia_status_TBL;
P_ia_loc_type             ia_loc_type_TBL;
P_ia_loc                  ia_loc_TBL;
P_ia_qty                  ia_qty_TBL;
P_ia_reason               ia_reason_TBL;
P_ia_date                 ia_date_TBL;
P_ia_prev_qty             ia_prev_qty_TBL;
P_ia_user                 ia_user_TBL;
P_ia_size                 NUMBER := 0;

P_ilsoh_item              ilsoh_item_TBL;
P_ilsoh_loc               ilsoh_loc_TBL;
P_ilsoh_adj_qty           ilsoh_qty_TBL;
P_ilsoh_pcsoh_adj_qty     ilsoh_pcsoh_TBL;
P_ilsoh_non_sell_qty      ilsoh_non_sell_qty_TBL;
P_ilsoh_average_weight    ilsoh_avg_wgt_TBL;
P_ilsoh_date              ilsoh_date_TBL;
P_ilsoh_user              ilsoh_user_TBL;
P_ilsoh_size              NUMBER := 0;

P_isq_item            isq_item_TBL;
P_isq_status          isq_status_TBL;
P_isq_loc_type        isq_loc_type_TBL;
P_isq_loc             isq_loc_TBL;
P_isq_qty             isq_qty_TBL;
P_isq_date            isq_date_TBL;
P_isq_user            isq_user_TBL;
---
-- P_isq_insert_ind is an indicator specifying whether the current
-- record should be inserted into the table inv_status_qty.  It is
-- set to 'Y' if there is currently no corresponding record on the
-- database table inv_status_qty.  It is set to 'N' if there is
-- a record currently on the table.
---
P_isq_insert_ind      isq_ind_TBL;
---
-- P_isq_deleted_ind is an indicator specifying whether the current
-- record should be deleted from the table inv_status_qty.  It is
-- set to 'Y' if the quantity for the current record goes down to 0.
-- If the quantity is set to anything other than 0, this is set to 'N'
---
P_isq_deleted_ind     isq_ind_TBL;
P_isq_size            NUMBER := 0;
---


---------------------------------------------------------------------------------------------
-- Function Name: UPD_NON_SELLABLE_QTY
-- Purpose      : Updates the non-sellable quantity on ITEM_LOC_SOH for the specified
--                item/loc.  This is called when the inventory is unavailable.
---------------------------------------------------------------------------------------------
FUNCTION UPD_NON_SELLABLE_QTY(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item            IN       ITEM_MASTER.ITEM%TYPE,
                              I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                              I_location        IN       INV_ADJ.LOCATION%TYPE,
                              I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: PROCESS_AVAILABLE
-- Purpose      : This is called when the inv_status specifies that the inventory is
--                available.  The appropriate tables are updated to reflect the available
--                inventory.
---------------------------------------------------------------------------------------------
FUNCTION PROCESS_AVAILABLE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_inv_adj         IN       INV_ADJ%ROWTYPE,
                           I_adj_weight      IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                           I_adj_weight_uom  IN       UOM_CLASS.UOM%TYPE,
                           I_vdate           IN       DATE,
                           I_pgm_name        IN       TRAN_DATA.PGM_NAME%TYPE,
                           I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                           I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                           I_pack_ind        IN       ITEM_MASTER.PACK_IND%TYPE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: PROCESS_UNAVAILABLE
-- Purpose      : This is called when the inv_status specifies that the inventory is
--                unavailable.  The appropriate tables are updated to reflect the unavailable
--                inventory.
---------------------------------------------------------------------------------------------
FUNCTION PROCESS_UNAVAILABLE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_inv_adj         IN       INV_ADJ%ROWTYPE,
                             I_adj_weight      IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                             I_adj_weight_uom  IN       UOM_CLASS.UOM%TYPE,
                             I_pgm_name        IN       TRAN_DATA.PGM_NAME%TYPE,
                             I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                             I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                             I_pack_ind        IN       ITEM_MASTER.PACK_IND%TYPE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: CREATE_ITEM_LOC_REL
-- Purpose      : Creates the item/location relationship by calling NEW_ITEM_LOC.
---------------------------------------------------------------------------------------------
FUNCTION CREATE_ITEM_LOC_REL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_item            IN       INV_ADJ.ITEM%TYPE,
                             I_location        IN       INV_ADJ.LOCATION%TYPE,
                             I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                             I_item_level      IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                             I_tran_level      IN       ITEM_MASTER.TRAN_LEVEL%TYPE,
                             I_pack_ind        IN       ITEM_MASTER.PACK_IND%TYPE,
                             I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: VALIDATE_INVADJ
-- Purpose      : Validates the item, location, inv_status, and reason.
---------------------------------------------------------------------------------------------
FUNCTION VALIDATE_INVADJ(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_pack_ind         IN OUT   ITEM_MASTER.PACK_IND%TYPE,
                         O_simple_pack_ind  IN OUT   ITEM_MASTER.SIMPLE_PACK_IND%TYPE,
                         O_catch_weight_ind IN OUT   ITEM_MASTER.CATCH_WEIGHT_IND%TYPE,
                         IO_inv_adj         IN OUT   INV_ADJ%ROWTYPE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: ITEM_LOC_EXIST
-- Purpose      : Checks to see if the item/location exists on item_loc_soh.  Also
--                gets the current qty on inv_status_qty by calling GET_INV_STATUS_QTY.
---------------------------------------------------------------------------------------------
FUNCTION ITEM_LOC_EXIST (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_stock_on_hand   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         O_found           IN OUT   BOOLEAN,
                         I_item            IN       ITEM_MASTER.ITEM%TYPE,
                         I_location        IN       ITEM_LOC_SOH.LOC%TYPE,
                         I_loc_type        IN       ITEM_LOC_SOH.LOC_TYPE%TYPE,
                         I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: STOCKHOLDING_INVADJ
-- Purpose      : Adjusts the inventory for the item and location specified.
---------------------------------------------------------------------------------------------
FUNCTION STOCKHOLDING_INVADJ(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_location        IN       INV_ADJ.LOCATION%TYPE,
                             I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                             I_item            IN       INV_ADJ.ITEM%TYPE,
                             I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                             I_reason          IN       INV_ADJ.REASON%TYPE,
                             I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                             I_adj_weight      IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                             I_adj_weight_uom  IN       UOM_CLASS.UOM%TYPE,
                             I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE,
                             I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                             I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                             I_user_id         IN       INV_ADJ.USER_ID%TYPE,
                             I_vdate           IN       DATE,
                             I_pgm_name        IN       TRAN_DATA.PGM_NAME%TYPE)
RETURN BOOLEAN;
--------------------------------------------------------------------------------
-- Function Name: GET_SYSTEM_INFO
-- Purpose      : Gets the vdate from the period table, and the multichannel indicator
--                from the system_options table.
---------------------------------------------------------------------------------------------
FUNCTION GET_SYSTEM_INFO(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_multichannel_ind   IN OUT   SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE,
                         O_vdate              IN OUT   DATE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: GET_INV_STATUS_QTY
-- Purpose      : Gets the qty from the table INV_STATUS_QTY.  Because bulk binding is being
--                used for all of the inserts/updates/deletes to the inv_status_qty table,
--                we need to check the PL/SQL table used for bulk binding as well as
--                the database table.
---------------------------------------------------------------------------------------------
FUNCTION GET_INV_STATUS_QTY (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_qty             IN OUT   INV_STATUS_QTY.QTY%TYPE,
                             O_tbl_index       IN OUT   BINARY_INTEGER,
                             I_item            IN       ITEM_MASTER.ITEM%TYPE,
                             I_location        IN       ITEM_LOC_SOH.LOC%TYPE,
                             I_loc_type        IN       ITEM_LOC_SOH.LOC_TYPE%TYPE,
                             I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: ADD_ILSOH_UPDATE_REC
-- Purpose      : Adds a record to the PL/SQL table used for bulk updates to item_loc_soh.
---------------------------------------------------------------------------------------------
FUNCTION ADD_ILSOH_UPDATE_REC(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item             IN       ITEM_MASTER.ITEM%TYPE,
                              I_location         IN       ITEM_LOC_SOH.LOC%TYPE,
                              I_soh_adj_qty      IN       ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                              I_pcsoh_adj_qty    IN       ITEM_LOC_SOH.PACK_COMP_SOH%TYPE,
                              I_non_sell_qty     IN       ITEM_LOC_SOH.NON_SELLABLE_QTY%TYPE,
                              I_average_weight   IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE)
RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
-- Function Name: GET_INV_STATUS_TYPES
-- Purpose      : Checks for the existence of the input inv_status
--                in the table inv_status_types.  The database table is cached in the global
--                variable LP_inv_status_types, since it is a small table that could
--                potentially be queried many times.
---------------------------------------------------------------------------------------------
FUNCTION GET_INV_STATUS_TYPES(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE)
   RETURN BOOLEAN;
--------------------------------------------------------------------------------------------
FUNCTION ADJ_STOCK_ON_HAND(I_item            IN       ITEM_MASTER.ITEM%TYPE,
                           I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                           I_location        IN       INV_ADJ.LOCATION%TYPE,
                           I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                           O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_found           IN OUT   BOOLEAN)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'INVADJ_SQL.ADJ_STOCK_ON_HAND';

   L_pack_ind        ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind    ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind   ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type       ITEM_MASTER.PACK_TYPE%TYPE;

BEGIN

   --empty out cache of update statements for item_loc_soh
   if INIT_SOH_UPDATE (O_error_message) = FALSE then
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;

   if BUILD_ADJ_STOCK_ON_HAND(O_error_message,
                              O_found,
                              I_item,
                              I_loc_type,
                              I_location,
                              I_adj_qty,
                              NULL,      --I_adj_weight
                              NULL,      --I_adj_weight_uom
                              L_pack_ind) = FALSE then
      return FALSE;
   end if;

   --call flush
   if FLUSH_SOH_UPDATE (O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END ADJ_STOCK_ON_HAND;
--------------------------------------------------------------------------------------------
FUNCTION BUILD_ADJ_STOCK_ON_HAND(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_found           IN OUT   BOOLEAN,
                                 I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                 I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                                 I_location        IN       INV_ADJ.LOCATION%TYPE,
                                 I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                                 I_adj_weight      IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                                 I_adj_weight_uom  IN       UOM_CLASS.UOM%TYPE,
                                 I_pack_ind        IN       ITEM_MASTER.PACK_IND%TYPE)
   RETURN BOOLEAN IS

   L_program           VARCHAR2(64) := 'INVADJ_SQL.BUILD_ADJ_STOCK_ON_HAND';
   L_item              ITEM_MASTER.ITEM%TYPE;
   L_soh_adj_qty       INV_ADJ.ADJ_QTY%TYPE := NULL;
   L_pcsoh_adj_qty     INV_ADJ.ADJ_QTY%TYPE := NULL;
   L_pcsoh_pack_qty    INV_ADJ.ADJ_QTY%TYPE := NULL;
   L_comp_items_TBL    PACKITEM_ATTRIB_SQL.COMP_ITEM_TBL;
   L_comp_qtys_TBL     PACKITEM_ATTRIB_SQL.COMP_QTY_TBL;

   L_qty               V_PACKSKU_QTY.QTY%TYPE;
   L_receive_as_type   ITEM_LOC.RECEIVE_AS_TYPE%TYPE;
   L_item_rec          ITEM_MASTER%ROWTYPE;
   L_new_avg_weight    ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_upd_qty           ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;
   L_cuom              ITEM_SUPP_COUNTRY.COST_UOM%TYPE;

   L_table             VARCHAR2(20) := 'ITEM_LOC_SOH';
   RECORD_LOCKED       EXCEPTION;
   PRAGMA              EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_SOH is
      select stock_on_hand + in_transit_qty
             + NVL(pack_comp_soh,0)
             + NVL(pack_comp_intran,0) total_qty,
             average_weight
        from item_loc_soh
       where item     = L_item
         and loc      = I_location
         for update nowait;

   L_sohcur_rec    C_LOCK_SOH%ROWTYPE;

BEGIN
   ---
   O_found := TRUE;

   --- Weight and weight UOM must be both populated or both null
   if I_adj_weight is NULL and I_adj_weight_uom is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('WGT_WGTUOM_REQUIRED',NULL,
                                            NULL,NULL);
      return FALSE;
   elsif I_adj_weight_uom is NULL and I_adj_weight is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('WGT_WGTUOM_REQUIRED',NULL,
                                            NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_pack_ind = 'N' then
      L_item := I_item;
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
      open C_LOCK_SOH;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_SOH','ITEM_LOC_SOH','Item: '||L_item||' Loc: '||to_char(I_location));
      close C_LOCK_SOH;
      ---
      if ADD_ILSOH_UPDATE_REC(O_error_message,
                              L_item,
                              I_location,
                              I_adj_qty,
                              0,                   ---I_pcsoh_adj_qty
                              0,                   ---I_non_sell_qty
                              NULL) = FALSE then   ---I_average_weight
         return FALSE;
      end if;
      ---
   else  -- pack item
      L_item := I_item;

      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_rec,
                                         L_item) = FALSE then
         return FALSE;
      end if;

      if ITEMLOC_ATTRIB_SQL.GET_RECEIVE_AS_TYPE(O_error_message,
                                                L_receive_as_type,
                                                L_item,
                                                I_location) = FALSE then
         return FALSE;
      end if;
      ---
      if L_receive_as_type = 'P' then
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
         open C_LOCK_SOH;
         -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
         -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
         close C_LOCK_SOH;
         ---
         if ADD_ILSOH_UPDATE_REC(O_error_message,
                                 L_item,
                                 I_location,
                                 I_adj_qty,
                                 0,                   ---I_pcsoh_adj_qty
                                 0,                   ---I_non_sell_qty
                                 L_new_avg_weight) = FALSE then
            return FALSE;
         end if;
         ---
      end if;
      ---
      if PACKITEM_ATTRIB_SQL.GET_COMP_QTYS(O_error_message,
                                           L_comp_items_TBL,
                                           L_comp_qtys_TBL,
                                           L_item) = FALSE then
         return FALSE;
      end if;

      FOR i in 1..L_comp_items_TBL.COUNT LOOP
         L_item := L_comp_items_TBL(i);
         ---
         if L_item_rec.simple_pack_ind = 'Y'  and
            L_item_rec.catch_weight_ind = 'Y' then
            -- calculate update qty
            if CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY(O_error_message,
                                                     L_upd_qty,
                                                     L_item,  -- component
                                                     I_adj_qty*L_comp_qtys_TBL(i),
                                                     -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
                                                     NULL,
                                                     NULL,
                                                     -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
                                                     I_item,  -- pack
                                                     I_location,
                                                     I_loc_type,
                                                     I_adj_qty) = FALSE then
               return FALSE;
            end if;
            --- Set units
            if I_loc_type = 'S' then
               L_soh_adj_qty := L_upd_qty;
               L_pcsoh_adj_qty := 0;
            else
               if L_receive_as_type = 'P' then
                  L_soh_adj_qty := 0;
                  L_pcsoh_adj_qty := L_upd_qty;
               else
                  L_soh_adj_qty := L_upd_qty;
                  L_pcsoh_adj_qty := 0;
               end if;
            end if;

         else  --- Not catch weight item, process as usual
            if I_loc_type = 'S' then
               L_soh_adj_qty := I_adj_qty * L_comp_qtys_TBL(i);
               L_pcsoh_adj_qty := 0;
            else
               if L_receive_as_type = 'P' then
                  L_soh_adj_qty := 0;
                  L_pcsoh_adj_qty := I_adj_qty * L_comp_qtys_TBL(i);
               else
                  L_soh_adj_qty := I_adj_qty * L_comp_qtys_TBL(i);
                  L_pcsoh_adj_qty := 0;
               end if;
            end if;

         end if; -- catch weight/simple pack inds
                    ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_SOH','ITEM_LOC_SOH','Item: '||L_item||' Loc: '||to_char(I_location));
         open C_LOCK_SOH;
         ---
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_SOH','ITEM_LOC_SOH','Item: '||L_item||' Loc: '||to_char(I_location));
         close C_LOCK_SOH;
         ---
         if ADD_ILSOH_UPDATE_REC(O_error_message,
                                 L_item,
                                 I_location,
                                 L_soh_adj_qty,
                                 L_pcsoh_adj_qty,
                                 0,                   ---I_non_sell_qty
                                 NULL) = FALSE then   ---I_average_weight
            return FALSE;
         end if;

      END LOOP;
   end if;  -- pack_ind = 'N'
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('REC_LOCK_ITEM_LOC',
                                            L_table,
                                            L_item,
                                            to_char(I_location));
      O_found := FALSE;
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END BUILD_ADJ_STOCK_ON_HAND;
---------------------------------------------------------------------------------------------
FUNCTION UPD_NON_SELLABLE_QTY(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item            IN       ITEM_MASTER.ITEM%TYPE,
                              I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                              I_location        IN       INV_ADJ.LOCATION%TYPE,
                              I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_SQL.UPD_NON_SELLABLE_QTY';

   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   L_table         VARCHAR2(30):= 'ITEM_LOC_SOH';

   cursor C_LOCK_LOC is
      select 'x'
        from item_loc_soh
       where item     = I_item
         and loc      = I_location
         for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_LOCK_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
   open C_LOCK_LOC;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
   close C_LOCK_LOC;
   ---
   if ADD_ILSOH_UPDATE_REC(O_error_message,
                           I_item,
                           I_location,
                           0,
                           0,                   ---I_pcsoh_adj_qty
                           I_adj_qty,           ---I_non_sell_qty
                           NULL) = FALSE then      ---average weight
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := O_error_message||SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                             L_table,
                                                             to_char(I_location),
                                                             I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPD_NON_SELLABLE_QTY;
--------------------------------------------------------------------------------------------
FUNCTION ADJ_UNAVAILABLE(I_item            IN       ITEM_MASTER.ITEM%TYPE,
                         I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                         I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                         I_location        IN       INV_ADJ.LOCATION%TYPE,
                         I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                         O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_found           IN OUT   BOOLEAN)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'INVADJ_SQL.ADJ_UNAVAILABLE';

   L_pack_ind        ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind    ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind   ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type       ITEM_MASTER.PACK_TYPE%TYPE;
   ---
   L_comp_items_TBL  PACKITEM_ATTRIB_SQL.comp_item_TBL;
   L_comp_qtys_TBL   PACKITEM_ATTRIB_SQL.comp_qty_TBL;
   L_comp_item       INV_ADJ.ITEM%TYPE := NULL;
   L_comp_adj_qty    INV_ADJ.ADJ_QTY%TYPE := NULL;

BEGIN

   --empty out cache of update statements for item_loc_soh
   if INIT_SOH_UPDATE (O_error_message) = FALSE then
      return FALSE;
   end if;

   --empty out cache of insert, update, and delete statements for inv_status_qty
   if INIT_INV_STAT_QTY (O_error_message) = FALSE then
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;

   if L_pack_ind = 'Y' and I_loc_type = 'S' then

      if PACKITEM_ATTRIB_SQL.GET_COMP_QTYS(O_error_message,
                                           L_comp_items_TBL,
                                           L_comp_qtys_TBL,
                                           I_item) = FALSE then
         return FALSE;
      end if;

      FOR i in 1..L_comp_items_TBL.COUNT LOOP
         L_comp_item := L_comp_items_TBL(i);
         L_comp_adj_qty := I_adj_qty * L_comp_qtys_TBL(i);

         if BUILD_ADJ_UNAVAILABLE(O_error_message,
                                  O_found,
                                  L_comp_item,
                                  I_inv_status,
                                  I_loc_type,
                                  I_location,
                                  L_comp_adj_qty) = FALSE then
            return FALSE;
         end if;
      END LOOP;

   else

      if BUILD_ADJ_UNAVAILABLE(O_error_message,
                               O_found,
                               I_item,
                               I_inv_status,
                               I_loc_type,
                               I_location,
                               I_adj_qty) = FALSE then
         return FALSE;
      end if;

   end if;

   --call flush
   if FLUSH_SOH_UPDATE (O_error_message) = FALSE then
      return FALSE;
   end if;

   --call flush
   if FLUSH_INV_STAT_QTY (O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END ADJ_UNAVAILABLE;
---------------------------------------------------------------------------------------------
FUNCTION BUILD_ADJ_UNAVAILABLE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                               O_found           IN OUT   BOOLEAN,
                               I_item            IN       ITEM_MASTER.ITEM%TYPE,
                               I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                               I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                               I_location        IN       INV_ADJ.LOCATION%TYPE,
                               I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(64)   := 'INVADJ_SQL.BUILD_ADJ_UNAVAILABLE';
   L_qty          INV_STATUS_QTY.QTY%TYPE;

   L_isq_index         BINARY_INTEGER := 0;

BEGIN
   O_found := TRUE;

   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
   --Following RIB error message has modified as the part of Performance issue.

   /*if ((I_item is NULL) OR (I_inv_status is NULL) OR (I_loc_type is NULL) OR
        (I_location is NULL) OR (I_adj_qty is NULL)) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',NULL,NULL,NULL);
      return FALSE;
   end if;*/
   --RIB error message enhancement
   if (I_item is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','item','NULL','NOT NULL');
      return FALSE;
   end if;

   if (I_inv_status is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','inv status','NULL','NOT NULL');
      return FALSE;
   end if;

   if (I_loc_type is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','loc type','NULL','NOT NULL');
      return FALSE;
   end if;

   if (I_location is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','location','NULL','NOT NULL');
      return FALSE;
   end if;

   if (I_adj_qty is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','adj qty','NULL','NOT NULL');
      return FALSE;
   end if;
   --RIB error message enhancement
   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End

   if GET_INV_STATUS_QTY (O_error_message,
                          L_qty,
                          L_isq_index,
                          I_item,
                          I_location,
                          I_loc_type,
                          I_inv_status) = FALSE then
      return FALSE;
   end if;

   ---
   -- There are 2 conditions for which L_qty can be 0
   -- for the current item/location/inv_status
   --    1.  There is no record on the database - if this is the case,
   --          the insert_ind should be NULL
   --
   --    2.  There is a record on the database, but it is
   --        currently marked for bulk deletion
   --        (ie deleted_ind in the PL/SQL table = 'Y')
   ---
   if L_qty = 0 then
      P_isq_qty(L_isq_index)  := I_adj_qty;
      P_isq_date(L_isq_index) := SYSDATE;
      P_isq_user(L_isq_index) := LP_userid;
      ---
      -- If the insert_ind is NULL and L_qty = 0,
      -- there is no record on the database.
      -- Set the insert ind to 'Y' to insert the record.
      ---
      if P_isq_insert_ind(L_isq_index) is NULL then
         P_isq_insert_ind(L_isq_index) := 'Y';
      end if;
      P_isq_deleted_ind(L_isq_index) := 'N';

      if L_qty + I_adj_qty < 0 then
         O_found := FALSE;
      end if;

   ---
   -- If the total quantity equals 0, delete the record.
   ---
   elsif L_qty + I_adj_qty = 0 then
      P_isq_qty(L_isq_index) := L_qty + I_adj_qty;
      P_isq_date(L_isq_index) := SYSDATE;
      P_isq_user(L_isq_index) := LP_userid;
      ---
      -- If the insert_ind is NULL and L_qty != 0,
      -- there is a record on the database.
      -- Set the insert ind to 'N' so that the record
      -- is not inserted.
      ---
      if P_isq_insert_ind(L_isq_index) is NULL then
         P_isq_insert_ind(L_isq_index) := 'N';
      end if;
      P_isq_deleted_ind(L_isq_index) := 'Y';

   ---
   -- If the total quantity does not equal 0, update the record with the new quantity.
   ---
   else
      P_isq_qty(L_isq_index)  := L_qty + I_adj_qty;
      P_isq_date(L_isq_index) := SYSDATE;
      P_isq_user(L_isq_index) := LP_userid;
      ---
      -- If the insert_ind is NULL and L_qty != 0,
      -- there is a record on the database.
      -- Set the insert ind to 'N' so that the record
      -- is not inserted.
      ---
      if P_isq_insert_ind(L_isq_index) is NULL then
         P_isq_insert_ind(L_isq_index) := 'N';
         P_isq_deleted_ind(L_isq_index) := 'N';
      end if;
      ---
      if L_qty + I_adj_qty < 0 then
         O_found := FALSE;
      end if;
   end if;
   ---
   if UPD_NON_SELLABLE_QTY(O_error_message,
                           I_item,
                           I_loc_type,
                           I_location,
                           I_adj_qty) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END BUILD_ADJ_UNAVAILABLE;
---------------------------------------------------------------------------------------------
FUNCTION ADJ_TRAN_DATA(I_item            IN       ITEM_MASTER.ITEM%TYPE,
                       I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                       I_location        IN       INV_ADJ.LOCATION%TYPE,
                       I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                       I_program         IN       TRAN_DATA.PGM_NAME%TYPE,
                       I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE,
                       I_tran_code       IN       TRAN_DATA.TRAN_CODE%TYPE,
                       I_reason          IN       INV_ADJ.REASON%TYPE,
                       I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                       I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                       I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                       O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       O_found           IN OUT   BOOLEAN)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'INVADJ_SQL.ADJ_TRAN_DATA';

   L_pack_ind        ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind    ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind   ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type       ITEM_MASTER.PACK_TYPE%TYPE;

BEGIN

   --empty out cache of tran_data inserts
   if STKLEDGR_SQL.INIT_TRAN_DATA_INSERT (O_error_message) = FALSE then
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;

   if BUILD_ADJ_TRAN_DATA(O_error_message,
                          O_found,
                          I_item,
                          I_loc_type,
                          I_location,
                          I_adj_qty,
                          NULL,     -- I_adj_weight,
                          NULL,     -- I_adj_weight_uom,
                          NULL,     -- I_order_no
                          I_program,
                          I_adj_date,
                          I_tran_code,
                          I_reason,
                          I_inv_status,
                          I_wac,
                          I_unit_retail,
                          L_pack_ind) = FALSE then
      return FALSE;
   end if;

   --call flush
   if STKLEDGR_SQL.FLUSH_TRAN_DATA_INSERT (O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               NULL);
         return FALSE;
END ADJ_TRAN_DATA;
---------------------------------------------------------------------------------------------
--  Overloaded INVADJ_SQL.ADJ_TRAN_DATA function
---------------------------------------------------------------------------------------------
FUNCTION ADJ_TRAN_DATA(I_item            IN       ITEM_MASTER.ITEM%TYPE,
                       I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                       I_location        IN       INV_ADJ.LOCATION%TYPE,
                       I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                       I_total_cost      IN       ORDLOC.UNIT_COST%TYPE,
                       I_total_retail    IN       ORDLOC.UNIT_RETAIL%TYPE,
                       I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                       I_program         IN       TRAN_DATA.PGM_NAME%TYPE,
                       I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE,
                       I_tran_code       IN       TRAN_DATA.TRAN_CODE%TYPE,
                       I_reason          IN       INV_ADJ.REASON%TYPE,
                       I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                       I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                       I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                       O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       O_found           IN OUT   BOOLEAN)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'INVADJ_SQL.ADJ_TRAN_DATA';

   L_pack_ind        ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind    ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind   ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type       ITEM_MASTER.PACK_TYPE%TYPE;

BEGIN

   --empty out cache of tran_data inserts
   if STKLEDGR_SQL.INIT_TRAN_DATA_INSERT (O_error_message) = FALSE then
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;

   if BUILD_ADJ_TRAN_DATA(O_error_message,
                          O_found,
                          I_item,
                          I_loc_type,
                          I_location,
                          I_adj_qty,
                          NULL,        -- I_adj_weight,
                          NULL,        -- I_adj_weight_uom,
                          I_order_no,
                          I_program,
                          I_adj_date,
                          I_tran_code,
                          I_reason,
                          I_inv_status,
                          I_wac,
                          I_unit_retail,
                          L_pack_ind) = FALSE then
      return FALSE;
   end if;

   --call flush
   if STKLEDGR_SQL.FLUSH_TRAN_DATA_INSERT (O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               NULL);
   return FALSE;
END ADJ_TRAN_DATA;
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Mod By     : Vipindas Thekke Purakkal, vipindas.thekkepurakkal@in.tesco.com
-- Mod Date   : 25-Oct-2007
-- Mod Ref    : Mod N108
-- Mod Details: Added a new parameter I_ref_no_2 in function BUILD_ADJ_TRAN_DATA
---------------------------------------------------------------------------------------------
FUNCTION BUILD_ADJ_TRAN_DATA(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_found           IN OUT   BOOLEAN,
                             I_item            IN       ITEM_MASTER.ITEM%TYPE,
                             I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                             I_location        IN       INV_ADJ.LOCATION%TYPE,
                             I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                             I_adj_weight      IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE DEFAULT NULL,
                             I_adj_weight_uom  IN       UOM_CLASS.UOM%TYPE DEFAULT NULL,
                             I_order_no        IN       ORDHEAD.ORDER_NO%TYPE   DEFAULT NULL,
                             I_program         IN       TRAN_DATA.PGM_NAME%TYPE,
                             I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE,
                             I_tran_code       IN       TRAN_DATA.TRAN_CODE%TYPE,
                             I_reason          IN       INV_ADJ.REASON%TYPE,
                             I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                             I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                             I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                             I_pack_ind        IN       ITEM_MASTER.PACK_IND%TYPE,
                             I_ref_no_2        IN       TRAN_DATA.REF_NO_2%TYPE DEFAULT NULL)
   RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'INVADJ_SQL.BUILD_ADJ_TRAN_DATA';
   L_total_cost               NUMBER(20,4);
   L_total_retail             NUMBER(20,4);
   L_item                     V_packsku_qty.ITEM%TYPE;
   L_pack_qty                 V_packsku_qty.QTY%TYPE;
   L_av_cost                  ITEM_LOC_SOH.AV_COST%TYPE;
   L_unit_cost                ITEM_LOC_SOH.UNIT_COST%TYPE;
   L_cost_basis               ITEM_LOC_SOH.UNIT_COST%TYPE;
   L_unit_retail              PRICE_HIST.UNIT_RETAIL%TYPE;
   L_units                    TRAN_DATA.UNITS%TYPE;
   L_ref_no_1                 TRAN_DATA.REF_NO_1%TYPE;
   L_ref_no_2                 TRAN_DATA.REF_NO_2%TYPE;
   L_gl_ref_no                TRAN_DATA.GL_REF_NO%TYPE;
   L_tran_code                TRAN_DATA.TRAN_CODE%TYPE;
   L_dept                     DEPS.DEPT%TYPE;
   L_class                    CLASS.CLASS%TYPE;
   L_subclass                 SUBCLASS.SUBCLASS%TYPE;
   L_std_av_ind               SYSTEM_OPTIONS.STD_AV_IND%TYPE;
   --L_error_message            VARCHAR2(255);
   L_cogs_ind                 INV_ADJ_REASON.COGS_IND%TYPE;

   L_comp_items_TBL           PACKITEM_ATTRIB_SQL.comp_item_TBL;
   L_comp_qtys_TBL            PACKITEM_ATTRIB_SQL.comp_qty_TBL;
   L_prorate_comp_costs_TBL   PACKITEM_ATTRIB_SQL.comp_cost_TBL;
   L_prorate_cost             ITEM_LOC_SOH.UNIT_COST%TYPE := NULL;
   L_pack_cost                ITEM_LOC_SOH.UNIT_COST%TYPE := NULL;

   L_item_rec                 ITEM_MASTER%ROWTYPE;
   L_item_comp_rec            ITEM_MASTER%ROWTYPE;
   L_sellable_ind             ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind            ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_xform_ind                ITEM_MASTER.ITEM_XFORM_IND%TYPE;
   L_pack_ind                 ITEM_MASTER.PACK_IND%TYPE;
   L_pack_type                ITEM_MASTER.PACK_TYPE%TYPE;

   L_int_fin_ind    WH.FINISHER_IND%TYPE := 'N';

   cursor C_ITEM_LOC is
      select ils.av_cost,
             ils.unit_cost,
             NVL(DECODE(L_int_fin_ind,
                        'Y',
                        ils.finisher_av_retail,
                        il.unit_retail),
                 il.unit_retail)
        from item_loc il, item_loc_soh ils
       where il.item = L_item
         and il.loc  = I_location
         and il.item = ils.item
         and il.loc  = ils.loc;

   cursor C_PACK_QTY is
   select item, qty
     from V_packsku_qty
    where pack_no = I_item;

   cursor C_GET_COGS_IND is
   select cogs_ind
     from inv_adj_reason
    where reason = I_reason;

   cursor C_EF_ITEM_LOC is
   select av_cost, unit_cost
     from item_loc_soh
    where item = L_item
      and loc  = I_location;

   cursor C_RETAIL is
      select il.unit_retail
        from item_loc il
       where il.item = L_item
         and il.loc  = I_location;

   cursor C_PACK_COST is
      select ils.unit_cost
        from item_loc_soh ils
       where ils.item = I_item
         and ils.loc  = I_location;

   cursor C_XFORM_IND is
      select item_xform_ind
        from item_master
       where item = L_item;

   cursor C_GET_INT_FIN_IND is
      select finisher_ind
        from wh
       where wh = I_location;

BEGIN

   -- 25-Oct-2007 Vipindas Thekke Purakkal,vipindas.thekkepurakkal@in.tesco.com Mod N108  Begin
   if I_ref_no_2 is NOT NULL then
      L_ref_no_2 := I_ref_no_2;
   end if;
   -- 25-Oct-2007 Vipindas Thekke Purakkal,vipindas.thekkepurakkal@in.tesco.com Mod N108  End

   --- Weight and weight UOM must be both populated or both null
   if I_adj_weight is NULL and I_adj_weight_uom is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('WGT_WGTUOM_REQUIRED',NULL,
                                            NULL,NULL);
      return FALSE;
   elsif I_adj_weight_uom is NULL and I_adj_weight is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('WGT_WGTUOM_REQUIRED',NULL,
                                            NULL,NULL);
      return FALSE;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if I_tran_code = 22 then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_COGS_IND',
                       'inv_adj_reason',
                       NULL);
      open C_GET_COGS_IND;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_COGS_IND',
                       'inv_adj_reason',
                       NULL);
      fetch C_GET_COGS_IND into L_cogs_ind;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_COGS_IND',
                       'inv_adj_reason',
                       NULL);
      close C_GET_COGS_IND;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INT_FIN_IND',
                    'wh',
                    NULL);
   open C_GET_INT_FIN_IND;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INT_FIN_IND',
                    'wh',
                    NULL);
   fetch C_GET_INT_FIN_IND into L_int_fin_ind;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_INT_FIN_IND',
                    'wh',
                    NULL);
   close C_GET_INT_FIN_IND;

   if I_pack_ind = 'N' then
      if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                        I_item,
                                        L_dept,
                                        L_class,
                                        L_subclass) = FALSE then
         RETURN FALSE;
      end if;
      ---
      L_item := I_item;
      ---
      if I_loc_type != 'E' then
         if I_wac is null then
            ---
            SQL_LIB.SET_MARK('OPEN','C_XFORM_IND','ITEM_MASTER','Item: '||L_item);
            open C_XFORM_IND;
            SQL_LIB.SET_MARK('FETCH','C_XFORM_IND','ITEM_MASTER','Item: '||L_item);
            fetch C_XFORM_IND into L_xform_ind;
            SQL_LIB.SET_MARK('CLOSE','C_XFORM_IND','ITEM_MASTER','Item: '||L_item);
            close C_XFORM_IND;
            ---
            SQL_LIB.SET_MARK('OPEN','C_ITEM_LOC','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
            open C_ITEM_LOC;
            SQL_LIB.SET_MARK('FETCH','C_ITEM_LOC','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
            fetch C_ITEM_LOC into L_av_cost,
                                  L_unit_cost,
                                  L_unit_retail;
            ---
            if C_ITEM_LOC%NOTFOUND then
               O_found := FALSE;
            else
               O_found := TRUE;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE','C_ITEM_LOC','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
            close C_ITEM_LOC;
            ---
            if L_xform_ind = 'Y' and L_orderable_ind = 'Y' then
               ---
               if ITEM_XFORM_SQL.CALCULATE_RETAIL(O_error_message,
                                                  L_item,
                                                  I_location,
                                                  L_unit_retail) = FALSE then
                  return FALSE;
               end if;
               ---
            end if;
         else
            L_av_cost := I_wac;
            L_unit_cost := I_wac;
            L_unit_retail := I_unit_retail;
         end if;
      else
         ---
         if I_unit_retail is NULL then
            ---
            if PRICING_ATTRIB_SQL.GET_EXTERNAL_FINISHER_RETAIL(O_error_message,
                                                               L_unit_retail,
                                                               L_item,
                                                               I_location) = FALSE then
               return FALSE;
            end if;
            ---
            open C_EF_ITEM_LOC;
            fetch C_EF_ITEM_LOC into L_av_cost, L_unit_cost;
            ---
            if C_EF_ITEM_LOC%NOTFOUND then
               O_found := FALSE;
            else
               O_found := TRUE;
            end if;
            close C_EF_ITEM_LOC;
         ---
         else
            L_unit_retail := I_unit_retail;
            L_av_cost := I_wac;
            L_unit_cost := I_wac;
         end if;
         ---

      end if;
      ---
      L_ref_no_1  := I_inv_status;
      L_gl_ref_no := I_reason;

      if I_tran_code = 22 then
         if SYSTEM_OPTIONS_SQL.STD_AV_IND(O_error_message,
                                          L_std_av_ind)= FALSE then
             return FALSE;
         end if;
         ---
         if L_cogs_ind = 'Y' then
            L_tran_code := 23;
         else
            L_tran_code := I_tran_code;
         end if;
         ---
         if L_std_av_ind = 'S' then
            L_total_cost := L_unit_cost * I_adj_qty;
         else
            L_total_cost := L_av_cost * I_adj_qty;
         end if;
         ---
         L_total_retail := L_unit_retail * I_adj_qty;
      else  /* TRAN_CODE = 25 */
         L_tran_code    := I_tran_code;
         L_ref_no_1     := I_order_no;
         L_ref_no_2     := I_inv_status;
         L_total_cost   := NULL;
         L_total_retail := NULL;
      end if;
      ---
      if STKLEDGR_SQL.BUILD_TRAN_DATA_INSERT(O_error_message,
                                             I_item,
                                             L_dept,
                                             L_class,
                                             L_subclass,
                                             I_location,
                                             I_loc_type,
                                             I_adj_date,
                                             L_tran_code,
                                             NULL,          -- I_adjust_code
                                             I_adj_qty,
                                             L_total_cost,
                                             L_total_retail,
                                             L_ref_no_1,
                                             L_ref_no_2,
                                             NULL,--I_tsf_source_st
                                             NULL,--I_tsf_source_wh
                                             NULL,--I_old_unit_retail
                                             NULL,--I_new_unit_retail
                                             NULL,--I_source_dept
                                             NULL,--I_source_class
                                             NULL,--I_source_subclass
                                             I_program,
                                             L_gl_ref_no) = FALSE then
         return FALSE;
      end if;
   else -- PACK item
      L_item := I_item;
      --- Get simple pack and catch weight indicators
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_rec,
                                         L_item) = FALSE then
         return FALSE;
      end if;
      -- commented by Satish B.N on 10-Feb-2009 Begin
      -- commented for DefNBS008686/Oracle Bug number 7191914

    /*  if I_loc_type = 'S' and I_tran_code = 22 then

         SQL_LIB.SET_MARK('OPEN','C_PACK_COST','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
         open C_PACK_COST;
         SQL_LIB.SET_MARK('FETCH','C_PACK_COST','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
         fetch C_PACK_COST into L_pack_cost;
         SQL_LIB.SET_MARK('CLOSE','C_PACK_COST','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
         close C_PACK_COST;

         if PACKITEM_ATTRIB_SQL.GET_COMP_PRORATE_COSTS(O_error_message,
                                                       L_comp_items_TBL,
                                                       L_comp_qtys_TBL,
                                                        L_prorate_comp_costs_TBL,
                                                       L_item,
                                                       L_pack_cost,
                                                       I_location) = FALSE then
            return FALSE;
         end if;

         FOR i in 1..L_comp_items_TBL.COUNT LOOP
            L_item := L_comp_items_TBL(i);
            L_pack_qty := L_comp_qtys_TBL(i);
            ---
            if L_item_rec.simple_pack_ind = 'Y'  and
               L_item_rec.catch_weight_ind = 'Y' then
               -- calculate total cost based on weight
               if CATCH_WEIGHT_SQL.CALC_TOTAL_COST(O_error_message,
                                                   L_total_cost, -- output
                                                   I_item, -- simple pack item
                                                   I_location,
                                                   I_loc_type,
                                                   L_prorate_comp_costs_TBL(i),
                                                   I_adj_qty,
                                                   -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
                                                   NULL,
                                                   NULL) = FALSE then
                                                   -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
                  return FALSE;
               end if;

               -- calculate units based on weight
               if CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY(O_error_message,
                                                        L_units,
                                                        L_item,  -- component
                                                        I_adj_qty*L_comp_qtys_TBL(i),
                                                        -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
                                                        NULL,
                                                        NULL,
                                                        -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
                                                        I_item,  -- pack
                                                        I_location,
                                                        I_loc_type,
                                                        I_adj_qty) = FALSE then
                  return FALSE;
               end if;

               -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
                -- calculate total retail based on weight
               if CATCH_WEIGHT_SQL.CALC_TOTAL_RETAIL(O_error_message,
                                                     L_item,
                                                     I_adj_qty*L_comp_qtys_TBL(i),
                                                     L_unit_retail,
                                                     I_location,
                                                     I_loc_type,
                                                     NULL,
                                                     NULL,
                                                     L_total_retail) = FALSE THEN
                  return FALSE;
               end if;
               -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
            else
               L_total_cost := L_prorate_comp_costs_TBL(i) * I_adj_qty;
               L_units := I_adj_qty * L_comp_qtys_TBL(i);
               -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
               ---
               SQL_LIB.SET_MARK('OPEN','C_RETAIL','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
               open C_RETAIL;
               SQL_LIB.SET_MARK('FETCH','C_RETAIL','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
               fetch C_RETAIL into L_unit_retail;
               SQL_LIB.SET_MARK('CLOSE','C_RETAIL','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
               close C_RETAIL;
               ---
               L_total_retail := L_unit_retail * L_units;
               ---
               -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
            end if;
            -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
            -- 28-Oct-2008 TESCO HSC/Murali 6907185 End

            if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                              L_item,
                                              L_dept,
                                              L_class,
                                              L_subclass) = FALSE then
               return FALSE;
            end if;
            ---
            if L_unit_retail is NULL then
               O_found := FALSE;
            else
               O_found := TRUE;
            end if;
            ---
            L_ref_no_1  := I_inv_status;
            L_gl_ref_no := I_reason;

            if L_cogs_ind = 'Y' then
               L_tran_code := 23;
            else
               L_tran_code := I_tran_code;
            end if;

            if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                               L_item_comp_rec,
                                               L_item) = FALSE then
               return FALSE;
            end if;
            if NVL(L_item_comp_rec.deposit_item_type,'N') != 'A' then
               if STKLEDGR_SQL.BUILD_TRAN_DATA_INSERT(O_error_message,
                                                      L_item,
                                                      L_dept,
                                                      L_class,
                                                      L_subclass,
                                                      I_location,
                                                      I_loc_type,
                                                      I_adj_date,
                                                      L_tran_code,
                                                      NULL,          --I_adjust_code
                                                      -- 28-Oct-2008 TESCO HSC/Murali 6330821 Begin
                                                      I_adj_qty * L_pack_qty,
                                                      -- 28-Oct-2008 TESCO HSC/Murali 6330821 End
                                                      L_total_cost,
                                                      L_total_retail,
                                                      L_ref_no_1,
                                                      L_ref_no_2,
                                                      NULL,     --I_tsf_source_st
                                                      NULL,     --I_tsf_source_wh
                                                      NULL,     --I_old_unit_retail
                                                      NULL,     --I_new_unit_retail
                                                      NULL,     --I_source_dept
                                                      NULL,     --I_source_class
                                                      NULL,     --I_source_subclass
                                                      I_program,
                                                      L_gl_ref_no) = FALSE then
                  return FALSE;
               end if;
            end if;
         END LOOP;
      else  -- not loctype S or not tran code 22
         L_item := I_item; */
      -- commented by Satish B.N DefNBS008686/Oracle Bug number 7191914 on 10-Feb-2009 End
         if PACKITEM_ATTRIB_SQL.GET_COMP_QTYS(O_error_message,
                                              L_comp_items_TBL,
                                              L_comp_qtys_TBL,
                                              L_item) = FALSE then
            return FALSE;
         end if;

         for i in 1..L_comp_items_TBL.COUNT LOOP
            L_item := L_comp_items_TBL(i);
            L_pack_qty := L_comp_qtys_TBL(i);
            ---
            if I_loc_type != 'E' then
               SQL_LIB.SET_MARK('OPEN','C_ITEM_LOC','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
               open C_ITEM_LOC;
               SQL_LIB.SET_MARK('FETCH','C_ITEM_LOC','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
               fetch C_ITEM_LOC into L_av_cost, L_unit_cost, L_unit_retail;
               ---
               if C_ITEM_LOC%NOTFOUND then
                  O_found := FALSE;
               else
                  O_found := TRUE;
               end if;
               ---
               SQL_LIB.SET_MARK('CLOSE','C_ITEM_LOC','ITEM_LOC','Item: '||L_item||' Loc: '||to_char(I_location));
               close C_ITEM_LOC;
            else
               if PRICING_ATTRIB_SQL.GET_EXTERNAL_FINISHER_RETAIL(O_error_message,
                                                                  L_unit_retail,
                                                                  L_item,
                                                                  I_location) = FALSE then
                  return FALSE;
               end if;
               ---
               open C_EF_ITEM_LOC;
               fetch C_EF_ITEM_LOC into L_av_cost, L_unit_cost;
               ---
               if C_EF_ITEM_LOC%NOTFOUND then
                  O_found := FALSE;
               else
                  O_found := TRUE;
               end if;
               close C_EF_ITEM_LOC;
            end if;
            ---
            L_ref_no_1  := I_inv_status;
            L_gl_ref_no := I_reason;
            ---
            if I_tran_code = 22 then
               if SYSTEM_OPTIONS_SQL.STD_AV_IND(O_error_message,
                                                L_std_av_ind) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_cogs_ind = 'Y' then
                  L_tran_code := 23;
               else
                  L_tran_code := I_tran_code;
               end if;
               ---
               if L_std_av_ind = 'S' then
                  L_cost_basis := L_unit_cost;
               else
                  L_cost_basis := L_av_cost;
               end if;
               ---
               if L_item_rec.simple_pack_ind = 'Y'  and
                  L_item_rec.catch_weight_ind = 'Y' then
                  -- get pack unit_cost to be used with nominal weight to derive 'per lb cost'
                  SQL_LIB.SET_MARK('OPEN','C_PACK_COST','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
                  open C_PACK_COST;
                  SQL_LIB.SET_MARK('FETCH','C_PACK_COST','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
                  fetch C_PACK_COST into L_pack_cost;
                  SQL_LIB.SET_MARK('CLOSE','C_PACK_COST','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
                  close C_PACK_COST;

                  if CATCH_WEIGHT_SQL.CALC_TOTAL_COST(O_error_message,
                                                      L_total_cost, -- output
                                                      I_item, -- pack item
                                                      I_location,
                                                      I_loc_type,
                                                      L_pack_cost,  -- pack's unit_cost
                                                      I_adj_qty,
                                                      -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
                                                      NULL,
                                                      NULL) = FALSE then
                                                      -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
                     return FALSE;
                  end if;
                  -- calculate units based on weight
                  if CATCH_WEIGHT_SQL.CALC_COMP_UPDATE_QTY(O_error_message,
                                                           L_units,
                                                           L_item,  -- component
                                                           I_adj_qty*L_comp_qtys_TBL(i),
                                                           -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
                                                           NULL,
                                                           NULL,
                                                           -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
                                                           I_item,  -- pack
                                                           I_location,
                                                           I_loc_type,
                                                           I_adj_qty) = FALSE then
                     return FALSE;
                  end if;

                  -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
                  -- calculate total retail based on weight
                  if CATCH_WEIGHT_SQL.CALC_TOTAL_RETAIL(O_error_message,
                                                        L_item,
                                                        I_adj_qty*L_comp_qtys_TBL(i),
                                                        L_unit_retail,
                                                        I_location,
                                                        I_loc_type,
                                                        NULL,
                                                        NULL,
                                                        L_total_retail) = FALSE THEN
                     return FALSE;
                  end if;
                  -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
               else
                  L_total_cost := L_cost_basis * I_adj_qty * L_pack_qty;
                  L_units := I_adj_qty * L_pack_qty;
                  -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
                  ---
                  L_total_retail := L_unit_retail * L_units;
                  -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
               end if;
               -- 28-Oct-2008 TESCO HSC/Murali 6907185 Begin
               -- 28-Oct-2008 TESCO HSC/Murali 6907185 End
            else  /* TRAN_CODE = 25 */
               L_tran_code    := I_tran_code;
               L_ref_no_1     := I_order_no;
               L_total_cost   := NULL;
               L_total_retail := NULL;
            end if;
            ---
            if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                               L_item_comp_rec,
                                               L_item) = FALSE then
               return FALSE;
            end if;
            if NVL(L_item_comp_rec.deposit_item_type,'N') != 'A' then
               if STKLEDGR_SQL.BUILD_TRAN_DATA_INSERT(O_error_message,
                                                      L_item,
                                                      L_item_comp_rec.dept,
                                                      L_item_comp_rec.class,
                                                      L_item_comp_rec.subclass,
                                                      I_location,
                                                      I_loc_type,
                                                      I_adj_date,
                                                      L_tran_code,
                                                      NULL,          --I_adjust_code
                                                      I_adj_qty * L_pack_qty,
                                                      L_total_cost,
                                                      L_total_retail,
                                                      L_ref_no_1,
                                                      /*Vipindas T.P., vipindas.thekkePurakkal@in.tesco.com
                                                      The Parameter ref_no_2 has been passed
                                                      the value of I_ref_no_2 instead of NULL
                                                        DefNBS004437  Begin*/
                                                      I_ref_no_2,   --I_ref_no_2,
                                                      /*DefNBS004437  End*/
                                                      NULL,         --I_tsf_source_st
                                                      NULL,         --I_tsf_source_wh
                                                      NULL,         --I_old_unit_retail
                                                      NULL,         --I_new_unit_retail
                                                      NULL,         --I_source_dept
                                                      NULL,         --I_source_class
                                                      NULL,         --I_source_subclass
                                                      I_program,
                                                      L_gl_ref_no) = FALSE then
                  return FALSE;
               end if;
               ---
            end if;
       end loop;
       -- commented by Satish B.N on 10-Feb-2009
       -- commented for DefNBS008686/Oracle Bug number 7191914
      --end if;  -- if I_loc_type = 'S' and I_tran_code = 22
   end if;   -- if I_pack_ind = 'N'
   ---
   return TRUE;

EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               NULL);
         return FALSE;
END BUILD_ADJ_TRAN_DATA;
---------------------------------------------------------------------------------------------
FUNCTION GET_UNAVAILABLE(I_item            IN       ITEM_MASTER.ITEM%TYPE,
                         I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                         I_location        IN       INV_ADJ.LOCATION%TYPE,
                         O_unavl_qty       IN OUT   INV_STATUS_QTY.QTY%TYPE,
                         O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_found           IN OUT   BOOLEAN)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'INVADJ_SQL.VALIDATE_SKU';

   L_qty         INV_STATUS_QTY.QTY%TYPE := NULL;
   L_tbl_index   BINARY_INTEGER := NULL;

   cursor C_SUM_ALL is
      select nvl(sum(qty),0)
        from inv_status_qty
       where item = I_item;

   cursor C_SUM_LOCATION is
      select nvl(sum(qty),0)
        from inv_status_qty
       where item     = I_item
         and loc_type = I_loc_type
         and location = I_location;

   cursor C_INV_STATUS_CODES is
      select *
        from inv_status_codes;
BEGIN
   if I_loc_type = 'W' then

      if LP_inv_status_codes is NULL then
         open C_INV_STATUS_CODES;
         fetch C_INV_STATUS_CODES BULK COLLECT INTO LP_inv_status_codes;
         close C_INV_STATUS_CODES;
      end if;

      O_unavl_qty := 0;

      FOR i IN 1..LP_inv_status_codes.COUNT LOOP
         if LP_inv_status_codes(i).inv_status is NOT NULL then
            if GET_INV_STATUS_QTY (O_error_message,
                                   L_qty,
                                   L_tbl_index,
                                   I_item,
                                   I_location,
                                   I_loc_type,
                                   LP_inv_status_codes(i).inv_status) = FALSE then
               return FALSE;
            end if;
            ---
            O_unavl_qty := O_unavl_qty + L_qty;
         end if;

      END LOOP;

   elsif I_loc_type in ('S','E') then

      SQL_LIB.SET_MARK('OPEN','C_SUM_LOCATION','inv_status_qty',NULL);
      open C_SUM_LOCATION;
      SQL_LIB.SET_MARK('FETCH','C_SUM_LOCATION','inv_status_qty',NULL);
      fetch C_SUM_LOCATION into O_unavl_qty;
      ---
      if C_SUM_LOCATION%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_SUM_LOCATION','inv_status_qty',NULL);
         close C_SUM_LOCATION;
         O_found := FALSE;
      else
         SQL_LIB.SET_MARK('CLOSE','C_SUM_LOCATION','inv_status_qty',NULL);
         close C_SUM_LOCATION;
         O_found := TRUE;
      end if;
   else
      SQL_LIB.SET_MARK('OPEN','C_SUM_ALL','inv_status_qty',NULL);
      open C_SUM_ALL;
      SQL_LIB.SET_MARK('FETCH','C_SUM_ALL','inv_status_qty',NULL);
      fetch C_SUM_ALL into O_unavl_qty;
      ---
      if C_SUM_ALL%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_SUM_ALL','inv_status_qty',NULL);
         close C_SUM_ALL;
         O_found := FALSE;
      else
         SQL_LIB.SET_MARK('CLOSE','C_SUM_ALL','inv_status_qty',NULL);
         close C_SUM_ALL;
         O_found := TRUE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               NULL);
         return FALSE;
END GET_UNAVAILABLE;
-------------------------------------------------------------------------------
FUNCTION GET_AVAIL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                   O_avail_qty       IN OUT   INV_STATUS_QTY.QTY%TYPE,
                   I_item            IN       INV_STATUS_QTY.ITEM%TYPE,
                   I_location        IN       INV_STATUS_QTY.LOCATION%TYPE,
                   I_loc_type        IN       INV_STATUS_QTY.LOC_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_unavl_qty       INV_STATUS_QTY.QTY%TYPE;
   L_stock_on_hand   INV_STATUS_QTY.QTY%TYPE;
   L_found           BOOLEAN;

BEGIN
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_location IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_location',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type NOT IN ('S','W','E') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            I_loc_type,'S W or E');
      return FALSE;
   end if;
   ---
   if I_loc_type = 'S' then
      if ITEMLOC_QUANTITY_SQL.GET_STOCK_ON_HAND(O_error_message,
                                                L_stock_on_hand,
                                                I_item,
                                                I_location,
                                                I_loc_type) = FALSE then
         return FALSE;
      end if;
   else
      if ITEMLOC_QUANTITY_SQL.GET_STOCK_ON_HAND(O_error_message,
                                                L_stock_on_hand,
                                                I_item,
                                                I_location,
                                                I_loc_type) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if INVADJ_SQL.GET_UNAVAILABLE(I_item,
                                 I_loc_type,
                                 I_location,
                                 L_unavl_qty,
                                 O_error_message,
                                 L_found) = FALSE then
      return FALSE;
   end if;
   ---
   O_avail_qty := nvl(L_stock_on_hand,0) - nvl(L_unavl_qty,0);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              'INVADJ_SQL.GET_AVAIL',
                                              to_char(SQLCODE));
        return FALSE;
END GET_AVAIL;
---------------------------------------------------------------------------------------------
FUNCTION GET_INV_STATUS_QTY (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_qty             IN OUT   INV_STATUS_QTY.QTY%TYPE,
                             O_tbl_index       IN OUT   BINARY_INTEGER,
                             I_item            IN       ITEM_MASTER.ITEM%TYPE,
                             I_location        IN       ITEM_LOC_SOH.LOC%TYPE,
                             I_loc_type        IN       ITEM_LOC_SOH.LOC_TYPE%TYPE,
                             I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_SQL.GET_INV_STATUS_QTY';

   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_INV_STATUS_QTY is
      select qty
        from inv_status_qty
       where item       = I_item
         and inv_status = I_inv_status
         and location   = I_location
         and loc_type   = I_loc_type
         for update nowait;

BEGIN
   O_qty := 0;
   O_tbl_index := 0;
   ---
   -- Check the PL/SQL table
   -- that contains the BULK INSERT records.
   ---
   FOR i in 1..P_isq_size LOOP
      if P_isq_item(i) = I_item and
         P_isq_status(i) = I_inv_status and
         P_isq_loc(i) = I_location then
         ---
         O_qty := P_isq_qty(i);
         O_tbl_index := i;
         EXIT;
         ---
      end if;
   END LOOP;

   if O_tbl_index = 0 then
      SQL_LIB.SET_MARK('OPEN','C_INV_STATUS_QTY','inv_status_qty','Item: '||I_item||
                       'location: '||to_char(I_location)||'Inv_status: '||to_char(I_inv_status));
      open C_INV_STATUS_QTY;
      SQL_LIB.SET_MARK('FETCH','C_INV_STATUS_QTY','inv_status_qty', 'Item: '||I_item||
                       'location: '||to_char(I_location)||'Inv_status: '||to_char(I_inv_status));
      fetch C_INV_STATUS_QTY into O_qty;
      ---
      close C_INV_STATUS_QTY;
      ---
      P_isq_size := P_isq_size + 1;
      P_isq_item(P_isq_size) := I_item;
      P_isq_status(P_isq_size) := I_inv_status;
      P_isq_loc_type(P_isq_size) := I_loc_type;
      P_isq_loc(P_isq_size) := I_location;
      P_isq_qty(P_isq_size) := O_qty;
      P_isq_date(P_isq_size) := SYSDATE;
      P_isq_user(P_isq_size) := LP_userid;
      P_isq_insert_ind(P_isq_size) := NULL;
      P_isq_deleted_ind(P_isq_size) := NULL;
      ---
      O_tbl_index := P_isq_size;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('NO_RSRV_INVSTAT_REC',
                                            to_char(I_inv_status),
                                            I_item,
                                            to_char(I_location));
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END GET_INV_STATUS_QTY;
---------------------------------------------------------------------------------------------
FUNCTION INSERT_INV_ADJ(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        I_item            IN       ITEM_MASTER.ITEM%TYPE,
                        I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                        I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                        I_location        IN       INV_ADJ.LOCATION%TYPE,
                        I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                        I_reason          IN       INV_ADJ.REASON%TYPE,
                        I_user_id         IN       INV_ADJ.USER_ID%TYPE,
                        I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE)
   RETURN BOOLEAN IS

   L_program                      VARCHAR2(64) := 'INVADJ_SQL.INSERT_INV_ADJ';
   L_error_message                VARCHAR2(255);
   L_found                        BOOLEAN;
   L_prev_qty                     INV_ADJ.PREV_QTY%TYPE;
   L_inv_status                   INV_ADJ.INV_STATUS%TYPE;
   L_unavail_stkord_inv_adj_ind   SYSTEM_OPTIONS.UNAVAIL_STKORD_INV_ADJ_IND%TYPE;

BEGIN

   if SYSTEM_OPTIONS_SQL.GET_UNAVAIL_STKORD_INV_ADJ_IND(O_error_message,
                                                        L_unavail_stkord_inv_adj_ind) = FALSE then
      return FALSE;
   end if;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_location',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type not in ('S','W','E') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            I_loc_type,'S W or E');
      return FALSE;
   elsif I_adj_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_adj_qty',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif (I_inv_status is NULL or I_inv_status = 0) and I_reason IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_reason',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_inv_status is not NULL and I_inv_status != 0
      and I_reason is not NULL
      and (L_unavail_stkord_inv_adj_ind = 'N'
      or (L_unavail_stkord_inv_adj_ind = 'Y' and I_reason != 13)) then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_reason',
                                               'NOT NULL','NULL');
         return FALSE;
   elsif I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_user_id',
                                            'NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   if INVADJ_VALIDATE_SQL.ITEM_LOC_EXIST(I_item,
                                         I_location,
                                         I_loc_type,
                                         nvl(I_inv_status,0),
                                         L_prev_qty,
                                         O_error_message,
                                         L_found) = FALSE then
      return FALSE;
   end if;
   ---
   if I_inv_status = 0 then
      L_inv_status := NULL;
   else
      L_inv_status := I_inv_status;
   end if;
   ---
   insert into inv_adj(item,
                       inv_status,
                       loc_type,
                       location,
                       adj_qty,
                       reason,
                       adj_date,
                       prev_qty,
                       user_id)
               values( I_item,
                       L_inv_status,
                       I_loc_type,
                       I_location,
                       I_adj_qty,
                       I_reason,
                       nvl(I_adj_date, LP_vdate),
                       L_prev_qty,
                       I_user_id);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
        return FALSE;
END INSERT_INV_ADJ;
-------------------------------------------------------------------------
FUNCTION ADJ_STOCK(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                   I_item            IN       ITEM_MASTER.ITEM%TYPE,
                   I_location        IN       INV_ADJ.LOCATION%TYPE,
                   I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                   I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                   I_reason          IN       INV_ADJ.REASON%TYPE,
                   I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                   I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                   I_user_id         IN       INV_ADJ.USER_ID%TYPE,
                   I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE)
   RETURN BOOLEAN IS

   L_program       TRAN_DATA.PGM_NAME%TYPE := 'INVADJ_SQL.ADJ_STOCK';
   L_found         BOOLEAN;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_location',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type not in ('S','W','E') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            I_loc_type,'S W or E');
      return FALSE;
   elsif I_adj_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_adj_qty',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_reason is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_reason',
                                            'NULL','NOT NULL');
      return FALSE;
    elsif I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_user_id',
                                            'NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   if INVADJ_SQL.INSERT_INV_ADJ(O_error_message,
                                I_item,
                                NULL,
                                I_loc_type,
                                I_location,
                                I_adj_qty,
                                I_reason,
                                I_user_id,
                                I_adj_date) = FALSE then
      return FALSE;
   end if;
   ---
   if INVADJ_SQL.ADJ_STOCK_ON_HAND(I_item,
                                   I_loc_type,
                                   I_location,
                                   I_adj_qty,
                                   O_error_message,
                                   L_found) = FALSE then
      return FALSE;
   end if;
   ---
   if INVADJ_SQL.ADJ_TRAN_DATA(I_item,
                               I_loc_type,
                               I_location,
                               I_adj_qty,
                               L_program,
                               nvl(I_adj_date, LP_vdate),
                               22,
                               I_reason,
                               NULL,
                               I_wac,
                               I_unit_retail,
                               O_error_message,
                               L_found) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
        return FALSE;
END ADJ_STOCK;
-------------------------------------------------------------------
FUNCTION STOCK_OUT(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                   I_item            IN       ITEM_MASTER.ITEM%TYPE,
                   I_location        IN       INV_ADJ.LOCATION%TYPE,
                   I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                   I_reason          IN       INV_ADJ.REASON%TYPE,
                   I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                   I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                   I_user_id         IN       INV_ADJ.USER_ID%TYPE,
                   I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_SQL.STOCK_OUT';
   L_avail_qty     INV_STATUS_QTY.QTY%TYPE;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_location',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type not in ('S','W','E') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            I_loc_type,'S W or E');
      return FALSE;
   elsif I_reason is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_reason',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_user_id',
                                            'NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   if INVADJ_SQL.GET_AVAIL(O_error_message,
                           L_avail_qty,
                           I_item,
                           I_location,
                           I_loc_type) = FALSE then
      return FALSE;
   end if;

   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
   --Following RIB error message has modified as the part of Performance issue.

   /*if L_avail_qty <= 0 or L_avail_qty IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('NONE_AVAIL_QTY',NULL,
                                             NULL,NULL);
      return FALSE;
   end if;*/
   ---
   --Enhanced Error Message
   if L_avail_qty <= 0 or L_avail_qty IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('NONE_AVAIL_QTY',
                                            'Item = '||I_item,
                                            'Location = '||I_location,
                                            NULL);
      return FALSE;
   end if;
   -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End

   if INVADJ_SQL.ADJ_STOCK(O_error_message,
                           I_item,
                           I_location,
                           I_loc_type,
                           L_avail_qty * -1,
                           I_reason,
                           I_wac,
                           I_unit_retail,
                           I_user_id,
                           I_adj_date) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
        return FALSE;
END STOCK_OUT;
-------------------------------------------------------------------
FUNCTION CHANGE_STATUS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_item            IN       ITEM_MASTER.ITEM%TYPE,
                       I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                       I_location        IN       INV_ADJ.LOCATION%TYPE,
                       I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                       I_move_to         IN       VARCHAR2,
                       I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                       I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                       I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                       I_user_id         IN       INV_ADJ.USER_ID%TYPE,
                       I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE)
   RETURN BOOLEAN IS

   L_program       TRAN_DATA.PGM_NAME%TYPE := 'INVADJ_SQL.CHANGE_STATUS';
   L_unavail_qty   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;
   L_found         BOOLEAN;
   L_avail_qty     INV_STATUS_QTY.QTY%TYPE;
   L_adj_qty       INV_ADJ.ADJ_QTY%TYPE;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_location',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type not in ('S','W','E') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            I_loc_type,'S W or E');
      return FALSE;
   elsif I_adj_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_adj_qty',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_adj_qty < 0 then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_adj_qty',
                                            to_char(I_adj_qty),'>= 0');
      return FALSE;
   elsif I_inv_status is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_inv_status',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_move_to is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_move_to',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_move_to not in ('A','U') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_move_to',
                                            I_move_to,'A or U');
      return FALSE;
    elsif I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_user_id',
                                            'NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   if I_move_to = 'A' then
      if INVADJ_VALIDATE_SQL.ITEM_LOC_EXIST(I_item,
                                            I_location,
                                            I_loc_type,
                                            I_inv_status,
                                            L_unavail_qty,
                                            O_error_message,
                                            L_found) = FALSE then
         return FALSE;
      end if;

      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*---
      if nvl(L_unavail_qty,0) < I_adj_qty then
         O_error_message := SQL_LIB.CREATE_MSG('NEGATIVE_ADJ_QTY',NULL,
                                                NULL,NULL);
         return FALSE;
      end if;
      ---*/

      --Enhanced Error Message
      if nvl(L_unavail_qty,0) < I_adj_qty then
         O_error_message := SQL_LIB.CREATE_MSG('NEGATIVE_ADJ_QTY',
                                               'Item = '||I_item,
                                               'Location = '||I_location,
                                               NULL);
         return FALSE;
      end if;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
      L_adj_qty := I_adj_qty * -1;
   else
      if INVADJ_SQL.GET_AVAIL(O_error_message,
                              L_avail_qty,
                              I_item,
                              I_location,
                              I_loc_type) = FALSE then
         return FALSE;
      end if;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*---
      if L_avail_qty < I_adj_qty then
         O_error_message := SQL_LIB.CREATE_MSG('NEGATIVE_ADJ_QTY_AS',NULL,
                                                NULL,NULL);
         return FALSE;
      end if;
      ---*/
      --Enhanced Error Message
      if L_avail_qty < I_adj_qty then
         O_error_message := SQL_LIB.CREATE_MSG('NEGATIVE_ADJ_QTY',
                                               'Item = '||I_item,
                                               'Location = '||I_location,
                                               NULL);
         return FALSE;
      end if;
      L_adj_qty := I_adj_qty;
   end if;
   ---
   if INVADJ_SQL.INSERT_INV_ADJ(O_error_message,
                                I_item,
                                I_inv_status,
                                I_loc_type,
                                I_location,
                                L_adj_qty,
                                NULL,
                                I_user_id,
                                I_adj_date) = FALSE then
      return FALSE;
   end if;
   ---
   if INVADJ_SQL.ADJ_UNAVAILABLE(I_item,
                                 I_inv_status,
                                 I_loc_type,
                                 I_location,
                                 L_adj_qty,
                                 O_error_message,
                                 L_found) = FALSE then
      return FALSE;
   end if;
   ---
   if INVADJ_SQL.ADJ_TRAN_DATA(I_item,
                               I_loc_type,
                               I_location,
                               L_adj_qty,
                               L_program,
                               nvl(I_adj_date, LP_vdate),
                               25,
                               NULL,
                               I_inv_status,
                               I_wac,
                               I_unit_retail,
                               O_error_message,
                               L_found) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
        return FALSE;
END CHANGE_STATUS;
---------------------------------------------------------------------
FUNCTION REMOVE_STOCK(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      I_item            IN       ITEM_MASTER.ITEM%TYPE,
                      I_location        IN       INV_ADJ.LOCATION%TYPE,
                      I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                      I_remove_from     IN       VARCHAR2,
                      I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                      I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                      I_reason          IN       INV_ADJ.REASON%TYPE,
                      I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                      I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                      I_user_id         IN       INV_ADJ.USER_ID%TYPE,
                      I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE)
   RETURN BOOLEAN IS

   L_avail_qty          INV_STATUS_QTY.QTY%TYPE;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_location',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_loc_type not in ('S','W','E') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_loc_type',
                                            I_loc_type,'S W or E');
      return FALSE;
   elsif I_adj_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_adj_qty',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_adj_qty < 0 then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_adj_qty',
                                            to_char(I_adj_qty),'>= 0');
      return FALSE;
   elsif I_remove_from is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_remove_from',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_remove_from not in ('A','U') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_remove_from',
                                            I_remove_from,'A or U');
      return FALSE;
    elsif I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_user_id',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_reason is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_reason',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_remove_from = 'A' and I_inv_status is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_remove_from/I_inv_status',
                                            'A/NOT NULL','A/NULL');
      return FALSE;
   elsif I_remove_from = 'U' and I_inv_status IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_remove_from/
                                            I_inv_status','U/NULL',
                                            'U/NOT NULL');
      return FALSE;
   end if;
   ---
   if I_remove_from = 'U' then
      if INVADJ_SQL.CHANGE_STATUS(O_error_message,
                                  I_item,
                                  I_inv_status,
                                  I_location,
                                  I_loc_type,
                                  'A',
                                  I_adj_qty,
                                  I_wac,
                                  I_unit_retail,
                                  I_user_id,
                                  I_adj_date) = FALSE then
         return FALSE;
      end if;
   else
      if INVADJ_SQL.GET_AVAIL(O_error_message,
                              L_avail_qty,
                              I_item,
                              I_location,
                              I_loc_type) = FALSE then
         return FALSE;
      end if;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      ---
      /*if L_avail_qty < I_adj_qty then
         O_error_message := SQL_LIB.CREATE_MSG('NEGATIVE_ADJ_QTY_AS',NULL,
                                                NULL,NULL);
         return FALSE;
      end if;*/

      if L_avail_qty < I_adj_qty then
         O_error_message := SQL_LIB.CREATE_MSG('NEGATIVE_ADJ_QTY',
                                               'Item = '||I_item,
                                               'Location = '||I_location,
                                               NULL);
         return FALSE;
      end if;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End
   end if;
   ---
   if INVADJ_SQL.ADJ_STOCK(O_error_message,
                           I_item,
                           I_location,
                           I_loc_type,
                           I_adj_qty * -1,
                           I_reason,
                           I_wac,
                           I_unit_retail,
                           I_user_id,
                           I_adj_date) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              'INVADJ_SQL.REMOVE_STOCK',
                                              to_char(SQLCODE));
        return FALSE;
END REMOVE_STOCK;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Private Functions accessed by PROCESS_INVADJ
--------------------------------------------------------------------------------
FUNCTION PROCESS_AVAILABLE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_inv_adj         IN       INV_ADJ%ROWTYPE,
                           I_adj_weight      IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                           I_adj_weight_uom  IN       UOM_CLASS.UOM%TYPE,
                           I_vdate           IN       DATE,
                           I_pgm_name        IN       TRAN_DATA.PGM_NAME%TYPE,
                           I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                           I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                           I_pack_ind        IN       ITEM_MASTER.PACK_IND%TYPE)
   RETURN BOOLEAN IS

   L_found      BOOLEAN := FALSE;
   L_tran_code  TRAN_DATA.TRAN_CODE%TYPE;
   L_tran_type  VARCHAR2(6);
   L_store      INV_ADJ.LOCATION%TYPE;
   L_wh         INV_ADJ.LOCATION%TYPE;

BEGIN
   if BUILD_ADJ_STOCK_ON_HAND(O_error_message,
                              L_found,
                              I_inv_adj.item,
                              I_inv_adj.loc_type,
                              I_inv_adj.location,
                              I_inv_adj.adj_qty,
                              I_adj_weight,
                              I_adj_weight_uom,
                              I_pack_ind) = FALSE then
      return FALSE;
   end if;
   ---
   L_tran_code := 22;
   ---
   if BUILD_ADJ_TRAN_DATA(O_error_message,
                          L_found,
                          I_inv_adj.item,
                          I_inv_adj.loc_type,
                          I_inv_adj.location,
                          I_inv_adj.adj_qty,
                          I_adj_weight,
                          I_adj_weight_uom,
                          NULL,    --I_order_no
                          I_pgm_name,
                          I_inv_adj.adj_date,
                          L_tran_code,
                          I_inv_adj.reason,
                          I_inv_adj.inv_status,
                          I_wac,
                          I_unit_retail,
                          I_pack_ind) = FALSE then
      return FALSE;
   end if;
   ---
   if I_inv_adj.adj_date < I_vdate then
      if I_inv_adj.loc_type = 'S' then
         L_wh    := -1;
         L_store := I_inv_adj.location;
      else
         L_wh    := I_inv_adj.location;
         L_store := -1;
      end if;
      ---
      L_tran_type := 'INVADJ';
      ---
      if UPDATE_SNAPSHOT_SQL.EXECUTE(O_error_message,
                                     L_tran_type,
                                     I_inv_adj.item,
                                     L_store,
                                     L_wh,
                                     I_inv_adj.adj_date,
                                     I_vdate,
                                     I_inv_adj.adj_qty) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.PROCESS_AVAILABLE',
                                            to_char(SQLCODE));
      return FALSE;
END PROCESS_AVAILABLE;
--------------------------------------------------------------------------------
FUNCTION PROCESS_UNAVAILABLE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_inv_adj         IN       INV_ADJ%ROWTYPE,
                             I_adj_weight      IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                             I_adj_weight_uom  IN       UOM_CLASS.UOM%TYPE,
                             I_pgm_name        IN       TRAN_DATA.PGM_NAME%TYPE,
                             I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                             I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                             I_pack_ind        IN       ITEM_MASTER.PACK_IND%TYPE)
   RETURN BOOLEAN IS

   L_found      BOOLEAN := FALSE;
   L_tran_code  TRAN_DATA.TRAN_CODE%TYPE;
   ---
   L_comp_items_TBL          PACKITEM_ATTRIB_SQL.comp_item_TBL;
   L_comp_qtys_TBL           PACKITEM_ATTRIB_SQL.comp_qty_TBL;
   L_comp_item               INV_ADJ.ITEM%TYPE := NULL;
   L_comp_adj_qty            INV_ADJ.ADJ_QTY%TYPE := NULL;

BEGIN

   if I_pack_ind = 'Y' and I_inv_adj.loc_type = 'S' then

      if PACKITEM_ATTRIB_SQL.GET_COMP_QTYS(O_error_message,
                                           L_comp_items_TBL,
                                           L_comp_qtys_TBL,
                                           I_inv_adj.item) = FALSE then
         return FALSE;
      end if;

      FOR i in 1..L_comp_items_TBL.COUNT LOOP
         L_comp_item := L_comp_items_TBL(i);
         L_comp_adj_qty := I_inv_adj.adj_qty * L_comp_qtys_TBL(i);

         if BUILD_ADJ_UNAVAILABLE(O_error_message,
                                  L_found,
                                  L_comp_item,
                                  I_inv_adj.inv_status,
                                  I_inv_adj.loc_type,
                                  I_inv_adj.location,
                                  L_comp_adj_qty) = FALSE then
            return FALSE;
         end if;
      END LOOP;

   else

      if BUILD_ADJ_UNAVAILABLE(O_error_message,
                               L_found,
                               I_inv_adj.item,
                               I_inv_adj.inv_status,
                               I_inv_adj.loc_type,
                               I_inv_adj.location,
                               I_inv_adj.adj_qty) = FALSE then
         return FALSE;
      end if;

   end if;
   ---
   L_tran_code := 25;
   ---
   if BUILD_ADJ_TRAN_DATA(O_error_message,
                          L_found,
                          I_inv_adj.item,
                          I_inv_adj.loc_type,
                          I_inv_adj.location,
                          I_inv_adj.adj_qty,
                          I_adj_weight,
                          I_adj_weight_uom,
                          NULL,    --I_order_no
                          I_pgm_name,
                          I_inv_adj.adj_date,
                          L_tran_code,
                          I_inv_adj.reason,
                          I_inv_adj.inv_status,
                          I_wac,
                          I_unit_retail,
                          I_pack_ind) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.PROCESS_UNAVAILABLE',
                                            to_char(SQLCODE));
      return FALSE;
END PROCESS_UNAVAILABLE;
--------------------------------------------------------------------------------
FUNCTION INSERT_INV_ADJ(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        I_inv_adj         IN       INV_ADJ%ROWTYPE)
   RETURN BOOLEAN IS

BEGIN

   P_ia_size := P_ia_size + 1;
   P_ia_item(P_ia_size)     := I_inv_adj.item;
   P_ia_status(P_ia_size)   := I_inv_adj.inv_status;
   P_ia_loc_type(P_ia_size) := I_inv_adj.loc_type;
   P_ia_loc(P_ia_size)      := I_inv_adj.location;
   P_ia_qty(P_ia_size)      := I_inv_adj.adj_qty;
   P_ia_reason(P_ia_size)   := I_inv_adj.reason;
   P_ia_date(P_ia_size)     := I_inv_adj.adj_date;
   P_ia_prev_qty(P_ia_size) := I_inv_adj.prev_qty;
   P_ia_user(P_ia_size)     := I_inv_adj.user_id;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.INSERT_INV_ADJ',
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_INV_ADJ;
--------------------------------------------------------------------------------
FUNCTION CREATE_ITEM_LOC_REL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_item            IN       INV_ADJ.ITEM%TYPE,
                             I_location        IN       INV_ADJ.LOCATION%TYPE,
                             I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                             I_item_level      IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                             I_tran_level      IN       ITEM_MASTER.TRAN_LEVEL%TYPE,
                             I_pack_ind        IN       ITEM_MASTER.PACK_IND%TYPE,
                             I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE)
   RETURN BOOLEAN IS

BEGIN

   if NEW_ITEM_LOC(O_error_message,
                   I_item,
                   I_location,
                   NULL, -- ITEM_PARENT
                   NULL, -- ITEM_GRANDPARENT
                   I_loc_type,
                   NULL, -- SHORT_DESC
                   NULL, -- DEPT
                   NULL, -- CLASS
                   NULL, -- SUBCLASS
                   I_item_level,
                   I_tran_level,
                   NULL, -- ITEM_STATUS
                   NULL, -- ZONE_GROUP_ID
                   NULL, -- WASTE TYPE
                   NULL, -- DAILY WASTE PCT
                   NULL, -- SELLABLE_IND
                   NULL, -- ORDERABLE_IND
                   I_pack_ind,
                   NULL, -- PACK_TYPE
                   NULL, -- UNIT_COST_LOC
                   NULL, -- UNIT_RETAIL_LOC
                   NULL, -- SELLING_RETAIL_LOC
                   NULL, -- SELLING_UOM
                   NULL, -- ITEM_LOC_STATUS
                   NULL, -- TAXABLE_IND
                   NULL, -- TI
                   NULL, -- HI
                   NULL, -- STORE_ORD_MULT
                   NULL, -- MEAS_OF_EACH
                   NULL, -- MEAS_OF_PRICE
                   NULL, -- UOM_OF_PRICE
                   NULL, -- PRIMARY_VARIANT
                   NULL, -- PRIMARY_SUPP
                   NULL, -- PRIMARY_CNTRY
                   NULL, -- LOCAL_ITEM_DESC
                   NULL, -- LOCAL_SHORT_DESC
                   NULL, -- PRIMARY_COST_PACK
                   NULL, -- RECEIVE_AS_TYPE
                   I_adj_date,
                   NULL) = FALSE then -- DEFAULT_TO_CHILDREN
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.CREATE_ITEM_LOC_REL',
                                            to_char(SQLCODE));
      return FALSE;
END CREATE_ITEM_LOC_REL;
--------------------------------------------------------------------------------
FUNCTION VALIDATE_INVADJ(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_pack_ind         IN OUT   ITEM_MASTER.PACK_IND%TYPE,
                         O_simple_pack_ind  IN OUT   ITEM_MASTER.SIMPLE_PACK_IND%TYPE,
                         O_catch_weight_ind IN OUT   ITEM_MASTER.CATCH_WEIGHT_IND%TYPE,
                         IO_inv_adj         IN OUT   INV_ADJ%ROWTYPE)
   RETURN BOOLEAN IS

   --L_exists                 VARCHAR2(1) := NULL;
   L_found                  BOOLEAN;
   L_not_used               INV_ADJ_REASON.REASON_DESC%TYPE;
   ---
   L_receive_as_type        ITEM_LOC.RECEIVE_AS_TYPE%TYPE;
   ---
   INV_INV_STATUS           EXCEPTION;
   INV_REASON_CODE          EXCEPTION;
   INVALID_ITEM             EXCEPTION;
   INV_ADJ_RCV_AS_TYPE_WH   EXCEPTION;

   cursor C_ITEM_MASTER is
      select item_parent,
             tran_level,
             item_level,
             pack_ind,
             simple_pack_ind,
             catch_weight_ind
        from item_master
       where item = IO_inv_adj.item;
BEGIN

   if IO_inv_adj.inv_status is not NULL then
      if GET_INV_STATUS_TYPES(O_error_message,
                              IO_inv_adj.inv_status) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if IO_inv_adj.reason is not null then
      if INVADJ_VALIDATE_SQL.REASON_EXIST(IO_inv_adj.reason,
                                          L_not_used,
                                          O_error_message,
                                          L_found) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if L_found = FALSE then
      raise INV_REASON_CODE;
   end if;
   ---
   if (LP_prev_item is NULL) or (LP_prev_item != IO_inv_adj.item) then
      open C_ITEM_MASTER;
      fetch C_ITEM_MASTER into LP_item_parent,
                               LP_tran_level,
                               LP_item_level,
                               LP_pack_ind,
                               LP_simple_pack_ind,
                               LP_catch_weight_ind;
      close C_ITEM_MASTER;
   end if;
   LP_prev_item := IO_inv_adj.item;
   O_pack_ind   := LP_pack_ind;
   O_simple_pack_ind := LP_simple_pack_ind;
   O_catch_weight_ind := LP_catch_weight_ind;
   ---
   if LP_item_level is NULL then
      raise INVALID_ITEM;
   end if;
   ---
   if LP_item_level > LP_tran_level then
      if LP_item_parent is NULL then
         raise INVALID_ITEM;
      else
         IO_inv_adj.item := LP_item_parent;
      end if;
   end if;
   ---
   if ITEM_LOC_EXIST(O_error_message,
                     IO_inv_adj.prev_qty,
                     L_found,
                     IO_inv_adj.item,
                     IO_inv_adj.location,
                     IO_inv_adj.loc_type,
                     IO_inv_adj.inv_status) = FALSE then
      return FALSE;
   end if;
   ---
   if L_found = FALSE then
      if CREATE_ITEM_LOC_REL(O_error_message,
                             IO_inv_adj.item,
                             IO_inv_adj.location,
                             IO_inv_adj.loc_type,
                             LP_item_level,
                             LP_tran_level,
                             LP_pack_ind,
                             IO_inv_adj.adj_date) = FALSE then
         return FALSE;
      end if;
      ---
      IO_inv_adj.prev_qty := 0;
   end if;
   ---
   if LP_pack_ind = 'Y' then
      if ITEMLOC_ATTRIB_SQL.GET_RECEIVE_AS_TYPE(O_error_message,
                                                L_receive_as_type,
                                                IO_inv_adj.item,
                                                IO_inv_adj.location) = FALSE then
         return FALSE;
      end if;
      ---
      if L_receive_as_type = 'E' and
         IO_inv_adj.loc_type = 'W' then
         raise INV_ADJ_RCV_AS_TYPE_WH;
      end if;
   end if;
   ---
   return TRUE;


EXCEPTION
   when INV_REASON_CODE then
      O_error_message := SQL_LIB.CREATE_MSG('INV_REASON_CODE',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   when INVALID_ITEM then
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*O_error_message := SQL_LIB.CREATE_MSG('INVALID_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);*/

      --RIB error message enhancement
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_ITEM',
                                            'Item = '||IO_inv_adj.item,
                                            NULL,
                                            NULL);
      return FALSE;
   when INV_ADJ_RCV_AS_TYPE_WH then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ADJ_RCV_AS_TYPE_WH',
                                            IO_inv_adj.item,
                                            IO_inv_adj.location,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                               SQLERRM,
                               'INVADJ_SQL.VALIDATE_INVADJ',
                               to_char(SQLCODE));
      return FALSE;
END VALIDATE_INVADJ;
---------------------------------------------------------------------------------------------
FUNCTION ITEM_LOC_EXIST (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_stock_on_hand   IN OUT   ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         O_found           IN OUT   BOOLEAN,
                         I_item            IN       ITEM_MASTER.ITEM%TYPE,
                         I_location        IN       ITEM_LOC_SOH.LOC%TYPE,
                         I_loc_type        IN       ITEM_LOC_SOH.LOC_TYPE%TYPE,
                         I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_SQL.ITEM_LOC_EXIST';

   L_isq_index         BINARY_INTEGER := 0;

   cursor C_SOH is
      select stock_on_hand
        from item_loc_soh
       where loc      = I_location
         and item     = I_item;

BEGIN
   O_found := TRUE;
   ---
   if I_inv_status is not null then
      if GET_INV_STATUS_QTY (O_error_message,
                             O_stock_on_hand,
                             L_isq_index,
                             I_item,
                             I_location,
                             I_loc_type,
                             I_inv_status) = FALSE then
         return FALSE;
      end if;
      ---
      if O_stock_on_hand = 0 then
         O_found := FALSE;
      end if;
   else
      SQL_LIB.SET_MARK('OPEN','C_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
      open C_SOH;
      SQL_LIB.SET_MARK('FETCH','C_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
      fetch C_SOH into O_stock_on_hand;
      ---
      if C_SOH%NOTFOUND then
         O_found := FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
      close C_SOH;
      ---
      if P_ilsoh_size > 0 then
         FOR i in 1..P_ilsoh_size LOOP
            if P_ilsoh_item(i) = I_item and
               P_ilsoh_loc(i) = I_location then
               O_stock_on_hand := O_stock_on_hand + P_ilsoh_adj_qty(i);
            end if;
         END LOOP;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END ITEM_LOC_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION STOCKHOLDING_INVADJ(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_location        IN       INV_ADJ.LOCATION%TYPE,
                             I_loc_type        IN       INV_ADJ.LOC_TYPE%TYPE,
                             I_item            IN       INV_ADJ.ITEM%TYPE,
                             I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE,
                             I_reason          IN       INV_ADJ.REASON%TYPE,
                             I_adj_qty         IN       INV_ADJ.ADJ_QTY%TYPE,
                             I_adj_weight      IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                             I_adj_weight_uom  IN       UOM_CLASS.UOM%TYPE,
                             I_adj_date        IN       INV_ADJ.ADJ_DATE%TYPE,
                             I_wac             IN       ITEM_LOC_SOH.AV_COST%TYPE,
                             I_unit_retail     IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                             I_user_id         IN       INV_ADJ.USER_ID%TYPE,
                             I_vdate           IN       DATE,
                             I_pgm_name        IN       TRAN_DATA.PGM_NAME%TYPE)
   RETURN BOOLEAN IS

   L_inv_adj          INV_ADJ%ROWTYPE;
   L_prev_qty         INV_ADJ.PREV_QTY%TYPE;
   L_pack_ind         ITEM_MASTER.PACK_IND%TYPE;
   L_simple_pack_ind  ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_catch_weight_ind ITEM_MASTER.CATCH_WEIGHT_IND%TYPE;
   ---
   L_found            BOOLEAN;
   L_comp_items_TBL   PACKITEM_ATTRIB_SQL.comp_item_TBL;
   L_comp_qtys_TBL    PACKITEM_ATTRIB_SQL.comp_qty_TBL;

BEGIN
   ---
   L_inv_adj.item       := I_item;
   L_inv_adj.inv_status := I_inv_status;
   L_inv_adj.loc_type   := I_loc_type;
   L_inv_adj.location   := I_location;
   L_inv_adj.adj_qty    := I_adj_qty;
   L_inv_adj.reason     := I_reason;
   L_inv_adj.adj_date   := I_adj_date;
   L_inv_adj.user_id    := I_user_id;
   ---
   if VALIDATE_INVADJ(O_error_message,
                      L_pack_ind,
                      L_simple_pack_ind,
                      L_catch_weight_ind,
                      L_inv_adj) = FALSE then
      return FALSE;
   end if;
   ---
   if I_inv_status is NULL then
      if PROCESS_AVAILABLE(O_error_message,
                           L_inv_adj,
                           I_adj_weight,
                           I_adj_weight_uom,
                           I_vdate,
                           I_pgm_name,
                           I_wac,
                           I_unit_retail,
                           L_pack_ind) = FALSE then
         return FALSE;
      end if;
   else
      if PROCESS_UNAVAILABLE(O_error_message,
                             L_inv_adj,
                             I_adj_weight,
                             I_adj_weight_uom,
                             I_pgm_name,
                             I_wac,
                             I_unit_retail,
                             L_pack_ind) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if L_inv_adj.loc_type = 'S' and L_pack_ind = 'Y' then

      if PACKITEM_ATTRIB_SQL.GET_COMP_QTYS(O_error_message,
                                           L_comp_items_TBL,
                                           L_comp_qtys_TBL,
                                           I_item) = FALSE then
         return FALSE;
      end if;

      FOR i in 1..L_comp_items_TBL.COUNT LOOP
         L_inv_adj.item := L_comp_items_TBL(i);

         -- For a simple pack catch weight item, if component's standard uom is MASS,
         -- actual weight in standard uom is used for INV_ADJ.ADJ_QTY.
         -- The value should be in P_ilsoh_adj_qty(P_ilsoh_size).

         if L_simple_pack_ind = 'Y' and L_catch_weight_ind = 'Y' then
            L_inv_adj.adj_qty := P_ilsoh_adj_qty(P_ilsoh_size);
         else
            L_inv_adj.adj_qty := I_adj_qty * L_comp_qtys_TBL(i);
         end if;
         ---
         if INSERT_INV_ADJ(O_error_message,
                           L_inv_adj) = FALSE then
            return FALSE;
         end if;
      END LOOP;

   else
      if INSERT_INV_ADJ(O_error_message,
                        L_inv_adj) = FALSE then
         return FALSE;
      end if;
   end if;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.STOCKHOLDING_INVADJ',
                                            to_char(SQLCODE));
      return FALSE;
END STOCKHOLDING_INVADJ;
--------------------------------------------------------------------------------
FUNCTION GET_SYSTEM_INFO(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_multichannel_ind   IN OUT   SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE,
                         O_vdate              IN OUT   DATE)
   RETURN BOOLEAN IS

BEGIN

   if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                              O_multichannel_ind) = FALSE then
      return FALSE;
   end if;
   ---
   O_vdate            := LP_vdate;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.GET_SYSTEM_INFO',
                                            to_char(SQLCODE));
      return FALSE;
END GET_SYSTEM_INFO;
--------------------------------------------------------------------------------
FUNCTION GET_INV_STATUS_TYPES(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_inv_status      IN       INV_ADJ.INV_STATUS%TYPE)
   RETURN BOOLEAN IS

   INV_INV_STATUS        EXCEPTION;

   cursor C_INV_STATUS_TYPES is
      select *
        from inv_status_types;
BEGIN

   if LP_inv_status_types is NULL then
      open C_INV_STATUS_TYPES;
      fetch C_INV_STATUS_TYPES BULK COLLECT INTO LP_inv_status_types;
      close C_INV_STATUS_TYPES;
   end if;

   FOR i IN 1..LP_inv_status_types.COUNT LOOP
      if LP_inv_status_types(i).inv_status = I_inv_status then
         return TRUE;
      end if;
   END LOOP;

   raise INV_INV_STATUS;

EXCEPTION
   when INV_INV_STATUS then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INV_STATUS',
                                            I_inv_status,
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.GET_INV_STATUS',
                                            to_char(SQLCODE));
      return FALSE;
END GET_INV_STATUS_TYPES;
--------------------------------------------------------------------------------
FUNCTION GET_INV_STATUS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                 O_inv_status             IN OUT   INV_STATUS_CODES.INV_STATUS%TYPE,
                 I_inv_status_code        IN       INV_STATUS_CODES.INV_STATUS_CODE%TYPE)
   RETURN BOOLEAN IS

   INV_INV_STATUS_CODE   EXCEPTION;

   cursor C_INV_STATUS_CODES is
      select *
        from inv_status_codes;
BEGIN

   if LP_inv_status_codes is NULL then
      open C_INV_STATUS_CODES;
      fetch C_INV_STATUS_CODES BULK COLLECT INTO LP_inv_status_codes;
      close C_INV_STATUS_CODES;
   end if;

   FOR i IN 1..LP_inv_status_codes.COUNT LOOP
      if LP_inv_status_codes(i).inv_status_code = I_inv_status_code then
         O_inv_status := LP_inv_status_codes(i).inv_status;
         return TRUE;
      end if;
   END LOOP;

   raise INV_INV_STATUS_CODE;

EXCEPTION
   when INV_INV_STATUS_CODE then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INV_STATUS',
                                            I_inv_status_code,
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.GET_INV_STATUS',
                                            to_char(SQLCODE));
      return FALSE;
END GET_INV_STATUS;
--------------------------------------------------------------------------------------------
FUNCTION GET_REASON_INFO(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_reason_desc     IN OUT   INV_ADJ_REASON.REASON_DESC%TYPE,
                         O_cogs_ind        IN OUT   INV_ADJ_REASON.COGS_IND%TYPE,
                         I_reason          IN       INV_ADJ_REASON.REASON%TYPE)
   RETURN BOOLEAN IS

   cursor C_GET_REASON_INFO is
      select reason_desc,
             cogs_ind
        from inv_adj_reason
       where reason = I_reason;
BEGIN

   if I_reason is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_reason', 'NULL','NOT NULL');
      return FALSE;
   end if;

   open C_GET_REASON_INFO;
   fetch C_GET_REASON_INFO into O_reason_desc,
                                O_cogs_ind;
   if C_GET_REASON_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INVAL_REASON',null, null, null);
      close C_GET_REASON_INFO;
      return FALSE;
   end if;
   close C_GET_REASON_INFO;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVADJ_SQL.GET_REASON_INFO',
                                            to_char(SQLCODE));
      return FALSE;
END GET_REASON_INFO;
--------------------------------------------------------------------------------------------
FUNCTION GET_UNAVL_INV_QTY(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_total_unavail IN OUT INV_STATUS_QTY.QTY%TYPE,
                           I_item          IN     INV_STATUS_QTY.ITEM%TYPE,
                           I_inv_status    IN     INV_STATUS_QTY.INV_STATUS%TYPE,
                           I_loc_type      IN     INV_STATUS_QTY.LOC_TYPE%TYPE,
                           I_location      IN     INV_STATUS_QTY.LOCATION%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_SQL.GET_UNAVL_INV_QTY';
   L_finisher_ind  WH.FINISHER_IND%TYPE := 'N';

   cursor C_UNAVAILABLE_TOTAL is
      select sum(visq.qty)
        from v_inv_status_qty visq
       where visq.item       = I_item
         and visq.inv_status = decode(I_inv_status, -1, visq.inv_status, I_inv_status)
         and visq.loc_type   = NVL(I_loc_type, visq.loc_type)
         and visq.location   = NVL(I_location, visq.location);

   cursor C_UNAVAILABLE_TOTAL_W is
      select sum(visq.qty)
        from v_inv_status_qty visq,
             wh
       where visq.item       = I_item
         and visq.inv_status = decode(I_inv_status, -1, visq.inv_status, I_inv_status)
         and visq.loc_type   = 'W'
         and visq.location   = NVL(I_location, visq.location)
         and wh.wh           = visq.location
         and wh.finisher_ind = L_finisher_ind;

BEGIN
   O_total_unavail := 0;
   ---
   if ( I_loc_type in ('W', 'I') ) then
      if ( I_loc_type = 'I' ) then
         L_finisher_ind := 'Y';
      end if;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      ---
      /*SQL_LIB.SET_MARK('OPEN',
                       'C_UNAVAILABLE_TOTAL_W',
                       'V_INV_STATUS_QTY',
                       I_item);
      open C_UNAVAILABLE_TOTAL_W;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_UNAVAILABLE_TOTAL_W',
                       'V_INV_STATUS_QTY',
                       I_item);
      fetch C_UNAVAILABLE_TOTAL_W into O_total_unavail;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_UNAVAILABLE_TOTAL_W',
                       'V_INV_STATUS_QTY',
                       I_item);
      close C_UNAVAILABLE_TOTAL_W;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_UNAVAILABLE_TOTAL',
                       'V_INV_STATUS_QTY',
                       I_item);
      open C_UNAVAILABLE_TOTAL;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_UNAVAILABLE_TOTAL',
                       'V_INV_STATUS_QTY',
                       I_item);
      fetch C_UNAVAILABLE_TOTAL into O_total_unavail;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_UNAVAILABLE_TOTAL',
                       'V_INV_STATUS_QTY',
                       I_item);
      close C_UNAVAILABLE_TOTAL;*/

      --RIB error message enhancement
      SQL_LIB.SET_MARK('OPEN',
                       'C_UNAVAILABLE_TOTAL_W',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      open C_UNAVAILABLE_TOTAL_W;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_UNAVAILABLE_TOTAL_W',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      fetch C_UNAVAILABLE_TOTAL_W into O_total_unavail;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_UNAVAILABLE_TOTAL_W',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      close C_UNAVAILABLE_TOTAL_W;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_UNAVAILABLE_TOTAL',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      open C_UNAVAILABLE_TOTAL;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_UNAVAILABLE_TOTAL',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      fetch C_UNAVAILABLE_TOTAL into O_total_unavail;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_UNAVAILABLE_TOTAL',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      close C_UNAVAILABLE_TOTAL;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End

   end if;
   ---
   return TRUE;
   --
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_UNAVL_INV_QTY;
--------------------------------------------------------------------------------
FUNCTION UNAVL_INV_EXIST(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_exist         IN OUT BOOLEAN,
                         I_item          IN     INV_STATUS_QTY.ITEM%TYPE,
                         I_inv_status    IN     INV_STATUS_QTY.INV_STATUS%TYPE,
                         I_loc_type      IN     INV_STATUS_QTY.LOC_TYPE%TYPE,
                         I_location      IN     INV_STATUS_QTY.LOCATION%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'INVADJ_SQL.UNAVL_INV_EXIST';
   L_inv       VARCHAR2(1)  := NULL;

   cursor C_UNAV_INV is
      select 'x'
        from v_inv_status_qty
       where location   = I_location
         and item       = I_item
         and loc_type   = I_loc_type
         and inv_status = decode(I_inv_status, -1, inv_status, I_inv_status)
         and rownum     = 1;

   BEGIN
      O_exist := NULL;

      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  Begin
      --Following RIB error message has modified as the part of Performance issue.
      /*---
      SQL_LIB.SET_MARK('OPEN',
                       'C_UNAV_INV',
                       'V_INV_STATUS_QTY',
                       I_item);
      open  C_UNAV_INV;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_UNAV_INV',
                       'V_INV_STATUS_QTY',
                       I_item);
      fetch C_UNAV_INV into L_inv;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_UNAV_INV',
                       'V_INV_STATUS_QTY',
                       I_item);
      close C_UNAV_INV;
      ---*/

      --RIB error message enhancement
      SQL_LIB.SET_MARK('OPEN',
                       'C_UNAV_INV',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      open  C_UNAV_INV;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_UNAV_INV',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      fetch C_UNAV_INV into L_inv;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_UNAV_INV',
                       'V_INV_STATUS_QTY',
                       'item ='||I_item||' loc ='||I_location);
      close C_UNAV_INV;
      -- 06-Jan-2009   TESCO HSC/Nandini Mariyappa   Def# PrfNBS010460 and NBS00010460  End

      if L_inv is NULL then
         O_exist := FALSE;
      else
         O_exist := TRUE;
      end if;
      ---
      return TRUE;
      ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UNAVL_INV_EXIST;
-----------------------------------------------------------------------------------------
FUNCTION BUILD_PROCESS_INVADJ(O_error_message       IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_location            IN       INV_ADJ.LOCATION%TYPE,
                              I_item                IN       INV_ADJ.ITEM%TYPE,
                              I_reason              IN       INV_ADJ.REASON%TYPE,
                              I_adj_qty             IN       INV_ADJ.ADJ_QTY%TYPE,
                              I_adj_weight          IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE,
                              I_adj_weight_uom      IN       UOM_CLASS.UOM%TYPE,
                              I_from_disposition    IN       INV_STATUS_CODES.INV_STATUS_CODE%TYPE,
                              I_to_disposition      IN       INV_STATUS_CODES.INV_STATUS_CODE%TYPE,
                              I_user_id             IN       INV_ADJ.USER_ID%TYPE,
                              I_adj_date            IN       INV_ADJ.ADJ_DATE%TYPE,
                              I_doc_no              IN       NUMBER,
                              I_doc_type            IN       VARCHAR2,
                              I_wac                 IN       ITEM_LOC_SOH.AV_COST%TYPE,
                              I_unit_retail         IN       ITEM_LOC.UNIT_RETAIL%TYPE)
   RETURN BOOLEAN IS

   L_program            TRAN_DATA.PGM_NAME%TYPE := 'INVADJ_SQL.BUILD_PROCESS_INVADJ';
   L_multichannel_ind   SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;
   ---
   L_from_inv_status    INV_ADJ.INV_STATUS%TYPE;
   L_to_inv_status      INV_ADJ.INV_STATUS%TYPE;
   ---
   L_inv_status         INV_ADJ.INV_STATUS%TYPE;
   L_adj_qty            INV_ADJ.ADJ_QTY%TYPE;
   L_loc_type           INV_ADJ.LOC_TYPE%TYPE;
   ---
   L_vwh_ind            BOOLEAN := FALSE;
   ---
   L_adjust_total_soh   BOOLEAN := FALSE;
   TYPE INV_STATUS_ARRAY_TYPE IS TABLE OF INV_ADJ.INV_STATUS%TYPE
   INDEX BY BINARY_INTEGER;
   L_inv_status_array   INV_STATUS_ARRAY_TYPE;
   ---
   L_order_no           ORDHEAD.ORDER_NO%TYPE := NULL;
   L_exists             BOOLEAN;
   L_tsf_no             TSFHEAD.TSF_NO%TYPE := NULL;
   ---
   L_dist_tab           DISTRIBUTION_SQL.DIST_TABLE_TYPE;
   L_CMI                VARCHAR2(50);
   L_dist_inv_status    INV_ADJ.INV_STATUS%TYPE;
   L_dist_adj_qty       INV_ADJ.ADJ_QTY%TYPE;
   ---
   INV_DISTRIBUTION     EXCEPTION;
   ---
   L_tsf_type           TSFHEAD.TSF_TYPE%TYPE;
   L_tsf_shipment       SHIPMENT.SHIPMENT%TYPE;
   L_ship_seq_no        SHIPSKU.SEQ_NO%TYPE;
   L_dist_loc           WH.WH%TYPE;
   ---
   L_unit_weight         ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_adj_weight          ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE;
   L_uom_class           UOM_CLASS.UOM_CLASS%TYPE;
   L_item_rec            ITEM_MASTER%ROWTYPE;

   cursor C_GET_TSF_TYPE is
      select tsf_type
        from tsfhead
       where tsf_no = L_tsf_no;
   ---
   -- Currently only allow one shipment per Externally Generated Transfers
   -- in the case that there could be more than one in the future, this
   -- cursor will get the last shipment and assume the adjustment is against
   -- that one.
   ---
   cursor C_GET_TSF_SHIP is
      select max(shipment)
        from shipsku
       where item      = I_item
         and distro_no = L_tsf_no;

   ---
   -- Need to get the max sequence number for the max shipment number
   -- there could be multiple cartons for the transfer, the adjustment
   -- will go against the last carton shipped.
   ---
   cursor C_GET_TSF_SHIP_SEQ is
      select max(seq_no)
        from shipsku
       where item      = I_item
         and distro_no = L_tsf_no
         and shipment  = L_tsf_shipment;

   cursor C_GET_TSF_VWH is
      select to_loc
        from tsfhead
       where tsf_no = L_tsf_no;

   cursor C_GET_ALLOC_VWH is
      select ad.to_loc
        from alloc_detail ad,
             wh w
       where ad.to_loc =  nvl(w.wh, I_location)
         and w.wh (+) = ad.to_loc
         and w.physical_wh (+) = I_location
         --
         and ad.alloc_no = I_doc_no;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_item',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_location',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_adj_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_adj_qty',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_adj_qty = 0 then
      O_error_message := SQL_LIB.CREATE_MSG('ADJ_QTY_ZERO',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   elsif I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_user_id',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_adj_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_adj_date',
                                            'NULL','NOT NULL');
      return FALSE;
   elsif I_doc_type is NOT NULL and I_doc_type not in ('P','T') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM','I_doc_type',
                                            I_doc_type,'P or T');
      return FALSE;
   elsif I_from_disposition is NULL and I_to_disposition is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_DISPOSITION',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   --- Weight and weight UOM must be both populated or both null
   elsif I_adj_weight is NULL and I_adj_weight_uom is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('WGT_WGTUOM_REQUIRED',NULL,
                                            NULL,NULL);
      return FALSE;
   elsif I_adj_weight_uom is NULL and I_adj_weight is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('WGT_WGTUOM_REQUIRED',NULL,
                                            NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_adj_weight_uom is NOT NULL then
      if not UOM_SQL.GET_CLASS(O_error_message,
                               L_uom_class,
                               UPPER(I_adj_weight_uom)) then
         return FALSE;
      end if;

      if L_uom_class != 'MASS' then
         O_error_message := SQL_LIB.CREATE_MSG('INV_WGTUOM_CLASS',
                                               I_adj_weight_uom, L_uom_class, NULL);
         return FALSE;
      end if;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_rec,
                                         I_item) = FALSE then
      return FALSE;
   end if;

   if L_item_rec.orderable_ind = 'Y' and
      L_item_rec.sellable_ind  = 'N' and
      L_item_rec.inventory_ind = 'N' then
      O_error_message := SQL_LIB.CREATE_MSG('NO_NONINVENT_ITEM', NULL, NULL, NULL);
      return FALSE;
   end if;

   if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                              L_multichannel_ind) = FALSE then
      return FALSE;
   end if;
   ---
   if LOCATION_ATTRIB_SQL.GET_TYPE(O_error_message,
                                   L_loc_type,
                                   I_location) = FALSE then
      return FALSE;
   end if;
   ---
   if L_loc_type = 'W' then
      if WH_ATTRIB_SQL.CHECK_VWH(O_error_message,
                                 L_vwh_ind,
                                 I_location,
                                 'N') = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if I_from_disposition is not NULL then
      if GET_INV_STATUS(O_error_message,
                        L_from_inv_status,
                        I_from_disposition) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if I_to_disposition is not NULL then
      if GET_INV_STATUS(O_error_message,
                        L_to_inv_status,
                        I_to_disposition) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   /*
   *  null -> ATS
   *     Distribution rule performed:
   *        Inbound Distribution Rule (Positive Inventory Adjustment to SOH)
   *     Inventory Adjustment performed:
   *        Positive adjustment to SOH
   *
   *  ATS -> null
   *     Distribution rule performed:
   *        Outbound Distribution Rule (Negative Inventory Adjustment from SOH)
   *     Inventory Adjustment performed:
   *        Negative adjustment to SOH
   *
   *  null -> TRBL
   *     Distribution rule performed:
   *        Inbound Distribution Rule (Positive Inventory Adjustment to UI)
   *     Inventory Adjustment performed:
   *        Positive adjustment to SOH
   *        Positive adjustment to UI
   *
   *  TRBL -> null
   *     Distribution rule performed:
   *        Outbound Distribution Rule (Negative Inventory Adjustment from UI)
   *     Inventory Adjustment performed:
   *        Negative adjustment to UI
   *        Negative adjustment to SOH
   *
   *  ATS -> TRBL
   *     Distribution rule performed:
   *        Outbound Distribution Rule (Negative Inventory Adjustment from SOH)
   *     Inventory Adjustment performed:
   *        Positive adjustment to UI
   *     NOTE:  The dist rule does not match the invadj rule, must handle as
   *     a special case
   *
   *  TRBL -> ATS
   *     Distribution rule performed:
   *        Outbound Distribution Rule (Negative Inventory Adjustment from UI)
   *     Inventory Adjustment performed:
   *        Negative adjustment to UI
   */

   if I_from_disposition is not NULL and I_to_disposition is not NULL then
      if  NVL(L_from_inv_status,-999) = NVL(L_to_inv_status,-999) then
         return TRUE;   -- no disposition change, done
      end if;
      --
      if L_to_inv_status is NULL then
         L_adj_qty := -1;
         L_inv_status := L_from_inv_status;
      elsif L_from_inv_status is NULL then
         L_adj_qty := +1;
         L_inv_status := L_to_inv_status;
      end if;
   elsif I_from_disposition is NULL or I_to_disposition is NULL then
      if I_from_disposition is NULL then
         L_adj_qty    := +1;
         L_inv_status := L_to_inv_status;
      elsif I_to_disposition is NULL then
         L_adj_qty    := -1;
         L_inv_status := L_from_inv_status;
      end if;
      ---
      if L_inv_status is not null then
         -- adding or removing unavailable inventory requires an adjustment
         -- to overall soh as well.
         L_adjust_total_soh := TRUE;
      end if;
   end if;
   ---
   L_adj_qty  := L_adj_qty * ABS(I_adj_qty);
   ---
   if L_multichannel_ind = 'Y' and
      L_loc_type         = 'W' and
      L_vwh_ind          = FALSE then
      ---
      L_CMI := 'INVADJ';
      ---
      if I_doc_type = 'P' then
         ---
         if I_doc_no is not NULL then
            if ORDER_ATTRIB_SQL.ITEMS_EXIST(O_error_message,
                                            L_exists,
                                            I_doc_no) = FALSE then
               return FALSE;
            end if;
            ---
            if L_exists = TRUE then
               L_order_no := I_doc_no;
               L_CMI      := 'ORDRCV';
            end if;
         end if;
         ---
      elsif I_doc_type = 'T' then
         L_tsf_no := I_doc_no;
         ---
         -- Get the transfer type
         ---
         open C_GET_TSF_TYPE;
         fetch C_GET_TSF_TYPE into L_tsf_type;
         close C_GET_TSF_TYPE;
         ---
         if L_tsf_type = 'EG' then
            ---
            -- Currently only allow one shipment per Externally Generated Transfers
            -- in the case that there could be more than one in the future, this
            -- cursor will get the last shipment and assume the adjustment is against
            -- that one.
            ---
            open C_GET_TSF_SHIP;
            fetch C_GET_TSF_SHIP into L_tsf_shipment;
            close C_GET_TSF_SHIP;
            ---
            -- Need to get the max sequence number for the max shipment number
            -- there could be multiple cartons for the transfer, the adjustment
            -- will go against the last carton shipped.
            ---
            open C_GET_TSF_SHIP_SEQ;
            fetch C_GET_TSF_SHIP_SEQ into L_ship_seq_no;
            close C_GET_TSF_SHIP_SEQ;
            ---
            L_CMI := 'TRANSFER';
         else
            ---
            -- If the transfer is not externally generated then we need to make the
            -- passed in adjustment for the virtual wh on the transfer.
            -- Since any transfer adjustment passed into this package
            -- will be for a physcial wh we need to get virtual wh from the transfer.
            ---
            open C_GET_TSF_VWH;
            fetch C_GET_TSF_VWH into L_dist_tab(1).wh;
            close C_GET_TSF_VWH;
            ---
            L_dist_tab(1).dist_qty := L_adj_qty;
         end if;
      elsif I_doc_type = 'A' then
         open C_GET_ALLOC_VWH;
         fetch C_GET_ALLOC_VWH into L_dist_tab(1).wh;
         close C_GET_ALLOC_VWH;
         ---
         L_dist_tab(1).dist_qty := L_adj_qty;
      end if;
      --
      -- This statement handles the special case where the distribution rule
      -- does not match the inventory adjustment rule
      if (I_from_disposition is not NULL and I_to_disposition is not NULL) and
      L_from_inv_status is NULL then
         L_dist_inv_status := null;
         L_dist_adj_qty := -1 * L_adj_qty;
      else
         L_dist_inv_status := L_inv_status;
         L_dist_adj_qty := L_adj_qty;
      end if;
      ---
      -- No need to perform distribution logic for non-EG transfers.
      ---
      if (L_tsf_no is not NULL and L_tsf_type = 'EG') or L_tsf_no is NULL then
         ---
         -- The item_loc_soh table needs to be flushed before calling the distribution
         -- package.  The distribution package needs the current values on this table.
         ---
         if FLUSH_SOH_UPDATE (O_error_message) = FALSE then
            return FALSE;
         end if;
         ---
         if DISTRIBUTION_SQL.DISTRIBUTE(O_error_message,
                                        L_dist_tab,
                                        I_item,
                                        I_location,
                                        L_dist_adj_qty,
                                        --
                                        L_CMI,
                                        L_dist_inv_status,
                                        NULL,               -- I_to_loc_type
                                        NULL,               -- I_to_loc
                                        L_order_no,         -- I_order_no
                                        L_tsf_shipment,              -- I_shipment
                                        L_ship_seq_no) = FALSE then  -- I_seq_no
            return FALSE;
         end if;
         --
         if L_dist_tab.count = 0 then
            raise INV_DISTRIBUTION;
         end if;
         --
         -- This statement handles the special case where the distribution rule
         -- does not match the inventory adjustment rule
         if (I_from_disposition is not NULL and I_to_disposition is not NULL) and
         L_from_inv_status is NULL then
            for i in L_dist_tab.first .. L_dist_tab.last
            loop
               L_dist_tab(i).dist_qty := -1 * L_dist_tab(i).dist_qty;
            end loop;
         end if;
      end if;
   else
      L_dist_tab(1).wh       := I_location;
      L_dist_tab(1).dist_qty := L_adj_qty;
   end if;
   ---
   if L_adjust_total_soh = TRUE then
      if L_adj_qty < 0 then
         -- adjust unavilable inventory first then adjust soh
         L_inv_status_array(1) := L_inv_status;
         L_inv_status_array(2) := null;
      else
         -- adjust osh first then adjust unavilable inventory
         L_inv_status_array(1) := null;
         L_inv_status_array(2) := L_inv_status;
      end if;
   else
      L_inv_status_array(1) := L_inv_status;
   end if;

   for i in L_dist_tab.first .. L_dist_tab.last
   loop
      for j in L_inv_status_array.first .. L_inv_status_array.last
      loop
         L_dist_loc := L_dist_tab(i).wh;
         ---
         if L_tsf_no is not NULL and L_tsf_type = 'EG' then
            L_dist_loc := L_dist_tab(i).to_loc;
         end if;
         ---
         if I_adj_weight is NOT NULL     and
            I_adj_weight_uom is NOT NULL then
            L_unit_weight := I_adj_weight/I_adj_qty;
            L_adj_weight := L_dist_tab(i).dist_qty * L_unit_weight;
         end if;

         if STOCKHOLDING_INVADJ(O_error_message,
                                L_dist_loc,
                                L_loc_type,
                                I_item,
                                L_inv_status_array(j),
                                I_reason,
                                L_dist_tab(i).dist_qty,
                                L_adj_weight,
                                I_adj_weight_uom,
                                I_adj_date,
                                I_wac,
                                I_unit_retail,
                                I_user_id,
                                LP_vdate,
                                L_program) = FALSE then
            return FALSE;
         end if;
      end loop;
   end loop;
   ---

   return TRUE;

EXCEPTION
   when INV_DISTRIBUTION then
      O_error_message := SQL_LIB.CREATE_MSG('INV_DISTRIBUTION',
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
END BUILD_PROCESS_INVADJ;
--------------------------------------------------------------------------------
-- The following functions are used to bulk DML statements together
--------------------------------------------------------------------------------
FUNCTION INIT_INV_ADJ_INSERT (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64)     := 'STKLEDGR_SQL.INIT_INV_ADJ_INSERT';

BEGIN

   P_ia_size := 0;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                            L_program,NULL);
      RETURN FALSE;
END INIT_INV_ADJ_INSERT;

-------------------------------------------------------------------------------
FUNCTION FLUSH_INV_ADJ_INSERT(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_function              VARCHAR2(60) := 'INVADJ_SQL.FLUSH_INV_ADJ_INSERT';

BEGIN

   if P_ia_size > 0 then
      SQL_LIB.SET_MARK('INSERT',NULL,'inv_adj', 'BULK INSERT');
      ---
      FORALL i IN 1..P_ia_size
         insert into inv_adj(item,
                             inv_status,
                             loc_type,
                             location,
                             adj_qty,
                             reason,
                             adj_date,
                             prev_qty,
                             user_id)
                     values( P_ia_item(i),
                             P_ia_status(i),
                             P_ia_loc_type(i),
                             P_ia_loc(i),
                             P_ia_qty(i),
                             P_ia_reason(i),
                             P_ia_date(i),
                             P_ia_prev_qty(i),
                             P_ia_user(i));
   end if;

   P_ia_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_function,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END FLUSH_INV_ADJ_INSERT;
--------------------------------------------------------------------------------
FUNCTION INIT_SOH_UPDATE (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64)     := 'STKLEDGR_SQL.INIT_SOH_UPDATE';

BEGIN

   P_ilsoh_size := 0;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                            L_program,NULL);
      RETURN FALSE;
END INIT_SOH_UPDATE;
-------------------------------------------------------------------------------
FUNCTION FLUSH_SOH_UPDATE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_function              VARCHAR2(60) := 'INVADJ_SQL.FLUSH_SOH_UPDATE';
   L_loc_type              ITEM_LOC_SOH.LOC_TYPE%TYPE;
   L_flag                  BOOLEAN;
   L_vwh_name              WH.WH_NAME%TYPE;
   L_item                  ITEM_LOC_SOH.ITEM%TYPE;
   L_loc                   ITEM_LOC_SOH.LOC%TYPE;
   L_non_sellable          ITEM_LOC_SOH.PACK_COMP_NON_SELLABLE%TYPE :=0;

   cursor C_PACK_COMP_NON_SELL is
      -- 28-Oct-2008 TESCO HSC/Murali 6840037 Begin
      select pq.qty,
             pq.item
        from v_packsku_qty pq,
             item_loc_soh ils
       where pq.pack_no = L_item
         and pq.item = ils.item
         and ils.loc = L_loc;
      -- 28-Oct-2008 TESCO HSC/Murali 6840037 Begin

BEGIN

   if P_ilsoh_size > 0 then
      SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_LOC_SOH', 'BULK UPDATE');
      ---
      FORALL i IN 1..P_ilsoh_size
        update item_loc_soh
           set stock_on_hand        = stock_on_hand + P_ilsoh_adj_qty(i),
               soh_update_datetime  = DECODE(P_ilsoh_adj_qty(i),
                                             0, soh_update_datetime,
                                                P_ilsoh_date(i)),
               pack_comp_soh        = pack_comp_soh + P_ilsoh_pcsoh_adj_qty(i),
               non_sellable_qty     = non_sellable_qty + P_ilsoh_non_sell_qty(i),
               average_weight       = NVL(P_ilsoh_average_weight(i),average_weight),
               last_update_datetime = P_ilsoh_date(i),
               last_update_id       = P_ilsoh_user(i)
         where item = P_ilsoh_item(i)
           and loc  = P_ilsoh_loc(i);

      FOR i IN 1..P_ilsoh_size loop

         L_item := P_ilsoh_item(i);
         L_loc := P_ilsoh_loc(i);
         L_non_sellable := P_ilsoh_non_sell_qty(i);

         if L_non_sellable != 0 then
            SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_LOC_SOH', 'ITEM: '||L_item);

            FOR rec in C_PACK_COMP_NON_SELL LOOP
               update item_loc_soh
                  -- 28-Oct-2008 TESCO HSC/Murali 6840037 Begin
                  set pack_comp_non_sellable = pack_comp_non_sellable + L_non_sellable * rec.qty
                  -- 28-Oct-2008 TESCO HSC/Murali 6840037 End
                where item = rec.item
                  and loc = L_loc;
            END LOOP;
         end if;
      END LOOP;

      FOR i IN 1..P_ilsoh_size LOOP

         if LOCATION_ATTRIB_SQL.GET_TYPE(O_error_message,
                                         L_loc_type,
                                         P_ilsoh_loc(i)) = FALSE then
            return FALSE;
         end if;

         if L_loc_type = 'W' then
            if WH_ATTRIB_SQL.CHECK_FINISHER(O_error_message,
                                            L_flag,
                                            L_vwh_name,
                                            P_ilsoh_loc(i))= FALSE then
               return FALSE;
            end if;
         end if;

         if L_loc_type = 'E' or L_flag = TRUE then
            if BOL_SQL.PUT_ILS_AV_RETAIL(O_error_message,
                                         P_ilsoh_loc(i),
                                         L_loc_type,
                                         P_ilsoh_item(i),
                                         NULL,
                                         NULL,
                                         NULL,
                                         P_ilsoh_adj_qty(i))  = FALSE then
               return FALSE;
            end if;
         end if;
      END LOOP;
   end if;

   P_ilsoh_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_function,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END FLUSH_SOH_UPDATE;
--------------------------------------------------------------------------------
FUNCTION INIT_INV_STAT_QTY (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64)     := 'STKLEDGR_SQL.INIT_INV_STAT_QTY';

BEGIN

   P_isq_size := 0;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,
                                            L_program,NULL);
      RETURN FALSE;
END INIT_INV_STAT_QTY;
-------------------------------------------------------------------------------
FUNCTION FLUSH_INV_STAT_QTY(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_function              VARCHAR2(60) := 'INVADJ_SQL.FLUSH_INV_STAT_QTY';

BEGIN

   if P_isq_size > 0 then
      ------
      SQL_LIB.SET_MARK('INSERT',NULL,'inv_status_qty','BULK INSERT');
      ---
      FORALL i IN 1..P_isq_size
         insert into inv_status_qty(item,
                                    inv_status,
                                    loc_type,
                                    location,
                                    qty,
                                    create_datetime,
                                    last_update_datetime,
                                    last_update_id)
                             select P_isq_item(i),
                                    P_isq_status(i),
                                    P_isq_loc_type(i),
                                    P_isq_loc(i),
                                    P_isq_qty(i),
                                    P_isq_date(i),
                                    P_isq_date(i),
                                    P_isq_user(i)
                               from dual
                              where P_isq_insert_ind(i) = 'Y'
                                and P_isq_deleted_ind(i) = 'N';
      ------
      SQL_LIB.SET_MARK('UPDATE',NULL,'inv_status_qty','BULK UPDATE');
      ---
      FORALL i IN 1..P_isq_size
         update inv_status_qty isq
            set isq.qty                   = P_isq_qty(i),
                isq.last_update_datetime  = P_isq_date(i),
                isq.last_update_id        = P_isq_user(i)
          where isq.item         = P_isq_item(i)
            and isq.inv_status   = P_isq_status(i)
            and isq.location     = P_isq_loc(i)
            and P_isq_insert_ind(i) = 'N'
            and P_isq_deleted_ind(i) = 'N';
      ------
      SQL_LIB.SET_MARK('DELETE',NULL,'inv_status_qty','BULK DELETE');
      ---
      FORALL i IN 1..P_isq_size
        delete inv_status_qty
         where item         = P_isq_item(i)
           and inv_status   = P_isq_status(i)
           and location     = P_isq_loc(i)
           and P_isq_insert_ind(i) = 'N'
           and P_isq_deleted_ind(i) = 'Y';
   end if;

   P_isq_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_function,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END FLUSH_INV_STAT_QTY;
--------------------------------------------------------------------------------------------
FUNCTION INIT_ALL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_SQL.INIT_ALL';

   cursor C_GET_VDATE is
      select vdate
        from period;

BEGIN

   open C_GET_VDATE;
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_VDATE',
                    'PERIOD',
                    NULL);

   fetch C_GET_VDATE into LP_vdate;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_VDATE',
                    'PERIOD',
                    NULL);

   close C_GET_VDATE;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_VDATE',
                    'PERIOD',
                    NULL);

   --empty out cache of update statements for item_loc_soh
   if INIT_SOH_UPDATE (O_error_message) = FALSE then
      return FALSE;
   end if;

   --empty out cache of insert, update, and delete statements for inv_status_qty
   if INIT_INV_STAT_QTY (O_error_message) = FALSE then
      return FALSE;
   end if;

   --empty out cache of insert statements for inv_adj
   if INIT_INV_ADJ_INSERT (O_error_message) = FALSE then
      return FALSE;
   end if;

   --empty out cache of tran_data inserts
   if STKLEDGR_SQL.INIT_TRAN_DATA_INSERT (O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END INIT_ALL;
--------------------------------------------------------------------------------------------
FUNCTION FLUSH_ALL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_SQL.FLUSH_ALL';

BEGIN

   --call flush
   if FLUSH_SOH_UPDATE (O_error_message) = FALSE then
      return FALSE;
   end if;

   --call flush
   if FLUSH_INV_STAT_QTY (O_error_message) = FALSE then
      return FALSE;
   end if;

   --call flush
   if FLUSH_INV_ADJ_INSERT (O_error_message) = FALSE then
      return FALSE;
   end if;

   --call flush
   if STKLEDGR_SQL.FLUSH_TRAN_DATA_INSERT (O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END FLUSH_ALL;
-------------------------------------------------------------------------------
FUNCTION ADD_ILSOH_UPDATE_REC(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item             IN       ITEM_MASTER.ITEM%TYPE,
                              I_location         IN       ITEM_LOC_SOH.LOC%TYPE,
                              I_soh_adj_qty      IN       ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                              I_pcsoh_adj_qty    IN       ITEM_LOC_SOH.PACK_COMP_SOH%TYPE,
                              I_non_sell_qty     IN       ITEM_LOC_SOH.NON_SELLABLE_QTY%TYPE,
                              I_average_weight   IN       ITEM_LOC_SOH.AVERAGE_WEIGHT%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_SQL.ADD_ILSOH_UPDATE_REC';

BEGIN

   P_ilsoh_size := P_ilsoh_size + 1;
   P_ilsoh_item(P_ilsoh_size) := I_item;
   P_ilsoh_loc(P_ilsoh_size) := I_location;
   P_ilsoh_adj_qty(P_ilsoh_size) := I_soh_adj_qty;
   P_ilsoh_pcsoh_adj_qty(P_ilsoh_size) := I_pcsoh_adj_qty;
   P_ilsoh_non_sell_qty(P_ilsoh_size) := I_non_sell_qty;
   P_ilsoh_average_weight(P_ilsoh_size) := I_average_weight;
   P_ilsoh_date(P_ilsoh_size) := sysdate;
   P_ilsoh_user(P_ilsoh_size) := LP_userid;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END ADD_ILSOH_UPDATE_REC;
--------------------------------------------------------------------------------
END INVADJ_SQL;
/

