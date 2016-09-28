CREATE OR REPLACE PACKAGE BODY CONTRACT_ORDER_SQL AS

   LP_table              VARCHAR2(100);
   RECORD_LOCKED         EXCEPTION;
   PRAGMA                EXCEPTION_INIT(Record_Locked, -54);
-----------------------------------------------------------------------------
FUNCTION BUILD_CONTRACT_ORDERS(O_error_message        IN OUT VARCHAR2,
                               I_contract_ordhead_seq IN     CONTRACT_ORDSKU.CONTRACT_ORDHEAD_SEQ%TYPE)
RETURN BOOLEAN IS

   L_order_number          contract_ordhead.order_no%TYPE :=0;
   L_current_contract_no   contract_header.contract_no%TYPE := 0;
   L_first_iteration       BOOLEAN := TRUE;
   L_exception_id          NUMBER(1);
   L_contract_ordhead_seq  CONTRACT_ORDHEAD.CONTRACT_ORDHEAD_SEQ%TYPE;
   L_item                  CONTRACT_ORDSKU.ITEM%TYPE;
   L_contract_no           contract_ordhead.contract_no%TYPE;
   L_table                 VARCHAR2(30);
   L_current_date          contract_ordhead.not_before_date%TYPE;


   cursor C_CONTRACT_ORDSKU IS
      select cos.contract_no,
             cos.item
        from contract_ordsku cos,
             contract_ordloc col
       where cos.contract_ordhead_seq = I_contract_ordhead_seq
         and col.contract_ordhead_seq = cos.contract_ordhead_seq
         and col.item = cos.item
         and cos.order_no IS NULL
    order by cos.contract_no
         for update nowait;


-- F_insert_head function ---------------------------------------

FUNCTION F_insert_head(I_contract_no IN CONTRACT_ORDSKU.CONTRACT_NO%TYPE)
   RETURN BOOLEAN IS

BEGIN
   L_current_date  := Get_Vdate;

   if ORDER_NUMBER_SQL.NEXT_ORDER_NUMBER(O_error_message,
                                         L_order_number) = FALSE then
      return FALSE;
   end if;

   -- Insert record into contract_ordhead

   SQL_LIB.SET_MARK('INSERT',NULL,'contract_ordhead','Order no:'
                    ||to_char(L_order_number)||' Contract no:'
                    ||to_char(I_contract_no));

   insert into contract_ordhead ( contract_ordhead_seq,
                                  contract_no,
                                  order_no,
                                  create_status,
                                  order_type,
                                  dept,
                                  supplier,
                                  not_before_date,
                                  not_after_date,
                                  currency_code,
                                  country_id)

   select I_contract_ordhead_seq,
          I_contract_no,
          L_order_number,
          'B',
          NULL,
          ch.dept,
          ch.supplier,
          L_current_date,
          ch.end_date,
          ch.currency_code,
          ch.country_id
    from  contract_header ch
   where  ch.contract_no = I_contract_no;

   L_contract_no := I_contract_no;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message :=  SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                                             'CONTRACT_ORDER_SQL', to_char(SQLCODE));
      return FALSE;


END;   -- function F_insert_head

   -- Main body of BUILD_CONTRACT_ORDERS

BEGIN

   -- Loop though all records in the contract_ordsku table

   FOR C_contract_ordsku_rec IN c_contract_ordsku
   LOOP

      L_contract_no := C_contract_ordsku_rec.contract_no;

      -- If this is the first iteration of the loop or a different contract is
      -- being updated then create an entry in contract_ordhead

      if ((c_contract_ordsku_rec.contract_no != L_current_contract_no)
           or (L_first_iteration = TRUE)) then

         --Set L_first_iteration to FALSE after first iteration.
         L_first_iteration := FALSE;

         -- Set the contract number flag for the next contract
         L_current_contract_no := c_contract_ordsku_rec.contract_no;

         -- Check for valid return value from the insert header function
         if F_insert_head(c_contract_ordsku_rec.contract_no) = FALSE then
            return FALSE;
         end if;

      end if;

      -- Update the record in the contract_ordsku table with the
      -- order number

      SQL_LIB.SET_MARK('UPDATE',NULL,'contract_ordsku','Order no: '||
                       to_char(L_order_number));
      update  contract_ordsku cos
         set     cos.order_no = L_order_number
       where   cos.contract_ordhead_seq = i_contract_ordhead_seq
         and     cos.contract_no = c_contract_ordsku_rec.contract_no
         and     cos.item = c_contract_ordsku_rec.item
         and     cos.order_no IS NULL;

      -- Update the record in the contract_ordloc table with the order number
      SQL_LIB.SET_MARK('UPDATE',NULL,'contract_ordloc','Order no: '||to_char(L_order_number));

      update contract_ordloc col
         set col.order_no = L_order_number
       where col.contract_ordhead_seq = I_contract_ordhead_seq
         and col.contract_no = c_contract_ordsku_rec.contract_no
         and col.item = c_contract_ordsku_rec.item
         and col.order_no IS NULL;

   END LOOP;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               'CONTRACT_ORDSKU, CONTRACT_ORDLOC',
                                               NULL,
                                               NULL);
      return FALSE;
  when OTHERS then
      O_error_message :=  SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                                             'CONTRACT_ORDER_SQL', to_char(SQLCODE));
      return FALSE;

END BUILD_CONTRACT_ORDERS;
-----------------------------------------------------------------------------
FUNCTION CREATE_CONTRACT_ORDERS(O_error_message         IN OUT  VARCHAR2,
                                I_contract_ordhead_seq  IN      CONTRACT_ORDSKU.CONTRACT_ORDHEAD_SEQ%TYPE)
