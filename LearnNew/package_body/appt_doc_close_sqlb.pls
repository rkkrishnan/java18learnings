CREATE OR REPLACE PACKAGE BODY APPT_DOC_CLOSE_SQL AS
----------------------------------------------------------------------------------------------
FUNCTION CHECK_OPEN_APPTS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          O_open           IN OUT BOOLEAN,
                          I_doc            IN     APPT_DETAIL.DOC%TYPE,
                          I_doc_type       IN     APPT_DETAIL.DOC_TYPE%TYPE)
RETURN BOOLEAN IS
   L_flag      VARCHAR2(1);
   L_function  VARCHAR2(50) := 'APPT_DOC_CLOSE_SQL.CHECK_OPEN_APPTS';
   ---
   cursor C_CHECK_OPEN_APPTS is
      select 'x'
        from appt_head ah, appt_detail ad
       where ah.appt     = ad.appt
         and ah.loc      = ad.loc
         and ah.loc_type = ad.loc_type
         and ad.doc      = I_doc
         and ad.doc_type = I_doc_type
         and ah.status  != 'AC'
         and rownum      = 1;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_CHECK_OPEN_APPTS','APPT_HEAD, APPT_DETAIL',NULL);
   open C_CHECK_OPEN_APPTS;
   SQL_LIB.SET_MARK('OPEN','C_CHECK_APPTS','APPT_HEAD, APPT_DETAIL',NULL);
   fetch C_CHECK_OPEN_APPTS into L_flag;
   ---
   if C_CHECK_OPEN_APPTS%FOUND then
      O_open := TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_APPTS','APPT_HEAD, APPT_DETAIL',NULL);
   close C_CHECK_OPEN_APPTS;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;

END CHECK_OPEN_APPTS;
----------------------------------------------------------------------------------------------
FUNCTION CLOSE_PO(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                  O_closed         IN OUT BOOLEAN,
                  I_order          IN     APPT_DETAIL.DOC%TYPE)
RETURN BOOLEAN IS
   L_function           VARCHAR2(50) := 'APPT_DOC_CLOSE_SQL.CLOSE_PO';
   L_flag               VARCHAR2(1);
   L_exist              BOOLEAN;
   L_appr_ind           VARCHAR2(3);
   L_import_ind         SYSTEM_OPTIONS.IMPORT_IND%TYPE;
   L_rtm_simplified_ind SYSTEM_OPTIONS.RTM_SIMPLIFIED_IND%TYPE;
   L_system_options_row SYSTEM_OPTIONS%ROWTYPE;
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(RECORD_LOCKED, -54);
   L_vdate              DATE         := GET_VDATE;
   ---
   cursor C_CHECK_QTYS is
      select 'x'
        from ordloc
       where order_no    = I_order
         and qty_ordered > NVL(qty_received, 0)
         and rownum = 1;

   cursor C_LOCK_ORDHEAD is
      select 'x'
        from ordhead
       where order_no = I_order
         for update nowait;

BEGIN
   O_closed := FALSE;
   SQL_LIB.SET_MARK('OPEN','C_CHECK_QTYS','ORDLOC',NULL);
   open C_CHECK_QTYS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_QTYS','ORDLOC',NULL);
   fetch C_CHECK_QTYS into L_flag;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_QTYS','ORDLOC',NULL);
   close C_CHECK_QTYS;
   ---

   if L_flag is NULL then
      SQL_LIB.SET_MARK('OPEN','C_LOCK_ORDHEAD','ORDHEAD',NULL);
      open C_LOCK_ORDHEAD;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_ORDHEAD','ORDHEAD',NULL);
      close C_LOCK_ORDHEAD;
      ---
      SQL_LIB.SET_MARK('UPDATE',NULL,'ORDHEAD','ORDER_NO:'||I_order);
      update ordhead
         set status     = 'C',
             close_date = L_vdate
       where order_no = I_order
         and status  != 'C';
      ---
      if DEAL_VALIDATE_SQL.DEAL_CALC_QUEUE_EXIST(O_error_message,
                                                 L_exist,
                                                 L_appr_ind,
                                                 I_order) = FALSE then
         return FALSE;
      end if;
      ---
      if L_exist then
         if ORDER_STATUS_SQL.DELETE_DEAL_CALC_QUEUE(O_error_message,
                                                    I_order) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      if SYSTEM_OPTIONS_SQL.GET_SYSTEM_OPTIONS(O_error_message,
                                               L_system_options_row) = FALSE then
         return FALSE;
      end if;
      ---
      L_import_ind := L_system_options_row.import_ind;
      L_rtm_simplified_ind := L_system_options_row.rtm_simplified_ind;
      ---
      if (L_import_ind = 'Y' and L_rtm_simplified_ind = 'N') then
         if ALC_ALLOC_SQL.ALLOC_ALL_PO_OBL(O_error_message,
                                           I_order) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      O_closed := TRUE;

   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED_MODULE',
                                             'ORDHEAD',
                                             'Order: '||to_char(I_order),
                                             L_function);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;

END CLOSE_PO;
-------------------------------------------------------------------------------------------
FUNCTION INS_UPD_TSFDETAIL(O_error_message    IN OUT  VARCHAR2,
                           I_tsf_no           IN      TSFDETAIL.TSF_NO%TYPE,
                           I_item             IN      TSFDETAIL.ITEM%TYPE,
                           I_tsf_qty          IN      TSFDETAIL.TSF_QTY%TYPE,
                           I_reconciled_qty   IN      TSFDETAIL.RECONCILED_QTY%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'APPT_DOC_CLOSE_SQL.INS_UPD_TSFDETAIL';

   L_rowid                    ROWID := NULL;

   L_table                    VARCHAR2(30) := 'TSFDETAIL';
   L_key1                     VARCHAR2(100) := I_tsf_no;
   L_key2                     VARCHAR2(100) := I_item;
   RECORD_LOCKED              EXCEPTION;
   PRAGMA                     EXCEPTION_INIT(Record_Locked, -54);

   L_item_exist               VARCHAR2(1) := 'N';
   L_tsf_seq_no               TSFDETAIL.TSF_SEQ_NO%TYPE := 0;
   L_supp_pack_size           TSFDETAIL.SUPP_PACK_SIZE%TYPE;
   L_inner_pack_size          item_supp_country.inner_pack_size%TYPE;

   cursor C_tsfdetail_lock is
      select rowid
        from tsfdetail
       where tsf_no = I_tsf_no
         and item = I_item
         for update nowait;

   cursor C_item_exist is
      select 'Y'
        from tsfdetail
       where tsf_no = I_tsf_no
         and item = I_item;

   cursor C_get_tsf_seq_no is
      select max(tsf_seq_no) + 1
        from tsfdetail
       where tsf_no = I_tsf_no;
BEGIN
   ---
   open C_item_exist;
   fetch C_item_exist into L_item_exist;
   close C_item_exist;
   ---
   if L_item_exist = 'Y' then
      ---
      open C_tsfdetail_lock;
      fetch C_tsfdetail_lock into L_rowid;
      close C_tsfdetail_lock;
      ---
      update tsfdetail
         set tsf_qty = tsf_qty + I_tsf_qty,
             reconciled_qty = nvl(reconciled_qty, 0) + nvl(I_reconciled_qty, 0)
       where rowid = L_rowid;
      ---
   else
      ---
      open C_get_tsf_seq_no;
      fetch C_get_tsf_seq_no into L_tsf_seq_no;
      ---
      if C_get_tsf_seq_no%NOTFOUND then
         L_tsf_seq_no := 1;
      end if;
      ---
      close C_get_tsf_seq_no;
      ---
      if L_tsf_seq_no is null then
         L_tsf_seq_no := 1;
      end if;
      ---
      if ITEM_SUPP_COUNTRY_SQL.DEFAULT_PRIM_CASE_SIZE(O_error_message,
                                                      L_supp_pack_size,
                                                      L_inner_pack_size,
                                                      I_item) = FALSE then
         return FALSE;
      end if;
      ---
      insert into tsfdetail(tsf_no,
                            tsf_seq_no,
                            item,
                            tsf_qty,
                            reconciled_qty,
                            supp_pack_size,
                            publish_ind)
                     values(I_tsf_no,
                            L_tsf_seq_no,
                            I_item,
                            I_tsf_qty,
                            nvl(I_reconciled_qty, 0),
                            L_supp_pack_size,
                            'N');
      ---
   end if;
   ---

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_key1,
                                             L_key2);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END INS_UPD_TSFDETAIL;
