CREATE OR REPLACE PACKAGE BODY DEAL_VALIDATE_SQL AS
----------------------------------------------------------------------------------------
-- Mod By      : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date    : 09-May-2008
-- Mod Ref     : ModN111
-- Mod Details : Added new function TSL_CHECK_COMMON_PRODUCT.This function will validate
--               if the exists Common Products for the passed Merchandise Hierarchy
--               (does not consider Merch Level 1 and 12).
----------------------------------------------------------------------------------------
-- Mod By      : Kumar/WiproEnabler
-- Mod Date    : 10-Jul-2009
-- Mod Ref     : Patch#8410021 and ST Def#12191
-- Mod Details : Added a new function CHECK_PRICE_CHG_DEAL to validate the existence of
--               vendor funded price changes in RPM which use this VFM deal.
---------------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date     : 18-May-2010
-- Mod Ref      : CR316
-- Mod Details  : Added new functions TSL_INT_CONTACT_EXISTS and TSL_GET_DEAL_CNT
---------------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date     : 31-May-2010
-- Mod Ref      : NBS00017761
-- Mod Details  : Modified TSL_GET_CNT_COST_CENTRE function cursor
---------------------------------------------------------------------------------------
-- Mod By       : Bhargavi Pujari, bharagavi.pujari@in.tesco.com
-- Mod Date     : 03-Jun-2010
-- Mod Ref      : MrgNB07783
-- Mod Details  : Modified TSL_GET_CNT_COST_CENTRE,removed input parameter modified cursor
---------------------------------------------------------------------------------------
FUNCTION DEAL_ID (O_error_message IN OUT VARCHAR2,
                  O_exist         IN OUT BOOLEAN,
                  I_deal_id       IN     deal_head.deal_id%TYPE)
RETURN BOOLEAN IS

   L_found VARCHAR2(1) := 'N';
   cursor C_DEAL_ID is
      select 'Y'
        from deal_head
       where deal_head.deal_id = I_deal_id;

BEGIN
   ---
   SQL_LIB.SET_MARK('OPEN','C_DEAL_ID','deal_head',
                    'deal_id: '||I_deal_id);
   open C_DEAL_ID;
   ---
   SQL_LIB.SET_MARK('FETCH','C_DEAL_ID','deal_head',
                    'deal_id: '||I_deal_id);
   fetch C_DEAL_ID into L_found;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_DEAL_ID','deal_head',
                    'deal_id: '||I_deal_id);
   close C_DEAL_ID;
   ---
   if L_found = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.DEAL_ID',
                                             to_char(SQLCODE));
      RETURN FALSE;
END DEAL_ID;
------------------------------------------------------------
FUNCTION THRESHOLD_OVERLAP(O_error_message   IN OUT VARCHAR2,
                           O_overlap_exists  IN OUT BOOLEAN,
                           I_deal_id         IN     deal_head.deal_id%TYPE,
                           I_deal_detail_id  IN     deal_detail.deal_detail_id%TYPE,
                           I_lower_limit     IN     deal_threshold.lower_limit%TYPE,
                           I_upper_limit     IN     deal_threshold.upper_limit%TYPE,
                           I_row_id          IN     ROWID)
RETURN BOOLEAN IS

   L_found VARCHAR2(1) := 'N';

   cursor C_THRESHOLD is
      select 'Y'
        from deal_threshold
       where deal_threshold.deal_id = I_deal_id
         and deal_threshold.deal_detail_id = I_deal_detail_id
         and not (deal_threshold.lower_limit > I_upper_limit
                  and
                  deal_threshold.lower_limit > I_lower_limit)
         and not (deal_threshold.upper_limit < I_lower_limit
                  and
                  deal_threshold.upper_limit < I_upper_limit)
         and (rowid != I_row_id or I_row_id is NULL);

BEGIN
   ---
   SQL_LIB.SET_MARK('OPEN','C_THRESHOLD','deal_threshold',
                    'deal_id: '||I_deal_id||', deal_detail_id: '||I_deal_detail_id);
   open C_THRESHOLD;
   ---
   SQL_LIB.SET_MARK('FETCH','C_THRESHOLD','deal_threshold',
                    'deal_id: '||I_deal_id||', deal_detail_id: '||I_deal_detail_id);
   fetch C_THRESHOLD into L_found;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_THRESHOLD','deal_threshold',
                    'deal_id: '||I_deal_id||', deal_detail_id: '||I_deal_detail_id);
   close C_THRESHOLD;
   ---
   -- if found, overlap exists
   if L_found = 'Y' then
      O_overlap_exists := TRUE;
   else
      O_overlap_exists := FALSE;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.THRESHOLD_OVERLAP',
                                             to_char(SQLCODE));
      RETURN FALSE;
END THRESHOLD_OVERLAP;
------------------------------------------------------------
FUNCTION VALID_ITEM_SUPP_HIER(O_error_message   IN OUT VARCHAR2,
                              O_exist           IN OUT BOOLEAN,
                              I_item            IN     item_master.item%TYPE,
                              I_partner_type    IN     deal_head.partner_type%TYPE,
                              I_partner_id      IN     deal_head.partner_id%TYPE,
                              I_supplier        IN     sups.supplier%TYPE,
                              I_origin_country  IN     country.country_id%TYPE)
RETURN BOOLEAN IS

   L_found     VARCHAR2(1) := 'N';

   cursor C_ITEM_SUPP_COUNTRY is
      select 'Y'
        from item_supp_country
       where item = I_item
         and (origin_country_id = I_origin_country or I_origin_country is null)
         and (supplier = I_supplier or I_supplier is null)
         and ((I_partner_type = 'S1' and supp_hier_type_1 = 'S1' and supp_hier_lvl_1 = I_partner_id)
              or (I_partner_type = 'S2' and supp_hier_type_2 = 'S2' and supp_hier_lvl_2 = I_partner_id)
              or (I_partner_type = 'S3' and supp_hier_type_3 = 'S3' and supp_hier_lvl_3 = I_partner_id)
              or (I_partner_type = 'S')
              -- 31-Jan-2008   Wipro/JK  Mod N32  Begin
              or (I_partner_type = 'SG'
              and supplier in (select sgd.supplier
                                 from tsl_sups_group_detail sgd
                                where sgd.group_id = I_partner_id ))
              or (I_partner_type ='SH'
              and exists (select tsh.element_id
                            from tsl_sups_hier tsh
                           where tsh.element_id = supplier
                           start with tsh.hier_id = I_partner_id
                         connect by prior tsh.element_id = tsh.parent_element_id)));
              -- 31-Jan-2008   Wipro/JK  Mod N32  End
BEGIN

   SQL_LIB.SET_MARK('OPEN','C_ITEM_SUPP_COUNTRY','item_supp_country',
                   'item: ' || I_item);
   open C_ITEM_SUPP_COUNTRY;
   ---
   SQL_LIB.SET_MARK('FETCH','C_ITEM_SUPP_COUNTRY','item_supp_country',
                    'item: ' || I_item);
   fetch C_ITEM_SUPP_COUNTRY into L_found;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_SUPP_COUNTRY','item_supp_country',
                    'item: ' || I_item);
   close C_ITEM_SUPP_COUNTRY;
   ---
   if L_found = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.VALID_ITEM_SUPP_HIER',
                                             to_char(SQLCODE));
      RETURN FALSE;
END VALID_ITEM_SUPP_HIER;
------------------------------------------------------------
FUNCTION CHK_ACTIVE_DEALS_SUP_HIER(O_error_message       IN OUT VARCHAR2,
                                   O_exist               IN OUT BOOLEAN,
                                   I_item                IN     deal_itemloc.item%TYPE,
                                   I_origin_country_id   IN     deal_itemloc.origin_country_id%TYPE,
                                   I_partner_id          IN     deal_head.partner_id%TYPE,
                                   I_partner_type        IN     deal_head.partner_type%TYPE)
RETURN BOOLEAN IS

   cursor C_DEAL_HEAD is
      select deal_id
        from deal_head
       where partner_type = I_partner_type
         and partner_id = I_partner_id;

   cursor C_DEAL_ITEMLOC(I_deal_id IN deal_head.deal_id%TYPE) is
      select company_ind,
             item,
             merch_level,
             item_parent,
             item_grandparent,
             dept,
             group_no,
             division
        from deal_itemloc
       where deal_id = I_deal_id
         and (item = I_item
              or item is null)
         and (origin_country_id = I_origin_country_id
              or origin_country_id is null);
   ---
   L_item_parent                 item_master.item_parent%TYPE;
   L_item_grandparent            item_master.item_grandparent%TYPE;
   L_dept                        deps.dept%TYPE;
   L_class                       class.class%TYPE;
   L_subclass                    subclass.subclass%TYPE;
   L_group                       groups.group_no%TYPE;
   L_division                    division.division%TYPE;

   ---

   /*Note - the following variables for extra info fetched by a package call.*/
   L_item_parent_desc_dummy       item_master.item_desc%TYPE;
   L_item_grandparent_desc_dummy  item_master.item_desc%TYPE;

BEGIN
   O_exist := FALSE;
   ---
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_sku','NULL','NOT NULL');
      return FALSE;
   elsif I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_origin_country_id','NULL','NOT NULL');
      return FALSE;
   elsif I_partner_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_partner_id','NULL','NOT NULL');
      return FALSE;
   elsif I_partner_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_partner_type','NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   FOR C1 IN C_DEAL_HEAD LOOP
      FOR C2 IN C_DEAL_ITEMLOC(C1.deal_id) LOOP
         if C2.company_ind = 'Y' then
            O_exist := TRUE;
            EXIT;
         end if;
         ---
         if (C2.item = I_item and C2.merch_level = '10') then
            O_exist := TRUE;
            EXIT;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_PARENT_INFO(O_error_message,
                                            L_item_parent,
                                            L_item_parent_desc_dummy,
                                            L_item_grandparent,
                                            L_item_grandparent_desc_dummy,
                                            I_item) = FALSE then
               return FALSE;
         end if;
         ---
         if (((L_item_parent = C2.item_parent) or (L_item_grandparent = C2.item_grandparent))
               and C2.merch_level in ('7', '8', '9')) then
               O_exist := TRUE;
               EXIT;
         end if;
         ---
         if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                           I_item,
                                           L_dept,
                                           L_class,
                                           L_subclass) = FALSE then
            return FALSE;
         end if;
         ---
         if (L_dept = C2.dept and C2.merch_level in ('4', '5', '6')) then
            O_exist := TRUE;
            EXIT;
         end if;
         ---
         if DEPT_ATTRIB_SQL.GET_DEPT_HIER(O_error_message,
                                          L_group,
                                          L_division,
                                          L_dept) = FALSE then
            return FALSE;
         end if;
         ---
         if (L_group = C2.group_no and C2.merch_level = '3') then
            O_exist := TRUE;
            EXIT;
         end if;
         ---
         if (L_division = C2.division and C2.merch_level = '2') then
            O_exist := TRUE;
            EXIT;
         end if;
         ---
      END LOOP;
      EXIT WHEN O_exist;
   END LOOP;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.CHK_ACTIVE_DEALS_SUP_HIER',
                                             to_char(SQLCODE));
      RETURN FALSE;
