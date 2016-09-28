CREATE OR REPLACE PACKAGE BODY DIFF_DIST_SQL AS
------------------------------------------------------------------------------
FUNCTION VALIDATE_RATIO (O_error_message   IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                         O_diff_ratio_desc IN OUT DIFF_RATIO_HEAD.DESCRIPTION%TYPE,
                         O_valid           IN OUT BOOLEAN,
                         I_diff_ratio      IN     DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE,
                         I_diff_group_1    IN     DIFF_RATIO_HEAD.DIFF_GROUP_1%TYPE)
 RETURN BOOLEAN IS

   L_dummy   VARCHAR2(1)  := 'Y';

   cursor C_VAL_RATIO is
      select 'x'
        from diff_ratio_head dh
       where dh.diff_group_1 = I_diff_group_1
         and dh.diff_group_2 is NULL
         and dh.diff_ratio_id = I_diff_ratio
         and exists( select 'x'
                       from diff_ratio_detail dd
                      where dd.diff_ratio_id = dh.diff_ratio_id );

BEGIN

   open C_VAL_RATIO;
   fetch C_VAL_RATIO into L_dummy;
   close C_VAL_RATIO;

   if L_dummy = 'Y' then
      O_error_message := SQL_LIB.CREATE_MSG('INV_DIFF_RATIO');
      O_valid := FALSE;
      return TRUE;
   else
      O_valid := TRUE;
   end if;
   ---

   if NOT DIFF_RATIO_SQL.GET_DIFF_RATIO_DESC(O_error_message,
                                             O_diff_ratio_desc,
                                             I_diff_ratio) then
      return FALSE;
   end if;


   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.VALIDATE_RATIO',
                                             to_char(SQLCODE));
      RETURN FALSE;

END VALIDATE_RATIO;
------------------------------------------------------------------------------------------------
FUNCTION VALIDATE_RATIO_STORE(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                              O_store_name    IN OUT STORE.STORE_NAME%TYPE,
                              I_diff_ratio    IN     DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE,
                              I_store         IN     STORE.STORE%TYPE)
  RETURN BOOLEAN IS

   L_dummy            VARCHAR2(1) := 'Y';



   cursor C_VALID_STORE is
      select 'x'
        from diff_ratio_detail drd,
             v_store           vstr
       where diff_ratio_id     = I_diff_ratio
         and drd.store         = I_store
         and drd.store         = vstr.store;


BEGIN
   ---
   open C_VALID_STORE;
   fetch C_VALID_STORE into L_dummy;
   close C_VALID_STORE;
   ---
   if L_dummy != 'x' then
      O_error_message := SQL_LIB.CREATE_MSG('ST_SIZE_RATIO', to_char(I_store));
      return FALSE;
   end if;
   ---
   if NOT STORE_ATTRIB_SQL.GET_NAME(O_error_message,
                                    I_store,
                                    O_store_name) then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.VALIDATE_RATIO_STORE',
                                             to_char(SQLCODE));
      RETURN FALSE;
END VALIDATE_RATIO_STORE;
------------------------------------------------------------------------------------------------
FUNCTION APPLY_RATIO(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                     I_ratio         IN     DIFF_RATIO_HEAD.DIFF_RATIO_ID%TYPE,
                     I_store         IN     DIFF_RATIO_DETAIL.STORE%TYPE)
   RETURN BOOLEAN IS

BEGIN
   update diff_apply_temp dat
      set pct = (select pct
                   from diff_ratio_detail drd
                  where drd.diff_ratio_id = I_ratio
                    and drd.diff_1 = dat.diff_id
                    and dat.status = 'A'
                    and nvl(drd.store, -999) = nvl(I_store, -999));

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.APPLY_RATIO',
                                             to_char(SQLCODE));
      RETURN FALSE;
END APPLY_RATIO;
------------------------------------------------------------------------------------------------
FUNCTION APPLY_ALL(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                   I_diff_range    IN     DIFF_RANGE_HEAD.DIFF_RANGE%TYPE)
  RETURN BOOLEAN IS