RETURN BOOLEAN IS

   L_work_day	           NUMBER(2);
   L_work_month	           NUMBER(2);
   L_work_year 	           NUMBER(4);
   L_454_day	           NUMBER(2);
   L_454_month	           NUMBER(2);
   L_454_year 	           NUMBER(4);
   L_function              VARCHAR2(20)  := NULL;
   L_eow_date              DATE;
   L_written_date          DATE;
   L_comment_desc          contract_header.comment_desc%TYPE;
   L_seq_no                addr.seq_no%TYPE;
   L_return_code           VARCHAR2(5);
   L_error_message         VARCHAR2(255);
   L_supplier              contract_header.supplier%TYPE;
   L_location              wh.wh%TYPE;
   L_loc_type              ORDLOC.LOC_TYPE%TYPE;
   L_multiple_locs_exist   BOOLEAN;
   L_virtual_wh            WH.WH%TYPE;
   L_elc_ind               VARCHAR2(1);
   L_base_country_id       SYSTEM_OPTIONS.BASE_COUNTRY_ID%TYPE;
   L_latest_ship_days      SYSTEM_OPTIONS.LATEST_SHIP_DAYS%TYPE;
   L_fob_title_pass        SYSTEM_OPTIONS.FOB_TITLE_PASS%TYPE;
   L_fob_title_pass_desc   SYSTEM_OPTIONS.FOB_TITLE_PASS_DESC%TYPE;
   L_exchange_rate         CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_contract_currency     CURRENCY_RATES.CURRENCY_CODE%TYPE;
   L_contract_country      CONTRACT_HEADER.COUNTRY_ID%TYPE;
   L_import_order_ind      ORDHEAD.IMPORT_ORDER_IND%TYPE;
   L_purchase_type         ORDHEAD.PURCHASE_TYPE%TYPE;
   L_pickup_date           ORDHEAD.PICKUP_DATE%TYPE;
   L_not_before_date       ORDHEAD.NOT_BEFORE_DATE%TYPE;
   L_not_after_date        ORDHEAD.NOT_AFTER_DATE%TYPE;
   L_pickup_loc            ORDHEAD.PICKUP_LOC%TYPE;
   L_vdate                 ORDHEAD.NOT_BEFORE_DATE%TYPE       := GET_VDATE;
   L_dummy                 VARCHAR2(1);
   L_min_esd               ORDHEAD.EARLIEST_SHIP_DATE%TYPE;
   L_max_lsd               ORDHEAD.LATEST_SHIP_DATE%TYPE;
   DATE_FAILED             EXCEPTION;

   cursor C_CONTRACT_ORDHEAD is
      select contract_no,
             order_no,
             order_type,
             dept,
             supplier,
             not_before_date,
             not_after_date,
             country_id,
             currency_code
        from contract_ordhead
       where contract_ordhead_seq = I_contract_ordhead_seq
         and create_status = 'G'
         for update of contract_no nowait;

   cursor C_CONTRACT_HEADER(L_contract_no_cursor    contract_header.contract_no%TYPE) is
      select comment_desc,
             supplier,
             country_id
        from contract_header
       where contract_no = L_contract_no_cursor;

   cursor C_SUPS_ADD_SEQ_NO is
      select seq_no
        from addr
       where key_value_1       = to_char(L_supplier)
         and module            = 'SUPP'
         and primary_addr_ind  = 'Y'
         and addr_type         = 04;

   cursor C_SYSTEM_OPTIONS is
      select elc_ind,
             base_country_id,
             latest_ship_days,
             fob_title_pass,
             fob_title_pass_desc
        from system_options;

   cursor C_CONTRACT_ORDSKU(L_contract_no_cursor   contract_header.contract_no%TYPE) is
      select cs.item,
             ch.country_id,
             isc.supp_pack_size,
             cs.unit_cost,
             NVL(isc.lead_time, 0) lead_time
        from contract_ordsku cs,
             item_supp_country isc,
             contract_header ch
       where cs.contract_no          = L_contract_no_cursor
         and cs.contract_ordhead_seq = I_contract_ordhead_seq
         and cs.item                 = isc.item
         and isc.supplier            = L_supplier
         and isc.origin_country_id   = ch.country_id
         and cs.contract_no          = ch.contract_no;

   cursor C_LOCK_ORDHEAD(L_order_no  ORDHEAD.ORDER_NO%TYPE) is
      select 'x'
        from ordhead
       where order_no = L_order_no
         for update nowait;

   cursor C_LOCK_ORDSKU(L_order_no  ORDHEAD.ORDER_NO%TYPE) is
      select 'x'
        from ordsku
       where order_no = L_order_no
         for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_SYSTEM_OPTIONS', 'SYSTEM_OPTIONS', NULL);
   open  C_SYSTEM_OPTIONS;
   SQL_LIB.SET_MARK('FETCH', 'C_SYSTEM_OPTIONS', 'SYSTEM_OPTIONS', NULL);
   fetch C_SYSTEM_OPTIONS into L_elc_ind,
                               L_base_country_id,
                               L_latest_ship_days,
                               L_fob_title_pass,
                               L_fob_title_pass_desc;
   SQL_LIB.SET_MARK('CLOSE', 'C_SYSTEM_OPTIONS', 'SYSTEM_OPTIONS', NULL);
   close C_SYSTEM_OPTIONS;
   ---
   --Loop through all records on contract_ordhead.
   for C_rec in C_CONTRACT_ORDHEAD
   loop
      ---
      if CURRENCY_SQL.GET_RATE(O_error_message,
                               L_exchange_rate,
                               C_rec.currency_code,
                               'P',
                               NULL) = FALSE then
         return FALSE;
      end if;
      ---
      --Get end of week date for C_rec.not_after_date
      L_work_day   := to_number(to_char(C_rec.not_after_date, 'DD'), '09');
      L_work_month := to_number(to_char(C_rec.not_after_date, 'MM'), '09');
      L_work_year  := to_number(to_char(C_rec.not_after_date, 'YYYY'), '0999');

      SQL_LIB.SET_MARK('SELECT', NULL, 'CALENDAR', 'DAY: '||to_char(L_work_day)
                       ||' MTH:  '||to_char(L_work_month)||' YEAR: '||to_char(L_work_year));

      CAL_TO_454_LDOW (L_work_day,
                       L_work_month,
                       L_work_year,
                       L_454_day,
                       L_454_month,
                       L_454_year,
                       L_return_code,
                       L_error_message);
      if L_return_code = 'FALSE' then
         L_function := 'CAL_TO_454_LDOW';
         raise DATE_FAILED;
      end if;
      L_eow_date := to_date(to_char(L_454_day, '09') || to_char(L_454_month, '09') ||
                    to_char(L_454_year, '0999'), 'DDMMYYYY');

      L_written_date := L_vdate;

      --Fetch contract_desc from contract_header
      open  C_CONTRACT_HEADER(C_rec.contract_no);
      fetch C_CONTRACT_HEADER into L_comment_desc,
                                   L_supplier,
                                   L_contract_country;
      close C_CONTRACT_HEADER;

      --Fetch primary address seq_no from addr table.
      open  C_SUPS_ADD_SEQ_NO;
      fetch C_SUPS_ADD_SEQ_NO into L_seq_no;
      close C_SUPS_ADD_SEQ_NO;

      -- if the base country is different than the contract
      -- country thant the order is a import county
      if (L_base_country_id = L_contract_country) then
         L_import_order_ind := 'N';
      else
         L_import_order_ind := 'Y';
      end if;
      --Insert record into ordhead table.
      SQL_LIB.SET_MARK('INSERT', NULL, 'ordhead', 'CONTRACT_ORDHEAD_SEQ: '||to_char(I_contract_ordhead_seq));
      insert into ordhead(order_no,
                          order_type,
                          dept,
                          buyer,
                          supplier,
                          supp_add_seq_no,
                          promotion,
                          qc_ind,
                          written_date,
                          not_before_date,
                          not_after_date,
                          otb_eow_date,
                          earliest_ship_date,
                          latest_ship_date,
                          close_date,
                          terms,
                          freight_terms,
                          orig_ind,
                          cust_order,
                          payment_method,
                          ship_method,
                          purchase_type,
                          status,
                          orig_approval_date,
                          orig_approval_id,
                          ship_pay_method,
                          fob_trans_res,
                          fob_trans_res_desc,
                          fob_title_pass,
                          fob_title_pass_desc,
                          edi_sent_ind,
                          edi_po_ind,
                          import_order_ind,
                          import_country_id,
                          po_ack_recvd_ind,
                          include_on_order_ind,
                          vendor_order_no,
                          exchange_rate,
                          factory,
                          agent,
                          discharge_port,
                          lading_port,
                          freight_contract_no,
                          po_type,
                          pre_mark_ind,
                          currency_code,
                          contract_no,
                          last_sent_rev_no,
                          pickup_loc,
                          pickup_no,
                          pickup_date,
                          comment_desc)
      select  C_rec.order_no,
              C_rec.order_type,
              C_rec.dept,
              NULL,                                         -- buyer
              C_rec.supplier,
              L_seq_no,
              NULL,                                         -- promotion
              s.qc_ind,
              L_written_date,
              C_rec.not_before_date,
              C_rec.not_after_date,
              L_eow_date,
              NULL,                                         -- earliest_ship_date
              NULL,                                         -- latest_ship_date
              NULL,                                         -- close_date
              ch.terms,
              s.freight_terms,
              2,                                            -- orig_ind
              'N',                                          -- cust_order
              s.payment_method,
              s.ship_method,
              NULL,                                         -- purchase_type
              'W',                                          -- status
              NULL,                                         -- orig_approval_date
              NULL,                                         -- orig_approval_id
              NULL,                                         -- ship_pay_method
              NULL,                                         -- fob_trans_res
              NULL,                                         -- fob_trans_res_desc
              L_fob_title_pass,                             -- fob_title_pass
              L_fob_title_pass_desc,                        -- fob_title_pass_desc
              'N',                                          -- edi_sent_ind
              s.edi_po_ind,
              L_import_order_ind,                           -- import_order_ind
              L_base_country_id,                            -- import_country_id
              'N',                                          -- pack_ack_recvd_ind
              'Y',                                          -- include_on_order_ind
              NULL,                                         -- vendor_order_no
              L_exchange_rate,
              NULL,                                         -- factory
              sia.agent,
              sia.discharge_port,
              sia.lading_port,
              NULL,                                         -- freight_contract_no
              NULL,                                         -- po_type
              'N',                                          -- pre_mark_ind
              C_rec.currency_code,
              C_rec.contract_no,
              NULL,                                         -- last_sent_rev_no
              NULL,                                         -- pickup_loc
              NULL,                                         -- pickup_no
              NULL,                                         -- pickup_date
              L_comment_desc
         from sups s,
              contract_header ch,
              sup_import_attr sia
        where C_rec.supplier =  s.supplier
          and s.supplier     =  ch.supplier
          and ch.supplier    =  sia.supplier(+)
          and ch.contract_no =  C_rec.contract_no;
	  ---

      --- Default supplier and agent level required documents to the order.
      if ORDER_SETUP_SQL.DEFAULT_ORDHEAD_DOCS(O_error_message,
                                              C_rec.order_no) = FALSE then
         return FALSE;
      end if;
      ---
      for C_rec_contract_ordsku in C_CONTRACT_ORDSKU(C_rec.contract_no)
      LOOP
         --Insert record into ordsku table.
         SQL_LIB.SET_MARK('INSERT', NULL, 'ordsku', 'CONTRACT_ORDHEAD_SEQ: '||to_char(I_contract_ordhead_seq));
         ---
         insert into ordsku(order_no,
                            item,
                            ref_item,
                            origin_country_id,
                            earliest_ship_date,
                            latest_ship_date,
                            supp_pack_size,
                            non_scale_ind)
                    values (C_rec.order_no,
                            C_rec_contract_ordsku.item,
                            NULL,
                            C_rec_contract_ordsku.country_id,
                            L_vdate  + C_rec_contract_ordsku.lead_time,
                            (L_vdate + C_rec_contract_ordsku.lead_time + L_latest_ship_days),
                            C_rec_contract_ordsku.supp_pack_size,
		            'N');
         ---
         if ((L_vdate + C_rec_contract_ordsku.lead_time) < L_min_esd) or L_min_esd is NULL then
            L_min_esd := L_vdate + C_rec_contract_ordsku.lead_time;
         end if;
         ---
         if ((L_vdate + C_rec_contract_ordsku.lead_time + L_latest_ship_days) > L_max_lsd) or L_max_lsd is NULL then
            L_max_lsd := L_vdate + C_rec_contract_ordsku.lead_time + L_latest_ship_days;
         end if;
         ---
         --Insert record into ordloc table.
         ---
         SQL_LIB.SET_MARK('INSERT', NULL, 'ordloc', 'CONTRACT_ORDHEAD_SEQ: '||to_char(I_contract_ordhead_seq));
         ---
         insert into ordloc(order_no,
                            item,
                            location,
                            loc_type,
                            unit_retail,
                            qty_ordered,
                            qty_received,
                            last_received,
                            qty_cancelled,
                            cancel_code,
                            cancel_date,
                            cancel_id,
		            qty_prescaled,
                            unit_cost,
                            unit_cost_init,
                            cost_source,
                            non_scale_ind)
                     select C_rec.order_no,
                            col.item,
                            col.location,
                            col.loc_type,
                            col.unit_retail,
                            col.qty_ordered,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
		            col.qty_ordered,
                            C_rec_contract_ordsku.unit_cost,
                            NULL,
                            'CONT',
                            'N'
                       from contract_ordloc col
                      where col.contract_no          = C_rec.contract_no
                        and col.contract_ordhead_seq = I_contract_ordhead_seq
                        and col.item                 = C_rec_contract_ordsku.item;

         ---
         if L_elc_ind = 'Y' then
            ---
            --Default expense components for all locations for the order item.
            if ORDER_EXPENSE_SQL.INSERT_COST_COMP(O_error_message,
                                                  C_rec.order_no,
                                                  C_rec_contract_ordsku.item,
	                                          NULL,
                                                  NULL,
                                                  NULL) = FALSE then
               return FALSE;
            end if;
            ---
            -- this only should be done if the order is an import order
            -- that is when the base country is different than the contract country
            if (L_base_country_id != L_contract_country) then
               --Default and calculate HTS information and duty components for the order item.
               if ORDER_HTS_SQL.DEFAULT_CALC_HTS(O_error_message,
                                                 C_rec.order_no,
                                                 C_rec_contract_ordsku.item,
				                 NULL) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            --Recalculate expenses associated with the order/item.
            if ELC_CALC_SQL.CALC_COMP(O_error_message,
                                      'PE',
                                      C_rec_contract_ordsku.item,
                                      NULL,
                                      NULL,
                                      NULL,
                                      C_rec.order_no,
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
         end if; --L_elc_ind = 'Y'
         ---
         if ORDER_SETUP_SQL.DEFAULT_ORDSKU_DOCS(O_error_message,
                                                C_rec.order_no,
                                                C_rec_contract_ordsku.item,
                                                C_rec_contract_ordsku.country_id,
                                                L_elc_ind,
                                                'Y') = FALSE then
            return FALSE;
         end if;

      END LOOP; --End of C_CONTRACT_ORDSKU loop
      ---
      -- Determine whether multiple locations exist on the order.
      ---
      if ORDER_ATTRIB_SQL.MULTIPLE_LOCS_EXIST(O_error_message,
                                              L_location,
                                              L_loc_type,
                                              L_multiple_locs_exist,
                                              L_virtual_wh,
                                              C_rec.order_no) = FALSE then
         return FALSE;
      end if;
      ---
      -- Add order inventory management information
      ---
      if ORDER_SETUP_SQL.DEFAULT_ORDER_INV_MGMT_INFO(O_error_message,
                                                     C_rec.order_no,
                                                     C_rec.supplier,
                                                     C_rec.dept,
                                                     L_location,
                                                     C_rec.currency_code,
                                                     L_exchange_rate,
                                                     'CO',
                                                     'N') = FALSE then
         return FALSE;
      end if;
      ---
      -- Get default Inventory Management information
      ---
      if SUP_INV_MGMT_SQL.GET_PURCHASE_PICKUP(O_error_message,
                                              L_purchase_type,
                                              L_pickup_loc,
                                              C_rec.supplier,
                                              C_rec.dept,
                                              L_location) = FALSE then
         return FALSE;
      end if;
      ---
      if L_purchase_type in ('FOB','BACK') then
         if ORDER_CALC_SQL.CALC_HEADER_DATES(O_error_message,
                                             L_pickup_date,
                                             L_not_before_date,
                                             L_not_after_date,
                                             C_rec.order_no,
                                             C_rec.supplier) = FALSE then
            return FALSE;
         end if;
         ---
         if C_rec.not_after_date < L_pickup_date then
            L_pickup_date := C_rec.not_after_date;
         end if;
         ---
         LP_table := 'ORDSKU';
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDSKU','ORDSKU',NULL);
         open C_LOCK_ORDSKU(C_rec.order_no);
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDSKU','ORDSKU',NULL);
         close C_LOCK_ORDSKU;
         ---
         update ordsku
            set pickup_loc = L_pickup_loc
          where order_no   = C_rec.order_no;
         ---
         LP_table := 'ORDHEAD';
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDHEAD','ORDHEAD',NULL);
         open C_LOCK_ORDHEAD(C_rec.order_no);
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDHEAD','ORDHEAD',NULL);
         close C_LOCK_ORDHEAD;
         ---
         if L_purchase_type = 'BACK' then
            update ordhead
               set purchase_type      = L_purchase_type,
                   pickup_loc         = L_pickup_loc,
                   pickup_date        = L_pickup_date,
                   backhaul_type      = 'C',
                   earliest_ship_date = L_min_esd,
                   latest_ship_date   = L_max_lsd
             where order_no           = C_rec.order_no;
            ---
            -- Default in any Backhaul Allowance Expenses
            ---
            if L_elc_ind = 'Y' then
               if ORDER_EXPENSE_SQL.INSERT_COST_COMP(O_error_message,
                                                     C_rec.order_no,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     'Y') = FALSE then
                  return FALSE;
               end if;
            end if;
         else
            update ordhead
               set purchase_type      = L_purchase_type,
                   pickup_loc         = L_pickup_loc,
                   pickup_date        = L_pickup_date,
                   earliest_ship_date = L_min_esd,
                   latest_ship_date   = L_max_lsd
             where order_no           = C_rec.order_no;
         end if;
      else
         ---
         LP_table := 'ORDHEAD';
         ---
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDHEAD','ORDHEAD',NULL);
         open C_LOCK_ORDHEAD(C_rec.order_no);
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDHEAD','ORDHEAD',NULL);
         close C_LOCK_ORDHEAD;
         ---
         update ordhead
            set purchase_type      = L_purchase_type,
                earliest_ship_date = L_min_esd,
                latest_ship_date   = L_max_lsd
          where order_no           = C_rec.order_no;
      end if;
      ---
      -- Update records last_ordered_date on contract_header.
      ---
      SQL_LIB.SET_MARK('UPDATE', NULL, 'contract_header', 'CONTRACT_NO: '||to_char(C_rec.contract_no));
      update contract_header
         set last_ordered_date = L_written_date
        where contract_no      = C_rec.contract_no;
   END LOOP;

   return TRUE;

EXCEPTION
   when DATE_FAILED then
      O_error_message := SQL_LIB.CREATE_MSG('STKLEDGR_DATE',
                                            L_function,
                                            'CONTRACT_ORDER_SQL',
                                            NULL);
      return FALSE;
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message :=  SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'CONTRACT_ORDER_SQL.CREATE_CONTRACT_ORDERS',
                                             to_char(SQLCODE));
      return FALSE;
