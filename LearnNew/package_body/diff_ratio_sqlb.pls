CREATE OR REPLACE PACKAGE BODY DIFF_RATIO_SQL AS
------------------------------------------------------------------------------
FUNCTION NEXT_DIFF_RATIO_ID (O_error_message IN OUT VARCHAR2,
                             O_diff_ratio_id IN OUT DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE)
RETURN BOOLEAN IS

   L_wrap_sequence_number        DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE;
   L_first_time                  VARCHAR2(3) := 'Yes';
   L_diff_ratio                  VARCHAR2(1);

   cursor C_DIFF_RATIO_ID_EXISTS is
      select 'x'
        from diff_ratio_head
       where diff_ratio_id = O_diff_ratio_id;

BEGIN
   LOOP
      SQL_LIB.SET_MARK('select',
                       'diff_ratio_sequence.NEXTVAL',
                       'sys.dual',
                       NULL);
      select diff_ratio_sequence.NEXTVAL
        into O_diff_ratio_id
        from sys.dual;
      ---
      if (L_first_time = 'Yes') then
         L_wrap_sequence_number := O_diff_ratio_id;
         L_first_time := 'No';
      elsif (O_diff_ratio_id = L_wrap_sequence_number) then
         O_error_message := SQL_LIB.CREATE_MSG('NO_NEXT_DIFF_RATIO');
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('open',
                       'C_DIFF_RATIO_ID_EXISTS',
                       'diff_ratio_head',
                       NULL);
      open C_DIFF_RATIO_ID_EXISTS;
      ---
      SQL_LIB.SET_MARK('fetch',
                       'C_DIFF_RATIO_ID_EXISTS',
                       'diff_ratio_head',
                       NULL);
      fetch C_DIFF_RATIO_ID_EXISTS into L_diff_ratio;
      if (C_DIFF_RATIO_ID_EXISTS%notfound) then
         SQL_LIB.SET_MARK('close',
                          'C_DIFF_RATIO_ID_EXISTS',
                          'diff_ratio_head',
                          NULL);
         close C_DIFF_RATIO_ID_EXISTS;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('close',
                       'C_DIFF_RATIO_ID_EXISTS',
                       'diff_ratio_head',
                       NULL);
      close C_DIFF_RATIO_ID_EXISTS;
   END LOOP;
   ---
   return TRUE;
EXCEPTION
   WHEN OTHERS THEN
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_RATIO_SQL.NEXT_DIFF_RATIO_ID',
                                             to_char(SQLCODE));
      return FALSE;
END NEXT_DIFF_RATIO_ID;
------------------------------------------------------------------------------
FUNCTION GET_DIFF_RATIO_DESC (O_ERROR_MESSAGE   IN OUT VARCHAR2,
                              O_DIFF_RATIO_DESC IN OUT DIFF_RATIO_HEAD.DESCRIPTION%TYPE,
                              I_DIFF_RATIO_ID   IN     DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE)
return BOOLEAN IS
   L_program VARCHAR2(64) :=  'DIFF_RATIO_SQL.GET_DIFF_RATIO_DESC';

   cursor C_DIFF_RATIO is
         select description
           from diff_ratio_head
          where diff_ratio_id = I_diff_ratio_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_DIFF_RATIO',
                    'DIFF_RATIO_HEAD',
                    'diff_ratio_id : '|| to_char(I_diff_ratio_id));
   open C_DIFF_RATIO;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_DIFF_RATIO',
                    'DIFF_RATIO_HEAD',
                    'diff_ratio_id : '|| to_char(I_diff_ratio_id));
                    fetch C_DIFF_RATIO into O_diff_ratio_desc;
   ---
   if C_DIFF_RATIO%NOTFOUND then
      O_error_message := sql_lib.create_msg('INV_DIFF_RATIO');
      close C_DIFF_RATIO;
      return FALSE;
   else
      if LANGUAGE_SQL.TRANSLATE (O_diff_ratio_desc,
                                 O_diff_ratio_desc,
                                 O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DIFF_RATIO',
                    'DIFF_RATIO_HEAD',
                    'diff_ratio_id : '|| to_char(I_diff_ratio_id));
   close C_DIFF_RATIO;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_DIFF_RATIO_DESC;
