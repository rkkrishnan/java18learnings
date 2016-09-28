CREATE OR REPLACE PACKAGE BODY ALC_ORDER_FINALIZE_SQL AS
---------------------------------------------------------------------
FUNCTION WHERE_CLAUSE (O_error_message       IN OUT VARCHAR2,
                       O_out_where_clause    IN OUT VARCHAR2,
                       I_start_variance_pct  IN     NUMBER,
                       I_end_variance_pct    IN     NUMBER)
RETURN BOOLEAN IS

   L_order_no                  ALC_HEAD.ORDER_NO%TYPE;
   L_seq_no                    ALC_HEAD.SEQ_NO%TYPE;
   L_item                      ALC_HEAD.ITEM%TYPE;
   L_pack_item                 ALC_HEAD.PACK_ITEM%TYPE;
   L_total_elc_item            ALC_COMP_LOC.ACT_VALUE%TYPE;
   L_total_alc_item            ALC_COMP_LOC.ACT_VALUE%TYPE;
   L_total_elc_order           ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_total_alc_order           ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_variance_percent          ALC_HEAD.ALC_QTY%TYPE;
   L_unit_elc                  ALC_COMP_LOC.ACT_VALUE%TYPE;
   L_unit_alc                  ALC_COMP_LOC.ACT_VALUE%TYPE;
   L_percent                   NUMBER;
   L_exists                    VARCHAR2(1);
   L_program                   VARCHAR2(64) := 'ALC_ORDER_FINALIZE_SQL.WHERE_CLAUSE';

   cursor C_GET_ALL_FIELDS is
      select order_no,
             seq_no,
             item,
             pack_item
        from alc_head_temp
       order by order_no, seq_no
         for update nowait;

   cursor C_ORDER_EXISTS is
      select 'x'
        from alc_head_temp
       where order_no = L_order_no
         and processed_ind = 'N'
         and rownum        = 1;

BEGIN

   for C_all_fields in C_GET_ALL_FIELDS LOOP
      L_exists           := NULL;
      L_order_no         := C_all_fields.order_no;
      L_seq_no           := C_all_fields.seq_no;
      L_item             := C_all_fields.item;
      L_pack_item        := C_all_fields.pack_item;
      ---
      if ALC_SQL.GET_ORDER_ITEM_TOTALS (O_error_message,
                                        L_unit_elc,
                                        L_unit_alc,
                                        L_total_elc_item,
                                        L_total_alc_item,
                                        L_percent,
                                        L_order_no,
                                        L_item,
                                        L_pack_item) = FALSE then
         return FALSE;
      end if;
      ---
      L_total_elc_order := L_total_elc_order + L_total_elc_item;
      L_total_elc_item  := NULL;
      L_total_alc_order := L_total_alc_order + L_total_alc_item;
      L_total_alc_item  := NULL;
      ---
      update alc_head_temp
         set processed_ind = 'Y'
       where order_no = L_order_no
         and seq_no   = L_seq_no
         and item     = L_item
         and ((pack_item = L_pack_item
               and L_pack_item is NOT NULL
               and pack_item is NOT NULL)
          or (L_pack_item is NULL
              and pack_item is NULL));
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_ORDER_EXISTS',
                       'ALC_HEAD_TEMP',
                       'order_no: '||to_char(L_order_no)||', processed_ind: N');
      open  C_ORDER_EXISTS;
      SQL_LIB.SET_MARK('FETCH',
                       'C_ORDER_EXISTS',
                       'ALC_HEAD_TEMP',
                       'order_no: '||to_char(L_order_no)||', processed_ind: N');
      fetch C_ORDER_EXISTS into L_exists;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_ORDER_EXISTS',
                       'ALC_HEAD_TEMP',
                       'order_no: '||to_char(L_order_no)||', processed_ind: N');
      close C_ORDER_EXISTS;
      ---
      if L_exists is NULL then
         if ALC_SQL.CALC_PERCENT_VARIANCE (O_error_message,
                                           L_variance_percent,
                                           L_total_alc_order,
                                           L_total_elc_order) = FALSE then
             return FALSE;
         end if;
         ---
         update alc_head_temp
            set variance_pct = L_variance_percent
          where order_no = L_order_no
            and seq_no   = L_seq_no
            and item     = L_item
            and ((pack_item = L_pack_item
                  and L_pack_item is NOT NULL
                  and pack_item is NOT NULL)
             or (L_pack_item is NULL
                 and pack_item is NULL));
         ---
         L_total_elc_order  := 0;
         L_total_alc_order  := 0;
         L_variance_percent := NULL;
      end if;
   END LOOP;
   ---
   if I_start_variance_pct is not NULL or I_end_variance_pct is not NULL then
      O_out_where_clause := 'where variance_pct between ' || NVL(I_start_variance_pct,0) || ' and ' || NVL(I_end_variance_pct,100);
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

