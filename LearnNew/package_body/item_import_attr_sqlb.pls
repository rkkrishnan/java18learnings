CREATE OR REPLACE PACKAGE BODY ITEM_IMPORT_ATTR_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    22-Jun-2007
--Mod Ref:     Mod number. 365b1
--Mod Details: Cascading the base item import attributes to its variants.
--             Appended TSL_DELETE_INSERT_VARIANT new function.
------------------------------------------------------------------------------------------------
FUNCTION ITEM_CHILD_EXISTS(O_error_message   IN OUT     VARCHAR2,
                           O_exists          IN OUT     BOOLEAN,
                           I_item            IN         ITEM_IMPORT_ATTR.ITEM%TYPE)
			RETURN BOOLEAN IS

   L_item_exists      VARCHAR2(1);

   CURSOR C_SELECT_CHILDREN IS
      select 'X'
        from item_import_attr iia, item_master im
       where im.item = iia.item
         and (im.item_parent = I_item
          or im.item_grandparent = I_item)
         and im.tran_level >= im.item_level;


BEGIN
   SQL_LIB.SET_MARK('open',
                    'C_SELECT_CHILDREN',
                    'item_import_attr',
                    NULL);
   open C_SELECT_CHILDREN ;

   SQL_LIB.SET_MARK('fetch',
                    'C_SELECT_CHILDREN',
                    'item_import_attr',
                    NULL);
   fetch C_SELECT_CHILDREN INTO L_item_exists;

   if C_SELECT_CHILDREN%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('close',
                    'C_SELECT_CHILDREN',
                    'item_import_attr',
                    NULL);
   close C_SELECT_CHILDREN;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ITEM_IMPORT_ATTR_SQL',
                                            to_char(SQLCODE));
	return FALSE;

END ITEM_CHILD_EXISTS;
--------------------------------------------------------------------------------------------
FUNCTION DELETE_INSERT_ITEM_CHILD(O_error_message    IN OUT     VARCHAR2,
                                  I_item             IN         ITEM_IMPORT_ATTR.ITEM%TYPE,
                                  I_tooling          IN         ITEM_IMPORT_ATTR.TOOLING%TYPE,
                                  I_first_order_ind  IN         ITEM_IMPORT_ATTR.FIRST_ORDER_IND%TYPE,
                                  I_amortize_base    IN         ITEM_IMPORT_ATTR.AMORTIZE_BASE%TYPE,
                                  I_open_balance     IN         ITEM_IMPORT_ATTR.OPEN_BALANCE%TYPE,
                                  I_commodity        IN         ITEM_IMPORT_ATTR.COMMODITY%TYPE,
                                  I_import_desc      IN         ITEM_IMPORT_ATTR.IMPORT_DESC%TYPE)
			      RETURN BOOLEAN IS

   L_item          ITEM_IMPORT_ATTR.ITEM%TYPE;
   L_table         VARCHAR2(255) := 'item_import_attr';
   RECORD_LOCKED   EXCEPTION;

   CURSOR C_LOCK_IIA IS
      select 'X'
        from item_master im, item_import_attr iia
       where im.item = iia.item
         and (im.item_parent = I_item
          or im.item_grandparent = I_item)
         and im.tran_level >= im.item_level
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('open',
                    'C_LOCK_IIA',
                    'item_import_attr',
                    NULL);
   open C_LOCK_IIA;

   SQL_LIB.SET_MARK('close',
                    'C_LOCK_IIA',
                    'item_import_attr',
                    NULL);
   close C_LOCK_IIA;
   ---

   SQL_LIB.SET_MARK('delete',
                    'C_APPLY_CHILDREN',
                    'item_import_attr',
                    NULL);
   delete from item_import_attr iia
    where exists (select 'X'
                    from item_master im
                   where (im.item_parent = I_item
                      or im.item_grandparent = I_item)
                     and im.tran_level >= im.item_level
                     and im.item = iia.item);
   ---
   SQL_LIB.SET_MARK('insert',
                    'NULL',
                    'item_import_attr',
                    NULL);
   insert into item_import_attr (item,
                                 tooling,
                                 first_order_ind,
                                 amortize_base,
                                 open_balance,
                                 commodity,
                                 import_desc)
                          select im.item,
                                 I_tooling,
                                 I_first_order_ind,
                                 I_amortize_base,
                                 I_open_balance,
                                 I_commodity,
                                 I_import_desc
                            from item_master im
                           where (im.item_parent = I_item
                              or im.item_grandparent = I_item)
                             and im.tran_level >= im.item_level;

   return TRUE;

   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               L_item,
                                               NULL);
         return FALSE;

      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               'ITEM_IMPORT_ATTR_SQL',
                                               to_char(SQLCODE));
	return FALSE;

