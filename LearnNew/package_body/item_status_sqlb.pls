CREATE OR REPLACE PACKAGE BODY ITEM_STATUS_SQL AS

-------------------------------------------------------------------------------
--- Function Name CHECK_ITEM
--- Purpose       This function will make certain that items are not
---               currently on active order or that there are
---               no pending price or cost changes for these items before
---               allowing a status change.
--------------------------------------------------------------------------------


FUNCTION CHECK_ITEM (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     O_exists          IN OUT VARCHAR2,
                     I_item            IN     ITEM_MASTER.ITEM%TYPE,
                     I_store           IN     ITEM_LOC.LOC%TYPE,
                     I_wh              IN     ITEM_LOC.LOC%TYPE)
   RETURN BOOLEAN IS

   L_program                   VARCHAR2(30)                   := 'ITEM_STATUS_SQL.CHECK_ITEM';
   L_location                  ITEM_LOC.LOC%TYPE              := NULL;
   L_item_level                ITEM_MASTER.ITEM_LEVEL%TYPE    := NULL;
   L_tran_level                ITEM_MASTER.TRAN_LEVEL%TYPE    := NULL;
   ---

   cursor C_ITEM_ORDERS_EXIST is
      select 'Y'
        from ordloc ol, ordhead oh
         where oh.order_no = ol.order_no
           and ol.location = L_location
           and ol.item = I_item
           and oh.status in ('W', 'S', 'A');
   ---
   cursor C_PARENT_ORDERS_EXIST is
      select 'Y'
        from ordloc ol, ordhead oh
         where oh.order_no = ol.order_no
           and ol.location = L_location
           and exists (select 'x'
                         from item_master im
                        where (im.item_parent = I_item
                           or im.item_grandparent = I_item)
                          and ol.item = im.item)
           and oh.status in ('W', 'S', 'A');


   ---
   cursor C_TRANSFER_ITEM is
      select 'Y'
        from tsfhead,
             tsfdetail
       where tsfhead.status in ('I','A','S','E')
         and tsfhead.to_loc = L_location
         and tsfhead.tsf_no = tsfdetail.tsf_no
         and tsfdetail.item = I_item;
   ---
   cursor C_TRANSFER_PARENT is
      select 'Y'
        from tsfhead th,
             tsfdetail td
       where th.status in ('I','A','S','E')
         and th.to_loc = L_location
         and th.tsf_no = td.tsf_no
         and exists (select 'X'
                      from item_master im
                     where (im.item_parent = I_item
                        or im.item_grandparent = I_item)
                       and im.item = td.item);
   ---
BEGIN
   if not ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                     L_item_level,
                                     L_tran_level,
                                     I_item) then
      return FALSE;
   end if;
   --

   if I_wh = -1 then
      L_location := I_store;
   elsif I_store = -1 then
      L_location := I_wh;
   end if;
   --

   if L_item_level >= L_tran_level then

      SQL_LIB.SET_MARK('OPEN',
                       'C_ITEM_ORDERS_EXIST',
                       'ord_head, ord_loc',
                       NULL);
      open C_ITEM_ORDERS_EXIST;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_ITEM_ORDERS_EXIST',
                       'ordhead, ordloc',
                       'Item '||I_item||', Store '||to_char(I_store));
      fetch C_ITEM_ORDERS_EXIST into O_exists;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_ITEM_ORDERS_EXIST',
                       'ordhead, ordloc',
                       NULL);
      close C_ITEM_ORDERS_EXIST;
      ---
      if O_exists = 'Y' then
      ---
         O_error_message := SQL_LIB.CREATE_MSG('ITEM_LOC_ORD_EXIST',
                                               I_item,
                                               to_char(L_location),
                                               NULL);
         return TRUE;
      end if;


      ---
      -- check for individual transfer to a store.
      SQL_LIB.SET_MARK('OPEN',
                       'C_TRANSFER_ITEM',
                       'tsfhead, tsfdetail',
                       NULL);
      open C_TRANSFER_ITEM;
      SQL_LIB.SET_MARK('FETCH',
                       'C_TRANSFER_ITEM',
                       'tsfhead, tsfdetail',
                       NULL);
      fetch C_TRANSFER_ITEM into O_exists;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_TRANSFER_ITEM',
                       'tsfhead, tsfdetail',
                        NULL);
      close C_TRANSFER_ITEM;
      if O_exists = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('ITEM_LOC_TSF_EXIST',
                                               I_item,
                                               to_char(L_location),
                                               NULL);
         return TRUE;
      end if;
   else -- L_item_level < L_tran_level
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_PARENT_ORDERS_EXIST',
                       'ordloc, ordhead, item_master',
                       NULL);
      open C_PARENT_ORDERS_EXIST;
      SQL_LIB.SET_MARK('FETCH',
                       'C_PARENT_ORDERS_EXIST',
                       'ordhead, ordloc, item_master',
                       'Item'||I_item||', Location '||to_char(L_location));
      fetch C_PARENT_ORDERS_EXIST into O_exists;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_PARENT_ORDERS_EXIST',
                       'ordhead, ordloc, item_master',
                       NULL);
      close C_PARENT_ORDERS_EXIST;
      ---
      if O_exists = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('ITEM_LOC_ORD_EXIST',
                                               I_item,
                                               to_char(L_location),
                                               NULL);
         return TRUE;
      end if;


      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_TRANSFER_PARENT',
                       'tsfhead, tsfdetail',
                       NULL);
      open C_TRANSFER_PARENT;
      SQL_LIB.SET_MARK('FETCH',
                       'C_TRANSFER_PARENT',
                       'tsfhead, tsfdetail',
                       NULL);
      fetch C_TRANSFER_PARENT into O_exists;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_TRANSFER_PARENT',
                       'tsfhead, tsfdetail',
                        NULL);
      close C_TRANSFER_PARENT;
      ---
      if O_exists = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('ITEM_LOC_TSF_EXIST',
                                               I_item,
                                               to_char(L_location),
                                               NULL);
         return TRUE;
      end if;
   end if;
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CHECK_ITEM;
--------------------------------------------------------------------------------
FUNCTION UPDATE_ITEM_STATUS (O_error_message   IN OUT VARCHAR2,
                             I_item            IN     ITEM_MASTER.ITEM%TYPE,
                             I_location        IN     ITEM_LOC.LOC%TYPE,
                             I_loc_type        IN     ITEM_LOC.LOC_TYPE%TYPE,
                             I_status          IN     ITEM_LOC.STATUS%TYPE,
                             I_taxable_ind     IN     ITEM_LOC.TAXABLE_IND%TYPE,
                             I_supplier        IN     ITEM_SUPPLIER.SUPPLIER%TYPE,
                             I_chg_status      IN     VARCHAR2,
                             I_chg_tax         IN     VARCHAR2,
                             I_chg_supplier    IN     VARCHAR2)
                             RETURN BOOLEAN IS

   L_program             VARCHAR2(50)                    := 'ITEM_STATUS_SQL.UPDATE_ITEM_STATUS';
   L_item                ITEM_LOC.ITEM%TYPE              := NULL;
   L_vdate               DATE                            := GET_VDATE;
   L_table_name          VARCHAR2(30)                    := NULL;
   L_update_status       VARCHAR2(1)                     := NULL;
   L_update_tax          VARCHAR2(1)                     := NULL;
   L_update_supplier     VARCHAR2(1)                     := NULL;
   L_exist               BOOLEAN                         := NULL;
   Record_Locked         EXCEPTION;
   PRAGMA                EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_ITEM_LOC is
      select l.item,
             l.status,
             l.taxable_ind,
             l.primary_supp,
             m.item_level,
             m.tran_level
        from ITEM_LOC l, ITEM_MASTER m
       where (l.item = I_item
              or l.item_parent = I_item
              or l.item_grandparent = I_item)
         and l.loc = I_location
         and l.loc_type = I_loc_type
         and l.item = m.item
         and m.item_level <= m.tran_level
         for update of l.item nowait;

