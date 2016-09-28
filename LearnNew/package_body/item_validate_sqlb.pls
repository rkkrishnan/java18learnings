CREATE OR REPLACE PACKAGE BODY ITEM_VALIDATE_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    27-Sep-2007
--Mod Ref:     Mod number. N20a
--Mod Details: Product attributes cascading
------------------------------------------------------------------------------------------------
--Mod By             : Raghuveer P R, raghuveer.perumal@in.tesco.com
--Mod Date           : 09-May-2008
--Mod Ref            : Mod N111
--Functions included : TSL_BARCODE_CHECK
--Mod Details        : This function will check if the selected Non-Tesco Brand EAN/UCC-13
--                     already is already in use in other ORMS instance.
--Note               : The code added here is for future requirment i.e. once the Barcode Check
--                     Web Service is up and running.Once it is available the below mentioned
--                     code needs to be uncommented and tested accordingly.As of now this part
--                     is commented because of unavailablity of Web Service and it will return
--                     always false i.e., the number does not exist in other instance.
-------------------------------------------------------------------------------------------------
--Mod By     : Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
--Mod Date   : 13-Jun-2008
--Mod Ref    : System Defect NBS00007055
--Mod Details: Added function TSL_EXIST to validate information
-------------------------------------------------------------------------------------------------
--Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
--Defect Id  : NBS00008966
--Mod Date   : 08-Sep-2008
--Mod Details: Modiifed the function TSL_BARCODE_CHECK
----------------------------------------------------------------------------------------------

