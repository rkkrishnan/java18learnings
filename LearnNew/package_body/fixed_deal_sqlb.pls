CREATE OR REPLACE PACKAGE BODY FIXED_DEAL_SQL AS

RECORD_LOCKED   EXCEPTION;
PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

----------------------------------------------------------------------------------------
--Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
--Mod Date     : 10-Aug-2010
--Mod Ref      : CR340
--Mod Details  : Added Two New Functions TSL_UPDATE_FIXED_DEAL and TSL_GET_FIXED_DEAL.
---------------------------------------------------------------------------------------
--Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
--Mod Date     : 24-Nov-2010
--Mod Ref      : MrgNBS019839(3.5btoPrdSi)
--Mod Details  : Merged CR340
---------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 12-Mar-2011
-- Mod Ref    : CR378a
-- Mod Details: Added three new functions TSL_CHECK_INVOICED_IND,TSL_CHECK_PAID_IND,
--              TSL_CHECK_VALID_STATUS_CHANGE
---------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 10-Aug-2011
-- Mod Ref    : CR378b
-- Mod Details: Added four new functions 'TSL_CHECK_INV_IND_SEARCH','TSL_CHECK_INV_IND_SEARCH',
--              TSL_GET_INV_INFO, TSL_GET_DEAL_COMMENTS,TSL_GET_CODE.Modified function
--              TSL_CHECK_VALID_STATUS_CHANGE
-------------------------------------------------------------------------------------------
-- Mod By     : Chithraprabha, chitraprabha.vadakkedath@in.tesco.com
-- Mod Date   : 09-july-2011
-- Mod Ref    : CR378b
-- Mod Details: 'INS_TSL_FIX_DEAL_TMP_GTT' function to insert deal to the temporary table
-------------------------------------------------------------------------------------------
--Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
--Mod Date     : 02-Nov-2011
--Mod Ref      : NBS00023874
--Mod Details  : Modified TSL_GET_INV_INFO.
-------------------------------------------------------------------------------------------
--Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
--Mod Date     : 29-Nov-2011
--Mod Ref      : NBS00023994
--Mod Details  : Modified TSL_GET_FIXED_DEAL for error message format.
-------------------------------------------------------------------------------------------
--Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
--Mod Date     : 28-Dec-2011
--Mod Ref      : NBS00024082(in DefNBS024097 branch,modified query and checked in DefNBS024082c)
--Mod Details  : Modified TSL_GET_INV_INFO to include country field in fetch and modified
--               record type INVOICE_REC.
-------------------------------------------------------------------------------------------
--Mod By       : Raghavendra S, Raghavendra.Shivaswamy@in.tesco.com
--Mod Date     : 16-Feb-2015
--Mod Ref      : PM036413 fix
--Mod Details  : Modified TSL_CHECK_VALID_STATUS_CHANGE  function to fetch the value from cursor C_OLD_VALUE only when
--               I_start_date < L_vdate.
-------------------------------------------------------------------------------------------

FUNCTION CHECK_DATES (I_deal_number   IN   NUMBER,
                      I_before_date   IN   DATE,
                      I_after_date    IN   DATE)
RETURN NUMBER IS


   L_dates_passed    BOOLEAN := FALSE;
   L_before_passed   BOOLEAN := FALSE;
   L_date_exist      VARCHAR2(1);

   CURSOR C_DEAL_AFTER IS
      SELECT 'x'
        FROM fixed_deal_dates
       WHERE deal_no      = I_deal_number
         AND collect_date >= I_after_date;

   CURSOR C_DEAL_BEFORE IS
      SELECT 'x'
        FROM fixed_deal_dates
       WHERE deal_no      = I_deal_number
         AND collect_date <= I_before_date;

   CURSOR C_DEAL_BOTH IS
      SELECT 'x'
        FROM fixed_deal_dates
       WHERE deal_no      = I_deal_number
         AND collect_date >= I_after_date
         AND collect_date <= I_before_date;


BEGIN

   if I_before_date is NULL then
      if I_after_date is NULL then
         --
         --- Both null, return true
         --
         return 1;
      else
         --
         --- After selection only
         --
         open C_DEAL_AFTER;

         fetch C_DEAL_AFTER into L_date_exist;

         if (C_DEAL_AFTER%notfound) THEN
             close C_DEAL_AFTER;
             return 0;
         end if;

         close C_DEAL_AFTER;

      end if;     -- if after date is NULL
   else           -- if before date is NULL

      if I_after_date is NULL then
         --
         --- Before date only
         --
         open C_DEAL_BEFORE;

         fetch C_DEAL_BEFORE into L_date_exist;

         if (C_DEAL_BEFORE%notfound) THEN
             close C_DEAL_BEFORE;
             return 0;
         end if;

         close C_DEAL_BEFORE;
      else
         --
         --- Both dates were passed in
         --
         open C_DEAL_BOTH;

         fetch C_DEAL_BOTH into L_date_exist;

         if (C_DEAL_BOTH%notfound) THEN
             close C_DEAL_BOTH;
             return 0;
         end if;

         close C_DEAL_BOTH;
      end if;

   end if;        -- if before date is NULL

   return 1;

EXCEPTION
   when OTHERS then

      close C_DEAL_AFTER;
      close C_DEAL_BEFORE;
      close C_DEAL_BOTH;

   return 0;
END CHECK_DATES;
------------------------------------------------------------------------------

FUNCTION NEXT_DEAL_NUMBER( O_error_message   IN OUT   VARCHAR2,
                           O_deal_number     IN OUT   NUMBER)
RETURN BOOLEAN IS

   L_wrap_sequence_number   COMPETITOR.COMPETITOR%TYPE;
   L_first_time             VARCHAR2(3)       := 'Yes';
   L_counter                VARCHAR2(1);

   CURSOR c_deal_sequence IS
      SELECT deal_sequence.NEXTVAL seq_no
        FROM dual;

   CURSOR C_DEAL_EXISTS IS
      SELECT 'x'
        FROM fixed_deal
       WHERE deal_no = O_deal_number
    union
      SELECT 'x'
        FROM deal_head
       WHERE deal_id = O_deal_number;

BEGIN

   FOR rec IN c_deal_sequence LOOP

      O_deal_number := rec.seq_no;

      if (L_first_time = 'Yes') THEN
         L_wrap_sequence_number := O_deal_number;
         L_first_time := 'No';
      elsif (O_deal_number = L_wrap_sequence_number) THEN
         O_error_message:= sql_lib.create_msg('NO_DEAL_NUMBERS',
                                                 NULL,NULL,NULL);
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('OPEN', 'C_DEAL_EXISTS', 'FIXED_DEAL',
                       'DEAL_NO: '|| to_char(O_deal_number));
      open C_DEAL_EXISTS;

      SQL_LIB.SET_MARK('FETCH', 'C_DEAL_EXISTS', 'FIXED_DEAL',
                       'DEAL_NO: '|| to_char(O_deal_number));
      fetch C_DEAL_EXISTS into L_counter;

      if (C_DEAL_EXISTS%notfound) THEN
         SQL_LIB.SET_MARK('CLOSE', 'C_DEAL_EXISTS', 'FIXED_DEAL',
                          'DEAL_NO: '|| to_char(O_deal_number));
         close C_DEAL_EXISTS;
         return TRUE;
      end if;

      SQL_LIB.SET_MARK('CLOSE', 'C_DEAL_EXISTS', 'FIXED_DEAL',
                       'DEAL_NO: '|| to_char(O_deal_number));
      close C_DEAL_EXISTS;

   END LOOP;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'FIXED_DEAL_SQL.NEXT_DEAL_NUMBER',
                                             to_char(SQLCODE));
   return FALSE;
END NEXT_DEAL_NUMBER;

------------------------------------------------------------------------------

