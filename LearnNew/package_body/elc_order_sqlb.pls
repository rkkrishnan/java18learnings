CREATE OR REPLACE PACKAGE BODY ELC_ORDER_SQL AS
--------------------------------------------------------------------------------
LP_consolidation_ind         SYSTEM_OPTIONS.CONSOLIDATION_IND%TYPE;
LP_currency_code_prim        CURRENCIES.CURRENCY_CODE%TYPE;
LP_emu_participating_ind     BOOLEAN;
LP_vdate                     DATE;
LP_primary_curr_to_euro_rate CURRENCY_RATES.EXCHANGE_RATE%TYPE;
--------------------------------------------------------------------------------
FUNCTION RECALC_COMP(O_error_message     IN OUT VARCHAR2,
                     O_est_value         IN OUT NUMBER,
                     I_dtl_flag          IN     VARCHAR2,
                     I_comp_id           IN     ELC_COMP.COMP_ID%TYPE,
                     I_calc_type         IN     VARCHAR2,
                     I_item              IN     ITEM_MASTER.ITEM%TYPE,
                     I_supplier          IN     SUPS.SUPPLIER%TYPE,
                     I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                     I_ord_seq_no        IN     ORDLOC_EXP.SEQ_NO%TYPE,
                     I_pack_item         IN     ORDLOC_EXP.PACK_ITEM%TYPE,
                     I_location          IN     ORDLOC.LOCATION%TYPE,
                     I_hts               IN     HTS.HTS%TYPE,
                     I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                     I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                     I_effect_from       IN     HTS.EFFECT_FROM%TYPE,
                     I_effect_to         IN     HTS.EFFECT_TO%TYPE)
   RETURN BOOLEAN IS

   L_program                   VARCHAR2(62)                           := 'ELC_ORDER_SQL.RECALC_COMP';

