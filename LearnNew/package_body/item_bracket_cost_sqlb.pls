CREATE OR REPLACE PACKAGE BODY ITEM_BRACKET_COST_SQL AS
------------------------------------------------------------------------------
FUNCTION GET_BRACKET(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     O_bracket_type1     IN OUT   SUP_INV_MGMT.BRACKET_TYPE1%TYPE,
                     O_bracket_uom1      IN OUT   SUP_INV_MGMT.BRACKET_UOM1%TYPE,
                     O_bracket_type2     IN OUT   SUP_INV_MGMT.BRACKET_TYPE2%TYPE,
                     O_bracket_uom2      IN OUT   SUP_INV_MGMT.BRACKET_UOM2%TYPE,
                     O_sup_dept_seq_no   IN OUT   SUP_INV_MGMT.SUP_DEPT_SEQ_NO%TYPE,
                     I_supplier          IN       SUP_INV_MGMT.SUPPLIER%TYPE,
                     I_dept              IN       SUP_INV_MGMT.DEPT%TYPE,
                     I_location          IN       SUP_INV_MGMT.LOCATION%TYPE)
RETURN BOOLEAN IS
   L_program     VARCHAR2(60) := 'ITEM_BRACKET_COST_SQL.GET_BRACKET';
   L_bracket_level   VARCHAR2(3);

   cursor C_GET_SDL_BRACKET is
      select bracket_type1,
             bracket_uom1,
             bracket_type2,
             bracket_uom2,
             sup_dept_seq_no
        from sup_inv_mgmt s,
             wh w
       where supplier   = I_supplier
         and dept       = I_dept
         and s.location = w.physical_wh
         and w.wh       = I_location;

   cursor C_GET_SD_BRACKET is
      select bracket_type1,
             bracket_uom1,
             bracket_type2,
             bracket_uom2,
             sup_dept_seq_no
        from sup_inv_mgmt
       where supplier = I_supplier
         and dept     = I_dept
         and location is NULL;

   cursor C_GET_S_BRACKET is
      select bracket_type1,
             bracket_uom1,
             bracket_type2,
             bracket_uom2,
             sup_dept_seq_no
        from sup_inv_mgmt
       where supplier = I_supplier
         and dept is NULL
         and location is NULL;

   cursor C_GET_SL_BRACKET is
      select bracket_type1,
             bracket_uom1,
             bracket_type2,
             bracket_uom2,
             sup_dept_seq_no
        from sup_inv_mgmt s,
             wh w
       where supplier   = I_supplier
         and dept is NULL
         and s.location = w.physical_wh
         and w.wh       = I_location;

