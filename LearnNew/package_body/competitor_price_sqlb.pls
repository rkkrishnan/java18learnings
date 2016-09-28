CREATE OR REPLACE PACKAGE BODY COMPETITOR_PRICE_SQL AS
------------------------------------------------------------------------------
FUNCTION CHECK_IF_DEFAULT(O_error_message IN OUT  VARCHAR2,
                          O_default       IN OUT  BOOLEAN,
                          I_shopper       IN      COMP_SHOP_LIST.SHOPPER%TYPE,
                          I_comp_store    IN      COMP_SHOP_LIST.COMP_STORE%TYPE,
                          I_shop_date     IN      COMP_SHOP_LIST.REC_DATE%TYPE,
                          I_competitor    IN      COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS
   L_program     VARCHAR2(60) := 'COMPETITOR_PRICE_SQL.CHECK_IF_DEFAULT';
   L_dummy       VARCHAR2(1)  := NULL;

   cursor C_COMP_SHOP_EXIST is
      select 'x'
        from comp_shop_list_temp
       where competitor = I_competitor
         and shop_date  = I_shop_date
         and comp_store = nvl(I_comp_store, comp_store)
         and shopper    = nvl(I_shopper, shopper)
         and comp_retail is NULL;

   cursor C_COMP_HIST_EXIST is
      select 'x'
        from comp_price_hist cph, comp_shop_list_temp csl
       where csl.competitor = I_competitor
         and cph.rec_date   < I_shop_date
         and csl.comp_store = nvl(I_comp_store, csl.comp_store)
         and csl.shopper    = nvl(I_shopper, csl.shopper)
         and cph.comp_store = csl.comp_store
         and cph.item       = csl.item
         and (csl.ref_item   = cph.ref_item
            or (cph.ref_item is NULL and csl.ref_item is NULL));
BEGIN
   if I_competitor is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_competitor',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_shop_date is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_shop_date',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   O_default := FALSE;

   SQL_LIB.SET_MARK('OPEN','C_COMP_SHOP_EXIST','COMP_SHOP_LIST_TEMP', 'COMPETITOR: '|| to_char(I_competitor));
   open C_COMP_SHOP_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_COMP_SHOP_EXIST','COMP_SHOP_LIST_TEMP', 'COMPETITOR: '|| to_char(I_competitor));
   fetch C_COMP_SHOP_EXIST into L_dummy;
   if C_COMP_SHOP_EXIST%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_COMP_SHOP_EXIST','COMP_SHOP_LIST_TEMP', 'COMPETITOR: '|| to_char(I_competitor));
      close C_COMP_SHOP_EXIST;

      SQL_LIB.SET_MARK('OPEN','C_COMP_HIST_EXIST','COMP_PRICE_HIST', 'COMPETITOR: '|| to_char(I_competitor));
      open C_COMP_HIST_EXIST;
      SQL_LIB.SET_MARK('FETCH','C_COMP_HIST_EXIST','COMP_PRICE_HIST', 'COMPETITOR: '|| to_char(I_competitor));
      fetch C_COMP_HIST_EXIST into L_dummy;
      if C_COMP_HIST_EXIST%FOUND then
         SQL_LIB.SET_MARK('CLOSE','C_COMP_HIST_EXIST','COMP_PRICE_HIST', 'COMPETITOR: '|| to_char(I_competitor));
         close C_COMP_HIST_EXIST;
         O_default := TRUE;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_COMP_HIST_EXIST','COMP_PRICE_HIST', 'COMPETITOR: '|| to_char(I_competitor));
      close C_COMP_HIST_EXIST;
   else
      SQL_LIB.SET_MARK('CLOSE','C_COMP_SHOP_EXIST','COMP_SHOP_LIST_TEMP', 'COMPETITOR: '|| to_char(I_competitor));
      close C_COMP_SHOP_EXIST;
   end if;
   O_default := FALSE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

   return FALSE;
END CHECK_IF_DEFAULT;
------------------------------------------------------------------------------
FUNCTION COMP_STORE_VALIDATION(O_error_message IN OUT VARCHAR2,
                               O_store_name    IN OUT COMP_STORE.STORE_NAME%TYPE,
                               O_currency      IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
                               I_comp_store    IN     COMP_SHOP_LIST.COMP_STORE%TYPE,
                               I_shopper       IN     COMP_SHOP_LIST.SHOPPER%TYPE,
                               I_item          IN     COMP_SHOP_LIST.ITEM%TYPE,
                               I_shop_date     IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                               I_competitor    IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(60)  := 'COMPETITOR_PRICE_SQL.COMP_STORE_VALIDATION';
   L_dummy         VARCHAR2(1)   := NULL;
   L_competitor    COMPETITOR.COMPETITOR%TYPE;
   L_comp_name     COMPETITOR.COMP_NAME%TYPE;

   cursor C_COMP_STORE_EXIST is
      select 'x'
        from comp_shop_list_temp
       where comp_store = I_comp_store
         and competitor = I_competitor
         and shop_date  = I_shop_date
         and shopper    = nvl(I_shopper, shopper)
         and item       = nvl(I_item, item);

BEGIN
   if I_competitor is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_competitor',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_shop_date is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_shop_date',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_comp_store is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_comp_store',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;


   SQL_LIB.SET_MARK('OPEN','C_COMP_STORE_EXIST','COMP_SHOP_LIST_TEMP', 'Shop Date: '|| to_char(I_shop_date)
                    || 'Competitor: '|| to_char(I_competitor));
   open C_COMP_STORE_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_COMP_STORE_EXIST','COMP_SHOP_LIST_TEMP', 'Shop Date: '|| to_char(I_shop_date)
                    || 'Competitor: '|| to_char(I_competitor));
   fetch C_COMP_STORE_EXIST into L_dummy;
   if C_COMP_STORE_EXIST%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_COMP_STORE_EXIST','COMP_SHOP_LIST_TEMP', 'Shop Date: '|| to_char(I_shop_date)
                    || 'Competitor: '|| to_char(I_competitor));
      close C_COMP_STORE_EXIST;
      O_error_message := SQL_LIB.CREATE_MSG('INV_COMP_STORE', NULL, NULL, NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_COMP_STORE_EXIST','COMP_SHOP_LIST_TEMP', 'Shop Date: '|| to_char(I_shop_date)
                    || 'Competitor: '|| to_char(I_competitor));
   close C_COMP_STORE_EXIST;

   if not COMPETITOR_SQL.GET_STORE_NAME(O_error_message,
                                        O_store_name,
                                        L_competitor,
                                        L_comp_name,
                                        O_currency,
                                        I_comp_store) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));

   return FALSE;
