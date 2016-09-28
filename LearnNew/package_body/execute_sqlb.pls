CREATE OR REPLACE PACKAGE BODY EXECUTE_SQL AS
---------------------------------------------------------------------------------
FUNCTION EXECUTE_SQL (O_ERROR_MESSAGE IN OUT VARCHAR2,
                      I_STATEMENT     IN     VARCHAR2)

RETURN BOOLEAN IS

   V_block_string	  VARCHAR2(10000) := NULL;
   V_cursor	        INTEGER	      := NULL;
   L_dummy          INTEGER         := NULL;
   L_error_message  VARCHAR2(255)   := NULL;

BEGIN

   V_block_string := 'BEGIN '||I_statement||' EXCEPTION when OTHERS then :O_error_message := (SQLERRM); END;';
   ---
   V_cursor := DBMS_SQL.OPEN_CURSOR;
   ---
   DBMS_SQL.PARSE(V_cursor, V_block_string, DBMS_SQL.V7);
   DBMS_SQL.BIND_VARIABLE(V_cursor, ':O_error_message', L_error_message, 255);
   ---
   L_dummy := DBMS_SQL.EXECUTE(V_cursor);
   ---
   DBMS_SQL.VARIABLE_VALUE(V_cursor, ':O_error_message', L_error_message);
   ---
   DBMS_SQL.CLOSE_CURSOR(V_cursor);
   ---
   O_error_message := L_error_message;
   ---
   if O_error_message is NULL then
      RETURN TRUE;
   else
      RETURN FALSE;
   end if;
   ---
EXCEPTION
   when OTHERS then
   O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                         SQLERRM,
                                         'EXECUTE_SQL.EXECUTE_SQL',
                                         NULL);
   RETURN FALSE;
END EXECUTE_SQL;
-------------------------------------------------------------------------------------
END EXECUTE_SQL;
/