------------------------------------------------------------------------------
FUNCTION DIFF_RATIO_EXISTS (O_ERROR_MESSAGE  IN OUT VARCHAR2,
                            O_FOUND          IN OUT BOOLEAN,
                            I_DIFF_RATIO_ID  IN     DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE)
return BOOLEAN IS
   L_program          VARCHAR2(64) :=  'DIFF_RATIO_SQL.DIFF_RATIO_EXISTS';
   L_dummy            VARCHAR2(1);
   cursor C_EXISTS is
         select 'x'
           from diff_ratio_head
          where diff_ratio_id = I_diff_ratio_id;
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'DIFF_RATIO_HEAD',
                    'diff_ratio_id : '|| to_char(I_diff_ratio_id));
   open C_EXISTS;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'DIFF_RATIO_HEAD',
                    'diff_ratio_id : '|| to_char(I_diff_ratio_id));
   fetch C_EXISTS into L_dummy;
   ---
   if C_EXISTS%NOTFOUND then
      O_FOUND := FALSE;
   else
      O_FOUND := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'DIFF_RATIO_HEAD',
                    'diff_ratio_id : '|| to_char(I_diff_ratio_id));
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
END DIFF_RATIO_EXISTS;
-------------------------------------------------------------------------------
FUNCTION CREATE_LIKE_DIFF_RATIO (O_ERROR_MESSAGE        IN OUT VARCHAR2,
                                 I_NEW_DIFF_RATIO_ID    IN DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE,
                                 I_NEW_DIFF_RATIO_DESC  IN DIFF_RATIO_HEAD.DESCRIPTION%TYPE,
                                 I_LIKE_DIFF_RATIO_ID   IN DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE)
                                 return BOOLEAN IS
   L_program       VARCHAR2(64) :=  'DIFF_RATIO_SQL.CREATE_LIKE_DIFF_RATIO';

BEGIN
   SQL_LIB.SET_MARK('INSERT',NULL,'DIFF_RATIO_HEAD','diff_ratio_id: '||to_char
(I_new_diff_ratio_id));
   ---
   insert into diff_ratio_head (diff_ratio_id,
                                description,
                                dept,
                                class,
                                subclass,
                                diff_group_1,
                                diff_group_2,
                                diff_group_3,
                                system_gen_ind,
                                regular_sales_ind,
                                prom_sales_ind,
                                clear_sales_ind,
                                period_type,
                                start_date,
                                end_date,
                                weeks_back,
                                last_review_date,
                                review_weeks,
                                update_ind)
      select I_new_diff_ratio_id,
             I_new_diff_ratio_desc,
             dept,
             class,
             subclass,
             diff_group_1,
             diff_group_2,
             diff_group_3,
             'N',
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL
        from diff_ratio_head
       where diff_ratio_id = I_like_diff_ratio_id;
   ---
   SQL_LIB.SET_MARK('INSERT',NULL,'DIFF_RATIO_DETAIL','diff_ratio_id: '||to_char
(I_new_diff_ratio_id));
   ---
   insert into diff_ratio_detail(diff_ratio_id,
                                 seq_no,
                                 store,
                                 diff_1,
                                 diff_2,
                                 diff_3,
                                 qty,
                                 pct)
      select I_new_diff_ratio_id,
             seq_no,
             store,
             diff_1,
             diff_2,
             diff_3,
             qty,
             pct
        from diff_ratio_detail
       where diff_ratio_id = I_like_diff_ratio_id;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CREATE_LIKE_DIFF_RATIO;
------------------------------------------------------------------------------
FUNCTION CREATE_LIKE_STORE_DETAIL (O_ERROR_MESSAGE  IN OUT VARCHAR2,
                                   I_DIFF_RATIO_ID  IN     diff_ratio_head.diff_ratio_id%TYPE,
                                   I_NEW_STORE      IN     store.store%TYPE,
                                   I_LIKE_STORE     IN     store.store%TYPE) return BOOLEAN
