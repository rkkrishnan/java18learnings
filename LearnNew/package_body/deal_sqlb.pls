CREATE OR REPLACE PACKAGE BODY DEAL_SQL AS
--------------------------------------------------------------------------------
-- Mod Script : dealsqls.pls
-- Mod By     : Richard Addison
-- Mod Date   : 23.10.2007
-- Mod Ref    : ORMS 364.2
-- Mod Details: Added new function TSL_UPDATE_TSL_FUTURE_COST
--------------------------------------------------------------------------------
-- Mod By:      Wipro/JK, jayakumar.gopal@in.tesco.com
-- Mod Date:    31-Jan-2008
-- Mod Ref:     Mod number. N32
-- Mod Details: Added logic to handle Supplier group and hierarchy
--------------------------------------------------------------------------------
-- Mod By        : Wipro/Shaestha, shaestha.naz@in.tesco.com
-- Mod Date      : 07-Mar-2008
-- Mod Ref       : Mod number N53
-- Mod Details   : Modified function APPLY_ITEM_LIST
-- Function Name : APPLY_ITEM_LIST
-- Purpose:      : It should not include the non-MU Ratio Packs when the attribute SYSTEM_OPTIONS.TSL_APPLY_RP_LINK =?Y?
-----------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Mod By      : Dhuraison Prince                                                                --
-- Mod Date    : 17-Apr-2008                                                                     --
-- Mod Ref     :                                                                                 --
-- Mod Details : Added code to lock records of deal tables during update/delete operation to     --
--               avoid deadlocks.                                                                --
---------------------------------------------------------------------------------------------------
-- Defect fix by : Dhuraison Prince, dhuraison.princepraveen@wipro.com --
-- Fix date      : 17-Jun-2008                                         --
-- Defect ref    : DefNBS007069                                        --
-- Fix details   : Changed the CREATE_FROM_EXIST function and removed  --
--                 call to CALC_INITIAL_INVOICE_DATE function for 'MOI'--
--                 billing type deals.                                  --
-------------------------------------------------------------------------
-- Def fix By  : KarthikDhanapal, karthik.dhanapal@wipro.com
-- Fix Date    : 30-Jul-2008
-- Defect Ref  : NBS00008076.
-- Fix Details : Changed the insert into values for deal head table for Create from existing.
--------------------------------------------------------------------------------
-- Fix By      : Raghuveer P R                                                                   --
-- Date        : 05-Jun-2008                                                                     --
-- Ref         : NBS00006826                                                                     --
-- Details     : Added ')' and removed '(' in the function APPLY_ITEM_LIST, C_GET_SKUS Cursor    --
---------------------------------------------------------------------------------------------------
-- Mod By      : Raghuveer P R, raghuveer.perumal@in.tesco.com
-- Mod Date    : 18-May-2008
-- Mod Ref     : Mod N111
-- Mod Details : Modified APPLY_ITEMLIST function to include Common Product Functionality
---------------------------------------------------------------------------------------------------
-- Mod By        : Satish B.N satish.narasimmhaiah@in.tesco.com
-- Mod Date      : 26-Aug-2008
-- Mod Details   : Added a new parameter to TSL_APPLY_REAL_TIME_COST function call as part of DefNBS007325
----------------------------------------------------------------------------------------------------------
-- Mod By     : Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com
-- Mod Date   : 10-Sep-2008
-- Mod Ref    : DefNBS008374
-- Mod Details: Created a new function TSL_DELETE_PUB_INFO
----------------------------------------------------------------------------------------------------------
-- Mod By     : Govindarajan K, Govindarajan.Karthigeyan@in.tesco.com
-- Mod Date   : 07-May-2010
-- Mod Ref    : DefNBS017371
-- Mod Details: Modified CREATE_FROM_EXIST to load the reason code
---------------------------------------------------------------------------------------------
-- Mod By     : Amit Parab
-- Mod Date   : 10-May-2010
-- Mod Ref    : DefNBS017372 / CR280
-- Mod Details: Modified CREATE_FROM_EXIST for tsl_channel_id
--------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 20-May-2010
-- Mod Ref    : CR316
-- Mod Details: Modified CREATE_FROM_EXIST to cascade newly added columns created as part of CR316
--              to deal_head table.
---------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 01-Jun-2010
-- Mod Ref    : MrgNBS017783(Merge 3.5b to 3.5f).
-- Mod Details: Merged DefNBS017371,DefNBS017372/CR280
--------------------------------------------------------------------------------------------------
-- Mod By     : Sripriya,Sripriya.karanam@in.tesco.com
-- Mod Date   : 22-Jun-2010
-- Mod Ref    : DefNBS17928.
-- Mod Details: Modified CREATE_FROM_EXIST
--------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 22-Jul-2010
-- Mod Ref    : NBS00018414
-- Mod Details: Modified CREATE_FROM_EXIST to cascade newly added column created as part of NBS00018414
--              to deal_head table and modified DefNBS17928 fix as it's copying internal contact filed
--              for deals otherthan billback and othertner than supplier as partner type.
---------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 23-Aug-2011
-- Mod Ref    : CR378b
-- Mod Details: Modified CREATE_FROM_EXIST to cascade newly added columns created as part of CR378b
--              to deal_head table(tsl_invoice_to field) and comments field inserted using fetched
--              column for the deal passed to the function as it's LONG TYPE.
---------------------------------------------------------------------------------------------------
-- Mod By     : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date   : 19-Oct-2011
-- Mod Ref    : NBS00023772
-- Mod Details: Modified CR378b of inserting tsl_invoice_to field in CREATE_FROM_EXIST function
--              as this field is removed now.
---------------------------------------------------------------------------------------------------
   RECORD_LOCKED  EXCEPTION;
--------------------------------------------------------------------------------------------------
FUNCTION INSERT_DEAL_QUEUE(O_error_message    IN OUT VARCHAR2,
                           I_deal_id          IN     DEAL_HEAD.DEAL_ID%TYPE)

RETURN BOOLEAN IS

   L_exists    VARCHAR2(1);

   cursor C_EXISTS is
      select 'X'
        from deal_queue
       where deal_id = I_deal_id;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_EXISTS','DEAL_QUEUE', NULL);
   open C_EXISTS;
   ---
   SQL_LIB.SET_MARK('FETCH','C_EXISTS','DEAL_QUEUE', NULL);
   fetch C_EXISTS into L_exists;
   ---
   if C_EXISTS%NOTFOUND then
   SQL_LIB.SET_MARK('INSERT', NULL, 'DEAL_QUEUE', 'deal ID: '||TO_CHAR(I_deal_id));
      ---
      insert into deal_queue(deal_id)
      values (I_deal_id);
      ---
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS','DEAL_QUEUE', NULL);
   close C_EXISTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      SQL_LIB.SET_MARK('CLOSE','C_EXISTS','DEAL_QUEUE', NULL);
      close C_EXISTS;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_SQL.INSERT_DEAL_QUEUE', to_char(SQLCODE));
      return FALSE;
END INSERT_DEAL_QUEUE;
-------------------------------------------------------------------------------------------------
FUNCTION CLOSE_CONFLICT_ANNUAL_DEAL(O_error_message     IN OUT VARCHAR2,
                                    I_deal_id           IN     DEAL_HEAD.DEAL_ID%TYPE,
                                    I_user_id           IN     DEAL_HEAD.CLOSE_ID%TYPE,
                                    I_close_date        IN     DEAL_HEAD.CLOSE_DATE%TYPE)
RETURN BOOLEAN IS

   L_table        VARCHAR2(30) := 'DEAL_HEAD';
   L_close_date   DEAL_HEAD.CLOSE_DATE%TYPE   := I_close_date;
   L_active_date  DEAL_HEAD.ACTIVE_DATE%TYPE := NULL;

   cursor C_LOCK_DEAL_HEAD is
     select active_date
       from deal_head
      where deal_id = I_deal_id
        for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_HEAD','DEAL_HEAD','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_HEAD;
   ---
   SQL_LIB.SET_MARK('FETCH','C_LOCK_DEAL_HEAD','DEAL_HEAD','DEAL ID: '||to_char(I_deal_id));
   fetch C_LOCK_DEAL_HEAD into L_active_date;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_HEAD','DEAL_HEAD','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_HEAD;
   ---
   -- If the close date is less than the active date, the deal is being superceded by
   -- by a new one with the same start date.  In this case the dealcls batch program
   -- will not have a chance to run, so close the deal here and set the close date
   -- equal to the active date so the dates will be consistent.
   if I_close_date < L_active_date then
      L_close_date := L_active_date;
      SQL_LIB.SET_MARK('UPDATE',NULL,'DEAL_HEAD','DEAL ID: '||to_char(I_deal_id));
      update deal_head
         set close_date = L_close_date,
             close_id   = I_user_id,
             status     = 'C'
       where deal_id    = I_deal_id;
   else
      SQL_LIB.SET_MARK('UPDATE',NULL,'DEAL_HEAD','DEAL ID: '||to_char(I_deal_id));
      update deal_head
         set close_date = L_close_date,
             close_id   = I_user_id
       where deal_id    = I_deal_id;
   end if;
   ---
   if not INSERT_DEAL_QUEUE(O_error_message,
                            I_deal_id) then
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_deal_id),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.CLOSE_CONFLICT_ANNUAL_DEAL',
                                            to_char(SQLCODE));
      return FALSE;
END CLOSE_CONFLICT_ANNUAL_DEAL;
-------------------------------------------------------------------------------------------------
FUNCTION INSERT_DEAL_SKU_TEMP(O_error_message         IN OUT      VARCHAR2,
                              I_item                  IN          deal_sku_temp.item%TYPE,
                              I_supplier              IN          deal_sku_temp.supplier%TYPE,
                              I_origin_country_id     IN          deal_sku_temp.origin_country_id%TYPE,
                              I_start_date            IN          deal_sku_temp.start_date%TYPE,
                              I_location              IN          deal_sku_temp.location%TYPE,
                              I_loc_type              IN          deal_sku_temp.loc_type%TYPE)
RETURN BOOLEAN is
   L_vdate               PERIOD.VDATE%TYPE := GET_VDATE;
   L_division            DEAL_ITEMLOC.DIVISION%TYPE;
   L_division_name       DIVISION.DIV_NAME%TYPE;
   L_group_no            DEAL_ITEMLOC.GROUP_NO%TYPE;
   L_group_name          GROUPS.GROUP_NAME%TYPE;
   L_dept                DEAL_ITEMLOC.DEPT%TYPE;
   L_dept_name           DEPS.DEPT_NAME%TYPE;
   L_class               DEAL_ITEMLOC.CLASS%TYPE;
   L_class_name          CLASS.CLASS_NAME%TYPE;
   L_subclass            DEAL_ITEMLOC.SUBCLASS%TYPE;
   L_subclass_name       SUBCLASS.SUB_NAME%TYPE;
   L_item_grandparent    DEAL_ITEMLOC.ITEM_GRANDPARENT%TYPE;
   L_item_gp_desc        ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_parent         DEAL_ITEMLOC.ITEM_PARENT%TYPE;
   L_item_p_desc         ITEM_MASTER.ITEM_DESC%TYPE;
   L_diff_1              DEAL_ITEMLOC.DIFF_1%TYPE;
   L_diff_1_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_2              DEAL_ITEMLOC.DIFF_2%TYPE;
   L_diff_2_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_3              DEAL_ITEMLOC.DIFF_3%TYPE;
   L_diff_3_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_4              DEAL_ITEMLOC.DIFF_4%TYPE;
   L_diff_4_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_chain               DEAL_ITEMLOC.CHAIN%TYPE;
   L_chain_name          CHAIN.CHAIN_NAME%TYPE;
   L_area                DEAL_ITEMLOC.AREA%TYPE;
   L_area_name           AREA.AREA_NAME%TYPE;
   L_region              DEAL_ITEMLOC.REGION%TYPE;
   L_region_name         REGION.REGION_NAME%TYPE;
   L_district            DEAL_ITEMLOC.DISTRICT%TYPE;
   L_district_name       DISTRICT.DISTRICT_NAME%TYPE;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_SQL.INSERT_DEAL_SKU_TEMP',NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_location is not NULL and I_loc_type <> 'W' then
      ---
      if not DEAL_ATTRIB_SQL.GET_ORG_HIER(O_error_message,
                                          L_chain,
                                          L_chain_name,
                                          L_area,
                                          L_area_name,
                                          L_region,
                                          L_region_name,
                                          L_district,
                                          L_district_name,
                                          5,
                                          I_location,
                                          FALSE) then
         return FALSE;
      end if;
      ---
   end if;
   ---
   if not DEAL_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                         L_division,
                                         L_division_name,
                                         L_group_no,
                                         L_group_name,
                                         L_dept,
                                         L_dept_name,
                                         L_class,
                                         L_class_name,
                                         L_subclass,
                                         L_subclass_name,
                                         L_item_grandparent,
                                         L_item_gp_desc,
                                         L_item_parent,
                                         L_item_p_desc,
                                         L_diff_1,
                                         L_diff_1_desc,
                                         L_diff_2,
                                         L_diff_2_desc,
                                         L_diff_3,
                                         L_diff_3_desc,
                                         L_diff_4,
                                         L_diff_4_desc,
                                         12,
                                         I_item,
                                         FALSE) then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'DEAL_SKU_TEMP', 'item: '||(I_item));
   insert into deal_sku_temp(item,
                             supplier,
                             origin_country_id,
                             start_date,
                             division,
                             group_no,
                             dept,
                             class,
                             subclass,
                             item_grandparent,
                             item_parent,
                             diff_1,
                             diff_2,
                             diff_3,
                             diff_4,
                             chain,
                             area,
                             region,
                             district,
                             location,
                             loc_type)
                      select I_item,
                             i.supplier,
                             i.origin_country_id,
                             nvl(I_start_date, L_vdate),
                             L_division,
                             L_group_no,
                             L_dept,
                             L_class,
                             L_subclass,
                             L_item_grandparent,
                             L_item_parent,
                             L_diff_1,
                             L_diff_2,
                             L_diff_3,
                             L_diff_4,
                             L_chain,
                             L_area,
                             L_region,
                             L_district,
                             I_location,
                             I_loc_type
                        from item_supp_country i
                       where i.item = I_item
                         and i.supplier = nvl(I_supplier, i.supplier)
                         and i.origin_country_id = nvl(I_origin_country_id, i.origin_country_id)
                         and NOT EXISTS(select 'x'
                                          from deal_sku_temp
                                         where item = I_item
                                           and supplier = nvl(I_supplier, i.supplier)
                                           and origin_country_id = nvl(I_origin_country_id, i.origin_country_id)
                                           and start_date = nvl(I_start_date, L_vdate)
                                           and (location = I_location
                                                or location is NULL and I_location is NULL)
                                           and (loc_type = I_loc_type
                                                or loc_type is NULL and I_loc_type is NULL));
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_SQL.INSERT_DEAL_SKU_TEMP', to_char(SQLCODE));
      return FALSE;
END INSERT_DEAL_SKU_TEMP;
-------------------------------------------------------------------------------------------------
FUNCTION SWITCH_ORDER(O_error_message       IN OUT VARCHAR2,
                      I_deal_id             IN     DEAL_HEAD.DEAL_ID%TYPE,
                      I_deal_detail_id_1    IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                      I_application_order_1 IN     DEAL_DETAIL.APPLICATION_ORDER%TYPE,
                      I_deal_detail_id_2    IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                      I_application_order_2 IN     DEAL_DETAIL.APPLICATION_ORDER%TYPE)
RETURN BOOLEAN IS
   L_table   VARCHAR2(30) := 'DEAL_DETAIL';

   cursor C_LOCK_DEAL_DETAIL is
     select 'x'
       from deal_detail
      where deal_id = I_deal_id
        and (deal_detail_id = I_deal_detail_id_1
             or deal_detail_id = I_deal_detail_id_2)
        for update nowait;

BEGIN
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_DETAIL','DEAL_DETAIL','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_DETAIL;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_DETAIL','DEAL_DETAIL','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_DETAIL;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'DEAL_DETAIL','DEAL ID: '||to_char(I_deal_id));
   ---
   update deal_detail
      set application_order = (select MAX(application_order) + 1
                                 from deal_detail
                                where deal_id = I_deal_id)
    where deal_id = I_deal_id
      and deal_detail_id = I_deal_detail_id_2;
   ---
   update deal_detail
      set application_order = I_application_order_2
    where deal_id = I_deal_id
      and deal_detail_id = I_deal_detail_id_1;
   ---
   update deal_detail
      set application_order = I_application_order_1
    where deal_id = I_deal_id
      and deal_detail_id = I_deal_detail_id_2;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_deal_id),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.SWITCH_ORDER',
                                            to_char(SQLCODE));
      return FALSE;
END SWITCH_ORDER;
------------------------------------------------------------------------------------------------
FUNCTION UPDATE_APPL_ORD(O_error_message     IN OUT VARCHAR2,
                         I_deal_id           IN     DEAL_HEAD.DEAL_ID%TYPE,
                         I_application_order IN     DEAL_DETAIL.APPLICATION_ORDER%TYPE,
                         I_action_ind        IN     VARCHAR2)
RETURN BOOLEAN IS
   L_table   VARCHAR2(30) := 'DEAL_DETAIL';

   cursor C_LOCK_DEAL_DETAIL is
     select 'x'
       from deal_detail
      where deal_id = I_deal_id
        and application_order >= I_application_order
        for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_DETAIL','DEAL_DETAIL','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_DETAIL;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_DETAIL','DEAL_DETAIL','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_DETAIL;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'DEAL_DETAIL','DEAL ID: '||to_char(I_deal_id));
   ---
   if I_action_ind = 'D' then
      update deal_detail
         set application_order = application_order - 1
       where deal_id = I_deal_id
         and application_order > I_application_order;
   elsif I_action_ind = 'I' then
      update deal_detail
         set application_order = application_order + 1
       where deal_id = I_deal_id
         and application_order >= I_application_order;
   end if;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_deal_id),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.UPDATE_APPL_ORD',
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_APPL_ORD;
-------------------------------------------------------------------------------------------------
FUNCTION CHECK_SUBMIT(O_error_message    IN OUT VARCHAR2,
                      O_exists           IN OUT BOOLEAN,
                      I_deal_id          IN     DEAL_HEAD.DEAL_ID%TYPE)
