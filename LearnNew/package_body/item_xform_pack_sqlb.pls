CREATE OR REPLACE PACKAGE BODY ITEM_XFORM_PACK_SQL AS
---------------------------------------------------------------------------------------
FUNCTION NEXT_XFORM_ID(O_error_message    IN OUT VARCHAR2,
                       O_return_code      IN OUT BOOLEAN,
                       O_tsf_xform_id     IN OUT TSF_XFORM.TSF_XFORM_ID%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.NEXT_XFORM_ID';

   L_tsf_xform_id         TSF_XFORM.TSF_XFORM_ID%TYPE;
   L_wrap_seq_no          TSF_XFORM.TSF_XFORM_ID%TYPE;
   L_first_time           VARCHAR2(3) := 'Yes';
   L_dummy                VARCHAR2(1);

   cursor C_tsf_xform_id_exist(cv_tsf_xform_id   TSF_XFORM.TSF_XFORM_ID%TYPE)   is
      select 'x'
        from tsf_xform
       where tsf_xform_id = cv_tsf_xform_id;

BEGIN
   ---
   LOOP
      ---
      select TSF_XFORM_ID_SEQUENCE.nextval
        into L_tsf_xform_id
        from dual;
      ---
      if L_first_time = 'Yes' then
         L_wrap_seq_no := L_tsf_xform_id;
         L_first_time := 'No';
      elsif (L_tsf_xform_id = L_wrap_seq_no) then
         O_error_message := 'Fatal error - no available tsf_xform_id';
         O_return_code := FALSE;
         EXIT;
      end if;
      ---
      O_tsf_xform_id := L_tsf_xform_id;
      ---
      open C_tsf_xform_id_exist(O_tsf_xform_id);
      fetch C_tsf_xform_id_exist into L_dummy;
      ---
      if C_tsf_xform_id_exist%NOTFOUND then
         ---
         O_return_code := TRUE;
         close C_tsf_xform_id_exist;
         EXIT;
         ---
      end if;
      ---
      close C_tsf_xform_id_exist;
      ---
   END LOOP;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END NEXT_XFORM_ID;
---------------------------------------------------------------------------------------
FUNCTION NEXT_XFORM_DETAIL_ID(O_error_message         IN OUT VARCHAR2,
                              O_return_code           IN OUT BOOLEAN,
                              O_tsf_xform_detail_id   IN OUT TSF_XFORM_DETAIL.TSF_XFORM_DETAIL_ID%TYPE)
RETURN BOOLEAN IS
   L_program                VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.NEXT_XFORM_DETAIL_ID';

   L_tsf_xform_detail_id    TSF_XFORM_DETAIL.TSF_XFORM_DETAIL_ID%TYPE;
   L_wrap_seq_no            TSF_XFORM_DETAIL.TSF_XFORM_DETAIL_ID%TYPE;
   L_first_time             VARCHAR2(3) := 'Yes';
   L_dummy                  VARCHAR2(1);

   cursor C_tsf_xform_detail_id_exist(cv_tsf_xform_detail_id   TSF_XFORM_DETAIL.TSF_XFORM_DETAIL_ID%TYPE)   is
      select 'x'
        from tsf_xform_detail
       where tsf_xform_detail_id = cv_tsf_xform_detail_id;

BEGIN
   ---
   LOOP
      ---
      select TSF_XFORM_DETAIL_ID_SEQUENCE.nextval
        into L_tsf_xform_detail_id
        from dual;
      ---
      if L_first_time = 'Yes' then
         L_wrap_seq_no := L_tsf_xform_detail_id;
         L_first_time := 'No';
      elsif (L_tsf_xform_detail_id = L_wrap_seq_no) then
         O_error_message := 'Fatal error - no available tsf_xform_detail_id';
         O_return_code := FALSE;
         EXIT;
      end if;
      ---
      O_tsf_xform_detail_id := L_tsf_xform_detail_id;
      ---
      open C_tsf_xform_detail_id_exist(O_tsf_xform_detail_id);
      fetch C_tsf_xform_detail_id_exist into L_dummy;
      ---
      if C_tsf_xform_detail_id_exist%NOTFOUND then
         ---
         O_return_code := TRUE;
         close C_tsf_xform_detail_id_exist;
         EXIT;
         ---
      end if;
      ---
      close C_tsf_xform_detail_id_exist;
      ---
   END LOOP;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END NEXT_XFORM_DETAIL_ID;
----------------------------------------------------------------------------------------
FUNCTION NEXT_PACKING_ID(O_error_message    IN OUT VARCHAR2,
                         O_return_code      IN OUT BOOLEAN,
                         O_tsf_packing_id   IN OUT TSF_PACKING.TSF_PACKING_ID%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.NEXT_PACKING_ID';

   L_tsf_packing_id       TSF_PACKING.TSF_PACKING_ID%TYPE;
   L_wrap_seq_no          TSF_PACKING.TSF_PACKING_ID%TYPE;
   L_first_time           VARCHAR2(3) := 'Yes';
   L_dummy                VARCHAR2(1);

   cursor C_tsf_packing_id_exist(cv_tsf_packing_id   TSF_PACKING.TSF_PACKING_ID%TYPE)   is
      select 'x'
        from tsf_packing
       where tsf_packing_id = cv_tsf_packing_id;

BEGIN
   ---
   LOOP
      ---
      select TSF_PACKING_ID_SEQUENCE.nextval
        into L_tsf_packing_id
        from dual;
      ---
      if L_first_time = 'Yes' then
         L_wrap_seq_no := L_tsf_packing_id;
         L_first_time := 'No';
      elsif (L_tsf_packing_id = L_wrap_seq_no) then
         O_error_message := 'Fatal error - no available tsf_packing_id';
         O_return_code := FALSE;
         EXIT;
      end if;
      ---
      O_tsf_packing_id := L_tsf_packing_id;
      ---
      open C_tsf_packing_id_exist(O_tsf_packing_id);
      fetch C_tsf_packing_id_exist into L_dummy;
      ---
      if C_tsf_packing_id_exist%NOTFOUND then
         ---
         O_return_code := TRUE;
         close C_tsf_packing_id_exist;
         EXIT;
         ---
      end if;
      ---
      close C_tsf_packing_id_exist;
      ---
   END LOOP;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END NEXT_PACKING_ID;
----------------------------------------------------------------------------------------
FUNCTION NEXT_PACK_SET_NO(O_error_message  IN OUT VARCHAR2,
                          O_set_no         IN OUT TSF_PACKING.SET_NO%TYPE,
                          I_tsf_no         IN     TSF_PACKING.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.NEXT_PACK_SET_NO';

   cursor C_create_set_no is
      select nvl(max(set_no),0) + 1
        from tsf_packing
       where tsf_no = I_tsf_no;

BEGIN
   ---
   open C_create_set_no;
   fetch C_create_set_no into O_set_no;
   close C_create_set_no;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END NEXT_PACK_SET_NO;
----------------------------------------------------------------------------------------
FUNCTION NEXT_PACKING_DETAIL_ID(O_error_message           IN OUT VARCHAR2,
                                O_return_code             IN OUT BOOLEAN,
                                O_tsf_packing_detail_id   IN OUT TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.NEXT_PACKING_DETAIL_ID';

   L_tsf_packing_detail_id       TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE;
   L_wrap_seq_no                 TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE;
   L_first_time                  VARCHAR2(3) := 'Yes';
   L_dummy                       VARCHAR2(1);

   cursor C_tsf_packing_detail_id_exist(cv_tsf_packing_detail_id   TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE)   is
      select 'x'
        from tsf_packing_detail
       where tsf_packing_detail_id = cv_tsf_packing_detail_id;

BEGIN
   ---
   LOOP
      ---
      select TSF_PACKING_DETAIL_ID_SEQUENCE.nextval
        into L_tsf_packing_detail_id
        from dual;
      ---
      if L_first_time = 'Yes' then
         L_wrap_seq_no := L_tsf_packing_detail_id;
         L_first_time := 'No';
      elsif (L_tsf_packing_detail_id = L_wrap_seq_no) then
         O_error_message := 'Fatal error - no available tsf_packing_detail_id';
         O_return_code := FALSE;
         EXIT;
      end if;
      ---

      O_tsf_packing_detail_id := L_tsf_packing_detail_id;

      ---
      open C_tsf_packing_detail_id_exist(O_tsf_packing_detail_id);
      fetch C_tsf_packing_detail_id_exist into L_dummy;
      ---
      if C_tsf_packing_detail_id_exist%NOTFOUND then
         ---
         O_return_code := TRUE;
         close C_tsf_packing_detail_id_exist;
         EXIT;
         ---
      end if;
      ---
      close C_tsf_packing_detail_id_exist;
      ---
   END LOOP;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END NEXT_PACKING_DETAIL_ID;
---------------------------------------------------------------------------------------
FUNCTION VALID_XFORM_ITEM(O_error_message   IN OUT VARCHAR2,
                          O_valid           IN OUT BOOLEAN,
                          O_item_desc       IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                          O_qty             IN OUT TSFDETAIL.TSF_QTY%TYPE,
                          I_tsf_no          IN     TSFDETAIL.TSF_NO%TYPE,
                          I_item            IN     TSFDETAIL.ITEM%TYPE,
                          I_diff_id         IN     TSF_XFORM_REQUEST.DIFF_ID%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.VALID_XFORM_ITEM';
   L_exist                VARCHAR2(1) := 'N';
   L_from_qty             tsf_xform_detail.from_qty%type;
   L_item_master          ITEM_MASTER%ROWTYPE;

   cursor C_valid_item is
      select im.item_desc,
             avl.qty
        from v_tsf_xform_avail avl,
             item_master im
       where avl.item = im.item
         and avl.tsf_no = I_tsf_no
         and avl.item = I_item
         and not exists (select 'x'
                           from tsf_xform_detail_temp
                          where tsf_no = I_tsf_no
                            and from_item = I_item)
         and not exists (select 'x'
                           from tsf_xform_request
                          where tsf_no = I_tsf_no
                            and item = I_item
                            and nvl(diff_id, '-1') = nvl(I_diff_id, '-1')
                            and record_type = 'F');

   cursor C_parent_diff_qty is
      select sum(t.tsf_qty) qty
        from tsfdetail t,
             item_master im
       where t.item = im.item
         and im.item_parent = I_item
         and t.tsf_no = I_tsf_no
         and (I_diff_id is null
              or (I_diff_id is not null and (im.diff_1 = I_diff_id
                                             or im.diff_2 = I_diff_id
                                             or im.diff_3 = I_diff_id
                                             or im.diff_4 = I_diff_id)))
         and not exists (select 'x'
                           from tsf_xform tx,
                                tsf_xform_detail txd
                          where tx.tsf_xform_id = txd.tsf_xform_id
                            and tx.tsf_no = I_tsf_no
                            and txd.from_item = t.item)
         and not exists (select 'x'
                           from tsf_packing tp,
                                tsf_packing_detail tpd
                          where tp.tsf_packing_id = tpd.tsf_packing_id
                            and tp.tsf_no = I_tsf_no
                            and tpd.item = t.item
                            and tpd.record_type = 'F')
         and not exists (select 'x'
                           from tsf_xform_detail_temp
                          where tsf_no = I_tsf_no
                            and from_item = t.item)
         and not exists (select 'x'
                           from tsf_xform_request
                          where tsf_no = I_tsf_no
                            and item = t.item
                            and record_type = 'F')
       union all
      select sum(t.tsf_qty * v.qty) qty
        from tsfdetail t,
             item_master im,
             v_packsku_qty v
       where t.tsf_no = I_tsf_no
         and v.pack_no = t.item
         and im.item = v.item
         and im.item_parent = I_item
         and (I_diff_id is null
              or (I_diff_id is not null and (im.diff_1 = I_diff_id
                                             or im.diff_2 = I_diff_id
                                             or im.diff_3 = I_diff_id
                                             or im.diff_4 = I_diff_id)))
         and not exists (select 'x'
                           from tsf_xform tx,
                                tsf_xform_detail txd
                          where tx.tsf_xform_id = txd.tsf_xform_id
                            and tx.tsf_no = I_tsf_no
                            and txd.from_item = v.item)
         and not exists (select 'x'
                           from tsf_packing tp,
                                tsf_packing_detail tpd
                          where tp.tsf_packing_id = tpd.tsf_packing_id
                            and tp.tsf_no = I_tsf_no
                            and tpd.item = v.item
                            and tpd.record_type = 'F')
         and not exists (select 'x'
                           from tsf_xform_detail_temp
                          where tsf_no = I_tsf_no
                            and from_item = v.item)
         and not exists (select 'x'
                           from tsf_xform_request
                          where tsf_no = I_tsf_no
                            and item = v.item
                            and record_type = 'F');

   cursor C_request_exist is
      select 'Y'
        from tsf_xform_request
       where tsf_no = I_tsf_no
         and record_type = 'F'
         and item = I_item
         and nvl(diff_id, '-1') = nvl(I_diff_id, '-1');

   cursor C_xfm_packing_item is
      select 'Y'
        from tsf_xform tx,
             tsf_xform_detail txd
       where tx.tsf_xform_id = txd.tsf_xform_id
         and tx.tsf_no = I_tsf_no
         and txd.from_item = I_item
       union all
      select 'Y'
        from tsf_xform_detail_temp
       where tsf_no = I_tsf_no
         and from_item = I_item
       union all
      select 'Y'
        from tsf_packing tp,
             tsf_packing_detail tpd,
             v_packsku_qty vpq
       where tp.tsf_packing_id = tpd.tsf_packing_id
         and tp.tsf_no = I_tsf_no
         and vpq.pack_no = tpd.item
         and vpq.item = I_item
         and tpd.record_type = 'F'
       union all
      select 'Y'
        from tsf_packing tp,
             tsf_packing_detail tpd
       where tp.tsf_packing_id = tpd.tsf_packing_id
         and tp.tsf_no = I_tsf_no
         and tpd.item = I_item
         and tpd.record_type = 'F';
BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   open C_valid_item;
   fetch C_valid_item into O_item_desc,
                           O_qty;
   ---
   if C_valid_item%NOTFOUND then
      O_valid := FALSE;
   else
      O_valid := TRUE;
   end if;
   ---
   close C_valid_item;
   ---
   if O_valid = FALSE then
      ---
      open C_request_exist;
      fetch C_request_exist into L_exist;
      close C_request_exist;
      ---
      if L_exist = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('XFORM_DUP_REQ',
                                               I_item,
                                               NULL,
                                               NULL);
         return FALSE;
      else
         ---
         open C_xfm_packing_item;
         fetch C_xfm_packing_item into L_exist;
         close C_xfm_packing_item;
         ---
         if L_exist = 'Y' then
            O_error_message := SQL_LIB.CREATE_MSG('ITEM_XFORM_PACK',
                                                  I_item,
                                                  NULL,
                                                  NULL);
            return FALSE;
         else
            O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_XFORM',
                                                  I_item,
                                                  NULL,
                                                  NULL);
            return FALSE;
         end if;
         ---
      end if;
      ---
   else
      ---
      -- if a parent item, recalculate the qty if diff_id is not null
      ---
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_master,
                                         I_item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_item_master.item_level != L_item_master.tran_level then
         ---
         L_from_qty := 0;
         ---
         FOR REC_children IN C_parent_diff_qty LOOP
            L_from_qty := L_from_qty + nvl(REC_children.qty,0);
         END LOOP;
         ---
         O_qty := L_from_qty;
         ---
         if O_qty = 0 then
            O_error_message := SQL_LIB.CREATE_MSG('ITEM_XFORM_PACK',
                                                  I_item,
                                                  NULL,
                                                  NULL);
            return FALSE;
         end if;
         ---
      end if;
      ---
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

END VALID_XFORM_ITEM;
---------------------------------------------------------------------------------------
--
-- Comments: Before calling this function, all the "from-item" on the request table
--           populated by POPULATE_XFORM_REQUEST are eligible for transformation.
--           The function will skip all the "from-parent", since all its children either
--           have been transformed and/or have been populated on the request table.

--           The function will simply distinguish the "to-item" as two parts, either
--           a transactional item or a non-transactional item.

FUNCTION XFORM_ITEM(O_error_message   IN OUT VARCHAR2,
                    O_partial_xform   IN OUT BOOLEAN,
                    I_tsf_no          IN     TSF_XFORM.TSF_NO%TYPE,
                    I_finisher        IN     TSFHEAD.FROM_LOC%TYPE,
                    I_finisher_type   IN     TSFHEAD.FROM_LOC_TYPE%TYPE,
                    I_to_loc          IN     TSFHEAD.TO_LOC%TYPE,
                    I_to_loc_type     IN     TSFHEAD.TO_LOC_TYPE%TYPE,
                    I_to_item         IN     TSFDETAIL.ITEM%TYPE,
                    I_to_diff_id      IN     TSF_XFORM_REQUEST.DIFF_ID%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.XFORM_ITEM';

   L_exist                    BOOLEAN;
   L_to_parent_ind            VARCHAR2(1) := 'N';
   L_to_diff_xx               NUMBER := 0;
   L_to_item_master           ITEM_MASTER%ROWTYPE;
   L_total_matched_skus       NUMBER := 0;
   L_total_from_items         NUMBER := 0;
   L_unit_retail_exists       BOOLEAN;

   cursor C_xform_from_items is
      select txr.item,
             txr.qty
        from tsf_xform_request txr,
             item_master im
       where txr.item = im.item
         and im.item_level = im.tran_level
         and txr.tsf_no = I_tsf_no
         and txr.record_type = 'F'
         and txr.item != I_to_item;  -- don't include same item transformation

   cursor C_total_from_items is
      select count(*)
        from tsf_xform_request txr,
             item_master im
       where txr.item = im.item
         and im.item_level = im.tran_level
         and txr.tsf_no = I_tsf_no
         and txr.record_type = 'F';

   -- find out which group the I_to_diff_id belongs to, diff_1 ?, diff_2 ?, diff_3 ? or diff_4 ?

   cursor C_to_diff_xx is
      select 1
        from item_master im,
             diff_group_detail dgd
       where im.diff_1 = dgd.diff_group_id
         and im.item = I_to_item
         and dgd.diff_id = I_to_diff_id
       union all
      select 2
        from item_master im,
             diff_group_detail dgd
       where im.diff_2 = dgd.diff_group_id
         and im.item = I_to_item
         and dgd.diff_id = I_to_diff_id
       union all
      select 3
        from item_master im,
             diff_group_detail dgd
       where im.diff_3 = dgd.diff_group_id
         and im.item = I_to_item
         and dgd.diff_id = I_to_diff_id
       union all
      select 4
        from item_master im,
             diff_group_detail dgd
       where im.diff_4 = dgd.diff_group_id
         and im.item = I_to_item
         and dgd.diff_id = I_to_diff_id;

   cursor C_matched_sku is
      select f.item   from_item,
             t.item   to_item,
             f.qty
        from (select item, diff_1, diff_2, diff_3, diff_4
                from item_master
               where item_parent = I_to_item
                 and (I_to_diff_id is null
                      or (I_to_diff_id is not null
                          and (diff_1 = I_to_diff_id
                               or diff_2 = I_to_diff_id
                               or diff_3 = I_to_diff_id
                               or diff_4 = I_to_diff_id)))) t,
             (select txr.item, txr.qty, im.diff_1, im.diff_2, im.diff_3, im.diff_4
                from item_master im,
                     tsf_xform_request txr
               where txr.tsf_no = I_tsf_no
                 and txr.record_type = 'F'
                 and txr.item = im.item
                 and im.item_level = im.tran_level) f
       where t.item != f.item  -- Make sure from item and to item are different items
         and ((I_to_diff_id is null and nvl(f.diff_1, '-1') = nvl(t.diff_1, '-1')
                                    and nvl(f.diff_2, '-1') = nvl(t.diff_2, '-1')
                                    and nvl(f.diff_3, '-1') = nvl(t.diff_3, '-1')
                                    and nvl(f.diff_4, '-1') = nvl(t.diff_4, '-1'))
          or (I_to_diff_id is not null
              and nvl(f.diff_1, '-1') = DECODE(L_to_diff_xx, 1, nvl(f.diff_1, '-1'), nvl(t.diff_1, '-1'))
              and nvl(f.diff_2, '-1') = DECODE(L_to_diff_xx, 2, nvl(f.diff_2, '-1'), nvl(t.diff_2, '-1'))
              and nvl(f.diff_3, '-1') = DECODE(L_to_diff_xx, 3, nvl(f.diff_3, '-1'), nvl(t.diff_3, '-1'))
              and nvl(f.diff_4, '-1') = DECODE(L_to_diff_xx, 4, nvl(f.diff_4, '-1'), nvl(t.diff_4, '-1'))));
BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_to_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_to_item',
                                             L_program,
                                             NULL);
      return FALSE;
   else
      ---
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_to_item_master,
                                         I_to_item) = FALSE then
         return FALSE;
      end if;
      ---
   end if;
   ---
   if L_to_item_master.item_level = L_to_item_master.tran_level then
      if TSF_VALIDATE_SQL.VALID_TO_ITEM(O_error_message,
                                        I_to_item,
                                        I_finisher,
                                        I_finisher_type) = FALSE then
         return FALSE;
      end if;
      ---
      if TSF_VALIDATE_SQL.VALID_TO_ITEM(O_error_message,
                                        I_to_item,
                                        I_to_loc,
                                        I_to_loc_type) = FALSE then
         return FALSE;
      end if;
      ---
      FOR REC_item in C_xform_from_items LOOP
         ---
         insert into tsf_xform_detail_temp(tsf_no,
                                           from_item,
                                           from_qty,
                                           to_item,
                                           to_qty)
                                    values(I_tsf_no,
                                           REC_item.item,
                                           REC_item.qty,
                                           I_to_item,
                                           REC_item.qty);
         ---
      END LOOP;
      ---
   else   -- to_item is a parent item
      ---
      if I_to_diff_id is not NULL then
         open C_to_diff_xx;
         fetch C_to_diff_xx into L_to_diff_xx;
         close C_to_diff_xx;
      end if;
      ---
      FOR REC_matched_sku IN C_matched_sku LOOP
         if TSF_VALIDATE_SQL.VALID_TO_ITEM(O_error_message,
                                           I_to_item,
                                           I_finisher,
                                           I_finisher_type) = FALSE then
            return FALSE;
         end if;
         ---
         if TSF_VALIDATE_SQL.VALID_TO_ITEM(O_error_message,
                                           I_to_item,
                                           I_to_loc,
                                           I_to_loc_type) = FALSE then
            return FALSE;
         end if;
         ---
         insert into tsf_xform_detail_temp(tsf_no,
                                           from_item,
                                           from_qty,
                                           to_item,
                                           to_qty)
                                    values(I_tsf_no,
                                           REC_matched_sku.from_item,
                                           REC_matched_sku.qty,
                                           REC_matched_sku.to_item,
                                           REC_matched_sku.qty);
         ---
         L_total_matched_skus := L_total_matched_skus + 1;
         ---
      END LOOP;
      ---
      if L_total_matched_skus = 0 then
         O_error_message := SQL_LIB.CREATE_MSG('XFORM_NO_MATCH',
                                               I_to_item,
                                               NULL,
                                               NULL);
         return FALSE;
      end if;
      ---
      open C_total_from_items;
      fetch C_total_from_items into L_total_from_items;
      close C_total_from_items;
      ---
      if L_total_from_items != L_total_matched_skus then
         O_partial_xform := TRUE;
      else
         O_partial_xform := FALSE;
      end if;
      ---
   end if;
   ---
   delete from tsf_xform_request
         where tsf_no = I_tsf_no;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END XFORM_ITEM;
-------------------------------------------------------------------------------------------
FUNCTION CREATE_TSF_XFORM(O_error_message   IN OUT VARCHAR2,
                          I_tsf_no          IN     TSF_XFORM.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.CREATE_TSF_XFORM';
   L_xform_exist              VARCHAR2(1) := 'N';
   L_return_code              BOOLEAN;
   L_tsf_xform_id             TSF_XFORM.TSF_XFORM_ID%TYPE;
   L_tsf_xform_detail_id      TSF_XFORM_DETAIL.TSF_XFORM_DETAIL_ID%TYPE;

   cursor C_tsf_xform_exist is
      select 'Y'
        from tsf_xform_detail_temp
       where tsf_no = I_tsf_no;

   cursor C_item_xform is
      select from_item,
             to_item,
             sum(from_qty) from_qty,
             sum(to_qty)  to_qty
        from tsf_xform_detail_temp
       where tsf_no = I_tsf_no
       group by from_item, to_item;

BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   open C_tsf_xform_exist;
   fetch C_tsf_xform_exist into L_xform_exist;
   close C_tsf_xform_exist;
   ---
   if L_xform_exist = 'N' then
      O_error_message := SQL_LIB.CREATE_MSG('NO_TSF_XFORM',
                                            I_tsf_no,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;
   ---
   if NEXT_XFORM_ID(O_error_message,
                    L_return_code,
                    L_tsf_xform_id) = FALSE
                 or L_return_code = FALSE then
      return FALSE;
   end if;
   ---
   insert into tsf_xform(tsf_xform_id,
                         tsf_no)
                  values(L_tsf_xform_id,
                         I_tsf_no);
   ---
   FOR REC_xform IN C_item_xform LOOP
      ---
      if NEXT_XFORM_DETAIL_ID(O_error_message,
                              L_return_code,
                              L_tsf_xform_detail_id) = FALSE
                           or L_return_code = FALSE then
         return FALSE;
      end if;
      ---
      insert into tsf_xform_detail(tsf_xform_id,
                                   tsf_xform_detail_id,
                                   from_item,
                                   from_qty,
                                   to_item,
                                   to_qty)
                            values(L_tsf_xform_id,
                                   L_tsf_xform_detail_id,
                                   REC_xform.from_item,
                                   REC_xform.from_qty,
                                   REC_xform.to_item,
                                   REC_xform.to_qty);
      ---
   END LOOP;
   ---
   delete from tsf_xform_detail_temp
         where tsf_no = I_tsf_no;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END CREATE_TSF_XFORM;
-------------------------------------------------------------------------------------------
FUNCTION DELETE_TSF_XFORM_HEAD(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                               I_tsf_xform_id    IN     TSF_XFORM.TSF_XFORM_ID%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.DELETE_TSF_XFORM_HEAD';
   L_exists               VARCHAR2(1)  := 'N';
  cursor C_CHECK_DETAILS_EXISTS is
     select 'Y'
       from tsf_xform_detail
      where tsf_xform_id = I_tsf_xform_id;

BEGIN
   if I_tsf_xform_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', 'I_tsf_xform_id', L_program, NULL);
      return FALSE;
   end if;
  open C_CHECK_DETAILS_EXISTS;
  fetch C_CHECK_DETAILS_EXISTS into L_exists;
  close C_CHECK_DETAILS_EXISTS;
  if L_exists = 'N' then
      delete from tsf_xform
       where tsf_xform_id = I_tsf_xform_id;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_TSF_XFORM_HEAD;
----------------------------------------------------------------------------------------------
FUNCTION DELETE_TSF_XFORM_REQUEST(O_error_message    IN OUT VARCHAR2,
                                  I_tsf_no           IN     TSF_XFORM_REQUEST.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_program           VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.DELETE_TSF_XFORM_REQUEST';
   L_exists            VARCHAR2(1) := 'N';

   cursor C_request_exist is
      select 'Y'
        from tsf_xform_request
       where tsf_no = I_tsf_no;
BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   open C_request_exist;
   fetch C_request_exist into L_exists;
   close C_request_exist;
   ---
   if L_exists = 'Y' then
      delete from tsf_xform_request
            where tsf_no = I_tsf_no;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_TSF_XFORM_REQUEST;
----------------------------------------------------------------------------------------------
FUNCTION GENERATE_TSF_PACKING_HEAD(O_error_message    IN OUT VARCHAR2,
                                   O_tsf_packing_id   IN OUT TSF_PACKING.TSF_PACKING_ID%TYPE,
                                   O_set_no           IN OUT TSF_PACKING.SET_NO%TYPE,
                                   I_tsf_no           IN     TSF_PACKING.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.GENERATE_TSF_PACKING_HEAD';
   L_return_code          BOOLEAN;
   L_tsf_packing_id       TSF_PACKING.TSF_PACKING_ID%TYPE;
   L_set_no               TSF_PACKING.SET_NO%TYPE;

BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if NEXT_PACKING_ID(O_error_message,
                      L_return_code,
                      L_tsf_packing_id) = FALSE
                   or L_return_code = FALSE then
      return FALSE;
   end if;
   ---
   if NEXT_PACK_SET_NO(O_error_message,
                       L_set_no,
                       I_tsf_no) = FALSE then
      return FALSE;
   end if;
   ---
   insert into TSF_PACKING(tsf_packing_id,
                           tsf_no,
                           set_no)
                    values(L_tsf_packing_id,
                           I_tsf_no,
                           L_set_no);
   ---
   O_tsf_packing_id := L_tsf_packing_id;
   O_set_no := L_set_no;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END GENERATE_TSF_PACKING_HEAD;
--------------------------------------------------------------------------------------------
FUNCTION DELETE_TSF_PACKING_DETAIL(O_error_message    IN OUT VARCHAR2,
                                   I_tsf_packing_id   IN     TSF_PACKING.TSF_PACKING_ID%TYPE)
RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.DELETE_TSF_PACKING_DETAIL';
   L_exists          VARCHAR2(1) := 'N';

   L_rowid              ROWID;
   L_table              VARCHAR2(30) := 'TSF_PACKING_DETAIL';
   L_key1               VARCHAR2(100);
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   cursor C_packing_detail_exist is
      select 'Y'
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id;

   cursor C_tpd_lock is
      select rowid
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         for update nowait;

BEGIN
   ---
   if I_tsf_packing_id IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_packing_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   open C_packing_detail_exist;
   fetch C_packing_detail_exist into L_exists;
   close C_packing_detail_exist;
   ---
   if L_exists = 'Y' then
      ---
      open C_tpd_lock;
      fetch C_tpd_lock into L_rowid;
      close C_tpd_lock;
      ---
      delete from tsf_packing_detail
            where tsf_packing_id = I_tsf_packing_id;
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_key1,
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END DELETE_TSF_PACKING_DETAIL;
--------------------------------------------------------------------------------------------
FUNCTION VALID_PACKING_ITEM(O_error_message   IN OUT VARCHAR2,
                            O_valid           IN OUT BOOLEAN,
                            O_item_desc       IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
                            O_qty             IN OUT TSFDETAIL.TSF_QTY%TYPE,
                            I_tsf_no          IN     TSFDETAIL.TSF_NO%TYPE,
                            I_item            IN     TSFDETAIL.ITEM%TYPE,
                            I_diff_id         IN     TSF_PACKING_DETAIL.DIFF_ID%TYPE)
RETURN BOOLEAN IS

   L_program           VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.VALID_PACKING_ITEM';
   L_exist             VARCHAR2(1) := 'N';
   L_temp_qty          TSFDETAIL.TSF_QTY%TYPE;
   L_item_master       ITEM_MASTER%ROWTYPE;

   cursor C_valid_item is
      select vim.item_desc,
             vtp.qty
        from v_item_master vim,
             v_tsf_packing_avail vtp
       where vim.item = vtp.item
         and vtp.tsf_no = I_tsf_no
         and vtp.item = I_item;

   cursor C_item_tsf_xfm_exist is
      select 'Y'
        from tsf_xform tx,
             tsf_xform_detail txd
       where tx.tsf_xform_id = txd.tsf_xform_id
         and tx.tsf_no = I_tsf_no
         and txd.from_item = I_item
       union all
      select 'Y'
        from tsf_packing tp,
             tsf_packing_detail tpd
       where tp.tsf_packing_id = tpd.tsf_packing_id
         and tp.tsf_no = I_tsf_no
         and tpd.item = I_item
         and tpd.record_type = 'F';

   cursor C_recalc_qty is
      select sum(td.tsf_qty) qty
        from tsfdetail td,
             item_master im
       where im.item = td.item
         and (nvl(im.diff_1, '-1') = I_diff_id
              or nvl(im.diff_2, '-1') = I_diff_id
              or nvl(im.diff_3, '-1') = I_diff_id
              or nvl(im.diff_4, '-1') = I_diff_id)
         and td.tsf_no = I_tsf_no
         and im.item_parent = I_item
         and not exists (select 'x'
                           from tsf_xform tx,
                                tsf_xform_detail txd
                          where tx.tsf_xform_id = txd.tsf_xform_id
                            and tx.tsf_no = td.tsf_no
                            and txd.from_item = td.item)
         and not exists (select 'x'
                           from tsf_packing tp,
                                tsf_packing_detail tpd
                          where tp.tsf_packing_id = tpd.tsf_packing_id
                            and tp.tsf_no = td.tsf_no
                            and tpd.item = td.item
                            and tpd.record_type = 'F')
       union all
      select sum(td.tsf_qty)  qty
        from tsf_xform tx,
             tsf_xform_detail txd,
             tsfdetail td
       where tx.tsf_xform_id = txd.tsf_xform_id
         and tx.tsf_no = I_tsf_no
         and tx.tsf_no = td.tsf_no
         and txd.from_item = td.item
         and txd.to_item in (select item
                               from item_master
                              where item_parent = I_item
                                and (nvl(diff_1, '-1') = I_diff_id
                                     or nvl(diff_2, '-1') = I_diff_id
                                     or nvl(diff_3, '-1') = I_diff_id
                                     or nvl(diff_4, '-1') = I_diff_id))
         and txd.to_item not in (select tpd.item
                           from tsf_packing tp, tsf_packing_detail tpd
                          where tp.tsf_packing_id = tpd.tsf_packing_id
                            and tp.tsf_no = I_tsf_no
                            and tpd.record_type = 'F'
                            and tpd.item = txd.to_item);

BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   open C_valid_item;
   fetch C_valid_item into O_item_desc,
                           O_qty;
   ---
   if C_valid_item%NOTFOUND then
      ---
      O_valid := FALSE;
      close C_valid_item;
      ---
      open C_item_tsf_xfm_exist;
      fetch C_item_tsf_xfm_exist into L_exist;
      close C_item_tsf_xfm_exist;
      ---
      if L_exist = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('ITEM_XFORM_PACK',
                                               I_item,
                                               NULL,
                                               NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('INV_ITEM_PACK',
                                               I_item,
                                               NULL,
                                               NULL);
      end if;
      ---
      return FALSE;
      ---
   else
      O_valid := TRUE;
   end if;
   ---
   close C_valid_item;
   ---
   -- Recalculate the qty for parent item
   ---

   L_temp_qty := 0;
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_item_master.item_level != L_item_master.tran_level
      and I_diff_id is not null then  -- parent item
      ---

      FOR REC_child IN C_recalc_qty LOOP
         ---
         L_temp_qty := L_temp_qty + nvl(REC_child.qty, 0);
         ---
      END LOOP;
      ---
      O_qty := L_temp_qty;
      ---
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

END VALID_PACKING_ITEM;
-------------------------------------------------------------------------------------------
FUNCTION EXPLODE_PACK(O_error_message   IN OUT VARCHAR2,
                      I_pack_no         IN     TSF_PACKING_DETAIL.ITEM%TYPE,
                      I_tsf_packing_id  IN     TSF_PACKING_DETAIL.TSF_PACKING_ID%TYPE,
                      I_tsf_no          IN     TSF_XFORM.TSF_NO%TYPE,
                      I_qty             IN     TSF_PACKING_DETAIL.QTY%TYPE)
RETURN BOOLEAN IS

   L_xfm_item                 TSF_PACKING_DETAIL.ITEM%TYPE;
   L_item                     TSF_PACKING_DETAIL.ITEM%TYPE;
   L_next_detail_id           TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE;
   L_to_loc                   TSFHEAD.TO_LOC%TYPE;
   L_to_loc_type              TSFHEAD.TO_LOC_TYPE%TYPE;
   L_return_code              BOOLEAN;
   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.EXPLODE_PACK';
   L_item_exist               VARCHAR2(1) := 'N';
   RECORD_LOCKED              EXCEPTION;
   PRAGMA                     EXCEPTION_INIT(Record_Locked, -54);
   cursor C_GET_TO_LOC is
      select to_loc,
             to_loc_type
        from tsfhead
       where tsf_parent_no = I_tsf_no;
   cursor C_GET_COMPONENT is
      select item,
             qty
        from v_packsku_qty
       where pack_no = I_pack_no;
   cursor C_GET_XFM_ITEM(cv_item TSF_PACKING_DETAIL.ITEM%TYPE) is
      select txd.to_item
        from tsf_xform tx, tsf_xform_detail txd
       where tx.tsf_xform_id = txd.tsf_xform_id
         and tx.tsf_no = I_tsf_no
         and txd.from_item = cv_item;

   cursor C_item_in_packing_detail (cv_item TSF_PACKING_DETAIL.ITEM%TYPE) is
      select 'Y'
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and record_type = 'R'
         and item = cv_item
         for update nowait;
   cursor C_pack_exist is
      select 'Y'
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and item = I_pack_no
         and record_type = 'F';

   cursor C_clear_previous_to_items is
      select 'Y'
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and record_type = 'R';

   L_previous_to_item_exist      VARCHAR2(1) := 'N';

BEGIN
   ---
   if I_pack_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_pack_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_tsf_packing_id IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_packing_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_qty IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_qty',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_TO_LOC',
                    'tsfhead',
                    I_tsf_no);
   open C_GET_TO_LOC;

   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_TO_LOC',
                    'tsfhead',
                    I_tsf_no);
   fetch C_GET_TO_LOC into L_to_loc,
                           L_to_loc_type;

   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_TO_LOC',
                    'tsfhead',
                    I_tsf_no);
   close C_GET_TO_LOC;
   ---
   -- Clear out the tsf_packing_detail table to remove all the 'R'esultant item for the specific tsf_packing_id
   -- if there exists.
   ---
   open C_clear_previous_to_items;
   fetch C_clear_previous_to_items into L_previous_to_item_exist;
   close C_clear_previous_to_items;
   ---
   if L_previous_to_item_exist = 'Y' then
      delete from tsf_packing_detail
            where tsf_packing_id = I_tsf_packing_id
              and record_type = 'R';
   end if;
   ---
   -- Insert the pack into the tsf_packing_detail table as "from item"
   ---
   open C_pack_exist;
   fetch C_pack_exist into L_item_exist;
   close C_pack_exist;
   ---
   if L_item_exist = 'N' then
      if NEXT_PACKING_DETAIL_ID(O_error_message,
                                L_return_code,
                                L_next_detail_id) = false
                             or L_return_code = false then
         return FALSE;
      end if;
      ---
      insert into tsf_packing_detail(tsf_packing_detail_id,
                                     tsf_packing_id,
                                     record_type,
                                     item,
                                     qty)
                              values(L_next_detail_id,
                                     I_tsf_packing_id,
                                     'F',
                                     I_pack_no,
                                     I_qty);
   end if;
   ---
   -- Blow down to the component level, insert the components(or its tranformed item if exists)
   -- into the tsf_packing_detail table as "to item"
   ---
   FOR REC_component in C_GET_COMPONENT LOOP
      ---
      open C_GET_XFM_ITEM(REC_component.item);
      fetch C_GET_XFM_ITEM into L_xfm_item;
      ---
      if C_GET_XFM_ITEM%NOTFOUND then
         L_item := REC_component.item;

         -- Since Item hasn't been transformed we need to Validate the item at the to_loc
         if TSF_VALIDATE_SQL.VALID_TO_ITEM(O_error_message,
                                           L_item,
                                           L_to_loc,
                                           L_to_loc_type) = FALSE then
            return FALSE;
         end if;
      else
         L_item := L_xfm_item;
      end if;
      ---
      close C_GET_XFM_ITEM;
      ---
      L_item_exist := 'N';
      ---
      open C_item_in_packing_detail(L_item);
      fetch C_item_in_packing_detail into L_item_exist;
      close C_item_in_packing_detail;
      ---
      if L_item_exist = 'Y' then
         update tsf_packing_detail
            set qty = qty + REC_component.qty * I_qty
          where tsf_packing_id = I_tsf_packing_id
            and item = L_item
            and record_type = 'R';
      else
         ---
         if NEXT_PACKING_DETAIL_ID(O_error_message,
                                   L_return_code,
                                   L_next_detail_id) = false
                                or L_return_code = false then
            return FALSE;
         end if;
         ---
         insert into tsf_packing_detail(tsf_packing_detail_id,
                                        tsf_packing_id,
                                        record_type,
                                        item,
                                        qty)
                                 values(L_next_detail_id,
                                        I_tsf_packing_id,
                                        'R',
                                        L_item,
                                        REC_component.qty * I_qty);
         ---
      end if;
      ---
   END LOOP;
   ---

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'TSF_PACKING_DETAIL',
                                            I_tsf_packing_id,
                                            L_item);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END EXPLODE_PACK;
------------------------------------------------------------------------------------------
FUNCTION DELETE_TSF_PACKING(O_error_message   IN OUT VARCHAR2,
                            I_tsf_no          IN     TSF_PACKING.TSF_NO%TYPE,
                            I_set_no          IN     TSF_PACKING.SET_NO%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.DELETE_TSF_PACKING';
   L_tsf_packing_id       TSF_PACKING.TSF_PACKING_ID%TYPE;

   L_rowid                ROWID;
   L_table                VARCHAR2(30);
   L_key1                 VARCHAR2(100);
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   cursor C_GET_TSF_PACKING_ID is
      select tsf_packing_id
        from tsf_packing
       where tsf_no = I_tsf_no
         and set_no = I_set_no;

   cursor C_tp_lock is
      select rowid
        from tsf_packing
       where tsf_packing_id = L_tsf_packing_id;
BEGIN

   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   if I_set_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_set_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   open C_GET_TSF_PACKING_ID;
   fetch C_GET_TSF_PACKING_ID into L_tsf_packing_id;
   close C_GET_TSF_PACKING_ID;
   ---
   L_key1 := L_tsf_packing_id;
   ---
   if L_tsf_packing_id is not null then
      ---
      if DELETE_TSF_PACKING_DETAIL(O_error_message,
                                   L_tsf_packing_id) = FALSE then
         return FALSE;
      end if;
      ---
      open C_tp_lock;
      fetch C_tp_lock into L_rowid;
      close C_tp_lock;
      ---
      delete from tsf_packing
            where rowid = L_rowid;
   end if;
   ---

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_key1,
                                             NULL);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_TSF_PACKING;
--------------------------------------------------------------------------------------------
FUNCTION TSF_PACKING_ITEM_EXISTS(O_error_message   IN OUT VARCHAR2,
                                 O_EXISTS          IN OUT BOOLEAN,
                                 I_tsf_packing_id  IN     TSF_PACKING_DETAIL.TSF_PACKING_ID%TYPE,
                                 I_record_type     IN     TSF_PACKING_DETAIL.RECORD_TYPE%TYPE,
                                 I_item            IN     TSF_PACKING_DETAIL.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.TSF_PACKING_ITEM_EXISTS';
   L_exists          VARCHAR2(1) := 'N';

   cursor C_packing_exists is
      select 'Y'
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and record_type = I_record_type
         and item = I_item;

BEGIN
   ---
   open C_packing_exists;
   fetch C_packing_exists into L_exists;
   close C_packing_exists;
   ---
   if L_exists = 'Y' then
      O_exists := TRUE;
   else
      O_exists := FALSE;
   end if;
   ---

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         NULL);
      return FALSE;

END TSF_PACKING_ITEM_EXISTS;
-----------------------------------------------------------------------------------------
FUNCTION CHECK_DUPLICATE_XFORM_REQUEST(O_error_message  IN OUT VARCHAR2,
                                       O_duplicate      IN OUT BOOLEAN,
                                       I_tsf_no         IN     TSF_XFORM_REQUEST.TSF_NO%TYPE,
                                       I_item           IN     TSF_XFORM_REQUEST.ITEM%TYPE,
                                       I_diff_id        IN     TSF_XFORM_REQUEST.DIFF_ID%TYPE)
RETURN BOOLEAN IS

   L_program               VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.CHECK_DUPLICATE_XFORM_REQUEST';
   L_request_item_exist    VARCHAR2(1)  := 'N';
   L_item_master           ITEM_MASTER%ROWTYPE;
   CURSOR C_request_item_exist(cv_item  tsf_xform_request.item%type) is
      select 'Y'
        from tsf_xform_request
       where tsf_no = I_tsf_no
         and record_type = 'F'
         and item = cv_item
         and nvl(diff_id, '-1') = nvl(I_diff_id, '-1');

BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   ---
   open C_request_item_exist(I_item);
   fetch C_request_item_exist into L_request_item_exist;
   close C_request_item_exist;
   ---
   if L_request_item_exist = 'Y' then
      O_error_message := SQL_LIB.CREATE_MSG('XFORM_DUP_REQ',
                                            I_item,
                                            NULL,
                                            NULL);
      O_duplicate := TRUE;
   else
      O_duplicate := FALSE;
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

END CHECK_DUPLICATE_XFORM_REQUEST;
----------------------------------------------------------------------------------------
FUNCTION BUILD_PACK(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                    O_bulk_item_left  IN OUT BOOLEAN,
                    O_short_qty_ind   IN OUT BOOLEAN,
                    I_tsf_no          IN TSF_PACKING.TSF_NO%TYPE,
                    I_tsf_packing_id  IN TSF_PACKING.TSF_PACKING_ID%TYPE,
                    I_to_pack_no      IN PACKITEM.PACK_NO%TYPE)
RETURN BOOLEAN IS

   L_program                   VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.BUILD_PACK';
   L_item_master               ITEM_MASTER%ROWTYPE;

   L_rowid                     ROWID;
   L_table                     VARCHAR2(30) := 'TSF_PACKING_DETAIL';
   L_key1                      VARCHAR2(100) := I_tsf_packing_id;
   L_key2                      VARCHAR2(100);
   RECORD_LOCKED               EXCEPTION;
   PRAGMA                      EXCEPTION_INIT(Record_Locked, -54);

   L_from_item_count           NUMBER := 0;
   L_pack_ind                  VARCHAR2(1) := 'N';
   L_pack_qty                  TSF_PACKING_DETAIL.QTY%TYPE;
   L_previous_to_item_exist    VARCHAR2(1) := 'N';
   L_from_qty                  TSF_PACKING_DETAIL.QTY%TYPE;

   cursor C_clear_previous_to_items is
      select 'Y'
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and record_type = 'R';

   cursor C_from_items is
      select item,
             diff_id,
             qty
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and record_type = 'F';

   cursor C_sku_in_pack(cv_item      tsf_packing_detail.item%type,
                        cv_diff_id   tsf_packing_detail.diff_id%type) is
      select v.item  item,
             (v.qty * L_from_qty) qty
        from v_packsku_qty v,
             tsfdetail td
       where td.item = v.pack_no
         and td.tsf_no = I_tsf_no
         and v.pack_no = cv_item
         and not exists (select 'x'
                           from tsf_xform tx,
                                tsf_xform_detail txd
                          where tx.tsf_xform_id = txd.tsf_xform_id
                            and tx.tsf_no = I_tsf_no
                            and txd.from_item = v.item)
       union all
      select txd.to_item  item,
             v.qty * L_from_qty
        from tsf_xform tx,
             tsf_xform_detail txd,
             v_packsku_qty v,
             tsfdetail td
       where tx.tsf_xform_id = txd.tsf_xform_id
         and tx.tsf_no = I_tsf_no
         and txd.from_item = v.item
         and td.item = v.pack_no
         and td.tsf_no = tx.tsf_no
         and v.pack_no = cv_item;

   cursor C_cal_packing_remainder is
      select tpd.item item,
             (tpd.qty - (L_pack_qty * v.qty)) qty
        from tsf_packing_detail tpd,
             v_packsku_qty v
       where tpd.item = v.item
         and tpd.tsf_packing_id = I_tsf_packing_id
         and tpd.record_type = 'R'
         and v.pack_no = I_to_pack_no;

   cursor C_packing_remainder_lock (cv_item  tsf_packing_detail.item%type) is
      select rowid
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and record_type = 'R'
         and item = cv_item
         FOR UPDATE NOWAIT;

   cursor C_non_matched_component_exist is
      select 'Y'
        from v_packsku_qty v
       where v.pack_no = I_to_pack_no
         and v.item not in (select tpd.item
                              from tsf_packing_detail tpd
                             where tpd.tsf_packing_id = I_tsf_packing_id
                               and tpd.record_type = 'R');

   cursor C_matched_components is
      select v.item, trunc(tpd.qty/v.qty) qty
        from v_packsku_qty v,
             tsf_packing_detail tpd
       where v.item = tpd.item
         and v.pack_no = I_to_pack_no
         and tpd.tsf_packing_id = I_tsf_packing_id
         and tpd.record_type = 'R';

   L_non_matched_exist     VARCHAR2(1) := 'N';
   ---------------------------------------------------------------------------------------------------
   FUNCTION INS_UPD_TSF_PACKING_DETAIL(O_error_message   IN OUT VARCHAR2,
                                       I_tsf_packing_id  IN     TSF_PACKING_DETAIL.TSF_PACKING_ID%TYPE,
                                       I_record_type     IN     TSF_PACKING_DETAIL.RECORD_TYPE%TYPE,
                                       I_item            IN     TSF_PACKING_DETAIL.ITEM%TYPE,
                                       I_qty             IN     TSF_PACKING_DETAIL.QTY%TYPE)
   RETURN BOOLEAN IS

      L_program                 VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.BUILD_PACK.INS_UPD_TSF_PACKING_DETAIL';
      L_exist                   BOOLEAN;
      L_rowid                   ROWID;
      L_return_code             BOOLEAN;
      L_tsf_packing_detail_id   TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE;
      L_item_master             item_master%rowtype;

      RECORD_LOCKED                        EXCEPTION;
      PRAGMA                               EXCEPTION_INIT(Record_Locked, -54);

      cursor C_tpd_lock is
         select rowid
           from tsf_packing_detail
          where tsf_packing_id = I_tsf_packing_id
            and record_type = I_record_type
            and item = I_item
            for update nowait;

   BEGIN
      ---
      if TSF_PACKING_ITEM_EXISTS(O_error_message,
                                 L_exist,
                                 I_tsf_packing_id,
                                 I_record_type,
                                 I_item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_exist = TRUE then
         ---
         open C_tpd_lock;
         fetch C_tpd_lock into L_rowid;
         close C_tpd_lock;
         ---
         update tsf_packing_detail
            set qty = qty + I_qty
          where rowid = L_rowid;
         ---
      else
         ---
         if NEXT_PACKING_DETAIL_ID(O_error_message,
                                   L_return_code,
                                   L_tsf_packing_detail_id) = FALSE
                                or L_return_code = FALSE then
            return FALSE;
         end if;
         ---
         insert into tsf_packing_detail(tsf_packing_detail_id,
                                        tsf_packing_id,
                                        record_type,
                                        item,
                                        diff_id,
                                        qty)
                                 values(L_tsf_packing_detail_id,
                                        I_tsf_packing_id,
                                        I_record_type,
                                        I_item,
                                        NULL,
                                        I_qty);
         ---
      end if;
      ---
      return TRUE;
   EXCEPTION
      when RECORD_LOCKED then
         O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                               'TSF_PACKING_DETAIL',
                                               I_tsf_packing_id,
                                               I_item);
         return FALSE;
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END INS_UPD_TSF_PACKING_DETAIL;
   ---------------------------------------------------------------------------------------------------
BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_tsf_packing_id IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_packing_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_to_pack_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_to_pack_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   -- Clear out the tsf_packing_detail table to remove all the 'R'esultant item for the specific tsf_packing_id
   -- if there exists.
   ---
   open C_clear_previous_to_items;
   fetch C_clear_previous_to_items into L_previous_to_item_exist;
   close C_clear_previous_to_items;
   ---
   if L_previous_to_item_exist = 'Y' then
      delete from tsf_packing_detail
            where tsf_packing_id = I_tsf_packing_id
              and record_type = 'R';
   end if;
   ---
   -- Since the form tsfpack will populate the transactional level items as "from item", so from-items are
   -- either single items or pack items.
   -- If it is single item, simply insert/accumulate it into the tsf_packing_detail table with record type 'R';
   -- otherwise, insert/accumulate it's original/transformed components into the table with record type 'R';
   ---
   FOR REC_from_items IN C_from_items LOOP
      ---
      L_from_item_count := L_from_item_count + 1;
      ---
      L_from_qty := REC_from_items.qty;
      ---
      if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                         L_item_master,
                                         REC_from_items.item) = FALSE then
         return FALSE;
      end if;
      ---
      L_pack_ind := L_item_master.pack_ind;
      ---
      if L_item_master.pack_ind = 'N' then
         ---
         if INS_UPD_TSF_PACKING_DETAIL(O_error_message,
                                       I_tsf_packing_id,
                                       'R',
                                       REC_from_items.item,
                                       L_from_qty) = FALSE then
            return FALSE;
         end if;
         ---
      else
         ---
         FOR REC_sku in C_sku_in_pack(REC_from_items.item, REC_from_items.diff_id) LOOP
            ---
            if INS_UPD_TSF_PACKING_DETAIL(O_error_message,
                                          I_tsf_packing_id,
                                          'R',
                                          REC_sku.item,
                                          REC_sku.qty) = FALSE then
               return FALSE;
            end if;
            ---
         END LOOP;
         ---
      end if;
      ---
   END LOOP;

   ---
   -- Calculate the total quantity of the pack can be built
   -- Check to see whether the "from items" contains all the required components, if yes, calculate the pack quantity;
   -- Otherwise, give a proper error message, and return FALSE
   ---
   open C_non_matched_component_exist;
   fetch C_non_matched_component_exist into L_non_matched_exist;
   close C_non_matched_component_exist;
   ---
   if L_non_matched_exist = 'Y' then
      ---
      if L_from_item_count = 1 and L_pack_ind = 'Y' then
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_RECONFIGURE',
                                                  NULL,
                                                  NULL,
                                                  NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_REPACK_ITM',
                                               NULL,
                                               NULL,
                                               NULL);
      end if;
      ---
      return FALSE;
      ---
   end if;
   ---
   FOR REC_matched_components IN C_matched_components LOOP
      ---
      if REC_matched_components.qty = 0 then
         O_short_qty_ind := TRUE;
         O_error_message := SQL_LIB.CREATE_MSG('CANNOT_REPACK_QTY',
                                               NULL,
                                               NULL,
                                               NULL);
         return FALSE;
      else
         if L_pack_qty is NULL or L_pack_qty > REC_matched_components.qty then
            L_pack_qty := REC_matched_components.qty;
         end if;
         ---
      end if;
      ---
   END LOOP;
   ---
   -- Calculate the left items/qty after packing, delete those with left qty zero
   ---

   FOR REC_cal_packing_remainder IN C_cal_packing_remainder LOOP
      ---
      L_key2 := REC_cal_packing_remainder.item;
      ---
      open C_packing_remainder_lock(REC_cal_packing_remainder.item);
      fetch C_packing_remainder_lock into L_rowid;
      close C_packing_remainder_lock;
      ---
      if REC_cal_packing_remainder.qty = 0 then
         ---
         delete from tsf_packing_detail
               where rowid = L_rowid;
         ---
      else
         ---
         O_bulk_item_left := TRUE;
         ---
         update tsf_packing_detail
            set qty = REC_cal_packing_remainder.qty
          where rowid = L_rowid;
         ---
      end if;
      ---
   END LOOP;

   ---
   -- Insert the "to_pack" to the detail table
   ---
   if INS_UPD_TSF_PACKING_DETAIL(O_error_message,
                                 I_tsf_packing_id,
                                 'R',
                                 I_to_pack_no,
                                 L_pack_qty) = FALSE then
      return FALSE;
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
END BUILD_PACK;
---------------------------------------------------------------------------------------
FUNCTION GET_XFORM_ITEM_DESC(O_error_message    IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                             O_from_item_desc   IN OUT    ITEM_MASTER.ITEM_DESC%TYPE,
                             O_to_item_desc     IN OUT    ITEM_MASTER.ITEM_DESC%TYPE,
                             I_from_item        IN        ITEM_MASTER.ITEM%TYPE,
                             I_to_item          IN        ITEM_MASTER.ITEM%TYPE)
 RETURN BOOLEAN IS

   L_program           VARCHAR2(50)            := 'ITEM_XFORM_PACK_SQL.GET_XFORM_ITEM_DESC';
   L_invalid_param     VARCHAR2(50);
   L_valid_diff        VARCHAR2(1)             := 'N';

 BEGIN
   if I_from_item is NULL then
      L_invalid_param := 'I_from_item';
   elsif I_to_item is NULL then
      L_invalid_param := 'I_to_item';
   end if;

   if L_invalid_param is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', L_invalid_param, L_program, NULL);
      return FALSE;
   end if;
   if ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                               O_from_item_desc,
                               I_from_item) = FALSE then
      return FALSE;
   end if;

   if ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                               O_to_item_desc,
                               I_to_item) = FALSE then
       return FALSE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         NULL);
      return FALSE;

