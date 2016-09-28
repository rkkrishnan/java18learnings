CREATE OR REPLACE PACKAGE BODY DIFF_SQL AS
----------------------------------------------------------------
-- Mod By      : Nandini Mariyappa
-- Mod Date    : 01-Aug-2011
-- Mod Ref     : CR396
-- Mod Details : Added new function TSL_GET_DIFF_ID_DTL to get
--               the Diff_Id details for a Diff_Id_Desc.
----------------------------------------------------------------
-- Mod By      : Vinutha Raju
-- Mod Date    : 01-Aug-2011
-- Mod Ref     : CR396
-- Mod Details : Added new function TSL_CHECK_TPNB_DIFF_EXISTS to check
--               if the diff Id entered is already associated to any of the
--               existing TPNBs.Also added TSL_GET_SEL_DESC
----------------------------------------------------------------
FUNCTION GET_DIFF_INFO_BASED_ON_TYPE ( O_error_message IN OUT VARCHAR2,
                                       O_description   IN OUT V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                                       O_diff_type     IN OUT V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                                       O_id_group_ind  IN OUT V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                                       I_id            IN     V_DIFF_ID_GROUP_TYPE.ID_GROUP%TYPE) return BOOLEAN IS

   L_program       VARCHAR2(64) := 'GET_DIFF_INFO_BASED_ON_TYPE';

   cursor C_INFO is
      select description, diff_type, id_group_ind
        from v_diff_id_group_type
       where id_group = I_id;

BEGIN

   if I_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_id',
                                            'NULL',
                                            'ID');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   open C_INFO;
   SQL_LIB.SET_MARK('FETCH','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   fetch C_INFO into O_description, O_diff_type, O_id_group_ind;
   ---
   if C_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
      close C_INFO;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DIFF',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   close C_INFO;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_description,
                             O_description,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END GET_DIFF_INFO_BASED_ON_TYPE;
--------------------------------------------------------------------------
FUNCTION GET_DIFF_INFO (O_error_message IN OUT VARCHAR2,
                        O_description   IN OUT V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                        O_diff_type     IN OUT V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                        O_id_group_ind  IN OUT V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                        I_id            IN     V_DIFF_ID_GROUP_TYPE.ID_GROUP%TYPE) return BOOLEAN IS

   L_program       VARCHAR2(64) := 'DIFF_SQL.GET_DIFF_INFO';


   cursor C_INFO is
      select   di.diff_desc,
               di.diff_type,
               'ID'
        from   v_diff_group_head vdgh,
               diff_group_detail dgd,
               diff_ids          di
       where   di.diff_id        = I_id
         and   di.diff_id        = dgd.diff_id
         and   dgd.diff_group_id = vdgh.diff_group_id
       union
      select   diff_desc,
               diff_type,
               'ID'
        from   diff_ids
       where   diff_id not in (select dgd.diff_id
                                 from v_diff_group_head vdgh,
                                      diff_group_detail dgd
                                where dgd.diff_group_id = vdgh.diff_group_id)
         and   diff_id = I_id
       union
      select   vdgh.diff_group_desc,
               vdgh.diff_type,
               'GROUP'
        from   v_diff_group_head  vdgh
       where   vdgh.diff_group_id = I_id;

BEGIN

   if I_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_id',
                                            'NULL',
                                            'ID');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   open C_INFO;
   SQL_LIB.SET_MARK('FETCH','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   fetch C_INFO into O_description, O_diff_type, O_id_group_ind;
   ---
   if C_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
      close C_INFO;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DIFF',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   close C_INFO;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_description,
                             O_description,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END GET_DIFF_INFO;
---------------------------------------------------------------------------
FUNCTION DIFF_ID_IN_GROUP (O_error_message  IN OUT   VARCHAR2,
                           O_exists         IN OUT   BOOLEAN,
                           I_diff_grp       IN       DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE,
                           I_diff_id        IN       DIFF_IDS.DIFF_ID%TYPE) return BOOLEAN IS

   L_program       VARCHAR2(64) := 'DIFF_SQL.DIFF_ID_IN_GROUP';
   L_dummy         VARCHAR2(1);

   cursor C_CHECK_GROUPS is
      select 'x'
        from diff_group_detail
       -- MrgNBS024063 16-Dec-2011 Chithraprabha,vadakkedath,chitraprabha@in.tesco.com Begin
       --IM1368290/DefNBS023897, Vinutha Raju, vinutha.raju@in.tesco.com, 04-Nov-11, Begin
       where UPPER(diff_id) = UPPER(I_diff_id)
         and UPPER(diff_group_id) = UPPER(I_diff_grp)
       --IM1368290/DefNBS023897, Vinutha Raju, vinutha.raju@in.tesco.com, 04-Nov-11, End
       -- MrgNBS024063 16-Dec-2011 Chithraprabha,vadakkedath,chitraprabha@in.tesco.com End
         and rownum = 1;  --- added as result of API tkprof for XITEM API performance

BEGIN
   if I_diff_grp is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_diff_grp',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_diff_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_diff_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_GROUPS','DIFF_GROUP_DETAIL','Diff ID: '||I_diff_id||', Diff Group ID: '||I_diff_grp);
   open C_CHECK_GROUPS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_GROUPS','DIFF_GROUP_DETAIL','Diff ID: '||I_diff_id||', Diff Group ID: '||I_diff_grp);
   fetch C_CHECK_GROUPS into L_dummy;
   ---
   if C_CHECK_GROUPS%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_GROUPS','DIFF_GROUP_DETAIL','Diff ID: '||I_diff_id||', Diff Group ID: '||I_diff_grp);
   close C_CHECK_GROUPS;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END DIFF_ID_IN_GROUP;