----------------------------------------------------------------------------------------------
FUNCTION REBUILD_2ND_LEG_DETAIL(O_error_message         IN OUT  VARCHAR2,
                                I_1st_leg_tsf_no        IN      TSFDETAIL.TSF_NO%TYPE,
                                I_2nd_leg_tsf_no        IN      TSFDETAIL.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'APPT_DOC_CLOSE_SQL.REBUILD_2ND_LEG_DETAIL';

   L_rowid                    ROWID;
   L_table                    VARCHAR2(30) := 'TSFDETAIL';
   L_key1                     VARCHAR2(100) := I_2nd_leg_tsf_no;
   L_key2                     VARCHAR2(100);
   RECORD_LOCKED              EXCEPTION;
   PRAGMA                     EXCEPTION_INIT(Record_Locked, -54);


   L_item_exist               VARCHAR2(1) := 'N';
   L_tsf_seq_no               TSFDETAIL.TSF_SEQ_NO%TYPE := 0;
   L_supp_pack_size           TSFDETAIL.SUPP_PACK_SIZE%TYPE;
   L_inner_pack_size          ITEM_SUPP_COUNTRY.INNER_PACK_SIZE%TYPE;
   L_comp_not_exist           VARCHAR2(1) := 'N';
   L_pack_qty                 NUMBER;
   L_to_pack_qty              TSFDETAIL.TSF_QTY%TYPE;
   L_item_master              ITEM_MASTER%ROWTYPE;
   L_tsf_xform_detail_id      TSF_XFORM_DETAIL.TSF_XFORM_DETAIL_ID%TYPE;
   L_to_item                  TSF_XFORM_DETAIL.TO_ITEM%TYPE;
   L_from_item                TSF_PACKING_DETAIL.ITEM%TYPE;
   L_set_no                   TSF_PACKING.SET_NO%TYPE;
   L_tsf_packing_id           TSF_PACKING.TSF_PACKING_ID%TYPE;
   L_packing_detail_id        TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE;
   L_return_code              BOOLEAN;

   cursor C_calc_2nd_leg_tsfqty is
      select item, sum(tsf_qty) tsf_qty, sum(reconciled_qty) reconciled_qty, tsf_price, supp_pack_size, publish_ind
        from (select t.item,
                     ss.qty_received tsf_qty,
                     (ss.qty_expected - ss.qty_received) reconciled_qty,
                     t.tsf_price,
                     t.supp_pack_size,
                     t.publish_ind
                from tsfdetail t,
                     shipsku ss
               where ss.distro_type = 'T'
                 and ss.distro_no = t.tsf_no
       and ss.item = t.item
                 and t.tsf_no = I_1st_leg_tsf_no
                 and ss.adjust_type is not null
                 and ss.adjust_type != 'FR'
               union all
              select t.item,
                     ss.qty_expected tsf_qty,
                     (ss.qty_expected - ss.qty_received) reconciled_qty,
                     t.tsf_price,
                     t.supp_pack_size,
                     t.publish_ind
                from tsfdetail t,
                     shipsku ss
               where ss.distro_type = 'T'
                 and ss.distro_no = t.tsf_no
       and ss.item = t.item
                 and t.tsf_no = I_1st_leg_tsf_no
                 and ss.adjust_type = 'FR'
               union all
              select t.item,
                     ss.qty_expected tsf_qty,
                     0 reconciled_qty,
                     t.tsf_price,
                     t.supp_pack_size,
                     t.publish_ind
                from tsfdetail t,
                     shipsku ss
               where ss.distro_type = 'T'
                 and ss.distro_no = t.tsf_no
       and ss.item = t.item
                 and t.tsf_no = I_1st_leg_tsf_no
                 and ss.adjust_type is NULL)
       group by item, tsf_price, supp_pack_size, publish_ind;

   cursor C_tsfdetail_lock(cv_item   tsfdetail.item%type) is
      select rowid
        from tsfdetail
       where tsf_no = I_2nd_leg_tsf_no
         and item = cv_item
         for update nowait;

   cursor C_xform_exist(cv_item  tsfdetail.item%type) is
      select tsf_xform_detail_id,
             to_item
        from tsf_xform tx,
             tsf_xform_detail txd
       where tx.tsf_xform_id  = txd.tsf_xform_id
         and tx.tsf_no = I_1st_leg_tsf_no
         and txd.from_item = cv_item;

   cursor C_comp_in_pack(cv_pack_no  v_packsku_qty.pack_no%type) is
      select item,
             qty
        from v_packsku_qty
       where pack_no = cv_pack_no;

   cursor C_item_exist(cv_item   tsfdetail.item%type) is
      select 'Y'
        from tsfdetail
       where tsf_no = I_2nd_leg_tsf_no
         and item = cv_item;

   ---
   -- Pack_no previously built on packing table

   cursor C_built_pack is
      select tp.tsf_packing_id,
             tp.set_no,
             tpd.item
        from tsf_packing tp,
             tsf_packing_detail tpd,
             item_master im
       where tp.tsf_packing_id = tpd.tsf_packing_id
         and tp.tsf_no = I_1st_leg_tsf_no
         and tpd.record_type = 'R'
         and tpd.item = im.item
         and im.pack_ind = 'Y';

   ---
   -- 2nd-leg does not have all components to re-build the pack

   cursor C_comp_not_exist (cv_pack_no  v_packsku_qty.pack_no%type) is
      select 'Y'
        from v_packsku_qty
       where pack_no = cv_pack_no
         and item not in (select item
                            from tsfdetail
            where tsf_no = I_2nd_leg_tsf_no);

   cursor C_comp_for_pack(cv_pack_no  v_packsku_qty.pack_no%type) is
      select t.item,
             trunc(t.tsf_qty/v.qty) pack_qty
        from tsfdetail t,
             v_packsku_qty v
       where t.item = v.item
         and v.pack_no = cv_pack_no
         and t.tsf_no = I_2nd_leg_tsf_no;
   cursor C_pack_to_pack(cv_packing_id tsf_packing_detail.tsf_packing_id%type,
                         cv_item       tsf_packing_detail.item%type) is
      select distinct tpd.qty,
                      tpd.item
        from tsf_packing tp,
             tsf_packing_detail tpd,
             v_packsku_qty v
       where tp.tsf_no = I_1st_leg_tsf_no
         and tp.tsf_packing_id = tpd.tsf_packing_id
         and tp.tsf_packing_id = cv_packing_id
         and tpd.record_type = 'F'
         and tpd.item = v.pack_no
         and exists (select 'x'
             from tsf_packing_detail td,
             v_packsku_qty v
            where td.tsf_packing_id = cv_packing_id
              and td.item = cv_item
         and td.item = v.pack_no);

   cursor C_calc_left_item(cv_pack_no  v_packsku_qty.pack_no%type) is
      select v.item,
             t.tsf_qty,
             (t.tsf_qty - (L_pack_qty * v.qty)) left_qty
        from tsfdetail t,
             v_packsku_qty v
       where t.item = v.item
         and t.tsf_no = I_2nd_leg_tsf_no
         and v.pack_no = cv_pack_no;

   cursor C_tpd_lock(cv_item          tsf_packing_detail.item%type,
                     cv_record_type   tsf_packing_detail.record_type%type) is
      select tpd.rowid
        from tsf_packing tp,
             tsf_packing_detail tpd
       where tp.tsf_packing_id = tpd.tsf_packing_id
         and tp.tsf_no = I_1st_leg_tsf_no
         and tpd.record_type = cv_record_type
         and tpd.item = cv_item
         for update nowait;

   cursor C_tpd_to_lock(cv_tsf_packing_id    tsf_packing_detail.tsf_packing_id%type,
                        cv_item              tsf_packing_detail.item%type) is
      select rowid
        from tsf_packing_detail
       where tsf_packing_id = cv_tsf_packing_id
         and record_type = 'R'
         and item = cv_item
         for update nowait;

   cursor C_tpd_pack_to_lock(cv_packing_id tsf_packing_detail.tsf_packing_id%type,
                         cv_item       tsf_packing_detail.item%type) is
      select tpd.rowid
        from tsf_packing tp,
             tsf_packing_detail tpd
       where tp.tsf_no = I_1st_leg_tsf_no
         and tp.tsf_packing_id = tpd.tsf_packing_id
         and tp.tsf_packing_id = cv_packing_id
         and tpd.record_type = 'R'
         and tpd.item = cv_item
    for update nowait;

   cursor C_txd_lock(cv_item  tsf_xform_detail.from_item%type) is
      select txd.rowid
        from tsf_xform tx,
             tsf_xform_detail txd
       where tx.tsf_xform_id = txd.tsf_xform_id
         and tx.tsf_no = I_1st_leg_tsf_no
         and txd.from_item = cv_item
         for update nowait;

   cursor C_get_seq_no is
      select max(tsf_seq_no) + 1
        from tsfdetail
       where tsf_no = I_2nd_leg_tsf_no;

   ---
   -- The PL/SQL table L_xform is used for updating the transformation info,
   -- its initial value is coming from the cursor C_xform_detail

   TYPE REC_xform IS RECORD(
      from_item       tsf_xform_detail.from_item%type,
      to_item         tsf_xform_detail.to_item%type,
      from_qty        tsf_xform_detail.from_qty%type);

   TYPE TBL_xform   IS TABLE OF REC_xform
      INDEX BY BINARY_INTEGER;

   L_xform     TBL_xform;
   L_idx       BINARY_INTEGER;

   cursor C_xform_detail is
      select txd.from_item,
             txd.to_item,
             0
        from tsf_xform tx,
             tsf_xform_detail txd
       where tx.tsf_xform_id = txd.tsf_xform_id
         and tx.tsf_no = I_1st_leg_tsf_no;
   ---
   -- After rebuild 2nd-leg, if initially exists a exploded pack, the packing
   -- instruction for this pack must also be updated based on shortage/overage

   cursor C_explode_pack is
      select tp.set_no,
             tpd.tsf_packing_id,
             tpd.item,
             tpd.qty
        from tsf_packing tp,
             tsf_packing_detail tpd,
        item_master im
       where tp.tsf_packing_id = tpd.tsf_packing_id
         and tpd.item = im.item
         and im.pack_ind = 'Y'
         and tp.tsf_no = I_1st_leg_tsf_no
         and tpd.record_type = 'F'
         and not exists (select 'x'
                           from tsf_packing_detail tpd2,
                      item_master im2
           where tpd2.tsf_packing_id = tpd.tsf_packing_id
             and tpd2.item = im2.item
             and im2.pack_ind = 'Y'
             and tpd2.record_type = 'R');

   ---
   -- The PL/SQL table L_packing is used for updating the packing instruction for a built pack,
   -- its initial available components is coming from the cursor C_avail_comp, the rebuilding
   -- process happens after rebuild 2nd-leg.

   cursor C_avail_comp(cv_tsf_packing_id   tsf_packing.tsf_packing_id%type,
                       cv_pack_no          v_packsku_qty.pack_no%type) is

      select v.item,
             v.qty comp_qty,
             avl.qty,
             0 left_qty,
             trunc(avl.qty/v.qty) pack_qty
        from v_packsku_qty v,
             (select item, sum(qty) qty
                from (select tpd.item, td.received_qty qty
                        from tsf_packing_detail tpd,
                             item_master im,
                             tsfdetail td
                       where tpd.item = im.item
                         and td.item = tpd.item
                         and td.tsf_no = I_1st_leg_tsf_no
                         and im.pack_ind = 'N'
                         and tpd.tsf_packing_id = cv_tsf_packing_id
                         and tpd.record_type = 'F'
                         and not exists (select 'x'
                                           from tsf_xform tx,
                       tsf_xform_detail txd
                 where tx.tsf_xform_id = txd.tsf_xform_id
                   and tx.tsf_no = td.tsf_no
                   and txd.from_item = tpd.item)
                       union all
            select v.item, (v.qty * td.received_qty) qty
                        from tsf_packing_detail tpd,
                             v_packsku_qty v,
                             tsfdetail td
                       where tpd.item = v.pack_no
                         and tpd.item = td.item
                         and td.tsf_no = I_1st_leg_tsf_no
                         and tpd.tsf_packing_id = cv_tsf_packing_id
                         and tpd.record_type = 'F'
                         and not exists (select 'x'
                                           from tsf_xform tx,
                       tsf_xform_detail txd
                 where tx.tsf_xform_id = txd.tsf_xform_id
                   and tx.tsf_no = td.tsf_no
                   and txd.from_item = v.item)
                       union all
                      select txd.to_item item, td.received_qty qty
                        from tsf_xform tx,
                             tsf_xform_detail txd,
                             tsf_packing_detail tpd,
                             tsfdetail td
                       where tx.tsf_xform_id = txd.tsf_xform_id
                         and tx.tsf_no = td.tsf_no
                         and tx.tsf_no = I_1st_leg_tsf_no
                         and txd.to_item = tpd.item
                         and txd.from_item = td.item
                         and tpd.record_type = 'F'
                         and tpd.tsf_packing_id = cv_tsf_packing_id
                       union all
                      select txd.to_item item, (td.received_qty * v.qty) qty
                        from tsf_xform tx,
                             tsf_xform_detail txd,
                        tsf_packing_detail tpd,
                        v_packsku_qty v,
                             tsfdetail td
                       where tx.tsf_xform_id = txd.tsf_xform_id
                         and tx.tsf_no = td.tsf_no
                         and tx.tsf_no = I_1st_leg_tsf_no
                         and txd.to_item = v.item
                         and v.pack_no = td.item
                         and v.pack_no = tpd.item
                         and tpd.record_type = 'F'
                         and tpd.tsf_packing_id = cv_tsf_packing_id)
                group by item) avl
       where avl.item = v.item
         and v.pack_no = cv_pack_no;

   TYPE REC_packing IS RECORD(
      item          tsf_packing_detail.item%type,
      comp_qty      tsf_packing_detail.qty%type,
      avail_qty     tsf_packing_detail.qty%type,
      left_qty      tsf_packing_detail.qty%type,
      pack_qty      tsf_packing_detail.qty%type);

   TYPE TBL_packing IS TABLE OF REC_packing
      INDEX BY BINARY_INTEGER;

   L_packing        TBL_packing;

BEGIN
   ---
   if I_1st_leg_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_1st_leg_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_2nd_leg_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_2nd_leg_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   -- Step 1. remove the initial 2nd-leg
   ---
   delete from tsfdetail
         where tsf_no = I_2nd_leg_tsf_no;
   ---
   L_xform.DELETE;
   ---
   open C_xform_detail;
   fetch C_xform_detail BULK COLLECT INTO L_xform;
   close C_xform_detail;

   -- step 2. rebuild 2nd-leg with initial items in the 1st-leg and the new qty after being reconciled,
   --         update the existing item tranformation instructions with the new quantity
   ---
   L_tsf_seq_no := 0;
   ---
   FOR REC_item IN C_calc_2nd_leg_tsfqty LOOP
      ---
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_master,
                                         REC_item.item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_item_master.pack_ind = 'N' then
         ---
         L_tsf_xform_detail_id := NULL;
         L_to_item := NULL;
         ---
         open C_xform_exist(REC_item.item);
         fetch C_xform_exist into L_tsf_xform_detail_id,
                                  L_to_item;
         close C_xform_exist;
         ---
         if L_tsf_xform_detail_id is not null then  -- item has been transformed
            ---
            -- accumulate the transformed qty with the new transferred quantity
            ---
            FOR L_idx IN L_xform.first..L_xform.last LOOP
               if L_xform(L_idx).from_item = REC_item.item then
                  L_xform(L_idx).from_qty := L_xform(L_idx).from_qty + REC_item.tsf_qty;
                  EXIT;
               end if;
            END LOOP;

            -- insert/accumulate 2nd-leg tsfdetail with L_to_item/REC_item.qty
            ---
            if INS_UPD_TSFDETAIL(O_error_message,
                                 I_2nd_leg_tsf_no,
                                 L_to_item,
                                 REC_item.tsf_qty,
                                 REC_item.reconciled_qty) = FALSE then
               return FALSE;
            end if;
            ---
         else   -- item hasn't been transformed
            ---
            -- insert/accumulate 2nd-leg tsfdetail with REC_item.item/REC_item.qty
            ---
            if INS_UPD_TSFDETAIL(O_error_message,
                                 I_2nd_leg_tsf_no,
                                 REC_item.item,
                                 REC_item.tsf_qty,
                                 REC_item.reconciled_qty) = FALSE then
               return FALSE;
            end if;
            ---
         end if;
         ---
      else  -- pack item
         ---
         FOR REC_comp IN C_comp_in_pack(REC_item.item) LOOP
            ---
            L_tsf_xform_detail_id := NULL;
            ---
            open C_xform_exist(REC_comp.item);
            fetch C_xform_exist into L_tsf_xform_detail_id,
                                     L_to_item;
            close C_xform_exist;
            ---
            if L_tsf_xform_detail_id is not null then  -- component item has been transformed
               ---
               -- insert/accumulate 2nd-leg tsfdetail with L_to_item/REC_item.qty * REC_comp.qty
               ---
               if INS_UPD_TSFDETAIL(O_error_message,
                                    I_2nd_leg_tsf_no,
                                    L_to_item,
                                    REC_item.tsf_qty * REC_comp.qty,
                                    REC_item.reconciled_qty) = FALSE then
                  return FALSE;
               end if;
               ---
               -- Accumulate transformed qty
               ---
               FOR L_idx IN L_xform.first..L_xform.last LOOP
                  if L_xform(L_idx).from_item = REC_comp.item then
                     L_xform(L_idx).from_qty := L_xform(L_idx).from_qty + REC_item.tsf_qty * REC_comp.qty;
                     EXIT;
                  end if;
               END LOOP;

            else   -- component hasn't been transformed
               ---
               -- insert/accumulate 2nd-leg tsfdetail with REC_comp.item/REC_item.qty * REC_comp.qty
               ---
               if INS_UPD_TSFDETAIL(O_error_message,
                                    I_2nd_leg_tsf_no,
                                    REC_comp.item,
                                    REC_item.tsf_qty * REC_comp.qty,
                                    REC_item.reconciled_qty) = FALSE then
                  return FALSE;
               end if;
               ---
            end if;
            ---
         END LOOP;
         ---
      end if;
      ---
      -- Update packing instruction for "from-item" with new qty
      ---
      L_table := 'TSF_PACKING_DETAIL';
      L_key1 := I_1st_leg_tsf_no;
      L_key2 := REC_item.item;
      ---
      L_rowid := NULL;
      ---
      open C_tpd_lock(REC_item.item, 'F');
      fetch C_tpd_lock into L_rowid;
      close C_tpd_lock;
      ---
      if REC_item.tsf_qty = 0 then
         delete from tsf_packing_detail
               where rowid = L_rowid;
      else
         update tsf_packing_detail
            set qty   = REC_item.tsf_qty
          where rowid = L_rowid;
      end if;
      ---
   END LOOP;
   ---
   FOR L_idx IN 1..L_xform.count LOOP
      ---
      L_table := 'TSF_XFORM_DETAIL';
      L_key1 := I_1st_leg_tsf_no;
      L_key2 := L_xform(L_idx).from_item;
      ---
      L_rowid := NULL;
      ---
      open C_txd_lock(L_xform(L_idx).from_item);
      fetch C_txd_lock into L_rowid;
      close C_txd_lock;
      ---
      if L_xform(L_idx).from_qty != 0 then
         update tsf_xform_detail
            set from_qty = L_xform(L_idx).from_qty,
                  to_qty = L_xform(L_idx).from_qty
          where rowid = L_rowid;
      else
         delete from tsf_xform_detail
          where rowid = L_rowid;
      end if;
      ---
   END LOOP;
   ---
   FOR REC_explode_pack IN C_explode_pack LOOP
      ---
      if REC_explode_pack.item is not null and REC_explode_pack.qty != 0 then
         ---
         if ITEM_XFORM_PACK_SQL.EXPLODE_PACK(O_error_message,
                                             REC_explode_pack.item,
                                             REC_explode_pack.tsf_packing_id,
                                             I_1st_leg_tsf_no,
                                             REC_explode_pack.qty) = FALSE then
            return FALSE;
         end if;
         ---
      elsif REC_explode_pack.qty = 0 then
         ---
         if ITEM_XFORM_PACK_SQL.DELETE_TSF_PACKING(O_error_message,
                                                   I_1st_leg_tsf_no,
                                                   REC_explode_pack.set_no) = FALSE then
            return FALSE;
         end if;
         ---
      end if;
      ---
   END LOOP;
   ---
   -- Step 3. For each built pack initially existing in the 1st-leg, re-estimate the possibility to rebuild it
   --         based on the newly created 2nd-leg.
   --         If the newly created 2nd-leg has all the required components and enought quantity for each component,
   --         rebuild it and update the 2nd-leg accordingly; Otherwise, remove the existing packing instruction.
   ---
   FOR REC_pack IN C_built_pack LOOP
      ---
      L_comp_not_exist := 'N';
      ---
      open C_comp_not_exist(REC_pack.item);
      fetch C_comp_not_exist into L_comp_not_exist;
      close C_comp_not_exist;
      ---
      if L_comp_not_exist = 'Y' then    -- the 2nd-leg does not have all required components
         ---
         -- delete the existing packing instruction
         ---
         if ITEM_XFORM_PACK_SQL.DELETE_TSF_PACKING(O_error_message,
                                                   I_1st_leg_tsf_no,
                                                   REC_pack.set_no) = FALSE then
            return FALSE;
         end if;
         ---
         L_pack_qty := 0;
         ---
      else  -- the 2nd-leg has all the required components to rebuild the pack
         ---
         -- Calculate the quantity of the pack which can be built
         ---
         L_pack_qty := 0;
         ---
         FOR REC_comp IN C_comp_for_pack(REC_pack.item) LOOP
            ---
            if REC_comp.pack_qty = 0 then  -- the component in 2nd-leg has no enough quantity to rebuild the pack
               ---
               -- delete the existing packing instruction
               ---
               if ITEM_XFORM_PACK_SQL.DELETE_TSF_PACKING(O_error_message,
                                                         I_1st_leg_tsf_no,
                                                         REC_pack.set_no) = FALSE then
                  return FALSE;
               end if;
               ---
               L_pack_qty := 0;
               EXIT;  --skip the current pack checking
               ---
            elsif L_pack_qty = 0 then
               L_pack_qty := REC_comp.pack_qty;    -- the qty can be packed based on the first component's tsf_qty
            elsif L_pack_qty > REC_comp.pack_qty then -- the component in 2nd-leg has enough quantity to rebuild the pack
               L_pack_qty := REC_comp.pack_qty;
            end if;
            ---
         END LOOP;
         ---
      end if;
      ---
      -- if the newly created 2nd-leg is eligible to rebuild the pack, rebuild it and update the 2nd-leg accordingly
      ---
      if L_pack_qty > 0 then
         ---
         -- For each component of pack being built, recalculate its left quantity after building
         -- and update the tsf_qty with left quantity on the 2nd-leg tsfdetail.
         ---
         FOR REC_comp_left IN C_calc_left_item(REC_pack.item) LOOP
            ---
            -- Update packing instruction of the from-item with the new tsf_qty
            ---
            L_table := 'TSFDETAIL';
            L_key2 := REC_comp_left.item;
            ---
            L_rowid := NULL;
            ---
            open C_tsfdetail_lock(REC_comp_left.item);
            fetch C_tsfdetail_lock into L_rowid;
            close C_tsfdetail_lock;
            ---
            if REC_comp_left.left_qty = 0 then  -- after rebuilding, the component has no quanity left
               ---
               delete from tsfdetail
                     where rowid = L_rowid;
               ---
            else
               update tsfdetail
                  set tsf_qty = REC_comp_left.left_qty
                where rowid = L_rowid;
               ---
            end if;
            ---
         END LOOP;
         ---
         -- insert the pack into 2nd-leg
         ---
         open C_get_seq_no;
         fetch C_get_seq_no into L_tsf_seq_no;
         close C_get_seq_no;
         ---
         if L_tsf_seq_no is null then
            L_tsf_seq_no := 1;
         end if;
         ---
         if ITEM_SUPP_COUNTRY_SQL.DEFAULT_PRIM_CASE_SIZE(O_error_message,
                                                         L_supp_pack_size,
                                                         L_inner_pack_size,
                                                         REC_pack.item) = FALSE then
            return FALSE;
         end if;
         ---
         insert into tsfdetail(tsf_no,
                               tsf_seq_no,
                               item,
                               tsf_qty,
                               supp_pack_size,
                               publish_ind)
                        values(I_2nd_leg_tsf_no,
                               L_tsf_seq_no,
                               REC_pack.item,
                               L_pack_qty,
                               L_supp_pack_size,
                               'N');
         ---
      end if;
      ---
   END LOOP;
   ---
   -- Step 4. Update packing instruction for built pack
   ---
   L_pack_qty := 0;
   ---
   FOR REC_pack IN C_built_pack LOOP
      ---
      L_packing.DELETE;
      ---
      open C_avail_comp(REC_pack.tsf_packing_id, REC_pack.item);
      fetch C_avail_comp BULK COLLECT into L_packing;
      close C_avail_comp;
      ---
      FOR L_idx IN 1..L_packing.count LOOP
         ---
         if L_packing(L_idx).pack_qty = 0 then
            ---
            if ITEM_XFORM_PACK_SQL.DELETE_TSF_PACKING(O_error_message,
                                                      I_1st_leg_tsf_no,
                                                      REC_pack.set_no) = FALSE then
               return FALSE;
            end if;
            ---
            L_pack_qty := 0;
            EXIT;  --skip the current pack checking
            ---
         elsif L_pack_qty = 0 then
            L_pack_qty := L_packing(L_idx).pack_qty;    -- the qty can be packed based on the first component's pack_qty
         elsif L_pack_qty > L_packing(L_idx).pack_qty then
            L_pack_qty := L_packing(L_idx).pack_qty;
         end if;
         ---
      END LOOP;
      ---
      if L_pack_qty > 0 then
         FOR L_idx IN 1..L_packing.count LOOP
            ---
            L_packing(L_idx).left_qty := L_packing(L_idx).avail_qty - L_packing(L_idx).comp_qty * L_pack_qty;
            ---
            L_table := 'TSF_PACKING_DETAIL';
            L_key1 := I_1st_leg_tsf_no;
            L_key2 := L_packing(L_idx).item;
            L_rowid := NULL;
            ---
            open C_tpd_to_lock(REC_pack.tsf_packing_id, L_packing(L_idx).item);
            fetch C_tpd_to_lock into L_rowid;
            close C_tpd_to_lock;
            ---
            if L_rowid is not NULL then  -- resultant component existed in initial packing instructions
               ---
               if L_packing(L_idx).left_qty != 0 then
                  update tsf_packing_detail
                     set qty = L_packing(L_idx).left_qty
                   where rowid = L_rowid;
               else
                  delete from tsf_packing_detail
                        where rowid = L_rowid;
               end if;
               ---
            else  -- resulatnt component didn't exist in initial packing instructions
               ---
               if L_packing(L_idx).left_qty != 0 then  -- New packing may have leftover components
                  ---
                  if ITEM_XFORM_PACK_SQL.NEXT_PACKING_DETAIL_ID(O_error_message,
                                                                L_return_code,
                                                                L_packing_detail_id) = FALSE
                                                             or L_return_code = FALSE then
                     return FALSE;
                  end if;
                  ---
                  insert into tsf_packing_detail(tsf_packing_detail_id,
                                                 tsf_packing_id,
                                                 record_type,
                                                 item,
                                                 qty)
                                          values(L_packing_detail_id,
                                                 REC_pack.tsf_packing_id,
                                                 'R',
                                                 L_packing(L_idx).item,
                                                 L_packing(L_idx).left_qty);
                  ---
               end if;
               ---
            end if;
            ---
         END LOOP;
         ---
         L_key2 := REC_pack.item;
         L_rowid := NULL;
         ---
         open C_tpd_to_lock(REC_pack.tsf_packing_id, REC_pack.item);
         fetch C_tpd_to_lock into L_rowid;
         close C_tpd_to_lock;
         ---
         update tsf_packing_detail
            set qty = L_pack_qty
          where rowid = L_rowid;
         ---
      end if;
      ---
      -- if transfer is a pack to pack transfer, copy resultant quantity
      L_to_pack_qty := 0;
      open C_pack_to_pack(REC_pack.tsf_packing_id, REC_pack.item);
      fetch C_pack_to_pack into L_to_pack_qty,
                                L_from_item;
      close C_pack_to_pack;
      if L_to_pack_qty != 0 then
         L_key2 := REC_pack.item;
         L_rowid := NULL;
         open C_tpd_pack_to_lock(REC_pack.tsf_packing_id, REC_pack.item);
         fetch C_tpd_pack_to_lock into L_rowid;
         close C_tpd_pack_to_lock;
         ---
         update tsf_packing_detail
            set qty = L_to_pack_qty
          where rowid = L_rowid;
      end if;
      -- Update packing instruction for "from-item" with new qty
      ---
      FOR L_idx IN 1..L_packing.count LOOP
         ---
         L_key2 := L_packing(L_idx).item;
         ---
         L_rowid := NULL;
         ---
         open C_tpd_lock(L_packing(L_idx).item, 'F');
         fetch C_tpd_lock into L_rowid;
         close C_tpd_lock;
         ---
         if L_rowid is NOT NULL then
            update tsf_packing_detail
               set qty = L_packing(L_idx).avail_qty
             where rowid = L_rowid;
         end if;
         ---
      END LOOP;
      ---
   END LOOP;
   ---

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_key1,
                                             L_key2);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;

