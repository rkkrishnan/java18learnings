CREATE OR REPLACE PACKAGE BODY CONTRACT_SQL AS
----------------------------------------------------------------------------------------
FUNCTION SUBMIT_CONTRACT(O_error_message  IN OUT VARCHAR2,
                         I_contract_type  IN     CONTRACT_HEADER.CONTRACT_TYPE%TYPE,
                         I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   RETURN BOOLEAN IS

L_soft_contract_ind     system_options.soft_contract_ind%TYPE;
L_detl                  VARCHAR2(1) := 'N';
L_contract_type_A       VARCHAR2(1) := 'N';
L_cost                  VARCHAR2(1) := 'N';
L_contract_type_B       VARCHAR2(1) := 'N';
L_qty_contracted        VARCHAR2(1) := 'N';
L_non_tran_lvl_items    VARCHAR2(1) := 'N';

cursor C_SYSTEM_IND is
   select soft_contract_ind
     from system_options;

cursor C_CONTRACT_DETL is
   select 'Y'
     from contract_detail
    where contract_no = I_contract_no
      and item is NULL;

cursor C_CONTRACT_COST is
   select 'Y'
     from contract_cost
    where contract_no = I_contract_no
      and item is NULL;

cursor C_CONTRACT_TYPE_A is
   select 'Y'
     from contract_detail
    where ready_date is NULL
      and contract_no = I_contract_no;

cursor C_CONTRACT_TYPE_B is
   select 'Y'
     from contract_detail
    where (location is NULL
       or ready_date is NULL)
      and contract_no = I_contract_no;

cursor C_CONTRACT_QTY is
   select 'Y'
     from contract_detail
    where contract_no = I_contract_no
      and qty_contracted < 1;

cursor C_CONTRACT_TRAN_ITEMS  is
   select 'Y'
     from contract_detail
    where contract_no = I_contract_no
      and item is NULL;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_CONTRACT_QTY','contract_detail',
                    NULL);
   open C_CONTRACT_QTY;

   SQL_LIB.SET_MARK('FETCH','C_CONTRACT_QTY','contract_detail',
                    NULL);
   fetch C_CONTRACT_QTY into L_qty_contracted;
   if C_CONTRACT_QTY%FOUND then
      O_error_message := SQL_LIB.CREATE_MSG('QTY_CONTRACTED',
                                               NULL,
                                               NULL,
                                               NULL);
      SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_QTY','contract_detail',
                       NULL);
      close C_CONTRACT_QTY;
      RETURN FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_QTY','contract_detail',
                    NULL);
   close C_CONTRACT_QTY;
   ---
   SQL_LIB.SET_MARK('OPEN','C_SYSTEM_IND','system_options',
                    NULL);
   open C_SYSTEM_IND;

   SQL_LIB.SET_MARK('FETCH','C_SYSTEM_IND','system_options',
                    NULL);
   fetch C_SYSTEM_IND into L_soft_contract_ind;

   SQL_LIB.SET_MARK('CLOSE','C_SYSTEM_IND','system_options',
                    NULL);
   close C_SYSTEM_IND;

   if L_soft_contract_ind = 'N' then
      if I_contract_type in ('A','B') then
         SQL_LIB.SET_MARK('OPEN','C_CONTRACT_DETL','contract_detail',
                          'Contract_no: '||to_char(I_contract_no));
         open C_CONTRACT_DETL;
         SQL_LIB.SET_MARK('FETCH','C_CONTRACT_DETL','contract_detail',
                          'Contract_no: '||to_char(I_contract_no));
         fetch C_CONTRACT_DETL INTO L_detl;
         SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_DETL','contract_detail',
                          'Contract_no: '||to_char(I_contract_no));
         close C_CONTRACT_DETL;

      elsif I_contract_type in ('C','D') then
         SQL_LIB.SET_MARK('OPEN','C_CONTRACT_COST','contract_cost',
                          'Contract_no: '||to_char(I_contract_no));
         open C_CONTRACT_COST;

         SQL_LIB.SET_MARK('FETCH','C_CONTRACT_COST','contract_cost',
                          'Contract_no: '||to_char(I_contract_no));
         fetch C_CONTRACT_COST into L_cost;

         SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_COST','contract_cost',
                          'Contract_no: '||to_char(I_contract_no));
         close C_CONTRACT_COST;

      end if;
      ---
      if L_detl = 'Y' or L_cost = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('CONTRACT_RECS_FIRMED_UP',
                                               NULL,
                                               NULL,
                                               NULL);

           RETURN FALSE;
      end if;
   end if;

   if I_contract_type = 'A' then
      SQL_LIB.SET_MARK('OPEN','C_CONTRACT_TYPE_A','contract_detail',
                       'Contract_no: '||to_char(I_contract_no));
      open C_CONTRACT_TYPE_A;

      SQL_LIB.SET_MARK('FETCH','C_CONTRACT_TYPE_A','contract_detail',
                       'Contract_no: '||to_char(I_contract_no));
      fetch C_CONTRACT_TYPE_A INTO L_contract_type_A;

      SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_TYPE_A','contract_detail',
                       'Contract_no: '||to_char(I_contract_no));
      close C_CONTRACT_TYPE_A;

      if L_contract_type_A = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('CONTRACT_TYPE_A',
                                               NULL,
                                               NULL,
                                               NULL);

         RETURN FALSE;
      end if;

   elsif I_contract_type = 'B' then
      SQL_LIB.SET_MARK('OPEN','C_CONTRACT_TYPE_B','contract_detail',
                       'Contract_no: '||to_char(I_contract_no));
      open C_CONTRACT_TYPE_B;

      SQL_LIB.SET_MARK('FETCH','C_CONTRACT_TYPE_B','contract_detail',
                       'Contract_no: '||to_char(I_contract_no));
      fetch C_CONTRACT_TYPE_B into L_contract_type_B;

      SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_TYPE_B','contract_detail',
                       'Contract_no: '||to_char(I_contract_no));
      close C_CONTRACT_TYPE_B;

      if L_contract_type_B = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('CONTRACT_TYPE_B',
                                               NULL,
                                               NULL,
                                               NULL);

         RETURN FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN','C_CONTRACT_TRAN_ITEMS','contract_detail',
                    NULL);
      open C_CONTRACT_TRAN_ITEMS;
      SQL_LIB.SET_MARK('FETCH','C_CONTRACT_TRAN_ITEMS','contract_detail',
                       NULL);
      fetch C_CONTRACT_TRAN_ITEMS into L_non_tran_lvl_items;
      SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_TRAN_ITEMS','contract_detail',
                       NULL);
      close C_CONTRACT_TRAN_ITEMS;

      if L_non_tran_lvl_items = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('CONTRACT_TYPE_B_TRAN_LVL',
                                               NULL,
                                               NULL,
                                               NULL);

         RETURN FALSE;
      end if;
   end if;
   RETURN TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'CONTRACT_SQL.SUBMIT_CONTRACT',
                                             TO_CHAR(sqlcode));
   RETURN FALSE;

