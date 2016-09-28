CREATE OR REPLACE PACKAGE BODY EXP_PROF_SQL AS
--------------------------------------------------------------------------------------
FUNCTION PROF_HEAD_EXIST(O_error_message     IN OUT VARCHAR2,
                         O_exists            IN OUT BOOLEAN,
                         I_exp_prof_type     IN     EXP_PROF_HEAD.EXP_PROF_TYPE%TYPE,
                         I_module            IN     EXP_PROF_HEAD.MODULE%TYPE,
                         I_key_value_1       IN     EXP_PROF_HEAD.KEY_VALUE_1%TYPE,
                         I_key_value_2       IN     EXP_PROF_HEAD.KEY_VALUE_2%TYPE,
                         I_zone_group_id     IN     COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE,
                         I_zone_id           IN     COST_ZONE.ZONE_ID%TYPE,
                         I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                         I_lading_port       IN     OUTLOC.OUTLOC_ID%TYPE,
                         I_discharge_port    IN     OUTLOC.OUTLOC_ID%TYPE)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(50) := 'EXP_PROF_SQL.PROF_HEAD_EXIST';
   L_exists      VARCHAR2(1)  := 'N';

   cursor C_CHECK_PROF_CTY is
      select 'Y'
        from exp_prof_head
       where exp_prof_type      = 'C'
         and module             = I_module
         and key_value_1        = I_key_value_1
         and (key_value_2       = I_key_value_2
          or (key_value_2       is NULL
              and I_key_value_2 is NULL))
         and origin_country_id  = NVL(I_origin_country_id, origin_country_id)
         and lading_port        = NVL(I_lading_port, lading_port)
         and discharge_port     = NVL(I_discharge_port, discharge_port);

   cursor C_CHECK_PROF_ZONE is
      select 'Y'
        from exp_prof_head
       where exp_prof_type      = I_exp_prof_type
         and module             = I_module
         and key_value_1        = I_key_value_1
         and (key_value_2       = I_key_value_2
          or (key_value_2       is NULL
              and I_key_value_2 is NULL))
         and zone_group_id      = NVL(I_zone_group_id, zone_group_id)
         and discharge_port     = NVL(I_discharge_port, discharge_port)
         and zone_id            = NVL(I_zone_id, zone_id);

