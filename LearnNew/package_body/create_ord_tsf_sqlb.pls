CREATE OR REPLACE PACKAGE BODY CREATE_ORD_TSF_SQL AS

LP_dept_level_transfers   SYSTEM_OPTIONS.DEPT_LEVEL_TRANSFERS%TYPE := NULL;
LP_invreqitem_rec         RIB_INVREQITEM_REC;

-------------------------------------------------------------------------

FUNCTION ROUND_NEED_QTY (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_rounded_qty    IN OUT  TSFDETAIL.TSF_QTY%TYPE,
                         I_item           IN      TSFDETAIL.ITEM%TYPE,
                         I_from_loc       IN      TSFHEAD.FROM_LOC%TYPE,
                         I_to_loc         IN      TSFHEAD.TO_LOC%TYPE,
                         I_need_qty       IN      TSFDETAIL.TSF_QTY%TYPE)
RETURN BOOLEAN;

-------------------------------------------------------------------------

FUNCTION CREATE_ORD (O_error_message  IN OUT  VARCHAR2,
                     I_store          IN      ITEM_LOC.LOC%TYPE,
                     I_item_tbl       IN      ITEM_TBL_ORD)
RETURN BOOLEAN;

-------------------------------------------------------------------------

FUNCTION CREATE_TSF_DETAIL (O_error_message  IN OUT  VARCHAR2,
                            I_tsf_dtl_rec    IN      TSF_REC)
RETURN BOOLEAN;

-------------------------------------------------------------------------

FUNCTION CREATE_TSF (O_error_message  IN OUT  VARCHAR2,
                     I_store          IN      ITEM_LOC.LOC%TYPE,
                     I_item_tbl       IN      ITEM_TBL_TSF)
RETURN BOOLEAN;

-------------------------------------------------------------------------
FUNCTION CREATE_ORD (O_error_message  IN OUT  VARCHAR2,
                     I_store          IN      ITEM_LOC.LOC%TYPE,
                     I_item_tbl       IN      ITEM_TBL_ORD)
RETURN BOOLEAN IS

   L_program  VARCHAR2(30)  := 'CREATE_ORD_TSF_SQL.CREATE_ORD';

   TYPE new_ord_rec is RECORD (order_no   ORDHEAD.ORDER_NO%TYPE,
                               supplier   SUPS.SUPPLIER%TYPE,
                               dept       DEPS.DEPT%TYPE,
                               curr_code  ORDHEAD.CURRENCY_CODE%TYPE,
                               need_date  STORE_ORDERS.NEED_DATE%TYPE);

   TYPE new_ord_tbl is TABLE of new_ord_rec INDEX BY BINARY_INTEGER;

   L_origin_country_id    ITEM_LOC.PRIMARY_CNTRY%TYPE  :=  NULL;
   L_currency_code        SUPS.CURRENCY_CODE%TYPE      :=  NULL;
   L_item_record          ITEM_MASTER%ROWTYPE          :=  NULL;
   L_order_no             ORDHEAD.ORDER_NO%TYPE        :=  NULL;

   L_item                 ITEM_MASTER.ITEM%TYPE        :=  NULL;
   L_supplier             SUPS.SUPPLIER%TYPE           :=  NULL;
   L_count                NUMBER(5)                    :=  0;
   L_found                VARCHAR2(2)                  :=  'N';
   L_dept_level_orders    UNIT_OPTIONS.DEPT_LEVEL_ORDERS%TYPE  := NULL;
   L_new_ord_tbl          NEW_ORD_TBL;

   L_user                 ORDHEAD.ORIG_APPROVAL_ID%TYPE   := USER;
   L_sysdate              ORDHEAD.ORIG_APPROVAL_DATE%TYPE := SYSDATE;
   L_valid                BOOLEAN;

   CURSOR c_get_origin_country_id IS
      select origin_country_id
        from repl_item_loc
       where item     = L_item
         and location = I_store
         and loc_type = 'S';

   CURSOR c_get_primary_country IS
      select primary_cntry
        from item_loc
       where item     = L_item
         and loc      = I_store
         and loc_type = 'S';

   CURSOR c_get_supplier_info IS
      select currency_code
        from sups
       where supplier = L_supplier;

