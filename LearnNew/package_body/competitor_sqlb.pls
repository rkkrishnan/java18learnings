CREATE OR REPLACE PACKAGE BODY COMPETITOR_SQL AS

------------------------------------------------------------------------------

FUNCTION COMPETITOR_EXIST(O_error_message  IN OUT  VARCHAR2,
                          O_exist          IN OUT  BOOLEAN,
                          I_competitor     IN      competitor.competitor%TYPE)
RETURN BOOLEAN IS

   L_dummy VARCHAR2(1) := NULL;

   cursor C_COMP_EXIST is
      select 'x'
        from competitor
       where competitor = I_competitor;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_COMP_EXIST','COMPETITOR', 'COMPETITOR: '|| I_competitor);
   open C_COMP_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_COMP_EXIST','COMPETITOR', 'COMPETITOR: '|| I_competitor);
   fetch C_COMP_EXIST into L_dummy;
   SQL_LIB.SET_MARK('CLOSE','C_COMP_EXIST','COMPETITOR', 'COMPETITOR: '|| I_competitor);
   close C_COMP_EXIST;

   if L_dummy = 'x' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.COMPETITOR_EXIST',
                                             to_char(SQLCODE));

   return FALSE;
END COMPETITOR_EXIST;

------------------------------------------------------------------------------

FUNCTION COMP_STORE_EXIST(O_error_message  IN OUT  VARCHAR2,
                          O_exist          IN OUT  BOOLEAN,
                          I_comp_store     IN      comp_store.store%TYPE)
RETURN BOOLEAN IS

   L_dummy VARCHAR2(1) := NULL;

   cursor C_STORE_EXIST is
      select 'x'
        from comp_store
       where store = I_comp_store;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_STORE_EXIST','COMP_STORE', 'STORE: '|| I_comp_store);
   open C_STORE_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_STORE_EXIST','COMP_STORE', 'STORE: '|| I_comp_store);
   fetch C_STORE_EXIST into L_dummy;
   SQL_LIB.SET_MARK('CLOSE','C_STORE_EXIST','COMP_STORE', 'STORE: '|| I_comp_store);
   close C_STORE_EXIST;

   if L_dummy = 'x' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.COMP_STORE_EXIST',
                                             to_char(SQLCODE));

   return FALSE;
END COMP_STORE_EXIST;

------------------------------------------------------------------------------

FUNCTION COMP_SHOPPER_EXIST(O_error_message  IN OUT  VARCHAR2,
                            O_exist          IN OUT  BOOLEAN,
                            I_comp_shopper   IN      comp_shopper.shopper%TYPE)
RETURN BOOLEAN IS

   L_dummy VARCHAR2(1) := NULL;

   cursor C_SHOPPER_EXIST is
      select 'x'
        from comp_shopper
       where shopper = I_comp_shopper;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_SHOPPER_EXIST','COMP_SHOPPER', 'SHOPPER: '|| I_comp_shopper);
   open C_SHOPPER_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_SHOPPER_EXIST','COMP_SHOPPER', 'SHOPPER: '|| I_comp_shopper);
   fetch C_SHOPPER_EXIST into L_dummy;
   SQL_LIB.SET_MARK('CLOSE','C_SHOPPER_EXIST','COMP_SHOPPER', 'SHOPPER: '|| I_comp_shopper);
   close C_SHOPPER_EXIST;

   if L_dummy = 'x' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.COMP_SHOPPER_EXIST',
                                             to_char(SQLCODE));

   return FALSE;
END COMP_SHOPPER_EXIST;

------------------------------------------------------------------------------

FUNCTION GET_NAME(O_error_message IN OUT VARCHAR2,
                  O_comp_name     IN OUT competitor.comp_name%TYPE,
                  I_competitor    IN     competitor.competitor%TYPE)
RETURN BOOLEAN IS

cursor C_COMP_NAME is
   select comp_name
     from competitor
    where competitor = I_competitor;

