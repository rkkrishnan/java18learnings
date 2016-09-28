CREATE OR REPLACE PACKAGE BODY INVC_MATCH_SQL AS
-----------------------------------------------------------------------------------------
FUNCTION CHECK_ASSOC(O_error_message   IN OUT   VARCHAR2,
                     I_rcpt            IN       shipment.shipment%TYPE)
   RETURN BOOLEAN is

BEGIN
   if I_rcpt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_rcpt',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('INSERT', NULL, 'invc_match_queue', 'shipment: '||to_char(I_rcpt));
   insert into invc_match_queue (invc_id)
      select distinct ix.invc_id
        from invc_xref ix, shipment s
       where s.shipment = I_rcpt
         and (ix.shipment = s.shipment
          or (apply_to_future_ind = 'Y'
              and (   (s.order_no = ix.order_no
                       and ix.location is NULL)
                   or (s.order_no = ix.order_no
                       and ix.location = s.to_loc)
                   or (s.asn = ix.asn
                       and ix.location is NULL)
                   or (s.asn = ix.asn
                       and ix.location = s.to_loc))))
         and not exists (select 'x'
                           from invc_match_queue imq
                          where imq.invc_id = ix.invc_id);

   SQL_LIB.SET_MARK('INSERT', NULL, 'invc_xref', 'shipment: '||to_char(I_rcpt));
   insert into invc_xref (invc_id,
                          order_no,
                          shipment,
                          asn,
                          location,
                          loc_type,
                          apply_to_future_ind)
      select distinct ix.invc_id,
             s.order_no,
             I_rcpt,
             s.asn,
             s.to_loc,
             s.to_loc_type,
             'N'
        from shipment s, invc_xref ix
       where s.shipment = I_rcpt
         and apply_to_future_ind = 'Y'
              and (   (s.order_no = ix.order_no
                       and ix.location is NULL)
                   or (s.order_no = ix.order_no
                       and ix.location = s.to_loc)
                   or (s.asn = ix.asn
                       and ix.location is NULL)
                   or (s.asn = ix.asn
                       and ix.location = s.to_loc))
         and not exists (select 'x'
                           from invc_xref
                          where shipment = I_rcpt
                            and invc_id = ix.invc_id);

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.CHECK_ASSOC',
                                             to_char(SQLCODE));
   return FALSE;
END CHECK_ASSOC;
-----------------------------------------------------------------------------------------
FUNCTION CHECK_TOLERANCE(O_error_message     IN OUT   VARCHAR2,
                         O_in_tolerance      IN OUT   BOOLEAN,
                         I_supplier          IN       sup_tolerance.supplier%TYPE,
                         I_tolerance_level   IN       sup_tolerance.tolerance_level%TYPE,
                         I_invc_value        IN       invc_head.total_merch_cost%TYPE,
                         I_rcpt_value        IN       invc_head.total_merch_cost%TYPE)
   RETURN BOOLEAN is

   L_in_tolerance      BOOLEAN := TRUE;
   L_tolerance_favor   sup_tolerance.tolerance_favor%TYPE;
   L_tolerance_type    sup_tolerance.tolerance_type%TYPE := NULL;

   cursor C_GET_TOL_VALUES is
      select tolerance_type, tolerance_value
        from sup_tolerance
       where supplier = I_supplier
         and tolerance_level = I_tolerance_level
         and tolerance_favor = L_tolerance_favor
         and lower_limit <= I_invc_value
         and upper_limit >= I_invc_value;

BEGIN
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_supplier',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_tolerance_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_tolerance_level',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_invc_value is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_value',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_rcpt_value is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_rcpt_value',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_rcpt_value < 0 or I_invc_value < 0 then
      O_in_tolerance := FALSE;
      return TRUE;
   elsif I_rcpt_value = I_invc_value then
      O_in_tolerance := TRUE;
      return TRUE;
   elsif I_rcpt_value > I_invc_value then
      L_tolerance_favor := 'R';
   elsif I_invc_value > I_rcpt_value then
      L_tolerance_favor := 'S';
   end if;

   for rec in C_GET_TOL_VALUES LOOP
      L_tolerance_type := rec.tolerance_type;
      ---
      if rec.tolerance_type = 'A' then
         ---
         if ABS(I_rcpt_value - I_invc_value) > rec.tolerance_value then
            L_in_tolerance := FALSE;
         end if;
         ---
      elsif rec.tolerance_type = 'P' then
         ---
         if L_tolerance_favor = 'S' then
            ---
            if ((I_invc_value - I_rcpt_value)/I_invc_value) * 100 > rec.tolerance_value then
               L_in_tolerance := FALSE;
            end if;
            ---
         else
            ---
            if ((I_rcpt_value - I_invc_value)/I_invc_value) * 100 > rec.tolerance_value then
               L_in_tolerance := FALSE;
            end if;
            ---
         end if;
         ---
      end if;
   end LOOP;

   if L_tolerance_type is NULL then
      L_in_tolerance := FALSE;
   end if;

   O_in_tolerance := L_in_tolerance;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.CHECK_TOLERANCE',
                                             to_char(SQLCODE));
   return FALSE;
END CHECK_TOLERANCE;
-----------------------------------------------------------------------------------------
FUNCTION CHECK_DETAILS(O_error_message   IN OUT   VARCHAR2,
                       O_reconciled      IN OUT   BOOLEAN,
                       I_invc_id         IN       invc_head.invc_id%TYPE)
   RETURN BOOLEAN is

   L_total_merch_cost     invc_head.total_merch_cost%TYPE;
   L_total_qty            invc_head.total_qty%TYPE;
   L_invc_date            invc_head.invc_date%TYPE;
   L_total_detail_cost    invc_detail.invc_unit_cost%TYPE;
   L_total_detail_qty     invc_detail.invc_qty%TYPE;
   L_match_mult_sup_ind   system_options.invc_match_mult_sup_ind%TYPE;
   L_match_qty_ind        system_options.invc_match_qty_ind%TYPE;
   L_vat_ind              system_options.vat_ind%TYPE;
   L_total_vat            invc_head.total_merch_cost%TYPE;
   L_total_detail_vat     invc_detail.invc_unit_cost%TYPE;

   cursor C_GET_HEAD_INFO is
      select total_merch_cost, total_qty, invc_date
        from invc_head
       where invc_id = I_invc_id;

   cursor C_CHECK_DETAIL is
      select SUM(invc_unit_cost * invc_qty),
             SUM(invc_qty),
             SUM(invc_unit_cost * invc_qty * NVL(invc_vat_rate/100, 0))
        from invc_detail
       where invc_id = I_invc_id;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   /* Retrieve cost and quantity information */
   SQL_LIB.SET_MARK('OPEN', 'C_GET_HEAD_INFO', 'invc_head', 'invc_id: '||to_char(I_invc_id));
   open C_GET_HEAD_INFO;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_GET_HEAD_INFO', 'invc_head', 'invc_id: '||to_char(I_invc_id));
   fetch C_GET_HEAD_INFO into L_total_merch_cost,
                              L_total_qty,
                              L_invc_date;
   ---
   if C_GET_HEAD_INFO%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_GET_HEAD_INFO', 'invc_head', 'invc_id: '||to_char(I_invc_id));
      close C_GET_HEAD_INFO;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO',
                                             NULL,
                                             NULL,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_HEAD_INFO', 'invc_head', 'invc_id: '||to_char(I_invc_id));
   close C_GET_HEAD_INFO;

   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_DETAIL', 'invc_detail', 'invc_id: '||to_char(I_invc_id));
   open C_CHECK_DETAIL;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_CHECK_DETAIL', 'invc_detail', 'invc_id: '||to_char(I_invc_id));
   fetch C_CHECK_DETAIL into L_total_detail_cost,
                             L_total_detail_qty,
                             L_total_detail_vat;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_DETAIL', 'invc_detail', 'invc_id: '||to_char(I_invc_id));
   close C_CHECK_DETAIL;

   /* Compare the total cost of the detail records to the total cost of */
   /* the header record */
   if L_total_detail_cost != NVL(L_total_merch_cost, 0) then
      O_reconciled := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('TOT_COST_NOT_EQUAL',
                                             NULL,
                                             NULL,
                                             NULL);
      return TRUE;
   else
      O_reconciled := TRUE;
   end if;
   ---
   if INVC_SQL.INVC_SYSTEM_OPTIONS_INDS(O_error_message,
                                        L_match_mult_sup_ind,
                                        L_match_qty_ind) = FALSE then
      return FALSE;
   end if;

   /* If the system options checks for total qty and if a total qty exists on the header */
   /* record, then compare the total quantity of the detail records to the total quantity */
   /* of the header record */

   if L_match_qty_ind = 'Y' then
      ---
      if L_total_detail_qty != L_total_qty or
         L_total_qty is NULL then
         O_reconciled := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('TOTAL_QTY_NOT_EQUAL',
                                                NULL,
                                                NULL,
                                                NULL);
         return TRUE;
      end if;
      ---
   end if;

   /* If the system options vat indicator = 'Y' then a check needs to made on the total */
   /* header vat and the total detail vat */

   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;

   if L_vat_ind = 'Y' then
      if INVC_ATTRIB_SQL.TOTAL_INVC_MERCH_VAT(O_error_message,
                                              L_total_vat,
                                              I_invc_id,
                                              'N') = FALSE then
         return FALSE;
      end if;
      ---
      if L_total_detail_vat != L_total_vat then
         O_reconciled := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('TOTAL_VAT_NOT_EQUAL',
                                                NULL,
                                                NULL,
                                                NULL);
         return TRUE;
      end if;
      ---
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.CHECK_DETAILS',
                                             to_char(SQLCODE));
   return FALSE;
