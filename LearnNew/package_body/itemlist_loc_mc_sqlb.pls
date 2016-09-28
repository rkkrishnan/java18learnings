CREATE OR REPLACE PACKAGE BODY ITEMLIST_LOC_MC_SQL IS

LP_user_id        USER_USERS.USERNAME%TYPE;
LP_parent_ind     VARCHAR(1) := 'N';  --indicates whether the process is for parent_item
LP_list_ind       VARCHAR(1) := 'N';  --indicates whether the process is for an itemlist
LP_supp_ind       VARCHAR(1) := 'N';  --indicates whether supplier is valid
LP_parent_item    VARCHAR(1) := 'N';  --indicates whether item is parent item or not
LP_tran_from_list VARCHAR(1) := 'N';  --indicates item is tran level from item list
LP_pos_update_ind VARCHAR(1) := 'N';  --indicates if item can be inserted to pos_mods table
------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    30-Jul-2007
--Mod Ref:     Mod number. 365b
--Mod Details: Amended script to explodes the base varient item information.
------------------------------------------------------------------------------------------------
--------------------------------------------------------------------
--
-- PRIVATE FUNCTIONS
--
--------------------------------------------------------------------

--------------------------------------------------------------------
-- PROCESS_ITEM_ATTRIBUTES:
--   Called by the ITEM function when loop through each item/location;
--   Update item/location record's status, status_update_date,
--     taxable_ind, and primary_supplier fields in ITEM_LOC table
--   if required by update flags.
--------------------------------------------------------------------
 FUNCTION PROCESS_ITEM_ATTRIBUTES(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                                  I_loc                     IN       ITEM_LOC.LOC%TYPE,
                                  I_loc_type                IN       ITEM_LOC.LOC_TYPE%TYPE,
                                  I_cb1                     IN       VARCHAR2,
                                  I_status                  IN       ITEM_LOC.STATUS%TYPE,
                                  I_cb2                     IN       VARCHAR2,
                                  I_taxable_ind             IN       ITEM_LOC.TAXABLE_IND%TYPE,
                                  I_cb3                     IN       VARCHAR2,
                                  I_supplier                IN       SUPS.SUPPLIER%TYPE,
                                  I_primary_country         IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                                  I_cb4                     IN       VARCHAR2,
                                  I_daily_waste_pct         IN       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                                  I_cb5                     IN       VARCHAR2,
                                  I_meas_of_each            IN       ITEM_LOC.MEAS_OF_EACH%TYPE,
                                  I_cb6                     IN       VARCHAR2,
                                  I_meas_of_price           IN       ITEM_LOC.MEAS_OF_PRICE%TYPE,
                                  I_cb7                     IN       VARCHAR2,
                                  I_uom_of_price            IN       ITEM_LOC.UOM_OF_PRICE%TYPE,
                                  I_cb8                     IN       VARCHAR2,
                                  I_primary_variant         IN       ITEM_LOC.PRIMARY_VARIANT%TYPE,
                                  I_cb9                     IN       VARCHAR2,
                                  I_ti                      IN       ITEM_LOC.TI%TYPE,
                                  I_cb10                    IN       VARCHAR2,
                                  I_hi                      IN       ITEM_LOC.HI%TYPE,
                                  I_cb11                    IN       VARCHAR2,
                                  I_loc_item_desc           IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                                  I_cb12                    IN       VARCHAR2,
                                  I_loc_short_desc          IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                                  I_cb13                    IN       VARCHAR2,
                                  I_primary_cost_pack       IN       ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                                  I_cb14                    IN       VARCHAR2,
                                  I_source_method           IN       ITEM_LOC.SOURCE_METHOD%TYPE,
                                  I_source_wh               IN       ITEM_LOC.SOURCE_WH%TYPE,
                                  I_cb15                    IN       VARCHAR2,
                                  I_store_ord_mult          IN       ITEM_LOC.STORE_ORD_MULT%TYPE,
                                  I_cb16                    IN       VARCHAR2,
                                  I_inbound_handling_days   IN       ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE)
   RETURN BOOLEAN IS

   L_current_status         ITEM_LOC.status%TYPE;
   L_current_tax_ind        ITEM_LOC.taxable_ind%TYPE;
   L_current_loc_item_desc  ITEM_LOC.local_item_desc%TYPE;
   L_current_loc_short_desc ITEM_LOC.local_short_desc %TYPE;
   L_return_date            PERIOD.VDATE%TYPE := get_vdate;
   L_simple_pack_ind        ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_table                  VARCHAR2(20);
   RECORD_LOCKED            EXCEPTION;
   PRAGMA                   EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_GET is
      select status,
             taxable_ind,
             local_item_desc,
             local_short_desc
        from item_loc
       where item = I_item
         and loc = I_loc;
  ---
   cursor C_LOCK is
      select 'x'
        from item_loc
       where item = I_item
         and loc = I_loc
         for update nowait;

   BEGIN
   if LP_pos_update_ind = 'Y' then
      if (I_cb1  = 'Y' or
          I_cb2  = 'Y' or
          I_cb11 = 'Y' or
          I_cb12 = 'Y') then
         open C_GET;
         fetch C_GET into L_current_status,
                          L_current_tax_ind,
                          L_current_loc_item_desc,
                          L_current_loc_short_desc;
         close C_GET;
      end if;

      ---if item status is being updated, get current status and compare to
      ---new status.  If they are different, write out POS_MODS records for
      ---the ITEM.

      if I_cb1 = 'Y' and I_loc_type = 'S' then
         if I_status != L_current_status then
            if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                              25,
                                              I_item,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_loc,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              (L_return_date+1),
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_status,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;

      ---if tax indicator is being updated, get current indicator and compare to
      ---new indicator.  If they are different, write out POS_MODS records for
      ---the item.
      if I_cb2 = 'Y' and I_loc_type = 'S' then
         if L_current_tax_ind != I_taxable_ind then
            if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                              26,
                                              I_item,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_loc,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              (L_return_date+1),
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_taxable_ind,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL) = FALSE then
               return FALSE;
            end if;
          end if;
      end if;

      ---if local item description is being updated, get current description and
      ---compare to new description.  If they are different, write out POS_MODS
      ---records for the item.
      if I_cb11 = 'Y'
      and I_loc_type = 'S'
      then
         if L_current_loc_item_desc != I_loc_item_desc then
            if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                              12,
                                              I_item,
                                              I_loc_item_desc,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_loc,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              (L_return_date+1),
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL) = FALSE then
               return FALSE;
            end if;
          end if;
      end if;

      ---if local short description is being updated, get current description and
      ---compare to new description.  If they are different, write out POS_MODS
      ---records for the item.
      if I_cb12 = 'Y'
      and I_loc_type = 'S'
      then
         if L_current_loc_short_desc != I_loc_short_desc then
            if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                              10,
                                              I_item,
                                              I_loc_short_desc,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_loc,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              (L_return_date+1),
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL) = FALSE then
               return FALSE;
            end if;
          end if;
      end if;
   end if; -- end of pos_update_ind
   ---updates the base cost accordiing the changes supp/primary country.

   if (LP_supp_ind = 'Y' and LP_parent_ind = 'N') or
      (LP_supp_ind = 'Y' and LP_parent_item = 'Y') then
      if not UPDATE_BASE_COST.CHG_ITEMLOC_PRIM_SUPP_CNTRY(O_error_message,
                                                          I_item,
                                                          I_loc,
                                                          I_supplier,
                                                          I_primary_country,
                                                          LP_parent_ind,
                                                          NULL /* Cost Change Number */ ) then
         RETURN FALSE;
      end if;
   end if;

   -- If changing the item status to a value other than 'Active', then check if the item is a simple pack,
   -- next remove it as a primary cost pack
   if I_cb1 = 'Y' and I_status != 'A' then
      if ITEM_ATTRIB_SQL.GET_SIMPLE_PACK_IND(O_error_message,
                                             L_simple_pack_ind,
                                             I_item) = FALSE then
         RETURN FALSE;
      end if;

      if L_simple_pack_ind = 'Y' then
         if ITEM_LOC_SQL.UPDATE_PRIMARY_COST_PACK(O_error_message,
                                                  I_item,
                                                  I_loc) = FALSE then
            RETURN FALSE;
         end if;
      end if;
   end if;

   ---update item attributes, decodes used to determine if update is required
   ---(ie. if I_cbn = Y then update attribute - means update checkbox has
   ---been checked)

   L_table := 'ITEM_LOC';
   open C_LOCK;
   close C_LOCK;
   update item_loc
      set status               = decode(I_cb1,
                                        'Y',
                                        I_status,
                                        status),
          status_update_date   = decode(I_cb1,
                                        'Y',
                                        L_return_date,
                                        status_update_date),
          taxable_ind          = decode(I_cb2,
                                        'Y',
                                        I_taxable_ind,
                                        taxable_ind),
          primary_supp        = decode(I_cb3,
                                       'N',
                                       primary_supp,
                                       (decode (I_supplier,
                                                NULL,
                                                primary_supp,
                                                I_supplier))),
          primary_cntry       = decode(I_cb3,
                                       'N',
                                       primary_cntry,
                                       (decode (I_primary_country,
                                                NULL,
                                                primary_cntry,
                                                I_primary_country))),

          daily_waste_pct      = decode(I_cb4,
                                        'Y',
                                        I_daily_waste_pct,
                                        daily_waste_pct),
          meas_of_each         = decode(I_cb5,
                                        'Y',
                                        I_meas_of_each,
                                        meas_of_each),
          meas_of_price        = decode(I_cb6,
                                        'Y',
                                        I_meas_of_price,
                                        meas_of_price),
          uom_of_price         = decode(I_cb7,
                                        'Y',
                                        I_uom_of_price,
                                        uom_of_price),
          primary_variant      = decode(I_cb8,
                                        'Y',
                                        I_primary_variant,
                                        primary_variant),
          ti                  = decode(I_cb9,
                                       'N',
                                       ti,
                                       (decode (I_ti,
                                                NULL,
                                                ti,
                                                I_ti))),
          hi                  = decode(I_cb10,
                                       'N',
                                       hi,
                                       (decode (I_hi,
                                                NULL,
                                                hi,
                                                I_hi))),
          local_item_desc      = decode(I_cb11,
                                        'Y',
                                        I_loc_item_desc,
                                        local_item_desc),
          local_short_desc     = decode(I_cb12,
                                        'Y',
                                        I_loc_short_desc,
                                        local_short_desc),
          primary_cost_pack   = decode(I_cb13,
                                       'N',
                                       primary_cost_pack,
                                       (decode (I_primary_cost_pack,
                                                NULL,
                                                primary_cost_pack,
                                                I_primary_cost_pack))),
          source_method        = decode(I_cb14,
                                        'Y',
                                        I_source_method,
                                        source_method),
          source_wh            = decode(I_source_method,
                                        'W',
                                        I_source_wh,
                                        (decode(I_source_method,
                                                NULL,
                                                source_wh,
                                                NULL))),
          store_ord_mult       = decode(I_cb15,
                                        'Y',
                                        I_store_ord_mult,
                                        store_ord_mult),
          inbound_handling_days = decode(I_cb16,
                                         'Y',
                                         I_inbound_handling_days,
                                         inbound_handling_days),
          last_update_datetime = SYSDATE,
          last_update_id       = USER
    where item   = I_item
      and loc    = I_loc;
   RETURN TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            to_char(I_loc));
      RETURN FALSE;
   when OTHERS then
      O_error_message := O_error_message||SQLERRM||' from PROCESS_ITEM_ATTRIBUTES function.';
      RETURN FALSE;
