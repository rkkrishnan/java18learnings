CREATE OR REPLACE PACKAGE BODY ITEM_LOC_SQL AS

TYPE locs_table_type IS
   TABLE OF STORE.STORE%TYPE INDEX BY BINARY_INTEGER;

TYPE item_loc_attr_rectype IS RECORD
   (loc_type              ITEM_LOC.LOC_TYPE%TYPE,
    primary_supp          ITEM_LOC.PRIMARY_SUPP%TYPE,
    primary_cntry         ITEM_LOC.PRIMARY_CNTRY%TYPE,
    primary_cost_pack     ITEM_LOC.PRIMARY_COST_PACK%TYPE,
    status                ITEM_LOC.STATUS%TYPE,
    local_item_desc       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
    local_short_desc      ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
    primary_variant       ITEM_LOC.PRIMARY_VARIANT%TYPE,
    unit_retail           ITEM_LOC.UNIT_RETAIL%TYPE,
    ti                    ITEM_LOC.TI%TYPE,
    hi                    ITEM_LOC.HI%TYPE,
    store_ord_mult        ITEM_LOC.STORE_ORD_MULT%TYPE,
    daily_waste_pct       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
    taxable_ind           ITEM_LOC.TAXABLE_IND%TYPE,
    meas_of_each          ITEM_LOC.MEAS_OF_EACH%TYPE,
    meas_of_price         ITEM_LOC.MEAS_OF_PRICE%TYPE,
    uom_of_price          ITEM_LOC.UOM_OF_PRICE%TYPE,
    selling_unit_retail   ITEM_LOC.SELLING_UNIT_RETAIL%TYPE,
    selling_uom           ITEM_LOC.SELLING_UOM%TYPE,
    receive_as_type       ITEM_LOC.RECEIVE_AS_TYPE%TYPE,
    inbound_handling_days ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE,
    source_method         ITEM_LOC.SOURCE_METHOD%TYPE,
    source_wh             ITEM_LOC.SOURCE_WH%TYPE,
    multi_units           ITEM_LOC.MULTI_UNITS%TYPE,
    multi_unit_retail     ITEM_LOC.MULTI_UNIT_RETAIL%TYPE,
    multi_selling_uom     ITEM_LOC.MULTI_SELLING_UOM%TYPE
);

-----------------------------------------------------------------
FUNCTION STORE_CLASS_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                       O_locs            IN OUT   locs_table_type,
                                       I_store_class     IN       STORE.STORE_CLASS%TYPE,
                                       I_currency_code   IN       STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

L_loop_index        NUMBER := 0;

cursor C_GET_LOCS is
   select store
     from v_store
    where store_class   = I_store_class
      and currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.STORE_CLASS_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END STORE_CLASS_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION DISTRICT_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                    O_locs            IN OUT   LOCS_TABLE_TYPE,
                                    I_district        IN       STORE.DISTRICT%TYPE,
                                    I_currency_code   IN       STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select store
        from v_store
       where district      = I_district
         and currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.DISTRICT_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END DISTRICT_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION REGION_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                  O_locs            IN OUT   LOCS_TABLE_TYPE,
                                  I_region          IN       REGION.REGION%TYPE,
                                  I_currency_code   IN       STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select store
        from v_store
       where region        = I_region
         and currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.REGION_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END REGION_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION AREA_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                O_locs            IN OUT   LOCS_TABLE_TYPE,
                                I_area            IN       AREA.AREA%TYPE,
                                I_currency_code   IN       STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

L_loop_index        NUMBER := 0;

cursor C_GET_LOCS is
   select store
     from v_store
    where area     = I_area
      and currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.AREA_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END AREA_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------
FUNCTION TSF_ZONE_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                    O_locs            IN OUT   LOCS_TABLE_TYPE,
                                    I_tsf_zone        IN       STORE.TRANSFER_ZONE%TYPE,
                                    I_currency_code   IN       STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select store
        from v_store
       where transfer_zone = I_tsf_zone
         and currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.TSF_ZONE_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END TSF_ZONE_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION PRICE_ZONE_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                      O_locs            IN OUT   locs_table_type,
                                      I_zone_group_id   IN       PRICE_ZONE_GROUP_STORE.ZONE_GROUP_ID%TYPE,
                                      I_zone_id         IN       PRICE_ZONE_GROUP_STORE.ZONE_ID%TYPE,
                                      I_currency_code   IN       STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select s.store
        from v_store s,
             price_zone_group_store pzgs
       where s.store             = pzgs.store
         and pzgs.zone_group_id  = I_zone_group_id
         and pzgs.zone_id        = nvl(I_zone_id, pzgs.zone_id)
         and s.currency_code     = nvl(I_currency_code, s.currency_code);