END CHK_ACTIVE_DEALS_SUP_HIER;
------------------------------------------------------------
FUNCTION CHECK_DELETE_ITEMLOC(O_error_message     IN OUT VARCHAR2,
                              O_exist             IN OUT BOOLEAN,
                              I_deal_id           IN     deal_itemloc.deal_id%TYPE,
                              I_deal_detail_id    IN     deal_itemloc.deal_detail_id%TYPE,
                              I_merch_level       IN     deal_itemloc.merch_level%TYPE,
                              I_company_ind       IN     deal_itemloc.company_ind%TYPE,
                              I_division          IN     deal_itemloc.division%TYPE,
                              I_group             IN     deal_itemloc.group_no%TYPE,
                              I_dept              IN     deal_itemloc.dept%TYPE,
                              I_class             IN     deal_itemloc.class%TYPE,
                              I_subclass          IN     deal_itemloc.subclass%TYPE,
                              I_item_grandparent  IN     deal_itemloc.item_grandparent%TYPE,
                              I_item_parent       IN     deal_itemloc.item_parent%TYPE,
                              I_diff_1            IN     deal_itemloc.diff_1%TYPE,
                              I_diff_2            IN     deal_itemloc.diff_2%TYPE,
                              I_diff_3            IN     deal_itemloc.diff_3%TYPE,
                              I_diff_4            IN     deal_itemloc.diff_4%TYPE,
                              I_item              IN     deal_itemloc.item%TYPE,
                              I_org_level         IN     deal_itemloc.org_level%TYPE,
                              I_chain             IN     deal_itemloc.chain%TYPE,
                              I_area              IN     deal_itemloc.area%TYPE,
                              I_region            IN     deal_itemloc.region%TYPE,
                              I_district          IN     deal_itemloc.district%TYPE,
                              I_location          IN     deal_itemloc.location%TYPE,
                              I_origin_country_id IN     deal_itemloc.origin_country_id%TYPE,
                              I_excl_ind          IN     deal_itemloc.excl_ind%TYPE)
RETURN BOOLEAN IS
   L_exist     VARCHAR2(1) := 'N';
   ---
   cursor C_SUB_ITEMLOC is
      select 'Y'
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and excl_ind = 'Y'
         and (I_merch_level = '1'
              or (I_merch_level = '2' and division = I_division)
              or (I_merch_level = '3' and group_no = I_group)
              or (I_merch_level = '4' and dept = I_dept)
              or (I_merch_level = '5'
                  and dept = I_dept
                  and class = I_class)
              or (I_merch_level = '6'
                  and dept = I_dept
                  and class = I_class
                  and subclass = I_subclass)
              or (I_merch_level = '7'
                  and (item_parent = I_item_parent
                    or item_grandparent = I_item_grandparent))
              or (I_merch_level = '8'
                  and (item_parent = I_item_parent
                   or item_grandparent = I_item_grandparent)
                  and diff_1 = I_diff_1)
              or (I_merch_level = '9'
                  and (item_parent = I_item_parent
                   or item_grandparent = I_item_grandparent)
                  and diff_2 = I_diff_2)
              or (I_merch_level = '10'
                  and (item_parent = I_item_parent
                   or item_grandparent = I_item_grandparent)
                  and diff_3 = I_diff_3)
              or (I_merch_level = '11'
                  and (item_parent = I_item_parent
                   or item_grandparent = I_item_grandparent)
                  and diff_4 = I_diff_4)
              or (I_merch_level = '12' and item = I_item))
         and (I_org_level is NULL
              or (I_org_level = '1' and chain = I_chain)
              or (I_org_level = '2' and area = I_area)
              or (I_org_level = '3' and region = I_region)
              or (I_org_level = '4' and district = I_district)
              or (I_org_level = '5' and location = I_location));

BEGIN
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_id','NULL','NOT NULL');
      return FALSE;
   elsif I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_detail_id','NULL','NOT NULL');
      return FALSE;
   elsif I_excl_ind = 'Y' then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_excl_ind','Y','N');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_SUB_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   open C_SUB_ITEMLOC;
   ---
   SQL_LIB.SET_MARK('FETCH','C_SUB_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   fetch C_SUB_ITEMLOC into L_exist;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_SUB_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   close C_SUB_ITEMLOC;
   ---
   if L_exist = 'Y' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.CHECK_DELETE_ITEMLOC',
                                             to_char(SQLCODE));
      RETURN FALSE;
END CHECK_DELETE_ITEMLOC;
------------------------------------------------------------
FUNCTION CHECK_DUP_ITEMLOC(O_error_message     IN OUT VARCHAR2,
                           O_exists            IN OUT BOOLEAN,
                           I_deal_id           IN     deal_itemloc.deal_id%TYPE,
                           I_deal_detail_id    IN     deal_itemloc.deal_detail_id%TYPE,
                           I_merch_level       IN     deal_itemloc.merch_level%TYPE,
                           I_org_level         IN     deal_itemloc.org_level%TYPE,
                           I_origin_country_id IN     country.country_id%TYPE,
                           I_company_ind       IN     deal_itemloc.company_ind%TYPE,
                           I_division          IN     deal_itemloc.division%TYPE,
                           I_group             IN     deal_itemloc.group_no%TYPE,
                           I_dept              IN     deal_itemloc.dept%TYPE,
                           I_class             IN     deal_itemloc.class%TYPE,
                           I_subclass          IN     deal_itemloc.subclass%TYPE,
                           I_item_grandparent  IN     deal_itemloc.item_grandparent%TYPE,
                           I_item_parent       IN     deal_itemloc.item_parent%TYPE,
                           I_diff_1            IN     deal_itemloc.diff_1%TYPE,
                           I_diff_2            IN     deal_itemloc.diff_2%TYPE,
                           I_diff_3            IN     deal_itemloc.diff_3%TYPE,
                           I_diff_4            IN     deal_itemloc.diff_4%TYPE,
                           I_chain             IN     deal_itemloc.chain%TYPE,
                           I_area              IN     deal_itemloc.area%TYPE,
                           I_region            IN     deal_itemloc.region%TYPE,
                           I_district          IN     deal_itemloc.district%TYPE,
                           I_loc_type          IN     deal_itemloc.loc_type%TYPE,
                           I_location          IN     deal_itemloc.location%TYPE,
                           I_item              IN     deal_itemloc.item%TYPE,
                           I_excl_ind          IN     deal_itemloc.excl_ind%TYPE)
RETURN BOOLEAN IS
   L_exist  VARCHAR2(1) := 'N';
   ---
   cursor C_DUP_ITEMLOC is
      select 'Y'
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and (merch_level = I_merch_level or I_merch_level is null)
         and (org_level = I_org_level or (I_org_level is null
                                          and org_level is null))
         and (origin_country_id = I_origin_country_id or (I_origin_country_id is null
                                                          and origin_country_id is null))
         and (company_ind = I_company_ind or I_company_ind is null)
         and (division = I_division or I_division is null)
         and (group_no = I_group or I_group is null)
         and (dept = I_dept or I_dept is null)
         and (class = I_class or I_class is null)
         and (subclass = I_subclass or I_subclass is null)
         and (item_grandparent = I_item_grandparent or I_item_grandparent is null)
         and (item_parent = I_item_parent or I_item_parent is null)
         and (diff_1 = I_diff_1 or I_diff_1 is null)
         and (diff_2 = I_diff_2 or I_diff_2 is null)
         and (diff_3 = I_diff_3 or I_diff_3 is null)
         and (diff_4 = I_diff_4 or I_diff_4 is null)
         and (chain = I_chain or I_chain is null)
         and (area = I_area or I_area is null)
         and (region = I_region or I_region is null)
         and (district = I_district or I_district is null)
         and (loc_type = I_loc_type or I_loc_type is null)
         and (location = I_location or I_location is null)
         and (item = I_item or I_item is null)
         and (excl_ind = I_excl_ind or I_excl_ind is null);

BEGIN

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_id','NULL','NOT NULL');
      return FALSE;
   elsif I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_detail_id','NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_DUP_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   open C_DUP_ITEMLOC;
   ---
   SQL_LIB.SET_MARK('FETCH','C_DUP_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   fetch C_DUP_ITEMLOC into L_exist;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_DUP_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   close C_DUP_ITEMLOC;
   ---
   if L_exist = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.CHECK_DUP_ITEMLOC',
                                             to_char(SQLCODE));
      RETURN FALSE;
END CHECK_DUP_ITEMLOC;
------------------------------------------------------------
FUNCTION CONFLICT_COLLECT_DATES_EXIST(O_error_message     IN OUT VARCHAR2,
                                      O_exists            IN OUT BOOLEAN,
                                      O_confl_deal_comp   IN OUT deal_itemloc.deal_detail_id%TYPE,
                                      I_deal_id           IN     deal_itemloc.deal_id%TYPE)
RETURN BOOLEAN IS
   cursor C_CONFLICTING_DEAL is
      select deal_detail_id
        from deal_detail dd, deal_head dh
       where dd.collect_start_date < dh.active_date
         and dd.deal_id = I_deal_id
         and dh.deal_id = I_deal_id;
BEGIN

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_id','NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CONFLICTING_DEAL','deal_detail, deal_head',
                    'deal_id: ' || I_deal_id);
   open C_CONFLICTING_DEAL;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CONFLICTING_DEAL','deal_detail, deal_head',
                    'deal_id: ' || I_deal_id);
   fetch C_CONFLICTING_DEAL into O_confl_deal_comp;
   ---
   if C_CONFLICTING_DEAL%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CONFLICTING_DEAL','deal_detail, deal_head',
                    'deal_id: ' || I_deal_id);
   close C_CONFLICTING_DEAL;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.CONFLICT_COLLECT_DATES_EXIST',
                                             to_char(SQLCODE));
      RETURN FALSE;
END CONFLICT_COLLECT_DATES_EXIST;
------------------------------------------------------------
FUNCTION ITEMLOC_EXISTS(O_error_message     IN OUT VARCHAR2,
                        O_exists            IN OUT BOOLEAN,
                        I_deal_id           IN     deal_head.deal_id%TYPE,
                        I_deal_detail_id    IN     deal_detail.deal_detail_id%TYPE)