END CHECK_DETAILS;
-----------------------------------------------------------------------------------------
FUNCTION CHECK_VAT(O_error_message   IN OUT   VARCHAR2,
                   O_reconciled      IN OUT   BOOLEAN,
                   I_invc_id         IN       invc_head.invc_id%TYPE,
                   I_supplier        IN       invc_head.supplier%TYPE)
   RETURN BOOLEAN is

   L_vat_ind              system_options.vat_ind%TYPE;
   L_total_vat            invc_head.total_merch_cost%TYPE;
   L_total_qty            invc_head.total_qty%TYPE;
   L_total_cost_rcpt      shipsku.unit_cost%TYPE;
   L_vat_rcpt             shipsku.unit_cost%TYPE := 0;
   L_total_vat_rcpt       shipsku.unit_cost%TYPE := 0;
   L_cost_in_tolerance    BOOLEAN;

   cursor C_SHIPMENTS is
      select distinct shipment
        from invc_xref
       where invc_id = I_invc_id
       order by shipment;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_reconciled := TRUE;

   /* If vat_ind is 'Y', then perform a check for vat invoice and vat receipt*/
   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;
   ---
   if L_vat_ind = 'Y' then
      if INVC_ATTRIB_SQL.TOTAL_INVC_MERCH_VAT(O_error_message,
                                              L_total_vat,
                                              I_invc_id,
                                              'N') = FALSE then
         return FALSE;
      end if;
      ---
      for rec in C_SHIPMENTS LOOP
         if rec.shipment is not NULL then
            if INVC_ATTRIB_SQL.GET_MATCH_RCPT_TOTALS (O_error_message,
                                                      L_total_qty,
                                                      L_total_cost_rcpt,
                                                      L_vat_rcpt,
                                                      I_invc_id,
                                                      rec.shipment) = FALSE then
               return FALSE;
            end if;
            ---
            L_total_vat_rcpt := L_total_vat_rcpt + L_vat_rcpt;
         end if;
      end LOOP;
      ---
      if INVC_MATCH_SQL.CHECK_TOLERANCE (O_error_message,
                                         L_cost_in_tolerance,
                                         I_supplier,
                                         'TC',
                                         L_total_vat,
                                         L_total_vat_rcpt) = FALSE then
         return FALSE;
      end if;
      ---
      if L_cost_in_tolerance = FALSE then
         O_reconciled := FALSE;
         O_error_message := SQL_LIB.CREATE_MSG('TOTAL_VAT_SUM_NOT_EQUAL',
                                                NULL,
                                                NULL,
                                                NULL);
      else
         O_reconciled := TRUE;
      end if;
   end if;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.CHECK_VAT',
                                             to_char(SQLCODE));
   return FALSE;
END CHECK_VAT;
-----------------------------------------------------------------------------------------
FUNCTION ITEM_MATCH_ALL(O_error_message   IN OUT   VARCHAR2,
                        O_match           IN OUT   BOOLEAN,
                        IO_reconciled     IN OUT   BOOLEAN,
                        I_invc_id         IN       invc_head.invc_id%TYPE,
                        I_user_id         IN       VARCHAR2,
                        I_supplier        IN       invc_head.supplier%TYPE,
                        I_vat_region      IN       vat_item.vat_region%TYPE)
   RETURN BOOLEAN is

   L_table           VARCHAR2(30);
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);
   L_dummy           VARCHAR2(1);
   L_supplier        invc_head.supplier%TYPE := I_supplier;
   L_reconciled      BOOLEAN;
   L_match           BOOLEAN := FALSE;

   cursor C_CHECK_ASSOC_EXISTS is
      select 'x'
        from invc_xref
       where invc_id = I_invc_id;

   cursor C_GET_SUPPLIER is
      select supplier
        from invc_head
       where invc_id = I_invc_id;

   cursor C_GET_INVC_INFO is
      select item,
             invc_unit_cost,
             invc_qty,
             invc_vat_rate
        from invc_detail id
       where invc_id = I_invc_id
         and status = 'U';

   cursor C_SHIPMENTS is
      select distinct ssk.shipment
        from invc_detail id, shipsku ssk, invc_match_wksht imw
       where id.invc_id = I_invc_id
         and id.invc_id = imw.invc_id
         and id.item = imw.item
         and id.invc_unit_cost = imw.invc_unit_cost
         and imw.item = ssk.item
         and imw.shipment = ssk.shipment
         and (imw.carton = ssk.carton
              or (imw.carton is NULL and ssk.carton is NULL))
         and (ssk.match_invc_id = I_invc_id
              or ssk.match_invc_id is NULL);

   cursor C_LOCK_INVC_TOLERANCE is
      select 'x'
        from invc_tolerance
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_INVC_HEAD is
      select 'x'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_user_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_ASSOC_EXISTS', 'invc_xref', 'invc_id: '||to_char(I_invc_id));
   open C_CHECK_ASSOC_EXISTS;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_CHECK_ASSOC_EXISTS', 'invc_xref', 'invc_id: '||to_char(I_invc_id));
   fetch C_CHECK_ASSOC_EXISTS into L_dummy;
   ---
   if C_CHECK_ASSOC_EXISTS%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_ASSOC_EXISTS', 'invc_xref', 'invc_id: '||to_char(I_invc_id));
      close C_CHECK_ASSOC_EXISTS;
      ---
      O_error_message := SQL_LIB.CREATE_MSG('MUST_ASSOC_INVC_SHIPMENT',
                                             to_char(I_invc_id),
                                             NULL,
                                             NULL);
      return FALSE;
      ---
   end if;
   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_ASSOC_EXISTS', 'invc_xref', 'invc_id: '||to_char(I_invc_id));
   close C_CHECK_ASSOC_EXISTS;

   if IO_reconciled != TRUE or
      IO_reconciled is NULL then
      ---
      if INVC_MATCH_SQL.CHECK_DETAILS(O_error_message,
                                      IO_reconciled,
                                      I_invc_id) = FALSE then
         return FALSE;
      end if;
      ---
      if IO_reconciled = FALSE then
         return TRUE;
         ---
      end if;
      ---
   end if;

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

   -- Since this match is at the detail level, delete any summary records
   -- that may have previously been written to the invc_tolerance table
   L_table := 'INVC_TOLERANCE';
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_INVC_TOLERANCE',
                    'INVC_TOLERANCE',
                    'INVOICE:'||to_char(I_invc_id));
   open C_LOCK_INVC_TOLERANCE;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_INVC_TOLERANCE',
                    'INVC_TOLERANCE',
                    'INVOICE:'||to_char(I_invc_id));
   close C_LOCK_INVC_TOLERANCE;

   SQL_LIB.SET_MARK('DELETE',
                     NULL,
                    'INVC_TOLERANCE',
                    'INVOICE: '||to_char(I_invc_id));

      delete invc_tolerance
       where invc_id = I_invc_id
         and item is NULL;

   for rec in C_GET_INVC_INFO LOOP
      if INVC_MATCH_SQL.ITEM_MATCH(O_error_message,
                                   L_match,
                                   IO_reconciled,
                                   I_invc_id,
                                   I_user_id,
                                   rec.item,
                                   rec.invc_unit_cost,
                                   rec.invc_qty,
                                   L_supplier,
                                   FALSE,
                                   I_vat_region,
                                   rec.invc_vat_rate,
                                   NULL) = FALSE then
         return FALSE;
      end if;
      ---
      if L_match = FALSE then
         O_match := FALSE;
      end if;
      L_match := FALSE;
   end LOOP;

   if O_match = FALSE then
      ---
      L_table := 'INVC_HEAD';
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(I_invc_id));
      open C_LOCK_INVC_HEAD;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(I_invc_id));
      close C_LOCK_INVC_HEAD;
      ---
      SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_head', 'invc_id: '||to_char(I_invc_id));
      update invc_head
         set match_fail_ind = 'Y'
       where invc_id = I_invc_id;
      ---
   end if;

   if INVC_SQL.UPDATE_STATUSES(O_error_message,
                               I_invc_id,
                               NULL,
                               I_user_id,
                               NULL) = FALSE then
      return FALSE;
   end if;

   for rec in C_SHIPMENTS LOOP
      if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                  NULL,
                                  rec.shipment,
                                  I_user_id,
                                  NULL) = FALSE then
         return FALSE;
      end if;
   end LOOP;

   if O_match is NULL then
      O_match := TRUE;
   else
      O_match := FALSE;
   end if;

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
                                            'INVC_MATCH_SQL.ITEM_MATCH_ALL',
                                             to_char(SQLCODE));
   return FALSE;
