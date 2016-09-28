CREATE OR REPLACE PACKAGE BODY CLOSE_SQL AS
-----------------------------------------------------------------------------------------
LP_multichannel_ind   SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;
-----------------------------------------------------------------------------------------
FUNCTION LOC_CLOSING_EXISTS(O_error_message  IN OUT  VARCHAR2,
                            O_exists         IN OUT  BOOLEAN,
                            I_location       IN      LOCATION_CLOSED.LOCATION%TYPE,
                            I_close_date     IN      LOCATION_CLOSED.CLOSE_DATE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_exists   VARCHAR2(1)  := 'N';
   L_program  VARCHAR2(64) := 'CLOSE_SQL.LOC_CLOSING_EXISTS';

   cursor C_EXIST is
      select 'Y'
        from location_closed
       where location   = I_location
         and close_date = I_close_date;

BEGIN
   if I_location is NULL or I_close_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   else
      SQL_LIB.SET_MARK('OPEN','C_EXIST','LOCATION_CLOSED','Location: '||to_char(I_location)||
                                                         ' Close Date: '||to_char(I_close_date));
      open C_EXIST;
      SQL_LIB.SET_MARK('FETCH','C_EXIST','LOCATION_CLOSED','Location: '||to_char(I_location)||
                                                          ' Close Date: '||to_char(I_close_date));
      fetch C_EXIST into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_EXIST','LOCATION_CLOSED','Location: '||to_char(I_location)||
                                                          ' Close Date: '||to_char(I_close_date));
      close C_EXIST;
      ---
      if L_exists = 'Y' then
         O_exists := TRUE;
      else
         O_exists := FALSE;
     end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.LOC_CLOSING_EXISTS',
                                            NULL);
      return FALSE;
END LOC_CLOSING_EXISTS;
--------------------------------------------------------------------------------------------
FUNCTION CO_CLOSING_EXISTS(O_error_message  IN OUT  VARCHAR2,
                           O_exists         IN OUT  BOOLEAN,
                           I_close_date     IN      COMPANY_CLOSED.CLOSE_DATE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_exists   VARCHAR2(1)  := 'N';
   L_program  VARCHAR2(64) := 'CLOSE_SQL.CO_CLOSING_EXISTS';

   cursor C_EXIST is
      select 'Y'
        from company_closed
       where close_date = I_close_date;

BEGIN
   if I_close_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   else
      SQL_LIB.SET_MARK('OPEN','C_EXIST','COMPANY_CLOSED',' Close Date: '||to_char(I_close_date));
      open C_EXIST;
      SQL_LIB.SET_MARK('FETCH','C_EXIST','COMPANY_CLOSED',' Close Date: '||to_char(I_close_date));
      fetch C_EXIST into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_EXIST','COMPANY_CLOSED',' Close Date: '||to_char(I_close_date));
      close C_EXIST;
      ---
      if L_exists = 'Y' then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.CO_CLOSING_EXISTS',
                                            NULL);
      return FALSE;
END CO_CLOSING_EXISTS;
--------------------------------------------------------------------------------------------
FUNCTION EXCEPT_EXISTS(O_error_message  IN OUT  VARCHAR2,
                       O_exists         IN OUT  BOOLEAN,
                       I_location       IN      COMPANY_CLOSED_EXCEP.LOCATION%TYPE,
                       I_close_date     IN      COMPANY_CLOSED_EXCEP.CLOSE_DATE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_exists   VARCHAR2(1)  := 'N';
   L_program  VARCHAR2(64) := 'CLOSE_SQL.EXCEPT_EXISTS';

   cursor C_EXIST is
      select 'Y'
        from company_closed_excep
       where location   = NVL(I_location, location)
         and close_date = I_close_date;

BEGIN
   if I_close_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   else
      SQL_LIB.SET_MARK('OPEN','C_EXIST','COMPANY_CLOSED_EXCEP','Location: '||to_char(I_location)||
                                                           ' Close Date: '||to_char(I_close_date));
      open C_EXIST;
      SQL_LIB.SET_MARK('FETCH','C_EXIST','COMPANY_CLOSED_EXCEP','Location: '||to_char(I_location)||
                                                            ' Close Date: '||to_char(I_close_date));
      fetch C_EXIST into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_EXIST','COMPANY_CLOSED_EXCEP','Location: '||to_char(I_location)||
                                                            ' Close Date: '||to_char(I_close_date));
      close C_EXIST;
      ---
      if L_exists = 'Y' then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.EXCEPT_EXISTS',
                                            NULL);
      return FALSE;
END EXCEPT_EXISTS;
--------------------------------------------------------------------------------------------
FUNCTION LOCK_EXCEP(O_error_message  IN OUT  VARCHAR2,
                    I_close_date     IN      COMPANY_CLOSED_EXCEP.CLOSE_DATE%TYPE)
   RETURN BOOLEAN IS

   L_table         VARCHAR2(30) := 'COMPANY_CLOSED_EXCEP';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_EXCEP is
      select 'x'
        from company_closed_excep
       where close_date = I_close_date
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_EXCEP','COMPANY_CLOSED_EXCEP','CLOSE DATE: '||to_char(I_close_date));
   open C_LOCK_EXCEP;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_EXCEP','COMPANY_CLOSED_EXCEP','CLOSE DATE: '||to_char(I_close_date));
   close C_LOCK_EXCEP;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_close_date),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.LOCK_EXCEP',
                                            NULL);
      return FALSE;
END LOCK_EXCEP;
--------------------------------------------------------------------------------------------
FUNCTION DELETE_EXCEP(O_error_message  IN OUT  VARCHAR2,
                      I_close_date     IN      COMPANY_CLOSED_EXCEP.CLOSE_DATE%TYPE)
   RETURN BOOLEAN IS

BEGIN
   SQL_LIB.SET_MARK('DELETE', NULL,'COMPANY_CLOSED_EXCEP','Close Date: '||to_char(I_close_date));

   delete from company_closed_excep
         where close_date = I_close_date;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.DELETE_EXCEP',
                                            NULL);
      return FALSE;
END DELETE_EXCEP;
--------------------------------------------------------------------------------------------
FUNCTION APPLY_LOC_EXCEPS(O_error_message  IN OUT  VARCHAR2,
                          I_close_date     IN      COMPANY_CLOSED_EXCEP.CLOSE_DATE%TYPE,
                          I_group_type     IN      VARCHAR2,
                          I_group_value    IN      VARCHAR2,
                          I_recv_ind       IN      VARCHAR2,
                          I_sales_ind      IN      VARCHAR2,
                          I_ship_ind       IN      VARCHAR2)
   RETURN BOOLEAN IS

   QUICK_EXIT  EXCEPTION;