RETURN BOOLEAN IS
   L_exists    VARCHAR2(1) := 'N';
   cursor C_ITEMLOC is
      select 'Y'
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;
BEGIN

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_id','NULL','NOT NULL');
      return FALSE;
   elsif I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_detail_id','NULL','NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   open C_ITEMLOC;
   ---
   SQL_LIB.SET_MARK('FETCH','C_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   fetch C_ITEMLOC into L_exists;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_ITEMLOC','deal_itemloc',
                    'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id);
   close C_ITEMLOC;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.ITEMLOC_EXISTS',
                                             to_char(SQLCODE));
      RETURN FALSE;
END ITEMLOC_EXISTS;
------------------------------------------------------------
FUNCTION VALIDATE_ITEMLOC (O_error_message     IN OUT VARCHAR2,
                           O_valid             IN OUT BOOLEAN,
                           I_deal_id           IN     deal_itemloc.deal_id%TYPE,
                           I_deal_detail_id    IN     deal_itemloc.deal_detail_id%TYPE,
                           I_merch_level       IN     deal_itemloc.merch_level%TYPE,
                           I_org_level         IN     deal_itemloc.org_level%TYPE,
                           I_origin_country_id IN     deal_itemloc.origin_country_id%TYPE,
                           I_company_ind       IN     deal_itemloc.company_ind%TYPE,
                           I_division          IN     deal_itemloc.division%TYPE,
                           I_group             IN     deal_itemloc.group_no%TYPE,
                           I_dept              IN     deal_itemloc.dept%TYPE,
                           I_class             IN     deal_itemloc.class%TYPE,
                           I_subclass          IN     deal_itemloc.subclass%TYPE,
                           I_item_grandparent  IN     deal_itemloc.item_grandparent%TYPE,
                           I_item_parent       IN     deal_itemloc.item_parent%TYPE,
                           I_diff_1            IN     deal_itemloc.diff_1%TYPE,
                           I_diff_2            IN     deal_itemloc.diff_2%TYPE,
                           I_diff_3            IN     deal_itemloc.diff_3%TYPE,
                           I_diff_4            IN     deal_itemloc.diff_4%TYPE,
                           I_item              IN     deal_itemloc.item%TYPE,
                           I_chain             IN     deal_itemloc.chain%TYPE,
                           I_area              IN     deal_itemloc.area%TYPE,
                           I_region            IN     deal_itemloc.region%TYPE,
                           I_district          IN     deal_itemloc.district%TYPE,
                           I_loc_type          IN     deal_itemloc.loc_type%TYPE,
                           I_location          IN     deal_itemloc.location%TYPE,
                           I_excl_ind          IN     deal_itemloc.excl_ind%TYPE)

RETURN BOOLEAN IS

   L_itemloc_exists           BOOLEAN := FALSE;
   L_dup_exists               BOOLEAN := FALSE;
   L_root_exists              BOOLEAN := FALSE;
   L_root_merch_level         deal_itemloc.merch_level%TYPE;
   L_root_org_level           deal_itemloc.org_level%TYPE;
   L_root_origin_country_id   deal_itemloc.origin_country_id%TYPE;
   L_merch_levels_equal       BOOLEAN := FALSE;
   L_org_levels_equal         BOOLEAN := FALSE;
   L_merch_lvl_desc           code_detail.code_desc%TYPE;
   L_org_lvl_desc             code_detail.code_desc%TYPE;
   ---

   cursor C_VALID_MERCH_VALUE is
      select 'Y'
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and excl_ind = 'N'
         and (L_root_merch_level = '1'
              or (L_root_merch_level = '2' and division = I_division)
              or (L_root_merch_level = '3' and group_no = I_group)
              or (L_root_merch_level = '4' and dept = I_dept)
              or (L_root_merch_level = '5'
                  and dept = I_dept
                  and class = I_class)
              or (L_root_merch_level = '6'
                  and dept = I_dept
                  and class = I_class
                  and subclass = I_subclass)
              or (L_root_merch_level = '7'
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '8'
                  and diff_1 = I_diff_1
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '9'
                  and diff_2 = I_diff_2
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '10'
                  and diff_3 = I_diff_3
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '11'
                  and diff_4 = I_diff_4
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '12' and item = I_item));
   ---
   L_valid_merch_value_exists VARCHAR2(1) := 'N';
   ---
   cursor C_VALID_ORG_VALUE is
   select 'Y'
     from deal_itemloc
    where deal_id = I_deal_id
      and deal_detail_id = I_deal_detail_id
      and excl_ind = 'N'
      and ((L_root_org_level = '1' and chain = I_chain)
           or (L_root_org_level = '2' and area = I_area)
           or (L_root_org_level = '3' and region = I_region)
           or (L_root_org_level = '4' and district = I_district)
           or (L_root_org_level = '5' and location = I_location));
   ---
   L_valid_org_value_exists VARCHAR2(1) := 'N';
   ---
   cursor C_VALID_COUNTRY is
      select 'Y'
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id
         and excl_ind = 'N'
         and origin_country_id = I_origin_country_id
         and (merch_level = '1'
              or (merch_level = '2' and division = I_division)
              or (merch_level = '3' and group_no = I_group)
              or (merch_level = '4' and dept = I_dept)
              or (merch_level = '5' and dept = I_dept and class = I_class)
              or (merch_level = '6' and dept = I_dept and class = I_class and subclass = I_subclass)
              or (L_root_merch_level = '7'
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '8'
                  and diff_1 = I_diff_1
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '9'
                  and diff_2 = I_diff_2
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '10'
                  and diff_3 = I_diff_3
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '11'
                  and diff_4 = I_diff_4
                  and ((item_parent = I_item_parent)
                      or (item_grandparent = I_item_grandparent)))
              or (L_root_merch_level = '12' and item = I_item));
   ---
   L_valid_country_exists     VARCHAR2(1) := 'N';
   ---
   cursor C_DESC_DIML is
      select code_desc
        from code_detail
       where code_type = 'DIML'
         and code = L_root_merch_level;
   ---
   cursor C_DESC_DIOL is
      select code_desc
        from code_detail
       where code_type = 'DIOL'
         and code = L_root_org_level;