END PROCESS_ITEM_ATTRIBUTES;

--------------------------------------------------------------------
-- CHECK_NEW_STATUS:
--   Called by the CHECK_ITEM_STATUS function when loop through each item/location;
--   Check if the status of the item/location can be updated. If not,
--     it will be rejected by calling ITEMLIST.MC_REJECTS_SQL.
--     INSERT_REJECTS.
-------------------------------------------------------------------
 FUNCTION CHECK_NEW_STATUS(O_error_message IN OUT VARCHAR2,
                            O_reject_report IN OUT VARCHAR2,
                            I_item          IN     ITEM_LOC.ITEM%TYPE,
                            I_loc           IN     ITEM_LOC.LOC%TYPE,
                            I_loc_type      IN     ITEM_LOC.LOC_TYPE%TYPE,
                            I_status        IN     ITEM_LOC.STATUS%TYPE,
                            I_update_ind    IN     VARCHAR2
                            --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   Begin
                            , I_called_ind  IN     VARCHAR2 DEFAULT 'N')
                            --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   End
          RETURN BOOLEAN IS

   L_exists      VARCHAR2(1)               := NULL;
   L_repl_wh     VARCHAR2(1)               := NULL;
   L_active      BOOLEAN;
   L_date        PERIOD.VDATE%TYPE             := GET_VDATE;
   L_table_name  daily_purge.table_name%TYPE   := NULL;
   ---
   cursor C_REPL is
      select 'Y'
        from repl_item_loc
       where item      = I_item
         and source_wh = I_loc
         and stock_cat in('C','L');
   ---
   cursor C_ORDERS_EXIST is
      select 'Y'
        from ordloc ol,
             ordhead oh
       where oh.order_no = ol.order_no
         and ol.location = I_loc
         and ol.item     = I_item
         and oh.status in ('W', 'S', 'A');
   ---
   cursor C_TRANSFERS_EXIST is
      select 'Y'
        from tsfhead th,
             tsfdetail td
       where th.status in ('I','A','S','E')
         and th.to_loc = I_loc
         and th.tsf_no = td.tsf_no
      and td.item   = I_item;
    ---
    --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   Begin
   cursor C_VAL_VARIANT_STATUS is
      select 'Y'
        from item_loc    il,
             item_master im
       where il.item           = im.tsl_base_item
         and il.loc            = I_loc
         and il.loc_type       = I_loc_type
         and il.status        != I_status
         and im.item           = I_item
         and im.tsl_base_item != im.item;
   ---
   L_exists_variant   BOOLEAN     := FALSE;
   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   End

 BEGIN
   O_reject_report := 'FALSE';
   --- check if ITEM is in an active pack item, if yes status cannot be changed (reject it)
   if I_status in ('I', 'C', 'D') then
      if I_loc_type = 'W' then
         open C_REPL;
         fetch C_REPL into L_repl_wh;
         close C_REPL;
         if L_repl_wh = 'Y' and I_update_ind = 'Y' then
            if ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                                      I_item,
                                                      I_loc_type,
                                                      I_loc,
                                                      'L',
                                                      'CANNOT_CHANGE_REPL_WH',
                                                      LP_user_id,
                                                      NULL,
                                                      NULL,
                                                      NULL) = FALSE then
               RETURN FALSE;
            end if;
            O_reject_report := 'TRUE';
            RETURN TRUE;
         end if;
      end if;
      ---

   end if;
   ---
   if I_status in ('D','I') then
      if ITEMLOC_ATTRIB_SQL.ITEM_IN_ACTIVE_PACK(O_error_message,
                                                I_item,
                                                I_loc,
                                                L_active) = FALSE then
         RETURN FALSE;
      end if;
      if L_active = TRUE and I_update_ind = 'Y' then
         if ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                                   I_item,
                                                   I_loc_type,
                                                   I_loc,
                                                   'L',
                                                   'SKU_IN_ACTIVE_PACK',
                                                   LP_user_id,
                                                   NULL,
                                                   NULL,
                                                   NULL) = FALSE then
            RETURN FALSE;
         end if;
         O_reject_report := 'TRUE';
         RETURN TRUE;
      end if;
      if NOT ITEM_STATUS_SQL.CHECK_ITEM(O_error_message,
                                        L_exists,
                                        I_item,
                                        NULL,
                                        I_loc) then
         RETURN FALSE;
      end if;
      if L_exists = 'Y' and I_update_ind = 'Y' then
         if ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                                   I_item,
                                                   I_loc_type,
                                                   I_loc,
                                                   'L',
                                                   'ITEM_IN_USE',
                                                   LP_user_id,
                                                   NULL,
                                                   NULL,
                                                   NULL) = FALSE then
            RETURN FALSE;
         end if;
         O_reject_report := 'TRUE';
         RETURN TRUE;
      end if;


      open C_ORDERS_EXIST;
      fetch C_ORDERS_EXIST into L_exists;
      close C_ORDERS_EXIST;
   ---
      if L_exists = 'Y' and I_update_ind = 'Y' then
         if ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                                   I_item,
                                                   I_loc_type,
                                                   I_loc,
                                                   'L',
                                                   'SKU_ORD_EXIST',
                                                   LP_user_id,
                                                   NULL,
                                                   NULL,
                                                   NULL) = FALSE then
            RETURN FALSE;
         end if;
         O_reject_report := 'TRUE';
         RETURN TRUE;
      end if;
   ---
      open C_TRANSFERS_EXIST;
      fetch C_TRANSFERS_EXIST into L_exists;
      close C_TRANSFERS_EXIST;
   ---
      if L_exists = 'Y' and I_update_ind = 'Y' then
         if ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                                   I_item,
                                                   I_loc_type,
                                                   I_loc,
                                                   'L',
                                                   'SKU_TSF_EXIST',
                                                   LP_user_id,
                                                   NULL,
                                                   NULL,
                                                   NULL) = FALSE then
            RETURN FALSE;
         end if;
         O_reject_report := 'TRUE';
         RETURN TRUE;
      end if;
   end if;

   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   Begin
   if I_called_ind = 'Y' then
      if TSL_BASE_VARIANT_SQL.VALIDATE_VARIANT_ITEM(O_error_message,
                                                    L_exists_variant,
                                                    I_item) = FALSE then
         return FALSE;

      end if;
      ---
      if L_exists_variant = TRUE then
         SQL_LIB.SET_MARK('OPEN',
                          'C_VAL_VARIANT_STATUS',
                          'ITEM_MASTER, ITEM_LOC',
                          'ITEM: ' || I_item);
         open C_VAL_VARIANT_STATUS;
         SQL_LIB.SET_MARK('FETCH',
                          'C_VAL_VARIANT_STATUS',
                          'ITEM_MASTER, ITEM_LOC',
                          'ITEM: ' || I_item);
         fetch C_VAL_VARIANT_STATUS into L_exists;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_VAL_VARIANT_STATUS',
                          'ITEM_MASTER, ITEM_LOC',
                          'ITEM: ' || I_item);
         close C_VAL_VARIANT_STATUS;
         ---
         if L_exists = 'Y' and I_update_ind = 'Y'then
            if ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                                      I_item,
                                                      I_loc_type,
                                                      I_loc,
                                                      'L',
                                                      'TSL_NOT_VAR_LOC_STATUS',
                                                      LP_user_id,
                                                      NULL,
                                                      NULL,
                                                      NULL) = FALSE then
               return FALSE;
            end if;
            O_reject_report := 'TRUE';
            return TRUE;
         end if;
      end if;
   end if;
   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   End
   if L_exists = 'Y' or L_repl_wh = 'Y' or L_active = TRUE then
      O_reject_report := 'TRUE';
   end if;

   ---
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := O_error_message||SQLERRM||' from CHECK_NEW_STATUS function.';
      RETURN FALSE;