END GET_XFORM_ITEM_DESC;
--------------------------------------------------------------------------------------------
FUNCTION GET_FILTER_DIFF_INFO(O_error_message    IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                              O_diff_desc        IN OUT    DIFF_IDS.DIFF_DESC%TYPE,
                              I_tsf_no           IN OUT    TSFHEAD.TSF_NO%TYPE,
                              I_to_from          IN        VARCHAR2,
                              I_diff             IN        DIFF_IDS.DIFF_ID%TYPE)
 RETURN BOOLEAN IS

   L_program           VARCHAR2(50)            := 'ITEM_XFORM_PACK_SQL.GET_FILTER_DIFF_INFO';
   L_invalid_param     VARCHAR2(50);
   L_valid_diff        VARCHAR2(1)             := 'N';
   L_diff_type         DIFF_IDS.DIFF_TYPE%TYPE;
   L_id_group_ind      VARCHAR2(50);

   cursor C_check_diff is
    select 'Y'
      from tsf_xform_detail txd,
       v_item_master vim,
       tsf_xform tx
     where tx.tsf_no = I_tsf_no
       and tx.tsf_xform_id = txd.tsf_xform_id
       and vim.item = decode(I_to_from,
                             'TO', txd.to_item,
                             txd.from_item)
       and (vim.diff_1    = I_diff
        or vim.diff_2 = I_diff
        or vim.diff_3 = I_diff
            or vim.diff_4 = I_diff);

 BEGIN
   if I_diff is NULL then
      L_invalid_param := 'I_diff';
   elsif I_to_from is NULL then
      L_invalid_param := 'I_to_from';
   end if;

   if L_invalid_param is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', L_invalid_param, L_program, NULL);
      return FALSE;
   end if;
   if DIFF_SQL.GET_DIFF_INFO(O_error_message,
                             O_diff_desc,
                             L_diff_type,
                             L_id_group_ind,
                             I_diff) = FALSE then
      return FALSE;
   end if;
   open C_check_diff;
   fetch C_check_diff into L_valid_diff;
   close C_check_diff;
   if L_valid_diff = 'N' then
      O_error_message := SQL_LIB.CREATE_MSG('INV_XFORM_DIFF_FILTER', NULL, NULL, NULL);
      return FALSE;
   else
      return TRUE;
   end if;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;

