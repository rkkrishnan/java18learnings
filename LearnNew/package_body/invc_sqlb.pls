CREATE OR REPLACE PACKAGE BODY INVC_SQL AS
--------------------------------------------------------------------
FUNCTION LOCK_INVC(O_error_message   IN OUT   VARCHAR2,
                   O_lock_ind        IN OUT   BOOLEAN,
                   I_invc_id         IN       INVC_HEAD.INVC_ID%TYPE)
   RETURN BOOLEAN IS

   L_table          VARCHAR2(30) := 'INVC_HEAD';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_INVC_HEAD is
      select 'X'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_SQL.LOCK_INVC',
                                            NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_INVC_HEAD',
                    'INVC_HEAD',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   open C_LOCK_INVC_HEAD;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_INVC_HEAD',
                    'INVC_HEAD',
                    'INVOICE:'||TO_CHAR(I_invc_id));
   close C_LOCK_INVC_HEAD;

   O_lock_ind := TRUE;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_invc_id),
                                             NULL);
      O_lock_ind := FALSE;
      return TRUE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'LOCK_INVC',
                                             to_char(SQLCODE));

      return FALSE;

END LOCK_INVC;
--------------------------------------------------------------------
FUNCTION UPDATE_STATUSES(O_error_message   IN OUT   VARCHAR2,
                         I_invc_id         IN       INVC_HEAD.INVC_ID%TYPE,
                         I_rcpt            IN       SHIPMENT.SHIPMENT%TYPE,
                         I_user_id         IN       USER_ATTRIB.USER_ID%TYPE,
                         I_supplier        IN       INVC_HEAD.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_status_count         NUMBER(1)   :=0;
   L_status_type          invc_detail.status%TYPE;
   L_approval             VARCHAR2(1) := 'N';
   L_shipskus_exist       VARCHAR2(1) := 'N';
   L_unmatched_shipskus   VARCHAR2(1) :='N';
   L_supplier             invc_head.supplier%TYPE;
   L_table                VARCHAR2(30):= 'INVC_HEAD';
   L_today_date           period.vdate%TYPE;
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);

   cursor C_COUNT_DETAIL_STATUSES is
      select count(distinct status)
        from invc_detail
       where invc_id = I_invc_id;

   cursor C_SAME_STATUS is
      select status
        from invc_detail
       where invc_id = I_invc_id;

   cursor C_SHIPSKUS_EXIST is
      select 'Y'
        from shipsku
       where shipment = I_rcpt;

   cursor C_UNMATCHED_SHIPSKUS is
      select 'Y'
        from shipsku
       where shipment = I_rcpt
         and match_invc_id is NULL;

   cursor C_SUPPLIER is
      select supplier
        from invc_head
       where invc_id = I_invc_id;

   cursor C_APPROVAL is
      select auto_appr_invc_ind
        from sups
       where supplier = L_supplier;

   cursor C_LOCK_INVOICE is
      select 'X'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_XREF is
      select 'X'
        from invc_xref inx
       where inx.invc_id          = I_invc_id
         and (apply_to_future_ind = 'Y'
          or  not exists (select 'X'
                            from shipsku sk
                           where sk.shipment   = inx.shipment
                             and match_invc_id = I_invc_id))
         for update nowait;

   cursor C_LOCK_MATCHED_INVOICE is
      select 'X'
        from invc_head
       where invc_id = I_invc_id
         and status  = 'M'
         for update nowait;

   cursor C_LOCK_NEW_MATCH is
      select 'X'
        from invc_head
       where invc_id = I_invc_id
         and status IN ('R','U')
         for update nowait;

   cursor C_LOCK_SHIPMENT is
      select 'X'
        from shipment
       where shipment = I_rcpt
         for update nowait;

BEGIN

   L_today_date := GET_VDATE;

   if I_invc_id is NOT NULL then

      SQL_LIB.SET_MARK('OPEN',
                       'C_COUNT_DETAIL_STATUSES',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open  C_COUNT_DETAIL_STATUSES;

      SQL_LIB.SET_MARK('FETCH',
                       'C_COUNT_DETAIL_STATUSES',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      fetch C_COUNT_DETAIL_STATUSES into L_status_count;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_COUNT_DETAIL_STATUSES',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_COUNT_DETAIL_STATUSES;

      if L_status_count >1 then

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_INVOICE',
                          'INVC_HEAD',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         open  C_LOCK_INVOICE;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_INVOICE',
                          'INVC_HEAD',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         close  C_LOCK_INVOICE;

         SQL_LIB.SET_MARK('UPDATE',
                           NULL,
                          'INVC_HEAD',
                          'STATUS: R'||
                          ',INVOICE:'||TO_CHAR(I_invc_id));

         update invc_head
            set status        = 'R',
                match_id      = NULL,
                match_date    = NULL,
                approval_id   = NULL,
                approval_date = NULL
          where invc_id       = I_invc_id;

      else
         SQL_LIB.SET_MARK('OPEN',
                          'C_SAME_STATUS',
                          'INVC_DETAIL',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         open  C_SAME_STATUS;

         SQL_LIB.SET_MARK('FETCH',
                          'C_SAME_STATUS',
                          'INVC_DETAIL',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         fetch C_SAME_STATUS into L_status_type;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_SAME_STATUS',
                          'INVC_DETAIL',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         close C_SAME_STATUS;

         if L_status_type = 'M' then

            if I_user_id IS NULL then
               O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                     'I_user_id',
                                                     'INVC_SQL.UPDATE_STATUSES',
                                                     NULL);
               return FALSE;
            end if;

            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_NEW_MATCH',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            open  C_LOCK_NEW_MATCH;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_NEW_MATCH',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            close  C_LOCK_NEW_MATCH;

            SQL_LIB.SET_MARK('UPDATE',
                              NULL,
                             'INVC_HEAD',
                             'STATUS: M'||
                            ',INVOICE:'||TO_CHAR(I_invc_id));

            update invc_head
               set status        = 'M',
                   match_id      = I_user_id,
                   match_date    = L_today_date,
                   approval_id   = NULL,
                   approval_date = NULL
             where invc_id       = I_invc_id
               and status IN ('R','U');

            L_table := 'INVC_XREF';
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_XREF',
                             'INVC_XREF',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            open C_LOCK_XREF;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_XREF',
                             'INVC_XREF',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            close C_LOCK_XREF;

            -- eliminate incorrect associations on invc_xref
            SQL_LIB.SET_MARK('DELETE',
                              NULL,
                             'INVC_XREF',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            delete
              from invc_xref inx
             where inx.invc_id          = I_invc_id
               and (apply_to_future_ind = 'Y'
                or  not exists (select 'X'
                                  from shipsku sk
                                 where sk.shipment   = inx.shipment
                                   and match_invc_id = I_invc_id));

            L_supplier := I_supplier;

            if L_supplier is NULL then
               SQL_LIB.SET_MARK('OPEN',
                                'C_SUPPLIER',
                                'INVC_HEAD',
                                'INVOICE:'||TO_CHAR(I_invc_id));
               open C_SUPPLIER;

               SQL_LIB.SET_MARK('FETCH',
                                'C_SUPPLIER',
                                'INVC_HEAD',
                               'INVOICE:'||TO_CHAR(I_invc_id));
               fetch C_SUPPLIER into L_supplier;

               SQL_LIB.SET_MARK('CLOSE',
                                'C_SUPPLIER',
                                'INVC_HEAD',
                                'INVOICE:'||TO_CHAR(I_invc_id));
               close C_SUPPLIER;
            end if;

            SQL_LIB.SET_MARK('OPEN',
                             'C_APPROVAL',
                             'SUPS',
                             'SUPPLIER:'||TO_CHAR(L_supplier));
            open C_APPROVAL;

            SQL_LIB.SET_MARK('FETCH',
                             'C_APPROVAL',
                             'SUPS',
                             'SUPPLIER:'||TO_CHAR(L_supplier));
            fetch C_APPROVAL into L_approval;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_APPROVAL',
                             'SUPS',
                             'SUPPLIER:'||TO_CHAR(L_supplier));
            close C_APPROVAL;

            if L_approval = 'Y' then

               L_table := 'INVC_HEAD';
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_MATCHED_INVOICE',
                                'INVC_HEAD',
                                'INVOICE:'||TO_CHAR(I_invc_id));
               open C_LOCK_MATCHED_INVOICE;

               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_MATCHED_INVOICE',
                                'INVC_HEAD',
                                'INVOICE:'||TO_CHAR(I_invc_id));
               close C_LOCK_MATCHED_INVOICE;

               SQL_LIB.SET_MARK('UPDATE',
                                NULL,
                                'INVC_HEAD',
                                'STATUS: A'||
                                ',INVOICE:'||TO_CHAR(I_invc_id));

               update invc_head
                  set status        = 'A',
                      approval_id   = I_user_id,
                      approval_date = L_today_date
                where invc_id       = I_invc_id
                   and status       = 'M';
            end if;

         elsif L_status_type = 'R' then

            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_INVOICE',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            open  C_LOCK_INVOICE;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_INVOICE',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            close  C_LOCK_INVOICE;

            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'INVC_HEAD',
                             'STATUS: R'||
                             ',INVOICE:'||TO_CHAR(I_invc_id));

            update invc_head
               set status        = 'R',
                   match_id      = NULL,
                   match_date    = NULL,
                   approval_id   = NULL,
                   approval_date = NULL
             where invc_id       = I_invc_id;

         else    --status is 'U'
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_INVOICE',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            open  C_LOCK_INVOICE;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_INVOICE',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            close  C_LOCK_INVOICE;

            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'INVC_HEAD',
                             'STATUS: U'||
                             ',INVOICE:'||TO_CHAR(I_invc_id));

            update invc_head
               set status        = 'U',
                   match_id      = NULL,
                   match_date    = NULL,
                   approval_id   = NULL,
                   approval_date = NULL
             where invc_id       = I_invc_id;
         end if;
      end if;
   end if;
   ---
   if I_rcpt is NOT NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_SHIPSKUS_EXIST',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt));
      open  C_SHIPSKUS_EXIST;

      SQL_LIB.SET_MARK('FETCH',
                       'C_SHIPSKUS_EXIST',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt));
      fetch C_SHIPSKUS_EXIST into L_shipskus_exist;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_SHIPSKUS_EXIST',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt));
      close C_SHIPSKUS_EXIST;

      if L_shipskus_exist = 'Y' then

         SQL_LIB.SET_MARK('OPEN',
                          'C_UNMATCHED_SHIPSKUS',
                          'SHIPSKU',
                          'RECEIPT:'||TO_CHAR(I_rcpt));
         open  C_UNMATCHED_SHIPSKUS;

         SQL_LIB.SET_MARK('FETCH',
                          'C_UNMATCHED_SHIPSKUS',
                          'SHIPSKU',
                          'RECEIPT:'||TO_CHAR(I_rcpt));
         fetch C_UNMATCHED_SHIPSKUS into L_unmatched_shipskus;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_UNMATCHED_SHIPSKUS',
                          'SHIPSKU',
                          'RECEIPT:'||TO_CHAR(I_rcpt));
         close C_UNMATCHED_SHIPSKUS;

         --this init and locking cursor are for both cases below
         L_table := 'SHIPMENT';

         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_SHIPMENT',
                          'SHIPMENT',
                          'RECEIPT:'||TO_CHAR(I_rcpt));
         open C_LOCK_SHIPMENT;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_SHIPMENT',
                          'SHIPMENT',
                          'RECEIPT:'||TO_CHAR(I_rcpt));
         close C_LOCK_SHIPMENT;

         if L_unmatched_shipskus = 'Y' then --case 1

            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'SHIPMENT',
                             'MATCHSTATUS: U'||
                             ',RECEIPT:'||TO_CHAR(I_rcpt));
            update shipment
               set invc_match_status = 'U',
                   invc_match_date   = NULL
             where shipment          = I_rcpt;
         else -- the shipsku records are matched with an invoice --case2

            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                            'SHIPMENT',
                            'MATCHSTATUS: M'||
                            ',RECEIPT:'||TO_CHAR(I_rcpt));

            update shipment
               set invc_match_status = 'M',
                   invc_match_date   = NVL(invc_match_date,L_today_date)
             where shipment          = I_rcpt;

         end if;
      end if;
   end if;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_invc_id),
                                             TO_CHAR(I_rcpt));
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.UPDATE_STATUSES',
                                            TO_CHAR(SQLCODE));
      return FALSE;


END UPDATE_STATUSES;
--------------------------------------------------------------------
FUNCTION REVERT(O_error_message   IN OUT   VARCHAR2,
                I_invc_id         IN       INVC_HEAD.INVC_ID%TYPE,
                I_item            IN       INVC_DETAIL.ITEM%TYPE,
                I_invc_unit_cost  IN       INVC_DETAIL.INVC_UNIT_COST%TYPE)
   RETURN BOOLEAN IS

   L_detail_status    VARCHAR2(1) := NULL;
   L_invoice_status   VARCHAR2(1) := 'N';
   L_table            VARCHAR2(30);
   RECORD_LOCKED      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_INVOICE_COST_ITEM is
      select 'X'
        from invc_detail
       where invc_id        = I_invc_id
         and item           = I_item
         and invc_unit_cost = I_invc_unit_cost
         and status         = 'U'
         for update nowait;

   cursor C_LOCK_INVOICE_ITEM is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         and item    = I_item
         and status  = 'U'
         for update nowait;

   cursor C_LOCK_INVOICE is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         and status  = 'U'
         for update nowait;

BEGIN

   L_table := 'INVC_DETAIL';

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_SQL.REVERT',
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_invc_unit_cost is NOT NULL then
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                               'I_item',
                                               'INVC_SQL.REVERT',
                                               NULL);
         return FALSE;
      end if;

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVOICE_COST_ITEM',
                       'INVC_DETAIL',
                       'INVOICE: '||TO_CHAR(I_invc_id)||
                       ',ITEM: '||I_item||
                       ',COST: '||TO_CHAR(I_invc_unit_cost));
      open C_LOCK_INVOICE_COST_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVOICE_COST_ITEM',
                       'INVC_DETAIL',
                       'INVOICE: '||TO_CHAR(I_invc_id)||
                       ',ITEM: '||I_item||
                       ',COST: '||TO_CHAR(I_invc_unit_cost));
      close C_LOCK_INVOICE_COST_ITEM;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item||
                       ',COST: '||TO_CHAR(I_invc_unit_cost));


      update invc_detail
         set invc_unit_cost = orig_unit_cost,
             invc_qty       = orig_qty,
             invc_vat_rate  = orig_vat_rate
       where invc_id        = I_invc_id
         and item           = I_item
         and invc_unit_cost = I_invc_unit_cost
         and status         = 'U';

      if SQL%NOTFOUND then
         -- line item has been previously matched and cannot be reverted
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_REVERT_ITEM',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;

   elsif I_invc_unit_cost is NULL and I_item is NOT NULL then
      --no unit cost given for item

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVOICE_ITEM',
                       'INVC_DETAIL',
                       'INVOICE: '||TO_CHAR(I_invc_id)||
                       ',ITEM: '||I_item);
      open C_LOCK_INVOICE_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVOICE_ITEM',
                       'INVC_DETAIL',
                       'INVOICE: '||TO_CHAR(I_invc_id)||
                       ',ITEM: '||I_item);
      close C_LOCK_INVOICE_ITEM;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'INVC_DETAIL',
                       'INVOICE: '||TO_CHAR(I_invc_id)||
                       ',ITEM: '||I_item);

      update invc_detail
         set invc_unit_cost = orig_unit_cost,
             invc_qty       = orig_qty,
             invc_vat_rate  = orig_vat_rate
       where invc_id        = I_invc_id
         and item           = I_item
         and status         = 'U';

      if SQL%NOTFOUND then
         -- line item has been previously matched and cannot be reverted
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_REVERT_ITEM',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;

   else -- entire invoice will be reverted

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVOICE',
                       'INVC_DETAIL',
                       'INVOICE: '||TO_CHAR(I_invc_id));
      open C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVOICE',
                       'INVC_DETAIL',
                       'INVOICE: '||TO_CHAR(I_invc_id));
      close C_LOCK_INVOICE;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update invc_detail
         set invc_unit_cost = orig_unit_cost,
             invc_qty       = orig_qty,
             invc_vat_rate  = orig_vat_rate
       where invc_id        = I_invc_id
         and status         = 'U';

      if SQL%NOTFOUND then
         --Invoice cannot be reverted...all items at least partially matched
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_REVERT_INVC',
                        NULL,
                        NULL,
                        NULL);
         return FALSE;
      end if;
   end if;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_invc_id),
                                             I_item);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.REVERT',
                                            TO_CHAR(SQLCODE));
      return FALSE;


