CREATE OR REPLACE PACKAGE BODY BANNER_SQL AS
--------------------------------------------------------------------------------
FUNCTION GET_BANNER_NAME    (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_banner_name          IN OUT BANNER.BANNER_NAME%TYPE,
                             I_banner_id            IN     BANNER.BANNER_ID%TYPE)
   RETURN BOOLEAN IS

   L_program_name            VARCHAR2(50) := 'BANNER_SQL.GET_BANNER_NAME';
   L_banner_name             BANNER.BANNER_NAME%TYPE;

   cursor C_BANNER_NAME is
      select banner_name
        from banner
       where banner_id  = I_banner_id;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_BANNER_NAME',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   open C_BANNER_NAME;
   SQL_LIB.SET_MARK('FETCH',
                    'C_BANNER_NAME',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   fetch C_BANNER_NAME into L_banner_name;

   if C_BANNER_NAME%NOTFOUND then
      O_error_message := 'INV_BANNER';
      SQL_LIB.SET_MARK('CLOSE',
                       'C_BANNER_NAME',
                       'BANNER',
                       'BANNER ID: '||to_char(I_banner_id));
      close C_BANNER_NAME;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_BANNER_NAME',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   close C_BANNER_NAME;
   if LANGUAGE_SQL.TRANSLATE(L_banner_name,
                             O_banner_name,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END GET_BANNER_NAME;
--------------------------------------------------------------------------------
FUNCTION BANNER_ID_EXIST     (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exist                 IN OUT BOOLEAN,
                              I_banner_id             IN     BANNER.BANNER_ID%TYPE)
   RETURN BOOLEAN IS

   L_program_name            VARCHAR2(50) := 'BANNER_SQL.BANNER_ID_EXIST';
   L_exists                  VARCHAR2(1);
   cursor C_BANNER_EXIST is
      select 'x'
        from banner
       where banner_id  = I_banner_id;

BEGIN
   O_exist := FALSE;

   SQL_LIB.SET_MARK('OPEN',
                    'C_BANNER_EXIST',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   open C_BANNER_EXIST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_BANNER_EXIST',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   fetch C_BANNER_EXIST into L_exists;

   if C_BANNER_EXIST%NOTFOUND then
      O_error_message := 'INV_BANNER';
      SQL_LIB.SET_MARK('CLOSE',
                       'C_BANNER_EXIST',
                       'BANNER',
                       'BANNER ID: '||to_char(I_banner_id));
      close C_BANNER_EXIST;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_BANNER_EXIST',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   close C_BANNER_EXIST;
   O_exist := TRUE;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END BANNER_ID_EXIST;
--------------------------------------------------------------------------------
FUNCTION DELETE_BANNER        (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_exist                 IN OUT BOOLEAN,
                               I_banner_id             IN     BANNER.BANNER_ID%TYPE)
   RETURN BOOLEAN IS
   L_program_name            VARCHAR2(50) := 'BANNER_SQL.DELETE_BANNER';
   L_exists                  VARCHAR2(1);

   cursor C_BANNER_EXIST_CHANNEL is
      select 'x'
        from channels
       where channels.banner_id  = I_banner_id;

   L_table                   VARCHAR2(30) := 'BANNER';

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_BANNER_EXIST_CHANNEL ',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   open C_BANNER_EXIST_CHANNEL;
   SQL_LIB.SET_MARK('FETCH',
                    'C_BANNER_EXIST_CHANNEL ',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   fetch C_BANNER_EXIST_CHANNEL  into L_exists;

   if C_BANNER_EXIST_CHANNEL%FOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_BANNER_EXIST_CHANNEL ',
                       'BANNER',
                       'BANNER ID: '||to_char(I_banner_id));
      close C_BANNER_EXIST_CHANNEL;
      O_exist := TRUE;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_BANNER_EXIST_CHANNEL ',
                    'BANNER',
                    'BANNER ID: '||to_char(I_banner_id));
   close C_BANNER_EXIST_CHANNEL;

   O_exist := FALSE;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_BANNER;
--------------------------------------------------------------------------------------------
END BANNER_SQL;
/