--Mod By     : Vinod Kumar,vinod.patalappa@in.tesco.com
--Mod Date   : 31-Dec-2008
--Mod Ref    : DefNBS010691
--Mod Details: To make it easy to fecth the value of O_exist called from the Biztalk.
-------------------------------------------------------------------------------------------------
--Mod By     : Ragesh Pillai ,ragesh.pillai@in.tesco.com
--Mod Date   : 02-Jan-2009
--Mod Ref    : DefNBS010712
--Mod Details: Modified the data type of O_exist in procedure TSL_EXIST_PROC from Boolean to Char(1),
--             Since BT RTA adapter expects 'Y' or 'N'
-------------------------------------------------------------------------------------------------
-- Modified by : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        : 20-July-2009
-- Defect Id   : NBS00013905
-- Desc        : Modified function TSL_BARCODE_CHECK
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Mod By      : Nandini Mariyappa
-- Mod Date    : 30-Jun-2010
-- Defect Id   : NBS00018045
-- Desc        : Modified function TSL_BARCODE_CHECK to invoke Barcode web service for SI.
--------------------------------------------------------------------------------------------------------
FUNCTION EXIST(O_error_message  IN OUT  VARCHAR2,
               O_exist          IN OUT  BOOLEAN,
               I_item           IN      ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   cursor C_exist is
      select item
        from item_master
       where item = I_item;

   L_program     VARCHAR2(64) := 'ITEM_VALIDATE_SQL.EXIST';
   L_item        ITEM_MASTER.ITEM%TYPE := NULL;

BEGIN
   /* Initialize output variables */
   O_error_message := NULL;
   O_exist := NULL;

   open C_exist;
   fetch C_exist
    into L_item;
   close C_exist;
   if L_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('INV_ITEM', NULL, NULL, NULL);
      O_exist := FALSE;
   else
      O_exist := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END EXIST;

-----------------------------------------------------------------------------------

FUNCTION CHECK_PARENT_CHILD(O_error_message  IN OUT  VARCHAR2,
                            O_parent         IN OUT  BOOLEAN,
                            O_grandparent    IN OUT  BOOLEAN,
                            I_ancestor       IN      ITEM_MASTER.ITEM%TYPE,
                            I_item           IN      ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   cursor C_relationship is
      select item,
             item_parent,
             item_grandparent
        from item_master
       where item = I_item;

   L_program              VARCHAR2(64) := 'ITEM_VALIDATE_SQL.CHECK_PARENT_CHILD';
   L_item                 ITEM_MASTER.ITEM%TYPE := NULL;
   L_item_parent          ITEM_MASTER.ITEM%TYPE := NULL;
   L_item_grandparent     ITEM_MASTER.ITEM%TYPE := NULL;

BEGIN
   /* Initialize output variables */
   O_error_message := NULL;
   O_parent := NULL;
   O_grandparent := NULL;

   open C_relationship;
   fetch C_relationship
    into L_item,
         L_item_parent,
         L_item_grandparent;
   close C_relationship;
   if L_item_parent = I_ancestor then
      O_parent := TRUE;
      O_grandparent := FALSE;
   else
      ---
      if L_item_grandparent = I_ancestor then
         O_parent := FALSE;
         O_grandparent := TRUE;
      else
         O_error_message := SQL_LIB.CREATE_MSG
                           ('ITEMS_NOT_REL', NULL, NULL, NULL);
         O_parent := FALSE;
         O_grandparent := FALSE;
      end if;
      ---
   end if;

   return TRUE;

EXCEPTION
   when NO_DATA_FOUND then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('NO_DATA_FOUND', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END CHECK_PARENT_CHILD;

-----------------------------------------------------------------------------------

FUNCTION CHILD_GCHILD_EXIST(O_error_message  IN OUT  VARCHAR2,
                            O_child          IN OUT  BOOLEAN,
                            O_gchild         IN OUT  BOOLEAN,
                            I_item           IN      ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   cursor C_grandparent is
      select item
        from item_master
       where item_grandparent = I_item
         and rownum = 1;
   cursor C_parent is
      select item
        from item_master
       where item_parent = I_item
         and rownum = 1;

   L_program              VARCHAR2(64) := 'ITEM_VALIDATE_SQL.CHILD_GCHILD_EXIST';
   L_gchild               ITEM_MASTER.ITEM%TYPE := NULL;
   L_child                ITEM_MASTER.ITEM%TYPE := NULL;

BEGIN
   /* Initialize output variables */
   O_error_message := NULL;
   O_child := NULL;
   O_gchild := NULL;

   open C_grandparent;
   fetch C_grandparent
    into L_gchild;
   close C_grandparent;
   if L_gchild is not NULL then
      O_child := TRUE;
      O_gchild := TRUE;
   else
      O_gchild := FALSE;
      open C_parent;
      fetch C_parent
       into L_child;
      close C_parent;
      ---
      if L_child is not NULL then
         O_child := TRUE;
      else
         O_child := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG
                           ('ITEM_NO_CHLD', NULL, NULL, NULL);
      end if;
      ---
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END CHILD_GCHILD_EXIST;

-----------------------------------------------------------------------------------

FUNCTION HIST_EXIST(O_error_message  IN OUT  VARCHAR2,
                    O_exist          IN OUT  BOOLEAN,
                    I_item           IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   cursor C_exist is
      select item
        from item_loc_hist
       where item = I_item
         and rownum = 1;

   L_program     VARCHAR2(64) := 'ITEM_VALIDATE_SQL.HIST_EXIST';
   L_item        ITEM_MASTER.ITEM%TYPE := NULL;

BEGIN
   /* Initialize output variables */
   O_error_message := NULL;
   O_exist := NULL;

   open C_exist;
   fetch C_exist
    into L_item;
   close C_exist;
   if L_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('NO_ITEM_LOC_HIST', NULL, NULL, NULL);
      O_exist := FALSE;
   else
      O_exist := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END HIST_EXIST;

-----------------------------------------------------------------------------------

FUNCTION VPN_GET_ITEM(O_error_message IN OUT  VARCHAR2,
                      O_item          IN OUT  ITEM_MASTER.ITEM%TYPE,
                      O_vpn_desc      IN OUT  ITEM_MASTER.DESC_UP%TYPE,
                      O_multiple      IN OUT  BOOLEAN,
                      O_exist         IN OUT  BOOLEAN,
                      I_vpn           IN      ITEM_SUPPLIER.VPN%TYPE)
RETURN BOOLEAN IS

   cursor C_get_vpn_item is
      select s.item,
             m.desc_up
        from item_supplier s,
             item_master m
       where s.vpn = I_vpn
         and s.item = m.item;

   L_program     VARCHAR2(64) := 'ITEM_VALIDATE_SQL.VPN_GET_ITEM';

BEGIN
   /* Initialize output variables */
   O_error_message := NULL;
   O_item := NULL;
   O_vpn_desc := NULL;
   O_multiple := NULL;
   O_exist := NULL;

   open c_get_vpn_item;
   fetch c_get_vpn_item
    into O_item,
         O_vpn_desc;
   if c_get_vpn_item%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('INV_VPN', NULL, NULL, NULL);
      O_exist := FALSE;
   else
      O_exist := TRUE;
      ---
      if LANGUAGE_SQL.TRANSLATE(O_vpn_desc,
                                O_vpn_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      ---
      fetch c_get_vpn_item
       into O_item,
            O_vpn_desc;
      ---
      if c_get_vpn_item%FOUND then
         O_multiple := TRUE;
         ---
         if LANGUAGE_SQL.TRANSLATE(O_vpn_desc,
                                   O_vpn_desc,
                                   O_error_message) = FALSE then
            return FALSE;
         end if;
         ---
      else
         O_multiple := FALSE;
      end if;
      ---
   end if;
   close c_get_vpn_item;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END VPN_GET_ITEM;
----------------------------------------------------------------------------------
FUNCTION VPN_GET_ITEM_DESC(O_error_message IN OUT  VARCHAR2,
                           O_item          IN OUT  ITEM_MASTER.ITEM%TYPE,
                           O_vpn_desc      IN OUT  ITEM_MASTER.DESC_UP%TYPE,
                           O_exist         IN OUT  BOOLEAN,
                           I_vpn           IN      ITEM_SUPPLIER.VPN%TYPE,
                           I_supplier      IN      ITEM_SUPPLIER.SUPPLIER%TYPE)
   RETURN BOOLEAN IS
   cursor C_GET_ITEM_DESC is
      select s.item,
             m.desc_up
        from item_supplier s,
             item_master m
       where s.supplier = I_supplier
         and s.vpn = I_vpn
         and s.item = m.item;

   L_program     VARCHAR2(64) := 'ITEM_VALIDATE_SQL.VPN_GET_ITEM_DESC';

BEGIN
   /* Initialize output variables */
   O_error_message := NULL;
   O_item := NULL;
   O_vpn_desc := NULL;
   O_exist := NULL;

   open C_GET_ITEM_DESC;
   fetch C_GET_ITEM_DESC into O_item,
                              O_vpn_desc;
   if C_GET_ITEM_DESC%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_VPN', NULL, NULL, NULL);
      O_exist := FALSE;
   else
      O_exist := TRUE;
      ---
      if LANGUAGE_SQL.TRANSLATE(O_vpn_desc,
                                O_vpn_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
   close C_GET_ITEM_DESC;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;
END VPN_GET_ITEM_DESC;
----------------------------------------------------------------------------------
FUNCTION VALID_CHILDREN_EXIST(O_error_message  IN OUT  VARCHAR2,
                              O_exist          IN OUT  BOOLEAN,
                              I_item           IN      ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   cursor C_CHILDREN is
      select item
        from item_master
       where item_parent = I_item
         and status != 'D';

   L_program              VARCHAR2(64) := 'ITEM_VALIDATE_SQL.VALID_CHILDREN_EXIST';
   L_child                ITEM_MASTER.ITEM%TYPE := NULL;

BEGIN
   /* Initialize output variables */
   O_error_message := NULL;
   O_exist := NULL;

   open C_CHILDREN;
   fetch C_CHILDREN into L_child;
   close C_CHILDREN;
   ---
   if L_child is not NULL then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      return FALSE;

END VALID_CHILDREN_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION CHILD_DIFF_EXISTS (O_error_message  IN OUT VARCHAR2,
                            O_exists         IN OUT  BOOLEAN,
                            I_diff_1         IN     ITEM_MASTER.DIFF_1%TYPE,
                            I_diff_2         IN     ITEM_MASTER.DIFF_2%TYPE,
                            I_diff_3         IN     ITEM_MASTER.DIFF_3%TYPE,
                            I_diff_4         IN     ITEM_MASTER.DIFF_4%TYPE,
                            I_item           IN     ITEM_MASTER.ITEM%TYPE,
                            I_diff_cnt       IN     NUMBER)
RETURN BOOLEAN IS

L_program    VARCHAR2(64)    := 'ITEM_VALIDATE_SQL.CHILD_DIFF_EXISTS';
L_dummy      VARCHAR2(1);


cursor C_EXISTS4 IS
      select 'Y'
        from item_master
       where (item_parent = I_item
       or item_grandparent = I_item)
       and diff_1 = I_diff_1
       and diff_2 = I_diff_2
       and diff_3 = I_diff_3
       and diff_4 = I_diff_4
       and rownum = 1;  --- added as result of API tkprof for XITEM API performance

cursor C_EXISTS3 IS
      select 'Y'
        from item_master
       where (item_parent = I_item
       or item_grandparent = I_item)
       and diff_1 = I_diff_1
       and diff_2 = I_diff_2
       and diff_3 = I_diff_3
       and rownum = 1;

cursor C_EXISTS2 IS
      select 'Y'
        from item_master
       where (item_parent = I_item
       or item_grandparent = I_item)
       and diff_1 = I_diff_1
       and diff_2 = I_diff_2
       and rownum = 1;

cursor C_EXISTS1 IS
      select 'Y'
        from item_master
       where (item_parent = I_item
       or item_grandparent = I_item)
       and diff_1 = I_diff_1
       and rownum = 1;

BEGIN
   ---
   if I_item is NULL or I_diff_cnt is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_item,I_diff_cnt','NULL','NOT NULL');
      RETURN FALSE;
   end if;
   if I_diff_1 is NULL then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_diff_1','NULL','NOT NULL');
      RETURN FALSE;
   end if;
   if I_diff_2 is NULL and I_diff_cnt > 1 then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_diff_2','NULL','NOT NULL');
      RETURN FALSE;
   end if;
   if I_diff_3 is NULL and I_diff_cnt > 2 then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_diff_3','NULL','NOT NULL');
      RETURN FALSE;
   end if;
   if I_diff_4 is NULL and I_diff_cnt > 3 then
      O_error_message:= SQL_LIB.CREATE_MSG('INVALID_PARM','I_diff_4','NULL','NOT NULL');
      RETURN FALSE;
   end if;

   if I_diff_cnt = 4 then
      SQL_LIB.SET_MARK('OPEN', 'C_EXISTS4','ITEM_MASTER','Item: '||I_item);
      open C_EXISTS4;
      SQL_LIB.SET_MARK('FETCH', 'C_EXISTS4','ITEM_MASTER','Item: '||I_item);
      fetch C_EXISTS4 into L_dummy;
      if C_EXISTS4%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_EXITS4','ITEM_MASTER','Item: '||I_item);
      close C_EXISTS4;
   elsif I_diff_cnt = 3 then
      SQL_LIB.SET_MARK('OPEN', 'C_EXISTS3','ITEM_MASTER','Item: '||I_item);
      open C_EXISTS3;
      SQL_LIB.SET_MARK('FETCH', 'C_EXISTS3','ITEM_MASTER','Item: '||I_item);
      fetch C_EXISTS3 into L_dummy;
      if C_EXISTS3%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_EXITS3','ITEM_MASTER','Item: '||I_item);
      close C_EXISTS3;
   elsif I_diff_cnt = 2 then
      SQL_LIB.SET_MARK('OPEN', 'C_EXISTS2','ITEM_MASTER','Item: '||I_item);
      open C_EXISTS2;
      SQL_LIB.SET_MARK('FETCH', 'C_EXISTS2','ITEM_MASTER','Item: '||I_item);
      fetch C_EXISTS2 into L_dummy;
      if C_EXISTS2%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_EXITS2','ITEM_MASTER','Item: '||I_item);
      close C_EXISTS2;
   elsif I_diff_cnt = 1 then
      SQL_LIB.SET_MARK('OPEN', 'C_EXISTS','ITEM_MASTER','Item: '||I_item);
      open C_EXISTS1;
      SQL_LIB.SET_MARK('FETCH', 'C_EXISTS','ITEM_MASTER','Item: '||I_item);
      fetch C_EXISTS1 into L_dummy;
      if C_EXISTS1%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_EXITS1','ITEM_MASTER','Item: '||I_item);
      close C_EXISTS1;
   end if;

  RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                        SQLERRM,
                        L_program,
                        NULL);
   RETURN FALSE;
END CHILD_DIFF_EXISTS;

---------------------------------------------------------------------------------------------
FUNCTION CHECK_STATUS(O_error_message IN OUT VARCHAR2,
                      O_exists        IN OUT BOOLEAN,
                      I_change_type   IN     VARCHAR2,
                      I_supplier      IN     SUPS.SUPPLIER%TYPE,
                      I_item_parent   IN     ITEM_MASTER.ITEM_PARENT%TYPE,
                      I_diff_group_id IN     DIFF_GROUP_DETAIL.DIFF_GROUP_ID%TYPE,
                      I_diff_id       IN     DIFF_GROUP_DETAIL.DIFF_ID%TYPE)
RETURN BOOLEAN IS

   L_item    ITEM_MASTER.ITEM%TYPE := NULL;
   L_program VARCHAR2(40) := 'ITEM_VALIDATE_SQL.CHECK_STATUS';

   cursor C_APPROVED_ITEM_NO_DIFF is
   select im.item
    from item_master im,
          item_supplier isupp
    where im.status NOT IN ('W',decode(I_change_type,'R','S','W'))
      and im.item = isupp.item
      and (   isupp.supplier    = I_supplier
           or I_supplier is null )
      and im.item_parent    = I_item_parent
      and exists (select '1'
                    from diff_group_detail
                   where diff_id in (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
                     and diff_group_id=I_diff_group_id)
      and rownum = 1;

   cursor C_APPROVED_ITEM_WITH_DIFF is
   select im.item
     from item_master im,
          item_supplier isupp
    where im.status NOT IN ('W',decode(I_change_type,'R','S','W'))
      and im.item = isupp.item
      and (   isupp.supplier    = I_supplier
           or I_supplier is null )
      and im.item_parent    = I_item_parent
      and I_diff_id in (im.diff_1,im.diff_2,im.diff_3,im.diff_4)
      and rownum = 1;

BEGIN
   --
   -- Validate that input parameters all have values
   --
   if I_diff_id is NULL then
      SQL_LIB.SET_MARK('OPEN','C_APPROVED_ITEM_NO_DIFF','ITEM_MASTER',NULL);
      open C_APPROVED_ITEM_NO_DIFF;
      SQL_LIB.SET_MARK('FETCH','C_APPROVED_ITEM_NO_DIFF','ITEM_MASTER',NULL);
      fetch C_APPROVED_ITEM_NO_DIFF into L_item;
      SQL_LIB.SET_MARK('CLOSE','C_APPROVED_ITEM_NO_DIFF','ITEM_MASTER',NULL);
      close C_APPROVED_ITEM_NO_DIFF;
   else
      SQL_LIB.SET_MARK('OPEN','C_APPROVED_ITEM_WITH_DIFF','ITEM_MASTER',NULL);
      open C_APPROVED_ITEM_WITH_DIFF;
      SQL_LIB.SET_MARK('FETCH','C_APPROVED_ITEM_WITH_DIFF','ITEM_MASTER',NULL);
      fetch C_APPROVED_ITEM_WITH_DIFF into L_item;
      SQL_LIB.SET_MARK('CLOSE','C_APPROVED_ITEM_WITH_DIFF','ITEM_MASTER',NULL);
      close C_APPROVED_ITEM_WITH_DIFF;
   end if;
   if L_item is NOT NULL then
       O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      if C_APPROVED_ITEM_NO_DIFF%ISOPEN then
          close C_APPROVED_ITEM_NO_DIFF;
       end if;
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              to_char(SQLCODE));
      return FALSE;
END;
-----------------------------------------------------------------------------------

FUNCTION VALIDATE_RPM_ZONE (O_error_message         IN OUT  VARCHAR2,
                            O_zone_id               IN OUT  ITEM_ZONE_PRICE.ZONE_ID%TYPE,
                            O_zone_desc             IN OUT  PRICE_ZONE.DESCRIPTION%TYPE,
                            O_currency_code         IN OUT  CURRENCIES.CURRENCY_CODE%TYPE,
                            O_exists                IN OUT  VARCHAR2,
                            I_rpm_display_zone_id   IN      ITEM_ZONE_PRICE.ZONE_ID%TYPE)
return BOOLEAN IS

   cursor C_CHECK_GTT_ZONE_INFO is
      select zone_id,
             zone_desc,
             currency_code
        from gtt_zone_info
       where zone_display_id = I_rpm_display_zone_id
         and rownum = 1;

   L_program        VARCHAR2(64) := 'ITEM_VALIDATE_SQL.VALIDATE_RPM_ZONE';
   L_zone_id        ITEM_ZONE_PRICE.ZONE_ID%TYPE;
   L_zone_desc      PRICE_ZONE.DESCRIPTION%TYPE;
   L_currency_code  CURRENCIES.CURRENCY_CODE%TYPE;

BEGIN
   ---
   O_exists := 'N';
   if I_rpm_display_zone_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_rpm_display_zone_id',
                                            'ITEM_VALIDATE_SQL.VALIDATE_RPM_ZONE',
                                            'NULL');
      return FALSE;
   end if;
   --
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_GTT_ZONE_INFO',
                    'GTT_ZONE_INFO',
                    'zone_display_id: '||TO_CHAR(I_rpm_display_zone_id));
   open C_CHECK_GTT_ZONE_INFO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_GTT_ZONE_INFO',
                    'GTT_ZONE_INFO',
                    'zone_display_id: '||TO_CHAR(I_rpm_display_zone_id));
   fetch C_CHECK_GTT_ZONE_INFO into L_zone_id,
                                    L_zone_desc,
                                    L_currency_code;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_GTT_ZONE_INFO',
                    'GTT_ZONE_INFO',
                    'zone_display_id: '||TO_CHAR(I_rpm_display_zone_id));
   close C_CHECK_GTT_ZONE_INFO;

   if L_zone_id is NOT NULL then
      O_exists := 'Y';
      O_zone_id       := L_zone_id;
      O_zone_desc     := L_zone_desc;
      O_currency_code := L_currency_code;
   end if;

   return TRUE;
   ---

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END VALIDATE_RPM_ZONE;
-----------------------------------------------------------------------------------
FUNCTION CHECK_CHILD_STATUS(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_exists             IN OUT   BOOLEAN,
                            I_item               IN       ITEM_MASTER.ITEM%TYPE,
                            I_chk_grndchld_ind   IN       VARCHAR2)
RETURN BOOLEAN IS

   L_exists     VARCHAR2(1)  := NULL;
   L_program    VARCHAR2(40) := 'ITEM_VALIDATE_SQL.CHECK_CHILD_STATUS';


   cursor C_WORKSHEET_CHILD IS
      select 'x'
        from item_master
       where status      = 'W'
         and item_parent = I_item
         and rownum      = 1;

   cursor C_WKSHT_GRANDCHLD IS
      select 'x'
        from item_master
       where status           = 'W'
         and (item_parent     = I_item
          or item_grandparent = I_item)
         and rownum           = 1;

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG',
                                            L_program,
                                            'I_item',
                                            'NULL');
      return FALSE;
   end if;
   ---
   if I_chk_grndchld_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG',
                                            L_program,
                                            'I_chk_grndchld_ind',
                                            'NULL');
      return FALSE;
   end if;
   ---
   if I_chk_grndchld_ind = 'N' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_WORKSHEET_CHILD',
                       'ITEM_MASTER',
                       NULL);
      open C_WORKSHEET_CHILD;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_WORKSHEET_CHILD',
                       'ITEM_MASTER',
                       NULL);
      fetch C_WORKSHEET_CHILD INTO L_exists;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_WORKSHEET_CHILD',
                       'ITEM_MASTER',
                       NULL);
      close C_WORKSHEET_CHILD;
   elsif I_chk_grndchld_ind = 'Y' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_WKSHT_GRANDCHLD',
                       'ITEM_MASTER',
                       NULL);
      open C_WKSHT_GRANDCHLD;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_WKSHT_GRANDCHLD',
                       'ITEM_MASTER',
                       NULL);
      fetch C_WKSHT_GRANDCHLD INTO L_exists;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_WKSHT_GRANDCHLD',
                       'ITEM_MASTER',
                       NULL);
      close C_WKSHT_GRANDCHLD;
   end if;
   ---
   if L_exists IS NULL THEN
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   return TRUE;

