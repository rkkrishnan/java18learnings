CREATE OR REPLACE PACKAGE BODY ITEM_XFORM_SQL AS


TYPE QTY_TO_FILL_REC is RECORD(orderable_item        ITEM_MASTER.ITEM%TYPE,
                               qty_requested         TSFDETAIL.TSF_QTY%TYPE,
                               qty_to_fill           TSFDETAIL.TSF_QTY%TYPE);

TYPE QTY_TO_FILL_TBL is TABLE OF QTY_TO_FILL_REC;
-------------------------------------------------------------------------------------------------------------
FUNCTION GET_QTY_TO_FILL(O_error_message       IN OUT        RTK_ERRORS.RTK_TEXT%TYPE,
                         IO_item_qty_tbl       IN OUT NOCOPY BTS_ORDITEM_QTY_TBL,
                         IO_qty_to_fill_tbl    IN OUT NOCOPY QTY_TO_FILL_TBL,
                         I_sell_item           IN            ITEM_MASTER.ITEM%TYPE,
                         I_sell_qty            IN            ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         I_inv_status          IN            INV_STATUS_CODES.INV_STATUS%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------------------------------------------
FUNCTION GET_QTY_TO_FILL_EG(O_error_message       IN OUT        RTK_ERRORS.RTK_TEXT%TYPE,
                            IO_item_qty_tbl       IN OUT NOCOPY BTS_ORDITEM_QTY_TBL,
                            IO_qty_to_fill_tbl    IN OUT NOCOPY QTY_TO_FILL_TBL,
                            I_sell_item           IN            ITEM_MASTER.ITEM%TYPE,
                            I_sell_qty            IN            ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                            I_inv_status          IN            INV_STATUS_CODES.INV_STATUS%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------------------------------------------
FUNCTION GET_ORDERABLE_QTY(O_error_message          IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_orderable_qty             OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                           I_sell_qty               IN     ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                           I_prod_loss_pct          IN     ITEM_XFORM_HEAD.PRODUCTION_LOSS_PCT%TYPE,
                           I_yield_from_head_pct    IN     ITEM_XFORM_DETAIL.YIELD_FROM_HEAD_ITEM_PCT%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------
FUNCTION NEXT_ITEM_XFORM_HEAD_ID(O_error_message        IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_item_xform_head_id   IN OUT   ITEM_XFORM_HEAD.ITEM_XFORM_HEAD_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60) := 'ITEM_XFORM_SQL.NEXT_ITEM_XFORM_HEAD_ID';


BEGIN



   select item_xform_head_seq.NEXTVAL
   into O_item_xform_head_id
   from sys.dual;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END NEXT_ITEM_XFORM_HEAD_ID;

-----------------------------------------------------------------------------------------------------------------
FUNCTION NEXT_ITEM_XFORM_DETAIL_ID(O_error_message          IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_item_xform_detail_id   IN OUT   ITEM_XFORM_DETAIL.ITEM_XFORM_DETAIL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60) := 'ITEM_XFORM_SQL.NEXT_ITEM_XFORM_DETAIL_ID';

BEGIN



   select item_xform_detail_seq.NEXTVAL
   into O_item_xform_detail_id
   from sys.dual;



   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END NEXT_ITEM_XFORM_DETAIL_ID;

-----------------------------------------------------------------------------------------------------------------
FUNCTION CHECK_MULTI_PARENTS(O_error_message      IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             O_multi_parent_ind   IN OUT   BOOLEAN,
                             I_item               IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60) := 'ITEM_XFORM_SQL.CHECK_MULTI_PARENTS';
   L_count     NUMBER;

   cursor C_CHK_MULTI_PARENTS is
      select count(*)
        from item_master iem,
             item_xform_head ixh,
             item_xform_detail ixd
       where ixd.detail_item        = I_item
         and ixd.item_xform_head_id = ixh.item_xform_head_id
         and ixh.head_item          = iem.item
         and iem.status             = 'A';

BEGIN

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   O_multi_parent_ind := FALSE;

   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHK_MULTI_PARENTS',
                    'item_xform_detail',
                    NULL);
   open C_CHK_MULTI_PARENTS;

   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_CHK_MULTI_PARENTS',
                    'item_xform_detail',
                    NULL);
   fetch C_CHK_MULTI_PARENTS into L_count;

   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHK_MULTI_PARENTS',
                    'item_xform_detail',
                    NULL);
   close C_CHK_MULTI_PARENTS;

   if L_count > 1 then
      O_multi_parent_ind := TRUE;
   end if;

   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END CHECK_MULTI_PARENTS;