END CREATE_CONTRACT_ORDERS;
-----------------------------------------------------------------------------
FUNCTION POP_CONTRACT_ORDSKU (I_skulist       IN SKULIST_DETAIL.SKULIST%TYPE,
                              I_seq           IN CONTRACT_ORDHEAD.CONTRACT_ORDHEAD_SEQ%TYPE,
                              O_error_message IN OUT VARCHAR2)
   return BOOLEAN is

   L_today              DATE                                    := Get_vdate;
   L_item	            CONTRACT_ORDSKU.ITEM%TYPE               := NULL;
   L_soft_contract_ind  SYSTEM_OPTIONS.SOFT_CONTRACT_IND%TYPE   := NULL;
   L_diff_1             ITEM_MASTER.DIFF_1%TYPE;
   L_diff_2             ITEM_MASTER.DIFF_2%TYPE;
   L_diff_3             ITEM_MASTER.DIFF_3%TYPE;
   L_diff_4             ITEM_MASTER.DIFF_4%TYPE;
   L_item_parent        ITEM_MASTER.ITEM_PARENT%TYPE;
   L_item_grandparent   ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_parent_exists      VARCHAR2(1)                             := NULL;
   L_exists             VARCHAR2(1)                             := NULL;

   cursor C_SOFT_CONTRACT_IND is
      select soft_contract_ind
        from system_options;

   cursor C_ITEM is
      select item
        from skulist_detail
       where item_level = tran_level
         and skulist = I_skulist;

   cursor C_ITEM_INFO is
      select item_parent,
             item_grandparent,
             diff_1,
             diff_2,
             diff_3,
             diff_4
        from item_master
       where item = L_item
         and item_parent is not NULL;

   cursor C_ANCESTRY_CHECK_AB is
      select 'X'
        from contract_detail cd,
             contract_header ch
       where ch.contract_no = cd.contract_no
         and ch.status in ('A','R')
         and ch.start_date <= L_today
         and ch.contract_type = 'A'
         and (   (    cd.item = L_item
                  and cd.item_level_index = 1)
              or (   ((cd.item_parent = L_item_parent
                      and cd.diff_1 = L_diff_1)
                  or (cd.item_grandparent = L_item_grandparent
                      and cd.diff_1 = L_diff_1))
                  and cd.item_level_index = 2)
              or (   ((cd.item_parent = L_item_parent
                      and cd.diff_2 = L_diff_2)
                  or (cd.item_grandparent = L_item_grandparent
                      and cd.diff_2 = L_diff_2))
                  and cd.item_level_index = 3)
              or (   ((cd.item_parent = L_item_parent
                      and cd.diff_3 = L_diff_3)
                  or (cd.item_grandparent = L_item_grandparent
                      and cd.diff_3 = L_diff_3))
                  and cd.item_level_index = 4)
              or (   ((cd.item_parent = L_item_parent
                      and cd.diff_4 = L_diff_4)
                  or (cd.item_grandparent = L_item_grandparent
                      and cd.diff_4 = L_diff_4))
                  and cd.item_level_index = 5)
              or (   (cd.item_parent = L_item_parent
                    or cd.item_grandparent = L_item_grandparent)
                  and cd.item_level_index = 6));

   cursor C_ANCESTRY_CHECK_CD is
      select 'X'
        from contract_cost cc,
             contract_header ch
       where ch.contract_no = cc.contract_no
         and ch.status in ('A','R')
         and ch.start_date <= L_today
         and ch.contract_type in ('C','D')
         and (   (    cc.item = L_item
                  and cc.item_level_index = 1)
              or (   ((cc.item_parent = L_item_parent
                      and cc.diff_1 = L_diff_1)
                  or (cc.item_grandparent = L_item_grandparent
                      and cc.diff_1 = L_diff_1))
                  and cc.item_level_index = 2)
              or (   ((cc.item_parent = L_item_parent
                      and cc.diff_2 = L_diff_2)
                  or (cc.item_grandparent = L_item_grandparent
                      and cc.diff_2 = L_diff_2))
                  and cc.item_level_index = 3)
              or (   ((cc.item_parent = L_item_parent
                      and cc.diff_3 = L_diff_3)
                  or (cc.item_grandparent = L_item_grandparent
                      and cc.diff_3 = L_diff_3))
                  and cc.item_level_index = 4)
              or (   ((cc.item_parent = L_item_parent
                      and cc.diff_4 = L_diff_4)
                  or (cc.item_grandparent = L_item_grandparent
                      and cc.diff_4 = L_diff_4))
                  and cc.item_level_index = 5)
              or (   (cc.item_parent = L_item_parent
                    or cc.item_grandparent = L_item_grandparent)
                  and cc.item_level_index = 6));

   cursor C_NO_ITEM_CHECK is
      select 'X'
        from contract_cost cc,
             contract_header ch
       where ch.contract_no = cc.contract_no
         and ch.status in ('A','R')
         and ch.contract_type != 'B'
         and ch.start_date <= L_today
         and cc.item = L_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN','c_soft_contract_ind',
         'system_options',NULL);
   open C_SOFT_CONTRACT_IND;

   SQL_LIB.SET_MARK('FETCH',
      'c_soft_contract_ind','system_options',NULL);
   fetch C_SOFT_CONTRACT_IND into L_soft_contract_ind;

   SQL_LIB.SET_MARK('CLOSE',
      'c_soft_contract_ind','system_options',NULL);
   close C_SOFT_CONTRACT_IND;

   SQL_LIB.SET_MARK('OPEN','c_item',
                    'skulist_detail',NULL);
   open C_ITEM;
   LOOP

      SQL_LIB.SET_MARK('FETCH',
                       'c_item','skulist_detail',NULL);
      fetch C_ITEM into L_item;
      if C_ITEM%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'c_item','skulist_detail',NULL);
         close C_ITEM;
         exit;
      end if;
      SQL_LIB.SET_MARK('OPEN', 'C_ITEM_INFO', 'ITEM_MASTER', NULL);
      open C_ITEM_INFO;
      SQL_LIB.SET_MARK('FETCH', 'C_ITEM_INFO', 'ITEM_MASTER', NULL);
      fetch C_ITEM_INFO into L_item_parent, L_item_grandparent, L_diff_1, L_diff_2, L_diff_3, L_diff_4;
      if C_ITEM_INFO%NOTFOUND then
         L_parent_exists := 'N';
         SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_INFO', 'ITEM_MASTER', NULL);
         close C_ITEM_INFO;
      else
         L_parent_exists := 'Y';
         SQL_LIB.SET_MARK('CLOSE', 'C_ITEM_INFO', 'ITEM_MASTER', NULL);
         close C_ITEM_INFO;
      end if;
      if L_parent_exists = 'Y' and L_soft_contract_ind = 'Y' then
         --
         -- Verify that the tran_level item is on a current, approved contract.
         -- If so, insert it into contract_ordsku.
         --
         SQL_LIB.SET_MARK('OPEN','C_ANCESTRY_CHECK_AB',
                          'contract_header/contract_detail',NULL);
         open C_ANCESTRY_CHECK_AB;
         SQL_LIB.SET_MARK('FETCH','C_ANCESTRY_CHECK_AB',
                          'contract_header/contract_detail',NULL);
         fetch C_ANCESTRY_CHECK_AB into L_exists;
         if C_ANCESTRY_CHECK_AB%FOUND then
            SQL_LIB.SET_MARK('INSERT',
                             NULL,'contract_ordsku',NULL);
            insert into contract_ordsku (contract_ordhead_seq,
                                         item)
                                  values(I_seq,
                                         L_item);
         else
            SQL_LIB.SET_MARK('OPEN','C_ANCESTRY_CHECK_CD',
                             'contract_header/contract_cost',NULL);
            open C_ANCESTRY_CHECK_CD;
            SQL_LIB.SET_MARK('FETCH','C_ANCESTRY_CHECK_CD',
                             'contract_header/contract_cost',NULL);
            fetch C_ANCESTRY_CHECK_CD into L_exists;
            if C_ANCESTRY_CHECK_CD%FOUND then
               SQL_LIB.SET_MARK('INSERT',
                                NULL,'contract_ordsku',NULL);
               insert into contract_ordsku (contract_ordhead_seq,
                                            item)
                                     values(I_seq,
                                            L_item);
            end if;
            SQL_LIB.SET_MARK('CLOSE','C_ANCESTRY_CHECK_CD',
                             'contract_header/contract_detail',NULL);
            close C_ANCESTRY_CHECK_CD;
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_ANCESTRY_CHECK_AB',
                          'contract_header/contract_detail',NULL);
         close C_ANCESTRY_CHECK_AB;
      elsif L_parent_exists = 'N' or L_soft_contract_ind = 'N' then
         --
         -- Verify that the item is on a current, approved contract.
         -- If so, insert it into contract_ordsku.
         --
         SQL_LIB.SET_MARK('OPEN','C_NO_ITEM_CHECK',
                          'contract_header/contract_cost',NULL);
         open C_NO_ITEM_CHECK;
         SQL_LIB.SET_MARK('FETCH','C_NO_ITEM_CHECK',
                          'contract_header/contract_cost',NULL);
         fetch C_NO_ITEM_CHECK into L_exists;
         if C_NO_ITEM_CHECK%FOUND then
            SQL_LIB.SET_MARK('INSERT',
                             NULL,'contract_ordsku',NULL);
            insert into contract_ordsku (contract_ordhead_seq,
                                         item)
                                  values(I_seq,
                                         L_item);
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_NO_ITEM_CHECK',
                          'contract_header/contract_cost',NULL);
         close C_NO_ITEM_CHECK;
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS THEN
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                           SQLERRM,
                                           'CONTRACT_ORDER_SQL.POP_CONTRACT_ORDSKU',
                                           to_char(SQLCODE));
     return FALSE;