EXCEPTION
   WHEN OTHERS THEN
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_CHILD_STATUS;
-----------------------------------------------------------------------------------
FUNCTION ITEMLOC_FILTER_LIST(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_diff_ind        IN OUT VARCHAR2,
                             I_item            IN     ITEM_LOC.ITEM%TYPE,
                             I_group_type      IN     CODE_DETAIL.CODE%TYPE,
                             I_group_id        IN     PARTNER.PARTNER_ID%TYPE)
RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'ITEM_VALIDATE_SQL.ITEMLOC_FILTER_LIST';
   L_total_itemloc   NUMBER(6) := 0;
   L_access_itemloc  NUMBER(6) := 0;

   cursor C_total_itemloc is
      select count(*)
        from item_loc
       where item = I_item;

   cursor C_access_itemloc is
      select count(*)
        from item_loc
       where item = I_item
         and (exists (select 'x'
                        from v_store
                       where store = loc
                         and rownum = 1)
              or exists (select 'x'
                           from v_wh
                          where wh = loc
                            and stockholding_ind = 'Y'
                            and rownum = 1)
              or exists (select 'x'
                           from v_internal_finisher
                          where finisher_id = loc
                            and rownum = 1)
              or exists (select 'x'
                           from v_external_finisher
                          where finisher_id = loc
                            and rownum = 1));

   cursor C_total_item_st is
      select count(*)
        from item_loc il,
             store s,
             district d,
             region r
       where il.loc = s.store
         and d.district = s.district
         and d.region = r.region
         and il.item = I_item
         and ((I_group_type = 'A'
               and r.area = I_group_id)
              or (I_group_type = 'R'
                  and d.region = I_group_id)
              or (I_group_type = 'D'
                  and s.district = I_group_id)
              or I_group_type = 'AS'
              or (I_group_type = 'C'
                  and s.store_class = I_group_id)
              or (I_group_type = 'T'
                  and s.transfer_zone = I_group_id));

   cursor C_access_item_st is
      select count(*)
        from item_loc il,
             v_store vs
       where il.item = I_item
         and il.loc_type = 'S'
         and il.loc = vs.store
         and ((I_group_type = 'R'
               and vs.region = I_group_id)
              or (I_group_type = 'A'
                  and vs.area = I_group_id)
              or (I_group_type = 'D'
                  and vs.district = I_group_id)
              or I_group_type = 'AS'
              or (I_group_type = 'C'
                  and vs.store_class = I_group_id)
              or (I_group_type = 'DW'
                  and vs.default_wh = I_group_id)
              or (I_group_type = 'S'
                  and il.loc = I_group_id)
              or (I_group_type = 'T'
                  and vs.transfer_zone = I_group_id));

   cursor C_total_lls is
      select count(*)
        from item_loc il,
             loc_list_detail lld
       where il.loc = lld.location
         and lld.loc_type = 'S'
         and il.item = I_item
         and lld.loc_list = I_group_id;

   cursor C_access_lls is
      select count(*)
        from item_loc il,
             loc_list_detail lld,
             v_store vs
       where lld.loc_type = 'S'
         and il.loc = lld.location
         and il.loc = vs.store
         and il.item = I_item
         and lld.loc_list = I_group_id;

   cursor C_total_llw is
      select count(*)
        from item_loc il,
             loc_list_detail lld,
             wh
       where il.loc = lld.location
         and lld.location = wh.wh
         and wh.stockholding_ind = 'Y'
         and il.item = I_item
         and lld.loc_list = I_group_id;

   cursor C_access_llw is
      select count(*)
        from item_loc il,
             loc_list_detail lld,
             v_wh vwh
       where il.loc = lld.location
         and il.loc = vwh.wh
         and vwh.stockholding_ind = 'Y'
         and il.item = I_item
         and lld.loc_list = I_group_id;

   cursor C_total_pzgs is
      select count(*)
        from item_loc il,
             price_zone_group_store pzgs
       where il.item = I_item
         and pzgs.store = il.loc
         and pzgs.zone_id = I_group_id;

   cursor C_access_pzgs is
      select count(*)
        from item_loc il,
             price_zone_group_store pzgs,
             v_store vs
       where il.item = I_item
         and pzgs.store = il.loc
         and il.loc = vs.store
         and pzgs.zone_id = I_group_id;

   cursor C_total_wh is
      select count(*)
        from item_loc il,
             wh
       where il.loc = wh.wh
         and il.item = I_item
         and wh.finisher_ind = 'N'
         and wh.stockholding_ind = 'Y'
         and (I_group_type = 'AW'
              or (I_group_type = 'W'
                  and il.loc = I_group_id));

   cursor C_access_wh is
      select count(*)
        from item_loc il,
             v_wh wh
       where il.loc = wh.wh
         and il.item = I_item
         and wh.stockholding_ind = 'Y'
         and (I_group_type = 'AW'
              or (I_group_type = 'W'
                  and il.loc = I_group_id));

   cursor C_total_int_finisher is
      select count(*)
        from item_loc il,
             wh
       where il.loc = wh.wh
         and il.item = I_item
         and wh.finisher_ind = 'Y'
         and wh.stockholding_ind = 'Y'
         and (I_group_type = 'AI'
              or (I_group_type = 'I'
                  and il.loc = I_group_id));

   cursor C_access_int_finisher is
      select count(*)
        from item_loc il,
             v_internal_finisher vif
       where il.loc = vif.finisher_id
         and il.item = I_item
         and (I_group_type = 'AI'
              or (I_group_type = 'I'
                  and il.loc = I_group_id));

   cursor C_total_ext_finisher is
      select count(*)
        from item_loc il,
             partner p
       where il.loc = p.partner_id
         and p.partner_type = 'E'
         and il.item = I_item
         and (I_group_type = 'AE'
              or (I_group_type = 'E'
                  and il.loc = I_group_id));

   cursor C_access_ext_finisher is
      select count(*)
        from item_loc il,
             v_external_finisher vef
       where il.loc = vef.finisher_id
         and il.loc_type = 'E'
         and il.item = I_item
         and (I_group_type = 'AE'
              or (I_group_type = 'E'
                  and il.loc = I_group_id));

   cursor C_total_pw is
      select count(*)
        from item_loc il,
             wh
       where il.loc = wh.wh
         and wh.stockholding_ind = 'Y'
         and wh.finisher_ind = 'N'
         and wh.physical_wh = I_group_id
         and il.item = I_item;

   cursor C_access_pw is
      select count(*) cnt
        from item_loc il,
             v_wh wh
       where il.loc = wh.wh
         and wh.stockholding_ind = 'Y'
         and il.item = I_item
         and wh.physical_wh = I_group_id;

   cursor C_total_loc_traits is
      select count(*)
        from item_loc il,
             loc_traits_matrix ltm
       where il.loc = ltm.store
         and il.item = I_item
         and ltm.loc_trait = I_group_id;

   cursor C_access_loc_traits is
      select count(*)
        from item_loc il,
             v_loc_traits vlt,
             loc_traits_matrix ltm,
             v_store vs
       where il.loc = ltm.store
         and ltm.store = vs.store
         and vlt.loc_trait = ltm.loc_trait
         and il.item = I_item
         and ltm.loc_trait = I_group_id;

   cursor C_total_item_st_s is
      select count(*)
        from item_loc il,
             store s
       where il.loc = s.store
         and il.item = I_item
         and il.loc = I_group_id;

   cursor C_total_item_st_w is
   select count(*)
     from item_loc il,
          store s
    where il.loc = s.store
      and il.item = I_item
      and s.default_wh = I_group_id;