RETURN BOOLEAN IS
   L_detail_exists        VARCHAR2(1);
   L_dummy                VARCHAR2(1) := null;
   L_deal_type            DEAL_HEAD.TYPE%TYPE;

   cursor C_DEAL_DETAILS_EXIST is
      select 'x'
        from deal_detail
       where deal_id = I_deal_id;

   cursor C_GET_DEAL_TYPE is
      select deal_head.type
        from deal_head
       where deal_head.deal_id = I_deal_id;

   cursor C_DEAL_DETAIL_ID is
      select 'x'
        from deal_detail
       where deal_id = I_deal_id
         and threshold_value_type != 'Q'
         and ((tran_discount_ind = 'N'
         and (NOT EXISTS(select 'x'
                           from deal_itemloc
                          where deal_id = deal_detail.deal_id
                            and deal_itemloc.deal_detail_id = deal_detail.deal_detail_id)
              or NOT EXISTS(select 'x'
                              from deal_threshold
                             where deal_threshold.deal_id = deal_detail.deal_id
                               and deal_threshold.deal_detail_id = deal_detail.deal_detail_id)))
          or (tran_discount_ind = 'Y'
         and NOT EXISTS (select 'x'
                           from deal_threshold
                          where deal_threshold.deal_id = deal_detail.deal_id
                            and deal_threshold.deal_detail_id = deal_detail.deal_detail_id)));

      cursor C_DETAIL_VFM is
         select 'x'
           from deaL_detail
          where deal_id = I_deal_id
            and (NOT EXISTS(select 'x'
                             from deal_itemloc
                            where deal_id = deal_detail.deal_id
                              and deal_itemloc.deal_detail_id = deal_detail.deal_detail_id));

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_DEAL_DETAIL_EXIST', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   open C_DEAL_DETAILS_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_DEAL_DETAIL_EXIST', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   fetch C_DEAL_DETAILS_EXIST into L_detail_exists;
   ---
   if C_DEAL_DETAILS_EXIST%NOTFOUND then
      O_exists := FALSE;
   else
      SQL_LIB.SET_MARK('OPEN', 'C_GET_DEAL_TYPE', 'DEAL_HEAD', 'deal id '||TO_CHAR(I_deal_id));
      open C_GET_DEAL_TYPE;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_GET_DEAL_TYPE', 'DEAL_HEAD', 'deal id '||TO_CHAR(I_deal_id));
      fetch C_GET_DEAL_TYPE into L_deal_type;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_DEAL_TYPE', 'DEAL_HEAD', 'deal id '||TO_CHAR(I_deal_id));
      close C_GET_DEAL_TYPE;
      ---
      if L_deal_type != 'M' then
         SQL_LIB.SET_MARK('OPEN','C_DEAL_DETAIL_ID', 'DEAL_DETAIL, DEAL_ITEMLOC, DEAL_THRESHOLD', 'deal id: '||TO_CHAR(I_deal_id));
         open C_DEAL_DETAIL_ID;
         ---
         SQL_LIB.SET_MARK('FETCH','C_DEAL_DETAIL_ID', 'DEAL_DETAIL, DEAL_ITEMLOC, DEAL_THRESHOLD', 'deal id: '||TO_CHAR(I_deal_id));
         fetch C_DEAL_DETAIL_ID into L_dummy;
         ---
         SQL_LIB.SET_MARK('CLOSE','C_DEAL_DETAIL_ID', 'DEAL_DETAIL, DEAL_ITEMLOC, DEAL_THRESHOLD', 'deal id: '||TO_CHAR(I_deal_id));
         close C_DEAL_DETAIL_ID;
         ---
         if L_dummy is not null then
            O_exists := FALSE;
         end if;
         ---
      else
         SQL_LIB.SET_MARK('OPEN','C_DETAIL_VFM', 'DEAL_DETAIL, DEAL_ITEMLOC', 'deal id: '||TO_CHAR(I_deal_id));
         open C_DETAIL_VFM;
         ---
         SQL_LIB.SET_MARK('FETCH','C_DETAIL_VFM', 'DEAL_DETAIL, DEAL_ITEMLOC', 'deal id: '||TO_CHAR(I_deal_id));
         fetch C_DETAIL_VFM into L_dummy;
         ---
         SQL_LIB.SET_MARK('CLOSE','C_DETAIL_VFM', 'DEAL_DETAIL, DEAL_ITEMLOC', 'deal id: '||TO_CHAR(I_deal_id));
         close C_DETAIL_VFM;
         ---
         if L_dummy is not null then
            O_exists := FALSE;
         end if;
         ---
      end if;
      ---
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_DEAL_DETAIL_EXIST', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   close C_DEAL_DETAILS_EXIST;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_SQL.CHECK_SUBMIT', to_char(SQLCODE));
      return FALSE;
END CHECK_SUBMIT;
-------------------------------------------------------------------------------------------------
FUNCTION APPLY_ITEM_LIST(O_error_message      IN OUT VARCHAR2,
                         O_conflict_exists    IN OUT BOOLEAN,
                         O_item_sup_ind       IN OUT VARCHAR2,
                         I_item_list          IN     SKULIST_HEAD.SKULIST%TYPE,
                         I_deal_id            IN     DEAL_HEAD.DEAL_ID%TYPE,
                         I_deal_detail_id     IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                         I_partner_type       IN     PARTNER.PARTNER_TYPE%TYPE,
                         I_partner_id         IN     PARTNER.PARTNER_ID%TYPE,
                         I_supplier           IN     SUPS.SUPPLIER%TYPE,
                         I_origin_country_id  IN     COUNTRY.COUNTRY_ID%TYPE,
                         I_org_level          IN     DEAL_ITEMLOC.ORG_LEVEL%TYPE,
                         I_loc_type           IN     DEAL_ITEMLOC.LOC_TYPE%TYPE,
                         I_org_value          IN     NUMBER,
                         I_excl_ind           IN     DEAL_ITEMLOC.EXCL_IND%TYPE)
RETURN BOOLEAN IS
   L_table               VARCHAR2(30) := 'DEAL_ITEMLOC';
   L_seq_no              DEAL_ITEMLOC.SEQ_NO%TYPE;
   L_division            DEAL_ITEMLOC.DIVISION%TYPE;
   L_division_name       DIVISION.DIV_NAME%TYPE;
   L_group_no            DEAL_ITEMLOC.GROUP_NO%TYPE;
   L_group_name          GROUPS.GROUP_NAME%TYPE;
   L_dept                DEAL_ITEMLOC.DEPT%TYPE;
   L_dept_name           DEPS.DEPT_NAME%TYPE;
   L_class               DEAL_ITEMLOC.CLASS%TYPE;
   L_class_name          CLASS.CLASS_NAME%TYPE;
   L_subclass            DEAL_ITEMLOC.SUBCLASS%TYPE;
   L_subclass_name       SUBCLASS.SUB_NAME%TYPE;
   L_item_grandparent    DEAL_ITEMLOC.ITEM_GRANDPARENT%TYPE;
   L_item_gp_desc        ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_parent         DEAL_ITEMLOC.ITEM_PARENT%TYPE;
   L_item_p_desc         ITEM_MASTER.ITEM_DESC%TYPE;
   L_diff_1              DEAL_ITEMLOC.DIFF_1%TYPE;
   L_diff_1_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_2              DEAL_ITEMLOC.DIFF_2%TYPE;
   L_diff_2_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_3              DEAL_ITEMLOC.DIFF_3%TYPE;
   L_diff_3_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_4              DEAL_ITEMLOC.DIFF_4%TYPE;
   L_diff_4_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_chain               DEAL_ITEMLOC.CHAIN%TYPE;
   L_chain_name          CHAIN.CHAIN_NAME%TYPE;
   L_area                DEAL_ITEMLOC.AREA%TYPE;
   L_area_name           AREA.AREA_NAME%TYPE;
   L_region              DEAL_ITEMLOC.REGION%TYPE;
   L_region_name         REGION.REGION_NAME%TYPE;
   L_district            DEAL_ITEMLOC.DISTRICT%TYPE;
   L_district_name       DISTRICT.DISTRICT_NAME%TYPE;
   L_merch_level         VARCHAR2(30);
   L_valid               BOOLEAN;
   L_location            NUMBER;
   L_item                DEAL_ITEMLOC.ITEM%TYPE;
   -- 07-Mar-2008 Wipro/Shaestha   ModN53  Begin
   L_apply_rp_link       SYSTEM_OPTIONS.TSL_APPLY_RP_LINK%TYPE;
   L_billing_type        DEAL_HEAD.BILLING_TYPE%TYPE;
   -- 07-Mar-2008 Wipro/Shaestha   ModN53  End
   -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 Begin
   L_origin_country      ITEM_MASTER.TSL_PRIMARY_COUNTRY%TYPE;
   L_apply_common_prd    SYSTEM_OPTIONS.TSL_COMMON_PRODUCT_IND%TYPE;
   L_system_options_row  SYSTEM_OPTIONS%ROWTYPE;
   -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 End

   cursor C_GET_SKUS is
      select /*+ no_expand */
             m.item item,
             m.item_level item_level,
             m.tran_level tran_level
        from skulist_detail s,
             item_master m,
             item_supp_country i,
             -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 Begin
             item_supplier isp
             -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 End
       where s.skulist = I_item_list
         and i.item = m.item
         and m.item = s.item
         and m.item_level = m.tran_level
         and m.status = 'A'
         and i.origin_country_id = NVL(I_origin_country_id, i.origin_country_id)
         and NVL(m.pack_type,-1) = DECODE(s.pack_ind, 'P', 'V', NVL (m.pack_type,-1))
         and ((i.supplier = I_supplier and I_partner_type = 'S')
          or (i.supp_hier_lvl_1 = I_partner_id and I_partner_type = 'S1')
          or (i.supp_hier_lvl_2 = I_partner_id and I_partner_type = 'S2')
         -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - Begin
          or (i.supp_hier_lvl_3 = I_partner_id and I_partner_type = 'S3')/* removeed ')' as a fix to NBS00006826 */
         -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - End
         -- 30-Jan-2008   Wipro/JK  Mod N32 Begin
          or (I_partner_type = 'SG'
         and i.supplier in (select sgd.supplier
                              from tsl_sups_group_detail sgd
                             where sgd.group_id = I_partner_id))
          or (I_partner_type = 'SH'
         and exists (select tsh.element_id
                       from tsl_sups_hier tsh
                      where tsh.element_id = i.supplier
                      start with tsh.hier_id  = I_partner_id
                    -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - Begin
                    connect by prior tsh.element_id = tsh.parent_element_id)))/* added ')' as a fix to NBS00006826 */
                    -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - End
         -- 30-Jan-2008   Wipro/JK  Mod N32 End
         -- 07-Mar-2008 Wipro/Shaestha   ModN53  Begin
         and NOT (m.pack_type              = 'V'
             and m.pack_ind                = 'Y'
             and m.simple_pack_ind         = 'N'
             and m.orderable_ind           = 'Y'
             and m.tsl_mu_ind              = 'N'
             and NVL(L_apply_rp_link, 'N') = 'Y')
          -- 07-Mar-2008 Wipro/Shaestha   ModN53  End
          -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 Begin
         and m.item     = isp.item
         and i.supplier = isp.supplier
         and NOT (m.tsl_common_ind = 'Y'
             and L_apply_common_prd = 'Y'
             and ((I_partner_type = 'S'
                  and m.tsl_primary_country != L_origin_country
                  and m.tsl_primary_country is NOT NULL
                  and isp.tsl_channel_id in ('1Y','2Y','3Y'))
                  or(I_partner_type in ('SG','SH'))))
         -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 End
       UNION
      select /*+ no_expand */
             m.item item,
             m.item_level item_level,
             m.tran_level tran_level
        from skulist_detail s,
             item_master m,
             item_supp_country i,
             -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 Begin
             item_supplier isp
             -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 End
       where s.skulist = I_item_list
         and i.item = m.item
         and m.item_parent = s.item
         and m.item_level = m.tran_level
         and m.status = 'A'
         and i.origin_country_id = NVL(I_origin_country_id, i.origin_country_id)
         and NVL(m.pack_type,-1) = DECODE(s.pack_ind, 'P', 'V', NVL (m.pack_type,-1))
         and ((i.supplier = I_supplier and I_partner_type = 'S')
          or (i.supp_hier_lvl_1 = I_partner_id and I_partner_type = 'S1')
          or (i.supp_hier_lvl_2 = I_partner_id and I_partner_type = 'S2')
          -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - Begin
          or (i.supp_hier_lvl_3 = I_partner_id and I_partner_type = 'S3')/* removeed ')' as a fix to NBS00006826 */
          -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - End
         -- 30-Jan-2008   Wipro/JK  Mod N32 Begin
          or (I_partner_type = 'SG'
         and i.supplier in (select sgd.supplier
                              from tsl_sups_group_detail sgd
                             where sgd.group_id = I_partner_id))
          or (I_partner_type = 'SH'
         and exists (select tsh.element_id
                       from tsl_sups_hier tsh
                      where tsh.element_id = i.supplier
                      start with tsh.hier_id  = I_partner_id
                    -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - Begin
                    connect by prior tsh.element_id = tsh.parent_element_id)))/* added ')' as a fix to NBS00006826 */
                    -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - End
         -- 30-Jan-2008   Wipro/JK  Mod N32 End
         -- 07-Mar-2008 Wipro/Shaestha   ModN53  Begin
         and NOT (m.pack_type              = 'V'
             and m.pack_ind                = 'Y'
             and m.simple_pack_ind         = 'N'
             and m.orderable_ind           = 'Y'
             and m.tsl_mu_ind              = 'N'
             and NVL(L_apply_rp_link, 'N') = 'Y')
          -- 07-Mar-2008 Wipro/Shaestha   ModN53  End
          -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 Begin
         and m.item     = isp.item
         and i.supplier = isp.supplier
         and NOT (m.tsl_common_ind = 'Y'
             and L_apply_common_prd = 'Y'
             and ((I_partner_type = 'S'
                  and m.tsl_primary_country != L_origin_country
                  and m.tsl_primary_country is NOT NULL
                  and isp.tsl_channel_id in ('1Y','2Y','3Y'))
                  or(I_partner_type in ('SG','SH'))))
         -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 End
       UNION
      select /*+ no_expand */
             m.item item,
             m.item_level item_level,
             m.tran_level tran_level
        from skulist_detail s,
             item_master m,
             item_supp_country i,
             -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 Begin
             item_supplier isp
             -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 End
       where s.skulist = I_item_list
         and i.item = m.item
         and m.item_grandparent = s.item
         and m.item_level = m.tran_level
         and m.status = 'A'
         and i.origin_country_id = NVL(I_origin_country_id, i.origin_country_id)
         and NVL(m.pack_type,-1) = DECODE(s.pack_ind, 'P', 'V', NVL (m.pack_type,-1))
         and ((i.supplier = I_supplier and I_partner_type = 'S')
          or (i.supp_hier_lvl_1 = I_partner_id and I_partner_type = 'S1')
          or (i.supp_hier_lvl_2 = I_partner_id and I_partner_type = 'S2')
          -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - Begin
          or (i.supp_hier_lvl_3 = I_partner_id and I_partner_type = 'S3')/* removeed ')' as a fix to NBS00006826 */
          -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - End
         -- 30-Jan-2008   Wipro/JK  Mod N32 Begin
          or (I_partner_type = 'SG'
         and i.supplier in (select sgd.supplier
                              from tsl_sups_group_detail sgd
                             where sgd.group_id = I_partner_id))
          or (I_partner_type = 'SH'
         and exists (select tsh.element_id
                       from tsl_sups_hier tsh
                      where tsh.element_id = i.supplier
                      start with tsh.hier_id  = I_partner_id
                    -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - Begin
                    connect by prior tsh.element_id = tsh.parent_element_id)))/* added ')' as a fix to NBS00006826 */
                    -- NBS00006826, 5-Jun-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com - End
         -- 30-Jan-2008   Wipro/JK  Mod N32 End
         -- 07-Mar-2008 Wipro/Shaestha   ModN53  Begin
         and NOT (m.pack_type              = 'V'
             and m.pack_ind                = 'Y'
             and m.simple_pack_ind         = 'N'
             and m.orderable_ind           = 'Y'
             and m.tsl_mu_ind              = 'N'
             and NVL(L_apply_rp_link, 'N') = 'Y')
          -- 07-Mar-2008 Wipro/Shaestha   ModN53  End
          -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 Begin
         and m.item     = isp.item
         and i.supplier = isp.supplier
         and NOT (m.tsl_common_ind = 'Y'
             and L_apply_common_prd = 'Y'
             and ((I_partner_type = 'S'
                  and m.tsl_primary_country != L_origin_country
                  and m.tsl_primary_country is NOT NULL
                  and isp.tsl_channel_id in ('1Y','2Y','3Y'))
                  or(I_partner_type in ('SG','SH'))));
         -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 End

   cursor C_LOCK_DEAL_ITEMLOC is
     select 'x'
       from deal_itemloc
      where deal_id        = I_deal_id
        and deal_detail_id = I_deal_detail_id
        for update nowait;