END REBUILD_2ND_LEG_DETAIL;
----------------------------------------------------------------------------------------------

FUNCTION CLOSE_TSF(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                   O_closed         IN OUT BOOLEAN,
                   I_tsf_no         IN     APPT_DETAIL.DOC%TYPE)
RETURN BOOLEAN IS

   L_function                 VARCHAR2(50) := 'APPT_DOC_CLOSE_SQL.CLOSE_TSF';

   L_table                    VARCHAR2(30);
   L_key1                     VARCHAR2(100);
   L_key2                     VARCHAR2(100);
   RECORD_LOCKED              EXCEPTION;
   PRAGMA                     EXCEPTION_INIT(RECORD_LOCKED, -54);

   L_shipping_shortage_ind    BOOLEAN;
   L_shipping_overage_ind     VARCHAR2(1) := 'N';
   L_reconcile_pending_ind    VARCHAR2(1) := 'N';
   --
   L_reconcile_pending2_ind   VARCHAR2(1) := 'N'; -- used for simple pack component items
   L_reconcile_pending3_ind   VARCHAR2(1) := 'N'; -- used for comparing tsf_qty and ship_qty
   L_item                     ITEM_LOC_SOH.ITEM%TYPE;
   L_remaining_qty            ITEM_LOC_SOH.IN_TRANSIT_QTY%TYPE;
   L_remaining_weight         ITEM_LOC_SOH.PACK_COMP_INTRAN%TYPE;
   ---
   L_tsf_parent_no            TSFHEAD.TSF_PARENT_NO%TYPE;
   L_1st_leg_status           TSFHEAD.STATUS%TYPE;
   L_2nd_leg_status           TSFHEAD.STATUS%TYPE;
   L_1st_leg_recon_ind        VARCHAR2(1) := 'N';
   L_finisher_loc_ind         VARCHAR2(1);
   L_finisher_entity_ind      VARCHAR2(1);
   L_2nd_leg_tsf_no           TSFHEAD.TSF_NO%TYPE;
   L_1st_leg_adjust_type      SHIPSKU.ADJUST_TYPE%TYPE;

   cursor C_check_ship_qtys is
      select 'Y'
        from shipsku s
       where s.distro_no = I_tsf_no
         and (NVL(s.qty_expected, 0) - NVL(s.qty_received, 0)) <> 0
         and (s.adjust_type is null or s.adjust_type = 'RE')
         and rownum = 1;

   cursor C_check_ship_weights is
      select 'Y'
        from shipsku s,
             item_master im
       where s.distro_no = I_tsf_no
         and (NVL(s.weight_expected, 0) - NVL(s.weight_received, 0)) <> 0
         and (adjust_type is null or adjust_type = 'RE')
         and im.item = s.item
         and im.catch_weight_ind = 'Y'
         and im.simple_pack_ind = 'Y'
         and rownum = 1;

   cursor c_get_item_ship_loc is
      select s.item,
             (NVL(s.qty_expected, 0) - NVL(s.qty_received, 0)) remaining_qty
        from shipsku s,
             shipment ship
       where s.distro_no = I_tsf_no
         and (NVL(s.qty_expected, 0) - NVL(s.qty_received, 0)) <> 0
         and (s.adjust_type is null or s.adjust_type = 'RE')
         and ship.shipment = s.shipment;

   cursor c_get_cw_item_ship_loc is
      select s.item,
             (NVL(s.weight_expected, 0) - NVL(s.weight_received, 0)) remaining_weight
        from shipsku s,
             shipment ship
       where s.distro_no = I_tsf_no
         and (NVL(s.weight_expected, 0) - NVL(s.weight_received, 0)) <> 0
         and (s.adjust_type is null or s.adjust_type = 'RE')
         and ship.shipment = s.shipment;

   cursor C_lock_tsfhead is
      select 'x'
        from tsfhead
       where tsf_no = I_tsf_no
         for update nowait;

   cursor C_get_tsf_parent_no is
      select nvl(tsf_parent_no, -1)
        from tsfhead
       where tsf_no = I_tsf_no;

   cursor C_get_tsf_status(cv_tsf_no  tsfhead.tsf_no%type) is
      select status
        from tsfhead
       where tsf_no = cv_tsf_no;

   cursor C_1st_leg_recon is
      select adjust_type
        from shipsku
       where distro_type = 'T'
         and distro_no = I_tsf_no
         and adjust_type is not null;

   cursor C_item_over_ship is
      select 'Y'
        from tsfdetail
       where tsf_no = I_tsf_no
         and (tsf_qty - NVL(cancelled_qty, 0)) < NVL(ship_qty, 0);

   cursor C_CHECK_TSF_REC_QTYS is
      select 'X'
        from tsfdetail
       where tsf_no = I_tsf_no
         and NVL(tsf_qty, 0) > NVL(ship_qty, 0)
         and rownum = 1;
BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_function,
                                             NULL);
      return FALSE;
   end if;
   ---
   open C_get_tsf_parent_no;
   fetch C_get_tsf_parent_no into L_tsf_parent_no;
   close C_get_tsf_parent_no;
   ---
   if L_tsf_parent_no != -1 then   -- the transfer is the 2nd-leg tsf
      ---
      open C_get_tsf_status(L_tsf_parent_no);
      fetch C_get_tsf_status into L_1st_leg_status;
      close C_get_tsf_status;
      ---
      if L_1st_leg_status != 'C' then  -- 1st-leg hasn't been closed
         ---
         O_closed := FALSE;
         return TRUE;
         ---
      else   -- the 1st-leg has been closed
         ---
         if TRANSFER_SQL.UPD_QTYS_WHEN_CLOSE(O_error_message,
                                             L_shipping_shortage_ind,
                                             '2', --process 2nd leg only
                                             L_tsf_parent_no) = FALSE then
            return FALSE;
         end if;
         ---
         -- close 2nd-leg
         ---
         open C_LOCK_TSFHEAD;
         close C_LOCK_TSFHEAD;
         ---
         L_table := 'TSFHEAD';
         L_key1 := I_tsf_no;
         L_key2 := NULL;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'TSFHEAD','TSF_NO:'||I_tsf_no);
         update tsfhead
            set status = 'C',
                close_date = get_vdate
          where tsf_no = I_tsf_no;
         ---
         O_closed := TRUE;
         ---
      end if;
      ---
   else  -- the input transfer is a regular tsf or the 1st-leg tsf
      ---
      -- Reconcile check for Non-catch_weight simple pack component items
      --
      open C_check_ship_qtys;
      fetch C_check_ship_qtys into L_reconcile_pending_ind;
      close C_check_ship_qtys;

      -- Reconcile check for Catch_weight simple pack component items
      --
      open C_check_ship_weights;
      fetch C_check_ship_weights into L_reconcile_pending2_ind;
      close C_check_ship_weights;
      --

      open C_check_tsf_rec_qtys;
      fetch C_check_tsf_rec_qtys into L_reconcile_pending3_ind;
      close C_check_tsf_rec_qtys;

      if L_reconcile_pending_ind = 'Y' or L_reconcile_pending3_ind = 'X' then  -- shortage/overage exists in 1st-leg and not yet reconcile
         O_closed := FALSE;
      else
         ---
         open C_lock_tsfhead;
         close C_lock_tsfhead;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'TSFHEAD','TSF_NO:'||I_tsf_no);
         L_table := 'TSFHEAD';
         L_key1 := I_tsf_no;
         L_key2 := NULL;
         ---
         update tsfhead
            set status = 'C',
                close_date = get_vdate
          where tsf_no = I_tsf_no;
         ---
         O_closed := TRUE;
         ---
         -- update tsf_reserved_qty of from loc and tsf_expected_qty of to loc for short shipped quantity
         ---
         if TRANSFER_SQL.UPD_QTYS_WHEN_CLOSE(O_error_message,
                                             L_shipping_shortage_ind,
                                             '1', --process 1st leg only
                                             I_tsf_no) = FALSE then
            return FALSE;
         end if;
         ---
         open C_1st_leg_recon;
         fetch C_1st_leg_recon into L_1st_leg_adjust_type;
         close C_1st_leg_recon;
         ---
         -- check whether the shipping overage exists
         ---
         open C_item_over_ship;
         fetch C_item_over_ship into L_shipping_overage_ind;
         close C_item_over_ship;
         ---
         if L_shipping_shortage_ind = TRUE
            or L_shipping_overage_ind = 'Y'
            or (L_1st_leg_adjust_type in ('FC','SL','RL')) then
            ---
             if TRANSFER_SQL.GET_FINISHER_INFO(O_error_message,
                                              L_finisher_loc_ind,
                                              L_finisher_entity_ind,
                                              I_tsf_no) = FALSE then
               return FALSE;
            end if;
            ---
            if L_finisher_entity_ind is not NULL then   -- the transfer is the 1st-leg
               ---
               if TRANSFER_SQL.GET_CHILD_TSF(O_error_message,
                                              L_2nd_leg_tsf_no,
                                              I_tsf_no) = FALSE then
                  return FALSE;
               end if;
               ---
               open C_get_tsf_status(L_2nd_leg_tsf_no);
               fetch C_get_tsf_status into L_2nd_leg_status;
               close C_get_tsf_status;
               ---
               if L_2nd_leg_status = 'A' then
                  ---
                  if REBUILD_2ND_LEG_DETAIL(O_error_message,
                                            I_tsf_no,
                                            L_2nd_leg_tsf_no) = FALSE then
                     return FALSE;
                  end if;
                  ---
               end if;
               ---
            end if;
            ---
         end if;
         ---
      end if;

   end if;
   ---

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_key1,
                                             L_key2);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;