BEGIN

   if I_competitor is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_competitor',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_COMP_NAME','COMPETITOR',
                    'COMPETITOR: '|| I_competitor);
   open C_COMP_NAME;

   SQL_LIB.SET_MARK('FETCH','C_COMP_NAME','COMPETITOR',
                    'COMPETITOR: '|| I_competitor);
   fetch C_COMP_NAME into O_comp_name;

   if C_COMP_NAME%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_COMP_NAME','COMPETITOR',
                    'COMPETITOR: '|| I_competitor);
      close C_COMP_NAME;
      ---
      if LANGUAGE_SQL.TRANSLATE(O_comp_name,
                                O_comp_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   else
      SQL_LIB.SET_MARK('CLOSE','C_COMP_NAME','COMPETITOR',
                    'COMPETITOR: '|| I_competitor);
      close C_COMP_NAME;
      ---
      O_error_message:= sql_lib.create_msg('INV_COMPETITOR',
                                           NULL,NULL,NULL);
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.GET_NAME',
                                             to_char(SQLCODE));
   RETURN FALSE;
END GET_NAME;

----------------------------------------------------------------------------------------

FUNCTION GET_STORE_NAME(O_error_message IN OUT VARCHAR2,
                        O_store_name    IN OUT comp_store.store_name%TYPE,
                        O_competitor    IN OUT competitor.competitor%TYPE,
                        O_comp_name     IN OUT competitor.comp_name%TYPE,
                        O_currency      IN OUT comp_store.currency_code%TYPE,
                        I_comp_store    IN     comp_store.store%TYPE)
RETURN BOOLEAN IS

L_competitor  competitor.competitor%TYPE := O_competitor;
L_comp_name   competitor.comp_name%TYPE  := O_comp_name;

cursor C_STORE_NAME is
   select cs.store_name,
          cs.competitor,
          c.comp_name,
          cs.currency_code
     from comp_store cs, competitor c
    where cs.store = I_comp_store
      and c.competitor = cs.competitor;

BEGIN

   if I_comp_store is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_comp_store',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_STORE_NAME','COMP_STORE',
                    'COMP_STORE: '|| I_comp_store);
   open C_STORE_NAME;

   SQL_LIB.SET_MARK('FETCH','C_STORE_NAME','COMP_STORE',
                    'COMP_STORE: '|| I_comp_store);
   fetch C_STORE_NAME into O_store_name, O_competitor, O_comp_name, O_currency;

   if C_STORE_NAME%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_STORE_NAME','COMP_STORE',
                    'COMP_STORE: '|| I_comp_store);
      close C_STORE_NAME;

      if L_competitor is not NULL then
         if L_competitor != O_competitor then
            O_competitor := L_competitor;
            O_comp_name  := L_comp_name;

            --- Invalid competitor/competitor store combination ---
            O_error_message:= sql_lib.create_msg('INVALID_COMP_LINK',
                                                 NULL,
                                                 NULL,
                                                 NULL);
            return FALSE;
         end if;
      end if;

      if LANGUAGE_SQL.TRANSLATE(O_store_name,
                                O_store_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;

      if LANGUAGE_SQL.TRANSLATE(O_comp_name,
                                O_comp_name,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   else
      SQL_LIB.SET_MARK('CLOSE','C_STORE_NAME','COMP_STORE',
                    'COMP_STORE: '|| I_comp_store);
      close C_STORE_NAME;
      ---
      O_error_message:= sql_lib.create_msg('INV_COMP_STORE',
                                           NULL,NULL,NULL);
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.GET_STORE_NAME',
                                             to_char(SQLCODE));
   RETURN FALSE;
END GET_STORE_NAME;

----------------------------------------------------------------------------------------

FUNCTION GET_SHOPPER_NAME(O_error_message IN OUT VARCHAR2,
                          O_shop_name     IN OUT comp_shopper.shopper_name%TYPE,
                          I_shopper       IN     comp_shopper.shopper%TYPE)
RETURN BOOLEAN IS

cursor C_SHOP_NAME is
   select shopper_name
     from comp_shopper
    where shopper = I_shopper;

BEGIN

   if I_shopper is NULL then
     O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                          'I_shopper',
                                          'NULL',
                                          'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_SHOP_NAME','COMPETITOR',
                    'COMP_SHOPPER: '|| I_shopper);
   open C_SHOP_NAME;

   SQL_LIB.SET_MARK('FETCH','C_SHOP_NAME','COMPETITOR',
                    'COMP_SHOPPER: '|| I_shopper);
   fetch C_SHOP_NAME into O_shop_name;

   if C_SHOP_NAME%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_SHOP_NAME','COMPETITOR',
                    'COMP_SHOPPER: '|| I_shopper);
      close C_SHOP_NAME;
   else
      SQL_LIB.SET_MARK('CLOSE','C_SHOP_NAME','COMPETITOR',
                    'COMP_SHOPPER: '|| I_shopper);
      close C_SHOP_NAME;
      ---
      O_error_message:= sql_lib.create_msg('INV_SHOPPER',
                                           NULL,NULL,NULL);
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.GET_SHOPPER_NAME',
                                             to_char(SQLCODE));
   RETURN FALSE;