BEGIN
   update diff_apply_temp dat
      set dat.status = 'A'
    where exists (select 'x'
                    from diff_range_detail drd
                   where drd.diff_range = I_diff_range
                     and (drd.diff_1 = dat.diff_id
                          or drd.diff_2 = dat.diff_id
                          or drd.diff_3 = dat.diff_id))
       or I_diff_range is NULL;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.APPLY_ALL',
                                             to_char(SQLCODE));
      RETURN FALSE;
END APPLY_ALL;
------------------------------------------------------------------------------------------------
FUNCTION REMOVE_ALL(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE)
  RETURN BOOLEAN IS

BEGIN
   update diff_apply_temp
      set status = 'U',
          ratio = NULL,
          pct   = NULL,
          qty   = NULL;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.REMOVE_ALL',
                                             to_char(SQLCODE));
      RETURN FALSE;
END REMOVE_ALL;
------------------------------------------------------------------------------------------------
FUNCTION POP_DIFF_APPLY_TEMP(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                             I_diff_group    IN     DIFF_GROUP_HEAD.DIFF_GROUP_ID%TYPE)
  RETURN BOOLEAN IS

BEGIN
   insert into diff_apply_temp(diff_id,
                               diff_desc,
                               display_seq,
                               status,
                               qty,
                               pct,
                               ratio)
                        select dgd.diff_id,
                               di.diff_desc,
                               dgd.display_seq,
                               'U',
                               NULL,
                               NULL,
                               NULL
                          from diff_group_detail dgd,
                               diff_ids di
                         where get_user_lang = get_primary_lang
                           and dgd.diff_group_id = I_diff_group
                           and dgd.diff_id = di.diff_id
                         union all
                        select dgd.diff_id,
                               NVL(tl.translated_value, di.diff_desc),
                               dgd.display_seq,
                               'U',
                               NULL,
                               NULL,
                               NULL
                          from diff_group_detail dgd,
                               diff_ids di,
                               tl_shadow tl
                         where get_user_lang != get_primary_lang
                           and dgd.diff_group_id = I_diff_group
                           and dgd.diff_id = di.diff_id
                           and upper(di.diff_desc) = tl.key (+)
                           and get_user_lang = tl.lang (+);

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.POP_DIFF_APPLY_TEMP',
                                             to_char(SQLCODE));
      RETURN FALSE;
END POP_DIFF_APPLY_TEMP;
------------------------------------------------------------------------------------------------
FUNCTION CHECK_APPLIED_RECS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                            O_valid           IN OUT   BOOLEAN,
                            I_dist_type       IN       VARCHAR2)
   RETURN BOOLEAN IS
   L_dummy    VARCHAR2(1)           := 'Y';

   cursor C_CHECK2 is
      select 'x'
        from diff_apply_temp
       where status = 'A';

BEGIN

   open C_CHECK2;
   fetch C_CHECK2 into L_dummy;
   close C_CHECK2;

   if L_dummy != 'x' then
      O_valid := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('MUST_APPLY_DIFF');
   else
      O_valid := TRUE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.CHECK_APPLIED_RECS',
                                             to_char(SQLCODE));
      RETURN FALSE;
END CHECK_APPLIED_RECS;
------------------------------------------------------------------------------------------------
FUNCTION INSERT_UPDATE_ORDER_RECS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_dist_uom_type IN     VARCHAR2,
                                  I_sum_ratio     IN     NUMBER,
                                  I_dist_type     IN     VARCHAR2,
                                  I_dist_uom      IN     UOM_CLASS.UOM%TYPE,
                                  I_purch_uom     IN     UOM_CLASS.UOM%TYPE,
                                  I_where_clause  IN     FILTER_TEMP.WHERE_CLAUSE%TYPE,
                                  I_order_no      IN     ORDHEAD.ORDER_NO%TYPE,
                                  I_diff_no       IN     NUMBER)
   RETURN BOOLEAN IS

   L_sum_ratio              VARCHAR2(30);
   L_condition              VARCHAR2(500);
   L_diff_select_statement  VARCHAR2(500);
   L_diff_where_statement   VARCHAR2(500);
   L_qty_string             VARCHAR2(500);
   L_calc_qty_string        VARCHAR2(500);
   L_act_qty_string         VARCHAR2(500);
   L_wksht_qty_string       VARCHAR2(500);
   L_statement              VARCHAR2(2000);

