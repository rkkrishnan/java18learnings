CREATE OR REPLACE PACKAGE BODY GEOGRAPHY_SQL AS
--------------------------------------------------------------------

FUNCTION COUNTRY_DESC(	O_error_message	IN OUT	VARCHAR2,
			I_country       IN     VARCHAR2,
			O_desc		IN OUT VARCHAR2)

RETURN BOOLEAN IS

   cursor C_ATTRIB is
   select country_desc
     from country
    where country_id = I_country;

BEGIN

   SQL_LIB.SET_MARK('OPEN' , 'C_ATTRIB', 'COUNTRY', I_country);
   open C_ATTRIB;
   SQL_LIB.SET_MARK('FETCH' , 'C_ATTRIB', 'COUNTRY', I_country);
   fetch C_ATTRIB into O_desc;
   if C_ATTRIB%NOTFOUND then
      O_error_message := sql_lib.create_msg('INV_COUNTRY',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE' , 'C_ATTRIB', 'COUNTRY', I_country);
      close C_ATTRIB;
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE' , 'C_ATTRIB', 'COUNTRY', I_country);
   close C_ATTRIB;

   if LANGUAGE_SQL.TRANSLATE(	O_desc,
					O_desc,
					O_error_message) = FALSE then
      RETURN FALSE;
   end if;

   RETURN TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
					     SQLERRM,
					    'GEOGRAPHY_SQL.COUNTRY_DESC',
					     to_char(SQLCODE));
   RETURN FALSE;

END COUNTRY_DESC;
--------------------------------------------------------------------
FUNCTION VALIDATE_STATE(i_state       IN     VARCHAR2,
                        o_exists      IN OUT VARCHAR2,
                        error_message IN OUT VARCHAR2) RETURN BOOLEAN IS

   L_exists   VARCHAR2(1);

   cursor C_STATE_EXISTS is
      select 'x'
        from state
       where state = i_state;
BEGIN
   open C_STATE_EXISTS;
   fetch C_STATE_EXISTS into L_exists;
   if C_STATE_EXISTS%NOTFOUND then
      o_exists := 'N';
   else
      o_exists := 'Y';
   end if;
   close C_STATE_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      error_message := sql_lib.create_msg('PACKAGE_ERROR',SQLERRM,'STATE_VALIDATE_SQL.EXIST',to_char(SQLCODE));
      return FALSE;
END VALIDATE_STATE;
--------------------------------------------------------------------
FUNCTION STATE_DESC(O_error_message IN OUT VARCHAR2,
                    O_desc          IN OUT state.description%TYPE,
                    I_state         IN     state.state%TYPE)
                    RETURN BOOLEAN IS

   cursor C_GET_DESC is
      select description
        from state
       where state = I_state;

BEGIN
   if I_state is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_state',
                                            'NULL',
                                            'NOT NULL');
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_GET_DESC', 'state', 'state: '||I_state);
   open C_GET_DESC;
   SQL_LIB.SET_MARK('FETCH', 'C_GET_DESC', 'state', 'state: '||I_state);
   fetch C_GET_DESC into O_desc;
   if C_GET_DESC%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_STATE',
                                             NULL,
                                             NULL,
                                             NULL);
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_DESC', 'state', 'state: '||I_state);
      close C_GET_DESC;
      RETURN FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_DESC', 'state', 'state: '||I_state);
   close C_GET_DESC;

   if LANGUAGE_SQL.TRANSLATE(O_desc,
                             O_desc,
                             O_error_message) = FALSE then
      RETURN FALSE;
   end if;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'GEOGRAPHY_SQL.STATE_DESC',
                                             to_char(SQLCODE));
   RETURN FALSE;

END STATE_DESC;
--------------------------------------------------------------------------------------------
END;
/

