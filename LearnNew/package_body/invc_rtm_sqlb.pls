CREATE OR REPLACE PACKAGE BODY INVC_RTM_SQL AS
---------------------------------------------------
FUNCTION NON_MERCH_CODE_COMP_CHECK(
        O_error_message       IN OUT   VARCHAR2,
        O_valid               IN OUT   BOOLEAN,
        I_obligation_key      IN       OBLIGATION_COMP.OBLIGATION_KEY%TYPE,
        I_ce_id               IN       CE_CHARGES.CE_ID%TYPE)
      RETURN BOOLEAN IS

   L_program    VARCHAR2(64)   := 'INVC_RTM_SQL.NON_MERCH_COMP_CODE_CHECK';
   L_exists     VARCHAR2(1)    := 'y';

   cursor C_OBLIGATION_KEY_VALIDATE is
      select 'x'
        from obligation_comp oc
       where oc.obligation_key = I_obligation_key
         and not exists( select 'x'
                           from non_merch_code_comp n
                          where n.comp_id = oc.comp_id);

   cursor C_CE_ID_VALIDATE is
      select 'x'
        from ce_charges cc
       where cc.ce_id = I_ce_id
         and NOT exists( select 'x'
                           from non_merch_code_comp n
                          where n.comp_id = cc.comp_id);

BEGIN

   if I_ce_id IS NULL and I_obligation_key IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'OBLIGATION_KEY and CE_ID',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_ce_id IS NULL then

      SQL_LIB.SET_MARK('OPEN',
                       'C_OBLIGATION_KEY_VALIDATE',
                       'OBLIGATION_COMP, NON_MERCH_CODE_COMP',
                       'OBLIGATION_KEY = ' || I_obligation_key);
      open C_OBLIGATION_KEY_VALIDATE;
      SQL_LIB.SET_MARK('FETCH',
                       'C_OBLIGATION_KEY_VALIDATE',
                       'OBLIGATION_COMP, NON_MERCH_CODE_COMP',
                       'OBLIGATION_KEY = ' || I_obligation_key);
      fetch C_OBLIGATION_KEY_VALIDATE into L_exists;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_OBLIGATION_KEY_VALIDATE',
                       'OBLIGATION_COMP, NON_MERCH_CODE_COMP',
                       'OBLIGATION_KEY = ' || I_obligation_key);

      close C_OBLIGATION_KEY_VALIDATE;

   elsif I_obligation_key IS NULL then

      SQL_LIB.SET_MARK('OPEN',
                       'C_CE_ID_VALIDATE',
                       'CE_CHARGES, NON_MERCH_CODE_COMP',
                       'CE_ID = ' || I_ce_id);
      open C_CE_ID_VALIDATE;
      SQL_LIB.SET_MARK('FETCH',
                       'C_CE_ID_VALIDATE',
                       'CE_CHARGES, NON_MERCH_CODE_COMP',
                       'CE_ID = ' || I_ce_id);
      fetch C_CE_ID_VALIDATE into L_exists;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_CE_ID_VALIDATE',
                       'CE_CHARGES, NON_MERCH_CODE_COMP',
                       'CE_ID = ' || I_ce_id);
      close C_CE_ID_VALIDATE;

   end if;

   if L_exists = 'x' then
      O_valid := FALSE;
   else
      O_valid := TRUE;
   end if;

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM,
                                            L_program, to_char(SQLCODE));
      return FALSE;

END NON_MERCH_CODE_COMP_CHECK;

