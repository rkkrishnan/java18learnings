CREATE OR REPLACE PACKAGE BODY INV_REQUEST_SQL AS

TYPE so_store_TBL         is table of STORE_ORDERS.STORE%TYPE      INDEX BY BINARY_INTEGER;
TYPE so_item_TBL          is table of STORE_ORDERS.ITEM%TYPE       INDEX BY BINARY_INTEGER;
TYPE so_need_date_TBL     is table of STORE_ORDERS.NEED_DATE%TYPE  INDEX BY BINARY_INTEGER;
TYPE so_need_qty_TBL      is table of STORE_ORDERS.NEED_QTY%TYPE   INDEX BY BINARY_INTEGER;
TYPE rowid_TBL            is table of ROWID                        INDEX BY BINARY_INTEGER;

P_so_ins_size             NUMBER := 0;
P_so_ins_item             so_item_TBL;
P_so_ins_store            so_store_TBL;
P_so_ins_need_date        so_need_date_TBL;
P_so_ins_need_qty         so_need_qty_TBL;

P_so_upd_size             NUMBER := 0;
P_so_upd_need_qty         so_need_qty_TBL;
P_so_upd_rowid            rowid_TBL;

LP_item_tbl               ITEM_TBL;
LP_store                  STORE_ORDERS.STORE%TYPE;

-------------------------------------------------------------------------
FUNCTION VERIFY_REPL_INFO (O_error_message  IN OUT  VARCHAR2,
                           O_ad_hoc_ind     IN OUT  VARCHAR2,
                           I_store          IN      STORE_ORDERS.STORE%TYPE,
                           I_request_type   IN      VARCHAR2,
                           I_item           IN      STORE_ORDERS.ITEM%TYPE,
                           I_need_date      IN      STORE_ORDERS.NEED_DATE%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------
FUNCTION CONVERT_NEED_QTY (O_error_message  IN OUT  VARCHAR2,
                           IO_need_qty      IN OUT  STORE_ORDERS.NEED_QTY%TYPE,
                           I_store          IN      STORE_ORDERS.STORE%TYPE,
                           I_item           IN      STORE_ORDERS.ITEM%TYPE,
                           I_uop            IN      UOM_CLASS.UOM%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------
FUNCTION VERIFY_ON_STORE (O_error_message  IN OUT  VARCHAR2,
                          I_store          IN      STORE_ORDERS.STORE%TYPE,
                          I_item           IN      STORE_ORDERS.ITEM%TYPE,
                          I_need_date      IN      STORE_ORDERS.NEED_DATE%TYPE,
                          I_need_qty       IN      STORE_ORDERS.NEED_QTY%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------
FUNCTION PREPARE_INSERT(O_error_message  IN OUT  VARCHAR2,
                        I_store          IN      STORE_ORDERS.STORE%TYPE,
                        I_item           IN      STORE_ORDERS.ITEM%TYPE,
                        I_need_date      IN      STORE_ORDERS.NEED_DATE%TYPE,
                        I_need_qty       IN      STORE_ORDERS.NEED_QTY%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------
FUNCTION PREPARE_UPDATE(O_error_message  IN OUT  VARCHAR2,
                        I_need_qty       IN      STORE_ORDERS.NEED_QTY%TYPE,
                        I_rowid          IN      ROWID)
RETURN BOOLEAN;
-------------------------------------------------------------------------
FUNCTION PREPARE_AD_HOC(O_error_message  IN OUT  VARCHAR2,
                        I_store          IN      STORE_ORDERS.STORE%TYPE,
                        I_item           IN      STORE_ORDERS.ITEM%TYPE,
                        I_need_date      IN      STORE_ORDERS.NEED_DATE%TYPE,
                        I_need_qty       IN      STORE_ORDERS.NEED_QTY%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------

/* Function and Procedure Bodies */
-------------------------------------------------------------------------
FUNCTION PROCESS (O_error_message  IN OUT  VARCHAR2,
                  I_store          IN      STORE_ORDERS.STORE%TYPE,
                  I_request_type   IN      VARCHAR2,
                  I_invreqitem_rec IN      RIB_INVREQITEM_REC)
RETURN BOOLEAN IS

   L_module       VARCHAR2(64)                := 'INV_REQUEST_SQL.PROCESS';
   L_ad_hoc_ind   VARCHAR2(1);
   L_item         STORE_ORDERS.ITEM%TYPE      := I_invreqitem_rec.item;
   L_uop          UOM_CLASS.UOM%TYPE          := I_invreqitem_rec.uop;
   L_need_date    STORE_ORDERS.NEED_DATE%TYPE := I_invreqitem_rec.need_date;
   L_need_qty     STORE_ORDERS.NEED_QTY%TYPE  := I_invreqitem_rec.qty_rqst;

   INVALID_ERROR      EXCEPTION;


BEGIN

   -- Check for required values. if the inputs at the item level is null,
   -- then keep processing the next item.
   if L_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM_IN_FUNC','L_item',
                                            'NULL',L_module);
      raise INVALID_ERROR;
   elsif L_need_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM_IN_FUNC','L_need_qty',
                                            'NULL',L_module);
      raise INVALID_ERROR;
   elsif L_uop is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM_IN_FUNC','L_uop',
                                            'NULL',L_module);
      raise INVALID_ERROR;
   elsif L_need_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM_IN_FUNC','L_need_date',
                                            'NULL',L_module);
      raise INVALID_ERROR;
   elsif L_uop not in ('EA', 'CA', 'PA') then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG',L_module,
                                            'L_uop',L_uop);
      raise INVALID_ERROR;
   end if;

   LP_store := I_store;

   if VERIFY_REPL_INFO (O_error_message,
                        L_ad_hoc_ind,
                        I_store,
                        I_request_type,
                        L_item,
                        L_need_date) = FALSE then
      raise INVALID_ERROR;
   end if;

   if L_uop != 'EA' then
      if CONVERT_NEED_QTY (O_error_message,
                           L_need_qty,
                           I_store,
                           L_item,
                           L_uop) = FALSE then
         raise INVALID_ERROR;
      end if;
   end if;

   if L_ad_hoc_ind = 'Y' then
      if PREPARE_AD_HOC(O_error_message,
                        I_store,
                        L_item,
                        L_need_date,
                        L_need_qty) = FALSE then
         raise INVALID_ERROR;
      end if;
   else
      if VERIFY_ON_STORE (O_error_message,
                          I_store,
                          L_item,
                          L_need_date,
                          L_need_qty) = FALSE then
         raise INVALID_ERROR;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when INVALID_ERROR then
      -- add item onto the error tbl and stop processing the item
      if RMSSUB_INVREQ_ERROR.ADD_ERROR(O_error_message,
                                       O_error_message,
                                       I_invreqitem_rec) = FALSE then
         return FALSE;
      end if;
      --- no need for further validation on this item
      return TRUE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END PROCESS;