END SUBMIT_CONTRACT;
-----------------------------------------------------------------------------
FUNCTION CALC_CONTRACT_TOTALS (O_error_message    IN OUT   VARCHAR2,
                               I_contract_no      IN       CONTRACT_HEADER.CONTRACT_NO%TYPE,
                               O_outstand_cost    IN OUT   CONTRACT_HEADER.OUTSTAND_COST%TYPE,
                               O_total_cost       IN OUT   CONTRACT_HEADER.TOTAL_COST%TYPE,
                               O_total_retail     IN OUT   ORDLOC.UNIT_RETAIL%TYPE)
return BOOLEAN is

   L_unit_cost                 CONTRACT_COST.UNIT_COST%TYPE;
   L_unit_cost_prim            CONTRACT_COST.UNIT_COST%TYPE;
   L_unit_retail_prim          ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE         := NULL;
   L_standard_uom_prim         ITEM_MASTER.STANDARD_UOM%TYPE            := NULL;
   L_selling_unit_retail_prim  ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE := NULL;
   L_selling_uom_prim          ITEM_ZONE_PRICE.SELLING_UOM%TYPE         := NULL;
   L_vat_ind                   SYSTEM_OPTIONS.VAT_IND%TYPE              := NULL;
   L_class_level_vat_ind       SYSTEM_OPTIONS.CLASS_LEVEL_VAT_IND%TYPE  := NULL;
   L_class_vat_ind             CLASS.CLASS_VAT_IND%TYPE                 := NULL;
   L_default_vat_region        SYSTEM_OPTIONS.DEFAULT_VAT_REGION%TYPE   := NULL;
   L_vat_rate                  VAT_ITEM.VAT_RATE%TYPE                   := NULL;
   L_vat_code                  VAT_ITEM.VAT_CODE%TYPE                   := NULL;
   L_dept                      DEPS.DEPT%TYPE                           := NULL;
   L_class                     CLASS.CLASS%TYPE                         := NULL;
   L_subclass                  SUBCLASS.SUBCLASS%TYPE                   := NULL;
   L_cont_curr				   CONTRACT_HEADER.CURRENCY_CODE%TYPE;

   cursor C_CONTRACT_DETAIL is
      select item,
             item_parent,
             item_grandparent,
             diff_1,
             diff_2,
             diff_3,
             diff_4,
             qty_contracted,
             NVL(qty_ordered,0) qty_ordered
        from contract_detail
       where contract_no = I_contract_no;

   cursor C_DEFAULT_VAT_REGION is
      select default_vat_region
        from system_options;
