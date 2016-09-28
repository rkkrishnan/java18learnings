CREATE OR REPLACE PACKAGE BODY INVC_ATTRIB_SQL AS
-------------------------------------------------------------------------------------------
FUNCTION GET_CURRENCY_RATE(O_error_message  IN OUT  VARCHAR2,
                           O_currency_code  IN OUT  invc_head.currency_code%TYPE,
                           O_exchange_rate  IN OUT  invc_head.exchange_rate%TYPE,
                           I_invc_id        IN      invc_head.invc_id%TYPE)
    RETURN BOOLEAN IS

   cursor C_get_curr_exchng is
      select currency_code,
             exchange_rate
        from invc_head
       where invc_id = I_invc_id;
BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_CURR_EXCHNG',
                    'INVC_HEAD',
                    'INVOICE NUMBER:'||to_char(I_invc_id));

   open C_get_curr_exchng;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_CURR_EXCHNG',
                    'INVC_HEAD',
                    'INVOICE NUMBER:'||to_char(I_invc_id));

   fetch C_get_curr_exchng into O_currency_code,
                                O_exchange_rate;
   if C_get_curr_exchng%NOTFOUND then

      SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CURR_EXCHNG',
                    'INVC_HEAD',
                    'INVOICE NUMBER:'||to_char(I_invc_id));
      close C_get_curr_exchng;
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_INVC',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_CURR_EXCHNG',
                    'INVC_HEAD',
                    'INVOICE NUMBER:'||to_char(I_invc_id));

   close C_get_curr_exchng;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         'INVC_ATTRIB_SQL.GET_CURRENCY_RATE',
                         to_char(SQLCODE));
      return FALSE;

END GET_CURRENCY_RATE;
-------------------------------------------------------------------------------------------
FUNCTION GET_INFO(O_error_message          IN OUT VARCHAR2,
                  O_supplier               IN OUT invc_head.supplier%TYPE,
                  O_partner_type           IN OUT invc_head.partner_type%TYPE,
                  O_partner_id             IN OUT invc_head.partner_id%TYPE,
                  O_currency_code          IN OUT invc_head.currency_code%TYPE,
                  O_invc_date              IN OUT invc_head.invc_date%TYPE,
                  O_status                 IN OUT invc_head.status%TYPE,
                  O_total_merch_cost_invc  IN OUT invc_head.total_merch_cost%TYPE,
                  O_total_qty              IN OUT invc_head.total_qty%TYPE,
                  O_invc_type              IN OUT invc_head.invc_type%TYPE,
                  O_ref_invc_id            IN OUT invc_head.ref_invc_id%TYPE,
                  O_ref_rtv_order_no       IN OUT invc_head.ref_rtv_order_no%TYPE,
                  O_create_id              IN OUT invc_head.create_id%TYPE,
                  O_ext_ref_no             IN OUT invc_head.ext_ref_no%TYPE,
                  O_exchange_rate          IN OUT invc_head.exchange_rate%TYPE,
                  I_invc_id                IN     invc_head.invc_id%TYPE)

   RETURN BOOLEAN IS

   cursor C_GET_INV_HD_DTL is
      select supplier,
             partner_type,
             partner_id,
             currency_code,
             invc_date,
             status,
             total_merch_cost,
             total_qty,
             invc_type,
             ref_invc_id,
             ref_rtv_order_no,
             create_id,
             ext_ref_no,
             exchange_rate
        from invc_head
       where invc_id = I_invc_id;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INV_HD_DTL',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));
   open C_GET_INV_HD_DTL;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INV_HD_DTL',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));
   fetch C_GET_INV_HD_DTL into O_supplier,
                               O_partner_type,
                               O_partner_id,
                               O_currency_code,
                               O_invc_date,
                               O_status,
                               O_total_merch_cost_invc,
                               O_total_qty,
                               O_invc_type,
                               O_ref_invc_id,
                               O_ref_rtv_order_no,
                               O_create_id,
                               O_ext_ref_no,
                               O_exchange_rate;

   if C_GET_INV_HD_DTL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_INVC',
                                            NULL,
                                            NULL,
                                            NULL);
       SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_INV_HD_DTL',
                       'invc_head',
                       'Invoice: '||to_char(I_invc_id));
       close C_GET_INV_HD_DTL;
       return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_INV_HD_DTL',
                       'invc_head',
                       'Invoice: '||to_char(I_invc_id));
   close C_GET_INV_HD_DTL;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         'INVC_ATTRIB_SQL.GET_INFO',
                         to_char(SQLCODE));
      return FALSE;

END GET_INFO;
-------------------------------------------------------------------------------------------
FUNCTION TOTAL_NON_MERCH_COST(O_error_message          IN OUT VARCHAR2,
                              O_total_non_merch_cost   IN OUT invc_non_merch.non_merch_amt%TYPE,
                              I_invc_id                IN     invc_non_merch.invc_id%TYPE,
                              I_dscnt_appl_ind         IN     VARCHAR2)

   RETURN BOOLEAN IS

   L_vat_region                       vat_region.vat_region%TYPE;
   L_invc_date                        invc_head.invc_date%TYPE;
   L_vat_rate                         vat_code_rates.vat_rate%TYPE;
   L_terms_dscnt_pct                  invc_head.terms_dscnt_pct%TYPE;

   cursor C_GET_VAT_NON_MERCH is
      select vat_code,
             non_merch_amt
        from invc_non_merch
       where invc_id = I_invc_id
         and vat_code is NOT NULL;

   cursor C_GET_INVC_INFO is
      select invc_date,
             terms_dscnt_pct
        from invc_head
       where invc_id = I_invc_id;

   cursor C_GET_TOTAL is
      select nvl(sum(non_merch_amt), 0)
        from invc_non_merch
       where invc_id = I_invc_id;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_dscnt_appl_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_dscnt_appl_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   O_total_non_merch_cost := 0;
   ---

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TOTAL',
                    'invc_non_merch',
                    'Invoice: '||to_char(I_invc_id));
   open C_GET_TOTAL;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TOTAL',
                    'invc_non_merch',
                    'Invoice: '||to_char(I_invc_id));
   fetch C_GET_TOTAL into O_total_non_merch_cost;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TOTAL',
                    'invc_non_merch',
                    'Invoice: '||to_char(I_invc_id));
   close C_GET_TOTAL;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INVC_INFO',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));
   open C_GET_INVC_INFO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INVC_INFO',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));
   fetch C_GET_INVC_INFO into L_invc_date,
                              L_terms_dscnt_pct;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_INVC_INFO',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));
   close C_GET_INVC_INFO;
   ---
   if I_dscnt_appl_ind = 'Y' then
         O_total_non_merch_cost := O_total_non_merch_cost - (O_total_non_merch_cost * (L_terms_dscnt_pct / 100));
   end if;
   ---
   FOR rec in C_GET_VAT_NON_MERCH LOOP
      if not VAT_SQL.GET_VAT_RATE(O_error_message,
                                  L_vat_region, -- NULL
                                  rec.vat_code,
                                  L_vat_rate,
                                  NULL, -- item
                                  NULL, -- dept
                                  NULL, -- loc type
                                  NULL, -- location
                                  L_invc_date,
                                  NULL) then
         return FALSE;
      end if;
      ---
      if I_dscnt_appl_ind = 'Y' then
         O_total_non_merch_cost := O_total_non_merch_cost + ((rec.non_merch_amt - (rec.non_merch_amt * (NVL(L_terms_dscnt_pct,0)/100))) * (L_vat_rate / 100));
      else
         O_total_non_merch_cost := O_total_non_merch_cost + (rec.non_merch_amt * (L_vat_rate / 100));
      end if;
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         'INVC_ATTRIB_SQL.TOTAL_NON_MERCH_COST',
                         to_char(SQLCODE));
      return FALSE;

