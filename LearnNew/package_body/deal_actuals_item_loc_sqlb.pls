CREATE OR REPLACE PACKAGE BODY DEAL_ACTUALS_ITEM_LOC_SQL AS
--------------------------------------------------------
FUNCTION GET_NEXT_DAI_ID(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_dai_id        IN OUT DEAL_ACTUALS_ITEM_LOC.DAI_ID%TYPE)
   RETURN BOOLEAN is

   L_first_time               VARCHAR2(1) := 'Y';
   L_wrap_seq_no              DEAL_ACTUALS_ITEM_LOC.DAI_ID%TYPE;
   L_exists                   VARCHAR2(1) :=  'N' ;

   cursor C_DAI_EXISTS is
      select 'Y'
        from deal_actuals_item_loc
       where dai_id  = O_dai_id
         and rownum = 1;

   cursor C_SELECT_NEXTVAL is
      select DEAL_ACTUALS_ITEMLOC_SEQ.NEXTVAL
        from dual;
BEGIN

   SQL_LIB.SET_MARK('OPEN','C_SELECT_NEXTVAL','DUAL',NULL);
   open C_SELECT_NEXTVAL;
   ---
   LOOP
      SQL_LIB.SET_MARK('FETCH','C_SELECT_NEXTVAL','DUAL',NULL);
      fetch C_SELECT_NEXTVAL into O_dai_id;
      ---
      if L_first_time = 'Y' then
         L_wrap_seq_no   := O_dai_id;
         L_first_time    := 'N';
      elsif O_dai_id = L_wrap_seq_no then
         O_error_message := SQL_LIB.CREATE_MSG('NO_DAI_NUM', NULL, NULL, NULL);
         SQL_LIB.SET_MARK('CLOSE','C_SELECT_NEXTVAL','DUAL',NULL);
         close C_SELECT_NEXTVAL;
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN','C_DAI_EXISTS','DEAL_ACTUALS_ITEM_LOC', 'dai_id: '||to_char(O_dai_id));
      open C_DAI_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_DAI_EXISTS','DEAL_ACTUALS_ITEM_LOC', 'dai_id:'||to_char(O_dai_id));
      fetch C_DAI_EXISTS into L_exists;
      SQL_LIB.SET_MARK('CLOSE','C_DAI_EXISTS','DEAL_ACTUALS_ITEM_LOC', 'dai_id:'||to_char(O_dai_id));
      close C_DAI_EXISTS;
      if L_exists = 'N'  then
         SQL_LIB.SET_MARK('CLOSE','C_SELECT_NEXTVAL','DUAL',NULL);
         close C_SELECT_NEXTVAL;
         return TRUE;
      end if;
      ---
   END LOOP;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_ACTUALS_ITEM_LOC_SQL.GET_NEXT_DAI_ID',
                                            to_char(SQLCODE));
   return FALSE;
END GET_NEXT_DAI_ID;
--------------------------------------------------------
END;
/

