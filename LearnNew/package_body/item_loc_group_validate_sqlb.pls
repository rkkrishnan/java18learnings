CREATE OR REPLACE PACKAGE BODY ITEM_LOC_GROUP_VALIDATE_SQL AS
---------------------------------------------------------------------
   FUNCTION GROUP_TYPE (O_error_message     IN OUT VARCHAR2,
                        I_group_type        IN     VARCHAR2,
                        I_item_level        IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                        I_tran_level        IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                        I_item              IN     ITEM_MASTER.ITEM%TYPE,
                        I_value             IN     VARCHAR2,
                        O_value_desc        IN OUT VARCHAR2,
                        O_exist_ind         IN OUT BOOLEAN)
            return BOOLEAN is

      QUICK_EXIT  EXCEPTION;
      L_program    VARCHAR2(60) := 'ITEM_LOC_GROUP_VALIDATE_SQL.GROUP_TYPE';

   BEGIN
      -- If the group is not a store class, then make sure that the value entered
      -- is a number.
      --
      if I_group_type != 'C' then
         if SQL_LIB.CHECK_NUMERIC(O_error_message,
                                  I_value) = FALSE then
            return FALSE;
         end if;
      end if;

      if I_group_type = 'S' then
         if STORES_REPL(O_error_message,
                        I_item_level,
                        I_tran_level,
                        I_item,
                        I_value,
                        O_value_desc,
                        O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'C' then
         if STORE_CLASS(O_error_message,
                        I_item_level,
                        I_tran_level,
                        I_item,
                        I_value,
                        O_value_desc,
                        O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'D' then
         if DISTRICTS(O_error_message,
                      I_item_level,
                      I_tran_level,
                      I_item,
                      I_value,
                      O_value_desc,
                      O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'R' then
         if REGIONS(O_error_message,
                    I_item_level,
                    I_tran_level,
                    I_item,
                    I_value,
                    O_value_desc,
                    O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'T' then
         if TZONE(O_error_message,
                  I_item_level,
                  I_tran_level,
                  I_item,
                  I_value,
                  O_value_desc,
                  O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'L' then
         if VAL_LOC_TRAITS(O_error_message,
                           I_item_level,
                           I_tran_level,
                           I_item,
                           I_value,
                           O_value_desc,
                           O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'DW' then
         if DEFAULT_WAREHOUSE (O_error_message,
                               I_item_level,
                               I_tran_level,
                               I_item,
                               I_value,
                               O_value_desc,
                               O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'W' then
         if WAREHOUSE (O_error_message,
                       I_item_level,
                       I_tran_level,
                       I_item,
                       I_value,
                       O_value_desc,
                       O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'LLS' then
         if  LOC_LIST_ST (O_error_message,
                          I_item_level,
                          I_tran_level,
                          I_item,
                          I_value,
                          O_value_desc,
                          O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'LLW' then
         if  LOC_LIST_WH (O_error_message,
                          I_item_level,
                          I_tran_level,
                          I_item,
                          I_value,
                          O_value_desc,
                          O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      elsif I_group_type = 'A' then
         if AREAS(O_error_message,
                  I_item_level,
                  I_tran_level,
                  I_item,
                  I_value,
                  O_value_desc,
                  O_exist_ind) = FALSE then
            raise QUICK_EXIT;
         end if;
      end if;

      return TRUE;

   EXCEPTION
      when QUICK_EXIT then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               O_error_message,
                                               L_program,
                                               NULL);

         return FALSE;
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END GROUP_TYPE;
---------------------------------------------------------------------
   FUNCTION STORES_REPL(O_error_message  IN OUT VARCHAR2,
                        I_item_level     IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                        I_tran_level     IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                        I_item           IN     ITEM_MASTER.ITEM%TYPE,
                        I_value          IN     STORE.STORE%TYPE,
                        O_value_desc     IN OUT STORE.STORE_NAME%TYPE,
                        O_exist_ind      IN OUT BOOLEAN)
            return BOOLEAN is

      L_program     VARCHAR2(60) := 'ITEM_LOC_GROUP_VALIDATE_SQL.STORES_REPL';
      cursor C_STORE_ITEM_REPL is
         select s.store_name
           from store s,
                item_loc il
          where il.loc = s.store
            and il.loc = I_value
            and il.item = I_item
            and s.stockholding_ind = 'Y'
            and il.status = 'A';

      cursor C_STORE_ITEM2_REPL is
         select s.store_name
           from store s,
                item_master im,
                item_loc il
          where il.loc = s.store
            and il.loc_type = 'S'
            and il.loc = I_value
            and im.item = il.item
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and s.stockholding_ind = 'Y'
            and il.status = 'A';

      cursor C_STORE_ITEM_LIST_REPL is
         select s.store_name
	   from store s,(select distinct loc
                           from item_loc il,
	                        skulist_detail sd
	                  where sd.skulist= I_item
	                    and sd.item = il.item
	                    and il.loc= I_value) ild
	  where (s.store = to_number(I_value)
	         or s.store = ild.loc)
            and s.stockholding_ind = 'Y';

   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_STORE_ITEM2_REPL',
                              'STORE',
                              I_value);
            open C_STORE_ITEM2_REPL;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_STORE_ITEM2_REPL',
                              'STORE',
                              I_value);
            fetch C_STORE_ITEM2_REPL into O_value_desc;
            if C_STORE_ITEM2_REPL%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_STORE_ITEM2_REPL',
                              'STORE',
                              I_value);
            close C_STORE_ITEM2_REPL;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_STORE_ITEM_REPL',
                              'STORE',
                              I_value);
            open C_STORE_ITEM_REPL;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_STORE_ITEM_REPL',
                              'STORE',
                              I_value);
            fetch C_STORE_ITEM_REPL into O_value_desc;
            if C_STORE_ITEM_REPL%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_STORE_ITEM_REPL',
                              'STORE',
                              I_value);
            close C_STORE_ITEM_REPL;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_STORE_ITEM_LIST_REPL',
                           'STORE',
                           I_value);
         open C_STORE_ITEM_LIST_REPL;
         SQL_LIB.SET_MARK ('FETCH',
                           'C_STORE_ITEM_LIST_REPL',
                           'STORE',
                           I_value);
         fetch C_STORE_ITEM_LIST_REPL into O_value_desc;
         if C_STORE_ITEM_LIST_REPL%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;
         SQL_LIB.SET_MARK ('CLOSE',
                           'C_STORE_ITEM_LIST_REPL',
                           'STORE',
                           I_value);
         close C_STORE_ITEM_LIST_REPL;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END STORES_REPL;
----------------------------------------------------------------------
   FUNCTION STORE_CLASS(O_error_message      IN OUT VARCHAR2,
                        I_item_level         IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                        I_tran_level         IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                        I_item               IN     ITEM_MASTER.ITEM%TYPE,
                        I_value              IN     VARCHAR2,
                        O_value_desc         IN OUT VARCHAR2,
                        O_exist_ind          IN OUT BOOLEAN)
            return BOOLEAN is
      L_dummy    VARCHAR2(1) := NULL;
      L_program   VARCHAR2(60) := 'ITEM_LOC_GROUP_VALIDATE_SQL.STORE_CLASS';

      cursor C_STORE_CLASS_ITEM is
         select cd.code_desc
           from store s,
                item_loc il,
                code_detail cd
          where il.loc = s.store
            and cd.code_type = 'CSTR'
            and cd.code = I_value
            and s.store_class = I_value
            and il.item = I_item
            and s.stockholding_ind = 'Y'
            and il.status = 'A';

      cursor C_STORE_CLASS_ITEM2 is
         select cd.code_desc
           from store s,
                item_loc il,
                item_master im,
                code_detail cd
          where il.loc = s.store
            and il.loc_type = 'S'
            and s.store_class = I_value
            and cd.code = I_value
            and cd.code_type = 'CSTR'
            and im.item = il.item
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and s.stockholding_ind = 'Y'
            and il.status = 'A';

      cursor C_STORE_CLASS_ITEM_LIST is
         select cd.code_desc
           from store s,
                code_detail cd
          where cd.code_type = 'CSTR'
            and cd.code = I_value
            and s.store_class = I_value
            and s.stockholding_ind = 'Y';
   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_STORE_CLASS_ITEM2',
                              'STORE',
                              I_value);
            open C_STORE_CLASS_ITEM2;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_STORE_CLASS_ITEM2',
                              'STORE',
                              I_value);
            fetch C_STORE_CLASS_ITEM2 into O_value_desc;
            if C_STORE_CLASS_ITEM2%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_STORE_CLASS_ITEM2',
                              'STORE',
                              I_value);
            close C_STORE_CLASS_ITEM2;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_STORE_CLASS_ITEM',
                              'STORE',
                              I_value);
            open C_STORE_CLASS_ITEM;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_STORE_CLASS_ITEM',
                              'STORE',
                              I_value);
            fetch C_STORE_CLASS_ITEM into O_value_desc;
            if C_STORE_CLASS_ITEM%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_STORE_CLASS_ITEM',
                              'STORE',
                              I_value);
            close C_STORE_CLASS_ITEM;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_STORE_CLASS_ITEM_LIST',
                           'STORE',
                           I_value);
         open C_STORE_CLASS_ITEM_LIST;
         SQL_LIB.SET_MARK ('FETCH',
                           'C_STORE_CLASS_ITEM_LIST',
                           'STORE',
                           I_value);
         fetch C_STORE_CLASS_ITEM_LIST into O_value_desc;
         if C_STORE_CLASS_ITEM_LIST%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;
         SQL_LIB.SET_MARK ('CLOSE',
                           'C_STORE_CLASS_ITEM_LIST',
                           'STORE',
                           I_value);
         close C_STORE_CLASS_ITEM_LIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END STORE_CLASS;