BEGIN
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_id','NULL','NOT NULL');
      return FALSE;
   elsif I_deal_detail_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_deal_detail_id','NULL','NOT NULL');
      return FALSE;
   elsif I_merch_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM', 'I_merch_level', 'NULL', 'NOT NULL');
      return FALSE;
   end if;
   ---
   if DEAL_VALIDATE_SQL.ITEMLOC_EXISTS(O_error_message,
                                       L_itemloc_exists,
                                       I_deal_id,
                                       I_deal_detail_id) = FALSE then
      return FALSE;
   end if;
   ---
   if L_itemloc_exists = FALSE then
      if I_excl_ind = 'Y' then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('INCL_BEFORE_EXCL', NULL, NULL, NULL);
         return TRUE;
      else
         O_valid := TRUE;
         return TRUE;
      end if;
   end if;
   ---
   if DEAL_VALIDATE_SQL.CHECK_DUP_ITEMLOC(O_error_message,
                                          L_dup_exists,
                                          I_deal_id,
                                          I_deal_detail_id,
                                          I_merch_level,
                                          I_org_level,
                                          I_origin_country_id,
                                          I_company_ind,
                                          I_division,
                                          I_group,
                                          I_dept,
                                          I_class,
                                          I_subclass,
                                          I_item_grandparent,
                                          I_item_parent,
                                          I_diff_1,
                                          I_diff_2,
                                          I_diff_3,
                                          I_diff_4,
                                          I_chain,
                                          I_area,
                                          I_region,
                                          I_district,
                                          I_loc_type,
                                          I_location,
                                          I_item,
                                          I_excl_ind) = FALSE then
      return FALSE;
   end if;
   ---
   if L_dup_exists then
      O_valid := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('DUP_RECORD', NULL, NULL, NULL);
      return TRUE;
   end if;
   if DEAL_ATTRIB_SQL.GET_ROOT_ITEMLOC_LEVEL(O_error_message,
                                             L_root_exists,
                                             L_root_merch_level,
                                             L_root_org_level,
                                             L_root_origin_country_id,
                                             I_deal_id,
                                             I_deal_detail_id) = FALSE then
         return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_DESC_DIML','code_detail', 'code: '||L_root_merch_level);
   open C_DESC_DIML;
   SQL_LIB.SET_MARK('FETCH','C_DESC_DIML','code_detail', 'code: '||L_root_merch_level);
   fetch C_DESC_DIML into L_merch_lvl_desc;
   SQL_LIB.SET_MARK('CLOSE','C_DESC_DIML','code_detail', 'code: '||L_root_merch_level);
   close C_DESC_DIML;
   ---
   SQL_LIB.SET_MARK('OPEN','C_DESC_DIOL','code_detail', 'code: '||L_root_org_level);
   open C_DESC_DIOL;
   SQL_LIB.SET_MARK('FETCH','C_DESC_DIOL','code_detail', 'code: '||L_root_org_level);
   fetch C_DESC_DIOL into L_org_lvl_desc;
   SQL_LIB.SET_MARK('CLOSE','C_DESC_DIOL','code_detail', 'code: '||L_root_org_level);
   close C_DESC_DIOL;
   ---
   if I_excl_ind = 'N' then
      -- verify record is at the root level for the component
      if I_merch_level != L_root_merch_level then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('BAD_INCL_MERCH_LEVEL', L_merch_lvl_desc, NULL, NULL);
         return TRUE;
      end if;
      ---
      if I_org_level is NOT NULL and L_root_org_level is NULL then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('NO_ORG_ALLOWED', NULL, NULL, NULL);
         return TRUE;
      end if;
      ---
      if I_org_level is NULL and L_root_org_level is NOT NULL then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('BAD_INCL_ORG_LEVEL', L_org_lvl_desc, NULL, NULL);
         return TRUE;
      end if;
      ---
      if I_org_level is NOT NULL and L_root_org_level is NOT NULL and I_org_level != L_root_org_level then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('BAD_INCL_ORG_LEVEL', L_org_lvl_desc, NULL, NULL);
         return TRUE;
      end if;
      ---
      if I_origin_country_id is NULL and L_root_origin_country_id is NOT NULL then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('BAD_INCL_ORG_CNTRY', L_root_origin_country_id, NULL, NULL);
         return TRUE;
      end if;
      ---
      if I_origin_country_id is NOT NULL and L_root_origin_country_id is NULL then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('NO_ORG_CNTRY_ALLOWED', NULL, NULL, NULL);
         return TRUE;
      end if;
   else
      -- verify that exclusion record falls within the root level
      if To_Number(I_merch_level) < To_Number(L_root_merch_level) then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('MERCH_LEVEL_TOO_HIGH', L_merch_lvl_desc, NULL, NULL);
         return TRUE;
      end if;
      ---
      -- open cursor to verify that merch value is a valid subset of
      -- some root record.  Fail if it isn't.
      SQL_LIB.SET_MARK('OPEN','C_VALID_MERCH_VALUE','deal_itemloc',
                             'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id || 'merch_level: ' || L_root_merch_level);
      open C_VALID_MERCH_VALUE;
      SQL_LIB.SET_MARK('FETCH','C_VALID_MERCH_VALUE','deal_itemloc',
                             'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id || 'merch_level: ' || L_root_merch_level);
      fetch C_VALID_MERCH_VALUE into L_valid_merch_value_exists;
      SQL_LIB.SET_MARK('CLOSE','C_VALID_MERCH_VALUE','deal_itemloc',
                             'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id || 'merch_level: ' || L_root_merch_level);
      close C_VALID_MERCH_VALUE;
      if L_valid_merch_value_exists = 'N' then
         O_valid := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('NO_HIGHER_MERCH_INCL', NULL, NULL, NULL);
         return TRUE;
      end if;
      ---
      if I_merch_level = L_root_merch_level then
         L_merch_levels_equal := TRUE;
      else
         L_merch_levels_equal := FALSE;
      end if;
      ---
      if L_root_org_level is NOT NULL then
         if I_org_level is NULL then
            O_valid := FALSE;
            O_error_message := SQL_LIB.CREATE_MSG('ORG_LEVEL_NEEDED', NULL, NULL, NULL);
            return TRUE;
         end if;
         ---
         if To_Number(I_org_level) < To_Number(L_root_org_level) then
            O_valid := FALSE;
            O_error_message := SQL_LIB.CREATE_MSG('ORG_LEVEL_TOO_HIGH', L_org_lvl_desc, NULL, NULL);
            return TRUE;
         end if;
         ---
         -- open cursor to verify that org value is a valid subset of
         -- some root record.  Fail if it isn't.
         if I_loc_type != 'W' or I_loc_type is NULL then
            SQL_LIB.SET_MARK('OPEN','C_VALID_ORG_VALUE','deal_itemloc',
                                   'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id || 'org_level: ' || L_root_org_level);
            open C_VALID_ORG_VALUE;
            ---
            SQL_LIB.SET_MARK('FETCH','C_VALID_ORG_VALUE','deal_itemloc',
                                   'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id || 'org_level: ' || L_root_org_level);
            fetch C_VALID_ORG_VALUE into L_valid_org_value_exists;
            ---
            SQL_LIB.SET_MARK('CLOSE','C_VALID_ORG_VALUE','deal_itemloc',
                                   'deal_id: ' || I_deal_id || ', deal_detail_id: ' || I_deal_detail_id || 'org_level: ' || L_root_org_level);
            close C_VALID_ORG_VALUE;

            -- If a record is not found set O_valid to FALSE, create an error message indicating that a
            -- higher level inclusion record does not exist above the passed in I_org_level and return
            -- TRUE.
            if L_valid_org_value_exists = 'N' then
               O_valid := FALSE;
               O_error_message := SQL_LIB.CREATE_MSG('NO_HIGHER_ORG_INCL', NULL, NULL, NULL);
               return TRUE;
            end if;
         end if; -- I_loc_type != 'W'
         ---
         if I_org_level = L_root_org_level then
            L_org_levels_equal := TRUE;
         else
            L_org_levels_equal := FALSE;
         end if;
      end if; -- L_root_org_level is NOT NULL
      ---
      if L_root_origin_country_id is NOT NULL then
         if I_origin_country_id is NULL then
            O_valid := FALSE;
            O_error_message := SQL_LIB.CREATE_MSG('NO_ORG_COUNTRY', NULL, NULL, NULL);
            return TRUE;
         end if;
         ---
         -- open cursor to see if I_origin_country equals some root origin
         -- country.  Fail if it doesn't.
         SQL_LIB.SET_MARK('OPEN','C_VALID_COUNTRY','deal_itemloc',
                                'deal_id: ' || I_deal_id ||
                                ', deal_detail_id: ' || I_deal_detail_id ||
                                ', origin_country_id: ' || I_origin_country_id);
         open C_VALID_COUNTRY;
         ---
         SQL_LIB.SET_MARK('FETCH','C_VALID_COUNTRY','deal_itemloc',
                                'deal_id: ' || I_deal_id ||
                                ', deal_detail_id: ' || I_deal_detail_id ||
                                ', origin_country_id: ' || I_origin_country_id);
         fetch C_VALID_COUNTRY into L_valid_country_exists;
         ---
         SQL_LIB.SET_MARK('CLOSE','C_VALID_COUNTRY','deal_itemloc',
                                'deal_id: ' || I_deal_id ||
                                ', deal_detail_id: ' || I_deal_detail_id ||
                                ', origin_country_id: ' || I_origin_country_id);
         close C_VALID_COUNTRY;

         -- If a record is not found set O_valid to FALSE, create an error message indicating that the
         -- origin country does not match an inclusion origin country and return TRUE.
         if L_valid_country_exists = 'N' then
            O_valid := FALSE;
            O_error_message := SQL_LIB.CREATE_MSG('COUNTRY_DOESNT_MATCH', NULL, NULL, NULL);
            return TRUE;
         end if;
         ---
      end if;
      ---
   end if; -- I_excl_ind = 'Y'
   ---
   O_valid := TRUE;
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.VALIDATE_ITEMLOC',
                                             to_char(SQLCODE));
      RETURN FALSE;
END VALIDATE_ITEMLOC;
--------------------------------------------------------------------------------
FUNCTION CHECK_THRESH_LIMITS(O_error_message    IN OUT VARCHAR2,
                             O_exists           IN OUT BOOLEAN,
                             I_deal_id          IN     DEAL_HEAD.DEAL_ID%TYPE)
RETURN BOOLEAN IS
   L_exists        VARCHAR2(1);
   L_error_message VARCHAR2(255);
   L_cost_fmt      currencies.currency_cost_fmt%TYPE;

   cursor C_CURR_COST_FMT is
      select c.currency_cost_fmt
        from deal_head d,
             currencies c
       where d.deal_id = I_deal_id
         and c.currency_code = d.currency_code;



   cursor C_EXISTS is
      select 'x'
        from deal_head h,
             deal_detail d
       where h.deal_id = I_deal_id
         and h.deal_id = d.deal_id
         and ((h.threshold_limit_type in ('Q', 'P')
               and NOT EXISTS (select 'x'
                                 from deal_threshold t
                                where t.deal_id        =  d.deal_id
                                  and t.deal_detail_id =  d.deal_detail_id
                                  and t.upper_limit    >= 99999999
                                  and rownum           =  1))
          or (h.threshold_limit_type = 'A'
              and NOT EXISTS (select 'x'
                                from deal_threshold t
                               where t.deal_id        =  d.deal_id
                                 and t.deal_detail_id =  d.deal_detail_id
                                 and t.upper_limit    >= 9999999999999999
                                 and rownum           =  1)))
         and rownum    = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_CURR_COST__FMT', 'DEAL_HEAD', 'deal id: '||TO_CHAR(I_deal_id));
   open C_CURR_COST_FMT;
   SQL_LIB.SET_MARK('FETCH', 'C_CURR_COST_FMT', 'DEAL_HEAD', 'deal id: '||TO_CHAR(I_deal_id));
   fetch C_CURR_COST_FMT into L_cost_fmt;
   SQL_LIB.SET_MARK('CLOSE','C_CURR_COST_FMT', 'DEAL_HEAD', 'deal id: '||TO_CHAR(I_deal_id));
   close C_CURR_COST_FMT;
   ---
   SQL_LIB.SET_MARK('OPEN','C_EXISTS', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   open C_EXISTS;
   ---
   SQL_LIB.SET_MARK('FETCH','C_EXISTS', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   fetch C_EXISTS into L_exists;
      ---
      if C_EXISTS%NOTFOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;
      ---
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   close C_EXISTS;

   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_VALIDATE_SQL.CHECK_THRESH_LIMITS', to_char(SQLCODE));
      return FALSE;
END CHECK_THRESH_LIMITS;
--------------------------------------------------------------------------------
FUNCTION PO_DEAL_EXIST(O_error_message    IN OUT      VARCHAR2,
                       O_exist            IN OUT      BOOLEAN,
                       O_deal_id          IN OUT      deal_head.deal_id%TYPE,
                       I_order_no         IN          deal_head.order_no%TYPE)
RETURN BOOLEAN IS
   L_deal_id       deal_head.deal_id%TYPE;

   cursor C_EXIST is
      select deal_id
        from deal_head
       where order_no = I_order_no;
BEGIN
   SQL_LIB.SET_MARK('OPEN','C_EXIST', 'DEAL_HEAD', 'order no: '||TO_CHAR(I_order_no));
   open C_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_EXIST', 'DEAL_HEAD', 'order no: '||TO_CHAR(I_order_no));
   fetch C_EXIST into L_deal_id;
      ---
      if C_EXIST%NOTFOUND then
         O_exist := FALSE;
      else
         O_exist := TRUE;
         O_deal_id := L_deal_id;
      end if;
      ---
   SQL_LIB.SET_MARK('CLOSE','C_EXIST', 'DEAL_HEAD', 'order no: '||TO_CHAR(I_order_no));
   close C_EXIST;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_VALIDATE_SQL.PO_DEAL_EXIST', to_char(SQLCODE));
      return FALSE;
END PO_DEAL_EXIST;
--------------------------------------------------------------------------------
FUNCTION CHECK_DELETE_DEAL(O_error_message    IN OUT   VARCHAR2,
                           O_exists           IN OUT   BOOLEAN,
                           I_deal_id          IN       DEAL_HEAD.DEAL_ID%TYPE,
                           I_deal_detail_id   IN       DEAL_DETAIL.DEAL_DETAIL_ID%TYPE)
RETURN BOOLEAN IS
   L_exist    VARCHAR2(1);


   cursor C_OD_EXIST is
      select 'x'
        from ordloc_discount
       where deal_id = I_deal_id
         and deal_detail_id = nvl(I_deal_detail_id, deal_detail_id);

BEGIN
   O_exists := FALSE;
   ---


      SQL_LIB.SET_MARK('OPEN',
                       'C_OD_EXIST',
                       'ORDLOC_DISCOUNT',
                       'deal id: '||TO_CHAR(I_deal_id));
      open C_OD_EXIST;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_OD_EXIST',
                       'ORDLOC_DISCOUNT',
                       'deal id: '||TO_CHAR(I_deal_id));
      fetch C_OD_EXIST into L_exist;
         ---
         if C_OD_EXIST%FOUND then
            O_exists := TRUE;
         end if;
         ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_OD_EXIST',
                       'ORDLOC_DISCOUNT',
                       'deal id: '||TO_CHAR(I_deal_id));
      close C_OD_EXIST;
      ---


   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_VALIDATE_SQL.CHECK_DELETE_DEAL',
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_DELETE_DEAL;
--------------------------------------------------------------------------------
FUNCTION TARGET_LEVEL_EXISTS(O_error_message    IN OUT VARCHAR2,
                             O_exists           IN OUT BOOLEAN,
                             O_deal_detail_id   IN OUT DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                             I_deal_id          IN     DEAL_HEAD.DEAL_ID%TYPE)
RETURN BOOLEAN IS
   L_exist    DEAL_DETAIL.DEAL_DETAIL_ID%TYPE;

   cursor C_EXIST is
     select dd.deal_detail_id
       from deal_detail dd, deal_threshold dt
      where dd.deal_id = I_deal_id
        and dd.deal_id = dt.deal_id
        and dd.deal_detail_id = dt.deal_detail_id
        and NOT EXISTS(select 'x'
                         from deal_threshold
                        where deal_id = dd.deal_id
                          and deal_detail_id = dd.deal_detail_id
                          and target_level_ind = 'Y');

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_EXIST', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   open C_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_EXIST', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   fetch C_EXIST into L_exist;
      ---
      if C_EXIST%FOUND then
         O_exists := FALSE;
         O_deal_detail_id := L_exist;
      else
         O_exists := TRUE;
      end if;
      ---
   SQL_LIB.SET_MARK('CLOSE','C_EXIST', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   close C_EXIST;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_VALIDATE_SQL.TARGET_LEVEL_EXISTS', to_char(SQLCODE));
      return FALSE;
END TARGET_LEVEL_EXISTS;
--------------------------------------------------------------------------------
FUNCTION CHK_FREE_GOODS_DEALS(O_error_message         IN OUT            VARCHAR2,
                              O_exist                 IN OUT            BOOLEAN,
                              O_item                  IN OUT            item_master.item%TYPE,
                              I_order_no              IN                ordhead.order_no%TYPE,
                              I_location              IN                ordloc.location%TYPE,
                              I_not_before_date       IN                ordhead.not_before_date%TYPE,
                              I_supplier              IN                ordhead.supplier%TYPE)
RETURN BOOLEAN IS
   L_supplier         ordhead.supplier%TYPE;
   L_not_before_date  ordhead.not_before_date%TYPE;
   L_item             item_master.item%TYPE;

   cursor C_ORDER_INFO is
      select not_before_date, supplier
        from ordhead
       where order_no = I_order_no;



   cursor C_GET_ITEM is
      select o.item
        from deal_detail dd,
             deal_head dh,
             ordloc o
       where o.order_no              =  I_order_no
         and o.location              =  I_location
         and o.cost_source           <> 'MANL'
         and dh.threshold_limit_type =  'Q'
         and dd.qty_thresh_buy_item  =  o.item
         and dh.active_date          <= L_not_before_date
         and (dh.close_date          >= L_not_before_date
              or dh.close_date is NULL)
         and dh.deal_id              =  dd.deal_id
         and dh.status               =  'A'
         and dh.supplier             =  L_supplier
         and o.unit_cost             <  dd.qty_thresh_free_item_unit_cost
         and NOT EXISTS(select 'x'
                          from ordloc_discount
                         where ((item         = o.item
                                 and pack_no is NULL)
                                or pack_no    = o.item)
                           and location       = o.location
                           and deal_id        = dd.deal_id
                           and deal_detail_id = dd.deal_detail_id)
         and (dh.order_no = o.order_no
              or (dh.order_no is NULL
                  and NOT EXISTS(select 'x'
                                   from deal_head
                                  where order_no = o.order_no
                                    and deal_id <> dd.deal_id)));


BEGIN
   if I_not_before_date is NULL or I_supplier is NULL then
      SQL_LIB.SET_MARK('OPEN','C_ORDER_INFO', 'ORDHEAD', 'order no: '||TO_CHAR(I_order_no));
      open C_ORDER_INFO;
      ---
      SQL_LIB.SET_MARK('FETCH','C_ORDER_INFO', 'ORDHEAD', 'order no: '||TO_CHAR(I_order_no));
      fetch C_ORDER_INFO into L_not_before_date, L_supplier;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_ORDER_INFO', 'ORDHEAD', 'order no: '||TO_CHAR(I_order_no));
      close C_ORDER_INFO;
   else
      L_supplier := I_supplier;
      L_not_before_date := I_not_before_date;
   end if;
   ---
   O_exist := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_ITEM', 'DEAL_DETAIL, DEAL_HEAD, ORDLOC', 'order no: '||TO_CHAR(I_order_no));
   open C_GET_ITEM;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_ITEM', 'DEAL_DETAIL, DEAL_HEAD, ORDLOC', 'order no: '||TO_CHAR(I_order_no));
   fetch C_GET_ITEM into L_item;
   ---
   if C_GET_ITEM%NOTFOUND then
      return TRUE;
   else
      O_exist := TRUE;
      O_item := L_item;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM', 'DEAL_DETAIL, DEAL_HEAD, ORDLOC', 'order no: '||TO_CHAR(I_order_no));
   close C_GET_ITEM;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_VALIDATE_SQL.TARGET_LEVEL_EXISTS', to_char(SQLCODE));
      return FALSE;
END CHK_FREE_GOODS_DEALS;
------------------------------------------------------------
FUNCTION BUY_GET_ITEMS(O_error_message     IN OUT    VARCHAR2,
                       O_overlap_exists    IN OUT    BOOLEAN,
                       I_deal_id           IN        DEAL_HEAD.DEAL_ID%TYPE,
                       I_deal_detail_id    IN        DEAL_DETAIL.DEAL_DETAIL_ID%TYPE,
                       I_active_date       IN        DEAL_HEAD.ACTIVE_DATE%TYPE,
                       I_close_date        IN        DEAL_HEAD.CLOSE_DATE%TYPE,
                       I_partner_type      IN        DEAL_HEAD.PARTNER_TYPE%TYPE,
                       I_partner_id        IN        DEAL_HEAD.PARTNER_ID%TYPE,
                       I_supplier          IN        DEAL_HEAD.SUPPLIER%TYPE,
                       I_buy_item          IN        DEAL_DETAIL.QTY_THRESH_BUY_ITEM%TYPE,
                       I_get_item          IN        DEAL_DETAIL.QTY_THRESH_GET_ITEM%TYPE)

RETURN BOOLEAN IS

   L_found   VARCHAR2(1) := 'N';
   L_active_date          deal_head.active_date%TYPE;
   L_close_date           deal_head.close_date%TYPE;

   cursor C_ACTIVE_CLOSE_DATE is
      select active_date,
             close_date
        from deal_head
       where deal_head.deal_id = I_deal_id;

   cursor C_BUY_GET_ITEM is
      select /*+ index(dd) */
             'Y'
        from deal_detail dd,
             deal_head dh
       where dd.deal_id = dh.deal_id
         and ((dh.status = 'A'
               and dh.deal_id != I_deal_id)
              or (dh.status = 'W'
                  and (dh.deal_id = I_deal_id
                       and dd.deal_detail_id != nvl(I_deal_detail_id,-999))))
         and ((dh.active_date < L_active_date
                  and (dh.close_date >= L_active_date and dh.close_date is not NULL)
                   or (dh.close_date is NULL and dh.active_date <= L_close_date))
          or (dh.active_date >= L_active_date
                 and (L_close_date is NULL or (L_close_date is not NULL and
                         dh.active_date <= L_close_date)))
          or dh.close_date is NULL and L_close_date is NULL)
         and (  (dh.supplier = I_supplier
                 and I_partner_type = 'S')
             or (dh.partner_id = I_partner_id
                 and dh.partner_type = I_partner_type))
         and (  (dd.qty_thresh_buy_item = I_buy_item
                 and dd.qty_thresh_get_item = I_get_item)
             or (dd.qty_thresh_buy_item = I_get_item)
             or (dd.qty_thresh_get_item = I_buy_item));

BEGIN
   if I_active_date is NULL then
      SQL_LIB.SET_MARK('OPEN','C_ACTIVE_CLOSE_DATE', 'DEAL_HEAD', 'deal_id: '||I_deal_id);
      open C_ACTIVE_CLOSE_DATE;
      ---
      SQL_LIB.SET_MARK('FETCH','C_ACTIVE_CLOSE_DATE', 'DEAL_HEAD', 'deal_id: '||I_deal_id);
      fetch C_ACTIVE_CLOSE_DATE into L_active_date, L_close_date;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_ACTIVE_CLOSE_DATE', 'DEAL_HEAD', 'deal_id: '||I_deal_id);
      close C_ACTIVE_CLOSE_DATE;
   else
      L_active_date := I_active_date;
      L_close_date  := I_close_date;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_BUY_GET_ITEM','DEAL_DETAIL, DEAL_HEAD',
                    'deal_id: '||I_deal_id);
   open C_BUY_GET_ITEM;
   ---
   SQL_LIB.SET_MARK('FETCH','C_BUY_GET_ITEM','DEAL_DETAIL, DEAL_HEAD',
                    'deal_id: '||I_deal_id);
   fetch C_BUY_GET_ITEM into L_found;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_BUY_GET_ITEM','DEAL_DETAIL, DEAL_HEAD',
                    'deal_id: '||I_deal_id);
   close C_BUY_GET_ITEM;
   ---
   -- if found, overlap exists
   if L_found = 'Y' then
      O_overlap_exists := TRUE;
   else
      O_overlap_exists := FALSE;
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.BUY_GET_ITEMS',
                                             to_char(SQLCODE));
      RETURN FALSE;
END BUY_GET_ITEMS;
--------------------------------------------------------------------------------------------------------
FUNCTION ALL_DEAL_IDS (O_error_message IN OUT VARCHAR2,
                       O_exist         IN OUT BOOLEAN,
                       O_type          IN OUT VARCHAR2,
                       I_deal_id       IN     deal_head.deal_id%TYPE)
RETURN BOOLEAN IS

   L_found VARCHAR2(1) := 'N';

   cursor C_FIXED_DEAL is
      select 'Y'
        from fixed_deal
       where deal_no = I_deal_id;

BEGIN
   if DEAL_VALIDATE_SQL.DEAL_ID(O_error_message,
                                O_exist,
                                I_deal_id) = FALSE then
      RETURN FALSE;
   end if;
   ---
   if O_exist = TRUE then
      O_type := 'D';
   else
      ---
      SQL_LIB.SET_MARK('OPEN','C_FIXED_DEAL','fixed_deal',
                    'deal_no: '||I_deal_id);
      open C_FIXED_DEAL;
      ---
      SQL_LIB.SET_MARK('FETCH','C_FIXED_DEAL','fixed_deal',
                    'deal_no: '||I_deal_id);
      fetch C_FIXED_DEAL into L_found;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_FIXED_DEAL','fixed_deal',
                    'deal_no: '||I_deal_id);
      close C_FIXED_DEAL;
      ---
      if L_found = 'Y' then
         O_exist := TRUE;
         O_type := 'F';
      else
         O_exist := FALSE;
      end if;
      ---
   end if;
   ---
   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.DEAL_ID',
                                             to_char(SQLCODE));
      RETURN FALSE;