END COMP_STORE_VALIDATION;
------------------------------------------------------------------------------
FUNCTION CURRENCY_VALIDATION(O_error_message IN OUT VARCHAR2,
                             I_shopper       IN     COMP_SHOP_LIST.SHOPPER%TYPE,
                             I_item          IN     COMP_SHOP_LIST.ITEM%TYPE,
                             I_currency      IN     CURRENCIES.CURRENCY_CODE%TYPE,
                             I_shop_date     IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                             I_competitor    IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS
   L_program     VARCHAR2(60)  := 'COMPETITOR_PRICE_SQL.CURRENCY_VALIDATION';
   L_dummy       VARCHAR2(1) := NULL;


   cursor C_CURRENCY_CODE is
      select 'Y'
        from comp_shop_list_temp csl,
             comp_store cs
       where csl.competitor   = I_competitor
         and csl.shop_date    = I_shop_date
         and csl.shopper      = nvl(I_shopper, csl.shopper)
         and csl.item         = nvl(I_item, csl.item)
         and csl.comp_store   = cs.store
         and cs.currency_code = I_currency;

BEGIN

   if I_competitor is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_competitor',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_shop_date is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_shop_date',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_currency is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_currency',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_CURRENCY_CODE','COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date));
   open C_CURRENCY_CODE;

   SQL_LIB.SET_MARK('FETCH','C_CURRENCY_CODE','COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date));

   fetch C_CURRENCY_CODE into L_dummy;

   if C_CURRENCY_CODE%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CURRENCY_CODE','COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date));
      close C_CURRENCY_CODE;
      ---
      O_error_message:= sql_lib.create_msg('CURRENCY_CODE',
                                           NULL,NULL,NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_CURRENCY_CODE','COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date));
   close C_CURRENCY_CODE;

   return TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   RETURN FALSE;
