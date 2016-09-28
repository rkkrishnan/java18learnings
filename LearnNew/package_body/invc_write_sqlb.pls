CREATE OR REPLACE PACKAGE BODY INVC_WRITE_SQL AS
-----------------------------------------------------------------------------------------
FUNCTION ASN_TO_INVC(O_error_message   IN OUT   VARCHAR2,
                     O_posted          IN OUT   BOOLEAN,
                     I_rcpt            IN       SHIPMENT.SHIPMENT%TYPE,
                     I_supplier        IN       SUPS.SUPPLIER%TYPE,
                     I_invc_type       IN       INVC_HEAD.INVC_TYPE%TYPE,
                     I_item            IN       SHIPSKU.ITEM%TYPE,
                     I_old_unit_cost   IN       SHIPSKU.UNIT_COST%TYPE,
                     I_new_unit_cost   IN       SHIPSKU.UNIT_COST%TYPE,
                     I_rcv_qty         IN       SHIPSKU.QTY_RECEIVED%TYPE,
                     I_adj_qty         IN       SHIPSKU.QTY_RECEIVED%TYPE,
                     I_vat_region      IN       VAT_ITEM.VAT_REGION%TYPE)
   RETURN BOOLEAN IS

   L_table                     VARCHAR2(30);
   RECORD_LOCKED               EXCEPTION;
   PRAGMA                      EXCEPTION_INIT(Record_Locked, -54);
   L_invc_type                 INVC_HEAD.INVC_TYPE%TYPE             := I_invc_type;
   L_supplier                  SUPS.SUPPLIER%TYPE                   := I_supplier;
   L_settlement_code           SUPS.SETTLEMENT_CODE%TYPE;
   L_auto_appr_dbt_memo        SUPS.AUTO_APPR_DBT_MEMO_IND%TYPE;
   L_invc_match_ind            SYSTEM_OPTIONS.INVC_MATCH_IND%TYPE;
   L_match_dummy               VARCHAR2(1);
   L_rec_match_invc_id         SHIPSKU.MATCH_INVC_ID%TYPE;
   L_invc_status               INVC_HEAD.STATUS%TYPE;
   L_addr_key                  INVC_HEAD.ADDR_KEY%TYPE;
   L_status                    INVC_HEAD.STATUS%TYPE;
   L_tot_invc_id               INVC_HEAD.INVC_ID%TYPE;
   L_new_invc_tot_cost         INVC_HEAD.TOTAL_MERCH_COST%TYPE;
   L_new_invc_tot_qty          INVC_HEAD.TOTAL_QTY%TYPE;
   L_new_invc_id               INVC_HEAD.INVC_ID%TYPE;
   L_match_mult_sup_ind        SYSTEM_OPTIONS.INVC_MATCH_MULT_SUP_IND%TYPE;
   L_match_qty_ind             SYSTEM_OPTIONS.INVC_MATCH_QTY_IND%TYPE;
   L_total_rcpt_qty            SHIPSKU.QTY_EXPECTED%TYPE            := NULL;
   L_vdate                     DATE                                 := GET_VDATE;
   L_vat_ind                   SYSTEM_OPTIONS.VAT_IND%TYPE;
   L_vat_region                VAT_ITEM.VAT_REGION%TYPE             := I_vat_region;
   L_vat_code                  VAT_ITEM.VAT_CODE%TYPE               := NULL;
   L_rcpt_vat_rate             VAT_ITEM.VAT_RATE%TYPE               := NULL;
   L_dummy_vat_rate            VAT_ITEM.VAT_RATE%TYPE               := NULL;
   L_order_no                  INVC_XREF.ORDER_NO%TYPE;
   L_invc_date                 INVC_HEAD.INVC_DATE%TYPE;
   L_asn_invc_id               INVC_HEAD.INVC_ID%TYPE;
   L_asn_rcpt_ind              VARCHAR2(1)                          := NULL;
   L_create_id                 INVC_HEAD.CREATE_ID%TYPE             := NULL;
   L_check_tolerances          BOOLEAN;
   L_invc_unit_cost            INVC_DETAIL.INVC_UNIT_COST%TYPE;
   L_invc_qty                  INVC_DETAIL.INVC_QTY%TYPE;
   L_shipsku_qty               SHIPSKU.QTY_RECEIVED%TYPE;
   L_total_cost_excl_vat       INVC_MERCH_VAT.TOTAL_COST_EXCL_VAT%TYPE;
   L_item                      SHIPSKU.ITEM%TYPE;
   L_conv_unit_cost_rec        SHIPSKU.UNIT_COST%TYPE               := 0;
   L_converted_cost_received   SHIPSKU.UNIT_COST%TYPE               := 0;
   L_total_conv_cost_rec       SHIPSKU.UNIT_COST%TYPE               := 0;
   L_seq_no                    INVC_TOLERANCE.SEQ_NO%TYPE;
   L_rowid                     ROWID;
   L_exists                    VARCHAR2(1);
   L_found                     BOOLEAN                             :=FALSE;
   L_primary_addr_type  ADD_TYPE_MODULE.ADDRESS_TYPE%TYPE;

   cursor C_GET_SUPPLIER is
      select oh.supplier
        from ordhead oh, shipment s
       where oh.order_no = s.order_no
         and s.shipment  = I_rcpt;

   cursor C_GET_SUPS_INFO is
      select settlement_code, auto_appr_dbt_memo_ind
        from sups
       where supplier = L_supplier;

   cursor C_INVC_MATCH_IND is
      select ext_invc_match_ind
        from system_options;

   cursor C_MATCH_INVC_EXISTS is
      select 'x'
        from shipsku
       where shipment = I_rcpt
         and match_invc_id is NOT NULL;

   cursor C_GET_MATCH_INVC_ID is
      select distinct match_invc_id
        from shipsku
       where shipment = I_rcpt
         and item     = I_item
         and match_invc_id is NOT NULL;

   cursor C_MATCH_ASN_INVC_EXISTS is
      select 'x'
        from shipsku s,
             invc_head i
       where s.shipment      = I_rcpt
         and s.match_invc_id = i.invc_id
         and i.create_id     = 'ASN_TO_INVC';

   cursor C_GET_ASN_MATCH_INVC_ID is
      select distinct s.match_invc_id
        from shipsku s,
             invc_head i
       where s.shipment      = I_rcpt
         and s.match_invc_id = i.invc_id
         and i.create_id     = 'ASN_TO_INVC';

   cursor C_GET_CREATE_ID is
      select i.create_id
        from invc_head i,
             shipsku s
       where s.shipment      = I_rcpt
         and s.item          = I_item
         and s.match_invc_id = i.invc_id;

   cursor C_INVC_STATUS is
      select status
        from invc_head
       where invc_id = L_rec_match_invc_id;

   cursor C_INVC_UNIT_COST is
      select invc_unit_cost,
             invc_qty
        from invc_detail
       where invc_id = L_rec_match_invc_id
         and item    = I_item;

   cursor C_GET_SHIPSKU_RCV_QTY is
      select SUM(qty_received)
        from shipsku
       where shipment      = I_rcpt
         and item          = I_item
         and match_invc_id = L_rec_match_invc_id;

   cursor C_NEW_TOT_RCPT is
      select SUM(unit_cost * qty_received), SUM(qty_received)
        from shipsku
       where shipment = I_rcpt;

    cursor C_NEW_TOT_INVC is
      select SUM(invc_unit_cost * invc_qty), SUM(invc_qty)
        from invc_detail
       where invc_id = L_tot_invc_id;

   cursor C_CHECK_DETAILS_EXIST is
      select 'x'
        from invc_detail
       where invc_id = L_rec_match_invc_id;

   cursor C_TOTAL_RCPT_QTY is
      select SUM(qty_expected)
        from shipsku
       where shipment = I_rcpt;

   cursor C_ASN_INVC_ID is
      select distinct ih.invc_id
        from invc_head ih,
             shipment s,
             shipsku ssk,
             ordhead oh
       where ((s.asn is NOT NULL
              and ih.ext_ref_no    = s.asn)
          or (s.asn is NULL
              and ih.ext_ref_no    = to_char(s.asn)))
         and s.shipment            = ssk.shipment
         and s.order_no            = oh.order_no
         and oh.supplier           = ih.supplier
         and ih.status            != 'P'
         and s.shipment            = I_rcpt
         and (ssk.match_invc_id is NULL
              or ssk.match_invc_id = ih.invc_id);

   cursor C_LOCK_ASN_INVC_DET is
      select 'x'
        from invc_detail
       where invc_id        = L_asn_invc_id
         and item           = I_item
         and invc_unit_cost = I_old_unit_cost
         for update nowait;

   cursor C_RCPT_INFO is
      select order_no, ship_date
        from shipment
       where shipment = I_rcpt;

   cursor C_RCPT_ITEMS is
      select distinct item
        from shipsku
       where shipment = I_rcpt;

   cursor C_LOCK_MTCH_INVC_DET is
      select 'x'
        from invc_detail
       where invc_id        = L_rec_match_invc_id
         and item           = I_item
         and invc_unit_cost = I_old_unit_cost
         for update nowait;

   cursor C_LOCK_SHIPMENT is
      select 'x'
        from shipment
       where shipment = I_rcpt
         for update nowait;

   cursor C_LOCK_SHIPSKU is
      select 'x'
        from shipsku
       where shipment = I_rcpt
         for update nowait;

   cursor C_LOCK_SHIPSKU_SKU is
      select 'x'
        from shipsku
       where shipment = I_rcpt
         and item     = I_item
         for update nowait;

   cursor C_LOCK_INVC_MERCH_VAT is
      select 'x'
        from invc_merch_vat
       where invc_id  = L_asn_invc_id
         and vat_code = L_vat_code
         for update nowait;

   cursor C_LOCK_INVC_VAT is
      select 'x'
        from invc_merch_vat
       where invc_id  = L_new_invc_id
         and vat_code = L_vat_code
         for update nowait;

   cursor C_LOCK_MERCH_VAT is
      select 'x'
        from invc_merch_vat
       where invc_id  = L_rec_match_invc_id
         and vat_code = L_vat_code
         for update nowait;

   cursor C_ASN_MATCH_INVC_QTY is
      select invc_qty
        from invc_detail
       where invc_id        = L_rec_match_invc_id
         and item           = I_item
         and invc_unit_cost = I_old_unit_cost;

   cursor C_NEW_ASN_TOT_COST_EXCL_VAT is
      select unit_cost * SUM(nvl(qty_expected,0))
        from shipsku
       where shipment = I_rcpt
         and item     = L_item
       group by unit_cost;

   cursor C_RCPT_TOTAL_COST is
      select inx.order_no,
             sk.unit_cost,
             sk.qty_received
        from shipsku sk,
             invc_xref inx,
             shipment sh
       where inx.invc_id           = L_rec_match_invc_id
         and sh.shipment           = inx.shipment
         and sk.shipment           = inx.shipment
         and sh.invc_match_status != 'C'
         and (sk.match_invc_id     = L_rec_match_invc_id
          or sk.match_invc_id is NULL);

   cursor C_INVC_TOTALS is
      select nvl(total_merch_cost,0),
             nvl(total_qty,0)
        from invc_head
       where invc_id = L_rec_match_invc_id;

   cursor C_INVC_TOLERANCE_SEQ_NO is
      select nvl(max(seq_no),0)
        from invc_tolerance
       where invc_id = L_rec_match_invc_id;

   cursor C_INVC_TOLERANCE_EXISTS is
      select rowid
        from invc_tolerance
       where invc_id = L_rec_match_invc_id
         and item    = I_item;

   cursor C_CHECK_ASN is
      select 'x'
        from invc_xref
       where shipment = I_rcpt;

