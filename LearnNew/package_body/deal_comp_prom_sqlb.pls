CREATE OR REPLACE PACKAGE BODY DEAL_COMP_PROM_SQL AS
----------------------------------------------------------------------------------
FUNCTION GET_ATTRIB (O_error_message        IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     O_deal_comp_prom_rec   IN OUT   DEAL_COMP_PROM%ROWTYPE,
                     I_deal_id              IN       DEAL_HEAD.DEAL_ID%TYPE,
                     I_deal_detail_id       IN       DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                     I_promotion_id         IN       DEAL_COMP_PROM.PROMOTION_ID%TYPE,
                     I_promo_comp_id        IN       DEAL_COMP_PROM.PROMO_COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(100)   := 'DEAL_COMP_PROM_SQL.GET_ATTRIB';

   cursor C_DEAL_COMP_PROM_REC is
      select *
        from deal_comp_prom
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and promotion_id   = I_promotion_id
         and promo_comp_id  = I_promo_comp_id;

BEGIN
   ---
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            'DEAL_COMP_PROM_SQL.GET_ATTRIB',
                                            'NULL');
      return FALSE;
   end if;
   --
   if I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_detail_id',
                                            'DEAL_COMP_PROM_SQL.GET_ATTRIB',
                                            'NULL');
      return FALSE;
   end if;
   ---
   if I_promotion_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_promotion_id',
                                            'DEAL_COMP_PROM_SQL.GET_ATTRIB',
                                            'NULL');
      return FALSE;
   end if;
   --
   if I_promo_comp_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_promo_comp_id',
                                            'DEAL_COMP_PROM_SQL.GET_ATTRIB',
                                            'NULL');
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_DEAL_COMP_PROM_REC',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   open C_DEAL_COMP_PROM_REC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DEAL_COMP_PROM_REC',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   fetch C_DEAL_COMP_PROM_REC into O_deal_comp_prom_rec;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DEAL_COMP_PROM_REC',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   close C_DEAL_COMP_PROM_REC;
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
FUNCTION CHECK_EXIST (O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      O_exists           IN OUT   BOOLEAN,
                      I_deal_id          IN       DEAL_HEAD.DEAL_ID%TYPE,
                      I_deal_detail_id   IN       DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                      I_promotion_id     IN       DEAL_COMP_PROM.PROMOTION_ID%TYPE,
                      I_promo_comp_id    IN       DEAL_COMP_PROM.PROMO_COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(100)   := 'DEAL_COMP_PROM_SQL.CHECK_EXIST';
   L_found     VARCHAR2(1);

   cursor C_CHECK_DEAL_COMP_PROM is
      select 'x'
        from deal_comp_prom
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and promotion_id   = I_promotion_id
         and promo_comp_id  = I_promo_comp_id
         and rownum         = 1;

BEGIN
   O_exists := FALSE;
   ---
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            'DEAL_COMP_PROM_SQL.CHECK_EXIST',
                                            'NULL');
      return FALSE;
   end if;
   --
   if I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_detail_id',
                                            'DEAL_COMP_PROM_SQL.CHECK_EXIST',
                                            'NULL');
      return FALSE;
   end if;
   ---
   if I_promotion_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_promotion_id',
                                            'DEAL_COMP_PROM_SQL.CHECK_EXIST',
                                            'NULL');
      return FALSE;
   end if;
   --
   if I_promo_comp_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_promo_comp_id',
                                            'DEAL_COMP_PROM_SQL.CHECK_EXIST',
                                            'NULL');
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_DEAL_COMP_PROM',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   open C_CHECK_DEAL_COMP_PROM;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_DEAL_COMP_PROM',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   fetch C_CHECK_DEAL_COMP_PROM into L_found;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_DEAL_COMP_PROM',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   close C_CHECK_DEAL_COMP_PROM;

   if L_found is NOT NULL then
      O_exists:= TRUE;
   else
      O_exists:= FALSE;
   end if;

   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END CHECK_EXIST;
----------------------------------------------------------------------------------
FUNCTION DELETE_DEAL_PROM (O_error_message        IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_deal_id              IN       DEAL_HEAD.DEAL_ID%TYPE,
                           I_deal_detail_id       IN       DEAL_DETAIL.DEAL_DETAIL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(100)   := 'DEAL_COMP_PROM_SQL.DELETE_DEAL_PROM';
   L_found     VARCHAR2(1);

   cursor C_CHECK_DEAL_COMP_PROM_EXIST is
      select 'x'
        from deal_comp_prom
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and rownum         = 1;

   cursor C_DELETE_DEAL_COMP_PROM_REC is
      select 'x'
        from deal_comp_prom
       where deal_id        = I_deal_id
         and deal_detail_id = I_deal_detail_id
         for update nowait;

BEGIN
   ---
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            'DEAL_COMP_PROM_SQL.DELETE_DEAL_PROM',
                                            'NULL');
      return FALSE;
   end if;
   --
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_DEAL_COMP_PROM_EXIST',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   open C_CHECK_DEAL_COMP_PROM_EXIST;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_DEAL_COMP_PROM_EXIST',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   fetch C_CHECK_DEAL_COMP_PROM_EXIST into L_found;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_DEAL_COMP_PROM_EXIST',
                    'DEAL_COMP_PROM',
                    'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
   close C_CHECK_DEAL_COMP_PROM_EXIST;
   ---
   if L_found is NOT NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_DELETE_DEAL_COMP_PROM_REC',
                       'DEAL_COMP_PROM',
                       'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
      open C_DELETE_DEAL_COMP_PROM_REC;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DELETE_DEAL_COMP_PROM_REC',
                       'DEAL_COMP_PROM',
                       'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));
      close C_DELETE_DEAL_COMP_PROM_REC;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'DEAL_COMP_PROM',
                       'deal_id: '||TO_CHAR(I_deal_id) ||'deal_detail_id: '||TO_CHAR(I_deal_detail_id));

      delete from deal_comp_prom
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;
   end if;

   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END DELETE_DEAL_PROM;
----------------------------------------------------------------------------------
END DEAL_COMP_PROM_SQL;
/