BEGIN
   ---
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_group_type = 'AL' or I_group_type is NULL then
      ---
      open C_total_itemloc;
      fetch C_total_itemloc into L_total_itemloc;
      close C_total_itemloc;
      ---
      open C_access_itemloc;
      fetch C_access_itemloc into L_access_itemloc;
      close C_access_itemloc;
      ---
   elsif I_group_type in ('A','R','D','AS', 'C', 'DW', 'S', 'T', 'P') then
      ---
      if I_group_type = 'S' then
               ---
                     open C_total_item_st_s;
                     fetch C_total_item_st_s into L_total_itemloc;
                     close C_total_item_st_s;
               ---
      elsif I_group_type = 'DW' then
         ---
               open C_total_item_st_w;
               fetch C_total_item_st_w into L_total_itemloc;
               close C_total_item_st_w;
         ---
      else
               open C_total_item_st;
               fetch C_total_item_st into L_total_itemloc;
               close C_total_item_st;
      end if;
      ---
      open C_access_item_st;
      fetch C_access_item_st into L_access_itemloc;
      close C_access_item_st;
      ---
   elsif I_group_type = 'PW' then
      ---
      open C_total_pw;
      fetch C_total_pw into L_total_itemloc;
      close C_total_pw;
      ---
      open C_access_pw;
      fetch C_access_pw into L_access_itemloc;
      close C_access_pw;
      ---
   elsif I_group_type = 'LLS' then
      ---
      open C_total_lls;
      fetch C_total_lls into L_total_itemloc;
      close C_total_lls;
      ---
      open C_access_lls;
      fetch C_access_lls into L_access_itemloc;
      close C_access_lls;
      ---
   elsif I_group_type = 'LLW' then
      ---
      open C_total_llw;
      fetch C_total_llw into L_total_itemloc;
      close C_total_llw;
      ---
      open C_access_llw;
      fetch C_access_llw into L_access_itemloc;
      close C_access_llw;
      ---
   elsif I_group_type in ('AW','W') then
      ---
      open C_total_wh;
      fetch C_total_wh into L_total_itemloc;
      close C_total_wh;
      ---
      open C_access_wh;
      fetch C_access_wh into L_access_itemloc;
      close C_access_wh;
      ---
   elsif I_group_type in ('AI', 'I') then
      ---
      open C_total_int_finisher;
      fetch C_total_int_finisher into L_total_itemloc;
      close C_total_int_finisher;
      ---
      open C_access_int_finisher;
      fetch C_access_int_finisher into L_access_itemloc;
      close C_access_int_finisher;
      ---
   elsif I_group_type in ('AE', 'E') then
      ---
      open C_total_ext_finisher;
      fetch C_total_ext_finisher into L_total_itemloc;
      close C_total_ext_finisher;
      ---
      open C_access_ext_finisher;
      fetch C_access_ext_finisher into L_access_itemloc;
      close C_access_ext_finisher;
      ---
   elsif I_group_type = 'Z' then
      ---
      open C_total_pzgs;
      fetch C_total_pzgs into L_total_itemloc;
      close C_total_pzgs;
      ---
      open C_access_pzgs;
      fetch C_access_pzgs into L_access_itemloc;
      close C_access_pzgs;
      ---
   elsif I_group_type = 'L' then
      ---
      open C_total_loc_traits;
      fetch C_total_loc_traits into L_total_itemloc;
      close C_total_loc_traits;
      ---
      open C_access_loc_traits;
      fetch C_access_loc_traits into L_access_itemloc;
      close C_access_loc_traits;
      ---
   end if;

   if L_total_itemloc != L_access_itemloc then
      O_diff_ind := 'Y';
   else
      O_diff_ind := 'N';
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
   RETURN FALSE;