END CURRENCY_VALIDATION;
----------------------------------------------------------------------------------------
FUNCTION DEFAULT_COMP_RETAIL(O_error_message IN OUT VARCHAR2,
                             I_comp_store    IN     COMP_SHOP_LIST.COMP_STORE%TYPE,
                             I_shop_date     IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                             I_competitor    IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(60)  := 'COMPETITOR_PRICE_SQL.DEFAULT_COMP_RETAIL';
   L_table          VARCHAR2(30)  := 'COMP_SHOP_LIST_TEMP';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);
   L_item           COMP_SHOP_LIST.ITEM%TYPE;
   L_ref_item       COMP_SHOP_LIST.REF_ITEM%TYPE;
   L_comp_store     COMP_SHOP_LIST.COMP_STORE%TYPE;

   cursor C_UPDATE_INFO is
      select cph.rec_date,
             cph.item,
             cph.ref_item,
             cph.comp_store,
             cph.comp_retail,
             cph.comp_retail_type,
             cph.multi_units,
             cph.multi_unit_retail,
             cph.prom_start_date,
             cph.prom_end_date,
             cph.offer_type
        from comp_price_hist cph,
             comp_shop_list_temp csl
       where cph.comp_store = csl.comp_store
         and csl.competitor = I_competitor
         and csl.shop_date  = I_shop_date
         and csl.item       = cph.item
         and (csl.ref_item   = cph.ref_item or (cph.ref_item is NULL and csl.ref_item is NULL))
         and csl.comp_store = nvl(I_comp_store, csl.comp_store)
         and csl.comp_retail is NULL
         and cph.rec_date = (select max(rec_date)
                               from comp_price_hist cph2
                              where cph2.item = cph.item
                                and (cph2.ref_item = cph.ref_item
                                     or (cph2.ref_item is NULL and cph.ref_item is NULL))
                                and cph2.comp_store = cph.comp_store);

   cursor C_LOCK_SHOP is
      select 'x'
        from comp_shop_list_temp
       where competitor = I_competitor
         and shop_date  = I_shop_date
         and item       = L_item
         and comp_store = L_comp_store
         and comp_retail is NULL
         and ((L_ref_item is not NULL and ref_item = L_ref_item) or
             (L_ref_item is NULL and ref_item is NULL))
         for update nowait;

