CREATE OR REPLACE PACKAGE BODY ITEMLIST_DELETE_SQL AS
-----------------------------------------------------------------------------------------------------
-- Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date:    26-Jun-2007
-- Mod Ref:     Mod number. 365b1
-- Mod Details: Included Item_type parameter
--              Appeneded SKULIST_DELETE function with Item type parameter.
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By:      Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Mod Date:    12-Nov-2009
-- Mod Ref:     CR208
-- Mod Details: Modified the functions SKULIST_DELETE to include two new parameters.
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By     :Sarayu Gouda, sarayu.gouda@in.tesco.com
-- Mod Date   :05-Jan-2010
-- Mod Ref    :SirNBS7705676
-- Mod Details:Removed the trigger having the logic to delete the records from skulist_dept_class_subclass
--             and included it in the function skulist_delete and del_skulist
-----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- Mod By     :Sripriya, sripriya.karanam@in.tesco.com
-- Mod Date   :23-Feb-2011
-- Mod Ref    :DefNBS016331
-- Mod Details: Added validation to delete the items , that only meet the criteria given in the slgrp screen.
-------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- Mod By     :Bhargavi Pujari/bharagavi.pujari@in.tesco.com
-- Mod Date   :13-Apr-2010
-- Mod Ref    :NBS00017034
-- Mod Details:Added validation to delete the complex pack items , if the item type selected is complex pack
-------------------------------------------------------------------------------------------------------------
-- Mod by      : Usha Patil, usha.patil@in.tesco.com
-- Date        : 19-Jul-2010
-- Mod Ref     : CR288C
-- Mod Details : Modified the function SKULIST_DELETE to add parameter new parameter.
------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
   RECORD_LOCKED   EXCEPTION;
   LP_table        VARCHAR2(50);
----------------------------------------------------------------
-- Name:    SKULIST_DELETE
-- Purpose: Deletes all styles or SKUs found given the specified criteria
--          and the number of styles or SKUs in the SKU list.
----------------------------------------------------------------
FUNCTION SKULIST_DELETE(I_itemlist           IN     SKULIST_HEAD.SKULIST%TYPE,
                        I_pack_ind           IN     ITEM_MASTER.PACK_IND%TYPE,
                        I_item               IN     ITEM_MASTER.ITEM%TYPE,
                        I_item_parent        IN     SKULIST_CRITERIA.ITEM_PARENT%TYPE,
                        I_item_grandparent   IN     SKULIST_CRITERIA.ITEM_GRANDPARENT%TYPE,
                        I_dept               IN     SKULIST_CRITERIA.DEPT%TYPE,
                        I_class              IN     SKULIST_CRITERIA.CLASS%TYPE,
                        I_subclass           IN     SKULIST_CRITERIA.SUBCLASS%TYPE,
                        I_supplier           IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                        I_zone_group         IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                        I_diff_1             IN     SKULIST_CRITERIA.DIFF_1%TYPE,
                        I_diff_2             IN     SKULIST_CRITERIA.DIFF_2%TYPE,
                        I_diff_3             IN     SKULIST_CRITERIA.DIFF_3%TYPE,
                        I_diff_4             IN     SKULIST_CRITERIA.DIFF_4%TYPE,
                        I_uda_id             IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                        I_uda_value          IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                        I_uda_max_date       IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                        I_uda_min_date       IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                        I_season_id          IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                        I_phase_id           IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                        I_count_ind          IN     VARCHAR2,
                        I_no_add_ind         IN     VARCHAR2,
                        I_item_level         IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                        O_no_items           IN OUT NUMBER,
                        O_error_message      IN OUT VARCHAR2)
   RETURN BOOLEAN is
   L_program          VARCHAR2(64) := 'ITEMLIST_DELETE_SQL.SKULIST_DELETE';
   L_item             ITEM_MASTER.ITEM%TYPE;
   L_dummy            VARCHAR2(1);
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(Record_Locked, -54);
   L_select           VARCHAR2(200);
   L_lock             VARCHAR2(200);
   L_from_clause      VARCHAR2(200);
   L_main_where       VARCHAR2(200);
   L_where_clause     VARCHAR2(3000);
   L_statement        VARCHAR2(3400);
   L_statement2       VARCHAR2(3400);
   L_statement3       VARCHAR2(3400);
   TYPE ORD_CURSOR is REF CURSOR;
   C_ITEM             ORD_CURSOR;
   --SirNBS7705676 Sarayu Gouda 05-Jan-2010 Begin
   L_Exist   Varchar2(1);

   Cursor C_EXISTS_UDA_ITEM_DATE is
      select 'X'
         from UDA_ITEM_DATE
       where UDA_ID = I_UDA_ID;
   --SirNBS7705676 Sarayu Gouda 05-Jan-2010 End
