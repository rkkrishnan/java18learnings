CREATE OR REPLACE PACKAGE BODY ITEM_LOC_TRAITS_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      WiproEnabler/Karthik Dhanapal
--Mod Date:    12-Jul-2007
--Mod Ref:     Mod number. 365b
--Mod Details: Amended script to explodes the base varient item information.
------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
FUNCTION GET_VALUES(O_error_message                 IN OUT  VARCHAR2,
                    O_exists                        IN OUT  BOOLEAN,
                    O_launch_date                   IN OUT  ITEM_LOC_TRAITS.LAUNCH_DATE%TYPE,
                    O_qty_key_options               IN OUT  ITEM_LOC_TRAITS.QTY_KEY_OPTIONS%TYPE,
                    O_manual_price_entry            IN OUT  ITEM_LOC_TRAITS.MANUAL_PRICE_ENTRY%TYPE,
                    O_deposit_code                  IN OUT  ITEM_LOC_TRAITS.DEPOSIT_CODE%TYPE,
                    O_food_stamp_ind                IN OUT  ITEM_LOC_TRAITS.FOOD_STAMP_IND%TYPE,
                    O_wic_ind                       IN OUT  ITEM_LOC_TRAITS.WIC_IND%TYPE,
                    O_proportional_tare_pct         IN OUT  ITEM_LOC_TRAITS.PROPORTIONAL_TARE_PCT%TYPE,
                    O_fixed_tare_value              IN OUT  ITEM_LOC_TRAITS.FIXED_TARE_VALUE%TYPE,
                    O_fixed_tare_uom                IN OUT  ITEM_LOC_TRAITS.FIXED_TARE_UOM%TYPE,
                    O_reward_eligible_ind           IN OUT  ITEM_LOC_TRAITS.REWARD_ELIGIBLE_IND%TYPE,
                    O_natl_brand_comp_item          IN OUT  ITEM_LOC_TRAITS.NATL_BRAND_COMP_ITEM%TYPE,
                    O_return_policy                 IN OUT  ITEM_LOC_TRAITS.RETURN_POLICY%TYPE,
                    O_stop_sale_ind                 IN OUT  ITEM_LOC_TRAITS.STOP_SALE_IND%TYPE,
                    O_elect_mtk_clubs               IN OUT  ITEM_LOC_TRAITS.ELECT_MTK_CLUBS%TYPE,
                    O_report_code                   IN OUT  ITEM_LOC_TRAITS.REPORT_CODE%TYPE,
                    O_req_shelf_life_on_selection   IN OUT  ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_SELECTION%TYPE,
                    O_req_shelf_life_on_receipt     IN OUT  ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_RECEIPT%TYPE,
                    O_ib_shelf_life                 IN OUT  ITEM_LOC_TRAITS.IB_SHELF_LIFE%TYPE,
                    O_store_reorderable_ind         IN OUT  ITEM_LOC_TRAITS.STORE_REORDERABLE_IND%TYPE,
                    O_rack_size                     IN OUT  ITEM_LOC_TRAITS.RACK_SIZE%TYPE,
                    O_full_pallet_item              IN OUT  ITEM_LOC_TRAITS.FULL_PALLET_ITEM%TYPE,
                    O_in_store_market_basket        IN OUT  ITEM_LOC_TRAITS.IN_STORE_MARKET_BASKET%TYPE,
                    O_storage_location              IN OUT  ITEM_LOC_TRAITS.STORAGE_LOCATION%TYPE,
                    O_alt_storage_location          IN OUT  ITEM_LOC_TRAITS.ALT_STORAGE_LOCATION%TYPE,
                    O_returnable_ind                IN OUT  ITEM_LOC_TRAITS.RETURNABLE_IND%TYPE,
                    O_refundable_ind                IN OUT  ITEM_LOC_TRAITS.REFUNDABLE_IND%TYPE,
                    O_back_order_ind                IN OUT  ITEM_LOC_TRAITS.BACK_ORDER_IND%TYPE,
                    I_item                          IN      ITEM_LOC_TRAITS.ITEM%TYPE,
                    I_location                      IN      VARCHAR2)
RETURN BOOLEAN IS
   L_program     VARCHAR2(64) := 'ITEM_LOC_TRAITS_SQL.GET_VALUES';

   cursor C_VALUES is
      select launch_date,
             qty_key_options,
             manual_price_entry,
             deposit_code,
             food_stamp_ind,
             wic_ind,
             proportional_tare_pct,
             fixed_tare_value,
             fixed_tare_uom,
             reward_eligible_ind,
             natl_brand_comp_item,
             return_policy,
             stop_sale_ind,
             elect_mtk_clubs,
             report_code,
             req_shelf_life_on_selection,
             req_shelf_life_on_receipt,
             ib_shelf_life,
             store_reorderable_ind,
             rack_size,
             full_pallet_item,
             in_store_market_basket,
             storage_location,
             alt_storage_location,
             returnable_ind,
             refundable_ind,
             back_order_ind
        from item_loc_traits
       where item = I_item
         and loc = to_number(I_location);

BEGIN
   O_exists := FALSE;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_location',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_VALUES','ITEM_LOC_TRAITS','ITEM: '||I_item || ', LOCATION: ' ||I_location);
   open C_VALUES;
   SQL_LIB.SET_MARK('FETCH', 'C_VALUES','ITEM_LOC_TRAITS','ITEM: '||I_item || ', LOCATION: ' ||I_location);
   fetch C_VALUES into O_launch_date,
                       O_qty_key_options,
                       O_manual_price_entry,
                       O_deposit_code,
                       O_food_stamp_ind,
                       O_wic_ind,
                       O_proportional_tare_pct,
                       O_fixed_tare_value,
                       O_fixed_tare_uom,
                       O_reward_eligible_ind,
                       O_natl_brand_comp_item,
                       O_return_policy,
                       O_stop_sale_ind,
                       O_elect_mtk_clubs,
                       O_report_code,
                       O_req_shelf_life_on_selection,
                       O_req_shelf_life_on_receipt,
                       O_ib_shelf_life,
                       O_store_reorderable_ind,
                       O_rack_size,
                       O_full_pallet_item,
                       O_in_store_market_basket,
                       O_storage_location,
                       O_alt_storage_location,
                       O_returnable_ind,
                       O_refundable_ind,
                       O_back_order_ind;

   if C_VALUES%FOUND then
      O_exists := TRUE;
   end if;

   SQL_LIB.SET_MARK('CLOSE', 'C_VALUES','ITEM_LOC_TRAITS','ITEM: '||I_item || ', LOCATION: ' ||I_location);
   close C_VALUES;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            SQLCODE);
      return FALSE;
END GET_VALUES;
-------------------------------------------------------------------------------
-- Only call this function with online forms to control what data the user can
-- see or use and do not call the function from batch.  This function retrieves
-- data from:
--    V_EXTERNAL_FINISHER V_INTERNAL_FINISHER V_STORE V_WH
-- which only returns data that the user has permission to access.
--------------------------------------------------------------------------------
FUNCTION APPLY (O_error_message   IN OUT   VARCHAR2,
                O_insert_ind      IN OUT   VARCHAR2,
                I_loc             IN       VARCHAR2,
                I_loc_type        IN       CODE_DETAIL.CODE_TYPE%TYPE,
                I_item            IN       ITEM_LOC.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program     VARCHAR2(64) := 'ITEM_LOC_TRAITS_SQL.APPLY';

BEGIN
   O_insert_ind := 'Y';

   if I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_loc_type',
                                            L_program,
                                            NULL);
      return FALSE;


   elsif I_loc_type NOT in ('A','AL','AS','AW','S','W', 'PW','C','D','R','T','Z','L','DW','LLS','LLW', 'AE', 'E', 'AI', 'I') then

      O_error_message := SQL_LIB.CREATE_MSG('INV_LOC_TYPE',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   elsif I_loc is NULL and I_loc_type NOT in ('AL','AS','AW', 'AE', 'AI') then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_loc',
                                            L_program,
                                            NULL);
      return FALSE;
   elsif I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_loc_type = 'S' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          item_loc i
                                    where s.store = to_number(I_loc)
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'W' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select w.wh,
                                          w.wh_name,
                                          'W'
                                     from v_wh w,
                                          item_loc i
                                    where w.wh = to_number(I_loc)
                                      and w.wh = i.loc
                                      and i.item = I_item
                                      and wh not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'PW' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select w.wh,
                                          w.wh_name,
                                          'W'
                                     from v_wh w,
                                          item_loc i
                                    where w.physical_wh = to_number(I_loc)
                                      and w.physical_wh <> w.wh
                                      and w.wh = i.loc
                                      and i.item = I_item
                                      and wh not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'AL' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          item_loc i
                                    where s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp)
                                    union all
                                   select w.wh,
                                          w.wh_name,
                                          'W'
                                     from v_wh w,
                                          item_loc i
                                    where w.wh = i.loc
                                      and i.item = I_item
                                      and wh not in
                                          (select location
                                             from mc_location_temp)
                                    union all
                                   select vef.finisher_id,
                                          vef.finisher_desc,
                                          'E'
                                     from v_external_finisher vef,
                                          item_loc i
                                    where i.loc = vef.finisher_id
                                      and i.item = I_item
                                      and vef.finisher_id not in
                                          (select location
                                             from mc_location_temp)
                                    union
                                   select vif.finisher_id,
                                          vif.finisher_desc,
                                          'I'
                                     from v_internal_finisher vif,
                                          item_loc i
                                    where i.loc = vif.finisher_id
                                      and i.item = I_item
                                      and vif.finisher_id not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'AS' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          item_loc i
                                    where s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);
      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'AW' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select w.wh,
                                          w.wh_name,
                                          'W'
                                     from v_wh w,
                                          item_loc i
                                    where w.wh = i.loc
                                      and i.item = I_item
                                      and wh not in
                                          (select location
                                             from mc_location_temp);
      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'C' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          item_loc i
                                    where store_class = I_loc
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'D' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          item_loc i
                                    where s.district = to_number(I_loc)
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'R' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          district d,
                                          item_loc i
                                    where s.district = d.district
                                      and d.region = to_number(I_loc)
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'A' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          district d,
                                          region r,
                                          item_loc i
                                    where s.district = d.district
                                      and d.region = r.region
                                      and r.area = to_number(I_loc)
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;


   elsif I_loc_type = 'T' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          item_loc i
                                    where s.transfer_zone = to_number(I_loc)
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'Z' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          price_zone_group_store p,
                                          item_loc il,
                                          item_master im
                                    where s.store = p.store
                                      and p.zone_id = to_number(I_loc)
                                      and s.store = il.loc
                                      and il.item = im.item
                                      and im.item = I_item
                                      and p.zone_group_id = im.retail_zone_group_id
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'L' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          loc_traits_matrix l,
                                          item_loc i
                                    where s.store = l.store
                                      and l.loc_trait = to_number(I_loc)
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'DW' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          item_loc i
                                    where s.default_wh = to_number(I_loc)
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'LLS' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from v_store s,
                                          loc_list_detail l,
                                          item_loc i
                                    where s.store = l.location
                                      and l.loc_list = to_number(I_loc)
                                      and l.loc_type = 'S'
                                      and s.store = i.loc
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'LLW' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select w.wh,
                                          w.wh_name,
                                          'W'
                                     from v_wh w,
                                          loc_list_detail l,
                                          item_loc i
                                    where w.wh = l.location
                                      and l.loc_list = to_number(I_loc)
                                      and l.loc_type = 'W'
                                      and w.wh = i.loc
                                      and i.item = I_item
                                      and w.wh not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'AE' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select vef.finisher_id,
                                          vef.finisher_desc,
                                          'E'
                                     from v_external_finisher vef,
                                          item_loc i
                                    where i.loc = vef.finisher_id
                                      and i.item = I_item
                                      and vef.finisher_id not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'E' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select vef.finisher_id,
                                          vef.finisher_desc,
                                          'E'
                                     from v_external_finisher vef,
                                          item_loc i
                                    where vef.finisher_id = to_number(I_loc)
                                      and i.loc = vef.finisher_id
                                      and i.item = I_item
                                      and vef.finisher_id not in
                                          (select location
                                             from mc_location_temp);


      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'AI' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select vif.finisher_id,
                                          vif.finisher_desc,
                                          'I'
                                     from v_internal_finisher vif,
                                          item_loc i
                                    where i.loc = vif.finisher_id
                                      and i.item = I_item
                                      and vif.finisher_id not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;

   elsif I_loc_type = 'I' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select vif.finisher_id,
                                          vif.finisher_desc,
                                          'I'
                                     from v_internal_finisher vif,
                                          item_loc i
                                    where vif.finisher_id = to_number(I_loc)
                                      and i.loc = vif.finisher_id
                                      and i.item = I_item
                                      and vif.finisher_id not in
                                          (select location
                                             from mc_location_temp);


      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;
   elsif I_loc_type = 'A' then
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type||',Item: '||I_item);
      insert into mc_location_temp(location,
                                   location_name,
                                   loc_type)
                                   select s.store,
                                          s.store_name,
                                          'S'
                                     from item_loc i,
                                          store s,
                                          district d,
                                          region r
                                    where r.area = to_number(I_loc)
                                      and d.region   = r.region
                                      and s.district = d.district
                                      and i.loc  = s.store
                                      and i.item = I_item
                                      and s.store not in
                                          (select location
                                             from mc_location_temp);

      if SQL%NOTFOUND then
         O_insert_ind := 'N';
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            SQLCODE);
      return FALSE;