BEGIN
   -- initialize create_order_sql for this run...
   if CREATE_ORDER_SQL.INIT(O_error_message) = FALSE then
      return FALSE;
   end if;

   -- get dept_level_orders to pass around as needed
   if UNIT_OPTIONS_SQL.DEPT_LEVEL_ORDERS(O_error_message,
                                         L_dept_level_orders) = FALSE then
      return FALSE;
   end if;

   -- loop through all the records in the item table passed in.
   FOR i in 1..I_item_tbl.count LOOP

      -- set up some needed information

      L_item              := I_item_tbl(i).item;
      L_supplier          := I_item_tbl(i).supplier;
      L_found             := 'N';
      L_origin_country_id := NULL;
      L_currency_code     := NULL;
      L_valid             := TRUE;

      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_record,
                                         I_item_tbl(i).item) = FALSE then
         L_valid := FALSE;
      else
         --- get origin country id from repl_item_loc. If null there, get from item_loc.
         OPEN c_get_origin_country_id;
         FETCH c_get_origin_country_id INTO L_origin_country_id;

         if L_origin_country_id is NULL then
            OPEN c_get_primary_country;
            FETCH c_get_primary_country INTO L_origin_country_id;
            CLOSE c_get_primary_country;
         end if;

         CLOSE c_get_origin_country_id;

         --- Make sure supplier and origin county are not NULL before call PROCESS_DETAIL
         --- to create the order
         if L_supplier is NULL then
            O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','L_supplier',L_program,NULL);
            L_valid := FALSE;
         elsif L_origin_country_id is NULL then
            O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','L_origin_country_id',L_program,NULL);
            L_valid := FALSE;
         end if;
      end if;
      ---
      if L_valid = TRUE then
         --- no errors, continue processing

         OPEN c_get_supplier_info;
         FETCH c_get_supplier_info INTO L_currency_code;
         CLOSE c_get_supplier_info;

         L_count := L_new_ord_tbl.count;

         -- Look for an existing order that this item can be added to
         if L_count > 0 then
            FOR j in 1..L_new_ord_tbl.count LOOP
               if L_supplier = L_new_ord_tbl(j).supplier and
                  L_currency_code = L_new_ord_tbl(j).curr_code and
                  (L_dept_level_orders = 'N' or
                   L_item_record.dept = L_new_ord_tbl(j).dept) then

                  L_order_no := L_new_ord_tbl(j).order_no;

                  -- add this item to the found order
                  if CREATE_ORDER_SQL.PROCESS_DETAIL(O_error_message,
                                                     L_order_no,
                                                     I_item_tbl(i).item,
                                                     I_item_tbl(i).need_qty,
                                                     I_store,
                                                     I_item_tbl(i).supplier,
                                                     L_item_record.dept,
                                                     L_origin_country_id,
                                                     L_currency_code,
                                                     I_item_tbl(i).item_loc_status,
                                                     null,
                                                     null) = FALSE then
                     return FALSE;
                  end if;

                  L_found := 'Y';

                  EXIT;
               end if;
            END LOOP;
         end if; -- L_count > 0

         -- if no order was found that would fit, create order header/details. If there are errors
         -- add to error package and process the next item.
         if L_found = 'N' then
            -- create the head info
            if CREATE_ORDER_SQL.PROCESS_HEAD(O_error_message,
                                             L_order_no,
                                             I_store,
                                             I_item_tbl(i).supplier,
                                             L_item_record.dept,
                                             L_origin_country_id,
                                             L_currency_code,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             'N/B',
                                             L_dept_level_orders) = FALSE then
               return FALSE;
            end if;
            -- create detail/item info
            if CREATE_ORDER_SQL.PROCESS_DETAIL(O_error_message,
                                               L_order_no,
                                               I_item_tbl(i).item,
                                               I_item_tbl(i).need_qty,
                                               I_store,
                                               I_item_tbl(i).supplier,
                                               L_item_record.dept,
                                               L_origin_country_id,
                                               L_currency_code,
                                               I_item_tbl(i).item_loc_status,
                                               null,
                                               null) = FALSE then
               return FALSE;
            end if;
            ---
            -- keep track of the orders created...
            L_count := L_count + 1;

            L_new_ord_tbl(L_count).order_no  := L_order_no;
            L_new_ord_tbl(L_count).supplier  := I_item_tbl(i).supplier;
            L_new_ord_tbl(L_count).dept      := L_item_record.dept;
            L_new_ord_tbl(L_count).curr_code := L_currency_code;
            L_new_ord_tbl(L_count).need_date := I_item_tbl(i).need_date;

         end if; -- if L_found = 'N'
      else
         -- build LP_invreqitem_rec to send to add_error. Defaulting uop to 'EA' since
         -- conversion of UOP has been done in INV_REQUEST_SQL.CONVERT_NEED_QTY
         LP_invreqitem_rec.item        := I_item_tbl(i).item;
         LP_invreqitem_rec.qty_rqst    := I_item_tbl(i).need_qty;
         LP_invreqitem_rec.need_date   := I_item_tbl(i).need_date;
         LP_invreqitem_rec.uop         := 'EA';
         ---
         if RMSSUB_INVREQ_ERROR.ADD_ERROR(O_error_message,
                                          O_error_message,
                                          LP_invreqitem_rec) = FALSE then
            return FALSE;
         end if;
      end if; -- L_valid = TRUE

   END LOOP; -- end looping on I_item_tbl

   -- write the newly created orders to the db
   if CREATE_ORDER_SQL.COMPLETE_TRANSACTION(O_error_message) = FALSE then
      return FALSE;
   end if;

   -- update the status on ordhead for each order created to 'A'pproved.
   FOR i IN 1..L_new_ord_tbl.count LOOP

      if CREATE_ORDER_SQL.SET_ORDER_DATES(O_error_message,
                                          L_new_ord_tbl(i).order_no,
                                          L_new_ord_tbl(i).need_date) = FALSE then
         return FALSE;
      end if;

      update ordhead
         set status = 'A',
             orig_approval_id   = L_user,
             orig_approval_date = L_sysdate
       where order_no = L_new_ord_tbl(i).order_no;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_ORD;
