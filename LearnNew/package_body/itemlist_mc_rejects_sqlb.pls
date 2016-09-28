CREATE OR REPLACE PACKAGE BODY ITEMLIST_MC_REJECTS_SQL AS
-----------------------------------------------------------------------------------
FUNCTION INSERT_REJECTS (O_error_message IN OUT VARCHAR2,
                         I_item          IN     ITEM_MASTER.ITEM%TYPE,
                         I_locn_type     IN     ITEM_LOC.LOC_TYPE%TYPE,
                         I_locn          IN     ITEM_LOC.LOC%TYPE,
                     	 I_type          IN     VARCHAR2,
                     	 I_key           IN     VARCHAR2,
                         I_user_id       IN     USER_USERS.USERNAME%TYPE,
                         I_txt_1         IN     VARCHAR2 := NULL,
                      	 I_txt_2         IN     VARCHAR2 := NULL,
                     	 I_txt_3         IN     VARCHAR2 := NULL) return BOOLEAN IS

   L_reason     MC_REJECTION_REASONS.REJECTION_REASON%TYPE  :=  NULL;
   L_program    VARCHAR2(64)   := 'ITEMLIST_MC_REJECTS_SQL.INSERT_REJECTS';

BEGIN
   if not GET_REJECT_REASON (O_error_message,
	       		     L_reason,
                             I_key,
                             I_txt_1,
                             I_txt_2,
                             I_txt_3) then
      return FALSE;
   end if;

   insert into mc_rejections
      values (I_item,
              I_type,
              L_reason,
              I_locn,
              I_locn_type,
              I_user_id);

   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               NULL);
        return FALSE;
END INSERT_REJECTS;
----------------------------------------------------------------------------------------
FUNCTION GET_REJECT_REASON(O_error_message    IN OUT VARCHAR2,
                           O_reason           IN OUT VARCHAR2,
                           I_key              VARCHAR2,
                           I_txt_1            VARCHAR2 := null,
                           I_txt_2            VARCHAR2 := null,
                           I_txt_3            VARCHAR2 := null)
   return BOOLEAN IS

   cursor C_GET_MSG (S_KEY mc_rejection_reasons.reason_key%TYPE) is
      select rejection_reason,
             decode(rtk_lang - get_user_lang,
                    0, 1,                                  -- same as user_lang
                       decode(rtk_lang - get_primary_lang,
                              0, 2,                        -- same as primary_lang
                                 3                         -- not user_lang, not primary_lang
			       )
		    ) sort_field
        from mc_rejection_reasons
       where reason_key = S_KEY
         and get_user_lang = get_primary_lang
       union all
      select nvl(tl.translated_value,rejection_reason),
             decode(rtk_lang - get_user_lang,
                    0, 1,                                  -- same as user_lang
                       decode(rtk_lang - get_primary_lang,
                              0, 2,                        -- same as primary_lang
                                 3                         -- not user_lang, not primary_lang
		               )
		    ) sort_field
        from mc_rejection_reasons, tl_shadow tl
       where reason_key = S_KEY
         and get_user_lang != get_primary_lang
         and upper(rejection_reason) = tl.key (+)
         and get_user_lang = tl.lang (+)
       order by 2;

   L_program    VARCHAR2(64)  := 'ITEMLIST_MC_REJECTS_SQL.GET_REJECT_REASON';
   L_key        varchar2(255) := I_key;
   L_txt_1      MC_REJECTION_REASONS.REJECTION_REASON%TYPE := I_txt_1;
   L_txt_2      MC_REJECTION_REASONS.REJECTION_REASON%TYPE := I_txt_2;
   L_txt_3      MC_REJECTION_REASONS.REJECTION_REASON%TYPE := I_txt_3;
   L_ret_val    number        := 0;   -- dummy return!
   L_sub_str    varchar2(3)   := '%s?';
   L_total      number        :=  0;
   L_sort_field number;

BEGIN
   ---
   if I_key is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_key',
                                            'ITEMLIST_MC_REJECTS_SQL.GET_REJECT_REASON',
                                            'NULL');
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN', 'C_GET_MSG', 'MC_REJECTION_REASONS', 'Key: ' ||I_key);
   open C_GET_MSG (L_key);
   SQL_LIB.SET_MARK('FETCH', 'C_GET_MSG', 'MC_REJECTION_REASONS', 'Key: ' ||I_key);
   fetch C_GET_MSG into O_reason, L_sort_field;

   if C_GET_MSG%NOTFOUND then
      O_reason := 'INTERNAL ERROR INVALID KEY:  ' || L_key;
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_MSG', 'MC_REJECTION_REASONS', 'Key: ' ||I_key);
      close C_GET_MSG;
      return TRUE;
   end if;

   if (O_reason is not null) then
      L_total := L_total + LENGTH (O_reason);
   end if;

   if (L_txt_1 is not null) then
      if LANGUAGE_SQL.TRANSLATE(L_txt_1,
                                L_txt_1,
                                O_error_message) = FALSE then
         RETURN FALSE;
      end if;
      L_total := L_total + LENGTH (L_txt_1) + 1;
   end if;

   if (L_txt_2 is not null) then
      if LANGUAGE_SQL.TRANSLATE(L_txt_2,
                                L_txt_2,
                                O_error_message) = FALSE then
         RETURN FALSE;
      end if;
      L_total := L_total + LENGTH (L_txt_2) + 1;
   end if;

   if (L_txt_3 is not null) then
      if LANGUAGE_SQL.TRANSLATE(L_txt_3,
                                L_txt_3,
                                O_error_message) = FALSE then
         RETURN FALSE;
      end if;
      L_total := L_total + LENGTH (L_txt_3) + 1;
   end if;

   if (L_total > 1000) then
      O_reason := 'REJECTION_MESSAGE INTERNAL ERROR:  Error message is too long';
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_MSG', 'MC_REJECTION_REASONS', 'Key: ' ||I_key);
      close C_GET_MSG;
      return TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_MSG', 'MC_REJECTION_REASONS', 'Key: ' ||I_key);
   close C_GET_MSG;

   -- did the user send in a second parameter
   -- to be included/appended in the message.

   if L_txt_1 is not null then

   -- he did, so if msg IS on the table and that
   -- message has a substitute string in it then put
   -- the string in place of that substitute string,
   -- otherwise append it.

      L_sub_str := '%s1';

      if instr(O_reason, L_sub_str) > 0 then
         O_reason := replace (O_reason, L_sub_str, L_txt_1);
      else
         O_reason := O_reason || ' ' || L_txt_1;
      end if;
   end if;

   if L_txt_2 is not null then

   -- check second parameter

      L_sub_str := '%s2';

      if instr(O_reason, L_sub_str) > 0 then
         O_reason := replace (O_reason, L_sub_str, L_txt_2);
      else
         O_reason := O_reason || ' ' || L_txt_2;
      end if;
   end if;

   if L_txt_3 is not null then

   -- check third parameter

      L_sub_str := '%s3';

      if instr(O_reason, L_sub_str) > 0 then
         O_reason := replace (O_reason, L_sub_str, L_txt_3);
      else
         O_reason := O_reason || ' ' || L_txt_3;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
        O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               NULL);
        return FALSE;
END GET_REJECT_REASON;
-----------------------------------------------------------------
END ITEMLIST_MC_REJECTS_SQL;
/

