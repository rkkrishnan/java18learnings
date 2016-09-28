CREATE OR REPLACE PACKAGE BODY BAL_GROUP_SQL AS
-----------------------------------------------------------------------------------
FUNCTION GET_CASHIER_REGISTER(O_error_message    IN OUT VARCHAR2,
                              O_cashier          IN OUT SA_BALANCE_GROUP.CASHIER%TYPE,
                              O_register         IN OUT SA_BALANCE_GROUP.REGISTER%TYPE,
                              I_store_day_seq_no IN     SA_STORE_DAY.STORE_DAY_SEQ_NO%TYPE,
                              I_bal_group_seq_no IN     SA_BALANCE_GROUP.BAL_GROUP_SEQ_NO%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program   VARCHAR2(50)  := 'BAL_GROUP_SQL.GET_CASHIER_REGISTER';
   ---
   cursor C_GET_CASHIER_REGISTER is
      select cashier,
             register
        from sa_balance_group
       where bal_group_seq_no = I_bal_group_seq_no
         and store_day_seq_no = I_store_day_seq_no;
BEGIN
   ---
   if I_store_day_seq_no is NOT NULL and
      I_bal_group_seq_no is NOT NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_CASHIER_REGISTER','SA_BALANCE_GROUP',NULL);
      open C_GET_CASHIER_REGISTER;
      SQL_LIB.SET_MARK('FETCH','C_GET_CASHIER_REGISTER','SA_BALANCE_GROUP',NULL);
      fetch C_GET_CASHIER_REGISTER into O_cashier,
                                        O_register;
      SQL_LIB.SET_MARK('CLOSE','C_GET_CASHIER_REGISTER','SA_BALANCE_GROUP',NULL);
      close C_GET_CASHIER_REGISTER;
   else
      O_error_message  := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                              NULL,
                                              NULL,
                                              NULL);
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
      return FALSE;