---------------------------------------------------
FUNCTION OBL_INVC_WRITE(
        O_error_message     IN OUT   VARCHAR2,
        I_obligation_key    IN       OBLIGATION.OBLIGATION_KEY%TYPE,
        I_ext_invc_no       IN       OBLIGATION.EXT_INVC_NO%TYPE,
        I_ext_invc_date     IN       OBLIGATION.EXT_INVC_DATE%TYPE,
        I_currency_code     IN       OBLIGATION.CURRENCY_CODE%TYPE,
        I_exchange_rate     IN       OBLIGATION.EXCHANGE_RATE%TYPE,
        I_supplier          IN       OBLIGATION.SUPPLIER%TYPE,
        I_partner_type      IN       OBLIGATION.PARTNER_TYPE%TYPE,
        I_partner_id        IN       OBLIGATION.PARTNER_ID%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)                         := 'INVC_RTM_SQL.OBL_INVC_WRITE';
   L_valid              BOOLEAN;
   L_duedays            TERMS.DUEDAYS%TYPE;
   L_terms              INVC_HEAD.TERMS%TYPE;
   L_addr_key           INVC_HEAD.ADDR_KEY%TYPE;
   L_due_date           INVC_HEAD.DUE_DATE%TYPE;
   L_next_invc_id       INVC_HEAD.INVC_ID%TYPE;
   L_vdate              PERIOD.VDATE%TYPE                    := GET_VDATE;
   L_non_merch_code     INVC_NON_MERCH.NON_MERCH_CODE%TYPE;
   L_comp_amt_sum       INVC_NON_MERCH.NON_MERCH_AMT%TYPE;
   L_vat_ind            SYSTEM_OPTIONS.VAT_IND%TYPE;
   L_zero_rate_vat_code VAT_CODE_RATES.VAT_CODE%TYPE         := NULL;
   L_comment            OBLIGATION.COMMENT_DESC%TYPE;

   cursor C_PARTNER is
      select p.terms,
             t.duedays
        from partner p,
             terms t
       where p.partner_id = I_partner_id
         and p.partner_type = I_partner_type
         and t.terms = p.terms;

   cursor C_SUPS is
      select s.terms,
             t.duedays
        from sups s,
             terms t
       where s.supplier = I_supplier
         and t.terms = s.terms;

   cursor C_NON_MERCH_CODE is
      select distinct n.non_merch_code
        from non_merch_code_comp n
       where exists (select 'x'
                       from obligation_comp oc
                      where oc.obligation_key = I_obligation_key
                        and oc.comp_id = n.comp_id);

   cursor C_SUM_OBLIGATION_COMP_AMT is
      select sum(oc.amt)
        from obligation_comp oc
       where oc.obligation_key = I_obligation_key
         and exists (select 'x'
                       from non_merch_code_comp n
                      where n.comp_id = oc.comp_id
                        and n.non_merch_code = L_non_merch_code);

   cursor C_SYSTEM_VAT_IND is
      select vat_ind
        from system_options;

   cursor C_GET_OBLIGATION_COMMENT is
      select comment_desc
        from obligation
       where obligation_key = I_obligation_key;