-------------------------------------------------------------------------
FUNCTION CREATE_TSF_DETAIL (O_error_message  IN OUT  VARCHAR2,
                            I_tsf_dtl_rec    IN      TSF_REC)
RETURN BOOLEAN IS

   L_program           VARCHAR2(30)                           := 'CREATE_TSF_DETAIL';
   L_tsf_seq           TSFDETAIL.TSF_SEQ_NO%TYPE;
   L_pack_ind          ITEM_MASTER.PACK_IND%TYPE;
   L_receive_as_type   ITEM_LOC.RECEIVE_AS_TYPE%TYPE;
   L_tsf_seq_no        TSFDETAIL.TSF_SEQ_NO%TYPE;
   L_supp_pack_size    ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;

   cursor C_VALID_ITEM is
      select pack_ind
        from item_master
       where item = I_tsf_dtl_rec.item
         and item_level = tran_level
         and status = 'A';

   cursor C_MAX_SEQ is
   select NVL(MAX(td.tsf_seq_no), 0) + 1
     from tsfdetail td
    where td.tsf_no = I_tsf_dtl_rec.tsf_no;

BEGIN
   ---
   if I_tsf_dtl_rec.tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','tsf_no',L_program,NULL);
      return FALSE;
   end if;
   if I_tsf_dtl_rec.item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','item',L_program,NULL);
      return FALSE;
   end if;
   if I_tsf_dtl_rec.need_qty is NULL or I_tsf_dtl_rec.need_qty < 0 then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','need_qty',L_program,NULL);
      return FALSE;
   end if;
   if I_tsf_dtl_rec.need_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','need_date',L_program,NULL);
      return FALSE;
   end if;
   ---
   open C_VALID_ITEM;
   fetch C_VALID_ITEM into L_pack_ind;
   if C_VALID_ITEM%NOTFOUND then
      close C_VALID_ITEM;
      O_error_message := SQL_LIB.CREATE_MSG('ERR_TSF_ITEM',I_tsf_dtl_rec.item,I_tsf_dtl_rec.from_loc,I_tsf_dtl_rec.to_loc);
      return FALSE;
   end if;
   close C_VALID_ITEM;
   ---
   if L_pack_ind = 'Y' then
      if ITEMLOC_ATTRIB_SQL.GET_RECEIVE_AS_TYPE(O_error_message,
                                                L_receive_as_type,
                                                I_tsf_dtl_rec.item,
                                                I_tsf_dtl_rec.from_loc) = FALSE then
         return FALSE;
      end if;
      if nvl(L_receive_as_type,'P') != 'E' then
         O_error_message := SQL_LIB.CREATE_MSG('ERR_TSF_ITEM',I_tsf_dtl_rec.item,I_tsf_dtl_rec.from_loc,I_tsf_dtl_rec.to_loc);
         return FALSE;
      end if;
   end if;
   ---
   if SUPP_ITEM_ATTRIB_SQL.GET_SUPP_PACK_SIZE(O_error_message,
                                              L_supp_pack_size,
                                              I_tsf_dtl_rec.item,
                                              NULL,
                                              NULL) = FALSE then
      return FALSE;
   end if;

   L_tsf_seq_no := 0;
   open C_MAX_SEQ;
   fetch C_MAX_SEQ into L_tsf_seq_no;
   close C_MAX_SEQ;

   insert into tsfdetail (tsf_no,
                          tsf_seq_no,
                          item,
                          inv_status,
                          tsf_qty,
                          fill_qty,
                          ship_qty,
                          received_qty,
                          distro_qty,
                          selected_qty,
                          cancelled_qty,
                          supp_pack_size,
                          tsf_po_link_no,
                          mbr_processed_ind,
                          publish_ind)
                   values(I_tsf_dtl_rec.tsf_no,              -- TSF_NO
                          L_tsf_seq_no,                      -- TSF_SEQ_NO
                          I_tsf_dtl_rec.item,                -- ITEM
                          NULL,                              -- INV_STATUS
                          I_tsf_dtl_rec.need_qty,            -- TSF_QTY
                          NULL,                              -- FILL_QTY
                          NULL,                              -- SHIP_QTY
                          NULL,                              -- RECEIVED_QTY
                          NULL,                              -- DISTRO_QTY
                          NULL,                              -- SELECTED_QTY
                          NULL,                              -- CANCELLED_QTY
                          L_supp_pack_size,                  -- SUPP_PACK_SIZE
                          NULL,                              -- TSF_PO_LINK_NO
                          NULL,                              -- MBR_PROCESSED_IND
                          'N');                              -- PUBLISH_IND

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_TSF_DETAIL;

