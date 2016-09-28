CREATE OR REPLACE PACKAGE BODY DEAL_THRESHOLD_SQL AS

RECORD_LOCKED   EXCEPTION;
PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

------------------------------------------------------------------------------
FUNCTION NEXT_REV_NO (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      O_revision_no     IN OUT DEAL_THRESHOLD_REV.REV_NO%TYPE,
                      I_deal_id         IN     DEAL_THRESHOLD_REV.DEAL_ID%TYPE,
                      I_deal_detail_id  IN     DEAL_THRESHOLD_REV.DEAL_DETAIL_ID%TYPE,
                      I_lower_limit     IN     DEAL_THRESHOLD_REV.LOWER_LIMIT%TYPE,
                      I_upper_limit     IN     DEAL_THRESHOLD_REV.UPPER_LIMIT%TYPE)
RETURN BOOLEAN IS

   cursor C_REV_NO is
      Select max(dtr.rev_no) + 1
        from deal_threshold_rev dtr
       where dtr.deal_id = I_deal_id
         and dtr.deal_detail_id = I_deal_detail_id
         and dtr.lower_limit = I_lower_limit
         and dtr.upper_limit = I_upper_limit;
   L_program  VARCHAR2(64) := 'DEAL_THRESHOLD_SQL.NEXT_REV_NO';
BEGIN
   if I_deal_id is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_deal_id',
         'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_deal_detail_id is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_deal_detail_id',
         'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_lower_limit is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_lower_limit',
        'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_upper_limit is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_upper_limit',
        'NULL', 'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_REV_NO','DEAL_THRESHOLD_REV','DEAL_ID: '||I_deal_id);
   open  C_REV_NO;
   SQL_LIB.SET_MARK('FETCH','C_REV_NO','DEAL_THRESHOLD_REV','DEAL_ID: '||I_deal_id);
   fetch  C_REV_NO into O_revision_no;
   SQL_LIB.SET_MARK('CLOSE','C_REV_NO','DEAL_THRESHOLD_REV','DEAL_ID: '||I_deal_id);
   close C_REV_NO;
   if O_revision_no is NULL then
      O_revision_no := 1;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;

END NEXT_REV_NO;
-----------------------------------------------------------------------------------------

FUNCTION THRESHOLD_REV (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        I_deal_id         IN     DEAL_THRESHOLD_REV.DEAL_ID%TYPE,
                        I_deal_detail_id  IN     DEAL_THRESHOLD_REV.DEAL_DETAIL_ID%TYPE,
                        I_revision_no     IN     DEAL_THRESHOLD_REV.REV_NO%TYPE,
                        I_lower_limit     IN     DEAL_THRESHOLD_REV.LOWER_LIMIT%TYPE,
                        I_upper_limit     IN     DEAL_THRESHOLD_REV.UPPER_LIMIT%TYPE,
                        I_action_ind      IN     DEAL_THRESHOLD_REV.ACTION%TYPE)
RETURN BOOLEAN IS

   L_order_no      DEAL_HEAD.ORDER_NO%TYPE;
   L_program       VARCHAR2(64) := 'DEAL_THRESHOLD_SQL.THRESHOLD_REV';
   L_vdate         DATE         := GET_VDATE();

   cursor C_DEAL_THRESHOLD is
      select dt.value,
             dt.target_level_ind,
             dt.total_ind,
             dt.reason,
             dh.order_no
        from deal_threshold dt,
             deal_head dh
       where dt.deal_id = I_deal_id
         and dt.deal_detail_id = I_deal_detail_id
         and dt.lower_limit = I_lower_limit
         and dt.upper_limit = I_upper_limit
         and dh.deal_id = dt.deal_id;
   L_deal_threshold_rec C_DEAL_THRESHOLD%ROWTYPE;
   cursor C_LOCK_DEAL_CALC_QUEUE (c_order_no deal_head.order_no%TYPE) is
      select 'x'
        from deal_calc_queue
       where order_no = c_order_no
         FOR UPDATE NOWAIT;