END ITEM_MATCH_ALL;
-----------------------------------------------------------------------------------------
FUNCTION ITEM_MATCH(O_error_message   IN OUT   VARCHAR2,
                    O_match           IN OUT   BOOLEAN,
                    IO_reconciled     IN OUT   BOOLEAN,
                    I_invc_id         IN       invc_match_wksht.invc_id%TYPE,
                    I_user_id         IN       VARCHAR2,
                    I_item            IN       invc_match_wksht.item%TYPE,
                    I_invc_cost       IN       invc_detail.invc_unit_cost%TYPE,
                    I_invc_qty        IN       invc_detail.invc_qty%TYPE,
                    I_supplier        IN       invc_head.supplier%TYPE,
                    I_single_call     IN       BOOLEAN,
                    I_vat_region      IN       vat_item.vat_region%TYPE,
                    I_invc_vat_rate   IN       invc_detail.invc_vat_rate%TYPE,
                    I_rcpt_vat_rate   IN       vat_item.vat_rate%TYPE)
   RETURN BOOLEAN is

   L_table                         VARCHAR2(30);
   RECORD_LOCKED                   EXCEPTION;
   PRAGMA                          EXCEPTION_INIT(Record_Locked, -54);
   L_dummy                         VARCHAR2(1);
   L_supplier                      invc_head.supplier%TYPE := I_supplier;
   L_cost_tolerance                BOOLEAN;
   L_in_cost_tolerance             BOOLEAN := TRUE;
   L_cost_dscrpncy_ind             invc_detail.cost_dscrpncy_ind%TYPE := 'N';
   L_in_qty_tolerance              BOOLEAN;
   L_qty_dscrpncy_ind              invc_detail.qty_dscrpncy_ind%TYPE := 'N';
   L_vat_ind                       system_options.vat_ind%TYPE;
   L_invc_vat_rate                 invc_detail.invc_vat_rate%TYPE := I_invc_vat_rate;
   L_rcpt_vat_rate                 vat_item.vat_rate%TYPE := I_rcpt_vat_rate;
   L_vat_dscrpncy_ind              invc_detail.vat_dscrpncy_ind%TYPE := 'N';
   L_vat_region                    vat_region.vat_region%TYPE := I_vat_region;
   L_rcpt_order_no                 shipment.order_no%TYPE;
   L_invc_date                     invc_head.invc_date%TYPE;
   L_vat_code                      vat_item.vat_code%TYPE;
   L_status                        invc_detail.status%TYPE;
   L_converted_unit_cost           shipsku.unit_cost%TYPE;
   L_cost                          invc_match_wksht.match_to_cost%TYPE := 0;
   L_total_cost                    invc_match_wksht.match_to_cost%TYPE := 0;
   L_qty                           invc_match_wksht.match_to_qty%TYPE  := 0;
   L_total_qty                     invc_match_wksht.match_to_qty%TYPE  := 0;
   L_data_found                    VARCHAR2(1)  := 'N';
   L_ship_extended_cost            invc_tolerance.total_cost%TYPE := 0;
   L_seq_no                        invc_tolerance.seq_no%TYPE;
   L_rowid                         ROWID;
   L_unit_cost_ord                 ORDLOC_INVC_COST.UNIT_COST%TYPE;
   L_order_curr                    ORDHEAD.CURRENCY_CODE%TYPE;
   L_order_exch                    ORDHEAD.EXCHANGE_RATE%TYPE;
   L_invc_curr                     INVC_HEAD.CURRENCY_CODE%TYPE;
   L_invc_exch                     INVC_HEAD.EXCHANGE_RATE%TYPE;

   cursor C_CHECK_ASSOC_EXISTS is
      select 'x'
        from invc_xref
       where invc_id = I_invc_id;

   cursor C_GET_SUPPLIER is
      select supplier
        from invc_head
       where invc_id = I_invc_id;

   cursor C_GET_RCPT_COST is
      select NVL(match_to_cost,0) match_to_cost,
             NVL(match_to_qty,0) match_to_qty
        from invc_match_wksht
       where invc_id = I_invc_id
         and item = I_item
         and invc_unit_cost = I_invc_cost;

   cursor C_INVC_VAT_RATE is
      select invc_vat_rate
        from invc_detail
       where invc_id = I_invc_id
         and item = I_item
         and invc_unit_cost = I_invc_cost;

   cursor C_RCPT_ORDER_AND_DATE is
      select ih.invc_date, ix.order_no
        from invc_head ih, invc_xref ix
       where ih.invc_id = ix.invc_id
         and ih.invc_id = I_invc_id;

   cursor C_SHIP_CARTON is
      select imw.shipment,
             imw.carton,
             s.to_loc
        from invc_match_wksht imw, shipment s
       where invc_id = I_invc_id
         and item = I_item
         and invc_unit_cost = I_invc_cost
         and imw.shipment = s.shipment;

   cursor C_SHIPMENTS is
      select distinct ssk.shipment
        from shipsku ssk, invc_match_wksht imw
       where ssk.item = imw.item
         and ssk.shipment = imw.shipment
         and (ssk.carton = imw.carton
              or (ssk.carton is NULL and imw.carton is NULL))
         and imw.invc_id = I_invc_id
         and imw.item = I_item
         and imw.invc_unit_cost = I_invc_cost
         and (ssk.match_invc_id = I_invc_id
              or ssk.match_invc_id is NULL);

   cursor C_LOCK_INVC_DETAIL is
      select 'x'
        from invc_detail
       where invc_id = I_invc_id
         and item = I_item
         and invc_unit_cost = I_invc_cost
         for update nowait;

   cursor C_LOCK_INVC_TOLERANCE is
      select 'x'
        from invc_tolerance
       where invc_id = I_invc_id
         and item = I_item
         and rowid = L_rowid
         for update nowait;

   cursor C_LOCK_INVC_HEAD is
      select 'x'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_SHIPSKU_UNMATCH is
      select 'x'
        from shipsku ssk
       where ssk.item = I_item
         and ssk.match_invc_id = I_invc_id
         and exists (select 'x'
                       from invc_match_wksht imw
                      where ssk.shipment = imw.shipment
                        and (ssk.carton = imw.carton
                             or (ssk.carton is NULL and imw.carton is NULL))
                        and ssk.item = imw.item
                        and imw.invc_id = I_invc_id
                        and imw.item = I_item
                        and imw.invc_unit_cost = I_invc_cost)
         for update nowait;

   cursor C_LOCK_SHIPSKU_MATCH is
      select 'x'
        from shipsku ssk
       where ssk.item = I_item
         and ssk.match_invc_id is NULL
         and exists (select 'x'
                       from invc_match_wksht imw
                      where ssk.shipment = imw.shipment
                        and (ssk.carton = imw.carton
                             or (ssk.carton is NULL and imw.carton is NULL))
                        and ssk.item = imw.item
                        and imw.invc_id = I_invc_id
                        and imw.item = I_item
                        and imw.invc_unit_cost = I_invc_cost)
         for update nowait;

   cursor C_GET_CURRENCY_INFO is
      select ih.currency_code,
             ih.exchange_rate,
             oh.currency_code,
             oh.exchange_rate
        from invc_head ih,
             ordhead oh,
             invc_match_wksht imw,
             shipment s
       where ih.invc_id         = imw.invc_id
         and imw.shipment       = s.shipment
         and s.order_no         = oh.order_no
         and ih.invc_id         = I_invc_id
         and imw.item           = I_item
         and imw.invc_unit_cost = I_invc_cost;

   cursor C_LOCK_OIC_UNMATCH is
      select 'x'
        from ordloc_invc_cost oic
       where oic.item          = I_item
         and oic.match_invc_id = I_invc_id
         and exists (select 'x'
                       from invc_match_wksht imw, shipment s
                      where oic.shipment       = imw.shipment
                        and (oic.carton        = imw.carton
                             or (oic.carton is NULL and imw.carton is NULL))
                        and oic.item           = imw.item
                        and oic.seq_no         = imw.match_to_seq_no
                        and s.shipment         = imw.shipment
                        and s.to_loc           = oic.location
                        and imw.invc_id        = I_invc_id
                        and imw.item           = I_item
                        and imw.invc_unit_cost = I_invc_cost)
         for update nowait;

   cursor C_LOCK_OIC_MATCH is
      select 'x'
        from ordloc_invc_cost oic
       where oic.item = I_item
         and oic.match_invc_id is NULL
         and exists (select 'x'
                       from invc_match_wksht imw, shipment s
                      where oic.shipment       = imw.shipment
                        and (oic.carton        = imw.carton
                             or (oic.carton is NULL and imw.carton is NULL))
                        and oic.item           = imw.item
                        and oic.seq_no         = imw.match_to_seq_no
                        and s.shipment         = imw.shipment
                        and s.to_loc           = oic.location
                        and imw.invc_id        = I_invc_id
                        and imw.item           = I_item
                        and imw.invc_unit_cost = I_invc_cost)
         for update nowait;

   cursor C_INVC_TOLERANCE_SEQ_NO is
      select nvl(max(seq_no),0)
        from invc_tolerance
       where invc_id = I_invc_id;

   cursor C_INVC_TOLERANCE_EXISTS is
      select rowid
        from invc_tolerance
       where invc_id = I_invc_id
         and item = I_item;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_user_id',
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

   if I_invc_cost is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_cost',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_invc_qty is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_qty',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_single_call is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_single_call',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_single_call = TRUE then
      ---
      SQL_LIB.SET_MARK('OPEN', 'C_CHECK_ASSOC_EXISTS', 'invc_xref', 'invc_id: '||to_char(I_invc_id));
      open C_CHECK_ASSOC_EXISTS;
      ---
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_ASSOC_EXISTS', 'invc_xref', 'invc_id: '||to_char(I_invc_id));
      fetch C_CHECK_ASSOC_EXISTS into L_dummy;
      ---
      if C_CHECK_ASSOC_EXISTS%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_ASSOC_EXISTS', 'invc_xref', 'invc_id: '||to_char(I_invc_id));
         close C_CHECK_ASSOC_EXISTS;
         ---
         O_error_message := SQL_LIB.CREATE_MSG('MUST_ASSOC_INVC_SHIPMENT',
                                                to_char(I_invc_id),
                                                NULL,
                                                NULL);
         return FALSE;
         ---
      end if;
      SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_ASSOC_EXISTS', 'invc_xref', 'invc_id: '||to_char(I_invc_id));
      close C_CHECK_ASSOC_EXISTS;
      ---
      if INVC_MATCH_SQL.CHECK_DETAILS(O_error_message,
                                      IO_reconciled,
                                      I_invc_id) = FALSE then
         return FALSE;
      end if;
      ---
      if IO_reconciled = FALSE then
         return TRUE;
      end if;
      ---
   end if;

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
   -- Check if the line item's unit cost match within tolerance
   -- Set O_match to NULL so that a FALSE value will only be returned
   --    if a tolerance is violated.
   O_match := NULL;
   SQL_LIB.SET_MARK('OPEN', 'C_GET_RCPT_COST', 'invc_match_wksht', 'invc_id: '||to_char(I_invc_id));
   open C_GET_RCPT_COST;
   LOOP
      SQL_LIB.SET_MARK('FETCH', 'C_GET_RCPT_COST', 'invc_match_wksht', 'invc_id: '||to_char(I_invc_id));
      fetch C_GET_RCPT_COST into L_cost,
                                 L_qty;
      ---
      if C_GET_RCPT_COST%NOTFOUND then
         if L_data_found = 'N' then
            O_match := FALSE;
            L_cost_dscrpncy_ind := 'Y';
            L_qty_dscrpncy_ind := 'Y';
         end if;
         EXIT;
      end if;
      ---
      L_total_qty := L_total_qty + L_qty;
      ---
      -- Calculate the total extended cost for the shipments
      L_ship_extended_cost := L_ship_extended_cost + (L_cost * L_qty);
      ---
      L_data_found := 'Y';
      if INVC_MATCH_SQL.CHECK_TOLERANCE(O_error_message,
                                        L_cost_tolerance,
                                        L_supplier,
                                        'LC',
                                        I_invc_cost,
                                        L_cost) = FALSE then
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_RCPT_COST', 'invc_match_wksht', 'invc_id: '||to_char(I_invc_id));
         close C_GET_RCPT_COST;
         return FALSE;
      end if;
      ---
      if L_cost_tolerance = FALSE then
         L_in_cost_tolerance := FALSE;
         L_cost_dscrpncy_ind := 'Y';
         O_match := FALSE;
      end if;
      ---
   END LOOP;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_RCPT_COST', 'invc_match_wksht', 'invc_id: '||to_char(I_invc_id));
   close C_GET_RCPT_COST;
   ---
   if INVC_MATCH_SQL.CHECK_TOLERANCE(O_error_message,
                                     L_in_qty_tolerance,
                                     L_supplier,
                                     'LQ',
                                     I_invc_qty,
                                     L_total_qty) = FALSE then
      return FALSE;
   end if;
   ---
   if L_in_qty_tolerance = FALSE then
      L_qty_dscrpncy_ind := 'Y';
      O_match := FALSE;
   end if;

   -- If no FALSE values were returned O_match will still be NULL
   -- Therefore, set O_match to TRUE
   if O_match is NULL then
      O_match := TRUE;
   end if;

   /* Check if the invoice line item's vat rate is the same as the receipt's vat rate */
   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then
      return FALSE;
   end if;

   if L_vat_ind = 'Y' then
      ---
      if L_invc_vat_rate is NULL then
         SQL_LIB.SET_MARK('OPEN', 'C_INVC_VAT_RATE', 'invc_detail',
                          'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
         open C_INVC_VAT_RATE;
         ---
         SQL_LIB.SET_MARK('FETCH', 'C_INVC_VAT_RATE', 'invc_detail',
                          'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
         fetch C_INVC_VAT_RATE into L_invc_vat_rate;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_INVC_VAT_RATE', 'invc_detail',
                          'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
         close C_INVC_VAT_RATE;
      end if;

      if L_rcpt_vat_rate is NULL then
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_RCPT_ORDER_AND_DATE', 'invc_head, invc_xref', 'invc_id: '||to_char(I_invc_id));
         open C_RCPT_ORDER_AND_DATE;
         ---
         SQL_LIB.SET_MARK('FETCH', 'C_RCPT_ORDER_AND_DATE', 'invc_head, invc_xref', 'invc_id: '||to_char(I_invc_id));
         fetch C_RCPT_ORDER_AND_DATE into L_invc_date, L_rcpt_order_no;
         ---
         if C_RCPT_ORDER_AND_DATE%NOTFOUND then
            SQL_LIB.SET_MARK('CLOSE', 'C_RCPT_ORDER_AND_DATE', 'invc_head, invc_xref', 'invc_id: '||to_char(I_invc_id));
            close C_RCPT_ORDER_AND_DATE;
            ---
            O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_INVC_INFO',
                                                   NULL,
                                                   NULL,
                                                   NULL);
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_RCPT_ORDER_AND_DATE', 'invc_head, invc_xref', 'invc_id: '||to_char(I_invc_id));
         close C_RCPT_ORDER_AND_DATE;

         if L_vat_region is NULL then
            ---
            if VAT_SQL.GET_VAT_REGION(O_error_message,
                                      L_vat_region,
                                      I_invc_id,
                                      L_rcpt_order_no) = FALSE then
               return FALSE;
            end if;
            ---
         end if;
         ---
         if L_vat_region is NOT NULL then
            ---
            if VAT_SQL.GET_VAT_RATE(O_error_message,
                                    L_vat_region,
                                    L_vat_code,  --- NULL
                                    L_rcpt_vat_rate,
                                    I_item,
                                    NULL,   --- dept
                                    NULL,   --- loc_type
                                    NULL,   --- location
                                    L_invc_date,
                                    'C') = FALSE then
               return FALSE;
            end if;
            ---
         end if;
         ---
      end if; /* if L_rcpt_invc_value is NULL */
      ---
      if NVL(L_rcpt_vat_rate,0) != NVL(L_invc_vat_rate, 0) then
         L_vat_dscrpncy_ind := 'Y';
         O_match := FALSE;
      end if;
      ---
   end if; /* if L_vat_ind = 'Y' */

   if O_match = FALSE then
      L_status := 'U';
   else
      L_status := 'M';
      ---
      -- If the total extended cost for the shipments is different than the
      -- extended cost for the invoice, either update the invc_tolerance
      -- table with the difference or insert a new row into invc_tolerance.
      if (I_invc_cost * I_invc_qty) != L_ship_extended_cost then
         SQL_LIB.SET_MARK('OPEN', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                          'invc_id: '||to_char(I_invc_id)||
                          ', item: '||I_item);
         open C_INVC_TOLERANCE_EXISTS;
         ---
         SQL_LIB.SET_MARK('FETCH', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                          'invc_id: '||to_char(I_invc_id)||
                          ', item: '||I_item);
         fetch C_INVC_TOLERANCE_EXISTS into L_rowid;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_INVC_TOLERANCE_EXISTS', 'invc_tolerance',
                          'invc_id: '||to_char(I_invc_id)||
                          ', item: '||I_item);
         close C_INVC_TOLERANCE_EXISTS;
         ---
         if L_rowid is not NULL then
            L_table := 'INVC_TOLERANCE';
            SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_TOLERANCE', 'invc_tolerance',
                             'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', rowid: '||to_char(L_rowid));
            open C_LOCK_INVC_TOLERANCE;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_TOLERANCE', 'invc_tolerance',
                             'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', rowid: '||to_char(L_rowid));
            close C_LOCK_INVC_TOLERANCE;
            ---
            SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_tolerance',
                             'invc_id: '||to_char(I_invc_id)||
                             ', item: '||I_item);
            update invc_tolerance
               set total_cost = total_cost + ((I_invc_cost * I_invc_qty) - L_ship_extended_cost)
             where rowid = L_rowid
               and invc_id = I_invc_id
               and item = I_item;
         else
            SQL_LIB.SET_MARK('OPEN', 'C_INVC_TOLERANCE_SEQ_NO', 'invc_tolerance',
                             'invc_id: '||to_char(I_invc_id));
            open C_INVC_TOLERANCE_SEQ_NO;
            ---
            SQL_LIB.SET_MARK('FETCH', 'C_INVC_TOLERANCE_SEQ_NO', 'invc_tolerance',
                             'invc_id: '||to_char(I_invc_id));
            fetch C_INVC_TOLERANCE_SEQ_NO into L_seq_no;
            ---
            SQL_LIB.SET_MARK('CLOSE', 'C_INVC_TOLERANCE_SEQ_NO', 'invc_tolerance',
                             'invc_id: '||to_char(I_invc_id));
            close C_INVC_TOLERANCE_SEQ_NO;
            ---
            SQL_LIB.SET_MARK('INSERT', NULL, 'invc_tolerance',
                             'invc_id: '||to_char(I_invc_id)||
                             ', item: '||I_item);
            insert into invc_tolerance (invc_id,
                                        seq_no,
                                        item,
                                        total_cost)
               values(I_invc_id,
                      L_seq_no + 1,
                      I_item,
                      (I_invc_cost * I_invc_qty) - L_ship_extended_cost);
         end if;
      end if;
   end if;


   L_table := 'INVC_DETAIL';
   SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_DETAIL', 'invc_detail',
                    'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
   open C_LOCK_INVC_DETAIL;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_DETAIL', 'invc_detail',
                    'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
   close C_LOCK_INVC_DETAIL;
   ---
   SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_detail',
                    'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
   update invc_detail
      set status = L_status,
          cost_dscrpncy_ind = L_cost_dscrpncy_ind,
          qty_dscrpncy_ind = L_qty_dscrpncy_ind,
          vat_dscrpncy_ind = L_vat_dscrpncy_ind
    where invc_id = I_invc_id
      and item = I_item
      and invc_unit_cost = I_invc_cost;
   ---
   SQL_LIB.SET_MARK('OPEN', 'C_GET_CURRENCY_INFO', 'ordhead, invc_head',
                    'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
   open C_GET_CURRENCY_INFO;
   SQL_LIB.SET_MARK('FETCH', 'C_GET_CURRENCY_INFO', 'ordhead, invc_head',
                    'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
   fetch C_GET_CURRENCY_INFO into L_invc_curr,
                                  L_invc_exch,
                                  L_order_curr,
                                  L_order_exch;
   SQL_LIB.SET_MARK('CLOSE', 'C_GET_CURRENCY_INFO', 'ordhead, invc_head',
                    'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
   close C_GET_CURRENCY_INFO;
   ---
   if NVL(L_invc_curr,'1') != NVL(L_order_curr,'1') then
      if CURRENCY_SQL.CONVERT(O_error_message,
                              I_invc_cost,
                              L_invc_curr,
                              L_order_curr,
                              L_unit_cost_ord,
                              'C',
                              NULL,
                              NULL,
                              L_invc_exch,
                              L_order_exch) = FALSE then
         return FALSE;
      end if;
   else
      L_unit_cost_ord := I_invc_cost;
   end if;
   ---
   if O_match = FALSE then
      if I_single_call = TRUE then
         L_table := 'INVC_HEAD';
         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(I_invc_id));
         open C_LOCK_INVC_HEAD;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(I_invc_id));
         close C_LOCK_INVC_HEAD;
         ---
         SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_head', 'invc_id: '||to_char(I_invc_id));
         update invc_head
            set match_fail_ind = 'Y'
          where invc_id = I_invc_id;
      end if;
      ---
      L_table := 'SHIPSKU';
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHIPSKU_UNMATCH', 'shipsku, invc_match_wksht',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      open C_LOCK_SHIPSKU_UNMATCH;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHIPSKU_UNMATCH', 'shipsku, invc_match_wksht',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      close C_LOCK_SHIPSKU_UNMATCH;
      ---
      SQL_LIB.SET_MARK('UPDATE', NULL, 'shipsku',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      ---
      L_table := 'ORDLOC_INVC_COST';
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_OIC_UNMATCH', 'ordloc_invc_cost, invc_match_wksht',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      open C_LOCK_OIC_UNMATCH;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_OIC_UNMATCH', 'ordloc_invc_cost, invc_match_wksht',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      close C_LOCK_OIC_UNMATCH;
      ---
      SQL_LIB.SET_MARK('UPDATE', NULL, 'ordloc_invc_cost',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      ---
      for rec in C_SHIP_CARTON LOOP
         update shipsku
            set match_invc_id = NULL
          where shipment      = rec.shipment
            and (carton       = rec.carton
                 or (carton is NULL and rec.carton is NULL))
            and item          = I_item
            and match_invc_id = I_invc_id;

         update ordloc_invc_cost
            set match_invc_id = NULL
          where shipment      = rec.shipment
            and (carton       = rec.carton
                 or (carton is NULL and rec.carton is NULL))
            and location      = rec.to_loc
            and item          = I_item
            and match_invc_id = I_invc_id
            and unit_cost     = L_unit_cost_ord;
      end LOOP;
   else
      if I_single_call = TRUE then
         L_table := 'INVC_HEAD';
         SQL_LIB.SET_MARK('OPEN', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(I_invc_id));
         open C_LOCK_INVC_HEAD;
         ---
         SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_INVC_HEAD', 'invc_head', 'invc_id: '||to_char(I_invc_id));
         close C_LOCK_INVC_HEAD;
         ---
         SQL_LIB.SET_MARK('UPDATE', NULL, 'invc_head', 'invc_id: '||to_char(I_invc_id));
         update invc_head
            set match_fail_ind = 'N'
          where invc_id = I_invc_id;
      end if;
      ---
      L_table := 'SHIPSKU';
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHIPSKU_MATCH', 'shipsku, invc_match_wksht',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      open C_LOCK_SHIPSKU_MATCH;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHIPSKU_MATCH', 'shipsku, invc_match_wksht',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      close C_LOCK_SHIPSKU_MATCH;
      ---
      SQL_LIB.SET_MARK('UPDATE', NULL, 'shipsku',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      ---
      L_table := 'ORDLOC_INVC_COST';
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_OIC_MATCH', 'ordloc_invc_cost, invc_match_wksht',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      open C_LOCK_OIC_MATCH;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_OIC_MATCH', 'ordloc_invc_cost, invc_match_wksht',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      close C_LOCK_OIC_MATCH;
      ---
      SQL_LIB.SET_MARK('UPDATE', NULL, 'ordloc_invc_cost',
                       'invc_id: '||to_char(I_invc_id)||', item: '||I_item||', invc_unit_cost: '||to_char(I_invc_cost));
      ---
      for rec in C_SHIP_CARTON LOOP
         update shipsku
            set match_invc_id = I_invc_id
          where shipment      = rec.shipment
            and (carton       = rec.carton
                 or (carton is NULL and rec.carton is NULL))
            and item          = I_item
            and match_invc_id is NULL;

         update ordloc_invc_cost
            set match_invc_id = I_invc_id
          where shipment      = rec.shipment
            and (carton       = rec.carton
                 or (carton is NULL and rec.carton is NULL))
            and location      = rec.to_loc
            and item          = I_item
            and unit_cost     = L_unit_cost_ord
            and match_invc_id is NULL;
      end LOOP;
   end if;

   if I_single_call = TRUE then
      ---
      if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                  I_invc_id,
                                  NULL,
                                  I_user_id,
                                  L_supplier) = FALSE then
         return FALSE;
      end if;
      ---
      for rec in C_SHIPMENTS LOOP
         if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                     NULL,
                                     rec.shipment,
                                     I_user_id,
                                     L_supplier) = FALSE then
            return FALSE;
         end if;
      end LOOP;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_invc_id),
                                             I_item);
   return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.ITEM_MATCH',
                                             to_char(SQLCODE));
   return FALSE;
