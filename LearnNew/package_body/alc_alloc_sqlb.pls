CREATE OR REPLACE PACKAGE BODY ALC_ALLOC_SQL AS
   LP_vdate              DATE := GET_VDATE;
   LP_currency_obl       CURRENCIES.CURRENCY_CODE%TYPE;
   LP_exchange_rate_obl  CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   TYPE po_tbl_type      IS TABLE OF ORDHEAD.ORDER_NO%TYPE INDEX BY BINARY_INTEGER;
   po_tbl                po_tbl_type;
------------------------------------------------------------------------------------
FUNCTION INSERT_ALC_COMP_LOCS(O_error_message     IN OUT VARCHAR2,
                              I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                              I_item              IN     ITEM_MASTER.ITEM%TYPE,
                              I_pack_item         IN     ITEM_MASTER.ITEM%TYPE,
                              I_obligation_key    IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                              I_comp_id           IN     ELC_COMP.COMP_ID%TYPE,
                              I_location          IN     ORDLOC.LOCATION%TYPE,
                              I_loc_type          IN     ORDLOC.LOC_TYPE%TYPE,
                              I_act_value         IN     ALC_COMP_LOC.ACT_VALUE%TYPE,
                              I_qty               IN     ALC_COMP_LOC.QTY%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64) := 'ALC_ALLOC_SQL.INSERT_ALC_COMP_LOCS';

BEGIN
   -- Expense comps will be reallocated at the end of the process
   if ADD_PO_TO_QUEUE(O_error_message,
                      I_order_no) = FALSE then
      return FALSE;
   end if;

   insert into alc_comp_loc(order_no,
                            seq_no,
                            comp_id,
                            location,
                            loc_type,
                            act_value,
                            qty,
                            last_calc_date)
                     select I_order_no,
                            seq_no,
                            I_comp_id,
                            I_location,
                            I_loc_type,
                            I_act_value,
                            I_qty,
                            LP_vdate
                       from alc_head
                      where order_no           = I_order_no
                        and item               = I_item
                        and ((pack_item       is NULL
                              and I_pack_item is NULL)
                          or (pack_item        = I_pack_item
                              and pack_item   is not NULL
                              and I_pack_item is not NULL))
                        and obligation_key     = I_obligation_key
                        and vessel_id         is NULL;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_ALC_COMP_LOCS;
------------------------------------------------------------------------------------
--- This function inserts all expense comps for the order/item/location
--- that have not yet been logged on an obligation
------------------------------------------------------------------------------------
FUNCTION INSERT_EXPENSE_COMPS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                              I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                              I_item            IN       ITEM_MASTER.ITEM%TYPE,
                              I_pack_item       IN       ITEM_MASTER.ITEM%TYPE,
                              I_location        IN       ORDLOC.LOCATION%TYPE,
                              I_loc_type        IN       ORDLOC.LOC_TYPE%TYPE,
                              I_loc_qty         IN       ALC_COMP_LOC.QTY%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64)                := 'ALC_ALLOC_SQL.INSERT_EXPENSE_COMPS';
   L_act_value       ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_comp_id         ELC_COMP.COMP_ID%TYPE;
   L_est_exp_value   ORDLOC_EXP.EST_EXP_VALUE%TYPE;
   L_comp_currency   ELC_COMP.COMP_CURRENCY%TYPE;

   cursor C_GET_EXP_COMPS is
      select e.comp_id,
             e.est_exp_value,
             e.comp_currency,
             e.exchange_rate,
             e.nom_flag_5
        from ordloc_exp e
       where e.order_no    = I_order_no
         and e.item        = I_item
         and (e.pack_item  = I_pack_item
              or (e.pack_item is NULL and I_pack_item is NULL))
         and e.nom_flag_4 != 'N'
         and e.location    = I_location
         and e.loc_type    = I_loc_type
         and e.comp_id NOT in (select o.comp_id
                                 from obligation_comp o,
                                      alc_comp_loc l,
                                      alc_head a
                                where l.order_no       = I_order_no
                                  and a.item           = I_item
                                  and (a.pack_item = I_pack_item
                                       or (a.pack_item is NULL and I_pack_item is NULL))
                                  and l.order_no       = a.order_no
                                  and l.seq_no         = a.seq_no
                                  and l.location       = I_location
                                  and o.comp_id        = l.comp_id
                                  and o.obligation_key = a.obligation_key);

BEGIN
   FOR L_rec in C_GET_EXP_COMPS LOOP
      L_est_exp_value := L_rec.est_exp_value;
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_est_exp_value,
                              L_rec.comp_currency,
                              NULL,  -- primary currency
                              L_est_exp_value,
                              'N',
                              NULL,
                              NULL,
                              L_rec.exchange_rate,
                              NULL) = FALSE then
         return FALSE;
      end if;
      ---
      -- The statment below is written to handle the following scenarios.
      -- When inserting components from ordloc_exp, if the 'In ALC' flag (nom_flag_5) is
      -- set to '+' then the act_value should be the same as the est_exp_value.
      -- If the 'In ALC' flag is set to '-' then the act_value should
      -- be the same as the est_exp_value, only negative.
      -- (to make the value negative, subtract it from zero)
      -- If the 'In ALC' flag is set to 'N/A' then the act_value should be zero.
      ---
      if L_rec.nom_flag_5 = '+' then
         L_act_value := L_est_exp_value;
      elsif L_rec.nom_flag_5 = '-' then
         L_act_value := (0 - L_est_exp_value);
      else
         L_act_value := 0;
      end if;
      ---
      -- Insert expense components into ALC_COMP_LOC
      ---
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ALC_COMP_LOC',
                       'ITEM: '||I_item||', ORDER_NO: '||I_order_no);
      insert into alc_comp_loc (order_no,
                                seq_no,
                                comp_id,
                                location,
                                loc_type,
                                act_value,
                                qty,
                                last_calc_date)
                         select I_order_no,
                                seq_no,
                                L_rec.comp_id,
                                I_location,
                                I_loc_type,
                                L_act_value,
                                I_loc_qty,
                                LP_vdate
                           from alc_head
                          where order_no       = I_order_no
                            and item           = I_item
                            and (pack_item     = I_pack_item
                                 or (pack_item is NULL
                                     and I_pack_item is NULL))
                            and obligation_key is NULL
                            and ce_id          is NULL;
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
END INSERT_EXPENSE_COMPS;
------------------------------------------------------------------------------------
--- This function inserts all assessment comps for the order/item/location
--- that have not yet been logged on a customs entry
------------------------------------------------------------------------------------
FUNCTION INSERT_ASSESS_COMPS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                             I_order_no        IN       ORDHEAD.ORDER_NO%TYPE,
                             I_item            IN       ITEM_MASTER.ITEM%TYPE,
                             I_pack_item       IN       ITEM_MASTER.ITEM%TYPE,
                             I_location        IN       ORDLOC.LOCATION%TYPE,
                             I_loc_type        IN       ORDLOC.LOC_TYPE%TYPE,
                             I_loc_qty         IN       ALC_COMP_LOC.QTY%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64)                := 'ALC_ALLOC_SQL.INSERT_ASSESS_COMPS';
   L_act_value       ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_comp_id         ELC_COMP.COMP_ID%TYPE;
   L_assess_value    ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE;
   L_comp_currency   ELC_COMP.COMP_CURRENCY%TYPE;

   cursor C_GET_ASSESS_COMPS is
      select distinct a.comp_id,
             e.comp_currency,
             a.nom_flag_5
        from ordsku_hts o,
             ordsku_hts_assess a,
             elc_comp e
       where o.order_no    = I_order_no
         and o.order_no    = a.order_no
         and o.item        = I_item
         and (o.pack_item  = I_pack_item
              or (o.pack_item is NULL and I_pack_item is NULL))
         and o.seq_no      = a.seq_no
         and a.comp_id     = e.comp_id
         and a.nom_flag_2 != 'N'
         and e.comp_id not in (select ce.comp_id
                                 from ce_charges ce,
                                      alc_head h,
                                      alc_comp_loc l
                                where h.order_no         = I_order_no
                                  and h.item             = I_item
                                  and (h.pack_item = I_pack_item
                                       or (h.pack_item is NULL and I_pack_item is NULL))
                                  and h.order_no         = l.order_no
                                  and h.seq_no           = l.seq_no
                                  and l.location         = I_location
                                  and ce.ce_id           = h.ce_id
                                  and ce.order_no        = h.order_no
                                  and h.vessel_id             = ce.vessel_id
                                  and h.voyage_flt_id         = ce.voyage_flt_id
                                  and h.estimated_depart_date = ce.estimated_depart_date
                                  and l.comp_id          = ce.comp_id
                                  and ce.item            = I_item
                                  and (ce.pack_item = I_pack_item
                                       or (ce.pack_item is NULL and I_pack_item is NULL)));

   cursor C_GET_ASSESS_VAL is
      select SUM(a.est_assess_value)
        from ordsku_hts o,
             ordsku_hts_assess a
       where o.order_no    = I_order_no
         and o.order_no    = a.order_no
         and o.item        = I_item
         and ((o.pack_item     is NULL
               and I_pack_item is NULL)
           or (o.pack_item      = I_pack_item
               and o.pack_item is NOT NULL
               and I_pack_item is NOT NULL))
         and o.seq_no      = a.seq_no
         and a.comp_id     = L_comp_id;

BEGIN

   FOR L_rec in C_GET_ASSESS_COMPS LOOP
      L_comp_id       := L_rec.comp_id;
      L_comp_currency := L_rec.comp_currency;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ASSESS_VAL',
                       'ORDSKU_HTS,ORDSKU_HTS_ASSESS',
                       NULL);
      open C_GET_ASSESS_VAL;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ASSESS_VAL',
                       'ORDSKU_HTS,ORDSKU_HTS_ASSESS',
                       NULL);
      fetch C_GET_ASSESS_VAL into L_assess_value;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ASSESS_VAL',
                       'ORDSKU_HTS,ORDSKU_HTS_ASSESS',
                       NULL);
      close C_GET_ASSESS_VAL;
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_assess_value,
                              L_comp_currency,
                              NULL,  -- primary currency
                              L_assess_value,
                              'N',
                              NULL,
                              NULL,
                              NULL,
                              NULL) = FALSE then
         return FALSE;
      end if;
      ---
      if L_rec.nom_flag_5 = '+' then
         L_act_value := L_assess_value;
      elsif L_rec.nom_flag_5 = '-' then
         L_act_value := (0 - L_assess_value);
      else
         L_act_value := 0;
      end if;
      ---
      -- Insert assessment components into ALC_COMP_LOC
      ---
      SQL_LIB.SET_MARK('INSERT',
                       NULL,
                       'ALC_COMP_LOC',
                       'ITEM: '||I_item||', ORDER_NO: '||I_order_no);
      insert into alc_comp_loc (order_no,
                                seq_no,
                                comp_id,
                                location,
                                loc_type,
                                act_value,
                                qty,
                                last_calc_date)
                         select I_order_no,
                                seq_no,
                                L_comp_id,
                                I_location,
                                I_loc_type,
                                L_act_value,
                                I_loc_qty,
                                LP_vdate
                           from alc_head
                          where order_no              = I_order_no
                            and item                  = I_item
                            and (pack_item            = I_pack_item
                                 or (pack_item       is NULL
                                     and I_pack_item is NULL))
                            and obligation_key       is NULL
                            and ce_id                is NULL;
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
END INSERT_ASSESS_COMPS;
------------------------------------------------------------------------------------
FUNCTION INSERT_ALC_HEAD(O_error_message     IN OUT VARCHAR2,
                         I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                         I_item              IN     ITEM_MASTER.ITEM%TYPE,
                         I_pack_item         IN     ITEM_MASTER.ITEM%TYPE,
                         I_obligation_key    IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                         I_vessel_id         IN     TRANSPORTATION.VESSEL_ID%TYPE,
                         I_voyage_flt_id     IN     TRANSPORTATION.VOYAGE_FLT_ID%TYPE,
                         I_etd               IN     TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE,
                         I_item_qty          IN     ORDLOC.QTY_RECEIVED%TYPE,
                         I_error_ind         IN     ALC_HEAD.ERROR_IND%TYPE)
   RETURN BOOLEAN IS

   L_program         VARCHAR2(64)             := 'ALC_ALLOC_SQL.INSERT_ALC_HEAD';
   L_seq_no          ALC_HEAD.SEQ_NO%TYPE;
   L_status          ALC_HEAD.STATUS%TYPE;

   cursor C_GET_MAX_SEQ is
      select NVL(MAX(seq_no), 0) + 1
        from alc_head
       where order_no = I_order_no;

BEGIN
   -- Get the maximum sequence number plus one.
   SQL_LIB.SET_MARK('OPEN','C_GET_MAX_SEQ','ALC_HEAD',NULL);
   open  C_GET_MAX_SEQ;
   SQL_LIB.SET_MARK('FETCH','C_GET_MAX_SEQ','ALC_HEAD',NULL);
   fetch C_GET_MAX_SEQ into L_seq_no;
   SQL_LIB.SET_MARK('CLOSE','C_GET_MAX_SEQ','ALC_HEAD',NULL);
   close C_GET_MAX_SEQ;
   ---
   if I_obligation_key is null then
      L_status := 'E';  -- estimated expenses
   else
      L_status := 'P';  -- pending obligation
   end if;
   -- insert into ALC_HEAD
   insert into alc_head (order_no,
                         item,
                         pack_item,
                         seq_no,
                         obligation_key,
                         vessel_id,
                         voyage_flt_id,
                         estimated_depart_date,
                         alc_qty,
                         status,
                         error_ind)
                 values (I_order_no,
                         I_item,
                         I_pack_item,
                         L_seq_no,
                         I_obligation_key,
                         I_vessel_id,
                         I_voyage_flt_id,
                         I_etd,
                         I_item_qty,
                         L_status,            -- status = 'Pending'
                         I_error_ind);   -- error flag

   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_ALC_HEAD;