BEGIN
   L_table_name := 'ITEM_LOC';

   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_LOC',
                    'item_loc',
                     NULL);

   FOR C_item_loc_rec in C_ITEM_LOC LOOP

      L_item := C_item_loc_rec.item;
      L_update_status   := 'N';
      L_update_tax      := 'N';
      L_update_supplier := 'N';

      if (I_chg_status = 'Y'
          and C_item_loc_rec.status != I_status) then
         L_update_status := 'Y';
         if (I_loc_type = 'S'
             and C_item_loc_rec.item_level = C_item_loc_rec.tran_level) then
            if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                              25,
                                              L_item,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_location,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              (L_vdate + 1),
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
      ---
      if (I_chg_tax = 'Y'
          and I_taxable_ind != C_item_loc_rec.taxable_ind
          and I_loc_type = 'S') then
         L_update_tax := 'Y';
         if (C_item_loc_rec.item_level = C_item_loc_rec.tran_level) then
            if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                              26,
                                              L_item,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              I_location,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              (L_vdate + 1),
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
      ---
      if (I_chg_supplier = 'Y'
          and I_supplier != C_item_loc_rec.primary_supp) then
         if SUPP_ITEM_SQL.EXIST(O_error_message,
                                L_exist,
                                L_item,
                                I_supplier) = FALSE then
            return FALSE;
         end if;
         ---
         if L_exist = TRUE then
            L_update_supplier := 'Y';
         end if;
      end if;
      ---
      if L_update_status = 'Y'
         or L_update_tax = 'Y'
         or L_update_supplier = 'Y' then
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'item_loc',
                          'Item: '|| I_item ||
                          ', Location: '||to_char(I_location));
         update item_loc
            set status                = decode(L_update_status,
                                               'Y',
                                               I_status,
                                               status),
                status_update_date    = decode(L_update_status,
                                               'Y',
                                               L_vdate,
                                               status_update_date),
                taxable_ind           = decode(L_update_tax,
                                               'Y',
                                               I_taxable_ind,
                                               taxable_ind),
                primary_supp          = decode(L_update_supplier,
                                               'Y',
                                               I_supplier,
                                               primary_supp),
                last_update_datetime  = sysdate,
                last_update_id        = user
         where current of C_item_loc;
      end if;
      ---
   END LOOP;
   ---
   RETURN TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',L_table_name,
                                            I_item,
                                            to_char(I_location));
      return FALSE;
   when DUP_VAL_ON_INDEX then
      NULL;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END UPDATE_ITEM_STATUS;
--------------------------------------------------------------------------------

END ITEM_STATUS_SQL;
/