BEGIN

   if I_obligation_key IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'OBLIGATION_KEY',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_ext_invc_no IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'EXT_INVC_NO',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_ext_invc_date IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'EXT_INVC_DATE',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_currency_code IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'CURRENCY_CODE',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_exchange_rate IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'EXCHANGE_RATE',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if NOT INVC_RTM_SQL.NON_MERCH_CODE_COMP_CHECK(O_error_message,
                                                 L_valid,
                                                 I_obligation_key,
                                                 NULL) then
      return FALSE;
   end if;

   if NOT L_valid then
      O_error_message := sql_lib.create_msg('INV_OBL_NON_MRCH_COMP', NULL,
                                            NULL, NULL);
      return FALSE;
   end if;




   if I_partner_type IS NOT NULL and I_partner_id IS NOT NULL then

      SQL_LIB.SET_MARK('OPEN',
                       'C_PARTNER',
                       'PARTNER, TERMS',
                       'PARTNER_ID = ' || I_partner_id || ' PARTNER_TYPE = ' || I_partner_type);
      open C_PARTNER;
      SQL_LIB.SET_MARK('FETCH',
                       'C_PARTNER',
                       'PARTNER, TERMS',
                       'PARTNER_ID = ' || I_partner_id || ' PARTNER_TYPE = ' || I_partner_type);
      fetch C_PARTNER into L_terms,
               L_duedays;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_PARTNER',
                       'PARTNER, TERMS',
                       'PARTNER_ID = ' || I_partner_id || ' PARTNER_TYPE = ' || I_partner_type);
      close C_PARTNER;

      if NOT PARTNER_SQL.GET_PART_PRIMARY_ADDR(O_error_message,
                                               L_addr_key,
                                               I_partner_id,
                                               I_partner_type,
                                               '05') then
         return FALSE;
      end if;

   elsif I_supplier IS NOT NULL then
      SQL_LIB.SET_MARK('OPEN',
                       'C_SUPS',
                       'SUPS, TERMS',
                       'SUPPLIER = ' || I_supplier);
      open C_SUPS;
      SQL_LIB.SET_MARK('FETCH',
                       'C_SUPS',
                       'SUPS, TERMS',
                       'SUPPLIER = ' || I_supplier);
      fetch C_SUPS into L_terms,
                        L_duedays;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SUPS',
                       'SUPS, TERMS',
                       'SUPPLIER = ' || I_supplier);
      close C_SUPS;

      if NOT SUPP_ATTRIB_SQL.GET_SUP_PRIMARY_ADDR(O_error_message,
                                                  L_addr_key,
                                                  I_supplier,
                                                  '05') then
         return FALSE;
      end if;
   elsif (I_partner_id IS NULL and I_partner_type IS NOT NULL) or
         (I_partner_id IS NOT NULL and I_partner_type IS NULL) then
            O_error_message := sql_lib.create_msg('INVALID_PARM',
                                                  'PARTNER_ID and PARTNER_TYPE',
                                                  'NULL', 'NOT NULL');

      return FALSE;
   end if;

   L_due_date := I_ext_invc_date + L_duedays;
   ---
   if NOT INVC_SQL.NEXT_INVC_ID(O_error_message,
                                L_next_invc_id) then
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_OBLIGATION_COMMENT',
                    'OBLIGATION','OBLIGATION_KEY = '||I_obligation_key);
   open C_GET_OBLIGATION_COMMENT;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_OBLIGATION_COMMENT',
                    'OBLIGATION','OBLIGATION_KEY = '||I_obligation_key);
   fetch C_GET_OBLIGATION_COMMENT into L_comment;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_OBLIGATION_COMMENT',
                    'OBLIGATION','OBLIGATION_KEY = '||I_obligation_key);
   close C_GET_OBLIGATION_COMMENT;
   ---

   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'INVC_HEAD','INVC_ID = ' || L_next_invc_id);
   insert into invc_head(invc_id,
                         invc_type,
                         supplier,
                         ext_ref_no,
                         status,
                         edi_invc_ind,
                         edi_sent_ind,
                         match_fail_ind,
                         obligation_key,
                         terms,
                         due_date,
                         terms_dscnt_appl_ind,
                         terms_dscnt_appl_non_mrch_ind,
                         create_id,
                         create_date,
                         invc_date,
                         force_pay_ind,
                         currency_code,
                         exchange_rate,
                         direct_ind,
                         partner_type,
                         partner_id,
                         addr_key,
                         paid_ind,
                         comments)
                values  (L_next_invc_id,
                         'N',
                         I_supplier,
                         'OB' || I_ext_invc_no,
                         'A',
                         'N',
                         'N',
                         'N',
                         I_obligation_key,
                         L_terms,
                         L_due_date,
                         'N',
                         'N',
                         'INVC_RTM_SQL.OBL_INVC_WRITE',
                         L_vdate,
                         I_ext_invc_date,
                         'N',
                         I_currency_code,
                         I_exchange_rate,
                         'N',
                         I_partner_type,
                         I_partner_id,
                         L_addr_key,
                         DECODE(L_terms, 'DNP', 'Y', 'N'),
                         L_comment);

   SQL_LIB.SET_MARK('OPEN',
                    'C_SYSTEM_VAT_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   open C_SYSTEM_VAT_IND;
   SQL_LIB.SET_MARK('FETCH',
                    'C_SYSTEM_VAT_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   fetch C_SYSTEM_VAT_IND into L_vat_ind;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_SYSTEM_VAT_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   close C_SYSTEM_VAT_IND;

   if L_vat_ind = 'Y' then
      if NOT VAT_SQL.GET_ZERO_RATE_VAT_CODE (O_error_message,
                                             L_zero_rate_vat_code) then
         return FALSE;
      end if;
   end if;

-- loop through all the non_merch_codes on non_merch_code_comp
-- that have records on obligation_comp for I_obligation_key
   for rec in C_NON_MERCH_CODE
      LOOP

         L_non_merch_code := rec.non_merch_code;

         SQL_LIB.SET_MARK('OPEN',
                          'C_SUM_OBLIGATION_COMP_AMT',
                          'OBLIGATION_COMP',
                          'OBLIGATION_KEY = ' || I_obligation_key);
         open C_SUM_OBLIGATION_COMP_AMT;
         SQL_LIB.SET_MARK('FETCH',
                          'C_SUM_OBLIGATION_COMP_AMT',
                          'OBLIGATION_COMP',
                          'OBLIGATION_KEY = ' || I_obligation_key);
         fetch C_SUM_OBLIGATION_COMP_AMT into L_comp_amt_sum;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_SUM_OBLIGATION_COMP_AMT',
                          'OBLIGATION_COMP',
                          'OBLIGATION_KEY = ' || I_obligation_key);
         close C_SUM_OBLIGATION_COMP_AMT;

         SQL_LIB.SET_MARK('INSERT',
                          NULL,
                          'INVC_NON_MERCH',
                          'INVC_ID = ' || L_next_invc_id);
         insert into invc_non_merch (invc_id,
                                     non_merch_code,
                                     non_merch_amt,
                                     service_perf_ind,
                                     vat_code)
                             values (L_next_invc_id,
                                     L_non_merch_code,
                                     L_comp_amt_sum,
                                     'N',
                                     L_zero_rate_vat_code);
      END LOOP;

      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'INVC_XREF',
                       'INVC_ID = ' || L_next_invc_id);
      insert into invc_xref (invc_id,
                             location,
                             loc_type,
                             apply_to_future_ind)
                     values (L_next_invc_id,
                             -999999999,
                             'S',
                             'N');

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM,
                                            L_program, to_char(SQLCODE));
      return FALSE;

