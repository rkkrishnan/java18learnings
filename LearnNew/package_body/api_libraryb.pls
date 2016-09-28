CREATE OR REPLACE PACKAGE BODY API_LIBRARY AS
-------------------------------------------------------------------------------------------

TYPE rib_settings_TBL is table of rib_settings%ROWTYPE;
LP_rib_settings       rib_settings_TBL;

-------------------------------------------------------------------------------------------
FUNCTION CONVERT_STRING_TO_DATE(O_error_message   IN OUT VARCHAR2,
                                O_date            IN OUT DATE,
                                I_datestring      IN     VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   --- Datestring is presumed to be of form 'DD-MM-YYYY:24HR:MI:SS'
   O_date := TO_DATE(I_datestring, 'DD-MM-YYYY:HH24:MI:SS');

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'API_LIBRARY.CONVERT_STRING_TO_DATE',
                                            to_char(SQLCODE));
   RETURN FALSE;
END CONVERT_STRING_TO_DATE;
--------------------------------------------------------------------------------------------
FUNCTION CONVERT_DATE_TO_STRING(O_error_message   IN OUT VARCHAR2,
                                O_datestring      IN OUT VARCHAR2,
                                I_date            IN     DATE)
RETURN BOOLEAN IS



BEGIN

   O_datestring := TO_CHAR(I_date,'DD-MM-YYYY:HH24:MI:SS');

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'API_LIBRARY.CONVERT_DATE_TO_STRING',
                                            to_char(SQLCODE));
   RETURN FALSE;
END CONVERT_DATE_TO_STRING;
--------------------------------------------------------------------------------
FUNCTION CREATE_MESSAGE(O_status        OUT VARCHAR2,
                        O_text          OUT VARCHAR2,
                        root            IN  OUT xmldom.DOMElement,
                        I_message_name  IN  VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   -- Create a new XML document whose root has the given tag name.
   if not rib_xml.newRoot(root,
                          I_message_name ) then
      HANDLE_ERRORS(O_status,
                    O_text,
                    XML_ERROR,
                    'API_LIBRARY.CREATE_MESSAGE');
      return FALSE;
   else
      O_status := API_CODES.SUCCESS;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      HANDLE_ERRORS(O_status,
                    O_text,
                    FATAL_ERROR,
                    'API_LIBRARY.CREATE_MESSAGE');
      return FALSE;

END CREATE_MESSAGE;
--------------------------------------------------------------------------------
FUNCTION WRITE_DOCUMENT(O_status        OUT    VARCHAR2,
                        O_text          OUT    VARCHAR2,
                        O_document      OUT    CLOB,
                        root            IN OUT xmldom.DOMElement)
RETURN BOOLEAN IS

BEGIN
   -- set the DTD on the document.
   rib_xml.setDocType(root);
   dbms_lob.createtemporary(O_document, TRUE);

   -- write the message out.
   if not rib_xml.writeRoot( root, O_document, false) then
      HANDLE_ERRORS(O_status,
                    O_text,
                    XML_ERROR,
                    'API_LIBRARY.WRITE_DOCUMENT');
      return FALSE;
   else
      O_status := API_CODES.DONE;
      rib_xml.freeRoot(root);
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      HANDLE_ERRORS(O_status,
                    O_text,
                    FATAL_ERROR,
                    'API_LIBRARY.WRITE_DOCUMENT');
      return FALSE;

END WRITE_DOCUMENT;
--------------------------------------------------------------------------------
FUNCTION CREATE_MESSAGE_STR(O_status        OUT VARCHAR2,
                            O_text          OUT VARCHAR2,
                            root            IN  OUT rib_sxw.SXWHandle,
                            I_message_name  IN  VARCHAR2)
RETURN BOOLEAN IS

BEGIN
   -- Create a new XML document whose root has the given tag name.
   rib_sxw.newRoot(root, I_message_name, O_status );
   if O_status != rib_sxw.SUCCESS then
      return FALSE;
   end if;

   O_status := API_CODES.SUCCESS;

   return TRUE;

EXCEPTION
   when OTHERS then
      HANDLE_ERRORS(O_status,
                    O_text,
                    FATAL_ERROR,
                    'API_LIBRARY.CREATE_MESSAGE_STR');
      return FALSE;

END CREATE_MESSAGE_STR;
--------------------------------------------------------------------------------
FUNCTION WRITE_DOCUMENT_STR(O_status        OUT    VARCHAR2,
                            O_text          OUT    VARCHAR2,
                            O_document      IN OUT nocopy CLOB,
                            root            IN OUT rib_sxw.SXWHandle)
RETURN BOOLEAN IS

BEGIN
   -- write the message out.
   rib_sxw.writeRoot( root, O_document, false, O_status);
   if O_status != rib_sxw.SUCCESS then
      return FALSE;
   end if;
   O_status := API_CODES.DONE;
   rib_sxw.freeRoot(root);

   return TRUE;

EXCEPTION
   when OTHERS then
      HANDLE_ERRORS(O_status,
                    O_text,
                    FATAL_ERROR,
                    'API_LIBRARY.WRITE_DOCUMENT_STR');
      return FALSE;

END WRITE_DOCUMENT_STR;
-------------------------------------------------------------------------------------------
PROCEDURE HANDLE_ERRORS(O_status               IN OUT  VARCHAR2,
                        IO_error_message       IN OUT  VARCHAR2,
                        I_cause                IN      VARCHAR2,
                        I_program              IN      VARCHAR2)
IS


   L_error_message VARCHAR2(255) := IO_error_message;
   L_error_type    VARCHAR2(5)   := NULL;

BEGIN

  /* Create initial error message to be parsed in SQL_LIB.
   * This error message may alread be created */
  if I_cause = WRONG_ORDER then
      L_error_message := SQL_LIB.CREATE_MSG('WRONG_ORDER',
                                             I_program,
                                             NULL,
                                             NULL);
   elsif I_cause = XML_ERROR then
      L_error_message := SQL_LIB.CREATE_MSG('XML_ERROR',
                                             I_program,
                                             NULL,
                                             NULL);
   elsif I_cause = FATAL_ERROR then
      if L_error_message is NULL then
         L_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                                 SQLERRM,
                                                 I_program,
                                                 to_char(SQLCODE));
      end if;
   elsif I_cause = NO_UPD_DONE then
      L_error_message := SQL_LIB.CREATE_MSG('NO_UPD_DONE',
                                             I_program,
                                             NULL,
                                             NULL);
   end if;

   /* Pass out parsed error message and error type */
   SQL_LIB.API_MSG(L_error_type,
                   L_error_message);

   if L_error_type = 'OR' then
       O_status := API_CODES.OUT_OF_SEQUENCE;
   elsif L_error_type in ('BL', 'OE') then
       O_status := API_CODES.UNHANDLED_ERROR;
   elsif L_error_type = 'LK' then
       O_status := API_CODES.LOCKED;
   else
       /* If PARSE_MSG fails, for example, we could get L_error_type = NULL */
       O_status := API_CODES.UNHANDLED_ERROR;
   end if;

   IO_error_message := L_error_message;