END APPLY;
-------------------------------------------------------------------------------
FUNCTION DELETE (O_error_message    IN OUT  VARCHAR2,
                 I_loc              IN      VARCHAR2,
                 I_loc_type         IN      CODE_DETAIL.CODE_TYPE%TYPE)
RETURN BOOLEAN IS
   L_table       VARCHAR2(64) := 'MC_LOCATION_TEMP';
   L_program     VARCHAR2(64) := 'ITEM_LOC_TRAITS_SQL.DELETE';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_STORE is
      select 'x'
        from mc_location_temp
       where location = to_number(I_loc)
         and loc_type = 'S'
         for update nowait;

   cursor C_LOCK_WH is
      select 'x'
        from mc_location_temp
       where location = to_number(I_loc)
         and loc_type = 'W'
         for update nowait;

   cursor C_LOCK_PHY_WH is
      select 'x'
        from mc_location_temp
       where location in
             (select wh
                from wh
               where physical_wh = to_number(I_loc))
                 for update nowait;

   cursor C_LOCK_ALL_LOCS is
      select 'x'
        from mc_location_temp
         for update nowait;

   cursor C_LOCK_ALL_STORES is
      select 'x'
        from mc_location_temp
       where loc_type = 'S'
         for update nowait;

   cursor C_LOCK_ALL_WH is
      select 'x'
        from mc_location_temp
       where loc_type = 'W'
         for update nowait;

   cursor C_LOCK_CLASS is
      select 'x'
        from mc_location_temp
       where location in
             (select store
                from store
               where store_class = I_loc)
                 for update nowait;

   cursor C_LOCK_DISTRICT is
      select 'x'
        from mc_location_temp
       where location in
             (select store
                from store
               where district = to_number(I_loc))
                 for update nowait;

   cursor C_LOCK_REGION is
      select 'x'
        from mc_location_temp
       where location in
             (select store
                from store
               where district in
                     (select district
                        from district
                       where region = to_number(I_loc)))
                 for update nowait;

   cursor C_LOCK_TRANSFER_ZONE is
      select 'x'
        from mc_location_temp
       where location in
             (select store
                from store
               where transfer_zone = to_number(I_loc))
                 for update nowait;

   cursor C_LOCK_PRICE_ZONE is
      select 'x'
        from mc_location_temp
       where location in
             (select store
                from price_zone_group_store
               where zone_group_id = to_number(I_loc))
                 for update nowait;

   cursor C_LOCK_LOC_TRAIT is
      select 'x'
        from mc_location_temp
       where location in
             (select store
                from loc_traits_matrix
               where loc_trait = to_number(I_loc))
                 for update nowait;

   cursor C_LOCK_DEFAULT_WH is
      select 'x'
        from mc_location_temp
       where location in
             (select store
                from store
               where default_wh = to_number(I_loc))
                 for update nowait;

   cursor C_LOCK_LOC_LIST_STORE is
      select 'x'
        from mc_location_temp
       where location in
             (select location
                from loc_list_detail
               where loc_list = to_number(I_loc)
                 and loc_type = 'S')
                 for update nowait;

   cursor C_LOCK_LOC_LIST_WH is
      select 'x'
        from mc_location_temp
       where location in
             (select location
                from loc_list_detail
               where loc_list = to_number(I_loc)
                 and loc_type = 'W')
         for update nowait;

   cursor C_LOCK_EXTERNAL is
      select 'x'
        from mc_location_temp
       where location = to_number(I_loc)
         and loc_type = 'E'
         for update nowait;

   cursor C_LOCK_ALL_EXTERNAL is
      select 'x'
        from mc_location_temp
       where loc_type = 'E'
         for update nowait;

   cursor C_LOCK_INTERNAL is
      select 'x'
        from mc_location_temp
       where location = to_number(I_loc)
         and loc_type = 'I'
         for update nowait;

   cursor C_LOCK_ALL_INTERNAL is
      select 'x'
        from mc_location_temp
       where loc_type = 'I'
         for update nowait;

BEGIN
   if I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_loc_type',
                                             L_program,
                                             NULL);
      return FALSE;
   elsif I_loc_type NOT in ('AL','AS','AW','S','W','PW','C','D','R','P','T','Z','L','DW','LLS','LLW', 'AE', 'E', 'AI', 'I') then
      O_error_message := SQL_LIB.CREATE_MSG('INV_LOC_TYPE',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   elsif I_loc is NULL and I_loc_type NOT in ('AL','AS','AW', 'AE', 'AI') then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_loc',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   if I_loc_type = 'S' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_STORE',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_STORE;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_STORE',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_STORE;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location = to_number(I_loc)
         and loc_type = 'S';
   elsif I_loc_type = 'W' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_WH;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_WH;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location = to_number(I_loc)
         and loc_type = 'W';
   elsif I_loc_type = 'PW' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_PHY_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_PHY_WH;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_PHY_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_PHY_WH;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where loc_type = 'W'
         and location in (select wh from wh where physical_wh = to_number(I_loc));
   elsif I_loc_type = 'AL' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ALL_LOCS',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_ALL_LOCS;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ALL_LOCS',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_ALL_LOCS;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp;
   elsif I_loc_type = 'AS' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ALL_STORES',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_ALL_STORES;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ALL_STORES',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_ALL_STORES;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where loc_type = 'S';
   elsif I_loc_type = 'AW' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ALL_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_ALL_WH;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ALL_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_ALL_WH;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where loc_type = 'W';
   elsif I_loc_type = 'C' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_CLASS',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_CLASS;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_CLASS',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_CLASS;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select store
                from store
               where store_class = I_loc);
   elsif I_loc_type = 'D' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DISTRICT',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_DISTRICT;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DISTRICT',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_DISTRICT;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select store
                from store
               where district = to_number(I_loc));
   elsif I_loc_type = 'R' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_REGION',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_REGION;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_REGION',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_REGION;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select store
                from store
               where district in
                     (select district
                        from district
                       where region = to_number(I_loc)));
   elsif I_loc_type = 'T' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_TRANSFER_ZONE',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_TRANSFER_ZONE;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_TRANSFER_ZONE',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_TRANSFER_ZONE;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select store
                from store
               where transfer_zone = to_number(I_loc));
   elsif I_loc_type = 'Z' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_PRICE_ZONE',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_PRICE_ZONE;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_PRICE_ZONE',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_PRICE_ZONE;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select store
                from price_zone_group_store
               where zone_group_id = to_number(I_loc));
   elsif I_loc_type = 'L' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_LOC_TRAIT',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_LOC_TRAIT;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_LOC_TRAIT',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_LOC_TRAIT;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select store
                from loc_traits_matrix
               where loc_trait = to_number(I_loc));
   elsif I_loc_type = 'DW' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DEFAULT_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_DEFAULT_WH;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DEFAULT_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_DEFAULT_WH;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select store
                from store
               where default_wh = to_number(I_loc));
   elsif I_loc_type = 'LLS' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_LOC_LIST_STORE',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_LOC_LIST_STORE;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_LOC_LIST_STORE',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_LOC_LIST_STORE;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select location
                from loc_list_detail
               where loc_list = to_number(I_loc)
                 and loc_type = 'S');
   elsif I_loc_type = 'LLW' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_LOC_LIST_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_LOC_LIST_WH;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_LOC_LIST_WH',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_LOC_LIST_WH;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location in
             (select location
                from loc_list_detail
               where loc_list = to_number(I_loc)
                 and loc_type = 'W');
   elsif I_loc_type = 'AE' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ALL_EXTERNAL',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_ALL_EXTERNAL;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ALL_EXTERNAL',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_ALL_EXTERNAL;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where loc_type = 'E';
   elsif I_loc_type = 'E' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_EXTERNAL',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_EXTERNAL;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_EXTERNAL',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_EXTERNAL;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location = to_number(I_loc)
         and loc_type = 'E';
   elsif I_loc_type = 'AI' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ALL_INTERNAL',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_ALL_INTERNAL;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ALL_INTERNAL',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_ALL_INTERNAL;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where loc_type = 'I';
   elsif I_loc_type = 'I' then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INTERNAL',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      open C_LOCK_INTERNAL;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INTERNAL',
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      close C_LOCK_INTERNAL;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'MC_LOCATION_TEMP',
                       'Location: '||I_loc||', Location type: '||I_loc_type);
      delete from mc_location_temp
       where location = to_number(I_loc)
         and loc_type = 'I';
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_loc,
                                               I_loc_type);
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            SQLCODE);
      return FALSE;

END DELETE;
-------------------------------------------------------------------------------
FUNCTION INSERT_UPDATE_SINGLE_LOC(O_error_message               IN OUT  VARCHAR2,
                                  I_launch_date                 IN      ITEM_LOC_TRAITS.LAUNCH_DATE%TYPE,
                                  I_qty_key_options             IN      ITEM_LOC_TRAITS.QTY_KEY_OPTIONS%TYPE,
                                  I_manual_price_entry          IN      ITEM_LOC_TRAITS.MANUAL_PRICE_ENTRY%TYPE,
                                  I_deposit_code                IN      ITEM_LOC_TRAITS.DEPOSIT_CODE%TYPE,
                                  I_food_stamp_ind              IN      ITEM_LOC_TRAITS.FOOD_STAMP_IND%TYPE,
                                  I_wic_ind                     IN      ITEM_LOC_TRAITS.WIC_IND%TYPE,
                                  I_proportional_tare_pct       IN      ITEM_LOC_TRAITS.PROPORTIONAL_TARE_PCT%TYPE,
                                  I_fixed_tare_value            IN      ITEM_LOC_TRAITS.FIXED_TARE_VALUE%TYPE,
                                  I_fixed_tare_uom              IN      ITEM_LOC_TRAITS.FIXED_TARE_UOM%TYPE,
                                  I_reward_eligible_ind         IN      ITEM_LOC_TRAITS.REWARD_ELIGIBLE_IND%TYPE,
                                  I_natl_brand_comp_item        IN      ITEM_LOC_TRAITS.NATL_BRAND_COMP_ITEM%TYPE,
                                  I_return_policy               IN      ITEM_LOC_TRAITS.RETURN_POLICY%TYPE,
                                  I_stop_sale_ind               IN      ITEM_LOC_TRAITS.STOP_SALE_IND%TYPE,
                                  I_elect_mtk_clubs             IN      ITEM_LOC_TRAITS.ELECT_MTK_CLUBS%TYPE,
                                  I_report_code                 IN      ITEM_LOC_TRAITS.REPORT_CODE%TYPE,
                                  I_req_shelf_life_on_selection IN      ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_SELECTION%TYPE,
                                  I_req_shelf_life_on_receipt   IN      ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_RECEIPT%TYPE,
                                  I_ib_shelf_life               IN      ITEM_LOC_TRAITS.IB_SHELF_LIFE%TYPE,
                                  I_store_reorderable_ind       IN      ITEM_LOC_TRAITS.STORE_REORDERABLE_IND%TYPE,
                                  I_rack_size                   IN      ITEM_LOC_TRAITS.RACK_SIZE%TYPE,
                                  I_full_pallet_item            IN      ITEM_LOC_TRAITS.FULL_PALLET_ITEM%TYPE,
                                  I_in_store_market_basket      IN      ITEM_LOC_TRAITS.IN_STORE_MARKET_BASKET%TYPE,
                                  I_storage_location            IN      ITEM_LOC_TRAITS.STORAGE_LOCATION%TYPE,
                                  I_alt_storage_location        IN      ITEM_LOC_TRAITS.ALT_STORAGE_LOCATION%TYPE,
                                  I_returnable_ind              IN      ITEM_LOC_TRAITS.RETURNABLE_IND%TYPE,
                                  I_refundable_ind              IN      ITEM_LOC_TRAITS.REFUNDABLE_IND%TYPE,
                                  I_back_order_ind              IN      ITEM_LOC_TRAITS.BACK_ORDER_IND%TYPE,
                                  I_exists                      IN      BOOLEAN,
                                  I_item                        IN      ITEM_LOC_TRAITS.ITEM%TYPE,
                                  I_location                    IN      VARCHAR2)