END GET_SHOPPER_NAME;

----------------------------------------------------------------------------------------

FUNCTION NEXT_COMP_NUMBER( O_error_message IN OUT VARCHAR2,
                           O_comp_number   IN OUT NUMBER)
RETURN BOOLEAN IS

   L_wrap_sequence_number   competitor.competitor%TYPE;
   L_first_time             VARCHAR2(3)       := 'Yes';
   L_dummy                  VARCHAR2(1);

   CURSOR c_comp_sequence IS
      SELECT comp_sequence.NEXTVAL seq_no
        FROM dual;

   CURSOR c_comp_exists IS
      SELECT 'x'
        FROM competitor
       WHERE competitor = O_comp_number;

BEGIN

    FOR rec IN c_comp_sequence LOOP

        O_comp_number := rec.seq_no;

        if (L_first_time = 'Yes') THEN
            L_wrap_sequence_number := O_comp_number;
            L_first_time := 'No';
        elsif (O_comp_number = L_wrap_sequence_number) THEN
            O_error_message:= sql_lib.create_msg('NO_COMP_NUMBERS',
                                                 NULL,NULL,NULL);
            return FALSE;
        end if;

        SQL_LIB.SET_MARK('OPEN', 'C_COMP_EXISTS', 'COMPETITOR',
                         'COMPETITOR: '|| to_char(O_comp_number));
        open c_comp_exists;

        SQL_LIB.SET_MARK('FETCH', 'C_COMP_EXISTS', 'COMPETITOR',
                         'COMPETITOR: '|| to_char(O_comp_number));
        fetch c_comp_exists into L_dummy;

        if (c_comp_exists%notfound) THEN
            SQL_LIB.SET_MARK('CLOSE', 'C_COMP_EXISTS', 'COMPETITOR',
                             'COMPETITOR: '|| to_char(O_comp_number));
            close c_comp_exists;
            return TRUE;
        end if;

        SQL_LIB.SET_MARK('CLOSE', 'C_COMP_EXISTS', 'COMPETITOR',
                         'COMPETITOR: '|| to_char(O_comp_number));
        close c_comp_exists;

    END LOOP;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.NEXT_COMP_NUMBER',
                                             to_char(SQLCODE));
   return FALSE;
END NEXT_COMP_NUMBER;

---------------------------------------------------------------------------------

FUNCTION NEXT_COMP_ST_NUMBER(O_error_message IN OUT VARCHAR2,
                             O_store_number   IN OUT NUMBER)
RETURN BOOLEAN IS

   L_wrap_sequence_number   COMP_STORE.STORE%TYPE;
   L_first_time             VARCHAR2(3) := 'Yes';
   L_dummy                  VARCHAR2(1);

   CURSOR c_comp_st_sequence IS
      SELECT comp_st_sequence.NEXTVAL seq_no
        FROM dual;

   CURSOR c_comp_st_exists IS
      SELECT 'x'
        FROM comp_store
       WHERE comp_store.store = O_store_number;

