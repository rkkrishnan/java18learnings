CREATE OR REPLACE PACKAGE BODY GET_REPL_ORDER_QTY_SQL AS
   LP_item                              ITEM_MASTER.ITEM%TYPE;
   LP_locn_type                         tsfhead.to_loc_type%TYPE;
   LP_locn                              store.store%TYPE;
   LP_sub_item_loc                      sub_items_head.location%TYPE;
   LP_store_need                        NUMBER(20,4);
   LP_pres_stock                        repl_item_loc.pres_stock%TYPE;
   LP_demo_stock                        repl_item_loc.demo_stock%TYPE;
   LP_repl_method                       repl_item_loc.repl_method%TYPE;
   LP_min_stock                         repl_item_loc.min_stock%TYPE;
   LP_max_stock                         repl_item_loc.max_stock%TYPE;
   LP_incr_pct                          repl_item_loc.incr_pct%TYPE;
   LP_min_supply_days                   repl_item_loc.min_supply_days%TYPE;
   LP_max_supply_days                   repl_item_loc.max_supply_days%TYPE;
   LP_time_supply_horizon               repl_item_loc.time_supply_horizon%TYPE;
   LP_inv_selling_days                  repl_item_loc.inv_selling_days%TYPE;
   LP_service_level                     repl_item_loc.service_level%TYPE;
   LP_lost_sales_factor                 repl_results.lost_sales_factor%TYPE;
   LP_lost_sales                        repl_results.lost_sales%TYPE;
   LP_due_ind                           repl_results.due_ind%TYPE;
   LP_aso                               repl_results.accepted_stock_out%TYPE;
   LP_eso                               repl_results.estimated_stock_out%TYPE;
   LP_min_supply_days_forecast          repl_results.min_supply_days_forecast%TYPE;
   LP_max_supply_days_forecast          repl_results.max_supply_days_forecast%TYPE;
   LP_tsh_forecast                      repl_results.time_supply_horizon_forecast%TYPE;
   LP_curr_olt_forecast                 repl_results.order_lead_time_forecast%TYPE;
   LP_next_olt_forecast                 repl_results.next_lead_time_forecast%TYPE;
   LP_review_time_forecast              repl_results.review_time_forecast%TYPE;
   LP_isd_forecast                      repl_results.inv_sell_days_forecast%TYPE;
   LP_curr_order_lead_time              NUMBER;
   LP_next_order_lead_time              NUMBER;
   LP_review_lead_time                  NUMBER;
   LP_net_inventory                     repl_results.net_inventory%TYPE;
   LP_stock_on_hand                     repl_results.stock_on_hand%TYPE;
   LP_pack_comp_soh                     repl_results.pack_comp_soh%TYPE;
   LP_on_order                          repl_results.on_order%TYPE;
   LP_in_transit_qty                    repl_results.in_transit_qty%TYPE;
   LP_pack_comp_intran                  repl_results.pack_comp_intran%TYPE;
   LP_tsf_resv_qty                      repl_results.tsf_resv_qty%TYPE;
   LP_pack_comp_resv                    repl_results.pack_comp_resv%TYPE;
   LP_tsf_expected_qty                  repl_results.tsf_expected_qty%TYPE;
   LP_pack_comp_exp                     repl_results.pack_comp_exp%TYPE;
   LP_rtv_qty                           repl_results.rtv_qty%TYPE;
   LP_alloc_in_qty                      repl_results.alloc_in_qty%TYPE;
   LP_alloc_out_qty                     repl_results.alloc_out_qty%TYPE;
   LP_non_sellable_qty                  repl_results.non_sellable_qty%TYPE;
   LP_order_point                       repl_results.order_point%TYPE := 0;
   LP_order_up_to_point                 repl_results.order_up_to_point%TYPE;
   LP_safety_stock                      repl_results.safety_stock%TYPE;
   LP_roq                               NUMBER(20,4);
   LP_vdate                             period.vdate%TYPE                                  :=  Get_Vdate;
   LP_terminal_stock_qty                repl_item_loc.terminal_stock_qty%TYPE;
   LP_due_ord_serv_basis                sup_inv_mgmt.due_ord_serv_basis%TYPE;
   LP_unit_cost                         tran_data.total_cost%TYPE;
   LP_unit_retail                       tran_data.total_retail%TYPE;
   LP_due_ord_process_ind               sup_inv_mgmt.due_ord_process_ind%TYPE;
   LP_repl_results_all_ind              system_options.repl_results_all_ind%TYPE;
   LP_season_id                         repl_item_loc.season_id%TYPE;
   LP_phase_id                          repl_item_loc.phase_id%TYPE;
   LP_phase_start                       phases.start_date%TYPE;
   LP_phase_end                         phases.end_date%TYPE;
   LP_net_inventory_lost_sales          repl_results.stock_on_hand%TYPE                    := NULL;
   LP_sub_inv_ind                       sub_items_head.use_stock_ind%TYPE                  := NULL;
   LP_sub_fore_ind                      sub_items_head.use_forecast_sales_ind%TYPE         := NULL;
   LP_reject_store_ord_ind              repl_item_loc.reject_store_ord_ind%TYPE;
   LP_store_order_roq                   NUMBER(20,4);
   LP_store_order_due_ind               repl_results.due_ind%TYPE;
   LP_srvce_lvl_type_simple_sales       CONSTANT   REPL_ITEM_LOC.SERVICE_LEVEL_TYPE%TYPE   := 'SS';

   TYPE safety_stock_type is record(
      safety_stock_std_dev NUMBER(12,4),
      exp_units_short      NUMBER(12,4));

   TYPE safety_stock_table_type is table of safety_stock_type
      index by binary_integer;

   LP_safety      safety_stock_table_type;
   LP_first       NUMBER := 0;

-------------------------------------------------------------------------
FUNCTION GET_NET_INVENTORY (O_error_message    IN OUT VARCHAR2,
                            O_net_inventory    IN OUT repl_results.stock_on_hand%TYPE)
RETURN BOOLEAN IS

   L_date                     period.vdate%TYPE               := NULL;
   L_avail                    NUMBER(20,4)                    := NULL;
   L_total_avail              NUMBER(20,4)                    := 0;
   L_soh                      repl_results.stock_on_hand%TYPE := 0;
   L_total_soh                repl_results.stock_on_hand%TYPE := 0;
   L_pack_comp_soh            repl_results.stock_on_hand%TYPE := 0;
   L_total_pack_comp_soh      repl_results.stock_on_hand%TYPE := 0;
   L_in_transit               repl_results.stock_on_hand%TYPE := 0;
   L_total_in_transit         repl_results.stock_on_hand%TYPE := 0;
   L_pack_comp_intran         repl_results.stock_on_hand%TYPE := 0;
   L_total_pack_comp_intran   repl_results.stock_on_hand%TYPE := 0;
   L_expected                 repl_results.stock_on_hand%TYPE := 0;
   L_total_expected           repl_results.stock_on_hand%TYPE := 0;
   L_pack_comp_exp            repl_results.stock_on_hand%TYPE := 0;
   L_total_pack_comp_exp      repl_results.stock_on_hand%TYPE := 0;
   L_on_order                 repl_results.stock_on_hand%TYPE := 0;
   L_total_on_order           repl_results.stock_on_hand%TYPE := 0;
   L_alloc_in                 repl_results.stock_on_hand%TYPE := 0;
   L_total_alloc_in           repl_results.stock_on_hand%TYPE := 0;
   L_rtv                      repl_results.stock_on_hand%TYPE := 0;
   L_total_rtv                repl_results.stock_on_hand%TYPE := 0;
   L_alloc_out                repl_results.stock_on_hand%TYPE := 0;
   L_total_alloc_out          repl_results.stock_on_hand%TYPE := 0;
   L_reserved                 repl_results.stock_on_hand%TYPE := 0;
   L_total_reserved           repl_results.stock_on_hand%TYPE := 0;
   L_pack_comp_resv           repl_results.stock_on_hand%TYPE := 0;
   L_total_pack_comp_resv     repl_results.stock_on_hand%TYPE := 0;
   L_non_sellable_qty         repl_results.stock_on_hand%TYPE := 0;
   L_total_non_sellable_qty   repl_results.stock_on_hand%TYPE := 0;


   L_sub_item                 sub_items_detail.sub_item%TYPE  := NULL;

   cursor C_SUB_ITEMS is
      select sid.sub_item
        from sub_items_detail sid,
             sub_items_head sih
       where sih.item          = sid.item
         and sih.location      = sid.location
         and sid.item          = LP_item
         and sid.location      = LP_sub_item_loc
         and sih.use_stock_ind = 'Y';

   cursor C_REPL_WH_LINK is
      select wh
        from wh
       where repl_wh_link = LP_locn;