BEGIN
   if I_zone_group_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ZONE_GROUP_ID',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_LOCS',
                    'STORE, PRICE_ZONE_GROUP_STORE',
                    'ZONE_GROUP_ID: '||to_char(I_zone_group_id)||', ZONE_ID: '||to_char(I_zone_id));
   open C_GET_LOCS;
   ---
   LOOP
      L_loop_index := L_loop_index + 1;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_LOCS',
                       'STORE, PRICE_ZONE_GROUP_STORE',
                       'ZONE_GROUP_ID: '||to_char(I_zone_group_id)||', ZONE_ID: '||to_char(I_zone_id));
      fetch C_GET_LOCS into O_locs(L_loop_index);
      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_LOCS',
                    'STORE, PRICE_ZONE_GROUP_STORE',
                    'ZONE_GROUP_ID: '||to_char(I_zone_group_id)||', ZONE_ID: '||to_char(I_zone_id));
   close C_GET_LOCS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.PRICE_ZONE_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END PRICE_ZONE_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION LOC_TRAIT_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                     O_locs            IN OUT   locs_table_type,
                                     I_loc_trait       IN       loc_traits_matrix.loc_trait%TYPE,
                                     I_currency_code   IN       store.currency_code%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select l.store
        from loc_traits_matrix l,
             v_store s
       where l.store = s.store
         and l.loc_trait = I_loc_trait
         and s.currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.LOC_TRAIT_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END LOC_TRAIT_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION DEFAULT_WH_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                      O_locs            IN OUT   LOCS_TABLE_TYPE,
                                      I_default_wh      IN       STORE.DEFAULT_WH%TYPE,
                                      I_currency_code   IN       STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select store
        from v_store
       where default_wh    = I_default_wh
         and currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.DEFAULT_WH_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END DEFAULT_WH_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION LOC_LIST_ST_LOCS_FOR_CURRENCY(O_error_message   IN   OUT VARCHAR2,
                                       O_locs            IN   OUT LOCS_TABLE_TYPE,
                                       I_loc_list        IN   LOC_LIST_DETAIL.LOC_LIST%TYPE,
                                       I_currency_code   IN   STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select location l
        from loc_list_detail l,
             v_store s
       where l.location = s.store
         and l.loc_list = I_loc_list
         and s.currency_code = nvl(I_currency_code, currency_code)
         and l.loc_type = 'S';

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.LOC_LIST_ST_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END LOC_LIST_ST_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION LOC_LIST_WH_LOCS_FOR_CURRENCY(O_error_message   OUT   VARCHAR2,
                                       O_locs            OUT   LOCS_TABLE_TYPE,
                                       I_loc_list        IN    LOC_LIST_DETAIL.LOC_LIST%TYPE,
                                       I_currency_code   IN    STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select distinct w.wh
        from loc_list_detail l,
             v_wh w
       where (l.location        = w.wh
              or w.physical_wh  = l.location)
         and l.loc_list         = I_loc_list
         and w.currency_code    = nvl(I_currency_code, currency_code)
         and l.loc_type         = 'W'
         and w.stockholding_ind = 'Y';

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;
      fetch C_GET_LOCS into O_locs(L_loop_index);
      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.LOC_LIST_WH_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END LOC_LIST_WH_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION ALL_WAREHOUSES_FOR_CURRENCY(O_error_message   OUT   VARCHAR2,
                                     O_locs            OUT   LOCS_TABLE_TYPE,
                                     I_currency_code   IN    STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select wh
        from v_wh
       where currency_code    = nvl(I_currency_code, currency_code)
         and stockholding_ind = 'Y'
         and NOT EXISTS (select wh
                           from wh_add
                          where wh = v_wh.wh);
BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;
      fetch C_GET_LOCS into O_locs(L_loop_index);
      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.ALL_WAREHOUSES_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END ALL_WAREHOUSES_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION ALL_STORES_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                 O_locs            IN OUT   LOCS_TABLE_TYPE,
                                 I_currency_code   IN       STORE.CURRENCY_CODE%TYPE)
return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select store
        from v_store
       where currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;

      fetch C_GET_LOCS into O_locs(L_loop_index);

      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.ALL_STORES_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END ALL_STORES_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION ALL_LOCS_FOR_CURRENCY(O_error_message   OUT   VARCHAR2,
                               O_locs            OUT   LOCS_TABLE_TYPE,
                               I_currency_code   IN    STORE.CURRENCY_CODE%TYPE)
   return BOOLEAN IS

   L_loop_index        NUMBER := 0;
   L_sub_loop_index    NUMBER;
   L_exit_greater_loop BOOLEAN := FALSE;

   cursor C_GET_WAREHOUSES is
      select wh
        from v_wh
       where currency_code    = nvl(I_currency_code, currency_code)
         and stockholding_ind = 'Y';

   cursor C_GET_STORES is
      select store
        from v_store
       where currency_code = nvl(I_currency_code, currency_code);

BEGIN
   open C_GET_WAREHOUSES;

   LOOP
      L_loop_index := L_loop_index + 1;
      fetch C_GET_WAREHOUSES into O_locs(L_loop_index);

      if C_GET_WAREHOUSES%NOTFOUND then
         open C_GET_STORES;
         L_sub_loop_index := L_loop_index - 1;

         LOOP
            L_sub_loop_index := L_sub_loop_index + 1;
            fetch C_GET_STORES into O_locs(L_sub_loop_index);

            if C_GET_STORES%NOTFOUND then
               L_exit_greater_loop := TRUE;
               EXIT;
            end if;
         END LOOP;

         close C_GET_STORES;
      end if;

      EXIT WHEN L_exit_greater_loop;
   END LOOP;

   close C_GET_WAREHOUSES;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.ALL_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END ALL_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION PHYSICAL_WH_LOCS_FOR_CURRENCY(O_error_message   OUT   VARCHAR2,
                                       O_locs            OUT   LOCS_TABLE_TYPE,
                                       I_ph_wh           IN    WH.PHYSICAL_WH%TYPE,
                                       I_currency_code   IN    STORE.CURRENCY_CODE%TYPE)
   return BOOLEAN IS

   L_program      VARCHAR2(50) := 'ITEM_LOC_SQL.PHYSICAL_WH_LOCS_FOR_CURRENCY';
   L_loop_index   NUMBER       := 0;

   cursor C_GET_LOCS is
      select wh
        from v_wh
       where physical_wh = I_ph_wh
         and currency_code = nvl(I_currency_code, currency_code)
         and stockholding_ind = 'Y';

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_GET_LOCS', 'WH', NULL);
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;
      fetch C_GET_LOCS into O_locs(L_loop_index);
      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   SQL_LIB.SET_MARK('CLOSE', 'C_GET_LOCS', 'WH', NULL);
   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      RETURN FALSE;
END PHYSICAL_WH_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION ALL_INT_FINISHERS_FOR_CURRENCY(O_error_message   OUT   VARCHAR2,
                                        O_locs            OUT   LOCS_TABLE_TYPE,
                                        I_currency_code   IN    STORE.CURRENCY_CODE%TYPE)
   return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select finisher_id
        from v_internal_finisher
       where currency_code    = nvl(I_currency_code, currency_code);
BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;
      fetch C_GET_LOCS into O_locs(L_loop_index);
      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.ALL_INT_FINISHERS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END ALL_INT_FINISHERS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION ALL_EXT_FINISHERS_FOR_CURRENCY(O_error_message   OUT   VARCHAR2,
                                        O_locs            OUT   LOCS_TABLE_TYPE,
                                        I_currency_code   IN    STORE.CURRENCY_CODE%TYPE)
   return BOOLEAN IS

   L_loop_index        NUMBER := 0;

   cursor C_GET_LOCS is
      select finisher_id
        from v_external_finisher
       where currency_code    = nvl(I_currency_code, currency_code);
BEGIN
   open C_GET_LOCS;

   LOOP
      L_loop_index := L_loop_index + 1;
      fetch C_GET_LOCS into O_locs(L_loop_index);
      EXIT WHEN C_GET_LOCS%NOTFOUND;
   END LOOP;

   close C_GET_LOCS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.ALL_EXT_FINISHERS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END ALL_EXT_FINISHERS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION GROUP_LOCS_FOR_CURRENCY(O_error_message   IN OUT   VARCHAR2,
                                 O_locs            IN OUT   LOCS_TABLE_TYPE,
                                 I_group_type      IN       CODE_DETAIL.CODE%TYPE,
                                 I_group_value     IN       CODE_DETAIL.CODE_DESC%TYPE,
                                 I_zone_group_id   IN       PRICE_ZONE_GROUP_STORE.ZONE_GROUP_ID%TYPE,
                                 I_currency_code   IN       CURRENCIES.CURRENCY_CODE%TYPE)
return BOOLEAN IS

BEGIN


   if I_group_type in('S', 'W', 'I', 'E') then
      O_locs(1) := I_group_value;
   elsif I_group_type = 'C' then
      if STORE_CLASS_LOCS_FOR_CURRENCY(O_error_message,
                                       O_locs,
                                       I_group_value,
                                       I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'D' then
      if DISTRICT_LOCS_FOR_CURRENCY(O_error_message,
                                    O_locs,
                                    I_group_value,
                                    I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'R' then
      if REGION_LOCS_FOR_CURRENCY(O_error_message,
                                  O_locs,
                                  I_group_value,
                                  I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'A' then
      if AREA_LOCS_FOR_CURRENCY(O_error_message,
                                O_locs,
                                I_group_value,
                                I_currency_code) = FALSE then
         return FALSE;
      end if;


   elsif I_group_type = 'T' then
      if TSF_ZONE_LOCS_FOR_CURRENCY(O_error_message,
                                    O_locs,
                                    I_group_value,
                                    I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'Z' then
      if PRICE_ZONE_LOCS_FOR_CURRENCY(O_error_message,
                                      O_locs,
                                      I_zone_group_id,
                                      I_group_value,
                                      I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'L' then
      if LOC_TRAIT_LOCS_FOR_CURRENCY(O_error_message,
                                     O_locs,
                                     I_group_value,
                                     I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'DW' then
      if DEFAULT_WH_LOCS_FOR_CURRENCY(O_error_message,
                                      O_locs,
                                      I_group_value,
                                      I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'LLS' then
      if LOC_LIST_ST_LOCS_FOR_CURRENCY(O_error_message,
                                       O_locs,
                                       I_group_value,
                                       I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'LLW' then
      if LOC_LIST_WH_LOCS_FOR_CURRENCY(O_error_message,
                                       O_locs,
                                       I_group_value,
                                       I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'AW' then
      if ALL_WAREHOUSES_FOR_CURRENCY(O_error_message,
                                     O_locs,
                                     I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'AS' then
      if ALL_STORES_FOR_CURRENCY(O_error_message,
                                 O_locs,
                                 I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'AL' then
      if ALL_LOCS_FOR_CURRENCY(O_error_message,
                               O_locs,
                               I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'PW' then
      if PHYSICAL_WH_LOCS_FOR_CURRENCY(O_error_message,
                                       O_locs,
                                       I_group_value,
                                       I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'AI' then
      if ALL_INT_FINISHERS_FOR_CURRENCY(O_error_message,
                                        O_locs,
                                        I_currency_code) = FALSE then
         return FALSE;
      end if;
   elsif I_group_type = 'AE' then
      if ALL_EXT_FINISHERS_FOR_CURRENCY(O_error_message,
                                        O_locs,
                                        I_currency_code) = FALSE then
         return FALSE;
      end if;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'ITEM_LOC_SQL.GROUP_LOCS_FOR_CURRENCY',
                                             to_char(SQLCODE));
      RETURN FALSE;
END GROUP_LOCS_FOR_CURRENCY;
--------------------------------------------------------------------------------------------
FUNCTION GET_ITEM_LOC(O_error_message         IN OUT   VARCHAR2,
                      O_item_parent           IN OUT   ITEM_LOC.ITEM_PARENT%TYPE,
                      O_item_grandparent      IN OUT   ITEM_LOC.ITEM_GRANDPARENT%TYPE,
                      O_loc_type              IN OUT   ITEM_LOC.LOC_TYPE%TYPE,
                      O_unit_retail           IN OUT   ITEM_LOC.UNIT_RETAIL%TYPE,
                      O_selling_unit_retail   IN OUT   ITEM_LOC.SELLING_UNIT_RETAIL%TYPE,
                      O_selling_uom           IN OUT   ITEM_LOC.SELLING_UOM%TYPE,
                      O_clear_ind             IN OUT   ITEM_LOC.CLEAR_IND%TYPE,
                      O_taxable_ind           IN OUT   ITEM_LOC.TAXABLE_IND%TYPE,
                      O_local_item_desc       IN OUT   ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                      O_local_short_desc      IN OUT   ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                      O_ti                    IN OUT   ITEM_LOC.TI%TYPE,
                      O_hi                    IN OUT   ITEM_LOC.HI%TYPE,
                      O_store_ord_mult        IN OUT   ITEM_LOC.STORE_ORD_MULT%TYPE,
                      O_status                IN OUT   ITEM_LOC.STATUS%TYPE,
                      O_status_update_date    IN OUT   ITEM_LOC.STATUS_UPDATE_DATE%TYPE,
                      O_daily_waste_pct       IN OUT   ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                      O_meas_of_each          IN OUT   ITEM_LOC.MEAS_OF_EACH%TYPE,
                      O_meas_of_price         IN OUT   ITEM_LOC.MEAS_OF_PRICE%TYPE,
                      O_uom_of_price          IN OUT   ITEM_LOC.UOM_OF_PRICE%TYPE,
                      O_primary_variant       IN OUT   ITEM_LOC.PRIMARY_VARIANT%TYPE,
                      O_primary_supp          IN OUT   ITEM_LOC.PRIMARY_SUPP%TYPE,
                      O_primary_cntry         IN OUT   ITEM_LOC.PRIMARY_CNTRY%TYPE,
                      O_primary_cost_pack     IN OUT   ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                      I_item                  IN       ITEM_LOC.ITEM%TYPE,
                      I_loc                   IN       ITEM_LOC.LOC%TYPE)
return BOOLEAN IS

   L_program VARCHAR2(64) := 'LOC_ITEM_SQL.GET_ITEM_LOC';

   cursor C_GET_ITEM_LOC is
      select item_parent,
             item_grandparent,
             loc_type,
             unit_retail,
             selling_unit_retail,
             selling_uom,
             clear_ind,
             taxable_ind,
             local_item_desc,
             local_short_desc,
             ti,
             hi,
             store_ord_mult,
             status,
             status_update_date,
             daily_waste_pct,
             meas_of_each,
             meas_of_price,
             uom_of_price,
             primary_variant,
             primary_supp,
             primary_cntry,
             primary_cost_pack
        from item_loc
       where item = I_item
         and loc  = I_loc;

BEGIN
   open C_GET_ITEM_LOC;
   fetch C_GET_ITEM_LOC into O_item_parent,
                             O_item_grandparent,
                             O_loc_type,
                             O_unit_retail,
                             O_selling_unit_retail,
                             O_selling_uom,
                             O_clear_ind,
                             O_taxable_ind,
                             O_local_item_desc,
                             O_local_short_desc,
                             O_ti,
                             O_hi,
                             O_store_ord_mult,
                             O_status,
                             O_status_update_date,
                             O_daily_waste_pct,
                             O_meas_of_each,
                             O_meas_of_price,
                             O_uom_of_price,
                             O_primary_variant,
                             O_primary_supp,
                             O_primary_cntry,
                             O_primary_cost_pack;
   close C_GET_ITEM_LOC;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END GET_ITEM_LOC;
-----------------------------------------------------------------
FUNCTION GET_ITEM_LOC(O_error_message   IN OUT   VARCHAR2,
                      O_item_loc        IN OUT   ITEM_LOC%ROWTYPE,
                      I_item            IN       ITEM_LOC.ITEM%TYPE,
                      I_loc             IN       ITEM_LOC.LOC%TYPE)
RETURN BOOLEAN is

   L_program VARCHAR2(64) := 'LOC_ITEM_SQL.GET_ITEM_LOC';

   cursor C_GET_ITEM_LOC is
      select *
        from item_loc
       where item = I_item
         and loc  = I_loc;

BEGIN
   open C_GET_ITEM_LOC;
   fetch C_GET_ITEM_LOC into O_item_loc;
   close C_GET_ITEM_LOC;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END GET_ITEM_LOC;
-----------------------------------------------------------------
FUNCTION CREATE_ITEM_LOC(O_error_message           IN OUT   VARCHAR2,
                         I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                         I_group_type              IN       CODE_DETAIL.CODE%TYPE,
                         I_group_value             IN       VARCHAR2,
                         I_currency_code           IN       STORE.CURRENCY_CODE%TYPE,
                         I_item_parent             IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                         I_item_grandparent        IN       ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                         I_loc_type                IN       ITEM_LOC.LOC_TYPE%TYPE,
                         I_short_desc              IN       ITEM_MASTER.SHORT_DESC%TYPE,
                         I_dept                    IN       ITEM_MASTER.DEPT%TYPE,
                         I_class                   IN       ITEM_MASTER.CLASS%TYPE,
                         I_subclass                IN       ITEM_MASTER.SUBCLASS%TYPE,
                         I_item_level              IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                         I_tran_level              IN       ITEM_MASTER.TRAN_LEVEL%TYPE,
                         I_item_status             IN       ITEM_MASTER.STATUS%TYPE,
                         I_zone_group_id           IN       ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                         I_waste_type              IN       ITEM_MASTER.WASTE_TYPE%TYPE,
                         I_daily_waste_pct         IN       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                         I_sellable_ind            IN       ITEM_MASTER.SELLABLE_IND%TYPE,
                         I_orderable_ind           IN       ITEM_MASTER.ORDERABLE_IND%TYPE,
                         I_pack_ind                IN       ITEM_MASTER.PACK_IND%TYPE,
                         I_pack_type               IN       ITEM_MASTER.PACK_TYPE%TYPE,
                         I_unit_cost_loc           IN       ITEM_LOC_SOH.UNIT_COST%TYPE,
                         I_unit_retail_loc         IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                         I_selling_retail_loc      IN       ITEM_LOC.SELLING_UNIT_RETAIL%TYPE,
                         I_selling_uom             IN       ITEM_LOC.SELLING_UOM%TYPE,
                         I_item_loc_status         IN       ITEM_LOC.STATUS%TYPE,
                         I_taxable_ind             IN       ITEM_LOC.TAXABLE_IND%TYPE,
                         I_ti                      IN       ITEM_LOC.TI%TYPE,
                         I_hi                      IN       ITEM_LOC.HI%TYPE,
                         I_store_ord_mult          IN       ITEM_LOC.STORE_ORD_MULT%TYPE,
                         I_meas_of_each            IN       ITEM_LOC.MEAS_OF_EACH%TYPE,
                         I_meas_of_price           IN       ITEM_LOC.MEAS_OF_PRICE%TYPE,
                         I_uom_of_price            IN       ITEM_LOC.UOM_OF_PRICE%TYPE,
                         I_primary_variant         IN       ITEM_LOC.PRIMARY_VARIANT%TYPE,
                         I_primary_supp            IN       ITEM_LOC.PRIMARY_SUPP%TYPE,
                         I_primary_cntry           IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                         I_local_item_desc         IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                         I_local_short_desc        IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                         I_primary_cost_pack       IN       ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                         I_date                    IN       DATE,
                         I_default_to_children     IN       BOOLEAN,
                         I_receive_as_type         IN       ITEM_LOC.RECEIVE_AS_TYPE%TYPE,
                         I_inbound_handling_days   IN       ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE,
                         I_store_price_ind         IN       ITEM_LOC.STORE_PRICE_IND%TYPE,
                         I_source_method           IN       ITEM_LOC.SOURCE_METHOD%TYPE,
                         I_source_wh               IN       ITEM_LOC.SOURCE_WH%TYPE,
                         I_multi_units             IN       ITEM_LOC.MULTI_UNITS%TYPE,
                         I_multi_unit_retail       IN       ITEM_LOC.MULTI_UNIT_RETAIL%TYPE,
                         I_multi_selling_uom       IN       ITEM_LOC.MULTI_SELLING_UOM%TYPE)
return BOOLEAN IS

   L_program         VARCHAR2(64) := 'ITEM_LOC_SQL.CREATE_ITEM_LOC';
   L_locs_table      locs_table_type;
   L_source_method   ITEM_LOC.SOURCE_METHOD%TYPE;
   L_hier_level      VARCHAR2(2) := I_loc_type;   --- Org hierarchy needed for calling the newitemloc package
                                                  --- which we need for the multi retail fields.
                                                  --- Package was originally developed for external itemloc API
                                                  --- which uses the whole org hierarchy.

BEGIN
   if GROUP_LOCS_FOR_CURRENCY(O_error_message,
                              L_locs_table,
                              I_group_type,
                              I_group_value,
                              I_zone_group_id,
                              I_currency_code) = FALSE then
      return FALSE;
   end if;
   ---
   if I_loc_type = 'S' and I_source_method is NULL then
      L_source_method := 'S';
   else
      L_source_method := I_source_method;
   end if;
   ---
   if I_group_type in ('DW','W','PW','I') then
      if I_inbound_handling_days is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG',
                                                      L_program,
                                                      'I_inbound_handling_days',
                                                      'null');
         Return FALSE;
      end if;
   else
      if I_inbound_handling_days is NOT NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_PARM_PROG',
                                                      L_program,
                                                      'I_inbound_handling_days',
                                                      'Not NULL');
         Return FALSE;
      end if;
   end if;
   FOR loop_index IN 1..L_locs_table.COUNT LOOP
      if NEW_ITEM_LOC_SQL.NEW_ITEM_LOC(O_error_message,
                                       I_item,
                                       L_hier_level,
                                       L_locs_table(loop_index),
                                       I_item_parent,
                                       I_item_grandparent,
                                       I_loc_type,
                                       I_short_desc,
                                       I_dept,
                                       I_class,
                                       I_subclass,
                                       I_item_level,
                                       I_tran_level,
                                       I_item_status,
                                       I_zone_group_id,
                                       I_waste_type,
                                       I_daily_waste_pct,
                                       I_sellable_ind,
                                       I_orderable_ind,
                                       I_pack_ind,
                                       I_pack_type,
                                       I_unit_cost_loc,
                                       I_unit_retail_loc,
                                       I_multi_units,
                                       I_multi_unit_retail,
                                       I_multi_selling_uom,
                                       I_selling_retail_loc,
                                       I_selling_uom,
                                       I_item_loc_status,
                                       I_taxable_ind,
                                       I_ti,
                                       I_hi,
                                       I_store_ord_mult,
                                       I_meas_of_each,
                                       I_meas_of_price,
                                       I_uom_of_price,
                                       I_primary_variant,
                                       I_primary_supp,
                                       I_primary_cntry,
                                       I_local_item_desc,
                                       I_local_short_desc,
                                       I_primary_cost_pack,
                                       I_receive_as_type,
                                       I_date,
                                       I_default_to_children,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       I_inbound_handling_days,
                                       I_group_type,
                                       I_store_price_ind,
                                       I_source_method => L_source_method,
                                       I_source_wh => I_source_wh) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_ITEM_LOC;
-----------------------------------------------------------------
FUNCTION ALL_LOCS_EXIST(O_error_message    IN OUT   VARCHAR2,
                        O_all_locs_exist   IN OUT   BOOLEAN,
                        I_item             IN       ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is

   L_dummy VARCHAR2(1);
   L_program VARCHAR2(64) := 'ITEM_LOC_SQL.ALL_LOCS_EXIST';

cursor C_ALL_LOCS_EXIST is
   select 'x'
     from store
    where store not in(select loc
                         from item_loc
                        where item = I_item)
   UNION ALL
   select 'x'
     from wh
    where wh not in(select loc
                      from item_loc
                     where item = I_item);

BEGIN
   open C_ALL_LOCS_EXIST;
   fetch C_ALL_LOCS_EXIST into L_dummy;

   if C_ALL_LOCS_EXIST%NOTFOUND then
      O_all_locs_exist := TRUE;
   else
      O_all_locs_exist := FALSE;
   end if;

   close C_ALL_LOCS_EXIST;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END ALL_LOCS_EXIST;
-----------------------------------------------------------------
FUNCTION INSERT_STATUS_POS_MOD(O_error_message   IN OUT   VARCHAR2,
                               I_item            IN       ITEM_MASTER.ITEM%TYPE,
                               I_loc             IN       ITEM_LOC.LOC%TYPE,
                               I_status          IN       ITEM_LOC.STATUS%TYPE)
return BOOLEAN is

   L_program VARCHAR2(64) := 'ITEM_LOC_SQL.INSERT_STATUS_POS_MOD';

BEGIN
   if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                     25,
                                     I_item,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     I_loc,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     (SYSDATE + 1),
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     I_status,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END INSERT_STATUS_POS_MOD;
-----------------------------------------------------------------
FUNCTION INSERT_POS_MODS(O_error_message      IN OUT   VARCHAR2,
                         I_item               IN       ITEM_LOC.ITEM%TYPE,
                         I_loc                IN       ITEM_LOC.LOC%TYPE,
                         I_local_item_desc    IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                         I_local_short_desc   IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                         I_taxable_ind        IN       ITEM_LOC.TAXABLE_IND%TYPE)
return BOOLEAN is

   L_dummy VARCHAR2(1);
   L_program VARCHAR2(64) := 'ITEM_LOC_SQL.INSERT_POS_MODS';

cursor C_LOCAL_DESC_CHANGED is
   select 'x'
     from item_loc
    where item = I_item
      and loc = I_loc
      and local_item_desc != I_local_item_desc;

cursor C_LOCAL_SHORT_DESC_CHANGED is
   select 'x'
     from item_loc
    where item = I_item
      and loc = I_loc
      and local_short_desc != I_local_short_desc;

cursor C_TAXABLE_CHANGED is
   select 'x'
     from item_loc
    where item = I_item
      and loc = I_loc
      and taxable_ind != I_taxable_ind;

BEGIN
   open C_LOCAL_DESC_CHANGED;
   fetch C_LOCAL_DESC_CHANGED into L_dummy;
   if C_LOCAL_DESC_CHANGED%FOUND then
      if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                        12,
                                        I_item,
                                        I_local_item_desc,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        I_loc,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        (SYSDATE + 1),
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL) = FALSE then
          return FALSE;
      end if;
   end if;
   close C_LOCAL_DESC_CHANGED;
   ---
   open C_LOCAL_SHORT_DESC_CHANGED;
   fetch C_LOCAL_SHORT_DESC_CHANGED into L_dummy;
   if C_LOCAL_SHORT_DESC_CHANGED%FOUND then
      if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                        10,
                                        I_item,
                                        I_local_short_desc,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        I_loc,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        (SYSDATE + 1),
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL) = FALSE then
          return FALSE;
      end if;
   end if;
   close C_LOCAL_SHORT_DESC_CHANGED;
   ---
   open C_TAXABLE_CHANGED;
   fetch C_TAXABLE_CHANGED into L_dummy;
   if C_TAXABLE_CHANGED%FOUND then
      if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                        26,
                                        I_item,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        I_loc,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        (SYSDATE + 1),
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        I_taxable_ind,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL) = FALSE then
          return FALSE;
      end if;
   end if;
   close C_TAXABLE_CHANGED;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END INSERT_POS_MODS;
-----------------------------------------------------------------
FUNCTION INSERT_PRIM_VARIANT_POS_MODS(O_error_message   IN OUT   VARCHAR2,
                                      I_item            IN       ITEM_LOC.ITEM%TYPE,
                                      I_loc             IN       ITEM_LOC.LOC%TYPE,
                                      I_item_loc_rec    IN       ITEM_LOC_ATTR_RECTYPE)
return BOOLEAN is

   L_dept       ITEM_MASTER.DEPT%TYPE;
   L_class      ITEM_MASTER.CLASS%TYPE;
   L_subclass   ITEM_MASTER.SUBCLASS%TYPE;
   L_program    VARCHAR2(64) := 'ITEM_LOC_SQL.INSERT_PRIM_VARIANT_POS_MODS';

   cursor C_PRIMARY_VARIANT is
      select im.dept,
             im.class,
             im.subclass
        from item_master im,
             item_loc il
       where im.item = il.item
         and il.item = I_item
         and loc     = I_loc
         and NVL(primary_variant, ' ') != I_item_loc_rec.primary_variant;

BEGIN
   open C_PRIMARY_VARIANT;
   fetch C_PRIMARY_VARIANT into L_dept,
                                L_class,
                                L_subclass;

   if C_PRIMARY_VARIANT%FOUND then
      if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                        01,
                                        I_item_loc_rec.primary_variant,
                                        NVL(I_item_loc_rec.local_item_desc,I_item_loc_rec.local_short_desc),
                                        NULL,
                                        L_dept,
                                        L_class,
                                        L_subclass,
                                        I_loc,
                                        I_item_loc_rec.selling_unit_retail,
                                        I_item_loc_rec.selling_uom,
                                        NULL,
                                        NULL,
                                        (SYSDATE + 1),
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NVL(I_item_loc_rec.status, 'A'),
                                        NVL(I_item_loc_rec.taxable_ind, 'Y'),
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL) = FALSE then
          return FALSE;
      end if;
   end if;
   close C_PRIMARY_VARIANT;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END INSERT_PRIM_VARIANT_POS_MODS;
-----------------------------------------------------------------
FUNCTION UPDATE_COST(O_error_message      IN OUT   VARCHAR2,
                     I_item               IN       ITEM_MASTER.ITEM%TYPE,
                     I_loc                IN       ITEM_LOC.ITEM%TYPE,
                     I_primary_supp       IN       ITEM_LOC.PRIMARY_SUPP%TYPE,
                     I_primary_cntry      IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                     I_process_children   IN       VARCHAR2)
return BOOLEAN is

   L_dummy   VARCHAR2(1);
   L_program VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_COST';

cursor C_SUPP_CNTRY_CHANGED is
   select 'x'
     from item_loc
    where item = I_item
      and loc  = I_loc
      and ((primary_supp != I_primary_supp) or (primary_cntry != I_primary_cntry));

BEGIN
   open C_SUPP_CNTRY_CHANGED;
   fetch  C_SUPP_CNTRY_CHANGED into L_dummy;

   -- If the supplier/country have been changed, the unit cost will need to be updated.
   if C_SUPP_CNTRY_CHANGED%FOUND then
      if UPDATE_BASE_COST.CHG_ITEMLOC_PRIM_SUPP_CNTRY(O_error_message,
                                                      I_item,
                                                      I_loc,
                                                      I_primary_supp,
                                                      I_primary_cntry,
                                                      I_process_children,
                                                      NULL /* Cost Change Number */ ) = FALSE then
         return FALSE;
      end if;
   end if;

   close C_SUPP_CNTRY_CHANGED;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_COST;
-----------------------------------------------------------------
FUNCTION STATUS_UPDATED(O_error_message    IN OUT   VARCHAR2,
                        O_status_updated   IN OUT   BOOLEAN,
                        I_item             IN       ITEM_MASTER.ITEM%TYPE,
                        I_loc              IN       ITEM_LOC.LOC%TYPE,
                        I_new_status       IN       ITEM_LOC.STATUS%TYPE)
return BOOLEAN is

   L_dummy   VARCHAR2(1);
   L_program VARCHAR2(64) := 'ITEM_LOC_SQL.STATUS_UPDATED';

cursor C_STATUS_CHANGED is
   select 'x'
     from item_loc
    where item = I_item
      and loc = I_loc
      and status != I_new_status;

BEGIN
   open C_STATUS_CHANGED;
   fetch C_STATUS_CHANGED into L_dummy;

   if C_STATUS_CHANGED%FOUND then
      O_status_updated := TRUE;
   end if;

   close C_STATUS_CHANGED;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END STATUS_UPDATED;
-----------------------------------------------------------------
FUNCTION UPDATE_TABLE(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                      I_item              IN       ITEM_MASTER.ITEM%TYPE,
                      I_loc               IN       ITEM_LOC.LOC%TYPE,
                      I_item_loc_rec      IN       ITEM_LOC_ATTR_RECTYPE,
                      I_status_updated    IN       BOOLEAN,
                      I_store_price_ind   IN       ITEM_LOC.STORE_PRICE_IND%TYPE DEFAULT NULL)
return BOOLEAN is

   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);

   L_status_update_date   ITEM_LOC.STATUS_UPDATE_DATE%TYPE;
   L_program              VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_TABLE';
   L_status               ITEM_MASTER.STATUS%TYPE;

   cursor C_LOCK_ITEM_LOC is
      select 'x'
        from item_loc
       where item = I_item
         and loc  = I_loc
         for update nowait;

   cursor C_GET_ITEM_STATUS is
      select status
        from item_master
       where item = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ITEM_LOC',
                    'ITEM_LOC',
                    I_item);
   open C_LOCK_ITEM_LOC;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ITEM_LOC',
                    'ITEM_LOC',
                    I_item);
   close C_LOCK_ITEM_LOC;

   if I_status_updated then
      L_status_update_date := SYSDATE;
   else
      L_status_update_date := NULL;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ITEM_STATUS',
                    'ITEM_MASTER',
                    I_item);
   open C_GET_ITEM_STATUS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ITEM_STATUS',
                    'ITEM_MASTER',
                    I_item);
   fetch C_GET_ITEM_STATUS into L_status;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ITEM_STATUS',
                    'ITEM_MASTER',
                    I_item);
   close C_GET_ITEM_STATUS;

   if L_status <> 'A' then
      update item_loc
         set primary_supp         = I_item_loc_rec.primary_supp,
             primary_cntry        = I_item_loc_rec.primary_cntry,
             status               = I_item_loc_rec.status,
             status_update_date   = nvl(L_status_update_date, status_update_date),
             local_item_desc      = I_item_loc_rec.local_item_desc,
             local_short_desc     = I_item_loc_rec.local_short_desc,
             primary_variant      = I_item_loc_rec.primary_variant,
             unit_retail          = I_item_loc_rec.unit_retail,
             -- 28-Oct-2008 TESCO HSC/Vinod Kumar 7006221 Begin
             regular_unit_retail  = I_item_loc_rec.unit_retail,
             -- 28-Oct-2008 TESCO HSC/Vinod Kumar 7006221 End
             ti                   = I_item_loc_rec.ti,
             hi                   = I_item_loc_rec.hi,
             store_ord_mult       = I_item_loc_rec.store_ord_mult,
             daily_waste_pct      = I_item_loc_rec.daily_waste_pct,
             taxable_ind          = I_item_loc_rec.taxable_ind,
             meas_of_each         = I_item_loc_rec.meas_of_each,
             meas_of_price        = I_item_loc_rec.meas_of_price,
             uom_of_price         = I_item_loc_rec.uom_of_price,
             selling_unit_retail  = I_item_loc_rec.selling_unit_retail,
             selling_uom          = I_item_loc_rec.selling_uom,
             primary_cost_pack    = I_item_loc_rec.primary_cost_pack,
             receive_as_type      = I_item_loc_rec.receive_as_type,
             source_method        = I_item_loc_rec.source_method,
             source_wh            = I_item_loc_rec.source_wh,
             multi_units          = I_item_loc_rec.multi_units,
             multi_unit_retail    = I_item_loc_rec.multi_unit_retail,
             multi_selling_uom    = I_item_loc_rec.multi_selling_uom,
             last_update_datetime = sysdate,
             last_update_id       = user,
             inbound_handling_days = I_item_loc_rec.inbound_handling_days,
             store_price_ind      = nvl(I_store_price_ind, 'N')
       where item = I_item
         and loc = I_loc;
   else
      update item_loc
         set primary_supp         = I_item_loc_rec.primary_supp,
             primary_cntry        = I_item_loc_rec.primary_cntry,
             status               = I_item_loc_rec.status,
             status_update_date   = nvl(L_status_update_date, status_update_date),
             local_item_desc      = I_item_loc_rec.local_item_desc,
             local_short_desc     = I_item_loc_rec.local_short_desc,
             primary_variant      = I_item_loc_rec.primary_variant,
             ti                   = I_item_loc_rec.ti,
             hi                   = I_item_loc_rec.hi,
             store_ord_mult       = I_item_loc_rec.store_ord_mult,
             daily_waste_pct      = I_item_loc_rec.daily_waste_pct,
             taxable_ind          = I_item_loc_rec.taxable_ind,
             meas_of_each         = I_item_loc_rec.meas_of_each,
             meas_of_price        = I_item_loc_rec.meas_of_price,
             uom_of_price         = I_item_loc_rec.uom_of_price,
             selling_uom          = I_item_loc_rec.selling_uom,
             primary_cost_pack    = I_item_loc_rec.primary_cost_pack,
             receive_as_type      = I_item_loc_rec.receive_as_type,
             source_method        = I_item_loc_rec.source_method,
             source_wh            = I_item_loc_rec.source_wh,
             last_update_datetime = sysdate,
             last_update_id       = user,
             inbound_handling_days = I_item_loc_rec.inbound_handling_days,
             store_price_ind      = nvl(I_store_price_ind, 'N')
       where item = I_item
         and loc = I_loc;
   end if;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                              'ITEM_LOC',
                                                              I_item,
                                                              I_loc);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_TABLE;
-----------------------------------------------------------------
FUNCTION UPDATE_ITEM_LOC_FOR_KIDS(O_error_message    IN OUT   VARCHAR2,
                                  I_item             IN       item_master.item%TYPE,
                                  I_loc              IN       item_loc.loc%TYPE,
                                  I_item_loc_rec     IN OUT   item_loc_attr_rectype,
                                  I_status_updated   IN       BOOLEAN)
return BOOLEAN is

L_program            VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_ITEM_LOC_FOR_KIDS';
L_status_update_date ITEM_LOC.STATUS_UPDATE_DATE%TYPE;

cursor C_GET_ITEM_CHILDREN is
   select item,
          status,
          item_level,
          tran_level
     from item_master
    where ((item_parent = I_item) or
           (item_grandparent = I_item))
      and tran_level >= item_level;

BEGIN
   -- The primary variant is not updated for child items.
   I_item_loc_rec.primary_variant := NULL;

   FOR item_child_rec IN C_GET_ITEM_CHILDREN LOOP
      if (I_item_loc_rec.loc_type = 'S') and
         (item_child_rec.status = 'A') and
         (item_child_rec.item_level = item_child_rec.tran_level) then

         if I_status_updated then
            if INSERT_STATUS_POS_MOD(O_error_message,
                                     item_child_rec.item,
                                     I_loc,
                                     I_item_loc_rec.status) = FALSE then
               return FALSE;
            end if;
         end if;

         if INSERT_POS_MODS(O_error_message,
                            item_child_rec.item,
                            I_loc,
                            I_item_loc_rec.local_item_desc,
                            I_item_loc_rec.local_short_desc,
                            I_item_loc_rec.taxable_ind) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      if UPDATE_TABLE(O_error_message,
                      item_child_rec.item,
                      I_loc,
                      I_item_loc_rec,
                      I_status_updated) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_ITEM_LOC_FOR_KIDS;
-----------------------------------------------------------------
FUNCTION UPDATE_STATUS_FOR_KIDS(O_error_message   IN OUT   VARCHAR2,
                                I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                I_loc             IN       ITEM_LOC.LOC%TYPE,
                                I_loc_type        IN       ITEM_LOC.LOC_TYPE%TYPE,
                                I_status          IN       ITEM_LOC.STATUS%TYPE)
return BOOLEAN is

   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   L_item_status   ITEM_MASTER.STATUS%TYPE;
   L_program       VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_STATUS_FOR_KIDS';
   L_child_item    ITEM_MASTER.ITEM%TYPE;
   L_dummy         VARCHAR2(1);

   cursor C_LOCK_ITEM_LOC(C_item IN item_master.item%TYPE) is
      select 'x'
        from item_loc
       where loc = I_loc
         and item = C_item
         for update of status nowait;

   cursor C_GET_ITEM_CHILDREN is
      select im.item,
             im.item_level,
             im.tran_level,
             im.status
        from item_master im,
             item_loc il
       where im.item = il.item
         and il.loc  = I_loc
         and ((im.item_parent = I_item) or (im.item_grandparent = I_item))
         and im.tran_level >= im.item_level;

BEGIN
   FOR item_child_rec IN C_GET_ITEM_CHILDREN LOOP
      if (I_loc_type = 'S') and
         (item_child_rec.status = 'A') and
         (item_child_rec.item_level = item_child_rec.tran_level) then

         if INSERT_STATUS_POS_MOD(O_error_message,
                                  item_child_rec.item,
                                  I_loc,
                                  I_status) = FALSE then
            return FALSE;
         end if;
      end if;

      L_child_item := item_child_rec.item;

      open C_LOCK_ITEM_LOC(L_child_item);
      close C_LOCK_ITEM_LOC;

      update item_loc
         set status = I_status,
             status_update_date   = SYSDATE,
             last_update_datetime = SYSDATE,
             last_update_id       = USER
       where item = item_child_rec.item
         and loc = I_loc;
   END LOOP;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                              'ITEM_ZONE_PRICE',
                                                              L_child_item,
                                                              I_loc);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_STATUS_FOR_KIDS;
-----------------------------------------------------------------
FUNCTION UPDATE_ITEM_LOC(O_error_message           IN OUT   VARCHAR2,
                         I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                         I_item_status             IN       ITEM_MASTER.STATUS%TYPE,
                         I_item_level              IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                         I_tran_level              IN       ITEM_MASTER.TRAN_LEVEL%TYPE,
                         I_loc                     IN       ITEM_LOC.LOC%TYPE,
                         I_loc_type                IN       ITEM_LOC.LOC_TYPE%TYPE,
                         I_primary_supp            IN       ITEM_LOC.PRIMARY_SUPP%TYPE,
                         I_primary_cntry           IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                         I_status                  IN       ITEM_LOC.STATUS%TYPE,
                         I_local_item_desc         IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                         I_local_short_desc        IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                         I_primary_variant         IN       ITEM_LOC.PRIMARY_VARIANT%TYPE,
                         I_unit_retail             IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                         I_ti                      IN       ITEM_LOC.TI%TYPE,
                         I_hi                      IN       ITEM_LOC.HI%TYPE,
                         I_store_ord_mult          IN       ITEM_LOC.STORE_ORD_MULT%TYPE,
                         I_daily_waste_pct         IN       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                         I_taxable_ind             IN       ITEM_LOC.TAXABLE_IND%TYPE,
                         I_meas_of_each            IN       ITEM_LOC.MEAS_OF_EACH%TYPE,
                         I_meas_of_price           IN       ITEM_LOC.MEAS_OF_PRICE%TYPE,
                         I_uom_of_price            IN       ITEM_LOC.UOM_OF_PRICE%TYPE,
                         I_selling_unit_retail     IN       ITEM_LOC.SELLING_UNIT_RETAIL%TYPE,
                         I_selling_uom             IN       ITEM_LOC.SELLING_UOM%TYPE,
                         I_primary_cost_pack       IN       ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                         I_process_children        IN       VARCHAR2,
                         I_receive_as_type         IN       ITEM_LOC.RECEIVE_AS_TYPE%TYPE,
                         I_inbound_handling_days   IN       ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE,
                         I_store_price_ind         IN       ITEM_LOC.STORE_PRICE_IND%TYPE,
                         I_source_method           IN       ITEM_LOC.SOURCE_METHOD%TYPE ,
                         I_source_wh               IN       ITEM_LOC.SOURCE_WH%TYPE,
                         I_multi_units             IN       ITEM_LOC.MULTI_UNITS%TYPE,
                         I_multi_unit_retail       IN       ITEM_LOC.MULTI_UNIT_RETAIL%TYPE,
                         I_multi_selling_uom       IN       ITEM_LOC.MULTI_SELLING_UOM%TYPE)
return BOOLEAN is

   L_dummy                 VARCHAR2(1);
   L_program               VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_ITEM_LOC';
   L_status_updated        BOOLEAN := FALSE;
   L_item_loc_rec          item_loc_attr_rectype;

BEGIN
   -- Set item loc rec
   L_item_loc_rec.loc_type              := I_loc_type;
   L_item_loc_rec.primary_supp          := I_primary_supp;
   L_item_loc_rec.primary_cntry         := I_primary_cntry;
   L_item_loc_rec.status                := I_status;
   L_item_loc_rec.local_item_desc       := I_local_item_desc;
   L_item_loc_rec.local_short_desc      := I_local_short_desc;
   L_item_loc_rec.primary_variant       := I_primary_variant;
   L_item_loc_rec.unit_retail           := I_unit_retail;
   L_item_loc_rec.ti                    := I_ti;
   L_item_loc_rec.hi                    := I_hi;
   L_item_loc_rec.store_ord_mult        := I_store_ord_mult;
   L_item_loc_rec.daily_waste_pct       := I_daily_waste_pct;
   L_item_loc_rec.taxable_ind           := I_taxable_ind;
   L_item_loc_rec.meas_of_each          := I_meas_of_each;
   L_item_loc_rec.meas_of_price         := I_meas_of_price;
   L_item_loc_rec.uom_of_price          := I_uom_of_price;
   L_item_loc_rec.selling_unit_retail   := I_selling_unit_retail;
   L_item_loc_rec.selling_uom           := I_selling_uom;
   L_item_loc_rec.primary_cost_pack     := I_primary_cost_pack;
   L_item_loc_rec.receive_as_type       := I_receive_as_type;
   L_item_loc_rec.inbound_handling_days := I_inbound_handling_days;
   L_item_loc_rec.multi_units           := I_multi_units;
   L_item_loc_rec.multi_unit_retail     := I_multi_unit_retail;
   L_item_loc_rec.multi_selling_uom     := I_multi_selling_uom;

   if I_loc_type = 'S' and I_source_method is NULL then
      L_item_loc_rec.source_method      := 'S';
   else
      L_item_loc_rec.source_method      := I_source_method;
   end if;

   L_item_loc_rec.source_wh := I_source_wh;

   ---
   -- If the supplier and origin country have been changed, the item/loc's
   -- unit cost may need to be updated.
   if UPDATE_COST(O_error_message,
                  I_item,
                  I_loc,
                  I_primary_supp,
                  I_primary_cntry,
                  I_process_children) = FALSE then
      return FALSE;
   end if;

   -- Determine if the item/loc status will be updated.
   if STATUS_UPDATED(O_error_message,
                     L_status_updated,
                     I_item,
                     I_loc,
                     I_status) = FALSE then
      return FALSE;
   end if;
   ---
   -- For transaction level items with approved status at stores, an insert into pos mods
   -- may be required if certian item/loc attributes have been updated.
   if (I_loc_type = 'S') and
      (I_item_status = 'A') then

      if I_item_level = I_tran_level then

         if L_status_updated then
            if INSERT_STATUS_POS_MOD(O_error_message,
                                     I_item,
                                     I_loc,
                                     I_status) = FALSE then
               return FALSE;
            end if;
         end if;

         if INSERT_POS_MODS(O_error_message,
                            I_item,
                            I_loc,
                            I_local_item_desc,
                            I_local_short_desc,
                            I_taxable_ind) = FALSE then
            return FALSE;
         end if;
      end if; -- item level = tran level

      if INSERT_PRIM_VARIANT_POS_MODS(O_error_message,
                                      I_item,
                                      I_loc,
                                      L_item_loc_rec) = FALSE then
         return FALSE;
      end if;

   end if; -- loc type = 'S' and item status = 'A'
   ---
   if UPDATE_TABLE(O_error_message,
                   I_item,
                   I_loc,
                   L_item_loc_rec,
                   L_status_updated,
                   I_store_price_ind
                   ) = FALSE then
      return FALSE;
   end if;


   -- Process the children.
   if I_process_children = 'Y' then
      if UPDATE_ITEM_LOC_FOR_KIDS(O_error_message,
                                  I_item,
                                  I_loc,
                                  L_item_loc_rec,
                                  L_status_updated) = FALSE then
         return FALSE;
      end if;

      -- Note: The item/loc rec returned by update_item_loc_for_kids may have
      -- been modified because the parameter is declared as IN OUT.

   -- Status is always updated for children.
   elsif L_status_updated then
      if UPDATE_STATUS_FOR_KIDS(O_error_message,
                                I_item,
                                I_loc,
                                I_loc_type,
                                I_status) = FALSE then
         return FALSE;
      end if;
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_ITEM_LOC;
-----------------------------------------------------------------
FUNCTION ITEM_LOC_ORDERS_EXIST(O_error_message   OUT   VARCHAR2,
                               O_orders_exist    OUT   BOOLEAN,
                               I_item            IN    ITEM_MASTER.ITEM%TYPE,
                               I_loc             IN    ITEM_LOC.LOC%TYPE)
return BOOLEAN is

   L_dummy              VARCHAR2(1);
   L_program            VARCHAR2(64) := 'ITEM_LOC_SQL.ITEM_LOC_ORDERS_EXIST';

   cursor C_ORDERS_EXIST is
      select 'x'
        from ordloc ol,
             ordhead oh
       where oh.order_no = ol.order_no
         and ol.location = I_loc
         and ol.item     = I_item
         and oh.status in ('W', 'S', 'A');

BEGIN
   open C_ORDERS_EXIST;
   fetch C_ORDERS_EXIST into L_dummy;

   O_orders_exist := C_ORDERS_EXIST%FOUND;

   close C_ORDERS_EXIST;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END ITEM_LOC_ORDERS_EXIST;
-----------------------------------------------------------------


-----------------------------------------------------------------
FUNCTION ITEM_LOC_TRANSFERS_EXIST(O_error_message     OUT   VARCHAR2,
                                  O_transfers_exist   OUT   BOOLEAN,
                                  I_item              IN    ITEM_MASTER.ITEM%TYPE,
                                  I_loc               IN    ITEM_LOC.LOC%TYPE)
return BOOLEAN is

   L_dummy              VARCHAR2(1);
   L_program            VARCHAR2(64) := 'ITEM_LOC_SQL.ITEM_LOC_TRANSFERS_EXIST';

   cursor C_TRANSFERS_EXIST is
      select 'Y'
        from tsfhead th,
             tsfdetail td
       where th.status in ('I','A','S','E')
         and th.to_loc = I_loc
         and th.tsf_no = td.tsf_no
         and td.item   = I_item;

BEGIN
   open C_TRANSFERS_EXIST;
   fetch C_TRANSFERS_EXIST into L_dummy;

   O_transfers_exist := C_TRANSFERS_EXIST%FOUND;

   close C_TRANSFERS_EXIST;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END ITEM_LOC_TRANSFERS_EXIST;
-----------------------------------------------------------------
FUNCTION CHECK_DEPENDENCIES(O_error_message        IN OUT   VARCHAR2,
                            O_dependencies_exist   IN OUT   BOOLEAN,
                            I_item                 IN       ITEM_MASTER.ITEM%TYPE,
                            I_loc                  IN       ITEM_LOC.LOC%TYPE,
                            I_loc_type             IN       ITEM_LOC.LOC_TYPE%TYPE)
return BOOLEAN is

   L_exist   BOOLEAN      := FALSE;
   L_program VARCHAR2(64) := 'ITEM_LOC_SQL.CHECK_DEPENDENCIES';

BEGIN
   if ITEM_LOC_ORDERS_EXIST(O_error_message,
                            L_exist,
                            I_item,
                            I_loc) = FALSE then
      return FALSE;
   end if;
   ---
   if L_exist then
      O_error_message := SQL_LIB.CREATE_MSG('ITEM_LOC_ORD_EXIST',
                                            I_item,
                                            to_char(I_loc),
                                            NULL);
      O_dependencies_exist := TRUE;
      return TRUE;
   end if;
   ---

   if ITEM_LOC_TRANSFERS_EXIST(O_error_message,
                               L_exist,
                               I_item,
                               I_loc) = FALSE then
      return FALSE;
   end if;
   ---
   if L_exist then
      O_error_message := SQL_LIB.CREATE_MSG('ITEM_LOC_TSF_EXIST',
                                            I_item,
                                            to_char(I_loc),
                                            NULL);

      O_dependencies_exist := TRUE;
      return TRUE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_DEPENDENCIES;
-----------------------------------------------------------------
FUNCTION CHECK_NEW_STATUS(O_error_message   IN OUT   VARCHAR2,
                          I_item            IN       ITEM_MASTER.ITEM%TYPE,
                          I_loc             IN       ITEM_LOC.LOC%TYPE,
                          I_loc_type        IN       ITEM_LOC.LOC_TYPE%TYPE,
                          I_old_status      IN       ITEM_LOC.STATUS%TYPE,
                          I_new_status      IN       ITEM_LOC.STATUS%TYPE)
return BOOLEAN is

   L_program             VARCHAR2(64) := 'ITEM_LOC_SQL.CHECK_NEW_STATUS';
   L_store               store.store%TYPE;
   L_wh                  wh.wh%TYPE;
   L_dependencies_exist  BOOLEAN;
   L_item_in_active_pack BOOLEAN;
   L_exists_as_source    BOOLEAN;

BEGIN
   /*
    * If the new status (I_new_status) is 'D' (delete) or 'I' (inactive),
    * then processing needs to check for current dependencies or current
    * pack dependencies.
    */
   if I_new_status in('D', 'I') then
      if CHECK_DEPENDENCIES(O_error_message,
                            L_dependencies_exist,
                            I_item,
                            I_loc,
                            I_loc_type) = FALSE then
         return FALSE;
      end if;

      -- Return the error message returned by check_dependencies.
      if L_dependencies_exist then
         return FALSE;
      end if;

      if ITEMLOC_ATTRIB_SQL.ITEM_IN_ACTIVE_PACK(O_error_message,
                                                I_item,
                                                I_loc,
                                                L_item_in_active_pack) = FALSE then
         return FALSE;
      end if;

      if L_item_in_active_pack then
         O_error_message := SQL_LIB.CREATE_MSG('ITEM_IN_ACTIVE_PACK',
                                               I_item,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;
   end if;

   /*
    * If the old status (I_old_status) is 'A' (active), the
    * new status (I_new_status) is 'D' (delete),  'I' (inactive),
    * or 'C' (discontinued), and the location type
    * is 'W' (warehouse), then processing needs to determine whether
    * the warehouse is a source warehouse.
    */
   if (I_old_status = 'A') and
      (I_new_status in('D', 'I', 'C')) and
      (I_loc_type = 'W') then

      if REPLENISHMENT_SQL.WH_EXISTS_AS_SOURCE(O_error_message,
                                               L_exists_as_source,
                                               I_item,
                                               I_loc) = FALSE then
         return FALSE;
      end if;

      if L_exists_as_source then
         O_error_message := SQL_LIB.CREATE_MSG('ITEMLOC_SOURCE_WH',
                                               I_loc,
                                               I_item,
                                               NULL);
         return FALSE;
      end if;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_NEW_STATUS;
-----------------------------------------------------------------
FUNCTION STATUS_CHANGE_VALID(O_error_message   IN OUT   VARCHAR2,
                            I_item             IN       ITEM_MASTER.ITEM%TYPE,
                            I_loc              IN       ITEM_LOC.LOC%TYPE,
                            I_loc_type         IN       ITEM_LOC.LOC_TYPE%TYPE,
                            I_old_status       IN       ITEM_LOC.STATUS%TYPE,
                            I_new_status       IN       ITEM_LOC.STATUS%TYPE)
return BOOLEAN is

L_program             VARCHAR2(64) := 'ITEM_LOC_SQL.STATUS_CHANGE_VALID';

cursor C_GET_ITEM_CHILDREN is
   select item
     from item_master
    where ((item_parent = I_item) or
           (item_grandparent = I_item))
      and tran_level >= item_level;

BEGIN
   if CHECK_NEW_STATUS(O_error_message,
                       I_item,
                       I_loc,
                       I_loc_type,
                       I_old_status,
                       I_new_status) = FALSE then
      return FALSE;
   end if;

   FOR item_rec IN C_GET_ITEM_CHILDREN LOOP
      if CHECK_NEW_STATUS(O_error_message,
                          item_rec.item,
                          I_loc,
                          I_loc_type,
                          I_old_status,
                          I_new_status) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END STATUS_CHANGE_VALID;
-----------------------------------------------------------------
FUNCTION LOCS_EXIST_FOR_GROUP(O_error_message   IN OUT   VARCHAR2,
                              O_locs_exist      IN OUT   BOOLEAN,
                              I_group_type      IN       CODE_DETAIL.CODE%TYPE,
                              I_group_value     IN       VARCHAR2,
                              I_zone_group_id   IN       PRICE_ZONE_GROUP_STORE.ZONE_GROUP_ID%TYPE)
return BOOLEAN is

   L_locs_table locs_table_type;
   L_program    VARCHAR2(64) := 'ITEM_LOC_SQL.LOCS_EXIST_FOR_GROUP';
   L_loc        item_loc.loc%TYPE;
   L_dummy      VARCHAR2(1);


   -- This cursor validates that the user has visibility to the location
   -- by joining it to v_store or v_wh.

   cursor C_LOC_VALID_FOR_USER is
      select 'x'
        from v_store vs
       where vs.store = L_loc
       union
      select 'x'
        from v_wh vw
       where vw.wh = L_loc;

BEGIN

   if GROUP_LOCS_FOR_CURRENCY(O_error_message,
                              L_locs_table,
                              I_group_type,
                              I_group_value,
                              I_zone_group_id, --- zone_group_id
                              NULL) = FALSE then
      return FALSE;
   end if;

   if L_locs_table.EXISTS(1) = TRUE then
      -- Need to ensure that the user has access to at least one of the
      -- locations
      FOR loop_index IN 1..L_locs_table.COUNT LOOP

         L_loc := L_locs_table(loop_index);
         open C_LOC_VALID_FOR_USER;

         fetch C_LOC_VALID_FOR_USER into L_dummy;
            if C_LOC_VALID_FOR_USER%FOUND then
               O_locs_exist := TRUE;
            else
               O_locs_exist := FALSE;
               O_error_message := SQL_LIB.CREATE_MSG('NO_LOCS_GROUP_USER',
                                                      NULL,
                                                      NULL,
                                                      NULL);
            end if;
         close C_LOC_VALID_FOR_USER;

         if O_locs_exist = TRUE then
            EXIT;
         end if;

      END LOOP;
   else
     O_locs_exist := FALSE;
     O_error_message := SQL_LIB.CREATE_MSG('NO_LOCS_GROUP',
                                            NULL,
                                            NULL,
                                            NULL);
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END LOCS_EXIST_FOR_GROUP;
-----------------------------------------------------------------
FUNCTION CHECK_LOC_TRAITS_COMPLETE(O_error_message   IN OUT   VARCHAR2,
                                   O_complete        IN OUT   VARCHAR2,
                                   I_item            IN       ITEM_MASTER.ITEM%TYPE,
                                   I_loc             IN       ITEM_LOC.LOC%TYPE)
return BOOLEAN is

   L_dummy   VARCHAR2(1);
   L_program VARCHAR2(64) := 'ITEM_LOC_SQL.CHECK_LOC_TRAITS_COMPLETE';

   cursor C_LOC_TRAITS_COMPLETE is
      select 'x'
        from item_loc_traits
       where item = I_item
         and loc  = nvl(I_loc, loc);

BEGIN
   open C_LOC_TRAITS_COMPLETE;
   fetch C_LOC_TRAITS_COMPLETE into L_dummy;

   if C_LOC_TRAITS_COMPLETE%NOTFOUND then
      O_complete := 'N';
   else
      O_complete := 'Y';
   end if;

   close C_LOC_TRAITS_COMPLETE;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_LOC_TRAITS_COMPLETE;
-----------------------------------------------------------------
FUNCTION ITEM_EXISTS_FOR_ALL_GROUP_LOCS(O_error_message         IN OUT   VARCHAR2,
                                        O_item_exists           IN OUT   BOOLEAN,
                                        O_item_active_at_locs   IN OUT   BOOLEAN,
                                        I_item                  IN       ITEM_MASTER.ITEM%TYPE,
                                        I_group_type            IN       CODE_DETAIL.CODE%TYPE,
                                        I_group_value           IN       VARCHAR2,
                                        I_price_zone_group      IN       PRICE_ZONE.ZONE_GROUP_ID%TYPE,
                                        I_currency_code         IN       CURRENCIES.CURRENCY_CODE%TYPE)
return BOOLEAN is

   L_locs_table       LOCS_TABLE_TYPE;
   L_program          VARCHAR2(64) := 'ITEM_LOC_SQL.ITEM_EXISTS_FOR_ALL_GROUP_LOCS';
   L_loc              ITEM_LOC.LOC%TYPE;
   L_dummy            VARCHAR2(1);
   L_item_exists_user BOOLEAN;
   L_status           ITEM_LOC.STATUS%TYPE;

   -- This cursor validates that the user has visibility to the location
   -- by joining it to v_store or v_wh

   cursor C_LOC_VALID_FOR_USER is
      select 'x'
        from v_store vs
       where vs.store = L_loc
       union
      select 'x'
        from v_wh vw
       where vw.wh = L_loc;

   cursor C_ALL_LOCS_EXIST is
      select status
        from item_loc
       where item = I_item
         and loc  = L_loc;

BEGIN
   if GROUP_LOCS_FOR_CURRENCY(O_error_message,
                              L_locs_table,
                              I_group_type,
                              I_group_value,
                              I_price_zone_group,
                              I_currency_code) = FALSE then
      return FALSE;
   end if;

   -- If there are no locs in the group, then O_item_exists should be FALSE.
   -- Initially set item to be active at all locations.  If it is not, the
   -- variable will be changed to false.
   O_item_exists         := FALSE;
   O_item_active_at_locs := TRUE;
   FOR loop_index IN 1..L_locs_table.COUNT LOOP
      L_loc := L_locs_table(loop_index);

      -- "Weed-Out" locations that the user does not have access to.
      open C_LOC_VALID_FOR_USER;
      fetch C_LOC_VALID_FOR_USER into L_dummy;
      if C_LOC_VALID_FOR_USER%FOUND then

         close C_LOC_VALID_FOR_USER;

         -- Check if Item Loc association exists
         open C_ALL_LOCS_EXIST;
         fetch C_ALL_LOCS_EXIST into L_status;
         if C_ALL_LOCS_EXIST%NOTFOUND then
            O_item_exists := FALSE;
         else
            O_item_exists := TRUE;
         end if;
         close C_ALL_LOCS_EXIST;

         if L_status != 'A' then
            O_item_active_at_locs := FALSE;
         end if;

      else
         close C_LOC_VALID_FOR_USER;
      end if;

      if O_item_exists = FALSE then
         EXIT;
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END ITEM_EXISTS_FOR_ALL_GROUP_LOCS;
-----------------------------------------------------------------
FUNCTION CHECK_PACK_COMP_ITEMLOC_STATUS(O_error_message        IN OUT   VARCHAR2,
                                        O_inactive_status      IN OUT   BOOLEAN,
                                        O_delete_disc_status   IN OUT   BOOLEAN,
                                        I_packitem             IN       ITEM_MASTER.ITEM%TYPE,
                                        I_group_type           IN       VARCHAR2,
                                        I_group_value          IN       VARCHAR2,
                                        I_price_zone_group     IN       ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE,
                                        I_currency_code        IN       CURRENCIES.CURRENCY_CODE%TYPE)
return BOOLEAN is

   L_locs_table   locs_table_type;

   L_item         ITEM_LOC.ITEM%TYPE;
   L_loc          ITEM_LOC.LOC%TYPE;
   L_status       ITEM_LOC.STATUS%TYPE;

   L_dummy        VARCHAR2(1);
   L_program      VARCHAR2(64) := 'ITEM_LOC_SQL.CHECK_PACK_COMP_ITEMLOC_STATUS';

   cursor C_GET_ALL_ITEM is
      select im.item
        from item_master im,
             packitem pi
       where im.item    = pi.item
         and pi.pack_no = I_packitem;

   cursor C_GET_STATUS is
         select status
           from item_loc
          where item = L_item
            and loc  = L_loc;

BEGIN
   if GROUP_LOCS_FOR_CURRENCY(O_error_message,
                              L_locs_table,
                              I_group_type,
                              I_group_value,
                              I_price_zone_group,
                              I_currency_code) = FALSE then
      return FALSE;
   end if;

   O_inactive_status    := FALSE;
   O_delete_disc_status := FALSE;

   FOR loop_index IN 1..L_locs_table.COUNT LOOP
     FOR rec in C_GET_ALL_ITEM LOOP
         L_item := rec.item;
         L_loc  := L_locs_table(loop_index);
         ---
         if L_item is not null then
            open C_GET_STATUS;
            fetch C_GET_STATUS into L_status;
            ---
            if L_status = 'I' then
               O_inactive_status := TRUE;
            elsif L_status in ('D','C') then
               O_delete_disc_status := TRUE;
            end if;
            ---
            close C_GET_STATUS;
         end if;
      END LOOP;
      ---
      if O_delete_disc_status and O_inactive_status then
         EXIT;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_PACK_COMP_ITEMLOC_STATUS;
-----------------------------------------------------------------
FUNCTION UPDATE_PACK_COMP_STATUS(O_error_message      IN OUT   VARCHAR2,
                                 I_packitem           IN       ITEM_MASTER.ITEM%TYPE,
                                 I_group_type         IN       VARCHAR2,
                                 I_group_value        IN       VARCHAR2,
                                 I_price_zone_group   IN       ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE,
                                 I_currency_code      IN       CURRENCIES.CURRENCY_CODE%TYPE)
return BOOLEAN is

   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);

   L_locs_table locs_table_type;
   L_item        item_master.item%TYPE;
   L_tran_level  item_master.tran_level%TYPE;
   L_item_level  item_master.item_level%TYPE;
   L_status      item_master.status%TYPE;
   L_loc         item_loc.loc%TYPE;
   L_loc_type    item_loc.loc_type%TYPE;
   L_rowid       ROWID;
   L_program    VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_PACK_COMP_STATUS';

   cursor C_GET_ALL_ITEM is
         select im.item,
                im.item_level,
                im.tran_level,
                im.status
           from item_master im,
                packitem pi
          where (im.item = pi.item or im.item_parent = pi.item or im.item_grandparent = pi.item)
            and pi.pack_no = I_packitem
         union
         select item,
                item_level,
                tran_level,
                status
           from item_master
          where item in (select im.item_parent
                           from item_master im,
                                packitem pi
                          where im.item = pi.item
                            and pi.pack_no = I_packitem)
         union
         select item,
                item_level,
                tran_level,
                status
           from item_master
          where item in (select im.item_grandparent
                           from item_master im,
                                packitem pi
                          where im.item = pi.item
                            and pi.pack_no = I_packitem);

      cursor C_LOCK_ITEM_LOC is
         select rowid,
                loc_type
           from item_loc
          where item   = L_item
            and loc    = L_loc
            and status = 'I'
            for update nowait;

BEGIN
   if GROUP_LOCS_FOR_CURRENCY(O_error_message,
                              L_locs_table,
                              I_group_type,
                              I_group_value,
                              I_price_zone_group,
                              I_currency_code) = FALSE then
      return FALSE;
   end if;

   FOR loop_index IN 1..L_locs_table.COUNT LOOP
      FOR rec in C_GET_ALL_ITEM loop
         L_item       := rec.item;
         L_tran_level := rec.tran_level;
         L_item_level := rec.item_level;
         L_status     := rec.status;
         L_loc        := L_locs_table(loop_index);

         open C_LOCK_ITEM_LOC;
         fetch C_LOCK_ITEM_LOC into L_rowid, L_loc_type;
         ---
         if C_LOCK_ITEM_LOC%FOUND then
            update item_loc
               set status = 'A',
                   last_update_datetime = SYSDATE,
                   last_update_id       = USER
             where rowid = L_rowid;
            ---
            if (L_loc_type = 'S') and (L_status = 'A') and (L_item_level = L_tran_level) then
               if INSERT_STATUS_POS_MOD(O_error_message,
                                        L_item,
                                        L_loc,
                                        'A') = FALSE then
                  close C_LOCK_ITEM_LOC;
                  return FALSE;
               end if;
            end if;
            ---
         end if;

         close C_LOCK_ITEM_LOC;

      END LOOP;

   END LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                              'ITEM_LOC',
                                                              I_packitem,
                                                              I_group_value);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_PACK_COMP_STATUS;