--------------------------------------------------------------------------
FUNCTION CHILDREN_EXIST(O_error_message  IN OUT   VARCHAR2,
                        O_children_exist IN OUT   BOOLEAN,
                        I_item           IN       ITEM_MASTER.ITEM%TYPE) return BOOLEAN IS

   L_program    VARCHAR2(64) := 'DIFF_SQL.CHILDREN_EXIST';
   L_dummy      VARCHAR2(1);

   cursor C_CHILDREN_EXIST is
      select 'x'
        from item_master
       where (item_parent = I_item
          or item_grandparent = I_item)
         and (diff_1 is not NULL
          or diff_2 is not NULL);

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_CHILDREN_EXIST','ITEM_MASTER','Item: '||I_item);
   open C_CHILDREN_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_CHILDREN_EXIST','ITEM_MASTER','Item: '||I_item);
   fetch C_CHILDREN_EXIST into L_dummy;
   ---
   if C_CHILDREN_EXIST%NOTFOUND then
      O_children_exist := FALSE;
   else
      O_children_exist := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHILDREN_EXIST','ITEM_MASTER','Item: '||I_item);
   close C_CHILDREN_EXIST;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END CHILDREN_EXIST;
--------------------------------------------------------------------------
FUNCTION GET_DIFF_TYPE (O_error_message IN OUT   VARCHAR2,
                        O_diff_type     IN OUT   V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                        I_id            IN       V_DIFF_ID_GROUP_TYPE.ID_GROUP%TYPE) return BOOLEAN IS

   L_program       VARCHAR2(64) := 'DIFF_SQL.GET_DIFF_INFO';

   cursor C_TYPE is
      select diff_type
        from v_diff_id_group_type
       where id_group = I_id;