-------------------------------------------------------------------------------
FUNCTION INSERT_ELC_COMPS(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                          I_order_no        IN       ORDHEAD.ORDER_NO%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(64)                := 'ALC_ALLOC_SQL.INSERT_ELC_COMPS';
   L_found                BOOLEAN;
   L_alc_head_exists      VARCHAR2(1)                 := NULL;
   L_pack_ind             ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind         ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind        ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type            ITEM_MASTER.PACK_TYPE%TYPE;
   L_comp_items           packitem_attrib_sql.comp_item_tbl;
   L_comp_qtys            packitem_attrib_sql.comp_qty_tbl;
   L_pack_no              ITEM_MASTER.ITEM%TYPE;
   L_comp_item            ITEM_MASTER.ITEM%TYPE;
   L_item                 ITEM_MASTER.ITEM%TYPE;
   L_option_ind           SYSTEM_OPTIONS.IMPORT_IND%TYPE;
   ---
   L_qty_rec              ORDLOC.QTY_RECEIVED%TYPE    := 0;
   L_qty_shp              SHIPSKU.QTY_EXPECTED%TYPE   := 0;
   L_qty_shp_loc          SHIPSKU.QTY_EXPECTED%TYPE   := 0;
   L_qty_ord              ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_loc_qty              ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_item_qty             ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_location             ORDLOC.LOCATION%TYPE;

   cursor C_GET_ITEM_QTY is
      select NVL(SUM(qty_received), 0) qty_received,
             NVL(SUM(qty_ordered), 0) qty_ordered
        from ordloc
       where order_no = I_order_no
         and item     = L_item;

   cursor C_GET_ITEM_SHP_QTY is
      select NVL(SUM(k.qty_expected), 0) qty_expected
        from shipment s,
             shipsku k
       where s.order_no = I_order_no
         and k.item     = L_item
         and s.shipment = k.shipment;

   cursor C_GET_ORD_LOCS is
      select location,
             loc_type,
             NVL(qty_received, 0) qty_received,
             NVL(qty_ordered, 0) qty_ordered
        from ordloc
       where order_no = I_order_no
         and item     = L_item;

   cursor C_GET_QTY_SHIPPED is
      select NVL(SUM(k.qty_expected), 0) qty_expected
        from shipment s,
             shipsku k
       where s.order_no = I_order_no
         and k.item     = L_item
         and s.to_loc   = L_location
         and s.shipment = k.shipment;

   cursor C_ALC_HEAD_EXISTS is
      select 'Y'
        from alc_head
       where order_no       = I_order_no
         and item           = L_item
         and pack_item      is NULL
         and obligation_key is NULL
         and ce_id          is NULL
         and rownum         = 1;

   cursor C_ALC_HEAD_EXISTS_PACK is
      select 'Y'
        from alc_head
       where order_no       = I_order_no
         and item           = L_comp_item
         and pack_item      = L_pack_no
         and obligation_key is NULL
         and ce_id          is NULL
         and rownum         = 1;

   cursor C_GET_ORD_SKUS is
      select item
        from ordsku
       where order_no = I_order_no;

   cursor C_LOCK_ALC_COMP_LOC1 is
      select 'X'
        from alc_comp_loc
       where order_no = I_order_no
         and seq_no in (select h.seq_no
                          from alc_head h
                         where h.order_no     = I_order_no
                           and obligation_key is NULL
                           and ce_id          is NULL)
         for update nowait;

   cursor C_LOCK_ALC_COMP_LOC2 is
      select 'X'
        from alc_comp_loc l
       where l.order_no = I_order_no
         and seq_no in (select h.seq_no
                          from alc_head h
                         where h.order_no       = I_order_no
                           and h.obligation_key is NOT NULL
                           and NOT exists (select 'x'
                                             from obligation_comp
                                            where obligation_key = h.obligation_key
                                              and comp_id        = l.comp_id
                                   and rownum         = 1))
         for update nowait;
   ---
   cursor C_LOCK_ALC_COMP_LOC3 is
      select 'X'
        from alc_comp_loc l
       where l.order_no = I_order_no
         and seq_no in (select h.seq_no
                          from alc_head h
                         where h.order_no = I_order_no
                           and h.ce_id    is NOT NULL
                           and NOT exists (select 'x'
                                             from ce_charges ce
                                            where ce.ce_id                = h.ce_id
                                              and ce.order_no             = h.order_no
                                              and h.vessel_id             = ce.vessel_id
                                              and h.voyage_flt_id         = ce.voyage_flt_id
                                              and h.estimated_depart_date = ce.estimated_depart_date
                                              and ce.comp_id              = l.comp_id
                                              and ce.item                 = h.item
                                              and (ce.pack_item           = h.pack_item
                                                   or (ce.pack_item      is NULL
                                                       and h.pack_item   is NULL))
                                              and rownum                  = 1))
         for update nowait;


BEGIN

   if NOT SYSTEM_OPTIONS_SQL.GET_ELC_IND(O_error_message,
                                         L_option_ind) then
      return FALSE;
   end if;
   if nvl(L_option_ind, 'N') != 'Y' then
      return TRUE;
   end if;
   if NOT SYSTEM_OPTIONS_SQL.GET_IMPORT_IND(O_error_message,
                                            L_option_ind) then
      return FALSE;
   end if;
   if nvl(L_option_ind, 'N') != 'Y' then
      return TRUE;
   end if;

   -- Delete all ELC comps for the order
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ALC_COMP_LOC1',
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   open C_LOCK_ALC_COMP_LOC1;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ALC_COMP_LOC1',
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   close C_LOCK_ALC_COMP_LOC1;
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   delete alc_comp_loc
    where order_no = I_order_no
      and seq_no in (select h.seq_no
                       from alc_head h
                      where h.order_no     = I_order_no
                        and obligation_key is NULL
                        and ce_id          is NULL);
   ---
   -- These two statements were added to deal with expenses and assessments
   -- that were logged prior to this fix.  Previously, expenses were logged
   -- under an obligation and assessements were logged under a customs entry.
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ALC_COMP_LOC2',
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   open C_LOCK_ALC_COMP_LOC2;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ALC_COMP_LOC2',
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   close C_LOCK_ALC_COMP_LOC2;
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   delete alc_comp_loc l
    where l.order_no = I_order_no
      and seq_no in (select h.seq_no
                       from alc_head h
                      where h.order_no       = I_order_no
                        and h.obligation_key is NOT NULL
                        and NOT exists (select 'x'
                                          from obligation_comp
                                         where obligation_key = h.obligation_key
                                           and comp_id        = l.comp_id
                                           and rownum         = 1));
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_LOCK_ALC_COMP_LOC3',
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   open C_LOCK_ALC_COMP_LOC3;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_LOCK_ALC_COMP_LOC3',
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   close C_LOCK_ALC_COMP_LOC3;
   SQL_LIB.SET_MARK('DELETE',
                    NULL,
                    'ALC_COMP_LOC',
                    'order no: '||to_char(I_order_no));
   delete alc_comp_loc l
    where l.order_no = I_order_no
      and seq_no in (select h.seq_no
                       from alc_head h
                      where h.order_no = I_order_no
                        and h.ce_id    is NOT NULL
                        and NOT exists (select 'x'
                                          from ce_charges ce
                                         where ce.ce_id                = h.ce_id
                                           and ce.order_no             = h.order_no
                                           and h.vessel_id             = ce.vessel_id
                                           and h.voyage_flt_id         = ce.voyage_flt_id
                                           and h.estimated_depart_date = ce.estimated_depart_date
                                           and ce.comp_id              = l.comp_id
                                           and ce.item                 = h.item
                                           and (ce.pack_item           = h.pack_item
                                                or (ce.pack_item      is NULL
                                                    and h.pack_item   is NULL))
                                           and rownum                  = 1));
   ---
   FOR rec in C_GET_ORD_SKUS LOOP
      L_item := rec.item;
      ---
      if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                       L_pack_ind,
                                       L_sellable_ind,
                                       L_orderable_ind,
                                       L_pack_type,
                                       L_item) = FALSE then
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_GET_ITEM_QTY',
                       'ORDLOC',
                       'order no: '||to_char(I_order_no)||' item: '||L_item);
      open C_GET_ITEM_QTY;
      SQL_LIB.SET_MARK('FETCH',
                       'C_GET_ITEM_QTY',
                       'ORDLOC',
                       'order no: '||to_char(I_order_no)||' item: '||L_item);
      fetch C_GET_ITEM_QTY into L_qty_rec,
                                L_qty_ord;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_GET_ITEM_QTY',
                       'ORDLOC',
                       'order no: '||to_char(I_order_no)||' item: '||L_item);
      close C_GET_ITEM_QTY;
      ---
      -- If the item is fully received, use the received quantity
      -- If the item is fully shipped, use the shipped quantity
      -- Otherwise use the order quantity
      ---
      if L_qty_rec >= L_qty_ord then
         L_item_qty := L_qty_rec;
      else
         SQL_LIB.SET_MARK('OPEN',
                          'C_GET_ITEM_SHP_QTY',
                          'SHIPMENT,SHIPSKU',
                          'order no: '||to_char(I_order_no)||' item: '||L_item);
         open C_GET_ITEM_SHP_QTY;
         SQL_LIB.SET_MARK('FETCH',
                          'C_GET_ITEM_SHP_QTY',
                          'SHIPMENT,SHIPSKU',
                          'order no: '||to_char(I_order_no)||' item: '||L_item);
         fetch C_GET_ITEM_SHP_QTY into L_qty_shp;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_GET_ITEM_SHP_QTY',
                          'SHIPMENT,SHIPSKU',
                          'order no: '||to_char(I_order_no)||' item: '||L_item);
         close C_GET_ITEM_SHP_QTY;
         if L_qty_shp >= L_qty_ord then
            L_item_qty := L_qty_shp;
         else
            L_item_qty := L_qty_ord;
         end if;
      end if;
      ---
      -- Insert alc_head record(s) if necessary
      -- If the item is a buyer pack, ALC records will be at the pack comp level
      ---
      if nvl(L_pack_type,'N') = 'B' then
         L_pack_no := L_item;
         if PACKITEM_ATTRIB_SQL.GET_COMP_QTYS(O_error_message,
                                              L_comp_items,
                                              L_comp_qtys,
                                              L_pack_no) = FALSE then
            return FALSE;
         end if;
         FOR i in L_comp_items.first..L_comp_items.last LOOP
            L_comp_item := L_comp_items(i);
            ---
            SQL_LIB.SET_MARK('OPEN',
                             'C_ALC_HEAD_EXISTS_PACK',
                             'ALC_HEAD',
                             NULL);
            open C_ALC_HEAD_EXISTS_PACK;
            SQL_LIB.SET_MARK('FETCH',
                             'C_ALC_HEAD_EXISTS_PACK',
                             'ALC_HEAD',
                             NULL);
            fetch C_ALC_HEAD_EXISTS_PACK into L_alc_head_exists;
            if L_alc_head_exists is NULL then
               L_found := FALSE;
            else
               L_found := TRUE;
            end if;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_ALC_HEAD_EXISTS_PACK',
                             'ALC_HEAD',
                             NULL);
            close C_ALC_HEAD_EXISTS_PACK;
            ---
            if NOT L_found then
               if INSERT_ALC_HEAD(O_error_message,
                                  I_order_no,
                                  L_comp_item,
                                  L_pack_no,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  L_item_qty * L_comp_qtys(i),
                                  'N') = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
         end loop;
      else
         SQL_LIB.SET_MARK('OPEN',
                          'C_ALC_HEAD_EXISTS',
                          'ALC_HEAD',
                          NULL);
         open C_ALC_HEAD_EXISTS;
         SQL_LIB.SET_MARK('FETCH',
                          'C_ALC_HEAD_EXISTS',
                          'ALC_HEAD',
                          NULL);
         fetch C_ALC_HEAD_EXISTS into L_alc_head_exists;
         if L_alc_head_exists is NULL then
            L_found := FALSE;
         else
            L_found := TRUE;
         end if;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ALC_HEAD_EXISTS',
                          'ALC_HEAD',
                          NULL);
         close C_ALC_HEAD_EXISTS;
         ---
         if NOT L_found then
            if INSERT_ALC_HEAD(O_error_message,
                               I_order_no,
                               L_item,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               L_item_qty,
                               'N') = FALSE then
               return FALSE;
            end if;
         end if;
      end if;
      ---
      FOR loc_rec in C_GET_ORD_LOCS LOOP
         L_location := loc_rec.location;
         ---
         -- If the item is fully received, use the received quantity
         -- If the item is fully shipped, use the shipped quantity
         -- Otherwise use the order quantity
         ---
         if L_qty_rec >= L_qty_ord then
            L_loc_qty := NVL(loc_rec.qty_received, 0);
         elsif L_qty_shp >= L_qty_ord then
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_QTY_SHIPPED',
                             'SHIPMENT,SHIPSKU',
                             NULL);
            open C_GET_QTY_SHIPPED;
            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_QTY_SHIPPED',
                             'SHIPMENT,SHIPSKU',
                             NULL);
            fetch C_GET_QTY_SHIPPED into L_qty_shp_loc;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_QTY_SHIPPED',
                             'SHIPMENT,SHIPSKU',
                             NULL);
            close C_GET_QTY_SHIPPED;
            ---
            L_loc_qty := NVL(L_qty_shp_loc, 0);
         else
            L_loc_qty := NVL(loc_rec.qty_ordered, 0);
         end if;
         if nvl(L_pack_type,'N') = 'B' then
            L_pack_no := L_item;
            FOR i in L_comp_items.first..L_comp_items.last LOOP
               L_comp_item := L_comp_items(i);
               ---
               if INSERT_EXPENSE_COMPS(O_error_message,
                                       I_order_no,
                                       L_comp_item,
                                       L_pack_no,
                                       L_location,
                                       loc_rec.loc_type,
                                       L_loc_qty * L_comp_qtys(i)) = FALSE then
                  return FALSE;
               end if;
               ---
               if INSERT_ASSESS_COMPS(O_error_message,
                                      I_order_no,
                                      L_comp_item,
                                      L_pack_no,
                                      L_location,
                                      loc_rec.loc_type,
                                      L_loc_qty * L_comp_qtys(i)) = FALSE then
                  return FALSE;
               end if;
            END LOOP;
         else
            if INSERT_EXPENSE_COMPS(O_error_message,
                                    I_order_no,
                                    L_item,
                                    NULL,
                                    L_location,
                                    loc_rec.loc_type,
                                    L_loc_qty) = FALSE then
               return FALSE;
            end if;
            ---
            if INSERT_ASSESS_COMPS(O_error_message,
                                   I_order_no,
                                   L_item,
                                   NULL,
                                   L_location,
                                   loc_rec.loc_type,
                                   L_loc_qty) = FALSE then
               return FALSE;
            end if;
         end if;
      END LOOP;
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
END INSERT_ELC_COMPS;
------------------------------------------------------------------------------------
FUNCTION ADD_PO_TO_QUEUE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE,
                         I_order_no        IN       ORDHEAD.ORDER_NO%TYPE)
   RETURN BOOLEAN IS
   L_program   VARCHAR2(64) := 'ALC_ALLOC_SQL.ADD_PO_TO_QUEUE';