END POP_CONTRACT_ORDSKU;
-----------------------------------------------------------------------------
FUNCTION UPDATE_ORDITEM(O_error_message        IN OUT  VARCHAR2,
                        O_adequate_sup_avail   IN OUT  BOOLEAN,
                        I_contract_no          IN      ordhead.contract_no%TYPE,
                        I_order_no             IN      ordhead.order_no%TYPE,
                        I_item                 IN      CONTRACT_ORDSKU.ITEM%TYPE,
                        I_qty_ordered          IN      contract_ordloc.qty_ordered%TYPE,
                        I_contract_type        IN      contract_header.contract_type%TYPE,
                        I_add_delete_ind       IN      VARCHAR2,
                        I_allow_over_order_ind IN      VARCHAR2,
                        I_ignore_sup_avail     IN      BOOLEAN)
return BOOLEAN IS

   L_contract_type     contract_header.contract_type%TYPE;
   L_supplier          sup_avail.supplier%TYPE;
   L_sup_avail         sup_avail.qty_avail%TYPE := 0;
   L_item_parent       ITEM_MASTER.ITEM_PARENT%TYPE;
   L_item_grandparent  ITEM_MASTER.ITEM_GRANDPARENT%TYPE;
   L_diff_1            ITEM_MASTER.DIFF_1%TYPE;
   L_diff_2            ITEM_MASTER.DIFF_2%TYPE;
   L_diff_3            ITEM_MASTER.DIFF_3%TYPE;
   L_diff_4            ITEM_MASTER.DIFF_4%TYPE;
   L_qty_left          contract_ordloc.qty_ordered%TYPE    := I_qty_ordered;
   L_avail             ordloc.qty_ordered%TYPE := 0;
   L_ordered           ordloc.qty_ordered%TYPE := 0;
   L_sup_update_qty    ordloc.qty_ordered%TYPE := 0;
   L_update_qty        ordloc.qty_ordered%TYPE := 0;
   L_rowid             ROWID;

   cursor C_ORDLOC is
      select SUM(qty_ordered - NVL(qty_received, 0))
        from ordloc
       where order_no = I_order_no
         and item = I_item;

   cursor C_CONTRACT_HEADER is
      select contract_type,
             supplier
        from contract_header
       where contract_no = I_contract_no;

   cursor C_SUP_AVAIL is
      select NVL(qty_avail, 0) qty_avail
        from sup_avail
       where supplier = L_supplier
         and item     = I_item;

   cursor C_LOCK_SUP_AVAIL is
    select 'x'
      from sup_avail
     where supplier = L_supplier
       and item     = I_item
       for update nowait;

   cursor C_ITEM_MASTER is
       select item_parent,
              item_grandparent,
              diff_1,
              diff_2,
              diff_3,
              diff_4
         from item_master
        where item = I_item;

   cursor C_CONT_DETL_ADD is
      select qty_contracted - NVL(qty_ordered,0) avail,
             rowid
        from contract_detail
       where contract_no = I_contract_no
         and ((item_level_index = 1
               and item = I_item)
          or (item_level_index = 2
         and ((item_parent = L_item_parent
         and   diff_1 = L_diff_1)
          or  (item_grandparent = L_item_grandparent
         and   diff_1 = L_diff_1)))
          or (item_level_index = 3
         and ((item_parent = L_item_parent
         and   diff_2 = L_diff_2)
          or  (item_grandparent = L_item_grandparent
         and   diff_2 = L_diff_2)))
          or (item_level_index = 4
         and ((item_parent = L_item_parent
         and   diff_3 = L_diff_3)
          or  (item_grandparent = L_item_grandparent
         and   diff_3 = L_diff_3)))
          or (item_level_index = 5
         and ((item_parent = L_item_parent
         and   diff_4 = L_diff_4)
          or  (item_grandparent = L_item_grandparent
         and   diff_4 = L_diff_4)))
          or (item_level_index = 6
         and (item_parent = L_item_parent
          or  item_grandparent = L_item_grandparent)))
       order by  ready_date,
                 item_level_index asc
      for update of qty_ordered nowait;

   cursor C_CONT_DETL_DEL is
      select NVL(qty_ordered,0) ordered
        from contract_detail
       where contract_no = I_contract_no
         and ((item_level_index = 1
               and item = I_item)
          or (item_level_index = 2
         and ((item_parent = L_item_parent
         and   diff_1 = L_diff_1)
          or  (item_grandparent = L_item_grandparent
         and   diff_1 = L_diff_1)))
          or (item_level_index = 3
         and ((item_parent = L_item_parent
         and   diff_2 = L_diff_2)
          or  (item_grandparent = L_item_grandparent
         and   diff_2 = L_diff_2)))
          or (item_level_index = 4
         and ((item_parent = L_item_parent
         and   diff_3 = L_diff_3)
          or  (item_grandparent = L_item_grandparent
         and   diff_3 = L_diff_3)))
          or (item_level_index = 5
         and ((item_parent = L_item_parent
         and   diff_4 = L_diff_4)
          or  (item_grandparent = L_item_grandparent
         and   diff_4 = L_diff_4)))
          or (item_level_index = 6
         and (item_parent = L_item_parent
          or  item_grandparent = L_item_grandparent)))
       order by ready_date desc,
                item_level_index desc
      for update of qty_ordered nowait;

