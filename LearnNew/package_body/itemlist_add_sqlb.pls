CREATE OR REPLACE PACKAGE BODY ITEMLIST_ADD_SQL AS
-----------------------------------------------------------------------------------------------------
-- Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date:    26-Jun-2007
-- Mod Ref:     Mod number. 365b1
-- Mod Details: Included Item_type parameter
--              Appeneded SKULIST_ADD function with Item type parameter.
-----------------------------------------------------------------------------------------------------
-- Mod By:      Chandru, chandrashekaran.natarajan@in.tesco.com
-- Mod Date:    11-Nov-2009
-- Mod Ref:     CR208 (Phase3.5b)
-- Mod Details: Two new functions TSL_POPULATE_TEMP and TSL_CREATE_NEW_ITEMLIST added,
--              existing function SKULIST_ADD modified
-----------------------------------------------------------------------------------------------------
-- Mod By     : Usha Patil, usha.patil@in.tesco.com
-- Mod Date   : 22-Jan-2010
-- Mod Ref    : NBS00016005
-- Mod Details: Modified the function SKULIST_ADD to add the items to the list based on filter criteria.
-----------------------------------------------------------------------------------------------------
-- Name:    SKULIST_ADD
-- Purpose: Inserts all styles or SKUs found given the specified criteria
--          counts and the number of styles or SKUs in the SKU list.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 15-Dec-2009
-- Mod Ref    : DefNBS015640
-- Mod Details: Removed the function TSL_CREATE_NEW_ITEMLIST and has been shifted to ITEMLIST_ATTRIB_SQL
--              Package.
-----------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 22-Dec-2009
-- Mod Ref    : DefNBS015747
-- Mod Details: Modified the function SKULIST_ADD with the new parameter.
-----------------------------------------------------------------------------------------------------
-- Modified by : Usha Patil, usha.patil@in.tesco.com
-- Date        : 19-Jul-2010
-- Mod Ref     : CR288C
-- Mod Details : Modified the function SKULIST_ADD with the new parameter.
------------------------------------------------------------------------------------------------------
-- Mod By     : JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 23-Sep-2010
-- Mod Ref    : PrfNBS019234
-- Mod Details: Modified the queries which are using USER_TAB_COLUMNS table to improve the performance.
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By     : Merlyn Mathew, merlyn.mathew@in.tesco.com
-- Mod Date   : 11-Nov-2010
-- Mod Ref    : CR332
-- Mod Details: Modified the function SKULIST_ADD to add the items to the list based on another criteria,
--              Style Ref Code.
-----------------------------------------------------------------------------------------------------

FUNCTION SKULIST_ADD(I_itemlist         IN     SKULIST_HEAD.SKULIST%TYPE,
                     I_pack_ind         IN     ITEM_MASTER.PACK_IND%TYPE,
                     I_item             IN     ITEM_MASTER.ITEM%TYPE,
                     I_item_parent      IN     SKULIST_CRITERIA.ITEM_PARENT%TYPE,
                     I_item_grandparent IN     SKULIST_CRITERIA.ITEM_GRANDPARENT%TYPE,
                     I_dept             IN     SKULIST_CRITERIA.DEPT%TYPE,
                     I_class            IN     SKULIST_CRITERIA.CLASS%TYPE,
                     I_subclass         IN     SKULIST_CRITERIA.SUBCLASS%TYPE,
                     I_supplier         IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                     I_zone_group_id    IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                     I_diff_1           IN     SKULIST_CRITERIA.DIFF_1%TYPE,
                     I_diff_2           IN     SKULIST_CRITERIA.DIFF_2%TYPE,
                     I_diff_3           IN     SKULIST_CRITERIA.DIFF_3%TYPE,
                     I_diff_4           IN     SKULIST_CRITERIA.DIFF_4%TYPE,
                     I_uda_id           IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                     I_uda_value        IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                     I_uda_max_date     IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                     I_uda_min_date     IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                     I_season_id        IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                     I_phase_id         IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                     I_count_ind        IN     VARCHAR2,
                     I_no_add           IN     VARCHAR2,
                     I_item_level       IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                     O_no_items         IN OUT NUMBER,
                     O_error_message    IN OUT VARCHAR2)
   RETURN BOOLEAN is
   L_program               VARCHAR2(64) := 'ITEMLIST_ADD_SQL.SKULIST_ADD';
   L_item                  SKULIST_DETAIL.ITEM%TYPE;
   L_item_exist_tpglist    VARCHAR2(1);
   L_new_itemlist	   SKULIST_HEAD.SKULIST%TYPE;
   L_itemlist_type         SKULIST_HEAD.TAX_PROD_GROUP_IND%TYPE;
   L_skulist_desc          SKULIST_HEAD.SKULIST_DESC%TYPE;
   L_create_date           SKULIST_HEAD.CREATE_DATE%TYPE;
   L_last_rebuild_date     SKULIST_HEAD.LAST_REBUILD_DATE%TYPE;
   L_create_id             SKULIST_HEAD.CREATE_ID%TYPE;
   L_static_ind            SKULIST_HEAD.STATIC_IND%TYPE;
   L_no_add_ind            SKULIST_HEAD.STATIC_IND%TYPE;
   L_comment_desc          SKULIST_HEAD.COMMENT_DESC%TYPE;
   L_username              USER_ROLE_PRIVS.USERNAME%TYPE := USER;
   L_vdate                 PERIOD.VDATE%TYPE := GET_VDATE;
   L_tax_code_exists       VARCHAR2(1) := 'Y';
   L_exists                VARCHAR2(1) := 'Y';
   L_dummy                 SKULIST_HEAD.SKULIST%TYPE;
   L_select                VARCHAR2(50);
   L_from_clause           VARCHAR2(200);
   L_between               VARCHAR2(50);
   L_exist_1               VARCHAR2(3000);
   L_exist_2               VARCHAR2(3000);
   L_dummy_where           VARCHAR2(3000);
   L_where_clause          VARCHAR2(3000);
   L_statement             VARCHAR2(3250);
   TYPE ORD_CURSOR is      REF CURSOR;
   C_ITEM                  ORD_CURSOR;
   L_data_level_security_ind  SYSTEM_OPTIONS.DATA_LEVEL_SECURITY_IND%TYPE;
   cursor C_TAX_CODES_EXIST is
      select 'x'
       from product_tax_code
      where item = L_item
        and ((start_date <= L_vdate + 1
            and (end_date is NULL
            or end_date > L_vdate))
         or start_date > L_vdate + 1);
   cursor C_SKULIST_DETAIL_EXISTS is
      select 'x'
       from skulist_detail
      where skulist = I_itemlist
        and item = L_item;
   cursor C_DATA_LEVEL_SECURITY is
      SELECT data_level_security_ind
        FROM system_options;