END GET_CASHIER_REGISTER;
------------------------------------------------------------------------------------
FUNCTION CHECK_DUPS(O_error_message    IN OUT VARCHAR2,
                    O_exists           IN OUT BOOLEAN,
                    I_store_day_seq_no IN     SA_STORE_DAY.STORE_DAY_SEQ_NO%TYPE,
                    I_cashier          IN     SA_BALANCE_GROUP.CASHIER%TYPE,
                    I_register         IN     SA_BALANCE_GROUP.REGISTER%TYPE,
                    I_start_datetime   IN     SA_BALANCE_GROUP.START_DATETIME%TYPE,
                    I_end_datetime     IN     SA_BALANCE_GROUP.END_DATETIME%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program  VARCHAR2(50) := 'BAL_GROUP_SQL.CHECK_DUPS';
   L_exists   VARCHAR2(1)  := 'N';
   ---
   cursor C_CHECK_CASHIER_TIME_DUPS is
      select 'Y'
        from sa_balance_group
       where store_day_seq_no = I_store_day_seq_no
         and (cashier = I_cashier
              and ((I_cashier is NOT NULL and cashier is NOT NULL)
                    or (I_cashier is NULL and cashier is NULL)))
         and ((to_char(I_start_datetime,          'MMDDYYYYHH24:MI')
                   BETWEEN to_char(start_datetime,'MMDDYYYYHH24:MI')
                and to_char(end_datetime,         'MMDDYYYYHH24:MI')
                and ((I_start_datetime is NOT NULL and start_datetime is NOT NULL)
                   or (I_start_datetime is NULL and start_datetime is NULL)))
             or (to_char(I_end_datetime,          'MMDDYYYYHH24:MI')
                   BETWEEN to_char(start_datetime,'MMDDYYYYHH24:MI')
                and to_char(end_datetime,         'MMDDYYYYHH24:MI')
                and ((I_end_datetime is NOT NULL and start_datetime is NOT NULL)
                   or (I_end_datetime is NULL and start_datetime is NULL)))
             or start_datetime is NULL
             or (to_char(I_start_datetime,    'MMDDYYYYHH24:MI')
                   <= to_char(start_datetime, 'MMDDYYYYHH24:MI')
                 and to_char(I_end_datetime,  'MMDDYYYYHH24:MI')
                   >= to_char(start_datetime, 'MMDDYYYYHH24:MI'))
             or (to_char(I_end_datetime,      'MMDDYYYYHH24:MI')
                   >= to_char(end_datetime,   'MMDDYYYYHH24:MI')
                 and to_char(I_start_datetime,'MMDDYYYYHH24:MI')
                   <= to_char(end_datetime,   'MMDDYYYYHH24:MI')));
   ---
   cursor C_CHECK_CASHIER_NO_TIME_DUPS is
      select 'Y'
        from sa_balance_group
       where store_day_seq_no = I_store_day_seq_no
         and cashier = I_cashier;
   ---
   cursor C_CHECK_REGISTER_TIME_DUPS is
      select 'Y'
        from sa_balance_group
       where store_day_seq_no = I_store_day_seq_no
         and (register = I_register
              and ((I_register is NOT NULL and register is NOT NULL)
                    or (I_register is NULL and register is NULL)))
         and ((to_char(I_start_datetime,       'MMDDYYYYHH24:MI')
              BETWEEN to_char(start_datetime,  'MMDDYYYYHH24:MI')
                  and to_char(end_datetime,    'MMDDYYYYHH24:MI')
                  and ((I_start_datetime is NOT NULL and start_datetime is NOT NULL)
                        or (I_start_datetime is NULL and start_datetime is NULL)))
              or (to_char(I_end_datetime,      'MMDDYYYYHH24:MI')
              BETWEEN to_char(start_datetime,  'MMDDYYYYHH24:MI')
                  and to_char(end_datetime,    'MMDDYYYYHH24:MI')
                  and ((I_end_datetime is NOT NULL and start_datetime is NOT NULL)
                        or (I_end_datetime is NULL and start_datetime is NULL)))
                  or start_datetime is NULL
             or (to_char(I_start_datetime,    'MMDDYYYYHH24:MI')
                   <= to_char(start_datetime, 'MMDDYYYYHH24:MI')
                 and to_char(I_end_datetime,  'MMDDYYYYHH24:MI')
                   >= to_char(start_datetime, 'MMDDYYYYHH24:MI'))
             or (to_char(I_end_datetime,      'MMDDYYYYHH24:MI')
                   >= to_char(end_datetime,   'MMDDYYYYHH24:MI')
                 and to_char(I_start_datetime,'MMDDYYYYHH24:MI')
                   <= to_char(end_datetime,   'MMDDYYYYHH24:MI')));
   ---
   cursor C_CHECK_REGISTER_NO_TIME_DUPS is
      select 'Y'
        from sa_balance_group
       where store_day_seq_no = I_store_day_seq_no
         and register = I_register;
BEGIN
   if I_store_day_seq_no is NULL or
         (I_cashier is NULL and I_register is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_cashier is NOT NULL then
      if I_start_datetime is NOT NULL then
         SQL_LIB.SET_MARK('OPEN','C_CHECK_CASHIER_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         open C_CHECK_CASHIER_TIME_DUPS;
         SQL_LIB.SET_MARK('FETCH','C_CHECK_CASHIER_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         fetch C_CHECK_CASHIER_TIME_DUPS into L_exists;
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_CASHIER_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         close C_CHECK_CASHIER_TIME_DUPS;
      else
         SQL_LIB.SET_MARK('OPEN','C_CHECK_CASHIER_NO_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         open C_CHECK_CASHIER_NO_TIME_DUPS;
         SQL_LIB.SET_MARK('FETCH','C_CHECK_CASHIER_NO_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         fetch C_CHECK_CASHIER_NO_TIME_DUPS into L_exists;
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_CASHIER_NO_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         close C_CHECK_CASHIER_NO_TIME_DUPS;
      end if;
   else --- Register is not NULL.
      if I_start_datetime is NOT NULL then
         SQL_LIB.SET_MARK('OPEN','C_CHECK_REGISTER_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         open C_CHECK_REGISTER_TIME_DUPS;
         SQL_LIB.SET_MARK('FETCH','C_CHECK_REGISTER_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         fetch C_CHECK_REGISTER_TIME_DUPS into L_exists;
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_REGISTER_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         close C_CHECK_REGISTER_TIME_DUPS;
      else
         SQL_LIB.SET_MARK('OPEN','C_CHECK_REGISTER_NO_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         open C_CHECK_REGISTER_NO_TIME_DUPS;
         SQL_LIB.SET_MARK('FETCH','C_CHECK_REGISTER_NO_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         fetch C_CHECK_REGISTER_NO_TIME_DUPS into L_exists;
         SQL_LIB.SET_MARK('CLOSE','C_CHECK_REGISTER_NO_TIME_DUPS','SA_BALANCE_GROUP',NULL);
         close C_CHECK_REGISTER_NO_TIME_DUPS;
      end if;
   end if;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
   else
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
END CHECK_DUPS;
--------------------------------------------------------------------------------------
FUNCTION INSERT_BAL_GROUP(O_error_message        IN OUT  VARCHAR2,
                          O_bal_group_inserted   IN OUT  BOOLEAN,
                          O_new_bal_group_seq_no IN OUT  SA_BALANCE_GROUP.BAL_GROUP_SEQ_NO%TYPE,
                          I_store_day_seq_no     IN      SA_STORE_DAY.STORE_DAY_SEQ_NO%TYPE,
                          I_cashier              IN      SA_BALANCE_GROUP.CASHIER%TYPE,
                          I_register             IN      SA_BALANCE_GROUP.REGISTER%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program          VARCHAR2(50) := 'BAL_GROUP_SQL.INSERT_BAL_GROUP';
   L_exists           BOOLEAN      := FALSE;
   L_seq_value        NUMBER;

BEGIN
   O_bal_group_inserted := FALSE;
   ---
   if I_store_day_seq_no is NOT NULL and
      (I_cashier is NOT NULL or
       I_register is NOT NULL) then
      if CHECK_DUPS(O_error_message,
                    L_exists,
                    I_store_day_seq_no,
                    I_cashier,
                    I_register,
                    NULL,
                    NULL) = FALSE then
         return FALSE;
      end if;
      ---
      if L_exists = FALSE then
         if SA_SEQUENCE2_SQL.GET_BAL_GROUP_SEQ(O_error_message,
                                               L_seq_value) = FALSE then
            return FALSE;
         end if;
         ---
         insert into sa_balance_group(store_day_seq_no,
                                      bal_group_seq_no,
                                      register,
                                      cashier)
                               values(I_store_day_seq_no,
                                      L_seq_value,
                                      I_register,
                                      I_cashier);
         if SQL%FOUND then
            O_bal_group_inserted   := TRUE;
            O_new_bal_group_seq_no := L_seq_value;
         end if;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                             NULL,
                                             NULL,
                                             NULL);
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
END INSERT_BAL_GROUP;
-------------------------------------------------------------------------------------
FUNCTION CASHIER_EXISTS(O_error_message IN OUT  VARCHAR2,
                        O_exists 	IN OUT  BOOLEAN,
                        O_cashier_name  IN OUT  SA_EMPLOYEE.NAME%TYPE,
                        I_cashier       IN      SA_BALANCE_GROUP.CASHIER%TYPE)
 RETURN BOOLEAN IS
   ---
   L_program  VARCHAR2(64) := 'BAL_GROUP_SQL.CASHIER_EXISTS';
   L_exists   VARCHAR2(1)  := 'N';
   L_name     SA_EMPLOYEE.NAME%TYPE;
   L_cashier  SA_BALANCE_GROUP.CASHIER%TYPE;
   ---
   cursor C_EXISTS is
      select distinct e.name name,
                      s.pos_id id
        from sa_employee e,
             sa_store_emp s
       where get_primary_lang = get_user_lang
         and e.emp_id         = s.emp_id
         and e.emp_type       = 'S'
         and s.pos_id         = I_cashier
      union all
      select distinct c.code_desc name,
                      b.cashier id
        from sa_balance_group b,
             code_detail c
       where not exists (select 'x'
                           from sa_store_emp t
                          where t.pos_id = b.cashier)
         and c.code_type = 'SAND'
         and c.code      = 'N'
         and b.cashier   = I_cashier
         and get_user_lang = get_primary_lang
      union all
      select distinct nvl(tl.translated_value, c.code_desc) name,
                      b.cashier id
        from sa_balance_group b,
             code_detail c,
             tl_shadow tl
       where get_primary_lang != get_user_lang
         and not exists (select 'x'
                           from sa_store_emp t
                          where t.pos_id = b.cashier)
         and c.code_type = 'SAND'
         and c.code      = 'N'
         and b.cashier   = I_cashier
         and upper(c.code_desc) = tl.key(+)
         and get_user_lang      = tl.lang(+);
BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_EXISTS','SA_EMPLOYEE,SA_STORE_EMP,SA_BALANCE_GROUP',NULL);
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_EXISTS','SA_EMPLOYEE,SA_STORE_EMP,SA_BALANCE_GROUP',NULL);
   fetch C_EXISTS into L_name,
                       L_cashier;
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS','SA_EMPLOYEE,SA_STORE_EMP,SA_BALANCE_GROUP',NULL);
   close C_EXISTS;
   ---
   if L_name is not NULL then
      O_exists       := TRUE;
      O_cashier_name := L_name;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END CASHIER_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION CASHIER_REGISTER_EXISTS(O_error_message     IN OUT  VARCHAR2,
                                 O_exists            IN OUT  BOOLEAN,
                                 I_store_day_seq_no  IN      SA_TRAN_HEAD.STORE_DAY_SEQ_NO%TYPE,
                                 I_cashier           IN      SA_TRAN_HEAD.CASHIER%TYPE,
                                 I_register          IN      SA_TRAN_HEAD.REGISTER%TYPE,
                                 I_start_datetime    IN      SA_TRAN_HEAD.TRAN_DATETIME%TYPE,
                                 I_end_datetime      IN      SA_TRAN_HEAD.TRAN_DATETIME%TYPE,
				 I_store	     IN	     SA_TRAN_HEAD.STORE%TYPE DEFAULT NULL,
				 I_day		     IN	     SA_TRAN_HEAD.DAY%TYPE DEFAULT NULL)
   RETURN BOOLEAN IS
   ---
   L_program  VARCHAR2(60) := 'BAL_GROUP_SQL.CASHIER_REGISTER_EXISTS';
   L_exists   VARCHAR2(1)  := 'N';
   L_store    SA_STORE_DAY.STORE%TYPE := I_store;
   L_day      SA_STORE_DAY.DAY%TYPE   := I_day;

   cursor C_GET_CASHIER_REG is
      select 'Y'
        from sa_tran_head
       where store_day_seq_no = I_store_day_seq_no
	 and store = L_store
	 and day = L_day
         and ((cashier    = I_cashier and cashier is NOT NULL)
             or (register = I_register and register is NOT NULL and cashier is NULL))
         and to_char(tran_datetime, 'MMDDYYYYHH24:MI')
             BETWEEN to_char(I_start_datetime, 'MMDDYYYYHH24:MI')
                     and to_char(I_end_datetime, 'MMDDYYYYHH24:MI');
BEGIN

   if I_store_day_seq_no is NOT NULL and
         (I_cashier is NOT NULL or I_register is NOT NULL) then
      ---
      if L_store is NULL or L_day is NULL then
         if STORE_DAY_SQL.GET_INTERNAL_DAY(o_error_message,
                                           L_store,
                                           L_day,
                                           I_store_day_seq_no,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      O_exists := FALSE;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_CASHIER_REG ','SA_TRAN_HEAD','CASHIER '||I_cashier);
      open C_GET_CASHIER_REG;
      SQL_LIB.SET_MARK('FETCH','C_GET_CASHIER_REG ','SA_TRAN_HEAD','CASHIER '||I_cashier);
      fetch C_GET_CASHIER_REG into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_GET_CASHIER_REG ','SA_TRAN_HEAD','CASHIER '||I_cashier);
      close C_GET_CASHIER_REG;
      ---
      if L_exists = 'Y' then
         O_exists := TRUE;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                             NULL,
                                             NULL,
                                             NULL);
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
END CASHIER_REGISTER_EXISTS;
------------------------------------------------------------------------------------------
FUNCTION TOTAL_EXISTS(O_error_message     IN OUT  VARCHAR2,
                      O_exists            IN OUT  BOOLEAN,
                      I_bal_group_seq_no  IN OUT  SA_TOTAL.BAL_GROUP_SEQ_NO%TYPE,
		      I_store		  IN      SA_TOTAL.STORE%TYPE DEFAULT NULL,
		      I_day		  IN      SA_TOTAL.DAY%TYPE DEFAULT NULL)
   RETURN BOOLEAN IS
   ---
   L_program  VARCHAR2(60) := 'BAL_GROUP_SQL.TOTAL_EXISTS';
   L_exists   VARCHAR2(1)  := 'N';
   L_store    SA_STORE_DAY.STORE%TYPE := I_store;
   L_day      SA_STORE_DAY.DAY%TYPE   := I_day;

   cursor C_GET_STORE_DAY is
      select store,
	     day
        from sa_total
       where bal_group_seq_no = I_bal_group_seq_no;

   cursor C_CHECK_TOTAL is
      select 'Y'
        from sa_total
       where bal_group_seq_no = I_bal_group_seq_no
	 and store	      = L_store
	 and day	      = L_day;

BEGIN

   if I_bal_group_seq_no is NOT NULL then
      ---
      if L_store is NULL or L_day is NULL then
         SQL_LIB.SET_MARK('OPEN','C_GET_STORE_DAY','SA_STORE_DAY',NULL);
         open C_GET_STORE_DAY;

         SQL_LIB.SET_MARK('FETCH','C_GET_STORE_DAY','SA_STORE_DAY',NULL);
         fetch C_GET_STORE_DAY into L_store,
	                            L_day;

         SQL_LIB.SET_MARK('CLOSE','C_GET_STORE_DAY','SA_STORE_DAY',NULL);
         close C_GET_STORE_DAY;
      end if;
      ---
      O_exists := FALSE;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CHECK_TOTAL','SA_TOTAL','BAL_GROUP_SEQ_NO '||to_char(I_bal_group_seq_no));
      open C_CHECK_TOTAL;
      SQL_LIB.SET_MARK('FETCH','C_CHECK_TOTAL','SA_TOTAL','BAL_GROUP_SEQ_NO '||to_char(I_bal_group_seq_no));
      fetch C_CHECK_TOTAL into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_TOTAL','SA_TOTAL','BAL_GROUP_SEQ_NO '||to_char(I_bal_group_seq_no));
      close C_CHECK_TOTAL;
      ---
      if L_exists = 'Y' then
         O_exists := TRUE;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                             NULL,
                                             NULL,
                                             NULL);
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
END TOTAL_EXISTS;
------------------------------------------------------------------------------------------
FUNCTION GET_BAL_GROUP_INFO(O_error_message    IN OUT  VARCHAR2,
                            O_register         IN OUT  SA_TRAN_HEAD.REGISTER%TYPE,
                            O_cashier          IN OUT  SA_TRAN_HEAD.CASHIER%TYPE,
                            O_cashier_name     IN OUT  SA_EMPLOYEE.NAME%TYPE,
                            I_store_day_seq_no IN      SA_BALANCE_GROUP.STORE_DAY_SEQ_NO%TYPE,
                            I_bal_group_seq_no IN      SA_BALANCE_GROUP.BAL_GROUP_SEQ_NO%TYPE,
                            I_store            IN      STORE.STORE%TYPE)
   RETURN BOOLEAN IS
   ---
   L_program   VARCHAR2(60) := 'SA_BALANCE_GROUP_SQL.GET_BAL_GROUP_INFO';
   ---
   cursor C_GET_INFO is
      select distinct register,
                      cashier
        from sa_balance_group
       where store_day_seq_no   = I_store_day_seq_no
         and bal_group_seq_no   = I_bal_group_seq_no;
BEGIN
   ---
   if I_store_day_seq_no is NULL or I_bal_group_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_NULL_INPUT_VAR',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   O_register     := NULL;
   O_cashier      := NULL;
   O_cashier_name := NULL;
   SQL_LIB.SET_MARK('OPEN','C_GET_INFO','SA_BALANCE_GROUP',NULL);
   open C_GET_INFO;
   SQL_LIB.SET_MARK('FETCH','C_GET_INFO','SA_BALANCE_GROUP',NULL);
   fetch C_GET_INFO into O_register,
                         O_cashier;
   SQL_LIB.SET_MARK('CLOSE','C_GET_INFO','SA_BALANCE_GROUP',NULL);
   close C_GET_INFO;
   ---
   if O_cashier is NOT NULL then
      if SA_EMPLOYEE_SQL.GET_CASHIER_NAME(O_error_message,
                                          O_cashier_name,
                                          O_cashier,
                                          I_store) = FALSE then
         O_cashier_name := NULL;
      end if;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_BAL_GROUP_INFO;
------------------------------------------------------------------------------------------
FUNCTION DELETE_BALANCE_GROUP(O_error_message     IN OUT  VARCHAR2,
                              O_bal_group_deleted IN OUT  BOOLEAN,
                              I_tran_seq_no       IN      sa_tran_head.tran_seq_no%TYPE,
                              I_store_day_seq_no  IN      sa_balance_group.store_day_seq_no%TYPE,
                              I_cashier           IN      sa_balance_group.cashier%TYPE,
                              I_register          IN      sa_balance_group.register%TYPE,
			      I_store		  IN      sa_tran_head.store%TYPE DEFAULT NULL,
			      I_day		  IN      sa_tran_head.day%TYPE DEFAULT NULL)
RETURN BOOLEAN IS

   L_program              VARCHAR2(60) := 'BAL_GROUP_SQL.DELETE_BALANCE_GROUP';
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   L_record_selected_ind  VARCHAR2(1)  := 'N';
   L_bal_group_seq_no     SA_BALANCE_GROUP.BAL_GROUP_SEQ_NO%TYPE;
   L_balance_level_ind    SA_SYSTEM_OPTIONS.BALANCE_LEVEL_IND%TYPE;
   L_exists               BOOLEAN;
   L_store                SA_STORE_DAY.STORE%TYPE := I_store;
   L_day                  SA_STORE_DAY.DAY%TYPE   := I_day;

   cursor C_TRAN_SEQ is
      select 'x'
        from sa_tran_head
       where store 	      = L_store
	 and day              = L_day
         and tran_seq_no     != I_tran_seq_no
         and store_day_seq_no = I_store_day_seq_no
         and (   (cashier  = I_cashier  and I_cashier  is NOT NULL)
              or (register = I_register and I_register is NOT NULL));

   cursor C_CONFLICT_EXISTS is
      select 'x'
        from sa_error
       where bal_group_seq_no = L_bal_group_seq_no
      UNION ALL
      select 'x'
        from sa_error_rev
       where bal_group_seq_no = L_bal_group_seq_no
      UNION ALL
      select 'x'
        from sa_error_temp
       where bal_group_seq_no = L_bal_group_seq_no
      UNION ALL
      select 'x'
        from sa_error_wksht
       where bal_group_seq_no = L_bal_group_seq_no
      UNION ALL
      select 'x'
        from sa_total
       where bal_group_seq_no = L_bal_group_seq_no;

   cursor C_LOCK_SA_BALANCE_GROUP is
      select 'x'
        from sa_balance_group
       where store_day_seq_no = I_store_day_seq_no
         and bal_group_seq_no = L_bal_group_seq_no
         for update nowait;

BEGIN

   O_bal_group_deleted := FALSE;
   ---
   if I_tran_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM',
                                            'I_tran_seq_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   elsif I_store_day_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM',
                                            'I_store_day_seq_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   elsif I_cashier is NULL and I_register is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM',
                                            'I_cashier and I_register',
                                            'NULL',
                                            'one of them NOT NULL');
      return FALSE;
   elsif I_cashier is NOT NULL and I_register is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM',
                                            'I_cashier and I_register',
                                            'NOT NULL',
                                            'one of them NULL');
      return FALSE;
   end if;
   ---
   if L_store is NULL or L_day is NULL then
      if STORE_DAY_SQL.GET_INTERNAL_DAY(o_error_message,
                                        L_store,
                                        L_day,
                                        I_store_day_seq_no,
                                        NULL,
                                        NULL,
                                        NULL,
                                        I_tran_seq_no) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_TRAN_SEQ',
                    'SA_BALANCE_GROUP',
                    'store_day_seq_no '||to_char(I_store_day_seq_no)||', cashier '||I_cashier||', register '||I_register);
   open C_TRAN_SEQ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_TRAN_SEQ',
                    'SA_BALANCE_GROUP',
                    'store_day_seq_no '||to_char(I_store_day_seq_no)||', cashier '||I_cashier||', register '||I_register);
   fetch C_TRAN_SEQ into L_record_selected_ind;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_TRAN_SEQ',
                    'SA_BALANCE_GROUP',
                    'store_day_seq_no '||to_char(I_store_day_seq_no)||', cashier '||I_cashier||', register '||I_register);
   close C_TRAN_SEQ;
   ---
   if L_record_selected_ind = 'N' then
      if GET_BAL_GROUP_SEQ(O_error_message,
                           L_exists,
                           L_bal_group_seq_no,
                           L_balance_level_ind,
                           I_store_day_seq_no,
                           I_cashier,
                           I_register,
                           NULL, /* start date/time */
                           NULL  /* end date/time   */) = FALSE then
         return FALSE;
      end if;
      if NOT L_exists then
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_CONFLICT_EXISTS',
                       'SA_ERROR, SA_ERROR_REV, SA_ERROR_TEMP, SA_ERROR_WKSHT, SA_TOTAL',
                       'bal_group_seq_no '||to_char(L_bal_group_seq_no));
      open C_CONFLICT_EXISTS;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CONFLICT_EXISTS',
                       'SA_ERROR, SA_ERROR_REV, SA_ERROR_TEMP, SA_ERROR_WKSHT, SA_TOTAL',
                       'bal_group_seq_no '||to_char(L_bal_group_seq_no));
      fetch C_CONFLICT_EXISTS into L_record_selected_ind;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CONFLICT_EXISTS',
                       'SA_ERROR, SA_ERROR_REV, SA_ERROR_TEMP, SA_ERROR_WKSHT, SA_TOTAL',
                       'bal_group_seq_no '||to_char(L_bal_group_seq_no));
      close C_CONFLICT_EXISTS;
      ---
      if L_record_selected_ind = 'N' then
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_SA_BALANCE_GROUP',
                          'SA_BALANCE_GROUP',
                          'store_day_seq_no '||to_char(I_store_day_seq_no)||', cashier '||I_cashier||', register '||I_register);
         open C_LOCK_SA_BALANCE_GROUP;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_SA_BALANCE_GROUP',
                          'SA_BALANCE_GROUP',
                          'store_day_seq_no '||to_char(I_store_day_seq_no)||', cashier '||I_cashier||', register '||I_register);
         close C_LOCK_SA_BALANCE_GROUP;
         ---
         delete from sa_balance_group
          where store_day_seq_no = I_store_day_seq_no
            and bal_group_seq_no = L_bal_group_seq_no;
         if SQL%FOUND then
            O_bal_group_deleted := TRUE;
         end if;
      end if;
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED',
                                            'SA_BALANCE_GROUP',
                                            'store_day_seq_no: '||to_char(I_store_day_seq_no), /* key value 1 */
                                            'bal_group_seq_no: '||to_char(L_bal_group_seq_no)  /* key value 2 */);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_BALANCE_GROUP;