END TOTAL_NON_MERCH_COST;
-------------------------------------------------------------------------------------------
FUNCTION TOTAL_INVC_MERCH_VAT(O_error_message          IN OUT VARCHAR2,
                              O_total_vat              IN OUT INVC_HEAD.TOTAL_MERCH_COST%TYPE,
                              I_invc_id                IN     INVC_HEAD.INVC_ID%TYPE,
                              I_dscnt_appl_ind         IN     VARCHAR2)

   RETURN BOOLEAN IS

   L_vat_region               VAT_REGION.VAT_REGION%TYPE;
   L_invc_date                INVC_HEAD.INVC_DATE%TYPE;
   L_vat_rate                 VAT_CODE_RATES.VAT_RATE%TYPE;
   L_terms_dscnt_pct          INVC_HEAD.TERMS_DSCNT_PCT%TYPE;

   cursor C_GET_VAT_MERCH is
      select vat_code,
             total_cost_excl_vat,
             -999 vat_cost
        from invc_merch_vat
       where invc_id = I_invc_id;

   cursor C_GET_INVC_INFO is
      select invc_date,
             terms_dscnt_pct
        from invc_head
       where invc_id = I_invc_id;

   cursor C_VAT_TOTAL is
      select NVL(SUM(vat_cost),0)
        from invc_detail_vat
       where invc_id = I_invc_id;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_dscnt_appl_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_dscnt_appl_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_INVC_INFO',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));
   open C_GET_INVC_INFO;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_INVC_INFO',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));
   fetch C_GET_INVC_INFO into L_invc_date,
                              L_terms_dscnt_pct;
   ---
   if C_GET_INVC_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_INVC',
                                             NULL,
                                             NULL,
                                             NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_IVNC_INFO',
                       'invc_head',
                       'Invoice: '||to_char(I_invc_id));
      close C_GET_INVC_INFO;

      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_IVNC_INFO',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));
   close C_GET_INVC_INFO;
   ---
   O_total_vat := 0;

   for merch_rec in C_GET_VAT_MERCH LOOP

      if not VAT_SQL.GET_VAT_RATE(O_error_message,
                                  L_vat_region, -- NULL
                                  merch_rec.vat_code,
                                  L_vat_rate,
                                  NULL, -- item
                                  NULL, -- dept
                                  NULL, -- loc type
                                  NULL, -- location
                                  L_invc_date,
                                  NULL) then
         return FALSE;
      end if;
      ---
      if I_dscnt_appl_ind = 'Y' then
         O_total_vat := O_total_vat +
         ((merch_rec.total_cost_excl_vat - (merch_rec.total_cost_excl_vat * (NVL(L_terms_dscnt_pct,0)/100))) * (L_vat_rate / 100));
      else
         O_total_vat := O_total_vat + (merch_rec.total_cost_excl_vat * (L_vat_rate / 100));
      end if;
      ---
   END LOOP;
   ---
   if O_total_vat = 0 then
      SQL_LIB.SET_MARK('OPEN',
                       'C_VAT_TOTAL',
                       'invc_detail_vat',
                       'Invoice: '||to_char(I_invc_id));
      open C_VAT_TOTAL;
      SQL_LIB.SET_MARK('FETCH',
                       'C_VAT_TOTAL',
                       'invc_detail_vat',
                       'Invoice: '||to_char(I_invc_id));
      fetch C_VAT_TOTAL into O_total_vat;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_VAT_TOTAL',
                       'invc_detail_vat',
                       'Invoice: '||to_char(I_invc_id));
      close C_VAT_TOTAL;
   end if;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                      SQLERRM,
                         'INVC_ATTRIB_SQL.TOTAL_INVC_MERCH_VAT',
                         to_char(SQLCODE));
      return FALSE;

END TOTAL_INVC_MERCH_VAT;
-------------------------------------------------------------------------------------------
FUNCTION GET_MATCH_RCPT_VAT_RATE(O_error_message  IN OUT VARCHAR2,
                                 O_rcpt_vat       IN OUT shipsku.unit_cost%TYPE,
                                 I_invc_id        IN     invc_head.invc_id%TYPE,
                                 I_invc_date      IN     invc_head.invc_date%TYPE,
                                 I_match_rcpt     IN     shipsku.shipment%TYPE,
                                 I_item           IN     shipsku.item%TYPE,
                                 I_vat_region     IN     vat_item.vat_region%TYPE)
   RETURN BOOLEAN IS

   L_vat_region         vat_region.vat_region%TYPE;
   L_vat_code           vat_codes.vat_code%TYPE;
   L_invc_date          invc_head.invc_date%TYPE       := I_invc_date;
   L_order_no           shipment.order_no%TYPE;

   cursor C_GET_ORDER_NO is
      select order_no
        from shipment
       where shipment = I_match_rcpt;

   cursor C_GET_INVC_DATE is
      select invc_date
        from invc_head
       where invc_id = I_invc_id;
BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_item',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_match_rcpt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_match_rcpt',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_vat_region is NULL then
      -- get the order number for the get_vat_region function call
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ORDER_NO',
                       'shipment',
                       'Receipt: '||I_match_rcpt);
      open C_GET_ORDER_NO;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ORDER_NO',
                       'shipment',
                       'Receipt: '||I_match_rcpt);
      fetch C_GET_ORDER_NO into L_order_no;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ORDER_NO',
                       'shipment',
                       'Receipt: '||I_match_rcpt);
      close C_GET_ORDER_NO;

      if not VAT_SQL.GET_VAT_REGION(O_error_message,
                                    L_vat_region,
                                    I_invc_id,
                                    L_order_no) then
         return FALSE;
      end if;
   else
      L_vat_region := I_vat_region;
   end if;
   ---
   if I_invc_date is NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_INVC_DATE',
                       'invc_head',
                       'Invoice: '||to_char(I_invc_id));
      open C_GET_INVC_DATE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_INVC_DATE',
                       'invc_head',
                       'Invoice: '||to_char(I_invc_id));
      fetch C_GET_INVC_DATE into L_invc_date;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_INVC_DATE',
                       'invc_head',
                       'Invoice: '||to_char(I_invc_id));
      close C_GET_INVC_DATE;
   end if;

   if L_vat_region is NOT NULL then
      if not VAT_SQL.GET_VAT_RATE(O_error_message,
                                  L_vat_region,
                                  L_vat_code,
                                  O_rcpt_vat,
                                  I_item,
                                  NULL, -- dept
                                  NULL, -- loc type
                                  NULL, -- location
                                  L_invc_date,
                                  'C') then
         return FALSE;
      end if;
   else
      O_rcpt_vat := 0;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         'INVC_ATTRIB_SQL.GET_MATCH_RCPT_VAT_RATE',
                         to_char(SQLCODE));
      return FALSE;

END GET_MATCH_RCPT_VAT_RATE;
-------------------------------------------------------------------------------------------
FUNCTION GET_MATCH_RCPT_TOTALS(O_error_message    IN OUT VARCHAR2,
                               O_total_qty        IN OUT shipsku.qty_received%TYPE,
                               O_total_cost_rcpt  IN OUT shipsku.unit_cost%TYPE,
                               O_total_vat_rcpt   IN OUT shipsku.unit_cost%TYPE,
                               I_invc_id          IN     invc_head.invc_id%TYPE,
                               I_match_rcpt       IN     shipsku.shipment%TYPE)
   RETURN BOOLEAN IS

   L_vat_ind         system_options.vat_ind%TYPE;
   L_item            invc_detail.item%TYPE;
   L_carton          shipsku.carton%TYPE;
   L_rcpt_qty        shipsku.unit_cost%TYPE;
   L_rcpt_cost       shipsku.unit_cost%TYPE;
   L_rcpt_vat        shipsku.unit_cost%TYPE;
   L_rcpt_dscnt      shipsku.unit_cost%TYPE;
   L_order_no        shipment.order_no%TYPE;
   L_total_cost_rcpt shipsku.unit_cost%TYPE;
   L_total_vat_rcpt  shipsku.unit_cost%TYPE;
   L_to_loc          shipment.to_loc%TYPE;
   L_dummy           VARCHAR2(1) := 'N';

   cursor C_RCPT_ORDER is
      select order_no, to_loc
        from shipment
       where shipment = I_match_rcpt;

   cursor C_INVC_TOTALS is
      select oic.item,
             oic.unit_cost,
             oic.qty
        from ordloc_invc_cost oic,
             invc_xref ix,
             shipment sh,
             shipsku sk
       where oic.order_no          = ix.order_no
         and oic.location          = L_to_loc
         and (oic.match_invc_id    = ix.invc_id
              or oic.match_invc_id is NULL)
         and oic.shipment          = ix.shipment
         and ix.invc_id            = I_invc_id
         and ix.shipment           = I_match_rcpt
         and ix.shipment           = sh.shipment
         and sh.invc_match_status != 'C'
         and sh.shipment           = sk.shipment
         and sk.item               = oic.item
         and sh.to_loc             = L_to_loc
         and (sk.match_invc_id     = I_invc_id
              or sk.match_invc_id is NULL)
   union all
      select sk1.item,
             sk1.unit_cost,
             NVL(sk1.qty_received, 0)
        from shipsku sk1
       where sk1.shipment = I_match_rcpt
         and (sk1.match_invc_id = I_invc_id
              or sk1.match_invc_id is NULL)
         and not exists (select 'x'
                           from ordloc_invc_cost oic1
                          where oic1.shipment = sk1.shipment
                            and oic1.item = sk1.item);

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_match_rcpt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_match_rcpt',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_RCPT_ORDER',
                    'SHIPMENT',
                    'Shipment : '||to_char(I_match_rcpt));
   open C_RCPT_ORDER;

   SQL_LIB.SET_MARK('FETCH',
                    'C_RCPT_ORDER',
                    'SHIPMENT',
                    'Shipment : '||to_char(I_match_rcpt));
   fetch C_RCPT_ORDER into L_order_no, L_to_loc;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_RCPT_ORDER',
                    'SHIPMENT',
                    'Shipment : '||to_char(I_match_rcpt));
   close C_RCPT_ORDER;
   ---
   if not SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                         O_error_message) then
      return FALSE;
   end if;
   ---
   O_total_qty         := 0;
   L_total_cost_rcpt   := 0;
   L_total_vat_rcpt    := 0;
   ---
   for invc_totals_rec in C_INVC_TOTALS LOOP
      L_rcpt_cost := invc_totals_rec.unit_cost;
      L_rcpt_qty  := invc_totals_rec.qty;
      ---
      if L_vat_ind = 'Y' then
         if not GET_MATCH_RCPT_VAT_RATE(O_error_message,
                                        L_rcpt_vat,
                                        I_invc_id,
                                        NULL,             -- invc date
                                        I_match_rcpt,
                                        invc_totals_rec.item,
                                        NULL) then
            return FALSE;
         end if;
      end if;
      ---
      O_total_qty         := O_total_qty + L_rcpt_qty;
      L_total_cost_rcpt   := L_total_cost_rcpt + (L_rcpt_cost * L_rcpt_qty);
      ---
      if L_vat_ind = 'Y' then
         L_total_vat_rcpt    := L_total_vat_rcpt + ((L_rcpt_vat/100) * L_rcpt_cost * L_rcpt_qty);
      end if;
      ---
   END LOOP;

   -- convert L_total_cost_rcpt and L_total_vat_rcpt into invoice currency
   ---
   if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                       L_order_no,
                                       'O',
                                       NULL,
                                       I_invc_id,
                                       'I',
                                       NULL,
                                       L_total_cost_rcpt,
                                       O_total_cost_rcpt,
                                       'C',
                                       NULL,
                                       NULL) = FALSE then
      return FALSE;
   end if;
   ---
   if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                       L_order_no,
                                       'O',
                                       NULL,
                                       I_invc_id,
                                       'I',
                                       NULL,
                                       L_total_vat_rcpt,
                                       O_total_vat_rcpt,
                                       'C',
                                       NULL,
                                       NULL) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         'INVC_ATTRIB_SQL.GET_MATCH_RCPT_TOTALS',
                         to_char(SQLCODE));
      return FALSE;