END CHECK_NEW_STATUS;

--------------------------------------------------------------------
-- CHECK_ITEM_STATUS:
--   Called by the ITEM function when loop through each item/location;
--   Check if the status of the item/location can be updated. If not,
--     it will be rejected by calling ITEMLIST.MC_REJECTS_SQL.
--     INSERT_REJECTS.
--------------------------------------------------------------------
 FUNCTION CHECK_ITEM_STATUS(O_error_message IN OUT VARCHAR2,
                            O_reject_report IN OUT VARCHAR2,
                            I_item          IN     ITEM_LOC.ITEM%TYPE,
                            I_loc           IN     ITEM_LOC.LOC%TYPE,
                            I_loc_type      IN     ITEM_LOC.LOC_TYPE%TYPE,
                            I_status        IN     ITEM_LOC.STATUS%TYPE
                             --10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting Begin
                            , I_called_ind  IN     VARCHAR2 DEFAULT 'N')
                            -- 10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting End
                     RETURN BOOLEAN IS

L_update_ind             VARCHAR2(1)            := 'Y';

cursor C_GET_ITEM_CHILDREN is
   select item
     from item_master
    where ((item_parent = I_item) or
           (item_grandparent = I_item))
     and tran_level = item_level;


 BEGIN

   if LP_parent_ind ='Y'then
      if CHECK_NEW_STATUS(O_error_message,
                          O_reject_report,
                          I_item,
                          I_loc,
                          I_loc_type,
                          I_status,
                          'Y'
                          --10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting Begin
                           , I_called_ind
                          -- 10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting End
                          ) = FALSE then
         RETURN FALSE;
      end if;
      if O_reject_report = 'TRUE' then
         RETURN TRUE;
      end if;

      FOR item_rec IN C_GET_ITEM_CHILDREN LOOP
         if CHECK_NEW_STATUS(O_error_message,
                             O_reject_report,
                             item_rec.item,
                             I_loc,
                             I_loc_type,
                             I_status,
                             'N'
                             --10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting Begin
                             , I_called_ind
                             -- 10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting End
                            ) = FALSE then
            RETURN FALSE;
         end if;
         if O_reject_report ='TRUE' then
            exit;
         end if;
      END LOOP;
   else
      if CHECK_NEW_STATUS(O_error_message,
                          O_reject_report,
                          I_item,
                          I_loc,
                          I_loc_type,
                          I_status,
                          'Y'
                          --10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting Begin
                           , I_called_ind
                          -- 10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting End
                          ) = FALSE then
         RETURN FALSE;
      end if;
   end if;

   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := O_error_message||SQLERRM||' from CHECK_ITEM_STATUS function.';
      RETURN FALSE;
END CHECK_ITEM_STATUS;
--------------------------------------------------------------------
-- CHECK_SUPPLIER:
--   Called by the ITEM function;
--   Validate the new supplier for the item being maintained by
--     checking the association of the item and the supplier in
--     table ITEM_SUPPLIER. If not, ITEMLIST_MC_REJECTS_SQL.
--     INSERT_REJECTS will be called
--------------------------------------------------------------------
FUNCTION CHECK_SUPPLIER(O_error_message   IN OUT VARCHAR2,
                        O_reject_report   IN OUT VARCHAR2,
                        I_item            IN     ITEM_LOC.ITEM%TYPE,
                        I_supplier        IN     SUPS.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_supplier_ind      VARCHAR2(1) := 'N';
   L_dummy             item_supp_country.origin_country_id%TYPE := NULL;
   L_exist             boolean;
   L_supplier          item_loc.primary_supp%TYPE := I_supplier;
   ---
   cursor C_ITEM_SUPPLIER is
      select 'Y'
        from item_supp_country
       where item      = I_item
         and supplier  = I_supplier;
BEGIN
   if LP_parent_ind = 'N' then

       open C_ITEM_SUPPLIER;
      fetch C_ITEM_SUPPLIER into L_supplier_ind;
      close C_ITEM_SUPPLIER;

      if L_supplier_ind = 'Y' then
         L_exist := TRUE;
      else
         L_exist := FALSE;
      end if;

   elsif LP_parent_ind = 'Y' then
      if not SUPP_ITEM_SQL.CHECK_CHILD_ITSUPPCNTRY(O_error_message,
                                                   L_exist,
                                                   I_item,
                                                   L_supplier,
                                                   L_dummy) then
         RETURN FALSE;
      end if;
   end if;
   ---
   if not L_exist then
      if NOT ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                                    I_item,
                                                    NULL,
                                                    NULL,
                                                    'L',
                                                    'ITEM_SUPPLIER',
                                                    LP_user_id,
                                                    I_supplier,
                                                    NULL,
                                                    NULL) then
         RETURN FALSE;
      end if;
      O_reject_report := 'TRUE';
   else
      LP_supp_ind := 'Y';
      O_reject_report := 'FALSE';
   end if;
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := O_error_message||SQLERRM||' from CHECK_SUPPLIER function.';
      RETURN FALSE;
END CHECK_SUPPLIER;

--------------------------------------------------------------------
--
-- PUBLIC FUNCTIONS
--
--------------------------------------------------------------------
FUNCTION ITEM_LIST (O_error_message           IN OUT   VARCHAR2,
                    O_reject_report           IN OUT   VARCHAR2,
                    I_item_list               IN       SKULIST_HEAD.SKULIST%TYPE,
                    I_cb1                     IN       VARCHAR2,
                    I_status                  IN       ITEM_LOC.STATUS%TYPE,
                    I_cb2                     IN       VARCHAR2,
                    I_taxable_ind             IN       ITEM_LOC.TAXABLE_IND%TYPE,
                    I_cb3                     IN       VARCHAR2,
                    I_supplier                IN       SUPS.SUPPLIER%TYPE,
                    I_primary_country         IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                    I_cb4                     IN       VARCHAR2,
                    I_daily_waste_pct         IN       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                    I_cb5                     IN       VARCHAR2,
                    I_meas_of_each            IN       ITEM_LOC.MEAS_OF_EACH%TYPE,
                    I_cb6                     IN       VARCHAR2,
                    I_meas_of_price           IN       ITEM_LOC.MEAS_OF_PRICE%TYPE,
                    I_cb7                     IN       VARCHAR2,
                    I_uom_of_price            IN       ITEM_LOC.UOM_OF_PRICE%TYPE,
                    I_cb8                     IN       VARCHAR2,
                    I_primary_variant         IN       ITEM_LOC.PRIMARY_VARIANT%TYPE,
                    I_cb9                     IN       VARCHAR2,
                    I_ti                      IN       ITEM_LOC.TI%TYPE,
                    I_cb10                    IN       VARCHAR2,
                    I_hi                      IN       ITEM_LOC.HI%TYPE,
                    I_cb11                    IN       VARCHAR2,
                    I_loc_item_desc           IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                    I_cb12                    IN       VARCHAR2,
                    I_loc_short_desc          IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                    I_cb13                    IN       VARCHAR2,
                    I_primary_cost_pack       IN       ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                    I_cb14                    IN       VARCHAR2,
                    I_source_method           IN       ITEM_LOC.SOURCE_METHOD%TYPE,
                    I_source_wh               IN       ITEM_LOC.SOURCE_WH%TYPE,
                    I_cb15                    IN       VARCHAR2,
                    I_store_ord_mult          IN       ITEM_LOC.STORE_ORD_MULT%TYPE,
                    I_cb16                    IN       VARCHAR2,
                    I_inbound_handling_days   IN       ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE,
                    I_user_id                 IN       USER_USERS.USERNAME%TYPE)
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64)                     := 'ITEMLIST_STORE_MC_SQL.ITEM_LIST';
   L_item                   SKULIST_DETAIL.ITEM%TYPE         := NULL;
   L_item_level             SKULIST_DETAIL.ITEM_LEVEL%TYPE   := NULL;
   L_tran_level             SKULIST_DETAIL.TRAN_LEVEL%TYPE   := NULL;
   L_item_reject_report     VARCHAR2(5);
   L_parent_reject_report   VARCHAR2(5);

   ---
   cursor C_ITEM_LIST is
      select item,
             item_level,
             tran_level
        from skulist_detail
       where skulist = I_item_list;