BEGIN

   if I_deal_id is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_deal_id',
         'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_deal_detail_id is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_deal_detail_id',
         'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_lower_limit is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_lower_limit',
        'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_upper_limit is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_upper_limit',
        'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_revision_no is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_revision_no',
        'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_action_ind is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_action_ind',
        'NULL', 'NOT NULL');
      return FALSE;
   end if;
   if I_action_ind = 'I' or I_action_ind = 'U' then
      SQL_LIB.SET_MARK('OPEN','C_DEAL_THRESHOLD','DEAL_THRESHOLD', 'DEAL_ID: '||I_deal_id);
      open C_DEAL_THRESHOLD;
      SQL_LIB.SET_MARK('FETCH','C_DEAL_THRESHOLD','DEAL_THRESHOLD','DEAL_ID: '||I_deal_id);
      fetch C_DEAL_THRESHOLD into L_deal_threshold_rec;
      L_order_no := L_deal_threshold_rec.order_no ;
      insert into DEAL_THRESHOLD_REV(deal_id,
                                     deal_detail_id,
                                     lower_limit,
                                     upper_limit,
                                     rev_no,
                                     value,
                                     target_level_ind,
                                     total_ind,
                                     action,
                                     reason,
                                     revision_date,
                                     last_update_id,
                                     last_update_datetime)
                              values(I_deal_id,
                                     I_deal_detail_id,
                                     I_lower_limit,
                                     I_upper_limit,
                                     I_revision_no,
                                     L_deal_threshold_rec.value,
                                     L_deal_threshold_rec.target_level_ind,
                                     L_deal_threshold_rec.total_ind,
                                     I_action_ind,
                                     L_deal_threshold_rec.reason,
                                     L_vdate,
                                     user,
                                     sysdate);
      BEGIN
         if L_deal_threshold_rec.order_no is not NULL then
            insert into deal_calc_queue(order_no,
                                        recalc_all_ind,
                                        override_manual_ind,
                                        order_appr_ind)
                                 values(L_order_no,
                                        'N',
                                        'N',
                                        'N');
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_DEAL_THRESHOLD','DEAL_THRESHOLD','DEAL_ID: '||I_deal_id);
         close C_DEAL_THRESHOLD;
      EXCEPTION
         when DUP_VAL_ON_INDEX then
            SQL_LIB.SET_MARK('CLOSE','C_DEAL_THRESHOLD','DEAL_THRESHOLD','DEAL_ID: '||I_deal_id);
            close C_DEAL_THRESHOLD;
            if L_deal_threshold_rec.order_no is not NULL then
               -- lock table before attempting update
               SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_CALC_QUEUE','DEAL_THRESHOLD', 'ORDER_NO: ' ||  L_order_no);
               open C_LOCK_DEAL_CALC_QUEUE(L_order_no);
               SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_CALC_QUEUE','DEAL_THRESHOLD', 'ORDER_NO: ' ||  L_order_no);
               close C_LOCK_DEAL_CALC_QUEUE;
               update deal_calc_queue
                  set recalc_all_ind = 'N',
                      override_manual_ind = 'N',
                      order_appr_ind = 'N'
                where order_no = L_order_no;
            end if;
      END;
   elsif I_action_ind = 'D' then
      insert into DEAL_THRESHOLD_REV(deal_id,
                                     deal_detail_id,
                                     lower_limit,
                                     upper_limit,
                                     rev_no,
                                     value,
                                     target_level_ind,
                                     total_ind,
                                     action,
                                     reason,
                                     revision_date,
                                     last_update_id,
                                     last_update_datetime)
                              values(I_deal_id,
                                     I_deal_detail_id,
                                     I_lower_limit,
                                     I_upper_limit,
                                     I_revision_no,
                                     0,
                                    'N',
                                    'N',
                                     I_action_ind,
                                     NULL,
                                     L_vdate,
                                     user,
                                     sysdate);
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;

END THRESHOLD_REV;

END DEAL_THRESHOLD_SQL;

/

