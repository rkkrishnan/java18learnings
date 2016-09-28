CREATE OR REPLACE PACKAGE BODY DAILY_PURGE_SQL AS
--------------------------------------------------------------------------------------
--Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
--Mod Date:    17-Mar-2008
--Mod Ref:     Mod number. N126
--Mod Details: Modified INSERT_RECORD function to handle deactivate functionality
--------------------------------------------------------------------------------------
-- Mod By:      Murali
-- Mod Date:    09-Apr-2008
-- Mod Ref:     DefNBS006050
-- Mod Details: Modified the function INSERT_RECORD to update deactivation date even for
--              children and grand children of the item being deactivated.
---------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Karthik Dhanapal
--Mod Date:    06-Aug-2008
--Mod Ref:     For defect NBS00003210/NBS00007972.
--Mod Details: Added the function INSERT_RECORD_FOR_ITEMMASTER.
------------------------------------------------------------------------------------------------
-- Mod By:      Tesco HSC/Satish B.N
-- Mod Date:    04-Sep-2008
-- Mod Ref:     DefNBS008693
-- Mod Details: Added a new parameter to INSERT_RECORD fucntion for DefNBS008693
---------------------------------------------------------------------------------------
-- Mod By:      Usha Patil, usha.patil@in.tesco.com
-- Mod Date:    25-May-2009
-- Mod Ref:     CR214
-- Mod Details: Modified the function INSERT_RECORD to update deactivation date for packs
--              and variants if the base or style is deactivated and to insert the worksheet
--              items into daily_purge table.
---------------------------------------------------------------------------------------
-- Mod By:      Usha Patil
-- Mod Date:    27-May-2009
-- Mod Ref:     Defect Id(NBS00013080)
-- Mod Details: Modified function UPDATE_ITEM_STATUS to update the packs to worksheet
--              status when style is made worksheet.
---------------------------------------------------------------------------------------
-- Mod By       : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date     : 23-Jun-2009
-- Def Ref      : MrgNBS013573
-- Def Details  : Modified the function UPDATE_ITEM_STATUS as a part of Merge.
-------------------------------------------------------------------------------------------------
-- Mod By:      Usha Patil
-- Mod Date:    08-Sep-2009
-- Mod Ref:     Defect Id(NBS00014580)
-- Mod Details: Modified function INSERT_RECORD to insert the correct delete orders for items
--              in worksheet status.
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-- Mod By:      Nandini M,Nandini.Mariyappa@in.tesco.com
-- Mod Date:    22-Mar-2010
-- Mod Ref:     CR224b
-- Mod Details: Added a new function TSL_CANCEL_DELETE to handle cancel deletion operation on items.
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-- Mod By:      Smitha Ramesh
-- Mod Date:    17-Mar-2014
-- Mod Ref:     CR495
-- Mod Details: Added a new function TSL_DELETE_RECORD to handle deletion from daily purge.
-------------------------------------------------------------------------------------------------
FUNCTION CHECK_EXISTS (O_error_message IN OUT VARCHAR2,
                       O_exists        IN OUT BOOLEAN,
                       I_key_value     IN     DAILY_PURGE.KEY_VALUE%TYPE,
                       I_table_name    IN     DAILY_PURGE.TABLE_NAME%TYPE)
   RETURN BOOLEAN IS

   L_dummy    VARCHAR2(1)  := NULL;

   cursor C_EXISTS is
      select 'x'
        from daily_purge
       where key_value = I_key_value
         and table_name = I_table_name;

BEGIN

   open C_EXISTS;
   fetch C_EXISTS into L_dummy;
   close C_EXISTS;

   if L_dummy = 'x' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DAILY_PURGE_SQL.CHECK_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_EXISTS;