BEGIN
   O_exists := TRUE;
   ---
   if I_exp_prof_type = 'C' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_PROF_CTY','EXP_PROF_HEAD', NULL);
      open C_CHECK_PROF_CTY;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_PROF_CTY','EXP_PROF_HEAD', NULL);
      fetch C_CHECK_PROF_CTY into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_PROF_CTY','EXP_PROF_HEAD', NULL);
      close C_CHECK_PROF_CTY;
      ---
      if L_exists = 'N' then
         O_error_message := SQL_LIB.CREATE_MSG('NO_PROF_HEAD',NULL,NULL,NULL);
         O_exists := FALSE;
      else
         O_error_message := SQL_LIB.CREATE_MSG('DUP_PROF_HEAD',NULL,NULL,NULL);
      end if;
   else
      SQL_LIB.SET_MARK('OPEN','C_CHECK_PROF_ZONE','EXP_PROF_HEAD', NULL);
      open C_CHECK_PROF_ZONE;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_PROF_ZONE','EXP_PROF_HEAD', NULL);
      fetch C_CHECK_PROF_ZONE into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_PROF_ZONE','EXP_PROF_HEAD', NULL);
      close C_CHECK_PROF_ZONE;
      ---
      if L_exists = 'N' then
         O_error_message := SQL_LIB.CREATE_MSG('NO_PROF_HEAD',NULL,NULL,NULL);
         O_exists := FALSE;
      else
         O_error_message := SQL_LIB.CREATE_MSG('DUP_PROF_HEAD',NULL,NULL,NULL);
      end if;
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
END PROF_HEAD_EXIST;
--------------------------------------------------------------------------------------
FUNCTION PROF_DETAIL_EXISTS(O_error_message IN OUT VARCHAR2,
                            O_exists        IN OUT BOOLEAN,
                            I_exp_prof_key  IN     EXP_PROF_HEAD.EXP_PROF_KEY%TYPE,
                            I_comp_id       IN     ELC_COMP.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'EXP_PROF_SQL.PROF_DETAILS_EXIST';
   L_exists  VARCHAR2(1)  := 'N';

   cursor C_CHECK_PROF_DTL is
      select 'Y'
        from exp_prof_detail
       where exp_prof_key = I_exp_prof_key
         and comp_id      = I_comp_id;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_PROF_DTL','EXP_PROF_DETAIL','Key: '||to_char(I_exp_prof_key));
   open C_CHECK_PROF_DTL;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_PROF_DTL','EXP_PROF_DETAIL','Key: '||to_char(I_exp_prof_key));
   fetch C_CHECK_PROF_DTL into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_PROF_DTL','EXP_PROF_DETAIL','Key: '||to_char(I_exp_prof_key));
   close C_CHECK_PROF_DTL;
   ---
   if L_exists = 'N' then
      O_error_message := SQL_LIB.CREATE_MSG('NO_PROF_DTLS',NULL,NULL,NULL);
      O_exists := FALSE;
   else
      O_error_message := SQL_LIB.CREATE_MSG('DUP_PROF_DETAIL',NULL,NULL,NULL);
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
END PROF_DETAIL_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION GET_NEXT_PROF(O_error_message IN OUT VARCHAR2,
                       O_exp_prof_key  IN OUT EXP_PROF_HEAD.EXP_PROF_KEY%TYPE)
   RETURN BOOLEAN IS

   L_program      VARCHAR2(50)                    := 'EXP_PROF_SQL.GET_NEXT_PROF';
   L_first_time   VARCHAR2(1)                     := 'Y';
   L_exists       VARCHAR2(1)                     := 'N';
   L_wrap_number  EXP_PROF_HEAD.EXP_PROF_KEY%TYPE;

   cursor C_GET_NEXT is
      select exp_prof_head_sequence.NEXTVAL
        from dual;

   cursor C_CHECK_KEY is
      select 'Y'
        from exp_prof_head
       where exp_prof_key = O_exp_prof_key;

BEGIN
   LOOP
      --- Retrieve sequence number
      SQL_LIB.SET_MARK('OPEN','C_GET_NEXT','DUAL',NULL);
      open C_GET_NEXT;
      SQL_LIB.SET_MARK('FETCH','C_GET_NEXT','DUAL',NULL);
      fetch C_GET_NEXT into O_exp_prof_key;
      ---
      if C_GET_NEXT%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_GET_NEXT','DUAL',NULL);
         close C_GET_NEXT;
         O_error_message := SQL_LIB.CREATE_MSG('ERR_RETRIEVE_SEQ',NULL,NULL,NULL);
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_GET_NEXT','DUAL',NULL);
      close C_GET_NEXT;
      ---
      if (L_first_time = 'Y') then
         L_wrap_number := O_exp_prof_key;
         L_first_time := 'N';
      elsif (O_exp_prof_key = L_wrap_number) then
         O_error_message := SQL_LIB.CREATE_MSG('NO_SEQ_NO_AVAIL',NULL,NULL,NULL);
         return FALSE;
      end if;

      --- Check key existence

      L_exists := 'N';

      SQL_LIB.SET_MARK('OPEN','C_CHECK_KEY','EXP_PROF_HEAD','key: '||to_char(O_exp_prof_key));
      open C_CHECK_KEY;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_KEY','EXP_PROF_HEAD','key: '||to_char(O_exp_prof_key));
      fetch C_CHECK_KEY into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_KEY','EXP_PROF_HEAD','key: '||to_char(O_exp_prof_key));
      close C_CHECK_KEY;
      ---
      if L_exists = 'N' then
         EXIT;
      end if;
      ---
   END LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_NEXT_PROF;
--------------------------------------------------------------------------------------
FUNCTION BASE_PROF_CHANGED(O_error_message     IN OUT VARCHAR2,
                           I_exp_prof_key      IN     EXP_PROF_HEAD.EXP_PROF_KEY%TYPE,
                           I_exp_prof_type     IN     EXP_PROF_HEAD.EXP_PROF_TYPE%TYPE,
                           I_module            IN     EXP_PROF_HEAD.MODULE%TYPE,
                           I_key_value_1       IN     EXP_PROF_HEAD.KEY_VALUE_1%TYPE,
                           I_key_value_2       IN     EXP_PROF_HEAD.KEY_VALUE_2%TYPE,
                           I_base_prof_ind     IN     EXP_PROF_HEAD.BASE_PROF_IND%TYPE)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(50)   := 'EXP_PROF_SQL.BASE_PROF_CHANGED';
   L_table       VARCHAR2(30)   := 'EXP_PROF_HEAD';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_EXP_PROF_HEAD is
      select 'x'
        from exp_prof_head
       where exp_prof_type      = I_exp_prof_type
         and module             = I_module
         and key_value_1        = I_key_value_1
         and (key_value_2       = I_key_value_2
          or (key_value_2       is NULL
              and I_key_value_2 is NULL))
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_EXP_PROF_HEAD','EXP_PROF_HEAD',NULL);
   open C_LOCK_EXP_PROF_HEAD;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_EXP_PROF_HEAD','EXP_PROF_HEAD',NULL);
   close C_LOCK_EXP_PROF_HEAD;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'EXP_PROF_HEAD',NULL);
   update exp_prof_head
      set base_prof_ind      = 'N'
    where exp_prof_type      = I_exp_prof_type
      and module             = I_module
      and key_value_1        = I_key_value_1
      and (key_value_2       = I_key_value_2
       or (key_value_2       is NULL
           and I_key_value_2 is NULL));
   ---
   if I_base_prof_ind = 'Y' then
      SQL_LIB.SET_MARK('UPDATE',NULL,'EXP_PROF_HEAD',NULL);
      update exp_prof_head
         set base_prof_ind = 'Y'
       where exp_prof_key  = I_exp_prof_key;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END BASE_PROF_CHANGED;