BEGIN
   if DELETE_LOC_EXCEPS(O_error_message,
                        I_close_date,
                        I_group_type,
                        I_group_value) = FALSE then
      raise QUICK_EXIT;
   end if;
   ---
   if INSERT_LOC_EXCEPS(O_error_message,
                        I_close_date,
                        I_group_type,
                        I_group_value,
                        I_recv_ind,
                        I_sales_ind,
                        I_ship_ind) = FALSE then
      raise QUICK_EXIT;
   end if;

   return TRUE;

EXCEPTION
   when QUICK_EXIT then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            O_error_message,
                                            'CLOSE_SQL.APPLY_LOC_EXCEPS',
                                            null);

      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.APPLY_LOC_EXCEPS',
                                            NULL);
      return FALSE;
END APPLY_LOC_EXCEPS;
--------------------------------------------------------------------------------------------
FUNCTION DELETE_LOC_EXCEPS(O_error_message  IN OUT  VARCHAR2,
                           I_close_date     IN      COMPANY_CLOSED_EXCEP.CLOSE_DATE%TYPE,
                           I_group_type     IN      VARCHAR2,
                           I_group_value    IN      VARCHAR2)
   RETURN BOOLEAN IS

   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);
   L_table        VARCHAR2(50) := 'COMPANY_CLOSED_EXCEP';

   cursor C_LOCK_STORE is
      select 'x'
        from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location   = to_number(I_group_value)
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_WH is
      select 'x'
        from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location   = to_number(I_group_value)
         and loc_type   = 'W'
         for update nowait;

   cursor C_LOCK_STORE_CLASS is
      select 'x'
       from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where store_class = I_group_value)
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_DISTRICT is
      select 'x'
       from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where district = to_number(I_group_value))
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_REGION is
      select 'x'
        from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where district in (select district
                                                from district
                                               where region = to_number(I_group_value)))
         and loc_type   = 'S'
         for update nowait;


   cursor C_LOCK_TRANS_ZONE is
      select 'x'
       from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where transfer_zone = to_number(I_group_value))
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_LOC_TRAIT is
      select 'x'
       from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from loc_traits_matrix
                           where loc_trait = to_number(I_group_value))
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_DEFAULT_WH is
      select 'x'
       from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where default_wh = to_number(I_group_value))
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_LOC_LIST_STORE is
      select 'x'
       from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select location
                            from loc_list_detail
                           where loc_list = to_number(I_group_value)
                             and loc_type = 'S')
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_LOC_LIST_WH is
      select 'x'
       from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select location
                            from loc_list_detail
                           where loc_list = to_number(I_group_value)
                             and loc_type = 'W')
         and loc_type   = 'W'
         for update nowait;

   cursor C_LOCK_ALL_STORE is
      select 'x'
        from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_ALL_WH is
      select 'x'
        from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and loc_type   = 'W'
         for update nowait;

BEGIN
   if I_group_type = 'S' then
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_STORE','COMPANY_CLOSED_EXCEP','Store: '||I_group_value);
      open C_LOCK_STORE;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_STORE','COMPANY_CLOSED_EXCEP','Store: '||I_group_value);
      close C_LOCK_STORE;

      SQL_LIB.SET_MARK('DELETE', NULL,'COMPANY_CLOSED_EXCEP','Store: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location   = to_number(I_group_value)
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'W' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_WH','COMPANY_CLOSED_EXCEP','Warehouse: '||I_group_value);
      open C_LOCK_WH;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_WH','COMPANY_CLOSED_EXCEP','Warehouse: '||I_group_value);
      close C_LOCK_WH;
      ---
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
         SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Warehouse: '||I_group_value);
         delete from company_closed_excep cce
          where close_date = NVL(I_close_date, close_date)
            and exists (select 'x'
                          from wh
                         where physical_wh      = to_number(I_group_value)
                           and wh.wh            = cce.location
                           and stockholding_ind = 'Y')
            and loc_type   = 'W';
      else
         SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Warehouse: '||I_group_value);
         delete from company_closed_excep
          where close_date = NVL(I_close_date, close_date)
            and location   = to_number(I_group_value)
            and loc_type   = 'W';
      end if;
   ---
   elsif I_group_type = 'C' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_STORE_CLASS','COMPANY_CLOSED_EXCEP','Store Class: '||I_group_value);
      open C_LOCK_STORE_CLASS;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_STORE_CLASS','COMPANY_CLOSED_EXCEP','Store Class: '||I_group_value);
      close C_LOCK_STORE_CLASS;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Store Class: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where store_class = I_group_value)
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'D' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DISTRICT','COMPANY_CLOSED_EXCEP','District: '||I_group_value);
      open C_LOCK_DISTRICT;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DISTRICT','COMPANY_CLOSED_EXCEP','District: '||I_group_value);
      close C_LOCK_DISTRICT;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','District: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where district = to_number(I_group_value))
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'R' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_REGION','COMPANY_CLOSED_EXCEP','Region: '||I_group_value);
      open C_LOCK_REGION;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_REGION','COMPANY_CLOSED_EXCEP','Region: '||I_group_value);
      close C_LOCK_REGION;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Region: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where district in (select district
                                                from district
                                               where region = to_number(I_group_value)))
         and loc_type   = 'S';
   ---
   ---
   elsif I_group_type = 'T' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_TRANS_ZONE','COMPANY_CLOSED_EXCEP','Transfer Zone: '||I_group_value);
      open C_LOCK_TRANS_ZONE;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_TRANS_ZONE','COMPANY_CLOSED_EXCEP','Transfer Zone: '||I_group_value);
      close C_LOCK_TRANS_ZONE;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Transfer Zone: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where transfer_zone = to_number(I_group_value))
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'L' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_LOC_TRAIT','COMPANY_CLOSED_EXCEP','Location trait: '||I_group_value);
      open C_LOCK_LOC_TRAIT;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_LOC_TRAIT','COMPANY_CLOSED_EXCEP','Location trait: '||I_group_value);
      close C_LOCK_LOC_TRAIT;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Location trait: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from loc_traits_matrix
                           where loc_trait = to_number(I_group_value))
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'DW' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DEFAULT_WH','COMPANY_CLOSED_EXCEP','Default WH: '||I_group_value);
      open C_LOCK_DEFAULT_WH;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEFAULT_WH','COMPANY_CLOSED_EXCEP','Default WH: '||I_group_value);
      close C_LOCK_DEFAULT_WH;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Default WH: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where default_wh = to_number(I_group_value))
         and loc_type   = 'S';

   ---
   elsif I_group_type = 'LLS' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_LOC_LIST_STORE','COMPANY_CLOSED_EXCEP','Location List Store: '||I_group_value);
      open C_LOCK_LOC_LIST_STORE;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_LOC_LIST_STORE','COMPANY_CLOSED_EXCEP','Location List Store: '||I_group_value);
      close C_LOCK_LOC_LIST_STORE;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Location List Store: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and location in (select location
                            from loc_list_detail
                           where loc_list = to_number(I_group_value)
                             and loc_type = 'S')
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'LLW' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_LOC_LIST_WH','COMPANY_CLOSED_EXCEP','Location List WH: '||I_group_value);
      open C_LOCK_LOC_LIST_WH;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_LOC_LIST_WH','COMPANY_CLOSED_EXCEP','Location List WH: '||I_group_value);
      close C_LOCK_LOC_LIST_WH;
      ---
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
      --Deletes all the Virtual Warehouses associated with a PWH or VWH on the location list.
         SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Location List WH: '||I_group_value);
         delete from company_closed_excep
          where close_date = NVL(I_close_date, close_date)
            and location in (select distinct w2.wh
                               from loc_list_detail l,
                                    wh w,
                                    wh w2
                              where l.loc_list          = to_number(I_group_value)
                                and l.location          = w.wh
                                and(w2.physical_wh      = w.wh
                                 or w2.physical_wh      = w.physical_wh)
                                and w2.stockholding_ind = 'Y'
                                and loc_type            = 'W');

      else    --Single Channel environment
         SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','Location List WH: '||I_group_value);
         delete from company_closed_excep
          where close_date = NVL(I_close_date, close_date)
            and location in (select location
                               from loc_list_detail
                              where loc_list = to_number(I_group_value)
                                and loc_type = 'W')
            and loc_type = 'W';
      end if;
   ---
   elsif I_group_type = 'AS' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_STORE','COMPANY_CLOSED_EXCEP','All Store: '||I_group_value);
      open C_LOCK_ALL_STORE;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_STORE','COMPANY_CLOSED_EXCEP','All Store: '||I_group_value);
      close C_LOCK_ALL_STORE;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP',' All Store: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'AW' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_WH','COMPANY_CLOSED_EXCEP','All Warehouse: '||I_group_value);
      open C_LOCK_ALL_WH;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_WH','COMPANY_CLOSED_EXCEP','All Warehouse: '||I_group_value);
      close C_LOCK_ALL_WH;

      SQL_LIB.SET_MARK('DELETE',NULL,'COMPANY_CLOSED_EXCEP','All Warehouse: '||I_group_value);
      delete from company_closed_excep
       where close_date = NVL(I_close_date, close_date)
         and loc_type   = 'W';
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('CLOSE_SQL.DELETE_LOC_EXCEPS',
                                            L_table,
                                            I_group_value);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.DELETE_LOC_EXCEPS',
                                            NULL);
      return FALSE;
