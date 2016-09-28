CREATE OR REPLACE PACKAGE BODY DIRECT_STORE_INVOICE_SQL AS
-------------------------------------------------------------------------------
FUNCTION CREATE_INVOICE(O_error_message         IN OUT VARCHAR2,
                        IO_invc_id              IN OUT INVC_HEAD.INVC_ID%TYPE,
                        I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                        I_supplier              IN     SUPS.SUPPLIER%TYPE,
                        I_vdate                 IN     PERIOD.VDATE%TYPE,
                        I_total_cost            IN     INVC_HEAD.TOTAL_MERCH_COST%TYPE,
                        I_total_qty             IN     INVC_HEAD.TOTAL_QTY%TYPE,
                        I_store                 IN     STORE.STORE%TYPE,
                        I_paid_ind              IN     INVC_HEAD.PAID_IND%TYPE,
                        I_ext_ref_no            IN     INVC_HEAD.EXT_REF_NO%TYPE,
                        I_proof_of_delivery_no  IN     INVC_HEAD.PROOF_OF_DELIVERY_NO%TYPE,
                        I_payment_ref_no    IN     INVC_HEAD.PAYMENT_REF_NO%TYPE,
                        I_payment_date          IN     INVC_HEAD.PAYMENT_DATE%TYPE)
RETURN BOOLEAN IS

   L_invc_id            INVC_HEAD.INVC_ID%TYPE;
   L_terms              ORDHEAD.TERMS%TYPE;
   L_freight_terms      ORDHEAD.FREIGHT_TERMS%TYPE;
   L_currency_code      ORDHEAD.CURRENCY_CODE%TYPE;
   L_payment_method     ORDHEAD.PAYMENT_METHOD%TYPE;
   L_user_name          USER_ATTRIB.USER_ID%TYPE;
   L_invc_match_qty_ind SYSTEM_OPTIONS.INVC_MATCH_QTY_IND%TYPE := 'N';
   L_percent            TERMS.PERCENT%TYPE;
   L_addr_key           ADDR.ADDR_KEY%TYPE;
   L_exists             BOOLEAN                                := FALSE;
   L_program            VARCHAR2(50)                           := 'DIRECT_STORE_INVOICE_SQL.CREATE_INVOICE';

   cursor C_ORDHEAD is
      select terms,
             freight_terms,
             currency_code,
             payment_method
        from ordhead
       where order_no = I_order_no;

   cursor C_SUPS is
      select terms,
             freight_terms,
             currency_code,
             payment_method
        from sups
       where supplier = I_supplier;

   cursor C_INVC_MATCH_QTY_IND is
      select invc_match_qty_ind
        from system_options;

   cursor C_TERMS is
      select percent
        from terms
       where terms = L_terms;