-----------------------------------------------------------------
FUNCTION UPDATE_RECV_AS_TYPE(O_error_message     IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_item              IN       ITEM_LOC.ITEM%TYPE,
                             I_location          IN       ITEM_LOC.LOC%TYPE,
                             I_receive_as_type   IN       ITEM_LOC.RECEIVE_AS_TYPE%TYPE)
   return BOOLEAN IS

   L_pwh           WH.WH%TYPE;
   L_program       VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_RECV_AS_TYPE';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_LOC is
      select 'x'
        from item_loc il
       where item = I_item
         and exists (select wh
                       from wh
                      where physical_wh      = L_pwh
                        and stockholding_ind = 'Y'
                        and il.loc           = wh.wh)
         and loc != I_location
         for UPDATE NOWAIT;

BEGIN
   if WH_ATTRIB_SQL.GET_PWH_FOR_VWH(O_error_message,
                                    L_pwh,
                                    I_location)= FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_LOC','ITEM_LOC','LOCATION: '||to_char(I_location));
   open C_LOCK_ITEM_LOC;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_LOC','ITEM_LOC','LOCATION: '||to_char(I_location));
   close C_LOCK_ITEM_LOC;
   ---
   update item_loc il
      set receive_as_type = I_receive_as_type,
          last_update_datetime = SYSDATE,
          last_update_id       = USER
    where item            = I_item
      and exists (select wh
                    from wh
                   where physical_wh      = L_pwh
                     and stockholding_ind = 'Y'
                     and il.loc           = wh.wh)
      and loc != I_location;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                              'ITEM_LOC',
                                                              I_item,
                                                              I_location);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_RECV_AS_TYPE;
