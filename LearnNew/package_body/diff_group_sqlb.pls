CREATE OR REPLACE PACKAGE BODY DIFF_GROUP_SQL AS
----------------------------------------------------------------------------
FUNCTION EXIST(O_error_message   IN OUT VARCHAR2,
               O_exist           IN OUT BOOLEAN,
               I_diff_group_id   IN     DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(64)      := 'DIFF_GROUP_SQL.EXIST';
   L_exist       VARCHAR2(1)       := NULL;

   cursor C_EXIST is
      select 'x'
        from diff_group_head
       where diff_group_id = I_diff_group_id
       union all
      select 'x'
        from diff_ids
       where diff_id = I_diff_group_id;

BEGIN

   if I_diff_group_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_diff_group_id', L_program, NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_EXIST', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
   open C_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_EXIST', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
   fetch C_EXIST into L_exist;
   ---
   if C_EXIST%NOTFOUND then
      O_exist := FALSE;
   else
      O_exist := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_EXIST', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
   close C_EXIST;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, TO_CHAR(SQLCODE));
      return FALSE;
END EXIST;
----------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message   IN OUT VARCHAR2,
                  O_group_desc      IN OUT DIFF_GROUP_HEAD.DIFF_GROUP_DESC%TYPE,
                  O_diff_type       IN OUT DIFF_GROUP_HEAD.DIFF_TYPE%TYPE,
                  I_diff_group_id   IN     DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE,
                  I_diff_1	         IN     ITEM_MASTER.DIFF_1%TYPE DEFAULT NULL,
                  I_diff_2          IN     ITEM_MASTER.DIFF_2%TYPE DEFAULT NULL,
                  I_diff_3          IN     ITEM_MASTER.DIFF_3%TYPE DEFAULT NULL,
                  I_diff_4          IN     ITEM_MASTER.DIFF_4%TYPE DEFAULT NULL
                  )
RETURN BOOLEAN IS

   L_program     VARCHAR2(64)      := 'DIFF_GROUP_SQL.GET_INFO';

   cursor C_GET_INFO is
      select diff_group_desc,
             diff_type
        from diff_group_head
       where diff_group_id = I_diff_group_id
       and diff_group_id in (I_diff_1,
                             I_diff_2,
                             I_diff_3,
                             I_diff_4);
        cursor C_GET_INFO_DIFF is
             select diff_group_desc,
                    diff_type
               from diff_group_head
       where diff_group_id = I_diff_group_id;