END GET_FILTER_DIFF_INFO;
--------------------------------------------------------------------------------------------
FUNCTION GET_FILTER_ITEM_INFO(O_error_message    IN OUT    RTK_ERRORS.RTK_TEXT%TYPE,
                              O_item_desc        IN OUT    ITEM_MASTER.ITEM_DESC%TYPE,
                              I_tsf_no           IN OUT    TSFHEAD.TSF_NO%TYPE,
                              I_to_from          IN        VARCHAR2,
                              I_item             IN        ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program           VARCHAR2(50)            := 'ITEM_XFORM_PACK_SQL.GET_FILTER_ITEM_INFO';
   L_invalid_param     VARCHAR2(50);
   L_valid             BOOLEAN;
   L_item_master       V_ITEM_MASTER%ROWTYPE;
   L_valid_xform_item  VARCHAR2(1)             := 'N';

 cursor C_check_item is
    select 'Y'
      from v_item_master vim, tsf_xform_detail txd, tsf_xform tx
     where tx.tsf_no = I_tsf_no
       and tx.tsf_xform_id = txd.tsf_xform_id
       and ((decode(I_to_from, 'TO', txd.to_item, txd.from_item) = I_item) or
           ((decode(I_to_from, 'TO', txd.to_item, txd.from_item) = vim.item) and
            (vim.item_parent = I_item)));

 BEGIN
   if I_item is NULL then
      L_invalid_param := 'I_item';
   elsif I_to_from is NULL then
      L_invalid_param := 'I_to_from';
   end if;

   if L_invalid_param is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', L_invalid_param, L_program, NULL);
      return FALSE;
   end if;
   if FILTER_LOV_VALIDATE_SQL.VALIDATE_ITEM_MASTER(O_error_message,
                                                   L_valid,
                                                   L_item_master,
                                                   I_item) = FALSE
   or L_valid = FALSE then
      O_error_message := SQL_LIB.CREATE_MSG('NO_VISIBILITY', 'Item: ', I_item, NULL);
      return FALSE;
   end if;
   open C_check_item;
   fetch C_check_item into L_valid_xform_item;
   if C_CHECK_ITEM%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('INV_TSF_ITEM', NULL, NULL, NULL);
      return FALSE;
   end if;
   close C_check_item;
   if L_valid_xform_item = 'Y' then
      if ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                                  O_item_desc,
                                  I_item) = FALSE then
         return FALSE;
      end if;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;