END GET_MATCH_RCPT_TOTALS;
---------------------------------------------------------------------------------------
FUNCTION TOTAL_INVC_COST(O_error_message              IN OUT VARCHAR2,
                         O_total_invc_cost            IN OUT invc_head.total_merch_cost%TYPE,
                         I_invc_id                    IN     invc_head.invc_id%TYPE,
                         I_mrch_dscnt_appl_ind        IN     VARCHAR2,
                         I_non_mrch_dscnt_appl_ind    IN     VARCHAR2)
   RETURN BOOLEAN IS

   L_invc_date             invc_head.invc_date%TYPE;
   L_total_merch_cost      invc_head.total_merch_cost%TYPE;
   L_terms_dscnt_pct       invc_head.terms_dscnt_pct%TYPE;
   L_total_dscnt_amt       invc_head.total_merch_cost%TYPE;
   L_total_non_merch_cost  invc_non_merch.non_merch_amt%TYPE;
   L_total_vat             invc_head.total_merch_cost%TYPE;
   L_vat_ind               system_options.vat_ind%TYPE;

   cursor C_invc_head is
      select total_merch_cost,
             terms_dscnt_pct
        from invc_head
       where invc_id = I_invc_id;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_mrch_dscnt_appl_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_mrch_dscnt_appl_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_non_mrch_dscnt_appl_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_non_mrch_dscnt_appl_ind',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_INVC_HEAD',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));

   open C_invc_head;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVC_HEAD',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));

   fetch C_invc_head into L_total_merch_cost,
                          L_terms_dscnt_pct;
   ---
   if C_invc_head%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_INVC',
                                            NULL,
                                            NULL,
                                            NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_INVC_HEAD',
                       'invc_head',
                       'Invoice: '||to_char(I_invc_id));

      close C_invc_head;
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVC_HEAD',
                    'invc_head',
                    'Invoice: '||to_char(I_invc_id));

   close C_invc_head;
   ---
   if INVC_ATTRIB_SQL.TOTAL_NON_MERCH_COST(O_error_message,
                                           L_total_non_merch_cost,
                                           I_invc_id,
                                           I_non_mrch_dscnt_appl_ind) = FALSE then
      return FALSE;
   end if;
   ---
   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   if L_vat_ind = 'Y' then
      if INVC_ATTRIB_SQL.TOTAL_INVC_MERCH_VAT(O_error_message,
                                              L_total_vat,
                                              I_invc_id,
                                              I_mrch_dscnt_appl_ind) = FALSE then
         return FALSE;
      end if;
      ---
   end if;
   ---
   if I_mrch_dscnt_appl_ind = 'Y' then
      L_total_dscnt_amt := NVL(L_total_merch_cost,0) * (NVL(L_terms_dscnt_pct,0)/100);
   end if;
   ---
   O_total_invc_cost := NVL(L_total_merch_cost,0) + NVL(L_total_non_merch_cost,0) + NVL(L_total_vat,0) - NVL(L_total_dscnt_amt,0);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         'INVC_ATTRIB_SQL.TOTAL_INVC_COST',
                         to_char(SQLCODE));
      return FALSE;

END TOTAL_INVC_COST;
--------------------------------------------------------------------------------------
FUNCTION GET_DBT_CRDT_INFO(O_error_message              IN OUT VARCHAR2,
                           O_invc_id                    IN OUT invc_head.invc_id%TYPE,
                           O_invc_type                  IN OUT invc_head.invc_type%TYPE,
                           O_invc_status                IN OUT invc_head.status%TYPE,
                           O_total_invc_cost            IN OUT invc_head.total_merch_cost%TYPE,
                           I_ref_invc_id                IN     invc_head.ref_invc_id%TYPE)
   RETURN BOOLEAN IS

   L_invc_id    invc_head.invc_id%TYPE;

   cursor C_get_dbt_crdt is
      select h.invc_id,
             h.invc_type,
             h.status
        from invc_head h
       where h.ref_invc_id = I_ref_invc_id
         and exists (select 'x'
                       from invc_detail d
                      where d.invc_id = h.invc_id);
BEGIN
   if I_ref_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ref_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_DBT_CRDT',
                    'invc_head',
                    'Ref Invoice: '||to_char(I_ref_invc_id));

   open C_get_dbt_crdt;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_DBT_CRDT',
                    'invc_head',
                    'Ref Invoice: '||to_char(I_ref_invc_id));

   fetch C_get_dbt_crdt into L_invc_id,
                             O_invc_type,
                             O_invc_status;

   if C_get_dbt_crdt%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('REF_INVC_NO_DETL',
                                            NULL,
                                            NULL,
                                            NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_DBT_CRDT',
                       'invc_head',
                       'Ref Invoice: '||to_char(I_ref_invc_id));
      close C_get_dbt_crdt;
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_DBT_CRDT',
                    'invc_head',
                    'Ref Invoice: '||to_char(I_ref_invc_id));

   close C_get_dbt_crdt;

   if INVC_ATTRIB_SQL.TOTAL_INVC_COST(O_error_message,
                                      O_total_invc_cost,
                                      L_invc_id,
                                      'N',
                                      'N') = FALSE then
      return FALSE;
   end if;
   ---
   O_invc_id := L_invc_id;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         'INVC_ATTRIB_SQL.GET_DBT_CRDT_INFO',
                         to_char(SQLCODE));
      return FALSE;

