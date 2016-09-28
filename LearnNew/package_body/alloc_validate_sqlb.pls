CREATE OR REPLACE PACKAGE BODY ALLOC_VALIDATE_SQL AS

-------------------------------------------------------------------
FUNCTION EXIST(	O_error_message	IN OUT	VARCHAR2,
		I_alloc_no	IN	NUMBER,
		O_exist		IN OUT	BOOLEAN)
	RETURN BOOLEAN IS

   L_dummy	VARCHAR2(1);

   cursor C_EXIST is
	select 'x'
	from alloc_header
	where alloc_no = I_alloc_no;

BEGIN
   open C_EXIST;
   fetch C_EXIST into L_dummy;
   if C_EXIST%NOTFOUND then
	O_error_message := sql_lib.create_msg('INV_ALLOC_NUM',
						null,null,null);
	O_exist := FALSE;
   else
	O_exist := TRUE;
   end if;

   close C_EXIST;
   return TRUE;

EXCEPTION
   when OTHERS then
	O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
						SQLERRM,
						'ALLOC_VALIDATE_SQL.EXIST',
						to_char(SQLCODE));
	return FALSE;
END EXIST;
---------------------------------------------------------------------
END ALLOC_VALIDATE_SQL;
/

