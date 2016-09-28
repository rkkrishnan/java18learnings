CREATE OR REPLACE PACKAGE BODY DYNAMIC_HIER_CODE_SQL AS

--------------------------------------------------------------------

FUNCTION GET_CODE_DESC(O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                       O_client_name      IN OUT  VARCHAR2,
                       O_client_name_abbr IN OUT  VARCHAR2,
                       I_rms_name         IN      VARCHAR2)
   RETURN BOOLEAN IS

   L_length            NUMBER;
   L_key               TL_SHADOW.KEY%TYPE;
   L_translated_value  TL_SHADOW.TRANSLATED_VALUE%TYPE;
   ---
   cursor C_GET_CODE is
      select client_name, abbr_name
        from dynamic_hier_code
       where rms_name = upper(I_rms_name);
   ---
   cursor C_TRANSLATE is
      select tl_shadow.translated_value
        from tl_shadow
       where tl_shadow.key  = UPPER(L_key)
         and tl_shadow.lang = GET_USER_LANG;
BEGIN
   open C_GET_CODE;
   fetch C_GET_CODE into O_client_name, O_client_name_abbr;
   close C_GET_CODE;
   ---
   if O_client_name is NULL then
      O_client_name := I_rms_name;
   end if;
   ---
   if O_client_name_abbr is NULL then
      O_client_name_abbr := rtrim(substrb(O_client_name, 1, 40));
   end if;
   ---
   if O_client_name != I_rms_name then
      if substr(I_rms_name, 1, 1) != lower(substr(I_rms_name, 1, 1)) then
         O_client_name := initcap(O_client_name);
         O_client_name_abbr := initcap(O_client_name_abbr);
      end if;
   end if;
   ---
   if GET_PRIMARY_LANG != GET_USER_LANG then
      L_key := O_client_name;
      ---
      open C_TRANSLATE;
      fetch C_TRANSLATE into L_translated_value;
      close C_TRANSLATE;
      ---
      if L_translated_value is not NULL then
         O_client_name := rtrim(substrb(L_translated_value, 1, 40));
      end if;
      ---
      L_translated_value := NULL;
      L_key := O_client_name_abbr;
      ---
      open C_TRANSLATE;
      fetch C_TRANSLATE into L_translated_value;
      close C_TRANSLATE;
      ---
      if L_translated_value is not NULL then
         O_client_name_abbr := rtrim(substrb(L_translated_value, 1, 40));
      end if;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQLERRM || 'DYNAMIC_HIER_CODE_SQL.GET_CODE_DESC' || to_char(SQLCODE);
     RETURN FALSE;
END GET_CODE_DESC;
-----------------------------------------------------------------------------------------
FUNCTION GET_CLIENT_NAMES(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                          O_names_table     IN OUT  client_names_table_type)
   RETURN BOOLEAN IS

   cursor C_NAMES is
      select *
        from dynamic_hier_code;

   L_loop_index    BINARY_INTEGER := 0;
   L_client_name   DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE;
   L_abbr_name     DYNAMIC_HIER_CODE.ABBR_NAME%TYPE;

BEGIN

   FOR rec in C_NAMES LOOP

      if GET_CODE_DESC(O_error_message,
                       L_client_name,
                       L_abbr_name,     -- the abbreviation for the client name
                       rec.rms_name) = FALSE then
         return FALSE;
      end if;

      O_names_table(L_loop_index).rms_name := rec.rms_name;
      O_names_table(L_loop_index).client_name := L_client_name;
      O_names_table(L_loop_index).abbr_name := L_abbr_name;

       L_loop_index := L_loop_index + 1;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DYNAMIC_HIER_CODE_SQL.GET_CLIENT_NAMES',
                                             to_char(SQLCODE));
      return FALSE;

END GET_CLIENT_NAMES;
-------------------------------------------------------------------------------
FUNCTION GET_MERCH_CLIENT_NAMES(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                O_division        IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE,
                                O_group           IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE,
                                O_department      IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE,
                                O_class           IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE,
                                O_subclass        IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE)
RETURN BOOLEAN IS

   L_dummy  DYNAMIC_HIER_CODE.ABBR_NAME%TYPE;

BEGIN

   if GET_CODE_DESC(O_error_message,
                    O_division,
                    L_dummy,
                    'Division') = FALSE then
      return FALSE;
   end if;
   if GET_CODE_DESC(O_error_message,
                    O_group,
                    L_dummy,
                    'Group') = FALSE then
      return FALSE;
   end if;
   if GET_CODE_DESC(O_error_message,
                    O_department,
                    L_dummy,
                    'Department') = FALSE then
      return FALSE;
   end if;
   if GET_CODE_DESC(O_error_message,
                    O_class,
                    L_dummy,
                    'Class') = FALSE then
      return FALSE;
   end if;
   if GET_CODE_DESC(O_error_message,
                    O_subclass,
                    L_dummy,
                    'Subclass') = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DYNAMIC_HIER_CODE_SQL.GET_MERCH_CLIENT_NAMES',
                                             to_char(SQLCODE));
      return FALSE;
END GET_MERCH_CLIENT_NAMES;
-------------------------------------------------------------------------------
FUNCTION GET_ORG_CLIENT_NAMES(O_error_message   IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                              O_company         IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE,
                              O_chain           IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE,
                              O_area            IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE,
                              O_region          IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE,
                              O_district        IN OUT  DYNAMIC_HIER_CODE.CLIENT_NAME%TYPE)
RETURN BOOLEAN IS
   L_dummy  DYNAMIC_HIER_CODE.ABBR_NAME%TYPE;

BEGIN

   if GET_CODE_DESC(O_error_message,
                    O_company,
                    L_dummy,
                    'Company') = FALSE then
      return FALSE;
   end if;
   if GET_CODE_DESC(O_error_message,
                    O_chain,
                    L_dummy,
                    'Chain') = FALSE then
      return FALSE;
   end if;
   if GET_CODE_DESC(O_error_message,
                    O_area,
                    L_dummy,
                    'Area') = FALSE then
      return FALSE;
   end if;
   if GET_CODE_DESC(O_error_message,
                    O_region,
                    L_dummy,
                    'Region') = FALSE then
      return FALSE;
   end if;
   if GET_CODE_DESC(O_error_message,
                    O_district,
                    L_dummy,
                    'District') = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'DYNAMIC_HIER_CODE_SQL.GET_ORG_CLIENT_NAMES',
                                             to_char(SQLCODE));
      return FALSE;
END GET_ORG_CLIENT_NAMES;
--------------------------------------------------------------------------------------------
END DYNAMIC_HIER_CODE_SQL;
/