BEGIN

   if I_diff_group_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_diff_group_id', L_program, NULL);
      return FALSE;
   end if;
   ---
   if I_diff_1 is not null then
      SQL_LIB.SET_MARK('OPEN', 'C_GET_INFO', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
      open C_GET_INFO;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_GET_INFO', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
      fetch C_GET_INFO into O_group_desc,
                            O_diff_type;
      ---
      if C_GET_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_DIFF_GROUP', NULL, NULL, NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_INFO', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
      close C_GET_INFO;
      return FALSE;
      end if;
      --
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_INFO', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
      close C_GET_INFO;
      ---
   elsif I_diff_1 is null then
      SQL_LIB.SET_MARK('OPEN', 'C_GET_INFO_DIFF', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
      open C_GET_INFO_DIFF;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_GET_INFO_DIFF', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
      fetch C_GET_INFO_DIFF into O_group_desc,
                                 O_diff_type;
      ---
      if C_GET_INFO_DIFF%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_DIFF_GROUP', NULL, NULL, NULL);
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_INFO_DIFF', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
         close C_GET_INFO_DIFF;
         return FALSE;
      end if;
      --
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_INFO_DIFF', 'DIFF_GROUP_HEAD', 'DIFF_GROUP_ID: '||I_diff_group_id);
      close C_GET_INFO_DIFF;
      ---
   end if;
   if LANGUAGE_SQL.TRANSLATE(O_group_desc,
                             O_group_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, TO_CHAR(SQLCODE));
      return FALSE;
END GET_INFO;
----------------------------------------------------------------------------
FUNCTION CHECK_DELETE(O_error_message  IN OUT VARCHAR2,
                      O_exists         IN OUT BOOLEAN,
                      I_diff_group_id  IN     DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(64)      := 'DIFF_GROUP_SQL.CHECK_DELETE';
   L_dummy        VARCHAR2(1);


   cursor C_CHECK_DELETE is
      select 'x'
        from diff_group_head dgh
       where dgh.diff_group_id = I_diff_group_id
         and (exists (select 'x'
                       from item_master im
                      where (im.diff_1 = dgh.diff_group_id)
                         or (im.diff_2 = dgh.diff_group_id)
                         or (im.diff_3 = dgh.diff_group_id)
                         or (im.diff_4 = dgh.diff_group_id))
                  or exists (select 'x'
                       from diff_range_head drh
                      where (drh.diff_group_1 = dgh.diff_group_id)
                         or (drh.diff_group_2 = dgh.diff_group_id)
                         or (drh.diff_group_3 = dgh.diff_group_id))
                  or exists (select 'x'
                       from pack_tmpl_head pth
                      where (pth.diff_group_1 = dgh.diff_group_id)
                         or (pth.diff_group_2 = dgh.diff_group_id)
                         or (pth.diff_group_3 = dgh.diff_group_id)
                         or (pth.diff_group_4 = dgh.diff_group_id)));



BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_DELETE', 'ITEM_MASTER', 'DIFF_GROUP_ID: '||I_diff_group_id);
   open C_CHECK_DELETE;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_CHECK_DELETE', 'ITEM_MASTER', 'DIFF_GROUP_ID: '||I_diff_group_id);
   fetch C_CHECK_DELETE into L_dummy;
   ---
   if C_CHECK_DELETE %FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_DELETE', 'ITEM_MASTER', 'DIFF_GROUP_ID: '||I_diff_group_id);
   close C_CHECK_DELETE;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END CHECK_DELETE;

-----------------------------------------------------------------------------------
FUNCTION DELETE_DIFF_GROUP_DETAILS(O_error_message  IN OUT VARCHAR2,
                                   I_diff_group_id  IN     DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(64)      := 'DIFF_GROUP_SQL.DELETE_DIFF_GROUP_DETAILS';
   L_table        VARCHAR2(50)      := 'DIFF_GROUP_DETAIL';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DETAIL is
      select 'x'
        from diff_group_detail
       where diff_group_id = I_diff_group_id
         for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_DETAIL', 'diff_group_detail', 'diff_group_id: '||I_diff_group_id);
   open C_LOCK_DETAIL;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_DETAIL', 'diff_group_detail', 'diff_group_id: '||I_diff_group_id);
   close C_LOCK_DETAIL;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL, 'diff_group_detail', 'diff_group_id :'||I_diff_group_id);
   delete from diff_group_detail
    where diff_group_id = I_diff_group_id;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('RECORD_LOCKED',
                                            L_table,
                                            I_diff_group_id,
                                            NULL);
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END DELETE_DIFF_GROUP_DETAILS;
-----------------------------------------------------------------------------------
FUNCTION DETAILS_NO_EXIST(O_error_message  IN OUT VARCHAR2,
                          O_no_details     IN OUT BOOLEAN,
                          O_diff_group_id  IN OUT DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(64)      := 'DIFF_GROUP_SQL.DETAILS_NO_EXIST';
   L_dummy        VARCHAR2(10);

   cursor C_DETAILS_NO_EXIST is
      select diff_group_id
        from diff_group_head
       where diff_group_id NOT IN (select diff_group_id
                                     from diff_group_detail);

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_DETAILS_NO_EXIST', 'DIFF_GROUP_HEAD', NULL);
   open C_DETAILS_NO_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_DETAILS_NO_EXIST', 'DIFF_GROUP_HEAD', NULL);
   fetch C_DETAILS_NO_EXIST into L_dummy;
   ---
   if C_DETAILS_NO_EXIST%FOUND then
      O_diff_group_id := L_dummy;
      O_no_details := TRUE;
   else
      O_no_details := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_DETAILS_NO_EXIST', 'DIFF_GROUP_HEAD', NULL);
   close C_DETAILS_NO_EXIST;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END DETAILS_NO_EXIST;
------------------------------------------------------------------------------------------
FUNCTION DUP_DIFF_ID(O_error_message   IN OUT VARCHAR2,
                     O_exists          IN OUT BOOLEAN,
                     I_diff_id         IN     DIFF_GROUP_DETAIL.DIFF_ID%TYPE,
                     I_diff_group_id   IN     DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(64)      := 'DIFF_GROUP_SQL.DUP_DIFF_ID';
   L_dummy        VARCHAR2(1);

cursor C_DUP_DIFF_ID is
      select 'Y'
        from diff_group_head h
       where (diff_group_id  = I_diff_group_id
         and exists (select 'x'
                       from diff_group_detail d
                      where h.diff_group_id = d.diff_group_id
                        and diff_id = I_diff_id));
BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_DUP_DIFF_ID', 'DIFF_GROUP_HEAD',
                    'DIFF_GROUP_ID: '||I_diff_group_id||', DIFF_ID: '||I_diff_id);
   open C_DUP_DIFF_ID;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_DUP_DIFF_ID', 'DIFF_GROUP_HEAD',
                    'DIFF_GROUP_ID: '||I_diff_group_id||', DIFF_ID: '||I_diff_id);
   fetch C_DUP_DIFF_ID into L_dummy;
   ---
   if C_DUP_DIFF_ID%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_DUP_DIFF_ID', 'DIFF_GROUP_HEAD',
                    'DIFF_GROUP_ID: '||I_diff_group_id||', DIFF_ID: '||I_diff_id);
   close C_DUP_DIFF_ID;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END DUP_DIFF_ID;
---------------------------------------------------------------------------------------------
FUNCTION CHECK_DELETE_DETAILS(O_error_message   IN OUT VARCHAR2,
                              O_exists          IN OUT BOOLEAN,
                              I_diff_id         IN     DIFF_GROUP_DETAIL.DIFF_ID%TYPE,
                              I_diff_group_id   IN     DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(64)      := 'DIFF_GROUP_SQL.CHECK_DELETE_GROUP_DETAILS';
   L_dummy        VARCHAR2(1);


   cursor C_ITEM_DIFF is
      select 'x'
        from diff_group_detail dgd
       where dgd.diff_id = I_diff_id
         and dgd.diff_group_id = I_diff_group_id
         and (exists (select 'x'
                       from item_master im
                      where (   (im.diff_1 = dgd.diff_group_id)
                             or (im.diff_2 = dgd.diff_group_id)
                             or (im.diff_3 = dgd.diff_group_id)
                             or (im.diff_4 = dgd.diff_group_id))
                        and exists (select 'x'
                                      from item_master im2
                                     where im.item = im2.item_parent
                                       and (  (im2.diff_1 = dgd.diff_id)
                                           or (im2.diff_2 = dgd.diff_id)
                                           or (im2.diff_3 = dgd.diff_id)
                                           or (im2.diff_4 = dgd.diff_id))))
          or exists (select 'x'
                       from diff_range_head drh,
                            diff_range_detail drd
                      where (drh.diff_range = drd.diff_range
                        and (   (drh.diff_group_1 = dgd.diff_group_id)
                             or (drh.diff_group_2 = dgd.diff_group_id)
                             or (drh.diff_group_3 = dgd.diff_group_id))
                        and (   (drd.diff_1 = dgd.diff_id)
                             or (drd.diff_2 = dgd.diff_id)
                             or (drd.diff_3 = dgd.diff_id))))
          or exists (select 'x'
                       from pack_tmpl_head pth,
                            pack_tmpl_detail ptd
                      where (pth.pack_tmpl_id = ptd.pack_tmpl_id
                        and (   (pth.diff_group_1 = dgd.diff_group_id)
                             or (pth.diff_group_2 = dgd.diff_group_id)
                             or (pth.diff_group_3 = dgd.diff_group_id)
                             or (pth.diff_group_4 = dgd.diff_group_id))
                        and (   (ptd.diff_1 = dgd.diff_id)
                             or (ptd.diff_2 = dgd.diff_id)
                             or (ptd.diff_3 = dgd.diff_id)
                             or (ptd.diff_4 = dgd.diff_id)))));

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_ITEM_DIFF', 'ITEM_MASTER',
                    'DIFF_GROUP_ID: '||I_diff_group_id||', DIFF_ID: '||I_diff_id);
   open C_ITEM_DIFF;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM_DIFF', 'ITEM_MASTER',
                    'DIFF_GROUP_ID: '||I_diff_group_id||', DIFF_ID: '||I_diff_id);
   fetch C_ITEM_DIFF into L_dummy;
   if C_ITEM_DIFF%NOTFOUND then
      o_exists := FALSE;
   else
      o_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_DIFF', 'ITEM_MASTER',
                    'DIFF_GROUP_ID: '||I_diff_group_id||', DIFF_ID: '||I_diff_id);
   close C_ITEM_DIFF;
   return TRUE;