-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_HEAD_ITEM(O_error_message          IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                       O_head_item              IN OUT   ITEM_XFORM_HEAD.HEAD_ITEM%TYPE,
                       I_item_xform_detail_id   IN       ITEM_XFORM_DETAIL.ITEM_XFORM_DETAIL_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(60) := 'ITEM_XFORM_SQL.GET_HEAD_ITEM';
   L_status    VARCHAR2(1);

   cursor C_GET_HEAD_ITEM is
      select ixh.head_item,
             im.status
        from item_xform_detail ixd,
             item_xform_head ixh,
             item_master im
       where ixd.item_xform_head_id   = ixh.item_xform_head_id
         and ixh.head_item            = im.item
         and ixd.item_xform_detail_id = I_item_xform_detail_id;


BEGIN

   if I_item_xform_detail_id IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item_xform_detail_id',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;

   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_HEAD_ITEM',
                    'item_xform_head,item_xform_detail',
                    NULL);
   open C_GET_HEAD_ITEM;

   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_HEAD_ITEM',
                    'item_xform_head,item_xform_detail',
                    NULL);
   fetch C_GET_HEAD_ITEM into O_head_item,
                              L_status;

   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_HEAD_ITEM',
                    'item_xform_head,item_xform_detail',
                    NULL);
   close C_GET_HEAD_ITEM;

   ---
   if O_head_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('HEAD_ITEM_NOT_FOUND',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   ---
   if L_status != 'A' then
      O_head_item := NULL;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END GET_HEAD_ITEM;


-----------------------------------------------------------------------------------------------------------------
FUNCTION FILTER_DETAIL_LIST(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_partial_ind     IN OUT   VARCHAR2,
                            I_item_xform_id   IN       ITEM_XFORM_DETAIL.ITEM_XFORM_HEAD_ID%TYPE,
                            I_item            IN       ITEM_XFORM_DETAIL.DETAIL_ITEM%TYPE,
                            I_filter_type     IN       VARCHAR2)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'ITEM_XFORM_SQL.FILTER_DETAIL_LIST';
   L_sell_ord_count  NUMBER ;
   L_item_count   NUMBER ;
   --Orderable Item Count
   cursor C_ORDERABLE_ITEM_COUNT is
      select count(*)
        from item_xform_detail ixdl
       where I_filter_type = 'S'
         and ixdl.detail_item = I_item;
   --Orderable Item View Count
   cursor C_ORDERABLE_ITEM_VIEW_COUNT is
      select count(*)
        from v_item_xform_detail  vixd
       where I_filter_type = 'S'
         and vixd.detail_item = I_item;
   --Sellable Item Count
   cursor C_SELLABLE_ITEM_COUNT is
      select count(*)
        from item_xform_detail ixdl
       where I_filter_type = 'O'
         and ixdl.item_xform_head_id = I_item_xform_id;
   --Sellable Item View Count
   cursor C_SELLABLE_ITEM_VIEW_COUNT is
      select count(*)
        from v_item_xform_detail vixd
       where I_filter_type = 'O'
         and vixd.item_xform_head_id = I_item_xform_id;
BEGIN
   --Check that values input are not null
   if ((I_item_xform_id IS NULL AND I_item IS NULL) OR
      (I_item_xform_id IS NOT NULL AND I_item IS NOT NULL)) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAMETER_INPUT',
                                            'I_item_xform_id, I_item',
                                            L_program,
                                            'NULL');
      return FALSE;
   end if;
   if (I_filter_type <> 'O' AND I_filter_type <> 'S') then
      O_error_message := SQL_LIB.CREATE_MSG('INV_FILTER',
                                            L_program,
                                            'NULL',
                                            'NULL');
      return FALSE;
   end if;
   L_sell_ord_count := 0;
   L_item_count := 0;
   if UPPER(I_filter_type) = 'S' then
      --Retrieve orderable item rows
      SQL_LIB.SET_MARK('OPEN','C_ORDERABLE_ITEM_COUNT','ITEM_XFORM_DETAIL',NULL);
      open C_ORDERABLE_ITEM_COUNT;
      SQL_LIB.SET_MARK('FETCH','C_ORDERABLE_ITEM_COUNT','ITEM_XFORM_DETAIL',NULL);
      fetch C_ORDERABLE_ITEM_COUNT into L_sell_ord_count;
      SQL_LIB.SET_MARK('CLOSE','C_ORDERABLE_ITEM_COUNT','ITEM_XFORM_DETAIL',NULL);
      close C_ORDERABLE_ITEM_COUNT;
      --Retrieve a count from the view v_item_xform_detail
      SQL_LIB.SET_MARK('OPEN','C_ORDERABLE_ITEM_VIEW_COUNT','V_ITEM_XFORM_DETAIL',NULL);
      open C_ORDERABLE_ITEM_VIEW_COUNT;
      SQL_LIB.SET_MARK('FETCH','C_ORDERABLE_ITEM_VIEW_COUNT','V_ITEM_XFORM_DETAIL',NULL);
      fetch C_ORDERABLE_ITEM_VIEW_COUNT into L_item_count;
      SQL_LIB.SET_MARK('CLOSE','C_ORDERABLE_ITEM_VIEW_COUNT','V_ITEM_XFORM_DETAIL',NULL);
      close C_ORDERABLE_ITEM_VIEW_COUNT;
   elsif UPPER(I_filter_type) = 'O' then
      --Retrieve sellable item rows
      SQL_LIB.SET_MARK('OPEN','C_SELLABLE_ITEM_COUNT','ITEM_XFORM_DETAIL',NULL);
      open C_SELLABLE_ITEM_COUNT;
      SQL_LIB.SET_MARK('FETCH','C_SELLABLE_ITEM_COUNT','ITEM_XFORM_DETAIL',NULL);
      fetch C_SELLABLE_ITEM_COUNT into L_sell_ord_count;
      SQL_LIB.SET_MARK('CLOSE','C_SELLABLE_ITEM_COUNT','ITEM_XFORM_DETAIL',NULL);
      close C_SELLABLE_ITEM_COUNT;
      --Retrieve a count from the view v_item_xform_detail
      SQL_LIB.SET_MARK('OPEN','C_SELLABLE_ITEM_VIEW_COUNT','V_ITEM_XFORM_DETAIL',NULL);
      open C_SELLABLE_ITEM_VIEW_COUNT;
      SQL_LIB.SET_MARK('FETCH','C_SELLABLE_ITEM_VIEW_COUNT','V_ITEM_XFORM_DETAIL',NULL);
      fetch C_SELLABLE_ITEM_VIEW_COUNT into L_item_count;
      SQL_LIB.SET_MARK('CLOSE','C_SELLABLE_ITEM_VIEW_COUNT','ITEM_XFORM_DETAIL',NULL);
      close C_SELLABLE_ITEM_VIEW_COUNT;
   end if;
   --Compare values from both cursors
   if L_sell_ord_count != L_item_count then
      O_partial_ind := 'Y';
   else
      O_partial_ind := 'N';
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END FILTER_DETAIL_LIST;
-----------------------------------------------------------------------------------------------------------------
FUNCTION CALCULATE_RETAIL (O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                           I_item            IN       ITEM_MASTER.ITEM%TYPE,
                           I_location        IN       ITEM_LOC.LOC%TYPE,
                           O_unit_retail     IN OUT   ITEM_LOC.UNIT_RETAIL%TYPE)
   RETURN BOOLEAN IS
   L_program                   VARCHAR2(50) := 'ITEM_XFORM_SQL.CALCULATE_RETAIL';
   L_found_rec                 VARCHAR2(1) := 'N';
   L_found_rec2                VARCHAR2(1);
   L_item                      ITEM_MASTER.ITEM%TYPE;
   L_unit_retail               ITEM_LOC.UNIT_RETAIL%TYPE;
   L_table1                    VARCHAR2(25) := 'ITEM_LOC';
   L_table2                    VARCHAR2(25) := 'ITEM_ZONE_PRICE';
   L_item_master_rec           ITEM_MASTER%ROWTYPE ;
   L_zone_group_id             ITEM_ZONE_PRICE.ZONE_GROUP_ID%TYPE;
   L_zone_id                   ITEM_ZONE_PRICE.ZONE_ID%TYPE;
   L_standard_uom_prim         ITEM_ZONE_PRICE.SELLING_UOM%TYPE;
   L_selling_unit_retail_prim  ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE;
   L_selling_uom_prim          ITEM_ZONE_PRICE.SELLING_UOM%TYPE;
   L_multi_units_zon           ITEM_ZONE_PRICE.MULTI_UNITS%TYPE;
   L_multi_unit_retail_zon     ITEM_ZONE_PRICE.MULTI_UNIT_RETAIL%TYPE;
   L_multi_selling_uom_zon     ITEM_ZONE_PRICE.MULTI_SELLING_UOM%TYPE;
   L_purge                     VARCHAR2(1) := 'N';


   cursor C_GET_SELLABLES is
      select b.detail_item,
             b.item_quantity_pct
        from item_xform_head a,
             item_xform_detail b
       where a.head_item = I_item
         and a.item_xform_head_id=b.item_xform_head_id;

   cursor C_GET_LOC_UNITRETAIL (L_item VARCHAR2)  is
         select 'Y', unit_retail
           from item_loc
          where loc = I_location
            and item = L_item;

   cursor C_PURGE is
      select 'Y'
        from daily_purge
       where key_value = I_item
         and rownum    = 1;