END CLOSE_TSF;
----------------------------------------------------------------------------------------------
FUNCTION CLOSE_ALLOC(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     O_closed         IN OUT BOOLEAN,
                     I_alloc          IN     APPT_DETAIL.DOC%TYPE)
RETURN BOOLEAN IS
   L_function     VARCHAR2(50) := 'APPT_DOC_CLOSE_SQL.CLOSE_ALLOC';
   L_flag         VARCHAR2(1)  := NULL;
   L_rowid        ROWID;
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);
   ---

   cursor C_CHECK_SHIP_QTYS is
      select 'x'
        from shipsku s,
             item_master im
       where s.distro_no = I_alloc
         and (NVL(s.qty_expected, 0) - NVL(s.qty_received, 0)) <> 0
         and (s.adjust_type is null or s.adjust_type = 'RE')
         and im.item = s.item
         and rownum = 1;

   cursor C_CHECK_SHIP_WEIGHTS is
      select 'x'
        from shipsku s,
             item_master im
       where s.distro_no = I_alloc
         and (NVL(s.weight_expected, 0) - NVL(s.weight_received, 0)) <> 0
         and (adjust_type is null or adjust_type = 'RE')
         and im.item = s.item
         and im.catch_weight_ind = 'Y'
         and im.simple_pack_ind = 'Y'
         and rownum = 1;

   cursor C_CHECK_ALLOC_REC_QTYS is
      select 'x'
        from alloc_detail
       where alloc_no = I_alloc
         and NVL(qty_allocated, 0) > NVL(qty_transferred, 0)
         and NVL(qty_allocated, 0) > NVL(qty_received, 0)
         and rownum = 1;

   cursor C_LOCK_ALLOC_HEADER is
      select rowid
        from alloc_header
       where alloc_no = I_alloc
         for update nowait;