BEGIN

   if I_competitor is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_competitor',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_shop_date is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_shop_date',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   FOR rec in C_UPDATE_INFO LOOP
      L_item       := rec.item;
      L_ref_item   := rec.ref_item;
      L_comp_store := rec.comp_store;

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHOP',L_table,
                    'Item: '|| L_item || 'Comp Store: '|| to_char(I_comp_store) || 'Date: '|| to_char(I_shop_date));
      open C_LOCK_SHOP;

      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHOP',L_table,
                    'Item: '|| L_item || 'Comp Store: '|| to_char(I_comp_store) || 'Date: '|| to_char(I_shop_date));
      close C_LOCK_SHOP;

      SQL_LIB.SET_MARK('UPDATE', L_table, NULL, NULL);

      update comp_shop_list_temp
         set rec_date          = I_shop_date,
             comp_retail       = rec.comp_retail,
             comp_retail_type  = rec.comp_retail_type,
             multi_units       = rec.multi_units,
             multi_unit_retail = rec.multi_unit_retail,
             prom_start_date   = rec.prom_start_date,
             prom_end_date     = rec.prom_end_date,
             offer_type        = rec.offer_type
       where competitor = I_competitor
         and shop_date  = I_shop_date
         and item       = L_item
         and comp_store = L_comp_store
         and comp_retail is NULL
         and ((L_ref_item is not NULL and ref_item = L_ref_item) or
             (L_ref_item is NULL and ref_item is NULL));
   END LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_item ||', '||L_comp_store,
                                             NULL);
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   RETURN FALSE;
END DEFAULT_COMP_RETAIL;
----------------------------------------------------------------------------------------
FUNCTION GET_COMP_RETAIL(O_error_message     IN OUT VARCHAR2,
                         O_unit_retail       IN OUT COMP_SHOP_LIST.COMP_RETAIL%TYPE,
                         O_multi_unit_retail IN OUT COMP_SHOP_LIST.MULTI_UNIT_RETAIL%TYPE,
                         O_multi_units       IN OUT COMP_SHOP_LIST.MULTI_UNITS%TYPE,
                         O_retail_type       IN OUT COMP_SHOP_LIST.COMP_RETAIL_TYPE%TYPE,
                         I_item              IN     COMP_SHOP_LIST.ITEM%TYPE,
                         I_ref_item          IN     COMP_SHOP_LIST.REF_ITEM%TYPE,
                         I_comp_store        IN     COMP_SHOP_LIST.COMP_STORE%TYPE,
                         I_shop_date         IN     COMP_SHOP_LIST.REC_DATE%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(60)  := 'COMPETITOR_PRICE_SQL.GET_COMP_RETAIL';

   cursor C_GET_RETAIL is
      select cph1.comp_retail,
             cph1.comp_retail_type,
             cph1.multi_units,
             cph1.multi_unit_retail
        from comp_price_hist cph1
       where cph1.item       = I_item
         and cph1.comp_store = I_comp_store
         and cph1.rec_date   <= I_shop_date
         and ((I_ref_item is not NULL and cph1.ref_item = I_ref_item) or
             (I_ref_item is NULL and cph1.ref_item is NULL))
         and cph1.rec_date = (select max(rec_date)
                                from comp_price_hist cph2
                               where cph1.item = cph2.item
                                 and cph1.comp_store = cph2.comp_store
                                 and (cph1.ref_item = cph2.ref_item
                                    or (cph1.ref_item is NULL and cph2.ref_item is NULL)));

BEGIN

   if I_item is NULL then
     O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                          'I_shopper',
                                          'NULL',
                                          'NOT NULL');
      return FALSE;
   end if;

   if I_comp_store is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_comp_store',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_shop_date is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_shop_date',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_GET_RETAIL','COMP_PRICE_HIST',
                    'Item: '|| I_item || 'Comp Store: '|| to_char(I_comp_store) || 'Date: '|| to_char(I_shop_date));
   open C_GET_RETAIL;

   SQL_LIB.SET_MARK('FETCH', 'C_GET_RETAIL','COMP_PRICE_HIST',
                    'Item: '|| I_item || 'Comp Store: '|| to_char(I_comp_store) || 'Date: '|| to_char(I_shop_date));
   fetch C_GET_RETAIL into O_unit_retail,
                           O_retail_type,
                           O_multi_units,
                           O_multi_unit_retail;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_RETAIL','COMP_PRICE_HIST',
                    'Item: '|| I_item || 'Comp Store: '|| to_char(I_comp_store) || 'Date: '|| to_char(I_shop_date));
   close C_GET_RETAIL;

   return TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   RETURN FALSE;
