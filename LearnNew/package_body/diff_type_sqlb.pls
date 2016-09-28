CREATE OR REPLACE PACKAGE BODY DIFF_TYPE_SQL AS
----------------------------------------------------------------
FUNCTION DIFF_TYPE_EXISTS(O_error_message  IN OUT  VARCHAR2,
                          O_exists         IN OUT  BOOLEAN,
                          I_diff_type      IN      DIFF_TYPE.DIFF_TYPE%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'DIFF_SQL.DIFF_TYPE_EXISTS';
   L_diff_type  DIFF_TYPE.DIFF_TYPE%TYPE := NULL;

   cursor C_CHECK_DIFF_TYPE is
      select diff_type
        from diff_type
       where diff_type = I_diff_type;

BEGIN

   open C_CHECK_DIFF_TYPE;
   fetch C_CHECK_DIFF_TYPE into L_diff_type;
   close C_CHECK_DIFF_TYPE;

   if L_diff_type is NULL then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;
END DIFF_TYPE_EXISTS;
--------------------------------------------------------------------------
FUNCTION CHECK_ASSOCIATION(O_error_message  IN OUT  VARCHAR2,
                           O_assoc_exists   IN OUT  BOOLEAN,
                           I_diff_type      IN      DIFF_TYPE.DIFF_TYPE%TYPE)
RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'DIFF_SQL.CHECK_ASSOCIATION';
   L_diff_type  DIFF_TYPE.DIFF_TYPE%TYPE := NULL;

   cursor C_CHECK_ASSOC is
      select diff_type
        from diff_group_head
       where diff_type = I_diff_type
      union
      select diff_type
        from diff_ids
       where diff_type = I_diff_type;

BEGIN

   open C_CHECK_ASSOC;
   fetch C_CHECK_ASSOC into L_diff_type;
   close C_CHECK_ASSOC;

   if L_diff_type is NULL then
      O_assoc_exists := FALSE;
   else
      O_assoc_exists := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;
END CHECK_ASSOCIATION;
--------------------------------------------------------------------------
FUNCTION GET_DESC(O_error_message     IN OUT    VARCHAR2,
                  O_diff_type_desc    IN OUT    DIFF_TYPE.DIFF_TYPE_DESC%TYPE,
                  I_diff_type         IN        DIFF_TYPE.DIFF_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'DIFF_TYPE_SQL.GET_DESC';
   L_desc       DIFF_TYPE.DIFF_TYPE_DESC%TYPE;

   cursor C_GET_DESC is
      select diff_type_desc
        from diff_type
       where diff_type = I_diff_type;

BEGIN
   open C_GET_DESC;
   fetch C_GET_DESC into L_desc;
   close C_GET_DESC;
   ---
   if L_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DIFF_TYPE',NULL,NULL,NULL);
      return FALSE;
   end if;
   ---
   if LANGUAGE_SQL.TRANSLATE(L_desc,
                             O_diff_type_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;
END GET_DESC;
--------------------------------------------------------------------------
END DIFF_TYPE_SQL;
/