----------------------------------------------------------------------------------------
FUNCTION INSERT_RECORD (O_error_message  IN OUT VARCHAR2,
                        I_key_value      IN     DAILY_PURGE.KEY_VALUE%TYPE,
                        I_table_name     IN     DAILY_PURGE.TABLE_NAME%TYPE,
                        I_delete_type    IN     DAILY_PURGE.DELETE_TYPE%TYPE,
                        I_delete_order   IN     DAILY_PURGE.DELETE_ORDER%TYPE,
                        -- 4-sep-2008 Tesco HSC/Satish DefNBS8693 Begin
                        I_deact_item     IN     VARCHAR2 DEFAULT 'Y')
                        -- 4-sep-2008 Tesco HSC/Satish DefNBS8693 End
   RETURN BOOLEAN IS

   L_dept              DEPS.DEPT%TYPE;
   L_class             CLASS.CLASS%TYPE;
   --11-May-2009 Tesco HSC/Usha Patil             Mod:CR214 Begin
   L_delete_order      DAILY_PURGE.DELETE_ORDER%TYPE := 1;
   L_base_delete_order DAILY_PURGE.DELETE_ORDER%TYPE := 1;
   L_item_tbl          TSL_DEACTIVATE_SQL.ITEM_API_TBLTYPE;
   L_depend_item_tbl   TSL_DEACTIVATE_SQL.ITEM_API_TBLTYPE;
   L_comp_item         PACKITEM.ITEM%TYPE := NULL;
   L_found             VARCHAR2(1);
   L_dummy             VARCHAR2(1);
   --11-May-2009 Tesco HSC/Usha Patil             Mod:CR214 End
   --17-MAR-2008    Wipro/JK  ModN126   Begin
   L_item           ITEM_MASTER%ROWTYPE;
   --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, Begin
   L_cancl_deact_date  VARCHAR2(1):= 'N';
   --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, End
   record_locked EXCEPTION;
   PRAGMA EXCEPTION_INIT(record_locked, -54);

   cursor C_LOCK_ITEM_MASTER is
     select 'x'
       from item_master im
      where im.item = i_key_value
        for update nowait;
   --17-MAR-2008    Wipro/JK  ModN126   End
   --11-May-2009 Tesco HSC/Usha Patil             Mod:CR214 Begin
   cursor C_CHK_PACK is
   select 'x'
     from packitem pi1,
          packitem pi2,
          item_master im
    where pi1.pack_no = I_key_value
      and pi1.item    = pi2.item
      and pi1.pack_no <> pi2.pack_no
      and im.item     = pi2.pack_no
      and nvl(im.tsl_deactivated,'N') <> 'Y'
      and im.simple_pack_ind          = 'Y';

   cursor C_GET_COMP is
   select pai.item
     from packitem pai,
          item_master iem
    where pai.pack_no = I_key_value
      and iem.item = pai.item
      and iem.pack_ind = 'N'
      and iem.status = 'A';

   cursor C_CHK_DLY_PRG is
   select 1
     from daily_purge
    where key_value = I_key_value;
   --11-May-2009 Tesco HSC/Usha Patil             Mod:CR214 End