END GET_FILTER_ITEM_INFO;
----------------------------------------------------------------------------------------------
FUNCTION TSF_XFORM_EXISTS(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                          O_xform_exist     IN OUT BOOLEAN,
                          I_tsf_no          IN     TSF_PACKING.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.TSF_XFORM_EXISTS';
   L_invalid_param        VARCHAR2(50);
   L_xform_exists         VARCHAR2(1);

   cursor C_check_xform is
      select 'Y'
        from tsf_xform
       where tsf_no = I_tsf_no;


 BEGIN
   if I_tsf_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', L_invalid_param, L_program, NULL);
      return FALSE;
   end if;
   open C_check_xform;
      fetch C_check_xform into L_xform_exists;
   close C_check_xform;
   if L_xform_exists = 'Y' then
       O_xform_exist := TRUE;
   else
      O_xform_exist := FALSE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END TSF_XFORM_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION XFORM_PACKING_EXIST(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             O_xform_exists    IN OUT BOOLEAN,
                             O_packing_exists  IN OUT BOOLEAN,
                             I_tsf_no          IN     TSFDETAIL.TSF_NO%TYPE,
                             I_item            IN     TSFDETAIL.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program            VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.XFORM_PACKING_EXIST';
   L_xform_exists       VARCHAR2(1)  := 'N';
   L_packing_exists     VARCHAR2(1)  := 'N';

   cursor C_XFORM_EXISTS is
      select 'Y'
        from tsf_xform tx,
             tsf_xform_detail txd
       where tx.tsf_no       = I_tsf_no
         and tx.tsf_xform_id = txd.tsf_xform_id
         and txd.from_item   = I_item
      UNION ALL
      select 'Y'
        from tsf_xform tx,
             tsf_xform_detail txd,
             v_packsku_qty vp
       where tx.tsf_no       = I_tsf_no
         and tx.tsf_xform_id = txd.tsf_xform_id
         and vp.pack_no      = I_item
         and vp.item         = txd.from_item;
   cursor C_PACKING_EXISTS is
      select 'Y'
        from tsf_packing tp,
             tsf_packing_detail tpd
       where tp.tsf_no         = I_tsf_no
         and tp.tsf_packing_id = tpd.tsf_packing_id
         and tpd.item          = I_item
         and tpd.record_type   = 'F'
      UNION ALL
      select 'Y'
        from tsf_packing tx,
             tsf_packing_detail txd,
             v_packsku_qty vp
       where tx.tsf_no          = I_tsf_no
         and tx.tsf_packing_id  = txd.tsf_packing_id
         and vp.pack_no         = I_item
         and vp.item            = txd.item
         and txd.record_type    = 'F'
      UNION ALL
      select 'Y'
        from tsf_packing tp,
             tsf_packing_detail tpd,
             tsf_xform tx,
             tsf_xform_detail txd
       where tp.tsf_no         = I_tsf_no
         and tx.tsf_no         = I_tsf_no
         and tp.tsf_packing_id = tpd.tsf_packing_id
         and tx.tsf_xform_id   = tx.tsf_xform_id
         and txd.from_item     = I_item
         and tpd.item          = txd.to_item
         and tpd.record_type   = 'F';
BEGIN

   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   open C_XFORM_EXISTS;
   fetch C_XFORM_EXISTS into L_xform_exists;
   close C_XFORM_EXISTS;
   if L_xform_exists = 'Y' then
      O_xform_exists := TRUE;
   else
      O_xform_exists := FALSE;
   end if;
   open C_PACKING_EXISTS;
   fetch C_PACKING_EXISTS into L_packing_exists;
   close C_PACKING_EXISTS;
   if L_packing_exists = 'Y' then
      O_packing_exists := TRUE;
   else
      O_packing_exists := FALSE;
   end if;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END XFORM_PACKING_EXIST;
---------------------------------------------------------------------------------------------------
FUNCTION FIND_SET (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                   O_set           IN OUT TSF_PACKING.SET_NO%TYPE,
                   I_item          IN     ITEM_MASTER.ITEM%TYPE,
                   I_item_type     IN     TSF_PACKING_DETAIL.RECORD_TYPE%TYPE,
                   I_tsf_no        IN     TSFHEAD.TSF_NO%TYPE)
RETURN BOOLEAN IS

   L_set TSF_PACKING.SET_NO%TYPE := -1;
   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.FIND_SET';

   CURSOR c_get_set IS
      select set_no
        from tsf_packing        tp,
             tsf_packing_detail tpd
       where tp.tsf_packing_id = tpd.tsf_packing_id
         and tp.tsf_no = I_tsf_no
         and tpd.item = I_item
         and tpd.record_type = I_item_type;

BEGIN
   open c_get_set;
   fetch c_get_set into L_set;
   if c_get_set%NOTFOUND then
     L_set := -1;
   end if;
   close c_get_set;
   O_set := L_set;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END FIND_SET;
---------------------------------------------------------------------------------------
FUNCTION DELETE_SET (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_pack_id       IN     TSF_PACKING.TSF_PACKING_ID%TYPE)
RETURN BOOLEAN IS

L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.DELETE_SET';
BEGIN
   delete from tsf_packing_detail where tsf_packing_id = I_pack_id;
   delete from tsf_packing where tsf_packing_id = I_pack_id;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_SET;
----------------------------------------------------------------------------------------
FUNCTION VALIDATE_ITEM (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                        O_exists        IN OUT BOOLEAN,
                        I_item_id       IN OUT ITEM_MASTER.ITEM%TYPE,
                        I_item_type     IN OUT TSF_PACKING_DETAIL.RECORD_TYPE%TYPE,
                        I_tsf_no        IN OUT TSF_PACKING.TSF_NO%TYPE)
RETURN BOOLEAN IS

L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.VALIDATE_ITEM';
L_return               VARCHAR2(1);
-- Dont need v_item_master because that validation will be done before this
-- function is called.
cursor C_packing_item_exist is
  select 'x'
    from tsf_packing        tp,
         tsf_packing_detail tpd
   where tp.tsf_packing_id = tpd.tsf_packing_id
     and tpd.item = I_item_id
     and tp.tsf_no = I_tsf_no
     and tpd.record_type = I_item_type;
BEGIN
   open C_packing_item_exist;
   fetch C_packing_item_exist into L_return;
   if C_packing_item_exist%FOUND then
      O_exists := TRUE;
   else
      O_exists := FALSE;
      O_error_message := 'NO_ITEM_XFER';
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END VALIDATE_ITEM;
------------------------------------------------------------------------------------------
FUNCTION DELETE_XFORM_PACK(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           I_to_item         IN     ITEM_MASTER.ITEM%TYPE,
                           I_from_item       IN     ITEM_MASTER.ITEM%TYPE,
                           I_tsf_no          IN     TSF_PACKING.TSF_NO%TYPE)
RETURN BOOLEAN IS
   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.DELETE_XFORM_PACK';
   L_tsf_packing_id       TSF_PACKING.TSF_PACKING_ID%TYPE;
   L_error_message        RTK_ERRORS.RTK_TEXT%TYPE;
   L_invalid_param        VARCHAR2(500);
   cursor C_GET_PACKING_INFO is
      select tp.set_no
        from tsf_packing_detail tpd, tsf_packing tp
       where tpd.item = I_to_item
         and tpd.record_type = 'F'
         and tpd.tsf_packing_id = tp.tsf_packing_id
         and tp.tsf_no = I_tsf_no
   UNION ALL
      select tp.set_no
        from tsf_xform tx,
             tsf_xform_detail txd,
             v_packsku_qty pi,
             tsf_packing tp,
             tsf_packing_detail tpd
       where tx.tsf_no = I_tsf_no
         and txd.from_item = I_from_item
         and tx.tsf_xform_id = txd.tsf_xform_id
         and txd.from_item = pi.item
         and pi.pack_no = tpd.item
         and tpd.record_type = 'F'
         and tp.tsf_no = tx.tsf_no;
BEGIN

   if I_to_item is NULL then
      L_invalid_param := 'I_to_item';
   elsif I_from_item is NULL then
      L_invalid_param := 'I_from_item';
   elsif I_tsf_no is NULL then
      L_invalid_param := 'I_tsf_no';
   end if;

   if L_invalid_param is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', L_invalid_param, L_program, NULL);
      return FALSE;
   end if;

   FOR C_rec IN C_GET_PACKING_INFO LOOP
      if ITEM_XFORM_PACK_SQL.DELETE_TSF_PACKING(L_error_message,
                                                I_tsf_no,
                                                C_rec.set_no) = FALSE then
         return FALSE;
      end if;
   end LOOP;
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                         SQLERRM,
                         L_program,
                         NULL);
      return FALSE;
END DELETE_XFORM_PACK;
------------------------------------------------------------------------------------------------
FUNCTION TSF_XFORM_PACK_ITEM_EXISTS(O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                    O_to_item_exist   IN OUT BOOLEAN,
                                    O_from_item_exist IN OUT BOOLEAN,
                                    I_tsf_no          IN     TSF_PACKING.TSF_NO%TYPE,
                                    I_to_item         IN     ITEM_MASTER.ITEM%TYPE,
                                    I_from_item       IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.TSF_XFORM_PACK_ITEM_EXISTS';
   L_invalid_param        VARCHAR2(50);
   L_to_item_packed       VARCHAR2(1)  := 'N';
   L_from_item_packed     VARCHAR2(1)  := 'N';

   cursor C_check_to_item is
      select 'Y'
        from tsf_packing_detail tpd, tsf_packing tp
       where tpd.item = I_to_item
         and tpd.record_type = 'F'
         and tpd.tsf_packing_id = tp.tsf_packing_id
         and tp.tsf_no = I_tsf_no;
   cursor C_check_from_item is
      select 'Y'
        from tsf_xform tx,
             tsf_xform_detail txd,
             v_packsku_qty pi,
             tsf_packing tp,
             tsf_packing_detail tpd
       where tx.tsf_no = I_tsf_no
         and txd.from_item = I_from_item
         and tx.tsf_xform_id = txd.tsf_xform_id
         and txd.from_item = pi.item
         and pi.pack_no = tpd.item
         and tpd.record_type = 'F'
         and tp.tsf_no = tx.tsf_no;


 BEGIN
   if I_tsf_no is NULL then
      L_invalid_param := 'I_tsf_no';
   elsif I_to_item is NULL then
      L_invalid_param := 'I_to_item';
   end if;

   if L_invalid_param is NOT NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL', L_invalid_param, L_program, NULL);
      return FALSE;
   end if;
   open C_check_to_item;
      fetch C_check_to_item into L_to_item_packed;
   close C_check_to_item;
   open C_check_from_item;
      fetch C_check_from_item into L_from_item_packed;
   close C_check_from_item;
   if L_to_item_packed = 'Y' then
       O_to_item_exist := TRUE;
   else
      O_to_item_exist := FALSE;
   end if;
   if L_from_item_packed = 'Y' then
      O_from_item_exist := TRUE;
   else
      O_from_item_exist := FALSE;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END TSF_XFORM_PACK_ITEM_EXISTS;
--------------------------------------------------------------------------------------------------
FUNCTION UPDATE_XFORM_QTY (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_xform_item      IN OUT TSF_XFORM_DETAIL.TO_ITEM%TYPE,
                           I_xform_tsf_no    IN     TSFDETAIL.TSF_NO%TYPE,
                           I_xform_item      IN     TSF_XFORM_DETAIL.FROM_ITEM%TYPE,
                           I_xform_qty       IN     TSF_XFORM_DETAIL.FROM_QTY%TYPE)
RETURN BOOLEAN IS
   L_program              VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.UPDATE_XFORM_QTY';
   L_tsf_xform_detail_id  TSF_XFORM_DETAIL.TSF_XFORM_DETAIL_ID%TYPE;

   L_rowid                ROWID;
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);
   cursor C_XFORM_ITEM is
      select to_item,
             tsf_xform_detail_id
        from tsf_xform_detail
       where tsf_xform_id in (select tsf_xform_id from tsf_xform where tsf_no = I_xform_tsf_no)
         and from_item = I_xform_item
      ;

   cursor C_xform_detail_lock is
      select rowid
        from tsf_xform_detail
       where tsf_xform_detail_id = L_tsf_xform_detail_id
         for update nowait;

BEGIN
   O_xform_item := NULL;
   open C_XFORM_ITEM;
   fetch C_XFORM_ITEM into O_xform_item, L_tsf_xform_detail_id;
   close C_XFORM_ITEM;
   ---
   if ( O_xform_item is not NULL ) then
      open C_xform_detail_lock;
      fetch C_xform_detail_lock into L_rowid;
      close C_xform_detail_lock;
      ---
      update tsf_xform_detail
         set from_qty = from_qty + I_xform_qty,
             to_qty   = to_qty + I_xform_qty
       where tsf_xform_detail_id = L_tsf_xform_detail_id;
   end if;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'TSF_XFORM_DETAIL',
                                             L_tsf_xform_detail_id,
                                             NULL);
   return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_XFORM_QTY;