BEGIN
   O_closed := FALSE;

   SQL_LIB.SET_MARK('OPEN','C_CHECK_SHIP_QTYS','SHIPSKU',NULL);
   open C_CHECK_SHIP_QTYS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_SHIP_QTYS','SHIPSKU',NULL);
   fetch C_CHECK_SHIP_QTYS into L_flag;
   ---
   if C_CHECK_SHIP_QTYS%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_SHIP_QTYS','SHIPSKU',NULL);
      close C_CHECK_SHIP_QTYS;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_SHIP_QTYS','SHIPSKU',NULL);
   close C_CHECK_SHIP_QTYS;


   SQL_LIB.SET_MARK('OPEN','C_CHECK_SHIP_WEIGHTS','SHIPSKU',NULL);
   open C_CHECK_SHIP_WEIGHTS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_SHIP_WEIGHTS','SHIPSKU',NULL);
   fetch C_CHECK_SHIP_WEIGHTS into L_flag;
   ---
   if C_CHECK_SHIP_WEIGHTS%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_SHIP_WEIGHTS','SHIPSKU',NULL);
      close C_CHECK_SHIP_WEIGHTS;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_SHIP_WEIGHTS','SHIPSKU',NULL);
   close C_CHECK_SHIP_WEIGHTS;


   SQL_LIB.SET_MARK('OPEN','C_CHECK_ALLOC_REC_QTYS','ALLOC_DETAIL',NULL);
   open C_CHECK_ALLOC_REC_QTYS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ALLOC_REC_QTYS','ALLOC_DETAIL',NULL);
   fetch C_CHECK_ALLOC_REC_QTYS into L_flag;
   ---
   if C_CHECK_ALLOC_REC_QTYS%FOUND then
      SQL_LIB.SET_MARK('CLOSE','C_CHECK_ALLOC_REC_QTYS','ALLOC_DETAIL',NULL);
      close C_CHECK_ALLOC_REC_QTYS;
      return TRUE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ALLOC_REC_QTYS','ALLOC_DETAIL',NULL);
   close C_CHECK_ALLOC_REC_QTYS;

   SQL_LIB.SET_MARK('UPDATE',NULL,'ALLOC_HEADER','ALLOC_NO:'||I_alloc);
   open C_LOCK_ALLOC_HEADER;
   fetch C_LOCK_ALLOC_HEADER into L_rowid;
   close C_LOCK_ALLOC_HEADER;
   update alloc_header
      set status = 'C'
    where rowid  = L_rowid;

   O_closed := TRUE;
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED_MODULE',
                                             'ALLOC_HEADER',
                                             'Alloc.: '||to_char(I_alloc),
                                             L_function);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;