BEGIN

   if I_key_value is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_key_value',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_table_name is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_table_name',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_delete_type is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_delete_type',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_delete_order is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_delete_order',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_table_name = 'DEPS' then
      L_dept := to_number(I_key_value);

      insert into daily_purge(key_value,
                              table_name,
                              delete_type,
                              delete_order)
                       values(I_key_value,
                              'DEPS',
                              'D',
                              '3');

      insert into daily_purge (key_value,
                               table_name,
                               delete_type,
                               delete_order)
                        select key_v,
                               'CLASS',
                               'D',
                               '2'
                          from (select substr(to_char(s.dept, '0999'), 2, 4) || ';' || substr(to_char(s.class, '0999'), 2, 4) key_v
                                  from class s
                                 where dept = L_dept) table_temp
                         where table_temp.key_v not in (select key_value
                                                          from daily_purge
                                                         where table_name = 'CLASS');

      insert into daily_purge (key_value,
                               table_name,
                               delete_type,
                               delete_order)
                        select key_v,
                               'SUBCLASS',
                               'D',
                               '1'
                          from (select substr(to_char(s.dept, '0999'), 2, 4) || ';' || substr(to_char(s.class, '0999'), 2, 4) || ';' || substr(to_char(s.subclass, '0999'), 2, 4) key_v
                                  from subclass s
                                 where dept = L_dept) table_temp
                         where table_temp.key_v not in (select key_value
                                                          from daily_purge
                                                         where table_name = 'SUBCLASS');

   elsif I_table_name = 'CLASS' then
      L_dept  := to_number(substr(I_key_value,1,4));
      L_class := to_number(substr(I_key_value,6,4));

      insert into daily_purge(key_value,
                              table_name,
                              delete_type,
                              delete_order)
                       values(I_key_value,
                              'CLASS',
                              'D',
                              '2');

      insert into daily_purge (key_value,
                               table_name,
                               delete_type,
                               delete_order)
                        select key_v,
                               'SUBCLASS',
                               'D',
                               '1'
                          from (select substr(to_char(s.dept, '0999'), 2, 4) || ';' || substr(to_char(s.class, '0999'), 2, 4) || ';' || substr(to_char(s.subclass, '0999'), 2, 4) key_v
                                  from subclass s
                                 where dept  = L_dept
                                   and class = L_class) table_temp
                         where table_temp.key_v not in (select key_value
                                                         from daily_purge
                                                        where table_name = 'SUBCLASS');
   --17-MAR-2008    Wipro/JK  ModN126   Begin
   elsif I_table_name = 'ITEM_MASTER' then
      if item_attrib_sql.get_item_master(o_error_message,
                                         L_item,
                                         I_key_value) = FALSE then
         return FALSE;
      end if;

      --  Added I_dact_item = 'Y'to if ondition for DefNBS8693.
      --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, Begin
      -- Below logic of setting the deactivation date = VDATE + 1 needs to be removed
      -- as deactivation date will be set onlie itself

      --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, Begin
      if L_item.status = 'A' and NVL(L_item.tsl_deactivated,'N') <> 'Y' and L_cancl_deact_date = 'Y' then
      --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, End
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_ITEM_MASTER',
                          'ITEM_MASTER',
                          'I_item ' || I_key_value);
         open c_lock_item_master;
       ---
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_ITEM_MASTER',
                          'ITEM_MASTER',
                          'I_item ' || I_key_value);
         close c_lock_item_master;
         ---
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'item_master',
                          'I_item ' || I_key_value);

         update item_master
            set tsl_deactivate_date = (select vdate + 1
                                         from period)
         where item = I_key_value;
         --09-Apr-2008 TESCO HSC/Murali        DefNBS006050 Begin
         update item_master set tsl_deactivate_date =(select vdate + 1
                                                        from period)
          where status = 'A' and
              --- DefNBS00011215 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , Begin
                tsl_suspended <> 'Y' and
                --- DefNBS00011215 , Tarun Kumar Mishra , tarun.mishra@in.tesco.com , End
             (item_parent = I_key_value or item_grandparent = I_key_value);
         --09-Apr-2008 TESCO HSC/Murali        DefNBS006050 End
         -- 11-May-2009 Tesco HSC/Usha Patil                Mod:CR214 Begin
         -- if a base item or style item is deactivated then deactivation date is set for the
         --entire item sturcture.

         if (L_item.item_level <= L_item.tran_level and L_item.pack_ind = 'N') then
            if TSL_DEACTIVATE_SQL.GET_ITEMS (O_error_message,
                                              L_item_tbl,
                                              L_item.item) = FALSE then
               return FALSE;
            end if;

            if L_item_tbl is NOT NULL and L_item_tbl.COUNT > 0 then
               FOR i in L_item_tbl.FIRST..L_item_tbl.LAST
               LOOP
                  SQL_LIB.SET_MARK('UPDATE',
                                   NULL,
                                   'item_master',
                                   'I_item ' || L_item_tbl(i).item);
                  update item_master
                     set tsl_deactivate_date = (select vdate + 1
                                                  from period)
                   where status = 'A'
                     and item = L_item_tbl(i).item;
               END LOOP;
            end if;
        elsif (L_item.item_level = 1 and L_item.pack_ind = 'Y' and L_item.simple_pack_ind = 'Y') then
         --if the last pack is deactivated then entire item structure of the component item will be set
         --a deactivation date.
            SQL_LIB.SET_MARK('OPEN',
                             'C_CHK_PACK',
                             'PACKITEM',
                             'item:'||L_item.item);
            open C_CHK_PACK;

            SQL_LIB.SET_MARK('FETCH',
                             'C_CHK_PACK',
                             'PACKITEM',
                             'item:'||L_item.item);
            fetch C_CHK_PACK into L_found;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_CHK_PACK',
                             'PACKITEM',
                             'item:'||L_item.item);
            close C_CHK_PACK;

            if L_found is NULL then
               SQL_LIB.SET_MARK('OPEN',
                                'C_GET_COMP',
                                'PACKITEM',
                                'item:'||L_item.item);
               open C_GET_COMP;

               SQL_LIB.SET_MARK('FETCH',
                                'C_GET_COMP',
                                'PACKITEM',
                                'item:'||L_item.item);
               fetch C_GET_COMP into L_comp_item;

               SQL_LIB.SET_MARK('CLOSE',
                                'C_GET_COMP',
                                'PACKITEM',
                                'item:'||L_item.item);
               close C_GET_COMP;

               if L_comp_item is NOT NULL then
                  if TSL_DEACTIVATE_SQL.GET_ITEMS (O_error_message,
                                                   L_depend_item_tbl,
                                                   L_comp_item) = FALSE then
                     return FALSE;
                  end if;
               end if;
            end if;

            if L_depend_item_tbl is NOT NULL and L_depend_item_tbl.COUNT > 0 then
               FOR i in L_depend_item_tbl.FIRST..L_depend_item_tbl.LAST
               LOOP
                  update item_master
                     set tsl_deactivate_date = (select vdate + 1
                                                  from period)
                   where item = L_depend_item_tbl(i).item
                     and L_depend_item_tbl(i).status = 'A';
               END LOOP;
            end if;
      end if;
         -- 11-May-2009 Tesco HSC/Usha Patil                Mod:CR214 End

      else
      --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, End
        -- 11-May-2009 Tesco HSC/Usha Patil                Mod:CR214 Begin
         if (L_item.item_level <= L_item.tran_level and L_item.pack_ind = 'N') then
            if TSL_DEACTIVATE_SQL.GET_ITEMS (O_error_message,
                                             L_item_tbl,
                                             L_item.item) = FALSE then
               return FALSE;
            end if;
            if L_item_tbl is NOT NULL and L_item_tbl.COUNT > 0 then
               FOR i in L_item_tbl.FIRST..L_item_tbl.LAST
               LOOP
                   if L_item_tbl(i).status <> 'A' then
                      if L_item_tbl(i).item_level = 2
                      and L_item_tbl(i).pack_ind = 'N'
                      and L_item_tbl(i).item = L_item_tbl(i).tsl_base_item then
                        L_delete_order := 2;
                      --08-Sep-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014580 Begin
                      elsif L_item_tbl(i).item_level < L_item_tbl(i).tran_level then
                        L_delete_order := 3;
                      --08-Sep-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014580 End
                      end if;

                      --08-Sep-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014580 Begin
                      if L_item_tbl(i).item_level <= L_item_tbl(i).tran_level then
                      --08-Sep-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014580 End
                         SQL_LIB.SET_MARK('INSERT',
                                          NULL,
                                          'daily_purge',
                                          'I_item ' || L_item_tbl(i).item);
                         insert into daily_purge(key_value,
                                                 table_name,
                                                 delete_type,
                                                 delete_order)
                                          values(L_item_tbl(i).item,
                                                 I_table_name,
                                                 I_delete_type,
                                                 L_delete_order);
                      --08-Sep-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014580 Begin
                      end if;
                      --08-Sep-2009 Tesco HSC/Usha Patil            Defect Id: NBS00014580 End
                   end if;
                   L_delete_order := 1;
               END LOOP;
            end if;
         end if;

         --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, Begin
         if ((L_item.status = 'A' and
              L_item.tsl_deactivate_date is NOT NULL and
              NVL(L_item.tsl_Deactivated, 'N') = 'Y') or
             (L_item.status in ('W','S') and
              NVL(L_item.tsl_Deactivated, 'N') = 'N'))then
         --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, End
           SQL_LIB.SET_MARK('OPEN',
                            'C_CHK_DLY_PRG',
                            'DAILY_PURGE',
                            'item:'||I_key_value);
           open C_CHK_DLY_PRG;

           SQL_LIB.SET_MARK('FETCH',
                            'C_CHK_DLY_PRG',
                            'DAILY_PURGE',
                            'item:'||I_key_value);
           fetch C_CHK_DLY_PRG into L_dummy;

           SQL_LIB.SET_MARK('CLOSE',
                            'C_CHK_DLY_PRG',
                            'DAILY_PURGE',
                            'item:'||I_key_value);
           close C_CHK_DLY_PRG;
           if L_dummy is NULL then
           -- 11-May-2009 Tesco HSC/Usha Patil                Mod:CR214 End
              SQL_LIB.SET_MARK('INSERT',
                               NULL,
                               'item_master',
                               'I_item ' || I_key_value);

              insert into daily_purge(key_value,
                                      table_name,
                                      delete_type,
                                      delete_order)
                               values(I_key_value,
                                      I_table_name,
                                      I_delete_type,
                                      I_delete_order);
           -- 11-May-2009 Tesco HSC/Usha Patil                Mod:CR214 Begin
           end if;
           -- 11-May-2009 Tesco HSC/Usha Patil                Mod:CR214 End
         --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, Begin
         end if;
         --CR224b, Nitin Kumar, nitin.kumar@in.tesco.com, 26-Mar-2009, End
      end if;
   --17-MAR-2008    Wipro/JK  ModN126   End

   else
      insert into daily_purge(key_value,
                              table_name,
                              delete_type,
                              delete_order)
                       values(I_key_value,
                              I_table_name,
                              I_delete_type,
                              I_delete_order);
   end if;
   return TRUE;