------------------------------------------------------------------------------------
FUNCTION GET_RECV_AS_TYPE_FOR_VWH(O_error_message     IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_exists            IN OUT    VARCHAR2,
                                  O_receive_as_type   IN OUT    ITEM_LOC.RECEIVE_AS_TYPE%TYPE,
                                  I_location          IN        ITEM_LOC.LOC%TYPE,
                                  I_item              IN        ITEM_LOC.ITEM%TYPE)
   return BOOLEAN IS

   cursor C_ITMLOC_RELATION(P_pwh WH.WH%TYPE)is
      select receive_as_type
        from item_loc il
       where item = I_item
         and exists (select wh
                       from wh
                      where physical_wh      = P_pwh
                        and stockholding_ind = 'Y'
                        and il.loc           = wh.wh);

   L_pwh       WH.WH%TYPE;
   L_program   VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_RECV_AS_TYPE';
BEGIN
   if WH_ATTRIB_SQL.GET_PWH_FOR_VWH(O_error_message,
                                    L_pwh,
                                    I_location)= FALSE then
      return FALSE;
   end if;
   ---
   for C_rec in C_ITMLOC_RELATION(L_pwh)
   loop
      if C_rec.receive_as_type is NOT NULL then
         O_receive_as_type := C_rec.receive_as_type;
         O_exists := 'Y';
         exit;
      else
         O_receive_as_type := NULL;
         O_exists := 'N';
      end if;
   end loop;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END GET_RECV_AS_TYPE_FOR_VWH;