BEGIN

   O_adequate_sup_avail := TRUE;

   if I_qty_ordered is NULL then
      open  C_ORDLOC;
      fetch C_ORDLOC into L_qty_left;
      close C_ORDLOC;
   else
      L_qty_left := I_qty_ordered;
   end if;

   open  C_CONTRACT_HEADER;
   fetch C_CONTRACT_HEADER into L_contract_type,
                                L_supplier;
   close C_CONTRACT_HEADER;

   open  C_ITEM_MASTER;
   fetch C_ITEM_MASTER into L_item_parent,
                            L_item_grandparent,
                            L_diff_1,
                            L_diff_2,
                            L_diff_3,
                            L_diff_4;
   close C_ITEM_MASTER;

   if I_add_delete_ind = 'A' then

      -- update sup_avail
      if L_contract_type in ('A', 'D') then
         SQL_LIB.SET_MARK('OPEN','C_SUP_AVAIL','sup_avail',NULL);
         open C_SUP_AVAIL;
         SQL_LIB.SET_MARK('FETCH','C_SUP_AVAIL','sup_avail',NULL);
         fetch C_SUP_AVAIL into L_sup_avail;
         SQL_LIB.SET_MARK('CLOSE','C_SUP_AVAIL','sup_avail',NULL);
         close C_SUP_AVAIL;

         L_sup_update_qty := L_qty_left;

         --- Check for adequate supplier availability
         if nvl(L_sup_avail,0) < L_sup_update_qty then

            --- Supplier availability is not adequate so set output parameter to FALSE
            O_adequate_sup_avail := FALSE;

            if I_ignore_sup_avail then
               --- If we should ignore supplier availability then bring
               --- the supplier available down to zero in sup_avail update, not an error
               L_sup_update_qty := L_sup_avail;
            else
               --- Supplier availability is NOT adequate and we are not ignoring
               --- this so create an error message and return TRUE so calling
               --- program can determine what to do.
               O_error_message := SQL_LIB.CREATE_MSG('LOW_AVAIL_SUPP',
                                                     I_item,
                                                     NULL,
                                                     NULL);
               return TRUE;
            end if;  --- I_ignore_sup_avail

         end if;

         SQL_LIB.SET_MARK('UPDATE',NULL,'sup_avail',
                          'Supplier: '||to_char(L_supplier)||
                          ', Item: '||I_item);

         open  C_LOCK_SUP_AVAIL;
         close C_LOCK_SUP_AVAIL;

         update sup_avail
           set qty_avail = qty_avail - L_sup_update_qty,
               last_update_date = (select vdate from period)
         where supplier = L_supplier
           and item     = I_item;

      end if;   -- end of update sup_avail

      if L_contract_type in ('A', 'B') then
         LP_table := 'CONTRACT_DETAIL';
         SQL_LIB.SET_MARK('UPDATE',NULL,'CONTRACT_DETAIL','CONTRACT_NO: '||
                          to_char(I_contract_no)||' ITEM: '|| I_item);
         FOR record IN C_CONT_DETL_ADD LOOP
            L_rowid := record.rowid;
            L_avail := record.avail;

            if L_avail > 0 then
               if L_avail >= L_qty_left then
                  L_update_qty := L_qty_left;
                  L_qty_left := 0;
               else
                  L_update_qty := L_avail;
                  L_qty_left := L_qty_left - L_update_qty;
               end if;

               update contract_detail
                  set qty_ordered = NVL(qty_ordered,0) + L_update_qty
                where current of C_CONT_DETL_ADD;
            end if;
            EXIT WHEN L_qty_left <= 0;
         END LOOP;

         if L_qty_left > 0 then
            if I_allow_over_order_ind = 'N' then
               O_error_message := SQL_LIB.CREATE_MSG('LOW_AVAIL_QTY',
                                                     to_char(I_contract_no),
                                                     I_item,
                                                     NULL);
               return FALSE;
            else
               SQL_LIB.SET_MARK('OPEN','C_CONT_DETL_ADD','CONTRACT_DETAIL',
                                'CONTRACT_NO: '||to_char(I_contract_no)||' ITEM: '||
                                I_item);
               open C_CONT_DETL_ADD;

               SQL_LIB.SET_MARK('FETCH','C_CONT_DETL_ADD','CONTRACT_DETAIL',
                                'CONTRACT_NO: '||to_char(I_contract_no)||' ITEM: '||
                                I_item);
               fetch C_CONT_DETL_ADD into L_avail,
                                          L_rowid;

               SQL_LIB.SET_MARK('CLOSE','C_CONT_DETL_ADD','CONTRACT_DETAIL',
                                'CONTRACT_NO: '||to_char(I_contract_no)||' ITEM: '||
                                I_item);
               close C_CONT_DETL_ADD;

               SQL_LIB.SET_MARK('UPDATE', NULL, 'CONTRACT_DETAIL', 'CONTRACT_NO: ' ||
                                to_char(I_contract_no)||' ITEM: '|| I_item);
               update contract_detail
                  set qty_ordered = NVL(qty_ordered,0) + L_qty_left
                where rowid = L_rowid;
            end if; -- allow_over_order_ind = 'Y'
         end if; -- L_qty_left > 0
      end if;   -- contract type 'A','B'

   elsif I_add_delete_ind = 'D' then
      -- update sup_avail
      if L_contract_type in ('A', 'D') then
         SQL_LIB.SET_MARK('UPDATE',NULL,'sup_avail',
                          'Supplier: '||to_char(L_supplier)||
                          ', Item: '||I_item);
         open  C_LOCK_SUP_AVAIL;
         close C_LOCK_SUP_AVAIL;

         update sup_avail
           set qty_avail = qty_avail + L_qty_left,
               last_update_date = (select vdate from period)
         where supplier = L_supplier
           and item     = I_item;
      end if;   -- end of update sup_avail

      if L_contract_type in ('A', 'B') then
         LP_table := 'CONTRACT_DETAIL';
         SQL_LIB.SET_MARK('UPDATE',NULL,'CONTRACT_DETAIL','CONTRACT_NO: '||
                          to_char(I_contract_no)||' ITEM: '|| I_item);
         FOR record IN C_CONT_DETL_DEL LOOP
            L_ordered := record.ordered;
            if L_ordered > 0 then
               if L_ordered >= L_qty_left then
                  L_update_qty := L_qty_left;
                  L_qty_left := 0;
               else
                  L_update_qty := L_ordered;
                  L_qty_left := L_qty_left - L_update_qty;
               end if;

               update contract_detail
                  set qty_ordered = qty_ordered - L_update_qty
                where current of C_CONT_DETL_DEL;
            end if;
            EXIT WHEN L_qty_left <= 0;
         END LOOP;
         if L_qty_left > 0 then
            O_error_message := SQL_LIB.CREATE_MSG('LOW_AVAIL_QTY',
                                                  to_char(I_contract_no),
                                                  I_item,
                                                  NULL);
            return FALSE;
         end if;
      end if;   -- contract type 'A','B'
   end if;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message :=  SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             LP_table,
                                             to_char(I_contract_no),
                                             I_item);
      return FALSE;

   when OTHERS then
      O_error_message :=  SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'CONTRACT_ORDER_SQL.UPDATE_ORDITEM',
                                             to_char(SQLCODE));
      return FALSE;