END GET_DBT_CRDT_INFO;
---------------------------------------------------------------------------------------------
FUNCTION GET_NMERCH_CODE_INFO(O_error_message  IN OUT VARCHAR2,
                              O_code_desc      IN OUT non_merch_code_head.non_merch_code_desc%TYPE,
                              O_service_ind    IN OUT non_merch_code_head.service_ind%TYPE,
                              I_code           IN     non_merch_code_head.non_merch_code%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'INVC_ATTRIB_SQL.GET_NMERCH_CODE_INFO';
   L_code_desc   NON_MERCH_CODE_HEAD.NON_MERCH_CODE_DESC%TYPE;

   cursor c_get_code_info IS
      select i.non_merch_code_desc,
             i.service_ind
        from non_merch_code_head i
       where i.non_merch_code = I_code;

BEGIN
   if I_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_code',
                                            L_program,
                                            NULL);
      return FALSE;

   else

      SQL_LIB.SET_MARK('OPEN',
                       'C_get_code_info',
                       'non_merch_code_head',
                       'Ref Non-Merch code: '||I_code);

       open C_get_code_info;

      SQL_LIB.SET_MARK('FETCH',
                       'C_get_code_info',
                       'non_merch_code_head',
                       'Ref Non-Merch code: '||I_code);

      fetch C_get_code_info into L_code_desc, O_service_ind;

      if C_get_code_info%NOTFOUND then
         -- LT Def NBS00015188, 30-Oct-2009, Nitin Gour, nitin.gour@in.tesco.com (BEGIN)
         /*O_error_message := SQL_LIB.CREATE_MSG('NO_NMERCH_CODE_DESC',
                                               NULL,
                                               NULL,
                                               NULL);*/
         O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_MI_COST_CENTRE',
                                               I_code,
                                               NULL,
                                               NULL);
         -- LT Def NBS00015188, 30-Oct-2009, Nitin Gour, nitin.gour@in.tesco.com (END)
         SQL_LIB.SET_MARK('CLOSE',
                          'C_get_code_info',
                          'non_merch_code_desc',
                          'Ref Non-Merch code: '||I_code);
         close C_get_code_info;
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_get_code_info',
                       'non_merch_code_desc',
                       'Ref Non-Merch code: '||I_code);

      close C_get_code_info;
      ---
      if LANGUAGE_SQL.TRANSLATE(L_code_desc,
                                O_code_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      ---
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_NMERCH_CODE_INFO;
--------------------------------------------------------------------------------------------------------
FUNCTION TOTAL_TRAN_DSCNT(O_error_message      IN OUT VARCHAR2,
                          O_total_tran_dscnt   IN OUT INVC_DISCOUNT.APPLIES_TO_AMT%TYPE,
                          I_invc_id            IN     INVC_DISCOUNT.INVC_ID%TYPE)
RETURN BOOLEAN IS

   L_discount_type     INVC_DISCOUNT.DISCOUNT_TYPE%TYPE;
   L_discount_value    INVC_DISCOUNT.DISCOUNT_VALUE%TYPE;
   L_applies_to_amt    INVC_DISCOUNT.APPLIES_TO_AMT%TYPE;
   L_discount_amt      INVC_DISCOUNT.DISCOUNT_VALUE%TYPE;
   L_total             NUMBER(20,4) := 0;
   ---
   cursor C_GET_INVC_ID is
      select discount_type,
             discount_value,
             applies_to_amt
        from invc_discount
       where invc_id = I_invc_id;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   for C_rec in C_GET_INVC_ID LOOP
      L_discount_type  := C_rec.discount_type;
      L_discount_value := C_rec.discount_value;
      L_applies_to_amt := C_rec.applies_to_amt;
      ---
      if L_discount_type = 'A' then
          L_discount_amt := L_discount_value;
      elsif L_discount_type = 'P' then
          L_discount_amt := ((L_discount_value/100) * L_applies_to_amt);
      end if;
      ---
      L_total := L_total +  L_discount_amt;
   END LOOP;
   ---
   O_total_tran_dscnt := L_total;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_ATTRIB_SQL.TOTAL_TRAN_DSCNT',
                                            to_char(SQLCODE));
      return FALSE;

END TOTAL_TRAN_DSCNT;
--------------------------------------------------------------------------------------------------------
FUNCTION MATCH_TO_COST_QTY(O_error_message      IN OUT VARCHAR2,
                           O_match_to_cost      IN OUT INVC_MATCH_WKSHT.MATCH_TO_COST%TYPE,
                           O_match_to_qty       IN OUT INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE,
                           I_invc_id            IN     INVC_MATCH_WKSHT.INVC_ID%TYPE,
                           I_item               IN     ITEM_MASTER.ITEM%TYPE,
                           I_shipment           IN     INVC_MATCH_WKSHT.SHIPMENT%TYPE,
                           I_carton             IN     INVC_MATCH_WKSHT.CARTON%TYPE,
                           I_invc_cost          IN     INVC_MATCH_WKSHT.INVC_UNIT_COST%TYPE,
                           I_invc_qty           IN     INVC_MATCH_WKSHT.INVC_MATCH_QTY%TYPE,
                           I_single_cost_out    IN     BOOLEAN)
RETURN BOOLEAN IS

   L_match_to_cost         INVC_MATCH_WKSHT.MATCH_TO_COST%TYPE;
   L_match_to_qty          INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE;
   L_qty_received          SHIPSKU.QTY_RECEIVED%TYPE;
   L_unit_cost_shipsku     SHIPSKU.UNIT_COST%TYPE;
   L_qty_ordloc            ORDLOC_INVC_COST.QTY%TYPE;
   L_unit_cost_ordloc      ORDLOC_INVC_COST.UNIT_COST%TYPE;
   L_order_no              ORDHEAD.ORDER_NO%TYPE;
   L_order_currency        ORDHEAD.CURRENCY_CODE%TYPE;
   L_invc_currency         INVC_HEAD.CURRENCY_CODE%TYPE;
   L_invc_cost_order       INVC_MATCH_WKSHT.INVC_UNIT_COST%TYPE;
   L_invc_qty              INVC_MATCH_WKSHT.INVC_MATCH_QTY%TYPE;
   L_temp                  NUMBER(21,4) := 99999999999999999;
   L_nearest_cost          ORDLOC_INVC_COST.UNIT_COST%TYPE;
   L_nearest_qty           ORDLOC_INVC_COST.QTY%TYPE;
   L_sum_qty               ORDLOC_INVC_COST.QTY%TYPE := 0;
   L_location              ORDLOC_INVC_COST.LOCATION%TYPE;
   L_dummy_exchange_rate   INVC_HEAD.EXCHANGE_RATE%TYPE;
   L_record                NUMBER;

   cursor C_INVC_MATCH_WKSHT is
      select match_to_cost,
             match_to_qty
        from invc_match_wksht
       where invc_id        = I_invc_id
         and item           = I_item
         and shipment       = I_shipment
         and (carton        = I_carton
              or (carton is NULL and I_carton is NULL))
         and invc_unit_cost = I_invc_cost;

   cursor C_SHIPSKU is
      select s.qty_received,
             s.unit_cost,
             sh.order_no,
             sh.to_loc
        from shipsku s, shipment sh
       where s.shipment = I_shipment
         and s.shipment = sh.shipment
         and s.item     = I_item
         and (s.carton  = I_carton
              or (s.carton is NULL and I_carton is NULL));

   cursor C_ORDLOC_INVC_COST_REC is
      select count(*)
        from ordloc_invc_cost
       where item                = I_item
         and order_no            = L_order_no
         and location            = L_location
         and match_invc_id       = I_invc_id
         and shipment            = I_shipment
         and (carton             = I_carton
              or (carton is NULL and I_carton is NULL));

   /* cursor below is used by main and internal function and  */
   /* needs to query all associated records whether           */
   /* match_invc_id is populated or not                       */

   cursor C_GET_SUM_QTY is
      select sum(qty)
        from ordloc_invc_cost
       where item               = I_item
         and order_no           = L_order_no
         and location           = L_location
         and shipment           = I_shipment
         and (carton            = I_carton
              or carton is NULL and I_carton is NULL)
         and (match_invc_id     = I_invc_id
              or match_invc_id is NULL);

   /* - cursor below will find the record with the cost and qty that  */
   /*   that most closely match the input cost and qty.               */
   /* - note that the cost match takes precedence over the qty match. */
   /* - cursor will always retrieve the lower unit_cost if 2 or more  */
   /*   unit_costs exist that are equidistant from the input cost     */
   /*   (provided that equidistant costs are nearest to input cost)   */

   cursor C_GET_NEAREST_COST_QTY is
      select * from (select unit_cost,
                            qty
                       from ordloc_invc_cost
                      where item          = I_item
                        and order_no      = L_order_no
                        and location      = L_location
                        and match_invc_id = I_invc_id
                        and shipment      = I_shipment
                        and (carton       = I_carton
                             or (carton is NULL and I_carton is NULL))
                   order by abs(unit_cost - L_invc_cost_order),
                            abs(qty - L_invc_qty),
                            unit_cost)
       where rownum = 1;

   cursor C_ORDLOC_INVC_COST is
      select unit_cost,
             qty
        from ordloc_invc_cost
       where item          = I_item
         and order_no      = L_order_no
         and location      = L_location
         and match_invc_id = I_invc_id
         and shipment      = I_shipment
         and (carton       = I_carton
              or (carton is NULL and I_carton is NULL));

   cursor C_ORDLOC_INVC_COST_NULL_REC is
      select count(*)
        from ordloc_invc_cost
         where item   = I_item
         and order_no = L_order_no
         and location = L_location
         and shipment = I_shipment
         and (carton  = I_carton
              or (carton is NULL and I_carton is NULL))
         and match_invc_id is NULL;

   cursor C_ORDLOC_INVC_COST_NULL is
      select unit_cost,
             qty
        from ordloc_invc_cost
       where item     = I_item
         and order_no = L_order_no
         and location = L_location
         and shipment = I_shipment
         and (carton  = I_carton
              or (carton is NULL and I_carton is NULL))
         and match_invc_id is NULL;