EXCEPTION
when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END CHECK_DELETE_DETAILS;
-----------------------------------------------------------------------------------------
FUNCTION DELETE_GRP_NO_DETAILS(O_error_message   IN OUT VARCHAR2,
                               I_diff_group_id   IN     DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
RETURN BOOLEAN IS

   L_program	VARCHAR2(64)      := 'DIFF_GROUP_SQL.DELETE_GROUP_NO_DETAILS';
   L_table        VARCHAR2(50)      := 'DIFF_GROUP_HEAD';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);


      CURSOR C_LOCK_GROUP is
      select 'x'
        from diff_group_head
       where diff_group_id = I_diff_group_id
         for update nowait;
BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_GROUP', 'diff_group_head', 'diff_group_id: '||I_diff_group_id);
   open C_LOCK_GROUP;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_GROUP', 'diff_group_head', 'diff_group_id: '||I_diff_group_id);
   close C_LOCK_GROUP;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL, 'diff_group_head', 'diff_group_id :'||I_diff_group_id);
   delete from diff_group_head
    where diff_group_id = I_diff_group_id;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('RECORD_LOCKED',
                                            L_table,
                                            I_diff_group_id,
                                            NULL);
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END DELETE_GRP_NO_DETAILS;
----------------------------------------------------------------------
FUNCTION GET_DIFF_GROUP_DETLS(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                              O_valid          IN OUT  BOOLEAN,
                              O_diff_type      IN OUT  DIFF_IDS.DIFF_TYPE%TYPE,
                              O_diff_desc      IN OUT  DIFF_IDS.DIFF_DESC%TYPE,
                              O_display_seq    IN OUT  DIFF_GROUP_DETAIL.DISPLAY_SEQ%TYPE,
                              I_diff_group     IN      DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE,
                              I_diff_id        IN      DIFF_IDS.DIFF_ID%TYPE,
                              I_item           IN      ITEM_MASTER.ITEM%TYPE DEFAULT NULL
                              )