END UPDATE_ORDITEM;
-----------------------------------------------------------------------------
FUNCTION UPDATE_ORDSTAT (I_contract_no    IN      ordhead.contract_no%TYPE,
                         I_order_no       IN      ordhead.order_no%TYPE,
                         I_old_status     IN      ordhead.status%TYPE,
                         I_new_status     IN      ordhead.status%TYPE,
                         O_error_message  IN OUT  VARCHAR2)
RETURN BOOLEAN IS

   L_contract_no         ordhead.contract_no%TYPE           := I_contract_no;
   L_order_no            ordhead.order_no%TYPE              := I_order_no;
   L_qty_ordered         ordloc.qty_ordered%TYPE            := 0;
   L_contract_type       contract_header.contract_type%TYPE;
   L_ord_total_cost      ordloc.unit_cost%TYPE;
   L_ord_outstand_cost   ordloc.unit_cost%TYPE;
   L_ord_cancel_cost     ordloc.unit_cost%TYPE;
   L_ord_prescale_cost   ordloc.unit_cost%TYPE;
   L_add_delete_ind      VARCHAR2(1);
   L_adequate_sup_avail  BOOLEAN;

   cursor C_CONTRACT_HDR is
      select contract_type
        from contract_header
       where contract_no = I_contract_no;

   cursor C_ORDLOC is
      select item,
             SUM(qty_ordered - NVL(qty_received, 0)) qty_ordered
        from ordloc
       where order_no = I_order_no
       group by item;

   cursor C_LOCK_CONTRACT_HEADER is
    select 'x'
      from contract_header
     where contract_no = I_contract_no
       for update nowait;