BEGIN

   --Ensure that only applied diffs are used.
   L_condition := 'and diff_apply_temp.status = ''A'' ';

   --If the dist_uom_type is 'C', the unit of purchase must be case.
   --If the dist_uom_type is either 'S'UOM or 'E'aches, the uop
   --may be either the SUOM or case.  If the uop is case and the dist_uom_type
   --is either 'S' or 'E', quantity entered by the user should be divided by the
   --supp_pack_size.
   ---
   L_sum_ratio := to_char(I_sum_ratio);

   if I_dist_uom_type = 'C' then
   ---
      if I_dist_type = 'Q' then
         L_qty_string := 'diff_apply_temp.qty ';
      elsif I_dist_type = 'R' then
         L_qty_string := '((diff_apply_temp.ratio * ordloc_wksht.wksht_qty)/ '||L_sum_ratio||')';
      elsif I_dist_type = 'P' then
         L_qty_string := '((diff_apply_temp.pct * ordloc_wksht.wksht_qty)/100) ';
      end if;
         --
      L_wksht_qty_string := 'ROUND('||L_qty_string||')';
      L_calc_qty_string := '('||L_qty_string ||' * ordloc_wksht.supp_pack_size)';
      L_act_qty_string := '('||L_wksht_qty_string ||' * ordloc_wksht.supp_pack_size)';
   else
      ---
      if I_dist_uom = I_purch_uom then
      ---
         if I_dist_type = 'Q' then
            L_qty_string := 'diff_apply_temp.qty ';
         elsif I_dist_type = 'R' then
            L_qty_string := '((diff_apply_temp.ratio * ordloc_wksht.wksht_qty)/ '||L_sum_ratio||')';
         elsif I_dist_type = 'P' then
            L_qty_string := '((diff_apply_temp.pct * ordloc_wksht.wksht_qty)/100) ';
         end if;
         ---
         L_wksht_qty_string := 'ROUND(('||L_qty_string||'))';
         L_calc_qty_string := L_qty_string;
         L_act_qty_string := L_qty_string;
         ---
      elsif I_dist_uom != I_purch_uom then
         ---
         if I_dist_type = 'Q' then
            L_qty_string := 'diff_apply_temp.qty ';
         elsif I_dist_type = 'R' then
            L_qty_string := '((diff_apply_temp.ratio * ordloc_wksht.act_qty)/ '||L_sum_ratio||')';
         elsif I_dist_type = 'P' then
            L_qty_string := '((diff_apply_temp.pct * ordloc_wksht.act_qty)/100) ';
         end if;
         ---
         L_wksht_qty_string := 'ROUND(('||L_qty_string||')/ordloc_wksht.supp_pack_size)';
         L_calc_qty_string := L_qty_string;
         L_act_qty_string := L_qty_string;
         ---
      end if;
      ---
   end if;
   ---
   if I_dist_type = 'R' then
      ---
      if UPDATE_OBJECT_SQL.UPDATE_ORDER_DIFF(O_error_message,
                                             I_order_no,
                                             I_dist_type,
                                             L_sum_ratio,
                                             I_where_clause,
                                             I_dist_uom_type,
                                             I_diff_no) = FALSE then
         return FALSE;
      end if;
      ---
   else
      ---
      if UPDATE_OBJECT_SQL.UPDATE_ORDER_DIFF(O_error_message,
                                             I_order_no,
                                             I_dist_type,
                                             NULL,
                                             I_where_clause,
                                             I_dist_uom_type,
                                             I_diff_no) = FALSE then
         return FALSE;
      end if;
      ---
   end if;
   ---

   if I_diff_no = 1 then
      L_diff_select_statement := 'diff_apply_temp.diff_id, ' ||
                                 'ordloc_wksht.diff_2, '||
                                 'ordloc_wksht.diff_3, '||
                                 'ordloc_wksht.diff_4, ';
      L_diff_where_statement  := 'and o2.diff_1 = diff_apply_temp.diff_id '||
                                 'and nvl(o2.diff_2, -1) = nvl(ordloc_wksht.diff_2, -1) '||
                                 'and nvl(o2.diff_3, -1) = nvl(ordloc_wksht.diff_3, -1) '||
                                 'and nvl(o2.diff_4, -1) = nvl(ordloc_wksht.diff_4, -1))';
   elsif I_diff_no = 2 then
      L_diff_select_statement := 'ordloc_wksht.diff_1, ' ||
                                 'diff_apply_temp.diff_id, '||
                                 'ordloc_wksht.diff_3, '||
                                 'ordloc_wksht.diff_4, ';
      L_diff_where_statement  := 'and nvl(o2.diff_1, -1) = nvl(ordloc_wksht.diff_1, -1) '||
                                 'and o2.diff_2 = diff_apply_temp.diff_id '||
                                 'and nvl(o2.diff_3, -1) = nvl(ordloc_wksht.diff_3, -1) '||
                                 'and nvl(o2.diff_4, -1) = nvl(ordloc_wksht.diff_4, -1))';
   elsif I_diff_no = 3 then
      L_diff_select_statement := 'ordloc_wksht.diff_1, ' ||
                                 'ordloc_wksht.diff_2, '||
                                 'diff_apply_temp.diff_id, '||
                                 'ordloc_wksht.diff_4, ';
      L_diff_where_statement  := 'and nvl(o2.diff_1, -1) = nvl(ordloc_wksht.diff_1, -1) '||
                                 'and nvl(o2.diff_2, -1) = nvl(ordloc_wksht.diff_2, -1) '||
                                 'and o2.diff_3 = diff_apply_temp.diff_id '||
                                 'and nvl(o2.diff_4, -1) = nvl(ordloc_wksht.diff_4, -1))';
   elsif I_diff_no = 4 then
      L_diff_select_statement := 'ordloc_wksht.diff_1, ' ||
                                 'ordloc_wksht.diff_2, '||
                                 'ordloc_wksht.diff_3, '||
                                 'diff_apply_temp.diff_id, ';
      L_diff_where_statement  := 'and nvl(o2.diff_1, -1) = nvl(ordloc_wksht.diff_1, -1) '||
                                 'and nvl(o2.diff_2, -1) = nvl(ordloc_wksht.diff_2, -1) '||
                                 'and nvl(o2.diff_3, -1) = nvl(ordloc_wksht.diff_3, -1) '||
                                 'and o2.diff_4 = diff_apply_temp.diff_id)';

   end if;

   L_statement := 'insert into ordloc_wksht(order_no, '||
                                            'item_parent, '||
                                            'item, '||
                                            'ref_item, '||
                                            'diff_1, '||
                                            'diff_2, '||
                                            'diff_3, '||
                                            'diff_4, '||
                                            'store_grade, '||
                                            'store_grade_group_id, '||
                                            'loc_type, '||
                                            'location, '||
                                            'calc_qty, '||
                                            'act_qty, '||
                                            'standard_uom, '||
                                            'variance_qty, '||
                                            'origin_country_id, '||
                                            'wksht_qty, '||
                                            'uop, '||
                                            'supp_pack_size) '||
                                     'select ordloc_wksht.order_no, '||
                                            'ordloc_wksht.item_parent, '||
                                            'ordloc_wksht.item, '||
                                            'ordloc_wksht.ref_item, '||
                                            L_diff_select_statement ||
                                            'ordloc_wksht.store_grade, '||
                                            'ordloc_wksht.store_grade_group_id, '||
                                            'ordloc_wksht.loc_type, '||
                                            'ordloc_wksht.location, '||
                                            L_calc_qty_string ||',' ||
                                            L_act_qty_string ||',' ||
                                            'ordloc_wksht.standard_uom, '||
                                            0 ||',' ||
                                            'ordloc_wksht.origin_country_id, '||
                                            L_wksht_qty_string||',' ||
                                            'ordloc_wksht.uop, ' ||
                                            'ordloc_wksht.supp_pack_size '||
                       'from ordloc_wksht, diff_apply_temp '||
                      'where ordloc_wksht.order_no = :I_order_no '||
                             I_where_clause||' '||
                             L_condition ||
                        'and not exists (select ''x'' ' ||
                                         ' from ordloc_wksht o2 ' ||
                                         'where o2.order_no = ordloc_wksht.order_no ' ||
                                           'and nvl(o2.store_grade_group_id,-1) = nvl(ordloc_wksht.store_grade_group_id,-1) ' ||
                                           'and nvl(o2.store_grade,-1) = nvl(ordloc_wksht.store_grade,-1) ' ||
                                           'and nvl(o2.loc_type,-1) = nvl(ordloc_wksht.loc_type,-1) ' ||
                                           'and nvl(o2.location,-1) = nvl(ordloc_wksht.location,-1) ' ||
                                           'and nvl(o2.item_parent,-1) = nvl(ordloc_wksht.item_parent,-1) ' ||
                                                L_diff_where_statement;

   EXECUTE IMMEDIATE L_statement USING I_order_no;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.INSERT_UPDATE_ORDER_RECS',
                                             to_char(SQLCODE));
      RETURN FALSE;