END CLOSE_ALLOC;
----------------------------------------------------------------------------------------------
FUNCTION CLOSE_DOC(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                   O_closed         IN OUT BOOLEAN,
                   I_appt_head      IN     APPT_HEAD%ROWTYPE)
RETURN BOOLEAN IS
   L_function VARCHAR2(50) := 'APPT_DOC_CLOSE_SQL.CLOSE_DOC';
   L_open     BOOLEAN      := FALSE;
   ---
   cursor C_FETCH_DOCS is
      select doc_type, doc
        from appt_detail
       where appt = I_appt_head.appt;

BEGIN
   FOR rec in C_FETCH_DOCS LOOP

      if CHECK_OPEN_APPTS(O_error_message,
                          L_open,
                          rec.doc,
                          rec.doc_type) = FALSE then
         return FALSE;
      end if;
      ---
      if not L_open then
         if rec.doc_type = 'P' then
            if CLOSE_PO(O_error_message,
                        O_closed,
                        rec.doc) = FALSE then
               return FALSE;
            end if;
         elsif rec.doc_type = 'T' then
            if CLOSE_TSF(O_error_message,
                         O_closed,
                         rec.doc) = FALSE then
               return FALSE;
            end if;
         elsif rec.doc_type = 'A' then
            if CLOSE_ALLOC(O_error_message,
                           O_closed,
                           rec.doc) = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
   END LOOP;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;

