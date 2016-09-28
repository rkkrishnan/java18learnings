CREATE OR REPLACE PACKAGE BODY INVC_ITEM_SQL AS
-----------------------------------------------------------------------------------------
FUNCTION INSERT_MATCH_QUEUE(O_error_message IN OUT VARCHAR2,
                            I_invc_id       IN     INVC_HEAD.INVC_ID%TYPE)
   return BOOLEAN IS

   L_program VARCHAR2(50) := 'INVC_ITEM_SQL.INSERT_MATCH_QUEUE';

BEGIN

   insert into invc_match_queue(invc_id)
                         values(I_invc_id);
   ---
   return TRUE;

EXCEPTION
   when DUP_VAL_ON_INDEX then
      return TRUE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END INSERT_MATCH_QUEUE;
-----------------------------------------------------------------------------------------
FUNCTION DELETE_MATCH_WKSHT(O_error_message   IN OUT VARCHAR2,
                            I_invc_id         IN     INVC_HEAD.INVC_ID%TYPE,
                            I_item            IN     ITEM_MASTER.ITEM%TYPE,
                            I_invc_unit_cost  IN     INVC_DETAIL.INVC_UNIT_COST%TYPE)
   return BOOLEAN IS

   L_program VARCHAR2(50) := 'INVC_ITEM_SQL. DELETE_MATCH_WKSHT';
   L_table   VARCHAR2(30) := 'INVC_MATCH_WKSHT';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(Record_Locked, -54);

   cursor C_lock_match_wksht is
      select 'x'
        from invc_match_wksht
       where invc_id        = I_invc_id
         and item           = I_item
         and invc_unit_cost = I_invc_unit_cost
         for update nowait;

BEGIN

   open C_lock_match_wksht;
   close C_lock_match_wksht;
   ---
   delete
     from invc_match_wksht
    where invc_id        = I_invc_id
      and item           = I_item
      and invc_unit_cost = I_invc_unit_cost;
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
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END DELETE_MATCH_WKSHT;
-----------------------------------------------------------------------------------------
FUNCTION INSERT_UPDATE_INVC(O_error_message     IN OUT VARCHAR2,
                            I_insert_update_ind IN     VARCHAR2,
                            I_invc_id           IN     INVC_HEAD.INVC_ID%TYPE,
                            I_item              IN     ITEM_MASTER.ITEM%TYPE,
                            I_invc_unit_cost    IN     INVC_DETAIL.INVC_UNIT_COST%TYPE,
                            I_shipment          IN     SHIPMENT.SHIPMENT%TYPE,
                            I_carton            IN     CARTON.CARTON%TYPE,
                            I_seq_no            IN     INVC_MATCH_WKSHT.SEQ_NO%TYPE,
                            I_match_to_cost     IN     INVC_MATCH_WKSHT.MATCH_TO_COST%TYPE,
                            I_match_to_qty      IN     INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE,
                            I_match_to_seq_no   IN     INVC_MATCH_WKSHT.MATCH_TO_SEQ_NO%TYPE)
   return BOOLEAN IS

   L_program         VARCHAR2(50) := 'INVC_ITEM_SQL.INSERT_UPDATE_INVC';
   L_dup_record      VARCHAR(2)   := 'Y';
   L_table           VARCHAR2(30) := 'INVC_MATCH_WKSHT';
   RECORD_LOCKED     EXCEPTION;
   PRAGMA            EXCEPTION_INIT(Record_Locked, -54);

   cursor C_CHECK_DUP_XREF is
      select 'X'
        from invc_xref
       where invc_id  = I_invc_id
         and shipment = I_shipment;

   cursor C_CHECK_DUP_WKSHT is
      select 'x'
        from invc_match_wksht
       where invc_id        = I_invc_id
         and item           = I_item
         and shipment       = I_shipment
         and seq_no         = I_seq_no
         and invc_unit_cost = I_invc_unit_cost
        for update nowait;