----------------------------------------------------------------------------------------------------
FUNCTION CHILD_LOCS_EXIST(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          O_child_locs_exist   IN OUT   BOOLEAN,
                          I_item               IN       ITEM_LOC.ITEM%TYPE)

   return BOOLEAN is

   L_dummy   VARCHAR2(1);
   L_program VARCHAR2(64) := 'ITEM_LOC_SQL.CHILD_LOCS_EXIST';

   cursor C_CHILD_LOCS_EXIST is
      select 'x'
        from item_loc
       where item_parent = I_item
          or item_grandparent = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_CHILD_LOCS_EXIST', 'item_loc', NULL);
   open C_CHILD_LOCS_EXIST;
   SQL_LIB.SET_MARK('FETCH', 'C_CHILD_LOCS_EXIST', 'item_loc', NULL);
   fetch C_CHILD_LOCS_EXIST into L_dummy;

   if C_CHILD_LOCS_EXIST%NOTFOUND then
      O_child_locs_exist := FALSE;
   else
      O_child_locs_exist := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_CHILD_LOCS_EXIST', 'item_loc', NULL);
   close C_CHILD_LOCS_EXIST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;

END CHILD_LOCS_EXIST;
---------------------------------------------------------------------------------
FUNCTION CHECK_PRIMARY_COST_PACK(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_exists          IN OUT   VARCHAR2,
                                 I_item            IN       ITEM_LOC.ITEM%TYPE,
                                 I_loc             IN       ITEM_LOC.LOC%TYPE)
   return BOOLEAN IS
   L_program       VARCHAR2(64) := 'ITEM_LOC_SQL.CHECK_PRIMARY_COST_PACK';
   L_rowid         ROWID;
   cursor C_ITEM_LOC(P_item item_loc.item%TYPE ) is
      select rowid
        from item_loc
       where loc   = I_loc
         and item  = P_item
         and primary_cost_pack is not null;
   cursor C_PACK_ITEM is
      select item
        from packitem
       where pack_no  = I_item;