EXCEPTION
   --17-MAR-2008    Wipro/JK  ModN126   Begin
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_MASTER',
                                            'DAILY_PURGE_SQL.INSERT_RECORD',
                                            'ITEM: ' ||I_key_value);
      return FALSE;
   --17-MAR-2008    Wipro/JK  ModN126   End
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DAILY_PURGE_SQL.INSERT_RECORD',
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_RECORD;
----------------------------------------------------------------------------------------
FUNCTION ITEM_PARENT_GRANDPARENT_EXIST(O_error_message IN OUT VARCHAR2,
                                       O_exists        IN OUT BOOLEAN,
                                       I_item          IN     ITEM_MASTER.ITEM%TYPE,
                                       I_table_name    IN     DAILY_PURGE.TABLE_NAME%TYPE)
   RETURN BOOLEAN IS

   L_dummy    VARCHAR2(1)  := 'N';

   cursor C_EXISTS is
      select *
        from (select 'Y'
                from daily_purge dp
               where I_item = dp.key_value
                 and table_name = I_table_name
                 and rownum = 1
               UNION
              select 'Y'
                from daily_purge dp,
                     item_master im
               where ((I_item = im.item and im.item_parent = dp.key_value)
                  or (I_item = im.item and im.item_grandparent = dp.key_value))
                 and table_name = I_table_name
                 and rownum = 1)
       where rownum = 1;

