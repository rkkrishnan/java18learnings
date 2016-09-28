CREATE OR REPLACE PACKAGE BODY DEPT_VALIDATE_SQL AS
------------------------------------------------------------------------------
   FUNCTION EXIST(O_error_message	IN OUT VARCHAR2,
                  I_dept		IN     NUMBER,
		  O_exist		IN OUT BOOLEAN)
            return BOOLEAN is

      L_program   VARCHAR2(64) := 'DEPT_VALIDATE_SQL.EXIST';
      L_dept      VARCHAR2(1);

-- This function determines if the entered dept exists

      cursor C_DEPT is
         select 'x'
           from deps
          where dept = I_dept
            and rownum = 1;

   BEGIN
      open C_DEPT;
      fetch C_DEPT into L_dept;
      if C_DEPT%NOTFOUND then
        O_exist := FALSE;
      else
	O_exist := TRUE;
      end if;

      close C_DEPT;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
						SQLERRM,
						L_program,
						null);
	 RETURN FALSE;

   END EXIST;
--------------------------------------------------------------------
FUNCTION DEPT_IN_HIER (O_error_message IN OUT VARCHAR2,
                       O_exists        IN OUT BOOLEAN,
                       I_group         IN     deps.group_no%TYPE,
                       I_division      IN     groups.division%TYPE,
                       I_dept          IN     deps.dept%TYPE)
                          RETURN BOOLEAN IS

   L_exists VARCHAR2(1);

   cursor C_DEPT_VALID_HIER is
      select 'x'
        from deps d, groups g
       where d.dept = I_dept
         and d.group_no = nvl(I_group, d.group_no)
         and d.group_no = g.group_no
         and g.division = nvl(I_division, g.division);


BEGIN
   if I_dept is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_dept','NULL','NOT NULL');
      return FALSE;
   elsif I_group is NULL and I_division is NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'I_group and I_division','NULL','NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_DEPT_VALID_HIER',
                    'GROUPS, DEPS',
                    'DEPARTMENT:'||to_char(I_dept)||
                    ', GROUP NO:'||to_char(I_group)||
                    ', DIVISION:'||to_char(I_division));

   open C_DEPT_VALID_HIER;

   SQL_LIB.SET_MARK('FETCH',
                    'C_DEPT_VALID_HIER',
                    'GROUPS, DEPS',
                    'DEPARTMENT:'||to_char(I_dept)||
                    ', GROUP NO:'||to_char(I_group)||
                    ', DIVISION:'||to_char(I_division));

   fetch C_DEPT_VALID_HIER into L_exists;

   if C_DEPT_VALID_HIER%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_DEPT_VALID_HIER',
                    'GROUPS,DEPS',
                    'DEPARTMENT:'||to_char(I_dept)||
                    ', GROUP NO:'||to_char(I_group)||
                    ', DIVISION:'||to_char(I_division));

   close C_DEPT_VALID_HIER;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
						SQLERRM,
						'DEPT_VALIDATE_SQL.DEPT_IN_HIER',
						to_char(SQLCODE));
	 RETURN FALSE;

END DEPT_IN_HIER;
---------------------------------------------------------------------


END DEPT_VALIDATE_SQL;
/