END ITEM_MATCH;
-----------------------------------------------------------------------------------------
FUNCTION UNMATCH(O_error_message   IN OUT   VARCHAR2,
                 O_status          IN OUT   invc_head.status%TYPE,
                 I_invc_id         IN       invc_head.invc_id%TYPE,
                 I_rcpt            IN       shipment.shipment%TYPE,
                 I_item            IN       invc_detail.item%TYPE)
   RETURN BOOLEAN is

   L_table            VARCHAR2(30) := 'INVC_DETAIL';
   L_shipment         SHIPMENT.SHIPMENT%TYPE;
   L_invc_type        INVC_HEAD.INVC_TYPE%TYPE;
   L_item             ITEM_MASTER.ITEM%TYPE;
   L_ref_rtv_order_no INVC_HEAD.REF_RTV_ORDER_NO%TYPE;
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(Record_Locked, -54);

   cursor C_INVOICE is
      select invc_id
        from invc_head inh
       where ref_invc_id = I_invc_id
         and exists (select 'X'
                       from invc_detail ind
                      where ind.invc_id = inh.invc_id);

   cursor C_INVC_TYPE is
      select invc_type
        from invc_head
       where invc_id = I_invc_id;

   cursor C_LOCK_DETAIL is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_DETAIL_ITEM is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         and item = I_item
         for update nowait;

   cursor C_LOCK_DETAIL_ITEM2 is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         and item = L_item
         for update nowait;

   cursor C_LOCK_INVC_TOLERANCE is
      select 'X'
        from invc_tolerance
       where invc_id = I_invc_id
         and item = I_item
         for update nowait;

   cursor C_LOCK_INVC_TOLERANCE2 is
      select 'X'
        from invc_tolerance
       where invc_id = I_invc_id
         and item = L_item
         for update nowait;

   cursor C_LOCK_DETAIL_RCPT is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         and item in (select item
                        from shipsku
                       where shipment = I_rcpt
                         and match_invc_id = I_invc_id)
         for update nowait;

   cursor C_LOCK_SHIPSKU is
      select 'X'
        from shipsku
       where match_invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_ORDLOC is
      select 'X'
        from ordloc_invc_cost
       where match_invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_SHIPSKU_RCPT is
      select 'X'
        from shipsku
       where shipment = I_rcpt
         and match_invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_ORDSKU_RCPT is
      select 'X'
        from ordloc_invc_cost
       where shipment = I_rcpt
         and match_invc_id = I_invc_id
         for update nowait;

   cursor C_SHIPMENT_SKU is
      select distinct shipment
        from shipsku
       where match_invc_id = I_invc_id
         and item = I_item;

   cursor C_LOCK_SHIPMENT_SKU is
      select 'X'
        from shipsku
       where match_invc_id = I_invc_id
         and item = I_item
         for update nowait;

   cursor C_LOCK_ORDLOC_ITEM is
      select 'X'
        from ordloc_invc_cost
       where match_invc_id = I_invc_id
         and item = I_item
         for update nowait;

   cursor C_SHIPMENT is
      select distinct shipment
        from shipsku
       where match_invc_id = I_invc_id;

   cursor C_STATUS is
      select status
        from invc_head
       where invc_id = I_invc_id;

   cursor C_ITEM is
      select item
        from shipsku
       where shipment = I_rcpt
         and match_invc_id = I_invc_id;

   cursor C_CHECK_RTV is
     select ref_rtv_order_no
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
                    'C_INVC_TYPE',
               'INVC_HEAD',
          'INVOICE:'||TO_CHAR(I_invc_id));
   open C_INVC_TYPE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVC_TYPE',
          'INVC_HEAD',
          'INVOICE:'||TO_CHAR(I_invc_id));
   fetch C_INVC_TYPE into L_invc_type;


   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVC_TYPE',
                    'INVC_HEAD',
          'INVOICE:'||TO_CHAR(I_invc_id));
   close C_INVC_TYPE;

   open  C_CHECK_RTV;
   fetch C_CHECK_RTV into L_ref_rtv_order_no;
   close C_CHECK_RTV;

   if L_invc_type = 'D' and L_ref_rtv_order_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('NO_UNMATCH_DEBIT_MEMO',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   for rec in C_INVOICE LOOP

      if INVC_SQL.DELETE_INVC(O_error_message,
                              rec.invc_id,
                              NULL) = FALSE then
         return FALSE;
      end if;

   end LOOP;

   /* Unmatch a single item */
   if I_item is NOT NULL then
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DETAIL_ITEM',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      open C_LOCK_DETAIL_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DETAIL_ITEM',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      close C_LOCK_DETAIL_ITEM;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);

      update invc_detail
         set status = 'U'
       where invc_id = I_invc_id
         and item = I_item;

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVC_TOLERANCE',
                       'INVC_TOLERANCE',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      open C_LOCK_INVC_TOLERANCE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVC_TOLERANCE',
                       'INVC_TOLERANCE',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      close C_LOCK_INVC_TOLERANCE;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_TOLERANCE',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);

      delete invc_tolerance
       where invc_id = I_invc_id
         and item = I_item;

      ---
      L_table := 'SHIPSKU';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_SHIPMENT_SKU',
                       'SHIPSKU',
                       'ITEM:'||I_item);
      open C_LOCK_SHIPMENT_SKU;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_SHIPMENT_SKU',
                       'SHIPSKU',
                       'ITEM:'||I_item);
      close C_LOCK_SHIPMENT_SKU;
      ---
      L_table := 'ORDLOC_INVC_COST';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ORDLOC_ITEM',
                       'ORDLOC_INVC_COST',
                       'ITEM:'||I_item||
                       ',INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_ORDLOC_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ORDLOC_ITEM',
                       'ORDLOC_INVC_COST',
                       'ITEM:'||I_item||
                       ',INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_ORDLOC_ITEM;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'ORDLOC_INVC_COST',
                       'ITEM:'||I_item||
                       ',INVOICE:'||TO_CHAR(I_invc_id));

      update ordloc_invc_cost
         set match_invc_id = NULL
       where item = I_item
         and match_invc_id = I_invc_id;
      ---
      for rec in C_SHIPMENT_SKU LOOP
         ---
         L_shipment := rec.shipment;
         ---
         SQL_LIB.SET_MARK('UPDATE',
                           NULL,
                          'SHIPSKU',
                          'RECEIPT:'||TO_CHAR(rec.shipment)||
                          ',ITEM:'||I_item||
                          ',INVOICE:'||TO_CHAR(I_invc_id));

         update shipsku
            set match_invc_id = NULL
          where shipment = rec.shipment
            and item = I_item
            and match_invc_id = I_invc_id;

         if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                     NULL,
                                     rec.shipment,
                                     NULL,
                                     NULL) = FALSE then
            return FALSE;
         end if;
         ---
      end LOOP;

      ---
   /* Unmatch a single receipt from the invoice */
   elsif I_rcpt is NOT NULL then

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DETAIL_RCPT',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));
      open C_LOCK_DETAIL_RCPT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DETAIL_RCPT',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));
      close C_LOCK_DETAIL_RCPT;

      ---
      L_table := 'ORDLOC_INVC_COST';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ORDSKU_RCPT',
                       'ORDLOC_INVC_COST',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_ORDSKU_RCPT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ORDSKU_RCPT',
                       'ORDLOC_INVC_COST',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_ORDSKU_RCPT;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'ORDLOC_INVC_COST',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',INVOICE:'||TO_CHAR(I_invc_id));

       update ordloc_invc_cost
            set match_invc_id = NULL
          where shipment = I_rcpt
            and match_invc_id = I_invc_id;
      ---
      for rec in C_ITEM LOOP
         L_item := rec.item;
         ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_DETAIL_ITEM2',
                          'INVC_DETAIL',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ITEM:'||rec.item);
         open C_LOCK_DETAIL_ITEM2;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_DETAIL_ITEM2',
                          'INVC_DETAIL',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ITEM:'||rec.item);
         close C_LOCK_DETAIL_ITEM2;

         SQL_LIB.SET_MARK('UPDATE',
                           NULL,
                          'INVC_DETAIL',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ITEM:'||rec.item);

         update invc_detail
            set status = 'U'
          where invc_id = I_invc_id
            and item = rec.item;

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_INVC_TOLERANCE2',
                          'INVC_TOLERANCE',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ITEM:'||rec.item);
         open C_LOCK_INVC_TOLERANCE2;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_INVC_TOLERANCE2',
                          'INVC_TOLERANCE',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ITEM:'||rec.item);
         close C_LOCK_INVC_TOLERANCE2;

         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'INVC_TOLERANCE',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ITEM:'||rec.item);

         delete invc_tolerance
          where invc_id = I_invc_id
            and item = rec.item;
         ---
      end LOOP;
      ---
      L_table := 'SHIPSKU';

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_SHIPSKU_RCPT',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_SHIPSKU_RCPT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_SHIPSKU_RCPT',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_SHIPSKU_RCPT;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',INVOICE:'||TO_CHAR(I_invc_id));

      update shipsku
         set match_invc_id = NULL
       where shipment = I_rcpt
         and match_invc_id = I_invc_id;

      ---
      if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                  NULL,
                                  I_rcpt,
                                  NULL,
                                  NULL) = FALSE then
         return FALSE;
      end if;
      ---

   /* Unmatch the entire invoice */
   elsif I_item is NULL and I_rcpt is NULL then
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DETAIL',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      open C_LOCK_DETAIL;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DETAIL',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_DETAIL;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update invc_detail
         set status = 'U',
             cost_dscrpncy_ind = 'N',
             qty_dscrpncy_ind = 'N',
             vat_dscrpncy_ind = 'N'
       where invc_id = I_invc_id;
      ---
      L_table := 'ORDLOC_INVC_COST';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ORDLOC',
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_ORDLOC;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ORDLOC',
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_ORDLOC;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update ordloc_invc_cost
         set match_invc_id = NULL
       where match_invc_id = I_invc_id;

      ---
      L_table := 'SHIPSKU';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_SHIPSKU',
                       'SHIPSKU',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_SHIPSKU;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_SHIPSKU',
                       'SHIPSKU',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_SHIPSKU;
      ---
      for rec in C_SHIPMENT LOOP
         ---
         L_shipment := rec.shipment;
         ---
         SQL_LIB.SET_MARK('UPDATE',
                           NULL,
                          'SHIPSKU',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          'RECEIPT:'||TO_CHAR(rec.shipment));
         update shipsku
            set match_invc_id = NULL
          where match_invc_id = I_invc_id
            and shipment = rec.shipment;

         if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                     NULL,
                                     rec.shipment,
                                     NULL,
                                     NULL) = FALSE then
            return FALSE;
         end if;
         ---
      end LOOP;
      ---
   end if;

   if INVC_SQL.UPDATE_STATUSES(O_error_message,
                               I_invc_id,
                               NULL,
                               NULL,
                               NULL) = FALSE then
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_STATUS',
                    'INVC_HEAD',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   open C_STATUS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_STATUS',
                    'INVC_HEAD',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   fetch C_STATUS into O_status;


   SQL_LIB.SET_MARK('CLOSE',
                    'C_STATUS',
                    'INVC_HEAD',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   close C_STATUS;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_invc_id),
                                             I_item);
   return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.UNMATCH',
                                             to_char(SQLCODE));
   return FALSE;