BEGIN
   O_outstand_cost   := 0;
   O_total_cost      := 0;
   O_total_retail    := 0;
   ---
   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_DEFAULT_VAT_REGION', 'SYSTEM_OPTIONS', NULL);
   open C_DEFAULT_VAT_REGION;
   SQL_LIB.SET_MARK('FETCH', 'C_DEFAULT_VAT_REGION', 'SYSTEM_OPTIONS', NULL);
   fetch C_DEFAULT_VAT_REGION into L_default_vat_region;
   SQL_LIB.SET_MARK('CLOSE', 'C_DEFAULT_VAT_REGION', 'SYSTEM_OPTIONS', NULL);
   close C_DEFAULT_VAT_REGION;
   ---
   if L_vat_ind = 'Y' then
      if SYSTEM_OPTIONS_SQL.GET_CLASS_LEVEL_VAT_IND(O_error_message,
                                                    L_class_level_vat_ind) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   FOR C_rec in C_CONTRACT_DETAIL LOOP
      if CONTRACT_SQL.GET_UNIT_COST(O_error_message,
                                    C_rec.item,
                                    I_contract_no,
                                    L_unit_cost,
                                    C_rec.diff_1,
                                    C_rec.diff_2,
                                    C_rec.diff_3,
                                    C_rec.diff_4,
                                    C_rec.item_parent,
                                    C_rec.item_grandparent) = FALSE then
         return FALSE;
      end if;
      O_total_cost    := O_total_cost + (L_unit_cost * C_rec.qty_contracted);
      O_outstand_cost := O_outstand_cost + (L_unit_cost * (C_rec.qty_contracted - C_rec.qty_ordered));

      ---
      if ((L_vat_ind = 'Y') and (L_class_level_vat_ind = 'Y')) then
         if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                           nvl(C_rec.item, (nvl(C_rec.item_parent, C_rec.item_grandparent))),
                                           L_dept,
                                           L_class,
                                           L_subclass) = FALSE then
            return FALSE;
         end if;
         ---
         if CLASS_ATTRIB_SQL.GET_CLASS_VAT_IND(O_error_message,
                                               L_class_vat_ind,
                                               L_dept,
                                               L_class) = FALSE then
            return FALSE;
         end if;
         ---
      end if;
      ---
      if ((L_vat_ind = 'Y') and (L_class_level_vat_ind = 'Y') and (L_class_vat_ind = 'N')) then
         if VAT_SQL.GET_VAT_RATE(O_error_message,
                                 L_default_vat_region,
                                 L_vat_code,
                                 L_vat_rate,
                                 nvl(C_rec.item, (nvl(C_rec.item_parent, C_rec.item_grandparent))),
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 'R') = FALSE then
            return FALSE;
         end if;
      else
         L_vat_rate := 0;
      end if;
      ---
      if ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL(O_error_message,
                                              L_unit_cost_prim,
                                              L_unit_retail_prim,
                                              L_standard_uom_prim,
                                              L_selling_unit_retail_prim,
                                              L_selling_uom_prim,
                                              nvl(C_rec.item, (nvl(C_rec.item_parent,
                                                                   C_rec.item_grandparent))),
                                                  'R') = FALSE then

         return FALSE;
      end if;
      ---
      L_unit_retail_prim := L_unit_retail_prim * (1 + (L_vat_rate/100));
      ---
      O_total_retail := O_total_retail + (L_unit_retail_prim * C_rec.qty_contracted);
   END LOOP;

   If NOT GET_CURRENCY_CODE(O_error_message,
                            L_cont_curr,
                            I_contract_no) then
	 return false;
   End if;

   if CURRENCY_SQL.CONVERT(O_error_message,
                               O_total_retail,
                               null,
                               L_cont_curr,
                               O_total_retail,
                              'R',
                              NULL,
                              NULL) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'CONTRACT_SQL.CALC_CONTRACT_TOTALS',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CALC_CONTRACT_TOTALS;
-----------------------------------------------------------------------------
FUNCTION GET_UNIT_COST(O_error_message IN OUT VARCHAR2,
                       I_item          IN     CONTRACT_COST.ITEM%TYPE,
                       I_contract_no   IN     CONTRACT_COST.CONTRACT_NO%TYPE,
                       O_cost          IN OUT CONTRACT_COST.UNIT_COST%TYPE)
RETURN BOOLEAN IS
BEGIN
   RETURN GET_UNIT_COST(O_error_message,
                        I_item,
                        I_contract_no,
                        O_cost,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL);
END;

FUNCTION GET_UNIT_COST(O_error_message    IN OUT VARCHAR2,
                       I_item             IN     CONTRACT_COST.ITEM%TYPE,
                       I_contract_no      IN     CONTRACT_COST.CONTRACT_NO%TYPE,
                       O_cost             IN OUT CONTRACT_COST.UNIT_COST%TYPE,
                       I_diff_1           IN     CONTRACT_COST.DIFF_1%TYPE,
                       I_diff_2           IN     CONTRACT_COST.DIFF_2%TYPE,
                       I_diff_3           IN     CONTRACT_COST.DIFF_3%TYPE,
                       I_diff_4           IN     CONTRACT_COST.DIFF_4%TYPE,
                       I_item_parent      IN     CONTRACT_COST.ITEM_PARENT%TYPE,
                       I_item_grandparent IN     CONTRACT_COST.ITEM_GRANDPARENT%TYPE)
