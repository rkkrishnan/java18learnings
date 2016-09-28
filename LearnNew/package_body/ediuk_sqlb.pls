CREATE OR REPLACE PACKAGE BODY EDIUK_SQL AS

/* declare package wide variables */
LP_item       ITEM_MASTER.ITEM%TYPE;
LP_ref_item   ITEM_MASTER.ITEM%TYPE;
LP_today      PERIOD.VDATE%TYPE;

/* declare package wide performance flags */
LP_date_on     VARCHAR2(1) := 'N';
LP_ref_item_on VARCHAR2(1) := 'N';

-------------------------------------------------------------------
FUNCTION SUPPLIER_EXISTS(O_error_message IN OUT VARCHAR2,
                         I_supplier      IN     SUPS.SUPPLIER%TYPE,
                         I_item_type     IN     VARCHAR2,
                         I_item_id       IN     VARCHAR2,
                         O_exist         IN OUT BOOLEAN)
RETURN BOOLEAN IS

L_program        VARCHAR2(64) := 'EDIUK_SQL.SUPPLIER_EXISTS';
L_return_code    VARCHAR2(5) := 'FALSE';
L_error_message  VARCHAR2(255);
L_dummy          VARCHAR2(1);
ABORTING         EXCEPTION;

   cursor C_SUPPLIER is
   select 'X'
     from item_supplier ss
    where ss.supplier = I_supplier
      and ss.item     = LP_item;

   cursor C_REF_ITEM is
   select im1.item
     from item_master im1, item_master im2
    where im2.item = I_item_id
	and im2.item_level > im2.tran_level
      and (im2.item_parent = im1.item
           or im2.item_grandparent = im1.item)
      and im1.item_level = im1.tran_level;

   cursor C_VPN is
   select ss.item
     from item_supplier ss
    where ss.vpn = I_item_id;

BEGIN
   /* reset package variables */
   LP_ref_item_on := 'N';
   LP_item        := NULL;
   LP_ref_item    := NULL;

   /* Retrieve parent if item is a ref item */
   if i_item_type = 'REF' then
      SQL_LIB.SET_MARK('OPEN','C_REF_ITEM','ITEM_MASTER',
                       'ref item: '||I_item_id);
      open C_REF_ITEM;
      SQL_LIB.SET_MARK('FETCH','C_REF_ITEM','ITEM_MASTER',
                       'ref item: '||I_item_id);
      fetch C_REF_ITEM into LP_item;
      if C_REF_ITEM%NOTFOUND then
         O_exist := FALSE;
         O_error_message := sql_lib.create_msg('ERR_RETRIEVE_REF_ITEM',
                                                L_program,
                                               'ref item: '||I_item_id,
                                               NULL);
      else
         o_exist := TRUE;
         /* set flag to indicate that ref item has been retrieved */
         LP_ref_item_on := 'Y';
         /* initialize package variables with ref item */
         LP_ref_item := i_item_id;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_REF_ITEM','ITEM_MASTER',
                       'ref item: '||I_item_id);
      close C_REF_ITEM;
   end if; /* end of ref item if statement */

   /* Retrieve/validate item if item is a vpn */
   if I_item_type = 'VPN' then
      SQL_LIB.SET_MARK('OPEN','C_VPN','ITEM_SUPPLIER',
                       'vpn: '||(I_item_id)||' supplier: '||to_char(I_supplier));
      open C_VPN;
      SQL_LIB.SET_MARK('FETCH','C_VPN','ITEM_SUPPLIER',
                       'vpn: '||(I_item_id)||' supplier: '||to_char(I_supplier));
      fetch C_VPN into LP_item;
      if C_VPN%NOTFOUND then
         o_exist := FALSE;
         O_error_message := sql_lib.create_msg('INV_VPN',
                                                L_program,
                                               'vpn: '||I_item_id,
                                               'supplier: '||to_char(I_supplier));
      else
         O_exist := TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_VPN','ITEM_SUPPLIER',
                       'vpn: '||(I_item_id)||' supplier: '||to_char(I_supplier));
      close C_VPN;
      ---
      return TRUE;
   end if;  /* end of vpn if statement */
   ---
   if (O_exist = TRUE and I_item_type in ('REF','VPN'))
      or (I_item_type = 'ITM') then
      /* Validate that item exists on item_supplier */
      if I_item_type = 'ITM' then
         LP_item := I_item_id;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN','C_SUPPLIER','ITEM_SUPPLIER',
                       'item: '||LP_item||' supplier: '||to_char(I_supplier));
      open C_SUPPLIER;
      SQL_LIB.SET_MARK('FETCH','C_SUPPLIER','ITEM_SUPPLIER',
                    'item: '||LP_item||' supplier: '||to_char(I_supplier));
      fetch C_SUPPLIER into L_dummy;
      if C_SUPPLIER%NOTFOUND then
         O_exist := FALSE;
         O_error_message := sql_lib.create_msg('INV_SKU_SUP',
                                                L_program,
                                               'item: '||LP_item,
                                               'supplier: '||to_char(i_supplier));
      else
         O_exist := TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_SUPPLIER','ITEM_SUPPLIER',
                       'item: '||LP_item||' supplier: '||to_char(I_supplier));
      close C_SUPPLIER;
   end if;
   ---
   return TRUE;