-------------------------------------------------------------------------

FUNCTION CREATE_TSF (O_error_message  IN OUT  VARCHAR2,
                     I_store          IN      ITEM_LOC.LOC%TYPE,
                     I_item_tbl       IN      ITEM_TBL_TSF)
RETURN BOOLEAN IS

   TYPE new_tsf_tbl is TABLE of tsf_rec INDEX BY BINARY_INTEGER;

   L_program        VARCHAR2(30)           := 'CREATE_TSF';
   L_return_code    VARCHAR2(5)            := 'TRUE';
   L_count          NUMBER(5)              := 0;
   L_found          VARCHAR2(1)            := 'N';
   L_tsf_no         TSFHEAD.TSF_NO%TYPE;
   L_new_tsf_tbl    NEW_TSF_TBL;
   L_tsf_dtl_rec    TSF_REC;

BEGIN
   FOR i in 1..I_item_tbl.count LOOP
      L_found := 'N';
      L_count := L_new_tsf_tbl.count;

      L_tsf_dtl_rec.item      := I_item_tbl(i).item;
      L_tsf_dtl_rec.dept      := I_item_tbl(i).dept;
      L_tsf_dtl_rec.from_loc  := I_item_tbl(i).from_loc;
      L_tsf_dtl_rec.to_loc    := I_item_tbl(i).to_loc;
      L_tsf_dtl_rec.need_qty  := I_item_tbl(i).need_qty;
      L_tsf_dtl_rec.need_date := I_item_tbl(i).need_date;
      L_tsf_dtl_rec.appr_ind  := I_item_tbl(i).appr_ind;

      if L_count > 0 then
         ---
         FOR j in 1..L_new_tsf_tbl.count LOOP
            if (L_tsf_dtl_rec.from_loc = L_new_tsf_tbl(j).from_loc and
                L_tsf_dtl_rec.appr_ind = L_new_tsf_tbl(j).appr_ind and
                (L_tsf_dtl_rec.dept      = L_new_tsf_tbl(j).dept or
                 LP_dept_level_transfers = 'N')) then
               ---
               L_tsf_dtl_rec.tsf_no := L_new_tsf_tbl(j).tsf_no;

               if CREATE_TSF_DETAIL(O_error_message,
                                    L_tsf_dtl_rec) = FALSE then
                  return FALSE;
               end if;

               L_found := 'Y';
               EXIT;
               ---
            end if;
         END LOOP;
         ---
      end if;

      if L_found != 'Y' then
         ---
         NEXT_TRANSFER_NUMBER(L_tsf_no,
                              L_return_code,
                              O_error_message);

         if (L_return_code <> 'TRUE') then
            return FALSE;
         end if;
         ---
         insert into tsfhead (tsf_no,
                              from_loc_type,
                              from_loc,
                              to_loc_type,
                              to_loc,
                              dept,
                              inventory_type,
                              tsf_type,
                              status,
                              freight_code,
                              routing_code,
                              create_date,
                              create_id,
                              approval_date,
                              approval_id,
                              delivery_date,
                              close_date,
                              ext_ref_no,
                              repl_tsf_approve_ind,
                              comment_desc)
                      values (L_tsf_no,                                                        -- Transfer Number
                              'W',                                                             -- From Loc Type
                              L_tsf_dtl_rec.from_loc,                                          -- Source Warehouse
                              'S',                                                             -- To Loc Type
                              I_store,                                                         -- Store
                              decode(LP_dept_level_transfers, 'Y', L_tsf_dtl_rec.dept, NULL),  -- Dept
                              'A',                                                             -- Inventory Type
                              'MR',                                                            -- Transfer Type
                              'I',                                                             -- Status
                              'N',                                                             -- Freight Code
                              NULL,                                                            -- Routing Code
                              sysdate,                                                         -- Create Date
                              'EXTERNAL',                                                      -- Create ID
                              NULL,                                                            -- Approval Date
                              NULL,                                                            -- Approval ID
                              NULL,                                                            -- Delivery_date
                              NULL,                                                            -- Close Date
                              NULL,                                                            -- External Reference Number
                              'N',                                                             -- Repl Transfer Approve Indicator
                              NULL);                                                           -- Comment Description
         ---
         L_tsf_dtl_rec.tsf_no   := L_tsf_no;

         if CREATE_TSF_DETAIL(O_error_message,
                              L_tsf_dtl_rec) = FALSE then
            return FALSE;
         end if;
         ---
         L_count := L_count + 1;
         L_new_tsf_tbl(L_count).tsf_no   := L_tsf_dtl_rec.tsf_no;
         L_new_tsf_tbl(L_count).dept     := L_tsf_dtl_rec.dept;
         L_new_tsf_tbl(L_count).from_loc := L_tsf_dtl_rec.from_loc;
         L_new_tsf_tbl(L_count).appr_ind := L_tsf_dtl_rec.appr_ind;
      end if;
      ---
   END LOOP;

   FOR j in 1..L_new_tsf_tbl.count LOOP
      if L_new_tsf_tbl(j).appr_ind = 'Y' then
         ---
         update tsfhead
            set status = 'A'
              , approval_date = sysdate
              , approval_id   = 'EXTERNAL'
          where tsf_no = L_new_tsf_tbl(j).tsf_no;
         ---
         if TRANSFER_SQL.UPD_TSF_RESV_EXP(O_error_message,
                                          L_new_tsf_tbl(j).tsf_no,
                                          'A',                             -- I_add_delete_ind
                                          FALSE) = FALSE then              -- I_appr_second_leg
            return FALSE;
         end if;
         ---
      end if;
   END LOOP;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_TSF;