---------------------------------------------------------------------------------------------------
FUNCTION UPDATE_XFORM_PACK_RESULT (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_tsf_no          IN     TSFDETAIL.TSF_NO%TYPE,
                                   I_item            IN     ITEM_MASTER.ITEM%TYPE,
                                   I_changed_qty     IN     TSF_PACKING_DETAIL.QTY%TYPE)
RETURN BOOLEAN IS
   L_program            VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.UPDATE_XFORM_PACK_RESULT';
   L_item               ITEM_MASTER.ITEM%TYPE;
   L_changed_qty        TSF_PACKING_DETAIL.QTY%TYPE;
   L_xform_item         TSF_XFORM_DETAIL.TO_ITEM%TYPE;
   L_is_pack            VARCHAR2(1) := 'N';
   FUNCTION_ERROR       EXCEPTION;
   cursor C_IS_PACK is
      select 'Y'
        from item_master
       where item = I_item
         and pack_ind = 'Y';
   cursor C_PACK_ITEMS is
      select item,
             qty*I_changed_qty
        from v_packsku_qty
       where pack_no = I_item;

   --------------------------------------------------------------------------------------------------
   FUNCTION UPDATE_PACK_QTY (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_pack_tsf_no     IN     TSFDETAIL.TSF_NO%TYPE,
                             I_pack_item       IN     TSF_PACKING_DETAIL.ITEM%TYPE,
                             I_pack_qty        IN     TSF_PACKING_DETAIL.QTY%TYPE)
   RETURN BOOLEAN IS
      L_program            VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.UPDATE_XFORM_PACK_RESULT.UPDATE_PACK_QTY';
      L_packing_id         TSF_PACKING.TSF_PACKING_ID%TYPE               := NULL;
      L_set_no             TSF_PACKING.SET_NO%TYPE := NULL;
      L_packing_detail_id  TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE := NULL;
      L_pack_qty           TSF_PACKING_DETAIL.QTY%TYPE                   := NULL;
      L_to_pack_no         TSF_PACKING_DETAIL.ITEM%TYPE                  := NULL;
      L_bulk_item_left     BOOLEAN := FALSE;
      L_short_qty_ind      BOOLEAN := FALSE;
      cursor C_GET_PACK_ID is
         select tp.tsf_packing_id,
                tp.set_no,
                tpd.tsf_packing_detail_id,
                tpd.qty
           from tsf_packing_detail tpd, tsf_packing tp
          where tp.tsf_no = I_pack_tsf_no
            and tpd.tsf_packing_id = tp.tsf_packing_id
            and tpd.item = I_pack_item
            and tpd.record_type = 'F'
         ;
      cursor C_BUILD_PACK is
         select tpd.item
           from tsf_packing_detail tpd, item_master im
          where tpd.tsf_packing_id = L_packing_id
            and tpd.record_type = 'R'
            and im.item = tpd.item
            and im.pack_ind = 'Y'
         ;

   BEGIN
      open C_GET_PACK_ID;
      fetch C_GET_PACK_ID into L_packing_id,
                               L_set_no,
                               L_packing_detail_id,
                               L_pack_qty;
      close C_GET_PACK_ID;
      if (L_packing_id is NULL) then
         return TRUE;
      end if;

      L_pack_qty := L_pack_qty + I_pack_qty;
      update tsf_packing_detail
         set qty = L_pack_qty
        where tsf_packing_detail_id = L_packing_detail_id;

      open C_BUILD_PACK;
      fetch C_BUILD_PACK into L_to_pack_no;
      close C_BUILD_PACK;

      --  Delete all the resultant items
      delete from tsf_packing_detail
        where tsf_packing_id = L_packing_id
          and record_type = 'R'
      ;
      --  Now recreate the resultant item by building a new pack
      --  or exploding the pack into its component items
      if ( L_to_pack_no is not null ) then
         if ( BUILD_PACK(O_error_message,
                         L_bulk_item_left,
                         L_short_qty_ind,
                         I_pack_tsf_no,
                         L_packing_id,
                         L_to_pack_no) =  FALSE) then
            ---
            if L_short_qty_ind = TRUE then
               ---
               if DELETE_TSF_PACKING(O_error_message,
                                     I_pack_tsf_no,
                                     L_set_no) = FALSE then
                  return FALSE;
               end if;
               ---
            else
               return FALSE;
            end if;
            ---
         end if;
      else
         if ( EXPLODE_PACK(O_error_message,
                           I_pack_item,
                           L_packing_id,
                           I_pack_tsf_no,
                           L_pack_qty) = FALSE ) then
            return FALSE;
         end if;
      end if;
      return TRUE;
   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               L_program,
                                               to_char(SQLCODE));
         return FALSE;
   END UPDATE_PACK_QTY;
   --------------------------------------------------------------------------------------------------