------------------------------------------------------------------------
-- This is an internal function that gets called from the main function
-- MATCH_TO_COST_QTY three different times.  It does the same processing
-- as in the main function except the cursor considers records on
-- ordloc_invc_cost table with NULL values for match_invc_id
------------------------------------------------------------------------
FUNCTION GET_COST_QTY(O_error_message      IN OUT VARCHAR2,
                      O_match_to_cost      IN OUT INVC_MATCH_WKSHT.MATCH_TO_COST%TYPE,
                      O_match_to_qty       IN OUT INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE,
                      I_order_no           IN     ORDLOC_INVC_COST.ORDER_NO%TYPE,
                      I_item               IN     INVC_MATCH_WKSHT.ITEM%TYPE,
                      I_location           IN     ORDLOC_INVC_COST.LOCATION%TYPE,
                      I_invc_cost          IN     INVC_MATCH_WKSHT.INVC_UNIT_COST%TYPE,
                      I_invc_qty           IN     INVC_MATCH_WKSHT.INVC_MATCH_QTY%TYPE,
                      I_single_cost_out    IN     BOOLEAN)
RETURN BOOLEAN IS

   L_invc_cost_order       INVC_MATCH_WKSHT.INVC_UNIT_COST%TYPE;
   L_invc_qty              INVC_MATCH_WKSHT.INVC_MATCH_QTY%TYPE;
   L_qty_ordloc            ORDLOC_INVC_COST.QTY%TYPE;
   L_unit_cost_ordloc      ORDLOC_INVC_COST.UNIT_COST%TYPE;
   L_nearest_cost          ORDLOC_INVC_COST.UNIT_COST%TYPE;
   L_nearest_qty           ORDLOC_INVC_COST.QTY%TYPE;
   L_sum_qty               ORDLOC_INVC_COST.QTY%TYPE := 0;
   L_record                NUMBER;


   /* - cursor below will find the record with the cost and qty that  */
   /*   that most closely match the input cost and qty.               */
   /* - note that the cost match takes precedence over the qty match. */
   /* - cursor will always retrieve the lower unit_cost if 2 or more  */
   /*   unit_costs exist that are equidistant from the input cost     */
   /*   (provided that equidistant costs are nearest to input cost)   */

   cursor C_GET_NEAREST_COST_QTY_NULL is
      select * from (select unit_cost,
                            qty
                       from ordloc_invc_cost
                      where item     = I_item
                        and order_no = I_order_no
                        and location = I_location
                        and shipment = I_shipment
                        and (carton  = I_carton
                             or (carton is NULL and I_carton is NULL))
                        and match_invc_id is NULL
                   order by abs(unit_cost - L_invc_cost_order),
                            abs(qty - L_invc_qty),
                            unit_cost)
       where rownum = 1;