BEGIN

    FOR rec IN c_comp_st_sequence LOOP

        O_store_number := rec.seq_no;

        if (L_first_time = 'Yes') THEN
            L_wrap_sequence_number := O_store_number;
            L_first_time := 'No';
        elsif (O_store_number = L_wrap_sequence_number) THEN
            O_error_message:= sql_lib.create_msg('NO_COMP_ST_NUMBERS',
                                                 NULL,NULL,NULL);
            return FALSE;
        end if;

        SQL_LIB.SET_MARK('OPEN', 'C_COMP_ST_EXISTS', 'COMP_STORE',
                         'COMP_STORE: '|| to_char(O_store_number));
        open c_comp_st_exists;

        SQL_LIB.SET_MARK('FETCH', 'C_COMP_ST_EXISTS', 'COMP_STORE',
                         'COMP_STORE: '|| to_char(O_store_number));
        fetch c_comp_st_exists into L_dummy;

        if (c_comp_st_exists%notfound) THEN
            SQL_LIB.SET_MARK('CLOSE', 'C_COMP_ST_EXISTS', 'COMP_STORE',
                             'COMP_STORE: '|| to_char(O_store_number));
            close c_comp_st_exists;
            return TRUE;
        end if;

        SQL_LIB.SET_MARK('CLOSE', 'C_COMP_ST_EXISTS', 'COMP_STORE',
                         'COMP_STORE: '|| to_char(O_store_number));
        close c_comp_st_exists;

    END LOOP;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.NEXT_COMP_ST_NUMBER',
                                             to_char(SQLCODE));
   return FALSE;
END NEXT_COMP_ST_NUMBER;

---------------------------------------------------------------------------------

FUNCTION NEXT_SHOPPER_NUMBER(O_error_message    IN OUT VARCHAR2,
                             O_shopper_number   IN OUT NUMBER)
RETURN BOOLEAN IS

   L_wrap_sequence_number   COMP_SHOPPER.SHOPPER%TYPE;
   L_first_time             VARCHAR2(3) := 'Yes';
   L_dummy                  VARCHAR2(1);

   CURSOR c_shop_sequence IS
      SELECT comp_shop_sequence.NEXTVAL seq_no
        FROM dual;

   CURSOR c_shopper_exists IS
      SELECT 'x'
        FROM comp_shopper
       WHERE comp_shopper.shopper = O_shopper_number;

BEGIN

    FOR rec IN c_shop_sequence LOOP

        O_shopper_number := rec.seq_no;

        if (L_first_time = 'Yes') THEN
            L_wrap_sequence_number := O_shopper_number;
            L_first_time := 'No';
        elsif (O_shopper_number = L_wrap_sequence_number) THEN
            O_error_message:= sql_lib.create_msg('NO_SHOPPER_NUMBERS',
                                                 NULL,NULL,NULL);
            return FALSE;
        end if;

        SQL_LIB.SET_MARK('OPEN', 'C_SHOPPER_EXISTS', 'COMP_SHOPPER',
                         'SHOPPER: '|| to_char(O_shopper_number));
        open c_shopper_exists;

        SQL_LIB.SET_MARK('FETCH', 'C_SHOPPER_EXISTS', 'COMP_SHOPPER',
                         'SHOPPER: '|| to_char(O_shopper_number));
        fetch c_shopper_exists into L_dummy;

        if (c_shopper_exists%notfound) THEN
            SQL_LIB.SET_MARK('CLOSE', 'C_SHOPPER_EXISTS', 'COMP_SHOPPER',
                             'SHOPPER: '|| to_char(O_shopper_number));
            close c_shopper_exists;
            return TRUE;
        end if;

        SQL_LIB.SET_MARK('CLOSE', 'C_SHOPPER_EXISTS', 'COMP_SHOPPER',
                         'SHOPPER: '|| to_char(O_shopper_number));
        close c_shopper_exists;

    END LOOP;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.NEXT_SHOPPER_NUMBER',
                                             to_char(SQLCODE));
   return FALSE;