BEGIN

   if RECALC_COMP(O_error_message,
                  O_est_value,
                  I_dtl_flag,
                  I_comp_id,
                  I_calc_type,
                  I_item,
                  I_supplier,
                  I_order_no,
                  I_ord_seq_no,
                  I_pack_item,
                  I_location,
                  I_hts,
                  I_import_country_id,
                  I_origin_country_id,
                  I_effect_from,
                  I_effect_to,
                  FALSE, -- extra exp info populated
                  NULL, -- calc basis
                  NULL, -- cvb code
                  NULL, -- comp rate
                  NULL, -- exchange rate
                  NULL, -- cost basis
                  NULL, -- comp currency
                  NULL, -- per count
                  NULL) = FALSE then -- per count uom
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
END RECALC_COMP;
--------------------------------------------------------------------------------
FUNCTION RECALC_COMP(O_error_message            IN OUT VARCHAR2,
                     O_est_value                IN OUT NUMBER,
                     I_dtl_flag                 IN     VARCHAR2,
                     I_comp_id                  IN     ELC_COMP.COMP_ID%TYPE,
                     I_calc_type                IN     VARCHAR2,
                     I_item                     IN     ITEM_MASTER.ITEM%TYPE,
                     I_supplier                 IN     SUPS.SUPPLIER%TYPE,
                     I_order_no                 IN     ORDHEAD.ORDER_NO%TYPE,
                     I_ord_seq_no               IN     ORDLOC_EXP.SEQ_NO%TYPE,
                     I_pack_item                IN     ORDLOC_EXP.PACK_ITEM%TYPE,
                     I_location                 IN     ORDLOC.LOCATION%TYPE,
                     I_hts                      IN     HTS.HTS%TYPE,
                     I_import_country_id        IN     COUNTRY.COUNTRY_ID%TYPE,
                     I_origin_country_id        IN     COUNTRY.COUNTRY_ID%TYPE,
                     I_effect_from              IN     HTS.EFFECT_FROM%TYPE,
                     I_effect_to                IN     HTS.EFFECT_TO%TYPE,
                     I_extra_exp_info_populated IN     BOOLEAN,
                     I_calc_basis               IN     ELC_COMP.CALC_BASIS%TYPE,
                     I_cvb_code                 IN     ORDLOC_EXP.CVB_CODE%TYPE,
                     I_comp_rate                IN     ORDLOC_EXP.COMP_RATE%TYPE,
                     I_exchange_rate            IN     ORDLOC_EXP.EXCHANGE_RATE%TYPE,
                     I_cost_basis               IN     ORDLOC_EXP.COST_BASIS%TYPE,
                     I_comp_currency            IN     ORDLOC_EXP.COMP_CURRENCY%TYPE,
                     I_per_count                IN     ORDLOC_EXP.PER_COUNT%TYPE,
                     I_per_count_uom            IN     ORDLOC_EXP.PER_COUNT_UOM%TYPE)
   RETURN BOOLEAN IS

   -- if I_calc_type is 'PE' Purchase Order Expenses
   --                   'PA' Purchase Order Assessments

   L_program                   VARCHAR2(62)                           := 'ELC_ORDER_SQL.RECALC_COMP';
   L_add                       VARCHAR2(1)                            := '+';
   L_sub                       VARCHAR2(1)                            := '-';
   L_currency_code_prim        CURRENCIES.CURRENCY_CODE%TYPE;

   ---
   -- These variables are typed as NUMBER to avoid rounding for accuracy.
   ---
   L_amount                    NUMBER     := 0;
   L_amount_sub                NUMBER     := 0;
   L_pack_amt                  NUMBER     := 0;
   L_packitem_amt              NUMBER     := 0;
   L_ord_cost                  NUMBER     := 0;
   L_est_value                 NUMBER     := 0;
   L_value                     NUMBER     := 0;
   L_per_unit_value            NUMBER     := 0;
   ----
   L_exp_dtl_amt               NUMBER     := 0;
   L_exp_dtl_amt_prim          NUMBER     := 0;
   L_exp_assess_dtl_amt        NUMBER     := 0;
   L_exp_assess_dtl_amt_prim   NUMBER     := 0;
   L_exp_flag_amt              NUMBER     := 0;
   L_exp_flag_amt_prim         NUMBER     := 0;
   L_exp_assess_flag_amt       NUMBER     := 0;
   L_exp_assess_flag_amt_prim  NUMBER     := 0;
   L_assess_dtl_amt            NUMBER     := 0;
   L_assess_dtl_amt_prim       NUMBER     := 0;
   L_assess_flag_amt           NUMBER     := 0;
   L_assess_flag_amt_prim      NUMBER     := 0;
   L_assess_exp_dtl_amt        NUMBER     := 0;
   L_assess_exp_dtl_amt_prim   NUMBER     := 0;
   L_assess_exp_flag_amt       NUMBER     := 0;
   L_assess_exp_flag_amt_prim  NUMBER     := 0;
   ---
   L_oper                      VARCHAR2(1);
   L_calc_basis                ELC_COMP.CALC_BASIS%TYPE;
   L_cvb_code                  CVB_HEAD.CVB_CODE%TYPE;
   L_comp_rate                 ELC_COMP.COMP_RATE%TYPE;
   L_cost_basis                ELC_COMP.COST_BASIS%TYPE;
   L_comp_currency             CURRENCIES.CURRENCY_CODE%TYPE;
   L_per_count                 ELC_COMP.PER_COUNT%TYPE;
   L_per_count_uom             UOM_CLASS.UOM%TYPE;
   L_nom_flag_1                ELC_COMP.NOM_FLAG_1%TYPE;
   L_nom_flag_2                ELC_COMP.NOM_FLAG_1%TYPE;
   L_nom_flag_3                ELC_COMP.NOM_FLAG_1%TYPE;
   L_nom_flag_4                ELC_COMP.NOM_FLAG_1%TYPE;
   L_nom_flag_5                ELC_COMP.NOM_FLAG_1%TYPE;
   L_orig_currency_code_prim   CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_code_sup         CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_code_ord         CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_ord         CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_exchange_type             CURRENCY_RATES.EXCHANGE_TYPE%TYPE;
   L_exchange_rate             CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_tot_ord_qty               ORDLOC.QTY_ORDERED%TYPE;
   L_supplier                  SUPS.SUPPLIER%TYPE;
   L_origin_country_id         COUNTRY.COUNTRY_ID%TYPE;
   L_supp_pack_size            ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;
   L_case_weight               ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
   L_weight_uom                ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
   L_case_length               ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
   L_case_height               ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
   L_case_width                ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
   L_lwh_uom                   ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
   L_standard_uom              UOM_CLASS.UOM%TYPE;
   L_uom                       UOM_CLASS.UOM%TYPE;
   L_standard_class            UOM_CLASS.UOM_CLASS%TYPE;
   L_uom_class                 UOM_CLASS.UOM_CLASS%TYPE;
   L_unit_of_work              IF_ERRORS.UNIT_OF_WORK%TYPE;
   L_counter                   NUMBER;
   L_euro_comp_currency        CURRENCIES.CURRENCY_CODE%TYPE;
   L_case_liquid_volume        ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
   L_liquid_vol_uom            UOM_CLASS.UOM%TYPE;
   L_ti                        ITEM_SUPP_COUNTRY.TI%TYPE;
   L_hi                        ITEM_SUPP_COUNTRY.HI%TYPE;
   L_inner_pack_size           ITEM_SUPP_COUNTRY.INNER_PACK_SIZE%TYPE;
   L_pallet_desc               CODE_DETAIL.CODE_DESC%TYPE;
   L_case_desc                 CODE_DETAIL.CODE_DESC%TYPE;
   L_inner_desc                CODE_DETAIL.CODE_DESC%TYPE;
   L_pallet_size               NUMBER;

   cursor C_CHECK_PO_EXCHANGE_TYPE is
      select r.exchange_type
        from currencies c,
             currency_rates r
       where c.currency_code  = L_comp_currency
         and c.currency_code  = r.currency_code
         and r.exchange_type  = 'P'
         and r.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where cr.exchange_type   = 'P'
                                    and cr.currency_code   = L_comp_currency
                                    and cr.effective_date <= LP_vdate);

   cursor C_GET_CVB_FLAGS is
      select nom_flag_1,
             nom_flag_2,
             nom_flag_3,
             nom_flag_4,
             nom_flag_5
        from cvb_head
       where cvb_code = L_cvb_code;

   -------------------------------------------
   -- Purchase Order Expense Cursors
   -------------------------------------------

   cursor C_PO_EXP_INFO is
      select elc.calc_basis,
             o.cvb_code,
             o.comp_rate,
             o.exchange_rate,
             o.cost_basis,
             o.comp_currency,
             o.per_count,
             o.per_count_uom
        from elc_comp elc,
             ordloc_exp o
       where o.order_no = I_order_no
         and o.seq_no   = I_ord_seq_no
         and o.comp_id  = elc.comp_id;

   cursor C_SUM_PO_EXP_DTLS is
      select NVL(SUM(o.est_exp_value/o.exchange_rate), 0)
        from ordloc_exp o,
             cvb_detail cd
       where o.order_no            = I_order_no
         and o.item                = I_item
         and ((o.pack_item         = I_pack_item
               and o.pack_item     is not NULL
               and I_pack_item     is not NULL)
             or (o.pack_item       is NULL
                 and I_pack_item   is NULL))
         and o.location            = I_location
         and o.comp_id             = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper;

   cursor C_EURO_SUM_PO_EXP_DTLS is
      select NVL(SUM(DECODE(euro.exchange_rate, NULL,
             o.est_exp_value/o.exchange_rate,
             o.est_exp_value/(euro.exchange_rate * o.exchange_rate))), 0)
        from cvb_detail cd,
             euro_exchange_rate euro,
             ordloc_exp o
       where o.order_no            = I_order_no
         and o.item                = I_item
         and ((o.pack_item         = I_pack_item
               and o.pack_item     is not NULL
               and I_pack_item     is not NULL)
             or (o.pack_item       is NULL
                 and I_pack_item   is NULL))
         and o.comp_currency       = euro.currency_code(+)
         and o.location            = I_location
         and o.comp_id             = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper;

   cursor C_SUM_PO_EXP_ASSESS_DTLS is
      select NVL(SUM(a.est_assess_value/c.exchange_rate), 0)
        from elc_comp e,
             cvb_detail cd,
             currency_rates c,
             ordsku_hts_assess a,
             ordsku_hts h
       where h.order_no       = I_order_no
         and h.item           = I_item
         and ((h.pack_item    = I_pack_item
              and I_pack_item is not NULL)
          or (h.pack_item     is NULL
              and I_pack_item is NULL))
         and a.order_no       = h.order_no
         and a.seq_no         = h.seq_no
         and e.comp_id        = a.comp_id
         and e.comp_currency != L_currency_code_prim
         and e.comp_currency  = c.currency_code
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where cr.currency_code   = e.comp_currency
                                    and cr.exchange_type   = L_exchange_type
                                    and cr.effective_date <= LP_vdate)
         and a.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_EURO_SUM_PO_EXP_ASSESS_DTLS is
      select NVL(SUM(DECODE(euro.currency_code, NULL,
          a.est_assess_value / c.exchange_rate,
          a.est_assess_value /(euro.exchange_rate *
                               LP_primary_curr_to_euro_rate))), 0)
        from elc_comp e,
             cvb_detail cd,
             currency_rates c,
             euro_exchange_rate euro,
             ordsku_hts_assess a,
             ordsku_hts h
       where h.order_no       = I_order_no
         and h.item           = I_item
         and ((h.pack_item    = I_pack_item
              and I_pack_item is not NULL)
          or (h.pack_item     is NULL
              and I_pack_item is NULL))
         and e.comp_currency  = euro.currency_code(+)
         and (e.comp_currency = c.currency_code
              or (c.currency_code = 'EUR' and euro.currency_code is not NULL))
         and a.order_no       = h.order_no
         and a.seq_no         = h.seq_no
         and e.comp_id        = a.comp_id
         and e.comp_currency != L_currency_code_prim
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where (cr.currency_code  = e.comp_currency
                                     or (cr.currency_code  = 'EUR' and euro.currency_code is not NULL))
                                    and cr.exchange_type   = L_exchange_type
                                    and cr.effective_date <= LP_vdate)
         and a.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_SUM_PO_EXP_ASSESS_DTLS_PRIM is
      select NVL(SUM(a.est_assess_value), 0)
        from elc_comp e,
             cvb_detail cd,
             ordsku_hts_assess a,
             ordsku_hts h
       where h.order_no       = I_order_no
         and h.item           = I_item
         and ((h.pack_item    = I_pack_item
              and I_pack_item is not NULL)
          or (h.pack_item     is NULL
              and I_pack_item is NULL))
         and a.order_no       = h.order_no
         and a.seq_no         = h.seq_no
         and a.comp_id        = e.comp_id
         and e.comp_currency  = L_currency_code_prim
         and a.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_SUM_PO_EXP_FLAGS is
      select NVL(SUM(est_exp_value/exchange_rate), 0)
        from ordloc_exp
       where order_no            = I_order_no
         and item                = I_item
         and location            = I_location
         and ((pack_item         = I_pack_item
               and pack_item     is not NULL
               and I_pack_item   is not NULL)
             or (pack_item       is NULL
                 and I_pack_item is NULL))
         and ((L_nom_flag_1      = 'Y' and nom_flag_1 = L_oper)
             or (L_nom_flag_2    = 'Y' and nom_flag_2 = L_oper)
             or (L_nom_flag_3    = 'Y' and nom_flag_3 = L_oper)
             or (L_nom_flag_4    = 'Y' and nom_flag_4 = L_oper)
             or (L_nom_flag_5    = 'Y' and nom_flag_5 = L_oper));

   cursor C_EURO_SUM_PO_EXP_FLAGS is
      select NVL(SUM(DECODE(euro.currency_code, NULL,
             est_exp_value/o.exchange_rate,
             est_exp_value/(euro.exchange_rate * o.exchange_rate))), 0)
        from ordloc_exp o,
             euro_exchange_rate euro
       where o.order_no            = I_order_no
         and o.item                = I_item
         and ((o.pack_item         = I_pack_item
               and o.pack_item     is not NULL
               and I_pack_item     is not NULL)
             or (o.pack_item       is NULL
                 and I_pack_item   is NULL))
         and o.location            = I_location
         and o.comp_currency       = euro.currency_code (+)
         and ((L_nom_flag_1      = 'Y' and o.nom_flag_1 = L_oper)
             or (L_nom_flag_2    = 'Y' and o.nom_flag_2 = L_oper)
             or (L_nom_flag_3    = 'Y' and o.nom_flag_3 = L_oper)
             or (L_nom_flag_4    = 'Y' and o.nom_flag_4 = L_oper)
             or (L_nom_flag_5    = 'Y' and o.nom_flag_5 = L_oper));

   cursor C_SUM_PO_EXP_ASSESS_FLAGS is
      select NVL(SUM(o.est_assess_value/c.exchange_rate), 0)
        from elc_comp e,
             currency_rates c,
             ordsku_hts_assess o,
             ordsku_hts h
       where h.order_no       = I_order_no
         and h.item           = I_item
         and ((h.pack_item    = I_pack_item
              and I_pack_item is not NULL)
          or (h.pack_item     is NULL
              and I_pack_item is NULL))
         and o.order_no       = h.order_no
         and o.seq_no         = h.seq_no
         and o.comp_id        = e.comp_id
         and e.comp_currency  = c.currency_code
         and e.comp_currency != L_currency_code_prim
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where cr.currency_code   = e.comp_currency
                                    and cr.exchange_type   = L_exchange_type
                                    and cr.effective_date <= LP_vdate)
         and ((L_nom_flag_1   = 'Y' and o.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and o.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and o.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and o.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and o.nom_flag_5 = L_oper));

   cursor C_EURO_SUM_PO_EXP_ASSESS_FLAGS is
      select NVL(SUM(DECODE(euro.currency_code, NULL,
             o.est_assess_value/c.exchange_rate,
             o.est_assess_value/(euro.exchange_rate *
                                 LP_primary_curr_to_euro_rate))), 0)
        from elc_comp e,
             currency_rates c,
             euro_exchange_rate euro,
             ordsku_hts_assess o,
             ordsku_hts h
       where h.order_no       = I_order_no
         and h.item           = I_item
         and ((h.pack_item    = I_pack_item
              and I_pack_item is not NULL)
          or (h.pack_item     is NULL
              and I_pack_item is NULL))
         and o.order_no       = h.order_no
         and o.seq_no         = h.seq_no
         and o.comp_id        = e.comp_id
         and (e.comp_currency = c.currency_code
              or (c.currency_code = 'EUR' and euro.currency_code is not NULL))
         and e.comp_currency  = euro.currency_code (+)
         and e.comp_currency != L_currency_code_prim
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where (cr.currency_code      = e.comp_currency
                                         or (cr.currency_code  = 'EUR' and euro.currency_code is not NULL))
                                    and cr.exchange_type       = L_exchange_type
                                    and cr.effective_date     <= LP_vdate)
         and ((L_nom_flag_1   = 'Y' and o.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and o.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and o.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and o.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and o.nom_flag_5 = L_oper));

   cursor C_SUM_PO_EXP_ASSESS_FLAGS_PRIM is
      select NVL(SUM(o.est_assess_value), 0)
        from elc_comp e,
             ordsku_hts_assess o,
             ordsku_hts h
       where h.order_no       = I_order_no
         and h.item           = I_item
         and ((h.pack_item    = I_pack_item
              and I_pack_item is not NULL)
          or (h.pack_item     is NULL
              and I_pack_item is NULL))
         and o.order_no       = h.order_no
         and o.seq_no         = h.seq_no
         and o.comp_id        = e.comp_id
         and e.comp_currency  = L_currency_code_prim
         and ((L_nom_flag_1   = 'Y' and o.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and o.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and o.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and o.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and o.nom_flag_5 = L_oper));

   -------------------------------------------
   -- Purchase Order Assessment Cursors
   -------------------------------------------

   cursor C_PO_ASSESS_INFO is
      select elc.calc_basis,
             o.cvb_code,
             o.comp_rate,
             elc.comp_currency,
             o.per_count,
             o.per_count_uom
        from elc_comp elc,
             ordsku_hts_assess o
       where o.order_no = I_order_no
         and o.seq_no   = I_ord_seq_no
         and o.comp_id  = I_comp_id
         and o.comp_id  = elc.comp_id;

   cursor C_SUM_PO_ASSESS_DTLS is
      select NVL(SUM(o.est_assess_value/c.exchange_rate), 0)
        from elc_comp e,
             cvb_detail cd,
             currency_rates c,
             ordsku_hts_assess o
       where o.order_no       = I_order_no
         and o.seq_no         = I_ord_seq_no
         and o.comp_id        = e.comp_id
         and e.comp_currency != L_currency_code_prim
         and e.comp_currency  = c.currency_code
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = e.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= LP_vdate)
         and o.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;


   cursor C_EURO_SUM_PO_ASSESS_DTLS is
      select NVL(SUM(DECODE(euro.currency_code, NULL,
          a.est_assess_value / c.exchange_rate,
          a.est_assess_value /(euro.exchange_rate *
                               LP_primary_curr_to_euro_rate))), 0)
        from elc_comp e,
             cvb_detail cd,
             currency_rates c,
             euro_exchange_rate euro,
             ordsku_hts_assess a
       where  a.order_no       = I_order_no
         and a.seq_no         = I_ord_seq_no
         and e.comp_currency  = euro.currency_code(+)
         and (e.comp_currency = c.currency_code
              or (c.currency_code = 'EUR' and euro.currency_code is not NULL))
         and e.comp_id        = a.comp_id
         and e.comp_currency != L_currency_code_prim
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where (cr.currency_code  = e.comp_currency
                                     or (cr.currency_code  = 'EUR' and euro.currency_code is not NULL))
                                    and cr.exchange_type   = L_exchange_type
                                    and cr.effective_date <= LP_vdate)
         and a.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_SUM_PO_ASSESS_DTLS_PRIM is
      select NVL(SUM(o.est_assess_value), 0)
        from ordsku_hts_assess o,
             cvb_detail cd,
             elc_comp e
       where o.order_no      = I_order_no
         and o.seq_no        = I_ord_seq_no
         and e.comp_currency = L_currency_code_prim
         and o.comp_id       = cd.comp_id
         and o.comp_id       = e.comp_id
         and cd.cvb_code     = L_cvb_code
         and cd.combo_oper   = L_oper;

   cursor C_SUM_PO_ASSESS_EXP_DTLS is
      select NVL(SUM((o.est_exp_value/o.exchange_rate) * ol.qty_ordered), 0)
        from ordloc ol,
             cvb_detail cd,
             ordloc_exp o
       where o.order_no        = I_order_no
         and o.order_no        = ol.order_no
         and o.location        = ol.location
         and ((o.item          = ol.item
               and I_pack_item is NULL)
            or (o.pack_item    = ol.item
               and I_pack_item is not NULL))
         and o.item            = I_item
         and ((o.pack_item     = I_pack_item
               and o.pack_item is not NULL
               and I_pack_item is not NULL)
            or (o.pack_item    is NULL
               and I_pack_item is NULL))
         and o.comp_id         = cd.comp_id
         and cd.cvb_code       = L_cvb_code
         and cd.combo_oper     = L_oper;

   cursor C_EURO_SUM_PO_ASSESS_EXP_DTLS is
      select NVL(SUM((DECODE(euro.currency_code, NULL,
             o.est_exp_value/o.exchange_rate,
             o.est_exp_value/(euro.exchange_rate*o.exchange_rate)))
                  * ol.qty_ordered), 0)
        from cvb_detail cd,
             euro_exchange_rate euro,
             ordloc ol,
             ordloc_exp o
       where o.order_no        = I_order_no
         and o.order_no        = ol.order_no
         and o.comp_currency   = euro.currency_code(+)
         and o.location        = ol.location
         and ((o.item          = ol.item
               and I_pack_item is NULL)
            or (o.pack_item    = ol.item
               and I_pack_item is not NULL))
         and o.item            = I_item
         and ((o.pack_item     = I_pack_item
               and o.pack_item is not NULL
               and I_pack_item is not NULL)
            or (o.pack_item    is NULL
               and I_pack_item is NULL))
         and o.comp_id         = cd.comp_id
         and cd.cvb_code       = L_cvb_code
         and cd.combo_oper     = L_oper;

   cursor C_SUM_PO_ASSESS_FLAGS is
      select NVL(SUM(o.est_assess_value/c.exchange_rate), 0)
        from currency_rates c,
             elc_comp e,
             ordsku_hts_assess o
       where o.order_no       = I_order_no
         and o.seq_no         = I_ord_seq_no
         and o.comp_id        = e.comp_id
         and e.comp_currency != L_currency_code_prim
         and e.comp_currency  = c.currency_code
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = e.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= LP_vdate)
         and ((L_nom_flag_1   = 'Y' and o.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and o.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and o.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and o.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and o.nom_flag_5 = L_oper));


   cursor C_EURO_SUM_PO_ASSESS_FLAGS is
      select NVL(SUM(DECODE(euro.currency_code, NULL,
             o.est_assess_value/c.exchange_rate,
             o.est_assess_value/(euro.exchange_rate *
                                 LP_primary_curr_to_euro_rate))), 0)
        from elc_comp e,
             currency_rates c,
             euro_exchange_rate euro,
             ordsku_hts_assess o
       where o.order_no       = I_order_no
         and o.seq_no         = I_ord_seq_no
         and o.comp_id        = e.comp_id
         and (e.comp_currency = c.currency_code
              or (c.currency_code = 'EUR' and euro.currency_code is not NULL))
         and e.comp_currency  = euro.currency_code (+)
         and e.comp_currency != L_currency_code_prim
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where (cr.currency_code      = e.comp_currency
                                         or (cr.currency_code  = 'EUR' and euro.currency_code is not NULL))
                                    and cr.exchange_type       = L_exchange_type
                                    and cr.effective_date     <= LP_vdate)
         and ((L_nom_flag_1   = 'Y' and o.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and o.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and o.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and o.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and o.nom_flag_5 = L_oper));

   cursor C_SUM_PO_ASSESS_FLAGS_PRIM is
      select NVL(SUM(o.est_assess_value), 0)
        from ordsku_hts_assess o,
             elc_comp e
       where o.order_no          = I_order_no
         and o.seq_no            = I_ord_seq_no
         and e.comp_currency     = L_currency_code_prim
         and e.comp_id           = o.comp_id
         and ((L_nom_flag_1    = 'Y' and o.nom_flag_1 = L_oper)
             or (L_nom_flag_2  = 'Y' and o.nom_flag_2 = L_oper)
             or (L_nom_flag_3  = 'Y' and o.nom_flag_3 = L_oper)
             or (L_nom_flag_4  = 'Y' and o.nom_flag_4 = L_oper)
             or (L_nom_flag_5  = 'Y' and o.nom_flag_5 = L_oper));

   cursor C_SUM_PO_ASSESS_EXP_FLAGS is
      select NVL(SUM((o.est_exp_value/o.exchange_rate) * ol.qty_ordered), 0)
        from ordloc ol,
             ordloc_exp o
       where o.order_no        = I_order_no
         and o.order_no        = ol.order_no
         and o.location        = ol.location
         and ((o.item          = ol.item
               and I_pack_item is NULL)
            or (o.pack_item    = ol.item
               and I_pack_item is not NULL))
         and o.item            = I_item
         and ((o.pack_item     = I_pack_item
               and o.pack_item is not NULL
               and I_pack_item is not NULL)
            or (o.pack_item    is NULL
               and I_pack_item is NULL))
         and ((L_nom_flag_1    = 'Y' and nom_flag_1 = L_oper)
             or (L_nom_flag_2  = 'Y' and nom_flag_2 = L_oper)
             or (L_nom_flag_3  = 'Y' and nom_flag_3 = L_oper)
             or (L_nom_flag_4  = 'Y' and nom_flag_4 = L_oper)
             or (L_nom_flag_5  = 'Y' and nom_flag_5 = L_oper));

   cursor C_EURO_SUM_PO_ASSESS_EXP_FLAGS is
      select NVL(SUM((DECODE(euro.currency_code, NULL,
             o.est_exp_value/o.exchange_rate,
             o.est_exp_value/(euro.exchange_rate*o.exchange_rate)))
                            * ol.qty_ordered), 0)
        from euro_exchange_rate euro,
             ordloc ol,
             ordloc_exp o
       where o.order_no        = I_order_no
         and o.order_no        = ol.order_no
         and o.comp_currency   = euro.currency_code(+)
         and o.location        = ol.location
         and ((o.item          = ol.item
               and I_pack_item is NULL)
            or (o.pack_item    = ol.item
               and I_pack_item is not NULL))
         and o.item            = I_item
         and ((o.pack_item     = I_pack_item
               and o.pack_item is not NULL
               and I_pack_item is not NULL)
            or (o.pack_item    is NULL
               and I_pack_item is NULL))
         and ((L_nom_flag_1  = 'Y' and nom_flag_1 = L_oper)
           or (L_nom_flag_2  = 'Y' and nom_flag_2 = L_oper)
           or (L_nom_flag_3  = 'Y' and nom_flag_3 = L_oper)
           or (L_nom_flag_4  = 'Y' and nom_flag_4 = L_oper)
           or (L_nom_flag_5  = 'Y' and nom_flag_5 = L_oper));

   -------------------------------------------
   -- General Information Cursors
   -------------------------------------------

   cursor C_GET_ORD_SUPP_ORIG is
      select oh.supplier,
             os.origin_country_id
        from ordhead oh,
             ordsku os
       where oh.order_no = I_order_no
         and oh.order_no = os.order_no
         and os.item     = NVL(I_pack_item, I_item);

   cursor C_GET_TOTAL_ORD_QTY is
      select SUM(qty_ordered)
        from ordloc
       where order_no = I_order_no
         and item     = NVL(I_pack_item, I_item);

   cursor C_GET_ITEM_LOC_UNIT_COST is
      select unit_cost
        from item_supp_country_loc
       where item              = I_item
         and supplier          = L_supplier
         and origin_country_id = L_origin_country_id
         and loc               = I_location;

   cursor C_GET_ORD_COST is
      select unit_cost
        from ordloc
       where order_no     = I_order_no
         and ((item       = NVL(I_pack_item, I_item)
             and location = I_location)
              or (item    = NVL(I_pack_item, I_item)
                 and I_location is NULL));

   cursor C_SUM_LOC_PACKITEM_COST is
      select SUM(i.unit_cost * v.qty)
        from item_supp_country_loc i,
             v_packsku_qty v
       where i.supplier          = L_supplier
         and i.origin_country_id = L_origin_country_id
         and i.loc               = I_location
         and i.item              = v.item
         and v.pack_no           = I_pack_item;

   cursor C_GET_DIMENSION is
      select i.supp_pack_size,
             d.weight,
             d.weight_uom,
             d.length,
             d.height,
             d.width,
             d.lwh_uom,
             d.liquid_volume,
             d.liquid_volume_uom
        from item_supp_country i,
             item_supp_country_dim d
       where i.item       = I_item
         and ((i.supplier = L_supplier
               and L_supplier is not NULL)
          or (i.primary_supp_ind = 'Y'
              and L_supplier is NULL))
         and ((i.origin_country_id = L_origin_country_id
               and L_origin_country_id is not NULL)
          or (i.primary_country_ind = 'Y'
              and L_origin_country_id is NULL))
         and i.item              = d.item (+)
         and i.supplier          = d.supplier (+)
         and i.origin_country_id = d.origin_country (+)
         and d.dim_object (+)    = 'CA';

   cursor C_GET_MISC_VALUE is
      select value
        from item_supp_uom
       where item     = I_item
         and supplier = L_supplier
         and uom      = L_per_count_uom;