BEGIN
   LP_user_id  := I_user_id;
   LP_list_ind := 'Y';
   O_reject_report := 'FALSE';
   -- loop to retrieve each item in item list
   for c1 in C_ITEM_LIST LOOP
      L_item       := c1.item;
      L_item_level := c1.item_level;
      L_tran_level := c1.tran_level;

      -- if the item in the item list has item_level = tran_level then
      -- call ITEM processing procedure.

      if L_item_level = L_tran_level then
         LP_tran_from_list := 'Y';
         if ITEM (O_error_message,
                  L_item_reject_report,
                  L_item,
                  I_cb1, I_status,
                  I_cb2, I_taxable_ind,
                  I_cb3, I_supplier,
                  I_primary_country,
                  I_cb4, I_daily_waste_pct,
                  I_cb5, I_meas_of_each,
                  I_cb6, I_meas_of_price,
                  I_cb7, I_uom_of_price,
                  I_cb8, I_primary_variant,
                  I_cb9, I_ti,
                  I_cb10, I_hi,
                  I_cb11, I_loc_item_desc,
                  I_cb12, I_loc_short_desc,
                  I_cb13, I_primary_cost_pack,
                  I_cb14, I_source_method,
                          I_source_wh,
                  I_cb15, I_store_ord_mult,
                  I_cb16, I_inbound_handling_days,
                  LP_user_id) = FALSE then
            RETURN FALSE;
         end if;
         if L_item_reject_report = 'TRUE' then
            O_reject_report := 'TRUE';
         end if;

      -- if item_level is smaller than
      -- tran_leve then call ITEM_PARENT.

      elsif L_item_level < L_tran_level then
         LP_tran_from_list := 'N';
         if ITEM_PARENT(O_error_message,
                        L_parent_reject_report,
                        L_item,
                        I_cb1, I_status,
                        I_cb2, I_taxable_ind,
                        I_cb3, I_supplier,
                        I_primary_country,
                        I_cb4, I_daily_waste_pct,
                        I_cb5, I_meas_of_each,
                        I_cb6, I_meas_of_price,
                        I_cb7, I_uom_of_price,
                        I_cb8, I_primary_variant,
                        I_cb9, I_ti,
                        I_cb10, I_hi,
                        I_cb11, I_loc_item_desc,
                        I_cb12, I_loc_short_desc,
                        'N',    I_primary_cost_pack,
                        I_cb14, I_source_method,
                                I_source_wh,
                        I_cb15, I_store_ord_mult,
                        I_cb16, I_inbound_handling_days,
                        LP_user_id) = FALSE then
            RETURN FALSE;
         end if;
         if L_parent_reject_report = 'TRUE' then
            O_reject_report := 'TRUE';
         end if;
      else
         -- item_level of the item is greater than tran-level therefore reject it
         if ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                             L_item,
                              NULL,
                              NULL,
                              'L',
                              'BELOW_TRAN_LEVEL',
                              LP_user_id,
                              NULL,
                              NULL,
                              NULL) = FALSE then
            RETURN FALSE;
         end if;
         O_reject_report := 'TRUE';
      end if;
   END LOOP;
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,L_program,null);
      RETURN FALSE;
END ITEM_LIST;
--------------------------------------------------------------------
FUNCTION ITEM_PARENT (O_error_message           IN OUT   VARCHAR2,
                      O_reject_report           IN OUT   VARCHAR2,
                      I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                      I_cb1                     IN       VARCHAR2,
                      I_status                  IN       ITEM_LOC.STATUS%TYPE,
                      I_cb2                     IN       VARCHAR2,
                      I_taxable_ind             IN       ITEM_LOC.TAXABLE_IND%TYPE,
                      I_cb3                     IN       VARCHAR2,
                      I_supplier                IN       SUPS.SUPPLIER%TYPE,
                      I_primary_country         IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                      I_cb4                     IN       VARCHAR2,
                      I_daily_waste_pct         IN       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                      I_cb5                     IN       VARCHAR2,
                      I_meas_of_each            IN       ITEM_LOC.MEAS_OF_EACH%TYPE,
                      I_cb6                     IN       VARCHAR2,
                      I_meas_of_price           IN       ITEM_LOC.MEAS_OF_PRICE%TYPE,
                      I_cb7                     IN       VARCHAR2,
                      I_uom_of_price            IN       ITEM_LOC.UOM_OF_PRICE%TYPE,
                      I_cb8                     IN       VARCHAR2,
                      I_primary_variant         IN       ITEM_LOC.PRIMARY_VARIANT%TYPE,
                      I_cb9                     IN       VARCHAR2,
                      I_ti                      IN       ITEM_LOC.TI%TYPE,
                      I_cb10                    IN       VARCHAR2,
                      I_hi                      IN       ITEM_LOC.HI%TYPE,
                      I_cb11                    IN       VARCHAR2,
                      I_loc_item_desc           IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                      I_cb12                    IN       VARCHAR2,
                      I_loc_short_desc          IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                      I_cb13                    IN       VARCHAR2,
                      I_primary_cost_pack       IN       ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                      I_cb14                    IN       VARCHAR2,
                      I_source_method           IN       ITEM_LOC.SOURCE_METHOD%TYPE,
                      I_source_wh               IN       ITEM_LOC.SOURCE_WH%TYPE,
                      I_cb15                    IN       VARCHAR2,
                      I_store_ord_mult          IN       ITEM_LOC.STORE_ORD_MULT%TYPE,
                      I_cb16                    IN       VARCHAR2,
                      I_inbound_handling_days   IN       ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE,
                      I_user_id                 IN       USER_USERS.USERNAME%TYPE)
   RETURN BOOLEAN IS

   L_program             VARCHAR2(64)       := 'ITEMLIST_STORE_MC_SQL.STYLE';
   L_item                ITEM_LOC.ITEM%TYPE := NULL;
   L_item_reject_report  VARCHAR2(5);
   L_table               VARCHAR2(20);
   ---
   L_item_level          ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level          ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_status              ITEM_MASTER.STATUS%TYPE;
   ---
   cursor C_EXPLODE_ITEM is
      select item,
             item_level,
             tran_level,
             status
        from item_master
       where (item_parent  = I_item or
              item_grandparent = I_item);

   cursor C_PARENT_ITEM is
     select item,
             item_level,
             tran_level,
             status
        from item_master
       where item = I_item;


BEGIN
   LP_user_id := I_user_id;
   LP_parent_ind := 'Y';
   O_reject_report := 'FALSE';
   if I_cb3 = 'Y' and LP_list_ind = 'N' then
      if NOT CHECK_SUPPLIER(O_error_message,
                            O_reject_report,
                            I_item,
                            I_supplier) then
         RETURN FALSE;
      else
         if O_reject_report = 'TRUE' then
            RETURN TRUE;
         end if;
      end if;
   end if;

   --updates the passed in item.
   LP_parent_item    := 'Y';

   OPEN C_PARENT_ITEM;
   fetch C_PARENT_ITEM into L_item,L_item_level,L_tran_level,L_status;
   CLOSE C_PARENT_ITEM;

   if L_status = 'A' and l_item_level=L_tran_level then
      LP_pos_update_ind := 'Y';
   else
      LP_pos_update_ind := 'N';
   end if;

   if ITEM (O_error_message,
            L_item_reject_report,
            I_item,
            I_cb1, I_status,
            I_cb2, I_taxable_ind,
            I_cb3, I_supplier,
            I_primary_country,
            I_cb4, I_daily_waste_pct,
            I_cb5, I_meas_of_each,
            I_cb6, I_meas_of_price,
            I_cb7, I_uom_of_price,
            I_cb8, I_primary_variant,
            I_cb9, I_ti,
            I_cb10, I_hi,
            I_cb11, I_loc_item_desc,
            I_cb12, I_loc_short_desc,
            I_cb13, I_primary_cost_pack,
            I_cb14, I_source_method,
                    I_source_wh,
            I_cb15, I_store_ord_mult,
            I_cb16, I_inbound_handling_days,
            LP_user_id) = FALSE then
      RETURN FALSE;
   end if;
   if L_item_reject_report = 'TRUE' then
      O_reject_report := 'TRUE';
   end if;

   -- loop to retrieve each item in the grandparent
   LP_parent_item := 'N';
   for c2 in C_EXPLODE_ITEM LOOP
      L_item := c2.item;
      ---
      if (c2.item_level = c2.tran_level) and
         c2.status = 'A' then
         LP_pos_update_ind := 'Y';
      else
         LP_pos_update_ind := 'N';
      end if;
      ---
      if ITEM (O_error_message,
               L_item_reject_report,
               L_item,
               I_cb1, I_status,
               I_cb2, I_taxable_ind,
               I_cb3, I_supplier,
               I_primary_country,
               I_cb4, I_daily_waste_pct,
               I_cb5, I_meas_of_each,
               I_cb6, I_meas_of_price,
               I_cb7, I_uom_of_price,
               I_cb8, I_primary_variant,
               I_cb9, I_ti,
               I_cb10, I_hi,
               I_cb11, I_loc_item_desc,
               I_cb12, I_loc_short_desc,
               'N', I_primary_cost_pack,
               I_cb14, I_source_method,
                       I_source_wh,
               I_cb15, I_store_ord_mult,
               I_cb16, I_inbound_handling_days,
               LP_user_id) = FALSE then
         RETURN FALSE;
      end if;
      if L_item_reject_report = 'TRUE' then
         O_reject_report := 'TRUE';
      end if;
   END LOOP;

   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,L_program,null);
      RETURN FALSE;