END UNMATCH;
-----------------------------------------------------------------------------------------
FUNCTION APPROVE(O_error_message               IN OUT   VARCHAR2,
                 O_service_perf_fail           IN OUT   BOOLEAN,
                 I_invc_id                     IN       invc_head.invc_id%TYPE,
                 I_user_id                     IN       VARCHAR2)
   RETURN BOOLEAN is

   L_status        invc_head.status%TYPE;
   L_vdate         DATE := GET_VDATE;
   L_table         VARCHAR2(30) := 'INVC_HEAD';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_INVOICE is
      select 'x'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_user_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if INVC_VALIDATE_SQL.VAL_SERV_PERF_IND(O_error_message,
                                          O_service_perf_fail,
                                          I_invc_id,
                                          NULL,
                                          NULL,
                                          NULL) = FALSE then
      return FALSE;
   end if;

   if O_service_perf_fail = TRUE then
      return TRUE;
   else
      L_table := 'INVC_HEAD';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update invc_head
         set status = 'A',
             approval_id = I_user_id,
             approval_date = L_vdate
       where invc_id = I_invc_id;

      if SQL%NOTFOUND then
         O_error_message:= SQL_LIB.CREATE_MSG('INV_INVC_ID',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;

      return TRUE;
   end if;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_invc_id),
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.APPROVE',
                                             to_char(SQLCODE));
   return FALSE;