-------------------------------------------------------------------------

FUNCTION CREATE_ORD_TSF (O_error_message  IN OUT  VARCHAR2,
                         I_store          IN      ITEM_LOC.LOC%TYPE,
                         I_item_tbl       IN      INV_REQUEST_SQL.ITEM_TBL)
RETURN BOOLEAN IS

   L_program           VARCHAR2(50)                        := 'CREATE_ORD_TSF_SQL.CREATE_ORD_TSF';
   L_supplier          SUPS.SUPPLIER%TYPE;
   L_source_wh         REPL_ITEM_LOC.SOURCE_WH%TYPE;
   L_stock_cat         REPL_ITEM_LOC.STOCK_CAT%TYPE;
   L_method            ITEM_LOC.SOURCE_METHOD%TYPE;
   L_dsd_ind           SUPS.DSD_IND%TYPE;
   L_repl_order_ctrl   REPL_ITEM_LOC.REPL_ORDER_CTRL%TYPE;
   L_soh               ITEM_LOC_SOH.STOCK_ON_HAND%TYPE;
   L_item_loc_status   ITEM_LOC.STATUS%TYPE;
   L_valid             BOOLEAN;


   L_item              ITEM_LOC.ITEM%TYPE;
   L_dept              ITEM_MASTER.DEPT%TYPE;
   L_need_qty          STORE_ORDERS.NEED_QTY%TYPE;
   L_rounded_need_qty  STORE_ORDERS.NEED_QTY%TYPE;
   L_need_date         STORE_ORDERS.NEED_DATE%TYPE;
   L_origin_country_id REPL_ITEM_LOC.ORIGIN_COUNTRY_ID%TYPE;
   L_record_exists     BOOLEAN := FALSE;

   L_count             NUMBER(10)  := 0;

   L_item_tbl_tsf      ITEM_TBL_TSF;
   L_item_tbl_ord      ITEM_TBL_ORD;

   cursor C_REPL_ITEM_LOC is
      select ril.primary_repl_supplier,
             ril.source_wh,
             ril.stock_cat,
             ril.repl_order_ctrl,
             nvl(ril.dept, im.dept),
             s.dsd_ind,
             il.status,
             ril.origin_country_id
        from repl_item_loc ril,
             sups s,
             item_loc il,
             item_master im
       where ril.item      = L_item
         and ril.location  = I_store
         and s.supplier(+) = ril.primary_repl_supplier
         and il.item       = ril.item
         and il.loc        = ril.location
         and il.item       = im.item
         and il.status     = 'A';

   cursor C_ITEM_LOC is
      select il.primary_supp,
             il.source_wh,
             il.source_method,
             im.dept,
             s.dsd_ind,
             il.status,
             il.primary_cntry
        from item_loc il,
             item_master im,
             sups s
       where il.item       = L_item
         and il.loc        = I_store
         and il.item       = im.item
         and s.supplier(+) = il.primary_supp
         and il.status     = 'A';

   cursor C_SOH is
      select stock_on_hand - tsf_reserved_qty
        from item_loc_soh
       where item = L_item
         and loc = L_source_wh;