BEGIN

   --Check that status change is occurring.
   if I_new_status = I_old_status then
      O_error_message := SQL_LIB.CREATE_MSG('STATUS_CHANGE',
                                            to_char(I_order_no),
                                            to_char(I_contract_no),
                                            NULL);
      return FALSE;
   end if;

   if ORDER_CALC_SQL.TOTAL_COSTS(O_error_message,
                                 L_ord_total_cost,
	                         L_ord_prescale_cost,
                                 L_ord_outstand_cost,
                                 L_ord_cancel_cost,
                                 I_order_no,
			         NULL,
			         NULL) = FALSE then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_CONTRACT_HDR','contract_header',NULL);
   open C_CONTRACT_HDR;
   SQL_LIB.SET_MARK('FETCH','C_CONTRACT_HDR','contract_header',NULL);
   fetch C_CONTRACT_HDR into L_contract_type;
   SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_HDR','contract_header',NULL);
   close C_CONTRACT_HDR;

   if I_new_status = 'A' then
      L_add_delete_ind := 'A';
   elsif I_new_status in ('D', 'C') then
      L_add_delete_ind := 'D';
   end if;

   -- Loop through items in order.
   FOR c_ordloc_rec IN c_ordloc
   LOOP
      if CONTRACT_ORDER_SQL.UPDATE_ORDITEM(O_error_message,
                                           L_adequate_sup_avail,
                                           I_contract_no,
                                           I_order_no,
                                           C_ordloc_rec.item,
                                           C_ordloc_rec.qty_ordered,
                                           L_contract_type,
                                           L_add_delete_ind,
                                           'N',
                                           FALSE) =  FALSE then
         return FALSE;
      end if;

      --- If supplier availability is not adequate then fail
      if L_adequate_sup_avail = FALSE then
         return FALSE;
      end if;

   END LOOP;

   --Update contract header.
   if I_new_status = 'A' then

      SQL_LIB.SET_MARK('UPDATE',NULL,'contract_header',
                       'Contract no: '||to_char(I_contract_no));

      open  C_LOCK_CONTRACT_HEADER;
      close C_LOCK_CONTRACT_HEADER;

      update contract_header
        set outstand_cost = outstand_cost - NVL(L_ord_total_cost, 0)
       where contract_no = I_contract_no;

   elsif I_new_status in ('D', 'C') then

      SQL_LIB.SET_MARK('UPDATE',NULL,'contract_header',
                       'Contract no: '||to_char(I_contract_no));

      open  C_LOCK_CONTRACT_HEADER;
      close C_LOCK_CONTRACT_HEADER;

      update contract_header
        set outstand_cost = outstand_cost + NVL(L_ord_total_cost, 0)
       where contract_no = I_contract_no;

   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            to_char(L_contract_no),
                                            to_char(L_order_no));
      return FALSE;

   when OTHERS then
      O_error_message :=  SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'CONTRACT_ORDER_SQL.UPDATE_ORDSTAT',
                                             to_char(SQLCODE));
      return FALSE;

END UPDATE_ORDSTAT;
-----------------------------------------------------------------------------
FUNCTION UPDATE_CONTRACT_ORD (I_item             IN     ITEM_MASTER.ITEM%TYPE,
                              I_seq              IN     CONTRACT_ORDLOC.CONTRACT_ORDHEAD_SEQ%TYPE,
                              I_contract_no      IN     CONTRACT_ORDLOC.CONTRACT_NO%TYPE,
                              O_error_message    IN OUT VARCHAR2)
return BOOLEAN IS

   L_contract_ordhead_seq  CONTRACT_ORDSKU.CONTRACT_ORDHEAD_SEQ%TYPE;
   L_item                  CONTRACT_ORDSKU.ITEM%TYPE;
   L_contract_no           CONTRACT_ORDLOC.CONTRACT_NO%TYPE;
   L_loc_type              contract_ordloc.loc_type%TYPE;
   L_location              contract_ordloc.location%TYPE;
   L_unit_cost             contract_ordsku.unit_cost%TYPE;
   L_unit_retail           contract_ordloc.unit_retail%TYPE := NULL;


   cursor C_LOCATION_TYPE is
      select col.loc_type,
             col.location,
             col.unit_retail
        from contract_ordloc col
       where col.item = I_item
         and col.contract_ordhead_seq = I_seq
         for update of unit_retail nowait;

   cursor C_GET_UNIT_RETAIL is
      select unit_retail
        from item_loc
       where item = I_item
         and loc = L_location
         and loc_type = L_loc_type;

   cursor C_LOCK_CONTRACT_ORDSKU is
      select 'x'
        from contract_ordsku
       where item = I_item
         and contract_ordhead_seq = I_seq
         for update nowait;


BEGIN

   LP_table := 'CONTRACT_ORDLOC';

   --Get the location.
   for C_LOCATION_TYPE_REC in C_LOCATION_TYPE
   loop

      L_loc_type := C_location_type_rec.loc_type;
      L_location := C_location_type_rec.location;

      SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_RETAIL','ITEM_LOC',null);
      open  C_GET_UNIT_RETAIL;
      SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_RETAIL','ITEM_LOC',null);
      fetch C_GET_UNIT_RETAIL into L_unit_retail;

      if C_GET_UNIT_RETAIL%NOTFOUND then
         o_error_message := SQL_LIB.CREATE_MSG('NO_REC_ITEM_LOC_LOCT',I_item,
                            to_char(L_location), L_loc_type);
         SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_RETAIL','ITEM_LOC',null);
         CLOSE C_GET_UNIT_RETAIL;
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_RETAIL','ITEM_LOC',null);
      close C_GET_UNIT_RETAIL;

      if L_unit_retail is not NULL then
         update contract_ordloc
            set unit_retail = L_unit_retail
          where current of C_location_type;
      end if;

   end loop;

   --Get I_item's contract unit cost.
   if CONTRACT_SQL.GET_UNIT_COST(O_error_message,
                                 I_item,
                                 I_contract_no,
                                 L_unit_cost) = FALSE then
      return FALSE;
   end if;

   --Update the contract ordsku table with the unit cost.
   SQL_LIB.SET_MARK('UPDATE',null,'contract_ordsku',null);

   LP_table := 'CONTRACT_ORDSKU';
   open C_LOCK_CONTRACT_ORDSKU;
   close C_LOCK_CONTRACT_ORDSKU;

   update contract_ordsku cos
      set cos.contract_no = I_contract_no,
          cos.unit_cost = L_unit_cost
    where cos.item = I_item
      and cos.contract_ordhead_seq = I_seq;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            to_char(L_contract_ordhead_seq),
                                            I_item);
      return FALSE;

   when OTHERS THEN
      o_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_ORDER_SQL.UPDATE_CONTRACT_ORD',
                                            to_char(SQLCODE));
      return FALSE;

END UPDATE_CONTRACT_ORD;
-----------------------------------------------------------------------------
FUNCTION CONTRACT_ITEM_EXISTS(O_error_message     IN OUT VARCHAR2,
                              O_contract_ind      IN OUT BOOLEAN,
                              I_skulist           IN     SKULIST_DETAIL.SKULIST%TYPE)