BEGIN
   --Check that values input are not null
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            'NULL');
      return FALSE;
   end if;
   O_unit_retail := 0;
   FOR rec_get_sellables  in C_GET_SELLABLES LOOP
      L_found_rec := 'Y';
      -- if a store is passed in
      if I_location IS NOT NULL then  -- if a store is passed in
         SQL_LIB.SET_MARK('OPEN','C_GET_LOC_UNITRETAIL','ITEM_LOC',NULL);
         open C_GET_LOC_UNITRETAIL(rec_get_sellables.detail_item);
         SQL_LIB.SET_MARK('FETCH', 'C_GET_LOC_UNITRETAIL', 'ITEM_LOC',NULL);
         L_found_rec2 := 'N';
         fetch C_GET_LOC_UNITRETAIL into L_found_rec2, L_unit_retail;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_LOC_UNITRETAIL', 'ITEM_LOC',NULL);
         close C_GET_LOC_UNITRETAIL;

         if L_found_rec2 = 'N' then
               if not PRICING_ATTRIB_SQL.GET_BASE_ZONE_RETAIL(O_error_message,
                                                        L_zone_group_id,
                                                        L_zone_id,
                                                        L_unit_retail,
                                                        L_standard_uom_prim,
                                                        L_selling_unit_retail_prim,
                                                        L_selling_uom_prim,
                                                        L_multi_units_zon,
                                                        L_multi_unit_retail_zon,
                                                        L_multi_selling_uom_zon,
                                                        rec_get_sellables.detail_item) then
                                             return FALSE;
             end if;
                if L_unit_retail is NOT NULL then
                 -- Convert retail to primary currency
                        if not CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                    L_zone_id,
                                                    'Z',
                                                    L_zone_group_id,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    L_unit_retail,
                                                    L_unit_retail,
                                                    'R',
                                                    NULL,
                                                    NULL) then
                        return FALSE;
                        end if;
                  Else
                        O_error_message := SQL_LIB.CREATE_MSG( 'NO_ITEM_ZONE_PRICE_REC',
                                                      rec_get_sellables.detail_item,
                                                      NULL,
                                                      NULL);
                        Return FALSE;
                  End if;

         end if;
      else --no I_location is passed in
       -- retrieve the unit retail of the sellable items
       -- attached to the orderable item
       if not PRICING_ATTRIB_SQL.GET_BASE_ZONE_RETAIL(O_error_message,
                                                        L_zone_group_id,
                                                        L_zone_id,
                                                        L_unit_retail,
                                                        L_standard_uom_prim,
                                                        L_selling_unit_retail_prim,
                                                        L_selling_uom_prim,
                                                        L_multi_units_zon,
                                                        L_multi_unit_retail_zon,
                                                        L_multi_selling_uom_zon,
                                                        rec_get_sellables.detail_item) then
           return FALSE;
        end if;

          if L_unit_retail is NOT NULL then
            -- Convert retail to primary currency
                    if not CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                    L_zone_id,
                                                    'Z',
                                                    L_zone_group_id,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    L_unit_retail,
                                                    L_unit_retail,
                                                    'R',
                                                    NULL,
                                                    NULL) then
                        return FALSE;
                    end if;
          Else
             O_error_message := SQL_LIB.CREATE_MSG( 'NO_ITEM_ZONE_PRICE_REC',
                                                      rec_get_sellables.detail_item,
                                                      NULL,
                                                      NULL);
             Return FALSE;
          End if;
      end if;
      O_unit_retail := O_unit_retail + (L_unit_retail * (rec_get_sellables.item_quantity_pct/100));

   END LOOP;
   --Check if records were fetched from C_GET_SELLABLES
   if L_found_rec = 'N' then
      if Item_Attrib_Sql.GET_ITEM_MASTER(O_error_message,
                                         L_item_master_rec,
                                         I_item) = FALSE then
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('OPEN',
                       'C_PURGE',
                       'DAILY_PURGE',
                       NULL);
      open C_PURGE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_PURGE',
                       'DAILY_PURGE',
                       NULL);
      fetch C_PURGE into L_purge;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_PURGE',
                       'DAILY_PURGE',
                       NULL);
      close C_PURGE;

      if ((L_item_master_rec.tran_level = L_item_master_rec.item_level) AND
          (L_purge = 'N')) then
         O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_SELL_ITEM',
                                                NULL,
                                                NULL,
                                               NULL);
         return FALSE;
      else
         O_unit_retail := NULL;
      end if;


   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CALCULATE_RETAIL;
-----------------------------------------------------------------------------------------------------------------
FUNCTION CALCULATE_COST(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        I_item            IN OUT   ITEM_MASTER.ITEM%TYPE,
                        I_location        IN       ITEM_LOC.LOC%TYPE,
                        O_unit_cost       OUT      ITEM_SUPP_COUNTRY.UNIT_COST%TYPE)
RETURN BOOLEAN IS

   L_program                 VARCHAR2(50) := 'ITEM_XFORM_SQL.CALCULATE_COST';
   L_sellable_retail         ITEM_LOC.UNIT_RETAIL%TYPE;
   L_orderable_retail        ITEM_LOC.UNIT_RETAIL%TYPE;
   L_orderable_cost          ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_itemloc_attrib_rec      ITEM_LOC%ROWTYPE;
   L_supplier                ITEM_SUPPLIER.SUPPLIER%TYPE;
   L_orderable_retail_final  ITEM_LOC.UNIT_RETAIL%TYPE;

   cursor C_GET_ITEM_LOC(I_item ITEM_MASTER.ITEM%TYPE,
                         I_location ITEM_LOC.LOC%TYPE) is
      select *
        from item_loc
       where item = I_item
         and loc = I_location;

   cursor C_GET_ORDERABLE_DET IS
      select a.head_item,
             b.yield_from_head_item_pct
        from item_xform_head a,
             item_xform_detail b
       where b.detail_item = I_item
         and a.item_xform_head_id = b.item_xform_head_id;

BEGIN

   if I_item is null then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARAM',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   O_unit_cost := 0;

   if I_location is NOT NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_LOC',
                       'ITEM_LOC',
                       'I_item: ' || I_item);
      open C_GET_ITEM_LOC(I_item,
                          I_location);

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_LOC',
                       'ITEM_LOC',
                       'I_item: ' || I_item);
      FETCH C_GET_ITEM_LOC into L_itemloc_attrib_rec;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_LOC',
                       'ITEM_LOC',
                       'I_item: ' || I_item);
      close C_GET_ITEM_LOC;

      if L_itemloc_attrib_rec.item is NOT NULL then
         L_sellable_retail := L_itemloc_attrib_rec.unit_retail;
      else
         if ITEM_PRICING_SQL.GET_BASE_RETAIL(O_error_message,
                                             L_sellable_retail,
                                             I_item) = FALSE then
            return FALSE;
         end if;
      end if;

   else
      if ITEM_PRICING_SQL.GET_BASE_RETAIL(O_error_message,
                                          L_sellable_retail,
                                          I_item) = FALSE then
         return FALSE;
      end if;
   end if;

   FOR C_orderable_det_rec IN C_GET_ORDERABLE_DET LOOP
      if SUPP_ITEM_SQL.GET_PRI_SUP_COST(  O_error_message,
                                          L_supplier,
                                          L_orderable_cost,
                                          C_orderable_det_rec.head_item,
                                          I_location) = FALSE then
         return FALSE;
      end if;

      if ITEM_XFORM_SQL.CALCULATE_RETAIL( O_error_message,
                                          C_orderable_det_rec.head_item,
                                          I_location,
                                          L_orderable_retail) = FALSE then
         return FALSE;
      end if;

      if (L_orderable_retail is NULL) OR (L_orderable_retail <=  0) then
         O_unit_cost := 0;
      else
         if C_orderable_det_rec.yield_from_head_item_pct is null then
            O_unit_cost := (L_sellable_retail / L_orderable_retail) * L_orderable_cost;
            EXIT;
         else
            O_unit_cost := O_unit_cost + ((L_sellable_retail / L_orderable_retail) *
                                          L_orderable_cost * (C_orderable_det_rec.yield_from_head_item_pct/100));
         end if;
      end if;

   END LOOP;
   return true;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             SQLCODE);
      return FALSE;