END DELETE_INSERT_ITEM_CHILD;
-------------------------------------------------------------------------------------------------------
-- 22-Jun-2007 Govindarajan - MOD 365b1 Begin
-------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_DELETE_INSERT_VARIANT
-- Purpose        : This function will delete and reinsert all records that are Variant Items
--                  of the selected Base Item on the ITEM_IMPORT_ATTR table.
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_INSERT_VARIANT (O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item              IN     ITEM_IMPORT_ATTR.ITEM%TYPE,
                                    I_tooling           IN     ITEM_IMPORT_ATTR.TOOLING%TYPE,
                                    I_first_order_ind   IN     ITEM_IMPORT_ATTR.FIRST_ORDER_IND%TYPE,
                                    I_amortize_base     IN     ITEM_IMPORT_ATTR.AMORTIZE_BASE%TYPE,
                                    I_open_balance      IN     ITEM_IMPORT_ATTR.OPEN_BALANCE%TYPE,
                                    I_commodity         IN     ITEM_IMPORT_ATTR.COMMODITY%TYPE,
                                    I_import_desc       IN     ITEM_IMPORT_ATTR.IMPORT_DESC%TYPE)
   return BOOLEAN is

   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(RECORD_LOCKED, -54);
   L_table              VARCHAR2(255) := 'item_import_attr';
   L_program            VARCHAR2(300) := 'ITEM_IMPORT_ATTR_SQL.TSL_DELETE_INSERT_VARIANT';

   -- This cursor will lock the variant information
   -- on the table ITEM_IMPORT_ATTR table
   cursor C_LOCK_IIA is
      select 'x'
        from item_import_attr iia,
             item_master im
       where im.item           = iia.item
         and im.tsl_base_item  = I_item
         and im.tsl_base_item != im.item
         and im.item_level     = im.tran_level
         and im.item_level     = 2
         for update nowait;

   -- This cursor will return the Variant Items associated to the Base Item information.
   cursor C_GET_VARIANT is
      select im.item item
        from item_master im
       where im.tsl_base_item  = I_item
         and im.tsl_base_item != im.item
         and im.item_level     = im.tran_level
         and im.item_level     = 2;

BEGIN
      if I_item is NULL then      -- L1 begin
          -- If input item is null then throws an eoor
          O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                I_item,
                                                L_program,
                                                NULL);
          return FALSE;
      else                    -- L1 else
          -- Locking the table by opening and closing the C_LOCK_IIA cursor
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_IIA',
                           L_table,
                           'ITEM: ' ||I_item);
          open C_LOCK_IIA;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_IIA',
                           L_table,
                           'ITEM: ' ||I_item);
          close C_LOCK_IIA;

          -- Deleting the records from REQ_DOC table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           L_table,
                           'ITEM: ' ||I_item);

          delete from item_import_attr iia
           where exists (select 'x'
                           from item_master im
                          where im.item         =  iia.item
                            and im.tsl_base_item  = I_item
                            and im.tsl_base_item != im.item
                            and im.item_level     = im.tran_level
                            and im.item_level     = 2);


          -- Getting the variant items from the item_master using C_GET_VARIANT cursor
          -- Opening the cursor C_GET_VARIANT
          SQL_LIB.SET_MARK('OPEN',
                           'C_GET_VARIANT',
                           L_table,
                           'ITEM: ' ||I_item);

          FOR C_get_variant_rec in C_GET_VARIANT
          LOOP              -- L2 bigin
              -- Inserting the item to the item_import_attr table
              SQL_LIB.SET_MARK('INSERT',
                               NULL,
                               L_table,
                               'ITEM: ' ||I_item);

              insert into item_import_attr
                          (item,
                          tooling,
                          first_order_ind,
                          amortize_base,
                          open_balance,
                          commodity,
                          import_desc)
                   values (C_get_variant_rec.item,
                          I_tooling,
                          I_first_order_ind,
                          I_amortize_base,
                          I_open_balance,
                          I_commodity,
                          I_import_desc);
          END LOOP;     -- L2 end
          return TRUE;
      end if;                        -- L1 end

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            'ITEM: ' ||I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_DELETE_INSERT_VARIANT;
-------------------------------------------------------------------------------------------------------
-- 22-Jun-2007 Govindarajan - MOD 365b1 End
-------------------------------------------------------------------------------------------------------
END ITEM_IMPORT_ATTR_SQL;
/