----------------------------------------------------------------------------------------
FUNCTION VERIFY_REPL_INFO (O_error_message  IN OUT  VARCHAR2,
                           O_ad_hoc_ind     IN OUT  VARCHAR2,
                           I_store          IN      STORE_ORDERS.STORE%TYPE,
                           I_request_type   IN      VARCHAR2,
                           I_item           IN      STORE_ORDERS.ITEM%TYPE,
                           I_need_date      IN      STORE_ORDERS.NEED_DATE%TYPE)
RETURN BOOLEAN IS

   L_module VARCHAR2(64) := 'INV_REQUEST_SQL.VERIFY_REPL_INFO';

   L_reject_store_ord_ind  REPL_ITEM_LOC.REJECT_STORE_ORD_IND%TYPE := NULL;
   L_next_delivery_date    REPL_ITEM_LOC.NEXT_DELIVERY_DATE%TYPE := NULL;
   L_next_review_date      REPL_ITEM_LOC.NEXT_REVIEW_DATE%TYPE := NULL;
   L_repl_method           REPL_ITEM_LOC.REPL_METHOD%TYPE := NULL;

   cursor C_CHECK_REPL_EXISTS is
      select reject_store_ord_ind,
             next_delivery_date,
             next_review_date,
             repl_method
        from repl_item_loc
       where item        = I_item
         and location    = I_store;

BEGIN
   O_ad_hoc_ind := 'N';

   open C_CHECK_REPL_EXISTS;
   fetch C_CHECK_REPL_EXISTS into L_reject_store_ord_ind,
                                  L_next_delivery_date,
                                  L_next_review_date,
                                  L_repl_method;
   close C_CHECK_REPL_EXISTS;
   ---
   if I_request_type = 'IR' then
      if ((L_repl_method is NULL) or
          (I_need_date < L_next_review_date)) then
         O_ad_hoc_ind := 'Y';
      end if;
   elsif I_request_type = 'SO' OR I_request_type is NULL then
      if nvl(L_repl_method, ' ') != 'SO' then
         O_error_message := SQL_LIB.CREATE_MSG('REPL_SO_ITEM_LOC',I_item,I_store, NULL);
         return FALSE;
      else
         -- If the reject_store_ord_ind is 'Y', and the need date is before the next delivery date,
         -- the need date is invalid.
         if (L_reject_store_ord_ind = 'Y') and (I_need_date < L_next_delivery_date) then
            O_error_message := SQL_LIB.CREATE_MSG('SO_REJECT_DATE',I_store,I_item, NULL);
            return FALSE;
         elsif (I_need_date < L_next_review_date) then
            O_ad_hoc_ind := 'Y';
         end if;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM_EXP','request_type',I_request_type,'IR or SO');
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END VERIFY_REPL_INFO;
----------------------------------------------------------------------------------------
FUNCTION CONVERT_NEED_QTY (O_error_message  IN OUT  VARCHAR2,
                           IO_need_qty      IN OUT  STORE_ORDERS.NEED_QTY%TYPE,
                           I_store          IN      STORE_ORDERS.STORE%TYPE,
                           I_item           IN      STORE_ORDERS.ITEM%TYPE,
                           I_uop            IN      UOM_CLASS.UOM%TYPE)