BEGIN

   for i in 1..po_tbl.count LOOP
      if po_tbl(i) = I_order_no then
         return TRUE;
      end if;
   end LOOP;
   po_tbl(po_tbl.count+1) := I_order_no;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ADD_PO_TO_QUEUE;
------------------------------------------------------------------------------------
FUNCTION INSERT_ELC_COMPS_FOR_QUEUE(O_error_message   IN OUT   RTK_ERRORS.RTK_TEXT%TYPE)
   RETURN BOOLEAN IS
   L_program   VARCHAR2(64) := 'ALC_ALLOC_SQL.INSERT_ELC_COMPS_FOR_QUEUE';
BEGIN


   for i in 1..po_tbl.count LOOP
      if INSERT_ELC_COMPS(O_error_message,
                          po_tbl(i)) = FALSE then
         return FALSE;
      end if;
   end LOOP;
   po_tbl.delete;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_ELC_COMPS_FOR_QUEUE;
------------------------------------------------------------------------------------
FUNCTION ALLOC_PO_ITEM(O_error_message       IN OUT   VARCHAR2,
                       I_obligation_key      IN       OBLIGATION.OBLIGATION_KEY%TYPE,
                       I_obligation_level    IN       OBLIGATION.OBLIGATION_LEVEL%TYPE,
                       I_key_value_1         IN       OBLIGATION.KEY_VALUE_1%TYPE,
                       I_key_value_2         IN       OBLIGATION.KEY_VALUE_2%TYPE,
                       I_comp_id             IN       ELC_COMP.COMP_ID%TYPE,
                       I_alloc_basis_uom     IN       UOM_CLASS.UOM%TYPE,
                       I_qty                 IN       OBLIGATION_COMP.QTY%TYPE,
                       I_amt_prim            IN       OBLIGATION_COMP.AMT%TYPE,
                       I_location            IN       ORDLOC.LOCATION%TYPE,
                       I_loc_type            IN       ORDLOC.LOC_TYPE%TYPE,
                       I_loc_qty             IN       ALC_COMP_LOC.QTY%TYPE,
                       I_loc_amt             IN       ALC_COMP_LOC.ACT_VALUE%TYPE)
   RETURN BOOLEAN IS

   L_program             VARCHAR2(64)                  := 'ALC_ALLOC_SQL.ALLOC_PO_ITEM';
   L_obl_locs_exist      VARCHAR2(1)                   := 'N';
   L_alc_head_exists     VARCHAR2(1)                   := 'N';
   L_error_ind           ALC_HEAD.ERROR_IND%TYPE       := 'N';
   L_item_rec_qty        ORDLOC.QTY_ORDERED%TYPE       := 0;
   L_item_ord_qty        ORDLOC.QTY_ORDERED%TYPE       := 0;
   L_comp_rec_qty        ORDLOC.QTY_ORDERED%TYPE       := 0;
   L_comp_qty            ORDLOC.QTY_ORDERED%TYPE       := 0;
   L_total_comp_qty      ORDLOC.QTY_ORDERED%TYPE       := 0;
   L_temp_qty            ORDLOC.QTY_ORDERED%TYPE       := 0;
   L_act_value           ALC_COMP_LOC.ACT_VALUE%TYPE   := 0;
   L_amt_prim            ALC_COMP_LOC.ACT_VALUE%TYPE   := 0;
   L_loc_amt             ALC_COMP_LOC.ACT_VALUE%TYPE   := 0;
   L_unit_cost           ORDLOC.UNIT_COST%TYPE         := 0;
   L_total_pack_cost     ORDLOC.UNIT_COST%TYPE         := 0;
   L_packitem_cost       ORDLOC.UNIT_COST%TYPE         := 0;
   L_qty                 ALC_COMP_LOC.QTY%TYPE         := 0;
   L_qty_rec             ORDLOC.QTY_RECEIVED%TYPE      := 0;
   L_qty_shp             ORDLOC.QTY_RECEIVED%TYPE      := 0;
   L_qty_ord             ORDLOC.QTY_ORDERED%TYPE       := 0;
   L_loc_qty             ORDLOC.QTY_ORDERED%TYPE       := 0;
   L_qty_shipped         SHIPSKU.QTY_EXPECTED%TYPE     := 0;
   L_order_no            ORDHEAD.ORDER_NO%TYPE;
   L_item                ITEM_MASTER.ITEM%TYPE;
   L_pack_no             ITEM_MASTER.ITEM%TYPE;
   L_comp_item           ITEM_MASTER.ITEM%TYPE;
   L_temp_comp_item      ITEM_MASTER.ITEM%TYPE;
   L_seq_no              ORDLOC_EXP.SEQ_NO%TYPE;
   L_supplier            SUPS.SUPPLIER%TYPE;
   L_origin_country_id   COUNTRY.COUNTRY_ID%TYPE;
   L_location            ORDLOC.LOCATION%TYPE;
   L_loc_type            ORDLOC.LOC_TYPE%TYPE;
   L_unit_of_work        IF_ERRORS.UNIT_OF_WORK%TYPE;
   L_uom                 UOM_CLASS.UOM%TYPE;
   L_standard_uom        UOM_CLASS.UOM%TYPE;
   L_temp_standard_uom   UOM_CLASS.UOM%TYPE;
   L_standard_class      UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor         UOM_CONVERSION.FACTOR%TYPE;
   ---
   L_pack_ind            ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind        ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind       ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type           ITEM_MASTER.PACK_TYPE%TYPE;
   ---
   L_table               VARCHAR2(30);
   RECORD_LOCKED         EXCEPTION;
   PRAGMA                EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_GET_ITEMS is
      select s.item,
             s.origin_country_id,
             o.supplier
        from ordsku s,
             ordhead o
       where o.order_no = L_order_no
         and o.order_no = s.order_no;

   cursor C_GET_ITEM_QTY is
      select NVL(SUM(qty_received), 0) qty_received,
             NVL(SUM(qty_ordered), 0) qty_ordered
        from ordloc
       where order_no = L_order_no
         and item     = L_item;

   cursor C_GET_ITEM_SHP_QTY is
      select NVL(SUM(k.qty_expected), 0) qty_expected
        from shipment s,
             shipsku k
       where s.order_no = L_order_no
         and k.item     = L_item
         and s.shipment = k.shipment;

   cursor C_ALC_HEAD_EXISTS is
      select 'Y'
        from alc_head
       where order_no = L_order_no
         and ((item             = L_item
               and pack_item   is NULL
               and nvl(L_pack_type,'N') != 'B')
           or (item             = L_comp_item
               and pack_item    = L_pack_no
               and nvl(L_pack_type,'N') = 'B'))
         and obligation_key = I_obligation_key
         and vessel_id     is NULL;

   cursor C_OBL_LOCS_EXIST is
      select 'Y'
        from obligation_comp_loc
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_GET_ORD_SUP_CTRY is
      select o.supplier,
             s.origin_country_id
        from ordhead o,
             ordsku s
       where o.order_no = L_order_no
         and o.order_no = s.order_no
         and s.item     = L_item;

   cursor C_GET_PACKITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

   cursor C_GET_PACKITEMS_QTY is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

   cursor C_GET_PACKITEM_COST is
      select (i.unit_cost * v.qty)
        from v_packsku_qty v,
             item_supp_country i
       where v.pack_no           = L_pack_no
         and v.item              = L_comp_item
         and v.item              = i.item
         and i.supplier          = L_supplier
         and i.origin_country_id = L_origin_country_id;

   cursor C_SUM_PACKITEM_COST is
      select SUM(i.unit_cost * v.qty)
        from v_packsku_qty v,
             item_supp_country i
       where v.pack_no           = L_pack_no
         and v.item              = i.item
         and i.supplier          = L_supplier
         and i.origin_country_id = L_origin_country_id;

   cursor C_GET_ORD_LOCS is
      select location,
             loc_type,
             NVL(qty_received, 0) qty_received,
             NVL(qty_ordered, 0) qty_ordered
        from ordloc
       where order_no = L_order_no
         and item     = L_item;

   cursor C_GET_QTY_SHIPPED is
      select NVL(SUM(k.qty_expected), 0) qty_expected
        from shipment s,
             shipsku k
       where s.order_no = L_order_no
         and k.item     = L_item
         and s.to_loc   = L_location
         and s.shipment = k.shipment;

   cursor C_GET_OBL_LOCS is
      select location,
             loc_type,
             amt,
             qty
        from obligation_comp_loc
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_GET_QTY_UOM is
      select per_count_uom
        from obligation_comp
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from alc_head
       where order_no         = L_order_no
         and ((item           = L_item
               and pack_item is NULL)
           or (item           = L_comp_item
               and pack_item  = L_item))
         and obligation_key   = I_obligation_key
         and vessel_id       is NULL
         for update nowait;