FUNCTION GET_DEAL_DESC(O_error_message   IN OUT   VARCHAR2,
                       O_deal_desc       IN OUT   FIXED_DEAL.DEAL_DESC%TYPE,
                       I_deal_no         IN       FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   cursor C_DEAL_DESC is
      select deal_desc
        from fixed_deal
       where deal_no = I_deal_no;

BEGIN

   if I_deal_no is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM', 'I_deal_no',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_DEAL_DESC','FIXED_DEAL',
                    'DEAL_NO: '|| I_deal_no);
   open C_DEAL_DESC;

   SQL_LIB.SET_MARK('FETCH','C_DEAL_DESC','FIXED_DEAL',
                    'DEAL_NO: '|| I_deal_no);
   fetch C_DEAL_DESC into O_deal_desc;

   if C_DEAL_DESC%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_DEAL_DESC','FIXED_DEAL',
                    'DEAL_NO: '|| I_deal_no);
      close C_DEAL_DESC;
      ---
      if LANGUAGE_SQL.TRANSLATE(O_deal_desc,
                                O_deal_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   else
      SQL_LIB.SET_MARK('CLOSE','C_DEAL_DESC','FIXED_DEAL',
                    'DEAL_NO: '|| I_deal_no);
      close C_DEAL_DESC;
      ---
      O_error_message:= sql_lib.create_msg('INV_DEAL',
                                           to_char(I_deal_no),
                                           NULL,NULL);
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'FIXED_DEAL_SQL.GET_DEAL_DESC',
                                             to_char(SQLCODE));
   RETURN FALSE;
END GET_DEAL_DESC;

------------------------------------------------------------------------------

FUNCTION INSERT_PERIOD(O_error_message   IN OUT   VARCHAR2,
                       I_deal_no         IN       FIXED_DEAL_DATES.DEAL_NO%TYPE,
                       I_start_date      IN       FIXED_DEAL_DATES.COLLECT_DATE%TYPE,
                       I_deal_amt        IN       FIXED_DEAL_DATES.FIXED_DEAL_AMT%TYPE,
                       I_periods         IN       FIXED_DEAL.COLLECT_PERIODS%TYPE,
                       I_increment       IN       FIXED_DEAL.COLLECT_PERIODS%TYPE)
RETURN BOOLEAN IS

   L_counter  FIXED_DEAL.COLLECT_PERIODS%TYPE := 0;

BEGIN

   LOOP

      SQL_LIB.SET_MARK('INSERT',NULL,'FIXED_DEAL_DATES','DEAL_NO: '||I_deal_no);
      insert into fixed_deal_dates (deal_no,
                                    collect_date,


                                     fixed_deal_amt)
                            values (I_deal_no,
                                    ADD_MONTHS(I_start_date, I_increment * L_counter),


                                    I_deal_amt);

      L_counter := L_counter + 1;

      if L_counter = I_periods then
         EXIT;
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'FIXED_DEAL_SQL.INSERT_PERIOD',
                                             to_char(SQLCODE));
   RETURN FALSE;
END INSERT_PERIOD;

------------------------------------------------------------------------------

FUNCTION CREATE_SCHEDULE(O_error_message   IN OUT   VARCHAR2,
                         I_deal_no         IN       FIXED_DEAL.DEAL_NO%TYPE,
                         I_start_date      IN       FIXED_DEAL.COLLECT_START_DATE%TYPE,
                         I_periods         IN       FIXED_DEAL.COLLECT_PERIODS%TYPE,
                         I_collect_by      IN       FIXED_DEAL.COLLECT_BY%TYPE,
                         I_deal_amt        IN       FIXED_DEAL.FIXED_DEAL_AMT%TYPE)
RETURN BOOLEAN IS

   cursor C_LOCK_FIXED_DEAL_DATES is
      select 'x'
        from fixed_deal_dates
       where deal_no = I_deal_no
         for update nowait;

BEGIN

   -- make sure input parameters are populated --
   if I_deal_no is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM', 'I_deal_no',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;
   if I_start_date is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM', 'I_start_date',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;
   if I_periods is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM', 'I_periods',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;
   if I_collect_by is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM', 'I_collect_by',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;
   if I_deal_amt is NULL then
      O_error_message:= sql_lib.create_msg('INVALID_PARM', 'I_deal_amt',
                                           'NULL', 'NOT NULL');
      return FALSE;
   end if;



   -- delete any existing fixed_deal_dates records --
   SQL_LIB.SET_MARK('OPEN','C_LOCK_FIXED_DEAL_DATES','FIXED_DEAL_DATES','DEAL_NO: '||I_deal_no);
   open  C_LOCK_FIXED_DEAL_DATES;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_FIXED_DEAL_DATES','FIXED_DEAL_DATES','DEAL_NO: '||I_deal_no);
   close C_LOCK_FIXED_DEAL_DATES;

   SQL_LIB.SET_MARK('DELETE',NULL,'FIXED_DEAL_DATES','DEAL_NO: '||I_deal_no);
   delete from fixed_deal_dates
    where deal_no = I_deal_no;

   -- insert new fixed_deal_dates records based on input parameters --
   if I_collect_by = 'D' or I_collect_by = 'M' then

      if not INSERT_PERIOD(O_error_message,
                           I_deal_no,
                           I_start_date,


                           I_deal_amt,
                           I_periods,
                           1) then            -- monthly or only once for 'D'ate collections
         return FALSE;
      end if;

   elsif I_collect_by = 'Q' then

      if not INSERT_PERIOD(O_error_message,
                           I_deal_no,
                           I_start_date,


                           I_deal_amt,
                           I_periods,
                           3) then            -- every three months or quarterly
         return FALSE;
      end if;

   elsif I_collect_by = 'A' then

      if not INSERT_PERIOD(O_error_message,
                           I_deal_no,
                           I_start_date,


                           I_deal_amt,
                           I_periods,
                           12) then           -- every twelve months or annually
         return FALSE;
      end if;

   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                          'FIXED_DEAL_DATES',
                                          I_deal_no);
      return FALSE;

   when OTHERS then
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'FIXED_DEAL_SQL.CREATE_SCHEDULE',
                                             to_char(SQLCODE));
   RETURN FALSE;
END CREATE_SCHEDULE;