RETURN BOOLEAN IS

   L_module VARCHAR2(64) := 'INV_REQUEST_SQL.CONVERT_NEED_QTY';

   L_ti                 ITEM_SUPP_COUNTRY.TI%TYPE := NULL;
   L_hi                 ITEM_SUPP_COUNTRY.HI%TYPE := NULL;
   L_supp_pack_size     ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE := NULL;

   cursor C_GET_QTY is
      select sc.ti,
             sc.hi,
             sc.supp_pack_size
        from item_loc il,
             item_supp_country sc
       where il.item          = I_item
         and il.loc           = I_store
         and il.item          = sc.item
         and il.primary_cntry = sc.origin_country_id
         and il.primary_supp  = sc.supplier
         and il.status        = 'A';

BEGIN

   open C_GET_QTY;
   fetch C_GET_QTY into L_ti,
                        L_hi,
                        L_supp_pack_size;
   if C_GET_QTY%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_LOC',I_item,I_store, NULL);
      return FALSE;
   end if;
   close C_GET_QTY;

   if I_uop = 'CA' then
      IO_need_qty := IO_need_qty * L_supp_pack_size;
   else
      IO_need_qty := (IO_need_qty * (L_ti * L_hi * L_supp_pack_size));
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END CONVERT_NEED_QTY;
----------------------------------------------------------------------------------------
FUNCTION PREPARE_AD_HOC(O_error_message  IN OUT  VARCHAR2,
                        I_store          IN      STORE_ORDERS.STORE%TYPE,
                        I_item           IN      STORE_ORDERS.ITEM%TYPE,
                        I_need_date      IN      STORE_ORDERS.NEED_DATE%TYPE,
                        I_need_qty       IN      STORE_ORDERS.NEED_QTY%TYPE)
RETURN BOOLEAN IS

   L_item_count   NUMBER := 0;
   L_module       VARCHAR2(64) := 'INV_REQUEST_SQL.PREPARE_AD_HOC';

BEGIN
   ---
   -- Check the PL/SQL table
   -- that contains the BULK INSERT records.
   -- If a record exists on the PL/SQL table,
   -- update the qty.
   ---
   FOR i in 1..LP_item_tbl.count LOOP
      if LP_item_tbl(i).item = I_item then
         ---
         LP_item_tbl(i).need_qty := LP_item_tbl(i).need_qty + I_need_qty;
         return TRUE;
         ---
      end if;
   END LOOP;

   ---
   -- If no record exists on the PL/SQL table
   -- for the current item/loc/need date, add a record.
   ---
   L_item_count := LP_item_tbl.count + 1;

   LP_item_tbl(L_item_count).item := I_item;
   LP_item_tbl(L_item_count).need_qty := I_need_qty;
   LP_item_tbl(L_item_count).need_date := I_need_date;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END PREPARE_AD_HOC;
-------------------------------------------------------------------------------
FUNCTION VERIFY_ON_STORE (O_error_message  IN OUT  VARCHAR2,
                          I_store          IN      STORE_ORDERS.STORE%TYPE,
                          I_item           IN      STORE_ORDERS.ITEM%TYPE,
                          I_need_date      IN      STORE_ORDERS.NEED_DATE%TYPE,
                          I_need_qty       IN      STORE_ORDERS.NEED_QTY%TYPE)
RETURN BOOLEAN IS

   L_module VARCHAR2(64) := 'INV_REQUEST_SQL.VERIFY_ON_STORE';
   L_rowid  ROWID        := NULL;

   cursor C_CHECK_UPDATE is
      select rowid
        from store_orders
       where item  = I_item
         and store = I_store
         and need_date = I_need_date;

BEGIN

   open C_CHECK_UPDATE;
   fetch C_CHECK_UPDATE into L_rowid;
   close C_CHECK_UPDATE;
   if L_rowid is NULL then
      if PREPARE_INSERT(O_error_message,
                        I_store,
                        I_item,
                        I_need_date,
                        I_need_qty) = FALSE then
         return FALSE;
      end if;
   else
      if PREPARE_UPDATE(O_error_message,
                        I_need_qty,
                        L_rowid) = FALSE then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END VERIFY_ON_STORE;