END NEXT_SHOPPER_NUMBER;

---------------------------------------------------------------------------------

FUNCTION CHECK_COMP_DELETE (O_error_message IN OUT  VARCHAR2,
                            O_exists        IN OUT  BOOLEAN,
                            I_competitor     IN   competitor.competitor%TYPE)
   return BOOLEAN is

   L_program   VARCHAR2(64)   :='COMPETITOR_SQL.CHECK_COMP_DELETE';
   L_exists      VARCHAR2(1)       := NULL;


   cursor C_CHECK_LIST is
      select 'Y'
        from comp_shop_list
       where competitor = I_competitor;

   cursor C_CHECK_STORE is
      select 'Y'
        from comp_store
       where competitor = I_competitor;


BEGIN
   if I_competitor is not NULL then

      --Check for records on shopping list table--

      O_exists := FALSE;
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'competitor'||I_competitor);
      open C_CHECK_LIST;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'competitor'||I_competitor);
      fetch C_CHECK_LIST into L_exists;
      if C_CHECK_LIST%FOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'competitor'||I_competitor);
         close C_CHECK_LIST;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_COMP_LIST', NULL, NULL, NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'competitor'||I_competitor);
      close C_CHECK_LIST;

      -- Check for records on the comp_store table --

      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_STORE', 'COMP_STORE',
             'competitor'||I_competitor);
      open C_CHECK_STORE;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_STORE', 'COMP_STORE',
             'competitor'||I_competitor);
      fetch C_CHECK_STORE into L_exists;
      if C_CHECK_STORE%FOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_STORE', 'COMP_STORE',
             'competitor'||I_competitor);
         close C_CHECK_STORE;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_COMP_STORE', NULL, NULL, NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_STORE', 'COMP_STORE',
             'competitor'||I_competitor);
      close C_CHECK_STORE;
   end if;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_COMP_DELETE;

-------------------------------------------------------------------------------------------

FUNCTION CHECK_COMP_ST_DELETE (O_error_message IN OUT  VARCHAR2,
                               O_exists        IN OUT  BOOLEAN,
                               I_comp_store    IN      competitor.competitor%TYPE)
   return BOOLEAN is

   L_program   VARCHAR2(64)   := 'COMPETITOR_SQL.CHECK_COMP_ST_DELETE';
   L_exists    VARCHAR2(1)    := NULL;

   cursor C_CHECK_LIST is
      select 'Y'
        from comp_shop_list
       where comp_store = I_comp_store;

   cursor C_CHECK_LINK is
      select 'Y'
        from comp_store_link
       where comp_store = I_comp_store;

   cursor C_CHECK_HIST is
      select 'Y'
        from comp_price_hist
       where comp_store = I_comp_store;

BEGIN

   if I_comp_store is not NULL then

      --Check for records on shopping list table--
      O_exists := FALSE;
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'competitor'||I_comp_store);
      open C_CHECK_LIST;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'competitor'||I_comp_store);
      fetch C_CHECK_LIST into L_exists;
      if C_CHECK_LIST%FOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'competitor'||I_comp_store);
         close C_CHECK_LIST;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_COMP_ST_LIST', NULL, NULL, NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'competitor'||I_comp_store);
      close C_CHECK_LIST;

      -- CHECK FOR RECORDS ON COMP_SHOP_LINK TABLE --

      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_LINK', 'COMP_STORE',
             'comp_store'||I_comp_store);
      open C_CHECK_LINK;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_LINK', 'COMP_STORE',
             'comp_store'||I_comp_store);

      fetch C_CHECK_LINK into L_exists;
      if C_CHECK_LINK%FOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_LINK', 'COMP_STORE',
             'comp_store'||I_comp_store);

         close C_CHECK_LINK;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_COMP_ST_LINK', NULL, NULL, NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_LINK', 'COMP_STORE',
             'comp_store'||I_comp_store);
      close C_CHECK_LINK;

      -- CHECK FOR RECORDS ON COMP_PRICE_HIST TABLE --

      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_HIST', 'COMP_STORE',
             'comp_store'||I_comp_store);
      open C_CHECK_HIST;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_HIST', 'COMP_STORE',
             'comp_store'||I_comp_store);

      fetch C_CHECK_HIST into L_exists;
      if C_CHECK_HIST%FOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_HIST', 'COMP_STORE',
             'comp_store'||I_comp_store);

         close C_CHECK_HIST;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_COMP_ST_HIST', NULL, NULL, NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_HIST', 'COMP_STORE',
             'comp_store'||I_comp_store);
      close C_CHECK_HIST;
   end if;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_COMP_ST_DELETE;