END INSERT_UPDATE_ORDER_RECS;
------------------------------------------------------------------------------------------------
FUNCTION INSERT_UPDATE_CONTRACT_RECS(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                     I_sum_ratio     IN     NUMBER,
                                     I_dist_type     IN     VARCHAR2,
                                     I_where_clause  IN     FILTER_TEMP.WHERE_CLAUSE%TYPE,
                                     I_contract_no   IN     CONTRACT_HEADER.CONTRACT_NO%TYPE,
                                     I_diff_no       IN     NUMBER)
   RETURN BOOLEAN IS

   L_sum_ratio              VARCHAR2(30);
   L_condition              VARCHAR2(500) := NULL;
   L_diff_select_statement  VARCHAR2(500) := NULL;
   L_diff_where_statement   VARCHAR2(500) := NULL;
   L_qty_select_statement   VARCHAR2(500) := NULL;
   L_qty_where_statement    VARCHAR2(500) := NULL;
   L_qty_string             VARCHAR2(500) := NULL;
   L_calc_qty_string        VARCHAR2(500) := NULL;
   L_act_qty_string         VARCHAR2(500) := NULL;
   L_var_qty_string         VARCHAR2(500) := NULL;
   L_wksht_qty_string       VARCHAR2(500) := NULL;
   L_statement              VARCHAR2(2000) := NULL;