BEGIN
   if I_itemlist is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_itemlist',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   L_new_itemlist := I_itemlist;
   L_no_add_ind   := I_no_add;
   ---
   if ITEMLIST_ATTRIB_SQL.GET_HEADER_INFO(O_error_message,
                                          L_skulist_desc,
                                          L_create_date,
                                          L_last_rebuild_date,
                                          L_create_id,
                                          L_static_ind,
                                          L_comment_desc,
                                          L_itemlist_type,
                                          I_itemlist) = FALSE then
      return FALSE;
   end if;
   ---
   L_select := 'select ima.item ';
   L_from_clause := 'from item_master ima';
   L_where_clause := ' where ima.item_level <= ima.tran_level ';
   open C_DATA_LEVEL_SECURITY;
   fetch C_DATA_LEVEL_SECURITY INTO L_data_level_security_ind;
   close C_DATA_LEVEL_SECURITY;
   if L_data_level_security_ind = 'Y' then
      L_from_clause := L_from_clause || ', skulist_dept sld';
      L_where_clause := L_where_clause || ' and sld.skulist = ' || TO_CHAR(L_new_itemlist) ||
                        ' and ima.dept = sld.dept ';
   end if;
   if I_item_parent is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        '((ima.item = ''' || I_item_parent || ''') or ' ||
                        '(ima.item_parent = '''||I_item_parent||''')) ';
   end if;
   if I_item_grandparent is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        '((ima.item = '''||I_item_grandparent||''') or ' ||
                        '(ima.item_parent = '''||I_item_grandparent||''') or ' ||
                        '(ima.item_grandparent = '''||I_item_grandparent||''')) ';
   end if;
   if I_item is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item = '''||I_item||'''';
   end if;
   if I_dept is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.dept = '||I_dept;
   end if;
   if I_class is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.class = '||I_class;
   end if;
   if I_subclass is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.subclass = '||I_subclass;
   end if;
   if I_diff_1 is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        '(ima.diff_1   = ''' ||I_diff_1|| ''' or ' ||
                        '(ima.diff_2   = ''' ||I_diff_1|| ''') or ' ||
                        '(ima.diff_3   = ''' ||I_diff_1|| ''') or ' ||
                        '(ima.diff_4   = ''' ||I_diff_1|| '''))';
      if I_diff_2 is NOT NULL then
         L_where_clause := L_where_clause || ' and ' ||
                        '(ima.diff_2   = ''' ||I_diff_2|| ''' or ' ||
                        '(ima.diff_3   = ''' ||I_diff_2|| ''') or ' ||
                        '(ima.diff_4   = ''' ||I_diff_2|| ''') or ' ||
                        '(ima.diff_1   = ''' ||I_diff_2|| '''))';
         if I_diff_3 is NOT NULL then
            L_where_clause := L_where_clause || ' and ' ||
                        '(ima.diff_3   = ''' ||I_diff_3|| ''' or ' ||
                        '(ima.diff_4   = ''' ||I_diff_3|| ''') or ' ||
                        '(ima.diff_1   = ''' ||I_diff_3|| ''') or ' ||
                        '(ima.diff_2   = ''' ||I_diff_3|| '''))';
            if I_diff_4 is NOT NULL then
               L_where_clause := L_where_clause || ' and ' ||
                        '(ima.diff_4   = ''' ||I_diff_4|| ''' or ' ||
                        '(ima.diff_1   = ''' ||I_diff_4|| ''') or ' ||
                        '(ima.diff_2   = ''' ||I_diff_4|| ''') or ' ||
                        '(ima.diff_3   = ''' ||I_diff_4|| '''))';
            end if;
         end if;
      end if;
   end if;
   if I_zone_group_id is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.retail_zone_group_id = '||I_zone_group_id;
   end if;
   if I_pack_ind is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.pack_ind = '''||I_pack_ind||'''';
   end if;
   if I_item_level is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item_level = '||I_item_level;
   end if;
   if I_supplier is NOT NULL then
      L_from_clause := L_from_clause ||
                       ', item_supplier isu';
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item = isu.item and ' ||
                        'isu.supplier = '||I_supplier;
   end if;
   if I_season_id is NOT NULL then
      L_from_clause := L_from_clause ||
                       ', item_seasons ise';
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item = ise.item and ' ||
                        'ise.season_id = '||I_season_id||' and ' ||
                        'ise.phase_id = nvl('||I_phase_id||', ise.phase_id)';
   end if;
   if I_uda_id is NOT NULL then
      L_dummy_where := L_where_clause;
      L_exist_1 := '(exists (select 1' ||
                             ' from uda_item_lov uil' ||
                            ' where ima.item = uil.item and '||
                                   'uil.uda_id = '||I_uda_id;
      L_exist_2 :=  'exists (select 1'||
                             ' from uda_item_date ud'||
                            ' where ima.item = ud.item and '||
                                   'ud.uda_id = '||I_uda_id;
      L_between := ') or ';
      L_where_clause := L_where_clause || ' and ' || L_exist_1 ||
                        L_between || L_exist_2 || '))';
   end if;
   if I_uda_value is NOT NULL then
      L_exist_1 := L_exist_1 || ' and ' || ' uil.uda_value = '||I_uda_value;
      L_where_clause := L_dummy_where || ' and ' || L_exist_1 ||
                        L_between || L_exist_2 || '))';
   end if;
   if I_uda_min_date is NOT NULL then
      L_exist_2 := L_exist_2 || ' and ' || ' ud.uda_date >= '''||I_uda_min_date||'''';
      L_where_clause := L_dummy_where || ' and ' || L_exist_1 ||
                        L_between || L_exist_2 || '))';
      end if;
   if I_uda_max_date is NOT NULL then
      L_exist_2 := L_exist_2 || ' and ' || ' ud.uda_date <= '''||I_uda_max_date||'''';
      L_where_clause := L_dummy_where || ' and ' || L_exist_1 ||
                        L_between || L_exist_2 || '))';
   end if;
   L_statement := L_select || L_from_clause || L_where_clause;
   EXECUTE IMMEDIATE L_statement;
   open C_ITEM for L_statement;
   LOOP
      fetch C_ITEM into L_item;
      EXIT WHEN C_ITEM%NOTFOUND;
      L_tax_code_exists := 'N';
      L_exists := 'N';
      if L_itemlist_type = 'Y' then
         if ITEM_IN_TPG_ITEMLIST(O_error_message,
                                 L_item,
                                 L_no_add_ind,
                                 L_new_itemlist,
                                 L_dummy,
                                 L_item_exist_tpglist) = FALSE then
            return FALSE;
         end if;
         ---
         if L_item_exist_tpglist = 'N' then
            open C_TAX_CODES_EXIST;
            fetch C_TAX_CODES_EXIST into L_tax_code_exists;
            close C_TAX_CODES_EXIST;
            if L_tax_code_exists != 'x' then
               ---
               if L_no_add_ind = 'N' then
                  open C_SKULIST_DETAIL_EXISTS;
                  fetch C_SKULIST_DETAIL_EXISTS into L_exists;
                  close C_SKULIST_DETAIL_EXISTS;
                  ---
                  if L_exists != 'x' then
                     ---
                     if ITEMLIST_ADD_SQL.INSERT_SKULIST_DETAIL(O_error_message,
                                                               I_itemlist,
                                                               L_item,
                                                               I_pack_ind) = FALSE then
                        return FALSE;
                     end if;
                     ---
                  end if;
                  ---
                  if INSERT_TPG_TAX_CODES(O_error_message,
                                          L_item,
                                          I_itemlist) = FALSE then
                     return FALSE;
                  end if;
                  ---
               end if;
               ---
            end if;
            ---
         end if;
         ---
      else
         open C_SKULIST_DETAIL_EXISTS;
         fetch C_SKULIST_DETAIL_EXISTS into L_exists;
         close C_SKULIST_DETAIL_EXISTS;
         ---
         if L_exists != 'x' then
            ---
            if ITEMLIST_ADD_SQL.INSERT_SKULIST_DETAIL(O_error_message,
                                                      I_itemlist,
                                                      L_item,
                                                      I_pack_ind) = FALSE then
               return FALSE;
            end if;
            ---
         end if;
         ---
      end if;
      ---
   END LOOP;
   close C_ITEM;
   if I_count_ind = 'Y' then
      if ITEMLIST_ATTRIB_SQL.GET_ITEM_COUNT(O_error_message,
                                            I_itemlist,
                                            O_no_items) = FALSE then
         return FALSE;
      end if;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      RETURN FALSE;
END SKULIST_ADD;
----------------------------------------------------------------
-- Function Name: SKULIST_ADD
-- Purpose: Inserts all styles or SKUs found given the specified criteria
--          counts and the number of styles or SKUs in the SKU list.
----------------------------------------------------------------
FUNCTION SKULIST_ADD(I_itemlist         IN     SKULIST_HEAD.SKULIST%TYPE,
                     I_pack_ind         IN     ITEM_MASTER.PACK_IND%TYPE,
                     I_item             IN     ITEM_MASTER.ITEM%TYPE,
                     I_item_parent      IN     SKULIST_CRITERIA.ITEM_PARENT%TYPE,
                     I_item_grandparent IN     SKULIST_CRITERIA.ITEM_GRANDPARENT%TYPE,
                     I_dept             IN     SKULIST_CRITERIA.DEPT%TYPE,
                     I_class            IN     SKULIST_CRITERIA.CLASS%TYPE,
                     I_subclass         IN     SKULIST_CRITERIA.SUBCLASS%TYPE,
                     I_supplier         IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                     I_zone_group_id    IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                     I_diff_1           IN     SKULIST_CRITERIA.DIFF_1%TYPE,
                     I_diff_2           IN     SKULIST_CRITERIA.DIFF_2%TYPE,
                     I_diff_3           IN     SKULIST_CRITERIA.DIFF_3%TYPE,
                     I_diff_4           IN     SKULIST_CRITERIA.DIFF_4%TYPE,
                     I_uda_id           IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                     I_uda_value        IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                     I_uda_max_date     IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                     I_uda_min_date     IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                     I_season_id        IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                     I_phase_id         IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                     I_count_ind        IN     VARCHAR2,
                     I_no_add           IN     VARCHAR2,
                     I_item_level       IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
-- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
                     I_tsl_item_type    IN     SKULIST_CRITERIA.TSL_ITEM_TYPE%TYPE,
                     --CR208 11-Nov-09 Chandru Begin
                     I_custom_field     IN     VARCHAR2,
                     I_value            IN     VARCHAR2,
                     --CR208 11-Nov-09 Chandru End
                     -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                     I_authorised_in    IN     ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE,
                     -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                     -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                     I_style_ref_code    IN    ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                     -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                     O_no_items         IN OUT NUMBER,
                     O_error_message    IN OUT VARCHAR2)
   return BOOLEAN is
   L_program               VARCHAR2(64) := 'ITEMLIST_ADD_SQL.SKULIST_ADD';
   L_item                  SKULIST_DETAIL.ITEM%TYPE;
   L_item_exist_tpglist    VARCHAR2(1);
   L_new_itemlist	   SKULIST_HEAD.SKULIST%TYPE;
   L_itemlist_type         SKULIST_HEAD.TAX_PROD_GROUP_IND%TYPE;
   L_skulist_desc          SKULIST_HEAD.SKULIST_DESC%TYPE;
   L_create_date           SKULIST_HEAD.CREATE_DATE%TYPE;
   L_last_rebuild_date     SKULIST_HEAD.LAST_REBUILD_DATE%TYPE;
   L_create_id             SKULIST_HEAD.CREATE_ID%TYPE;
   L_static_ind            SKULIST_HEAD.STATIC_IND%TYPE;
   L_no_add_ind            SKULIST_HEAD.STATIC_IND%TYPE;
   L_comment_desc          SKULIST_HEAD.COMMENT_DESC%TYPE;
   L_username              USER_ROLE_PRIVS.USERNAME%TYPE := USER;
   L_vdate                 PERIOD.VDATE%TYPE := GET_VDATE;
   L_tax_code_exists       VARCHAR2(1) := 'Y';
   L_exists                VARCHAR2(1) := 'Y';
   L_dummy                 SKULIST_HEAD.SKULIST%TYPE;
   L_select                VARCHAR2(50);
   L_from_clause           VARCHAR2(200);
   L_between               VARCHAR2(50);
   L_exist_1               VARCHAR2(3000);
   L_exist_2               VARCHAR2(3000);
   L_dummy_where           VARCHAR2(3000);
   L_where_clause          VARCHAR2(3000);
   L_statement             VARCHAR2(3250);
   --22-Jan-2010 Tesco HSC/Usha Patil             Defect Id: NBS00016005 Begin
   L_data_type             USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   L_date                  DATE;
   L_value                 VARCHAR2(30);
   --22-Jan-2010 Tesco HSC/Usha Patil             Defect Id: NBS00016005 End

   TYPE ORD_CURSOR is      REF CURSOR;
   C_ITEM                  ORD_CURSOR;
   L_data_level_security_ind  SYSTEM_OPTIONS.DATA_LEVEL_SECURITY_IND%TYPE;
   cursor C_TAX_CODES_EXIST is
      select 'x'
       from product_tax_code
      where item = L_item
        and ((start_date <= L_vdate + 1
            and (end_date is NULL
            or end_date > L_vdate))
         or start_date > L_vdate + 1);
   cursor C_SKULIST_DETAIL_EXISTS is
      select 'x'
       from skulist_detail
      where skulist = I_itemlist
        and item = L_item;
   cursor C_DATA_LEVEL_SECURITY is
      SELECT data_level_security_ind
        FROM system_options;
   --CR208 11-Nov-09 Chandru Begin
   cursor C_PARENT_TABLE is
      select parent_table
        from tsl_custom_fields
       where UPPER(custom_field_name) = UPPER(I_custom_field);
   L_parent_table          TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;
   --CR208 11-Nov-09 Chandru End
   --22-Jan-2010 Tesco HSC/Usha Patil             Defect Id: NBS00016005 Begin
   cursor C_DATA_TYPE is
      select data_type
        from user_tab_columns
       --23-Sep-10  JK  DefNBS019234   Begin
       where table_name  = upper(L_parent_table)
         and column_name = upper(I_custom_field);
       --23-Sep-10  JK  DefNBS019234   End
   --22-Jan-2010 Tesco HSC/Usha Patil             Defect Id: NBS00016005 End

BEGIN
   if I_itemlist is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_itemlist',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   --22-Jan-2010 Tesco HSC/Usha Patil             Defect Id: NBS00016005 Begin
   L_value := I_value;
   --22-Jan-2010 Tesco HSC/Usha Patil             Defect Id: NBS00016005 End
   ---
   L_new_itemlist := I_itemlist;
   L_no_add_ind   := I_no_add;
   ---
   if ITEMLIST_ATTRIB_SQL.GET_HEADER_INFO(O_error_message,
                                          L_skulist_desc,
                                          L_create_date,
                                          L_last_rebuild_date,
                                          L_create_id,
                                          L_static_ind,
                                          L_comment_desc,
                                          L_itemlist_type,
                                          I_itemlist) = FALSE then
      return FALSE;
   end if;
   ---
   L_select := 'select ima.item ';
   L_from_clause := 'from item_master ima';
   L_where_clause := ' where ima.item_level <= ima.tran_level ';
   open C_DATA_LEVEL_SECURITY;
   fetch C_DATA_LEVEL_SECURITY INTO L_data_level_security_ind;
   close C_DATA_LEVEL_SECURITY;
   if L_data_level_security_ind = 'Y' then
      L_from_clause := L_from_clause || ', skulist_dept sld';
      L_where_clause := L_where_clause || ' and sld.skulist = ' || TO_CHAR(L_new_itemlist) ||
                        ' and ima.dept = sld.dept ';
   end if;
   if I_item_parent is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        '((ima.item = ''' || I_item_parent || ''') or ' ||
                        '(ima.item_parent = '''||I_item_parent||''')) ';
   end if;
   if I_item_grandparent is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        '((ima.item = '''||I_item_grandparent||''') or ' ||
                        '(ima.item_parent = '''||I_item_grandparent||''') or ' ||
                        '(ima.item_grandparent = '''||I_item_grandparent||''')) ';
   end if;
   if I_item is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item = '''||I_item||'''';
   end if;
   if I_dept is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.dept = '||I_dept;
   end if;
   if I_class is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.class = '||I_class;
   end if;
   if I_subclass is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.subclass = '||I_subclass;
   end if;
   if I_diff_1 is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        '(ima.diff_1   = ''' ||I_diff_1|| ''' or ' ||
                        '(ima.diff_2   = ''' ||I_diff_1|| ''') or ' ||
                        '(ima.diff_3   = ''' ||I_diff_1|| ''') or ' ||
                        '(ima.diff_4   = ''' ||I_diff_1|| '''))';
      if I_diff_2 is NOT NULL then
         L_where_clause := L_where_clause || ' and ' ||
                        '(ima.diff_2   = ''' ||I_diff_2|| ''' or ' ||
                        '(ima.diff_3   = ''' ||I_diff_2|| ''') or ' ||
                        '(ima.diff_4   = ''' ||I_diff_2|| ''') or ' ||
                        '(ima.diff_1   = ''' ||I_diff_2|| '''))';
         if I_diff_3 is NOT NULL then
            L_where_clause := L_where_clause || ' and ' ||
                        '(ima.diff_3   = ''' ||I_diff_3|| ''' or ' ||
                        '(ima.diff_4   = ''' ||I_diff_3|| ''') or ' ||
                        '(ima.diff_1   = ''' ||I_diff_3|| ''') or ' ||
                        '(ima.diff_2   = ''' ||I_diff_3|| '''))';
            if I_diff_4 is NOT NULL then
               L_where_clause := L_where_clause || ' and ' ||
                        '(ima.diff_4   = ''' ||I_diff_4|| ''' or ' ||
                        '(ima.diff_1   = ''' ||I_diff_4|| ''') or ' ||
                        '(ima.diff_2   = ''' ||I_diff_4|| ''') or ' ||
                        '(ima.diff_3   = ''' ||I_diff_4|| '''))';
            end if;
         end if;
      end if;
   end if;
   if I_zone_group_id is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.retail_zone_group_id = '||I_zone_group_id;
   end if;
   if I_pack_ind is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.pack_ind = '''||I_pack_ind||'''';
   end if;
   if I_item_level is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item_level = '||I_item_level;
   end if;
   if I_supplier is NOT NULL then
      L_from_clause := L_from_clause ||
                       ', item_supplier isu';
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item = isu.item and ' ||
                        'isu.supplier = '||I_supplier;
   end if;
   if I_season_id is NOT NULL then
      L_from_clause := L_from_clause ||
                       ', item_seasons ise';
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item = ise.item and ' ||
                        'ise.season_id = '||I_season_id||' and ' ||
                        'ise.phase_id = nvl('||I_phase_id||', ise.phase_id)';
   end if;
   if I_uda_id is NOT NULL then
      L_dummy_where := L_where_clause;
      L_exist_1 := '(exists (select 1' ||
                             ' from uda_item_lov uil' ||
                            ' where ima.item = uil.item and '||
                                   'uil.uda_id = '||I_uda_id;
      L_exist_2 :=  'exists (select 1'||
                             ' from uda_item_date ud'||
                            ' where ima.item = ud.item and '||
                                   'ud.uda_id = '||I_uda_id;
      L_between := ') or ';
      L_where_clause := L_where_clause || ' and ' || L_exist_1 ||
                        L_between || L_exist_2 || '))';
   end if;
   if I_uda_value is NOT NULL then
      L_exist_1 := L_exist_1 || ' and ' || ' uil.uda_value = '||I_uda_value;
      L_where_clause := L_dummy_where || ' and ' || L_exist_1 ||
                        L_between || L_exist_2 || '))';
   end if;
   if I_uda_min_date is NOT NULL then
      L_exist_2 := L_exist_2 || ' and ' || ' ud.uda_date >= '''||I_uda_min_date||'''';
      L_where_clause := L_dummy_where || ' and ' || L_exist_1 ||
                        L_between || L_exist_2 || '))';
      end if;
   if I_uda_max_date is NOT NULL then
      L_exist_2 := L_exist_2 || ' and ' || ' ud.uda_date <= '''||I_uda_max_date||'''';
      L_where_clause := L_dummy_where || ' and ' || L_exist_1 ||
                        L_between || L_exist_2 || '))';
   end if;
------------------------------------------------------------------------------------------
--  26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com  Mod 365b1 Begin
------------------------------------------------------------------------------------------
   if I_tsl_item_type = 'B' then           -- Base item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item = ima.item' ||
                        ' and ima.item_level = ima.tran_level' ||
                        ' and ima.item_level = 2 ';
   elsif I_tsl_item_type = 'V' then         -- Variant item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item != ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_tsl_item_type = 'P' then            -- Price marked
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_price_mark_ind = ''Y'' ';
   elsif I_tsl_item_type = 'S' then         -- Simple pack
      L_where_clause := L_where_clause ||
                        ' and ima.simple_pack_ind = ''Y'' ';
   --22-Dec-2009     TESCO HSC/Joy Stephen   DefNBS015747    Begin
   elsif I_tsl_item_type = 'C' then      -- Complex pack
      L_where_clause := L_where_clause ||
                        ' and ima.pack_ind = ''Y'' ' ||
                        ' and ima.simple_pack_ind = ''N'' ';
   --22-Dec-2009     TESCO HSC/Joy Stephen   DefNBS015747    End
   end if;
------------------------------------------------------------------------------------------
-- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com  Mod 365b1  End
------------------------------------------------------------------------------------------
   --CR208 11-Nov-09 Chandru Begin
   if I_custom_field is NOT NULL and
      I_value is NOT NULL then
      open C_PARENT_TABLE;
      fetch C_PARENT_TABLE into L_parent_table;
      close C_PARENT_TABLE;
      --22-Jan-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016005 Begin
      --Fetching the values from C_DATA_TYPE
      SQL_LIB.SET_MARK('OPEN',
                       'C_DATA_TYPE',
                       'USER_TAB_COLUMNS',
                       'table_name: '||L_parent_table);
      open C_DATA_TYPE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_DATA_TYPE',
                       'USER_TAB_COLUMNS',
                       'table_name: '||L_parent_table);
      fetch C_DATA_TYPE into L_data_type;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DATA_TYPE',
                       'USER_TAB_COLUMNS',
                       'table_name: '||L_parent_table);
      close C_DATA_TYPE;

      if L_data_type = 'DATE' then
         L_date := TO_DATE(L_value, 'DD-MM-YYYY');
         L_value := L_date;
      end if;
      --22-Jan-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016005 End

      L_from_clause  := L_from_clause || ', '|| L_parent_table  ||' tsltab ';
      --22-Jan-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016005 Begin
      --Modified I_value to L_value and added 'and' condition
      L_where_clause := L_where_clause || ' and tsltab.'||I_custom_field||' =  '''||L_value||''''
      ||' and ima.item = tsltab.item';
      --22-Jan-2010 Tesco HSC/Usha Patil               Defect Id: NBS00016005 End
  end if;
   --CR208 11-Nov-09 Chandru End
   -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if I_authorised_in is NOT NULL then
      L_where_clause := L_where_clause||' and ima.tsl_country_auth_ind = '''|| I_authorised_in ||'''';
   end if;
   -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
   if I_style_ref_code is NOT NULL then
      L_where_clause := L_where_clause||' and ima.item_desc_secondary = '''|| I_style_ref_code ||'''';
   end if;
   -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
   L_statement := L_select || L_from_clause || L_where_clause;
   EXECUTE IMMEDIATE L_statement;
   open C_ITEM for L_statement;
   LOOP
      fetch C_ITEM into L_item;
      EXIT WHEN C_ITEM%NOTFOUND;
      L_tax_code_exists := 'N';
      L_exists := 'N';
      if L_itemlist_type = 'Y' then
         if ITEM_IN_TPG_ITEMLIST(O_error_message,
                                 L_item,
                                 L_no_add_ind,
                                 L_new_itemlist,
                                 L_dummy,
                                 L_item_exist_tpglist) = FALSE then
            return FALSE;
         end if;
         ---
         if L_item_exist_tpglist = 'N' then
            open C_TAX_CODES_EXIST;
            fetch C_TAX_CODES_EXIST into L_tax_code_exists;
            close C_TAX_CODES_EXIST;
            if L_tax_code_exists != 'x' then
               ---
               if L_no_add_ind = 'N' then
                  open C_SKULIST_DETAIL_EXISTS;
                  fetch C_SKULIST_DETAIL_EXISTS into L_exists;
                  close C_SKULIST_DETAIL_EXISTS;
                  ---
                  if L_exists != 'x' then
                     ---
                     if ITEMLIST_ADD_SQL.INSERT_SKULIST_DETAIL(O_error_message,
                                                               I_itemlist,
                                                               L_item,
                                                               I_pack_ind) = FALSE then
                        return FALSE;
                     end if;
                     ---
                  end if;
                  ---
                  if INSERT_TPG_TAX_CODES(O_error_message,
                                          L_item,
                                          I_itemlist) = FALSE then
                     return FALSE;
                  end if;
                  ---
               end if;
               ---
            end if;
            ---
         end if;
         ---
      else
         open C_SKULIST_DETAIL_EXISTS;
         fetch C_SKULIST_DETAIL_EXISTS into L_exists;
         close C_SKULIST_DETAIL_EXISTS;
         ---
         if L_exists != 'x' then
            ---
            if ITEMLIST_ADD_SQL.INSERT_SKULIST_DETAIL(O_error_message,
                                                      I_itemlist,
                                                      L_item,
                                                      I_pack_ind) = FALSE then
               return FALSE;
            end if;
            ---
         end if;
         ---
      end if;
      ---
   END LOOP;
   close C_ITEM;
   if I_count_ind = 'Y' then
      if ITEMLIST_ATTRIB_SQL.GET_ITEM_COUNT(O_error_message,
                                            I_itemlist,
                                            O_no_items) = FALSE then
         return FALSE;
      end if;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      RETURN FALSE;
END SKULIST_ADD;
----------------------------------------------------------------
FUNCTION ITEM_IN_TPG_ITEMLIST(O_error_message  IN OUT  VARCHAR2,
                              I_item           IN      ITEM_MASTER.ITEM%TYPE,
                              I_no_add_ind     IN      VARCHAR2,
                              I_skulist        IN      SKULIST_HEAD.SKULIST%TYPE,
                              O_skulist        IN OUT  SKULIST_HEAD.SKULIST%TYPE,
                              O_exists         IN OUT  VARCHAR2)
   RETURN BOOLEAN is
   L_skulist              SKULIST_HEAD.SKULIST%TYPE;
   L_new_skulist          SKULIST_HEAD.SKULIST%TYPE;
   L_program              VARCHAR2(64) := 'ITEMLST_ADD_SQL.ITEM_IN_TPG_ITEMLIST';
   L_exists               VARCHAR2(1);
   L_no_add_ind           SKULIST_HEAD.STATIC_IND%TYPE;
   cursor C_ITEM_IN_TPG_ITEMLIST is
      select skulist_head.skulist
        from skulist_head, skulist_detail sd
       where skulist_head.skulist = sd.skulist
         and sd.item = I_item
         and skulist_head.tax_prod_group_ind = 'Y'
         and sd.skulist != I_skulist
         and not exists (select 'x'
                       from itemlist_tax_temp itt
                      where itt.item = I_item
                        and itt.itemlist = I_skulist);
   cursor C_ITEM_TAX_CODES is
      select 'x'
        from product_tax_code
       where item = I_item
         and item not in (select item from skulist_detail
                           where skulist_detail.skulist = I_skulist)
         and not exists (select 'x'
                       from itemlist_tax_temp itt
                      where itt.item = I_item
                        and itt.itemlist = I_skulist);
   cursor C_CHECK_ITEMLIST is
      select 'x'
        from skulist_detail
       where (item = I_item
         and skulist = L_new_skulist)
          or exists (select 'x'
                       from itemlist_tax_temp itt
                      where itt.item = I_item
                        and itt.itemlist = L_new_skulist);
BEGIN
   L_no_add_ind := I_no_add_ind;
   L_new_skulist := I_skulist;
   O_exists := 'N';
   SQL_LIB.SET_MARK('OPEN','C_ITEM_IN_TPG_ITEMLIST','SKULIST_DETAIL','ITEM: '||(I_item));
   open C_ITEM_IN_TPG_ITEMLIST;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_IN_TPG_ITEMLIST','SKULIST_DETAIL','ITEM: '||(I_item));
   fetch C_ITEM_IN_TPG_ITEMLIST into L_skulist;
   if C_ITEM_IN_TPG_ITEMLIST%FOUND then
      O_exists := 'Y';
      O_skulist := L_skulist;
      if L_no_add_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN',NULL,'ITEMLIST_TAX_TEMP','ITEMLIST: '||to_char(L_skulist));
         insert into itemlist_tax_temp(item,
                                      itemlist,
                                      TPG_itemlist,
                                      tax_code_ind)
                               values(I_item,
                                      L_new_skulist,
                                      L_skulist,
                                      'Y');
      end if;
   elsif L_no_add_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_ITEM_TAX_CODES','SKULIST_DETAIL','ITEM: '||(I_item));
      open C_ITEM_TAX_CODES;
      SQL_LIB.SET_MARK('FETCH','C_ITEM_TAX_CODES','SKULIST_DETAIL','ITEM: '||(I_item));
      fetch C_ITEM_TAX_CODES into L_exists;
      if C_ITEM_TAX_CODES%FOUND then
         O_exists := 'Y';
           insert into itemlist_tax_temp(item,
                                         itemlist,
                                         TPG_itemlist,
                                         tax_code_ind)
                                  VALUES(I_item,
                                         L_new_skulist,
                                         NULL,
                                         'Y');
      else
            SQL_LIB.SET_MARK('OPEN','C_CHECK_ITEMLIST','SKULIST_DETAIL','ITEM: '||(I_item));
            open C_CHECK_ITEMLIST;
            SQL_LIB.SET_MARK('FETCH','C_CHECK_ITEMLIST','SKULIST_DETAIL','ITEM: '||(I_item));
            fetch C_CHECK_ITEMLIST into L_exists;
            if C_CHECK_ITEMLIST%NOTFOUND then
               insert into itemlist_tax_temp(item,
                                            itemlist,
                                            TPG_itemlist,
                                            tax_code_ind)
                                     VALUES(I_item,
                                            L_new_skulist,
                                            NULL,
                                            'N');
            end if;
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEMLIST','SKULIST_DETAIL','ITEM: '||(I_item));
            close C_CHECK_ITEMLIST;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_ITEM_TAX_CODES','PRODUCT_TAX_CODES','ITEM: '||(I_item));
      close C_ITEM_TAX_CODES;
   else
      O_exists := 'N';
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_IN_TPG_ITEMLIST','SKULIST_DETAIL','ITEM: '||(I_item));
   close C_ITEM_IN_TPG_ITEMLIST;
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END ITEM_IN_TPG_ITEMLIST;
----------------------------------------------------------------
FUNCTION INSERT_TPG_TAX_CODES(O_error_message  IN OUT  VARCHAR2,
                              I_item           IN      ITEM_MASTER.ITEM%TYPE,
                              I_skulist        IN      SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   L_skulist              SKULIST_HEAD.SKULIST%TYPE;
   L_program              VARCHAR2(64) := 'ITEMLIST_ADD_SQL.INSERT_TPG_TAX_CODES';
   L_seq_no               PRODUCT_TAX_CODE.SEQ_NO%TYPE;
   L_item                 PRODUCT_TAX_CODE.ITEM%TYPE;
   L_user_name            VARCHAR2(30)  := SYS_CONTEXT('USERENV','SESSION_USER');
   L_vdate                PERIOD.VDATE%TYPE := GET_VDATE;
   L_error_message        VARCHAR2(255);
   L_start_date           PERIOD.VDATE%TYPE;
   L_end_date             PERIOD.VDATE%TYPE;
   L_sku_on_list_exists   VARCHAR2(1)  := 'N';
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   cursor C_ITEM is
      select item
        from skulist_detail
       where skulist = I_skulist
         and item    != I_item;
   cursor C_SKU_ON_LIST is
      select 'Y'
        from itemlist_taxcode_temp
       where itemlist = I_skulist;
   cursor C_INSERT_TAX_CODES is
    select seq_no,
           dept,
           item,
           tax_jurisdiction_id,
           tax_type_id,
           start_date,
           end_date
      from product_tax_code,
           period
     where item = L_item
        and ((start_date <= vdate + 1
            and (end_date is NULL
            or end_date > vdate))
         or start_date > vdate +1);
   cursor C_INSERT_TAX_CODES_ILTCTEMP is
    select tax_jurisdiction_id,
           tax_type_id,
           start_date,
           end_date
      from itemlist_taxcode_temp
     where itemlist = I_skulist;
   cursor C_TAXCODE_TEMP_LOCK is
      select 'x'
        from ITEMLIST_TAXCODE_TEMP
       where itemlist = I_skulist
      for update nowait;
BEGIN
   open C_ITEM;
   fetch C_ITEM into L_item;
   close C_ITEM;
   ---
   if NEXT_PRODUCT_TAX_CODE_SEQ(L_seq_no,
                             L_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   open C_SKU_ON_LIST;
   fetch C_SKU_ON_LIST into L_sku_on_list_exists;
   close C_SKU_ON_LIST;
   ---
   if L_item is NOT NULL and L_sku_on_list_exists = 'N' then
      ---
      ---
      FOR L_tax_rec in C_INSERT_TAX_CODES LOOP
         ---
         if NEXT_PRODUCT_TAX_CODE_SEQ(L_seq_no,
                                      O_error_message)= FALSE then
            return FALSE;
         end if;
         ---
         if L_tax_rec.start_date > L_vdate + 2 then
            L_start_date := L_tax_rec.start_date;
         else
            L_start_date := L_vdate + 1;
         end if;
         -----
         if L_tax_rec.end_date >= L_vdate + 2 then
            L_start_date := L_tax_rec.start_date;
         else
            L_start_date := L_vdate + 1;
         end if;
         SQL_LIB.SET_MARK('INSERT','NULL','PRODUCT_TAX_CODE','ITEM: '||(L_item));
         insert into product_tax_code(seq_no,
                                      dept,
                                      item,
                                      tax_jurisdiction_id,
                                      tax_type_id,
                                      start_date,
                                      end_date,
                                      download_ind,
                                      create_id,
                                      create_date,
                                      create_datetime,
                                      last_update_id,
                                      last_update_datetime)
                              values (L_seq_no,
                                      NULL,
                                      I_item,
                                      L_tax_rec.tax_jurisdiction_id,
                                      L_tax_rec.tax_type_id,
                                      L_start_date,
                                      L_end_date,
                                      'Y',
                                      L_user_name,
                                      L_vdate,
                                      SYSDATE,
                                      L_user_name,
                                      SYSDATE);
         ---
      end LOOP;
      ---
   elsif L_sku_on_list_exists = 'Y' then
      ---
      SQL_LIB.SET_MARK('LOOP','NULL','C_INSERT_TAX_CODES_ILTCTEMP','ITEMLIST: '||to_char(I_skulist));
      ---
      FOR L_rec in C_INSERT_TAX_CODES_ILTCTEMP LOOP
         ---
         if NEXT_PRODUCT_TAX_CODE_SEQ(L_seq_no,
                                      O_error_message)= FALSE then
            return FALSE;
         end if;
         ---
         if L_rec.start_date >= L_vdate + 2 then
            L_start_date := L_rec.start_date;
         else
            L_start_date := L_vdate + 1;
         end if;
         -----
         if L_rec.end_date >= L_vdate + 2 then
            L_start_date := L_rec.start_date;
         else
            L_start_date := L_vdate +1;
         end if;
         ------
         SQL_LIB.SET_MARK('INSERT','NULL','PRODUCT_TAX_CODE','ITEM: '||(L_item));
         insert into product_tax_code(seq_no,
                                      dept,
                                      item,
                                      tax_jurisdiction_id,
                                      tax_type_id,
                                      start_date,
                                      end_date,
                                      download_ind,
                                      create_id,
                                      create_date,
                                      create_datetime,
                                      last_update_id,
                                      last_update_datetime)
                               values(L_seq_no,
                                      NULL,
                                      I_item,
                                      L_rec.tax_jurisdiction_id,
                                      L_rec.tax_type_id,
                                      L_start_date,
                                      L_end_date,
                                      'Y',
                                      L_user_name,
                                      L_vdate,
                                      SYSDATE,
                                      L_user_name,
                                      SYSDATE);
         ---
      end LOOP;
      ---
      -- Records are only needed for the first item.
      ---
      open C_TAXCODE_TEMP_LOCK;
      close C_TAXCODE_TEMP_LOCK;
      delete from itemlist_taxcode_temp
       where itemlist = I_skulist;
      ---
   end if;
   ---
   RETURN TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('ITEMLIST_TAXCODE_TEMP_REC_LOCK',
                                            to_char(I_skulist),
                                            NULL,
                                            NULL);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
			  	             SQLERRM,
				             L_program,
				             to_char(SQLCODE));
      RETURN FALSE;
END INSERT_TPG_TAX_CODES;
-------------------------------------------------------------------------------------------------------
FUNCTION ITEM_ON_ITEMLIST(O_error_message   IN OUT  VARCHAR2,
                          O_exists          IN OUT  VARCHAR2,
                          I_item            IN      SKULIST_DETAIL.ITEM%TYPE,
                          I_skulist         IN      SKULIST_DETAIL.SKULIST%TYPE)
return BOOLEAN is
   L_dummy   VARCHAR2(1);
   L_program VARCHAR2(64) := 'ITEMLIST_ADD_SQL.ITEM_ON_ITEMLIST';
   cursor C_ITEM_EXISTS is
      select 'x'
        from skulist_detail
       where item = I_item
         and skulist = I_skulist;
BEGIN
   open C_ITEM_EXISTS;
   fetch C_ITEM_EXISTS into L_dummy;
   if C_ITEM_EXISTS%FOUND then
      O_exists := 'Y';
   else
      O_exists := 'N';
   end if;
   close C_ITEM_EXISTS;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
			  	                    SQLERRM,
				                    L_program,
				                    to_char(SQLCODE));
      return FALSE;
END ITEM_ON_ITEMLIST;
---------------------------------------------------------------------------------------------------------
FUNCTION INSERT_SKULIST_DETAIL(O_error_message  IN OUT VARCHAR2,
                               I_itemlist       IN     SKULIST_HEAD.SKULIST%TYPE,
                               I_item           IN     ITEM_MASTER.ITEM%TYPE,
                               I_pack_ind       IN     ITEM_MASTER.PACK_IND%TYPE)
return BOOLEAN is
   L_item_level    ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level    ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_username      USER_ROLE_PRIVS.USERNAME%TYPE := USER;
   L_vdate         PERIOD.VDATE%TYPE := GET_VDATE;
   L_program       VARCHAR2(60) := 'ITEMLIST_ADD_SQL.INSERT_SKULIST_DETAIL';
   L_pack_ind      ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind  ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type     ITEM_MASTER.PACK_TYPE%TYPE;
BEGIN
   if I_pack_ind is NULL then
      ---
      if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                       L_pack_ind,
                                       L_sellable_ind,
                                       L_orderable_ind,
                                       L_pack_type,
                                       I_item) = FALSE then
         return FALSE;
      end if;
      ---
   else
      L_pack_ind := I_pack_ind;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                 L_item_level,
                                 L_tran_level,
                                 I_item) = FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT',NULL,'SKULIST_DETAIL','ITEMLIST: '||to_char(I_itemlist)||' ITEM: '||(I_item)||' PACK_IND: '||I_pack_ind);
   insert into skulist_detail(skulist,
                              item,
                              item_level,
                              tran_level,
                              pack_ind,
                              insert_id,
                              insert_date,
                              create_datetime,
                              last_update_datetime,
                              last_update_id)
                       values(I_itemlist,
                              I_item,
                              L_item_level,
                              L_tran_level,
                              L_pack_ind,
                              L_username,
                              L_vdate,
                              SYSDATE,
                              SYSDATE,
                              L_username);
   if SIT_SQL.INSERT_ITEM(O_error_message,
                          I_itemlist,
                          I_item) = FALSE then
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
END INSERT_SKULIST_DETAIL;
---------------------------------------------------------------------------------------------------------
--CR208 Phase 3.5b 10-Nov-2009 Chandru Begin
FUNCTION TSL_POPULATE_TEMP(O_error_message  IN OUT  VARCHAR2,
                           I_itemlist       IN      SKULIST_HEAD.SKULIST%TYPE,
                           I_item           IN      ITEM_MASTER.ITEM%TYPE,
                           I_value          IN      VARCHAR2)
   RETURN BOOLEAN IS
   L_program             VARCHAR2(60) := 'ITEMLIST_ADD_SQL.TSL_POPULATE_TEMP';
   L_itemlist_table      ITEMLIST_ATTRIB_SQL.ITEMLIST_TABLE;
   L_item_rec            ITEM_MASTER%ROWTYPE;
BEGIN
   if I_item is NOT NULL then
      insert into tsl_skulist_value_temp
         values(I_itemlist,
                I_item,
                I_value);
   else
      if ITEMLIST_ATTRIB_SQL.GET_ITEMLIST_ITEMS(O_error_message,
                                                L_itemlist_table,
                                                I_itemlist) = FALSE then
         return FALSE;
      end if;
      FOR L_rec in L_itemlist_table.FIRST .. L_itemlist_table.LAST LOOP
          insert into tsl_skulist_value_temp
             values(I_itemlist,
                    L_itemlist_table(L_rec).item,
                    null);
      END LOOP;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
			  	                                  SQLERRM,
				                                    L_program,
				                                    TO_CHAR(SQLCODE));
      return FALSE;
END TSL_POPULATE_TEMP;
-----------------------------------------------------------------------------
--15-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015640    Begin
--As part of this defect(Additional requirements) this function has been removed
--and clubbed to ITEMLIST_ATTIRB_SQL package.
-----------------------------------------------------------------------------
--15-Dec-2009   TESCO HSC/Joy Stephen   DefNBS015640    End
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
--CR208 Phase 3.5b 10-Nov-2009 Chandru End
END;
/