END CALCULATE_COST;
-----------------------------------------------------------------------------------------------------------------
FUNCTION GET_SUM_OF_YIELD_PERCENTAGES(O_error_message            IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                      O_sum_of_yield_percentages IN OUT ITEM_XFORM_DETAIL.YIELD_FROM_HEAD_ITEM_PCT%TYPE,
                                      I_detail_item              IN     ITEM_XFORM_DETAIL.DETAIL_ITEM%TYPE)

RETURN BOOLEAN

IS

   FUNCTION_NAME CONSTANT VARCHAR2(43) := 'ITEM_XFORM_SQL.GET_SUM_OF_YIELD_PERCENTAGES';

   cursor   C_IXD
       is
   select   sum(ixd.yield_from_head_item_pct)
     from   item_xform_detail ixd
    where   ixd.detail_item   = I_detail_item;

BEGIN

   if I_detail_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG ('INV_PARM_PROG',
                                             FUNCTION_NAME,
                                             'I_detail_item',
                                             'NULL');
      return FALSE;
   end if;

   O_sum_of_yield_percentages := NULL;

   SQL_LIB.SET_MARK('OPEN',
                    'C_IXD',
                    'ITEM_XFORM_DETAIL',
                    'I_detail_item='||I_detail_item);

   open  C_IXD;

   SQL_LIB.SET_MARK('FETCH',
                    'C_IXD',
                    'ITEM_XFORM_DETAIL',
                    'I_detail_item='||I_detail_item);

   fetch C_IXD
    into O_sum_of_yield_percentages;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_IXD',
                    'ITEM_XFORM_DETAIL',
                    'I_detail_item='||I_detail_item);

   close C_IXD;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             FUNCTION_NAME,
                                             SQLCODE);
      return FALSE;
END GET_SUM_OF_YIELD_PERCENTAGES;
-----------------------------------------------------------------------------------------------------------------
FUNCTION ITEM_XFORM_DETAIL_EXISTS(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_exists             IN OUT BOOLEAN,
                                  I_item_xform_head_id IN     ITEM_XFORM_DETAIL.ITEM_XFORM_HEAD_ID%TYPE,
                                  I_detail_item        IN     ITEM_XFORM_DETAIL.DETAIL_ITEM%TYPE)

RETURN BOOLEAN

IS

   FUNCTION_NAME CONSTANT VARCHAR2(39) := 'ITEM_XFORM_SQL.ITEM_XFORM_DETAIL_EXISTS';

   cursor   C_IXD
       is
   select   1
     from   item_xform_detail      ixd
    where   ixd.item_xform_head_id = I_item_xform_head_id
      and   ixd.detail_item        = I_detail_item;

   c_ixd_row   C_IXD%ROWTYPE;

BEGIN

   if I_item_xform_head_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG ('INV_PARM_PROG',
                                             FUNCTION_NAME,
                                             'I_item_xform_head_id',
                                             'NULL');
      return FALSE;
   end if;

   if I_detail_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG ('INV_PARM_PROG',
                                             FUNCTION_NAME,
                                             'I_detail_item',
                                             'NULL');
      return FALSE;
   end if;

   O_exists := NULL;

   SQL_LIB.SET_MARK('OPEN',
                    'C_IXD',
                    'ITEM_XFORM_DETAIL',
                    'I_item_xform_head_id='||I_item_xform_head_id||
                    '/I_detail_item='      ||I_detail_item);

   open  C_IXD;

   SQL_LIB.SET_MARK('FETCH',
                    'C_IXD',
                    'ITEM_XFORM_DETAIL',
                    'I_item_xform_head_id='||I_item_xform_head_id||
                    '/I_detail_item='      ||I_detail_item);

   fetch C_IXD
    into c_ixd_row;

   O_exists := C_IXD%FOUND;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_IXD',
                    'ITEM_XFORM_DETAIL',
                    'I_item_xform_head_id='||I_item_xform_head_id||
                    '/I_detail_item='      ||I_detail_item);

   close C_IXD;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             FUNCTION_NAME,
                                             SQLCODE);
      return FALSE;
END ITEM_XFORM_DETAIL_EXISTS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION COUNT_XFORM_DETAIL_RECS(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_count              IN OUT NUMBER,
                                 I_detail_item        IN     ITEM_XFORM_DETAIL.DETAIL_ITEM%TYPE)

RETURN BOOLEAN

IS

   FUNCTION_NAME CONSTANT VARCHAR2(39) := 'ITEM_XFORM_SQL.COUNT_XFORM_DETAIL_RECS';

  cursor   C_COUNT_DETAIL
         is
     select   count(*)
       from   item_xform_detail
      where   detail_item        = I_detail_item;


BEGIN

   if I_detail_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG ('INV_PARM_PROG',
                                                FUNCTION_NAME,
                                                'I_detail_item',
                                                'NULL');
         return FALSE;
   end if;
   O_count := NULL;
   SQL_LIB.SET_MARK('OPEN',
                    'C_COUNT_DETAIL',
                    'ITEM_XFORM_DETAIL',
                    'I_detail_item='      ||I_detail_item);
   open  C_COUNT_DETAIL;
   SQL_LIB.SET_MARK('FETCH',
                    'C_COUNT_DETAIL',
                    'ITEM_XFORM_DETAIL',
                    'I_detail_item='      ||I_detail_item);
   fetch C_COUNT_DETAIL
   into O_count;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_COUNT_DETAIL',
                    'ITEM_XFORM_DETAIL',
                    'I_detail_item='      ||I_detail_item);
   close C_COUNT_DETAIL;
   return TRUE;



EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             FUNCTION_NAME,
                                             SQLCODE);
      return FALSE;
END COUNT_XFORM_DETAIL_RECS;
-----------------------------------------------------------------------------------------------------------------
FUNCTION SET_YIELD_PCT_NULL(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_detail_item        IN     ITEM_XFORM_DETAIL.DETAIL_ITEM%TYPE)

RETURN BOOLEAN

IS

   FUNCTION_NAME CONSTANT VARCHAR2(39) := 'ITEM_XFORM_SQL.SET_YIELD_PCT_NULL';
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);
   cursor   C_CHECK_LOCK
          is
      select  'x'
        from  item_xform_detail
       where  detail_item        = I_detail_item
         for  update nowait;

BEGIN

   if I_detail_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG ('INV_PARM_PROG',
                                                FUNCTION_NAME,
                                                'I_detail_item',
                                                'NULL');
         return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',NULL,'C_CHECK_LOCK','Detail Item:'||I_detail_item);
   Open C_CHECK_LOCK;
   SQL_LIB.SET_MARK('CLOSE',NULL,'C_CHECK_LOCK','Detail Item:'||I_detail_item);
   Close C_CHECK_LOCK;
   SQL_LIB.SET_MARK('UPDATE',NULL,'ITEM_XFORM_DETAIL','Detail Item:'||I_detail_item);
   update item_xform_detail
      set yield_from_head_item_pct = NULL
    where detail_item = I_detail_item;
   return TRUE;



EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'ITEM_XFORM_DETAIL',
                                            I_detail_item,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             FUNCTION_NAME,
                                             SQLCODE);
      return FALSE;
END SET_YIELD_PCT_NULL;
-----------------------------------------------------------------------------------------------------------------
FUNCTION ITEM_XFORM_HEAD_EXISTS(O_error_message      IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                O_exists             IN OUT BOOLEAN,
                                I_head_item          IN     ITEM_MASTER.ITEM%TYPE)

