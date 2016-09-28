CREATE OR REPLACE PACKAGE BODY DEPOSIT_ITEM_SQL AS
--------------------------------------------------------------------
FUNCTION VALIDATE_PACK(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       O_exists          IN OUT   BOOLEAN,
                       I_item            IN       PACKITEM.PACK_NO%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(50)    := 'DEPOSIT_ITEM_SQL.VALIDATE_PACK';

   L_count_items   NUMBER(1);
   L_item_qty      PACKITEM.PACK_QTY%TYPE;
   L_qty_1         PACKITEM.PACK_QTY%TYPE;
   L_qty_2         PACKITEM.PACK_QTY%TYPE;
   L_qty_3         PACKITEM.PACK_QTY%TYPE;
   L_dep_type      ITEM_MASTER.DEPOSIT_ITEM_TYPE%TYPE;
   L_dep_1         ITEM_MASTER.DEPOSIT_ITEM_TYPE%TYPE;
   L_dep_2         ITEM_MASTER.DEPOSIT_ITEM_TYPE%TYPE;
   L_dep_3         ITEM_MASTER.DEPOSIT_ITEM_TYPE%TYPE;
   L_loop_1        BOOLEAN := TRUE;
   L_loop_2        BOOLEAN := FALSE;
   L_loop_3        BOOLEAN := FALSE;
   ---
   cursor C_COUNT_ITEMS is
      select COUNT(*)
        from packitem
       where pack_no = I_item;

   cursor C_GET_DEP_PACK is
      select im.deposit_item_type,
             pi.pack_qty
        from item_master im,
             packitem pi
       where pi.pack_no = I_item
         and pi.item = im.item
         and im.deposit_item_type is not NULL;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   ---
   SQL_LIB.SET_MARK('OPEN','C_COUNT_ITEMS','PACKITEM',NULL);
   open C_COUNT_ITEMS;

   SQL_LIB.SET_MARK('FETCH','C_COUNT_ITEMS','PACKITEM',NULL);
   fetch C_COUNT_ITEMS into L_count_items;

   SQL_LIB.SET_MARK('CLOSE','C_COUNT_ITEMS','PACKITEM',NULL);
   close C_COUNT_ITEMS;

   if L_count_items > 3 then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PACK_COMP',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   elsif L_count_items = 0 then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PACKITEM_FUNC',
                                            L_program,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   if L_count_items NOT in (2,3) then
      O_exists := FALSE;
      return TRUE;
   else

      O_exists := FALSE;

      for rec in C_GET_DEP_PACK LOOP

         -- reinitialize variables
         L_dep_type := NULL;
         L_item_qty := NULL;

         -- get the deposit_type and quantity of item
         L_dep_type := rec.deposit_item_type;
         L_item_qty := rec.pack_qty;

         if L_loop_1 = FALSE and
            L_loop_2 = FALSE then
            O_exists := TRUE;
         end if;

         ---
         if L_dep_type not in ('E', 'A', 'Z') then
            O_exists := FALSE;
            return TRUE;
         elsif L_loop_1 then
            L_dep_1 := L_dep_type;
            L_qty_1 := L_item_qty;
            L_loop_1 := FALSE;
            L_loop_2 := TRUE;
         elsif L_loop_2 then
            L_dep_2 := L_dep_type;
            L_qty_2 := L_item_qty;
            L_loop_2 := FALSE;
            L_loop_3 := TRUE;
         elsif L_loop_3 then
            L_dep_3 := L_dep_type;
            L_qty_3 := L_item_qty;
            L_loop_3 := FALSE;
         end if;

         -- if any of the deposit_item_type value repeats, o_exists is false
         -- if crate quantity is not 1 or content quantity is not equal to container quantity, o_exists is false
         if (L_count_items = 2) and
            (L_loop_3) then
            if (L_dep_1 = L_dep_2) or
               (L_dep_1 = 'Z') or
               (L_dep_2 = 'Z') or
               (L_qty_1 != L_qty_2) then
               O_exists := FALSE;
               return TRUE;
            end if;
         elsif (L_loop_1 = FALSE) and
               (L_loop_2 = FALSE) and
               (L_loop_3 = FALSE) then
            if ((L_dep_1 = L_dep_2) or
                (L_dep_1 = L_dep_3) or
                (L_dep_2 = L_dep_3) or
                ((L_dep_3 = 'Z') and
                 ((L_qty_1 != L_qty_2) or
                  (L_qty_3 != 1))) or
                ((L_dep_2 = 'Z') and
                 ((L_qty_1 != L_qty_3) or
                  (L_qty_2 != 1))) or
                ((L_dep_1 = 'Z') and
                 ((L_qty_2 != L_qty_3) or
                  (L_qty_1 != 1)))) then
               O_exists := FALSE;
               return TRUE;
            end if;
         elsif (L_loop_3) then
            if ((L_dep_1 = L_dep_2) or
                ((L_dep_1 != 'Z') and
                 (L_dep_2 != 'Z') and
                 (L_qty_1 != L_qty_2))) then
               O_exists := FALSE;
               return TRUE;
            end if;
         elsif (L_count_items = 2) and
            (L_loop_3) then
            if L_dep_1 = 'Z' then
               O_exists := FALSE;
               return FALSE;
            end if;
         end if;
      END LOOP;
   end if;

   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END VALIDATE_PACK;
--------------------------------------------------------------------------------
END DEPOSIT_ITEM_SQL;
/