BEGIN

   open C_EXISTS;
   fetch C_EXISTS into L_dummy;
   close C_EXISTS;

   if L_dummy = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DAILY_PURGE_SQL.ITEM_PARENT_GRANDPARENT_EXIST',
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_PARENT_GRANDPARENT_EXIST;
----------------------------------------------------------------------------------------
FUNCTION UPDATE_ITEM_STATUS(O_error_message  IN OUT VARCHAR2,
                            I_item           IN     ITEM_MASTER.ITEM%TYPE)
     RETURN BOOLEAN IS
     RECORD_LOCKED   EXCEPTION;
     PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
     LP_table        VARCHAR2(50);
 cursor C_LOCK_ITEM_MASTER is
    select 'x'
      from item_master
     where item = I_item
        or item_parent = I_item
        or item_grandparent = I_item
       for update nowait;

   --27-May-2009 Tesco HSC/Usha Patil             Defect Id:NBS00013080 Begin
   cursor C_UPDATE_PACK_STATUS is
   select pi.pack_no
     from packitem pi,
          item_master im
    where im.item = pi.item
      and im.item_parent = I_item;

   TYPE UPDATE_PACK_STATUS_TBL is TABLE OF C_UPDATE_PACK_STATUS%ROWTYPE
      INDEX BY BINARY_INTEGER;
   L_update_pack_status_tbl  UPDATE_PACK_STATUS_TBL;

   cursor C_ITEM_MASTER_LOCK(L_item ITEM_MASTER.ITEM%TYPE) is
   select 'x'
     from item_master
    where item = L_item
      for update nowait;
   --27-May-2009 Tesco HSC/Usha Patil             Defect Id:NBS00013080 End

 BEGIN
      LP_table := 'ITEM_MASTER';
      open C_LOCK_ITEM_MASTER;
      close C_LOCK_ITEM_MASTER;

   --27-May-2009 Tesco HSC/Usha Patil             Defect Id:NBS00013080 Begin
   open C_UPDATE_PACK_STATUS;
   fetch C_UPDATE_PACK_STATUS bulk collect into L_update_pack_status_tbl;
   close C_UPDATE_PACK_STATUS;

   if L_update_pack_status_tbl is NOT NULL and L_update_pack_status_tbl.COUNT > 0 then
      FOR i IN L_update_pack_status_tbl.FIRST..L_update_pack_status_tbl.LAST
      LOOP
         open C_ITEM_MASTER_LOCK(L_update_pack_status_tbl(i).pack_no);
         close C_ITEM_MASTER_LOCK;

         SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_MASTER', 'ITEM: '||L_update_pack_status_tbl(i).pack_no);

         update item_master
            set status = 'W'
          where item = L_update_pack_status_tbl(i).pack_no
             or item_parent =L_update_pack_status_tbl(i).pack_no;
      END LOOP;
   end if;
   --27-May-2009 Tesco HSC/Usha Patil             Defect Id:NBS00013080 End

      SQL_LIB.SET_MARK('UPDATE', NULL, 'ITEM_MASTER', 'ITEM: '||i_item);

      update item_master
         set status = 'W'
       where item_grandparent = I_item;
      update item_master
      set status = 'W'
       where item_parent = I_item;
      update item_master
      set status = 'W'
       where item = I_item;
      return TRUE;
 EXCEPTION

    when RECORD_LOCKED then
       O_error_message := sql_lib.create_msg('RECORD_LOCKED',
                                             LP_table,
                                             I_item,
                                             NULL);
       return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DAILY_PURGE_SQL.ITEM_STATUS',
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_ITEM_STATUS;
----------------------------------------------------------------------------------------
FUNCTION CONTENTS_ITEM_EXISTS(O_error_message  IN OUT VARCHAR2,
                              O_exists         IN OUT BOOLEAN,
                              I_item           IN     ITEM_MASTER.ITEM%TYPE)
     RETURN BOOLEAN IS

 L_dummy   VARCHAR2(1);

 cursor C_CHECK_CONTENTS_ITEM is
    select 'x'
      from item_master im
     where im.container_item = I_item
       and im.item not in(select key_value
                            from daily_purge
                           where key_value = im.item
                             and table_name = 'ITEM_MASTER')
       and rownum = 1;
 BEGIN

      open   C_CHECK_CONTENTS_ITEM;
      fetch  C_CHECK_CONTENTS_ITEM into L_dummy;
      close  C_CHECK_CONTENTS_ITEM;

      if L_dummy is not null then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;

      return TRUE;
 EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DAILY_PURGE_SQL.CONTENTS_ITEM_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;