RETURN BOOLEAN IS

   L_order_number          contract_ordhead.order_no%TYPE := 0;
   L_today                 DATE                           := Get_vdate;
   L_exists                VARCHAR2(1)                    := NULL;


   cursor C_CONTRACT_ITEM_EXISTS is
      select 'X'
       from skulist_detail
      where skulist_detail.skulist = I_skulist
        and exists(select 'x'
                     from contract_cost cc,
                          contract_header ch
                    where ch.contract_no = cc.contract_no
                      and ch.status in ('A','R')
                      and ch.start_date <= L_today
                      and ch.contract_type != 'B'
                      and ch.orderable_ind = 'Y'
                      and (cc.item = skulist_detail.item
                          or cc.item_parent in (select im.item_parent
                                                 from item_master im
                                                where skulist_detail.item = im.item)
                          or cc.item_grandparent in (select im.item_grandparent
                                                       from item_master im
                                                      where skulist_detail.item = im.item)));


BEGIN

   if I_skulist is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('ENTER_ITEMLIST',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   -- Validate that item list contains items that are on a current, approved
   -- contract.
   --
   open C_CONTRACT_ITEM_EXISTS;
   fetch C_CONTRACT_ITEM_EXISTS into L_exists;

   if C_CONTRACT_ITEM_EXISTS%NOTFOUND then
      close C_CONTRACT_ITEM_EXISTS;
      O_contract_ind := FALSE;
   else
      close C_CONTRACT_ITEM_EXISTS;
      O_contract_ind := TRUE;
   end if;

   return TRUE;

EXCEPTION
    when OTHERS THEN
      o_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_ORDER_SQL.CONTRACT_ITEM_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;

END CONTRACT_ITEM_EXISTS;
-----------------------------------------------------------------------------
FUNCTION VALIDATE_UPDATES(O_error_message  IN OUT  VARCHAR2,
                          I_contract_no    IN      ORDHEAD.CONTRACT_NO%TYPE,
                          I_order_no       IN      ORDHEAD.ORDER_NO%TYPE,
                          I_old_status     IN      ORDHEAD.STATUS%TYPE,
                          I_new_status     IN      ORDHEAD.STATUS%TYPE)
RETURN BOOLEAN IS
   L_contract_type     CONTRACT_HEADER.CONTRACT_TYPE%TYPE;
   L_add_delete_ind    VARCHAR2(1);
   L_supplier          SUP_AVAIL.SUPPLIER%TYPE;
   L_item              ORDLOC.ITEM%TYPE;
   L_sup_avail         SUP_AVAIL.QTY_AVAIL%TYPE;


   cursor C_CONTRACT_HDR is
      select contract_type,
             supplier
        from contract_header
       where contract_no = I_contract_no;

   cursor C_ORDLOC is
      select item,
             SUM(NVL(qty_ordered, 0) - NVL(qty_received, 0)) qty_ordered
        from ordloc
       where order_no = I_order_no
       group by item;

   cursor C_SUP_AVAIL is
      select NVL(qty_avail, 0) qty_avail
        from sup_avail
       where supplier = L_supplier
         and item     = L_item;

BEGIN
   --Check that status change is occurring.
   if I_new_status = I_old_status then
      O_error_message := SQL_LIB.CREATE_MSG('STATUS_CHANGE',
                                            to_char(I_order_no),
                                            to_char(I_contract_no),
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN','C_CONTRACT_HDR','contract_header',NULL);
   open C_CONTRACT_HDR;
   SQL_LIB.SET_MARK('FETCH','C_CONTRACT_HDR','contract_header',NULL);
   fetch C_CONTRACT_HDR into L_contract_type,
                             L_supplier;
   SQL_LIB.SET_MARK('CLOSE','C_CONTRACT_HDR','contract_header',NULL);
   close C_CONTRACT_HDR;

   if L_contract_type in ('A', 'D') then
      FOR c_ordloc_rec IN c_ordloc
      LOOP
         L_item := C_ordloc_rec.item;
         -- Check sup_avail
         SQL_LIB.SET_MARK('OPEN','C_SUP_AVAIL','sup_avail',NULL);
         open C_SUP_AVAIL;
         SQL_LIB.SET_MARK('FETCH','C_SUP_AVAIL','sup_avail',NULL);
         fetch C_SUP_AVAIL into L_sup_avail;
         SQL_LIB.SET_MARK('CLOSE','C_SUP_AVAIL','sup_avail',NULL);
         close C_SUP_AVAIL;
         ---
         if L_sup_avail < C_ordloc_rec.qty_ordered then
            O_error_message := SQL_LIB.CREATE_MSG('LOW_AVAIL_SUPP',
                                                  L_item,
                                                  NULL,
                                                  NULL);
            return FALSE;
         end if;
         -- end of Check sup_avail
      END LOOP;
   end if;

   return TRUE;
EXCEPTION
    when OTHERS THEN
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_ORDER_SQL.VALIDATE_UPDATES',
                                            to_char(SQLCODE));
      return FALSE;

END VALIDATE_UPDATES;
-----------------------------------------------------------------------------
FUNCTION UPDATE_CONTRACT_HEADER_DATE ( O_error_message  IN OUT  VARCHAR2,
                                       I_contract_no    IN      ORDHEAD.CONTRACT_NO%TYPE)
return BOOLEAN IS

   L_vdate  ORDHEAD.NOT_BEFORE_DATE%TYPE       := GET_VDATE;

   cursor C_LOCK_CONTRACT_HEADER is
      select 'x'
        from contract_header
       where contract_no = I_contract_no
         for update nowait;

BEGIN
   LP_table := 'CONTRACT_HEADER';
   open C_LOCK_CONTRACT_HEADER;
   close C_LOCK_CONTRACT_HEADER;

   ---
   -- Update record's last_ordered_date on contract_header.
   ---
   SQL_LIB.SET_MARK('UPDATE', NULL, 'contract_header', 'CONTRACT_NO: '||to_char(I_contract_no));
   update contract_header
      set last_ordered_date = L_vdate
    where contract_no      = I_contract_no;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            LP_table,
                                            to_char(I_contract_no),
                                            NULL);
      return FALSE;

   when OTHERS THEN
      o_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_ORDER_SQL.UPDATE_CONTRACT_HEADER_DATE',
                                            to_char(SQLCODE));
      return FALSE;

END UPDATE_CONTRACT_HEADER_DATE;
-----------------------------------------------------------------------------
FUNCTION CONTRACT_ORDLOC_EXISTS ( O_error_message         IN OUT  VARCHAR2,
                                  O_exist                 IN OUT  BOOLEAN,
                                  I_contract_ordhead_seq  IN      CONTRACT_ORDLOC.CONTRACT_ORDHEAD_SEQ%TYPE,
                                  I_contract_no           IN      ORDHEAD.CONTRACT_NO%TYPE,
                                  I_item                  IN      CONTRACT_ORDLOC.ITEM%TYPE,
                                  I_loc                   IN      CONTRACT_ORDLOC.LOCATION%TYPE,
                                  I_loc_type              IN      CONTRACT_ORDLOC.LOC_TYPE%TYPE)
return BOOLEAN IS

   L_exist    VARCHAR2(1);

   cursor C_CONTRACT_ORDLOC is
      select 'x'
        from contract_ordloc
       where contract_ordhead_seq = I_contract_ordhead_seq
         and contract_no = I_contract_no
         and item = I_item
         and loc_type = I_loc_type
         and location = I_loc;

BEGIN

   open C_CONTRACT_ORDLOC;
   fetch C_CONTRACT_ORDLOC into L_exist;

   if C_CONTRACT_ORDLOC%NOTFOUND then
      close C_CONTRACT_ORDLOC;
      O_exist := FALSE;
   else
      close C_CONTRACT_ORDLOC;
      O_exist := TRUE;
   end if;

   return TRUE;

EXCEPTION

   when OTHERS THEN
      o_error_message := sql_lib.create_msg('PACKAGE_ERROR',
                                            SQLERRM,
                                            'CONTRACT_ORDER_SQL.CONTRACT_ORDLOC_EXISTS',
                                            to_char(SQLCODE));
      return FALSE;

END CONTRACT_ORDLOC_EXISTS;
-----------------------------------------------------------------------------
END CONTRACT_ORDER_SQL;
/