BEGIN

   /* get the date to pass into the ITEMLOC_QUANTITY_SQL function */
   if LP_repl_method in ('C','M','F','D','DI') then
      L_date := LP_vdate + LP_next_order_lead_time + LP_review_lead_time;
   else
      L_date := LP_vdate + LP_min_supply_days;
   end if;

   if LP_locn_type = 'S' then
       if NOT ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL(O_error_message,
                                                        L_avail,
                                                        L_soh,
                                                        L_pack_comp_soh,
                                                        L_in_transit,
                                                        L_pack_comp_intran,
                                                        L_expected,
                                                        L_pack_comp_exp,
                                                        L_on_order,
                                                        L_alloc_in,
                                                        L_rtv,
                                                        L_alloc_out,
                                                        L_reserved,
                                                        L_pack_comp_resv,
                                                        L_non_sellable_qty,
                                                        LP_item,
                                                        LP_locn,
                                                        LP_locn_type,
                                                        L_date,
                                                        'N',
                                                        LP_order_point,
                                                        'R') then
         return FALSE;
      end if;
      L_total_avail            := L_avail;
      L_total_soh              := NVL(L_soh,0);
      L_total_in_transit       := NVL(L_in_transit,0);
      L_total_expected         := NVL(L_expected,0);
      L_total_on_order         := NVL(L_on_order,0);
      L_total_alloc_in         := NVL(L_alloc_in,0);
      L_total_rtv              := NVL(L_rtv,0);
      L_total_non_sellable_qty := NVL(L_non_sellable_qty,0);
      L_total_reserved         := NVL(L_reserved,0);

      if LP_sub_inv_ind = 'Y' then

         SQL_LIB.SET_MARK('OPEN','C_SUB_ITEMS','SUB_ITEMS_DETAIL',
                          'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
         open C_SUB_ITEMS;
         LOOP
            SQL_LIB.SET_MARK('FETCH','C_SUB_ITEMS','SUB_ITEMS_DETAIL',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
            fetch C_SUB_ITEMS into L_sub_item;
            if C_SUB_ITEMS%NOTFOUND then
               Exit;
            else
                if NOT ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL(O_error_message,
                                                                 L_avail,
                                                                 L_soh,
                                                                 L_pack_comp_soh,
                                                                 L_in_transit,
                                                                 L_pack_comp_intran,
                                                                 L_expected,
                                                                 L_pack_comp_exp,
                                                                 L_on_order,
                                                                 L_alloc_in,
                                                                 L_rtv,
                                                                 L_alloc_out,
                                                                 L_reserved,
                                                                 L_pack_comp_resv,
                                                                 L_non_sellable_qty,
                                                                 L_sub_item,
                                                                 LP_locn,
                                                                 LP_locn_type,
                                                                 L_date,
                                                                 'N',
                                                                 LP_order_point,
                                                                 'R') then
                  return FALSE;
               end if;
            end if;
            L_total_avail            := L_total_avail            + NVL(L_avail,0);
            L_total_soh              := L_total_soh              + NVL(L_soh,0);
            L_total_in_transit       := L_total_in_transit       + NVL(L_in_transit,0);
            L_total_expected         := L_total_expected         + NVL(L_expected,0);
            L_total_on_order         := L_total_on_order         + NVL(L_on_order,0);
            L_total_alloc_in         := L_total_alloc_in         + NVL(L_alloc_in,0);
            L_total_rtv              := L_total_rtv              + NVL(L_rtv,0);
            L_total_non_sellable_qty := L_total_non_sellable_qty + NVL(L_non_sellable_qty,0);
            L_total_reserved         := L_total_reserved         + NVL(L_reserved,0);
         END LOOP;

         SQL_LIB.SET_MARK('CLOSE','C_SUB_ITEMS','SUB_ITEMS_DETAIL',
                          'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
         close C_SUB_ITEMS;
      end if;

   elsif LP_locn_type = 'W' then
      /* Loop through all linked warehouses */
      for c_rec in C_REPL_WH_LINK LOOP
         if NOT ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL(O_error_message,
                                                          L_avail,
                                                          L_soh,
                                                          L_pack_comp_soh,
                                                          L_in_transit,
                                                          L_pack_comp_intran,
                                                          L_expected,
                                                          L_pack_comp_exp,
                                                          L_on_order,
                                                          L_alloc_in,
                                                          L_rtv,
                                                          L_alloc_out,
                                                          L_reserved,
                                                          L_pack_comp_resv,
                                                          L_non_sellable_qty,
                                                          LP_item,
                                                          c_rec.wh,
                                                          LP_locn_type,
                                                          L_date,
                                                          'N',
                                                          LP_order_point,
                                                          'R') then
            return FALSE;
         end if;
         L_total_avail            := L_total_avail              + L_avail;
         L_total_soh              := L_total_soh                + NVL(L_soh,0);
         L_total_pack_comp_soh    := L_total_pack_comp_soh      + NVL(L_pack_comp_soh,0);
         L_total_in_transit       := L_total_in_transit         + NVL(L_in_transit,0);
         L_total_pack_comp_intran := L_total_pack_comp_intran   + NVL(L_pack_comp_intran,0);
         L_total_expected         := L_total_expected           + NVL(L_expected,0);
         L_total_pack_comp_exp    := L_total_pack_comp_exp      + NVL(L_pack_comp_exp,0);
         L_total_on_order         := L_total_on_order           + NVL(L_on_order,0);
         L_total_alloc_in         := L_total_alloc_in           + NVL(L_alloc_in,0);
         L_total_rtv              := L_total_rtv                + NVL(L_rtv,0);
         L_total_alloc_out        := L_total_alloc_out          + NVL(L_alloc_out,0);
         L_total_reserved         := L_total_reserved           + NVL(L_reserved,0);
         L_total_pack_comp_resv   := L_total_pack_comp_resv     + NVL(L_pack_comp_resv,0);
         L_total_non_sellable_qty := L_total_non_sellable_qty   + NVL(L_non_sellable_qty,0);
      end LOOP;
      ---
      if LP_sub_inv_ind = 'Y' then

         SQL_LIB.SET_MARK('OPEN','C_SUB_ITEMS','SUB_ITEMS_DETAIL',
                          'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
         open C_SUB_ITEMS;
         LOOP
            SQL_LIB.SET_MARK('FETCH','C_SUB_ITEMS','SUB_ITEMS_DETAIL',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
            fetch C_SUB_ITEMS into L_sub_item;
            if C_SUB_ITEMS%NOTFOUND then
               Exit;
            else
               /* Loop through all linked warehouses */
               for c_rec in C_REPL_WH_LINK LOOP
                  if NOT ITEMLOC_QUANTITY_SQL.GET_LOC_FUTURE_AVAIL(O_error_message,
                                                                   L_avail,
                                                                   L_soh,
                                                                   L_pack_comp_soh,
                                                                   L_in_transit,
                                                                   L_pack_comp_intran,
                                                                   L_expected,
                                                                   L_pack_comp_exp,
                                                                   L_on_order,
                                                                   L_alloc_in,
                                                                   L_rtv,
                                                                   L_alloc_out,
                                                                   L_reserved,
                                                                   L_pack_comp_resv,
                                                                   L_non_sellable_qty,
                                                                   L_sub_item,
                                                                   c_rec.wh,
                                                                   LP_locn_type,
                                                                   L_date,
                                                                  'N',
                                                                  LP_order_point,
                                                                  'R') then
                     return FALSE;
                  end if;
                  ---
                  L_total_avail            := L_total_avail            + NVL(L_avail,0);
                  L_total_soh              := L_total_soh              + NVL(L_soh,0);
                  L_total_pack_comp_soh    := L_total_pack_comp_soh    + NVL(L_pack_comp_soh,0);
                  L_total_in_transit       := L_total_in_transit       + NVL(L_in_transit,0);
                  L_total_pack_comp_intran := L_total_pack_comp_intran + NVL(L_pack_comp_intran,0);
                  L_total_expected         := L_total_expected         + NVL(L_expected,0);
                  L_total_pack_comp_exp    := L_total_pack_comp_exp    + NVL(L_pack_comp_exp,0);
                  L_total_on_order         := L_total_on_order         + NVL(L_on_order,0);
                  L_total_alloc_in         := L_total_alloc_in         + NVL(L_alloc_in,0);
                  L_total_rtv              := L_total_rtv              + NVL(L_rtv,0);
                  L_total_alloc_out        := L_total_alloc_out        + NVL(L_alloc_out,0);
                  L_total_reserved         := L_total_reserved         + NVL(L_reserved,0);
                  L_total_pack_comp_resv   := L_total_pack_comp_resv   + NVL(L_pack_comp_resv,0);
                  L_total_non_sellable_qty := L_total_non_sellable_qty + NVL(L_non_sellable_qty,0);
               end LOOP;
            end if;
         end LOOP;

         SQL_LIB.SET_MARK('CLOSE','C_SUB_ITEMS','SUB_ITEMS_DETAIL',
                          'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
         close C_SUB_ITEMS;
      end if;
   end if;

   O_net_inventory     := GREATEST((L_total_avail - LP_demo_stock),0);
   LP_stock_on_hand    := L_total_soh;
   LP_pack_comp_soh    := L_total_pack_comp_soh;
   LP_in_transit_qty   := L_total_in_transit;
   LP_pack_comp_intran := L_total_pack_comp_intran;
   LP_tsf_expected_qty := L_total_expected;
   LP_pack_comp_exp    := L_total_pack_comp_exp;
   LP_on_order         := L_total_on_order;
   LP_alloc_in_qty     := L_total_alloc_in;
   LP_rtv_qty          := L_total_rtv;
   LP_alloc_out_qty    := L_total_alloc_out;
   LP_tsf_resv_qty     := L_total_reserved;
   LP_pack_comp_resv   := L_total_pack_comp_resv;
   LP_non_sellable_qty := L_total_non_sellable_qty;

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.GET_NET_INVENTORY',
                                         to_char(SQLCODE));
   return FALSE;
END GET_NET_INVENTORY;
-------------------------------------------------------------------------
FUNCTION GET_FORECAST_FOR_PERIOD (O_error_message    IN OUT   VARCHAR2,
                                  O_forecast         IN OUT   item_forecast.forecast_sales%TYPE,
                                  I_loc              IN       item_forecast.loc%TYPE,
                                  I_first_date       IN       period.vdate%TYPE,
                                  I_item             IN       item_master.item%TYPE,
                                  I_domain_id        IN       domain.domain_id%TYPE,
                                  I_last_date        IN       period.vdate%TYPE,
                                  I_days_of_period   IN       repl_item_loc.wh_lead_time%TYPE)
RETURN BOOLEAN IS


   L_last_eow_date         item_forecast.eow_date%TYPE               := NULL;
   L_eow_date              item_forecast.eow_date%TYPE               := NULL;
   L_increment             number(5)                                 := NULL;
   L_forecast_sales        NUMBER(20,4)                              := NULL;
   L_first_week_forecast   item_forecast.forecast_sales%TYPE         := NULL;
   L_last_week_forecast    item_forecast.forecast_sales%TYPE         := NULL;
   L_total_forecast        NUMBER(20,4)                              := NULL;
   L_temp_sales            item_forecast.forecast_sales%TYPE         := NULL;
   L_in_day                NUMBER(2)                                 := NULL;
   L_in_month              NUMBER(2)                                 := NULL;
   L_in_year               NUMBER(4)                                 := NULL;
   L_out_day               NUMBER(2)                                 := NULL;
   L_out_week              NUMBER(2)                                 := NULL;
   L_out_month             NUMBER(2)                                 := NULL;
   L_out_year              NUMBER(4)                                 := NULL;
   L_return_code           VARCHAR2(5)                               := NULL;
   L_error_message         VARCHAR2(255)                             := NULL;
   L_first_date            period.vdate%TYPE                         := I_first_date;
   L_days_of_period        repl_item_loc.wh_lead_time%TYPE           := I_days_of_period;
   L_daily_forecast        daily_item_forecast.forecast_sales%TYPE   := NULL;
   L_max_daily_date        daily_item_forecast.data_date%TYPE        := NULL;

   cursor C_ITEM_FORECAST is
      select NVL(ifc.forecast_sales,0),
             ifc.eow_date
        from item_forecast ifc
       where ifc.loc       = I_loc
         and ifc.item      = I_item
         and ifc.domain_id = I_domain_id
         and ifc.eow_date BETWEEN L_first_date and L_last_eow_date
       order by ifc.eow_date asc;

   cursor C_DAILY_ITEM_FORECAST is
      select SUM(NVL(forecast_sales,0)),
             MAX(data_date)
        from daily_item_forecast
       where loc        = I_loc
         and item       = I_item
         and domain_id  = I_domain_id
         and data_date > L_first_date
         and data_date <= I_last_date;

BEGIN

   /* get the daily forecast sales and the max available date for daily data */
   SQL_LIB.SET_MARK('OPEN','C_DAILY_ITEM_FORECAST','DAILY_ITEM_FORECAST',
                    'ITEM: '||I_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   open C_DAILY_ITEM_FORECAST;

   SQL_LIB.SET_MARK('FETCH','C_DAILY_ITEM_FORECAST','DAILY_ITEM_FORECAST',
                    'ITEM: '||I_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   fetch C_DAILY_ITEM_FORECAST into L_daily_forecast,
                                    L_max_daily_date;

   SQL_LIB.SET_MARK('CLOSE','C_DAILY_ITEM_FORECAST','DAILY_ITEM_FORECAST',
                    'ITEM: '||I_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   close C_DAILY_ITEM_FORECAST;

   /* job is done if daily data covers it all */
   if L_max_daily_date = I_last_date then
      O_forecast := L_daily_forecast;
      return TRUE;
   /* adjust the first date and days of period to get weekly forecasts for the remaining perid */
   elsif L_max_daily_date < I_last_date then
      L_first_date     := L_max_daily_date;
      L_days_of_period := I_last_date - L_first_date;
   /* set daily forecast to 0 if no daily forecast exists */
   elsif L_max_daily_date is NULL then
      L_daily_forecast := 0;
   end if;

   /* retrieve the 454 day for I_last_date, this is used to get L_last_eow_date */

   if NOT DATES_SQL.GET_EOW_DATE(L_error_message,
                                 L_last_eow_date,
                                 I_last_date) then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_ITEM_FORECAST','ITEM_FORECAST',
                    'ITEM: '||I_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   open C_ITEM_FORECAST;

   L_temp_sales     := 0;
   L_forecast_sales := 0;
   L_total_forecast := 0;
   L_increment      := 0;
   LOOP
      SQL_LIB.SET_MARK('FETCH','C_ITEM_FORECAST','ITEM_FORECAST',
                       'ITEM: '||I_item||
                       ' LOC: '||to_char(I_loc)||
                       ' DOMAIN: '||to_char(I_domain_id));
      fetch C_ITEM_FORECAST into L_forecast_sales,
                                 L_eow_date;
      if C_ITEM_FORECAST%NOTFOUND then
         if L_last_eow_date - L_eow_date >= 7 then
            EXIT;
         else
            if L_increment = 0 then
               --- No forecast history.
               L_total_forecast := 0;
            elsif L_increment = 1 then
               --- This is if the start and end date are within the first week
               --- and prorating is needed.
               if I_last_date - L_first_date < 7 then
                  --- checks if the forecast period exists partially over one
                  --- week and partially over another, in which case only use
                  --- the days from the second week to calculate the total
                  --- forecast for the week.
                  if L_eow_date - 7 < I_last_date
                     and L_eow_date - 7 > L_first_date then
                     L_total_forecast := ((L_temp_sales /7)
                                         * (I_last_date - (L_eow_date - 7)));
                  else
                     L_total_forecast := ((L_temp_sales / 7)
                                        * (I_last_date - L_first_date));
                  end if;

               --- the following code will be performed if only one history
               --- record is returned for a forecasting period that is greater
               --- than 1 week.
               else
                  --- if the last date of the period is within a week of the
                  --- last record returned from the hist table, prorate the
                  --- last week.
                  if L_eow_date - I_last_date < 7 and
                     L_eow_date - I_last_date > 0 then
                     L_total_forecast := (L_temp_sales /7)
                                         * (7 - (L_eow_date - I_last_date));
                  end if;
               end if;
            elsif L_increment > 1 then
               --- calculate the prorated forecast for the last week.
               if L_eow_date - I_last_date < 7 and
                  L_eow_date - I_last_date > 0 then
                  --- if the last week, check if prorating is needed subtract
                  --- out the last week, since it will be recalculated.
                  L_total_forecast     := L_total_forecast - L_temp_sales;

                  L_last_week_forecast := (L_temp_sales / 7)
                                          * (7 - (L_eow_date - I_last_date));
               else
                  L_last_week_forecast := 0;
               end if;

               --- add the prorated last week into the total forecast.
               L_total_forecast := L_total_forecast + L_last_week_forecast;
            end if;
            exit;
         end if;
      else -- forecast found
         --- Increment forecast week counter
         L_increment := L_increment + 1;

         --- If the first week, check if prorating is needed.
         if L_increment = 1 and (L_eow_date - L_first_date) < 7 then
            L_first_week_forecast := (L_forecast_sales / 7)
                                     * (L_eow_date - L_first_date);
            L_total_forecast      := L_first_week_forecast;
         else
            --- Add the weekly forecast sales to the total.
            L_total_forecast      := L_total_forecast + L_forecast_sales;
         end if;

         --- Put the current forecasted sales into temp variables in case
         --- they are prorated for the last week.
         L_temp_sales := L_forecast_sales;
      end if;
   END LOOP;

   SQL_LIB.SET_MARK('CLOSE','C_ITEM_FORECAST','ITEM_FORECAST',
                    'ITEM: '||I_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   close C_ITEM_FORECAST;

   /* sum up the total weekly forecast sales and the daily forecast sales as the output */
   O_forecast := L_total_forecast + L_daily_forecast;

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.GET_FORECAST_FOR_PERIOD',
                                         to_char(SQLCODE));
   return FALSE;
END GET_FORECAST_FOR_PERIOD;
-------------------------------------------------------------------------
FUNCTION CALCULATE_FORECAST_FOR_PERIOD (O_error_message    IN OUT   VARCHAR2,
                                        O_forecast         IN OUT   item_forecast.forecast_sales%TYPE,
                                        I_loc              IN       item_forecast.loc%TYPE,
                                        I_first_date       IN       period.vdate%TYPE,
                                        I_item             IN       item_master.item%TYPE,
                                        I_domain_id        IN       domain.domain_id%TYPE,
                                        I_last_date        IN       period.vdate%TYPE,
                                        I_days_of_period   IN       repl_item_loc.wh_lead_time%TYPE)
RETURN BOOLEAN IS

   L_total_forecast   item_forecast.forecast_sales%TYPE   := 0;
   L_wh_forecast      item_forecast.forecast_sales%TYPE   := 0;

   cursor C_REPL_WH_LINK is
      select wh
        from wh
       where repl_wh_link = I_loc
       order by wh;

BEGIN

   /* If the location is a store then,
     I_loc is the location the forecasts are being gathered for.
     Otherwise, if the location is a warehouse,
     we loop through all linked virtual warehouses and gather forecasts.
     I_first_date is the beginning date of the forecasting period.
     I_last_date is the last date of the forecasting period.
     I_days_of_period is the number of days in the forecasting period.
     L_eow_date is the current eow_date returned from the hist table in the period.
     O_forecast is the forecasting units returned for the forecasting period.
    */

   if LP_locn_type = 'W' then
      for c_rec in C_REPL_WH_LINK LOOP
         if NOT GET_FORECAST_FOR_PERIOD (O_error_message,
                                         L_wh_forecast,
                                         c_rec.wh,
                                         I_first_date,
                                         I_item,
                                         I_domain_id,
                                         I_last_date,
                                         I_days_of_period) then

            return FALSE;
         end if;
         /* Summed up total forecast returned by all the linked warehouses */
         L_total_forecast := NVL(L_wh_forecast, 0) + L_total_forecast;
      end LOOP;
   else
      if NOT GET_FORECAST_FOR_PERIOD (O_error_message,
                                      L_total_forecast,
                                      I_loc,
                                      I_first_date,
                                      I_item,
                                      I_domain_id,
                                      I_last_date,
                                      I_days_of_period) then

          return FALSE;
       end if;
   end if;

   O_forecast := NVL(L_total_forecast, 0);

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.CALCULATE_FORECAST_FOR_PERIOD',
                                         to_char(SQLCODE));
   return FALSE;
END CALCULATE_FORECAST_FOR_PERIOD;
----------------------------------------------------------------------------------------
FUNCTION GET_LOCN_NEED_CONSTANT (O_error_message   IN OUT   VARCHAR2)
RETURN BOOLEAN IS


BEGIN

   /* calculate the order point */
   LP_order_point := GREATEST(LEAST(LP_max_stock * LP_incr_pct/100,
                                    99999999.9999),LP_pres_stock);
   ---
   LP_order_up_to_point := LP_order_point;

   /* if the order point is less than the net inv, the item/loc is not due */
   if LP_order_point <= LP_net_inventory then
      LP_due_ind := 'N';
   else
      LP_due_ind := 'Y';
   end if;

   LP_roq := (LP_order_point - LP_net_inventory);

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.GET_LOCN_NEED_CONSTANT',
                                         to_char(SQLCODE));
   return FALSE;
END GET_LOCN_NEED_CONSTANT;
-------------------------------------------------------------------------
FUNCTION GET_LOCN_NEED_MIN_MAX (O_error_message    IN OUT   VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   /* calculate the order point */
   LP_order_point := GREATEST(LEAST(LP_min_stock * LP_incr_pct/100,
                                    99999999.9999),LP_pres_stock);

   LP_order_up_to_point := GREATEST(LEAST(LP_max_stock * LP_incr_pct/100,
                                          99999999.9999),LP_pres_stock);

   /* if the order point is less than the net inv, the item/loc is not due */
   if LP_order_point <= LP_net_inventory then
      LP_due_ind := 'N';
   else
      LP_due_ind := 'Y';
   end if;

   LP_roq := (LP_order_up_to_point - LP_net_inventory);

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.GET_LOCN_NEED_MIN_MAX',
                                         to_char(SQLCODE));
   return FALSE;
END GET_LOCN_NEED_MIN_MAX;
-------------------------------------------------------------------------
FUNCTION GET_LOCN_NEED_FLOATING_POINT (O_error_message    IN OUT   VARCHAR2)
RETURN BOOLEAN IS

BEGIN

   /* calculate the order point */
   LP_order_point := GREATEST(LEAST(LP_max_stock * LP_incr_pct/100,
                                    99999999.9999),LP_pres_stock);

   LP_order_up_to_point := LP_order_point;

   /* if the order point is less than the net inv, the item/loc is not due */
   if LP_order_point <= LP_net_inventory then
      LP_due_ind := 'N';
   else
      LP_due_ind := 'Y';
   end if;

   LP_roq := (LP_order_point - LP_net_inventory);

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                        'GET_REPL_ORDER_QTY_SQL.GET_LOCN_NEED_FLOATING_POINT',
                                         to_char(SQLCODE));
   return FALSE;
END GET_LOCN_NEED_FLOATING_POINT;
-------------------------------------------------------------------------
FUNCTION GET_STORE_ORDERS(O_error_message    IN OUT   VARCHAR2)
RETURN BOOLEAN IS

 L_from_date    repl_item_loc.last_delivery_date%TYPE;
 L_to_date      repl_item_loc.last_delivery_date%TYPE;
 L_no_from_date repl_item_loc.last_delivery_date%TYPE;


 RECORD_LOCKED  EXCEPTION;
 PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);


cursor C_STORE_ORD_ROQ is
   select NVL(SUM(so.need_qty),0)
     from store_orders so
    where so.item = LP_item
      and so.store = LP_locn
      and so.need_date BETWEEN (to_date(L_from_date)) and (to_date(L_to_date))
      and so.processed_date is NULL
      and so.need_qty > 0;

cursor C_SOURCE_WH_ROQ is
   select NVL(SUM(so.need_qty),0)
     from store_orders so,
          repl_item_loc ril
    where so.item = LP_item
      and so.item = ril.item
      and so.store = ril.location
      and ril.source_wh = LP_locn
      and ril.repl_method = 'SO'
      and ((ril.reject_store_ord_ind = 'Y'
            and need_date BETWEEN (ril.wh_lead_time + L_from_date) and (ril.wh_lead_time + L_to_date))
           or(ril.reject_store_ord_ind = 'N'
              and need_date BETWEEN (L_no_from_date) and (ril.wh_lead_time + L_to_date)))
      and processed_date is NULL
      and need_qty > 0;

cursor C_LOCK_STORE_ORDERS is
   select 'x'
     from store_orders
    where item = LP_item
      and store = LP_locn
      and need_date BETWEEN (to_date(L_from_date)) and (to_date(L_to_date))
      and processed_date is NULL
      and need_qty > 0
      for update nowait;


BEGIN
   /* Set date variables.  The to_date is the next_review_date plus the next lead time. */
   L_to_date := (LP_next_order_lead_time + (LP_review_lead_time + to_date(LP_vdate)));
   L_from_date := (LP_curr_order_lead_time + to_date(LP_vdate));
   L_no_from_date := to_date('19010101','YYYYMMDD');

   /* Open cursor and fetch total store order need for store location. */
   if LP_locn_type = 'S' then
      ---
      /* If the store's reject_store_ord_ind is set to 'N'O on repl_item_loc,
       *  then no current delivery date will need to be considered. */
      if LP_reject_store_ord_ind = 'N' then
         L_from_date := L_no_from_date;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN','C_STORE_ORD_ROQ','STORE_ORDERS',
                       'ITEM: '||LP_item||' STORE: '||to_char(LP_locn));
      open C_STORE_ORD_ROQ;
      SQL_LIB.SET_MARK('FETCH','C_STORE_ORD_ROQ','STORE_ORDERS',
                       'ITEM: '||LP_item||' STORE: '||to_char(LP_locn));
      fetch C_STORE_ORD_ROQ into LP_store_order_roq;
      SQL_LIB.SET_MARK('CLOSE','C_STORE_ORD_ROQ','STORE_ORDERS',
                       'ITEM: '||LP_item||' STORE: '||to_char(LP_locn));
      close C_STORE_ORD_ROQ;

      /* If no records are found, then set the ROQ to zero. */
      if LP_store_order_roq = 0 then
         LP_store_order_due_ind := 'N';
      else
         LP_store_order_due_ind := 'Y';
         ---
         /* Update the processed_date on the store_orders table if a need_qty is returned. */
         SQL_LIB.SET_MARK('OPEN','C_LOCK_STORE_ORDERS','STORE_ORDERS',
                          'ITEM: '||LP_item||' STORE: '||to_char(LP_locn));
         open C_LOCK_STORE_ORDERS;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_STORE_ORDERS','STORE_ORDERS',
                          'ITEM: '||LP_item||' STORE: '||to_char(LP_locn));
         close C_LOCK_STORE_ORDERS ;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'STORE_ORDERS',
                          'ITEM: '||LP_item||' STORE: '||to_char(LP_locn));
         ---
         update store_orders
           set processed_date = LP_vdate
          where item = LP_item
            and store = LP_locn
            and need_date BETWEEN (to_date(L_from_date)) and (to_date(L_to_date))
            and processed_date is NULL
            and need_qty > 0;
      end if;
   else
      /* Open cursor and fetch total store order need for all stores at source wh. */
      SQL_LIB.SET_MARK('OPEN','C_SOURCE_WH_ROQ','STORE_ORDERS',
                       'ITEM: '||LP_item||' WH: '||to_char(LP_locn));
      open C_SOURCE_WH_ROQ;
      SQL_LIB.SET_MARK('FETCH','C_SOURCE_WH_ROQ','STORE_ORDERS',
                       'ITEM: '||LP_item||' WH: '||to_char(LP_locn));
      fetch C_SOURCE_WH_ROQ into LP_store_order_roq;
      SQL_LIB.SET_MARK('CLOSE','C_SOURCE_WH_ROQ','STORE_ORDERS',
                       'ITEM: '||LP_item||' WH: '||to_char(LP_locn));
      close C_SOURCE_WH_ROQ;
      ---
      if LP_store_order_roq = 0 then
         LP_store_order_due_ind := 'N';
      else
         LP_store_order_due_ind := 'Y';
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             'STORE_ORDERS',
                                             'I_item: '||LP_item,
                                             'I_location: '||to_char(LP_locn));
      return FALSE;