BEGIN

   if I_rcpt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_rcpt',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_item is NOT NULL and I_old_unit_cost is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_old_unit_cost',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_item is NOT NULL
      and (I_new_unit_cost is NULL
           and I_rcv_qty is NULL
           and I_adj_qty is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_new_unit_cost, I_rcv_qty, I_adj_qty',
                                            'all NULL',
                                            'value(s) NOT NULL');
      return FALSE;
   end if;
   ---
   if L_supplier is NULL then
      SQL_LIB.SET_MARK('OPEN', 'C_GET_SUPPLIER', 'ordhead, shipment',
                       'shipment: '||to_char(I_rcpt));
      open C_GET_SUPPLIER;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_GET_SUPPLIER', 'ordhead, shipment',
                       'shipment: '||to_char(I_rcpt));
      fetch C_GET_SUPPLIER into L_supplier;
      ---
      if C_GET_SUPPLIER%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPPLIER', 'ordhead, shipment',
                          'shipment: '||to_char(I_rcpt));
         close C_GET_SUPPLIER;
         ---
         O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_SUPPLIER',
                                                NULL,
                                                NULL,
                                                NULL);
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPPLIER', 'ordhead, shipment',
                       'shipment: '||to_char(I_rcpt));
      close C_GET_SUPPLIER;
   end if;
   ---
   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_GET_SUPS_INFO', 'sups', 'supplier: '||to_char(L_supplier));
   open C_GET_SUPS_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_GET_SUPS_INFO', 'sups', 'supplier: '||to_char(L_supplier));
   fetch C_GET_SUPS_INFO into L_settlement_code,
                              L_auto_appr_dbt_memo;
   ---
   if C_GET_SUPS_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPS_INFO', 'sups', 'supplier: '||to_char(L_supplier));
      close C_GET_SUPS_INFO;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_SUPS_INFO',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPS_INFO', 'sups', 'supplier: '||to_char(L_supplier));
   close C_GET_SUPS_INFO;
   ---
   if ADDRESS_SQL.VALID_INVC_ADDR(O_error_message,
                                  L_found,
                                  I_supplier,
                                  NULL,
                                  NULL)= FALSE then
      return FALSE;
   end if;

   if L_found = FALSE then
      if ADDRESS_SQL.GET_SUPP_PRIMARY_ADDR_TYPE(O_error_message,
                                                L_primary_addr_type) = FALSE then
         return FALSE;
      end if;
   else
      L_primary_addr_type :='05';
   end if;
   if SUPP_ATTRIB_SQL.GET_SUP_PRIMARY_ADDR(O_error_message,
                                           L_addr_key,
                                           L_supplier,
                                           L_primary_addr_type)= FALSE then
      return FALSE;
   end if;
   ---
   if INVC_SQL.INVC_SYSTEM_OPTIONS_INDS(O_error_message,
                                        L_match_mult_sup_ind,
                                        L_match_qty_ind) = FALSE then
      return FALSE;
   end if;

   if I_item is NOT NULL then
      ---
      if (L_settlement_code = 'E'
        and (I_adj_qty is NOT NULL or I_new_unit_cost is NOT NULL)) then
         SQL_LIB.SET_MARK('OPEN','C_GET_CREATE_ID','invc_head, shipsku','Shipment :'||to_char(I_rcpt)||
                                                                         ', Item :'|| I_item);
         open C_GET_CREATE_ID;
         ---
         SQL_LIB.SET_MARK('FETCH','C_GET_CREATE_ID','invc_head, shipsku','Shipment :'||to_char(I_rcpt)||
                                                                         ', Item :'||I_item);
         fetch C_GET_CREATE_ID into L_create_id;
         ---
         if C_GET_CREATE_ID%FOUND then
            if L_create_id != 'ASN_TO_INVC' then
               L_asn_rcpt_ind := 'N';
            else
               L_asn_rcpt_ind := 'Y';
            end if;
         end if;
         ---
         SQL_LIB.SET_MARK('CLOSE','C_GET_CREATE_ID','invc_head, shipsku','Shipment :'||to_char(I_rcpt)||
                                                                         ', Item :'|| I_item);
         close C_GET_CREATE_ID;
      end if;
      ---
      if (L_settlement_code != 'E' or L_asn_rcpt_ind = 'N') then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_INVC_MATCH_IND', 'system_options', NULL);
         open C_INVC_MATCH_IND;
         ---
         SQL_LIB.SET_MARK('FETCH', 'C_INVC_MATCH_IND', 'system_options', NULL);
         fetch C_INVC_MATCH_IND into L_invc_match_ind;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_INVC_MATCH_IND', 'system_options', NULL);
         close C_INVC_MATCH_IND;

         if L_invc_match_ind != 'Y' then
            return TRUE;
         end if;

         -- When a unit cost/qty adjustment is being made to an item, if the supplier's settlement code is
         -- not 'E' and the receipt has been matched to at least one invoice, depending on the status
         -- of those matched invoices, O_posted will return TRUE, the invoice will be unmatched, or the
         -- invoice will be unapproved.

         SQL_LIB.SET_MARK('OPEN', 'C_MATCH_INVC_EXISTS', 'shipsku', 'shipment: '||to_char(I_rcpt));
         open C_MATCH_INVC_EXISTS;
         ---
         SQL_LIB.SET_MARK('FETCH', 'C_MATCH_INVC_EXISTS', 'shipsku', 'shipment: '||to_char(I_rcpt));
         fetch C_MATCH_INVC_EXISTS into L_match_dummy;
         ---
         if C_MATCH_INVC_EXISTS%NOTFOUND then
            SQL_LIB.SET_MARK('CLOSE', 'C_MATCH_INVC_EXISTS', 'shipsku', 'shipment: '||to_char(I_rcpt));
            close C_MATCH_INVC_EXISTS;
            return TRUE;
         end if;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_MATCH_INVC_EXISTS', 'shipsku', 'shipment: '||to_char(I_rcpt));
         close C_MATCH_INVC_EXISTS;

         FOR rec in C_GET_MATCH_INVC_ID LOOP
            L_rec_match_invc_id := rec.match_invc_id;
            ---
            -- Retrieve the last seq_no written to the invc_tolerance table
            SQL_LIB.SET_MARK('OPEN', 'C_INVC_TOLERANCE_SEQ_NO', 'invc_tolerance',
                             'invc_id: '||to_char(L_rec_match_invc_id));
            open C_INVC_TOLERANCE_SEQ_NO;
            ---
            SQL_LIB.SET_MARK('FETCH', 'C_INVC_TOLERANCE_SEQ_NO', 'invc_tolerance',
                             'invc_id: '||to_char(L_rec_match_invc_id));
            fetch C_INVC_TOLERANCE_SEQ_NO into L_seq_no;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_INVC_TOLERANCE_SEQ_NO', 'invc_tolerance',
                             'invc_id: '||to_char(L_rec_match_invc_id));
            close C_INVC_TOLERANCE_SEQ_NO;
            ---
            SQL_LIB.SET_MARK('OPEN', 'C_INVC_STATUS', 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
            open C_INVC_STATUS;
            ---
            SQL_LIB.SET_MARK('FETCH', 'C_INVC_STATUS', 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
            fetch C_INVC_STATUS into L_invc_status;
            ---
            if C_INVC_STATUS%NOTFOUND then
               SQL_LIB.SET_MARK('CLOSE', 'C_INVC_STATUS', 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
               close C_INVC_STATUS;
               ---
               O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_STATUS',
                                                      NULL,
                                                      NULL,
                                                      NULL);
               return FALSE;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_INVC_STATUS', 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
            close C_INVC_STATUS;
            ---
            --- 'P'osted, 'M'atched, pa'R'tially matched, 'A'pproved
            ---
            if L_invc_status = 'P' then
               O_posted := TRUE;
            elsif L_invc_status in ('M','R','A') then
               SQL_LIB.SET_MARK('OPEN',
                                'C_INVC_UNIT_COST',
                                'invc_detail',
                                'invc_id: '||to_char(L_rec_match_invc_id)||
                                ', Item: '|| I_item);
               open C_INVC_UNIT_COST;
               SQL_LIB.SET_MARK('FETCH',
                                'C_INVC_UNIT_COST',
                                'invc_detail',
                                'invc_id: '||to_char(L_rec_match_invc_id)||
                                ', Item: '|| I_item);
               fetch C_INVC_UNIT_COST into L_invc_unit_cost,
                                           L_invc_qty;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_INVC_UNIT_COST',
                                'invc_detail',
                                'invc_id: '||to_char(L_rec_match_invc_id)||
                                ', Item: '|| I_item);
               close C_INVC_UNIT_COST;
               ---
               if L_invc_qty is NOT NULL then
                  if I_adj_qty is not NULL then
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_GET_SHIPSKU_RCV_QTY',
                                      'shipsku',
                                      'shipment: '||to_char(I_rcpt)||
                                      ', Item: '|| I_item);
                     open C_GET_SHIPSKU_RCV_QTY;
                     SQL_LIB.SET_MARK('FETCH',
                                      'C_GET_SHIPSKU_RCV_QTY',
                                      'shipsku',
                                      'shipment: '||to_char(I_rcpt)||
                                      ', Item: '|| I_item);
                     fetch C_GET_SHIPSKU_RCV_QTY into L_shipsku_qty;
                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_GET_SHIPSKU_RCV_QTY',
                                      'shipsku',
                                      'shipment: '||to_char(I_rcpt)||
                                      ', Item: '|| I_item);
                     close C_GET_SHIPSKU_RCV_QTY;
                     ---
                     if INVC_MATCH_SQL.CHECK_TOLERANCE(O_error_message,
                                                       L_check_tolerances,
                                                       L_supplier,
                                                       'LQ',
                                                       L_invc_qty,
                                                       L_shipsku_qty) = FALSE then
                         return FALSE;
                     end if;
                     ---
                     -- If there is a difference between the original and new received
                     -- quantity that is within tolerance, update the invc_tolerance table
                     -- with the total cost difference.
                     if ((L_check_tolerances = TRUE)
                        and (L_invc_qty != L_shipsku_qty)) then
                        SQL_LIB.SET_MARK('OPEN', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', item: '|| I_item);
                        open C_INVC_TOLERANCE_EXISTS;
                        ---
                        SQL_LIB.SET_MARK('FETCH', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', item: '|| I_item);
                        fetch C_INVC_TOLERANCE_EXISTS into L_rowid;
                        ---
                        SQL_LIB.SET_MARK('CLOSE', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', item: '|| I_item);
                        close C_INVC_TOLERANCE_EXISTS;
                        ---
                        if L_rowid is not NULL then
                           SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_tolerance',
                                            'invc_id: '||to_char(L_rec_match_invc_id)||
                                            ', item: '|| I_item);
                           update invc_tolerance
                              set total_cost = total_cost + ((L_invc_qty - L_shipsku_qty) * L_invc_unit_cost)
                            where rowid   = L_rowid
                              and invc_id = L_rec_match_invc_id
                              and item    = I_item;
                        else
                           L_seq_no := L_seq_no + 1;
                           ---
                           SQL_LIB.SET_MARK('INSERT', NULL, 'invc_tolerance',
                                            'invc_id: '||to_char(L_rec_match_invc_id)||
                                            ', item: '|| I_item);
                           insert into invc_tolerance (invc_id,
                                                       seq_no,
                                                       item,
                                                       total_cost)
                              values(L_rec_match_invc_id,
                                     L_seq_no,
                                     I_item,
                                     (L_invc_qty - L_shipsku_qty) * L_invc_unit_cost);
                        end if;
                     end if;
                  elsif I_new_unit_cost is not NULL then
                     if INVC_MATCH_SQL.CHECK_TOLERANCE(O_error_message,
                                                       L_check_tolerances,
                                                       L_supplier,
                                                       'LC',
                                                       L_invc_unit_cost,
                                                       I_new_unit_cost) = FALSE then
                         return FALSE;
                     end if;
                     ---
                     -- If there is a difference between the original and new unit cost
                     -- that is within tolerance, update the invc_tolerance table.
                     if (L_check_tolerances = TRUE)
                        and (L_invc_unit_cost != I_new_unit_cost) then
                        SQL_LIB.SET_MARK('OPEN', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', item: '|| I_item);
                        open C_INVC_TOLERANCE_EXISTS;
                        ---
                        SQL_LIB.SET_MARK('FETCH', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', item: '|| I_item);
                        fetch C_INVC_TOLERANCE_EXISTS into L_rowid;
                        ---
                        SQL_LIB.SET_MARK('CLOSE', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', item: '|| I_item);
                        close C_INVC_TOLERANCE_EXISTS;
                        ---
                        if L_rowid is not NULL then
                           update invc_tolerance
                              set total_cost = total_cost + ((L_invc_unit_cost - I_new_unit_cost) * L_invc_qty)
                            where rowid   = L_rowid
                              and invc_id = L_rec_match_invc_id
                              and item    = I_item;
                        else
                           L_seq_no := L_seq_no + 1;
                           ---
                           SQL_LIB.SET_MARK('INSERT', NULL, 'invc_tolerance',
                                            'invc_id: '||to_char(L_rec_match_invc_id)||
                                            ', item : '|| I_item);
                           insert into invc_tolerance (invc_id,
                                                       seq_no,
                                                       item,
                                                       total_cost)
                              values(L_rec_match_invc_id,
                                     L_seq_no,
                                     I_item,
                                     (L_invc_unit_cost - I_new_unit_cost) * L_invc_qty);
                        end if;
                     end if;
                  end if;
               elsif I_adj_qty is NOT NULL or I_new_unit_cost is NOT NULL then
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_INVC_TOTALS',
                                   'INVC_HEAD',
                                   'INVOICE:'||TO_CHAR(L_rec_match_invc_id));
                  open C_INVC_TOTALS;
                  ---
                  SQL_LIB.SET_MARK('FETCH',
                                   'C_INVC_TOTALS',
                                   'INVC_HEAD',
                                   'INVOICE:'||TO_CHAR(L_rec_match_invc_id));
                  fetch C_INVC_TOTALS into L_new_invc_tot_cost, L_new_invc_tot_qty;

                  if C_INVC_TOTALS%NOTFOUND then
                     O_error_message := SQL_LIB.CREATE_MSG('INV_INVC_ID', NULL, NULL, NULL);
                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_INVC_TOTALS',
                                      'INVC_HEAD',
                                      'INVOICE:'||TO_CHAR(L_rec_match_invc_id));
                     close C_INVC_TOTALS;
                     ---
                     return FALSE;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_INVC_TOTALS',
                                   'INVC_HEAD',
                                   'INVOICE:'||TO_CHAR(L_rec_match_invc_id));
                  close C_INVC_TOTALS;
                  ---
                  FOR rec in C_RCPT_TOTAL_COST LOOP
                     if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                         rec.order_no,
                                                         'O',
                                                         NULL,
                                                         L_rec_match_invc_id,
                                                         'I',
                                                         NULL,
                                                         rec.unit_cost,
                                                         L_conv_unit_cost_rec,
                                                         'C',
                                                         NULL,
                                                         NULL) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     L_converted_cost_received := L_conv_unit_cost_rec * nvl(rec.qty_received,0);
                     L_total_conv_cost_rec := L_total_conv_cost_rec + NVL(L_converted_cost_received,0);
                     L_shipsku_qty := L_shipsku_qty + nvl(rec.qty_received, 0);
                  END LOOP;
                  ---
                  -- compare difference between invoice and receipt total cost
                  if INVC_MATCH_SQL.CHECK_TOLERANCE(O_error_message,
                                                    L_check_tolerances,
                                                    L_supplier,
                                                    'TC',
                                                    L_new_invc_tot_cost,
                                                    L_total_conv_cost_rec) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  -- If there is a difference between the invoice and receipt total cost
                  -- that is within tolerance, write a record to invc_tolerance showing
                  -- the summary difference.
                  if L_check_tolerances = TRUE then
                     SQL_LIB.SET_MARK('DELETE',
                                      NULL,
                                      'INVC_TOLERANCE',
                                      'INVOICE: '||to_char(L_rec_match_invc_id));
                     delete invc_tolerance
                      where invc_id = L_rec_match_invc_id;
                     ---
                     if L_new_invc_tot_cost != L_total_conv_cost_rec then
                        SQL_LIB.SET_MARK('INSERT',
                                         NULL,
                                         'INVC_TOLERANCE',
                                         'INVOICE: '||to_char(L_rec_match_invc_id));

                        insert into invc_tolerance (invc_id,
                                                    seq_no,
                                                    item,
                                                    total_cost)
                           values(L_rec_match_invc_id,
                                  1,
                                  NULL,
                                  L_new_invc_tot_cost - L_total_conv_cost_rec);
                     end if;
                  end if;
                  ---
                  if I_adj_qty is NOT NULL
                    and L_match_qty_ind = 'Y'
                    and L_check_tolerances then
                     if INVC_MATCH_SQL.CHECK_TOLERANCE(O_error_message,
                                                       L_check_tolerances,
                                                       L_supplier,
                                                       'TQ',
                                                       L_new_invc_tot_qty,
                                                       L_shipsku_qty) = FALSE then
                        return FALSE;
                     end if;
                  end if;
               end if;
               ---
               if L_check_tolerances = FALSE then
                  --- 'M'atched, Pa'R'tially Matched
                  if L_invc_status in ('M', 'R') then
                     if INVC_MATCH_SQL.UNMATCH(O_error_message,
                                               L_status,
                                               L_rec_match_invc_id,
                                               I_rcpt,
                                               I_item) = FALSE then
                        return FALSE;
                     end if;
                  --- 'A'pproved
                  elsif L_invc_status = 'A' then
                     if INVC_MATCH_SQL.UNAPPROVE(O_error_message,
                                                 L_rec_match_invc_id,
                                                 TRUE) = FALSE then
                        return FALSE;
                     end if;
                  end if;
               end if;
            end if;
         END LOOP;
      else -- L_settlement_code = 'E' and L_asn_rcpt_ind = 'Y' or L_asn_rcpt_ind is NULL

         -- If the supplier's settlement code is 'E' and a unit cost or quantity adjustment is made,
         -- different code will execute depending on the status of the invoices that are matched
         -- to the receipt/item. If the matched invoice has been posted, a new invoice, equivalent
         -- to WRITE_DBT_CRDT, will be written for the adjustment. If the matched invoice is not
         -- posted, a direct update will occur for the invoice/item on the invc_detail table.

         if (I_adj_qty is NOT NULL
              or (I_old_unit_cost is NOT NULL and I_new_unit_cost is NOT NULL)) then
            ---
            SQL_LIB.SET_MARK('OPEN', 'C_MATCH_ASN_INVC_EXISTS', 'shipsku', 'shipment: '||to_char(I_rcpt));
            open C_MATCH_ASN_INVC_EXISTS;
            ---
            SQL_LIB.SET_MARK('FETCH', 'C_MATCH_ASN_INVC_EXISTS', 'shipsku', 'shipment: '||to_char(I_rcpt));
            fetch C_MATCH_ASN_INVC_EXISTS into L_match_dummy;
            ---
            if C_MATCH_ASN_INVC_EXISTS%NOTFOUND then
               SQL_LIB.SET_MARK('CLOSE', 'C_MATCH_ASN_INVC_EXISTS', 'shipsku', 'shipment: '||to_char(I_rcpt));
               close C_MATCH_ASN_INVC_EXISTS;
               ---
               return TRUE;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_MATCH_ASN_INVC_EXISTS', 'shipsku', 'shipment: '||to_char(I_rcpt));
            close C_MATCH_ASN_INVC_EXISTS;
            ---
            FOR rec in C_GET_ASN_MATCH_INVC_ID LOOP
               L_rec_match_invc_id := rec.match_invc_id;
               ---
               if L_vat_ind = 'Y' then
                  L_vat_code := NULL;
                  ---
                  SQL_LIB.SET_MARK('OPEN', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
                  open C_RCPT_INFO;
                  ---
                  SQL_LIB.SET_MARK('FETCH', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
                  fetch C_RCPT_INFO into L_order_no,
                                         L_invc_date;
                  ---
                  if C_RCPT_INFO%NOTFOUND then
                     SQL_LIB.SET_MARK('CLOSE', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
                     close C_RCPT_INFO;
                     ---
                     O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO',
                                                            NULL,
                                                            NULL,
                                                            NULL);
                      return FALSE;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('CLOSE', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
                  close C_RCPT_INFO;
                  ---
                  if L_vat_region is NULL then
                     if VAT_SQL.GET_VAT_REGION(O_error_message,
                                               L_vat_region,
                                               L_rec_match_invc_id,
                                               L_order_no) = FALSE then
                        return FALSE;
                     end if;
                  end if;
                  ---
                  if L_vat_region is NOT NULL then
                     if VAT_SQL.GET_VAT_RATE(O_error_message,
                                             L_vat_region,
                                             L_vat_code,   --- NULL
                                             L_dummy_vat_rate,
                                             I_item,
                                             NULL,        --- dept
                                             NULL,        --- loc_type
                                             NULL,
                                             L_invc_date,
                                             'C') = FALSE then
                        return FALSE;
                     end if;
                  end if;
                  ---
               end if;
               ---
               SQL_LIB.SET_MARK('OPEN', 'C_INVC_STATUS', 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
               open C_INVC_STATUS;
               ---
               SQL_LIB.SET_MARK('FETCH', 'C_INVC_STATUS', 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
               fetch C_INVC_STATUS into L_invc_status;
               ---
               if C_INVC_STATUS%NOTFOUND then
                  SQL_LIB.SET_MARK('CLOSE', 'C_INVC_STATUS', 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
                  close C_INVC_STATUS;
                  ---
                  O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_STATUS',
                                                         NULL,
                                                         NULL,
                                                         NULL);
                  return FALSE;
               end if;
               ---
               SQL_LIB.SET_MARK('CLOSE', 'C_INVC_STATUS', 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
               close C_INVC_STATUS;
               ---
               if L_invc_status = 'P' then
                  if L_invc_type is NULL then
                     if SUPP_ATTRIB_SQL.DBT_MEMO_CODE(O_error_message,
                                                      L_invc_type,
                                                      L_supplier) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if L_invc_type = 'Y' then
                        L_invc_type := 'D';
                     else
                        L_invc_type := 'R';
                     end if;
                     ---
                  else
                     L_invc_type := I_invc_type;
                  end if;
                  ---
                  if L_invc_type = 'D' and L_auto_appr_dbt_memo = 'N' then
                     L_status := 'M';
                  elsif L_invc_type = 'R' or L_auto_appr_dbt_memo = 'Y' then
                     L_status := 'A';
                  end if;
                  ---
                  if INVC_SQL.NEXT_INVC_ID(O_error_message,
                                           L_new_invc_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('INSERT', NULL, 'invc_head', 'invc_id: '||to_char(L_rec_match_invc_id));
                  insert into invc_head (invc_id,
                                         invc_type,
                                         supplier,
                                         ext_ref_no,
                                         status,
                                         edi_invc_ind,
                                         match_fail_ind,
                                         ref_invc_id,
                                         ref_rtv_order_no,
                                         ref_rsn_code,
                                         terms,
                                         due_date,
                                         payment_method,
                                         terms_dscnt_pct,
                                         terms_dscnt_appl_ind,
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
                                         comments,
                                         edi_sent_ind,
                                         terms_dscnt_appl_non_mrch_ind,
                                         direct_ind,
                                         paid_ind,
                                         addr_key)
                     select L_new_invc_id,
                            L_invc_type,
                            supplier,
                            ext_ref_no,
                            L_status,
                            'N',
                            'N',
                            L_rec_match_invc_id,
                            NULL,
                            NULL,
                            NULL,
                            due_date,
                            payment_method,
                            NULL,
                            'N',
                            NULL,
                            'ASN_TO_INVC',
                            L_vdate,
                            invc_date,
                            'ASN_TO_INVC',
                            L_vdate,
                            DECODE(L_status, 'A', 'ASN_TO_INVC', NULL),
                            DECODE(L_status, 'A', L_vdate, NULL),
                            'N',
                            NULL,
                            NULL,
                            currency_code,
                            exchange_rate,
                            NULL,
                            NULL,
                            NULL,
                            'N',
                            'N',
                            'N',
                            'N',
                            addr_key
                       from invc_head
                      where invc_id = L_rec_match_invc_id;
                  ---
                  if I_new_unit_cost is NOT NULL then
                     if L_vat_ind = 'Y' and L_vat_code is NOT NULL then
                        SQL_LIB.SET_MARK('INSERT', NULL, 'invc_merch_vat',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||', vat code '||L_vat_code);
                        insert into invc_merch_vat(invc_id,
                                                   vat_code,
                                                   total_cost_excl_vat)
                        select L_new_invc_id,
                               L_vat_code,
                               ((id.invc_unit_cost - I_new_unit_cost) * id.invc_qty)
                          from invc_detail id
                         where id.invc_id        = L_rec_match_invc_id
                           and id.item           = I_item
                           and id.invc_unit_cost = I_old_unit_cost;
                     end if; -- L_vat_ind = 'Y'
                     ---
                     SQL_LIB.SET_MARK('INSERT', NULL, 'invc_detail',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||', Item '||
                                       I_item||', invc_unit_cost '||to_char(I_old_unit_cost));
                     insert into invc_detail (invc_id,
                                              item,
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
                        select distinct L_new_invc_id,
                               I_item,
                               id.invc_unit_cost - I_new_unit_cost,
                               id.invc_qty,
                               id.invc_vat_rate,
                               'M',
                               id.invc_unit_cost - I_new_unit_cost,
                               id.invc_qty,
                               id.invc_vat_rate,
                               'Y',
                               'N',
                               'N',
                               'N',
                               NULL
                          from invc_detail id
                         where id.invc_id        = L_rec_match_invc_id
                           and id.item           = I_item
                           and id.invc_unit_cost = I_old_unit_cost;
                   elsif I_adj_qty is NOT NULL then
                     if L_vat_ind = 'Y' and L_vat_code is NOT NULL then
                        SQL_LIB.SET_MARK('INSERT', NULL, 'invc_merch_vat',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||', vat code '||L_vat_code);
                        insert into invc_merch_vat(invc_id,
                                                   vat_code,
                                                   total_cost_excl_vat)
                           values(L_new_invc_id,
                                  L_vat_code,
                                  (I_old_unit_cost * I_adj_qty));
                     end if; -- L_vat_ind = 'Y'

                     SQL_LIB.SET_MARK('INSERT', NULL, 'invc_detail',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||
                                      ', Item: '|| I_item||', invc_unit_cost: '||to_char(I_old_unit_cost));
                     insert into invc_detail (invc_id,
                                              item,
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
                        select distinct L_new_invc_id,
                               I_item,
                               id.invc_unit_cost,
                               I_adj_qty,
                               id.invc_vat_rate,
                               'M',
                               id.invc_unit_cost,
                               I_adj_qty,
                               id.invc_vat_rate,
                               'N',
                               'Y',
                               'N',
                               'N',
                               NULL
                          from invc_detail id
                         where id.invc_id        = L_rec_match_invc_id
                           and id.item           = I_item
                           and id.invc_unit_cost = I_old_unit_cost;
                  end if;
                  ---
                  L_tot_invc_id := L_new_invc_id;
                  ---
                  SQL_LIB.SET_MARK('OPEN', 'C_NEW_TOT_INVC', 'invc_detail', 'invc_id: '||to_char(L_tot_invc_id));
                  open C_NEW_TOT_INVC;
                  ---
                  SQL_LIB.SET_MARK('FETCH', 'C_NEW_TOT_INVC', 'invc_detail', 'invc_id: '||to_char(L_tot_invc_id));
                  fetch C_NEW_TOT_INVC into L_new_invc_tot_cost,
                                            L_new_invc_tot_qty;
                  ---
                  SQL_LIB.SET_MARK('CLOSE', 'C_NEW_TOT_INVC', 'invc_detail', 'invc_id: '||to_char(L_tot_invc_id));
                  close C_NEW_TOT_INVC;
                  ---
                  if L_match_qty_ind != 'Y' then
                     L_new_invc_tot_qty := NULL;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_head', 'invc_id: '||to_char(L_new_invc_id));
                  update invc_head
                     set total_merch_cost = L_new_invc_tot_cost,
                         total_qty = L_new_invc_tot_qty
                   where invc_id = L_new_invc_id;
               else   -- L_status != P
                  if I_new_unit_cost is NOT NULL then
                     if L_vat_ind = 'Y' then
                        SQL_LIB.SET_MARK('OPEN', 'C_ASN_MATCH_INVC_QTY', 'invc_detail',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', Item: '|| I_item||' invc_unit_cost: '||to_char(I_old_unit_cost));
                        open C_ASN_MATCH_INVC_QTY;

                        SQL_LIB.SET_MARK('FETCH', 'C_ASN_MATCH_INVC_QTY', 'invc_detail',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', Item: '|| I_item||' invc_unit_cost: '||to_char(I_old_unit_cost));
                        fetch C_ASN_MATCH_INVC_QTY into L_invc_qty;
                        ---
                        if C_ASN_MATCH_INVC_QTY%NOTFOUND then
                           O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO',
                                                                  NULL,
                                                                  NULL,
                                                                  NULL);
                        SQL_LIB.SET_MARK('CLOSE', 'C_ASN_MATCH_INVC_QTY', 'invc_detail',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', Item: '|| I_item||' invc_unit_cost: '||to_char(I_old_unit_cost));
                           close C_ASN_MATCH_INVC_QTY;
                           return FALSE;
                        end if;
                        ---
                        SQL_LIB.SET_MARK('CLOSE', 'C_ASN_MATCH_INVC_QTY', 'invc_detail',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||
                                         ', Item: '|| I_item||' invc_unit_cost: '||to_char(I_old_unit_cost));
                        close C_ASN_MATCH_INVC_QTY;
                        ---
                        L_table := 'invc_merch_vat';

                        SQL_LIB.SET_MARK('OPEN', 'C_LOCK_MERCH_VAT', 'invc_merch_vat',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||', vat code: '||L_vat_code);
                        open C_LOCK_MERCH_VAT;
                        ---
                        SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_MERCH_VAT', 'invc_merch_vat',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||', vat code: '||L_vat_code);
                        close C_LOCK_MERCH_VAT;
                        ---
                        SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_merch_vat',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||', vat code: '||L_vat_code);
                        update invc_merch_vat
                           set total_cost_excl_vat = total_cost_excl_vat - (I_old_unit_cost * L_invc_qty)
                         where invc_id   = L_rec_match_invc_id
                           and vat_code  = L_vat_code;
                        ---
                        if SQL%FOUND then
                           update invc_merch_vat
                              set total_cost_excl_vat = total_cost_excl_vat + (I_new_unit_cost * L_invc_qty)
                            where invc_id  = L_rec_match_invc_id
                              and vat_code = L_vat_code;
                        end if;
                     end if; -- L_vat_ind = 'Y'
                     ---
                     L_table := 'invc_detail';
                     SQL_LIB.SET_MARK('OPEN', 'C_LOCK_MTCH_INVC_DET', 'invc_detail',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||
                                      ', Item: '|| I_item||', invc_unit_cost: '||to_char(I_old_unit_cost));
                     open C_LOCK_MTCH_INVC_DET;
                     ---
                     SQL_LIB.SET_MARK('FETCH', 'C_LOCK_MTCH_INVC_DET', 'invc_detail',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||
                                      ', Item: '|| I_item||', invc_unit_cost: '||to_char(I_old_unit_cost));
                     close C_LOCK_MTCH_INVC_DET;

                     SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_detail',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||
                                      ', Item: '|| I_item||', invc_unit_cost: '||to_char(I_old_unit_cost));
                     update invc_detail
                        set invc_unit_cost = I_new_unit_cost
                      where invc_id        = L_rec_match_invc_id
                        and item           = I_item
                        and invc_unit_cost = I_old_unit_cost;
                     ---
                     L_tot_invc_id := L_rec_match_invc_id;
                  elsif I_adj_qty is NOT NULL then
                     if L_vat_ind = 'Y' then
                        L_table := 'invc_merch_vat';
                        ---
                        SQL_LIB.SET_MARK('OPEN', 'C_LOCK_MERCH_VAT', 'invc_merch_vat',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||', vat code: '||L_vat_code);
                        open C_LOCK_MERCH_VAT;
                        ---
                        SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_MERCH_VAT', 'invc_merch_vat',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||', vat code: '||L_vat_code);
                        close C_LOCK_MERCH_VAT;
                        ---
                        SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_merch_vat',
                                         'invc_id: '||to_char(L_rec_match_invc_id)||', vat code: '||L_vat_code);
                        update invc_merch_vat
                           set total_cost_excl_vat = total_cost_excl_vat + (I_adj_qty * I_old_unit_cost)
                         where invc_id  = L_rec_match_invc_id
                           and vat_code = L_vat_code;
                     end if; -- L_vat_ind = 'Y'
                     ---
                     L_table := 'invc_detail';
                     SQL_LIB.SET_MARK('OPEN', 'C_LOCK_MTCH_INVC_DET', 'invc_detail',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||
                                      ', Item: '|| I_item||', invc_unit_cost: '||to_char(I_old_unit_cost));
                     open C_LOCK_MTCH_INVC_DET;
                     ---
                     SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_MTCH_INVC_DET', 'invc_detail',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||
                                      ', Item: '|| I_item||', invc_unit_cost: '||to_char(I_old_unit_cost));
                     close C_LOCK_MTCH_INVC_DET;

                     SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_detail',
                                      'invc_id: '||to_char(L_rec_match_invc_id)||
                                      ', Item: '|| I_item||', invc_unit_cost: '||to_char(I_old_unit_cost));
                     update invc_detail
                        set invc_qty = invc_qty + I_adj_qty
                      where invc_id        = L_rec_match_invc_id
                        and item           = I_item
                        and invc_unit_cost = I_old_unit_cost;
                     ---
                     L_tot_invc_id := L_rec_match_invc_id;
                  end if; -- I_adj_qty or I_new_unit_cost is NOT NULL
                  ---
                  SQL_LIB.SET_MARK('OPEN', 'C_NEW_TOT_INVC', 'invc_detail', 'invc_id: '||to_char(L_tot_invc_id));
                  open C_NEW_TOT_INVC;
                  ---
                  SQL_LIB.SET_MARK('FETCH', 'C_NEW_TOT_INVC', 'invc_detail', 'invc_id: '||to_char(L_tot_invc_id));
                  fetch C_NEW_TOT_INVC into L_new_invc_tot_cost,
                                            L_new_invc_tot_qty;
                  ---
                  SQL_LIB.SET_MARK('CLOSE', 'C_NEW_TOT_INVC', 'invc_detail', 'invc_id: '||to_char(L_tot_invc_id));
                  close C_NEW_TOT_INVC;
                  ---
                  if L_match_qty_ind != 'Y' then
                     L_new_invc_tot_qty := NULL;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_head', 'invc_id: '||to_char(L_tot_invc_id));
                  update invc_head
                     set total_merch_cost = L_new_invc_tot_cost,
                         total_qty        = L_new_invc_tot_qty
                   where invc_id = L_tot_invc_id;
                end if;  -- L_status
            END LOOP;
         elsif (I_adj_qty is NULL and I_rcv_qty is NOT NULL) then
            -- When receiving a single item, a check is made to see if the shipment is part of an
            -- ASN that has already been invoiced. If an ASN invoice does exist and the shipment's
            -- supplier is the same as the invoice's supplier, a record will be added to invc_detail
            -- for the item. If an invoice does not exist for the ASN or the ASN's shipment's supplier
            -- is different from the already invoiced ASN, a new header record will be written as
            -- well as a new detail record for the item.

            SQL_LIB.SET_MARK('OPEN', 'C_ASN_INVC_ID', 'invc_head, shipment, shipsku, ordhead',
                             'shipment: '||to_char(I_rcpt));
            open C_ASN_INVC_ID;
            ---
            SQL_LIB.SET_MARK('FETCH', 'C_ASN_INVC_ID', 'invc_head, shipment, shipsku, ordhead',
                             'shipment: '||to_char(I_rcpt));
            fetch C_ASN_INVC_ID into L_asn_invc_id;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_ASN_INVC_ID', 'invc_head, shipment, shipsku, ordhead',
                             'shipment: '||to_char(I_rcpt));
            close C_ASN_INVC_ID;
            ---
            if L_asn_invc_id is NULL then
               ---
                L_invc_type := 'I';

                if INVC_SQL.NEXT_INVC_ID(O_error_message,
                                         L_asn_invc_id) = FALSE then
                   return FALSE;
                end if;
                ---
                SQL_LIB.SET_MARK('INSERT', NULL, 'invc_head', 'shipment: '||to_char(I_rcpt));
                insert into invc_head(invc_id,
                                      invc_type,
                                      supplier,
                                      ext_ref_no,
                                      status,
                                      edi_invc_ind,
                                      match_fail_ind,
                                      ref_invc_id,
                                      ref_rtv_order_no,
                                      ref_rsn_code,
                                      terms,
                                      due_date,
                                      payment_method,
                                      terms_dscnt_pct,
                                      terms_dscnt_appl_ind,
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
                                      comments,
                                      edi_sent_ind,
                                      terms_dscnt_appl_non_mrch_ind,
                                      direct_ind,
                                      paid_ind,
                                      addr_key)
                  select L_asn_invc_id,
                         L_invc_type,
                         L_supplier,
                         NVL(s.asn, I_rcpt),
                         'A',
                         'N',
                         'N',
                         NULL,
                         NULL,
                         NULL,
                         oh.terms,
                         s.ship_date + t.duedays,
                         oh.payment_method,
                         t.percent,
                         'N',
                         oh.freight_terms,
                         'ASN_TO_INVC',
                         L_vdate,
                         s.ship_date,
                         'ASN_TO_INVC',
                         L_vdate,
                         'ASN_TO_INVC',
                         L_vdate,
                         'N',
                         NULL,
                         NULL,
                         oh.currency_code,
                         oh.exchange_rate,
                         NULL,
                         NULL,
                         s.comments,
                         'N',
                         'N',
                         'N',
                         'N',
                         L_addr_key
                    from shipment s,
                         ordhead oh,
                         terms t
                   where s.order_no = oh.order_no
                     and oh.terms   = t.terms
                     and s.shipment = I_rcpt
                group by s.asn, oh.terms, s.ship_date, t.duedays, t.percent, oh.payment_method,
                         oh.freight_terms, oh.currency_code, oh.exchange_rate, s.comments;
            end if; -- if L_asn_invc_id is NULL
            ---
            if L_vat_ind = 'Y' then
               ---
               SQL_LIB.SET_MARK('OPEN', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
               open C_RCPT_INFO;
               ---
               SQL_LIB.SET_MARK('FETCH', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
               fetch C_RCPT_INFO into L_order_no,
                                      L_invc_date;
               ---
               if C_RCPT_INFO%NOTFOUND then
                  SQL_LIB.SET_MARK('CLOSE', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
                  close C_RCPT_INFO;
                  ---
                  O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO',
                                                         NULL,
                                                         NULL,
                                                         NULL);
                  return FALSE;
               end if;
               ---
               SQL_LIB.SET_MARK('CLOSE', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
               close C_RCPT_INFO;
               ---
               if L_vat_region is NULL then
                  if VAT_SQL.GET_VAT_REGION(O_error_message,
                                            L_vat_region,
                                            L_asn_invc_id,
                                            L_order_no) = FALSE then
                     return FALSE;
                  end if;
               end if;
               ---
               if L_vat_region is NOT NULL then
                  if VAT_SQL.GET_VAT_RATE(O_error_message,
                                           L_vat_region,
                                           L_vat_code,   --- NULL
                                           L_rcpt_vat_rate,
                                           I_item,
                                           NULL,        --- dept
                                           NULL,        --- loc_type
                                           NULL,
                                           L_invc_date,
                                           'C') = FALSE then
                     return FALSE;
                  end if;
               end if;
               ---
               L_table := 'invc_merch_vat';

               SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_MERCH_VAT', 'invc_merch_vat',
                                'invc_id: '||to_char(L_asn_invc_id)||', vat code: '||L_vat_code);
               open C_LOCK_INVC_MERCH_VAT;
               ---
               SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_MERCH_VAT', 'invc_merch_vat',
                                'invc_id: '||to_char(L_asn_invc_id)||', vat code: '||L_vat_code);
               close C_LOCK_INVC_MERCH_VAT;
               ---
               SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_merch_vat',
                                'invc_id: '||to_char(L_asn_invc_id)||', vat code: '||L_vat_code);

               update invc_merch_vat
                  set total_cost_excl_vat = total_cost_excl_vat + (I_old_unit_cost * I_rcv_qty)
                where invc_id  = L_asn_invc_id
                  and vat_code = L_vat_code;
               ---
               if SQL%NOTFOUND and L_vat_code is NOT NULL then
                  SQL_LIB.SET_MARK('INSERT', NULL, 'invc_merch_vat', 'invc_id: '||to_char(L_asn_invc_id));
                  ---
                  insert into invc_merch_vat(invc_id,
                                             vat_code,
                                             total_cost_excl_vat)
                     values(L_asn_invc_id,
                            L_vat_code,
                            (I_old_unit_cost * I_rcv_qty));
               end if;
            end if; -- L_vat_ind = 'Y'
            ---
            L_tot_invc_id := L_asn_invc_id;
            ---
            --- Note: Because this invoice is being created as matched and approved there are not
            --- invc_match_wksht records being created.  Invoice detail records are created because
            --- EDI Merchandise Invoices and Docs require them (needed in edidlinv to send to ReIM).
            ---
            SQL_LIB.SET_MARK('INSERT', NULL, 'invc_detail',
                             'invc_id: '||to_char(L_rec_match_invc_id)||
                             ', Item: '|| I_item||', shipment: '||to_char(I_rcpt));

            insert into invc_detail (invc_id,
                                     item,
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
               select distinct L_asn_invc_id,
                      I_item,
                      ss.unit_cost,
                      ss.qty_received,
                      L_rcpt_vat_rate,
                      'M',
                      NULL,
                      NULL,
                      NULL,
                      'N',
                      'N',
                      'N',
                      'Y',
                      NULL
                 from shipsku ss
                where ss.shipment = I_rcpt
                  and ss.item     = I_item;

            SQL_LIB.SET_MARK('OPEN', 'C_NEW_TOT_RCPT', 'shipsku', 'rcpt: '||to_char(I_rcpt));
            open C_NEW_TOT_RCPT;
            ---
            SQL_LIB.SET_MARK('FETCH', 'C_NEW_TOT_RCPT', 'shipsku', 'rcpt: '||to_char(I_rcpt));
            fetch C_NEW_TOT_RCPT into L_new_invc_tot_cost,
                                      L_new_invc_tot_qty;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_NEW_TOT_RCPT', 'shipsku', 'rcpt: '||to_char(I_rcpt));
            close C_NEW_TOT_RCPT;
            ---
            if L_match_qty_ind != 'Y' then
               L_new_invc_tot_qty := NULL;
            end if;
            ---
            SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_head', 'invc_id: '||to_char(L_tot_invc_id));
            update invc_head
               set total_merch_cost = L_new_invc_tot_cost,
                   total_qty        = L_new_invc_tot_qty
             where invc_id = L_tot_invc_id;

            SQL_LIB.SET_MARK('INSERT', NULL, 'invc_xref', 'shipment: '||to_char(I_rcpt));
            insert into invc_xref (invc_id,
                                   order_no,
                                   shipment,
                                   asn,
                                   location,
                                   loc_type,
                                   apply_to_future_ind)
               select L_asn_invc_id,
                      order_no,
                      I_rcpt,
                      asn,
                      to_loc,
                      to_loc_type,
                      'N'
                 from shipment
                where shipment = I_rcpt
                  and not exists (select 'x'
                                    from invc_xref
                                   where invc_id  = L_asn_invc_id
                                     and shipment = I_rcpt);

            L_table := 'SHIPSKU';
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHIPSKU_SKU', 'shipsku', 'shipment: '||
                              to_char(I_rcpt)||', Item: '|| I_item);
            open C_LOCK_SHIPSKU_SKU;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHIPSKU_SKU', 'shipsku', 'shipment: '||
                              to_char(I_rcpt)||', Item: '|| I_item);
            close C_LOCK_SHIPSKU_SKU;
            ---
            SQL_LIB.SET_MARK('UPDATE', NULL, 'shipsku', 'shipment: '||to_char(I_rcpt)||', Item: '|| I_item);
            update shipsku
               set match_invc_id = L_asn_invc_id,
                   qty_matched = I_rcv_qty
             where shipment = I_rcpt
               and item     = I_item;

            if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                        NULL,
                                        I_rcpt,
                                        NULL,
                                        NULL) = FALSE then
               return FALSE;
            end if;
            ---
         end if; -- Values of I_old_unit_cost, I_new_unit_cost, I_rcv_qty, I_adj_qty
         ---
      end if; -- L_settlement_code
   elsif I_item is NULL then
      -- Invoice the entire shipment and its associated items
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_ASN', 'shipment', 'shipment: '||to_char(I_rcpt));
      open C_CHECK_ASN;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_ASN', 'shipment', 'shipment: '||to_char(I_rcpt));
      fetch C_CHECK_ASN into L_exists;
      if C_CHECK_ASN%FOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_ASN', 'shipment', 'shipment: '||to_char(I_rcpt));
         close C_CHECK_ASN;
         return TRUE;
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_ASN', 'shipment', 'shipment: '||to_char(I_rcpt));
      close C_CHECK_ASN;
      ---
      if L_settlement_code != 'E' then
         return TRUE;
      end if;
      ---
      if L_invc_type is NULL then
         L_invc_type := 'I';
      end if;
      ---
      if INVC_SQL.NEXT_INVC_ID(O_error_message,
                               L_new_invc_id) = FALSE then
         return FALSE;
      end if;
      ---
      if L_match_qty_ind = 'Y' then
         SQL_LIB.SET_MARK('OPEN', 'C_TOTAL_RCPT_QTY', 'shipsku', 'shipment: '||to_char(I_rcpt));
         open C_TOTAL_RCPT_QTY;
         ---
         SQL_LIB.SET_MARK('FETCH', 'C_TOTAL_RCPT_QTY', 'shipsku', 'shipment: '||to_char(I_rcpt));
         fetch C_TOTAL_RCPT_QTY into L_total_rcpt_qty;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_TOTAL_RCPT_QTY', 'shipsku', 'shipment: '||to_char(I_rcpt));
         close C_TOTAL_RCPT_QTY;
      end if;
      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'invc_head', 'shipment: '||to_char(I_rcpt));
      insert into invc_head (invc_id,
                             invc_type,
                             supplier,
                             ext_ref_no,
                             status,
                             edi_invc_ind,
                             match_fail_ind,
                             ref_invc_id,
                             ref_rtv_order_no,
                             ref_rsn_code,
                             terms,
                             due_date,
                             payment_method,
                             terms_dscnt_pct,
                             terms_dscnt_appl_ind,
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
                             comments,
                             edi_sent_ind,
                             terms_dscnt_appl_non_mrch_ind,
                             direct_ind,
                             paid_ind,
                             addr_key)
         select L_new_invc_id,
                L_invc_type,
                L_supplier,
                NVL(s.asn, I_rcpt),
                'A',
                'N',
                'N',
                NULL,
                NULL,
                NULL,
                oh.terms,
                s.ship_date + t.duedays,
                oh.payment_method,
                t.percent,
                'N',
                oh.freight_terms,
                'ASN_TO_INVC',
                L_vdate,
                s.ship_date,
                'ASN_TO_INVC',
                L_vdate,
                'ASN_TO_INVC',
                L_vdate,
                'N',
                NULL,
                NULL,
                oh.currency_code,
                oh.exchange_rate,
                SUM(ssk.unit_cost * ssk.qty_expected),
                L_total_rcpt_qty,
                s.comments,
                'N',
                'N',
                'N',
                'N',
                L_addr_key
           from shipment s,
                shipsku ssk,
                ordhead oh,
                terms t
          where s.shipment = ssk.shipment
            and s.order_no = oh.order_no
            and oh.terms   = t.terms
            and s.shipment = I_rcpt
       group by s.asn, oh.terms, s.ship_date, t.duedays, t.percent, oh.payment_method,
                oh.freight_terms, oh.currency_code, oh.exchange_rate, s.comments;
      ---
      if L_vat_ind = 'Y' then
         if L_vat_region is NULL then
            SQL_LIB.SET_MARK('OPEN', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
            open C_RCPT_INFO;
            ---
            SQL_LIB.SET_MARK('FETCH', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
            fetch C_RCPT_INFO into L_order_no,
                                   L_invc_date;
            ---
            if C_RCPT_INFO%NOTFOUND then
               SQL_LIB.SET_MARK('CLOSE', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
               close C_RCPT_INFO;
               ---
               O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO',
                                                      NULL,
                                                      NULL,
                                                      NULL);
               return FALSE;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_RCPT_INFO', 'shipment', 'shipment: '||to_char(I_rcpt));
            close C_RCPT_INFO;
            ---
            if VAT_SQL.GET_VAT_REGION(O_error_message,
                                      L_vat_region,
                                      L_new_invc_id,
                                      L_order_no) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         FOR c_rcpt_items_rec in C_RCPT_ITEMS LOOP
            L_item := c_rcpt_items_rec.item;
            ---
            if L_vat_region is NOT NULL then
               L_vat_code := NULL;
               ---
               if VAT_SQL.GET_VAT_RATE(O_error_message,
                                       L_vat_region,
                                       L_vat_code,   --- NULL
                                       L_rcpt_vat_rate,
                                       c_rcpt_items_rec.item,
                                       NULL,         --- dept
                                       NULL,         --- loc_type
                                       NULL,
                                       L_invc_date,
                                       'C') = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            SQL_LIB.SET_MARK('OPEN', 'C_NEW_ASN_TOT_COST_EXCL_VAT', 'shipsku', 'shipment: '||to_char(I_rcpt)||
                             ', Item :'|| c_rcpt_items_rec.item);
            open C_NEW_ASN_TOT_COST_EXCL_VAT;
            ---
            SQL_LIB.SET_MARK('FETCH', 'C_NEW_ASN_TOT_COST_EXCL_VAT', 'shipsku', 'shipment: '||to_char(I_rcpt)||
                             ', Item :'|| c_rcpt_items_rec.item);
            fetch C_NEW_ASN_TOT_COST_EXCL_VAT into L_total_cost_excl_vat;
            ---
            if C_NEW_ASN_TOT_COST_EXCL_VAT%NOTFOUND then
            SQL_LIB.SET_MARK('CLOSE', 'C_NEW_ASN_TOT_COST_EXCL_VAT', 'shipsku', 'shipment: '||to_char(I_rcpt)||
                             ', Item :'|| c_rcpt_items_rec.item);
               close C_NEW_ASN_TOT_COST_EXCL_VAT;
               O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO',
                                                      NULL,
                                                      NULL,
                                                      NULL);
               return FALSE;
            end if;
            ---
            SQL_LIB.SET_MARK('OPEN', 'C_NEW_ASN_TOT_COST_EXCL_VAT', 'shipsku', 'shipment: '||to_char(I_rcpt)||
                             ', Item :'|| c_rcpt_items_rec.item);
            close C_NEW_ASN_TOT_COST_EXCL_VAT;
            ---
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_VAT', 'invc_merch_vat', 'invc_id : '||to_char(L_new_invc_id)||
                             ', vat code :'||L_vat_code);
            open C_LOCK_INVC_VAT;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_VAT', 'invc_merch_vat', 'invc_id : '||to_char(L_new_invc_id)||
                             ', vat code :'||L_vat_code);
            close C_LOCK_INVC_VAT;
            ---
            SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_merch_vat',
                             'invc_id: '||to_char(L_new_invc_id)||', vat code: '||L_vat_code);
            update invc_merch_vat
               set total_cost_excl_vat = total_cost_excl_vat + L_total_cost_excl_vat
             where invc_id  = L_new_invc_id
               and vat_code = L_vat_code;
            ---
            if SQL%NOTFOUND and L_vat_code is NOT NULL then
               SQL_LIB.SET_MARK('INSERT', NULL, 'invc_merch_vat', 'invc_id : '||to_char(L_new_invc_id)||
                                ', vat code :'||L_vat_code);
               insert into invc_merch_vat(invc_id,
                                          vat_code,
                                          total_cost_excl_vat)
                  values(L_new_invc_id,
                         L_vat_code,
                         L_total_cost_excl_vat);
            end if;
         END LOOP;
      end if; -- L_vat_ind value
      ---
      L_table := 'SHIPMENT';
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHIPMENT', 'shipment', 'shipment: '||to_char(I_rcpt));
      open C_LOCK_SHIPMENT;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHIPMENT', 'shipment', 'shipment: '||to_char(I_rcpt));
      close C_LOCK_SHIPMENT;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'shipment', 'shipment: '||to_char(I_rcpt));
      update shipment
         set invc_match_status = 'M',
             invc_match_date   = L_vdate
       where shipment = I_rcpt;

      L_table := 'SHIPSKU';
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHIPSKU', 'shipsku', 'shipment: '||to_char(I_rcpt));
      open C_LOCK_SHIPSKU;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHIPSKU', 'shipsku', 'shipment: '||to_char(I_rcpt));
      close C_LOCK_SHIPSKU;

      SQL_LIB.SET_MARK('UPDATE', NULL, 'shipsku', 'shipment: '||to_char(I_rcpt));
      update shipsku
         set match_invc_id = L_new_invc_id,
             qty_matched = I_rcv_qty
       where shipment = I_rcpt;

      SQL_LIB.SET_MARK('INSERT', NULL, 'invc_xref', 'shipment: '||to_char(I_rcpt));
      insert into invc_xref (invc_id,
                             order_no,
                             shipment,
                             asn,
                             location,
                             loc_type,
                             apply_to_future_ind)
         select L_new_invc_id,
                order_no,
                I_rcpt,
                asn,
                to_loc,
                to_loc_type,
                'N'
           from shipment
          where shipment = I_rcpt
            and not exists (select 'x'
                              from invc_xref
                             where invc_id = L_asn_invc_id
                               and shipment = I_rcpt);
      ---
   end if; -- I_item value
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_rcpt),
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_WRITE_SQL.ASN_TO_INVC',
                                             to_char(SQLCODE));
      return FALSE;