END;
--------------------------------------------------------------------------------------------------------
FUNCTION ORDHEAD_DATES_EXIST (O_error_message IN OUT VARCHAR2,
                              O_exist         IN OUT BOOLEAN,
                              I_order_no      IN     ORDHEAD.ORDER_NO%TYPE)
RETURN BOOLEAN IS

   L_exists   VARCHAR2(1);

   cursor C_DATES_EXIST is
      select 'X'
        from ordhead
       where not_before_date is not NULL
         and not_after_date is not NULL
         and order_no = I_order_no;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_DATES_EXIST', 'ORDHEAD', 'order no: '||TO_CHAR(I_order_no));
   open C_DATES_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_DATES_EXIST', 'ORDHEAD', 'order no: '||TO_CHAR(I_order_no));
   fetch C_DATES_EXIST into L_exists;
      ---
      if C_DATES_EXIST%NOTFOUND then
         O_exist := FALSE;
      else
         O_exist := TRUE;
      end if;
      ---
   SQL_LIB.SET_MARK('CLOSE','C_DATES_EXIST', 'ORDHEAD', 'order no: '||TO_CHAR(I_order_no));
   close C_DATES_EXIST;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.DEAL_ID',
                                             to_char(SQLCODE));
      RETURN FALSE;
END;
--------------------------------------------------------------------------------------------------------
FUNCTION DEAL_ORDER_EXIST(O_error_message                   IN OUT      VARCHAR2,
                          O_exists                          IN OUT      BOOLEAN,
                          I_order_no                        IN          ordhead.order_no%TYPE)