RETURN BOOLEAN IS
   L_table       VARCHAR2(64) := 'ITEM_LOC_TRAITS';
   L_program     VARCHAR2(64) := 'ITEM_LOC_TRAITS_SQL.INSERT_UPDATE_SINGLE_LOC';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_UPDATE_SINGLE_LOC is
      select 'x'
        from item_loc_traits
       where item = I_item
         and loc = to_number(I_location)
         for update nowait;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   elsif I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_location',
                                             L_program,
                                             NULL);
      return FALSE;
   elsif I_exists is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_exists',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_exists = TRUE then
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_UPDATE_SINGLE_LOC',
                       'ITEM_LOC_TRAITS',
                       'Item: '||I_item||'Location: '||I_location);
      open C_LOCK_UPDATE_SINGLE_LOC;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_UPDATE_SINGLE_LOC',
                       'ITEM_LOC_TRAITS',
                       'Item: '||I_item||'Location: '||I_location);
      close C_LOCK_UPDATE_SINGLE_LOC;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ITEM_LOC_TRAITS',
                       'Item: '||I_item||'Location: '||I_location);
      update item_loc_traits
         set launch_date = I_launch_date,
             qty_key_options = I_qty_key_options,
             manual_price_entry = I_manual_price_entry,
             deposit_code = I_deposit_code,
             food_stamp_ind = I_food_stamp_ind,
             wic_ind = I_wic_ind,
             proportional_tare_pct = I_proportional_tare_pct,
             fixed_tare_value = I_fixed_tare_value,
             fixed_tare_uom = I_fixed_tare_uom,
             reward_eligible_ind = I_reward_eligible_ind,
             natl_brand_comp_item = I_natl_brand_comp_item,
             return_policy = I_return_policy,
             stop_sale_ind = I_stop_sale_ind,
             elect_mtk_clubs = I_elect_mtk_clubs,
             report_code = I_report_code,
             req_shelf_life_on_selection = I_req_shelf_life_on_selection,
             req_shelf_life_on_receipt = I_req_shelf_life_on_receipt,
             ib_shelf_life = I_ib_shelf_life,
             store_reorderable_ind = I_store_reorderable_ind,
             rack_size = I_rack_size,
             full_pallet_item = I_full_pallet_item,
             in_store_market_basket = I_in_store_market_basket,
             storage_location = I_storage_location,
             alt_storage_location = I_alt_storage_location,
             returnable_ind = I_returnable_ind,
             refundable_ind = I_refundable_ind,
             back_order_ind = I_back_order_ind,
             last_update_datetime = sysdate,
             last_update_id = user
       where item = I_item
         and loc = to_number(I_location);
   else
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ITEM_LOC_TRAITS',
                       'Item: '||I_item||'Location: '||I_location);
      insert into item_loc_traits(item,
                                  loc,
                                  launch_date,
                                  qty_key_options,
                                  manual_price_entry,
                                  deposit_code,
                                  food_stamp_ind,
                                  wic_ind,
                                  proportional_tare_pct,
                                  fixed_tare_value,
                                  fixed_tare_uom,
                                  reward_eligible_ind,
                                  natl_brand_comp_item,
                                  return_policy,
                                  stop_sale_ind,
                                  elect_mtk_clubs,
                                  report_code,
                                  req_shelf_life_on_selection,
                                  req_shelf_life_on_receipt,
                                  ib_shelf_life,
                                  store_reorderable_ind,
                                  rack_size,
                                  full_pallet_item,
                                  in_store_market_basket,
                                  storage_location,
                                  alt_storage_location,
                                  returnable_ind,
                                  refundable_ind,
                                  back_order_ind,
                                  create_datetime,
                                  last_update_datetime,
                                  last_update_id)
         values(I_item,
                to_number(I_location),
                I_launch_date,
                I_qty_key_options,
                I_manual_price_entry,
                I_deposit_code,
                I_food_stamp_ind,
                I_wic_ind,
                I_proportional_tare_pct,
                I_fixed_tare_value,
                I_fixed_tare_uom,
                I_reward_eligible_ind,
                I_natl_brand_comp_item,
                I_return_policy,
                I_stop_sale_ind,
                I_elect_mtk_clubs,
                I_report_code,
                I_req_shelf_life_on_selection,
                I_req_shelf_life_on_receipt,
                I_ib_shelf_life,
                I_store_reorderable_ind,
                I_rack_size,
                I_full_pallet_item,
                I_in_store_market_basket,
                I_storage_location,
                I_alt_storage_location,
                I_returnable_ind,
                I_refundable_ind,
                I_back_order_ind,
                sysdate,
                sysdate,
                user);
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               I_location);
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            SQLCODE);
      return FALSE;

END INSERT_UPDATE_SINGLE_LOC;
-------------------------------------------------------------------------------
FUNCTION INSERT_UPDATE_MULTI_LOC(O_error_message                        IN OUT  VARCHAR2,
                                 I_update_launch_date                   IN      VARCHAR2,
                                 I_launch_date                          IN      ITEM_LOC_TRAITS.LAUNCH_DATE%TYPE,
                                 I_update_qty_key_options               IN      VARCHAR2,
                                 I_qty_key_options                      IN      ITEM_LOC_TRAITS.QTY_KEY_OPTIONS%TYPE,
                                 I_update_manual_price_entry            IN      VARCHAR2,
                                 I_manual_price_entry                   IN      ITEM_LOC_TRAITS.MANUAL_PRICE_ENTRY%TYPE,
                                 I_update_deposit_code                  IN      VARCHAR2,
                                 I_deposit_code                         IN      ITEM_LOC_TRAITS.DEPOSIT_CODE%TYPE,
                                 I_update_food_stamp_ind                IN      VARCHAR2,
                                 I_food_stamp_ind                       IN      ITEM_LOC_TRAITS.FOOD_STAMP_IND%TYPE,
                                 I_update_wic_ind                       IN      VARCHAR2,
                                 I_wic_ind                              IN      ITEM_LOC_TRAITS.WIC_IND%TYPE,
                                 I_update_proportional_tare_pct         IN      VARCHAR2,
                                 I_proportional_tare_pct                IN      ITEM_LOC_TRAITS.PROPORTIONAL_TARE_PCT%TYPE,
                                 I_update_fixed_tare_value              IN      VARCHAR2,
                                 I_fixed_tare_value                     IN      ITEM_LOC_TRAITS.FIXED_TARE_VALUE%TYPE,
                                 I_update_fixed_tare_uom                IN      VARCHAR2,
                                 I_fixed_tare_uom                       IN      ITEM_LOC_TRAITS.FIXED_TARE_UOM%TYPE,
                                 I_update_reward_eligible_ind           IN      VARCHAR2,
                                 I_reward_eligible_ind                  IN      ITEM_LOC_TRAITS.REWARD_ELIGIBLE_IND%TYPE,
                                 I_update_natl_brand_comp_item          IN      VARCHAR2,
                                 I_natl_brand_comp_item                 IN      ITEM_LOC_TRAITS.NATL_BRAND_COMP_ITEM%TYPE,
                                 I_update_return_policy                 IN      VARCHAR2,
                                 I_return_policy                        IN      ITEM_LOC_TRAITS.RETURN_POLICY%TYPE,
                                 I_update_stop_sale_ind                 IN      VARCHAR2,
                                 I_stop_sale_ind                        IN      ITEM_LOC_TRAITS.STOP_SALE_IND%TYPE,
                                 I_update_elect_mtk_clubs               IN      VARCHAR2,
                                 I_elect_mtk_clubs                      IN      ITEM_LOC_TRAITS.ELECT_MTK_CLUBS%TYPE,
                                 I_update_report_code                   IN      VARCHAR2,
                                 I_report_code                          IN      ITEM_LOC_TRAITS.REPORT_CODE%TYPE,
                                 I_upd_req_shelf_life_on_select         IN      VARCHAR2,
                                 I_req_shelf_life_on_selection          IN      ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_SELECTION%TYPE,
                                 I_upd_req_shelf_life_on_rcpt           IN      VARCHAR2,
                                 I_req_shelf_life_on_receipt            IN      ITEM_LOC_TRAITS.REQ_SHELF_LIFE_ON_RECEIPT%TYPE,
                                 I_upd_ib_shelf_life                    IN      VARCHAR2,
                                 I_ib_shelf_life                        IN      ITEM_LOC_TRAITS.IB_SHELF_LIFE%TYPE,
                                 I_upd_store_reorderable_ind           IN      VARCHAR2,
                                 I_store_reorderable_ind                IN      ITEM_LOC_TRAITS.STORE_REORDERABLE_IND%TYPE,
                                 I_update_rack_size                     IN      VARCHAR2,
                                 I_rack_size                            IN      ITEM_LOC_TRAITS.RACK_SIZE%TYPE,
                                 I_update_full_pallet_item              IN      VARCHAR2,
                                 I_full_pallet_item                     IN      ITEM_LOC_TRAITS.FULL_PALLET_ITEM%TYPE,
                                 I_upd_in_store_market_basket           IN      VARCHAR2,
                                 I_in_store_market_basket               IN      ITEM_LOC_TRAITS.IN_STORE_MARKET_BASKET%TYPE,
                                 I_update_storage_location              IN      VARCHAR2,
                                 I_storage_location                     IN      ITEM_LOC_TRAITS.STORAGE_LOCATION%TYPE,
                                 I_update_alt_storage_location          IN      VARCHAR2,
                                 I_alt_storage_location                 IN      ITEM_LOC_TRAITS.ALT_STORAGE_LOCATION%TYPE,
                                 I_update_returnable_ind                IN      VARCHAR2,
                                 I_returnable_ind                       IN      ITEM_LOC_TRAITS.RETURNABLE_IND%TYPE,
                                 I_update_refundable_ind                IN      VARCHAR2,
                                 I_refundable_ind                       IN      ITEM_LOC_TRAITS.REFUNDABLE_IND%TYPE,
                                 I_update_back_order_ind                IN      VARCHAR2,
                                 I_back_order_ind                       IN      ITEM_LOC_TRAITS.BACK_ORDER_IND%TYPE,
                                 I_item                                 IN      ITEM_LOC_TRAITS.ITEM%TYPE)
