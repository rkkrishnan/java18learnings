CREATE OR REPLACE PACKAGE BODY CONTRACT_DETAIL_SQL AS
--------------------------------------------------------------------------------
FUNCTION CONTRACT_HEADER_EXISTS
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.CONTRACT_HEADER_EXISTS';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select 'x'
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
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'CONTRACT_HEADER',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'CONTRACT_HEADER',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_EXISTS into L_record_found;
   if C_EXISTS%NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('CONTRACT_HEADER_NOT_EXIST',
                                            to_char(I_contract_no),
                                            NULL,
                                            NULL);
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'CONTRACT_HEADER',
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
END CONTRACT_HEADER_EXISTS;
--------------------------------------------------------------------------------
FUNCTION CONTRACT_COST_EXISTS
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.CONTRACT_COST_EXISTS';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select 'x'
        from contract_cost
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
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS',
                    'CONTRACT_COST',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'CONTRACT_COST',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_EXISTS into L_record_found;
   if C_EXISTS%NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_CONTRACT_COST_FOR_CONT',
                                            to_char(I_contract_no),
                                            NULL,
                                            NULL);
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'CONTRACT_COST',
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
END CONTRACT_COST_EXISTS;
--------------------------------------------------------------------------------
FUNCTION CONTRACT_DETAIL_EXISTS
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          I_item           IN     CONTRACT_DETAIL.ITEM%TYPE,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.CONTRACT_DETAIL_EXISTS';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select 'x'
        from contract_detail
       where contract_no = I_contract_no
         and (   nvl(item, 'NULL') = nvl(I_item, 'NULL')
              or I_item is NULL);
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
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_EXISTS into L_record_found;
   if C_EXISTS%NOTFOUND then
      O_exists := FALSE;
      if I_item is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('NO_CONTRACT_DETL_FOR_CONT',
                                               to_char(I_contract_no),
                                               NULL,
                                               NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_CNTRDETL_FOR_CONT_ITEM',
                                               I_item,
                                               to_char(I_contract_no),
                                               NULL);
      end if;
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'CONTRACT_DETAIL',
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
END CONTRACT_DETAIL_EXISTS;
--------------------------------------------------------------------------------
FUNCTION CONTRACT_DETAIL_PARENT_EXISTS
         (O_error_message    IN OUT VARCHAR2,
          O_exists           IN OUT BOOLEAN,
          I_item_parent      IN     CONTRACT_DETAIL.ITEM_PARENT%TYPE,
          I_item_grandparent IN     CONTRACT_DETAIL.ITEM_GRANDPARENT%TYPE,
          I_contract_no      IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.CONTRACT_DETAIL_PARENT_EXISTS';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select 'x'
        from contract_detail
       where (   item_parent      = I_item_parent
              or item_grandparent = I_item_grandparent)
         and contract_no          = I_contract_no;
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
                    'CONTRACT_DETAIL',
                    'Contract No.: '      ||to_char(I_contract_no) ||
                    ', Item Parent: '     ||I_item_parent          ||
                    ', Item Grandparent: '||I_item_grandparent);
   open  C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'CONTRACT_DETAIL',
                    'Contract No.: '      ||to_char(I_contract_no) ||
                    ', Item Parent: '     ||I_item_parent          ||
                    ', Item Grandparent: '||I_item_grandparent);
   fetch C_EXISTS into L_record_found;
   if C_EXISTS%NOTFOUND then
      O_exists := FALSE;
      if I_item_parent is NOT NULL then
         O_error_message := SQL_LIB.CREATE_MSG('NO_CNTRDETL_FOR_CONT_ITEM',
                                               I_item_parent,
                                               to_char(I_contract_no),
                                               NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_CNTRDETL_FOR_CONT_ITEM',
                                               I_item_grandparent,
                                               to_char(I_contract_no),
                                               NULL);
      end if;
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'CONTRACT_DETAIL',
                    'Contract No.: '      ||to_char(I_contract_no) ||
                    ', Item Parent: '     ||I_item_parent          ||
                    ', Item Grandparent: '||I_item_grandparent);
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
END CONTRACT_DETAIL_PARENT_EXISTS;
--------------------------------------------------------------------------------
FUNCTION CONTRACT_EXISTS_ON_ORDHEAD
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          I_status_code    IN     VARCHAR2,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.CONTRACT_EXISTS_ON_ORDHEAD';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_EXISTS is
      select 'x'
        from ordhead
       where contract_no = I_contract_no
         and (   (status = I_status_code    and I_status_code in ('W', 'S', 'A', 'C'))
              or (status in ('W', 'S', 'A') and I_status_code = 'WSA')
              or (I_status_code is NULL));
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
                    'ORDHEAD',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS',
                    'ORDHEAD',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_EXISTS into L_record_found;
   if C_EXISTS%NOTFOUND then
      O_exists := FALSE;
      if I_status_code is NULL then
         O_error_message := SQL_LIB.CREATE_MSG('NO_ORDER_C_DETAILS',
                                               NULL,
                                               NULL,
                                               NULL);
      else
         O_error_message := SQL_LIB.CREATE_MSG('NO_ORD_STATUS_FOR_CONTRAC',
                                               NULL,
                                               NULL,
                                               NULL);
      end if;
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS',
                    'ORDHEAD',
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
END CONTRACT_EXISTS_ON_ORDHEAD;
--------------------------------------------------------------------------------
FUNCTION GET_DETAIL_REF_ITEM
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          O_ref_item       IN OUT CONTRACT_DETAIL.REF_ITEM%TYPE,
          O_ref_item_desc  IN OUT ITEM_MASTER.ITEM_DESC%TYPE,
          I_item           IN     CONTRACT_DETAIL.ITEM%TYPE,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.GET_DETAIL_REF_ITEM';
   ---
   cursor C_GET_REF_ITEM is
      select ref_item
        from contract_detail
       where contract_no = I_contract_no
         and item        = I_item;
BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_REF_ITEM',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no) || ', Item: '||I_item);
   open  C_GET_REF_ITEM;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_REF_ITEM',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no) || ', Item: '||I_item);
   fetch C_GET_REF_ITEM into O_ref_item;
   if C_GET_REF_ITEM%FOUND and O_ref_item is NOT NULL then
      O_exists := TRUE;
      if ITEM_ATTRIB_SQL.GET_DESC(O_error_message,
                                  O_ref_item_desc,
                                  O_ref_item ) = FALSE then
         return FALSE;
      end if;
   else
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_REF_ITEM_ON_CONTRACT',
                                            to_char(I_contract_no),
                                            I_item,
                                            NULL);
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_REF_ITEM',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no) || ', Item: '||I_item);
   close C_GET_REF_ITEM;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_DETAIL_REF_ITEM;