-----------------------------------------------------------------------
   FUNCTION DISTRICTS(O_error_message      IN OUT VARCHAR2,
                      I_item_level         IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                      I_tran_level         IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                      I_item               IN     ITEM_MASTER.ITEM%TYPE,
                      I_value              IN     DISTRICT.DISTRICT%TYPE,
                      O_value_desc         IN OUT DISTRICT.DISTRICT_NAME%TYPE,
                      O_exist_ind          IN OUT BOOLEAN)
            return BOOLEAN is

     L_program      VARCHAR2(60) := 'ITEM_LOC_GROUP_VALIDATE_SQL.DISTRICTS';

      cursor C_DISTRICT_ITEM is
         select distinct d.district_name
           from district d,
                store s,
                item_loc il
          where s.district = d.district
            and il.loc = s.store
            and s.stockholding_ind = 'Y'
            and d.district = I_value
            and il.item = I_item
            and il.status = 'A';

      cursor C_DISTRICT_ITEM2 is
         select distinct d.district_name
           from district d,
                store s,
                item_master im,
                item_loc il
          where s.district = d.district
            and il.loc = s.store
            and s.stockholding_ind = 'Y'
            and im.item = il.item
            and d.district = I_value
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and il.status = 'A';

      cursor C_DISTRICT_ITEM_LIST is
         select distinct d.district_name
           from district d,
                store s
          where s.district = d.district
            and d.district = I_value
            and s.stockholding_ind = 'Y';

   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_DISTRICT_ITEM2',
                              'DISTRICT',
                              I_value);
            open C_DISTRICT_ITEM2;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_DISTRICT_ITEM2',
                              'DISTRICT',
                              I_value);
            fetch C_DISTRICT_ITEM2 into O_value_desc;
            if C_DISTRICT_ITEM2%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_DISTRICT_ITEM2',
                              'DISTRICT',
                              I_value);
            close C_DISTRICT_ITEM2;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_DISTRICT_ITEM',
                              'DISTRICT',
                              I_value);
            open C_DISTRICT_ITEM;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_DISTRICT_ITEM',
                              'DISTRICT',
                              I_value);
            fetch C_DISTRICT_ITEM into O_value_desc;
            if C_DISTRICT_ITEM%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_DISTRICT_ITEM',
                              'DISTRICT',
                              I_value);
            close C_DISTRICT_ITEM;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_DISTRICT_ITEM_LIST',
                           'DISTRICT',
                           I_value);
         open C_DISTRICT_ITEM_LIST;
         SQL_LIB.SET_MARK ('FETCH',
                           'C_DISTRICT_ITEM_LIST',
                           'DISTRICT',
                           I_value);
         fetch C_DISTRICT_ITEM_LIST into O_value_desc;
         if C_DISTRICT_ITEM_LIST%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;
         SQL_LIB.SET_MARK ('CLOSE',
                           'C_DISTRICT_ITEM_LIST',
                           'DISTRICT',
                           I_value);
         close C_DISTRICT_ITEM_LIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END DISTRICTS;