BEGIN
   SAVEPOINT SP_UPDATE_XFORM_PACK;
   open C_IS_PACK;
   fetch C_IS_PACK into L_is_pack;
   close C_IS_PACK;

   if ( L_is_pack = 'Y' ) then
      open C_PACK_ITEMS;
      loop
         fetch C_PACK_ITEMS into L_item, L_changed_qty;
         if C_PACK_ITEMS%NOTFOUND then
            exit;
         end if;
         if ( UPDATE_XFORM_QTY(O_error_message,
                               L_xform_item,
                               I_tsf_no,
                               L_item,
                               L_changed_qty) = FALSE ) then
            raise FUNCTION_ERROR;
         end if;
      end loop;

      close C_PACK_ITEMS;

      if ( UPDATE_PACK_QTY(O_error_message,
                           I_tsf_no,
                           I_item,
                           I_changed_qty) = FALSE ) then
         raise FUNCTION_ERROR;
      end if;

   else
      L_xform_item := NULL;
      if ( UPDATE_XFORM_QTY(O_error_message,
                            L_xform_item,
                            I_tsf_no,
                            I_item,
                            I_changed_qty) = FALSE ) then
         raise FUNCTION_ERROR;
      end if;

      if ( L_xform_item is NULL ) then
      -- if item transformation hasn't occured use the bulk item
         L_xform_item := I_item;
      end if;

      if ( UPDATE_PACK_QTY(O_error_message,
                           I_tsf_no,
                           L_xform_item,
                           I_changed_qty) = FALSE ) then
         raise FUNCTION_ERROR;
      end if;
   end if;
   return TRUE;