END DELETE_LOC_EXCEPS;
--------------------------------------------------------------------------------------------
FUNCTION INSERT_LOC_EXCEPS(O_error_message  IN OUT  VARCHAR2,
                           I_close_date     IN      COMPANY_CLOSED_EXCEP.CLOSE_DATE%TYPE,
                           I_group_type     IN      VARCHAR2,
                           I_group_value    IN      VARCHAR2,
                           I_recv_ind       IN      VARCHAR2,
                           I_sales_ind      IN      VARCHAR2,
                           I_ship_ind       IN      VARCHAR2)
   RETURN BOOLEAN IS

BEGIN
  if I_group_type = 'S' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Store: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                values(I_close_date,
                                       I_group_value,
                                       'S',
                                       I_recv_ind,
                                       I_sales_ind,
                                       I_ship_ind);
   ---
   elsif I_group_type = 'W' then
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
         SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Warehouse: '||I_group_value);
         insert into company_closed_excep(close_date,
                                          location,
                                          loc_type,
                                          recv_ind,
                                          sales_ind,
                                          ship_ind)
                                   select I_close_date,
                                          wh,
                                          'W',
                                          I_recv_ind,
                                          I_sales_ind,
                                          I_ship_ind
                                     from wh
                                    where physical_wh      = I_group_value
                                      and stockholding_ind = 'Y';
      else
         SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Warehouse: '||I_group_value);
         insert into company_closed_excep(close_date,
                                          location,
                                          loc_type,
                                          recv_ind,
                                          sales_ind,
                                          ship_ind)
                                   values(I_close_date,
                                          I_group_value,
                                          'W',
                                          I_recv_ind,
                                          I_sales_ind,
                                          I_ship_ind);
      end if;
   ---
   elsif I_group_type = 'C' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Store Class: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       store,
                                       'S',
                                       DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                       I_sales_ind,
                                       DECODE(stockholding_ind, 'Y',I_ship_ind,'N')
                                  from store
                                 where store_class      = I_group_value
                                   and(stockholding_ind = 'Y'
                                    or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'D' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','District: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       store,
                                       'S',
                                       DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                       I_sales_ind,
                                       DECODE(stockholding_ind, 'Y',I_ship_ind,'N')
                                  from store
                                 where district         = to_number(I_group_value)
                                   and(stockholding_ind = 'Y'
                                    or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'R' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Region: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       store,
                                       'S',
                                       DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                       I_sales_ind,
                                       DECODE(stockholding_ind, 'Y',I_ship_ind,'N')
                                  from store
                                 where district in (select district
                                                      from district
                                                     where region = to_number(I_group_value))
                                                       and(stockholding_ind = 'Y'
                                                        or I_sales_ind      = 'Y');
   ---
   ---
   elsif I_group_type = 'T' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Transfer Zone: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       store,
                                       'S',
                                       DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                       I_sales_ind,
                                       DECODE(stockholding_ind, 'Y',I_ship_ind,'N')
                                  from store
                                 where transfer_zone    = to_number(I_group_value)
                                   and(stockholding_ind = 'Y'
                                    or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'L' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Location trait: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       lt.store,
                                       'S',
                                       DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                       I_sales_ind,
                                       DECODE(stockholding_ind, 'Y',I_ship_ind,'N')
                                  from loc_traits_matrix lt,
                                       store s
                                 where loc_trait        = to_number(I_group_value)
                                   and lt.store         = s.store
                                   and(stockholding_ind = 'Y'
                                    or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'DW' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Default WH: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       store,
                                       'S',
                                       DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                       I_sales_ind,
                                       DECODE(stockholding_ind, 'Y',I_ship_ind,'N')
                                  from store
                                 where default_wh       = to_number(I_group_value)
                                   and(stockholding_ind = 'Y'
                                    or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'LLS' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Location List Store: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       location,
                                       'S',
                                       DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                       I_sales_ind,
                                       DECODE(stockholding_ind, 'Y',I_ship_ind,'N')
                                  from loc_list_detail l,
                                       store s
                                 where loc_list         = to_number(I_group_value)
                                   and loc_type         = 'S'
                                   and l.location       = s.store
                                   and(stockholding_ind = 'Y'
                                    or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'LLW' then
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
      --Inserts all the Virtual Warehouses associated with a PWH or VWH on the location list.
         SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Location List WH: '||I_group_value);
         insert into company_closed_excep(close_date,
                                          location,
                                          loc_type,
                                          recv_ind,
                                          sales_ind,
                                          ship_ind)
                          select distinct I_close_date,
                                          w2.wh,
                                          'W',
                                          I_recv_ind,
                                          I_sales_ind,
                                          I_ship_ind
                            from loc_list_detail l,
                                 wh w,
                                 wh w2
                           where l.loc_list          = to_number(I_group_value)
                             and l.location          = w.wh
                             and(w2.physical_wh      = w.wh
                              or w2.physical_wh      = w.physical_wh)
                             and w2.stockholding_ind = 'Y'
                             and loc_type            = 'W';
      else     --Single Channel environment
         SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP','Location List WH: '||I_group_value);
         insert into company_closed_excep(close_date,
                                          location,
                                          loc_type,
                                          recv_ind,
                                          sales_ind,
                                          ship_ind)
                                   select I_close_date,
                                          location,
                                          'W',
                                          I_recv_ind,
                                          I_sales_ind,
                                          I_ship_ind
                                     from loc_list_detail
                                    where loc_list = to_number(I_group_value)
                                      and loc_type = 'W';
      end if;
   ---
   elsif I_group_type = 'AS' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP',' All Store: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       store,
                                       'S',
                                       DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                       I_sales_ind,
                                       DECODE(stockholding_ind, 'Y',I_ship_ind,'N')
                                  from store
                                 where(stockholding_ind = 'Y'
                                    or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'AW' then
      SQL_LIB.SET_MARK('INSERT', NULL,'COMPANY_CLOSED_EXCEP',' All Warehouse: '||I_group_value);

      insert into company_closed_excep(close_date,
                                       location,
                                       loc_type,
                                       recv_ind,
                                       sales_ind,
                                       ship_ind)
                                select I_close_date,
                                       wh,
                                       'W',
                                       I_recv_ind,
                                       I_sales_ind,
                                       I_ship_ind
                                  from wh;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.INSERT_LOC_EXCEPS',
                                            NULL);
      return FALSE;
END INSERT_LOC_EXCEPS;
--------------------------------------------------------------------------------------------
FUNCTION APPLY_CLOSED_LOCATIONS(O_error_message  IN OUT  VARCHAR2,
                                I_close_date     IN      LOCATION_CLOSED.CLOSE_DATE%TYPE,
                                I_group_type     IN      VARCHAR2,
                                I_group_value    IN      VARCHAR2,
                                I_recv_ind       IN      VARCHAR2,
                                I_sales_ind      IN      VARCHAR2,
                                I_ship_ind       IN      VARCHAR2,
                                I_close_reason   IN      LOCATION_CLOSED.REASON%TYPE)
   RETURN BOOLEAN IS

   QUICK_EXIT  EXCEPTION;

BEGIN
   if DELETE_CLOSED_LOCATIONS(O_error_message,
                              I_close_date,
                              I_group_type,
                              I_group_value) = FALSE then
      raise QUICK_EXIT;
   end if;
   ---
   if INSERT_CLOSED_LOCATIONS(O_error_message,
                              I_close_date,
                              I_group_type,
                              I_group_value,
                              I_recv_ind,
                              I_sales_ind,
                              I_ship_ind,
                              I_close_reason) = FALSE then
      raise QUICK_EXIT;
   end if;

   return TRUE;

EXCEPTION
   when QUICK_EXIT then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            O_error_message,
                                            'CLOSE_SQL.APPLY_CLOSED_LOCATIONS',
                                            null);

         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.APPLY_CLOSED_LOCATIONS',
                                            NULL);
      return FALSE;
END APPLY_CLOSED_LOCATIONS;
--------------------------------------------------------------------------------------------
FUNCTION DELETE_CLOSED_LOCATIONS(O_error_message  IN OUT  VARCHAR2,
                                 I_close_date     IN      LOCATION_CLOSED.CLOSE_DATE%TYPE,
                                 I_group_type     IN      VARCHAR2,
                                 I_group_value    IN      VARCHAR2)
   RETURN BOOLEAN IS

   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);
   L_table        VARCHAR2(50) := 'LOCATION_CLOSED';

   cursor C_LOCK_STORE is
      select 'x'
        from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location   = to_number(I_group_value)
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_WH_MCY is
      select 'x'
        from location_closed lc
       where lc.close_date = NVL(I_close_date, lc.close_date)
         and lc.loc_type   = 'W'
         and exists ( select 'x'
                        from v_wh w,
                             wh w2
                       where w.physical_wh = to_number(I_group_value)
                         and w.wh <> w.physical_wh
                         and w.stockholding_ind = 'Y'
                         and w.physical_wh    = w2.physical_wh
                         and w2.wh <> w2.physical_wh
                         and w2.stockholding_ind = 'Y'
                         and lc.location = w2.wh)
         for update nowait;

   cursor C_LOCK_WH_MCN is
      select 'x'
        from location_closed lc
       where lc.close_date = NVL(I_close_date, lc.close_date)
         and lc.location   = to_number(I_group_value)
         and lc.loc_type   = 'W'
         and exists ( select 'x'
                        from v_wh w
                       where w.wh = to_number(I_group_value))
         for update nowait;

   cursor C_LOCK_STORE_CLASS is
      select 'x'
       from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where store_class = I_group_value)
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_DISTRICT is
      select 'x'
       from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where district = to_number(I_group_value))
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_REGION is
      select 'x'
        from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where district in (select district
                                                from district
                                               where region = to_number(I_group_value)))
         and loc_type   = 'S'
         for update nowait;


   cursor C_LOCK_TRANS_ZONE is
      select 'x'
       from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where transfer_zone = to_number(I_group_value))
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_LOC_TRAIT is
      select 'x'
       from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from loc_traits_matrix
                           where loc_trait = to_number(I_group_value))
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_DEFAULT_WH is
      select 'x'
       from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where default_wh = to_number(I_group_value))
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_LOC_LIST_STORE is
      select 'x'
       from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select location
                            from loc_list_detail
                           where loc_list = to_number(I_group_value)
                             and loc_type = 'S')
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_LOC_LIST_WH_MCY is
      select 'x'
       from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select distinct w2.wh
                            from loc_list_detail l,
                                 v_wh w,
                                 wh w2
                           where l.loc_list         = to_number(I_group_value)
                             and l.loc_type           = 'W'
                             and (l.location        = w.wh
                              or l.location         = w.physical_wh)
                             and w.stockholding_ind = 'Y'
                             and w.physical_wh      <> w.wh
                             and w.physical_wh      = w2.physical_wh
                             and w2.stockholding_ind = 'Y'
                             and w2.physical_wh     <> w2.wh)
         and loc_type   = 'W'
         for update nowait;

   cursor C_LOCK_LOC_LIST_WH_MCN is
      select 'x'
       from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select location
                            from loc_list_detail l,
                                 v_wh w
                           where l.loc_list = to_number(I_group_value)
                             and l.loc_type = 'W'
                             and l.location = w.wh)
         and loc_type   = 'W'
         for update nowait;

   cursor C_LOCK_ALL_STORE is
      select 'x'
        from location_closed
       where close_date = NVL(I_close_date, close_date)
         and loc_type   = 'S'
         for update nowait;

   cursor C_LOCK_ALL_WH_MCY is
      select 'x'
        from location_closed lc
       where lc.close_date = NVL(I_close_date, lc.close_date)
         and lc.loc_type   = 'W'
         and exists (select 'x'
                       from v_wh w,
                            wh w2
                      where lc.location = w2.wh
                        and w.physical_wh <> w.wh
                        and w.stockholding_ind = 'Y'
                        and w.physical_wh = w2.physical_wh
                        and w2.physical_wh <> w2.wh
                        and w2.stockholding_ind = 'Y')
         for update nowait;

   cursor C_LOCK_ALL_WH_MCN is
      select 'x'
        from location_closed lc
       where lc.close_date = NVL(I_close_date, lc.close_date)
         and lc.loc_type   = 'W'
         and exists (select 'x'
                       from v_wh w
                      where lc.location = w.wh)
         for update nowait;