END GET_COMP_RETAIL;
----------------------------------------------------------------------------------------
FUNCTION INSERT_DELETE_COMP_TEMP(O_error_message IN OUT VARCHAR2,
                                 I_shopper       IN     COMP_SHOP_LIST.SHOPPER%TYPE,
                                 I_comp_store    IN     COMP_SHOP_LIST.COMP_STORE%TYPE,
                                 I_shop_date     IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                                 I_competitor    IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS
   L_program        VARCHAR2(60)   := 'COMPETITOR_PRICE_SQL.INSERT_DELETE_COMP_TEMP';
   L_table          VARCHAR2(30)   := 'COMP_SHOP_LIST_TEMP';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_SHOP is
      select 'x'
        from comp_shop_list_temp
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHOP','COMP_SHOP_LIST_TEMP', NULL);
   open C_LOCK_SHOP;

   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHOP','COMP_SHOP_LIST_TEMP', NULL);
   close C_LOCK_SHOP;

   SQL_LIB.SET_MARK('UPDATE', 'COMP_SHOP_LIST_TEMP', NULL, NULL);
   delete from comp_shop_list_temp;

   if I_competitor is not NULL and I_shop_date is not NULL then

         SQL_LIB.SET_MARK('INSERT', 'COMP_SHOP_LIST_TEMP', NULL, NULL);
      insert into comp_shop_list_temp(shopper,
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
                                      multi_units,
                                      multi_unit_retail,
                                      prom_start_date,
                                      prom_end_date,
                                      offer_type)
                               select shopper,
                                      shop_date,
                                      item,
                                      item_desc,
                                      ref_item,
                                      competitor,
                                      comp_name,
                                      comp_store,
                                      comp_store_name,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL
                                 from comp_shop_list
                                where competitor = I_competitor
                                  and shop_date  = I_shop_date
                                  and shopper    = nvl(I_shopper, shopper)
                                  and comp_store = nvl(I_comp_store, comp_store)
                                  and comp_retail is NULL;
   end if;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             NULL,
                                             NULL);

   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   RETURN FALSE;
END INSERT_DELETE_COMP_TEMP;
----------------------------------------------------------------------------------------
FUNCTION ITEM_VALIDATION(O_error_message IN OUT VARCHAR2,
                         O_item_desc     IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                         I_shopper       IN     COMP_SHOP_LIST.SHOPPER%TYPE,
                         I_comp_store    IN     COMP_SHOP_LIST.COMP_STORE%TYPE,
                         I_currency      IN     CURRENCIES.CURRENCY_CODE%TYPE,
                         I_item          IN     COMP_SHOP_LIST.ITEM%TYPE,
                         I_ref_item      IN     COMP_SHOP_LIST.REF_ITEM%TYPE,
                         I_shop_date     IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                         I_competitor    IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS
   L_program     VARCHAR2(60)  := 'COMPETITOR_PRICE_SQL.ITEM_VALIDATION';
   L_dummy       VARCHAR2(1);

   CURSOR C_ITEM_VAL is
      select 'Y'
        from comp_shop_list_temp csl,
             comp_store cs
       where csl.competitor = I_competitor
         and csl.shop_date  = I_shop_date
         and csl.item       = I_item
         and csl.comp_store = nvl(I_comp_store, csl.comp_store)
         and csl.comp_store = cs.store
         and csl.shopper    = nvl(I_shopper, csl.shopper)
         and cs.currency_code = nvl(I_currency, cs.currency_code)
         and ((I_ref_item is not NULL and ref_item = I_ref_item) or
             (I_ref_item is NULL));

BEGIN
   if I_competitor is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_competitor',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_shop_date is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_shop_date',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM_VAL', 'COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date)
                    || 'Item : '||I_item);
   open C_ITEM_VAL;

   SQL_LIB.SET_MARK('FETCH', 'C_ITEM_VAL', 'COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date)
                    || 'Item : '||I_item);

   fetch C_ITEM_VAL into L_dummy;

   if C_ITEM_VAL%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_VAL', 'COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date)
                    || 'Item : '||I_item);

      close C_ITEM_VAL;

      O_error_message := SQL_LIB.CREATE_MSG('INVALID_ITEM', NULL, NULL, NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_VAL', 'COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date)
                    || 'Item : '||I_item);
   close C_ITEM_VAL;

   if not ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                                   O_item_desc,
                                   I_item) then
      return FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END ITEM_VALIDATION;