EXCEPTION
   when OTHERS then
      L_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'API_LIBRARY.HANDLE_ERRORS',
                                             to_char(SQLCODE));

      SQL_LIB.API_MSG(L_error_type,
                      L_error_message);

      IO_error_message := L_error_message;

      O_status := API_CODES.UNHANDLED_ERROR;

END HANDLE_ERRORS;
-------------------------------------------------------------------------------------------
FUNCTION readRoot(message     in clob,
                  messageName in varchar2)
return xmldom.DOMElement as

BEGIN

   return(rib_xml.readRoot(message, messageName, false, false));

END readRoot;
-------------------------------------------------------------------------------------------


PROCEDURE GET_RIB_SETTINGS(O_status_code            IN OUT VARCHAR2,
                           O_error_msg              IN OUT VARCHAR2,
                           O_max_details_to_publish    OUT NUMBER,
                           O_num_threads               OUT NUMBER,
                           O_minutes_time_lag          OUT NUMBER,
                           I_family                 IN     VARCHAR2)
IS
   cursor C_COUNT is
      select *
        from rib_settings;

   PROGRAM_ERROR         EXCEPTION;

BEGIN

   O_status_code := API_CODES.SUCCESS;

   if LP_rib_settings is NULL then
      open C_COUNT;
      fetch C_COUNT BULK COLLECT INTO LP_rib_settings;
      close C_COUNT;
   end if;

   FOR i IN 1..LP_rib_settings.COUNT LOOP
      if upper(LP_rib_settings(i).family) = upper(I_family) then
         O_max_details_to_publish := LP_rib_settings(i).max_details_to_publish;
         O_num_threads            := LP_rib_settings(i).num_threads;
         O_minutes_time_lag       := LP_rib_settings(i).minutes_time_lag;
         return;
      end if;
   END LOOP;

   O_error_msg := SQL_LIB.CREATE_MSG('NO_RIB_SETTINGS',
                                     I_family, NULL, NULL);
   raise PROGRAM_ERROR;

EXCEPTION
   when OTHERS then
      API_LIBRARY.HANDLE_ERRORS(O_status_code,
                                O_error_msg,
                                API_LIBRARY.FATAL_ERROR,
                                'API_LIBRARY.GET_RIB_SETTINGS');
END GET_RIB_SETTINGS;
-------------------------------------------------------------------------------------------

FUNCTION INIT(O_error_message IN OUT VARCHAR2)
RETURN BOOLEAN IS
BEGIN

   -- reset DATES_SQL cache as eWays do not reset database connection
   if DATES_SQL.RESET_GLOBALS(O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'API_LIBRARY.INIT',
                                            to_char(SQLCODE));
      return FALSE;

END INIT;
-------------------------------------------------------------------------------------------

END API_LIBRARY;
/

