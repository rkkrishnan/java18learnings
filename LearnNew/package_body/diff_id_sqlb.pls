CREATE OR REPLACE PACKAGE BODY DIFF_ID_SQL AS

FUNCTION CHECK_DELETE (O_error_message          IN OUT    VARCHAR2,
                       O_items_exist            IN OUT    BOOLEAN,
                       O_group_details_exist    IN OUT    BOOLEAN,
                       O_range_details_exist    IN OUT    BOOLEAN,
                       I_diff_id                IN        DIFF_IDS.DIFF_ID%TYPE)
   RETURN BOOLEAN IS

   cursor C_ITEM_MASTER is
   select 'Y'
     from item_master
    where diff_1 = I_diff_id
       OR diff_2 = I_diff_id
       OR diff_3 = I_diff_id
       OR diff_4 = I_diff_id;

   cursor C_DIFF_GROUP_DETAIL is
   select 'Y'
     from diff_group_detail
    where diff_id = I_diff_id;

   cursor C_DIFF_RANGE_DETAIL is
   select 'Y'
     from diff_range_detail
    where (diff_1 = I_diff_id or
           diff_2 = I_diff_id or
           diff_3 = I_diff_id);

   L_dummy1 VARCHAR2(1)   := NULL;
   L_dummy2 VARCHAR2(1)   := NULL;
   L_dummy3 VARCHAR2(1)   := NULL;
   L_program VARCHAR2(65) := 'DIFF_ID_SQL.CHECK_DELETE';

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_ITEM_MASTER','item_master','diff_id:'||I_diff_id);
   open C_ITEM_MASTER;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_MASTER','item_master','diff_id:'||I_diff_id);
   fetch C_ITEM_MASTER into L_dummy1;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_MASTER','item_master','diff_id:'||I_diff_id);
   close C_ITEM_MASTER;


   SQL_LIB.SET_MARK('OPEN','C_DIFF_GROUP_DETAIL','diff_group_detail','diff_id:'||I_diff_id);
   open C_DIFF_GROUP_DETAIL;
   SQL_LIB.SET_MARK('FETCH','C_DIFF_GROUP_DETAIL','diff_group_detail','diff_id:'||I_diff_id);
   fetch C_DIFF_GROUP_DETAIL into L_dummy2;
   SQL_LIB.SET_MARK('CLOSE','C_DIFF_GROUP_DETAIL','diff_group_detail','diff_id:'||I_diff_id);
   close C_DIFF_GROUP_DETAIL;

   SQL_LIB.SET_MARK('OPEN','C_DIFF_RANGE_DETAIL','diff_range_detail','diff_id:'||I_diff_id);
   open C_DIFF_RANGE_DETAIL;
   SQL_LIB.SET_MARK('FETCH','C_DIFF_RANGE_DETAIL','diff_range_detail','diff_id:'||I_diff_id);
   fetch C_DIFF_RANGE_DETAIL into L_dummy3;
   SQL_LIB.SET_MARK('CLOSE','C_DIFF_RANGE_DETAIL','diff_range_detail','diff_id:'||I_diff_id);
   close C_DIFF_RANGE_DETAIL;

   O_items_exist := FALSE;
   O_group_details_exist := FALSE;
   O_range_details_exist := FALSE;

   if L_dummy1 = 'Y' then
         O_items_exist := TRUE;
   end if;

   if L_dummy2 = 'Y' then
         O_group_details_exist := TRUE;
   end if;

   if L_dummy3 = 'Y' then
         O_range_details_exist := TRUE;
   end if;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         to_char(SQLCODE));
    RETURN FALSE;

END CHECK_DELETE;

----------------------------------------------------------------------------------------------------
FUNCTION DIFF_ID_EXISTS (O_error_message   IN OUT   VARCHAR2,
                         O_exists                   IN OUT  BOOLEAN,
                         I_diff_id                  IN      DIFF_IDS.DIFF_ID%TYPE)

   RETURN BOOLEAN IS

   cursor C_DIFF_ID_EXISTS is
     select  'Y'
       from  diff_ids
      where  diff_id       = I_diff_id
      union  all
     select  'Y'
       from  diff_group_head
      where  diff_group_id = I_diff_id;

   L_dummy VARCHAR2(1) := 'X';
   L_program VARCHAR2(65) := 'DIFF_ID_SQL.DIFF_ID_EXISTS';

   BEGIN

    SQL_LIB.SET_MARK('OPEN',
                     'C_DIFF_ID_EXISTS',
                     'diff_ids',
                     'diff_id:'||I_diff_id);
   open C_DIFF_ID_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                     'C_DIFF_ID_EXISTS',
                     'diff_ids',
                     'diff_id:'||I_diff_id);
   fetch C_DIFF_ID_EXISTS into L_dummy;

   SQL_LIB.SET_MARK('CLOSE',
                     'C_DIFF_ID_EXISTS',
                     'diff_ids',
                     'diff_id:'||I_diff_id);
   close C_DIFF_ID_EXISTS;

   if L_dummy = 'Y' then
     O_exists:= TRUE;
   else
     O_exists:= FALSE;
   end if;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         to_char(SQLCODE));
    RETURN FALSE;