when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                          SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.GET_STORE_ORDERS',
                                          to_char(SQLCODE));
   return FALSE;
END GET_STORE_ORDERS;
------------------------------------------------------------------------------------------
FUNCTION GET_ITEM_SUB_FORECAST (O_error_message      IN OUT   VARCHAR2,
                                O_total_forecast     IN OUT   item_forecast.forecast_sales%TYPE,
                                I_item               IN       item_master.item%TYPE,
                                I_loc                IN       item_forecast.loc%TYPE,
                                I_sub_item_loc       IN       sub_items_head.location%TYPE,
                                I_sub_forecast_ind   IN       sub_items_head.use_forecast_sales_ind%TYPE,
                                I_first_date         IN       period.vdate%TYPE,
                                I_domain_id          IN       domain.domain_id%TYPE,
                                I_last_date          IN       period.vdate%TYPE,
                                I_days_of_period     IN       repl_item_loc.wh_lead_time%TYPE)
RETURN BOOLEAN IS

   L_sub_item         sub_items_detail.sub_item%TYPE    := NULL;
   L_forecast         item_forecast.forecast_sales%TYPE := 0;
   L_total_forecast   item_forecast.forecast_sales%TYPE := 0;

   cursor C_SUB_ITEMS_FORECAST is
      select sid.sub_item
        from sub_items_detail sid,
             sub_items_head sih
       where sih.item                   = sid.item
         and sih.location               = sid.location
         and sid.item                   = I_item
         and sid.location               = I_sub_item_loc
         and sih.use_forecast_sales_ind = 'Y';