END CONTENTS_ITEM_EXISTS;
-----------------------------------------------------------------------------------------------
FUNCTION REF_ITEM_COUNT(O_error_message  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        O_rec_count      IN OUT   NUMBER,
                        I_item           IN       ITEM_MASTER.ITEM%TYPE,
                        I_table_name     IN       DAILY_PURGE.TABLE_NAME%TYPE)
   RETURN BOOLEAN IS

   L_rec_count    NUMBER  := 0;
   L_program      VARCHAR2(64) := 'DAILY_PURGE_SQL.REF_ITEM_COUNT';

   cursor C_COUNT is
      select count(*)
        from item_master
       where item_parent = I_item
         and item_level  > tran_level
         and item not in ( select key_value
                             from daily_purge dp,item_master im
                            where dp.key_value   = im.item
                              and im.item_parent = I_item
                              and dp.table_name  = I_table_name);

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_table_name is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_table_name',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNT',
                    'item_master',
                    NULL);
   open C_COUNT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNT',
                    'item_master',
                    NULL);
   fetch C_COUNT into L_rec_count;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_COUNT',
                    'item_master',
                    NULL);
   close C_COUNT;

   O_rec_count := L_rec_count;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DAILY_PURGE_SQL.REF_ITEM_COUNT',to_char(SQLCODE));
      return FALSE;
END REF_ITEM_COUNT;
-----------------------------------------------------------------------------------------------
FUNCTION CHECK_PRIMARY_REF_ITEM_IND(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                    O_exists          IN OUT   BOOLEAN,
                                    I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                    I_table_name      IN       DAILY_PURGE.TABLE_NAME%TYPE)
   RETURN BOOLEAN IS

   L_dummy    VARCHAR2(1)  := 'N';
   L_program  VARCHAR2(64) := 'DAILY_PURGE_SQL.CHECK_PRIMARY_REF_ITEM_IND';

   cursor C_EXISTS is
      select 'Y'
        from item_master
       where item_parent = I_item
         and primary_ref_item_ind = 'Y'
         and item in ( select dp.key_value
                             from daily_purge dp,item_master im
                        where dp.key_value   = im.item
                          and im.item_parent = I_item
                          and dp.table_name  = I_table_name)
         and rownum = 1;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_table_name is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_table_name',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'item_master',
                    NULL);
   open C_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'item_master',
                    NULL);
   fetch C_EXISTS into L_dummy;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'item_master',
                    NULL);
   close C_EXISTS;

   if L_dummy = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DAILY_PURGE_SQL.CHECK_PRIMARY_REF_ITEM_IND',
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_PRIMARY_REF_ITEM_IND;
----------------------------------------------------------------------------------------
FUNCTION ALL_RECORDS_DELETED(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists        IN OUT BOOLEAN,
                             I_item          IN     ITEM_MASTER.ITEM%TYPE,
                             I_table_name    IN     DAILY_PURGE.TABLE_NAME%TYPE)
   RETURN BOOLEAN IS

   L_dummy    VARCHAR2(1)  := 'N';
   L_program  VARCHAR2(64) := 'DAILY_PURGE_SQL.ALL_RECORDS_DELETED';

   cursor C_EXISTS is
      select 'Y'
        from item_master
       where item_parent = I_item
         and item not in (select dp.key_value
                            from daily_purge dp,
                                 item_master im
                           where dp.key_value   = im.item
                             and im.item_parent = I_item
                             and dp.table_name  = I_table_name)
         and rownum = 1;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_table_name is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_table_name',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'item_master',
                    NULL);
   open C_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'item_master',
                    NULL);
   fetch C_EXISTS into L_dummy;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'item_master',
                    NULL);
   close C_EXISTS;

   if L_dummy = 'Y' then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DAILY_PURGE_SQL.ALL_RECORDS_DELETED',
                                            to_char(SQLCODE));
      return FALSE;
END ALL_RECORDS_DELETED;
----------------------------------------------------------------------------------------
--07-Aug-2008   WiproEnabler/Karthik   DefNBS00003210   Begin
----------------------------------------------------------------------------------------
FUNCTION INSERT_RECORD_FOR_ITEMMASTER (O_error_message  IN OUT VARCHAR2,
                                       I_key_value      IN     DAILY_PURGE.KEY_VALUE%TYPE,
                                       I_table_name     IN     DAILY_PURGE.TABLE_NAME%TYPE,
                                       I_delete_type    IN     DAILY_PURGE.DELETE_TYPE%TYPE,
                                       I_delete_order   IN     DAILY_PURGE.DELETE_ORDER%TYPE)
   return BOOLEAN is

   L_program    VARCHAR2(64)  := 'DAILY_PURGE_SQL.INSERT_RECORD_FOR_ITEMMASTER';