END APPROVE;
-----------------------------------------------------------------------------------------
FUNCTION UNAPPROVE(O_error_message   IN OUT   VARCHAR2,
                   I_invc_id         IN       invc_head.invc_id%TYPE,
                   I_unmatch         IN       BOOLEAN)
   RETURN BOOLEAN is

   L_status        invc_head.status%TYPE;
   L_dummy         VARCHAR2(1);
   L_table         VARCHAR2(30) := 'INVC_HEAD';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_INVOICE is
      select 'X'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_unmatch is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_unmatch',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_unmatch = TRUE then
      ---
      if INVC_MATCH_SQL.UNMATCH(O_error_message,
                                L_dummy,
                                I_invc_id,
                                NULL,
                                NULL) = FALSE then
         return FALSE;
      end if;

      L_table := 'INVC_HEAD';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update invc_head
         set approval_id = NULL,
             approval_date = NULL
       where invc_id = I_invc_id;
   else

      L_table := 'INVC_HEAD';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update invc_head
         set status = 'M',
             approval_id = NULL,
             approval_date = NULL
       where invc_id = I_invc_id;
   end if;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_invc_id),
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.UNAPPROVE',
                                             to_char(SQLCODE));
   return FALSE;

END UNAPPROVE;
-----------------------------------------------------------------------------------------
FUNCTION TOTAL_MATCH(O_error_message           IN OUT   VARCHAR2,
                     O_match                   IN OUT   BOOLEAN,
                     O_reconciled              IN OUT   BOOLEAN,
                     O_invc_status             IN OUT   invc_head.status%TYPE,
                     O_service_perf_fail       IN OUT   BOOLEAN,
                     I_invc_id                 IN       invc_head.invc_id%TYPE,
                     I_user_id                 IN       VARCHAR2)
   RETURN BOOLEAN IS

   L_exists                                VARCHAR2(1);
   L_today_date                            DATE := GET_VDATE;
   L_reconciled                            BOOLEAN;
   L_supplier                              invc_head.supplier%TYPE;
   L_matched                               VARCHAR2(1) := 'N';
   L_total_merch_cost                      invc_head.total_merch_cost%TYPE;
   L_total_qty                             invc_head.total_qty%TYPE;
   L_match_to_cost                         shipsku.unit_cost%TYPE := 0;
   L_match_to_qty                          shipsku.qty_received%TYPE := 0;
   L_cost_received                         shipsku.unit_cost%TYPE := 0;
   L_conv_cost_rec                         shipsku.unit_cost%TYPE := 0;
   L_total_conv_cost_rec                   shipsku.unit_cost%TYPE := 0;
   L_qty_received                          shipsku.qty_received%TYPE := 0;
   L_cost_in_tolerance                     BOOLEAN;
   L_match_mult_sup_ind                    system_options.invc_match_mult_sup_ind%TYPE;
   L_match_qty_ind                         system_options.invc_match_qty_ind%TYPE;
   L_qty_in_tolerance                      BOOLEAN;
   L_auto_appr_ind                         sups.auto_appr_invc_ind%TYPE;
   L_status                                invc_head.status%TYPE;
   L_appr_user_id                          VARCHAR2(30) := NULL;
   L_appr_date                             DATE := NULL;
   L_shipment                              shipment.shipment%TYPE;
   L_rcpt_order_no                         shipment.order_no%TYPE;
   L_table                                 VARCHAR2(30) := 'INVC_HEAD';
   RECORD_LOCKED                           EXCEPTION;
   PRAGMA                                  EXCEPTION_INIT(Record_Locked, -54);

   cursor C_SHIP_EXISTS is
      select 'x'
        from invc_xref
       where invc_id = I_invc_id
         and shipment is NOT NULL;

   cursor C_INVC_TOTAL_COST is
      select oic.order_no   order_no,
             oic.unit_cost  unit_cost,
             oic.qty        qty
        from ordloc_invc_cost oic,
             invc_xref ix,
             shipment sh,
             shipsku sk
       where oic.order_no       = ix.order_no
         and (oic.match_invc_id = ix.invc_id
              or oic.match_invc_id is NULL)
         and oic.shipment       = ix.shipment
         and ix.invc_id         = I_invc_id
         and ix.shipment        = sh.shipment
         and sh.invc_match_status != 'C'
         and sh.shipment        = sk.shipment
         and sk.item            = oic.item
         and sh.to_loc          = oic.location
         and (sk.match_invc_id  = I_invc_id
              or sk.match_invc_id is NULL)
     union all
      select inx1.order_no     order_no,
             sk1.unit_cost     unit_cost,
             sk1.qty_received  qty
        from shipsku sk1,
             invc_xref inx1,
             shipment sh1
       where inx1.invc_id = I_invc_id
         and sk1.qty_received is NOT NULL
         and sh1.shipment = inx1.shipment
         and sk1.shipment = inx1.shipment
         and sh1.invc_match_status != 'C'
         and (sk1.match_invc_id = I_invc_id
              or sk1.match_invc_id is NULL)
         and not exists (select 'x'
                           from ordloc_invc_cost oic1
                          where oic1.shipment = sk1.shipment
                            and oic1.item     = sk1.item
                            and oic1.order_no = inx1.order_no);

   cursor C_INVC_TOTALS is
      select nvl(total_merch_cost,0),
             nvl(total_qty,0),
             supplier
        from invc_head
       where invc_id = I_invc_id;

   cursor C_RCPT_ITEMS is
      select sk.shipment,
             sk.item,
             sk.unit_cost,
             SUM(sk.qty_received) qty_received
        from shipsku sk, invc_xref ix
       where sk.shipment = ix.shipment
         and ix.invc_id = I_invc_id
         and (sk.match_invc_id = I_invc_id
              or sk.match_invc_id is NULL)
    group by sk.shipment, sk.item, sk.unit_cost;

   cursor C_LOCK_INVC_TOLERANCE is
      select 'X'
        from invc_tolerance
       where invc_id = I_invc_id
         for update nowait;

   cursor C_AUTO_APPR_IND is
      select auto_appr_invc_ind
        from sups
       where supplier = L_supplier;

   cursor C_LOCK_INVOICE is
      select 'X'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

   cursor C_SHIPMENTS is
      select sh.shipment
        from shipment sh, invc_xref inx
       where inx.invc_id = I_invc_id
         and inx.shipment = sh.shipment
         and sh.invc_match_status = 'U'
         and exists (select 'X'
                       from shipsku sk
                      where sk.shipment = sh.shipment
                        and (match_invc_id = I_invc_id
                             or match_invc_id is NULL));

   cursor C_LOCK_SHIPSKUS is
      select 'X'
        from shipsku
       where shipment = L_shipment
         and match_invc_id is NULL
         for update nowait;

   cursor C_LOCK_ORDLOC_INVC_COST is
      select 'X'
        from ordloc_invc_cost
       where shipment = L_shipment
         and match_invc_id is NULL
         for update nowait;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_MATCH_SQL.TOTAL_MATCH',
                                             NULL);
      return FALSE;
   end if;

   if I_user_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_user_id',
                                            'INVC_MATCH_SQL.TOTAL_MATCH',
                                             NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_SHIP_EXISTS',
                    'INVC_XREF',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   open C_SHIP_EXISTS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_SHIP_EXISTS',
                    'INVC_XREF',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   fetch C_SHIP_EXISTS into L_exists;
   ---
   if C_SHIP_EXISTS%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SHIP_EXISTS',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_SHIP_EXISTS;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE',
                    'C_SHIP_EXISTS',
                    'INVC_XREF',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   close C_SHIP_EXISTS;

   SQL_LIB.SET_MARK('OPEN',
                    'C_INVC_TOTALS',
                    'INVC_HEAD',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   open C_INVC_TOTALS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVC_TOTALS',
                    'INVC_HEAD',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   fetch C_INVC_TOTALS into L_total_merch_cost, L_total_qty, L_supplier;

   if C_INVC_TOTALS%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_INVC_ID',
                                             NULL,
                                             NULL,
                                             NULL);
      SQL_LIB.SET_MARK('CLOSE',
                       'C_INVC_TOTALS',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_INVC_TOTALS;

      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVC_TOTALS',
                    'INVC_HEAD',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   close C_INVC_TOTALS;
   ---
   if INVC_MATCH_SQL.CHECK_VAT(O_error_message,
                               O_reconciled,
                               I_invc_id,
                               L_supplier) = FALSE then
      return FALSE;
   end if;

   if O_reconciled = FALSE then
      return TRUE;
   end if;
   ---
   for rec in C_INVC_TOTAL_COST LOOP
      L_match_to_cost := rec.unit_cost;
      L_match_to_qty  := rec.qty;
      ---
      L_cost_received := L_match_to_cost* L_match_to_qty;
      ---
      -- convert L_cost_received into invoice currency
      ---
      if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                          rec.order_no,
                                          'O',
                                          NULL,
                                          I_invc_id,
                                          'I',
                                          NULL,
                                          NVL(L_cost_received,0),
                                          L_conv_cost_rec,
                                          'C',
                                          NULL,
                                          NULL) = FALSE then
         return FALSE;
      end if;
      ---
      L_total_conv_cost_rec := L_total_conv_cost_rec + L_conv_cost_rec;
      L_qty_received := L_qty_received + L_match_to_qty;
      ---
   end LOOP;
   ---
   -- compare difference between invoice and receipt total cost
   if INVC_MATCH_SQL.CHECK_TOLERANCE(O_error_message,
                                     L_cost_in_tolerance,
                                     L_supplier,
                                     'TC',
                                     L_total_merch_cost,
                                     L_total_conv_cost_rec) = FALSE then
      return FALSE;
   end if;
   ---
   if L_cost_in_tolerance = FALSE then
      O_match := FALSE;
   else
      O_match := TRUE;
   end if;
   ---
   if INVC_SQL.INVC_SYSTEM_OPTIONS_INDS(O_error_message,
                                        L_match_mult_sup_ind,
                                        L_match_qty_ind) = FALSE then
         return FALSE;
   end if;
      ---
   if L_match_qty_ind = 'Y' then
         -- compare differentiation between invoice and receipt total qty
      if INVC_MATCH_SQL.CHECK_TOLERANCE(O_error_message,
                                        L_qty_in_tolerance,
                                        L_supplier,
                                        'TQ',
                                        L_total_qty,
                                        L_qty_received) = FALSE then
         return FALSE;
      end if;
      ---
      if L_qty_in_tolerance = FALSE then
         O_match := FALSE;
      end if;
      ---
   end if;
   ---
   if O_match = TRUE then
      SQL_LIB.SET_MARK('OPEN',
                       'C_AUTO_APPR_IND',
                       'SUPS',
                       'SUPPLIER:'||TO_CHAR(L_supplier));
      open C_AUTO_APPR_IND;

      SQL_LIB.SET_MARK('FETCH',
                       'C_AUTO_APPR_IND',
                       'SUPS',
                       'SUPPLIER:'||TO_CHAR(L_supplier));
      fetch C_AUTO_APPR_IND into L_auto_appr_ind;

      if C_AUTO_APPR_IND%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_AUTO_APPR_IND',
                          'SUPS',
                          'SUPPLIER:'||TO_CHAR(L_supplier));
         close C_AUTO_APPR_IND;
         O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_APPR_INVC_IND',
                                                NULL,
                                                NULL,
                                                NULL);
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_AUTO_APPR_IND',
                       'SUPS',
                       'SUPPLIER:'||TO_CHAR(L_supplier));
      close C_AUTO_APPR_IND;
      ---
      if L_auto_appr_ind = 'Y' then
         if INVC_VALIDATE_SQL.VAL_SERV_PERF_IND(O_error_message,
                                                O_service_perf_fail,
                                                I_invc_id,
                                                L_supplier,
                                                NULL,
                                                NULL) = FALSE then
            return FALSE;
         end if;
         if O_service_perf_fail = TRUE then
            L_status := 'M';
         else
            L_status := 'A';
            L_appr_user_id := I_user_id;
            L_appr_date := L_today_date;
         end if;
      else
         L_status := 'M';
      end if;
      L_table := 'INVC_HEAD';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update invc_head
         set status = L_status,
             match_id = I_user_id,
             match_date = L_today_date,
             approval_id = L_appr_user_id,
             approval_date = L_appr_date,
             match_fail_ind = 'N'
       where invc_id = I_invc_id;

      L_table := 'INVC_TOLERANCE';
      -- Since this match is at the summary level, delete any detail records
      -- that may have previously been written to the invc_tolerance table,
      -- then insert a summary record.
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVC_TOLERANCE',
                       'INVC_TOLERANCE',
                       'INVOICE:'||to_char(I_invc_id));
      open C_LOCK_INVC_TOLERANCE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVC_TOLERANCE',
                       'INVC_TOLERANCE',
                       'INVOICE:'||to_char(I_invc_id));
      close C_LOCK_INVC_TOLERANCE;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_TOLERANCE',
                       'INVOICE: '||to_char(I_invc_id));
      delete invc_tolerance
       where invc_id = I_invc_id;

      if L_total_merch_cost != L_total_conv_cost_rec then
         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'INVC_TOLERANCE',
                          'INVOICE: '||to_char(I_invc_id));

         insert into invc_tolerance (invc_id,
                                     seq_no,
                                     item,
                                     total_cost)
               values(I_invc_id,
                      1,
                      NULL,
                      (L_total_merch_cost - L_total_conv_cost_rec));
      end if;

      L_table := 'SHIPSKU';
      for rec in C_SHIPMENTS LOOP

         L_shipment := rec.shipment;

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_SHIPSKUS',
                          'SHIPSKU',
                          'SHIPMENT:'||TO_CHAR(L_shipment)||
                          'INVOICE:'||TO_CHAR(I_invc_id));
            open C_LOCK_SHIPSKUS;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_SHIPSKUS',
                          'SHIPSKU',
                          'SHIPMENT:'||TO_CHAR(L_shipment)||
                          'INVOICE:'||TO_CHAR(I_invc_id));
            close C_LOCK_SHIPSKUS;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'SHIPSKU',
                          'SHIPMENT:'||TO_CHAR(L_shipment)||
                          'INVOICE:'||TO_CHAR(I_invc_id));

         update shipsku
            set match_invc_id = I_invc_id
          where shipment = L_shipment
            and match_invc_id is NULL;

         L_table := 'ORDLOC_INVC_COST';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_ORDLOC_INVC_COST',
                          'ORDLOC_INVC_COST',
                          'SHIPMENT:'||TO_CHAR(L_shipment)||
                          'INVOICE:'||TO_CHAR(I_invc_id));
            open C_LOCK_ORDLOC_INVC_COST;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_ORDLOC_INVC_COST',
                          'ORDLOC_INVC_COST',
                          'SHIPMENT:'||TO_CHAR(L_shipment)||
                          'INVOICE:'||TO_CHAR(I_invc_id));
            close C_LOCK_ORDLOC_INVC_COST;

         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'ORDLOC_INVC_COST',
                          'SHIPMENT:'||TO_CHAR(L_shipment)||
                          'INVOICE:'||TO_CHAR(I_invc_id));

         update ordloc_invc_cost
            set match_invc_id = I_invc_id
          where shipment = L_shipment
            and match_invc_id is NULL;

         if INVC_SQL.UPDATE_STATUSES(O_error_message,
                                     NULL,
                                     L_shipment,
                                     I_user_id,
                                     L_supplier) = FALSE then
            return FALSE;
         end if;
      end LOOP;

   else  /* O_match = FALSE */
      L_table := 'INVC_HEAD';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVOICE',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update invc_head
         set match_fail_ind = 'Y'
       where invc_id = I_invc_id;
   end if; /* O_match value */

   O_invc_status := L_status;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_invc_id),
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_MATCH_SQL.TOTAL_MATCH',
                                             to_char(SQLCODE));
   return FALSE;

