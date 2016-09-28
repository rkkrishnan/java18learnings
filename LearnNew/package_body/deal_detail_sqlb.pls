CREATE OR REPLACE PACKAGE BODY DEAL_DETAIL_SQL AS
----------------------------------------------------------------------------------
FUNCTION GET_ATTRIB (O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     O_exists            IN OUT   BOOLEAN,
                     O_deal_detail_rec   IN OUT   DEAL_DETAIL%ROWTYPE,
                     I_deal_id           IN       DEAL_HEAD.DEAL_ID%TYPE,
                     I_deal_detail_id    IN       DEAL_DETAIL.DEAL_DETAIL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(100)   := 'DEAL_DETAIL_SQL.GET_ATTRIB';

   cursor C_DEAL_DETAIL_REC is
      select *
        from deal_detail
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id;

BEGIN
   ---
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('DEAL_ID_REQUIRED',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   --
   if I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('DEAL_DETAIL_ID_REQUIRED',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_DEAL_DETAIL_REC',
                    'DEAL_DETAIL',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   open C_DEAL_DETAIL_REC;
   SQL_LIB.SET_MARK('FETCH',
                    'C_DEAL_DETAIL_REC',
                    'DEAL_DETAIL',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   fetch C_DEAL_DETAIL_REC into O_deal_detail_rec;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DEAL_DETAIL_REC',
                    'DEAL_DETAIL',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   close C_DEAL_DETAIL_REC;

   if O_deal_detail_rec.deal_id is NULL then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   --
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END GET_ATTRIB;
----------------------------------------------------------------------------------
END DEAL_DETAIL_SQL;
/