BEGIN
   if I_item_list is NULL or
      I_deal_id is NULL or
      I_deal_detail_id is NULL or
      I_partner_type is NULL or
      (I_partner_id is NULL and I_supplier is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_SQL.APPLY_ITEM_LIST',NULL,NULL);
      return FALSE;
   end if;
   ---
   if (I_loc_type <> 'W' or I_loc_type is NULL) and I_org_level is not NULL then
      if not DEAL_ATTRIB_SQL.GET_ORG_HIER(O_error_message,
                                          L_chain,
                                          L_chain_name,
                                          L_area,
                                          L_area_name,
                                          L_region,
                                          L_region_name,
                                          L_district,
                                          L_district_name,
                                          I_org_level,
                                          I_org_value,
                                          FALSE) then
         return FALSE;
      end if;
   end if;
   ---
   if I_loc_type = 'W' or I_org_level = 5 then
      L_location := I_org_value;
   else
      L_location := NULL;
   end if;
   ---
   if I_org_level = 1 then
      L_chain := I_org_value;
   elsif I_org_level = 2 then
      L_area := I_org_value;
   elsif I_org_level = 3 then
      L_region := I_org_value;
   elsif I_org_level = 4 then
      L_district := I_org_value;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_ITEMLOC','DEAL_ITEMLOC','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_ITEMLOC;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_ITEMLOC','DEAL_ITEMLOC','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_ITEMLOC;
   ---
   O_item_sup_ind  := 'N';
   ---
   -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 Begin
   -- 07-Mar-2008 Wipro/Shaestha   ModN53  Begin
   /*if (SYSTEM_OPTIONS_SQL.TSL_GET_APPLY_RP_LINK (O_error_message,
                                                 L_apply_rp_link)) = FALSE then
      return FALSE;
   end if;*/
   -- Commented the above lines as part of Mod N111

   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                            L_system_options_row) = FALSE then
      return FALSE;
   end if;

   L_apply_rp_link    := L_system_options_row.tsl_apply_rp_link;
   L_apply_common_prd := L_system_options_row.tsl_common_product_ind;
   L_origin_country   := L_system_options_row.tsl_origin_country;

   -- 08-May-2008 Raghuveer P R, raghuveer.perumal@in.tesco.com ModN111 End

   if (L_apply_rp_link = 'Y') then
      if (DEAL_ATTRIB_SQL.TSL_GET_BILLING_TYPE (O_error_message,
                                                L_billing_type,
                                                I_deal_id)) = FALSE then
         return FALSE;
      end if;

      if (L_billing_type not in ( 'MOI','MBB')) then
         L_apply_rp_link :='N';
      end if;
   end if;
   -- 07-Mar-2008 Wipro/Shaestha   ModN53  End
   FOR rec IN C_GET_SKUS LOOP
      ---
      O_item_sup_ind  := 'Y';
      ---
      if rec.item_level = rec.tran_level then
         L_merch_level := '12';
         L_item        := rec.item;
      elsif rec.item_level < rec.tran_level then
         L_merch_level := '7';
      end if;
      ---
      if not DEAL_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                            L_division,
                                            L_division_name,
                                            L_group_no,
                                            L_group_name,
                                            L_dept,
                                            L_dept_name,
                                            L_class,
                                            L_class_name,
                                            L_subclass,
                                            L_subclass_name,
                                            L_item_grandparent,
                                            L_item_gp_desc,
                                            L_item_parent,
                                            L_item_p_desc,
                                            L_diff_1,
                                            L_diff_1_desc,
                                            L_diff_2,
                                            L_diff_2_desc,
                                            L_diff_3,
                                            L_diff_3_desc,
                                            L_diff_4,
                                            L_diff_4_desc,
                                            L_merch_level,
                                            rec.item,
                                            FALSE) then
         return FALSE;
      end if;
      ---
      if not DEAL_VALIDATE_SQL.VALIDATE_ITEMLOC(O_error_message,
                                                L_valid,
                                                I_deal_id,
                                                I_deal_detail_id,
                                                L_merch_level,
                                                I_org_level,
                                                I_origin_country_id,
                                                NULL,
                                                L_division,
                                                L_group_no,
                                                L_dept,
                                                L_class,
                                                L_subclass,
                                                L_item_grandparent,
                                                L_item_parent,
                                                L_diff_1,
                                                L_diff_2,
                                                L_diff_3,
                                                L_diff_4,
                                                L_item,
                                                L_chain,
                                                L_area,
                                                L_region,
                                                L_district,
                                                I_loc_type,
                                                L_location,
                                                I_excl_ind) then
         return FALSE;
      end if;
      ---
      if L_valid = FALSE then
         O_conflict_exists := TRUE;
      else
         ---
         if not DEAL_ATTRIB_SQL.GET_NEXT_DEALITLC_SEQ(O_error_message,
                                                      L_seq_no,
                                                      I_deal_id,
                                                      I_deal_detail_id) then
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('INSERT',NULL,'DEAL_ITEMLOC','DEAL ID: '||to_char(I_deal_id));
         insert into deal_itemloc(deal_id,
                                  deal_detail_id,
                                  seq_no,
                                  merch_level,
                                  company_ind,
                                  division,
                                  group_no,
                                  dept,
                                  class,
                                  subclass,
                                  item_grandparent,
                                  item_parent,
                                  diff_1,
                                  diff_2,
                                  diff_3,
                                  diff_4,
                                  org_level,
                                  chain,
                                  area,
                                  region,
                                  district,
                                  location,
                                  loc_type,
                                  origin_country_id,
                                  item,
                                  excl_ind,
                                  create_datetime,
                                  last_update_id,
                                  last_update_datetime)
                           values(I_deal_id,
                                  I_deal_detail_id,
                                  L_seq_no,
                                  L_merch_level,
                                  'N',
                                  L_division,
                                  L_group_no,
                                  L_dept,
                                  L_class,
                                  L_subclass,
                                  L_item_grandparent,
                                  L_item_parent,
                                  L_diff_1,
                                  L_diff_2,
                                  L_diff_3,
                                  L_diff_4,
                                  I_org_level,
                                  DECODE(I_org_level, 1, I_org_value, L_chain),
                                  DECODE(I_org_level, 2, I_org_value, L_area),
                                  DECODE(I_org_level, 3, I_org_value, L_region),
                                  DECODE(I_org_level, 4, I_org_value, L_district),
                                  L_location,
                                  I_loc_type,
                                  I_origin_country_id,
                                  L_item,
                                  I_excl_ind,
                                  sysdate,
                                  user,
                                  sysdate);
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_deal_id),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.APPL_ITEM_LIST',
                                            to_char(SQLCODE));
   return FALSE;
END APPLY_ITEM_LIST;
-------------------------------------------------------------------------------------------------
FUNCTION INSERT_DEAL_CALC_QUEUE(O_error_message         IN OUT  VARCHAR2,
                                I_order_no              IN      deal_calc_queue.order_no%TYPE,
                                I_recalc_all_ind        IN      deal_calc_queue.recalc_all_ind%TYPE,
                                I_override_manual_ind   IN      deal_calc_queue.override_manual_ind%TYPE,
                                I_order_appr_ind        IN      deal_calc_queue.order_appr_ind%TYPE)
RETURN BOOLEAN IS
   L_exists     deal_calc_queue.order_no%TYPE;

BEGIN
   SQL_LIB.SET_MARK('UPDATE',NULL,'DEAL_CALC_QUEUE','ORDER NO: '||to_char(I_order_no));
   update deal_calc_queue
      set recalc_all_ind      = DECODE(I_recalc_all_ind, 'Y', 'Y', recalc_all_ind),
          override_manual_ind = DECODE(I_override_manual_ind, 'Y', 'Y', override_manual_ind),
          order_appr_ind      = DECODE(I_order_appr_ind, 'Y', 'Y', order_appr_ind)
    where order_no = I_order_no;
   ---
   if SQL%NOTFOUND then
      SQL_LIB.SET_MARK('INSERT',NULL,'DEAL_CALC_QUEUE','ORDER NO: '||to_char(I_order_no));
      insert into deal_calc_queue(order_no,
                                  recalc_all_ind,
                                  override_manual_ind,
                                  order_appr_ind)
                           values(I_order_no,
                                  I_recalc_all_ind,
                                  I_override_manual_ind,
                                  I_order_appr_ind);
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.INSERT_DEAL_CALC_QUEUE',
                                            to_char(SQLCODE));
   return FALSE;
END INSERT_DEAL_CALC_QUEUE;
-------------------------------------------------------------------------------------------------
FUNCTION UPDATE_THRESH_TARGET_IND(O_error_message    IN OUT VARCHAR2,
                                  I_deal_id          IN OUT DEAL_HEAD.DEAL_ID%TYPE,
                                  I_deal_detail_id   IN OUT DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                                  I_lower            IN DEAL_THRESHOLD.LOWER_LIMIT%TYPE,
                                  I_upper            IN DEAL_THRESHOLD.UPPER_LIMIT%TYPE,
                                  I_value            IN DEAL_THRESHOLD.VALUE%TYPE)
RETURN BOOLEAN IS
   L_table         VARCHAR2(64) := 'DEAL_THRESHOLD';
   -- Applying Locks, 06-May-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   -- Applying Locks, 06-May-2008, Nitin Gour, nitin.gour@in.tesco.com (END

   cursor C_LOCK_DEAL_THRESHOLD is
     select 'x'
       from deal_threshold
      where deal_id = I_deal_id
        and deal_detail_id = I_deal_detail_id
        for update nowait;

   -- Applying Locks, 06-May-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   cursor C_LOCK_DEAL_THRESHOLD2 is
     select 'x'
       from deal_threshold
      where deal_id = I_deal_id
        and deal_detail_id = I_deal_detail_id
        and lower_limit = I_lower
        and upper_limit = I_upper
        and value = I_value
        for update nowait;
   -- Applying Locks, 06-May-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
BEGIN
   if I_deal_id is NULL or I_deal_detail_id is NULL or I_lower is NULL
      or I_upper is NULL or I_value is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_SQL.UPDATE_THRESH_TARGET_IND',NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_THRESHOLD','DEAL_THRESHOLD','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_THRESHOLD;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_THRESHOLD','DEAL_THRESHOLD','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_THRESHOLD;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'DEAL_THRESHOLD','DEAL ID: '||to_char(I_deal_id));
   ---
   update deal_threshold
      set target_level_ind = 'N'
    where deal_id = I_deal_id
      and deal_detail_id = I_deal_detail_id;
   ---
   -- Applying Locks, 06-May-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_THRESHOLD2','DEAL_THRESHOLD','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_THRESHOLD2;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_DEAL_THRESHOLD2','DEAL_THRESHOLD','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_THRESHOLD2;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'DEAL_THRESHOLD','DEAL ID: '||to_char(I_deal_id));
   ---
   -- Applying Locks, 06-May-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
   update deal_threshold
      set target_level_ind = 'Y'
    where deal_id = I_deal_id
      and deal_detail_id = I_deal_detail_id
      and lower_limit = I_lower
      and upper_limit = I_upper
      and value = I_value;

   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
        O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                              L_table,
                                              I_deal_id,
                                              NULL);
        return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.UPDATE_THRESH_TARGET_IND',
                                            to_char(SQLCODE));
   return FALSE;
END UPDATE_THRESH_TARGET_IND;
-------------------------------------------------------------------------------------------------
FUNCTION INSERT_PO_DEAL(O_error_message  IN OUT  VARCHAR2,
                        O_deal_id        IN OUT  deal_head.deal_id%TYPE,
                        I_order_no       IN      deal_head.order_no%TYPE,
                        I_supplier       IN      deal_head.supplier%TYPE,
                        I_currency_code  IN      deal_head.currency_code%TYPE,
                        I_active_date    IN      deal_head.active_date%TYPE,
                        I_create_date    IN      deal_head.create_datetime%TYPE,
                        I_approval_date  IN      deal_head.approval_date%TYPE,
                        I_user_id        IN      deal_head.create_id%TYPE,
                        I_ext_ref_no     IN      deal_head.ext_ref_no%TYPE,
                        I_comments       IN      deal_head.comments%TYPE,
                        I_billing_type                 IN   DEAL_HEAD.BILLING_TYPE%TYPE,
                        I_bill_back_period             IN   DEAL_HEAD.BILL_BACK_PERIOD%TYPE,
                        I_deal_appl_timing             IN   DEAL_HEAD.DEAL_APPL_TIMING%TYPE,
                        I_threshold_limit_type         IN   DEAL_HEAD.THRESHOLD_LIMIT_TYPE%TYPE,
                        I_threshold_limit_uom          IN   DEAL_HEAD.THRESHOLD_LIMIT_UOM%TYPE,
                        I_rebate_ind                   IN   DEAL_HEAD.REBATE_IND%TYPE,
                        I_rebate_calc_type             IN   DEAL_HEAD.REBATE_CALC_TYPE%TYPE,
                        I_growth_rebate_ind            IN   DEAL_HEAD.GROWTH_REBATE_IND%TYPE,
                        I_historical_comp_start_date   IN   DEAL_HEAD.HISTORICAL_COMP_START_DATE%TYPE,
                        I_historical_comp_end_date     IN   DEAL_HEAD.HISTORICAL_COMP_END_DATE%TYPE,
                        I_rebate_purch_sales_ind       IN   DEAL_HEAD.REBATE_PURCH_SALES_IND%TYPE,
                        I_deal_reporting_level         IN   DEAL_HEAD.DEAL_REPORTING_LEVEL%TYPE,
                        I_bill_back_method             IN   DEAL_HEAD.BILL_BACK_METHOD%TYPE,
                        I_deal_income_calculation      IN   DEAL_HEAD.DEAL_INCOME_CALCULATION%TYPE,
                        I_invoice_processing_logic     IN   DEAL_HEAD.INVOICE_PROCESSING_LOGIC%TYPE,
                        I_stock_ledger_ind             IN   DEAL_HEAD.STOCK_LEDGER_IND%TYPE,
                        I_include_vat_ind              IN   DEAL_HEAD.INCLUDE_VAT_IND%TYPE,
                        I_billing_partner_type         IN   DEAL_HEAD.BILLING_PARTNER_TYPE%TYPE,
                        I_billing_partner_id           IN   DEAL_HEAD.BILLING_PARTNER_ID%TYPE,
                        I_billing_supplier_id          IN   DEAL_HEAD.BILLING_SUPPLIER_ID%TYPE,
                        I_growth_rate_to_date          IN   DEAL_HEAD.GROWTH_RATE_TO_DATE%TYPE,
                        I_turnover_to_date             IN   DEAL_HEAD.TURNOVER_TO_DATE%TYPE,
                        I_actual_monies_earned_to_date IN   DEAL_HEAD.ACTUAL_MONIES_EARNED_TO_DATE%TYPE,
                        I_security_ind                 IN   DEAL_HEAD.SECURITY_IND%TYPE,
                        I_est_next_invoice_date        IN   DEAL_HEAD.EST_NEXT_INVOICE_DATE%TYPE,
                        I_last_invoice_date            IN   DEAL_HEAD.LAST_INVOICE_DATE%TYPE)

RETURN BOOLEAN AS
   L_deal_id          deal_head.deal_id%TYPE;
   L_vdate            PERIOD.VDATE%TYPE := GET_VDATE;
   L_supplier         deal_head.supplier%TYPE;
   L_currency_code    deal_head.currency_code%TYPE;
   L_active_date      deal_head.active_date%TYPE;
   L_status           ordhead.status%TYPE;

   cursor C_GET_ORDHEAD is
      select supplier,
             currency_code,
             not_before_date
        from ordhead
       where order_no = I_order_no;

BEGIN
   if I_order_no is NULL or I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_SQL.INSERT_PO_DEAL',NULL,NULL);
      return FALSE;
   end if;

   if I_billing_type          is NULL
   or I_rebate_ind            is NULL
   or I_growth_rebate_ind     is NULL
   or I_stock_ledger_ind      is NULL
   or I_include_vat_ind       is NULL
   or I_billing_partner_type  is NULL
   or I_security_ind          is NULL
     then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_SQL.INSERT_PO_DEAL',NULL,NULL);
      return FALSE;
   end if;

   ---
   if not DEAL_ATTRIB_SQL.GET_NEXT_DEAL_ID(O_error_message,
                                           L_deal_id) then
      return FALSE;
   end if;
   ---
   if I_supplier is NULL or I_currency_code is NULL or I_active_date is NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_ORDHEAD','ORDHEAD','ORDER NO: '||to_char(I_order_no));
      open C_GET_ORDHEAD;
      SQL_LIB.SET_MARK('FETCH','C_GET_ORDHEAD','ORDHEAD','ORDER NO: '||to_char(I_order_no));
      fetch C_GET_ORDHEAD into L_supplier, L_currency_code, L_active_date;
      SQL_LIB.SET_MARK('CLOSE','C_GET_ORDHEAD','ORDHEAD','ORDER NO: '||to_char(I_order_no));
           close C_GET_ORDHEAD;
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT',NULL,'DEAL_HEAD','ORDER NO: '||to_char(I_order_no));
   insert into deal_head(deal_id,
                         partner_type,
                         partner_id,
                         supplier,
                         type,
                         status,
                         currency_code,
                         active_date,
                         close_date,
                         close_id,
                         create_datetime,
                         create_id,
                         approval_date,
                         approval_id,
                         reject_date,
                         reject_id,
                         ext_ref_no,
                         order_no,
                         recalc_approved_orders,
                         comments,
                         last_update_id,
                         last_update_datetime,
                         billing_type,
                         bill_back_period,
                         deal_appl_timing,
                         threshold_limit_type,
                         threshold_limit_uom,
                         rebate_ind,
                         rebate_calc_type,
                         growth_rebate_ind,
                         historical_comp_start_date,
                         historical_comp_end_date,
                         rebate_purch_sales_ind,
                         deal_reporting_level,
                         bill_back_method,
                         deal_income_calculation,
                         invoice_processing_logic,
                         stock_ledger_ind,
                         include_vat_ind,
                         billing_partner_type,
                         billing_partner_id,
                         billing_supplier_id,
                         growth_rate_to_date,
                         turnover_to_date,
                         actual_monies_earned_to_date,
                         security_ind,
                         est_next_invoice_date,
                         last_invoice_date)
                  values(L_deal_id,
                         'S',
                         NULL,
                         nvl(I_supplier, L_supplier),
                         'O',
                         'W',
                         nvl(I_currency_code, L_currency_code),
                         nvl(I_active_date, L_active_date),
                         NULL,
                         NULL,
                         nvl(I_create_date, L_vdate),
                         I_user_id,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         I_ext_ref_no,
                         I_order_no,
                         'N',
                         I_comments,
                         user,
                         sysdate,
                         I_billing_type,
                         I_bill_back_period,
                         I_deal_appl_timing,
                         I_threshold_limit_type,
                         I_threshold_limit_uom,
                         I_rebate_ind,
                         I_rebate_calc_type,
                         I_growth_rebate_ind,
                         I_historical_comp_start_date,
                         I_historical_comp_end_date,
                         I_rebate_purch_sales_ind,
                         I_deal_reporting_level,
                         I_bill_back_method,
                         I_deal_income_calculation,
                         I_invoice_processing_logic,
                         I_stock_ledger_ind,
                         I_include_vat_ind,
                         I_billing_partner_type,
                         I_billing_partner_id,
                         nvl(I_billing_supplier_id, L_supplier),
                         I_growth_rate_to_date,
                         I_turnover_to_date,
                         I_actual_monies_earned_to_date,
                         I_security_ind,
                         I_est_next_invoice_date,
                         I_last_invoice_date);

   O_deal_id := L_deal_id;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.INSERT_PO_DEAL',
                                            to_char(SQLCODE));
   return FALSE;
END INSERT_PO_DEAL;
-------------------------------------------------------------------------------------------------
FUNCTION APPLY_ITEM_LOC_LIST(O_error_message     IN OUT VARCHAR2,
                             O_conflict_exists   IN OUT BOOLEAN,
                             O_item_sup_ind      IN OUT VARCHAR2,
                             I_loc_list          IN     LOC_LIST_DETAIL.LOC_LIST%TYPE,
                             I_item_list         IN     SKULIST_HEAD.SKULIST%TYPE,
                             I_deal_id           IN     DEAL_HEAD.DEAL_ID%TYPE,
                             I_deal_detail_id    IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                             I_partner_type      IN     DEAL_HEAD.PARTNER_TYPE%TYPE,
                             I_partner_id        IN     DEAL_HEAD.PARTNER_ID%TYPE,
                             I_supplier          IN     DEAL_HEAD.SUPPLIER%TYPE,
                             I_origin_country_id IN     DEAL_ITEMLOC.ORIGIN_COUNTRY_ID%TYPE,
                             I_excl_ind          IN     DEAL_ITEMLOC.EXCL_IND%TYPE)
RETURN BOOLEAN IS
   L_conflict_exists     BOOLEAN := FALSE;

   cursor C_GET_LOCS is
      select distinct w.physical_wh location,
             l.loc_type loc_type
        from loc_list_detail l,
             wh w
       where l.location = w.wh
         and l.loc_type = 'W'
         and l.loc_list = I_loc_list
   union all
      select location, loc_type
        from loc_list_detail
       where loc_type = 'S'
         and loc_list = I_loc_list
      order by 2,1;


BEGIN
   for REC IN C_GET_LOCS LOOP
      ---
      if C_GET_LOCS%NOTFOUND then
         Exit;
      end if;
      ---
      if not APPLY_ITEM_LIST(O_error_message,
                             L_conflict_exists,
                             O_item_sup_ind,
                             I_item_list,
                             I_deal_id,
                             I_deal_detail_id,
                             I_partner_type,
                             I_partner_id,
                             I_supplier,
                             I_origin_country_id,
                             5,
                             rec.loc_type,
                             rec.location,
                             I_excl_ind) then
         return FALSE;
      end if;
      ---
      if L_conflict_exists = TRUE then
         O_conflict_exists := TRUE;
      end if;
      ---
   END LOOP;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.APPLY_ITEM_LOC_LIST',
                                            to_char(SQLCODE));
   return FALSE;
