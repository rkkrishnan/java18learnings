CREATE OR REPLACE PACKAGE BODY ITEMLIST_VALIDATE_SQL AS

-------------------------------------------------------------------
FUNCTION EXIST(	O_error_message	    IN OUT    VARCHAR2,
		I_skulist	    IN        NUMBER,
		O_exist		    IN OUT    BOOLEAN) RETURN BOOLEAN IS

   L_dummy	VARCHAR2(1);

   cursor C_EXIST is
	select 'x'
	from skulist_head
	where skulist = I_skulist;

BEGIN
   open C_EXIST;
   fetch C_EXIST into L_dummy;
   if C_EXIST%NOTFOUND then
	O_error_message := sql_lib.create_msg('INV_SKU_LIST',
						null,null,null);
	O_exist := FALSE;
   else
	O_exist := TRUE;
   end if;

   close C_EXIST;
   return TRUE;

EXCEPTION
   when OTHERS then
	O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                               SQLERRM,
                                               'ITEMLIST_VALIDATE_SQL.EXIST',
                                               to_char(SQLCODE));
	return FALSE;
END EXIST;
---------------------------------------------------------------------
FUNCTION CHECK_EDIT_EXISTS(O_error_message   IN OUT	VARCHAR2,
		           O_exist	     IN OUT	BOOLEAN,
                           I_itemlist        IN      SKULIST_HEAD.SKULIST%TYPE,
                           I_user_id         IN      SKULIST_HEAD.CREATE_ID%TYPE) RETURN BOOLEAN IS
   L_dummy VARCHAR2(1);

    cursor C_EDIT_EXIST is
    select 'Y'
      from skulist_head
     where skulist = I_itemlist
       and (create_id = I_user_id
        or user_security_ind = 'N');

BEGIN
   if I_itemlist is NULL or I_user_id is NULL then
      O_error_message := sql_lib.create_msg ('INVALID_PARM',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_EDIT_EXIST', 'SKULIST_HEAD', 'ITEMLIST_ID: '||I_itemlist);
   open C_EDIT_EXIST;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_EDIT_EXIST', 'SKULIST_HEAD', 'ITEMLIST_ID: '||I_itemlist);
   fetch C_EDIT_EXIST into L_dummy;
   ---
   if C_EDIT_EXIST%NOTFOUND then
      O_exist := FALSE;
   else
      O_exist := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_EDIT_EXIST', 'SKULIST_HEAD', 'ITEMLIST_ID: '||I_itemlist);
   close C_EDIT_EXIST;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             'ITEMLIST_VALIDATE_SQL.CHECK_EDIT_EXISTS',
                                             to_char(SQLCODE));
	return FALSE;
END CHECK_EDIT_EXISTS;
------------------------------------------------------------------------------------------------
-- Function : valid_mu_items
-- Purpose  : Checks if atleast one valid MU item exists in the item list
-- Mod ref  : CR381
-- Mod date : 15-Mar-2011
-- Mod by   : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
------------------------------------------------------------------------------------------------
FUNCTION VALID_MU_ITEMS (O_error_message IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         I_itemlist      IN      SKULIST_HEAD.SKULIST%TYPE,
                         O_exists_ind    IN OUT  VARCHAR2)
RETURN BOOLEAN IS

   L_item ITEM_MASTER.ITEM%TYPE := NULL;

   cursor C_VALID_MU_EXIST is
   select sld.item
     from skulist_detail sld,
          item_master im
    where sld.skulist = I_itemlist
      and sld.item = im.item
      --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
      --DefNBS022406, commenting the below validation, as 'both' items also can be linked
      /*and NVL(im.tsl_country_auth_ind,'x') <> 'B'*/
      --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end
      and im.tsl_mu_ind = 'Y';

BEGIN

      SQL_LIB.SET_MARK('OPEN',
                       'C_VALID_MU_EXIST',
                       'SKULIST_DETAIL',
                       'ITEMLIST_ID: '||I_itemlist);
      open C_VALID_MU_EXIST;

      SQL_LIB.SET_MARK('FETCH',
                       'C_VALID_MU_EXIST',
                       'SKULIST_DETAIL',
                       'ITEMLIST_ID: '||I_itemlist);

      fetch C_VALID_MU_EXIST into L_item;

      if C_VALID_MU_EXIST%NOTFOUND then
         O_exists_ind := 'N';
      else
         O_exists_ind := 'Y';
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_VALID_MU_EXIST',
                       'SKULIST_DETAIL',
                       'ITEMLIST_ID: '||I_itemlist);

      close C_VALID_MU_EXIST;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             'ITEMLIST_VALIDATE_SQL.VALID_MU_ITEMS',
                                             to_char(SQLCODE));
	return FALSE;
END VALID_MU_ITEMS;
------------------------------------------------------------------------------------------------
-- Function : validate_mu_link
-- Purpose  : Validate Item-Location for linking
-- Mod ref  : DefNBS022076 (CR381)
-- Mod date : 25-Mar-2011
-- Mod by   : Chandrachooda, chandrachooda.hirannaiah@in.tesco.com
------------------------------------------------------------------------------------------------
FUNCTION VALIDATE_MU_LINK (O_error_message IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                           I_mu_item       IN      ITEM_MASTER.ITEM%TYPE,
                           I_std_item      IN      ITEM_MASTER.ITEM%TYPE,
                           I_store         IN      STORE.STORE%TYPE)