BEGIN

   if I_order_no is not NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_ORDHEAD','ordhead','order_no: '||TO_CHAR(I_order_no));
      open C_ORDHEAD;

      SQL_LIB.SET_MARK('FETCH',
                       'C_ORDHEAD','ordhead','order_no: '||TO_CHAR(I_order_no));
      fetch C_ORDHEAD into L_terms,
                           L_freight_terms,
                           L_currency_code,
                           L_payment_method;

      if C_ORDHEAD%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                       'C_ORDHEAD','ordhead','order_no: '||TO_CHAR(I_order_no));
         close C_ORDHEAD;
         O_error_message := SQL_LIB.CREATE_MSG('INV_ORDER_NO',
                                               NULL,NULL,NULL);
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ORDHEAD','ordhead','order_no: '||TO_CHAR(I_order_no));
      close C_ORDHEAD;
   else
      SQL_LIB.SET_MARK('OPEN',
                       'C_SUPS','sups','supplier: '||TO_CHAR(I_supplier));
      open C_SUPS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_SUPS','sups','supplier: '||TO_CHAR(I_supplier));
      fetch C_SUPS into L_terms,
                        L_freight_terms,
                        L_currency_code,
                        L_payment_method;

      if C_SUPS%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                       'C_SUPS','sups','supplier: '||TO_CHAR(I_supplier));
         close C_SUPS;
         O_error_message := SQL_LIB.CREATE_MSG('INV_SUPPLIER',
                                               NULL,NULL,NULL);
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_SUPS','sups','supplier: '||TO_CHAR(I_supplier));
      close C_SUPS;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_INVC_MATCH_QTY_IND','system_options',NULL);
   open C_INVC_MATCH_QTY_IND;

   SQL_LIB.SET_MARK('FETCH','C_INVC_MATCH_QTY_IND','system_options',NULL);
   fetch C_INVC_MATCH_QTY_IND into L_invc_match_qty_ind;

   if C_INVC_MATCH_QTY_IND%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_INVC_MATCH_QTY_IND','system_options',NULL);
      close C_INVC_MATCH_QTY_IND;
      O_error_message := SQL_LIB.CREATE_MSG('FAILED_SYSTEM_OPTIONS',
                                            NULL,NULL,NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_INVC_MATCH_QTY_IND','system_options',NULL);
   close C_INVC_MATCH_QTY_IND;
   ---
   SQL_LIB.SET_MARK('OPEN','C_TERMS','terms','terms: '||L_terms);
   open C_TERMS;

   SQL_LIB.SET_MARK('FETCH','C_TERMS','terms','terms: '||L_terms);
   fetch C_TERMS into L_percent;

   if C_TERMS%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_TERMS','terms','terms: '||L_terms);
      close C_TERMS;
      O_error_message := SQL_LIB.CREATE_MSG('INV_TERMS',
                                            NULL,NULL,NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_TERMS','terms','terms: '||L_terms);
   close C_TERMS;
   ---
   if SQL_LIB.GET_USER_NAME(O_error_message,
                            L_user_name) = FALSE then
      return FALSE;
   end if;
   ---
   if not SUPP_ATTRIB_SQL.GET_SUP_PRIMARY_ADDR(O_error_message,
                                               L_addr_key,
                                               I_supplier,
                                               '05') then
      return FALSE;
   end if;
   ---
   if I_order_no is not NULL then
      if not DIRECT_STORE_INVOICE_SQL.CHECK_INVC_DUPS(O_error_message,
                                                      L_invc_id,
                                                      NULL,
                                                      I_supplier,
                                                      NULL,
                                                      NULL,
                                                      I_vdate,
                                                      I_ext_ref_no,
                                                      I_proof_of_delivery_no,
                                                      I_payment_ref_no,
                                                      I_payment_date) then
         return FALSE;
      end if;
   end if;
   ---
   if L_invc_id is not NULL then
     if not DIRECT_STORE_INVOICE_SQL.CHECK_INVC_DETAIL(O_error_message,
                                                       L_exists,
                                                       L_invc_id) then
        return FALSE;
     end if;
     ---
     if L_exists = TRUE then
        O_error_message := SQL_LIB.CREATE_MSG('INVC_EXIST', L_invc_id,NULL,NULL);
        return FALSE;
     end if;
     --- invoice already exists, but is only a header record. update existing record.
     update invc_head
        set total_merch_cost     = I_total_cost,
        total_qty            = DECODE(L_invc_match_qty_ind,'Y',I_total_qty,'N',NULL),
            paid_ind             = I_paid_ind,
            ext_ref_no           = nvl(I_ext_ref_no, ext_ref_no),
            proof_of_delivery_no = nvl(I_proof_of_delivery_no, proof_of_delivery_no),
            payment_ref_no       = nvl(I_payment_ref_no, payment_ref_no),
            payment_date         = nvl(I_payment_date, payment_date)
      where invc_id = L_invc_id;
   else
      if IO_invc_id is NULL then
         if INVC_SQL.NEXT_INVC_ID(O_error_message,
                                  L_invc_id) = FALSE then
            return FALSE;
         end if;
      else
         L_invc_id := IO_invc_id;
      end if;
      ---
      SQL_LIB.SET_MARK('INSERT',NULL,'invc_head',NULL);
      insert into invc_head (invc_id,
                             invc_type,
                             supplier,
                             ext_ref_no,
                             status,
                             edi_invc_ind,
                             edi_sent_ind,
                             match_fail_ind,
                             ref_invc_id,
                             ref_rtv_order_no,
                             ref_rsn_code,
                             terms,
                             due_date,
                             payment_method,
                             terms_dscnt_pct,
                             terms_dscnt_appl_ind,
                             terms_dscnt_appl_non_mrch_ind,
                             freight_terms,
                             create_id,
                             create_date,
                             invc_date,
                             match_id,
                             match_date,
                             approval_id,
                             approval_date,
                             force_pay_ind,
                             force_pay_id,
                             post_date,
                             currency_code,
                             exchange_rate,
                             total_merch_cost,
                             total_qty,
                             direct_ind,
                             addr_key,
                             paid_ind,
                             payment_ref_no,
                             payment_date,
                             proof_of_delivery_no,
                             comments)
                     values (L_invc_id,
                             decode(I_order_no, NULL, 'N', 'I'),
                             I_supplier,
                             I_ext_ref_no,
                             'A',
                             'N',
                             'N',
                             'N',
                             NULL,
                             NULL,
                             NULL,
                             L_terms,
                             I_vdate,
                             L_payment_method,
                             L_percent,
                             'N',
                             'N',
                             L_freight_terms,
                             L_user_name,
                             I_vdate,
                             I_vdate,
                             L_user_name,
                             I_vdate,
                             L_user_name,
                             I_vdate,
                             'N',
                             NULL,
                             NULL,
                             L_currency_code,
                             NULL,
                             I_total_cost,
                             DECODE(L_invc_match_qty_ind,'Y',I_total_qty,'N',NULL),
                             'Y',
                             L_addr_key,
                             I_paid_ind,
                             I_payment_ref_no,
                             I_payment_date,
                             I_proof_of_delivery_no,
                             NULL);
   end if; --new invoice

   if I_order_no is not NULL then
      -- The shipment tables are updated to reflect the creation/updating of
      -- the invoice.  As Quick Order Entry will only ever create one shipment
      -- per order we are able to query the shipment tables by the order number
      -- passed into the create invoice function.
      SQL_LIB.SET_MARK('UPDATE',NULL,'shipment',NULL);
      update shipment
         set invc_match_status = 'M',
             invc_match_date   = I_vdate
       where order_no = I_order_no;

      SQL_LIB.SET_MARK('UPDATE',NULL,'shipsku',NULL);
      update shipsku
         set match_invc_id = L_invc_id,
             qty_matched = I_total_qty
       where exists (select 'x'
                       from shipment sh
                      where order_no = I_order_no
                        and sh.shipment = shipsku.shipment);
      ---
      ---For new or updated invoice, insert details. CHECK_INVC_DUPS
      ---verifies details do not exist on invc_detail
      if DIRECT_STORE_INVOICE_SQL.INVOICE_ITEM(O_error_message,
                                               I_order_no,
                                               L_invc_id,
                                               I_store) = FALSE then
         return FALSE;
      end if;
   end if;
   --- check if incoming invoice id already exists.
   --- if it does, then non-merch details exist
   if IO_invc_id is not NULL then
      --- Insert non-merchandise details from temp table to main table
      SQL_LIB.SET_MARK('INSERT',NULL,'invc_non_merch',NULL);
      insert into invc_non_merch(invc_id,
                                 non_merch_code,
                                 non_merch_amt,
                                 vat_code,
                                 service_perf_ind,
                                 store)
                          select L_invc_id,
                                 non_merch_code,
                                 non_merch_amt,
                                 vat_code,
                                 service_perf_ind,
                                 store
                            from invc_non_merch_temp
                           where invc_id = IO_invc_id;

      SQL_LIB.SET_MARK('DELETE',NULL,'invc_non_merch_temp',NULL);
      delete from invc_non_merch_temp;
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
END CREATE_INVOICE;
-------------------------------------------------------------------------------
FUNCTION INVOICE_ITEM(O_error_message   IN OUT VARCHAR2,
                      I_order_no        IN     ORDHEAD.ORDER_NO%TYPE,
                      I_invc_id         IN     INVC_HEAD.INVC_ID%TYPE,
                      I_store           IN     STORE.STORE%TYPE)
RETURN BOOLEAN IS

   L_shipment     SHIPMENT.SHIPMENT%TYPE;
   L_item         SHIPSKU.ITEM%TYPE;
   L_ref_item     SHIPSKU.REF_ITEM%TYPE;
   L_unit_cost    SHIPSKU.UNIT_COST%TYPE;
   L_qty_received SHIPSKU.QTY_RECEIVED%TYPE;
   L_vat_region   VAT_REGION.VAT_REGION%TYPE      := NULL;
   L_vat_rate     VAT_ITEM.VAT_RATE%TYPE          := NULL;
   L_vat_code     VAT_DEPS.VAT_CODE%TYPE;
   L_vdate        PERIOD.VDATE%TYPE               := GET_VDATE;
   L_exist        VARCHAR2(1)                     := 'N';
   L_vat_ind      SYSTEM_OPTIONS.VAT_IND%TYPE     := NULL;
   L_program      VARCHAR2(50)                    := 'DIRECT_STORE_INVOICE_SQL.INVOICE_ITEM';

   cursor C_SHIPMENT is
      select shipment
        from shipment
       where order_no = I_order_no;

   cursor C_SHIPSKU is
      select item,
             ref_item,
             unit_cost,
             qty_received
        from shipsku
       where shipment = L_shipment;

  cursor C_INVC_DETAIL is
     select 'Y'
       from invc_detail
      where invc_id   = I_invc_id
        and item      = L_item
        and invc_unit_cost = L_unit_cost;
BEGIN

   SQL_LIB.SET_MARK('OPEN','C_SHIPMENT','shipment','order_no: '||TO_CHAR(I_order_no));
   open C_SHIPMENT;

   SQL_LIB.SET_MARK('FETCH','C_SHIPMENT','shipment','order_no: '||TO_CHAR(I_order_no));
   fetch C_SHIPMENT into L_shipment;

   if C_SHIPMENT%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_SHIPMENT','shipment','order_no: '||TO_CHAR(I_order_no));
      close C_SHIPMENT;
      O_error_message := SQL_LIB.CREATE_MSG('SHIP_NO_ORDER',
                                            NULL,NULL,NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_SHIPMENT','shipment','order_no: '||TO_CHAR(I_order_no));
   close C_SHIPMENT;
   ---
   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   if L_vat_ind = 'Y' then
      if VAT_SQL.GET_VAT_REGION(O_error_message,
                                L_vat_region,
                                I_invc_id,
                                I_order_no) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT',NULL,'invc_xref',NULL);
   insert into invc_xref (INVC_ID,
                         ORDER_NO,
                         SHIPMENT,
                         ASN,
                         LOCATION,
                         LOC_TYPE,
                         APPLY_TO_FUTURE_IND)
                 values (I_invc_id,
                         I_order_no,
                         L_shipment,
                         NULL,
                         I_store,
                         'S',
                         'N');

   SQL_LIB.SET_MARK('FETCH','C_SHIPSKU','shipsku','shipment: '||TO_CHAR(L_shipment));
   for rec in C_SHIPSKU LOOP
      L_item         := rec.item;
      L_ref_item     := rec.ref_item;
      L_unit_cost    := rec.unit_cost;
      L_qty_received := rec.qty_received;

      ---
      if L_vat_ind = 'Y' then
         if VAT_SQL.GET_VAT_RATE(O_error_message,
                                 L_vat_region,
                                 L_vat_code,
                                 L_vat_rate,
                                 L_item,
                                 NULL,
                                 NULL,
                                 NULL,
                                 L_vdate,
                                 'C') = FALSE then
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('INSERT',NULL,'invc_merch_vat',NULL);
         insert into invc_merch_vat(invc_id,
                                    vat_code,
                                    total_cost_excl_vat)
                             values(I_invc_id,
                                    L_vat_code,
                                    L_unit_cost * L_qty_received);
      end if;
      ---
      SQL_LIB.SET_MARK('INSERT',NULL,'invc_detail',NULL);
      insert into invc_detail (invc_id,
                              item,
                              ref_item,
                              invc_unit_cost,
                              invc_qty,
                              invc_vat_rate,
                              status,
                              orig_unit_cost,
                              orig_qty,
                              orig_vat_rate,
                              cost_dscrpncy_ind,
                              qty_dscrpncy_ind,
                              vat_dscrpncy_ind,
                              processed_ind,
                              comments)
                      values (I_invc_id,
                              L_item,
                              L_ref_item,
                              L_unit_cost,
                              L_qty_received,
                              L_vat_rate,
                              'M',
                              NULL,
                              NULL,
                              NULL,
                              'N',
                              'N',
                              'N',
                              'N',
                              NULL);
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END INVOICE_ITEM;
-------------------------------------------------------------------------------
FUNCTION CHECK_INVC_DETAIL(O_error_message  IN OUT VARCHAR2,
                           O_exists         IN OUT BOOLEAN,
                           I_invc_id        IN     INVC_DETAIL.INVC_ID%TYPE)
RETURN BOOLEAN IS

  L_exist        VARCHAR2(1)  := 'N';
  L_program      VARCHAR2(50) := 'DIRECT_STORE_INVOICE_SQL.CHECK_INVC_DETAIL';

  cursor C_INVC_DETAIL is
     select 'Y'
       from invc_detail
      where invc_id = I_invc_id;
BEGIN

  O_exists := FALSE;
  ---
  SQL_LIB.SET_MARK('OPEN','C_INVC_DETAIL','invc_detail','invc_id: '||TO_CHAR(I_invc_id));
  open C_INVC_DETAIL;

  SQL_LIB.SET_MARK('FETCH','C_INVC_DETAIL','invc_detail','invc_id: '||TO_CHAR(I_invc_id));
  fetch C_INVC_DETAIL into L_exist;

  if L_exist = 'Y' then
     O_exists := TRUE;
  end if;

  SQL_LIB.SET_MARK('CLOSE','C_INVC_DETAIL','invc_detail','invc_id: '||TO_CHAR(I_invc_id));
  close C_INVC_DETAIL;

  return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;
END CHECK_INVC_DETAIL;
-------------------------------------------------------------------------------
FUNCTION CHECK_INVC_DUPS(O_error_message        IN OUT VARCHAR2,
                         O_invc_id              IN OUT INVC_HEAD.INVC_ID%TYPE,
                         I_invc_id              IN     INVC_HEAD.INVC_ID%TYPE,
                         I_supplier         IN     INVC_HEAD.SUPPLIER%TYPE,
                         I_partner_type         IN     INVC_HEAD.PARTNER_TYPE%TYPE,
                         I_partner_id           IN     INVC_HEAD.PARTNER_ID%TYPE,
                         I_invc_date            IN     INVC_HEAD.INVC_DATE%TYPE,
                         I_ext_ref_no           IN     INVC_HEAD.EXT_REF_NO%TYPE,
                         I_proof_of_delivery_no IN     INVC_HEAD.PROOF_OF_DELIVERY_NO%TYPE,
                         I_payment_ref_no       IN     INVC_HEAD.PAYMENT_REF_NO%TYPE,
                         I_payment_date         IN     INVC_HEAD.PAYMENT_DATE%TYPE)
RETURN BOOLEAN IS

   L_program VARCHAR2(50) := 'DIRECT_STORE_INVOICE_SQL.CHECK_INVC_DUPS';

   cursor C_INVC_ID is
      select invc_id
        from invc_head
       where invc_id                      != nvl(I_invc_id, -1)
         and ((supplier                    = I_supplier
               and I_partner_type          is NULL
               and I_partner_id            is NULL)
             or (partner_type              = I_partner_type
                 and partner_id            = I_partner_id
                 and I_supplier            is NULL))
         and ((invc_date                   = I_invc_date)
             or (payment_date              = I_payment_date))
         and invc_type                     in ('I','N','O')
         and (((ext_ref_no                 = I_ext_ref_no)
             and (proof_of_delivery_no     = I_proof_of_delivery_no)
             and (payment_ref_no           = I_payment_ref_no))
          or ((ext_ref_no                  = I_ext_ref_no)
             and (proof_of_delivery_no     = I_proof_of_delivery_no)
             and (I_payment_ref_no         is NULL))
          or ((proof_of_delivery_no        = I_proof_of_delivery_no)
             and (payment_ref_no           = I_payment_ref_no)
             and (I_ext_ref_no             is NULL))
          or ((ext_ref_no                  = I_ext_ref_no)
             and (payment_ref_no           = I_payment_ref_no)
             and (I_proof_of_delivery_no   is NULL))
          or ((ext_ref_no                  = I_ext_ref_no)
             and (I_proof_of_delivery_no   is NULL)
             and (I_payment_ref_no         is NULL))
          or ((proof_of_delivery_no        = I_proof_of_delivery_no)
             and (I_ext_ref_no             is NULL)
             and (I_payment_ref_no         is NULL))
          or ((payment_ref_no              = I_payment_ref_no)
             and (I_ext_ref_no             is NULL)
             and (I_proof_of_delivery_no   is NULL))
          or ((ext_ref_no                  is NULL)
             and (proof_of_delivery_no     is NULL)
             and (payment_ref_no           = I_payment_ref_no))
          or ((proof_of_delivery_no        is NULL)
             and (payment_ref_no           is NULL)
             and (ext_ref_no               = I_ext_ref_no))
          or ((ext_ref_no                  is NULL)
             and (payment_ref_no           is NULL)
             and (proof_of_delivery_no     = I_proof_of_delivery_no))
          or ((ext_ref_no                  is NULL)
             and (proof_of_delivery_no     = I_proof_of_delivery_no)
             and (payment_ref_no           = I_payment_ref_no))
          or ((proof_of_delivery_no        is NULL)
             and (ext_ref_no               = I_ext_ref_no)
             and (payment_ref_no           = I_payment_ref_no))
          or ((payment_ref_no              is NULL)
             and (ext_ref_no               = I_ext_ref_no)
             and (proof_of_delivery_no     = I_proof_of_delivery_no)));

BEGIN

  if O_invc_id is not NULL then
     O_invc_id := NULL;
  end if;

  SQL_LIB.SET_MARK('OPEN','C_INVC_ID','invc_head','supplier: '||TO_CHAR(I_supplier));
  open C_INVC_ID;

  SQL_LIB.SET_MARK('FETCH','C_INVC_ID','invc_head','supplier: '||TO_CHAR(I_supplier));
  fetch C_INVC_ID into O_invc_id;

  SQL_LIB.SET_MARK('CLOSE','C_INVC_ID','invc_head','supplier: '||TO_CHAR(I_supplier));
  close C_INVC_ID;

  return TRUE;

EXCEPTION
  when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
     return FALSE;
END CHECK_INVC_DUPS;
-------------------------------------------------------------------------------
FUNCTION INVC_NON_MERCH_TEMP_EXIST(O_error_message   IN OUT VARCHAR2,
                                   O_exists          IN OUT BOOLEAN,
                                   I_non_merch_code  IN     NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE,
                                   I_invc_id         IN     INVC_NON_MERCH.INVC_ID%TYPE)

RETURN BOOLEAN IS

  L_exists          VARCHAR2(1);
  L_program         VARCHAR2(60) := 'DIRECT_STORE_INVOICE_SQL.INVC_NON_MERCH_TEMP_EXIST';

  cursor C_INVC_NON_MERCH_EXIST is
     select 'Y'
       from  invc_non_merch_temp
      where  non_merch_code  = I_non_merch_code
        and  invc_id         = I_invc_id;

BEGIN

  SQL_LIB.SET_MARK('OPEN','C_INVC_NON_MERCH_EXIST','invc_non_merch',NULL);
  open C_INVC_NON_MERCH_EXIST;

  SQL_LIB.SET_MARK('FETCH','C_INVC_NON_MERCH_EXIST','invc_non_merch',NULL);
  fetch C_INVC_NON_MERCH_EXIST into L_exists;

  if C_INVC_NON_MERCH_EXIST%NOTFOUND then
     O_exists := FALSE;
  else
     O_exists := TRUE;
  end if;

  SQL_LIB.SET_MARK('CLOSE','C_INVC_NON_MERCH_EXIST','invc_non_merch',NULL);
  close C_INVC_NON_MERCH_EXIST;

  return TRUE;

EXCEPTION
  when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            TO_CHAR(SQLCODE));
     RETURN FALSE;
END INVC_NON_MERCH_TEMP_EXIST;
----------------------------------------------------------------------------------
END DIRECT_STORE_INVOICE_SQL;
/

