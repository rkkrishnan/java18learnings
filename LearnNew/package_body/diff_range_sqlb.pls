CREATE OR REPLACE PACKAGE BODY DIFF_RANGE_SQL AS
-------------------------------------------------------------------------------------------
FUNCTION EXIST(O_error_message    IN OUT VARCHAR2,
               O_exist            IN OUT BOOLEAN,
               I_diff_range       IN     DIFF_RANGE_HEAD.DIFF_RANGE%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(50)     := 'DIFF_RANGE_SQL.EXIST';
   L_exist      VARCHAR2(1)      := NULL;

   cursor C_EXIST is
      select 'x'
        from diff_range_head
       where diff_range = I_diff_range;

BEGIN

   if I_diff_range is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_diff_range', L_program, NULL);
      return FALSE;
   end if;
   ---
   open C_EXIST;
   fetch C_EXIST into L_exist;
   if C_EXIST%NOTFOUND then
      O_exist := FALSE;
   else
      O_exist := TRUE;
   end if;

   close C_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, TO_CHAR(SQLCODE));
      return FALSE;
END EXIST;
-------------------------------------------------------------------------------------------
FUNCTION LIKE_RANGE(O_error_message    IN OUT VARCHAR2,
                    I_new_range        IN     DIFF_RANGE_HEAD.DIFF_RANGE%TYPE,
                    I_new_range_desc   IN     DIFF_RANGE_HEAD.DIFF_RANGE_DESC%TYPE,
                    I_like_range       IN     DIFF_RANGE_HEAD.DIFF_RANGE%TYPE)
RETURN BOOLEAN IS

   L_program  VARCHAR2(50)                     := 'DIFF_RANGE_SQL.LIKE_RANGE';

BEGIN

   if I_new_range is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_new_range', L_program, NULL);
      return FALSE;
   elsif I_like_range is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_like_range', L_program, NULL);
      return FALSE;
   end if;
   ---
   insert into diff_range_head(diff_range,
                               diff_range_desc,
                               diff_group_1,
                               diff_group_2,
                               diff_group_3,
                               diff_range_type)
                        select I_new_range,
                               NVL(I_new_range_desc, diff_range_desc),
                               diff_group_1,
                               diff_group_2,
                               diff_group_3,
                               diff_range_type
                          from diff_range_head
                         where diff_range = I_like_range;

   ---
   insert into diff_range_detail(diff_range,
                                 seq_no,
                                 diff_1,
                                 diff_2,
                                 diff_3,
                                 qty)
                          select I_new_range,
                                 seq_no,
                                 diff_1,
                                 diff_2,
                                 diff_3,
                                 qty
                            from diff_range_detail
                           where diff_range = I_like_range;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, TO_CHAR(SQLCODE));
      return FALSE;
END LIKE_RANGE;
-------------------------------------------------------------------------------------------
FUNCTION DELETE_RANGE(O_error_message    IN OUT VARCHAR2,
                      I_diff_range    IN     DIFF_RANGE_HEAD.DIFF_RANGE%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50)     := 'DIFF_RANGE_SQL.DELETE_RANGE';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   L_table         VARCHAR2(50);

   cursor C_LOCK_RANGE_DETAIL is
      select 'x'
        from diff_range_detail
       where diff_range = I_diff_range
         for update nowait;


   cursor C_LOCK_RANGE_HEAD is
      select 'x'
        from diff_range_head
       where diff_range = I_diff_range
         for update nowait;

BEGIN

   L_table := 'DIFF_RANGE_DETAIL';
   open C_LOCK_RANGE_DETAIL;
   close C_LOCK_RANGE_DETAIL;

   delete from diff_range_detail
    where diff_range = I_diff_range;

   ---
   L_table := 'DIFF_RANGE_HEAD';
   open C_LOCK_RANGE_HEAD;
   close C_LOCK_RANGE_HEAD;

   delete from diff_range_head
    where diff_range = I_diff_range;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED', L_table, TO_CHAR(I_diff_range), NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, TO_CHAR(SQLCODE));
      return FALSE;
END DELETE_RANGE;
-------------------------------------------------------------------------------------------
FUNCTION CHECK_DUPLICATE(O_error_message IN OUT VARCHAR2,
                         O_duplicate     IN OUT BOOLEAN,
                         I_diff_1        IN     DIFF_RANGE_DETAIL.DIFF_1%TYPE,
                         I_diff_2        IN     DIFF_RANGE_DETAIL.DIFF_2%TYPE,
                         I_diff_3        IN     DIFF_RANGE_DETAIL.DIFF_3%TYPE,
                         I_diff_range    IN     DIFF_RANGE_DETAIL.DIFF_RANGE%TYPE,
                         I_rowid         IN     ROWID)