RETURN BOOLEAN IS

   L_program VARCHAR2(100) := 'DIFF_GROUP_SQL.GET_DIFF_GROUP_DETLS';

   cursor C_GET_INFO is
   select dgh.diff_type,
          di.diff_desc,
          dgd.display_seq
     from diff_group_detail dgd,
          diff_ids di, diff_group_head dgh
    where di.diff_id = dgd.diff_id
      and dgh.diff_group_id = dgd.diff_group_id
      and dgd.diff_group_id = I_diff_group
      and di.diff_id = I_diff_id
      and (I_item is null
          or
          exists (select 1
                    from item_master im
                   where im.item_parent = I_item
                     and dgd.diff_id in (im.diff_1,im.diff_2,im.diff_3,im.diff_4)));


BEGIN
   open C_GET_INFO;
   fetch C_GET_INFO into O_diff_type,
                         O_diff_desc,
                         O_display_seq;
   close C_GET_INFO;

   if O_diff_type is NULL then
      O_valid := FALSE;
   else
      O_valid := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END GET_DIFF_GROUP_DETLS;
----------------------------------------------------------------------


---------------------------------------------------------------------------------------------
   -- PRIVATE FUNCTION SPECS
---------------------------------------------------------------------------------------------
   -- Function Name: LOCK_DIFF_GROUP
   -- Purpose      : This function will lock the DIFF_GROUP_HEAD table for update or delete.
---------------------------------------------------------------------------------------------
FUNCTION LOCK_DIFF_GROUP(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         I_diffgrp_id      IN       DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
   RETURN BOOLEAN;
---------------------------------------------------------------------------------------------
   -- Function Name: LOCK_DIFF_GROUP_DETAIL
   -- Purpose      : This function will lock the DIFF_GROUP_DETAIL table for update or delete.
---------------------------------------------------------------------------------------------
FUNCTION LOCK_DIFF_GROUP_DETAIL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                I_diffgrp_id      IN       DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE,
                                I_diff_id         IN       DIFF_GROUP_DETAIL.DIFF_ID%TYPE)
   RETURN BOOLEAN;
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
   -- PUBLIC FUNCTIONS