--------------------------------------------------------------------------------
FUNCTION GET_HEADER_DATES
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          O_start_date     IN OUT CONTRACT_HEADER.START_DATE%TYPE,
          O_end_date       IN OUT CONTRACT_HEADER.END_DATE%TYPE,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.GET_HEADER_DATES';
   ---
   cursor C_GET_DATES is
      select start_date, end_date
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
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_DATES',
                    'CONTRACT_HEADER',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_GET_DATES;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_DATES',
                    'CONTRACT_HEADER',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_GET_DATES into O_start_date,
                          O_end_date;
   if C_GET_DATES%NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('CONTRACT_HEADER_NOT_EXIST',
                                            to_char(I_contract_no),
                                            NULL,
                                            NULL);
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_DATES',
                    'CONTRACT_HEADER',
                    'Contract No.: '||to_char(I_contract_no));
   close C_GET_DATES;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_HEADER_DATES;
--------------------------------------------------------------------------------
FUNCTION GET_READY_DATE
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          O_ready_date     IN OUT CONTRACT_DETAIL.READY_DATE%TYPE,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.GET_READY_DATE';
   ---
   cursor C_GET_DATE is
      select ready_date
        from contract_detail
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
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_DATE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_GET_DATE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_DATE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_GET_DATE into O_ready_date;
   if C_GET_DATE%NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_CONTRACT_DETL_FOR_CONT',
                                            to_char(I_contract_no),
                                            NULL,
                                            NULL);
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_DATE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   close C_GET_DATE;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_READY_DATE;
--------------------------------------------------------------------------------
FUNCTION GET_DETAIL_QUANTITIES
         (O_error_message    IN OUT VARCHAR2,
          O_exists           IN OUT BOOLEAN,
          O_qty_contracted   IN OUT CONTRACT_DETAIL.QTY_CONTRACTED%TYPE,
          O_qty_ordered      IN OUT CONTRACT_DETAIL.QTY_ORDERED%TYPE,
          O_qty_received     IN OUT CONTRACT_DETAIL.QTY_RECEIVED%TYPE,
          I_item_grandparent IN     CONTRACT_DETAIL.ITEM_GRANDPARENT%TYPE,
          I_item_parent      IN     CONTRACT_DETAIL.ITEM_PARENT%TYPE,
          I_item             IN     CONTRACT_DETAIL.ITEM%TYPE,
          I_contract_no      IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.GET_DETAIL_QUANTITIES';
   ---
   cursor C_GET_QUANTITIES is
      select qty_contracted,
             qty_ordered,
             qty_received
        from contract_detail
       where contract_no = I_contract_no
         and (   item                = I_item
              or I_item             is NULL)
         and (   item_parent         = I_item_parent
              or I_item_parent      is NULL)
         and (   item_grandparent    = I_item_grandparent
              or I_item_grandparent is NULL);
BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_item_grandparent is NULL and I_item_parent is NULL and I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM_GRANDPARENT, I_ITEM_PARENT, I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_QUANTITIES',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_GET_QUANTITIES;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_QUANTITIES',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_GET_QUANTITIES into O_qty_contracted,
                               O_qty_ordered,
                               O_qty_received;
   if C_GET_QUANTITIES%NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_CONTRACT_DETL_FOR_CONT',
                                            to_char(I_contract_no),
                                            NULL,
                                            NULL);
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_QUANTITIES',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   close C_GET_QUANTITIES;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_DETAIL_QUANTITIES;
--------------------------------------------------------------------------------
FUNCTION CHECK_READY_DATE_IN_RANGE
         (O_error_message  IN OUT VARCHAR2,
          O_within_range   IN OUT BOOLEAN,
          I_start_date     IN     CONTRACT_HEADER.START_DATE%TYPE,
          I_end_date       IN     CONTRACT_HEADER.END_DATE%TYPE,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.CHECK_READY_DATE_IN_RANGE';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_EXISTS_OUTSIDE_RANGE is
      select 'x'
        from contract_detail
       where contract_no = I_contract_no
         and (   ready_date > I_end_date
                 or ready_date < I_start_date);
BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_start_date is NULL and I_end_date is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_START_DATE or I_END_DATE',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_EXISTS_OUTSIDE_RANGE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   open  C_EXISTS_OUTSIDE_RANGE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_EXISTS_OUTSIDE_RANGE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   fetch C_EXISTS_OUTSIDE_RANGE into L_record_found;
   if C_EXISTS_OUTSIDE_RANGE%FOUND then
      O_within_range := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('READY_DATE_OUT_OF_RANGE',
                                            NULL,
                                            NULL,
                                            NULL);
   else
      O_within_range := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_EXISTS_OUTSIDE_RANGE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_contract_no));
   close C_EXISTS_OUTSIDE_RANGE;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CHECK_READY_DATE_IN_RANGE;
--------------------------------------------------------------------------------
FUNCTION GET_FILTER_WHERE
         (O_error_message  IN OUT VARCHAR2,
          O_filter_exists  IN OUT BOOLEAN,
          O_where_clause   IN OUT FILTER_TEMP.WHERE_CLAUSE%TYPE,
          I_form_name      IN     FILTER_TEMP.FORM_NAME%TYPE,
          I_unique_key     IN     FILTER_TEMP.UNIQUE_KEY%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.GET_FILTER_WHERE';
   L_table         VARCHAR2(30)  := 'FILTER_TEMP';
   ---
   cursor C_GET_WHERE is
      select where_clause
        from filter_temp
       where form_name  = I_form_name
         and unique_key = I_unique_key;
BEGIN
   if I_form_name is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_FORM_NAME',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_unique_key is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_UNIQUE_KEY',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_WHERE',
                    L_table,
                    'Form: '|| I_form_name || ', Key: '|| I_unique_key);
   open  C_GET_WHERE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_WHERE',
                    L_table,
                    'Form: '|| I_form_name || ', Key: '|| I_unique_key);
   fetch C_GET_WHERE into O_where_clause;
   if C_GET_WHERE%NOTFOUND then
      O_filter_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_FILTER_TEMP_EXISTS',
                                            I_form_name,
                                            I_unique_key,
                                            NULL);
   else
      O_filter_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_WHERE',
                    L_table,
                    'Form: '|| I_form_name || ', Key: '|| I_unique_key);
   close C_GET_WHERE;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_FILTER_WHERE;