END REVERT;
--------------------------------------------------------------------
FUNCTION APPLY_XREF(O_error_message          IN OUT   VARCHAR2,
                    I_invc_id                IN       INVC_XREF.INVC_ID%TYPE,
                    I_order_no               IN       SHIPMENT.ORDER_NO%TYPE,
                    I_asn_no                 IN       SHIPMENT.ASN%TYPE,
                    I_to_loc                 IN       SHIPMENT.TO_LOC%TYPE,
                    I_to_loc_type            IN       SHIPMENT.TO_LOC_TYPE%TYPE,
                    I_supplier               IN       INVC_HEAD.SUPPLIER%TYPE,
                    I_apply_to_future_ind    IN       INVC_XREF.APPLY_TO_FUTURE_IND%TYPE)
   RETURN BOOLEAN IS

   L_supplier       invc_head.supplier%TYPE;
   L_mult_sup       system_options.invc_match_mult_sup_ind%TYPE;
   L_shipment       shipment.shipment%TYPE;
   L_asn            shipment.asn%TYPE;
   L_to_loc         shipment.to_loc%TYPE;
   L_loc_type       invc_xref.loc_type%TYPE;
   L_check          VARCHAR2(1) := NULL;


   cursor C_SUPPLIER is
      select supplier
        from invc_head
       where invc_id = I_invc_id;

   cursor C_MULT_SUPPLIERS is
      select invc_match_mult_sup_ind
        from system_options;

   cursor C_DUPLICATE is
      select 'X'
        from invc_xref
       where invc_id    = I_invc_id
         and ((order_no = I_order_no)
               or (order_no is NULL and I_order_no is NULL))
         and ((asn   = I_asn_no)
               or (asn is NULL and I_asn_no is NULL))
         and ((location = I_to_loc)
               or (location is NULL and I_to_loc is NULL))
         and apply_to_future_ind = 'Y';

BEGIN

   if I_apply_to_future_ind is NULL then

      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_apply_to_future_ind',
                                            'INVC_SQL.APPLY_XREF');
      return FALSE;
   end if;

   if I_apply_to_future_ind NOT IN ('Y','N') then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_apply_to_future_ind',
                                            I_apply_to_future_ind,
                                            'Y or N');
      return FALSE;
   end if;

   if I_order_no is NULL and I_asn_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_EITHER',
                                            'I_order_no',
                                            'I_asn_no',
                                            'INVC_SQL.APPLY_XREF');
      return FALSE;
   end if;

   if I_order_no is NOT NULL and I_asn_no is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_COMBO',
                                            'INVC_SQL.APPLY_XREF',
                                            'the I_order_no',
                                            'I_asn_no' ||
                                            ' input parameters');
      return FALSE;
   end if;

   if I_order_no is NOT NULL then

      if I_to_loc is NOT NULL then

         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'INVC_XREF',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ORDER:'||TO_CHAR(I_order_no)||
                          ',LOCATION: '||TO_CHAR(I_to_loc));

         insert into invc_xref(invc_id,
                               order_no,
                               shipment,
                               asn,
                               location,
                               loc_type,
                               apply_to_future_ind)
                        select I_invc_id,
                               s.order_no,
                               s.shipment,
                               s.asn,
                               s.to_loc,
                               s.to_loc_type,
                               'N'
                          from shipment s
                         where s.order_no          = I_order_no
                           and s.to_loc            = I_to_loc
                           and s.status_code       = 'R'
                           and s.invc_match_status = 'U'
                           and not exists (select 'X'
                                              from invc_xref inx
                                             where inx.invc_id  = I_invc_id
                                               and inx.shipment = s.shipment);

      else --location passed as null


         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'INVC_XREF',
                          'INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ORDER:'||TO_CHAR(I_order_no));

         insert into invc_xref(invc_id,
                               order_no,
                               shipment,
                               asn,
                               location,
                               loc_type,
                               apply_to_future_ind)
                        select I_invc_id,
                               s.order_no,
                               s.shipment,
                               s.asn,
                               s.to_loc,
                               s.to_loc_type,
                               'N'
                          from shipment s
                         where s.order_no          = I_order_no
                           and s.status_code       = 'R'
                           and s.invc_match_status = 'U'
                           and not exists (select 'X'
                                             from invc_xref inx
                                            where inx.invc_id  = I_invc_id
                                              and inx.shipment = s.shipment);

      end if;

   else -- I_asn_no is NOT NULL

      SQL_LIB.SET_MARK('OPEN',
                       'C_MULT_SUPPLIERS',
                       'SYSTEM_OPTIONS',
                       NULL);
      open C_MULT_SUPPLIERS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_MULT_SUPPLIERS',
                       'SYSTEM_OPTIONS',
                       NULL);
      fetch C_MULT_SUPPLIERS into L_mult_sup;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_MULT_SUPPLIERS',
                       'SYSTEM_OPTIONS',
                       NULL);
      close C_MULT_SUPPLIERS;

      if L_mult_sup = 'N' then --matching to receipts from mult suppliers not allowed

         if I_supplier is NOT NULL then
            L_supplier := I_supplier;
         else
            SQL_LIB.SET_MARK('OPEN',
                             'C_SUPPLIER',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            open C_SUPPLIER;

            SQL_LIB.SET_MARK('FETCH',
                             'C_SUPPLIER',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            fetch C_SUPPLIER into L_supplier;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_SUPPLIER',
                             'INVC_HEAD',
                             'INVOICE:'||TO_CHAR(I_invc_id));
            close C_SUPPLIER;
         end if;

         if I_to_loc is NOT NULL then

            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'INVC_XREF',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ASN:'||(I_asn_no)||
                             ',LOCATION:'||TO_CHAR(I_to_loc));

            insert into invc_xref(invc_id,
                                  order_no,
                                  shipment,
                                  asn,
                                  location,
                                  loc_type,
                                  apply_to_future_ind)
                           select I_invc_id,
                                  s.order_no,
                                  s.shipment,
                                  s.asn,
                                  s.to_loc,
                                  s.to_loc_type,
                                  'N'
                             from shipment s
                            where s.asn               = I_asn_no
                              and s.status_code       = 'R'
                              and s.invc_match_status = 'U'
                              and s.to_loc          = I_to_loc
                              and s.order_no in (select o.order_no
                                                  from ordhead o
                                                 where o.supplier = L_supplier)
                                                   and not exists (select 'X'
                                                                    from invc_xref inx
                                                                   where inx.invc_id  = I_invc_id
                                                                     and inx.shipment = s.shipment);

         else --location passed as null

            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                             'INVC_XREF',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ASN:'||(I_asn_no));

            insert into invc_xref(invc_id,
                                  order_no,
                                  shipment,
                                  asn,
                                  location,
                                  loc_type,
                                  apply_to_future_ind)
                           select I_invc_id,
                                  s.order_no,
                                  s.shipment,
                                  s.asn,
                                  s.to_loc,
                                  s.to_loc_type,
                                  'N'
                              from shipment s
                             where s.asn               = I_asn_no
                               and s.status_code       = 'R'
                               and s.invc_match_status = 'U'
                               and s.order_no in (select o.order_no
                                                   from ordhead o
                                                  where o.supplier = L_supplier)
                                                    and not exists (select 'X'
                                                                     from invc_xref inx
                                                                    where inx.invc_id  = I_invc_id
                                                                      and inx.shipment = s.shipment);
         end if;
      else -- matching to receipts from mult suppliers allowed

         if I_to_loc is NOT NULL then

            SQL_LIB.SET_MARK('INSERT',
                             NULL,
                            'INVC_XREF',
                            'INVOICE:'||TO_CHAR(I_invc_id)||
                            ',ASN:'||(I_asn_no)||
                            ',LOCATION:'||TO_CHAR(I_to_loc));

            insert into invc_xref(invc_id,
                                  order_no,
                                  shipment,
                                  asn,
                                  location,
                                  loc_type,
                                  apply_to_future_ind)
                           select I_invc_id,
                                  s.order_no,
                                  s.shipment,
                                  s.asn,
                                  s.to_loc,
                                  s.to_loc_type,
                                  'N'
                              from shipment s
                             where s.asn               = I_asn_no
                               and s.status_code       = 'R'
                               and s.invc_match_status = 'U'
                               and s.to_loc            = I_to_loc
                               and not exists (select 'X'
                                                 from invc_xref inx
                                                where inx.invc_id  = I_invc_id
                                                  and inx.shipment = s.shipment);
         else --location is null

            SQL_LIB.SET_MARK('INSERT',
                              NULL,
                             'INVC_XREF',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ASN:'||(I_asn_no));


            insert into invc_xref(invc_id,
                                  order_no,
                                  shipment,
                                  asn,
                                  location,
                                  loc_type,
                                  apply_to_future_ind)
                           select I_invc_id,
                                  s.order_no,
                                  s.shipment,
                                  s.asn,
                                  s.to_loc,
                                  s.to_loc_type,
                                  'N'
                             from shipment s
                            where s.asn               = I_asn_no
                              and s.status_code       = 'R'
                              and s.invc_match_status = 'U'
                              and not exists (select 'X'
                                                from invc_xref inx
                                               where inx.invc_id  = I_invc_id
                                                 and inx.shipment = s.shipment);
         end if;
      end if;
   end if;
   ---
   if I_apply_to_future_ind = 'Y' then

      if I_to_loc is NOT NULL then

         if I_to_loc_type is NULL then

            if LOCATION_ATTRIB_SQL.GET_TYPE(O_error_message,
                                            L_loc_type,
                                            I_to_loc) = FALSE then
            return FALSE;
            end if;

         else
            L_loc_type := I_to_loc_type;
         end if;
      end if;

      SQL_LIB.SET_MARK('OPEN',
                       'C_DUPLICATE',
                       'INVC_XREF',
                       ',INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ORDER:'||TO_CHAR(I_order_no)||
                       ',ASN:'||(I_asn_no)||
                       ',LOCATION:'||TO_CHAR(I_to_loc));
      open C_DUPLICATE;

      SQL_LIB.SET_MARK('FETCH',
                       'C_DUPLICATE',
                       'INVC_XREF',
                       ',INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ORDER:'||TO_CHAR(I_order_no)||
                       ',ASN:'||(I_asn_no)||
                       ',LOCATION:'||TO_CHAR(I_to_loc));
      fetch C_DUPLICATE into L_check;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_DUPLICATE',
                       'INVC_XREF',
                       ',INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ORDER:'||TO_CHAR(I_order_no)||
                       ',ASN:'||(I_asn_no)||
                       ',LOCATION:'||TO_CHAR(I_to_loc));
      close C_DUPLICATE;

      if L_check is NULL then

         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'INVC_XREF',
                          ',INVOICE:'||TO_CHAR(I_invc_id)||
                          ',ORDER:'||TO_CHAR(I_order_no)||
                          ',ASN:'||(I_asn_no)||
                          ',LOCATION:'||TO_CHAR(I_to_loc));

         insert into invc_xref(invc_id,
                               order_no,
                               asn,
                               location,
                               loc_type,
                               apply_to_future_ind)
                       values (I_invc_id,
                               I_order_no,
                               I_asn_no,
                               I_to_loc,
                               L_loc_type,
                               'Y');
      end if;
   end if;

   return TRUE;
EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.APPLY_XREF',
                                            TO_CHAR(SQLCODE));
      return FALSE;