RETURN BOOLEAN IS

   L_diff_1           CONTRACT_COST.DIFF_1%TYPE;
   L_diff_2           CONTRACT_COST.DIFF_2%TYPE;
   L_diff_3           CONTRACT_COST.DIFF_3%TYPE;
   L_diff_4           CONTRACT_COST.DIFF_4%TYPE;
   L_item_parent      CONTRACT_COST.ITEM_PARENT%TYPE;
   L_item_grandparent CONTRACT_COST.ITEM_GRANDPARENT%TYPE;

   cursor C_GET_ITEM_INFO is
      select item_parent,
             item_grandparent,
             diff_1,
             diff_2,
             diff_3,
             diff_4
        from item_master
       where item = I_item;

   cursor C_CC_ITEM is
      select cc.unit_cost
        from contract_cost cc
       where cc.contract_no = I_contract_no
         and cc.item        = I_item;

   cursor C_CC_ITEM_PARENT is
      select cc.unit_cost
        from contract_cost cc
       where cc.contract_no = I_contract_no
         and (  (     cc.item_level_index = 1
                  and cc.item             = I_item)
              or (cc.item_level_index = 2
                  and (   (    cc.item_parent = L_item_parent
                           and cc.diff_1      = L_diff_1)
                       or (    cc.item_grandparent = L_item_grandparent
                           and cc.diff_1           = L_diff_1)))
              or  (   cc.item_level_index = 3
                  and (   (    cc.item_parent = L_item_parent
                           and cc.diff_2      = L_diff_2)
                       or (    cc.item_grandparent = L_item_grandparent
                           and cc.diff_2           = L_diff_2)))
              or (    cc.item_level_index = 4
                  and (   (    cc.item_parent = L_item_parent
                           and cc.diff_3      = L_diff_3)
                       or (    cc.item_grandparent = L_item_grandparent
                           and cc.diff_3           = L_diff_3)))
              or (    cc.item_level_index = 5
                  and (   (    cc.item_parent = L_item_parent
                           and cc.diff_4      = L_diff_4)
                       or (    cc.item_grandparent = L_item_grandparent
                           and cc.diff_4           = L_diff_4)))
              or (    cc.item_level_index = 6
                  and (   cc.item_parent      = L_item_parent
                       or cc.item_grandparent = L_item_grandparent))
             )
     order by cc.item_level_index;

BEGIN
   L_item_parent      := I_item_parent;
   L_item_grandparent := I_item_grandparent;
   L_diff_1           := I_diff_1;
   L_diff_2           := I_diff_2;
   L_diff_3           := I_diff_3;
   L_diff_4           := I_diff_4;

   if(I_item is not NULL) then
      sql_lib.set_mark('OPEN','C_GET_ITEM_INFO','ITEM_MASTER','ITEM='||I_item);
      OPEN C_GET_ITEM_INFO;

      sql_lib.set_mark('FETCH','C_GET_ITEM_INFO','ITEM_MASTER','ITEM='||I_item);
      FETCH C_GET_ITEM_INFO INTO L_item_parent,
                                 L_item_grandparent,
                                 L_diff_1,
                                 L_diff_2,
                                 L_diff_3,
                                 L_diff_4;

      if (L_item_parent is NULL and L_item_grandparent is NULL) then
         sql_lib.set_mark('CLOSE','C_GET_ITEM_INFO','ITEM_MASTER','ITEM='||I_item);
         close C_GET_ITEM_INFO;

         sql_lib.set_mark('OPEN','C_CC_ITEM','CONTRACT_COST',
                          'ITEM='||I_item||'CONTRACT='||to_char(I_contract_no));
         OPEN C_CC_ITEM;

         sql_lib.set_mark('FETCH','C_CC_ITEM','CONTRACT_COST',
                          'ITEM='||I_item||'CONTRACT='||to_char(I_contract_no));
         FETCH C_CC_ITEM INTO O_cost;

         if C_CC_ITEM%NOTFOUND then
              O_error_message := sql_lib.create_msg('NOT_A_ITEM',I_item);
            sql_lib.set_mark('CLOSE','C_CC_ITEM','CONTRACT_COST',
                             'ITEM='||I_item||'CONTRACT='||to_char(I_contract_no));
            CLOSE C_CC_ITEM;
            RETURN FALSE;
         end if;

         sql_lib.set_mark('CLOSE','C_CC_ITEM','CONTRACT_COST',
                          'ITEM='||I_item||'CONTRACT='||to_char(I_contract_no));
         CLOSE C_CC_ITEM;
         RETURN TRUE;
      end if;
      sql_lib.set_mark('CLOSE','C_GET_ITEM_INFO','ITEM_MASTER','ITEM='||I_item);
      close C_GET_ITEM_INFO;

   end if;
   sql_lib.set_mark('OPEN','C_CC_ITEM_PARENT','CONTRACT_COST',
                    'ITEM='||I_item||'CONTRACT='||to_char(I_contract_no));
   OPEN C_CC_ITEM_PARENT;

   sql_lib.set_mark('FETCH','C_CC_ITEM_PARENT','CONTRACT_COST',
                    'ITEM='||I_item||'CONTRACT='||to_char(I_contract_no));
   FETCH C_CC_ITEM_PARENT INTO O_cost;

   if C_CC_ITEM_PARENT%NOTFOUND then
      O_error_message := sql_lib.create_msg('NOT_A_ITEM', I_item);
      sql_lib.set_mark('CLOSE','C_CC_ITEM_PARENT','CONTRACT_COST',
                       'ITEM='||I_item||'CONTRACT='||to_char(I_contract_no));
      CLOSE C_CC_ITEM_PARENT;
      RETURN FALSE;
   end if;

   sql_lib.set_mark('CLOSE','C_CC_ITEM_PARENT','CONTRACT_COST',
                    'ITEM='||I_item||'CONTRACT='||to_char(I_contract_no));
   CLOSE C_CC_ITEM_PARENT;

   RETURN TRUE;
