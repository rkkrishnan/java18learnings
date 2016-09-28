CREATE OR REPLACE PACKAGE BODY DEAL_INT_SQL AS
------------------------------------------------------------------------------------------------
FUNCTION UPDATE_DEAL_PROM(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          I_deal_id            IN       DEAL_DETAIL.DEAL_ID%TYPE,
                          I_deal_detail_id     IN       DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                          I_contribution_pct   IN       DEAL_DETAIL.VFP_DEFAULT_CONTRIB_PCT%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(60)      := 'DEAL_INT_SQL.UPDATE_DEAL_PROM';
   L_check_vfp          VARCHAR2(1);
   L_check_vfp_detail   VARCHAR2(1);
   L_vdate              PERIOD.VDATE%TYPE := GET_VDATE();
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);

   cursor C_CHECK_VFP is
      select 'x'
        from deal_head
       where deal_id        = I_deal_id
         and billing_type   = 'BBVFP'
         and rownum = 1;

   cursor C_CHECK_VFP_DETAIL is
      select 'x'
        from deal_detail dd,
             deal_comp_prom dcp
       where dd.deal_id            = I_deal_id
         and dd.deal_detail_id     = I_deal_detail_id
         and dd.collect_start_date <= L_vdate
         and rownum = 1;

   cursor C_LOCK_DEAL is
      select 'x'
        from deal_detail
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         for update nowait;

BEGIN
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   if I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_detail_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   if I_contribution_pct is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_contribution_pct',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_VFP',
                    'deal_head',
                    NULL);
   open C_CHECK_VFP;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_VFP',
                    'deal_head',
                    NULL);
   fetch C_CHECK_VFP into L_check_vfp;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_VFP',
                    'deal_head',
                    NULL);
   close C_CHECK_VFP;
   if L_check_vfp is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('VFP_DEAL_NOT_EXIST',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_VFP_DETAIL',
                    'deal_detail',
                    NULL);
   open C_CHECK_VFP_DETAIL;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_VFP_DETAIL',
                    'deal_detail',
                    NULL);
   fetch C_CHECK_VFP_DETAIL into L_check_vfp_detail;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_VFP_DETAIL',
                    'deal_detail',
                    NULL);
   close C_CHECK_VFP_DETAIL;

   if L_check_vfp_detail is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('VFP_DEAL_NOT_EXIST',
                                            NULL,
                                            NULL,
                                            NULL);
         return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL',
                    'deal_detail',
                    NULL);
   open C_LOCK_DEAL;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL',
                    'deal_detail',
                    NULL);
   close C_LOCK_DEAL;
   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    'deal_detail',
                    NULL);
   update deal_detail
      set vfp_default_contrib_pct = I_contribution_pct
    where deal_id         = I_deal_id
      and deal_detail_id  = I_deal_detail_id;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'deal_detail',
                                            to_char(I_deal_id),
                                            to_char(I_deal_detail_id));
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_DEAL_PROM;
------------------------------------------------------------------------------------------------
END DEAL_INT_SQL;
/

