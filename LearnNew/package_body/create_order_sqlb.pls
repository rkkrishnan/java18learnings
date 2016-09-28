CREATE OR REPLACE PACKAGE BODY CREATE_ORDER_SQL AS

LP_invc_id             invc_non_merch_temp.invc_id%TYPE     := NULL;
LP_order_type          ordhead.order_type%type              := NULL;
LP_qty_sum             shipsku.qty_received%TYPE            := 0;
LP_cost_sum            item_supp_country.unit_cost%TYPE     := 0;
LP_supp_currency_code  sups.currency_code%TYPE              := NULL;
LP_shipment            shipment.shipment%TYPE               := NULL;
LP_dept_level_orders   unit_options.dept_level_orders%TYPE  := NULL;
-----------------------BULK BIND VARS-------------------------------
------------------for ordauto_temp insert---------------------------
TYPE order_no_TBL           is table of ordhead.order_no%TYPE          INDEX BY BINARY_INTEGER;
TYPE item_TBL               is table of item_master.item%TYPE          INDEX BY BINARY_INTEGER;
TYPE ref_item_TBL           is table of item_master.item%TYPE          INDEX BY BINARY_INTEGER;
TYPE supplier_TBL           is table of sups.supplier%TYPE             INDEX BY BINARY_INTEGER;
TYPE dept_TBL               is table of deps.dept%TYPE                 INDEX BY BINARY_INTEGER;
TYPE store_TBL              is table of store.store%TYPE               INDEX BY BINARY_INTEGER;
TYPE qty_received_TBL       is table of ordloc.qty_received%TYPE       INDEX BY BINARY_INTEGER;
TYPE standard_uom_TBL       is table of item_master.standard_uom%TYPE  INDEX BY BINARY_INTEGER;
TYPE unit_cost_TBL          is table of ordloc.unit_cost%TYPE          INDEX BY BINARY_INTEGER;
TYPE currency_code_TBL      is table of sups.currency_code%TYPE        INDEX BY BINARY_INTEGER;
TYPE unit_retail_TBL        is table of ordloc.unit_retail%TYPE        INDEX BY BINARY_INTEGER;
TYPE origin_country_id_TBL  is table of ordsku.origin_country_id%TYPE  INDEX BY BINARY_INTEGER;
TYPE cost_source_TBL        is table of ordloc.cost_source%TYPE        INDEX BY BINARY_INTEGER;

TYPE weight_received_TBL       is table of shipsku.weight_received%TYPE       INDEX BY BINARY_INTEGER;
TYPE weight_received_uom_TBL   is table of shipsku.weight_received_uom%TYPE   INDEX BY BINARY_INTEGER;

LP_head_order_no       order_no_TBL;
LP_head_supplier       supplier_TBL;
LP_head_dept           dept_TBL;
LP_head_currency_code  currency_code_TBL;

LP_head_count           NUMBER := 0;

LPA_order_no           order_no_TBL;
LPA_item               item_TBL;
LPA_ref_item           ref_item_TBL;
LPA_supplier           supplier_TBL;
LPA_dept               dept_TBL;
LPA_store              store_TBL;
LPA_qty_received       qty_received_TBL;
LPA_standard_uom       standard_uom_TBL;
LPA_unit_cost          unit_cost_TBL;
LPA_currency_code      currency_code_TBL;
LPA_unit_retail        unit_retail_TBL;
LPA_origin_country_id  origin_country_id_TBL;
LPA_cost_source        cost_source_TBL;

LPA_weight_received       weight_received_TBL;
LPA_weight_received_uom   weight_received_uom_TBL;

L_ordauto_temp_insert_size NUMBER := 0;

-----------------------------------------------------------------------------------------
FUNCTION PROCESS_ITEM(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      I_order_no             IN      ordhead.order_no%TYPE,
                      I_item                 IN      item_master.item%TYPE,
                      I_ref_item             IN      item_master.item%TYPE,
                      I_qty_received         IN      shipsku.qty_received%TYPE,
                      I_unit_cost            IN      item_supp_country.unit_cost%TYPE,
                      I_store                IN      store.store%TYPE,
                      I_supplier             IN      sups.supplier%TYPE,
                      I_dept                 IN      deps.dept%TYPE,
                      I_origin_country_id    IN      item_supp_country.origin_country_id%TYPE,
                      I_currency_code        IN      sups.currency_code%TYPE,
                      I_item_loc_status      IN      ITEM_LOC.STATUS%TYPE,
                      I_weight_received      IN      SHIPSKU.WEIGHT_RECEIVED%TYPE,
                      I_weight_received_uom  IN      SHIPSKU.WEIGHT_RECEIVED_UOM%TYPE)
RETURN BOOLEAN;
-------------------------------------------------------------------------------------------------------
FUNCTION EXPLODE_PACK(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      I_order_no             IN      ordhead.order_no%TYPE,
                      I_pack_no              IN      item_master.item%TYPE,
                      I_ref_item             IN      item_master.item%TYPE,
                      I_qty_received         IN      shipsku.qty_received%TYPE,
                      I_store                IN      store.store%TYPE,
                      I_supplier             IN      sups.supplier%TYPE,
                      I_dept                 IN      deps.dept%TYPE,
                      I_origin_country_id    IN      item_supp_country.origin_country_id%TYPE,
                      I_currency_code        IN      sups.currency_code%TYPE,
                      I_item_loc_status      IN      ITEM_LOC.STATUS%TYPE)
RETURN BOOLEAN;
-----------------------------------------------------------------------------------------