------------------------------------------------------------------------------
FUNCTION CREATE_MERCH_LOC (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exists          IN OUT   VARCHAR2,
                           I_group_type      IN       FIXED_DEAL_MERCH_LOC.LOC_TYPE%TYPE,
                           I_group_value     IN       VARCHAR2,
                           I_deal_no         IN       FIXED_DEAL_MERCH_LOC.DEAL_NO%TYPE,
                           I_seq_no          IN       FIXED_DEAL_MERCH_LOC.SEQ_NO%TYPE,
                           I_contrib_ratio   IN       FIXED_DEAL_MERCH_LOC.CONTRIB_RATIO%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(32) := 'FIXED_DEAL_SQL.CREATE_MERCH_LOC';
   L_multichannel_ind   SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;
   L_exists             BOOLEAN;

   cursor C_STORE_CLASS is
      select store
        from v_store
       where store_class = I_group_value;

   cursor C_STORE_DISTRICT is
      select store
        from v_store
       where district = I_group_value;

   cursor C_SH_STORE_AREA is
      select store
        from store_hierarchy
       where area = I_group_value;

   cursor C_SH_STORE_REGION is
      select store
        from store_hierarchy
       where region = I_group_value;

   cursor C_LOC_LIST_DETAIL_LOCATION is
      select location
        from loc_list_detail l,
             v_wh v
       where l.location = v.wh
         and loc_type             = 'W'
         and loc_list             = I_group_value
         and ((L_multichannel_ind = 'Y' and stockholding_ind = 'Y') or
              (L_multichannel_ind = 'N' and stockholding_ind = 'Y'));

   cursor C_LOC_LIST_DETAIL_LOCATION_S is
      select location
        from loc_list_detail
       where loc_list = I_group_value
         and loc_type = 'S';

   cursor C_STORE_TRANSFER_ZONE is
      select store
        from v_store
       where transfer_zone = I_group_value;

   cursor C_LOC_TRAIT is
      select store
        from loc_traits_matrix
       where loc_trait = I_group_value;

   cursor C_PRIZE_ZONE_GROUP_STORE is
      select distinct store
        from price_zone_group_store
       where zone_id = I_group_value;

   cursor C_STORE_UNION_WH is
      select store loc,
             'S' loc_type
        from v_store
       union all
      select wh loc,
             'W' loc_type
        from v_wh
       where ((L_multichannel_ind = 'Y' and stockholding_ind = 'Y') or
              (L_multichannel_ind = 'N' and stockholding_ind = 'Y'));

   cursor C_STORE is
      select store
        from v_store;

   cursor C_WH is
      select wh
        from v_wh
       where ((L_multichannel_ind = 'Y' and stockholding_ind = 'Y') or
              (L_multichannel_ind = 'N' and stockholding_ind = 'Y'));

BEGIN

   ---
   if I_group_type is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_group_type',
                                           NULL,
                                           NULL);
      return FALSE;
   end if;
   ---
   if I_deal_no is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_deal_no',
                                           NULL,
                                           NULL);
      return FALSE;
   end if;
   ---
   if I_seq_no is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_seq_no',
                                           NULL,
                                           NULL);
      return FALSE;
   end if;
   ---
   if I_contrib_ratio is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_contrib_ratio',
                                           NULL,
                                           NULL);
      return FALSE;
   end if;
   ---
   if SYSTEM_OPTIONS_SQL.GET_MULTICHANNEL_IND(O_error_message,
                                              L_multichannel_ind) = FALSE then
      return FALSE;
   end if;
   ---
   O_exists := 'N';

   if I_group_type in ('S','W','E','PW','DW') then
      if FIXED_DEAL_SQL.MERCH_LOC_EXISTS (O_error_message,
                                          L_exists,
                                          I_deal_no,
                                          I_seq_no,
                                          I_group_value) = FALSE then
         return FALSE;
      end if;

      if L_exists then
         O_error_message := SQL_LIB.CREATE_MSG('LOC_EXISTS',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;
   end if;
   ---
   if I_group_type = 'S' or I_group_type = 'W' or I_group_type = 'E' then
      insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                        seq_no,
                                        loc_type,
                                        location,
                                        contrib_ratio)
                                values (I_deal_no,
                                        I_seq_no,
                                        I_group_type,
                                        I_group_value,
                                        I_contrib_ratio);

   elsif I_group_type = 'PW' or I_group_type = 'DW' then
      insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                        seq_no,
                                        loc_type,
                                        location,
                                        contrib_ratio)
                                values (I_deal_no,
                                        I_seq_no,
                                        'W',
                                        I_group_value,
                                        I_contrib_ratio);

   elsif I_group_type = 'C' then
      for c_store_class_rec in C_STORE_CLASS
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_store_class_rec.store,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'D' then
      for c_store_district_rec in C_STORE_DISTRICT
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_store_district_rec.store,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'A' then
      for c_sh_store_area_rec in C_SH_STORE_AREA
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_sh_store_area_rec.store,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'R' then
      for c_ch_store_region_rec in C_SH_STORE_REGION
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_ch_store_region_rec.store,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'LLW' then
      for c_loc_list_detail_location_rec in C_LOC_LIST_DETAIL_LOCATION
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'W',
                                              c_loc_list_detail_location_rec.location,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'LLS' then
      for c_loc_lt_detail_loc_s_rec in C_LOC_LIST_DETAIL_LOCATION_S
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_loc_lt_detail_loc_s_rec.location,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'T' then
      for c_store_transfer_zone_rec in C_STORE_TRANSFER_ZONE
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_store_transfer_zone_rec.store,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'L' then
      for c_loc_trait_rec in C_LOC_TRAIT
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_loc_trait_rec.store,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'Z' then
      for c_prize_zone_group_store_rec in C_PRIZE_ZONE_GROUP_STORE
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_prize_zone_group_store_rec.store,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'AL' then
      for c_store_union_wh_rec in C_STORE_UNION_WH
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              c_store_union_wh_rec.loc_type,
                                              c_store_union_wh_rec.loc,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'AS' then
      for c_store_rec in C_STORE
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'S',
                                              c_store_rec.store,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   elsif I_group_type = 'AW' then
      for c_wh_rec in C_WH
      LOOP
         BEGIN
            insert into FIXED_DEAL_MERCH_LOC (deal_no,
                                              seq_no,
                                              loc_type,
                                              location,
                                              contrib_ratio)
                                      values (I_deal_no,
                                              I_seq_no,
                                              'W',
                                              c_wh_rec.wh,
                                              I_contrib_ratio);
         EXCEPTION
            when DUP_VAL_ON_INDEX then
               O_exists := 'Y';
         END;
      END LOOP;

   else
      O_error_message := sql_lib.create_msg('INVALID_PARM',
                                            'I_group_type',
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                          'FIXED_DEAL_MERCH_LOC',
                                          I_deal_no);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CREATE_MERCH_LOC;

----------------------------------------------------------------------------------------------
FUNCTION MERCH_LOC_EXISTS (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exists          IN OUT   BOOLEAN,
                           I_deal_no         IN       FIXED_DEAL_MERCH_LOC.DEAL_NO%TYPE,
                           I_seq_no          IN       FIXED_DEAL_MERCH_LOC.SEQ_NO%TYPE,
                           I_location        IN       FIXED_DEAL_MERCH_LOC.LOCATION%TYPE)
RETURN BOOLEAN IS

   L_program  VARCHAR2(32) := 'FIXED_DEAL_SQL.MERCH_LOC_EXISTS';
   L_deal     FIXED_DEAL_MERCH_LOC.DEAL_NO%TYPE;

   cursor C_DEAL_MERCH_LOC (I_sequence_no IN FIXED_DEAL_MERCH_LOC.SEQ_NO%TYPE) is
      select distinct deal_no
        from fixed_deal_merch_loc
       where deal_no   = I_deal_no
         and seq_no    = I_sequence_no
         and (location is null or
              location = nvl(I_location,location));

   cursor C_DEAL is
      select seq_no
        from fixed_deal_merch
       where deal_no = I_deal_no;

BEGIN

   O_exists := TRUE;

   if I_deal_no is NULL then
      O_error_message:= sql_lib.create_msg('REQUIRED_INPUT_IS_NULL', 'I_deal_no',L_program, NULL);
      return FALSE;
   end if;

   if I_seq_no is NULL then

      FOR L_deal_rec IN C_DEAL LOOP

         SQL_LIB.SET_MARK('OPEN','C_DEAL_MERCH_LOC','fixed_deal_merch_loc','NULL');
         open C_DEAL_MERCH_LOC (L_deal_rec.seq_no);

         SQL_LIB.SET_MARK('FETCH','C_DEAL_MERCH_LOC', 'fixed_deal_merch_loc','NULL');
         fetch C_DEAL_MERCH_LOC into L_deal;

         if C_DEAL_MERCH_LOC%NOTFOUND then
            O_exists := FALSE;
            SQL_LIB.SET_MARK('CLOSE','C_DEAL_MERCH_LOC', 'fixed_deal_merch_loc','NULL');
            close C_DEAL_MERCH_LOC;
            EXIT;
         else
            SQL_LIB.SET_MARK('CLOSE','C_DEAL_MERCH_LOC', 'fixed_deal_merch_loc','NULL');
            close C_DEAL_MERCH_LOC;
         end if;


      END LOOP;

   else

      SQL_LIB.SET_MARK('OPEN','C_DEAL_MERCH_LOC','fixed_deal_merch_loc','NULL');
      open C_DEAL_MERCH_LOC (I_seq_no);

      SQL_LIB.SET_MARK('FETCH','C_DEAL_MERCH_LOC', 'fixed_deal_merch_loc','NULL');
      fetch C_DEAL_MERCH_LOC into L_deal;

      if C_DEAL_MERCH_LOC%NOTFOUND then
         O_exists := FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE','C_DEAL_MERCH_LOC', 'fixed_deal_merch_loc','NULL');
      close C_DEAL_MERCH_LOC;

   end if;


   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                          'FIXED_DEAL_MERCH_LOC',
                                          I_deal_no);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END MERCH_LOC_EXISTS;

