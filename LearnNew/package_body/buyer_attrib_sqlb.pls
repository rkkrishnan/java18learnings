CREATE OR REPLACE PACKAGE BODY BUYER_ATTRIB_SQL AS
-------------------------------------------------------------------------------
FUNCTION GET_NAME(I_BUYER         IN NUMBER,
                  O_BUYER_NAME    IN OUT VARCHAR2,
                  O_error_message IN OUT VARCHAR2) return BOOLEAN IS

   L_program	VARCHAR2(64) := 'BUYER_ATTRIB_SQL.GET_NAME';

   cursor C_BUYER is
      select buyer_name
        from buyer
       where buyer = I_BUYER;
BEGIN
   open C_BUYER;
   fetch C_BUYER into O_BUYER_NAME;
   if C_BUYER%NOTFOUND then
      O_error_message := 'INV_BUYER';
      close C_BUYER;
      Return FALSE;
   end if;
   close C_BUYER;

   if LANGUAGE_SQL.TRANSLATE(O_buyer_name,
                             O_buyer_name,
                             O_error_message) = FALSE then
      return FALSE;
   end if;

   Return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
						SQLERRM,
						L_program,
						to_char(SQLCODE));
      Return FALSE;
END GET_NAME;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
FUNCTION EXIST(   I_BUYER         IN NUMBER,
                  O_EXIST         IN OUT BOOLEAN,
                  O_error_message IN OUT VARCHAR2) return BOOLEAN IS

   L_program	VARCHAR2(64) := 'BUYER_ATTRIB_SQL.EXIST';
   L_dummy	VARCHAR2(1);

   cursor C_BUYER is
      select 'x'
        from buyer
       where buyer = I_BUYER;
BEGIN
   open C_BUYER;
   fetch C_BUYER into L_dummy;
   if C_BUYER%NOTFOUND then
      close C_BUYER;
      O_exist := FALSE;
   else
      close C_BUYER;
      O_exist := TRUE;
   end if;

   Return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
						SQLERRM,
						L_program,
						to_char(SQLCODE));
      Return FALSE;
END EXIST;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
FUNCTION BUYER_DETAILS(O_error_message IN OUT VARCHAR2,
                       O_buyer_name    IN OUT buyer.buyer_name%TYPE,
                       O_buyer_phone   IN OUT buyer.buyer_phone%TYPE,
                       O_buyer_fax     IN OUT buyer.buyer_fax%TYPE,
                       I_buyer         IN     buyer.buyer%TYPE)
                       RETURN BOOLEAN IS

L_function  VARCHAR2(50)  := 'BUYER_ATTRIB_SQL.BUYER_DETAILS';

cursor C_BUYER_DETAILS is
   select buyer_name,
          buyer_phone,
          buyer_fax
     from buyer
    where buyer = I_buyer;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_BUYER_DETAILS','buyer',
                    'buyer: '||TO_CHAR(I_buyer));
   open C_BUYER_DETAILS;

   SQL_LIB.SET_MARK('FETCH','C_BUYER_DETAILS','buyer',
                    'buyer: '||TO_CHAR(I_buyer));
   fetch C_BUYER_DETAILS into O_buyer_name,
                              O_buyer_phone,
                              O_buyer_fax;
   if C_BUYER_DETAILS%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_BUYER',NULL,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE','C_BUYER_DETAILS','buyer',
                       'buyer: '||TO_CHAR(I_buyer));
      close C_BUYER_DETAILS;
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_BUYER_DETAILS','buyer',
                    'buyer: '||TO_CHAR(I_buyer));
   close C_BUYER_DETAILS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END BUYER_DETAILS;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
END BUYER_ATTRIB_SQL;
/