--------------------------------------------------------------------------------
FUNCTION LOCK_CONTRACT_COST
         (O_error_message  IN OUT VARCHAR2,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.LOCK_CONTRACT_COST';
   L_table         VARCHAR2(30)  := 'CONTRACT_COST';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_RECORD is
      select 'x'
        from contract_cost
       where contract_no = I_contract_no
         for update of contract_no nowait;
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
                    'C_LOCK_RECORD',
                    L_table,
                    'Contract No.: '||to_char(I_contract_no));
   open  C_LOCK_RECORD;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_RECORD',
                    L_table,
                    'Contract No.: '||to_char(I_contract_no));
   close C_LOCK_RECORD;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_contract_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END LOCK_CONTRACT_COST;
--------------------------------------------------------------------------------
FUNCTION LOCK_CONTRACT_DETAIL
         (O_error_message  IN OUT VARCHAR2,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.LOCK_CONTRACT_DETAIL';
   L_table         VARCHAR2(30)  := 'CONTRACT_DETAIL';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_RECORD is
      select 'x'
        from contract_detail
       where contract_no = I_contract_no
         for update of contract_no nowait;
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
                    'C_LOCK_RECORD',
                    L_table,
                    'Contract No.: '||to_char(I_contract_no));
   open  C_LOCK_RECORD;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_RECORD',
                    L_table,
                    'Contract No.: '||to_char(I_contract_no));
   close C_LOCK_RECORD;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_contract_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END LOCK_CONTRACT_DETAIL;
--------------------------------------------------------------------------------
FUNCTION LOCK_CONTRACT_MATRIX_TEMP
         (O_error_message  IN OUT VARCHAR2,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.LOCK_CONTRACT_MATRIX_TEMP';
   L_table         VARCHAR2(30)  := 'CONTRACT_MATRIX_TEMP';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_RECORD is
      select 'x'
        from contract_matrix_temp
       where contract_no = I_contract_no
         for update of contract_no nowait;
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
                    'C_LOCK_RECORD',
                    L_table,
                    'Contract No.: '||to_char(I_contract_no));
   open  C_LOCK_RECORD;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_RECORD',
                    L_table,
                    'Contract No.: '||to_char(I_contract_no));
   close C_LOCK_RECORD;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_contract_no),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END LOCK_CONTRACT_MATRIX_TEMP;
--------------------------------------------------------------------------------
FUNCTION LOCK_FILTER_TEMP
         (O_error_message  IN OUT VARCHAR2,
          I_form_name      IN     FILTER_TEMP.FORM_NAME%TYPE,
          I_unique_key     IN     FILTER_TEMP.UNIQUE_KEY%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.LOCK_FILTER_TEMP';
   L_table         VARCHAR2(30)  := 'FILTER_TEMP';
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_RECORD is
      select 'x'
        from filter_temp
       where form_name  = I_form_name
         and unique_key = I_unique_key
         for update of form_name nowait;
BEGIN
   if I_form_name is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_FORM_NAME',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_unique_key is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_UNIQUE_KEY',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_RECORD',
                    L_table,
                    'Form: '|| I_form_name || ', Key: '|| I_unique_key);
   open  C_LOCK_RECORD;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_RECORD',
                    L_table,
                    'Form: '|| I_form_name || ', Key: '|| I_unique_key);
   close C_LOCK_RECORD;
   ---
   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            'Form: '|| I_form_name,
                                            'Key: ' || I_unique_key);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END LOCK_FILTER_TEMP;
--------------------------------------------------------------------------------
FUNCTION DELETE_FILTER_TEMP
         (O_error_message  IN OUT VARCHAR2,
          I_form_name      IN     FILTER_TEMP.FORM_NAME%TYPE,
          I_unique_key     IN     FILTER_TEMP.UNIQUE_KEY%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.DELETE_FILTER_TEMP';
BEGIN
   if I_form_name is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_FORM_NAME',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_unique_key is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_UNIQUE_KEY',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if LOCK_FILTER_TEMP(O_error_message,
                       I_form_name,
                       I_unique_key) = FALSE then
      return FALSE;
   end if;
   ---
   delete from filter_temp
    where form_name  = I_form_name
      and unique_key = I_unique_key;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_FILTER_TEMP;
--------------------------------------------------------------------------------
FUNCTION INSERT_UPDATE_FILTER_TEMP
         (O_error_message  IN OUT VARCHAR2,
          I_where_clause   IN     FILTER_TEMP.WHERE_CLAUSE%TYPE,
          I_form_name      IN     FILTER_TEMP.FORM_NAME%TYPE,
          I_unique_key     IN     FILTER_TEMP.UNIQUE_KEY%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.INSERT_UPDATE_FILTER_TEMP';
BEGIN
   if I_form_name is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_FORM_NAME',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_unique_key is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_UNIQUE_KEY',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if LOCK_FILTER_TEMP(O_error_message,
                       I_form_name,
                       I_unique_key) = FALSE then
      return FALSE;
   end if;
   ---
   update filter_temp
      set where_clause = I_where_clause
    where form_name    = I_form_name
      and unique_key   = I_unique_key;
   if SQL%NOTFOUND then
      insert into filter_temp(form_name,
                              unique_key,
                              where_clause)
                       values(I_form_name,
                              I_unique_key,
                              I_where_clause);
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
END INSERT_UPDATE_FILTER_TEMP;
--------------------------------------------------------------------------------
FUNCTION NEXT_PREV_CONTRACT_ORDSKU
         (O_error_message  IN OUT VARCHAR2,
          O_next_prev_exists  IN OUT BOOLEAN,
          I_contract_ordhead_seq  IN   CONTRACT_ORDSKU.CONTRACT_ORDHEAD_SEQ%TYPE,
          I_current_item          IN   CONTRACT_ORDSKU.ITEM%TYPE,
          I_next_prev_ind         IN   VARCHAR2)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60) := 'CONTRACT_DETAIL_SQL.NEXT_PREV_CONTRACT_ORDSKU';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_NEXT_PREV_EXISTS is
      select 'x'
        from contract_ordsku co
       where co.contract_ordhead_seq = I_contract_ordhead_seq
         and (  (co.item > I_current_item and I_next_prev_ind = 'N')
              or(co.item < I_current_item and I_next_prev_ind = 'P'));
BEGIN
   if I_contract_ordhead_seq is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_ORDHEAD_SEQ',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_current_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CURRENT_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_next_prev_ind is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_NEXT_PREV_IND',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_NEXT_PREV_EXISTS',
                    'CONTRACT_ORDSKU',
                    'Seq. No.: '||to_char(I_contract_ordhead_seq)||', Item: '||I_current_item);
   open C_NEXT_PREV_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_NEXT_PREV_EXISTS',
                    'CONTRACT_ORDSKU',
                    'Seq. No.: '||to_char(I_contract_ordhead_seq)||', Item: '||I_current_item);
   fetch C_NEXT_PREV_EXISTS into L_record_found;
   if C_NEXT_PREV_EXISTS%NOTFOUND then
      O_next_prev_exists := FALSE;
   else
      O_next_prev_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_NEXT_PREV_EXISTS',
                    'CONTRACT_ORDSKU',
                    'Seq. No.: '||to_char(I_contract_ordhead_seq)||', Item: '||I_current_item);
   close C_NEXT_PREV_EXISTS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END NEXT_PREV_CONTRACT_ORDSKU;