BEGIN
   if I_supplier is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_supplier',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if not SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                              L_bracket_level,
                                              I_supplier) then
      return FALSE;
   end if;

   if L_bracket_level = 'L' then
      SQL_LIB.SET_MARK('OPEN','C_GET_SL_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                       || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
      open C_GET_SL_BRACKET;
      SQL_LIB.SET_MARK('FETCH','C_GET_SL_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                       || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
      fetch C_GET_SL_BRACKET into O_bracket_type1,
                                  O_bracket_uom1,
                                  O_bracket_type2,
                                  O_bracket_uom2,
                                  O_sup_dept_seq_no;
      if C_GET_SL_BRACKET%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_GET_SL_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         close C_GET_SL_BRACKET;
         SQL_LIB.SET_MARK('OPEN','C_GET_S_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         open C_GET_S_BRACKET;
         SQL_LIB.SET_MARK('FETCH','C_GET_S_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         fetch C_GET_S_BRACKET into O_bracket_type1,
                                    O_bracket_uom1,
                                    O_bracket_type2,
                                    O_bracket_uom2,
                                    O_sup_dept_seq_no;
         SQL_LIB.SET_MARK('CLOSE','C_GET_S_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         close C_GET_S_BRACKET;
      else
         SQL_LIB.SET_MARK('CLOSE','C_GET_SL_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         close C_GET_SL_BRACKET;
      end if;
   else
      SQL_LIB.SET_MARK('OPEN','C_GET_SDL_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                       || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
      open C_GET_SDL_BRACKET;
      SQL_LIB.SET_MARK('FETCH','C_GET_SDL_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                       || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
      fetch C_GET_SDL_BRACKET into O_bracket_type1,
                                   O_bracket_uom1,
                                   O_bracket_type2,
                                   O_bracket_uom2,
                                   O_sup_dept_seq_no;
      if C_GET_SDL_BRACKET%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_GET_SDL_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         close C_GET_SDL_BRACKET;
         SQL_LIB.SET_MARK('OPEN','C_GET_SD_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         open C_GET_SD_BRACKET;
         SQL_LIB.SET_MARK('FETCH','C_GET_SD_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         fetch C_GET_SD_BRACKET into O_bracket_type1,
                                     O_bracket_uom1,
                                     O_bracket_type2,
                                     O_bracket_uom2,
                                     O_sup_dept_seq_no;
         if C_GET_SD_BRACKET%NOTFOUND then
            SQL_LIB.SET_MARK('CLOSE','C_GET_SD_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                             || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
            close C_GET_SD_BRACKET;
            SQL_LIB.SET_MARK('OPEN','C_GET_S_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                             || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
            open C_GET_S_BRACKET;
            SQL_LIB.SET_MARK('FETCH','C_GET_S_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                             || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
            fetch C_GET_S_BRACKET into O_bracket_type1,
                                       O_bracket_uom1,
                                       O_bracket_type2,
                                       O_bracket_uom2,
                                       O_sup_dept_seq_no;
            SQL_LIB.SET_MARK('CLOSE','C_GET_S_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
            close C_GET_S_BRACKET;
         else
            SQL_LIB.SET_MARK('CLOSE','C_GET_SD_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                             || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
            close C_GET_SD_BRACKET;
         end if;
      else
         SQL_LIB.SET_MARK('CLOSE','C_GET_SDL_BRACKET','SUP_INV_MGMT', 'SUPPLIER: '|| to_char(I_supplier)
                          || 'DEPARTMENT: '||to_char(I_dept) || 'LOCATION: '||to_char(I_location));
         close C_GET_SDL_BRACKET;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_BRACKET;
------------------------------------------------------------------------------
FUNCTION UPDATE_ALL_LOCATION_BRACKETS(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                      I_item               IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ITEM%TYPE,
                                      I_supplier           IN       ITEM_SUPP_COUNTRY_BRACKET_COST.SUPPLIER%TYPE,
                                      I_origin_country     IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ORIGIN_COUNTRY_ID%TYPE,
                                      I_process_children   IN       VARCHAR2)
RETURN BOOLEAN IS

   L_program        VARCHAR2(60)  := 'ITEM_BRACKET_COST_SQL.UPDATE_ALL_LOCATION_BRACKETS';
   L_table          VARCHAR2(30)  := 'ITEM_SUPP_COUNTRY_BRACKET_COST';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   L_bracket_value  ITEM_SUPP_COUNTRY_BRACKET_COST.BRACKET_VALUE1%TYPE;

   cursor C_UPDATE_COST is
      select bracket_value1,
             unit_cost
        from item_supp_country_bracket_cost
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country
         and location is NULL;

   cursor C_LOCK_ISCBC is
      select 'x'
        from item_supp_country_bracket_cost
       where item               = I_item
         and supplier           = I_supplier
         and origin_country_id  = I_origin_country
         and bracket_value1     = L_bracket_value
         and location is not NULL
         for update nowait;

   cursor C_UPDATE_LOCS is
      select loc
        from item_supp_country_loc
       where item               = I_item
         and supplier           = I_supplier
         and origin_country_id  = I_origin_country
         and loc_type = 'W';

   cursor C_GET_CHILDREN is
      select im.item
        from item_master im,
             item_supp_country_bracket_cost iscbc
       where iscbc.supplier          = I_supplier
         and iscbc.origin_country_id = I_origin_country
         and (im.item_parent         = I_item or
              im.item_grandparent    = I_item)
         and im.item_level          <= im.tran_level
         and iscbc.item              = im.item;

BEGIN
   if I_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_supplier',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_origin_country is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_origin_country',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   --- Loop through and get the cost for each bracket at the item/supplier/country bracket level
   --- use that cost to update the corresponding bracket's cost at the item/supplier/country/location bracket level.
   FOR rec in C_UPDATE_COST LOOP
      L_bracket_value := rec.bracket_value1;

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country));
      open C_LOCK_ISCBC;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country));
      close C_LOCK_ISCBC;

      SQL_LIB.SET_MARK('UPDATE','ITEM_SUPP_COUNTRY_BRACKET_COST', NULL, 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country));

      update item_supp_country_bracket_cost
         set unit_cost = rec.unit_cost
       where item               = I_item
         and supplier           = I_supplier
         and origin_country_id  = I_origin_country
         and bracket_value1     = L_bracket_value
         and location is not NULL;

   END LOOP;

   --- Loop through each location at the item/supplier/country/location bracket level and
   --- update the cost at item/supplier/country/location to the primary brackets cost.
   FOR rec in C_UPDATE_LOCS LOOP
      --- 'N'o is passed into the UPDATE_LOCATION_COST function for processing children because this
      --- function will call UPDATE_LOCATION_COST by child item if processing children is 'Y'es.
      if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                        I_item,
                                                        I_supplier,
                                                        I_origin_country,
                                                        rec.loc,
                                                        'N') then
         return FALSE;
      end if;
   END LOOP;

   --- if the item is a parent, then recall this function for each child item.
   if I_process_children = 'Y' then
      FOR rec in C_GET_CHILDREN LOOP
         if not ITEM_BRACKET_COST_SQL.UPDATE_ALL_LOCATION_BRACKETS(O_error_message,
                                                                   rec.item,
                                                                   I_supplier,
                                                                   I_origin_country,
                                                                   'N') then
            return FALSE;
         end if;
      END LOOP;
   end if;
return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'Item: '||I_item ||', Supplier : '||to_char(I_supplier) ||',
                                             Origin Country: '||I_origin_country,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

      return FALSE;
END UPDATE_ALL_LOCATION_BRACKETS;
------------------------------------------------------------------------------
FUNCTION UPDATE_LOCATION_COST(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item               IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ITEM%TYPE,
                              I_supplier           IN       ITEM_SUPP_COUNTRY_BRACKET_COST.SUPPLIER%TYPE,
                              I_origin_country     IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ORIGIN_COUNTRY_ID%TYPE,
                              I_location           IN       ITEM_SUPP_COUNTRY_BRACKET_COST.LOCATION%TYPE,
                              I_process_children   IN       VARCHAR2)
RETURN BOOLEAN IS

   L_program        VARCHAR2(60)  := 'ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST';
   L_table          VARCHAR2(30)  := 'ITEM_SUPP_COUNTRY_BRACKET_COST';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   L_bracket_cost   ITEM_SUPP_COUNTRY_BRACKET_COST.UNIT_COST%TYPE;
   L_location_cost  ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE;
   L_rowid          ROWID;

   cursor C_UPDATE_COST is
      select unit_cost
        from item_supp_country_bracket_cost
       where item                = I_item
         and supplier            = I_supplier
         and origin_country_id   = I_origin_country
         and location            = I_location
         and default_bracket_ind = 'Y';

   cursor C_LOCK_ISCL is
      select unit_cost,
             rowid
        from item_supp_country_loc
       where item                = I_item
         and supplier            = I_supplier
         and origin_country_id   = I_origin_country
         and loc                 = I_location
         for update nowait;

   cursor C_GET_CHILDREN is
      select im.item
        from item_master im,
             item_supp_country_bracket_cost iscbc
       where iscbc.supplier          = I_supplier
         and iscbc.origin_country_id = I_origin_country
         and iscbc.location          = I_location
         and (im.item_parent         = I_item or
              im.item_grandparent    = I_item)
         and im.item_level          <= im.tran_level
         and iscbc.item              = im.item;

BEGIN
   if I_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_supplier',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_origin_country is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_origin_country',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_location is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_location',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_UPDATE_COST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   open C_UPDATE_COST;

   SQL_LIB.SET_MARK('FETCH','C_UPDATE_COST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   fetch C_UPDATE_COST into L_bracket_cost;

   SQL_LIB.SET_MARK('CLOSE','C_UPDATE_COST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   close C_UPDATE_COST;

   SQL_LIB.SET_MARK('OPEN','C_LOCK_ISCL','ITEM_SUPP_COUNTRY_LOC', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   open C_LOCK_ISCL;

   SQL_LIB.SET_MARK('FETCH','C_LOCK_ISCL','ITEM_SUPP_COUNTRY_LOC', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   fetch C_LOCK_ISCL into L_location_cost,
                          L_rowid;

   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISCL','ITEM_SUPP_COUNTRY_LOC', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   close C_LOCK_ISCL;

   SQL_LIB.SET_MARK('UPDATE','ITEM_SUPP_COUNTRY_LOC', NULL, 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                       || 'Location: '|| to_char(I_location));

   if L_bracket_cost != L_location_cost then
      update item_supp_country_loc
         set unit_cost            = L_bracket_cost,
             last_update_id       = user,
             last_update_datetime = sysdate
       where rowid                = L_rowid;

      --- 'N'o is passed into the CHANGE_COST function for processing children because this
      --- function will call CHANGE_COST by child item if processing children is 'Y'es.
      if not UPDATE_BASE_COST.CHANGE_COST(O_error_message,
                                          I_item,
                                          I_supplier,
                                          I_origin_country,
                                          I_location,
                                          'N', ---I_process_children_ind
                                          'N', /*update child cost*/
                                          NULL /* Cost Change Number */ ) then
         return FALSE;
      end if;
   end if;

   if I_process_children = 'Y' then

      FOR rec in C_GET_CHILDREN LOOP
         --- if the item is a parent, then recall this function for each child item.
         if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                           rec.item,
                                                           I_supplier,
                                                           I_origin_country,
                                                           I_location,
                                                           'N') then
            return FALSE;
         end if;
      END LOOP;
   end if;
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'Item: '||I_item ||', Supplier : '||to_char(I_supplier) ||',
                                             Origin Country: '||I_origin_country||', Location: '||I_location,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

      return FALSE;
END UPDATE_LOCATION_COST;
----------------------------------------------------------------------------------------
FUNCTION MC_UPDATE_LOCATIONS(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_item               IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ITEM%TYPE,
                             I_supplier           IN       ITEM_SUPP_COUNTRY_BRACKET_COST.SUPPLIER%TYPE,
                             I_origin_country     IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ORIGIN_COUNTRY_ID%TYPE,
                             I_location           IN       ITEM_SUPP_COUNTRY_BRACKET_COST.LOCATION%TYPE,
                             I_process_children   IN       VARCHAR2)
RETURN BOOLEAN IS

   L_program        VARCHAR2(60)  := 'ITEM_BRACKET_COST_SQL.MC_UPDATE_LOCATIONS';
   L_table          VARCHAR2(30)   := 'ITEM_SUPP_COUNTRY_BRACKET_COST';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   L_bracket_value  ITEM_SUPP_COUNTRY_BRACKET_COST.BRACKET_VALUE1%TYPE;

   cursor C_UPDATE_COST is
      select bracket_value1,
             unit_cost
        from item_supp_country_bracket_cost
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country
         and location          = I_location;

   cursor C_LOCK_ISCBC is
      select 'X'
        from item_supp_country_bracket_cost iscbc,
             wh wh1,
             wh wh2
       where item               = I_item
         and supplier           = I_supplier
         and origin_country_id  = I_origin_country
         and bracket_value1     = L_bracket_value
         and wh1.wh             = I_location
         and wh1.physical_wh    = wh2.physical_wh
         and iscbc.location     = wh2.wh
         and wh2.wh            != I_location
         for update of iscbc.item nowait;

   cursor C_UPDATE_VIRTUAL_LOCS is
      select wh2.wh wh
        from item_supp_country_bracket_cost iscbc,
             wh wh1,
             wh wh2
       where item               = I_item
         and supplier           = I_supplier
         and origin_country_id  = I_origin_country
         and wh1.wh             = I_location
         and wh1.physical_wh    = wh2.physical_wh
         and iscbc.location     = wh2.wh;

   cursor C_GET_CHILDREN is
      select im.item
        from item_master im,
             item_supp_country_bracket_cost iscbc
       where iscbc.supplier          = I_supplier
         and iscbc.origin_country_id = I_origin_country
         and iscbc.location          = I_location
         and (im.item_parent         = I_item or
              im.item_grandparent    = I_item)
         and im.item_level          <= im.tran_level
         and iscbc.item              = im.item;

BEGIN
   if I_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_supplier',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_origin_country is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_origin_country',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   --- retrieve the cost for each bracket for the passed in virtual warehouse
   --- then update all other virtual warehouses in the same physical warehouse
   --- for the virtual warehouse passed in.
   FOR rec in C_UPDATE_COST LOOP
      L_bracket_value := rec.bracket_value1;

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country));
      open C_LOCK_ISCBC;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country));
      close C_LOCK_ISCBC;

      SQL_LIB.SET_MARK('UPDATE','ITEM_SUPP_COUNTRY_BRACKET_COST', NULL, 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country));

      update item_supp_country_bracket_cost
         set unit_cost = rec.unit_cost
       where item               = I_item
         and supplier           = I_supplier
         and origin_country_id  = I_origin_country
         and bracket_value1     = L_bracket_value
         and location in (select wh2.wh
                            from item_supp_country_bracket_cost iscbc,
                                wh wh1,
                                wh wh2
                           where item               = I_item
                             and supplier           = I_supplier
                             and origin_country_id  = I_origin_country
                             and wh1.wh             = I_location
                             and wh1.physical_wh    = wh2.physical_wh
                             and iscbc.location     = wh2.wh
                             and wh2.wh            != I_location);
   END LOOP;

   --- Update the item/supplier/country/location record for each virtual warehouse
   FOR rec in C_UPDATE_VIRTUAL_LOCS LOOP
      --- 'N'o is passed into the UPDATE_LOCATION_COST function for processing children because this
      --- function will call UPDATE_LOCATION_COST by child item if processing children is 'Y'es.
      if not ITEM_BRACKET_COST_SQL.UPDATE_LOCATION_COST(O_error_message,
                                                        I_item,
                                                        I_supplier,
                                                        I_origin_country,
                                                        rec.wh,
                                                        'N') then
         return FALSE;
      end if;
   END LOOP;

   --- if the item is a parent, then recursively call this function for each child item.
   if I_process_children = 'Y' then
      FOR rec in C_GET_CHILDREN LOOP
         if not ITEM_BRACKET_COST_SQL.MC_UPDATE_LOCATIONS(O_error_message,
                                                          rec.item,
                                                          I_supplier,
                                                          I_origin_country,
                                                          I_location,
                                                          'N') then
            return FALSE;
         end if;
      END LOOP;
   end if;
return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'Item: '||I_item ||', Supplier : '||to_char(I_supplier) ||',
                                             Origin Country: '||I_origin_country||', Location: '||I_location,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

      return FALSE;
END MC_UPDATE_LOCATIONS;
------------------------------------------------------------------------------
FUNCTION UPDATE_CHILDREN(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         I_item             IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ITEM%TYPE,
                         I_supplier         IN       ITEM_SUPP_COUNTRY_BRACKET_COST.SUPPLIER%TYPE,
                         I_origin_country   IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ORIGIN_COUNTRY_ID%TYPE,
                         I_location         IN       ITEM_SUPP_COUNTRY_BRACKET_COST.LOCATION%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(60)  := 'ITEM_BRACKET_COST_SQL.UPDATE_CHILDREN';
   L_table          VARCHAR2(30)  := 'ITEM_SUPP_COUNTRY_BRACKET_COST';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   L_bracket_value   ITEM_SUPP_COUNTRY_BRACKET_COST.BRACKET_VALUE1%TYPE;

   cursor C_UPDATE_CHILD_COST is
      select bracket_value1,
             unit_cost
        from item_supp_country_bracket_cost
       where item                = I_item
         and supplier            = I_supplier
         and origin_country_id   = I_origin_country
         and (location           = I_location
             or (location is NULL and I_location is NULL));

   cursor C_LOCK_ISCBC is
      select 'x'
        from item_supp_country_bracket_cost iscbc,
             item_master im
       where supplier             = I_supplier
         and origin_country_id    = I_origin_country
         and (location            = I_location
             or (location is NULL and I_location is NULL))
         and bracket_value1       = L_bracket_value
         and (im.item_parent      = I_item or
              im.item_grandparent = I_item)
         and im.item_level       <= im.tran_level
         and iscbc.item           = im.item
         for update of iscbc.item nowait;

BEGIN
   if I_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_supplier',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_origin_country is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_origin_country',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   --- update all the child records cost to the parent for each bracket.
   FOR rec in C_UPDATE_CHILD_COST LOOP
      L_bracket_value := rec.bracket_value1;

      SQL_LIB.SET_MARK('OPEN','C_LOCK_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                       || 'Location: '|| to_char(I_location));
      open C_LOCK_ISCBC;

      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ISCBC','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                       || 'Location: '|| to_char(I_location));
      close C_LOCK_ISCBC;

      SQL_LIB.SET_MARK('UPDATE','ITEM_SUPP_COUNTRY_BRACKET_COST', NULL, 'Item: '|| (I_item)
                       || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                       || 'Location: '|| to_char(I_location));

      update item_supp_country_bracket_cost iscbc
         set unit_cost = rec.unit_cost
       where supplier            = I_supplier
         and origin_country_id   = I_origin_country
         and (location           = I_location
             or (location is NULL and I_location is NULL))
         and bracket_value1      = L_bracket_value
         and exists (select 'x'
                       from item_master im
                      where (im.item_parent      = I_item or
                             im.item_grandparent = I_item)
                        and im.item_level       <= im.tran_level
                        and iscbc.item           = im.item);
   END LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             'Item: '||I_item ||', Supplier : '||to_char(I_supplier) ||',
                                             Origin Country: '||I_origin_country||', Location: '||I_location,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

      return FALSE;
END UPDATE_CHILDREN;
----------------------------------------------------------------------------------------
FUNCTION BRACKETS_EXIST(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        O_exists           IN OUT   BOOLEAN,
                        I_item             IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ITEM%TYPE,
                        I_supplier         IN       ITEM_SUPP_COUNTRY_BRACKET_COST.SUPPLIER%TYPE,
                        I_origin_country   IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ORIGIN_COUNTRY_ID%TYPE,
                        I_location         IN       ITEM_SUPP_COUNTRY_BRACKET_COST.LOCATION%TYPE)
RETURN BOOLEAN IS
   L_program    VARCHAR2(60)  := 'ITEM_BRACKET_COST_SQL.BRACKETS_EXIST';
   L_dummy      VARCHAR2(1);

   cursor C_EXIST is
      select 'X'
        from item_supp_country_bracket_cost
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country
         and (location         = I_location
             or (location is NULL and I_location is NULL));

BEGIN
   if I_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_supplier',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_origin_country is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_origin_country',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   O_exists := FALSE;

   SQL_LIB.SET_MARK('OPEN','C_EXIST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   open C_EXIST;

   SQL_LIB.SET_MARK('FETCH','C_EXIST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   fetch C_EXIST into L_dummy;
   if C_EXIST%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_EXIST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   close C_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

      return FALSE;
END BRACKETS_EXIST;
----------------------------------------------------------------------------------------
FUNCTION CREATE_BRACKET(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        I_item             IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ITEM%TYPE,
                        I_supplier         IN       ITEM_SUPP_COUNTRY_BRACKET_COST.SUPPLIER%TYPE,
                        I_origin_country   IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ORIGIN_COUNTRY_ID%TYPE,
                        I_location         IN       ITEM_SUPP_COUNTRY_BRACKET_COST.LOCATION%TYPE,
                        I_all_locs         IN       VARCHAR2)
RETURN BOOLEAN IS
   L_program       VARCHAR2(60)  := 'ITEM_BRACKET_COST_SQL.CREATE_BRACKET';
   L_dummy         VARCHAR2(1);
   L_pack_ind      ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind  ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type     ITEM_MASTER.PACK_TYPE%TYPE;
   L_dept          ITEM_MASTER.DEPT%TYPE;
   L_class         ITEM_MASTER.CLASS%TYPE;
   L_subclass      ITEM_MASTER.SUBCLASS%TYPE;
   L_bracket_level VARCHAR2(3);
   L_exists        BOOLEAN;
   L_mc_ind        SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;

   cursor C_GET_SUPP_COUNTRY is
      select supplier,
             origin_country_id
        from item_supp_country
       where item              = I_item
         and supplier          = nvl(I_supplier, supplier)
         and origin_country_id = nvl(I_origin_country, origin_country_id);

   cursor C_GET_MC_LOC is
     select wh2.wh loc
        from wh wh1,
              wh wh2
       where wh1.wh          = I_location
         and wh1.physical_wh = wh2.physical_wh
         and EXISTS (select 'x'
                       from item_supp_country_bracket_cost iscbc
                      where iscbc.location = wh2.wh
                        and iscbc.location != I_location);


   L_mc_loc     C_GET_MC_LOC%ROWTYPE;
BEGIN
   if I_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;
   --- Check if the item is a buyer pack.  If it is,
   --- no records will be created as buyer packs do
   --- have bracket costing records.
   ---
   if not ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                        L_pack_ind,
                                        L_sellable_ind,
                                        L_orderable_ind,
                                        L_pack_type,
                                        I_item) then
      return FALSE;
   end if;

   if L_pack_ind = 'Y' and L_pack_type = 'B' then
      return TRUE;
   end if;

   if not ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                         I_item,
                                         L_dept,
                                         L_class,
                                         L_subclass) then
      return FALSE;
   end if;


   --- Get all the supplier/country combinations for the item
   --- to create brackets
   FOR rec in C_GET_SUPP_COUNTRY LOOP

      if not SUP_INV_MGMT_SQL.GET_INV_MGMT_LEVEL(O_error_message,
                                                 L_bracket_level,
                                                 rec.supplier) then
         return FALSE;
      end if;

      if I_location is NULL and (I_all_locs is NULL or I_all_locs = 'N') then
         if L_bracket_level in ('S', 'D') then
            --- check if brackets have been created yet.  If not, create them
            if not BRACKETS_EXIST(O_error_message,
                                  L_exists,
                                  I_item,
                                  rec.supplier,
                                  rec.origin_country_id,
                                  NULL) then
               return FALSE;
            end if;
            if L_exists = FALSE then
            --- Insert a record at the country level using either the
            --- supplier or supplier/dept bracket
               insert into item_supp_country_bracket_cost(item,
                                                          supplier,
                                                          origin_country_id,
                                                          location,
                                                          loc_type,
                                                          default_bracket_ind,
                                                          bracket_value1,
                                                          unit_cost,
                                                          bracket_value2,
                                                          sup_dept_seq_no)
                                                   select I_item,
                                                          rec.supplier,
                                                          rec.origin_country_id,
                                                          NULL,
                                                          NULL,
                                                          sbc.default_bracket_ind,
                                                          sbc.bracket_value1,
                                                          isc.unit_cost,
                                                          sbc.bracket_value2,
                                                          sbc.sup_dept_seq_no
                                                     from item_supp_country isc,
                                                          sup_bracket_cost sbc
                                                    where isc.item              = I_item
                                                      and isc.supplier          = rec.supplier
                                                      and isc.origin_country_id = rec.origin_country_id
                                                      and isc.supplier          = sbc.supplier
                                                      and sbc.dept              = L_dept;
               if SQL%NOTFOUND then
                  insert into item_supp_country_bracket_cost(item,
                                                             supplier,
                                                             origin_country_id,
                                                             location,
                                                             loc_type,
                                                             default_bracket_ind,
                                                             bracket_value1,
                                                             unit_cost,
                                                             bracket_value2,
                                                             sup_dept_seq_no)
                                                      select I_item,
                                                             rec.supplier,
                                                             rec.origin_country_id,
                                                             NULL,
                                                             NULL,
                                                             sbc.default_bracket_ind,
                                                             sbc.bracket_value1,
                                                             isc.unit_cost,
                                                             sbc.bracket_value2,
                                                             sbc.sup_dept_seq_no
                                                        from item_supp_country isc,
                                                             sup_bracket_cost sbc
                                                       where isc.item              = I_item
                                                         and isc.supplier          = rec.supplier
                                                         and isc.origin_country_id = rec.origin_country_id
                                                         and isc.supplier          = sbc.supplier
                                                         and sbc.dept is NULL;
               end if; -- SQL notfound
            end if; -- L_exists is FALSE
         end if; -- bracket level

         return TRUE;

      end if;

      if L_bracket_level in ('S', 'D') then
      --- use country bracket cost records for the passed in location or
      --- all location brackets
         insert into item_supp_country_bracket_cost(
                     item,
                     supplier,
                     origin_country_id,
                     location,
                     loc_type,
                     default_bracket_ind,
                     bracket_value1,
                     unit_cost,
                     bracket_value2,
                     sup_dept_seq_no)
              select I_item,
                     rec.supplier,
                     rec.origin_country_id,
                     nvl(I_location, iscl.loc),
                     'W',
                     iscbc.default_bracket_ind,
                     iscbc.bracket_value1,
                     iscbc.unit_cost,
                     iscbc.bracket_value2,
                     iscbc.sup_dept_seq_no
                from item_supp_country_bracket_cost iscbc,
                     item_supp_country_loc iscl
               where iscbc.item = I_item
                 and iscbc.supplier          = rec.supplier
                 and iscbc.origin_country_id = rec.origin_country_id
                 and iscbc.location is NULL
                 and iscbc.item              = iscl.item
                 and iscbc.supplier          = iscl.supplier
                 and iscbc.origin_country_id = iscl.origin_country_id
                 and iscl.loc                = nvl(I_location, iscl.loc)
                 and iscl.loc_type           = 'W'
                 and not exists(
                   select 'x'
                     from item_supp_country_bracket_cost iscbc2
                    where iscbc2.item              = I_item
                      and iscbc2.supplier          = rec.supplier
                      and iscbc2.origin_country_id = rec.origin_country_id
                      and iscbc2.location          = nvl(I_location, iscl.loc)
                      and iscbc2.bracket_value1    = iscbc.bracket_value1
                      and rownum = 1 );
         if SQL%NOTFOUND then
         --- No item/supplier/country bracket record exists.
         --- use supplier/dept bracket structure and location cost for
         --- all brackets.
            insert into item_supp_country_bracket_cost(
                       item,
                       supplier,
                       origin_country_id,
                       location,
                       loc_type,
                       default_bracket_ind,
                       bracket_value1,
                       unit_cost,
                       bracket_value2,
                       sup_dept_seq_no)
                select I_item,
                       rec.supplier,
                       rec.origin_country_id,
                       nvl(I_location, iscl.loc),
                       'W',
                       sbc.default_bracket_ind,
                       sbc.bracket_value1,
                       iscl.unit_cost,
                       sbc.bracket_value2,
                       sbc.sup_dept_seq_no
                  from item_supp_country_loc iscl,
                       sup_bracket_cost sbc
                 where iscl.item              = I_item
                   and iscl.supplier          = rec.supplier
                   and iscl.origin_country_id = rec.origin_country_id
                   and iscl.loc               = nvl(I_location, iscl.loc)
                   and iscl.loc_type          = 'W'
                   and iscl.supplier          = sbc.supplier
                   and sbc.dept               = L_dept
                   and not exists(
                     select 'x'
                       from item_supp_country_bracket_cost iscbc2
                      where iscbc2.item              = I_item
                        and iscbc2.supplier          = rec.supplier
                        and iscbc2.origin_country_id = rec.origin_country_id
                        and iscbc2.location          = nvl(I_location,iscl.loc)
                        and iscbc2.bracket_value1    = sbc.bracket_value1
                        and rownum = 1 );
            if SQL%NOTFOUND then
            --- No record exists for the supplier/dept for the item's dept or
            --- only brackets exist at supplier level.  In either case, use
            --- sup level bracket, location cost
               insert into item_supp_country_bracket_cost(
                       item,
                       supplier,
                       origin_country_id,
                       location,
                       loc_type,
                       default_bracket_ind,
                       bracket_value1,
                       unit_cost,
                       bracket_value2,
                       sup_dept_seq_no)
                select I_item,
                       rec.supplier,
                       rec.origin_country_id,
                       nvl(I_location, iscl.loc),
                       'W',
                       sbc.default_bracket_ind,
                       sbc.bracket_value1,
                       iscl.unit_cost,
                       sbc.bracket_value2,
                       sbc.sup_dept_seq_no
                  from item_supp_country_loc iscl,
                       sup_bracket_cost sbc
                 where iscl.item              = I_item
                   and iscl.supplier          = rec.supplier
                   and iscl.origin_country_id = rec.origin_country_id
                   and iscl.loc               = nvl(I_location, iscl.loc)
                   and iscl.loc_type          = 'W'
                   and iscl.supplier          = sbc.supplier
                   and sbc.dept is NULL
                   and not exists(
                     select 'x'
                       from item_supp_country_bracket_cost iscbc2
                      where iscbc2.item              = I_item
                        and iscbc2.supplier          = rec.supplier
                        and iscbc2.origin_country_id = rec.origin_country_id
                        and iscbc2.location          = nvl(I_location,iscl.loc)
                        and iscbc2.bracket_value1    = sbc.bracket_value1
                        and rownum = 1 );
            end if;
         end if;
      elsif L_bracket_level in ('L', 'A') then
      --- use location bracket structure, location level cost for all brackets
         insert into item_supp_country_bracket_cost(
                       item,
                       supplier,
                       origin_country_id,
                       location,
                       loc_type,
                       default_bracket_ind,
                       bracket_value1,
                       unit_cost,
                       bracket_value2,
                       sup_dept_seq_no)
                select I_item,
                       rec.supplier,
                       rec.origin_country_id,
                       nvl(I_location, iscl.loc),
                       'W',
                       sbc.default_bracket_ind,
                       sbc.bracket_value1,
                       iscl.unit_cost,
                       sbc.bracket_value2,
                       sbc.sup_dept_seq_no
                  from item_supp_country_loc iscl,
                       sup_bracket_cost sbc,
                       wh
                 where iscl.item              = I_item
                   and iscl.supplier          = rec.supplier
                   and iscl.origin_country_id = rec.origin_country_id
                   and iscl.loc               = nvl(I_location, iscl.loc)
                   and iscl.loc_type          = 'W'
                   and iscl.supplier          = sbc.supplier
                   and iscl.loc               = wh.wh
                   and wh.physical_wh         = sbc.location
                   and ((sbc.dept = L_dept and L_bracket_level = 'A') or
                        (sbc.dept is NULL and L_bracket_level = 'L'))
                   and not exists(
                     select 'x'
                       from item_supp_country_bracket_cost iscbc2
                      where iscbc2.item              = I_item
                        and iscbc2.supplier          = rec.supplier
                        and iscbc2.origin_country_id = rec.origin_country_id
                        and iscbc2.location          = nvl(I_location,iscl.loc)
                        and iscbc2.bracket_value1    = sbc.bracket_value1
                        and rownum = 1 );
         --- create all location structures for locations with no location
         --- bracket structure for the passed in location, use higher level
         --- structure (supplier or supplier/dept)and location level cost for
         --- all brackets
         insert into item_supp_country_bracket_cost(
                       item,
                       supplier,
                       origin_country_id,
                       location,
                       loc_type,
                       default_bracket_ind,
                       bracket_value1,
                       unit_cost,
                       bracket_value2,
                       sup_dept_seq_no)
                select I_item,
                       rec.supplier,
                       rec.origin_country_id,
                       nvl(I_location, iscl.loc),
                       'W',
                       sbc.default_bracket_ind,
                       sbc.bracket_value1,
                       iscl.unit_cost,
                       sbc.bracket_value2,
                       sbc.sup_dept_seq_no
                  from item_supp_country_loc iscl,
                       sup_bracket_cost sbc
                 where iscl.item              = I_item
                   and iscl.supplier          = rec.supplier
                   and iscl.origin_country_id = rec.origin_country_id
                   and iscl.loc               = nvl(I_location, iscl.loc)
                   and iscl.loc_type          = 'W'
                   and iscl.supplier          = sbc.supplier
                   and sbc.location is NULL
                   and ((sbc.dept = L_dept and L_bracket_level = 'A') or
                        (sbc.dept is NULL and L_bracket_level = 'L'))
                   and not exists (
                     select 'x'
                       from sup_bracket_cost s,
                            wh
                      where s.supplier = sbc.supplier
                        and ((s.dept = sbc.dept and L_bracket_level = 'A') or
                             (s.dept is NULL and L_bracket_level = 'L'))
                        and iscl.loc       = wh.wh
                        and wh.physical_wh = s.location
                        and rownum = 1)
                   and not exists(
                     select 'x'
                       from item_supp_country_bracket_cost iscbc2
                      where iscbc2.item              = I_item
                        and iscbc2.supplier          = rec.supplier
                        and iscbc2.origin_country_id = rec.origin_country_id
                        and iscbc2.location          = nvl(I_location,iscl.loc)
                        and iscbc2.bracket_value1    = sbc.bracket_value1
                        and rownum = 1 );
         if SQL%NOTFOUND then
         --- if no records are inserted for a supplier/department, then a
         --- supplier/department/location bracket exists but no
         --- supplier/department.  Need to use the supplier level bracket.
            insert into item_supp_country_bracket_cost(item,
                       supplier,
                       origin_country_id,
                       location,
                       loc_type,
                       default_bracket_ind,
                       bracket_value1,
                       unit_cost,
                       bracket_value2,
                       sup_dept_seq_no)
                select I_item,
                       rec.supplier,
                       rec.origin_country_id,
                       nvl(I_location, iscl.loc),
                       'W',
                       sbc.default_bracket_ind,
                       sbc.bracket_value1,
                       iscl.unit_cost,
                       sbc.bracket_value2,
                       sbc.sup_dept_seq_no
                  from item_supp_country_loc iscl,
                       sup_bracket_cost sbc
                 where iscl.item              = I_item
                   and iscl.supplier          = rec.supplier
                   and iscl.origin_country_id = rec.origin_country_id
                   and iscl.loc               = nvl(I_location, iscl.loc)
                   and iscl.loc_type          = 'W'
                   and iscl.supplier          = sbc.supplier
                   and sbc.location is NULL
                   and (sbc.dept is NULL and L_bracket_level = 'A')
                   and not exists (
                     select 'x'
                       from sup_bracket_cost s,
                            wh
                      where s.supplier     = sbc.supplier
                        and (s.dept = L_dept and L_bracket_level = 'A')
                        and iscl.loc       = wh.wh
                        and wh.physical_wh = s.location
                        and rownum = 1)
                   and not exists(
                     select 'x'
                       from item_supp_country_bracket_cost iscbc2
                      where iscbc2.item              = I_item
                        and iscbc2.supplier          = rec.supplier
                        and iscbc2.origin_country_id = rec.origin_country_id
                        and iscbc2.location          = nvl(I_location,iscl.loc)
                        and iscbc2.bracket_value1    = sbc.bracket_value1
                        and rownum = 1 );
         end if;
      end if;

      -- In a multi-channel environment, a virtual warehouse may be
      -- added to an item after an existing virtual warehouse in the
      -- same physical warehouse has already been added.  In that instance
      -- the new virtual warehouse being added must have it's costs
      -- updated to the existing virtual warehouses already attached to
      -- the item.
      if I_location is not NULL then
         if not SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                        L_mc_ind) then
            return FALSE;
         end if;
         if L_mc_ind = 'Y' then
            open C_GET_MC_LOC;
            fetch C_GET_MC_LOC into L_mc_loc.loc;
            if C_GET_MC_LOC%FOUND then
               close C_GET_MC_LOC;
               if not ITEM_BRACKET_COST_SQL.MC_UPDATE_LOCATIONS(O_error_message,
                                                                I_item,
                                                                rec.supplier,
                                                                rec.origin_country_id,
                                                                L_mc_loc.loc,
                                                                'N'/*process children*/) then
                  return FALSE;
               end if;
            else
               close C_GET_MC_LOC;
            end if;
         end if;
      end if;
   END LOOP;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CREATE_BRACKET;
---------------------------------------------------------------------------------------
FUNCTION BRACKET_COST_EXISTS(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists           IN OUT   BOOLEAN,
                             I_item             IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ITEM%TYPE,
                             I_supplier         IN       ITEM_SUPP_COUNTRY_BRACKET_COST.SUPPLIER%TYPE,
                             I_origin_country   IN       ITEM_SUPP_COUNTRY_BRACKET_COST.ORIGIN_COUNTRY_ID%TYPE,
                             I_location         IN       ITEM_SUPP_COUNTRY_BRACKET_COST.LOCATION%TYPE)
RETURN BOOLEAN IS
   L_program    VARCHAR2(60)  := 'ITEM_BRACKET_COST_SQL.BRACKET_COST_EXISTS';
   L_dummy      VARCHAR2(1);

   cursor C_EXIST is
      select 'X'
        from item_supp_country_bracket_cost
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_country
         and (location         = I_location
             or (location is NULL and I_location is NULL))
         and nvl(unit_cost, 0) = 0;

BEGIN
   if I_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_supplier is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_supplier',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_origin_country is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_origin_country',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   O_exists := FALSE;

   SQL_LIB.SET_MARK('OPEN','C_EXIST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   open C_EXIST;

   SQL_LIB.SET_MARK('FETCH','C_EXIST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   fetch C_EXIST into L_dummy;
   if C_EXIST%FOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_EXIST','ITEM_SUPP_COUNTRY_BRACKET_COST', 'Item: '|| (I_item)
                    || 'Supplier: '|| to_char(I_supplier) || 'Country: '|| (I_origin_country)
                    || 'Location: '|| to_char(I_location));
   close C_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

      return FALSE;
END BRACKET_COST_EXISTS;
-----------------------------------------------------------------------------
FUNCTION SUPP_BRACKET_EXISTS(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists           IN OUT   BOOLEAN,
                             I_supplier         IN       SUP_BRACKET_COST.SUPPLIER%TYPE,
                             I_origin_country   IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                             I_dept             IN       SUP_BRACKET_COST.DEPT%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(60)  := 'ITEM_BRACKET_COST_SQL.SUPP_BRACKET_EXISTS';
   L_dummy      VARCHAR2(1);

   cursor C_EXIST is
       select 'x'
         from item_supp_country isc,
              sup_bracket_cost sbc
        where isc.supplier           = I_supplier
          and isc.origin_country_id  = I_origin_country
          and isc.supplier           = sbc.supplier
          and (sbc.dept              = I_dept or
               sbc.dept is NULL)
          and rownum                 = 1;

BEGIN

   O_exists := FALSE;

   SQL_LIB.SET_MARK('OPEN',
                    'C_EXIST',
                    'ITEM_SUPP_COUNTRY',
                    'Supplier: '|| to_char(I_supplier)|| 'Country: '|| (I_origin_country) || 'Dept: '|| to_char(I_dept));
   open C_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXIST',
                    'ITEM_SUPP_COUNTRY',
                    'Supplier: '|| to_char(I_supplier)|| 'Country: '|| (I_origin_country) || 'Dept: '|| to_char(I_dept));
   fetch C_EXIST into L_dummy;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXIST',
                    'ITEM_SUPP_COUNTRY',
                    'Supplier: '|| to_char(I_supplier)|| 'Country: '|| (I_origin_country) || 'Dept: '|| to_char(I_dept));
   close C_EXIST;

   if L_dummy = 'x' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

      return FALSE;
END SUPP_BRACKET_EXISTS;
---------------------------------------------------------------------------------------
END ITEM_BRACKET_COST_SQL;
/