IS

   L_program          VARCHAR2(64)   :=  'DIFF_RATIO_SQL.CREATE_LIKE_STORE_DETAIL';
   L_seq_no           DIFF_RATIO_DETAIL.SEQ_NO%TYPE;
   L_diff_1           DIFF_RATIO_DETAIL.DIFF_1%TYPE;
   L_diff_2           DIFF_RATIO_DETAIL.DIFF_2%TYPE;
   L_diff_3           DIFF_RATIO_DETAIL.DIFF_3%TYPE;
   L_qty              DIFF_RATIO_DETAIL.QTY%TYPE;
   L_pct              DIFF_RATIO_DETAIL.PCT%TYPE;

   cursor C_LIKE_STORE is
      select diff_1,
             diff_2,
             diff_3,
             qty,
             pct
        from diff_ratio_detail
       where diff_ratio_id = I_diff_ratio_id
         and store = I_like_store;
   ---
   cursor C_GET_MAX is
      select MAX(seq_no)
        from diff_ratio_detail;
   ---
BEGIN
   SQL_LIB.SET_MARK('INSERT',NULL,'DIFF_RATIO_DETAIL','store: '||to_char (I_new_store));
   ---
   open C_GET_MAX;
   fetch C_GET_MAX into L_seq_no;
   close C_GET_MAX;
   ---
   open C_LIKE_STORE;
   LOOP
      fetch C_LIKE_STORE into L_diff_1,
                              L_diff_2,
                              L_diff_3,
                              L_qty,
                              L_pct;
      if C_LIKE_STORE%NOTFOUND then
         Exit;
      end if;
      L_seq_no := L_seq_no + 1;
      ---
      insert into diff_ratio_detail(diff_ratio_id,
                                    seq_no,
                                    store,
                                    diff_1,
                                    diff_2,
                                    diff_3,
                                    qty,
                                    pct)
          values(I_diff_ratio_id,
                 L_seq_no,
                 I_new_store,
                 L_diff_1,
                 L_diff_2,
                 L_diff_3,
                 L_qty,
                 L_pct);
   END LOOP;
   close C_LIKE_STORE;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CREATE_LIKE_STORE_DETAIL;
------------------------------------------------------------------------------
FUNCTION DELETE_STORE_DETAIL (O_ERROR_MESSAGE  IN OUT VARCHAR2,
                              I_DIFF_RATIO_ID  IN     DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE)
return BOOLEAN IS

   L_program       VARCHAR2(64)   :=  'DIFF_RATIO_SQL.DELETE_STORE_DETAIL';
   L_table         VARCHAR2(30);
   L_dummy         VARCHAR2(255);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DIFF_RATIO_DETAIL is
      select 'x'
        from diff_ratio_detail
       where diff_ratio_id = I_diff_ratio_id
         for update nowait;

BEGIN
   L_table := 'DIFF_RATIO_DETAIL';
   open C_LOCK_DIFF_RATIO_DETAIL;
   close C_LOCK_DIFF_RATIO_DETAIL;
   delete from diff_ratio_detail
      where diff_ratio_id = I_diff_ratio_id;
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_diff_ratio_id));
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_STORE_DETAIL;
------------------------------------------------------------------------------
FUNCTION SIMILAR_DIFF_RATIO (O_ERROR_MESSAGE  IN OUT VARCHAR2,
                             O_FOUND          IN OUT BOOLEAN,
                             I_DEPT           IN     DIFF_RATIO_HEAD.DEPT%TYPE,
                             I_CLASS          IN     DIFF_RATIO_HEAD.CLASS%TYPE,
                             I_SUBCLASS       IN     DIFF_RATIO_HEAD.SUBCLASS%TYPE,
                             I_DIFF_GROUP_1   IN     DIFF_RATIO_HEAD.DIFF_GROUP_1%TYPE,
                             I_DIFF_GROUP_2   IN     DIFF_RATIO_HEAD.DIFF_GROUP_2%TYPE,
                             I_DIFF_GROUP_3   IN     DIFF_RATIO_HEAD.DIFF_GROUP_3%TYPE,
                             I_SYSTEM_GEN_IND IN     DIFF_RATIO_HEAD.SYSTEM_GEN_IND%TYPE)