--------------------------------------------------------------------------------
FUNCTION GET_VALID_AVAILABILITY
         (O_error_message  IN OUT VARCHAR2,
          O_exists         IN OUT BOOLEAN,
          O_qty_avail      IN OUT SUP_AVAIL.QTY_AVAIL%TYPE,
          O_supplier       IN OUT SUP_AVAIL.SUPPLIER%TYPE,
          I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE,
          I_item           IN     CONTRACT_ORDSKU.ITEM%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60) := 'CONTRACT_DETAIL_SQL.GET_VALID_AVAILABILITY';
   ---
   cursor C_VALID_AVAIL is
     select sa.qty_avail, sa.supplier
       from sup_avail sa, contract_header ch
      where sa.item           = I_item
        and ch.supplier       = sa.supplier
        and ch.contract_type in ('A','D')
        and ch.contract_no    = I_contract_no;
BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_VALID_AVAIL',
                    'CONTRACT_HEADER, SUP_AVAIL',
                    'Contract No.: '||to_char(I_contract_no)||', Item: '||I_item);
   open C_VALID_AVAIL;
   SQL_LIB.SET_MARK('FETCH',
                    'C_VALID_AVAIL',
                    'CONTRACT_HEADER, SUP_AVAIL',
                    'Contract No.: '||to_char(I_contract_no)||', Item: '||I_item);
   fetch C_VALID_AVAIL into O_qty_avail,
                            O_supplier;
   if C_VALID_AVAIL%NOTFOUND then
      O_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG ('NO_SUP_AVAIL_FOR_ITEM',
                                             I_item,
                                             NULL,
                                             NULL);
   else
      O_exists := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_VALID_AVAIL',
                    'CONTRACT_HEADER, SUP_AVAIL',
                    'Contract No.: '||to_char(I_contract_no)||', Item: '||I_item);
   close C_VALID_AVAIL;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_VALID_AVAILABILITY;
--------------------------------------------------------------------------------
FUNCTION VALIDATE_CONTRACT_NO(O_error_message  IN OUT VARCHAR2,
                     O_valid          IN OUT BOOLEAN,
                  IO_vdate         IN OUT PERIOD.VDATE%TYPE,
                     I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE,
                     I_item           IN     CONTRACT_ORDSKU.ITEM%TYPE)
   return BOOLEAN is
   ---
   L_dummy      CONTRACT_HEADER.ORDERABLE_IND%TYPE;
   ---

BEGIN
   if VALIDATE_CONTRACT_NO(O_error_message,
                     O_valid,
                           L_dummy,
                           IO_vdate,
                     I_contract_no,
                     I_item)= FALSE then
      return FALSE;
   else
      return TRUE;
   end if;
END VALIDATE_CONTRACT_NO;
--------------------------------------------------------------------------------
FUNCTION VALIDATE_CONTRACT_NO(O_error_message  IN OUT VARCHAR2,
                     O_valid          IN OUT BOOLEAN,
                  O_orderable_ind  IN OUT CONTRACT_HEADER.ORDERABLE_IND%TYPE,
                     IO_vdate         IN OUT PERIOD.VDATE%TYPE,
                     I_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE,
                     I_item           IN     CONTRACT_ORDSKU.ITEM%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60) := 'CONTRACT_DETAIL_SQL.VALIDATE_CONTRACT_NO';
   L_record_found  VARCHAR2(1);
   ---
   cursor C_CHECK_CONTRACT_INFO is
      select 'x',
             ch.orderable_ind
        from contract_cost cc,
             contract_header ch,
             item_master im
       where ch.contract_no    = cc.contract_no
         and ch.contract_no    = I_contract_no
         and ch.status        in ('A','R')
         and ch.start_date    <= IO_vdate
         and ch.contract_type in ('A', 'C', 'D')
         and im.item           = I_item
         and (   (    cc.item  = im.item
                  and cc.item_level_index = 1)
              or (   (   (cc.item_parent = im.item_parent or cc.item_grandparent = im.item_grandparent)
                      and cc.diff_1 = im.diff_1)
                  and cc.item_level_index = 2)
              or (   (   (cc.item_parent = im.item_parent or cc.item_grandparent = im.item_grandparent)
                      and cc.diff_2 = im.diff_2)
                  and cc.item_level_index = 3)
              or (   (   (cc.item_parent = im.item_parent or cc.item_grandparent = im.item_grandparent)
                      and cc.diff_3 = im.diff_3)
                  and cc.item_level_index = 4)
              or (   (   (cc.item_parent = im.item_parent or cc.item_grandparent = im.item_grandparent)
                      and cc.diff_4 = im.diff_4)
                  and cc.item_level_index = 5)
              or (   (cc.item_parent = im.item_parent or cc.item_grandparent = im.item_grandparent)
                  and cc.item_level_index = 6));

BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if IO_vdate is NULL then
      IO_vdate := GET_VDATE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_CHECK_CONTRACT_INFO',
                    'CONTRACT_HEADER, CONTRACT_COST, ITEM_MASTER',
                    'Contract No.: '||to_char(I_contract_no)||', Item: '||I_item);
   open C_CHECK_CONTRACT_INFO;

   SQL_LIB.SET_MARK('FETCH',
                    'C_CHECK_CONTRACT_INFO',
                    'CONTRACT_HEADER, CONTRACT_COST, ITEM_MASTER',
                    'Contract No.: '||to_char(I_contract_no)||', Item: '||I_item);
   fetch C_CHECK_CONTRACT_INFO into L_record_found, O_orderable_ind;

   if C_CHECK_CONTRACT_INFO%NOTFOUND then
      O_valid := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG ('CONTRACT_NOT_VALID_ITEM',
                                             to_char(I_contract_no),
                                             I_item,
                                             NULL);
   else
      O_valid := TRUE;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_CHECK_CONTRACT_INFO',
                    'CONTRACT_HEADER, CONTRACT_COST, ITEM_MASTER',
                    'Contract No.: '||to_char(I_contract_no)||', Item: '||I_item);
   close C_CHECK_CONTRACT_INFO;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALIDATE_CONTRACT_NO;
--------------------------------------------------------------------------------
FUNCTION INSERT_UPDATE_CONTRACT_ORDLOC
         (O_error_message         IN OUT VARCHAR2,
          I_loc_group             IN     VARCHAR2,
          I_loc_group_value       IN     VARCHAR2,
          I_qty_ordered           IN     CONTRACT_ORDLOC.QTY_ORDERED%TYPE,
          I_contract_ordhead_seq  IN     CONTRACT_ORDLOC.CONTRACT_ORDHEAD_SEQ%TYPE,
          I_contract_no           IN     CONTRACT_ORDLOC.CONTRACT_NO%TYPE,
          I_item                  IN     CONTRACT_ORDSKU.ITEM%TYPE)
   return BOOLEAN is
   ---
   L_program      VARCHAR2(60) := 'CONTRACT_DETAIL_SQL.INSERT_UPDATE_CONTRACT_ORDLOC';
   L_record_found VARCHAR2(1);
   ---