END ITEMLOC_FILTER_LIST;
-----------------------------------------------------------------------------------------
-- 27-Sep-2007 Govindarajan - MOD N20a Begin
-----------------------------------------------------------------------------------------
-- Function Name : TSL_CHILD_GCHILD_APPROVE_EXIST
-- Purpose       : Checks if any Approved items exist with the entered item as a
--                 parent or grandparent.
---------------------------------------------------------------------------------------------
FUNCTION TSL_CHILD_GCHILD_APPROVE_EXIST (O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                         O_child          IN OUT BOOLEAN,
                                         O_gchild         IN OUT BOOLEAN,
                                         I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is
   L_program        VARCHAR2(300) := 'ITEM_VALIDATE_SQL.TSL_CHILD_GCHILD_APPROVE_EXIST';
   L_gchild         VARCHAR2(1);
   L_child          VARCHAR2(1);

   -- This cursor will validate if the passed Item is the
   -- grandparent of any Approved Item
   cursor C_GRANDPARENT is
   select 'x'
     from item_master im
    where im.item_grandparent  = I_item
      and im.status            = 'A';

   -- This cursor will validate if the passed Item is the
   -- parent of any Approved Item
   cursor C_PARENT is
   select 'x'
     from item_master im
    where im.item_parent = I_item
      and im.status      = 'A';
BEGIN
  if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'ITEM : '||I_item,
                                             L_program,
                                             NULL);
      return FALSE;
  end if;

  O_error_message := NULL;
  O_gchild := NULL;
  O_child := NULL;

  SQL_LIB.SET_MARK('OPEN',
                   'C_GRANDPARENT',
                   'ITEM_MASTER',
                   'ITEM: ' ||I_item);
  open C_GRANDPARENT;

  SQL_LIB.SET_MARK('FETCH',
                   'C_GRANDPARENT',
                   'ITEM_MASTER',
                   'ITEM: ' ||I_item);
  fetch C_GRANDPARENT into L_gchild;

  SQL_LIB.SET_MARK('CLOSE',
                   'C_GRANDPARENT',
                   'ITEM_MASTER',
                   'ITEM: ' ||I_item);
  close C_GRANDPARENT;


  if L_gchild is NOT NULL then
    O_child := TRUE;
    O_gchild := TRUE;
  else
    O_gchild := FALSE;

    SQL_LIB.SET_MARK('OPEN',
                     'C_PARENT',
                     'ITEM_MASTER',
                     'ITEM: ' ||I_item);
    open C_PARENT;

    SQL_LIB.SET_MARK('FETCH',
                     'C_PARENT',
                     'ITEM_MASTER',
                     'ITEM: ' ||I_item);
    fetch C_PARENT into L_child;

    SQL_LIB.SET_MARK('CLOSE',
                     'C_PARENT',
                     'ITEM_MASTER',
                     'ITEM: ' ||I_item);
    close C_PARENT;

    if L_child is NOT NULL then
      O_child := TRUE;
    else
      O_child := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('ITEM_NO_CHILD',
                                             NULL,
                                             NULL,
                                             NULL);
    end if;
  end if;
  return TRUE;