EXCEPTION
  when OTHERS then
        O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                SQLERRM,
                'CONTRACT_SQL.GET_UNIT_COST',
                TO_CHAR(SQLCODE));
   RETURN FALSE;
END GET_UNIT_COST;
-----------------------------------------------------------------------------
FUNCTION LOCK_CONTRACT(O_error_message IN OUT VARCHAR2,
                       I_contract_no   IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
RETURN BOOLEAN IS
   L_table             VARCHAR2(30);
   RECORD_LOCKED       EXCEPTION;
   PRAGMA              EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK is
      select 'x'
        from contract_header
       where contract_no=I_contract_no
         for update nowait;
BEGIN
   L_table := 'CONTRACT_HEADER';

   sql_lib.set_mark('OPEN','C_lock','CONTRACT_HEADER',
                    'CONTRACT='||to_char(I_contract_no));
   OPEN C_LOCK;
   sql_lib.set_mark('CLOSE','C_lock','CONTRACT_HEADER',
                    'CONTRACT='||to_char(I_contract_no));
   CLOSE C_LOCK;
   RETURN TRUE;
EXCEPTION
 when RECORD_LOCKED then
        O_error_message:=sql_lib.create_msg('CONTRACT_LOCKED',to_char(I_contract_no));
    RETURN FALSE;
 when OTHERS then
        O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                SQLERRM,
                'CONTRACT_SQL.LOCK_CONTRACT',
                TO_CHAR(SQLCODE));
   RETURN FALSE;
END LOCK_CONTRACT;
-------------------------------------------------------------------------------------------------------
-- This function calculates the total_retail_excl_vat using the default vat on the system options
-- table, not per location.
--------------------------------------------------------------------------------------------------------
FUNCTION GET_RETAIL_EXCL_VAT(O_error_message            IN OUT  VARCHAR2,
                             O_total_retail_excl_vat    IN OUT  ORDLOC.UNIT_RETAIL%TYPE,
                             I_contract_no              IN      CONTRACT_HEADER.CONTRACT_NO%TYPE)

      return BOOLEAN is



   L_unit_rtl_excl_vat          ORDLOC.UNIT_RETAIL%TYPE := 0;
   L_vat_region                 VAT_ITEM.VAT_REGION%TYPE;
   L_vat_code                   VAT_ITEM.VAT_CODE%TYPE;
   L_vat_rate                   VAT_ITEM.VAT_RATE%TYPE;
   L_unit_cost_prim             CONTRACT_COST.UNIT_COST%TYPE;
   L_unit_retail_prim           ITEM_ZONE_PRICE.UNIT_RETAIL%TYPE := NULL;
   L_uom_prim                   ITEM_MASTER.STANDARD_UOM%TYPE;
   L_selling_unit_retail_prim   ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE := NULL;
   L_selling_uom_prim           ITEM_ZONE_PRICE.SELLING_UOM%TYPE := NULL;
   L_dept                       DEPS.DEPT%TYPE := NULL;
   L_class                      CLASS.CLASS%TYPE := NULL;
   L_subclass                   SUBCLASS.SUBCLASS%TYPE := NULL;
   L_class_level_vat_ind        SYSTEM_OPTIONS.CLASS_LEVEL_VAT_IND%TYPE := NULL;
   L_class_vat_ind              CLASS.CLASS_VAT_IND%TYPE := NULL;

   cursor C_DEFAULT_VAT is
      select default_vat_region
        from system_options;

   cursor C_GET_DETAILS is
      select item,
             item_parent,
             item_grandparent,
             qty_contracted
        from contract_detail
       where contract_no = I_contract_no;

