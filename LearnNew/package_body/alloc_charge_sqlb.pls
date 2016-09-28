CREATE OR REPLACE PACKAGE BODY ALLOC_CHARGE_SQL AS
-------------------------------------------------------------------------------
FUNCTION DELETE_CHRGS(O_error_message IN OUT VARCHAR2,
                      I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                      I_to_loc        IN     ITEM_LOC.LOC%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(50) := 'ALLOC_CHARGE_SQL.DELETE_CHRGS';
   L_table       VARCHAR2(30) := 'ALLOC_CHRG';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_ALLOC_CHRG is
      select 'x'
        from alloc_chrg
       where alloc_no = I_alloc_no
         and to_loc   = nvl(I_to_loc, to_loc)
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ALLOC_CHRG','ALLOC_CHRG','alloc: '||to_char(I_alloc_no));
   open C_LOCK_ALLOC_CHRG;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALLOC_CHRG','ALLOC_CHRG','alloc: '||to_char(I_alloc_no));
   close C_LOCK_ALLOC_CHRG;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'ALLOC_CHRG','alloc: '||to_char(I_alloc_no));
   delete from alloc_chrg
         where alloc_no = I_alloc_no
           and to_loc   = nvl(I_to_loc, to_loc);
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_alloc_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_CHRGS;
--------------------------------------------------------------------------------
FUNCTION DEFAULT_CHRGS(O_error_message IN OUT VARCHAR2,
                       I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                       I_from_loc      IN     STORE.STORE%TYPE,
                       I_to_loc        IN     STORE.STORE%TYPE,
                       I_to_loc_type   IN     ITEM_LOC.LOC_TYPE%TYPE,
                       I_item          IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(65) := 'ALLOC_CHARGE_SQL.DEFAULT_CHRGS';
   L_item               ITEM_MASTER.ITEM%TYPE;
   L_comp_item          ITEM_MASTER.ITEM%TYPE;
   L_default_chrgs_ind  TSF_TYPE.DEFAULT_CHRGS_IND%TYPE := 'N';
   L_buyer_pack         VARCHAR2(1)                     := 'N';

   cursor C_BUYER_PACK is
      select 'Y'
        from item_master
       where item      = L_item
         and pack_ind  = 'Y'
         and pack_type = 'B';

   cursor C_PACKITEM is
      select item
        from v_packsku_qty
       where pack_no = L_item;

   -----------------------------------------------------------------------------------------
   -- Internal function called to perform the actual inserts into alloc_chrg
   ---
   FUNCTION INSERT_CHRGS(IF_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                         IF_from_loc      IN     STORE.STORE%TYPE,
                         IF_to_loc        IN     STORE.STORE%TYPE,
                         IF_to_loc_type   IN     ITEM_LOC.LOC_TYPE%TYPE,
                         IF_item          IN     ITEM_MASTER.ITEM%TYPE,
                         IF_pack_item     IN     ITEM_MASTER.ITEM%TYPE)
      RETURN BOOLEAN IS

      LF_program   VARCHAR2(40) := 'ALLOC_CHARGE_SQL.INSERT_CHRGS';

   BEGIN
      SQL_LIB.SET_MARK('INSERT', NULL, 'ALLOC_CHRG', NULL);
      insert into alloc_chrg(alloc_no,
                             to_loc,
                             item,
                             comp_id,
                             pack_item,
                             to_loc_type,
                             comp_rate,
                             per_count,
                             per_count_uom,
                             up_chrg_group,
                             comp_currency,
                             display_order)
                      select IF_alloc_no,
                             IF_to_loc,
                             IF_item,
                             comp_id,
                             IF_pack_item,
                             IF_to_loc_type,
                             comp_rate,
                             per_count,
                             per_count_uom,
                             up_chrg_group,
                             comp_currency,
                             display_order
                        from item_chrg_detail i
                       where item          = IF_item
                         and from_loc      = IF_from_loc
                         and to_loc        = IF_to_loc
                         and not exists(select 'Y'
                                          from alloc_chrg a
                                         where a.alloc_no          = IF_alloc_no
                                           and a.to_loc            = IF_to_loc
                                           and a.item              = IF_item
                                           and ((a.pack_item       = IF_pack_item
                                                 and IF_pack_item is not NULL)
                                             or (IF_pack_item     is NULL
                                                 and a.pack_item  is NULL))
                                           and a.comp_id           = i.comp_id);
      ---
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               LF_program,
                                               to_char(SQLCODE));
         return FALSE;
   END INSERT_CHRGS;
   -----------------------------------------------------------------------------------------
BEGIN
   ---
   -- If Default Up Charges Indicator is set to 'N'
   -- return TRUE without defaulting any charges.
   ---
   if SYSTEM_OPTIONS_SQL.GET_DEFAULT_ALLOC_CHRG_IND(O_error_message,
                                                    L_default_chrgs_ind) = FALSE then
      return FALSE;
   end if;
   ---
   if L_default_chrgs_ind = 'N' then
      return TRUE;
   end if;
   ---
   L_item := I_item;
   ---
   SQL_LIB.SET_MARK('OPEN','C_BUYER_PACK','ITEM_MASTER','Pack no: '||L_item);
   open C_BUYER_PACK;
   SQL_LIB.SET_MARK('FETCH','C_BUYER_PACK','ITEM_MASTER','Pack no: '||L_item);
   fetch C_BUYER_PACK into L_buyer_pack;
   SQL_LIB.SET_MARK('CLOSE','C_BUYER_PACK','ITEM_MASTER','Pack no: '||L_item);
   close C_BUYER_PACK;
   ---
   if L_buyer_pack = 'N' then
      if INSERT_CHRGS(I_alloc_no,
                      I_from_loc,
                      I_to_loc,
                      I_to_loc_type,
                      L_item,
                      NULL) = FALSE then
         return FALSE;
      end if;
   else  -- L_buyer_pack = 'Y'
      for C_rec in C_PACKITEM loop
         L_comp_item := C_rec.item;
         ---
         if INSERT_CHRGS(I_alloc_no,
                         I_from_loc,
                         I_to_loc,
                         I_to_loc_type,
                         L_comp_item,
                         L_item) = FALSE then
            return FALSE;
         end if;
      end loop;
   end if; -- L_buyer_pack = 'N'
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_CHRGS;
---------------------------------------------------------------------------------------------
FUNCTION CHARGES_EXIST(O_error_message IN OUT VARCHAR2,
                       O_exists        IN OUT BOOLEAN,
                       I_alloc_no      IN     ALLOC_HEADER.ALLOC_NO%TYPE,
                       I_to_loc        IN     STORE.STORE%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60)  := 'ALLOC_CHARGE_SQL.CHARGES_EXIST';
   L_exists    VARCHAR2(1)   := 'N';

   cursor C_CHARGES_EXIST is
      select 'Y'
        from alloc_chrg
       where alloc_no = I_alloc_no
         and to_loc   = NVL(I_to_loc, to_loc);

BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHARGES_EXIST','ALLOC_CHRG','Alloc: '||to_char(I_alloc_no));
   open C_CHARGES_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_CHARGES_EXIST','ALLOC_CHRG','Alloc: '||to_char(I_alloc_no));
   fetch C_CHARGES_EXIST into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHARGES_EXIST','ALLOC_CHRG','Alloc: '||to_char(I_alloc_no));
   close C_CHARGES_EXIST;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
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
END CHARGES_EXIST;
--------------------------------------------------------------------------------------
END ALLOC_CHARGE_SQL;
/