END TOTAL_MATCH;
-----------------------------------------------------------------------------------------
FUNCTION CHECK_VAT_RATES(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         I_invc_id         IN       INVC_DETAIL.INVC_ID%TYPE)
   RETURN BOOLEAN IS

   L_vat_rate    INVC_DETAIL.INVC_VAT_RATE%TYPE;
   L_invc_date   INVC_HEAD.INVC_DATE%TYPE;
   L_valid       VARCHAR2(1) := 'N';

   cursor C_INVC_DATE is
      select invc_date
        from invc_head
       where invc_id = I_invc_id;

   cursor C_INVC_DETAIL_RATES is
      select invc_vat_rate
        from invc_detail
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
                    'C_INVC_DATE',
                    'INVC_HEAD',
                    'INVC_ID:'||to_char(I_invc_id));
   open C_INVC_DATE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_INVC_DATE',
                    'INVC_HEAD',
                    'INVC_ID:'||to_char(I_invc_id));
   fetch C_INVC_DATE into L_invc_date;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_INVC_DATE',
                    'INVC_HEAD',
                    'INVC_ID:'||to_char(I_invc_id));
   close C_INVC_DATE;

   if L_invc_date is NULL then
      O_error_message := 'INV_INVC_ID';
      return FALSE;
   end if;

   for rec in C_INVC_DETAIL_RATES LOOP
      L_vat_rate := rec.invc_vat_rate;
      L_valid    := 'N';

      if CHECK_VAT_CODE(O_error_message,
                        L_valid,
                        I_invc_id,
                        L_vat_rate,
                        L_invc_date) = FALSE then
         return FALSE;
      end if;

      if L_valid = 'N' then
         O_error_message := 'INV_RATE_MISMATCH';
         return FALSE;
      end if;

   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_MATCH_SQL.CHECK_VAT_RATES',
                                            to_char(SQLCODE));
      return FALSE;