BEGIN
    FOR c_pack_item_rec in C_PACK_ITEM loop
       open C_ITEM_LOC(c_pack_item_rec.item);
       fetch C_ITEM_LOC into L_rowid;
       if L_rowid is not null then
          O_exists := 'Y';
         exit;
       else
         O_exists := 'N';
       end if;
       close C_ITEM_LOC;
    END LOOP;
    return TRUE;
 EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
 END CHECK_PRIMARY_COST_PACK;
 ----------------------------------------------------------------------------------------------
FUNCTION UPDATE_PRIMARY_COST_PACK(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_item            IN       ITEM_LOC.ITEM%TYPE,
                                  I_loc             IN       ITEM_LOC.LOC%TYPE DEFAULT NULL)
   return BOOLEAN IS
   L_program       VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_PRIMARY_COST_PACK';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   L_rowid         ROWID;

   cursor C_LOCK_ITEM_LOC(P_item item_loc.item%TYPE ) is
      select rowid
        from item_loc
       where loc   = I_loc
         and item  = P_item
         and primary_cost_pack is not null
         for update nowait;
   ---
   cursor C_PACK_ITEM is
      select item
        from packitem
       where pack_no  = I_item;
BEGIN
    FOR c_pack_item_rec in C_PACK_ITEM loop
       open C_LOCK_ITEM_LOC(c_pack_item_rec.item);
       fetch C_LOCK_ITEM_LOC into L_rowid;
       update item_loc
          set primary_cost_pack = NULL,
          last_update_datetime  = SYSDATE,
          last_update_id        = USER
        where rowid = L_rowid;
       ---
       close C_LOCK_ITEM_LOC;
    END LOOP;

    return TRUE;
 EXCEPTION
   when RECORD_LOCKED then
      O_error_message :=O_error_message|| SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                                              'ITEM_LOC',
                                                              I_item,
                                                              I_loc);
      RETURN FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
 END UPDATE_PRIMARY_COST_PACK;