END ITEM_PARENT;
--------------------------------------------------------------------
 FUNCTION ITEM (O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                O_reject_report           IN OUT   VARCHAR2,
                I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                I_cb1                     IN       VARCHAR2,
                I_status                  IN       ITEM_LOC.STATUS%TYPE,
                I_cb2                     IN       VARCHAR2,
                I_taxable_ind             IN       ITEM_LOC.TAXABLE_IND%TYPE,
                I_cb3                     IN       VARCHAR2,
                I_supplier                IN       SUPS.SUPPLIER%TYPE,
                I_primary_country         IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                I_cb4                     IN       VARCHAR2,
                I_daily_waste_pct         IN       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                I_cb5                     IN       VARCHAR2,
                I_meas_of_each            IN       ITEM_LOC.MEAS_OF_EACH%TYPE,
                I_cb6                     IN       VARCHAR2,
                I_meas_of_price           IN       ITEM_LOC.MEAS_OF_PRICE%TYPE,
                I_cb7                     IN       VARCHAR2,
                I_uom_of_price            IN       ITEM_LOC.UOM_OF_PRICE%TYPE,
                I_cb8                     IN       VARCHAR2,
                I_primary_variant         IN       ITEM_LOC.PRIMARY_VARIANT%TYPE,
                I_cb9                     IN       VARCHAR2,
                I_ti                      IN       ITEM_LOC.TI%TYPE,
                I_cb10                    IN       VARCHAR2,
                I_hi                      IN       ITEM_LOC.HI%TYPE,
                I_cb11                    IN       VARCHAR2,
                I_loc_item_desc           IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                I_cb12                    IN       VARCHAR2,
                I_loc_short_desc          IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                I_cb13                    IN       VARCHAR2,
                I_primary_cost_pack       IN       ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                I_cb14                    IN       VARCHAR2,
                I_source_method           IN       ITEM_LOC.SOURCE_METHOD%TYPE,
                I_source_wh               IN       ITEM_LOC.SOURCE_WH%TYPE,
                I_cb15                    IN       VARCHAR2,
                I_store_ord_mult          IN       ITEM_LOC.STORE_ORD_MULT%TYPE,
                I_cb16                    IN       VARCHAR2,
                I_inbound_handling_days   IN       ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE,
                I_user_id                 IN       USER_USERS.USERNAME%TYPE
                --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   Begin
                ,I_call_from_variant      IN       VARCHAR2 DEFAULT 'N')
                --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a
   RETURN BOOLEAN IS

   L_program                VARCHAR2(64)                          := 'ITEMLIST_STORE_MC_SQL.ITEM';
   L_loc                    ITEM_LOC.LOC%TYPE                     := NULL;
   L_loc_type               ITEM_LOC.LOC_TYPE%TYPE                := NULL;
   L_status_reject_report   VARCHAR2(5)                           := 'FALSE';
   L_cb4                    VARCHAR2(1)                           := NULL;
   L_daily_waste_pct        ITEM_LOC.DAILY_WASTE_PCT%TYPE         := NULL;
   L_waste_pct              ITEM_MASTER.WASTE_PCT%TYPE;
   L_waste_type             ITEM_MASTER.WASTE_TYPE%TYPE;
   L_default_waste_pct      ITEM_MASTER.DEFAULT_WASTE_PCT%TYPE;
   L_status                 ITEM_MASTER.STATUS%TYPE               := NULL;
   L_pack_loc_status        ITEM_LOC.STATUS%TYPE;
   L_error_message          RTK_ERRORS.RTK_TEXT%TYPE              := NULL;
   L_item_master            ITEM_MASTER%ROWTYPE;
   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   Begin
   --L_update_ind             VARCHAR2(1);
   L_update_ind             VARCHAR2(1) := 'N';
   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   End
   L_finisher_ind           WH.FINISHER_IND%TYPE                  := NULL;
   L_inbound_handling_days  ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE   := NULL;
   L_item_level             VARCHAR2(1)                           := 'N';
   ---

   cursor C_LOCATION is
      select temp.location,
             temp.loc_type,
             wh.finisher_ind
        from mc_location_temp temp,
             item_loc il,
             wh wh
       where temp.location = il.loc
         and il.loc        = wh.wh (+)
         and il.item       = I_item;
   ---
   cursor C_STATUS is
      select status
        from item_master
       where item = I_item;
   ---
   cursor C_CHECK_ITEM_LEVEL is
      select  'Y'
        from item_master
       where item_level != tran_level
	 and item = I_item;

