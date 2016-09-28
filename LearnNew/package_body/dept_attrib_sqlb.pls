CREATE OR REPLACE PACKAGE BODY DEPT_ATTRIB_SQL AS


-------------------------------------------------------------------------
FUNCTION GET_ACCTNG_METHODS (	O_error_message IN OUT	VARCHAR2,
				I_dept		IN	NUMBER,
				O_profit_type	IN OUT	NUMBER,
				O_markup_type	IN OUT	VARCHAR2)
			return BOOLEAN IS

   L_program	VARCHAR2(64)	:= 'DEPT_ATTRIB_SQL.GET_ACCTNG_METHODS';

   CURSOR c_acct_method IS
	SELECT markup_calc_type, profit_calc_type
	FROM deps
	WHERE dept = I_dept;

BEGIN
   OPEN c_acct_method;
   FETCH c_acct_method INTO O_markup_type, O_profit_type;
   if c_acct_method%NOTFOUND then
	CLOSE c_acct_method;
	O_error_message := SQL_LIB.CREATE_MSG('INV_DEPT',null,null,null);
	return FALSE;
   else
	CLOSE c_acct_method;
	return TRUE;
   end if;

EXCEPTION
   when OTHERS then
	O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
						SQLERRM,
						L_program,
						null);
	return FALSE;

END GET_ACCTNG_METHODS;
----------------------------------------------------------------------
   FUNCTION GET_NAME( O_error_message  IN OUT VARCHAR2,
                      I_dept           IN     NUMBER,
                      O_dept_desc      IN OUT VARCHAR2)
   RETURN BOOLEAN IS

      L_program	VARCHAR2(64)	:= 'DEPT_ATTRIB_SQL.GET_NAME';

      cursor C_DEPT IS
             select dept_name
             from   deps
             where  dept = I_dept;
   BEGIN
      open C_DEPT;
      fetch C_DEPT into O_dept_desc;
      if C_DEPT%NOTFOUND then
         close C_DEPT;
         O_error_message := sql_lib.create_msg('INV_DEPT',
						null,null,null);
         RETURN FALSE;
      else
         close C_DEPT;
         if LANGUAGE_SQL.TRANSLATE(O_dept_desc,
				   O_dept_desc,
				   O_error_message) = FALSE then
            return FALSE;
         end if;

        RETURN TRUE;
      end if;
   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
						SQLERRM,
						L_program,
						null);
         RETURN FALSE;
   END GET_NAME;
-----------------------------------------------------------------
FUNCTION GET_DEPT_HIER (O_error_message IN OUT VARCHAR2,
                        O_group         IN OUT deps.group_no%TYPE,
                        O_division      IN OUT groups.division%TYPE,
                        I_dept          IN     deps.dept%TYPE)
                        RETURN BOOLEAN IS

   cursor C_GET_DEPT_HIER is
      select d.group_no,
             g.division
        from deps d,
             groups g
       where dept = I_dept
         and d.group_no = g.group_no;

BEGIN

   if I_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_DEPT', 'NULL', 'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_DEPT_HIER',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));

   open C_GET_DEPT_HIER;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_DEPT_HIER',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));


   fetch C_GET_DEPT_HIER into O_group, O_division;

   if C_GET_DEPT_HIER%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_DEPT_HIER',
                       'DEPS',
                       'DEPARTMENT:'||to_char(I_dept));
      close C_GET_DEPT_HIER;
      O_error_message:= sql_lib.create_msg('INV_DEPT', NULL,NULL,NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_DEPT_HIER',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));

   close C_GET_DEPT_HIER;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
						SQLERRM,
						'DEPT_ATTRIB_SQL.GET_DEPT_HIER',
						to_char(SQLCODE));
      return FALSE;
END GET_DEPT_HIER;
--------------------------------------------------------------------
FUNCTION GET_PURCHASE_TYPE (O_error_message IN OUT VARCHAR2,
                            O_purchase_type IN OUT DEPS.PURCHASE_TYPE%TYPE,
                            I_dept          IN     DEPS.DEPT%TYPE)
RETURN BOOLEAN IS

 cursor C_PURCHASE_TYPE is
      select purchase_type
        from deps
       where dept = I_dept;

