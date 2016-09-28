CREATE OR REPLACE PACKAGE BODY ITEMLIST_COUNT_SQL AS
-----------------------------------------------------------------------------------------------------
-- Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date:    27-Jun-2007
-- Mod Ref:     Mod number. 365b1
-- Mod Details: Included I_item_type parameter
--              Appended the COUNT_LIST and COUNT_EXIST function with Item type parameter.
-----------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 16-Nov-2009
-- Defect Id   : CR208
-- Desc        : Modified the functions COUNT_LIST,COUNT_EXISTS with custom field and value parameter.
-----------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 21-Dec-2009
-- Defect Id   : DefNBS015640/DefNBS015736
-- Desc        : Modified the functions COUNT_LIST,COUNT_EXISTS with I_country_id parameter.
------------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 15-Jan-2010
-- Defect Id   : DefNBS015930
-- Desc        : Modified the functions COUNT_LIST,COUNT_EXISTS to handle the DATE format parameter.
------------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 05-Feb-2010
-- Defect Id   : DefNBS016127
-- Desc        : Modified the functions COUNT_LIST,COUNT_EXISTS to handle case sensitive filtering.
------------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 05-Feb-2010
-- Defect Id   : DefNBS016155(Design Updation)
-- Desc        : Modified the functions COUNT_LIST,COUNT_EXISTS.
------------------------------------------------------------------------------------------------------
-- Modified by : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Date        : 05-Feb-2010
-- Defect Id   : DefNBS016143
-- Desc        : Modified the functions COUNT_LIST,COUNT_EXISTS to handle the low level code specially.
------------------------------------------------------------------------------------------------------
-- Modified by : Usha Patil, usha.patil@in.tesco.com
-- Date        : 19-Jul-2010
-- Mod Ref     : CR288C
-- Desc        : Modified the functions COUNT_LIST,COUNT_EXISTS.
------------------------------------------------------------------------------------------------------
-- Modified by : Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com
-- Date        : 01-Nov-2010
-- Defect Id   : CR332
-- Desc        : Modified the functions COUNT_LIST,COUNT_EXISTS with style_ref_code parameter.
-----------------------------------------------------------------------------------------------------
--- Procedure:  COUNT_LIST
--- Purpose:	This function counts the number of items that are in an itemlist.
-----------------------------------------------------------------------------------
FUNCTION COUNT_LIST (I_itemlist         IN     SKULIST_HEAD.SKULIST%TYPE,
                     I_pack_ind         IN     ITEM_MASTER.PACK_IND%TYPE,
                     I_item             IN     ITEM_MASTER.ITEM%TYPE,
                     I_item_parent      IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                     I_item_grandparent IN     ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                     I_dept             IN     ITEM_MASTER.DEPT%TYPE,
                     I_class            IN     ITEM_MASTER.CLASS%TYPE,
                     I_subclass         IN     ITEM_MASTER.SUBCLASS%TYPE,
                     I_supplier         IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                     I_zone_group_id    IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                     I_diff_1           IN     ITEM_MASTER.DIFF_1%TYPE,
                     I_diff_2           IN     ITEM_MASTER.DIFF_2%TYPE,
                     I_diff_3           IN     ITEM_MASTER.DIFF_3%TYPE,
                     I_diff_4           IN     ITEM_MASTER.DIFF_4%TYPE,
                     I_uda_id           IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                     I_uda_value        IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                     I_uda_max_date     IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                     I_uda_min_date     IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                     I_season_id        IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                     I_phase_id         IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                     I_item_level       IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                     O_no_items         IN OUT NUMBER,
                     O_error_message    IN OUT VARCHAR2)
                     RETURN BOOLEAN IS
   L_program          VARCHAR2(64) := 'ITEMLIST_COUNT.COUNT_LIST';
   L_select           VARCHAR2(50);
   L_from_clause      VARCHAR2(200);
   L_where_clause     VARCHAR2(3000);
   L_statement        VARCHAR2(3250);
   L_exist_1          VARCHAR2(3000);
   L_exist_2          VARCHAR2(3000);
   L_between          VARCHAR2(50);
   L_dummy_where      VARCHAR2(3000);
   TYPE ORD_CURSOR is REF CURSOR;
   C_ITEM             ORD_CURSOR;
   L_data_level_security_ind  SYSTEM_OPTIONS.DATA_LEVEL_SECURITY_IND%TYPE;
   cursor C_DATA_LEVEL_SECURITY is
      SELECT data_level_security_ind
        FROM system_options;
BEGIN
   --
   L_select := 'select count(distinct ima.item) ';
   L_from_clause := 'from item_master ima';
   L_where_clause := ' where ima.item_level <= ima.tran_level ';
   open C_DATA_LEVEL_SECURITY;
   fetch C_DATA_LEVEL_SECURITY INTO L_data_level_security_ind;
   close C_DATA_LEVEL_SECURITY;
   if L_data_level_security_ind = 'Y' then
      L_from_clause := L_from_clause || ', skulist_dept sld';
      L_where_clause := L_where_clause || ' and sld.skulist = ' || TO_CHAR(I_itemlist) ||
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
   fetch C_ITEM into O_no_items;
   close C_ITEM;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
			  	             SQLERRM,
				             L_program,
				             to_char(SQLCODE));
      RETURN FALSE;