END CHECK_VAT_RATES;
-----------------------------------------------------------------------------------------
FUNCTION CHECK_VAT_CODE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                        O_valid           IN OUT   VARCHAR2,
                        I_invc_id         IN       INVC_DETAIL.INVC_ID%TYPE,
                        I_vat_rate        IN       INVC_DETAIL.ORIG_VAT_RATE%TYPE,
                        I_invc_date       IN       INVC_HEAD.INVC_DATE%TYPE)
   RETURN BOOLEAN IS

   L_dummy   VARCHAR2(2);

   cursor C_CHECK_VAT_CODE is
      select 'x'
        from invc_merch_vat imv,
             vat_code_rates vcr1
       where imv.invc_id       = I_invc_id
         and imv.vat_code      = vcr1.vat_code
         and vcr1.vat_rate     = I_vat_rate
         and vcr1.active_date <= I_invc_date
         and rownum            = 1;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   if I_vat_rate is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_vat_rate',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;

   O_valid := 'Y';

   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_VAT_CODE',
                    'INVC_MERCH_VAT, VAT_CODE_RATES',
                    'INVC_ID:'||TO_CHAR(I_invc_id)||
                    'VAT_RATE:'||TO_CHAR(I_vat_rate));
   open C_CHECK_VAT_CODE;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_VAT_CODE',
                    'INVC_MERCH_VAT, VAT_CODE_RATES',
                    'INVC_ID:'||TO_CHAR(I_invc_id)||
                    'VAT_RATE:'||TO_CHAR(I_vat_rate));
   fetch C_CHECK_VAT_CODE into L_dummy;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_VAT_CODE',
                    'INVC_MERCH_VAT, VAT_CODE_RATES',
                    'INVC_ID:'||TO_CHAR(I_invc_id)||
                    'VAT_RATE:'||TO_CHAR(I_vat_rate));
   close C_CHECK_VAT_CODE;

   if L_dummy is NULL then
      O_valid := 'N';
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_MATCH_SQL.CHECK_VAT_CODE',
                                            to_char(SQLCODE));
  return FALSE;

END CHECK_VAT_CODE;
-----------------------------------------------------------------------------------------
END INVC_MATCH_SQL;
/