END ASN_TO_INVC;
-----------------------------------------------------------------------------------------
FUNCTION WRITE_DBT_CRDT(O_error_message   IN OUT   VARCHAR2,
                        I_invc_id         IN       INVC_HEAD.INVC_ID%TYPE,
                        I_invc_type       IN       INVC_HEAD.INVC_TYPE%TYPE,
                        I_user_id         IN       USER_ATTRIB.USER_ID%TYPE,
                        I_ref_rsn_code    IN       INVC_HEAD.REF_RSN_CODE%TYPE,
                        I_supplier        IN       INVC_HEAD.SUPPLIER%TYPE,
                        I_dbt_crdt_id     IN       INVC_HEAD.INVC_ID%TYPE,
                        I_vat_region      IN       VAT_ITEM.VAT_REGION%TYPE)
   RETURN BOOLEAN IS

   L_table                VARCHAR2(30);
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   L_reconciled           BOOLEAN;
   L_match_mult_sup_ind   SYSTEM_OPTIONS.INVC_MATCH_MULT_SUP_IND%TYPE;
   L_match_qty_ind        SYSTEM_OPTIONS.INVC_MATCH_QTY_IND%TYPE;
   L_match                BOOLEAN;
   L_supplier             INVC_HEAD.SUPPLIER%TYPE               := I_supplier;
   L_invc_type            INVC_HEAD.INVC_TYPE%TYPE              := I_invc_type;
   L_ext_ref_no           INVC_HEAD.EXT_REF_NO%TYPE;
   L_auto_appr_dbt_memo   SUPS.AUTO_APPR_DBT_MEMO_IND%TYPE;
   L_status               INVC_HEAD.STATUS%TYPE;
   L_new_invc_id          INVC_HEAD.INVC_ID%TYPE;
   L_vat_ind              SYSTEM_OPTIONS.VAT_IND%TYPE;
   L_vdate                DATE                                  := GET_VDATE;
   L_vat_region           VAT_ITEM.VAT_REGION%TYPE              := I_vat_region;
   L_order_no             INVC_XREF.ORDER_NO%TYPE;
   L_invc_date            INVC_HEAD.INVC_DATE%TYPE;
   L_vat_code             VAT_ITEM.VAT_CODE%TYPE;
   L_vat_rate             VAT_ITEM.VAT_RATE%TYPE;
   L_new_tot_cost         INVC_DETAIL.INVC_UNIT_COST%TYPE;
   L_new_tot_qty          INVC_DETAIL.INVC_QTY%TYPE;
   L_count                NUMBER                                := 0;
   L_item                 INVC_DETAIL.ITEM%TYPE;
   L_cost_dscrpncy_ind    INVC_DETAIL.COST_DSCRPNCY_IND%TYPE;
   L_qty_dscrpncy_ind     INVC_DETAIL.QTY_DSCRPNCY_IND%TYPE;
   L_vat_dscrpncy_ind     INVC_DETAIL.VAT_DSCRPNCY_IND%TYPE;
   L_match_to_qty         INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE;
   L_vat_difference       NUMBER := 0;
   L_exists               VARCHAR2(1);
   L_tot_cost_excl_vat    INVC_MERCH_VAT.TOTAL_COST_EXCL_VAT%TYPE;
   L_rowid                VARCHAR2(30);

   cursor C_GET_SUPPLIER is
      select supplier
        from invc_head
       where invc_id = I_invc_id;

   cursor C_count is
      select count(*)
        from invc_head
       where ref_invc_id = I_invc_id;

   cursor C_GET_AUTO_APPR_DBT_MEMO is
      select auto_appr_dbt_memo_ind
        from sups
       where supplier = L_supplier;

   cursor C_INVC_DATE_AND_ORDER is
      select ih.invc_date, ix.order_no, ih.ext_ref_no
        from invc_head ih,
             invc_xref ix
       where ih.invc_id = ix.invc_id
         and ih.invc_id = I_invc_id;

   cursor C_DBT_CRDT_INFO is
      select id.item,
             id.invc_qty,
             id.invc_unit_cost,
             id.invc_vat_rate,
             id.cost_dscrpncy_ind,
             id.qty_dscrpncy_ind,
             id.vat_dscrpncy_ind,
             imw.invc_unit_cost imw_unit_cost,
             imw.match_to_cost,
             SUM(imw.match_to_qty) match_to_qty,
             sh.to_loc,
             sh.to_loc_type
        from invc_detail      id,
             invc_match_wksht imw,
             shipsku          ssk,
             shipment         sh
       where id.invc_id         = I_invc_id
         and id.invc_id         = imw.invc_id
         and id.item            = imw.item
         and id.invc_unit_cost  = imw.invc_unit_cost
         and imw.shipment       = ssk.shipment
         and ssk.shipment       = sh.shipment
         and imw.item           = ssk.item
         and (imw.carton        = ssk.carton
              or imw.carton is NULL and ssk.carton is NULL)
         and ssk.match_invc_id is NULL
    group by id.item,
             id.invc_qty,
             id.invc_unit_cost,
             id.invc_vat_rate,
             id.cost_dscrpncy_ind,
             id.qty_dscrpncy_ind,
             id.vat_dscrpncy_ind,
             imw.invc_unit_cost,
             imw.match_to_cost,
             sh.to_loc,
             sh.to_loc_type;

   cursor C_NEW_INVC_TOT_INFO is
      select NVL(SUM(invc_unit_cost * invc_qty), 0), NVL(SUM(invc_qty), 0)
        from invc_detail
       where invc_id = NVL(I_dbt_crdt_id, L_new_invc_id);

   cursor C_SHIPMENTS is
      select distinct ssk.shipment
        from invc_detail id,
             shipsku ssk,
             invc_match_wksht imw
       where id.invc_id         = I_invc_id
         and id.invc_id         = imw.invc_id
         and id.item            = imw.item
         and id.invc_unit_cost  = imw.invc_unit_cost
         and imw.item           = ssk.item
         and imw.shipment       = ssk.shipment
         and (imw.carton        = ssk.carton
              or imw.carton is NULL and ssk.carton is NULL)
         and (ssk.match_invc_id = I_invc_id
              or ssk.match_invc_id is NULL);

   cursor C_LOCK_INVC_HEAD is
      select 'x'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_INVC_DETAIL is
      select 'x'
        from invc_detail
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_SHIPSKU is
      select 'x'
        from shipsku ssk
       where exists (select 'x'
                       from invc_detail id,
                            invc_match_wksht imw
                      where id.invc_id        = imw.invc_id
                        and id.item           = imw.item
                        and id.invc_unit_cost = imw.invc_unit_cost
                        and imw.shipment      = ssk.shipment
                        and imw.item          = ssk.item
                        and (imw.carton       = ssk.carton
                             or imw.carton is NULL and ssk.carton is NULL)
                        and id.invc_id        = I_invc_id)
         and ssk.match_invc_id is NULL
         for update nowait;

   cursor C_CHECK_DETAILS is
      select 'x'
        from invc_detail
       where invc_id = I_invc_id;

   cursor C_MERCH_VAT_EXISTS is
      select 'x'
        from invc_merch_vat
       where invc_id  = NVL(I_dbt_crdt_id, L_new_invc_id)
         and vat_code = L_vat_code
         and rownum   = 1;

   cursor C_MERCH_VAT_HEADER is
      select v.vat_code
        from vat_code_rates v
       where v.vat_rate     = L_vat_rate
         and v.active_date <= L_invc_date
         and exists (select 'x'
                       from invc_merch_vat i
                      where i.invc_id  = I_invc_id
                        and i.vat_code = v.vat_code
                        and rownum     = 1);

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_user_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if INVC_SQL.INVC_SYSTEM_OPTIONS_INDS(O_error_message,
                                        L_match_mult_sup_ind,
                                        L_match_qty_ind) = FALSE then
      return FALSE;
   end if;
   ---
   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   if L_supplier is NULL then
      SQL_LIB.SET_MARK('OPEN', 'C_GET_SUPPLIER', 'invc_head', 'invc_id: '||to_char(I_invc_id));
      open C_GET_SUPPLIER;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_GET_SUPPLIER', 'invc_head', 'invc_id: '||to_char(I_invc_id));
      fetch C_GET_SUPPLIER into L_supplier;
      ---
      if C_GET_SUPPLIER%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPPLIER', 'invc_head', 'invc_id: '||to_char(I_invc_id));
         close C_GET_SUPPLIER;
         ---
         O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_SUPPLIER',
                                                NULL,
                                                NULL,
                                                NULL);
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPPLIER', 'invc_head', 'invc_id: '||to_char(I_invc_id));
      close C_GET_SUPPLIER;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_INVC_DATE_AND_ORDER', 'invc_head, invc_xref', 'invc_id: '||to_char(I_invc_id));
   open C_INVC_DATE_AND_ORDER;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_INVC_DATE_AND_ORDER', 'invc_head, invc_xref', 'invc_id: '||to_char(I_invc_id));
   fetch C_INVC_DATE_AND_ORDER into L_invc_date,
                                    L_order_no,
                                    L_ext_ref_no;
   ---
   if C_INVC_DATE_AND_ORDER%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_INVC_DATE_AND_ORDER', 'invc_head, invc_xref', 'invc_id: '||to_char(I_invc_id));
      close C_INVC_DATE_AND_ORDER;
            ---
      O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO',
                                                   NULL,
                                                   NULL,
                                                   NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_INVC_DATE_AND_ORDER', 'invc_head, invc_xref', 'invc_id: '||to_char(I_invc_id));
   close C_INVC_DATE_AND_ORDER;
   ---
   if I_dbt_crdt_id is NULL then
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_DETAILS', 'invc_head', 'invc_id: '||to_char(I_invc_id));
      open C_CHECK_DETAILS;
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_DETAILS', 'invc_head', 'invc_id: '||to_char(I_invc_id));
      fetch C_CHECK_DETAILS into L_exists;
      ---
      if C_CHECK_DETAILS%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_DETAILS', 'invc_head', 'invc_id: '||to_char(I_invc_id));
         close C_CHECK_DETAILS;
         ---
         if INVC_MATCH_SQL.CHECK_VAT(O_error_message,
                                     L_reconciled,
                                     I_invc_id,
                                     L_supplier) = FALSE then
            return FALSE;
         end if;
      else
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_DETAILS', 'invc_head', 'invc_id: '||to_char(I_invc_id));
         close C_CHECK_DETAILS;
         ---
         if INVC_MATCH_SQL.CHECK_DETAILS(O_error_message,
                                         L_reconciled,
                                         I_invc_id) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      if L_reconciled = FALSE then
         return FALSE;
      end if;
      ---
       if L_vat_ind = 'Y' then
         if L_vat_region is NULL then
            if VAT_SQL.GET_VAT_REGION(O_error_message,
                                      L_vat_region,
                                      I_invc_id,
                                      L_order_no) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      ---
      if INVC_MATCH_SQL.ITEM_MATCH_ALL(O_error_message,
                                       L_match,
                                       L_reconciled,
                                       I_invc_id,
                                       I_user_id,
                                       L_supplier,
                                       L_vat_region) = FALSE then
         return FALSE;
      end if;
      ---
      if L_match = TRUE and L_reconciled = TRUE then
         return TRUE;
      end if;
      ---
      if INVC_SQL.NEXT_INVC_ID(O_error_message,
                               L_new_invc_id) = FALSE then
         return FALSE;
      end if;
   end if;  -- if I_dbt_crdt_id is NULL
   ---
   if L_invc_type is NULL then
      if SUPP_ATTRIB_SQL.DBT_MEMO_CODE(O_error_message,
                                       L_invc_type,
                                       L_supplier) = FALSE then
         return FALSE;
      end if;
      ---
      if L_invc_type = 'Y' then
         L_invc_type := 'D';
      else
         L_invc_type := 'R';
      end if;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_GET_AUTO_APPR_DBT_MEMO', 'supplier', 'supplier: '||to_char(L_supplier));
   open C_GET_AUTO_APPR_DBT_MEMO;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_GET_AUTO_APPR_DBT_MEMO', 'supplier', 'supplier: '||to_char(L_supplier));
   fetch C_GET_AUTO_APPR_DBT_MEMO into L_auto_appr_dbt_memo;
   ---
   if C_GET_AUTO_APPR_DBT_MEMO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_AUTO_APPR_DBT_MEMO', 'supplier', 'supplier: '||to_char(L_supplier));
      close C_GET_AUTO_APPR_DBT_MEMO;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_AUTO_APP_DBT_MEMO',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_AUTO_APPR_DBT_MEMO', 'supplier', 'supplier: '||to_char(L_supplier));
   close C_GET_AUTO_APPR_DBT_MEMO;
   ---
   if ((L_invc_type = 'D' or L_invc_type = 'M') and L_auto_appr_dbt_memo = 'N') or L_invc_type = 'C' then
      L_status := 'M';
   elsif L_invc_type = 'R' or L_auto_appr_dbt_memo = 'Y' then
      L_status := 'A';
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_COUNT', 'invc_head', 'ref_invc_id: '||to_char(I_invc_id));
   open C_COUNT;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_COUNT', 'invc_head', 'ref_invc_id: '||to_char(I_invc_id));
   fetch C_COUNT into L_count;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_COUNT', 'invc_head', 'ref_invc_id: '||to_char(I_invc_id));
   close C_COUNT;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'invc_head', 'invc_id: '||to_char(I_invc_id));
   insert into invc_head (invc_id,
                          invc_type,
                          supplier,
                          ext_ref_no,
                          status,
                          edi_invc_ind,
                          match_fail_ind,
                          ref_invc_id,
                          ref_rtv_order_no,
                          ref_rsn_code,
                          terms,
                          due_date,
                          payment_method,
                          terms_dscnt_pct,
                          terms_dscnt_appl_ind,
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
                          comments,
                          edi_sent_ind,
                          terms_dscnt_appl_non_mrch_ind,
                          direct_ind,
                          paid_ind,
                          addr_key)
      select NVL(I_dbt_crdt_id, L_new_invc_id),
             L_invc_type,
             supplier,
             L_ext_ref_no,
             L_status,
             edi_invc_ind,
             'N',
             I_invc_id,
             NULL,
             I_ref_rsn_code,
             terms,
             due_date,
             payment_method,
             terms_dscnt_pct,
             terms_dscnt_appl_ind,
             NULL,
             I_user_id,
             L_vdate,
             invc_date,
             I_user_id,
             L_vdate,
             DECODE(L_status, 'A', I_user_id, NULL),
             DECODE(L_status, 'A', L_vdate, NULL),
             'N',
             NULL,
             NULL,
             currency_code,
             exchange_rate,
             NULL,
             NULL,
             NULL,
             'N',
             'N',
             'N',
             'N',
             addr_key
        from invc_head
       where invc_id = I_invc_id;
   ---
   for rec in C_DBT_CRDT_INFO loop
      L_item               := rec.item;
      L_cost_dscrpncy_ind  := rec.cost_dscrpncy_ind;
      L_qty_dscrpncy_ind   := rec.qty_dscrpncy_ind;
      L_vat_dscrpncy_ind   := rec.vat_dscrpncy_ind;
      L_vat_rate           := rec.invc_vat_rate;
      L_vat_difference     := 0;
      L_match_to_qty       := rec.match_to_qty;
      L_tot_cost_excl_vat  := NULL;

      SQL_LIB.SET_MARK('OPEN',
                       'C_MERCH_VAT_HEADER',
                       'vat_code_rates',
                       'invc_id: '|| to_char(I_invc_id));
      open C_MERCH_VAT_HEADER;

      SQL_LIB.SET_MARK('FETCH',
                       'C_MERCH_VAT_HEADER',
                       'vat_code_rates',
                       'invc_id: '|| to_char(I_invc_id));
      fetch C_MERCH_VAT_HEADER into L_vat_code;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_MERCH_VAT_HEADER',
                       'vat_code_rates',
                       'invc_id: '|| to_char(I_invc_id));
      close C_MERCH_VAT_HEADER;

      if L_vat_code is NULL then
         O_error_message := 'INV_RATE_MISMATCH';
         return FALSE;
      end if;

      --- Cost, quantity, or VAT discrepancies exist.
      if (rec.cost_dscrpncy_ind = 'Y') or
         (rec.qty_dscrpncy_ind  = 'Y') or
         (rec.vat_dscrpncy_ind  = 'Y') then

         --- If the invoice quantity is not equal to the total quantity from the worksheet
         --- for this invc/item/indicators, then create record for unit_cost times qty difference.
         if rec.invc_qty != L_match_to_qty then
            insert into invc_detail
                  ( invc_id,
                    item,
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
            values( NVL(I_dbt_crdt_id, L_new_invc_id),
                    rec.item,
                    rec.imw_unit_cost,
                    (rec.invc_qty - L_match_to_qty),
                    rec.invc_vat_rate,
                    'M',
                    rec.imw_unit_cost,
                    (rec.invc_qty - L_match_to_qty),
                    rec.invc_vat_rate,
                    rec.cost_dscrpncy_ind,
                    rec.qty_dscrpncy_ind,
                    rec.vat_dscrpncy_ind,
                    'N',
                    NULL);

            L_tot_cost_excl_vat := (rec.imw_unit_cost * (rec.invc_qty - L_match_to_qty));

            SQL_LIB.SET_MARK('OPEN',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
            open C_MERCH_VAT_EXISTS;

            SQL_LIB.SET_MARK('FETCH',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
            fetch C_MERCH_VAT_EXISTS into L_exists;

            SQL_LIB.SET_MARK('CLOSE',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
            close C_MERCH_VAT_EXISTS;

            if L_exists is NULL then
               insert into invc_merch_vat
                      (invc_id,
                       vat_code,
                       total_cost_excl_vat)
               values (NVL(I_dbt_crdt_id, L_new_invc_id),
                       L_vat_code,
                       L_tot_cost_excl_vat);
            else
               update invc_merch_vat
                  set total_cost_excl_vat = total_cost_excl_vat + L_tot_cost_excl_vat
                where rowid = L_rowid;
            end if;


            -- If there is a discrepancy in the invoice and receipt qty, this would cause a
            -- discrepancy in the vat amount if the invoice vat rate > 0.
            if rec.invc_vat_rate > 0 and rec.vat_dscrpncy_ind != 'Y' then
               L_vat_difference := ((rec.invc_qty - L_match_to_qty) * rec.imw_unit_cost * rec.invc_vat_rate)/100;
                  -- Create record on invc_detail_vat for vat difference as a result of qty difference.
                  insert into invc_detail_vat (invc_id,
                                               item,
                                               invc_unit_cost,
                                               vat_cost)
                                       values (NVL(I_dbt_crdt_id, L_new_invc_id),
                                               rec.item,
                                               rec.imw_unit_cost,
                                               L_vat_difference);
            end if; -- qty discrepancy, no vat discrepancy
         end if; -- rec.invc_qty != L_match_to_qty
         --- If the invoice_unit_cost is not equal to the match_to_cost from the worksheet then
         --- create record for unit_cost difference times order qty (match_to_qty).
         if rec.imw_unit_cost != rec.match_to_cost then
            insert into invc_detail
                  ( invc_id,
                    item,
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
            values( NVL(I_dbt_crdt_id, L_new_invc_id),
                    rec.item,
                    (rec.imw_unit_cost - rec.match_to_cost),
                    rec.match_to_qty,
                    rec.invc_vat_rate,
                    'M',
                    (rec.imw_unit_cost - rec.match_to_cost),
                    rec.match_to_qty,
                    rec.invc_vat_rate,
                    rec.cost_dscrpncy_ind,
                    rec.qty_dscrpncy_ind,
                    'Y',
                    'N',
                    NULL);

            L_tot_cost_excl_vat := ((rec.imw_unit_cost - rec.match_to_cost) * rec.match_to_qty);

            SQL_LIB.SET_MARK('OPEN',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
            open C_MERCH_VAT_EXISTS;

            SQL_LIB.SET_MARK('FETCH',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
            fetch C_MERCH_VAT_EXISTS into L_exists;

            SQL_LIB.SET_MARK('CLOSE',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
            close C_MERCH_VAT_EXISTS;

            if L_exists is NULL then
               insert into invc_merch_vat
                      (invc_id,
                       vat_code,
                       total_cost_excl_vat)
               values (NVL(I_dbt_crdt_id, L_new_invc_id),
                       L_vat_code,
                       L_tot_cost_excl_vat);
            else
               update invc_merch_vat
                  set total_cost_excl_vat = total_cost_excl_vat + L_tot_cost_excl_vat
                where rowid = L_rowid;
            end if;

         end if; -- rec.invc_unit_cost != rec.imw_unit_cost
         --- If there is a VAT discrepancy we need to add a record to make up the VAT difference.
         --- This record will go on invc_detail_vat as the vat_cost.
         if (rec.vat_dscrpncy_ind = 'Y' and rec.invc_vat_rate > 0) then
            --- Get the correct vat rate and code.
            L_vat_rate           := NULL;
            L_vat_code           := NULL;
            ---
            if VAT_SQL.GET_VAT_RATE(O_error_message,   ---    OUT
                                    L_vat_region,      --- IN OUT
                                    L_vat_code,        --- IN OUT (NULL)
                                    L_vat_rate,        ---    OUT (NULL)
                                    rec.item,          --- IN     item
                                    NULL,              --- IN     dept
                                    rec.to_loc_type,   --- IN     loc_type
                                    rec.to_loc,        --- IN     location
                                    L_invc_date,       --- IN     date
                                    'C') = FALSE then  --- IN     vat_type
               return FALSE;
            end if; -- GET_VAT_RATE
            --- Calculate the total vat that has not been accounted for in the above calculations.
            --- This is the order qty * order cost * difference between order and invoice vat rates.
            L_vat_difference := ((rec.invc_qty * rec.imw_unit_cost * rec.invc_vat_rate)
                                  - (L_match_to_qty * rec.match_to_cost * L_vat_rate))/100;
            --- Create record on invc_detail_vat for vat discrepancy.
            insert into invc_detail_vat (invc_id,
                                         item,
                                         invc_unit_cost,
                                         vat_cost)
                                 values (NVL(I_dbt_crdt_id, L_new_invc_id),
                                         rec.item,
                                         rec.imw_unit_cost,
                                         L_vat_difference);
         end if;  -- rec.vat_dscrpncy_ind = 'Y'
      end if;   -- rec.cost/qty/vat_dscrpncy_ind = 'Y'
   END LOOP;  -- for rec in C_DBT_CRDT_INFO loop

   --- If I_dbt_crdt_id is NULL and there are no corresponding records on invc_match_wksht
   --- table then write a credit for the invoice_unit_cost times the invc_quantity.
   insert into invc_detail
         ( invc_id,
           item,
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
    select NVL(I_dbt_crdt_id, L_new_invc_id),
           item,
           id.invc_unit_cost,
           id.invc_qty,
           id.invc_vat_rate,
           'M',
           id.invc_unit_cost,
           id.invc_qty,
           id.invc_vat_rate,
           'Y',
           'Y',
           L_vat_ind,
           'N',
           NULL
      from invc_detail id
     where id.invc_id = I_invc_id
       and not exists (select 'x'
                         from invc_match_wksht imw
                        where imw.invc_id        = I_invc_id
                          and imw.invc_id        = id.invc_id
                          and imw.item           = id.item
                          and imw.invc_unit_cost = id.invc_unit_cost);
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_NEW_INVC_TOT_INFO', 'invc_detail', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   open C_NEW_INVC_TOT_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_NEW_INVC_TOT_INFO', 'invc_detail', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   fetch C_NEW_INVC_TOT_INFO into L_new_tot_cost, L_new_tot_qty;
   ---
   if C_NEW_INVC_TOT_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_NEW_INVC_TOT_INFO', 'invc_detail', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
      close C_NEW_INVC_TOT_INFO;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_COST_QTY_INFO',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_NEW_INVC_TOT_INFO', 'invc_detail', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   close C_NEW_INVC_TOT_INFO;
   ---
   if L_match_qty_ind = 'N' then
      L_new_tot_qty := NULL;
   end if;
   ---
   L_table := 'INVC_HEAD';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(I_invc_id));
   open C_LOCK_INVC_HEAD;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(I_invc_id));
   close C_LOCK_INVC_HEAD;
   ---
   SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_head', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   update invc_head
      set total_merch_cost = L_new_tot_cost,
          total_qty        = L_new_tot_qty
    where invc_id = NVL(I_dbt_crdt_id, L_new_invc_id);
   ---
   L_table := 'INVC_DETAIL';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_DETAIL', 'invc_detail', 'invc_id: '||to_char(I_invc_id));
   open C_LOCK_INVC_DETAIL;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_DETAIL', 'invc_detail', 'invc_id: '||to_char(I_invc_id));
   close C_LOCK_INVC_DETAIL;
   ---
   SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_detail', 'invc_id: '||to_char(I_invc_id));
   update invc_detail
      set status = 'M'
    where invc_id = I_invc_id;
   ---
   L_table := 'SHIPSKU';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHIPSKU', 'invc_detail, invc_match_wksht, shipsku', 'invc_id: '||to_char(I_invc_id));
   open C_LOCK_SHIPSKU;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHIPSKU', 'invc_detail, invc_match_wksht, shipsku', 'invc_id: '||to_char(I_invc_id));
   close C_LOCK_SHIPSKU;
   ---
   SQL_LIB.SET_MARK('UPDATE', NULL, 'shipsku, invc_detail, invc_match_wksht, shipsku', 'invc_id: '||to_char(I_invc_id));
   update shipsku ssk
      set ssk.match_invc_id = I_invc_id
    where exists (select 'x'
                    from invc_detail id, invc_match_wksht imw
                   where id.invc_id        = imw.invc_id
                     and id.item           = imw.item
                     and id.invc_unit_cost = imw.invc_unit_cost
                     and imw.shipment      = ssk.shipment
                     and imw.item          = ssk.item
                     and (imw.carton       = ssk.carton
                          or imw.carton is NULL and ssk.carton is NULL)
                     and id.invc_id        = I_invc_id)
      and ssk.match_invc_id is NULL;
   ---
   if INVC_SQL.UPDATE_STATUSES(O_error_message,
                               I_invc_id,
                               NULL,
                               I_user_id,
                               L_supplier) = FALSE then
      return FALSE;
   end if;
   ---
   FOR rec in C_SHIPMENTS LOOP
      if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                  NULL,
                                  rec.shipment,
                                  I_user_id,
                                  L_supplier) = FALSE then
         return FALSE;
      end if;
   END LOOP;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_invc_id),
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_WRITE_SQL.WRITE_DBT_CRDT',
                                            to_char(SQLCODE));
      return FALSE;
END WRITE_DBT_CRDT;
-----------------------------------------------------------------------------------------
FUNCTION WRITE_RTV_DBT_CRDT(O_error_message   IN OUT   VARCHAR2,
                            I_rtv_order_no    IN       RTV_HEAD.RTV_ORDER_NO%TYPE,
                            I_invc_type       IN       INVC_HEAD.INVC_TYPE%TYPE,
                            I_user_id         IN       USER_ATTRIB.USER_ID%TYPE,
                            I_ref_rsn_code    IN       INVC_HEAD.REF_RSN_CODE%TYPE,
                            I_supplier        IN       RTV_HEAD.SUPPLIER%TYPE,
                            I_dbt_crdt_id     IN       INVC_HEAD.INVC_ID%TYPE)
   RETURN BOOLEAN IS

   L_table                VARCHAR2(30);
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   L_supplier             RTV_HEAD.SUPPLIER%TYPE       := I_supplier;
   L_invc_type            INVC_HEAD.INVC_TYPE%TYPE     := I_invc_type;
   L_new_invc_id          INVC_HEAD.INVC_ID%TYPE;
   L_auto_appr_dbt_memo   SUPS.AUTO_APPR_DBT_MEMO_IND%TYPE;
   L_payment_method       SUPS.PAYMENT_METHOD%TYPE;
   L_currency_code        SUPS.CURRENCY_CODE%TYPE;
   L_status               INVC_HEAD.STATUS%TYPE;
   L_addr_key             INVC_HEAD.ADDR_KEY%TYPE;
   L_vdate                DATE                         := GET_VDATE;
   L_new_tot_cost         INVC_DETAIL.INVC_UNIT_COST%TYPE;
   L_new_tot_qty          INVC_DETAIL.INVC_QTY%TYPE;
   L_match_mult_sup_ind   SYSTEM_OPTIONS.INVC_MATCH_MULT_SUP_IND%TYPE;
   L_match_qty_ind        SYSTEM_OPTIONS.INVC_MATCH_QTY_IND%TYPE;
   L_vat_ind              SYSTEM_OPTIONS.VAT_IND%TYPE;
   L_vat_region           VAT_ITEM.VAT_REGION%TYPE;
   L_vat_code             VAT_ITEM.VAT_CODE%TYPE;
   L_vat_rate             VAT_ITEM.VAT_RATE%TYPE;
   L_old_item             RTV_DETAIL.ITEM%TYPE   := -1;
   L_item                 RTV_DETAIL.ITEM%TYPE;
   L_unit_cost            RTV_DETAIL.UNIT_COST%TYPE;
   L_qty                  RTV_DETAIL.QTY_RETURNED%TYPE;
   L_non_merch_code_desc  NON_MERCH_CODE_HEAD.NON_MERCH_CODE_DESC%TYPE;
   L_service_ind          NON_MERCH_CODE_HEAD.SERVICE_IND%TYPE;
   L_non_merch_amt        INVC_NON_MERCH.NON_MERCH_AMT%TYPE;
   L_restock_pct          RTV_HEAD.RESTOCK_PCT%TYPE;
   L_non_merch_code       NON_MERCH_CODE_HEAD.NON_MERCH_CODE%TYPE;
   L_rh_supplier          RTV_HEAD.SUPPLIER%TYPE;
   L_ret_auth_num         RTV_HEAD.RET_AUTH_NUM%TYPE;
   L_created_date         RTV_HEAD.CREATED_DATE%TYPE;
   L_courier              RTV_HEAD.COURIER%TYPE;
   L_store                RTV_HEAD.STORE%TYPE;
   L_existing_status      INVC_HEAD.STATUS%TYPE := NULL;
   L_existing_id          INVC_HEAD.INVC_ID%TYPE := NULL;
   L_rowid                VARCHAR2(30);
   L_rtv_store            RTV_HEAD.STORE%TYPE;
   L_rtv_wh               RTV_HEAD.WH%TYPE;
   L_location             RTV_HEAD.STORE%TYPE;
   L_loc_type             ITEM_LOC.LOC_TYPE%TYPE;

   cursor C_CHECK_EXISTANCE is
      select invc_id,
             status
        from invc_head
       where ref_rtv_order_no = I_rtv_order_no;

   cursor C_GET_SUPPLIER is
      select supplier,
             store
        from rtv_head
       where rtv_order_no = I_rtv_order_no;

   cursor C_GET_SUPS_INFO is
      select auto_appr_dbt_memo_ind,
             payment_method,
             currency_code,
             NVL(vat_region, -1)
        from sups
       where supplier = L_supplier;

   cursor C_NEW_INVC_TOT_INFO is
      select SUM(invc_unit_cost * invc_qty), SUM(invc_qty)
        from invc_detail
       where invc_id = NVL(I_dbt_crdt_id, L_new_invc_id);

   cursor C_LOCK_INVC_HEAD is
      select 'x'
        from invc_head
       where invc_id = NVL(I_dbt_crdt_id, L_new_invc_id)
         for update nowait;

   cursor C_RTV_DETAIL is
      select distinct item,
             unit_cost - ((NVL(restock_pct, 0)/100) * unit_cost) unit_cost,
             SUM(qty_returned) qty
        from rtv_detail rd
       where rtv_order_no = I_rtv_order_no
         and NVL(qty_returned, 0) != 0
         and not exists (select 'x'
                           from invc_detail id, invc_head ih
                          where id.invc_id = ih.invc_id
                            and ih.status = 'P'
                            and ih.ref_rtv_order_no = I_rtv_order_no
                            and id.item = rd.item)
      group by item, unit_cost - ((NVL(restock_pct, 0)/100) * unit_cost);

   cursor C_GET_NON_MERCH_CODE_DETAILS is
      select non_merch_code_desc,
             service_ind
        from non_merch_code_head
       where non_merch_code = 'M';

   cursor C_MERCH_VAT_EXISTS is
      select rowid
        from invc_merch_vat
       where invc_id  = NVL(I_dbt_crdt_id, L_new_invc_id)
         and vat_code = L_vat_code;

   cursor C_GET_RTV_LOCATION is
      select store,
             wh
        from rtv_head
       where rtv_order_no = I_rtv_order_no;


BEGIN

   if I_rtv_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_rtv_order_no',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_user_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---

   open C_CHECK_EXISTANCE;
   fetch C_CHECK_EXISTANCE into L_existing_id, L_existing_status;
   close C_CHECK_EXISTANCE;

   if L_existing_status != 'P' then
      if INVC_SQL.DELETE_INVC(O_error_message,
                              L_existing_id,
                              NULL) = FALSE then
         return FALSE;
      end if;
   end if;
   ---

   if L_supplier is NULL then
      SQL_LIB.SET_MARK('OPEN', 'C_GET_SUPPLIER', 'rtv_head', 'rtv_order_no: '||to_char(I_rtv_order_no));
      open C_GET_SUPPLIER;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_GET_SUPPLIER', 'rtv_head', 'rtv_order_no: '||to_char(I_rtv_order_no));
      fetch C_GET_SUPPLIER into L_supplier, L_store;
      ---
      if C_GET_SUPPLIER%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPPLIER', 'rtv_head', 'rtv_order_no: '||to_char(I_rtv_order_no));
         close C_GET_SUPPLIER;
         ---
         O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_SUPPLIER',
                                                NULL,
                                                NULL,
                                                NULL);
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPPLIER', 'rtv_head', 'rtv_order_no: '||to_char(I_rtv_order_no));
      close C_GET_SUPPLIER;
   end if;
   ---
   if L_invc_type is NULL then
      ---
      if SUPP_ATTRIB_SQL.DBT_MEMO_CODE(O_error_message,
                                       L_invc_type,
                                       L_supplier) = FALSE then
         return FALSE;
      end if;
      ---
      if L_invc_type = 'Y' then
         L_invc_type := 'D';
      else
         L_invc_type := 'R';
      end if;
      ---
   end if;

   if I_dbt_crdt_id is NULL then
      ---
      -- fix for defect 364694: create INVC_HEAD with the next number in sequence when rtv
      -- contains multiple items. Reuse the INVC_ID deleted earlier for the same rtv.
      ---
      if L_existing_id is NOT NULL and L_existing_status != 'P' then
         L_new_invc_id := L_existing_id;
      else
         if INVC_SQL.NEXT_INVC_ID(O_error_message,
                                  L_new_invc_id) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
   end if;
   ---
   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_GET_SUPS_INFO', 'sups', 'supplier: '||to_char(L_supplier));
   open C_GET_SUPS_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_GET_SUPS_INFO', 'sups', 'supplier: '||to_char(L_supplier));
   fetch C_GET_SUPS_INFO into L_auto_appr_dbt_memo,
                              L_payment_method,
                              L_currency_code,
                              L_vat_region;
   ---
   if C_GET_SUPS_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPS_INFO', 'sups', 'supplier: '||to_char(L_supplier));
      close C_GET_SUPS_INFO;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_SUPS_INFO',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_SUPS_INFO', 'sups', 'supplier: '||to_char(L_supplier));
   close C_GET_SUPS_INFO;

   if ((L_invc_type = 'D' or L_invc_type = 'M') and L_auto_appr_dbt_memo = 'N') or L_invc_type = 'C' then
      L_status := 'M';
   elsif L_invc_type = 'R' or L_auto_appr_dbt_memo = 'Y' then
      L_status := 'A';
   end if;
   ---
   if SUPP_ATTRIB_SQL.GET_SUP_PRIMARY_ADDR(O_error_message,
                                           L_addr_key,
                                           L_supplier,
                                           '05')= FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'invc_head', 'rtv_order_no: '||to_char(I_rtv_order_no));
   insert into invc_head(invc_id,
                         invc_type,
                         supplier,
                         ext_ref_no,
                         status,
                         edi_invc_ind,
                         match_fail_ind,
                         ref_invc_id,
                         ref_rtv_order_no,
                         ref_rsn_code,
                         terms,
                         due_date,
                         payment_method,
                         terms_dscnt_pct,
                         terms_dscnt_appl_ind,
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
                         comments,
                         edi_sent_ind,
                         terms_dscnt_appl_non_mrch_ind,
                         direct_ind,
                         paid_ind,
                         addr_key)
      select NVL(I_dbt_crdt_id, L_new_invc_id),
             L_invc_type,
             supplier,
             CASE
             	WHEN ret_auth_num IS NOT NULL THEN 'AUTH#'||ret_auth_num
             	WHEN ext_ref_no IS NOT NULL THEN 'REF#'||ext_ref_no
             	ELSE 'ORD#'||rtv_order_no
             END,
             L_status,
             'N',
             'N',
             NULL,
             I_rtv_order_no,
             I_ref_rsn_code,
             NULL,
             L_vdate,
             L_payment_method,
             NULL,
             'N',
             NULL,
             I_user_id,
             L_vdate,
             L_vdate,
             I_user_id,
             L_vdate,
             DECODE(L_status, 'A', I_user_id, NULL),
             DECODE(L_status, 'A', L_vdate, NULL),
             'N',
             NULL,
             NULL,
             L_currency_code,
             NULL,
             NULL,
             NULL,
             NULL,
             'N',
             'N',
             'N',
             'N',
             L_addr_key
        from rtv_head
       where rtv_order_no = I_rtv_order_no;
      ---
   if L_vat_ind = 'N' then
      SQL_LIB.SET_MARK('INSERT', NULL, 'invc_detail', 'rtv_order_no: '||to_char(I_rtv_order_no));
      insert into invc_detail (invc_id,
                               item,
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
         select distinct NVL(I_dbt_crdt_id, L_new_invc_id),
                item,
                unit_cost,
                SUM(qty_returned),
                NULL,
                'M',
                unit_cost,
                SUM(qty_returned),
                NULL,
                'N',
                'N',
                'N',
                'N',
                NULL
           from rtv_detail rd
          where rtv_order_no = I_rtv_order_no
            and NVL(qty_returned, 0) != 0
            and not exists (select 'x'
                              from invc_detail id, invc_head ih
                             where id.invc_id = ih.invc_id
                               and ih.status = 'P'
                               and ih.ref_rtv_order_no = I_rtv_order_no
                               and id.item = rd.item)
       group by item, unit_cost;
   else -- vat_ind = 'Y'
      -- Loop through each item on the rtv.  Retrieve the current vat rate for the item,
      -- calculate the vat for the rtv quantity, and insert the records into the
      -- invc_detail and invc_detail_vat tables.
      for rec in C_RTV_DETAIL LOOP
         L_item      := rec.item;
         L_unit_cost := rec.unit_cost;
         L_qty       := rec.qty;
         if L_old_item != L_item then
            -- Get the correct vat rate and code for the new item
            L_vat_rate           := NULL;
            L_vat_code           := NULL;
            ---
            if VAT_SQL.GET_VAT_RATE(O_error_message,   -- IN  OUT
                                    L_vat_region,      -- IN OUT
                                    L_vat_code,        -- IN OUT (NULL)
                                    L_vat_rate,        -- IN OUT (NULL)
                                    L_item,            -- IN     item
                                    NULL,              -- IN     dept
                                    NULL,              -- IN     loc_type
                                    NULL,              -- IN     location
                                    L_vdate,           -- IN     date
                                    'C') = FALSE then  -- IN     vat_type
               return FALSE;
            end if; -- GET_VAT_RATE
            ---
            L_old_item := L_item;
         end if;
         ---
         SQL_LIB.SET_MARK('INSERT', NULL, 'invc_detail', 'rtv_order_no: '||to_char(I_rtv_order_no));
         insert into invc_detail (invc_id,
                                  item,
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
            values(NVL(I_dbt_crdt_id, L_new_invc_id),
                   L_item,
                   L_unit_cost,
                   L_qty,
                   L_vat_rate,
                   'M',
                   L_unit_cost,
                   L_qty,
                   NULL,
                   'N',
                   'N',
                   'N',
                   'N',
                   null);
         ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
         open C_MERCH_VAT_EXISTS;

         SQL_LIB.SET_MARK('FETCH',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
         fetch C_MERCH_VAT_EXISTS into L_rowid;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_MERCH_VAT_EXISTS',
                          'invc_merch_vat',
                          'invc_id : ' || to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
         close C_MERCH_VAT_EXISTS;

         if L_rowid is NULL then
            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'invc_merch_vat',
                             'invc_id: '||to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));

            insert into invc_merch_vat(invc_id,
                                       vat_code,
                                       total_cost_excl_vat)
                                values(NVL(I_dbt_crdt_id, L_new_invc_id),
                                       L_vat_code,
                                       L_unit_cost * L_qty);

            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'invc_detail_vat',
                             'invc_id: '||to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));
         else
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'invc_merch_vat',
                             'invc_id: '||to_char(nvl(I_dbt_crdt_id, L_new_invc_id)));

            update invc_merch_vat
               set total_cost_excl_vat = total_cost_excl_vat + (L_unit_cost * L_qty)
             where rowid = L_rowid;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL, 'invc_detail_vat', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
         insert into invc_detail_vat(invc_id,
                                     item,
                                     invc_unit_cost,
                                     vat_cost)
           values (NVL(I_dbt_crdt_id, L_new_invc_id),
                   L_item,
                   L_unit_cost,
                   L_unit_cost * L_qty * (L_vat_rate/100));
      END LOOP;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_NEW_INVC_TOT_INFO', 'invc_detail', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   open C_NEW_INVC_TOT_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_NEW_INVC_TOT_INFO', 'invc_detail', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   fetch C_NEW_INVC_TOT_INFO into L_new_tot_cost, L_new_tot_qty;
   ---
   if C_NEW_INVC_TOT_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_NEW_INVC_TOT_INFO', 'invc_detail', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
      close C_NEW_INVC_TOT_INFO;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_COST_QTY_INFO',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_NEW_INVC_TOT_INFO', 'invc_detail', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   close C_NEW_INVC_TOT_INFO;
   ---
   if INVC_SQL.INVC_SYSTEM_OPTIONS_INDS(O_error_message,
                                        L_match_mult_sup_ind,
                                        L_match_qty_ind) = FALSE then
      return FALSE;
   end if;
   ---
   if L_match_qty_ind = 'N' then
      L_new_tot_qty := NULL;
   end if;
   ---
   if RTV_ATTRIB_SQL.GET_HEADER_INFO(O_error_message,
                                     L_rh_supplier,
                                     L_ret_auth_num,
                                     L_created_date,
                                     L_courier,
                                     L_restock_pct,
                                     I_rtv_order_no) = FALSE then
      return FALSE;
   end if;
   --- If the handling percent is not equal to zero then there are handling charges and the
   --- non_merch_code is set to Miscellaneous ('M').
   if L_restock_pct != 0 then
      L_non_merch_code := 'M';

      SQL_LIB.SET_MARK('OPEN', 'C_GET_NON_MERCH_CODE_DETAILS', 'non_merch_code_head', 'non_merch_code: '||  L_non_merch_code);
      open  C_GET_NON_MERCH_CODE_DETAILS;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_GET_NON_MERCH_CODE_DETAILS', 'non_merch_code_head', 'non_merch_code: '|| L_non_merch_code);
      fetch C_GET_NON_MERCH_CODE_DETAILS into L_non_merch_code_desc, L_service_ind;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_NON_MERCH_CODE_DETAILS', 'non_merch_code_head', 'non_merch_code: '|| L_non_merch_code);
      close C_GET_NON_MERCH_CODE_DETAILS;
      ---
      L_non_merch_amt := -(L_new_tot_cost/L_restock_pct);
      L_new_tot_cost := L_new_tot_cost + L_non_merch_amt;
      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'invc_non_merch', 'rtv_order_no: '||to_char(I_rtv_order_no));
         insert into invc_non_merch(invc_id,
                                    non_merch_code,
                                    non_merch_amt,
                                    vat_code,
                                    service_perf_ind,
                                    store)
            values(NVL(I_dbt_crdt_id, L_new_invc_id),
                   L_non_merch_code,
                   L_non_merch_amt,
                   L_vat_code,
                   'N',
                   L_store);

   end if;
   ---
   L_table := 'INVC_HEAD';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   open C_LOCK_INVC_HEAD;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   close C_LOCK_INVC_HEAD;
   ---
   SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_head', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   update invc_head
      set total_merch_cost = L_new_tot_cost,
          total_qty = L_new_tot_qty
    where invc_id = NVL(I_dbt_crdt_id, L_new_invc_id);
   ---
   --- Insert into INVC_XREF table to associate the RTVs and debit memos so that they can be
   --- cross-referenced  or invoice matched.
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_RTV_LOCATION',
                    'rtv_head',
                    'rtv_order_no: '||I_rtv_order_no);
   open C_GET_RTV_LOCATION;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_RTV_LOCATION',
                    'rtv_head',
                    'rtv_order_no: '||I_rtv_order_no);
   fetch C_GET_RTV_LOCATION into L_rtv_store,
                                 L_rtv_wh;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_RTV_LOCATION',
                    'rtv_head',
                    'rtv_order_no: '||I_rtv_order_no);
   close C_GET_RTV_LOCATION;

   if L_rtv_store = -1 and L_rtv_wh is NOT NULL then
      L_location := L_rtv_wh;
      L_loc_type := 'W';
   elsif L_rtv_store is NOT NULL then
      L_location := L_rtv_store;
      L_loc_type := 'S';
   else
      L_location := NULL;
      L_loc_type := NULL;
   end if;

   SQL_LIB.SET_MARK('INSERT', NULL, 'invc_xref', 'invc_id: '||to_char(NVL(I_dbt_crdt_id, L_new_invc_id)));
   insert into invc_xref(invc_id,
                         order_no,
                         shipment,
                         asn,
                         location,
                         loc_type,
                         apply_to_future_ind)
                  values(NVL(I_dbt_crdt_id, L_new_invc_id),
                         NULL,
                         NULL,
                         NULL,
                         L_location,
                         L_loc_type,
                         'N');


   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(NVL(I_dbt_crdt_id, L_new_invc_id)),
                                             NULL);
   return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_WRITE_SQL.WRITE_RTV_DBT_CRDT',
                                             to_char(SQLCODE));
   return FALSE;