------------------------------------------------------------------------------------
FUNCTION ITEM_DESC_TO_ITEMLOC(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_item            IN       ITEM_MASTER.ITEM%TYPE,
                              I_item_desc       IN       ITEM_MASTER.ITEM_DESC%TYPE,
                              I_short_desc      IN       ITEM_MASTER.SHORT_DESC%TYPE,
                              I_item_level      IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                              I_tran_level      IN       ITEM_MASTER.TRAN_LEVEL%TYPE)
   RETURN BOOLEAN IS

   L_loc                       ITEM_LOC.LOC%TYPE;
   L_loc_type                  ITEM_LOC.LOC_TYPE%TYPE;
   L_current_loc_item_desc     ITEM_LOC.LOCAL_ITEM_DESC%TYPE;
   L_current_short_desc        ITEM_LOC.LOCAL_SHORT_DESC%TYPE;
   L_taxable_ind               ITEM_LOC.TAXABLE_IND%TYPE;
   L_program                   VARCHAR2(62)   := 'ITEM_LOC_SQL.ITEM_DESC_TO_ITEMLOC';
   RECORD_LOCKED               EXCEPTION;
   L_status                    VARCHAR2(1) := NULL;

  cursor C_ITEM is
      select 'A'
        from item_master
       where item = I_item
         and status = 'A';

  cursor C_LOCK is
      select 'x'
        from item_loc
       where item = I_item
         and loc  = L_loc
         for update nowait;

   cursor C_GET is
      select loc,
             loc_type,
             local_item_desc,
             local_short_desc,
             taxable_ind
        from item_loc
       where item     = I_item;