BEGIN

   if NOT CALCULATE_FORECAST_FOR_PERIOD (O_error_message,
                                         L_forecast,
                                         I_loc,
                                         I_first_date,
                                         I_item,
                                         I_domain_id,
                                         I_last_date,
                                         I_days_of_period) then
      return FALSE;
   end if;

   L_total_forecast := L_forecast;

   if I_sub_forecast_ind = 'Y' then

      SQL_LIB.SET_MARK('OPEN','C_SUB_ITEMS_FORECAST','SUB_ITEMS_DETAIL',
                       'ITEM: '||I_item||' LOC: '||to_char(I_sub_item_loc));
      open C_SUB_ITEMS_FORECAST;
      LOOP
         SQL_LIB.SET_MARK('FETCH','C_SUB_ITEMS_FORECAST','SUB_ITEMS_DETAIL',
                          'ITEM: '||I_item||' LOC: '||to_char(I_sub_item_loc));
         fetch C_SUB_ITEMS_FORECAST into L_sub_item;
         if C_SUB_ITEMS_FORECAST%NOTFOUND then
            Exit;
         else
            if NOT CALCULATE_FORECAST_FOR_PERIOD (O_error_message,
                                                  L_forecast,
                                                  I_loc,
                                                  I_first_date,
                                                  L_sub_item,
                                                  I_domain_id,
                                                  I_last_date,
                                                  I_days_of_period) then
               return FALSE;
            end if;
         end if;

         L_total_forecast := NVL(L_total_forecast, 0) + NVL(L_forecast, 0);

      END LOOP;

      SQL_LIB.SET_MARK('CLOSE','C_SUB_ITEMS_FORECAST','SUB_ITEMS_DETAIL',
                       'ITEM: '||I_item||' LOC: '||to_char(I_sub_item_loc));
      close C_SUB_ITEMS_FORECAST;

   end if;

   O_total_forecast := L_total_forecast;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'GET_REPL_ORDER_QTY_SQL.GET_ITEM_SUB_FORECAST',
                                            to_char(SQLCODE));
      return FALSE;
END GET_ITEM_SUB_FORECAST;
-------------------------------------------------------------------------
FUNCTION GET_LOCN_NEED_TIME_SUPPLY(O_error_message   IN OUT   VARCHAR2,
                                   I_domain_id       IN       domain.domain_id%TYPE)
RETURN BOOLEAN IS

   L_last_eow_date        item_forecast.eow_date%TYPE         := NULL;
   L_forecast             NUMBER(20,4)                        := NULL;
   L_total_rate_of_sale   NUMBER(20,4)                        := 0;
   L_total_fdmin          item_forecast.forecast_sales%TYPE   := NULL;
   L_total_fdmax          item_forecast.forecast_sales%TYPE   := NULL;

BEGIN

   if (NVL(LP_time_supply_horizon,0) > 0) then

       L_last_eow_date := LP_vdate + LP_time_supply_horizon;

      /* get sales rate over time supply horz */
      if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                    L_forecast,
                                    LP_item,
                                    LP_locn,
                                    LP_sub_item_loc,
                                    LP_sub_fore_ind,
                                    LP_vdate,
                                    I_domain_id,
                                    L_last_eow_date,
                                    LP_time_supply_horizon) then
         return FALSE;
      end if;

      L_total_rate_of_sale := L_forecast / LP_time_supply_horizon;

      LP_tsh_forecast      := L_forecast;

      /* find order point and order up to point */
      if NVL(LP_phase_end, LP_min_supply_days + LP_vdate + 1) - LP_vdate <= LP_min_supply_days then

         LP_order_point       := LEAST(L_total_rate_of_sale * (LP_phase_end - LP_vdate) +
                                  LP_terminal_stock_qty, 99999999.9999);
         LP_order_up_to_point := LP_order_point;

      else /* end LP_phase_end - LP_vdate > LP_min_supply_days */

         LP_order_point       := LEAST(GREATEST(L_total_rate_of_sale * LP_min_supply_days,
                                 LP_pres_stock), 99999999.9999);

         if NVL(LP_phase_end, LP_max_supply_days + LP_vdate + 1) - LP_vdate <= LP_max_supply_days then

            LP_order_up_to_point := LEAST(L_total_rate_of_sale * (LP_phase_end - LP_vdate) +
                                         LP_terminal_stock_qty, 99999999.9999);

         else

            LP_order_up_to_point := LEAST(GREATEST(L_total_rate_of_sale * LP_max_supply_days,
                                                   LP_pres_stock), 99999999.9999);

         end if; /* end LP_phase_end - LP_vdate <= LP_max_supply_days */

      end if; /* end LP_phase_end - LP_vdate <= LP_min_supply_days */

      if LP_due_ord_process_ind = 'N' and LP_repl_results_all_ind = 'N' then
         if LP_order_point <= LP_net_inventory then
            LP_roq               := 0;
            LP_due_ind           := 'N';
            LP_order_up_to_point := 0;
            return TRUE;
         end if;
        end if;

   else /* time supply horz is <= 0 */

      ---- SET THE ORDER POINT ----

      /* season ends before the min supply day, order point equals the forcast for */
      /* vdate to end of season */
      if NVL(LP_phase_end, LP_min_supply_days + LP_vdate + 1) - LP_vdate <= LP_min_supply_days then

         /* get sales rate over season */
         if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                       L_forecast,
                                       LP_item,
                                       LP_locn,
                                       LP_sub_item_loc,
                                       LP_sub_fore_ind,
                                       LP_vdate,
                                       I_domain_id,
                                       LP_phase_end,
                                       LP_phase_end - LP_vdate) then
            return FALSE;
         end if;

         L_total_fdmin               := L_forecast;
         LP_min_supply_days_forecast := L_forecast;

         LP_order_point              := LEAST(L_total_fdmin + LP_terminal_stock_qty, 99999999.9999);

      else /* LP_phase_end - LP_vdate > LP_min_supply_days */
      /* season ends after the min supply day, order point equals the forcast for */
      /* vdate to min_supply_days */

         /* get sales rate over min supply days */
         if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                       L_forecast,
                                       LP_item,
                                       LP_locn,
                                       LP_sub_item_loc,
                                       LP_sub_fore_ind,
                                       LP_vdate,
                                       I_domain_id,
                                       LP_vdate + NVL(LP_min_supply_days, 0),
                                       LP_min_supply_days) then
            return FALSE;
         end if;

         L_total_fdmin               := L_forecast;
         LP_min_supply_days_forecast := L_forecast;

         LP_order_point              := LEAST(GREATEST(L_total_fdmin, LP_pres_stock), 99999999.9999);

      end if; /* end LP_phase_end - LP_vdate <= LP_min_supply_days */

      ----

      if LP_due_ord_process_ind = 'N' and LP_repl_results_all_ind = 'N' then
         if LP_order_point <= LP_net_inventory then
            LP_roq               := 0;
            LP_due_ind           := 'N';
            LP_order_up_to_point := 0;
            return TRUE;
         end if;
      end if;

      ---- SET THE UP TO ORDER POINT ----

      /* phase ends before the min supply days, so order up to pt is same as order pt */
      if NVL(LP_phase_end, LP_min_supply_days + LP_vdate + 1) - LP_vdate <= LP_min_supply_days then

         LP_order_up_to_point := LP_order_point;
         LP_max_supply_days_forecast := LP_min_supply_days_forecast;

      /* phase ends before the max supply days, order up to pt is forecast to season end */
      elsif NVL(LP_phase_end, + LP_max_supply_days + LP_vdate + 1) - LP_vdate <= LP_max_supply_days then

         /* get sales rate over season */
         if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                       L_forecast,
                                       LP_item,
                                       LP_locn,
                                       LP_sub_item_loc,
                                       LP_sub_fore_ind,
                                       LP_vdate,
                                       I_domain_id,
                                       LP_phase_end,
                                       LP_phase_end - LP_vdate) then
            return FALSE;
         end if;

         L_total_fdmax               := L_forecast;
         LP_max_supply_days_forecast := L_forecast;

         LP_order_up_to_point        := LEAST(L_total_fdmax + LP_terminal_stock_qty, 99999999.9999);

      /* phase ends after max supply days of phase is null, order up to pt is forecast to max */
      /* supply days */
      else /* LP_phase_end - LP_vdate > LP_max_supply_days */

         /* get sales rate over max supply days */
         if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                       L_forecast,
                                       LP_item,
                                       LP_locn,
                                       LP_sub_item_loc,
                                       LP_sub_fore_ind,
                                       LP_vdate,
                                       I_domain_id,
                                       LP_vdate + NVL(LP_max_supply_days, 0),
                                       LP_max_supply_days) then
            return FALSE;
         end if;

         L_total_fdmax               := L_forecast;
         LP_max_supply_days_forecast := L_forecast;

         LP_order_up_to_point        := LEAST(GREATEST(L_total_fdmax, LP_pres_stock), 99999999.9999);

      end if; /* LP_phase_end - LP_vdate <= LP_max_supply_days */

   end if; /* end time supply horz is <= 0 */

   /* if the order point is less than the net inv, the item/loc is not due */
   if LP_order_point <= LP_net_inventory then
      LP_due_ind := 'N';
   else
      LP_due_ind := 'Y';
   end if;

   LP_roq := LP_order_up_to_point - LP_net_inventory;

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.GET_LOCN_NEED_TIME_SUPPLY',
                                         to_char(SQLCODE));
   return FALSE;
END GET_LOCN_NEED_TIME_SUPPLY;
---------------------------------------------------------------------------------------------
FUNCTION GET_FORECAST_STD_DEV(O_error_message   IN OUT   VARCHAR2,
                              O_std_dev         IN OUT   item_forecast.forecast_std_dev%TYPE,
                              I_loc             IN       item_forecast.loc%TYPE,
                              I_domain_id       IN       domain.domain_id%TYPE,
                              I_item            IN       item_forecast.item%TYPE,
                              I_date            IN       item_forecast.eow_date%TYPE)