RETURN BOOLEAN IS

   L_exists      VARCHAR2(3);

   cursor C_GET_DEAL is
      select DISTINCT 'x'
        from ordloc
       where order_no = I_order_no
         and cost_source = 'DEAL';

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_DEAL','DEAL_ORDER_EXIST','ORDER NO: '||to_char(I_order_no));
   open C_GET_DEAL;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_DEAL','DEAL_ORDER_EXIST','ORDER NO: '||to_char(I_order_no));
   fetch C_GET_DEAL into L_exists;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_DEAL', 'DEAL_ORDER_EXIST','ORDER NO: '||to_char(I_order_no));
   close C_GET_DEAL;
   ---
   if L_exists ='x' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.DEAL_ORDER_EXIST',
                                            to_char(SQLCODE));
   return FALSE;
END DEAL_ORDER_EXIST;
--------------------------------------------------------------------------------------------------------
FUNCTION CHECK_DELETE_DETAIL_THRESH(O_error_message    IN OUT VARCHAR2,
                                    O_detail_exists    IN OUT BOOLEAN,
                                    O_thresh_exists    IN OUT BOOLEAN,
                                    I_deal_id          IN     DEAL_HEAD.DEAL_ID%TYPE,
                                    I_deal_detail_id   IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE)
RETURN BOOLEAN IS
   L_detail_exist           VARCHAR2(1);
   L_thresh_exist           VARCHAR2(1);
   L_thresh_rev_exist       VARCHAR2(1);
   L_item_loc_explode_exist VARCHAR2(1);

   cursor C_CHECK_DEAL_DETAIL is
      select 'x'
        from deal_itemloc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;

   cursor C_CHECK_DEAL_ITEM_LOC_EXPLODE is
      select 'x'
        from deal_item_loc_explode
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;

   cursor C_CHECK_DEAL_THRESH is
      select 'x'
        from deal_threshold
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;

   cursor C_CHECK_DEAL_THRESH_REV is
      select 'x'
        from deal_threshold_rev
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;

BEGIN
   O_detail_exists := FALSE;
   O_thresh_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_DEAL_DETAIL', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   open C_CHECK_DEAL_DETAIL;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_DEAL_DETAIL', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   fetch C_CHECK_DEAL_DETAIL into L_detail_exist;
      ---
      if C_CHECK_DEAL_DETAIL%FOUND then
         O_detail_exists := TRUE;
      end if;
      ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_DEAL_DETAIL', 'DEAL_DETAIL', 'deal id: '||TO_CHAR(I_deal_id));
   close C_CHECK_DEAL_DETAIL;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_DEAL_ITEM_LOC_EXPLODE','DEAL_ITEM_LOC_EXPLODE','Deal id: '||TO_CHAR(I_deal_id));
   open C_CHECK_DEAL_ITEM_LOC_EXPLODE;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_DEAL_ITEM_LOC_EXPLODE','DEAL_ITEM_LOC_EXPLODE','Deal id: '||TO_CHAR(I_deal_id));
   fetch C_CHECK_DEAL_ITEM_LOC_EXPLODE into L_item_loc_explode_exist;
   ---
   if C_CHECK_DEAL_ITEM_LOC_EXPLODE%FOUND then
      O_detail_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_DEAL_ITEM_LOC_EXPLODE','DEAL_ITEM_LOC_EXPLODE','Deal id: '||TO_CHAR(I_deal_id));
   close C_CHECK_DEAL_ITEM_LOC_EXPLODE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_DEAL_THRESH', 'DEAL_THRESH', 'deal id: '||TO_CHAR(I_deal_id));
   open C_CHECK_DEAL_THRESH;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_DEAL_THRESH', 'DEAL_THRESHOLD', 'deal id: '||TO_CHAR(I_deal_id));
   fetch C_CHECK_DEAL_THRESH into L_thresh_exist;
      ---
      if C_CHECK_DEAL_THRESH%FOUND then
         O_thresh_exists := TRUE;
      end if;
      ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_DEAL_THRESH', 'DEAL_THRESH', 'deal id: '||TO_CHAR(I_deal_id));
   close C_CHECK_DEAL_THRESH;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_DEAL_THRESH_REV','DEAL_THRESHOLD_REV','Deal id: '||TO_CHAR(I_deal_id));
   open C_CHECK_DEAL_THRESH_REV;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_DEAL_THRESH_REV','DEAL_THRESHOLD_REV','Deal id: '||TO_CHAR(I_deal_id));
   fetch C_CHECK_DEAL_THRESH_REV into L_thresh_rev_exist;
   ---
   if C_CHECK_DEAL_THRESH_REV%FOUND then
      O_thresh_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_DEAL_THRESH_REV','DEAL_THRESHOLD_REV','Deal id: '||TO_CHAR(I_deal_id));
   close C_CHECK_DEAL_THRESH_REV;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_VALIDATE_SQL.CHECK_DELETE_DETAIL_THRESH', to_char(SQLCODE));
      return FALSE;
END CHECK_DELETE_DETAIL_THRESH;
--------------------------------------------------------------------------------------------------------
FUNCTION CHECK_DELETE_ACTUALS(O_error_message    IN OUT VARCHAR2,
                              O_actuals_exists   IN OUT BOOLEAN,
                              I_deal_id          IN     DEAL_HEAD.DEAL_ID%TYPE,
                              I_deal_detail_id   IN     DEAL_DETAIL.DEAL_DETAIL_ID%TYPE)
RETURN BOOLEAN IS

   L_actuals_exist VARCHAR2(1);

   cursor C_CHECK_DEAL_ACTUALS_ITEM_LOC is
      select 'x'
        from deal_actuals_item_loc
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;

   cursor C_CHECK_DEAL_ACTUALS_FORECAST is
      select 'x'
        from deal_actuals_forecast
       where deal_id = I_deal_id
         and deal_detail_id = I_deal_detail_id;

BEGIN

   O_actuals_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_DEAL_ACTUALS_ITEM_LOC','DEAL_ACTUALS_ITEM_LOC','Deal id: '||TO_CHAR(I_deal_id));
   open C_CHECK_DEAL_ACTUALS_ITEM_LOC;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_DEAL_ACTUALS_ITEM_LOC','DEAL_ACTUALS_ITEM_LOC','Deal id: '||TO_CHAR(I_deal_id));
   fetch C_CHECK_DEAL_ACTUALS_ITEM_LOC into L_actuals_exist;
   ---
   if C_CHECK_DEAL_ACTUALS_ITEM_LOC%FOUND then
      O_actuals_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_DEAL_ACTUALS_ITEM_LOC','DEAL_ACTUALS_ITEM_LOC','Deal id: '||TO_CHAR(I_deal_id));
   close C_CHECK_DEAL_ACTUALS_ITEM_LOC;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_DEAL_ACTUALS_FORECAST','DEAL_ACTUALS_FORECAST','Deal id: '||TO_CHAR(I_deal_id));
   open C_CHECK_DEAL_ACTUALS_FORECAST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_DEAL_ACTUALS_FORECAST','DEAL_ACTUALS_FORECAST','Deal id: '||TO_CHAR(I_deal_id));
   fetch C_CHECK_DEAL_ACTUALS_FORECAST into L_actuals_exist;
   ---
   if C_CHECK_DEAL_ACTUALS_FORECAST%FOUND then
      O_actuals_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_DEAL_ACTUALS_FORECAST','DEAL_ACTUALS_FORECAST','Deal id: '||TO_CHAR(I_deal_id));
   close C_CHECK_DEAL_ACTUALS_FORECAST;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'DEAL_VALIDATE_SQL.CHECK_DELETE_ACTUAL_FORECAST', to_char(SQLCODE));
      return FALSE;
END CHECK_DELETE_ACTUALS;
--------------------------------------------------------------------------------------------------------
FUNCTION CHECK_PO_DEAL_DATES(O_error_message    IN OUT      VARCHAR2,
                             I_order_no         IN          ORDHEAD.ORDER_NO%TYPE,
                             I_not_before_date  IN          ORDHEAD.NOT_BEFORE_DATE%TYPE)