END APPLY_XREF;
--------------------------------------------------------------------
FUNCTION DEFAULT_ITEMS(O_error_message   IN OUT   VARCHAR2,
                       I_invc_id         IN       INVC_HEAD.INVC_ID%TYPE,
                       I_overwrite       IN       BOOLEAN,
                       I_vat_region      IN       VAT_REGION.VAT_REGION%TYPE)
   RETURN BOOLEAN IS


   L_vat_ind        system_options.vat_ind%TYPE;
   L_vat_rate       invc_detail.invc_vat_rate%TYPE;
   L_vat_region     vat_region.vat_region%TYPE;
   L_order_no       invc_xref.order_no%TYPE;
   L_invc_date      invc_head.invc_date%TYPE;
   L_exists         VARCHAR2(1);
   L_item           shipsku.item%TYPE;
   L_unit_cost      invc_detail.invc_unit_cost%TYPE;
   L_rcpt           shipsku.shipment%TYPE;
   L_qty_match      ordloc_invc_cost.qty%TYPE := 0;
   L_qty            ordloc_invc_cost.qty%TYPE := NULL;
   L_qty_recv       ordloc_invc_cost.qty%TYPE := 0;
   L_qty_sum        ordloc_invc_cost.qty%TYPE := 0;
   L_assoc_qty      ordloc_invc_cost.qty%TYPE := 0;
   L_seq_no         ordloc_invc_cost.seq_no%TYPE;
   L_table          VARCHAR2(30);
   L_count          NUMBER(5)                 := 0;
   L_check          VARCHAR2(1);
   L_carton         shipsku.carton%type;
   L_shipsku_seq_no shipsku.seq_no%type;
   L_to_loc         shipment.to_loc%type;
   L_order_curr     ordhead.currency_code%TYPE;
   L_order_exch     ordhead.exchange_rate%TYPE;
   L_invc_curr      invc_head.currency_code%TYPE;
   L_invc_exch      invc_head.exchange_rate%TYPE;
   L_unit_cost_invc invc_match_wksht.invc_unit_cost%TYPE;
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DETAIL is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_DETAIL_ITEM is
      select 'X'
        from invc_detail
       where invc_id         = I_invc_id
         and item            = L_item
         and invc_unit_cost  = L_unit_cost
         for update nowait;

   cursor C_LOCK_WKSHT is
      select 'X'
        from invc_match_wksht
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_WKSHT_ITEM is
      select 'X'
        from invc_match_wksht
       where invc_id         = I_invc_id
         and item            = L_item
         and invc_unit_cost  = L_unit_cost
         for update nowait;

  cursor C_LOCK_ORDLOC_INVC is
      select 'X'
         from ordloc_invc_cost
        where match_invc_id = I_invc_id
          for update nowait;

   cursor C_ORDER is
      select inx.order_no,
             ih.invc_date
        from invc_xref inx,
             invc_head ih
       where inx.invc_id = I_invc_id
         and ih.invc_id  = inx.invc_id;

   cursor C_INSERT is
      select inx.order_no,
             sk.shipment,
             sk.item,
             sk.ref_item,
             NVL(sk.qty_received,0) qty_rec,
             sk.carton,
             sk.seq_no,
             sk.unit_cost,
             sh.to_loc,
             oh.currency_code order_curr,
             oh.exchange_rate order_exch,
             ih.currency_code invc_curr,
             ih.exchange_rate invc_exch
        from invc_xref inx,
             shipsku sk,
             shipment sh,
             ordhead oh,
             invc_head ih
       where inx.invc_id       = I_invc_id
         and inx.shipment      = sk.shipment
         and (sk.match_invc_id = I_invc_id
             or sk.match_invc_id is NULL)
         and sh.shipment       = sk.shipment
         and sh.order_no       = oh.order_no
         and ih.invc_id        = inx.invc_id;

   cursor C_CK_SHIPMENT is
      select 'Y'
        from ordloc_invc_cost
       where order_no            = L_order_no
         and item                = L_item
         and location            = L_to_loc
         and shipment            = L_rcpt
         and (match_invc_id is not NULL
              and match_invc_id != I_invc_id);

   cursor C_COUNT is
      select count(*)
         from ordloc_invc_cost
        where order_no = L_order_no
          and item     = L_item
         and shipment  = L_rcpt
          and location = L_to_loc
          and match_invc_id is NULL;

   cursor C_ORDLOC is
      select seq_no,
             qty,
             unit_cost
        from ordloc_invc_cost
       where order_no = L_order_no
         and item     = L_item
         and shipment = L_rcpt
         and location = L_to_loc
         and match_invc_id is NULL
       order by seq_no;

   cursor C_ORDLOC_QTY is
      select seq_no,
             qty,
             unit_cost
        from ordloc_invc_cost
       where order_no = L_order_no
         and item     = L_item
         and qty      = L_qty_recv
         and shipment = L_rcpt
         and location = L_to_loc
         and match_invc_id is NULL;

   cursor C_CHECK_INVC_MATCH is
      select 'X'
        from invc_match_wksht
       where invc_id        = I_invc_id
         and item           = L_item
         and invc_unit_cost = L_unit_cost
         and shipment       = L_rcpt
         and seq_no         = L_shipsku_seq_no;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_SQL.DEFAULT_ITEMS',
                                            NULL);
      return FALSE;
   end if;

   if I_overwrite is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_overwrite',
                                            'INVC_SQL.DEFAULT_ITEMS',
                                            NULL);
      return FALSE;
   end if;

   if SYSTEM_OPTIONS_SQL.GET_VAT_IND(L_vat_ind,
                                     O_error_message) = FALSE then

      return FALSE;
   end if;

   if I_overwrite = TRUE then

      L_table := 'INVC_MATCH_WKSHT';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_WKSHT',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_WKSHT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_WKSHT',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_WKSHT;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      delete
        from invc_match_wksht
       where invc_id = I_invc_id;
      ---
      L_table := 'INVC_DETAIL';
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

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      delete
        from invc_detail
       where invc_id = I_invc_id;


      L_table := 'ORDLOC_INVC_COST';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ORDLOC_INVC',
                       'ORDLOC_INVC_COST',
                       'INVC_ID:'||TO_CHAR(I_invc_id));
      open C_LOCK_ORDLOC_INVC;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ORDLOC_INVC',
                       'ORDLOC_INVC_COST',
                       'INVC_ID:'||TO_CHAR(I_invc_id));
      close C_LOCK_ORDLOC_INVC;

      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ORDLOC_INVC_COST',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      update ordloc_invc_cost
         set match_invc_id = NULL
       where match_invc_id = I_invc_id;
   end if;

   if L_vat_ind = 'Y' then

      SQL_LIB.SET_MARK('OPEN',
                       'C_ORDER',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_ORDER;

      SQL_LIB.SET_MARK('FETCH',
                       'C_ORDER',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      fetch C_ORDER into L_order_no, L_invc_date;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_ORDER',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_ORDER;

      if I_vat_region is NULL then

         if VAT_SQL.GET_VAT_REGION(O_error_message,
                                   L_vat_region,
                                   I_invc_id,
                                   L_order_no) = FALSE then
            return FALSE;
         end if;
      else
         L_vat_region := I_vat_region;
      end if;
   end if;
   ---
   for rec in C_INSERT LOOP
      -- for the locking cursor
      L_item           := rec.item;
      L_order_no       := rec.order_no;
      L_rcpt           := rec.shipment;
      L_qty_recv       := rec.qty_rec;
      L_unit_cost      := rec.unit_cost;
      L_carton         := rec.carton;
      L_shipsku_seq_no := rec.seq_no;
      L_to_loc         := rec.to_loc;
      L_qty            := NULL;
      L_exists         := 'N';
      L_order_curr     := rec.order_curr;
      L_order_exch     := rec.order_exch;
      L_invc_curr      := rec.invc_curr;
      L_invc_exch      := rec.invc_exch;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_CK_SHIPMENT',
                       'ORDLOC_INVC_COST',
                       'ORDER NO:'||TO_CHAR(L_order_no)||
                       ',ITEM :'||L_item);
      open C_CK_SHIPMENT;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CK_SHIPMENT',
                       'ORDLOC_INVC_COST',
                       'ORDER NO:'||TO_CHAR(L_order_no)||
                       ',ITEM :'||L_item);
      fetch C_CK_SHIPMENT into L_exists;

      -- if the record found, the shipment has already been matched
      ---
      if C_CK_SHIPMENT%NOTFOUND then

         SQL_LIB.SET_MARK('CLOSE',
                          'C_CK_SHIPMENT',
                          'ORDLOC_INVC_COST',
                          'ORDER NO:'||TO_CHAR(L_order_no)||
                          ',ITEM :'||L_item);
         close C_CK_SHIPMENT;


         SQL_LIB.SET_MARK('OPEN',
                          'C_COUNT',
                          'ORDLOC_INVC_COST',
                          'ORDER NO:'||TO_CHAR(L_order_no)||
                          ',ITEM :'||L_item);
         open C_COUNT;
         SQL_LIB.SET_MARK('FETCH',
                          'C_COUNT',
                          'ORDLOC_INVC_COST',
                          'ORDER NO:'||TO_CHAR(L_order_no)||
                          ',ITEM :'||L_item);
         fetch C_COUNT into L_count;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_COUNT',
                          'ORDLOC_INVC_COST',
                          'ORDER NO:'||TO_CHAR(L_order_no)||
                          ',ITEM :'||L_item);
         close C_COUNT;

         ---
         if L_count = 0 then  --this invoice has no deals associated with it.
            ---
            L_table := 'INVC_DETAIL';
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_DETAIL_ITEM',
                             'INVC_DETAIL',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost));
            open C_LOCK_DETAIL_ITEM;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_DETAIL_ITEM',
                             'INVC_DETAIL',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost));
            close C_LOCK_DETAIL_ITEM;
            ---
            if L_order_curr != L_invc_curr then
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_unit_cost,
                                       L_order_curr,
                                       L_invc_curr,
                                       L_unit_cost_invc,
                                       'C',
                                       NULL,
                                       NULL,
                                       L_order_exch,
                                       L_invc_exch) = FALSE then
                  return FALSE;
               end if;
            else
               L_unit_cost_invc := L_unit_cost;
            end if;
            ---
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'INVC_DETAIL',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost));

            update invc_detail
               set invc_qty                = (invc_qty + L_qty_recv),
                   orig_qty                = (orig_qty + L_qty_recv)
                  where invc_id            = I_invc_id
                    and item               = L_item
                    and invc_unit_cost     = L_unit_cost_invc;

            if SQL%NOTFOUND then
               ---
               if L_vat_region is NOT NULL then
                  if INVC_ATTRIB_SQL.GET_MATCH_RCPT_VAT_RATE (O_error_message,
                                                              L_vat_rate,
                                                              I_invc_id,
                                                              L_invc_date,
                                                              L_rcpt,
                                                              L_item,
                                                              L_vat_region) = FALSE then
                      return FALSE;
                  end if;
               end if;
               ---
               SQL_LIB.SET_MARK('INSERT',
                                NULL,
                                'INVC_DETAIL',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost));

               insert into invc_detail(invc_id,
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
                                values(I_invc_id,
                                       L_item,
                                       rec.ref_item,
                                       L_unit_cost_invc,
                                       L_qty_recv,
                                       L_vat_rate,
                                       'U',
                                       L_unit_cost_invc,
                                       L_qty_recv,
                                       L_vat_rate,
                                       'N',
                                       'N',
                                       'N',
                                       'N',
                                       NULL);
            end if;

            SQL_LIB.SET_MARK('OPEN',
                             'C_CHECK_INVC_MATCH',
                             'INVC_MATCH_WKSHT',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost)||
                             ',SHIPMENT:'||TO_CHAR(L_rcpt));
            open C_CHECK_INVC_MATCH;

            SQL_LIB.SET_MARK('FETCH',
                             'C_CHECK_INVC_MATCH',
                             'INVC_MATCH_WKSHT',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost)||
                             ',SHIPMENT:'||TO_CHAR(L_rcpt));
            fetch C_CHECK_INVC_MATCH into L_check;
            ---
            if C_CHECK_INVC_MATCH%NOTFOUND then
               SQL_LIB.SET_MARK('CLOSE',
                                'C_CHECK_INVC_MATCH',
                                'INVC_MATCH_WKSHT',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost)||
                                ',SHIPMENT:'||TO_CHAR(L_rcpt));
               close C_CHECK_INVC_MATCH;

               SQL_LIB.SET_MARK('INSERT',
                                NULL,
                                'INVC_MATCH_WKSHT',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost));
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
                                      values(I_invc_id,
                                             L_item,
                                             L_unit_cost_invc,
                                             L_rcpt,
                                             L_shipsku_seq_no,
                                             L_carton,
                                             NULL,
                                             L_unit_cost_invc,
                                             L_qty_recv,
                                             NULL);
            else
               SQL_LIB.SET_MARK('CLOSE',
                                'C_CHECK_INVC_MATCH',
                                'INVC_MATCH_WKSHT',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost)||
                                ',SHIPMENT:'||TO_CHAR(L_rcpt));
                 close C_CHECK_INVC_MATCH;
            end if;
            ---
         elsif L_count = 1 then  --the invoice has a non- buy/get deal associated.
         ---
            SQL_LIB.SET_MARK('OPEN',
                             'C_ORDLOC',
                             'ORDLOC_INVC_COST',
                             'ORDER NO:'||TO_CHAR(L_order_no)||
                             ',ITEM :'||L_item);
            open C_ORDLOC;
            SQL_LIB.SET_MARK('FETCH',
                             'C_ORDLOC',
                             'ORDLOC_INVC_COST',
                             'ORDER NO:'||TO_CHAR(L_order_no)||
                             ',ITEM :'||L_item);
            fetch C_ORDLOC into L_seq_no,
                                L_qty,
                                L_unit_cost;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_ORDLOC',
                             'ORDLOC_INVC_COST',
                             'ORDER NO:'||TO_CHAR(L_order_no)||
                             ',ITEM :'||L_item);
            close C_ORDLOC;
            ---
            -- If the qty in ordloc_invc_cost is less than or equal to
            -- the qty_received in shipsku, update tables with the
            -- ordloc_invc_cost qty.  Otherwise, update tables with the
            -- qty_received.
            ---
            if L_qty <= L_qty_recv then
               L_qty_match := L_qty;
            else
               L_qty_match := L_qty_recv;
            end if;
            ---
            L_table := 'INVC_DETAIL';
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_DETAIL_ITEM',
                             'INVC_DETAIL',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost));
            open C_LOCK_DETAIL_ITEM;

            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_DETAIL_ITEM',
                             'INVC_DETAIL',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost));
            close C_LOCK_DETAIL_ITEM;
            ---
            if L_order_curr != L_invc_curr then
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_unit_cost,
                                       L_order_curr,
                                       L_invc_curr,
                                       L_unit_cost_invc,
                                       'C',
                                       NULL,
                                       NULL,
                                       L_order_exch,
                                       L_invc_exch) = FALSE then
                  return FALSE;
               end if;
            else
               L_unit_cost_invc := L_unit_cost;
            end if;
            ---
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'INVC_DETAIL',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost));

            update invc_detail
               set invc_qty                = (invc_qty + L_qty_match),
                   orig_qty                = (orig_qty + L_qty_match)
                  where invc_id            = I_invc_id
                    and item               = L_item
                    and invc_unit_cost     = L_unit_cost_invc;

            if SQL%NOTFOUND then
               ---
               if L_vat_region is NOT NULL then
                  if INVC_ATTRIB_SQL.GET_MATCH_RCPT_VAT_RATE (O_error_message,
                                                              L_vat_rate,
                                                              I_invc_id,
                                                              L_invc_date,
                                                              L_rcpt,
                                                              L_item,
                                                              L_vat_region) = FALSE then
                      return FALSE;
                   end if;
               end if;
               ---
               SQL_LIB.SET_MARK('INSERT',
                                NULL,
                                'INVC_DETAIL',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost));

               insert into invc_detail(invc_id,
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
                                values(I_invc_id,
                                       L_item,
                                       rec.ref_item,
                                       L_unit_cost_invc,
                                       L_qty_match,
                                       L_vat_rate,
                                       'U',
                                       L_unit_cost_invc,
                                       L_qty_match,
                                       L_vat_rate,
                                       'N',
                                       'N',
                                       'N',
                                       'N',
                                       NULL);
             end if;

             SQL_LIB.SET_MARK('OPEN',
                              'C_CHECK_INVC_MATCH',
                              'INVC_MATCH_WKSHT',
                              'INVOICE:'||TO_CHAR(I_invc_id)||
                              ',ITEM:'||L_item||
                              ',COST:'||TO_CHAR(L_unit_cost)||
                              ',SHIPMENT:'||TO_CHAR(L_rcpt));
            open C_CHECK_INVC_MATCH;

            SQL_LIB.SET_MARK('FETCH',
                             'C_CHECK_INVC_MATCH',
                             'INVC_MATCH_WKSHT',
                             'INVOICE:'||TO_CHAR(I_invc_id)||
                             ',ITEM:'||L_item||
                             ',COST:'||TO_CHAR(L_unit_cost)||
                             ',SHIPMENT:'||TO_CHAR(L_rcpt));
            fetch C_CHECK_INVC_MATCH into L_check;

            if C_CHECK_INVC_MATCH%NOTFOUND then
               SQL_LIB.SET_MARK('CLOSE',
                                'C_CHECK_INVC_MATCH',
                                'INVC_MATCH_WKSHT',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost)||
                                ',SHIPMENT:'||TO_CHAR(L_rcpt));
               close C_CHECK_INVC_MATCH;

               SQL_LIB.SET_MARK('INSERT',
                                NULL,
                                'INVC_MATCH_WKSHT',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost));
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
                                      values(I_invc_id,
                                             L_item,
                                             L_unit_cost_invc,
                                             L_rcpt,
                                             L_shipsku_seq_no,
                                             L_carton,
                                             NULL,
                                             L_unit_cost_invc,
                                             L_qty_match,
                                             L_seq_no);
            else
               SQL_LIB.SET_MARK('CLOSE',
                                'C_CHECK_INVC_MATCH',
                                'INVC_MATCH_WKSHT',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost)||
                                ',SHIPMENT:'||TO_CHAR(L_rcpt));
               close C_CHECK_INVC_MATCH;
            end if;
            ---
         else   -- L_count > 1 , means the invoice has an associated buy/get deal.
            SQL_LIB.SET_MARK('OPEN',
                             'C_ORDLOC_QTY',
                             'ORDLOC_INVC_COST',
                             'ORDER NO:'||TO_CHAR(L_order_no)||
                             ',ITEM :'||L_item);
            open C_ORDLOC_QTY;
            SQL_LIB.SET_MARK('FETCH',
                             'C_ORDLOC_QTY',
                             'ORDLOCINVC_COST',
                             'ORDER NO:'||TO_CHAR(L_order_no)||
                             ',ITEM :'||L_item);
            fetch C_ORDLOC_QTY into L_seq_no,
                                    L_qty,
                                    L_unit_cost;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_ORDLOC_QTY',
                             'ORDLOC_INVC_COST',
                             'ORDER NO:'||TO_CHAR(L_order_no)||
                             ',ITEM :'||L_item);
            close C_ORDLOC_QTY;

            if L_qty is NOT NULL then
               ---
               -- qty from ordloc is equal to the qty received from shipsku
               ---
               L_table := 'INVC_DETAIL';
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_DETAIL_ITEM',
                                'INVC_DETAIL',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost));
               open C_LOCK_DETAIL_ITEM;

               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_DETAIL_ITEM',
                                'INVC_DETAIL',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost));
               close C_LOCK_DETAIL_ITEM;
               ---
               if L_order_curr != L_invc_curr then
                  if CURRENCY_SQL.CONVERT(O_error_message,
                                          L_unit_cost,
                                          L_order_curr,
                                          L_invc_curr,
                                          L_unit_cost_invc,
                                          'C',
                                          NULL,
                                          NULL,
                                          L_order_exch,
                                          L_invc_exch) = FALSE then
                     return FALSE;
                  end if;
               else
                  L_unit_cost_invc := L_unit_cost;
               end if;
               ---
               SQL_LIB.SET_MARK('UPDATE',
                                NULL,
                                'INVC_DETAIL',
                                'INVOICE:'||TO_CHAR(I_invc_id));
               update invc_detail
                  set invc_qty            = (invc_qty + L_qty),
                      orig_qty            = (orig_qty + L_qty)
                     where invc_id        = I_invc_id
                       and item           = L_item
                       and invc_unit_cost = L_unit_cost_invc;

               if SQL%NOTFOUND then
                  ---
                  if L_vat_region is NOT NULL then
                     if INVC_ATTRIB_SQL.GET_MATCH_RCPT_VAT_RATE (O_error_message,
                                                                 L_vat_rate,
                                                                 I_invc_id,
                                                                 L_invc_date,
                                                                 L_rcpt,
                                                                 L_item,
                                                                 L_vat_region) = FALSE then
                         return FALSE;
                     end if;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'INVC_DETAIL',
                                   'INVOICE:'||TO_CHAR(I_invc_id)||
                                   ',ITEM:'||L_item||
                                   ',COST:'||TO_CHAR(L_unit_cost));

                  insert into invc_detail(invc_id,
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
                                   values(I_invc_id,
                                          L_item,
                                          rec.ref_item,
                                          L_unit_cost_invc,
                                          L_qty,
                                          L_vat_rate,
                                          'U',
                                          L_unit_cost_invc,
                                          L_qty,
                                          L_vat_rate,
                                          'N',
                                          'N',
                                          'N',
                                          'N',
                                          NULL);
               end if;

               SQL_LIB.SET_MARK('OPEN',
                                'C_CHECK_INVC_MATCH',
                                'INVC_MATCH_WKSHT',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost)||
                                ',SHIPMENT:'||TO_CHAR(L_rcpt));

               open C_CHECK_INVC_MATCH;

               SQL_LIB.SET_MARK('FETCH',
                                'C_CHECK_INVC_MATCH',
                                'INVC_MATCH_WKSHT',
                                'INVOICE:'||TO_CHAR(I_invc_id)||
                                ',ITEM:'||L_item||
                                ',COST:'||TO_CHAR(L_unit_cost)||
                                ',SHIPMENT:'||TO_CHAR(L_rcpt));

               fetch C_CHECK_INVC_MATCH into L_check;

               if C_CHECK_INVC_MATCH%NOTFOUND then
                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_CHECK_INVC_MATCH',
                                   'INVC_MATCH_WKSHT',
                                   'INVOICE:'||TO_CHAR(I_invc_id)||
                                   ',ITEM:'||L_item||
                                   ',COST:'||TO_CHAR(L_unit_cost)||
                                   ',SHIPMENT:'||TO_CHAR(L_rcpt));

                  close C_CHECK_INVC_MATCH;

                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'INVC_MATCH_WKSHT',
                                   'INVOICE:'||TO_CHAR(I_invc_id)||
                                   ',ITEM:'||L_item||
                                   ',COST:'||TO_CHAR(L_unit_cost));
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
                                         values(I_invc_id,
                                                L_item,
                                                L_unit_cost_invc,
                                                L_rcpt,
                                                L_shipsku_seq_no,
                                                L_carton,
                                                NULL,
                                                L_unit_cost_invc,
                                                L_qty_recv,
                                                L_seq_no);
               else
                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_CHECK_INVC_MATCH',
                                   'INVC_MATCH_WKSHT',
                                   'INVOICE:'||TO_CHAR(I_invc_id)||
                                   ',ITEM:'||L_item||
                                   ',COST:'||TO_CHAR(L_unit_cost)||
                                   ',SHIPMENT:'||TO_CHAR(L_rcpt));
                  close C_CHECK_INVC_MATCH;
               end if;

            else
               -- qty is not equal to qty received
               ---
               SQL_LIB.SET_MARK('OPEN',
                                'C_ORDLOC',
                                'ORDLOC_INVC_COST',
                                'ORDER NO:'||TO_CHAR(L_order_no)||
                                ',ITEM :'||L_item);
               open C_ORDLOC;
               SQL_LIB.SET_MARK('FETCH',
                                'C_ORDLOC',
                                'ORDLOC_INVC_COST',
                                'ORDER NO:'||TO_CHAR(L_order_no)||
                                ',ITEM :'||L_item);
               fetch C_ORDLOC into L_seq_no,
                                   L_qty,
                                   L_unit_cost;
               ---
               L_qty_sum := L_qty;
               ---
               if L_qty < L_qty_recv then
                  LOOP
                     ---
                    L_table := 'INVC_DETAIL';
                     SQL_LIB.SET_MARK('OPEN',
                                      'C_LOCK_DETAIL_ITEM',
                                      'INVC_DETAIL',
                                      'INVOICE:'||TO_CHAR(I_invc_id)||
                                      ',ITEM:'||L_item||
                                      ',COST:'||TO_CHAR(L_unit_cost));
                     open C_LOCK_DETAIL_ITEM;

                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_LOCK_DETAIL_ITEM',
                                      'INVC_DETAIL',
                                      'INVOICE:'||TO_CHAR(I_invc_id)||
                                      ',ITEM:'||L_item||
                                      ',COST:'||TO_CHAR(L_unit_cost));
                     close C_LOCK_DETAIL_ITEM;
                     ---
                     if L_order_curr != L_invc_curr then
                        if CURRENCY_SQL.CONVERT(O_error_message,
                                                L_unit_cost,
                                                L_order_curr,
                                                L_invc_curr,
                                                L_unit_cost_invc,
                                                'C',
                                                NULL,
                                                NULL,
                                                L_order_exch,
                                                L_invc_exch) = FALSE then
                           return FALSE;
                        end if;
                     else
                        L_unit_cost_invc := L_unit_cost;
                     end if;
                     ---
                     SQL_LIB.SET_MARK('UPDATE',
                                      NULL,
                                      'INVC_DETAIL',
                                      'INVOICE:'||TO_CHAR(I_invc_id));
                     update invc_detail
                        set invc_qty           = (invc_qty + L_qty),
                            orig_qty           = (orig_qty + L_qty)
                          where invc_id        = I_invc_id
                            and item           = L_item
                            and invc_unit_cost = L_unit_cost_invc;

                     if SQL%NOTFOUND then
                        ---
                        if L_vat_region is NOT NULL then
                           if INVC_ATTRIB_SQL.GET_MATCH_RCPT_VAT_RATE (O_error_message,
                                                                       L_vat_rate,
                                                                       I_invc_id,
                                                                       L_invc_date,
                                                                       L_rcpt,
                                                                       L_item,
                                                                       L_vat_region) = FALSE then
                              return FALSE;
                           end if;
                        end if;
                        ---
                        SQL_LIB.SET_MARK('INSERT',
                                           NULL,
                                          'INVC_DETAIL',
                                          'INVOICE:'||TO_CHAR(I_invc_id)||
                                          ',ITEM:'||L_item||
                                          ',COST:'||TO_CHAR(L_unit_cost));

                        insert into invc_detail(invc_id,
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
                                         values(I_invc_id,
                                                L_item,
                                                rec.ref_item,
                                                L_unit_cost_invc,
                                                L_qty,
                                                L_vat_rate,
                                                'U',
                                                L_unit_cost_invc,
                                                L_qty,
                                                L_vat_rate,
                                                'N',
                                                'N',
                                                'N',
                                                'N',
                                                NULL);
                     end if;

                     SQL_LIB.SET_MARK('OPEN',
                                      'C_CHECK_INVC_MATCH',
                                      'INVC_MATCH_WKSHT',
                                      'INVOICE:'||TO_CHAR(I_invc_id)||
                                      ',ITEM:'||L_item||
                                      ',COST:'||TO_CHAR(L_unit_cost)||
                                      ',SHIPMENT:'||TO_CHAR(L_rcpt));
                     open C_CHECK_INVC_MATCH;

                     SQL_LIB.SET_MARK('FETCH',
                                      'C_CHECK_INVC_MATCH',
                                      'INVC_MATCH_WKSHT',
                                      'INVOICE:'||TO_CHAR(I_invc_id)||
                                      ',ITEM:'||L_item||
                                      ',COST:'||TO_CHAR(L_unit_cost)||
                                      ',SHIPMENT:'||TO_CHAR(L_rcpt));
                     fetch C_CHECK_INVC_MATCH into L_check;

                     if C_CHECK_INVC_MATCH%NOTFOUND then
                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_CHECK_INVC_MATCH',
                                         'INVC_MATCH_WKSHT',
                                         'INVOICE:'||TO_CHAR(I_invc_id)||
                                         ',ITEM:'||L_item||
                                         ',COST:'||TO_CHAR(L_unit_cost)||
                                         ',SHIPMENT:'||TO_CHAR(L_rcpt));
                         close C_CHECK_INVC_MATCH;

                        SQL_LIB.SET_MARK('INSERT',
                                         NULL,
                                         'INVC_MATCH_WKSHT',
                                         'INVOICE:'||TO_CHAR(I_invc_id)||
                                         ',ITEM:'||L_item||
                                         ',COST:'||TO_CHAR(L_unit_cost));
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
                                               values(I_invc_id,
                                                      L_item,
                                                      L_unit_cost_invc,
                                                      L_rcpt,
                                                      L_shipsku_seq_no,
                                                      L_carton,
                                                      NULL,
                                                      L_unit_cost_invc,
                                                      L_qty,
                                                      L_seq_no);
                     else
                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_CHECK_INVC_MATCH',
                                         'INVC_MATCH_WKSHT',
                                         'INVOICE:'||TO_CHAR(I_invc_id)||
                                         ',ITEM:'||L_item||
                                         ',COST:'||TO_CHAR(L_unit_cost)||
                                         ',SHIPMENT:'||TO_CHAR(L_rcpt));
                        close C_CHECK_INVC_MATCH;
                     end if;
                     ---
                     L_assoc_qty := L_qty_recv - L_qty_sum;
                     ---
                     SQL_LIB.SET_MARK('FETCH',
                                      'C_ORDLOC',
                                      'ORDLOC_INVC_COST',
                                      'ORDER NO:'||TO_CHAR(L_order_no)||
                                      ',ITEM :'||L_item);
                     fetch C_ORDLOC into L_seq_no,
                                         L_qty,
                                         L_unit_cost;
                     if C_ORDLOC%NOTFOUND then
                        EXIT;
                     end if;
                     ---
                     L_qty_sum := L_qty_sum + L_qty;
                     ---
                     if L_qty_sum >= L_qty_recv then
                        L_table := 'INVC_DETAIL';
                        SQL_LIB.SET_MARK('OPEN',
                                         'C_LOCK_DETAIL_ITEM',
                                         'INVC_DETAIL',
                                         'INVOICE:'||TO_CHAR(I_invc_id)||
                                         ',ITEM:'||L_item||
                                         ',COST:'||TO_CHAR(L_unit_cost));
                        open C_LOCK_DETAIL_ITEM;

                        SQL_LIB.SET_MARK('CLOSE',
                                         'C_LOCK_DETAIL_ITEM',
                                         'INVC_DETAIL',
                                         'INVOICE:'||TO_CHAR(I_invc_id)||
                                         ',ITEM:'||L_item||
                                         ',COST:'||TO_CHAR(L_unit_cost));
                        close C_LOCK_DETAIL_ITEM;
                        ---
                        if L_order_curr != L_invc_curr then
                           if CURRENCY_SQL.CONVERT(O_error_message,
                                                   L_unit_cost,
                                                   L_order_curr,
                                                   L_invc_curr,
                                                   L_unit_cost_invc,
                                                   'C',
                                                   NULL,
                                                   NULL,
                                                   L_order_exch,
                                                   L_invc_exch) = FALSE then
                              return FALSE;
                           end if;
                        else
                           L_unit_cost_invc := L_unit_cost;
                        end if;
                        ---
                        SQL_LIB.SET_MARK('UPDATE',
                                         NULL,
                                         'INVC_DETAIL',
                                         'INVOICE:'||TO_CHAR(I_invc_id));
                        update invc_detail
                           set invc_qty         = (invc_qty + L_assoc_qty),
                               orig_qty         = (orig_qty + L_assoc_qty)
                           where invc_id        = I_invc_id
                             and item           = L_item
                             and invc_unit_cost = L_unit_cost_invc;

                        if SQL%NOTFOUND then
                           ---
                           if L_vat_region is NOT NULL then
                              if INVC_ATTRIB_SQL.GET_MATCH_RCPT_VAT_RATE (O_error_message,
                                                                          L_vat_rate,
                                                                          I_invc_id,
                                                                          L_invc_date,
                                                                          L_rcpt,
                                                                          L_item,
                                                                          L_vat_region) = FALSE then
                                 return FALSE;
                              end if;
                           end if;
                           ---
                           SQL_LIB.SET_MARK('INSERT',
                                            NULL,
                                            'INVC_DETAIL',
                                            'INVOICE:'||TO_CHAR(I_invc_id)||
                                            ',ITEM:'||L_item||
                                            ',COST:'||TO_CHAR(L_unit_cost));

                           insert into invc_detail(invc_id,
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
                                            values(I_invc_id,
                                                   L_item,
                                                   rec.ref_item,
                                                   L_unit_cost_invc,
                                                   L_assoc_qty,
                                                   L_vat_rate,
                                                   'U',
                                                   L_unit_cost_invc,
                                                   L_assoc_qty,
                                                   L_vat_rate,
                                                   'N',
                                                   'N',
                                                   'N',
                                                   'N',
                                                    NULL);
                        end if;

                        SQL_LIB.SET_MARK('OPEN',
                                         'C_CHECK_INVC_MATCH',
                                         'INVC_MATCH_WKSHT',
                                         'INVOICE:'||TO_CHAR(I_invc_id)||
                                         ',ITEM:'||L_item||
                                         ',COST:'||TO_CHAR(L_unit_cost)||
                                         ',SHIPMENT:'||TO_CHAR(L_rcpt));
                        open C_CHECK_INVC_MATCH;

                        SQL_LIB.SET_MARK('FETCH',
                                         'C_CHECK_INVC_MATCH',
                                         'INVC_MATCH_WKSHT',
                                         'INVOICE:'||TO_CHAR(I_invc_id)||
                                         ',ITEM:'||L_item||
                                         ',COST:'||TO_CHAR(L_unit_cost)||
                                         ',SHIPMENT:'||TO_CHAR(L_rcpt));
                        fetch C_CHECK_INVC_MATCH into L_check;

                        if C_CHECK_INVC_MATCH%NOTFOUND then
                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_CHECK_INVC_MATCH',
                                            'INVC_MATCH_WKSHT',
                                            'INVOICE:'||TO_CHAR(I_invc_id)||
                                            ',ITEM:'||L_item||
                                            ',COST:'||TO_CHAR(L_unit_cost)||
                                            ',SHIPMENT:'||TO_CHAR(L_rcpt));
                           close C_CHECK_INVC_MATCH;

                           SQL_LIB.SET_MARK('INSERT',
                                            NULL,
                                            'INVC_MATCH_WKSHT',
                                            'INVOICE:'||TO_CHAR(I_invc_id)||
                                            ',ITEM:'||L_item||
                                            ',COST:'||TO_CHAR(L_unit_cost));
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
                                                  values(I_invc_id,
                                                         L_item,
                                                         L_unit_cost_invc,
                                                         L_rcpt,
                                                         L_shipsku_seq_no,
                                                         L_carton,
                                                         NULL,
                                                         L_unit_cost_invc,
                                                         L_assoc_qty,
                                                         L_seq_no);
                        else
                           SQL_LIB.SET_MARK('CLOSE',
                                            'C_CHECK_INVC_MATCH',
                                            'INVC_MATCH_WKSHT',
                                            'INVOICE:'||TO_CHAR(I_invc_id)||
                                            ',ITEM:'||L_item||
                                            ',COST:'||TO_CHAR(L_unit_cost)||
                                            ',SHIPMENT:'||TO_CHAR(L_rcpt));

                           close C_CHECK_INVC_MATCH;
                        end if;

                        EXIT;
                     end if; -- L_qty_sum >= L_qty_recv
                  END LOOP;
                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_ORDLOC',
                                   'ORDLOC_INVC_COST',
                                   'ORDER NO:'||TO_CHAR(L_order_no)||
                                   ',ITEM :'||L_item);
                  close C_ORDLOC;

               elsif L_qty > L_qty_recv then
                  ---
                  L_table := 'INVC_DETAIL';
                  SQL_LIB.SET_MARK('OPEN',
                                   'C_LOCK_DETAIL_ITEM',
                                   'INVC_DETAIL',
                                   'INVOICE:'||TO_CHAR(I_invc_id)||
                                   ',ITEM:'||L_item||
                                   ',COST:'||TO_CHAR(L_unit_cost));
                  open C_LOCK_DETAIL_ITEM;
                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_LOCK_DETAIL_ITEM',
                                   'INVC_DETAIL',
                                   'INVOICE:'||TO_CHAR(I_invc_id)||
                                   ',ITEM:'||L_item||
                                   ',COST:'||TO_CHAR(L_unit_cost));
                  close C_LOCK_DETAIL_ITEM;
                  ---
                  if L_order_curr != L_invc_curr then
                     if CURRENCY_SQL.CONVERT(O_error_message,
                                             L_unit_cost,
                                             L_order_curr,
                                             L_invc_curr,
                                             L_unit_cost_invc,
                                             'C',
                                             NULL,
                                             NULL,
                                             L_order_exch,
                                             L_invc_exch) = FALSE then
                        return FALSE;
                     end if;
                  else
                     L_unit_cost_invc := L_unit_cost;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('UPDATE',
                                   NULL,
                                   'INVC_DETAIL',
                                   'INVOICE:'||TO_CHAR(I_invc_id));
                  update invc_detail
                     set invc_qty        = (invc_qty + L_qty_recv),
                       orig_qty          = (orig_qty + L_qty_recv)
                    where invc_id        = I_invc_id
                      and item           = L_item
                      and invc_unit_cost = L_unit_cost_invc;

                  if SQL%NOTFOUND then
                     ---
                     if L_vat_region is NOT NULL then
                        if INVC_ATTRIB_SQL.GET_MATCH_RCPT_VAT_RATE (O_error_message,
                                                                    L_vat_rate,
                                                                    I_invc_id,
                                                                    L_invc_date,
                                                                    L_rcpt,
                                                                    L_item,
                                                                    L_vat_region) = FALSE then
                           return FALSE;
                        end if;
                     end if;
                     ---
                     SQL_LIB.SET_MARK('INSERT',
                                      NULL,
                                      'INVC_DETAIL',
                                      'INVOICE:'||TO_CHAR(I_invc_id)||
                                      ',ITEM:'||L_item||
                                      ',COST:'||TO_CHAR(L_unit_cost));
                      insert into invc_detail(invc_id,
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
                                       values(I_invc_id,
                                              L_item,
                                              rec.ref_item,
                                              L_unit_cost_invc,
                                              L_qty_recv,
                                              L_vat_rate,
                                              'U',
                                              L_unit_cost_invc,
                                              L_qty_recv,
                                              L_vat_rate,
                                              'N',
                                              'N',
                                              'N',
                                              'N',
                                              NULL);
                  end if;

                  SQL_LIB.SET_MARK('OPEN',
                                   'C_CHECK_INVC_MATCH',
                                   'INVC_MATCH_WKSHT',
                                   'INVOICE:'||TO_CHAR(I_invc_id)||
                                   ',ITEM:'||L_item||
                                   ',COST:'||TO_CHAR(L_unit_cost)||
                                   ',SHIPMENT:'||TO_CHAR(L_rcpt));

                  open C_CHECK_INVC_MATCH;

                  SQL_LIB.SET_MARK('FETCH',
                                   'C_CHECK_INVC_MATCH',
                                   'INVC_MATCH_WKSHT',
                                   'INVOICE:'||TO_CHAR(I_invc_id)||
                                   ',ITEM:'||L_item||
                                   ',COST:'||TO_CHAR(L_unit_cost)||
                                   ',SHIPMENT:'||TO_CHAR(L_rcpt));

                  fetch C_CHECK_INVC_MATCH into L_check;

                  if C_CHECK_INVC_MATCH%NOTFOUND then
                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_CHECK_INVC_MATCH',
                                      'INVC_MATCH_WKSHT',
                                      'INVOICE:'||TO_CHAR(I_invc_id)||
                                      ',ITEM:'||L_item||
                                      ',COST:'||TO_CHAR(L_unit_cost)||
                                      ',SHIPMENT:'||TO_CHAR(L_rcpt));

                     close C_CHECK_INVC_MATCH;

                     SQL_LIB.SET_MARK('INSERT',
                                      NULL,
                                      'INVC_MATCH_WKSHT',
                                      'INVOICE:'||TO_CHAR(I_invc_id)||
                                      ',ITEM:'||L_item||
                                      ',COST:'||TO_CHAR(L_unit_cost));
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
                                            values(I_invc_id,
                                                   L_item,
                                                   L_unit_cost_invc,
                                                   L_rcpt,
                                                   L_shipsku_seq_no,
                                                   L_carton,
                                                   NULL,
                                                   L_unit_cost_invc,
                                                   L_qty_recv,
                                                   L_seq_no);
                  else
                     SQL_LIB.SET_MARK('CLOSE',
                                      'C_CHECK_INVC_MATCH',
                                      'INVC_MATCH_WKSHT',
                                      'INVOICE:'||TO_CHAR(I_invc_id)||
                                      ',ITEM:'||L_item||
                                      ',COST:'||TO_CHAR(L_unit_cost)||
                                      ',SHIPMENT:'||TO_CHAR(L_rcpt));

                     close C_CHECK_INVC_MATCH;
                  end if;
                  SQL_LIB.SET_MARK('CLOSE',
                                   'C_ORDLOC',
                                   'ORDLOC_INVC_COST',
                                   'ORDER NO:'||TO_CHAR(L_order_no)||
                                   ',ITEM :'||L_item);
                  close C_ORDLOC;
               end if;
            end if;
         end if; -- count > 1

      else -- C_CK_SHIPMENT%NOTFOUND
         SQL_LIB.SET_MARK('CLOSE',
                          'C_CK_SHIPMENT',
                          'ORDLOC_INVC_COST',
                          'ORDER NO:'||TO_CHAR(L_order_no)||
                          ',ITEM :'||L_item);
         close C_CK_SHIPMENT;
      end if;
   END LOOP;
   ---
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
                                            'INVC_SQL.DEFAULT_ITEMS',
                                            TO_CHAR(SQLCODE));
      return FALSE;