--------------------------------------------------------------------------------------------
FUNCTION INSERT_DIFF_GROUP(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_diff_group_rec    IN       DIFF_GROUP_SQL.DIFF_GROUP_REC)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DIFF_GROUP_SQL.INSERT_DIFF_GROUP';

BEGIN
   -- Insert Diff Group header record
   SQL_LIB.SET_MARK('INSERT', NULL, 'DIFF_GROUP_HEAD', 'diff_group_id: '||I_diff_group_rec.diff_group_head_row.diff_group_id);
   insert into DIFF_GROUP_HEAD(diff_group_id,
                               diff_type,
                               diff_group_desc,
                               create_datetime,
                               last_update_id,
                               last_update_datetime)
                       values (I_diff_group_rec.diff_group_head_row.diff_group_id,
                               I_diff_group_rec.diff_group_head_row.diff_type,
                               I_diff_group_rec.diff_group_head_row.diff_group_desc,
                               I_diff_group_rec.diff_group_head_row.create_datetime,
                               I_diff_group_rec.diff_group_head_row.last_update_id,
                               I_diff_group_rec.diff_group_head_row.last_update_datetime);

   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_INSERT_REC');
      return FALSE;
   end if;

   -- If header record was successfully inserted then insert detail records

   if not INSERT_DETAIL(O_error_message,
                        I_diff_group_rec.diff_group_details) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END INSERT_DIFF_GROUP;
---------------------------------------------------------------------------------------------
FUNCTION INSERT_DETAIL(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_diff_group_detail_tbl   IN       DIFF_GROUP_SQL.DIFF_GROUP_DETAIL_TBL)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DIFF_GROUP_SQL.INSERT_DETAIL';

BEGIN

   FOR i in I_diff_group_detail_tbl.first..I_diff_group_detail_tbl.last LOOP
      SQL_LIB.SET_MARK('INSERT', NULL, 'DIFF_GROUP_DETAIL', 'diff_id: '||I_diff_group_detail_tbl(i).diff_id);
      insert into DIFF_GROUP_DETAIL(diff_id,
                                    diff_group_id,
                                    display_seq,
                                    create_datetime,
                                    last_update_id,
                                    last_update_datetime)
                            values (I_diff_group_detail_tbl(i).diff_id,
                                    I_diff_group_detail_tbl(i).diff_group_id,
                                    I_diff_group_detail_tbl(i).display_seq,
                                    I_diff_group_detail_tbl(i).create_datetime,
                                    I_diff_group_detail_tbl(i).last_update_id,
                                    I_diff_group_detail_tbl(i).last_update_datetime);
   end LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END INSERT_DETAIL;
---------------------------------------------------------------------------------------------
FUNCTION UPDATE_HEAD(O_error_message         IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     I_diff_group_head_rec   IN       DIFF_GROUP_HEAD%ROWTYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DIFF_GROUP_SQL.UPDATE_HEAD';

BEGIN

   if not LOCK_DIFF_GROUP(O_error_message,
                          I_diff_group_head_rec.diff_group_id) then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('UPDATE', NULL, 'DIFF_GROUP_HEAD', 'diff_group_id: '||I_diff_group_head_rec.diff_group_id);
   update diff_group_head
      set diff_type            = I_diff_group_head_rec.diff_type,
          diff_group_desc      = I_diff_group_head_rec.diff_group_desc,
          last_update_id       = I_diff_group_head_rec.last_update_id,
          last_update_datetime = I_diff_group_head_rec.last_update_datetime
    where diff_group_id        = I_diff_group_head_rec.diff_group_id;
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

END UPDATE_HEAD;
-------------------------------------------------------------------------------------------------------
FUNCTION UPDATE_DETAIL(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_diff_group_detail_tbl   IN       DIFF_GROUP_SQL.DIFF_GROUP_DETAIL_TBL)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DIFF_GROUP_SQL.UPDATE_DETAIL';

BEGIN
   FOR i in I_diff_group_detail_tbl.first..I_diff_group_detail_tbl.last LOOP
      if not LOCK_DIFF_GROUP_DETAIL(O_error_message,
                                    I_diff_group_detail_tbl(i).diff_group_id,
                                    I_diff_group_detail_tbl(i).diff_id) then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'DIFF_GROUP_DETAIL', 'diff_id: '||I_diff_group_detail_tbl(i).diff_id);
      update DIFF_GROUP_DETAIL
         set display_seq          = I_diff_group_detail_tbl(i).display_seq,
             last_update_id       = I_diff_group_detail_tbl(i).last_update_id,
             last_update_datetime = I_diff_group_detail_tbl(i).last_update_datetime
       where diff_group_id = I_diff_group_detail_tbl(i).diff_group_id
         and diff_id = I_diff_group_detail_tbl(i).diff_id;

      if SQL%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('COULD_NOT_UPDATE_REC');
         return FALSE;
      end if;

   end LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END UPDATE_DETAIL;