RETURN BOOLEAN IS
   L_active_date   DEAL_HEAD.ACTIVE_DATE%TYPE;
   L_table         VARCHAR2(30);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_EXIST is
      select active_date
        from deal_head
       where order_no = I_order_no;

   cursor C_LOCK_DEAL_HEAD is
      select 'x'
            from deal_head
       where order_no = I_order_no
             for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_EXIST', 'DEAL_HEAD', 'order no: '||TO_CHAR(I_order_no));
   open C_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_EXIST', 'DEAL_HEAD', 'order no: '||TO_CHAR(I_order_no));
   fetch C_EXIST into L_active_date;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_EXIST', 'DEAL_HEAD', 'order no: '||TO_CHAR(I_order_no));
   close C_EXIST;

   if I_not_before_date is NULL then
      o_error_message := SQL_LIB.CREATE_MSG('NO_UPDATE_NULL', 'deal_head', 'active_date', NULL);
      return FALSE;
   end if;

   if L_active_date != I_not_before_date then
      --- LOCK DEAL_HEAD
      L_table := 'DEAL_HEAD';
      open C_LOCK_DEAL_HEAD;
          close C_LOCK_DEAL_HEAD;

      --- UPDATE DEAL_HEAD WITH NEW DATE
      update DEAL_HEAD
         set active_date = I_not_before_date
       where order_no = I_order_no;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                L_table,
                                            to_char(I_order_no));
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                         'DEAL_VALIDATE_SQL.CHECK_PO_DEAL_DATES', to_char(SQLCODE));
      return FALSE;
END CHECK_PO_DEAL_DATES;
-------------------------------------------------------------------------------------------------------
FUNCTION DEAL_CALC_QUEUE_EXIST(O_error_message    IN OUT      VARCHAR2,
                               O_exist            IN OUT      BOOLEAN,
                               O_approved         IN OUT      VARCHAR2,
                               I_order_no         IN          DEAL_CALC_QUEUE.ORDER_NO%TYPE)
RETURN BOOLEAN IS
   L_exist    VARCHAR2(1)  := NULL;

   cursor C_EXIST is
      select 'x',
             order_appr_ind
        from deal_calc_queue
       where order_no = I_order_no;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_EXIST', 'DEAL_CALC_QUEUE', 'order no: '||TO_CHAR(I_order_no));
   open C_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_EXIST', 'DEAL_CALC_QUEUE', 'order no: '||TO_CHAR(I_order_no));
   fetch C_EXIST into L_exist,
                      O_approved;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_EXIST', 'DEAL_CALC_QUEUE', 'order no: '||TO_CHAR(I_order_no));
   close C_EXIST;

   if L_exist = 'x' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                         'DEAL_VALIDATE_SQL.DEAL_CALC_QUEUE_EXIST', to_char(SQLCODE));
      return FALSE;
END DEAL_CALC_QUEUE_EXIST;
-------------------------------------------------------------------------------------------------------
FUNCTION GET_DEAL_STATUS(O_error_message    IN OUT      VARCHAR2,
                         O_status           IN OUT      DEAL_HEAD.STATUS%TYPE,
                         I_order_no         IN          DEAL_HEAD.ORDER_NO%TYPE)
RETURN BOOLEAN IS

   cursor C_EXIST is
      select status
        from deal_head
       where order_no = I_order_no;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_EXIST', 'GET_DEAL_STATUS', 'order no: '||TO_CHAR(I_order_no));
   open C_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_EXIST', 'GET_DEAL_STATUS', 'order no: '||TO_CHAR(I_order_no));
   fetch C_EXIST into O_status;
   ---
   if C_EXIST%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_EXIST', 'GET_DEAL_STATUS', 'order no: '||TO_CHAR(I_order_no));
      close C_EXIST;
      o_error_message := SQL_LIB.CREATE_MSG('NO_DEAL_ORDER',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   else
      SQL_LIB.SET_MARK('CLOSE','C_EXIST', 'GET_DEAL_STATUS', 'order no: '||TO_CHAR(I_order_no));
      close C_EXIST;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                         'DEAL_VALIDATE_SQL.GET_DEAL_STATUS', to_char(SQLCODE));
      return FALSE;
END GET_DEAL_STATUS;
--------------------------------------------------------------------------------------------------------
FUNCTION DEAL_PROM_EXIST(O_error_message  IN OUT  VARCHAR2,
                         O_exists         IN OUT  BOOLEAN,
                         I_deal_id        IN      DEAL_PROM.DEAL_ID%TYPE,
                         I_promotion      IN      DEAL_PROM.PROMOTION%TYPE)
RETURN BOOLEAN IS

   L_exists      VARCHAR2(3);

   cursor C_GET_DEAL_PROM is
      select 'x'
        from deal_prom
       where deal_id = I_deal_id
         and promotion = I_promotion;

BEGIN
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_DEAL_PROM','DEAL_PROM_EXIST','DEAL ID: '||to_char(I_deal_id));
   open C_GET_DEAL_PROM;
   ---
   SQL_LIB.SET_MARK('FETCH','C_GET_DEAL_PROM','DEAL_PROM_EXIST','DEAL ID: '||to_char(I_deal_id));
   fetch C_GET_DEAL_PROM into L_exists;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_GET_DEAL_PROM', 'DEAL_PROM_EXIST','DEAL ID: '||to_char(I_deal_id));
   close C_GET_DEAL_PROM;
   ---
   if L_exists ='x' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_SQL.DEAL_PROM_EXIST',
                                            to_char(SQLCODE));
   return FALSE;
END DEAL_PROM_EXIST;
-------------------------------------------------------------------------------------------------------
FUNCTION TRAN_COMPONENT_DATE_OVERLAP(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                     O_exists          IN OUT   BOOLEAN,
                                     I_active_date     IN       DEAL_HEAD.ACTIVE_DATE%TYPE,
                                     I_close_date      IN       DEAL_HEAD.CLOSE_DATE%TYPE,
                                     I_supplier        IN       DEAL_HEAD.SUPPLIER%TYPE,
                                     I_deal_id         IN       DEAL_HEAD.DEAL_ID%TYPE,
                                     I_deal_type       IN       DEAL_HEAD.TYPE%TYPE)
RETURN BOOLEAN IS

   L_comp_active_date   DEAL_HEAD.ACTIVE_DATE%TYPE := NULL;
   L_comp_close_date    DEAL_HEAD.CLOSE_DATE%TYPE  := NULL;
   L_deal_type		DEAL_HEAD.TYPE%TYPE        := NULL;

   L_program            VARCHAR2(64) := 'DEAL_VALIDATE_SQL.TRAN_COMPONENT_DATE_OVERLAP';

   cursor C_CONFLICTING_DEAL is
      select h.active_date,
             h.close_date,
             h.type
        from deal_head h, deal_detail d
       where h.deal_id != I_deal_id
         and h.status = 'A'
         and h.supplier = I_supplier
         and h.deal_id = d.deal_id
         and tran_discount_ind = 'Y';
BEGIN

   O_exists := FALSE;
   ---
   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_supplier',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_active_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_active_date',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   --- Loop through the dates for the transaction deal components
   SQL_LIB.SET_MARK('LOOP',
                    'C_CONFLICTING_DEAL',
                    'deal_detail, deal_head',
                    'deal_id: ' || I_deal_id);
   FOR C_get_comp_date_rec in C_CONFLICTING_DEAL LOOP
      ---
      L_comp_active_date := C_get_comp_date_rec.active_date;
      L_comp_close_date := C_get_comp_date_rec.close_date;
      L_deal_type        := C_get_comp_date_rec.type;
      ---
      if ((I_deal_type != 'O') or (I_deal_type = 'O' and L_deal_type != 'O')) then
         if I_close_date is NULL and L_comp_close_date is NULL then
            O_exists := TRUE;
            EXIT;
         elsif I_close_date is NULL and L_comp_close_date is NOT NULL then
            if ((I_active_date <= L_comp_active_date) OR
               (L_comp_close_date >= I_active_date)) then
               O_exists := TRUE;
               EXIT;
            end if;
         elsif I_close_date is NOT NULL and  L_comp_close_date is NULL then
            if I_close_date < L_comp_active_date then
               NULL;
            else
               O_exists := TRUE;
               EXIT;
            end if;
         elsif I_close_date is NOT NULL and L_comp_close_date is NOT NULL then
            if ((L_comp_active_date < I_active_date) and
               (L_comp_close_date < I_active_date)) then
               NULL;
            elsif ((L_comp_active_date > I_close_date) and
               (L_comp_close_date > I_close_date)) then
               NULL;
            else
               O_exists := TRUE;
               EXIT;
            end if;
         end if;
      else
         O_exists:=FALSE;
         EXIT;
      end if;
      ---
   END LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.TRAN_COMPONENT_DATE_OVERLAP',
                                             to_char(SQLCODE));
      return FALSE;
END TRAN_COMPONENT_DATE_OVERLAP;
------------------------------------------------------------
FUNCTION TRAN_LVL_COMP_EXISTS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exists          IN OUT   BOOLEAN,
                              I_deal_id         IN       DEAL_DETAIL.DEAL_ID%TYPE)
RETURN BOOLEAN IS

   L_exists    VARCHAR2(1);
   L_program   VARCHAR2(64) := 'DEAL_VALIDATE_SQL.TRAN_LVL_COMP_EXISTS';

   cursor C_GET_TRAN_LVL_COMP is
      select 'x'
        from deal_detail
       where deal_id = I_deal_id
         and tran_discount_ind = 'Y'
         and rownum = 1;

BEGIN

   if I_deal_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_deal_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TRAN_LVL_COMP',
                    'DEAL_DETAIL',
                    'DEAL ID: '||to_char(I_deal_id));
   open C_GET_TRAN_LVL_COMP;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TRAN_LVL_COMP',
                    'DEAL_DETAIL',
                    'DEAL ID: '||to_char(I_deal_id));
   fetch C_GET_TRAN_LVL_COMP into L_exists;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TRAN_LVL_COMP',
                    'DEAL_DETAIL',
                    'DEAL ID: '||to_char(I_deal_id));
   close C_GET_TRAN_LVL_COMP;
   ---
   if L_exists is not NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_VALIDATE_SQL.TRAN_LVL_COMP_EXISTS',
                                            to_char(SQLCODE));
   return FALSE;
END TRAN_LVL_COMP_EXISTS;
-------------------------------------------------------------------------------------------------------
FUNCTION CHECK_DEAL_PAST_DATE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              O_exists          IN OUT   BOOLEAN,
                              I_order_no        IN       ORDHEAD.ORDER_NO%TYPE)