END COUNT_LIST;
------------------------------------------------------------------------------------
-- Function name  : COUNT_LIST
-- Purpose        : This function counts the number of items that are in an itemlist.
------------------------------------------------------------------------------------
FUNCTION COUNT_LIST (I_itemlist         IN     SKULIST_HEAD.SKULIST%TYPE,
                     I_pack_ind         IN     ITEM_MASTER.PACK_IND%TYPE,
                     I_item             IN     ITEM_MASTER.ITEM%TYPE,
                     I_item_parent      IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                     I_item_grandparent IN     ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                     I_dept             IN     ITEM_MASTER.DEPT%TYPE,
                     I_class            IN     ITEM_MASTER.CLASS%TYPE,
                     I_subclass         IN     ITEM_MASTER.SUBCLASS%TYPE,
                     I_supplier         IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                     I_zone_group_id    IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                     I_diff_1           IN     ITEM_MASTER.DIFF_1%TYPE,
                     I_diff_2           IN     ITEM_MASTER.DIFF_2%TYPE,
                     I_diff_3           IN     ITEM_MASTER.DIFF_3%TYPE,
                     I_diff_4           IN     ITEM_MASTER.DIFF_4%TYPE,
                     I_uda_id           IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                     I_uda_value        IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                     I_uda_max_date     IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                     I_uda_min_date     IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                     I_season_id        IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                     I_phase_id         IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                     I_item_level       IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                     O_no_items         IN OUT NUMBER,
                     O_error_message    IN OUT VARCHAR2,
-- added by Govindarajan on 27-Jun-2007, Govindarajan.Karthigeyan@in.tesco.com
                     I_item_type        IN     VARCHAR2,
                     --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
                     I_custom_field     IN     VARCHAR2,
                     I_value            IN     VARCHAR2,
                     --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End
                     --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
                     I_country_id       IN     VARCHAR2,
                     --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
                     --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   Begin
                     I_code_type        IN     VARCHAR2,
                     --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   End
                     -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                     I_authorised_in    IN     ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE)
                     -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   RETURN BOOLEAN is
   L_program          VARCHAR2(64) := 'ITEMLIST_COUNT.COUNT_LIST';
   L_select           VARCHAR2(50);
   L_from_clause      VARCHAR2(200);
   L_where_clause     VARCHAR2(3000);
   L_statement        VARCHAR2(3250);
   L_exist_1          VARCHAR2(3000);
   L_exist_2          VARCHAR2(3000);
   L_between          VARCHAR2(50);
   L_dummy_where      VARCHAR2(3000);
   TYPE ORD_CURSOR is REF CURSOR;
   C_ITEM             ORD_CURSOR;
   L_data_level_security_ind  SYSTEM_OPTIONS.DATA_LEVEL_SECURITY_IND%TYPE;
   --21-Dec-2009   TESCO HSC/Joy Stephen    DefNBS015736/DefNBS015640    Begin
   L_country_exists   ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE;
   --21-Dec-2009   TESCO HSC/Joy Stephen    DefNBS015736/DefNBS015640    End
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --We have removed this piece of code after the design updation to new date format.
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End
   --L_data_type        USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   L_date             DATE;
   L_value            VARCHAR2(30);
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End

   cursor C_DATA_LEVEL_SECURITY is
      select data_level_security_ind
        from system_options;

   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   L_tsl_parent_table    TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;

   CURSOR C_GET_PARENT_TABLE is
   select parent_table
     from tsl_custom_fields
    where upper(custom_field_name) = upper(I_custom_field);
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End

   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   CURSOR C_GET_COUNTRY_EXISTS is
   select 'X'
     from user_tab_columns
    where upper(table_name) = upper(L_tsl_parent_table)
      and upper(column_name)= 'TSL_COUNTRY_ID';
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End

   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --This cursor fetches the data type length
   --We have removed this piece of code after the design updation to new date format.
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End