EXCEPTION
   when FUNCTION_ERROR then
      ROLLBACK TO SAVEPOINT SP_UPDATE_XFORM_PACK;
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_XFORM_PACK_RESULT;
--------------------------------------------------------------------------------------------
FUNCTION GET_XFORM_TO_ITEM(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                           O_exists         IN OUT BOOLEAN,
                           O_to_item        IN OUT ITEM_MASTER.ITEM%TYPE,
                           I_tsf_no         IN     TSFHEAD.TSF_NO%TYPE,
                           I_from_item      IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.GET_XFORM_TO_ITEM';
   cursor C_XFORM_DETAIL is
      select xd.to_item
        from tsf_xform x,
             tsf_xform_detail xd
       where x.tsf_no = I_tsf_no
         and x.tsf_xform_id = xd.tsf_xform_id
         and xd.from_item = I_from_item;
BEGIN
   open C_XFORM_DETAIL;
   fetch C_XFORM_DETAIL into O_to_item;
   if C_XFORM_DETAIL%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   close C_XFORM_DETAIL;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_XFORM_TO_ITEM;
----------------------------------------------------------------------------------------------
FUNCTION POPULATE_PACKING_FROM_ITEMS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_tsf_no         IN     TSF_PACKING.TSF_NO%TYPE,
                                     I_tsf_packing_id IN     TSF_PACKING.TSF_PACKING_ID%TYPE,
                                     I_item           IN     TSF_PACKING_DETAIL.ITEM%TYPE,
                                     I_diff_id        IN     TSF_PACKING_DETAIL.DIFF_ID%TYPE,
                                     I_qty            IN     TSF_PACKING_DETAIL.QTY%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.POPULATE_PACKING_FROM_ITEMS';
   L_item_master              ITEM_MASTER%ROWTYPE;
   L_return_code              BOOLEAN;
   L_tsf_packing_detail_id    TSF_PACKING_DETAIL.TSF_PACKING_DETAIL_ID%TYPE;

   L_rowid                    ROWID;
   RECORD_LOCKED              EXCEPTION;
   PRAGMA                     EXCEPTION_INIT(Record_Locked, -54);
   L_key                      tsf_packing_detail.item%type;
   L_sku_exist                VARCHAR2(1) := 'N';


   cursor C_children is
      select t.item  item,
             t.tsf_qty  qty
        from tsfdetail t,
             item_master im
       where t.item = im.item
         and (nvl(im.diff_1, '-1') = nvl(I_diff_id, '-1')
              or nvl(im.diff_2, '-1') = nvl(I_diff_id, '-1')
              or nvl(im.diff_3, '-1') = nvl(I_diff_id, '-1')
              or nvl(im.diff_4, '-1') = nvl(I_diff_id, '-1'))
         and t.tsf_no = I_tsf_no
         and im.item_parent = I_item
         and not exists (select 'x'
                           from tsf_xform tx,
                                tsf_xform_detail txd
                          where tx.tsf_xform_id = txd.tsf_xform_id
                            and tx.tsf_no = I_tsf_no
                            and txd.from_item = t.item)
         and not exists (select 'x'
                           from tsf_packing tp, tsf_packing_detail tpd
                          where tp.tsf_packing_id = tpd.tsf_packing_id
                            and tp.tsf_no = I_tsf_no
                            and tpd.record_type = 'F'
                            and tpd.item = t.item)
       union all
      select txd.to_item  item,
             td.tsf_qty  qty
        from tsf_xform tx,
             tsf_xform_detail txd,
             tsfdetail td
       where tx.tsf_xform_id = txd.tsf_xform_id
         and tx.tsf_no = I_tsf_no
         and tx.tsf_no = td.tsf_no
         and txd.from_item = td.item
         and txd.to_item in (select item
                               from item_master
                              where item_parent = I_item
                                and (nvl(diff_1, '-1') = nvl(I_diff_id, '-1')
                                     or nvl(diff_2, '-1') = nvl(I_diff_id, '-1')
                                     or nvl(diff_3, '-1') = nvl(I_diff_id, '-1')
                                     or nvl(diff_4, '-1') = nvl(I_diff_id, '-1')))
         and not exists (select 'x'
                           from tsf_packing tp, tsf_packing_detail tpd
                          where tp.tsf_packing_id = tpd.tsf_packing_id
                            and tp.tsf_no = I_tsf_no
                            and tpd.record_type = 'F'
                            and tpd.item = txd.to_item);

   cursor C_tpd_lock(cv_item  tsf_packing_detail.item%type) is
      select rowid
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and record_type = 'F'
         and item = cv_item
         for update nowait;

   cursor C_sku_exist(cv_item  tsf_packing_detail.item%type) is
      select 'Y'
        from tsf_packing_detail tpd
       where tpd.tsf_packing_id = I_tsf_packing_id
         and tpd.record_type = 'F'
         and (tpd.item = cv_item);

BEGIN
   ---
   if I_tsf_packing_id IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_packing_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_item_master.item_level != L_item_master.tran_level then  -- parent item
      ---
      FOR REC_children IN C_children LOOP
         ---
         L_sku_exist := 'N';
         ---
         open C_sku_exist(REC_children.item);
         fetch C_sku_exist into L_sku_exist;
         close C_sku_exist;
         ---
         if L_sku_exist = 'N' then
            ---
            if NEXT_PACKING_DETAIL_ID(O_error_message,
                                      L_return_code,
                                      L_tsf_packing_detail_id) = FALSE
                                   or L_return_code = FALSE then
               return FALSE;
            end if;
            ---
            insert into tsf_packing_detail(tsf_packing_detail_id,
                                           tsf_packing_id,
                                           record_type,
                                           item,
                                           diff_id,
                                           qty)
                                    values(L_tsf_packing_detail_id,
                                           I_tsf_packing_id,
                                           'F',
                                           REC_children.item,
                                           NULL,
                                           REC_children.qty);
            ---
         else
            ---
            L_key := REC_children.item;
            ---
            open C_tpd_lock(REC_children.item);
            fetch C_tpd_lock into L_rowid;
            close C_tpd_lock;
            ---
            update tsf_packing_detail
               set qty = qty + REC_children.qty
             where rowid = L_rowid;
            ---
         end if;
         ---
      END LOOP;
      ---
   else  --transactional item
      ---
      L_sku_exist := 'N';
      ---
      open C_sku_exist(I_item);
      fetch C_sku_exist into L_sku_exist;
      close C_sku_exist;
      ---
      if L_sku_exist = 'N' then
         ---
         if NEXT_PACKING_DETAIL_ID(O_error_message,
                                   L_return_code,
                                   L_tsf_packing_detail_id) = FALSE
                                or L_return_code = FALSE then
            return FALSE;
         end if;
         ---
         insert into tsf_packing_detail(tsf_packing_detail_id,
                                        tsf_packing_id,
                                        record_type,
                                        item,
                                        diff_id,
                                        qty)
                                 values(L_tsf_packing_detail_id,
                                        I_tsf_packing_id,
                                        'F',
                                        I_item,
                                        NULL,
                                        I_qty);
         ---
      else
         ---
         L_key := I_item;
         ---
         open C_tpd_lock(I_item);
         fetch C_tpd_lock into L_rowid;
         close C_tpd_lock;
         ---
         update tsf_packing_detail
            set qty = qty + I_qty
          where rowid = L_rowid;
         ---
      end if;
      ---
   end if;
   ---

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'TSF_PACKING_DETAIL',
                                            I_tsf_packing_id,
                                            L_key);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END POPULATE_PACKING_FROM_ITEMS;
----------------------------------------------------------------------------------------------
FUNCTION DELETE_PACKING_FROM_ITEMS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_tsf_no         IN     TSF_PACKING.TSF_NO%TYPE,
                                   I_tsf_packing_id IN     TSF_PACKING.TSF_PACKING_ID%TYPE,
                                   I_item           IN     TSF_PACKING_DETAIL.ITEM%TYPE,
                                   I_diff_id        IN     TSF_PACKING_DETAIL.DIFF_ID%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.DELETE_PACKING_FROM_ITEMS';
   L_item_master              ITEM_MASTER%ROWTYPE;

   RECORD_LOCKED              EXCEPTION;
   L_rowid                    ROWID;
   PRAGMA                     EXCEPTION_INIT(Record_Locked, -54);
   L_key                      TSF_PACKING_DETAIL.ITEM%TYPE;

   L_item_exist               BOOLEAN;

   cursor C_tpd_lock(cv_item  tsf_packing_detail.item%type) is
      select rowid
        from tsf_packing_detail
       where tsf_packing_id = I_tsf_packing_id
         and record_type = 'F'
         and item = cv_item
         for update nowait;

   cursor C_children is
      select tpd.item
        from tsf_packing_detail tpd,
             item_master im,
             tsfdetail t
       where tpd.item = im.item
         and t.item = tpd.item
         and t.tsf_no = I_tsf_no
         and (nvl(im.diff_1, '-1') = nvl(I_diff_id, '-1')
              or nvl(im.diff_2, '-1') = nvl(I_diff_id, '-1')
              or nvl(im.diff_3, '-1') = nvl(I_diff_id, '-1')
              or nvl(im.diff_4, '-1') = nvl(I_diff_id, '-1'))
         and tpd.tsf_packing_id = I_tsf_packing_id
         and tpd.record_type = 'F'
         and im.item_parent = I_item
         and not exists (select 'x'
                           from tsf_xform tx,
                                tsf_xform_detail txd
                          where tx.tsf_xform_id = txd.tsf_xform_id
                            and tx.tsf_no = I_tsf_no
                            and txd.from_item = t.item)
       union all
      select tpd.item
        from tsf_packing_detail tpd
       where tpd.tsf_packing_id = I_tsf_packing_id
         and tpd.record_type = 'F'
         and tpd.item in (select txd.to_item
                            from tsf_xform tx,
                                 tsf_xform_detail txd
                           where tx.tsf_xform_id = txd.tsf_xform_id
                             and tx.tsf_no = I_tsf_no
                             and txd.to_item in (select item
                                                   from item_master
                                                  where item_parent = I_item
                                                    and (nvl(diff_1, '-1') = nvl(I_diff_id, '-1')
                                                         or nvl(diff_2, '-1') = nvl(I_diff_id, '-1')
                                                         or nvl(diff_3, '-1') = nvl(I_diff_id, '-1')
                                                         or nvl(diff_4, '-1') = nvl(I_diff_id, '-1'))));

BEGIN
   ---
   if I_tsf_packing_id IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_packing_id',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   else
      ---
      if ITEM_VALIDATE_SQL.EXIST(O_error_message,
                                 L_item_exist,
                                 I_item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_item_exist = FALSE then
         return TRUE;
      end if;
      ---
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_item_master.item_level != L_item_master.tran_level then  -- parent item
      ---
      FOR REC_children IN C_children LOOP
         ---
         L_rowid := NULL;
         ---
         open C_tpd_lock(REC_children.item);
         fetch C_tpd_lock into L_rowid;
         close C_tpd_lock;
         ---
         L_key := REC_children.item;
         ---
         delete from tsf_packing_detail
               where rowid = L_rowid;
         ---
      END LOOP;
      ---
   else
      ---
      open C_tpd_lock(I_item);
      fetch C_tpd_lock into L_rowid;
      close C_tpd_lock;
      ---
      L_key := I_item;
      ---
      delete from tsf_packing_detail
            where rowid = L_rowid;
      ---
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'TSF_PACKING_DETAIL',
                                            I_tsf_packing_id,
                                            L_key);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_PACKING_FROM_ITEMS;