BEGIN

   if I_insert_update_ind = 'I' then
      insert into invc_match_wksht(invc_id,
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
             I_item,
             I_invc_unit_cost,
             I_shipment,
             I_seq_no,
             I_carton,
             NULL,
             I_match_to_cost,
             I_match_to_qty,
             I_match_to_seq_no);
      ---
      open C_CHECK_DUP_XREF;
      fetch C_CHECK_DUP_XREF into L_dup_record;
      close C_CHECK_DUP_XREF;
      ---
      if L_dup_record = 'Y' then
         insert into invc_xref(invc_id,
                               order_no,
                               shipment,
                               asn,
                               location,
                               loc_type,
                               apply_to_future_ind)
         select I_invc_id,
                order_no,
                I_shipment,
                asn,
                to_loc,
                to_loc_type,
                'N'
           from shipment
          where shipment = I_shipment;
      end if;
   elsif I_insert_update_ind = 'U' then
      open C_CHECK_DUP_WKSHT;
      fetch C_CHECK_DUP_WKSHT into L_dup_record;
      close C_CHECK_DUP_WKSHT;
      ---
      if L_dup_record = 'Y' then
         insert into invc_match_wksht(invc_id,
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
                   I_item,
                   I_invc_unit_cost,
                   I_shipment,
                   I_seq_no,
                   I_carton,
                   NULL,
                   I_match_to_cost,
                   I_match_to_qty,
                   I_match_to_seq_no);
      else
         update invc_match_wksht
            set match_to_cost   = I_match_to_cost,
                match_to_qty    = I_match_to_qty,
                match_to_seq_no = I_match_to_seq_no
          where invc_id         = I_invc_id
         and   item            = I_item
         and   shipment        = I_shipment
         and   seq_no          = I_seq_no
         and   invc_unit_cost  = I_invc_unit_cost;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',
                                             L_program);
      return FALSE;
   end if;
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
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END INSERT_UPDATE_INVC;
-----------------------------------------------------------------------------------------
FUNCTION CHECK_DUPLICATES(O_error_message     IN OUT VARCHAR2,
                          O_exists            IN OUT BOOLEAN,
                          I_item              IN     ITEM_MASTER.ITEM%TYPE,
                          I_invc_unit_cost    IN     INVC_DETAIL.INVC_UNIT_COST%TYPE,
                          I_invc_id           IN     INVC_HEAD.INVC_ID%TYPE)
return BOOLEAN IS

   L_program         VARCHAR2(50) := 'INVC_ITEM_SQL.CHECK_DUPLICATES';
   L_exists          VARCHAR2(1)  := 'N';

   cursor C_check_duplicates is
      select 'Y'
        from invc_detail
       where item           = I_item
         and invc_unit_cost = I_invc_unit_cost
         and invc_id        = I_invc_id;

BEGIN

   O_exists := FALSE;
   ---
   open C_check_duplicates;
   fetch C_check_duplicates into L_exists;
   close C_check_duplicates;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
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
END CHECK_DUPLICATES;
-----------------------------------------------------------------------------------------
FUNCTION CHECK_DUPLICATES_WKSHT(O_error_message     IN OUT VARCHAR2,
                                O_exists            IN OUT BOOLEAN,
                                I_item              IN     ITEM_MASTER.ITEM%TYPE,
                                I_invc_unit_cost    IN     INVC_DETAIL.INVC_UNIT_COST%TYPE,
                                I_invc_id           IN     INVC_HEAD.INVC_ID%TYPE,
                                I_shipment          IN     SHIPMENT.SHIPMENT%TYPE,
                                I_seq_no            IN     INVC_MATCH_WKSHT.SEQ_NO%TYPE)
   return BOOLEAN IS

   L_program         VARCHAR2(60) := 'INVC_ITEM_SQL.CHECK_DUPLICATES_WKSHT';
   L_exists          VARCHAR2(1)  := 'N';

   cursor C_check_duplicates is
      select 'Y'
        from invc_match_wksht
       where item           = I_item
         and invc_unit_cost = I_invc_unit_cost
         and invc_id        = I_invc_id
         and shipment       = I_shipment
         and seq_no         = I_seq_no;

BEGIN

   O_exists := FALSE;
   ---
   open C_check_duplicates;
   fetch C_check_duplicates into L_exists;
   close C_check_duplicates;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
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
END CHECK_DUPLICATES_WKSHT;
-----------------------------------------------------------------------------------------
FUNCTION MULTIPLE_RCPT_INFO(O_error_message   IN OUT VARCHAR2,
                            O_count_rcpts     IN OUT NUMBER,
                            O_total_qty       IN OUT INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE,
                            O_shipment        IN OUT SHIPMENT.SHIPMENT%TYPE,
                            O_carton          IN OUT CARTON.CARTON%TYPE,
                            O_seq_no          IN OUT INVC_MATCH_WKSHT.SEQ_NO%TYPE,
                            O_match_to_qty    IN OUT INVC_MATCH_WKSHT.MATCH_TO_QTY%TYPE,
                            O_match_to_cost   IN OUT INVC_MATCH_WKSHT.MATCH_TO_COST%TYPE,
                            O_match_to_seq_no IN OUT INVC_MATCH_WKSHT.MATCH_TO_SEQ_NO%TYPE,
                            I_invc_id         IN     INVC_HEAD.INVC_ID%TYPE,
                            I_item            IN     ITEM_MASTER.ITEM%TYPE,
                            I_invc_unit_cost  IN     INVC_MATCH_WKSHT.INVC_UNIT_COST%TYPE)
   return BOOLEAN IS

   L_program VARCHAR2(50) := 'INVC_ITEM_SQL.MULTIPLE_RCPT_INFO';
   L_match_to_cost INVC_MATCH_WKSHT.MATCH_TO_COST%TYPE;

   cursor C_mult_rcpts is
    select count(invc_id),
           nvl(SUM(nvl(match_to_qty,0)),0),
           match_to_cost
      from invc_match_wksht
     where invc_id        = I_invc_id
       and item           = I_item
       and invc_unit_cost = I_invc_unit_cost
       group by match_to_cost;

  cursor C_shipment is
    select shipment,
           carton,
           seq_no,
           match_to_qty,
           match_to_cost,
           match_to_seq_no
      from invc_match_wksht
     where invc_id        = I_invc_id
       and item           = I_item
       and invc_unit_cost = I_invc_unit_cost;