BEGIN

   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   L_value := I_value;
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   open C_GET_PARENT_TABLE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   fetch C_GET_PARENT_TABLE into L_tsl_parent_table;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   close C_GET_PARENT_TABLE;
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End

   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   open C_GET_COUNTRY_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   fetch C_GET_COUNTRY_EXISTS into L_country_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   close C_GET_COUNTRY_EXISTS;
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End

   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --Fetching the values from C_DATA_TYP_LEN
   --We have removed this piece of code after the design updation to new date format.
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   if UPPER(I_custom_field) = 'TSL_LOW_LVL_CODE' then
      L_value := replace(L_value,'_', ' ');
   end if;
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End
   --
   L_select := 'select count(distinct ima.item) ';
   L_from_clause := 'from item_master ima';
   L_where_clause := ' where ima.item_level <= ima.tran_level ';
   open C_DATA_LEVEL_SECURITY;
   fetch C_DATA_LEVEL_SECURITY INTO L_data_level_security_ind;
   close C_DATA_LEVEL_SECURITY;
   if L_data_level_security_ind = 'Y' then
      L_from_clause := L_from_clause || ', skulist_dept sld';
      L_where_clause := L_where_clause || ' and sld.skulist = ' || TO_CHAR(I_itemlist) ||
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
   ---------------------------------------------------------------------------------------
   -- 27-Jun-2007 Govindarajan - MOD 365b1 Begin
   ---------------------------------------------------------------------------------------
   if I_item_type = 'B' then      -- Base item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item = ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_item_type = 'V' then     -- Variant item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item != ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_item_type = 'P' then        -- Price marked
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_price_mark_ind = ''Y'' ';
   elsif I_item_type = 'S' then       -- Simple pack
      L_where_clause := L_where_clause ||
                        ' and ima.simple_pack_ind = ''Y'' ';
   elsif I_item_type = 'C' then      -- Complex pack
      L_where_clause := L_where_clause ||
                        ' and ima.pack_ind = ''Y'' ' ||
                        ' and ima.simple_pack_ind = ''N'' ';
   end if;
   ---------------------------------------------------------------------------------------
   -- 27-Jun-2007 Govindarajan - MOD 365b1 End
   ---------------------------------------------------------------------------------------
   --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   Begin
   --05-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016127   Begin
   --15-Jan-2010     TESCO HSC/Joy Stephen      DefNBS015930   Begin
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   if I_custom_field is NOT NULL and L_value is NOT NULL and L_country_exists is NOT NULL then
      L_from_clause  := L_from_clause||', '||L_tsl_parent_table||' tsltab';
      if I_country_id = 'B'  or I_country_id is NULL then
         if I_code_type = 'TBRA' then
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper('''||L_value||''')
                              and upper(tsltab.tsl_brand_ind) = upper(''Y'') and ima.item = tsltab.item and tsltab.tsl_country_id = ''U'' and exists( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         elsif I_code_type = 'TNBR' then
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper('''||L_value||''')
                              and upper(tsltab.tsl_brand_ind) = upper(''N'') and ima.item = tsltab.item and tsltab.tsl_country_id = ''U'' and exists( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         else
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper('''||L_value||''')
                              and ima.item = tsltab.item and tsltab.tsl_country_id = ''U'' and exists
                              ( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         end if;
      else
         if I_code_type = 'TBRA' then
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                              upper(tsltab.tsl_brand_ind) = upper(''Y'') and tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         elsif I_code_type = 'TNBR' then
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                              upper(tsltab.tsl_brand_ind) = upper(''N'') and tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         else
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                              tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         end if;
      end if;
   elsif I_custom_field is NOT NULL and L_value is NOT NULL and L_country_exists is NULL then
      L_from_clause  := L_from_clause||', '||L_tsl_parent_table||' tsltab';
      L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                        ima.item = tsltab.item';
   end if;
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
   --15-Jan-2010     TESCO HSC/Joy Stephen      DefNBS015930   End
   --05-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016127   End
   --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   End
   -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if I_authorised_in is NOT NULL then
      L_where_clause := L_where_clause||' and ima.tsl_country_auth_ind = '''|| I_authorised_in ||'''';
   end if;
   -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   L_statement := L_select || L_from_clause || L_where_clause;
   EXECUTE IMMEDIATE L_statement;
   open C_ITEM for L_statement;
   fetch C_ITEM into O_no_items;
   close C_ITEM;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
			  	             SQLERRM,
				             L_program,
				             to_char(SQLCODE));
      RETURN FALSE;
END COUNT_LIST;
------------------------------------------------------------------------------------
-- Function name  : COUNT_LIST
-- Purpose        : This function counts the number of items that are in an itemlist.
------------------------------------------------------------------------------------
FUNCTION COUNT_LIST (I_itemlist         IN     SKULIST_HEAD.SKULIST%TYPE,
                     I_pack_ind         IN     ITEM_MASTER.PACK_IND%TYPE,
                     I_item             IN     ITEM_MASTER.ITEM%TYPE,
                     I_item_parent      IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                     I_item_grandparent IN     ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                     I_dept             IN     ITEM_MASTER.DEPT%TYPE,
                     I_class            IN     ITEM_MASTER.CLASS%TYPE,
                     I_subclass         IN     ITEM_MASTER.SUBCLASS%TYPE,
                     I_supplier         IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                     I_zone_group_id    IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                     I_diff_1           IN     ITEM_MASTER.DIFF_1%TYPE,
                     I_diff_2           IN     ITEM_MASTER.DIFF_2%TYPE,
                     I_diff_3           IN     ITEM_MASTER.DIFF_3%TYPE,
                     I_diff_4           IN     ITEM_MASTER.DIFF_4%TYPE,
                     I_uda_id           IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                     I_uda_value        IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                     I_uda_max_date     IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                     I_uda_min_date     IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                     I_season_id        IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                     I_phase_id         IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                     I_item_level       IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                     O_no_items         IN OUT NUMBER,
                     O_error_message    IN OUT VARCHAR2,
-- added by Govindarajan on 27-Jun-2007, Govindarajan.Karthigeyan@in.tesco.com
                     I_item_type        IN     VARCHAR2,
                     --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
                     I_custom_field     IN     VARCHAR2,
                     I_value            IN     VARCHAR2,
                     --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End
                     --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
                     I_country_id       IN     VARCHAR2,
                     --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
                     --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   Begin
                     I_code_type        IN     VARCHAR2,
                     --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   End
                     -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                     I_authorised_in    IN     ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE,
                     -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                     -- 01-Nov-2010  CR332, Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com Begin
                     I_style_ref_code   IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
                     -- 01-Nov-2010  CR332, Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com End
   RETURN BOOLEAN is
   L_program          VARCHAR2(64) := 'ITEMLIST_COUNT.COUNT_LIST';
   L_select           VARCHAR2(50);
   L_from_clause      VARCHAR2(200);
   L_where_clause     VARCHAR2(3000);
   L_statement        VARCHAR2(3250);
   L_exist_1          VARCHAR2(3000);
   L_exist_2          VARCHAR2(3000);
   L_between          VARCHAR2(50);
   L_dummy_where      VARCHAR2(3000);
   TYPE ORD_CURSOR is REF CURSOR;
   C_ITEM             ORD_CURSOR;
   L_data_level_security_ind  SYSTEM_OPTIONS.DATA_LEVEL_SECURITY_IND%TYPE;
   --21-Dec-2009   TESCO HSC/Joy Stephen    DefNBS015736/DefNBS015640    Begin
   L_country_exists   ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE;
   --21-Dec-2009   TESCO HSC/Joy Stephen    DefNBS015736/DefNBS015640    End
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --We have removed this piece of code after the design updation to new date format.
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End
   --L_data_type        USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   L_date             DATE;
   L_value            VARCHAR2(30);
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End

   cursor C_DATA_LEVEL_SECURITY is
      select data_level_security_ind
        from system_options;

   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   L_tsl_parent_table    TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;

   CURSOR C_GET_PARENT_TABLE is
   select parent_table
     from tsl_custom_fields
    where upper(custom_field_name) = upper(I_custom_field);
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End

   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   CURSOR C_GET_COUNTRY_EXISTS is
   select 'X'
     from user_tab_columns
    where upper(table_name) = upper(L_tsl_parent_table)
      and upper(column_name)= 'TSL_COUNTRY_ID';
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End

   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --This cursor fetches the data type length
   --We have removed this piece of code after the design updation to new date format.
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End

BEGIN

   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   L_value := I_value;
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   open C_GET_PARENT_TABLE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   fetch C_GET_PARENT_TABLE into L_tsl_parent_table;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   close C_GET_PARENT_TABLE;
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End

   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   open C_GET_COUNTRY_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   fetch C_GET_COUNTRY_EXISTS into L_country_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   close C_GET_COUNTRY_EXISTS;
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End

   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --Fetching the values from C_DATA_TYP_LEN
   --We have removed this piece of code after the design updation to new date format.
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   if UPPER(I_custom_field) = 'TSL_LOW_LVL_CODE' then
      L_value := replace(L_value,'_', ' ');
   end if;
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End
   --
   L_select := 'select count(distinct ima.item) ';
   L_from_clause := 'from item_master ima';
   L_where_clause := ' where ima.item_level <= ima.tran_level ';
   open C_DATA_LEVEL_SECURITY;
   fetch C_DATA_LEVEL_SECURITY INTO L_data_level_security_ind;
   close C_DATA_LEVEL_SECURITY;
   if L_data_level_security_ind = 'Y' then
      L_from_clause := L_from_clause || ', skulist_dept sld';
      L_where_clause := L_where_clause || ' and sld.skulist = ' || TO_CHAR(I_itemlist) ||
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
   ---------------------------------------------------------------------------------------
   -- 27-Jun-2007 Govindarajan - MOD 365b1 Begin
   ---------------------------------------------------------------------------------------
   if I_item_type = 'B' then      -- Base item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item = ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_item_type = 'V' then     -- Variant item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item != ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_item_type = 'P' then        -- Price marked
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_price_mark_ind = ''Y'' ';
   elsif I_item_type = 'S' then       -- Simple pack
      L_where_clause := L_where_clause ||
                        ' and ima.simple_pack_ind = ''Y'' ';
   elsif I_item_type = 'C' then      -- Complex pack
      L_where_clause := L_where_clause ||
                        ' and ima.pack_ind = ''Y'' ' ||
                        ' and ima.simple_pack_ind = ''N'' ';
   end if;
   ---------------------------------------------------------------------------------------
   -- 27-Jun-2007 Govindarajan - MOD 365b1 End
   ---------------------------------------------------------------------------------------
   --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   Begin
   --05-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016127   Begin
   --15-Jan-2010     TESCO HSC/Joy Stephen      DefNBS015930   Begin
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   if I_custom_field is NOT NULL and L_value is NOT NULL and L_country_exists is NOT NULL then
      L_from_clause  := L_from_clause||', '||L_tsl_parent_table||' tsltab';
      if I_country_id = 'B'  or I_country_id is NULL then
         if I_code_type = 'TBRA' then
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper('''||L_value||''')
                              and upper(tsltab.tsl_brand_ind) = upper(''Y'') and ima.item = tsltab.item and tsltab.tsl_country_id = ''U'' and exists( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         elsif I_code_type = 'TNBR' then
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper('''||L_value||''')
                              and upper(tsltab.tsl_brand_ind) = upper(''N'') and ima.item = tsltab.item and tsltab.tsl_country_id = ''U'' and exists( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         else
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper('''||L_value||''')
                              and ima.item = tsltab.item and tsltab.tsl_country_id = ''U'' and exists
                              ( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         end if;
      else
         if I_code_type = 'TBRA' then
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                              upper(tsltab.tsl_brand_ind) = upper(''Y'') and tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         elsif I_code_type = 'TNBR' then
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                              upper(tsltab.tsl_brand_ind) = upper(''N'') and tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         else
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                              tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         end if;
      end if;
   elsif I_custom_field is NOT NULL and L_value is NOT NULL and L_country_exists is NULL then
      L_from_clause  := L_from_clause||', '||L_tsl_parent_table||' tsltab';
      L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                        ima.item = tsltab.item';
   end if;
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
   --15-Jan-2010     TESCO HSC/Joy Stephen      DefNBS015930   End
   --05-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016127   End
   --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   End
   -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if I_authorised_in is NOT NULL then
      L_where_clause := L_where_clause||' and ima.tsl_country_auth_ind = '''|| I_authorised_in ||'''';
   end if;
   -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
---------------------------------------------------------------------------------------------
   -- 01-Nov-2010  CR332, Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com Begin
   if I_style_ref_code is NOT NULL then
      L_where_clause := L_where_clause||' and ima.item_desc_secondary  = '''|| I_style_ref_code  ||'''';
   end if;
   -- 01-Nov-2010  CR332, Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com End
---------------------------------------------------------------------------------------------
   L_statement := L_select || L_from_clause || L_where_clause;
   EXECUTE IMMEDIATE L_statement;
   open C_ITEM for L_statement;
   fetch C_ITEM into O_no_items;
   close C_ITEM;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
			  	             SQLERRM,
				             L_program,
				             to_char(SQLCODE));
      RETURN FALSE;
END COUNT_LIST;
------------------------------------------------------------------------------------
FUNCTION COUNT_EXISTS (I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE,
                       I_pack_ind          IN     ITEM_MASTER.PACK_IND%TYPE,
                       I_item              IN     ITEM_MASTER.ITEM%TYPE,
                       I_item_parent       IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                       I_item_grandparent  IN     ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                       I_dept              IN     ITEM_MASTER.DEPT%TYPE,
                       I_class             IN     ITEM_MASTER.CLASS%TYPE,
                       I_subclass          IN     ITEM_MASTER.SUBCLASS%TYPE,
                       I_supplier          IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                       I_zone_group_id     IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                       I_diff_1            IN     ITEM_MASTER.DIFF_1%TYPE,
                       I_diff_2            IN     ITEM_MASTER.DIFF_2%TYPE,
                       I_diff_3            IN     ITEM_MASTER.DIFF_3%TYPE,
                       I_diff_4            IN     ITEM_MASTER.DIFF_4%TYPE,
                       I_uda_id            IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                       I_uda_value         IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                       I_uda_max_date      IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                       I_uda_min_date      IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                       I_season_id         IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                       I_phase_id          IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                       I_item_level        IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                       O_no_items          IN OUT NUMBER,
                       O_error_message     IN OUT VARCHAR2)
   RETURN BOOLEAN IS
   L_program          VARCHAR2(64) := 'ITEMLIST_COUNT.COUNT_EXISTS';
   L_select           VARCHAR2(50);
   L_from_clause      VARCHAR2(200);
   L_where_clause     VARCHAR2(3000);
   L_statement        VARCHAR2(3250);
   L_exist_1          VARCHAR2(3000);
   L_exist_2          VARCHAR2(3000);
   L_between          VARCHAR2(50);
   L_dummy_where      VARCHAR2(3000);
   TYPE ORD_CURSOR is REF CURSOR;
   C_ITEM             ORD_CURSOR;

BEGIN
   --
   L_select := 'select count(distinct ima.item) ';
   L_from_clause := 'from item_master ima, skulist_detail sd';
   L_where_clause := ' where ima.item_level <= ima.tran_level ' ||
                        'and ima.item = sd.item ' ||
                        'and sd.skulist = ' || I_itemlist;
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
   fetch C_ITEM into O_no_items;
   close C_ITEM;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
			  	             SQLERRM,
				             L_program,
				             to_char(SQLCODE));
      RETURN FALSE;
END COUNT_EXISTS;
------------------------------------------------------------------------------------
-- Function name  : COUNT_EXISTS
-- Purpose        :	This function counts the number of items that are in an itemlist
--                  and exist on the skulist_detail table.
-----------------------------------------------------------------------------------
FUNCTION COUNT_EXISTS (I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE,
                       I_pack_ind          IN     ITEM_MASTER.PACK_IND%TYPE,
                       I_item              IN     ITEM_MASTER.ITEM%TYPE,
                       I_item_parent       IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                       I_item_grandparent  IN     ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                       I_dept              IN     ITEM_MASTER.DEPT%TYPE,
                       I_class             IN     ITEM_MASTER.CLASS%TYPE,
                       I_subclass          IN     ITEM_MASTER.SUBCLASS%TYPE,
                       I_supplier          IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                       I_zone_group_id     IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                       I_diff_1            IN     ITEM_MASTER.DIFF_1%TYPE,
                       I_diff_2            IN     ITEM_MASTER.DIFF_2%TYPE,
                       I_diff_3            IN     ITEM_MASTER.DIFF_3%TYPE,
                       I_diff_4            IN     ITEM_MASTER.DIFF_4%TYPE,
                       I_uda_id            IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                       I_uda_value         IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                       I_uda_max_date      IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                       I_uda_min_date      IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                       I_season_id         IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                       I_phase_id          IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                       I_item_level        IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
-- added by Govindarajan on 27-Jun-2007, Govindarajan.Karthigeyan@in.tesco.com
                       I_item_type         IN     VARCHAR2,
                       O_no_items          IN OUT NUMBER,
                       O_error_message     IN OUT VARCHAR2,
                       --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
                       I_custom_field      IN     VARCHAR2,
                       I_value             IN     VARCHAR2,
                       --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End
                       --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
                       I_country_id        IN     VARCHAR2,
                       --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
                       --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   Begin
                       I_code_type        IN     VARCHAR2,
                       --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   End
                       -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                       I_authorised_in    IN     ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE)
                       -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   RETURN BOOLEAN is
   L_program          VARCHAR2(64) := 'ITEMLIST_COUNT.COUNT_EXISTS';
   L_select           VARCHAR2(50);
   L_from_clause      VARCHAR2(200);
   L_where_clause     VARCHAR2(3000);
   L_statement        VARCHAR2(3250);
   L_exist_1          VARCHAR2(3000);
   L_exist_2          VARCHAR2(3000);
   L_between          VARCHAR2(50);
   L_dummy_where      VARCHAR2(3000);
   TYPE ORD_CURSOR is REF CURSOR;
   C_ITEM             ORD_CURSOR;
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   L_country_exists   ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE;
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --We have removed this piece of code after the design updation to new date format.
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End
   L_date             DATE;
   L_value            VARCHAR2(30);
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End

   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   L_tsl_parent_table    TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;

   CURSOR C_GET_PARENT_TABLE is
   select parent_table
     from tsl_custom_fields
    where upper(custom_field_name) = upper(I_custom_field);
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End

   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   CURSOR C_GET_COUNTRY_EXISTS is
   select 'X'
     from user_tab_columns
    where upper(table_name) = upper(L_tsl_parent_table)
      and upper(column_name)= 'TSL_COUNTRY_ID';
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End

   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --We have removed this piece of code after the design updation to new date format.
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --This cursor fetches the data type length
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End

BEGIN
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   L_value := I_value;
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   open C_GET_PARENT_TABLE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   fetch C_GET_PARENT_TABLE into L_tsl_parent_table;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   close C_GET_PARENT_TABLE;
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End

   --21-Dec-2009   TESCO HSC/Joy Stephen         DefNBS015736/DefNBS015640    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   open C_GET_COUNTRY_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   fetch C_GET_COUNTRY_EXISTS into L_country_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   close C_GET_COUNTRY_EXISTS;
   --21-Dec-2009   TESCO HSC/Joy Stephen         DefNBS015736/DefNBS015640    End
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --We have removed this piece of code after the design updation to new date format.
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --Fetching the values from C_DATA_TYP_LEN
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   if UPPER(I_custom_field) = 'TSL_LOW_LVL_CODE' then
      L_value := replace(L_value,'_', ' ');
   end if;
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End
   --
   L_select := 'select count(distinct ima.item) ';
   L_from_clause := 'from item_master ima, skulist_detail sd';
   L_where_clause := ' where ima.item_level <= ima.tran_level ' ||
                        'and ima.item = sd.item ' ||
                        'and sd.skulist = ' || I_itemlist;
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
   ------------------------------------------------------------------------------------
   -- 27-Jun-2007 Govindarajan - MOD 365b1 Begin
   ------------------------------------------------------------------------------------
   if I_item_type = 'B' then            -- Base item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item = ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_item_type = 'V' then        -- Variant item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item != ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_item_type = 'P' then        -- Price marker
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_price_mark_ind = ''Y'' ';
   elsif I_item_type = 'S' then        -- Simple pack
      L_where_clause := L_where_clause ||
                        ' and ima.simple_pack_ind = ''Y'' ';
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   elsif I_item_type = 'C' then      -- Complex pack
      L_where_clause := L_where_clause ||
                        ' and ima.pack_ind = ''Y'' ' ||
                        ' and ima.simple_pack_ind = ''N'' ';
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
   end if;
   ------------------------------------------------------------------------------------
   -- 27-Jun-2007 Govindarajan - MOD 365b1 End
   ------------------------------------------------------------------------------------
   --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   Begin
   --05-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016127   Begin
   --15-Jan-2010     TESCO HSC/Joy Stephen      DefNBS015930   Begin
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   if I_custom_field is NOT NULL and L_value is NOT NULL and L_country_exists is NOT NULL then
      L_from_clause  := L_from_clause||', '||L_tsl_parent_table||' tsltab';
      if I_country_id = 'B'  or I_country_id is NULL then
         if I_code_type = 'TBRA' then
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''')
                              and sd.item = tsltab.item and upper(tsltab.tsl_brand_ind) = upper(''Y'') and
                              tsltab.tsl_country_id = ''U'' and exists ( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         elsif I_code_type = 'TNBR' then
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''')
                              and sd.item = tsltab.item and upper(tsltab.tsl_brand_ind) = upper(''N'') and
                              tsltab.tsl_country_id = ''U'' and exists( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         else
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''')
                              and sd.item = tsltab.item and tsltab.tsl_country_id = ''U'' and exists
                              ( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         end if;
      else
         if I_code_type = 'TBRA' then
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''') and
                              upper(tsltab.tsl_brand_ind) = upper(''Y'') and tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         elsif I_code_type = 'TNBR' then
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''') and
                              upper(tsltab.tsl_brand_ind) = upper(''N'') and tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         else
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''') and
                              tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         end if;
      end if;
   elsif I_custom_field is NOT NULL and L_value is NOT NULL and L_country_exists is NULL then
      L_from_clause  := L_from_clause||', '||L_tsl_parent_table||' tsltab';
      L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                        ima.item = tsltab.item';
   end if;
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
   --15-Jan-2010     TESCO HSC/Joy Stephen      DefNBS015930   End
   --05-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016127   End
   --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   End
   -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if I_authorised_in is NOT NULL then
      L_where_clause := L_where_clause||' and ima.tsl_country_auth_ind = '''|| I_authorised_in ||'''';
   end if;
   -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End

   L_statement := L_select || L_from_clause || L_where_clause;
   EXECUTE IMMEDIATE L_statement;
   open C_ITEM for L_statement;
   fetch C_ITEM into O_no_items;
   close C_ITEM;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
			  	             SQLERRM,
				             L_program,
				             to_char(SQLCODE));
      RETURN FALSE;
END COUNT_EXISTS;
------------------------------------------------------------------------------------
-- Function name  : COUNT_EXISTS
-- Purpose        :	This function counts the number of items that are in an itemlist
--                  and exist on the skulist_detail table.
-----------------------------------------------------------------------------------
FUNCTION COUNT_EXISTS (I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE,
                       I_pack_ind          IN     ITEM_MASTER.PACK_IND%TYPE,
                       I_item              IN     ITEM_MASTER.ITEM%TYPE,
                       I_item_parent       IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                       I_item_grandparent  IN     ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                       I_dept              IN     ITEM_MASTER.DEPT%TYPE,
                       I_class             IN     ITEM_MASTER.CLASS%TYPE,
                       I_subclass          IN     ITEM_MASTER.SUBCLASS%TYPE,
                       I_supplier          IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                       I_zone_group_id     IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                       I_diff_1            IN     ITEM_MASTER.DIFF_1%TYPE,
                       I_diff_2            IN     ITEM_MASTER.DIFF_2%TYPE,
                       I_diff_3            IN     ITEM_MASTER.DIFF_3%TYPE,
                       I_diff_4            IN     ITEM_MASTER.DIFF_4%TYPE,
                       I_uda_id            IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                       I_uda_value         IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                       I_uda_max_date      IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                       I_uda_min_date      IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                       I_season_id         IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                       I_phase_id          IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                       I_item_level        IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
-- added by Govindarajan on 27-Jun-2007, Govindarajan.Karthigeyan@in.tesco.com
                       I_item_type         IN     VARCHAR2,
                       O_no_items          IN OUT NUMBER,
                       O_error_message     IN OUT VARCHAR2,
                       --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
                       I_custom_field      IN     VARCHAR2,
                       I_value             IN     VARCHAR2,
                       --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End
                       --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
                       I_country_id        IN     VARCHAR2,
                       --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
                       --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   Begin
                       I_code_type        IN     VARCHAR2,
                       --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   End
                       -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                       I_authorised_in    IN     ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE,
                       -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                       -- 01-Nov-2010  CR332, Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com Begin
                       I_style_ref_code   IN     ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
                       -- 01-Nov-2010  CR332, Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com End
   RETURN BOOLEAN is
   L_program          VARCHAR2(64) := 'ITEMLIST_COUNT.COUNT_EXISTS';
   L_select           VARCHAR2(50);
   L_from_clause      VARCHAR2(200);
   L_where_clause     VARCHAR2(3000);
   L_statement        VARCHAR2(3250);
   L_exist_1          VARCHAR2(3000);
   L_exist_2          VARCHAR2(3000);
   L_between          VARCHAR2(50);
   L_dummy_where      VARCHAR2(3000);
   TYPE ORD_CURSOR is REF CURSOR;
   C_ITEM             ORD_CURSOR;
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   L_country_exists   ITEM_ATTRIBUTES.TSL_COUNTRY_ID%TYPE;
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --We have removed this piece of code after the design updation to new date format.
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End
   L_date             DATE;
   L_value            VARCHAR2(30);
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End

   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   L_tsl_parent_table    TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;

   CURSOR C_GET_PARENT_TABLE is
   select parent_table
     from tsl_custom_fields
    where upper(custom_field_name) = upper(I_custom_field);
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End

   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   CURSOR C_GET_COUNTRY_EXISTS is
   select 'X'
     from user_tab_columns
    where upper(table_name) = upper(L_tsl_parent_table)
      and upper(column_name)= 'TSL_COUNTRY_ID';
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End

   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --We have removed this piece of code after the design updation to new date format.
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --This cursor fetches the data type length
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End

BEGIN
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   L_value := I_value;
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   open C_GET_PARENT_TABLE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   fetch C_GET_PARENT_TABLE into L_tsl_parent_table;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_PARENT_TABLE',
                    'TSL_CUSTOM_FIELDS',
                    'Parent Table: '||I_custom_field);
   close C_GET_PARENT_TABLE;
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End

   --21-Dec-2009   TESCO HSC/Joy Stephen         DefNBS015736/DefNBS015640    Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   open C_GET_COUNTRY_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   fetch C_GET_COUNTRY_EXISTS into L_country_exists;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COUNTRY_EXISTS',
                    'USER_TAB_COLUMNS',
                    'Parent Table: '||L_tsl_parent_table);
   close C_GET_COUNTRY_EXISTS;
   --21-Dec-2009   TESCO HSC/Joy Stephen         DefNBS015736/DefNBS015640    End
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   Begin
   --We have removed this piece of code after the design updation to new date format.
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   Begin
   --Fetching the values from C_DATA_TYP_LEN
   --15-Jan-2010   TESCO HSC/Joy Stephen    DefNBS015930   End
   if UPPER(I_custom_field) = 'TSL_LOW_LVL_CODE' then
      L_value := replace(L_value,'_', ' ');
   end if;
   --04-Mar-2010   TESCO HSC/Joy Stephen    DefNBS016143   End
   --
   L_select := 'select count(distinct ima.item) ';
   L_from_clause := 'from item_master ima, skulist_detail sd';
   L_where_clause := ' where ima.item_level <= ima.tran_level ' ||
                        'and ima.item = sd.item ' ||
                        'and sd.skulist = ' || I_itemlist;
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

   ------------------------------------------------------------------------------------
   -- 27-Jun-2007 Govindarajan - MOD 365b1 Begin
   ------------------------------------------------------------------------------------
   if I_item_type = 'B' then            -- Base item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item = ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_item_type = 'V' then        -- Variant item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item != ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_item_type = 'P' then        -- Price marker
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_price_mark_ind = ''Y'' ';
   elsif I_item_type = 'S' then        -- Simple pack
      L_where_clause := L_where_clause ||
                        ' and ima.simple_pack_ind = ''Y'' ';
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   elsif I_item_type = 'C' then      -- Complex pack
      L_where_clause := L_where_clause ||
                        ' and ima.pack_ind = ''Y'' ' ||
                        ' and ima.simple_pack_ind = ''N'' ';
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
   end if;
   ------------------------------------------------------------------------------------
   -- 27-Jun-2007 Govindarajan - MOD 365b1 End
   ------------------------------------------------------------------------------------
   --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   Begin
   --05-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016127   Begin
   --15-Jan-2010     TESCO HSC/Joy Stephen      DefNBS015930   Begin
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    Begin
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    Begin
   if I_custom_field is NOT NULL and L_value is NOT NULL and L_country_exists is NOT NULL then
      L_from_clause  := L_from_clause||', '||L_tsl_parent_table||' tsltab';
      if I_country_id = 'B'  or I_country_id is NULL then
         if I_code_type = 'TBRA' then
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''')
                              and sd.item = tsltab.item and upper(tsltab.tsl_brand_ind) = upper(''Y'') and
                              tsltab.tsl_country_id = ''U'' and exists ( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         elsif I_code_type = 'TNBR' then
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''')
                              and sd.item = tsltab.item and upper(tsltab.tsl_brand_ind) = upper(''N'') and
                              tsltab.tsl_country_id = ''U'' and exists( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         else
            L_where_clause := L_where_clause||' and  upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''')
                              and sd.item = tsltab.item and tsltab.tsl_country_id = ''U'' and exists
                              ( select item from '||L_tsl_parent_table|| ' tsltab2 where
                              tsltab2.tsl_country_id = ''R'' and tsltab2.item = tsltab.item)';
         end if;
      else
         if I_code_type = 'TBRA' then
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''') and
                              upper(tsltab.tsl_brand_ind) = upper(''Y'') and tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         elsif I_code_type = 'TNBR' then
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''') and
                              upper(tsltab.tsl_brand_ind) = upper(''N'') and tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         else
            L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper( '''||L_value||''') and
                              tsltab.tsl_country_id = '''||I_country_id||''' and ima.item = tsltab.item';
         end if;
      end if;
   elsif I_custom_field is NOT NULL and L_value is NOT NULL and L_country_exists is NULL then
      L_from_clause  := L_from_clause||', '||L_tsl_parent_table||' tsltab';
      L_where_clause := L_where_clause||' and upper(tsltab.'||I_custom_field||') = upper('''||L_value||''') and
                        ima.item = tsltab.item';
   end if;
   --11-Nov-2009     TESCO HSC/Joy Stephen      CR208    End
   --21-Dec-2009     TESCO HSC/Joy Stephen      DefNBS015736/DefNBS015640    End
   --15-Jan-2010     TESCO HSC/Joy Stephen      DefNBS015930   End
   --05-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016127   End
   --17-Feb-2010     TESCO HSC/Joy Stephen      DefNBS016155(Design Updation)   End
   -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   if I_authorised_in is NOT NULL then
      L_where_clause := L_where_clause||' and ima.tsl_country_auth_ind = '''|| I_authorised_in ||'''';
   end if;
   -- 16-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
---------------------------------------------------------------------------------------------
   -- 01-Nov-2010  CR332, Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com Begin
   if I_style_ref_code is NOT NULL then
      L_where_clause := L_where_clause||' and ima.item_desc_secondary  = '''|| I_style_ref_code  ||'''';
   end if;
   -- 01-Nov-2010  CR332, Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com End
---------------------------------------------------------------------------------------------
   L_statement := L_select || L_from_clause || L_where_clause;
   EXECUTE IMMEDIATE L_statement;
   open C_ITEM for L_statement;
   fetch C_ITEM into O_no_items;
   close C_ITEM;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
			  	             SQLERRM,
				             L_program,
				             to_char(SQLCODE));
      RETURN FALSE;
END COUNT_EXISTS;
------------------------------------------------------------------------------------
END;
/