BEGIN
   O_total_retail_excl_vat := 0;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_DEFAULT_VAT', 'SYSTEM_OPTIONS', NULL);
   open C_DEFAULT_VAT;
   SQL_LIB.SET_MARK('FETCH', 'C_DEFAULT_VAT', 'SYSTEM_OPTIONS', NULL);
   fetch C_DEFAULT_VAT into L_vat_region;
   SQL_LIB.SET_MARK('CLOSE', 'C_DEFAULT_VAT', 'SYSTEM_OPTIONS', NULL);
   close C_DEFAULT_VAT;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_GET_DETAILS', 'CONTRACT_DETAIL', 'contract_no: '||to_char(I_contract_no));
   SQL_LIB.SET_MARK('FETCH', 'C_GET_DETAILS', 'CONTRACT_DETAIL', 'contract_no: '||to_char(I_contract_no));
   for C_rec in C_GET_DETAILS loop
      if SYSTEM_OPTIONS_SQL.GET_CLASS_LEVEL_VAT_IND(O_error_message,
                                                    L_class_level_vat_ind) = FALSE then
         return FALSE;
      end if;
      ---
      if L_class_level_vat_ind = 'Y' then
         if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                           nvl(C_rec.item, (nvl(C_rec.item_parent, C_rec.item_grandparent))),
                                           L_dept,
                                           L_class,
                                           L_subclass) = FALSE then
            return FALSE;
         end if;
         ---
         if CLASS_ATTRIB_SQL.GET_CLASS_VAT_IND(O_error_message,
                                               L_class_vat_ind,
                                               L_dept,
                                               L_class) = FALSE then
            return FALSE;
         end if;
         ---
      else
         L_class_vat_ind := 'Y';
      end if;
      ---
      if L_class_vat_ind = 'Y' then
         if VAT_SQL.GET_VAT_RATE(O_error_message,
                                 L_vat_region,
                                 L_vat_code,
                                 L_vat_rate,
                                 nvl(C_rec.item, (nvl(C_rec.item_parent, C_rec.item_grandparent))),
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 'R') = FALSE then
            return FALSE;
         end if;
      else
         L_vat_rate := 0;
      end if;
      ---
      if ITEM_ATTRIB_SQL.GET_BASE_COST_RETAIL(O_error_message,
                                              L_unit_cost_prim,
                                              L_unit_retail_prim,
                                              L_uom_prim,
                                              L_selling_unit_retail_prim,
                                              L_selling_uom_prim,
                                              nvl(C_rec.item, (nvl(C_rec.item_parent, C_rec.item_grandparent))),
                                              'R') = FALSE then
         return FALSE;
      end if;
      ---
      L_unit_rtl_excl_vat  := ((C_rec.qty_contracted * L_unit_retail_prim)/(1 + (L_vat_rate/100)));
      O_total_retail_excl_vat := O_total_retail_excl_vat + L_unit_rtl_excl_vat;
   end loop;
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_DETAILS', 'CONTRACT_DETAIL', 'contract_no: '||to_char(I_contract_no));
   ---
   if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                       NULL,
                                       NULL,
                                       NULL,
                                       I_contract_no,
                                       'C',
                                       NULL,
                                       O_total_retail_excl_vat,
                                       O_total_retail_excl_vat,
                                       'R',
                                       NULL,
                                       NULL) = FALSE then
      return FALSE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_SQL.GET_RETAIL_EXCL_VAT',
                                            to_char(SQLCODE));
      return FALSE;
END GET_RETAIL_EXCL_VAT;
------------------------------------------------------------------------------------------------
FUNCTION POP_COST_HIST(O_error_message  IN OUT  VARCHAR2,
                       I_contract_no    IN      CONTRACT_HEADER.CONTRACT_NO%TYPE,
                       I_order_no       IN      ORDHEAD.ORDER_NO%TYPE)
   return BOOLEAN is

   L_dummy      VARCHAR2(1);
   L_item       ORDSKU.ITEM%TYPE;
   L_unit_cost  ORDLOC.UNIT_COST%TYPE;
   L_order_no   ORDSKU.ORDER_NO%TYPE;
   L_vdate      PERIOD.VDATE%TYPE := NULL;

   cursor C_COST_HIST_RECS is
      select 'x'
        from contract_cost_hist
       where item = L_item
         and contract_no = I_contract_no;

   cursor C_ORDLOC is
      select item, (sum(unit_cost * qty_ordered)/sum(qty_ordered)) unit_cost
        from ordloc
       where order_no = I_order_no
    group by item;