EXCEPTION
  when OTHERS then
    --To check whether the cursor is closed or not
    if C_GRANDPARENT%ISOPEN then
       SQL_LIB.SET_MARK('CLOSE',
                        'C_GRANDPARENT',
                        'ITEM_MASTER',
                        'ITEM: ' || I_item);
       close C_GRANDPARENT;
    end if;
    ---
    if C_PARENT%ISOPEN then
       SQL_LIB.SET_MARK('CLOSE',
                        'C_PARENT',
                        'ITEM_MASTER',
                        'ITEM: ' || I_item);
       close C_PARENT;
    end if;
    ---
    O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           L_program,
                                           TO_CHAR(SQLCODE));
    return FALSE;
END TSL_CHILD_GCHILD_APPROVE_EXIST;
---------------------------------------------------------------------------------------------
-- 27-Sep-2007 Govindarajan - MOD N20a end
---------------------------------------------------------------------------------------------
-- Function : TSL_BARCODE_CHECK
-- Purpose  : This function will check if the selected Non-Tesco Brand EAN/UCC-13 already is
--            already in use in other ORMS instance.
---------------------------------------------------------------------------------------------
-- Defect Id:- NBS00008966, 08-Sep-2008, Nitin Kumar, nitin.kumar@in.tesco.com, Begin
---------------------------------------------------------------------------------------------
--Mod By     : Nitin Kumar, nitin.kumar@in.tesco.com
--Mod Date   : 08-Sep-2008
--Mod Details: Modiifed the function TSL_BARCODE_CHECK
----------------------------------------------------------------------------------------------
-- Modified by : Nitin Kumar, nitin.kumar@in.tesco.com
-- Date        : 20-July-2009
-- Defect Id   : NBS00013905
-- Desc        : Modified function TSL_BARCODE_CHECK
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_BARCODE_CHECK(O_error_message       IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exists              IN OUT BOOLEAN,
                           I_item_no             IN     ITEM_MASTER.ITEM%TYPE,
                           I_item_no_type        IN     VARCHAR2)
   RETURN BOOLEAN is

   -- User defined exceptions
   E_BARCODE             EXCEPTION;
   --
   L_program             VARCHAR2(300) := 'ITEM_VALIDATE_SQL.TSL_BARCODE_CHECK';
   L_req                 TSL_WEB_SERVICE_SQL.TSL_REQUEST_REC;
   L_resp                TSL_WEB_SERVICE_SQL.TSL_RESPONSE_REC;
   L_docelem             xmldom.DOMElement;
   L_elem                xmldom.DOMElement;
   L_nodelist            xmldom.DOMNodelist;
   L_sys_opt_val         SYSTEM_OPTIONS%ROWTYPE;
   O_resp                TSL_WEB_SERVICE_SQL.TSL_RESPONSE_REC;
   L_barcode_exists_ind  VARCHAR2(1);

