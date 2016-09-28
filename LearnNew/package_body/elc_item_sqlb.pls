CREATE OR REPLACE PACKAGE BODY ELC_ITEM_SQL AS
----------------------------------------------------------------------------------------
FUNCTION RECALC_COMP(O_error_message     IN OUT VARCHAR2,
                     O_est_value         IN OUT NUMBER,
                     I_dtl_flag          IN     VARCHAR2,
                     I_comp_id           IN     ELC_COMP.COMP_ID%TYPE,
                     I_calc_type         IN     VARCHAR2,
                     I_item              IN     ITEM_MASTER.ITEM%TYPE,
                     I_supplier          IN     SUPS.SUPPLIER%TYPE,
                     I_item_exp_type     IN     ITEM_EXP_HEAD.ITEM_EXP_TYPE%TYPE,
                     I_item_exp_seq      IN     ITEM_EXP_HEAD.ITEM_EXP_SEQ%TYPE,
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

   L_program                   VARCHAR2(62)                           := 'ELC_ITEM_SQL.RECALC_COMP';
   L_oper                      VARCHAR2(1)                            := '+';
   L_counter                   NUMBER;
   L_amount                    NUMBER     := 0;
   L_amount_temp               NUMBER     := 0;
   L_value                     NUMBER                                 := 0;
   L_per_unit_value            NUMBER     := 0;
   ----
   L_exp_dtl_amt               NUMBER     := 0;
   L_exp_dtl_amt_prim          NUMBER     := 0;
   L_exp_dtl_amt_zone          NUMBER     := 0;
   L_exp_dtl_amt_zone_prim     NUMBER     := 0;
   L_exp_dtl_amt_ctry          NUMBER     := 0;
   L_exp_dtl_amt_ctry_prim     NUMBER     := 0;
   L_exp_assess_dtl_amt        NUMBER     := 0;
   L_exp_assess_dtl_amt_prim   NUMBER     := 0;
   L_exp_flag_amt              NUMBER     := 0;
   L_exp_flag_amt_prim         NUMBER     := 0;
   L_exp_flag_amt_zone         NUMBER     := 0;
   L_exp_flag_amt_zone_prim    NUMBER     := 0;
   L_exp_flag_amt_ctry         NUMBER     := 0;
   L_exp_flag_amt_ctry_prim    NUMBER     := 0;
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
   L_calc_basis                ELC_COMP.CALC_BASIS%TYPE;
   L_cvb_code                  CVB_HEAD.CVB_CODE%TYPE;
   L_comp_rate                 ELC_COMP.COMP_RATE%TYPE;
   L_cost_basis                ELC_COMP.COST_BASIS%TYPE;
   L_comp_currency             CURRENCIES.CURRENCY_CODE%TYPE;
   L_per_count                 ELC_COMP.PER_COUNT%TYPE;
   L_per_count_uom             UOM_CLASS.UOM%TYPE;
   L_zone_group_id             COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE;
   L_nom_flag_1                ELC_COMP.NOM_FLAG_1%TYPE;
   L_nom_flag_2                ELC_COMP.NOM_FLAG_1%TYPE;
   L_nom_flag_3                ELC_COMP.NOM_FLAG_1%TYPE;
   L_nom_flag_4                ELC_COMP.NOM_FLAG_1%TYPE;
   L_nom_flag_5                ELC_COMP.NOM_FLAG_1%TYPE;
   L_consolidation_ind         SYSTEM_OPTIONS.CONSOLIDATION_IND%TYPE;
   L_orig_currency_code_prim   CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_code_prim        CURRENCIES.CURRENCY_CODE%TYPE;
   L_currency_rate_prim        CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_currency_code_sup         CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_type             CURRENCY_RATES.EXCHANGE_TYPE%TYPE;
   L_exchange_rate             CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_currency_cost_dec         CURRENCIES.CURRENCY_COST_DEC%TYPE;
   L_vdate                     DATE;
   L_exists                    BOOLEAN;
   L_supplier                  SUPS.SUPPLIER%TYPE;
   L_origin_country_id         COUNTRY.COUNTRY_ID%TYPE;
   L_supp_pack_size            ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;
   L_ship_carton_wt            ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
   L_weight_uom                ITEM_SUPP_COUNTRY_DIM.WEIGHT_UOM%TYPE;
   L_ship_carton_len           ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
   L_ship_carton_hgt           ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
   L_ship_carton_wid           ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
   L_dimension_uom             ITEM_SUPP_COUNTRY_DIM.LWH_UOM%TYPE;
   L_liquid_volume             ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
   L_liquid_volume_uom         ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME_UOM%TYPE;
   L_standard_uom              UOM_CLASS.UOM%TYPE;
   L_uom                       UOM_CLASS.UOM%TYPE;
   L_standard_class            UOM_CLASS.UOM_CLASS%TYPE;
   L_uom_class                 UOM_CLASS.UOM_CLASS%TYPE;
   L_uom_conv_factor           ITEM_MASTER.UOM_CONV_FACTOR%TYPE;
   L_unit_of_work              IF_ERRORS.UNIT_OF_WORK%TYPE;
   L_emu_participating_ind     BOOLEAN;
   L_primary_curr_to_euro_rate CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_euro_comp_currency        CURRENCIES.CURRENCY_CODE%TYPE;
   L_euro_comp_currency_exists VARCHAR2(1) := 'N';
   L_temp                      NUMBER     := 0;

   cursor C_GET_PRIM_CURR_INFO is
      select r.exchange_rate,
             c.currency_cost_dec
        from currencies c,
             currency_rates r
       where c.currency_code  = L_currency_code_prim
         and c.currency_code  = r.currency_code
         and r.exchange_type  = L_exchange_type
         and r.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where cr.exchange_type = L_exchange_type
                                    and cr.currency_code = L_currency_code_prim
                                    and cr.effective_date <= L_vdate);

   cursor C_GET_CVB_FLAGS is
      select nom_flag_1,
             nom_flag_2,
             nom_flag_3,
             nom_flag_4,
             nom_flag_5
        from cvb_head
       where cvb_code = L_cvb_code;

   -------------------------------------------
   -- Item Expense Cursors
   ---

   cursor C_ITEM_EXP_INFO is
      select elc.calc_basis,
             itm.cvb_code,
             itm.comp_rate,
             itm.comp_currency,
             itm.per_count,
             itm.per_count_uom
        from elc_comp elc,
             item_exp_detail itm
       where itm.item          = I_item
         and itm.supplier      = I_supplier
         and itm.item_exp_type = I_item_exp_type
         and itm.item_exp_seq  = I_item_exp_seq
         and itm.comp_id       = I_comp_id
         and itm.comp_id       = elc.comp_id;
   ---
   ---
   cursor C_SUM_EXP_DTLS is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             cvb_detail cd,
             currency_rates c
       where it.item           = I_item
         and it.comp_currency  = c.currency_code
         and it.comp_currency != L_currency_code_prim
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier      = I_supplier
         and it.item_exp_type = I_item_exp_type
         and it.item_exp_seq  = I_item_exp_seq
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;
   ---
   cursor C_EURO_SUM_EXP_DTLS_1 is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             cvb_detail cd,
             currency_rates c
       where it.item          = I_item
         and it.comp_currency = c.currency_code
         and it.comp_currency = L_euro_comp_currency
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier      = I_supplier
         and it.item_exp_type = I_item_exp_type
         and it.item_exp_seq  = I_item_exp_seq
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_EURO_SUM_EXP_DTLS_2 is
      select NVL(SUM(it.est_exp_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_exp_detail it,
             cvb_detail cd,
             currency_rates c,
             euro_exchange_rate euro
       where it.item           = I_item
         and it.comp_currency  = euro.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier      = I_supplier
         and it.item_exp_type = I_item_exp_type
         and it.item_exp_seq  = I_item_exp_seq
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_GET_CURR_DTLS is
      select distinct comp_currency
        from item_exp_detail it,
             cvb_detail cd
       where it.item           = I_item
         and it.supplier       = I_supplier
         and it.item_exp_type  = I_item_exp_type
         and it.item_exp_seq   = I_item_exp_seq
         and it.comp_currency != L_currency_code_prim
         and it.comp_id        = cd.comp_id
         and cd.cvb_code       = L_cvb_code
         and cd.combo_oper     = L_oper;
   ---
   cursor C_SUM_EXP_DTLS_PRIM is
      select NVL(SUM(it.est_exp_value),0)
        from item_exp_detail it,
             cvb_detail cd
       where it.item          = I_item
         and it.comp_currency = L_currency_code_prim
         and it.supplier      = I_supplier
         and it.item_exp_type = I_item_exp_type
         and it.item_exp_seq  = I_item_exp_seq
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;
   ---
   cursor C_SUM_EXP_DTLS_CTRY is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c
       where it.item               = I_item
         and it.comp_currency      = c.currency_code
         and it.comp_currency     != L_currency_code_prim
         and c.exchange_type       = L_exchange_type
         and c.effective_date      = (select max(cr.effective_date)
                                        from currency_rates cr
                                       where cr.currency_code   = it.comp_currency
                                         and cr.exchange_type   = L_exchange_type
                                         and cr.effective_date <= L_vdate)
         and it.supplier           = I_supplier
         and it.item_exp_seq       = ih.item_exp_seq
         and it.item_exp_type      = ih.item_exp_type
         and it.item               = ih.item
         and it.supplier           = ih.supplier
         and ih.origin_country_id  = L_origin_country_id
         and ih.base_exp_ind       = 'Y'
         and ih.item_exp_type      = 'C'
         and it.comp_id            = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper;
   ---
   cursor C_EURO_SUM_EXP_DTLS_CTRY_1 is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c
       where it.item               = I_item
         and it.comp_currency = c.currency_code
         and it.comp_currency = L_euro_comp_currency
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier           = I_supplier
         and it.item_exp_type      = ih.item_exp_type
         and it.item               = ih.item
         and it.supplier           = ih.supplier
         and ih.origin_country_id  = L_origin_country_id
         and it.item_exp_seq       = ih.item_exp_seq
         and ih.base_exp_ind       = 'Y'
         and ih.item_exp_type      = 'C'
         and it.comp_id            = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper;

   cursor C_EURO_SUM_EXP_DTLS_CTRY_2 is
      select NVL(SUM(it.est_exp_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c,
             euro_exchange_rate euro
       where it.item           = I_item
         and it.comp_currency  = euro.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier           = I_supplier
         and it.item_exp_type      = ih.item_exp_type
         and it.item               = ih.item
         and it.supplier           = ih.supplier
         and ih.origin_country_id  = L_origin_country_id
         and it.item_exp_seq       = ih.item_exp_seq
         and ih.base_exp_ind       = 'Y'
         and ih.item_exp_type      = 'C'
         and it.comp_id            = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper;
   ---
   cursor C_GET_CURR_DTLS_CTRY is
      select distinct comp_currency
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd
       where ih.item               = I_item
         and it.supplier           = I_supplier
         and it.item_exp_type      = ih.item_exp_type
         and it.item               = ih.item
         and it.supplier           = ih.supplier
         and ih.origin_country_id  = L_origin_country_id
         and it.item_exp_seq       = ih.item_exp_seq
         and ih.base_exp_ind       = 'Y'
         and ih.item_exp_type      = 'C'
         and it.comp_id            = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper
         and it.comp_currency     != L_currency_code_prim;

   cursor C_SUM_EXP_DTLS_CTRY_PRIM is
      select NVL(SUM(it.est_exp_value),0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd
       where it.item              = I_item
         and it.comp_currency     = L_currency_code_prim
         and it.supplier          = I_supplier
         and it.comp_id           = cd.comp_id
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.origin_country_id = L_origin_country_id
         and ih.base_exp_ind      = 'Y'
         and ih.item_exp_type     = 'C'
         and cd.cvb_code          = L_cvb_code
         and cd.combo_oper        = L_oper;
   ---
   cursor C_SUM_EXP_DTLS_ZONE is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c
       where it.item               = I_item
         and it.comp_currency      = c.currency_code
         and it.comp_currency     != L_currency_code_prim
         and c.exchange_type       = L_exchange_type
         and c.effective_date      = (select max(cr.effective_date)
                                        from currency_rates cr
                                       where cr.currency_code   = it.comp_currency
                                         and cr.exchange_type   = L_exchange_type
                                         and cr.effective_date <= L_vdate)
         and it.supplier           = I_supplier
         and it.item_exp_seq       = ih.item_exp_seq
         and it.item_exp_type      = ih.item_exp_type
         and it.item               = ih.item
         and ih.supplier           = it.supplier
         and ih.base_exp_ind       = 'Y'
         and ih.item_exp_type      = 'Z'
         and it.comp_id            = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper;
   ---
   cursor C_EURO_SUM_EXP_DTLS_ZONE_1 is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c
       where it.item           = I_item
         and it.comp_currency = c.currency_code
         and it.comp_currency = L_euro_comp_currency
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier           = I_supplier
         and it.item_exp_seq       = ih.item_exp_seq
         and it.item_exp_type      = ih.item_exp_type
         and it.item               = ih.item
         and it.supplier           = ih.supplier
         and ih.item_exp_type      = 'Z'
         and ih.base_exp_ind       = 'Y'
         and it.comp_id            = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper;

   cursor C_EURO_SUM_EXP_DTLS_ZONE_2 is
      select NVL(SUM(it.est_exp_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c,
             euro_exchange_rate euro
       where it.item           = I_item
         and it.comp_currency  = euro.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier           = I_supplier
         and it.item_exp_seq       = ih.item_exp_seq
         and it.item_exp_type      = ih.item_exp_type
         and it.item               = ih.item
         and it.supplier           = ih.supplier
         and ih.item_exp_type      = 'Z'
         and ih.base_exp_ind       = 'Y'
         and it.comp_id            = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper;

   cursor C_GET_CURR_DTLS_ZONE is
      select distinct comp_currency
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd
       where ih.item               = I_item
         and it.supplier           = I_supplier
         and it.item_exp_seq       = ih.item_exp_seq
         and it.item_exp_type      = ih.item_exp_type
         and it.item               = ih.item
         and it.supplier           = ih.supplier
         and ih.item_exp_type      = 'Z'
         and ih.base_exp_ind       = 'Y'
         and it.comp_id            = cd.comp_id
         and cd.cvb_code           = L_cvb_code
         and cd.combo_oper         = L_oper
         and it.comp_currency     != L_currency_code_prim;
   ---
   cursor C_SUM_EXP_DTLS_ZONE_PRIM is
      select NVL(SUM(it.est_exp_value),0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd
       where it.item              = I_item
         and it.comp_currency     = L_currency_code_prim
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.item_exp_type     = 'Z'
         and ih.base_exp_ind      = 'Y'
         and it.comp_id           = cd.comp_id
         and cd.cvb_code          = L_cvb_code
         and cd.combo_oper        = L_oper;
   ---
   cursor C_SUM_EXP_ASSESS_DTLS is
      select NVL(SUM(a.est_assess_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_hts_assess a,
             elc_comp e,
             cvb_detail cd,
             currency_rates c
       where a.item           = I_item
         and e.comp_id        = a.comp_id
         and e.comp_currency  = c.currency_code
         and e.comp_currency != L_currency_code_prim
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                   from currency_rates cr
                                  where cr.currency_code   = e.comp_currency
                                    and cr.exchange_type   = L_exchange_type
                                    and cr.effective_date <= L_vdate)
         and a.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;
   ---
   cursor C_EURO_SUM_EXP_ASSESS_DTLS_1 is
      select NVL(SUM(a.est_assess_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_hts_assess a,
             elc_comp e,
             cvb_detail cd,
             currency_rates c
       where a.item            = I_item
         and e.comp_id         = a.comp_id
         and e.comp_currency   = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and a.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_EURO_SUM_EXP_ASSESS_DTLS_2 is
      select NVL(SUM(a.est_assess_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_hts_assess a,
             elc_comp e,
             cvb_detail cd,
             currency_rates c,
             euro_exchange_rate euro
       where a.item           = I_item
         and e.comp_id        = a.comp_id
         and e.comp_currency  = euro.currency_code
         and e.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and a.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_GET_CURR_EA_DTLS is
      select distinct e.comp_currency
        from item_hts_assess it,
             elc_comp e,
             cvb_detail cd
       where it.item          = I_item
         and it.comp_id       = e.comp_id
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper
         and e.comp_currency != L_currency_code_prim;
   ---
   cursor C_SUM_EXP_ASSESS_DTLS_PRIM is
      select NVL(SUM(a.est_assess_value),0)
        from item_hts_assess a,
             elc_comp e,
             cvb_detail cd
       where a.item           = I_item
         and a.comp_id        = e.comp_id
         and e.comp_currency  = L_currency_code_prim
         and a.comp_id        = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;
   ---
   cursor C_SUM_EXP_FLAGS is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             currency_rates c
       where it.item           = I_item
         and it.comp_currency  = c.currency_code
         and it.comp_currency != L_currency_code_prim
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier      = I_supplier
         and it.item_exp_type = I_item_exp_type
         and it.item_exp_seq  = I_item_exp_seq
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_EURO_SUM_EXP_FLAGS_1 is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             currency_rates c
       where it.item          = I_item
         and it.comp_currency = c.currency_code
         and it.comp_currency = L_euro_comp_currency
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier      = I_supplier
         and it.item_exp_type = I_item_exp_type
         and it.item_exp_seq  = I_item_exp_seq
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_EURO_SUM_EXP_FLAGS_2 is
      select NVL(SUM(it.est_exp_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_exp_detail it,
             currency_rates c,
             euro_exchange_rate euro
       where it.item           = I_item
         and it.comp_currency  = euro.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier      = I_supplier
         and it.item_exp_type = I_item_exp_type
         and it.item_exp_seq  = I_item_exp_seq
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_GET_CURR_FLAGS is
      select distinct comp_currency
        from item_exp_detail
       where item           = I_item
         and supplier       = I_supplier
         and item_exp_type  = I_item_exp_type
         and item_exp_seq   = I_item_exp_seq
         and comp_currency != L_currency_code_prim
         and ((L_nom_flag_1   = 'Y' and nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and nom_flag_5 = L_oper));
   ---
   cursor C_SUM_EXP_FLAGS_PRIM is
      select NVL(SUM(it.est_exp_value), 0)
        from item_exp_detail it
       where it.item          = I_item
         and it.comp_currency = L_currency_code_prim
         and it.supplier      = I_supplier
         and it.item_exp_type = I_item_exp_type
         and it.item_exp_seq  = I_item_exp_seq
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_SUM_EXP_FLAGS_ZONE is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c
       where it.item              = I_item
         and it.comp_currency     = c.currency_code
         and it.comp_currency    != L_currency_code_prim
         and c.exchange_type      = L_exchange_type
         and c.effective_date     = (select max(cr.effective_date)
                                       from currency_rates cr
                                       where cr.currency_code   = it.comp_currency
                                         and cr.exchange_type   = L_exchange_type
                                         and cr.effective_date <= L_vdate)
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.item_exp_type     = 'Z'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));

   ---
   cursor C_EURO_SUM_EXP_FLAGS_ZONE_1 is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c
       where it.item          = I_item
         and it.comp_currency = c.currency_code
         and it.comp_currency = L_euro_comp_currency
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.item_exp_type     = 'Z'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_EURO_SUM_EXP_FLAGS_ZONE_2 is
      select NVL(SUM(it.est_exp_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c,
             euro_exchange_rate euro
       where it.item           = I_item
         and it.comp_currency  = euro.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.item_exp_type     = 'Z'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_GET_CURR_FLAGS_ZONE is
      select distinct comp_currency
        from item_exp_detail it,
             item_exp_head ih
       where it.item              = I_item
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.item_exp_type     = 'Z'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper))
         and it.comp_currency    != L_currency_code_prim;
   ---
   cursor C_SUM_EXP_FLAGS_ZONE_PRIM is
      select NVL(SUM(it.est_exp_value), 0)
        from item_exp_detail it,
             item_exp_head ih
       where it.item              = I_item
         and it.comp_currency     = L_currency_code_prim
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.item_exp_type     = 'Z'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_SUM_EXP_FLAGS_CTRY is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c
       where it.item          = I_item
         and it.comp_currency = c.currency_code
         and it.comp_currency = L_currency_code_prim
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.origin_country_id = L_origin_country_id
         and ih.item_exp_type     = 'C'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));

   ---
   cursor C_EURO_SUM_EXP_FLAGS_CTRY_1 is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c
       where it.item          = I_item
         and it.comp_currency = c.currency_code
         and it.comp_currency = L_euro_comp_currency
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.origin_country_id = L_origin_country_id
         and ih.item_exp_type     = 'C'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_EURO_SUM_EXP_FLAGS_CTRY_2 is
      select NVL(SUM(it.est_exp_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c,
             euro_exchange_rate euro
       where it.item           = I_item
         and it.comp_currency  = euro.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.origin_country_id = L_origin_country_id
         and ih.item_exp_type     = 'C'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_GET_CURR_FLAGS_CTRY is
      select distinct comp_currency
        from item_exp_detail it,
             item_exp_head ih
       where it.item              = I_item
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.origin_country_id = L_origin_country_id
         and ih.item_exp_type     = 'C'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper))
         and it.comp_currency    != L_currency_code_prim;
   ---
   cursor C_SUM_EXP_FLAGS_CTRY_PRIM is
      select NVL(SUM(it.est_exp_value), 0)
        from item_exp_detail it,
             item_exp_head ih
       where it.item              = I_item
         and it.comp_currency     = L_currency_code_prim
         and it.supplier          = I_supplier
         and it.item_exp_seq      = ih.item_exp_seq
         and it.item_exp_type     = ih.item_exp_type
         and it.item              = ih.item
         and it.supplier          = ih.supplier
         and ih.origin_country_id = L_origin_country_id
         and ih.item_exp_type     = 'C'
         and ih.base_exp_ind      = 'Y'
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_SUM_EXP_ASSESS_FLAGS is
      select NVL(SUM(it.est_assess_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_hts_assess it,
             elc_comp e,
             currency_rates c
       where it.item           = I_item
         and it.comp_id        = e.comp_id
         and e.comp_currency   = c.currency_code
         and e.comp_currency  != L_currency_code_prim
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = e.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_EURO_SUM_EXP_ASSESS_FLAGS_1 is
      select NVL(SUM(a.est_assess_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_hts_assess a,
             elc_comp e,
             currency_rates c
       where a.item           = I_item
         and e.comp_id        = a.comp_id
         and e.comp_currency  = c.currency_code
         and e.comp_currency  = L_euro_comp_currency
         and c.exchange_type  = L_exchange_type
         and c.effective_date = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = e.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1   = 'Y' and a.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and a.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and a.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and a.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and a.nom_flag_5 = L_oper));

   cursor C_EURO_SUM_EXP_ASSESS_FLAGS_2 is
      select NVL(SUM(a.est_assess_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_hts_assess a,
             elc_comp e,
             currency_rates c,
             euro_exchange_rate euro
       where a.item           = I_item
         and a.comp_id        = e.comp_id
         and e.comp_currency  = euro.currency_code
         and e.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1   = 'Y' and a.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and a.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and a.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and a.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and a.nom_flag_5 = L_oper));

   cursor C_GET_CURR_EA_FLAGS is
      select distinct e.comp_currency
        from item_hts_assess a,
             elc_comp e
       where a.item           = I_item
         and a.comp_id        = e.comp_id
         and e.comp_currency != L_currency_code_prim
         and ((L_nom_flag_1   = 'Y' and a.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and a.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and a.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and a.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and a.nom_flag_5 = L_oper));
   ---
   cursor C_SUM_EXP_ASSESS_FLAGS_PRIM is
      select NVL(SUM(it.est_assess_value), 0)
        from item_hts_assess it,
             elc_comp e
       where it.item          = I_item
         and it.comp_id       = e.comp_id
         and e.comp_currency  = L_currency_code_prim
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));

   -------------------------------------------
   -- Item Assessment Cursors
   -------------------------------------------
   cursor C_ITEM_ASSESS_INFO is
      select elc.calc_basis,
             itm.cvb_code,
             itm.comp_rate,
             elc.comp_currency,
             itm.per_count,
             itm.per_count_uom
        from elc_comp elc,
             item_hts_assess itm
       where itm.item              = I_item
         and itm.hts               = I_hts
         and itm.import_country_id = I_import_country_id
         and itm.origin_country_id = I_origin_country_id
         and itm.effect_from       = I_effect_from
         and itm.effect_to         = I_effect_to
         and itm.comp_id           = I_comp_id
         and itm.comp_id           = elc.comp_id;
   ---
   cursor C_SUM_ASSESS_DTLS is
      select NVL(SUM(it.est_assess_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_hts_assess it,
             elc_comp e,
             cvb_detail cd,
             currency_rates c
       where it.item              = I_item
         and it.hts               = I_hts
         and it.import_country_id = I_import_country_id
         and it.origin_country_id = I_origin_country_id
         and it.effect_from       = I_effect_from
         and it.effect_to         = I_effect_to
         and it.comp_id           = e.comp_id
         and e.comp_currency     != L_currency_code_prim
         and e.comp_currency      = c.currency_code
         and c.exchange_type      = L_exchange_type
         and c.effective_date     = (select max(cr.effective_date)
                                       from currency_rates cr
                                      where cr.currency_code   = e.comp_currency
                                        and cr.exchange_type   = L_exchange_type
                                        and cr.effective_date <= L_vdate)
         and it.comp_id           = cd.comp_id
         and cd.cvb_code          = L_cvb_code
         and cd.combo_oper        = L_oper;

   ---
   cursor C_EURO_SUM_ASSESS_DTLS_1 is
      select NVL(SUM(it.est_assess_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_hts_assess it,
             elc_comp e,
             cvb_detail cd,
             currency_rates c
       where it.item              = I_item
         and it.hts               = I_hts
         and it.import_country_id = I_import_country_id
         and it.origin_country_id = I_origin_country_id
         and it.effect_from       = I_effect_from
         and it.effect_to         = I_effect_to
         and it.comp_id           = e.comp_id
         and e.comp_currency      = c.currency_code
         and e.comp_currency      = L_euro_comp_currency
         and c.exchange_type      = L_exchange_type
         and c.effective_date     = (select max(cr.effective_date)
                                       from currency_rates cr
                                      where cr.currency_code   = e.comp_currency
                                        and cr.exchange_type   = L_exchange_type
                                        and cr.effective_date <= L_vdate)
         and it.comp_id           = cd.comp_id
         and cd.cvb_code          = L_cvb_code
         and cd.combo_oper        = L_oper;

   cursor C_EURO_SUM_ASSESS_DTLS_2 is
      select NVL(SUM(it.est_assess_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_hts_assess it,
             elc_comp e,
             cvb_detail cd,
             currency_rates c,
             euro_exchange_rate euro
       where it.item              = I_item
         and it.hts               = I_hts
         and it.import_country_id = I_import_country_id
         and it.origin_country_id = I_origin_country_id
         and it.effect_from       = I_effect_from
         and it.effect_to         = I_effect_to
         and it.comp_id           = e.comp_id
         and e.comp_currency      = euro.currency_code
         and e.comp_currency      = L_euro_comp_currency
         and c.currency_code      = 'EUR'
         and c.exchange_type      = L_exchange_type
         and c.effective_date     = (select max(cr.effective_date)
                                       from currency_rates cr
                                      where cr.currency_code   = 'EUR'
                                        and cr.exchange_type   = L_exchange_type
                                        and cr.effective_date <= L_vdate)
         and it.comp_id           = cd.comp_id
         and cd.cvb_code          = L_cvb_code
         and cd.combo_oper        = L_oper;

   cursor C_GET_CURR_ASS_DTLS is
      select distinct e.comp_currency
        from item_hts_assess it,
             elc_comp e,
             cvb_detail cd
       where it.item          = I_item
         and it.comp_id       = e.comp_id
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper
         and e.comp_currency != L_currency_code_prim;
   ---
   cursor C_SUM_ASSESS_DTLS_PRIM is
      select NVL(SUM(it.est_assess_value), 0)
        from item_hts_assess it,
             cvb_detail cd
       where it.item              = I_item
         and it.hts               = I_hts
         and it.import_country_id = I_import_country_id
         and it.origin_country_id = I_origin_country_id
         and it.effect_from       = I_effect_from
         and it.effect_to         = I_effect_to
         and it.comp_id           = cd.comp_id
         and L_comp_currency      = L_currency_code_prim
         and cd.cvb_code          = L_cvb_code
         and cd.combo_oper        = L_oper;
   ---
   cursor C_SUM_ASSESS_EXP_DTLS is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c
       where it.item           = I_item
         and ih.supplier       = L_supplier
         and ih.base_exp_ind   = 'Y'
         and it.item           = ih.item
         and it.supplier       = ih.supplier
         and it.item_exp_type  = ih.item_exp_type
         and (ih.item_exp_type = 'Z' or (ih.item_exp_type = 'C'
                                         and ih.origin_country_id = I_origin_country_id))
         and it.item_exp_seq   = ih.item_exp_seq
         and it.comp_currency != L_currency_code_prim
         and it.comp_currency  = c.currency_code
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;
   ---
   cursor C_EURO_SUM_ASSESS_EXP_DTLS_1 is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c
       where it.item           = I_item
         and ih.supplier       = L_supplier
         and ih.base_exp_ind   = 'Y'
         and it.item           = ih.item
         and it.supplier       = ih.supplier
         and it.item_exp_type  = ih.item_exp_type
         and (ih.item_exp_type = 'Z' or (ih.item_exp_type = 'C'
                                         and ih.origin_country_id = I_origin_country_id))
         and it.item_exp_seq   = ih.item_exp_seq
         and it.comp_currency  = c.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_EURO_SUM_ASSESS_EXP_DTLS_2 is
      select NVL(SUM(it.est_exp_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd,
             currency_rates c,
             euro_exchange_rate euro
       where it.item           = I_item
         and ih.supplier       = L_supplier
         and ih.base_exp_ind   = 'Y'
         and it.item           = ih.item
         and it.supplier       = ih.supplier
         and it.item_exp_type  = ih.item_exp_type
         and (ih.item_exp_type = 'Z' or (ih.item_exp_type = 'C'
                                         and ih.origin_country_id = I_origin_country_id))
         and it.item_exp_seq   = ih.item_exp_seq
         and it.comp_currency  = euro.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;

   cursor C_GET_CURR_AE_DTLS is
      select distinct comp_currency
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd
       where it.item           = I_item
         and ih.supplier       = L_supplier
         and ih.base_exp_ind   = 'Y'
         and it.item           = ih.item
         and it.supplier       = ih.supplier
         and it.item_exp_type  = ih.item_exp_type
         and (ih.item_exp_type = 'Z' or (ih.item_exp_type = 'C'
                                         and ih.origin_country_id = I_origin_country_id))
         and it.item_exp_seq   = ih.item_exp_seq
         and it.comp_currency != L_currency_code_prim
         and it.comp_id        = cd.comp_id
         and cd.cvb_code       = L_cvb_code
         and cd.combo_oper     = L_oper;
   ---
   cursor C_SUM_ASSESS_EXP_DTLS_PRIM is
      select NVL(SUM(it.est_exp_value), 0)
        from item_exp_detail it,
             item_exp_head ih,
             cvb_detail cd
       where it.item          = I_item
         and ih.supplier      = L_supplier
         and ih.base_exp_ind  = 'Y'
         and it.item          = ih.item
         and it.supplier      = ih.supplier
         and it.item_exp_type = ih.item_exp_type
         and (ih.item_exp_type = 'Z' or (ih.item_exp_type = 'C'
                                         and ih.origin_country_id = I_origin_country_id))
         and it.item_exp_seq  = ih.item_exp_seq
         and it.comp_currency = L_currency_code_prim
         and it.comp_id       = cd.comp_id
         and cd.cvb_code      = L_cvb_code
         and cd.combo_oper    = L_oper;
   ---
   cursor C_SUM_ASSESS_FLAGS is
      select NVL(SUM(it.est_assess_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_hts_assess it,
             elc_comp e,
             currency_rates c
       where it.item              = I_item
         and it.hts               = I_hts
         and it.import_country_id = I_import_country_id
         and it.origin_country_id = I_origin_country_id
         and it.effect_from       = I_effect_from
         and it.effect_to         = I_effect_to
         and it.comp_id           = e.comp_id
         and e.comp_currency     != L_currency_code_prim
         and e.comp_currency      = c.currency_code
         and c.exchange_type      = L_exchange_type
         and c.effective_date     = (select max(cr.effective_date)
                                       from currency_rates cr
                                      where cr.currency_code   = e.comp_currency
                                        and cr.exchange_type   = L_exchange_type
                                        and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_EURO_SUM_ASSESS_FLAGS_1 is
      select NVL(SUM(it.est_assess_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_hts_assess it,
             elc_comp e,
             currency_rates c
       where it.item              = I_item
         and it.hts               = I_hts
         and it.import_country_id = I_import_country_id
         and it.origin_country_id = I_origin_country_id
         and it.effect_from       = I_effect_from
         and it.effect_to         = I_effect_to
         and it.comp_id           = e.comp_id
         and e.comp_currency   = c.currency_code
         and e.comp_currency   = L_euro_comp_currency
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = e.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_EURO_SUM_ASSESS_FLAGS_2 is
      select NVL(SUM(it.est_assess_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_hts_assess it,
             elc_comp e,
             currency_rates c,
             euro_exchange_rate euro
       where it.item              = I_item
         and it.hts               = I_hts
         and it.import_country_id = I_import_country_id
         and it.origin_country_id = I_origin_country_id
         and it.effect_from       = I_effect_from
         and it.effect_to         = I_effect_to
         and it.comp_id           = e.comp_id
         and e.comp_currency   = euro.currency_code
         and e.comp_currency   = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_GET_CURR_A_FLAGS is
      select distinct comp_currency
        from item_hts_assess it,
             elc_comp e
       where it.item              = I_item
         and it.hts               = I_hts
         and it.import_country_id = I_import_country_id
         and it.origin_country_id = I_origin_country_id
         and it.effect_from       = I_effect_from
         and it.effect_to         = I_effect_to
         and it.comp_id           = e.comp_id
         and e.comp_currency     != L_currency_code_prim
         and ((L_nom_flag_1       = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2     = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3     = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4     = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5     = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_SUM_ASSESS_FLAGS_PRIM is
      select NVL(SUM(est_assess_value), 0)
        from item_hts_assess
       where item              = I_item
         and hts               = I_hts
         and import_country_id = I_import_country_id
         and origin_country_id = I_origin_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and L_comp_currency   = L_currency_code_prim
         and ((L_nom_flag_1    = 'Y' and nom_flag_1 = L_oper)
             or (L_nom_flag_2  = 'Y' and nom_flag_2 = L_oper)
             or (L_nom_flag_3  = 'Y' and nom_flag_3 = L_oper)
             or (L_nom_flag_4  = 'Y' and nom_flag_4 = L_oper)
             or (L_nom_flag_5  = 'Y' and nom_flag_5 = L_oper));
   ---
   cursor C_SUM_ASSESS_EXP_FLAGS is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c
       where it.item           = I_item
         and ih.supplier       = L_supplier
         and ih.base_exp_ind   = 'Y'
         and it.item           = ih.item
         and it.supplier       = ih.supplier
         and it.item_exp_type  = ih.item_exp_type
         and it.item_exp_seq   = ih.item_exp_seq
         and it.comp_currency != L_currency_code_prim
         and it.comp_currency  = c.currency_code
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_EURO_SUM_ASSESS_EXP_FLAGS_1 is
      select NVL(SUM(it.est_exp_value * (L_currency_rate_prim/c.exchange_rate)), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c
       where it.item           = I_item
         and ih.supplier       = L_supplier
         and ih.base_exp_ind   = 'Y'
         and it.item           = ih.item
         and it.supplier       = ih.supplier
         and it.item_exp_type  = ih.item_exp_type
         and it.item_exp_seq   = ih.item_exp_seq
         and it.comp_currency  = c.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = it.comp_currency
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_EURO_SUM_ASSESS_EXP_FLAGS_2 is
      select NVL(SUM(it.est_exp_value/euro.exchange_rate/L_primary_curr_to_euro_rate), 0)
        from item_exp_detail it,
             item_exp_head ih,
             currency_rates c,
             euro_exchange_rate euro
       where it.item           = I_item
         and ih.supplier       = L_supplier
         and ih.base_exp_ind   = 'Y'
         and it.item           = ih.item
         and it.supplier       = ih.supplier
         and it.item_exp_type  = ih.item_exp_type
         and (ih.item_exp_type = 'Z' or (ih.item_exp_type = 'C'
                                         and ih.origin_country_id = I_origin_country_id))
         and it.item_exp_seq   = ih.item_exp_seq
         and it.comp_currency  = euro.currency_code
         and it.comp_currency  = L_euro_comp_currency
         and c.currency_code   = 'EUR'
         and c.exchange_type   = L_exchange_type
         and c.effective_date  = (select max(cr.effective_date)
                                    from currency_rates cr
                                   where cr.currency_code   = 'EUR'
                                     and cr.exchange_type   = L_exchange_type
                                     and cr.effective_date <= L_vdate)
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));

   cursor C_GET_CURR_AE_FLAGS is
      select distinct comp_currency
        from item_exp_detail it,
             item_exp_head ih
       where it.item           = I_item
         and ih.supplier       = L_supplier
         and ih.base_exp_ind   = 'Y'
         and it.item           = ih.item
         and it.supplier       = ih.supplier
         and it.item_exp_type  = ih.item_exp_type
         and (ih.item_exp_type = 'Z' or (ih.item_exp_type = 'C'
                                         and ih.origin_country_id = I_origin_country_id))
         and it.item_exp_seq   = ih.item_exp_seq
         and it.comp_currency != L_currency_code_prim
         and ((L_nom_flag_1   = 'Y' and it.nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and it.nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and it.nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and it.nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and it.nom_flag_5 = L_oper));
   ---
   cursor C_SUM_ASSESS_EXP_FLAGS_PRIM is
      select NVL(SUM(it.est_exp_value), 0)
        from item_exp_detail it,
             item_exp_head ih
       where it.item          = I_item
         and ih.supplier      = L_supplier
         and ih.base_exp_ind  = 'Y'
         and it.item          = ih.item
         and it.supplier      = ih.supplier
         and it.item_exp_type = ih.item_exp_type
         and it.item_exp_seq  = ih.item_exp_seq
         and it.comp_currency = L_currency_code_prim
         and ((L_nom_flag_1   = 'Y' and nom_flag_1 = L_oper)
             or (L_nom_flag_2 = 'Y' and nom_flag_2 = L_oper)
             or (L_nom_flag_3 = 'Y' and nom_flag_3 = L_oper)
             or (L_nom_flag_4 = 'Y' and nom_flag_4 = L_oper)
             or (L_nom_flag_5 = 'Y' and nom_flag_5 = L_oper));

   -------------------------------------------
   -- General Information Cursors
   -------------------------------------------
   cursor C_SUPPLIER is
      select i.supplier
        from item_supp_country i
       where i.item               = I_item
         and i.origin_country_id  = I_origin_country_id
         and (i.primary_supp_ind  = 'Y'
              or not exists (select 'x'
                               from item_supp_country s
                              where s.origin_country_id = I_origin_country_id
                                and s.item              = I_item
                                and s.primary_supp_ind  = 'Y'));

   cursor C_GET_UNIT_COST is
      select unit_cost
        from item_supp_country
       where item       = I_item
         and ((supplier = L_supplier
               and L_supplier is not NULL)
          or (primary_supp_ind = 'Y'
              and L_supplier is NULL))
         and ((origin_country_id = L_origin_country_id
               and L_origin_country_id is not NULL)
          or (primary_country_ind = 'Y'
              and L_origin_country_id is NULL));

   cursor C_GET_DIMENSION is
      select i.supp_pack_size,
             id.weight,
             id.weight_uom,
             id.length,
             id.height,
             id.width,
             id.lwh_uom,
             id.liquid_volume,
             id.liquid_volume_uom
       from  item_supp_country i,item_supp_country_dim id
       where i.item = id.item
       and   i.supplier = id.supplier
       and   i.origin_country_id = id.origin_country
       and   id.dim_object = 'CA'
       and   i.item       = I_item
         and ((i.supplier = L_supplier
               and L_supplier is not NULL)
          or (i.primary_supp_ind = 'Y'
              and L_supplier is NULL))
         and ((i.origin_country_id = L_origin_country_id
               and L_origin_country_id is not NULL)
          or (i.primary_country_ind = 'Y'
              and L_origin_country_id is NULL));

   cursor C_GET_MISC_VALUE is
      select value
        from item_supp_uom
       where item     = I_item
         and supplier = L_supplier
         and uom      = L_per_count_uom;

   cursor C_EURO_COMP_CURR_EXISTS is
      select 'Y'
        from euro_exchange_rate
       where currency_code = L_euro_comp_currency;

BEGIN

   O_est_value         := 0;
   L_origin_country_id := I_origin_country_id;
   L_supplier          := I_supplier;
   ---
   L_vdate             := GET_VDATE;
   ---
   if SYSTEM_OPTIONS_SQL.CONSOLIDATION_IND(O_error_message,
                                           L_consolidation_ind) = FALSE then
      return FALSE;
   end if;
   ---
   if L_consolidation_ind = 'Y' then
      L_exchange_type := 'C';
   else
      L_exchange_type := 'O';
   end if;
   ---
   if SYSTEM_OPTIONS_SQL.CURRENCY_CODE(O_error_message,
                                       L_currency_code_prim) = FALSE then
      return FALSE;
   end if;
   ---
   --Check if L_currency_code_prim is EMU member.
   ---
   if CURRENCY_SQL.CHECK_EMU_COUNTRIES(O_error_message,
                                       L_emu_participating_ind,
                                       L_currency_code_prim) = FALSE then
      return FALSE;
   end if;
   ---
   --Set the original primary currency code for final currency conversion.
   ---
   L_orig_currency_code_prim := L_currency_code_prim;
   ---
   --Set currency code to 'EUR' for EMU members.
   ---
   if L_emu_participating_ind = TRUE then
      L_currency_code_prim := 'EUR';
   end if;
   ---
   -- Get the primary currency information to be used to convert the estimated values
   -- in the cursors as they are summed together.
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_PRIM_CURR_INFO','CURRENCIES, CURRENCY_RATES',NULL);
   open C_GET_PRIM_CURR_INFO;
   SQL_LIB.SET_MARK('FETCH','C_GET_PRIM_CURR_INFO','CURRENCIES, CURRENCY_RATES',NULL);
   fetch C_GET_PRIM_CURR_INFO into L_currency_rate_prim,
                                   L_currency_cost_dec;
   if C_GET_PRIM_CURR_INFO%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_CURR_INFO_FOUND',L_currency_code_prim,NULL,NULL);
      SQL_LIB.SET_MARK('CLOSE','C_GET_PRIM_CURR_INFO','CURRENCIES, CURRENCY_RATES',NULL);
      close C_GET_PRIM_CURR_INFO;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_GET_PRIM_CURR_INFO','CURRENCIES, CURRENCY_RATES',NULL);
   close C_GET_PRIM_CURR_INFO;
   ---
   --Retrieve the 'EUR' exchange rate if the primary currency is not one of the EMU
   --countries.
   ---
   if L_currency_code_prim != 'EUR' then
      if CURRENCY_SQL.GET_RATE(O_error_message,
                               L_primary_curr_to_euro_rate,
                               'EUR',
                               L_consolidation_ind,
                               L_vdate) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if I_calc_type = 'IE' then
      if I_supplier is NULL then
         if SUPP_ITEM_ATTRIB_SQL.GET_PRIMARY_SUPP(O_error_message,
                                                  L_exists,
                                                  L_supplier,
                                                  I_item) = FALSE then

            return FALSE;
         end if;
      end if;
      ---
      if I_item_exp_type = 'Z' then
         if SUPP_ITEM_ATTRIB_SQL.GET_PRIMARY_COUNTRY(O_error_message,
                                                     L_origin_country_id,
                                                     I_item,
                                                     L_supplier) = FALSE then
            return FALSE;
         end if;
      end if;
   elsif I_calc_type = 'IA' then
      SQL_LIB.SET_MARK('OPEN','C_SUPPLIER','ITEM_SUPP_COUNTRY',
                       'Item: ' ||I_item ||
                       ' Origin Country: ' || I_origin_country_id);
      open C_SUPPLIER;
      SQL_LIB.SET_MARK('FETCH','C_SUPPLIER','ITEM_SUPP_COUNTRY',
                       'Item: ' ||I_item ||
                       ' Origin Country: ' || I_origin_country_id);
      fetch C_SUPPLIER into L_supplier;
      if C_SUPPLIER%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_SUPPLIER','ITEM_SUPP_COUNTRY',
                          'Item: ' ||I_item ||
                          ' Origin Country: ' || I_origin_country_id);
         close C_SUPPLIER;
         O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_ORIGIN_REC',I_origin_country_id,NULL,NULL);
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_SUPPLIER','ITEM_SUPP_COUNTRY',
                       'Item: ' ||I_item ||
                       ' Origin Country: ' || I_origin_country_id);
      close C_SUPPLIER;
   end if;
   ---
   if I_calc_type = 'IE' then
      SQL_LIB.SET_MARK('OPEN','C_ITEM_EXP_INFO','ITEM_EXP_DETAIL',NULL);
      open C_ITEM_EXP_INFO;
      SQL_LIB.SET_MARK('FETCH','C_ITEM_EXP_INFO','ITEM_EXP_DETAIL',NULL);
      fetch C_ITEM_EXP_INFO into L_calc_basis,
                                 L_cvb_code,
                                 L_comp_rate,
                                 L_comp_currency,
                                 L_per_count,
                                 L_per_count_uom;
      if C_ITEM_EXP_INFO%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_COMP',NULL,NULL,NULL);
         SQL_LIB.SET_MARK('CLOSE','C_ITEM_EXP_INFO','ITEM_EXP_DETAIL',NULL);
         close C_ITEM_EXP_INFO;
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_ITEM_EXP_INFO','ITEM_EXP_DETAIL',NULL);
      close C_ITEM_EXP_INFO;

   elsif I_calc_type = 'IA' then
      ---
      SQL_LIB.SET_MARK('OPEN','C_ITEM_ASSESS_INFO','ITEM_HTS_ASSESS',NULL);
      open C_ITEM_ASSESS_INFO;
      SQL_LIB.SET_MARK('FETCH','C_ITEM_ASSESS_INFO','ITEM_HTS_ASSESS',NULL);
      fetch C_ITEM_ASSESS_INFO into L_calc_basis,
                                    L_cvb_code,
                                    L_comp_rate,
                                    L_comp_currency,
                                    L_per_count,
                                    L_per_count_uom;
      if C_ITEM_ASSESS_INFO%NOTFOUND then
         O_error_message := SQL_LIB.CREATE_MSG('INV_COMP',NULL,NULL,NULL);
         SQL_LIB.SET_MARK('CLOSE','C_ITEM_ASSESS_INFO','ITEM_HTS_ASSESS',NULL);
         close C_ITEM_ASSESS_INFO;
         return FALSE;
      end if;
      SQL_LIB.SET_MARK('CLOSE','C_ITEM_ASSESS_INFO','ITEM_HTS_ASSESS',NULL);
      close C_ITEM_ASSESS_INFO;
      ---
   end if;
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
         ---
         L_counter := 1;
         ---
         LOOP
            EXIT when L_counter = 3;
            ---
            if L_counter = 1 then
               L_oper := '+';
            else
               L_oper := '-';
            end if;
            ---
            if I_dtl_flag = 'D' then
               ---
               -- Sum '+' expense detail components.
               ---
               if I_calc_type = 'IE' then

                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor sums the expense components of the CVB that
                     -- is attached to the component passed into this function,
                     -- that have a component currency that is different from the primary
                     -- currency.  As it sums the estimated expense values, it
                     -- converts the values into the primary currency.
                     -- If the primary currency is an EMU member, this cursor will then
                     -- sum all expenses for all countries, including the member country.
                     -- 'EUR' values will not be summed and will be considered to be the
                     -- primary currency.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_DTLS','ITEM_EXP_DETAIL',NULL);
                     open C_SUM_EXP_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_DTLS','ITEM_EXP_DETAIL',NULL);
                     fetch C_SUM_EXP_DTLS into L_exp_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_DTLS','ITEM_EXP_DETAIL',NULL);
                     close C_SUM_EXP_DTLS;
                     ---
                  else  --L_currency_code_prim is not 'EUR'--
                     ---
                     -- This cursor sums the expense components of the CVB that
                     -- is attached to the component passed into this function,
                     -- that have a component currency that is different from the primary
                     -- currency.  As it sums the estimated expense values, it
                     -- converts the values into the primary currency.
                     -- This cursor sums both EMU countries and non-EMU countries.
                     ---
                     L_exp_dtl_amt := 0;
                     ---
                     for Curr_rec in C_GET_CURR_DTLS loop
                        L_euro_comp_currency := Curr_rec.comp_currency;
                        ---
                        L_euro_comp_currency_exists := 'N';
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        open C_EURO_COMP_CURR_EXISTS;
                        SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                        SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        close C_EURO_COMP_CURR_EXISTS;
                        ---
                        L_temp := 0;
                        ---
                        if L_euro_comp_currency_exists = 'Y' then
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_DTLS_2','ITEM_EXP_DETAIL',NULL);
                           open C_EURO_SUM_EXP_DTLS_2;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_DTLS_2','ITEM_EXP_DETAIL',NULL);
                           fetch C_EURO_SUM_EXP_DTLS_2 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_DTLS_2','ITEM_EXP_DETAIL',NULL);
                           close C_EURO_SUM_EXP_DTLS_2;
                        else
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_DTLS_1','ITEM_EXP_DETAIL',NULL);
                           open C_EURO_SUM_EXP_DTLS_1;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_DTLS_1','ITEM_EXP_DETAIL',NULL);
                           fetch C_EURO_SUM_EXP_DTLS_1 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_DTLS_1','ITEM_EXP_DETAIL',NULL);
                           close C_EURO_SUM_EXP_DTLS_1;
                        end if;
                        ---
                        L_exp_dtl_amt := L_exp_dtl_amt + L_temp;
                     end loop;
                  end if;
                  ---
                  -- This cursor sums the expense components of the CVB
                  -- that have a component currency that is the same as
                  -- the primary currency.  No conversion is needed.
                  -- If the primary currency is an EMU member, 'EUR' will be considered
                  -- the primary currency.
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_DTLS_PRIM','ITEM_EXP_DETAIL',NULL);
                  open C_SUM_EXP_DTLS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_DTLS_PRIM','ITEM_EXP_DETAIL',NULL);
                  fetch C_SUM_EXP_DTLS_PRIM into L_exp_dtl_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_DTLS_PRIM','ITEM_EXP_DETAIL',NULL);
                  close C_SUM_EXP_DTLS_PRIM;
                  ---
                  -- The following cursors are being called to retrieve expense values of the opposite
                  -- item expense type to be used in the calculation of the current component.  Zone level
                  -- expenses may be based on country level expenses and vice versa...
                  ---
                  if I_item_exp_type = 'Z' and I_comp_id <> 'TEXPZ' then
                     if L_currency_code_prim = 'EUR' then
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_DTLS_CTRY','ITEM_EXP_DETAIL',NULL);
                        open C_SUM_EXP_DTLS_CTRY;
                        SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_DTLS_CTRY','ITEM_EXP_DETAIL',NULL);
                        fetch C_SUM_EXP_DTLS_CTRY into L_exp_dtl_amt_ctry;
                        SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_DTLS_CTRY','ITEM_EXP_DETAIL',NULL);
                        close C_SUM_EXP_DTLS_CTRY;
                        ---
                     else  --L_currency_code_prim is not 'EUR'--
                        ---
                        L_exp_dtl_amt_ctry := 0;
                        ---
                        for Curr_rec in C_GET_CURR_DTLS_CTRY loop
                           L_euro_comp_currency := Curr_rec.comp_currency;
                           ---
                           L_euro_comp_currency_exists := 'N';
                           ---
                           SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           open C_EURO_COMP_CURR_EXISTS;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           close C_EURO_COMP_CURR_EXISTS;
                           ---
                           L_temp := 0;
                           ---
                           if L_euro_comp_currency_exists = 'Y' then
                              SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_DTLS_CTRY_2','ITEM_EXP_DETAIL',NULL);
                              open C_EURO_SUM_EXP_DTLS_CTRY_2;
                              SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_DTLS_CTRY_2','ITEM_EXP_DETAIL',NULL);
                              fetch C_EURO_SUM_EXP_DTLS_CTRY_2 into L_temp;
                              SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_DTLS_CTRY_2','ITEM_EXP_DETAIL',NULL);
                              close C_EURO_SUM_EXP_DTLS_CTRY_2;
                           else
                              SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_DTLS_CTRY_1','ITEM_EXP_DETAIL',NULL);
                              open C_EURO_SUM_EXP_DTLS_CTRY_1;
                              SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_DTLS_CTRY_1','ITEM_EXP_DETAIL',NULL);
                              fetch C_EURO_SUM_EXP_DTLS_CTRY_1 into L_temp;
                              SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_DTLS_CTRY_1','ITEM_EXP_DETAIL',NULL);
                              close C_EURO_SUM_EXP_DTLS_CTRY_1;
                           end if;
                           ---
                           L_exp_dtl_amt_ctry := L_exp_dtl_amt_ctry + L_temp;
                        end loop;
                     end if;
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_DTLS_CTRY_PRIM','ITEM_EXP_DETAIL',NULL);
                     open C_SUM_EXP_DTLS_CTRY_PRIM;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_DTLS_CTRY_PRIM','ITEM_EXP_DETAIL',NULL);
                     fetch C_SUM_EXP_DTLS_CTRY_PRIM into L_exp_dtl_amt_ctry_prim;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_DTLS_CTRY_PRIM','ITEM_EXP_DETAIL',NULL);
                     close C_SUM_EXP_DTLS_CTRY_PRIM;
                     ---
                  elsif I_item_exp_type = 'C' and I_comp_id <> 'TEXPC' then
                     if L_currency_code_prim = 'EUR' then
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_DTLS_ZONE','ITEM_EXP_DETAIL',NULL);
                        open C_SUM_EXP_DTLS_ZONE;
                        SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_DTLS_ZONE','ITEM_EXP_DETAIL',NULL);
                        fetch C_SUM_EXP_DTLS_ZONE into L_exp_dtl_amt_zone;
                        SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_DTLS_ZONE','ITEM_EXP_DETAIL',NULL);
                        close C_SUM_EXP_DTLS_ZONE;
                        ---
                     else  --L_currency_code_prim is not 'EUR'--
                        ---
                        L_exp_dtl_amt_zone := 0;
                        ---
                        for Curr_rec in C_GET_CURR_DTLS_ZONE loop
                           L_euro_comp_currency := Curr_rec.comp_currency;
                           ---
                           L_euro_comp_currency_exists := 'N';
                           ---
                           SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           open C_EURO_COMP_CURR_EXISTS;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           close C_EURO_COMP_CURR_EXISTS;
                           ---
                           L_temp := 0;
                           ---
                           if L_euro_comp_currency_exists = 'Y' then
                              SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_DTLS_ZONE_2','ITEM_EXP_DETAIL',NULL);
                              open C_EURO_SUM_EXP_DTLS_ZONE_2;
                              SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_DTLS_ZONE_2','ITEM_EXP_DETAIL',NULL);
                              fetch C_EURO_SUM_EXP_DTLS_ZONE_2 into L_temp;
                              SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_DTLS_ZONE_2','ITEM_EXP_DETAIL',NULL);
                              close C_EURO_SUM_EXP_DTLS_ZONE_2;
                           else
                              SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_DTLS_ZONE_1','ITEM_EXP_DETAIL',NULL);
                              open C_EURO_SUM_EXP_DTLS_ZONE_1;
                              SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_DTLS_ZONE_1','ITEM_EXP_DETAIL',NULL);
                              fetch C_EURO_SUM_EXP_DTLS_ZONE_1 into L_temp;
                              SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_DTLS_ZONE_1','ITEM_EXP_DETAIL',NULL);
                              close C_EURO_SUM_EXP_DTLS_ZONE_1;
                           end if;
                           ---
                           L_exp_dtl_amt_zone := L_exp_dtl_amt_zone + L_temp;
                        end loop;
                     end if;
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_DTLS_ZONE_PRIM','ITEM_EXP_DETAIL',NULL);
                     open C_SUM_EXP_DTLS_ZONE_PRIM;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_DTLS_ZONE_PRIM','ITEM_EXP_DETAIL',NULL);
                     fetch C_SUM_EXP_DTLS_ZONE_PRIM into L_exp_dtl_amt_zone_prim;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_DTLS_ZONE_PRIM','ITEM_EXP_DETAIL',NULL);
                     close C_SUM_EXP_DTLS_ZONE_PRIM;
                  end if;
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor sums the assessment components of the CVB
                     -- that have a component currency different from the
                     -- primary currency.  As it sums the estimated assessment
                     -- values, it converts the values into the primary currency.
                     -- If the primary currency is an EMU member, this cursor will then
                     -- sum all expenses for all countries, including the member country.
                     -- 'EUR' values will not be summed and will be considered to be the
                     -- primary currency.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_ASSESS_DTLS','ITEM_HTS_ASSESS',NULL);
                     open C_SUM_EXP_ASSESS_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_ASSESS_DTLS','ITEM_HTS_ASSESS',NULL);
                     fetch C_SUM_EXP_ASSESS_DTLS into L_exp_assess_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_ASSESS_DTLS','ITEM_HTS_ASSESS',NULL);
                     close C_SUM_EXP_ASSESS_DTLS;
                     ---
                  else  --L_currency_code_prim is not 'EUR'--
                     ---
                     -- This cursor sums the assessment components of the CVB
                     -- that have a component currency different from the
                     -- primary currency.  As it sums the estimated assessment
                     -- values, it converts the values into the primary currency.
                     -- This cursor sums both EMU countries and non-EMU countries.
                     ---
                     L_exp_assess_dtl_amt := 0;
                     ---
                     for Curr_rec in C_GET_CURR_EA_DTLS loop
                        L_euro_comp_currency := Curr_rec.comp_currency;
                        ---
                        L_euro_comp_currency_exists := 'N';
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        open C_EURO_COMP_CURR_EXISTS;
                        SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                        SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        close C_EURO_COMP_CURR_EXISTS;
                        ---
                        L_temp := 0;
                        ---
                        if L_euro_comp_currency_exists = 'Y' then
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_ASSESS_DTLS_2','ITEM_HTS_ASSESS',NULL);
                           open C_EURO_SUM_EXP_ASSESS_DTLS_2;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_ASSESS_DTLS_2','ITEM_HTS_ASSESS',NULL);
                           fetch C_EURO_SUM_EXP_ASSESS_DTLS_2 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_ASSESS_DTLS_2','ITEM_HTS_ASSESS',NULL);
                           close C_EURO_SUM_EXP_ASSESS_DTLS_2;
                        else
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_ASSESS_DTLS_1','ITEM_HTS_ASSESS',NULL);
                           open C_EURO_SUM_EXP_ASSESS_DTLS_1;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_ASSESS_DTLS_1','ITEM_HTS_ASSESS',NULL);
                           fetch C_EURO_SUM_EXP_ASSESS_DTLS_1 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_ASSESS_DTLS_1','ITEM_HTS_ASSESS',NULL);
                           close C_EURO_SUM_EXP_ASSESS_DTLS_1;
                        end if;
                        ---
                        L_exp_assess_dtl_amt := L_exp_assess_dtl_amt + L_temp;
                     end loop;
                  end if;
                  ---
                  -- This cursor sums the assessment components of the CVB
                  -- that have a component currency that is the same as
                  -- the primary currency.  No conversion is needed.
                  -- If the primary currency is an EMU member, 'EUR' will be considered
                  -- the primary currency.
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_ASSESS_DTLS_PRIM','ITEM_HTS_ASSESS',NULL);
                  open C_SUM_EXP_ASSESS_DTLS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_ASSESS_DTLS_PRIM','ITEM_HTS_ASSESS',NULL);
                  fetch C_SUM_EXP_ASSESS_DTLS_PRIM into L_exp_assess_dtl_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_ASSESS_DTLS_PRIM','ITEM_HTS_ASSESS',NULL);
                  close C_SUM_EXP_ASSESS_DTLS_PRIM;

               elsif I_calc_type = 'IA' then
                  ---
                  -- Sum '+' assessment detail components.
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor sums the assessment components of the CVB that
                     -- is attached to the component passed into this function,
                     -- that have a component currency that is different from the primary
                     -- currency.  As it sums the estimated expense values, it
                     -- converts the values into the primary currency.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS_DTLS','ITEM_HTS_ASSESS',NULL);
                     open C_SUM_ASSESS_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS_DTLS','ITEM_HTS_ASSESS',NULL);
                     fetch C_SUM_ASSESS_DTLS into L_assess_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS_DTLS','ITEM_HTS_ASSESS',NULL);
                     close C_SUM_ASSESS_DTLS;
                     ---
                  else   --L_currency_code_prim != 'EUR'--
                     ---
                     -- This cursor sums the assessment components of the CVB that
                     -- is attached to the component passed into this function,
                     -- that have a component currency that is different from the primary
                     -- currency.  As it sums the estimated expense values, it
                     -- converts the values into the primary currency.
                     ---
                     L_assess_dtl_amt := 0;
                     ---
                     for Curr_rec in C_GET_CURR_ASS_DTLS loop
                        L_euro_comp_currency := Curr_rec.comp_currency;
                        ---
                        L_euro_comp_currency_exists := 'N';
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        open C_EURO_COMP_CURR_EXISTS;
                        SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                        SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        close C_EURO_COMP_CURR_EXISTS;
                        ---
                        L_temp := 0;
                        ---
                        if L_euro_comp_currency_exists = 'Y' then
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_ASSESS_DTLS_2','ITEM_HTS_ASSESS',NULL);
                           open C_EURO_SUM_EXP_ASSESS_DTLS_2;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_ASSESS_DTLS_2','ITEM_HTS_ASSESS',NULL);
                           fetch C_EURO_SUM_EXP_ASSESS_DTLS_2 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_ASSESS_DTLS_2','ITEM_HTS_ASSESS',NULL);
                           close C_EURO_SUM_EXP_ASSESS_DTLS_2;
                        else
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_ASSESS_DTLS_1','ITEM_HTS_ASSESS',NULL);
                           open C_EURO_SUM_ASSESS_DTLS_1;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_ASSESS_DTLS_1','ITEM_HTS_ASSESS',NULL);
                           fetch C_EURO_SUM_ASSESS_DTLS_1 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_ASSESS_DTLS_1','ITEM_HTS_ASSESS',NULL);
                           close C_EURO_SUM_ASSESS_DTLS_1;
                        end if;
                        ---
                        L_assess_dtl_amt := L_assess_dtl_amt + L_temp;
                     end loop;
                  end if;
                  ---
                  -- This cursor sums the expense components of the CVB
                  -- that have a component currency that is the same as
                  -- the primary currency.  No conversion is needed.
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS_DTLS_PRIM','ITEM_HTS_ASSESS',NULL);
                  open C_SUM_ASSESS_DTLS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS_DTLS_PRIM','ITEM_HTS_ASSESS',NULL);
                  fetch C_SUM_ASSESS_DTLS_PRIM into L_assess_dtl_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS_DTLS_PRIM','ITEM_HTS_ASSESS',NULL);
                  close C_SUM_ASSESS_DTLS_PRIM;
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor sums the expense components of the CVB
                     -- that have a component currency different from the
                     -- primary currency.  As it sums the estimated assessment
                     -- values, it converts the values into the primary currency.
                     -- Since assessments are attached at the Item header level,
                     -- we do not have all of the specific information such as
                     -- a supplier, a lading port, a discharge port, or a zone.
                     -- Therefore, in this case, we sum the expenses that exist for
                     -- the primary supplier, and the 'Base' set of expenses.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS_EXP_DTLS','ITEM_EXP_DETAIL',NULL);
                     open C_SUM_ASSESS_EXP_DTLS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS_EXP_DTLS','ITEM_EXP_DETAIL',NULL);
                     fetch C_SUM_ASSESS_EXP_DTLS into L_assess_exp_dtl_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS_EXP_DTLS','ITEM_EXP_DETAIL',NULL);
                     close C_SUM_ASSESS_EXP_DTLS;
                     ---
                  else  --L_currency_code_prim != 'EUR'--
                     ---
                     L_assess_exp_dtl_amt := 0;
                     ---
                     for Curr_rec in C_GET_CURR_AE_DTLS loop
                        L_euro_comp_currency := Curr_rec.comp_currency;
                        ---
                        L_euro_comp_currency_exists := 'N';
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        open C_EURO_COMP_CURR_EXISTS;
                        SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                        SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        close C_EURO_COMP_CURR_EXISTS;
                        ---
                        L_temp := 0;
                        ---
                        if L_euro_comp_currency_exists = 'Y' then
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_ASSESS_EXP_DTLS_2','ITEM_EXP_DETAIL',NULL);
                           open C_EURO_SUM_ASSESS_EXP_DTLS_2;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_ASSESS_EXP_DTLS_2','ITEM_EXP_DETAIL',NULL);
                           fetch C_EURO_SUM_ASSESS_EXP_DTLS_2 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_ASSESS_EXP_DTLS_2','ITEM_EXP_DETAIL',NULL);
                           close C_EURO_SUM_ASSESS_EXP_DTLS_2;
                        else
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_ASSESS_EXP_DTLS_1','ITEM_EXP_DETAIL',NULL);
                           open C_EURO_SUM_ASSESS_EXP_DTLS_1;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_ASSESS_EXP_DTLS_1','ITEM_EXP_DETAIL',NULL);
                           fetch C_EURO_SUM_ASSESS_EXP_DTLS_1 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_ASSESS_EXP_DTLS_1','ITEM_EXP_DETAIL',NULL);
                           close C_EURO_SUM_ASSESS_EXP_DTLS_1;
                        end if;
                        ---
                        L_assess_exp_dtl_amt := L_assess_exp_dtl_amt + L_temp;
                     end loop;
                  end if;
                  ---
                  -- This cursor sums the assessment components of the CVB
                  -- that have a component currency that is the same as
                  -- the primary currency.  No conversion is needed.
                  -- Since assessments are attached at the Item header level,
                  -- we do not have all of the specific information such as
                  -- a supplier, a lading port, a discharge port, or a zone.
                  -- Therefore, in this case, we sum the expenses that exist for
                  -- the primary supplier, and the 'Base' set of expenses.
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS_EXP_DTLS_PRIM','ITEM_EXP_DETAIL',NULL);
                  open C_SUM_ASSESS_EXP_DTLS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS_EXP_DTLS_PRIM','ITEM_EXP_DETAIL',NULL);
                  fetch C_SUM_ASSESS_EXP_DTLS_PRIM into L_assess_exp_dtl_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS_EXP_DTLS_PRIM','ITEM_EXP_DETAIL',NULL);
                  close C_SUM_ASSESS_EXP_DTLS_PRIM;
                  ---
               end if;

            elsif I_dtl_flag = 'F' then
               if I_calc_type = 'IE' then
                  ---
                  -- If a component has a cvb, and that cvb has a flag set to 'Y',
                  -- then these cursors will sum up all components that have the
                  -- same flags set to '+'.
                  ---
                  -- Sum '+' expense flag components.
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor will some all expense components with the appropriate
                     -- flags set to '+' where the component's currency is not the same
                     -- as the primary currency.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_FLAGS','ITEM_EXP_DETAIL',NULL);
                     open C_SUM_EXP_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_FLAGS','ITEM_EXP_DETAIL',NULL);
                     fetch C_SUM_EXP_FLAGS into L_exp_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_FLAGS','ITEM_EXP_DETAIL',NULL);
                     close C_SUM_EXP_FLAGS;
                     ---
                  else --L_currency_code_prim is not 'EUR'--
                     ---
                     L_exp_flag_amt := 0;
                     ---
                     for Curr_rec in C_GET_CURR_FLAGS loop
                        L_euro_comp_currency := Curr_rec.comp_currency;
                        ---
                        L_euro_comp_currency_exists := 'N';
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        open C_EURO_COMP_CURR_EXISTS;
                        SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                        SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        close C_EURO_COMP_CURR_EXISTS;
                        ---
                        L_temp := 0;
                        ---
                        if L_euro_comp_currency_exists = 'Y' then
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_FLAGS_2','ITEM_EXP_DETAIL',NULL);
                           open C_EURO_SUM_EXP_FLAGS_2;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_FLAGS_2','ITEM_EXP_DETAIL',NULL);
                           fetch C_EURO_SUM_EXP_FLAGS_2 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_FLAGS_2','ITEM_EXP_DETAIL',NULL);
                           close C_EURO_SUM_EXP_FLAGS_2;
                        else
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_FLAGS_1','ITEM_EXP_DETAIL',NULL);
                           open C_EURO_SUM_EXP_FLAGS_1;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_FLAGS_1','ITEM_EXP_DETAIL',NULL);
                           fetch C_EURO_SUM_EXP_FLAGS_1 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_FLAGS_1','ITEM_EXP_DETAIL',NULL);
                           close C_EURO_SUM_EXP_FLAGS_1;
                        end if;
                        ---
                        L_exp_flag_amt := L_exp_flag_amt + L_temp;
                     end loop;
                  end if;
                  ---
                  -- This cursor will some all expense components with the appropriate
                  -- flags set to '+' where the component's currency is the same
                  -- as the primary currency.
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_FLAGS_PRIM','ITEM_EXP_DETAIL',NULL);
                  open C_SUM_EXP_FLAGS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_FLAGS_PRIM','ITEM_EXP_DETAIL',NULL);
                  fetch C_SUM_EXP_FLAGS_PRIM into L_exp_flag_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_FLAGS_PRIM','ITEM_EXP_DETAIL',NULL);
                  close C_SUM_EXP_FLAGS_PRIM;
                  ---
                  -- The following cursors are being called to retrieve expense values of the opposite
                  -- item expense type to be used in the calculation of the current component.  Zone level
                  -- expenses may be based on country level expenses and vice versa...
                  ---
                  if I_item_exp_type = 'Z' and I_comp_id <> 'TEXPZ' then
                     if L_currency_code_prim = 'EUR' then
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_FLAGS_CTRY','ITEM_EXP_DETAIL',NULL);
                        open C_SUM_EXP_FLAGS_CTRY;
                        SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_FLAGS_CTRY','ITEM_EXP_DETAIL',NULL);
                        fetch C_SUM_EXP_FLAGS_CTRY into L_exp_flag_amt_ctry;
                        SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_FLAGS_CTRY','ITEM_EXP_DETAIL',NULL);
                        close C_SUM_EXP_FLAGS_CTRY;
                        ---
                     else --L_currency_code_prim is not 'EUR'--
                        ---
                        L_exp_flag_amt_ctry := 0;
                        ---
                        for Curr_rec in C_GET_CURR_FLAGS_CTRY loop
                           L_euro_comp_currency := Curr_rec.comp_currency;
                           ---
                           L_euro_comp_currency_exists := 'N';
                           ---
                           SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           open C_EURO_COMP_CURR_EXISTS;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           close C_EURO_COMP_CURR_EXISTS;
                           ---
                           L_temp := 0;
                           ---
                           if L_euro_comp_currency_exists = 'Y' then
                              SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_FLAGS_CTRY_2','ITEM_EXP_DETAIL',NULL);
                              open C_EURO_SUM_EXP_FLAGS_CTRY_2;
                              SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_FLAGS_CTRY_2','ITEM_EXP_DETAIL',NULL);
                              fetch C_EURO_SUM_EXP_FLAGS_CTRY_2 into L_temp;
                              SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_FLAGS_CTRY_2','ITEM_EXP_DETAIL',NULL);
                              close C_EURO_SUM_EXP_FLAGS_CTRY_2;
                           else
                              SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_FLAGS_CTRY_1','ITEM_EXP_DETAIL',NULL);
                              open C_EURO_SUM_EXP_FLAGS_CTRY_1;
                              SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_FLAGS_CTRY_1','ITEM_EXP_DETAIL',NULL);
                              fetch C_EURO_SUM_EXP_FLAGS_CTRY_1 into L_temp;
                              SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_FLAGS_CTRY_1','ITEM_EXP_DETAIL',NULL);
                              close C_EURO_SUM_EXP_FLAGS_CTRY_1;
                           end if;
                           ---
                           L_exp_flag_amt_ctry := L_exp_flag_amt_ctry + L_temp;
                        end loop;
                     end if;
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_FLAGS_CTRY_PRIM','ITEM_EXP_DETAIL',NULL);
                     open C_SUM_EXP_FLAGS_CTRY_PRIM;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_FLAGS_CTRY_PRIM','ITEM_EXP_DETAIL',NULL);
                     fetch C_SUM_EXP_FLAGS_CTRY_PRIM into L_exp_flag_amt_ctry_prim;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_FLAGS_CTRY_PRIM','ITEM_EXP_DETAIL',NULL);
                     close C_SUM_EXP_FLAGS_CTRY_PRIM;
                  elsif I_item_exp_type = 'C' and I_comp_id <> 'TEXPC' then
                     if L_currency_code_prim = 'EUR' then
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_FLAGS_ZONE','ITEM_EXP_DETAIL',NULL);
                        open C_SUM_EXP_FLAGS_ZONE;
                        SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_FLAGS_ZONE','ITEM_EXP_DETAIL',NULL);
                        fetch C_SUM_EXP_FLAGS_ZONE into L_exp_flag_amt_zone;
                        SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_FLAGS_ZONE','ITEM_EXP_DETAIL',NULL);
                        close C_SUM_EXP_FLAGS_ZONE;
                        ---
                     else --L_currency_code_prim is not 'EUR'--
                        ---
                        L_exp_flag_amt_zone := 0;
                        ---
                        for Curr_rec in C_GET_CURR_FLAGS_ZONE loop
                           L_euro_comp_currency := Curr_rec.comp_currency;
                           ---
                           L_euro_comp_currency_exists := 'N';
                           ---
                           SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           open C_EURO_COMP_CURR_EXISTS;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                           close C_EURO_COMP_CURR_EXISTS;
                           ---
                           L_temp := 0;
                           ---
                           if L_euro_comp_currency_exists = 'Y' then
                              SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_FLAGS_ZONE_2','ITEM_EXP_DETAIL',NULL);
                              open C_EURO_SUM_EXP_FLAGS_ZONE_2;
                              SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_FLAGS_ZONE_2','ITEM_EXP_DETAIL',NULL);
                              fetch C_EURO_SUM_EXP_FLAGS_ZONE_2 into L_temp;
                              SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_FLAGS_ZONE_2','ITEM_EXP_DETAIL',NULL);
                              close C_EURO_SUM_EXP_FLAGS_ZONE_2;
                           else
                              SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_FLAGS_ZONE_1','ITEM_EXP_DETAIL',NULL);
                              open C_EURO_SUM_EXP_FLAGS_ZONE_1;
                              SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_FLAGS_ZONE_1','ITEM_EXP_DETAIL',NULL);
                              fetch C_EURO_SUM_EXP_FLAGS_ZONE_1 into L_temp;
                              SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_FLAGS_ZONE_1','ITEM_EXP_DETAIL',NULL);
                              close C_EURO_SUM_EXP_FLAGS_ZONE_1;
                           end if;
                           ---
                           L_exp_flag_amt_zone := L_exp_flag_amt_zone + L_temp;
                        end loop;
                     end if;
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_FLAGS_ZONE_PRIM','ITEM_EXP_DETAIL',NULL);
                     open C_SUM_EXP_FLAGS_ZONE_PRIM;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_FLAGS_ZONE_PRIM','ITEM_EXP_DETAIL',NULL);
                     fetch C_SUM_EXP_FLAGS_ZONE_PRIM into L_exp_flag_amt_zone_prim;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_FLAGS_ZONE_PRIM','ITEM_EXP_DETAIL',NULL);
                     close C_SUM_EXP_FLAGS_ZONE_PRIM;
                  end if;
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     -- This cursor will some all assessment components with the appropriate
                     -- flags set to '+' where the component's currency is not the same
                     -- as the primary currency.
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_ASSESS_FLAGS','ITEM_HTS_ASSESS',NULL);
                     open C_SUM_EXP_ASSESS_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_ASSESS_FLAGS','ITEM_HTS_ASSESS',NULL);
                     fetch C_SUM_EXP_ASSESS_FLAGS into L_exp_assess_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_ASSESS_FLAGS','ITEM_HTS_ASSESS',NULL);
                     close C_SUM_EXP_ASSESS_FLAGS;
                     ---
                  else --L_currency_code_prim is not 'EUR'--
                     ---
                     L_exp_assess_flag_amt := 0;
                     ---
                     for Curr_rec in C_GET_CURR_EA_FLAGS loop
                        L_euro_comp_currency := Curr_rec.comp_currency;
                        ---
                        L_euro_comp_currency_exists := 'N';
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        open C_EURO_COMP_CURR_EXISTS;
                        SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                        SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        close C_EURO_COMP_CURR_EXISTS;
                        ---
                        L_temp := 0;
                        ---
                        if L_euro_comp_currency_exists = 'Y' then
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_ASSESS_FLAGS_2','ITEM_HTS_ASSESS',NULL);
                           open C_EURO_SUM_EXP_ASSESS_FLAGS_2;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_ASSESS_FLAGS_2','ITEM_HTS_ASSESS',NULL);
                           fetch C_EURO_SUM_EXP_ASSESS_FLAGS_2 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_ASSESS_FLAGS_2','ITEM_HTS_ASSESS',NULL);
                           close C_EURO_SUM_EXP_ASSESS_FLAGS_2;
                        else
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_EXP_ASSESS_FLAGS_1','ITEM_HTS_ASSESS',NULL);
                           open C_EURO_SUM_EXP_ASSESS_FLAGS_1;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_EXP_ASSESS_FLAGS_1','ITEM_HTS_ASSESS',NULL);
                           fetch C_EURO_SUM_EXP_ASSESS_FLAGS_1 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_EXP_ASSESS_FLAGS_1','ITEM_HTS_ASSESS',NULL);
                           close C_EURO_SUM_EXP_ASSESS_FLAGS_1;
                        end if;
                        ---
                        L_exp_assess_flag_amt := L_exp_assess_flag_amt + L_temp;
                     end loop;
                  end if;
                  ---
                  -- This cursor will some all expense components with the appropriate
                  -- flags set to '+' where the component's currency is the same
                  -- as the primary currency.
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_EXP_ASSESS_FLAGS_PRIM','ITEM_HTS_ASSESS',NULL);
                  open C_SUM_EXP_ASSESS_FLAGS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_EXP_ASSESS_FLAGS_PRIM','ITEM_HTS_ASSESS',NULL);
                  fetch C_SUM_EXP_ASSESS_FLAGS_PRIM into L_exp_assess_flag_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_EXP_ASSESS_FLAGS_PRIM','ITEM_HTS_ASSESS',NULL);
                  close C_SUM_EXP_ASSESS_FLAGS_PRIM;
---
-- The comments above (where I_dtl_flag = 'F' and I_calc_type = 'IE') apply as well
-- to the following cursors (where I_calc_type = 'IA').
---
               elsif I_calc_type = 'IA' then
                  ---
                  -- Sum '+' assessment flag components.
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS_FLAGS','ITEM_HTS_ASSESS',NULL);
                     open C_SUM_ASSESS_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS_FLAGS','ITEM_HTS_ASSESS',NULL);
                     fetch C_SUM_ASSESS_FLAGS into L_assess_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS_FLAGS','ITEM_HTS_ASSESS',NULL);
                     close C_SUM_ASSESS_FLAGS;
                     ---
                  else   --L_currency_code_prim is not 'EUR'--
                     ---
                     L_assess_flag_amt := 0;
                     ---
                     for Curr_rec in C_GET_CURR_A_FLAGS loop
                        L_euro_comp_currency := Curr_rec.comp_currency;
                        ---
                        L_euro_comp_currency_exists := 'N';
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        open C_EURO_COMP_CURR_EXISTS;
                        SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                        SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        close C_EURO_COMP_CURR_EXISTS;
                        ---
                        L_temp := 0;
                        ---
                        if L_euro_comp_currency_exists = 'Y' then
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_ASSESS_FLAGS_2','ITEM_HTS_ASSESS',NULL);
                           open C_EURO_SUM_ASSESS_FLAGS_2;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_ASSESS_FLAGS_2','ITEM_HTS_ASSESS',NULL);
                           fetch C_EURO_SUM_ASSESS_FLAGS_2 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_ASSESS_FLAGS_2','ITEM_HTS_ASSESS',NULL);
                           close C_EURO_SUM_ASSESS_FLAGS_2;
                        else
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_ASSESS_FLAGS_1','ITEM_HTS_ASSESS',NULL);
                           open C_EURO_SUM_ASSESS_FLAGS_1;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_ASSESS_FLAGS_1','ITEM_HTS_ASSESS',NULL);
                           fetch C_EURO_SUM_ASSESS_FLAGS_1 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_ASSESS_FLAGS_1','ITEM_HTS_ASSESS',NULL);
                           close C_EURO_SUM_ASSESS_FLAGS_1;
                        end if;
                        ---
                        L_assess_flag_amt := L_assess_flag_amt + L_temp;
                     end loop;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS_FLAGS_PRIM','ITEM_HTS_ASSESS',NULL);
                  open C_SUM_ASSESS_FLAGS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS_FLAGS_PRIM','ITEM_HTS_ASSESS',NULL);
                  fetch C_SUM_ASSESS_FLAGS_PRIM into L_assess_flag_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS_FLAGS_PRIM','ITEM_HTS_ASSESS',NULL);
                  close C_SUM_ASSESS_FLAGS_PRIM;
                  ---
                  if L_currency_code_prim = 'EUR' then
                     ---
                     SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS_EXP_FLAGS','ITEM_EXP_DETAIL',NULL);
                     open C_SUM_ASSESS_EXP_FLAGS;
                     SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS_EXP_FLAGS','ITEM_EXP_DETAIL',NULL);
                     fetch C_SUM_ASSESS_EXP_FLAGS into L_assess_exp_flag_amt;
                     SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS_EXP_FLAGS','ITEM_EXP_DETAIL',NULL);
                     close C_SUM_ASSESS_EXP_FLAGS;
                     ---
                  else   --L_currency_code_prim is not 'EUR'--
                     ---
                     L_assess_exp_flag_amt := 0;
                     ---
                     for Curr_rec in C_GET_CURR_AE_FLAGS loop
                        L_euro_comp_currency := Curr_rec.comp_currency;
                        ---
                        L_euro_comp_currency_exists := 'N';
                        ---
                        SQL_LIB.SET_MARK('OPEN','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        open C_EURO_COMP_CURR_EXISTS;
                        SQL_LIB.SET_MARK('FETCH','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        fetch C_EURO_COMP_CURR_EXISTS into L_euro_comp_currency_exists;
                        SQL_LIB.SET_MARK('CLOSE','C_EURO_COMP_CURR_EXISTS','EURO_EXCHANGE_RATE',NULL);
                        close C_EURO_COMP_CURR_EXISTS;
                        ---
                        L_temp := 0;
                        ---
                        if L_euro_comp_currency_exists = 'Y' then
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_ASSESS_EXP_FLAGS_2','ITEM_EXP_DETAIL',NULL);
                           open C_EURO_SUM_ASSESS_EXP_FLAGS_2;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_ASSESS_EXP_FLAGS_2','ITEM_EXP_DETAIL',NULL);
                           fetch C_EURO_SUM_ASSESS_EXP_FLAGS_2 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_ASSESS_EXP_FLAGS_2','ITEM_EXP_DETAIL',NULL);
                           close C_EURO_SUM_ASSESS_EXP_FLAGS_2;
                        else
                           SQL_LIB.SET_MARK('OPEN','C_EURO_SUM_ASSESS_EXP_FLAGS_1','ITEM_EXP_DETAIL',NULL);
                           open C_EURO_SUM_ASSESS_EXP_FLAGS_1;
                           SQL_LIB.SET_MARK('FETCH','C_EURO_SUM_ASSESS_EXP_FLAGS_1','ITEM_EXP_DETAIL',NULL);
                           fetch C_EURO_SUM_ASSESS_EXP_FLAGS_1 into L_temp;
                           SQL_LIB.SET_MARK('CLOSE','C_EURO_SUM_ASSESS_EXP_FLAGS_1','ITEM_EXP_DETAIL',NULL);
                           close C_EURO_SUM_ASSESS_EXP_FLAGS_1;
                        end if;
                        ---
                        L_assess_exp_flag_amt := L_assess_exp_flag_amt + L_temp;
                     end loop;
                  end if;
                  ---
                  SQL_LIB.SET_MARK('OPEN','C_SUM_ASSESS_EXP_FLAGS_PRIM','ITEM_EXP_DETAIL',NULL);
                  open C_SUM_ASSESS_EXP_FLAGS_PRIM;
                  SQL_LIB.SET_MARK('FETCH','C_SUM_ASSESS_EXP_FLAGS_PRIM','ITEM_EXP_DETAIL',NULL);
                  fetch C_SUM_ASSESS_EXP_FLAGS_PRIM into L_assess_exp_flag_amt_prim;
                  SQL_LIB.SET_MARK('CLOSE','C_SUM_ASSESS_EXP_FLAGS_PRIM','ITEM_EXP_DETAIL',NULL);
                  close C_SUM_ASSESS_EXP_FLAGS_PRIM;
                  ---
               end if;
               ---
            end if;
            ---
            -- Add components to the total.
            L_amount_temp := (  L_exp_dtl_amt          + L_exp_dtl_amt_prim
                              + L_exp_dtl_amt_zone     + L_exp_dtl_amt_zone_prim
                              + L_exp_dtl_amt_ctry     + L_exp_dtl_amt_ctry_prim
                              + L_exp_assess_dtl_amt   + L_exp_assess_dtl_amt_prim
                              + L_exp_flag_amt         + L_exp_flag_amt_prim
                              + L_exp_flag_amt_zone    + L_exp_flag_amt_zone_prim
                              + L_exp_flag_amt_ctry    + L_exp_flag_amt_ctry_prim
                              + L_exp_assess_flag_amt  + L_exp_assess_flag_amt_prim
                              + L_assess_dtl_amt       + L_assess_dtl_amt_prim
                              + L_assess_exp_dtl_amt   + L_assess_exp_dtl_amt_prim
                              + L_assess_flag_amt      + L_assess_flag_amt_prim
                              + L_assess_exp_flag_amt  + L_assess_exp_flag_amt_prim);
            ---
            if L_counter = 1 then
               L_amount := L_amount + L_amount_temp;
            else
               L_amount := L_amount - L_amount_temp;
            end if;
            ---
            L_counter := L_counter + 1;
         END LOOP;
         ---
         if L_emu_participating_ind = TRUE then
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
            SQL_LIB.SET_MARK('OPEN','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
            open C_GET_UNIT_COST;
            SQL_LIB.SET_MARK('FETCH','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
            fetch C_GET_UNIT_COST into L_amount;
            SQL_LIB.SET_MARK('CLOSE','C_GET_UNIT_COST','ITEM_SUPP_COUNTRY',NULL);
            close C_GET_UNIT_COST;
            ---
            -- Convert L_amount from supplier currency to primary currency.
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
      end if; -- L_cvb_code is not NULL/NULL.

      -- Calculate the Estimate Expense Value.  When the Calculation Basis is Value, the
      -- expense or assessment is simply a percentage of an amount.

      O_est_value := L_amount * (L_comp_rate/100);

      -- Convert O_est_value from primary currency to the Component's currency.
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
         SQL_LIB.SET_MARK('OPEN','C_GET_DIMENSION','ITEM_SUPP_COUNTRY, ITEM_SUPP_COUNTRY_DIM',NULL);
         open C_GET_DIMENSION;
         SQL_LIB.SET_MARK('FETCH','C_GET_DIMENSION','ITEM_SUPP_COUNTRY, ITEM_SUPP_COUNTRY_DIM',NULL);
         fetch C_GET_DIMENSION into L_supp_pack_size,
                                    L_ship_carton_wt,
                                    L_weight_uom,
                                    L_ship_carton_len,
                                    L_ship_carton_hgt,
                                    L_ship_carton_wid,
                                    L_dimension_uom,
                                    L_liquid_volume,
                                    L_liquid_volume_uom;
         SQL_LIB.SET_MARK('CLOSE','C_GET_DIMENSION','ITEM_SUPP_COUNTRY, ITEM_SUPP_COUNTRY_DIM',NULL);
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
                                                L_per_unit_value, -- standard UOM conversion factor
                                                I_item,
                                                'N') = FALSE then
               return FALSE;
            end if;
            ---
            if L_per_unit_value is NULL then
               if L_standard_uom <> 'EA' then
                  L_per_unit_value := 0;
                  if I_calc_type in ('IE','IA') then
                     L_unit_of_work := 'Item '||I_item||
                                       ', Component '||I_comp_id;
                  end if;
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
            L_uom  := 'EA';

         elsif L_uom_class = 'PACK' then

            L_value := 1 / L_supp_pack_size;

         elsif L_uom_class = 'MISC' then
            SQL_LIB.SET_MARK('OPEN','C_GET_MISC_VALUE','ITEM_SUPP_UOM', NULL);
            open C_GET_MISC_VALUE;
            SQL_LIB.SET_MARK('FETCH','C_GET_MISC_VALUE','ITEM_SUPP_UOM', NULL);
            fetch C_GET_MISC_VALUE into L_value;
            ---
            if C_GET_MISC_VALUE%NOTFOUND then
               L_value := 0;
               ---
               if I_calc_type in ('IE','IA') then
                  L_unit_of_work := 'Item '||I_item||', Supplier '||to_char(L_supplier)||
                                    ', Component '||I_comp_id;
               end if;
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
            if L_ship_carton_wt is NULL then
               L_per_unit_value := 0;
               ---
               if I_calc_type in ('IE','IA') then
                  L_unit_of_work := 'Item '||I_item||', Supplier '||to_char(L_supplier)||
                                    ', Origin Country '||L_origin_country_id||
                                    ', Component '||I_comp_id;
               end if;
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
               L_per_unit_value := L_ship_carton_wt/L_supp_pack_size;
               L_uom := L_weight_uom;
            end if;

         elsif L_uom_class = 'LVOL' then
            if L_liquid_volume_uom is NULL then
               L_per_unit_value := 0;
               ---
               if I_calc_type in ('IE','IA') then
                  L_unit_of_work := 'Item '||I_item||', Supplier '||to_char(L_supplier)||
                                    ', Origin Country '||L_origin_country_id||
                                    ', Component '||I_comp_id;
               end if;
               ---
               if INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                  SQL_LIB.GET_MESSAGE_TEXT('NO_LVOL_INFO',
                                                            I_item,
                                                            to_char(L_supplier),
                                                            L_origin_country_id),
                                                            L_program,
                                                            L_unit_of_work) = FALSE then
                  return FALSE;
               end if;
            else
               L_per_unit_value := L_liquid_volume/L_supp_pack_size;
               L_uom := L_liquid_volume_uom;
            end if;

         elsif L_uom_class = 'VOL' then
            if L_ship_carton_len is NULL or L_ship_carton_wid is NULL or L_ship_carton_hgt is NULL then
               L_per_unit_value := 0;
               ---
               if I_calc_type in ('IE','IA') then
                  L_unit_of_work := 'Item '||I_item||', Supplier '||to_char(L_supplier)||
                                    ', Origin Country '||L_origin_country_id||
                                    ', Component '||I_comp_id;
               end if;
               ---
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
               L_per_unit_value := (L_ship_carton_len * L_ship_carton_hgt * L_ship_carton_wid)
                                    /L_supp_pack_size;
               ---
               L_uom := L_dimension_uom||'3';
            end if;
         elsif L_uom_class = 'AREA' then
            if L_ship_carton_len is NULL or L_ship_carton_wid is NULL then
               L_per_unit_value := 0;
               ---
               if I_calc_type in ('IE','IA') then
                  L_unit_of_work := 'Item '||I_item||', Supplier '||to_char(L_supplier)||
                                    ', Origin Country '||L_origin_country_id||
                                    ', Component '||I_comp_id;
               end if;
               ---
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
               L_per_unit_value := (L_ship_carton_len * L_ship_carton_wid)/L_supp_pack_size;
               ---
               L_uom := L_dimension_uom||'2';
            end if;
         elsif L_uom_class = 'DIMEN' then
            if L_ship_carton_len is NULL then
               L_per_unit_value := 0;
               ---
               if I_calc_type in ('IE','IA') then
                  L_unit_of_work := 'Item '||I_item||', Supplier '||to_char(L_supplier)||
                                    ', Origin Country '||L_origin_country_id||
                                    ', Component '||I_comp_id;
               end if;
               ---
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
               L_per_unit_value := L_ship_carton_len/L_supp_pack_size;
               ---
               L_uom := L_dimension_uom;
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
-------------------------------------------------------------------------------
-- Function: COST_ZONE_CHANGE
--  Purpose: Deletes existing item_exp_detail and item_exp_head records for the
--           item.  If suppliers exist, returns the total elc for the
--           primary supplier.
-------------------------------------------------------------------------------
FUNCTION COST_ZONE_CHANGE(O_error_message    IN OUT  VARCHAR2,
                          O_total_elc        IN OUT  NUMBER,
                          I_suppliers_exist  IN      VARCHAR2,
                          I_item             IN      ITEM_MASTER.ITEM%TYPE)
return BOOLEAN is

   L_program            VARCHAR2(62) := 'ELC_ITEM_SQL.COST_ZONE_CHANGE';
   L_total_exp          NUMBER;
   L_exp_currency       CURRENCIES.CURRENCY_CODE%TYPE;
   L_exchange_rate_exp  CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_total_dty          NUMBER;
   L_dty_currency       CURRENCIES.CURRENCY_CODE%TYPE;
   L_table              VARCHAR2(20);
   RECORD_LOCKED        EXCEPTION;
   PRAGMA               EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_DETAIL is
      select 'x'
        from item_exp_detail ied
       where ied.item_exp_type = 'Z'
         and (   ied.item = I_item
              or exists (select 'x'
                           from item_master im
                          where ied.item_exp_type = 'Z'
                            and ied.item   = im.item
                            and (   I_item = im.item_parent
                                 or I_item = im.item_grandparent)))
         for update of ied.item nowait;

   cursor C_LOCK_HEAD is
      select 'x'
        from item_exp_head ieh
       where ieh.item_exp_type = 'Z'
         and (   ieh.item = I_item
              or exists (select 'x'
                           from item_master im
                          where ieh.item_exp_type = 'Z'
                            and ieh.item   = im.item
                            and (   I_item = im.item_parent
                                 or I_item = im.item_grandparent)))
         for update of ieh.item nowait;

BEGIN

   --- Lock tables.
   L_table := 'item_exp_detail';
   open  C_LOCK_DETAIL;
   close C_LOCK_DETAIL;
   L_table := 'item_exp_head';
   open  C_LOCK_HEAD;
   close C_LOCK_HEAD;

   --- Delete existing records  from item_exp_detail
   delete from item_exp_detail ied
         where ied.item_exp_type = 'Z'
           and (   ied.item = I_item
                or exists (select 'x'
                             from item_master im
                            where ied.item_exp_type = 'Z'
                              and ied.item   = im.item
                              and (   I_item = im.item_parent
                                   or I_item = im.item_grandparent)));

   --- Delete existing records from item_exp_head
   delete from item_exp_head ieh
         where ieh.item_exp_type = 'Z'
           and (   ieh.item = I_item
                or exists (select 'x'
                             from item_master im
                            where ieh.item_exp_type = 'Z'
                              and ieh.item   = im.item
                              and (   I_item = im.item_parent
                                   or I_item = im.item_grandparent)));

   --- If suppliers exist then calculate total ELC for primary supplier
   if I_suppliers_exist = 'Y' then
      if ELC_CALC_SQL.CALC_TOTALS(O_error_message,
                                  O_total_elc,
                                  L_total_exp,
                                  L_exp_currency,
                                  L_exchange_rate_exp,
                                  L_total_dty,
                                  L_dty_currency,
                                  NULL,
                                  I_item,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            I_item,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END COST_ZONE_CHANGE;
-------------------------------------------------------------------------------
FUNCTION NEW_COST_ZONE_COMP_DETAILS(O_error_message    IN OUT  RTK_ERRORS.RTK_TEXT%TYPE,
                                    I_item             IN      ITEM_MASTER.ITEM%TYPE,
                                    I_cost_zone_group  IN      ITEM_MASTER.COST_ZONE_GROUP_ID%TYPE)
return BOOLEAN IS
   L_supplier           ITEM_SUPP_COUNTRY.SUPPLIER%TYPE;
   L_pack_type          ITEM_MASTER.PACK_TYPE%TYPE;
   L_elc_ind            SYSTEM_OPTIONS.ELC_IND%TYPE;
   L_exists             BOOLEAN := FALSE;
   L_program            VARCHAR2(255) :='NEW_COST_ZONE_COMP_DETAILS';

   CURSOR C_SUPPLIER is
   select supplier
     from item_supp_country
    where item = I_item;

   CURSOR C_NOT_BUYER_PACK is
   select pack_type
     from item_master
    where item = I_item;

BEGIN
   OPEN C_NOT_BUYER_PACK;
   FETCH C_NOT_BUYER_PACK into L_pack_type;
   CLOSE C_NOT_BUYER_PACK;

   if SYSTEM_OPTIONS_SQL.GET_ELC_IND(O_error_message,
                                     L_elc_ind) = FALSE then
      return FALSE;
   end if;

   if (NVL(L_pack_type,'x')!= 'B' and L_elc_ind = 'Y') then
      FOR rec in C_SUPPLIER
      LOOP
         L_supplier := rec.supplier;
         if EXP_PROF_SQL.PROF_HEAD_EXIST(O_error_message,
                                         L_exists,
                                         'Z',
                                         'SUPP',
                                         to_char(L_supplier),
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if L_exists = FALSE then
            if EXP_PROF_SQL.BASE_PROF_EXIST(O_error_message,
                                            L_exists,
                                            'Z',
                                            'SUPP',
                                            to_char(L_supplier),
                                            NULL) = FALSE then
               return FALSE;
            end if;
         end if;
         if L_exists = TRUE then
            if ITEM_EXPENSE_SQL.DEFAULT_EXPENSES(O_error_message,
                                                 I_item,
               	                                 L_supplier,
               	                                 NULL,
               	                                 I_cost_zone_group) = FALSE then
               return FALSE;
            end if;
            ---
            if ITEM_EXPENSE_SQL.DEFAULT_GROUP_EXP(O_error_message,
                                                  I_item,
                                                  L_supplier,
                                                  NULL) = FALSE then
               return FALSE;
            end if;
         end if;

      END LOOP;
   end if;
   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            NULL);
      return FALSE;
END NEW_COST_ZONE_COMP_DETAILS;
-- 12.02.2008, ORMS 364.2,Richard Addison(BEGIN)
--------------------------------------------------------------------------------------------
--Function:  TSL_COMP_IN_USE
--Purpose:   Returns TRUE if the passed in component has been associated with an item.
--------------------------------------------------------------------------------------------
FUNCTION TSL_COMP_IN_USE(O_error_message    IN OUT VARCHAR2,
                         O_comp_in_use      IN OUT VARCHAR2,
                         I_comp_id          IN ELC_COMP.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   cursor C_COMP_IN_USE IS
      select 'Y'
        from dual
       where exists ( select 'X'
                        from item_exp_detail
                       where comp_id = I_comp_id);

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_COMP_IN_USE','ITEM_EXP_DETAIL', NULL);
   open C_COMP_IN_USE;
   ---
   SQL_LIB.SET_MARK('FETCH','C_COMP_IN_USE','ITEM_EXP_DETAIL', NULL);
   fetch C_COMP_IN_USE into O_comp_in_use;
   ---
   if C_COMP_IN_USE%NOTFOUND then
      O_comp_in_use := 'N';
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_COMP_IN_USE','ITEM_EXP_DETAIL', NULL);
   close C_COMP_IN_USE;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      SQL_LIB.SET_MARK('CLOSE','C_COMP_IN_USE','ITEM_EXP_DETAIL', NULL);
      close C_COMP_IN_USE;
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR', SQLERRM,
                          'ELC_ITEM_SQL.TSL_COMP_IN_USE', to_char(SQLCODE));
      return FALSE;
END TSL_COMP_IN_USE;
-------------------------------------------------------------------------------
-- 12.02.2008, ORMS 364.2,Richard Addison(END)
-------------------------------------------------------------------------------
END ELC_ITEM_SQL;
/