BEGIN
   O_est_value         := 0;
   L_origin_country_id := I_origin_country_id;
   L_supplier          := I_supplier;
   ---
   if LP_vdate is NULL then
      LP_vdate := GET_VDATE;
   end if;
   ---
   if LP_consolidation_ind is NULL then
      if SYSTEM_OPTIONS_SQL.CONSOLIDATION_IND(O_error_message,
                                              LP_consolidation_ind) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if LP_consolidation_ind = 'Y' then
      L_exchange_type := 'C';
   else
      L_exchange_type := 'O';
   end if;
   ---
   if LP_currency_code_prim is NULL then
      if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                          LP_currency_code_prim) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   --Check if LP_currency_code_prim is EMU member and set accordingly.
   ---
   if LP_emu_participating_ind is NULL then
      if CURRENCY_SQL.CHECK_EMU_COUNTRIES(O_error_message,
                                          LP_emu_participating_ind,
                                          LP_currency_code_prim) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   L_orig_currency_code_prim := LP_currency_code_prim;
   ---
   if LP_emu_participating_ind = TRUE then
      L_currency_code_prim := 'EUR';
   else
      L_currency_code_prim := LP_currency_code_prim;
   end if;
   ---
   -- Retrieve the 'EUR' exchange rate
   -- if the primary currency is not one of the EMU countries.
   ---
   if L_currency_code_prim != 'EUR' and LP_primary_curr_to_euro_rate is NULL then
      if CURRENCY_SQL.GET_RATE(O_error_message,
                               LP_primary_curr_to_euro_rate,
                               'EUR',
                               LP_consolidation_ind,
                               LP_vdate) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if (I_supplier is NULL or I_origin_country_id is NULL) then
      SQL_LIB.SET_MARK('OPEN','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
      open C_GET_ORD_SUPP_ORIG;
      SQL_LIB.SET_MARK('FETCH','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
      fetch C_GET_ORD_SUPP_ORIG into L_supplier,
                                     L_origin_country_id;
      SQL_LIB.SET_MARK('CLOSE','C_GET_ORD_SUPP_ORIG','ORDHEAD','Order no: '||to_char(I_order_no));
      close C_GET_ORD_SUPP_ORIG;
   end if;
   ---
   if I_calc_type = 'PE' then
      if I_extra_exp_info_populated = TRUE then
          -- If the calling function (i.e. ELC_CALC_SQL.CALC_COMP) has retrieved the following
          -- expense attributes, then use the input values as opposed to querying the ELC_COMP
          -- and ORDLOC_EXP tables again via the C_PO_EXP_INFO cursor.
          L_calc_basis := I_calc_basis;
          L_cvb_code := I_cvb_code;
          L_comp_rate := I_comp_rate;
          L_exchange_rate := I_exchange_rate;
          L_cost_basis := I_cost_basis;
          L_comp_currency := I_comp_currency;
          L_per_count := I_per_count;
          L_per_count_uom := I_per_count_uom;
      else
         SQL_LIB.SET_MARK('OPEN','C_PO_EXP_INFO','ORDLOC_EXP',NULL);
         open C_PO_EXP_INFO;
         SQL_LIB.SET_MARK('FETCH','C_PO_EXP_INFO','ORDLOC_EXP',NULL);
         fetch C_PO_EXP_INFO into L_calc_basis,
                                  L_cvb_code,
                                  L_comp_rate,
                                  L_exchange_rate,
                                  L_cost_basis,
                                  L_comp_currency,
                                  L_per_count,
                                  L_per_count_uom;
         if C_PO_EXP_INFO%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('INV_COMP',NULL,NULL,NULL);
            SQL_LIB.SET_MARK('CLOSE','C_PO_EXP_INFO','ORDLOC_EXP',NULL);
            close C_PO_EXP_INFO;
            return FALSE;
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_PO_EXP_INFO','ORDLOC_EXP',NULL);
         close C_PO_EXP_INFO;
      end if;
   elsif I_calc_type = 'PA' then
      SQL_LIB.SET_MARK('OPEN','C_GET_TOTAL_ORD_QTY','ORDSKU',NULL);
      open C_GET_TOTAL_ORD_QTY;
      SQL_LIB.SET_MARK('FETCH','C_GET_TOTAL_ORD_QTY','ORDSKU',NULL);
      fetch C_GET_TOTAL_ORD_QTY into L_tot_ord_qty;
      SQL_LIB.SET_MARK('CLOSE','C_GET_TOTAL_ORD_QTY','ORDSKU',NULL);
      close C_GET_TOTAL_ORD_QTY;
      ---
      -- set L_tot_ord_qty to 1 to avoid divide-by-zero error
      -- when calculating L_assess_exp_dtl_amt(_prim) and
      -- L_assess_exp_flag_amt(prim)
      ---
      if L_tot_ord_qty = 0 then
         L_tot_ord_qty := 1;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN','C_PO_ASSESS_INFO','ORDSKU_HTS_ASSESS',NULL);
      open C_PO_ASSESS_INFO;
      SQL_LIB.SET_MARK('FETCH','C_PO_ASSESS_INFO','ORDSKU_HTS_ASSESS',NULL);
      fetch C_PO_ASSESS_INFO into L_calc_basis,
                                  L_cvb_code,
                                  L_comp_rate,
                                  L_comp_currency,
                                  L_per_count,
                                  L_per_count_uom;
      if C_PO_ASSESS_INFO%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_COMP',NULL,NULL,NULL);
         SQL_LIB.SET_MARK('CLOSE','C_PO_ASSESS_INFO','ORDSKU_HTS_ASSESS',NULL);
         close C_PO_ASSESS_INFO;
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_PO_ASSESS_INFO','ORDSKU_HTS_ASSESS',NULL);
      close C_PO_ASSESS_INFO;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_PO_EXCHANGE_TYPE','CURRENCY_RATES','Currency: '||L_comp_currency);
   open C_CHECK_PO_EXCHANGE_TYPE;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_PO_EXCHANGE_TYPE','CURRENCY_RATES','Currency: '||L_comp_currency);
   fetch C_CHECK_PO_EXCHANGE_TYPE into L_exchange_type;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_PO_EXCHANGE_TYPE','CURRENCY_RATES','Currency: '||L_comp_currency);
   close C_CHECK_PO_EXCHANGE_TYPE;
   ---
   if L_calc_basis = 'V' then    -- The expense is a 'Value' based expense.
      ---
      -- If the cvb_code of a component is not NULL then we need to sum up the
      -- values of the components of the cvb.
      ---
      if L_cvb_code is not NULL then
         if I_dtl_flag = 'F' then
            SQL_LIB.SET_MARK('OPEN','C_GET_CVB_FLAGS','CVB_HEAD','CVB Code: '||L_cvb_code);
            open C_GET_CVB_FLAGS;
            SQL_LIB.SET_MARK('FETCH','C_GET_CVB_FLAGS','CVB_HEAD','CVB Code: '||L_cvb_code);
            fetch C_GET_CVB_FLAGS into L_nom_flag_1,
                                       L_nom_flag_2,
                                       L_nom_flag_3,
                                       L_nom_flag_4,
                                       L_nom_flag_5;
            if C_GET_CVB_FLAGS%NOTFOUND then
               O_error_message := SQL_LIB.CREATE_MSG('INV_CVB',NULL,NULL,NULL);
               SQL_LIB.SET_MARK('OPEN','C_GET_CVB_FLAGS','CVB_HEAD','CVB Code: '||L_cvb_code);
               close C_GET_CVB_FLAGS;
               return FALSE;
            end if;
            SQL_LIB.SET_MARK('OPEN','C_GET_CVB_FLAGS','CVB_HEAD','CVB Code: '||L_cvb_code);
            close C_GET_CVB_FLAGS;
            ---
         end if;
         ---
         -- Components of cvb's all have a combination operation of either '+' or '-'.
         -- Here we will sum the components with a combination operator of '+'.  Then
         -- we will subtract all of the components with a combination operator of '-'
         -- from the value gotten here.
         L_counter := 1;
         LOOP
            EXIT when L_counter = 3;
            if L_counter = 1 then
               L_oper := L_add;
            else
               L_oper := L_sub;
            end if;

            if I_dtl_flag = 'D' then
               if I_calc_type = 'PE' then
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor sums the expense components of the CVB that
                     -- is attached to the component passed into this function,
                     -- that have a component currency that is different from the primary
                     -- currency.  As it sums the estimated expense values, it
                     -- converts the values into the primary currency.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_PO_EXP_DTLS','ORDLOC_EXP',NULL);
                     open C_SUM_PO_EXP_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_PO_EXP_DTLS','ORDLOC_EXP',NULL);
                     fetch C_SUM_PO_EXP_DTLS into L_exp_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_EXP_DTLS','ORDLOC_EXP',NULL);
                     close C_SUM_PO_EXP_DTLS;
                  else --L_currency_code_prim != 'EUR'--
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_PO_EXP_DTLS','ORDLOC_EXP',NULL);
                     open C_EURO_SUM_PO_EXP_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_PO_EXP_DTLS','ORDLOC_EXP',NULL);
                     fetch C_EURO_SUM_PO_EXP_DTLS into L_exp_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_PO_EXP_DTLS','ORDLOC_EXP',NULL);
                     close C_EURO_SUM_PO_EXP_DTLS;
                  end if;
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor sums the assessment components of the CVB
                     -- that have a component currency different from the
                     -- primary currency.  As it sums the estimated assessment
                     -- values, it converts the values into the primary currency.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_PO_EXP_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     open C_SUM_PO_EXP_ASSESS_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_PO_EXP_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     fetch C_SUM_PO_EXP_ASSESS_DTLS into L_exp_assess_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_EXP_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     close C_SUM_PO_EXP_ASSESS_DTLS;
                  else --L_currency_code_prim is not 'EUR'--
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_PO_EXP_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     open C_EURO_SUM_PO_EXP_ASSESS_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_PO_EXP_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     fetch C_EURO_SUM_PO_EXP_ASSESS_DTLS into L_exp_assess_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_PO_EXP_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     close C_EURO_SUM_PO_EXP_ASSESS_DTLS;
                  end if;
                  ---
                  -- This cursor sums the assessment components of the CVB
                  -- that have a component currency that is the same as
                  -- the primary currency.  No conversion is needed.
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_PO_EXP_ASSESS_DTLS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  open C_SUM_PO_EXP_ASSESS_DTLS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_PO_EXP_ASSESS_DTLS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  fetch C_SUM_PO_EXP_ASSESS_DTLS_PRIM into L_exp_assess_dtl_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_EXP_ASSESS_DTLS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  close C_SUM_PO_EXP_ASSESS_DTLS_PRIM;
               elsif I_calc_type = 'PA' then
                  ---
                  -- Sum assessment detail components.
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor sums the assessment components of the CVB that
                     -- is attached to the component passed into this function,
                     -- that have a component currency that is different from the primary
                     -- currency.  As it sums the estimated expense values, it
                     -- converts the values into the primary currency.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_PO_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     open C_SUM_PO_ASSESS_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_PO_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     fetch C_SUM_PO_ASSESS_DTLS into L_assess_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     close C_SUM_PO_ASSESS_DTLS;
                  else --L_currency_code_prim is not 'EUR'--
                     ---
                     L_euro_comp_currency := NULL;
                     ---
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_PO_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     open C_EURO_SUM_PO_ASSESS_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_PO_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     fetch C_EURO_SUM_PO_ASSESS_DTLS into L_assess_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_PO_ASSESS_DTLS','ORDSKU_HTS_ASSESS',NULL);
                     close C_EURO_SUM_PO_ASSESS_DTLS;

                  end if;
                  ---
                  -- This cursor sums the expense components of the CVB
                  -- that have a component currency that is the same as
                  -- the primary currency.  No conversion is needed.
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_PO_ASSESS_DTLS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  open C_SUM_PO_ASSESS_DTLS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_PO_ASSESS_DTLS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  fetch C_SUM_PO_ASSESS_DTLS_PRIM into L_assess_dtl_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_ASSESS_DTLS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  close C_SUM_PO_ASSESS_DTLS_PRIM;
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor sums the expense components of the CVB
                     -- that have a component currency different from the
                     -- primary currency.  As it sums the estimated assessment
                     -- values, it converts the values into the primary currency.
                     -- Since assessments are attached at the Order Item header level,
                     -- we do not have the exact location.  Therefore, in this case,
                     -- we sum the estimated values that exist for the all of the
                     -- locations that the item is ordered to and then divide
                     -- by the total qty ordered to get the average.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_PO_ASSESS_EXP_DTLS','ORDLOC_EXP',NULL);
                     open C_SUM_PO_ASSESS_EXP_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_PO_ASSESS_EXP_DTLS','ORDLOC_EXP',NULL);
                     fetch C_SUM_PO_ASSESS_EXP_DTLS into L_assess_exp_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_ASSESS_EXP_DTLS','ORDLOC_EXP',NULL);
                     close C_SUM_PO_ASSESS_EXP_DTLS;
                  else --L_currency_code_prim is not 'EUR'--
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_PO_ASSESS_EXP_DTLS','ORDLOC_EXP',NULL);
                     open C_EURO_SUM_PO_ASSESS_EXP_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_PO_ASSESS_EXP_DTLS','ORDLOC_EXP',NULL);
                     fetch C_EURO_SUM_PO_ASSESS_EXP_DTLS into L_assess_exp_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_PO_ASSESS_EXP_DTLS','ORDLOC_EXP',NULL);
                     close C_EURO_SUM_PO_ASSESS_EXP_DTLS;
                  end if;
                  ---
                  L_assess_exp_dtl_amt := L_assess_exp_dtl_amt/NVL(L_tot_ord_qty, 1);
                  ---
                  -- This cursor sums the assessment components of the CVB
                  -- that have a component currency that is the same as
                  -- the primary currency.  No conversion is needed.
                  -- Since assessments are attached at the Order Item header level,
                  -- we do not have the exact location.  Therefore, in this case,
                  -- we sum the estimated values that exist for the all of the
                  -- locations that the item is ordered to and then divide
                  -- by the total qty ordered to get the average.
                  ---
                  L_assess_exp_dtl_amt_prim := L_assess_exp_dtl_amt_prim/NVL(L_tot_ord_qty, 1);
               end if;
            elsif I_dtl_flag = 'F' then
               if I_calc_type = 'PE' then
                  ---
                  -- Sum expense flag components.
                  ---
                  if L_currency_code_prim = 'EUR' then
                     SQL_LIB.SET_MARK('OPEN','C_SUM_PO_EXP_FLAGS','ORDLOC_EXP',NULL);
                     open C_SUM_PO_EXP_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_PO_EXP_FLAGS','ORDLOC_EXP',NULL);
                     fetch C_SUM_PO_EXP_FLAGS into L_exp_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_EXP_FLAGS','ORDLOC_EXP',NULL);
                     close C_SUM_PO_EXP_FLAGS;
                  else   --L_currency_code_prim is not 'EUR'--
                     SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_PO_EXP_FLAGS','ORDLOC_EXP',NULL);
                     open C_EURO_SUM_PO_EXP_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_PO_EXP_FLAGS','ORDLOC_EXP',NULL);
                     fetch C_EURO_SUM_PO_EXP_FLAGS into L_exp_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_PO_EXP_FLAGS','ORDLOC_EXP',NULL);
                     close C_EURO_SUM_PO_EXP_FLAGS;
                  end if;
                  ---
                  if L_currency_code_prim = 'EUR' then
                     SQL_LIB.SET_MARK('OPEN','C_SUM_PO_EXP_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     open C_SUM_PO_EXP_ASSESS_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_PO_EXP_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     fetch C_SUM_PO_EXP_ASSESS_FLAGS into L_exp_assess_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_EXP_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     close C_SUM_PO_EXP_ASSESS_FLAGS;
                  else   --L_currency_code_prim is not 'EUR'--
                  ---
                     SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_PO_EXP_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     open C_EURO_SUM_PO_EXP_ASSESS_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_PO_EXP_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     fetch C_EURO_SUM_PO_EXP_ASSESS_FLAGS into L_exp_assess_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_PO_EXP_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     close C_EURO_SUM_PO_EXP_ASSESS_FLAGS;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_PO_EXP_ASSESS_FLAGS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  open C_SUM_PO_EXP_ASSESS_FLAGS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_PO_EXP_ASSESS_FLAGS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  fetch C_SUM_PO_EXP_ASSESS_FLAGS_PRIM into L_exp_assess_flag_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_EXP_ASSESS_FLAGS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  close C_SUM_PO_EXP_ASSESS_FLAGS_PRIM;
               elsif I_calc_type = 'PA' then
                  ---
                  -- Sum assessment flag components.
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_PO_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     open C_SUM_PO_ASSESS_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_PO_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     fetch C_SUM_PO_ASSESS_FLAGS into L_assess_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     close C_SUM_PO_ASSESS_FLAGS;
                  else   --L_currency_code_prim is not 'EUR'--
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_PO_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     open C_EURO_SUM_PO_ASSESS_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_PO_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     fetch C_EURO_SUM_PO_ASSESS_FLAGS into L_assess_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_PO_ASSESS_FLAGS','ORDSKU_HTS_ASSESS',NULL);
                     close C_EURO_SUM_PO_ASSESS_FLAGS;

                  end if;
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_PO_ASSESS_FLAGS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  open C_SUM_PO_ASSESS_FLAGS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_PO_ASSESS_FLAGS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  fetch C_SUM_PO_ASSESS_FLAGS_PRIM into L_assess_flag_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_ASSESS_FLAGS_PRIM','ORDSKU_HTS_ASSESS',NULL);
                  close C_SUM_PO_ASSESS_FLAGS_PRIM;
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_PO_ASSESS_EXP_FLAGS','ORDLOC_EXP',NULL);
                     open C_SUM_PO_ASSESS_EXP_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_PO_ASSESS_EXP_FLAGS','ORDLOC_EXP',NULL);
                     fetch C_SUM_PO_ASSESS_EXP_FLAGS into L_assess_exp_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_PO_ASSESS_EXP_FLAGS','ORDLOC_EXP',NULL);
                     close C_SUM_PO_ASSESS_EXP_FLAGS;
                  else   --L_currency_code_prim is not 'EUR'--
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_PO_ASSESS_EXP_FLAGS','ORDLOC_EXP',NULL);
                     open C_EURO_SUM_PO_ASSESS_EXP_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_PO_ASSESS_EXP_FLAGS','ORDLOC_EXP',NULL);
                     fetch C_EURO_SUM_PO_ASSESS_EXP_FLAGS into L_assess_exp_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_PO_ASSESS_EXP_FLAGS','ORDLOC_EXP',NULL);
                     close C_EURO_SUM_PO_ASSESS_EXP_FLAGS;
                  end if;
                  ---
                  L_assess_exp_flag_amt      := L_assess_exp_flag_amt/NVL(L_tot_ord_qty, 1);
                  L_assess_exp_flag_amt_prim := L_assess_exp_flag_amt_prim/NVL(L_tot_ord_qty, 1);
               end if;
            end if;
            ---
            L_amount_sub :=  L_exp_dtl_amt         + L_exp_dtl_amt_prim
                           + L_exp_assess_dtl_amt  + L_exp_assess_dtl_amt_prim
                           + L_exp_flag_amt        + L_exp_flag_amt_prim
                           + L_exp_assess_flag_amt + L_exp_assess_flag_amt_prim
                           + L_assess_dtl_amt      + L_assess_dtl_amt_prim
                           + L_assess_exp_dtl_amt  + L_assess_exp_dtl_amt_prim
                           + L_assess_flag_amt     + L_assess_flag_amt_prim
                           + L_assess_exp_flag_amt + L_assess_exp_flag_amt_prim;
            ---
            if L_counter = 1 then
               -- Add '+' components to the total.
               L_amount := L_amount + L_amount_sub;
            else
               -- Subtract '-' components from the total.
               L_amount := L_amount - L_amount_sub;
            end if;
            ---
            L_counter := L_counter + 1;
         END LOOP;
         ---
         if LP_emu_participating_ind = TRUE then
            ---
            --Convert L_amount from 'EUR' to the primary currency.
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_amount,
                                    'EUR',
                                    L_orig_currency_code_prim,
                                    L_amount,
                                    'C',
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL) = FALSE then
               return FALSE;
            end if;
         end if;
      else  -- L_cvb_code is NULL
         ---
         -- When the component has a 'Calculation Basis' of 'Value', but has no cvb,
         -- the expenses or assessments are based on the Supplier's unit cost or the
         -- Order's unit cost.
         ---
         if I_dtl_flag = 'D' then
            if (I_calc_type = 'PE' and L_cost_basis = 'S') then
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_LOC_UNIT_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
               open C_GET_ITEM_LOC_UNIT_COST;
               SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_LOC_UNIT_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
               fetch C_GET_ITEM_LOC_UNIT_COST into L_amount;
               SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_LOC_UNIT_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
               close C_GET_ITEM_LOC_UNIT_COST;
               ---
               if CURRENCY_SQL.CONVERT_BY_LOCATION(O_error_message,
                                                   L_supplier,
                                                   'V',
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   L_amount,
                                                   L_amount,
                                                   'C',
                                                   NULL,
                                                   NULL) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            if  I_calc_type = 'PA' or
               (I_calc_type = 'PE' and L_cost_basis = 'O') then
               ---
               -- The 'Cost Basis' is '0' (Order unit cost).  Get the
               -- unit cost of the item/location on the order.
               ---
               SQL_LIB.SET_MARK('OPEN','C_GET_ORD_COST','ORDLOC',NULL);
               open C_GET_ORD_COST;
               SQL_LIB.SET_MARK('FETCH','C_GET_ORD_COST','ORDLOC',NULL);
               fetch C_GET_ORD_COST into L_ord_cost;
               SQL_LIB.SET_MARK('CLOSE','C_GET_ORD_COST','ORDLOC',NULL);
               close C_GET_ORD_COST;
               ---
               L_amount := L_ord_cost;
               ---
               if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                                     L_currency_code_ord,
                                                     L_exchange_rate_ord,
                                                     I_order_no) = FALSE then
                  return FALSE;
               end if;
               ---
               -- Convert L_amount from order currency to primary currency.
               ---
               if CURRENCY_SQL.CONVERT(O_error_message,
                                       L_amount,
                                       L_currency_code_ord,
                                       NULL,
                                       L_amount,
                                       'C',
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL) = FALSE then
                  return FALSE;
               end if;
               ---
               if I_pack_item is not NULL then
                  SQL_LIB.SET_MARK('OPEN','C_GET_ITEM_LOC_UNIT_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
                  open C_GET_ITEM_LOC_UNIT_COST;
                  SQL_LIB.SET_MARK('FETCH','C_GET_ITEM_LOC_UNIT_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
                  fetch C_GET_ITEM_LOC_UNIT_COST into L_packitem_amt;
                  SQL_LIB.SET_MARK('CLOSE','C_GET_ITEM_LOC_UNIT_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
                  close C_GET_ITEM_LOC_UNIT_COST;
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_LOC_PACKITEM_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
                  open C_SUM_LOC_PACKITEM_COST;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_LOC_PACKITEM_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
                  fetch C_SUM_LOC_PACKITEM_COST into L_pack_amt;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_LOC_PACKITEM_COST','ITEM_SUPP_COUNTRY_LOC',NULL);
                  close C_SUM_LOC_PACKITEM_COST;
                  ---
                  L_amount := L_amount * (L_packitem_amt/L_pack_amt);
               end if;
            end if;
         end if;
      end if; -- L_cvb_code is not NULL/NULL.
      ---
      -- Calculate the Estimate Expense Value.  When the Calculation Basis is Value, the
      -- expense or assessment is simply a percentage of an amount.
      ---
      O_est_value := L_amount * (L_comp_rate/100);

      if CURRENCY_SQL.CONVERT(O_error_message,
                              O_est_value,
                              NULL,
                              L_comp_currency,
                              O_est_value,
                              'C',
                              NULL,
                              NULL,
                              NULL,
                              NULL) = FALSE then
          return FALSE;
      end if;
   elsif L_calc_basis = 'S' then  -- The expense is a 'Specific' expense.
      if I_dtl_flag = 'D' then
         ---
         -- Get all of the Dimension information.
         ---
         SQL_LIB.SET_MARK('OPEN','C_GET_DIMENSION','ITEM_SUPP_COUNTRY,ITEM_SUPPLIER',NULL);

         open C_GET_DIMENSION;
         SQL_LIB.SET_MARK('FETCH','C_GET_DIMENSION','ITEM_SUPP_COUNTRY,ITEM_SUPPLIER',NULL);
         fetch C_GET_DIMENSION into L_supp_pack_size,
                                    L_case_weight,
                                    L_weight_uom,
                                    L_case_length,
                                    L_case_height,
                                    L_case_width,
                                    L_lwh_uom,
                                    L_case_liquid_volume,
                                    L_liquid_vol_uom;
         SQL_LIB.SET_MARK('CLOSE','C_GET_DIMENSION','ITEM_SUPP_COUNTRY,ITEM_SUPPLIER',NULL);
         close C_GET_DIMENSION;
         ---
         if UOM_SQL.GET_CLASS(O_error_message,
                              L_uom_class,
                              L_per_count_uom) = FALSE then
            return FALSE;
         end if;
         ---
         if L_uom_class in ('QTY') then
            if ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                L_standard_uom,
                                                L_standard_class,
                                                L_per_unit_value,  -- standard UOM conversion factor
                                                I_item,
                                                'N') = FALSE then
               return FALSE;
            end if;
            ---
            if L_per_unit_value is NULL then
               if L_standard_uom <> 'EA' then
                  L_per_unit_value := 0;
                  ---
                  L_unit_of_work := 'Order No. '||to_char(I_order_no)||
                                    ', Item '||I_item||
                                    ', Component '||I_comp_id;
                  ---
                  if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                 SQL_LIB.GET_MESSAGE_TEXT('NO_CONV_FACTOR',
                                                          I_item,
                                                          NULL,
                                                          NULL),
                                                          L_program,
                                                          L_unit_of_work) = FALSE then
                     return FALSE;
                  end if;
               else
                  L_per_unit_value := 1;
               end if;
            end if;
            ---
            L_uom := 'EA';
         elsif L_uom_class = 'PACK' then
            if L_per_count_uom = 'PAL' then
               if SUPP_ITEM_ATTRIB_SQL.GET_PACK_SIZES(O_error_message      ,
                                                      L_ti                 ,
                                                      L_hi                 ,
                                                      L_supp_pack_size     ,
                                                      L_inner_pack_size    ,
                                                      L_pallet_desc        ,
                                                      L_case_desc          ,
                                                      L_inner_desc         ,
                                                      I_item               ,
                                                      I_supplier           ,
                                                      I_origin_country_id  ) = FALSE then
                  return FALSE;
               end if;
               L_pallet_size := L_ti * L_hi;
               L_value := 1 / (L_supp_pack_size * L_pallet_size);
            else
               L_value := 1 / L_supp_pack_size;
            end if;

         elsif L_uom_class = 'MISC' then
            SQL_LIB.SET_MARK('OPEN','C_GET_MISC_VALUE','ITEM_SUPP_UOM', NULL);
            open C_GET_MISC_VALUE;
            SQL_LIB.SET_MARK('FETCH','C_GET_MISC_VALUE','ITEM_SUPP_UOM', NULL);
            fetch C_GET_MISC_VALUE into L_value;
            ---
            if C_GET_MISC_VALUE%NOTFOUND then
               L_value := 0;
               ---
               L_unit_of_work := 'Order No. '||to_char(I_order_no)||
                                 ', Item '||I_item||
                                 ', Component '||I_comp_id;
               ---
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                              SQL_LIB.GET_MESSAGE_TEXT('NO_MISC_CONV_INFO',
                                                       I_item,
                                                       to_char(L_supplier),
                                                       NULL),
                                                       L_program,
                                                       L_unit_of_work) = FALSE then
                  return FALSE;
               end if;
            end if;
            ---
            SQL_LIB.SET_MARK('CLOSE','C_GET_MISC_VALUE','ITEM_SUPP_UOM', NULL);
            close C_GET_MISC_VALUE;
         elsif L_uom_class = 'MASS' then
            if L_case_weight is NULL then
               L_per_unit_value := 0;
               ---
               L_unit_of_work := 'Order No. '||to_char(I_order_no)||
                                 ',Item '||I_item||
                                 ', Component '||I_comp_id;
               ---
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                                       SQL_LIB.GET_MESSAGE_TEXT('NO_WT_INFO',
                                                       I_item,
                                                       to_char(L_supplier),
                                                       L_origin_country_id),
                                                       L_program,
                                                       L_unit_of_work) = FALSE then
                  return FALSE;
               end if;
            else
               L_per_unit_value := L_case_weight/L_supp_pack_size;
               L_uom := L_weight_uom;
            end if;
         elsif L_uom_class = 'VOL' then
            if L_case_length is NULL or L_case_width is NULL or
                    L_case_height is NULL then
               L_per_unit_value := 0;
               ---
               L_unit_of_work := 'Order No. '||to_char(I_order_no)||
                                 ', Item '||I_item||
                                 ', Component '||I_comp_id;
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                              SQL_LIB.GET_MESSAGE_TEXT('NO_DIMEN_INFO',
                                                       I_item,
                                                       to_char(L_supplier),
                                                       L_origin_country_id),
                                                       L_program,
                                                       L_unit_of_work) = FALSE then
                  return FALSE;
               end if;
            else
               ---
               -- Get the per unit ship carton volume.
               ---
               L_per_unit_value := (L_case_length * L_case_height *
                                    L_case_width)/L_supp_pack_size;
               L_uom := L_lwh_uom||'3';
            end if;
         elsif L_uom_class = 'AREA' then
            if L_case_length is NULL or L_case_width is NULL then
               L_per_unit_value := 0;
               ---
               L_unit_of_work := 'Order No. '||to_char(I_order_no)||
                                 ', Item '||I_item||
                                 ', Component '||I_comp_id;
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                              SQL_LIB.GET_MESSAGE_TEXT('NO_DIMEN_INFO',
                                                       I_item,
                                                       to_char(L_supplier),
                                                       L_origin_country_id),
                                                       L_program,
                                                       L_unit_of_work) = FALSE then
                  return FALSE;
               end if;
            else
               ---
               -- Get the per unit ship carton area.
               ---

               L_per_unit_value := (L_case_length *
                                    L_case_width)/L_supp_pack_size;
               L_uom := L_lwh_uom||'2';
            end if;
         elsif L_uom_class = 'DIMEN' then
            if L_case_length is NULL then
               L_per_unit_value := 0;
               ---
               L_unit_of_work := 'Order No. '||to_char(I_order_no)||
                                 ', Item '||I_item||
                                 ', Component '||I_comp_id;
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                              SQL_LIB.GET_MESSAGE_TEXT('NO_DIMEN_INFO',
                                                       I_item,
                                                       to_char(L_supplier),
                                                       L_origin_country_id),
                                                       L_program,
                                                       L_unit_of_work) = FALSE then
                  return FALSE;
               end if;
            else
               ---
               -- Get the per unit ship carton length.
               ---
               L_per_unit_value := L_case_length/L_supp_pack_size;
               ---
               L_uom := L_lwh_uom;
            end if;
         elsif L_uom_class = 'LVOL' then
            if L_case_liquid_volume is NULL then
               L_per_unit_value := 0;
               ---
               L_unit_of_work := 'Order No. '||to_char(I_order_no)||
                                 ', Item '||I_item||
                                 ', Component '||I_comp_id;
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                              SQL_LIB.GET_MESSAGE_TEXT('NO_LVOL_INFO',
                                                       I_item,
                                                       to_char(L_supplier),
                                                       L_origin_country_id),
                                                       L_program,
                                                       L_unit_of_work) = FALSE
               then
                  return FALSE;
               end if;
            else
               ---
               -- Get the per unit liquid volume
               ---
                L_per_unit_value := L_case_liquid_volume/L_supp_pack_size;
                L_uom   := L_liquid_vol_uom;
            end if;
         end if;
         ---
         if L_uom_class in ('VOL','AREA','DIMEN','QTY','MASS','LVOL') then
            if L_per_unit_value <> 0 then
               if UOM_SQL.WITHIN_CLASS(O_error_message,
                                       L_value,
                                       L_per_count_uom,
                                       L_per_unit_value,
                                       L_uom,
                                       L_uom_class) = FALSE then
                  return FALSE;
               end if;
            else
               L_value := 0;
            end if;
         end if;
         ---
         -- Calculate the Estimate Expense Value
         ---
         O_est_value := L_value * (L_comp_rate/L_per_count);

      end if;  -- if I_dtl_flag = 'D'
   end if; -- if calc_basis = 'S' ('Specific')
   ---
   if O_est_value is NULL then
      O_est_value := 0;
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
END RECALC_COMP;
----------------------------------------------------------------------------------------
END ELC_ORDER_SQL;
/