BEGIN
   LP_user_id := I_user_id;
   O_reject_report := 'FALSE';
   -- first check if valid supplier
   -- if called from ITEM_PARENT, check is not required since it's done in
   -- ITEM_PARENT function (ie. if supplier is valid at parent level, it's
   -- valid at SKU level)
   -- if called from ITEM_LIST function check has to be done

   if I_cb3 = 'Y' and LP_parent_ind = 'N' and LP_list_ind = 'N' then
      if NOT CHECK_SUPPLIER(O_error_message,
                            O_reject_report,
                            I_item,
                            I_supplier) then
         RETURN FALSE;
      else
         if O_reject_report = 'TRUE' then
            RETURN TRUE;
         end if;
      end if;
   end if;
   ---
   -- Retrieve item information from item_master
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;

   -- Determine if item is sellable-only item.
   -- The L_update_ind will replace the update status
   -- indicators I_cb3, I_cb9, I_cb10 and I_cb13. This indicator
   -- will restrict the update of Primary Supplier, Primary
   -- Country, Ti, Hi and Primary Cost Pack for sellable-only items.
   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   Begin
   if I_call_from_variant = 'N' then
   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   End
     if (L_item_master.sellable_ind = 'Y') and
        (L_item_master.orderable_ind = 'N') then
        L_update_ind := 'N';
     else
        L_update_ind := 'Y';
     end if;
   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   Begin
   else
      LP_supp_ind := 'N';
   end if;
   --18-July-2007 WiproEnabler/Nuno Correia - MOD 365a   End

   if ITEM_ATTRIB_SQL.GET_WASTAGE(L_error_message,
                                  L_waste_type,
                                  L_waste_pct,
                                  L_default_waste_pct,
                                  I_item) = FALSE then
      return FALSE;
   end if;

   if L_waste_type = 'SP' then
      L_cb4 := I_cb4;
      L_daily_waste_pct := I_daily_waste_pct;
   else
      L_cb4 := 'N';
      L_daily_waste_pct := NULL;
   end if;
   ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_STATUS',
                       'item_master',
                       'item: '||I_item);

      open C_STATUS;

      SQL_LIB.SET_MARK('fetch',
                       'C_STATUS',
                       'item_master',
                       'item: '||I_item);

      fetch C_STATUS into L_status;

      SQL_LIB.SET_MARK('close',
                       'C_STATUS',
                       'item_master',
                       'item: '||I_item);

      close C_STATUS;

      SQL_LIB.SET_MARK('OPEN',
                       'C_CHECK_ITEM_LEVEL',
                       'item_master',
                       'item: '||I_item);

      open C_CHECK_ITEM_LEVEL;

      SQL_LIB.SET_MARK('fetch',
                       'C_CHECK_ITEM_LEVEL',
                       'item_master',
                       'item: '||I_item);

      fetch C_CHECK_ITEM_LEVEL into L_item_level;

      SQL_LIB.SET_MARK('close',
                       'C_CHECK_ITEM_LEVEL',
                       'item_master',
                       'item: '||I_item);

      close C_CHECK_ITEM_LEVEL;

   if L_item_level ='Y' then
      LP_parent_item := 'Y';
   end if;

   if LP_parent_item = 'N' then
      if L_status = 'A' then
         LP_pos_update_ind := 'Y';
      else
         LP_pos_update_ind := 'N';
      end if;
   end if;
   ---

   -- loop to retrieve all chosen locations for which to
   -- update attributes
   for cLoc in C_LOCATION LOOP
      L_loc      := cLoc.location;
      L_loc_type := cLoc.loc_type;
      L_finisher_ind := cLoc.finisher_ind;
      L_status_reject_report := 'FALSE'; -- this is to reset the rejection status at the start of each location loop

      -- if updating item status, check if item status rules is broken.
      -- If a rule is broken, do not update item attributes for
      if I_cb1 = 'Y' then
         if NOT CHECK_ITEM_STATUS(O_error_message,
                                  L_status_reject_report,
                                  I_item,
                                  L_loc,
                                  L_loc_type,
                                  I_status
                                  --10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting Begin
                                  , I_call_from_variant
                                  --10-Dec-2007 Ragesh Pillai ragesh.pillai@in.tesco.com - Forward Porting End
                                  ) then
            RETURN FALSE;
         else
            if L_status_reject_report = 'TRUE' then
               O_reject_report := 'TRUE';
            end if;
         end if;
      end if;
      ---
      if I_cb13 = 'Y' then
         --- if the user is attempting to update the primary cost pack, ensure the pack
         --- is in active status at the given location.
         if ITEMLOC_ATTRIB_SQL.ITEM_STATUS(L_error_message,
                                           I_primary_cost_pack,
                                           L_loc,
                                           L_pack_loc_status)= FALSE then
            return FALSE;
         end if;
         ---
         if L_pack_loc_status != 'A' then
            if ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS(O_error_message,
                                                      I_item,
                                                      L_loc_type,
                                                      L_loc,
                                                      'L',
                                                      'INACTIVE_SIMPLE_PACK_LOC',
                                                      LP_user_id,
                                                      NULL,
                                                      NULL,
                                                      NULL) = FALSE then
               RETURN FALSE;
            end if;
            L_status_reject_report := 'TRUE';
            O_reject_report := 'TRUE';
         end if;
      end if;
      ---
      if L_status_reject_report = 'FALSE' then
         ---
         if I_cb14 = 'Y' and
            L_loc_type = 'W' and
            L_finisher_ind = 'N' then

            L_inbound_handling_days := I_inbound_handling_days;
         else
            L_inbound_handling_days := NULL;

         end if;
         ---
         if NOT PROCESS_ITEM_ATTRIBUTES(O_error_message,
                                        I_item,
                                        L_loc,
                                        L_loc_type,
                                        I_cb1, I_status,
                                        I_cb2, I_taxable_ind,
                                        L_update_ind, I_supplier,
                                        I_primary_country,
                                        I_cb4, I_daily_waste_pct,
                                        I_cb5, I_meas_of_each,
                                        I_cb6, I_meas_of_price,
                                        I_cb7, I_uom_of_price,
                                        I_cb8, I_primary_variant,
                                        L_update_ind, I_ti,
                                        L_update_ind, I_hi,
                                        I_cb11, I_loc_item_desc,
                                        I_cb12, I_loc_short_desc,
                                        L_update_ind, I_primary_cost_pack,
                                        I_cb14, I_source_method,
                                                I_source_wh,
                                        I_cb15, I_store_ord_mult,
                                        I_cb16, L_inbound_handling_days) then

            RETURN FALSE;
         end if;
      end if;
   END LOOP;
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,L_program,null);
      RETURN FALSE;
END ITEM;
--------------------------------------------------------------------
FUNCTION PRIMARY_COST_PACK_LOC (O_error_message        IN OUT VARCHAR2,
                                O_valid_simple_pack    IN OUT BOOLEAN,
                                I_primary_cost_pack    IN     ITEM_LOC.PRIMARY_COST_PACK%TYPE)
   RETURN BOOLEAN IS

   L_location            MC_LOCATION_TEMP.LOCATION%TYPE;
   L_exists              BOOLEAN;
   L_program             VARCHAR2(64)                       := 'ITEMLIST_LOC_MC_SQL.PRIMARY_COST_PACK_LOC';
   L_error_message       VARCHAR2(255)                      := NULL;

   cursor C_GET_LOCATIONS is
      select location
        from mc_location_temp;

BEGIN
   if I_primary_cost_pack is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_primary_cost_pack',
                                            'NULL',
                                            'NOT NULL');
      RETURN FALSE;
   end if;

   for c3 in C_GET_LOCATIONS LOOP
      L_location := c3.location;
      --  Loop through all records retrieved from the cursor.
      --  Call below function to populate local exist variable.
      --  If the exist variable equals false, show error message
      --  indicating that no primary cost pack info exists for
      --  the location.

      if ITEMLOC_ATTRIB_SQL.ITEM_LOC_EXIST(L_error_message,
                                           I_primary_cost_pack,
                                           L_location,
                                           L_exists) = FALSE then
         RETURN FALSE;
      end if;

      if L_exists = FALSE then
         O_error_message := SQL_LIB.CREATE_MSG('NO_PRIM_COST_PACK',
                                               I_primary_cost_pack,
                                               to_char(L_location),
                                               NULL);
         O_valid_simple_pack := FALSE;

         RETURN TRUE;
      end if;

   END LOOP;

   O_valid_simple_pack := TRUE;
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      RETURN FALSE;

END PRIMARY_COST_PACK_LOC;
---------------------------------------------------------------------------------------------
FUNCTION CHECK_PRIMARY_COST_PACK_LOC (O_error_message         IN OUT VARCHAR2,
                                      O_exists                IN OUT VARCHAR2,
                                      I_primary_cost_pack     IN     ITEM_LOC.PRIMARY_COST_PACK%TYPE)
   RETURN BOOLEAN IS

   L_program             VARCHAR2(64)                       := 'ITEMLIST_LOC_MC_SQL.CHECK_PRIMARY_COST_PACK_LOC';
   L_error_message       VARCHAR2(255)                      := NULL;
   L_exists              VARCHAR2(1)                        := 'N';

   cursor C_CHECK_COST_PACK_EXIST is
      select 'x'
        from item_loc il,
             mc_location_temp mlt
       where il.loc = mlt.location
         and il.primary_cost_pack = I_primary_cost_pack;

BEGIN
   open C_CHECK_COST_PACK_EXIST;
   fetch C_CHECK_COST_PACK_EXIST into L_exists;
   if C_CHECK_COST_PACK_EXIST%NOTFOUND then
      O_exists := 'N';
   else
      O_exists := 'Y';
   end if;
   close C_CHECK_COST_PACK_EXIST;
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      RETURN FALSE;