BEGIN

   --- Check for multiple shipments associated with this line item
   open C_mult_rcpts;
   fetch C_mult_rcpts into O_count_rcpts,
                           O_total_qty,
                           L_match_to_cost;
   close C_mult_rcpts;
   ---
   if O_count_rcpts = 1 then
      open C_shipment;
      fetch C_shipment into O_shipment,
                            O_carton,
                            O_seq_no,
                            O_match_to_qty,
                            O_match_to_cost,
                            O_match_to_seq_no;
      close C_shipment;
   else
      O_match_to_cost := L_match_to_cost;
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
END MULTIPLE_RCPT_INFO;
-----------------------------------------------------------------------------------------
FUNCTION VALID_ORDER_OR_CARTON(O_error_message IN OUT VARCHAR2,
                               O_valid         IN OUT BOOLEAN,
                               O_bill_to_id    IN OUT ORDHEAD.BILL_TO_ID%TYPE,
                               I_order_no      IN     ORDHEAD.ORDER_NO%TYPE,
                               I_carton        IN     CARTON.CARTON%TYPE,
                               I_shipment      IN     SHIPMENT.SHIPMENT%TYPE,
                               I_asn_no        IN     SHIPMENT.ASN%TYPE,
                               I_supplier      IN     SUPS.SUPPLIER%TYPE,
                               I_item          IN     ITEM_MASTER.ITEM%TYPE,
                               I_mult_sup_ind  IN     VARCHAR2)
   return BOOLEAN is

   L_program VARCHAR2(50) := 'INVC_ITEM_SQL.VALID_ORDER_OR_CARTON';

   cursor C_valid is
      select o.bill_to_id
        from shipsku k,
             shipment h,
             ordhead o
       where ((k.carton            = NVL(I_carton, k.carton)
               and k.carton is NOT NULL)
          or (k.carton is NULL
               and I_carton is NULL))
         and k.item              = I_item
         and k.match_invc_id is NULL
         and k.shipment          = nvl(I_shipment, k.shipment)
         and k.shipment          = h.shipment
         and h.invc_match_status = 'U'
         and h.status_code       = 'R'
         and (h.asn     = nvl(I_asn_no, h.asn)
          or (h.asn is NULL and I_asn_no is NULL))
         and h.order_no          = nvl(I_order_no, h.order_no)
         and h.order_no          = o.order_no
         and ((o.supplier        = I_supplier
               and I_mult_sup_ind = 'N')
          or I_mult_sup_ind = 'Y');

BEGIN

   O_valid := FALSE;
   ---
   open C_valid;
   fetch C_valid into O_bill_to_id;
   ---
   if C_valid%FOUND then
      O_valid := TRUE;
   end if;
   ---
   close C_valid;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALID_ORDER_OR_CARTON;
-----------------------------------------------------------------------------------------
FUNCTION UPDATE_INVC_QTY(O_error_message    IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         O_invc_qty         IN OUT   INVC_DETAIL.INVC_QTY%TYPE,
                         I_item             IN       INVC_DETAIL.ITEM%TYPE,
                         I_invc_unit_cost   IN       INVC_DETAIL.INVC_UNIT_COST%TYPE,
                         I_invc_id          IN       INVC_DETAIL.INVC_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'INVC_ITEM_SQL.UPDATE_INVC_QTY';

BEGIN

   update invc_detail
      set invc_qty = invc_qty + O_invc_qty
    where invc_id        = I_invc_id
      and item           = I_item
      and invc_unit_cost = I_invc_unit_cost;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END UPDATE_INVC_QTY;
-------------------------------------------------------------------------------------------
END;
/