----------------------------------------------------------------------------------------
FUNCTION REF_ITEM_VALIDATION(O_error_message IN OUT VARCHAR2,
                             O_ref_item_desc IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                             O_item_desc     IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                             IO_item         IN OUT COMP_SHOP_LIST.ITEM%TYPE,
                             I_shopper       IN     COMP_SHOP_LIST.SHOPPER%TYPE,
                             I_comp_store    IN     COMP_SHOP_LIST.COMP_STORE%TYPE,
                             I_currency      IN     CURRENCIES.CURRENCY_CODE%TYPE,
                             I_ref_item      IN     COMP_SHOP_LIST.REF_ITEM%TYPE,
                             I_shop_date     IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                             I_competitor    IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS
   L_program     VARCHAR2(60)  := 'COMPETITOR_PRICE_SQL.REF_ITEM_VALIDATION';
   L_dummy       VARCHAR2(1);

   CURSOR C_ITEM_VAL is
      select csl.item
        from comp_shop_list_temp csl,
             comp_store cs
       where csl.competitor = I_competitor
         and csl.shop_date  = I_shop_date
         and csl.ref_item   = I_ref_item
         and csl.item       = nvl(IO_item, csl.item)
         and csl.comp_store = nvl(I_comp_store, csl.comp_store)
         and csl.comp_store = cs.store
         and csl.shopper    = nvl(I_shopper, csl.shopper)
         and cs.currency_code = nvl(I_currency, cs.currency_code);

BEGIN
   if I_competitor is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_competitor',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_shop_date is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_shop_date',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   if I_ref_item is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM',
                                           'I_ref_item',
                                           'NULL',
                                           'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM_VAL', 'COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date)
                    || 'Item : '||I_ref_item);
   open C_ITEM_VAL;

   SQL_LIB.SET_MARK('FETCH', 'C_ITEM_VAL', 'COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date)
                    || 'Item : '||I_ref_item);

   fetch C_ITEM_VAL into IO_item;

   if C_ITEM_VAL%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_VAL', 'COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date)
                    || 'Item : '||I_ref_item);

      close C_ITEM_VAL;

      O_error_message := SQL_LIB.CREATE_MSG('INVALID_ITEM', NULL, NULL, NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_VAL', 'COMP_SHOP_LIST_TEMP, COMP_STORE',
                    'Competitor: '|| to_char(I_competitor) || 'Shop Date: '|| to_char(I_shop_date)
                    || 'Item : '||I_ref_item);
   close C_ITEM_VAL;

   if not ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                                   O_ref_item_desc,
                                   I_ref_item) then
      return FALSE;
   end if;

   if not ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                                   O_item_desc,
                                   IO_item) then
      return FALSE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END REF_ITEM_VALIDATION;
