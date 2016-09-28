CREATE OR REPLACE PACKAGE BODY CONTRACT_DIST_SQL AS
---------------------------------------------------------------------------------------------
-- Function Name: VALIDATE_DIFF
-- Purpose:       Validates the diffs before distributing the contract.
--
FUNCTION VALIDATE_DIFF(O_error_message  IN OUT  VARCHAR2,
                       O_qty_ind        IN OUT  VARCHAR2,
                       I_diff_no        IN      NUMBER,
                       I_diff_group     IN      V_DIFF_ID_GROUP_TYPE.ID_GROUP%TYPE,
                       I_contract       IN      CONTRACT_HEADER.CONTRACT_NO%TYPE,
                       I_where_clause   IN      FILTER_TEMP.WHERE_CLAUSE%TYPE)
   return BOOLEAN IS
      L_cursor1         INTEGER;
      L_rows_processed  INTEGER;
      L_tot_recs        NUMBER(4);
      L_tot_qty_recs    NUMBER(4);
      L_where_clause    FILTER_TEMP.WHERE_CLAUSE%TYPE;
   BEGIN
      if I_contract is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                               'I_CONTRACT',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      if I_diff_no is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                               'I_DIFF_NO',
                                               'NULL',
                                               'NOT NULL');
         return FALSE;
      end if;
      L_where_clause := I_where_clause;
      if L_where_clause is NOT NULL then
         L_where_clause := ' and '||L_where_clause;
      end if;
      ---
      --- Check for records with transaction level items. If any exist, return false.
      ---
      L_cursor1 := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(L_cursor1, 'select item from contract_matrix_temp where item is not NULL and contract_no = '|| to_char(I_contract) ||
                     L_where_clause,
                     DBMS_SQL.V7);
      L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
      --- Evaluate if rows are returned.
      if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
         O_error_message := ('NO_DIFF_CNTR_TRANLVL_ITEM');
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
         return FALSE;
      end if;
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      ---
      if I_diff_no = 1 then
         --- Check for records that have diff. 1 already distributed. If so, return false.
         ---
         L_cursor1 := DBMS_SQL.OPEN_CURSOR;
         DBMS_SQL.PARSE(L_cursor1, 'select contract_matrix_temp.diff_1 '||
                                    ' from contract_matrix_temp, v_diff_id_group_type v '||
                                   ' where contract_matrix_temp.diff_1 is not NULL    '||
                                     ' and contract_matrix_temp.diff_1 = v.id_group   '||
                                     ' and v.id_group_ind = ''ID'' '||
                                     ' and contract_matrix_temp.contract_no = '|| to_char(I_contract) ||
                        L_where_clause,
                        DBMS_SQL.V7);
         L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
         --- Evaluate if rows are returned.
         if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
            O_error_message := ('STYLES_DISTR_COLOR');
            DBMS_SQL.CLOSE_CURSOR(L_cursor1);
            return FALSE;
         end if;
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
         --- Check for records that have a items using a different diff group than specified. If so, return false.
         ---
         L_cursor1 := DBMS_SQL.OPEN_CURSOR;
         DBMS_SQL.PARSE(L_cursor1,
                        'select ''x'' '||
                        '  from contract_matrix_temp, v_diff_id_group_type v, item_master im '||
                        ' where contract_matrix_temp.diff_1 is NULL    '||
                        '   and nvl(contract_matrix_temp.item_parent, contract_matrix_temp.item_grandparent) = im.item '||
                        '   and im.diff_1      = v.id_group '||
                        '   and v.id_group_ind = ''GROUP'' '||
                        '   and v.id_group    != '''|| I_diff_group ||''' '||
                        '   and contract_matrix_temp.contract_no  = '|| to_char(I_contract) ||
                        L_where_clause,
                        DBMS_SQL.V7);
         L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
         --- Evaluate if rows are returned.
         if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
            O_error_message := ('DIFF_DISTR_MULTI_GROUPS');
            DBMS_SQL.CLOSE_CURSOR(L_cursor1);
            return FALSE;
         end if;
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);

      elsif I_diff_no = 2 then
         --- Check for records that have diff. 2 already distributed. If so, return false.
         ---
         L_cursor1 := DBMS_SQL.OPEN_CURSOR;
         DBMS_SQL.PARSE(L_cursor1, 'select contract_matrix_temp.diff_2 '||
                                    ' from contract_matrix_temp, v_diff_id_group_type v '||
                                   ' where contract_matrix_temp.diff_2 is not NULL    '||
                                     ' and contract_matrix_temp.diff_2 = v.id_group   '||
                                     ' and v.id_group_ind = ''ID'' '||
                                     ' and contract_matrix_temp.contract_no = '|| to_char(I_contract) ||
                        L_where_clause,
                        DBMS_SQL.V7);
         L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
         --- Evaluate if rows are returned.
         if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
            O_error_message := ('STYLES_DISTR_COLOR');
            DBMS_SQL.CLOSE_CURSOR(L_cursor1);
            return FALSE;
         end if;
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
         --- Check for records that have a items using a different diff group than specified. If so, return false.
         ---
         L_cursor1 := DBMS_SQL.OPEN_CURSOR;
         DBMS_SQL.PARSE(L_cursor1,
                        'select ''x'' '||
                        '  from contract_matrix_temp, v_diff_id_group_type v, item_master im '||
                        ' where contract_matrix_temp.diff_2 is NULL    '||
                        '   and nvl(contract_matrix_temp.item_parent, contract_matrix_temp.item_grandparent) = im.item '||
                        '   and im.diff_2      = v.id_group '||
                        '   and v.id_group_ind = ''GROUP'' '||
                        '   and v.id_group    != '''|| I_diff_group ||''' '||
                        '   and contract_matrix_temp.contract_no  = '|| to_char(I_contract) ||
                        L_where_clause,
                        DBMS_SQL.V7);
         L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
         --- Evaluate if rows are returned.
         if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
            O_error_message := ('DIFF_DISTR_MULTI_GROUPS');
            DBMS_SQL.CLOSE_CURSOR(L_cursor1);
            return FALSE;
         end if;
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      elsif I_diff_no = 3 then
         --- Check for records that have diff. 3 already distributed. If so, return false.
         ---
         L_cursor1 := DBMS_SQL.OPEN_CURSOR;
         DBMS_SQL.PARSE(L_cursor1, 'select contract_matrix_temp.diff_3 '||
                                    ' from contract_matrix_temp, v_diff_id_group_type v '||
                                   ' where contract_matrix_temp.diff_3 is not NULL    '||
                                     ' and contract_matrix_temp.diff_3 = v.id_group   '||
                                     ' and v.id_group_ind = ''ID'' '||
                                     ' and contract_matrix_temp.contract_no = '|| to_char(I_contract) ||
                        L_where_clause,
                        DBMS_SQL.V7);
         L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
         --- Evaluate if rows are returned.
         if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
            O_error_message := ('STYLES_DISTR_COLOR');
            DBMS_SQL.CLOSE_CURSOR(L_cursor1);
            return FALSE;
         end if;
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
         --- Check for records that have a items using a different diff group than specified. If so, return false.
         ---
         L_cursor1 := DBMS_SQL.OPEN_CURSOR;
         DBMS_SQL.PARSE(L_cursor1,
                        'select ''x'' '||
                        '  from contract_matrix_temp, v_diff_id_group_type v, item_master im '||
                        ' where contract_matrix_temp.diff_3 is NULL    '||
                        '   and nvl(contract_matrix_temp.item_parent, contract_matrix_temp.item_grandparent) = im.item '||
                        '   and im.diff_3      = v.id_group '||
                        '   and v.id_group_ind = ''GROUP'' '||
                        '   and v.id_group    != '''|| I_diff_group ||''' '||
                        '   and contract_matrix_temp.contract_no  = '|| to_char(I_contract) ||
                        L_where_clause,
                        DBMS_SQL.V7);
         L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
         --- Evaluate if rows are returned.
         if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
            O_error_message := ('DIFF_DISTR_MULTI_GROUPS');
            DBMS_SQL.CLOSE_CURSOR(L_cursor1);
            return FALSE;
         end if;
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      elsif I_diff_no = 4 then
         --- Check for records that have diff. 4 already distributed. If so, return false.
         ---
         L_cursor1 := DBMS_SQL.OPEN_CURSOR;
         DBMS_SQL.PARSE(L_cursor1, 'select contract_matrix_temp.diff_4 '||
                                    ' from contract_matrix_temp, v_diff_id_group_type v '||
                                   ' where contract_matrix_temp.diff_4 is not NULL    '||
                                     ' and contract_matrix_temp.diff_4 = v.id_group   '||
                                     ' and v.id_group_ind = ''ID'' '||
                                     ' and contract_matrix_temp.contract_no = '|| to_char(I_contract) ||
                        L_where_clause,
                        DBMS_SQL.V7);
         L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
         --- Evaluate if rows are returned.
         if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
            O_error_message := ('STYLES_DISTR_COLOR');
            DBMS_SQL.CLOSE_CURSOR(L_cursor1);
            return FALSE;
         end if;
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
         --- Check for records that have a items using a different diff group than specified. If so, return false.
         ---
         L_cursor1 := DBMS_SQL.OPEN_CURSOR;
         DBMS_SQL.PARSE(L_cursor1,
                        'select ''x'' '||
                        '  from contract_matrix_temp, v_diff_id_group_type v, item_master im '||
                        ' where contract_matrix_temp.diff_4 is NULL    '||
                        '   and nvl(contract_matrix_temp.item_parent, contract_matrix_temp.item_grandparent) = im.item '||
                        '   and im.diff_4      = v.id_group '||
                        '   and v.id_group_ind = ''GROUP'' '||
                        '   and v.id_group    != '''|| I_diff_group ||''' '||
                        '   and contract_matrix_temp.contract_no  = '|| to_char(I_contract) ||
                        L_where_clause,
                        DBMS_SQL.V7);
         L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
         --- Evaluate if rows are returned.
         if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
            O_error_message := ('DIFF_DISTR_MULTI_GROUPS');
            DBMS_SQL.CLOSE_CURSOR(L_cursor1);
            return FALSE;
         end if;
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      end if;
      ---
      --- Check for all or no records having quantities. If so, return false.
      L_cursor1 := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(L_cursor1, 'select count (*) from contract_matrix_temp where contract_no = '|| to_char(I_contract) ||
                     L_where_clause,
                     DBMS_SQL.V7);
      DBMS_SQL.DEFINE_COLUMN(L_cursor1, 1, L_tot_recs);
      L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
      if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
         DBMS_SQL.COLUMN_VALUE(L_cursor1, 1, L_tot_recs);
      end if;
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      ---
      L_cursor1 := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(L_cursor1, 'select count (*) from contract_matrix_temp where qty > 0 and contract_no = '|| to_char(I_contract) ||
                     L_where_clause,
                     DBMS_SQL.V7);
      DBMS_SQL.DEFINE_COLUMN(L_cursor1, 1, L_tot_qty_recs);
      L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
      if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
         DBMS_SQL.COLUMN_VALUE(L_cursor1, 1, L_tot_qty_recs);
      end if;
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      --- Evaluating if both cursors return the same number of rows and L_tot_qty_recs is not zero. If not return false.
      if L_tot_recs != L_tot_qty_recs and L_tot_qty_recs != 0 then
         O_error_message := ('INV_DIST_QTY');
         return FALSE;
      end if;
      ---
      --- Set quantity indicator to yes if all records contain quantities.
      if L_tot_recs = L_tot_qty_recs and L_tot_qty_recs > 0 then
         O_qty_ind := 'Y';
      else
         O_qty_ind := 'N';
      end if;
      ---
      return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'CONTRACT_DIST_SQL.VALIDATE_DIFF',
                                             to_char(SQLCODE));
      DBMS_SQL.close_cursor(L_cursor1);
      return FALSE;
END VALIDATE_DIFF;
--------------------------------------------------------------------------------------------
-- Function_Name: VALIDATE_DATE
-- Purpose:       Validates the filter criteria for dates before distributing the contract.
--
FUNCTION VALIDATE_DATE(O_error_message  IN OUT  VARCHAR2,
                       I_contract       IN      CONTRACT_HEADER.CONTRACT_NO%TYPE,
                       I_where_clause   IN      FILTER_TEMP.WHERE_CLAUSE%TYPE)
   return BOOLEAN is
      L_cursor1         INTEGER;
      L_rows_processed  INTEGER;
      L_where_clause    FILTER_TEMP.WHERE_CLAUSE%TYPE := I_where_clause;
   BEGIN
      L_where_clause := I_where_clause;
      if L_where_clause is not NULL then
         L_where_clause := ' and '||L_where_clause;
      end if;
      ---
      --- Check for records that have dates that have already been distributed. If so, return false.
      L_cursor1 := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(L_cursor1, 'select ready_date from contract_matrix_temp where ready_date is not NULL and contract_no = '|| to_char(I_contract) ||
                     L_where_clause,
                     DBMS_SQL.V7);
      L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
      --- Evaluate if rows are returned.
      if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
         O_error_message := ('DATES_DISTR');
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
         return FALSE;
      end if;
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      ---
      --- Check for all records having quantities. If not, return false.
      L_cursor1 := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(L_cursor1, 'select qty from contract_matrix_temp where (qty is NULL or qty = 0) and contract_no = '|| to_char(I_contract) ||
                     L_where_clause,
                     DBMS_SQL.V7);
      L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
      if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
         O_error_message := ('INV_DATE_DIST_QTY');
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
         return FALSE;
      end if;
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      ---
      return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'CONTRACT_DIST_SQL.VALIDATE_DATE',
                                             to_char(SQLCODE));
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      return FALSE;
END VALIDATE_DATE;
-----------------------------------------------------------------------------------------------
-- Function Name: VALIDATE_LOCATION
-- Purpose:       Validates the filter criteria for locations before distributing the contract.
--
FUNCTION VALIDATE_LOCATION(O_error_message  IN OUT  VARCHAR2,
                           O_qty_ind        IN OUT  VARCHAR2,
                           I_contract       IN      CONTRACT_HEADER.CONTRACT_NO%TYPE,
                           I_complete_ind   IN      VARCHAR2,
                           I_where_clause   IN      FILTER_TEMP.WHERE_CLAUSE%TYPE)
   return BOOLEAN is
      L_cursor1         INTEGER;
      L_rows_processed  INTEGER;
      L_tot_recs        NUMBER(4);
      L_tot_qty_recs    NUMBER(4);
      L_where_clause    FILTER_TEMP.WHERE_CLAUSE%TYPE;
   BEGIN
      L_where_clause := I_where_clause;
      if L_where_clause is not NULL then
         L_where_clause := ' and '||L_where_clause;
      end if;
      ---
      --- Check for records that have locations that have already been distributed. If so, return false.
      L_cursor1 := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(L_cursor1, 'select location from contract_matrix_temp where location is not NULL and contract_no = '|| to_char(I_contract) ||
                     L_where_clause,
                     DBMS_SQL.V7);
      L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
      --- Evaluate if rows are returned */
      if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
         O_error_message := ('LOC_DISTR');
         DBMS_SQL.CLOSE_CURSOR(L_cursor1);
         return FALSE;
      end if;
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      --- Check for all records having quantities. If not, return false.
      L_cursor1 := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(L_cursor1, 'select count (*) from contract_matrix_temp where contract_no = '|| to_char(I_contract) ||
                     L_where_clause,
                     DBMS_SQL.V7);
      DBMS_SQL.DEFINE_COLUMN(L_cursor1, 1, L_tot_recs);
      L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
      if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
         DBMS_SQL.COLUMN_VALUE(L_cursor1, 1, L_tot_recs);
      end if;
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      ---
      L_cursor1 := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(L_cursor1, 'select count (*) from contract_matrix_temp where qty > 0 and contract_no = '|| to_char(I_contract) ||
                     L_where_clause,
                     DBMS_SQL.V7);
      DBMS_SQL.DEFINE_COLUMN(L_cursor1, 1, L_tot_qty_recs);
      L_rows_processed := DBMS_SQL.EXECUTE(L_cursor1);
      if DBMS_SQL.FETCH_ROWS(L_cursor1) > 0 then
         DBMS_SQL.COLUMN_VALUE(L_cursor1, 1, L_tot_qty_recs);
      end if;
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      --- Evaluating if both cursors return the same number of rows and L_tot_qty_recs is not zero.
      if L_tot_recs != L_tot_qty_recs and L_tot_qty_recs != 0 then
         O_error_message := ('INV_DIST_QTY');
         return FALSE;
      end if;
      ---
      --- Set quantity indicator to yes if all records contain quantities */
      if L_tot_recs = L_tot_qty_recs and L_tot_qty_recs > 0 then
         O_qty_ind := 'Y';
      else
         O_qty_ind := 'N';
      end if;
      ---
      return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG( 'PACKAGE_ERROR',
                                             SQLERRM,
                                             'CONTRACT_DIST_SQL.VALIDATE_LOCATION',
                                             to_char(SQLCODE));
      DBMS_SQL.CLOSE_CURSOR(L_cursor1);
      return FALSE;
END VALIDATE_LOCATION;
---------------------------------------------------------------------------------------------
FUNCTION POP_DETAIL_COST(O_error_message       IN OUT  VARCHAR2,
                         O_qty_increased_ind   IN OUT  BOOLEAN,
                         O_diff_cost_ind       IN OUT  BOOLEAN,
                         I_contract_no         IN      CONTRACT_HEADER.CONTRACT_NO%TYPE,
                         I_contract_type       IN      CONTRACT_HEADER.CONTRACT_TYPE%TYPE,
                         I_mode                IN      VARCHAR2,
                         I_calling_form        IN      VARCHAR2,
                         I_supplier            IN      ITEM_SUPPLIER.SUPPLIER%TYPE)
   return BOOLEAN is
      C_CURSOR             INTEGER;
      L_dummy              INTEGER;
      L_text               VARCHAR2(9000)                    := NULL;
      L_where_clause       FILTER_TEMP.WHERE_CLAUSE%TYPE     := NULL;
      L_max_seq_no         CONTRACT_DETAIL.SEQ_NO%TYPE;
      L_contract_rate      CURRENCY_RATES.EXCHANGE_RATE%TYPE;
      L_dec                CURRENCIES.CURRENCY_COST_DEC%TYPE;
      L_sups_rate          CURRENCY_RATES.EXCHANGE_RATE%TYPE;
      L_supplier_currency  CURRENCIES.CURRENCY_CODE%TYPE;
      L_contract_currency  CURRENCIES.CURRENCY_CODE%TYPE;
      L_currency_cost_fmt  CURRENCIES.CURRENCY_COST_FMT%TYPE;
      L_country_id         CONTRACT_HEADER.COUNTRY_ID%TYPE;
      ---
      cursor C_GET_DETAIL_WHERE is
         select where_clause
           from filter_temp
          where form_name = 'CNTRDETL'
            and unique_key = I_contract_no;

      cursor C_GET_DETAIL_SEQ_NO is
         select nvl(max(seq_no), 0)
           from contract_detail
          where contract_no = I_contract_no;

      cursor C_GET_COST_SEQ_NO is
         select nvl(max(seq_no), 0)
           from contract_cost
          where contract_no = I_contract_no;

      cursor C_INSERT_TRAN_LEVEL_ITEM_CC is
            select distinct m.item,
                   m.item_parent,
                   m.item_grandparent,
                   i.unit_cost,
                   m.diff_1,
                   m.diff_2,
                   m.diff_3,
                   m.diff_4
              from contract_matrix_temp m,
                   item_supp_country i
             where m.item               = i.item
               and i.supplier           = I_supplier
               and i.origin_country_id  = L_country_id
               and m.contract_no        = I_contract_no
               and not exists(select 'x'
                               from contract_cost c
                              where c.contract_no     = I_contract_no
                               and c.item             = m.item
                               and c.item_level_index = 1);

      cursor C_INSERT_PARENT_CC is
            /* This cursor will select based only on the item parent. The selection
               of the item grandparent is for reference purposes only. */
            select distinct m.item_grandparent,
                   m.item_parent,
                   i.unit_cost,
                   m.diff_1,
                   m.diff_2,
                   m.diff_3,
                   m.diff_4
              from contract_matrix_temp m,
                   item_supp_country i
             where m.item_parent       = i.item
               and m.item is null
               and i.supplier          = I_supplier
               and i.origin_country_id = L_country_id
               and m.contract_no       = I_contract_no
               and not exists (select 'x'
                               from contract_cost c
                              where c.contract_no      = I_contract_no
                                and c.item_parent      = m.item_parent
                                and c.item            is NULL
                                and (c.diff_1         = m.diff_1
                                     or c.diff_1      is NULL)
                                and (c.diff_2         = m.diff_2
                                  or c.diff_2         is NULL)
                                and (c.diff_3         = m.diff_3
                                  or c.diff_3         is NULL)
                                and (c.diff_4         = m.diff_4
                                  or c.diff_4         is NULL));

      cursor C_INSERT_GRANDPARENT_CC is
            select distinct m.item_grandparent,
                   i.unit_cost,
                   m.diff_1,
                   m.diff_2,
                   m.diff_3,
                   m.diff_4
              from contract_matrix_temp m,
                   item_supp_country i
             where m.item_grandparent  = i.item
               and m.item is null
               and i.supplier          = I_supplier
               and i.origin_country_id = L_country_id
               and m.contract_no       = I_contract_no
               and not exists(select 'x'
                               from contract_cost c
                              where c.contract_no      = I_contract_no
                                and c.item_grandparent = m.item_grandparent
                                and c.item            is NULL
                                and (c.diff_1          = m.diff_1
                                  or c.diff_1         is NULL)
                                and (c.diff_2          = m.diff_2
                                  or c.diff_2         is NULL)
                                and (c.diff_3          = m.diff_3
                                  or c.diff_3         is NULL)
                                and (c.diff_4          = m.diff_4
                                  or c.diff_4         is NULL));

      cursor C_CONTRACT_CURRENCY is
         select cu.currency_cost_dec,
                c.currency_code,
                cu.currency_cost_fmt,
                c.country_id
           from contract_header c,
                currencies cu
          where c.currency_code = cu.currency_code
            and c.contract_no   = I_contract_no;

      cursor C_UPDATE_CONTRACT_DETAIL is
        select ((d.qty_contracted) + nvl(m.qty, 0)) qty, m.ready_date
          from contract_matrix_temp m, contract_detail d
         where d.contract_no = m.contract_no
           and d.contract_no = I_contract_no
           and (    d.item_grandparent  = m.item_grandparent
                or (d.item_grandparent is NULL and m.item_grandparent is NULL))
           and (    d.item_parent       = m.item_parent
                or (d.item_parent      is NULL and m.item_parent      is NULL))
           and (    d.item              = m.item
                or (d.item             is NULL and m.item             is NULL))
           and (    d.diff_1            = m.diff_1
                or (d.diff_1           is NULL and m.diff_1           is NULL))
           and (    d.diff_2            = m.diff_2
                or (d.diff_2           is NULL and m.diff_2           is NULL))
           and (    d.diff_3            = m.diff_3
                or (d.diff_3           is NULL and m.diff_3           is NULL))
           and (    d.diff_4            = m.diff_4
                or (d.diff_4           is NULL and m.diff_4           is NULL))
           and (    d.loc_type          = m.loc_type
                or (d.loc_type         is NULL and m.loc_type         is NULL))
           and (    d.location          = m.location
                or (d.location         is NULL and m.location         is NULL))
           and (    d.ready_date        = m.ready_date
                or (d.ready_date       is NULL and m.ready_date       is NULL));
   BEGIN
      -- get the currency rate for the contract/supplier
      SQL_LIB.SET_MARK('OPEN', 'C_CONTRACT_CURRENCY', 'SUPS',
                       'contract_no: '||to_char(I_contract_no));
      open C_CONTRACT_CURRENCY;
      SQL_LIB.SET_MARK('FETCH', 'C_CONTRACT_CURRENCY', 'SUPS',
                       'contract_no: '||to_char(I_contract_no));
      fetch C_CONTRACT_CURRENCY into L_dec,
                                     L_contract_currency,
                                     L_currency_cost_fmt,
                                     L_country_id;
      SQL_LIB.SET_MARK('CLOSE', 'C_CONTRACT_CURRENCY', 'SUPS',
                       'contract_no: '||to_char(I_contract_no));
      close C_CONTRACT_CURRENCY;
      ---
      --Retrieve the exchange rate for the contract's currency code.
      if CURRENCY_SQL.GET_RATE(O_error_message,
                               L_contract_rate,
                               L_contract_currency,
                               NULL,
                               NULL) = FALSE then
         return FALSE;
      end if;
      ---
      --Retrieve currency code for the contract supplier.
      if CURRENCY_SQL.GET_CURR_LOC(O_error_message,
                                   I_supplier,
                                   'V',
                                   NULL,
                                   L_supplier_currency) = FALSE then
         return FALSE;
      end if;
      ---
      --Retrieve the exchange rate for the contract supplier currency code.
      if CURRENCY_SQL.GET_RATE(O_error_message,
                               L_sups_rate,
                               L_supplier_currency,
                               NULL,
                               NULL) = FALSE then
         return FALSE;
      end if;
      ---
      if I_calling_form = 'CNTRDETL' then
         ---
         if I_mode = 'EDIT' then
            SQL_LIB.SET_MARK('OPEN', 'C_GET_DETAIL_WHERE', 'CONTRACT_DETAIL',
                             'contract_no: '||to_char(I_contract_no));
            open C_GET_DETAIL_WHERE;
            SQL_LIB.SET_MARK('FETCH', 'C_GET_DETAIL_WHERE', 'CONTRACT_DETAIL',
                             'contract_no: '||to_char(I_contract_no));
            fetch C_GET_DETAIL_WHERE into L_where_clause;
            SQL_LIB.SET_MARK('CLOSE', 'C_GET_DETAIL_WHERE', 'CONTRACT_DETAIL',
                             'contract_no: '||to_char(I_contract_no));
            close C_GET_DETAIL_WHERE;
            ---
            if L_where_clause is not NULL then
               L_where_clause := ' and '||L_where_clause;
            end if;
            ---
            L_text := 'delete from contract_detail where contract_no = '||to_char(I_contract_no)||L_where_clause||';';
            ---
            if EXECUTE_SQL.EXECUTE_SQL(O_error_message,
                                       L_text) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_DETAIL_SEQ_NO', 'CONTRACT_DETAIL',
                          'contract_no: '||to_char(I_contract_no));
         open C_GET_DETAIL_SEQ_NO;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_DETAIL_SEQ_NO', 'CONTRACT_DETAIL',
                          'contract_no: '||to_char(I_contract_no));
         fetch C_GET_DETAIL_SEQ_NO into L_max_seq_no;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_DETAIL_SEQ_NO', 'CONTRACT_DETAIL',
                          'contract_no: '||to_char(I_contract_no));
         close C_GET_DETAIL_SEQ_NO;
         ---
         for contract_detail_rec in C_UPDATE_CONTRACT_DETAIL loop
         -- update the contract_detail table with additional information from contract_matrix_temp
            update contract_detail d
               set qty_contracted = contract_detail_rec.qty
             where d.contract_no = I_contract_no
               and d.seq_no in
                   (select d.seq_no
                      from contract_detail d, contract_matrix_temp m
                    where d.contract_no = I_contract_no
                      and d.contract_no = m.contract_no
                      and (    d.item_grandparent  = m.item_grandparent
                           or (d.item_grandparent is NULL and m.item_grandparent is NULL))
                      and (    d.item_parent       = m.item_parent
                           or (d.item_parent      is NULL and m.item_parent      is NULL))
                      and (    d.item              = m.item
                           or (d.item             is NULL and m.item             is NULL))
                      and (    d.diff_1            = m.diff_1
                           or (d.diff_1           is NULL and m.diff_1           is NULL))
                      and (    d.diff_2            = m.diff_2
                           or (d.diff_2           is NULL and m.diff_2           is NULL))
                      and (    d.diff_3            = m.diff_3
                           or (d.diff_3           is NULL and m.diff_3           is NULL))
                      and (    d.diff_4            = m.diff_4
                           or (d.diff_4           is NULL and m.diff_4           is NULL))
                      and (    d.loc_type          = m.loc_type
                           or (d.loc_type         is NULL and m.loc_type         is NULL))
                      and (    d.location          = m.location
                           or (d.location         is NULL and m.location         is NULL))
                      and (    d.ready_date        = m.ready_date
                           or (d.ready_date       is NULL and m.ready_date       is NULL))
                      and (    d.ready_date       is NULL
                           or  d.ready_date        = contract_detail_rec.ready_date));
            O_qty_increased_ind := TRUE;
         end loop;
         ---
         -- insert new records into the contract_detail table
         insert into contract_detail(contract_no,
                                     seq_no,
                                     item_grandparent,
                                     item_parent,
                                     item,
                                     ref_item,
                                     diff_1,
                                     diff_2,
                                     diff_3,
                                     diff_4,
                                     loc_type,
                                     location,
                                     ready_date,
                                     qty_contracted,
                                     qty_ordered,
                                     qty_received,
                                     item_level_index,
                                     cur_repl_qty)
            select I_contract_no,
                   (ROWNUM + L_max_seq_no),
                   m.item_grandparent,
                   m.item_parent,
                   m.item,
                   m.ref_item,
                   m.diff_1,
                   m.diff_2,
                   m.diff_3,
                   m.diff_4,
                   m.loc_type,
                   m.location,
                   m.ready_date,
                   nvl(m.qty,0),
                   NULL,
                   NULL,
                   decode(m.item, NULL,
                      decode(m.diff_4, decode(m.diff_4, im.diff_4, m.diff_4, NULL, m.diff_4, NULL),
                         decode(m.diff_3, decode(m.diff_3, im.diff_3, m.diff_3, NULL, m.diff_3, NULL),
                            decode(m.diff_2, decode(m.diff_2, im.diff_2, m.diff_2, NULL, m.diff_2, NULL),
                               decode(m.diff_1, decode(m.diff_1, im.diff_1, m.diff_1, NULL, m.diff_1, NULL), 6, 2),
                            3),
                         4),
                      5),
                   1),
                   /* logic for decoding the item level index
                         if item is NULL
                            if diff_4 is NULL
                               parent/no diff. level = 6
                               if diff_3 is NULL
                                  parent/no diff level = 5
                                  if diff_2 is NULL
                                     parent/no diff level = 4
                                     if diff_1 is NULL
                                        parent/no diff. level = 3
                                     else
                                        parent/diff. 1 level  = 2
                                  else
                                     parent/diff. 2 level  = 3
                               else
                                  parent/diff. 3 level  = 4
                            else
                               parent/diff. 4 level  = 5
                         else transaction level item level = 1 */
                   NULL
              from contract_matrix_temp m, item_master im
             where m.contract_no = I_contract_no
               and im.item       = nvl(m.item, nvl(m.item_parent, m.item_grandparent))
               and not exists (select 'x'
                                from contract_detail d
                               where d.contract_no = I_contract_no
                                 and (    d.item_grandparent  = m.item_grandparent
                                      or (d.item_grandparent is NULL and m.item_grandparent is NULL))
                                 and (    d.item_parent       = m.item_parent
                                      or (d.item_parent      is NULL and m.item_parent      is NULL))
                                 and (    d.item              = m.item
                                      or (d.item             is NULL and m.item             is NULL))
                                 and (    d.diff_1            = m.diff_1
                                      or (d.diff_1           is NULL and m.diff_1           is NULL))
                                 and (    d.diff_2            = m.diff_2
                                      or (d.diff_2           is NULL and m.diff_2           is NULL))
                                 and (    d.diff_3            = m.diff_3
                                      or (d.diff_3           is NULL and m.diff_3           is NULL))
                                 and (    d.diff_4            = m.diff_4
                                      or (d.diff_4           is NULL and m.diff_4           is NULL))
                                 and (    d.loc_type          = m.loc_type
                                      or (d.loc_type         is NULL and m.loc_type         is NULL))
                                 and (    d.location          = m.location
                                      or (d.location         is NULL and m.location         is NULL))
                                 and (    d.ready_date        = m.ready_date
                                      or (d.ready_date       is NULL and m.ready_date       is NULL)));
         ---
         SQL_LIB.SET_MARK('OPEN', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         open C_GET_COST_SEQ_NO;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         fetch C_GET_COST_SEQ_NO into L_max_seq_no;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         close C_GET_COST_SEQ_NO;
         ---
         -- insert transaction level item records into the contract_cost table
         for tran_level_rec in C_INSERT_TRAN_LEVEL_ITEM_CC LOOP
            L_max_seq_no := L_max_seq_no + 1;
            insert into contract_cost(contract_no,
                                      seq_no,
                                      item_grandparent,
                                      item_parent,
                                      item,
                                      diff_1,
                                      diff_2,
                                      diff_3,
                                      diff_4,
                                      unit_cost,
                                      item_level_index)
               values (I_contract_no,
                       L_max_seq_no,
                       tran_level_rec.item_grandparent,
                       tran_level_rec.item_parent,
                       tran_level_rec.item,
                       tran_level_rec.diff_1,
                       tran_level_rec.diff_2,
                       tran_level_rec.diff_3,
                       tran_level_rec.diff_4,
                       ROUND(tran_level_rec.unit_cost * L_contract_rate/L_sups_rate, L_dec),
                       1);
         end LOOP;
         ---
         FOR parent_rec in C_INSERT_PARENT_CC LOOP
            /* Insert item parent into the contract_cost table. The selection
               of the item grandparent is for reference purposes only. */

           insert into contract_cost(contract_no,
                                     seq_no,
                                     item_grandparent,
                                     item_parent,
                                     item,
                                     diff_1,
                                     diff_2,
                                     diff_3,
                                     diff_4,
                                     unit_cost,
                                     item_level_index)
            select I_contract_no,
                   (ROWNUM + L_max_seq_no),
                   parent_rec.item_grandparent,
                   parent_rec.item_parent,
                   NULL, --- item
                   parent_rec.diff_1,
                   parent_rec.diff_2,
                   parent_rec.diff_3,
                   parent_rec.diff_4,
                   ROUND(parent_rec.unit_cost * L_contract_rate/L_sups_rate, L_dec),
                   decode(m.item, NULL,
                      decode(m.diff_4, decode(m.diff_4, im.diff_4, m.diff_4, NULL, m.diff_4, NULL),
                         decode(m.diff_3, decode(m.diff_3, im.diff_3, m.diff_3, NULL, m.diff_3, NULL),
                            decode(m.diff_2, decode(m.diff_2, im.diff_2, m.diff_2, NULL, m.diff_2, NULL),
                               decode(m.diff_1, decode(m.diff_1, im.diff_1, m.diff_1, NULL, m.diff_1, NULL), 6, 2),
                            3),
                         4),
                      5),
                   1)
                   /* logic for decoding the item level index
                         if item is NULL
                            if diff_4 is NULL
                               parent/no diff. level = 6
                               if diff_3 is NULL
                                  parent/no diff level = 5
                                  if diff_2 is NULL
                                     parent/no diff level = 4
                                     if diff_1 is NULL
                                        parent/no diff. level = 3
                                     else
                                        parent/diff. 1 level  = 2
                                  else
                                     parent/diff. 2 level  = 3
                               else
                                  parent/diff. 3 level  = 4
                            else
                               parent/diff. 4 level  = 5
                         else transaction level item level = 1 */
              from contract_matrix_temp m, item_master im
             where m.contract_no = I_contract_no
               and m.item_parent = im.item
               and (m.diff_1 = parent_rec.diff_1
                   or (m.diff_1 IS NULL AND parent_rec.diff_1 IS NULL))
               and (m.diff_2 = parent_rec.diff_2
                   or (m.diff_2 IS NULL AND parent_rec.diff_2 IS NULL))
               and (m.diff_3 = parent_rec.diff_3
                   or (m.diff_3 IS NULL AND parent_rec.diff_3 IS NULL))
               and (m.diff_4 = parent_rec.diff_4
                   or (m.diff_4 IS NULL AND parent_rec.diff_4 IS NULL))
               and not exists (select 'x'
                                from contract_cost c
                               where c.contract_no = I_contract_no
                                 and (    c.item_grandparent  = m.item_grandparent
                                      or (c.item_grandparent is NULL and m.item_grandparent is NULL))
                                 and (    c.item_parent       = m.item_parent
                                      or (c.item_parent      is NULL and m.item_parent      is NULL))
                                 and (    c.item              = m.item
                                      or (c.item             is NULL and m.item             is NULL))
                                 and (    c.diff_1            = m.diff_1
                                      or (c.diff_1           is NULL and m.diff_1           is NULL))
                                 and (    c.diff_2            = m.diff_2
                                      or (c.diff_2           is NULL and m.diff_2           is NULL))
                                 and (    c.diff_3            = m.diff_3
                                      or (c.diff_3           is NULL and m.diff_3           is NULL))
                                 and (    c.diff_4            = m.diff_4
                                      or (c.diff_4           is NULL and m.diff_4           is NULL)))
               and rownum = 1;
         L_max_seq_no := L_max_seq_no + 1;
         end LOOP;
         ---
         FOR grandparent_rec in C_INSERT_GRANDPARENT_CC LOOP

           insert into contract_cost(contract_no,
                                     seq_no,
                                     item_grandparent,
                                     item_parent,
                                     item,
                                     diff_1,
                                     diff_2,
                                     diff_3,
                                     diff_4,
                                     unit_cost,
                                     item_level_index)
            select I_contract_no,
                   (ROWNUM + L_max_seq_no),
                   grandparent_rec.item_grandparent,
                   NULL, --- item_parent
                   NULL, --- item
                   grandparent_rec.diff_1,
                   grandparent_rec.diff_2,
                   grandparent_rec.diff_3,
                   grandparent_rec.diff_4,
                   ROUND(grandparent_rec.unit_cost * L_contract_rate/L_sups_rate, L_dec),
                   decode(m.item, NULL,
                      decode(m.diff_4, decode(m.diff_4, im.diff_4, m.diff_4, NULL, m.diff_4, NULL),
                         decode(m.diff_3, decode(m.diff_3, im.diff_3, m.diff_3, NULL, m.diff_3, NULL),
                            decode(m.diff_2, decode(m.diff_2, im.diff_2, m.diff_2, NULL, m.diff_2, NULL),
                               decode(m.diff_1, decode(m.diff_1, im.diff_1, m.diff_1, NULL, m.diff_1, NULL), 6, 2),
                            3),
                         4),
                      5),
                   1)
                   /* logic for decoding the item level index
                         if item is NULL
                            if diff_4 is NULL
                               parent/no diff. level = 6
                               if diff_3 is NULL
                                  parent/no diff level = 5
                                  if diff_2 is NULL
                                     parent/no diff level = 4
                                     if diff_1 is NULL
                                        parent/no diff. level = 3
                                     else
                                        parent/diff. 1 level  = 2
                                  else
                                     parent/diff. 2 level  = 3
                               else
                                  parent/diff. 3 level  = 4
                            else
                               parent/diff. 4 level  = 5
                         else transaction level item level = 1 */
              from contract_matrix_temp m, item_master im
             where m.contract_no = I_contract_no
               and m.item_grandparent = im.item
               and (m.diff_1 = grandparent_rec.diff_1
                   or (m.diff_1 IS NULL AND grandparent_rec.diff_1 IS NULL))
               and (m.diff_2 = grandparent_rec.diff_2
                   or (m.diff_2 IS NULL AND grandparent_rec.diff_2 IS NULL))
               and (m.diff_3 = grandparent_rec.diff_3
                   or (m.diff_3 IS NULL AND grandparent_rec.diff_3 IS NULL))
               and (m.diff_4 = grandparent_rec.diff_4
                   or (m.diff_4 IS NULL AND grandparent_rec.diff_4 IS NULL))
               and not exists (select 'x'
                                from contract_cost c
                               where c.contract_no = I_contract_no
                                 and (    c.item_grandparent  = m.item_grandparent
                                      or (c.item_grandparent is NULL and m.item_grandparent is NULL))
                                 and (    c.item_parent       = m.item_parent
                                      or (c.item_parent      is NULL and m.item_parent      is NULL))
                                 and (    c.item              = m.item
                                      or (c.item             is NULL and m.item             is NULL))
                                 and (    c.diff_1            = m.diff_1
                                      or (c.diff_1           is NULL and m.diff_1           is NULL))
                                 and (    c.diff_2            = m.diff_2
                                      or (c.diff_2           is NULL and m.diff_2           is NULL))
                                 and (    c.diff_3            = m.diff_3
                                      or (c.diff_3           is NULL and m.diff_3           is NULL))
                                 and (    c.diff_4            = m.diff_4
                                      or (c.diff_4           is NULL and m.diff_4           is NULL)))
               and rownum = 1;
         L_max_seq_no := L_max_seq_no + 1;
         end LOOP;
      else --- from 'CNTRCOST' form.
         SQL_LIB.SET_MARK('OPEN', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         open C_GET_COST_SEQ_NO;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         fetch C_GET_COST_SEQ_NO into L_max_seq_no;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         close C_GET_COST_SEQ_NO;
         ---
         insert into contract_cost(contract_no,
                                   seq_no,
                                   item_grandparent,
                                   item_parent,
                                   item,
                                   diff_1,
                                   diff_2,
                                   diff_3,
                                   diff_4,
                                   unit_cost,
                                   item_level_index)
            select I_contract_no,
                    (ROWNUM + L_max_seq_no),
                    m.item_grandparent,
                    m.item_parent,
                    m.item,
                    m.diff_1,
                    m.diff_2,
                    m.diff_3,
                    m.diff_4,
                    ROUND(i.unit_cost * L_contract_rate/L_sups_rate, L_dec),
                    decode(m.item, NULL,
                       decode(m.diff_4, decode(m.diff_4, im.diff_4, m.diff_4, NULL, m.diff_4, NULL),
                          decode(m.diff_3, decode(m.diff_3, im.diff_3, m.diff_3, NULL, m.diff_3, NULL),
                             decode(m.diff_2, decode(m.diff_2, im.diff_2, m.diff_2, NULL, m.diff_2, NULL),
                                decode(m.diff_1, decode(m.diff_1, im.diff_1, m.diff_1, NULL, m.diff_1, NULL), 6, 2),
                             3),
                          4),
                       5),
                    1)
                    /* logic for decoding the item level index
                          if item is NULL
                             if diff_4 is NULL
                                parent/no diff. level = 6
                                if diff_3 is NULL
                                   parent/no diff level = 5
                                   if diff_2 is NULL
                                      parent/no diff level = 4
                                      if diff_1 is NULL
                                         parent/no diff. level = 3
                                      else
                                         parent/diff. 1 level  = 2
                                   else
                                      parent/diff. 2 level  = 3
                                else
                                   parent/diff. 3 level  = 4
                             else
                                parent/diff. 4 level  = 5
                          else transaction level item level = 1 */
              from contract_matrix_temp m, item_supp_country i, item_master im
             where i.item                = nvl(m.item, nvl(m.item_parent, m.item_grandparent))
               and m.item_parent = im.item
               and i.supplier            = I_supplier
               and i.origin_country_id   = L_country_id
               and contract_no           = I_contract_no
               and m.contract_no         = I_contract_no
               and not exists(select 'x'
                               from contract_cost c
                              where contract_no = I_contract_no
                                and (    c.item_grandparent  = m.item_grandparent
                                     or (c.item_grandparent is NULL and m.item_grandparent is NULL))
                                and (    c.item_parent       = m.item_parent
                                     or (c.item_parent      is NULL and m.item_parent      is NULL))
                                and (    c.item              = m.item
                                     or (c.item             is NULL and m.item             is NULL))
                                and (    c.diff_1            = m.diff_1
                                     or (c.diff_1           is NULL and m.diff_1           is NULL))
                                and (    c.diff_2            = m.diff_2
                                     or (c.diff_2           is NULL and m.diff_2           is NULL))
                                and (    c.diff_3            = m.diff_3
                                     or (c.diff_3           is NULL and m.diff_3           is NULL))
                                and (    c.diff_4            = m.diff_4
                                     or (c.diff_4           is NULL and m.diff_4           is NULL)));
         SQL_LIB.SET_MARK('OPEN', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         open C_GET_COST_SEQ_NO;
         SQL_LIB.SET_MARK('FETCH', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         fetch C_GET_COST_SEQ_NO into L_max_seq_no;
         SQL_LIB.SET_MARK('CLOSE', 'C_GET_COST_SEQ_NO', 'CONTRACT_COST',
                          'contract_no: '||to_char(I_contract_no));
         close C_GET_COST_SEQ_NO;
         ---
         -- insert transaction level item records into the contract_cost table
         for tran_level_rec in C_INSERT_TRAN_LEVEL_ITEM_CC LOOP
            L_max_seq_no := L_max_seq_no + 1;
            insert into contract_cost(contract_no,
                                      seq_no,
                                      item_grandparent,
                                      item_parent,
                                      item,
                                      diff_1,
                                      diff_2,
                                      diff_3,
                                      diff_4,
                                      unit_cost,
                                      item_level_index)
               values (I_contract_no,
                       L_max_seq_no,
                       tran_level_rec.item_grandparent,
                       tran_level_rec.item_parent,
                       tran_level_rec.item,
                       tran_level_rec.diff_1,
                       tran_level_rec.diff_2,
                       tran_level_rec.diff_3,
                       tran_level_rec.diff_4,
                       ROUND(tran_level_rec.unit_cost * L_contract_rate/L_sups_rate, L_dec),
                       1);
         end LOOP;
         --- Insert parent level records into the cost table.
         FOR parent_rec in C_INSERT_PARENT_CC LOOP
            /* Insert item parent into the contract_cost table. The selection
               of the item grandparent is for reference purposes only. */

           insert into contract_cost(contract_no,
                                     seq_no,
                                     item_grandparent,
                                     item_parent,
                                     item,
                                     diff_1,
                                     diff_2,
                                     diff_3,
                                     diff_4,
                                     unit_cost,
                                     item_level_index)
            select I_contract_no,
                    (ROWNUM + L_max_seq_no),
                    parent_rec.item_grandparent,
                    parent_rec.item_parent,
                    NULL, --- item
                    parent_rec.diff_1,
                    parent_rec.diff_2,
                    parent_rec.diff_3,
                    parent_rec.diff_4,
                    ROUND(parent_rec.unit_cost * L_contract_rate/L_sups_rate, L_dec),
                    decode(m.item, NULL,
                       decode(m.diff_4, decode(m.diff_4, im.diff_4, m.diff_4, NULL, m.diff_4, NULL),
                          decode(m.diff_3, decode(m.diff_3, im.diff_3, m.diff_3, NULL, m.diff_3, NULL),
                             decode(m.diff_2, decode(m.diff_2, im.diff_2, m.diff_2, NULL, m.diff_2, NULL),
                                decode(m.diff_1, decode(m.diff_1, im.diff_1, m.diff_1, NULL, m.diff_1, NULL), 6, 2),
                             3),
                          4),
                       5),
                    1)
                    /* logic for decoding the item level index
                          if item is NULL
                             if diff_4 is NULL
                                parent/no diff. level = 6
                                if diff_3 is NULL
                                   parent/no diff level = 5
                                   if diff_2 is NULL
                                      parent/no diff level = 4
                                      if diff_1 is NULL
                                         parent/no diff. level = 3
                                      else
                                         parent/diff. 1 level  = 2
                                   else
                                      parent/diff. 2 level  = 3
                                else
                                   parent/diff. 3 level  = 4
                             else
                                parent/diff. 4 level  = 5
                          else transaction level item level = 1 */
              from contract_matrix_temp m, item_supp_country i, item_master im
             where i.item                = nvl(m.item, nvl(m.item_parent, m.item_grandparent))
               and m.item_parent = im.item
               and i.supplier            = I_supplier
               and i.origin_country_id   = L_country_id
               and contract_no           = I_contract_no
               and m.contract_no         = I_contract_no
               and (m.diff_1 = parent_rec.diff_1
                   or (m.diff_1 IS NULL AND parent_rec.diff_1 IS NULL))
               and (m.diff_2 = parent_rec.diff_2
                   or (m.diff_2 IS NULL AND parent_rec.diff_2 IS NULL))
               and (m.diff_3 = parent_rec.diff_3
                   or (m.diff_3 IS NULL AND parent_rec.diff_3 IS NULL))
               and (m.diff_4 = parent_rec.diff_4
                   or (m.diff_4 IS NULL AND parent_rec.diff_4 IS NULL))
               and not exists(select 'x'
                               from contract_cost c
                              where contract_no = I_contract_no
                                and (    c.item_grandparent  = m.item_grandparent
                                     or (c.item_grandparent is NULL and m.item_grandparent is NULL))
                                and (    c.item_parent       = m.item_parent
                                     or (c.item_parent      is NULL and m.item_parent      is NULL))
                                and (    c.item              = m.item
                                     or (c.item             is NULL and m.item             is NULL))
                                and (    c.diff_1            = m.diff_1
                                     or (c.diff_1           is NULL and m.diff_1           is NULL))
                                and (    c.diff_2            = m.diff_2
                                     or (c.diff_2           is NULL and m.diff_2           is NULL))
                                and (    c.diff_3            = m.diff_3
                                     or (c.diff_3           is NULL and m.diff_3           is NULL))
                                and (    c.diff_4            = m.diff_4
                                     or (c.diff_4           is NULL and m.diff_4           is NULL)))
               and rownum = 1;
         L_max_seq_no := L_max_seq_no + 1;
         end LOOP;
         --- Insert grandparent level records into the cost table.
         FOR grandparent_rec in C_INSERT_GRANDPARENT_CC LOOP

           insert into contract_cost(contract_no,
                                     seq_no,
                                     item_grandparent,
                                     item_parent,
                                     item,
                                     diff_1,
                                     diff_2,
                                     diff_3,
                                     diff_4,
                                     unit_cost,
                                     item_level_index)
            select I_contract_no,
                   (ROWNUM +  L_max_seq_no),
                   grandparent_rec.item_grandparent,
                   NULL, --- item_parent
                   NULL, --- item
                   grandparent_rec.diff_1,
                   grandparent_rec.diff_2,
                   grandparent_rec.diff_3,
                   grandparent_rec.diff_4,
                   ROUND(grandparent_rec.unit_cost * L_contract_rate/L_sups_rate, L_dec),
                   decode(m.item, NULL,
                      decode(m.diff_4, decode(m.diff_4, im.diff_4, m.diff_4, NULL, m.diff_4, NULL),
                         decode(m.diff_3, decode(m.diff_3, im.diff_3, m.diff_3, NULL, m.diff_3, NULL),
                            decode(m.diff_2, decode(m.diff_2, im.diff_2, m.diff_2, NULL, m.diff_2, NULL),
                               decode(m.diff_1, decode(m.diff_1, im.diff_1, m.diff_1, NULL, m.diff_1, NULL), 6, 2),
                            3),
                         4),
                      5),
                   1)
                   /* logic for decoding the item level index
                         if item is NULL
                            if diff_4 is NULL
                               parent/no diff. level = 6
                               if diff_3 is NULL
                                  parent/no diff level = 5
                                  if diff_2 is NULL
                                     parent/no diff level = 4
                                     if diff_1 is NULL
                                        parent/no diff. level = 3
                                     else
                                        parent/diff. 1 level  = 2
                                  else
                                     parent/diff. 2 level  = 3
                               else
                                  parent/diff. 3 level  = 4
                            else
                               parent/diff. 4 level  = 5
                         else transaction level item level = 1 */
             from contract_matrix_temp m, item_supp_country i, item_master im
            where i.item                = nvl(m.item, nvl(m.item_parent, m.item_grandparent))
              and m.item_parent = im.item
              and i.supplier            = I_supplier
              and i.origin_country_id   = L_country_id
              and contract_no           = I_contract_no
              and m.contract_no         = I_contract_no
              and (m.diff_1 = grandparent_rec.diff_1
                   or (m.diff_1 IS NULL AND grandparent_rec.diff_1 IS NULL))
              and (m.diff_2 = grandparent_rec.diff_2
                   or (m.diff_2 IS NULL AND grandparent_rec.diff_2 IS NULL))
              and (m.diff_3 = grandparent_rec.diff_3
                   or (m.diff_3 IS NULL AND grandparent_rec.diff_3 IS NULL))
              and (m.diff_4 = grandparent_rec.diff_4
                   or (m.diff_4 IS NULL AND grandparent_rec.diff_4 IS NULL))
              and not exists(select 'x'
                              from contract_cost c
                             where contract_no = I_contract_no
                               and (    c.item_grandparent  = m.item_grandparent
                                    or (c.item_grandparent is NULL and m.item_grandparent is NULL))
                               and (    c.item_parent       = m.item_parent
                                    or (c.item_parent      is NULL and m.item_parent      is NULL))
                               and (    c.item              = m.item
                                    or (c.item             is NULL and m.item             is NULL))
                               and (    c.diff_1            = m.diff_1
                                   or (c.diff_1           is NULL and m.diff_1           is NULL))
                               and (    c.diff_2            = m.diff_2
                                    or (c.diff_2           is NULL and m.diff_2           is NULL))
                               and (    c.diff_3            = m.diff_3
                                    or (c.diff_3           is NULL and m.diff_3           is NULL))
                               and (    c.diff_4            = m.diff_4
                                    or (c.diff_4           is NULL and m.diff_4           is NULL)))
              and rownum = 1;
         L_max_seq_no := L_max_seq_no + 1;
         end LOOP;
         ---
         if I_contract_type in ('A','B') then
            SQL_LIB.SET_MARK('OPEN', 'C_GET_DETAIL_SEQ_NO', 'CONTRACT_DETAIL',
                             'contract_no: '||to_char(I_contract_no));
            open C_GET_DETAIL_SEQ_NO;
            SQL_LIB.SET_MARK('FETCH', 'C_GET_DETAIL_SEQ_NO', 'CONTRACT_DETAIL',
                             'contract_no: '||to_char(I_contract_no));
            fetch C_GET_DETAIL_SEQ_NO into L_max_seq_no;
            SQL_LIB.SET_MARK('CLOSE', 'C_GET_DETAIL_SEQ_NO', 'CONTRACT_DETAIL',
                             'contract_no: '||to_char(I_contract_no));
            close C_GET_DETAIL_SEQ_NO;
            ---
            insert into contract_detail(contract_no,
                                        seq_no,
                                        item_grandparent,
                                        item_parent,
                                        item,
                                        ref_item,
                                        diff_1,
                                        diff_2,
                                        diff_3,
                                        diff_4,
                                        loc_type,
                                        location,
                                        ready_date,
                                        qty_contracted,
                                        qty_ordered,
                                        qty_received,
                                        item_level_index,
                                        cur_repl_qty)
               select I_contract_no,
                      (ROWNUM + L_max_seq_no),
                      m.item_grandparent,
                      m.item_parent,
                      m.item,
                      m.ref_item,
                      m.diff_1,
                      m.diff_2,
                      m.diff_3,
                      m.diff_4,
                      m.loc_type,
                      m.location,
                      m.ready_date,
                      nvl(m.qty,0),
                      NULL,
                      NULL,
                   decode(m.item, NULL,
                      decode(m.diff_4, decode(m.diff_4, im.diff_4, m.diff_4, NULL, m.diff_4, NULL),
                         decode(m.diff_3, decode(m.diff_3, im.diff_3, m.diff_3, NULL, m.diff_3, NULL),
                            decode(m.diff_2, decode(m.diff_2, im.diff_2, m.diff_2, NULL, m.diff_2, NULL),
                               decode(m.diff_1, decode(m.diff_1, im.diff_1, m.diff_1, NULL, m.diff_1, NULL), 6, 2),
                            3),
                         4),
                      5),
                   1),
                      /* logic for decoding the item level index
                            if item is NULL
                               if diff_4 is NULL
                                  parent/no diff. level = 6
                                  if diff_3 is NULL
                                     parent/no diff level = 5
                                     if diff_2 is NULL
                                        parent/no diff level = 4
                                        if diff_1 is NULL
                                           parent/no diff. level = 3
                                        else
                                           parent/diff. 1 level  = 2
                                     else
                                        parent/diff. 2 level  = 3
                                  else
                                     parent/diff. 3 level  = 4
                               else
                                  parent/diff. 4 level  = 5
                            else transaction level item level = 1 */
                      NULL
                 from contract_matrix_temp m, item_master im
                where m.contract_no = I_contract_no
               and m.item_parent = im.item
                  and not exists (select 'x'
                                   from contract_detail d
                                  where d.contract_no = I_contract_no
                                    and (    d.item_grandparent  = m.item_grandparent
                                         or (d.item_grandparent is NULL and m.item_grandparent is NULL))
                                    and (    d.item_parent       = m.item_parent
                                         or (d.item_parent      is NULL and m.item_parent      is NULL))
                                    and (    d.item              = m.item
                                         or (d.item             is NULL and m.item             is NULL))
                                    and (    d.diff_1            = m.diff_1
                                         or (d.diff_1           is NULL and m.diff_1           is NULL))
                                    and (    d.diff_2            = m.diff_2
                                         or (d.diff_2           is NULL and m.diff_2           is NULL))
                                    and (    d.diff_3            = m.diff_3
                                         or (d.diff_3           is NULL and m.diff_3           is NULL))
                                    and (    d.diff_4            = m.diff_4
                                         or (d.diff_4           is NULL and m.diff_4           is NULL)));
         end if;
      end if;
      return TRUE;
   EXCEPTION
      when OTHERS then
         O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                               SQLERRM,
                                               'CONTRACT_DIST_SQL.POP_DETAIL_COST',
                                               to_char(SQLCODE));
         if DBMS_SQL.IS_OPEN (C_CURSOR) then
            DBMS_SQL.CLOSE_CURSOR (C_CURSOR);
         end if;
         return FALSE;
END POP_DETAIL_COST;
---------------------------------------------------------------------------------------------
FUNCTION CONTRACT_MATRIX_TEMP_EXISTS
         (O_error_message     IN OUT VARCHAR2,
          O_duplicate_found   IN OUT BOOLEAN,
          I_item_grandparent  IN     CONTRACT_MATRIX_TEMP.ITEM_GRANDPARENT%TYPE,
          I_item_parent       IN     CONTRACT_MATRIX_TEMP.ITEM_PARENT%TYPE,
          I_item              IN     CONTRACT_MATRIX_TEMP.ITEM%TYPE,
          I_diff_1            IN     CONTRACT_MATRIX_TEMP.DIFF_1%TYPE,
          I_diff_2            IN     CONTRACT_MATRIX_TEMP.DIFF_2%TYPE,
          I_diff_3            IN     CONTRACT_MATRIX_TEMP.DIFF_3%TYPE,
          I_diff_4            IN     CONTRACT_MATRIX_TEMP.DIFF_4%TYPE,
          I_contract_no       IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DIST_SQL.CONTRACT_MATRIX_TEMP_EXISTS';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select 'x'
        from contract_matrix_temp
       where contract_no = I_contract_no
         and nvl(item_grandparent, '-1') = nvl(I_item_grandparent, '-1')
         and nvl(item_parent, '-1')      = nvl(I_item_parent, '-1')
         and nvl(item, '-1')             = nvl(I_item, '-1')
         and nvl(diff_1, '-1')           = nvl(I_diff_1, '-1')
         and nvl(diff_2, '-1')           = nvl(I_diff_2, '-1')
         and nvl(diff_3, '-1')           = nvl(I_diff_3, '-1')
         and nvl(diff_4, '-1')           = nvl(I_diff_4, '-1')
         and location is NULL
         and ready_date is NULL;

BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'CONTRACT_MATRIX_TEMP',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'CONTRACT_MATRIX_TEMP',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_EXISTS into L_record_found;
   if C_EXISTS%FOUND then
      O_duplicate_found := TRUE;
      O_error_message := SQL_LIB.CREATE_MSG('DUP_CONTRACT_DETAILS',
                                            NULL,
                                            NULL,
                                            NULL);
   else
      O_duplicate_found := FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'CONTRACT_MATRIX_TEMP',
                    'Contract No.: '||to_char(I_contract_no));
   close C_EXISTS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CONTRACT_MATRIX_TEMP_EXISTS;
---------------------------------------------------------------------------------------------
FUNCTION ASSOCIATE_TO_CHILD
         (O_error_message   IN OUT VARCHAR2,
          O_child_rejected  IN OUT BOOLEAN,
          I_contract_no     IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program              VARCHAR2(60)  := 'CONTRACT_DIST_SQL.ASSOCIATE_TO_CHILD';
   L_item                 CONTRACT_MATRIX_TEMP.ITEM%TYPE;
   L_status               ITEM_MASTER.STATUS%TYPE;
   L_item_grandparent     CONTRACT_MATRIX_TEMP.ITEM_GRANDPARENT%TYPE;
   L_item_parent          CONTRACT_MATRIX_TEMP.ITEM_PARENT%TYPE;
   L_diff_1               CONTRACT_MATRIX_TEMP.DIFF_1%TYPE;
   L_diff_2               CONTRACT_MATRIX_TEMP.DIFF_2%TYPE;
   L_diff_3               CONTRACT_MATRIX_TEMP.DIFF_1%TYPE;
   L_diff_4               CONTRACT_MATRIX_TEMP.DIFF_2%TYPE;
   L_qty                  CONTRACT_MATRIX_TEMP.QTY%TYPE;
   L_supplier             CONTRACT_HEADER.SUPPLIER%TYPE;
   L_country_id           CONTRACT_HEADER.COUNTRY_ID%TYPE;
   L_unit_cost_cont       CONTRACT_MATRIX_TEMP.UNIT_COST%TYPE;
   L_currency_cont        CURRENCIES.CURRENCY_CODE%TYPE;
   L_rate_cont            CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_cost_fmt_cont        CURRENCIES.CURRENCY_COST_FMT%TYPE;
   L_cost_dec_cont        CURRENCIES.CURRENCY_COST_DEC%TYPE;
   L_unit_cost_supp       ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_currency_supp        CURRENCIES.CURRENCY_CODE%TYPE;
   L_rate_supp            CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_cost_fmt_supp        CURRENCIES.CURRENCY_COST_FMT%TYPE;
   L_cost_dec_supp        CURRENCIES.CURRENCY_COST_DEC%TYPE;
   L_supp_country_exists  BOOLEAN;
   L_duplicate_found      BOOLEAN;
   ---
   cursor C_GET_GRANDPARENT_TO_ASSOCIATE is
      select cmt.item_grandparent,
             cmt.diff_1,
             cmt.diff_2,
             cmt.diff_3,
             cmt.diff_4,
             cmt.qty,
             ch.supplier,
             ch.country_id
        from contract_matrix_temp cmt,
             contract_header ch,
             item_master im
       where cmt.item_parent      is NULL
         and cmt.item_grandparent is NOT NULL
         and cmt.item_grandparent  = im.item
         and im.diff_1            is NOT NULL
         and cmt.diff_1           is NOT NULL
         and (  (   cmt.diff_2    is NOT NULL
                 and im.diff_2    is NOT NULL)
              or(   cmt.diff_2    is NULL
                 and im.diff_2    is NULL))
         and (   (cmt.diff_3      is NOT NULL
                 and im.diff_3    is NOT NULL)
              or( cmt.diff_3      is NULL
                 and im.diff_3    is NULL))
         and (   (cmt.diff_4      is NOT NULL
                 and im.diff_4    is NOT NULL)
              or( cmt.diff_4      is NULL
                 and im.diff_4    is NULL))
         and cmt.contract_no       = ch.contract_no
         and ch.contract_no        = I_contract_no;

   cursor C_GET_PARENT_TO_ASSOCIATE is
      select cmt.item_grandparent,
             cmt.item_parent,
             cmt.diff_1,
             cmt.diff_2,
             cmt.diff_3,
             cmt.diff_4,
             cmt.qty,
             ch.supplier,
             ch.country_id
        from contract_matrix_temp cmt,
             contract_header ch,
             item_master im
       where cmt.item          is NULL
         and cmt.item_parent   is NOT NULL
         and cmt.item_parent    = im.item
         and im.diff_1         is NOT NULL
         and cmt.diff_1        is NOT NULL
         and (  (   cmt.diff_2 is NOT NULL
                 and im.diff_2 is NOT NULL)
              or(   cmt.diff_2 is NULL
                 and im.diff_2 is NULL))
         and (   (cmt.diff_3      is NOT NULL
                 and im.diff_3    is NOT NULL)
              or( cmt.diff_3      is NULL
                 and im.diff_3    is NULL))
         and (   (cmt.diff_4      is NOT NULL
                 and im.diff_4    is NOT NULL)
              or( cmt.diff_4      is NULL
                 and im.diff_4    is NULL))
         and cmt.contract_no    = ch.contract_no
         and ch.contract_no     = I_contract_no;

   cursor C_GET_ITEM_FROM_ASSOCIATION(C_item ITEM_MASTER.ITEM%TYPE) is
      select im.item,
             im.status
        from item_master im
       where item_parent           = C_item
         and nvl(diff_1, '-1')     = nvl(L_diff_1, '-1')
         and nvl(diff_2, '-1')     = nvl(L_diff_2, '-1')
         and nvl(diff_3, '-1')     = nvl(L_diff_3, '-1')
         and nvl(diff_4, '-1')     = nvl(L_diff_4, '-1');

BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   O_child_rejected := FALSE;
   ---
   if GET_CURRENCY_CODES(O_error_message,
                         L_currency_supp,
                         L_rate_supp,
                         L_cost_fmt_supp,
                         L_cost_dec_supp,
                         L_supplier,
                         L_currency_cont,
                         L_rate_cont,
                         L_cost_fmt_cont,
                         L_cost_dec_cont,
                         I_contract_no) = FALSE then
      return FALSE;
   end if;
   ---
   --- Check for item parents to associate with item grandparent/diffs.
   for c_rec in C_GET_GRANDPARENT_TO_ASSOCIATE LOOP
      L_item_grandparent := c_rec.item_grandparent;
      L_diff_1           := c_rec.diff_1;
      L_diff_2           := c_rec.diff_2;
      L_diff_3           := c_rec.diff_3;
      L_diff_4           := c_rec.diff_4;
      L_qty              := c_rec.qty;
      L_supplier         := c_rec.supplier;
      L_country_id       := c_rec.country_id;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_FROM_ASSOCIATION',
                       'ITEM_MASTER',
                       'Item Grandparent: '||L_item_grandparent);
      open  C_GET_ITEM_FROM_ASSOCIATION(L_item_grandparent);
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_FROM_ASSOCIATION',
                       'ITEM_MASTER',
                       'Item Grandparent: '||L_item_grandparent);
      fetch C_GET_ITEM_FROM_ASSOCIATION into L_item_parent,
                                             L_status;
      if C_GET_ITEM_FROM_ASSOCIATION%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_FROM_ASSOCIATION',
                          'ITEM_MASTER',
                          'Item Grandparent: '||L_item_grandparent);
         close C_GET_ITEM_FROM_ASSOCIATION;
         --- Insert an error because Item Parent not found from association.
         O_child_rejected := TRUE;
         insert into orddist_item_temp
               (contract_no,
                order_no,
                item_parent,
                item,
                diff_1,
                diff_2,
                diff_3,
                diff_4,
                qty,
                reason)
            values
               (I_contract_no,
                NULL,
                L_item_grandparent,
                NULL,
                L_diff_1,
                L_diff_2,
                L_diff_3,
                L_diff_4,
                L_qty,
                'INV_ITEM_DIFF_COMBO');
      elsif L_status != 'A' then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_FROM_ASSOCIATION',
                          'ITEM_MASTER',
                          'Item Grandparent: '||L_item_grandparent);
         close C_GET_ITEM_FROM_ASSOCIATION;
         --- Insert an error because Item Parent found is not approved.
         O_child_rejected := TRUE;
         insert into orddist_item_temp
               (contract_no,
                order_no,
                item_parent,
                item,
                diff_1,
                diff_2,
                diff_3,
                diff_4,
                qty,
                reason)
            values
               (I_contract_no,
                NULL,
                L_item_grandparent,
                L_item_parent,
                L_diff_1,
                L_diff_2,
                L_diff_3,
                L_diff_4,
                L_qty,
                'ITEM_NOT_APPROVE_CONTRACT');
      else
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_FROM_ASSOCIATION',
                          'ITEM_MASTER',
                          'Item Grandparent: '||L_item_grandparent);
         close C_GET_ITEM_FROM_ASSOCIATION;
         if SUPP_ITEM_SQL.ITEM_SUPP_COUNTRY_EXISTS(O_error_message,
                                                   L_supp_country_exists,
                                                   L_item_parent,
                                                   L_supplier,
                                                   L_country_id) = FALSE then
            return FALSE;
         end if;
         if L_supp_country_exists = FALSE then
            --- Insert an error because Item Parent found is not
            --- part of the specified supplier/origin country.
            O_child_rejected := TRUE;
            insert into orddist_item_temp
                  (contract_no,
                   order_no,
                   item_parent,
                   item,
                   diff_1,
                   diff_2,
                   diff_3,
                   diff_4,
                   qty,
                   reason)
               values
                  (I_contract_no,
                   NULL,
                   L_item_grandparent,
                   L_item_parent,
                   L_diff_1,
                   L_diff_2,
                   L_diff_3,
                   L_diff_4,
                   L_qty,
                   'INV_ITEM_SUPP_CNTRY');
         else
            --- Add the child item parent to the contract.
            if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                      L_unit_cost_supp,
                                      L_item_parent,
                                      L_supplier,
                                      L_country_id,
                                      NULL --- Location
                                      ) = FALSE then
               return FALSE;
            end if;
            if L_currency_cont != L_currency_supp then
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_unit_cost_supp,
                                       L_currency_supp,
                                       L_currency_cont,
                                       L_unit_cost_cont,
                                       'C',
                                       NULL,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
            else
               L_unit_cost_cont := L_unit_cost_supp;
            end if;
            ---
            update contract_matrix_temp
               set item_parent = L_item_parent,
                   unit_cost   = L_unit_cost_cont
             where item_grandparent  = L_item_grandparent
               and nvl(diff_1, '-1') = nvl(L_diff_1, '-1')
               and nvl(diff_2, '-1') = nvl(L_diff_2, '-1')
               and nvl(diff_3, '-1') = nvl(L_diff_3, '-1')
               and nvl(diff_4, '-1') = nvl(L_diff_4, '-1')
               and item_parent      is NULL;
         end if;     --- Check for valid item-supplier-origin country relationship.
      end if;        --- Check if child item parent is found and approved.
   end LOOP;
   ---
   --- Check for items to associate with item parent/diffs.
   L_item_grandparent := NULL;
   for c_rec in C_GET_PARENT_TO_ASSOCIATE LOOP
      L_item_grandparent := c_rec.item_grandparent;
      L_item_parent      := c_rec.item_parent;
      L_diff_1           := c_rec.diff_1;
      L_diff_2           := c_rec.diff_2;
      L_diff_3           := c_rec.diff_3;
      L_diff_4           := c_rec.diff_4;
      L_qty              := c_rec.qty;
      L_supplier         := c_rec.supplier;
      L_country_id       := c_rec.country_id;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_FROM_ASSOCIATION',
                       'ITEM_MASTER',
                       'Item Parent: '||L_item_parent);
      open  C_GET_ITEM_FROM_ASSOCIATION(L_item_parent);
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_FROM_ASSOCIATION',
                       'ITEM_MASTER',
                       'Item Parent: '||L_item_parent);
      fetch C_GET_ITEM_FROM_ASSOCIATION into L_item,
                                             L_status;
      if C_GET_ITEM_FROM_ASSOCIATION%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_FROM_ASSOCIATION',
                          'ITEM_MASTER',
                          'Item Parent: '||L_item_parent);
         close C_GET_ITEM_FROM_ASSOCIATION;
         --- Insert an error because Item not found from association.
         O_child_rejected := TRUE;
         insert into orddist_item_temp
               (contract_no,
                order_no,
                item_parent,
                item,
                diff_1,
                diff_2,
                diff_3,
                diff_4,
                qty,
                reason)
            values
               (I_contract_no,
                NULL,
                L_item_parent,
                NULL,
                L_diff_1,
                L_diff_2,
                L_diff_3,
                L_diff_4,
                L_qty,
                'INV_ITEM_DIFF_COMBO');
      elsif L_status != 'A' then
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_FROM_ASSOCIATION',
                          'ITEM_MASTER',
                          'Item Parent: '||L_item_parent);
         close C_GET_ITEM_FROM_ASSOCIATION;
         --- Insert an error because Item found is not approved.
         O_child_rejected := TRUE;
         insert into orddist_item_temp
               (contract_no,
                order_no,
                item_parent,
                item,
                diff_1,
                diff_2,
                diff_3,
                diff_4,
                qty,
                reason)
            values
               (I_contract_no,
                NULL,
                L_item_parent,
                L_item,
                L_diff_1,
                L_diff_2,
                L_diff_3,
                L_diff_4,
                L_qty,
                'ITEM_NOT_APPROVE_CONTRACT');
      else
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_FROM_ASSOCIATION',
                          'ITEM_MASTER',
                          'Item Parent: '||L_item_parent);
         close C_GET_ITEM_FROM_ASSOCIATION;
         if SUPP_ITEM_SQL.ITEM_SUPP_COUNTRY_EXISTS(O_error_message,
                                                   L_supp_country_exists,
                                                   L_item,
                                                   L_supplier,
                                                   L_country_id) = FALSE then
            close C_GET_ITEM_FROM_ASSOCIATION;
            return FALSE;
         end if;
         if L_supp_country_exists = FALSE then
            --- Insert an error because Item found is part of the specified supplier/origin country.
            O_child_rejected := TRUE;
            insert into orddist_item_temp
                  (contract_no,
                   order_no,
                   item_parent,
                   item,
                   diff_1,
                   diff_2,
                   diff_3,
                   diff_4,
                   qty,
                   reason)
               values
                  (I_contract_no,
                   NULL,
                   L_item_parent,
                   L_item,
                   L_diff_1,
                   L_diff_2,
                   L_diff_3,
                   L_diff_4,
                   L_qty,
                   'INV_ITEM_SUPP_CNTRY');
         else
            --- Add the child item to the contract.
            if SUPP_ITEM_SQL.GET_COST(O_error_message,
                                      L_unit_cost_supp,
                                      L_item,
                                      L_supplier,
                                      L_country_id,
                                      NULL --- Location
                                      ) = FALSE then
               return FALSE;
            end if;
            if L_currency_cont != L_currency_supp then
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_unit_cost_supp,
                                       L_currency_supp,
                                       L_currency_cont,
                                       L_unit_cost_cont,
                                       'C',
                                       NULL,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
            else
               L_unit_cost_cont := L_unit_cost_supp;
            end if;
            ---
            update contract_matrix_temp
               set item      = L_item,
                   unit_cost = L_unit_cost_cont
             where item_parent       = L_item_parent
               and nvl(diff_1, '-1') = nvl(L_diff_1, '-1')
               and nvl(diff_2, '-1') = nvl(L_diff_2, '-1')
               and nvl(diff_3, '-1') = nvl(L_diff_3, '-1')
               and nvl(diff_4, '-1') = nvl(L_diff_4, '-1')
               and item             is NULL;
         end if;     --- Check for valid item-supplier-origin country relationship.
      end if;        --- Check if child item is found and approved.
   end LOOP;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END ASSOCIATE_TO_CHILD;
---------------------------------------------------------------------------------------------
FUNCTION EXPLODE_TO_TRAN_LEVEL
         (O_error_message       IN OUT VARCHAR2,
          O_rec_inserted        IN OUT BOOLEAN,
          I_item_grandparent    IN     CONTRACT_MATRIX_TEMP.ITEM_GRANDPARENT%TYPE,
          I_item_parent         IN     CONTRACT_MATRIX_TEMP.ITEM_PARENT%TYPE,
          I_loc_type            IN     CONTRACT_MATRIX_TEMP.LOC_TYPE%TYPE,
          I_location            IN     CONTRACT_MATRIX_TEMP.LOCATION%TYPE,
          I_ready_date          IN     CONTRACT_MATRIX_TEMP.READY_DATE%TYPE,
          I_contract_supplier   IN     CONTRACT_HEADER.SUPPLIER%TYPE,
          I_contract_country_id IN     CONTRACT_HEADER.COUNTRY_ID%TYPE,
          I_contract_no         IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DIST_SQL.EXPLODE_TO_TRAN_LEVEL';
   L_unit_cost_cont       CONTRACT_MATRIX_TEMP.UNIT_COST%TYPE;
   L_currency_cont        CURRENCIES.CURRENCY_CODE%TYPE;
   L_rate_cont            CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_cost_fmt_cont        CURRENCIES.CURRENCY_COST_FMT%TYPE;
   L_cost_dec_cont        CURRENCIES.CURRENCY_COST_DEC%TYPE;
   L_supplier             CONTRACT_HEADER.SUPPLIER%TYPE;
   L_unit_cost_supp       ITEM_SUPP_COUNTRY.UNIT_COST%TYPE;
   L_currency_supp        CURRENCIES.CURRENCY_CODE%TYPE;
   L_rate_supp            CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_cost_fmt_supp        CURRENCIES.CURRENCY_COST_FMT%TYPE;
   L_cost_dec_supp        CURRENCIES.CURRENCY_COST_DEC%TYPE;
   L_contract_type        CONTRACT_HEADER.CONTRACT_TYPE%TYPE;
BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_contract_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_SUPPLIER',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_contract_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_COUNTRY_ID',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_item_parent is NULL and I_item_grandparent is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM_PARENT and I_ITEM_GRANDPARENT',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if GET_CURRENCY_CODES(O_error_message,
                         L_currency_supp,
                         L_rate_supp,
                         L_cost_fmt_supp,
                         L_cost_dec_supp,
                         L_supplier,
                         L_currency_cont,
                         L_rate_cont,
                         L_cost_fmt_cont,
                         L_cost_dec_cont,
                         I_contract_no) = FALSE then
      return FALSE;
   end if;
   ---
   insert into contract_matrix_temp(contract_no,
                                    item_grandparent,
                                    item_parent,
                                    item,
                                    ref_item,
                                    diff_1,
                                    diff_2,
                                    diff_3,
                                    diff_4,
                                    loc_type,
                                    location,
                                    ready_date,
                                    unit_cost)
    select I_contract_no,
           im.item_grandparent,
           im.item_parent,
           im.item,
           NULL,      -- ref item
           im.diff_1, -- diff 1
           im.diff_2, -- diff 2
           im.diff_3, -- diff 3
           im.diff_4, -- diff 4
           I_loc_type,
           I_location,
           I_ready_date,
           ROUND(i.unit_cost * L_rate_cont/L_rate_supp, L_cost_dec_cont)
      from item_master im, item_supp_country i
     where (   (im.item_grandparent = I_item_grandparent and I_item_grandparent is NOT NULL)
            or (im.item_parent      = I_item_parent      and I_item_parent      is NOT NULL))
       and im.status           = 'A'
       and im.item_level       = im.tran_level
       and im.item             = i.item
       and i.supplier          = I_contract_supplier
       and i.origin_country_id = I_contract_country_id
       and not exists (select 'x'
                         from contract_matrix_temp cmt
                        where cmt.contract_no = I_contract_no
                          and cmt.item        = im.item);
   if SQL%NOTFOUND then
      O_rec_inserted := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG ('NO_EXPLODE_CNTR_TO_TRAN_L',
                                             nvl(I_item_grandparent, I_item_parent),
                                             NULL,
                                             NULL);
   else
      O_rec_inserted := TRUE;
      if CONTRACT_SQL.GET_CONTRACT_TYPE (o_error_message,
                                         L_contract_type,
                                         I_contract_no) = FALSE then
         return FALSE;
      end if;
      ---
      if L_contract_type = 'B' then  -- if type B need to delete source record
          delete from contract_matrix_temp
                where contract_no = I_contract_no
                  and ((item_grandparent = I_item_grandparent
                       and I_item_grandparent is not NULL)
                   or (item_parent = I_item_parent
                       and I_item_parent is not NULL))
                  and item is NULL;
      end if;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END EXPLODE_TO_TRAN_LEVEL;
---------------------------------------------------------------------------------------------
FUNCTION GET_CURRENCY_CODES
         (O_error_message       IN OUT VARCHAR2,
          IO_currency_supplier  IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
          O_rate_supplier       IN OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE,
          O_cost_fmt_supplier   IN OUT CURRENCIES.CURRENCY_COST_FMT%TYPE,
          O_cost_dec_supplier   IN OUT CURRENCIES.CURRENCY_COST_DEC%TYPE,
          IO_supplier           IN OUT CONTRACT_HEADER.SUPPLIER%TYPE,
          IO_currency_contract  IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
          O_rate_contract       IN OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE,
          O_cost_fmt_contract   IN OUT CURRENCIES.CURRENCY_COST_FMT%TYPE,
          O_cost_dec_contract   IN OUT CURRENCIES.CURRENCY_COST_DEC%TYPE,
          I_contract_no         IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program   VARCHAR2(60)  := 'CONTRACT_DIST_SQL.GET_CURRENCY_CODES';
   L_rtl_fmt   CURRENCIES.CURRENCY_RTL_FMT%TYPE;
   L_rtl_dec   CURRENCIES.CURRENCY_RTL_DEC%TYPE;
   ---
   cursor C_GET_CONTRACT_INFO is
      select currency_code, supplier
        from contract_header
       where contract_no = I_contract_no;

BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if IO_supplier is NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_CONTRACT_INFO',
                       'CONTRACT_HEADER',
                       'Contract No.: '||to_char(I_contract_no));
      open  C_GET_CONTRACT_INFO;
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_CONTRACT_INFO',
                       'CONTRACT_HEADER',
                       'Contract No.: '||to_char(I_contract_no));
      fetch C_GET_CONTRACT_INFO into IO_currency_contract, IO_supplier;
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_CONTRACT_INFO',
                       'CONTRACT_HEADER',
                       'Contract No.: '||to_char(I_contract_no));
      close C_GET_CONTRACT_INFO;
   elsif IO_currency_contract is NULL then
      if CONTRACT_SQL.GET_CURRENCY_CODE(O_error_message,
                                        IO_currency_contract,
                                        I_contract_no) = FALSE then
         return FALSE;
      end if;
   end if;
   if IO_currency_supplier is NULL then
      if SUPP_ATTRIB_SQL.GET_CURRENCY_CODE(O_error_message,
                                           IO_currency_supplier,
                                           IO_supplier) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if CURRENCY_SQL.GET_RATE(O_error_message,
                            O_rate_supplier,
                            IO_currency_supplier,
                            NULL,
                            NULL) = FALSE then
      return FALSE;
   end if;
   if CURRENCY_SQL.GET_RATE(O_error_message,
                            O_rate_contract,
                            IO_currency_contract,
                            NULL,
                            NULL) = FALSE then
      return FALSE;
   end if;
   ---
   if CURRENCY_SQL.GET_FORMAT(O_error_message,
                              IO_currency_supplier,
                              L_rtl_fmt,
                              L_rtl_dec,
                              O_cost_fmt_supplier,
                              O_cost_dec_supplier) = FALSE then
      return FALSE;
   end if;
   if CURRENCY_SQL.GET_FORMAT(O_error_message,
                              IO_currency_contract,
                              L_rtl_fmt,
                              L_rtl_dec,
                              O_cost_fmt_contract,
                              O_cost_dec_contract) = FALSE then
      return FALSE;
   end if;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_CURRENCY_CODES;
---------------------------------------------------------------------------------------------
FUNCTION VALIDATE_PARENT_DIFF (O_error_message       IN OUT VARCHAR2,
                               O_exists              IN OUT BOOLEAN,
                               I_contract_no         IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program   VARCHAR2(60)  := 'CONTRACT_DIST_SQL.VALIDATE_PARENT_DIFF';
   L_exists    VARCHAR2(1);
   ---
   cursor C_PARENT_DIFF is
      select 'x'
        from contract_matrix_temp cmt,
             item_master im
       where cmt.item is NULL
         and cmt.contract_no = I_contract_no
         and (im.item = cmt.item_parent or im.item = cmt.item_grandparent)
         and im.item_level = 1
         and ((nvl(cmt.diff_1, im.diff_1) != im.diff_1
               and nvl(cmt.diff_2, im.diff_2) != im.diff_2)
              or (nvl(cmt.diff_1, im.diff_1) != im.diff_1
                  and nvl(cmt.diff_3, im.diff_3) != im.diff_3)
              or (nvl(cmt.diff_1, im.diff_1) != im.diff_1
                  and nvl(cmt.diff_4, im.diff_4) != im.diff_4)
              or (nvl(cmt.diff_2, im.diff_2) != im.diff_2
                  and nvl(cmt.diff_3, im.diff_3) != im.diff_3)
              or (nvl(cmt.diff_2, im.diff_2) != im.diff_2
                  and nvl(cmt.diff_4, im.diff_4) != im.diff_4)
              or (nvl(cmt.diff_3, im.diff_3) != im.diff_3
                  and nvl(cmt.diff_4, im.diff_4) != im.diff_4));

BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   open C_PARENT_DIFF;
   fetch C_PARENT_DIFF into L_exists;
   if C_PARENT_DIFF%NOTFOUND then
      O_exists := FALSE;
   else
      O_exists := TRUE;
   end if;
   close C_PARENT_DIFF;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALIDATE_PARENT_DIFF;
---------------------------------------------------------------------------------------------
END;
/