END WRITE_RTV_DBT_CRDT;
-----------------------------------------------------------------------------------------


-------------------------------------------------------------------------


------------------------------------------------------------------------------------------
FUNCTION INVC_UNIT_COST_CHANGE (O_error_message         IN OUT VARCHAR2,
                                I_old_invc_unit_cost    IN     INVC_DETAIL.INVC_UNIT_COST%TYPE,
                                I_new_invc_unit_cost    IN     INVC_DETAIL.INVC_UNIT_COST%TYPE,
                                I_item                  IN     INVC_DETAIL.ITEM%TYPE,
                                I_invc_id               IN     INVC_DETAIL.INVC_ID%TYPE)
   return BOOLEAN is

   L_table                 VARCHAR2(30);
   RECORD_LOCKED           EXCEPTION;
   PRAGMA                  EXCEPTION_INIT(Record_Locked, -54);
   L_invc_id               INVC_MATCH_WKSHT.INVC_ID%TYPE;

   cursor C_GET_INVC_ID is
      select invc_id
        from invc_match_wksht
       where invc_id        = I_invc_id
         and item           = I_item
         and invc_unit_cost = I_old_invc_unit_cost;

   cursor C_LOCK_INVC_MATCH_WKSHT is
      select 'x'
        from invc_match_wksht
       where invc_id        = I_invc_id
         and item           = I_item
         and invc_unit_cost = I_old_invc_unit_cost
         for update nowait;

   cursor C_LOCK_INVC_DETAIL is
      select 'x'
        from invc_detail
       where invc_id        = I_invc_id
         and item           = I_item
         and invc_unit_cost = I_old_invc_unit_cost
         for update nowait;