------------------------------------------------------------------------------------------

FUNCTION CHECK_COMP_SHOPPER_DELETE(O_error_message IN OUT  VARCHAR2,
                                   O_exists        IN OUT  BOOLEAN,
                                   I_shopper       IN       comp_shopper.shopper%TYPE)
   return BOOLEAN is

   L_program   VARCHAR2(64)   :='COMPETITOR_SQL.CHECK_COMP_SHOPPER_DELETE';
   L_exists    VARCHAR2(1)    := NULL;

   cursor C_CHECK_LIST is
      select 'Y'
        from comp_shop_list
       where shopper = I_shopper;

BEGIN

   if I_shopper is not NULL then

      --Check for records on shopping list table--
      O_exists := FALSE;
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'shopper'||I_shopper);
      open C_CHECK_LIST;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'shopper'||I_shopper);
      fetch C_CHECK_LIST into L_exists;
      if C_CHECK_LIST%FOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'shopper'||I_shopper);
         close C_CHECK_LIST;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_DEL_COMP_SHOPPER', NULL, NULL, NULL);
         O_exists := TRUE;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_LIST', 'COMP_SHOP_LIST',
             'shopper'||I_shopper);
      close C_CHECK_LIST;

   end if;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_COMP_SHOPPER_DELETE;

--------------------------------------------------------------------------------------------

FUNCTION CREATE_SHOP_LIST(O_error_message   IN OUT  VARCHAR2,
                          I_itemlist        IN      skulist_head.skulist%TYPE) return BOOLEAN is