END DEFAULT_ITEMS;
--------------------------------------------------------------------
FUNCTION NEXT_INVC_ID(O_error_message   IN OUT   VARCHAR2,
                      O_invc_id         IN OUT   INVC_HEAD.INVC_ID%TYPE)
   RETURN BOOLEAN IS

   L_check              VARCHAR2(1) :='N';
   L_wrap_sequence_no   invc_head.invc_id%TYPE;
   L_first_time         VARCHAR2(3) := 'yes';

   cursor C_INVOICE_SEQ is
      select invc_sequence.NEXTVAL
        from dual;

   cursor C_INVOICE_EXISTS is
      select 'Y'
        from invc_head
       where invc_id = O_invc_id;

BEGIN

   LOOP
      L_check := 'N';
      SQL_LIB.SET_MARK('OPEN',
                       'C_INVOICE_SEQ',
                       'DUAL',
                        NULL);
      open C_INVOICE_SEQ;

      SQL_LIB.SET_MARK('FETCH',
                       'C_INVOICE_SEQ',
                       'DUAL',
                        NULL);
      fetch C_INVOICE_SEQ into O_invc_id;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_INVOICE_SEQ',
                       'DUAL',
                        NULL);
      close C_INVOICE_SEQ;

      if L_first_time        = 'yes' then
         L_wrap_sequence_no := O_invc_id;
         L_first_time       := 'no';
      elsif O_invc_id        = L_wrap_sequence_no then
         O_error_message    := SQL_LIB.CREATE_MSG('NO_MORE_WO_ID_SEQUENCE',
                                                  NULL,
                                                  NULL,
                                                  NULL);
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_INVOICE_EXISTS',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(O_invc_id));
      open C_INVOICE_EXISTS;

      SQL_LIB.SET_MARK('FETCH',
                       'C_INVOICE_EXISTS',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(O_invc_id));
      fetch C_INVOICE_EXISTS into L_check;

      if C_INVOICE_EXISTS%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_INVOICE_EXISTS',
                          'INVC_HEAD',
                          'INVOICE:'||TO_CHAR(O_invc_id));
         close C_INVOICE_EXISTS;
         EXIT;
      end if;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_INVOICE_EXISTS',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(O_invc_id));
      close C_INVOICE_EXISTS;

   END LOOP;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                            'INVC_SQL.NEXT_INVC_ID',
                                             TO_CHAR(SQLCODE));
      return FALSE;