FUNCTION PROCESS_NMEXP(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                       I_non_merch_code       IN      invc_non_merch_temp.non_merch_code%TYPE,
                       I_non_merch_amt        IN      invc_non_merch_temp.non_merch_amt%TYPE,
                       I_vat_code             IN      invc_non_merch_temp.vat_code%TYPE,
                       I_service_perf_ind     IN      invc_non_merch_temp.service_perf_ind%TYPE,
                       I_store                IN      store.store%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'CREATE_ORDER_SQL.PROCESS_NMEXP';
   L_exists  VARCHAR2(1) := NULL;
   L_invc_id invc_non_merch_temp.invc_id%TYPE := NULL;

   CURSOR c_validate_non_merch_code IS
      SELECT 'Y'
        FROM non_merch_code_head
       WHERE non_merch_code = I_non_merch_code;

   CURSOR c_validate_vat_code IS
      SELECT 'Y'
        FROM vat_codes
       WHERE vat_code = I_vat_code;

   CURSOR c_non_merch_exists IS
      SELECT 'Y'
        FROM invc_non_merch_temp
       WHERE non_merch_code = I_non_merch_code
         AND invc_id = LP_invc_id;
BEGIN
   OPEN c_validate_non_merch_code;
   FETCH c_validate_non_merch_code into L_exists;
   if L_exists is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_NON_MERCH_CODE', I_non_merch_code, NULL, NULL);
      return FALSE;
   end if;
   /** validate vat_code **/
   if I_vat_code is not NULL then
      L_exists := NULL;
      OPEN c_validate_vat_code;
      FETCH c_validate_vat_code into L_exists;
      if L_exists is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INV_VAT_LOC', I_vat_code, NULL, NULL);
         return FALSE;
      end if;
   end if;

   /** Validate service_performed_ind. **/
   if ((I_service_perf_ind != 'Y') and
       (I_service_perf_ind != 'N')) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_SERVICE_PERF_IND', I_service_perf_ind, NULL, NULL);
      return FALSE;
   end if;

   /** if this is the first non-merch expense record then    **/
   /** we need to generate an invoice number for insert into **/
   /** invc_non_merch_temp table and to pass as parameter    **/
   /** for create_invc()                                     **/
   if LP_invc_id is NULL then
      if INVC_SQL.NEXT_INVC_ID(O_error_message,
                               LP_invc_id) = FALSE then
         return FALSE;
      end if;
   end if;

   /** see if this non_merch_code already exists on table **/
   L_exists := NULL;
   OPEN c_non_merch_exists;
   FETCH c_non_merch_exists into L_exists;

   if L_exists = 'Y' then
      O_error_message := SQL_LIB.CREATE_MSG('NMERCH_CODE_EXISTS', I_non_merch_code, LP_invc_id, NULL);
      return FALSE;
   end if;

   /** insert non-merch records **/
   INSERT INTO invc_non_merch_temp
              (invc_id,
               non_merch_code,
               non_merch_amt,
               vat_code,
               service_perf_ind,
               store)
       VALUES (LP_invc_id,
               I_non_merch_code,
               I_non_merch_amt,
               I_vat_code,
               I_service_perf_ind,
               I_store);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END PROCESS_NMEXP;
-----------------------------------------------------------------------------------------
FUNCTION PROCESS_DETAIL(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                        I_order_no             IN      ORDHEAD.ORDER_NO%TYPE,
                        I_item                 IN      ITEM_MASTER.ITEM%TYPE,
                        I_qty_received         IN      SHIPSKU.QTY_RECEIVED%TYPE,
                        I_store                IN      STORE.STORE%TYPE,
                        I_supplier             IN      SUPS.SUPPLIER%TYPE,
                        I_dept                 IN      DEPS.DEPT%TYPE,
                        I_origin_country_id    IN      ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                        I_currency_code        IN      SUPS.CURRENCY_CODE%TYPE,
                        I_item_loc_status      IN      ITEM_LOC.STATUS%TYPE,
                        I_weight_received      IN      SHIPSKU.WEIGHT_RECEIVED%TYPE,
                        I_weight_received_uom  IN      SHIPSKU.WEIGHT_RECEIVED_UOM%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(50)                := 'CREATE_ORDER_SQL.PROCESS_DETAIL';

BEGIN

   if PROCESS_DETAIL(O_error_message,
                     I_order_no,
                     I_item,
                     I_qty_received,
                     I_store,
                     I_supplier,
                     I_dept,
                     I_origin_country_id,
                     I_currency_code,
                     I_item_loc_status,
                     I_weight_received,
                     I_weight_received_uom,
                     null) = FALSE then
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
END PROCESS_DETAIL;

-----------------------------------------------------------------------------------------
FUNCTION PROCESS_DETAIL(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                        I_order_no             IN      ORDHEAD.ORDER_NO%TYPE,
                        I_item                 IN      ITEM_MASTER.ITEM%TYPE,
                        I_qty_received         IN      SHIPSKU.QTY_RECEIVED%TYPE,
                        I_store                IN      STORE.STORE%TYPE,
                        I_supplier             IN      SUPS.SUPPLIER%TYPE,
                        I_dept                 IN      DEPS.DEPT%TYPE,
                        I_origin_country_id    IN      ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
                        I_currency_code        IN      SUPS.CURRENCY_CODE%TYPE,
                        I_item_loc_status      IN      ITEM_LOC.STATUS%TYPE,
                        I_weight_received      IN      SHIPSKU.WEIGHT_RECEIVED%TYPE,
                        I_weight_received_uom  IN      SHIPSKU.WEIGHT_RECEIVED_UOM%TYPE,
                        I_unit_cost            IN      ITEM_SUPP_COUNTRY.UNIT_COST%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(50)                := 'CREATE_ORDER_SQL.PROCESS_DETAIL';
   L_item        item_master.item%TYPE       := NULL;
   L_ref_item    item_master.item%TYPE       := NULL;
   L_item_parent item_master.item%TYPE       := NULL;
   L_item_level  item_master.item_level%TYPE := NULL;
   L_tran_level  item_master.tran_level%TYPE := NULL;
   L_status      item_master.status%TYPE     := NULL;

   CURSOR c_item_levels IS
      SELECT item_parent,
             item_level,
             tran_level,
             status
        FROM item_master
       WHERE item = I_item;

BEGIN
   /** Validate qty is greater than 0. **/
   if I_qty_received <= 0 then
      O_error_message := SQL_LIB.CREATE_MSG('QTY_GREATER_THAN_ZERO_QTY', I_qty_received, NULL, NULL);
      return FALSE;
   end if;

   /** determine if this is a reference item **/
   OPEN c_item_levels;
   FETCH c_item_levels INTO L_item_parent,
                            L_item_level,
                            L_tran_level,
                            L_status;

   if L_item_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_ITEM', I_item, NULL, NULL);
      return FALSE;
   end if;

   /** Check that the status of the item is Approved. **/
   if L_status != 'A' then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_NOT_APPROVED', I_item, NULL, NULL);
      return FALSE;
   end if;

   /** if the item level is equal to the tran level, then we write the order **/
   /** using this item (ref_item will be null);                              **/
   if L_item_level = L_tran_level then
      L_item := I_item;
      L_ref_item := NULL;
   /** if the item level is 1 below the tran level, then this is a    **/
   /** ref_item and we need to use the item parent to write the order **/
   elsif ((L_item_level - L_tran_level) = 1) then
      L_item := L_item_parent;
      L_ref_item := I_item;
   /** if anything other than the above 2 cases, then orders cannot be written for this item **/
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_LEVEL_ITEM_LEVEL', I_item, L_item_level, NULL);
      return FALSE;
   end if;

   /** Validate the item and insert records to ordauto_temp. **/
   if PROCESS_ITEM(O_error_message,
                   I_order_no,
                   L_item,
                   L_ref_item,
                   I_qty_received,
                   I_unit_cost,
                   I_store,
                   I_supplier,
                   I_dept,
                   I_origin_country_id,
                   I_currency_code,
                   I_item_loc_status,
                   I_weight_received,
                   I_weight_received_uom) = FALSE then
      return FALSE;
   end if;

   RETURN TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END PROCESS_DETAIL;
-----------------------------------------------------------------------------------------
FUNCTION PROCESS_ITEM(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      I_order_no             IN      ordhead.order_no%TYPE,
                      I_item                 IN      item_master.item%TYPE,
                      I_ref_item             IN      item_master.item%TYPE,
                      I_qty_received         IN      shipsku.qty_received%TYPE,
                      I_unit_cost            IN      item_supp_country.unit_cost%TYPE,
                      I_store                IN      store.store%TYPE,
                      I_supplier             IN      sups.supplier%TYPE,
                      I_dept                 IN      deps.dept%TYPE,
                      I_origin_country_id    IN      item_supp_country.origin_country_id%TYPE,
                      I_currency_code        IN      sups.currency_code%TYPE,
                      I_item_loc_status      IN      ITEM_LOC.STATUS%TYPE,
                      I_weight_received      IN      SHIPSKU.WEIGHT_RECEIVED%TYPE,
                      I_weight_received_uom  IN      SHIPSKU.WEIGHT_RECEIVED_UOM%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50)            := 'CREATE_ORDER_SQL.PROCESS_ITEM';
   L_dept    item_master.dept%TYPE   := NULL;
   L_status  item_master.status%TYPE := NULL;
   L_standard_uom  item_master.standard_uom%TYPE := NULL;
   L_pack_ind  item_master.pack_ind%TYPE := NULL;
   L_orderable_ind  item_master.orderable_ind%TYPE := NULL;
   L_item_xform_ind  item_master.item_xform_ind%TYPE := NULL;
   L_pack_type  item_master.pack_type%TYPE := NULL;
   L_order_as_type  item_master.order_as_type%TYPE := NULL;
   L_purchase_type  deps.purchase_type%TYPE := NULL;
   L_sellable_ind  item_master.sellable_ind%TYPE := NULL;
   L_selling_retail     ITEM_ZONE_PRICE.SELLING_UNIT_RETAIL%TYPE := NULL;
   L_selling_uom        ITEM_ZONE_PRICE.SELLING_UOM%TYPE := NULL;
   L_multi_units        ITEM_ZONE_PRICE.MULTI_UNITS%TYPE := NULL;
   L_multi_unit_retail  ITEM_ZONE_PRICE.MULTI_UNIT_RETAIL%TYPE := NULL;
   L_multi_uom          ITEM_ZONE_PRICE.MULTI_SELLING_UOM%TYPE := NULL;

   L_item_loc_status VARCHAR2(1) := NULL;
   L_exists VARCHAR2(1) := NULL;
   L_unit_cost item_supp_country.unit_cost%TYPE := NULL;
   L_unit_retail item_loc.unit_retail%TYPE := NULL;
   L_supplier item_supp_country.supplier%TYPE := NULL;
   L_origin_country_id item_supp_country.origin_country_id%TYPE := NULL;
   L_store store.store%TYPE := NULL;
   L_currency_code sups.currency_code%TYPE := NULL;
   L_iscl_unit_cost    ITEM_SUPP_COUNTRY_LOC.UNIT_COST%TYPE     := NULL;

   CURSOR c_item_info IS
      SELECT im.dept,
             im.status,
             im.standard_uom,
             im.pack_ind,
             im.sellable_ind,
             im.orderable_ind,
             im.item_xform_ind,
             im.pack_type,
             im.order_as_type,
             d.purchase_type
        FROM item_master im,
             deps        d
       WHERE im.item = I_item
         AND d.dept  = im.dept;

   CURSOR c_item_loc IS
      SELECT status
        FROM item_loc
       WHERE item     = I_item
         AND loc      = I_store
         AND loc_type = 'S';

   CURSOR c_item_supp IS
      SELECT 'Y'
        FROM item_supplier
       WHERE item     = I_item
         AND supplier = I_supplier;

BEGIN
   /** Get the item information **/
   OPEN c_item_info;
   FETCH c_item_info INTO L_dept,
                          L_status,
                          L_standard_uom,
                          L_pack_ind,
                          L_sellable_ind,
                          L_orderable_ind,
                          L_item_xform_ind,
                          L_pack_type,
                          L_order_as_type,
                          L_purchase_type;
   if L_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_ITEM', I_item, NULL, NULL);
      return FALSE;
   end if;
   /** Check that the status of the item is approved. **/
   if L_status != 'A' then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_NOT_APPROVED', I_item, NULL, NULL);
      return FALSE;
   end if;

   /** Validate dept is not consignment. **/
   if (L_purchase_type = 1) then
      O_error_message := SQL_LIB.CREATE_MSG('CSMT_ITEMS_ITEM', I_item, NULL, NULL);
      return FALSE;
   end if;

   /** Check pack indicators. **/
   if (L_pack_ind = 'Y') then
      if (L_orderable_ind = 'N') then
         O_error_message := SQL_LIB.CREATE_MSG('PACK_NOT_ORDERABLE', I_item, NULL, NULL);
         return FALSE;
      end if;
   end if;

   /** Validate item_loc exists. */
   if I_item_loc_status is NULL then
      OPEN c_item_loc;
      FETCH c_item_loc INTO L_item_loc_status;
      CLOSE c_item_loc;
      if (L_item_loc_status is NULL) then
         /* create an item_loc record since it doesn't exist */
         if NEW_ITEM_LOC(O_error_message,
                         I_item,
                         I_store,
                         NULL,
                         NULL,
                         'S',                 /* store */
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         'A',                 /* make item/loc record Active */
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
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
   else
      L_item_loc_status := I_item_loc_status;
   end if;

   /** All items must have same dept when dept_level_orders = 'Y' other than DSD Orders. **/
   if (LP_dept_level_orders = 'Y') and LP_order_type != 'DSD' then
      /** compare each dept to the transaction level dept **/
      if (I_dept != L_dept) then
         O_error_message := SQL_LIB.CREATE_MSG('DEPT_REQUIRED_DEPT', I_dept, NULL, NULL);
         return FALSE;
      end if;
   end if;

   /** Validate item_supplier exists. **/
   L_exists := 'N';
   OPEN c_item_supp;
   FETCH c_item_supp INTO L_exists;

   if (L_exists = 'N') then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_SUPP_ITM_SUPP', I_item, I_supplier, NULL);
      return FALSE;
   end if;

   /** If this is a buyer pack, ordered as eaches, then we need to explode the pack. **/
   /** For each item in the pack we will call process_item to validate and insert.   **/
   if ((L_pack_ind      = 'Y') and
       (L_pack_type     = 'B') and
       (L_order_as_type = 'E')) then
      if (EXPLODE_PACK(O_error_message,
                       I_order_no,
                       I_item,
                       I_ref_item,
                       I_qty_received,
                       I_store,
                       I_supplier,
                       I_dept,
                       I_origin_country_id,
                       I_currency_code,
                       I_item_loc_status)) = FALSE then
         return FALSE;
      end if;
   /** This is not a pack we need to explode, so continue. **/
   else
      /** Get unit cost. **/
      L_supplier := I_supplier;
      L_origin_country_id := I_origin_country_id;
      L_store := I_store;

      if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                L_iscl_unit_cost,
                                I_item,
                                L_supplier,
                                L_origin_country_id,
                                L_store) = FALSE then
         return FALSE;
      end if;

      if I_unit_cost is NOT NULL then
         L_unit_cost := I_unit_cost;
      else
         L_unit_cost := L_iscl_unit_cost;
         /** If supplier currency is not same as order currency then convert. **/
         if (LP_supp_currency_code != I_currency_code) then
            L_currency_code := I_currency_code;
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_unit_cost,
                                    LP_supp_currency_code,
                                    L_currency_code,
                                    L_unit_cost,
                                    'C',
                                    NULL,
                                    'P') = FALSE then
               return FALSE;
            end if;
         end if; /* end currency conversion */
      end if;

      /* end get cost */
      /** Sum the qty and qty*cost for invoicing. **/
      LP_qty_sum  := LP_qty_sum  + I_qty_received;
      LP_cost_sum := LP_cost_sum + (L_unit_cost * I_qty_received);

      /** Get unit_retail. **/
      if ((L_pack_ind = 'Y') and (L_sellable_ind = 'N')) then
         /** This is a non-sellable pack so we need to build the retail. **/
         if PRICING_ATTRIB_SQL.BUILD_PACK_RETAIL(O_error_message,
                                                 L_unit_retail,
                                                 I_item,
                                                 'S',
                                                 I_store) = FALSE then
            return FALSE;
         end if;
      elsif L_item_xform_ind = 'Y' and L_orderable_ind = 'Y' then
          if ITEM_XFORM_SQL.CALCULATE_RETAIL(O_error_message,
                                             I_item,
                                             I_store,
                                             L_unit_retail) = FALSE then
             return FALSE;
          end if;
      else
         /** Not a non-sellable pack so just get retail. **/
         if PRICING_ATTRIB_SQL.GET_RETAIL(O_error_message,
                                          L_unit_retail,
                                          L_standard_uom,
                                          L_selling_retail,
                                          L_selling_uom,
                                          L_multi_units,
                                          L_multi_unit_retail,
                                          L_multi_uom,
                                          I_item,
                                          'S',
                                          I_store) = FALSE then
            return FALSE;
         end if;
      end if;  /* end get unit retail */

      /** insert into ordauto_temp **/
      L_ordauto_temp_insert_size := L_ordauto_temp_insert_size + 1;

      LPA_order_no(L_ordauto_temp_insert_size) := I_order_no;
      LPA_item(L_ordauto_temp_insert_size) := I_item;
      LPA_ref_item(L_ordauto_temp_insert_size) := I_ref_item;
      LPA_supplier(L_ordauto_temp_insert_size) := I_supplier;
      LPA_dept(L_ordauto_temp_insert_size) := I_dept;
      LPA_store(L_ordauto_temp_insert_size) := I_store;
      LPA_qty_received(L_ordauto_temp_insert_size) := I_qty_received;
      LPA_standard_uom(L_ordauto_temp_insert_size) := L_standard_uom;
      LPA_unit_cost(L_ordauto_temp_insert_size) := L_unit_cost;
      LPA_currency_code(L_ordauto_temp_insert_size) := I_currency_code;
      LPA_unit_retail(L_ordauto_temp_insert_size) := L_unit_retail;
      LPA_origin_country_id(L_ordauto_temp_insert_size) := I_origin_country_id;
      LPA_weight_received(L_ordauto_temp_insert_size) := I_weight_received;
      LPA_weight_received_uom(L_ordauto_temp_insert_size) := I_weight_received_uom;
      -- Check if unit cost was manually overwritten.  Then, assign cost source respectively.
      LPA_cost_source(L_ordauto_temp_insert_size) := 'NORM';
      if I_unit_cost is NOT NULL then
         if (LP_supp_currency_code != I_currency_code) then
            L_currency_code := I_currency_code;
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_iscl_unit_cost,
                                    LP_supp_currency_code,
                                    L_currency_code,
                                    L_iscl_unit_cost,
                                    'C',
                                    NULL,
                                    'P') = FALSE then
               return FALSE;
            end if;
         end if; /* end currency conversion */

         if I_unit_cost <> L_iscl_unit_cost then
            LPA_cost_source(L_ordauto_temp_insert_size) := 'MANL';
         end if;
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
END PROCESS_ITEM;
-----------------------------------------------------------------------------------------
FUNCTION EXPLODE_PACK(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      I_order_no             IN      ordhead.order_no%TYPE,
                      I_pack_no              IN      item_master.item%TYPE,
                      I_ref_item             IN      item_master.item%TYPE,
                      I_qty_received         IN      shipsku.qty_received%TYPE,
                      I_store                IN      store.store%TYPE,
                      I_supplier             IN      sups.supplier%TYPE,
                      I_dept                 IN      deps.dept%TYPE,
                      I_origin_country_id    IN      item_supp_country.origin_country_id%TYPE,
                      I_currency_code        IN      sups.currency_code%TYPE,
                      I_item_loc_status      IN      ITEM_LOC.STATUS%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50) := 'CREATE_ORDER_SQL.EXPLODE_PACK';
   L_records_found BOOLEAN      := false;

   CURSOR c_pack_items IS
      SELECT item,
             qty
        FROM v_packsku_qty
       WHERE pack_no = I_pack_no;

BEGIN
   /** Process each item in the pack. **/
   FOR rec IN c_pack_items LOOP
      if (PROCESS_ITEM(O_error_message,
                       I_order_no,
                       rec.item,
                       I_ref_item,
                       I_qty_received * rec.qty,
                       NULL,
                       I_store,
                       I_supplier,
                       I_dept,
                       I_origin_country_id,
                       I_currency_code,
                       I_item_loc_status,
                       null,                 -- weight_received
                       null)) = FALSE then   -- weight_received_uom
         return FALSE;
      end if;
      L_records_found := true;
   END LOOP;

   if (L_records_found = false) then
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEMS_IN_PACK_PACK', I_pack_no, NULL, NULL);
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
END EXPLODE_PACK;
-----------------------------------------------------------------------------------------
FUNCTION PROCESS_HEAD(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                      O_order_no             IN OUT  ordhead.order_no%TYPE,
                      I_store                IN      store.store%TYPE,
                      I_supplier             IN      sups.supplier%TYPE,
                      I_dept                 IN      deps.dept%TYPE,
                      I_origin_country_id    IN      item_supp_country.origin_country_id%TYPE,
                      I_currency_code        IN      sups.currency_code%TYPE,
                      I_paid_ind             IN      INVC_HEAD.PAID_IND%TYPE,
                      I_deals_ind            IN      VARCHAR2,
                      I_invoice_ind          IN      VARCHAR2,
                      I_ext_ref_no           IN      INVC_HEAD.EXT_REF_NO%TYPE,
                      I_proof_of_delivery_no IN      INVC_HEAD.PROOF_OF_DELIVERY_NO%TYPE,
                      I_payment_ref_no       IN      INVC_HEAD.PAYMENT_REF_NO%TYPE,
                      I_ext_receipt_no       IN      SHIPMENT.EXT_REF_NO_IN%TYPE,
                      I_order_type           IN      ORDHEAD.ORDER_TYPE%TYPE,
                      I_dept_level_orders    IN      UNIT_OPTIONS.DEPT_LEVEL_ORDERS%TYPE)
RETURN BOOLEAN IS

   L_program       VARCHAR2(50)             := 'CREATE_ORDER_SQL.PROCESS_HEAD';
   L_exists        VARCHAR2(1)              := NULL;
   L_status        item_master.status%type  := NULL;
   L_purchase_type deps.purchase_type%type  := NULL;
   L_order_no      ordhead.order_no%TYPE    := NULL;

   CURSOR c_validate_sup IS
      SELECT 'Y',
             sup_status,
             currency_code
        FROM sups
       WHERE supplier = I_supplier;

   CURSOR c_validate_country IS
      SELECT 'Y'
        FROM country
       WHERE country_id = I_origin_country_id;

   CURSOR c_validate_store IS
      SELECT 'Y'
        FROM store
       WHERE store = I_store;

   CURSOR c_validate_dept IS
      SELECT 'Y',
             purchase_type
        FROM deps
       WHERE dept = I_dept;

   CURSOR c_validate_currency IS
      SELECT 'Y'
        FROM currencies
       WHERE currency_code = I_currency_code;
BEGIN
   /** validate supplier **/
   OPEN c_validate_sup;
   FETCH c_validate_sup into L_exists,
                             L_status,
                             LP_supp_currency_code;
   if (L_exists is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_SUPP_SUPP', I_supplier, NULL, NULL);
      return FALSE;
   end if;

   if (L_status != 'A') then
      O_error_message := SQL_LIB.CREATE_MSG('INACTIVE_SUPPLIER_SUPP', I_supplier, NULL, NULL);
      return FALSE;
   end if;

   /** validate country **/
   L_exists := NULL;
   OPEN c_validate_country;
   FETCH c_validate_country into L_exists;

   if (L_exists is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_COUNTRY_COUNTRY', I_origin_country_id, NULL, NULL);
      return FALSE;
   end if;

   /** validate store **/
   L_exists := NULL;
   OPEN c_validate_store;
   FETCH c_validate_store into L_exists;

   if (L_exists is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_STORE_STORE', I_store, NULL, NULL);
      return FALSE;
   end if;

   /** Department is required when dept_level_orders = Y other than DSD Orders; if dept is null then write error. **/
   if ((I_dept_level_orders = 'Y') and (I_dept is NULL) and (I_order_type != 'DSD')) then
      O_error_message := SQL_LIB.CREATE_MSG('DEPT_REQUIRED', NULL, NULL, NULL);
      return FALSE;
   end if;

   LP_dept_level_orders := I_dept_level_orders;

   /** Validate the department if it is not null. **/
   if (I_dept is not NULL) then
      L_exists := NULL;
      OPEN c_validate_dept;
      FETCH c_validate_dept into L_exists,
                                 L_purchase_type;

      if (L_exists is NULL) then
         O_error_message := SQL_LIB.CREATE_MSG('INV_DEPT_DEPT', I_dept, NULL, NULL);
         return FALSE;
      end if;

      if (L_purchase_type = 1) then
         O_error_message := SQL_LIB.CREATE_MSG('CSMT_ITEMS_DEPT', I_dept, NULL, NULL);
         return FALSE;
      end if;

   end if; /* end validate dept */

   /** validate currency **/
   L_exists := NULL;
   OPEN c_validate_currency;
   FETCH c_validate_currency into L_exists;

   if (L_exists is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_CURR_CURR', I_currency_code, NULL, NULL);
      return FALSE;
   end if;

   if I_order_type not in ('DSD', 'N/B') then
      O_error_message := SQL_LIB.CREATE_MSG('ORD_TYPE_NB_DSD', L_program, NULL, NULL);
      return FALSE;
   end if;

   if I_order_type = 'DSD' then
      /** Validate paid_ind. **/
      if ((I_paid_ind != 'Y') and
          (I_paid_ind != 'N')) then
         O_error_message := SQL_LIB.CREATE_MSG('INV_PAID_IND', I_paid_ind, NULL, NULL);
         return FALSE;
      end if;

      /** Must have an ext_ref_no and/or proof_of_delivery_no and/or payment_ref_no if invc_ind = 'Y'. **/
      if ((I_invoice_ind              = 'Y') and
          (I_ext_ref_no               is NULL)  and
          (I_proof_of_delivery_no     is NULL)  and
          (I_payment_ref_no           is NULL)) then
         O_error_message := SQL_LIB.CREATE_MSG('EXT_REF_NO_REQUIRED', NULL, NULL, NULL);
         return FALSE;
      end if;

      /** Validate invoice_ind. **/
      if ((I_invoice_ind != 'Y') and
          (I_invoice_ind != 'N')) then
         O_error_message := SQL_LIB.CREATE_MSG('INV_INVC_IND_INVC_IND', I_invoice_ind, NULL, NULL);
         return FALSE;
      end if;

      /** Validate deals_ind. **/
      if ((I_deals_ind != 'Y') and
          (I_deals_ind != 'N')) then
         O_error_message := SQL_LIB.CREATE_MSG('INV_DEALS_IND_DEALS_IND', I_deals_ind, NULL, NULL);
         return FALSE;
      end if;

      /** Validate external receipt no **/
      if I_ext_receipt_no is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM_EXP', 'I_ext_receipt_no', 'NULL', 'NOT NULL');
         return FALSE;
      end if;
   end if;  /* end if order_type = 'DSD' */

   /** fetch an order number **/
   if ORDER_NUMBER_SQL.NEXT_ORDER_NUMBER(O_error_message,
                                         L_order_no) = FALSE then
      return FALSE;
   end if;

   LP_order_type := I_order_type;

   LP_head_count := LP_head_count + 1;

   LP_head_order_no(LP_head_count)       := L_order_no;
   LP_head_supplier(LP_head_count)       := I_supplier;
   LP_head_dept(LP_head_count)           := I_dept;
   LP_head_currency_code(LP_head_count)  := I_currency_code;

   O_order_no := L_order_no;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END PROCESS_HEAD;
-----------------------------------------------------------------------------------------
FUNCTION COMPLETE_DSD_TRANSACTION(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                  O_dsd_deals_rec           OUT  RIB_DSDDeals_REC,
                                  I_order_no             IN      ordhead.order_no%TYPE,
                                  I_store                IN      store.store%TYPE,
                                  I_supplier             IN      sups.supplier%TYPE,
                                  I_dept                 IN      deps.dept%TYPE,
                                  I_invoice_ind          IN      VARCHAR2,
                                  I_currency_code        IN      sups.currency_code%TYPE,
                                  I_paid_ind             IN      INVC_HEAD.PAID_IND%TYPE,
                                  I_deals_ind            IN      VARCHAR2,
                                  I_ext_ref_no           IN      INVC_HEAD.EXT_REF_NO%TYPE,
                                  I_proof_of_delivery_no IN      INVC_HEAD.PROOF_OF_DELIVERY_NO%TYPE,
                                  I_payment_ref_no       IN      INVC_HEAD.PAYMENT_REF_NO%TYPE,
                                  I_payment_date         IN      INVC_HEAD.PAYMENT_DATE%TYPE,
                                  I_ext_receipt_no       IN      SHIPMENT.EXT_REF_NO_IN%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(50)  := 'CREATE_ORDER_SQL.COMPLETE_DSD_TRANSACTION';

BEGIN
   if COMPLETE_TRANSACTION(O_error_message) = FALSE then
      return FALSE;
   end if;

   /** insert shipment records **/
   if SHIPMENT_ATTRIB_SQL.NEXT_SHIPMENT(O_error_message,
                                        LP_shipment) = FALSE then
      return false;
   end if;

   O_dsd_deals_rec := RIB_DSDDeals_REC(1, I_order_no, I_supplier, I_store, I_dept, I_currency_code,
                                       I_paid_ind, I_ext_ref_no, I_proof_of_delivery_no, I_payment_ref_no,
                                       I_payment_date, I_deals_ind, LP_shipment, LP_invc_id, I_invoice_ind,
                                       GET_VDATE, LP_qty_sum, LP_cost_sum, I_ext_receipt_no);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END COMPLETE_DSD_TRANSACTION;
-----------------------------------------------------------------------------------------
FUNCTION COMPLETE_TRANSACTION(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program        VARCHAR2(50)    := 'CREATE_ORDER_SQL.COMPLETE_TRANSACTION';
   L_approve_ind    VARCHAR2(1)     := 'N';
   L_dept           DEPS.DEPT%TYPE  := NULL;

BEGIN

   FORALL j IN 1..L_ordauto_temp_insert_size
      INSERT INTO ordauto_temp
                 (order_no,
                  item,
                  ref_item,
                  supplier,
                  dept,
                  store,
                  qty,
                  standard_uom,
                  unit_cost,
                  currency_code,
                  unit_retail,
                  origin_country_id,
                  cost_source,
                  weight_received,
                  weight_received_uom)
          VALUES (LPA_order_no(j),
                  LPA_item(j),
                  LPA_ref_item(j),
                  LPA_supplier(j),
                  LPA_dept(j),
                  LPA_store(j),
                  LPA_qty_received(j),
                  LPA_standard_uom(j),
                  LPA_unit_cost(j),
                  LPA_currency_code(j),
                  LPA_unit_retail(j),
                  LPA_origin_country_id(j),
                  LPA_cost_source(j),
                  LPA_weight_received(j),
                  LPA_weight_received_uom(j));

   FOR i in 1..LP_head_count LOOP
      if LP_dept_level_orders = 'Y' then
         L_dept := LP_head_dept(i);
      end if;

      if ORDER_CREATE_SQL.CREATE_ORDER(O_error_message,
                                       L_approve_ind,
                                       LP_head_order_no(i),
                                       LP_head_supplier(i),
                                       L_dept,
                                       LP_head_currency_code(i),
                                       GET_VDATE,
                                       LP_order_type) = FALSE then
         return FALSE;
      end if;

      if L_approve_ind = 'N' then
         O_error_message := SQL_LIB.CREATE_MSG('ORDER_NOT_APPROVED', NULL, NULL, NULL);
         return FALSE;
      end if;

   END LOOP;

   -- The ordauto_temp records will be deleted in RMSSUB_DSDDEALS package.
   -- This is done in order to pass the catch weight information on to
   -- the RMSSUB_DSDDEALS package where shipments are created and received.

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END COMPLETE_TRANSACTION;
-----------------------------------------------------------------------------------------
FUNCTION SET_ORDER_DATES(O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         I_order_no         IN      ORDHEAD.ORDER_NO%TYPE,
                         I_need_date        IN      ORDSKU.LATEST_SHIP_DATE%TYPE)
RETURN BOOLEAN IS

   L_program               VARCHAR2(50)                          := 'CREATE_ORDER_SQL.SET_ORDER_DATES';
   L_item                  ITEM_MASTER.ITEM%TYPE                 := NULL;
   L_lead_time             ITEM_SUPP_COUNTRY.LEAD_TIME%TYPE      := NULL;
   L_latest_ship_days      SYSTEM_OPTIONS.LATEST_SHIP_DAYS%TYPE  := NULL;
   L_latest_ship_date      ORDSKU.LATEST_SHIP_DATE%TYPE          := NULL;
   L_max_latest_ship_date  ORDSKU.LATEST_SHIP_DATE%TYPE          := I_need_date;
   L_need_date_eow         ORDHEAD.OTB_EOW_DATE%TYPE             := NULL;
   L_vdate                 PERIOD.VDATE%TYPE                     := GET_VDATE;

   CURSOR c_get_item_lead_time IS
      select isc.item,
             isc.lead_time
        from item_supp_country isc,
             ordhead oh,
             ordsku os
       where oh.order_no          = I_order_no
         and isc.supplier         = oh.supplier
         and os.order_no          = oh.order_no
         and os.item              = isc.item
         and os.origin_country_id = isc.origin_country_id;

BEGIN

   if SYSTEM_OPTIONS_SQL.GET_LATEST_SHIP_DAYS(O_error_message,
                                              L_latest_ship_days) = FALSE then
      return FALSE;
   end if;

   -- Loop through all the ordsku records for the given order
   FOR rec IN c_get_item_lead_time LOOP

      L_latest_ship_date := L_vdate + L_latest_ship_days + nvl(rec.lead_time,0);

      if L_latest_ship_date < I_need_date then
         L_latest_ship_date := I_need_date;
      end if;

      -- update this ordsku record accordingly
      update ordsku
         set earliest_ship_date = L_vdate,
             latest_ship_date   = L_latest_ship_date
       where order_no = I_order_no
         and item     = rec.item;

      -- keep track of the greatest latest_ship_date for update the header record
      if L_max_latest_ship_date < L_latest_ship_date then
         L_max_latest_ship_date := L_latest_ship_date;
      end if;

   END LOOP;

   -- grab the eow date for the given need date
   if DATES_SQL.GET_EOW_DATE(O_error_message,
                             L_need_date_eow,
                             I_need_date) = FALSE then
      return FALSE;
   end if;

   -- update the header record
   update ordhead
      set earliest_ship_date = L_vdate,
          latest_ship_date   = L_max_latest_ship_date,
          not_before_date    = L_vdate,
          not_after_date     = L_max_latest_ship_date,
          pickup_date        = I_need_date,
          otb_eow_date       = L_need_date_eow
    where order_no = I_order_no;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END SET_ORDER_DATES;
-----------------------------------------------------------------------------------------
FUNCTION RESET(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(30) := 'CREATE_ORDER_SQL.RESET';

BEGIN
   LP_invc_id                         := NULL;
   LP_order_type                      := NULL;
   LP_qty_sum                         := 0;
   LP_cost_sum                        := 0;
   LP_supp_currency_code              := NULL;
   LP_shipment                        := NULL;

   LP_head_order_no.DELETE;
   LP_head_supplier.DELETE;
   LP_head_dept.DELETE;
   LP_head_currency_code.DELETE;

   LP_head_count  := 0;

   LPA_order_no.DELETE;
   LPA_item.DELETE;
   LPA_ref_item.DELETE;
   LPA_supplier.DELETE;
   LPA_dept.DELETE;
   LPA_store.DELETE;
   LPA_qty_received.DELETE;
   LPA_standard_uom.DELETE;
   LPA_unit_cost.DELETE;
   LPA_currency_code.DELETE;
   LPA_unit_retail.DELETE;
   LPA_origin_country_id.DELETE;
   LPA_cost_source.DELETE;
   LPA_weight_received.DELETE;
   LPA_weight_received_UOM.DELETE;

   L_ordauto_temp_insert_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END RESET;
-----------------------------------------------------------------------------------------
FUNCTION INIT(O_error_message        IN OUT  RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(30) := 'CREATE_ORDER_SQL.INIT';

BEGIN
   LP_head_order_no.DELETE;
   LP_head_supplier.DELETE;
   LP_head_dept.DELETE;
   LP_head_currency_code.DELETE;

   LP_head_count  := 0;

   LPA_order_no.DELETE;
   LPA_item.DELETE;
   LPA_ref_item.DELETE;
   LPA_supplier.DELETE;
   LPA_dept.DELETE;
   LPA_store.DELETE;
   LPA_qty_received.DELETE;
   LPA_standard_uom.DELETE;
   LPA_unit_cost.DELETE;
   LPA_currency_code.DELETE;
   LPA_unit_retail.DELETE;
   LPA_origin_country_id.DELETE;
   LPA_cost_source.DELETE;
   LPA_weight_received.DELETE;
   LPA_weight_received_UOM.DELETE;

   L_ordauto_temp_insert_size := 0;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INIT;
-----------------------------------------------------------------------------------------
END CREATE_ORDER_SQL;
/

