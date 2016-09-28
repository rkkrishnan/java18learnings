CREATE OR REPLACE PACKAGE BODY ITEM_SUPP_UOM_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Ramasamy
--Mod Date:    05-Jul-2007
--Mod Ref:     Mod number. 365b
--Mod Details: Amended script to explodes the base varient item information.
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--Mod By:      Karthik Dhanapal
--Mod Date:    15-Oct-2007
--Mod Ref:     Mod number. 365b
--Mod Details: Added condition for the where clause of the insert statement of TSL_COPY_BASE_ITSUPUOM.
------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
FUNCTION COPY_DOWN_PARENT_INFO(O_error_message     IN OUT VARCHAR2,
                               I_item              IN     ITEM_SUPP_UOM.ITEM%TYPE,
                               I_supplier          IN     ITEM_SUPP_UOM.SUPPLIER%TYPE)
   return BOOLEAN is
   L_program        VARCHAR2(64) := 'ITEM_SUPP_UOM_SQL.COPY_DOWN_PARENT_INFO';
   L_table          VARCHAR2(255) := 'ITEM_SUPP_UOM';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           Exception_Init(Record_Locked, -54);

   cursor C_RECORD_LOCKED is
      select 'x'
        from item_supp_uom isu
       where isu.supplier = I_supplier
         and isu.item in (select item
                            from item_master
                           where (item_parent       = I_item
                              or  item_grandparent  = I_item)
                             and item_level >= tran_level)
      for update nowait;


BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_RECORD_LOCKED',
                       'ITEM_SUPP_UOM',
                        NULL);
      open C_RECORD_LOCKED;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_RECORD_LOCKED',
                       'ITEM_SUPP_UOM',
                        NULL);
      close C_RECORD_LOCKED;


      SQL_LIB.SET_MARK('DELETE',
                        NULL,
                       'ITEM_SUPP_UOM',
                        NULL);

      delete from item_supp_uom isu
       where isu.supplier = I_supplier
         and isu.item in (select item
                            from item_master
                           where (item_parent       = I_item
                              or  item_grandparent  = I_item)
                             and item_level <= tran_level);

      SQL_LIB.SET_MARK('INSERT',
                        NULL,
                       'ITEM_SUPP_UOM',
                        NULL);
      insert into item_supp_uom(item,
                                supplier,
                                uom,
                                value,
                                create_datetime,
                                last_update_datetime,
                                last_update_id)
                         select im.item,
                                isu.supplier,
                                isu.uom,
                                isu.value,
                                SYSDATE,
                                SYSDATE,
                                USER
                           from item_supp_uom isu,
                                item_master im,
                                item_supplier its
                          where isu.item     = I_item
                            and isu.supplier = I_supplier
                            and isu.supplier = its.supplier
                            and its.item     = im.item
                            and im.item in (select item
                                              from item_master
                                             where (item_parent      = I_item
                                                or  item_grandparent = I_item)
                                               and item_level <= tran_level);
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
     O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                            NULL);
     return FALSE;
   when OTHERS then
       O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
			  	             SQLERRM,
				             L_program,
				             to_char(SQLCODE));
      RETURN FALSE;
END COPY_DOWN_PARENT_INFO;
--------------------------------------------------------------------------------------------
FUNCTION CHILD_ITEM_FOR_SUPP_EXISTS(O_error_message IN OUT VARCHAR2,
                                    O_exists        IN OUT BOOLEAN,
                                    I_item          IN     ITEM_SUPP_UOM.ITEM%TYPE,
                                    I_supplier      IN     ITEM_SUPP_UOM.SUPPLIER%TYPE)
   return BOOLEAN IS
   ---
   L_program     VARCHAR2(64) := 'ITEM_SUPP_UOM_SQL.CHILD_ITEM_FOR_SUPP_EXISTS';
   L_select_ind  VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select 'x'
        from item_supplier isp,
             item_master im
       where (  (im.item_parent      is NOT NULL and im.item_parent      = I_item)
              or(im.item_grandparent is NOT NULL and im.item_grandparent = I_item))
         and im.item        = isp.item
         and im.item_level <= im.tran_level
         and isp.supplier   = I_supplier;
BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_SUPPLIER',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'ITEM_SUPPLIER',
                    'Item: '||I_item||', Supplier: '||to_char(I_supplier));
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'ITEM_SUPPLIER',
                    'Item: '||I_item||', Supplier: '||to_char(I_supplier));
   fetch C_EXISTS into L_select_ind;
   if C_EXISTS%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'ITEM_SUPPLIER',
                    'Item: '||I_item||', Supplier: '||to_char(I_supplier));
   close C_EXISTS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHILD_ITEM_FOR_SUPP_EXISTS;
--------------------------------------------------------------------------------------------
--05-Jul-2007 WiproEnabler/Ramasamy - MOD 365b   Begin
---------------------------------------------------------------------------------------------------------------
   --TSL_COPY_BASE_ITSUPUOM     This function copies the Base item information over its Variant Items information.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_COPY_BASE_ITSUPUOM(O_error_message IN OUT VARCHAR2,
                                   I_item          IN     ITEM_SUPP_UOM.ITEM%TYPE,
                                   I_supplier      IN     ITEM_SUPP_UOM.SUPPLIER%TYPE)
      return BOOLEAN is

      L_program VARCHAR2(64) := 'ITEM_SUPP_UOM_SQL.TSL_COPY_BASE_ITSUPUOM  ';
      L_table   VARCHAR2(65) := 'ITEM_SUPP_UOM';
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);
      --This cursor will return all the Variant Items associated to the selected Base Item, and
      --that have the same Diff_1 or Diff_2, or null
      cursor C_RECORD_LOCKED is
         select 'x'
           from item_supp_uom isu
          where isu.supplier = I_supplier
            and isu.item in (select im.item
                               from item_master im
                              where im.tsl_base_item = I_item
                                and im.tsl_base_item != im.item
                                and im.item_level    = im.tran_level
                                and im.item_level    = 2)
            for update nowait;
   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_item',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --Checking whether I_supplier is null
      if I_supplier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                               'I_supplier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      --
      --Opening the cursor C_RECORD_LOCKED
      SQL_LIB.SET_MARK('OPEN',
                       'C_RECORD_LOCKED',
                       'ITEM_SUPP_UOM',
                       'ITEM: ' || I_item);
      open C_RECORD_LOCKED;
      --Closing the cursor C_RECORD_LOCKED
      SQL_LIB.SET_MARK('CLOSE',
                       'C_RECORD_LOCKED',
                       'ITEM_SUPP_UOM',
                       'ITEM: ' || I_item);
      close C_RECORD_LOCKED;
      --
      --Delete records from the ITEM_SUPP_UOM table
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'ITEM_SUPP_UOM',
                       'ITEM: ' || I_item);
      --
      delete from item_supp_uom isu
       where isu.supplier = I_supplier
         and isu.item in (select im.item
                            from item_master im
                           where im.tsl_base_item = I_item
                             and im.tsl_base_item != im.item
                             and im.item_level    = im.tran_level
                             and im.item_level    = 2);
      --
      --Insert records into the ITEM_SUPP_UOM table
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ITEM_SUPP_UOM',
                       'ITEM: ' || I_item);
      --
      insert into item_supp_uom
         (item,
          supplier,
          uom,
          value,
          create_datetime,
          last_update_datetime,
          last_update_id)
         (select im.item,
                 isu.supplier,
                 isu.uom,
                 isu.value,
                 SYSDATE,
                 SYSDATE,
                 USER
            from item_supp_uom  isu,
                 item_master    im,
                 item_supplier  its
           where isu.supplier     = I_supplier
             and im.tsl_base_item = isu.item
             and im.tsl_base_item != im.item
             and im.item_level    = im.tran_level
             and im.item_level    = 2
             and isu.item         = its.item
             and isu.supplier     = its.supplier
             --15-OCT-2007   WIPROENABLER/KARTHIK   MOD365b  BEGIN
             and im.tsl_base_item = I_item
             --15-OCT-2007   WIPROENABLER/KARTHIK   MOD365b  END
             );
      --
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               TO_CHAR(I_supplier));
         return FALSE;
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_COPY_BASE_ITSUPUOM;
   --05-Jul-2007 WiproEnabler/Ramasamy - MOD 365b   End
   --------------------------------------------------------------------------------------
END ITEM_SUPP_UOM_SQL;
/