---------------------------------------------------------------------------------------------
FUNCTION PREPARE_INSERT(O_error_message  IN OUT  VARCHAR2,
                        I_store          IN      STORE_ORDERS.STORE%TYPE,
                        I_item           IN      STORE_ORDERS.ITEM%TYPE,
                        I_need_date      IN      STORE_ORDERS.NEED_DATE%TYPE,
                        I_need_qty       IN      STORE_ORDERS.NEED_QTY%TYPE)
RETURN BOOLEAN IS

   L_module       VARCHAR2(64) := 'INV_REQUEST_SQL.PREPARE_INSERT';

BEGIN
   ---
   -- Check the PL/SQL table
   -- that contains the BULK INSERT records.
   -- If a record exists on the PL/SQL table,
   -- update the qty.
   ---
   FOR i in 1..P_so_ins_size LOOP
      if P_so_ins_item(i) = I_item and
         P_so_ins_store(i) = I_store and
         P_so_ins_need_date(i) = I_need_date then
         ---
         P_so_ins_need_qty(i) := P_so_ins_need_qty(i) + I_need_qty;
         return TRUE;
         ---
      end if;
   END LOOP;

   ---
   -- If no record exists on the PL/SQL table
   -- for the current item/loc/need date, add a record.
   ---
   P_so_ins_size := P_so_ins_size + 1;
   P_so_ins_item(P_so_ins_size)      := I_item;
   P_so_ins_store(P_so_ins_size)     := I_store;
   P_so_ins_need_date(P_so_ins_size) := I_need_date;
   P_so_ins_need_qty(P_so_ins_size)  := I_need_qty;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END PREPARE_INSERT;
-------------------------------------------------------------------------------
FUNCTION PREPARE_UPDATE(O_error_message  IN OUT  VARCHAR2,
                        I_need_qty       IN      STORE_ORDERS.NEED_QTY%TYPE,
                        I_rowid          IN      ROWID)
RETURN BOOLEAN IS

   L_module       VARCHAR2(64) := 'INV_REQUEST_SQL.PREPARE_UPDATE';

BEGIN
   ---
   -- Add a record to the PL/SQL table
   -- that contains the BULK UPDATE records.
   ---
   P_so_upd_size := P_so_upd_size + 1;
   P_so_upd_need_qty(P_so_upd_size)  := I_need_qty;
   P_so_upd_rowid(P_so_upd_size)  := I_rowid;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END PREPARE_UPDATE;
-------------------------------------------------------------------------------
FUNCTION INIT(O_error_message  IN OUT  VARCHAR2)
RETURN BOOLEAN IS

   L_module       VARCHAR2(64) := 'INV_REQUEST_SQL.INIT';

BEGIN

   P_so_ins_size := 0;
   P_so_upd_size := 0;
   LP_item_tbl.DELETE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END INIT;
--------------------------------------------------------------------------------
FUNCTION FLUSH(O_error_message  IN OUT  VARCHAR2)
RETURN BOOLEAN IS

   L_module       VARCHAR2(64) := 'INV_REQUEST_SQL.FLUSH';

BEGIN

   if P_so_ins_size > 0 then
      ------
      SQL_LIB.SET_MARK('INSERT',NULL,'store_orders','BULK INSERT');
      ---
      FORALL i IN 1..P_so_ins_size
         insert into store_orders(item,
                                  store,
                                  need_date,
                                  need_qty,
                                  processed_date)
                           values(P_so_ins_item(i),
                                  P_so_ins_store(i),
                                  P_so_ins_need_date(i),
                                  P_so_ins_need_qty(i),
                                  NULL);
   end if;

   if P_so_upd_size > 0 then
      SQL_LIB.SET_MARK('UPDATE',NULL,'STORE_ORDERS', 'BULK UPDATE');
      ---
      FORALL i IN 1..P_so_upd_size
        update store_orders
           set need_qty  = need_qty + P_so_upd_need_qty(i)
         where rowid     = P_so_upd_rowid(i);
   end if;

   if LP_item_tbl.count != 0 then
      if CREATE_ORD_TSF_SQL.CREATE_ORD_TSF(O_error_message,
                                           LP_store,
                                           LP_item_tbl) = FALSE then
         return FALSE;
      end if;
   end if;

   P_so_ins_size := 0;
   P_so_upd_size := 0;
   LP_item_tbl.DELETE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END FLUSH;
--------------------------------------------------------------------------------
END INV_REQUEST_SQL;
/