END NEXT_INVC_ID;
--------------------------------------------------------------------
FUNCTION DELETE_INVC(O_error_message   IN OUT   VARCHAR2,
                     I_invc_id         IN       INVC_HEAD.INVC_ID%TYPE,
                     I_item            IN       INVC_DETAIL.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_table          VARCHAR2(30);
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   cursor C_CHECK_REF_INVC is
      select invc_id
        from invc_head
       where ref_invc_id = I_invc_id;

   cursor C_LOCK_DETAIL is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_NON_MERCH is
      select 'X'
        from invc_non_merch
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_MERCH_VAT is
      select 'X'
        from invc_merch_vat
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_INVC_DETAIL_VAT is
      select 'x'
        from invc_detail_vat
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_MATCH_QUEUE is
      select 'X'
        from invc_match_queue
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_HEAD is
      select 'X'
        from invc_head
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_DISC is
      select 'X'
        from invc_discount
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_DETAIL_ITEM is
      select 'X'
        from invc_detail
       where invc_id = I_invc_id
         and item    = I_item
         for update nowait;

   cursor C_LOCK_INVC_TOLERANCE is
      select 'X'
        from invc_tolerance
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_INVC_TOLERANCE_ITEM is
      select 'X'
        from invc_tolerance
       where invc_id = I_invc_id
         and item    = I_item
         for update nowait;

   cursor C_LOCK_ORDLOC is
      select 'X'
        from ordloc_invc_cost
       where match_invc_id = I_invc_id
         and item          = I_item
         for update nowait;

   cursor C_LOCK_ORDLOC_INVC is
      select 'X'
        from ordloc_invc_cost oic
       where match_invc_id = I_invc_id
         for update nowait;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_SQL.DELETE_INVC',
                                            NULL);
      return FALSE;
   end if;

   if I_item is NULL then
      --  Delete all of the reference invoices
      for rec in C_CHECK_REF_INVC LOOP
         ---
         L_table :=  'INVC_DETAIL';
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
         ---
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'INVC_DETAIL',
                          'INVC_ID:'||TO_CHAR(I_invc_id));
         delete
           from invc_detail
          where invc_id = rec.invc_id;
         ---
         L_table :=  'INVC_NON_MERCH';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_NON_MERCH',
                          'INVC_NON_MERCH',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         open C_LOCK_NON_MERCH;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_NON_MERCH',
                          'INVC_NON_MERCH',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         close C_LOCK_NON_MERCH;

         SQL_LIB.SET_MARK('DELETE',
                           NULL,
                          'INVC_NON_MERCH',
                          'INVC_ID:'||TO_CHAR(I_invc_id));

         delete
           from invc_non_merch
          where invc_id = rec.invc_id;
         ---
         L_table:= 'INVC_MERCH_VAT';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_MERCH_VAT',
                          'INVC_MERCH_VAT',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         open C_LOCK_MERCH_VAT;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_MERCH_VAT',
                          'INVC_MERCH_VAT',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         close C_LOCK_MERCH_VAT;

         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'INVC_MERCH_VAT',
                          'INVC_ID:'||TO_CHAR(I_invc_id));

         delete
           from invc_merch_vat
          where invc_id = rec.invc_id;
         ---
         L_table:= 'INVC_DETAIL_VAT';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_INVC_DETAIL_VAT',
                          'INVC_DETAIL_VAT',
                          'INVC_ID:'||TO_CHAR(I_invc_id));
         open C_LOCK_INVC_DETAIL_VAT;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_INVC_DETAIL_VAT',
                          'INVC_DETAIL_VAT',
                          'INVC_ID:'||TO_CHAR(I_invc_id));
         close C_LOCK_INVC_DETAIL_VAT;

         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'INVC_DETAIL_VAT',
                          'INVC_ID:'||TO_CHAR(I_invc_id));

         delete
           from invc_detail_vat
          where invc_id = rec.invc_id;
         ---
         L_table :=  'INVC_DISCOUNT';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_DISC',
                          'INVC_DISCOUNT',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         open C_LOCK_DISC;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_DISC',
                          'INVC_DISCOUNT',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         close C_LOCK_DISC;
         ---
         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'INVC_DISCOUNT',
                          'INVC_ID:'||TO_CHAR(I_invc_id));

         delete from invc_discount
            where invc_id = I_invc_id;
         ---
         L_table:= 'INVC_TOLERANCE';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_INVC_TOLERANCE',
                          'INVC_TOLERANCE',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         open C_LOCK_INVC_TOLERANCE;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_INVC_TOLERANCE',
                          'INVC_TOLERANCE',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         close C_LOCK_INVC_TOLERANCE;

         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'INVC_TOLERANCE',
                          'INVC_ID:'||TO_CHAR(I_invc_id));

         delete
           from invc_tolerance
          where invc_id = rec.invc_id;

         ---
         L_table :=  'INVC_HEAD';
         SQL_LIB.SET_MARK('OPEN',
                          'C_LOCK_HEAD',
                          'INVC_HEAD',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         open C_LOCK_HEAD;

         SQL_LIB.SET_MARK('CLOSE',
                          'C_LOCK_HEAD',
                          'INVC_HEAD',
                          'INVOICE:'||TO_CHAR(I_invc_id));
         close C_LOCK_HEAD;
         ---

         SQL_LIB.SET_MARK('DELETE',
                          NULL,
                          'INVC_HEAD',
                          'INVC_ID:'||TO_CHAR(I_invc_id));

        delete from invc_head
          where invc_id = rec.invc_id;

      END LOOP;
      ---
      L_table :=  'ORDLOC_INVC_COST';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ORDLOC_INVC',
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_ORDLOC_INVC;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ORDLOC_INVC',
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_ORDLOC_INVC;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                        NULL,
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      update ordloc_invc_cost
         set match_invc_id = NULL
       where match_invc_id = I_invc_id;
      ---
     --  Now delete the referenced invoice
      if INVC_SQL.DELETE_INVC_WKSHT(O_error_message,
                                    I_invc_id,
                                    NULL,
                                    NULL) = FALSE then
         return FALSE;
      end if;
      ---
      L_table :=  'INVC_DETAIL';
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

      SQL_LIB.SET_MARK('DELETE',
                        NULL,
                       'INVC_DETAIL',
                       'INVC_ID:'||TO_CHAR(I_invc_id));
      delete
        from invc_detail
       where invc_id = I_invc_id;
      ---
      L_table :=  'INVC_NON_MERCH';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_NON_MERCH',
                       'INVC_NON_MERCH',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_NON_MERCH;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_NON_MERCH',
                       'INVC_NON_MERCH',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_NON_MERCH;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_NON_MERCH',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete
        from invc_non_merch
       where invc_id = I_invc_id;
      ---
      L_table:= 'INVC_MERCH_VAT';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_MERCH_VAT',
                       'INVC_MERCH_VAT',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_MERCH_VAT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_MERCH_VAT',
                       'INVC_MERCH_VAT',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_MERCH_VAT;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_MERCH_VAT',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete
        from invc_merch_vat
       where invc_id = I_invc_id;
      ---
      L_table:= 'INVC_DETAIL_VAT';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVC_DETAIL_VAT',
                       'INVC_DETAIL_VAT',
                       'INVC_ID:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVC_DETAIL_VAT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVC_DETAIL_VAT',
                       'INVC_DETAIL_VAT',
                       'INVC_ID:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVC_DETAIL_VAT;

      SQL_LIB.SET_MARK('DELETE',
                        NULL,
                       'INVC_DETAIL_VAT',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete
        from invc_detail_vat
       where invc_id = I_invc_id;
      ---
      L_table:= 'INVC_TOLERANCE';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVC_TOLERANCE',
                       'INVC_TOLERANCE',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVC_TOLERANCE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVC_TOLERANCE',
                       'INVC_TOLERANCE',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVC_TOLERANCE;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_TOLERANCE',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete
        from invc_tolerance
       where invc_id = I_invc_id;

      ---
      L_table := 'INVC_MATCH_QUEUE';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_MATCH_QUEUE',
                       'INVC_MATCH_QUEUE',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_MATCH_QUEUE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_MATCH_QUEUE',
                       'INVC_MATCH_QUEUE',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_MATCH_QUEUE;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_MATCH_QUEUE',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete
        from invc_match_queue
       where invc_id = I_invc_id;
      ---
      L_table :=  'INVC_DISCOUNT';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DISC',
                       'INVC_DISCOUNT',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_DISC;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DISC',
                       'INVC_DISCOUNT',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_DISC;
      ---
      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_DISCOUNT',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete from invc_discount
         where invc_id = I_invc_id;
      ---
      L_table :=  'INVC_HEAD';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_HEAD',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_HEAD;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_HEAD',
                       'INVC_HEAD',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_HEAD;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_HEAD',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete
        from invc_head
       where invc_id = I_invc_id;

   else --I_item is not null

      L_table :=  'ORDLOC_INVC_COST';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_ORDLOC',
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      open C_LOCK_ORDLOC;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_ORDLOC',
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      close C_LOCK_ORDLOC;
      ---
      SQL_LIB.SET_MARK('UPDATE',
                       NULL,
                       'ORDLOC_INVC_COST',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);

      update ordloc_invc_cost
         set match_invc_id = NULL
       where item          = I_item
         and match_invc_id = I_invc_id;
      ---
      if INVC_SQL.DELETE_INVC_WKSHT(O_error_message,
                                    I_invc_id,
                                    NULL,
                                    I_item) = FALSE then
         return FALSE;
      end if;
      ---
      L_table:= 'INVC_TOLERANCE';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVC_TOLERANCE_ITEM',
                       'INVC_TOLERANCE',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVC_TOLERANCE_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVC_TOLERANCE_ITEM',
                       'INVC_TOLERANCE',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVC_TOLERANCE_ITEM;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_TOLERANCE',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete
        from invc_tolerance
       where invc_id = I_invc_id
         and item = I_item;

      ---
      L_table :=  'INVC_DETAIL';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_DETAIL_LOC',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      open C_LOCK_DETAIL_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_DETAIL_LOC',
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      close C_LOCK_DETAIL_ITEM;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_DETAIL',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);

      delete
        from invc_detail
       where invc_id = I_invc_id
         and item = I_item;
      ---
      L_table:= 'INVC_DETAIL_VAT';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_INVC_DETAIL_VAT',
                       'INVC_DETAIL_VAT',
                       'INVC_ID:'||TO_CHAR(I_invc_id));
      open C_LOCK_INVC_DETAIL_VAT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_INVC_DETAIL_VAT',
                       'INVC_DETAIL_VAT',
                       'INVC_ID:'||TO_CHAR(I_invc_id));
      close C_LOCK_INVC_DETAIL_VAT;

      SQL_LIB.SET_MARK('DELETE',
                        NULL,
                       'INVC_DETAIL_VAT',
                       'INVC_ID:'||TO_CHAR(I_invc_id));

      delete
        from invc_detail_vat
       where invc_id = I_invc_id
         and item    = I_item;
      ---
   end if;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_invc_id),
                                             I_item);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.DELETE_INVC',
                                            TO_CHAR(SQLCODE));
   return FALSE;