----------------------------------------------------------------------------------------------

FUNCTION DELETE_RECORDS  (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          I_deal_no         IN       FIXED_DEAL_MERCH_LOC.DEAL_NO%TYPE,
                          I_seq_no          IN       FIXED_DEAL_MERCH_LOC.SEQ_NO%TYPE)
RETURN BOOLEAN IS

   cursor C_LOCK_FIXED_DEAL_MERCH_LOC is
      select 'x'
        from fixed_deal_merch_loc
       where deal_no = I_deal_no
         and seq_no  = nvl(I_seq_no,seq_no)
         for update nowait;

   cursor C_LOCK_FIXED_DEAL_MERCH is
      select 'x'
        from fixed_deal_merch
       where deal_no = I_deal_no
         and seq_no  = nvl(I_seq_no,seq_no)
         for update nowait;

   L_table   VARCHAR2(20);
   L_program VARCHAR2(30)  := 'FIXED_DEAL_SQL.DELETE_RECORDS';

BEGIN

   L_table := 'FIXED_DEAL_MERCH_LOC';

   open C_LOCK_FIXED_DEAL_MERCH_LOC;
   close C_LOCK_FIXED_DEAL_MERCH_LOC;

   L_table := 'FIXED_DEAL_MERCH';

   open C_LOCK_FIXED_DEAL_MERCH;
   close C_LOCK_FIXED_DEAL_MERCH;

   delete fixed_deal_merch_loc
    where deal_no = I_deal_no
      and seq_no = nvl(I_seq_no,seq_no);

   delete fixed_deal_merch
    where deal_no = I_deal_no
      and seq_no = nvl(I_seq_no,seq_no);

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('DELRECS_REC_LOC',
                                            L_table,
                                            I_deal_no);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END DELETE_RECORDS;
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- DefNBS019466   Tesco HSC/Manikandan            19-OCT-2010 -- Begin
-- Name:       DELETE_INV_RECORDS
-- Purpose:    This function will not allow to delete if the deal has invoiced
-----------------------------------------------------------------------------

FUNCTION DELETE_INV_RECORDS  (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_deal_no         IN       FIXED_DEAL_MERCH_LOC.DEAL_NO%TYPE,
                              I_check           IN OUT   VARCHAR2)
RETURN BOOLEAN IS


   L_program  VARCHAR2(64)  := 'ITEM_APPROVAL_SQL.APPROVAL_CHECK';

   cursor C_CHECK_INV_EXIST is
      select 'Y'
        from fixed_deal_dates fdd where
        fdd.deal_no = I_deal_no
        and fdd.extracted_ind = 'Y';


BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_INV_EXIST',
                    'fixed_deal_dates',
                    'NULL');

    Open C_CHECK_INV_EXIST;

    SQL_LIB.SET_MARK('FETCH',
                     'C_CHECK_INV_EXIST',
                     'fixed_deal_dates',
                     'NULL');



    FETCH C_CHECK_INV_EXIST INTO I_check;

    if C_CHECK_INV_EXIST%NOTFOUND then
      I_check := 'N';
    end if;

    SQL_LIB.SET_MARK('CLOSE',
                     'C_CHECK_INV_EXIST',
                     'dual',
                     'NULL');

    close C_CHECK_INV_EXIST;

    return TRUE;



EXCEPTION

     when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
     return FALSE;

END DELETE_INV_RECORDS;

---------------------------------------------------------------------------------------------
-- DefNBS019466   Tesco HSC/Manikandan            19-OCT-2010 -- End
----------------------------------------------------------------------------------------------

FUNCTION GET_SEQ_NO (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                     O_seq_id          IN OUT   FIXED_DEAL_MERCH.SEQ_NO%TYPE)
RETURN BOOLEAN IS

   L_first_time    VARCHAR2(1)                    := 'Y';
   L_wrap_seq_no   FIXED_DEAL_MERCH.SEQ_NO%TYPE;
   L_exists        VARCHAR2(1)                    := 'N' ;
   L_program       VARCHAR2(30)                   := 'FIXED_DEAL_SQL.GET_SEQ_NO';

   cursor C_SEQ_EXISTS is
      select 'Y'
        from fixed_deal_merch
       where seq_no = O_seq_id
         and rownum = 1;

   cursor C_SELECT_NEXTVAL is
      select fixed_deal_merch_id_seq.NEXTVAL
        from dual;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_select_nextval',
                    'dual',
                    'NULL');
   open C_SELECT_NEXTVAL;
   ---
   LOOP
      SQL_LIB.SET_MARK('FETCH',
                       'C_select_nextval',
                       'dual',
                       'NULL');
      fetch C_SELECT_NEXTVAL into O_seq_id;
      ---
      if L_first_time = 'Y' then
         L_wrap_seq_no   := O_seq_id;
         L_first_time    := 'N';
      elsif (O_seq_id = L_wrap_seq_no) then
         O_error_message := SQL_LIB.CREATE_MSG('NO_SEQ_NO',
                                               NULL,
                                               NULL,
                                               NULL);
         SQL_LIB.SET_MARK('CLOSE',
                          'C_select_nextval',
                          'dual',
                          'NULL');
         close C_SELECT_NEXTVAL;
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_seq_exists',
                       'dual',
                       'NULL');
      open C_SEQ_EXISTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_seq_exists',
                       'dual',
                       'NULL');
      fetch C_SEQ_EXISTS into L_exists;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_seq_exists',
                       'dual',
                       'NULL');
      close C_SEQ_EXISTS;
      ---
      if L_exists = 'N'  then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_select_nextval',
                          'dual',
                          NULL);
         close C_SELECT_NEXTVAL;
         return TRUE;
      end if;
      ---
   END LOOP;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
   return FALSE;