BEGIN
   if I_group_type = 'S' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_STORE','LOCATION_CLOSED','Store: '||I_group_value);
      open C_LOCK_STORE;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_STORE','LOCATION_CLOSED','Store: '||I_group_value);
      close C_LOCK_STORE;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Store: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location   = to_number(I_group_value)
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'W' then
      ---
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                              LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_WH_MCY','LOCATION_CLOSED','Warehouse: '||I_group_value);
         open C_LOCK_WH_MCY;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_WH_MCY','LOCATION_CLOSED','Warehouse: '||I_group_value);
         close C_LOCK_WH_MCY;
         ---
         SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Warehouse: '||I_group_value);
         delete from location_closed lc
          where close_date = NVL(I_close_date, close_date)
            and exists (select 'x'
                        from v_wh w,
                             wh w2
                       where w.physical_wh = to_number(I_group_value)
                         and w.wh <> w.physical_wh
                         and w.stockholding_ind = 'Y'
                         and w.physical_wh    = w2.physical_wh
                         and w2.wh <> w2.physical_wh
                         and w2.stockholding_ind = 'Y'
                         and lc.location = w2.wh)
            and loc_type   = 'W';
      else   --Single Channel Environment
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_WH_MCN','LOCATION_CLOSED','Warehouse: '||I_group_value);
         open C_LOCK_WH_MCN;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_WH_MCN','LOCATION_CLOSED','Warehouse: '||I_group_value);
         close C_LOCK_WH_MCN;
         ---
         SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Warehouse: '||I_group_value);
         delete from location_closed
          where close_date = NVL(I_close_date, close_date)
            and location   = to_number(I_group_value)
            and loc_type   = 'W'
            and exists (select 'x'
                        from v_wh w
                       where w.wh = to_number(I_group_value));
      end if;
   ---
   elsif I_group_type = 'C' then
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_STORE_CLASS','LOCATION_CLOSED','Store Class: '||I_group_value);
      open C_LOCK_STORE_CLASS;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_STORE_CLASS','LOCATION_CLOSED','Store Class: '||I_group_value);
      close C_LOCK_STORE_CLASS;

      SQL_LIB.SET_MARK('DELETE', NULL,'LOCATION_CLOSED','Store Class: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where store_class = I_group_value)
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'D' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DISTRICT','LOCATION_CLOSED','District: '||I_group_value);
      open C_LOCK_DISTRICT;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DISTRICT','LOCATION_CLOSED','District: '||I_group_value);
      close C_LOCK_DISTRICT;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','District: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where district = to_number(I_group_value))
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'R' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_REGION','LOCATION_CLOSED','Region: '||I_group_value);
      open C_LOCK_REGION;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_REGION','LOCATION_CLOSED','Region: '||I_group_value);
      close C_LOCK_REGION;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Region: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where district in (select district
                                                from district
                                               where region = to_number(I_group_value)))
         and loc_type   = 'S';
   ---
   ---
   elsif I_group_type = 'T' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_TRANS_ZONE','LOCATION_CLOSED','Transfer Zone: '||I_group_value);
      open C_LOCK_TRANS_ZONE;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_TRANS_ZONE','LOCATION_CLOSED','Transfer Zone: '||I_group_value);
      close C_LOCK_TRANS_ZONE;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Transfer Zone: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where transfer_zone = to_number(I_group_value))
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'L' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_LOC_TRAIT','LOCATION_CLOSED','Location trait: '||I_group_value);
      open C_LOCK_LOC_TRAIT;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_LOC_TRAIT','LOCATION_CLOSED','Location trait: '||I_group_value);
      close C_LOCK_LOC_TRAIT;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Location trait: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from loc_traits_matrix
                           where loc_trait = to_number(I_group_value))
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'DW' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_DEFAULT_WH','LOCATION_CLOSED','Default WH: '||I_group_value);
      open C_LOCK_DEFAULT_WH;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEFAULT_WH','LOCATION_CLOSED','Default WH: '||I_group_value);
      close C_LOCK_DEFAULT_WH;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Default WH: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select store
                            from store
                           where default_wh = to_number(I_group_value))
         and loc_type   = 'S';

   ---
   elsif I_group_type = 'LLS' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_LOC_LIST_STORE','LOCATION_CLOSED','Location List Store: '||I_group_value);
      open C_LOCK_LOC_LIST_STORE;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_LOC_LIST_STORE','LOCATION_CLOSED','Location List Store: '||I_group_value);
      close C_LOCK_LOC_LIST_STORE;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Location List Store: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and location in (select location
                            from loc_list_detail
                           where loc_list = to_number(I_group_value)
                             and loc_type = 'S')
                             and loc_type   = 'S';
   ---
   elsif I_group_type = 'LLW' then
      ---
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_LOC_LIST_WH_MCY','LOCATION_CLOSED','Location List WH: '||I_group_value);
         open C_LOCK_LOC_LIST_WH_MCY;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_LOC_LIST_WH_MCY','LOCATION_CLOSED','Location List WH: '||I_group_value);
         close C_LOCK_LOC_LIST_WH_MCY;
         ---
      --Deletes all the Virtual Warehouses associated with PW or VW on the location list.
         SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Location List WH: '||I_group_value);
         delete from location_closed
          where close_date = NVL(I_close_date, close_date)
            and location in (select distinct w2.wh
                               from loc_list_detail l,
                                    v_wh w,
                                    wh w2
                              where l.loc_list          = to_number(I_group_value)
                                and l.loc_type           = 'W'
                                and (l.location        = w.wh
                                 or l.location         = w.physical_wh)
                                and w.stockholding_ind = 'Y'
                                and w.physical_wh      <> w.wh
                                and w.physical_wh      = w2.physical_wh
                                and w2.stockholding_ind = 'Y'
                                and w2.physical_wh     <> w2.wh)
                                and loc_type   = 'W';
      else    --Single Channel environment
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_LOC_LIST_WH_MCY','LOCATION_CLOSED','Location List WH: '||I_group_value);
         open C_LOCK_LOC_LIST_WH_MCY;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_LOC_LIST_WH_MCY','LOCATION_CLOSED','Location List WH: '||I_group_value);
         close C_LOCK_LOC_LIST_WH_MCY;
         ---
         SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED','Location List WH: '||I_group_value);
         delete from location_closed
          where close_date = NVL(I_close_date, close_date)
            and location in (select l.location
                               from loc_list_detail l,
                                    v_wh w
                              where l.loc_list = to_number(I_group_value)
                                and l.loc_type = 'W'
                                and l.location = w.wh)
            and loc_type   = 'W';
      end if;
   ---
   elsif I_group_type = 'AS' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_STORE','LOCATION_CLOSED',' All Store: '||I_group_value);
      open C_LOCK_ALL_STORE;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_STORE','LOCATION_CLOSED',' All Store: '||I_group_value);
      close C_LOCK_ALL_STORE;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED',' All Store: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and loc_type   = 'S';
   ---
   elsif I_group_type = 'AW' then
      ---
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_WH_MCY','LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         open C_LOCK_ALL_WH_MCY;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_WH_MCY','LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         close C_LOCK_ALL_WH_MCY;
         ---

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED',' All Warehouse: '||I_group_value);
      delete from location_closed lc
       where close_date = NVL(I_close_date, close_date)
            and loc_type   = 'W'
            and exists (select 'x'
                       from v_wh w,
                            wh w2
                      where lc.location = w2.wh
                        and w.physical_wh <> w.wh
                        and w.stockholding_ind = 'Y'
                        and w.physical_wh = w2.physical_wh
                        and w2.physical_wh <> w2.wh
                        and w2.stockholding_ind = 'Y');
      else
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_WH_MCN','LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         open C_LOCK_ALL_WH_MCN;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_WH_MCN','LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         close C_LOCK_ALL_WH_MCN;
         ---
         SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         delete from location_closed lc
          where close_date = NVL(I_close_date, close_date)
            and loc_type   = 'W'
            and exists (select 'x'
                       from v_wh w
                      where lc.location = w.wh);
      end if;
   elsif I_group_type = 'AL' then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_STORE','LOCATION_CLOSED',' All Locations: '||I_group_value);
      open C_LOCK_ALL_STORE;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_STORE','LOCATION_CLOSED',' All Locations: '||I_group_value);
      close C_LOCK_ALL_STORE;

      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED',' All Locations: '||I_group_value);
      delete from location_closed
       where close_date = NVL(I_close_date, close_date)
         and loc_type   = 'S';

      ---
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_WH_MCY','LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         open C_LOCK_ALL_WH_MCY;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_WH_MCY','LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         close C_LOCK_ALL_WH_MCY;
         ---
      SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED',' All Warehouse: '||I_group_value);
      delete from location_closed lc
       where close_date = NVL(I_close_date, close_date)
            and loc_type   = 'W'
            and exists (select 'x'
                       from v_wh w,
                            wh w2
                      where lc.location = w2.wh
                        and w.physical_wh <> w.wh
                        and w.stockholding_ind = 'Y'
                        and w.physical_wh = w2.physical_wh
                        and w2.physical_wh <> w2.wh
                        and w2.stockholding_ind = 'Y');
      else
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ALL_WH_MCN','LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         open C_LOCK_ALL_WH_MCN;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALL_WH_MCN','LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         close C_LOCK_ALL_WH_MCN;
         ---
         SQL_LIB.SET_MARK('DELETE',NULL,'LOCATION_CLOSED',' All Warehouse: '||I_group_value);
         delete from location_closed lc
          where close_date = NVL(I_close_date, close_date)
            and loc_type   = 'W'
            and exists (select 'x'
                       from v_wh w
                      where lc.location = w.wh);
      end if;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('CLOSE_SQL.DELETE_CLOSED_LOCATIONS',
                                            L_table,
                                            I_group_value);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.DELETE_CLOSED_LOCATIONS',
                                            NULL);
      return FALSE;