BEGIN

   if I_key_value is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_key_value',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_table_name is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_table_name',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_delete_type is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_delete_type',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_delete_order is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_delete_order',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_table_name = 'ITEM_MASTER' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'item_master',
                       'I_item ' || I_key_value);

      insert into daily_purge(key_value,
                              table_name,
                              delete_type,
                              delete_order)
                       values(I_key_value,
                              I_table_name,
                              I_delete_type,
                              I_delete_order);

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_RECORD_FOR_ITEMMASTER;
--06-Aug-2008   WiproEnabler/Karthik   DefNBS00003210   End
----------------------------------------------------------------------------------------
--22-Mar-2010   Tesco HSC/Nandini M    Mod CR224b       Begin
----------------------------------------------------------------------------------------
--  Function Name : TSL_CANCEL_DELETE
--  Purpose       : This function will revert back the daily_purge changes
--                  once the user clicks Cancel Delete operation.
----------------------------------------------------------------------------------------
FUNCTION TSL_CANCEL_DELETE (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_key_value      IN     DAILY_PURGE.KEY_VALUE%TYPE)
   return BOOLEAN is

   L_program          VARCHAR2(64)  := 'DAILY_PURGE_SQL.TSL_CANCEL_DELETE';
   L_item_tbl         TSL_DEACTIVATE_SQL.ITEM_API_TBLTYPE;
   L_item             ITEM_MASTER.ITEM%TYPE;
   L_variant_item     ITEM_MASTER.ITEM%TYPE;
   L_item_rec         ITEM_MASTER%ROWTYPE;
   L_item_fetch       ITEM_MASTER.ITEM%TYPE;
   L_comp_item        PACKITEM.ITEM%TYPE := NULL;

   cursor C_GET_COMP(Cp_item PACKITEM.PACK_NO%TYPE) is
   select pai.item
     from packitem pai,
          item_master iem
    where pai.pack_no = Cp_item
      and iem.item = pai.item
      and iem.pack_ind = 'N';

   cursor C_COMP_EXISTS is
   select 'X'
     from daily_purge dp
    where dp.key_value = L_comp_item;

   CURSOR C_LOCK_DAILY_PURGE(Cp_item DAILY_PURGE.KEY_VALUE%TYPE) is
   select 'X'
    from daily_purge
   where key_value  = Cp_item
     and table_name = 'ITEM_MASTER'
   for update nowait;

   CURSOR C_GET_BASE_ITEMS(Cp_Item ITEM_MASTER.ITEM%TYPE) is
   select im.tsl_base_item
     from item_master im
    where im.item = Cp_item
      and im.item != im.tsl_base_item
      and im.item_level = im.tran_level
      and im.pack_ind = 'N';