----------------------------------------------------------------------------------------
FUNCTION DEL_PROF_HEAD(O_error_message IN OUT VARCHAR2,
                       I_exp_prof_type IN     EXP_PROF_HEAD.EXP_PROF_TYPE%TYPE,
                       I_module        IN     EXP_PROF_HEAD.MODULE%TYPE,
                       I_key_value_1   IN     EXP_PROF_HEAD.KEY_VALUE_1%TYPE,
                       I_key_value_2   IN     EXP_PROF_HEAD.KEY_VALUE_2%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'EXP_PROF_SQL.DEL_PROF_HEAD';
   L_table         VARCHAR2(30) := 'EXP_PROF_HEAD';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_EXP_PROF_HEAD is
      select 'x'
        from exp_prof_head eh
       where eh.exp_prof_type   = I_exp_prof_type
         and eh.module          = I_module
         and eh.key_value_1     = I_key_value_1
         and (eh.key_value_2    = I_key_value_2
          or (eh.key_value_2    is NULL
              and I_key_value_2 is NULL))
         and eh.exp_prof_key not in
               (select ed.exp_prof_key
                  from exp_prof_detail ed)
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_EXP_PROF_HEAD','EXP_PROF_HEAD',NULL);
   open C_LOCK_EXP_PROF_HEAD;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_EXP_PROF_HEAD','EXP_PROF_HEAD',NULL);
   close C_LOCK_EXP_PROF_HEAD;

   SQL_LIB.SET_MARK('DELETE',NULL,'EXP_PROF_HEAD',NULL);
   delete from exp_prof_head eh
      where eh.exp_prof_type   = I_exp_prof_type
        and eh.module          = I_module
        and eh.key_value_1     = I_key_value_1
        and (eh.key_value_2    = I_key_value_2
         or (eh.key_value_2    is NULL
             and I_key_value_2 is NULL))
        and eh.exp_prof_key not in
              (select ed.exp_prof_key
                 from exp_prof_detail ed);
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEL_PROF_HEAD;
----------------------------------------------------------------------------------------
FUNCTION LOCK_PROF_DETAILS(O_error_message    IN OUT  VARCHAR2,
                           I_exp_prof_key     IN      EXP_PROF_HEAD.EXP_PROF_KEY%TYPE)
   RETURN BOOLEAN IS

      L_table        VARCHAR2(30)   := 'EXP_PROF_DETAIL';
      RECORD_LOCKED  EXCEPTION;
      PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

      cursor C_LOCK_PROF_DETAIL is
         select 'X'
           from exp_prof_detail
          where exp_prof_key = I_exp_prof_key
            for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_PROF_DETAIL', 'EXP_PROF_DETAIL', NULL);
   open C_LOCK_PROF_DETAIL;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_PROF_DETAIL', 'EXP_PROF_DETAIL', NULL);
   close C_LOCK_PROF_DETAIL;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_exp_prof_key),
                                             NULL);

      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'EXP_PROF_SQL.LOCK_PROF_DETAILS',
                                             to_char(SQLCODE));
      return FALSE;