BEGIN
   L_lock := 'select item ' ||
               'from skulist_detail ';
   L_main_where := 'where skulist = ' ||I_itemlist ||
                    ' and item in (select ima.item ';
   L_from_clause := 'from item_master ima';
   L_where_clause := ' where ima.item_level <= ima.tran_level ';
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
   if I_zone_group is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.retail_zone_group_id = '||I_zone_group;
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
      --SirNBS7705676 Sarayu Gouda 05-Jan-2010 Begin
      --Below existing code is commented as per SirNBS7705676
      /*L_from_clause := L_from_clause ||
                       ', uda_item_lov uil' ||
                       ', uda_item_date ud';
      L_where_clause := L_where_clause || ' and ' ||
                        '((ima.item = ud.item and ' ||
                          'ud.uda_id = '||I_uda_id||') or ' ||
                         '(ima.item = uil.item and ' ||
                          'uil.uda_id = '||I_uda_id||')) ';*/
      /* Note that the uda either exists in uda_item_date or in uda_item_lov */
      SQL_LIB.SET_MARK('OPEN',
                       'C_EXISTS_UDA_ITEM_DATE',
                       'UDA_ITEM_DATE', NULL);
      open C_EXISTS_UDA_ITEM_DATE;
      SQL_LIB.SET_MARK('FETCH',
                       'C_EXISTS_UDA_ITEM_DATE',
           'UDA_ITEM_DATE', NULL);
      fetch C_EXISTS_UDA_ITEM_DATE into L_Exist;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXISTS_UDA_ITEM_DATE',
                       'UDA_ITEM_DATE', NULL);
      close C_EXISTS_UDA_ITEM_DATE;

      if L_Exist = 'X' then
         L_from_clause := L_from_clause ||
                        ', uda_item_date ud';
         L_where_clause := L_where_clause || ' and ' ||
                         '(ima.item = ud.item and ' ||
                         'ud.uda_id = '||I_uda_id||') ';
      else
         L_from_clause := L_from_clause ||
                        ', uda_item_lov uil';
         L_where_clause := L_where_clause || ' and ' ||
                          '(ima.item = uil.item and ' ||
                          'uil.uda_id = '||I_uda_id||') ';

      end if;
      --SirNBS7705676 Sarayu Gouda 05-Jan-2010 Begin
   end if;
   if I_uda_value is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'uil.uda_value = '||I_uda_value;
   end if;
   if I_uda_min_date is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ud.uda_date >= '''||I_uda_min_date||'''';
   end if;
   if I_uda_max_date is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ud.uda_date <= '''||I_uda_max_date||'''';
   end if;
   if I_no_add_ind = 'N' then
      L_statement := L_lock ||
                     L_main_where ||
                     L_from_clause ||
                     L_where_clause ||
                     ') for update nowait';
      EXECUTE IMMEDIATE L_statement;
      open C_ITEM for L_statement;
    loop
      fetch C_ITEM into L_item;
      if C_ITEM%FOUND then
         if SIT_SQL.DELETE_ITEM(O_error_message,
                                I_itemlist,
                                L_item) = FALSE then
            return FALSE;
         end if;
      else
         EXIT;
      end if;
    end loop;
      close C_ITEM;
      L_statement2 := 'delete from skulist_detail ' ||
                       L_main_where ||
                       L_from_clause ||
                       L_where_clause ||')';
      EXECUTE IMMEDIATE L_statement2;
      --SirNBS7705676 Sarayu Gouda 05-Jan-2010 Begin
      delete from skulist_dept_class_subclass sk1
       where sk1.skulist = I_itemlist
         and (sk1.skulist, sk1.dept, sk1.class, sk1.subclass) not in
                (select sk2.skulist, im2.dept, im2.class, im2.subclass
                   from item_master im2,
                        skulist_detail sk2
                  where sk2.skulist = I_itemlist
                    and sk2.item = im2.item);
      --SirNBS7705676 Sarayu Gouda 05-Jan-2010 Begin
   else
      L_statement3 := 'delete from itemlist_tax_temp ' ||
                      'where itemlist_tax_temp.itemlist = ' ||I_itemlist ||
                      ' and item in (select ima.item ' ||
                      L_from_clause ||
                      L_where_clause || ')';
      EXECUTE IMMEDIATE L_statement3;
   end if;
   ---
   if I_count_ind = 'Y' then
      if ITEMLIST_ATTRIB_SQL.GET_ITEM_COUNT(O_error_message,
                                     I_itemlist,
                                  O_no_items) = FALSE then
         RETURN FALSE;
      end if;
   end if;
   RETURN TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('SKULIST_DETAIL_REC_LOCK',
                                            to_char(I_itemlist),
                                            NULL,
                                            NULL);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         to_char(SQLCODE));
      RETURN FALSE;