BEGIN

   if I_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_id',
                                            'NULL',
                                            'ID');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_TYPE','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   open C_TYPE;
   SQL_LIB.SET_MARK('FETCH','C_TYPE','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   fetch C_TYPE into O_diff_type;
   ---
   if C_TYPE%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_TYPE','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
      close C_TYPE;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DIFF',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_TYPE','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   close C_TYPE;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END GET_DIFF_TYPE;

--------------------------------------------------------------------------
--     Name: GET_DIFF_INFO
--  Purpose: Retrieve id_group_ind, diff_type, diff_type_desc, diff_description
--------------------------------------------------------------------------
FUNCTION GET_DIFF_INFO (O_error_message   IN OUT   VARCHAR2,
                        O_diff_desc       IN OUT   V_DIFF_ID_GROUP_TYPE.DESCRIPTION%TYPE,
                        O_diff_type_desc  IN OUT   DIFF_TYPE.DIFF_TYPE_DESC%TYPE,
                        O_diff_type       IN OUT   V_DIFF_ID_GROUP_TYPE.DIFF_TYPE%TYPE,
                        O_id_group_ind    IN OUT   V_DIFF_ID_GROUP_TYPE.ID_GROUP_IND%TYPE,
                        I_id              IN       V_DIFF_ID_GROUP_TYPE.ID_GROUP%TYPE)
return BOOLEAN is

   L_program       VARCHAR2(64) := 'DIFF_SQL.GET_DIFF_INFO';

   cursor C_INFO is
      select v.description,
             dt.diff_type_desc,
             v.diff_type,
             v.id_group_ind
        from v_diff_id_group_type v,
             diff_type            dt
       where v.id_group  = I_id
         and v.diff_type = dt.diff_type;

BEGIN

   if I_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_id',
                                            'NULL',
                                            'ID');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   open C_INFO;
   SQL_LIB.SET_MARK('FETCH','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   fetch C_INFO into O_diff_desc,
                     O_diff_type_desc,
                     O_diff_type,
                     O_id_group_ind;
   SQL_LIB.SET_MARK('CLOSE','C_INFO','V_DIFF_ID_GROUP_TYPE','ID: '||I_id);
   close C_INFO;
   ---
   if O_diff_desc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DIFF',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   ---
   if LANGUAGE_SQL.TRANSLATE(O_diff_desc,
                             O_diff_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_diff_type_desc,
                             O_diff_type_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END GET_DIFF_INFO;
--------------------------------------------------------------------------
FUNCTION GET_DIFF_DESC (O_error_message IN OUT VARCHAR2,
                        O_description   IN OUT DIFF_IDS.DIFF_DESC%TYPE,
                        I_diff_id       IN     DIFF_IDS.DIFF_ID%TYPE) return BOOLEAN IS

   L_program       VARCHAR2(64) := 'DIFF_SQL.GET_DIFF_DESC';


   cursor C_DESC is
      select  diff_desc
        from  diff_ids
       where  diff_id = I_diff_id;

BEGIN
/* This function returns the description of a diff_id and should only be used
 * in instances where security policy has already validated Diff, currently
 * being called from the dealmain.fmb form in the deal_itemloc datablock. */

   if I_diff_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_id',
                                            'NULL',
                                            'ID');
      return FALSE;
   end if;

   open C_DESC;
   fetch C_DESC into O_description;
   ---
   if C_DESC%NOTFOUND then
      close C_DESC;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_DIFF',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   close C_DESC;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_description,
                             O_description,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END GET_DIFF_DESC;
--------------------------------------------------------------------------
----------------------------------------------------------------
-- CR396 01-Aug-2011 Nandini M/nandini.mariyappa@in.tesco.com Begin
----------------------------------------------------------------
-- Name   : TSL_GET_DIFF_ID_DTL
-- Purpose: This function returns the diff_id for a diff_description.
----------------------------------------------------------------
FUNCTION TSL_GET_DIFF_ID_DTL (O_error_message IN OUT VARCHAR2,
                              O_diff_id       OUT    DIFF_IDS.DIFF_ID%TYPE,
                              I_description   IN     DIFF_IDS.DIFF_DESC%TYPE
                              )
return BOOLEAN is

   L_program       VARCHAR2(64) := 'DIFF_SQL.TSL_GET_DIFF_ID_DTL';

   cursor C_GET_DIFF_ID is
   select diff_id
     from diff_ids
    where UPPER(diff_desc) = UPPER(I_description);

BEGIN

   /* This function returns the diff_id of a description */

   if I_description is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('ENT_VALID_DIFF_ID',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_GET_DIFF_ID', 'DIFF_IDS', I_description);
   open C_GET_DIFF_ID;

   SQL_LIB.SET_MARK('FETCH', 'C_GET_DIFF_ID', 'DIFF_IDS', I_description);
   fetch C_GET_DIFF_ID into O_diff_id;

   if C_GET_DIFF_ID%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_DIFF_ID', 'DIFF_IDS', I_description);
      close C_GET_DIFF_ID;

      O_error_message := SQL_LIB.CREATE_MSG('INV_DIFF_ID',
                                            I_description,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_DIFF_ID', 'DIFF_IDS', I_description);
   close C_GET_DIFF_ID;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;
END TSL_GET_DIFF_ID_DTL;
----------------------------------------------------------------
-- CR396 01-Aug-2011 Nandini M/nandini.mariyappa@in.tesco.com End
----------------------------------------------------------------
-- CR396 01-Aug-2011 Vinutha R/vinutha.raju@in.tesco.com Begin
----------------------------------------------------------------
-- Name   : TSL_CHECK_TPNB_DIFF_EXISTS
-- Purpose: This function checks if the diff Id entered is already associated to any of the
--               existing TPNBs
----------------------------------------------------------------
FUNCTION TSL_CHECK_TPNB_DIFF_EXISTS (O_error_message  IN OUT   VARCHAR2,
                                     O_exist          IN OUT   BOOLEAN,
                                     I_item_parent    IN       ITEM_MASTER.ITEM%TYPE,
                                     I_item           IN       ITEM_MASTER.ITEM%TYPE,
                                     I_diff_id_1      IN       DIFF_IDS.DIFF_ID%TYPE,
                                     I_diff_id_2      IN       DIFF_IDS.DIFF_ID%TYPE,
                                     I_diff_id_3      IN       DIFF_IDS.DIFF_ID%TYPE,
                                     I_diff_id_4      IN       DIFF_IDS.DIFF_ID%TYPE)
return BOOLEAN is

   L_program    VARCHAR2(64) := 'DIFF_SQL.TSL_CHECK_TPNB_DIFF_EXISTS';
   L_dummy      VARCHAR2(1);

   cursor C_TPNB_WITH_DIFF_ENTRD_EXIST is
   select 'x'
     from item_master
    where item_parent     = I_item_parent
      and item           != I_item
      and NVL(diff_1,'A') = NVL(I_diff_id_1,'A')
      and NVL(diff_2,'A') = NVL(I_diff_id_2,'A')
      and NVL(diff_3,'A') = NVL(I_diff_id_3,'A')
      and NVL(diff_4,'A') = NVL(I_diff_id_4,'A');

BEGIN

   if I_item_parent is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_parent',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

    if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_TPNB_WITH_DIFF_ENTRD_EXIST',
                    'ITEM_MASTER',
                    'Item: '||I_item_parent);
   open C_TPNB_WITH_DIFF_ENTRD_EXIST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_TPNB_WITH_DIFF_ENTRD_EXIST',
                    'ITEM_MASTER',
                    'Item: '||I_item_parent);
   fetch C_TPNB_WITH_DIFF_ENTRD_EXIST into L_dummy;
   ---
   if C_TPNB_WITH_DIFF_ENTRD_EXIST%NOTFOUND then
      O_exist := FALSE;
   else
      O_exist := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_TPNB_WITH_DIFF_ENTRD_EXIST',
                    'ITEM_MASTER',
                    'Item: '||I_item_parent);
   close C_TPNB_WITH_DIFF_ENTRD_EXIST;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END TSL_CHECK_TPNB_DIFF_EXISTS;