-------------------------------------------------------------------------
   FUNCTION REGIONS(O_error_message        IN OUT VARCHAR2,
                    I_item_level           IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                    I_tran_level           IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                    I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                    I_value                IN     REGION.REGION%TYPE,
                    O_value_desc           IN OUT REGION.REGION_NAME%TYPE,
                    O_exist_ind            IN OUT BOOLEAN)
      return BOOLEAN is

      L_program      VARCHAR2(60) := 'ITEM_LOC_GROUP_VALIDATE_SQL.REGIONS';

      cursor C_REGION_ITEM is
         select distinct r.region_name
           from region r,
                store s,
                store_hierarchy sh,
                item_loc il
          where sh.region = r.region
            and s.store = sh.store
            and il.loc = s.store
            and s.stockholding_ind = 'Y'
            and r.region = I_value
            and il.item = I_item
            and il.status = 'A';

      cursor C_REGION_ITEM2 is
         select distinct r.region_name
           from region r,
                store s,
                store_hierarchy sh,
                item_master im,
                item_loc il
          where r.region = sh.region
            and sh.store = s.store
            and il.loc = s.store
            and im.item = il.item
            and s.stockholding_ind = 'Y'
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and r.region = I_value
            and il.status = 'A';
      cursor C_REGION_ITEM_LIST is
         select distinct r.region_name
           from region r,
                store_hierarchy sh,
                store s
          where sh.region = r.region
            and s.store = sh.store
            and s.stockholding_ind = 'Y'
            and r.region = I_value;

   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_REGION_ITEM2',
                              'REGION',
                              I_value);
            open C_REGION_ITEM2;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_REGION_ITEM2',
                              'REGION',
                              I_value);
            fetch C_REGION_ITEM2 into O_value_desc;
            if C_REGION_ITEM2%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_REGION_ITEM2',
                              'REGION',
                              I_value);
            close C_REGION_ITEM2;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_REGION_ITEM',
                              'REGION',
                              I_value);
            open C_REGION_ITEM;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_REGION_ITEM',
                              'REGION',
                              I_value);
            fetch C_REGION_ITEM into O_value_desc;
            if C_REGION_ITEM%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_REGION_ITEM',
                              'REGION',
                              I_value);
            close C_REGION_ITEM;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_REGION_ITEM_LIST',
                           'REGION',
                           I_value);
         open C_REGION_ITEM_LIST;
         SQL_LIB.SET_MARK ('FETCH',
                           'C_REGION_ITEM_LIST',
                           'REGION',
                           I_value);
         fetch C_REGION_ITEM_LIST into O_value_desc;
         if C_REGION_ITEM_LIST%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;
         SQL_LIB.SET_MARK ('CLOSE',
                           'C_REGION_ITEM_LIST',
                           'REGION',
                           I_value);
         close C_REGION_ITEM_LIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END REGIONS;