BEGIN

   /* if the itemlist is null, don't bother */
   if I_itemlist is NULL then
     O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                          'I_itemlist',
                                          'NULL',
                                          'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('INSERT',NULL,'COMP_SHOP_LIST',
                    'ITEMLIST: '|| I_itemlist);

   insert into comp_shop_list (shopper,
                               shop_date,
                               item,
                               item_desc,
                               ref_item,
                               competitor,
                               comp_name,
                               comp_store,
                               comp_store_name,
                               rec_date,
                               comp_retail,
                               comp_retail_type,
                               prom_start_date,
                               prom_end_date,
                               offer_type,
                               multi_units,
                               multi_unit_retail)
                        select distinct cl.shopper,
                               cl.shop_date,
                               im.item,
                               im.item_desc,
                               im.item,
                               cl.competitor,
                               c.comp_name,
                               cl.comp_store,
                               cs.store_name,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL
                          from comp_list_temp cl,
                               competitor c,
                               comp_store cs,
                               skulist_detail sd,
                               item_master im
                         where cl.competitor          = c.competitor
                           and cl.comp_store          = cs.store
                           and cl.item_list           = I_itemlist
                           and cl.item_list           = sd.skulist
                           and im.tran_level          = im.item_level
                           and im.sellable_ind        = 'Y'
                           and im.item_number_type not in ('ITEM', 'PLU', 'VPLU')
                           and (sd.item               = im.item
                             or sd.item               = im.item_parent
                             or sd.item               = im.item_grandparent)
                           and not exists (
                               select 1
                                 from comp_shop_list csl
                                where csl.competitor     = cl.competitor
                                  and csl.shopper        = cl.shopper
                                  and csl.comp_store     = cl.comp_store
                                  and csl.shop_date      = cl.shop_date
                                  and csl.item           = im.item
                                  and (csl.ref_item       is null or
                                       csl.ref_item       = im.item));

   SQL_LIB.SET_MARK('INSERT',NULL,'COMP_SHOP_LIST',
                    'ITEMLIST: '|| I_itemlist);
   insert into comp_shop_list (shopper,
                               shop_date,
                               item,
                               item_desc,
                               ref_item,
                               competitor,
                               comp_name,
                               comp_store,
                               comp_store_name,
                               rec_date,
                               comp_retail,
                               comp_retail_type,
                               prom_start_date,
                               prom_end_date,
                               offer_type,
                               multi_units,
                               multi_unit_retail)
                        select distinct cl.shopper,
                               cl.shop_date,
                               im.item,
                               NVL(im2.item_desc, im.item_desc),
                               im2.item,
                               cl.competitor,
                               c.comp_name,
                               cl.comp_store,
                               cs.store_name,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL
                          from comp_list_temp cl,
                               competitor c,
                               comp_store cs,
                               skulist_detail sd,
                               item_master im,
                               item_master im2
                         where cl.competitor          = c.competitor
                           and cl.comp_store          = cs.store
                           and cl.item_list           = I_itemlist
                           and cl.item_list           = sd.skulist
                           and im.tran_level          = im.item_level
                           and im.sellable_ind        = 'Y'
                           and im.item_number_type in ('ITEM', 'PLU', 'VPLU')
                           and (sd.item               = im.item
                             or sd.item               = im.item_parent
                             or sd.item               = im.item_grandparent)
                           and im2.item_parent(+)     = im.item
                           and not exists (
                               select 1
                                 from comp_shop_list csl
                                where csl.competitor     = cl.competitor
                                  and csl.shopper        = cl.shopper
                                  and csl.comp_store     = cl.comp_store
                                  and csl.shop_date      = cl.shop_date
                                  and csl.item           = im.item
                                  and (csl.ref_item       is null or
                                       csl.ref_item       = im2.item));
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'COMPETITOR_SQL.CREATE_SHOP_LIST',
                                            to_char(SQLCODE));
      return FALSE;
END CREATE_SHOP_LIST;
------------------------------------------------------------------------------

FUNCTION COMP_STORE_LINK_EXIST(O_error_message  IN OUT  VARCHAR2,
                               O_exist          IN OUT  BOOLEAN,
                               I_comp_store     IN      comp_store_link.comp_store%TYPE,
                               I_store          IN      comp_store_link.store%TYPE)
RETURN BOOLEAN IS

   L_dummy VARCHAR2(1) := NULL;

   cursor C_COMP_STORE_LINK_EXIST is
      select 'x'
        from comp_store_link
       where comp_store = I_comp_store and
                  store = I_store;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_COMP_STORE_LINK_EXIST','COMP_STORE_LINK', 'COMP_STORE: '|| I_comp_store || 'STORE: '|| I_store);
   open C_COMP_STORE_LINK_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_COMP_STORE_LINK_EXIST','COMP_STORE_LINK', 'COMP_STORE: '|| I_comp_store || 'STORE: '|| I_store);
   fetch C_COMP_STORE_LINK_EXIST into L_dummy;
   SQL_LIB.SET_MARK('CLOSE','C_COMP_STORE_LINK_EXIST','COMP_STORE_LINK', 'COMP_STORE: '|| I_comp_store || 'STORE: '|| I_store);
   close C_COMP_STORE_LINK_EXIST;

   if L_dummy = 'x' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             'COMPETITOR_SQL.COMP_STORE_LINK_EXIST',
                                             to_char(SQLCODE));

   return FALSE;
END COMP_STORE_LINK_EXIST;


--------------------------------------------------------------------------------------------

END COMPETITOR_SQL;
/