BEGIN

   if I_diff_no = 1 then
      L_diff_select_statement := 'diff_apply_temp.diff_id, ' ||
                                 'contract_matrix_temp.diff_2, '||
                                 'contract_matrix_temp.diff_3, '||
                                 'contract_matrix_temp.diff_4, ';
      L_diff_where_statement  := 'and c2.diff_1 = diff_apply_temp.diff_id '||
                                 'and nvl(c2.diff_2, -1) = nvl(contract_matrix_temp.diff_2, -1) '||
                                 'and nvl(c2.diff_3, -1) = nvl(contract_matrix_temp.diff_3, -1) '||
                                 'and nvl(c2.diff_4, -1) = nvl(contract_matrix_temp.diff_4, -1))';
   elsif I_diff_no = 2 then
      L_diff_select_statement := 'contract_matrix_temp.diff_1, ' ||
                                 'diff_apply_temp.diff_id, '||
                                 'contract_matrix_temp.diff_3, '||
                                 'contract_matrix_temp.diff_4, ';
      L_diff_where_statement  := 'and nvl(c2.diff_1, -1) = nvl(contract_matrix_temp.diff_1, -1) '||
                                 'and c2.diff_2 = diff_apply_temp.diff_id '||
                                 'and nvl(c2.diff_3, -1) = nvl(contract_matrix_temp.diff_3, -1) '||
                                 'and nvl(c2.diff_4, -1) = nvl(contract_matrix_temp.diff_4, -1))';
   elsif I_diff_no = 3 then
      L_diff_select_statement := 'contract_matrix_temp.diff_1, ' ||
                                 'contract_matrix_temp.diff_2, '||
                                 'diff_apply_temp.diff_id, '||
                                 'contract_matrix_temp.diff_4, ';
      L_diff_where_statement  := 'and nvl(c2.diff_1, -1) = nvl(contract_matrix_temp.diff_1, -1) '||
                                 'and nvl(c2.diff_2, -1) = nvl(contract_matrix_temp.diff_2, -1) '||
                                 'and c2.diff_3 = diff_apply_temp.diff_id '||
                                 'and nvl(c2.diff_4, -1) = nvl(contract_matrix_temp.diff_4, -1))';
   elsif I_diff_no = 4 then
      L_diff_select_statement := 'contract_matrix_temp.diff_1, ' ||
                                 'contract_matrix_temp.diff_2, '||
                                 'contract_matrix_temp.diff_3, '||
                                 'diff_apply_temp.diff_id, ';
      L_diff_where_statement  := 'and nvl(c2.diff_1, -1) = nvl(contract_matrix_temp.diff_1, -1) '||
                                 'and nvl(c2.diff_2, -1) = nvl(contract_matrix_temp.diff_2, -1) '||
                                 'and nvl(c2.diff_3, -1) = nvl(contract_matrix_temp.diff_3, -1) '||
                                 'and c2.diff_4 = diff_apply_temp.diff_id)';

   end if;

   if I_dist_type = 'R' then
      L_sum_ratio := I_sum_ratio;
   else
      L_sum_ratio := NULL;
   end if;

   if I_dist_type = 'Q' then
      L_qty_select_statement := 'diff_apply_temp.qty, ';
   elsif I_dist_type = 'P' then
      L_qty_select_statement := 'ROUND((contract_matrix_temp.qty*diff_apply_temp.pct)/100), ';
      L_qty_where_statement := 'and diff_apply_temp.pct > 0 ';
   elsif I_dist_type = 'R' then
      L_qty_select_statement := 'ROUND((contract_matrix_temp.qty/'||to_char(I_sum_ratio)||')*diff_apply_temp.ratio), ';
      L_qty_where_statement := 'and diff_apply_temp.ratio > 0 ';
   else
      L_qty_select_statement := 'ROUND(contract_matrix_temp.qty), ';
   end if;


   if UPDATE_OBJECT_SQL.UPDATE_CONTRACT_DIFF(O_error_message,
                                             I_contract_no,
                                             I_dist_type,
                                             L_sum_ratio,
                                             I_where_clause,
                                             I_diff_no) = FALSE then
      return FALSE;
   end if;

   L_statement := 'insert into contract_matrix_temp(contract_no, ' ||
                                                    'item_grandparent, ' ||
                                                    'item_parent, ' ||
                                                    'item, ' ||
                                                    'ref_item, ' ||
                                                    'diff_1, ' ||
                                                    'diff_2, ' ||
                                                    'diff_3, ' ||
                                                    'diff_4, ' ||
                                                    'loc_type, ' ||
                                                    'location, ' ||
                                                    'ready_date, ' ||
                                                    'qty, ' ||
                                                    'unit_cost) '||
                   'select contract_matrix_temp.contract_no, ' ||
                          'contract_matrix_temp.item_grandparent, '||
                          'contract_matrix_temp.item_parent, '||
                          'contract_matrix_temp.item, '||
                          'contract_matrix_temp.ref_item, '||
                           L_diff_select_statement ||
                          'contract_matrix_temp.loc_type, '||
                          'contract_matrix_temp.location, '||
                          'contract_matrix_temp.ready_date, '||
                           L_qty_select_statement ||
                          'contract_matrix_temp.unit_cost '||
                     'from contract_matrix_temp, diff_apply_temp '||
                    'where contract_matrix_temp.contract_no = :I_contract_no '||
                           I_where_clause||' '||
                      'and diff_apply_temp.status = ''A'' '||
                           L_qty_where_statement ||' '||
                      'and not exists (select ''x'' ' ||
                                       ' from contract_matrix_temp c2 ' ||
                                       'where c2.contract_no = contract_matrix_temp.contract_no ' ||
                                         'and (c2.item_grandparent = contract_matrix_temp.item_grandparent or '||
                                              'c2.item_parent = contract_matrix_temp.item_parent) '||
                                         'and nvl(c2.loc_type,-1) = nvl(contract_matrix_temp.loc_type,-1) '||
                                         'and nvl(c2.location,-1) = nvl(contract_matrix_temp.location,-1) '||
                                         'and (c2.ready_date = contract_matrix_temp.ready_date or ' ||
                                             '(c2.ready_date is NULL and contract_matrix_temp.ready_date is NULL)) '||
                                          L_diff_where_statement;
   EXECUTE IMMEDIATE L_statement USING I_contract_no;
   return TRUE;
   ---
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.INSERT_UPDATE_CONTRACT_RECS',
                                             to_char(SQLCODE));
      RETURN FALSE;