RETURN BOOLEAN IS

   L_daily_data_exist   VARCHAR2(1) := 'Y';
   L_std_dev            item_forecast.forecast_std_dev%TYPE;
   L_start_day          NUMBER(1);
   L_end_day            NUMBER(1);

   cursor C_DAILY_ITEM_STD_DEV is
      select NVL(forecast_std_dev,0)
        from daily_item_forecast
       where item      = I_item
         and loc       = I_loc
         and domain_id = I_domain_id
         and data_date = I_date;

   cursor C_ITEM_STD_DEV is
      select NVL(ifc.forecast_std_dev,0)
        from item_forecast ifc
       where ifc.item      = I_item
         and ifc.loc       = I_loc
         and ifc.domain_id = I_domain_id
         and ifc.eow_date >= I_date
         and ifc.eow_date < I_date + 7;

BEGIN
   /* Try to get the forecast_std_dev from daily forecast table first */
   SQL_LIB.SET_MARK('OPEN','C_DAILY_ITEM_STD_DEV','ITEM_FORECAST',
                    'ITEM: '||LP_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   open C_DAILY_ITEM_STD_DEV;
   SQL_LIB.SET_MARK('FETCH','C_DAILY_ITEM_STD_DEV','ITEM_FORECAST',
                    'ITEM: '||LP_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   fetch C_DAILY_ITEM_STD_DEV into L_std_dev;
   if C_DAILY_ITEM_STD_DEV%NOTFOUND then
      L_daily_data_exist := 'N';
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_DAILY_ITEM_STD_DEV','ITEM_FORECAST',
                    'ITEM: '||LP_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   close C_DAILY_ITEM_STD_DEV;

   if L_daily_data_exist != 'N' then
      O_std_dev := NVL(L_std_dev, 0);
      return TRUE;
   end if;

   /* Get the forecast_std_dev from weekly forecast table */
   SQL_LIB.SET_MARK('OPEN','C_ITEM_STD_DEV','ITEM_FORECAST',
                    'ITEM: '||LP_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   open C_ITEM_STD_DEV;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_STD_DEV','ITEM_FORECAST',
                    'ITEM: '||LP_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   fetch C_ITEM_STD_DEV into L_std_dev;
   if C_ITEM_STD_DEV%NOTFOUND then
      L_std_dev := 0;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_STD_DEV','ITEM_FORECAST',
                    'ITEM: '||LP_item||
                    ' LOC: '||to_char(I_loc)||
                    ' DOMAIN: '||to_char(I_domain_id));
   close C_ITEM_STD_DEV;

   /* Adjust the forecast_std_dev from weekly data */
   L_start_day := to_number(to_char(to_date(LP_vdate + 1), 'D'));
   L_end_day := to_number(to_char(to_date(I_date), 'D'));
   O_std_dev := NVL(L_std_dev *
                    sqrt(1 - ((L_start_day - L_end_day + 6) /
                              (I_date - LP_vdate + L_start_day - L_end_day + 6))),0);

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.GET_FORECAST_STD_DEV',
                                         to_char(SQLCODE));
   return FALSE;
END GET_FORECAST_STD_DEV;
-------------------------------------------------------------------------
FUNCTION CALCULATE_FORECAST_FOR_STD_DEV(O_error_message   IN OUT   VARCHAR2,
                                        O_std_dev         IN OUT   item_forecast.forecast_std_dev%TYPE,
                                        I_domain_id       IN       domain.domain_id%TYPE,
                                        I_item            IN       item_forecast.item%TYPE,
                                        I_date            IN       item_forecast.eow_date%TYPE)

RETURN BOOLEAN IS

   L_loc                  ITEM_FORECAST.LOC%TYPE;
   L_subtotal_std_dev     item_forecast.forecast_std_dev%TYPE := 0;
   L_wh_std_dev           item_forecast.forecast_std_dev%TYPE := 0;
   L_total_std_dev        item_forecast.forecast_std_dev%TYPE := 0;
   L_total_number_of_wh   NUMBER(2) := 0;

   cursor C_REPL_WH_LINK is
      select wh
        from wh
       where repl_wh_link = L_loc;

BEGIN

   L_loc := LP_locn;

   /* Loop through all linked warehouses */
   if LP_locn_type = 'W' then
      for c_rec in C_REPL_WH_LINK LOOP
         if NOT GET_FORECAST_STD_DEV (O_error_message,
                                      L_wh_std_dev,
                                      c_rec.wh,
                                      I_domain_id,
                                      I_item,
                                      I_date) then

            return FALSE;
         end if;

         /* Sum total standard deviation from linked warehouses */
         L_subtotal_std_dev   := NVL(L_wh_std_dev, 0) + L_subtotal_std_dev;

         /* Add up the number of warehouses being looped through for averaging */
         L_total_number_of_wh := L_total_number_of_wh + 1;
      end LOOP;

      /* Get the average standard deviation from the number of linked warehouses processed */
      L_total_std_dev := (L_subtotal_std_dev/L_total_number_of_wh);

   else
      if NOT GET_FORECAST_STD_DEV (O_error_message,
                                   L_total_std_dev,
                                   L_loc,
                                   I_domain_id,
                                   I_item,
                                   I_date) then

         return FALSE;
      end if;
   end if;

   O_std_dev := NVL(L_total_std_dev, 0);

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.CALCULATE_FORECAST_FOR_STD_DEV',
                                         to_char(SQLCODE));
   return FALSE;
END CALCULATE_FORECAST_FOR_STD_DEV;
------------------------------------------------------------------------------------------
FUNCTION GET_LOCN_NEED_DYNAMIC(O_error_message        IN OUT   VARCHAR2,
                               I_domain_id            IN       DOMAIN.DOMAIN_ID%TYPE,
                               I_service_level_type   IN       REPL_ITEM_LOC.SERVICE_LEVEL_TYPE%TYPE DEFAULT NULL,
                               I_last_delivery_date   IN       REPL_ITEM_LOC.LAST_DELIVERY_DATE%TYPE DEFAULT NULL,
                               I_next_delivery_date   IN       REPL_ITEM_LOC.NEXT_DELIVERY_DATE%TYPE DEFAULT NULL)
RETURN BOOLEAN IS

   L_exp_units_short          NUMBER(20,10)                                  := NULL;

   L_units_short_high         safety_stock_lookup.exp_units_short%TYPE       := NULL;
   L_units_short_low          safety_stock_lookup.exp_units_short%TYPE       := NULL;
   L_std_dev_high             safety_stock_lookup.safety_stock_std_dev%TYPE  := NULL;
   L_std_dev_low              safety_stock_lookup.safety_stock_std_dev%TYPE  := NULL;

   L_curr_ord_lead_date        period.vdate%TYPE                             := NULL;
   L_next_ord_lead_date        period.vdate%TYPE                             := NULL;
   L_review_date               period.vdate%TYPE                             := NULL;
   L_inv_sell_date             period.vdate%TYPE                             := NULL;
   L_phase_forecast_total      NUMBER(20,4)                                  := NULL;
   L_review_forecast_total     NUMBER(20,4)                                  := NULL;
   L_inv_sell_forecast_total   NUMBER(20,4)                                  := NULL;
   L_review_std_dev            item_forecast.forecast_std_dev%TYPE           := NULL;
   L_review_std_dev_total      item_forecast.forecast_std_dev%TYPE           := NULL;
   L_review_std_dev_avg        item_forecast.forecast_std_dev%TYPE           := NULL;
   L_safety_stock_std_dev      safety_stock_lookup.safety_stock_std_dev%TYPE := NULL;
   L_sub_item                  sub_items_detail.sub_item%TYPE                := NULL;
   L_forecast                  NUMBER(20,4)                                  := NULL;
   L_increment_ITEM            NUMBER(2)                                     := 0;
   L_current_ITEM              ITEM_MASTER.ITEM%TYPE                         := NULL;
   L_difference                NUMBER(20,4)                                  := NULL;
   L_temp_review_lead_time     NUMBER                                        := NULL;
   L_temp_nolt                 NUMBER                                        := NULL;

   L_K                        NUMBER(20,4) := NULL;
   L_lookup_K                 NUMBER(20,4) := NULL;

   L_uom_conv_factor          item_master.uom_conv_factor%TYPE;
   L_standard_uom             uom_class.uom%TYPE;
   L_standard_class           uom_class.uom_class%TYPE;
   L_i                          INTEGER;

   cursor C_SUB_ITEMS_DYNAMIC is
      select sid.sub_item
        from sub_items_detail sid,
             sub_items_head sih
       where sih.item                   = sid.item
         and sih.location               = sid.location
         and sid.item                   = LP_item
         and sid.location               = LP_sub_item_loc
         and sih.use_forecast_sales_ind = 'Y';

   cursor C_SS_STD_DEV is
      select safety_stock_std_dev,
             exp_units_short
        from safety_stock_lookup
    order by exp_units_short desc;

   cursor C_LOOKUPK_HIGH is
      select max(exp_units_short),
             min(safety_stock_std_dev)
        from safety_stock_lookup
       where safety_stock_std_dev >= L_K;

   cursor C_LOOKUPK_LOW is
      select min(exp_units_short),
             max(safety_stock_std_dev)
        from safety_stock_lookup
       where safety_stock_std_dev <= L_K;