--------------------------------------------------------------------------


----------------------------------------------------------------------------
   FUNCTION TZONE(O_error_message        IN OUT VARCHAR2,
                  I_item_level           IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                  I_tran_level           IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                  I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                  I_value                IN     VARCHAR2,
                  O_value_desc           IN OUT VARCHAR2,
                  O_exist_ind            IN OUT BOOLEAN)
      return BOOLEAN is

      L_program     VARCHAR2(60) := 'ITEM_LOC_GROUP_VALIDATE_SQL.TZONE';
      cursor C_TRANSFER_ZONE_ITEM is
         select tz.description
           from tsfzone tz,
                store s,
                item_loc il
          where s.transfer_zone = tz.transfer_zone
            and il.loc = s.store
            and tz.transfer_zone = I_value
            and il.item = I_item
            and s.stockholding_ind = 'Y'
            and il.status = 'A';

      cursor C_TRANSFER_ZONE_ITEM2 is
         select tz.description
           from tsfzone tz,
                store s,
                item_master im,
                item_loc il
          where s.transfer_zone = tz.transfer_zone
            and tz.transfer_zone = I_value
            and il.loc = s.store
            and il.loc_type = 'S'
            and im.item = il.item
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and s.stockholding_ind = 'Y'
            and il.status = 'A';

      cursor C_TRANSFER_ZONE_ITEM_LIST is
         select tz.description
           from tsfzone tz,
                store s
          where s.transfer_zone = tz.transfer_zone
            and tz.transfer_zone = I_value
            and s.stockholding_ind = 'Y';

   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_TRANSFER_ZONE_ITEM2',
                              'TSFZONE',
                              I_value);
            open C_TRANSFER_ZONE_ITEM2;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_TRANSFER_ZONE_ITEM2',
                              'TSFZONE',
                              I_value);
            fetch C_TRANSFER_ZONE_ITEM2 into O_value_desc;
            if C_TRANSFER_ZONE_ITEM2%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_TRANSFER_ZONE_ITEM2',
                              'TSFZONE',
                              I_value);
            close C_TRANSFER_ZONE_ITEM2;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_TRANSFER_ZONE_ITEM',
                              'TSFZONE',
                              I_value);
            open C_TRANSFER_ZONE_ITEM;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_TRANSFER_ZONE_ITEM',
                              'TSFZONE',
                              I_value);
            fetch C_TRANSFER_ZONE_ITEM into O_value_desc;
            if C_TRANSFER_ZONE_ITEM%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_TRANSFER_ZONE_ITEM',
                              'TSFZONE',
                              I_value);
            close C_TRANSFER_ZONE_ITEM;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_TRANSFER_ZONE_ITEM_LIST',
                           'TSFZONE',
                           I_value);
         open C_TRANSFER_ZONE_ITEM_LIST;
         SQL_LIB.SET_MARK ('FETCH',
                           'C_TRANSFER_ZONE_ITEM_LIST',
                           'TSFZONE',
                           I_value);
         fetch C_TRANSFER_ZONE_ITEM_LIST into O_value_desc;
         if C_TRANSFER_ZONE_ITEM_LIST%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;
         SQL_LIB.SET_MARK ('CLOSE',
                           'C_TRANSFER_ZONE_ITEM_LIST',
                           'TSFZONE',
                           I_value);
         close C_TRANSFER_ZONE_ITEM_LIST;
      end if;
      return TRUE;      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END TZONE;
