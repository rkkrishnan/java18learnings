CREATE OR REPLACE PACKAGE BODY ITEM_TARIFF_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    25-Jun-2007
--Mod Ref:     Mod number. 365b1
--Mod Details: Cascading the base item tariff to its variants.
--             Appeneded TSL_COPY_BASE_TARIFF new function.
------------------------------------------------------------------------------------------------
FUNCTION COPY_DOWN_PARENT_TARIFF (O_error_message  IN OUT VARCHAR2,
                                  I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(65) := 'ITEM_TARIFF_SQL.COPY_DOWN_PARENT_TARIFF';
   L_table         VARCHAR2(65);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_ELIGIBLE_TARIFF is
      select 'x'
        from cond_tariff_treatment
       where item in (select item
                        from item_master
                       where (item_parent = I_item
                          or item_grandparent = I_item)
                         and item_level <= tran_level)
         for update nowait;


BEGIN

   L_table := 'COND_TARIFF_TREATMENT';

   open  C_LOCK_ITEM_ELIGIBLE_TARIFF;
   close C_LOCK_ITEM_ELIGIBLE_TARIFF;

   SQL_LIB.SET_MARK('DELETE', NULL, 'COND_TARIFF_TREATMENT',
                'Item: ' || I_item);

   delete cond_tariff_treatment
       where item in (select item
                        from item_master
                       where (item_parent = I_item
                          or item_grandparent = I_item)
                         and item_level <= tran_level);
   ---
   ---
   if ELC_CALC_SQL.CALC_COMP(O_error_message,
                             'IA',
                             I_item,
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
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'COND_TARIFF_TREATMENT',
                'Item: ' || I_item);

   insert into cond_tariff_treatment (item,
                                      tariff_treatment,
                                      create_datetime,
                                      last_update_datetime,
                                      last_update_id)
                               select im.item,
                                      ct.tariff_treatment,
                                      sysdate,
                                      sysdate,
                                      user
                                 from cond_tariff_treatment ct,
                                      item_master im
                                where ct.item = I_item
                                  and (im.item_parent = ct.item
                                       or im.item_grandparent = ct.item)
                                  and item_level <= tran_level;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('TABLE_LOCKED',
                                           L_table,
                                           I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END COPY_DOWN_PARENT_TARIFF;
-------------------------------------------------------------------------------------------------------
-- 25-Jun-2007 Govindarajan - MOD 365b1 Begin
-------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_COPY_BASE_TARIFF
-- Purpose        : Remove old COND_TARIFF_TREATMENT values of all Variant Items
--                  associated to the passed in item, get latest values for the
--                  Base Item, and insert new COND_TARIFF_TREATMENT values for
--                  the valid Variant Items.
------------------------------------------------------------------------------------
FUNCTION TSL_COPY_BASE_TARIFF (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_table          VARCHAR2(65) := 'COND_TARIFF_TREATMENT';
   L_program        VARCHAR2(300) := 'ITEM_TARIFF_SQL.TSL_COPY_BASE_TARIFF';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);
   L_valid          BOOLEAN;

   -- This cursor will lock the variant information on the
   -- table COND_TARIFF_TREATMENT table
   cursor C_LOCK_ITEM_ELIGIBLE_TARIFF is
      select 'x'
        from cond_tariff_treatment ctt
       where ctt.item in (select im.item
                            from item_master im
                           where im.tsl_base_item  = I_item
                             and im.tsl_base_item != im.item
                             and im.item_level     = im.tran_level
                             and im.item_level     = 2)
         for update nowait;

   -- This cursor will return the Variant Items number
   -- associated to the Base Item information.
   cursor C_INSERT_CTT is
      select im.item item,
             ctt.tariff_treatment
        from cond_tariff_treatment ctt,
             item_master im
       where ctt.item           = I_item
         and ctt.item           = NVL(im.tsl_base_item, im.item)
         and im.tsl_base_item  != im.item
         and im.item_level      = im.tran_level
         and im.item_level      = 2;

BEGIN
      if I_item is NULL then                                       -- L1 begin
          -- If input item is null then throws an error
          O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                I_item,
                                                L_program,
                                                NULL);
          return FALSE;
      else                                                        -- L1 else

          -- Opening and closing the C_LOCK_ITEM_ELIGIBLE_TARIFF cursor
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_ITEM_ELIGIBLE_TARIFF',
                           L_table,
                           'ITEM: ' ||I_item);
          open C_LOCK_ITEM_ELIGIBLE_TARIFF;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_ITEM_ELIGIBLE_TARIFF',
                           L_table,
                           'ITEM: ' ||I_item);
          close C_LOCK_ITEM_ELIGIBLE_TARIFF;

          -- Deleting the records from COND_TARIFF_TREATMENT table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           L_table,
                           'ITEM: ' ||I_item);

          delete from cond_tariff_treatment
           where item in (select im.item
                            from item_master im
                           where im.tsl_base_item  = I_item
                             and im.tsl_base_item != im.item
                             and im.item_level     = im.tran_level
                             and im.item_level     = 2);

          -- calling ELC_CALC_SQL.CALC_COMP function
          L_valid := ELC_CALC_SQL.CALC_COMP (O_error_message,
                                             'IA',
                                             I_item,
                                             NULL ,
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
                                             NULL);

          if L_valid = TRUE then              -- L2 begin

              -- Cursor for ITEM_HTS table
              -- Opening the cursor C_INSERT_CTT
              SQL_LIB.SET_MARK('OPEN',
                               'C_INSERT_CTT',
                               L_table,
                               'ITEM: ' ||I_item);
              FOR C_insert_ctt_rec in C_INSERT_CTT
              LOOP                                            -- L3 begin
                  -- Inserting records into ITEM_HTS table
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   L_table,
                                   'ITEM: ' ||I_item);

                  insert into cond_tariff_treatment
                              (item,
                               tariff_treatment,
                               create_datetime,
                               last_update_datetime,
                               last_update_id)
                       values (C_insert_ctt_rec.item,
                               C_insert_ctt_rec.tariff_treatment,
                               SYSDATE,
                               SYSDATE,
                               USER);

              END LOOP;         -- L3 end

              return TRUE;
          else                       -- L2 else
              return FALSE;
          end if;                    -- L2 end
      end if;                                              -- L1 end
EXCEPTION
   -- Raising an exception for record lock error
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            'ITEM: ' ||I_item);
      return FALSE;

   -- Raising an exception for others
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END TSL_COPY_BASE_TARIFF;
-------------------------------------------------------------------------------------------------------
-- 25-Jun-2007 Govindarajan - MOD 365b1 End
-------------------------------------------------------------------------------------------------------
END ITEM_TARIFF_SQL;
/

