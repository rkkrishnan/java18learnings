CREATE OR REPLACE PACKAGE BODY CLASS_ATTRIB_SQL AS
----------------------------------------------------------------
   FUNCTION GET_NAME (O_error_message   IN OUT VARCHAR2,
                      I_dept        IN     NUMBER,
                      I_class           IN     NUMBER,
                      O_class_name      IN OUT VARCHAR2)
   RETURN BOOLEAN IS

      L_program   VARCHAR2(64)   := 'CLASS_ATTRIB_SQL.GET_NAME';

      cursor C_CLASS IS
             select class_name
               from class
              where class = I_class
                and dept  = I_dept;

   BEGIN
      open C_CLASS;
      fetch C_CLASS into O_class_name;
      if C_CLASS%NOTFOUND then
         close C_CLASS;
         O_error_message := sql_lib.create_msg('INV_CLASS',
                                               NULL,
                                               NULL,
                                               NULL);
         RETURN FALSE;
      else
         close C_CLASS;
            if LANGUAGE_SQL.TRANSLATE( O_class_name,
                                       O_class_name,
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
                                               NULL);
         RETURN FALSE;
   END GET_NAME;
-----------------------------------------------------------------
FUNCTION GET_CLASS_VAT_IND (O_error_message  IN OUT VARCHAR2,
                            O_class_vat_ind  IN OUT CLASS.CLASS_VAT_IND%TYPE,
                            I_dept           IN     DEPS.DEPT%TYPE,
                            I_class          IN     CLASS.CLASS%TYPE)
RETURN BOOLEAN is

   L_program   VARCHAR2(64)   := 'CLASS_ATTRIB_SQL.GET_CLASS_VAT_IND';

   cursor C_VAT_IND is
    select class_vat_ind
      from class
     where class = I_class
       and dept  = I_dept;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_VAT_IND', 'CLASS', I_class);
   open C_VAT_IND;
   SQL_LIB.SET_MARK('FETCH', 'C_VAT_IND', 'CLASS', I_class);
   fetch C_VAT_IND into O_class_vat_ind;
   SQL_LIB.SET_MARK('CLOSE', 'C_VAT_IND', 'CLASS', I_class);
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
END GET_CLASS_VAT_IND;
--------------------------------------------------------------------
FUNCTION ITEMS_EXIST_IN_CLASS (O_error_message  IN OUT VARCHAR2,
                               O_exist          IN OUT BOOLEAN,
                               I_dept           IN     DEPS.DEPT%TYPE,
                               I_class          IN     CLASS.CLASS%TYPE)
   RETURN BOOLEAN is

      L_exist     VARCHAR2(1)       := 'N';
      L_program   VARCHAR2(64)   := 'CLASS_ATTRIB_SQL.ITEMS_EXIST_IN_CLASS';

      cursor C_ITEMS is
       select 'Y'
         from item_master
        where class = I_class
          and dept  = I_dept;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_ITEMS','ITEM_MASTER',I_class);
   open C_ITEMS;
   SQL_LIB.SET_MARK('FETCH','C_ITEMS','ITEM_MASTER',I_class);
   fetch C_ITEMS into L_exist;
   SQL_LIB.SET_MARK('CLOSE','C_ITEMS','ITEM_MASTER',I_class);
   close C_ITEMS;
   ---
   if L_exist = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
         RETURN FALSE;
   END ITEMS_EXIST_IN_CLASS;
-----------------------------------------------------------------
FUNCTION GET_CLASS_VAT_IND (O_error_message  IN OUT VARCHAR2,
                            O_class_vat_ind  IN OUT CLASS.CLASS_VAT_IND%TYPE,
                            I_item           IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN is

   L_program   VARCHAR2(64)   := 'CLASS_ATTRIB_SQL.GET_CLASS_VAT_IND';

   cursor C_VAT_IND is
    select class_vat_ind
      from class c,
           item_master im
     where im.class = c.class
       and im.dept  = c.dept
       and im.item  = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_VAT_IND', 'ITEM', I_item);
   open C_VAT_IND;
   SQL_LIB.SET_MARK('FETCH', 'C_VAT_IND', 'ITEM', I_item);
   fetch C_VAT_IND into O_class_vat_ind;
   SQL_LIB.SET_MARK('CLOSE', 'C_VAT_IND', 'ITEM', I_item);
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
END GET_CLASS_VAT_IND;
--------------------------------------------------------------------
END CLASS_ATTRIB_SQL;
/