BEGIN
   if I_store is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_store',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   -- initialize record
   LP_invreqitem_rec :=   RIB_INVREQITEM_REC(null,    -- rib_oid
                                             null,    -- item
                                             null,    -- qty_rqst
                                             null,    -- uop
                                             null);   -- need_date

   if I_item_tbl(1).item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_item', L_program, NULL);
      return FALSE;
   end if;
   ---
   if SYSTEM_OPTIONS_SQL.GET_DEPT_LEVEL_TSF(O_error_message,
                                            LP_dept_level_transfers) = FALSE then
      return FALSE;
   end if;
   ---
   FOR i in 1..I_item_tbl.count LOOP
      -- initialize values since they change for each item detail processed
      L_item              := I_item_tbl(i).item;
      L_need_qty          := I_item_tbl(i).need_qty;
      L_rounded_need_qty  := NULL;
      L_need_date         := I_item_tbl(i).need_date;
      L_valid             := TRUE;
      L_supplier          := NULL;
      L_item_loc_status   := NULL;
      L_stock_cat         := NULL;
      L_source_wh         := NULL;
      L_repl_order_ctrl   := NULL;
      L_dsd_ind           := NULL;
      L_method            := NULL;
      L_dept              := NULL;
      L_soh               := NULL;
      L_origin_country_id := NULL;
      L_record_exists     := FALSE;

      open C_REPL_ITEM_LOC;
      fetch C_REPL_ITEM_LOC into L_supplier,
                                 L_source_wh,
                                 L_stock_cat,
                                 L_repl_order_ctrl,
                                 L_dept,
                                 L_dsd_ind,
                                 L_item_loc_status,
                                 L_origin_country_id;
      if C_REPL_ITEM_LOC%NOTFOUND then
         close C_REPL_ITEM_LOC;

         open C_ITEM_LOC;
         fetch C_ITEM_LOC into L_supplier,
                               L_source_wh,
                               L_method,
                               L_dept,
                               L_dsd_ind,
                               L_item_loc_status,
                               L_origin_country_id;

         if C_ITEM_LOC%NOTFOUND then

            close C_ITEM_LOC;
            -- if the item location relationship was not found, create it and then requery
            if NEW_ITEM_LOC(O_error_message,
                            L_item,
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
               L_valid := FALSE;
            end if;

            open C_ITEM_LOC;
            fetch C_ITEM_LOC into L_supplier,
                                  L_source_wh,
                                  L_method,
                                  L_dept,
                                  L_dsd_ind,
                                  L_item_loc_status,
                                  L_origin_country_id;
            close C_ITEM_LOC;
         else
            close C_ITEM_LOC;
         end if;
      else
         close C_REPL_ITEM_LOC;
      end if;
      ---
      -- if we have a source wh, make sure that there is an item_loc record
      -- for that wh and this item
      ---

      if L_source_wh is not NULL then
         if NEW_ITEM_LOC(O_error_message,
                         L_item,
                         L_source_wh,
                         NULL,
                         NULL,
                         'W',                 /* wh */
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
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
            L_valid := FALSE;
         end if;
      end if;
      ---
      open C_SOH;
      fetch C_SOH into L_soh;
      close C_SOH;
      ---
      if L_valid = TRUE then

         if ( ( NVL(L_stock_cat, ' ') = 'D' ) or
              ( L_method = 'S' ) or
              ( L_method = 'W' and NVL(L_soh, 0) < L_need_qty and L_dsd_ind = 'Y' ) ) then

            --- build the order array
            if L_origin_country_id is NULL then
               O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                     'L_origin_country_id',
                                                     L_program,
                                                     NULL);

               -- build LP_invreqitem_rec to send to add_error. Defaulting uop to 'EA' since conversion of
               -- UOP has been done in INV_REQUEST_SQL.CONVERT_NEED_QTY
               LP_invreqitem_rec.item        := L_item;
               LP_invreqitem_rec.qty_rqst    := L_need_qty;
               LP_invreqitem_rec.need_date   := L_need_date;
               LP_invreqitem_rec.uop         := 'EA';
               ---
               if RMSSUB_INVREQ_ERROR.ADD_ERROR(O_error_message,
                                                O_error_message,
                                                LP_invreqitem_rec) = FALSE then
                  return FALSE;
               end if;
            elsif ITEM_SUPP_COUNTRY_LOC_SQL.LOC_EXISTS(O_error_message,
                                                       L_record_exists,
                                                       L_item,
                                                       L_supplier,
                                                       L_origin_country_id,
                                                       I_store)  = FALSE then
               return FALSE;
            end if;
            ---
            if not L_record_exists then
               O_error_message := SQL_LIB.CREATE_MSG('SUP_COST_NOT_FOUND',
                                                     L_supplier,
                                                     L_item,
                                                     NULL);

               -- build LP_invreqitem_rec to send to add_error. Defaulting uop to 'EA' since conversion of
               -- UOP has been done in INV_REQUEST_SQL.CONVERT_NEED_QTY
               LP_invreqitem_rec.item        := L_item;
               LP_invreqitem_rec.qty_rqst    := L_need_qty;
               LP_invreqitem_rec.need_date   := L_need_date;
               LP_invreqitem_rec.uop         := 'EA';
               ---
               if RMSSUB_INVREQ_ERROR.ADD_ERROR(O_error_message,
                                                O_error_message,
                                                LP_invreqitem_rec) = FALSE then
                  return FALSE;
               end if;
            else
               L_count := L_item_tbl_ord.count + 1;
               ---
               L_item_tbl_ord(L_count).supplier         := L_supplier;
               L_item_tbl_ord(L_count).item             := L_item;
               L_item_tbl_ord(L_count).need_qty         := L_need_qty;
               L_item_tbl_ord(L_count).need_date        := L_need_date;
               L_item_tbl_ord(L_count).item_loc_status  := L_item_loc_status;
            end if;
         else
            -- build the transfer array
            if L_source_wh is NULL then
               O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL','L_source_wh',L_program,NULL);

               -- build LP_invreqitem_rec to send to add_error. Defaulting uop to 'EA' since conversion of
               -- UOP has been done in INV_REQUEST_SQL.CONVERT_NEED_QTY
               LP_invreqitem_rec.item        := L_item;
               LP_invreqitem_rec.qty_rqst    := L_need_qty;
               LP_invreqitem_rec.need_date   := L_need_date;
               LP_invreqitem_rec.uop         := 'EA';
               ---
               if RMSSUB_INVREQ_ERROR.ADD_ERROR(O_error_message,
                                                O_error_message,
                                                LP_invreqitem_rec) = FALSE then
                  return FALSE;
               end if;
            elsif ROUND_NEED_QTY(O_error_message,
                                 L_rounded_need_qty,
                                 L_item,
                                 L_source_wh,
                                 I_store,
                                 L_need_qty) = FALSE then
               -- build LP_invreqitem_rec to send to add_error. Defaulting uop to 'EA' since conversion of
               -- UOP has been done in INV_REQUEST_SQL.CONVERT_NEED_QTY
               LP_invreqitem_rec.item        := L_item;
               LP_invreqitem_rec.qty_rqst    := L_need_qty;
               LP_invreqitem_rec.need_date   := L_need_date;
               LP_invreqitem_rec.uop         := 'EA';
               ---
               if RMSSUB_INVREQ_ERROR.ADD_ERROR(O_error_message,
                                                O_error_message,
                                                LP_invreqitem_rec) = FALSE then
                  return FALSE;
               end if;
            else

               ---
               L_count := L_item_tbl_tsf.count + 1;
               ---
               L_item_tbl_tsf(L_count).item      := L_item;
               L_item_tbl_tsf(L_count).dept      := L_dept;
               L_item_tbl_tsf(L_count).from_loc  := L_source_wh;
               L_item_tbl_tsf(L_count).to_loc    := I_store;
               L_item_tbl_tsf(L_count).need_qty  := L_rounded_need_qty;
               L_item_tbl_tsf(L_count).need_date := L_need_date;
               ---
               if (nvl(L_repl_order_ctrl, ' ') = 'A' or
                   L_repl_order_ctrl is  NULL) and
                   L_soh >= L_need_qty then
                   L_item_tbl_tsf(L_count).appr_ind := 'Y';
               else
                  L_item_tbl_tsf(L_count).appr_ind := 'N';
               end if;
            end if; -- L_source_wh is not null
         end if; -- check if order or transfer should be created
      else -- L_valid is FALSE
         -- build LP_invreqitem_rec to send to add_error. Defaulting uop to 'EA' since conversion of
         -- UOP has been done in INV_REQUEST_SQL.CONVERT_NEED_QTY
         LP_invreqitem_rec.item        := L_item;
         LP_invreqitem_rec.qty_rqst    := L_need_qty;
         LP_invreqitem_rec.need_date   := L_need_date;
         LP_invreqitem_rec.uop         := 'EA';
         ---
         if RMSSUB_INVREQ_ERROR.ADD_ERROR(O_error_message,
                                          O_error_message,
                                          LP_invreqitem_rec) = FALSE then
            return FALSE;
         end if;
      end if;  -- L_valid = TRUE
   END LOOP;
   ---
   if L_item_tbl_ord.count > 0 then
      if CREATE_ORD(O_error_message,
                    I_store,
                    L_item_tbl_ord) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if L_item_tbl_tsf.count > 0 then
      if CREATE_TSF(O_error_message,
                    I_store,
                    L_item_tbl_tsf) = FALSE then
         return FALSE;
      end if;
   end if;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM, L_program, TO_CHAR(SQLCODE));
      return FALSE;