RETURN BOOLEAN IS
   L_table       VARCHAR2(64) := 'ITEM_LOC_TRAITS';
   L_program     VARCHAR2(64) := 'ITEM_LOC_TRAITS_SQL.INSERT_UPDATE_MULTI_LOC';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_UPDATE_MULTI_LOC is
      select 'x'
        from item_loc_traits
       where item = I_item
         for update nowait;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_UPDATE_MULTI_LOC',
                    'ITEM_LOC_TRAITS',
                    'Item: '||I_item);
   open C_LOCK_UPDATE_MULTI_LOC;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_UPDATE_MULTI_LOC',
                    'ITEM_LOC_TRAITS',
                    'Item: '||I_item);
   close C_LOCK_UPDATE_MULTI_LOC;

   SQL_LIB.SET_MARK('UPDATE',
                    NULL,
                    'ITEM_LOC_TRAITS',
                    'Item: '||I_item);

   update item_loc_traits i
      set launch_date = decode(I_update_launch_date, 'Y', I_launch_date, i.launch_date),
          qty_key_options = decode(I_update_qty_key_options, 'Y', I_qty_key_options, i.qty_key_options),
          manual_price_entry = decode(I_update_manual_price_entry, 'Y', I_manual_price_entry, i.manual_price_entry),
          deposit_code = decode(I_update_deposit_code, 'Y', I_deposit_code, i.deposit_code),
          food_stamp_ind = decode(I_update_food_stamp_ind, 'Y', I_food_stamp_ind, i.food_stamp_ind),
          wic_ind = decode(I_update_wic_ind, 'Y', I_wic_ind, i.wic_ind),
          proportional_tare_pct = decode(I_update_proportional_tare_pct, 'Y', I_proportional_tare_pct, i.proportional_tare_pct),
          fixed_tare_value = decode(I_update_fixed_tare_value, 'Y', I_fixed_tare_value, i.fixed_tare_value),
          fixed_tare_uom = decode(I_update_fixed_tare_uom, 'Y', I_fixed_tare_uom, i.fixed_tare_uom),
          reward_eligible_ind = decode(I_update_reward_eligible_ind, 'Y', I_reward_eligible_ind, i.reward_eligible_ind),
          natl_brand_comp_item = decode(I_update_natl_brand_comp_item, 'Y', I_natl_brand_comp_item, i.natl_brand_comp_item),
          return_policy = decode(I_update_return_policy, 'Y', I_return_policy, i.return_policy),
          stop_sale_ind = decode(I_update_stop_sale_ind, 'Y', I_stop_sale_ind, i.stop_sale_ind),
          elect_mtk_clubs = decode(I_update_elect_mtk_clubs, 'Y', I_elect_mtk_clubs, i.elect_mtk_clubs),
          report_code = decode(I_update_report_code, 'Y', I_report_code, i.report_code),
          req_shelf_life_on_selection = decode(I_upd_req_shelf_life_on_select, 'Y', I_req_shelf_life_on_selection, i.req_shelf_life_on_selection),
          req_shelf_life_on_receipt = decode(I_upd_req_shelf_life_on_rcpt, 'Y', I_req_shelf_life_on_receipt, i.req_shelf_life_on_receipt),
          ib_shelf_life = decode(I_upd_ib_shelf_life, 'Y', I_ib_shelf_life, i.ib_shelf_life),
          store_reorderable_ind = decode(I_upd_store_reorderable_ind, 'Y', I_store_reorderable_ind, i.store_reorderable_ind),
          rack_size = decode(I_update_rack_size, 'Y', I_rack_size, i.rack_size),
          full_pallet_item = decode(I_update_full_pallet_item, 'Y', I_full_pallet_item, i.full_pallet_item),
          in_store_market_basket = decode(I_upd_in_store_market_basket, 'Y', I_in_store_market_basket, i.in_store_market_basket),
          storage_location = decode(I_update_storage_location, 'Y', I_storage_location, i.storage_location),
          alt_storage_location = decode(I_update_alt_storage_location, 'Y', I_alt_storage_location, i.alt_storage_location),
          returnable_ind = decode(I_update_returnable_ind, 'Y', I_returnable_ind, i.returnable_ind),
          refundable_ind = decode(I_update_refundable_ind, 'Y', I_refundable_ind, i.refundable_ind),
          back_order_ind = decode(I_update_back_order_ind, 'Y', I_back_order_ind, i.back_order_ind),
          last_update_datetime = sysdate,
          last_update_id = user
    where exists(select 'x'
                   from mc_location_temp m
                  where m.location = i.loc
                    and i.item = I_item);

   insert into item_loc_traits(item,
                               loc,
                               launch_date,
                               qty_key_options,
                               manual_price_entry,
                               deposit_code,
                               food_stamp_ind,
                               wic_ind,
                               proportional_tare_pct,
                               fixed_tare_value,
                               fixed_tare_uom,
                               reward_eligible_ind,
                               natl_brand_comp_item,
                               return_policy,
                               stop_sale_ind,
                               elect_mtk_clubs,
                               report_code,
                               req_shelf_life_on_selection,
                               req_shelf_life_on_receipt,
                               ib_shelf_life,
                               store_reorderable_ind,
                               rack_size,
                               full_pallet_item,
                               in_store_market_basket,
                               storage_location,
                               alt_storage_location,
                               returnable_ind,
                               refundable_ind,
                               back_order_ind,
                               create_datetime,
                               last_update_datetime,
                               last_update_id)
      select I_item,
             m.location,
             decode(I_update_launch_date, 'Y', I_launch_date, NULL),
             decode(I_update_qty_key_options, 'Y', I_qty_key_options, NULL),
             decode(I_update_manual_price_entry, 'Y', I_manual_price_entry, NULL),
             decode(I_update_deposit_code, 'Y', I_deposit_code, NULL),
             decode(I_update_food_stamp_ind, 'Y', I_food_stamp_ind, NULL),
             decode(I_update_wic_ind, 'Y', I_wic_ind, NULL),
             decode(I_update_proportional_tare_pct, 'Y', I_proportional_tare_pct, NULL),
             decode(I_update_fixed_tare_value, 'Y', I_fixed_tare_value, NULL),
             decode(I_update_fixed_tare_uom, 'Y', I_fixed_tare_uom, NULL),
             decode(I_update_reward_eligible_ind, 'Y', I_reward_eligible_ind, NULL),
             decode(I_update_natl_brand_comp_item, 'Y', I_natl_brand_comp_item, NULL),
             decode(I_update_return_policy, 'Y', I_return_policy, NULL),
             decode(I_update_stop_sale_ind, 'Y', I_stop_sale_ind, NULL),
             decode(I_update_elect_mtk_clubs, 'Y', I_elect_mtk_clubs, NULL),
             decode(I_update_report_code, 'Y', I_report_code, NULL),
             decode(I_upd_req_shelf_life_on_select, 'Y', I_req_shelf_life_on_selection, NULL),
             decode(I_upd_req_shelf_life_on_rcpt, 'Y', I_req_shelf_life_on_receipt, NULL),
             decode(I_upd_ib_shelf_life, 'Y', I_ib_shelf_life, NULL),
             decode(I_upd_store_reorderable_ind, 'Y', I_store_reorderable_ind, NULL),
             decode(I_update_rack_size, 'Y', I_rack_size, NULL),
             decode(I_update_full_pallet_item, 'Y', I_full_pallet_item, NULL),
             decode(I_upd_in_store_market_basket, 'Y', I_in_store_market_basket, NULL),
             decode(I_update_storage_location, 'Y', I_storage_location, NULL),
             decode(I_update_alt_storage_location, 'Y', I_alt_storage_location, NULL),
             decode(I_update_returnable_ind, 'Y', I_returnable_ind, NULL),
             decode(I_update_refundable_ind, 'Y', I_refundable_ind, NULL),
             decode(I_update_back_order_ind, 'Y', I_back_order_ind, NULL),
             sysdate,
             sysdate,
             user
        from mc_location_temp m
       where not exists(select 'x'
                          from item_loc_traits i
                         where m.location = i.loc
                           and i.item = I_item);

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               NULL);
         return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            SQLCODE);
      return FALSE;

END INSERT_UPDATE_MULTI_LOC;
-------------------------------------------------------------------------------
FUNCTION POS_MODS_INSERT(O_error_message              IN OUT  VARCHAR2,
                         I_launch_date_upd            IN      BOOLEAN,
                         I_launch_date                IN      POS_MODS.LAUNCH_DATE%TYPE,
                         I_qty_key_options_upd        IN      BOOLEAN,
                         I_qty_key_options            IN      POS_MODS.QTY_KEY_OPTIONS%TYPE,
                         I_manual_price_entry_upd     IN      BOOLEAN,
                         I_manual_price_entry         IN      POS_MODS.MANUAL_PRICE_ENTRY%TYPE,
                         I_deposit_code_upd           IN      BOOLEAN,
                         I_deposit_code               IN      POS_MODS.DEPOSIT_CODE%TYPE,
                         I_food_stamp_ind_upd         IN      BOOLEAN,
                         I_food_stamp_ind             IN      POS_MODS.FOOD_STAMP_IND%TYPE,
                         I_wic_ind_upd                IN      BOOLEAN,
                         I_wic_ind                    IN      POS_MODS.WIC_IND%TYPE,
                         I_proportional_tare_pct_upd  IN      BOOLEAN,
                         I_proportional_tare_pct      IN      POS_MODS.PROPORTIONAL_TARE_PCT%TYPE,
                         I_fixed_tare_value_upd       IN      BOOLEAN,
                         I_fixed_tare_value           IN      POS_MODS.FIXED_TARE_VALUE%TYPE,
                         I_fixed_tare_uom_upd         IN      BOOLEAN,
                         I_fixed_tare_uom             IN      POS_MODS.FIXED_TARE_UOM%TYPE,
                         I_reward_eligible_ind_upd    IN      BOOLEAN,
                         I_reward_eligible_ind        IN      POS_MODS.REWARD_ELIGIBLE_IND%TYPE,
                         I_elect_mtk_clubs_upd        IN      BOOLEAN,
                         I_elect_mtk_clubs            IN      POS_MODS.ELECT_MTK_CLUBS%TYPE,
                         I_return_policy_upd          IN      BOOLEAN,
                         I_return_policy              IN      POS_MODS.RETURN_POLICY%TYPE,
                         I_stop_sale_ind_upd          IN      BOOLEAN,
                         I_stop_sale_ind              IN      POS_MODS.STOP_SALE_IND%TYPE,
                         I_returnable_ind_upd         IN      BOOLEAN,
                         I_returnable_ind             IN      POS_MODS.RETURNABLE_IND%TYPE,
                         I_refundable_ind_upd         IN      BOOLEAN,
                         I_refundable_ind             IN      POS_MODS.REFUNDABLE_IND%TYPE,
                         I_back_order_ind_upd         IN      BOOLEAN,
                         I_back_order_ind             IN      POS_MODS.BACK_ORDER_IND%TYPE,
                         I_item                       IN      ITEM_LOC_TRAITS.ITEM%TYPE,
                         I_loc                        IN      VARCHAR2)