BEGIN
   -- Check if input parameters if they are NULL
   if ((I_item_no is NULL) or (I_item_no_type is NULL)) then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            NULL,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;


   -- Fetch the value from system_options table
   if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS (O_error_message,
                                             L_sys_opt_val) = FALSE then
      return FALSE;
   end if;

   --30-Jun-2010   nandini.mariyappa@in.tesco.com   DefNBS018045  Begin
   --Removed following check as single instance still need to use the Barcode service to
   --prevent the shared use of supplier branded barcodes

   -- START of request to Barocode Check Web Service for checking if used number exists in other instance
   if TSL_WEB_SERVICE_SQL.NEW_REQUEST(O_error_message,
                                      L_req,
                                      L_sys_opt_val.TSL_BARCODE_REQ_METHOD,
                                      L_sys_opt_val.TSL_BARCODE_NS) = FALSE then
      return FALSE;
   end if;

   -- Start the Complex Parameter
   TSL_WEB_SERVICE_SQL.ADD_COMPLEX_PARAMETER(O_error_message,
                                             L_req,
                                             'CheckBarcodeRequest');
   if O_error_message is NOT NULL then
      return FALSE;
   end if;

   -- Set the UserId
   TSL_WEB_SERVICE_SQL.ADD_PARAMETER(O_error_message,
                                     L_req,
                                     'UserId',
                                     NULL,
                                     L_sys_opt_val.TSL_BARCODE_USER_ID);

   if O_error_message is NOT NULL then
      return FALSE;
   end if;

   -- Set the Application ID type
   TSL_WEB_SERVICE_SQL.ADD_PARAMETER(O_error_message,
                                     L_req,
                                     'ApplicationId',
                                     NULL,
                                     L_sys_opt_val.TSL_BARCODE_APPLN_ID);

   if O_error_message is NOT NULL then
      return FALSE;
   end if;


   -- Set the item number to be sent for checking
   TSL_WEB_SERVICE_SQL.ADD_PARAMETER(O_error_message,
                                     L_req,
                                     'ItemNumber',
                                     NULL,
                                     I_item_no);

   if O_error_message is NOT NULL then
      return FALSE;
   end if;

   -- Set the item number type to be sent for checking
   TSL_WEB_SERVICE_SQL.ADD_PARAMETER(O_error_message,
                                     L_req,
                                     'ItemNumberType',
                                     NULL,
                                     I_item_no_type);

   if O_error_message is NOT NULL then
      return FALSE;
   end if;

   -- Close the Complex Parameter
   TSL_WEB_SERVICE_SQL.END_COMPLEX_PARAMETER(O_error_message,
                                             L_req,
                                             'CheckBarcodeRequest');
   if O_error_message is NOT NULL then
      return FALSE;
   end if;

   -- Invoke the Barcode Check web service for EAN/OCC Check
   -- UAT Defect NBS00013905, 16-July-2009, Nitin Kumar, nitin.kumar@in.tesco.com Begin
   -- TSL_WEB_SERVICE_SQL.INVOKE(O_error_message,
   TSL_WEB_SERVICE_SQL.INVOKE_BARCODE_CHECK(O_error_message,
   -- UAT Defect NBS00013905, 16-July-2009, Nitin Kumar, nitin.kumar@in.tesco.com End
                                            L_req,
                                            L_sys_opt_val.TSL_BARCODE_URL,
                                            GP_barcode_action,
                                            L_resp);

   if O_error_message is NOT NULL then
      return FALSE;
   end if;

   -- Start of processing return message from Barcode Check Web service
   if  TSL_WEB_SERVICE_SQL.GET_SUB_DOCUMENT(O_error_message,
                                            O_resp,
                                            L_resp,
                                            '/CheckBarcodeExistsResponse/CheckBarcodeExistsResult/Status',
                                            L_sys_opt_val.TSL_BARCODE_NS) = FALSE then
      return FALSE;
   end if;

   -- Parse the sub document to get return/error code from Barocode Web Service
   L_docelem  := rib_xml.readroot(O_resp.doc.getStringVal,'CheckBarcodeExistsResponse',FALSE,TRUE,FALSE);
   L_nodelist := rib_xml.getChildren(L_docelem,'Code');
   L_elem     := rib_xml.getListElement(L_nodelist,0);


   if NOT (rib_xml.isNULL(L_elem)) then
      -- If there was an error in reponse,attempt to get error description from Barcode Check Web Service,
      -- otherwise use default error
      if rib_xml.getText(L_elem) <> '0' then
         L_nodelist := rib_xml.getChildren(L_docelem,'Description');
         L_elem     := rib_xml.getListElement(L_nodelist,0);
         if NOT (rib_xml.isNULL(L_elem)) then
            O_error_message := rib_xml.getText(L_elem) || ' : ' ||
                               SQL_LIB.GET_MESSAGE_TEXT('TSL_BARCODE_WEBSERVICE',
                                                        I_item_no,
                                                        NULL,
                                                        NULL);
         else
            O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_BARCODE_WEBSERVICE',
                                                        I_item_no_type,
                                                        NULL,
                                                        NULL);
         end if;
         return FALSE;
      else -- There is No error in Barcode web Service Response
         -- Check Whether the barcode exists in other instance or not.
         if  TSL_WEB_SERVICE_SQL.GET_SUB_DOCUMENT(O_error_message,
                                                  O_resp,
                                                  L_resp,
                                                  '/CheckBarcodeExistsResponse/CheckBarcodeExistsResult',
                                                  L_sys_opt_val.TSL_BARCODE_NS) = FALSE then
            return FALSE;
         end if;

         L_docelem  := rib_xml.readroot(O_resp.doc.getStringVal,'CheckBarcodeExistsResponse',FALSE,TRUE,FALSE);
         L_nodelist := rib_xml.getChildren(L_docelem,'BarcodeExistsInd');
         L_elem     := rib_xml.getListElement(L_nodelist,0);
         if NOT (rib_xml.isNULL(L_elem)) then
            L_barcode_exists_ind := rib_xml.getText(L_elem);
            --Check the Barcode Exists Indicator
            if L_barcode_exists_ind = 'Y' then
               O_exists := TRUE;
            else
               O_exists := FALSE;
            end if;
         else
            raise E_BARCODE;
         end if;
      end if;
   else
      raise E_BARCODE;
   end if;
   --30-Jun-2010   nandini.mariyappa@in.tesco.com   DefNBS018045   End

   return TRUE;