RETURN BOOLEAN

IS

   FUNCTION_NAME CONSTANT VARCHAR2(39) := 'ITEM_XFORM_SQL.ITEM_XFORM_HEAD_EXISTS';

   cursor   C_IXH
       is
   select   1
     from   item_xform_head ixh
    where   ixh.head_item   = I_head_item;

   c_ixh_row   C_IXH%ROWTYPE;

BEGIN

   if I_head_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG ('INV_PARM_PROG',
                                             FUNCTION_NAME,
                                             'I_head_item',
                                             'NULL');
      return FALSE;
   end if;

   O_exists := NULL;

   SQL_LIB.SET_MARK('OPEN',
                    'C_IXH',
                    'ITEM_XFORM_HEAD',
                    'I_head_item='||I_head_item);

   open  C_IXH;

   SQL_LIB.SET_MARK('FETCH',
                    'C_IXH',
                    'ITEM_XFORM_HEAD',
                    'I_head_item='||I_head_item);

   fetch C_IXH
    into c_ixh_row;

   O_exists := C_IXH%FOUND;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_IXH',
                    'ITEM_XFORM_HEAD',
                    'I_head_item='||I_head_item);

   close C_IXH;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             FUNCTION_NAME,
                                             SQLCODE);
      return FALSE;
END ITEM_XFORM_HEAD_EXISTS;

-------------------------------------------------------------------------------------------------------------
FUNCTION TSF_ORDERABLE_ITEM_INFO(O_error_message   IN OUT        RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_orderable_TBL   IN OUT NOCOPY BTS_ORDITEM_QTY_TBL,
                                 I_sell_item_tbl   IN            ITEM_TBL,
                                 I_sell_qty_tbl    IN            QTY_TBL,
                                 I_inv_status_tbl  IN            INV_STATUS_TBL,
                                 I_tsf_no          IN            TSFDETAIL.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_module                 VARCHAR2(64) := 'ITEM_XFORM_SQL.TSF_ORDERABLE_ITEM_INFO';

   L_qty_to_fill_tbl   QTY_TO_FILL_TBL := NULL;
   L_tsf_type          TSFHEAD.TSF_TYPE%TYPE;
   ----
   --- For details on the C_TSF_ORDERABLE cursor, see comments in GET_QTY_TO_FILL
   ----
   cursor C_TSF_ORDERABLE(I_item       IN ITEM_MASTER.ITEM%TYPE,
                          I_inv_status IN TSFDETAIL.INV_STATUS%TYPE) is
      select orderable_item,
             tsf_qty  qty_requested,
             tsf_qty - NVL(ord_tbl_qty,0) - ship_qty  qty_to_fill
        from (select tdt.item orderable_item,
                     NVL(tdt.tsf_qty,0)  tsf_qty,
                     NVL(tdt.ship_qty,0)  ship_qty,
                     sum(NVL(tmp.qty,0)) ord_tbl_qty
                from tsfdetail tdt,
                     item_xform_detail ixd,
                     item_xform_head ixh,
                     TABLE(cast(O_orderable_TBL AS bts_orditem_qty_tbl)) tmp
               where ixd.item_xform_head_id = ixh.item_xform_head_id
                 and ixh.head_item          = tdt.item
                 and tdt.tsf_no             = I_tsf_no
                 and NVL(tdt.inv_status,-1) = I_inv_status
                 and ixd.detail_item        = I_item
                 and tmp.orderable_item(+) = tdt.item
               group by tdt.item,
                        tdt.tsf_qty,
                        tdt.ship_qty)
       order by qty_to_fill desc;

   cursor c_get_tsf_type is
      select tsf_type
        from tsfhead
       where tsf_no = I_tsf_no;

BEGIN

   O_orderable_TBL := BTS_ORDITEM_QTY_TBL();

   FOR i IN I_sell_item_tbl.FIRST..I_sell_item_tbl.LAST LOOP

      open C_TSF_ORDERABLE(I_sell_item_tbl(i),I_inv_status_tbl(i));
      fetch C_TSF_ORDERABLE BULK COLLECT into L_qty_to_fill_tbl;
      close C_TSF_ORDERABLE;
      ---

      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_TSF_TYPE',
                       'TSFHEAD',
                       I_tsf_no);
      open C_GET_TSF_TYPE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_TSF_TYPE',
                       'TSFHEAD',
                       I_tsf_no);
      fetch C_GET_TSF_TYPE into L_tsf_type;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_TSF_TYPE',
                       'TSFHEAD',
                       I_tsf_no);
      close C_GET_TSF_TYPE;

      if L_tsf_type != 'EG' then
         if GET_QTY_TO_FILL(O_error_message,
                            O_orderable_TBL,
                            L_qty_to_fill_tbl,
                            I_sell_item_tbl(i),
                            I_sell_qty_tbl(i),
                            I_inv_status_tbl(i)) = FALSE then
            return FALSE;
         end if;
      else
         if GET_QTY_TO_FILL_EG(O_error_message,
                               O_orderable_TBL,
                               L_qty_to_fill_tbl,
                               I_sell_item_tbl(i),
                               I_sell_qty_tbl(i),
                               I_inv_status_tbl(i)) = FALSE then
            return FALSE;
         end if;
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);

      return FALSE;

END TSF_ORDERABLE_ITEM_INFO;
-------------------------------------------------------------------------------------------------------------
FUNCTION ALLOC_ORDERABLE_ITEM_INFO(O_error_message   IN OUT        RTK_ERRORS.RTK_TEXT%TYPE,
                                   O_orderable_TBL   IN OUT NOCOPY BTS_ORDITEM_QTY_TBL,
                                   I_sell_item_tbl   IN            ITEM_TBL,
                                   I_sell_qty_tbl    IN            QTY_TBL,
                                   I_alloc_no        IN            ALLOC_HEADER.ALLOC_NO%TYPE,
                                   I_to_loc          IN            ALLOC_DETAIL.TO_LOC%TYPE)
RETURN BOOLEAN IS

   L_module                 VARCHAR2(64) := 'ITEM_XFORM_SQL.ALLOC_ORDERABLE_ITEM_INFO';

   L_qty_to_fill_tbl   QTY_TO_FILL_TBL := NULL;
   ----
   --- For details on the C_ALLOC_ORDERABLE cursor, see comments in GET_QTY_TO_FILL
   ----
   cursor C_ALLOC_ORDERABLE(I_item       IN ITEM_MASTER.ITEM%TYPE) is
      select orderable_item,
             qty_allocated  qty_requested,
             qty_allocated - NVL(ord_tbl_qty,0) - ship_qty  qty_to_fill
        from (select alh.item orderable_item,
                     ald.qty_allocated,
                     NVL(ald.qty_transferred,0)  ship_qty,
                     sum(NVL(tmp.qty,0)) ord_tbl_qty
                from alloc_detail ald,
                     alloc_header alh,
                     item_xform_detail ixd,
                     item_xform_head ixh,
                     TABLE(cast(O_orderable_TBL AS bts_orditem_qty_tbl)) tmp
               where ixd.item_xform_head_id = ixh.item_xform_head_id
                 and ixh.head_item          = alh.item
                 and alh.alloc_no           = I_alloc_no
                 and alh.alloc_no           = ald.alloc_no
                 and ald.to_loc             = I_to_loc
                 and ixd.detail_item        = I_item
                 and tmp.orderable_item(+)  = alh.item
               group by alh.item,
                        ald.qty_allocated,
                        ald.qty_transferred)
       order by qty_to_fill desc;