BEGIN
   L_order_no := TO_NUMBER(I_key_value_1);
   L_item     := I_key_value_2;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ORD_SUP_CTRY',
                    'ORDHEAD,ORDSKU',
                    'Order: '||to_char(L_order_no));
   open C_GET_ORD_SUP_CTRY;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ORD_SUP_CTRY',
                    'ORDHEAD,ORDSKU',
                    'Order: '||to_char(L_order_no));
   fetch C_GET_ORD_SUP_CTRY into L_supplier,
                                 L_origin_country_id;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ORD_SUP_CTRY',
                    'ORDHEAD,ORDSKU',
                    'Order: '||to_char(L_order_no));
   close C_GET_ORD_SUP_CTRY;
   ---
   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    L_item) = FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_QTY_UOM',
                    'OBLIGATION_COMP',
                    'Obligation: '||to_char(I_obligation_key)||
                    ' Component: '||I_comp_id);
   open C_GET_QTY_UOM;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_QTY_UOM',
                    'OBLIGATION_COMP',
                    'Obligation: '||to_char(I_obligation_key)||
                    ' Component: '||I_comp_id);
   fetch C_GET_QTY_UOM into L_uom;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_QTY_UOM',
                    'OBLIGATION_COMP',
                    'Obligation: '||to_char(I_obligation_key)||
                    ' Component: '||I_comp_id);
   close C_GET_QTY_UOM;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_OBL_LOCS_EXIST',
                    'OBLIGATION_COMP_LOC',
                    NULL);
   open C_OBL_LOCS_EXIST;
   SQL_LIB.SET_MARK('FETCH',
                    'C_OBL_LOCS_EXIST',
                    'OBLIGATION_COMP_LOC',
                    NULL);
   fetch C_OBL_LOCS_EXIST into L_obl_locs_exist;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_OBL_LOCS_EXIST',
                    'OBLIGATION_COMP_LOC',
                    NULL);
   close C_OBL_LOCS_EXIST;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ITEM_QTY',
                    'ORDLOC',
                    'order no: '||to_char(L_order_no)||
                    ' item: '||L_item);
   open C_GET_ITEM_QTY;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ITEM_QTY',
                    'ORDLOC',
                    'order no: '||to_char(L_order_no)||
                    ' item: '||L_item);
   fetch C_GET_ITEM_QTY into L_qty_rec,
                             L_qty_ord;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ITEM_QTY',
                    'ORDLOC',
                    'order no: '||to_char(L_order_no)||
                    ' item: '||L_item);
   close C_GET_ITEM_QTY;
   ---
   SQL_LIB.SET_MARK('OPEN',
                    'C_GET_ITEM_SHP_QTY',
                    'SHIPMENT,SHIPSKU',
                    'order no: '||
                    to_char(L_order_no)||
                    ' item: '||L_item);
   open C_GET_ITEM_SHP_QTY;
   SQL_LIB.SET_MARK('FETCH',
                    'C_GET_ITEM_SHP_QTY',
                    'SHIPMENT,SHIPSKU',
                    'order no: '||to_char(L_order_no)||
                    ' item: '||L_item);
   fetch C_GET_ITEM_SHP_QTY into L_qty_shp;
   SQL_LIB.SET_MARK('CLOSE',
                    'C_GET_ITEM_SHP_QTY',
                    'SHIPMENT,SHIPSKU',
                    'order no: '||to_char(L_order_no)||
                    ' item: '||L_item);
   close C_GET_ITEM_SHP_QTY;
   ---
   if nvl(L_pack_type,'N') = 'B' then
      L_pack_no := L_item;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_SUM_PACKITEM_COST',
                       'V_PACKSKU_QTY,ITEM_SUPP_COUNTRY_LOC',
                       NULL);
      open C_SUM_PACKITEM_COST;
      SQL_LIB.SET_MARK('FETCH',
                       'C_SUM_PACKITEM_COST',
                       'V_PACKSKU_QTY,ITEM_SUPP_COUNTRY_LOC',
                       NULL);
      fetch C_SUM_PACKITEM_COST into L_total_pack_cost;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_SUM_PACKITEM_COST',
                       'V_PACKSKU_QTY,ITEM_SUPP_COUNTRY_LOC',
                       NULL);
      close C_SUM_PACKITEM_COST;
      ---
      FOR C_rec in C_GET_PACKITEMS LOOP
         L_comp_item      := C_rec.item;
         L_error_ind      := 'N';
         L_total_comp_qty := 0;
         L_qty            := 0;
         ---
         if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                             L_standard_uom,
                                             L_standard_class,
                                             L_conv_factor,
                                             L_comp_item,
                                             'N') = FALSE then
            return FALSE;
         end if;
         ---
         if I_qty <> 0 then
            ---
            -- This loop is needed here in order to ensure that the
            -- errors get entered in appropriately and are not duplicated.
            ---
            FOR P_rec in C_GET_PACKITEMS_QTY LOOP
               L_temp_comp_item:= P_rec.item;
               ---
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_temp_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_temp_comp_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_comp_qty,
                                  NVL(I_alloc_basis_uom, L_uom),
                                  P_rec.qty,
                                  L_temp_standard_uom,
                                  L_temp_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_comp_qty = 0 and L_temp_comp_item= L_comp_item then
                  L_unit_of_work := 'Order No. '||to_char(L_order_no)||', Item '||L_temp_comp_item||
                                    ', Pack '||L_item||
                                    ', Obligation '||to_char(I_obligation_key)||
                                    ', Component '||I_comp_id;
                  ---
                  if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                                          SQL_LIB.GET_MESSAGE_TEXT('ALC_UOM_ERROR',
                                                                                   L_temp_comp_item,
                                                                                   NULL,
                                                                                   NULL),
                                                          L_program,
                                                          L_unit_of_work) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  L_error_ind := 'Y';
               end if;
               ---
               L_total_comp_qty := L_total_comp_qty + L_comp_qty;
            END LOOP;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_comp_qty,
                               NVL(I_alloc_basis_uom, L_uom),
                               C_rec.qty,
                               L_standard_uom,
                               C_rec.item,
                               L_supplier,
                               L_origin_country_id) = FALSE then
               return FALSE;
            end if;
            ---
            if L_total_comp_qty = 0 then
               L_total_comp_qty := 1;
            end if;
            ---
            L_temp_qty := I_qty * (L_comp_qty / L_total_comp_qty);
            ---
            -- Convert the temp qty from the alloc basis uom to the comp item's stndrd uom.
            ---
            if L_temp_qty <> 0 then
               if UOM_SQL.CONVERT(O_error_message,
                                  L_qty,
                                  L_standard_uom,
                                  L_temp_qty,
                                  NVL(I_alloc_basis_uom, L_uom),
                                  L_comp_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_qty = 0 then
                  L_unit_of_work := 'Order No. '||to_char(L_order_no)||', Item '||L_comp_item||
                                    ', Pack '||L_item||
                                    ', Obligation '||to_char(I_obligation_key)||
                                    ', Component '||I_comp_id;
                  ---
                  if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                                          SQL_LIB.GET_MESSAGE_TEXT('ALC_UOM_ERROR',
                                                                                   L_comp_item,
                                                                                   NULL,
                                                                                   NULL),
                                                          L_program,
                                                          L_unit_of_work) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  L_error_ind := 'Y';
               end if;
            end if;
            ---
            L_amt_prim := I_amt_prim * (L_temp_qty / I_qty);
         else
            L_qty      := 1;
            L_amt_prim := 0;
         end if;
         ---
         if I_alloc_basis_uom is NULL then
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_PACKITEM_COST',
                             'V_PACKSKU_QTY,ITEM_SUPP_COUNTRY_LOC',
                             NULL);
            open C_GET_PACKITEM_COST;
            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_PACKITEM_COST',
                             'V_PACKSKU_QTY,ITEM_SUPP_COUNTRY_LOC',
                             NULL);
            fetch C_GET_PACKITEM_COST into L_packitem_cost;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_PACKITEM_COST',
                             'V_PACKSKU_QTY,ITEM_SUPP_COUNTRY_LOC',
                             NULL);
            close C_GET_PACKITEM_COST;
            ---
            L_amt_prim := I_amt_prim * (L_packitem_cost / L_total_pack_cost);
         end if;
         ---
         SQL_LIB.SET_MARK('OPEN',
                          'C_ALC_HEAD_EXISTS',
                          'ALC_HEAD',
                          NULL);
         open C_ALC_HEAD_EXISTS;
         SQL_LIB.SET_MARK('FETCH',
                          'C_ALC_HEAD_EXISTS',
                          'ALC_HEAD',
                          NULL);
         fetch C_ALC_HEAD_EXISTS into L_alc_head_exists;
         SQL_LIB.SET_MARK('CLOSE',
                          'C_ALC_HEAD_EXISTS',
                          'ALC_HEAD',
                          NULL);
         close C_ALC_HEAD_EXISTS;
         ---
         if L_alc_head_exists = 'N' then
            if INSERT_ALC_HEAD(O_error_message,
                               L_order_no,
                               L_comp_item,
                               L_pack_no,
                               I_obligation_key,
                               NULL,
                               NULL,
                               NULL,
                               L_qty,
                               L_error_ind) = FALSE then
               return FALSE;
            end if;
         else
            if L_error_ind = 'Y' then
               ---
               -- Lock the ALC records.
               ---
               L_table := 'ALC_HEAD';
               SQL_LIB.SET_MARK('OPEN',
                                'C_LOCK_ALC_HEAD',
                                'ALC_HEAD',
                                NULL);
               open C_LOCK_ALC_HEAD;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_LOCK_ALC_HEAD',
                                'ALC_HEAD',
                                NULL);
               close C_LOCK_ALC_HEAD;
               ---
               SQL_LIB.SET_MARK('UPDATE',
                                NULL,
                                'ALC_HEAD',
                                NULL);
               ---
               update alc_head
                  set error_ind = 'Y'
                where order_no         = L_order_no
                  and ((item           = L_item
                        and pack_item is NULL)
                    or (item           = L_comp_item
                        and pack_item  = L_item))
                  and obligation_key   = I_obligation_key
                  and vessel_id       is NULL;
            end if;
         end if;
         ---
         L_alc_head_exists := 'N';
         ---
         if L_obl_locs_exist = 'N' then
            FOR L_rec in C_GET_ORD_LOCS LOOP
               L_location := L_rec.location;
               ---
               SQL_LIB.SET_MARK('OPEN',
                                'C_GET_QTY_SHIPPED',
                                'SHIPMENT,SHIPSKU',
                                NULL);
               open C_GET_QTY_SHIPPED;
               SQL_LIB.SET_MARK('FETCH',
                                'C_GET_QTY_SHIPPED',
                                'SHIPMENT,SHIPSKU',
                                NULL);
               fetch C_GET_QTY_SHIPPED into L_qty_shipped;
               SQL_LIB.SET_MARK('CLOSE',
                                'C_GET_QTY_SHIPPED',
                                'SHIPMENT,SHIPSKU',
                                NULL);
               close C_GET_QTY_SHIPPED;
               ---
               if L_qty_rec >= L_qty_ord and  L_qty_ord >0 then
                  L_loc_qty := (NVL(L_rec.qty_received, 0) / L_qty_rec) * L_qty;
               elsif L_qty_shp > 0 then
                  L_loc_qty := (NVL(L_qty_shipped, 0) / L_qty_shp) * L_qty;
               elsif  L_qty_ord >0 then
                  L_loc_qty := (NVL(L_rec.qty_ordered, 0) / L_qty_ord) * L_qty;
               end if;
               ---
               if L_loc_qty = 0 then
                  L_amt_prim := 0;
                  L_qty      := 1;
               end if;
               ---
               if INSERT_ALC_COMP_LOCS(O_error_message,
                                       L_order_no,
                                       L_comp_item,
                                       L_pack_no,
                                       I_obligation_key,
                                       I_comp_id,
                                       L_rec.location,
                                       L_rec.loc_type,
                                       L_amt_prim / L_qty,
                                       L_loc_qty) = FALSE then
                  return FALSE;
               end if;
               ---
               -- Removed call to insert_elc_comps.  Expenses are now
               -- logged at order approval time in alc_alloc_sql.insert_expense_comps
               ---
            END LOOP;
         else  -- Obligation Location records exist
            if I_location is not NULL then
               -- convert location qty from alloc_basis_uom to eaches
               ---
               L_total_comp_qty := 0;
               L_loc_qty        := 0;
               ---
               if I_loc_qty <> 0 then
                  FOR P_rec in C_GET_PACKITEMS_QTY LOOP
                     L_temp_comp_item:= P_rec.item;
                     ---
                     if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                         L_temp_standard_uom,
                                                         L_standard_class,
                                                         L_conv_factor,
                                                         L_temp_comp_item,
                                                         'N') = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if UOM_SQL.CONVERT(O_error_message,
                                        L_comp_qty,
                                        NVL(I_alloc_basis_uom, L_uom),
                                        P_rec.qty,
                                        L_temp_standard_uom,
                                        L_temp_comp_item,
                                        L_supplier,
                                        L_origin_country_id) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     L_total_comp_qty := L_total_comp_qty + L_comp_qty;
                  END LOOP;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_comp_qty,
                                     NVL(I_alloc_basis_uom, L_uom),
                                     C_rec.qty,
                                     L_standard_uom,
                                     L_comp_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if L_total_comp_qty = 0 then
                     L_total_comp_qty := 1;
                  end if;
                  ---
                  L_temp_qty := I_loc_qty * (L_comp_qty / L_total_comp_qty);
                  ---
                  if I_alloc_basis_uom is not NULL then
                     L_loc_amt := I_loc_amt * (L_temp_qty / I_loc_qty);
                  else
                     L_loc_amt := I_loc_amt * (L_packitem_cost / L_total_pack_cost);
                  end if;
                  ---
                  -- Convert the temp qty from the alloc basis uom to the comp item's standard uom.
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_loc_qty,
                                     L_standard_uom,
                                     L_temp_qty,
                                     NVL(I_alloc_basis_uom, L_uom),
                                     L_comp_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
               else
                  L_loc_qty := I_loc_qty;
               end if;
               ---
               if L_loc_qty = 0 then
                  L_loc_amt := 0;
                  L_temp_qty := 1;
               else
                  L_temp_qty := L_loc_qty;
               end if;
               ---
               if INSERT_ALC_COMP_LOCS(O_error_message,
                                       L_order_no,
                                       L_comp_item,
                                       L_pack_no,
                                       I_obligation_key,
                                       I_comp_id,
                                       I_location,
                                       I_loc_type,
                                       L_loc_amt / L_temp_qty,
                                       L_loc_qty) = FALSE then
                  return FALSE;
               end if;
               ---
               -- Removed call to insert_elc_comps.  Expenses are now
               -- logged at order approval time in alc_alloc_sql.insert_expense_comps
               ---
            else
               FOR L_rec in C_GET_OBL_LOCS LOOP
                  ---
                  -- convert location qty from alloc_basis_uom to eaches
                  L_total_comp_qty := 0;
                  L_loc_qty        := 0;
                  ---
                  if L_rec.qty <> 0 then
                     FOR P_rec in C_GET_PACKITEMS_QTY LOOP
                        L_temp_comp_item:= P_rec.item;
                        ---
                        if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                            L_temp_standard_uom,
                                                            L_standard_class,
                                                            L_conv_factor,
                                                            L_temp_comp_item,
                                                            'N') = FALSE then
                           return FALSE;
                        end if;
                        ---
                        if UOM_SQL.CONVERT(O_error_message,
                                           L_comp_qty,
                                           NVL(I_alloc_basis_uom, L_uom),
                                           P_rec.qty,
                                           L_temp_standard_uom,
                                           L_temp_comp_item,
                                           L_supplier,
                                           L_origin_country_id) = FALSE then
                           return FALSE;
                        end if;
                        ---
                        L_total_comp_qty := L_total_comp_qty + L_comp_qty;
                     END LOOP;
                     ---
                     if UOM_SQL.CONVERT(O_error_message,
                                        L_comp_qty,
                                        NVL(I_alloc_basis_uom, L_uom),
                                        C_rec.qty,
                                        L_standard_uom,
                                        L_comp_item,
                                        L_supplier,
                                        L_origin_country_id) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if L_total_comp_qty = 0 then
                        L_total_comp_qty := 1;
                     end if;
                     ---
                     L_temp_qty := L_rec.qty * (L_comp_qty / L_total_comp_qty);
                     ---
                     -- Convert the temp qty from the alloc basis uom to the comp item's stndrd uom.
                     ---
                     if UOM_SQL.CONVERT(O_error_message,
                                        L_loc_qty,
                                        L_standard_uom,
                                        L_temp_qty,
                                        NVL(I_alloc_basis_uom, L_uom),
                                        L_comp_item,
                                        L_supplier,
                                        L_origin_country_id) = FALSE then
                        return FALSE;
                     end if;
                  else
                     L_loc_qty := L_rec.qty;
                  end if;
                  ---
                  if L_loc_qty = 0 then
                     L_amt_prim := 0;
                     L_temp_qty := 1;
                  else
                     ---
                     -- Convert the obligation amount from obligation currency to primary currency.
                     ---
                     if CURRENCY_SQL.CONVERT(O_error_message,
                                             L_rec.amt,
                                             LP_currency_obl,
                                             NULL,  -- primary currency
                                             L_amt_prim,
                                             'N',
                                             NULL,
                                             NULL,
                                             LP_exchange_rate_obl,
                                             NULL) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if I_alloc_basis_uom is not NULL then
                        L_amt_prim := L_amt_prim * (L_temp_qty / L_rec.qty);
                     else
                        L_amt_prim := L_amt_prim * (L_packitem_cost / L_total_pack_cost);
                     end if;
                     ---
                     L_temp_qty := L_loc_qty;
                  end if;
                  ---
                  if INSERT_ALC_COMP_LOCS(O_error_message,
                                          L_order_no,
                                          L_comp_item,
                                          L_pack_no,
                                          I_obligation_key,
                                          I_comp_id,
                                          L_rec.location,
                                          L_rec.loc_type,
                                          L_amt_prim / L_temp_qty,
                                          L_loc_qty) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  -- Removed call to insert_elc_comps.  Expenses are now
                  -- logged at order approval time in alc_alloc_sql.insert_expense_comps
                  ---
               END LOOP;  -- C_GET_OBL_LOCS LOOP
            end if;
         end if;    -- obligation locs exist
      END LOOP;  -- C_GET_PACKITEMS LOOP
   else  -- L_item is not a buyer pack
      ---
      -- convert obligation qty from alloc_basis_uom to eaches
      ---
      if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                          L_standard_uom,
                                          L_standard_class,
                                          L_conv_factor,
                                          L_item,
                                          'N') = FALSE then
         return FALSE;
      end if;
      ---
      if I_qty <> 0 then
         if UOM_SQL.CONVERT(O_error_message,
                            L_qty,
                            L_standard_uom,
                            I_qty,
                            NVL(I_alloc_basis_uom, L_uom),
                            L_item,
                            L_supplier,
                            L_origin_country_id) = FALSE then
            return FALSE;
         end if;
         ---
         if L_qty = 0 then
            L_unit_of_work := 'Order No. '||to_char(L_order_no)||', Item '||L_item||
                              ', Obligation '||to_char(I_obligation_key)||
                              ', Component '||I_comp_id;
            L_error_ind    := 'Y';
            ---
            if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                                    SQL_LIB.GET_MESSAGE_TEXT('ALC_UOM_ERROR',
                                                                             L_item,
                                                                             NULL,
                                                                             NULL),
                                                    L_program,
                                                    L_unit_of_work) = FALSE then
               return FALSE;
            end if;
         end if;
      else
         L_qty := I_qty;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN',
                       'C_ALC_HEAD_EXISTS',
                       'ALC_HEAD',
                       NULL);
      open C_ALC_HEAD_EXISTS;
      SQL_LIB.SET_MARK('FETCH',
                       'C_ALC_HEAD_EXISTS',
                       'ALC_HEAD',
                       NULL);
      fetch C_ALC_HEAD_EXISTS into L_alc_head_exists;
      SQL_LIB.SET_MARK('CLOSE',
                       'C_ALC_HEAD_EXISTS',
                       'ALC_HEAD',
                       NULL);
      close C_ALC_HEAD_EXISTS;
      ---
      if L_alc_head_exists = 'N' then
         if INSERT_ALC_HEAD(O_error_message,
                            L_order_no,
                            L_item,
                            NULL,
                            I_obligation_key,
                            NULL,
                            NULL,
                            NULL,
                            L_qty,
                            L_error_ind) = FALSE then
            return FALSE;
         end if;
      else
         if L_error_ind = 'Y' then
            ---
            -- Lock the ALC records.
            ---
            L_table := 'ALC_HEAD';
            SQL_LIB.SET_MARK('OPEN',
                             'C_LOCK_ALC_HEAD',
                             'ALC_HEAD',
                             NULL);
            open C_LOCK_ALC_HEAD;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_LOCK_ALC_HEAD',
                             'ALC_HEAD',
                             NULL);
            close C_LOCK_ALC_HEAD;
            ---
            SQL_LIB.SET_MARK('UPDATE',
                             NULL,
                             'ALC_HEAD',
                             NULL);
            ---
            update alc_head
               set error_ind = 'Y'
             where order_no         = L_order_no
               and ((item           = L_item
                     and pack_item is NULL)
                 or (item           = L_comp_item
                     and pack_item  = L_item))
               and obligation_key   = I_obligation_key
               and vessel_id       is NULL;
         end if;
      end if;
      ---
      if L_obl_locs_exist = 'N' then
         FOR C_rec in C_GET_ORD_LOCS LOOP
            L_location := C_rec.location;
            ---
            SQL_LIB.SET_MARK('OPEN',
                             'C_GET_QTY_SHIPPED',
                             'SHIPMENT,SHIPSKU',
                             NULL);
            open C_GET_QTY_SHIPPED;
            SQL_LIB.SET_MARK('FETCH',
                             'C_GET_QTY_SHIPPED',
                             'SHIPMENT,SHIPSKU',
                             NULL);
            fetch C_GET_QTY_SHIPPED into L_qty_shipped;
            SQL_LIB.SET_MARK('CLOSE',
                             'C_GET_QTY_SHIPPED',
                             'SHIPMENT,SHIPSKU',
                             NULL);
            close C_GET_QTY_SHIPPED;
            ---
            if L_qty_rec >= L_qty_ord and L_qty_ord > 0 then
               L_loc_qty := (NVL(C_rec.qty_received, 0) / L_qty_rec) * L_qty;
            elsif L_qty_shp > 0 then
               L_loc_qty := (NVL(L_qty_shipped, 0) / L_qty_shp) * L_qty;
            elsif L_qty_ord > 0  then
               L_loc_qty := (NVL(C_rec.qty_ordered, 0) / L_qty_ord) * L_qty;
            end if;
            ---
            if L_qty = 0 then
               L_amt_prim := 0;
               L_temp_qty := 1;
            else
               L_temp_qty := L_qty;
               L_amt_prim := I_amt_prim;
            end if;
            ---
            if INSERT_ALC_COMP_LOCS(O_error_message,
                                    L_order_no,
                                    L_item,
                                    NULL,
                                    I_obligation_key,
                                    I_comp_id,
                                    C_rec.location,
                                    C_rec.loc_type,
                                    L_amt_prim / L_temp_qty,
                                    L_loc_qty) = FALSE then
               return FALSE;
            end if;
            ---
            -- Removed call to insert_elc_comps.  Expenses are now
            -- logged at order approval time in alc_alloc_sql.insert_expense_comps
            ---
         END LOOP;
      else
         if I_location is not NULL then
            if I_alloc_basis_uom <> L_standard_uom then
               -- convert location qty from alloc_basis_uom to the item's stndrd uom.
               if UOM_SQL.CONVERT(O_error_message,
                                  L_loc_qty,
                                  L_standard_uom,
                                  I_loc_qty,
                                  NVL(I_alloc_basis_uom, L_uom),
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            else
               L_loc_qty := I_loc_qty;
            end if;
            ---
            if L_loc_qty = 0 then
               L_loc_amt  := 0;
               L_temp_qty := 1;
            else
               L_temp_qty := L_loc_qty;
               L_loc_amt := I_loc_amt;
            end if;
            ---
            if INSERT_ALC_COMP_LOCS(O_error_message,
                                    L_order_no,
                                    L_item,
                                    NULL,
                                    I_obligation_key,
                                    I_comp_id,
                                    I_location,
                                    I_loc_type,
                                    L_loc_amt / L_temp_qty,
                                    L_loc_qty) = FALSE then
               return FALSE;
            end if;
            ---
            --- Removed call to insert_elc_comps.  Expenses are now
            -- logged at order approval time in alc_alloc_sql.insert_expense_comps
            ---
         else   -- I_location is NULL
            FOR C_rec in C_GET_OBL_LOCS LOOP
               if I_alloc_basis_uom <> L_standard_uom then
                  ---
                  -- convert location qty from alloc_basis_uom to the item's stndrd uom.
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_loc_qty,
                                     L_standard_uom,
                                     C_rec.qty,
                                     NVL(I_alloc_basis_uom, L_uom),
                                     L_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
               else
                  L_loc_qty := C_rec.qty;
               end if;
               ---
               -- Convert the obligation amount from obligation currency to primary currency.
               ---
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       C_rec.amt,
                                       LP_currency_obl,
                                       NULL,  -- primary currency
                                       L_amt_prim,
                                       'N',
                                       NULL,
                                       NULL,
                                       LP_exchange_rate_obl,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
               ---
               if L_loc_qty = 0 then
                  L_amt_prim := 0;
                  L_temp_qty := 1;
               else
                  L_temp_qty := L_loc_qty;
               end if;
               ---
               if INSERT_ALC_COMP_LOCS(O_error_message,
                                       L_order_no,
                                       L_item,
                                       NULL,
                                       I_obligation_key,
                                       I_comp_id,
                                       C_rec.location,
                                       C_rec.loc_type,
                                       L_amt_prim / L_temp_qty,
                                       L_loc_qty) = FALSE then
                  return FALSE;
               end if;
               ---
               -- Removed call to insert_elc_comps.  Expenses are now
               -- logged at order approval time in alc_alloc_sql.insert_expense_comps
               ---
            END LOOP;  -- C_GET_OBL_LOCS LOOP
         end if;   -- I_location is not NULL
      end if;  -- obligation locs exist
   end if;  -- L_pack_type = 'B'
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
END ALLOC_PO_ITEM;
-------------------------------------------------------------------------------
FUNCTION ALLOC_PO(O_error_message     IN OUT VARCHAR2,
                  I_obligation_key    IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                  I_obligation_level  IN     OBLIGATION.OBLIGATION_LEVEL%TYPE,
                  I_key_value_1       IN     OBLIGATION.KEY_VALUE_1%TYPE,
                  I_comp_id           IN     ELC_COMP.COMP_ID%TYPE,
                  I_alloc_basis_uom   IN     UOM_CLASS.UOM%TYPE,
                  I_uom_class         IN     UOM_CLASS.UOM_CLASS%TYPE,
                  I_qty               IN     OBLIGATION_COMP.QTY%TYPE,
                  I_amt_prim          IN     OBLIGATION_COMP.AMT%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(64)                := 'ALC_ALLOC_SQL.ALLOC_PO';
   L_obl_locs_exist       VARCHAR2(1)                 := 'N';
   L_item_ord_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_item_rec_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_pack_rec_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_comp_rec_qty         ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_comp_qty             ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_total_rec_qty        ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_rec_qty              ORDLOC.QTY_ORDERED%TYPE     := 0;
   L_qty                  ALC_COMP_LOC.QTY%TYPE       := 0;
   L_item_qty             ALC_COMP_LOC.QTY%TYPE       := 0;
   L_loc_qty              ALC_COMP_LOC.QTY%TYPE       := 0;
   L_act_value            ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_amt_prim             ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_amt                  ALC_COMP_LOC.ACT_VALUE%TYPE := 0;
   L_total_rec_cost       ORDLOC.UNIT_COST%TYPE       := 0;
   L_unit_cost            ORDLOC.UNIT_COST%TYPE       := 0;
   L_total_comp_qty       ORDLOC.QTY_ORDERED%TYPE;
   L_order_no             ORDHEAD.ORDER_NO%TYPE;
   L_item                 ITEM_MASTER.ITEM%TYPE;
   L_comp_item            ITEM_MASTER.ITEM%TYPE;
   L_location             ORDLOC.LOCATION%TYPE;
   L_loc_type             ORDLOC.LOC_TYPE%TYPE;
   L_supplier             SUPS.SUPPLIER%TYPE;
   L_origin_country_id    COUNTRY.COUNTRY_ID%TYPE;
   L_temp_qty             ALC_HEAD.ALC_QTY%TYPE;
   L_standard_uom         UOM_CLASS.UOM%TYPE;
   L_uom                  UOM_CLASS.UOM%TYPE;
   L_standard_class       UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor          UOM_CONVERSION.FACTOR%TYPE;
   ---
   L_pack_ind             ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind         ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind        ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type            ITEM_MASTER.PACK_TYPE%TYPE;
   ---
   L_table                VARCHAR2(30);
   RECORD_LOCKED          EXCEPTION;
   PRAGMA                 EXCEPTION_INIT(Record_Locked, -54);

   cursor C_OBL_LOCS_EXIST is
      select 'Y'
        from obligation_comp_loc
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_GET_ITEMS is
      select s.item,
             s.origin_country_id,
             o.supplier
        from ordsku s,
             ordhead o
       where o.order_no = L_order_no
         and o.order_no = s.order_no;

   cursor C_GET_PACKITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

   cursor C_GET_ITEM_QTY is
      select NVL(SUM(qty_received), 0)
        from ordloc
       where order_no = L_order_no
         and item     = L_item;

   cursor C_GET_ITEMLOC_QTY is
      select NVL(SUM(qty_received), 0)
        from ordloc
       where order_no = L_order_no
         and item     = L_item
         and location = L_location;

   cursor C_GET_OBL_LOCS is
      select location,
             loc_type,
             amt,
             qty
        from obligation_comp_loc
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_LOCK_ALC_HEAD is
      select 'x'
        from alc_head
       where order_no       = L_order_no
         and obligation_key = I_obligation_key
         for update nowait;

   cursor C_GET_QTY_UOM is
      select per_count_uom
        from obligation_comp
       where obligation_key = I_obligation_key
         and comp_id        = I_comp_id;

   cursor C_GET_ORD_COST is
      select item,(sum(unit_cost*qty_ordered)/sum(qty_ordered)) unit_cost
        from ordloc
       where order_no   = L_order_no
       and qty_ordered > 0
    group by item ;

   cursor C_GET_ITEMLOC_COST is
      select l.item,
             l.unit_cost
        from ordloc l
       where l.order_no = L_order_no
         and l.location = L_location
         and l.loc_type = L_loc_type ;

BEGIN
   L_order_no := to_number(I_key_value_1);
   ---
   SQL_LIB.SET_MARK('OPEN','C_OBL_LOCS_EXIST','OBLIGATION_COMP_LOC',NULL);
   open C_OBL_LOCS_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_OBL_LOCS_EXIST','OBLIGATION_COMP_LOC',NULL);
   fetch C_OBL_LOCS_EXIST into L_obl_locs_exist;
   SQL_LIB.SET_MARK('CLOSE','C_OBL_LOCS_EXIST','OBLIGATION_COMP_LOC',NULL);
   close C_OBL_LOCS_EXIST;
   ---
   if I_alloc_basis_uom is not NULL then
      if L_obl_locs_exist = 'N' then
         ---
         -- Loop through the items on ordsku and sum the total qty received in the alloc basis uom.
         ---
         FOR C_rec in C_GET_ITEMS LOOP
            L_item              := C_rec.item;
            L_origin_country_id := C_rec.origin_country_id;
            L_supplier          := C_rec.supplier;
            L_item_rec_qty      := 0;
            L_pack_rec_qty      := 0;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                              ' item: '||L_item);
            open C_GET_ITEM_QTY;
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                               ' item: '||L_item);
            fetch C_GET_ITEM_QTY into L_rec_qty;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                               ' item: '||L_item);
            close C_GET_ITEM_QTY;
            ---
            if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                             L_pack_ind,
                                             L_sellable_ind,
                                             L_orderable_ind,
                                             L_pack_type,
                                             L_item) = FALSE then
               return FALSE;
            end if;
            ---
            if nvl(L_pack_type,'N') = 'B' then
               FOR C_rec in C_GET_PACKITEMS LOOP
                  L_comp_item:= C_rec.item;
                  L_comp_qty := C_rec.qty;
                  ---
                  if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                      L_standard_uom,
                                                      L_standard_class,
                                                      L_conv_factor,
                                                      L_comp_item,
                                                      'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_comp_qty,
                                     I_alloc_basis_uom,
                                     L_comp_qty,
                                     L_standard_uom,
                                     L_comp_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  L_pack_rec_qty := L_pack_rec_qty + (L_rec_qty * L_comp_qty);
               END LOOP;
            else
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  I_alloc_basis_uom,
                                  L_rec_qty,
                                  L_standard_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            L_total_rec_qty := L_total_rec_qty + L_item_rec_qty + L_pack_rec_qty;
         END LOOP;
         -- loop through items on ordsku
         FOR C_rec in C_GET_ITEMS LOOP
            L_item               := C_rec.item;
            L_origin_country_id := C_rec.origin_country_id;
            L_supplier          := C_rec.supplier;
            L_item_rec_qty      := 0;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                              ' item: '||L_item);
            open C_GET_ITEM_QTY;
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                               ' item: '||L_item);
            fetch C_GET_ITEM_QTY into L_rec_qty;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                               ' item: '||L_item);
            close C_GET_ITEM_QTY;
            ---
            if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                             L_pack_ind,
                                             L_sellable_ind,
                                             L_orderable_ind,
                                             L_pack_type,
                                             L_item) = FALSE then
               return FALSE;
            end if;
            ---
            if nvl(L_pack_type,'N') = 'B' then
               FOR C_rec in C_GET_PACKITEMS LOOP
                  L_comp_item:= C_rec.item;
                  L_comp_qty := C_rec.qty;
                  ---
                  if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                      L_standard_uom,
                                                      L_standard_class,
                                                      L_conv_factor,
                                                      L_comp_item,
                                                      'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_comp_qty,
                                     I_alloc_basis_uom,
                                     L_comp_qty,
                                     L_standard_uom,
                                     L_comp_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  L_item_rec_qty := L_item_rec_qty + (L_rec_qty * L_comp_qty);
               END LOOP;
            else
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  I_alloc_basis_uom,
                                  L_rec_qty,
                                  L_standard_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            if L_total_rec_qty <> 0 then
               -- take qty * expense amt / total qty
               L_act_value := L_item_rec_qty * I_amt_prim / L_total_rec_qty;
               L_qty       := L_item_rec_qty * I_qty      / L_total_rec_qty;
            else
               L_act_value := 0;
               L_qty := 0;
            end if;
            ---
            if ALLOC_PO_ITEM(O_error_message,
                             I_obligation_key,
                             I_obligation_level,
                             I_key_value_1,
                             L_item,
                             I_comp_id,
                             I_alloc_basis_uom,
                             L_qty,
                             L_act_value,
                             NULL,
                             NULL,
                             NULL,
                             NULL) = FALSE then
               return FALSE;
            end if;
         END LOOP;
      else  -- L_obl_locs_exist = 'Y'
         L_temp_qty := 1;
         ---
         FOR L_rec in C_GET_OBL_LOCS LOOP
            L_location      := L_rec.location;
            L_total_rec_qty := 0;
            ---
            FOR C_rec in C_GET_ITEMS LOOP
               L_item              := C_rec.item;
               L_origin_country_id := C_rec.origin_country_id;
               L_supplier          := C_rec.supplier;
               L_item_rec_qty      := 0;
               L_pack_rec_qty      := 0;
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_ITEMLOC_QTY','ORDLOC',NULL);
               open C_GET_ITEMLOC_QTY;
               SQL_LIB.SET_MARK('FETCH','C_GET_ITEMLOC_QTY','ORDLOC',NULL);
               fetch C_GET_ITEMLOC_QTY into L_rec_qty;
               SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMLOC_QTY','ORDLOC',NULL);
               close C_GET_ITEMLOC_QTY;
               ---
               if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                                L_pack_ind,
                                                L_sellable_ind,
                                                L_orderable_ind,
                                                L_pack_type,
                                                L_item) = FALSE then
                  return FALSE;
               end if;
               ---
               if nvl(L_pack_type,'N') = 'B' then
                  FOR C_rec in C_GET_PACKITEMS LOOP
                     L_comp_item:= C_rec.item;
                     L_comp_qty := C_rec.qty;
                     ---
                     if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                         L_standard_uom,
                                                         L_standard_class,
                                                         L_conv_factor,
                                                         L_comp_item,
                                                         'N') = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if UOM_SQL.CONVERT(O_error_message,
                                        L_comp_qty,
                                        I_alloc_basis_uom,
                                        L_comp_qty,
                                        L_standard_uom,
                                        L_comp_item,
                                        L_supplier,
                                        L_origin_country_id) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     L_pack_rec_qty := L_pack_rec_qty + (L_rec_qty * L_comp_qty);
                  END LOOP;
               else
                  if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                      L_standard_uom,
                                                      L_standard_class,
                                                      L_conv_factor,
                                                      L_item,
                                                      'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     I_alloc_basis_uom,
                                     L_rec_qty,
                                     L_standard_uom,
                                     L_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
               end if;
               ---
               L_total_rec_qty := L_total_rec_qty + L_item_rec_qty + L_pack_rec_qty;
            END LOOP;
            ---
            -- loop through items on ordsku
            ---
            FOR C_rec in C_GET_ITEMS LOOP
               L_item              := C_rec.item;
               L_origin_country_id := C_rec.origin_country_id;
               L_supplier          := C_rec.supplier;
               L_item_rec_qty      := 0;
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_ITEMLOC_QTY','ORDLOC',NULL);
               open C_GET_ITEMLOC_QTY;
               SQL_LIB.SET_MARK('FETCH','C_GET_ITEMLOC_QTY','ORDLOC',NULL);
               fetch C_GET_ITEMLOC_QTY into L_rec_qty;
               SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMLOC_QTY','ORDLOC',NULL);
               close C_GET_ITEMLOC_QTY;
               ---
               if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                                L_pack_ind,
                                                L_sellable_ind,
                                                L_orderable_ind,
                                                L_pack_type,
                                                L_item) = FALSE then
                  return FALSE;
               end if;
               ---
               if nvl(L_pack_type,'N') = 'B' then
                  FOR C_rec in C_GET_PACKITEMS LOOP
                     L_comp_item:= C_rec.item;
                     L_comp_qty := C_rec.qty;
                     ---
                     if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                         L_standard_uom,
                                                         L_standard_class,
                                                         L_conv_factor,
                                                         L_comp_item,
                                                         'N') = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if UOM_SQL.CONVERT(O_error_message,
                                        L_comp_qty,
                                        I_alloc_basis_uom,
                                        L_comp_qty,
                                        L_standard_uom,
                                        L_comp_item,
                                        L_supplier,
                                        L_origin_country_id) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     L_item_rec_qty := L_item_rec_qty + (L_rec_qty * L_comp_qty);
                  END LOOP;
               else
                  if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                      L_standard_uom,
                                                      L_standard_class,
                                                      L_conv_factor,
                                                      L_item,
                                                      'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     I_alloc_basis_uom,
                                     L_rec_qty,
                                     L_standard_uom,
                                     L_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
               end if;
               ---
               if L_total_rec_qty <> 0 then
                  -- take qty * expense amt / total qty
                  L_amt := L_item_rec_qty * L_rec.amt / L_total_rec_qty;
                  L_qty := L_item_rec_qty * L_rec.qty / L_total_rec_qty;
               else
                  L_amt := 0;
                  L_qty := 0;
               end if;
               ---
               -- Convert the obligation amount from obligation currency to primary currency.
               ---
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_amt,
                                       LP_currency_obl,
                                       NULL,  -- primary currency
                                       L_amt_prim,
                                       'N',
                                       NULL,
                                       NULL,
                                       LP_exchange_rate_obl,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
               ---
               if ALLOC_PO_ITEM(O_error_message,
                                I_obligation_key,
                                I_obligation_level,
                                I_key_value_1,
                                L_item,
                                I_comp_id,
                                I_alloc_basis_uom,
                                L_temp_qty, -- qty will be updated after the loop
                                0,          -- amt will be updated after the loop
                                L_location,
                                L_rec.loc_type,
                                L_qty,
                                L_amt_prim) = FALSE then
                  return FALSE;
               end if;
               ---
            END LOOP;
            L_temp_qty := 0;
         END LOOP;
         ---
         -- Lock the ALC records.
         ---
         L_table := 'ALC_HEAD';
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ALC_HEAD','ALC_HEAD',NULL);
         open C_LOCK_ALC_HEAD;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALC_HEAD','ALC_HEAD',NULL);
         close C_LOCK_ALC_HEAD;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'ALC_HEAD',NULL);
         update alc_head a
            set a.alc_qty = (select SUM(l.qty)
                               from alc_comp_loc l
                              where l.order_no = a.order_no
                                and l.seq_no   = a.seq_no
                                and l.comp_id  = I_comp_id)
          where a.order_no       = L_order_no
            and a.obligation_key = I_obligation_key;
      end if;
   else    -- L_alloc_basis_uom is NULL
      SQL_LIB.SET_MARK('OPEN','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                ' Component: '||I_comp_id);
      open C_GET_QTY_UOM;
      SQL_LIB.SET_MARK('FETCH','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                 ' Component: '||I_comp_id);
      fetch C_GET_QTY_UOM into L_uom;
      SQL_LIB.SET_MARK('CLOSE','C_GET_QTY_UOM','OBLIGATION_COMP','Obligation: '||to_char(I_obligation_key)||
                                                                 ' Component: '||I_comp_id);
      close C_GET_QTY_UOM;
      ---
      L_total_rec_cost := 0;
      L_total_rec_qty  := 0;
      ---
      -- I_alloc_basis_uom is NULL therefore allocate across monetary value.
      -- open cursor that sums the unit cost of each item on ordsku
      -- loop through items on ordsku and take unit cost * the expense amount / total cost.
      if L_obl_locs_exist = 'N' then
         FOR C_rec in C_GET_ORD_COST LOOP
            L_unit_cost         := C_rec.unit_cost;
            L_item              := C_rec.item;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                              ' item: '||L_item);
            open C_GET_ITEM_QTY;
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                               ' item: '||L_item);
            fetch C_GET_ITEM_QTY into L_item_qty;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                               ' item: '||L_item);
            close C_GET_ITEM_QTY;
            ---
            if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                             L_pack_ind,
                                             L_sellable_ind,
                                             L_orderable_ind,
                                             L_pack_type,
                                             L_item) = FALSE then
               return FALSE;
            end if;
            ---
            if nvl(L_pack_type,'N') = 'B' then
               L_item_rec_qty := 0;
               FOR C_rec in C_GET_PACKITEMS LOOP
                  L_comp_item    := C_rec.item;
                  L_comp_rec_qty := C_rec.qty;
                  ---
                  if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                      L_standard_uom,
                                                      L_standard_class,
                                                      L_conv_factor,
                                                      L_comp_item,
                                                      'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_comp_rec_qty,
                                     L_uom,
                                     L_comp_rec_qty,
                                     L_standard_uom,
                                     L_comp_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_item_qty);
               END LOOP;
            else
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_uom,
                                  L_item_qty,
                                  L_standard_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            L_total_rec_cost := L_total_rec_cost + (L_item_qty * L_unit_cost);
            L_total_rec_qty  := L_total_rec_qty  +  L_item_rec_qty;
         END LOOP;
         ---
         L_item_rec_qty := 0;
         ---
         FOR C_rec in C_GET_ORD_COST LOOP
            L_unit_cost         := C_rec.unit_cost;
            L_item               := C_rec.item;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                              ' item: '||L_item);
            open C_GET_ITEM_QTY;
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                               ' item: '||L_item);
            fetch C_GET_ITEM_QTY into L_item_qty;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                               ' item: '||L_item);
            close C_GET_ITEM_QTY;
            ---
            if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                             L_pack_ind,
                                             L_sellable_ind,
                                             L_orderable_ind,
                                             L_pack_type,
                                             L_item) = FALSE then
               return FALSE;
            end if;
            ---
            if nvl(L_pack_type,'N') = 'B' then
               L_item_rec_qty := 0;
               FOR C_rec in C_GET_PACKITEMS LOOP
                  L_comp_item    := C_rec.item;
                  L_comp_rec_qty := C_rec.qty;
                  ---
                  if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                      L_standard_uom,
                                                      L_standard_class,
                                                      L_conv_factor,
                                                      L_comp_item,
                                                      'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_comp_rec_qty,
                                     L_uom,
                                     L_comp_rec_qty,
                                     L_standard_uom,
                                     L_comp_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
                  ---
                  L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_item_qty);
               END LOOP;
            else
               if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                   L_standard_uom,
                                                   L_standard_class,
                                                   L_conv_factor,
                                                   L_item,
                                                   'N') = FALSE then
                  return FALSE;
               end if;
               ---
               if UOM_SQL.CONVERT(O_error_message,
                                  L_item_rec_qty,
                                  L_uom,
                                  L_item_qty,
                                  L_standard_uom,
                                  L_item,
                                  L_supplier,
                                  L_origin_country_id) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            -- calculate: expense amt * (qty / total qty) and qty * (qty / total qty)
            L_amt_prim := I_amt_prim * ((L_item_qty * L_unit_cost) / L_total_rec_cost);
            L_qty      := I_qty      *  (L_item_rec_qty            / L_total_rec_qty);
            ---
            if ALLOC_PO_ITEM(O_error_message,
                             I_obligation_key,
                             I_obligation_level,
                             I_key_value_1,
                             L_item,
                             I_comp_id,
                             NULL,
                             L_qty,
                             L_amt_prim,
                             NULL,
                             NULL,
                             NULL,
                             NULL) = FALSE then
               return FALSE;
            end if;
         END LOOP;
      else
         L_temp_qty := 1;
         ---
         FOR L_rec in C_GET_OBL_LOCS LOOP
            L_location       := L_rec.location;
            L_loc_type       := L_rec.loc_type;
            L_total_rec_cost := 0;
            L_total_rec_qty  := 0;
            L_item_rec_qty   := 0;
            ---
            FOR C_rec in C_GET_ITEMLOC_COST LOOP
               L_unit_cost         := C_rec.unit_cost;
               L_item               := C_rec.item;
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_ITEMLOC_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                                    ' item: '||L_item);
               open C_GET_ITEMLOC_QTY;
               SQL_LIB.SET_MARK('FETCH','C_GET_ITEMLOC_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                                     ' item: '||L_item);
               fetch C_GET_ITEMLOC_QTY into L_item_qty;
               SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMLOC_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                                     ' item: '||L_item);
               close C_GET_ITEMLOC_QTY;
               ---
               if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                                L_pack_ind,
                                                L_sellable_ind,
                                                L_orderable_ind,
                                                L_pack_type,
                                                L_item) = FALSE then
                  return FALSE;
               end if;
               ---
               if nvl(L_pack_type,'N') = 'B' then
                  L_item_rec_qty := 0;
                  FOR C_rec in C_GET_PACKITEMS LOOP
                     L_comp_item    := C_rec.item;
                     L_comp_rec_qty := C_rec.qty;
                     ---
                     if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                         L_standard_uom,
                                                         L_standard_class,
                                                         L_conv_factor,
                                                         L_comp_item,
                                                         'N') = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if UOM_SQL.CONVERT(O_error_message,
                                        L_comp_rec_qty,
                                        L_uom,
                                        L_comp_rec_qty,
                                        L_standard_uom,
                                        L_comp_item,
                                        L_supplier,
                                        L_origin_country_id) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_item_qty);
                  END LOOP;
               else
                  if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                      L_standard_uom,
                                                      L_standard_class,
                                                      L_conv_factor,
                                                      L_item,
                                                      'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     L_uom,
                                     L_item_qty,
                                     L_standard_uom,
                                     L_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
               end if;
               ---
               L_total_rec_cost := L_total_rec_cost + (L_item_qty * L_unit_cost);
               L_total_rec_qty  := L_total_rec_qty  +  L_item_rec_qty;
            END LOOP;
            ---
            L_item_rec_qty := 0;
            ---
            FOR C_rec in C_GET_ITEMLOC_COST LOOP
               L_unit_cost         := C_rec.unit_cost;
               L_item               := C_rec.item;
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_ITEMLOC_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                                    ' item: '||L_item);
               open C_GET_ITEMLOC_QTY;
               SQL_LIB.SET_MARK('FETCH','C_GET_ITEMLOC_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                                     ' item: '||L_item);
               fetch C_GET_ITEMLOC_QTY into L_item_qty;
               SQL_LIB.SET_MARK('CLOSE','C_GET_ITEMLOC_QTY','ORDLOC','order no: '||to_char(L_order_no)||
                                                                     ' item: '||L_item);
               close C_GET_ITEMLOC_QTY;
               ---
               if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                                L_pack_ind,
                                                L_sellable_ind,
                                                L_orderable_ind,
                                                L_pack_type,
                                                L_item) = FALSE then
                  return FALSE;
               end if;
               ---
               if nvl(L_pack_type,'N') = 'B' then
                  L_item_rec_qty := 0;
                  FOR C_rec in C_GET_PACKITEMS LOOP
                     L_comp_item    := C_rec.item;
                     L_comp_rec_qty := C_rec.qty;
                     ---
                     if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                         L_standard_uom,
                                                         L_standard_class,
                                                         L_conv_factor,
                                                         L_comp_item,
                                                         'N') = FALSE then
                        return FALSE;
                     end if;
                     ---
                     if UOM_SQL.CONVERT(O_error_message,
                                        L_comp_rec_qty,
                                        L_uom,
                                        L_comp_rec_qty,
                                        L_standard_uom,
                                        L_comp_item,
                                        L_supplier,
                                        L_origin_country_id) = FALSE then
                        return FALSE;
                     end if;
                     ---
                     L_item_rec_qty := L_item_rec_qty + (L_comp_rec_qty * L_item_qty);
                  END LOOP;
               else
                  if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                      L_standard_uom,
                                                      L_standard_class,
                                                      L_conv_factor,
                                                      L_item,
                                                      'N') = FALSE then
                     return FALSE;
                  end if;
                  ---
                  if UOM_SQL.CONVERT(O_error_message,
                                     L_item_rec_qty,
                                     L_uom,
                                     L_item_qty,
                                     L_standard_uom,
                                     L_item,
                                     L_supplier,
                                     L_origin_country_id) = FALSE then
                     return FALSE;
                  end if;
               end if;
               ---
               L_amt := L_rec.amt * (L_item_qty * L_unit_cost / L_total_rec_cost);
               L_qty := L_rec.qty * (L_item_rec_qty           / L_total_rec_qty);
               ---
               -- Convert the obligation amount from obligation currency to primary currency.
               ---
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_amt,
                                       LP_currency_obl,
                                       NULL,  -- primary currency
                                       L_amt_prim,
                                       'N',
                                       NULL,
                                       NULL,
                                       LP_exchange_rate_obl,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
               ---
               if ALLOC_PO_ITEM(O_error_message,
                                I_obligation_key,
                                I_obligation_level,
                                I_key_value_1,
                                L_item,
                                I_comp_id,
                                NULL,
                                L_temp_qty, -- qty will be updated after loop
                                0,          -- amt will be updated after loop
                                L_location,
                                L_rec.loc_type,
                                L_qty,
                                L_amt_prim) = FALSE then
                  return FALSE;
               end if;
            END LOOP;
            L_temp_qty := 0;
         END LOOP;
         ---
         -- Lock the ALC records.
         ---
         L_table := 'ALC_HEAD';
         SQL_LIB.SET_MARK('OPEN','C_LOCK_ALC_HEAD','ALC_HEAD',NULL);
         open C_LOCK_ALC_HEAD;
         SQL_LIB.SET_MARK('CLOSE','C_LOCK_ALC_HEAD','ALC_HEAD',NULL);
         close C_LOCK_ALC_HEAD;
         ---
         SQL_LIB.SET_MARK('UPDATE',NULL,'ALC_HEAD',NULL);
         update alc_head a
            set a.alc_qty = (select SUM(l.qty)
                               from alc_comp_loc l
                              where l.order_no = a.order_no
                                and l.seq_no   = a.seq_no
                                and l.comp_id  = I_comp_id)
          where a.order_no       = L_order_no
            and a.obligation_key = I_obligation_key;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            to_char(I_obligation_key),
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ALLOC_PO;
-------------------------------------------------------------------------------
FUNCTION ALLOC_COMP(O_error_message     IN OUT VARCHAR2,
                    I_obligation_key    IN     OBLIGATION.OBLIGATION_KEY%TYPE,
                    I_obligation_level  IN     OBLIGATION.OBLIGATION_LEVEL%TYPE,
                    I_key_value_1       IN     OBLIGATION.KEY_VALUE_1%TYPE,
                    I_key_value_2       IN     OBLIGATION.KEY_VALUE_2%TYPE,
                    I_key_value_3       IN     OBLIGATION.KEY_VALUE_3%TYPE,
                    I_key_value_4       IN     OBLIGATION.KEY_VALUE_4%TYPE,
                    I_key_value_5       IN     OBLIGATION.KEY_VALUE_5%TYPE,
                    I_key_value_6       IN     OBLIGATION.KEY_VALUE_6%TYPE,
                    I_comp_id           IN     ELC_COMP.COMP_ID%TYPE,
                    I_alloc_basis_uom   IN     UOM_CLASS.UOM%TYPE,
                    I_qty               IN     OBLIGATION_COMP.QTY%TYPE,
                    I_amt_obl           IN     OBLIGATION_COMP.AMT%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64)              := 'ALC_ALLOC_SQL.ALLOC_COMP';
   L_amt_prim           OBLIGATION_COMP.AMT%TYPE;
   L_uom_class          UOM_CLASS.UOM_CLASS%TYPE;
   L_currency_prim      CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_prim CURRENCY_RATES.EXCHANGE_RATE%TYPE;

   cursor C_GET_CURR is
      select currency_code,
             exchange_rate
        from obligation
       where obligation_key = I_obligation_key;