BEGIN
   if I_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_DEPT',
                                             'NULL',
                                             'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_PURCHASE_TYPE',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));

   open C_PURCHASE_TYPE;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_PURCHASE_TYPE',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));


   fetch C_PURCHASE_TYPE into O_purchase_type;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_PURCHASE_TYPE',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));
   ---
   if C_PURCHASE_TYPE%NOTFOUND then
	close C_PURCHASE_TYPE;
	O_error_message := SQL_LIB.CREATE_MSG('INV_DEPT',null,null,null);
	return FALSE;
   else
	close C_PURCHASE_TYPE;
	return TRUE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
						SQLERRM,
						'DEPT_ATTRIB_SQL.GET_PURCHASE_TYPE',
						to_char(SQLCODE));
      return FALSE;
END GET_PURCHASE_TYPE;
--------------------------------------------------------------------
FUNCTION GET_MARKUP( O_error_message	 	IN OUT	VARCHAR2,
                        O_markup_calc_type   	IN OUT	DEPS.MARKUP_CALC_TYPE%TYPE,
                        O_budgeted_intake		IN OUT	DEPS.BUD_INT%TYPE,
                        O_budgeted_markup		IN OUT	DEPS.BUD_MKUP%TYPE,
                        I_dept			IN		DEPS.DEPT%TYPE)
RETURN BOOLEAN IS
cursor C_GET_MARKUP is
      select markup_calc_type,
             bud_int,
             bud_mkup
        from deps
       where dept = I_dept;
BEGIN
   if I_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_DEPT',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_MARKUP',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));

   open C_GET_MARKUP;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_MARKUP',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));


   fetch C_GET_MARKUP into O_markup_calc_type,
                           O_budgeted_intake,
                           O_budgeted_markup;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_MARKUP',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));
   ---
   if C_GET_MARKUP%NOTFOUND then
	close C_GET_MARKUP;
	O_error_message := SQL_LIB.CREATE_MSG('INV_DEPT',null,null,null);
	return FALSE;
   else
	close C_GET_MARKUP;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
					              SQLERRM,
					              'DEPT_ATTRIB_SQL.GET_MARKUP',
					              to_char(SQLCODE));
      return FALSE;
END GET_MARKUP;
--------------------------------------------------------------------
FUNCTION GET_BUYER(O_error_message   IN OUT   VARCHAR2,
                   O_buyer           IN OUT   DEPS.BUYER%TYPE,
                   O_buyer_name      IN OUT   BUYER.BUYER_NAME%TYPE,
                   I_dept            IN       DEPS.DEPT%TYPE)
   return BOOLEAN is

   cursor C_GET_BUYER is
      select buyer
        from deps
       where dept = I_dept;

BEGIN
   if I_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_DEPT',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_BUYER',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));
   open C_GET_BUYER;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_BUYER',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));
   fetch C_GET_BUYER into O_buyer;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_BUYER',
                    'DEPS',
                    'DEPARTMENT:'||to_char(I_dept));
   if C_GET_BUYER%NOTFOUND then
	close C_GET_BUYER;
	O_error_message := SQL_LIB.CREATE_MSG('INV_DEPT',null,null,null);
	return FALSE;
   else
	close C_GET_BUYER;
   end if;

   if O_buyer is NOT NULL then
      if BUYER_ATTRIB_SQL.GET_NAME(O_buyer,
                                   O_buyer_name,
                                   O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEPT_ATTRIB_SQL.GET_BUYER',
                                            to_char(SQLCODE));
      return FALSE;
END GET_BUYER;
-----------------------------------------------------------------
FUNCTION GET_DEPT_VAT_IND (O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_dept_vat_incl_ind  IN OUT DEPS.DEPT_VAT_INCL_IND%TYPE,
                           I_dept               IN     DEPS.DEPT%TYPE)
RETURN BOOLEAN is

   L_program	VARCHAR2(64)	:= 'DEPT_ATTRIB_SQL.GET_DEPT_VAT_IND';

   cursor C_VAT_IND is
    select dept_vat_incl_ind
      from deps
     where dept = I_dept;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_VAT_IND', 'DEPS', I_dept);
   open C_VAT_IND;
   SQL_LIB.SET_MARK('FETCH', 'C_VAT_IND', 'DEPS', I_dept);
   fetch C_VAT_IND into O_dept_vat_incl_ind;
   SQL_LIB.SET_MARK('CLOSE', 'C_VAT_IND', 'DEPS', I_dept);
   close C_VAT_IND;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      RETURN FALSE;
END GET_DEPT_VAT_IND;
--------------------------------------------------------------------
END DEPT_ATTRIB_SQL;
/