END APPLY_ITEM_LOC_LIST;
--------------------------------------------------------------------------------------------
FUNCTION APPLY_LOC_LIST(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_conflict_exists   IN OUT BOOLEAN,
                        I_loc_list          IN     LOC_LIST_DETAIL.LOC_LIST%TYPE,
                        I_deal_id           IN     DEAL_HEAD.DEAL_ID%TYPE,
                        I_deal_detail_id    IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                        I_merch_level       IN     DEAL_ITEMLOC.MERCH_LEVEL%TYPE,
                        I_merch_value       IN     VARCHAR2,
                        I_merch_value_2     IN     VARCHAR2,
                        I_merch_value_3     IN     VARCHAR2,
                        I_origin_country_id IN     DEAL_ITEMLOC.ORIGIN_COUNTRY_ID%TYPE,
                        I_excl_ind          IN     DEAL_ITEMLOC.EXCL_IND%TYPE)
RETURN BOOLEAN IS

   L_table               VARCHAR2(30) := 'DEAL_ITEMLOC';
   L_seq_no              DEAL_ITEMLOC.SEQ_NO%TYPE;
   L_item                DEAL_ITEMLOC.ITEM%TYPE;
   L_division            DEAL_ITEMLOC.DIVISION%TYPE;
   L_division_name       DIVISION.DIV_NAME%TYPE;
   L_group_no            DEAL_ITEMLOC.GROUP_NO%TYPE;
   L_group_name          GROUPS.GROUP_NAME%TYPE;
   L_dept                DEAL_ITEMLOC.DEPT%TYPE;
   L_dept_name           DEPS.DEPT_NAME%TYPE;
   L_class               DEAL_ITEMLOC.CLASS%TYPE;
   L_class_name          CLASS.CLASS_NAME%TYPE;
   L_subclass            DEAL_ITEMLOC.SUBCLASS%TYPE;
   L_subclass_name       SUBCLASS.SUB_NAME%TYPE;
   L_item_grandparent    DEAL_ITEMLOC.ITEM_GRANDPARENT%TYPE;
   L_item_gp_desc        ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_parent         DEAL_ITEMLOC.ITEM_PARENT%TYPE;
   L_item_p_desc         ITEM_MASTER.ITEM_DESC%TYPE;
   L_diff_1              DEAL_ITEMLOC.DIFF_1%TYPE;
   L_diff_1_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_2              DEAL_ITEMLOC.DIFF_2%TYPE;
   L_diff_2_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_3              DEAL_ITEMLOC.DIFF_3%TYPE;
   L_diff_3_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_4              DEAL_ITEMLOC.DIFF_4%TYPE;
   L_diff_4_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_chain               DEAL_ITEMLOC.CHAIN%TYPE;
   L_chain_name          CHAIN.CHAIN_NAME%TYPE;
   L_area                DEAL_ITEMLOC.AREA%TYPE;
   L_area_name           AREA.AREA_NAME%TYPE;
   L_region              DEAL_ITEMLOC.REGION%TYPE;
   L_region_name         REGION.REGION_NAME%TYPE;
   L_district            DEAL_ITEMLOC.DISTRICT%TYPE;
   L_district_name       DISTRICT.DISTRICT_NAME%TYPE;
   L_valid               BOOLEAN;
   L_company_ind         DEAL_ITEMLOC.COMPANY_IND%TYPE;
   L_item_level          ITEM_MASTER.ITEM_LEVEL%TYPE;
   L_tran_level          ITEM_MASTER.TRAN_LEVEL%TYPE;

   cursor C_GET_LOCS is
      select distinct w.physical_wh location,
             l.loc_type loc_type
        from loc_list_detail l,
             wh w
       where l.location = w.wh
         and l.loc_type = 'W'
         and l.loc_list = I_loc_list
   union all
      select location, loc_type
        from loc_list_detail
       where loc_type = 'S'
         and loc_list = I_loc_list
      order by 2,1;

BEGIN
   if I_loc_list is NULL or I_deal_id is NULL or I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_SQL.APPLY_ITEM_LIST',NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_merch_level <> 1 then
      if not DEAL_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                            L_division,
                                            L_division_name,
                                            L_group_no,
                                            L_group_name,
                                            L_dept,
                                            L_dept_name,
                                            L_class,
                                            L_class_name,
                                            L_subclass,
                                            L_subclass_name,
                                            L_item_grandparent,
                                            L_item_gp_desc,
                                            L_item_parent,
                                            L_item_p_desc,
                                            L_diff_1,
                                            L_diff_1_desc,
                                            L_diff_2,
                                            L_diff_2_desc,
                                            L_diff_3,
                                            L_diff_3_desc,
                                            L_diff_4,
                                            L_diff_4_desc,
                                            I_merch_level,
                                            I_merch_value,
                                            FALSE) then
         return FALSE;
      end if;
      L_company_ind := 'N';
   else
      L_company_ind := 'Y';
   end if;
   ---
   if I_merch_level = 2 then
      L_division :=  to_number(I_merch_value);
   elsif I_merch_level = 3 then
      L_group_no := to_number(I_merch_value);
   elsif I_merch_level in (4, 5, 6) then
      L_dept     := to_number(I_merch_value);
      L_class    := to_number(I_merch_value_2);
      L_subclass := to_number(I_merch_value_3);
   elsif I_merch_level = 12 then
      L_item := I_merch_value;
   end if;
   ---
   FOR rec IN C_GET_LOCS LOOP
      ---
      if not DEAL_ATTRIB_SQL.GET_NEXT_DEALITLC_SEQ (O_error_message,
                                                    L_seq_no,
                                                    I_deal_id,
                                                    I_deal_detail_id) then
         return FALSE;
      end if;
      ---
      if rec.loc_type != 'W' then
         if not DEAL_ATTRIB_SQL.GET_ORG_HIER(O_error_message,
                                             L_chain,
                                             L_chain_name,
                                             L_area,
                                             L_area_name,
                                             L_region,
                                             L_region_name,
                                             L_district,
                                             L_district_name,
                                             5,
                                             rec.location,
                                             FALSE) then
            return FALSE;
         end if;
      else
         L_chain    := NULL;
         L_area     := NULL;
         L_region   := NULL;
         L_district := NULL;
      end if;
      ---
      if not DEAL_VALIDATE_SQL.VALIDATE_ITEMLOC(O_error_message,
                                                L_valid,
                                                I_deal_id,
                                                I_deal_detail_id,
                                                I_merch_level,
                                                5,
                                                I_origin_country_id,
                                                L_company_ind,
                                                L_division,
                                                L_group_no,
                                                L_dept,
                                                L_class,
                                                L_subclass,
                                                L_item_grandparent,
                                                L_item_parent,
                                                L_diff_1,
                                                L_diff_2,
                                                L_diff_3,
                                                L_diff_4,
                                                L_item,
                                                L_chain,
                                                L_area,
                                                L_region,
                                                L_district,
                                                rec.loc_type,
                                                rec.location,
                                                I_excl_ind) then
         return FALSE;
      end if;
      ---
      if L_valid = FALSE then
         O_conflict_exists := TRUE;
      else
         SQL_LIB.SET_MARK('INSERT',NULL,'DEAL_ITEMLOC','DEAL ID: '||to_char(I_deal_id));
         insert into deal_itemloc(deal_id,
                                  deal_detail_id,
                                  seq_no,
                                  merch_level,
                                  company_ind,
                                  division,
                                  group_no,
                                  dept,
                                  class,
                                  subclass,
                                  item_grandparent,
                                  item_parent,
                                  diff_1,
                                  diff_2,
                                  diff_3,
                                  diff_4,
                                  org_level,
                                  chain,
                                  area,
                                  region,
                                  district,
                                  location,
                                  origin_country_id,
                                  loc_type,
                                  item,
                                  excl_ind,
                                  create_datetime,
                                  last_update_id,
                                  last_update_datetime)
                           values(I_deal_id,
                                  I_deal_detail_id,
                                  L_seq_no,
                                  I_merch_level,
                                  L_company_ind,
                                  L_division,
                                  L_group_no,
                                  L_dept,
                                  L_class,
                                  L_subclass,
                                  L_item_grandparent,
                                  L_item_parent,
                                  L_diff_1,
                                  L_diff_2,
                                  L_diff_3,
                                  L_diff_4,
                                  5,
                                  L_chain,
                                  L_area,
                                  L_region,
                                  L_district,
                                  rec.location,
                                  I_origin_country_id,
                                  rec.loc_type,
                                  L_item,
                                  I_excl_ind,
                                  sysdate,
                                  user,
                                  sysdate);
      end if;
   END LOOP;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.APPLY_LOC_LIST',
                                            to_char(SQLCODE));
   return FALSE;
END APPLY_LOC_LIST;
--------------------------------------------------------------------------------------------
FUNCTION INSERT_QTY_THRESH_ITEMS(O_error_message    IN OUT VARCHAR2,
                                 I_deal_id          IN     DEAL_HEAD.DEAL_ID%TYPE,
                                 I_deal_detail_id   IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                                 I_buy_item         IN     DEAL_DETAIL.QTY_THRESH_BUY_ITEM%TYPE,
                                 I_get_item         IN     DEAL_DETAIL.QTY_THRESH_GET_ITEM%TYPE,
                                 I_org_level        IN     DEAL_ITEMLOC.ORG_LEVEL%TYPE,
                                 I_chain            IN     DEAL_ITEMLOC.CHAIN%TYPE,
                                 I_area             IN     DEAL_ITEMLOC.AREA%TYPE,
                                 I_region           IN     DEAL_ITEMLOC.REGION%TYPE,
                                 I_district         IN     DEAL_ITEMLOC.DISTRICT%TYPE,
                                 I_location         IN     DEAL_ITEMLOC.LOCATION%TYPE,
                                 I_loc_type         IN     DEAL_ITEMLOC.LOC_TYPE%TYPE)
RETURN BOOLEAN IS
   L_seq_no              DEAL_ITEMLOC.SEQ_NO%TYPE;
   L_division            DEAL_ITEMLOC.DIVISION%TYPE;
   L_division_name       DIVISION.DIV_NAME%TYPE;
   L_group_no            DEAL_ITEMLOC.GROUP_NO%TYPE;
   L_group_name          GROUPS.GROUP_NAME%TYPE;
   L_dept                DEAL_ITEMLOC.DEPT%TYPE;
   L_dept_name           DEPS.DEPT_NAME%TYPE;
   L_class               DEAL_ITEMLOC.CLASS%TYPE;
   L_class_name          CLASS.CLASS_NAME%TYPE;
   L_subclass            DEAL_ITEMLOC.SUBCLASS%TYPE;
   L_subclass_name       SUBCLASS.SUB_NAME%TYPE;
   L_item_grandparent    DEAL_ITEMLOC.ITEM_GRANDPARENT%TYPE;
   L_item_gp_desc        ITEM_MASTER.ITEM_DESC%TYPE;
   L_item_parent         DEAL_ITEMLOC.ITEM_PARENT%TYPE;
   L_item_p_desc         ITEM_MASTER.ITEM_DESC%TYPE;
   L_diff_1              DEAL_ITEMLOC.DIFF_1%TYPE;
   L_diff_1_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_2              DEAL_ITEMLOC.DIFF_2%TYPE;
   L_diff_2_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_3              DEAL_ITEMLOC.DIFF_3%TYPE;
   L_diff_3_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_diff_4              DEAL_ITEMLOC.DIFF_4%TYPE;
   L_diff_4_desc         DIFF_IDS.DIFF_DESC%TYPE;
   L_chain               DEAL_ITEMLOC.CHAIN%TYPE;
   L_area                DEAL_ITEMLOC.AREA%TYPE;
   L_region              DEAL_ITEMLOC.REGION%TYPE;
   L_district            DEAL_ITEMLOC.DISTRICT%TYPE;
   L_dummy               VARCHAR2(62);

   cursor C_GET_LOCS is
      select ll.location,
             ll.loc_type
        from loc_list_detail ll
       where ll.loc_list = I_location
      and (( ll.loc_type = 'W'
             and exists (select 'x' from wh
                          where wh = ll.location
                            and physical_wh = wh))
          or loc_type = 'S');

BEGIN
   if I_get_item <> I_buy_item then
      if not DEAL_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                            L_division,
                                            L_division_name,
                                            L_group_no,
                                            L_group_name,
                                            L_dept,
                                            L_dept_name,
                                            L_class,
                                            L_class_name,
                                            L_subclass,
                                            L_subclass_name,
                                            L_item_grandparent,
                                            L_item_gp_desc,
                                            L_item_parent,
                                            L_item_p_desc,
                                            L_diff_1,
                                            L_diff_1_desc,
                                            L_diff_2,
                                            L_diff_2_desc,
                                            L_diff_3,
                                            L_diff_3_desc,
                                            L_diff_4,
                                            L_diff_4_desc,
                                            12,
                                            I_get_item,
                                            FALSE) then
         return FALSE;
      end if;
      ---
      if I_org_level != 5 or (I_org_level = 5 and I_loc_type is not NULL) then
         if not DEAL_ATTRIB_SQL.GET_NEXT_DEALITLC_SEQ(O_error_message,
                                                      L_seq_no,
                                                      I_deal_id,
                                                      I_deal_detail_id) then
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('INSERT',NULL,'DEAL_ITEMLOC','DEAL ID: '||to_char(I_deal_id));
         insert into DEAL_ITEMLOC(deal_id,
                                  deal_detail_id,
                                  seq_no,
                                  merch_level,
                                  company_ind,
                                  division,
                                  group_no,
                                  dept,
                                  class,
                                  subclass,
                                  item_grandparent,
                                  item_parent,
                                  diff_1,
                                  diff_2,
                                  diff_3,
                                  diff_4,
                                  org_level,
                                  chain,
                                  area,
                                  region,
                                  district,
                                  location,
                                  origin_country_id,
                                  loc_type,
                                  item,
                                  excl_ind,
                                  create_datetime,
                                  last_update_id,
                                  last_update_datetime)
                           values(I_deal_id,
                                  I_deal_detail_id,
                                  L_seq_no,
                                  12,
                                  'N',
                                  L_division,
                                  L_group_no,
                                  L_dept,
                                  L_class,
                                  L_subclass,
                                  L_item_grandparent,
                                  L_item_parent,
                                  L_diff_1,
                                  L_diff_2,
                                  L_diff_3,
                                  L_diff_4,
                                  I_org_level,
                                  I_chain,
                                  I_area,
                                  I_region,
                                  I_district,
                                  I_location,
                                  NULL,
                                  I_loc_type,
                                  I_get_item,
                                  'N',
                                  sysdate,
                                  user,
                                  sysdate);
      elsif I_org_level = 5 and I_loc_type is NULL then

         SQL_LIB.SET_MARK('OPEN','C_GET_LOCS','LOC_LIST_DETAIL','LOC_LIST: '||to_char(I_location));
         for recs in C_GET_LOCS LOOP
            ---
            if not DEAL_ATTRIB_SQL.GET_NEXT_DEALITLC_SEQ(O_error_message,
                                                         L_seq_no,
                                                         I_deal_id,
                                                         I_deal_detail_id) then
               return FALSE;
            end if;
            if recs.loc_type != 'W' then
               if not DEAL_ATTRIB_SQL.GET_ORG_HIER(O_error_message,
                                                   L_chain,
                                                   L_dummy,
                                                   L_area,
                                                   L_dummy,
                                                   L_region,
                                                   L_dummy,
                                                   L_district,
                                                   L_dummy,
                                                   5,
                                                   recs.location,
                                                   FALSE) then
                  return FALSE;
               end if;
            else
               L_chain    := NULL;
               L_area     := NULL;
               L_region   := NULL;
               L_district := NULL;
            end if;
            ---
            SQL_LIB.SET_MARK('INSERT',NULL,'DEAL_ITEMLOC','DEAL ID: '||to_char(I_deal_id)|| ' LOCATION: '||recs.location);
            insert into DEAL_ITEMLOC(deal_id,
                                     deal_detail_id,
                                     seq_no,
                                     merch_level,
                                     company_ind,
                                     division,
                                     group_no,
                                     dept,
                                     class,
                                     subclass,
                                     item_grandparent,
                                     item_parent,
                                     diff_1,
                                     diff_2,
                                     diff_3,
                                     diff_4,
                                     org_level,
                                     chain,
                                     area,
                                     region,
                                     district,
                                     location,
                                     origin_country_id,
                                     loc_type,
                                     item,
                                     excl_ind,
                                     create_datetime,
                                     last_update_id,
                                     last_update_datetime)
                              values(I_deal_id,
                                     I_deal_detail_id,
                                     L_seq_no,
                                     12,
                                     'N',
                                     L_division,
                                     L_group_no,
                                     L_dept,
                                     L_class,
                                     L_subclass,
                                     L_item_grandparent,
                                     L_item_parent,
                                     L_diff_1,
                                     L_diff_2,
                                     L_diff_3,
                                     L_diff_4,
                                     I_org_level,
                                     L_chain,
                                     L_area,
                                     L_region,
                                     L_district,
                                     recs.location,
                                     NULL,
                                     recs.loc_type,
                                     I_get_item,
                                     'N',
                                     sysdate,
                                     user,
                                     sysdate);
         end LOOP;
      end if;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.INSERT_QTY_THRESH_ITEMS',
                                            to_char(SQLCODE));
   return FALSE;

END INSERT_QTY_THRESH_ITEMS;
--------------------------------------------------------------------------------------------
FUNCTION APPLY_ON_RCPT_DEALS(O_error_message    IN OUT      VARCHAR2,
                             I_order_no         IN          ordloc_discount.order_no%TYPE,
                             I_item             IN          ordloc_discount.item%TYPE,
                             I_location         IN          ordloc_discount.location%TYPE)
RETURN BOOLEAN IS
   L_table                 VARCHAR2(30);
   L_max_appl_order        ordloc_discount.application_order%TYPE;
   L_pack_no               ordloc_discount.pack_no%TYPE;
   L_discount              NUMBER;
   L_unit_cost             ordloc.unit_cost%TYPE;
   L_exists                VARCHAR2(1) := NULL;

   cursor C_GET_MAX_APPL_ORDER is

      select MAX(o.application_order), MAX(o.pack_no)
        from ordloc_discount o, deal_head d, store s
       where o.order_no = I_order_no
         and ((o.item = I_item and o.pack_no is null) or o.pack_no = I_item)
         and o.location = I_location
         and o.paid_ind = 'N'
         and o.deal_id = d.deal_id
         and d.billing_type = 'OI'
         and d.deal_appl_timing = 'R'
         and o.location = s.store
   union all
      select MAX(o.application_order), MAX(o.pack_no)
        from ordloc_discount o,
             deal_head d,
             wh w
       where o.order_no = I_order_no
         and ((o.item = I_item and o.pack_no is NULL) or o.pack_no = I_item)
         and w.wh = I_location
         and o.paid_ind = 'N'
         and o.deal_id = d.deal_id
         and d.billing_type = 'OI'
         and d.deal_appl_timing = 'R'
         and o.location = w.physical_wh
       order by 1, 2;

   cursor C_GET_PACK_SKUS is
      select item, qty
        from v_packsku_qty
       where pack_no = L_pack_no;

   cursor C_LOCK_ORDLOC is
     select 'x'
       from ordloc
      where order_no = I_order_no
        and item = I_item
        and location = I_location
        for update nowait;

   cursor C_EXPENSE_EXISTS is
      select 'x'
        from ordloc_exp
       where order_no = I_order_no
         and item = I_item
         and location = I_location
         and est_exp_value > 0;

   cursor C_ASSESSMENT_EXISTS is
      select 'x'
        from ordsku_hts
       where order_no = I_order_no
         and item = I_item
         and seq_no in (select seq_no
                          from ordsku_hts_assess
                         where order_no = I_order_no
                           and est_assess_value > 0);

