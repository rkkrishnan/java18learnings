CREATE OR REPLACE PACKAGE BODY BUYER_WKSHT_ATTRIB_SQL AS
------------------------------------------------------------------------------
FUNCTION CALC_TOTAL(O_error_message   IN OUT   VARCHAR2,
                    O_total           IN OUT   REPL_RESULTS.UNIT_COST%TYPE,
                    I_audsid          IN       REPL_RESULTS.AUDSID%TYPE,
                    I_uom_type        IN       CODE_DETAIL.CODE%TYPE,
                    I_to_uom          IN       ITEM_MASTER.STANDARD_UOM%TYPE)
   return BOOLEAN is

   L_amount              REPL_RESULTS.UNIT_COST%TYPE := 0;
   L_supplier            ITEM_SUPP_COUNTRY.SUPPLIER%TYPE;
   L_prev_supplier       SUPS.SUPPLIER%TYPE;
   L_currency_code       SUPS.CURRENCY_CODE%TYPE;
   L_qty                 REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_item                ITEM_SUPP_COUNTRY.ITEM%TYPE;
   L_origin_country_id   ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE;
   L_uom_class           UOM_CLASS.UOM_CLASS%TYPE;
   L_repl_case           REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_ib_case             REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_manual_case         REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_repl_pallet         REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_ib_pallet           REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_manual_pallet       REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_repl_stat           REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_ib_stat             REPL_RESULTS.ORDER_ROQ%TYPE := 0;
   L_manual_stat         REPL_RESULTS.ORDER_ROQ%TYPE := 0;

   cursor C_GET_SUM_AMT is
      select SUM(order_roq * unit_cost),
             primary_repl_supplier
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and order_roq > 0
         and audsid = I_audsid
    group by primary_repl_supplier
      UNION ALL
      select SUM(order_roq * unit_cost),
             supplier
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and order_roq > 0
         and audsid = I_audsid
    group by supplier
      UNION ALL
      select SUM(order_roq * unit_cost),
             supplier
        from buyer_wksht_manual
       where status = 'W'
         and order_roq > 0
         and audsid = I_audsid
    group by supplier
      order by 2;

   cursor C_GET_NON_PACK is
      select SUM(order_roq),
             item,
             primary_repl_supplier,
             origin_country_id
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and order_roq > 0
         and audsid = I_audsid
    group by item,
             primary_repl_supplier,
             origin_country_id
      UNION ALL
      select SUM(order_roq),
             item,
             supplier,
             origin_country_id
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and order_roq > 0
         and audsid = I_audsid
    group by item,
             supplier,
             origin_country_id
      UNION ALL
      select SUM(order_roq),
             item,
             supplier,
             origin_country_id
        from buyer_wksht_manual
       where status = 'W'
         and order_roq > 0
         and audsid = I_audsid
    group by item,
             supplier,
             origin_country_id;

   cursor C_GET_REPL_QTY is
      select NVL(SUM(order_roq/case_size), 0),
             NVL(SUM(order_roq/(ti * hi * case_size)), 0)
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and order_roq > 0
         and audsid = I_audsid;

   cursor C_GET_IB_QTY is
      select NVL(SUM(order_roq/case_size), 0),
             NVL(SUM(order_roq/(ti * hi * case_size)), 0)
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and order_roq > 0
         and audsid = I_audsid;

   cursor C_GET_MANUAL_QTY is
      select NVL(SUM(order_roq/case_size), 0),
             NVL(SUM(order_roq/(ti * hi * case_size)), 0)
        from buyer_wksht_manual
       where status = 'W'
         and order_roq > 0
         and audsid = I_audsid;

   cursor C_GET_REPL_STAT is
      select NVL(SUM(r.order_roq/r.case_size * iscd.stat_cube), 0)
        from repl_results r,
             item_supp_country_dim iscd
       where r.item = iscd.item
         and r.primary_repl_supplier = iscd.supplier
         and r.origin_country_id = iscd.origin_country
         and r.repl_order_ctrl ='B'
         and r.status = 'W'
         and r.order_roq > 0
         and r.audsid = I_audsid
         and iscd.dim_object = 'CA';

   cursor C_GET_IB_STAT is
      select NVL(SUM(i.order_roq/i.case_size * iscd.stat_cube), 0)
        from ib_results i,
             item_supp_country_dim iscd
       where i.item = iscd.item
         and i.supplier = iscd.supplier
         and i.origin_country_id = iscd.origin_country
         and i.ib_order_ctrl ='B'
         and i.status = 'W'
         and i.order_roq > 0
         and i.audsid = I_audsid
         and iscd.dim_object = 'CA';

   cursor C_GET_MANUAL_STAT is
      select NVL(SUM(b.order_roq/b.case_size * iscd.stat_cube), 0)
        from buyer_wksht_manual b,
             item_supp_country_dim iscd
       where b.item = iscd.item
         and b.supplier = iscd.supplier
         and b.origin_country_id = iscd.origin_country
         and b.status = 'W'
         and b.order_roq > 0
         and b.audsid = I_audsid
         and iscd.dim_object = 'CA';

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_total := 0;

   if I_uom_type = 'AMNT' then
      SQL_LIB.SET_MARK('OPEN','C_GET_SUM_AMT', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                      'AUDSID: '||to_char(I_audsid));
      open C_GET_SUM_AMT;
      LOOP
         SQL_LIB.SET_MARK('FETCH','C_GET_SUM_AMT', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                         'AUDSID: '||to_char(I_audsid));
         fetch C_GET_SUM_AMT into L_amount,
                                  L_supplier;
         Exit when C_GET_SUM_AMT%NOTFOUND;

         if L_prev_supplier != L_supplier or L_prev_supplier is NULL then
            if SUPP_ATTRIB_SQL.GET_CURRENCY_CODE(O_error_message,
                                                 L_currency_code,
                                                 L_supplier) = FALSE then
               return FALSE;
            end if;
         end if;

         if L_currency_code != I_to_uom then
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_amount,
                                    L_currency_code,
                                    I_to_uom,
                                    L_amount,
                                    'C',
                                    NULL,
                                    NULL) = FALSE then
               return FALSE;
            end if;
         end if;
         L_prev_supplier := L_supplier;
         O_total := O_total + L_amount;
      END LOOP;
      SQL_LIB.SET_MARK('CLOSE','C_GET_SUM_AMT', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                      'AUDSID: '||to_char(I_audsid));
      close C_GET_SUM_AMT;
   else  /* I_uom_type = 'QTY'- all non-currency uom types which include packs, pallets and stat cases */
      if I_to_uom != 'STAT' then
         if UOM_SQL.GET_CLASS(O_error_message,
                              L_uom_class,
                              I_to_uom) = FALSE then
            return FALSE;
         end if;
      end if;

      if L_uom_class != 'PACK' then
         SQL_LIB.SET_MARK('OPEN','C_GET_NON_PACK', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                         'AUDSID: '||to_char(I_audsid));
         open C_GET_NON_PACK;
         LOOP
            SQL_LIB.SET_MARK('FETCH','C_GET_NON_PACK', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                            'AUDSID: '||to_char(I_audsid));
            fetch C_GET_NON_PACK into L_qty,
                                      L_item,
                                      L_supplier,
                                      L_origin_country_id;
            Exit when C_GET_NON_PACK%NOTFOUND;

            if UOM_SQL.CONVERT(O_error_message,
                               L_qty,
                               I_to_uom,
                               L_qty,
                               NULL,
                               L_item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            O_total := O_total + L_qty;
         END LOOP;
         SQL_LIB.SET_MARK('CLOSE','C_GET_NON_PACK', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                         'AUDSID: '||to_char(I_audsid));
         close C_GET_NON_PACK;
      elsif I_to_uom != 'STAT' then  /* the UOM class is 'PACK' or the I_to_uom is pallet */
         SQL_LIB.SET_MARK('OPEN','C_GET_REPL_QTY', 'REPL_RESULTS', 'AUDSID: '||to_char(I_audsid));
         open C_GET_REPL_QTY;
         SQL_LIB.SET_MARK('FETCH','C_GET_REPL_QTY', 'REPL_RESULTS', 'AUDSID: '||to_char(I_audsid));
         fetch C_GET_REPL_QTY into L_repl_case,
                                   L_repl_pallet;
         SQL_LIB.SET_MARK('CLOSE','C_GET_REPL_QTY', 'REPL_RESULTS', 'AUDSID: '||to_char(I_audsid));
         close C_GET_REPL_QTY;

         SQL_LIB.SET_MARK('OPEN','C_GET_IB_QTY', 'IB_RESULTS', 'AUDSID: '||to_char(I_audsid));
         open C_GET_IB_QTY;
         SQL_LIB.SET_MARK('FETCH','C_GET_IB_QTY', 'IB_RESULTS', 'AUDSID: '||to_char(I_audsid));
         fetch C_GET_IB_QTY into L_ib_case,
                                 L_ib_pallet;
         SQL_LIB.SET_MARK('CLOSE','C_GET_IB_QTY', 'IB_RESULTS', 'AUDSID: '||to_char(I_audsid));
         close C_GET_IB_QTY;

         SQL_LIB.SET_MARK('OPEN','C_GET_MANUAL_QTY', 'BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
         open C_GET_MANUAL_QTY;
         SQL_LIB.SET_MARK('FETCH','C_GET_MANUAL_QTY', 'BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
         fetch C_GET_MANUAL_QTY into L_manual_case,
                                     L_manual_pallet;
         SQL_LIB.SET_MARK('CLOSE','C_GET_MANUAL_QTY', 'BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
         close C_GET_MANUAL_QTY;

         if I_to_uom != 'PAL' then
            O_total := L_repl_case + L_ib_case + L_manual_case;
         else
            O_total := L_repl_pallet + L_ib_pallet + L_manual_pallet;
         end if;
      else /* I_to_uom is stat case */
         SQL_LIB.SET_MARK('OPEN','C_GET_REPL_STAT', 'REPL_RESULTS', 'AUDSID: '||to_char(I_audsid));
         open C_GET_REPL_STAT;
         SQL_LIB.SET_MARK('FETCH','C_GET_REPL_STAT', 'REPL_RESULTS', 'AUDSID: '||to_char(I_audsid));
         fetch C_GET_REPL_STAT into L_repl_stat;
         SQL_LIB.SET_MARK('CLOSE','C_GET_REPL_STAT', 'REPL_RESULTS', 'AUDSID: '||to_char(I_audsid));
         close C_GET_REPL_STAT;

         SQL_LIB.SET_MARK('OPEN','C_GET_IB_STAT', 'IB_RESULTS', 'AUDSID: '||to_char(I_audsid));
         open C_GET_IB_STAT;
         SQL_LIB.SET_MARK('FETCH','C_GET_IB_STAT', 'IB_RESULTS', 'AUDSID: '||to_char(I_audsid));
         fetch C_GET_IB_STAT into L_ib_stat;
         SQL_LIB.SET_MARK('CLOSE','C_GET_IB_STAT', 'IB_RESULTS', 'AUDSID: '||to_char(I_audsid));
         close C_GET_IB_STAT;

         SQL_LIB.SET_MARK('OPEN','C_GET_MANUAL_STAT', 'BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
         open C_GET_MANUAL_STAT;
         SQL_LIB.SET_MARK('FETCH','C_GET_MANUAL_STAT', 'BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
         fetch C_GET_MANUAL_STAT into L_manual_stat;
         SQL_LIB.SET_MARK('CLOSE','C_GET_MANUAL_STAT', 'BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
         close C_GET_MANUAL_STAT;

         O_total := L_repl_stat + L_ib_stat + L_manual_stat;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.CALC_TOTAL',
                                            to_char(SQLCODE));
      return FALSE;
END CALC_TOTAL;
------------------------------------------------------------------------------
FUNCTION CHECK_ADD_TO_PO(O_error_message            IN OUT   VARCHAR2,
                         O_selected_exists          IN OUT   BOOLEAN,
                         O_dup_source_type_exists   IN OUT   BOOLEAN,
                         O_mult_supp_exists         IN OUT   BOOLEAN,
                         O_mult_item_cntry_exists   IN OUT   BOOLEAN,
                         O_mult_unit_cost_exists    IN OUT   BOOLEAN,
                         O_zero_qty_exists          IN OUT   BOOLEAN,
                         I_audsid                   IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_supplier                REPL_RESULTS.PRIMARY_REPL_SUPPLIER%TYPE;
   L_mult_pool_supp_exists   BOOLEAN;
   L_pool_supplier           REPL_RESULTS.POOL_SUPPLIER%TYPE;
   L_mult_dept_exists        BOOLEAN;
   L_dept                    REPL_RESULTS.DEPT%TYPE;
   L_mult_loc_exists         BOOLEAN;
   L_location                REPL_RESULTS.LOCATION%TYPE;
   L_loc_type                REPL_RESULTS.LOC_TYPE%TYPE;
   L_vwh                     REPL_RESULTS.LOCATION%TYPE;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if CHECK_ID(O_error_message,
               O_selected_exists,
               I_audsid) = FALSE then
      return FALSE;
   end if;

   if O_selected_exists = FALSE then
      return TRUE;
   end if;

   /* Check if multiple replenishment and investment buy source type, item, */
   /* supplier, origin country and location worksheet items have been selected */

   if DUP_SOURCE_TYPE_EXISTS(O_error_message,
                             O_dup_source_type_exists,
                             I_audsid) = FALSE then
      return FALSE;
   end if;

   if O_dup_source_type_exists = TRUE then
      return TRUE;
   end if;

   /* Before accessing the PO List Window on the Buyer Worksheet form */
   /* check that the line items selected are from the same supplier, */
   /* if the same item is selected more than once that the line items */
   /* have the same origin country, if the same item and location is */
   /* selected more than once that the line items have the same unit cost. */

   if CHECK_MULT_EXISTS(O_error_message,
                        O_mult_supp_exists,
                        L_supplier,
                        L_mult_pool_supp_exists,
                        L_pool_supplier,
                        O_mult_item_cntry_exists,
                        O_mult_unit_cost_exists,
                        L_mult_dept_exists,
                        L_dept,
                        L_mult_loc_exists,
                        L_location,
                        L_loc_type,
                        L_vwh,
                        'Y',   --- check for multiple suppliers
                        'N',   --- check for multiple pool suppliers
                        'Y',   --- check for multiple item/countries
                        'Y',   --- check for multiple item/loc/unit costs
                        'N',   --- check for multiple departments
                        'N',   --- check for multiple locations,
                        'Y',   --- exits the function as soon as multiple info is found
                        I_audsid) = FALSE then
      return FALSE;
   end if;

   if O_mult_supp_exists = TRUE or O_mult_item_cntry_exists = TRUE
      or O_mult_unit_cost_exists = TRUE then
      return TRUE;
   end if;

   if CHECK_ORDER_QTY(O_error_message,
                      O_zero_qty_exists,
                      I_audsid) = FALSE then
      return FALSE;
    end if;

    return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.CHECK_ADD_TO_PO',
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_ADD_TO_PO;
------------------------------------------------------------------------------
FUNCTION CHECK_ID(O_error_message   IN OUT   VARCHAR2,
                  O_exists          IN OUT   BOOLEAN,
                  I_audsid          IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_dummy   VARCHAR2(1);

   cursor C_CHECK_ID is
      select 'x'
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION ALL
      select 'x'
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION ALL
      select 'x'
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_CHECK_ID', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
   open C_CHECK_ID;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ID', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
   fetch C_CHECK_ID into L_dummy;
   ---
   O_exists := C_CHECK_ID%FOUND;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ID', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
   close C_CHECK_ID;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.CHECK_ID',
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_ID;
------------------------------------------------------------------------------
FUNCTION CHECK_MULT_EXISTS(O_error_message            IN OUT   VARCHAR2,
                           O_mult_supp_exists         IN OUT   BOOLEAN,
                           O_supplier                 IN OUT   REPL_RESULTS.PRIMARY_REPL_SUPPLIER%TYPE,
                           O_mult_pool_supp_exists    IN OUT   BOOLEAN,
                           O_pool_supplier            IN OUT   REPL_RESULTS.POOL_SUPPLIER%TYPE,
                           O_mult_item_cntry_exists   IN OUT   BOOLEAN,
                           O_mult_unit_cost_exists    IN OUT   BOOLEAN,
                           O_mult_dept_exists         IN OUT   BOOLEAN,
                           O_dept                     IN OUT   REPL_RESULTS.DEPT%TYPE,
                           O_mult_loc_exists          IN OUT   BOOLEAN,
                           O_location                 IN OUT   REPL_RESULTS.LOCATION%TYPE,
                           O_loc_type                 IN OUT   REPL_RESULTS.LOC_TYPE%TYPE,
                           O_vwh                      IN OUT   REPL_RESULTS.LOCATION%TYPE,
                           I_check_supp               IN       VARCHAR2,
                           I_check_pool_supp          IN       VARCHAR2,
                           I_check_item               IN       VARCHAR2,
                           I_check_unit_cost          IN       VARCHAR2,
                           I_check_dept               IN       VARCHAR2,
                           I_check_loc                IN       VARCHAR2,
                           I_exit_when_mult           IN       VARCHAR2,
                           I_audsid                   IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_item                  BUYER_WKSHT_MANUAL.ITEM%TYPE;
   L_origin_country_id     BUYER_WKSHT_MANUAL.ORIGIN_COUNTRY_ID%TYPE;
   L_prev_item             BUYER_WKSHT_MANUAL.ITEM%TYPE;
   L_prev_origin_country   BUYER_WKSHT_MANUAL.ORIGIN_COUNTRY_ID%TYPE;
   L_location              BUYER_WKSHT_MANUAL.LOCATION%TYPE;
   L_prev_location         BUYER_WKSHT_MANUAL.LOCATION%TYPE;
   L_prev_vwh              BUYER_WKSHT_MANUAL.LOCATION%TYPE;
   L_vwh                   NUMBER := -1;
   L_unit_cost             BUYER_WKSHT_MANUAL.UNIT_COST%TYPE;
   L_prev_unit_cost        BUYER_WKSHT_MANUAL.UNIT_COST%TYPE;

   cursor C_CHECK_SUPP is
      select primary_repl_supplier supplier
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select supplier
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select supplier
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid;

   cursor C_CHECK_POOL_SUPP is
      select pool_supplier
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select pool_supplier
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select pool_supplier
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid;

   cursor C_CHECK_ITEM_CNTRY is
      select item,
             origin_country_id
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select item,
             origin_country_id
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select item,
             origin_country_id
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid;

   cursor C_CHECK_UNIT_COST is
      select item,
             location,
             unit_cost
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select item,
             location,
             unit_cost
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select item,
             location,
             unit_cost
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid;

   cursor C_CHECK_DEPT is
      select dept
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select dept
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select dept
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid;

   cursor C_CHECK_LOC is
      select NVL(physical_wh, location),
             loc_type,
             DECODE(loc_type, 'W', location, NULL)
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select NVL(physical_wh, location),
             loc_type,
             DECODE(loc_type, 'W', location, NULL) virtual_wh
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select NVL(physical_wh, location),
             loc_type,
             DECODE(loc_type, 'W', location, NULL) virtual_wh
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_mult_supp_exists       := FALSE;
   O_mult_pool_supp_exists  := FALSE;
   O_mult_item_cntry_exists := FALSE;
   O_mult_unit_cost_exists  := FALSE;
   O_mult_dept_exists       := FALSE;
   O_mult_loc_exists        := FALSE;

   if I_check_supp = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_SUPP', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      open C_CHECK_SUPP;
      ---
      LOOP
         SQL_LIB.SET_MARK('FETCH','C_CHECK_SUPP', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                          'AUDSID: '||to_char(I_audsid));
         fetch C_CHECK_SUPP into O_supplier;

         if C_CHECK_SUPP%ROWCOUNT > 1 then
            O_mult_supp_exists := TRUE;
            O_supplier := NULL;

            if I_exit_when_mult = 'Y' then
               SQL_LIB.SET_MARK('CLOSE','C_CHECK_SUPP', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                                'AUDSID: '||to_char(I_audsid));
               close C_CHECK_SUPP;
               return TRUE;
            end if;
         end if;

         Exit when C_CHECK_SUPP%ROWCOUNT > 1 or C_CHECK_SUPP%NOTFOUND;
      END LOOP;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_SUPP', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      close C_CHECK_SUPP;
   end if;

   if O_mult_supp_exists = TRUE and I_check_pool_supp = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_POOL_SUPP', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      open C_CHECK_POOL_SUPP;
      ---
      LOOP
         SQL_LIB.SET_MARK('FETCH','C_CHECK_POOL_SUPP', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                          'AUDSID: '||to_char(I_audsid));
         fetch C_CHECK_POOL_SUPP into O_pool_supplier;

         if C_CHECK_POOL_SUPP%ROWCOUNT > 1 then
            O_mult_pool_supp_exists := TRUE;
            O_pool_supplier := NULL;
         end if;

         Exit when C_CHECK_POOL_SUPP%ROWCOUNT > 1 or C_CHECK_POOL_SUPP%NOTFOUND;
      END LOOP;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_POOL_SUPP', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      close C_CHECK_POOL_SUPP;
   end if;

   if I_check_item = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_ITEM_CNTRY', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      open C_CHECK_ITEM_CNTRY;
      ---
      LOOP
         SQL_LIB.SET_MARK('FETCH','C_CHECK_ITEM_CNTRY', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                          'AUDSID: '||to_char(I_audsid));
         fetch C_CHECK_ITEM_CNTRY into L_item,
                                       L_origin_country_id;
         Exit when C_CHECK_ITEM_CNTRY%NOTFOUND;

         if L_prev_item = L_item and L_prev_origin_country != L_origin_country_id then
            O_mult_item_cntry_exists := TRUE;

            if I_exit_when_mult = 'Y' then
               SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_CNTRY', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                                'AUDSID: '||to_char(I_audsid));
               close C_CHECK_ITEM_CNTRY;
               return TRUE;
            end if;

            Exit;
         end if;

         L_prev_item           := L_item;
         L_prev_origin_country := L_origin_country_id;
      END LOOP;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_CNTRY', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      close C_CHECK_ITEM_CNTRY;
   end if;

   if I_check_unit_cost = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_UNIT_COST', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      open C_CHECK_UNIT_COST;
      ---
      LOOP
         SQL_LIB.SET_MARK('FETCH','C_CHECK_UNIT_COST', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                          'AUDSID: '||to_char(I_audsid));
         fetch C_CHECK_UNIT_COST into L_item,
                                      L_location,
                                      L_unit_cost;
         Exit when C_CHECK_UNIT_COST%NOTFOUND;

         if L_prev_item = L_item and L_prev_location = L_location
            and L_prev_unit_cost != L_unit_cost then
            O_mult_unit_cost_exists := TRUE;

            if I_exit_when_mult = 'Y' then
               SQL_LIB.SET_MARK('CLOSE','C_CHECK_UNIT_COST', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                                'AUDSID: '||to_char(I_audsid));
               close C_CHECK_UNIT_COST;
               return TRUE;
            end if;

            Exit;
         end if;

         L_prev_item      := L_item;
         L_prev_location  := L_location;
         L_prev_unit_cost := L_unit_cost;
      END LOOP;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_UNIT_COST', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      close C_CHECK_UNIT_COST;
   end if;

   if I_check_dept = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_DEPT', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      open C_CHECK_DEPT;
      ---
      LOOP
         SQL_LIB.SET_MARK('FETCH','C_CHECK_DEPT', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                          'AUDSID: '||to_char(I_audsid));
         fetch C_CHECK_DEPT into O_dept;

         if C_CHECK_DEPT%ROWCOUNT > 1 then
            O_mult_dept_exists := TRUE;
            O_dept := NULL;
         end if;

         Exit when C_CHECK_DEPT%ROWCOUNT > 1 or C_CHECK_DEPT%NOTFOUND;
      END LOOP;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_DEPT', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      close C_CHECK_DEPT;
   end if;

   if I_check_loc = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_CHECK_LOC', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      open C_CHECK_LOC;
      ---
      LOOP
         SQL_LIB.SET_MARK('FETCH','C_CHECK_LOC', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                          'AUDSID: '||to_char(I_audsid));
         fetch C_CHECK_LOC into O_location,
                                O_loc_type,
                                O_vwh;
         Exit when C_CHECK_LOC%NOTFOUND;

         if L_prev_location != O_location then
            O_mult_loc_exists := TRUE;
            O_location := NULL;
            O_loc_type := NULL;
            O_vwh := NULL;

            SQL_LIB.SET_MARK('CLOSE','C_CHECK_LOC', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                             'AUDSID: '||to_char(I_audsid));
            close C_CHECK_LOC;
            return TRUE;
         end if;

         L_prev_location := O_location;

         /* If the same physical wh has been selected, then check if multiple virtual wh's */
         /* have been selected. If a virtual wh has been selected and the previous wh is */
         /* the same as the current wh, set L_prev_vwh. Otherwise, if the previous wh is */
         /* different from the current wh, set L_vwh to NULL.  O_vwh will then be passed */
         /* out as NULL. */
         if O_vwh is NOT NULL and L_vwh is NOT NULL then
            if L_prev_vwh != O_vwh then
               L_vwh := NULL;
            else
               L_prev_vwh := O_vwh;
            end if;
         end if;
      END LOOP;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_LOC', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                       'AUDSID: '||to_char(I_audsid));
      close C_CHECK_LOC;

      if L_vwh is NULL then
         O_vwh := NULL;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.CHECK_MULT_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_MULT_EXISTS;
------------------------------------------------------------------------------
FUNCTION CHECK_ORDER_QTY(O_error_message   IN OUT   VARCHAR2,
                         O_exists          IN OUT   BOOLEAN,
                         I_audsid          IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_dummy   VARCHAR2(1);

   cursor C_CHECK_QTY is
      select 'x'
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and order_roq <= 0
         and audsid = I_audsid
      UNION ALL
      select 'x'
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and order_roq <= 0
         and audsid = I_audsid
      UNION ALL
      select 'x'
        from buyer_wksht_manual
       where status = 'W'
         and order_roq <= 0
         and audsid = I_audsid;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_CHECK_QTY', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
   open C_CHECK_QTY;
   ---
   SQL_LIB.SET_MARK('FETCH','C_CHECK_QTY', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
   fetch C_CHECK_QTY into L_dummy;
   ---
   if C_CHECK_QTY%NOTFOUND then
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_QTY', 'REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL', 'AUDSID: '||to_char(I_audsid));
   close C_CHECK_QTY;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.CHECK_ORDER_QTY',
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_ORDER_QTY;
------------------------------------------------------------------------------
FUNCTION CHECK_PO_UNIT_COST(O_error_message           IN OUT   VARCHAR2,
                            O_mult_unit_cost_exists   IN OUT   BOOLEAN,
                            I_order_no                IN       ORDHEAD.ORDER_NO%TYPE,
                            I_audsid                  IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_dummy   VARCHAR2(1);

   cursor C_UNIT_COST is
      select 'x'
        from ordloc ol
       where ol.order_no = I_order_no
         and exists (select 'x'
                       from repl_results r
                      where r.repl_order_ctrl = 'B'
                        and r.status = 'W'
                        and r.audsid = I_audsid
                        and r.item = ol.item
                        and r.location = ol.location
                        and r.unit_cost != ol.unit_cost
                     UNION ALL
                     select 'x'
                       from ib_results i
                      where i.ib_order_ctrl = 'B'
                        and i.status = 'W'
                        and i.audsid = I_audsid
                        and i.item = ol.item
                        and i.location = ol.location
                        and i.unit_cost != ol.unit_cost
                     UNION ALL
                     select 'x'
                       from buyer_wksht_manual b
                      where b.status = 'W'
                        and b.audsid = I_audsid
                        and b.item = ol.item
                        and b.location = ol.location
                        and b.unit_cost != ol.unit_cost);

BEGIN
   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_order_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_mult_unit_cost_exists := FALSE;

   SQL_LIB.SET_MARK('OPEN','C_UNIT_COST', 'ORDSKU, REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                    'ORDER_NO: '||to_char(I_order_no)||', AUDSID: '||to_char(I_audsid));
   open C_UNIT_COST;
   ---
   SQL_LIB.SET_MARK('FETCH','C_UNIT_COST', 'ORDSKU, REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                    'ORDER_NO: '||to_char(I_order_no)||', AUDSID: '||to_char(I_audsid));
   fetch C_UNIT_COST into L_dummy;
   ---
   if C_UNIT_COST%FOUND then
      O_mult_unit_cost_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_UNIT_COST', 'ORDSKU, REPL_RESULTS, IB_RESULTS, BUYER_WKSHT_MANUAL',
                    'ORDER_NO: '||to_char(I_order_no)||', AUDSID: '||to_char(I_audsid));
   close C_UNIT_COST;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.CHECK_PO_UNIT_COST',
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_PO_UNIT_COST;
------------------------------------------------------------------------------
FUNCTION CONSTRAINTS_AND_CALC(O_error_message           IN OUT   VARCHAR2,
                              O_exists                  IN OUT   BOOLEAN,
                              O_supplier                IN OUT   SUPS.SUPPLIER%TYPE,
                              O_sup_name                IN OUT   SUPS.SUP_NAME%TYPE,
                              O_scale_cnstr_type1       IN OUT   SUP_INV_MGMT.SCALE_CNSTR_TYPE1%TYPE,
                              O_scale_cnstr_uom1        IN OUT   SUP_INV_MGMT.SCALE_CNSTR_UOM1%TYPE,
                              O_scale_cnstr_curr1       IN OUT   SUP_INV_MGMT.SCALE_CNSTR_CURR1%TYPE,
                              O_scale_cnstr_min_val1    IN OUT   SUP_INV_MGMT.SCALE_CNSTR_MIN_VAL1%TYPE,
                              O_scale_cnstr_max_val1    IN OUT   SUP_INV_MGMT.SCALE_CNSTR_MAX_VAL1%TYPE,
                              O_actual1                 IN OUT   SUP_INV_MGMT.SCALE_CNSTR_MIN_VAL1%TYPE,
                              O_scale_cnstr_type2       IN OUT   SUP_INV_MGMT.SCALE_CNSTR_TYPE2%TYPE,
                              O_scale_cnstr_uom2        IN OUT   SUP_INV_MGMT.SCALE_CNSTR_UOM2%TYPE,
                              O_scale_cnstr_curr2       IN OUT   SUP_INV_MGMT.SCALE_CNSTR_CURR2%TYPE,
                              O_scale_cnstr_min_val2    IN OUT   SUP_INV_MGMT.SCALE_CNSTR_MIN_VAL2%TYPE,
                              O_scale_cnstr_max_val2    IN OUT   SUP_INV_MGMT.SCALE_CNSTR_MAX_VAL2%TYPE,
                              O_actual2                 IN OUT   SUP_INV_MGMT.SCALE_CNSTR_MIN_VAL2%TYPE,
                              O_total                   IN OUT   SUP_INV_MGMT.SCALE_CNSTR_MIN_VAL2%TYPE,
                              I_audsid                  IN       REPL_RESULTS.AUDSID%TYPE,
                              I_uom_type                IN       CODE_DETAIL.CODE%TYPE,
                              I_to_uom                  IN       ITEM_MASTER.STANDARD_UOM%TYPE)
   return BOOLEAN is

   L_mult_supp_exists         BOOLEAN;
   L_mult_pool_supp_exists    BOOLEAN;
   L_pool_supplier            SUP_INV_MGMT.POOL_SUPPLIER%TYPE;
   L_mult_item_cntry_exists   BOOLEAN;
   L_mult_unit_cost_exists    BOOLEAN;
   L_mult_dept_exists         BOOLEAN;
   L_dept                     REPL_RESULTS.DEPT%TYPE;
   L_mult_loc_exists          BOOLEAN;
   L_location                 REPL_RESULTS.LOCATION%TYPE;
   L_loc_type                 REPL_RESULTS.LOC_TYPE%TYPE;
   L_vwh                      REPL_RESULTS.LOCATION%TYPE;
   L_multichannel_ind         SYSTEM_OPTIONS.MULTICHANNEL_IND%TYPE;
   L_mult_phys_wh_exists      BOOLEAN;
   L_physical_wh              REPL_RESULTS.PHYSICAL_WH%TYPE;
   L_scale_cnstr_ind          SUP_INV_MGMT.SCALE_CNSTR_IND%TYPE;
   L_scale_cnstr_lvl          SUP_INV_MGMT.SCALE_CNSTR_LVL%TYPE;
   L_scale_cnstr_obj          SUP_INV_MGMT.SCALE_CNSTR_OBJ%TYPE;
   L_scale_cnstr_min_tol1     SUP_INV_MGMT.SCALE_CNSTR_MIN_TOL1%TYPE;
   L_scale_cnstr_max_tol1     SUP_INV_MGMT.SCALE_CNSTR_MAX_TOL1%TYPE;
   L_scale_cnstr_min_tol2     SUP_INV_MGMT.SCALE_CNSTR_MIN_TOL2%TYPE;
   L_scale_cnstr_max_tol2     SUP_INV_MGMT.SCALE_CNSTR_MAX_TOL2%TYPE;
   L_uom_type                 CODE_DETAIL.CODE%TYPE;
   L_to_uom                   ITEM_MASTER.STANDARD_UOM%TYPE;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_exists := TRUE;

   if I_uom_type is NOT NULL and I_to_uom is NOT NULL then
      if CALC_TOTAL(O_error_message,
                    O_total,
                    I_audsid,
                    I_uom_type,
                    I_to_uom) = FALSE then
         return FALSE;
      end if;
   end if;

   /* The below function will check if multiple suppliers have been selected.  */
   /* If so, then a check will be made to see if multiple pool suppliers have */
   /* been selected.  Also, a check will be made to see if multiple departments */
   /* and locations have been selected.  This will determine which scaling constraints */
   /* to retrieve.  For example, if multiple suppliers, the same pool supplier, */
   /* multiple departments and the same physical warehouse were selected, then the scaling */
   /* constraints retrieved would be those at the supplier/location level where the supplier */
   /* is the pool supplier and the location is the physical warehouse. */

   if CHECK_MULT_EXISTS(O_error_message,
                        L_mult_supp_exists,
                        O_supplier,
                        L_mult_pool_supp_exists,
                        L_pool_supplier,
                        L_mult_item_cntry_exists,
                        L_mult_unit_cost_exists,
                        L_mult_dept_exists,
                        L_dept,
                        L_mult_loc_exists,
                        L_location,
                        L_loc_type,
                        L_vwh,
                        'Y',   --- check for multiple suppliers
                        'Y',   --- check for multiple pool suppliers
                        'N',   --- check for multiple item/countries
                        'N',   --- check for multiple item/loc/unit costs
                        'Y',   --- check for multiple departments
                        'Y',   --- check for multiple locations
                        'N',   --- will not exit the function when multiple info is found
                        I_audsid) = FALSE then
      return FALSE;
   end if;

   /* If multiple suppliers were selected, check if the worksheet items have the same */
   /* pool supplier. If so, retrieve scaling constraints for the pool supplier. */
   if L_mult_supp_exists = TRUE then
      /* if multiple pool suppliers exist or no pool supplier exists for the selected */
      /* line items, do not retrieve scaling constraints */
      if L_mult_pool_supp_exists = TRUE or L_pool_supplier is NULL then
         O_exists := FALSE;
         O_supplier := NULL;
         return TRUE;
      elsif L_pool_supplier is NOT NULL then
         O_supplier := L_pool_supplier;
      end if;
   end if;

   if SUP_INV_MGMT_SQL.GET_SCALING_CNSTR_INFO(O_error_message,
                                              L_scale_cnstr_ind,
                                              L_scale_cnstr_lvl,
                                              L_scale_cnstr_obj,
                                              O_scale_cnstr_type1,
                                              O_scale_cnstr_uom1,
                                              O_scale_cnstr_curr1,
                                              O_scale_cnstr_min_val1,
                                              O_scale_cnstr_max_val1,
                                              L_scale_cnstr_min_tol1,
                                              L_scale_cnstr_max_tol1,
                                              O_scale_cnstr_type2,
                                              O_scale_cnstr_uom2,
                                              O_scale_cnstr_curr2,
                                              O_scale_cnstr_min_val2,
                                              O_scale_cnstr_max_val2,
                                              L_scale_cnstr_min_tol2,
                                              L_scale_cnstr_max_tol2,
                                              O_supplier,
                                              L_dept,
                                              L_location) = FALSE then
      return FALSE;
   end if;

   /* If no scaling constraints exist, exit the function */
   if O_scale_cnstr_type1 is NULL then
      O_supplier := NULL;
      O_exists := FALSE;
      return TRUE;
   end if;

   if SUPP_ATTRIB_SQL.GET_SUPP_DESC(O_error_message,
                                    O_supplier,
                                    O_sup_name) = FALSE then
      return FALSE;
   end if;

   if O_scale_cnstr_type1 = 'A' then
      L_uom_type := 'AMNT';
      L_to_uom := O_scale_cnstr_curr1;
   else
      L_uom_type := 'QTY';

      if O_scale_cnstr_type1 = 'P' then
         L_to_uom := 'PAL';
         O_scale_cnstr_uom1 := 'PAL';
      elsif O_scale_cnstr_type1 = 'C' then
         L_to_uom := 'CS';
         O_scale_cnstr_uom1 := 'CS';
      elsif O_scale_cnstr_type1 = 'E' then
         L_to_uom := 'EA';
         O_scale_cnstr_uom1 := 'EA';
      elsif O_scale_cnstr_type1 = 'S' then
         L_to_uom := 'STAT';
         O_scale_cnstr_uom1 := 'STAT';
      else
         L_to_uom := O_scale_cnstr_uom1;
      end if;
   end if;

   if CALC_TOTAL(O_error_message,
                 O_actual1,
                 I_audsid,
                 L_uom_type,
                 L_to_uom) = FALSE then
      return FALSE;
   end if;

   if O_scale_cnstr_type2 is NOT NULL then
      if O_scale_cnstr_type2 = 'A' then
         L_uom_type := 'AMNT';
         L_to_uom := O_scale_cnstr_curr2;
      else
         L_uom_type := 'QTY';

         if O_scale_cnstr_type2 = 'P' then
            L_to_uom := 'PAL';
            O_scale_cnstr_uom2 := 'PAL';
         elsif O_scale_cnstr_type2 = 'C' then
            L_to_uom := 'CS';
            O_scale_cnstr_uom2 := 'CS';
         elsif O_scale_cnstr_type2 = 'E' then
            L_to_uom := 'EA';
            O_scale_cnstr_uom2 := 'EA';
         elsif O_scale_cnstr_type2 = 'S' then
            L_to_uom := 'STAT';
            O_scale_cnstr_uom2 := 'STAT';
         else
            L_to_uom := O_scale_cnstr_uom2;
         end if;
      end if;

      if CALC_TOTAL(O_error_message,
                    O_actual2,
                    I_audsid,
                    L_uom_type,
                    L_to_uom) = FALSE then
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.CONSTRAINTS_AND_CALC',
                                            to_char(SQLCODE));
      return FALSE;
END CONSTRAINTS_AND_CALC;
------------------------------------------------------------------------------
FUNCTION DUP_EXISTS(O_error_message       IN OUT   VARCHAR2,
                    O_exists              IN OUT   BOOLEAN,
                    O_rowid               IN OUT   ROWID,
                    O_source_type         IN OUT   BUYER_WKSHT_MANUAL.SOURCE_TYPE%TYPE,
                    I_item                IN       BUYER_WKSHT_MANUAL.ITEM%TYPE,
                    I_supplier            IN       BUYER_WKSHT_MANUAL.SUPPLIER%TYPE,
                    I_origin_country_id   IN       BUYER_WKSHT_MANUAL.ORIGIN_COUNTRY_ID%TYPE,
                    I_location            IN       BUYER_WKSHT_MANUAL.LOCATION%TYPE)
   return BOOLEAN is

   L_date   DATE;

   cursor C_EXISTS is
      select rowid,
             'R',
             MAX(repl_date)
        from repl_results
       where item = I_item
         and primary_repl_supplier = I_supplier
         and origin_country_id = I_origin_country_id
         and location = I_location
         and repl_order_ctrl = 'B'
         and status = 'W'
    group by rowid
      UNION ALL
      select rowid,
             'M',
             create_date
        from buyer_wksht_manual
       where item = I_item
         and supplier = I_supplier
         and origin_country_id = I_origin_country_id
         and location = I_location
         and status = 'W';

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_location',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_EXISTS','REPL_RESULTS, BUYER_WKSHT_MANUAL','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id
                    ||', Location: '|| to_char(I_location));
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_EXISTS','REPL_RESULTS, BUYER_WKSHT_MANUAL','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id
                    ||', Location: '|| to_char(I_location));
   fetch C_EXISTS into O_rowid,
                       O_source_type,
                       L_date;
   ---
   O_exists := C_EXISTS%FOUND;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS','REPL_RESULTS, BUYER_WKSHT_MANUAL','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id
                    ||', Location: '|| to_char(I_location));
   close C_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.DUP_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;
END DUP_EXISTS;
------------------------------------------------------------------------------
FUNCTION DUP_SOURCE_TYPE_EXISTS(O_error_message   IN OUT   VARCHAR2,
                                O_exists          IN OUT   BOOLEAN,
                                I_audsid          IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_count_repl   NUMBER(3);
   L_count_ib     NUMBER(3);

   cursor C_REPL_EXISTS is
      select MAX(COUNT(source_type))
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
    group by item, primary_repl_supplier, origin_country_id, location, stock_cat;

   cursor C_IB_EXISTS is
      select MAX(COUNT(source_type))
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
    group by item, supplier, origin_country_id, location;

BEGIN
   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_exists := FALSE;

   open C_REPL_EXISTS;
   fetch C_REPL_EXISTS into L_count_repl;
   close C_REPL_EXISTS;

   if L_count_repl > 1 then
      O_exists := TRUE;
   else
      open C_IB_EXISTS;
      fetch C_IB_EXISTS into L_count_ib;
      close C_IB_EXISTS;

      if L_count_ib > 1 then
         O_exists := TRUE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WORKSHEET_SQL.DUP_SOURCE_TYPE_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;
END DUP_SOURCE_TYPE_EXISTS;
------------------------------------------------------------------------------
FUNCTION GET_BUYER_WKSHT_MANUAL_INFO(O_error_message       IN OUT   VARCHAR2,
                                     O_dept                IN OUT   ITEM_MASTER.DEPT%TYPE,
                                     O_class               IN OUT   ITEM_MASTER.CLASS%TYPE,
                                     O_subclass            IN OUT   ITEM_MASTER.SUBCLASS%TYPE,
                                     O_item_type           IN OUT   BUYER_WKSHT_MANUAL.ITEM_TYPE%TYPE,
                                     O_comp_item           IN OUT   ITEM_MASTER.ITEM%TYPE,
                                     O_buyer               IN OUT   DEPS.BUYER%TYPE,
                                     O_pool_supplier       IN OUT   SUPS.SUPPLIER%TYPE,
                                     O_physical_wh         IN OUT   WH.WH%TYPE,
                                     O_repl_wh_link        IN OUT   WH.REPL_WH_LINK%TYPE,
                                     O_supp_lead_time      IN OUT   ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE,
                                     O_pickup_lead_time    IN OUT   ITEM_SUPP_COUNTRY_LOC.PICKUP_LEAD_TIME%TYPE,
                                     O_supp_unit_cost      IN OUT   ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE,
                                     O_supp_pack_size      IN OUT   ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE,
                                     O_ti                  IN OUT   ITEM_SUPP_COUNTRY.TI%TYPE,
                                     O_hi                  IN OUT   ITEM_SUPP_COUNTRY.HI%TYPE,
                                     I_item                IN       BUYER_WKSHT_MANUAL.ITEM%TYPE,
                                     I_supplier            IN       BUYER_WKSHT_MANUAL.SUPPLIER%TYPE,
                                     I_origin_country_id   IN       BUYER_WKSHT_MANUAL.ORIGIN_COUNTRY_ID%TYPE,
                                     I_loc_type            IN       BUYER_WKSHT_MANUAL.LOC_TYPE%TYPE,
                                     I_location            IN       BUYER_WKSHT_MANUAL.LOCATION%TYPE)
   return BOOLEAN is

   L_pack_ind           ITEM_MASTER.PACK_IND%TYPE;
   L_simple_pack_ind    ITEM_MASTER.SIMPLE_PACK_IND%TYPE;
   L_exists             BOOLEAN;
   L_qty                PACKITEM.PACK_QTY%TYPE;
   L_buyer_name         BUYER.BUYER_NAME%TYPE;

   /* placeholder variables for GET_WH_MULTI_INFO function */
   L_channel_id         WH.CHANNEL_ID%TYPE;
   L_stockholding_ind   WH.STOCKHOLDING_IND%TYPE;
   L_protect_wh_ind     WH.PROTECTED_IND%TYPE;
   L_forecast_wh_ind    WH.FORECAST_WH_IND%TYPE;
   L_rounding_seq       WH.ROUNDING_SEQ%TYPE;
   L_repl_ind           WH.REPL_IND%TYPE;
   L_repl_src_ord       WH.REPL_SRC_ORD%TYPE;
   L_ib_ind             WH.IB_IND%TYPE;
   L_ib_wh_link         WH.IB_WH_LINK%TYPE;
   L_auto_ib_clear      WH.AUTO_IB_CLEAR%TYPE;

   L_total_lead_time    ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE;
   L_primary_ind        VARCHAR2(1);

   cursor C_ITEM_INFO is
      select dept,
             class,
             subclass,
             pack_ind,
             simple_pack_ind
        from item_master
       where item = I_item;

   cursor C_GET_ITEM_SUPP_CNTRY_INFO is
      select isc.lead_time,
             iscl.pickup_lead_time,
             iscl.unit_cost,
             isc.supp_pack_size,
             isc.ti,
             isc.hi
        from item_supp_country isc,
             item_supp_country_loc iscl
       where isc.item = iscl.item
         and isc.supplier = iscl.supplier
         and isc.origin_country_id = iscl.origin_country_id
         and iscl.item = I_item
         and iscl.supplier = I_supplier
         and iscl.origin_country_id = I_origin_country_id
         and iscl.loc = I_location;

BEGIN
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_origin_country_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_loc_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_loc_type',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_location is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_location',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_ITEM_INFO','ITEM_MASTER','Item: '||I_item);
   open C_ITEM_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH','C_ITEM_INFO','ITEM_MASTER','Item: '||I_item);
   fetch C_ITEM_INFO into O_dept,
                          O_class,
                          O_subclass,
                          L_pack_ind,
                          L_simple_pack_ind;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_INFO','ITEM_MASTER','Item: '||I_item);
   if C_ITEM_INFO%NOTFOUND then
      close C_ITEM_INFO;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   close C_ITEM_INFO;

   if L_pack_ind = 'Y' then
      O_item_type := 'P';
   else
      O_item_type := 'N';
   end if;

   if L_simple_pack_ind = 'Y' then
      if PACKITEM_ATTRIB_SQL.GET_ITEM_AND_QTY(O_error_message,
                                              L_exists,
                                              O_comp_item,
                                              L_qty,
                                              I_item) = FALSE then
         return FALSE;
      end if;
   end if;

   if DEPT_ATTRIB_SQL.GET_BUYER(O_error_message,
                                O_buyer,
                                L_buyer_name,
                                O_dept) = FALSE then
      return FALSE;
   end if;

   if SUP_INV_MGMT_SQL.GET_POOL_SUPPLIER(O_error_message,
                                         O_pool_supplier,
                                         I_supplier,
                                         O_dept,
                                         I_location) = FALSE then
      return FALSE;
   end if;

   if I_loc_type = 'W' then
      if WH_ATTRIB_SQL.GET_WH_MULTI_INFO(O_error_message,
                                         O_physical_wh,
                                         L_channel_id,
                                         L_stockholding_ind,
                                         L_protect_wh_ind,
                                         L_forecast_wh_ind,
                                         L_rounding_seq,
                                         L_repl_ind,
                                         O_repl_wh_link,
                                         L_repl_src_ord,
                                         L_ib_ind,
                                         L_ib_wh_link,
                                         L_auto_ib_clear,
                                         I_location) = FALSE then
         return FALSE;
      end if;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_SUPP_CNTRY_INFO','ITEM_SUPP_COUNTRY, ITEM_SUPP_COUNTRY_LOC',
                    'Item: '||I_item||', Supplier: '||to_char(I_supplier)||', Origin Country: '||I_origin_country_id
                    ||', Location: '||to_char(I_location));
   open C_GET_ITEM_SUPP_CNTRY_INFO;

   SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_SUPP_CNTRY_INFO','ITEM_SUPP_COUNTRY, ITEM_SUPP_COUNTRY_LOC',
                    'Item: '||I_item||', Supplier: '||to_char(I_supplier)||', Origin Country: '||I_origin_country_id
                    ||', Location: '||to_char(I_location));
   fetch C_GET_ITEM_SUPP_CNTRY_INFO into O_supp_lead_time,
                                         O_pickup_lead_time,
                                         O_supp_unit_cost,
                                         O_supp_pack_size,
                                         O_ti,
                                         O_hi;

   SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_SUPP_CNTRY_INFO','ITEM_SUPP_COUNTRY, ITEM_SUPP_COUNTRY_LOC',
                    'Item: '||I_item||', Supplier: '||to_char(I_supplier)||', Origin Country: '||I_origin_country_id
                    ||', Location: '||to_char(I_location));
   close C_GET_ITEM_SUPP_CNTRY_INFO;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.GET_BUYER_WKSHT_MANUAL_INFO',
                                            to_char(SQLCODE));
      return FALSE;
END GET_BUYER_WKSHT_MANUAL_INFO;
-----------------------------------------------------------------------------
FUNCTION NON_PROCESSED_EXISTS(O_error_message   IN OUT   VARCHAR2,
                              O_exists          IN OUT   BOOLEAN,
                              I_tsf_no          IN       TSFDETAIL.TSF_NO%TYPE)
   return BOOLEAN is

   L_dummy   VARCHAR2(1);

   cursor C_EXISTS is
      select 'x'
        from tsfdetail
       where tsf_no = I_tsf_no
         and mbr_processed_ind = 'N';

BEGIN
   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_tsf_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_exists := FALSE;

   SQL_LIB.SET_MARK('OPEN','C_EXISTS','TSFDETAIL','TSF_NO: '||to_char(I_tsf_no));
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_EXISTS','TSFDETAIL','TSF_NO: '||to_char(I_tsf_no));
   fetch C_EXISTS into L_dummy;
   ---
   if C_EXISTS%FOUND then
      O_exists := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS','TSFDETAIL','TSF_NO: '||to_char(I_tsf_no));
   close C_EXISTS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.NON_PROCESSED_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;
END NON_PROCESSED_EXISTS;
------------------------------------------------------------------------------
FUNCTION VALIDATE_ADD_ITEM(O_error_message       IN OUT   VARCHAR2,
                           O_exists              IN OUT   BOOLEAN,
                           O_unit_cost           IN OUT   ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE,
                           I_item                IN       ITEM_SUPP_COUNTRY_LOC.ITEM%TYPE,
                           I_supplier            IN       ITEM_SUPP_COUNTRY_LOC.SUPPLIER%TYPE,
                           I_origin_country_id   IN       ITEM_SUPP_COUNTRY_LOC.ORIGIN_COUNTRY_ID%TYPE,
                           I_location            IN       ITEM_SUPP_COUNTRY_LOC.LOC%TYPE)
   return BOOLEAN is

   cursor C_EXISTS is
      select iscl.unit_cost
        from item_supp_country_loc iscl, item_master im
       where iscl.item = im.item
         and iscl.item = NVL(I_item, iscl.item)
         and iscl.supplier = NVL(I_supplier, iscl.supplier)
         and iscl.origin_country_id = NVL(I_origin_country_id, iscl.origin_country_id)
         and iscl.loc = NVL(I_location, iscl.loc)
         and (iscl.loc_type = 'W'
             or (iscl.loc_type = 'S'
                 and exists (select 'x'
                               from store s
                              where s.store = iscl.loc
                                and s.stockholding_ind = 'Y')))
         and im.status = 'A'
         and im.item_level = im.tran_level
         and (im.pack_ind = 'N'
             or (im.pack_ind = 'Y' and im.pack_type = 'V'));

BEGIN
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id
                    ||', Location: '|| to_char(I_location));
   open C_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id
                    ||', Location: '|| to_char(I_location));
   fetch C_EXISTS into O_unit_cost;
   ---
   if C_EXISTS%NOTFOUND then
      O_exists := FALSE;
      O_unit_cost := NULL;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_EXISTS','ITEM_SUPP_COUNTRY_LOC','Item: '||I_item||
                    ', Supplier: '||to_char(I_supplier)||', Country: '||I_origin_country_id
                    ||', Location: '|| to_char(I_location));
   close C_EXISTS;

   if O_exists = TRUE then
      if I_item is NULL or I_supplier is NULL or I_origin_country_id is NULL
         or I_location is NULL then
         O_unit_cost := NULL;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.VALIDATE_ADD_ITEM',
                                            to_char(SQLCODE));
      return FALSE;
END VALIDATE_ADD_ITEM;
------------------------------------------------------------------------------
FUNCTION VALIDATE_PO(O_error_message   IN OUT   VARCHAR2,
                     O_valid           IN OUT   BOOLEAN,
                     I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                     I_audsid          IN       REPL_RESULTS.AUDSID%TYPE)
   return BOOLEAN is

   L_exists                   BOOLEAN;
   L_status                   ORDHEAD.STATUS%TYPE;
   L_contract_no              ORDHEAD.CONTRACT_NO%TYPE;
   L_ord_supplier             ORDHEAD.SUPPLIER%TYPE;
   L_ord_dept                 ORDHEAD.DEPT%TYPE;
   L_ord_location             ORDHEAD.LOCATION%TYPE;
   L_mult_supp_exists         BOOLEAN;
   L_supplier                 REPL_RESULTS.PRIMARY_REPL_SUPPLIER%TYPE;
   L_mult_pool_supp_exists    BOOLEAN;
   L_pool_supplier            REPL_RESULTS.POOL_SUPPLIER%TYPE;
   L_mult_item_cntry_exists   BOOLEAN;
   L_mult_unit_cost_exists    BOOLEAN;
   L_mult_dept_exists         BOOLEAN;
   L_dept                     REPL_RESULTS.DEPT%TYPE;
   L_mult_loc_exists          BOOLEAN;
   L_location                 REPL_RESULTS.LOCATION%TYPE;
   L_loc_type                 REPL_RESULTS.LOC_TYPE%TYPE;
   L_vwh                      REPL_RESULTS.LOCATION%TYPE;
   L_ordsku_exists            BOOLEAN;
   L_item                     REPL_RESULTS.ITEM%TYPE;
   L_ord_origin_country       ORDSKU.ORIGIN_COUNTRY_ID%TYPE;
   L_prepack_order            BOOLEAN;
   L_dummy                    VARCHAR2(1);
   L_ordloc_exists            BOOLEAN;
   L_single_loc_ind           ORD_INV_MGMT.SINGLE_LOC_IND%TYPE;
   L_loc_exists               BOOLEAN;

   cursor C_ORDER_INFO is
      select status,
             contract_no,
             supplier,
             dept,
             location
        from ordhead
       where order_no = I_order_no;

   cursor C_GET_ITEM is
      select item,
             origin_country_id,
             item_type
        from repl_results
       where repl_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select item,
             origin_country_id,
             item_type
        from ib_results
       where ib_order_ctrl = 'B'
         and status = 'W'
         and audsid = I_audsid
      UNION
      select item,
             origin_country_id,
             item_type
        from buyer_wksht_manual
       where status = 'W'
         and audsid = I_audsid;

   cursor C_CHECK_ITEM_DEPT is
      select 'x'
        from v_packsku_qty vpq,
             item_master im
       where vpq.pack_no = L_item
         and vpq.item = im.item
         and im.dept != L_ord_dept;

BEGIN
   if I_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_order_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_audsid is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_audsid',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_valid := TRUE;

   open C_ORDER_INFO;
   fetch C_ORDER_INFO into L_status,
                           L_contract_no,
                           L_ord_supplier,
                           L_ord_dept,
                           L_ord_location;
   if C_ORDER_INFO%NOTFOUND then
      close C_ORDER_INFO;
      O_error_message := SQL_LIB.CREATE_MSG('INV_ORDER_NO',
                          NULL,
                          NULL,
                          NULL);
      O_valid := FALSE;
      return TRUE;
   end if;
   close C_ORDER_INFO;

   if L_status != 'W' then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_STATUS',
                                            NULL,
                                            NULL,
                                            NULL);
      O_valid := FALSE;
      return TRUE;
   end if;

   if L_contract_no is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_CONTRACT',
                                            NULL,
                                            NULL,
                                            NULL);
      O_valid := FALSE;
      return TRUE;
   end if;

   /* The below function will do the following: */
   /* 1. Retrieve the line items' supplier in order to compare to the entered order's supplier. */
   /* 2. Check if multiple departments were selected.  If one department was selected */
   /*    and the order has a department specified, the two departments must be the same. */
   /*    If more than one department was selected, ensure that the order does not have a */
   /*    department specified. */
   /* 3. Check if multiple locations were selected.  If several locations were selected, */
   /*    the location value on ordhead must be null.  If one location was selected, */
   /*    the location on ordhead must either be null or populated with that particular */
   /*    location. */

   if CHECK_MULT_EXISTS(O_error_message,
                        L_mult_supp_exists,
                        L_supplier,
                        L_mult_pool_supp_exists,
                        L_pool_supplier,
                        L_mult_item_cntry_exists,
                        L_mult_unit_cost_exists,
                        L_mult_dept_exists,
                        L_dept,
                        L_mult_loc_exists,
                        L_location,
                        L_loc_type,
                        L_vwh,
                        'Y',   --- check for multiple suppliers
                        'N',   --- check for multiple pool suppliers
                        'N',   --- check for multiple item/countries
                        'N',   --- check for multiple item/loc/unit costs
                        'Y',   --- check for multiple departments
                        'Y',   --- check for multiple locations
                        'N',   --- will not exit the function when multiple info is found
                        I_audsid) = FALSE then
      return FALSE;
   end if;

   if L_supplier != L_ord_supplier then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_SUPP',
                                            to_char(L_ord_supplier),
                                            to_char(L_supplier),
                                            NULL);
      O_valid := FALSE;
      return TRUE;
   end if;

   /* If selected line items were from the same department and a department is */
   /* specified on the entered order, the worksheet department must be the same as */
   /* the order department. */
   if L_mult_dept_exists = FALSE then
      if L_dept != L_ord_dept then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_DEPT',
                                            to_char(L_ord_dept),
                                            to_char(L_dept),
                                            NULL);
         O_valid := FALSE;
         return TRUE;
      end if;
   else
      /* If selected line items were from different departments, ensure that the */
      /* order does not have a department specified. */
      if L_ord_dept is NOT NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_SINGLE_DEPT_ORD',
                                               NULL,
                                               NULL,
                                               NULL);
         O_valid := FALSE;
         return TRUE;
      end if;
   end if;

   if ORDER_ITEM_ATTRIB_SQL.ORDER_EXISTS(O_error_message,
                                         L_ordsku_exists,
                                         I_order_no) = FALSE then
      return FALSE;
   end if;

   FOR rec in C_GET_ITEM LOOP
      L_item := rec.item;

      /* If ordsku records exist, if the worksheet item already exists on the order */
      /* they both must have the same origin country.  */
      if L_ordsku_exists then
         if ORDER_ITEM_ATTRIB_SQL.GET_ORIGIN_COUNTRY(O_error_message,
                                                     L_exists,
                                                     L_ord_origin_country,
                                                     I_order_no,
                                                     L_item) = FALSE then
            return FALSE;
         end if;

         if L_exists = TRUE and rec.origin_country_id != L_ord_origin_country then
            O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_ORIGIN_CNTRY',
                                            L_item,
                                            L_ord_origin_country,
                                            rec.origin_country_id);
            O_valid := FALSE;
            return TRUE;
         end if;
      end if;

      /* If the item is a pack, it cannot be added to a fashion prepack order.  Also, */
      /* if the selected worksheet items are from the same department as the department */
      /* specified on the order the pack item's component items must be from the same department. */
      if rec.item_type = 'P' then
         if ORDER_ATTRIB_SQL.GET_PREPACK_IND(O_error_message,
                                             L_prepack_order,
                                             I_order_no) = FALSE then
            return FALSE;
         end if;

         if L_prepack_order = TRUE then
            O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_FASH_PREPACK',
                                            NULL,
                                            NULL,
                                            NULL);
            O_valid := FALSE;
            return TRUE;
         end if;

         if L_mult_dept_exists = FALSE then
            if L_ord_dept is NOT NULL then
               SQL_LIB.SET_MARK('OPEN','C_CHECK_ITEM_DEPT', 'V_PACKSKU_QTY, ITEM_MASTER',
                                'ITEM: '||L_item);
               open C_CHECK_ITEM_DEPT;
               SQL_LIB.SET_MARK('FETCH','C_CHECK_ITEM_DEPT', 'V_PACKSKU_QTY, ITEM_MASTER',
                                'ITEM: '||L_item);
               fetch C_CHECK_ITEM_DEPT into L_dummy;
               ---
               if C_CHECK_ITEM_DEPT%FOUND then
                  SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_DEPT', 'V_PACKSKU_QTY, ITEM_MASTER',
                                   'ITEM: '||L_item);
                  close C_CHECK_ITEM_DEPT;
                  O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_PACK_DEPT',
                                            L_item,
                                            to_char(L_dept),
                                            NULL);
                  O_valid := FALSE;
                  return TRUE;
               end if;
               ---
               SQL_LIB.SET_MARK('CLOSE','C_CHECK_ITEM_DEPT', 'V_PACKSKU_QTY, ITEM_MASTER',
                                'ITEM: '||L_item);
               close C_CHECK_ITEM_DEPT;
            end if;
         end if;
      end if;
   END LOOP;

   /* If the selected line items were from the same location and a location is */
   /* specified on the entered order, the worksheet location must be the same as */
   /* the order location. */
   /* L_location will either be a physical warehouse or a store.  The below code */
   /* does the following:
   /* 1.  If the location selected is a store, check if that store is on the order. */
   /*     If not, error out.
   /* 2.  If the location selected is a physical wh, check if that physical wh is */
   /*     on the order. If not, compare virtual warehouses.  If a single virtual wh */
   /*     was selected, check if that virtual wh is on the order.  If multiple */
   /*     virtual wh's were selected (L_vh is null) and the order location contains */
   /*     a value, error out. */
   if L_mult_loc_exists = FALSE then
      if (L_location != L_ord_location and
         (L_vwh != L_ord_location or (L_ord_location is NOT NULL and L_vwh is NULL))) then
         O_error_message := SQL_LIB.CREATE_MSG('INV_SINGLE_LOC_ORD',
                                               to_char(L_ord_location),
                                               NULL,
                                               NULL);
         O_valid := FALSE;
         return TRUE;
      end if;
   else
      /* If selected line items were from different locations, ensure that the */
      /* order does not have a location specified. */
      if L_ord_location is NOT NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_PO_SINGLE_LOC',
                                               NULL,
                                               NULL,
                                               NULL);
         O_valid := FALSE;
         return TRUE;
      end if;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'BUYER_WKSHT_ATTRIB_SQL.VALIDATE_PO',
                                            to_char(SQLCODE));
      return FALSE;