BEGIN
   if I_loc_group is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_LOC_GROUP',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_qty_ordered is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_QTY_ORDERED',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_contract_ordhead_seq is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_ORDHEAD_SEQ',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_item is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if I_loc_group = 'L' then
      --- Insert for a location trait.
      insert into contract_ordloc
         (contract_ordhead_seq,
          contract_no,
          item,
          location,
          loc_type,
          order_no,
          unit_retail,
          qty_ordered)
          select I_contract_ordhead_seq,
                 I_contract_no,
                 I_item,
                 lt.store,
                 'S',
                  NULL,
                  0,
                 I_qty_ordered
           from store s,
                loc_traits_matrix lt
          where s.store = lt.store
            and s.stockholding_ind = 'Y'
            and (to_char(lt.loc_trait) = I_loc_group_value)
            and not exists (select 'x'
                              from contract_ordloc co
                             where co.item                 = I_item
                               and co.contract_ordhead_seq = I_contract_ordhead_seq
                               and co.location             = s.store);
      ---
      update contract_ordloc co
         set qty_ordered = I_qty_ordered
       where co.item                  = I_item
         and co.contract_ordhead_seq = I_contract_ordhead_seq
         and co.location             in (select s.store
                                           from store s,
                                                loc_traits_matrix ltm
                                          where s.store = ltm.store
                                            and s.stockholding_ind = 'Y'
                                            and (to_char(ltm.loc_trait) = I_loc_group_value));
   elsif I_loc_group != 'W' then
      --- Insert for store groups.
      insert into contract_ordloc
         (contract_ordhead_seq,
          contract_no,
          item,
          location,
          loc_type,
          order_no,
          unit_retail,
          qty_ordered)
       select I_contract_ordhead_seq,
              I_contract_no,
              I_item,
              s.store,
              'S',
              NULL,
               0,
              I_qty_ordered
        from store s, district d
       where (   (s.store_class             = I_loc_group_value and I_loc_group = 'C')
              or ( to_char(s.district)      = I_loc_group_value and I_loc_group = 'D')
              or ( to_char(d.region)        = I_loc_group_value and I_loc_group = 'R')
              or ( to_char(s.transfer_zone) = I_loc_group_value and I_loc_group = 'T')


              or ( to_char(s.store)         = I_loc_group_value and I_loc_group = 'S')
              or ( to_char(s.store)         <> '0'              and I_loc_group = 'AS'))
         and s.stockholding_ind = 'Y'
         and s.district = d.district
         and not exists
           (select 'x'
              from contract_ordloc co
             where co.item                 = I_item
               and co.contract_ordhead_seq = I_contract_ordhead_seq
               and co.location             = s.store);
      ---
      update contract_ordloc co
         set co.qty_ordered = I_qty_ordered
       where co.item                 = I_item
         and co.contract_ordhead_seq = I_contract_ordhead_seq
         and co.location in
            (select s.store
               from store s,
                    district d
              where ((s.store_class            = I_loc_group_value and I_loc_group = 'C')
                 or ( to_char(s.district)      = I_loc_group_value and I_loc_group = 'D')
                 or ( to_char(d.region)        = I_loc_group_value and I_loc_group = 'R')
                 or ( to_char(s.transfer_zone) = I_loc_group_value and I_loc_group = 'T')


                 or ( to_char(s.store)         = I_loc_group_value and I_loc_group = 'S')
                 or ( to_char(s.store)         <> '0'              and I_loc_group = 'AS'))
                and s.stockholding_ind = 'Y'
                and s.district = d.district);
   else --- I_loc_group is W
      --- Insert for warehouse.
      insert into contract_ordloc
         (contract_ordhead_seq,
          contract_no,
          item,
          location,
          loc_type,
          order_no,
          unit_retail,
          qty_ordered)
          select I_contract_ordhead_seq,
                 I_contract_no,
                 I_item,
                 wh,
                 'W',
                 NULL,
                 0,
                 I_qty_ordered
           from wh
          where wh.wh = I_loc_group_value
            and wh.stockholding_ind = 'Y'
            and not exists (select 'x'
                              from contract_ordloc
                             where item                 = I_item
                               and contract_no          = I_contract_no
                               and contract_ordhead_seq = I_contract_ordhead_seq
                               and location             = wh.wh);
      ---
      update contract_ordloc
         set qty_ordered = I_qty_ordered
       where location             = I_loc_group_value
         and contract_no          = I_contract_no
         and contract_ordhead_seq = I_contract_ordhead_seq
         and item                 = I_item;
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
END INSERT_UPDATE_CONTRACT_ORDLOC;
--------------------------------------------------------------------------------
FUNCTION CREATE_FROM_EXISTING
         (O_error_message           IN OUT VARCHAR2,
          O_dates_auto_adjust       IN OUT BOOLEAN,
          IO_contract_approval_ind  IN OUT VARCHAR2,
          I_new_contract_no         IN     CONTRACT_HEADER.CONTRACT_NO%TYPE,
          I_existing_contract_no    IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program      VARCHAR2(60)                     := 'CONTRACT_DETAIL_SQL.CREATE_FROM_EXISTING';
   L_user_id      CONTRACT_HEADER.CREATE_ID%TYPE   := USER;
   L_vdate        CONTRACT_HEADER.CREATE_DATE%TYPE := GET_VDATE;
   L_start_date   CONTRACT_HEADER.START_DATE%TYPE;
   L_end_date     CONTRACT_HEADER.END_DATE%TYPE;
   L_ready_date   CONTRACT_DETAIL.READY_DATE%TYPE;
   ---
   cursor C_GET_DATE is
      select start_date,
             end_date
        from contract_header
       where contract_no = I_existing_contract_no;

   cursor C_GET_READY_DATE is
      select ready_date
        from contract_detail
       where contract_no = I_existing_contract_no;
BEGIN
   if I_existing_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_EXISTING_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_new_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_NEW_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_DATE',
                    'CONTRACT_HEADER',
                    'Contract No.: '||to_char(I_existing_contract_no));
   open  C_GET_DATE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_DATE',
                    'CONTRACT_HEADER',
                    'Contract No.: '||to_char(I_existing_contract_no));
   fetch C_GET_DATE into L_start_date,
                         L_end_date;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_DATE',
                    'CONTRACT_HEADER',
                    'Contract No.: '||to_char(I_existing_contract_no));
   close C_GET_DATE;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_READY_DATE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_existing_contract_no));
   open C_GET_READY_DATE;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_READY_DATE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_existing_contract_no));
   fetch C_GET_READY_DATE into L_ready_date;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_READY_DATE',
                    'CONTRACT_DETAIL',
                    'Contract No.: '||to_char(I_existing_contract_no));
   close C_GET_READY_DATE;
   ---
   if L_start_date < L_vdate and L_end_date < L_vdate then
      O_dates_auto_adjust := TRUE;
      O_error_message := SQL_LIB.CREATE_MSG('CNTR_DATE_UPDTD',
                                            NULL,
                                            NULL,
                                            NULL);
      L_start_date := L_vdate;
      L_end_date   := L_vdate;
      L_ready_date := NULL;
   else
      O_dates_auto_adjust := FALSE;
   end if;
   ---
   insert into contract_header
               (contract_no,
                contract_type,
                dept,
                supplier,
                terms,
                status,
                status_date,
                create_date,
                create_id,
                submitted_date,
                submitted_id,
                approval_date,
                approval_id,
                review_date,
                review_id,
                cancel_date,
                cancel_id,
                complete_date,
                start_date,
                end_date,
                last_ordered_date,
                distributor,
                country_id,
                currency_code,
                ship_method,
                total_cost,
                outstand_cost,
                est_duty,
                est_expenses,
                edi_contract_ind,
                edi_sent_ind,
                contract_approval_ind,
                orderable_ind,
                cur_repl_cost,
                comment_desc)
      select  I_new_contract_no,
              ch.contract_type,
              ch.dept,
              ch.supplier,
              ch.terms,
              'W',          -- status
              ch.status_date,
              L_vdate,      -- create date
              L_user_id,    -- create id
              NULL,         -- submitted date
              NULL,         -- submitted id
              NULL,         -- approval date
              NULL,         -- approval id
              NULL,         -- review date
              NULL,         -- review id
              NULL,         -- cancel date
              NULL,         -- cancel id
              NULL,         -- complete date
              L_start_date, -- start date
              L_end_date,   -- end date
              NULL,         -- last ordered date
              ch.distributor,
              ch.country_id,
              ch.currency_code,
              ch.ship_method,
              0,            -- total cost
              0,            -- outstand cost
              ch.est_duty,
              ch.est_expenses,
              ch.edi_contract_ind,
              ch.edi_sent_ind,
              ch.contract_approval_ind,
              ch.orderable_ind,
              0,            -- cur repl cost
              ch.comment_desc
         from contract_header ch
        where ch.contract_no = I_existing_contract_no;
   ---
   --- Decode contract approval
   if IO_contract_approval_ind != 'Y' then
      IO_contract_approval_ind := 'N';
   end if;
   ---
   insert into contract_detail
               (contract_no,
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
        select I_new_contract_no,
               c.seq_no,
               c.item_grandparent,
               c.item_parent,
               c.item,
               c.ref_item,
               c.diff_1,
               c.diff_2,
               c.diff_3,
               c.diff_4,
               c.loc_type,
               c.location,
               L_ready_date,
               c.qty_contracted,
               0,
               0,
               c.item_level_index,
               c.cur_repl_qty
          from contract_detail c
         where c.contract_no = I_existing_contract_no;
   ---
   insert into contract_cost
               (contract_no,
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
        select I_new_contract_no,
            c.seq_no,
               c.item_grandparent,
               c.item_parent,
               c.item,
               c.diff_1,
               c.diff_2,
               c.diff_3,
               c.diff_4,
               c.unit_cost,
               c.item_level_index
          from contract_cost c
         where c.contract_no = I_existing_contract_no;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END CREATE_FROM_EXISTING;
--------------------------------------------------------------------------------
FUNCTION VALID_CNTRACT_MATRIX_TEMP_LIST
         (O_error_message     IN OUT VARCHAR2,
          O_item_exists       IN OUT BOOLEAN,
          O_list_desc         IN OUT SKULIST_HEAD.SKULIST_DESC%TYPE,
          I_dept              IN     ITEM_MASTER.DEPT%TYPE,
          I_supplier          IN     ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
          I_origin_country_id IN     ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
          I_item_list         IN     SKULIST_DETAIL.SKULIST%TYPE,
          I_contract_no       IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program           VARCHAR2(60) := 'CONTRACT_DETAIL_SQL.VALID_CNTRACT_MATRIX_TEMP_LIST';
   L_record_found_ind  VARCHAR2(1);
   ---
   cursor C_ITEM_EXISTS is
      select 'x'
        from skulist_detail s,
             item_master im,
             item_supp_country i
       where s.skulist           = I_item_list
         and im.item_level      <= im.tran_level
         and s.item              = im.item
         and im.status           = 'A'
         and im.dept             = I_dept
         and im.item             = i.item
         and i.supplier          = I_supplier
         and i.origin_country_id = I_origin_country_id
         and not exists (select 'x'
                           from contract_matrix_temp cmt
                          where cmt.contract_no = I_contract_no
                            and (   (    s.tran_level - s.item_level = 2
                                     and cmt.item_grandparent        = s.item)
                                 or (    s.tran_level - s.item_level = 1
                                     and cmt.item_parent             = s.item)
                                 or (    s.tran_level - s.item_level = 0
                                     and cmt.item                    = s.item)));
BEGIN
   if I_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_DEPT',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_SUPPLIER',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ORIGIN_COUNTRY_ID',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_item_list is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM_LIST',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_ITEM_EXISTS',
                    'SKULIST_DETAIL, ITEM_MASTER, ITEM_SUPPLIER',
                    'Contract No.: '||to_char(I_contract_no) ||
                    ' Item List: '||  to_char(I_item_list)   ||
                    ' Dept: '||       to_char(I_dept)        ||
                    ' Supplier '||    to_char(I_supplier)    ||
                    ' Country: '||    I_origin_country_id);
   open  C_ITEM_EXISTS;
   SQL_LIB.SET_MARK('FETCH',
                    'C_ITEM_EXISTS',
                    'SKULIST_DETAIL, ITEM_MASTER, ITEM_SUPPLIER',
                    'Contract No.: '||to_char(I_contract_no) ||
                    ' Item List: '||  to_char(I_item_list)   ||
                    ' Dept: '||       to_char(I_dept)        ||
                    ' Supplier '||    to_char(I_supplier)    ||
                    ' Country: '||    I_origin_country_id);
   fetch C_ITEM_EXISTS into L_record_found_ind;
   if C_ITEM_EXISTS%NOTFOUND then
      O_item_exists := FALSE;
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_RECS',
                                            to_char(I_item_list),
                                            NULL,
                                            NULL);
   else
      O_item_exists := TRUE;
      if ITEMLIST_ATTRIB_SQL.GET_NAME(O_error_message,
                                      I_item_list,
                                      O_list_desc) = FALSE then
         return FALSE;
      end if;
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_ITEM_EXISTS',
                    'SKULIST_DETAIL, ITEM_MASTER, ITEM_SUPPLIER',
                    'Contract No.: '||to_char(I_contract_no) ||
                    ' Item List: '||  to_char(I_item_list)   ||
                    ' Dept: '||       to_char(I_dept)        ||
                    ' Supplier '||    to_char(I_supplier)    ||
                    ' Country: '||    I_origin_country_id);
   close C_ITEM_EXISTS;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END VALID_CNTRACT_MATRIX_TEMP_LIST;