BEGIN

   L_curr_ord_lead_date := LP_vdate + NVL(LP_curr_order_lead_time,0);
   L_next_ord_lead_date := LP_vdate + NVL(LP_next_order_lead_time,0);
   L_review_date   := L_next_ord_lead_date + NVL(LP_review_lead_time,0);
   L_inv_sell_date := L_curr_ord_lead_date + NVL(LP_inv_selling_days,0);

   /* get forecast for from vdate to current order lead date */
   if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                 L_forecast,
                                 LP_item,
                                 LP_locn,
                                 LP_sub_item_loc,
                                 LP_sub_fore_ind,
                                 LP_vdate,
                                 I_domain_id,
                                 L_curr_ord_lead_date,
                                 LP_curr_order_lead_time) then
      return FALSE;
   end if;
   LP_curr_olt_forecast := L_forecast;

   /* get forecast for from vdate to next order lead date */
   if LP_curr_order_lead_time = LP_next_order_lead_time then
      LP_next_olt_forecast := LP_curr_olt_forecast;
   else
      /* Since NOLT is different from COLT, phase end might be before the end of NOLT. */
      /* If this happens, forecast for NOLT should be adjusted to the phase end. */
      if NVL(LP_phase_end, L_next_ord_lead_date + 1) <= L_next_ord_lead_date then
         if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                       L_forecast,
                                       LP_item,
                                       LP_locn,
                                       LP_sub_item_loc,
                                       LP_sub_fore_ind,
                                       LP_vdate,
                                       I_domain_id,
                                       LP_phase_end,
                                       LP_phase_end - LP_vdate) then
            return FALSE;
         end if;
      else
         if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                       L_forecast,
                                       LP_item,
                                       LP_locn,
                                       LP_sub_item_loc,
                                       LP_sub_fore_ind,
                                       LP_vdate,
                                       I_domain_id,
                                       L_next_ord_lead_date,
                                       LP_next_order_lead_time) then
            return FALSE;
         end if;
      end if;
      LP_next_olt_forecast := L_forecast;
   end if;

   /* If phase ends before the end of NOLT, the order point calculation stops */
   /* since no review forecast is needed. */
   if NVL(LP_phase_end, L_next_ord_lead_date + 1) <= L_next_ord_lead_date then
      LP_review_time_forecast := 0;
      LP_order_point := LEAST(LP_next_olt_forecast + LP_terminal_stock_qty, 99999999.9999);

   /* If the end of the phase falls between the next order lead date and the review lead */
   /* date, the roq is set by calculating the forecast for from the next order lead date */
   /* to the end of phase date. */
   elsif NVL(LP_phase_end, L_review_date + 1) <= L_review_date then

      /* get forecast for review_date to end of phase */
      if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                    L_forecast,
                                    LP_item,
                                    LP_locn,
                                    LP_sub_item_loc,
                                    LP_sub_fore_ind,
                                    L_next_ord_lead_date,
                                    I_domain_id,
                                    LP_phase_end,
                                    LP_phase_end - L_next_ord_lead_date) then
         return FALSE;
      end if;

      L_phase_forecast_total  := L_forecast;
      LP_review_time_forecast := L_forecast;

      /* calculate the order point */
      LP_order_point := LEAST(LP_next_olt_forecast + L_phase_forecast_total +
                              LP_terminal_stock_qty, 99999999.9999);

   else

      /* get forecast for from next order lead date to review date */
      if NOT CALCULATE_FORECAST_FOR_PERIOD (O_error_message,
                                            L_forecast,
                                            LP_locn,
                                            L_next_ord_lead_date,
                                            LP_item,
                                            I_domain_id,
                                            L_review_date,
                                            LP_review_lead_time) then
         return FALSE;
      end if;

      L_review_forecast_total := L_forecast;
      L_increment_ITEM        := L_increment_ITEM + 1;

      L_current_ITEM          := LP_item;

      if NOT CALCULATE_FORECAST_FOR_STD_DEV (O_error_message,
                                             L_review_std_dev,
                                             I_domain_id,
                                             L_current_ITEM,
                                             L_review_date) then
         return FALSE;
      end if;

      L_review_std_dev_total := L_review_std_dev;

      if LP_sub_fore_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN','C_SUB_ITEMS_DYNAMIC','SUB_ITEMS_DETAIL',
                          'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
         open C_SUB_ITEMS_DYNAMIC;
         LOOP
            SQL_LIB.SET_MARK('FETCH','C_SUB_ITEMS_DYNAMIC','SUB_ITEMS_DETAIL',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
            fetch C_SUB_ITEMS_DYNAMIC into L_sub_item;
            if C_SUB_ITEMS_DYNAMIC%NOTFOUND then
               Exit;
            else
               if NOT CALCULATE_FORECAST_FOR_PERIOD (O_error_message,
                                                     L_forecast,
                                                     LP_locn,
                                                     L_next_ord_lead_date,
                                                     L_sub_item,
                                                     I_domain_id,
                                                     L_review_date,
                                                     LP_review_lead_time) then
                  return FALSE;
               end if;
            end if;

            L_review_forecast_total := L_review_forecast_total + NVL(L_forecast,0);
            L_increment_ITEM        := L_increment_ITEM + 1;

            L_current_ITEM          := L_sub_item;

            if NOT CALCULATE_FORECAST_FOR_STD_DEV (O_error_message,
                                                   L_review_std_dev,
                                                   I_domain_id,
                                                   L_current_ITEM,
                                                   L_review_date) then
               return FALSE;
            end if;

            L_review_std_dev_total   := L_review_std_dev_total + L_review_std_dev;

         END LOOP;

         SQL_LIB.SET_MARK('CLOSE','C_SUB_ITEMS_DYNAMIC','SUB_ITEMS_DETAIL',
                          'ITEM: '||LP_item||' LOC: '||to_char(LP_sub_item_loc));
         close C_SUB_ITEMS_DYNAMIC;

      end if;

      /* set the review_std_dev as an average of the number of sub ITEMs plus the main ITEM */
      L_review_std_dev_avg := (L_review_std_dev_total / L_increment_ITEM);

      /* calculate the safety stock */
      if (LP_repl_method = 'D' and I_service_level_type = LP_srvce_lvl_type_simple_sales) then
         if CALCULATE_FORECAST_FOR_PERIOD(O_error_message,
                                          L_forecast,
                                          LP_locn,
                                          I_last_delivery_date,
                                          LP_item,
                                          I_domain_id,
                                          I_next_delivery_date,
                                          NULL) = FALSE then
            return FALSE;
         end if;
         LP_safety_stock := L_forecast * (NVL(LP_service_level,0)/100);
      elsif L_review_std_dev_avg = 0 then
         LP_safety_stock := 0;
      else
         L_exp_units_short := (((1 - (NVL(LP_service_level,0)/100)) * L_review_forecast_total)
                                 /  L_review_std_dev_avg);

          if LP_first = 0 then
            L_i := 0;
            FOR c_rec in C_SS_STD_DEV loop
               L_i := L_i + 1;
               LP_safety(L_i).safety_stock_std_dev := c_rec.safety_stock_std_dev;
               LP_safety(L_i).exp_units_short      := c_rec.exp_units_short;
            end loop;
            LP_first := 1;
         end if;

         for j in LP_safety.first..LP_safety.last loop
            if L_exp_units_short >= LP_safety(j).exp_units_short then
               L_std_dev_low := LP_safety(j).safety_stock_std_dev;
               L_units_short_low := LP_safety(j).exp_units_short;
               exit;
            end if;
         end loop;

         for j in LP_safety.first..LP_safety.last loop
            if L_exp_units_short <= LP_safety(j).exp_units_short then
               L_units_short_high := LP_safety(j).exp_units_short;
            end if;
         end loop;

         for j in reverse LP_safety.first..LP_safety.last loop
            if L_exp_units_short <= LP_safety(j).exp_units_short then
               L_std_dev_high := LP_safety(j).safety_stock_std_dev;
               exit;
            end if;
         end loop;

         /* if the denominator in the L_std_dev formula will be zero */
         /* make it equal to one so it does not divide by zero */
         if L_units_short_high - L_units_short_low = 0 then
            L_units_short_high := L_units_short_high + 1;
         end if;

         /* do statistical calculation to get the safety stock std dev */
         /* that exists on the table for the given exp_units_short */
         /* NOTE: the std dev should be in the same relative position */
         /* between two records as the exp units short is */
         if L_exp_units_short >= 4.5 then
            L_safety_stock_std_dev := -4.5;
         elsif L_exp_units_short < 0.000 then
            L_safety_stock_std_dev := 4.5;
         else
            L_safety_stock_std_dev := ((((L_exp_units_short - L_units_short_low)
                                        / (L_units_short_high - L_units_short_low))
                                        * (L_std_dev_high - L_std_dev_low))
                                        + L_std_dev_low);
         end if;

         LP_safety_stock := (L_safety_stock_std_dev * L_review_std_dev_avg);

      end if; /* end L_review_std_dev_avg = 0 */

      /* calculate the order point */
      LP_order_point := LEAST(LP_next_olt_forecast + L_review_forecast_total
                        + GREATEST(LP_safety_stock, LP_pres_stock), 99999999.9999);

      LP_review_time_forecast := L_review_forecast_total;

   end if; /* end checking LP_phase_end with L_review_date */

   /* retrieve the net inventory */
   if NOT GET_NET_INVENTORY( O_error_message,
                             LP_net_inventory) then
      return FALSE;
   end if;

   if LP_due_ord_process_ind = 'N' and LP_repl_results_all_ind = 'N' then
      if LP_order_point <= LP_net_inventory then
         LP_roq               := 0;
         LP_due_ind           := 'N';
         LP_order_up_to_point := 0;
         return TRUE;
      end if;
   end if;

   /* LOST SALES */
   /* Lost sales are calculated by using the current order lead date only. */

   /* retrieve the net inventory, with LP_review_lead_time of zero */
   /* to get lost sales net inventory of zero for calculations */
   L_temp_review_lead_time := LP_review_lead_time;
   LP_review_lead_time     := 0;

   /* copy LP_next_order_lead_time to a temporary variable */
   L_temp_nolt             := LP_next_order_lead_time;
   LP_next_order_lead_time := LP_curr_order_lead_time;

   if NOT GET_NET_INVENTORY( O_error_message,
                             LP_net_inventory_lost_sales) then
      return FALSE;
   end if;

   LP_review_lead_time     := L_temp_review_lead_time;
   /* copy temporary variable back to LP_next_order_lead_time */
   LP_next_order_lead_time := L_temp_nolt;

   /* calculate lost sales */
   if LP_curr_olt_forecast <= LP_net_inventory_lost_sales then
      LP_lost_sales := 0;
   else
      LP_lost_sales := (1 - (NVL(LP_lost_sales_factor,0)/100))
                       * (LP_curr_olt_forecast - LP_net_inventory_lost_sales);
   end if;

   /* If the review date is on or later than the inv selling date, */
   /* the order up to point should be set equal to the order point. */
   if L_review_date >= L_inv_sell_date then
      LP_order_up_to_point := LP_order_point;
      LP_isd_forecast      := LP_review_time_forecast;

      /* If the phase ended before the end of the review time */
      /* do not need to calculate aso, eso                    */
      if NVL(LP_phase_end, L_review_date + 1) <= L_review_date then
         if LP_order_point <= LP_net_inventory then
            LP_due_ind := 'N';
         else
            LP_due_ind := 'Y';
         end if;

         LP_aso := 0;
         LP_eso := 0;
         LP_roq := LP_order_point - LP_net_inventory - LP_lost_sales;
         return TRUE;
      end if;
   else
      if NVL(LP_phase_end, L_inv_sell_date + 1) <= L_inv_sell_date then

         /* If the phase ended before the end of the review time */
         /* set the order up to point equal to the order point   */
         /* do not need to calculate aso, eso                    */
         if NVL(LP_phase_end, L_review_date + 1) <= L_review_date then
            LP_order_up_to_point := LP_order_point;
            LP_isd_forecast := LP_review_time_forecast;

            if LP_order_point <= LP_net_inventory then
               LP_due_ind := 'N';
            else
               LP_due_ind := 'Y';
            end if;

            LP_aso := 0;
            LP_eso := 0;
            LP_roq := LP_order_point - LP_net_inventory - LP_lost_sales;
            return TRUE;
         else
            /* get forecast for from current order lead time to end of phase */
            if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                          L_forecast,
                                          LP_item,
                                          LP_locn,
                                          LP_sub_item_loc,
                                          LP_sub_fore_ind,
                                          L_curr_ord_lead_date,
                                          I_domain_id,
                                          LP_phase_end,
                                          LP_phase_end - L_curr_ord_lead_date) then
               return FALSE;
            end if;

            L_phase_forecast_total := L_forecast;
            LP_isd_forecast        := L_forecast;

            /* calculate the order up to point */
            LP_order_up_to_point   := LEAST(LP_curr_olt_forecast + L_phase_forecast_total +
                                            LP_terminal_stock_qty, 99999999.9999);
         end if; /* already got forecast up to end of phase */

      else

         /* get forecast for order lead date to inv selling date */
         if NOT GET_ITEM_SUB_FORECAST (O_error_message,
                                       L_forecast,
                                       LP_item,
                                       LP_locn,
                                       LP_sub_item_loc,
                                       LP_sub_fore_ind,
                                       L_curr_ord_lead_date,
                                       I_domain_id,
                                       L_inv_sell_date,
                                       LP_inv_selling_days) then
           return FALSE;
         end if;

         L_inv_sell_forecast_total := L_forecast;
         LP_isd_forecast           := L_forecast;

         /* calculate the order up to point */
         LP_order_up_to_point      := LEAST(LP_curr_olt_forecast + L_inv_sell_forecast_total
                                      + GREATEST(LP_safety_stock, LP_pres_stock), 99999999.9999);

      end if; /* end checking LP_phase_end with L_inv_sell_date */

   end if; /*end LP_review_lead_time < LP_inv_selling_days */

   /********************************************************************************/
   /* calculate the eso and aso */
   /*****************************/

   if LP_due_ord_process_ind = 'Y' then
      /* set the aso */
      LP_aso := (LP_review_time_forecast) *
                (1-(LP_service_level/100));

      /* set the eso */

         /*set the K value*/
         if L_review_std_dev_avg = 0 then
            LP_eso := 0;
         else
            L_K := ( (LP_net_inventory - (LP_next_olt_forecast + LP_review_time_forecast)) /
                       L_review_std_dev_avg );

            /*set the lookup(K) value*/
            SQL_LIB.SET_MARK('OPEN','C_LOOKUPK_HIGH','SAFETY_STOCK_LOOKUP',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_locn));
            open C_LOOKUPK_HIGH;
            SQL_LIB.SET_MARK('FETCH','C_LOOKUPK_HIGH','SAFETY_STOCK_LOOKUP',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_locn));
            fetch C_LOOKUPK_HIGH into L_units_short_high,
                                      L_std_dev_high;
            SQL_LIB.SET_MARK('CLOSE','C_LOOKUPK_HIGH','SAFETY_STOCK_LOOKUP',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_locn));
            close C_LOOKUPK_HIGH;

            SQL_LIB.SET_MARK('OPEN','C_LOOKUPK_LOW','SAFETY_STOCK_LOOKUP',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_locn));
            open C_LOOKUPK_LOW;
            SQL_LIB.SET_MARK('FETCH','C_LOOKUPK_LOW','SAFETY_STOCK_LOOKUP',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_locn));
            fetch C_LOOKUPK_LOW into L_units_short_low,
                                     L_std_dev_low;
            SQL_LIB.SET_MARK('CLOSE','C_LOOKUPK_LOW','SAFETY_STOCK_LOOKUP',
                             'ITEM: '||LP_item||' LOC: '||to_char(LP_locn));
            close C_LOOKUPK_LOW;
            /* aviod dividing by zero when possible */
            if L_std_dev_high - L_std_dev_low = 0 then
              L_std_dev_high := L_std_dev_high + 1;
            end if;

            /* set the lookup(k) values */
            if L_K <= -10 then
               L_lookup_K := 10;
            elsif L_K >= 4.5 then
               L_lookup_K := 0;
            else
               L_lookup_K := ((((L_K - L_std_dev_low)
                                / (L_std_dev_high - L_std_dev_low))
                                * (L_units_short_high - L_units_short_low))
                                + L_units_short_low);

            end if;
         LP_eso := L_lookup_K * L_review_std_dev_avg;
      end if;

      if LP_due_ord_serv_basis = 'C' then
        LP_aso := LP_aso * LP_unit_cost;
        LP_eso := LP_eso * LP_unit_cost;
      elsif LP_due_ord_serv_basis = 'P' then
        LP_aso := LP_aso * (LP_unit_retail - LP_unit_cost);
        LP_eso := LP_eso * (LP_unit_retail - LP_unit_cost);
      elsif LP_due_ord_serv_basis = 'U' then
        /* get the uom conversion factor from the item tables */
        if NOT ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                L_standard_uom,
                                                L_standard_class,
                                                L_uom_conv_factor,
                                                LP_item,
                                                'N') then
           return FALSE;
        end if;

        if L_uom_conv_factor IS NOT NULL then
           LP_aso := LP_aso * L_uom_conv_factor;
           LP_eso := LP_eso * L_uom_conv_factor;
        end if;

      end if;

   else
        LP_aso := 0;
      LP_eso := 0;

   end if; /* end LP_due_ord_process_ind = 'Y' */

   /*********************************/
   /* end calculate the eso and aso */
   /*******************************************************************************/

   /* set the due indicator */

   /* due order processing requires that the due_ind be set using the
      estimated and accepted stock out values */
   if LP_due_ord_process_ind = 'Y' then
      if LP_eso <= LP_aso then
         LP_due_ind := 'N';
      else
         LP_due_ind := 'Y';
      end if;
   else
      /* non due order processing dynamic records set the due flag like all
         the order replenishment methods */
      if LP_order_point <= LP_net_inventory then
         LP_due_ind := 'N';
      else
         LP_due_ind := 'Y';
      end if;
   end if;

   LP_roq := (GREATEST(LP_order_point,LP_order_up_to_point)
                       - LP_net_inventory - LP_lost_sales);

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.GET_LOCN_NEED_DYNAMIC',
                                         to_char(SQLCODE));
   return FALSE;