BEGIN

   open C_ORDLOC_INVC_COST_NULL_REC;
   fetch C_ORDLOC_INVC_COST_NULL_REC into L_record;
   close C_ORDLOC_INVC_COST_NULL_REC;
   ---
   if L_record = 0 then
      -- convert L_unit_cost_shipsku into invoice currency
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_unit_cost_shipsku,
                              L_order_currency,
                              L_invc_currency,
                              O_match_to_cost,
                              'C',
                              NULL,
                              NULL) = FALSE then
         return FALSE;
      end if;
      ---
      O_match_to_qty  := L_qty_received;
      return TRUE;
      ---
   elsif L_record = 1 then   -- 1 record found
      open C_ORDLOC_INVC_COST_NULL;
      fetch C_ORDLOC_INVC_COST_NULL into L_unit_cost_ordloc,
                                         L_qty_ordloc;
      close C_ORDLOC_INVC_COST_NULL;
      ---
      -- convert L_unit_cost_ordloc into invoice currency
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_unit_cost_ordloc,
                              L_order_currency,
                              L_invc_currency,
                              O_match_to_cost,
                              'C',
                              NULL,
                              NULL) = FALSE then
         return FALSE;
      end if;
      ---
      O_match_to_qty  := L_qty_ordloc;
      ---
      return TRUE;
   elsif L_record > 1 then    -- more than 1 record was found
      if I_single_cost_out = TRUE then
         O_match_to_cost := NULL;
         O_match_to_qty  := NULL;
         ---
         return TRUE;
      end if;
      ---
      if I_invc_cost is NULL then
         -- convert L_unit_cost_shipsku into invoice currency
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_unit_cost_shipsku,
                                 L_order_currency,
                                 L_invc_currency,
                                 O_match_to_cost,
                                 'C',
                                 NULL,
                                 NULL) = FALSE then
            return FALSE;
         end if;
         ---
         O_match_to_qty  := L_qty_received;
         return TRUE;
         ---
      else   -- I_invc_cost is not NULL
         -- convert I_invc_cost into order currency
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 I_invc_cost,
                                 L_invc_currency,
                                 L_order_currency,
                                 L_invc_cost_order,
                                 'C',
                                 NULL,
                                 NULL) = FALSE then
            return FALSE;
         end if;
         -- get the qty_received from shipsku if I_invc_qty is passed in NULL
         if I_invc_qty is NULL then
            L_invc_qty := L_qty_received;
         else
            L_invc_qty := I_invc_qty;
         end if;
         -- find unit_cost and qty that most closely match
         -- I_invc_cost (resp. L_invc_cost_order) and I_invc_qty (resp. L_invc_qty)

         open C_GET_NEAREST_COST_QTY_NULL;
         fetch C_GET_NEAREST_COST_QTY_NULL into L_nearest_cost, L_nearest_qty;
         close C_GET_NEAREST_COST_QTY_NULL;

         open C_GET_SUM_QTY;
         fetch C_GET_SUM_QTY into L_sum_qty;
         close C_GET_SUM_QTY;

         if L_nearest_qty <= (L_qty_received - (L_sum_qty - L_nearest_qty)) then

            -- qty received is greater than or equal to what we're
            -- being invoiced for, return nearest cost and qty from ordloc_invc_cost
            -- to promote a match.

            -- convert L_temp_cost into invoice currency
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_nearest_cost,
                                    L_order_currency,
                                    L_invc_currency,
                                    O_match_to_cost,
                                    'C',
                                    NULL,
                                    NULL) = FALSE then
               return FALSE;
            end if;
            ---
            O_match_to_qty  := L_nearest_qty;
            ---
            return TRUE;
         else

            -- qty we're being invoiced for exceeds what we've received,
            -- so return shipsku cost and qty to ensure we match against
            -- what was actually received.

            -- convert I_unit_cost_shipsku into invoice currency
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_unit_cost_shipsku,
                                    L_order_currency,
                                    L_invc_currency,
                                    O_match_to_cost,
                                    'C',
                                    NULL,
                                    NULL) = FALSE then
               return FALSE;
            end if;
            ---
            O_match_to_qty  := L_qty_received;
            return TRUE;
            ---
         end if;
      end if;    -- I_invc_cost not NULL
   end if;       -- C_ORDLOC_INVC_COST_NULL cursor
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_ATTRIB_SQL.MATCH_TO_COST_QTY',
                                            to_char(SQLCODE));
      return FALSE;
END GET_COST_QTY;
------------------------------------------------------------------------------------
-- main function MATCH_TO_COST_QTY begins
BEGIN
   if I_invc_id is NULL or I_item is NULL or I_shipment is NULL
      or I_single_cost_out is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',
                                            'INVC_ATTRIB_SQL.MATCH_TO_COST_QTY',
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---

   -- retrieve qty_received and unit_cost from shipsku and order_no from shipment
   open C_SHIPSKU;
   fetch C_SHIPSKU into L_qty_received,
                        L_unit_cost_shipsku,
                        L_order_no,
                        L_location;
   if C_SHIPSKU%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_SHIP',NULL,NULL,NULL);
      close C_SHIPSKU;
      return FALSE;
   end if;

   close C_SHIPSKU;
   ---
   open C_INVC_MATCH_WKSHT;
   fetch C_INVC_MATCH_WKSHT into L_match_to_cost,
                                 L_match_to_qty;
   if C_INVC_MATCH_WKSHT%FOUND then
      open C_ORDLOC_INVC_COST_REC;
      fetch C_ORDLOC_INVC_COST_REC into L_record;
      close C_ORDLOC_INVC_COST_REC;

      if L_record < 1 then
         -- no deals were applied, return shipment's cost/qty from wksht --
         O_match_to_cost := L_match_to_cost;
         O_match_to_qty  := L_match_to_qty;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_INVC_MATCH_WKSHT',
                          'INVC_MATCH_WKSHT',
                          'Invoice: '||to_char(I_invc_id));
         close C_INVC_MATCH_WKSHT;
         return TRUE;
      end if;
   end if;
   ---
   --reset L_record to NULL for next record count --
   L_record := NULL;
   ---
   close C_INVC_MATCH_WKSHT;
   ---

   open C_ORDLOC_INVC_COST_REC;
   fetch C_ORDLOC_INVC_COST_REC into L_record;
   close C_ORDLOC_INVC_COST_REC;
   ---
   -- retrieve L_order_currency and L_invc_currency
   if CURRENCY_SQL.GET_CURR_LOC(O_error_message,
                                L_order_no,
                                'O',
                                NULL,
                                L_order_currency) = FALSE then
      return FALSE;
   end if;
   ---
   if GET_CURRENCY_RATE(O_error_message,
                        L_invc_currency,
                        L_dummy_exchange_rate,
                        I_invc_id) = FALSE then
      return FALSE;
   end if;

   ---
   if L_record = 0 then    -- no records found
      if GET_COST_QTY(O_error_message,
                      O_match_to_cost,
                      O_match_to_qty,
                      L_order_no,
                      I_item,
                      L_location,
                      I_invc_cost,
                      I_invc_qty,
                      I_single_cost_out) = FALSE then
         return FALSE;
      end if;
   elsif L_record = 1 then  -- one record is found
      open C_ORDLOC_INVC_COST;
      fetch C_ORDLOC_INVC_COST into L_unit_cost_ordloc,
                                    L_qty_ordloc;
      close C_ORDLOC_INVC_COST;
      ---
      -- convert L_unit_cost_ordloc into invoice currency
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_unit_cost_ordloc,
                              L_order_currency,
                              L_invc_currency,
                              O_match_to_cost,
                              'C',
                              NULL,
                              NULL) = FALSE then
         return FALSE;
      end if;
      ---
      O_match_to_qty  := L_qty_ordloc;
      ---
      return TRUE;
   elsif L_record > 1 then   -- more than one record is found
      if I_single_cost_out = TRUE then
         O_match_to_cost := NULL;
         O_match_to_qty  := NULL;
         ---
         return TRUE;
      end if;
      ---
      if I_invc_cost is NULL then
         if GET_COST_QTY(O_error_message,
                         O_match_to_cost,
                         O_match_to_qty,
                         L_order_no,
                         I_item,
                         L_location,
                         I_invc_cost,
                         I_invc_qty,
                         I_single_cost_out) = FALSE then
            return FALSE;
         end if;
      else   -- I_invc_cost is not NULL
         -- convert I_invc_cost into order currency
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 I_invc_cost,
                                 L_invc_currency,
                                 L_order_currency,
                                 L_invc_cost_order,
                                 'C',
                                 NULL,
                                 NULL) = FALSE then
            return FALSE;
         end if;
         ---
         -- get the qty_received from shipsku if I_invc_qty is passed in NULL
         if I_invc_qty is NULL then
            L_invc_qty := L_qty_received;
         else
            L_invc_qty := I_invc_qty;
         end if;

         open C_GET_NEAREST_COST_QTY;
         fetch C_GET_NEAREST_COST_QTY into L_nearest_cost, L_nearest_qty;
         close C_GET_NEAREST_COST_QTY;

         open C_GET_SUM_QTY;
         fetch C_GET_SUM_QTY into L_sum_qty;
         close C_GET_SUM_QTY;

         if L_nearest_qty <= (L_qty_received - (L_sum_qty - L_nearest_qty)) then

            -- qty received is greater than or equal to what we're
            -- being invoiced for, return nearest cost and qty from ordloc_invc_cost
            -- to promote a match.

            -- convert L_temp_cost into invoice currency
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_nearest_cost,
                                    L_order_currency,
                                    L_invc_currency,
                                    O_match_to_cost,
                                    'C',
                                    NULL,
                                    NULL) = FALSE then
               return FALSE;
            end if;
            ---
            O_match_to_qty  := L_nearest_qty;
            ---
            return TRUE;
         else

            -- qty we're being invoiced for exceeds what we've received,
            -- so return shipsku cost and qty to ensure we match against
            -- what was actually received.

            if GET_COST_QTY(O_error_message,
                            O_match_to_cost,
                            O_match_to_qty,
                            L_order_no,
                            I_item,
                            L_location,
                            I_invc_cost,
                            I_invc_qty,
                            I_single_cost_out) = FALSE then
               return FALSE;
            end if;
         end if;  -- L_nearest_qty not TRUE
      end if;  -- I_invc_cost not NULL
   end if;  -- C_ORDLOC_INVC_COST%FOUND cursor
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_ATTRIB_SQL.MATCH_TO_COST_QTY',
                                            to_char(SQLCODE));
      return FALSE;