RETURN BOOLEAN IS
   L_program       VARCHAR2(65) := 'ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_launch_date_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           50,
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
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           I_launch_date,
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
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          50,
                                                          I_item,
                                                          I_launch_date,
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
   end if;
   ---
   if I_qty_key_options_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           51,
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
                                           I_qty_key_options,
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
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          51,
                                                          I_item,
                                                          NULL,
                                                          I_qty_key_options,
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
   end if;
   ---
   if I_manual_price_entry_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           52,
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
                                           I_manual_price_entry,
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
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          52,
                                                          I_item,
                                                          NULL,
                                                          NULL,
                                                          I_manual_price_entry,
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
   end if;
   ---
   if I_deposit_code_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           53,
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
                                           I_deposit_code,
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
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          53,
                                                          I_item,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          I_deposit_code,
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
   end if;
   ---
   if I_food_stamp_ind_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           54,
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
                                           I_food_stamp_ind,
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
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          54,
                                                          I_item,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          I_food_stamp_ind,
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
   end if;
   ---
   if I_wic_ind_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           55,
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
                                           I_wic_ind,
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
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          55,
                                                          I_item,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          I_wic_ind,
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
   end if;
   ---
   if I_proportional_tare_pct_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           56,
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
                                           I_proportional_tare_pct,
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
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          56,
                                                          I_item,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          I_proportional_tare_pct,
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
   end if;
   ---
   if I_fixed_tare_value_upd and
      I_fixed_tare_uom_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           57,
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
                                           I_fixed_tare_value,
                                           I_fixed_tare_uom,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL) = FALSE then
            return FALSE;
         end if;
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          57,
                                                          I_item,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          I_fixed_tare_value,
                                                          I_fixed_tare_uom,
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
   end if;
   ---
   if I_reward_eligible_ind_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           58,
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
                                           I_reward_eligible_ind,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL) = FALSE then
            return FALSE;
         end if;
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          58,
                                                          I_item,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          I_reward_eligible_ind,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;
   ---
   if I_elect_mtk_clubs_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           59,
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
                                           I_elect_mtk_clubs,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL) = FALSE then
            return FALSE;
         end if;
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          59,
                                                          I_item,
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
                                                          I_elect_mtk_clubs,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;
   ---
   if I_return_policy_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           60,
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
                                           I_return_policy,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL) = FALSE then
            return FALSE;
         end if;
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          60,
                                                          I_item,
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
                                                          I_return_policy,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;
   ---
   if I_stop_sale_ind_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           61,
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
                                           NULL,
                                           I_stop_sale_ind,
                                           NULL,
                                           NULL,
                                           NULL) = FALSE then
            return FALSE;
         end if;
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          61,
                                                          I_item,
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
                                                          I_stop_sale_ind,
                                                          NULL,
                                                          NULL,
                                                          NULL) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;
   ---
   if I_returnable_ind_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           62,
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
                                           NULL,
                                           NULL,
                                           I_returnable_ind,
                                           NULL,
                                           NULL) = FALSE then
            return FALSE;
         end if;
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          62,
                                                          I_item,
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
                                                          I_returnable_ind,
                                                          NULL,
                                                          NULL) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;
   ---
   if I_refundable_ind_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           63,
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
                                           NULL,
                                           NULL,
                                           NULL,
                                           I_refundable_ind,
                                           NULL) = FALSE then
            return FALSE;
         end if;
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          63,
                                                          I_item,
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
                                                          I_refundable_ind,
                                                          NULL) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;
   ---
   if I_back_order_ind_upd then
      if I_loc is NOT NULL then
         if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                           64,
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
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           I_back_order_ind) = FALSE then
            return FALSE;
         end if;
      else
         if ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC(O_error_message,
                                                          64,
                                                          I_item,
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
                                                          I_back_order_ind) = FALSE then
            return FALSE;
         end if;
      end if;
   end if;
   ---
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END POS_MODS_INSERT;
-------------------------------------------------------------------------------
FUNCTION POS_MODS_INSERT_MULTI_LOC(O_error_message          IN OUT VARCHAR2,
                                   I_tran_type              IN POS_MODS.TRAN_TYPE%TYPE,
                                   I_item                   IN POS_MODS.ITEM%TYPE,
                                   I_launch_date            IN POS_MODS.LAUNCH_DATE%TYPE,
                                   I_qty_key_options        IN POS_MODS.QTY_KEY_OPTIONS%TYPE,
                                   I_manual_price_entry     IN POS_MODS.MANUAL_PRICE_ENTRY%TYPE,
                                   I_deposit_code           IN POS_MODS.DEPOSIT_CODE%TYPE,
                                   I_food_stamp_ind         IN POS_MODS.FOOD_STAMP_IND%TYPE,
                                   I_wic_ind                IN POS_MODS.WIC_IND%TYPE,
                                   I_proportional_tare_pct  IN POS_MODS.PROPORTIONAL_TARE_PCT%TYPE,
                                   I_fixed_tare_value       IN POS_MODS.FIXED_TARE_VALUE%TYPE,
                                   I_fixed_tare_uom         IN POS_MODS.FIXED_TARE_UOM%TYPE,
                                   I_reward_eligible_ind    IN POS_MODS.REWARD_ELIGIBLE_IND%TYPE,
                                   I_elect_mtk_clubs        IN POS_MODS.ELECT_MTK_CLUBS%TYPE,
                                   I_return_policy          IN POS_MODS.RETURN_POLICY%TYPE,
                                   I_stop_sale_ind          IN POS_MODS.STOP_SALE_IND%TYPE,
                                   I_returnable_ind         IN POS_MODS.RETURNABLE_IND%TYPE,
                                   I_refundable_ind         IN POS_MODS.REFUNDABLE_IND%TYPE,
                                   I_back_order_ind         IN POS_MODS.BACK_ORDER_IND%TYPE)
RETURN BOOLEAN IS
   L_program       VARCHAR2(65) := 'ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT_MULTI_LOC';

   cursor C_POS_MODS_MULTI_LOC is
      select location
        from mc_location_temp
       where loc_type = 'S';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;

   FOR loc in C_POS_MODS_MULTI_LOC LOOP
      if POS_UPDATE_SQL.POS_MODS_INSERT(O_error_message,
                                        I_tran_type,
                                        I_item,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        loc.location,
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
                                        I_launch_date,
                                        I_qty_key_options,
                                        I_manual_price_entry,
                                        I_deposit_code,
                                        I_food_stamp_ind,
                                        I_wic_ind,
                                        I_proportional_tare_pct,
                                        I_fixed_tare_value,
                                        I_fixed_tare_uom,
                                        I_reward_eligible_ind,
                                        I_elect_mtk_clubs,
                                        I_return_policy,
                                        I_stop_sale_ind,
                                        I_returnable_ind,
                                        I_refundable_ind,
                                        I_back_order_ind) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END POS_MODS_INSERT_MULTI_LOC;
-------------------------------------------------------------------------------
FUNCTION COPY_DOWN_PARENT_SINGLE_LOC (O_error_message               IN OUT VARCHAR2,
                                      I_launch_date_upd             IN     BOOLEAN,
                                      I_launch_date                 IN     POS_MODS.LAUNCH_DATE%TYPE,
                                      I_qty_key_options_upd         IN     BOOLEAN,
                                      I_qty_key_options             IN     POS_MODS.QTY_KEY_OPTIONS%TYPE,
                                      I_manual_price_entry_upd      IN     BOOLEAN,
                                      I_manual_price_entry          IN     POS_MODS.MANUAL_PRICE_ENTRY%TYPE,
                                      I_deposit_code_upd            IN     BOOLEAN,
                                      I_deposit_code                IN     POS_MODS.DEPOSIT_CODE%TYPE,
                                      I_food_stamp_ind_upd          IN     BOOLEAN,
                                      I_food_stamp_ind              IN     POS_MODS.FOOD_STAMP_IND%TYPE,
                                      I_wic_ind_upd                 IN     BOOLEAN,
                                      I_wic_ind                     IN     POS_MODS.WIC_IND%TYPE,
                                      I_proportional_tare_pct_upd   IN     BOOLEAN,
                                      I_proportional_tare_pct       IN     POS_MODS.PROPORTIONAL_TARE_PCT%TYPE,
                                      I_fixed_tare_value_upd        IN     BOOLEAN,
                                      I_fixed_tare_value            IN     POS_MODS.FIXED_TARE_VALUE%TYPE,
                                      I_fixed_tare_uom_upd          IN     BOOLEAN,
                                      I_fixed_tare_uom              IN     POS_MODS.FIXED_TARE_UOM%TYPE,
                                      I_reward_eligible_ind_upd     IN     BOOLEAN,
                                      I_reward_eligible_ind         IN     POS_MODS.REWARD_ELIGIBLE_IND%TYPE,
                                      I_elect_mtk_clubs_upd         IN     BOOLEAN,
                                      I_elect_mtk_clubs             IN     POS_MODS.ELECT_MTK_CLUBS%TYPE,
                                      I_return_policy_upd           IN     BOOLEAN,
                                      I_return_policy               IN     POS_MODS.RETURN_POLICY%TYPE,
                                      I_stop_sale_ind_upd           IN     BOOLEAN,
                                      I_stop_sale_ind               IN     POS_MODS.STOP_SALE_IND%TYPE,
                                      I_returnable_ind_upd          IN     BOOLEAN,
                                      I_returnable_ind              IN     POS_MODS.RETURNABLE_IND%TYPE,
                                      I_refundable_ind_upd          IN     BOOLEAN,
                                      I_refundable_ind              IN     POS_MODS.REFUNDABLE_IND%TYPE,
                                      I_back_order_ind_upd          IN     BOOLEAN,
                                      I_back_order_ind              IN     POS_MODS.BACK_ORDER_IND%TYPE,
                                      I_item                        IN     ITEM_MASTER.ITEM%TYPE,
                                      I_loc                         IN     VARCHAR2)
RETURN BOOLEAN IS

   L_program       VARCHAR2(65) := 'ITEM_LOC_TRAITS_SQL.COPY_DOWN_PARENT_SINGLE_LOC';
   L_table         VARCHAR2(65) := 'ITEM_LOC_TRAITS';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   L_error_message  VARCHAR2(255);

   cursor C_LOCK_ITEM_LOC_TRAITS is
      select 'x'
        from item_loc_traits ilt
       where exists (select 'x'
                       from item_master im
                      where im.item = ilt.item
                        and (im.item_parent = I_item
                         or im.item_grandparent = I_item)
                        and im.item_level <= im.tran_level)
         and loc = to_number(I_loc)
         for update nowait;

   cursor C_POS_MODS_INSERT_CHILDREN is
      select im.item,
             il.loc
        from item_loc il,
             item_master im
       where im.item_parent = I_item
         and im.item_level = im.tran_level
         and im.status = 'A'
         and il.item = im.item
         and il.loc = to_number(I_loc)
         and il.loc_type = 'S'
      UNION ALL
      select im.item,
             il.loc
        from item_loc il,
             item_master im
       where im.item_grandparent = I_item
         and im.item_level = im.tran_level
         and im.status = 'A'
         and il.item = im.item
         and il.loc = to_number(I_loc)
         and il.loc_type = 'S';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_loc is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_loc',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_LOC_TRAITS',
                    'ITEM_LOC_TRAITS', 'Item: ' || I_item || ', Location: ' || I_loc);
   OPEN  C_LOCK_ITEM_LOC_TRAITS;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_LOC_TRAITS',
                    'ITEM_LOC_TRAITS', 'Item: ' || I_item || ', Location: ' || I_loc);
   CLOSE C_LOCK_ITEM_LOC_TRAITS;

   SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_LOC_TRAITS',
                    'Item: ' || I_item || ', Location: ' || I_loc);

   delete from item_loc_traits ilt
    where exists (select 'x'
                    from item_master im
                   where im.item = ilt.item
                     and (im.item_parent = I_item
                      or im.item_grandparent = I_item)
                     and im.item_level <= im.tran_level)
      and loc = to_number(I_loc);
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_LOC_TRAITS',
                    'Item: ' || I_item || ', Location: ' || I_loc);

   insert into item_loc_traits(item,
                               loc,
                               launch_date,
                               qty_key_options,
                               manual_price_entry,
                               deposit_code,
                               food_stamp_ind,
                               wic_ind,
                               proportional_tare_pct,
                               fixed_tare_value,
                               fixed_tare_uom,
                               reward_eligible_ind,
                               natl_brand_comp_item,
                               return_policy,
                               stop_sale_ind,
                               elect_mtk_clubs,
                               report_code,
                               req_shelf_life_on_selection,
                               req_shelf_life_on_receipt,
                               ib_shelf_life,
                               store_reorderable_ind,
                               rack_size,
                               full_pallet_item,
                               in_store_market_basket,
                               storage_location,
                               alt_storage_location,
                               returnable_ind,
                               refundable_ind,
                               back_order_ind,
                               create_datetime,
                               last_update_id,
                               last_update_datetime)
                               select im.item,
                                      ilt.loc,
                                      ilt.launch_date,
                                      ilt.qty_key_options,
                                      ilt.manual_price_entry,
                                      ilt.deposit_code,
                                      ilt.food_stamp_ind,
                                      ilt.wic_ind,
                                      ilt.proportional_tare_pct,
                                      ilt.fixed_tare_value,
                                      ilt.fixed_tare_uom,
                                      ilt.reward_eligible_ind,
                                      ilt.natl_brand_comp_item,
                                      ilt.return_policy,
                                      ilt.stop_sale_ind,
                                      ilt.elect_mtk_clubs,
                                      ilt.report_code,
                                      ilt.req_shelf_life_on_selection,
                                      ilt.req_shelf_life_on_receipt,
                                      ilt.ib_shelf_life,
                                      ilt.store_reorderable_ind,
                                      ilt.rack_size,
                                      ilt.full_pallet_item,
                                      ilt.in_store_market_basket,
                                      ilt.storage_location,
                                      ilt.alt_storage_location,
                                      ilt.returnable_ind,
                                      ilt.refundable_ind,
                                      ilt.back_order_ind,
                                      sysdate,
                                      user,
                                      sysdate
                                 from item_loc_traits ilt,
                                      item_loc il,
                                      item_master im
                                where ilt.item = I_item
                                  and il.loc = to_number(I_loc)
                                  and im.item_parent = ilt.item
                                  and im.item_level <= im.tran_level
                                  and il.item = im.item
                                  and il.loc = ilt.loc
                               UNION ALL
                               select im.item,
                                      ilt.loc,
                                      ilt.launch_date,
                                      ilt.qty_key_options,
                                      ilt.manual_price_entry,
                                      ilt.deposit_code,
                                      ilt.food_stamp_ind,
                                      ilt.wic_ind,
                                      ilt.proportional_tare_pct,
                                      ilt.fixed_tare_value,
                                      ilt.fixed_tare_uom,
                                      ilt.reward_eligible_ind,
                                      ilt.natl_brand_comp_item,
                                      ilt.return_policy,
                                      ilt.stop_sale_ind,
                                      ilt.elect_mtk_clubs,
                                      ilt.report_code,
                                      ilt.req_shelf_life_on_selection,
                                      ilt.req_shelf_life_on_receipt,
                                      ilt.ib_shelf_life,
                                      ilt.store_reorderable_ind,
                                      ilt.rack_size,
                                      ilt.full_pallet_item,
                                      ilt.in_store_market_basket,
                                      ilt.storage_location,
                                      ilt.alt_storage_location,
                                      ilt.returnable_ind,
                                      ilt.refundable_ind,
                                      ilt.back_order_ind,
                                      sysdate,
                                      user,
                                      sysdate
                                 from item_loc_traits ilt,
                                      item_loc il,
                                      item_master im
                                where ilt.item = I_item
                                  and il.loc = to_number(I_loc)
                                  and im.item_grandparent = ilt.item
                                  and im.item_level <= im.tran_level
                                  and il.item = im.item
                                  and il.loc = ilt.loc;

   FOR pos_mod IN C_POS_MODS_INSERT_CHILDREN LOOP
      if POS_MODS_INSERT(O_error_message,
                         I_launch_date_upd,
                         I_launch_date,
                         I_qty_key_options_upd,
                         I_qty_key_options,
                         I_manual_price_entry_upd,
                         I_manual_price_entry,
                         I_deposit_code_upd,
                         I_deposit_code,
                         I_food_stamp_ind_upd,
                         I_food_stamp_ind,
                         I_wic_ind_upd,
                         I_wic_ind,
                         I_proportional_tare_pct_upd,
                         I_proportional_tare_pct,
                         I_fixed_tare_value_upd,
                         I_fixed_tare_value,
                         I_fixed_tare_uom_upd,
                         I_fixed_tare_uom,
                         I_reward_eligible_ind_upd,
                         I_reward_eligible_ind,
                         I_elect_mtk_clubs_upd,
                         I_elect_mtk_clubs,
                         I_return_policy_upd,
                         I_return_policy,
                         I_stop_sale_ind_upd,
                         I_stop_sale_ind,
                         I_returnable_ind_upd,
                         I_returnable_ind,
                         I_refundable_ind_upd,
                         I_refundable_ind,
                         I_back_order_ind_upd,
                         I_back_order_ind,
                         pos_mod.item,
                         pos_mod.loc) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                           L_table,
                                           I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END COPY_DOWN_PARENT_SINGLE_LOC;