BEGIN
   L_table := 'invc_match_wksht';
   SQL_LIB.SET_MARK('OPEN', 'C_GET_INVC_ID','invc_match_wksht','INVC_ID: '||to_char(I_invc_id));
   open C_GET_INVC_ID;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_GET_INVC_ID','invc_match_wksht','INVC_ID: '||to_char(I_invc_id));
   fetch C_GET_INVC_ID into L_invc_id;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_INVC_ID','invc_match_wksht','INVC_ID: '||to_char(I_invc_id));
   close C_GET_INVC_ID;
   ---
   if L_invc_id is not NULL then
      INSERT into invc_match_wksht_temp (invc_id,
                                         item,
                                         invc_unit_cost,
                                         shipment,
                                         seq_no,
                                         carton,
                                         invc_match_qty,
                                         match_to_cost,
                                         match_to_qty,
                                         match_to_seq_no)
         select I_invc_id,
                I_item,
                I_new_invc_unit_cost,
                shipment,
                seq_no,
                carton,
                invc_match_qty,
                match_to_cost,
                match_to_qty,
                match_to_seq_no
           from invc_match_wksht
          where invc_id        = I_invc_id
            and item           = I_item
            and invc_unit_cost = I_old_invc_unit_cost;
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_MATCH_WKSHT','invc_match_wksht','INVC_ID: '||to_char(I_invc_id));
      open C_LOCK_INVC_MATCH_WKSHT;
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_MATCH_WKSHT','invc_match_wksht','INVC_ID: '||to_char(I_invc_id));
      close C_LOCK_INVC_MATCH_WKSHT;
      ---
      SQL_LIB.SET_MARK('DELETE', NULL,'invc_match_wksht','INVC_ID: '||to_char(I_invc_id));
      delete from invc_match_wksht
            where invc_id        = I_invc_id
              and item           = I_item
              and invc_unit_cost = I_old_invc_unit_cost;
   end if;
   ---
   L_table := 'invc_detail';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_DETAIL','invc_detail','INVC_ID: '||to_char(I_invc_id));
   open C_LOCK_INVC_DETAIL;
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_DETAIL','invc_detail','INVC_ID: '||to_char(I_invc_id));
   close C_LOCK_INVC_DETAIL;
   ---
   SQL_LIB.SET_MARK('UPDATE', NULL,'invc_detail','INVC_ID: '||to_char(I_invc_id));
      update invc_detail
         set invc_unit_cost = I_new_invc_unit_cost
       where invc_id        = I_invc_id
         and item           = I_item
         and invc_unit_cost = I_old_invc_unit_cost;
   ---
   if L_invc_id is not NULL then
      insert into invc_match_wksht (invc_id,
                                    item,
                                    invc_unit_cost,
                                    shipment,
                                    seq_no,
                                    carton,
                                    invc_match_qty,
                                    match_to_cost,
                                    match_to_qty,
                                    match_to_seq_no)
         select I_invc_id,
                I_item,
                I_new_invc_unit_cost,
                shipment,
                seq_no,
                carton,
                invc_match_qty,
                match_to_cost,
                match_to_qty,
                match_to_seq_no
           from invc_match_wksht_temp
          where invc_id        = I_invc_id
            and item           = I_item
            and invc_unit_cost = I_new_invc_unit_cost;
      ---
      SQL_LIB.SET_MARK('DELETE', NULL,'invc_match_wksht_temp','INVC_ID: '||to_char(I_invc_id));
      delete from invc_match_wksht_temp
            where invc_id        = I_invc_id
              and item           = I_item
              and invc_unit_cost = I_new_invc_unit_cost;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_invc_id),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_WRITE_SQL.INVC_UNIT_COST_CHANGE',
                                             to_char(SQLCODE));
      return FALSE;
END INVC_UNIT_COST_CHANGE;
-------------------------------------------------------------------------------------------
END INVC_WRITE_SQL;
/