END DIFF_ID_EXISTS;
-------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------
   -- PRIVATE FUNCTION SPECS
-------------------------------------------------------------------------------------------------------
   -- Function Name: LOCK_DIFF_IDS
   -- Purpose      : This function will lock the DIFF_IDS table for update or delete.
-------------------------------------------------------------------------------------------------------
FUNCTION LOCK_DIFF_ID(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      I_diffid          IN       DIFF_IDS.DIFF_ID%TYPE)
   RETURN BOOLEAN;
-------------------------------------------------------------------------------------------------------
FUNCTION LOCK_DIFF_ID(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      I_diffid          IN       DIFF_IDS.DIFF_ID%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50)  := 'DIFF_ID_SQL.LOCK_DIFF_ID';
   L_table        VARCHAR2(10)  := 'DIFF_IDS';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DIFF_ID IS
      select 'x'
        from DIFF_IDS
       where diff_id = I_diffid
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_DIFF_ID', 'DIFF_IDS', 'diff_id: '||I_diffid);
   open C_LOCK_DIFF_ID;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_DIFF_ID', 'DIFF_IDS', 'diff_id: '||I_diffid);
   close C_LOCK_DIFF_ID;

   ---
   return TRUE;
EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('DELRECS_REC_LOC',
                                            L_table,
                                            'DIFF_IDS'||I_diffid,
                                            NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END LOCK_DIFF_ID;
----------------------------------------------------------------------------------------------
FUNCTION INSERT_DIFFID(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_diffid_rec      IN       DIFF_IDS%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DIFF_ID_SQL.INSERT_DIFFID';

BEGIN
   SQL_LIB.SET_MARK('INSERT', NULL, 'DIFF_IDS', 'diff_id: '||I_diffid_rec.diff_id);
   insert into DIFF_IDS (diff_id,
                         diff_type,
                         diff_desc,
                         industry_code,
                         industry_subgroup,
                         create_datetime,
                         last_update_id,
                         last_update_datetime)
                 values (I_diffid_rec.diff_id,
                         I_diffid_rec.diff_type,
                         I_diffid_rec.diff_desc,
                         I_diffid_rec.industry_code,
                         I_diffid_rec.industry_subgroup,
                         I_diffid_rec.create_datetime,
                         I_diffid_rec.last_update_id,
                         I_diffid_rec.last_update_datetime);
   ---
   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_INSERT_REC');
      return FALSE;
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

END INSERT_DIFFID;
-------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_DIFFID(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_diffid_rec      IN       DIFF_IDS%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DIFF_ID_SQL.UPDATE_DIFF_ID';

BEGIN
   if not LOCK_DIFF_ID(O_error_message,
                       I_diffid_rec.diff_id) then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('UPDATE', NULL, 'DIFF_IDS', 'diff_id: '||I_diffid_rec.diff_id);
   update DIFF_IDS
      set diff_desc            = NVL(I_diffid_rec.diff_desc, diff_desc),
          industry_code        = NVL(I_diffid_rec.industry_code, industry_code),
          industry_subgroup    = NVL(I_diffid_rec.industry_subgroup, industry_subgroup),
          last_update_id       = NVL(I_diffid_rec.last_update_id, last_update_id),
          last_update_datetime = NVL(I_diffid_rec.last_update_datetime, last_update_datetime)
    where diff_id = I_diffid_rec.diff_id;
   ---
   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_UPDATE_REC');
      return FALSE;
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

END UPDATE_DIFFID;
-------------------------------------------------------------------------------------------------------
FUNCTION DELETE_DIFFID(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_diffid_rec      IN       DIFF_IDS%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DIFF_ID_SQL.DELETE_DIFF_ID';

BEGIN
   if not LOCK_DIFF_ID(O_error_message,
                       I_diffid_rec.diff_id) then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('DELETE', NULL, 'DIFF_IDS', 'diff_id: '||I_diffid_rec.diff_id);
   delete from DIFF_IDS
    where diff_id = I_diffid_rec.diff_id;
   ---
   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_RECORDS');
      return FALSE;
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

END DELETE_DIFFID;
-------------------------------------------------------------------------------------------------------
END DIFF_ID_SQL;
/