EXCEPTION
when ABORTING then
   return FALSE;
when OTHERS then
   o_error_message := sql_lib.create_msg('PACKAGE_ERROR',
	  				 SQLERRM,
					 L_program,
					 to_char(SQLCODE));
   return FALSE;

END SUPPLIER_EXISTS;
-------------------------------------------------------------------
FUNCTION SUP_AVAIL_INSERTS(I_supplier      IN     SUPS.SUPPLIER%TYPE,
                           I_avail_qty     IN     NUMBER,
                           O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'EDIUK_SQL.SUP_AVAIL_INSERTS';
   L_exists        BOOLEAN;
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_DATE is
      select vdate
        from period;

   cursor C_LOCK_SUP_AVAIL is
      select 'x'
        from sup_avail
       where item     = LP_item
         and supplier = I_supplier
         for update nowait;

BEGIN

      /* fetch the date if it hasn't already been retrieved */
      if LP_date_on != 'Y' then

         SQL_LIB.SET_MARK('OPEN','C_DATE','PERIOD','vdate');
         open C_DATE;

         SQL_LIB.SET_MARK('FETCH','C_DATE','PERIOD','vdate');
         fetch C_DATE into LP_today;

         SQL_LIB.SET_MARK('CLOSE','C_DATE','PERIOD','vdate');
         close C_DATE;

         LP_date_on := 'Y';
      end if;

      SQL_LIB.SET_MARK('UPDATE', NULL,'SUP_AVAIL',
                  'item: '||LP_item||' supplier: '||to_char(I_supplier));
      ---
      open C_LOCK_SUP_AVAIL;
      close C_LOCK_SUP_AVAIL;
      ---
      update sup_avail sa
         set qty_avail = I_avail_qty,
             last_update_date = LP_today,
             last_declared_date = LP_today
       where item     = LP_item
         and supplier = I_supplier;

      if SQL%NOTFOUND then

         /* if no ref item has been retreived yet then retrieve it */
         if LP_ref_item_on = 'N' then
            if ITEM_ATTRIB_SQL.GET_PRIMARY_REF_ITEM(O_error_message,
                                                    LP_ref_item,
                                                    L_exists,
                                                    LP_item) = FALSE then
               return FALSE;
            end if;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL,'SUP_AVAIL',
                'item: '||LP_item||' supplier: '||to_char(I_supplier));

         insert into sup_avail
               (supplier,
                item,
                ref_item,
                qty_avail,
                last_update_date,
                last_declared_date)
        values (I_supplier,
                LP_item,
                LP_ref_item,
                I_avail_qty,
                LP_today,
                LP_today);
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'SUP_AVAIL',
                                            to_char(I_supplier),
                                            LP_item);
      return FALSE;
      when OTHERS then
         o_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
	 RETURN FALSE;

END SUP_AVAIL_INSERTS;
-------------------------------------------------------------------
END EDIUK_SQL;
/