END CLOSE_DOC;
----------------------------------------------------------------------------------------------
FUNCTION CLOSE_ALL_ALLOCS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE)
RETURN BOOLEAN IS

   TYPE ROWID_TBL is table of ROWID;

   L_function     VARCHAR2(50) := 'APPT_DOC_CLOSE_SQL.CLOSE_ALL_ALLOCS';

   L_rowids       ROWID_TBL;
   L_alloc_no1    ALLOC_NO_TBL;
   L_alloc_no2    ALLOC_NO_TBL;

   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_CHECK_SHIP_QTYS is
     select dcq.doc
       from doc_close_queue_temp dcq
      where dcq.doc_type = 'A'
        and not exists (select /*+ first_rows(1) */ 'x'
                          from shipsku
                         where distro_no = dcq.doc
                           and NVL(qty_expected, 0) != NVL(qty_received,0)
                           and NVL(adjust_type, 'RE') = 'RE'
                           and rownum = 1);

   cursor C_CHECK_ALLOC_REC_QTYS is
     select /*+ CARDINALITY(I 100) */ ah.alloc_no, ah.rowid
       from TABLE(CAST(L_alloc_no1 as ALLOC_NO_TBL)) i,
            alloc_header ah
      where ah.alloc_no = value(i)
        and not exists (select /*+ first_rows(1) */ 'x'
                          from alloc_detail ad
                         where ad.alloc_no = ah.alloc_no
                           and ad.qty_allocated > NVL(ad.qty_transferred, 0)
                           and ad.qty_allocated > NVL(ad.qty_received, 0)
                           and rownum = 1)
        for update of ah.status nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN', 'C_CHECK_SHIP_QTYS', 'SHIPSKU', NULL);
   open  C_CHECK_SHIP_QTYS;

   loop
      SQL_LIB.SET_MARK('FETCH', 'C_CHECK_SHIP_QTYS', 'SHIPSKU', NULL);
      fetch C_CHECK_SHIP_QTYS BULK COLLECT INTO L_alloc_no1 LIMIT 100;

      if ( L_alloc_no1.COUNT > 0 ) then
         SQL_LIB.SET_MARK('OPEN', 'C_CHECK_ALLOC_REC_QTYS', 'ALLOC_DETAIL', NULL);
         open  C_CHECK_ALLOC_REC_QTYS;
         fetch C_CHECK_ALLOC_REC_QTYS BULK COLLECT INTO L_alloc_no2, L_rowids;
         close C_CHECK_ALLOC_REC_QTYS;

         SQL_LIB.SET_MARK('UPDATE', NULL, 'ALLOC_HEADER', NULL);
         forall i in 1..L_rowids.count
            update alloc_header
               set status = 'C'
             where ROWID = L_rowids(i);

         SQL_LIB.SET_MARK('DELETE', NULL, 'DOC_CLOSE_QUEUE', NULL);
         forall i in 1..L_alloc_no2.count
            delete doc_close_queue
             where doc_type = 'A'
               and doc = L_alloc_no2(i);
      end if;

      exit when C_CHECK_SHIP_QTYS%NOTFOUND;
   end loop;

   SQL_LIB.SET_MARK('CLOSE', 'C_CHECK_SHIP_QTYS', 'SHIPSKU', NULL);
   close C_CHECK_SHIP_QTYS;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('RECORD_LOCKED_MODULE',
                                             'ALLOC_HEADER',
                                             NULL,
                                             L_function);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_function,
                                             to_char(SQLCODE));
      return FALSE;

END CLOSE_ALL_ALLOCS;
----------------------------------------------------------------------------------------------
END APPT_DOC_CLOSE_SQL;
/

