CREATE OR REPLACE PACKAGE BODY INTERFACE_SQL AS
---------------------------------------------------------------------

FUNCTION INSERT_INTERFACE_ERROR (O_error_message IN OUT VARCHAR2,
                                 I_error         IN     IF_ERRORS.ERROR%TYPE,
                                 I_program_name  IN     IF_ERRORS.PROGRAM_NAME%TYPE,
                                 I_unit_of_work  IN     IF_ERRORS.UNIT_OF_WORK%TYPE)
RETURN BOOLEAN IS

L_program        VARCHAR2(64) := 'INTERFACE_SQL.INSERT_INTERFACE_ERROR';

BEGIN
   ---
   SQL_LIB.SET_MARK('INSERT',
                     NULL,
                    'IF_ERRORS',
                    'L_program');
   ---
   --- insert values to if_errors

   insert into if_errors(err_date,
                          error,
                          program_name,
                          unit_of_work)
                   values (sysdate,
                           I_error,
                           I_program_name,
                           I_unit_of_work);
   ---
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      RETURN FALSE;
END INSERT_INTERFACE_ERROR;
---------------------------------------------------------------------
END INTERFACE_SQL;
/