FUNCTION APPLY_RCPT_DEALS_SKU(O_error_message          IN OUT      VARCHAR2,
                              I_item                   IN          item_master.item%TYPE,
                              I_location               IN          ordloc_discount.location%TYPE,
                              I_order_no               IN          ordloc_discount.order_no%TYPE,
                              I_max_application_order  IN          ordloc_discount.application_order%TYPE,
                              I_pack_no                IN          ordloc_discount.pack_no%TYPE,
                              I_pack_ind               IN          VARCHAR2,
                              I_pack_qty               IN          v_packsku_qty.qty%TYPE,
                              O_discount               IN OUT      NUMBER,
                              O_unit_cost              IN OUT      ordloc.unit_cost%TYPE)



RETURN BOOLEAN is
   L_net_unit_cost             NUMBER;
   L_cumulative_discount_amt   NUMBER  := 0;
   L_discount_value            NUMBER;
   L_unit_cost_init            NUMBER;
   L_unit_cost_init_sup        NUMBER;
   L_supplier                  ORDHEAD.SUPPLIER%TYPE;
   L_table                     VARCHAR2(30);
   L_application_order         ORDLOC_DISCOUNT.APPLICATION_ORDER%TYPE;
   L_unit_cost                 ORDLOC.UNIT_COST%TYPE;
   L_loc                       ORDLOC_DISCOUNT.LOCATION%TYPE;

   cursor C_GET_DISCOUNTS is
      select o.discount_type,
             o.discount_value,
             o.paid_ind,
             o.application_order,
             h.billing_type,
             h.deal_appl_timing,
             d.deal_class,
             l.unit_cost_init,
             l.unit_cost
        from ordloc_discount o,
             deal_detail d,
             deal_head h,
             ordloc l,
             store s
       where o.item = I_item
         and o.order_no = I_order_no
         and o.location = I_location
         and o.application_order <= I_max_application_order
         and d.deal_id = o.deal_id
         and d.deal_detail_id = o.deal_detail_id
         and d.deal_id = h.deal_id
         and l.item = NVL(I_pack_no, I_item)
         and l.order_no = o.order_no
         and l.location = o.location
         and o.location = s.store
   union all
      select o.discount_type,
             o.discount_value,
             o.paid_ind,
             o.application_order,
             h.billing_type,
             h.deal_appl_timing,
             d.deal_class,
             l.unit_cost_init,
             l.unit_cost
        from ordloc_discount o,
             deal_detail d,
             deal_head h,
             ordloc l,
             wh w
       where o.item = I_item
         and o.order_no = I_order_no
         and l.location = I_location
         and o.application_order <= I_max_application_order
         and d.deal_id = h.deal_id
         and d.deal_id = o.deal_id
         and d.deal_detail_id = o.deal_detail_id
         and l.item = NVL(I_pack_no, I_item)
         and l.order_no = o.order_no
         and l.location = w.wh
         and w.physical_wh = o.location
       order by 4;

   cursor C_GET_UNIT_COST is
      select i.unit_cost,
             oh.supplier
        from item_supp_country_loc i,
             ordhead oh,
             ordloc ol,
             ordsku os
       where i.item = I_item
         and i.loc = I_location
         and oh.order_no = I_order_no
         and i.supplier = oh.supplier
         and ol.order_no = oh.order_no
         and ol.item = i.item
         and ol.location = i.loc
         and oh.order_no = os.order_no
         and ol.item = os.item
         and os.item = I_item
         and i.origin_country_id = os.origin_country_id;

   cursor C_GET_DISCOUNT_LOC is
      select o.location
        from ordloc_discount o,
             store s
       where o.item = I_item
         and o.order_no = I_order_no
         and o.location = I_location
         and s.store = o.location
         and o.application_order = L_application_order
   union all
      select o.location
        from ordloc_discount o,
             wh w
       where o.item = I_item
         and o.order_no = I_order_no
         and o.location = w.physical_wh
         and w.wh = I_location
         and o.application_order = L_application_order;

   cursor C_LOCK_ORDLOC_DISCOUNT is
     select 'x'
       from ordloc_discount
      where item = I_item
        and order_no = I_order_no
        and location = L_loc
        and application_order = L_application_order
        for update nowait;

BEGIN
   if I_pack_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY, ORDHEAD, ORDSKU','ORDER NO: '||TO_CHAR(I_order_no));
      open C_GET_UNIT_COST;
      SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY, ORDHEAD, ORDSKU','ORDER NO: '||TO_CHAR(I_order_no));
      fetch C_GET_UNIT_COST into L_unit_cost_init_sup, L_supplier;
      SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY, ORDHEAD, ORDSKU','ORDER NO: '||TO_CHAR(I_order_no));
      close C_GET_UNIT_COST;
   end if;
   if not CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                           L_supplier,
                                           'V',
                                           NULL,
                                           I_order_no,
                                           'O',
                                           NULL,
                                           L_unit_cost_init_sup,
                                           L_unit_cost_init,
                                           'C',
                                           NULL,
                                           NULL) then
      return FALSE;
   end if;
   ---
   for REC in C_GET_DISCOUNTS LOOP
      if C_GET_DISCOUNTS%NOTFOUND then
         EXIT;
      end if;
      ---
      O_unit_cost := rec.unit_cost;

      if I_pack_ind <> 'Y' then
         L_unit_cost_init := rec.unit_cost_init;
      end if;
      ---
      if L_net_unit_cost is NULL then
         L_net_unit_cost := L_unit_cost_init;
      end if;
      ---
      if rec.discount_type = 'F' then
         L_net_unit_cost := L_net_unit_cost - (L_unit_cost_init - rec.discount_value);
         if rec.billing_type = 'OI' and rec.deal_appl_timing = 'R' and rec.paid_ind = 'N' then
            L_cumulative_discount_amt := L_cumulative_discount_amt + (L_unit_cost_init - rec.discount_value);
         end if;
      elsif rec.discount_type = 'A' or rec.discount_type = 'Q' then
         L_net_unit_cost := L_net_unit_cost - rec.discount_value;
         if rec.billing_type = 'OI' and rec.deal_appl_timing = 'R' and rec.paid_ind = 'N' then
            L_cumulative_discount_amt := L_cumulative_discount_amt + rec.discount_value;
         end if;
      elsif rec.discount_type = 'P' then
         if rec.deal_class in ('CU', 'EX') then
            L_discount_value := rec.discount_value/100 * L_unit_cost_init;
         elsif rec.deal_class = 'CS' then
            L_discount_value := rec.discount_value/100 * L_net_unit_cost;
         end if;
         L_net_unit_cost := L_net_unit_cost - L_discount_value;
         if rec.billing_type = 'OI' and rec.deal_appl_timing = 'R' and rec.paid_ind = 'N' then
            L_cumulative_discount_amt := L_cumulative_discount_amt + L_discount_value;
         end if;
      end if;
      ---
      if rec.billing_type = 'OI' and rec.deal_appl_timing = 'R' and rec.paid_ind = 'N' then
         L_table := 'ORDLOC_DISCOUNT';
         L_application_order := rec.application_order;

         SQL_LIB.SET_MARK('OPEN','C_GET_DISCOUNT_LOC','ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
         open C_GET_DISCOUNT_LOC;
         SQL_LIB.SET_MARK('FETCH','C_GET_DISCOUNT_LOC','ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
         fetch C_GET_DISCOUNT_LOC into L_loc;
         SQL_LIB.SET_MARK('CLOSE',' C_GET_DISCOUNT_LOC ','ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
         close C_GET_DISCOUNT_LOC;

         SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDSKU','ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
         open C_LOCK_ORDLOC_DISCOUNT;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDSKU','ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
         close C_LOCK_ORDLOC_DISCOUNT;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
         update ORDLOC_DISCOUNT
            set paid_ind = 'Y'
          where item = I_item
            and order_no = I_order_no
            and application_order = rec.application_order
            and location = L_loc;
      end if;
      ---
   end LOOP;
   ---
   if I_pack_ind = 'Y' then
      L_cumulative_discount_amt := L_cumulative_discount_amt * I_pack_qty;
   end if;
   ---
   O_discount := L_cumulative_discount_amt;
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            TO_CHAR(I_order_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.APPLY_ON_RCPT_DEALS',
                                            TO_CHAR(SQLCODE));
   return FALSE;

END APPLY_RCPT_DEALS_SKU;

BEGIN
   if I_order_no is null or I_item is null then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_SQL.APPLY_ON_RCPT_DEALS',null,null);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_MAX_APPL_ORDER','ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
   open C_GET_MAX_APPL_ORDER;
   SQL_LIB.SET_MARK('FETCH','C_GET_MAX_APPL_ORDER','ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
   fetch C_GET_MAX_APPL_ORDER into L_max_appl_order, L_pack_no;
   SQL_LIB.SET_MARK('CLOSE','C_GET_MAX_APPL_ORDER','ORDLOC_DISCOUNT','ORDER NO: '||TO_CHAR(I_order_no));
   close C_GET_MAX_APPL_ORDER;
   ---
   if L_pack_no is NULL then
      if not APPLY_RCPT_DEALS_SKU(O_error_message,
                                  I_item,
                                  I_location,
                                  I_order_no,
                                  L_max_appl_order,
                                  NULL,
                                  'N',
                                  NULL,
                                  L_discount,
                                  L_unit_cost) then
         return FALSE;
      end if;
   else
      for REC in C_GET_PACK_SKUS LOOP
         if C_GET_PACK_SKUS%notfound then
            EXIT;
         end if;
         if not APPLY_RCPT_DEALS_SKU(O_error_message,
                                     rec.item,
                                     I_location,
                                     I_order_no,
                                     L_max_appl_order,
                                     I_item,
                                     'Y',
                                     rec.qty,
                                     L_discount,
                                     L_unit_cost) then
            return FALSE;
         end if;
      END LOOP;
   end if;
   ---
   if L_discount > L_unit_cost then
      O_error_message := SQL_LIB.CREATE_MSG('UNIT_COST_NOT_NEG', NULL, NULL, NULL);
      return FALSE;
   end if;
   ---
   if L_discount > 0 then
      L_table := 'ORDLOC';
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDLOC','ORDLOC','ORDER NO: '||TO_CHAR(I_order_no));
      open C_LOCK_ORDLOC;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDLOC','ORDLOC','ORDER NO: '||TO_CHAR(I_order_no));
      close C_LOCK_ORDLOC;
      ---
      SQL_LIB.SET_MARK('UPDATE',NULL,'ORDLOC','ORDER NO: '||TO_CHAR(I_order_no));
      ----
      update ordloc
         set unit_cost = unit_cost - L_discount,
             cost_source = 'DEAL'
        where order_no = I_order_no
          and item = I_item
          and location = I_location;
       ---
       --recalculate expenses for items if expenses exist
        SQL_LIB.SET_MARK('OPEN','C_EXPENSE_EXISTS','ORDSKU_EXP','ORDER NO: '||TO_CHAR(I_order_no));
        open C_EXPENSE_EXISTS;
        ---
        SQL_LIB.SET_MARK('FETCH','C_EXPENSE_EXISTS','ORDSKU_EXP','ORDER NO: '||TO_CHAR(I_order_no));
        fetch C_EXPENSE_EXISTS into L_exists;
        ---
        if C_EXPENSE_EXISTS%found then
           ---
           if ELC_CALC_SQL.CALC_COMP(O_error_message,
                                     'PE',
                                     I_item,
                                     NULL,
                                     NULL,
                                     NULL,
                                     I_order_no,
                                     NULL,
                                     NULL,
                                     NULL,
                                     I_location,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL) = FALSE then
              SQL_LIB.SET_MARK('CLOSE','C_EXPENSE_EXISTS','ORDSKU_EXP','ORDER NO: '||TO_CHAR(I_order_no));
              close C_EXPENSE_EXISTS;
              ---
              return FALSE;
           end if;
           ---
        end if;
        ---
        ---
        SQL_LIB.SET_MARK('CLOSE','C_EXPENSE_EXISTS','ORDSKU_EXP','ORDER NO: '||TO_CHAR(I_order_no));
        close C_EXPENSE_EXISTS;
        ---
        --recalculate assessments for order if assessments exist
        SQL_LIB.SET_MARK('OPEN','C_ASSESSMENT_EXISTS','ORDSKU_HTS_ASSESS','ORDER NO: '||TO_CHAR(I_order_no));
        open C_ASSESSMENT_EXISTS;
        ---
        SQL_LIB.SET_MARK('FETCH','C_ASSESSMENT_EXISTS','ORDSKU_HTS_ASSESS','ORDER NO: '||TO_CHAR(I_order_no));
        fetch C_ASSESSMENT_EXISTS into L_exists;
        ---
        if C_ASSESSMENT_EXISTS%found then
           if ELC_CALC_SQL.CALC_COMP(O_error_message,
                                     'PA',
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     I_order_no,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL) = FALSE then
              SQL_LIB.SET_MARK('CLOSE','C_ASSESSMENT_EXISTS','ORDSKU_HTS_ASSESSMENT','ORDER NO: '||TO_CHAR(I_order_no));
              close C_ASSESSMENT_EXISTS;
              ---
              return FALSE;
           end if;
           ---
           --recalculate expenses for order based on the new assessment values
           if ELC_CALC_SQL.CALC_COMP(O_error_message,
                                     'PE',
                                     I_item,
                                     NULL,
                                     NULL,
                                     NULL,
                                     I_order_no,
                                     NULL,
                                     NULL,
                                     NULL,
                                     I_location,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL) = FALSE then
              return FALSE;
           end if;
           ---
        end if;
        ---
        SQL_LIB.SET_MARK('CLOSE','C_ASSESSMENT_EXISTS','ORDSKU_HTS_ASSESS','ORDER NO: '||TO_CHAR(I_order_no));
        close C_ASSESSMENT_EXISTS;
        ---
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            TO_CHAR(I_order_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.APPLY_ON_RCPT_DEALS',
                                            TO_CHAR(SQLCODE));
      return FALSE;
END APPLY_ON_RCPT_DEALS;
--------------------------------------------------------------------------------------------
FUNCTION DELETE_DEALS(O_error_message    IN OUT      VARCHAR2,
                      I_deal_id          IN          deal_head.deal_id%TYPE)

RETURN BOOLEAN is

   L_table            VARCHAR2(30);
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DEAL_COMP_PROM is
      select 'x'
        from deal_comp_prom
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_QUEUE is
      select 'x'
        from deal_queue
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_ORDLOC_DISCOUNT is
      select 'x'
        from ORDLOC_DISCOUNT
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_POP_TERMS_FULFILLMENT is
      select 'x'
        from pop_terms_fulfillment
       where pop_def_seq_no in
             (select pop_def_seq_no
                from pop_terms_def
               where deal_id = I_deal_id)
         for update nowait;

   cursor C_LOCK_POP_TERMS_DEF is
      select 'x'
        from pop_terms_def
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_THRESHOLD is
      select 'x'
        from deal_threshold
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
        from deal_itemloc
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_THRESHOLD_REV is
      select 'x'
        from deal_threshold_rev
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_ITEM_LOC_EXPLODE is
      select 'x'
        from deal_item_loc_explode
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_ACTUALS_ITEM_LOC is
      select 'x'
        from deal_actuals_item_loc
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_ACTUALS_FORECAST is
      select 'x'
        from deal_actuals_forecast
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_DETAIL is
      select 'x'
        from deal_detail
       where deal_id = I_deal_id
         for update nowait;

   cursor C_LOCK_DEAL_HEAD is
      select 'x'
        from deal_head
       where deal_id = I_deal_id
         for update nowait;

BEGIN
   --lock table deal_comp_prom and remove deal

   ---
   L_table := 'deal_comp_prom';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_COMP_PROM',
                    'DEAL_COMP_PROM',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_COMP_PROM;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_COMP_PROM',
                    'DEAL_COMP_PROM',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_COMP_PROM;
   ---
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'DEAL_COMP_PROM',
                    'DEAL ID '||TO_CHAR(I_deal_id));
   delete from deal_comp_prom
    where deal_comp_prom.deal_id = I_deal_id;
   ---

   --lock table deal_queue and remove deal

   ---
   L_table := 'deal_queue';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_QUEUE',
                    'DEAL_QUEUE',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_QUEUE;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_QUEUE',
                    'DEAL_QUEUE',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_QUEUE;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_QUEUE', 'DEAL ID '||TO_CHAR(I_deal_id));
   delete from deal_queue
    where deal_queue.deal_id = I_deal_id;
   ---

   --lock table ORDLOC_DISCOUNT and remove deal

   ---
   L_table := 'ORDLOC_DISCOUNT';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ORDLOC_DISCOUNT',
                    'ORDLOC_DISCOUNT',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_ORDLOC_DISCOUNT;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ORDLOC_DISCOUNT',
                    'ORDLOC_DISCOUNT',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_ORDLOC_DISCOUNT;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'ORDLOC_DISCOUNT', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from ORDLOC_DISCOUNT
    where ORDLOC_DISCOUNT.deal_id = I_deal_id;
   ---

   --lock table pop_terms_fulfillment and remove deal
   ---
   L_table := 'pop_terms_fulfillment';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_POP_TERMS_FULFILLMENT',
                    'POP_TERMS_FULFILLMENT',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_POP_TERMS_FULFILLMENT;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_POP_TERMS_FULFILLMENT',
                    'POP_TERMS_FULFILLMENT',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_POP_TERMS_FULFILLMENT;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'POP_TERMS_FULFILLMENT', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from pop_terms_fulfillment
    where pop_def_seq_no in
        (select pop_def_seq_no
           from pop_terms_def
          where deal_id = I_deal_id);
   ---
   --lock table pop_terms_def and remove deal
   ---
   L_table := 'pop_terms_def';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_POP_TERMS_DEF',
                    'POP_TERMS_DEF',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_POP_TERMS_DEF;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_POP_TERMS_DEF',
                    'POP_TERMS_DEF',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_POP_TERMS_DEF;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'POP_TERMS_DEF', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from pop_terms_def
    where deal_id = I_deal_id;
   ---
   --lock table deal_threshold and remove deal

   L_table := 'deal_threshold';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_THRESHOLD',
                    'DEAL_THRESHOLD',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_THRESHOLD;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_THRESHOLD',
                    'DEAL_THRESHOLD',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_THRESHOLD;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_THRESHOLD', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_threshold
    where deal_threshold.deal_id = I_deal_id;
   ---

   --lock table deal_itemloc and remove deal

   L_table := 'deal_itemloc';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_ITEMLOC',
                    'DEAL_ITEMLOC',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_ITEMLOC;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_ITEMLOC',
                    'DEAL_ITEMLOC',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_ITEMLOC;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_ITEMLOC', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_itemloc
    where deal_itemloc.deal_id = I_deal_id;
   ---
   ---
   --lock table deal_threshold_rev and remove deal

   L_table := 'deal_threshold_rev';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_THRESHOLD_REV',
                    'DEAL_THRESHOLD_REV',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_THRESHOLD_REV;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_THRESHOLD_REV',
                    'DEAL_THRESHOLD_REV',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_THRESHOLD_REV;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_THRESHOLD_REV', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_threshold_rev
    where deal_id = I_deal_id;
   ---
   --lock table deal_item_loc_explode and remove deal

   L_table := 'deal_item_loc_explode';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_ITEM_LOC_EXPLODE',
                    'DEAL_ITEM_LOC_EXPLODE',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_ITEM_LOC_EXPLODE;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_ITEM_LOC_EXPLODE',
                    'DEAL_ITEM_LOC_EXPLODE',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_ITEM_LOC_EXPLODE;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_ITEM_LOC_EXPLODE', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_item_loc_explode
    where deal_id = I_deal_id;
   ---
   --lock table deal_actuals_item_loc and remove deal

   L_table := 'deal_actuals_item_loc';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_ACTUALS_ITEM_LOC',
                    'DEAL_ACTUALS_ITEM_LOC',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_ACTUALS_ITEM_LOC;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_ACTUALS_ITEM_LOC',
                    'DEAL_ACTUALS_ITEM_LOC',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_ACTUALS_ITEM_LOC;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_ACTUALS_ITEM_LOC', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_actuals_item_loc
    where deal_id = I_deal_id;
   ---
   --lock table deal_actuals_forecast and remove deal

   L_table := 'deal_actuals_forecast';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_ACTUALS_FORECAST',
                    'DEAL_ACTUALS_FORECAST',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_ACTUALS_FORECAST;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_ACTUALS_FORECAST',
                    'DEAL_ACTUALS_FORECAST',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_ACTUALS_FORECAST;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_ACTUALS_FORECAST', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_actuals_forecast
    where deal_id = I_deal_id;
   ---
   ---
   --lock table deal_detail and remove deal

   L_table := 'deal_detail';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_DETAIL',
                    'DEAL_DETAIL',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_DETAIL;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_DETAIL',
                    'DEAL_DETAIL',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_DETAIL;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_DETAIL', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_detail
    where deal_detail.deal_id = I_deal_id;
   ---

   --lock table deal_head and remove deal

   L_table := 'deal_head';
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_HEAD',
                    'DEAL_HEAD',
                    'DEAL ID: '||to_char(I_deal_id));

   open C_LOCK_DEAL_HEAD;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_HEAD',
                    'DEAL_HEAD',
                    'DEAL ID: '||to_char(I_deal_id));

   close C_LOCK_DEAL_HEAD;
   ---
   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_HEAD', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_head
    where deal_head.deal_id = I_deal_id;

   return TRUE;


EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            NULL,
                                                  NULL);
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.DELETE_DEALS',
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_DEALS;
--------------------------------------------------------------------------------------------
FUNCTION CHECK_IS_BUY_ITEM (O_error_message    IN OUT      VARCHAR2,
                            O_item_is_buy_item IN OUT      BOOLEAN,
                            O_qty_locs_on_deal IN OUT      ORDLOC.QTY_ORDERED%TYPE,
                            O_deal_id          IN OUT      DEAL_HEAD.DEAL_ID%TYPE,
                            O_buy_qty          IN OUT      DEAL_DETAIL.QTY_THRESH_BUY_QTY%TYPE,
                            O_get_type         IN OUT      DEAL_DETAIL.QTY_THRESH_GET_TYPE%TYPE,
                            O_get_value        IN OUT      DEAL_DETAIL.QTY_THRESH_GET_VALUE%TYPE,
                            O_get_qty          IN OUT      DEAL_DETAIL.QTY_THRESH_GET_QTY%TYPE,
                            O_get_item         IN OUT      DEAL_DETAIL.QTY_THRESH_GET_ITEM%TYPE,
                            I_item             IN          ITEM_MASTER.ITEM%TYPE,
                            I_loc              IN          STORE.STORE%TYPE,
                            I_loc_type         IN          ORDLOC.LOC_TYPE%TYPE,
                            I_order_no         IN          ORDHEAD.ORDER_NO%TYPE)