BEGIN

   O_orderable_TBL := BTS_ORDITEM_QTY_TBL();

   FOR i IN I_sell_item_tbl.FIRST..I_sell_item_tbl.LAST LOOP

      open C_ALLOC_ORDERABLE(I_sell_item_tbl(i));
      fetch C_ALLOC_ORDERABLE BULK COLLECT into L_qty_to_fill_tbl;
      close C_ALLOC_ORDERABLE;
      ---
      if GET_QTY_TO_FILL(O_error_message,
                         O_orderable_TBL,
                         L_qty_to_fill_tbl,
                         I_sell_item_tbl(i),
                         I_sell_qty_tbl(i),
                         NULL) = FALSE then
         return FALSE;
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);

      return FALSE;

END ALLOC_ORDERABLE_ITEM_INFO;
-------------------------------------------------------------------------------------------------------------
FUNCTION RTV_ORDERABLE_ITEM_INFO(O_error_message   IN OUT        RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_orderable_TBL   IN OUT NOCOPY BTS_ORDITEM_QTY_TBL,
                                 I_sell_item_tbl   IN            ITEM_TBL,
                                 I_sell_qty_tbl    IN            QTY_TBL,
                                 I_rtv_order_no    IN            RTV_HEAD.RTV_ORDER_NO%TYPE,
                                 I_ext_ref_no      IN            RTV_HEAD.EXT_REF_NO%TYPE,
                                 I_location        IN            ITEM_LOC.LOC%TYPE,
                                 I_inv_status_tbl  IN            INV_STATUS_TBL,
                                 I_reason_tbl      IN            RTV_SQL.REASON_TBL)
RETURN BOOLEAN IS

   L_program                 VARCHAR2(64) := 'ITEM_XFORM_SQL.RTV_ORDERABLE_ITEM_INFO';

   L_rtv_exists              VARCHAR2(1) := NULL;
   L_rtv_order_no            RTV_HEAD.RTV_ORDER_NO%TYPE := NULL;

   cursor C_RTV_EXISTS is
      select 'x'
        from rtv_head
       where rtv_order_no = I_rtv_order_no
         and status_ind in ('10', '15')
         and rownum = 1;

   cursor C_EXT_REF_RTV_EXISTS is
      select rtv_order_no
        from rtv_head
       where ext_ref_no = I_ext_ref_no
         and status_ind in ('10', '15')
         and ((store = I_location)
          or (wh = I_location))
         and rownum = 1;
   ----
   --- For details on the C_RTV_ORDERABLE cursor, see comments in GET_QTY_TO_FILL
   ----
   cursor C_RTV_ORDERABLE(I_item       IN ITEM_MASTER.ITEM%TYPE,
                          I_inv_status IN INV_STATUS_CODES.INV_STATUS%TYPE,
                          I_reason     IN RTV_DETAIL.REASON%TYPE) is
      select rtd.item orderable_item,
             NVL(rtd.qty_requested,0)  qty_requested,
             NVL(rtd.qty_requested,0) - NVL(rtd.qty_returned,0)  qty_to_fill
        from rtv_detail rtd,
             item_xform_detail ixd,
             item_xform_head ixh,
             TABLE(cast(O_orderable_TBL AS bts_orditem_qty_tbl)) tmp
       where ixd.item_xform_head_id = ixh.item_xform_head_id
         and ixh.head_item          = rtd.item
         and rtd.rtv_order_no       = L_rtv_order_no
         and NVL(rtd.inv_status,-1) = I_inv_status
         and rtd.reason             = I_reason
         and ixd.detail_item        = I_item
         and tmp.orderable_item(+)  = rtd.item
       order by qty_to_fill desc;

   L_rtv_cur_tbl   QTY_TO_FILL_TBL := NULL;

BEGIN

   O_orderable_TBL := BTS_ORDITEM_QTY_TBL();

   FOR i IN I_sell_item_tbl.FIRST..I_sell_item_tbl.LAST LOOP

      -- check if RTV exists, if not it is an externally generated RTV
      open C_RTV_EXISTS;
      fetch C_RTV_EXISTS into L_rtv_exists;
      close C_RTV_EXISTS;

      if L_rtv_exists is NOT NULL then
         L_rtv_order_no := I_rtv_order_no;
      else
         open C_EXT_REF_RTV_EXISTS;
         fetch C_EXT_REF_RTV_EXISTS into L_rtv_order_no;
         close C_EXT_REF_RTV_EXISTS;
      end if;
      ---
      if L_rtv_order_no is not NULL then
         open C_RTV_ORDERABLE(I_sell_item_tbl(i),I_inv_status_tbl(i),I_reason_tbl(i));
         fetch C_RTV_ORDERABLE BULK COLLECT into L_rtv_cur_tbl;
         close C_RTV_ORDERABLE;
      end if;

      if GET_QTY_TO_FILL(O_error_message,
                         O_orderable_TBL,
                         L_rtv_cur_tbl,
                         I_sell_item_tbl(i),
                         I_sell_qty_tbl(i),
                         I_inv_status_tbl(i)) = FALSE then
         return FALSE;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);

      return FALSE;

END RTV_ORDERABLE_ITEM_INFO;
-------------------------------------------------------------------------------------------------------------
FUNCTION GET_QTY_TO_FILL(O_error_message       IN OUT        RTK_ERRORS.RTK_TEXT%TYPE,
                         IO_item_qty_tbl       IN OUT NOCOPY BTS_ORDITEM_QTY_TBL,
                         IO_qty_to_fill_tbl    IN OUT NOCOPY QTY_TO_FILL_TBL,
                         I_sell_item           IN            ITEM_MASTER.ITEM%TYPE,
                         I_sell_qty            IN            ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                         I_inv_status          IN            INV_STATUS_CODES.INV_STATUS%TYPE)
RETURN BOOLEAN IS


   L_module                  VARCHAR2(64) := 'ITEM_XFORM_SQL.GET_QTY_TO_FILL';

   L_orderable_qty           ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
   L_total_qty               ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

   L_fully_shipped       BOOLEAN := TRUE;

   cursor C_XFORM_INFO is
      select h.head_item,
             h.production_loss_pct,
             d.detail_item,
             d.yield_from_head_item_pct
        from item_xform_detail d, item_xform_head h
       where d.item_xform_head_id = h.item_xform_head_id
         and d.detail_item = I_sell_item;