-----------------------------------------------------------------------------
   FUNCTION VAL_LOC_TRAITS(O_error_message       IN OUT VARCHAR2,
                           I_item_level          IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                           I_tran_level          IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                           I_item                IN     ITEM_MASTER.ITEM%TYPE,
                           I_value               IN     VARCHAR2,
                           O_value_desc          IN OUT VARCHAR2,
                           O_exist_ind           IN OUT BOOLEAN)
      return BOOLEAN is

      L_program     VARCHAR2(60)  := 'ITEM_LOC_GROUP_VALIDATE_SQL.VAL_LOC_TRAITS';
      cursor C_LOC_TRAIT_ITEM is
         select lt.description
           from loc_traits lt,
                  loc_traits_matrix ltm,
                  item_loc il,
                store s
          where ltm.loc_trait = lt.loc_trait
            and il.loc = ltm.store
            and il.loc = s.store
            and s.stockholding_ind = 'Y'
            and lt.loc_trait = I_value
            and il.item = I_item
            and il.status = 'A';

      cursor C_LOC_TRAIT_ITEM2 is
         select lt.description
           from loc_traits lt,
                loc_traits_matrix ltm,
                item_master im,
                item_loc il,
                store s
          where ltm.loc_trait = I_value
            and ltm.loc_trait = lt.loc_trait
            and il.loc = ltm.store
            and ltm.store = s.store
            and s.stockholding_ind = 'Y'
            and il.loc_type = 'S'
            and im.item = il.item
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and il.status = 'A';

      cursor C_LOC_TRAIT_ITEM_LIST is
         select lt.description
           from loc_traits lt,
                  loc_traits_matrix ltm,
                store s
          where ltm.loc_trait      = lt.loc_trait
            and lt.loc_trait       = I_value
            and ltm.store          = s.store
            and s.stockholding_ind = 'Y';

   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_LOC_TRAIT_ITEM2',
                              'LOC_TRAIT',
                              I_value);
            open C_LOC_TRAIT_ITEM2;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_LOC_TRAIT_ITEM2',
                              'LOC_TRAIT',
                              I_value);
            fetch C_LOC_TRAIT_ITEM2 into O_value_desc;
            if C_LOC_TRAIT_ITEM2%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_LOC_TRAIT_ITEM2',
                              'LOC_TRAIT',
                              I_value);
            close C_LOC_TRAIT_ITEM2;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_LOC_TRAIT_ITEM',
                              'LOC_TRAIT',
                              I_value);
            open C_LOC_TRAIT_ITEM;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_LOC_TRAIT_ITEM',
                              'LOC_TRAIT',
                              I_value);
            fetch C_LOC_TRAIT_ITEM into O_value_desc;
            if C_LOC_TRAIT_ITEM%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_LOC_TRAIT_ITEM',
                              'LOC_TRAIT',
                              I_value);
            close C_LOC_TRAIT_ITEM;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_LOC_TRAIT_ITEM_LIST',
                           'LOC_TRAIT',
                           I_value);
         open C_LOC_TRAIT_ITEM_LIST;
         SQL_LIB.SET_MARK ('FETCH',
                           'C_LOC_TRAIT_ITEM_LIST',
                           'LOC_TRAIT',
                           I_value);
         fetch C_LOC_TRAIT_ITEM_LIST into O_value_desc;
         if C_LOC_TRAIT_ITEM_LIST%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;
         SQL_LIB.SET_MARK ('CLOSE',
                           'C_LOC_TRAIT_ITEM_LIST',
                           'LOC_TRAIT',
                           I_value);
         close C_LOC_TRAIT_ITEM_LIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END VAL_LOC_TRAITS;
----------------------------------------------------------------------------
   FUNCTION DEFAULT_WAREHOUSE(O_error_message       IN OUT VARCHAR2,
                              I_item_level          IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                              I_tran_level          IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                              I_item                IN     ITEM_MASTER.ITEM%TYPE,
                              I_value               IN     VARCHAR2,
                              O_value_desc          IN OUT VARCHAR2,
                              O_exist_ind           IN OUT BOOLEAN)
      return BOOLEAN is

      L_program     VARCHAR2(60)  := 'ITEM_LOC_GROUP_VALIDATE_SQL.DEFAULT_WAREHOUSE';
      cursor C_DEFAULT_WH_ITEM is
         select wh.wh_name
           from wh,
                store s,
                item_loc il
          where s.default_wh = wh.wh
            and il.loc = s.store
            and s.default_wh = I_value
            and il.item = I_item
            and s.stockholding_ind = 'Y'
            and il.status = 'A';

      cursor C_DEFAULT_WH_ITEM2 is
         select wh.wh_name
           from wh,
                store s,
                item_master im,
                item_loc il
          where s.default_wh = I_value
            and s.default_wh = wh.wh
            and il.loc = s.store
            and im.item = il.item
            and il.loc_type = 'S'
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and s.stockholding_ind = 'Y'
            and il.status = 'A';
      cursor C_DEFAULT_WH_ITEM_LIST is
         select wh.wh_name
           from wh,
                  store s
          where s.default_wh = wh.wh
            and s.default_wh = I_value
            and s.stockholding_ind = 'Y';
   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_DEFAULT_WH_ITEM2',
                              'WH',
                              I_value);
            open C_DEFAULT_WH_ITEM2;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_DEFAULT_WH_ITEM2',
                              'WH',
                              I_value);
            fetch C_DEFAULT_WH_ITEM2 into O_value_desc;
            if C_DEFAULT_WH_ITEM2%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_DEFAULT_WH_ITEM2',
                              'WH',
                              I_value);
            close C_DEFAULT_WH_ITEM2;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_DEFAULT_WH_ITEM',
                              'WH',
                              I_value);
            open C_DEFAULT_WH_ITEM;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_DEFAULT_WH_ITEM',
                              'WH',
                              I_value);
            fetch C_DEFAULT_WH_ITEM into O_value_desc;
            if C_DEFAULT_WH_ITEM%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_DEFAULT_WH_ITEM',
                              'WH',
                              I_value);
            close C_DEFAULT_WH_ITEM;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_DEFAULT_WH_ITEM_LIST',
                           'WH',
                           I_value);
         open C_DEFAULT_WH_ITEM_LIST;
         SQL_LIB.SET_MARK ('FETCH',
                           'C_DEFAULT_WH_ITEM_LIST',
                           'WH',
                           I_value);
         fetch C_DEFAULT_WH_ITEM_LIST into O_value_desc;
         if C_DEFAULT_WH_ITEM_LIST%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;
         SQL_LIB.SET_MARK ('CLOSE',
                           'C_DEFAULT_WH_ITEM_LIST',
                           'WH',
                           I_value);
         close C_DEFAULT_WH_ITEM_LIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END DEFAULT_WAREHOUSE;