RETURN BOOLEAN IS

   L_mu_item                ITEM_MASTER.ITEM%TYPE;
   L_mu_auth_country        ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
   L_std_item_status        ITEM_MASTER.STATUS%TYPE;
   L_std_auth_country       ITEM_MASTER.TSL_COUNTRY_AUTH_IND%TYPE;
   L_entity_id              TSF_ENTITY.TSF_ENTITY_ID%TYPE;
   L_entity_desc            TSF_ENTITY.TSF_ENTITY_DESC%TYPE;
   L_store_country          VARCHAR2(1);


   cursor C_VALID_MU_ITEM is
   select im.item,
          im.tsl_country_auth_ind
     from item_master im
    where im.item = I_mu_item
      and im.tsl_mu_ind = 'Y'
      and im.item_level = 2
      and im.tran_level = 2
      --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com begin
      --DefNBS022406, commenting the below validation, as 'both' items also can be linked
      and im.pack_ind = 'N';
      /*and NVL(im.tsl_country_auth_ind,'x') <> 'B';*/
      --DefNBS022406, 26-Apr-2011, Chandrachooda, chandrachooda.hirannaiah@in.tesco.com end

   cursor C_GET_STD_ITEM is
   select im.status,
          im.tsl_country_auth_ind
     from item_master im
    where im.item = I_std_item;

BEGIN

   --check I_mu_item for valid MU TPNB
   SQL_LIB.SET_MARK('OPEN',
                    'C_VALID_MU_ITEM',
                    'ITEM_MASTER',
                    'ITEM: '||I_mu_item);
   open C_VALID_MU_ITEM;

   SQL_LIB.SET_MARK('FETCH',
                    'C_VALID_MU_ITEM',
                    'ITEM_MASTER',
                    'ITEM: '||I_mu_item);

   fetch C_VALID_MU_ITEM into L_mu_item, L_mu_auth_country;

   if C_VALID_MU_ITEM%NOTFOUND then
	    O_error_message := sql_lib.get_message_text('TSL_NOT_VALID_MU_TPNB',	null,null,null);
      return FALSE;
   end if;

   --check I_std_item for approval state
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_STD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: '||I_mu_item);
   open C_GET_STD_ITEM;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_STD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: '||I_mu_item);

   fetch C_GET_STD_ITEM into L_std_item_status, L_std_auth_country;

   if L_std_item_status <> 'A' then
   	  O_error_message := sql_lib.get_message_text('ITEM_STATUS',	null,null,null);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_STD_ITEM',
                    'ITEM_MASTER',
                    'ITEM: '||I_mu_item);
   close C_GET_STD_ITEM;

   --get the store country
	 if LOCATION_ATTRIB_SQL.GET_ENTITY (O_error_message,
	                                    L_entity_id,
	                                    L_entity_desc,
	                                    I_store,
	                                    'S') = FALSE then
	    return FALSE;
	 end if;
	 ---
	 if L_entity_id = 1 then
	    L_store_country := 'U';
	 elsif L_entity_id = 2 then
	    L_store_country := 'R';
	 end if;
	 ---
   ---check the logic for MU-TPNB-store linking
   if L_mu_auth_country in ('U') and L_std_auth_country in ('R') then
      O_error_message := sql_lib.get_message_text('TSL_INV_MU_LINK', 'UK', 'UK or BOTH', 'UK');
      return FALSE;
   elsif L_mu_auth_country in ('R') and L_std_auth_country in ('U') then
      O_error_message := sql_lib.get_message_text('TSL_INV_MU_LINK', 'ROI', 'ROI or BOTH', 'ROI');
      return FALSE;
   end if;

   --DefNBS022481, 04-May-2011, Chandrachooda, Chandrachooda.Hirannaiah@in.tesco.com begin
   if L_mu_auth_country in ('U') then
      if (L_std_auth_country in ('U') and L_store_country in ('R')) then
         O_error_message := sql_lib.get_message_text('TSL_INV_MU_STR_LINK', 'UK', 'UK', 'ROI');
      end if;
   end if;
   if L_mu_auth_country in ('R') then
      if (L_std_auth_country in ('R') and L_store_country in ('U')) then
         O_error_message := sql_lib.get_message_text('TSL_INV_MU_STR_LINK', 'ROI', 'ROI', 'UK');
      end if;
   end if;
   if L_mu_auth_country in ('B') then
      if (L_std_auth_country in ('U') and L_store_country in ('R')) then
         O_error_message := sql_lib.get_message_text('TSL_INV_MU_STR_LINK', 'BOTH', 'UK', 'ROI');
      end if;
      if (L_std_auth_country in ('R') and L_store_country in ('U')) then
         O_error_message := sql_lib.get_message_text('TSL_INV_MU_STR_LINK', 'BOTH', 'ROI', 'UK');
      end if;
   end if;

   /*
   if L_store_country = 'U' and L_mu_auth_country in ('R') then
      O_error_message := sql_lib.get_message_text('TSL_INV_MU_STORE_LINK', 'ROI', 'UK', null);
      return FALSE;
   elsif L_store_country = 'R' and L_mu_auth_country in ('U') then
      O_error_message := sql_lib.get_message_text('TSL_INV_MU_STORE_LINK', 'UK', 'ROI', null);
      return FALSE;
   end if;
   */
   --DefNBS022481, 04-May-2011, Chandrachooda, Chandrachooda.Hirannaiah@in.tesco.com end

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg ('PACKAGE_ERROR',
                                             SQLERRM,
                                             'ITEMLIST_VALIDATE_SQL.VALIDATE_MU_LINK',
                                             to_char(SQLCODE));
	return FALSE;
END VALIDATE_MU_LINK;
------------------------------------------------------------------------------------------------

END ITEMLIST_VALIDATE_SQL;
/