--------------------------------------------------------------------------------
FUNCTION INS_CNTRACT_MATRIX_TEMP_LIST
         (O_error_message       IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
          I_dept                IN       ITEM_MASTER.DEPT%TYPE,
          I_supplier            IN       ITEM_SUPP_COUNTRY.SUPPLIER%TYPE,
          I_origin_country_id   IN       ITEM_SUPP_COUNTRY.ORIGIN_COUNTRY_ID%TYPE,
          I_item_list           IN       SKULIST_DETAIL.SKULIST%TYPE,
          I_qty                 IN       CONTRACT_MATRIX_TEMP.QTY%TYPE,
          I_contract_no         IN       CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program  VARCHAR2(60) := 'CONTRACT_DETAIL_SQL.INS_CNTRACT_MATRIX_TEMP_LIST';
BEGIN
   if I_dept is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_DEPT',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_supplier is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_SUPPLIER',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_origin_country_id is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ORIGIN_COUNTRY_ID',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_item_list is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_ITEM_LIST',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   insert into contract_matrix_temp
          (contract_no,
           item_grandparent,
           item_parent,
           item,
           ref_item,
           diff_1,
           diff_2,
           loc_type,
           location,
           ready_date,
           qty,
           unit_cost)
      select I_contract_no,
             decode(              (skd.tran_level - skd.item_level), 2, skd.item,
                    decode(       (skd.tran_level - skd.item_level), 1, iem.item_parent,
                           decode((skd.tran_level - skd.item_level), 0, iem.item_grandparent,
                                   NULL))),
             /* If the item is 2 levels above the tran. level, the column gets the item.
                    Else if the item is 1 level above the tran. level, the column gets the item's parent.
                           Else if the item is at the tran. level, the column gets the item's grandparent.
                                   Else the column gets NULL. */
             decode(              (skd.tran_level - skd.item_level), 1, skd.item,
                    decode(       (skd.tran_level - skd.item_level), 0, iem.item_parent, NULL)),
             /* If the item is 1 level above the tran. level, the column gets the item.
                    Else if the item is at the tran. level, the column gets the item's parent.
                                   Else the column gets NULL. */
             decode((skd.tran_level - skd.item_level), 0, skd.item,
                     NULL),
             /* If the item is at the tran. level, the column gets the item.
                     Else the column gets NULL. */
             NULL, -- ref item
             decode((skd.tran_level - skd.item_level), 0, NULL,
                     iem.diff_1),
             /* If the item is at the tran. level, the column gets NULL.
                     Else the column gets diff 1. */
             decode((skd.tran_level - skd.item_level), 0, NULL,
                     iem.diff_2),
             /* If the item is at the tran. level, the column gets NULL.
                     Else the column gets diff 2. */
             NULL,
             NULL,
             NULL,
             I_qty,
             NULL
        from skulist_detail skd,
             item_master iem,
             item_supp_country isc
       where skd.skulist           = I_item_list
         and iem.item_level        <= iem.tran_level
         and skd.item              = iem.item
         and iem.status            = 'A'
         and ((iem.orderable_ind = 'Y' and iem.inventory_ind = 'Y')
             or (iem.pack_ind = 'Y' and iem.sellable_ind = 'Y'))
         and iem.dept              = I_dept
         and iem.item              = isc.item
         and isc.supplier          = I_supplier
         and isc.origin_country_id = I_origin_country_id
         and not exists (select 'x'
                           from contract_matrix_temp cmt
                          where cmt.contract_no = I_contract_no
                            and (   (skd.tran_level - skd.item_level  = 2
                                     and cmt.item_grandparent         = skd.item
                                     and cmt.item_parent is NULL)
                                 or (skd.tran_level - skd.item_level  = 1
                                     and cmt.item_parent              = skd.item
                                     and cmt.item is NULL)
                                 or ( skd.tran_level - skd.item_level = 0
                                     and cmt.item                     = skd.item)));
   if SQL%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_RECS',
                                            to_char(I_item_list),
                                            NULL,
                                            NULL);
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
END INS_CNTRACT_MATRIX_TEMP_LIST;
--------------------------------------------------------------------------------
FUNCTION DELETE_CONTRACT_MATRIX_TEMP
         (O_error_message  IN OUT VARCHAR2,
          I_contract_no    IN     CONTRACT_MATRIX_TEMP.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program       VARCHAR2(60)  := 'CONTRACT_DETAIL_SQL.DELETE_CONTRACT_MATRIX_TEMP';
BEGIN
   if I_contract_no is NULL then
      O_error_message := SQL_LIB.CREATE_MSG('INVALID_PARM',
                                            'I_CONTRACT_NO',
                                            'NULL',
                                            'NOT NULL');
      return FALSE;
   end if;
   ---
   if LOCK_CONTRACT_MATRIX_TEMP(O_error_message,
                                I_contract_no) = FALSE then
      return FALSE;
   end if;
   ---
   delete from contract_matrix_temp
    where contract_no = I_contract_no;
   ---
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END DELETE_CONTRACT_MATRIX_TEMP;
--------------------------------------------------------------------------------
FUNCTION GET_CONTRACT_MATRIX_TEMP_QTY
         (O_error_message     IN OUT VARCHAR2,
          I_contract_no       IN     CONTRACT_HEADER.CONTRACT_NO%TYPE)
   return BOOLEAN is
   ---
   L_program           VARCHAR2(60) := 'CONTRACT_DETAIL_SQL.GET_CNTRACT_MATRIX_TEMP_QTY';
   L_record_found_ind  VARCHAR2(1);
   L_ready_date        CONTRACT_MATRIX_TEMP.READY_DATE%TYPE;
   L_pct               DATE_DIST_TEMP.DIST_PCT%TYPE;
   L_totqty            CONTRACT_MATRIX_TEMP.QTY%TYPE;
   L_sumqty            CONTRACT_MATRIX_TEMP.QTY%TYPE;
   L_diffqty           CONTRACT_MATRIX_TEMP.QTY%TYPE;
   ---
   cursor C_GET_QTY is
      select qty
        from contract_matrix_temp
       where contract_no = I_contract_no
         and ready_date IS NULL;


   cursor C_GET_DISTDATE is
      select dist_pct,dist_date
        from date_dist_temp
       where contract_no = I_contract_no;

   cursor C_GET_SUMQTY is
      select sum(qty)
        from contract_matrix_temp
       where contract_no = I_contract_no
         and ready_date IS NOT NULL;

   cursor C_GET_RDYDATE is
      select ready_date
        from contract_matrix_temp
       where contract_no = I_contract_no
         and ready_date IS NOT NULL;


BEGIN

   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_QTY',
                    'CONTRACT_MATRIX_TEMP',
                    'Contract No.: '|| I_contract_no);
   open  C_GET_QTY;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_QTY',
                    'CONTRACT_MATRIX_TEMP',
                    'Contract No.: '|| I_contract_no);
   fetch C_GET_QTY into L_totqty;
   if C_GET_QTY%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_QTY',
                                            I_contract_no,
                                            NULL,
                                            NULL);
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_QTY',
          'CONTRACT_MATRIX_TEMP',
                    'Contract No.: '|| I_contract_no);
   close C_GET_QTY;
   ---
   SQL_LIB.SET_MARK('OPEN',
                       'C_GET_DISTDATE',
                       'DATE_DIST_TEMP',
                       'Contract No.: '|| I_contract_no);
   open  C_GET_DISTDATE;
   LOOP
     fetch C_GET_DISTDATE into L_pct,L_ready_date;
     ------
     EXIT WHEN C_GET_DISTDATE%NOTFOUND;
     -----
         update contract_matrix_temp
                  set qty =  ROUND(L_totqty*L_pct/100.00)
                where contract_no = I_contract_no
                  and ready_date = L_ready_date
                  and (L_totqty > (select sum(qty)
                       from contract_matrix_temp
                    where contract_no = I_contract_no
                      and ready_date IS NOT NULL));
      ---
   END LOOP;
   SQL_LIB.SET_MARK('CLOSE',
                     'C_GET_DISTDATE',
                 'DATE_DIST_TEMP',
                     'Contract No.: '|| I_contract_no);
   close C_GET_DISTDATE;
   ----
   SQL_LIB.SET_MARK('OPEN',
                       'C_GET_SUMQTY',
                       'CONTRACT_MATRIX_TEMP',
                       'Contract No.: '|| I_contract_no);

   open  C_GET_SUMQTY;
   SQL_LIB.SET_MARK('FETCH',
                     'C_GET_SUMQTY',
                     'CONTRACT_MATRIX_TEMP',
                     'Contract No.: '|| I_contract_no);
   fetch C_GET_SUMQTY into L_sumqty;
   if C_GET_SUMQTY%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('NO_QTY',
                                               I_contract_no,
                                               NULL,
                                               NULL);
   end if;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_SUMQTY',
             'CONTRACT_MATRIX_TEMP',
                    'Contract No.: '|| I_contract_no);
   close C_GET_SUMQTY;
   ---
   L_diffqty := L_totqty - L_sumqty;

   SQL_LIB.SET_MARK('OPEN',
                     'C_GET_RDYDATE',
                     'CONTRACT_MATRIX_TEMP',
                     'Contract No.: '|| I_contract_no);
   open  C_GET_RDYDATE;
   LOOP
     fetch C_GET_RDYDATE into L_ready_date;
     ------
     EXIT WHEN C_GET_RDYDATE%NOTFOUND;
     ------

               update contract_matrix_temp
                  set qty =  qty + 1
                where contract_no = I_contract_no
                  and ready_date = L_ready_date
                  and L_diffqty > 0;

                L_diffqty := L_diffqty - 1;

      -----
   END LOOP;
   close C_GET_RDYDATE;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG ('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             to_char(SQLCODE));
      return FALSE;
END GET_CONTRACT_MATRIX_TEMP_QTY;
--------------------------------------------------------------------------------
END CONTRACT_DETAIL_SQL;
/

