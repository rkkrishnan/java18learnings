CREATE OR REPLACE PACKAGE BODY ELC_CALC_SQL AS
--------------------------------------------------------------------------------------
FUNCTION CALC_COMP(O_error_message     IN OUT VARCHAR2,
                   I_calc_type         IN     VARCHAR2,
                   I_item              IN     ITEM_MASTER.ITEM%TYPE,
                   I_supplier          IN     SUPS.SUPPLIER%TYPE,
                   I_item_exp_type     IN     ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                   I_item_exp_seq      IN     ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE,
                   I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                   I_ord_seq_no        IN     ORDLOC_EXP.SEQ_NO%TYPE,
                   I_pack_item         IN     ORDLOC_EXP.PACK_ITEM%TYPE,
                   I_zone_id           IN     COST_ZONE.ZONE_ID%TYPE,
                   I_hts               IN     HTS.HTS%TYPE,
                   I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                   I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                   I_effect_from       IN     HTS.EFFECT_FROM%TYPE,
                   I_effect_to         IN     HTS.EFFECT_TO%TYPE)
   RETURN BOOLEAN IS

   -- if I_calc_type is 'IE' then the function will calculate Item Expenses
   --                   'IA' Item Assessments
   --                   'PE' Purchase Order Expenses
   --                   'PA' Purchase Order Assessments

   L_program            VARCHAR2(62)             := 'ELC_CALC_SQL.CALC_COMP';

BEGIN
   if CALC_COMP(O_error_message,
                I_calc_type,
                I_item,
                I_supplier,
                I_item_exp_type,
                I_item_exp_seq,
                I_order_no,
                I_ord_seq_no,
                I_pack_item,
                I_zone_id,
                NULL,
                I_hts,
                I_import_country_id,
                I_origin_country_id,
                I_effect_from,
                I_effect_to) = FALSE then
      return FALSE;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CALC_COMP;
----------------------------------------------------------------------------------------
FUNCTION CALC_COMP(O_error_message     IN OUT VARCHAR2,
                   I_calc_type         IN     VARCHAR2,
                   I_item              IN     ITEM_MASTER.ITEM%TYPE,
                   I_supplier          IN     SUPS.SUPPLIER%TYPE,
                   I_item_exp_type     IN     ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                   I_item_exp_seq      IN     ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE,
                   I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                   I_ord_seq_no        IN     ORDLOC_EXP.SEQ_NO%TYPE,
                   I_pack_item         IN     ORDLOC_EXP.PACK_ITEM%TYPE,
                   I_zone_id           IN     COST_ZONE.ZONE_ID%TYPE,
                   I_location          IN     ORDLOC.LOCATION%TYPE,
                   I_hts               IN     HTS.HTS%TYPE,
                   I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                   I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                   I_effect_from       IN     HTS.EFFECT_FROM%TYPE,
                   I_effect_to         IN     HTS.EFFECT_TO%TYPE)
   RETURN BOOLEAN IS

   -- if I_calc_type is 'IE' then the function will calculate Item Expenses
   --                   'IA' Item Assessments
   --                   'PE' Purchase Order Expenses
   --                   'PA' Purchase Order Assessments

   L_program            VARCHAR2(62) := 'ELC_CALC_SQL.CALC_COMP';
   L_est_value          ITEM_EXP_DETAIL.EST_EXP_VALUE%TYPE;

   cursor C_GET_ITEM_EXP is
      select it.comp_id,
             elc.comp_level,
             it.item_exp_type,
             it.item_exp_seq,
             it.supplier,
             ih.origin_country_id
        from item_exp_detail it,
             item_exp_head ih,
             elc_comp elc
       where it.item          = I_item
         and it.comp_id       = elc.comp_id
         and it.supplier      = NVL(I_supplier, it.supplier)
         and it.item_exp_type = NVL(I_item_exp_type, it.item_exp_type)
         and it.item_exp_seq  = NVL(I_item_exp_seq, it.item_exp_seq)
         and it.item          = ih.item
         and it.supplier      = ih.supplier
         and it.item_exp_type = ih.item_exp_type
         and it.item_exp_seq  = ih.item_exp_seq
         --09-Nov-2011 Tesco HSC/Usha Patil        PrfNBS023365 Begin
         and ih.base_exp_ind  = 'Y'
         --09-Nov-2011 Tesco HSC/Usha Patil        PrfNBS023365 End
         and ((ih.origin_country_id = nvl(I_origin_country_id, ih.origin_country_id)
               and ih.origin_country_id is not NULL)
              or (ih.origin_country_id is NULL))
       order by 2;

   cursor C_GET_ITEM_ASSESS is
      select it.comp_id,
             elc.comp_level,
             it.hts,
             it.import_country_id,
             it.origin_country_id,
             it.effect_from,
             it.effect_to
        from item_hts_assess it,
             elc_comp elc
       where it.item              = I_item
         and it.comp_id           = elc.comp_id
         and it.hts               = NVL(I_hts, it.hts)
         and it.import_country_id = NVL(I_import_country_id, it.import_country_id)
         and it.origin_country_id = NVL(I_origin_country_id, it.origin_country_id)
         and it.effect_from       = NVL(I_effect_from, it.effect_from)
         and it.effect_to         = NVL(I_effect_to, it.effect_to)
       order by 2;

   -- This holds the results of both the C_GET_PO_EXP_ALL_LOCS and C_GET_PO_EXP cursors.
   TYPE po_exp_record IS RECORD(comp_id ORDLOC_EXP.COMP_ID%TYPE,
                                comp_level ELC_COMP.COMP_LEVEL%TYPE,
                                item ORDLOC_EXP.ITEM%TYPE,
                                pack_item ORDLOC_EXP.PACK_ITEM%TYPE,
                                seq_no ORDLOC_EXP.SEQ_NO%TYPE,
                                location ORDLOC_EXP.LOCATION%TYPE,
                                calc_basis elc_comp.calc_basis%TYPE,
                                cvb_code ordloc_exp.cvb_code%TYPE,
                                comp_rate ordloc_exp.comp_rate%TYPE,
                                exchange_rate ordloc_exp.exchange_rate%TYPE,
                                cost_basis ordloc_exp.cost_basis%TYPE,
                                comp_currency ordloc_exp.comp_currency%TYPE,
                                per_count ordloc_exp.per_count%TYPE,
                                per_count_uom ordloc_exp.per_count_uom%TYPE);

   TYPE po_exp_table IS TABLE OF po_exp_record INDEX BY BINARY_INTEGER;
   L_po_exp po_exp_table;

   -- The purpose of this cursor is to avoid the expensive logic found in the
   -- C_GET_PO_EXP cursor, which handles the scenarios where either the I_zone_id
   -- or I_location variable is NULL.  An IF statement was added below to only call
   -- the C_GET_PO_EXP_LOC cursor when the Zone Id is input as NULL, and the input
   -- Location is not NULL.  This allows the expensive Zone/Location OR statements
   -- along with the COST_ZONE_GROUP_LOC and ITEM_MASTER sub-queries to be avoided.
   cursor C_GET_PO_EXP_LOC is
      select ord.comp_id,
             elc.comp_level,
             ord.item,
             ord.pack_item,
             ord.seq_no,
             ord.location,
             elc.calc_basis,
             ord.cvb_code,
             ord.comp_rate,
             ord.exchange_rate,
             ord.cost_basis,
             ord.comp_currency,
             ord.per_count,
             ord.per_count_uom
        from ordloc_exp ord,
             elc_comp elc
       where ord.order_no = I_order_no
         and ord.item = NVL(I_item, ord.item)
         and ((ord.pack_item = NVL(I_pack_item, ord.pack_item))
              or (ord.pack_item is NULL and I_pack_item is NULL))
         and ord.comp_id = elc.comp_id
         and ord.location = I_location
       order by 2;

   cursor C_GET_PO_EXP is
      select ord.comp_id,
             elc.comp_level,
             ord.item,
             ord.pack_item,
             ord.seq_no,
             ord.location,
             elc.calc_basis,
             ord.cvb_code,
             ord.comp_rate,
             ord.exchange_rate,
             ord.cost_basis,
             ord.comp_currency,
             ord.per_count,
             ord.per_count_uom
        from ordloc_exp ord,
             elc_comp elc
       where ord.order_no    = I_order_no
         and ord.item        = NVL(I_item, ord.item)
         and ((ord.pack_item = NVL(I_pack_item, ord.pack_item))
              or (ord.pack_item is NULL and I_pack_item is NULL))
         and ord.seq_no      = NVL(I_ord_seq_no, ord.seq_no)
         and ((ord.location  = NVL(I_location, ord.location)
               and I_zone_id is NULL)
             or (I_zone_id   is not NULL
                 and ord.location in (select c.location
                                        from cost_zone_group_loc c
                                       where c.zone_id       = I_zone_id
                                         and c.zone_group_id = (select i.cost_zone_group_id
                                                                  from item_master i
                                                                 where i.item = NVL(ord.pack_item, ord.item)))))
         and ord.comp_id     = elc.comp_id
       order by 2;

   cursor C_GET_PO_ASSESS is
      select ord.comp_id,
             elc.comp_level,
             oh.item,
             oh.pack_item,
             ord.seq_no,
            oh.hts,
             oh.import_country_id,
             oh.effect_from,
             oh.effect_to
        from ordsku_hts_assess ord,
             ordsku_hts oh,
             ordsku os,
             elc_comp elc
       where ord.order_no         = I_order_no
         and ord.order_no         = os.order_no
         and ord.order_no         = oh.order_no
         and ord.seq_no           = oh.seq_no
         and ((oh.item            = os.item)
              or (oh.pack_item    = os.item))
         and ord.seq_no           = NVL(I_ord_seq_no, ord.seq_no)
         and oh.item              = NVL(I_item, oh.item)
         and ((oh.pack_item = NVL(I_pack_item, oh.pack_item))
              or (oh.pack_item is NULL and I_pack_item is NULL))
         and oh.hts               = NVL(I_hts, oh.hts)
         and oh.import_country_id = NVL(I_import_country_id, oh.import_country_id)
         and oh.effect_from       = NVL(I_effect_from, oh.effect_from)
         and oh.effect_to         = NVL(I_effect_to, oh.effect_to)
         and ord.comp_id          = elc.comp_id
       order by 2;