END SKULIST_DELETE;
---------------------------------------------------------------------------------------
-- Function Name  :   SKULIST_DELETE
-- Purpose        :   Deletes all styles or SKUs found given the specified criteria
--                    and the number of styles or SKUs in the SKU list.
---------------------------------------------------------------------------------------
FUNCTION SKULIST_DELETE(I_itemlist           IN     SKULIST_HEAD.SKULIST%TYPE,
                        I_pack_ind           IN     ITEM_MASTER.PACK_IND%TYPE,
                        I_item               IN     ITEM_MASTER.ITEM%TYPE,
                        I_item_parent        IN     SKULIST_CRITERIA.ITEM_PARENT%TYPE,
                        I_item_grandparent   IN     SKULIST_CRITERIA.ITEM_GRANDPARENT%TYPE,
                        I_dept               IN     SKULIST_CRITERIA.DEPT%TYPE,
                        I_class              IN     SKULIST_CRITERIA.CLASS%TYPE,
                        I_subclass           IN     SKULIST_CRITERIA.SUBCLASS%TYPE,
                        I_supplier           IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                        I_zone_group         IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                        I_diff_1             IN     SKULIST_CRITERIA.DIFF_1%TYPE,
                        I_diff_2             IN     SKULIST_CRITERIA.DIFF_2%TYPE,
                        I_diff_3             IN     SKULIST_CRITERIA.DIFF_3%TYPE,
                        I_diff_4             IN     SKULIST_CRITERIA.DIFF_4%TYPE,
                        I_uda_id             IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                        I_uda_value          IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                        I_uda_max_date       IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                        I_uda_min_date       IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                        I_season_id          IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                        I_phase_id           IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                        I_count_ind          IN     VARCHAR2,
                        I_no_add_ind         IN     VARCHAR2,
                        I_item_level         IN     ITEM_MASTER.ITEM_LEVEL%TYPE,
                        -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com  Mod 365b1
                        I_tsl_item_type      IN     SKULIST_CRITERIA.TSL_ITEM_TYPE%TYPE,
                        --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
                        I_custom_field       IN     SKULIST_CRITERIA.TSL_CUSTOM_FIELD%TYPE,
                        I_value              IN     SKULIST_CRITERIA.TSL_VALUE%TYPE,
                        --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
                        -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                        I_authorised_in      IN       ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE,
                        -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                        -- 11-Nov-2010, CR332, Merlyn Mathew, merlyn.mathew@in.tesco.com, Begin
                        I_Style_Ref_Code   IN  ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE,
                        -- 11-Nov-2010, CR332, Merlyn Mathew, merlyn.mathew@in.tesco.com, End
                        O_no_items           IN OUT NUMBER,
                        O_error_message      IN OUT VARCHAR2)
   return BOOLEAN is
   L_program          VARCHAR2(64) := 'ITEMLIST_DELETE_SQL.SKULIST_DELETE';
   L_item             ITEM_MASTER.ITEM%TYPE;
   L_dummy            VARCHAR2(1);
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(Record_Locked, -54);
   L_select           VARCHAR2(200);
   L_lock             VARCHAR2(200);
   L_from_clause      VARCHAR2(200);
   L_main_where       VARCHAR2(200);
   L_where_clause     VARCHAR2(3000);
   L_statement        VARCHAR2(3400);
   L_statement2       VARCHAR2(3400);
   L_statement3       VARCHAR2(3400);
   TYPE ORD_CURSOR is REF CURSOR;
   C_ITEM             ORD_CURSOR;

   --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
   CURSOR  C_PARENT_TABLE is
     select tcf.parent_table
       from tsl_custom_fields tcf
      where UPPER(tcf.custom_field_name) = UPPER(I_custom_field);

   L_parent_table     TSL_CUSTOM_FIELDS.PARENT_TABLE%TYPE;
   --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