---------------------------------------------------------------------------------
FUNCTION UPDATE_ALL_ITEM_STORES(O_error_message     IN OUT VARCHAR2,
                                I_comp_retail       IN     COMP_SHOP_LIST.COMP_RETAIL%TYPE,
                                I_multi_unit_retail IN     COMP_SHOP_LIST.MULTI_UNIT_RETAIL%TYPE,
                                I_multi_units       IN     COMP_SHOP_LIST.MULTI_UNITS%TYPE,
                                I_comp_retail_type  IN     COMP_SHOP_LIST.COMP_RETAIL_TYPE%TYPE,
                                I_rec_date          IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                                I_offer_type        IN     COMP_SHOP_LIST.OFFER_TYPE%TYPE,
                                I_prom_start_date   IN     COMP_SHOP_LIST.PROM_START_DATE%TYPE,
                                I_prom_end_date     IN     COMP_SHOP_LIST.PROM_END_DATE%TYPE,
                                I_shopper           IN     COMP_SHOP_LIST.SHOPPER%TYPE,
                                I_item              IN     COMP_SHOP_LIST.ITEM%TYPE,
                                I_ref_item          IN     COMP_SHOP_LIST.REF_ITEM%TYPE,
                                I_currency          IN     CURRENCIES.CURRENCY_CODE%TYPE,
                                I_shop_date         IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                                I_competitor        IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(60) := 'COMPETITOR_PRICE_SQL.UPDATE_ALL_ITEM_STORES';
   L_table         VARCHAR2(30) := 'COMP_SHOP_LIST_TEMP';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_SHOP is
      select 'x'
        from comp_shop_list_temp
       where competitor = I_competitor
         and shop_date  = I_shop_date
         and item       = I_item
         and shopper    = nvl(I_shopper, shopper)
         and ((I_ref_item is not NULL and ref_item = I_ref_item) or
             (I_ref_item is NULL))
         and comp_store in (select store
                              from comp_store
                             where currency_code = I_currency
                               and competitor    = I_competitor)
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHOP', L_table,
                    'Item: '|| I_item || 'competitor: '||to_char(I_competitor) || 'Date: '||to_char(I_shop_date));
   open C_LOCK_SHOP;

   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHOP', L_table,
                    'Item: '|| I_item || 'competitor: '||to_char(I_competitor) || 'Date: '||to_char(I_shop_date));
   close C_LOCK_SHOP;

   SQL_LIB.SET_MARK('UPDATE', L_table, NULL, NULL);

   update comp_shop_list_temp
      set rec_date          = I_rec_date,
          comp_retail       = I_comp_retail,
          comp_retail_type  = I_comp_retail_type,
          multi_units       = I_multi_units,
          multi_unit_retail = I_multi_unit_retail,
          prom_start_date   = I_prom_start_date,
          prom_end_date     = I_prom_end_date,
          offer_type        = I_offer_type
    where competitor = I_competitor
      and shop_date  = I_shop_date
      and item       = I_item
      and shopper    = nvl(I_shopper, shopper)
      and ((I_ref_item is not NULL and ref_item = I_ref_item) or
             (I_ref_item is NULL))
      and comp_store in (select store
                           from comp_store
                          where currency_code = I_currency
                            and competitor    = I_competitor);
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             I_item ||', '||I_competitor,
                                             NULL);
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END UPDATE_ALL_ITEM_STORES;
---------------------------------------------------------------------------------
FUNCTION UPDATE_COMP_SHOP_LIST(O_error_message     IN OUT VARCHAR2,
                               I_shopper           IN     COMP_SHOP_LIST.SHOPPER%TYPE,
                               I_comp_store        IN     COMP_SHOP_LIST.COMP_STORE%TYPE,
                               I_shop_date         IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                               I_competitor        IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(60)  := 'COMPETITOR_PRICE_SQL.UPDATE_COMP_SHOP_LIST';
   L_table          VARCHAR2(30)   := 'COMP_SHOP_LIST';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   L_item           COMP_SHOP_LIST.ITEM%TYPE;
   L_ref_item       COMP_SHOP_LIST.REF_ITEM%TYPE;
   L_comp_store     COMP_SHOP_LIST.COMP_STORE%TYPE;
   L_shopper        COMP_SHOP_LIST.SHOPPER%TYPE;

   cursor C_GET_INFO is
      select item,
             ref_item,
             rec_date,
             comp_store,
             comp_retail,
             comp_retail_type,
             multi_units,
             multi_unit_retail,
             prom_start_date,
             prom_end_date,
             offer_type,
             shopper
        from comp_shop_list_temp csl
       where competitor = I_competitor
         and shop_date  = I_shop_date
         and shopper    = nvl(I_shopper, shopper)
         and comp_store = nvl(I_comp_store, comp_store);

   cursor C_LOCK_SHOP is
      select 'x'
        from comp_shop_list
       where competitor = I_competitor
         and shop_date  = I_shop_date
         and item       = L_item
         and comp_store = L_comp_store
         and shopper    = L_shopper
         and ((L_ref_item is not NULL and ref_item = L_ref_item) or
             (L_ref_item is NULL and ref_item is NULL))
         for update nowait;
BEGIN

   FOR new in C_GET_INFO LOOP
      L_item := new.item;
      L_ref_item := new.ref_item;
      L_comp_store := new.comp_store;
      L_shopper   := new.shopper;

      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHOP','COMP_SHOP_LIST',
                    'Item: '|| L_item || 'competitor: '||to_char(I_competitor) || 'Date: '||to_char(I_shop_date));
      open C_LOCK_SHOP;

      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHOP','COMP_SHOP_LIST',
                    'Item: '|| L_item || 'competitor: '||to_char(I_competitor) || 'Date: '||to_char(I_shop_date));
      close C_LOCK_SHOP;

      SQL_LIB.SET_MARK('UPDATE', 'COMP_SHOP_LIST', NULL, NULL);
      update comp_shop_list
         set rec_date          = new.rec_date,
             comp_retail       = new.comp_retail,
             comp_retail_type  = new.comp_retail_type,
             multi_units       = new.multi_units,
             multi_unit_retail = new.multi_unit_retail,
             prom_start_date   = new.prom_start_date,
             prom_end_date     = new.prom_end_date,
             offer_type        = new.offer_type
       where competitor = I_competitor
         and shop_date  = I_shop_date
         and item       = L_item
         and comp_store = L_comp_store
         and shopper    = L_shopper
         and ((L_ref_item is not NULL and ref_item = L_ref_item) or
             (L_ref_item is NULL and ref_item is NULL));

   END LOOP;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             I_shop_date ||', '||I_competitor,
                                             NULL);
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END UPDATE_COMP_SHOP_LIST;
---------------------------------------------------------------------------------
FUNCTION UPDATE_SINGLE_ITEM_STORE(O_error_message     IN OUT VARCHAR2,
                                  I_comp_retail       IN     COMP_SHOP_LIST.COMP_RETAIL%TYPE,
                                  I_multi_unit_retail IN     COMP_SHOP_LIST.MULTI_UNIT_RETAIL%TYPE,
                                  I_multi_units       IN     COMP_SHOP_LIST.MULTI_UNITS%TYPE,
                                  I_comp_retail_type  IN     COMP_SHOP_LIST.COMP_RETAIL_TYPE%TYPE,
                                  I_rec_date          IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                                  I_offer_type        IN     COMP_SHOP_LIST.OFFER_TYPE%TYPE,
                                  I_prom_start_date   IN     COMP_SHOP_LIST.PROM_START_DATE%TYPE,
                                  I_prom_end_date     IN     COMP_SHOP_LIST.PROM_END_DATE%TYPE,
                                  I_shopper           IN     COMP_SHOP_LIST.SHOPPER%TYPE,
                                  I_item              IN     COMP_SHOP_LIST.ITEM%TYPE,
                                  I_ref_item          IN     COMP_SHOP_LIST.REF_ITEM%TYPE,
                                  I_comp_store        IN     COMP_SHOP_LIST.COMP_STORE%TYPE,
                                  I_shop_date         IN     COMP_SHOP_LIST.REC_DATE%TYPE,
                                  I_competitor        IN     COMP_SHOP_LIST.COMPETITOR%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(60)  := 'COMPETITOR_PRICE_SQL.UPDATE_SINGLE_ITEM_STORES';
   L_table         VARCHAR2(30)  := 'COMP_SHOP_LIST_TEMP';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_SHOP is
      select 'x'
        from comp_shop_list_temp
       where competitor = I_competitor
         and shop_date  = I_shop_date
         and item       = I_item
         and comp_store = I_comp_store
         and shopper    = nvl(I_shopper, shopper)
         and ((I_ref_item is not NULL and ref_item = I_ref_item) or
              (I_ref_item is NULL))
         for update nowait;
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHOP', L_table,
                    'Item: '|| I_item || 'Comp Store: '||to_char(I_comp_store) || 'Date: '||to_char(I_shop_date));
   open C_LOCK_SHOP;

   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHOP', L_table,
                    'Item: '|| I_item || 'Comp Store: '||to_char(I_comp_store) || 'Date: '||to_char(I_shop_date));
   close C_LOCK_SHOP;


   SQL_LIB.SET_MARK('UPDATE', L_table, NULL, NULL);

   update comp_shop_list_temp
      set rec_date          = I_rec_date,
          comp_retail       = I_comp_retail,
          comp_retail_type  = I_comp_retail_type,
          multi_units       = I_multi_units,
          multi_unit_retail = I_multi_unit_retail,
          prom_start_date   = I_prom_start_date,
          prom_end_date     = I_prom_end_date,
          offer_type        = I_offer_type
    where competitor = I_competitor
      and shop_date  = I_shop_date
      and item       = I_item
      and comp_store = I_comp_store
      and shopper    = nvl(I_shopper, shopper)
      and ((I_ref_item is not NULL and ref_item = I_ref_item) or
             (I_ref_item is NULL));

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             I_item ||', '||I_comp_store,
                                             NULL);
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END UPDATE_SINGLE_ITEM_STORE;
---------------------------------------------------------------------------------
END COMPETITOR_PRICE_SQL;
/

