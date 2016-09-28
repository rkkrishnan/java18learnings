CREATE OR REPLACE PACKAGE BODY ITEMLIST_BUILD_SQL AS
-----------------------------------------------------------------------------------------------------
-- Mod By:      Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date:    26-Jun-2007
-- Mod Ref:     Mod number. 365b1
-- Mod Details: Included Item_type parameter
--              Appeneded INSERT_CRITERIA function with Item type parameter
--              and modified the REBUILD_LIST and COPY_CRITERIA function.
-------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-- Mod By     :Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Mod Date   :12-Nov-2007
-- Mod Ref    :CR208
-- Mod Details:1.Modified the functions INSERT_CRITERIA and COPY_CRITERIA to include two new parameters.
--             2.Added new function TSL_UPDATE_SKULIST_CRITERIA to update SKULIST_CRITERIA.
-----------------------------------------------------------------------------------------------------
-- Mod By     :Sarayu Gouda, sarayu.gouda@in.tesco.com
-- Mod Date   :05-Jan-2010
-- Mod Ref    :SirNBS7705676
-- Mod Details:Removed the trigger having the logic to delete the records from skulist_dept_class_subclass
--             and included it in the function clear_list.
-----------------------------------------------------------------------------------------------------
-- Mod By     :Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   :26-Feb-2010
-- Mod Ref    :DefNBS016023
-- Mod Details:Modified the function TSL_UPDATE_SKULIST_CRITERIA to handle the new date format.
-----------------------------------------------------------------------------------------------------
-- Modified by : Usha Patil, usha.patil@in.tesco.com
-- Date        : 19-Jul-2010
-- Mod Ref     : CR288C
-- Mod Details : Modified the function REBUILD_LIST to add parameter to the skulist_add and delete functions.
------------------------------------------------------------------------------------------------------
-- Mod By     : Joy Stephen, joy.johnchristopher@in.tesco.com
-- Mod Date   : 04-Aug-2010
-- Mod Ref    : PrfNBS018117
-- Mod Details: Modified the function TSL_UPDATE_SKULIST_CRITERIA.
-----------------------------------------------------------------------------------------------------
-- Mod By     : JK, jayakumar.gopal@in.tesco.com
-- Mod Date   : 23-Sep-2010
-- Mod Ref    : PrfNBS019234
-- Mod Details: Modified the queries which are using USER_TAB_COLUMNS table to improve the performance.
-----------------------------------------------------------------------------------------------------
-- Mod By       : Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com
-- Mod Date     : 01-Nov-2010
-- Mod Ref      : CR332
-- Mod Details  : Added one new function TSL_INS_SKULIST_STYLE_REF_CODE
---------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Mod By       : Accenture/Merlyn Mathew Merlyn.Mathew@in.tesco.com
-- Mod Date     : 11-Nov-2010
-- Mod Ref      : CR332
-- Mod Details  : Modified calls to ITEMLIST_ADD_SQL.SKULIST_ADD and ITEMLIST_DELETE_SQL.SKULIST_DELETE
--                in REBUILD_LIST function to include Style ref code in parameter list
--------------------------------------------------------------------------------------------------------
FUNCTION CLEAR_LIST (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_itemlist      IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   ---
   L_program              VARCHAR2(64) := 'ITEMLIST_BUILD_SQL.GET_NAME';
   L_table                VARCHAR2(20) := NULL;
   L_skulist_desc         SKULIST_HEAD.SKULIST_DESC%TYPE;
   L_create_date          SKULIST_HEAD.CREATE_DATE%TYPE;
   L_last_rebuild_date    SKULIST_HEAD.LAST_REBUILD_DATE%TYPE;
   L_create_id        SKULIST_HEAD.CREATE_ID%TYPE;
   L_static_ind       SKULIST_HEAD.STATIC_IND%TYPE;
   L_comment_desc         SKULIST_HEAD.COMMENT_DESC%TYPE;
   L_tpg_itemlist     SKULIST_HEAD.TAX_PROD_GROUP_IND%TYPE;
   L_exists               BOOLEAN;
   L_vdate                PERIOD.VDATE%TYPE := GET_VDATE;
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_HEADER_LOCK is
      select 'x'
        from SKULIST_DETAIL
       where skulist = I_itemlist
         for update nowait;
   cursor C_TAX_CODES_LOCK is
      select 'x'
       from PRODUCT_TAX_CODE
      where item in (select item
                      from skulist_detail
                     where skulist = I_itemlist)
        for update nowait;
   cursor C_SIT_EXPLODE_LOCK is
      select 'x'
        from SIT_EXPLODE
       where skulist = I_itemlist
         for update nowait;
   ---
BEGIN
   ---
   if ITEMLIST_ATTRIB_SQL.GET_HEADER_INFO(O_error_message,
                                          L_skulist_desc,
                                          L_create_date,
                                          L_last_rebuild_date,
                                          L_create_id,
                                          L_static_ind,
                                          L_comment_desc,
                                          L_tpg_itemlist,
                                          I_itemlist) = FALSE then
      return FALSE;
   end if;
   ---
   if L_tpg_itemlist = 'Y' then
      ---
      if ITEMLIST_BUILD_SQL.INSERT_ITEMLIST_TAXCODE_TEMP(O_error_message,
                                                         I_itemlist) = FALSE then
         return FALSE;
      end if;
      ---
      open C_TAX_CODES_LOCK;
      close C_TAX_CODES_LOCK;
      ----
      delete from product_tax_code
         where item in (select item
                          from skulist_detail
                         where skulist = I_itemlist)
                 and ((start_date <= L_vdate + 1
                 and (end_date is NULL
                 or end_date > L_vdate))
                 or start_date > L_vdate + 1);
   end if;
   ---
   open C_HEADER_LOCK;
   close C_HEADER_LOCK;
   delete from skulist_detail
    where skulist = I_itemlist;
   ---
   --SirNBS7705676 Sarayu Gouda 05-Jan-2010 Begin
   delete from SKULIST_DEPT_CLASS_SUBCLASS
    where SKULIST_DEPT_CLASS_SUBCLASS.skulist = I_itemlist;
   --SirNBS7705676 Sarayu Gouda 05-Jan-2010 End

   if SIT_SQL.SIT_EXISTS(O_error_message,
                         L_exists,
                         I_itemlist,
                         NULL) = FALSE then
      return FALSE;
   end if;
   if L_exists then
      if SIT_SQL.COPY_SIT_CONFLICT(O_error_message,
                                   I_itemlist,
                                   NULL) =  FALSE then
         return FALSE;
      end if;
      ---
      open C_SIT_EXPLODE_LOCK;
      close C_SIT_EXPLODE_LOCK;
      ---
      delete from sit_explode
      where skulist = I_itemlist;
   end if;
   RETURN TRUE;
EXCEPTION
   when RECORD_LOCKED then
      if C_HEADER_LOCK%ISOPEN then
         close C_HEADER_LOCK;
         L_table := 'SKULIST_DETAIL';
      elsif C_TAX_CODES_LOCK%ISOPEN then
         close C_TAX_CODES_LOCK;
         L_table := 'PRODUCT_TAX_CODE';
      elsif C_SIT_EXPLODE_LOCK%ISOPEN then
         close C_SIT_EXPLODE_LOCK;
         L_table := 'SIT_EXPLODE';
      end if;
      O_error_message := sql_lib.create_msg('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_itemlist));
      RETURN FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END CLEAR_LIST;
----------------------------------------------------------------------------------
-- Function name  : REBUILD_LIST
-- Purpose        : The REBUILD_LIST function will rebuild the specified
--                  item list based on the criteria saved on the
--                  new SKULIST_CRITERIA table.
----------------------------------------------------------------------------------
FUNCTION REBUILD_LIST (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       O_no_items      IN OUT NUMBER,
                       I_itemlist      IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   L_program                VARCHAR2(64) := 'ITEMLIST_BUILD_SQL.REBUILD_LIST';
   L_table                  VARCHAR2(20) := NULL;
   L_action_type            SKULIST_CRITERIA.ACTION_TYPE%TYPE;
   L_pack_ind               SKULIST_DETAIL.PACK_IND%TYPE;
   L_item                   SKULIST_CRITERIA.ITEM%TYPE;
   L_item_level             SKULIST_CRITERIA.ITEM_LEVEL%TYPE;
   L_item_parent            SKULIST_CRITERIA.ITEM_PARENT%TYPE;
   L_item_grandparent       SKULIST_CRITERIA.ITEM_GRANDPARENT%TYPE;
   L_uda_id                 SKULIST_CRITERIA.UDA_ID%TYPE;
   L_uda_min_date           SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE;
   L_uda_max_date           SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE;
   L_uda_value              SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE;
   L_supplier               SKULIST_CRITERIA.SUPPLIER%TYPE;
   L_dept                   SKULIST_CRITERIA.DEPT%TYPE;
   L_class                  SKULIST_CRITERIA.CLASS%TYPE;
   L_subclass               SKULIST_CRITERIA.SUBCLASS%TYPE;
   L_diff_1                 SKULIST_CRITERIA.DIFF_1%TYPE;
   L_diff_2                 SKULIST_CRITERIA.DIFF_2%TYPE;
   L_diff_3                 SKULIST_CRITERIA.DIFF_3%TYPE;
   L_diff_4                 SKULIST_CRITERIA.DIFF_4%TYPE;
   L_season_id              SKULIST_CRITERIA.SEASON_ID%TYPE;
   L_phase_id               SKULIST_CRITERIA.PHASE_ID%TYPE;
   L_zone_group_id          SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE;
   -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
   L_tsl_item_type          SKULIST_CRITERIA.TSL_ITEM_TYPE%TYPE;
   L_sellable_ind           ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind          ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type              ITEM_MASTER.PACK_TYPE%TYPE;
   L_vdate                  PERIOD.VDATE%TYPE := NULL;
   L_rowid                  ROWID;
   RECORD_LOCKED            EXCEPTION;
   PRAGMA                   EXCEPTION_INIT(Record_Locked, -54);

   --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
   L_custom_field           SKULIST_CRITERIA.TSL_CUSTOM_FIELD%TYPE;
   L_value                  SKULIST_CRITERIA.TSL_VALUE%TYPE;
   --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
   -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
   L_authorised_in          ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE := NULL;
   L_item_master_row        ITEM_MASTER%ROWTYPE;
   -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
   -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
   L_style_ref_code         ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE := NULL;
   -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End

   cursor C_GET_SKULIST_DETAIL_ROWID is
     select rowid
       from skulist_detail
      where skulist_detail.item       = L_item
        and skulist_detail.skulist    = I_itemlist
          for update nowait;
   cursor C_CRITERIA is
      select action_type,
             item,
             item_level,
             item_parent,
             item_grandparent,
             uda_id,
             uda_value_min_date,
             uda_value_max_date,
             uda_value_lov,
             supplier,
             dept,
             class,
             subclass,
             diff_1,
             diff_2,
             diff_3,
             diff_4,
             season_id,
             phase_id,
             zone_group_id,
             --26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
             tsl_item_type,
             --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
             tsl_custom_field,
             tsl_value
             --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
        from skulist_criteria
       where skulist = I_itemlist
    order by seq_no;
   cursor C_HEAD_LOCK is
      select 'x'
        from skulist_head
       where skulist = I_itemlist
         for update nowait;
   cursor C_TAXCODE_TEMP_LOCK is
      select 'x'
        from itemlist_taxcode_temp
       where itemlist = I_itemlist
         for update nowait;
BEGIN
   L_vdate := DATES_SQL.GET_VDATE;
   open C_HEAD_LOCK;
   close C_HEAD_LOCK;
   update SKULIST_HEAD
      set LAST_REBUILD_DATE = L_vdate
    where skulist = I_itemlist;
   if ITEMLIST_BUILD_SQL.CLEAR_LIST(O_error_message,
                                    I_itemlist) = FALSE then
      RETURN FALSE;
   end if;
   for rec in C_CRITERIA LOOP
      L_action_type := rec.action_type;
      L_item := rec.item;
      L_item_level := rec.item_level;
      L_item_parent := rec.item_parent;
      L_item_grandparent := rec.item_grandparent;
      L_uda_id := rec.uda_id;
      L_uda_min_date := rec.uda_value_min_date;
      L_uda_max_date := rec.uda_value_max_date;
      L_uda_value := rec.uda_value_lov;
      L_supplier := rec.supplier;
      L_dept := rec.dept;
      L_class := rec.class;
      L_subclass := rec.subclass;
      L_diff_1 := rec.diff_1;
      L_diff_2 := rec.diff_2;
      L_diff_3 := rec.diff_3;
      L_diff_4 := rec.diff_4;
      L_season_id := rec.season_id;
      L_phase_id := rec.phase_id;
      L_zone_group_id := rec.zone_group_id;
      -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
      L_tsl_item_type := rec.tsl_item_type;
      --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
      L_custom_field    := rec.tsl_custom_field;
      L_value           := rec.tsl_value;
      --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
      L_pack_ind := NULL;
      -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
      L_authorised_in := NULL;
      -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
      ---
      -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
      L_style_ref_code := NULL;
      -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End

      if L_item is not NULL then
         if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                          L_pack_ind,
                                          L_sellable_ind,
                                          L_orderable_ind,
                                          L_pack_type,
                                          L_item) = FALSE then
            return FALSE;
         end if;
         -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
         if ITEM_ATTRIB_SQL.GET_ITEM_MASTER (O_error_message,
                                             L_item_master_row,
                                             L_item) =  FALSE then
            return FALSE;
         end if;
         L_authorised_in := L_item_master_row.tsl_country_auth_ind;
         -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
      end if;
      ---
      ---If Action_Type = 'A'dd then call SKULIST_ADD---
      if L_action_type = 'A' then
         if ITEMLIST_ADD_SQL.SKULIST_ADD(I_itemlist,
                                         L_pack_ind,
                                         L_item,
                                         L_item_parent,
                                         L_item_grandparent,
                                         L_dept,
                                         L_class,
                                         L_subclass,
                                         L_supplier,
                                         L_zone_group_id,
                                         L_diff_1,
                                         L_diff_2,
                                         L_diff_3,
                                         L_diff_4,
                                         L_uda_id,
                                         L_uda_value,
                                         L_uda_max_date,
                                         L_uda_min_date,
                                         L_season_id,
                                         L_phase_id,
                                         'N',
                                         'N',
                                         L_item_level,
                                         -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
                                         L_tsl_item_type,
                                         --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
                                         L_custom_field,
                                         L_value,
                                         --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
                                         -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                                         L_authorised_in,
                                         -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                                          -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                                         L_style_ref_code,
                                         -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                                         O_no_items,
                                         O_error_message) = FALSE then
            RETURN FALSE;
         end if;
      elsif L_action_type = 'D' then
         if L_item is not NULL then
            if ITEMLIST_BUILD_SQL.DELETE_SINGLE_ITEM(O_error_message,
                                                     L_item,
                                                     I_itemlist) = FALSE then
               RETURN FALSE;
            end if;
         else
            if ITEMLIST_DELETE_SQL.SKULIST_DELETE(I_itemlist,
                                                  L_pack_ind,
                                                  L_item,
                                                  L_item_parent,
                                                  L_item_grandparent,
                                                  L_dept,
                                                  L_class,
                                                  L_subclass,
                                                  L_supplier,
                                                  L_zone_group_id,
                                                  L_diff_1,
                                                  L_diff_2,
                                                  L_diff_3,
                                                  L_diff_4,
                                                  L_uda_id,
                                                  L_uda_value,
                                                  L_uda_max_date,
                                                  L_uda_min_date,
                                                  L_season_id,
                                                  L_phase_id,
                                                  'N',
                                                  'N',
                                                  L_item_level,
                                                  -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
                                                  L_tsl_item_type,
                                                  --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
                                                  L_custom_field,
                                                  L_value,
                                                  --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
                                                  -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, Begin
                                                  L_authorised_in,
                                                  -- 19-Jul-2010, CR288C, Usha Patil, usha.patil@in.tesco.com, End
                                                  -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, Begin
                                                  L_style_ref_code,
                                                  -- 11-Nov-2010, CR332, Merlyn Mathew, Merlyn.Mathew@in.tesco.com, End
                                                  O_no_items,
                                                  O_error_message) = FALSE then
               RETURN FALSE;
            end if;
         end if;
      end if;
   END LOOP;
   ---
   if SIT_SQL.REBUILD_SIT_CONFLICT(O_error_message,
                                   I_itemlist,
                                   NULL) = FALSE then
         return FALSE;
      end if;
   if ITEMLIST_ATTRIB_SQL.GET_ITEM_COUNT(O_error_message,
                                         I_itemlist,
                                         O_no_items) = FALSE then
      RETURN FALSE;
   end if;
   ---
   -- Delete to handle case where no items met the criteria.
   ---
   ---
   open C_TAXCODE_TEMP_LOCK;
   close C_TAXCODE_TEMP_LOCK;
   -----
   delete from itemlist_taxcode_temp
         where itemlist = I_itemlist;
   ---
   RETURN TRUE;
EXCEPTION
   when RECORD_LOCKED then
      if C_HEAD_LOCK%ISOPEN then
         close C_HEAD_LOCK;
         L_table := 'SKULIST_HEAD';
      elsif C_TAXCODE_TEMP_LOCK%ISOPEN then
         close C_TAXCODE_TEMP_LOCK;
         L_table := 'ITEMLIST_TAXCODE_TEMP';
      end if;
      O_error_message := sql_lib.create_msg('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_itemlist));
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END REBUILD_LIST;
----------------------------------------------------------
FUNCTION GET_MAX_SEQUENCE_NO (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_sequence_no   IN OUT SKULIST_CRITERIA.SEQ_NO%TYPE,
                              I_itemlist      IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   L_program       VARCHAR2(64) := 'ITEMLIST_BUILD_SQL.GET_MAX_SEQUENCE_NO';
   cursor C_SEQUENCE_NO is
      select nvl(max(seq_no) + 1,1)
        from skulist_criteria
       where skulist = I_itemlist;
BEGIN
   open C_SEQUENCE_NO;
   fetch C_SEQUENCE_NO into O_sequence_no;
   close C_SEQUENCE_NO;
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END GET_MAX_SEQUENCE_NO;
----------------------------------------------------------
FUNCTION LOCK_RECORDS(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   L_program      VARCHAR2(64) := 'ITEMLIST_BUILD_SQL.LOCK_RECORDS';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);
   cursor C_GET_SKULIST_HEAD is
      select 'x'
        from skulist_head
       where skulist = I_itemlist
         for update nowait;
BEGIN
   open C_GET_SKULIST_HEAD;
   close C_GET_SKULIST_HEAD;
   RETURN TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('SKULIST_REC_LOCK',
                                            to_char(I_itemlist),
                                            NULL,
                                            NULL);
      RETURN FALSE;
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END LOCK_RECORDS;
------------------------------------------------------------------------------------
-- Function Name  : INSERT_CRITERIA
-- Purpose        : This function inserts the criteria for the given step
--                  of building the item list.
------------------------------------------------------------------------------------
FUNCTION INSERT_CRITERIA(I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE,
                         I_seq_no            IN     SKULIST_CRITERIA.SEQ_NO%TYPE,
                         I_action_type       IN     SKULIST_CRITERIA.ACTION_TYPE%TYPE,
                         I_item              IN     ITEM_MASTER.ITEM%TYPE,
                         I_item_parent       IN     ITEM_MASTER.ITEM%TYPE,
                         I_item_grandparent  IN     ITEM_MASTER.ITEM%TYPE,
                         I_uda_id            IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                         I_uda_min_date      IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                         I_uda_max_date      IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                         I_uda_value_lov     IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                         I_supplier          IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                         I_dept              IN     SKULIST_CRITERIA.DEPT%TYPE,
                         I_class             IN     SKULIST_CRITERIA.CLASS%TYPE,
                         I_subclass          IN     SKULIST_CRITERIA.SUBCLASS%TYPE,
                         I_diff_1            IN     SKULIST_CRITERIA.DIFF_1%TYPE,
                         I_diff_2            IN     SKULIST_CRITERIA.DIFF_2%TYPE,
                         I_diff_3            IN     SKULIST_CRITERIA.DIFF_3%TYPE,
                         I_diff_4            IN     SKULIST_CRITERIA.DIFF_4%TYPE,
                         I_season_id         IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                         I_phase_id          IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                         I_zone_group_id     IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                         I_item_level        IN     SKULIST_CRITERIA.ITEM_LEVEL%TYPE,
                         O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE)
   RETURN BOOLEAN is
   L_program        VARCHAR2(64) := 'ITEMLIST_BUILD_SQL.INSERT_CRITERIA';
BEGIN
   SQL_LIB.SET_MARK('INSERT',NULL,'SKULIST_CRITERIA','ITEMLIST: '||I_itemlist||' SEQ_NO: '||to_char(I_seq_no));
    insert into SKULIST_CRITERIA
               (skulist,
                seq_no,
                action_type,
                item_level,
                item,
                item_parent,
                item_grandparent,
                uda_id,
                uda_value_min_date,
                uda_value_max_date,
                uda_value_lov,
                supplier,
                dept,
                class,
                subclass,
                diff_1,
                diff_2,
                diff_3,
                diff_4,
                season_id,
                phase_id,
                zone_group_id,
                last_update_datetime,
                last_update_id,
                create_datetime)
      values(I_itemlist,
             I_seq_no,
             I_action_type,
             I_item_level,
             I_item,
             I_item_parent,
             I_item_grandparent,
             I_uda_id,
             I_uda_min_date,
             I_uda_max_date,
             I_uda_value_lov,
             I_supplier,
             I_dept,
             I_class,
             I_subclass,
             I_diff_1,
             I_diff_2,
             I_diff_3,
             I_diff_4,
             I_season_id,
             I_phase_id,
             I_zone_group_id,
             sysdate,
             user,
             sysdate);
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END INSERT_CRITERIA;
-----------------------------------------------------------------------
-- Function Name  : INSERT_CRITERIA
-- Purpose        : This function inserts the criteria for the given step
--                  of building the item list.
-----------------------------------------------------------------------
FUNCTION INSERT_CRITERIA(I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE,
                         I_seq_no            IN     SKULIST_CRITERIA.SEQ_NO%TYPE,
                         I_action_type       IN     SKULIST_CRITERIA.ACTION_TYPE%TYPE,
                         I_item              IN     ITEM_MASTER.ITEM%TYPE,
                         I_item_parent       IN     ITEM_MASTER.ITEM%TYPE,
                         I_item_grandparent  IN     ITEM_MASTER.ITEM%TYPE,
                         I_uda_id            IN     SKULIST_CRITERIA.UDA_ID%TYPE,
                         I_uda_min_date      IN     SKULIST_CRITERIA.UDA_VALUE_MIN_DATE%TYPE,
                         I_uda_max_date      IN     SKULIST_CRITERIA.UDA_VALUE_MAX_DATE%TYPE,
                         I_uda_value_lov     IN     SKULIST_CRITERIA.UDA_VALUE_LOV%TYPE,
                         I_supplier          IN     SKULIST_CRITERIA.SUPPLIER%TYPE,
                         I_dept              IN     SKULIST_CRITERIA.DEPT%TYPE,
                         I_class             IN     SKULIST_CRITERIA.CLASS%TYPE,
                         I_subclass          IN     SKULIST_CRITERIA.SUBCLASS%TYPE,
                         I_diff_1            IN     SKULIST_CRITERIA.DIFF_1%TYPE,
                         I_diff_2            IN     SKULIST_CRITERIA.DIFF_2%TYPE,
                         I_diff_3            IN     SKULIST_CRITERIA.DIFF_3%TYPE,
                         I_diff_4            IN     SKULIST_CRITERIA.DIFF_4%TYPE,
                         I_season_id         IN     SKULIST_CRITERIA.SEASON_ID%TYPE,
                         I_phase_id          IN     SKULIST_CRITERIA.PHASE_ID%TYPE,
                         I_zone_group_id     IN     SKULIST_CRITERIA.ZONE_GROUP_ID%TYPE,
                         I_item_level        IN     SKULIST_CRITERIA.ITEM_LEVEL%TYPE,
                         -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
                         I_tsl_item_type     IN     SKULIST_CRITERIA.TSL_ITEM_TYPE%TYPE,
                         --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
                         I_custom_field       IN     SKULIST_CRITERIA.TSL_CUSTOM_FIELD%TYPE,
                         I_value              IN     SKULIST_CRITERIA.TSL_VALUE%TYPE,
                         --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
                         O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE)
   return BOOLEAN is
   L_program        VARCHAR2(64) := 'ITEMLIST_BUILD_SQL.INSERT_CRITERIA';
BEGIN
   SQL_LIB.SET_MARK('INSERT',NULL,'SKULIST_CRITERIA','ITEMLIST: '||I_itemlist||' SEQ_NO: '||to_char(I_seq_no));
    insert into SKULIST_CRITERIA
               (skulist,
                seq_no,
                action_type,
                item_level,
                item,
                item_parent,
                item_grandparent,
                uda_id,
                uda_value_min_date,
                uda_value_max_date,
                uda_value_lov,
                supplier,
                dept,
                class,
                subclass,
                diff_1,
                diff_2,
                diff_3,
                diff_4,
                season_id,
                phase_id,
                zone_group_id,
                -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
                tsl_item_type,
                --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
                tsl_custom_field,
                tsl_value,
                --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
                last_update_datetime,
                last_update_id,
                create_datetime)
      values(I_itemlist,
             I_seq_no,
             I_action_type,
             I_item_level,
             I_item,
             I_item_parent,
             I_item_grandparent,
             I_uda_id,
             I_uda_min_date,
             I_uda_max_date,
             I_uda_value_lov,
             I_supplier,
             I_dept,
             I_class,
             I_subclass,
             I_diff_1,
             I_diff_2,
             I_diff_3,
             I_diff_4,
             I_season_id,
             I_phase_id,
             I_zone_group_id,
             -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
             I_tsl_item_type,
             --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
             I_custom_field,
             I_value,
             --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
             sysdate,
             user,
             sysdate);
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END INSERT_CRITERIA;
----------------------------------------------------------
FUNCTION DELETE_CRITERIA(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         I_itemlist          IN     SKULIST_CRITERIA.SKULIST%TYPE,
                         I_item              IN     SKULIST_CRITERIA.ITEM%TYPE)
   RETURN BOOLEAN is
   L_program        VARCHAR2(64) := 'ITEMLIST_BUILD_SQL.DELETE_CRITERIA';
BEGIN
   SQL_LIB.SET_MARK('DELETE', NULL, 'SKULIST_CRITERIA',
                    'ITEMLIST: '||I_itemlist||' Item: '|| I_item);
   delete from SKULIST_CRITERIA
    where skulist = I_itemlist
      and item = I_item;
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END DELETE_CRITERIA;
----------------------------------------------------------------------------
-- Function Name : COPY_CRITERIA
-- Purpose       : This function copies the criteria from one
--                 skulist to another, used in create from existing
--                 in SLHEAD.fmb.
----------------------------------------------------------------------------
FUNCTION COPY_CRITERIA(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                       I_itemlist_old      IN     SKULIST_HEAD.SKULIST%TYPE,
                       I_itemlist_new      IN     SKULIST_HEAD.SKULIST%TYPE,
                       --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
                       I_custom_field      IN    SKULIST_CRITERIA.TSL_CUSTOM_FIELD%TYPE,
                       I_value             IN    SKULIST_CRITERIA.TSL_VALUE%TYPE)
                       --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
   RETURN BOOLEAN is
   L_program    VARCHAR2(255)   := 'ITEMLIST_BUILD_SQL.COPY_CRITERIA';
BEGIN
   insert into SKULIST_CRITERIA
               (skulist,
                seq_no,
                action_type,
                item_level,
                item,
                item_parent,
                item_grandparent,
                uda_id,
                uda_value_min_date,
                uda_value_max_date,
                uda_value_lov,
                supplier,
                dept,
                class,
                subclass,
                diff_1,
                diff_2,
                diff_3,
                diff_4,
                season_id,
                phase_id,
                zone_group_id,
                -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
                tsl_item_type,
                --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
                tsl_custom_field,
                tsl_value,
                --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
                last_update_datetime,
                last_update_id,
                create_datetime)
      select I_itemlist_new,
             seq_no,
             action_type,
             item_level,
             item,
             item_parent,
             item_grandparent,
             uda_id,
             uda_value_min_date,
             uda_value_max_date,
             uda_value_lov,
             supplier,
             dept,
             class,
             subclass,
             diff_1,
             diff_2,
             diff_3,
             diff_4,
             season_id,
             phase_id,
             zone_group_id,
             -- 26-Jun-2007 Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com Mod 365b1
             tsl_item_type,
             --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 Begin
             tsl_custom_field,
             tsl_value,
             --12-Nov-2009 Vinod, vinod.patalappa@in.tesco.com  CR208 End
             sysdate,
             user,
             sysdate
        from skulist_criteria
       where skulist = I_itemlist_old;
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END COPY_CRITERIA;
----------------------------------------------------------
FUNCTION INSERT_SINGLE_ITEM(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_item           IN     ITEM_MASTER.ITEM%TYPE,
                            I_itemlist           IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   L_program                  VARCHAR2(64)            := 'ITEMLIST_BUILD_SQL.INSERT_SINGLE_ITEM';
   L_itemlist_tpgitem_exists  VARCHAR2(1)                 := 'N';
   L_skulist                  SKULIST_HEAD.SKULIST%TYPE;
   L_new_skulist              SKULIST_HEAD.SKULIST%TYPE;
   L_itemlist_desc            SKULIST_HEAD.SKULIST_DESC%TYPE;
   L_pack_ind                 ITEM_MASTER.PACK_IND%TYPE;
   L_item_level               ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level               ITEM_MASTER.TRAN_LEVEL%TYPE;
   L_create_date              SKULIST_HEAD.CREATE_DATE%TYPE;
   L_create_id                SKULIST_HEAD.CREATE_ID%TYPE;
   L_rebuild_date             SKULIST_HEAD.LAST_REBUILD_DATE%TYPE;
   L_static_ind               SKULIST_HEAD.STATIC_IND%TYPE;
   L_comment_desc             SKULIST_HEAD.COMMENT_DESC%TYPE;
   L_itemlist_type            SKULIST_HEAD.TAX_PROD_GROUP_IND%TYPE;
   L_username                 USER_ROLE_PRIVS.USERNAME%TYPE := USER;
   L_vdate                    PERIOD.VDATE%TYPE := GET_VDATE;
   L_sellable_ind             ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind            ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type                ITEM_MASTER.PACK_TYPE%TYPE;
BEGIN
   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;
   if ITEM_ATTRIB_SQL.GET_LEVELS(O_error_message,
                                 L_item_level,
                                 L_tran_level,
                                 I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if ITEMLIST_ATTRIB_SQL.GET_HEADER_INFO(O_error_message,
                                          L_itemlist_desc,
                                          L_create_date,
                                          L_rebuild_date,
                                          L_create_id,
                                          L_static_ind,
                                          L_comment_desc,
                                          L_itemlist_type,
                                          I_itemlist) = FALSE then
      RETURN FALSE;
   end if;
   if L_itemlist_type = 'Y' then
      if ITEMLIST_ADD_SQL.ITEM_IN_TPG_ITEMLIST(O_error_message,
                                               I_item,
                                               'N',
                                               I_itemlist,
                                               L_new_skulist,
                                               L_itemlist_tpgitem_exists) = FALSE then
         return FALSE;
      end if;
   else
      L_itemlist_tpgitem_exists := 'N';
   end if;
   if L_itemlist_tpgitem_exists = 'N' then
      SQL_LIB.SET_MARK('INSERT',NULL,'SKULIST_DETAIL','ITEMLIST: '||to_char(I_itemlist));
      insert into skulist_detail(skulist,
                                 item_level,
                                 tran_level,
                                 item,
                                 pack_ind,
                                 insert_id,
                                 insert_date,
                                 last_update_datetime,
                                 last_update_id,
                                 create_datetime)
                          values(I_itemlist,
                                 L_item_level,
                                 L_tran_level,
                                 I_item,
                                 L_pack_ind,
                                 L_username,
                                 L_vdate,
                                 sysdate,
                                 L_username,
                                 sysdate);
      if L_itemlist_type = 'Y' then
       if ITEMLIST_ADD_SQL.INSERT_TPG_TAX_CODES(O_error_message,
                                                  I_item,
                                                  I_itemlist) = FALSE then
               return FALSE;
           end if;
      end if;
      if SIT_SQL.INSERT_ITEM(O_error_message,
                             I_itemlist,
                             I_item) = FALSE then
         return FALSE;
      end if;
   end if;
   RETURN TRUE;
EXCEPTION
   when DUP_VAL_ON_INDEX then
      NULL;
      RETURN TRUE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END INSERT_SINGLE_ITEM;
----------------------------------------------------------
FUNCTION DELETE_SINGLE_ITEM(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_item          IN     ITEM_MASTER.ITEM%TYPE,
                            I_itemlist      IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   L_program      VARCHAR2(64)      := 'ITEMLIST_BUILD_SQL.DELETE_SINGLE_ITEM';
   L_rowid        ROWID;
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);
   cursor C_GET_SKULIST_DETAIL_ROWID is
     select rowid
       from skulist_detail
      where skulist_detail.item    = I_item
        and skulist_detail.skulist = I_itemlist
        for update nowait;
BEGIN
   open  C_GET_SKULIST_DETAIL_ROWID;
   fetch C_GET_SKULIST_DETAIL_ROWID into L_rowid;
   close C_GET_SKULIST_DETAIL_ROWID;
   delete from skulist_detail
    where rowid = L_rowid;
   if SIT_SQL.DELETE_ITEM(O_error_message,
                          I_itemlist,
                          I_item) = FALSE then
      return FALSE;
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
END DELETE_SINGLE_ITEM;
----------------------------------------------------------
FUNCTION INSERT_ITEMLIST_TAXCODE_TEMP(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                      I_itemlist      IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   ---
   L_program         VARCHAR2(64)        := 'ITEMLIST_BUILD_SQL.INSERT_ITEMLIST_TAXCODE_TEMP';
   L_vdate           PERIOD.VDATE%TYPE   := GET_VDATE;
BEGIN
   ---
   insert into itemlist_taxcode_temp(itemlist,
                                     tax_jurisdiction_id,
                                     tax_type_id,
                                     start_date,
                                     end_date)
                              select I_itemlist,
                                     tax_jurisdiction_id,
                                     tax_type_id,
                                     start_date,
                                     end_date
                                from product_tax_code
                               where item = (select MIN(item)
                                               from skulist_detail
                                              where skulist = I_itemlist)
                                 and ((start_date <= L_vdate + 1
                                       and (end_date is NULL
                                        or end_date > L_vdate))
                                    or start_date > L_vdate + 1);
   ---
   RETURN TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END INSERT_ITEMLIST_TAXCODE_TEMP;
---------------------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_DEPS
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION SKULIST_DEPT_EXIST(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_exist             IN OUT BOOLEAN,
                            I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE,
                            I_merch_level       IN     SYSTEM_OPTIONS.SKULIST_ORG_LEVEL_CODE%TYPE,
                            I_merch_id          IN     DEPS.DEPT%TYPE,
                            I_merch_class_id    IN     CLASS.CLASS%TYPE,
                            I_merch_subclass_id IN     SUBCLASS.SUBCLASS%TYPE)
RETURN BOOLEAN IS
   L_program         VARCHAR2(64)        := 'ITEMLIST_BUILD_SQL.SKULIST_DEPT_EXIST';
   cursor c_skulist_dept_exist is
      select 'Y'
        from skulist_dept sd,
             v_deps vd,
             v_subclass vsc
       where sd.dept  = vsc.dept
         and sd.class = vsc.class
         and sd.skulist = I_itemlist
         and ((I_merch_level = 'D' and vd.division = I_merch_id and vd.dept = vsc.dept)
           or (I_merch_level = 'G' and vd.group_no = I_merch_id and vd.dept = vsc.dept)
           or (I_merch_level = 'P' and vd.dept     = I_merch_id and vd.dept = vsc.dept)
           or (I_merch_level = 'C' and vd.dept     = I_merch_id and vd.dept = vsc.dept and vsc.class = I_merch_class_id)
           or (I_merch_level = 'S' and vd.dept     = I_merch_id and vd.dept = vsc.dept and vsc.class = I_merch_class_id and vsc.subclass = I_merch_subclass_id));
   L_skulist_dept_exist     VARCHAR2(1) := 'N';
BEGIN
   ---
   if I_itemlist is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_itemlist',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_merch_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_merch_level',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_merch_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_merch_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   open c_skulist_dept_exist;
   fetch c_skulist_dept_exist into L_skulist_dept_exist;
   close c_skulist_dept_exist;
   ---
   if L_skulist_dept_exist = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END SKULIST_DEPT_EXIST;
---------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_DEPS
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION INSERT_SKULIST_DEPT(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_itemlist          IN     SKULIST_HEAD.SKULIST%TYPE,
                             I_merch_level       IN     SYSTEM_OPTIONS.SKULIST_ORG_LEVEL_CODE%TYPE,
                             I_merch_id          IN     DEPS.DEPT%TYPE,
                             I_merch_class_id    IN     CLASS.CLASS%TYPE,
                             I_merch_subclass_id IN     SUBCLASS.SUBCLASS%TYPE)
   RETURN BOOLEAN is
   ---
   L_program         VARCHAR2(64)        := 'ITEMLIST_BUILD_SQL.INSERT_SKULIST_DEPT';
BEGIN
   insert into skulist_dept(skulist,
                            dept,
                            class,
                            subclass)
                    select I_itemlist,
                           vsc.dept,
                           vsc.class,
                           vsc.subclass
                      from v_deps v,
                           v_subclass vsc
                     where ((I_merch_level = 'D' and v.division = I_merch_id and v.dept = vsc.dept)
                         or (I_merch_level = 'G' and v.group_no = I_merch_id and v.dept = vsc.dept)
                         or (I_merch_level = 'P' and v.dept     = I_merch_id and v.dept = vsc.dept)
                         or (I_merch_level = 'C' and v.dept     = I_merch_id and v.dept = vsc.dept and vsc.class = I_merch_class_id)
                         or (I_merch_level = 'S' and v.dept     = I_merch_id and v.dept = vsc.dept and vsc.class = I_merch_class_id and vsc.subclass = I_merch_subclass_id))
                       and not exists (select 'x'
                                         from skulist_dept sd
                                        where sd.dept     = vsc.dept
                                          and sd.class    = vsc.class
                                          and sd.subclass = vsc.subclass
                                          and sd.skulist  = I_itemlist);
   ---
   RETURN TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END INSERT_SKULIST_DEPT;
----------------------------------------------------------
FUNCTION COPY_SKULIST_DEPT(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           I_skulist_old      IN     SKULIST_HEAD.SKULIST%TYPE,
                           I_skulist_new      IN     SKULIST_HEAD.SKULIST%TYPE)
   RETURN BOOLEAN is
   ---
   L_program         VARCHAR2(64)        := 'ITEMLIST_BUILD_SQL.COPY_SKULIST_DEPT';
BEGIN
   ---
   insert into skulist_dept(skulist,
                            dept,
                            class,
                            subclass)
                    select I_skulist_new,
                           sd.dept,
                           sd.class,
                           sd.subclass
                      from skulist_dept sd
                     where sd.skulist = I_skulist_old;
   ---
   RETURN TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END COPY_SKULIST_DEPT;
--------------------------------------------------------------------------------
-- Mod By     : Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Mod Date   : 12-Nov-2007
-- Mod Ref    : CR208
-- Mod Details: New function to get the datatype for the passing parameter.
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Only call this function with online forms to validate the data type entered by
-- user and the value been given as input.
-- which only returns datatype for the entered value.
--------------------------------------------------------------------------------
FUNCTION TSL_GET_DATA_TYPE (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_data_type     IN OUT USER_TAB_COLUMNS.DATA_TYPE%TYPE,
                            O_column_name   IN OUT USER_TAB_COLUMNS.COLUMN_NAME%TYPE,
                            O_data_length   IN OUT USER_TAB_COLUMNS.DATA_LENGTH%TYPE,
                            I_custom_code   IN     TSL_CUSTOM_FIELDS.CUSTOM_CODE%TYPE)
   RETURN BOOLEAN is
   ---
   L_program         VARCHAR2(64)        := 'ITEMLIST_BUILD_SQL.TSL_GET_DATA_TYPE';

   cursor C_GET_CUSTOM_CODE is
  select utc.column_name, utc.data_type,utc.data_length
    from  user_tab_columns utc,
          tsl_custom_fields tcf
   --23-Sep-10  JK  DefNBS019234   Begin
   where  utc.table_name  = upper(tcf.parent_table)
     and  utc.column_name = upper(tcf.custom_field_name)
   --23-Sep-10  JK  DefNBS019234   End
     and  upper(tcf.custom_code)  = upper(I_custom_code);



BEGIN
   ---

      --Cursor to get the data type.
      SQL_LIB.SET_MARK('OPEN','C_GET_CUSTOM_CODE','USER_TAB_COLUMNS',
                       'column_name: '|| I_custom_code);
      open C_GET_CUSTOM_CODE;

      SQL_LIB.SET_MARK('FETCH','C_GET_CUSTOM_CODE','USER_TAB_COLUMNS',
                       'column_name:'|| I_custom_code);
      fetch C_GET_CUSTOM_CODE into O_data_type,
                                   O_column_name,
                                   O_data_length;

      SQL_LIB.SET_MARK('CLOSE','C_GET_CUSTOM_CODE','USER_TAB_COLUMNS',
                       'column_name: '|| I_custom_code);
      close C_GET_CUSTOM_CODE;

   RETURN TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END TSL_GET_DATA_TYPE;
--------------------------------------------------------------------------------
-- Mod By     : Vinod Patalappa, vinod.patalappa@in.tesco.com
-- Mod Date   : 12-Nov-2007
-- Mod Ref    : CR208
-- Mod Details: New function to update SKULIST_CRITERIA with new value and custom
--              code.
--------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_SKULIST_CRITERIA (O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                      I_skulist            IN SKULIST_CRITERIA.SKULIST%TYPE,
                                      I_item               IN SKULIST_CRITERIA.ITEM%TYPE,
                                      I_tsl_custom_field   IN TSL_CUSTOM_FIELDS.CUSTOM_FIELD_NAME%TYPE,
                                      I_tsl_value          IN VARCHAR2)
   RETURN BOOLEAN is
   ---
   L_program         VARCHAR2(64)        := 'ITEMLIST_BUILD_SQL.TSL_UPDATE_SKULIST_CRITERIA';

   L_exists      VARCHAR2(1);
   L_data_type   USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (BEGIN)
   -- As part of the design updation we have removed this piece of code.
   -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (END)

   cursor C_LOCK_SKULIST_CRITERIA is
   select 'X'
     from skulist_criteria
    where skulist = I_skulist
      --03-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117   Begin
      and item = I_item
      --03-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117   End
    for update nowait;

   cursor C_GET_SKULIST_CRITERIA is
   select 'X'
     from skulist_criteria
    where skulist = I_skulist
      and item    = I_item;

   cursor C_GET_DATA_TYPE is
   select utc.data_type
     from user_tab_columns utc,
          tsl_custom_fields tcf
   where  upper(tcf.custom_field_name)  = upper(I_tsl_custom_field)
     --23-Sep-10  JK  DefNBS019234   Begin
     and  utc.column_name = upper(tcf.custom_field_name)
     and  utc.table_name  = upper(tcf.parent_table);
     --23-Sep-10  JK  DefNBS019234   End

BEGIN
      -- Lock the skulist_criteria record and update the tsl_custom_field and tsl_value supplier
      -- for I_skulist where the I_skulist is
      -- equal to the input skulist.
      ---
      --Cursor to look up skulist exits.
      SQL_LIB.SET_MARK('OPEN','C_GET_SKULIST_CRITERIA','SKULIST_CRITERIA',
                       'skulist: '|| I_skulist);
      open C_GET_SKULIST_CRITERIA;
      SQL_LIB.SET_MARK('FETCH','C_GET_SKULIST_CRITERIA','SKULIST_CRITERIA',
                       'skulist:'|| I_skulist);
      fetch C_GET_SKULIST_CRITERIA into L_exists;

      SQL_LIB.SET_MARK('CLOSE','C_GET_SKULIST_CRITERIA','SKULIST_CRITERIA',
                       'skulist: '|| I_skulist);
      close C_GET_SKULIST_CRITERIA;

      --Cursor to get the data type for  up skulist exits.
      open C_GET_DATA_TYPE;
      SQL_LIB.SET_MARK('FETCH','C_GET_DATA_TYPE','USER_TAB_COLUMNS',
                       'column_name:'|| I_tsl_custom_field);
      fetch C_GET_DATA_TYPE into L_data_type;

      SQL_LIB.SET_MARK('CLOSE','C_GET_DATA_TYPE','USER_TAB_COLUMNS',
                       'column_name: '|| I_tsl_custom_field);
      close C_GET_DATA_TYPE;

      -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (BEGIN)
      -- As part of the design updation we have removed this piece of code.
      -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (END)
      if L_exists is NOT NULL then
         --03-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117   Begin
         SQL_LIB.SET_MARK('OPEN','C_LOCK_SKULIST_CRITERIA','SKULIST_CRITERIA',
                          'skulist: '|| I_skulist);
         open C_LOCK_SKULIST_CRITERIA;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_SKULIST_CRITERIA','SKULIST_CRITERIA',
                          'skulist: '|| I_skulist);
         close C_LOCK_SKULIST_CRITERIA;
         --03-Aug-2010   TESCO HSC/Joy Stephen    PrfNBS018117   End
         update skulist_criteria
            set tsl_custom_field = I_tsl_custom_field,
                -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (BEGIN)
                tsl_value        = I_tsl_value
                -- SIT DefNBS016023, 26-Feb-2010, Joy Stephen, joy.johnchristopher@in.tesco.com (END)
          where skulist          = I_skulist
            and item             = I_item;
      end if;

   RETURN TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END TSL_UPDATE_SKULIST_CRITERIA;
----------------------------------------------------------------------------------------------------------
-- Mod By     : Shireen Sheosunker, shireen.sheosunker@uk.tesco.com
-- Mod Date   : 22-Apr-2010
-- Mod Ref    : CR261
-- Mod Details: New function TSL_UPD_SL_CRITERIA_RESTRICT to update
--              SKULIST CRITERIA with new value and custom code
----------------------------------------------------------------------------------------------------------
FUNCTION TSL_UPD_SL_CRITERIA_RESTRICT (O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                      I_skulist            IN SKULIST_CRITERIA.SKULIST%TYPE,
                                      I_item               IN SKULIST_CRITERIA.ITEM%TYPE,
                                      I_tsl_custom_field   IN TSL_REST_FIELDS.REST_CUSTOM_FIELD_NAME%TYPE,
                                      I_tsl_value          IN VARCHAR2)
   RETURN BOOLEAN is
   ---
   L_program         VARCHAR2(64)        := 'ITEMLIST_BUILD_SQL.TSL_UPD_SL_CRITERIA_RESTRICT';

   L_exists      VARCHAR2(1);
   L_data_type   USER_TAB_COLUMNS.DATA_TYPE%TYPE;


   cursor C_LOCK_SKULIST_CRITERIA is
   select 'X'
     from skulist_criteria
    where skulist = I_skulist
    for update nowait;

   cursor C_GET_SKULIST_CRITERIA is
   select 'X'
     from skulist_criteria
    where skulist = I_skulist
      and item    = I_item;

   cursor C_GET_DATA_TYPE is
   select utc.data_type
     from user_tab_columns utc,
          tsl_rest_fields tcf
   where  upper(tcf.rest_custom_field_name)  = upper(I_tsl_custom_field)
     --23-Sep-10  JK  DefNBS019234   Begin
     and  utc.column_name = upper(tcf.rest_custom_field_name)
     and  utc.table_name  = upper(tcf.rest_parent_table);
     --23-Sep-10  JK  DefNBS019234   End

BEGIN
      -- Lock the skulist_criteria record and update the tsl_rest_field and tsl_value supplier
      -- for I_skulist where the I_skulist is
      -- equal to the input skulist.

      SQL_LIB.SET_MARK('OPEN','C_LOCK_SKULIST_CRITERIA','SKULIST_CRITERIA',
                       'skulist: '|| I_skulist);
      open C_LOCK_SKULIST_CRITERIA;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_SKULIST_CRITERIA','SKULIST_CRITERIA',
                       'skulist: '|| I_skulist);
      close C_LOCK_SKULIST_CRITERIA;

      --Cursor to look up skulist exits.
      SQL_LIB.SET_MARK('OPEN','C_GET_SKULIST_CRITERIA','SKULIST_CRITERIA',
                       'skulist: '|| I_skulist);
      open C_GET_SKULIST_CRITERIA;
      SQL_LIB.SET_MARK('FETCH','C_GET_SKULIST_CRITERIA','SKULIST_CRITERIA',
                       'skulist:'|| I_skulist);
      fetch C_GET_SKULIST_CRITERIA into L_exists;

      SQL_LIB.SET_MARK('CLOSE','C_GET_SKULIST_CRITERIA','SKULIST_CRITERIA',
                       'skulist: '|| I_skulist);
      close C_GET_SKULIST_CRITERIA;

      --Cursor to get the data type for  up skulist exits.
      open C_GET_DATA_TYPE;
      SQL_LIB.SET_MARK('FETCH','C_GET_DATA_TYPE','USER_TAB_COLUMNS',
                       'column_name:'|| I_tsl_custom_field);
      fetch C_GET_DATA_TYPE into L_data_type;

      SQL_LIB.SET_MARK('CLOSE','C_GET_DATA_TYPE','USER_TAB_COLUMNS',
                       'column_name: '|| I_tsl_custom_field);
      close C_GET_DATA_TYPE;

      if L_exists is NOT NULL then
         update skulist_criteria
            set tsl_custom_field = I_tsl_custom_field,
                tsl_value        = I_tsl_value
          where skulist          = I_skulist
            and item             = I_item;
      end if;

   RETURN TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;
END TSL_UPD_SL_CRITERIA_RESTRICT;
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- CR332 01-Nov-2010 Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com Begin
---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
-- Mod By     : Bijaya Kumar Behera, Bijayakumar.Behera@in.tesco.com
-- Mod Date   : 01-Nov-2010
-- Mod Ref    : CR332
-- Mod Details: New function TSL_INS_SKULIST_STYLE_REF_CODE to insert into SKULIST_DEPT table records matching
--              Style Ref Code
----------------------------------------------------------------------------------------------------------

FUNCTION TSL_INS_SKULIST_STYLE_REF_CODE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                        I_itemlist       IN      SKULIST_HEAD.SKULIST%TYPE,
                                        I_Style_Ref_Code IN      ITEM_MASTER.ITEM_DESC_SECONDARY%TYPE)
RETURN BOOLEAN
 IS

   L_program      VARCHAR2(60)       := 'ITEMLIST_BUILD_SQL.TSL_INS_SKULIST_STYLE_REF_CODE';


   cursor C_GET_MERCH_INFO is
      select vim.dept,vim.class,vim.subclass
        from V_ITEM_MASTER vim
       where vim.item_desc_secondary = I_Style_Ref_Code;


BEGIN

   if I_itemlist is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_itemlist,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   if I_Style_Ref_Code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            I_Style_Ref_Code,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   FOR curr_rec IN C_GET_MERCH_INFO
   LOOP
      SQL_LIB.SET_MARK('INSERT',NULL,'SKULIST_DEPT','ITEMLIST: '||I_itemlist);
       insert into skulist_dept(skulist,
                                dept,
                                class,
                                subclass)
                                select I_itemlist,
                                       vsc.dept,
                                       vsc.class,
                                       vsc.subclass
                                from v_deps v,
                                     v_subclass vsc
                                where (v.dept = curr_rec.dept
                                and v.dept = vsc.dept
                                and vsc.class = curr_rec.class
                                and vsc.subclass = curr_rec.subclass)
                                and not exists (select 'x'
                                                from skulist_dept sd
                                                where sd.dept = vsc.dept
                                                and sd.class = vsc.class
                                                and sd.subclass = vsc.subclass
                                                and sd.skulist  = I_itemlist);
   END LOOP;
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      RETURN FALSE;

END TSL_INS_SKULIST_STYLE_REF_CODE;
---------------------------------------------------------------------------------------------
-- CR332 01-Nov-2010 Accenture/Bijaya Kumar Behera Bijayakumar.Behera@in.tesco.com End
---------------------------------------------------------------------------------------------
END ITEMLIST_BUILD_SQL;
/

