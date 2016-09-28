CREATE OR REPLACE PACKAGE BODY GEOCODE_SQL AS
----------------------------------------------------------
FUNCTION LOCK_GEOCODE_TXCDE(O_error_message    IN OUT    VARCHAR2,
                            O_lock_ind         IN OUT    BOOLEAN,
                            I_geocode_level    IN        GEOCODE_STORE.GEOCODE_LEVEL%TYPE,
                            I_country          IN        GEOCODE_STORE.COUNTRY_GEOCODE_ID%TYPE,
                            I_state            IN        GEOCODE_STORE.STATE_GEOCODE_ID%TYPE,
                            I_county           IN        GEOCODE_STORE.COUNTY_GEOCODE_ID%TYPE,
                            I_city             IN        GEOCODE_STORE.CITY_GEOCODE_ID%TYPE,
                            I_district         IN        GEOCODE_STORE.DISTRICT_GEOCODE_ID%TYPE)


   RETURN BOOLEAN is
   ---
   L_program            VARCHAR2(64) := 'GEOCODE_SQL.LOCK_GEOCODE_TXCDE';
   ---
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_GEOCODE_COUNRTY_LOCK is
      select 'X'
        from geocode_txcde
       where country_geocode_id = I_country
         and state_geocode_id is NULL
         and county_geocode_id is NULL
         and city_geocode_id is NULL
         and district_geocode_id is NULL
      for update nowait;


   cursor C_GEOCODE_STATE_LOCK is
      select 'X'
        from geocode_txcde
       where country_geocode_id = I_country
         and state_geocode_id = I_state
         and county_geocode_id is NULL
         and city_geocode_id is NULL
         and district_geocode_id is NULL
      for update nowait;


   cursor C_GEOCODE_COUNTY_LOCK is
      select 'X'
        from geocode_txcde
       where country_geocode_id = I_country
         and state_geocode_id = I_state
         and county_geocode_id = I_county
         and city_geocode_id is NULL
         and district_geocode_id is NULL
      for update nowait;

   cursor C_GEOCODE_CITY_LOCK is
      select 'X'
        from geocode_txcde
       where country_geocode_id = I_country
         and state_geocode_id = I_state
         and county_geocode_id = I_county
         and city_geocode_id = I_city
         and district_geocode_id is NULL
      for update nowait;

   cursor C_GEOCODE_DISTRICT_LOCK is
      select 'X'
        from geocode_txcde
       where country_geocode_id = I_country
         and state_geocode_id = I_state
         and county_geocode_id = I_county
         and city_geocode_id = I_city
         and district_geocode_id = I_district
      for update nowait;

   ---
BEGIN

   if I_geocode_level = 'CNTRY' then
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_COUNTRY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country);
      open C_GEOCODE_COUNRTY_LOCK;
      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_COUNTRY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country);
      close C_GEOCODE_COUNRTY_LOCK;

  elsif I_geocode_level = 'STATE'then
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_STATE_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state);
      open C_GEOCODE_STATE_LOCK;
      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_STATE_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state);
      close C_GEOCODE_STATE_LOCK;

  elsif I_geocode_level = 'CNTY' then
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_COUNTY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state||'COUNTY:  '||I_county);
      open C_GEOCODE_COUNTY_LOCK;
      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_COUNTY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state||'COUNTY:  '||I_county);
      close C_GEOCODE_COUNTY_LOCK;

  elsif I_geocode_level = 'CITY' then
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_CITY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state||'COUNTY:  '||I_county||'CITY:  '||I_city);
      open C_GEOCODE_CITY_LOCK;
      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_CITY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state||'COUNTY:  '||I_county||'CITY:  '||I_city);
      close C_GEOCODE_CITY_LOCK;

  else
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_DISTRICT_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
        I_state||'COUNTY:  '||I_county||'CITY:  '||I_city||'DISTRICT:  '||I_district);
      open C_GEOCODE_DISTRICT_LOCK;

      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_DISTRICT_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
        I_state||'COUNTY:  '||I_county||'CITY:  '||I_city||'DISTRICT:  '||I_district);
      close C_GEOCODE_DISTRICT_LOCK;
  end if;

   O_lock_ind := TRUE;

   RETURN TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('GEOCODE_TAXCODE_REC_LOCK',
                                            NULL,
                                            NULL,
                                            NULL);

      O_lock_ind := FALSE;
      return TRUE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;