RETURN BOOLEAN is
  L_deal_id        DEAL_HEAD.DEAL_ID%TYPE := NULL;
  L_buy_qty        DEAL_DETAIL.QTY_THRESH_BUY_QTY%TYPE := NULL;
  L_get_type       DEAL_DETAIL.QTY_THRESH_GET_TYPE%TYPE := NULL;
  L_get_value      DEAL_DETAIL.QTY_THRESH_GET_VALUE%TYPE := NULL;
  L_get_qty        DEAL_DETAIL.QTY_THRESH_GET_QTY%TYPE := NULL;
  L_get_item       DEAL_DETAIL.QTY_THRESH_GET_ITEM%TYPE := NULL;
  L_org_level      DEAL_ITEMLOC.ORG_LEVEL%TYPE := NULL;
  ---
  L_dil_chain      DEAL_ITEMLOC.CHAIN%TYPE := NULL;
  L_dil_area       DEAL_ITEMLOC.AREA%TYPE := NULL;
  L_dil_region     DEAL_ITEMLOC.REGION%TYPE := NULL;
  L_dil_district   DEAL_ITEMLOC.DISTRICT%TYPE := NULL;
  L_dil_location   DEAL_ITEMLOC.LOCATION%TYPE := NULL;
  L_dil_loc_type   DEAL_ITEMLOC.LOC_TYPE%TYPE := NULL;
  ---
  L_sh_chain       STORE_HIERARCHY.CHAIN%TYPE := NULL;
  L_sh_area        STORE_HIERARCHY.AREA%TYPE := NULL;
  L_sh_region      STORE_HIERARCHY.REGION%TYPE := NULL;
  L_sh_district    STORE_HIERARCHY.DISTRICT%TYPE := NULL;
  ---
  L_temp           VARCHAR2(1);
  ---

  cursor C_CHECK_BUY_ITEM is
     select dh.deal_id,
            dd.qty_thresh_buy_qty,
            dd.qty_thresh_get_type,
            dd.qty_thresh_get_value,
            dd.qty_thresh_get_qty,
            dd.qty_thresh_get_item,
            dil.org_level,
            dil.chain,
            dil.area,
            dil.region,
            dil.district,
            dil.location,
            dil.loc_type
       from deal_detail dd,
            deal_head dh,
            deal_itemloc dil,
            ordhead o
      where o.order_no = I_order_no
        and o.supplier = dh.supplier
        and o.not_before_date >= dh.active_date
        and o.not_after_date <= dh.close_date
        and dh.status = 'A'
        and dh.deal_id = dd.deal_id
        and dd.threshold_value_type = 'Q'  --meaning the deal comp is buy/get
        and dd.qty_thresh_buy_item = I_item;


   cursor C_GET_LOC_HIERARCHY is
      select chain,
             area,
             region,
             district
        from store_hierarchy
       where store = I_loc;

   cursor C_LOC_IN_LIST is
      select 'x'
        from loc_list_detail
       where loc_list = L_dil_location
         and location = I_loc;

   cursor C_ORDLOC_SUM_LOC is
      select sum(qty_ordered)
        from ordloc
       where location = L_dil_location;

   cursor C_ORDLOC_SUM_LOC_list is
      select sum(qty_ordered)
        from ordloc o
       where o.location in
             (select location
                from loc_list_detail
               where loc_list = L_dil_location);

   cursor C_ORDLOC_SUM_CHAIN is
      select sum(qty_ordered)
        from ordloc o
       where o.location in
             (select store
                from STORE_HIERARCHY
               where chain = L_dil_chain);

   cursor C_ORDLOC_SUM_AREA is
      select sum(qty_ordered)
        from ordloc
       where location in
             (select store
                from STORE_HIERARCHY
               where area = L_dil_area);

   cursor C_ORDLOC_SUM_REGION is
      select sum(qty_ordered)
        from ordloc
       where location in
             (select store
                from STORE_HIERARCHY
               where area = L_dil_region);

   cursor C_ORDLOC_SUM_DISTRICT is
      select sum(qty_ordered)
        from ordloc
       where location in
             (select store
                from STORE_HIERARCHY
               where area = L_dil_district);

BEGIN
   ---
   if I_order_no is NULL or I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT','DEAL_SQL.CHECK_IS_BUY_ITEM' ,NULL,NULL);
      return FALSE;
   end if;
   ---
   O_item_is_buy_item := FALSE;
   ---
   open C_CHECK_BUY_ITEM;
   ---
   fetch C_CHECK_BUY_ITEM into L_deal_id,
                               L_buy_qty,
                               L_get_type,
                               L_get_value,
                               L_get_qty,
                               L_get_item,
                               L_org_level,
                               L_dil_chain,
                               L_dil_area,
                               L_dil_region,
                               L_dil_district,
                               L_dil_location,
                               L_dil_loc_type;
   ---
   close C_CHECK_BUY_ITEM;
   ---
   --loc on deal_itemloc is a store/warehouse and can be compared directly with
   --the location passed into the function
   ---
   if L_org_level = 5 and L_dil_loc_type in ('S', 'W') then
      ---
      if I_loc = L_dil_location then
         O_item_is_buy_item := TRUE;
         O_deal_id := L_deal_id;
         O_buy_qty := L_buy_qty;
         O_get_type := L_get_type;
         O_get_value := L_get_value;
         O_get_qty := L_get_qty;
         O_get_item := L_get_item;
      end if;
      ---
      open C_ORDLOC_SUM_LOC;
      fetch C_ORDLOC_SUM_LOC into O_qty_locs_on_deal;
      close C_ORDLOC_SUM_LOC;
      ---
   ---
   --loc on deal_itemloc is loc type is not store/warehouse, it is a location list
   --and need to check if the location passed in is part of the location list on deal_itemloc
   ---
   elsif L_org_level = 5 and L_dil_loc_type not in ('S', 'W') then
      ---
      open C_LOC_IN_LIST;
      fetch C_LOC_IN_LIST into L_temp;
      close C_LOC_IN_LIST;
      ---
      if L_temp = 'x' then
         O_item_is_buy_item := TRUE;
         O_deal_id := L_deal_id;
         O_buy_qty := L_buy_qty;
         O_get_type := L_get_type;
         O_get_value := L_get_value;
         O_get_qty := L_get_qty;
         O_get_item := L_get_item;
      end if;
      ---
      open C_ORDLOC_SUM_LOC_LIST;
      fetch C_ORDLOC_SUM_LOC_LIST into O_qty_locs_on_deal;
      close C_ORDLOC_SUM_LOC_LIST;
      ---
      ---
   elsif L_org_level in (1, 2, 3, 4) then
      open C_GET_LOC_HIERARCHY;
      fetch C_GET_LOC_HIERARCHY into L_sh_chain,
                                     L_sh_area,
                                     L_sh_region,
                                     L_sh_district;
      close C_GET_LOC_HIERARCHY;
      ---
      if L_org_level = 1 then
         ---
         if L_dil_chain = L_sh_chain then
            O_item_is_buy_item := TRUE;
            O_deal_id := L_deal_id;
            O_buy_qty := L_buy_qty;
            O_get_type := L_get_type;
            O_get_value := L_get_value;
            O_get_qty := L_get_qty;
            O_get_item := L_get_item;
         end if;
         ---
         open C_ORDLOC_SUM_CHAIN;
         fetch C_ORDLOC_SUM_CHAIN into O_qty_locs_on_deal;
         close C_ORDLOC_SUM_CHAIN;
         ---
      elsif L_org_level = 2 then
         ---
         if L_dil_area = L_sh_area then
            O_item_is_buy_item := TRUE;
            O_deal_id := L_deal_id;
            O_buy_qty := L_buy_qty;
            O_get_type := L_get_type;
            O_get_value := L_get_value;
            O_get_qty := L_get_qty;
            O_get_item := L_get_item;
         end if;
         ---
         open C_ORDLOC_SUM_AREA;
         fetch C_ORDLOC_SUM_AREA into O_qty_locs_on_deal;
         close C_ORDLOC_SUM_AREA;
         ---
      elsif L_org_level = 3 then
         ---
         if L_dil_region = L_sh_region then
            O_item_is_buy_item := TRUE;
            O_deal_id := L_deal_id;
            O_buy_qty := L_buy_qty;
            O_get_type := L_get_type;
            O_get_value := L_get_value;
            O_get_qty := L_get_qty;
            O_get_item := L_get_item;
         end if;
         ---
         open C_ORDLOC_SUM_REGION;
         fetch C_ORDLOC_SUM_REGION into O_qty_locs_on_deal;
         close C_ORDLOC_SUM_REGION;
         ---
      elsif L_org_level = 4 then
         ---
         if L_dil_district = L_sh_district then
            O_item_is_buy_item := TRUE;
            O_deal_id := L_deal_id;
            O_buy_qty := L_buy_qty;
            O_get_type := L_get_type;
            O_get_value := L_get_value;
            O_get_qty := L_get_qty;
            O_get_item := L_get_item;
         end if;
         ---
         open C_ORDLOC_SUM_DISTRICT;
         fetch C_ORDLOC_SUM_DISTRICT into O_qty_locs_on_deal;
         close C_ORDLOC_SUM_DISTRICT;
         ---
      end if;
      ---
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.CHECK_IS_BUY_ITEM',
                                            to_char(SQLCODE));
   return FALSE;
END CHECK_IS_BUY_ITEM;
--------------------------------------------------------------------------------------------
--Function:  GET_ITEM_LOC_DEAL_DISCOUNTS
--Purpose:   This function will calculate the total item/loc discounts that have been
--           applied to a PO
--------------------------------------------------------------------------------------------
FUNCTION GET_ITEM_LOC_DEAL_DISCOUNTS(O_error_message                   IN OUT      VARCHAR2,
                                     O_total_deal_discs                IN OUT      ordloc_discount.discount_amt_per_unit%TYPE,
                                     I_order_no                        IN          ordhead.order_no%TYPE)
RETURN BOOLEAN IS

   cursor C_GET_TOTAL is
      select sum(nvl(old.discount_amt_per_unit,0)*v.total_qty_ordered)
        from ordloc_discount old,
             V_ORDLOC_STORES_PHYS_WH v
       where old.order_no = v.order_no
         and old.item = v.item
         and old.location = v.location
         and old.order_no = I_order_no
       group by old.order_no;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_TOTAL','ORDLOC_DISCOUNT','ORDER NO: '||to_char(I_order_no));
   open C_GET_TOTAL;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_TOTAL','ORDLOC_DISCOUNT','ORDER NO: '||to_char(I_order_no));
   fetch C_GET_TOTAL into O_total_deal_discs;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_TOTAL','ORDLOC_DISCOUNT','ORDER NO: '||to_char(I_order_no));
   close C_GET_TOTAL;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.GET_ITEM_LOC_DEAL_DISCOUNTS',
                                            to_char(SQLCODE));
   return FALSE;
END GET_ITEM_LOC_DEAL_DISCOUNTS;
--------------------------------------------------------------------------------------------
FUNCTION DELETE_ITEMLOC_THRESH(O_error_message             IN OUT      VARCHAR2,
                               I_itemloc_exist             BOOLEAN,
                               I_thresh_exist              BOOLEAN,
                               I_deal_id                   IN          DEAL_ITEMLOC.DEAL_ID%TYPE,
                               I_deal_detail_id            IN          DEAL_ITEMLOC.DEAL_DETAIL_ID%TYPE)
RETURN BOOLEAN IS

   cursor C_LOCK_DEAL_ITEMLOC is
      select 'x'
       from deal_itemloc
      where deal_id = I_deal_id
        and deal_detail_id = I_deal_detail_id
        for update nowait;

   cursor C_LOCK_DEAL_THRESHOLD is
      select 'x'
       from deal_threshold
      where deal_id = I_deal_id
        and deal_detail_id = I_deal_detail_id
        for update nowait;

   cursor C_LOCK_DEAL_ITEM_LOC_EXPLODE is
      select 'x'
       from deal_item_loc_explode
      where deal_id = I_deal_id
        and deal_detail_id = I_deal_detail_id
        for update nowait;

   cursor C_LOCK_DEAL_THRESHOLD_REV is
      select 'x'
       from deal_threshold_rev
      where deal_id = I_deal_id
        and deal_detail_id = I_deal_detail_id
        for update nowait;

BEGIN
   if I_itemloc_exist then
      --if the record exists, lock table deal_itemloc and remove deal
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DEAL_ITEMLOC',
                       'DEAL_ITEMLOC',
                       'DEAL ID: '||to_char(I_deal_id));

      open C_LOCK_DEAL_ITEMLOC;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DEAL_ITEMLOC',
                       'DEAL_ITEMLOC',
                       'DEAL ID: '||to_char(I_deal_id));

      close C_LOCK_DEAL_ITEMLOC;
      ---
      SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_ITEMLOC', 'DEAL ID '||TO_CHAR(I_deal_id));

      delete from deal_itemloc
       where deal_itemloc.deal_id = I_deal_id
         and deal_itemloc.deal_detail_id = I_deal_detail_id;
      ---
      --lock table deal_item_loc_explode and remove deal
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DEAL_ITEM_LOC_EXPLODE',
                       'DEAL_ITEM_LOC_EXPLODE',
                       'DEAL ID: '||to_char(I_deal_id));

      open C_LOCK_DEAL_ITEM_LOC_EXPLODE;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DEAL_ITEM_LOC_EXPLODE',
                       'DEAL_ITEM_LOC_EXPLODE',
                       'DEAL ID: '||to_char(I_deal_id));

      close C_LOCK_DEAL_ITEM_LOC_EXPLODE;
      ---
      SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_ITEM_LOC_EXPLODE', 'DEAL ID '||TO_CHAR(I_deal_id));

      delete from deal_item_loc_explode
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;
      ---
   end if;

   if I_thresh_exist then
      --if the record exists, lock table deal_threshold and remove deal
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DEAL_THRESHOLD',
                       'DEAL_THRESHOLD',
                       'DEAL ID: '||to_char(I_deal_id));

      open C_LOCK_DEAL_THRESHOLD;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DEAL_THRESHOLD',
                       'DEAL_THRESHOLD',
                       'DEAL ID: '||to_char(I_deal_id));

      close C_LOCK_DEAL_THRESHOLD;
      ---
      SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_THRESHOLD', 'DEAL ID '||TO_CHAR(I_deal_id));

      delete from deal_threshold
       where deal_threshold.deal_id = I_deal_id
         and deal_threshold.deal_detail_id = I_deal_detail_id;
      ---
      --lock table deal_threshold_rev and remove deal
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DEAL_THRESHOLD_REV',
                       'DEAL_ITEM_THRESHOLD_REV',
                       'DEAL ID: '||to_char(I_deal_id));

      open C_LOCK_DEAL_THRESHOLD_REV;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DEAL_THRESHOLD_REV',
                       'DEAL_THRESHOLD_REV',
                       'DEAL ID: '||to_char(I_deal_id));

      close C_LOCK_DEAL_THRESHOLD_REV;
      ---
      SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_THRESHOLD_REV', 'DEAL ID '||TO_CHAR(I_deal_id));

      delete from deal_threshold_rev
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;
      ---
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.DELETE_ITEMLOC_THRESH',
                                            to_char(SQLCODE));
   return FALSE;
END DELETE_ITEMLOC_THRESH;
--------------------------------------------------------------------------------------------
FUNCTION DELETE_ITEM_LOC_EXPLODE(O_error_message  IN OUT  VARCHAR2,
                                 I_deal_id        IN      DEAL_ITEM_LOC_EXPLODE.DEAL_ID%TYPE,
                                 I_deal_detail_id IN      DEAL_ITEM_LOC_EXPLODE.DEAL_DETAIL_ID%TYPE)