BEGIN
   ---
   -- Get the Obligation's currency and exchange rate.
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_CURR','OBLIGATION','Obligation Key: '||to_char(I_obligation_key));
   open C_GET_CURR;
   SQL_LIB.SET_MARK('FETCH','C_GET_CURR','OBLIGATION','Obligation Key: '||to_char(I_obligation_key));
   fetch C_GET_CURR into LP_currency_obl,
                         LP_exchange_rate_obl;
   SQL_LIB.SET_MARK('CLOSE','C_GET_CURR','OBLIGATION','Obligation Key: '||to_char(I_obligation_key));
   close C_GET_CURR;
   ---
   if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                       L_currency_prim) = FALSE then
      return FALSE;
   end if;
   ---
   if CURRENCY_SQL.GET_RATE(O_error_message,
                            L_exchange_rate_prim,
                            L_currency_prim,
                            NULL,
                            NULL) = FALSE then
      return FALSE;
   end if;
   ---
   -- Convert the obligation amount from obligation currency to primary currency.
   ---
   if CURRENCY_SQL.CONVERT(O_error_message,
                           I_amt_obl,
                           LP_currency_obl,
                           L_currency_prim,  -- primary currency
                           L_amt_prim,
                           'N',
                           NULL,
                           NULL,
                           LP_exchange_rate_obl,
                           L_exchange_rate_prim) = FALSE then
      return FALSE;
   end if;
   ---
   if I_obligation_level = 'PO' then
      if ALLOC_PO(O_error_message,
                  I_obligation_key,
                  I_obligation_level,
                  I_key_value_1,
                  I_comp_id,
                  I_alloc_basis_uom,
                  L_uom_class,
                  I_qty,
                  L_amt_prim) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'POIT' then
      if ALLOC_PO_ITEM(O_error_message,
                       I_obligation_key,
                       I_obligation_level,
                       I_key_value_1,
                       I_key_value_2,
                       I_comp_id,
                       I_alloc_basis_uom,
                       I_qty,
                       L_amt_prim,
                       NULL,
                       NULL,
                       NULL,
                       NULL) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'TRCO' then
      if CO_ALLOC_SQL.ALLOC_CONTAINER(O_error_message,
                                      I_obligation_key,
                                      I_obligation_level,
                                      I_key_value_1,
                                      I_key_value_2,
                                      I_key_value_3,
                                      to_date(I_key_value_4, 'DD-MON-RR'),
                                      I_comp_id,
                                      I_alloc_basis_uom,
                                      I_qty,
                                      L_amt_prim) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level in ('TRCP','TRBP') then
      if TRAN_ALLOC_SQL.ALLOC_PO_ITEM(O_error_message,
                                      I_obligation_key,
                                      I_obligation_level,
                                      I_key_value_2,
                                      I_key_value_3,
                                      to_date(I_key_value_4, 'DD-MON-RR'),
                                      to_number(I_key_value_5),
                                      I_key_value_6,
                                      I_comp_id,
                                      I_alloc_basis_uom,
                                      I_qty,
                                      L_amt_prim) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'TRBL' then
      if BL_ALLOC_SQL.ALLOC_BL_AWB(O_error_message,
                                   I_obligation_key,
                                   I_obligation_level,
                                   I_key_value_1,
                                   I_key_value_2,
                                   I_key_value_3,
                                   to_date(I_key_value_4, 'DD-MON-RR'),
                                   I_comp_id,
                                   I_alloc_basis_uom,
                                   I_qty,
                                   L_amt_prim) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'TRVV' then
      if VVE_ALLOC_SQL.ALLOC_VVE(O_error_message,
                                 I_obligation_key,
                                 I_obligation_level,
                                 I_key_value_1,
                                 I_key_value_2,
                                 to_date(I_key_value_3, 'DD-MON-RR'),
                                 I_comp_id,
                                 I_alloc_basis_uom,
                                 I_qty,
                                 L_amt_prim) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'TRVP' then
      if TRAN_ALLOC_SQL.ALLOC_PO_ITEM(O_error_message,
                                      I_obligation_key,
                                      I_obligation_level,
                                      I_key_value_1,
                                      I_key_value_2,
                                      to_date(I_key_value_3, 'DD-MON-RR'),
                                      to_number(I_key_value_4),
                                      I_key_value_5,
                                      I_comp_id,
                                      I_alloc_basis_uom,
                                      I_qty,
                                      L_amt_prim) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'CUST' then
      if CE_ALLOC_SQL.ALLOC_CE(O_error_message,
                               I_obligation_key,
                               I_obligation_level,
                               I_key_value_1,
                               I_comp_id,
                               I_alloc_basis_uom,
                               I_qty,
                               L_amt_prim) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'TRCPO' then
      if CO_ALLOC_SQL.ALLOC_CONTAINER(O_error_message,
                                      I_obligation_key,
                                      I_obligation_level,
                                      I_key_value_1,
                                      I_key_value_2,
                                      I_key_value_3,
                                      TO_DATE(I_key_value_4, 'DD-MON-RR'),
                                      I_comp_id,
                                      I_alloc_basis_uom,
                                      I_qty,
                                      L_amt_prim,
                                      I_key_value_5) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'TRBLP' then
      if BL_ALLOC_SQL.ALLOC_BL_AWB(O_error_message,
                                   I_obligation_key,
                                   I_obligation_level,
                                   I_key_value_1,
                                   I_key_value_2,
                                   I_key_value_3,
                                   TO_DATE(I_key_value_4, 'DD-MON-RR'),
                                   I_comp_id,
                                   I_alloc_basis_uom,
                                   I_qty,
                                   L_amt_prim,
                                   I_key_value_5) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'TRVVEP' then
      if VVE_ALLOC_SQL.ALLOC_VVE(O_error_message,
                                 I_obligation_key,
                                 I_obligation_level,
                                 I_key_value_1,
                                 I_key_value_2,
                                 TO_DATE(I_key_value_3, 'DD-MON-RR'),
                                 I_comp_id,
                                 I_alloc_basis_uom,
                                 I_qty,
                                 L_amt_prim,
                                 I_key_value_4) = FALSE then
         return FALSE;
      end if;
   elsif I_obligation_level = 'POT' then
      if VVE_ALLOC_SQL.ALLOC_PO_VVE(O_error_message,
                                    I_obligation_key,
                                    I_obligation_level,
                                    I_key_value_1,
                                    I_comp_id,
                                    I_alloc_basis_uom,
                                    I_qty,
                                    L_amt_prim) = FALSE then
         return FALSE;
      end if;
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
END ALLOC_COMP;
-------------------------------------------------------------------------------
FUNCTION ALLOC_ALL_PO_OBL(O_error_message IN OUT VARCHAR2,
                          I_order_no      IN     ORDHEAD.ORDER_NO%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(64) := 'ALC_ALLOC_SQL.ALLOC_ALL_PO_OBL';

   cursor C_GET_OBLIGATIONS is
      select obligation_key,
             obligation_level,
             key_value_2
        from obligation
       where obligation_level in ('PO','POIT')
         and key_value_1       = to_char(I_order_no);

BEGIN
   FOR C_rec in C_GET_OBLIGATIONS LOOP
      if ALLOC_ALL_OBL_COMPS(O_error_message,
                             C_rec.obligation_key,
                             C_rec.obligation_level,
                             to_char(I_order_no),
                             C_rec.key_value_2,
                             NULL,
                             NULL,
                             NULL,
                             NULL) = FALSE then
         return FALSE;
      end if;
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
END ALLOC_ALL_PO_OBL;
-------------------------------------------------------------------------------
FUNCTION ALLOC_ALL_OBL_COMPS(O_error_message      IN OUT   VARCHAR2,
                             I_obligation_key     IN       OBLIGATION.OBLIGATION_KEY%TYPE,
                             I_obligation_level   IN       OBLIGATION.OBLIGATION_LEVEL%TYPE,
                             I_key_value_1        IN       OBLIGATION.KEY_VALUE_1%TYPE,
                             I_key_value_2        IN       OBLIGATION.KEY_VALUE_2%TYPE,
                             I_key_value_3        IN       OBLIGATION.KEY_VALUE_3%TYPE,
                             I_key_value_4        IN       OBLIGATION.KEY_VALUE_4%TYPE,
                             I_key_value_5        IN       OBLIGATION.KEY_VALUE_5%TYPE,
                             I_key_value_6        IN       OBLIGATION.KEY_VALUE_6%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(64)   := 'ALC_ALLOC_SQL.ALLOC_ALL_OBL_COMPS';


   cursor C_GET_CONT_COMPS is
      select c.comp_id,
             c.alloc_basis_uom,
             c.qty,
             c.amt
        from obligation_comp c,
             obligation o
       where o.obligation_key     = c.obligation_key
         and o.obligation_key     = I_obligation_key
         and o.obligation_level   = I_obligation_level
         and ((I_obligation_level = 'TRCO'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3
               and o.key_value_4  = I_key_value_4)
           or (I_obligation_level = 'TRCPO'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3
               and o.key_value_4  = I_key_value_4
               and o.key_value_5  = I_key_value_5)
           or (I_obligation_level = 'TRCP'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3
               and o.key_value_4  = I_key_value_4
               and o.key_value_5  = I_key_value_5
               and o.key_value_6  = I_key_value_6))
         and c.in_alc_ind         = 'Y';


   cursor C_GET_BL_COMPS is
      select c.comp_id,
             c.alloc_basis_uom,
             c.qty,
             c.amt
        from obligation_comp c,
             obligation o
       where o.obligation_key     = c.obligation_key
         and o.obligation_key     = I_obligation_key
         and o.obligation_level   = I_obligation_level
         and ((I_obligation_level = 'TRBL'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3
               and o.key_value_4  = I_key_value_4)
           or (I_obligation_level = 'TRBLP'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3
               and o.key_value_4  = I_key_value_4
               and o.key_value_5  = I_key_value_5)
           or (I_obligation_level = 'TRBP'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3
               and o.key_value_4  = I_key_value_4
               and o.key_value_5  = I_key_value_5
               and o.key_value_6  = I_key_value_6))
         and c.in_alc_ind         = 'Y';


   cursor C_GET_VVE_COMPS is
      select c.comp_id,
             c.alloc_basis_uom,
             c.qty,
             c.amt
        from obligation_comp c,
             obligation o
       where o.obligation_key     = c.obligation_key
         and o.obligation_key     = I_obligation_key
         and o.obligation_level   = I_obligation_level
         and ((I_obligation_level = 'TRVV'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3)
           or (I_obligation_level = 'TRVVEP'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3
               and o.key_value_4  = I_key_value_4)
           or (I_obligation_level = 'TRVP'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2
               and o.key_value_3  = I_key_value_3
               and o.key_value_4  = I_key_value_4
               and o.key_value_5  = I_key_value_5))
         and c.in_alc_ind         = 'Y';

   cursor C_GET_CE_COMPS is
      select c.comp_id,
             c.alloc_basis_uom,
             c.qty,
             c.amt
        from obligation_comp c,
             obligation o
       where o.obligation_key     = c.obligation_key
         and o.obligation_key     = I_obligation_key
         and o.obligation_level   = I_obligation_level
         and I_obligation_level   = 'CUST'
         and o.key_value_1        = I_key_value_1
         and c.in_alc_ind         = 'Y';


   cursor C_GET_PO_COMPS is
      select c.comp_id,
             c.alloc_basis_uom,
             c.qty,
             c.amt
        from obligation_comp c,
             obligation o
       where o.obligation_key     = c.obligation_key
         and o.obligation_key     = I_obligation_key
         and o.obligation_level   = I_obligation_level
         and ((I_obligation_level in ('PO', 'POT')
               and o.key_value_1  = I_key_value_1)
           or (I_obligation_level = 'POIT'
               and o.key_value_1  = I_key_value_1
               and o.key_value_2  = I_key_value_2))
         and c.in_alc_ind         = 'Y';

BEGIN

   if I_obligation_level not in ('PO','POIT','POT') then

      ---
      -- If an Obligation has already been allocated to ALC, need
      -- to delete the associated ALC records and errors and
      -- re-allocate the Obligation using the new information.
      ---
      if OBLIGATION_SQL.DELETE_ALC(O_error_message,
                                   I_obligation_key)= FALSE then
         return FALSE;
      end if;
      ---
      if ALC_SQL.DELETE_ERRORS(O_error_message,
                               NULL,
                               I_obligation_key,
                               NULL) = FALSE then
         return FALSE;
      end if;
   end if;
   ---

   if I_obligation_level in ('TRCO','TRCP','TRCPO') then
      FOR C_rec in C_GET_CONT_COMPS LOOP
         if ALLOC_COMP(O_error_message,
                       I_obligation_key,
                       I_obligation_level,
                       I_key_value_1,
                       I_key_value_2,
                       I_key_value_3,
                       I_key_value_4,
                       I_key_value_5,
                       I_key_value_6,
                       C_rec.comp_id,
                       C_rec.alloc_basis_uom,
                       C_rec.qty,
                       C_rec.amt) = FALSE then
            return FALSE;
         end if;
      END LOOP;

   elsif I_obligation_level in ('TRBL','TRBP','TRBLP') then
      FOR C_rec in C_GET_BL_COMPS LOOP
         if ALLOC_COMP(O_error_message,
                       I_obligation_key,
                       I_obligation_level,
                       I_key_value_1,
                       I_key_value_2,
                       I_key_value_3,
                       I_key_value_4,
                       I_key_value_5,
                       I_key_value_6,
                       C_rec.comp_id,
                       C_rec.alloc_basis_uom,
                       C_rec.qty,
                       C_rec.amt) = FALSE then
            return FALSE;
         end if;
      END LOOP;

   elsif I_obligation_level in ('TRVV','TRVP','TRVVEP') then
      FOR C_rec in C_GET_VVE_COMPS LOOP
         if ALLOC_COMP(O_error_message,
                       I_obligation_key,
                       I_obligation_level,
                       I_key_value_1,
                       I_key_value_2,
                       I_key_value_3,
                       I_key_value_4,
                       I_key_value_5,
                       I_key_value_6,
                       C_rec.comp_id,
                       C_rec.alloc_basis_uom,
                       C_rec.qty,
                       C_rec.amt) = FALSE then
            return FALSE;
         end if;
      END LOOP;
   elsif I_obligation_level = 'CUST' then
      FOR C_rec in C_GET_CE_COMPS LOOP
         if ALC_ALLOC_SQL.ALLOC_COMP(O_error_message,
                                     I_obligation_key,
                                     I_obligation_level,
                                     I_key_value_1,
                                     I_key_value_2,
                                     I_key_value_3,
                                     I_key_value_4,
                                     I_key_value_5,
                                     I_key_value_6,
                                     C_rec.comp_id,
                                     C_rec.alloc_basis_uom,
                                     C_rec.qty,
                                     C_rec.amt) = FALSE then
            return FALSE;
         end if;
      END LOOP;

   elsif I_obligation_level in ('PO','POIT','POT') then
      ---
      -- If an Obligation has already been allocated to ALC, need
      -- to delete the associated ALC records and errors and
      -- re-allocate the Obligation using the new information.
      ---
      if OBLIGATION_SQL.DELETE_ALC(O_error_message,
                                   I_obligation_key) = FALSE then
         return FALSE;
      end if;
      ---
      if ALC_SQL.DELETE_ERRORS(O_error_message,
                               to_number(I_key_value_1),
                               I_obligation_key,
                               NULL) = FALSE then
         return FALSE;
      end if;
      ---
      FOR C_rec in C_GET_PO_COMPS LOOP
         if ALLOC_COMP(O_error_message,
                       I_obligation_key,
                       I_obligation_level,
                       I_key_value_1,
                       I_key_value_2,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       C_rec.comp_id,
                       C_rec.alloc_basis_uom,
                       C_rec.qty,
                       C_rec.amt) = FALSE then
            return FALSE;
         end if;
      END LOOP;
   end if;
   -- Reallocate assessment comps for all affected pos.
   if ALC_ALLOC_SQL.INSERT_ELC_COMPS_FOR_QUEUE(O_error_message) = FALSE then
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
END ALLOC_ALL_OBL_COMPS;
------------------------------------------------------------------------------------
END ALC_ALLOC_SQL;
/