----------------------------------------------------------------
-- CR396 01-Aug-2011 Vinutha R/vinutha.raju@in.tesco.com End
----------------------------------------------------------------
-- CR396 02-Aug-2011 Vinutha R/vinutha.raju@in.tesco.com Begin
----------------------------------------------------------------
-- Name   : TSL_GET_SEL_DESC
-- Purpose: This function returns the sel description of an item
----------------------------------------------------------------
FUNCTION TSL_GET_SEL_DESC (O_error_message  IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           O_sel_desc_1     IN OUT   TSL_ITEMDESC_SEL.SEL_DESC_1%TYPE,
                           O_sel_desc_2     IN OUT   TSL_ITEMDESC_SEL.SEL_DESC_2%TYPE,
                           O_sel_desc_3     IN OUT   TSL_ITEMDESC_SEL.SEL_DESC_3%TYPE,
                           I_item           IN       ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is

   L_program    VARCHAR2(64) := 'DIFF_SQL.TSL_GET_SEL_DESC';

   cursor C_GET_SEL_DESC is
   select tis.sel_desc_1,
          tis.sel_desc_2,
          tis.sel_desc_3
     from tsl_itemdesc_sel tis
    where tis.item = I_item
      and tis.effective_date = (select MIN(dt)
                                  from (select MAX(tis2.effective_date) dt
                                          from tsl_itemdesc_sel tis2
                                         where tis2.item           = I_item
                                           and tis2.effective_date <= get_vdate()
                                         union
                                        select MIN(tis3.effective_date) dt
                                          from tsl_itemdesc_sel tis3
                                         where tis3.item           = I_item
                                           and tis3.effective_date > get_vdate()));

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_parent',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_SEL_DESC',
                    'TSL_ITEMDESC_SEL',
                    'Item: '||I_item);
   open C_GET_SEL_DESC;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_SEL_DESC',
                    'TSL_ITEMDESC_SEL',
                    'Item: '||I_item);
   fetch C_GET_SEL_DESC
     into O_sel_desc_1,
          O_sel_desc_2,
          O_sel_desc_3;
   ---

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_SEL_DESC',
                    'TSL_ITEMDESC_SEL',
                    'Item: '||I_item);
   close C_GET_SEL_DESC;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END TSL_GET_SEL_DESC;