return BOOLEAN IS
   L_program          VARCHAR2(64) :=  'DIFF_RATIO_SQL.SIMILAR_DIFF_RATIO';
   L_dummy            VARCHAR2(1);

   cursor C_SIMILAR is
         select 'x'
           from diff_ratio_head
          where dept               = I_dept
            and class              = I_class
            and subclass           = I_subclass
            and system_gen_ind     = I_system_gen_ind
            and diff_group_1       = I_diff_group_1
            and (    diff_group_2  = I_diff_group_2
                 or (diff_group_2 is NULL and I_diff_group_2 is NULL))
            and (    diff_group_3  = I_diff_group_3
                 or (diff_group_3 is NULL and I_diff_group_3 is NULL));
BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_SIMILAR',
                    'DIFF_RATIO_HEAD',
                     NULL);
   open C_SIMILAR;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_SIMILAR',
                    'DIFF_RATIO_HEAD',
                     NULL);
   fetch C_SIMILAR into L_dummy;
   ---
   if C_SIMILAR%NOTFOUND then
      O_found := FALSE;
   else
      O_found := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_SIMILAR',
                    'DIFF_RATIO_HEAD',
                     NULL);
   close C_SIMILAR;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END SIMILAR_DIFF_RATIO;
-------------------------------------------------------------------------------
FUNCTION DETAIL_EXISTS(O_ERROR_MESSAGE        IN OUT VARCHAR2,
                       O_EXISTS               IN OUT VARCHAR2,
                       I_DIFF_RATIO_ID  IN     DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE) return
BOOLEAN IS

   L_program       VARCHAR2(64)   :=  'DIFF_RATIO_SQL.DETAIL_EXISTS';
   cursor C_DETAIL_EXISTS is
      select 'Y'
        from diff_ratio_detail
       where diff_ratio_id = I_diff_ratio_id;

BEGIN
   O_EXISTS := 'N';

   SQL_LIB.SET_MARK('OPEN',
                    'C_DETAIL_EXISTS',
                    'DIFF_RATIO_DETAIL',
                     NULL);
   open C_DETAIL_EXISTS;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_DETAIL_EXISTS',
                    'DIFF_RATIO_DETAIL',
                     NULL);
   fetch C_DETAIL_EXISTS into O_EXISTS;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DETAIL_EXISTS',
                    'DIFF_RATIO_DETAIL',
                     NULL);
   close C_DETAIL_EXISTS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END DETAIL_EXISTS;
---------------------------------------------------------------------------------------
FUNCTION GET_GROUPS_AND_DESC(O_error_message    IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_ratio_desc       IN OUT DIFF_RATIO_HEAD.DESCRIPTION%TYPE,
                             O_diff_group_1     IN OUT DIFF_RATIO_HEAD.DIFF_GROUP_1%TYPE,
                             O_diff_group_2     IN OUT DIFF_RATIO_HEAD.DIFF_GROUP_1%TYPE,
                             O_diff_group_3     IN OUT DIFF_RATIO_HEAD.DIFF_GROUP_1%TYPE,
                             I_ratio_id         IN     DIFF_RATIO_DETAIL.DIFF_RATIO_ID%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'DIFF_RATIO_SQL.GET_GROUPS_AND_DESC';



   cursor C_GET_GROUPS is
      select   distinct
               drh.diff_group_1,
               drh.diff_group_2,
               drh.diff_group_3
        from   v_diff_group_head vdgh,
               diff_ratio_head   drh
       where   drh.diff_ratio_id = I_ratio_id
         and  (drh.diff_group_1  = vdgh.diff_group_id
            or drh.diff_group_2  = vdgh.diff_group_id
            or drh.diff_group_3  = vdgh.diff_group_id);


BEGIN
   if I_ratio_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_ratio_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   --
   if GET_DIFF_RATIO_DESC(O_error_message,
                          O_ratio_desc,
                          I_ratio_id) = FALSE then
      return FALSE;
   end if;
   --
   open  C_GET_GROUPS;
   fetch C_GET_GROUPS into O_diff_group_1,
                           O_diff_group_2,
                           O_diff_group_3;
   close C_GET_GROUPS;
   --
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_GROUPS_AND_DESC;
---------------------------------------------------------------------------------------
END DIFF_RATIO_SQL;
/