RETURN BOOLEAN IS

   L_exists    VARCHAR2(1);
   L_vdate     PERIOD.VDATE%TYPE   := GET_VDATE;
   L_program   VARCHAR2(64) := 'DEAL_VALIDATE_SQL.CHECK_DEAL_PAST_DATE';

   cursor C_GET_APPROVED_DEAL is
      select 'x'
        from deal_head
       where order_no = I_order_no
         and status in ('A','S')
         and active_date < L_vdate;

BEGIN
   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            I_order_no,
                                            'NULL',
                                            'NULL');
      return FALSE;
   end if;

   open  C_GET_APPROVED_DEAL;
   fetch C_GET_APPROVED_DEAL into L_exists;
   close C_GET_APPROVED_DEAL;

   if L_exists is NOT NULL then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'DEAL_VALIDATE_SQL.CHECK_DEAL_PAST_DATE',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END;
-------------------------------------------------------------------------------------------------------
-- 09-May-2008 Nitin Kumar, nitin.kumar@in.tesco.com Mod N111 Begin
-------------------------------------------------------------------------------------------------------
-- Mod By      : Nitin Kumar, nitin.kumar@in.tesco.com
-- Mod Date    : 09-May-2008
-- Mod Ref     : ModN111
-- Mod Details : Added new function TSL_CHECK_COMMON_PRODUCT.This function will validate
--               if the exists Common Products for the passed Merchandise Hierarchy
--               (does not consider Merch Level 1 and 12).
--------------------------------------------------------------------------------------------------------
FUNCTION TSL_CHECK_COMMON_PRODUCT (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_exists          IN OUT   BOOLEAN,
                                   I_merch_level     IN       VARCHAR2,
                                   I_merch_value_1   IN       VARCHAR2,
                                   I_merch_value_2   IN       VARCHAR2,
                                   I_merch_value_3   IN       VARCHAR2)
   RETURN BOOLEAN is

    --
    L_program       VARCHAR2(100) := 'DEAL_VALIDATE_SQL.TSL_CHECK_COMMON_PRODUCT';
    L_dummy         VARCHAR2(1)   := NULL;
    --

    --This cursor will return a record if the exists Common Products for the passed Merchandise Hierarchy
    --(does not consider Merch Level 1 and 12)
    CURSOR C_EXISTS_COMMON_PRODUCT is
    select 'X'
      from v_item_master vim
     where vim.tsl_common_ind  = 'Y'
       and ((I_merch_level = 2 and vim.division    = I_merch_value_1) or
            (I_merch_level = 3 and vim.group_no    = I_merch_value_1) or
            (I_merch_level = 4 and vim.dept        = I_merch_value_1) or
            (I_merch_level = 5 and vim.dept        = I_merch_value_1
                               and vim.class       = I_merch_value_2) or
            (I_merch_level = 6 and vim.dept        = I_merch_value_1
                               and vim.class       = I_merch_value_2
                               and vim.subclass    = I_merch_value_3) or
            (I_merch_level = 7 and vim.item_parent = I_merch_value_1) or
            (I_merch_level = 8 and vim.item_parent = I_merch_value_1
                               and vim.diff_1      = I_merch_value_2) or
            (I_merch_level = 9 and vim.item_parent = I_merch_value_1
                               and vim.diff_2      = I_merch_value_2) or
            (I_merch_level =10 and vim.item_parent = I_merch_value_1
                               and vim.diff_3      = I_merch_value_2) or
            (I_merch_level =11 and vim.item_parent = I_merch_value_1
                               and vim.diff_4      = I_merch_value_2));

BEGIN
       --
      SQL_LIB.SET_MARK('OPEN',
                       'C_EXISTS_COMMON_PRODUCT',
                       'V_ITEM_MASTER',
                        NULL);
      open C_EXISTS_COMMON_PRODUCT;

      SQL_LIB.SET_MARK('FETCH',
                       'C_EXISTS_COMMON_PRODUCT',
                       'V_ITEM_MASTER',
                        NULL);
      fetch C_EXISTS_COMMON_PRODUCT into L_dummy;

      if C_EXISTS_COMMON_PRODUCT%FOUND then
         O_exists := TRUE;
      else
         O_exists := FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_EXISTS_COMMON_PRODUCT',
                       'V_ITEM_MASTER',
                        NULL);
      close C_EXISTS_COMMON_PRODUCT;

 return TRUE;

EXCEPTION
    when OTHERS then
       if C_EXISTS_COMMON_PRODUCT%ISOPEN then
          SQL_LIB.SET_MARK('CLOSE',
                           'V_ITEM_MASTER',
                           'DEAL_HEAD',
                            NULL);
          close C_EXISTS_COMMON_PRODUCT;
       end if;
       O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                              SQLERRM,
                                              L_program,
                                              TO_CHAR(SQLCODE));
          return FALSE;

END TSL_CHECK_COMMON_PRODUCT;
-- 09-May-2008 Nitin Kumar, nitin.kumar@in.tesco.com Mod N111 End
---------------------------------------------------------------------------------------------------------
-- 10-Jul-2009 Kumar/WiproEnabler Def#12191 Begin
--------------------------------------------------------------------------------------------------------
FUNCTION CHECK_PRICE_CHG_DEAL(O_error_message    IN OUT   VARCHAR2,
                              O_exists           IN OUT   BOOLEAN,
                              I_deal_id          IN       DEAL_HEAD.DEAL_ID%TYPE,
                              I_deal_detail_id   IN       DEAL_DETAIL.DEAL_DETAIL_ID%TYPE)
RETURN BOOLEAN IS
   L_exist    VARCHAR2(1);


   cursor C_PD_EXIST is
      select 'x'
        from rpm_price_change
       where deal_id = I_deal_id
         and deal_detail_id = nvl(I_deal_detail_id, deal_detail_id);

BEGIN
   O_exists := FALSE;
   ---


      SQL_LIB.SET_MARK('OPEN',
                       'C_PD_EXIST',
                       'RPM_PRICE_CHANGE',
                       'deal id: '||TO_CHAR(I_deal_id));
      open C_PD_EXIST;
      ---
      SQL_LIB.SET_MARK('FETCH',
                       'C_PD_EXIST',
                       'RPM_PRICE_CHANGE',
                       'deal id: '||TO_CHAR(I_deal_id));
      fetch C_PD_EXIST into L_exist;
         ---
         if C_PD_EXIST%FOUND then
            O_exists := TRUE;
         end if;
         ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_PD_EXIST',
                       'RPM_PRICE_CHANGE',
                       'deal id: '||TO_CHAR(I_deal_id));
      close C_PD_EXIST;
      ---


   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'DEAL_VALIDATE_SQL.CHECK_PRICE_CHG_DEAL',
                                            to_char(SQLCODE));
      return FALSE;
END ;
-------------------------------------------------------------------------------------------------------
-- 10-Jul-2009 Kumar/WiproEnabler Def#12191 End
-------------------------------------------------------------------------------------------------------
-- CR316 18-May-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com Begin
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_INT_CONTACT_EXISTS(O_error_message    IN OUT   VARCHAR2,
                                O_exists           IN OUT   BOOLEAN,
                                I_int_contact      IN       USER_ATTRIB.USER_NAME%TYPE)
RETURN BOOLEAN IS
   L_exist    VARCHAR2(1);
   L_program    VARCHAR2(64) := 'DEAL_VALIDATE_SQL.TSL_INT_CONTACT_EXISTS';

   -- Cursor Declaration
   cursor C_INT_CONT_EXIST is
      select 'x'
        from USER_ATTRIB
       where USER_NAME = I_int_contact;

BEGIN
   O_exists := FALSE;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_INT_CONT_EXIST',
                    'USER_ATTRIB',
                    'user name : '||TO_CHAR(I_int_contact));
   open C_INT_CONT_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_INT_CONT_EXIST',
                    'USER_ATTRIB',
                    'user name : '||TO_CHAR(I_int_contact));
   fetch C_INT_CONT_EXIST into L_exist;
   ---
   if C_INT_CONT_EXIST%FOUND then
      O_exists := TRUE;
   else
      O_error_message:= SQL_LIB.CREATE_MSG('TSL_INV_CONTACT');
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_INT_CONT_EXIST',
                    'USER_ATTRIB',
                    'user name : '||TO_CHAR(I_int_contact));
   close C_INT_CONT_EXIST;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END TSL_INT_CONTACT_EXISTS ;
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_DEAL_CNT(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                          O_rec_count      IN OUT  NUMBER,
                          I_deal_id        IN      DEAL_HEAD.DEAL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program    VARCHAR2(64) := 'DEAL_VALIDATE_SQL.TSL_GET_DEAL_CNT';

   CURSOR C_GET_CNT is
   select count(deal_id)
     from tsl_inv_deals
    where deal_id = I_deal_id;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CNT',
                    'tsl_inv_deals',
                    'Deal Id = ' ||I_deal_id);
   open C_GET_CNT;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CNT',
                    'tsl_inv_deals',
                    'Deal Id = ' ||I_deal_id);
   fetch C_GET_CNT into O_rec_count;

   if C_GET_CNT%NOTFOUND then
      O_rec_count := 0;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CNT',
                    'tsl_inv_deals',
                    'Deal Id = ' ||I_deal_id);
   close C_GET_CNT;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_DEAL_CNT;
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_GET_CNT_COST_CENTRE(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_rec_count      IN OUT  NUMBER)
   RETURN BOOLEAN IS
 L_program    VARCHAR2(64) := 'DEAL_VALIDATE_SQL.TSL_GET_CNT_COST_CENTRE';

   -- LT Defect NBS00017761 31-May-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com Begin
   -- Modified cursor to reurn if it does n't contain NULLs
   -- MrgNBS017783 03-Jun-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com Begin
   CURSOR C_GET_CNT is
   select count(t.rev_cost_centre)
     from tsl_debtor_area t,tsl_non_merch_code_head_roi tr
    where t.rev_cost_centre = tr.non_merch_code
      and t.debtor_area is NOT NULL;
   -- MrgNBS017783 03-Jun-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com End
   -- LT Defect NBS00017761 31-May-2010 Bhargavi Pujari,bharagavi.pujari@in.tesco.com End

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CNT',
                    'tsl_debtor_area',
                    NULL);
   open C_GET_CNT;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CNT',
                    'tsl_debtor_area',
                    NULL);
   fetch C_GET_CNT into O_rec_count;

   if C_GET_CNT%NOTFOUND then
      O_rec_count := 0;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CNT',
                    'tsl_debtor_area',
                    NULL);
   close C_GET_CNT;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_GET_CNT_COST_CENTRE;
-------------------------------------------------------------------------------------------------------
-- CR316 18-May-2010 Bhargavi Pujari, bharagavi.pujari@in.tesco.com End
-------------------------------------------------------------------------------------------------------
END DEAL_VALIDATE_SQL;
/