END DELETE_CLOSED_LOCATIONS;
--------------------------------------------------------------------------------------------
FUNCTION INSERT_CLOSED_LOCATIONS(O_error_message  IN OUT  VARCHAR2,
                                 I_close_date     IN      LOCATION_CLOSED.CLOSE_DATE%TYPE,
                                 I_group_type     IN      VARCHAR2,
                                 I_group_value    IN      VARCHAR2,
                                 I_recv_ind       IN      VARCHAR2,
                                 I_sales_ind      IN      VARCHAR2,
                                 I_ship_ind       IN      VARCHAR2,
                                 I_close_reason   IN      LOCATION_CLOSED.REASON%TYPE)
   RETURN BOOLEAN IS

BEGIN
   if I_group_type = 'S' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Store: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           values(I_close_date,
                                  I_group_value,
                                  'S',
                                  I_recv_ind,
                                  I_sales_ind,
                                  I_ship_ind,
                                  I_close_reason);
   ---
   elsif I_group_type = 'W' then
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
         SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Warehouse: '||I_group_value);
         insert into location_closed(close_date,
                                     location,
                                     loc_type,
                                     recv_ind,
                                     sales_ind,
                                     ship_ind,
                                     reason)
                              select distinct I_close_date,
                                     w2.wh,
                                     'W',
                                     I_recv_ind,
                                     I_sales_ind,
                                     I_ship_ind,
                                     I_close_reason
                                from v_wh w,
                                     wh w2
                               where w.physical_wh = to_number(I_group_value)
                                 and w.wh <> w.physical_wh
                                 and w.stockholding_ind = 'Y'
                                 and w.physical_wh    = w2.physical_wh
                                 and w2.wh <> w2.physical_wh
                                 and w2.stockholding_ind = 'Y';
      else
         SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Warehouse: '||I_group_value);
         insert into location_closed(close_date,
                                     location,
                                     loc_type,
                                     recv_ind,
                                     sales_ind,
                                     ship_ind,
                                     reason)
                              select I_close_date,
                                     I_group_value,
                                     'W',
                                     I_recv_ind,
                                     I_sales_ind,
                                     I_ship_ind,
                                     I_close_reason
                                from v_wh
                               where wh = to_number(I_group_value);
      end if;
   ---
   elsif I_group_type = 'C' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Store Class: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  store,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from store
                            where store_class      = I_group_value
                              and(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'D' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','District: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  store,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from store
                            where district = to_number(I_group_value)
                              and(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'R' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Region: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  store,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from store
                            where district in (select district
                                                 from district
                                                where region = to_number(I_group_value))
                              and(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');
   ---
   ---
   elsif I_group_type = 'T' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Transfer Zone: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  store,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from store
                            where transfer_zone    = to_number(I_group_value)
                              and(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'L' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Location trait: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  lt.store,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from loc_traits_matrix lt,
                            store s
                            where loc_trait        = to_number(I_group_value)
                              and lt.store         = s.store
                              and(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'DW' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Default WH: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  store,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from store
                            where default_wh       = to_number(I_group_value)
                              and(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'LLS' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Location List Store: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  location,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from loc_list_detail l,
                            store s
                            where loc_list         = to_number(I_group_value)
                              and loc_type         = 'S'
                              and l.location       = s.store
                              and(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'LLW' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED','Location List WH: '||I_group_value);
      ---
      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
      --Inserts all the Virtual Warehouses associated with a PWH or VWH on the location list.
         insert into location_closed(close_date,
                                     location,
                                     loc_type,
                                     recv_ind,
                                     sales_ind,
                                     ship_ind,
                                     reason)
                     select distinct I_close_date,
                                     w2.wh,
                                     'W',
                                     I_recv_ind,
                                     I_sales_ind,
                                     I_ship_ind,
                                     I_close_reason
                                from loc_list_detail l,
                                     v_wh w,
                                     wh w2
                               where l.loc_list          = to_number(I_group_value)
                                 and l.loc_type           = 'W'
                                 and (l.location        = w.wh
                                  or l.location         = w.physical_wh)
                                 and w.stockholding_ind = 'Y'
                                 and w.physical_wh      <> w.wh
                                 and w.physical_wh      = w2.physical_wh
                                 and w2.stockholding_ind = 'Y'
                                 and w2.physical_wh     <> w2.wh;
   else     --Single Channel environment
         insert into location_closed(close_date,
                                     location,
                                     loc_type,
                                     recv_ind,
                                     sales_ind,
                                     ship_ind,
                                     reason)
                              select I_close_date,
                                     l.location,
                                     'W',
                                     I_recv_ind,
                                     I_sales_ind,
                                     I_ship_ind,
                                     I_close_reason
                               from loc_list_detail l,
                                    v_wh w
                              where l.loc_list = to_number(I_group_value)
                                and l.loc_type = 'W'
                                and l.location = w.wh;
      end if;
   ---
   elsif I_group_type = 'AS' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED',' All Store: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  store,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from store
                            where(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');
   ---
   elsif I_group_type = 'AW' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED',' All Warehouse: '||I_group_value);

      if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                                 LP_multichannel_ind)= FALSE then
         return FALSE;
      end if;
      ---
      if LP_multichannel_ind = 'Y' then
         insert into location_closed(close_date,
                                     location,
                                     loc_type,
                                     recv_ind,
                                     sales_ind,
                                     ship_ind,
                                     reason)
                              select distinct I_close_date,
                                     w2.wh,
                                     'W',
                                     I_recv_ind,
                                     I_sales_ind,
                                     I_ship_ind,
                                     I_close_reason
                                from v_wh w,
                                     wh w2
                               where w.physical_wh <> w.wh
                                 and w.stockholding_ind = 'Y'
                                 and w.physical_wh = w2.physical_wh
                                 and w2.physical_wh <> w2.wh
                                 and w2.stockholding_ind = 'Y';
      else
         insert into location_closed(close_date,
                                     location,
                                     loc_type,
                                     recv_ind,
                                     sales_ind,
                                     ship_ind,
                                     reason)
                              select I_close_date,
                                     wh,
                                     'W',
                                     I_recv_ind,
                                     I_sales_ind,
                                     I_ship_ind,
                                     I_close_reason
                                from v_wh;
      end if;
   elsif I_group_type = 'AL' then
      SQL_LIB.SET_MARK('INSERT', NULL,'LOCATION_CLOSED',' All locations: '||I_group_value);

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  store,
                                  'S',
                                  DECODE(stockholding_ind, 'Y',I_recv_ind,'N'),
                                  I_sales_ind,
                                  DECODE(stockholding_ind, 'Y',I_ship_ind,'N'),
                                  I_close_reason
                             from store
                            where(stockholding_ind = 'Y'
                               or I_sales_ind      = 'Y');

      insert into location_closed(close_date,
                                  location,
                                  loc_type,
                                  recv_ind,
                                  sales_ind,
                                  ship_ind,
                                  reason)
                           select I_close_date,
                                  wh,
                                  'W',
                                  I_recv_ind,
                                  I_sales_ind,
                                  I_ship_ind,
                                  I_close_reason
                             from v_wh;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.INSERT_CLOSED_LOCATIONS',
                                            NULL);
      return FALSE;
END INSERT_CLOSED_LOCATIONS;
---------------------------------------------------------------------------------------------
FUNCTION DELETE_STORE_SHIP_DATES(O_error_message  IN OUT  VARCHAR2,
                                 I_close_date     IN      LOCATION_CLOSED.CLOSE_DATE%TYPE,
                                 I_group_type     IN      VARCHAR2,
                                 I_group_value    IN      VARCHAR2)
   RETURN BOOLEAN IS

   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);
   L_table        VARCHAR2(50) := 'STORE_SHIP_DATE';

   cursor C_LOCK_WH_MCY is
      select 'x'
        from  store_ship_date ssd
       where ship_date = I_close_date
        and exists (select 'x'
                        from v_wh w,
                             wh w2
                       where w.physical_wh = to_number(I_group_value)
                         and w.wh <> w.physical_wh
                         and w.stockholding_ind = 'Y'
                         and w.physical_wh    = w2.physical_wh
                         and w2.wh <> w2.physical_wh
                         and w2.stockholding_ind = 'Y'
                         and ssd.wh = w2.wh)
        for update nowait;

   cursor C_LOCK_WH_MCN is
      select 'x'
        from  store_ship_date
       where ship_date = I_close_date
        and WH = to_number(I_group_value)
         and exists ( select 'x'
                        from v_wh w
                       where w.wh = to_number(I_group_value))
        for update nowait;

  cursor C_LOCK_LOC_LIST_WH_MCY is
      select 'x'
        from store_ship_date
       where ship_date = I_close_date
        and WH in (select distinct w2.wh
                            from loc_list_detail l,
                                 v_wh w,
                                 wh w2
                           where l.loc_list         = to_number(I_group_value)
                             and l.loc_type           = 'W'
                             and (l.location        = w.wh
                              or l.location         = w.physical_wh)
                             and w.stockholding_ind = 'Y'
                             and w.physical_wh      <> w.wh
                             and w.physical_wh      = w2.physical_wh
                             and w2.stockholding_ind = 'Y'
                             and w2.physical_wh     <> w2.wh)
        for update nowait;

  cursor C_LOCK_LOC_LIST_WH_MCN is
      select 'x'
        from store_ship_date
       where ship_date = I_close_date
        and WH in (select location
                            from loc_list_detail l,
                                 v_wh w
                           where l.loc_list = to_number(I_group_value)
                             and l.loc_type = 'W'
                             and l.location = w.wh)
        for update nowait;

  cursor C_LOCK_ALL_WH_MCY is
      select 'x'
        from store_ship_date ssd
       where ship_date = I_close_date
         and exists(select 'x'
                       from v_wh w,
                            wh w2
                      where ssd.wh = w2.wh
                        and w.physical_wh <> w.wh
                        and w.stockholding_ind = 'Y'
                        and w.physical_wh = w2.physical_wh
                        and w2.physical_wh <> w2.wh
                        and w2.stockholding_ind = 'Y')
        for update nowait;

  cursor C_LOCK_ALL_WH_MCN is
      select 'x'
        from store_ship_date ssd
       where ship_date = I_close_date
         and exists (select 'x'
                       from v_wh w
                      where ssd.wh = w.wh)
        for update nowait;

BEGIN

   ---
   if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                              LP_multichannel_ind)= FALSE then
      return FALSE;
   end if;
   ---
   if I_group_type = 'W' then
      if LP_multichannel_ind = 'Y' then
         open C_LOCK_WH_MCY;
         close C_LOCK_WH_MCY;

      SQL_LIB.SET_MARK('DELETE', NULL,'STORE_SHIP_DATE','Warehouse: '||to_char(I_close_date));

         delete from store_ship_date ssd
          where ship_date = I_close_date
             and exists (select 'x'
                        from v_wh w,
                             wh w2
                       where w.physical_wh = to_number(I_group_value)
                         and w.wh <> w.physical_wh
                         and w.stockholding_ind = 'Y'
                         and w.physical_wh    = w2.physical_wh
                         and w2.wh <> w2.physical_wh
                         and w2.stockholding_ind = 'Y'
                         and ssd.wh = w2.wh);
      else
         open C_LOCK_WH_MCN;
         close C_LOCK_WH_MCN;

         SQL_LIB.SET_MARK('DELETE', NULL,'STORE_SHIP_DATE','Warehouse: '||to_char(I_close_date));

         delete from store_ship_date
          where ship_date = I_close_date
             and WH = to_number(I_group_value)
             and exists ( select 'x'
                            from v_wh w
                           where w.wh = to_number(I_group_value));
      end if;

   elsif I_group_type = 'LLW' then
      if LP_multichannel_ind = 'Y' then
         open C_LOCK_LOC_LIST_WH_MCY;
         close C_LOCK_LOC_LIST_WH_MCY;

         SQL_LIB.SET_MARK('DELETE', NULL,'STORE_SHIP_DATE','Location List WH: '||to_char(I_close_date));

         delete from store_ship_date
          where ship_date = I_close_date
            and WH in (select distinct w2.wh
                            from loc_list_detail l,
                                 v_wh w,
                                 wh w2
                           where l.loc_list         = to_number(I_group_value)
                             and l.loc_type           = 'W'
                             and (l.location        = w.wh
                              or l.location         = w.physical_wh)
                             and w.stockholding_ind = 'Y'
                             and w.physical_wh      <> w.wh
                             and w.physical_wh      = w2.physical_wh
                             and w2.stockholding_ind = 'Y'
                             and w2.physical_wh     <> w2.wh);
      else
         open C_LOCK_LOC_LIST_WH_MCN;
         close C_LOCK_LOC_LIST_WH_MCN;


      SQL_LIB.SET_MARK('DELETE', NULL,'STORE_SHIP_DATE','Location List WH: '||to_char(I_close_date));

      delete from store_ship_date
       where ship_date = I_close_date
         and WH in (select location
                            from loc_list_detail
                           where loc_list = to_number(I_group_value)
                             and loc_type = 'W');

      end if;

   elsif I_group_type = 'AW' then
      if LP_multichannel_ind = 'Y' then
         open C_LOCK_ALL_WH_MCY;
         close C_LOCK_ALL_WH_MCY;

      SQL_LIB.SET_MARK('DELETE', NULL,'STORE_SHIP_DATE',' All Warehouse: '||to_char(I_close_date));

         delete from store_ship_date ssd
          where ship_date = I_close_date
         and exists(select 'x'
                       from v_wh w,
                            wh w2
                      where ssd.wh = w2.wh
                        and w.physical_wh <> w.wh
                        and w.stockholding_ind = 'Y'
                        and w.physical_wh = w2.physical_wh
                        and w2.physical_wh <> w2.wh
                        and w2.stockholding_ind = 'Y');
      else
         open C_LOCK_ALL_WH_MCN;
         close C_LOCK_ALL_WH_MCN;

         SQL_LIB.SET_MARK('DELETE', NULL,'STORE_SHIP_DATE',' All Warehouse: '||to_char(I_close_date));

         delete from store_ship_date ssd
          where ship_date = I_close_date
            and exists (select 'x'
                          from v_wh w
                         where ssd.wh = w.wh);
      end if;

   end if;

  return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('CLOSE_SQL.DELETE_STORE_SHIP_DATES',
                                            L_table,
                                            to_char(I_close_date));
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CLOSE_SQL.DELETE_STORE_SHIP_DATES',
                                            NULL);
      return FALSE;
END DELETE_STORE_SHIP_DATES;
------------------------------------------------------------------------------------------------------

END CLOSE_SQL;
/