END INSERT_UPDATE_CONTRACT_RECS;
------------------------------------------------------------------------------------------------
FUNCTION DELETE_TEMP_TABLES(O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_order_no      IN     ORDHEAD.ORDER_NO%TYPE,
                            I_contract_no   IN     CONTRACT_HEADER.CONTRACT_NO%TYPE,
                            I_pack_tmpl_id  IN     PACK_TMPL_HEAD.PACK_TMPL_ID%TYPE,
                            I_diff_no       IN     NUMBER,
                            I_where_clause  IN     FILTER_TEMP.WHERE_CLAUSE%TYPE)
 RETURN BOOLEAN IS

   L_statement          VARCHAR2(2000);
   L_table              VARCHAR2(30);
   L_diff_where_clause  VARCHAR2(200);
   L_where_clause       FILTER_TEMP.WHERE_CLAUSE%TYPE;
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);
   L_error_1            VARCHAR2(30);
   L_error_2            VARCHAR2(30);

   cursor C_LOCK_TEMP_PACK_TMPL is
      select 'x'
        from temp_pack_tmpl
       where pack_tmpl_id = I_pack_tmpl_id
         and selected_ind = 'Y'
         for update nowait;

BEGIN
   ---
   if I_pack_tmpl_id is NOT NULL then
      L_table := 'TEMP_PACK_TMPL';
      open C_LOCK_TEMP_PACK_TMPL;
      close C_LOCK_TEMP_PACK_TMPL;
      L_error_1 := to_char(I_pack_tmpl_id);
      L_error_2 := 'selected_ind = Y';
      ---
      delete from temp_pack_tmpl
       where pack_tmpl_id = I_pack_tmpl_id
         and selected_ind = 'Y';
      ---
   elsif I_order_no is NOT NULL then

      if not ORDER_SETUP_SQL.LOCK_ORDHEAD(O_error_message,
                                          I_order_no) then
         return FALSE;
      end if;
      ---
      if I_where_clause is not NULL then
         L_where_clause := 'and '||I_where_clause;
      else
         L_where_clause := I_where_clause;
      end if;
      ---
      L_diff_where_clause := 'and ordloc_wksht.diff_'||I_diff_no||' is NULL ';
      ---
      L_statement := 'delete from ordloc_wksht ' ||
                      'where ordloc_wksht.order_no = :I_order_no ' ||
                             L_diff_where_clause ||
                             L_where_clause;
      EXECUTE IMMEDIATE L_statement USING I_order_no;
   else

      if not CONTRACT_SQL.LOCK_CONTRACT (O_error_message,
                                         I_contract_no) then
         return FALSE;
      end if;
      ---
      if I_where_clause is not NULL then
         L_where_clause := 'and '||I_where_clause;
      else
         L_where_clause := I_where_clause;
      end if;
      ---
      L_diff_where_clause := 'and contract_matrix_temp.diff_'||I_diff_no||' is NULL ';
      ---
      L_statement := 'delete from contract_matrix_temp ' ||
                      'where contract_matrix_temp.contract_no = :I_contract_no ' ||
                             L_diff_where_clause ||
                             L_where_clause;
      EXECUTE IMMEDIATE L_statement USING I_contract_no;
   end if;
   ---
   delete from diff_apply_temp;

   return TRUE;