----------------------------------------------------------------------
   FUNCTION WAREHOUSE(O_error_message       IN OUT VARCHAR2,
                      I_item_level          IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                      I_tran_level          IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                      I_item                IN     ITEM_MASTER.ITEM%TYPE,
                      I_value               IN     VARCHAR2,
                      O_value_desc          IN OUT VARCHAR2,
                      O_exist_ind           IN OUT BOOLEAN)
      return BOOLEAN is

      L_program     VARCHAR2(60)  := 'ITEM_LOC_GROUP_VALIDATE_SQL.WAREHOUSE';
      cursor C_WH_ITEM is
         select wh.wh_name
           from wh,
                  item_loc il
          where il.loc = wh.wh
            and il.loc = I_value
            and il.item = I_item
            and wh.stockholding_ind = 'Y'
            and wh.repl_ind = 'Y';

      cursor C_WH_ITEM2 is
         select wh.wh_name
           from wh,
                item_master im,
                item_loc il
          where il.loc = I_value
            and il.loc = wh.wh
            and il.loc_type = 'W'
            and im.item = il.item
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and wh.stockholding_ind = 'Y'
            and wh.repl_ind = 'Y';

      cursor C_WH_ITEM_LIST is
         select wh.wh_name
           from wh,(select distinct loc
                      from item_loc il,
                           skulist_detail sd
                     where sd.skulist= I_item
                       and sd.item = il.item
                       and il.loc= I_value) ild
          where (wh.wh = I_value
                 or wh.wh = ild.loc)
            and wh.stockholding_ind = 'Y'
            and wh.repl_ind = 'Y';

   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_WH_ITEM2',
                              'WH',
                              I_value);
            open C_WH_ITEM2;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_WH_ITEM2',
                              'WH',
                              I_value);
            fetch C_WH_ITEM2 into O_value_desc;
            if C_WH_ITEM2%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_WH_ITEM2',
                              'WH',
                              I_value);
            close C_WH_ITEM2;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_WH_ITEM',
                              'WH',
                              I_value);
            open C_WH_ITEM;
            SQL_LIB.SET_MARK ('FETCH',
                              'C_WH_ITEM',
                              'WH',
                              I_value);
            fetch C_WH_ITEM into O_value_desc;
            if C_WH_ITEM%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;
            SQL_LIB.SET_MARK ('CLOSE',
                              'C_WH_ITEM',
                              'WH',
                              I_value);
            close C_WH_ITEM;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_WH_ITEM_LIST',
                           'WH',
                           I_value);
         open C_WH_ITEM_LIST;
         SQL_LIB.SET_MARK ('FETCH',
                           'C_WH_ITEM_LIST',
                           'WH',
                           I_value);
         fetch C_WH_ITEM_LIST into O_value_desc;
         if C_WH_ITEM_LIST%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;
         SQL_LIB.SET_MARK ('CLOSE',
                           'C_WH_ITEM_LIST',
                           'WH',
                           I_value);
         close C_WH_ITEM_LIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END WAREHOUSE;
