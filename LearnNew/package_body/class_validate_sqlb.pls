CREATE OR REPLACE PACKAGE BODY CLASS_VALIDATE_SQL AS

   FUNCTION EXIST(O_error_message IN OUT VARCHAR2,
                  I_dept          IN     NUMBER,
                  I_class         IN     NUMBER,
		  O_exist	  IN OUT BOOLEAN)
            return BOOLEAN is

      L_program    VARCHAR2(64) := 'CLASS_VALIDATE_SQL.EXIST';
      L_class      VARCHAR2(1);

-- This function determines if the entered class exists

      cursor C_CLASS is
         select 'x'
           from class
          where dept = I_dept
            and class = I_class;

   BEGIN
      open C_CLASS;
      fetch C_CLASS into L_class;
      if C_CLASS%NOTFOUND then
         O_exist := FALSE;
      else
	 O_exist := TRUE;
      end if;

      close C_CLASS;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
						SQLERRM,
						L_program,
						null);
	 RETURN FALSE;


   END EXIST;
END CLASS_VALIDATE_SQL;
/