-------------------------------------------------------------------------------
FUNCTION COPY_DOWN_PARENT_MULTI_LOC (O_error_message              IN OUT  VARCHAR2,
                                     I_launch_date_upd            IN      BOOLEAN,
                                     I_launch_date                IN      POS_MODS.LAUNCH_DATE%TYPE,
                                     I_qty_key_options_upd        IN      BOOLEAN,
                                     I_qty_key_options            IN      POS_MODS.QTY_KEY_OPTIONS%TYPE,
                                     I_manual_price_entry_upd     IN      BOOLEAN,
                                     I_manual_price_entry         IN      POS_MODS.MANUAL_PRICE_ENTRY%TYPE,
                                     I_deposit_code_upd           IN      BOOLEAN,
                                     I_deposit_code               IN      POS_MODS.DEPOSIT_CODE%TYPE,
                                     I_food_stamp_ind_upd         IN      BOOLEAN,
                                     I_food_stamp_ind             IN      POS_MODS.FOOD_STAMP_IND%TYPE,
                                     I_wic_ind_upd                IN      BOOLEAN,
                                     I_wic_ind                    IN      POS_MODS.WIC_IND%TYPE,
                                     I_proportional_tare_pct_upd  IN      BOOLEAN,
                                     I_proportional_tare_pct      IN      POS_MODS.PROPORTIONAL_TARE_PCT%TYPE,
                                     I_fixed_tare_value_upd       IN      BOOLEAN,
                                     I_fixed_tare_value           IN      POS_MODS.FIXED_TARE_VALUE%TYPE,
                                     I_fixed_tare_uom_upd         IN      BOOLEAN,
                                     I_fixed_tare_uom             IN      POS_MODS.FIXED_TARE_UOM%TYPE,
                                     I_reward_eligible_ind_upd    IN      BOOLEAN,
                                     I_reward_eligible_ind        IN      POS_MODS.REWARD_ELIGIBLE_IND%TYPE,
                                     I_elect_mtk_clubs_upd        IN      BOOLEAN,
                                     I_elect_mtk_clubs            IN      POS_MODS.ELECT_MTK_CLUBS%TYPE,
                                     I_return_policy_upd          IN      BOOLEAN,
                                     I_return_policy              IN      POS_MODS.RETURN_POLICY%TYPE,
                                     I_stop_sale_ind_upd          IN      BOOLEAN,
                                     I_stop_sale_ind              IN      POS_MODS.STOP_SALE_IND%TYPE,
                                     I_returnable_ind_upd         IN      BOOLEAN,
                                     I_returnable_ind             IN      POS_MODS.RETURNABLE_IND%TYPE,
                                     I_refundable_ind_upd         IN      BOOLEAN,
                                     I_refundable_ind             IN      POS_MODS.REFUNDABLE_IND%TYPE,
                                     I_back_order_ind_upd         IN      BOOLEAN,
                                     I_back_order_ind             IN      POS_MODS.BACK_ORDER_IND%TYPE,
                                     I_item                       IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(65) := 'ITEM_LOC_TRAITS_SQL.COPY_DOWN_PARENT_MULTI_LOC';
   L_table         VARCHAR2(65) := 'ITEM_LOC_TRAITS';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   L_error_message  VARCHAR2(255);

   cursor C_LOCK_ITEM_LOC_TRAITS is
      select 'x'
        from item_loc_traits ilt
       where exists (select 'x'
                       from item_master im
                      where im.item = ilt.item
                        and (im.item_parent = I_item
                         or im.item_grandparent = I_item)
                        and im.item_level <= im.tran_level)
         and exists (select 'x'
                       from mc_location_temp m
                      where m.location = ilt.loc)
         for update nowait;

   cursor C_POS_MODS_INSERT_CHILDREN is
      select im.item,
             ilt.loc
        from item_loc_traits ilt,
             mc_location_temp mlt,
             item_master im
       where ilt.item = I_item
         and im.item_parent = ilt.item
         and im.item_level = im.tran_level
         and im.status = 'A'
         and mlt.location = ilt.loc
         and mlt.loc_type = 'S'
         and exists( select 'x'
                       from item_loc itl
                      where itl.item = im.item
                        and itl.loc  = ilt.loc)
      UNION ALL
      select im.item,
             ilt.loc
        from item_loc_traits ilt,
             mc_location_temp mlt,
             item_master im
       where ilt.item = I_item
         and im.item_grandparent = ilt.item
         and im.item_level = im.tran_level
         and im.status = 'A'
         and mlt.location = ilt.loc
         and mlt.loc_type = 'S'
         and exists( select 'x'
                       from item_loc itl
                      where itl.item = im.item
                        and itl.loc  = ilt.loc);

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                             'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_ITEM_LOC_TRAITS',
                    'ITEM_LOC_TRAITS', 'Item: ' || I_item);
   OPEN  C_LOCK_ITEM_LOC_TRAITS;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_ITEM_LOC_TRAITS',
                    'ITEM_LOC_TRAITS', 'Item: ' || I_item);
   CLOSE C_LOCK_ITEM_LOC_TRAITS;

   SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_LOC_TRAITS',
                    'Item: ' || I_item);

   delete from item_loc_traits ilt
    where exists (select 'x'
                    from item_master im
                   where im.item = ilt.item
                     and (im.item_parent = I_item
                      or im.item_grandparent = I_item)
                     and im.item_level <= im.tran_level)
      and exists (select 'x'
                    from mc_location_temp m
                   where m.location = ilt.loc);
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_LOC_TRAITS',
                    'Item: ' || I_item);

   insert into item_loc_traits(item,
                               loc,
                               launch_date,
                               qty_key_options,
                               manual_price_entry,
                               deposit_code,
                               food_stamp_ind,
                               wic_ind,
                               proportional_tare_pct,
                               fixed_tare_value,
                               fixed_tare_uom,
                               reward_eligible_ind,
                               natl_brand_comp_item,
                               return_policy,
                               stop_sale_ind,
                               elect_mtk_clubs,
                               report_code,
                               req_shelf_life_on_selection,
                               req_shelf_life_on_receipt,
                               ib_shelf_life,
                               store_reorderable_ind,
                               rack_size,
                               full_pallet_item,
                               in_store_market_basket,
                               storage_location,
                               alt_storage_location,
                               returnable_ind,
                               refundable_ind,
                               back_order_ind,
                               create_datetime,
                               last_update_id,
                               last_update_datetime)
                               select im.item,
                                      ilt.loc,
                                      ilt.launch_date,
                                      ilt.qty_key_options,
                                      ilt.manual_price_entry,
                                      ilt.deposit_code,
                                      ilt.food_stamp_ind,
                                      ilt.wic_ind,
                                      ilt.proportional_tare_pct,
                                      ilt.fixed_tare_value,
                                      ilt.fixed_tare_uom,
                                      ilt.reward_eligible_ind,
                                      ilt.natl_brand_comp_item,
                                      ilt.return_policy,
                                      ilt.stop_sale_ind,
                                      ilt.elect_mtk_clubs,
                                      ilt.report_code,
                                      ilt.req_shelf_life_on_selection,
                                      ilt.req_shelf_life_on_receipt,
                                      ilt.ib_shelf_life,
                                      ilt.store_reorderable_ind,
                                      ilt.rack_size,
                                      ilt.full_pallet_item,
                                      ilt.in_store_market_basket,
                                      ilt.storage_location,
                                      ilt.alt_storage_location,
                                      ilt.returnable_ind,
                                      ilt.refundable_ind,
                                      ilt.back_order_ind,
                                      sysdate,
                                      user,
                                      sysdate
                                 from item_loc_traits ilt,
                                      mc_location_temp mlt,
                                      item_master im
                                where ilt.item = I_item
                                  and im.item_parent = ilt.item
                                  and im.item_level <= im.tran_level
                                  and mlt.location = ilt.loc
                                  and exists( select 'x'
                                                from item_loc itl
                                               where itl.item = im.item
                                                 and itl.loc  = ilt.loc)
                               UNION ALL
                               select im.item,
                                      ilt.loc,
                                      ilt.launch_date,
                                      ilt.qty_key_options,
                                      ilt.manual_price_entry,
                                      ilt.deposit_code,
                                      ilt.food_stamp_ind,
                                      ilt.wic_ind,
                                      ilt.proportional_tare_pct,
                                      ilt.fixed_tare_value,
                                      ilt.fixed_tare_uom,
                                      ilt.reward_eligible_ind,
                                      ilt.natl_brand_comp_item,
                                      ilt.return_policy,
                                      ilt.stop_sale_ind,
                                      ilt.elect_mtk_clubs,
                                      ilt.report_code,
                                      ilt.req_shelf_life_on_selection,
                                      ilt.req_shelf_life_on_receipt,
                                      ilt.ib_shelf_life,
                                      ilt.store_reorderable_ind,
                                      ilt.rack_size,
                                      ilt.full_pallet_item,
                                      ilt.in_store_market_basket,
                                      ilt.storage_location,
                                      ilt.alt_storage_location,
                                      ilt.returnable_ind,
                                      ilt.refundable_ind,
                                      ilt.back_order_ind,
                                      sysdate,
                                      user,
                                      sysdate
                                 from item_loc_traits ilt,
                                      mc_location_temp mlt,
                                      item_master im
                                where ilt.item = I_item
                                  and im.item_grandparent = ilt.item
                                  and im.item_level <= im.tran_level
                                  and mlt.location = ilt.loc
                                  and exists( select 'x'
                                                from item_loc itl
                                               where itl.item = im.item
                                                 and itl.loc  = ilt.loc);

   FOR pos_mod IN C_POS_MODS_INSERT_CHILDREN LOOP
      if POS_MODS_INSERT(O_error_message,
                         I_launch_date_upd,
                         I_launch_date,
                         I_qty_key_options_upd,
                         I_qty_key_options,
                         I_manual_price_entry_upd,
                         I_manual_price_entry,
                         I_deposit_code_upd,
                         I_deposit_code,
                         I_food_stamp_ind_upd,
                         I_food_stamp_ind,
                         I_wic_ind_upd,
                         I_wic_ind,
                         I_proportional_tare_pct_upd,
                         I_proportional_tare_pct,
                         I_fixed_tare_value_upd,
                         I_fixed_tare_value,
                         I_fixed_tare_uom_upd,
                         I_fixed_tare_uom,
                         I_reward_eligible_ind_upd,
                         I_reward_eligible_ind,
                         I_elect_mtk_clubs_upd,
                         I_elect_mtk_clubs,
                         I_return_policy_upd,
                         I_return_policy,
                         I_stop_sale_ind_upd,
                         I_stop_sale_ind,
                         I_returnable_ind_upd,
                         I_returnable_ind,
                         I_refundable_ind_upd,
                         I_refundable_ind,
                         I_back_order_ind_upd,
                         I_back_order_ind,
                         pos_mod.item,
                         pos_mod.loc) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                           L_table,
                                           I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END COPY_DOWN_PARENT_MULTI_LOC;