END LOCK_PROF_DETAILS;
----------------------------------------------------------------------------------------
FUNCTION DEL_PROF_DETAILS(O_error_message IN OUT VARCHAR2,
                          I_exp_prof_key  IN     EXP_PROF_HEAD.EXP_PROF_KEY%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(50)   := 'EXP_PROF_SQL.DEL_PROF_DETAILS';
   L_table         VARCHAR2(30)   := 'EXP_PROF_DETAIL';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_EXP_PROF_DETAIL is
      select 'x'
        from exp_prof_detail
       where exp_prof_key = I_exp_prof_key
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_EXP_PROF_DETAIL','EXP_PROF_DETAIL','Key: '||to_char(I_exp_prof_key));
   open C_LOCK_EXP_PROF_DETAIL;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_EXP_PROF_DETAIL','EXP_PROF_DETAIL','Key: '||to_char(I_exp_prof_key));
   close C_LOCK_EXP_PROF_DETAIL;
   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'EXP_PROF_DETAIL',NULL);
   delete from exp_prof_detail
         where exp_prof_key = I_exp_prof_key;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_exp_prof_key),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEL_PROF_DETAILS;
----------------------------------------------------------------------------------------
FUNCTION CHECK_HEADER_NO_DETAILS(O_error_message     IN OUT VARCHAR2,
                                 O_exists            IN OUT BOOLEAN,
                                 I_exp_prof_type     IN     EXP_PROF_HEAD.EXP_PROF_TYPE%TYPE,
                                 I_module            IN     EXP_PROF_HEAD.MODULE%TYPE,
                                 I_key_value_1       IN     EXP_PROF_HEAD.KEY_VALUE_1%TYPE,
                                 I_key_value_2       IN     EXP_PROF_HEAD.KEY_VALUE_2%TYPE)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(40) := 'EXP_PROF_SQL.CHECK_HEADER_NO_DETAILS';
   L_exists      VARCHAR2(1)  := 'N';

   cursor C_CHECK_FOR_DETAILS is
      select 'Y'
        from exp_prof_head eh
       where eh.exp_prof_type   = I_exp_prof_type
         and eh.module          = I_module
         and eh.key_value_1     = I_key_value_1
         and (eh.key_value_2    = I_key_value_2
          or (eh.key_value_2    is NULL
              and I_key_value_2 is NULL))
         and eh.exp_prof_key not in
               (select ed.exp_prof_key
                  from exp_prof_detail ed);

BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK FOR_DETAILS','EXP_PROF_HEAD, EXP_PROF_DETAIL', NULL);
   open C_CHECK_FOR_DETAILS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK FOR_DETAILS','EXP_PROF_HEAD, EXP_PROF_DETAIL', NULL);
   fetch C_CHECK_FOR_DETAILS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK FOR_DETAILS','EXP_PROF_HEAD, EXP_PROF_DETAIL', NULL);
   close C_CHECK_FOR_DETAILS;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
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

END CHECK_HEADER_NO_DETAILS;
---------------------------------------------------------------------------------------------
FUNCTION BASE_PROF_EXIST(O_error_message     IN OUT VARCHAR2,
                         O_exists            IN OUT BOOLEAN,
                         I_exp_prof_type     IN     EXP_PROF_HEAD.EXP_PROF_TYPE%TYPE,
                         I_module            IN     EXP_PROF_HEAD.MODULE%TYPE,
                         I_key_value_1       IN     EXP_PROF_HEAD.KEY_VALUE_1%TYPE,
                         I_key_value_2       IN     EXP_PROF_HEAD.KEY_VALUE_2%TYPE)
   RETURN BOOLEAN IS

   L_program     VARCHAR2(50) := 'EXP_PROF_SQL.BASE_PROF_EXIST';
   L_exists      VARCHAR2(1)  := 'N';

   cursor C_CHECK_BASE_PROF is
      select 'Y'
        from exp_prof_head
       where exp_prof_type      = I_exp_prof_type
         and module             = I_module
         and key_value_1        = I_key_value_1
         and (key_value_2       = I_key_value_2
          or (key_value_2       is NULL
              and I_key_value_2 is NULL))
         and base_prof_ind      = 'Y';

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_BASE_PROF','EXP_PROF_HEAD', NULL);
   open C_CHECK_BASE_PROF;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_BASE_PROF','EXP_PROF_HEAD', NULL);
   fetch C_CHECK_BASE_PROF into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_BASE_PROF','EXP_PROF_HEAD', NULL);
   close C_CHECK_BASE_PROF;
   ---
   if L_exists = 'N' then
      O_error_message := SQL_LIB.CREATE_MSG('NO_PROF_HEAD',NULL,NULL,NULL);
      O_exists := FALSE;
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
END BASE_PROF_EXIST;
--------------------------------------------------------------------------------------
END EXP_PROF_SQL;
/