BEGIN

   if IO_qty_to_fill_tbl is NULL or
      IO_qty_to_fill_tbl.COUNT = 0 then
      FOR rec IN C_XFORM_INFO LOOP

         if GET_ORDERABLE_QTY(O_error_message,
                              L_orderable_qty,
                              I_sell_qty,
                              rec.production_loss_pct,
                              rec.yield_from_head_item_pct) = FALSE then
            return FALSE;
         end if;
         ---
         IO_item_qty_tbl.EXTEND();
         IO_item_qty_tbl(IO_item_qty_tbl.COUNT) := bts_orditem_qty_rec(rec.head_item,
                                                                       rec.detail_item,
                                                                       L_orderable_qty,
                                                                       I_inv_status);
      END LOOP;
   else  --- Record(s) were found on the RTV/Allocation/Transfer
      ----
      --- To determine the quantity to use for each orderable item on the transfer/RTV/alloc,
      --- the following process is followed:
      ---    If transfer has not been fully shipped,
      ---       Find the remaining qty to fill for each orderable item
      ---       (associated with the sellable item) on the transfer/RTV/alloc.
      ---
      ---       (Note:  If the orderable item is already on O_orderable_TBL from a previous
      ---               sellable item, the qty from that O_orderable_TBL record
      ---               will be used to help determine the qty to fill. Check the cursors in
      ---               TSF_ORDERABLE_ITEM_INFO, RTV_ORDERABLE_ITEM_INFO, and ALLOC_ORDERABLE_ITEM_INFO.
      ---               Each cursor fetches the summed qty on O_orderable_TBL for the orderable item)
      ---
      ---        Qty to Fill = Expected Qty - Existing O_orderable_TBL Qty - Shipped Qty
      ---
      ---
      ---    If transfer/RTV/alloc has been fully shipped,
      ---       The qty to fill for each orderable item will be the item's Expected Qty.
      ----
      L_total_qty := 0;
      L_fully_shipped       := TRUE;
      ---
      FOR j IN IO_qty_to_fill_tbl.FIRST..IO_qty_to_fill_tbl.LAST LOOP
         if IO_qty_to_fill_tbl(j).qty_to_fill > 0 then
            L_fully_shipped := FALSE;
         end if;
         ---
         if IO_qty_to_fill_tbl(j).qty_to_fill <= 0 and
            L_fully_shipped then
            IO_qty_to_fill_tbl(j).qty_to_fill := IO_qty_to_fill_tbl(j).qty_requested;
         elsif IO_qty_to_fill_tbl(j).qty_to_fill < 0 then
            IO_qty_to_fill_tbl(j).qty_to_fill := 0;
         end if;
         ---
         ---  The total qty to fill for the sellable item is calculated
         ---  by summing the orderable items' qtys to fill.
         ---
         L_total_qty := L_total_qty + IO_qty_to_fill_tbl(j).qty_to_fill;
      END LOOP;
      ---
      FOR j IN IO_qty_to_fill_tbl.FIRST..IO_qty_to_fill_tbl.LAST LOOP
         ---
         ---  The qty for each orderable item is calculated by prorating
         ---  the orderable item's qty to fill against the total qty to fill.
         ---
         L_orderable_qty := I_sell_qty * (IO_qty_to_fill_tbl(j).qty_to_fill / L_total_qty);
         ---
         if L_orderable_qty != 0 then
            IO_item_qty_tbl.EXTEND();
            IO_item_qty_tbl(IO_item_qty_tbl.COUNT) := bts_orditem_qty_rec(IO_qty_to_fill_tbl(j).orderable_item,
                                                                          I_sell_item,
                                                                          L_orderable_qty,
                                                                          I_inv_status);
         end if;
      END LOOP;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END GET_QTY_TO_FILL;
-------------------------------------------------------------------------------------------------------------
FUNCTION GET_QTY_TO_FILL_EG(O_error_message       IN OUT        RTK_ERRORS.RTK_TEXT%TYPE,
                            IO_item_qty_tbl       IN OUT NOCOPY BTS_ORDITEM_QTY_TBL,
                            IO_qty_to_fill_tbl    IN OUT NOCOPY QTY_TO_FILL_TBL,
                            I_sell_item           IN            ITEM_MASTER.ITEM%TYPE,
                            I_sell_qty            IN            ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                            I_inv_status          IN            INV_STATUS_CODES.INV_STATUS%TYPE)
RETURN BOOLEAN IS


   L_module                  VARCHAR2(64) := 'ITEM_XFORM_SQL.GET_QTY_TO_FILL';

   L_orderable_qty           ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;
   L_total_qty               ITEM_LOC_SOH.STOCK_ON_HAND%TYPE := 0;

   L_fully_shipped           BOOLEAN := TRUE;

   L_exists                  VARCHAR2(1);
   L_head_item               ITEM_XFORM_HEAD.HEAD_ITEM%TYPE;
   L_yield_from_head         ITEM_XFORM_DETAIL.YIELD_FROM_HEAD_ITEM_PCT%TYPE;
   L_total_yield             ITEM_XFORM_DETAIL.YIELD_FROM_HEAD_ITEM_PCT%TYPE   :=0;

   cursor C_XFORM_INFO is
      select h.head_item,
             h.production_loss_pct,
             d.detail_item,
             d.yield_from_head_item_pct
        from item_xform_detail d, item_xform_head h
       where d.item_xform_head_id = h.item_xform_head_id
         and d.detail_item = I_sell_item;

   cursor C_CHECK_ORDLOC is
      select 'x'
        from ordloc
       where item = L_head_item;

BEGIN

   if IO_qty_to_fill_tbl is NULL or
      IO_qty_to_fill_tbl.COUNT = 0 then
      FOR rec IN C_XFORM_INFO LOOP
         L_exists                := NULL;
         L_head_item             := rec.head_item;
         L_yield_from_head       := rec.yield_from_head_item_pct;

         SQL_LIB.SET_MARK('OPEN',
                          'C_ORDLOC',
                          'ORDLOC',
                          L_head_item);
         open C_CHECK_ORDLOC;

         SQL_LIB.SET_MARK('FETCH',
                          'C_ORDLOC',
                          'ORDLOC',
                          L_head_item);
         fetch C_CHECK_ORDLOC into L_exists;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ORDLOC',
                          'ORDLOC',
                          L_head_item);
         close C_CHECK_ORDLOC;

         if L_exists is NOT NULL then
            L_total_yield        :=  L_total_yield + L_yield_from_head;
         end if;

      END LOOP;

      FOR rec IN C_XFORM_INFO LOOP

         L_exists                := NULL;
         L_head_item             := rec.head_item;
         L_yield_from_head       := rec.yield_from_head_item_pct;

         SQL_LIB.SET_MARK('OPEN',
                          'C_ORDLOC',
                          'ORDLOC',
                          L_head_item);
         open C_CHECK_ORDLOC;

         SQL_LIB.SET_MARK('FETCH',
                          'C_ORDLOC',
                          'ORDLOC',
                          L_head_item);
         fetch C_CHECK_ORDLOC into L_exists;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_ORDLOC',
                          'ORDLOC',
                          L_head_item);
         close C_CHECK_ORDLOC;

         if L_exists is NOT NULL then

            L_yield_from_head := (L_yield_from_head/L_total_yield) * 100;

            if GET_ORDERABLE_QTY(O_error_message,
                                 L_orderable_qty,
                                 I_sell_qty,
                                 rec.production_loss_pct,
                                 L_yield_from_head) = FALSE then
               return FALSE;
            end if;
            ---
            IO_item_qty_tbl.EXTEND();
            IO_item_qty_tbl(IO_item_qty_tbl.COUNT) := bts_orditem_qty_rec(rec.head_item,
                                                                          rec.detail_item,
                                                                          L_orderable_qty,
                                                                          I_inv_status);
         end if;
      END LOOP;
   else  --- Record(s) were found on the RTV/Allocation/Transfer
      ----
      --- To determine the quantity to use for each orderable item on the transfer/RTV/alloc,
      --- the following process is followed:
      ---    If transfer has not been fully shipped,
      ---       Find the remaining qty to fill for each orderable item
      ---       (associated with the sellable item) on the transfer/RTV/alloc.
      ---
      ---       (Note:  If the orderable item is already on O_orderable_TBL from a previous
      ---               sellable item, the qty from that O_orderable_TBL record
      ---               will be used to help determine the qty to fill. Check the cursors in
      ---               TSF_ORDERABLE_ITEM_INFO, RTV_ORDERABLE_ITEM_INFO, and ALLOC_ORDERABLE_ITEM_INFO.
      ---               Each cursor fetches the summed qty on O_orderable_TBL for the orderable item)
      ---
      ---        Qty to Fill = Expected Qty - Existing O_orderable_TBL Qty - Shipped Qty
      ---
      ---
      ---    If transfer/RTV/alloc has been fully shipped,
      ---       The qty to fill for each orderable item will be the item's Expected Qty.
      ----
      L_total_qty := 0;
      L_fully_shipped       := TRUE;
      ---
      FOR j IN IO_qty_to_fill_tbl.FIRST..IO_qty_to_fill_tbl.LAST LOOP
         if IO_qty_to_fill_tbl(j).qty_to_fill > 0 then
            L_fully_shipped := FALSE;
         end if;
         ---
         if IO_qty_to_fill_tbl(j).qty_to_fill <= 0 and
            L_fully_shipped then
            IO_qty_to_fill_tbl(j).qty_to_fill := IO_qty_to_fill_tbl(j).qty_requested;
         elsif IO_qty_to_fill_tbl(j).qty_to_fill < 0 then
            IO_qty_to_fill_tbl(j).qty_to_fill := 0;
         end if;
         ---
         ---  The total qty to fill for the sellable item is calculated
         ---  by summing the orderable items' qtys to fill.
         ---
         L_total_qty := L_total_qty + IO_qty_to_fill_tbl(j).qty_to_fill;
      END LOOP;
      ---
      FOR j IN IO_qty_to_fill_tbl.FIRST..IO_qty_to_fill_tbl.LAST LOOP
         ---
         ---  The qty for each orderable item is calculated by prorating
         ---  the orderable item's qty to fill against the total qty to fill.
         ---
         L_orderable_qty := I_sell_qty * (IO_qty_to_fill_tbl(j).qty_to_fill / L_total_qty);
         ---
         if L_orderable_qty != 0 then
            IO_item_qty_tbl.EXTEND();
            IO_item_qty_tbl(IO_item_qty_tbl.COUNT) := bts_orditem_qty_rec(IO_qty_to_fill_tbl(j).orderable_item,
                                                                          I_sell_item,
                                                                          L_orderable_qty,
                                                                          I_inv_status);
         end if;
      END LOOP;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_module,
                                            NULL);
      return FALSE;