BEGIN

   SQL_LIB.SET_MARK('OPEN', 'C_ITEM', 'item_master', NULL);
   open C_ITEM;
   SQL_LIB.SET_MARK('FETCH', 'C_ITEM', 'item_master', NULL);
   fetch C_ITEM into L_status;
   SQL_LIB.SET_MARK('CLOSE', 'C_ITEM', 'item_MASTER', NULL);
   close C_ITEM;


   for rec in C_GET LOOP
      L_loc                   := rec.loc;
      L_loc_type              := rec.loc_type;
      L_current_loc_item_desc := rec.local_item_desc;
      L_current_short_desc    := rec.local_short_desc;
      L_taxable_ind           := rec.taxable_ind;

      -- If the Long Desc is changed the form changes the Short Desc automatically. Update both.
      if L_current_loc_item_desc != I_item_desc then
         ---
         if L_loc_type = 'S' and (I_item_level = I_tran_level) and L_status='A' then
            if INSERT_POS_MODS(O_error_message,
                               I_item,
                               L_loc,
                               I_item_desc,
                               I_short_desc,
                               L_taxable_ind) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         open  C_LOCK;
         close C_LOCK;
         update item_loc
            set local_item_desc  = I_item_desc,
                local_short_desc = I_short_desc,
                last_update_datetime = SYSDATE,
                last_update_id       = USER
          where item       = I_item
            and loc        = L_loc;

      -- if the Long Desc is unchanged only Update the Short Desc.
      elsif L_current_short_desc != I_short_desc then
         ---
         if L_loc_type = 'S' and (I_item_level = I_tran_level) and L_status='A' then
            if INSERT_POS_MODS(O_error_message,
                               I_item,
                               L_loc,
                               I_item_desc,
                               I_short_desc,
                               L_taxable_ind) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         open  C_LOCK;
         close C_LOCK;
         update item_loc
            set local_short_desc = I_short_desc,
            last_update_datetime = SYSDATE,
            last_update_id       = USER
          where item       = I_item
            and loc        = L_loc;
      end if;
   END LOOP;

   RETURN TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             'ITEM_LOC',
                                             'I_item',
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_DESC_TO_ITEMLOC;
-----------------------------------------------------------------------------------
FUNCTION ITEM_LOCATION_EXISTS(O_error_message          IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              O_item_location_exists   IN OUT   BOOLEAN,
                              I_item                   IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_item_loc_exists   VARCHAR2(1)  := NULL;
   L_program           VARCHAR2(64) := 'ITEM_LOC_SQL.ITEM_LOCATION_EXISTS';

   cursor C_ITEM_LOCATION_EXISTS is
      select 'x'
        from item_loc
       where item = I_item;

BEGIN

   open C_ITEM_LOCATION_EXISTS;
   fetch C_ITEM_LOCATION_EXISTS into L_item_loc_exists;
   close C_ITEM_LOCATION_EXISTS;

   O_item_location_exists := (L_item_loc_exists is NOT NULL);

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END ITEM_LOCATION_EXISTS;
-----------------------------------------------------------------
FUNCTION UPDATE_ITEM_LOC(O_error_message           IN OUT   VARCHAR2,
                         I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                         I_item_status             IN       ITEM_MASTER.STATUS%TYPE,
                         I_item_level              IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                         I_tran_level              IN       ITEM_MASTER.TRAN_LEVEL%TYPE,
                         I_loc                     IN       ITEM_LOC.LOC%TYPE,
                         I_loc_type                IN       ITEM_LOC.LOC_TYPE%TYPE,
                         I_primary_supp            IN       ITEM_LOC.PRIMARY_SUPP%TYPE,
                         I_primary_cntry           IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                         I_status                  IN       ITEM_LOC.STATUS%TYPE,
                         I_local_item_desc         IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                         I_local_short_desc        IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                         I_primary_variant         IN       ITEM_LOC.PRIMARY_VARIANT%TYPE,
                         I_unit_retail             IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                         I_ti                      IN       ITEM_LOC.TI%TYPE,
                         I_hi                      IN       ITEM_LOC.HI%TYPE,
                         I_store_ord_mult          IN       ITEM_LOC.STORE_ORD_MULT%TYPE,
                         I_daily_waste_pct         IN       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                         I_taxable_ind             IN       ITEM_LOC.TAXABLE_IND%TYPE,
                         I_meas_of_each            IN       ITEM_LOC.MEAS_OF_EACH%TYPE,
                         I_meas_of_price           IN       ITEM_LOC.MEAS_OF_PRICE%TYPE,
                         I_uom_of_price            IN       ITEM_LOC.UOM_OF_PRICE%TYPE,
                         I_selling_unit_retail     IN       ITEM_LOC.SELLING_UNIT_RETAIL%TYPE,
                         I_selling_uom             IN       ITEM_LOC.SELLING_UOM%TYPE,
                         I_primary_cost_pack       IN       ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                         I_process_children        IN       VARCHAR2,
                         I_receive_as_type         IN       ITEM_LOC.RECEIVE_AS_TYPE%TYPE,
                         I_inbound_handling_days   IN       ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE DEFAULT NULL,
                         I_store_price_ind         IN       ITEM_LOC.STORE_PRICE_IND%TYPE       DEFAULT NULL,
                         I_source_method           IN       ITEM_LOC.SOURCE_METHOD%TYPE         DEFAULT NULL,
                         I_source_wh               IN       ITEM_LOC.SOURCE_WH%TYPE             DEFAULT NULL)
return BOOLEAN is

   L_program               VARCHAR2(64) := 'ITEM_LOC_SQL.UPDATE_ITEM_LOC';

   L_multi_units             ITEM_LOC.MULTI_UNITS%TYPE;
   L_multi_unit_retail       ITEM_LOC.MULTI_UNIT_RETAIL%TYPE;
   L_multi_selling_uom       ITEM_LOC.MULTI_SELLING_UOM%TYPE;

BEGIN
   --- Overloaded for call from rmssub_xitemloc API
   ---
   if ITEM_LOC_SQL.UPDATE_ITEM_LOC(O_error_message,
                                   I_item,
                                   I_item_status,
                                   I_item_level,
                                   I_tran_level,
                                   I_loc,
                                   I_loc_type,
                                   I_primary_supp,
                                   I_primary_cntry,
                                   I_status,
                                   I_local_item_desc,
                                   I_local_short_desc,
                                   I_primary_variant,
                                   I_unit_retail,
                                   I_ti,
                                   I_hi,
                                   I_store_ord_mult,
                                   I_daily_waste_pct,
                                   I_taxable_ind,
                                   I_meas_of_each,
                                   I_meas_of_price,
                                   I_uom_of_price,
                                   I_selling_unit_retail,
                                   I_selling_uom,
                                   I_primary_cost_pack,
                                   I_process_children,
                                   I_receive_as_type,
                                   I_inbound_handling_days,
                                   I_store_price_ind,
                                   I_source_method,
                                   I_source_wh,
                                   L_multi_units,
                                   L_multi_unit_retail,
                                   L_multi_selling_uom) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END UPDATE_ITEM_LOC;
-----------------------------------------------------------------
FUNCTION CREATE_ITEM_LOC(O_error_message           IN OUT   VARCHAR2,
                         I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                         I_group_type              IN       CODE_DETAIL.CODE%TYPE,
                         I_group_value             IN       VARCHAR2,
                         I_currency_code           IN       STORE.CURRENCY_CODE%TYPE,
                         I_item_parent             IN       ITEM_MASTER.ITEM_PARENT%TYPE,
                         I_item_grandparent        IN       ITEM_MASTER.ITEM_GRANDPARENT%TYPE,
                         I_loc_type                IN       ITEM_LOC.LOC_TYPE%TYPE,
                         I_short_desc              IN       ITEM_MASTER.SHORT_DESC%TYPE,
                         I_dept                    IN       ITEM_MASTER.DEPT%TYPE,
                         I_class                   IN       ITEM_MASTER.CLASS%TYPE,
                         I_subclass                IN       ITEM_MASTER.SUBCLASS%TYPE,
                         I_item_level              IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                         I_tran_level              IN       ITEM_MASTER.TRAN_LEVEL%TYPE,
                         I_item_status             IN       ITEM_MASTER.STATUS%TYPE,
                         I_zone_group_id           IN       ITEM_MASTER.RETAIL_ZONE_GROUP_ID%TYPE,
                         I_waste_type              IN       ITEM_MASTER.WASTE_TYPE%TYPE,
                         I_daily_waste_pct         IN       ITEM_LOC.DAILY_WASTE_PCT%TYPE,
                         I_sellable_ind            IN       ITEM_MASTER.SELLABLE_IND%TYPE,
                         I_orderable_ind           IN       ITEM_MASTER.ORDERABLE_IND%TYPE,
                         I_pack_ind                IN       ITEM_MASTER.PACK_IND%TYPE,
                         I_pack_type               IN       ITEM_MASTER.PACK_TYPE%TYPE,
                         I_unit_cost_loc           IN       ITEM_LOC_SOH.UNIT_COST%TYPE,
                         I_unit_retail_loc         IN       ITEM_LOC.UNIT_RETAIL%TYPE,
                         I_selling_retail_loc      IN       ITEM_LOC.SELLING_UNIT_RETAIL%TYPE,
                         I_selling_uom             IN       ITEM_LOC.SELLING_UOM%TYPE,
                         I_item_loc_status         IN       ITEM_LOC.STATUS%TYPE,
                         I_taxable_ind             IN       ITEM_LOC.TAXABLE_IND%TYPE,
                         I_ti                      IN       ITEM_LOC.TI%TYPE,
                         I_hi                      IN       ITEM_LOC.HI%TYPE,
                         I_store_ord_mult          IN       ITEM_LOC.STORE_ORD_MULT%TYPE,
                         I_meas_of_each            IN       ITEM_LOC.MEAS_OF_EACH%TYPE,
                         I_meas_of_price           IN       ITEM_LOC.MEAS_OF_PRICE%TYPE,
                         I_uom_of_price            IN       ITEM_LOC.UOM_OF_PRICE%TYPE,
                         I_primary_variant         IN       ITEM_LOC.PRIMARY_VARIANT%TYPE,
                         I_primary_supp            IN       ITEM_LOC.PRIMARY_SUPP%TYPE,
                         I_primary_cntry           IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                         I_local_item_desc         IN       ITEM_LOC.LOCAL_ITEM_DESC%TYPE,
                         I_local_short_desc        IN       ITEM_LOC.LOCAL_SHORT_DESC%TYPE,
                         I_primary_cost_pack       IN       ITEM_LOC.PRIMARY_COST_PACK%TYPE,
                         I_date                    IN       DATE,
                         I_default_to_children     IN       BOOLEAN,
                         I_receive_as_type         IN       ITEM_LOC.RECEIVE_AS_TYPE%TYPE,
                         I_inbound_handling_days   IN       ITEM_LOC.INBOUND_HANDLING_DAYS%TYPE DEFAULT NULL,
                         I_store_price_ind         IN       ITEM_LOC.STORE_PRICE_IND%TYPE  DEFAULT NULL,
                         I_source_method           IN       ITEM_LOC.SOURCE_METHOD%TYPE    DEFAULT NULL,
                         I_source_wh               IN       ITEM_LOC.SOURCE_WH%TYPE        DEFAULT NULL)
return BOOLEAN IS

   L_program               VARCHAR2(64) := 'ITEM_LOC_SQL.CREATE_ITEM_LOC';
   L_multi_units           ITEM_LOC.MULTI_UNITS%TYPE;
   L_multi_unit_retail     ITEM_LOC.MULTI_UNIT_RETAIL%TYPE;
   L_multi_selling_uom     ITEM_LOC.MULTI_SELLING_UOM%TYPE;

BEGIN
    --- Overloaded for call from contlocs.fmb
   if ITEM_LOC_SQL.CREATE_ITEM_LOC(O_error_message,
                                   I_item,
                                   I_group_type,
                                   I_group_value,
                                   I_currency_code,
                                   I_item_parent,
                                   I_item_grandparent,
                                   I_loc_type,
                                   I_short_desc,
                                   I_dept,
                                   I_class,
                                   I_subclass,
                                   I_item_level,
                                   I_tran_level,
                                   I_item_status,
                                   I_zone_group_id,
                                   I_waste_type,
                                   I_daily_waste_pct,
                                   I_sellable_ind,
                                   I_orderable_ind,
                                   I_pack_ind,
                                   I_pack_type,
                                   I_unit_cost_loc,
                                   I_unit_retail_loc,
                                   I_selling_retail_loc,
                                   I_selling_uom,
                                   I_item_loc_status,
                                   I_taxable_ind,
                                   I_ti,
                                   I_hi,
                                   I_store_ord_mult,
                                   I_meas_of_each,
                                   I_meas_of_price,
                                   I_uom_of_price,
                                   I_primary_variant,
                                   I_primary_supp,
                                   I_primary_cntry,
                                   I_local_item_desc,
                                   I_local_short_desc,
                                   I_primary_cost_pack,
                                   I_date,
                                   I_default_to_children,
                                   I_receive_as_type,
                                   I_inbound_handling_days,
                                   I_store_price_ind,
                                   I_source_method,
                                   I_source_wh,
                                   L_multi_units,
                                   L_multi_unit_retail,
                                   L_multi_selling_uom) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',SQLERRM,
                                            L_program,TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_ITEM_LOC;
------------------------------------------------------------------------------------
-- NBS00018163 13-Jul-2010 Bhargavi pujari/bharagavi.pujari@in.tesco.com Begin
------------------------------------------------------------------------------------
FUNCTION TSL_UPDATE_ITEM_LOC(O_error_message           IN OUT   VARCHAR2,
                             I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                             I_old_supplier            IN       ITEM_LOC.PRIMARY_SUPP%TYPE,
                             I_new_supplier            IN       ITEM_LOC.PRIMARY_SUPP%TYPE,
                             I_primary_country         IN       ITEM_LOC.PRIMARY_CNTRY%TYPE,
                             I_ti                      IN       ITEM_LOC.TI%TYPE,
                             I_hi                      IN       ITEM_LOC.HI%TYPE,
                             I_cascade                 IN       VARCHAR2,
                             I_var_exists              IN       VARCHAR2,
                             I_item_level              IN       ITEM_MASTER.ITEM_LEVEL%TYPE,
                             I_tran_level              IN       ITEM_MASTER.TRAN_LEVEL%TYPE)
return BOOLEAN is

   L_program               VARCHAR2(64) := 'ITEM_LOC_SQL.TSL_UPDATE_ITEM_LOC';
   L_item                  ITEM_MASTER.ITEM%TYPE;
   L_error_message         RTK_ERRORS.Rtk_Text%TYPE;
   L_exists                BOOLEAN;
   L_origin_country_id     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_unit_cost             item_supp_country.unit_cost%TYPE;

   cursor C_GET_ITEM is
   select item
     from item_master
    where item = I_item
      and item_level <= tran_level;

    cursor C_GET_ITEM_VAR is
   select im.item
     from item_master im
    where ((im.tsl_base_item = I_item) and (im.tsl_base_item != im.item))
      and im.item_level <= im.tran_level;

   cursor C_GET_ITEM_CHILDREN is
   select item
     from item_master
    where item_parent = I_item
      and item_level <= tran_level;

   cursor C_LOCK_ITEM_LOC is
      select 'x'
        from item_loc il
       where il.item         = L_item
        and  il.primary_supp = I_old_supplier
         for update nowait;

   cursor C_LOCK_ITEM_LOC_SOH is
      select 'x'
        from item_loc_soh ils
       where ils.item         = L_item
        and  ils.primary_supp = I_old_supplier
         for update nowait;

BEGIN
   ---
   if I_item_level <= I_tran_level then
      if NOT ITEM_SUPP_COUNTRY_SQL.GET_UNIT_COST(O_error_message,
                                                 L_unit_cost,
                                                 I_item ,
                                                 I_new_supplier,
                                                 I_primary_country) then
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM',
                       'ITEM_LOC',
                       I_item);
      open C_GET_ITEM;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM',
                       'ITEM_LOC',
                       I_item);
      fetch C_GET_ITEM into L_item;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM',
                       'ITEM_LOC',
                       I_item);
      close C_GET_ITEM;
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ITEM_LOC',
                       'ITEM_LOC',
                       I_item);
      open C_LOCK_ITEM_LOC;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ITEM_LOC',
                       'ITEM_LOC',
                       I_item);
      close C_LOCK_ITEM_LOC;
      update item_loc
         set primary_supp         = I_new_supplier,
             primary_cntry        = I_primary_country,
             ti                   = I_ti,
             hi                   = I_hi
       where item                 = L_item
         and primary_supp         = I_old_supplier;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ITEM_LOC_SOH',
                       'ITEM_LOC',
                       I_item);
      open C_LOCK_ITEM_LOC_SOH;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ITEM_LOC_SOH',
                       'ITEM_LOC',
                       I_item);
      close C_LOCK_ITEM_LOC_SOH;
      if I_item_level = I_tran_level then
        update item_loc_soh ils
           set ils.unit_cost        = L_unit_cost,
               ils.primary_supp     = I_new_supplier,
               ils.primary_cntry    = I_primary_country
         where ils.item             = L_item
           and ils.primary_supp     = I_new_supplier;
      end if;

      if I_item_level = 1 and I_tran_level = 2 then
         if I_cascade = 'Y' then
            FOR c_rec IN C_GET_ITEM_CHILDREN LOOP
               L_item := c_rec.item;
               if NOT ITEM_SUPP_COUNTRY_SQL.GET_PRIMARY_COUNTRY(O_error_message ,
                                                                L_exists,
                                                                L_origin_country_id ,
                                                                L_item,
                                                                I_new_supplier) then
                  return FALSE;
               end if;
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_ITEM_LOC',
                                'ITEM_LOC',
                                I_item);
               open C_LOCK_ITEM_LOC;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_ITEM_LOC',
                                'ITEM_LOC',
                                I_item);
               close C_LOCK_ITEM_LOC;
               if L_exists = TRUE then
                 update item_loc
                    set primary_supp         = I_new_supplier,
                        primary_cntry        = I_primary_country,
                        ti                   = I_ti,
                        hi                   = I_hi
                  where item                 = L_item
                    and primary_supp         = I_old_supplier;
               end if;
                ---
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_ITEM_LOC_SOH',
                                'ITEM_LOC',
                                I_item);
               open C_LOCK_ITEM_LOC_SOH;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_ITEM_LOC_SOH',
                                'ITEM_LOC',
                                I_item);
               close C_LOCK_ITEM_LOC_SOH;
               if L_exists = TRUE then
                 update item_loc_soh ils
                    set ils.primary_supp     = I_new_supplier,
                        ils.primary_cntry    = I_primary_country,
                        ils.unit_cost        = L_unit_cost
                  where ils.item             = L_item
                    and ils.primary_supp     = I_new_supplier;
               end if;
            END LOOP;
         end if;
      end if;
      if I_item_level = 2 and I_tran_level = 2 then
         if I_var_exists = 'Y' then
            FOR C_rec in C_GET_ITEM_VAR LOOP
               L_item := c_rec.item;
               if NOT ITEM_SUPP_COUNTRY_SQL.GET_PRIMARY_COUNTRY(O_error_message ,
                                                                L_exists,
                                                                L_origin_country_id ,
                                                                L_item,
                                                                I_new_supplier) then
                  return FALSE;
               end if;
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_ITEM_LOC',
                                'ITEM_LOC',
                                I_item);
               open C_LOCK_ITEM_LOC;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_ITEM_LOC',
                                'ITEM_LOC',
                                I_item);
               close C_LOCK_ITEM_LOC;
               if L_exists = TRUE then
                 update item_loc
                    set primary_supp         = I_new_supplier,
                        primary_cntry        = I_primary_country,
                        ti                   = I_ti,
                        hi                   = I_hi
                  where item                 = L_item
                    and primary_supp         = I_old_supplier;
               end if;
                ---
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_ITEM_LOC_SOH',
                                'ITEM_LOC',
                                I_item);
               open C_LOCK_ITEM_LOC_SOH;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_ITEM_LOC_SOH',
                                'ITEM_LOC',
                                I_item);
               close C_LOCK_ITEM_LOC_SOH;
               if L_exists = TRUE then
                 update item_loc_soh ils
                    set ils.primary_supp     = I_new_supplier,
                        ils.primary_cntry    = I_primary_country,
                        ils.unit_cost        = L_unit_cost
                  where ils.item             = L_item
                    and ils.primary_supp     = I_new_supplier;
               end if;
            END LOOP;
         end if;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_UPDATE_ITEM_LOC;
------------------------------------------------------------------------------------
FUNCTION TSL_SUPP_LOC_EXIST(O_error_message           IN OUT   VARCHAR2,
                            O_exists                  IN OUT   BOOLEAN,
                            I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                            I_supplier                IN       ITEM_LOC.PRIMARY_SUPP%TYPE)
return BOOLEAN  IS

   L_item_loc_exists   VARCHAR2(1)  := NULL;
   L_program           VARCHAR2(64) := 'ITEM_LOC_SQL.ITEM_LOCATION_EXISTS';

   cursor C_ITEM_LOCATION_EXISTS is
      select 'x'
        from item_loc il
       where il.item = I_item
         and il.primary_supp = I_supplier;

BEGIN
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_LOCATION_EXISTS',
                    'ITEM_LOC',
                    I_item);
   open C_ITEM_LOCATION_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_LOCATION_EXISTS',
                    'ITEM_LOC',
                    I_item);
   fetch C_ITEM_LOCATION_EXISTS into L_item_loc_exists;
   if C_ITEM_LOCATION_EXISTS%FOUND then
     O_exists := TRUE;
   else
     O_exists := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_LOCATION_EXISTS',
                    'ITEM_LOC',
                    I_item);
   close C_ITEM_LOCATION_EXISTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END TSL_SUPP_LOC_EXIST;
------------------------------------------------------------------------------------
-- NBS00018163 13-Jul-2010 Bhargavi pujari/bharagavi.pujari@in.tesco.com End
------------------------------------------------------------------------------------
END ITEM_LOC_SQL;
/