END CREATE_ORD_TSF;
-------------------------------------------------------------------------
FUNCTION ROUND_NEED_QTY (O_error_message  IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                         O_rounded_qty    IN OUT  TSFDETAIL.TSF_QTY%TYPE,
                         I_item           IN      TSFDETAIL.ITEM%TYPE,
                         I_from_loc       IN      TSFHEAD.FROM_LOC%TYPE,
                         I_to_loc         IN      TSFHEAD.TO_LOC%TYPE,
                         I_need_qty       IN      TSFDETAIL.TSF_QTY%TYPE)
RETURN BOOLEAN IS

   L_inv_parm          VARCHAR2(50) := NULL;
   L_store_ord_mult    ITEM_MASTER.STORE_ORD_MULT%TYPE;
   L_store_pack_size   ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;
   L_break_pack_ind    WH.BREAK_PACK_IND%TYPE;
   L_program           VARCHAR2(30) := 'ROUND_NEED_QTY';

BEGIN
   if I_item is NULL then
      L_inv_parm := 'I_item';
   elsif I_from_loc is NULL then
      L_inv_parm := 'I_from_loc';
   elsif I_to_loc is NULL then
      L_inv_parm := 'I_to_loc';
   elsif I_need_qty is NULL or I_need_qty < 0 then
      L_inv_parm := 'I_need_qty';
   end if;
   ---
   if L_inv_parm is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            L_inv_parm,
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if ROUNDING_SQL.GET_PACKSIZE(O_error_message,
                                L_store_pack_size,
                                L_store_ord_mult,
                                L_break_pack_ind,
                                I_item,
                                I_from_loc,
                                NULL,
                                NULL,
                                I_to_loc) = FALSE then
      return FALSE;
   end if;
   ---
   if ROUNDING_SQL.TO_INNER_CASE(O_error_message,
                                 O_rounded_qty,
                                 I_item,
                                 NULL,
                                 NULL,
                                 I_to_loc,
                                 I_need_qty,
                                 NULL,
                                 L_store_pack_size,
                                 L_store_ord_mult,
                                 L_break_pack_ind) = FALSE then
      return FALSE;
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
END ROUND_NEED_QTY;
-------------------------------------------------------------------------
END CREATE_ORD_TSF_SQL;
/