END CHECK_PRIMARY_COST_PACK_LOC;
---------------------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_INTERNAL_FINISHER V_STORE V_WH
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION INSERT_MC_LOC_TEMP (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_group_value     IN     VARCHAR2,
                             I_group_type      IN     CODE_DETAIL.CODE%TYPE,
                             I_zone_group_id   IN     PRICE_ZONE_GROUP.ZONE_GROUP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program             VARCHAR2(64) := 'ITEMLIST_LOC_MC_SQL.INSERT_MC_LOC_TEMP';
   L_multichannel_ind    SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;

BEGIN
   if I_group_type = 'AL' then
      insert into mc_location_temp
      select v_store.store,
             v_store.store_name,
             'S'
        from v_store
       where not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store)
   UNION ALL
      select v_wh.wh,
             v_wh.wh_name,
             'W'
        from v_wh
       where v_wh.stockholding_ind = 'Y'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_wh.wh)
   UNION ALL
      select wh.wh,
             wh.wh_name,
             'W'
        from wh,
             v_internal_finisher vf
       where vf.finisher_id = wh.wh
         and wh.finisher_ind = 'Y'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = wh.wh);


   -- add the store to the location list if it doesn't already
   -- exist in the list
   elsif I_group_type = 'S' then

      insert into mc_location_temp
      select store,
             store_name,
             'S'
        from store
       where store = I_group_value
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = I_group_value);


   -- add each store in the class to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'C' then

      insert into mc_location_temp
      select store,
             store_name,
             'S'
        from v_store
       where store_class = I_group_value
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);

   -- add each store in the district to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'D' then

      insert into mc_location_temp
      select store,
             store_name,
             'S'
        from v_store
       where district = I_group_value
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);

   -- add each store in the region to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'R' then

      insert into mc_location_temp
      select v_store.store,
             v_store.store_name,
             'S'
        from v_store
       where v_store.region = I_group_value
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);

   elsif I_group_type = 'A' then

      insert into mc_location_temp
      select v_store.store,
             v_store.store_name,
             'S'
        from v_store
       where area = I_group_value
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);




   -- add each store in the transfer zone to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'T' then

      insert into mc_location_temp
      select v_store.store,
             v_store.store_name,
             'S'
        from v_store
       where transfer_zone = I_group_value
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);


   -- add each store with the location trait to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'L' then

      insert into mc_location_temp
      select v_store.store,
             v_store.store_name,
             'S'
        from v_store,
             loc_traits_matrix
       where loc_traits_matrix.store     = v_store.store
         and loc_traits_matrix.loc_trait = I_group_value
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);


   -- add each store in the price zone to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'Z' then

      insert into mc_location_temp
      select distinct
             v_store.store,
             v_store.store_name,
             'S'
        from v_store,
             price_zone_group_store
       where price_zone_group_store.zone_id       = I_group_value
         and price_zone_group_store.zone_group_id = I_zone_group_id
         and price_zone_group_store.store         = v_store.store
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);

   elsif I_group_type = 'AS' then
      insert into mc_location_temp
      select store,
             store_name,
             'S'
        from v_store
       where not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);

   elsif I_group_type = 'LLS' then
      insert into mc_location_temp
      select store,
             store_name,
             'S'
        from v_store, loc_list_detail
       where loc_list_detail.loc_list = I_group_value
         and loc_list_detail.loc_type = 'S'
         and loc_list_detail.location = v_store.store
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_store.store);

   elsif I_group_type = 'DW' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from wh,
             v_store vs
       where wh.wh  = I_group_value
         and wh.wh  = vs.default_wh
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = I_group_value);

   elsif I_group_type = 'PW' then
      insert into mc_location_temp
      select v_wh.wh,
             v_wh.wh_name,
             'W'
        from v_wh
       where v_wh.physical_wh = I_group_value
         and v_wh.stockholding_ind = 'Y'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location in(select wh
                                                              from v_wh
                                                             where physical_wh = I_group_value
                                                               and stockholding_ind = 'Y'));


   elsif I_group_type = 'W' then
      insert into mc_location_temp
      select wh.wh,
             wh.wh_name,
             'W'
        from wh
       where wh.wh = I_group_value
         and wh.stockholding_ind = 'Y'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = I_group_value);

   elsif I_group_type = 'AW' then
      insert into mc_location_temp
      select v_wh.wh,
             v_wh.wh_name,
             'W'
        from v_wh
       where v_wh.stockholding_ind = 'Y'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_wh.wh);
   --- Finishers
      elsif I_group_type = 'I' then
         insert into mc_location_temp
         select wh.wh,
                wh.wh_name,
                'W'
           from wh
          where wh.wh = I_group_value
            and wh.stockholding_ind = 'Y'
            and wh.finisher_ind = 'Y'
            and not exists(select 'x'
                             from mc_location_temp
                            where mc_location_temp.location = I_group_value);

      elsif I_group_type = 'AI' then
         insert into mc_location_temp
         select wh.wh,
                wh.wh_name,
                'W'
           from wh,
      v_internal_finisher vf
          where vf.finisher_id = wh.wh
            and wh.finisher_ind = 'Y'
            and not exists(select 'x'
                             from mc_location_temp
                            where mc_location_temp.location = wh.wh);

   ---
   elsif I_group_type = 'LLW' then
      select multichannel_ind
        into L_multichannel_ind
        from system_options;

      if L_multichannel_ind  = 'N' then
         insert into mc_location_temp
         select v_wh.wh,
                v_wh.wh_name,
                'W'
           from v_wh,
                loc_list_detail
          where loc_list_detail.loc_list = I_group_value
            and loc_list_detail.loc_type = 'W'
            and loc_list_detail.location = v_wh.wh
            and not exists(select 'x'
                             from mc_location_temp
                            where mc_location_temp.location = v_wh.wh);
        else --L_multichannel_ind  = 'Y'
           insert into mc_location_temp
           select v_wh.wh,
                  v_wh.wh_name,
                  'W'
             from v_wh,
                  loc_list_detail l
            where l.loc_list = I_group_value
              and v_wh.stockholding_ind = 'Y'
           and (l.location = v_wh.wh or  l.location = v_wh.physical_wh)
           and not exists(select 'x'
                            from mc_location_temp
                           where mc_location_temp.location = v_wh.wh
                              or mc_location_temp.location in (select wh2.wh
                                                                 from v_wh wh2
                                                                where l.location = wh2.physical_wh));
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
      RETURN FALSE;

END INSERT_MC_LOC_TEMP;
---------------------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_INTERNAL_FINISHER V_STORE V_WH
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION INSERT_MC_LOC_TEMP (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_group_value     IN     VARCHAR2,
                             I_group_type      IN     CODE_DETAIL.CODE%TYPE,
                             I_zone_group_id   IN     PRICE_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                             I_item            IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program             VARCHAR2(64) := 'ITEMLIST_LOC_MC_SQL.INSERT_MC_LOC_TEMP';
   L_multichannel_ind    SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;

BEGIN
   if I_group_type = 'AL' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             item_loc i
       where i.item = I_item
         and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store)
   UNION ALL
      select v_wh.wh,
             v_wh.wh_name,
             'W'
        from v_wh,
             item_loc i
       where v_wh.stockholding_ind = 'Y'
         and i.item = I_item
         and v_wh.wh = i.loc
         and i.loc_type = 'W'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = v_wh.wh)
   UNION ALL
      select wh.wh,
             wh.wh_name,
             'W'
        from wh,
             v_internal_finisher vf,
             item_loc i
       where vf.finisher_id = wh.wh
         and i.item = I_item
         and wh.wh = i.loc
         and i.loc_type = 'W'
         and wh.finisher_ind = 'Y'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = wh.wh);


   -- add the store to the location list if it doesn't already
   -- exist in the list
   elsif I_group_type = 'S' then

      insert into mc_location_temp
      select store,
             store_name,
             'S'
        from store
       where store = I_group_value
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = I_group_value);


   -- add each store in the class to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'C' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             item_loc i
       where store_class = I_group_value
         and i.item = I_item
         and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store);

   -- add each store in the district to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'D' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             item_loc i
       where vs.district = I_group_value
         and i.item = I_item
         and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store);

   -- add each store in the region to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'R' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             item_loc i
       where vs.region = I_group_value
         and i.item = I_item
         and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store);

   elsif I_group_type = 'A' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             item_loc i
       where vs.area = I_group_value
         and i.item = I_item
         and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store);




   -- add each store in the transfer zone to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'T' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             item_loc i
       where vs.transfer_zone = I_group_value
         and i.item = I_item
         and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store);


   -- add each store with the location trait to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'L' then

      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             item_loc i,
             loc_traits_matrix ltm
       where ltm.store     = vs.store
         and ltm.loc_trait = I_group_value
         and i.item = I_item
    and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store);


   -- add each store in the price zone to the location list
   -- if it doesn't already exist in the list
   elsif I_group_type = 'Z' then
      insert into mc_location_temp
      select distinct
             vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             price_zone_group_store pzgs,
             item_loc i
       where pzgs.zone_id       = I_group_value
         and pzgs.zone_group_id = I_zone_group_id
         and pzgs.store         = vs.store
         and i.item             = I_item
         and vs.store           = i.loc
         and i.loc_type         = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store);

   elsif I_group_type = 'AS' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             item_loc i
       where i.item = I_item
         and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp mlt
                         where mlt.location = vs.store);

   elsif I_group_type = 'LLS' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from v_store vs,
             loc_list_detail lld,
             item_loc i
       where lld.loc_list = I_group_value
         and lld.loc_type = 'S'
         and lld.location = vs.store
         and i.item = I_item
         and vs.store = i.loc
         and i.loc_type = 'S'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = vs.store);

   elsif I_group_type = 'DW' then
      insert into mc_location_temp
      select vs.store,
             vs.store_name,
             'S'
        from wh,
             v_store vs,
             item_loc i
       where wh.wh  = I_group_value
         and wh.wh  = vs.default_wh
         and i.item = I_item
         and i.loc_type = 'S'
         and i.loc = vs.store
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = I_group_value);

   elsif I_group_type = 'PW' then
      insert into mc_location_temp
      select v_wh.wh,
             v_wh.wh_name,
             'W'
        from v_wh,
             item_loc i
       where v_wh.physical_wh = I_group_value
         and v_wh.stockholding_ind = 'Y'
         and i.item = I_item
         and i.loc = v_wh.wh
         and i.loc_type = 'W'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location in(select wh
                                                              from v_wh
                                                             where physical_wh = I_group_value
                                                               and stockholding_ind = 'Y'));


   elsif I_group_type = 'W' then
      insert into mc_location_temp
      select wh.wh,
             wh.wh_name,
             'W'
        from wh,
             item_loc i
       where wh.wh = I_group_value
         and wh.stockholding_ind = 'Y'
         and i.item = I_item
         and i.loc = wh.wh
         and i.loc_type = 'W'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = I_group_value);

   elsif I_group_type = 'AW' then
      insert into mc_location_temp
      select v_wh.wh,
             v_wh.wh_name,
             'W'
        from v_wh,
             item_loc i
       where v_wh.stockholding_ind = 'Y'
         and i.item                = I_item
         and i.loc                 = v_wh.wh
         and i.loc_type            = 'W'
         and not exists(select 'x'
                          from mc_location_temp
                         where mc_location_temp.location = v_wh.wh);
   --- Finishers
      elsif I_group_type = 'I' then
         insert into mc_location_temp
         select wh.wh,
                wh.wh_name,
                'W'
           from wh,
                item_loc i
          where wh.wh               = I_group_value
            and wh.stockholding_ind = 'Y'
            and wh.finisher_ind     = 'Y'
            and i.item              = I_item
            and i.loc               = wh.wh
            and i.loc_type          = 'W'
            and not exists(select 'x'
                             from mc_location_temp
                            where mc_location_temp.location = I_group_value);

      elsif I_group_type = 'AI' then
         insert into mc_location_temp
         select wh.wh,
                wh.wh_name,
                'W'
           from wh,
      v_internal_finisher vf,
      item_loc i
          where vf.finisher_id  = wh.wh
            and wh.finisher_ind = 'Y'
            and i.item          = I_item
            and i.loc           = wh.wh
            and i.loc_type      = 'W'
            and not exists(select 'x'
                             from mc_location_temp
                            where mc_location_temp.location = wh.wh);

   ---
   elsif I_group_type = 'LLW' then
      select multichannel_ind
        into L_multichannel_ind
        from system_options;

      if L_multichannel_ind  = 'N' then
         insert into mc_location_temp
         select v_wh.wh,
                v_wh.wh_name,
                'W'
           from v_wh,
                loc_list_detail lld,
                item_loc i
          where lld.loc_list = I_group_value
            and lld.loc_type = 'W'
            and lld.location = v_wh.wh
            and i.item = I_item
            and i.loc = v_wh.wh
            and i.loc_type = 'W'
            and not exists(select 'x'
                             from mc_location_temp
                            where mc_location_temp.location = v_wh.wh);
        else --L_multichannel_ind  = 'Y'
           insert into mc_location_temp
           select v_wh.wh,
                  v_wh.wh_name,
                  'W'
             from v_wh,
                  loc_list_detail l,
                  item_loc i
            where l.loc_list = I_group_value
              and v_wh.stockholding_ind = 'Y'
              and i.item = I_item
              and i.loc = v_wh.wh
              and i.loc_type = 'W'
           and (l.location = v_wh.wh or  l.location = v_wh.physical_wh)
           and not exists(select 'x'
                            from mc_location_temp
                           where mc_location_temp.location = v_wh.wh
                              or mc_location_temp.location in (select wh2.wh
                                                                 from v_wh wh2
                                                                where l.location = wh2.physical_wh));
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
      RETURN FALSE;