END;
-----------------------------------------------------------------------------
FUNCTION MERCH_DEAL_EXISTS (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_exists          IN OUT   BOOLEAN,
                            I_deal_no         IN       FIXED_DEAL_MERCH.DEAL_NO%TYPE,
                            I_dept            IN       FIXED_DEAL_MERCH.DEPT%TYPE,
                            I_class           IN       FIXED_DEAL_MERCH.CLASS%TYPE,
                            I_subclass        IN       FIXED_DEAL_MERCH.SUBCLASS%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(32) := 'FIXED_DEAL_SQL.MERCH_DEAL_EXISTS';
   L_deal     FIXED_DEAL_MERCH_LOC.DEAL_NO%TYPE;

   cursor C_DEAL_MERCH is
      select distinct deal_no
        from fixed_deal_merch
       where deal_no   = I_deal_no
         and (dept is null or
              dept     = nvl(I_dept,dept))
         and (class is null or
              class    = nvl(I_class,class))
         and (subclass is null or
              subclass = nvl(I_subclass,subclass));

BEGIN

   O_exists := TRUE;

   if I_deal_no is NULL then
      O_error_message:= sql_lib.create_msg('REQUIRED_INPUT_IS_NULL', 'I_deal_no',L_program, NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_DEAL_MERCH','fixed_deal_merch','NULL');
   open C_DEAL_MERCH;

   SQL_LIB.SET_MARK('FETCH','C_DEAL_MERCH', 'fixed_deal_merch','NULL');
   fetch C_DEAL_MERCH into L_deal;

   if C_DEAL_MERCH%NOTFOUND then
      O_exists := FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_DEAL_MERCH', 'fixed_deal_merch','NULL');
   close C_DEAL_MERCH;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END MERCH_DEAL_EXISTS;
-----------------------------------------------------------------------------
FUNCTION DELETE_DEAL_DATES (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            I_deal_no         IN       FIXED_DEAL_MERCH.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(32) := 'FIXED_DEAL_SQL.DELETE_DEAL_DATES';

   cursor C_LOCK_FIXED_DEAL_DATES is
      select 'x'
        from fixed_deal_dates
       where deal_no = I_deal_no
         for update nowait;

BEGIN

   if I_deal_no is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_deal_no',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_FIXED_DEAL_DATES',
                    'FIXED_DEAL_DATES',
                    'DEAL_NO: '||I_deal_no);
   open C_LOCK_FIXED_DEAL_DATES;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_FIXED_DEAL_DATES',
                    'FIXED_DEAL_DATES',
                    'DEAL_NO: '||I_deal_no);
   close C_LOCK_FIXED_DEAL_DATES;

   delete from fixed_deal_dates
    where deal_no = I_deal_no;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_DEAL_DATES;
-----------------------------------------------------------------------------------------------
-- MrgNBS019839(3.5b to PrdSi) 24-Nov-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com Begin
-----------------------------------------------------------------------------------------------
-- CR340 10-Aug-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com Begin
-----------------------------------------------------------------------------------
-- Name   : TSL_GET_FIXED_DEAL
-- Purpose: To get whole fixdeal row when passed deal no.
-----------------------------------------------------------------------------------
FUNCTION TSL_GET_FIXED_DEAL (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_fixed_deal_rec  OUT      FIXED_DEAL%ROWTYPE,
                             I_deal_no         IN       FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(32) := 'FIXED_DEAL_SQL.GET_FIXED_DEAL';

   CURSOR C_GET_FIXED_DEAL is
   select *
     from fixed_deal
    where deal_no = I_deal_no;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_FIXED_DEAL',
                    'FIXED_DEAL',
                    'DEAL_NO: '||I_deal_no);
   open C_GET_FIXED_DEAL;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_FIXED_DEAL',
                    'FIXED_DEAL',
                    'DEAL_NO: '||I_deal_no);
   fetch C_GET_FIXED_DEAL into O_fixed_deal_rec;

   if C_GET_FIXED_DEAL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_DEAL',
                                            -- NBS00023994 21-Nov-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
                                            --'Deal='||I_deal_no,
                                            I_deal_no,
                                            -- NBS00023994 21-Nov-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
                                            null,
                                            null);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_FIXED_DEAL',
                       'FIXED_DEAL',
                       'DEAL_NO: '||I_deal_no);
      close C_GET_FIXED_DEAL;
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
END TSL_GET_FIXED_DEAL;
-----------------------------------------------------------------------------------
-- Name   : TSL_UPDATE_FIXED_DEAL
-- Purpose: To update fixed deal with default vaues for new deal.
-----------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_FIXED_DEAL (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                I_deal_no         IN       FIXED_DEAL.DEAL_NO%TYPE,
                                I_duns_number     IN       SUPS.Duns_Number%TYPE,
                                I_shared_ind      IN       SUPS.Tsl_Shared_Supp_Ind%TYPE,
                                I_debtor_area     IN       TSL_DEBTOR_AREA.DEBTOR_AREA%TYPE,
                                I_user_name       IN       user_attrib.user_name%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'FIXED_DEAL_SQL.TSL_UPDATE_FIXED_DEAL';

   CURSOR C_LOCK_FIXED_DEAL is
   select 'x'
     from fixed_deal
    where deal_no = I_deal_no
      for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_FIXED_DEAL',
                    'FIXED_DEAL',
                    'DEAL_NO: '||I_deal_no);
   open C_LOCK_FIXED_DEAL;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_FIXED_DEAL',
                    'FIXED_DEAL',
                    'DEAL_NO: '||I_deal_no);
   close C_LOCK_FIXED_DEAL;
   update fixed_deal fd
      set fd.tsl_rev_company = decode(I_shared_ind,'Y',(select t.rev_comp_u from tsl_deal_default t),
                               decode(I_duns_number,'GB',(select t.rev_comp_u from tsl_deal_default t),
                               (select t.rev_comp_r from tsl_deal_default t))),
          fd.tsl_debtor_area = I_debtor_area,
          fd.tsl_internal_contact = I_user_name
      where   fd.deal_no = I_deal_no;
    -- NBS00019911, 01-Dec-2010, V Manikandan,   Begin
   update fixed_deal fd
      set fd.TSL_PRIMARY_SALES_PERSON =
                               decode(I_duns_number,'GB',(select t.TSL_PRIMARY_SALES_PERSON from tsl_deal_default t),
                               (I_user_name))
      where   fd.deal_no = I_deal_no;
     -- NBS00019911, 01-Dec-2010, V Manikandan,   End

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END TSL_UPDATE_FIXED_DEAL;
-----------------------------------------------------------------------------------
-- CR340 10-Aug-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com End
-----------------------------------------------------------------------------------------------
-- MrgNBS019839(3.5b to PrdSi) 24-Nov-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com End
-----------------------------------------------------------------------------------------------
-- CR378a 15-Mar-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
--------------------------------------------------------------------------------------------
--Function:  TSL_CHECK_INVOICED_IND
--Purpose:   This is a new function which will be used to check if deal is invoiced.
--------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_INVOICED_IND (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_invoiced_ind  IN OUT VARCHAR2,
                                 I_deal_no       IN     FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN is

   L_program   VARCHAR2(65) := 'FIXED_DEAL_SQL.TSL_CHECK_INVOICED_IND';

   CURSOR C_CHECK_INVOICED_IND is
   select 'Y'
     from fixed_deal fd,
          tsl_inv_deals tid,
          tsl_inv_head tih,
          tsl_inv_audit tia
    where fd.deal_no = I_deal_no
      and fd.deal_no = tid.deal_id
      and tid.inv_no = tih.inv_no
      and tih.trx_reference = tia.trx_reference
      and tia.actual_invoice_amount > 0
      and rownum = 1 ;
BEGIN

   if I_deal_no is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_deal_no',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_INVOICED_IND',
                    'FIXED_DEAL',
                    NULL);
   open C_CHECK_INVOICED_IND;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_INVOICED_IND',
                    'FIXED_DEAL',
                    NULL);
   fetch C_CHECK_INVOICED_IND into O_invoiced_ind;

   if C_CHECK_INVOICED_IND%NOTFOUND then
      O_invoiced_ind := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_INVOICED_IND',
                    'FIXED_DEAL',
                    NULL);
   close C_CHECK_INVOICED_IND;

   return TRUE;

EXCEPTION
   WHEN OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;

