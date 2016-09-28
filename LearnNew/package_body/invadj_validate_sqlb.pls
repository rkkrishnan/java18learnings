CREATE OR REPLACE PACKAGE BODY INVADJ_VALIDATE_SQL AS
---------------------------------------------------------------------------------------------
FUNCTION ITEM_EXIST (I_item              IN      ITEM_MASTER.ITEM%TYPE,
                     O_item_desc         IN OUT  ITEM_MASTER.DESC_UP%TYPE,
                     O_error_message     IN OUT  VARCHAR2,
                     O_found             IN OUT  BOOLEAN)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_VALIDATE_SQL.ITEM_EXIST';

   cursor C_ITEM is
      select initcap(desc_up)
        from item_master
       where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_ITEM','ITEM_MASTER',' ITEM: '||I_item);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH','C_ITEM','ITEM_MASTER',' ITEM: '||I_item);
   fetch C_ITEM into O_item_desc;
   ---
   if C_ITEM%NOTFOUND then
      O_found := FALSE;
   else
      O_found := TRUE;
      if LANGUAGE_SQL.TRANSLATE(O_item_desc,
                                O_item_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_ITEM','ITEM_MASTER',' ITEM: '||I_item);
   close C_ITEM;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END ITEM_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION REASON_EXIST (I_reason         IN      INV_ADJ_REASON.REASON%TYPE,
                       O_reason_desc    IN OUT  INV_ADJ_REASON.REASON_DESC%TYPE,
                       O_error_message  IN OUT  VARCHAR2,
                       O_found          IN OUT  BOOLEAN)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INV_SQL.REASON_EXIST';

   cursor C_REASON is
      select reason_desc
        from inv_adj_reason
       where reason = I_reason;

BEGIN
   O_found := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_REASON','INV_ADJ_REASON',' REASON: '||I_reason);
   open C_REASON;
   SQL_LIB.SET_MARK('FETCH','C_REASON','INV_ADJ_REASON',' REASON: '||I_reason);
   fetch C_REASON into O_reason_desc;
   if C_REASON%NOTFOUND then
      O_found := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_REASON','INV_ADJ_REASON',' REASON: '||I_reason);
   close C_REASON;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_reason_desc,
                             O_reason_desc,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END REASON_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION LOCATION_EXIST (I_location             IN      ITEM_LOC_SOH.LOC%TYPE,
                         I_item                 IN      ITEM_MASTER.ITEM%TYPE,
                         I_loc_type             IN      INV_ADJ.LOC_TYPE%TYPE,
                         I_inv_status           IN      INV_STATUS_QTY.INV_STATUS%TYPE,
                         O_location_desc        IN OUT  PARTNER.PARTNER_DESC%TYPE,
                         O_stock_on_hand        IN OUT  ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         O_error_message        IN OUT  VARCHAR2,
                         O_found                IN OUT  BOOLEAN)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_VALIDATE_SQL.LOCATION_EXIST';

BEGIN
   if I_loc_type = 'S' then
      if STORE_ATTRIB_SQL.GET_NAME(O_error_message,
                                   I_location,
                                   O_location_desc) = FALSE then
         return FALSE;
      end if;
   elsif I_loc_type = 'W' then
      if WH_ATTRIB_SQL.GET_NAME(O_error_message,
                                I_location,
                                O_location_desc) = FALSE then
         return FALSE;
      end if;
   elsif I_loc_type = 'E' then
      if PARTNER_SQL.GET_DESC(O_error_message,
                              O_location_desc,
                              I_location,
                              'E') = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if INVADJ_VALIDATE_SQL.ITEM_LOC_EXIST(I_item,
                                         I_location,
                                         I_loc_type,
                                         I_inv_status,
                                         O_stock_on_hand,
                                         O_error_message,
                                         O_found) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END LOCATION_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION ITEM_LOC_EXIST (I_item          IN      ITEM_MASTER.ITEM%TYPE,
                         I_location      IN      ITEM_LOC_SOH.LOC%TYPE,
                         I_loc_type      IN      ITEM_LOC_SOH.LOC_TYPE%TYPE,
                         I_inv_status    IN      INV_ADJ.INV_STATUS%TYPE,
                         O_stock_on_hand IN OUT  ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         O_error_message IN OUT  VARCHAR2,
                         O_found         IN OUT  BOOLEAN)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'INVADJ_VALIDATE_SQL.ITEM_LOC_EXIST';

   cursor C_SOH is
      select stock_on_hand
        from item_loc_soh
       where loc_type = decode(I_loc_type, 'I', 'W', I_loc_type)
         and loc      = I_location
         and item     = I_item;

   cursor C_INV_STATUS_QTY is
      select qty
        from inv_status_qty
       where item       = I_item
         and inv_status = I_inv_status
         and location   = I_location;

BEGIN
   O_found := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
   open C_SOH;
   SQL_LIB.SET_MARK('FETCH','C_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
   fetch C_SOH into O_stock_on_hand;
   ---
   if C_SOH%NOTFOUND then
      O_found := FALSE;
   end if;
   ---

   SQL_LIB.SET_MARK('CLOSE','C_SOH','ITEM_LOC_SOH','Item: '||I_item||' Loc: '||to_char(I_location));
   close C_SOH;
   ---
   if I_inv_status != 0 then
      SQL_LIB.SET_MARK('OPEN','C_INV_STATUS_QTY','INV_STATUS_QTY',
                       ' Item: '||I_item||' INV_STATUS: '||
                       to_char(I_inv_status)||' LOCATION: '||to_char(I_location));
      open C_INV_STATUS_QTY;
      SQL_LIB.SET_MARK('FETCH','C_INV_STATUS_QTY','INV_STATUS_QTY',
                       ' Item: '||I_item||' INV_STATUS: '||
                       to_char(I_inv_status)||' LOCATION: '||to_char(I_location));
      fetch C_INV_STATUS_QTY into O_stock_on_hand;
      ---
      if C_INV_STATUS_QTY%NOTFOUND then
         O_stock_on_hand := 0;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_INV_STATUS_QTY','INV_STATUS_QTY',
                       ' Item: '||I_item||' INV_STATUS: '||
                       to_char(I_inv_status)||' LOCATION: '||to_char(I_location));
      close C_INV_STATUS_QTY;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END ITEM_LOC_EXIST;
---------------------------------------------------------------------------------------------
FUNCTION CHECK_INV_STATUS_EXIST (I_inv_status        IN      INV_STATUS_TYPES.INV_STATUS%TYPE,
                                 O_error_message     IN OUT  VARCHAR2,
                                 O_found             IN OUT  BOOLEAN)
   RETURN BOOLEAN IS

   L_dummy VARCHAR2(1);
   L_program  VARCHAR2(64) := 'INVENTORY_STATUS_SQL.CHECK_INV_STATUS_EXIST';

   cursor C_INV_STATUS is
      select 'x'
        from INV_STATUS_TYPES
       where inv_status = I_inv_status;

BEGIN
   O_found := FALSE;
   ---
   open  C_INV_STATUS;
   fetch C_INV_STATUS into L_dummy;
   if C_INV_STATUS%FOUND then
      O_found := TRUE;
   end if;
   close C_INV_STATUS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END CHECK_INV_STATUS_EXIST;
-------------------------------------------------------------------------------------------
FUNCTION INV_STATUS_CONSTRAINTS_EXIST (I_foreign_constraints IN      INV_STATUS_TYPES.INV_STATUS%TYPE,
                                       O_error_message       IN OUT  VARCHAR2,
                                       O_found               IN OUT  BOOLEAN)
   RETURN BOOLEAN IS

   L_program               VARCHAR2(64) := 'INVENTORY_STATUS_SQL.INV_STATUS_CONSTRAINTS_EXIST';
   L_foreign_constraints   VARCHAR2(1);

   cursor C_FOREIGN_CONSTRAINTS is
      select 'x'
        from inv_status_qty
       where inv_status = I_foreign_constraints;
BEGIN
   O_found := FALSE;
   ---
   open C_FOREIGN_CONSTRAINTS;
   fetch C_FOREIGN_CONSTRAINTS into L_Foreign_Constraints;
   if C_FOREIGN_CONSTRAINTS%FOUND then
      O_found := TRUE;
   end if;
   close C_FOREIGN_CONSTRAINTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END INV_STATUS_CONSTRAINTS_EXIST;
-----------------------------------------------------------------------------------------------
FUNCTION CHECK_INV_REASON_EXIST (I_reason         IN      INV_ADJ_REASON.REASON%TYPE,
                                 O_error_message  IN OUT  VARCHAR2,
                                 O_found          IN OUT  BOOLEAN)
   RETURN BOOLEAN IS

   L_program  VARCHAR2(64) := 'ITEM_LOC_INVENTORY_SQL.CHECK_INV_REASON_EXIST';
   L_dummy    VARCHAR2(1);

   cursor C_INV_REASON is
      select 'x'
        from inv_adj_reason
       where reason = I_reason;
BEGIN
   O_found := FALSE;
   ---
   open  C_INV_REASON;
   fetch C_INV_REASON into L_dummy;
   if C_INV_REASON%FOUND then
      O_found := TRUE;
   end if;
   ---
   close C_INV_REASON;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END CHECK_INV_REASON_EXIST;
-------------------------------------------------------------------------------------
FUNCTION INV_REASON_CONSTRAINTS_EXIST(I_foreign_constraints  IN      INV_ADJ_REASON.REASON%TYPE,
                                      O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                      O_found                IN OUT  BOOLEAN)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_LOC_INVENTORY_SQL.INV_REASON_CONSTRAINTS_EXIST';
   L_constraints_found    VARCHAR2(1)  := 'N';

   cursor C_FOREIGN_CONSTRAINTS_REASON is
      select 'Y'
        from inv_adj
       where reason = I_foreign_constraints
         and rownum = 1
       union all
      select 'Y'
        from fif_gl_cross_ref
       where tran_code in (22,23)
         and tran_ref_no = I_foreign_constraints
         and rownum = 1;

BEGIN

   if I_foreign_constraints is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM_IN_FUNC',
                                            'I_foreign_constraints',
                                            'NULL',
                                            L_program);
      return FALSE;
   end if;

   open  C_FOREIGN_CONSTRAINTS_REASON;
   fetch C_FOREIGN_CONSTRAINTS_REASON into L_constraints_found;
   close C_FOREIGN_CONSTRAINTS_REASON;

   O_found := (L_constraints_found = 'Y');

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END INV_REASON_CONSTRAINTS_EXIST;
--------------------------------------------------------------------------------------
END INVADJ_VALIDATE_SQL;
/