EXCEPTION
  when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             L_error_1,
                                             L_error_2);
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'DIFF_DIST_SQL.DELETE_TEMP_TABLES',
                                             to_char(SQLCODE));
      RETURN FALSE;
END DELETE_TEMP_TABLES;
-----------------------------------------------------------------------------------
FUNCTION DELETE_ORDDIST_ITEM_TEMP(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_order             IN     ORDHEAD.ORDER_NO%TYPE,
                                  I_contract          IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
RETURN BOOLEAN IS

BEGIN
   delete from orddist_item_temp
    where order_no = I_order
       or contract_no = I_contract;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ORDER_DIST_SQL.DELETE_ORDDIST_ITEM_TEMP',
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_ORDDIST_ITEM_TEMP;
-------------------------------------------------------------------------------
FUNCTION CREATE_NEW_DIFF_CHILDREN(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                  I_order             IN     ORDHEAD.ORDER_NO%TYPE,
                                  I_contract          IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
RETURN BOOLEAN IS

BEGIN

   insert into item_temp(item,
                         item_number_type,
                         item_level,
                         item_desc,
                         diff_1,
                         diff_2,
                         diff_3,
                         diff_4,
                         existing_item_parent)
                  select item,
                         item_number_type,
                         item_level,
                         item_desc,
                         diff_1,
                         diff_2,
                         diff_3,
                         diff_4,
                         item_parent
                    from orddist_item_temp
                   where (order_no = I_order or
                          contract_no = I_contract)
                     and item is NOT NULL
                     and NOT exists (select 'x'
                                       from item_master
                                      where orddist_item_temp.item = item_master.item);

   if NOT ITEM_CREATE_SQL.TRAN_CHILDREN(O_error_message,
                                        'Y',
                                        'Y') then
      return FALSE;
   end if;

   if DIFF_APPLY_SQL.CLEAR_TEMP_TABLE(O_error_message,
                                      'ALL') = FALSE then
      return FALSE;
   end if;


   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ORDER_DIST_SQL.CREATE_NEW_DIFF_CHILDREN',
                                            to_char(SQLCODE));
      return FALSE;
END CREATE_NEW_DIFF_CHILDREN;
-------------------------------------------------------------------------------
FUNCTION DELETE_PARENT_DIFF(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_order             IN     ORDHEAD.ORDER_NO%TYPE,
                            I_contract          IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
RETURN BOOLEAN IS

BEGIN
   if I_order is NOT NULL then
      delete from ordloc_wksht ow
       where order_no = I_order
         and exists (select 'x'
                       from orddist_item_temp oit
                      where oit.order_no = ow.order_no
                        and oit.item_parent = ow.item_parent
                        and (oit.diff_1 = ow.diff_1 or
                             (oit.diff_1 is NULL and ow.diff_1 is NULL))
                        and (oit.diff_2 = ow.diff_2 or
                             (oit.diff_2 is NULL and ow.diff_2 is NULL))
                        and (oit.diff_3 = ow.diff_3 or
                             (oit.diff_3 is NULL and ow.diff_3 is NULL))
                        and (oit.diff_4 = ow.diff_4 or
                             (oit.diff_4 is NULL and ow.diff_4 is NULL)));
   else
      delete from contract_matrix_temp cmt
       where contract_no = I_contract
         and exists (select 'x'
                       from orddist_item_temp oit
                      where oit.contract_no = cmt.contract_no
                        and oit.item_parent = cmt.item_parent
                        and (oit.diff_1 = cmt.diff_1 or
                             (oit.diff_1 is NULL and cmt.diff_1 is NULL))
                        and (oit.diff_2 = cmt.diff_2 or
                             (oit.diff_2 is NULL and cmt.diff_2 is NULL))
                        and (oit.diff_3 = cmt.diff_3 or
                             (oit.diff_3 is NULL and cmt.diff_3 is NULL))
                        and (oit.diff_4 = cmt.diff_4 or
                             (oit.diff_4 is NULL and cmt.diff_4 is NULL)));
   end if;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ORDER_DIST_SQL.DELETE_PARENT_DIFF',
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_PARENT_DIFF;
--------------------------------------------------------------------------------------
FUNCTION ORDDIST_ITEM_TEMP_EXIST(O_error_message     IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                                 O_exist             IN OUT BOOLEAN,
                                 I_order             IN     ORDHEAD.ORDER_NO%TYPE,
                                 I_contract          IN     CONTRACT_HEADER.CONTRACT_NO%TYPE,
                                 I_item              IN     ORDDIST_ITEM_TEMP.ITEM%TYPE)
RETURN BOOLEAN IS

   L_dummy    VARCHAR2(1)  := 'Y';

   cursor C_CHECK is
      select 'x'
        from orddist_item_temp
       where (order_no = I_order or
             contract_no = I_contract)
         and item = I_item;

BEGIN
   open C_CHECK;
   fetch C_CHECK into L_dummy;
   close C_CHECK;

   if L_dummy = 'x' then
      O_exist := TRUE;
   else
      O_exist := FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            'ORDER_DIST_SQL.ORDDIST_ITEM_TEMP_EXIST',
                                            to_char(SQLCODE));
      return FALSE;
END ORDDIST_ITEM_TEMP_EXIST;
-----------------------------------------------------------------------------------------
END;
/