BEGIN
   L_vdate := DATES_SQL.GET_VDATE;
   FOR C_REC in C_ORDLOC LOOP
      L_item       := C_REC.ITEM;
      L_unit_cost  := C_REC.UNIT_COST;

      open C_COST_HIST_RECS;
      fetch C_COST_HIST_RECS into L_dummy;
      if C_COST_HIST_RECS%NOTFOUND then
         insert into contract_cost_hist(contract_no,
                                        item,
                                        active_date,
                                        unit_cost)
                values (I_contract_no,
                        L_item,
                        L_vdate,
                        L_unit_cost);
      end if;
      close C_COST_HIST_RECS;
   END LOOP;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_SQL.POP_COST_HIST',
                                            to_char(SQLCODE));
      return FALSE;
END POP_COST_HIST;
----------------------------------------------------------------------------------------
FUNCTION GET_CONTRACT_TYPE (O_error_message   IN OUT VARCHAR2,
                            O_contract_type   IN OUT CONTRACT_HEADER.CONTRACT_TYPE%TYPE,
                            I_contract_no     IN CONTRACT_HEADER.CONTRACT_NO%TYPE)
   RETURN BOOLEAN IS

   cursor C_CONTRACT_HEADER is
      select contract_type
        from contract_header
       where contract_no = I_contract_no;
BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_contract_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   else
      open C_CONTRACT_HEADER;
      fetch C_CONTRACT_HEADER into O_contract_type;
      close C_CONTRACT_HEADER;
      return TRUE;
   end if;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_SQL.GET_CONTRACT_TYPE',
                                            to_char(SQLCODE));
      return FALSE;
END GET_CONTRACT_TYPE;
----------------------------------------------------------------------------------------
FUNCTION ITEM_ON_CONTRACT (O_error_message   IN OUT VARCHAR2,
                           O_exists          IN OUT BOOLEAN,
                           O_pack_item_ind   IN OUT VARCHAR2,
                           I_contract_no     IN     CONTRACT_DETAIL.CONTRACT_NO%TYPE,
                           I_item            IN     CONTRACT_DETAIL.ITEM%TYPE)

   RETURN BOOLEAN IS

   L_item_parent      ITEM_MASTER.ITEM_PARENT%TYPE;
   L_item_grandparent ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_diff_1           ITEM_MASTER.DIFF_1%TYPE;
   L_diff_2           ITEM_MASTER.DIFF_2%TYPE;
   L_diff_3           ITEM_MASTER.DIFF_3%TYPE;
   L_diff_4           ITEM_MASTER.DIFF_4%TYPE;
   L_pack_ind         ITEM_MASTER.PACK_IND%TYPE;
   L_dummy            Varchar2(1);

   cursor C_GET_CONTRACT_DETAIL is
       select 'x'
         from contract_detail cd
        where cd.contract_no = I_contract_no
          and ((item_level_index = 1 and cd.item = I_item)
           or (item_level_index = 2
               and (   (    cd.item_parent = L_item_parent
                        and diff_1         = L_diff_1)
                    or (    cd.item_grandparent = L_item_grandparent
                        and diff_1              = L_diff_1)))
           or (item_level_index = 3
               and (   (    cd.item_parent = L_item_parent
                        and diff_2         = L_diff_2)
                    or (    cd.item_grandparent = L_item_grandparent
                        and diff_2              = L_diff_2)))
           or (item_level_index = 4
               and (   (    cd.item_parent = L_item_parent
                        and diff_3         = L_diff_3)
                    or (    cd.item_grandparent = L_item_grandparent
                        and diff_3              = L_diff_3)))
           or (item_level_index = 5
               and (   (    cd.item_parent = L_item_parent
                        and diff_4         = L_diff_4)
                    or (    cd.item_grandparent = L_item_grandparent
                        and diff_4              = L_diff_4)))
           or (item_level_index = 6
               and (   cd.item_parent      = L_item_parent
                    or cd.item_grandparent = L_item_grandparent)));

   cursor C_GET_ITEM_INFO is
       select item_parent,
              item_grandparent,
              diff_1,
              diff_2,
              diff_3,
              diff_4,
              pack_ind
         from item_master
        where item = I_item;

BEGIN
   open C_GET_ITEM_INFO;
   fetch C_GET_ITEM_INFO into L_item_parent,
                              L_item_grandparent,
                              L_diff_1,
                              L_diff_2,
                              L_diff_3,
                              L_diff_4,
                              L_pack_ind;
   close C_GET_ITEM_INFO;

   if L_pack_ind = 'Y' then
      O_pack_item_ind := 'Y';
   else
      O_pack_item_ind := 'N';
      OPEN C_GET_CONTRACT_DETAIL;
      FETCH C_GET_CONTRACT_DETAIL into L_dummy;
         if C_GET_CONTRACT_DETAIL%FOUND then
            O_exists := TRUE;
         else
            O_exists := FALSE;
         end if;
      CLOSE C_GET_CONTRACT_DETAIL;
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_SQL.ITEM_ON_CONTRACT',
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_ON_CONTRACT;
----------------------------------------------------------------------------------------
FUNCTION GET_CURRENCY_CODE(O_error_message      IN OUT VARCHAR2,
                           O_currency_code      IN OUT CONTRACT_HEADER.CURRENCY_CODE%TYPE,
                           I_contract_no        IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)

   RETURN BOOLEAN IS

   L_currency_code CONTRACT_HEADER.CURRENCY_CODE%TYPE := NULL;

   cursor C_GET_CURRENCY_CODE is
      select currency_code
        from contract_header
       where contract_no = I_contract_no;

BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_contract_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_GET_CURRENCY_CODE', 'CONTRACT_HEADER', 'contract_no:  '||to_char(I_contract_no));
   open C_GET_CURRENCY_CODE;
   SQL_LIB.SET_MARK('FETCH', 'C_GET_CURRENCY_CODE', 'CONTRACT_HEADER', 'contract_no:  '||to_char(I_contract_no));
   fetch C_GET_CURRENCY_CODE into L_currency_code;
   if C_GET_CURRENCY_CODE%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_CONTRACT_NO',
                                            'I_contract_no',
                                            'NULL',
                                            'NULL');
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_CURRENCY_CODE', 'CONTRACT_HEADER', 'contract_no:  '||to_char(I_contract_no));
      close C_GET_CURRENCY_CODE;
      return FALSE;
   else
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_CURRENCY_CODE', 'CONTRACT_HEADER', 'contract_no:  '||to_char(I_contract_no));
      close C_GET_CURRENCY_CODE;
      O_currency_code := L_currency_code;
      return TRUE;
   end if;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_SQL.GET_CURRENCY_CODE',
                                            to_char(SQLCODE));
      return FALSE;
END GET_CURRENCY_CODE;
--------------------------------------------------------------------------------------------------------
FUNCTION GET_SUPPLIER(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                      O_supplier        IN OUT CONTRACT_HEADER.SUPPLIER%TYPE,
                      I_contract_no     IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
RETURN BOOLEAN IS

   cursor C_SUPP is
      select supplier
        from contract_header
       where contract_no = I_contract_no;

BEGIN
   open C_SUPP;
   fetch C_SUPP into O_supplier;
   close C_SUPP;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_SQL.GET_SUPPLIER',
                                            to_char(SQLCODE));
      return FALSE;
END GET_SUPPLIER;
-------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                  O_valid          IN OUT  BOOLEAN,
                  O_division       IN OUT  DIVISION.DIVISION%TYPE,
                  O_div_name       IN OUT  DIVISION.DIV_NAME%TYPE,
                  O_group_no       IN OUT  GROUPS.GROUP_NO%TYPE,
                  O_group_name     IN OUT  GROUPS.GROUP_NAME%TYPE,
                  O_dept           IN OUT  DEPS.DEPT%TYPE,
                  O_dept_name      IN OUT  DEPS.DEPT_NAME%TYPE,
                  O_supplier       IN OUT  SUPS.SUPPLIER%TYPE,
                  O_sup_name       IN OUT  SUPS.SUP_NAME%TYPE,
                  O_status         IN OUT  CONTRACT_HEADER.STATUS%TYPE,
                  I_contract_no    IN      CONTRACT_HEADER.CONTRACT_NO%TYPE)
RETURN BOOLEAN IS

   L_contract_no  CONTRACT_HEADER.CONTRACT_NO%TYPE := NULL;

   cursor C_GET_INFO is
      select dv.division,
             dv.div_name,
             gr.group_no,
             gr.group_name,
             dp.dept,
             dp.dept_name,
             s.supplier,
             s.sup_name,
             ch.status,
             ch.contract_no
        from contract_header ch,
             division        dv,
             groups          gr,
             deps            dp,
             sups            s
       where ch.contract_no = I_contract_no
         and ch.supplier    = s.supplier
         and ch.dept        = dp.dept
         and dp.group_no    = gr.group_no
         and gr.division    = dv.division;

BEGIN

   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_contract_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   open  C_GET_INFO;
   fetch C_GET_INFO into O_division,
                         O_div_name,
                         O_group_no,
                         O_group_name,
                         O_dept,
                         O_dept_name,
                         O_supplier,
                         O_sup_name,
                         O_status,
                         L_contract_no;
   close C_GET_INFO;

   if L_contract_no is NULL then
      O_valid := FALSE;
      return TRUE;
   end if;

   O_valid := TRUE;

   if LANGUAGE_SQL.TRANSLATE(O_div_name,
                             O_div_name,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_group_name,
                             O_group_name,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_dept_name,
                             O_dept_name,
                             O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   if LANGUAGE_SQL.TRANSLATE(O_sup_name,
                             O_sup_name,
                             O_error_message) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_SQL.GET_INFO',
                                            to_char(SQLCODE));
      return FALSE;
END GET_INFO;
--------------------------------------------------------------------------------------------------------
END CONTRACT_SQL;
/