END GET_LOCN_NEED_DYNAMIC;
-------------------------------------------------------------------------
FUNCTION REPL_METHOD (O_error_message              IN OUT   VARCHAR2,
                      O_order_qty                  IN OUT   ORDLOC.QTY_ORDERED%TYPE,
                      O_order_point                IN OUT   REPL_RESULTS.ORDER_POINT%TYPE,
                      O_order_up_to_point          IN OUT   REPL_RESULTS.ORDER_UP_TO_POINT%TYPE,
                      O_net_inventory              IN OUT   REPL_RESULTS.NET_INVENTORY%TYPE,
                      O_stock_on_hand              IN OUT   REPL_RESULTS.STOCK_ON_HAND%TYPE,
                      O_pack_comp_soh              IN OUT   REPL_RESULTS.PACK_COMP_SOH%TYPE,
                      O_on_order                   IN OUT   REPL_RESULTS.ON_ORDER%TYPE,
                      O_in_transit_qty             IN OUT   REPL_RESULTS.IN_TRANSIT_QTY%TYPE,
                      O_pack_comp_intran           IN OUT   REPL_RESULTS.PACK_COMP_INTRAN%TYPE,
                      O_tsf_resv_qty               IN OUT   REPL_RESULTS.TSF_RESV_QTY%TYPE,
                      O_pack_comp_resv             IN OUT   REPL_RESULTS.PACK_COMP_RESV%TYPE,
                      O_tsf_expected_qty           IN OUT   REPL_RESULTS.TSF_EXPECTED_QTY%TYPE,
                      O_pack_comp_exp              IN OUT   REPL_RESULTS.PACK_COMP_EXP%TYPE,
                      O_rtv_qty                    IN OUT   REPL_RESULTS.RTV_QTY%TYPE,
                      O_alloc_in_qty               IN OUT   REPL_RESULTS.ALLOC_IN_QTY%TYPE,
                      O_alloc_out_qty              IN OUT   REPL_RESULTS.ALLOC_OUT_QTY%TYPE,
                      O_non_sellable_qty           IN OUT   REPL_RESULTS.NON_SELLABLE_QTY%TYPE,
                      O_safety_stock               IN OUT   REPL_RESULTS.SAFETY_STOCK%TYPE,
                      O_lost_sales                 IN OUT   REPL_RESULTS.LOST_SALES%TYPE,
                      O_due_ind                    IN OUT   REPL_RESULTS.DUE_IND%TYPE,
                      O_aso                        IN OUT   REPL_RESULTS.ACCEPTED_STOCK_OUT%TYPE,
                      O_eso                        IN OUT   REPL_RESULTS.ESTIMATED_STOCK_OUT%TYPE,
                      O_min_supply_days_forecast   IN OUT   REPL_RESULTS.MIN_SUPPLY_DAYS_FORECAST%TYPE,
                      O_max_supply_days_forecast   IN OUT   REPL_RESULTS.MAX_SUPPLY_DAYS_FORECAST%TYPE,
                      O_tsh_forecast               IN OUT   REPL_RESULTS.TIME_SUPPLY_HORIZON_FORECAST%TYPE,
                      O_curr_olt_forecast          IN OUT   REPL_RESULTS.ORDER_LEAD_TIME_FORECAST%TYPE,
                      O_next_olt_forecast          IN OUT   REPL_RESULTS.NEXT_LEAD_TIME_FORECAST%TYPE,
                      O_review_time_forecast       IN OUT   REPL_RESULTS.REVIEW_TIME_FORECAST%TYPE,
                      O_isd_forecast               IN OUT   REPL_RESULTS.INV_SELL_DAYS_FORECAST%TYPE,
                      I_item                       IN       REPL_ITEM_LOC.ITEM%TYPE,
                      I_locn_type                  IN       REPL_ITEM_LOC.LOC_TYPE%TYPE,
                      I_locn                       IN       REPL_ITEM_LOC.LOCATION%TYPE,
                      I_sub_item_loc               IN       SUB_ITEMS_HEAD.LOCATION%TYPE,
                      I_store_need                 IN       ORDLOC.QTY_ORDERED%TYPE,
                      I_pres_stock                 IN       REPL_ITEM_LOC.PRES_STOCK%TYPE,
                      I_demo_stock                 IN       REPL_ITEM_LOC.DEMO_STOCK%TYPE,
                      I_repl_method                IN       REPL_ITEM_LOC.REPL_METHOD%TYPE,
                      I_min_stock                  IN       REPL_ITEM_LOC.MIN_STOCK%TYPE,
                      I_max_stock                  IN       REPL_ITEM_LOC.MAX_STOCK%TYPE,
                      I_incr_pct                   IN       REPL_ITEM_LOC.INCR_PCT%TYPE,
                      I_min_supply_days            IN       REPL_ITEM_LOC.MIN_SUPPLY_DAYS%TYPE,
                      I_max_supply_days            IN       REPL_ITEM_LOC.MAX_SUPPLY_DAYS%TYPE,
                      I_time_supply_horizon        IN       REPL_ITEM_LOC.TIME_SUPPLY_HORIZON%TYPE,
                      I_inv_selling_days           IN       REPL_ITEM_LOC.INV_SELLING_DAYS%TYPE,
                      I_service_level              IN       REPL_ITEM_LOC.SERVICE_LEVEL%TYPE,
                      I_lost_sales_factor          IN       REPL_ITEM_LOC.LOST_SALES_FACTOR%TYPE,
                      I_curr_order_lead_time       IN       RPL_NET_INVENTORY_TMP.CURR_ORDER_LEAD_TIME%TYPE,
                      I_next_order_lead_time       IN       RPL_NET_INVENTORY_TMP.NEXT_ORDER_LEAD_TIME%TYPE,
                      I_review_lead_time           IN       REPL_ITEM_LOC.PICKUP_LEAD_TIME%TYPE,
                      I_terminal_stock_qty         IN       REPL_ITEM_LOC.TERMINAL_STOCK_QTY%TYPE,
                      I_due_ord_serv_basis         IN       SUP_INV_MGMT.DUE_ORD_SERV_BASIS%TYPE,
                      I_unit_cost                  IN       TRAN_DATA.TOTAL_COST%TYPE,
                      I_unit_retail                IN       TRAN_DATA.TOTAL_RETAIL%TYPE,
                      I_due_ord_process_ind        IN       SUP_INV_MGMT.DUE_ORD_PROCESS_IND%TYPE,
                      I_repl_results_all_ind       IN       SYSTEM_OPTIONS.REPL_RESULTS_ALL_IND%TYPE,
                      I_season_id                  IN       REPL_ITEM_LOC.SEASON_ID%TYPE,
                      I_phase_id                   IN       REPL_ITEM_LOC.PHASE_ID%TYPE,
                      I_domain_id                  IN       DOMAIN.DOMAIN_ID%TYPE,
                      I_reject_store_ord_ind       IN       REPL_ITEM_LOC.REJECT_STORE_ORD_IND%TYPE,
                      I_date                       IN       DATE,
                      I_last_delivery_date         IN       REPL_ITEM_LOC.LAST_DELIVERY_DATE%TYPE DEFAULT NULL,
                      I_next_delivery_date         IN       REPL_ITEM_LOC.NEXT_DELIVERY_DATE%TYPE DEFAULT NULL)

RETURN BOOLEAN IS

   L_stock_cat            repl_item_loc.stock_cat%TYPE;
   L_source_wh            repl_item_loc.source_wh%TYPE;
   L_sub_item_loc         repl_item_loc.location%TYPE;
   L_service_level_type   REPl_ITEM_LOC.SERVICE_LEVEL_TYPE%TYPE   := NULL;
   L_forecast             NUMBER(20,4)                            := NULL;

   cursor C_GET_PHASE is
      select start_date,
        end_date
        from phases
        where phase_id = LP_phase_id
     and season_id = LP_season_id;

   cursor C_SUBS is
      select sih.use_stock_ind,
             sih.use_forecast_sales_ind
        from sub_items_head sih
       where sih.item     = LP_item
         and sih.location = LP_sub_item_loc;

   cursor C_GET_REPL_INFO is
      /* Old cursor is being modified to include service_level_type in the select statement */
      select ril.stock_cat,
             ril.source_wh,
             ril.service_level_type
        from repl_item_loc ril
       where ril.item     = I_item
         and ril.location = LP_locn;