----------------------------------------------------------------------------
   FUNCTION LOC_LIST_WH (O_error_message IN OUT VARCHAR2,
                         I_item_level    IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                         I_tran_level    IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                         I_item          IN     ITEM_MASTER.ITEM%TYPE,
                         I_value         IN     VARCHAR2,
                         O_value_desc    IN OUT VARCHAR2,
                         O_exist_ind     IN OUT BOOLEAN)
      return BOOLEAN is

      L_program VARCHAR2(60)  := 'ITEM_LOC_GROUP_VALIDATE_SQL.LOC_LIST_WH';

      CURSOR C_LOC_LIST_WH_ITEM is
         select distinct llh.loc_list_desc
           from loc_list_head llh,
                loc_list_detail lld,
                item_loc il,
                wh w
          where llh.loc_list = lld.loc_list
            and w.wh = il.loc
            and w.stockholding_ind = 'Y'
            and w.repl_ind = 'Y'
            and llh.loc_list = I_value
            and il.item = I_item
            and (lld.location = il.loc or lld.location = w.physical_wh)
            and il.status = 'A';

      CURSOR C_LOC_LIST_WH_ITEM2 IS
         select distinct h.loc_list_desc
           from loc_list_head h,
                loc_list_detail d,
                item_loc il,
                wh w
          where h.loc_list = d.loc_list
            and w.wh = il.loc
            and w.stockholding_ind = 'Y'
            and w.repl_ind = 'Y'
            and h.loc_list = I_value
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and (d.location = il.loc or d.location = w.physical_wh)
            and il.status = 'A';

      CURSOR C_LOC_LIST_WH_ITEMLIST IS
         select llh.loc_list_desc
           from loc_list_head llh,
                loc_list_detail lld,
                wh w,
                item_loc il,
                skulist_detail sd
          where llh.loc_list = I_value
            and llh.loc_list = lld.loc_list
            and (lld.location = il.loc or lld.location = w.physical_wh)
            and w.wh = il.loc
            and w.stockholding_ind = 'Y'
            and w.repl_ind = 'Y'
            and sd.skulist = I_item
            and il.item = sd.item
            and il.status = 'A';

   BEGIN

      if (I_item_level != 0) then
         if (I_item_level < I_tran_level) then
            open C_LOC_LIST_WH_ITEM2;
            fetch C_LOC_LIST_WH_ITEM2 into O_value_desc;
            if (C_LOC_LIST_WH_ITEM2%FOUND) then
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            else
               O_exist_ind := FALSE;
            end if;
            close C_LOC_LIST_WH_ITEM2;
         elsif (I_item_level >= I_tran_level) then
            open C_LOC_LIST_WH_ITEM;
            fetch C_LOC_LIST_WH_ITEM into O_value_desc;
            if (C_LOC_LIST_WH_ITEM%FOUND) then
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            else
               O_exist_ind := FALSE;
            end if;
            close C_LOC_LIST_WH_ITEM;
         end if;
      else
         open C_LOC_LIST_WH_ITEMLIST;
         fetch C_LOC_LIST_WH_ITEMLIST into O_value_desc;
         if (C_LOC_LIST_WH_ITEMLIST%FOUND) then
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         else
            O_exist_ind := FALSE;
         end if;
         close C_LOC_LIST_WH_ITEMLIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END LOC_LIST_WH;
   ----------------------------------------------------------------------------
   FUNCTION LOC_LIST_ST (O_error_message IN OUT VARCHAR2,
                         I_item_level    IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                         I_tran_level    IN     ITEM_MASTER.TRAN_LEVEL%TYPE,
                         I_item          IN     ITEM_MASTER.ITEM%TYPE,
                         I_value         IN     VARCHAR2,
                         O_value_desc    IN OUT VARCHAR2,
                         O_exist_ind     IN OUT BOOLEAN)
      return BOOLEAN is

      L_program VARCHAR2(60)  := 'ITEM_LOC_GROUP_VALIDATE_SQL.LOC_LIST_ST';

      CURSOR C_LOC_LIST_ST_ITEM IS
         select h.loc_list_desc
           from loc_list_head h,
                loc_list_detail d,
                item_loc il,
                store s
          where h.loc_list = d.loc_list
            and h.loc_list = I_value
            and d.loc_type = 'S'
            and d.location = il.loc
            and s.store = il.loc
            and s.stockholding_ind = 'Y'
            and il.item = I_item
            and il.status = 'A';

      CURSOR C_LOC_LIST_ST_ITEM2 IS
         select distinct h.loc_list_desc
           from loc_list_head h,
                loc_list_detail d,
                item_loc il,
                store s
          where h.loc_list = I_value
            and h.loc_list = d.loc_list
            and d.location = il.loc
            and s.store = il.loc
            and s.stockholding_ind = 'Y'
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and il.status = 'A';

      CURSOR C_LOC_LIST_ST_ITEMLIST IS
         select distinct llh.loc_list_desc
           from loc_list_head llh,
                loc_list_detail lld,
                store s,
                item_loc il,
                skulist_detail sd
          where llh.loc_list = I_value
            and llh.loc_list = lld.loc_list
            and lld.location = s.store
            and lld.location = il.loc
            and s.stockholding_ind = 'Y'
            and sd.skulist = I_item
            and il.item = sd.item
            and il.status = 'A';


   BEGIN

      if (I_item_level != 0) then
         if (I_item_level < I_tran_level) then
            open C_LOC_LIST_ST_ITEM2;
            fetch C_LOC_LIST_ST_ITEM2 into O_value_desc;
            if (C_LOC_LIST_ST_ITEM2%FOUND) then
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            else
               O_exist_ind := FALSE;
            end if;
            close C_LOC_LIST_ST_ITEM2;
         elsif (I_item_level >= I_tran_level) then
            open C_LOC_LIST_ST_ITEM;
            fetch C_LOC_LIST_ST_ITEM into O_value_desc;
            if (C_LOC_LIST_ST_ITEM%FOUND) then
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            else
               O_exist_ind := FALSE;
            end if;
            close C_LOC_LIST_ST_ITEM;
         end if;
      else
         open C_LOC_LIST_ST_ITEMLIST;
         fetch C_LOC_LIST_ST_ITEMLIST into O_value_desc;
         if (C_LOC_LIST_ST_ITEMLIST%FOUND) then
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         else
            O_exist_ind := FALSE;
         end if;
         close C_LOC_LIST_ST_ITEMLIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END LOC_LIST_ST;
