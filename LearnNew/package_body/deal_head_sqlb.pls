CREATE OR REPLACE PACKAGE BODY DEAL_HEAD_SQL AS

----------------------------------------------------------------------------------------
FUNCTION GET_ATTRIB(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                    O_exists          IN OUT   BOOLEAN,
                    O_deal_head_rec   IN OUT   DEAL_HEAD%ROWTYPE,
                    I_deal_id         IN       DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS

   L_null_parameter_name  VARCHAR2(30);
   NULL_PARAMETER         EXCEPTION;

   cursor C_DEAL_HEAD_REC is
      select *
        from deal_head
       where deal_id = I_deal_id;

BEGIN

   --Validate input parameters
   if I_deal_id is NULL then
      L_null_parameter_name := 'deal_id';
      raise NULL_PARAMETER;
   end if;

   --Verify if record exists
   SQL_LIB.SET_MARK('OPEN','C_DEAL_HEAD_REC','DEAL_HEAD',to_char(I_deal_id));
   open C_DEAL_HEAD_REC;

   SQL_LIB.SET_MARK('FETCH','C_DEAL_HEAD_REC','DEAL_HEAD',to_char(I_deal_id));
   fetch C_DEAL_HEAD_REC into O_deal_head_rec;

   O_exists := C_DEAL_HEAD_REC%FOUND;

   SQL_LIB.SET_MARK('CLOSE','C_DEAL_HEAD_REC','DEAL_HEAD',to_char(I_deal_id));
   close C_DEAL_HEAD_REC;
   ---

   return TRUE;

EXCEPTION
   when NULL_PARAMETER then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             L_null_parameter_name,
                                            'DEAL_HEAD_SQL.GET_ATTRIB',
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_HEAD_SQL.GET_ATTRIB',
                                             TO_CHAR(SQLCODE));
      return FALSE;

END GET_ATTRIB;
--------------------------------------------------------------------------------------
END DEAL_HEAD_SQL;
/