BEGIN
   L_lock := 'select item ' ||
               'from skulist_detail ';
   L_main_where := 'where skulist = ' ||I_itemlist ||
                    ' and item in (select ima.item ';
   L_from_clause := 'from item_master ima';
   L_where_clause := ' where ima.item_level <= ima.tran_level ';
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
   if I_zone_group is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.retail_zone_group_id = '||I_zone_group;
   end if;
   if I_pack_ind is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.pack_ind = '''||I_pack_ind||'''';
   end if;
   if I_item_level is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ima.item_level = '||I_item_level;
   end if;
---------------------------------------------------------------------------------------------
-- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com  Mod 365b1      Begin
---------------------------------------------------------------------------------------------
   if I_tsl_item_type = 'B' then       -- Base item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item = ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_tsl_item_type = 'V' then    -- Variant item
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_base_item != ima.item' ||
                        ' and ima.item_level = ima.tran_level ' ||
                        ' and ima.item_level = 2 ';
   elsif I_tsl_item_type = 'P' then    -- Price marked
      L_where_clause := L_where_clause ||
                        ' and ima.tsl_price_mark_ind = ''Y'' ';
   elsif I_tsl_item_type = 'S' then     -- Simple pack
      L_where_clause := L_where_clause ||
                        ' and ima.simple_pack_ind = ''Y'' ';
   -- NBS00017034 13-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   elsif I_tsl_item_type = 'C' then     -- Complex pack
      L_where_clause := L_where_clause ||
                        ' and ima.simple_pack_ind = ''N'' ' ||
                        ' and ima.pack_ind        = ''Y'' ';
   -- NBS00017034 13-Apr-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
   end if;