EXCEPTION
   when E_BARCODE then
      O_error_message := SQL_LIB.GET_MESSAGE_TEXT('TSL_BARCODE_WEBSERVICE',
                                                  I_item_no,
                                                  NULL,
                                                  NULL);

      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
     return FALSE;

END TSL_BARCODE_CHECK;
---------------------------------------------------------------------------------------------
-- Defect Id:- NBS00008966, 08-Sep-2008, Nitin Kumar, nitin.kumar@in.tesco.com, End
---------------------------------------------------------------------------------------------
-- DefNBS007055, 13-Jun-2008, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
-----------------------------------------------------------------------------------------
-- Function Name : TSL_EXIST
-- Purpose       : To validate Item information into TSL_AUTO_GENERATE_TEMP table
-----------------------------------------------------------------------------------------
FUNCTION TSL_EXIST (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                    O_exist          IN OUT  BOOLEAN,
                    I_item           IN      ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN is

   L_program     VARCHAR2(64)          := 'ITEM_VALIDATE_SQL.TSL_EXIST';
   L_item        ITEM_MASTER.ITEM%TYPE := NULL;

   cursor C_exist is
   select item_number
     from tsl_auto_generate_temp
    where item_number = I_item;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'c_EXIST',
                    'TSL_AUTO_GENERATE_TEMP',
                    'ITEM_NUMBER: ' || I_item);
   open C_exist;

   SQL_LIB.SET_MARK('FETCH',
                    'c_EXIST',
                    'TSL_AUTO_GENERATE_TEMP',
                    'ITEM_NUMBER: ' || I_item);
   fetch C_exist into L_item;

   SQL_LIB.SET_MARK('CLOSE',
                    'c_EXIST',
                    'TSL_AUTO_GENERATE_TEMP',
                    'ITEM_NUMBER: ' || I_item);
   close C_exist;

   if L_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      O_exist := FALSE;
   else
      O_exist := TRUE;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_EXIST;
-----------------------------------------------------------------------------------------
-- DefNBS007055, 13-Jun-2008, Nitin Gour, nitin.gour@in.tesco.com (END)
-----------------------------------------------------------------------------------------
-- DefNBS010691, 31-Dec-2008, Vinod Kumar,vinod.patalappa@in.tesco.com (BEGIN)
-----------------------------------------------------------------------------------------
-- Procedure Name : TSL_EXIST_PROC
-- Purpose        : To make it easy to fecth the value of O_exist called from the Biztalk.
-----------------------------------------------------------------------------------------
PROCEDURE TSL_EXIST_PROC (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                          O_exist          IN OUT  CHAR,
                          I_item           IN      ITEM_MASTER.ITEM%TYPE) IS
  cursor C_exist is
      select item
        from item_master
       where item = I_item;

   L_program     VARCHAR2(64) := 'ITEM_VALIDATE_SQL.TSL_EXIST_PROC';
   L_item        ITEM_MASTER.ITEM%TYPE := NULL;

BEGIN
   /* Initialize output variables */
   O_error_message := NULL;
   O_exist := NULL;

   open C_exist;
   fetch C_exist
    into L_item;
   close C_exist;
   if L_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('INV_ITEM', NULL, NULL, NULL);
      O_exist := 'N';
   else
      O_exist := 'Y';
   end if;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG
                        ('PACKAGE_ERROR', SQLERRM, L_program, to_char(SQLCODE));
      O_exist := 'N';

END TSL_EXIST_PROC;
-----------------------------------------------------------------------------------------
-- DefNBS010691, 31-Dec-2008, Vinod Kumar,vinod.patalappa@in.tesco.com (END)
-----------------------------------------------------------------------------------------
END ITEM_VALIDATE_SQL;
/