END DELETE_INVC;
------------------------------------------------------------------------------------------------------
FUNCTION WRITE_INVC_TOL_TRAN_DATA(O_error_message     IN OUT   VARCHAR2,
                                  I_invc_id           IN       INVC_HEAD.INVC_ID%TYPE,
                                  I_vdate             IN       DATE,
                                  I_default_dept      IN       DEPS.DEPT%TYPE,
                                  I_default_class     IN       CLASS.CLASS%TYPE,
                                  I_default_subclass  IN       SUBCLASS.SUBCLASS%TYPE,
                                  I_default_store     IN       STORE.STORE%TYPE,
                                  I_default_wh        IN       WH.WH%TYPE)
                            RETURN BOOLEAN is

   L_dept              DEPS.DEPT%TYPE;
   L_class             CLASS.CLASS%TYPE;
   L_subclass          SUBCLASS.SUBCLASS%TYPE;
   L_tran_code         TRAN_DATA.TRAN_CODE%TYPE := '71';
   L_total_cost        INVC_TOLERANCE.TOTAL_COST%TYPE;
   L_item              INVC_TOLERANCE.ITEM%TYPE;
   L_default_location  TRAN_DATA.LOCATION%TYPE;
   L_default_loc_type  TRAN_DATA.LOC_TYPE%TYPE;

   cursor C_INVC_TOLERANCE is
      select item,
             total_cost
        from invc_tolerance
       where invc_id = I_invc_id
       order by seq_no;

BEGIN
   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_vdate is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_vdate',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_default_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_default_dept',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_default_class is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_default_class',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_default_subclass is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_default_subclass',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_default_store is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_default_store',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_default_wh is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_default_wh',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---

   if I_default_wh = -1 then
      L_default_location := I_default_store;
      L_default_loc_type := 'S';
   else
      L_default_location := I_default_wh;
      L_default_loc_type := 'W';
   end if;

   for recs in C_INVC_TOLERANCE LOOP
      L_item       := recs.item;
      L_total_cost := recs.total_cost;
      ---
      if L_item is NOT NULL then
         if ITEM_ATTRIB_SQL.GET_MERCH_HIER(O_error_message,
                                           L_item,
                                           L_dept,
                                           L_class,
                                           L_subclass) = FALSE then
            return FALSE;
         end if;
      else
         L_dept     := I_default_dept;
         L_class    := I_default_class;
         L_subclass := I_default_subclass;
      end if;
      ---
      if STKLEDGR_SQL.TRAN_DATA_INSERT(O_error_message,
                                       L_item,
                                       L_dept,
                                       L_class,
                                       L_subclass,
                                       L_default_location,
                                       L_default_loc_type,
                                       I_vdate,
                                       L_tran_code,
                                       'C',
                                       0,
                                       L_total_cost,
                                       NULL,
                                       I_invc_id,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       'INVC_SQL.WRITE_INVC_TOL_TRAN_DATA') = FALSE then
         return FALSE;
      end if;
   end LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_SQL.WRITE_INVC_TOL_TRAN_DATA',
                                             TO_CHAR(SQLCODE));
      return FALSE;
END WRITE_INVC_TOL_TRAN_DATA;
------------------------------------------------------------------------------------------------------------
FUNCTION DELETE_INVC_WKSHT(O_error_message   IN OUT   VARCHAR2,
                           I_invc_id         IN       INVC_MATCH_WKSHT.INVC_ID%TYPE,
                           I_rcpt            IN       INVC_MATCH_WKSHT.SHIPMENT%TYPE,
                           I_item            IN       INVC_MATCH_WKSHT.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_table          VARCHAR2(30);
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_WKSHT is
      select 'X'
        from invc_match_wksht
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_WKSHT_RCPT is
      select 'X'
        from invc_match_wksht
       where invc_id  = I_invc_id
         and shipment = I_rcpt
         for update nowait;

   cursor C_LOCK_WKSHT_ITEM is
      select 'X'
        from invc_match_wksht
       where invc_id = I_invc_id
         and item    = I_item
         for update nowait;

   cursor C_LOCK_WKSHT_RCPT_ITEM is
      select 'X'
        from invc_match_wksht
       where invc_id  = I_invc_id
         and shipment = I_rcpt
         and item     = I_item
         for update nowait;

   cursor C_LOCK_XREF is
      select 'X'
        from invc_xref
       where invc_id = I_invc_id
         for update nowait;

   cursor C_LOCK_XREF_RCPT is
      select 'X'
        from invc_xref
       where invc_id  = I_invc_id
         and shipment = I_rcpt
         for update nowait;

   cursor C_LOCK_XREF_EXISTS is
      select 'X'
        from invc_xref inx
       where inx.invc_id         = I_invc_id
      and apply_to_future_ind    = 'N'
         and not exists (select 'X'
               from invc_match_wksht imw
              where imw.invc_id  = I_invc_id
                and imw.shipment = inx.shipment)
         for update nowait;

BEGIN

   L_table := 'INVC_MATCH_WKSHT';

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_SQL.DELETE_INVC_WKSHT',
                                            NULL);
      return FALSE;
   end if;

   if (I_rcpt is NULL and I_item is NULL) then

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_WKSHT',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_WKSHT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_WKSHT',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_WKSHT;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      delete
        from invc_match_wksht
       where invc_id = I_invc_id;

      L_table := 'INVC_XREF';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_XREF',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      open C_LOCK_XREF;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_XREF',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id));
      close C_LOCK_XREF;


      SQL_LIB.SET_MARK('DELETE',
                        NULL,
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id));

      delete
        from invc_xref
       where invc_id = I_invc_id;

   elsif (I_rcpt is NOT NULL and I_item is NULL) then

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_WKSHT_RCPT',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));
      open C_LOCK_WKSHT_RCPT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_WKSHT_RCPT',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));
      close C_LOCK_WKSHT_RCPT;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));

      delete
        from invc_match_wksht
       where invc_id  = I_invc_id
         and shipment = I_rcpt;

      L_table := 'INVC_XREF';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_XREF_RCPT',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));
      open C_LOCK_XREF_RCPT;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_XREF_RCPT',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));
      close C_LOCK_XREF_RCPT;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));

      delete
        from invc_xref
       where invc_id  = I_invc_id
         and shipment = I_rcpt;

   elsif (I_rcpt is NULL and I_item is NOT NULL) then

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_WKSHT_ITEM',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      open C_LOCK_WKSHT_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_WKSHT_ITEM',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      close C_LOCK_WKSHT_ITEM;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);

      delete
        from invc_match_wksht
       where invc_id = I_invc_id
         and item    = I_item;

      L_table := 'INVC_XREF';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_XREF_EXISTS',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      open C_LOCK_XREF_EXISTS;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_XREF_EXISTS',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);
      close C_LOCK_XREF_EXISTS;


      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',ITEM:'||I_item);

      delete
        from invc_xref inx
       where inx.invc_id         = I_invc_id
         and apply_to_future_ind = 'N'
         and not exists (select 'X'
                          from invc_match_wksht imw
                         where imw.invc_id  = I_invc_id
                           and imw.shipment = inx.shipment);

   else -- I_rcpt and I_item are NOT NULL

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_WKSHT_RCPT_ITEM',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',ITEM:'||I_item);
      open C_LOCK_WKSHT_RCPT_ITEM;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_WKSHT_RCPT_ITEM',
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',ITEM:'||I_item);

      close C_LOCK_WKSHT_RCPT_ITEM;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_MATCH_WKSHT',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',ITEM:'||I_item);

      delete
        from invc_match_wksht
       where invc_id  = I_invc_id
         and shipment = I_rcpt
         and item     = I_item;

      L_table := 'INVC_XREF';
      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_XREF_EXISTS',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));
      open C_LOCK_XREF_EXISTS;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_XREF_EXISTS',
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));
      close C_LOCK_XREF_EXISTS;

      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'INVC_XREF',
                       'INVOICE:'||TO_CHAR(I_invc_id)||
                       ',RECEIPT:'||TO_CHAR(I_rcpt));

      delete
        from invc_xref inx
       where inx.invc_id         = I_invc_id
         and apply_to_future_ind = 'N'
         and not exists (select 'X'
               from invc_match_wksht imw
              where imw.invc_id  = I_invc_id
                and imw.shipment = inx.shipment);

   end if;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_invc_id),
                                             TO_CHAR(I_rcpt)||
                                             ','||
                                             I_item);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.DELETE_INVC_WKSHT',
                                            TO_CHAR(SQLCODE));
      return FALSE;


END DELETE_INVC_WKSHT;
---------------------------------------------------------------------
FUNCTION INSERT_INVC_XREF(O_error_message   IN OUT   VARCHAR2,
                          I_invc_id         IN       INVC_XREF.INVC_ID%TYPE,
                          I_rcpt            IN       INVC_XREF.SHIPMENT%TYPE)
   RETURN BOOLEAN IS

   L_table          VARCHAR2(30);
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

BEGIN


   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_SQL.INSERT_INVC_XREF',
                                             NULL);

      return FALSE;
   elsif I_rcpt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_rcpt',
                                            'INVC_SQL.INSERT_INVC_XREF',
                                            NULL);

      return FALSE;
   end if;

   SQL_LIB.SET_MARK('INSERT',
                     NULL,
                    'INVC_XREF',
                    'INVC_ID:'||TO_CHAR(I_invc_id)||
                    ',RECEIPT:'||TO_CHAR(I_rcpt));

   insert into invc_xref(invc_id,
                         order_no,
                         shipment,
                         asn,
                         location,
                         loc_type,
                         apply_to_future_ind)
   select I_invc_id,
          order_no,
          I_rcpt,
          asn,
          to_loc,
          to_loc_type,
          'N'
     from shipment
    where shipment = I_rcpt;

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
                                            'INVC_SQL.INSERT_INVC_XREF',
                                            TO_CHAR(SQLCODE));
      return FALSE;

END INSERT_INVC_XREF;
---------------------------------------------------------------------
FUNCTION CHECK_MATCH(O_error_message   IN OUT   VARCHAR2,
                     O_matched         IN OUT   BOOLEAN,
                     I_invc_id         IN       INVC_MATCH_WKSHT.INVC_ID%TYPE,
                     I_rcpt            IN       INVC_MATCH_WKSHT.SHIPMENT%TYPE,
                     I_item            IN       INVC_MATCH_WKSHT.ITEM%TYPE)
   RETURN BOOLEAN IS


   L_check   VARCHAR2(1) := NULL;

   cursor C_MATCHED is
      select 'Y'
        from shipsku
       where shipment      = I_rcpt
         and match_invc_id = I_invc_id;

   cursor C_MATCHED_ITEM is
      select 'Y'
        from shipsku
    where shipment         = I_rcpt
         and item          = I_item
         and match_invc_id = I_invc_id;