BEGIN
   ---
   -- Expenses and assessments will need to calculated at different times.
   -- For example, in some cases, expenses will need to be calculated for
   -- an entire order, and at other times, for a particular item on the
   -- order.  The following cursors will loop through all of the
   -- appropriate components in the order of their Computaion Level.  Components
   -- with a Computation Level of 1 will be calculated first (99 will be last).
   ---
   if I_calc_type = 'IE' then
      -- The estimated values must first be cleared out before calculating.
      update item_exp_detail it
         set est_exp_value = 0,
             last_update_datetime = sysdate,
             last_update_id = user
       where it.item          = I_item
         and it.supplier      = NVL(I_supplier, it.supplier)
         and it.item_exp_type = NVL(I_item_exp_type, it.item_exp_type)
         and it.item_exp_seq  = NVL(I_item_exp_seq, it.item_exp_seq)
         and it.item_exp_seq in (select ih.item_exp_seq
                                from item_exp_head ih
                               where it.item          = ih.item
                                 and it.supplier      = ih.supplier
                                 and it.item_exp_type = ih.item_exp_type
                                 and ih.item          = I_item
                                 and (I_supplier is NULL or
                                      ih.supplier     = I_supplier)
                                 and (I_item_exp_type is NULL or
                                      ih.item_exp_type = I_item_exp_type)
                                 and (I_item_exp_seq is NULL or
                                      ih.item_exp_seq  = I_item_exp_seq)
                                 and ((ih.origin_country_id = nvl(I_origin_country_id, ih.origin_country_id)
                                       and ih.origin_country_id is not NULL)
                                      or (ih.origin_country_id is NULL)));
      ---
      SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_EXP','ITEM_EXP_DETAIL',NULL);
      FOR C_rec in C_GET_ITEM_EXP LOOP
         ---
         if ELC_ITEM_SQL.RECALC_COMP(O_error_message,
                                     L_est_value,
                                     'D',         -- Passing a 'D' for 'Component Details'
                                     C_rec.comp_id,
                                     I_calc_type,
                                     I_item,
                                     C_rec.supplier,
                                     C_rec.item_exp_type,
                                     C_rec.item_exp_seq,
                                     NULL,
                                     NULL,
                                     C_rec.origin_country_id,
                                     NULL,
                                     NULL) = FALSE then
            return FALSE;
         end if;
         ---
         -- Update the table with the calculated value of the component
         ---
         update item_exp_detail
            set est_exp_value        = L_est_value,
                last_update_datetime = sysdate,
                last_update_id       = user
          where item          = I_item
            and supplier      = C_rec.supplier
            and item_exp_type = C_rec.item_exp_type
            and item_exp_seq  = C_rec.item_exp_seq
            and comp_id       = C_rec.comp_id;
         ---
         if ELC_ITEM_SQL.RECALC_COMP(O_error_message,
                                     L_est_value,
                                     'F',         -- Passing a 'F' for 'Nomination Flags'
                                     C_rec.comp_id,
                                     I_calc_type,
                                     I_item,
                                     C_rec.supplier,
                                     C_rec.item_exp_type,
                                     C_rec.item_exp_seq,
                                     NULL,
                                     NULL,
                                     C_rec.origin_country_id,
                                     NULL,
                                     NULL) = FALSE then
            return FALSE;
         end if;
         ---
         -- Update the table by adding the value of the Component Flags
         -- to the components base value.
         ---
         update item_exp_detail
            set est_exp_value        = (est_exp_value + L_est_value),
                last_update_datetime = sysdate,
                last_update_id       = user
          where item                 = I_item
            and supplier             = C_rec.supplier
            and item_exp_type        = C_rec.item_exp_type
            and item_exp_seq         = C_rec.item_exp_seq
            and comp_id              = C_rec.comp_id;
      END LOOP;
   end if;
   ---
   if I_calc_type = 'IA' then
      -- The estimated values must first be cleared out before calculating.
      update item_hts_assess
         set est_assess_value     = 0,
             last_update_datetime = sysdate,
             last_update_id       = user
       where item                 = I_item
         and hts                  = NVL(I_hts, hts)
         and import_country_id    = NVL(I_import_country_id, import_country_id)
         and origin_country_id    = NVL(I_origin_country_id, origin_country_id)
         and effect_from          = NVL(I_effect_from, effect_from)
         and effect_to            = NVL(I_effect_to, effect_to);
      ---
      SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_ASSESS','ITEM_HTS_ASSESS',NULL);
      FOR C_rec in C_GET_ITEM_ASSESS LOOP
         ---
         -- Since HTS codes and Tariff Treatments will
         -- become invalid over time, the best rates
         -- need to be found each time we recalculate.
         ---
         if UPDATE_TARIFF_RATES(O_error_message,
                                I_calc_type,
                                NULL,
                                NULL,
                                I_item,
                                NULL,
                                I_supplier,
                                C_rec.hts,
                                C_rec.import_country_id,
                                C_rec.origin_country_id,
                                C_rec.effect_from,
                                C_rec.effect_to,
                                C_rec.comp_id) = FALSE then
            return FALSE;
         end if;
         ---
         if ELC_ITEM_SQL.RECALC_COMP(O_error_message,
                                     L_est_value,
                                     'D',          -- Passing a 'D' for 'Component Details'
                                     C_rec.comp_id,
                                     I_calc_type,
                                     I_item,
                                     I_supplier,
                                     NULL,
                                     NULL,
                                     C_rec.hts,
                                     C_rec.import_country_id,
                                     C_rec.origin_country_id,
                                     C_rec.effect_from,
                                     C_rec.effect_to) = FALSE then
            return FALSE;
         end if;
         ---
         -- Update the table with the calculated value of the component
         ---
         update item_hts_assess
            set est_assess_value     = L_est_value,
                last_update_datetime = sysdate,
                last_update_id       = user
          where item                 = I_item
            and hts                  = C_rec.hts
            and import_country_id    = C_rec.import_country_id
            and origin_country_id    = C_rec.origin_country_id
            and effect_from          = C_rec.effect_from
            and effect_to            = C_rec.effect_to
            and comp_id              = C_rec.comp_id;
         ---
         if ELC_ITEM_SQL.RECALC_COMP(O_error_message,
                                     L_est_value,
                                     'F',        -- Passing a 'F' for 'Nomination Flags'
                                     C_rec.comp_id,
                                     I_calc_type,
                                     I_item,
                                     I_supplier,
                                     NULL,
                                     NULL,
                                     C_rec.hts,
                                     C_rec.import_country_id,
                                     C_rec.origin_country_id,
                                     C_rec.effect_from,
                                     C_rec.effect_to) = FALSE then
            return FALSE;
         end if;
         ---
         -- Update the table by adding the value of the Component Flags
         -- to the components base value.
         ---
         update item_hts_assess
            set est_assess_value  = (est_assess_value + L_est_value),
                last_update_datetime = sysdate,
                last_update_id = user
          where item              = I_item
            and hts               = C_rec.hts
            and import_country_id = C_rec.import_country_id
            and origin_country_id = C_rec.origin_country_id
            and effect_from       = C_rec.effect_from
            and effect_to         = C_rec.effect_to
            and comp_id           = C_rec.comp_id;
      END LOOP;
   end if;
   ---
   if I_calc_type = 'PE' then
      ---
      if I_order_no IS NOT NULL and
         I_location IS NOT NULL and
         I_zone_id IS NULL and
         I_ord_seq_no IS NULL then

         -- The estimated values must first be cleared out before calculating.
         update ordloc_exp ord
            set est_exp_value = 0
          where ord.order_no    = I_order_no
            and ord.item        = NVL(I_item, ord.item)
            and ((ord.pack_item = NVL(I_pack_item, ord.pack_item))
                 or (ord.pack_item is NULL and I_pack_item is NULL))
            and ord.location = I_location;

         SQL_LIB.SET_MARK('OPEN','C_GET_PO_EXP_LOC','ORDLOC_EXP, ELC_COMP',NULL);
         open C_GET_PO_EXP_LOC;
         SQL_LIB.SET_MARK('FETCH','C_GET_PO_EXP_LOC','ORDLOC_EXP, ELC_COMP',NULL);
         fetch C_GET_PO_EXP_LOC BULK COLLECT into L_po_exp;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PO_EXP_LOC','ORDLOC_EXP, ELC_COMP',NULL);
         close C_GET_PO_EXP_LOC;
      else
         -- The estimated values must first be cleared out before calculating.
         update ordloc_exp ord
            set est_exp_value = 0
          where ord.order_no    = I_order_no
            and ord.item        = NVL(I_item, ord.item)
            and ((ord.pack_item = NVL(I_pack_item, ord.pack_item))
                 or (ord.pack_item is NULL and I_pack_item is NULL))
            and ord.seq_no      = NVL(I_ord_seq_no, ord.seq_no)
            and ((ord.location  = NVL(I_location, ord.location)
                  and I_zone_id is NULL)
                or (I_zone_id   is not NULL
                    and ord.location in (select c.location
                                           from cost_zone_group_loc c
                                          where c.zone_id       = I_zone_id
                                            and c.zone_group_id = (select i.cost_zone_group_id
                                                                     from item_master i
                                                                    where i.item = NVL(ord.pack_item, ord.item)))));
         SQL_LIB.SET_MARK('OPEN','C_GET_PO_EXP','ORDLOC_EXP, ELC_COMP',NULL);
         open C_GET_PO_EXP;
         SQL_LIB.SET_MARK('FETCH','C_GET_PO_EXP','ORDLOC_EXP, ELC_COMP',NULL);
         fetch C_GET_PO_EXP BULK COLLECT into L_po_exp;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PO_EXP','ORDLOC_EXP, ELC_COMP',NULL);
         close C_GET_PO_EXP;
      end if;

      FOR a in 1 .. L_po_exp.COUNT LOOP

         if ELC_ORDER_SQL.RECALC_COMP(O_error_message,
                                      L_est_value,
                                      'D',           -- Passing a 'D' for 'Component Details'
                                      L_po_exp(a).comp_id,
                                      I_calc_type,
                                      L_po_exp(a).item,
                                      I_supplier,
                                      I_order_no,
                                      L_po_exp(a).seq_no,
                                      L_po_exp(a).pack_item,
                                      L_po_exp(a).location,
                                      NULL, -- hts
                                      NULL, -- import country id
                                      I_origin_country_id,
                                      NULL, -- effect from
                                      NULL, -- effect to
                                      TRUE, -- extra exp info populated
                                      L_po_exp(a).calc_basis,
                                      L_po_exp(a).cvb_code,
                                      L_po_exp(a).comp_rate,
                                      L_po_exp(a).exchange_rate,
                                      L_po_exp(a).cost_basis,
                                      L_po_exp(a).comp_currency,
                                      L_po_exp(a).per_count,
                                      L_po_exp(a).per_count_uom) = FALSE then
            return FALSE;
         end if;
         ---
         -- Update the table with the calculated value of the component
         ---
         update ordloc_exp
            set est_exp_value = L_est_value
          where order_no      = I_order_no
            and seq_no        = L_po_exp(a).seq_no;
         ---
         if ELC_ORDER_SQL.RECALC_COMP(O_error_message,
                                      L_est_value,
                                      'F',        -- Passing a 'F' for 'Nomination Flags'
                                      L_po_exp(a).comp_id,
                                      I_calc_type,
                                      L_po_exp(a).item,
                                      I_supplier,
                                      I_order_no,
                                      L_po_exp(a).seq_no,
                                      L_po_exp(a).pack_item,
                                      L_po_exp(a).location,
                                      NULL, -- hts
                                      NULL, -- import country id
                                      I_origin_country_id,
                                      NULL, -- effect from
                                      NULL, -- effect to
                                      TRUE, -- extra exp info populated
                                      L_po_exp(a).calc_basis,
                                      L_po_exp(a).cvb_code,
                                      L_po_exp(a).comp_rate,
                                      L_po_exp(a).exchange_rate,
                                      L_po_exp(a).cost_basis,
                                      L_po_exp(a).comp_currency,
                                      L_po_exp(a).per_count,
                                      L_po_exp(a).per_count_uom) = FALSE then
            return FALSE;
         end if;
         ---
         -- Update the table by adding the value of the Component Flags
         -- to the components base value.
         ---
         update ordloc_exp
            set est_exp_value = (est_exp_value + L_est_value)
          where order_no      = I_order_no
            and seq_no        = L_po_exp(a).seq_no;
      END LOOP;
   end if;
   ---
   if I_calc_type = 'PA' then
      -- The estimated values must first be cleared out before calculating.
      update ordsku_hts_assess
         set est_assess_value = 0
       where order_no         = I_order_no
         and seq_no in (select o.seq_no
                          from ordsku_hts o
                         where o.order_no          = I_order_no
                           and o.seq_no            = NVL(I_ord_seq_no, o.seq_no)
                           and o.item              = NVL(I_item, o.item)
                           and ((o.pack_item = NVL(I_pack_item, o.pack_item))
                               or (o.pack_item is NULL and I_pack_item is NULL))
                           and o.hts               = NVL(I_hts, o.hts)
                           and o.import_country_id = NVL(I_import_country_id, o.import_country_id)
                           and o.effect_from       = NVL(I_effect_from, o.effect_from)
                           and o.effect_to         = NVL(I_effect_to, o.effect_to));
      ---
      SQL_LIB.SET_MARK('FETCH','C_GET_PO_ASSESS','ORDSKU_HTS_ASSESS',NULL);
      FOR C_rec in C_GET_PO_ASSESS LOOP
         ---
         -- Since HTS codes and Tariff Treatments will
         -- become invalid over time, the best rates
         -- need to be found each time we recalculate.
         ---
         if UPDATE_TARIFF_RATES(O_error_message,
                                I_calc_type,
                                I_order_no,
                                C_rec.seq_no,
                                C_rec.item,
                                C_rec.pack_item,
                                I_supplier,
                                C_rec.hts,
                                C_rec.import_country_id,
                                I_origin_country_id,
                                C_rec.effect_from,
                                C_rec.effect_to,
                                C_rec.comp_id) = FALSE then
            return FALSE;
         end if;
         ---
         if ELC_ORDER_SQL.RECALC_COMP(O_error_message,
                                      L_est_value,
                                      'D',          -- Passing a 'D' for 'Component Details'
                                      C_rec.comp_id,
                                      I_calc_type,
                                      C_rec.item,
                                      NULL,
                                      I_order_no,
                                      C_rec.seq_no,
                                      C_rec.pack_item,
                                      NULL,
                                      C_rec.hts,
                                      C_rec.import_country_id,
                                      NULL,
                                      C_rec.effect_from,
                                      C_rec.effect_to) = FALSE then
            return FALSE;
         end if;
         ---
         -- Update the table with the calculated value of the component
         ---
         update ordsku_hts_assess
            set est_assess_value = L_est_value
          where order_no         = I_order_no
            and comp_id          = C_rec.comp_id
            and seq_no           = C_rec.seq_no;
         ---
         if ELC_ORDER_SQL.RECALC_COMP(O_error_message,
                                      L_est_value,
                                      'F',        -- Passing a 'F' for 'Nomination Flags'
                                      C_rec.comp_id,
                                      I_calc_type,
                                      C_rec.item,
                                      NULL,
                                      I_order_no,
                                      C_rec.seq_no,
                                      C_rec.pack_item,
                                      NULL,
                                      C_rec.hts,
                                      C_rec.import_country_id,
                                      NULL,
                                      C_rec.effect_from,
                                      C_rec.effect_to) = FALSE then
            return FALSE;
         end if;
         ---
         -- Update the table by adding the value of the Component Flags
         -- to the components base value.
         ---
         update ordsku_hts_assess
            set est_assess_value = (est_assess_value + L_est_value)
          where order_no         = I_order_no
            and comp_id          = C_rec.comp_id
            and seq_no           = C_rec.seq_no;
      END LOOP;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CALC_COMP;