BEGIN
   LP_locn_type                 := I_locn_type;
   LP_locn                      := I_locn;
   LP_store_need                := I_store_need;
   LP_pres_stock                := NVL(I_pres_stock,0);
   LP_demo_stock                := NVL(I_demo_stock,0);
   LP_repl_method               := I_repl_method;
   LP_min_stock                 := NVL(I_min_stock,0);
   LP_max_stock                 := NVL(I_max_stock,0);
   LP_incr_pct                  := NVL(I_incr_pct,100);
   LP_min_supply_days           := NVL(I_min_supply_days,0);
   LP_max_supply_days           := NVL(I_max_supply_days,0);
   LP_time_supply_horizon       := I_time_supply_horizon;
   LP_inv_selling_days          := NVL(I_inv_selling_days,0);
   LP_service_level             := NVL(I_service_level,0);
   LP_lost_sales_factor         := NVL(I_lost_sales_factor,0);
   LP_curr_order_lead_time      := NVL(I_curr_order_lead_time,0);
   LP_next_order_lead_time      := NVL(I_next_order_lead_time,0);
   LP_review_lead_time          := NVL(I_review_lead_time,0);
   LP_terminal_stock_qty        := I_terminal_stock_qty;
   LP_due_ord_serv_basis        := I_due_ord_serv_basis;
   LP_unit_cost                 := I_unit_cost;
   LP_unit_retail               := I_unit_retail;
   LP_due_ord_process_ind       := I_due_ord_process_ind;
   LP_repl_results_all_ind      := I_repl_results_all_ind;
   LP_reject_store_ord_ind      := I_reject_store_ord_ind;
   LP_due_ind                   := 'N';
   LP_aso                       := NULL;
   LP_eso                       := NULL;
   LP_min_supply_days_forecast  := NULL;
   LP_max_supply_days_forecast  := NULL;
   LP_tsh_forecast              := NULL;
   LP_curr_olt_forecast         := NULL;
   LP_next_olt_forecast         := NULL;
   LP_review_time_forecast      := NULL;
   LP_isd_forecast              := NULL;
   LP_net_inventory             := 0;
   LP_stock_on_hand             := 0;
   LP_pack_comp_soh             := 0;
   LP_on_order                  := 0;
   LP_in_transit_qty            := 0;
   LP_pack_comp_intran          := 0;
   LP_tsf_resv_qty              := 0;
   LP_pack_comp_resv            := 0;
   LP_tsf_expected_qty          := 0;
   LP_pack_comp_exp             := 0;
   LP_rtv_qty                   := 0;
   LP_alloc_in_qty              := 0;
   LP_alloc_out_qty             := 0;
   LP_non_sellable_qty          := 0;
   LP_roq                       := 0;
   LP_order_point               := 0;
   LP_order_up_to_point         := 0;
   LP_net_inventory             := 0;
   LP_safety_stock              := NULL;
   LP_lost_sales                := NULL;

   if I_date is not NULL then
      LP_vdate := I_date;
   end if;

   /* Set substitute item location if its passed in as NULL */
   if (L_sub_item_loc is NULL and LP_locn_type = 'S')
      or (LP_repl_method in ('D', 'F')) then
      SQL_LIB.SET_MARK('OPEN','C_GET_REPL_INFO','REPL_ITEM_LOC',
                       'ITEM: '||I_item||' LOC: '|| to_char(LP_locn));
      open C_GET_REPL_INFO;
      SQL_LIB.SET_MARK('FETCH','C_GET_REPL_INFO','REPL_ITEM_LOC',
                       'ITEM: '||I_item||' LOC: '|| to_char(LP_locn));
      fetch C_GET_REPL_INFO into L_stock_cat,
                                 L_source_wh,
                                 L_service_level_type;
      SQL_LIB.SET_MARK('CLOSE','C_GET_REPL_INFO','REPL_ITEM_LOC',
                       'ITEM: '||I_item||' LOC: '|| to_char(LP_locn));
      close C_GET_REPL_INFO;
   end if;
   if L_sub_item_loc is NULL then
      if LP_locn_type = 'S' then
         ---
         /* If the store is warehouse stocked or crosslinked, then the
            source warehouse is used to define the sub items. */
         if L_stock_cat in ('W', 'L') then
            L_sub_item_loc := L_source_wh;
         else
            L_sub_item_loc := LP_locn;
         end if;
      else
         L_sub_item_loc := LP_locn;
      end if;
   end if;

   /* set the sub item indicators */
   if (NVL(LP_item,-1) != I_item
       or
       (NVL(LP_sub_item_loc, -1) != L_sub_item_loc)) then
      ---
      LP_item := I_item;
      LP_sub_item_loc := L_sub_item_loc;
      ---
      SQL_LIB.SET_MARK('OPEN','C_SUBS','SUB_ITEMS_HEAD',
                       'ITEM: '||LP_item||' LOC: '|| to_char(LP_sub_item_loc));
      open C_SUBS;
      SQL_LIB.SET_MARK('FETCH','C_SUBS','SUB_ITEMS_HEAD',
                       'ITEM: '||LP_item||' LOC: '|| to_char(LP_sub_item_loc));
      fetch C_SUBS into LP_sub_inv_ind,
                        LP_sub_fore_ind;
      if C_SUBS%notfound then
         LP_sub_inv_ind  := 'N';
         LP_sub_fore_ind := 'N';
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_SUBS','SUB_ITEMS_HEAD',
                        'ITEM: '||LP_item||' LOC: '|| to_char(LP_sub_item_loc));
      close C_SUBS;

   end if;

   /* find phase end date if given a phase */
   if I_season_id is NOT NULL and I_phase_id is NOT NULL then

      /* Only do this if the season and phase are different than the ones already in memory. */
      if (NVL(LP_season_id, -1) != I_season_id OR NVL(LP_phase_id,-1) != I_phase_id) then

         LP_season_id           := I_season_id;
         LP_phase_id            := I_phase_id;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_PHASE','PHASES',
                          'PHASE ID: '||to_char(LP_phase_id));
         open C_GET_PHASE;
         SQL_LIB.SET_MARK('FETCH','C_GET_PHASE','PHASES',
                          'PHASE_ID: '||to_char(LP_phase_id));
         fetch C_GET_PHASE into LP_phase_start,
                                LP_phase_end;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PHASE','PHASES',
                           'PHASE_ID: '||to_char(LP_phase_id));
         close C_GET_PHASE;
         ---
         if (LP_vdate + LP_curr_order_lead_time < LP_phase_start -1) then
            O_order_qty         := 0;
            O_order_point       := 0;
            O_order_up_to_point := 0;
            O_net_inventory     := 0;
            O_due_ind           := 'N';
            return TRUE;
         end if;
         ---
         if (LP_vdate + LP_curr_order_lead_time >= LP_phase_end) then
            O_order_qty         := 0;
            O_order_point       := 0;
            O_order_up_to_point := 0;
            O_net_inventory     := 0;
            O_due_ind           := 'N';
            return TRUE;
         end if;
      end if;
   else
     LP_season_id   := NULL;
     LP_phase_id    := NULL;
     LP_phase_start := NULL;
     LP_phase_end   := NULL;
   end if;

   /* retrieve the net inventory */
   if (LP_repl_method != 'D' or (LP_repl_method = 'D' and LP_locn_type = 'W')) then
      /* retrieve the net inventory */
      if NOT GET_NET_INVENTORY( O_error_message,
                                LP_net_inventory) then
         return FALSE;
      end if;
   end if;

   /* perform the correct ROQ calculation by replenishment method */
   if LP_repl_method = 'C' then
      if NOT GET_LOCN_NEED_CONSTANT (O_error_message) then
         return FALSE;
      end if;

   elsif LP_repl_method = 'M' then
      if NOT GET_LOCN_NEED_MIN_MAX (O_error_message) then
         return FALSE;
      end if;

   elsif LP_repl_method = 'F' then
      if NOT GET_LOCN_NEED_FLOATING_POINT (O_error_message) then
         return FALSE;
      end if;
      if L_service_level_type = LP_srvce_lvl_type_simple_sales then
         if CALCULATE_FORECAST_FOR_PERIOD (O_error_message,
                                           L_forecast,
                                           LP_locn,
                                           I_last_delivery_date,
                                           LP_item,
                                           I_domain_id,
                                           I_next_delivery_date,
                                           NULL) = FALSE then
            return FALSE;
         end if;
         LP_safety_stock := L_forecast * (NVL(LP_service_level,0)/100);
      end if;

   elsif LP_repl_method = 'SO' then
      if NOT GET_STORE_ORDERS(O_error_message) then
         return FALSE;
      end if;

   elsif LP_repl_method = 'T' then
      if LP_locn_type = 'W' then
         LP_order_point := LEAST(GREATEST(LP_store_need, LP_pres_stock),99999999.9999);
         LP_order_up_to_point := LEAST(GREATEST(LP_store_need, LP_pres_stock),99999999.9999);
         ---
         LP_roq :=  LP_order_up_to_point - LP_net_inventory;
      else
         if NOT GET_LOCN_NEED_TIME_SUPPLY (O_error_message,
                                           I_domain_id) then
            return FALSE;
         end if;
      end if;

   elsif LP_repl_method = 'D' then
      if LP_locn_type = 'W' then
         LP_order_point := LEAST(GREATEST(LP_store_need, LP_pres_stock),99999999.9999);
         LP_order_up_to_point := LEAST(GREATEST(LP_store_need, LP_pres_stock),99999999.9999);
         ---
         LP_roq :=  LP_order_up_to_point - LP_net_inventory;

         if LP_due_ord_process_ind = 'N' then
            if LP_roq > 0 then
               LP_due_ind := 'Y';
            end if;
         end if;
      else
         if NOT GET_LOCN_NEED_DYNAMIC (O_error_message,
                                       I_domain_id,
                                       L_service_level_type,
                                       I_last_delivery_date,
                                       I_next_delivery_date) then
            return FALSE;
         end if;
      end if;

   elsif LP_repl_method = 'TI' then
      if NOT GET_LOCN_NEED_TIME_SUPPLY (O_error_message,
                                        I_domain_id) then
         return FALSE;
      end if;

   elsif LP_repl_method = 'DI' then
       if NOT GET_LOCN_NEED_DYNAMIC (O_error_message,
                                     I_domain_id) then
            return FALSE;
       end if;
   end if;

   if LP_repl_method != 'SO' then
      if NOT GET_STORE_ORDERS(O_error_message) then
         return FALSE;
      end if;

      if LP_roq < 0 then
         LP_roq := 0;
      end if;

      if (LP_due_ind = 'Y' and LP_store_order_due_ind = 'Y') then
         LP_roq := LP_roq + LP_store_order_roq;
      elsif (LP_due_ind = 'N' and LP_store_order_due_ind = 'Y') then
         LP_roq := LP_store_order_roq;
      end if;

      if LP_store_order_roq > 0 then
         LP_due_ind := LP_store_order_due_ind;
      end if;

   else
      LP_roq     := LP_store_order_roq;
      LP_due_ind := LP_store_order_due_ind;
   end if;

   ---
   /* If due order processing is off, the due indicator will be set
    * to No if no order is needed for the location.  Therefore, we
    * set the roq to zero and pass it out of the function */
   if LP_due_ord_process_ind = 'N' then
      if LP_due_ind = 'N' then
         LP_roq := 0;
      end if;
   end if;

   O_order_qty                 := LP_roq;
   O_order_point               := LP_order_point;
   O_order_up_to_point         := LP_order_up_to_point;
   O_net_inventory             := LP_net_inventory;
   O_safety_stock              := LP_safety_stock;
   O_lost_sales                := LP_lost_sales;

   O_due_ind                   := LP_due_ind;
   O_aso                       := LP_aso;
   O_eso                       := LP_eso;
   O_min_supply_days_forecast  := LP_min_supply_days_forecast;
   O_max_supply_days_forecast  := LP_max_supply_days_forecast;
   O_tsh_forecast              := LP_tsh_forecast;
   O_curr_olt_forecast         := LP_curr_olt_forecast;
   O_next_olt_forecast         := LP_next_olt_forecast;
   O_review_time_forecast      := LP_review_time_forecast;
   O_isd_forecast              := LP_isd_forecast;
   O_net_inventory             := LP_net_inventory;
   O_stock_on_hand             := LP_stock_on_hand;
   O_pack_comp_soh             := LP_pack_comp_soh;
   O_on_order                  := LP_on_order;
   O_in_transit_qty            := LP_in_transit_qty;
   O_pack_comp_intran          := LP_pack_comp_intran;
   O_tsf_resv_qty              := LP_tsf_resv_qty;
   O_pack_comp_resv            := LP_pack_comp_resv;
   O_tsf_expected_qty          := LP_tsf_expected_qty;
   O_pack_comp_exp             := LP_pack_comp_exp;
   O_rtv_qty                   := LP_rtv_qty;
   O_alloc_in_qty              := LP_alloc_in_qty;
   O_alloc_out_qty             := LP_alloc_out_qty;
   O_non_sellable_qty          := LP_non_sellable_qty;

   return TRUE;

EXCEPTION
when OTHERS then
   O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                         SQLERRM,
                                         'GET_REPL_ORDER_QTY_SQL.REPL_METHOD',
                                         to_char(SQLCODE));
   return FALSE;
END REPL_METHOD;
---------------------------------------------------------------------------------------
END GET_REPL_ORDER_QTY_SQL;
/