---------------------------------------------------------------------------------------------
-- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com  Mod 365b1      End
---------------------------------------------------------------------------------------------

   --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
   if I_custom_field is NOT NULL  and I_value is NOT NULL then
      open  C_PARENT_TABLE;
      fetch C_PARENT_TABLE into L_parent_table;
      close C_PARENT_TABLE;
      L_from_clause := L_from_clause ||
                       ', '|| L_parent_table || ' tcf ';
      L_where_clause := L_where_clause ||
                       --NBSDef16331 23-Feb-2011 Sripriya,sripriya.karanam@in.tesco.com Begin
                       'and ima.item = tcf.item ' ||
                       --NBSDef16331 23-Feb-2011 Sripriya,sripriya.karanam@in.tesco.com End
                       'and tcf.'||I_custom_field ||' = '''||I_value||'''';
   end if;
   --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
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
      L_from_clause := L_from_clause ||
                       ', uda_item_lov uil' ||
                       ', uda_item_date ud';
      L_where_clause := L_where_clause || ' and ' ||
                        '((ima.item = ud.item and ' ||
                          'ud.uda_id = '||I_uda_id||') or ' ||
                         '(ima.item = uil.item and ' ||
                          'uil.uda_id = '||I_uda_id||')) ';
   end if;
   if I_uda_value is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'uil.uda_value = '||I_uda_value;
   end if;
   if I_uda_min_date is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ud.uda_date >= '''||I_uda_min_date||'''';
   end if;
   if I_uda_max_date is NOT NULL then
      L_where_clause := L_where_clause || ' and ' ||
                        'ud.uda_date <= '''||I_uda_max_date||'''';
   end if;
   if I_no_add_ind = 'N' then
      L_statement := L_lock ||
                     L_main_where ||
                     L_from_clause ||
                     L_where_clause ||
                     ') for update nowait';
      EXECUTE IMMEDIATE L_statement;
      open C_ITEM for L_statement;
    loop
      fetch C_ITEM into L_item;
      if C_ITEM%FOUND then
         if SIT_SQL.DELETE_ITEM(O_error_message,
                                I_itemlist,
                                L_item) = FALSE then
            return FALSE;
         end if;
      else
         EXIT;
      end if;
    end loop;
      close C_ITEM;
      L_statement2 := 'delete from skulist_detail ' ||
                       L_main_where ||
                       L_from_clause ||
                       L_where_clause ||')';
      EXECUTE IMMEDIATE L_statement2;
   else
      L_statement3 := 'delete from itemlist_tax_temp ' ||
                      'where itemlist_tax_temp.itemlist = ' ||I_itemlist ||
                      ' and item in (select ima.item ' ||
                      L_from_clause ||
                      L_where_clause || ')';
      EXECUTE IMMEDIATE L_statement3;
   end if;
   ---
   if I_count_ind = 'Y' then
      if ITEMLIST_ATTRIB_SQL.GET_ITEM_COUNT(O_error_message,
                                     I_itemlist,
                                  O_no_items) = FALSE then
         RETURN FALSE;
      end if;
   end if;
   RETURN TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('SKULIST_DETAIL_REC_LOCK',
                                            to_char(I_itemlist),
                                            NULL,
                                            NULL);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         to_char(SQLCODE));
      RETURN FALSE;
END SKULIST_DELETE;
---------------------------------------------------------------------------------------------
FUNCTION DEL_SKULIST(O_error_message   IN OUT      VARCHAR2,
                     I_skulist         IN          SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
BEGIN
   LP_table:= 'STAKE_SCHEDULE';
   SQL_LIB.SET_MARK('DELETE',NULL,'STAKE_SCHEDULE','SKULIST: '|| I_skulist);
   delete from stake_schedule
      where stake_schedule.skulist = I_skulist;
   LP_table:= 'LOC_CLSF_DETAIL';
   SQL_LIB.SET_MARK('DELETE',NULL,'LOC_CLSF_DETAIL','SKULIST: '|| I_skulist);
   delete from loc_clsf_detail
      where loc_clsf_detail.skulist = I_skulist;
   LP_table:= 'SKULIST_CRITERIA';
   SQL_LIB.SET_MARK('DELETE',NULL,'SKULIST_CRITERIA','SKULIST: '|| I_skulist);
   delete from skulist_criteria
      where skulist_criteria.skulist = I_skulist;
   LP_table:= 'SKULIST_DETAIL';
   SQL_LIB.SET_MARK('DELETE',NULL,'SKULIST_DETAIL','SKULIST: '|| I_skulist);
   delete from skulist_detail
      where skulist_detail.skulist = I_skulist;
   --SirNBS7705676 Sarayu Gouda 05-Jan-2010 Begin
   LP_table:= 'SKULIST_DEPT_CLASS_SUBCLASS';

   SQL_LIB.SET_MARK('DELETE',NULL,'SKULIST_DEPT_CLASS_SUBCLASS','SKULIST: '|| I_skulist);
   delete from SKULIST_DEPT_CLASS_SUBCLASS
      where SKULIST_DEPT_CLASS_SUBCLASS.skulist = I_skulist;
   --SirNBS7705676 Sarayu Gouda 05-Jan-2010 Begin
   LP_table:= 'SKULIST_DEPT';
   SQL_LIB.SET_MARK('DELETE',NULL,'SKULIST_DEPT','SKULIST: '|| I_skulist);
   delete from skulist_dept
      where skulist_dept.skulist = I_skulist;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                SQLERRM,
                                'DEL_SKULIST',
                                to_char(SQLCODE));
      RETURN FALSE;
END DEL_SKULIST;
-----------------------------------------------------------------------
FUNCTION LOCK_SKULIST (O_error_message  IN OUT VARCHAR2,
                       I_skulist        skulist_head.skulist%TYPE)
   RETURN BOOLEAN is
   cursor C_LOCK_STAKE_SCHEDULE is
      select 'x'
        from stake_schedule
       where skulist = I_skulist
         for update nowait;
   cursor C_LOCK_LOC_CLSF_DETAIL is
      select 'x'
        from loc_clsf_detail
       where skulist = I_skulist
         for update nowait;
   cursor C_LOCK_SKULIST_CRITERIA is
      select 'x'
        from skulist_criteria
       where skulist = I_skulist
         for update nowait;
   cursor C_LOCK_SKULIST_DETAIL is
      select 'x'
        from skulist_detail
       where skulist = I_skulist
         for update nowait;
BEGIN
   LP_table := 'STAKE_SCHEDULE';
   open C_LOCK_STAKE_SCHEDULE;
   close C_LOCK_STAKE_SCHEDULE;
   LP_table := 'LOC_CLSF_DETAIL';
   open C_LOCK_LOC_CLSF_DETAIL;
   close C_LOCK_LOC_CLSF_DETAIL;
   LP_table := 'SKULIST_CRITERIA';
   open C_LOCK_SKULIST_CRITERIA;
   close C_LOCK_SKULIST_CRITERIA;
   LP_table := 'SKULIST_DETAIL';
   open C_LOCK_SKULIST_DETAIL;
   close C_LOCK_SKULIST_DETAIL;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('ITEMDELETE_REC_LOC',
                                            LP_table,
                                            I_skulist);
      RETURN FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                SQLERRM,
                                'LOCK_SKULIST',
                                to_char(SQLCODE));
      RETURN FALSE;
END LOCK_SKULIST;
--------------------------------------------------------------
END ITEMLIST_DELETE_SQL;
/