END VALIDATE_PO;
------------------------------------------------------------------------------
FUNCTION CHECK_AOQ(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                   I_item             IN       ITEM_SUPP_COUNTRY.ITEM%TYPE,
                   I_aoq              IN       NUMBER,
                   I_supplier         IN       ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
                   I_origin_ctry_id   IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE)
   RETURN BOOLEAN is

   L_program          VARCHAR2(61) := 'BUYER_WKSHT_ATTRIB_SQL.CHECK_AOQ';
   L_min_order_qty    ITEM_SUPP_COUNTRY.MIN_ORDER_QTY%TYPE := 0;
   L_max_order_qty    ITEM_SUPP_COUNTRY.MAX_ORDER_QTY%TYPE := 0;

   cursor C_CHECK_QTY is
      select min_order_qty,
             max_order_qty
        from item_supp_country
       where item              = I_item
         and supplier          = I_supplier
         and origin_country_id = I_origin_ctry_id;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_QTY',
                    'ITEM_SUPP_COUNTRY',
                    'ITEM : '||to_char(I_item));
   open C_CHECK_QTY;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_QTY',
                    'ITEM_SUPP_COUNTRY',
                    'ITEM : '||to_char(I_item));
   fetch C_CHECK_QTY into L_min_order_qty,
                          L_max_order_qty;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_QTY',
                    'ITEM_SUPP_COUNTRY',
                    'ITEM: '||to_char(I_item));
   close C_CHECK_QTY;

   if (L_max_order_qty < NVL(I_aoq,0)) or (NVL(I_aoq,0) < L_min_order_qty) then
      O_error_message := SQL_LIB.CREATE_MSG('ORDSKU_QTY_LIMIT1',
                                            TO_CHAR(I_item),
                                            TO_CHAR(L_min_order_qty),
                                            TO_CHAR(L_max_order_qty));
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CHECK_AOQ;
------------------------------------------------------------------------------
END BUYER_WKSHT_ATTRIB_SQL;
/