----------------------------------------------------------------------------
   FUNCTION AREAS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                  I_item_level      IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                  I_tran_level      IN       ITEM_MASTER.TRAN_LEVEL%TYPE,
                  I_item            IN       ITEM_MASTER.ITEM%TYPE,
                  I_value           IN       AREA.AREA%TYPE,
                  O_value_desc      IN OUT   AREA.AREA_NAME%TYPE,
                  O_exist_ind       IN OUT   BOOLEAN)
      return BOOLEAN is

      L_program      VARCHAR2(60) := 'ITEM_LOC_GROUP_VALIDATE_SQL.AREAS';

      cursor C_AREA_ITEM is
         select distinct a.area_name
           from area a,
                store s,
                store_hierarchy sh,
                item_loc il
          where sh.area = a.area
            and s.store = sh.store
            and il.loc = s.store
            and s.stockholding_ind = 'Y'
            and a.area = I_value
            and il.item = I_item
            and il.status = 'A';

      cursor C_AREA_ITEM2 is
         select distinct a.area_name
           from area a,
                store s,
                store_hierarchy sh,
                item_master im,
                item_loc il
          where a.area = sh.area
            and sh.store = s.store
            and il.loc = s.store
            and im.item = il.item
            and s.stockholding_ind = 'Y'
            and im.item_level = I_tran_level
            and (il.item_parent = I_item or
                 il.item_grandparent = I_item)
            and a.area = I_value
            and il.status = 'A';

      cursor C_AREA_ITEM_LIST is
         select distinct a.area_name
           from area a,
                store_hierarchy sh,
                store s
          where sh.area = a.area
            and s.store = sh.store
            and s.stockholding_ind = 'Y'
            and a.area = I_value;

   BEGIN
      if I_item_level != 0 then
         if I_item_level < I_tran_level then
            SQL_LIB.SET_MARK ('OPEN',
                              'C_AREA_ITEM2',
                              'AREA',
                              I_value);
            open C_AREA_ITEM2;

            SQL_LIB.SET_MARK ('FETCH',
                              'C_AREA_ITEM2',
                              'AREA',
                              I_value);
            fetch C_AREA_ITEM2 into O_value_desc;

            if C_AREA_ITEM2%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;

            SQL_LIB.SET_MARK ('CLOSE',
                              'C_AREA_ITEM2',
                              'AREA',
                              I_value);
            close C_AREA_ITEM2;
         else
            SQL_LIB.SET_MARK ('OPEN',
                              'C_AREA_ITEM',
                              'AREA',
                              I_value);
            open C_AREA_ITEM;

            SQL_LIB.SET_MARK ('FETCH',
                              'C_AREA_ITEM',
                              'AREA',
                              I_value);
            fetch C_AREA_ITEM into O_value_desc;

            if C_AREA_ITEM%NOTFOUND then
               O_exist_ind := FALSE;
            else
               O_exist_ind := TRUE;
               if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                         O_value_desc,
                                         O_error_message) = FALSE then
                  return FALSE;
               end if;
            end if;

            SQL_LIB.SET_MARK ('CLOSE',
                              'C_AREA_ITEM',
                              'AREA',
                              I_value);
            close C_AREA_ITEM;
         end if;
      else
         SQL_LIB.SET_MARK ('OPEN',
                           'C_AREA_ITEM_LIST',
                           'AREA',
                           I_value);
         open C_AREA_ITEM_LIST;

         SQL_LIB.SET_MARK ('FETCH',
                           'C_AREA_ITEM_LIST',
                           'AREA',
                           I_value);
         fetch C_AREA_ITEM_LIST into O_value_desc;

         if C_AREA_ITEM_LIST%NOTFOUND then
            O_exist_ind := FALSE;
         else
            O_exist_ind := TRUE;
            if LANGUAGE_SQL.TRANSLATE(O_value_desc,
                                      O_value_desc,
                                      O_error_message) = FALSE then
               return FALSE;
            end if;
         end if;

         SQL_LIB.SET_MARK ('CLOSE',
                           'C_AREA_ITEM_LIST',
                           'AREA',
                           I_value);
         close C_AREA_ITEM_LIST;
      end if;
      return TRUE;

   EXCEPTION
      when OTHERS then
         O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END AREAS;
--------------------------------------------------------------------------
END;
/