-------------------------------------------------------------------------------------------------------
FUNCTION DELETE_DETAIL(O_error_message           IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       I_diff_group_detail_tbl   IN       DIFF_GROUP_SQL.DIFF_GROUP_DETAIL_TBL)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'DIFF_GROUP_SQL.DELETE_DETAIL';

BEGIN

   FOR i in I_diff_group_detail_tbl.first..I_diff_group_detail_tbl.last LOOP
      if not LOCK_DIFF_GROUP_DETAIL(O_error_message,
                                    I_diff_group_detail_tbl(i).diff_group_id,
                                    I_diff_group_detail_tbl(i).diff_id) then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('DELETE', NULL, 'DIFF_GROUP_DETAIL', 'diff_id: '||I_diff_group_detail_tbl(i).diff_id);
      delete from diff_group_detail
       where diff_group_id = I_diff_group_detail_tbl(i).diff_group_id
         and diff_id = I_diff_group_detail_tbl(i).diff_id;

   end LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END DELETE_DETAIL;
-------------------------------------------------------------------------------------------------------
FUNCTION LOCK_DIFF_GROUP(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         I_diffgrp_id      IN       DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
   RETURN BOOLEAN IS



   L_program      VARCHAR2(50)  := 'DIFF_GROUP_SQL.LOCK_DIFF_GROUP';
   L_table        VARCHAR2(20)  := 'DIFF_GROUP_HEAD';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DIFF_GROUP is
      select 'x'
        from diff_group_head
       where diff_group_id = I_diffgrp_id
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_DIFF_GROUP', 'DIFF_GROUP_HEAD', 'diff_group_id: '||I_diffgrp_id);
   open C_LOCK_DIFF_GROUP;

   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_DIFF_GROUP', 'DIFF_GROUP_HEAD', 'diff_group_id: '||I_diffgrp_id);
   close C_LOCK_DIFF_GROUP;
   ---

   return TRUE;
EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('DELRECS_REC_LOC',
                                            L_table,
                                            'DIFF_GROUP_HEAD'||I_diffgrp_id,
                                            NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END LOCK_DIFF_GROUP;
---------------------------------------------------------------------------------------------
FUNCTION LOCK_DIFF_GROUP_DETAIL(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                I_diffgrp_id      IN       DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE,
                                I_diff_id         IN       DIFF_GROUP_DETAIL.DIFF_ID%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50)  := 'DIFF_GROUP_SQL.LOCK_DIFF_GROUP_DETAIL';
   L_table        VARCHAR2(20)  := 'DIFF_GROUP_DETAIL';

   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DIFF_GROUP_DETAIL is
      select 'x'
        from diff_group_detail
       where diff_id = I_diff_id
         and diff_group_id = I_diffgrp_id
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_DIFF_GROUP_DETAIL', 'DIFF_GROUP_DETAIL', 'diff_id: '||I_diff_id);
   open C_LOCK_DIFF_GROUP_DETAIL;

   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_DIFF_GROUP_DETAIL', 'DIFF_GROUP_DETAIL', 'diff_id: '||I_diff_id);
   close C_LOCK_DIFF_GROUP_DETAIL;

   ---
   return TRUE;
EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('DELRECS_REC_LOC',
                                            L_table,
                                            'DIFF_GROUP_DETAIL'||I_diff_id,
                                            NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END LOCK_DIFF_GROUP_DETAIL;
---------------------------------------------------------------------------------------------
FUNCTION DIFF_GROUP_EXISTS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exist           IN OUT   BOOLEAN,
                           I_diffgrp_id      IN       DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50)  := 'DIFF_GROUP_SQL.DIFF_GROUP_EXISTS';
   L_exist        VARCHAR2(1)   := NULL;

   cursor C_DIFF_GROUP is
      select 'x'
        from diff_group_head
       where diff_group_id = I_diffgrp_id;

BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_DIFF_GROUP', 'DIFF_GROUP_HEAD', 'diff_group_id: '||I_diffgrp_id);
   open C_DIFF_GROUP;

   SQL_LIB.SET_MARK('FETCH', 'C_DIFF_GROUP', 'DIFF_GROUP_HEAD', 'diff_group_id: '||I_diffgrp_id);
   fetch C_DIFF_GROUP into L_exist;

   if C_DIFF_GROUP%FOUND then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_DIFF_GROUP', 'DIFF_GROUP_HEAD', 'diff_group_id: '||I_diffgrp_id);
   close C_DIFF_GROUP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END DIFF_GROUP_EXISTS;
--------------------------------------------------------------------------------------------------
FUNCTION GET_DIFF_TYPE(O_error_message   IN OUT   VARCHAR2,
                       O_diff_type       IN OUT   DIFF_IDS.DIFF_TYPE%TYPE,
                       I_diff_id         IN       DIFF_IDS.DIFF_ID%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'DIFF_GROUP_SQL.GET_DIFF_TYPE';

   cursor C_GET_DIFF_TYPE is
      select diff_type
        from diff_ids
       where diff_id = I_diff_id;

BEGIN

   if I_diff_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_diff_id',
                                            'NULL',
                                            'Diff ID');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_DIFF_TYPE','DIFF_IDS','Diff_id: '||I_diff_id);
   open C_GET_DIFF_TYPE;

   SQL_LIB.SET_MARK('FETCH','C_GET_DIFF_TYPE','DIFF_IDS','Diff_id: '||I_diff_id);
   fetch C_GET_DIFF_TYPE into O_diff_type;
   ---
   if C_GET_DIFF_TYPE%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_DIFF_TYPE','DIFF_IDS','Diff_id: '||I_diff_id);
      close C_GET_DIFF_TYPE;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DIFF',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_DIFF_TYPE','DIFF_IDS','Diff_id: '||I_diff_id);
   close C_GET_DIFF_TYPE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END GET_DIFF_TYPE;
-----------------------------------------------------------------------------------------------------
FUNCTION GET_DIFF_GROUP_TYPE(O_error_message   IN OUT   VARCHAR2,
                             O_diff_type       IN OUT   DIFF_GROUP_HEAD.DIFF_TYPE%TYPE,
                             I_diff_grp_id     IN       DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)

   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'DIFF_GROUP_SQL.GET_DIFF_GROUP_TYPE';

   cursor C_GET_DIFF_GRP_TYPE is
      select diff_type
        from diff_group_head
       where diff_group_id = I_diff_grp_id;

BEGIN

   if I_diff_grp_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_diff_grp_id',
                                            'NULL',
                                            'Diff Group ID');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_DIFF_GRP_TYPE','DIFF_GROUP_HEAD','Diff_group_id: '||I_diff_grp_id);
   open C_GET_DIFF_GRP_TYPE;

   SQL_LIB.SET_MARK('FETCH','C_GET_DIFF_GRP_TYPE','DIFF_GROUP_HEAD','Diff_group_id: '||I_diff_grp_id);
   fetch C_GET_DIFF_GRP_TYPE into O_diff_type;
   ---
   if C_GET_DIFF_GRP_TYPE%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_GET_DIFF_GRP_TYPE','DIFF_GROUP_HEAD','Diff_group_id: '||I_diff_grp_id);
      close C_GET_DIFF_GRP_TYPE;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DIFF',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_DIFF_GRP_TYPE','DIFF_GROUP_HEAD','Diff_group_id: '||I_diff_grp_id);
   close C_GET_DIFF_GRP_TYPE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END GET_DIFF_GROUP_TYPE;
-----------------------------------------------------------------------------------------------------
END DIFF_GROUP_SQL;
/