BEGIN

   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_rec,
                                      I_key_value) = FALSE then
      return FALSE;
   end if;

   if L_item_rec.pack_ind = 'Y'  then
      if L_item_rec.item_level = 1 then
         L_item_fetch := L_item_rec.item;
      elsif L_item_rec.item_level = 2 then
         L_item_fetch := L_item_rec.item_parent;
      end if;
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_COMP',
                       'ITEM_MASTER'||'PACKITEM',
                       'ITEM: '||L_item_rec.item_parent);
      open C_GET_COMP(L_item_fetch);

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_COMP',
                       'ITEM_MASTER'||'PACKITEM',
                       'ITEM: '||L_item_rec.item_parent);
      fetch C_GET_COMP into L_comp_item;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_COMP',
                       'ITEM_MASTER'||'PACKITEM',
                       'ITEM: '||L_item_rec.item_parent);
      close C_GET_COMP;

      SQL_LIB.SET_MARK('OPEN',
                       'C_COMP_EXISTS',
                       'DAILY_PURGE',
                       'ITEM: '||L_comp_item);
      open C_COMP_EXISTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_COMP_EXISTS',
                       'DAILY_PURGE',
                       'ITEM: '||L_comp_item);
      fetch C_COMP_EXISTS into L_comp_item;

      if L_comp_item is NOT NULL and C_COMP_EXISTS%FOUND then
         O_error_message := sql_lib.create_msg('TSL_CANNOT_DEL_PACK',
                                               'I_key_value',
                                               'NULL',
                                               'NULL');
            return FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_COMP_EXISTS',
                       'DAILY_PURGE',
                       'ITEM: '||L_comp_item);
      close C_COMP_EXISTS;

   end if;
      --Get the items list that for which deletion needs to be cancel
      L_item_tbl.delete; -- Intialize the record type

      if (L_item_rec.item_level < L_item_rec.tran_level and L_item_rec.pack_ind = 'N') or
         (L_item_rec.item_level = L_item_rec.tran_level and L_item_rec.pack_ind = 'Y') then
         L_item_tbl(1).item := L_item_rec.item;
      elsif (L_item_rec.item_level = L_item_rec.tran_level and L_item_rec.pack_ind = 'N') then--TPNB/Variant
         if L_item_rec.item = L_item_rec.tsl_base_item then -- Its a Base item
            L_item_tbl(1).item := L_item_rec.item;
            L_item_tbl(2).item := L_item_rec.item_parent;
         end if;
         if L_item_rec.item != L_item_rec.tsl_base_item then -- Its a Variant item
            L_item_tbl(1).item := L_item_rec.item;
            L_item_tbl(2).item := L_item_rec.item_parent;
            L_item_tbl(3).item := L_item_rec.tsl_base_item;
         end if;
      elsif L_item_rec.item_level > L_item_rec.tran_level then
         L_item_tbl(1).item := L_item_rec.item;
         L_item_tbl(2).item := L_item_rec.item_parent;
         if L_item_rec.pack_ind = 'N' then
            L_item_tbl(3).item := L_item_rec.item_grandparent;
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_BASE_ITEMS',
                             'ITEM_MASTER',
                             'ITEM: '||L_item_rec.item_parent);
            open C_GET_BASE_ITEMS(L_item_rec.item_parent);

            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_BASE_ITEMS',
                             'ITEM_MASTER',
                             'ITEM: '||L_item_rec.item_parent);
            fetch C_GET_BASE_ITEMS into L_variant_item;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_BASE_ITEMS',
                             'ITEM_MASTER',
                             'ITEM: '||L_item_rec.item_parent);
            close C_GET_BASE_ITEMS ;
            if L_variant_item is NOT NULL then
               L_item_tbl(4).item := L_variant_item;
            end if;
         end if;
      end if;
      --
      if L_item_tbl is NOT NULL and L_item_tbl.COUNT > 0 then
         FOR i in L_item_tbl.FIRST..L_item_tbl.LAST
         LOOP
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_DAILY_PURGE',
                             'DAILY_PURGE',
                              L_item_tbl(i).item);
            open C_LOCK_DAILY_PURGE(L_item_tbl(i).item);

            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_DAILY_PURGE',
                             'DAILY_PURGE',
                              L_item_tbl(i).item);
            close C_LOCK_DAILY_PURGE;

            delete from daily_purge
                  where key_value  = L_item_tbl(i).item
                    and table_name = 'ITEM_MASTER'
                    and exists (select 'X'
                                  from item_master im
                                 where im.item = L_item_tbl(i).item
                                   and im.status in ('W','S'));
         END LOOP;
      end if;
      --

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_CANCEL_DELETE;
----------------------------------------------------------------------------------------
--22-Mar-2010   Tesco HSC/Nandini M    Mod CR224b       End
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- CR495, 04-March-2014, Smitha Ramesh, smitharamesh.areyada@in.tesco.com (BEGIN)
----------------------------------------------------------------------------------------
-- Function : TSL_DELETE_RECORD
-- Purpose  : This is a new function which will be used to delete the
--            item from the daily purge table once it has been moved/exchanged to a live parent
-----------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_RECORD(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item         IN     ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_program         VARCHAR2(50) := 'DAILY_PURGE_SQL.TSL_DELETE_RECORD';
   L_key_value       DAILY_PURGE.KEY_VALUE%TYPE;

  cursor C_LOCK is
   select key_value
      from daily_purge
      where key_value = I_item
      for update nowait;

BEGIN

    SQL_LIB.SET_MARK('OPEN',
                     'C_LOCK',
                     'DAILY_PURGE',
                     'NULL');
    open C_LOCK;
    SQL_LIB.SET_MARK('FETCH',
                     'C_LOCK',
                     'DAILY_PURGE',
                     'NULL');
    fetch C_LOCK into L_key_value;
    if C_LOCK%found then
       delete from daily_purge where key_value = I_item;
    end if;
    SQL_LIB.SET_MARK('CLOSE',
                     'C_LOCK',
                     'DAILY_PURGE',
                     'NULL');
    close C_LOCK;

    return TRUE;
EXCEPTION
    when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_DELETE_RECORD;
-------------------------------------------------------------------------
--CR495, 04-March-2014, Smitha Ramesh, smitharamesh.areyada@in.tesco.com (END)
-------------------------------------------------------------------------
END DAILY_PURGE_SQL;
/