END TSL_CHECK_INVOICED_IND;
--------------------------------------------------------------------------------------------
--Function:  TSL_CHECK_PAID_IND
--Purpose:   This is a new function which will be used to check if deal amount is paid or not.
--------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_PAID_IND (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_paid_ind      IN OUT VARCHAR2,
                             I_deal_no       IN     FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN is

   L_program              VARCHAR2(65) := 'FIXED_DEAL_SQL.TSL_CHECK_PAID_IND';
   L_gross_invoice_amount TSL_INV_AUDIT.PLANNED_INVOICE_AMOUNT%TYPE;
   L_gross_paid_amount    TSL_INV_AUDIT.INVOICE_PAID_AMOUNT%TYPE;

   CURSOR C_GET_AMOUNT is
   select sum(nvl(planned_invoice_amount,0)),
          sum(nvl(invoice_paid_amount,0))
     from fixed_deal fd,
          tsl_inv_deals tid,
          tsl_inv_head tih,
          tsl_inv_audit tia
    where fd.deal_no = I_deal_no
      and fd.deal_no = tid.deal_id
      and tid.inv_no = tih.inv_no
      and tih.trx_reference = tia.trx_reference ;

BEGIN

   if I_deal_no is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_deal_no',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_AMOUNT',
                    'FIXED_DEAL',
                    NULL);
   open C_GET_AMOUNT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_AMOUNT',
                    'FIXED_DEAL',
                    NULL);
   fetch C_GET_AMOUNT into L_gross_invoice_amount,
                           L_gross_paid_amount;

   if L_gross_invoice_amount = L_gross_paid_amount then
      O_paid_ind := 'Y';
   else
      O_paid_ind := 'N';
   end if;

   if C_GET_AMOUNT%NOTFOUND then
      O_paid_ind := 'N';
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_AMOUNT',
                    'FIXED_DEAL',
                    NULL);
   close C_GET_AMOUNT;

   return TRUE;

EXCEPTION
   WHEN OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END TSL_CHECK_PAID_IND;
--------------------------------------------------------------------------------------------
--Function:  TSL_CHECK_VALID_STATUS_CHANGE
--Purpose:   This is a new function which will be used to check if status change of deal is valid.
--------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_VALID_STATUS_CHANGE  (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                         O_valid         IN OUT BOOLEAN,
                                         I_status        IN     FIXED_DEAL.STATUS%TYPE,
                                         I_start_date    IN     FIXED_DEAL.COLLECT_START_DATE%TYPE,
                                         I_deal_no       IN     FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN is

   L_program              VARCHAR2(65) := 'FIXED_DEAL_SQL.TSL_CHECK_VALID_STATUS_CHANGE';
   L_vdate                DATE         := GET_VDATE();
   L_old_status           FIXED_DEAL.STATUS%TYPE;
   -- CR378b 24-May-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   L_extracted_deal       VARCHAR2(1) := 'N';

   cursor C_OLD_VALUE is
   select status
     from fixed_deal
    where deal_no = I_deal_no;

   CURSOR C_EXTRACTED_DEAL is
   select fdd.extracted_ind
     from fixed_deal_dates fdd
    where fdd.deal_no      = I_deal_no
      and fdd.collect_date = I_start_date;
   -- CR378b 24-May-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End


BEGIN

   O_valid := TRUE;
   if I_deal_no is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_deal_no',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;

   -- CR378b 24-May-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXTRACTED_DEAL',
                    'FIXED_DEAL',
                    NULL);
   open C_EXTRACTED_DEAL;

   SQL_LIB.SET_MARK('FETCH',
                    'C_EXTRACTED_DEAL',
                    'FIXED_DEAL',
                    NULL);
   fetch C_EXTRACTED_DEAL into L_extracted_deal;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXTRACTED_DEAL',
                    'FIXED_DEAL',
                    NULL);
   close C_EXTRACTED_DEAL;
   -- PM036413 17-Feb-2015 Raghavendra S,Raghavendra.Shivaswamy@in.tesco.com Begin
   --if I_start_date > L_vdate or
   if I_start_date < L_vdate or
   -- PM036413 17-Feb-2015 Raghavendra S,Raghavendra.Shivaswamy@in.tesco.com End
      L_extracted_deal = 'Y'then
   -- CR378b 24-May-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End

      SQL_LIB.SET_MARK('OPEN',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      open C_OLD_VALUE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      fetch C_OLD_VALUE into L_old_status;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      close C_OLD_VALUE;

      if L_old_status is not NULL and I_status = 'I' and L_old_status = 'A' then
         O_valid := FALSE;
      else
         O_valid := TRUE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   WHEN OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
   return FALSE;
END;
-------------------------------------------------------------------------------------------
-- CR378b 24-May-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
-------------------------------------------------------------------------------------------
--Function:  TSL_GET_INV_INFO
--Purpose:   This is a new function which will be used to get the invoice information
-------------------------------------------------------------------------------------------
PROCEDURE TSL_GET_INV_INFO  (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_inv_info_table  IN OUT FIXED_DEAL_SQL.INVOICE_TABLE,
                             I_deal_id         IN     FIXED_DEAL.DEAL_NO%TYPE)
IS
   CURSOR C_GET_INV_INFO is
   select distinct fdd.collect_date period_date,
          tia.ext_inv_no,
          tia.planned_invoice_amount,
          tia.actual_invoice_amount,
          tia.invoice_paid_amount,(select sum(NVL(tdc1.Credit_Note_Amount,0))
             from TSL_DEAL_CREDIT_NOTE tdc1
             where tdc1.deal_id = tid.deal_id
             and tdc1.inv_no = tia.ext_inv_no) Credit_Note_Amount
          -- DefNBS024082 23-Dec-2011 Chithraprabha,vadakkedath.chitraprabha@in.tesco.com Begin
          ,tih.invc_ctry
          -- DefNBS024082 23-Dec-2011 Chithraprabha,vadakkedath.chitraprabha@in.tesco.com End
     from FIXED_DEAL_DATES fdd,
          TSL_INV_AUDIT tia,
          TSL_DEAL_CREDIT_NOTE tdc,
          TSL_INV_DEALS tid,
          DEAL_DETAIL dd,
          TSL_INV_HEAD tih
    where fdd.deal_no       = I_deal_id
      and fdd.deal_no       = tid.deal_id
      -- DefNBS024082 23-Dec-2011 Chithraprabha,vadakkedath.chitraprabha@in.tesco.com Begin
      and fdd.extracted_ind = 'Y'
      and tih.inv_no        = tid.inv_no
      and tih.trx_reference = tia.trx_reference
      and tdc.inv_no(+)     = tia.ext_inv_no
      and tia.extract_date  = fdd.collect_date
      -- DefNBS024082 23-Dec-2011 Chithraprabha,vadakkedath.chitraprabha@in.tesco.com End
    UNION ALL
    select distinct tia.extract_date period_date,
          tia.ext_inv_no,
          tia.planned_invoice_amount,
          tia.actual_invoice_amount,
          tia.invoice_paid_amount,
          (select sum(NVL(tdc1.Credit_Note_Amount,0))
             from TSL_DEAL_CREDIT_NOTE tdc1
             where tdc1.deal_id = tid.deal_id
             and tdc1.inv_no = tia.ext_inv_no) Credit_Note_Amount,
          -- DefNBS024082 23-Dec-2011 Chithraprabha,vadakkedath.chitraprabha@in.tesco.com Begin
          tih.invc_ctry
          -- DefNBS024082 23-Dec-2011 Chithraprabha,vadakkedath.chitraprabha@in.tesco.com End
     from DEAL_HEAD dh,
          TSL_INV_AUDIT tia,
          TSL_DEAL_CREDIT_NOTE tdc,
          TSL_INV_DEALS tid,
          tsl_inv_head tih
    where dh.Deal_Id        = I_deal_id
      and dh.deal_id        = tid.deal_id
      and tih.inv_no        = tid.inv_no
      and tdc.inv_no(+)     = tia.ext_inv_no
      and tih.trx_reference = tia.trx_reference
    order by 1,2;
      -- DefNBS024082 23-Dec-2011 Chithraprabha,vadakkedath.chitraprabha@in.tesco.com End

   CURSOR C_GET_NON_INV_DEALS is
   select fdd.collect_date period_date
     from fixed_deal fd,
          fixed_deal_dates fdd
    where fd.deal_no = fdd.deal_no
      and fd.deal_no = I_deal_id
    UNION
    select tia.extract_date period_date
     from DEAL_HEAD dh,
          deal_actuals_forecast df,
          TSL_INV_AUDIT tia,
          TSL_INV_DEALS tid
    where df.Deal_Id       = I_deal_id
      and dh.deal_id       = df.deal_id
      and df.deal_id       = tid.deal_id
      and tid.inv_no       = tia.ext_inv_no
      and tia.extract_date = df.reporting_date;

    L_count NUMBER;

BEGIN
   if I_deal_id is NOT NULL then
      L_count := 1;
      FOR C_rec in C_GET_INV_INFO
      LOOP
         O_inv_info_table(L_count).PERIOD_DATE        := C_rec.period_date;
         O_inv_info_table(L_count).INV_NO             := C_rec.ext_inv_no;
         if C_rec.planned_invoice_amount is NOT NULL then
            O_inv_info_table(L_count).PLAN_INV_AMT       := C_rec.planned_invoice_amount;
         else
            O_inv_info_table(L_count).PLAN_INV_AMT       := 0;
         end if;
         if C_rec.actual_invoice_amount is NOT NULL then
            O_inv_info_table(L_count).ACT_INV_AMT        := C_rec.actual_invoice_amount;
         else
            O_inv_info_table(L_count).ACT_INV_AMT        := 0;
         end if;
         if C_rec.invoice_paid_amount is NOT NULL then
            O_inv_info_table(L_count).PAID_AMOUNT        := C_rec.invoice_paid_amount;
         else
            O_inv_info_table(L_count).PAID_AMOUNT        := 0;
         end if;
         if C_rec.Credit_Note_Amount is NOT NULL then
            O_inv_info_table(L_count).CREDIT_NOTE_AMOUNT := C_rec.Credit_Note_Amount;
         else
            O_inv_info_table(L_count).CREDIT_NOTE_AMOUNT := 0;
         end if;
         O_inv_info_table(L_count).NET_PAYMENT        := NVL(NVL(C_rec.invoice_paid_amount,0)  - NVL(C_rec.Credit_Note_Amount,0),0);

         -- NBS00024082 28-Dec-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
         if C_rec.invc_ctry is NOT NULL then
            O_inv_info_table(L_count).invc_ctry          := C_rec.invc_ctry ;
         end if;
         -- NBS00024082 28-Dec-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
         L_count := L_count+ 1;
      END LOOP;
      if O_inv_info_table.count = 0 then
         FOR C_rec1 in C_GET_NON_INV_DEALS
         LOOP
            O_inv_info_table(L_count).PERIOD_DATE        := C_rec1.period_date ;
            O_inv_info_table(L_count).INV_NO             := NULL;
            O_inv_info_table(L_count).PLAN_INV_AMT       := 0;
            O_inv_info_table(L_count).ACT_INV_AMT        := 0;
            O_inv_info_table(L_count).PAID_AMOUNT        := 0;
            O_inv_info_table(L_count).CREDIT_NOTE_AMOUNT := 0;
            O_inv_info_table(L_count).NET_PAYMENT        := 0;
            -- NBS00024082 28-Dec-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
             O_inv_info_table(L_count).invc_ctry         := NULL;
            -- NBS00024082 28-Dec-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End

            -- NBS00023874 02-Nov-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
            L_count := L_count+ 1;
            -- NBS00023874 02-Nov-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
         END LOOP ;
      end if;
   end if;
EXCEPTION
   WHEN OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'FIXED_DEAL_SQL.TSL_GET_INV_INFO',
                                             to_char(SQLCODE));