BEGIN

   if I_invc_id is NULL then

      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_invc_id',
                                            'INVC_SQL.CHECK_MATCH',
                                            NULL);
      return FALSE;

   elsif I_rcpt is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_rcpt',
                                            'INVC_SQL.CHECK_MATCH',
                                             NULL);
      return FALSE;
   end if;

   if I_item is NOT NULL then

      SQL_LIB.SET_MARK('OPEN',
                       'C_MATCHED_ITEM',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',ITEM:'||I_item||
                       ',MATCH_INVC:'||TO_CHAR(I_invc_id));
      open C_MATCHED_ITEM;

      SQL_LIB.SET_MARK('FETCH',
                       'C_MATCHED_ITEM',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',ITEM:'||I_item||
                       ',MATCH_INVC:'||TO_CHAR(I_invc_id));
      fetch C_MATCHED_ITEM into L_check;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_MATCHED_ITEM',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',ITEM:'||I_item||
                       ',MATCH_INVC:'||TO_CHAR(I_invc_id));
      close C_MATCHED_ITEM;

   else -- I_item is null

      SQL_LIB.SET_MARK('OPEN',
                       'C_MATCHED',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',MATCH_INVC:'||TO_CHAR(I_invc_id));
      open C_MATCHED;

      SQL_LIB.SET_MARK('FETCH',
                       'C_MATCHED',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',MATCH_INVC:'||TO_CHAR(I_invc_id));
      fetch C_MATCHED into L_check;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_MATCHED',
                       'SHIPSKU',
                       'RECEIPT:'||TO_CHAR(I_rcpt)||
                       ',MATCH_INVC:'||TO_CHAR(I_invc_id));
      close C_MATCHED;

   end if;

   if L_check = 'Y' then
      O_matched := TRUE;
   else
      O_matched := FALSE;
   end if;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.CHECK_MATCH',
                                            TO_CHAR(SQLCODE));
      return FALSE;

END CHECK_MATCH;
---------------------------------------------------------------------
FUNCTION INVC_SYSTEM_OPTIONS_INDS
   (O_error_message             IN OUT   VARCHAR2,
    O_invc_match_mult_sup_ind   IN OUT   SYSTEM_OPTIONS.INVC_MATCH_MULT_SUP_IND%TYPE,
    O_invc_match_qty_ind        IN OUT   SYSTEM_OPTIONS.INVC_MATCH_QTY_IND%TYPE)
   RETURN BOOLEAN IS

   cursor C_SYSTEM_INDS is
      select invc_match_mult_sup_ind, invc_match_qty_ind
        from system_options;

BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_SYSTEM_INDS',
                    'SYSTEM_OPTIONS',
                     NULL);
   open C_SYSTEM_INDS;

   SQL_LIB.SET_MARK('FETCH',
                    'C_SYSTEM_INDS',
                    'SYSTEM_OPTIONS',
                    NULL);
   fetch C_SYSTEM_INDS into O_invc_match_mult_sup_ind, O_invc_match_qty_ind;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_SYSTEM_INDS',
                    'SYSTEM_OPTIONS',
                    NULL);
   close C_SYSTEM_INDS;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.INVC_SYSTEM_OPTIONS_INDS',
                                            TO_CHAR(SQLCODE));
   return FALSE;

END INVC_SYSTEM_OPTIONS_INDS;
---------------------------------------------------------------------
FUNCTION DEFAULT_TOLERANCES(O_error_message   IN OUT   VARCHAR2,
                            I_supplier        IN       SUP_TOLERANCE.SUPPLIER%TYPE)
   RETURN BOOLEAN IS

   L_table          VARCHAR2(30);
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);


   cursor C_LOCK_SUP_TOLERANCE is
      select 'X'
        from sup_tolerance
       where supplier = I_supplier
         for update nowait;

BEGIN

   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_supplier',
                                            'INVC_SQL.DEFAULT_TOLERANCES',
                                            NULL);
      return FALSE;
   end if;

   L_table := 'SUP_TOLERANCE';

   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_SUP_TOLERANCE',
                    'SUP_TOLERANCE',
                    'SUPPLIER:'||TO_CHAR(I_supplier));
   open C_LOCK_SUP_TOLERANCE;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_SUP_TOLERANCE',
                    'SUP_TOLERANCE',
                    'SUPPLIER:'||TO_CHAR(I_supplier));
   close C_LOCK_SUP_TOLERANCE;

   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'SUP_TOLERANCE',
                    'SUPPLIER:'||TO_CHAR(I_supplier));

   delete
     from sup_tolerance
    where supplier = I_supplier;

   SQL_LIB.SET_MARK('INSERT',
                    NULL,
                    'SUP_TOLERANCE',
                    'SUPPLIER:'||TO_CHAR(I_supplier));

   insert into sup_tolerance(supplier,
                             tolerance_favor,
                             tolerance_level,
                             lower_limit,
                             upper_limit,
                             tolerance_type,
                             tolerance_value)
                      select I_supplier,
                             tolerance_favor,
                             tolerance_level,
                             lower_limit,
                             upper_limit,
                             tolerance_type,
                             tolerance_value
                        from invc_default_tolerance;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_supplier),
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.DEFAULT_TOLERANCES',
                                            TO_CHAR(SQLCODE));
      return FALSE;

END DEFAULT_TOLERANCES;
---------------------------------------------------------------------
FUNCTION DEFAULT_LINE_TOLERANCE
   (O_error_message     IN OUT   VARCHAR2,
    I_tolerance_favor   IN       INVC_DEFAULT_TOLERANCE.TOLERANCE_FAVOR%TYPE,
    I_tolerance_level   IN       INVC_DEFAULT_TOLERANCE.TOLERANCE_LEVEL%TYPE,
    I_lower_limit       IN       INVC_DEFAULT_TOLERANCE.LOWER_LIMIT%TYPE,
    I_upper_limit       IN       INVC_DEFAULT_TOLERANCE.UPPER_LIMIT%TYPE,
    I_tolerance_type    IN       INVC_DEFAULT_TOLERANCE.TOLERANCE_TYPE%TYPE,
    I_tolerance_value   IN       INVC_DEFAULT_TOLERANCE.TOLERANCE_VALUE%TYPE,
    I_action_type       IN       VARCHAR2)
    RETURN BOOLEAN IS

  L_lower_overlap   BOOLEAN;
   L_upper_overlap   BOOLEAN;
   L_table           VARCHAR2(30);
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_SUP_TOLERANCE is
      select 'X'
        from sup_tolerance
       where tolerance_favor = I_tolerance_favor
         and tolerance_level = I_tolerance_level
         and lower_limit     = I_lower_limit
         and upper_limit     = I_upper_limit
         and tolerance_type  = I_tolerance_type
         for update nowait;

BEGIN

   if I_tolerance_favor is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tolerance_favor',
                                            'INVC_SQL.DEFAULT_LINE_TOLERANCE',
                                            NULL);
      return FALSE;
   elsif I_tolerance_level is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tolerance_level',
                                            'INVC_SQL.DEFAULT_LINE_TOLERANCE',
                                            NULL);
      return FALSE;
   elsif I_lower_limit is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_lower_limit',
                                            'INVC_SQL.DEFAULT_LINE_TOLERANCE',
                                            NULL);
      return FALSE;
   elsif I_upper_limit is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_upper_limit',
                                            'INVC_SQL.DEFAULT_LINE_TOLERANCE',
                                            NULL);
      return FALSE;
   elsif I_tolerance_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tolerance_type',
                                            'INVC_SQL.DEFAULT_LINE_TOLERANCE',
                                            NULL);
      return FALSE;
   elsif I_action_type is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_action_type',
                                            'INVC_SQL.DEFAULT_LINE_TOLERANCE',
                                            NULL);
      return FALSE;
   elsif I_action_type != 'D' and I_tolerance_value is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tolerance_value',
                                            'INVC_SQL.DEFAULT_LINE_TOLERANCE',
                                            NULL);
      return FALSE;
   end if;

   L_table := 'SUP_TOLERANCE';

   if I_action_type = 'D' then

      SQL_LIB.SET_MARK('OPEN',
                       'C_LOCK_SUP_TOLERANCE',
                       'SUP_TOLERANCE',
                       'TOL_FAVOR:'||I_tolerance_favor||
                       ',TOL_LEVEL:'||I_tolerance_level||
                       ',TOL_TYPE:'||I_tolerance_type);
      open C_LOCK_SUP_TOLERANCE;

      SQL_LIB.SET_MARK('CLOSE',
                       'C_LOCK_SUP_TOLERANCE',
                       'SUP_TOLERANCE',
                       'TOL_FAVOR:'||I_tolerance_favor||
                       ',TOL_LEVEL:'||I_tolerance_level||
                       ',TOL_TYPE:'||I_tolerance_type);
      close C_LOCK_SUP_TOLERANCE;


      SQL_LIB.SET_MARK('DELETE',
                       NULL,
                       'SUP_TOLERANCE',
                       'TOL_FAVOR:'||I_tolerance_favor||
                       ',TOL_LEVEL:'||I_tolerance_level||
                       ',TOL_TYPE:'||I_tolerance_type);

      delete
        from sup_tolerance
       where tolerance_favor = I_tolerance_favor
         and tolerance_level = I_tolerance_level
         and lower_limit     = I_lower_limit
         and upper_limit     = I_upper_limit
         and tolerance_type  = I_tolerance_type;

   else
      -- Will insert records into sup_tolerance for all suppliers, except where a
      -- where a tolerance overlaps with an existing one.
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'SUP_TOLERANCE',
                       'TOL_FAVOR:'||I_tolerance_favor||
                       ',TOL_LEVEL:'||I_tolerance_level||
                       ',UPPER_LIM:'||I_upper_limit||
                       ',LOWER_LIM:'||I_lower_limit);

      insert into sup_tolerance (supplier,
                                 tolerance_favor,
                                 tolerance_level,
                                 lower_limit,
                                 upper_limit,
                                 tolerance_type,
                                 tolerance_value)
      select s.supplier,
             I_tolerance_favor,
             I_tolerance_level,
             I_lower_limit,
             I_upper_limit,
             I_tolerance_type,
             I_tolerance_value
        from sups s
       where NOT EXISTS(select 'x'
                          from sup_tolerance st
                         where st.supplier        = s.supplier
                           and st.tolerance_level = I_tolerance_level
                           and st.tolerance_favor = I_tolerance_favor
                           and st.tolerance_type  = I_tolerance_type
                           and (I_lower_limit between st.lower_limit and st.upper_limit
                               or I_upper_limit between st.lower_limit and st.upper_limit));

   end if;

   return TRUE;

EXCEPTION

   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_tolerance_favor||
                                            ','||I_tolerance_level,
                                            TO_CHAR(I_lower_limit)||
                                            ','||TO_CHAR(I_upper_limit));
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'INVC_SQL.DEFAULT_LINE_TOLERANCE',
                                            TO_CHAR(SQLCODE));
      return FALSE;

END DEFAULT_LINE_TOLERANCE;
---------------------------------------------------------------------
FUNCTION CLOSE_OPEN_SHIP(O_error_message   IN OUT   VARCHAR2,
                         O_close_ind       IN OUT   BOOLEAN,
                         I_shipment        IN       SHIPMENT.SHIPMENT%TYPE)
   RETURN BOOLEAN IS

   L_ship_close_ind     BOOLEAN := FALSE;
   L_xref_close_ind     BOOLEAN := FALSE;
   L_ship_exists        VARCHAR2(1);
   L_xref_exists        VARCHAR2(1);
   L_table              VARCHAR2(30);
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);

   cursor C_CHECK_SHIP is
      select 'x'
        from shipsku sk, invc_head ih
       where sk.match_invc_id = ih.invc_id
         and sk.shipment      = I_shipment
         and ih.status       != 'P';

   cursor C_CHECK_XREF is
      select 'x'
        from invc_xref ix, invc_head ih
       where ix.invc_id   = ih.invc_id
         and ix.shipment  = I_shipment
         and ih.status   != 'P';

   cursor C_LOCK_SHIPMENT is
      select 'x'
        from shipment
       where shipment = I_shipment
         for update nowait;
BEGIN

   if I_shipment is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_shipment',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;


   -- Check if there are matched invoices to the shipment not in posted status
   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SHIP', 'shipsku, invc_head', 'shipment: '||TO_CHAR(I_shipment));
   open C_CHECK_SHIP;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SHIP', 'shipsku, invc_head', 'shipment: '||TO_CHAR(I_shipment));
   fetch C_CHECK_SHIP into L_ship_exists;
   ---
   if C_CHECK_SHIP%NOTFOUND then
      L_ship_close_ind := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SHIP', 'shipsku, invc_head', 'shipment: '||TO_CHAR(I_shipment));
   close C_CHECK_SHIP;


   -- Check if there are any shipments associated with non-posted invoices on the INVC_XREF table
   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_XREF', 'invc_xref, invc_head', 'shipment: '||TO_CHAR(I_shipment));
   open C_CHECK_XREF;
   ---
   SQL_LIB.SET_MARK('FETCH', 'C_CHECK_XREF', 'invc_xref, invc_head', 'shipment: '||TO_CHAR(I_shipment));
   fetch C_CHECK_XREF into L_xref_exists;
   ---
   if C_CHECK_XREF%NOTFOUND then
      L_xref_close_ind := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_XREF', 'invc_xref, invc_head', 'shipment: '||TO_CHAR(I_shipment));
   close C_CHECK_XREF;

   if L_ship_close_ind = TRUE and L_xref_close_ind = TRUE then
      O_close_ind := TRUE;
   else
      O_close_ind := FALSE;
   end if;

   if O_close_ind = TRUE then
      ---
      L_table := 'SHIPMENT';
      SQL_LIB.SET_MARK('OPEN', 'C_LOCK_SHIPMENT', 'shipment', 'shipment: '||TO_CHAR(I_shipment));
      open C_LOCK_SHIPMENT;
      ---
      SQL_LIB.SET_MARK('CLOSE', 'C_LOCK_SHIPMENT', 'shipment', 'shipment: '||TO_CHAR(I_shipment));
      close C_LOCK_SHIPMENT;
      ---
      SQL_LIB.SET_MARK('UPDATE', NULL, 'shipment', 'shipment: '||TO_CHAR(I_shipment));
      update shipment
         set invc_match_status = 'C'
       where shipment = I_shipment;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             TO_CHAR(I_shipment),
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_SQL.CLOSE_OPEN_SHIP',
                                             TO_CHAR(SQLCODE));
      return FALSE;

END CLOSE_OPEN_SHIP;
---------------------------------------------------------------------
FUNCTION CHECK_PO_TERMS(O_error_message   IN OUT   VARCHAR2,
                        O_matching_terms  IN OUT   BOOLEAN,
                        O_po_terms        IN OUT   ORDHEAD.TERMS%TYPE,
                        I_invc_id         IN       INVC_HEAD.INVC_ID%TYPE)
   RETURN BOOLEAN is

   L_po_terms           ordhead.terms%TYPE;
   L_loop_ind           NUMBER(1)  := 1;

   cursor C_CHECK_PO_TERMS is
      select distinct o.terms
        from ordhead o,
             invc_xref x
       where x.invc_id  = I_invc_id
         and x.order_no = o.order_no;

BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   O_matching_terms := TRUE;

   FOR recs in C_CHECK_PO_TERMS LOOP
      if L_loop_ind = 1 then
         O_po_terms := recs.terms;
      else
         L_po_terms := recs.terms;
         ---
         if O_po_terms != L_po_terms then
            O_matching_terms := FALSE;
            EXIT;
         end if;
         ---
      end if;
      ---
      L_loop_ind := L_loop_ind + 1;
   END LOOP;
   ---
   if O_po_terms is NULL then
      O_matching_terms := FALSE;
   end if;
   ---

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_SQL.CHECK_PO_TERMS',
                                             TO_CHAR(SQLCODE));
      return FALSE;

END CHECK_PO_TERMS;
---------------------------------------------------------------------------------------------------------
FUNCTION OVERWRITE_INVC_TERMS(O_error_message     IN OUT   VARCHAR2,
                              O_overwritten       IN OUT   BOOLEAN,
                              I_invc_id           IN       INVC_HEAD.INVC_ID%TYPE,
                              I_new_terms         IN       INVC_HEAD.TERMS%TYPE)
   RETURN BOOLEAN is

   L_new_terms        invc_head.terms%TYPE := I_new_terms;
   L_overwrite_ind    BOOLEAN              := TRUE;
   L_lock_ind         BOOLEAN;