END WHERE_CLAUSE;
----------------------------------------------------------------------
FUNCTION ALC_FINALIZE (O_error_message      IN OUT VARCHAR2,
                       I_order_no           IN     ORDHEAD.ORDER_NO%TYPE,
                       I_update_wac_ind     IN     VARCHAR2)
   RETURN BOOLEAN IS

   L_supplier        ORDHEAD.SUPPLIER%TYPE;
   L_exists          BOOLEAN;
   L_program         VARCHAR2(64) := 'ALC_ORDER_FINALIZE_SQL.ALC_FINALIZE';

   cursor C_GET_ITEM_INFO is
      select distinct item,
             pack_item
        from alc_head
       where order_no = I_order_no
         and status = 'P'
         and (obligation_key is not null or ce_id is not null);

BEGIN

   if I_order_no is NOT NULL and
      I_update_wac_ind is NOT NULL then
      if ORDER_ATTRIB_SQL.GET_SUPPLIER (O_error_message,
                                        L_exists,
                                        L_supplier,
                                        I_order_no) = FALSE then
         return FALSE;
      end if;
      ---
      for C_item in C_GET_ITEM_INFO LOOP
         ---
         if ALC_SQL.UPDATE_STKLEDGR (O_error_message,
                                     I_order_no,
                                     C_item.item,
                                     C_item.pack_item,
                                     L_supplier) = FALSE then
            return FALSE;
         end if;
         ---
         L_supplier      := NULL;
         L_exists        := NULL;
      END LOOP;
      ---
      if CE_SQL.UPDATE_ORD_ITEM_ALC_STATUS (O_error_message,
                                           'R',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            I_order_no,
                                            NULL) = FALSE then
         return FALSE;
      end if;
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',
                                             L_program,
                                             NULL,
                                             NULL);
      return FALSE;
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
END ALC_FINALIZE;

------------------------------------------------------------------
FUNCTION GET_ALC_STATUS (O_error_message    IN OUT VARCHAR2,
                         O_alc_status       IN OUT ALC_HEAD.STATUS%TYPE,
                         I_order_no         IN     ORDHEAD.ORDER_NO%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(64) := 'ALC_ORDER_FINALIZE_SQL.GET_ALC_STATUS';

   cursor C_STATUS is
      select po_alc_status
        from v_alc_head
       where order_no = I_order_no;

BEGIN

   O_alc_status := 'E';
   open  C_STATUS;
   fetch C_STATUS into O_alc_status;
   close C_STATUS;

   return TRUE;


EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_ALC_STATUS;
----------------------------------------------------------------------
FUNCTION UPDATE_ALC_STATUS (O_error_message    IN OUT VARCHAR2,
                I_order_no         IN     ORDHEAD.ORDER_NO%TYPE,
                I_status           IN     ALC_HEAD.STATUS%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'ALC_ORDER_FINALIZE_SQL.UPDATE_ALC_STATUS';
   L_table              VARCHAR2(64) := 'ALC_HEAD';
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from alc_head
       where order_no = I_order_no
         and status = 'P'
         for update nowait;

BEGIN
   if I_order_no is NOT NULL and I_status is NOT NULL then
      open C_lock_alc_head;
      close C_lock_alc_head;
      ---
      update alc_head
         set status = I_status
       where order_no = I_order_no
         and status = 'P';
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',
                               L_program,
                               NULL,
                               NULL);
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_order_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_ALC_STATUS;

----------------------------------------------------------------------
FUNCTION DELETE_ALC_HEAD_TEMP (O_error_message        IN OUT    VARCHAR2)

   RETURN BOOLEAN IS

   L_program            VARCHAR2(64) := 'ALC_ORDER_FINALIZE_SQL.DELETE_ALC_HEAD_TEMP';
   L_table              VARCHAR2(64) := 'ALC_HEAD_TEMP';
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_ALC_HEAD_TEMP is
      select 'x'
        from alc_head_temp
         for update nowait;

BEGIN
   open  C_LOCK_ALC_HEAD_TEMP;
   close C_LOCK_ALC_HEAD_TEMP;
   ---
   delete from alc_head_temp;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             NULL,
                                             NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_ALC_HEAD_TEMP;
----------------------------------------------------------------------
FUNCTION NO_FINALIZATION (O_error_message    IN OUT VARCHAR2,
                          I_order_no         IN     ORDHEAD.ORDER_NO%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64) := 'ALC_ORDER_FINALIZE_SQL.NO_FINALIZATION';
   L_table              VARCHAR2(64) := 'ALC_HEAD';
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from alc_head
       where order_no = I_order_no
         and status = 'E'
         for update nowait;

BEGIN
   if I_order_no is NOT NULL then
      open C_lock_alc_head;
      close C_lock_alc_head;
      ---
      update alc_head
         set status = 'N'
       where order_no = I_order_no
         and status = 'E';
      ---
      if sql%rowcount = 0 then
         if not ALC_ALLOC_SQL.INSERT_ELC_COMPS(O_error_message,
                                               I_order_no) then
            return FALSE;
         end if;
         update alc_head
            set status = 'N'
          where order_no = I_order_no
            and status = 'E';
      end if;
      ---
   else
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',
                                            L_program,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_order_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END NO_FINALIZATION;

----------------------------------------------------------------------
END ALC_ORDER_FINALIZE_SQL;
/