END OBL_INVC_WRITE;
----------------------------------------------------
FUNCTION CE_INVC_WRITE (
        O_error_message     IN OUT   VARCHAR2,
        I_ce_id             IN       CE_HEAD.CE_ID%TYPE,
        I_entry_no          IN       CE_HEAD.ENTRY_NO%TYPE,
        I_entry_date        IN       CE_HEAD.ENTRY_DATE%TYPE,
        I_payee             IN       CE_HEAD.PAYEE%TYPE,
        I_payee_type        IN       CE_HEAD.PAYEE_TYPE%TYPE,
        I_currency_code     IN       CE_HEAD.CURRENCY_CODE%TYPE,
        I_exchange_rate     IN       CE_HEAD.EXCHANGE_RATE%TYPE)
      RETURN BOOLEAN IS

   L_program             VARCHAR2(64)                         := 'INVC_RTM_SQL.CE_INVC_WRITE';
   L_valid               BOOLEAN;
   L_duedays             TERMS.DUEDAYS%TYPE;
   L_terms               INVC_HEAD.TERMS%TYPE;
   L_addr_key            INVC_HEAD.ADDR_KEY%TYPE;
   L_due_date            INVC_HEAD.DUE_DATE%TYPE;
   L_next_invc_id        INVC_HEAD.INVC_ID%TYPE;
   L_vdate               PERIOD.VDATE%TYPE                    := GET_VDATE;
   L_non_merch_code      INVC_NON_MERCH.NON_MERCH_CODE%TYPE;
   L_comp_amt            INVC_NON_MERCH.NON_MERCH_AMT%TYPE    := 0;
   L_total_comp_amt      INVC_NON_MERCH.NON_MERCH_AMT%TYPE    := 0;
   L_item                CE_CHARGES.ITEM%TYPE;
   L_pack_item           CE_CHARGES.PACK_ITEM%TYPE;
   L_prev_pack_item      CE_CHARGES.PACK_ITEM%TYPE            := -999;
   L_pack_qty            CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE;
   L_packitem_qty        PACKITEM.PACK_QTY%TYPE;
   L_standard_uom        UOM_CLASS.UOM%TYPE;
   L_standard_class      UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor         ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_standard_qty        PACKITEM.PACK_QTY%TYPE;
   L_vat_ind             SYSTEM_OPTIONS.VAT_IND%TYPE;
   L_zero_rate_vat_code  VAT_CODE_RATES.VAT_CODE%TYPE := NULL;

   cursor C_PARTNER is
      select p.terms,
             t.duedays
        from partner p,
             terms t
       where p.partner_id = I_payee
         and p.partner_type = I_payee_type
         and t.terms = p.terms;

   cursor C_NON_MERCH_CODE is
      select distinct n.non_merch_code
        from non_merch_code_comp n
       where exists (select 'x'
                       from ce_charges cc
                      where cc.ce_id = I_ce_id
                        and cc.comp_id = n.comp_id);

   cursor C_CE_CHARGES is
      select cc.item,
             cc.pack_item,
             cc.comp_id,
             cc.comp_value,
             coi.manifest_item_qty,
             coi.manifest_item_qty_uom
        from ce_charges cc,
             ce_ord_item coi,
             non_merch_code_comp n
       where n.non_merch_code = L_non_merch_code
         and n.comp_id = cc.comp_id
         and cc.ce_id = coi.ce_id
         and cc.ce_id = I_ce_id
    order by pack_item;

   cursor C_PACKITEM is
      select pack_qty
        from packitem
       where pack_no = L_pack_item
         and item = L_item;

   cursor C_VDATE is
      select vdate
        from period;

   cursor C_SYSTEM_VAT_IND is
      select vat_ind
        from system_options;