END LOCK_GEOCODE_TXCDE;
----------------------------------------------------------
FUNCTION LOCK_GEOCODE_STORE(O_error_message    IN OUT    VARCHAR2,
                            O_lock_ind         IN OUT    BOOLEAN,
                            I_geocode_level    IN        GEOCODE_STORE.GEOCODE_LEVEL%TYPE,
                            I_country          IN        GEOCODE_STORE.COUNTRY_GEOCODE_ID%TYPE,
                            I_state            IN        GEOCODE_STORE.STATE_GEOCODE_ID%TYPE,
                            I_county           IN        GEOCODE_STORE.COUNTY_GEOCODE_ID%TYPE,
                            I_city             IN        GEOCODE_STORE.CITY_GEOCODE_ID%TYPE,
                            I_district         IN        GEOCODE_STORE.DISTRICT_GEOCODE_ID%TYPE)

          RETURN BOOLEAN is

   L_program            VARCHAR2(64) := 'GEOCODE_SQL.LOCK_GEOCODE_STORE';
   ---
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_GEOCODE_COUNRTY_LOCK is
      select 'X'
        from geocode_store
       where country_geocode_id = I_country
         and state_geocode_id is NULL
         and county_geocode_id is NULL
         and city_geocode_id is NULL
         and district_geocode_id is NULL
      for update nowait;


   cursor C_GEOCODE_STATE_LOCK is
      select 'X'
        from geocode_store
       where country_geocode_id = I_country
         and state_geocode_id = I_state
         and county_geocode_id is NULL
         and city_geocode_id is NULL
         and district_geocode_id is NULL
      for update nowait;


   cursor C_GEOCODE_COUNTY_LOCK is
      select 'X'
        from geocode_store
       where country_geocode_id = I_country
         and state_geocode_id = I_state
         and county_geocode_id = I_county
         and city_geocode_id is NULL
         and district_geocode_id is NULL
      for update nowait;

   cursor C_GEOCODE_CITY_LOCK is
      select 'X'
        from geocode_store
       where country_geocode_id = I_country
         and state_geocode_id = I_state
         and county_geocode_id = I_county
         and city_geocode_id = I_city
         and district_geocode_id is NULL
      for update nowait;

   cursor C_GEOCODE_DISTRICT_LOCK is
      select 'X'
        from geocode_store
       where country_geocode_id = I_country
         and state_geocode_id = I_state
         and county_geocode_id = I_county
         and city_geocode_id = I_city
         and district_geocode_id = I_district
      for update nowait;

   ---
BEGIN

   if I_geocode_level = 'CNTRY' then
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_COUNTRY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country);
      open C_GEOCODE_COUNRTY_LOCK;
      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_COUNTRY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country);
      close C_GEOCODE_COUNRTY_LOCK;

  elsif I_geocode_level = 'STATE'then
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_STATE_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state);
      open C_GEOCODE_STATE_LOCK;
      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_STATE_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state);
      close C_GEOCODE_STATE_LOCK;

  elsif I_geocode_level = 'CNTY' then
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_COUNTY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state||'COUNTY:  '||I_county);
      open C_GEOCODE_COUNTY_LOCK;
      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_COUNTY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state||'COUNTY:  '||I_county);
      close C_GEOCODE_COUNTY_LOCK;

  elsif I_geocode_level = 'CITY' then
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_CITY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state||'COUNTY:  '||I_county||'CITY:  '||I_city);
      open C_GEOCODE_CITY_LOCK;
      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_CITY_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
                       I_state||'COUNTY:  '||I_county||'CITY:  '||I_city);
      close C_GEOCODE_CITY_LOCK;

  else
      SQL_LIB.SET_MARK('OPEN','C_GEOCODE_DISTRICT_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
        I_state||'COUNTY:  '||I_county||'CITY:  '||I_city||'DISTRICT:  '||I_district);
      open C_GEOCODE_DISTRICT_LOCK;

      SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_DISTRICT_LOCK','GEOCODE_STORE','COUNTRY: '||I_country||' STATE:  '||
        I_state||'COUNTY:  '||I_county||'CITY:  '||I_city||'DISTRICT:  '||I_district);
      close C_GEOCODE_DISTRICT_LOCK;
  end if;

   O_lock_ind := TRUE;

   RETURN TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('GEOCODE_TAXCODE_REC_LOCK',
                                            NULL,
                                            NULL,
                                            NULL);

      O_lock_ind := FALSE;
      return TRUE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;

END LOCK_GEOCODE_STORE;
----------------------------------------------------------
FUNCTION STORE_EXISTS(O_error_message       IN OUT     VARCHAR2,
                      O_exists              IN OUT     VARCHAR2,
                      I_store               IN         GEOCODE_STORE.STORE%TYPE,
                      O_geocode_level       IN OUT     GEOCODE_STORE.GEOCODE_LEVEL%TYPE,
                      O_country             IN OUT     GEOCODE_STORE.COUNTRY_GEOCODE_ID%TYPE,
                      O_state               IN OUT     GEOCODE_STORE.STATE_GEOCODE_ID%TYPE,
                      O_county              IN OUT     GEOCODE_STORE.COUNTY_GEOCODE_ID%TYPE,
                      O_city                IN OUT     GEOCODE_STORE.CITY_GEOCODE_ID%TYPE,
                      O_district            IN OUT     GEOCODE_STORE.DISTRICT_GEOCODE_ID%TYPE)
   RETURN BOOLEAN is
   ---
   L_program                   VARCHAR2(64)    := 'GEOCODE_SQL.STORE_EXISTS';
   L_table                     VARCHAR2(64)    := 'GEOCODE_STORE';
   ---

   cursor C_STORE_EXISTS is
      select geocode_level,
             country_geocode_id,
             state_geocode_id,
             county_geocode_id,
             city_geocode_id,
             district_geocode_id
        from geocode_store
       where store = I_store;
   ---
BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_STORE_EXISTS', L_table, 'STORE: '||to_char(I_store));
   open C_STORE_EXISTS;
   SQL_LIB.SET_MARK('FETCH', 'C_STORE_EXISTS', L_table, 'STORE: '||to_char(I_store));
   fetch C_STORE_EXISTS into O_geocode_level,
                             O_country,
                             O_state,
                             O_county,
                             O_city,
                             O_district;
   if C_STORE_EXISTS%FOUND then
      O_exists := 'Y';
   else
      O_exists := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_STORE_EXISTS', L_table, 'STORE: '||to_char(I_store));
   close C_STORE_EXISTS;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END STORE_EXISTS;
----------------------------------------------------------
FUNCTION DELETE_STORE(O_error_message   IN OUT    VARCHAR2,
                      I_store           IN        GEOCODE_STORE.STORE%TYPE)
   RETURN BOOLEAN is

   L_program            VARCHAR2(64) := 'GEOCODE_SQL.DELETE_STORE';
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);


   cursor C_LOCK_GEOCODE_STORE is
    select 'x'
      from geocode_store
     where store = I_store
     for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN',NULL,'STORE','GEOCODE_STORE: '||to_char(I_store));
   open C_LOCK_GEOCODE_STORE;

   SQL_LIB.SET_MARK('CLOSE',NULL,'STORE','GEOCODE_STORE: '||to_char(I_store));
   close C_LOCK_GEOCODE_STORE;

   ---
   SQL_LIB.SET_MARK('DELETE',NULL,'STORE','GEOCODE_STORE: '||to_char(I_store));
   ---
   delete from geocode_store
         where store = I_store;
   ---
   RETURN TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('GEOCODE_STORE_REC_LOCK',
                                            I_store,
                                            NULL,
                                            NULL);

      return FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END DELETE_STORE;
----------------------------------------------------------
FUNCTION NEXT_GEOCODE_TXCDE(O_error_message IN OUT  VARCHAR2,
                            O_seq_no        IN OUT  GEOCODE_TXCDE.SEQ_NO%TYPE)
   RETURN BOOLEAN is

   L_program	VARCHAR2(64) := 'GEOCODE_SQL.NEXT_GEOCODE_TXCDE';
   L_first_one    GEOCODE_TXCDE.SEQ_NO%TYPE  := NULL;
   L_seq_no_tmp   GEOCODE_TXCDE.SEQ_NO%TYPE  := NULL;
   L_exists       VARCHAR2(1)                   := 'N';

   cursor C_SEQ is
      select geocode_txcde_sequence.NEXTVAL seq
        from sys.dual;

   cursor C_EXISTS is
      select 'Y'
        from geocode_txcde
       where seq_no = L_seq_no_tmp;

BEGIN
   LOOP
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_SEQ',
                       'GEOCODE_TXCDE_SEQUENCE',
                       NULL);
      open  C_SEQ;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_SEQ',
                       'GEOCODE_TXCDE_SEQUENCE',
                       NULL);
      fetch C_SEQ into L_seq_no_tmp;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SEQ',
                       'GEOCODE_TXCDE_SEQUENCE',
                       NULL);
      close C_SEQ;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_EXISTS',
                       'GEOCODE_TXCDE',
                       'SEQ NO: '||TO_CHAR(L_seq_no_tmp));
      open  C_EXISTS;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_EXISTS',
                       'GEOCODE_TXCDE',
                       'SEQ NO: '||TO_CHAR(L_seq_no_tmp));
      fetch C_EXISTS into L_exists;
      ---
      if (C_EXISTS%notfound) then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_EXISTS',
                          'GEOCODE_TXCDE',
                          'SEQ NO: '||TO_CHAR(L_seq_no_tmp));
         close C_EXISTS;
         O_seq_no := L_seq_no_tmp;
         return TRUE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXISTS',
                       'GEOCODE_TXCDE',
                       'SEQ NO: '||TO_CHAR(L_seq_no_tmp));
      close C_EXISTS;
      ---
      if L_first_one is NULL then
         ---
         L_first_one := L_seq_no_tmp;
         ---
      else
         ---
         if L_first_one = L_seq_no_tmp then
            ---
            O_error_message := SQL_LIB.CREATE_MSG('ERR_RETRIEVE_SEQ',
                                                   NULL,
                                                   NULL,
                                                   NULL);
            return FALSE;
            ---
         end if;
         ---
      end if;
      ---
   END LOOP;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END NEXT_GEOCODE_TXCDE;