-------------------------------------------------------------------------------
   --12-Jul-2007 WiproEnabler/Karthik Dhanapal - MOD 365b   Begin
   ---------------------------------------------------------------------------------------------------------------
   --TSL_COPY_BASE_SINGLE_LOC This function will default identical item/location trait records down to the Variant
   -- Items for the inputted base item and location. The defaulting will go down as far as the transaction level.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_COPY_BASE_SINGLE_LOC(O_error_message             IN OUT VARCHAR2,
                                     I_launch_date_upd           IN     BOOLEAN,
                                     I_launch_date               IN     POS_MODS.LAUNCH_DATE%TYPE,
                                     I_qty_key_options_upd       IN     BOOLEAN,
                                     I_qty_key_options           IN     POS_MODS.QTY_KEY_OPTIONS%TYPE,
                                     I_manual_price_entry_upd    IN     BOOLEAN,
                                     I_manual_price_entry        IN     POS_MODS.MANUAL_PRICE_ENTRY%TYPE,
                                     I_deposit_code_upd          IN     BOOLEAN,
                                     I_deposit_code              IN     POS_MODS.DEPOSIT_CODE%TYPE,
                                     I_food_stamp_ind_upd        IN     BOOLEAN,
                                     I_food_stamp_ind            IN     POS_MODS.FOOD_STAMP_IND%TYPE,
                                     I_wic_ind_upd               IN     BOOLEAN,
                                     I_wic_ind                   IN     POS_MODS.WIC_IND%TYPE,
                                     I_proportional_tare_pct_upd IN     BOOLEAN,
                                     I_proportional_tare_pct     IN     POS_MODS.PROPORTIONAL_TARE_PCT%TYPE,
                                     I_fixed_tare_value_upd      IN     BOOLEAN,
                                     I_fixed_tare_value          IN     POS_MODS.FIXED_TARE_VALUE%TYPE,
                                     I_fixed_tare_uom_upd        IN     BOOLEAN,
                                     I_fixed_tare_uom            IN     POS_MODS.FIXED_TARE_UOM%TYPE,
                                     I_reward_eligible_ind_upd   IN     BOOLEAN,
                                     I_reward_eligible_ind       IN     POS_MODS.REWARD_ELIGIBLE_IND%TYPE,
                                     I_elect_mtk_clubs_upd       IN     BOOLEAN,
                                     I_elect_mtk_clubs           IN     POS_MODS.ELECT_MTK_CLUBS%TYPE,
                                     I_return_policy_upd         IN     BOOLEAN,
                                     I_return_policy             IN     POS_MODS.RETURN_POLICY%TYPE,
                                     I_stop_sale_ind_upd         IN     BOOLEAN,
                                     I_stop_sale_ind             IN     POS_MODS.STOP_SALE_IND%TYPE,
                                     I_returnable_ind_upd        IN     BOOLEAN,
                                     I_returnable_ind            IN     POS_MODS.RETURNABLE_IND%TYPE,
                                     I_refundable_ind_upd        IN     BOOLEAN,
                                     I_refundable_ind            IN     POS_MODS.REFUNDABLE_IND%TYPE,
                                     I_back_order_ind_upd        IN     BOOLEAN,
                                     I_back_order_ind            IN     POS_MODS.BACK_ORDER_IND%TYPE,
                                     I_item                      IN     ITEM_MASTER.ITEM%TYPE,
                                     I_loc                       IN     VARCHAR2)
      return BOOLEAN is

      L_program VARCHAR2(64) := 'ITEM_LOC_TRAITS_SQL.TSL_COPY_BASE_SINGLE_LOC';
      L_table   VARCHAR2(65) := 'ITEM_LOC_TRAITS';
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);
      --This cursor will lock the variant/loc information on the table ITEM_LOC_TRAITS table
      cursor C_LOCK_VARIANT_LOC_TRAITS is
         select 'x'
           from item_loc_traits ilt
          where ilt.loc = TO_NUMBER(I_loc)
            and exists (select im.item
                          from item_master im
                         where ilt.item         = im.item
                           and im.tsl_base_item = I_item
                           and im.tsl_base_item != im.item
                           and im.item_level    = im.tran_level
                           and im.item_level    = 2)
            for update nowait;
      --This cursor will return all the Variant Items associated to a given location.
      cursor C_POS_MODS_INSERT_VARIANT is
         select im.item,
                il.loc
           from item_master im,
                item_loc    il
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and im.status        = 'A'
            and il.item          = im.item
            and il.loc           = TO_NUMBER(I_loc)
            and il.loc_type      = 'S';
   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                               'I_item',
                                               L_program,
                                               NULL);
         return FALSE;
      end if;
      --Checking whether I_loc is null
      if I_loc is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                               'I_loc',
                                               L_program,
                                               NULL);
         return FALSE;
      end if;

      --Opening the cursor C_LOCK_VARIANT_LOC_TRAITS
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_VARIANT_LOC_TRAITS',
                       'ITEM_LOC_TRAITS',
                       'ITEM: ' || I_item);
      open C_LOCK_VARIANT_LOC_TRAITS;
      --Closing the cursor C_LOCK_VARIANT_LOC_TRAITS
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_VARIANT_LOC_TRAITS',
                       'ITEM_LOC_TRAITS',
                       'ITEM: ' || I_item);
      close C_LOCK_VARIANT_LOC_TRAITS;
      --
      --Delete records from the ITEM_LOC_TRAITS table
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'ITEM_LOC_TRAITS',
                       'ITEM: ' || I_item);
      --
      delete from item_loc_traits ilt
       where exists (select 'x'
                       from item_master im
                      where im.item          = ilt.item
                        and im.tsl_base_item = I_item
                        and im.tsl_base_item != im.item
                        and im.item_level    = im.tran_level
                        and im.item_level    = 2)
         and loc = TO_NUMBER(I_loc);

      --Insert records into the ITEM_LOC_TRAITS table
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ITEM_LOC_TRAITS',
                       'ITEM: ' || I_item);
      --
      insert into item_loc_traits
         (item,
          loc,
          launch_date,
          qty_key_options,
          manual_price_entry,
          deposit_code,
          food_stamp_ind,
          wic_ind,
          proportional_tare_pct,
          fixed_tare_value,
          fixed_tare_uom,
          reward_eligible_ind,
          natl_brand_comp_item,
          return_policy,
          stop_sale_ind,
          elect_mtk_clubs,
          report_code,
          req_shelf_life_on_selection,
          req_shelf_life_on_receipt,
          ib_shelf_life,
          store_reorderable_ind,
          rack_size,
          full_pallet_item,
          in_store_market_basket,
          storage_location,
          alt_storage_location,
          returnable_ind,
          refundable_ind,
          back_order_ind,
          create_datetime,
          last_update_datetime,
          last_update_id)
         (select im.item,
                 ilt.loc,
                 ilt.launch_date,
                 ilt.qty_key_options,
                 ilt.manual_price_entry,
                 ilt.deposit_code,
                 ilt.food_stamp_ind,
                 ilt.wic_ind,
                 ilt.proportional_tare_pct,
                 ilt.fixed_tare_value,
                 ilt.fixed_tare_uom,
                 ilt.reward_eligible_ind,
                 ilt.natl_brand_comp_item,
                 ilt.return_policy,
                 ilt.stop_sale_ind,
                 ilt.elect_mtk_clubs,
                 ilt.report_code,
                 ilt.req_shelf_life_on_selection,
                 ilt.req_shelf_life_on_receipt,
                 ilt.ib_shelf_life,
                 ilt.store_reorderable_ind,
                 ilt.rack_size,
                 ilt.full_pallet_item,
                 ilt.in_store_market_basket,
                 ilt.storage_location,
                 ilt.alt_storage_location,
                 ilt.returnable_ind,
                 ilt.refundable_ind,
                 ilt.back_order_ind,
                 SYSDATE,
                 SYSDATE,
                 USER
            from item_loc_traits ilt,
                 item_master     im,
                 item_loc        il
           where ilt.item         = I_item
             and ilt.loc          = il.loc
             and ilt.item         = il.item
             and il.loc           = TO_NUMBER(I_loc)
             and im.tsl_base_item = ilt.item
             and im.tsl_base_item != im.item
             and im.item_level    = im.tran_level
             and im.item_level    = 2);
      --
      --Opening the cursor C_POS_MODS_INSERT_VARIANT
      SQL_LIB.SET_MARK('OPEN',
                       'C_POS_MODS_INSERT_VARIANT',
                       'ITEM_LOC,ITEM_MASTER',
                       'ITEM: ' || I_item);
      FOR C_rec in C_POS_MODS_INSERT_VARIANT
      LOOP
         --Executing the package function
         if NOT
             ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT(O_error_message             => O_error_message,
                                                 I_launch_date_upd           => I_launch_date_upd,
                                                 I_launch_date               => I_launch_date,
                                                 I_qty_key_options_upd       => I_qty_key_options_upd,
                                                 I_qty_key_options           => I_qty_key_options,
                                                 I_manual_price_entry_upd    => I_manual_price_entry_upd,
                                                 I_manual_price_entry        => I_manual_price_entry,
                                                 I_deposit_code_upd          => I_deposit_code_upd,
                                                 I_deposit_code              => I_deposit_code,
                                                 I_food_stamp_ind_upd        => I_food_stamp_ind_upd,
                                                 I_food_stamp_ind            => I_food_stamp_ind,
                                                 I_wic_ind_upd               => I_wic_ind_upd,
                                                 I_wic_ind                   => I_wic_ind,
                                                 I_proportional_tare_pct_upd => I_proportional_tare_pct_upd,
                                                 I_proportional_tare_pct     => I_proportional_tare_pct,
                                                 I_fixed_tare_value_upd      => I_fixed_tare_value_upd,
                                                 I_fixed_tare_value          => I_fixed_tare_value,
                                                 I_fixed_tare_uom_upd        => I_fixed_tare_uom_upd,
                                                 I_fixed_tare_uom            => I_fixed_tare_uom,
                                                 I_reward_eligible_ind_upd   => I_reward_eligible_ind_upd,
                                                 I_reward_eligible_ind       => I_reward_eligible_ind,
                                                 I_elect_mtk_clubs_upd       => I_elect_mtk_clubs_upd,
                                                 I_elect_mtk_clubs           => I_elect_mtk_clubs,
                                                 I_return_policy_upd         => I_return_policy_upd,
                                                 I_return_policy             => I_return_policy,
                                                 I_stop_sale_ind_upd         => I_stop_sale_ind_upd,
                                                 I_stop_sale_ind             => I_stop_sale_ind,
                                                 I_returnable_ind_upd        => I_returnable_ind_upd,
                                                 I_returnable_ind            => I_returnable_ind,
                                                 I_refundable_ind_upd        => I_refundable_ind_upd,
                                                 I_refundable_ind            => I_refundable_ind,
                                                 I_back_order_ind_upd        => I_back_order_ind_upd,
                                                 I_back_order_ind            => I_back_order_ind,
                                                 I_item                      => C_rec.item,
                                                 I_loc                       => C_rec.loc) then
            return FALSE;
         end if;
         --
      END LOOP;
      --
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               NULL);
         return FALSE;
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_COPY_BASE_SINGLE_LOC;
   ---------------------------------------------------------------------------------------------------------------
   --TSL_COPY_BASE_MULTI_LOC This function will default identical item/location trait records down to the Variant
   -- Items for the inputted base item and location. The defaulting will go down as far as the transaction level.
   ---------------------------------------------------------------------------------------------------------------
   FUNCTION TSL_COPY_BASE_MULTI_LOC(O_error_message             IN OUT VARCHAR2,
                                    I_launch_date_upd           IN     BOOLEAN,
                                    I_launch_date               IN     POS_MODS.LAUNCH_DATE%TYPE,
                                    I_qty_key_options_upd       IN     BOOLEAN,
                                    I_qty_key_options           IN     POS_MODS.QTY_KEY_OPTIONS%TYPE,
                                    I_manual_price_entry_upd    IN     BOOLEAN,
                                    I_manual_price_entry        IN     POS_MODS.MANUAL_PRICE_ENTRY%TYPE,
                                    I_deposit_code_upd          IN     BOOLEAN,
                                    I_deposit_code              IN     POS_MODS.DEPOSIT_CODE%TYPE,
                                    I_food_stamp_ind_upd        IN     BOOLEAN,
                                    I_food_stamp_ind            IN     POS_MODS.FOOD_STAMP_IND%TYPE,
                                    I_wic_ind_upd               IN     BOOLEAN,
                                    I_wic_ind                   IN     POS_MODS.WIC_IND%TYPE,
                                    I_proportional_tare_pct_upd IN     BOOLEAN,
                                    I_proportional_tare_pct     IN     POS_MODS.PROPORTIONAL_TARE_PCT%TYPE,
                                    I_fixed_tare_value_upd      IN     BOOLEAN,
                                    I_fixed_tare_value          IN     POS_MODS.FIXED_TARE_VALUE%TYPE,
                                    I_fixed_tare_uom_upd        IN     BOOLEAN,
                                    I_fixed_tare_uom            IN     POS_MODS.FIXED_TARE_UOM%TYPE,
                                    I_reward_eligible_ind_upd   IN     BOOLEAN,
                                    I_reward_eligible_ind       IN     POS_MODS.REWARD_ELIGIBLE_IND%TYPE,
                                    I_elect_mtk_clubs_upd       IN     BOOLEAN,
                                    I_elect_mtk_clubs           IN     POS_MODS.ELECT_MTK_CLUBS%TYPE,
                                    I_return_policy_upd         IN     BOOLEAN,
                                    I_return_policy             IN     POS_MODS.RETURN_POLICY%TYPE,
                                    I_stop_sale_ind_upd         IN     BOOLEAN,
                                    I_stop_sale_ind             IN     POS_MODS.STOP_SALE_IND%TYPE,
                                    I_returnable_ind_upd        IN     BOOLEAN,
                                    I_returnable_ind            IN     POS_MODS.RETURNABLE_IND%TYPE,
                                    I_refundable_ind_upd        IN     BOOLEAN,
                                    I_refundable_ind            IN     POS_MODS.REFUNDABLE_IND%TYPE,
                                    I_back_order_ind_upd        IN     BOOLEAN,
                                    I_back_order_ind            IN     POS_MODS.BACK_ORDER_IND%TYPE,
                                    I_item                      IN     ITEM_MASTER.ITEM%TYPE
                                    )
      return BOOLEAN is

      L_program VARCHAR2(64) := 'ITEM_LOC_TRAITS_SQL.TSL_COPY_BASE_MULTI_LOC';
      L_table   VARCHAR2(65) := 'ITEM_LOC_TRAITS';
      RECORD_LOCKED EXCEPTION;
      PRAGMA EXCEPTION_INIT(RECORD_LOCKED,
                            -54);
      --This cursor will lock the variant/loc information on the table ITEM_LOC_TRAITS table
      cursor C_LOCK_VARIANT_LOC_TRAITS is
         select 'x'
           from item_loc_traits ilt
          where exists (select im.item
                          from item_master im
                         where ilt.item         = im.item
                           and im.tsl_base_item = I_item
                           and im.tsl_base_item != im.item
                           and im.item_level    = im.tran_level
                           and im.item_level    = 2)
            and exists (select m.location
                          from mc_location_temp m
                         where ilt.loc = m.location)
            for update nowait;
      --This cursor will return all the Variant Items associated to a given location.
      cursor C_POS_MODS_INSERT_VARIANT is
         select im.item,
                ilt.loc
           from item_master      im,
                item_loc_traits  ilt,
                mc_location_temp mlt
          where im.tsl_base_item = I_item
            and im.tsl_base_item != im.item
            and im.item_level    = im.tran_level
            and im.item_level    = 2
            and im.status        = 'A'
            and ilt.item         = im.item
            and mlt.loc_type     = 'S'
            and mlt.location     = ilt.loc
            and exists (select 'X'
                          from item_loc il
                         where il.item = im.item
                           and il.loc  = ilt.loc);
   BEGIN
      --Checking whether I_item is null
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                               'I_item',
                                               L_program,
                                               NULL);
         return FALSE;
      end if;
      --Opening the cursor C_LOCK_VARIANT_LOC_TRAITS
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_VARIANT_LOC_TRAITS',
                       'ITEM_LOC_TRAITS',
                       'ITEM: ' || I_item);
      open C_LOCK_VARIANT_LOC_TRAITS;
      --Closing the cursor C_LOCK_VARIANT_LOC_TRAITS
      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_VARIANT_LOC_TRAITS',
                       'ITEM_LOC_TRAITS',
                       'ITEM: ' || I_item);
      close C_LOCK_VARIANT_LOC_TRAITS;
      --
      --Delete records from the ITEM_LOC_TRAITS table
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'ITEM_LOC_TRAITS',
                       'ITEM: ' || I_item);
      --
      delete from item_loc_traits ilt
       where exists (select 'x'
                       from item_master im
                      where im.item          = ilt.item
                        and im.tsl_base_item = I_item
                        and im.tsl_base_item != im.item
                        and im.item_level    = im.tran_level
                        and im.item_level    = 2)
         and exists (select 'x'
                       from mc_location_temp m
                      where m.location = ilt.loc);

      --Insert records into the ITEM_LOC_TRAITS table
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ITEM_LOC_TRAITS',
                       'ITEM: ' || I_item);
      --
      insert into item_loc_traits
         (item,
          loc,
          launch_date,
          qty_key_options,
          manual_price_entry,
          deposit_code,
          food_stamp_ind,
          wic_ind,
          proportional_tare_pct,
          fixed_tare_value,
          fixed_tare_uom,
          reward_eligible_ind,
          natl_brand_comp_item,
          return_policy,
          stop_sale_ind,
          elect_mtk_clubs,
          report_code,
          req_shelf_life_on_selection,
          req_shelf_life_on_receipt,
          ib_shelf_life,
          store_reorderable_ind,
          rack_size,
          full_pallet_item,
          in_store_market_basket,
          storage_location,
          alt_storage_location,
          returnable_ind,
          refundable_ind,
          back_order_ind,
          create_datetime,
          last_update_datetime,
          last_update_id)
         (select im.item,
                 ilt.loc,
                 ilt.launch_date,
                 ilt.qty_key_options,
                 ilt.manual_price_entry,
                 ilt.deposit_code,
                 ilt.food_stamp_ind,
                 ilt.wic_ind,
                 ilt.proportional_tare_pct,
                 ilt.fixed_tare_value,
                 ilt.fixed_tare_uom,
                 ilt.reward_eligible_ind,
                 ilt.natl_brand_comp_item,
                 ilt.return_policy,
                 ilt.stop_sale_ind,
                 ilt.elect_mtk_clubs,
                 ilt.report_code,
                 ilt.req_shelf_life_on_selection,
                 ilt.req_shelf_life_on_receipt,
                 ilt.ib_shelf_life,
                 ilt.store_reorderable_ind,
                 ilt.rack_size,
                 ilt.full_pallet_item,
                 ilt.in_store_market_basket,
                 ilt.storage_location,
                 ilt.alt_storage_location,
                 ilt.returnable_ind,
                 ilt.refundable_ind,
                 ilt.back_order_ind,
                 SYSDATE,
                 SYSDATE,
                 USER
            from item_loc_traits  ilt,
                 item_master      im,
                 item_loc         il,
                 mc_location_temp mlt
           where ilt.item         = I_item
             and ilt.loc          = il.loc
             and im.item          = il.item
             and im.tsl_base_item = ilt.item
             and im.tsl_base_item != im.item
             and im.item_level    = im.tran_level
             and im.item_level    = 2
             and mlt.location     = ilt.loc);
      --
      FOR C_rec in C_POS_MODS_INSERT_VARIANT
      LOOP
         --Executing the package function
         if NOT
             ITEM_LOC_TRAITS_SQL.POS_MODS_INSERT(O_error_message             => O_error_message,
                                                 I_launch_date_upd           => I_launch_date_upd,
                                                 I_launch_date               => I_launch_date,
                                                 I_qty_key_options_upd       => I_qty_key_options_upd,
                                                 I_qty_key_options           => I_qty_key_options,
                                                 I_manual_price_entry_upd    => I_manual_price_entry_upd,
                                                 I_manual_price_entry        => I_manual_price_entry,
                                                 I_deposit_code_upd          => I_deposit_code_upd,
                                                 I_deposit_code              => I_deposit_code,
                                                 I_food_stamp_ind_upd        => I_food_stamp_ind_upd,
                                                 I_food_stamp_ind            => I_food_stamp_ind,
                                                 I_wic_ind_upd               => I_wic_ind_upd,
                                                 I_wic_ind                   => I_wic_ind,
                                                 I_proportional_tare_pct_upd => I_proportional_tare_pct_upd,
                                                 I_proportional_tare_pct     => I_proportional_tare_pct,
                                                 I_fixed_tare_value_upd      => I_fixed_tare_value_upd,
                                                 I_fixed_tare_value          => I_fixed_tare_value,
                                                 I_fixed_tare_uom_upd        => I_fixed_tare_uom_upd,
                                                 I_fixed_tare_uom            => I_fixed_tare_uom,
                                                 I_reward_eligible_ind_upd   => I_reward_eligible_ind_upd,
                                                 I_reward_eligible_ind       => I_reward_eligible_ind,
                                                 I_elect_mtk_clubs_upd       => I_elect_mtk_clubs_upd,
                                                 I_elect_mtk_clubs           => I_elect_mtk_clubs,
                                                 I_return_policy_upd         => I_return_policy_upd,
                                                 I_return_policy             => I_return_policy,
                                                 I_stop_sale_ind_upd         => I_stop_sale_ind_upd,
                                                 I_stop_sale_ind             => I_stop_sale_ind,
                                                 I_returnable_ind_upd        => I_returnable_ind_upd,
                                                 I_returnable_ind            => I_returnable_ind,
                                                 I_refundable_ind_upd        => I_refundable_ind_upd,
                                                 I_refundable_ind            => I_refundable_ind,
                                                 I_back_order_ind_upd        => I_back_order_ind_upd,
                                                 I_back_order_ind            => I_back_order_ind,
                                                 I_item                      => C_rec.item,
                                                 I_loc                       => C_rec.loc) then
            return FALSE;
         end if;
         --
      END LOOP;
      --
      ---
      return TRUE;
      ---
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               L_table,
                                               I_item,
                                               NULL);
         return FALSE;
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               TO_CHAR(SQLCODE));
         return FALSE;
   END TSL_COPY_BASE_MULTI_LOC;
   --12-Jul-2007 WiproEnabler/Karthik Dhanapal - MOD 365b   End
-----------------------------------------------------------------------------------------------------------------------
END;
/