------------------------------------------------------------------------------------------
FUNCTION GET_BAL_GROUP_SEQ(O_error_message       IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exists              IN OUT  BOOLEAN,
                           O_bal_group_seq_no    IN OUT  SA_BALANCE_GROUP.BAL_GROUP_SEQ_NO%TYPE,
                           IO_balance_level_ind  IN OUT  SA_SYSTEM_OPTIONS.BALANCE_LEVEL_IND%TYPE,
                           I_store_day_seq_no    IN      SA_BALANCE_GROUP.STORE_DAY_SEQ_NO%TYPE,
                           I_cashier             IN      SA_BALANCE_GROUP.CASHIER%TYPE,
                           I_register            IN      SA_BALANCE_GROUP.REGISTER%TYPE,
                           I_start_datetime      IN      SA_BALANCE_GROUP.START_DATETIME%TYPE,
                           I_end_datetime        IN      SA_BALANCE_GROUP.END_DATETIME%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(60)  := 'BAL_GROUP_SQL.GET_BAL_GROUP_SEQ';

   cursor C_GET_BAL_GROUP_SEQ is
      select bal_group_seq_no
        from sa_balance_group
       where store_day_seq_no = I_store_day_seq_no
         and (   (    cashier = I_cashier
                  AND IO_balance_level_ind = 'C')
              OR
                 (    register = I_register
                  AND IO_balance_level_ind = 'R'))
         and nvl(to_char(start_datetime, 'YYYYMMDDHH24MISS'), -1) = nvl(to_char(I_start_datetime, 'YYYYMMDDHH24MISS'), -1)
         and nvl(to_char(end_datetime, 'YYYYMMDDHH24MISS'), -1) = nvl(to_char(I_end_datetime, 'YYYYMMDDHH24MISS'), -1);

BEGIN
   ---
   if IO_balance_level_ind is NULL then
      if SA_SYSTEM_OPTIONS_SQL.GET_BAL_LEVEL(O_error_message,
                                             IO_balance_level_ind) = FALSE then
         return FALSE;
      end if;
   end if;
   ---

   ---
   if I_store_day_seq_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_store_day_seq_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---

   ---
   if IO_balance_level_ind = 'C' then
      if I_cashier is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                               'I_cashier',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
   end if;
   ---

   ---
   if IO_balance_level_ind = 'R' then
      if I_register is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                               'I_register',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
   end if;
   ---

   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_BAL_GROUP_SEQ',
                    'SA_BALANCE_GROUP',
                    'store_day_seq_no '||to_char(I_store_day_seq_no)||
                    ', cashier  '||(I_cashier)||
                    ', register '||(I_register)||
                    ', start_datetime '||to_char(I_start_datetime)||
                    ', end_datetime '||to_char(I_end_datetime));

   open C_GET_BAL_GROUP_SEQ;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_BAL_GROUP_SEQ',
                    'SA_BALANCE_GROUP',
                    'store_day_seq_no '||to_char(I_store_day_seq_no)||
                    ', cashier  '||(I_cashier)||
                    ', register '||(I_register)||
                    ', start_datetime '||to_char(I_start_datetime)||
                    ', end_datetime '||to_char(I_end_datetime));

   fetch C_GET_BAL_GROUP_SEQ into O_bal_group_seq_no;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_BAL_GROUP_SEQ',
                    'SA_BALANCE_GROUP',
                    'store_day_seq_no '||to_char(I_store_day_seq_no)||
                    ', cashier  '||(I_cashier)||
                    ', register '||(I_register)||
                    ', start_datetime '||to_char(I_start_datetime)||
                    ', end_datetime '||to_char(I_end_datetime));

   close C_GET_BAL_GROUP_SEQ;

   if O_bal_group_seq_no is NULL then
         O_exists := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('BAL_GROUP_NOT_EXISTS',
                                               NULL,
                                               NULL,
                                               NULL);
      else
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
END GET_BAL_GROUP_SEQ;
------------------------------------------------------------------------------------------
END BAL_GROUP_SQL;
/