RETURN BOOLEAN IS

   L_dummy   VARCHAR2(1)  := 'N';
   L_program VARCHAR2(50) := 'DIFF_RANGE_SQL.CHECK_DUPLICATE';

   cursor C_DUPLICATE is
      select 'Y'
        from diff_range_detail
       where diff_range = I_diff_range
         and diff_1 = I_diff_1
         and (diff_2 = I_diff_2
              or diff_2 is NULL and I_diff_2 is NULL)
         and (diff_3 = I_diff_3
              or diff_3 is NULL and I_diff_3 is NULL)
         and (rowid != I_rowid or I_rowid is NULL);

BEGIN

   if I_diff_1 is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_diff_1',
                                            L_program,
                                            NULL);
         return FALSE;
   elsif I_diff_range is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_diff_range',
                                            L_program,
                                            NULL);
         return FALSE;
   end if;

   open C_DUPLICATE;
   fetch C_DUPLICATE into L_dummy;
   close C_DUPLICATE;

   if L_dummy = 'Y' then
      O_duplicate := TRUE;
   else
      O_duplicate := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_DUPLICATE;
-------------------------------------------------------------------------------------------
FUNCTION GET_HEADER_INFO(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_header_rec    IN OUT DIFF_RANGE_SQL.HEADER_INFO,
                         I_diff_group1   IN     DIFF_RANGE_HEAD.DIFF_GROUP_1%TYPE,
                         I_diff_group2   IN     DIFF_RANGE_HEAD.DIFF_GROUP_2%TYPE,
                         I_diff_group3   IN     DIFF_RANGE_HEAD.DIFF_GROUP_3%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(30) := 'DIFF_RANGE_SQL.GET_HEADER_INFO';

   cursor C_GET_HEADER_INFO is
      select dg1.diff_group_desc,
             DECODE(I_diff_group2, NULL, NULL, dg2.diff_group_desc),
             DECODE(I_diff_group3, NULL, NULL, dg3.diff_group_desc),
             dg1.diff_type,
             dt1.diff_type_desc,
             DECODE(I_diff_group2, NULL, NULL, dg2.diff_type),
             DECODE(I_diff_group2, NULL, NULL, dt2.diff_type_desc),
             DECODE(I_diff_group3, NULL, NULL, dg3.diff_type),
             DECODE(I_diff_group3, NULL, NULL, dt3.diff_type_desc)
        from diff_group_head dg1,
             diff_group_head dg2,
             diff_group_head dg3,
             diff_type dt1,
             diff_type dt2,
             diff_type dt3
       where dg1.diff_group_id = I_diff_group1
         and (dg2.diff_group_id = I_diff_group2
              or I_diff_group2 is NULL)
         and (dg3.diff_group_id = I_diff_group3
              or I_diff_group3 is NULL)
         and dt1.diff_type      = dg1.diff_type
         and (dt2.diff_type     = dg2.diff_type)  /* diff_group_head-diff_type join will occur even if I_diff_group2 */
         and (dt3.diff_type     = dg3.diff_type);  /* and I_diff_group3 are NULL - then values are cleared later */

BEGIN

   if I_diff_group1 is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_diff_group1',
                                            L_program,
                                            NULL);
         return FALSE;
   end if;

   open C_GET_HEADER_INFO;
   fetch C_GET_HEADER_INFO into O_header_rec.group1_desc,
                                O_header_rec.group2_desc,
                                O_header_rec.group3_desc,
                                O_header_rec.type1,
                                O_header_rec.type1_desc,
                                O_header_rec.type2,
                                O_header_rec.type2_desc,
                                O_header_rec.type3,
                                O_header_rec.type3_desc;
   close C_GET_HEADER_INFO;

   if O_header_rec.group1_desc is NULL then
      -- cursor found no records
      O_error_message := SQL_LIB.CREATE_MSG('INV_DIFF_GROUP',
                                             NULL,
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if O_header_rec.type1_desc is not NULL then
      if LANGUAGE_SQL.TRANSLATE(O_header_rec.group1_desc,
                                O_header_rec.group1_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;

      if LANGUAGE_SQL.TRANSLATE(O_header_rec.type1_desc,
                                O_header_rec.type1_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   if O_header_rec.type2_desc is not NULL then
      if LANGUAGE_SQL.TRANSLATE(O_header_rec.group2_desc,
                                O_header_rec.group2_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;

      if LANGUAGE_SQL.TRANSLATE(O_header_rec.type2_desc,
                                O_header_rec.type2_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   if O_header_rec.type3_desc is not NULL then
      if LANGUAGE_SQL.TRANSLATE(O_header_rec.group3_desc,
                                O_header_rec.group3_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;

      if LANGUAGE_SQL.TRANSLATE(O_header_rec.type3_desc,
                                O_header_rec.type3_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_HEADER_INFO;
-------------------------------------------------------------------------------------------
FUNCTION GET_NEXT_SEQ_NO(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_seq_no        IN OUT DIFF_RANGE_DETAIL.SEQ_NO%TYPE,
                         I_diff_range    IN     DIFF_RANGE_DETAIL.DIFF_RANGE%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(30) := 'DIFF_RANGE_SQL.GET_NEXT_SEQ_NO';

   cursor C_SEQ_NO is
      select NVL(max(seq_no + 1),1)
        from diff_range_detail
       where diff_range = I_diff_range;

BEGIN

   if I_diff_range is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_diff_range',
                                            L_program,
                                            NULL);
         return FALSE;
   end if;

   open C_SEQ_NO;
   fetch C_SEQ_NO into O_seq_no;
   close C_SEQ_NO;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_NEXT_SEQ_NO;
-------------------------------------------------------------------------------------------
FUNCTION GET_GROUPS_AND_DESC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists        IN OUT BOOLEAN,
                             O_range_desc    IN OUT DIFF_RANGE_HEAD.DIFF_RANGE_DESC%TYPE,
                             O_group_1       IN OUT DIFF_RANGE_HEAD.DIFF_GROUP_1%TYPE,
                             O_group_2       IN OUT DIFF_RANGE_HEAD.DIFF_GROUP_2%TYPE,
                             O_group_3       IN OUT DIFF_RANGE_HEAD.DIFF_GROUP_3%TYPE,
                             I_diff_range    IN     DIFF_RANGE_HEAD.DIFF_RANGE%TYPE)
RETURN BOOLEAN IS

      L_program    VARCHAR2(35) := 'DIFF_RANGE_SQL.GET_GROUPS_AND_DESC';
      L_range_type DIFF_RANGE_HEAD.DIFF_RANGE_TYPE%TYPE;

BEGIN
   if GET_GROUPS_AND_DESC(O_error_message,
                          O_exists,
                          O_range_desc,
                          L_range_type,
                          O_group_1,
                          O_group_2,
                          O_group_3,
                          I_diff_range) = FALSE then
      return FALSE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_GROUPS_AND_DESC;
-------------------------------------------------------------------------------------------
FUNCTION GET_GROUPS_AND_DESC(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_exists        IN OUT BOOLEAN,
                             O_range_desc    IN OUT DIFF_RANGE_HEAD.DIFF_RANGE_DESC%TYPE,
                             O_range_type    IN OUT DIFF_RANGE_HEAD.DIFF_RANGE_TYPE%TYPE,
                             O_group_1       IN OUT DIFF_RANGE_HEAD.DIFF_GROUP_1%TYPE,
                             O_group_2       IN OUT DIFF_RANGE_HEAD.DIFF_GROUP_2%TYPE,
                             O_group_3       IN OUT DIFF_RANGE_HEAD.DIFF_GROUP_3%TYPE,
                             I_diff_range    IN     DIFF_RANGE_HEAD.DIFF_RANGE%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(35) := 'DIFF_RANGE_SQL.GET_GROUPS_AND_DESC';
   L_rowid   rowid;

   cursor C_GROUPS_DESC is
      select  drh.rowid,
              drh.diff_range_desc,
              drh.diff_range_type,
              drh.diff_group_1,
              drh.diff_group_2,
              drh.diff_group_3
        from  v_diff_group_head vdgh,
              diff_range_head   drh
       where  drh.diff_range    = I_diff_range
         and  drh.diff_group_1  = vdgh.diff_group_id
         and  ((drh.diff_group_2 is NULL)
		        or (drh.diff_group_2 in (select diff_group_id
		                                   from v_diff_group_head vdg
							              where vdg.diff_group_id = drh.diff_group_2)))
		 and  ((drh.diff_group_3 is NULL)
		        or (drh.diff_group_3 in (select diff_group_id
		                                   from v_diff_group_head vdg
					   					  where vdg.diff_group_id = drh.diff_group_3)));

BEGIN

   if I_diff_range is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_diff_range', L_program, NULL);
      return FALSE;
   end if;

   open C_GROUPS_DESC;
   fetch C_GROUPS_DESC into L_rowid,
                            O_range_desc,
                            O_range_type,
                            O_group_1,
                            O_group_2,
                            O_group_3;
   close C_GROUPS_DESC;

   if L_rowid is not NULL then
      O_exists := TRUE;
      if LANGUAGE_SQL.TRANSLATE(O_range_desc,
                                O_range_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_GROUPS_AND_DESC;
-------------------------------------------------------------------------------------------
END DIFF_RANGE_SQL;
/