END INSERT_MC_LOC_TEMP;
 --30-Jul-2007 WiproEnabler/Ramasamy - MOD 365b   Begin
   ---------------------------------------------------------------------------------------------------------------
   --TSL_BASE_ITEM   Called from the Mass Item Location form if updates are being done to a Level 2 Base Item.
   -- Loop through Variant Items in the Base Item and does all the item/location level checking to determine if the
   -- item's attributes can be updated with the values the user has specified. Once all the appropriate checks have
   -- been performed and passed, it updates the database fields which the user has specified.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_BASE_ITEM(O_error_message         IN OUT VARCHAR2,
                          O_reject_report         IN OUT VARCHAR2,
                          I_item                  IN OUT ITEM_MASTER.ITEM%TYPE,
                          I_cb1                   IN     VARCHAR2,
                          I_status                IN     ITEM_LOC.STATUS%TYPE,
                          I_cb2                   IN     VARCHAR2,
                          I_taxable_ind           IN     ITEM_LOC.TAXABLE_IND%TYPE,
                          I_cb3                   IN     VARCHAR2,
                          I_supplier              IN     SUPS.SUPPLIER%TYPE,
                          I_primary_country       IN     ITEM_LOC.PRIMARY_CNTRY%TYPE,
                          I_cb4                   IN     VARCHAR2,
                          I_daily_waste_pct       IN     ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                          I_cb5                   IN     VARCHAR2,
                          I_meas_of_each          IN     ITEM_LOC.MEAS_OF_EACH%TYPE,
                          I_cb6                   IN     VARCHAR2,
                          I_meas_of_price         IN     ITEM_LOC.MEAS_OF_PRICE%TYPE,
                          I_cb7                   IN     VARCHAR2,
                          I_uom_of_price          IN     ITEM_LOC.UOM_OF_PRICE%TYPE,
                          I_cb8                   IN     VARCHAR2,
                          I_primary_variant       IN     ITEM_LOC.PRIMARY_VARIANT%TYPE,
                          I_cb9                   IN     VARCHAR2,
                          I_ti                    IN     ITEM_LOC.TI%TYPE,
                          I_cb10                  IN     VARCHAR2,
                          I_hi                    IN     ITEM_LOC.HI%TYPE,
                          I_cb11                  IN     VARCHAR2,
                          I_loc_item_desc         IN     ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                          I_cb12                  IN     VARCHAR2,
                          I_loc_short_desc        IN     ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                          I_cb13                  IN     VARCHAR2,
                          I_primary_cost_pack     IN     ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                          I_cb14                  IN     VARCHAR2,
                          I_source_method         IN     ITEM_LOC.SOURCE_METHOD%TYPE,
                          I_source_wh             IN     ITEM_LOC.SOURCE_WH%TYPE,
                          I_cb15                  IN     VARCHAR2,
                          I_store_ord_mult        IN     ITEM_LOC.STORE_ORD_MULT%TYPE,
                          I_cb16                  IN     VARCHAR2,
                          I_inbound_handling_days IN     ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE,
                          I_user_id               IN     USER_USERS.USERNAME%TYPE)

    return BOOLEAN is

      L_program            VARCHAR2(64) := 'ITEMLIST_LOC_MC_SQL.TSL_BASE_ITEM';
      L_item               ITEM_MASTER.ITEM%TYPE;
      L_item_reject_report VARCHAR2(65);

      --This cursor will return all the variant Items associated to a given Base Item
      cursor C_EXPLODE_ITEM is
         select im.item,
                im.status,
                im.tran_level,
                im.item_level
           from item_master im
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item;
   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --
      LP_user_id      := I_user_id;
      O_reject_report := 'FALSE';
      --
      -- loop to retrieve each item in the grandparent
      --Opening the cursor C_EXPLODE_ITEM
      SQL_LIB.SET_MARK('OPEN',
                       'C_EXPLODE_ITEM',
                       'ITEM_MASTER',
                       'ITEM: ' || I_item);
      FOR C_rec in C_EXPLODE_ITEM
      LOOP
         --
         L_item := C_rec.item;
         ---
         if (C_rec.item_level = C_rec.tran_level)
            and C_rec.status = 'A' then
            LP_pos_update_ind := 'Y';
         else
            LP_pos_update_ind := 'N';
         end if;
         ---
         -- Executing package fucntion
         if NOT ITEMLIST_LOC_MC_SQL.ITEM (O_error_message           =>O_error_message,
                                          O_reject_report           =>L_item_reject_report,
                                          I_item                    =>L_item,
                                          I_cb1                     =>I_cb1,
                                          I_status                  =>I_status,
                                          I_cb2                     =>I_cb2,
                                          I_taxable_ind             =>I_taxable_ind,
                                          I_cb3                     =>I_cb3,
                                          I_supplier                =>I_supplier,
                                          I_primary_country         =>I_primary_country,
                                          I_cb4                     =>'N',
                                          I_daily_waste_pct         =>NULL,
                                          I_cb5                     =>I_cb5,
                                          I_meas_of_each            =>I_meas_of_each,
                                          I_cb6                     =>I_cb6,
                                          I_meas_of_price           =>I_meas_of_price,
                                          I_cb7                     =>I_cb7,
                                          I_uom_of_price            =>I_uom_of_price,
                                          I_cb8                     =>'N',
                                          I_primary_variant         =>NULL,
                                          I_cb9                     =>I_cb9,
                                          I_ti                      =>I_ti,
                                          I_cb10                    =>I_cb10,
                                          I_hi                      =>I_hi,
                                          I_cb11                    =>'N',
                                          I_loc_item_desc           =>NULL,
                                          I_cb12                    =>'N',
                                          I_loc_short_desc          =>NULL,
                                          I_cb13                    =>'N',
                                          I_primary_cost_pack       =>NULL,
                                          I_cb14                    =>I_cb14,
                                          I_source_method           =>I_source_method,
                                          I_source_wh               =>I_source_wh,
                                          I_cb15                    =>I_cb15,
                                          I_store_ord_mult          =>I_store_ord_mult,
                                          I_cb16                    =>I_cb16,
                                          I_inbound_handling_days   =>I_inbound_handling_days,
                                          I_user_id                 =>LP_user_id) then
            return FALSE;
         end if;
         if L_item_reject_report = 'TRUE' then
            O_reject_report := 'TRUE';
         end if;
      END LOOP;
      ---
      return TRUE;
      ---
   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_BASE_ITEM;
   --30-Jul-2007 WiproEnabler/Ramasamy - MOD 365b   End
---------------------------------------------------------------------------------------------
END ITEMLIST_LOC_MC_SQL;
/