END MATCH_TO_COST_QTY;
--------------------------------------------------------------------------------------------------------
FUNCTION CHECK_REASON_CODE_TYPE (O_error_message   IN OUT VARCHAR2,
                                 O_type_ind        IN OUT VARCHAR2,
                                 I_code            IN     CODE_DETAIL.CODE_TYPE%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64) := 'INVC_ATTRIB_SQL.CHECK_REASON_CODE_TYPE';

   cursor C_CHECK_NON_MERCH is
      select 'N'
        from non_merch_code_head n
       where n.non_merch_code = I_code;

   cursor C_CHECK_CODE_DETAIL is
      select 'C'
        from code_detail c
       where c.code_type = 'REAC'
         and c.code      = I_code;


BEGIN
   if I_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INPUT_GENERIC',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_NON_MERCH', 'NON_MERCH_CODE_HEAD', NULL);
   open C_CHECK_NON_MERCH;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_CHECK_NON_MERCH', 'NON_MERCH_CODE_HEAD', NULL);
   fetch C_CHECK_NON_MERCH into O_type_ind;
   ---
   if O_type_ind is NULL then
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_CODE_DETAIL', 'CODE_DETAIL', NULL);
      open C_CHECK_CODE_DETAIL;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_CODE_DETAIL', 'CODE_DETAIL', NULL);
      fetch C_CHECK_CODE_DETAIL into O_type_ind;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_CODE_DETAIL', 'CODE_DETAIL', NULL);
      close C_CHECK_CODE_DETAIL;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_NON_MERCH', 'NON_MERCH_CODE_HEAD', NULL);
   close C_CHECK_NON_MERCH;
   ---
   if O_type_ind is NULL then
      O_type_ind := 'I';
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
END CHECK_REASON_CODE_TYPE;
--------------------------------------------------------------------------------------------------------
-- 09-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 Begin
FUNCTION GET_NMERCH_CODE_INFO_ROI(O_error_message  IN OUT VARCHAR2,
                                  O_code_desc      IN OUT non_merch_code_head.non_merch_code_desc%TYPE,
                                  O_service_ind    IN OUT non_merch_code_head.service_ind%TYPE,
                                  I_code           IN     non_merch_code_head.non_merch_code%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(64) := 'INVC_ATTRIB_SQL.GET_NMERCH_CODE_INFO_ROI';
   L_code_desc   NON_MERCH_CODE_HEAD.NON_MERCH_CODE_DESC%TYPE;

      CURSOR C_GET_CODE_INFO is
      select i.non_merch_code_desc,
             i.service_ind
        from tsl_non_merch_code_head_roi i
       where i.non_merch_code = I_code;

BEGIN
   if I_code is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_code',
                                            L_program,
                                            NULL);
      return FALSE;

   else

      SQL_LIB.SET_MARK('OPEN',
                       'C_get_code_info',
                       'non_merch_code_head',
                       'Ref Non-Merch code: '||I_code);

       open C_get_code_info;

      SQL_LIB.SET_MARK('FETCH',
                       'C_get_code_info',
                       'non_merch_code_head',
                       'Ref Non-Merch code: '||I_code);

      fetch C_get_code_info into L_code_desc, O_service_ind;

      if C_get_code_info%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('TSL_INV_MI_COST_CENTRE',
                                               I_code,
                                               NULL,
                                               NULL);

         SQL_LIB.SET_MARK('CLOSE',
                          'C_get_code_info',
                          'non_merch_code_desc',
                          'Ref Non-Merch code: '||I_code);
         close C_get_code_info;
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE',
                       'C_get_code_info',
                       'non_merch_code_desc',
                       'Ref Non-Merch code: '||I_code);

      close C_get_code_info;
      ---
      if LANGUAGE_SQL.TRANSLATE(L_code_desc,
                                O_code_desc,
                                O_error_message) = FALSE then
         return FALSE;
      end if;
      ---
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
     O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GET_NMERCH_CODE_INFO_ROI;
-- 09-Aug-2010 Vipindas T.P. ,vipindas.thekkepurakkal@in.tesco.com CR354 End
--------------------------------------------------------------------------------------------------------
END INVC_ATTRIB_SQL;
/