----------------------------------------------------------------------------------------
FUNCTION UPDATE_TARIFF_RATES(O_error_message     IN OUT VARCHAR2,
                             I_calc_type         IN     VARCHAR2,
                             I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                             I_seq_no            IN     ORDSKU_HTS.SEQ_NO%TYPE,
                             I_item              IN     ITEM_MASTER.ITEM%TYPE,
                             I_pack_item         IN     ITEM_MASTER.ITEM%TYPE,
                             I_supplier          IN     SUPS.SUPPLIER%TYPE,
                             I_hts               IN     HTS.HTS%TYPE,
                             I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                             I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                             I_effect_from       IN     HTS.EFFECT_FROM%TYPE,
                             I_effect_to         IN     HTS.EFFECT_TO%TYPE,
                             I_comp_id           IN     ELC_COMP.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(62) := 'ELC_CALC_SQL.UPDATE_TARIFF_RATES';
   L_item               ITEM_MASTER.ITEM%TYPE;
   L_cvd_rate           ELC_COMP.COMP_RATE%TYPE;
   L_ad_rate            ELC_COMP.COMP_RATE%TYPE;
   L_rate               ELC_COMP.COMP_RATE%TYPE;
   L_tariff_treatment   HTS_TARIFF_TREATMENT.TARIFF_TREATMENT%TYPE;
   L_qty_1              NUMBER;
   L_qty_2              NUMBER;
   L_qty_3              NUMBER;
   L_units_1            HTS.UNITS_1%TYPE;
   L_units_2            HTS.UNITS_2%TYPE;
   L_units_3            HTS.UNITS_3%TYPE;
   L_specific_rate      HTS_TARIFF_TREATMENT.SPECIFIC_RATE%TYPE;
   L_av_rate            HTS_TARIFF_TREATMENT.AV_RATE%TYPE;
   L_other_rate         HTS_TARIFF_TREATMENT.OTHER_RATE%TYPE;
   L_cvd_case_no        HTS_CVD.CASE_NO%TYPE;
   L_ad_case_no         HTS_AD.CASE_NO%TYPE;
   L_duty_comp_code     HTS.DUTY_COMP_CODE%TYPE;
   L_origin_country_id  COUNTRY.COUNTRY_ID%TYPE;
   L_exists             BOOLEAN;
   L_tax_comp_code      HTS_TAX.TAX_COMP_CODE%TYPE;
   L_tax_av_rate        HTS_TAX.TAX_AV_RATE%TYPE;
   L_tax_specific_rate  HTS_TAX.TAX_SPECIFIC_RATE%TYPE;
   L_fee_comp_code      HTS_FEE.FEE_COMP_CODE%TYPE;
   L_fee_av_rate        HTS_FEE.FEE_AV_RATE%TYPE;
   L_fee_specific_rate  HTS_FEE.FEE_SPECIFIC_RATE%TYPE;

   cursor C_GET_CVD_RATE is
      select rate
        from hts_cvd
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and origin_country_id = L_origin_country_id
         and case_no           = L_cvd_case_no;

   cursor C_GET_AD_RATE is
      select rate
        from hts_ad
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and origin_country_id = L_origin_country_id
         and case_no           = L_ad_case_no;

   cursor C_TAX_COMP is
      select tax_specific_rate,
             tax_av_rate,
             tax_comp_code
        from hts_tax
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and ((tax_comp_code in ('1','2','4','5','C','D','7','9')
               and tax_type||tax_comp_code||'A'||I_import_country_id = I_comp_id)
              or (tax_comp_code in ('4','5','D')
                  and tax_type||tax_comp_code||'B'||I_import_country_id = I_comp_id));

   cursor C_FEE_COMP is
      select fee_specific_rate,
             fee_av_rate,
             fee_comp_code
        from hts_fee
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and ((fee_comp_code in ('1','2','4','5','C','D','7','9')
               and fee_type||fee_comp_code||'A'||I_import_country_id = I_comp_id)
             or (fee_comp_code in ('4','5','D')
                 and fee_type||fee_comp_code||'B'||I_import_country_id = I_comp_id));
BEGIN
   ---
   -- System Generated assessments (assessments that are automatically attached
   -- when an HTS code is attached to an Item or Order/Item) need to have their
   -- rates updated before calculating.
   ---
   if I_pack_item is not NULL then
      L_item := I_pack_item;
   else
      L_item := I_item;
   end if;
   ---
   if I_origin_country_id is NULL then
      if ORDER_ITEM_ATTRIB_SQL.GET_ORIGIN_COUNTRY(O_error_message,
                                                  L_exists,
                                                  L_origin_country_id,
                                                  I_order_no,
                                                  L_item) = FALSE then
         return FALSE;
      end if;
   else
      L_origin_country_id := I_origin_country_id;
   end if;
   ---
   if I_comp_id in ('DTY0A'||I_import_country_id,'DTY1A'||I_import_country_id,
                    'DTY2A'||I_import_country_id,'DTY3A'||I_import_country_id,
                    'DTY4A'||I_import_country_id,'DTY5A'||I_import_country_id,
                    'DTY6A'||I_import_country_id,'DTY7A'||I_import_country_id,
                    'DTY9A'||I_import_country_id,'DTYCA'||I_import_country_id,
                    'DTYDA'||I_import_country_id,'DTYEA'||I_import_country_id,
                    'DTY3B'||I_import_country_id,'DTY4B'||I_import_country_id,
                    'DTY5B'||I_import_country_id,'DTY6B'||I_import_country_id,
                    'DTYDB'||I_import_country_id,'DTYEB'||I_import_country_id,
                    'DTY6C'||I_import_country_id,'DTYEC'||I_import_country_id,
                    'DUTY'||I_import_country_id,'CVD'||I_import_country_id,
                    'AD'||I_import_country_id)  then
      if I_calc_type = 'IA' then
         if ITEM_HTS_SQL.GET_HTS_DETAILS(O_error_message,
                                         L_tariff_treatment,
                                         L_qty_1,
                                         L_qty_2,
                                         L_qty_3,
                                         L_units_1,
                                         L_units_2,
                                         L_units_3,
                                         L_specific_rate,
                                         L_av_rate,
                                         L_other_rate,
                                         L_cvd_case_no,
                                         L_ad_case_no,
                                         L_duty_comp_code,
                                         I_item,
                                         I_supplier,
                                         I_hts,
                                         I_import_country_id,
                                         L_origin_country_id,
                                         I_effect_from,
                                         I_effect_to) = FALSE then
            return FALSE;
           end if;
      elsif I_calc_type = 'PA' then
         if ORDER_HTS_SQL.GET_HTS_DETAILS(O_error_message,
                                          L_tariff_treatment,
                                          L_qty_1,
                                          L_qty_2,
                                          L_qty_3,
                                          L_units_1,
                                          L_units_2,
                                          L_units_3,
                                          L_specific_rate,
                                          L_av_rate,
                                          L_other_rate,
                                          L_cvd_case_no,
                                          L_ad_case_no,
                                          L_duty_comp_code,
                                          I_item,
                                          I_order_no,
                                          I_hts,
                                          I_import_country_id,
                                          L_origin_country_id,
                                          I_effect_from,
                                          I_effect_to) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      if L_cvd_case_no is not NULL then
         SQL_LIB.SET_MARK('OPEN',  'C_GET_CVD_RATE', 'HTS_CVD', NULL);
         open C_GET_CVD_RATE;
         SQL_LIB.SET_MARK('FETCH',  'C_GET_CVD_RATE', 'HTS_CVD', NULL);
         fetch C_GET_CVD_RATE into L_cvd_rate;
         SQL_LIB.SET_MARK('CLOSE',  'C_GET_CVD_RATE', 'HTS_CVD', NULL);
         close C_GET_CVD_RATE;
      end if;
      ---
      if L_ad_case_no is not NULL then
         SQL_LIB.SET_MARK('OPEN',  'C_GET_AD_RATE', 'HTS_AD', NULL);
         open C_GET_AD_RATE;
         SQL_LIB.SET_MARK('FETCH',  'C_GET_AD_RATE', 'HTS_AD', NULL);
         fetch C_GET_AD_RATE into L_ad_rate;
         SQL_LIB.SET_MARK('CLOSE',  'C_GET_AD_RATE', 'HTS_AD', NULL);
         close C_GET_AD_RATE;
      end if;
      ---
      if L_duty_comp_code in ('1','2','3','4','5','6','C','D','E') then
         L_rate := L_specific_rate;
      elsif L_duty_comp_code in ('0','7','9') then
         L_rate := L_av_rate;
      end if;
      ---
      if I_comp_id in ('DTY4B'||I_import_country_id,'DTY5B'||I_import_country_id,
                       'DTYDB'||I_import_country_id,'DTY6C'||I_import_country_id,
                       'DTYEC'||I_import_country_id) then
         L_rate := L_av_rate;
      elsif I_comp_id in ('DTY3B'||I_import_country_id,'DTY6B'||I_import_country_id,
                          'DTYEB'||I_import_country_id) then
         L_rate := L_other_rate;
      elsif I_comp_id = 'CVD'||I_import_country_id then
         L_rate := L_cvd_rate;
      elsif I_comp_id = 'AD'||I_import_country_id then
         L_rate := L_ad_rate;
      elsif I_comp_id = 'DUTY'||I_import_country_id then
         L_rate := 100;
      end if;
   else
      SQL_LIB.SET_MARK('OPEN','C_TAX_COMP', 'HTS_TAX', NULL);
      open C_TAX_COMP;
      SQL_LIB.SET_MARK('FETCH','C_TAX_COMP', 'HTS_TAX', NULL);
      fetch C_TAX_COMP into L_tax_specific_rate,
                            L_tax_av_rate,
                            L_tax_comp_code;
      SQL_LIB.SET_MARK('CLOSE','C_TAX_COMP', 'HTS_TAX', NULL);
      close C_TAX_COMP;
      ---
      if L_tax_specific_rate is NULL then
         SQL_LIB.SET_MARK('OPEN','C_FEE_COMP','HTS_FEE', NULL);
         open C_FEE_COMP;
         SQL_LIB.SET_MARK('FETCH','C_FEE_COMP','HTS_FEE', NULL);
         fetch C_FEE_COMP into L_fee_specific_rate,
                               L_fee_av_rate,
                               L_fee_comp_code;
         SQL_LIB.SET_MARK('CLOSE','C_FEE_COMP','HTS_FEE', NULL);
         close C_FEE_COMP;
         ---
         if L_fee_comp_code is not NULL then
            if L_fee_comp_code in ('1','2','4','5','C','D') then
               L_rate := L_fee_specific_rate;
            end if;
            ---
            if L_fee_comp_code in ('7','9') then
               L_rate := L_fee_av_rate;
            end if;
         end if;
      else
         if L_tax_comp_code in ('1','2','4','5','C','D') then
            L_rate := L_tax_specific_rate;
         end if;
         ---
         if L_tax_comp_code in ('7','9') then
            L_rate := L_tax_av_rate;
         end if;
      end if;
   end if;
   ---
   if (I_calc_type = 'IA' and L_rate is not NULL) then
      update item_hts_assess
         set comp_rate         = L_rate,
             last_update_datetime = sysdate,
             last_update_id = user
       where item              = I_item
         and hts               = I_hts
         and import_country_id = I_import_country_id
         and origin_country_id = L_origin_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and comp_id           = I_comp_id;
   end if;
   ---
   if (I_calc_type = 'PA' and L_rate is not NULL) then
      update ordsku_hts_assess
         set comp_rate = L_rate
       where order_no  = I_order_no
         and seq_no    = I_seq_no
         and comp_id   = I_comp_id;
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
END UPDATE_TARIFF_RATES;
----------------------------------------------------------------------------------------
FUNCTION CALC_TOTALS(O_error_message     IN OUT VARCHAR2,
                     O_total_elc         IN OUT NUMBER,
                     O_total_exp         IN OUT NUMBER,
                     O_exp_currency      IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
                     O_exchange_rate_exp IN OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                     O_total_dty         IN OUT NUMBER,
                     O_dty_currency      IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
                     I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                     I_item              IN     ITEM_MASTER.ITEM%TYPE,
                     I_comp_item         IN     ITEM_MASTER.ITEM%TYPE,
                     I_zone_id           IN     COST_ZONE.ZONE_ID%TYPE,
                     I_location          IN     ORDLOC.LOCATION%TYPE,
                     I_supplier          IN     SUPS.SUPPLIER%TYPE,
                     I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                     I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                     I_cost              IN     ORDLOC.UNIT_COST%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(62)                     := 'ELC_CALC_SQL.CALC_TOTALS';
   L_texpz_exp            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_texpz_prim           ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_texpc_exp            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_texpc_prim           ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_total_exp            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_total_dty            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_cost                 NUMBER                           := 0;
   L_temp_cost            NUMBER                           := 0;
   L_comp_item_cost       NUMBER                           := 0;
   L_tot_comp_items_cost  NUMBER                           := 0;
   L_supplier             SUPS.SUPPLIER%TYPE               := I_supplier;
   L_origin_country_id    COUNTRY.COUNTRY_ID%TYPE          := I_origin_country_id;
   L_import_country_id    COUNTRY.COUNTRY_ID%TYPE          := I_import_country_id;
   L_buyer_pack           VARCHAR2(1)                      := 'N';
   L_pack_type            ITEM_MASTER.PACK_TYPE%TYPE       := 'N';
   L_pack_ind             ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind         ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind        ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_dty_comp_id          ELC_COMP.COMP_ID%TYPE;
   L_currency_prim        CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_sup         CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_ord         CURRENCIES.CURRENCY_CODE%TYPE;
   L_ord_exchange_rate    CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_texpz_currency       CURRENCIES.CURRENCY_CODE%TYPE;
   L_texpc_currency       CURRENCIES.CURRENCY_CODE%TYPE;
   L_item                 ITEM_MASTER.ITEM%TYPE;
   L_qty                  V_PACKSKU_QTY.QTY%TYPE;
   ---

   cursor C_GET_ORD_SUPP_ORIG is
      select oh.supplier,
             os.origin_country_id,
             oh.import_country_id
        from ordhead oh,
             ordsku os
       where oh.order_no = I_order_no
         and oh.order_no = os.order_no
         and os.item     = I_item;

   cursor C_CHECK_ZONE_RECS(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item          = d.item
         and h.item          = L_item
         and h.supplier      = d.supplier
         and h.supplier      = L_supplier
         and h.item_exp_type = d.item_exp_type
         and h.item_exp_seq  = d.item_exp_seq
         and h.zone_id       = I_zone_id
         and h.item_exp_type = 'Z'
         and d.comp_id       = 'TEXPZ';

   cursor C_GET_ZONE_BASE(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item          = d.item
         and h.item          = L_item
         and h.supplier      = d.supplier
         and h.supplier      = L_supplier
         and h.item_exp_type = d.item_exp_type
         and h.item_exp_seq  = d.item_exp_seq
         and h.zone_id       = I_zone_id
         and h.item_exp_type = 'Z'
         and h.base_exp_ind  = 'Y'
         and d.comp_id       = 'TEXPZ';

   cursor C_GET_EXP_WITH_BASE_DIS(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item           = d.item
         and h.item           = L_item
         and h.supplier       = d.supplier
         and h.supplier       = L_supplier
         and h.item_exp_type  = d.item_exp_type
         and h.item_exp_seq   = d.item_exp_seq
         and h.zone_id        = I_zone_id
         and h.item_exp_type  = 'Z'
         and d.comp_id        = 'TEXPZ'
         and h.discharge_port = (select i.discharge_port
                                   from item_exp_head i
                                  where i.item          = L_item
                                    and i.supplier      = L_supplier
                                    and i.item_exp_type = 'Z'
                                    and i.base_exp_ind  = 'Y');

   cursor C_GET_ITEM_TEXPZ(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item          = d.item
         and h.item          = L_item
         and h.supplier      = d.supplier
         and h.supplier      = L_supplier
         and h.item_exp_type = d.item_exp_type
         and h.item_exp_seq  = d.item_exp_seq
         and h.item_exp_type = 'Z'
         and h.base_exp_ind  = 'Y'
         and d.comp_id       = 'TEXPZ';

   cursor C_GET_ITEM_TEXPC(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item              = d.item
         and h.item              = L_item
         and h.supplier          = d.supplier
         and h.supplier          = L_supplier
         and h.item_exp_type     = d.item_exp_type
         and h.item_exp_seq      = d.item_exp_seq
         and h.item_exp_type     = 'C'
         and h.origin_country_id = L_origin_country_id
         and h.base_exp_ind      = 'Y'
         and d.comp_id           = 'TEXPC';

   cursor C_GET_ITEM_TDTY(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(SUM(a.est_assess_value), 0)
        from item_hts_assess a,
             item_hts h
       where h.item              = L_item
         and h.item              = a.item
         and h.hts               = a.hts
         and h.import_country_id = a.import_country_id
         and h.import_country_id = L_import_country_id
         and h.origin_country_id = a.origin_country_id
         and h.origin_country_id = L_origin_country_id
         and h.effect_from       = a.effect_from
         and h.effect_to         = a.effect_to
         and a.comp_id           = L_dty_comp_id;

   cursor C_GET_ASSESS_CURR is
      select comp_currency
        from elc_comp
       where comp_id = L_dty_comp_id;

   cursor C_GET_UNIT_COST(L_item ITEM_MASTER.ITEM%TYPE) is
      select i.unit_cost,
             s.currency_code
        from item_supp_country i,
             sups s
       where i.item              = L_item
         and i.supplier          = s.supplier
         and s.supplier          = L_supplier
         and i.origin_country_id = L_origin_country_id;

   cursor C_GET_SUM_COMP_COST is
      select NVL(SUM(i.unit_cost * v.qty), 0)
        from item_supp_country i,
             v_packsku_qty v
       where i.supplier          = L_supplier
         and i.origin_country_id = L_origin_country_id
         and i.item              = v.item
         and v.pack_no           = I_item;

   cursor C_GET_ORDER_COST is
      select ol.unit_cost,
             oh.currency_code,
             oh.exchange_rate
        from ordloc ol,
             ordhead oh
       where oh.order_no = I_order_no
         and oh.order_no = ol.order_no
         and ol.item     = I_item
         and ol.location = I_location;

   cursor C_PACK_ITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = I_item;

   cursor C_GET_COMPITEM_QTY is
      select qty
        from v_packsku_qty
       where pack_no = I_item
         and item    = I_comp_item;

   cursor C_GET_PO_TEXP_NONPACK is
      select NVL(est_exp_value, 0),
             comp_currency,
             exchange_rate
        from ordloc_exp
       where order_no         = I_order_no
         and item             = I_item
         and pack_item       is NULL
         and location         = I_location
         and comp_id          = 'TEXP';

   cursor C_GET_PO_TEXP_PACK(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(est_exp_value, 0),
             comp_currency,
             exchange_rate
        from ordloc_exp
       where order_no         = I_order_no
         and pack_item        = I_item
         and item             = L_item
         and location         = I_location
         and comp_id          = 'TEXP';

   cursor C_GET_PO_TDTY(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(SUM(a.est_assess_value), 0)
        from ordsku_hts_assess a,
             ordsku_hts h
       where h.order_no          = I_order_no
         and h.order_no          = a.order_no
         and h.seq_no            = a.seq_no
         and ((L_buyer_pack      = 'N'
              and h.item         = I_item
              and h.pack_item   is NULL)
          or (L_buyer_pack       = 'Y'
              and h.pack_item    =  I_item
              and h.item         =  L_item))
         and h.import_country_id =  L_import_country_id
         and a.comp_id           =  L_dty_comp_id;

BEGIN
   O_total_exp := 0;
   O_total_dty := 0;
   O_total_elc := 0;
   ---
   if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                       L_currency_prim) = FALSE then
      return FALSE;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then

      return FALSE;
   end if;
   if(L_orderable_ind = 'N') then
       return TRUE ;
   end if;


   ---
   if L_pack_type = 'B' then
      L_buyer_pack := 'Y';
   end if;
   ---
   if (L_orderable_ind = 'Y' or L_pack_ind = 'N') then
      ---
      if I_order_no is NULL then
         if (I_supplier is NULL or I_origin_country_id is NULL) then
            if SUPP_ITEM_ATTRIB_SQL.GET_PRIMARY_SUPP_COUNTRY(O_error_message,
                                                             L_supplier,
                                                             L_origin_country_id,
                                                             I_item) = FALSE then
               return FALSE;
            end if;
         elsif I_supplier is not NULL then
            L_supplier := I_supplier;
         elsif I_origin_country_id is not NULL then
            L_origin_country_id := I_origin_country_id;
         end if;
      else  -- I_order_no is NOT NULL
         if (I_supplier is NULL or I_origin_country_id is NULL) then
            SQL_LIB.SET_MARK('OPEN','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
            open C_GET_ORD_SUPP_ORIG;
            SQL_LIB.SET_MARK('FETCH','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
            fetch C_GET_ORD_SUPP_ORIG into L_supplier,
                                           L_origin_country_id,
                                           L_import_country_id;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
            close C_GET_ORD_SUPP_ORIG;
         end if;
      end if;  -- I_order_no is NULL/not NULL
   end if;    -- L_orderable_ind = 'Y' or L_pack_ind = 'N'
   ---
   if I_import_country_id is NULL then
      if SYSTEM_OPTIONS_SQL.GET_BASE_COUNTRY(O_error_message,
                                             L_import_country_id) = FALSE then
         return FALSE;
      end if;
   else
      L_import_country_id := I_import_country_id;
   end if;
   ---
   L_dty_comp_id := 'TDTY'||L_import_country_id;
   ---
   if I_order_no is NULL then -- Need to get totals for an item.
      if (L_pack_ind = 'N' or L_pack_type = 'V') then
         if I_zone_id is not NULL then
            SQL_LIB.SET_MARK('OPEN','C_CHECK_ZONE_RECS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            open C_CHECK_ZONE_RECS(I_item);
            SQL_LIB.SET_MARK('FETCH','C_CHECK_ZONE_RECS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            fetch C_CHECK_ZONE_RECS into L_texpz_exp,
                                         L_texpz_currency;
            if C_CHECK_ZONE_RECS%FOUND then
               SQL_LIB.SET_MARK('OPEN','C_GET_ZONE_BASE','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               open C_GET_ZONE_BASE(I_item);
               SQL_LIB.SET_MARK('FETCH','C_GET_ZONE_BASE','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               fetch C_GET_ZONE_BASE into L_texpz_exp,
                                          L_texpz_currency;
               if C_GET_ZONE_BASE%NOTFOUND then
                  SQL_LIB.SET_MARK('OPEN','C_GET_EXP_WITH_BASE_DIS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                  open C_GET_EXP_WITH_BASE_DIS(I_item);
                  SQL_LIB.SET_MARK('FETCH','C_GET_EXP_WITH_BASE_DIS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                  fetch C_GET_EXP_WITH_BASE_DIS into L_texpz_exp,
                                                     L_texpz_currency;
                  SQL_LIB.SET_MARK('CLOSE','C_GET_EXP_WITH_BASE_DIS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                  close C_GET_EXP_WITH_BASE_DIS;
               end if;
               ---
               SQL_LIB.SET_MARK('CLOSE','C_GET_ZONE_BASE','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               close C_GET_ZONE_BASE;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE','C_CHECK_ZONE_RECS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            close C_CHECK_ZONE_RECS;
         else
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_TEXPZ','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            open C_GET_ITEM_TEXPZ(I_item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_TEXPZ','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            fetch C_GET_ITEM_TEXPZ into L_texpz_exp,
                                        L_texpz_currency;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_TEXPZ','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            close C_GET_ITEM_TEXPZ;
         end if;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_TEXPC','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
         open C_GET_ITEM_TEXPC(I_item);
         SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_TEXPC','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
         fetch C_GET_ITEM_TEXPC into L_texpc_exp,
                                     L_texpc_currency;
         SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_TEXPC','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
         close C_GET_ITEM_TEXPC;
         ---
         if L_texpz_currency is not NULL then
            -- Convert the Zone Level Total Expense value from
            -- expense currency to primary currency
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_texpz_exp,
                                    L_texpz_currency,
                                    L_currency_prim,
                                    L_texpz_prim,
                                    NULL,
                                    NULL,
                                    NULL) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         if L_texpc_currency is not NULL then
            -- Convert the Country Level Total Expense value from
            -- expense currency to primary currency
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_texpc_exp,
                                    L_texpc_currency,
                                    L_currency_prim,
                                    L_texpc_prim,
                                    NULL,
                                    NULL,
                                    NULL) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         O_total_exp    := NVL(L_texpz_prim, 0) + NVL(L_texpc_prim, 0);
         O_exp_currency := L_currency_prim;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_TDTY','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         open C_GET_ITEM_TDTY(I_item);
         SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_TDTY','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         fetch C_GET_ITEM_TDTY into O_total_dty;
         SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_TDTY','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         close C_GET_ITEM_TDTY;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         open C_GET_ASSESS_CURR;
         SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         fetch C_GET_ASSESS_CURR into O_dty_currency;
         SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         close C_GET_ASSESS_CURR;
         ---
         if I_cost is NULL then
            SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
            open C_GET_UNIT_COST(I_item);
            SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
            fetch C_GET_UNIT_COST into L_cost,
                                       L_currency_sup;
            if C_GET_UNIT_COST%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('NO_SUP_CTRY_UNIT_COST',
                                                     I_item,
                                                     L_supplier,
                                                     L_origin_country_id);
               SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
               close C_GET_UNIT_COST;
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
            close C_GET_UNIT_COST;
         else
            L_cost := I_cost;
            ---
            if SUPP_ATTRIB_SQL.GET_CURRENCY_CODE(O_error_message,
                                                 L_currency_sup,
                                                 L_supplier) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         -- Convert the Unit Cost from the supplier's currency
         -- to primary currency.
         ---
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_cost,
                                 L_currency_sup,
                                 L_currency_prim,
                                 L_cost,
                                 NULL,
                                 NULL,
                                 NULL) = FALSE then
            return FALSE;
         end if;
      else -- L_pack_type = 'B'(buyer pack) or L_orderable_ind = 'N'(non - orderable pack)
         if I_cost is NULL then
            L_cost := 0;
         else
            L_cost := I_cost;
         end if;

         FOR C_rec in C_PACK_ITEMS LOOP
            L_item       := C_rec.item;
            L_qty        := C_rec.qty;
            L_temp_cost  := 0;
            ---
            if L_orderable_ind = 'N' then  -- the pack is non-orderable.
               ---
               -- Because the pack is non-orderable, it will not have
               -- a supplier or origin country.  Therefore we must get
               -- the expenses and duty for each component item of the
               -- pack using the component item's supplier and origin
               -- country.
               ---
               if (I_supplier is NULL or I_origin_country_id is NULL) then
                  if SUPP_ITEM_ATTRIB_SQL.GET_PRIMARY_SUPP_COUNTRY(O_error_message,
                                                                   L_supplier,
                                                                   L_origin_country_id,
                                                                   L_item) = FALSE then
                     return FALSE;
                  end if;
               elsif I_supplier is not NULL then
                  L_supplier := I_supplier;
               elsif I_origin_country_id is not NULL then
                  L_origin_country_id := I_origin_country_id;
               end if;
            end if;
            ---
            L_texpz_exp  := 0;
            L_texpz_prim := 0;
            L_texpc_exp  := 0;
            L_texpc_prim := 0;
            L_total_dty  := 0;
            ---
            if I_zone_id is not NULL then
               SQL_LIB.SET_MARK('OPEN','C_CHECK_ZONE_RECS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               open C_CHECK_ZONE_RECS(L_item);
               SQL_LIB.SET_MARK('FETCH','C_CHECK_ZONE_RECS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               fetch C_CHECK_ZONE_RECS into L_texpz_exp,
                                            L_texpz_currency;
               if C_CHECK_ZONE_RECS%FOUND then
                  SQL_LIB.SET_MARK('OPEN','C_GET_ZONE_BASE','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                  open C_GET_ZONE_BASE(L_item);
                  SQL_LIB.SET_MARK('FETCH','C_GET_ZONE_BASE','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                  fetch C_GET_ZONE_BASE into L_texpz_exp,
                                             L_texpz_currency;
                  if C_GET_ZONE_BASE%NOTFOUND then
                     SQL_LIB.SET_MARK('OPEN','C_GET_EXP_WITH_BASE_DIS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                     open C_GET_EXP_WITH_BASE_DIS(L_item);
                     SQL_LIB.SET_MARK('FETCH','C_GET_EXP_WITH_BASE_DIS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                     fetch C_GET_EXP_WITH_BASE_DIS into L_texpz_exp,
                                                        L_texpz_currency;
                     SQL_LIB.SET_MARK('CLOSE','C_GET_EXP_WITH_BASE_DIS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                     close C_GET_EXP_WITH_BASE_DIS;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('CLOSE','C_GET_ZONE_BASE','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
                  close C_GET_ZONE_BASE;
               end if;
               ---
               SQL_LIB.SET_MARK('CLOSE','C_CHECK_ZONE_RECS','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               close C_CHECK_ZONE_RECS;
            else
               SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_TEXPZ','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               open C_GET_ITEM_TEXPZ(L_item);
               SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_TEXPZ','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               fetch C_GET_ITEM_TEXPZ into L_texpz_exp,
                                           L_texpz_currency;
               SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_TEXPZ','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
               close C_GET_ITEM_TEXPZ;
            end if;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_TEXPC','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            open C_GET_ITEM_TEXPC(L_item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_TEXPC','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            fetch C_GET_ITEM_TEXPC into L_texpc_exp,
                                        L_texpc_currency;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_TEXPC','ITEM_EXP_DETAIL, ITEM_EXP_HEAD',NULL);
            close C_GET_ITEM_TEXPC;
            ---
            if L_texpz_currency is not NULL then
               ---
               -- Convert the Zone level Total Expense from expense currency to primary currency.
               ---
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_texpz_exp,
                                       L_texpz_currency,
                                       L_currency_prim,
                                       L_texpz_prim,
                                       NULL,
                                       NULL,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            if L_texpc_currency is not NULL then
               ---
               -- Convert the Country level Total Expense from expense currency to primary currency.
               ---
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_texpc_exp,
                                       L_texpc_currency,
                                       L_currency_prim,
                                       L_texpc_prim,
                                       NULL,
                                       NULL,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            O_total_exp    := O_total_exp + ((NVL(L_texpz_prim, 0) + NVL(L_texpc_prim, 0)) * NVL(L_qty, 0));
            O_exp_currency := L_currency_prim;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_TDTY','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            open C_GET_ITEM_TDTY(L_item);
            SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_TDTY','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            fetch C_GET_ITEM_TDTY into L_total_dty;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_TDTY','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            close C_GET_ITEM_TDTY;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            open C_GET_ASSESS_CURR;
            SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            fetch C_GET_ASSESS_CURR into O_dty_currency;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            close C_GET_ASSESS_CURR;
            ---
            O_total_dty := O_total_dty + (NVL(L_total_dty, 0) * NVL(L_qty, 0));
            ---
            if I_cost is NULL then
               SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
               open C_GET_UNIT_COST(L_item);
               SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
               fetch C_GET_UNIT_COST into L_comp_item_cost,
                                          L_currency_sup;
               if C_GET_UNIT_COST%NOTFOUND then
                  O_error_message := SQL_LIB.CREATE_MSG('NO_SUP_CTRY_UNIT_COST',
                                                        L_item,
                                                        L_supplier,
                                                        L_origin_country_id);
                  SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
                  close C_GET_UNIT_COST;
                  return FALSE;
               end if;
               ---
               SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
               close C_GET_UNIT_COST;
               ---
               L_temp_cost := L_temp_cost + (L_comp_item_cost * L_qty);

            end if;
            ---
            -- Convert the Unit Cost from the supplier's currency
            -- to primary currency.
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_temp_cost,
                                    L_currency_sup,
                                    L_currency_prim,
                                    L_temp_cost,
                                    NULL,
                                    NULL,
                                    NULL) = FALSE then
               return FALSE;
            end if;
            ---
            L_cost := L_cost + L_temp_cost;
         END LOOP; -- loop through a pack's component skus
      end if; -- if L_pack_type = 'B' or L_orderable_ind = 'N'(non-orderable)/NULL(vendor pack,staple sku,fashion sku)

   else  -- If I_order_no is not NULL
      ---
      -- if buyer pack then need to get location for each component item
      -- loop through the comps of the pack get the texp and tdty
      -- sum results from fetch in loop.
      ---
      if L_buyer_pack = 'Y' then
         if I_cost is NULL then
            SQL_LIB.SET_MARK('OPEN','C_GET_ORDER_COST','ORDHEAD,ORDLOC',NULL);
            open C_GET_ORDER_COST;
            SQL_LIB.SET_MARK('FETCH','C_GET_ORDER_COST','ORDHEAD,ORDLOC',NULL);
            fetch C_GET_ORDER_COST into L_cost,
                                        L_currency_ord,
                                        L_ord_exchange_rate;
            if C_GET_ORDER_COST%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('NO_ORD_COST_FOUND',
                                                     I_order_no,
                                                     I_item,
                                                     L_supplier);
               SQL_LIB.SET_MARK('CLOSE','C_GET_ORDER_COST','ORDHEAD,ORDLOC',NULL);
               close C_GET_ORDER_COST;
               return FALSE;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE','C_GET_ORDER_COST','ORDHEAD,ORDLOC',NULL);
            close C_GET_ORDER_COST;
            ---
         else
            L_cost := I_cost;
            ---
            if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                                  L_currency_ord,
                                                  L_ord_exchange_rate,
                                                  I_order_no) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         -- Convert the Order Cost from the order's currency
         -- to primary currency.
         ---
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_cost,
                                 L_currency_ord,
                                 L_currency_prim,
                                 L_cost,
                                 NULL,
                                 NULL,
                                 NULL,
                                 L_ord_exchange_rate,
                                 NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if I_comp_item is NULL then
            FOR C_rec in C_PACK_ITEMS LOOP
               L_item      := C_rec.item;
               L_qty       := C_rec.qty;
               L_total_exp := 0;
               L_total_dty := 0;
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
               open C_GET_PO_TEXP_PACK(L_item);
               SQL_LIB.SET_MARK('FETCH','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
               fetch C_GET_PO_TEXP_PACK into L_total_exp,
                                             O_exp_currency,
                                             O_exchange_rate_exp;
               SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
               close C_GET_PO_TEXP_PACK;
               O_total_exp := O_total_exp + (NVL(L_total_exp, 0) * NVL(L_qty, 0));
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_PO_TDTY',
                                'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
               open C_GET_PO_TDTY(L_item);
               SQL_LIB.SET_MARK('FETCH','C_GET_PO_TDTY',
                                'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
               fetch C_GET_PO_TDTY into L_total_dty;
               SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TDTY',
                                'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
               close C_GET_PO_TDTY;
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_CURR',
                                'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
               open C_GET_ASSESS_CURR;
               SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_CURR',
                                'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
               fetch C_GET_ASSESS_CURR into O_dty_currency;
               SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_CURR',
                                 'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
               close C_GET_ASSESS_CURR;
               ---
               O_total_dty := O_total_dty + (NVL(L_total_dty, 0) * NVL(L_qty, 0));
            END LOOP;
            ---
         else   -- I_comp_item is not NULL
            SQL_LIB.SET_MARK('OPEN','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
            open C_GET_PO_TEXP_PACK(I_comp_item);
            SQL_LIB.SET_MARK('FETCH','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
            fetch C_GET_PO_TEXP_PACK into O_total_exp,
                                          O_exp_currency,
                                          O_exchange_rate_exp;
            SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
            close C_GET_PO_TEXP_PACK;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_PO_TDTY',
                             'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
            open C_GET_PO_TDTY(I_comp_item);
            SQL_LIB.SET_MARK('FETCH','C_GET_PO_TDTY',
                              'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
            fetch C_GET_PO_TDTY into O_total_dty;
            SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TDTY',
                              'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
            close C_GET_PO_TDTY;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_CURR',
                             'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            open C_GET_ASSESS_CURR;
            SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_CURR',
                             'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            fetch C_GET_ASSESS_CURR into O_dty_currency;
            SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_CURR',
                             'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
            close C_GET_ASSESS_CURR;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_COST',
                             'ITEM_SUPP_COUNTRY',NULL);
            open C_GET_UNIT_COST(I_comp_item);
            SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_COST',
                             'ITEM_SUPP_COUNTRY',NULL);
            fetch C_GET_UNIT_COST into L_comp_item_cost,
                                       L_currency_sup;
            if C_GET_UNIT_COST%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('NO_SUP_CTRY_UNIT_COST',
                                                     I_comp_item,
                                                     L_supplier,
                                                     L_origin_country_id);
               SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST',
                                'ITEM_SUPP_COUNTRY',NULL);
               close C_GET_UNIT_COST;
               return FALSE;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST',
                             'ITEM_SUPP_COUNTRY',NULL);
            close C_GET_UNIT_COST;
            ---
            SQL_LIB.SET_MARK('OPEN','C_GET_SUM_COMP_COST',
                             'ITEM_SUPP_COUNTRY',NULL);
            open C_GET_SUM_COMP_COST;
            SQL_LIB.SET_MARK('FETCH','C_GET_SUM_COMP_COST',
                             'ITEM_SUPP_COUNTRY',NULL);
            fetch C_GET_SUM_COMP_COST into L_tot_comp_items_cost;
            SQL_LIB.SET_MARK('CLOSE','C_GET_SUM_COMP_COST',
                             'ITEM_SUPP_COUNTRY',NULL);
            close C_GET_SUM_COMP_COST;
            ---
            if L_tot_comp_items_cost = 0 then
               L_cost := 0;
            else
               L_cost := (NVL(L_comp_item_cost, 0)
                            * NVL(L_cost, 0))/NVL(L_tot_comp_items_cost, 1);
            end if;
         end if; -- if I_comp_sku is not NULL
      else -- L_buyer_pack = 'N'
         SQL_LIB.SET_MARK('OPEN','C_GET_PO_TEXP_NONPACK','ORDLOC_EXP',NULL);
         open C_GET_PO_TEXP_NONPACK;
         SQL_LIB.SET_MARK('FETCH','C_GET_PO_TEXP_NONPACK','ORDLOC_EXP',NULL);
         fetch C_GET_PO_TEXP_NONPACK into O_total_exp,
                                          O_exp_currency,
                                          O_exchange_rate_exp;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TEXP_NONPACK','ORDLOC_EXP',NULL);
         close C_GET_PO_TEXP_NONPACK;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
         open C_GET_PO_TDTY(NULL);
         SQL_LIB.SET_MARK('FETCH','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
         fetch C_GET_PO_TDTY into O_total_dty;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
         close C_GET_PO_TDTY;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         open C_GET_ASSESS_CURR;
         SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         fetch C_GET_ASSESS_CURR into O_dty_currency;
         SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         close C_GET_ASSESS_CURR;
         ---
         if I_cost is NULL then
            SQL_LIB.SET_MARK('OPEN','C_GET_ORDER_COST','ORDHEAD,ORDLOC',NULL);
            open C_GET_ORDER_COST;
            SQL_LIB.SET_MARK('FETCH','C_GET_ORDER_COST','ORDHEAD,ORDLOC',NULL);
            fetch C_GET_ORDER_COST into L_cost,
                                        L_currency_ord,
                                        L_ord_exchange_rate;
            if C_GET_ORDER_COST%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('NO_ORD_COST_FOUND',
                                                     I_order_no,
                                                     I_item,
                                                     L_supplier);
               SQL_LIB.SET_MARK('CLOSE','C_GET_ORDER_COST','ORDHEAD,ORDLOC',NULL);
               close C_GET_ORDER_COST;
               return FALSE;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE','C_GET_ORDER_COST','ORDHEAD,ORDLOC',NULL);
            close C_GET_ORDER_COST;
         else
            L_cost := I_cost;
            ---
            if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                                  L_currency_ord,
                                                  L_ord_exchange_rate,
                                                  I_order_no) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         -- Convert the Order Cost from the order's currency
         -- to primary currency.
         ---
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_cost,
                                 L_currency_ord,
                                 L_currency_prim,
                                 L_cost,
                                 NULL,
                                 NULL,
                                 NULL,
                                 L_ord_exchange_rate,
                                 NULL) = FALSE then
            return FALSE;
         end if;
      end if; -- L_buyer_pack = 'Y'/'N'
   end if; -- I_order_no is not NULL
   ---
   if O_exp_currency is not NULL then
      ---
      -- Convert the Total Expense value from the expense currency
      -- to primary currency.
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              O_total_exp,
                              O_exp_currency,
                              L_currency_prim,
                              L_total_exp,
                              NULL,
                              NULL,
                              NULL,
                              O_exchange_rate_exp,
                              NULL) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if O_dty_currency is not NULL then
      ---
      -- Convert the Total Duty value from the import currency
      -- to primary currency.
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              O_total_dty,
                              O_dty_currency,
                              L_currency_prim,
                              L_total_dty,
                              NULL,
                              NULL,
                              NULL) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   -- Add the Total Expense value to the Total Duty value to
   -- get Total Estimated Landed Cost (Total ELC).  The value
   -- is in the Primary currency.
   ---
   O_total_elc := NVL(L_total_exp, 0) + NVL(L_total_dty, 0) + NVL(L_cost, 0);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CALC_TOTALS;
----------------------------------------------------------------------------------------
FUNCTION CALC_BACKHAUL_TOTAL(O_error_message         IN OUT VARCHAR2,
                             O_total_allowance_prim  IN OUT ORDLOC_EXP.EST_EXP_VALUE%TYPE,
                             O_total_allowance_ord   IN OUT ORDLOC_EXP.EST_EXP_VALUE%TYPE,
                             I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                             I_currency_prim         IN     CURRENCIES.CURRENCY_CODE%TYPE,
                             I_currency_ord          IN     CURRENCIES.CURRENCY_CODE%TYPE,
                             I_exchange_rate_ord     IN     CURRENCY_RATES.EXCHANGE_RATE%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(62)                     := 'ELC_CALC_SQL.CALC_BACKHAUL_TOTAL';
   L_total_exp            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_total_back_prim      ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_total_pack_back_prim ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_est_exp_value_exp    ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_est_exp_value_prim   ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_buyer_pack           VARCHAR2(1)                      := 'N';
   L_pack_type            ITEM_MASTER.PACK_TYPE%TYPE       := 'N';
   L_pack_ind             ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind         ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind        ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_currency_prim        CURRENCIES.CURRENCY_CODE%TYPE    := I_currency_prim;
   L_currency_exp         CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_exp    CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_item                 ITEM_MASTER.ITEM%TYPE;
   L_comp_item            ITEM_MASTER.ITEM%TYPE;
   L_location             ORDLOC.LOCATION%TYPE;
   L_qty                  V_PACKSKU_QTY.QTY%TYPE;
   L_qty_ordered          ORDLOC.QTY_ORDERED%TYPE;
   ---
   cursor C_GET_ITEM_LOCS is
      select item,
             location,
             qty_ordered
        from ordloc
       where order_no = I_order_no;

   cursor C_PACK_ITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

   cursor C_GET_COMPS is
      select NVL(o.est_exp_value, 0) est_exp_value,
             o.comp_currency,
             o.exchange_rate
        from ordloc_exp o,
             elc_comp e
       where o.order_no       = I_order_no
         and ((L_buyer_pack   = 'N'
               and o.item     = L_item
               and o.pack_item is NULL)
          or (L_buyer_pack    = 'Y'
              and o.pack_item = L_item
              and o.item      = L_comp_item))
         and o.location       = L_location
         and o.comp_id        = e.comp_id
         and e.exp_category   = 'B';

BEGIN
   O_total_allowance_prim := 0;
   O_total_allowance_ord  := 0;
   ---
   if I_currency_prim is NULL then
      if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                          L_currency_prim) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   FOR C_rec in C_GET_ITEM_LOCS LOOP
      L_item        := C_rec.item;
      L_location    := C_rec.location;
      L_qty_ordered := C_rec.qty_ordered;
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
      if L_pack_type = 'B' then
         L_buyer_pack := 'Y';
      end if;
      ---
      -- if buyer pack then need to get location for each component item
      -- loop through the comps of the pack get the texp and tdty
      -- sum results from fetch in loop.
      ---
      if L_buyer_pack = 'Y' then
         L_total_pack_back_prim := 0;
         ---
         FOR C_rec in C_PACK_ITEMS LOOP
            L_comp_item       := C_rec.item;
            L_qty             := C_rec.qty;
            L_total_back_prim := 0;
            ---
            FOR L_rec in C_GET_COMPS LOOP
               L_est_exp_value_exp := L_rec.est_exp_value;
               L_currency_exp      := L_rec.comp_currency;
               L_exchange_rate_exp := L_rec.exchange_rate;
               ---
               -- Convert from Expense Currency to Primary Currency.
               ---
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_est_exp_value_exp,
                                       L_currency_exp,
                                       L_currency_prim,
                                       L_est_exp_value_prim,
                                       NULL,
                                       NULL,
                                       NULL,
                                       L_exchange_rate_exp,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
               ---
               L_total_back_prim := L_total_back_prim + L_est_exp_value_prim;
            END LOOP;
            ---
            L_total_pack_back_prim := L_total_pack_back_prim + (NVL(L_total_back_prim, 0) * NVL(L_qty, 0));
         END LOOP;
      else -- L_pack_ind = 'N'
         L_total_back_prim := 0;
         ---
         FOR L_rec in C_GET_COMPS LOOP
            L_est_exp_value_exp := L_rec.est_exp_value;
            L_currency_exp      := L_rec.comp_currency;
            L_exchange_rate_exp := L_rec.exchange_rate;
            ---
            -- Convert from Expense Currency to Primary Currency.
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_est_exp_value_exp,
                                    L_currency_exp,
                                    L_currency_prim,
                                    L_est_exp_value_prim,
                                    NULL,
                                    NULL,
                                    NULL,
                                    L_exchange_rate_exp,
                                    NULL) = FALSE then
               return FALSE;
            end if;
            ---
            L_total_back_prim := L_total_back_prim + L_est_exp_value_prim;
         END LOOP;
      end if; -- L_pack_ind = 'Y'/'N'
      ---
      O_total_allowance_prim :=   O_total_allowance_prim
                                + (NVL(L_total_back_prim, 0)      * NVL(L_qty_ordered, 0))
                                + (NVL(L_total_pack_back_prim, 0) * NVL(L_qty_ordered, 0));
   END LOOP;
   ---
   if O_total_allowance_prim is not NULL then
      ---
      -- Convert the Total Expense value from the primary currency
      -- to order currency.
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              O_total_allowance_prim,
                              L_currency_prim,
                              I_currency_ord,
                              O_total_allowance_ord,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              I_exchange_rate_ord) = FALSE then
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
END CALC_BACKHAUL_TOTAL;
----------------------------------------------------------------------------------------
FUNCTION CALC_ORDER_TOTALS(O_error_message     IN OUT VARCHAR2,
                           O_total_elc         IN OUT NUMBER,
                           O_total_exp         IN OUT NUMBER,
                           O_exp_currency      IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
                           O_exchange_rate_exp IN OUT CURRENCY_RATES.EXCHANGE_RATE%TYPE,
                           O_total_dty         IN OUT NUMBER,
                           O_dty_currency      IN OUT CURRENCIES.CURRENCY_CODE%TYPE,
                           I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                           I_item              IN     ITEM_MASTER.ITEM%TYPE,
                           I_pack_ind          IN     ITEM_MASTER.PACK_IND%TYPE,
                           I_sellable_ind      IN     ITEM_MASTER.SELLABLE_IND%TYPE,
                           I_orderable_ind     IN     ITEM_MASTER.ORDERABLE_IND%TYPE,
                           I_pack_type         IN     ITEM_MASTER.PACK_TYPE%TYPE,
                           I_qty_ordered IN ORDLOC.QTY_ORDERED%TYPE,
                           I_comp_item         IN     ITEM_MASTER.ITEM%TYPE,
                           I_zone_id           IN     COST_ZONE.ZONE_ID%TYPE,
                           I_location          IN     ORDLOC.LOCATION%TYPE,
                           I_supplier          IN     SUPS.SUPPLIER%TYPE,
                           I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                           I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                           I_cost              IN     ORDLOC.UNIT_COST%TYPE)
   RETURN BOOLEAN IS

   L_program              VARCHAR2(62)                     := 'ELC_CALC_SQL.CALC_ORDER_TOTALS';
   L_texpz_exp            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_texpz_prim           ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_texpc_exp            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_texpc_prim           ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_total_exp            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_total_dty            ORDLOC_EXP.EST_EXP_VALUE%TYPE    := 0;
   L_cost                 NUMBER                           := 0;
   L_temp_cost            NUMBER                           := 0;
   L_comp_item_cost       NUMBER                           := 0;
   L_tot_comp_items_cost  NUMBER                           := 0;
   L_supplier             SUPS.SUPPLIER%TYPE               := I_supplier;
   L_origin_country_id    COUNTRY.COUNTRY_ID%TYPE          := I_origin_country_id;
   L_import_country_id    COUNTRY.COUNTRY_ID%TYPE          := I_import_country_id;
   L_buyer_pack           VARCHAR2(1)                      := 'N';
   L_pack_type            ITEM_MASTER.PACK_TYPE%TYPE       := 'N';
   L_pack_ind             ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind         ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind        ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_dty_comp_id          ELC_COMP.COMP_ID%TYPE;
   L_currency_prim        CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_sup         CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_ord         CURRENCIES.CURRENCY_CODE%TYPE;
   L_ord_exchange_rate    CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_texpz_currency       CURRENCIES.CURRENCY_CODE%TYPE;
   L_texpc_currency       CURRENCIES.CURRENCY_CODE%TYPE;
   L_item                 ITEM_MASTER.ITEM%TYPE;
   L_qty                  V_PACKSKU_QTY.QTY%TYPE;
   L_qty_ordered          ORDLOC.QTY_ORDERED%TYPE;
   ---

   cursor C_GET_ORD_SUPP_ORIG is
      select oh.supplier,
             os.origin_country_id,
             oh.import_country_id
        from ordhead oh,
             ordsku os
       where oh.order_no = I_order_no
         and oh.order_no = os.order_no
         and os.item     = I_item;

   cursor C_CHECK_ZONE_RECS(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item          = d.item
         and h.item          = L_item
         and h.supplier      = d.supplier
         and h.supplier      = L_supplier
         and h.item_exp_type = d.item_exp_type
         and h.item_exp_seq  = d.item_exp_seq
         and h.zone_id       = I_zone_id
         and h.item_exp_type = 'Z'
         and d.comp_id       = 'TEXPZ';

   cursor C_GET_ZONE_BASE(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item          = d.item
         and h.item          = L_item
         and h.supplier      = d.supplier
         and h.supplier      = L_supplier
         and h.item_exp_type = d.item_exp_type
         and h.item_exp_seq  = d.item_exp_seq
         and h.zone_id       = I_zone_id
         and h.item_exp_type = 'Z'
         and h.base_exp_ind  = 'Y'
         and d.comp_id       = 'TEXPZ';

   cursor C_GET_EXP_WITH_BASE_DIS(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item           = d.item
         and h.item           = L_item
         and h.supplier       = d.supplier
         and h.supplier       = L_supplier
         and h.item_exp_type  = d.item_exp_type
         and h.item_exp_seq   = d.item_exp_seq
         and h.zone_id        = I_zone_id
         and h.item_exp_type  = 'Z'
         and d.comp_id        = 'TEXPZ'
         and h.discharge_port = (select i.discharge_port
                                   from item_exp_head i
                                  where i.item          = L_item
                                    and i.supplier      = L_supplier
                                    and i.item_exp_type = 'Z'
                                    and i.base_exp_ind  = 'Y');

   cursor C_GET_ITEM_TEXPZ(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item          = d.item
         and h.item          = L_item
         and h.supplier      = d.supplier
         and h.supplier      = L_supplier
         and h.item_exp_type = d.item_exp_type
         and h.item_exp_seq  = d.item_exp_seq
         and h.item_exp_type = 'Z'
         and h.base_exp_ind  = 'Y'
         and d.comp_id       = 'TEXPZ';

   cursor C_GET_ITEM_TEXPC(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(d.est_exp_value, 0),
             d.comp_currency
        from item_exp_detail d,
             item_exp_head h
       where h.item              = d.item
         and h.item              = L_item
         and h.supplier          = d.supplier
         and h.supplier          = L_supplier
         and h.item_exp_type     = d.item_exp_type
         and h.item_exp_seq      = d.item_exp_seq
         and h.item_exp_type     = 'C'
         and h.origin_country_id = L_origin_country_id
         and h.base_exp_ind      = 'Y'
         and d.comp_id           = 'TEXPC';

   cursor C_GET_ITEM_TDTY(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(SUM(a.est_assess_value), 0)
        from item_hts_assess a,
             item_hts h
       where h.item              = L_item
         and h.item              = a.item
         and h.hts               = a.hts
         and h.import_country_id = a.import_country_id
         and h.import_country_id = L_import_country_id
         and h.origin_country_id = a.origin_country_id
         and h.origin_country_id = L_origin_country_id
         and h.effect_from       = a.effect_from
         and h.effect_to         = a.effect_to
         and a.comp_id           = L_dty_comp_id;

   cursor C_GET_ASSESS_CURR is
      select comp_currency
        from elc_comp
       where comp_id = L_dty_comp_id;

   cursor C_GET_UNIT_COST(L_item ITEM_MASTER.ITEM%TYPE) is
      select i.unit_cost,
             s.currency_code
        from item_supp_country i,
             sups s
       where i.item              = L_item
         and i.supplier          = s.supplier
         and s.supplier          = L_supplier
         and i.origin_country_id = L_origin_country_id;

  cursor C_GET_ORDER_QTY is
     select ol.qty_ordered
       from ordloc ol
      where ol.order_no = I_order_no
        and ol.item     = I_item
        and ol.location = I_location;

   cursor C_GET_SUM_COMP_COST is
      select NVL(SUM(i.unit_cost * v.qty), 0)
        from item_supp_country i,
             v_packsku_qty v
       where i.supplier          = L_supplier
         and i.origin_country_id = L_origin_country_id
         and i.item              = v.item
         and v.pack_no           = I_item;

   cursor C_GET_ORDER_COST is
      select ol.unit_cost,
             oh.currency_code,
             oh.exchange_rate
        from ordloc ol,
             ordhead oh
       where oh.order_no = I_order_no
         and oh.order_no = ol.order_no
         and ol.item     = I_item
         and ol.location = I_location;

   cursor C_PACK_ITEMS is
      select item,
             qty
        from v_packsku_qty
       where pack_no = I_item;

   cursor C_GET_COMPITEM_QTY is
      select qty
        from v_packsku_qty
       where pack_no = I_item
         and item    = I_comp_item;

   cursor C_GET_PO_TEXP_NONPACK is
      select NVL(est_exp_value, 0),
             comp_currency,
             exchange_rate
        from ordloc_exp
       where order_no         = I_order_no
         and item             = I_item
         and pack_item       is NULL
         and location         = I_location
         and comp_id          = 'TEXP';

   cursor C_GET_PO_TEXP_PACK(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(est_exp_value, 0),
             comp_currency,
             exchange_rate
        from ordloc_exp
       where order_no         = I_order_no
         and pack_item        = I_item
         and item             = L_item
         and location         = I_location
         and comp_id          = 'TEXP';

   cursor C_GET_PO_TDTY(L_item ITEM_MASTER.ITEM%TYPE) is
      select NVL(SUM(a.est_assess_value), 0)
        from ordsku_hts_assess a,
             ordsku_hts h
       where h.order_no          = I_order_no
         and h.order_no          = a.order_no
         and h.seq_no            = a.seq_no
         and ((L_buyer_pack      = 'N'
              and h.item         = I_item
              and h.pack_item   is NULL)
          or (L_buyer_pack       = 'Y'
              and h.pack_item    =  I_item
              and h.item         =  L_item))
         and h.import_country_id =  L_import_country_id
         and a.comp_id           =  L_dty_comp_id;

BEGIN
   O_total_exp := 0;
   O_total_dty := 0;
   O_total_elc := 0;
   ---
   if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                       L_currency_prim) = FALSE then
      return FALSE;
   end if;
   ---

   if I_pack_ind IS NULL and
      I_sellable_ind IS NULL and
      I_orderable_ind IS NULL then
      -- Optimally the following item indicators were passed into this function, but if
      -- they were not, they must be retrieved from ITEM_MASTER.
      if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                       L_pack_ind,
                                       L_sellable_ind,
                                       L_orderable_ind,
                                       L_pack_type,
                                       I_item) = FALSE then
         return FALSE;
      end if;
   else
      L_pack_ind := I_pack_ind;
      L_sellable_ind := I_sellable_ind;
      L_orderable_ind := I_orderable_ind;
      L_pack_type := I_pack_type;
   end if;

   if(L_orderable_ind = 'N') then
       return TRUE ;
   end if;
   ---
   if L_pack_type = 'B' then
      L_buyer_pack := 'Y';
   end if;
   ---
   if (L_orderable_ind = 'Y' or L_pack_ind = 'N') then
      ---
      if (I_supplier is NULL or I_origin_country_id is NULL) then
         SQL_LIB.SET_MARK('OPEN','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
         open C_GET_ORD_SUPP_ORIG;
         SQL_LIB.SET_MARK('FETCH','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
         fetch C_GET_ORD_SUPP_ORIG into L_supplier,
                                        L_origin_country_id,
                                        L_import_country_id;
         SQL_LIB.SET_MARK('CLOSE','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
         close C_GET_ORD_SUPP_ORIG;
      end if;
   end if;    -- L_orderable_ind = 'Y' or L_pack_ind = 'N'
   ---
   if I_import_country_id is NULL then
      if SYSTEM_OPTIONS_SQL.GET_BASE_COUNTRY(O_error_message,
                                             L_import_country_id) = FALSE then
         return FALSE;
      end if;
   else
      L_import_country_id := I_import_country_id;
   end if;
   ---
   L_dty_comp_id := 'TDTY'||L_import_country_id;
   ---
   -- Get the quantity ordered for the item if it has not been input
   if I_qty_ordered IS NULL then
      open C_GET_ORDER_QTY;
      SQL_LIB.SET_MARK('FETCH','C_GET_ORDER_QTY','ORDLOC',NULL);
      fetch C_GET_ORDER_QTY into L_qty_ordered;
      if C_GET_ORDER_QTY%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('NO_ORD_QTY_FOUND',
                                               I_order_no,
                                               I_item,
                                               I_location);
         SQL_LIB.SET_MARK('CLOSE','C_GET_ORDER_QTY','ORDLOC',NULL);
         close C_GET_ORDER_QTY;
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_GET_ORDER_QTY','ORDLOC',NULL);
      close C_GET_ORDER_QTY;
   else
      L_qty_ordered := I_qty_ordered;
   end if;

   ---
   -- if buyer pack then need to get location for each component item
   -- loop through the comps of the pack get the texp and tdty
   -- sum results from fetch in loop.
   ---
   if L_buyer_pack = 'Y' then
      L_cost := I_cost;
      ---
      if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                            L_currency_ord,
                                            L_ord_exchange_rate,
                                            I_order_no) = FALSE then
         return FALSE;
      end if;

      ---
      -- Convert the Order Cost from the order's currency
      -- to primary currency.
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_cost,
                              L_currency_ord,
                              L_currency_prim,
                              L_cost,
                              NULL,
                              NULL,
                              NULL,
                              L_ord_exchange_rate,
                              NULL) = FALSE then
         return FALSE;
      end if;

      ---
      FOR C_rec in C_PACK_ITEMS LOOP
         L_item      := C_rec.item;
         L_qty       := C_rec.qty;
         L_total_exp := 0;
         L_total_dty := 0;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
         open C_GET_PO_TEXP_PACK(L_item);
         SQL_LIB.SET_MARK('FETCH','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
         fetch C_GET_PO_TEXP_PACK into L_total_exp,
                                       O_exp_currency,
                                       O_exchange_rate_exp;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TEXP_PACK','ORDLOC_EXP',NULL);
         close C_GET_PO_TEXP_PACK;
		 O_total_exp := O_total_exp + (NVL(L_total_exp, 0) * NVL(L_qty, 0));
		 ---
	     SQL_LIB.SET_MARK('OPEN','C_GET_PO_TDTY',
                          'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
         open C_GET_PO_TDTY(L_item);
         SQL_LIB.SET_MARK('FETCH','C_GET_PO_TDTY',
                          'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
         fetch C_GET_PO_TDTY into L_total_dty;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TDTY',
                          'ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
         close C_GET_PO_TDTY;
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_CURR',
                          'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         open C_GET_ASSESS_CURR;
         SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_CURR',
                          'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         fetch C_GET_ASSESS_CURR into O_dty_currency;
         SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_CURR',
                          'ITEM_HTS, ITEM_HTS_ASSESS',NULL);
         close C_GET_ASSESS_CURR;
         ---
         O_total_dty := O_total_dty + (NVL(L_total_dty, 0) * NVL(L_qty, 0));

         END LOOP;
        --Multiple up the expense by the qty ordered
         O_total_exp := O_total_exp * L_qty_ordered;
	    --Multiply up the duty by the qty ordered
	     O_total_dty := O_total_dty * L_qty_ordered;

      else -- L_buyer_pack = 'N'
         SQL_LIB.SET_MARK('OPEN','C_GET_PO_TEXP_NONPACK','ORDLOC_EXP',NULL);
         open C_GET_PO_TEXP_NONPACK;
         SQL_LIB.SET_MARK('FETCH','C_GET_PO_TEXP_NONPACK','ORDLOC_EXP',NULL);
         fetch C_GET_PO_TEXP_NONPACK into O_total_exp,
                                          O_exp_currency,
                                          O_exchange_rate_exp;
         SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TEXP_NONPACK','ORDLOC_EXP',NULL);
         close C_GET_PO_TEXP_NONPACK;
	 ---
	 --Multiple the expense by the total order qty
	 ---
	    O_total_exp := O_total_exp * L_qty_ordered;
	   ---
       SQL_LIB.SET_MARK('OPEN','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
       open C_GET_PO_TDTY(NULL);
       SQL_LIB.SET_MARK('FETCH','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
       fetch C_GET_PO_TDTY into O_total_dty;
       SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
       close C_GET_PO_TDTY;
       ---
	   --Multiple the duty by the total order qty
	   ---
	    O_total_dty := O_total_dty * L_qty_ordered;
	   ---
       SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
       open C_GET_ASSESS_CURR;
       SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
       fetch C_GET_ASSESS_CURR into O_dty_currency;
       SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
       close C_GET_ASSESS_CURR;
       ---

       L_cost := I_cost;
       ---
       if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                             L_currency_ord,
                                             L_ord_exchange_rate,
                                             I_order_no) = FALSE then
          return FALSE;
       end if;

	  -- Convert the Order Cost from the order's currency
      -- to primary currency.
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_cost,
                              L_currency_ord,
                              L_currency_prim,
                              L_cost,
                              NULL,
                              NULL,
                              NULL,
                              L_ord_exchange_rate,
                              NULL) = FALSE then
          return FALSE;
       end if;
     end if; -- L_buyer_pack = 'Y'/'N'
   ---
   if O_exp_currency is not NULL then
      ---
      -- Convert the Total Expense value from the expense currency
      -- to primary currency.
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              O_total_exp,
                              O_exp_currency,
                              L_currency_prim,
                              L_total_exp,
                              NULL,
                              NULL,
                              NULL,
                              O_exchange_rate_exp,
                              NULL) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if O_dty_currency is not NULL then
      ---
      -- Convert the Total Duty value from the import currency
      -- to primary currency.
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              O_total_dty,
                              O_dty_currency,
                              L_currency_prim,
                              L_total_dty,
                              NULL,
                              NULL,
                              NULL) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   -- Add the Total Expense value to the Total Duty value to
   -- get Total Estimated Landed Cost (Total ELC).  The value
   -- is in the Primary currency.
   ---

   O_total_elc := NVL(L_total_exp, 0) + NVL(L_total_dty, 0) + NVL(L_cost, 0);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CALC_ORDER_TOTALS;
--------------------------------------------------------------------------------------------------------------------------------
END ELC_CALC_SQL;
/