----------------------------------------------------------------
-- Name   : TSL_GET_DB_ITEM_DESC
-- Purpose: This function returns the Item/BaseSel/Pack description of an item
----------------------------------------------------------------
FUNCTION TSL_GET_DB_ITEM_DESC (O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                               O_base_item_desc_1 IN OUT  TSL_ITEMDESC_BASE.BASE_ITEM_DESC_1%TYPE,
                               O_base_item_desc_2 IN OUT  TSL_ITEMDESC_BASE.BASE_ITEM_DESC_2%TYPE,
                               O_base_item_desc_3 IN OUT  TSL_ITEMDESC_BASE.BASE_ITEM_DESC_3%TYPE,
                               O_sel_desc_1       IN OUT  TSL_ITEMDESC_SEL.SEL_DESC_1%TYPE,
                               O_sel_desc_2       IN OUT  TSL_ITEMDESC_SEL.SEL_DESC_2%TYPE,
                               O_sel_desc_3       IN OUT  TSL_ITEMDESC_SEL.SEL_DESC_3%TYPE,
                               O_pack_desc        IN OUT  TSL_ITEMDESC_PACK.PACK_DESC%TYPE,
                               O_item_desc        IN OUT  ITEM_MASTER.ITEM_DESC%TYPE,
                               I_item             IN      ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is
   L_program    VARCHAR2(64) := 'DIFF_SQL.TSL_GET_DB_ITEM_DESC';

   cursor C_GET_ITEM_DESC is
   select UPPER(item_desc)
     from item_master
    where item = I_item;

   cursor C_BASE_DESC Is
   select UPPER(tib1.base_item_desc_1),
          UPPER(tib1.base_item_desc_2),
          UPPER(tib1.base_item_desc_3)
     from tsl_itemdesc_base tib1
    where tib1.item           = I_item
      and tib1.effective_date = (select MIN(dt)
                                   from (select MAX(tib3.effective_date) dt
                                           from tsl_itemdesc_base tib3
                                          where tib3.item           = i_item
                                            and tib3.effective_date <= get_vdate()
                                          union
                                         select MIN(tib4.effective_date) dt
                                           from  tsl_itemdesc_base tib4
                                          where  tib4.item           = i_item
                                            and  tib4.effective_date > get_vdate()
                                       )
                                 );
   cursor C_GET_SEL_DESC is
   select UPPER(tis.sel_desc_1),
          UPPER(tis.sel_desc_2),
          UPPER(tis.sel_desc_3)
     from tsl_itemdesc_sel tis
    where tis.item = I_item
      and tis.effective_date = (select MIN(dt)
                                  from (select MAX(tis2.effective_date) dt
                                          from tsl_itemdesc_sel tis2
                                         where tis2.item           = I_item
                                           and tis2.effective_date <= get_vdate()
                                         union
                                        select MIN(tis3.effective_date) dt
                                          from tsl_itemdesc_sel tis3
                                         where tis3.item           = I_item
                                           and tis3.effective_date > get_vdate()));
   cursor C_PACK_OCC Is
   select tpnb.item             tpnb
          ,pi.item
          ,pi.pack_no
          ,pi.pack_qty           pack_qty
          ,tpnd.item             tpnd
          ,tpnd.status           tpnd_status
          ,tpnd.item_desc        tpnd_desc
          ,occ.item              occ
          ,occ.item_number_type  occ_type
          ,isc.unit_cost         pack_cost
          ,iscd.weight           case_weight
     from item_master           tpnb
          ,packitem              pi
          ,item_master           tpnd
          ,item_master           occ
          ,item_supplier         isup
          ,item_supp_country     isc
          ,item_supp_country_dim iscd
    where  tpnb.item                   = I_item
      and  pi.item                     = tpnb.item
      and  tpnd.item                   = pi.pack_no
      and  tpnd.item_level             = 1
      and  tpnd.tran_level             = 1
      and  tpnd.tsl_prim_pack_ind      = 'Y'
      and  occ.item_parent          (+)= tpnd.item
      and  occ.item_level           (+)= 2
      and  occ.tran_level           (+)= 1
      and  occ.primary_ref_item_ind (+)= 'Y'
      and  isup.item                   = tpnd.item
      and  isup.primary_supp_ind       = 'Y'
      and  isc.item                    = isup.item
      and  isc.supplier                = isup.supplier
      and  isc.primary_supp_ind        = 'Y'
      and  isc.primary_country_ind     = 'Y'
      and  iscd.item                (+)= isc.item
      and  iscd.supplier            (+)= isc.supplier
      and  iscd.origin_country      (+)= isc.origin_country_id
      and  iscd.dim_object          (+)= 'CA'
        ;
   r_pack_occ c_pack_occ%rowtype;

   cursor C_PACK_DESC(p_pack_no in tsl_itemdesc_pack.pack_no%TYPE) Is
   select UPPER(tip1.pack_desc)
     from tsl_itemdesc_pack tip1
    where tip1.pack_no        = p_pack_no
      and tip1.effective_date = ( select MIN(dt)
                                   from(select MAX(tip3.effective_date) dt
                                          from tsl_itemdesc_pack tip3
                                         where tip3.pack_no        = p_pack_no
                                           and tip3.effective_date <= get_vdate()
                                        union
                                        select MIN(tip4.effective_date) dt
                                          from tsl_itemdesc_pack tip4
                                         where tip4.pack_no        = p_pack_no
                                           and tip4.effective_date > get_vdate()));
BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_DESC','ITEM_MASTER','ITEM: '||I_item);
   open C_GET_ITEM_DESC;
   SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_DESC','ITEM_MASTER','ITEM: '||I_item);
   fetch C_GET_ITEM_DESC into O_item_desc;
   SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_DESC','ITEM_MASTER','ITEM: '||I_item);
   close C_GET_ITEM_DESC;

   SQL_LIB.SET_MARK('OPEN',
                    'C_BASE_DESC',
                    'TSL_ITEMDESC_BASE',
                    'Item: '||I_item);
   open C_BASE_DESC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_BASE_DESC',
                    'TSL_ITEMDESC_BASE',
                    'Item: '||I_item);
   fetch C_BASE_DESC
    into O_base_item_desc_1,
         O_base_item_desc_2,
         O_base_item_desc_3;
   ---

   SQL_LIB.SET_MARK('CLOSE',
                    'C_BASE_DESC',
                    'TSL_ITEMDESC_BASE',
                    'Item: '||I_item);
   close C_BASE_DESC;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_SEL_DESC',
                    'TSL_ITEMDESC_SEL',
                    'Item: '||I_item);
   open C_GET_SEL_DESC;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_SEL_DESC',
                    'TSL_ITEMDESC_SEL',
                    'Item: '||I_item);
   fetch C_GET_SEL_DESC
    into O_sel_desc_1,
         O_sel_desc_2,
         O_sel_desc_3;
   ---

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_SEL_DESC',
                    'TSL_ITEMDESC_SEL',
                    'Item: '||I_item);


   SQL_LIB.SET_MARK('OPEN',
                    'C_PACK_OCC',
                    'ITEM_MASTER'||'PACKITEM',
                    'Item: '||I_item);
   open c_pack_occ;

   SQL_LIB.SET_MARK('FETCH',
                    'C_PACK_OCC',
                    'ITEM_MASTER'||'PACKITEM',
                    'Item: '||I_item);
   fetch c_pack_occ into r_pack_occ;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_PACK_OCC',
                    'ITEM_MASTER'||'PACKITEM',
                    'Item: '||I_item);
   close c_pack_occ;

   SQL_LIB.SET_MARK('OPEN',
                    'C_PACK_DESC',
                    'TSL_ITEMDESC_PACK',
                    'Item: '||I_item);
   open C_PACK_DESC(r_pack_occ.tpnd);
   SQL_LIB.SET_MARK('FETCH',
                    'C_PACK_DESC',
                    'TSL_ITEMDESC_PACK',
                    'Item: '||I_item);
   fetch C_PACK_DESC into O_pack_desc;
   ---

   SQL_LIB.SET_MARK('CLOSE',
                    'C_PACK_DESC',
                    'TSL_ITEMDESC_PACK',
                    'Item: '||I_item);
   close C_PACK_DESC;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_GET_DB_ITEM_DESC;
-- CR396 02-Aug-2011 Vinutha R/vinutha.raju@in.tesco.com End
----------------------------------------------------------------
END DIFF_SQL;
/