----------------------------------------------------------------------------------------------
FUNCTION POPULATE_XFORM_REQUEST(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                I_tsf_no         IN     TSFHEAD.TSF_NO%TYPE,
                                I_item           IN     TSF_XFORM_REQUEST.ITEM%TYPE,
                                I_diff_id        IN     TSF_XFORM_REQUEST.DIFF_ID%TYPE,
                                I_qty            IN     TSF_XFORM_REQUEST.QTY%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.POPULATE_XFORM_REQUEST';

   L_item_master              ITEM_MASTER%ROWTYPE;
   L_request_item_exist       VARCHAR2(1) := 'N';
   L_total_qty                TSF_XFORM_REQUEST.QTY%TYPE := 0;
   L_item_parent              ITEM_MASTER.ITEM_PARENT%TYPE;
   L_child_avail              VARCHAR2(1) := 'N';

   CURSOR C_request_item_exist(cv_item  tsf_xform_request.item%type) is
      select 'Y'
        from tsf_xform_request
       where tsf_no = I_tsf_no
         and record_type = 'F'
         and item = cv_item;

   CURSOR C_children is
      select item,
             sum(qty) qty
        from (select t.item,
                     t.tsf_qty qty
                from tsfdetail t,
                     item_master im
               where t.item = im.item
                 and t.tsf_no = I_tsf_no
                 and im.item_parent = I_item
                 and (I_diff_id is null
                      or (I_diff_id is not null and (im.diff_1 = I_diff_id
                                                     or im.diff_2 = I_diff_id
                                                     or im.diff_3 = I_diff_id
                                                     or im.diff_4 = I_diff_id)))
                 and not exists (select 'x'
                                   from tsf_xform tx,
                                        tsf_xform_detail txd
                                  where tx.tsf_xform_id = txd.tsf_xform_id
                                    and tx.tsf_no = I_tsf_no
                                    and txd.from_item = t.item
                                  union all
                                 select 'x'
                                   from tsf_packing tp,
                                        tsf_packing_detail tpd
                                  where tp.tsf_packing_id = tpd.tsf_packing_id
                                    and tp.tsf_no = I_tsf_no
                                    and tpd.item = t.item
                                    and tpd.record_type = 'F'
                                  union all
                                 select 'x'
                                   from tsf_xform_detail_temp
                                  where tsf_no = I_tsf_no
                                    and from_item = t.item)
               union all
              select v.item,
                     (t.tsf_qty * v.qty) qty
                from tsfdetail t,
                     item_master im,
                     v_packsku_qty v
               where t.tsf_no = I_tsf_no
                 and im.item_parent = I_item
                 and v.pack_no = t.item
                 and im.item = v.item
                 and (I_diff_id is null
                      or (I_diff_id is not null and (im.diff_1 = I_diff_id
                                                     or im.diff_2 = I_diff_id
                                                     or im.diff_3 = I_diff_id
                                                     or im.diff_4 = I_diff_id)))
                 and not exists (select 'x'
                                   from tsf_xform tx,
                                        tsf_xform_detail txd
                                  where tx.tsf_xform_id = txd.tsf_xform_id
                                    and tx.tsf_no = I_tsf_no
                                    and txd.from_item = v.item
                                  union all
                                 select 'x'
                                   from tsf_packing tp,
                                        tsf_packing_detail tpd
                                  where tp.tsf_packing_id = tpd.tsf_packing_id
                                    and tp.tsf_no = I_tsf_no
                                    and tpd.item = v.item
                                    and tpd.record_type = 'F'
                                  union all
                                 select 'x'
                                   from tsf_xform_detail_temp
                                  where tsf_no = I_tsf_no
                                    and from_item = v.item)) txr
    group by item;

    cursor C_no_child_avail is
       select 'Y'
         from v_tsf_xform_avail v,
              item_master im
        where im.item = v.item
          and im.item_parent = L_item_parent
          and v.tsf_no = I_tsf_no
          and not exists (select 'x'
                            from tsf_xform_request
                           where tsf_no = I_tsf_no
                             and item = v.item)
          and not exists (select 'x'
                            from tsf_xform_detail_temp
                           where tsf_no = I_tsf_no
                             and from_item = v.item);

   cursor C_available_qty(cv_item TSF_XFORM_REQUEST.ITEM%TYPE) is
      select qty
        from v_tsf_xform_avail
       where tsf_no = I_tsf_no
         and item = cv_item;

BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_item_master.item_level != L_item_master.tran_level then  -- parent item
      ---
      FOR REC_sku IN C_children LOOP
         ---
         L_request_item_exist := 'N';
         ---
         if REC_sku.item is not null then
            ---
            open C_request_item_exist(REC_sku.item);
            fetch C_request_item_exist into L_request_item_exist;
            close C_request_item_exist;
            ---
            if L_request_item_exist = 'N' then
               ---
               insert into tsf_xform_request(tsf_no,
                                             record_type,
                                             item,
                                             qty)
                                      values(I_tsf_no,
                                             'F',
                                             REC_sku.item,
                                             REC_sku.qty);
               ---
            end if;
            ---
            L_total_qty := L_total_qty + nvl(REC_sku.qty,0);
            ---
         end if;
         ---
      END LOOP;
      ---
      if I_diff_id is null then  -- the whole parent is selected, insert the parent item into request table
         ---
         L_request_item_exist := 'N';
         ---
         open C_request_item_exist(I_item);
         fetch C_request_item_exist into L_request_item_exist;
         close C_request_item_exist;
         ---
         if L_request_item_exist = 'N' then
            ---
            open C_available_qty(I_item);
            fetch C_available_qty into L_total_qty;
            close C_available_qty;
            ---
            insert into tsf_xform_request(tsf_no,
                                          record_type,
                                          item,
                                          diff_id,
                                          qty)
                                   values(I_tsf_no,
                                          'F',
                                          I_item,
                                          NULL,
                                          L_total_qty);
            ---
         end if;
         ---
      end if;
      ---
   else  -- transactional item
      ---
      L_request_item_exist := 'N';
      ---
      open C_request_item_exist(I_item);
      fetch C_request_item_exist into L_request_item_exist;
      close C_request_item_exist;
      ---
      if L_request_item_exist = 'N' then
         ---
         insert into tsf_xform_request(tsf_no,
                                       record_type,
                                       item,
                                       diff_id,
                                       qty)
                                values(I_tsf_no,
                                       'F',
                                       I_item,
                                       NULL,
                                       I_qty);
         ---
      end if;
      ---
   end if;
   ---
   -- Check to see whether all the children have been transformed/selected to be transformed,
   -- if yes, insert the parent item into the request table
   ---
   if L_item_master.item_parent is not null then
      ---
      L_item_parent := L_item_master.item_parent;
      ---
      open C_no_child_avail;
      fetch C_no_child_avail into L_child_avail;
      close C_no_child_avail;
      ---
      if L_child_avail = 'N' then
         ---
         L_request_item_exist := 'N';
         ---
         open C_request_item_exist(L_item_parent);
         fetch C_request_item_exist into L_request_item_exist;
         close C_request_item_exist;
         ---
         if L_request_item_exist = 'N' then
            ---
            open C_available_qty(L_item_parent);
            fetch C_available_qty into L_total_qty;
            close C_available_qty;
            ---
            insert into tsf_xform_request(tsf_no,
                                          record_type,
                                          item,
                                          diff_id,
                                          qty)
                                   values(I_tsf_no,
                                          'F',
                                          L_item_parent,
                                          NULL,
                                          L_total_qty);
         end if;
         ---
      end if;
      ---
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

END POPULATE_XFORM_REQUEST;
------------------------------------------------------------------------------------------------
FUNCTION DELETE_XFORM_REQUEST_ITEM(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                   I_tsf_no         IN     TSFHEAD.TSF_NO%TYPE,
                                   I_item           IN     TSF_XFORM_REQUEST.ITEM%TYPE,
                                   I_diff_id        IN     TSF_XFORM_REQUEST.DIFF_ID%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.DELETE_XFORM_REQUEST_ITEM';
   L_item_master              ITEM_MASTER%ROWTYPE;

   RECORD_LOCKED              EXCEPTION;
   L_rowid                    ROWID;
   PRAGMA                     EXCEPTION_INIT(Record_Locked, -54);
   L_key                      TSF_XFORM_REQUEST.ITEM%TYPE;

   CURSOR C_request_child_exist(cv_item  tsf_xform_request.item%type) is
      select rowid
        from tsf_xform_request
       where tsf_no = I_tsf_no
         and record_type = 'F'
         and item = cv_item;

   CURSOR C_request_item_exist(cv_item  tsf_xform_request.item%type) is
      select rowid
        from tsf_xform_request
       where tsf_no = I_tsf_no
         and record_type = 'F'
         and item = cv_item
         and (I_diff_id is null
              or (I_diff_id is not null and diff_id = I_diff_id));

   CURSOR C_children is
      select t.item
        from tsfdetail t,
             item_master im
       where t.item = im.item
         and im.item_parent = I_item
         and t.tsf_no = I_tsf_no
         and (I_diff_id is null
              or (I_diff_id is not null and (im.diff_1 = I_diff_id
                                             or im.diff_2 = I_diff_id
                                             or im.diff_3 = I_diff_id
                                             or im.diff_4 = I_diff_id)))
         and not exists (select 'x'
                           from tsf_xform tx,
                                tsf_xform_detail txd
                          where tx.tsf_xform_id = txd.tsf_xform_id
                            and tx.tsf_no = I_tsf_no
                            and txd.from_item = t.item)
         and not exists (select 'x'
                           from tsf_packing tp,
                                tsf_packing_detail tpd
                          where tp.tsf_packing_id = tpd.tsf_packing_id
                            and tp.tsf_no = I_tsf_no
                            and tpd.item = t.item
                            and tpd.record_type = 'F')
         and not exists (select 'x'
                           from tsf_xform_detail_temp
                          where tsf_no = I_tsf_no
                            and from_item = t.item)
       union
      select v.item
        from tsfdetail t,
             item_master im,
             v_packsku_qty v
       where v.pack_no = t.item
         and im.item = v.item
         and t.tsf_no = I_tsf_no
         and im.item_parent = I_item
         and (I_diff_id is null
              or (I_diff_id is not null and (im.diff_1 = I_diff_id
                                             or im.diff_2 = I_diff_id
                                             or im.diff_3 = I_diff_id
                                             or im.diff_4 = I_diff_id)))
         and not exists (select 'x'
                           from tsf_xform tx,
                                tsf_xform_detail txd
                          where tx.tsf_xform_id = txd.tsf_xform_id
                            and tx.tsf_no = I_tsf_no
                            and txd.from_item = v.item)
         and not exists (select 'x'
                           from tsf_packing tp,
                                tsf_packing_detail tpd
                          where tp.tsf_packing_id = tpd.tsf_packing_id
                            and tp.tsf_no = I_tsf_no
                            and tpd.item = v.item
                            and tpd.record_type = 'F')
         and not exists (select 'x'
                           from tsf_xform_detail_temp
                          where tsf_no = I_tsf_no
                            and from_item = v.item);
BEGIN
   ---
   if I_tsf_no IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_tsf_no',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_ITEM_MASTER(O_error_message,
                                      L_item_master,
                                      I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_item_master.item_level != L_item_master.tran_level then  -- parent item
      ---
      FOR REC_sku IN C_children LOOP
         ---
         if REC_sku.item is not null then
            ---
            open C_request_child_exist(REC_sku.item);
            fetch C_request_child_exist into L_rowid;
            close C_request_child_exist;
            ---
            L_key := REC_sku.item;
            ---
            delete from tsf_xform_request
                  where rowid = L_rowid;
            ---
         end if;
         ---
      END LOOP;
      ---
   end if;
   ---
   open C_request_item_exist(I_item);
   fetch C_request_item_exist into L_rowid;
   close C_request_item_exist;
   ---
   L_key := I_item;
   ---
   delete from tsf_xform_request
         where rowid = L_rowid;
   ---
   if L_item_master.item_parent is not null then
      ---
      open C_request_item_exist(L_item_master.item_parent);
      fetch C_request_item_exist into L_rowid;
      close C_request_item_exist;
      ---
      L_key := L_item_master.item_parent;
      ---
      delete from tsf_xform_request
            where rowid = L_rowid;
      ---
   end if;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'TSF_XFORM_REQUEST',
                                            I_tsf_no,
                                            L_key);
      return FALSE;

   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;

END DELETE_XFORM_REQUEST_ITEM;
--------------------------------------------------------------------------------------------------
FUNCTION UNIT_RETAIL_EXISTS(O_error_message  IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            O_exists         IN OUT BOOLEAN,
                            I_item           IN     ITEM_MASTER.ITEM%TYPE,
                            I_diff_id        IN     DIFF_IDS.DIFF_ID%TYPE,
                            I_loc            IN     ITEM_LOC.LOC%TYPE)
RETURN BOOLEAN IS

   L_program                  VARCHAR2(64) := 'ITEM_XFORM_PACK_SQL.UNIT_RETAIL_EXISTS';
   L_unit_retail_not_exist    VARCHAR2(1) := 'N';

   CURSOR C_unit_retail_not_exist IS
      select 'Y'
        from item_loc il,
             v_packsku_qty v
       where il.item = v.item
         and il.loc = I_loc
         and v.pack_no = I_item
         and il.unit_retail is null
       union all
      select 'Y'
        from item_loc il,
             item_master im
       where il.item = im.item
         and im.tran_level = im.item_level
         and im.pack_ind = 'N'
         and il.loc = I_loc
         and il.item = I_item
         and il.unit_retail is null
       union all
      select 'Y'
        from item_loc il,
             item_master im
       where il.item = im.item
         and im.item_parent = I_item
         and il.loc = I_loc
         and il.unit_retail is null
         and (I_diff_id is null
              or (I_diff_id is not null and (im.diff_1 = I_diff_id
                                             or im.diff_2 = I_diff_id
                                             or im.diff_3 = I_diff_id
                                             or im.diff_4 = I_diff_id)));
BEGIN
   ---
   if I_item IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_item',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   if I_loc IS NULL then
      O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                            'I_loc',
                                             L_program,
                                             NULL);
      return FALSE;
   end if;
   ---
   open C_unit_retail_not_exist;
   fetch C_unit_retail_not_exist into L_unit_retail_not_exist;
   close C_unit_retail_not_exist;
   ---
   if L_unit_retail_not_exist = 'Y' then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UNIT_RETAIL_EXISTS;
---------------------------------------------------------------------------------------------------
END ITEM_XFORM_PACK_SQL;
/