END TSL_GET_INV_INFO;
--------------------------------------------------------------------------------------------
--Function:  TSL_GET_CODE
--Purpose:   This is a new function which will be used to get the code details
--------------------------------------------------------------------------------------------
FUNCTION TSL_GET_CODE ( O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                        O_code           IN OUT  CODE_DETAIL.CODE%TYPE,
                        I_code_desc      IN      CODE_DETAIL.CODE_DESC%TYPE,
                        I_code_type      IN      CODE_DETAIL.CODE_TYPE%TYPE)
RETURN BOOLEAN IS
   CURSOR C_GET_CODE is
   select code
     from code_detail
    where code_type = I_code_type
      and code_desc = I_code_desc ;

BEGIN
   if I_code_desc is NOT NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_CODE',
                       'CODE_DETAIL',
                       'Code_desc = ' ||I_code_desc);
      open C_GET_CODE;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_CODE',
                       'CODE_DETAIL',
                       'Code_desc = ' ||I_code_desc);
      fetch C_GET_CODE into O_code;
      if  C_GET_CODE%NOTFOUND then
        O_code := NULL;
      end if;
      SQL_LIB.SET_MARK('CLOSE',
                      'C_GET_CODE',
                      'CODE_DETAIL',
                      'Code_desc = ' ||I_code_desc);
      close C_GET_CODE;
  end if;
  return TRUE;
EXCEPTION
   WHEN OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'FIXED_DEAL_SQL.TSL_GET_CODE',
                                             to_char(SQLCODE));
   return FALSE;
END TSL_GET_CODE;
--------------------------------------------------------------------------------------------
-- CR378b 24-May-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
--------------------------------------------------------------------------------------------
-- CR378b 09-july-2011 Chithraprabha, chitraprabha.vadakkedath@in.tesco.com Begin
--------------------------------------------------------------------------------------------
-- Name   : INS_TSL_FIX_DEAL_TMP_GTT
-- Purpose: To insert the deals into the temporary table
--------------------------------------------------------------------------------------------
FUNCTION INS_TSL_FIX_DEAL_TMP_GTT(O_error_message IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_query IN  varchar2)

RETURN BOOLEAN IS
   I_insert_query  VARCHAR2(9000) := NULL;
   L_sql_select    VARCHAR2(9000) := NULL;
   L_exists        VARCHAR2(1)    := NULL;
   L_program       VARCHAR2(64)   := 'FIXED_DEAL_SQL.INS_TSL_FIX_DEAL_TMP_GTT';
   v_count         NUMBER(10);
   cursor C_CHK_REC_EXISTS is
      select 'x'
         from TSL_FIX_DEAL_TMP_GTT;

BEGIN

      if I_query is not null then
         I_insert_query := 'insert into TSL_FIX_DEAL_TMP_GTT (deal_no)
                               select deal_no
                                  from fixed_deal where ' || I_query ;
         execute immediate I_insert_query;
         dbms_output.put_line(I_insert_query);

     end if;
     select count(*) into v_count from TSL_FIX_DEAL_TMP_GTT;
     O_error_message := v_count;
     if v_count <= 0 then
        O_error_message := 'NO_REC';
        return FALSE;
    end if;
        return TRUE;

EXCEPTION
  when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;

END INS_TSL_FIX_DEAL_TMP_GTT;
----------------------------------------------------------------------------------------------
-- CR378b 09-july-2011 Chithraprabha, chitraprabha.vadakkedath@in.tesco.com End
----------------------------------------------------------------------------------------------
-- CR378b 10-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
----------------------------------------------------------------------------------------------
-- Name   : TSL_CHECK_PAID_IND_SEARCH
-- Purpose: To check the fully paid deals.
----------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_PAID_IND_SEARCH ( I_deal_no IN FIXED_DEAL.DEAL_NO%TYPE)
RETURN NUMBER IS
   L_error_message rtk_errors.rtk_text%TYPE;
   L_paid_ind      VARCHAR2(1);
BEGIN
   if TSL_CHECK_PAID_IND (L_error_message,
                          L_paid_ind,
                          I_deal_no) then
      if L_paid_ind = 'Y' then
        return 1;
      else
        return 0;
      end if;
   end if;
   return 1;