BEGIN

   if I_ce_id IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'CE_ID',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_entry_no IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'ENTRY_NO',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_entry_date IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'ENTRY_DATE',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_payee IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'PAYEE',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_payee_type IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'PAYEE_TYPE',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_currency_code IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'CURRENCY_CODE',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if I_exchange_rate IS NULL then
      O_error_message := sql_lib.create_msg('INVALID_PARM', 'EXCHANGE_RATE',
                                            'NULL', 'NOT NULL');
      return FALSE;
   end if;

   if NOT INVC_RTM_SQL.NON_MERCH_CODE_COMP_CHECK(O_error_message,
                                                 L_valid,
                                                 NULL,
                                                 I_ce_id) then
      return FALSE;
   end if;

   if NOT L_valid then
      O_error_message := sql_lib.create_msg('INV_CE_NON_MRCH_COMP', NULL,
                                            NULL, NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('OPEN',
                    'C_PARTNER',
                    'PARTNER, TERMS',
                    'PARTNER_ID = ' || I_payee ||
                    ' PARTNER_TYPE = ' || I_payee_type);

   open C_PARTNER;
   SQL_LIB.SET_MARK('FETCH',
                    'C_PARTNER',
                    'PARTNER, TERMS',
                    'PARTNER_ID = ' || I_payee ||
                    ' PARTNER_TYPE = ' || I_payee_type);

   fetch C_PARTNER into L_terms,
                        L_duedays;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_PARTNER',
                    'PARTNER, TERMS',
                    'PARTNER_ID = ' || I_payee ||
                    ' PARTNER_TYPE = ' || I_payee_type);

   close C_PARTNER;

   if NOT PARTNER_SQL.GET_PART_PRIMARY_ADDR(O_error_message,
                                            L_addr_key,
                                            I_payee,
                                            I_payee_type,
                                            '05') then
      return FALSE;
   end if;

   L_due_date := I_entry_date + L_duedays;
   ---
   if NOT INVC_SQL.NEXT_INVC_ID(O_error_message,
                                L_next_invc_id) then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'INVC_HEAD',
                    'INVC_ID = ' || L_next_invc_id);
   insert into INVC_HEAD(invc_id,
                         invc_type,
                         ext_ref_no,
                         status,
                         edi_invc_ind,
                         edi_sent_ind,
                         match_fail_ind,
                         ce_id,
                         terms,
                         due_date,
                         terms_dscnt_appl_ind,
                         terms_dscnt_appl_non_mrch_ind,
                         create_id,
                         create_date,
                         invc_date,
                         force_pay_ind,
                         currency_code,
                         exchange_rate,
                         direct_ind,
                         partner_type,
                         partner_id,
                         addr_key,
                         paid_ind)
                  values(L_next_invc_id,
                         'N',
                         'CE' || I_entry_no,
                         'A',
                         'N',
                         'N',
                         'N',
                         I_ce_id,
                         L_terms,
                         L_due_date,
                         'N',
                         'N',
                         'INVC_RTM_SQL.CE_INVC_WRITE',
                         L_vdate,
                         I_entry_date,
                         'N',
                         I_currency_code,
                         I_exchange_rate,
                         'N',
                         I_payee_type,
                         I_payee,
                         L_addr_key,
                         DECODE(L_terms, 'DNP', 'Y', 'N'));

   SQL_LIB.SET_MARK('OPEN',
                    'C_SYSTEM_VAT_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   open C_SYSTEM_VAT_IND;
   SQL_LIB.SET_MARK('FETCH',
                    'C_SYSTEM_VAT_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   fetch C_SYSTEM_VAT_IND into L_vat_ind;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_SYSTEM_VAT_IND',
                    'SYSTEM_OPTIONS',
                    NULL);
   close C_SYSTEM_VAT_IND;

   if L_vat_ind = 'Y' then
      if NOT VAT_SQL.GET_ZERO_RATE_VAT_CODE (O_error_message,
                                             L_zero_rate_vat_code) then
         return FALSE;
      end if;
   end if;

-- loop through all the non_merch_codes on non_merch_code_comp
-- that have records on obligation_comp for I_obligation_key
   for rec_non_merch_code in C_NON_MERCH_CODE LOOP
      L_non_merch_code := rec_non_merch_code.non_merch_code;
      L_total_comp_amt := 0;

      for rec_ce_charges in C_CE_CHARGES LOOP

         L_comp_amt  := 0;
         L_pack_item := rec_ce_charges.pack_item;
         L_item      := rec_ce_charges.item;

         if L_pack_item IS NOT NULL then
            if L_pack_item != L_prev_pack_item then
               if NOT CE_CHARGES_SQL.CALC_PACK_QTY(
                                          O_error_message,
                                          L_pack_qty,
                                          L_pack_item,
                                          rec_ce_charges.manifest_item_qty,
                                          rec_ce_charges.manifest_item_qty_uom,
                                          NULL,
                                          NULL) then
                   return FALSE;
               end if;
            end if;

            SQL_LIB.SET_MARK('OPEN',
                             'C_PACKITEM',
                             'PACKITEM',
                             'PACK_ITEM = ' || L_pack_item || ' ITEM = ' || L_item);
            open C_PACKITEM;
            SQL_LIB.SET_MARK('FETCH',
                             'C_PACKITEM',
                             'PACKITEM',
                             'PACK_ITEM = ' || L_pack_item || ' ITEM = ' || L_item);

            fetch C_PACKITEM into L_packitem_qty;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_PACKITEM',
                             'PACKITEM',
                             'PACK_ITEM = ' || L_pack_item || ' ITEM = ' || L_item);

            close C_PACKITEM;

            L_comp_amt := L_packitem_qty * L_pack_qty * rec_ce_charges.comp_value;
            L_prev_pack_item := L_pack_item;

         else
            if NOT ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                    L_standard_uom,
                                                    L_standard_class,
                                                    L_conv_factor,
                                                    L_item,
                                                    'N') then
               return FALSE;
            end if;

            if NOT UOM_SQL.CONVERT(O_error_message,
                                   L_standard_qty,
                                   L_standard_uom,
                                   rec_ce_charges.manifest_item_qty,
                                   rec_ce_charges.manifest_item_qty_uom,
                                   L_item,
                                   NULL,
                                   NULL) then
               return FALSE;
            end if;

            L_comp_amt := L_standard_qty * rec_ce_charges.comp_value;
         end if;   -- if rec_ce_charges.pack_item IS NOT NULL

         L_total_comp_amt := L_total_comp_amt + L_comp_amt;

      END LOOP;

         insert into invc_non_merch(invc_id,
                                    non_merch_code,
                                    non_merch_amt,
                                    service_perf_ind,
                                    vat_code)
                             values(L_next_invc_id,
                                    rec_non_merch_code.non_merch_code,
                                    L_total_comp_amt,
                                    'N',
                                    L_zero_rate_vat_code);
   END LOOP;

   SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'INVC_XREF',
                       'INVC_ID = ' || L_next_invc_id);
      insert into invc_xref (invc_id,
                             location,
                             loc_type,
                             apply_to_future_ind)
                     values (L_next_invc_id,
                             -999999999,
                             'S',
                             'N');

   return TRUE;

EXCEPTION

   when OTHERS then
      O_error_message := sql_lib.create_msg('PACKAGE_ERROR', SQLERRM,
                                            L_program, to_char(SQLCODE));
      return FALSE;

END CE_INVC_WRITE;

END INVC_RTM_SQL;
/