RETURN BOOLEAN IS

   cursor C_LOCK_DEAL_ITEM_LOC_EXPLODE is
      select 'x'
       from deal_item_loc_explode
      where deal_id = I_deal_id
        and deal_detail_id = I_deal_detail_id
        for update nowait;

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_ITEM_LOC_EXPLODE','DEAL_ITEM_LOC_EXPLODE','DEAL ID: '||to_char(I_deal_id));
   open C_LOCK_DEAL_ITEM_LOC_EXPLODE;

   SQL_LIB.SET_MARK('OPEN','C_LOCK_DEAL_ITEM_LOC_EXPLODE','DEAL_ITEM_LOC_EXPLODE','DEAL ID: '||to_char(I_deal_id));
   close C_LOCK_DEAL_ITEM_LOC_EXPLODE;

   SQL_LIB.SET_MARK('DELETE', NULL,'DEAL_ITEM_LOC_EXPLODE', 'DEAL ID '||TO_CHAR(I_deal_id));

   delete from deal_item_loc_explode
    where deal_id = I_deal_id
      and deal_detail_id = I_deal_detail_id;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.DELETE_ITEM_LOC_EXPLODE',
                                            to_char(SQLCODE));
   return FALSE;
END DELETE_ITEM_LOC_EXPLODE;
--------------------------------------------------------------------------------------------
FUNCTION CREATE_FROM_EXIST(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_new_deal_id     IN OUT   DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                           I_deal_id         IN       DEAL_ACTUALS_FORECAST.DEAL_ID%TYPE,
                           I_start_date      IN       DEAL_HEAD.ACTIVE_DATE%TYPE,
                           I_end_date        IN       DEAL_HEAD.CLOSE_DATE%TYPE,
                           I_supplier        IN       DEAL_HEAD.SUPPLIER%TYPE,
                           I_partner_type    IN       DEAL_HEAD.PARTNER_TYPE%TYPE,
                           I_partner_id      IN       DEAL_HEAD.PARTNER_ID%TYPE)
RETURN BOOLEAN IS

   L_program CONSTANT VARCHAR2(61) := 'DEAL_SQL.CREATE_FROM_EXIST';

   L_new_invoice_date               DEAL_HEAD.EST_NEXT_INVOICE_DATE%TYPE;
   L_new_reporting_date             DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE;
   L_last_reporting_date            DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE;
   L_vdate                          DATE := GET_VDATE();
   L_deal_head_rec                  DEAL_HEAD%ROWTYPE;
   L_exists                         BOOLEAN;
   L_first_time                     BOOLEAN := TRUE;
   L_prev_deal_detail_id            DEAL_ACTUALS_FORECAST.DEAL_DETAIL_ID%TYPE;
   L_calc_rep_date                  DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE := NULL;
   L_count_old_deal                 NUMBER(10)  := 0;
   L_count_new_deal                 NUMBER(10)  := 0;
   L_count_deal                     NUMBER(10)  := 0;
   L_reporting_date                 DEAL_ACTUALS_FORECAST.REPORTING_DATE%TYPE;
   L_old_actual_forecast_turnover   DEAL_ACTUALS_FORECAST.ACTUAL_FORECAST_TURNOVER%TYPE;
   -- DefNBS017928, 22-Jun-2010, Sripriya,sripriya.karanam@in.tesco.com (BEGIN)
   L_contact                        DEAL_HEAD.TSL_INTERNAL_CONTACT%TYPE;
   -- DefNBS017928, 22-Jun-2010, Sripriya,sripriya.karanam@in.tesco.com (END)
   -- NBS00018414 22-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   L_cascade_int_contact            VARCHAR2(1);
   -- NBS00018414 22-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
   -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   L_comments                       DEAL_HEAD.Comments%TYPE;
   -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End

   cursor C_LOCK_DEAL_ACTUALS_FORECAST is
      select 'x'
        from deal_actuals_forecast
       where deal_id = O_new_deal_id
         for update nowait;

   cursor C_DEAL_DETAIL is
      select deal_detail_id
        from deal_detail
      where  deal_id = O_new_deal_id;

   cursor C_OLD_DEAL_DETAIL_ID is
      select distinct deal_detail_id
        from deal_actuals_forecast
       where deal_id = I_deal_id;

   cursor C_COUNT_OLD_DEAL_ACTUALS is
      select count(1)
        from deal_actuals_forecast
       where deal_id        = I_deal_id;

   cursor C_COUNT_NEW_DEAL_ACTUALS is
      select count(1)
        from deal_actuals_forecast
       where deal_id        = O_new_deal_id;

   cursor C_GET_OLD_DEAL_ACTUALS (C_deal_detail_id IN DEAL_ACTUALS_FORECAST.DEAL_DETAIL_ID%TYPE) is
      select actual_forecast_turnover
        from deal_actuals_forecast
       where deal_id        = I_deal_id
         and deal_detail_id = C_deal_detail_id
       order by reporting_date;

   cursor C_GET_NEW_DEAL_ACTUALS (C_deal_detail_id IN DEAL_ACTUALS_FORECAST.DEAL_DETAIL_ID%TYPE) is
      select reporting_date
        from deal_actuals_forecast
       where deal_id        = O_new_deal_id
         and deal_detail_id = C_deal_detail_id
       order by reporting_date;

   -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   CURSOR C_GET_COMMENTS is
   select comments
     from deal_head
    where deal_id = I_deal_id;
    -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End

BEGIN
   ---
   if I_deal_id is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                           'I_deal_id',
                                           L_program,
                                           NULL);
      return FALSE;
   end if;
   if I_start_date is NULL then
         O_error_message:= SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                              'I_start_date',
                                              L_program,
                                              NULL);
         return FALSE;
   end if;
   --
   if DEAL_ATTRIB_SQL.GET_NEXT_DEAL_ID(O_error_message,
                                       O_new_deal_id) = FALSE then
      return FALSE;
   end if;
   ---
   if DEAL_HEAD_SQL.GET_ATTRIB(O_error_message,
                               L_exists,
                               L_deal_head_rec,
                               I_deal_id) = FALSE then
      return FALSE;
   end if;
   ---
   -- NBS00018414 22-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
   if L_deal_head_rec.Billing_Type in('BB','MBB','BBR') and L_deal_head_rec.Partner_Type = 'S' then
      L_cascade_int_contact := 'Y';
   else
      L_cascade_int_contact := 'N';
   end if;
   -- NBS00018414 22-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
   -- 17-Jun-2008 Dhuraison Prince - Defect NBS007069 BEGIN
   if L_deal_head_rec.billing_type not in ('OI','MOI') then
   -- 17-Jun-2008 Dhuraison Prince - Defect NBS007069 END
      ---
      if DEAL_FINANCE_SQL.CALC_INITIAL_INVOICE_DATE(O_error_message,
                                                    L_new_invoice_date,
                                                    I_start_date,
                                                    I_end_date,
                                                    L_deal_head_rec.bill_back_period) = FALSE then
          return FALSE;
      end if;
      ---
   end if;
   ---
   -- DefNBS017928, 22-Jun-2010, Sripriya,sripriya.karanam@in.tesco.com (BEGIN)
   if LOC_PROD_SECURITY_SQL.GET_USER_NAME(O_error_message,
          	                              L_contact,
          	                              USER) = FALSE then
      return FALSE;
   end if;
   -- DefNBS017928, 22-Jun-2010, Sripriya,sripriya.karanam@in.tesco.com (END)

   -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_COMMENTS',
                    'DEAL_HEAD',
                    'Deal ID = ' || (I_deal_id));
   open C_GET_COMMENTS ;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_COMMENTS',
                    'DEAL_HEAD',
                    'Deal ID = ' || (I_deal_id));
   fetch C_GET_COMMENTS into L_comments ;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_COMMENTS',
                    'DEAL_HEAD',
                    'Deal ID = ' || (I_deal_id));
   close C_GET_COMMENTS ;
   -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
   insert into deal_head (deal_id,
                          partner_type,
                          partner_id,
                          supplier,
                          type,
                          status,
                          currency_code,
                          active_date,
                          close_date,
                          close_id,
                          create_datetime,
                          create_id,
                          approval_date,
                          approval_id,
                          reject_date,
                          reject_id,
                          ext_ref_no,
                          order_no,
                          recalc_approved_orders,
                          -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
                          --comments,
                          -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
                          last_update_id,
                          last_update_datetime,
                          billing_type,
                          bill_back_period,
                          deal_appl_timing,
                          threshold_limit_type,
                          threshold_limit_uom,
                          rebate_ind,
                          rebate_calc_type,
                          growth_rebate_ind,
                          historical_comp_start_date,
                          historical_comp_end_date,
                          rebate_purch_sales_ind,
                          deal_reporting_level,
                          bill_back_method,
                          deal_income_calculation,
                          invoice_processing_logic,
                          stock_ledger_ind,
                          include_vat_ind,
                          billing_partner_type,
                          billing_partner_id,
                          billing_supplier_id,
                          growth_rate_to_date,
                          turnover_to_date,
                          actual_monies_earned_to_date,
                          security_ind,
                          est_next_invoice_date,
                          last_invoice_date,
                          -- 07-May-2010, DefNBS017371, Govindarajan K, Begin
                          tsl_cost_reason_code,
                          -- 07-May-2010, DefNBS017371, Govindarajan K, End
                          -- 14-Aug-2009 Sarayu P Gouda - Defect NBS010506 BEGIN
                          track_pack_level_ind,
                          -- 14-Aug-2009 Sarayu P Gouda - Defect NBS010506 END
                          --CR280 / Defect 17372 ; Amit Parab ; 09/05/2010 - Begin
                          tsl_channel_id,
                          --CR280 / Defect 17372 ; Amit Parab ; 09/05/2010 - End
                          -- CR316 20-May-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                          tsl_company_code,
                          tsl_rev_company,
                          tsl_rev_account,
                          tsl_rev_cost_centre,
                          tsl_debtor_area,
                          tsl_internal_contact,
                          -- NBS00018414 22-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                          tsl_primary_sales_person
                          -- NBS00023772 19-Oct-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
                          -- Removed the tsl_invoice_to field as per latest requirement of CR378b
                          -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
                          --tsl_invoice_to
                          -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
                          -- NBS00023772 19-Oct-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
                          --
                          )
                          -- NBS00018414 22-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                          -- CR316 20-May-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                   select O_new_deal_id,
                          nvl(I_partner_type, partner_type),
                          decode(nvl(I_partner_type, partner_type), 'S', NULL, nvl(I_partner_id, partner_id)),
                          decode(nvl(I_partner_type, partner_type), 'S', nvl(I_supplier, supplier), NULL),
                          type,
                          'W',
                          currency_code,
                          I_start_date,
                          I_end_date,
                          NULL,
                          SYSDATE,
                          USER,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          ext_ref_no,
                          order_no,
                          recalc_approved_orders,
                          -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
                          --comments,
                          -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
                          USER,
                          SYSDATE,
                          billing_type,
                          bill_back_period,
                          deal_appl_timing,
                          threshold_limit_type,
                          threshold_limit_uom,
                          rebate_ind,
                          rebate_calc_type,
                          growth_rebate_ind,
                          historical_comp_start_date,
                          historical_comp_end_date,
                          rebate_purch_sales_ind,
                          deal_reporting_level,
                          bill_back_method,
                          deal_income_calculation,
                          invoice_processing_logic,
                          stock_ledger_ind,
                          include_vat_ind,
                          --30-Jul-2008 WiproEnabler/karthik -DefNBS00008076 Begin
                          nvl(billing_partner_type, partner_type),
                          decode(nvl(billing_partner_type, partner_type), 'S', NULL, billing_partner_id),
                          decode(nvl(billing_partner_type, partner_type), 'S', billing_supplier_id, NULL),
                          --30-Jul-2008 WiproEnabler/karthik -DefNBS00008076 End
                          0,
                          0,
                          0,
                          security_ind,
                          L_new_invoice_date,
                          NULL,
                          -- 07-May-2010, DefNBS017371, Govindarajan K, Begin
                          tsl_cost_reason_code,
                          -- 07-May-2010, DefNBS017371, Govindarajan K, End
                          -- 14-Aug-2009 Sarayu P Gouda - Defect NBS010506 BEGIN
                          track_pack_level_ind,
                          -- 14-Aug-2009 Sarayu P Gouda - Defect NBS010506 END
                          --CR280 / Defect 17372 ; Amit Parab ; 09/05/2010 - Begin
                          tsl_channel_id,
                          --CR280 / Defect 17372 ; Amit Parab ; 09/05/2010 - End
                          -- CR316 20-May-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                          tsl_company_code,
                          tsl_rev_company,
                          tsl_rev_account,
                          tsl_rev_cost_centre,
                          tsl_debtor_area,
                          -- DefNBS017928, 22-Jun-2010, Sripriya,sripriya.karanam@in.tesco.com (BEGIN)
                          --tsl_internal_contact
                          -- NBS00018414 22-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com Begin
                          decode(L_cascade_int_contact,'Y',L_contact,NULL),
                          tsl_primary_sales_person
                          -- NBS00023772 19-Oct-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
                          -- Removed the tsl_invoice_to field as per latest requirement of CR378b
                          -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
                          -- tsl_invoice_to
                          -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
                          -- NBS00023772 19-Oct-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End
                          -- NBS00018414 22-Jul-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                          -- DefNBS017928, 22-Jun-2010, Sripriya,sripriya.karanam@in.tesco.com (END)
                          -- CR316 20-May-2010 Bhargavi Pujari/bharagavi.pujari@in.tesco.com End
                     from deal_head
                    where deal_id = I_deal_id;
   ---
   -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   update deal_head dh
      set dh.comments = L_comments
    where dh.deal_id  = O_new_deal_id;
   -- CR378b 23-Aug-2011 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End

   insert into deal_detail (deal_id,
                            deal_detail_id,
                            deal_comp_type,
                            application_order,
                            collect_start_date,
                            collect_end_date,
                            cost_appl_ind,
                            price_cost_appl_ind,
                            deal_class,
                            threshold_value_type,
                            qty_thresh_buy_item,
                            qty_thresh_get_type,
                            qty_thresh_get_value,
                            qty_thresh_buy_qty,
                            qty_thresh_recur_ind,
                            qty_thresh_buy_target,
                            qty_thresh_buy_avg_loc,
                            qty_thresh_get_item,
                            qty_thresh_get_qty,
                            qty_thresh_free_item_unit_cost,
                            tran_discount_ind,
                            current_comp_start_date,
                            current_comp_end_date,
                            comments,
                            create_datetime,
                            last_update_id,
                            last_update_datetime,
                            calc_to_zero_ind,
                            total_forecast_units,
                            total_forecast_revenue,
                            total_budget_turnover,
                            total_actual_forecast_turnover,
                            total_baseline_growth_budget,
                            total_baseline_growth_act_for,
                            vfp_default_contrib_pct,
                            total_actual_fixed_ind,
                            total_budget_fixed_ind)
                     select O_new_deal_id,
                            deal_detail_id,
                            deal_comp_type,
                            application_order,
                            I_start_date,
                            I_end_date,
                            cost_appl_ind,
                            price_cost_appl_ind,
                            deal_class,
                            threshold_value_type,
                            qty_thresh_buy_item,
                            qty_thresh_get_type,
                            qty_thresh_get_value,
                            qty_thresh_buy_qty,
                            qty_thresh_recur_ind,
                            qty_thresh_buy_target,
                            qty_thresh_buy_avg_loc,
                            qty_thresh_get_item,
                            qty_thresh_get_qty,
                            qty_thresh_free_item_unit_cost,
                            tran_discount_ind,
                            current_comp_start_date,
                            current_comp_end_date,
                            comments,
                            SYSDATE,
                            USER,
                            SYSDATE,
                            calc_to_zero_ind,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            vfp_default_contrib_pct,
                            'N',
                            total_budget_fixed_ind
                       from deal_detail
                      where deal_id = I_deal_id;
   ---
   insert into deal_itemloc (deal_id,
                             deal_detail_id,
                             seq_no,
                             merch_level,
                             company_ind,
                             division,
                             group_no,
                             dept,
                             class,
                             subclass,
                             item_parent,
                             item_grandparent,
                             diff_1,
                             diff_2,
                             diff_3,
                             diff_4,
                             org_level,
                             chain,
                             area,
                             region,
                             district,
                             location,
                             origin_country_id,
                             loc_type,
                             item,
                             excl_ind,
                             create_datetime,
                             last_update_id,
                             last_update_datetime)
                      select O_new_deal_id,
                             deal_detail_id,
                             seq_no,
                             merch_level,
                             company_ind,
                             division,
                             group_no,
                             dept,
                             class,
                             subclass,
                             item_parent,
                             item_grandparent,
                             diff_1,
                             diff_2,
                             diff_3,
                             diff_4,
                             org_level,
                             chain,
                             area,
                             region,
                             district,
                             location,
                             origin_country_id,
                             loc_type,
                             item,
                             excl_ind,
                             SYSDATE,
                             USER,
                             SYSDATE
                        from deal_itemloc
                       where deal_id = I_deal_id;
   ---
   insert into deal_threshold (deal_id,
                               deal_detail_id,
                               lower_limit,
                               upper_limit,
                               value,
                               target_level_ind,
                               create_datetime,
                               last_update_id,
                               last_update_datetime,
                               total_ind,
                               reason)
                        select O_new_deal_id,
                               deal_detail_id,
                               lower_limit,
                               upper_limit,
                               value,
                               target_level_ind,
                               SYSDATE,
                               USER,
                               SYSDATE,
                               total_ind,
                               reason
                          from deal_threshold
                         where deal_id = I_deal_id;
   ---
   -- When billing type is Off-Invoice then there will be no
   -- deal performance records required

   -- 17-Jun-2008 Dhuraison Prince - Defect NBS007069 BEGIN
   if L_deal_head_rec.billing_type not in ('OI','MOI') then
   -- 17-Jun-2008 Dhuraison Prince - Defect NBS007069 END
      ---
      for L_new_deal_detail_rec in C_DEAL_DETAIL LOOP
         if DEAL_ACTUAL_FORECAST_SQL.CREATE_TEMPLATE(O_error_message,
                                                     O_new_deal_id,
                                                     I_start_date,
                                                     I_end_date,
                                                     L_new_deal_detail_rec.deal_detail_id,
                                                     L_deal_head_rec.deal_reporting_level) = FALSE then
            return FALSE;
         end if;

      end LOOP;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DEAL_ACTUALS_FORECAST',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(O_new_deal_id));
      open C_LOCK_DEAL_ACTUALS_FORECAST;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DEAL_ACTUALS_FORECAST',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(O_new_deal_id));
      close C_LOCK_DEAL_ACTUALS_FORECAST;
      ---
      --Update the new deal actuals forecast baseline turnover with
      --the actual forecast turnover from the existind deal
      SQL_LIB.SET_MARK('OPEN',
                       'C_COUNT_OLD_DEAL_ACTUALS',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(I_deal_id));
      open C_COUNT_OLD_DEAL_ACTUALS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_COUNT_OLD_DEAL_ACTUALS',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(I_deal_id));
      fetch C_COUNT_OLD_DEAL_ACTUALS into L_count_old_deal;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_COUNT_OLD_DEAL_ACTUALS',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(I_deal_id));
      close C_COUNT_OLD_DEAL_ACTUALS;

      SQL_LIB.SET_MARK('OPEN',
                       'C_COUNT_NEW_DEAL_ACTUALS',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(O_new_deal_id));
      open C_COUNT_NEW_DEAL_ACTUALS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_COUNT_NEW_DEAL_ACTUALS',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(O_new_deal_id));
      fetch C_COUNT_NEW_DEAL_ACTUALS into L_count_new_deal;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_COUNT_NEW_DEAL_ACTUALS',
                       'DEAL_ACTUALS_FORECAST',
                       'DEAL ID: '||to_char(O_new_deal_id));
      close C_COUNT_NEW_DEAL_ACTUALS;

      if L_count_old_deal >= L_count_new_deal then
         L_count_deal := L_count_new_deal;
      else
         L_count_deal := L_count_old_deal;
      end if;

      FOR rec_old in C_OLD_DEAL_DETAIL_ID LOOP
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_OLD_DEAL_ACTUALS',
                          'DEAL_ACTUALS_FORECAST',
                          'DEAL ID: '||to_char(I_deal_id));
         open C_GET_OLD_DEAL_ACTUALS (rec_old.deal_detail_id);

         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_NEW_DEAL_ACTUALS',
                          'DEAL_ACTUALS_FORECAST',
                          'DEAL ID: '||to_char(O_new_deal_id));
         open C_GET_NEW_DEAL_ACTUALS (rec_old.deal_detail_id);

         FOR i in 1..L_count_deal LOOP

            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_OLD_DEAL_ACTUALS',
                             'DEAL_ACTUALS_FORECAST',
                             'DEAL ID: '||to_char(I_deal_id));
            fetch C_GET_OLD_DEAL_ACTUALS into L_old_actual_forecast_turnover;

            if L_old_actual_forecast_turnover is NULL then
               Exit;
            end if;

            SQL_LIB.SET_MARK('FETCH',
                              'C_GET_NEW_DEAL_ACTUALS',
                              'DEAL_ACTUALS_FORECAST',
                              'DEAL ID: '||to_char(O_new_deal_id));
            fetch C_GET_NEW_DEAL_ACTUALS into L_reporting_date;

            if L_reporting_date is NULL then
               return FALSE;
            end if;

            SQL_LIB.SET_MARK('UPDATE',
                             'C_GET_NEW_DEAL_ACTUALS',
                             'DEAL_ACTUALS_FORECAST',
                             'DEAL ID: '||to_char(O_new_deal_id));

            update deal_actuals_forecast daf
               set daf.baseline_turnover = L_old_actual_forecast_turnover
             where daf.deal_id         = O_new_deal_id
               and daf.deal_detail_id  = rec_old.deal_detail_id
               and daf.reporting_date  = L_reporting_date;

         END LOOP;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_OLD_DEAL_ACTUALS',
                          'DEAL_ACTUALS_FORECAST',
                          'DEAL ID: '||to_char(I_deal_id));
         close C_GET_OLD_DEAL_ACTUALS;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_NEW_DEAL_ACTUALS',
                          'DEAL_ACTUALS_FORECAST',
                          'DEAL ID: '||to_char(O_new_deal_id));
         close C_GET_NEW_DEAL_ACTUALS;
      END LOOP;
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'deal_actuals_forecast',
                                            I_deal_id,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.CREATE_FROM_EXIST',
                                            to_char(SQLCODE));
   return FALSE;