END TSL_CHECK_PAID_IND_SEARCH;
---------------------------------------------------------------------------------------------------------
-- Name   : TSL_CHECK_INV_IND_SEARCH
-- Purpose: To check the invoiced deals.
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_INV_IND_SEARCH ( I_deal_no IN FIXED_DEAL.DEAL_NO%TYPE)
RETURN NUMBER IS
   L_error_message rtk_errors.rtk_text%TYPE;
   L_inv_ind       VARCHAR2(1);
   L_exist         VARCHAR2(1);

BEGIN
   if TSL_CHECK_INVOICED_IND (L_error_message,
                              L_inv_ind,
                              I_deal_no) then
      if L_inv_ind = 'Y' then
        return 1;
      else
        return 0;
      end if;
   end if;
   return 1;
END TSL_CHECK_INV_IND_SEARCH;
------------------------------------------------------------------------------------------------------------
-- Name   : GET_DEAL_COMMENTS
-- Purpose: To check the fully paid deals.
----------------------------------------------------------------------------------------------
FUNCTION TSL_GET_DEAL_COMMENTS(I_deal_no IN NUMBER)
RETURN VARCHAR2 IS

   CURSOR C_GET_COMMENTS is
   select comments
     from fixed_deal
    where deal_no = I_deal_no
   UNION ALL
   select comments
     from deal_head
    where deal_id = I_deal_no ;

   L_comments VARCHAR2(32767) ;
BEGIN
 open C_GET_COMMENTS;
 fetch C_GET_COMMENTS into L_comments;
 close C_GET_COMMENTS ;
 L_comments := substr(L_comments, 1, 2000);

 return L_comments;

END TSL_GET_DEAL_COMMENTS;
------------------------------------------------------------------------------------------------------------
-- CR378b 10-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
------------------------------------------------------------------------------------------------------------
-- CR604 04-Apr-2014 Ramya.K.Shetty@in.tesco.com Begin
------------------------------------------------------------------------------------------------------------
--FUNCTION NAME: TSL_VAT_DEF_REQ
--Purpose:       This function checks if VAT should be defaulted or not
-------------------------------------------------------------------------------------
FUNCTION TSL_VAT_DEF_REQ(O_ERROR_MESSAGE OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_VAT_DEF_REQ  OUT VARCHAR2)
RETURN BOOLEAN  IS

   L_program      VARCHAR2(50) :=   'FIXED_DEAL_SQL.VAT_DEF_REQ ';
   L_exists       VARCHAR2(1)  := NULL;

   CURSOR c_get_vat is
   select 'X'
     from tsl_vat_checkbox_def
    where rownum=1;

BEGIN
   SQL_LIB.SET_MARK('open',
                    'c_get_vat',
                    'tsl_vat_checkbox_def',
                    null);
   open c_get_vat;

   SQL_LIB.SET_MARK('fetch',
                    'c_get_vat',
                    'tsl_vat_checkbox_def',
                    null);
   fetch c_get_vat into L_exists;

   if L_exists is not null then
      O_VAT_DEF_REQ :='Y';
   else
      O_VAT_DEF_REQ :='N';
   end if;

   SQL_LIB.SET_MARK('close',
                    'c_get_vat',
                    'tsl_vat_checkbox_def',
                    null);
   close c_get_vat;
RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         to_char(SQLCODE));
   return FALSE;
END TSL_VAT_DEF_REQ;
-------------------------------------------------------------------------------------------------
-- CR604 04-Apr-2014 Ramya.K.Shetty@in.tesco.com End
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
--Author   : Raghavendra S, Raghavendra.Shivaswamy@in.tesco.com
--Date     : 04-Apr-2014
--Mod Ref  : CR604
--Function : TSL_GET_VAT_DETAILS.
--Purpose  : This function fetches the suppliers country from the primary address of the supplier.
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_VAT_DETAILS(O_error_message    OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_vat_code         OUT   VAT_CODES.VAT_CODE%TYPE,
                             O_vat_disable_ind  OUT   VARCHAR2,
                             O_vat_ind          OUT   VARCHAR2,
                             O_vanilla_ind      OUT   VARCHAR2,
                             O_country_id       OUT   TSL_SUPP_ADDR.COUNTRY_ORIGIN%TYPE,
                             O_vat_no           OUT   TSL_SUPP_ADDR.VAT_NO%TYPE,
                             I_supplier         IN    SUPS.SUPPLIER%TYPE,
                             I_tsl_mi_code      IN    FIXED_DEAL.TSL_MI_CODE%TYPE,
                             I_deal_code        IN    CODE_DETAIL.CODE%TYPE)
   RETURN BOOLEAN IS

   L_program	 varchar2(300)                    := 'FIXED_DEAL_SQL.GET_VAT_DETAILS';
   L_vanilla_ind VARCHAR2(1)                      := 'N';
   L_sup_country TSL_SUPP_ADDR.SUP_COUNTRY%TYPE   := NULL;
   L_vat_no      TSL_SUPP_ADDR.VAT_NO%TYPE        := NULL;
   L_country_id  ADDR.COUNTRY_ID%TYPE             := NULL;


   CURSOR C_GET_VAT_DEF is
      select vat_ind, vat_disable_ind
        from tsl_vat_checkbox_def
       where code      = I_deal_code
         and code_type = 'FXDT';

BEGIN
   if I_deal_code is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_deal_code',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_VAT_DEF',
                    'tsl_vat_checkbox_def',
                    NULL);
   open C_GET_VAT_DEF;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_VAT_DEF',
                    'tsl_vat_checkbox_def',
                    NULL);
   fetch C_GET_VAT_DEF into O_vat_ind,
                            O_vat_disable_ind;

   if C_GET_VAT_DEF%NOTFOUND then
      L_vanilla_ind := 'Y';
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_VAT_DEF',
                       'tsl_vat_checkbox_def',
                       NULL);
      close C_GET_VAT_DEF;
   else
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_VAT_DEF',
                       'tsl_vat_checkbox_def',
                       NULL);
      close C_GET_VAT_DEF;
   end if;
   O_vanilla_ind := L_vanilla_ind;

   if O_vat_ind = 'Y' then
      if ADDRESS_SQL.TSL_GET_SUPPLIER_COUNTRY(O_error_message,
                                          L_country_id,
                                          L_sup_country,
                                          L_vat_no,
                                          I_supplier) = FALSE then
      return FALSE;
      else
         O_country_id := L_country_id;
         O_vat_no     := L_vat_no;

      end if;

      if I_tsl_mi_code IS NULL then
         if L_country_id = 'ROI' and L_vat_no = 'IE' then
            O_vat_code := 'SROI';
         elsif L_country_id = 'ROI' and L_vat_no = 'XX' and L_sup_country='IRELAND' then
            O_vat_code := 'SROI';
		 elsif L_country_id is NULL and L_vat_no is NULL and L_sup_country is NULL then
            O_vat_code := 'SROI';
         else
            O_vat_code := 'Z';
         end if;
      elsif I_tsl_mi_code IS NOT NULL then
         if L_country_id = 'UK' and L_vat_no = 'GB' then
            O_vat_code := 'S';
         elsif L_country_id = 'UK' and L_vat_no = 'XX' and L_sup_country='UNITED KINGDOM' then
            O_vat_code := 'S';
		 elsif L_country_id is NULL and L_vat_no is NULL and L_sup_country is NULL then
            O_vat_code := 'S';
         else
            O_vat_code := 'Z';
         end if;
      else
         O_vat_code := 'Z';
      end if;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
   return FALSE;
END TSL_GET_VAT_DETAILS;
-------------------------------------------------------------------------------------------------
-- CR604 04-Apr-2014 Raghavendra.Shivaswamy@in.tesco.com End
-------------------------------------------------------------------------------------------------
END fixed_deal_sql;
/

