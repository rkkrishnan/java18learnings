CREATE OR REPLACE PACKAGE BODY CHANNEL_SQL AS
--------------------------------------------------------------------------------
FUNCTION GET_CHANNEL_NAME    (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_channel_name          IN OUT CHANNELS.CHANNEL_NAME%TYPE,
                              I_channel_id            IN     CHANNELS.CHANNEL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program_name            VARCHAR2(50) := 'CHANNEL_SQL.GET_CHANNEL_NAME';
   L_channel_name            CHANNELS.CHANNEL_NAME%TYPE;

   cursor C_CHANNEL_NAME is
      select channel_name
        from channels
       where channel_id  = I_channel_id;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHANNEL_NAME',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   open C_CHANNEL_NAME;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHANNEL_NAME',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   fetch C_CHANNEL_NAME into L_channel_name;

   if C_CHANNEL_NAME%NOTFOUND then
      O_error_message := 'INV_CHANNEL';
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHANNEL_NAME',
                       'CHANNELS',
                       'CHANNEL ID: '||to_char(I_channel_id));
      close C_CHANNEL_NAME;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHANNEL_NAME',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   close C_CHANNEL_NAME;
   if LANGUAGE_SQL.TRANSLATE(L_channel_name,
                             O_channel_name,
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
END GET_CHANNEL_NAME;
--------------------------------------------------------------------------------


FUNCTION CHANNEL_ID_EXIST     (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_exist                 IN OUT BOOLEAN,
                               I_channel_id            IN     CHANNELS.CHANNEL_ID%TYPE)
   RETURN BOOLEAN IS
   L_program_name            VARCHAR2(50) := 'CHANNEL_SQL.CHANNEL_ID_EXIST';
   L_exists                  VARCHAR2(1);
   cursor C_CHANNEL_EXIST is
      select 'x'
        from channels
       where channel_id  = I_channel_id;

BEGIN
   O_exist := FALSE;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHANNEL_EXIST',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   open C_CHANNEL_EXIST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHANNEL_EXIST',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   fetch C_CHANNEL_EXIST into L_exists;

   if C_CHANNEL_EXIST%NOTFOUND then
      O_error_message := 'INV_CHANNEL';
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHANNEL_EXIST',
                       'CHANNELS',
                       'CHANNEL ID: '||to_char(I_channel_id));
      close C_CHANNEL_EXIST;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHANNEL_EXIST',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   close C_CHANNEL_EXIST;
   O_exist := TRUE;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END CHANNEL_ID_EXIST;


---------------------------------------------------------------------------------------


FUNCTION GET_CHANNEL_WH_NAME  (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_wh_name               IN OUT WH.WH_NAME%TYPE,
                               I_wh                    IN     WH.WH%TYPE,
                               I_channel_id            IN     CHANNELS.CHANNEL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program_name            VARCHAR2(50) := 'CHANNEL_SQL.GET_CHANNEL_WH_NAME';
   L_wh_name                 WH.WH_NAME%TYPE;
   L_exists                  VARCHAR2(1);

   cursor C_WH_NAME is
      select wh_name
        from wh
       where wh.wh = I_wh
         and wh.channel_id = I_channel_id;

   cursor C_WH_FINISHER is
      select 'x'
        from wh
       where wh.wh = I_wh
         and wh.finisher_ind = 'N';

BEGIN

   open C_WH_NAME;

   fetch C_WH_NAME into L_wh_name;

   if C_WH_NAME%NOTFOUND then
      close C_WH_NAME;
      O_error_message := 'WH_NOT_ATT_CHANN';
      return FALSE;
   end if;

   close C_WH_NAME;
   ---
   open C_WH_FINISHER;

   fetch C_WH_FINISHER into L_exists;

   if C_WH_FINISHER%NOTFOUND then
      close C_WH_FINISHER;
      O_error_message := SQL_LIB.CREATE_MSG('INV_WH_FIN');
      return FALSE;
   end if;

   close C_WH_FINISHER;

   if LANGUAGE_SQL.TRANSLATE(L_wh_name,
                             O_wh_name,
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
END GET_CHANNEL_WH_NAME;

--------------------------------------------------------------------------------
FUNCTION DELETE_CHANNEL       (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               O_exist                 IN OUT BOOLEAN,
                               I_channel_id            IN     CHANNELS.CHANNEL_ID%TYPE)
   RETURN BOOLEAN IS
   L_program_name            VARCHAR2(50) := 'CHANNEL_SQL.DELETE_CHANNEL';
   L_exists                  VARCHAR2(1);

   cursor C_CHANNEL_EXIST_WH_STORE is
      select 'x'
        from wh
       where wh.channel_id  = I_channel_id
      UNION ALL
      select 'x'
        from store
       where store.channel_id = I_channel_id;

   L_table                   VARCHAR2(30) := 'CHANNELS';

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHANNEL_EXIST_WH_STORE ',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   open C_CHANNEL_EXIST_WH_STORE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHANNEL_EXIST_WH_STORE ',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   fetch C_CHANNEL_EXIST_WH_STORE  into L_exists;

   if C_CHANNEL_EXIST_WH_STORE%FOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CHANNEL_EXIST_WH_STORE ',
                       'CHANNELS',
                       'CHANNEL ID: '||to_char(I_channel_id));
      close C_CHANNEL_EXIST_WH_STORE;
      O_exist := TRUE;
      return TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHANNEL_EXIST_WH_STORE ',
                    'CHANNELS',
                    'CHANNEL ID: '||to_char(I_channel_id));
   close C_CHANNEL_EXIST_WH_STORE;

   O_exist := FALSE;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program_name,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_CHANNEL;
--------------------------------------------------------------------------------
FUNCTION GET_DEAL_CHANNEL    (O_error_message         IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_channel_id            IN OUT CHANNELS.CHANNEL_ID%TYPE,
                              I_deal_id               IN     DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program_name            VARCHAR2(50) := 'CHANNEL_SQL.GET_DEAL_CHANNEL';
   L_channel_id              CHANNELS.CHANNEL_ID%TYPE;

   cursor C_DEAL_CHANNEL is
      select tsl_channel_id
        from deal_head
       where deal_id  = I_deal_id;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_DEAL_CHANNEL',
                    'DEAL_HEAD',
                    'DEAL ID: '||to_char(I_deal_id));
   open C_DEAL_CHANNEL;
   SQL_LIB.SET_MARK('FETCH',
                    'C_DEAL_CHANNEL',
                    'DEAL_HEAD',
                    'DEAL ID: '||to_char(I_deal_id));
   fetch C_DEAL_CHANNEL into L_channel_id;

   if C_DEAL_CHANNEL%NOTFOUND then
      O_error_message := 'INV_DEAL';
      SQL_LIB.SET_MARK('CLOSE',
                       'C_DEAL_CHANNEL',
                       'DEAL_HEAD',
                       'DEAL ID: '||to_char(I_deal_id));
      close C_DEAL_CHANNEL;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_DEAL_CHANNEL',
                    'DEAL_HEAD',
                    'DEAL ID: '||to_char(I_deal_id));
   close C_DEAL_CHANNEL;
   if LANGUAGE_SQL.TRANSLATE(L_channel_id,
                             O_channel_id,
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
END GET_DEAL_CHANNEL;
--------------------------------------------------------------------------------
END CHANNEL_SQL;
/