END CREATE_FROM_EXIST;
--------------------------------------------------------------------------------------------
FUNCTION PO_CASCADE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                    O_po_cascade      IN OUT   VARCHAR2,
                    I_deal_id         IN       DEAL_DETAIL.DEAL_ID%TYPE)
RETURN BOOLEAN IS

   cursor C_DEAL_EXCLUSIVE_IND IS
   select 'Y'
     from deal_detail
    where deal_id = I_deal_id
      and (tran_discount_ind = 'N'
           or deal_class = 'EX');

   L_exclusive_ind       VARCHAR2(1)    := 'N';
   L_program_name        VARCHAR2(20)   := 'DEAL_SQL.PO_CASCADE';
BEGIN

   --check for null parameter
   if I_deal_id is NULL then
      O_error_message := sql_lib.create_msg('REQUIRED_INPUT_IS_NULL', 'I_deal_id', L_program_name, NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_DEAL_EXCLUSIVE_IND', 'DEAL_DETAIL', NULL);
   open C_DEAL_EXCLUSIVE_IND;
   SQL_LIB.SET_MARK('FETCH', 'C_DEAL_EXCLUSIVE_IND', 'DEAL_DETAIL', NULL);
   fetch C_DEAL_EXCLUSIVE_IND into L_exclusive_ind;
   SQL_LIB.SET_MARK('CLOSE', 'C_DEAL_EXCLUSIVE_IND', 'DEAL_DETAIL', NULL);
   close C_DEAL_EXCLUSIVE_IND;
   O_po_cascade := L_exclusive_ind;
return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
   return FALSE;

END PO_CASCADE;
--------------------------------------------------------------------------------------------
FUNCTION CHECK_STATUS(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      O_status         IN OUT  FIXED_DEAL.STATUS%TYPE,
                      I_end_date       IN      FIXED_DEAL.COLLECT_END_DATE%TYPE,
                      I_deal_no        IN      FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   L_old_status              FIXED_DEAL.STATUS%TYPE;
   L_vdate                   PERIOD.VDATE%TYPE;
   L_program_name            VARCHAR2(30)   := 'DEAL_SQL.CHECK_STATUS';

   cursor C_OLD_VALUE is
   select status
     from fixed_deal
    where deal_no = I_deal_no;

BEGIN

   L_vdate := GET_VDATE();

   if I_end_date < L_vdate then
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

      if L_old_status is not NULL then
         O_status := L_old_status;
      end if;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
   return FALSE;

END CHECK_STATUS;

--------------------------------------------------------------------------------------------
FUNCTION CHECK_TYPE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                    O_type           IN OUT  FIXED_DEAL.TYPE%TYPE,
                    I_start_date     IN      FIXED_DEAL.COLLECT_START_DATE%TYPE,
                    I_deal_no        IN      FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   L_old_type                FIXED_DEAL.TYPE%TYPE;
   L_vdate                   PERIOD.VDATE%TYPE;
   L_program_name            VARCHAR2(30)   := 'DEAL_SQL.CHECK_TYPE';

   cursor C_OLD_VALUE is
   select type
     from fixed_deal
    where deal_no = I_deal_no;

BEGIN

   L_vdate := GET_VDATE();

   if I_start_date < L_vdate then
      SQL_LIB.SET_MARK('OPEN',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      open C_OLD_VALUE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      fetch C_OLD_VALUE into L_old_type;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      close C_OLD_VALUE;

      if L_old_type is not NULL then
         O_type := L_old_type;
      end if;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
   return FALSE;

END CHECK_TYPE;

--------------------------------------------------------------------------------------------
FUNCTION CHECK_INVOICE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                       O_invoice        IN OUT  FIXED_DEAL.INVOICE_PROCESSING_LOGIC%TYPE,
                       I_start_date     IN      FIXED_DEAL.COLLECT_START_DATE%TYPE,
                       I_deal_no        IN      FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   L_old_invoice             FIXED_DEAL.INVOICE_PROCESSING_LOGIC%TYPE;
   L_vdate                   PERIOD.VDATE%TYPE;
   L_program_name            VARCHAR2(50)   := 'DEAL_SQL.CHECK_INVOICE';

   cursor C_OLD_VALUE is
   select invoice_processing_logic
     from fixed_deal
    where deal_no = I_deal_no;

BEGIN

   L_vdate := GET_VDATE();

   if I_start_date < L_vdate then
      SQL_LIB.SET_MARK('OPEN',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      open C_OLD_VALUE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      fetch C_OLD_VALUE into L_old_invoice;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      close C_OLD_VALUE;

      if L_old_invoice is not NULL then
         O_invoice := L_old_invoice;
      end if;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
   return FALSE;

END CHECK_INVOICE;

--------------------------------------------------------------------------------------------
FUNCTION CHECK_DEBIT_CREDIT(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                            O_deb_cred       IN OUT  FIXED_DEAL.DEB_CRED_IND%TYPE,
                            I_start_date     IN      FIXED_DEAL.COLLECT_START_DATE%TYPE,
                            I_deal_no        IN      FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   L_old_deb_cred            FIXED_DEAL.DEB_CRED_IND%TYPE;
   L_vdate                   PERIOD.VDATE%TYPE;
   L_program_name            VARCHAR2(50)   := 'DEAL_SQL.CHECK_DEBIT_CREDIT';

   cursor C_OLD_VALUE is
   select deb_cred_ind
     from fixed_deal
    where deal_no = I_deal_no;

BEGIN

   L_vdate := GET_VDATE();

   if I_start_date < L_vdate then
      SQL_LIB.SET_MARK('OPEN',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      open C_OLD_VALUE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      fetch C_OLD_VALUE into L_old_deb_cred;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      close C_OLD_VALUE;

      if L_old_deb_cred is not NULL then
         O_deb_cred := L_old_deb_cred;
      end if;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
   return FALSE;

END CHECK_DEBIT_CREDIT;

--------------------------------------------------------------------------------------------
FUNCTION CHECK_MERCH_IND(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_merch_ind      IN OUT  FIXED_DEAL.MERCH_IND%TYPE,
                         I_start_date     IN      FIXED_DEAL.COLLECT_START_DATE%TYPE,
                         I_deal_no        IN      FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   L_old_merch_ind           FIXED_DEAL.MERCH_IND%TYPE;
   L_vdate                   PERIOD.VDATE%TYPE;
   L_program_name            VARCHAR2(40)   := 'DEAL_SQL.MERCH_IND';

   cursor C_OLD_VALUE is
   select merch_ind
     from fixed_deal
    where deal_no = I_deal_no;

BEGIN

   L_vdate := GET_VDATE();

   if I_start_date < L_vdate then
      SQL_LIB.SET_MARK('OPEN',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      open C_OLD_VALUE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      fetch C_OLD_VALUE into L_old_merch_ind;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      close C_OLD_VALUE;

      if L_old_merch_ind is not NULL then
         O_merch_ind := L_old_merch_ind;
      end if;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
   return FALSE;

END CHECK_MERCH_IND;

--------------------------------------------------------------------------------------------
FUNCTION CHECK_VAT_IND(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                       O_vat_ind        IN OUT  FIXED_DEAL.VAT_IND%TYPE,
                       I_start_date     IN      FIXED_DEAL.COLLECT_START_DATE%TYPE,
                       I_deal_no        IN      FIXED_DEAL.DEAL_NO%TYPE)
RETURN BOOLEAN IS

   L_old_vat_ind             FIXED_DEAL.VAT_IND%TYPE;
   L_vdate                   PERIOD.VDATE%TYPE;
   L_program_name            VARCHAR2(40)   := 'DEAL_SQL.VAT_IND';

   cursor C_OLD_VALUE is
   select vat_ind
     from fixed_deal
    where deal_no = I_deal_no;

BEGIN

   L_vdate := GET_VDATE();

   if I_start_date < L_vdate then
      SQL_LIB.SET_MARK('OPEN',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      open C_OLD_VALUE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      fetch C_OLD_VALUE into L_old_vat_ind;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_OLD_VALUE',
                       'FIXED_DEAL',
                       NULL);
      close C_OLD_VALUE;

      if L_old_vat_ind is not NULL then
         O_vat_ind := L_old_vat_ind;
      end if;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program_name,
                                            to_char(SQLCODE));
   return FALSE;

END CHECK_VAT_IND;
-- 23.10.2007, ORMS 364.2,Richard Addison(BEGIN)
--------------------------------------------------------------------------------------------
--Function:  TSL_UPDATE_TSL_FUTURE_COST
--Purpose:   When deals are approved, unapproved or closed, the dealmain form will make a
--           direct call to this new function to update TSL_FUTURE_COST in real time for
--           MOI/MBB/MRR type deals on primary pack/primary pack supplier /primary pack
--           supplier primary country. Merchandise level records will not have been exploded
--           yet and will be handled by the batch. The code also needs to process supplier
--           groups functionality for MBB/MMR type deals(See BSD 32)
--           Also need to update DEAL_ITEM_LOC_EXPLODE to inform the batch of any changes
--           to merch level deals in the case of updates or unnaprovals.
--------------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_TSL_FUTURE_COST (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_deal_id       IN     DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(100)   := 'DEAL_SQL.TSL_UPDATE_TSL_FUTURE_COST';
   L_item     ITEM_MASTER.ITEM%TYPE;
   -- 17-Apr-08 - Dhuraison Prince - BEGIN
   L_table    VARCHAR2(64);

   -- exceptions declaration
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   -- 17-Apr-08 - Dhuraison Prince - END

    cursor C_GET_ITEMS is
    select distinct(pi.item)
      from item_master im,
           packitem pi,
           item_supp_country isc,
           deal_head dh,
           deal_detail dd,
           deal_itemloc di
     where dh.deal_id = I_deal_id
       and dh.billing_type IN ('MOI','MBB','MRR')
       and dd.deal_id = dh.deal_id
       and di.deal_id = dh.deal_id
       and di.deal_detail_id = dd.deal_detail_id
       and di.merch_level = 12
       and di.item = im.item
       and di.excl_ind = 'N'
       and im.tsl_prim_pack_ind = 'Y'
       and pi.pack_no = im.item
       and isc.item = im.item
       and isc.primary_supp_ind = 'Y'
       and isc.primary_country_ind = 'Y'
       and isc.origin_country_id =NVL(di.origin_country_id,isc.origin_country_id)
       and dh.supplier = isc.supplier;

   -- 17-Apr-08 - Dhuraison Prince - BEGIN
   -- cursor for record locking
   CURSOR C_LOCK_DEAL_ITEM_LOC_EXPLODE is
   select 'X'
     from deal_item_loc_explode
    where deal_id = I_deal_id
      for update of tsl_rtc_processed nowait;
   -- 17-Apr-08 - Dhuraison Prince - END

BEGIN
   O_error_message := ' ';

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DEAL',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   --
   -- Update real time future costs for the pack compoenent if the deal applies
   -- to a primary pack/ supplier / country.
   for c_rec in C_GET_ITEMS loop
     if (TSL_APPLY_REAL_TIME_COST(O_error_message,
                                  c_rec.item,
                                 'Y',
   -- 26-Aug-2008 Tesco HSC/Satish B.N DefNBS007325 Begin
                                 'O')!=0) then
   -- 26-Aug-2008 Tesco HSC/Satish B.N DefNBS007325 End
      return false;
   end if;
   end LOOP;

   -- 17-Apr-08 - Dhuraison Prince - BEGIN
   -- Locking the records for deletion
   L_table := 'DEAL_ITEM_LOC_EXPLODE';
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_ITEM_LOC_EXPLODE',
                    'DEAL_ITEM_LOC_EXPLODE',
                    'Deal ID = ' || (I_deal_id));
   open C_LOCK_DEAL_ITEM_LOC_EXPLODE;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_ITEM_LOC_EXPLODE',
                    'DEAL_ITEM_LOC_EXPLODE',
                    'Deal ID = ' || (I_deal_id));
   close C_LOCK_DEAL_ITEM_LOC_EXPLODE;
   -- 17-Apr-08 - Dhuraison Prince - END
   ---
   -- Update deal_item_loc_explode to inform the batch of any changes. For newly approved
   -- deals no records will exist.
   SQL_LIB.SET_MARK('UPDATE',
                    '',
                    'DEAL_ITEM_LOC_EXPLODE',
                    'DEAL ID: '||to_char(I_deal_id));

   update deal_item_loc_explode
      set tsl_rtc_processed = 'N'
    where deal_id = I_deal_id;

   return TRUE;
   ---
EXCEPTION
   -- 17-Apr-08 - Dhuraison Prince - BEGIN
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_deal_id,
                                            NULL);
      return FALSE;
   -- 17-Apr-08 - Dhuraison Prince - END
   ---
   when OTHERS then
      -- 17-Apr-08 - Dhuraison Prince - BEGIN
      if C_LOCK_DEAL_ITEM_LOC_EXPLODE%ISOPEN then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_DEAL_ITEM_LOC_EXPLODE',
                          'DEAL_ITEM_LOC_EXPLODE',
                          'Deal ID = ' || (I_deal_id));
         close C_LOCK_DEAL_ITEM_LOC_EXPLODE;
      end if;
      -- 17-Apr-08 - Dhuraison Prince - END
      ---
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_UPDATE_TSL_FUTURE_COST;
-- 23.10.2007, ORMS 364.2,Richard Addison(END)

--------------------------------------------------------------------------------------------
--DefNBS008974, 10-Sep-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com Begin
--Function:  TSL_DELETE_PUB_INFO
--Purpose:   This function is used to delete the records in tsl_deal_pub_info for a deal
--------------------------------------------------------------------------------------------
FUNCTION TSL_DELETE_PUB_INFO (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              I_deal_id       IN     DEAL_HEAD.DEAL_ID%TYPE)
RETURN BOOLEAN IS
   L_program              VARCHAR2(50)    := 'DEAL_SQL.TSL_DELETE_PUB_INFO';
   L_error_message        RTK_ERRORS.RTK_TEXT%TYPE;

   CURSOR C_LOCK_DEAL_PUB_INFO is
   select 'X'
     from tsl_deal_pub_info
    where deal_id    = I_deal_id
      for update nowait;

   CURSOR C_LOCK_DEAL_MFQUEUE is
   select 'X'
     from tsl_deal_mfqueue
    where deal_id    = I_deal_id
      for update nowait;
BEGIN
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   --Deleting Pub info Records
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_PUB_INFO',
                    'TSL_DEAL_PUB_INFO',
                    'DEAL_ID: '||(I_deal_id));
   open C_LOCK_DEAL_PUB_INFO;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_PUB_INFO',
                    'TSL_DEAL_PUB_INFO',
                    'DEAL_ID: '||(I_deal_id));
   close C_LOCK_DEAL_PUB_INFO;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'TSL_DEAL_PUB_INFO',
                    'DEAL_ID: '||(I_deal_id));
   delete from tsl_deal_pub_info
    where  deal_id= I_deal_id;


   --Deleting MF_QUEUE Records
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_DEAL_MFQUEUE',
                    'TSL_DEAL_MFQUEUE',
                    'DEAL_ID: '||(I_deal_id));
   open C_LOCK_DEAL_PUB_INFO;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_DEAL_MFQUEUE',
                    'TSL_DEAL_MFQUEUE',
                    'DEAL_ID: '||(I_deal_id));
   close C_LOCK_DEAL_PUB_INFO;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'TSL_DEAL_MFQUEUE',
                    'DEAL_ID: '||(I_deal_id));

   delete from tsl_deal_mfqueue
    where  deal_id= I_deal_id;

   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           to_char(SQLCODE));
     return FALSE;
END TSL_DELETE_PUB_INFO;
--------------------------------------------------------------------------------------------
--DefNBS008974, 10-Sep-2008, Vipindas T.P., vipindas.thekkepurakkal@in.tesco.com End
END DEAL_SQL;
/