END GET_QTY_TO_FILL_EG;
-------------------------------------------------------------------------------------------------------------
FUNCTION ORDERABLE_ITEM_INFO(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_orderable_TBL   OUT    BTS_ORDITEM_QTY_TBL,
                             I_sell_item_tbl   IN     ITEM_TBL,
                             I_sell_qty_tbl    IN     QTY_TBL)
RETURN BOOLEAN IS

   L_program    VARCHAR2(62) := 'ITEM_XFORM_SQL.ORDERABLE_ITEM_INFO';
   L_xform_no   NUMBER := 0;
   L_qty        NUMBER(12,4);

   cursor C_XFORM_INFO(I_item IN ITEM_MASTER.ITEM%TYPE) is
      select h.head_item,
             h.production_loss_pct,
             d.detail_item,
             d.yield_from_head_item_pct
        from item_xform_detail d, item_xform_head h
       where d.item_xform_head_id = h.item_xform_head_id
         and d.detail_item = I_item;

BEGIN
   O_orderable_TBL    := bts_orditem_qty_tbl();

   FOR i IN I_sell_item_tbl.FIRST..I_sell_item_tbl.LAST LOOP
      FOR rec IN C_XFORM_INFO(I_sell_item_tbl(i)) LOOP
         if GET_ORDERABLE_QTY(O_error_message,
                              L_qty,
                              I_sell_qty_tbl(i),
                              rec.production_loss_pct,
                              rec.yield_from_head_item_pct) = FALSE then
            return FALSE;
         end if;
         ---
         L_xform_no := L_xform_no + 1;
         O_orderable_TBL.EXTEND();
         O_orderable_TBL(L_xform_no) := bts_orditem_qty_rec(rec.head_item,
                                                            rec.detail_item,
                                                            L_qty,
                                                            NULL);
      END LOOP;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);

      return FALSE;

END ORDERABLE_ITEM_INFO;
-------------------------------------------------------------------------------------------------------------
FUNCTION GET_ORDERABLE_QTY(O_error_message          IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_orderable_qty             OUT ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                           I_sell_qty               IN     ITEM_LOC_SOH.STOCK_ON_HAND%TYPE,
                           I_prod_loss_pct          IN     ITEM_XFORM_HEAD.PRODUCTION_LOSS_PCT%TYPE,
                           I_yield_from_head_pct    IN     ITEM_XFORM_DETAIL.YIELD_FROM_HEAD_ITEM_PCT%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(64) := 'ITEM_XFORM_SQL.GET_ORDERABLE_QTY';

BEGIN

   if I_yield_from_head_pct is NULL then --- single orderable item
      O_orderable_qty := (I_sell_qty / (1-(NVL(I_prod_loss_pct,0)/100)));
   else --- multiple orderable items for a single sellable
      O_orderable_qty := (I_sell_qty * (I_yield_from_head_pct/100))/(1-(NVL(I_prod_loss_pct,0)/100));
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);

      return FALSE;

END GET_ORDERABLE_QTY;
-------------------------------------------------------------------------------------------------------------
FUNCTION XFORM_HEAD_DETAIL_COUNT(O_error_message              IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_multi_parent_ind           IN OUT   BOOLEAN,
                                 O_sum_of_yield_percentages   IN OUT   ITEM_XFORM_DETAIL.YIELD_FROM_HEAD_ITEM_PCT%TYPE,
                                 I_head_item                  IN       ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(60) := 'ITEM_XFORM_SQL.XFORM_HEAD_DETAIL_COUNT';
   L_detail_item   ITEM_XFORM_DETAIL.DETAIL_ITEM%TYPE;

   cursor C_IXD is
   select ixd.detail_item
     from item_xform_head        ixh,
          item_xform_detail      ixd,
          item_master            iem
    where (iem.item_parent            = I_head_item
          and iem.item                = ixh.head_item
          and ixh.item_xform_head_id  = ixd.item_xform_head_id)
       or (ixh.head_item              = I_head_item
          and ixh.item_xform_head_id  = ixd.item_xform_head_id
          and iem.item                = ixh.head_item);

BEGIN

   if I_head_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_IXD',
                    'item_xform_detail',
                    NULL);
   open C_IXD;
   ---
   SQL_LIB.SET_MARK('FETCH',
                    'C_IXD',
                    'item_xform_detail',
                    NULL);
   fetch C_IXD into L_detail_item;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_IXD',
                    'item_xform_detail',
                    NULL);
   close C_IXD;

   if ITEM_XFORM_SQL.CHECK_MULTI_PARENTS(O_error_message,
                                         O_multi_parent_ind,
                                         L_detail_item) = FALSE then
      return FALSE;
   end if;

   if O_multi_parent_ind = TRUE then
      if ITEM_XFORM_SQL.GET_SUM_OF_YIELD_PERCENTAGES(O_error_message,
                                                     O_sum_of_yield_percentages,
                                                     L_detail_item) = FALSE then
         return FALSE;
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

END XFORM_HEAD_DETAIL_COUNT;
-----------------------------------------------------------------------------------------------------------------
END ITEM_XFORM_SQL;
/