BEGIN

   if I_invc_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_invc_id',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if L_new_terms is NULL then
      if INVC_SQL.CHECK_PO_TERMS(O_error_message,
                                 L_overwrite_ind,
                                 L_new_terms,
                                 I_invc_id) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if L_overwrite_ind = TRUE then
      if INVC_SQL.LOCK_INVC(O_error_message,
                            L_lock_ind,
                            I_invc_id) = FALSE then
         return FALSE;
      end if;
      ---
      if L_lock_ind = TRUE then
         SQL_LIB.SET_MARK('UPDATE',
                          NULL,
                          'invc_head',
                          'invc_id: '||TO_CHAR(I_invc_id));
         update invc_head
            set terms   = L_new_terms
          where invc_id = I_invc_id;

          O_overwritten := TRUE;
      else
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               'invc_head',
                                               to_char(I_invc_id));
         O_overwritten := FALSE;
      end if;
   else
       O_overwritten := FALSE;
   end if;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_SQL.OVERWRITE_INVC_TERMS',
                                             TO_CHAR(SQLCODE));
      return FALSE;

END OVERWRITE_INVC_TERMS;
----------------------------------------------------------------------------------------
FUNCTION UPDATE_INVOICE(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        I_order_no       IN     ORDHEAD.ORDER_NO%TYPE,
                        I_item           IN     ITEM_MASTER.ITEM%TYPE,
                        I_location       IN     STORE.STORE%TYPE,
                        I_shipment       IN     SHIPMENT.SHIPMENT%TYPE,
                        I_carton         IN     CARTON.CARTON%TYPE,
                        I_receipt_qty    IN     SHIPSKU.QTY_RECEIVED%TYPE)
   RETURN BOOLEAN IS

   L_buy_qty              DEAL_DETAIL.QTY_THRESH_BUY_QTY%TYPE;
   L_get_qty              DEAL_DETAIL.QTY_THRESH_GET_QTY%TYPE;
   L_buy_accum            DEAL_DETAIL.QTY_THRESH_BUY_QTY%TYPE;
   L_get_accum            DEAL_DETAIL.QTY_THRESH_GET_QTY%TYPE;
   L_buy_rec              ORDLOC_INVC_COST.QTY%TYPE;
   L_min_unit_cost        ORDLOC_INVC_COST.UNIT_COST%TYPE;
   L_max_unit_cost        ORDLOC_INVC_COST.UNIT_COST%TYPE;
   L_recur_ind            DEAL_DETAIL.QTY_THRESH_RECUR_IND%TYPE;
   L_remain_recpt         SHIPSKU.QTY_RECEIVED%TYPE;
   L_shipment             ORDLOC_INVC_COST.SHIPMENT%TYPE;
   L_max_seq_no           ORDLOC_INVC_COST.SEQ_NO%TYPE;
   L_program              VARCHAR2(50)  := 'INVC_SQL.UPDATE_INVOICE';
   ---

   cursor C_GET_MIN_MAX is
      select max(seq_no),
             max(NVL(shipment,0)),
             min(unit_cost),
             max(unit_cost)
        from ordloc_invc_cost
       where order_no = I_order_no
         and item     = I_item
         and location = I_location;

   cursor C_GET_BUY_QTY_REC is
      select NVL(SUM(qty),0)
        from ordloc_invc_cost
       where order_no        = I_order_no
         and item            = I_item
         and unit_cost       = L_max_unit_cost
         and NVL(shipment,0) > 0;

   cursor C_LOCK_ORDLOC_INVC_COST is
      select 'x'
        from ordloc_invc_cost
       where order_no = I_order_no
         and item     = I_item
         for update nowait;

   cursor C_GET_THRESHOLD_INFO is
      select NVL(dd.qty_thresh_buy_qty,0),
             NVL(dd.qty_thresh_recur_ind,'N'),
             NVL(dd.qty_thresh_get_qty,0)
        from deal_detail dd, ordloc_discount od
       where od.order_no             = I_order_no
         and od.item                 = I_item
         and od.deal_id              = dd.deal_id
         and od.deal_detail_id       = dd.deal_detail_id
         and dd.threshold_value_type = 'Q'
         and dd.qty_thresh_buy_item  = I_item
         and dd.qty_thresh_get_item  = I_item;

BEGIN

   if I_order_no is NULL then
      o_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_order_no',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_item is NULL then
      o_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_location is NULL then
      o_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_location',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_shipment is NULL then
      o_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_shipment',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   if I_receipt_qty is NULL then
      o_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_receipt_qty',
                                            L_program,
                                            NULL);
      return FALSE;
   end if;
   ---
   -- get max(seq-no), shipment nbr, min and max(unit-cost)
   SQL_LIB.SET_MARK('OPEN','C_GET_MIN_MAX','ORDLOC_INVC_COST',
                    'Order: '||TO_CHAR(I_order_no)||I_location||
                    ' ITEM: '||TO_CHAR(I_item));
   open C_GET_MIN_MAX;

   SQL_LIB.SET_MARK('FETCH','C_GET_MIN_MAX','ORDLOC_INVC_COST',
                    'Order: '||TO_CHAR(I_order_no)||I_location||
                    ' ITEM: '||TO_CHAR(I_item));
   fetch C_GET_MIN_MAX into L_max_seq_no,
                            L_shipment,
                            L_min_unit_cost,
                            L_max_unit_cost;

   SQL_LIB.SET_MARK('CLOSE','C_GET_MIN_MAX','ORDLOC_INVC_COST',
                    'Order: '||TO_CHAR(I_order_no)||I_location||
                    ' ITEM: '||TO_CHAR(I_item));
   close C_GET_MIN_MAX;
   ---
   if L_min_unit_cost = L_max_unit_cost then
      -- all the same unit-cost, no buy/get free
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDLOC_INVC_COST','ORDLOC_INVC_COST',
                       'Order: '||TO_CHAR(I_order_no)||I_location||
                       ' ITEM: '||TO_CHAR(I_item));
      open C_LOCK_ORDLOC_INVC_COST;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDLOC_INVC_COST','ORDLOC_INVC_COST',
                       'Order: '||TO_CHAR(I_order_no)||I_location||
                       ' ITEM: '||TO_CHAR(I_item));
      close C_LOCK_ORDLOC_INVC_COST;
      SQL_LIB.SET_MARK('UPDATE',NULL,'ORDLOC_INVC_COST',
                       'Order: '||TO_CHAR(I_order_no)||I_location||
                       ' ITEM: '||TO_CHAR(I_item));

      if L_shipment = 0 then
         update ordloc_invc_cost
            set qty      = I_receipt_qty,
                shipment = I_shipment,
                carton   = I_carton
          where order_no = I_order_no
            and item     = I_item
            and location = I_location;
      else
         SQL_LIB.SET_MARK('INSERT',null,'ORDLOC_INVC_COST',
                          'ITEM:'||TO_CHAR(I_item)||I_location||
                          ',ORDER NO:'||TO_CHAR(I_order_no));

         insert into ordloc_invc_cost(order_no,
                                      item,
                                      location,
                                      seq_no,
                                      unit_cost,
                                      qty,
                                      match_invc_id,
                                      shipment,
                                      carton)
                               SELECT I_order_no,
                                      I_item,
                                      I_location,
                                     (L_max_seq_no + 1),
                                      unit_cost,
                                      I_receipt_qty,
                                      NULL,
                                      I_shipment,
                                      I_carton
                                 from ordloc_invc_cost
                                where order_no = I_order_no
                                  and item     = I_item
                                  and location = I_location
                                  and seq_no   = L_max_seq_no;

      end if; -- end if L-shipment = 0
   end if; -- end if min_unit_cost = max_unit_cost

   if L_min_unit_cost <> L_max_unit_cost then
      -- multiple unit_cost's; this is part of a buy / get free
      -- apply prorated within thresholds
      SQL_LIB.SET_MARK('OPEN','C_GET_THRESHOLD_INFO','DEAL_DETAIL',
                       'Order: '||TO_CHAR(I_order_no)||I_location||
                       ' ITEM: '||TO_CHAR(I_item));
      open C_GET_THRESHOLD_INFO;

      SQL_LIB.SET_MARK('FETCH','C_GET_THRESHOLD_INFO','DEAL_DETAIL',
                       'Order: '||TO_CHAR(I_order_no)||I_location||
                       ' ITEM: '||TO_CHAR(I_item));
      fetch C_GET_THRESHOLD_INFO into L_buy_qty,
                                      L_recur_ind,
                                      L_get_qty;

      if C_GET_THRESHOLD_INFO%NOTFOUND then
         -- No threshold info - just update prorated based on total quantity.
         SQL_LIB.SET_MARK('CLOSE','C_GET_THRESHOLD_INFO','DEAL_DETAIL',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         close C_GET_THRESHOLD_INFO;

         SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDLOC_INVC_COST','ORDLOC_INVC_COST',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         open C_LOCK_ORDLOC_INVC_COST;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDLOC_INVC_COST','ORDLOC_INVC_COST',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         close C_LOCK_ORDLOC_INVC_COST;
         SQL_LIB.SET_MARK('UPDATE',NULL,'ORDLOC_INVC_COST',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));

         if L_shipment = 0 then
            update ordloc_invc_cost
               set qty      = I_receipt_qty,
                   shipment = I_shipment,
                   carton   = I_carton
             where order_no = I_order_no
               and item     = I_item
               and location = I_location;
         else
            SQL_LIB.SET_MARK('INSERT',null,'ORDLOC_INVC_COST',
                             'ITEM:'||TO_CHAR(I_item)||
                             ',ORDER NO:'||TO_CHAR(I_order_no));

            insert into ordloc_invc_cost(order_no,
                                         item,
                                         location,
                                         seq_no,
                                         unit_cost,
                                         qty,
                                         match_invc_id,
                                         shipment,
                                         carton)
                                  select I_order_no,
                                         I_item,
                                         I_location,
                                        (L_max_seq_no + 1),
                                         unit_cost,
                                         I_receipt_qty,
                                         NULL,
                                         I_shipment,
                                         I_carton
                                    from ordloc_invc_cost
                                   where order_no = I_order_no
                                     and item     = I_item
                                     and location = I_location
                                     and seq_no   = L_max_seq_no;
         end if; -- end if L-shipment = 0
      else -- Found threshold info

         SQL_LIB.SET_MARK('CLOSE','C_GET_THRESHOLD_INFO','DEAL_DETAIL',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         close C_GET_THRESHOLD_INFO;

         -- if we get here, we found valid deal info
         L_buy_accum := 0;
         L_get_accum := 0;
         L_buy_rec   := 0;

         SQL_LIB.SET_MARK('OPEN','C_GET_BUY_QTY_REC','ORDLOC_INVC_COST',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         open C_GET_BUY_QTY_REC;
         SQL_LIB.SET_MARK('FETCH','C_GET_BUY_QTY_REC','ORDLOC_INVC_COST',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         fetch C_GET_BUY_QTY_REC into L_buy_rec;
         SQL_LIB.SET_MARK('CLOSE','C_GET_BUY_QTY_REC','ORDLOC_INVC_COST',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         close C_GET_BUY_QTY_REC;

         -- add any "unused" buy qty to the current receipt
         L_remain_recpt := I_receipt_qty + MOD(L_buy_rec,L_buy_qty);
         LOOP
            if L_buy_qty < L_remain_recpt then
               L_buy_accum := L_buy_accum + L_buy_qty;
               L_remain_recpt := L_remain_recpt - L_buy_qty;
            else
               L_buy_accum := L_buy_accum + L_remain_recpt;
               L_remain_recpt := 0;
            end if;
            if L_get_qty < L_remain_recpt and L_remain_recpt > 0 then
               L_get_accum := L_get_accum + L_get_qty;
               L_remain_recpt := L_remain_recpt - L_get_qty;
            else
               L_get_accum := L_get_accum + L_remain_recpt;
               L_remain_recpt := 0;
            end if;
            if L_recur_ind = 'N' or L_remain_recpt = 0 then
               -- if no recursion but still some receipt qty
               L_buy_accum := L_buy_accum + L_remain_recpt;
               EXIT;
            end if;
         end LOOP;

         -- back out "unused" from prior receipts - only used to
         -- calculate get qty.
         L_buy_accum := L_buy_accum - MOD(L_buy_rec,L_buy_qty);

         SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDLOC_INVC_COST','ORDLOC_INVC_COST',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         open C_LOCK_ORDLOC_INVC_COST;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDLOC_INVC_COST','ORDLOC_INVC_COST',
                          'Order: '||TO_CHAR(I_order_no)||I_location||
                          ' ITEM: '||TO_CHAR(I_item));
         close C_LOCK_ORDLOC_INVC_COST;

         if L_shipment = 0 then -- First receipt
            SQL_LIB.SET_MARK('UPDATE',NULL,'ORDLOC_INVC_COST',
                             'Order: '||TO_CHAR(I_order_no)||I_location||
                             ' ITEM: '||TO_CHAR(I_item));
            update ordloc_invc_cost
               set qty       = L_buy_accum,
                   shipment  = I_shipment,
                    carton   = I_carton
             where order_no  = I_order_no
               and item      = I_item
               and location  = I_location
               and unit_cost = L_max_unit_cost;

            SQL_LIB.SET_MARK('UPDATE',NULL,'ORDLOC_INVC_COST',
                             'Order: '||TO_CHAR(I_order_no)||I_location||
                             ' ITEM: '||TO_CHAR(I_item));
            update ordloc_invc_cost
               set qty       = L_get_accum,
                   shipment  = I_shipment,
                    carton   = I_carton
             where order_no  = I_order_no
               and item      = I_item
               and location  = I_location
               and unit_cost = L_min_unit_cost;
         else -- Not the first receipt
            SQL_LIB.SET_MARK('INSERT',null,'ORDLOC_INVC_COST',
                             'ITEM:'||TO_CHAR(I_item)||
                             ',ORDER NO:'||TO_CHAR(I_order_no));
            insert into ordloc_invc_cost(order_no,
                                         item,
                                         location,
                                         seq_no,
                                         unit_cost,
                                         qty,
                                         match_invc_id,
                                         shipment,
                                         carton)
                         select distinct I_order_no,
                                         I_item,
                                         I_location,
                                        (L_max_seq_no + 1),
                                         unit_cost,
                                         L_buy_accum,
                                         NULL,
                                         I_shipment,
                                         I_carton
                                    from ordloc_invc_cost
                                   where order_no  = I_order_no
                                     and item      = I_item
                                     and location  = I_location
                                     and unit_cost = L_max_unit_cost;

            SQL_LIB.SET_MARK('INSERT',null,'ORDlOC_INVC_COST',
                             'ITEM:'||TO_CHAR(I_item)||
                             ',ORDER NO:'||TO_CHAR(I_order_no));
            INSERT into ordloc_invc_cost(order_no,
                                         item,
                                         location,
                                         seq_no,
                                         unit_cost,
                                         qty,
                                         match_invc_id,
                                         shipment,
                                         carton)
                         SELECT distinct I_order_no,
                                         I_item,
                                         I_location,
                                        (L_max_seq_no + 2),
                                         unit_cost,
                                         L_get_accum,
                                         NULL,
                                         I_shipment,
                                         I_carton
                                    from ordloc_invc_cost
                                   where order_no  = I_order_no
                                     and item      = I_item
                                     and location  = I_location
                                     and unit_cost = L_min_unit_cost;
         end if; -- end if L_shipment = 0
      end if; -- end if c_get_threshold_info%notfound
   end if; -- end if L_max_seq_no > 1 or min_unit_cost <> max_unit_cost

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             'INVC_SQL.UPDATE_INVOICE',
                                             TO_CHAR(SQLCODE));
      return FALSE;

END UPDATE_INVOICE;
---------------------------------------------------------------------------------------------------------------
END INVC_SQL;
/