----------------------------------------------------------
FUNCTION GEOCODE_TAX_CODE_EXISTS(O_error_message        IN OUT   VARCHAR2,
                                 O_exists               IN OUT   VARCHAR2,
                                 O_start_date           IN OUT   GEOCODE_TXCDE.START_DATE%TYPE,
                                 I_orig_start_date      IN       GEOCODE_TXCDE.START_DATE%TYPE,
                                 O_end_date             IN OUT   GEOCODE_TXCDE.START_DATE%TYPE,
                                 I_orig_end_date        IN       GEOCODE_TXCDE.START_DATE%TYPE,
                                 I_country_id           IN       GEOCODE_TXCDE.COUNTRY_GEOCODE_ID%TYPE,
                                 I_state_id             IN       GEOCODE_TXCDE.STATE_GEOCODE_ID%TYPE,
                                 I_county_id            IN       GEOCODE_TXCDE.COUNTY_GEOCODE_ID%TYPE,
                                 I_city_id              IN       GEOCODE_TXCDE.CITY_GEOCODE_ID%TYPE,
                                 I_dist_id              IN       GEOCODE_TXCDE.DISTRICT_GEOCODE_ID%TYPE,
                                 I_tax_jurisdiction_id  IN       GEOCODE_TXCDE.TAX_JURISDICTION_ID%TYPE,
                                 I_tax_type_id          IN       GEOCODE_TXCDE.TAX_TYPE_ID%TYPE)
   RETURN BOOLEAN is
   ---
   L_program       VARCHAR2(64)    := 'GEOCODE_SQL.GEOCODE_TAX_CODE_EXISTS';
   L_table         VARCHAR2(64)    := 'GEOCODE_TXCDE';
   L_start_date    GEOCODE_TXCDE.START_DATE%TYPE;
   L_end_date      GEOCODE_TXCDE.START_DATE%TYPE;
                                 ---

 cursor C_COUNTRY_TAX_CODE_EXISTS is
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and (start_date >= O_start_date
             or end_date is NULL
             or (start_date <= O_start_date
                 and end_date >= O_start_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      is NULL
         and county_geocode_id     is NULL
         and city_geocode_id       is NULL
         and district_geocode_id   is NULL
         and O_end_date is NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and end_date is NULL
         and (start_date <= O_start_date
            or start_date <= O_end_date)
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      is NULL
         and county_geocode_id     is NULL
         and city_geocode_id       is NULL
         and district_geocode_id   is NULL
         and O_end_date is NOT NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and ((start_date <= O_start_date
               and end_date >= O_start_date)
           or (start_date <= O_end_date
               and end_date >= O_end_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and end_date != nvl(I_orig_end_date, end_date -1)
         and end_date is NOT NULL
         and country_geocode_id    = I_country_id
         and state_geocode_id      is NULL
         and county_geocode_id     is NULL
         and city_geocode_id       is NULL
         and district_geocode_id   is NULL
         and O_end_date is NOT NULL;

 cursor C_STATE_TAX_CODE_EXISTS is
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and (start_date >= O_start_date
             or end_date is NULL
             or (start_date <= O_start_date
                 and end_date >= O_start_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     is NULL
         and city_geocode_id       is NULL
         and district_geocode_id   is NULL
         and O_end_date is NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and end_date is NULL
         and (start_date <= O_start_date
            or start_date <= O_end_date)
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     is NULL
         and city_geocode_id     is NULL
         and district_geocode_id   is NULL
         and O_end_date is NOT NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and ((start_date <= O_start_date
               and end_date >= O_start_date)
           or (start_date <= nvl(O_end_date, start_date -1)
               and end_date >= O_end_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and end_date != nvl(I_orig_end_date, end_date -1)
         and end_date is NOT NULL
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     is NULL
         and city_geocode_id	     is NULL
         and district_geocode_id   is NULL
         and O_end_date is NOT NULL;


 cursor C_COUNTY_TAX_CODE_EXISTS is
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
          and (start_date >= O_start_date
             or end_date is NULL
             or (start_date <= O_start_date
                 and end_date >= O_start_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       is NULL
         and district_geocode_id   is NULL
         and O_end_date is NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and end_date is NULL
         and (start_date <= O_start_date
            or start_date <= O_end_date)
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       is NULL
         and district_geocode_id   is NULL
         and O_end_date is NOT NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and ((start_date <= O_start_date
               and end_date >= O_start_date)
           or (start_date <= nvl(O_end_date, start_date -1)
               and end_date >= O_end_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and end_date != nvl(I_orig_end_date, end_date -1)
         and end_date is NOT NULL
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       is NULL
         and district_geocode_id   is NULL
         and O_end_date is NOT NULL;




 cursor C_CITY_TAX_CODE_EXISTS is
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and (start_date >= O_start_date
             or end_date is NULL
             or (start_date <= O_start_date
                 and end_date >= O_start_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       = I_city_id
         and district_geocode_id   is NULL
         and O_end_date is NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and end_date is NULL
         and (start_date <= O_start_date
            or start_date <= O_end_date)
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       = I_city_id
         and district_geocode_id   is NULL
         and O_end_date is NOT NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and ((start_date <= O_start_date
               and end_date >= O_start_date)
           or (start_date <= nvl(O_end_date, start_date -1)
               and end_date >= O_end_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and end_date != nvl(I_orig_end_date, end_date -1)
         and end_date is NOT NULL
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       = I_city_id
         and district_geocode_id   is NULL
         and O_end_date is NOT NULL;


 cursor C_DISTRICT_TAX_CODE_EXISTS is
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and (start_date >= O_start_date
             or end_date is NULL
             or (start_date <= O_start_date
                 and end_date >= O_start_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       = I_city_id
         and district_geocode_id   = I_dist_id
         and O_end_date is NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and end_date is NULL
         and (start_date <= O_start_date
            or start_date <= O_end_date)
         and start_date != nvl(I_orig_start_date, start_date -1)
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       = I_city_id
         and district_geocode_id   = I_dist_id
         and O_end_date is NOT NULL
    UNION ALL
     select  start_date,
             end_date
        from geocode_txcde
       where tax_jurisdiction_id   = I_tax_jurisdiction_id
         and tax_type_id           = I_tax_type_id
         and ((start_date <= O_start_date
               and end_date >= O_start_date)
           or (start_date <= nvl(O_end_date, start_date -1)
               and end_date >= O_end_date))
         and start_date != nvl(I_orig_start_date, start_date -1)
         and end_date != nvl(I_orig_end_date, end_date -1)
         and end_date is NOT NULL
         and country_geocode_id    = I_country_id
         and state_geocode_id      = I_state_id
         and county_geocode_id     = I_county_id
         and city_geocode_id       = I_city_id
         and district_geocode_id   = I_dist_id
         and O_end_date is NOT NULL;

BEGIN

   if I_dist_id is NOT NULL then

      SQL_LIB.SET_MARK('OPEN','C_DISTRICT_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      open C_DISTRICT_TAX_CODE_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_DISTRICT_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      fetch C_DISTRICT_TAX_CODE_EXISTS into L_start_date, L_end_date;
      if C_DISTRICT_TAX_CODE_EXISTS%NOTFOUND then
         O_exists :='N';
      else
         O_exists     := 'Y';
         O_start_date :=  L_start_date;
         O_end_date   :=  L_end_date;

      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_DISTRICT_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      close C_DISTRICT_TAX_CODE_EXISTS;

   elsif I_city_id is NOT NULL then


      SQL_LIB.SET_MARK('OPEN','C_CITY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      open C_CITY_TAX_CODE_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_CITY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      fetch C_CITY_TAX_CODE_EXISTS into L_start_date, L_end_date;
      if C_CITY_TAX_CODE_EXISTS%NOTFOUND then
         O_exists :='N';
      else
         O_exists     := 'Y';
         O_start_date :=  L_start_date;
         O_end_date   :=  L_end_date;

      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CITY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      close C_CITY_TAX_CODE_EXISTS;

   elsif I_county_id is not NULL then


      SQL_LIB.SET_MARK('OPEN','C_COUNTY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      open C_COUNTY_TAX_CODE_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_COUNTY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      fetch C_COUNTY_TAX_CODE_EXISTS into L_start_date, L_end_date;
      if C_COUNTY_TAX_CODE_EXISTS%NOTFOUND then
         O_exists :='N';
      else
         O_exists     := 'Y';
         O_start_date :=  L_start_date;
         O_end_date   :=  L_end_date;

      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_COUNTY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      close C_COUNTY_TAX_CODE_EXISTS;

   elsif I_state_id is not NULL then

      SQL_LIB.SET_MARK('OPEN','C_STATE_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      open C_STATE_TAX_CODE_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_STATE_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      fetch C_STATE_TAX_CODE_EXISTS into L_start_date, L_end_date;
      if C_STATE_TAX_CODE_EXISTS%NOTFOUND then
         O_exists :='N';
      else
         O_exists     := 'Y';
         O_start_date :=  L_start_date;
         O_end_date   :=  L_end_date;

      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_STATE_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      close C_STATE_TAX_CODE_EXISTS;

   else

      SQL_LIB.SET_MARK('OPEN','C_COUNTRY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      open C_COUNTRY_TAX_CODE_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_COUNTRY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      fetch C_COUNTRY_TAX_CODE_EXISTS into L_start_date, L_end_date;
      if C_COUNTRY_TAX_CODE_EXISTS%NOTFOUND then
         O_exists :='N';
      else
         O_exists     := 'Y';
         O_start_date :=  L_start_date;
         O_end_date   :=  L_end_date;

      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_COUNTRY_TAX_CODE_EXISTS',L_table,'TAX TYPE:'||I_tax_type_id);
      close C_COUNTRY_TAX_CODE_EXISTS;

   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GEOCODE_TAX_CODE_EXISTS;
---------------------------------------------------------------------------------------
FUNCTION LOCK_PROD_TAX_CODE(O_error_message    IN OUT    VARCHAR2,
                            I_item             IN        PRODUCT_TAX_CODE.ITEM%TYPE,
                            I_type             IN        VARCHAR2)


   RETURN BOOLEAN is
   ---
   L_program            VARCHAR2(64) := 'GEOCODE_SQL.LOCK_PROD_TAX_CODE';
   L_type_desc          CODE_DETAIL.CODE_DESC%TYPE := NULL;
   L_code_type          CODE_HEAD.CODE_TYPE%TYPE := 'TXHD';
   ---
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   ---

   cursor C_PRODUCT_TAX_ITEMLIST_LOCK is
      select 'X'
        from product_tax_code pc,
             skulist_detail sd
       where pc.item = sd.item
         and sd.skulist = I_item
      for update nowait;

   cursor C_PRODUCT_TAX_DEPT_LOCK is
      select 'X'
        from product_tax_code
       where dept = I_item
      for update nowait;

   cursor C_PRODUCT_TAX_ITEM_LOCK is
      select 'X'
        from product_tax_code
       where item = I_item
      for update nowait;

   ---
BEGIN
      if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                    L_code_type,
                                    I_type,
                                    L_type_desc) = FALSE then
         return FALSE;
      end if;

      if I_type = 'L' then
         SQL_LIB.SET_MARK('OPEN','C_PRODUCT_TAX_ITEM_LIST_LOCK','PRODUCT_TAX_CODE','ITEMLIST: '||I_item);
         open C_PRODUCT_TAX_ITEMLIST_LOCK;
         SQL_LIB.SET_MARK('CLOSE','C_PRODUCT_TAX_ITEM_LIST_LOCK','PRODUCT_TAX_CODE','ITEMLIST: '||I_item);
         close C_PRODUCT_TAX_ITEMLIST_LOCK;

     elsif I_type = 'D' then
         SQL_LIB.SET_MARK('OPEN','C_PRODUCT_TAX_DEPT_LOCK','PRODUCT_TAX_CODE','DEPT: '||I_item);
         open C_PRODUCT_TAX_DEPT_LOCK;
         SQL_LIB.SET_MARK('CLOSE','C_PRODUCT_TAX_DEPT_LOCK','PRODUCT_TAX_CODE','DEPT: '||I_item);
         close C_PRODUCT_TAX_DEPT_LOCK;
     else
         SQL_LIB.SET_MARK('OPEN','C_PRODUCT_TAX_ITEM_LOCK','PRODUCT_TAX_CODE','ITEM: '||I_item);
         open C_PRODUCT_TAX_ITEM_LOCK;
         SQL_LIB.SET_MARK('CLOSE','C_PRODUCT_TAX_ITEM_LOCK','PRODUCT_TAX_CODE','ITEM: '||I_item);
         close C_PRODUCT_TAX_ITEM_LOCK;

     end if;

   RETURN TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('LOCK_PROD_TAX_CODE',
                                            L_type_desc,
                                            I_item,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;

END LOCK_PROD_TAX_CODE;
-----------------------------------------------------------------------------------------------
FUNCTION GET_TAX_RATES(O_error_message    IN OUT VARCHAR2,
                       O_total            IN OUT TAX_RATES.TAX_RATE%TYPE,
                       I_country          IN     COUNTRY_GEOCODES.COUNTRY_GEOCODE_ID%TYPE,
                       I_state            IN     STATE_GEOCODES.STATE_GEOCODE_ID%TYPE,
                       I_county           IN     COUNTY_GEOCODES.COUNTY_GEOCODE_ID%TYPE,
                       I_city             IN     CITY_GEOCODES.CITY_GEOCODE_ID%TYPE,
                       I_dist             IN     DISTRICT_GEOCODES.DISTRICT_GEOCODE_ID%TYPE,
                       I_type             IN     VARCHAR2,
                       I_item             IN     ITEM_MASTER.ITEM%TYPE,
                       I_item_list        IN     SKULIST_HEAD.SKULIST%TYPE,
                       I_dept             IN     DEPS.DEPT%TYPE)

     RETURN BOOLEAN IS
--
  L_program                 VARCHAR2(64) := 'GEOCODE_SQL.GET_TAX_RATES';
  L_vdate                   PERIOD.VDATE%TYPE  := GET_VDATE;
  L_tax_jurisdiction_id     TAX_JURISDICTIONS.TAX_JURISDICTION_ID%TYPE;
  L_tax_type_id             CODE_DETAIL.CODE%TYPE;
  L_tax_type_desc           CODE_DETAIL.CODE_DESC%TYPE;
  L_tax_level_id            CODE_DETAIL.CODE%TYPE;
  L_tax_level_desc          CODE_DETAIL.CODE_DESC%TYPE;
  L_item                    ITEM_MASTER.ITEM%TYPE;
  L_jurisdiction_desc       TAX_JURISDICTIONS.TAX_JURISDICTION_DESC%TYPE;
  L_rate                    TAX_RATES.TAX_RATE%TYPE;
  ---
  cursor C_GET_TXCDE is
     select tax_jurisdiction_id,
            tax_type_id
       from geocode_txcde
      where (geocode_level = 'DIST'    and  district_geocode_id = nvl(I_dist,'0')
                                       and  city_geocode_id     = nvl(I_city,'0')
                                       and  county_geocode_id   = nvl(I_county,'0')
                                       and  state_geocode_id    = nvl(I_state,'0')
                                       and  country_geocode_id  = I_country
                                       and  start_date <= L_vdate
                                       and  nvl(end_date,L_vdate) >= L_vdate)
                                    OR (geocode_level = 'CITY'    and  city_geocode_id     = nvl(I_city,'0')
                                       and  county_geocode_id   = nvl(I_county,'0')
                                       and  state_geocode_id    = nvl(I_state,'0')
                                       and  country_geocode_id  = I_country
                                       and  start_date <= L_vdate
                                       and  nvl(end_date,L_vdate) >= L_vdate)
                                    OR (geocode_level = 'COUNTY'  and  county_geocode_id   = nvl(I_county,'0')
                                       and  state_geocode_id    = nvl(I_state,'0')
                                       and  country_geocode_id  = I_country
                                       and  start_date <= L_vdate
                                       and  nvl(end_date,L_vdate) >= L_vdate)
                                    OR (geocode_level = 'STATE'   and  state_geocode_id    = nvl(I_state,'0')
                                       and  country_geocode_id  = I_country
                                       and  start_date <= L_vdate
                                       and  nvl(end_date,L_vdate) >= L_vdate)
                                    OR (geocode_level = 'CNTRY'   and (country_geocode_id  = I_country
                                       and  start_date <= L_vdate
                                       and  nvl(end_date,L_vdate) >= L_vdate));
  ---
  cursor C_GET_PRODUCT_TAX_CODE is
     select tax_jurisdiction_id
       from product_tax_code
      where item = L_item
        and tax_jurisdiction_id = L_tax_jurisdiction_id
        and tax_type_id = L_tax_type_id
        and start_date <= L_vdate
        and nvl(end_date, L_vdate) >= L_vdate
        and I_type != 'D'
     UNION ALL
     select tax_jurisdiction_id
       from product_tax_code
      where dept = I_dept
        and tax_jurisdiction_id = L_tax_jurisdiction_id
        and tax_type_id = L_tax_type_id
        and start_date <= L_vdate
        and nvl(end_date, L_vdate) >= L_vdate
        and I_type = 'D';
  ---
  cursor C_GET_TAX_RATE is
     select tax_rate
       from tax_rates
      where tax_jurisdiction_id = L_tax_jurisdiction_id
        and tax_type_id = L_tax_type_id
        and start_date <= L_vdate
        and nvl(end_date, L_vdate) >= L_vdate;
  ---
  cursor C_GET_JURIS_DESC is
     select tax_level_id,
            tax_jurisdiction_desc
       from tax_jurisdictions
      where tax_jurisdiction_id = L_tax_jurisdiction_id;
  ---
  cursor C_GET_REP_ITEM is
     select item
       from skulist_detail
      where skulist = I_item_list;
  ---
BEGIN
  O_total := 0;
  ---
   SQL_LIB.SET_MARK('DELETE',NULL,'TAX_CODE_TEMP',NULL);
   delete from TAX_CODE_TEMP;
  ---
   if I_type = 'L' then
      SQL_LIB.SET_MARK('OPEN','C_GET_REP_ITEM','SKULIST_DETAIL','SKULIST: '||I_item_list);
      open  C_GET_REP_ITEM;
      SQL_LIB.SET_MARK('FETCH','C_GET_REP_ITEM','SKULIST_DETAIL','SKULIST: '||I_item_list);
      fetch C_GET_REP_ITEM into L_item;
      SQL_LIB.SET_MARK('CLOSE','C_GET_REP_ITEM','SKULIST_DETAIL','SKULIST: '||I_item_list);
      close C_GET_REP_ITEM;
   else
      L_item := I_item;
   end if;
   ----
   SQL_LIB.SET_MARK('OPEN','C_GET_TXCDE','GEOCODE_TXCDE','COUNTRY: '||I_country||
                                                          ' STATE: '||I_state||
                                                         ' COUNTY: '||I_county||
                                                           ' CITY: '||I_city||
                                                           ' DIST: '||I_dist);
   FOR c_rec in C_GET_TXCDE LOOP
      L_tax_jurisdiction_id := c_rec.tax_jurisdiction_id;
      L_tax_type_id    := c_rec.tax_type_id;
      ---
          SQL_LIB.SET_MARK('OPEN','C_GET_PRODUCT_TAX_CODE','PRODUCT_TAX_CODE','ITEM: '||I_item||' DEPT: '||I_dept);
      open  C_GET_PRODUCT_TAX_CODE;
          SQL_LIB.SET_MARK('FETCH','C_GET_PRODUCT_TAX_CODE','PRODUCT_TAX_CODE','ITEM: '||I_item||' DEPT: '||I_dept);
      fetch C_GET_PRODUCT_TAX_CODE into L_tax_jurisdiction_id;
      ---
         if C_GET_PRODUCT_TAX_CODE%FOUND then
                SQL_LIB.SET_MARK('CLOSE','C_GET_PRODUCT_TAX_CODE','PRODUCT_TAX_CODE','ITEM: '||I_item||' DEPT: '||I_dept);
            close C_GET_PRODUCT_TAX_CODE;
            ---
                SQL_LIB.SET_MARK('OPEN','C_GET_JURIS_DESC','TAX_JURISDICTIONS','TAX JURISDICTION ID'||L_tax_jurisdiction_id);
            open  C_GET_JURIS_DESC;
                SQL_LIB.SET_MARK('FETCH','C_GET_JURIS_DESC','TAX_JURISDICTIONS','TAX JURISDICTION ID'||L_tax_jurisdiction_id);
                fetch C_GET_JURIS_DESC into L_tax_level_id,
                                            L_jurisdiction_desc;
                SQL_LIB.SET_MARK('CLOSE','C_GET_JURIS_DESC','TAX_JURISDICTIONS','TAX JURISDICTION ID'||L_tax_jurisdiction_id);
                close C_GET_JURIS_DESC;
            ---
            if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                          'TXLV',
                                          L_tax_level_id,
                                          L_tax_level_desc) = FALSE then
               return FALSE;
            end if;
            ---
            if LANGUAGE_SQL.GET_CODE_DESC(O_error_message,
                                          'TXTY',
                                          L_tax_type_id,
                                          L_tax_type_desc) = FALSE then
               return FALSE;
            end if;
              ---
            if LANGUAGE_SQL.TRANSLATE(L_jurisdiction_desc,
                                          L_jurisdiction_desc,
                                          O_error_message) = FALSE then
               return FALSE;
            end if;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_TAX_RATE','TAX_RATES','TAX TYPE ID'||L_tax_type_id);
            open  C_GET_TAX_RATE;
            SQL_LIB.SET_MARK('FETCH','C_GET_TAX_RATE','TAX_RATES','TAX TYPE ID'||L_tax_type_id);
            fetch C_GET_TAX_RATE into L_rate;
            if C_GET_TAX_RATE%NOTFOUND then
               L_rate := 0;
            end if;
            O_total := (O_total + L_rate);
            SQL_LIB.SET_MARK('CLOSE','C_GET_TAX_RATE','TAX_RATES','TAX TYPE ID'||L_tax_type_id);
            close C_GET_TAX_RATE;
                ---
            if L_tax_jurisdiction_id is NOT NULL then
                 SQL_LIB.SET_MARK('INSERT',NULL,'TAX_CODE_TEMP',NULL);
               insert into TAX_CODE_TEMP(tax_jurisdiction_id,
                                         tax_jurisdiction_desc,
                                         tax_level_desc,
                                         tax_type_desc,
                                         tax_rate)
                                  values (L_tax_jurisdiction_id,
                                          L_jurisdiction_desc,
                                          L_tax_level_desc,
                                          L_tax_type_desc,
                                          L_rate);
            end if;
                ---
         else
            SQL_LIB.SET_MARK('CLOSE','C_GET_PRODUCT_TAX_CODE','PRODUCT_TAX_CODE','ITEM: '||I_item||' DEPT: '||I_dept);
            close C_GET_PRODUCT_TAX_CODE;
         end if;
        ---
   END LOOP;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
---
END GET_TAX_RATES;
----------------------------------------------------------
FUNCTION LOCK_GEOCODE(O_error_message    IN OUT    VARCHAR2,
                      O_lock_ind         IN OUT    BOOLEAN)


   RETURN BOOLEAN is
   ---
   L_program            VARCHAR2(64) := 'GEOCODE_SQL.LOCK_GEOCODE_TXCDE';
   ---
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_GEOCODE_COUNRTY_LOCK is
      select 'X'
        from country_geocodes
      for update nowait;


   cursor C_GEOCODE_STATE_LOCK is
      select 'X'
        from state_geocodes
      for update nowait;


   cursor C_GEOCODE_COUNTY_LOCK is
      select 'X'
        from county_geocodes
      for update nowait;

   cursor C_GEOCODE_CITY_LOCK is
      select 'X'
        from city_geocodes
      for update nowait;

   cursor C_GEOCODE_DISTRICT_LOCK is
      select 'X'
        from district_geocodes
      for update nowait;

   ---
BEGIN

   SQL_LIB.SET_MARK('OPEN','C_GEOCODE_COUNTRY_LOCK','GEOCODE_STORE',' ');
   open C_GEOCODE_COUNRTY_LOCK;
   SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_COUNTRY_LOCK','GEOCODE_STORE',' ');

   close C_GEOCODE_COUNRTY_LOCK;

   SQL_LIB.SET_MARK('OPEN','C_GEOCODE_STATE_LOCK','GEOCODE_STORE',' ');

   open C_GEOCODE_STATE_LOCK;
   SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_STATE_LOCK','GEOCODE_STORE',' ');
   close C_GEOCODE_STATE_LOCK;
   SQL_LIB.SET_MARK('OPEN','C_GEOCODE_COUNTY_LOCK','GEOCODE_STORE',' ');

   open C_GEOCODE_COUNTY_LOCK;
   SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_COUNTY_LOCK','GEOCODE_STORE',' ');

   close C_GEOCODE_COUNTY_LOCK;

   SQL_LIB.SET_MARK('OPEN','C_GEOCODE_CITY_LOCK','GEOCODE_STORE',' ');

   open C_GEOCODE_CITY_LOCK;
   SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_CITY_LOCK','GEOCODE_STORE',' ');

   close C_GEOCODE_CITY_LOCK;
    SQL_LIB.SET_MARK('OPEN','C_GEOCODE_DISTRICT_LOCK','GEOCODE_STORE',' ');

   open C_GEOCODE_DISTRICT_LOCK;
   SQL_LIB.SET_MARK('CLOSE','C_GEOCODE_DISTRICT_LOCK','GEOCODE_STORE',' ');
   close C_GEOCODE_DISTRICT_LOCK;

   O_lock_ind := TRUE;

   RETURN TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('GEOCODE_TAXCODE_REC_LOCK',
                                            NULL,
                                            NULL,
                                            NULL);

      O_lock_ind := FALSE;
      return TRUE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;

END LOCK_GEOCODE;
----------------------------------------------------------

------------
END GEOCODE_SQL;
/

