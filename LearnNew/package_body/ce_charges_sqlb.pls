CREATE OR REPLACE PACKAGE BODY CE_CHARGES_SQL AS
--------------------------------------------------------------------------------------
FUNCTION GET_NEXT_SEQ(O_error_message          IN OUT  VARCHAR2,
                      O_seq_no                 IN OUT  CE_CHARGES.SEQ_NO%TYPE,
                      I_ce_id                  IN      CE_CHARGES.CE_ID%TYPE,
                      I_vessel_id              IN      CE_CHARGES.VESSEL_ID%TYPE,
                      I_voyage_id              IN      CE_CHARGES.VOYAGE_FLT_ID%TYPE,
                      I_estimated_depart_date  IN      CE_CHARGES.ESTIMATED_DEPART_DATE%TYPE,
                      I_order_no               IN      ORDHEAD.ORDER_NO%TYPE,
                      I_item                   IN      ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS
   L_program   VARCHAR2(50) := 'CE_CHARGES_SQL.GET_NEXT_SEQ';

   cursor C_GET_MAX_SEQ is
      select nvl(MAX(seq_no),0) + 1
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_MAX_SEQ','CE_CHARGES',NULL);
   open C_GET_MAX_SEQ;

   SQL_LIB.SET_MARK('FETCH','C_GET_MAX_SEQ','CE_CHARGES',NULL);
   fetch C_GET_MAX_SEQ into O_seq_no;

   SQL_LIB.SET_MARK('CLOSE','C_GET_MAX_SEQ','CE_CHARGES',NULL);
   close C_GET_MAX_SEQ;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_NEXT_SEQ;
--------------------------------------------------------------------------------------
FUNCTION CHARGES_EXIST(O_error_message          IN OUT  VARCHAR2,
                       O_exists                 IN OUT  BOOLEAN,
                       I_ce_id                  IN      CE_CHARGES.CE_ID%TYPE,
                       I_vessel_id              IN      CE_CHARGES.VESSEL_ID%TYPE,
                       I_voyage_id              IN      CE_CHARGES.VOYAGE_FLT_ID%TYPE,
                       I_estimated_depart_date  IN      CE_CHARGES.ESTIMATED_DEPART_DATE%TYPE,
                       I_order_no               IN      ORDHEAD.ORDER_NO%TYPE,
                       I_item                   IN      ITEM_MASTER.ITEM%TYPE,
                       I_pack_item              IN      ITEM_MASTER.ITEM%TYPE,
                       I_hts                    IN      HTS.HTS%TYPE,
                       I_effect_from            IN      HTS.EFFECT_FROM%TYPE,
                       I_effect_to              IN      HTS.EFFECT_TO%TYPE,
                       I_comp_id                IN      ELC_COMP.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'CE_CHARGES_SQL.CHARGES_EXIST';
   L_exists    VARCHAR2(1)  := 'N';

   cursor C_CHARGE_EXISTS is
      select 'Y'
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and ((pack_item           = I_pack_item
               and I_pack_item is not NULL)
          or (pack_item is NULL and I_pack_item is NULL))
         and ((hts                 = I_hts)
          or (hts is NULL and I_hts is NULL))
         and ((effect_from         = I_effect_from)
          or (effect_from is NULL and I_effect_from is NULL))
         and ((effect_to           = I_effect_to)
          or (effect_to is NULL and I_effect_to is NULL))
         and comp_id               = I_comp_id;

BEGIN
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_CHARGE_EXISTS','CE_CHARGES',NULL);
   open C_CHARGE_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_CHARGE_EXISTS','CE_CHARGES',NULL);
   fetch C_CHARGE_EXISTS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHARGE_EXISTS','CE_CHARGES',NULL);
   close C_CHARGE_EXISTS;
   ---
   if L_exists = 'N' then
      O_exists := FALSE;
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
END CHARGES_EXIST;
--------------------------------------------------------------------------------------
FUNCTION DELETE_HTS(O_error_message          IN OUT  VARCHAR2,
                    I_ce_id                  IN      CE_CHARGES.CE_ID%TYPE,
                    I_vessel_id              IN      CE_CHARGES.VESSEL_ID%TYPE,
                    I_voyage_id              IN      CE_CHARGES.VOYAGE_FLT_ID%TYPE,
                    I_estimated_depart_date  IN      CE_CHARGES.ESTIMATED_DEPART_DATE%TYPE,
                    I_order_no               IN      ORDHEAD.ORDER_NO%TYPE,
                    I_item                   IN      ITEM_MASTER.ITEM%TYPE,
                    I_pack_item              IN      ITEM_MASTER.ITEM%TYPE,
                    I_hts                    IN      HTS.HTS%TYPE)
RETURN BOOLEAN IS
   L_program      VARCHAR2(50) := 'CE_CHARGES_SQL.DELETE_HTS';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         exception_init(RECORD_LOCKED, -54);

   cursor C_LOCK_CE_CHARGES is
      select 'x'
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and ((pack_item           = I_pack_item
               and I_pack_item is not NULL)
          or (pack_item is NULL and I_pack_item is NULL))
         and hts                   = I_hts
         for update nowait;

BEGIN
   --- lock ce_charges table
   SQL_LIB.SET_MARK('OPEN','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
   open C_LOCK_CE_CHARGES;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
   close C_LOCK_CE_CHARGES;

   --- delete given record
   SQL_LIB.SET_MARK('DELETE',NULL,'CE_CHARGES',NULL);
   delete from ce_charges
    where ce_id                 = I_ce_id
      and vessel_id             = I_vessel_id
      and voyage_flt_id         = I_voyage_id
      and estimated_depart_date = I_estimated_depart_date
      and order_no              = I_order_no
      and item                  = I_item
      and ((pack_item           = I_pack_item
            and I_pack_item is not NULL)
       or (pack_item is NULL and I_pack_item is NULL))
      and hts                   = I_hts;

   return TRUE;
EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'CE_CHARGES',
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DELETE_HTS;
--------------------------------------------------------------------------------------
--This is an internal function called by INSERT_COMPS
FUNCTION GET_MAX_SEQ_NO(O_error_message         IN OUT VARCHAR2,
                        O_seq_no                IN OUT CE_CHARGES.SEQ_NO%TYPE,
                        I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                        I_vessel_id             IN     CE_SHIPMENT.VESSEL_ID%TYPE,
                        I_voyage_flt_id         IN     CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                        I_estimated_depart_date IN     CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                        I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                        I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                        I_pack_item             IN     ITEM_MASTER.ITEM%TYPE)

RETURN BOOLEAN IS

 L_program           VARCHAR2(50)            := 'GET_MAX_SEQ_NO';

cursor C_GET_MAX_SEQ is
      select nvl(MAX(seq_no),0)
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_GET_MAX_SEQ','CE_CHARGES',NULL);
   open C_GET_MAX_SEQ;

   SQL_LIB.SET_MARK('FETCH','C_GET_MAX_SEQ','CE_CHARGES',NULL);
   fetch C_GET_MAX_SEQ into O_seq_no;

   SQL_LIB.SET_MARK('CLOSE','C_GET_MAX_SEQ','CE_CHARGES',NULL);
   close C_GET_MAX_SEQ;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_MAX_SEQ_NO;
--------------------------------------------------------------------------------------
FUNCTION INSERT_COMPS(O_error_message           IN OUT   VARCHAR2,
                      I_ce_id                   IN       CE_HEAD.CE_ID%TYPE,
                      I_vessel_id               IN       CE_SHIPMENT.VESSEL_ID%TYPE,
                      I_voyage_flt_id           IN       CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                      I_estimated_depart_date   IN       CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                      I_order_no                IN       ORDHEAD.ORDER_NO%TYPE,
                      I_item                    IN       ITEM_MASTER.ITEM%TYPE,
                      I_pack_item               IN       ITEM_MASTER.ITEM%TYPE,
                      I_hts                     IN       HTS.HTS%TYPE,
                      I_import_country_id       IN       COUNTRY.COUNTRY_ID%TYPE,
                      I_effect_from             IN       HTS.EFFECT_FROM%TYPE,
                      I_effect_to               IN       HTS.EFFECT_TO%TYPE,
                      I_cvb_code                IN       CVB_HEAD.CVB_CODE%TYPE)

RETURN BOOLEAN IS
   L_program             VARCHAR2(50) := 'CE_CHARGES_SQL.INSERT_COMPS';
   L_exists              VARCHAR2(1)  := 'N';
   L_exp_vfd_exists      VARCHAR2(1)  := 'N';
   L_oc_exists           BOOLEAN;
   L_order_exists        BOOLEAN;
   L_seq_no              CE_CHARGES.SEQ_NO%TYPE;
   L_first_record        CE_CHARGES.SEQ_NO%TYPE;
   L_origin_country_id   COUNTRY.COUNTRY_ID%TYPE;
   L_ce_currency         CURRENCIES.CURRENCY_CODE%TYPE;
   L_ce_exchange_rate    CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_ce_charge_seq_no    CE_CHARGES.SEQ_NO%TYPE;
   L_ce_comp_rate        CE_CHARGES.COMP_RATE%TYPE;
   L_ce_comp_value       CE_CHARGES.COMP_VALUE%TYPE;
   L_ce_per_count_uom    CE_CHARGES.PER_COUNT_UOM%TYPE;
   L_tariff_treatment    HTS_TARIFF_TREATMENT.TARIFF_TREATMENT%TYPE;
   L_qty_1               NUMBER;
   L_qty_2               NUMBER;
   L_qty_3               NUMBER;
   L_units_1             HTS.UNITS_1%TYPE;
   L_units_2             HTS.UNITS_2%TYPE;
   L_units_3             HTS.UNITS_3%TYPE;
   L_specific_rate       HTS_TARIFF_TREATMENT.SPECIFIC_RATE%TYPE := 0;
   L_av_rate             HTS_TARIFF_TREATMENT.AV_RATE%TYPE       := 0;
   L_other_rate          HTS_TARIFF_TREATMENT.OTHER_RATE%TYPE    := 0;
   L_comp_rate           ELC_COMP.COMP_RATE%TYPE                 := 0;
   L_per_count           ELC_COMP.PER_COUNT%TYPE;
   L_per_count_uom       ELC_COMP.PER_COUNT_UOM%TYPE;
   L_comp_id             ELC_COMP.COMP_ID%TYPE;
   L_cvd_case_no         HTS_CVD.CASE_NO%TYPE;
   L_ad_case_no          HTS_AD.CASE_NO%TYPE;
   L_duty_comp_code      HTS.DUTY_COMP_CODE%TYPE;
   L_tax_comp_code       HTS.DUTY_COMP_CODE%TYPE;
   L_tax_type            HTS_TAX.TAX_TYPE%TYPE;
   L_fee_comp_code       HTS.DUTY_COMP_CODE%TYPE;
   L_fee_type            HTS_FEE.FEE_TYPE%TYPE;
   L_elc_currency        CURRENCIES.CURRENCY_CODE%TYPE;
   L_elc_comp_id         ELC_COMP.COMP_ID%TYPE;
   L_elc_comp_type       ELC_COMP.COMP_TYPE%TYPE;
   L_elc_comp_rate       ELC_COMP.COMP_RATE%TYPE;
   L_elc_per_count       ELC_COMP.PER_COUNT%TYPE;
   L_elc_per_count_uom   ELC_COMP.PER_COUNT_UOM%TYPE;
   L_ose_currency        CURRENCIES.CURRENCY_CODE%TYPE;
   L_ose_exchange_rate   CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_ose_comp_id         ORDLOC_EXP.COMP_ID%TYPE;
   L_ose_per_count       ORDLOC_EXP.PER_COUNT%TYPE;
   L_ose_per_count_uom   ORDLOC_EXP.PER_COUNT_UOM%TYPE;
   L_location            ORDLOC.LOCATION%TYPE;
   L_ol_qty_ordered      ORDLOC.QTY_ORDERED%TYPE;
   L_os_comp_rate        ORDLOC_EXP.COMP_RATE%TYPE;
   L_os_per_count        ORDLOC_EXP.PER_COUNT%TYPE;
   L_os_est_exp_value    ORDLOC_EXP.EST_EXP_VALUE%TYPE;
   L_total_order_qty     ORDLOC.QTY_ORDERED%TYPE;
   L_ose_comp_rate       ORDLOC_EXP.COMP_RATE%TYPE     := 0;
   L_cost_zone_group     COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE := 0;
   L_ose_comp_value      ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_total_comp_rate     ORDLOC_EXP.COMP_RATE%TYPE     := 0;
   L_total_est_exp_value ORDLOC_EXP.EST_EXP_VALUE%TYPE := 0;
   L_hts                 HTS.HTS%TYPE;
   L_effect_from         HTS.EFFECT_FROM%TYPE;
   L_effect_to           HTS.EFFECT_TO%TYPE;
   L_water_mode_ind      VARCHAR2(1)  := 'N';
   L_hmf_exists          VARCHAR2(1)  := 'N';
   L_table               VARCHAR2(30);
   RECORD_LOCKED         EXCEPTION;
   PRAGMA                EXCEPTION_INIT(Record_Locked, -54);

   cursor C_CHECK_EXISTS is
      select 'Y'
        from ordsku_hts
       where order_no   = I_order_no
         and item       = I_item
         and ((pack_item = I_pack_item
               and I_pack_item is not NULL)
          or (pack_item is NULL and I_pack_item is NULL))
         and hts        = I_hts;

   cursor C_CONVERT_CURRENCY is
      select elc.comp_currency,
             cc.seq_no,
             cc.comp_rate,
             cc.comp_value,
             cc.per_count_uom
        from ce_charges cc,
             elc_comp  elc
       where cc.ce_id                 = I_ce_id
         and cc.vessel_id             = I_vessel_id
         and cc.voyage_flt_id         = I_voyage_flt_id
         and cc.estimated_depart_date = I_estimated_depart_date
         and cc.order_no              = I_order_no
         and cc.item                  = I_item
         and ((cc.pack_item           = I_pack_item
               and cc.pack_item      is not NULL
               and I_pack_item       is not NULL)
             or (cc.pack_item        is NULL
                 and I_pack_item     is NULL))
         and cc.seq_no                > L_first_record
         and cc.comp_id               = elc.comp_id
         and elc.comp_type            = 'A'
    order by seq_no;

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

   cursor C_GET_TAX_INFO is
      select tax_type,
             tax_comp_code,
             tax_specific_rate,
             tax_av_rate
        from hts_tax
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to;

   cursor C_GET_FEE_INFO is
      select fee_type,
             fee_comp_code,
             fee_specific_rate,
             fee_av_rate
        from hts_fee
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to;

   cursor C_LOCK_CE_CHARGES is
      select 'x'
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and ((pack_item           = I_pack_item
               and pack_item      is not NULL
               and I_pack_item    is not NULL)
             or (pack_item        is NULL
                 and I_pack_item  is NULL))
         and seq_no                = L_ce_charge_seq_no
         for update nowait;

   cursor C_CE_SHIPMENT is
      select 'Y'
        from ce_shipment
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and tran_mode_id          in (10, 11, 12);

   cursor C_HMF_EXISTS is
      select 'Y'
        from ordsku_hts_assess oha,
             ordsku_hts oh
       where oha.order_no         = oh.order_no
         and oha.seq_no           = oh.seq_no
         and oh.order_no          = I_order_no
         and oh.hts               = I_hts
         and oh.import_country_id = I_import_country_id
         and oh.effect_from       = I_effect_from
         and oh.effect_to         = I_effect_to
         and oha.comp_id          like 'HMF%';

BEGIN

   SQL_LIB.SET_MARK('OPEN','C_CE_SHIPMENT','CE_SHIPMENT',NULL);
   open C_CE_SHIPMENT;
   SQL_LIB.SET_MARK('FETCH','C_CE_SHIPMENT','CE_SHIPMENT',NULL);
   fetch C_CE_SHIPMENT into L_water_mode_ind;
   SQL_LIB.SET_MARK('CLOSE','C_CE_SHIPMENT','CE_SHIPMENT',NULL);
   close C_CE_SHIPMENT;

   if GET_MAX_SEQ_NO(O_error_message,
                     L_seq_no,
                     I_ce_id,
                     I_vessel_id,
                     I_voyage_flt_id,
                     I_estimated_depart_date,
                     I_order_no,
                     I_item,
                     I_pack_item) = FALSE then
      return FALSE;
   end if;

   --- need to keep track of what records were added so the
   --- currency can be converted into customs entry currency.

   L_first_record := L_seq_no;

   --- retrieve customs entry currency for currency conversions
   if CE_SQL.GET_CURRENCY_RATE(O_error_message,
                               L_ce_currency,
                               L_ce_exchange_rate,
                               I_ce_id) = FALSE then
      return FALSE;
   end if;

   --- pull value off ordsku_hts_assesss otherwise default with zero
   SQL_LIB.SET_MARK('OPEN','C_CHECK_EXISTS','ORDSKU_HTS', NULL);
   open C_CHECK_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_EXISTS','ORDSKU_HTS', NULL);
   fetch C_CHECK_EXISTS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_EXISTS','ORDSKU_HTS', NULL);
   close C_CHECK_EXISTS;

   --- record exists on ordsku_hts for the given hts/order/item combination
   if L_exists = 'Y' then
      SQL_LIB.SET_MARK('OPEN','C_HMF_EXISTS','ORDSKU_HTS',NULL);
      open C_HMF_EXISTS;
      SQL_LIB.SET_MARK('FETCH','C_HMF_EXISTS','ORDSKU_HTS',NULL);
      fetch C_HMF_EXISTS into L_hmf_exists;
      SQL_LIB.SET_MARK('CLOSE','C_HMF_EXISTS','ORDSKU_HTS',NULL);
      close C_HMF_EXISTS;

      SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
      insert into ce_charges (ce_id,
                              vessel_id,
                              voyage_flt_id,
                              estimated_depart_date,
                              order_no,
                              item,
                              seq_no,
                              pack_item,
                              hts,
                              effect_from,
                              effect_to,
                              comp_id,
                              comp_rate,
                              per_count_uom,
                              comp_value,
                              cvb_code)
         select I_ce_id,
                I_vessel_id,
                I_voyage_flt_id,
                I_estimated_depart_date,
                I_order_no,
                I_item,
                L_seq_no + rownum,
                I_pack_item,
                I_hts,
                I_effect_from,
                I_effect_to,
                a.comp_id,
                a.comp_rate/ NVL(a.per_count,1),
                a.per_count_uom,
                a.est_assess_value,
                a.cvb_code
           from ordsku_hts o,
                ordsku_hts_assess a
          where ((a.comp_id             NOT like 'HMF%'
                  and L_water_mode_ind    = 'N')
                  or  L_water_mode_ind    = 'Y')
            and o.order_no          = I_order_no
            and o.order_no          = a.order_no
            and o.seq_no            = a.seq_no
            and o.item              = I_item
            and ((o.pack_item       = I_pack_item and I_pack_item is not NULL)
             or (o.pack_item is NULL and I_pack_item is NULL))
            and o.hts               = I_hts
            and o.import_country_id = I_import_country_id
            and o.effect_from       = I_effect_from
            and o.effect_to         = I_effect_to
            and a.nom_flag_2       in ('+','-')
            and not exists (select 'x'
                              from ce_charges c
                             where c.ce_id                 = I_ce_id
                               and c.vessel_id             = I_vessel_id
                               and c.voyage_flt_id         = I_voyage_flt_id
                               and c.estimated_depart_date = I_estimated_depart_date
                               and c.order_no              = I_order_no
                               and c.item                  = I_item
                               and ((c.pack_item           = I_pack_item
                                     and I_pack_item is not NULL)
                                or (c.pack_item is NULL and I_pack_item is NULL))
                               and c.hts                   = I_hts
                               and c.effect_from           = I_effect_from
                               and c.effect_to             = I_effect_to
                               and c.comp_id               = a.comp_id);

      if GET_MAX_SEQ_NO(O_error_message,
                        L_seq_no,
                        I_ce_id,
                        I_vessel_id,
                        I_voyage_flt_id,
                        I_estimated_depart_date,
                        I_order_no,
                        I_item,
                        I_pack_item) = FALSE then
         return FALSE;
      end if;
      ---
      -- Insert MPF Component if it was not associated with the Order/Item/HTS
      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
      insert into ce_charges(ce_id,
                             vessel_id,
                             voyage_flt_id,
                             estimated_depart_date,
                             order_no,
                             item,
                             seq_no,
                             pack_item,
                             hts,
                             effect_from,
                             effect_to,
                             comp_id,
                             comp_rate,
                             per_count_uom,
                             comp_value,
                             cvb_code)
         select I_ce_id,
                I_vessel_id,
                I_voyage_flt_id,
                I_estimated_depart_date,
                I_order_no,
                I_item,
                L_seq_no + rownum,
                I_pack_item,
                I_hts,
                I_effect_from,
                I_effect_to,
                ec.comp_id,
                (ec.comp_rate / NVL(ec.per_count,1)),
                ec.per_count_uom,
                0,
                DECODE(ec.calc_basis, 'S', NULL, NVL(I_cvb_code, ec.cvb_code))
           from elc_comp ec
          where ec.comp_id         like 'MPF'||I_import_country_id
            and ec.import_country_id  = I_import_country_id
            and not exists (select 'x'
                              from ce_charges c
                             where c.ce_id                 = I_ce_id
                               and c.vessel_id             = I_vessel_id
                               and c.voyage_flt_id         = I_voyage_flt_id
                               and c.estimated_depart_date = I_estimated_depart_date
                               and c.order_no              = I_order_no
                               and c.item                  = I_item
                               and ((c.pack_item           = I_pack_item
                                     and I_pack_item is not NULL)
                                or (c.pack_item is NULL and I_pack_item is NULL))
                               and c.hts                   = I_hts
                               and c.effect_from           = I_effect_from
                               and c.effect_to             = I_effect_to
                               and c.comp_id               = ec.comp_id);
      ---
      if GET_MAX_SEQ_NO(O_error_message,
                        L_seq_no,
                        I_ce_id,
                        I_vessel_id,
                        I_voyage_flt_id,
                        I_estimated_depart_date,
                        I_order_no,
                        I_item,
                        I_pack_item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_water_mode_ind = 'Y' and
         L_hmf_exists     = 'N' then
         insert into ce_charges (ce_id,
                                 vessel_id,
                                 voyage_flt_id,
                                 estimated_depart_date,
                                 order_no,
                                 item,
                                 seq_no,
                                 pack_item,
                                 hts,
                                 effect_from,
                                 effect_to,
                                 comp_id,
                                 comp_rate,
                                 per_count_uom,
                                 comp_value,
                                 cvb_code)
         select I_ce_id,
                I_vessel_id,
                I_voyage_flt_id,
                I_estimated_depart_date,
                I_order_no,
                I_item,
                L_seq_no + rownum,
                I_pack_item,
                I_hts,
                I_effect_from,
                I_effect_to,
                ec.comp_id,
                ec.comp_rate/ NVL(ec.per_count,1),
                ec.per_count_uom,
                0,
                NVL(I_cvb_code, ec.cvb_code)
           from elc_comp ec
          where ec.comp_id            like 'HMF%'
            and ec.import_country_id  = I_import_country_id
            and not exists (select 'x'
                              from ce_charges c
                             where c.ce_id                 = I_ce_id
                               and c.vessel_id             = I_vessel_id
                               and c.voyage_flt_id         = I_voyage_flt_id
                               and c.estimated_depart_date = I_estimated_depart_date
                               and c.order_no              = I_order_no
                               and c.item                  = I_item
                               and ((c.pack_item           = I_pack_item
                                     and I_pack_item is not NULL)
                                or (c.pack_item is NULL and I_pack_item is NULL))
                               and c.hts                   = I_hts
                               and c.effect_from           = I_effect_from
                               and c.effect_to             = I_effect_to
                               and c.comp_id               like 'HMF%');
      end if;
      ---
      -- record does not exist for hts/order/item combination
      ---
   else
      --- retrieve the origin country of the order/item combination
      if ORDER_ITEM_ATTRIB_SQL.GET_ORIGIN_COUNTRY(O_error_message,
                                                  L_oc_exists,
                                                  L_origin_country_id,
                                                  I_order_no,
                                                  NVL(I_pack_item, I_item)) = FALSE then
         return FALSE;
      end if;
      ---
      if L_oc_exists = FALSE then
         O_error_message := SQL_LIB.CREATE_MSG('ERR_RETRIEVE_ORIGIN_CO',NULL,NULL,NULL);
         return FALSE;
      end if;
      ---
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
      ---
      -- Insert Assessments with the Always Default Indicator set to 'Y'.
      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
      insert into ce_charges(ce_id,
                             vessel_id,
                             voyage_flt_id,
                             estimated_depart_date,
                             order_no,
                             item,
                             seq_no,
                             pack_item,
                             hts,
                             effect_from,
                             effect_to,
                             comp_id,
                             comp_rate,
                             per_count_uom,
                             comp_value,
                             cvb_code)
         select I_ce_id,
                I_vessel_id,
                I_voyage_flt_id,
                I_estimated_depart_date,
                I_order_no,
                I_item,
                L_seq_no + rownum,
                I_pack_item,
                I_hts,
                I_effect_from,
                I_effect_to,
                ec.comp_id,
                (ec.comp_rate / NVL(ec.per_count,1)),
                ec.per_count_uom,
                0,
                DECODE(ec.calc_basis, 'S', NULL, NVL(I_cvb_code, ec.cvb_code))
           from elc_comp ec
          where ec.comp_type          = 'A'
            and ec.import_country_id  = I_import_country_id
            and ec.nom_flag_2         in ('+','-')
            and ec.always_default_ind = 'Y'
            and not exists (select 'x'
                              from ce_charges c
                             where c.ce_id                 = I_ce_id
                               and c.vessel_id             = I_vessel_id
                               and c.voyage_flt_id         = I_voyage_flt_id
                               and c.estimated_depart_date = I_estimated_depart_date
                               and c.order_no              = I_order_no
                               and c.item                  = I_item
                               and ((c.pack_item           = I_pack_item
                                     and I_pack_item is not NULL)
                                   or (c.pack_item is NULL and I_pack_item is NULL))
                               and c.hts                   = I_hts
                               and c.effect_from           = I_effect_from
                               and c.effect_to             = I_effect_to
                               and c.comp_id               = ec.comp_id);


      if GET_MAX_SEQ_NO(O_error_message,
                        L_seq_no,
                        I_ce_id,
                        I_vessel_id,
                        I_voyage_flt_id,
                        I_estimated_depart_date,
                        I_order_no,
                        I_item,
                        I_pack_item) = FALSE then
         return FALSE;
      end if;
      ---
      if L_water_mode_ind = 'Y' then
         insert into ce_charges (ce_id,
                                 vessel_id,
                                 voyage_flt_id,
                                 estimated_depart_date,
                                 order_no,
                                 item,
                                 seq_no,
                                 pack_item,
                                 hts,
                                 effect_from,
                                 effect_to,
                                 comp_id,
                                 comp_rate,
                                 per_count_uom,
                                 comp_value,
                                 cvb_code)
         select I_ce_id,
                I_vessel_id,
                I_voyage_flt_id,
                I_estimated_depart_date,
                I_order_no,
                I_item,
                L_seq_no + rownum,
                I_pack_item,
                I_hts,
                I_effect_from,
                I_effect_to,
                ec.comp_id,
                ec.comp_rate/ NVL(ec.per_count,1),
                ec.per_count_uom,
                0,
                NVL(I_cvb_code, ec.cvb_code)
           from elc_comp ec
          where ec.comp_id            like 'HMF%'
            and ec.import_country_id  = I_import_country_id
            and not exists (select 'x'
                              from ce_charges c
                             where c.ce_id                 = I_ce_id
                               and c.vessel_id             = I_vessel_id
                               and c.voyage_flt_id         = I_voyage_flt_id
                               and c.estimated_depart_date = I_estimated_depart_date
                               and c.order_no              = I_order_no
                               and c.item                  = I_item
                               and ((c.pack_item           = I_pack_item
                                     and I_pack_item is not NULL)
                                   or (c.pack_item is NULL and I_pack_item is NULL))
                               and c.hts                   = I_hts
                               and c.effect_from           = I_effect_from
                               and c.effect_to             = I_effect_to
                               and c.comp_id               = ec.comp_id);
      end if;

      -- Insert the Duty Assessments from the Estimated Landed Cost Components table.

      if L_duty_comp_code = '0' then
         L_comp_rate     := 0;
         L_per_count     := NULL;
         L_per_count_uom := NULL;
      end if;
      ---
      if L_duty_comp_code in ('1','3','4','6','C') then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_1;
      end if;
      ---
      if L_duty_comp_code in ('2','5','E') then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_2;
      end if;
      ---
      if L_duty_comp_code in ('7','9') then
         L_comp_rate     := L_av_rate;
         L_per_count     := NULL;
         L_per_count_uom := NULL;
      end if;
      ---
      if L_duty_comp_code = 'D' then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_3;
      end if;
      ---
      L_comp_id := 'DTY'||L_duty_comp_code||'A'||I_import_country_id;
      ---
      if L_duty_comp_code in ('0','1','2','3','4','5','6','7','9','C','D','E') then
         if GET_MAX_SEQ_NO(O_error_message,
                           L_seq_no,
                           I_ce_id,
                           I_vessel_id,
                           I_voyage_flt_id,
                           I_estimated_depart_date,
                           I_order_no,
                           I_item,
                           I_pack_item) = FALSE then
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
         insert into ce_charges(ce_id,
                                vessel_id,
                                voyage_flt_id,
                                estimated_depart_date,
                                order_no,
                                item,
                                seq_no,
                                pack_item,
                                hts,
                                effect_from,
                                effect_to,
                                comp_id,
                                comp_rate,
                                per_count_uom,
                                comp_value,
                                cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   NVL(L_comp_rate, elc.comp_rate/elc.per_count),
                   decode(L_duty_comp_code, '0', NULL,
                                            '7', NULL,
                                            '9', NULL,
                                            NVL(L_per_count_uom, elc.per_count_uom)),
                   0,
                   DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'x'
                                 from ce_charges cc
                                where cc.ce_id                 = I_ce_id
                                  and cc.vessel_id             = I_vessel_id
                                  and cc.voyage_flt_id         = I_voyage_flt_id
                                  and cc.estimated_depart_date = I_estimated_depart_date
                                  and cc.order_no              = I_order_no
                                  and cc.item                  = I_item
                                  and ((cc.pack_item           = I_pack_item
                                        and I_pack_item is not NULL)
                                   or (cc.pack_item is NULL and I_pack_item is NULL))
                                  and cc.hts                   = I_hts
                                  and cc.effect_from           = I_effect_from
                                  and cc.effect_to             = I_effect_to
                                  and cc.comp_id               = elc.comp_id);
      end if;
      ---
      if L_duty_comp_code in ('3','6') then
         L_comp_rate     := L_other_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_2;
      end if;
      ---
      if L_duty_comp_code in ('4','5','D') then
         L_comp_rate     := L_av_rate;
         L_per_count     := NULL;
         L_per_count_uom := NULL;
      end if;
      ---
      if L_duty_comp_code = 'E' then
         L_comp_rate     := L_other_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_3;
      end if;
      ---
      L_comp_id := 'DTY'||L_duty_comp_code||'B'||I_import_country_id;
      ---
      if L_duty_comp_code in ('3','4','5','6','D','E') then
         if GET_MAX_SEQ_NO(O_error_message,
                           L_seq_no,
                           I_ce_id,
                           I_vessel_id,
                           I_voyage_flt_id,
                           I_estimated_depart_date,
                           I_order_no,
                           I_item,
                           I_pack_item) = FALSE then
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
         insert into ce_charges(ce_id,
                                vessel_id,
                                voyage_flt_id,
                                estimated_depart_date,
                                order_no,
                                item,
                                seq_no,
                                pack_item,
                                hts,
                                effect_from,
                                effect_to,
                                comp_id,
                                comp_rate,
                                per_count_uom,
                                comp_value,
                                cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   NVL(L_comp_rate, elc.comp_rate/elc.per_count),
                   decode(L_duty_comp_code, '0', NULL,
                                            '7', NULL,
                                            '9', NULL,
                                            NVL(L_per_count_uom, elc.per_count_uom)),
                   0,
                   DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from ce_charges cc
                                where cc.ce_id                 = I_ce_id
                                  and cc.vessel_id             = I_vessel_id
                                  and cc.voyage_flt_id         = I_voyage_flt_id
                                  and cc.estimated_depart_date = I_estimated_depart_date
                                  and cc.order_no              = I_order_no
                                  and cc.item                  = I_item
                                  and ((cc.pack_item            = I_pack_item
                                        and I_pack_item is not NULL)
                                   or (cc.pack_item is NULL and I_pack_item is NULL))
                                  and cc.hts                   = I_hts
                                  and cc.effect_from           = I_effect_from
                                  and cc.effect_to             = I_effect_to
                                  and cc.comp_id               = elc.comp_id);
      end if;
      ---
      L_comp_id := 'DTY'||L_duty_comp_code||'C'||I_import_country_id;
      ---
      if L_duty_comp_code in ('6','E') then
         if GET_MAX_SEQ_NO(O_error_message,
                           L_seq_no,
                           I_ce_id,
                           I_vessel_id,
                           I_voyage_flt_id,
                           I_estimated_depart_date,
                           I_order_no,
                           I_item,
                           I_pack_item) = FALSE then
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
         insert into ce_charges(ce_id,
                                vessel_id,
                                voyage_flt_id,
                                estimated_depart_date,
                                order_no,
                                item,
                                seq_no,
                                pack_item,
                                hts,
                                effect_from,
                                effect_to,
                                comp_id,
                                comp_rate,
                                per_count_uom,
                                comp_value,
                                cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   NVL(L_av_rate, elc.comp_rate),
                   NULL,
                   0,
                   DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from ce_charges cc
                                where cc.ce_id                 = I_ce_id
                                  and cc.vessel_id             = I_vessel_id
                                  and cc.voyage_flt_id         = I_voyage_flt_id
                                  and cc.estimated_depart_date = I_estimated_depart_date
                                  and cc.order_no              = I_order_no
                                  and cc.item                  = I_item
                                  and ((cc.pack_item            = I_pack_item
                                        and I_pack_item is not NULL)
                                   or (cc.pack_item is NULL and I_pack_item is NULL))
                                  and cc.hts                   = I_hts
                                  and cc.effect_from           = I_effect_from
                                  and cc.effect_to             = I_effect_to
                                  and cc.comp_id               = elc.comp_id);
      end if;

      -- Insert the Tax Assessments from the Estimated Landed Cost Components table.

   for C_GET_TAX_INFO_REC in C_GET_TAX_INFO loop
      L_tax_type       := C_GET_TAX_INFO_REC.tax_type;
      L_tax_comp_code  := C_GET_TAX_INFO_REC.tax_comp_code;
      L_specific_rate  := C_GET_TAX_INFO_REC.tax_specific_rate;
      L_av_rate        := C_GET_TAX_INFO_REC.tax_av_rate;

      ---
      if L_tax_comp_code in ('1','4','C') then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_1;
      end if;
      ---
      if L_tax_comp_code in ('2','5') then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_2;
      end if;
      ---
      if L_tax_comp_code in ('7','9') then
         L_comp_rate     := L_av_rate;
         L_per_count     := NULL;
         L_per_count_uom := NULL;
      end if;
      ---
      if L_tax_comp_code = 'D' then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_3;
      end if;
      ---
      L_comp_id := L_tax_type||L_tax_comp_code||'A'||I_import_country_id;
      ---
      if L_tax_comp_code in ('1','2','4','5','7','9','C','D') then
         if GET_MAX_SEQ_NO(O_error_message,
                           L_seq_no,
                           I_ce_id,
                           I_vessel_id,
                           I_voyage_flt_id,
                           I_estimated_depart_date,
                           I_order_no,
                           I_item,
                           I_pack_item) = FALSE then
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
         insert into ce_charges(ce_id,
                                vessel_id,
                                voyage_flt_id,
                                estimated_depart_date,
                                order_no,
                                item,
                                seq_no,
                                pack_item,
                                hts,
                                effect_from,
                                effect_to,
                                comp_id,
                                comp_rate,
                                per_count_uom,
                                comp_value,
                                cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   NVL(L_comp_rate, elc.comp_rate/elc.per_count),
                   decode(L_tax_comp_code, '7', NULL,
                                           '9', NULL,
                                           NVL(L_per_count_uom, elc.per_count_uom)),
                   0,
                   DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from ce_charges cc
                                where cc.ce_id                 = I_ce_id
                                  and cc.vessel_id             = I_vessel_id
                                  and cc.voyage_flt_id         = I_voyage_flt_id
                                  and cc.estimated_depart_date = I_estimated_depart_date
                                  and cc.order_no              = I_order_no
                                  and cc.item                  = I_item
                                  and ((cc.pack_item            = I_pack_item
                                        and I_pack_item is not NULL)
                                   or (cc.pack_item is NULL and I_pack_item is NULL))
                                  and cc.hts                   = I_hts
                                  and cc.effect_from           = I_effect_from
                                  and cc.effect_to             = I_effect_to
                                  and cc.comp_id               = elc.comp_id);
      end if;
      ---
      L_comp_id := L_tax_type||L_tax_comp_code||'B'||I_import_country_id;
      ---
      if L_tax_comp_code in ('4','5','D') then
         if GET_MAX_SEQ_NO(O_error_message,
                           L_seq_no,
                           I_ce_id,
                           I_vessel_id,
                           I_voyage_flt_id,
                           I_estimated_depart_date,
                           I_order_no,
                           I_item,
                           I_pack_item) = FALSE then
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
         insert into ce_charges(ce_id,
                                vessel_id,
                                voyage_flt_id,
                                estimated_depart_date,
                                order_no,
                                item,
                                seq_no,
                                pack_item,
                                hts,
                                effect_from,
                                effect_to,
                                comp_id,
                                comp_rate,
                                per_count_uom,
                                comp_value,
                                cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   NVL(L_av_rate, elc.comp_rate),
                   NULL,
                   0,
                   DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from ce_charges cc
                                where cc.ce_id                 = I_ce_id
                                  and cc.vessel_id             = I_vessel_id
                                  and cc.voyage_flt_id         = I_voyage_flt_id
                                  and cc.estimated_depart_date = I_estimated_depart_date
                                  and cc.order_no              = I_order_no
                                  and cc.item                  = I_item
                                  and ((cc.pack_item            = I_pack_item
                                        and I_pack_item is not NULL)
                                   or (cc.pack_item is NULL and I_pack_item is NULL))
                                  and cc.hts                   = I_hts
                                  and cc.effect_from           = I_effect_from
                                  and cc.effect_to             = I_effect_to
                                  and cc.comp_id               = elc.comp_id);
      end if;
   end loop;
      -- Insert the Fee Assessments from the Estimated Landed Cost Components table.

   for C_GET_FEE_INFO_REC in C_GET_FEE_INFO loop
      L_fee_type       := C_GET_FEE_INFO_REC.fee_type;
      L_fee_comp_code  := C_GET_FEE_INFO_REC.fee_comp_code;
      L_specific_rate  := C_GET_FEE_INFO_REC.fee_specific_rate;
      L_av_rate        := C_GET_FEE_INFO_REC.fee_av_rate;
      ---
      if L_fee_comp_code in ('1','4','C') then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_1;
      end if;
      ---
      if L_fee_comp_code in ('2','5') then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_2;
      end if;
      ---
      if L_fee_comp_code in ('7','9') then
         L_comp_rate     := L_av_rate;
         L_per_count     := NULL;
         L_per_count_uom := NULL;
      end if;
      ---
      if L_fee_comp_code = 'D' then
         L_comp_rate     := L_specific_rate;
         L_per_count     := 1;
         L_per_count_uom := L_units_3;
      end if;
      ---
      L_comp_id := L_fee_type||L_fee_comp_code||'A'||I_import_country_id;
      ---
      if L_fee_comp_code in ('1','2','4','5','7','9','C','D') then
         if GET_MAX_SEQ_NO(O_error_message,
                           L_seq_no,
                           I_ce_id,
                           I_vessel_id,
                           I_voyage_flt_id,
                           I_estimated_depart_date,
                           I_order_no,
                           I_item,
                           I_pack_item) = FALSE then
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
         insert into ce_charges(ce_id,
                                vessel_id,
                                voyage_flt_id,
                                estimated_depart_date,
                                order_no,
                                item,
                                seq_no,
                                pack_item,
                                hts,
                                effect_from,
                                effect_to,
                                comp_id,
                                comp_rate,
                                per_count_uom,
                                comp_value,
                                cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   NVL(L_comp_rate, elc.comp_rate/elc.per_count),
                   decode(L_fee_comp_code, '7', NULL,
                                           '9', NULL,
                                           NVL(L_per_count_uom, elc.per_count_uom)),
                   0,
                   DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from ce_charges cc
                                where cc.ce_id                 = I_ce_id
                                  and cc.vessel_id             = I_vessel_id
                                  and cc.voyage_flt_id         = I_voyage_flt_id
                                  and cc.estimated_depart_date = I_estimated_depart_date
                                  and cc.order_no              = I_order_no
                                  and cc.item                  = I_item
                                  and ((cc.pack_item            = I_pack_item
                                        and I_pack_item is not NULL)
                                   or (cc.pack_item is NULL and I_pack_item is NULL))
                                  and cc.hts                   = I_hts
                                  and cc.effect_from           = I_effect_from
                                  and cc.effect_to             = I_effect_to
                                  and cc.comp_id               = elc.comp_id);
      end if;
      ---
      L_comp_id := L_fee_type||L_fee_comp_code||'B'||I_import_country_id;
      ---
      if L_fee_comp_code in ('4','5','D') then
         if GET_MAX_SEQ_NO(O_error_message,
                           L_seq_no,
                           I_ce_id,
                           I_vessel_id,
                           I_voyage_flt_id,
                           I_estimated_depart_date,
                           I_order_no,
                           I_item,
                           I_pack_item) = FALSE then
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
         insert into ce_charges(ce_id,
                                vessel_id,
                                voyage_flt_id,
                                estimated_depart_date,
                                order_no,
                                item,
                                seq_no,
                                pack_item,
                                hts,
                                effect_from,
                                effect_to,
                                comp_id,
                                comp_rate,
                                per_count_uom,
                                comp_value,
                                cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   NVL(L_av_rate, elc.comp_rate),
                   NULL,
                   0,
                   DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from ce_charges cc
                                where cc.ce_id                 = I_ce_id
                                  and cc.vessel_id             = I_vessel_id
                                  and cc.voyage_flt_id         = I_voyage_flt_id
                                  and cc.estimated_depart_date = I_estimated_depart_date
                                  and cc.order_no              = I_order_no
                                  and cc.item                  = I_item
                                  and ((cc.pack_item           = I_pack_item
                                        and I_pack_item is not NULL)
                                   or (cc.pack_item is NULL and I_pack_item is NULL))
                                  and cc.hts                   = I_hts
                                  and cc.effect_from           = I_effect_from
                                  and cc.effect_to             = I_effect_to
                                  and cc.comp_id               = elc.comp_id);
      end if;
   end loop;

      -- Insert the CVD (Countervailing) Assessments
      -- from the Estimated Landed Cost Components table.
      ---
      if L_cvd_case_no is not NULL then
         SQL_LIB.SET_MARK('OPEN','C_GET_CVD_RATE', 'HTS_CVD', NULL);
         open C_GET_CVD_RATE;
         SQL_LIB.SET_MARK('FETCH','C_GET_CVD_RATE', 'HTS_CVD', NULL);
         fetch C_GET_CVD_RATE into L_comp_rate;
         if C_GET_CVD_RATE%FOUND then
            if GET_MAX_SEQ_NO(O_error_message,
                              L_seq_no,
                              I_ce_id,
                              I_vessel_id,
                              I_voyage_flt_id,
                              I_estimated_depart_date,
                              I_order_no,
                              I_item,
                              I_pack_item) = FALSE then
               return FALSE;
            end if;

            SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
            insert into ce_charges(ce_id,
                                   vessel_id,
                                   voyage_flt_id,
                                   estimated_depart_date,
                                   order_no,
                                   item,
                                   seq_no,
                                   pack_item,
                                   hts,
                                   effect_from,
                                   effect_to,
                                   comp_id,
                                   comp_rate,
                                   per_count_uom,
                                   comp_value,
                                   cvb_code)
               select I_ce_id,
                      I_vessel_id,
                      I_voyage_flt_id,
                      I_estimated_depart_date,
                      I_order_no,
                      I_item,
                      L_seq_no + rownum,
                      I_pack_item,
                      I_hts,
                      I_effect_from,
                      I_effect_to,
                      elc.comp_id,
                      NVL(L_comp_rate, elc.comp_rate),
                      NULL,
                      0,
                      DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
                 from elc_comp elc
                where elc.comp_id           = 'CVD'||I_import_country_id
                  and elc.comp_type         = 'A'
                  and elc.import_country_id = I_import_country_id
                  and not exists (select 'Y'
                                    from ce_charges cc
                                   where cc.ce_id                 = I_ce_id
                                     and cc.vessel_id             = I_vessel_id
                                     and cc.voyage_flt_id         = I_voyage_flt_id
                                     and cc.estimated_depart_date = I_estimated_depart_date
                                     and cc.order_no              = I_order_no
                                     and cc.item                  = I_item
                                     and ((cc.pack_item           = I_pack_item
                                           and I_pack_item is not NULL)
                                      or (cc.pack_item is NULL and I_pack_item is NULL))
                                     and cc.hts                   = I_hts
                                     and cc.effect_from           = I_effect_from
                                     and cc.effect_to             = I_effect_to
                                     and cc.comp_id               = elc.comp_id);
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_GET_CVD_RATE', 'HTS_CVD', NULL);
         close C_GET_CVD_RATE;
      end if; -- L_cvd_case_no is not NULL
      ---
      -- Insert the AD (Anti-Dumping) Assessments
      -- from the Estimated Landed Cost Components table.
      ---
      if L_ad_case_no is not NULL then
         SQL_LIB.SET_MARK('OPEN','C_GET_AD_RATE', 'HTS_AD', NULL);
         open C_GET_AD_RATE;
         SQL_LIB.SET_MARK('FETCH','C_GET_AD_RATE', 'HTS_AD', NULL);
         fetch C_GET_AD_RATE into L_comp_rate;
         if C_GET_AD_RATE%FOUND then
            if GET_MAX_SEQ_NO(O_error_message,
                              L_seq_no,
                              I_ce_id,
                              I_vessel_id,
                              I_voyage_flt_id,
                              I_estimated_depart_date,
                              I_order_no,
                              I_item,
                              I_pack_item) = FALSE then
               return FALSE;
            end if;

            SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
            insert into ce_charges(ce_id,
                                   vessel_id,
                                   voyage_flt_id,
                                   estimated_depart_date,
                                   order_no,
                                   item,
                                   seq_no,
                                   pack_item,
                                   hts,
                                   effect_from,
                                   effect_to,
                                   comp_id,
                                   comp_rate,
                                   per_count_uom,
                                   comp_value,
                                   cvb_code)
               select I_ce_id,
                      I_vessel_id,
                      I_voyage_flt_id,
                      I_estimated_depart_date,
                      I_order_no,
                      I_item,
                      L_seq_no + rownum,
                      I_pack_item,
                      I_hts,
                      I_effect_from,
                      I_effect_to,
                      elc.comp_id,
                      NVL(L_comp_rate, elc.comp_rate),
                      NULL,
                      0,
                      DECODE(elc.calc_basis, 'S', NULL, NVL(I_cvb_code, elc.cvb_code))
                 from elc_comp elc
                where elc.comp_id           = 'AD'||I_import_country_id
                  and elc.comp_type         = 'A'
                  and elc.import_country_id = I_import_country_id
                  and not exists (select 'Y'
                                    from ce_charges cc
                                   where cc.ce_id                 = I_ce_id
                                     and cc.vessel_id             = I_vessel_id
                                     and cc.voyage_flt_id         = I_voyage_flt_id
                                     and cc.estimated_depart_date = I_estimated_depart_date
                                     and cc.order_no              = I_order_no
                                     and cc.item                  = I_item
                                     and ((cc.pack_item            = I_pack_item
                                           and I_pack_item is not NULL)
                                      or (cc.pack_item is NULL and I_pack_item is NULL))
                                     and cc.hts                   = I_hts
                                     and cc.effect_from           = I_effect_from
                                     and cc.effect_to             = I_effect_to
                                     and cc.comp_id               = elc.comp_id);
         end if;
         SQL_LIB.SET_MARK('CLOSE','C_GET_AD_RATE', 'HTS_AD', NULL);
         close C_GET_AD_RATE;
      end if;  -- if L_ad_case_no is not NULL
   end if;
   ---
   -- Assessment components need to be converted into customs entry
   -- currency.
   ---
   for C_CONVERT_CURRENCY_REC in C_CONVERT_CURRENCY loop
      L_elc_currency     := C_CONVERT_CURRENCY_REC.comp_currency;
      L_ce_charge_seq_no := C_CONVERT_CURRENCY_REC.seq_no;
      L_ce_comp_rate     := C_CONVERT_CURRENCY_REC.comp_rate;
      L_ce_comp_value    := C_CONVERT_CURRENCY_REC.comp_value;
      L_ce_per_count_uom := C_CONVERT_CURRENCY_REC.per_count_uom;

      --- convert from component currency to customs entry currency
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_ce_comp_value,
                              L_elc_currency,
                              L_ce_currency,
                              L_ce_comp_value,
                              'C',
                              NULL,
                              NULL,
                              NULL,
                              L_ce_exchange_rate) = FALSE then
         return FALSE;
      end if;
      ---
      if L_ce_per_count_uom is not NULL then
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_ce_comp_rate,
                                 L_elc_currency,
                                 L_ce_currency,
                                 L_ce_comp_rate,
                                 'C',
                                 NULL,
                                 NULL,
                                 NULL,
                                 L_ce_exchange_rate) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      L_table := 'CE_CHARGES';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
      open C_LOCK_CE_CHARGES;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
      close C_LOCK_CE_CHARGES;

      SQL_LIB.SET_MARK('UPDATE',NULL,'CE_CHARGES',NULL);
      update ce_charges
         set comp_rate  = L_ce_comp_rate,
             comp_value = L_ce_comp_value
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and ((pack_item           = I_pack_item
               and pack_item      is not NULL
               and I_pack_item    is not NULL)
             or (pack_item        is NULL
                 and I_pack_item  is NULL))
         and seq_no                = L_ce_charge_seq_no;
   end loop;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            'CE_CHARGES',
                                            NULL,
                                            NULL);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_COMPS;
--------------------------------------------------------------------------------------
FUNCTION INSERT_COMPS(O_error_message         IN OUT VARCHAR2,
                      I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                      I_vessel_id             IN     CE_SHIPMENT.VESSEL_ID%TYPE,
                      I_voyage_flt_id         IN     CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                      I_estimated_depart_date IN     CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                      I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                      I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                      I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                      I_hts                   IN     HTS.HTS%TYPE,
                      I_import_country_id     IN     COUNTRY.COUNTRY_ID%TYPE,
                      I_effect_from           IN     HTS.EFFECT_FROM%TYPE,
                      I_effect_to             IN     HTS.EFFECT_TO%TYPE)

RETURN BOOLEAN IS

 L_program           VARCHAR2(50)            := 'CE_CHARGES_SQL.INSERT_COMPS';


BEGIN
   if CE_CHARGES_SQL.INSERT_COMPS(O_error_message,
                                  I_ce_id,
                                  I_vessel_id,
                                  I_voyage_flt_id,
                                  I_estimated_depart_date,
                                  I_order_no,
                                  I_item,
                                  I_pack_item,
                                  I_hts,
                                  I_import_country_id,
                                  I_effect_from,
                                  I_effect_to,
                                  NULL) = FALSE then
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
END INSERT_COMPS;
--------------------------------------------------------------------------------------
FUNCTION CALC_TOTALS(O_error_message     IN OUT   VARCHAR2,
                     O_total_duty        IN OUT   CE_CHARGES.COMP_VALUE%TYPE,
                     O_total_vfd         IN OUT   CE_CHARGES.COMP_VALUE%TYPE,
                     O_total_taxes       IN OUT   CE_CHARGES.COMP_VALUE%TYPE,
                     O_total_other       IN OUT   CE_CHARGES.COMP_VALUE%TYPE,
                     O_total_est_assess  IN OUT   CE_CHARGES.COMP_VALUE%TYPE,
                     I_ce_id             IN       CE_HEAD.CE_ID%TYPE)
RETURN BOOLEAN IS
   L_program               VARCHAR2(50) := 'CE_CHARGES_SQL.CALC_TOTALS';
   L_vessel_id             CE_ORD_ITEM.VESSEL_ID%TYPE;
   L_voyage_flt_id         CE_ORD_ITEM.VOYAGE_FLT_ID%TYPE;
   L_estimated_depart_date CE_ORD_ITEM.ESTIMATED_DEPART_DATE%TYPE;
   L_order_no              CE_ORD_ITEM.ORDER_NO%TYPE;
   L_item                  CE_ORD_ITEM.ITEM%TYPE;
   L_pack_item             PACKITEM.PACK_NO%TYPE;
   L_manifest_item_qty     CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE;
   L_manifest_item_qty_uom CE_ORD_ITEM.MANIFEST_ITEM_QTY_UOM%TYPE;
   L_cleared_qty           CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_cleared_qty_uom       CE_ORD_ITEM.CLEARED_QTY_UOM%TYPE;
   L_carton_qty            CE_ORD_ITEM.CARTON_QTY%TYPE;
   L_carton_qty_uom        CE_ORD_ITEM.CARTON_QTY_UOM%TYPE;
   L_gross_wt              CE_ORD_ITEM.GROSS_WT%TYPE;
   L_gross_wt_uom          CE_ORD_ITEM.GROSS_WT_UOM%TYPE;
   L_cubic                 CE_ORD_ITEM.CUBIC%TYPE;
   L_cubic_uom             CE_ORD_ITEM.CUBIC_UOM%TYPE;
   L_net_wt                CE_ORD_ITEM.NET_WT%TYPE;
   L_net_wt_uom            CE_ORD_ITEM.NET_WT_UOM%TYPE;
   L_import_country_id     CE_HEAD.IMPORT_COUNTRY_ID%TYPE;
   L_currency_code         CE_HEAD.CURRENCY_CODE%TYPE;
   L_exchange_rate         CE_HEAD.EXCHANGE_RATE%TYPE;
   L_duty_value            CE_CHARGES.COMP_VALUE%TYPE;
   L_tax_value             CE_CHARGES.COMP_VALUE%TYPE;
   L_other_value           CE_CHARGES.COMP_VALUE%TYPE;
   L_qty                   CE_ORD_ITEM.CLEARED_QTY%TYPE;
   L_qty_uom               CE_ORD_ITEM.CUBIC_UOM%TYPE;
   L_combo_oper            CVB_DETAIL.COMBO_OPER%TYPE;
   L_packitem_qty          V_PACKSKU_QTY.QTY%TYPE;
   L_standard_class        UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor           UOM_CONVERSION.FACTOR%TYPE;
   L_standard_uom          UOM_CLASS.UOM%TYPE;
   L_comp_currency         ORDLOC_EXP.COMP_CURRENCY%TYPE;
   L_pack_qty              CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE;
   L_pack_uom              UOM_CLASS.UOM%TYPE;
   L_location              ORDLOC.LOCATION%TYPE;
   L_qty_ordered           ORDLOC.QTY_ORDERED%TYPE;
   L_est_exp_value         ORDLOC_EXP.EST_EXP_VALUE%TYPE;
   L_total_value           ORDLOC_EXP.EST_EXP_VALUE%TYPE       := 0;
   L_total_dty             ORDLOC_EXP.EST_EXP_VALUE%TYPE;
   L_dty_currency          ORDLOC_EXP.COMP_CURRENCY%TYPE;
   L_value                 ORDLOC_EXP.EST_EXP_VALUE%TYPE       := 0;
   L_vfd_exchange_rate     ORDLOC_EXP.EXCHANGE_RATE%TYPE;
   L_est_exp_value_ce      ORDLOC_EXP.EST_EXP_VALUE%TYPE;
   L_total_order_qty       ORDLOC.QTY_ORDERED%TYPE;
   L_supplier              SUPS.SUPPLIER%TYPE;
   L_origin_country_id     COUNTRY.COUNTRY_ID%TYPE;
   L_est_assess            ORDLOC_EXP.EST_EXP_VALUE%TYPE       := 0;
   L_tdty_comp_id          ELC_COMP.COMP_ID%TYPE;

   cursor C_GET_QTY is
      select distinct co.vessel_id       vessel_id,
             co.voyage_flt_id            voyage_flt_id,
             co.estimated_depart_date    estimated_depart_date,
             co.order_no                 order_no,
             cc.item                     item,
             cc.pack_item                pack_item,
             NVL(co.manifest_item_qty,0) manifest_item,
             co.manifest_item_qty_uom,
             NVL(co.cleared_qty,0)       cleared,
             co.cleared_qty_uom,
             NVL(co.carton_qty,0)        carton,
             co.carton_qty_uom,
             NVL(co.gross_wt,0)          gross,
             co.gross_wt_uom,
             NVL(co.cubic,0)             cubic,
             co.cubic_uom,
             NVL(co.net_wt,0)            net,
             co.net_wt_uom,
             ch.currency_code,
             ch.exchange_rate,
             ch.import_country_id
        from ce_head     ch,
             ce_shipment cs,
             ce_ord_item co,
             ce_charges  cc
       where ch.ce_id                 = I_ce_id
         and ch.ce_id                 = cs.ce_id
         and cs.ce_id                 = co.ce_id
         and cs.vessel_id             = co.vessel_id
         and cs.voyage_flt_id         = co.voyage_flt_id
         and cs.estimated_depart_date = co.estimated_depart_date
         and cc.ce_id                 = co.ce_id
         and cc.vessel_id             = co.vessel_id
         and cc.voyage_flt_id         = co.voyage_flt_id
         and cc.estimated_depart_date = co.estimated_depart_date
         and cc.order_no              = co.order_no
         and ((cc.item                = co.item
               and cc.pack_item is NULL)
          or  (cc.pack_item           = co.item
               and cc.pack_item is NOT NULL));

   cursor C_GET_DUTY_VALUE is
      select NVL(SUM(comp_value),0)
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = L_vessel_id
         and voyage_flt_id         = L_voyage_flt_id
         and estimated_depart_date = L_estimated_depart_date
         and order_no              = L_order_no
         and item                  = L_item
         and ((pack_item           = L_pack_item
               and L_pack_item is not NULL)
            or (pack_item is NULL and L_pack_item is NULL))
         and comp_id               like 'DTY%';

   cursor C_GET_VFD_TOTAL is
      select oe.est_exp_value,
             oe.comp_currency,
             oe.exchange_rate,
             cd.combo_oper
        from ordloc_exp oe,
             cvb_detail cd
       where oe.order_no          = L_order_no
         and oe.item              = L_item
         and ((oe.pack_item       = L_pack_item
               and L_pack_item is not NULL)
            or (oe.pack_item is NULL and L_pack_item is NULL))
         and cd.cvb_code          = 'VFD'||L_import_country_id
         and oe.comp_id           = cd.comp_id
         and oe.location          = L_location;

   cursor C_GET_TAX_VALUE is
      select NVL(SUM(comp_value),0)
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = L_vessel_id
         and voyage_flt_id         = L_voyage_flt_id
         and estimated_depart_date = L_estimated_depart_date
         and order_no              = L_order_no
         and item                  = L_item
         and ((pack_item           = L_pack_item
               and L_pack_item is not NULL)
             or (pack_item is NULL and L_pack_item is NULL))
         and (comp_id in (select distinct tax_type||tax_comp_code||'A'||L_import_country_id
                            from hts_tax
                           where tax_comp_code in ('1','2','4','5','C','D','7','9'))
               or (comp_id in (select distinct tax_type||tax_comp_code||'B'||L_import_country_id
                                 from hts_tax
                                where tax_comp_code in ('4','5','D'))));

   cursor C_GET_OTHER_VALUE is
      select NVL(SUM(comp_value),0)
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = L_vessel_id
         and voyage_flt_id         = L_voyage_flt_id
         and estimated_depart_date = L_estimated_depart_date
         and order_no              = L_order_no
         and item                  = L_item
         and ((pack_item           = L_pack_item
               and L_pack_item is not NULL)
            or (pack_item is NULL and L_pack_item is NULL))
         and comp_id       not like 'DTY%'
         and (comp_id not in (select distinct tax_type||tax_comp_code||'A'||L_import_country_id
                                from hts_tax
                               where tax_comp_code in ('1','2','4','5','C','D','7','9')))
         and (comp_id not in (select distinct tax_type||tax_comp_code||'B'||L_import_country_id
                                      from hts_tax
                                     where tax_comp_code in ('4','5','D')));

   cursor C_V_PACKSKU_QTY is
      select qty
        from v_packsku_qty
       where item    = L_item
         and pack_no = L_pack_item;

   cursor C_ORDLOC_QTY is
      select qty_ordered
        from ordloc
       where order_no     = L_order_no
         and ((item       = L_item
               and L_pack_item is NULL)
             or (item     = L_pack_item))
         and location     = L_location;

   cursor C_LOCATIONS is
      select distinct location
        from ordloc_exp
       where order_no     = L_order_no
         and item         = L_item
         and ((pack_item  = L_pack_item
               and L_pack_item is not NULL)
            or (pack_item is NULL
                and L_pack_item is NULL));

   cursor C_ORDHEAD_ORDSKU is
      select oh.supplier,
             os.origin_country_id
        from ordhead oh,
             ordsku os
       where oh.order_no = os.order_no
         and os.item     = NVL(L_pack_item, L_item)
         and oh.order_no = L_order_no;

   cursor C_GET_PO_TDTY is
      select NVL(SUM(a.est_assess_value), 0)
        from ordsku_hts_assess a,
             ordsku_hts h
       where h.order_no          =  L_order_no
         and h.order_no          =  a.order_no
         and h.seq_no            =  a.seq_no
         and ((L_pack_item       is NULL
              and h.item         =  L_item
              and h.pack_item    is NULL)
          or (L_pack_item        is not NULL
              and h.pack_item    =  L_pack_item
              and h.item         =  L_item))
         and h.import_country_id =  L_import_country_id
         and a.comp_id           =  L_tdty_comp_id;

   cursor C_GET_ASSESS_CURR is
      select comp_currency
        from elc_comp
       where comp_id = L_tdty_comp_id;

BEGIN
   O_total_duty       := 0;
   O_total_vfd        := 0;
   O_total_taxes      := 0;
   O_total_other      := 0;
   O_total_est_assess := 0;
   ---
   for C_GET_QTY_REC in C_GET_QTY loop
      L_vessel_id             := C_GET_QTY_REC.vessel_id;
      L_voyage_flt_id         := C_GET_QTY_REC.voyage_flt_id;
      L_estimated_depart_date := C_GET_QTY_REC.estimated_depart_date;
      L_order_no              := C_GET_QTY_REC.order_no;
      L_item                  := C_GET_QTY_REC.item;
      L_pack_item             := C_GET_QTY_REC.pack_item;
      L_manifest_item_qty     := C_GET_QTY_REC.manifest_item;
      L_manifest_item_qty_uom := C_GET_QTY_REC.manifest_item_qty_uom;
      L_cleared_qty           := C_GET_QTY_REC.cleared;
      L_cleared_qty_uom       := C_GET_QTY_REC.cleared_qty_uom;
      L_carton_qty            := C_GET_QTY_REC.carton;
      L_carton_qty_uom        := C_GET_QTY_REC.carton_qty_uom;
      L_gross_wt              := C_GET_QTY_REC.gross;
      L_gross_wt_uom          := C_GET_QTY_REC.gross_wt_uom;
      L_cubic                 := C_GET_QTY_REC.cubic;
      L_cubic_uom             := C_GET_QTY_REC.cubic_uom;
      L_net_wt                := C_GET_QTY_REC.net;
      L_net_wt_uom            := C_GET_QTY_REC.net_wt_uom;
      L_currency_code         := C_GET_QTY_REC.currency_code;
      L_exchange_rate         := C_GET_QTY_REC.exchange_rate;
      L_import_country_id     := C_GET_QTY_REC.import_country_id;
      ---
      if L_manifest_item_qty > 0 then
         L_qty     := L_manifest_item_qty;
         L_qty_uom := L_manifest_item_qty_uom;
      elsif L_cleared_qty > 0 then
         L_qty     := L_cleared_qty;
         L_qty_uom := L_cleared_qty_uom;
      elsif L_carton_qty > 0 then
         L_qty     := L_carton_qty;
         L_qty_uom := L_carton_qty_uom;
      elsif L_gross_wt > 0 then
         L_qty     := L_gross_wt;
         L_qty_uom := L_gross_wt_uom;
      elsif L_cubic > 0 then
         L_qty     := L_cubic;
         L_qty_uom := L_cubic_uom;
      else
         L_qty     := L_net_wt;
         L_qty_uom := L_net_wt_uom;
      end if;
      ---
      SQL_LIB.SET_MARK('OPEN','C_ORDHEAD_ORDSKU','ORDHEAD',NULL);
      open C_ORDHEAD_ORDSKU;
      SQL_LIB.SET_MARK('FETCH','C_ORDHEAD_ORDSKU','ORDHEAD',NULL);
      fetch C_ORDHEAD_ORDSKU into L_supplier, L_origin_country_id;
      SQL_LIB.SET_MARK('CLOSE','C_ORDHEAD_ORDSKU','ORDHEAD',NULL);
      close C_ORDHEAD_ORDSKU;
      ---
      if L_pack_item is not NULL then
         ---
         -- Get number of packs ordered
         if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                         L_pack_qty,
                                         L_pack_item,
                                         L_qty,
                                         L_qty_uom,
                                         L_supplier,
                                         L_origin_country_id) = FALSE then
            return FALSE;
         end if;
         ---
         -- Get number of items in each pack
         SQL_LIB.SET_MARK('OPEN','C_V_PACKSKU_QTY','V_PACKSKU_QTY',NULL);
         open C_V_PACKSKU_QTY;
         SQL_LIB.SET_MARK('FETCH','C_V_PACKSKU_QTY','V_PACKSKU_QTY',NULL);
         fetch C_V_PACKSKU_QTY into L_packitem_qty;
         SQL_LIB.SET_MARK('CLOSE','C_V_PACKSKU_QTY','V_PACKSKU_QTY',NULL);
         close C_V_PACKSKU_QTY;
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
         L_qty     := (L_pack_qty * L_packitem_qty);
         L_qty_uom := L_standard_uom;
         ---
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
                            L_qty,
                            L_standard_uom,
                            L_qty,
                            L_qty_uom,
                            L_item,
                            L_supplier,
                            L_origin_country_id) = FALSE then
            return FALSE;
         end if;
         ---
         L_packitem_qty := 1;
      end if;

      --- calculate total DUTY
      L_duty_value := 0;
      ---

      SQL_LIB.SET_MARK('OPEN','C_GET_DUTY_VALUE','CE_CHARGES',NULL);
      open C_GET_DUTY_VALUE;
      SQL_LIB.SET_MARK('FETCH','C_GET_DUTY_VALUE','CE_CHARGES',NULL);
      fetch C_GET_DUTY_VALUE into L_duty_value;
      SQL_LIB.SET_MARK('CLOSE','C_GET_DUTY_VALUE','CE_CHARGES',NULL);
      close C_GET_DUTY_VALUE;
      ---
      O_total_duty := O_total_duty + (L_qty * L_duty_value);

      --- calculate total Taxes
      L_tax_value := 0;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_TAX_VALUE','CE_CHARGES',NULL);
      open C_GET_TAX_VALUE;
      SQL_LIB.SET_MARK('FETCH','C_GET_TAX_VALUE','CE_CHARGES',NULL);
      fetch C_GET_TAX_VALUE into L_tax_value;
      SQL_LIB.SET_MARK('CLOSE','C_GET_TAX_VALUE','CE_CHARGES',NULL);
      close C_GET_TAX_VALUE;

      O_total_taxes := O_total_taxes + (L_qty * L_tax_value);

      --- calculate total for others
      L_other_value := 0;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_OTHER_VALUE','CE_CHARGES',NULL);
      open C_GET_OTHER_VALUE;
      SQL_LIB.SET_MARK('FETCH','C_GET_OTHER_VALUE','CE_CHARGES',NULL);
      fetch C_GET_OTHER_VALUE into L_other_value;
      SQL_LIB.SET_MARK('CLOSE','C_GET_OTHER_VALUE','CE_CHARGES',NULL);
      close C_GET_OTHER_VALUE;
      ---
      O_total_other := O_total_other + (L_qty * L_other_value);
      ---
      L_other_value := 0;
      ---
      L_total_value     := 0;
      L_total_order_qty := 0;
      ---
      for ELC_REC in C_LOCATIONS loop
         L_location := ELC_REC.location;
         ---
         SQL_LIB.SET_MARK('OPEN','C_ORDLOC_QTY','ORDLOC',NULL);
         open C_ORDLOC_QTY;
         SQL_LIB.SET_MARK('FETCH','C_ORDLOC_QTY','ORDLOC',NULL);
         fetch C_ORDLOC_QTY into L_qty_ordered;
         SQL_LIB.SET_MARK('CLOSE','C_ORDLOC_QTY','ORDLOC',NULL);
         close C_ORDLOC_QTY;
         ---
         -- calculate total VFD
         ---
         L_value           := 0;
         ---
         for C_GET_VFD_TOTAL_REC in C_GET_VFD_TOTAL loop
            L_est_exp_value     := C_GET_VFD_TOTAL_REC.est_exp_value;
            L_comp_currency     := C_GET_VFD_TOTAL_REC.comp_currency;
            L_vfd_exchange_rate := C_GET_VFD_TOTAL_REC.exchange_rate;
            L_combo_oper        := C_GET_VFD_TOTAL_REC.combo_oper;
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_est_exp_value,
                                    L_comp_currency,
                                    L_currency_code,
                                    L_est_exp_value_ce,
                                    'C',
                                    NULL,
                                    NULL,
                                    L_vfd_exchange_rate,
                                    L_exchange_rate) = FALSE then
               return FALSE;
            end if;
            ---
            if L_combo_oper = '+' then
               L_value := L_value + L_est_exp_value_ce;
            else
               L_value := L_value - L_est_exp_value_ce;
            end if;
         end loop;
         ---
         L_total_value     := L_total_value + (L_value * L_qty_ordered * L_packitem_qty);
         L_total_order_qty := L_total_order_qty + (L_qty_ordered * L_packitem_qty);
      end loop;
      ---
      O_total_vfd := O_total_vfd + ((L_total_value / L_total_order_qty) * L_qty);
      ---
      L_tdty_comp_id := 'TDTY'||L_import_country_id;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
      open C_GET_PO_TDTY;
      SQL_LIB.SET_MARK('FETCH','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
      fetch C_GET_PO_TDTY into L_total_dty;
      SQL_LIB.SET_MARK('CLOSE','C_GET_PO_TDTY','ORDSKU_HTS, ORDSKU_HTS_ASSESS',NULL);
      close C_GET_PO_TDTY;
      ---
      SQL_LIB.SET_MARK('OPEN','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
      open C_GET_ASSESS_CURR;
      SQL_LIB.SET_MARK('FETCH','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
      fetch C_GET_ASSESS_CURR into L_dty_currency;
      SQL_LIB.SET_MARK('CLOSE','C_GET_ASSESS_CURR','ITEM_HTS, ITEM_HTS_ASSESS',NULL);
      close C_GET_ASSESS_CURR;
      ---
      if L_dty_currency is not NULL then
         ---
         -- Convert the Total Duty value from the import currency
         -- to Customs Entry currency.
         ---
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_total_dty,
                                 L_dty_currency,
                                 L_currency_code,
                                 L_total_dty,
                                 'C',
                                 NULL,
                                 NULL,
                                 NULL,
                                 L_exchange_rate) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      L_est_assess := L_est_assess + (L_total_dty  * L_qty);
   end loop;
   ---
   O_total_est_assess := L_est_assess;
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
--------------------------------------------------------------------------------------

FUNCTION DEFAULT_CHARGES(O_error_message   IN OUT VARCHAR2,
                         I_ce_id           IN     CE_HEAD.CE_ID%TYPE,
                         I_vessel_id       IN     CE_SHIPMENT.VESSEL_ID%TYPE,
                         I_voyage_flt_id   IN     CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                         I_est_depart_date IN     CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                         I_order_no        IN     CE_ORD_ITEM.ORDER_NO%TYPE,
                         I_item            IN     CE_ORD_ITEM.ITEM%TYPE,
                         I_import_country  IN     COUNTRY.COUNTRY_ID%TYPE)
RETURN BOOLEAN IS

   L_program           VARCHAR2(50)               := 'CE_CHARGES_SQL.DEFAULT_CHARGES';
   L_hts               HTS.HTS%TYPE;
   L_effect_from       HTS.EFFECT_FROM%TYPE;
   L_effect_to         HTS.EFFECT_TO%TYPE;
   L_pack_item         V_PACKSKU_QTY.ITEM%TYPE;
   L_pack_ind          ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind      ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind     ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type         ITEM_MASTER.ORDERABLE_IND%TYPE;
   ---
   cursor C_ORDSKU_HTS_PACK is
      select distinct oh.hts,
             oh.effect_from,
             oh.effect_to,
             vp.item
        from ordsku_hts    oh,
             ordsku        os,
             v_packsku_qty vp
       where os.order_no  = I_order_no
         and os.item      = I_item
         and oh.order_no  = os.order_no
         and oh.item      = vp.item
         and oh.pack_item = vp.pack_no
         and vp.pack_no   = I_item;

   cursor C_ORDSKU_HTS is
      select distinct oh.hts,
             oh.effect_from,
             oh.effect_to
        from ordsku_hts oh,
             ordsku     os
       where os.order_no   = I_order_no
         and oh.order_no   = os.order_no
         and os.item       = I_item
         and oh.item       = os.item
         and oh.pack_item is NULL;

BEGIN
   --- if the item is a buyer pack, then need to populate the item
   --- field and pack item field on the ce_charges table
   ---
   if ITEM_ATTRIB_SQL.GET_PACK_INDS(O_error_message,
                                    L_pack_ind,
                                    L_sellable_ind,
                                    L_orderable_ind,
                                    L_pack_type,
                                    I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_pack_type = 'B' then
      for C_ORDSKU_HTS_PACK_REC in C_ORDSKU_HTS_PACK loop
         L_hts               := C_ORDSKU_HTS_PACK_REC.hts;
         L_effect_from       := C_ORDSKU_HTS_PACK_REC.effect_from;
         L_effect_to         := C_ORDSKU_HTS_PACK_REC.effect_to;
         L_pack_item         := C_ORDSKU_HTS_PACK_REC.item;

         if CE_CHARGES_SQL.INSERT_COMPS(O_error_message,
                                        I_ce_id,
                                        I_vessel_id,
                                        I_voyage_flt_id,
                                        I_est_depart_date,
                                        I_order_no,
                                        L_pack_item,
                                        I_item,
                                        L_hts,
                                        I_import_country,
                                        L_effect_from,
                                        L_effect_to) = FALSE then
            return FALSE;
         end if;
      end loop;
   else   --- L_buyer_pack = 'N'
      for C_ORDSKU_HTS_REC in C_ORDSKU_HTS loop
         L_hts               := C_ORDSKU_HTS_REC.hts;
         L_effect_from       := C_ORDSKU_HTS_REC.effect_from;
         L_effect_to         := C_ORDSKU_HTS_REC.effect_to;

         if CE_CHARGES_SQL.INSERT_COMPS(O_error_message,
                                        I_ce_id,
                                        I_vessel_id,
                                        I_voyage_flt_id,
                                        I_est_depart_date,
                                        I_order_no,
                                        I_item,
                                        NULL,
                                        L_hts,
                                        I_import_country,
                                        L_effect_from,
                                        L_effect_to,
                                        NULL) = FALSE then
            return FALSE;
         end if;
      end loop;
   end if;    --- if item is a buyer pack

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_CHARGES;
--------------------------------------------------------------------------------------
FUNCTION CVB_RATE_TOTAL(O_error_message     IN OUT VARCHAR2,
                        O_rate_total        IN OUT ELC_COMP.COMP_RATE%TYPE,
                        I_ce_id             IN     CE_HEAD.CE_ID%TYPE,
                        I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                        I_vessel_id         IN     CE_SHIPMENT.VESSEL_ID%TYPE,
                        I_voyage_flt_id     IN     CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                        I_est_depart_date   IN     CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                        I_order_no          IN     ORDHEAD.ORDER_NO%TYPE,
                        I_item              IN     ITEM_MASTER.ITEM%TYPE,
                        I_pack_item         IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_program           VARCHAR2(50)              := 'CE_CHARGES_SQL.CVB_RATE_TOTAL';
   L_hts               CE_CHARGES.HTS%TYPE;
   L_cvb_code          CE_CHARGES.CVB_CODE%TYPE;
   L_comp_rate         ELC_COMP.COMP_RATE%TYPE;
   L_pack_item         ITEM_MASTER.ITEM%TYPE     := I_pack_item;
   L_item              ITEM_MASTER.ITEM%TYPE     := I_item;
   L_rate_total        ELC_COMP.COMP_RATE%TYPE   := 0;

   cursor C_CECHARGE_HTS_CVB_CODE is
      select distinct cc.hts,
             cc.cvb_code
        from ce_charges cc
       where ce_id                  = I_ce_id
         and vessel_id              = I_vessel_id
         and voyage_flt_id          = I_voyage_flt_id
         and estimated_depart_date  = I_est_depart_date
         and order_no               = I_order_no
         and item                   = L_item
         and ((pack_item            = L_pack_item
               and L_pack_item      is not NULL)
             or (pack_item          is     NULL
                 and L_pack_item    is     NULL))
         and comp_id                like 'MPF%';

   cursor C_ELCCOMP_COMP_RATE is
      select ec.comp_rate
        from elc_comp ec,
             cvb_detail cd
       where L_cvb_code = cd.cvb_code
         and ec.comp_id  = cd.comp_id;

   cursor C_PACKSKUS is
      select item
        from v_packsku_qty
       where pack_no = I_pack_item;

BEGIN
   if (I_ce_id                 is NULL or
       I_vessel_id             is NULL or
       I_voyage_flt_id         is NULL or
       I_est_depart_date       is NULL or
       I_order_no              is NULL or
       I_item                  is NULL) then

      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   if I_pack_item is NULL then
      O_rate_total := 0;
      ---
      for C_CECHARGE_HTS_CVB_CODE_REC in C_CECHARGE_HTS_CVB_CODE loop
         L_hts         := C_CECHARGE_HTS_CVB_CODE_REC.hts;
         L_cvb_code    := C_CECHARGE_HTS_CVB_CODE_REC.cvb_code;
         ---
         if L_cvb_code   = 'VFD'||I_import_country_id then
            L_comp_rate := 100;
         else
            SQL_LIB.SET_MARK('OPEN','C_ELCCOMP_COMP_RATE','CE_CHARGES',NULL);
            open C_ELCCOMP_COMP_RATE;
            SQL_LIB.SET_MARK('FETCH','C_ELCCOMP_COMP_RATE','CE_CHARGES',NULL);
            fetch C_ELCCOMP_COMP_RATE into L_comp_rate;
            SQL_LIB.SET_MARK('CLOSE','C_ELCCOMP_COMP_RATE','CE_CHARGES',NULL);
            close C_ELCCOMP_COMP_RATE;
         end if;
         ---
         O_rate_total := O_rate_total + L_comp_rate;
         L_comp_rate := 0;
      end loop;
   else
      for C_rec in C_PACKSKUS loop
         L_item := C_rec.item;
         ---
         L_rate_total := 0;
         ---
         for C_CECHARGE_HTS_CVB_CODE_REC in C_CECHARGE_HTS_CVB_CODE loop
            L_hts         := C_CECHARGE_HTS_CVB_CODE_REC.hts;
            L_cvb_code    := C_CECHARGE_HTS_CVB_CODE_REC.cvb_code;
            ---
            if L_cvb_code   = 'VFD'||I_import_country_id then
               L_comp_rate := 100;
            else
               SQL_LIB.SET_MARK('OPEN','C_ELCCOMP_COMP_RATE','CE_CHARGES',NULL);
               open C_ELCCOMP_COMP_RATE;
               SQL_LIB.SET_MARK('FETCH','C_ELCCOMP_COMP_RATE','CE_CHARGES',NULL);
               fetch C_ELCCOMP_COMP_RATE into L_comp_rate;
               SQL_LIB.SET_MARK('CLOSE','C_ELCCOMP_COMP_RATE','CE_CHARGES',NULL);
               close C_ELCCOMP_COMP_RATE;
            end if;
            ---
            L_rate_total := L_rate_total + L_comp_rate;
            L_comp_rate  := 0;
         end loop;
         ---
         if L_rate_total not in (0, 100) then
            O_rate_total := 50;
            exit;
         else
            O_rate_total := 100;
         end if;
      end loop;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CVB_RATE_TOTAL;
--------------------------------------------------------------------------------------
FUNCTION ORD_HTS_ASSESS_EXISTS(O_error_message  IN OUT VARCHAR2,
                               O_exists         IN OUT  BOOLEAN,
                               I_order_no       IN     ORDHEAD.ORDER_NO%TYPE,
                               I_item           IN     ITEM_MASTER.ITEM%TYPE,
                               I_pack_item      IN     ITEM_MASTER.ITEM%TYPE,
                               I_hts            IN     HTS.HTS%TYPE,
                               I_effect_from    IN     HTS.EFFECT_FROM%TYPE,
                               I_effect_to      IN     HTS.EFFECT_TO%TYPE,
                               I_comp_id        IN     ELC_COMP.COMP_ID%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'CE_CHARGES_SQL.ORD_HTS_ASSESS_EXISTS';
   L_exists    VARCHAR2(1)  := 'N';


   cursor C_ORD_HTS_ASSESS_EXISTS is
      select 'Y'
        from ordsku_hts_assess oha,
             ordsku_hts oh
       where oha.order_no        = oh.order_no
         and oha.seq_no          = oh.seq_no
         and oh.order_no         = I_order_no
         and oh.item             = I_item
         and ((oh.pack_item      = I_pack_item
               and I_pack_item   is not NULL
               and oh.pack_item  is not NULL)
                or (oh.pack_item is NULL and I_pack_item is NULL))
         and oh.hts              = I_hts
         and oh.effect_from      = I_effect_from
         and oh.effect_to        = I_effect_to
         and oha.comp_id         = I_comp_id;

BEGIN
   if (I_order_no              is NULL or
       I_item                  is NULL or
       I_hts                   is NULL or
       I_effect_from           is NULL or
       I_effect_to             is NULL or
       I_comp_id               is NULL) then

      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ORD_HTS_ASSESS_EXISTS','ORDSKU_HTS_ASSESS',NULL);
   open C_ORD_HTS_ASSESS_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_ORD_HTS_ASSESS_EXISTS','ORD_HTS_ASSESS',NULL);
   fetch C_ORD_HTS_ASSESS_EXISTS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_ORD_HTS_ASSESS_EXISTS','ORD_HTS_ASSESS',NULL);
   close C_ORD_HTS_ASSESS_EXISTS;
   ---
   if L_exists = 'N' then
      O_exists := FALSE;
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
END ORD_HTS_ASSESS_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION VALIDATE_CHARGES(O_error_message     IN OUT VARCHAR2,
                          O_valid             IN OUT BOOLEAN,
                          I_ce_id             IN     CE_HEAD.CE_ID%TYPE,
                          I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                          I_comp_id           IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'CE_CHARGES_SQL.VALIDATE_CHARGES';
   L_exists    VARCHAR2(1)  := 'N';

   cursor C_VALIDATE_CHARGES is
      select 'Y'
        from elc_comp
       where comp_id        = I_comp_id
         and (comp_type     = 'E'
              or (comp_type = 'A'
                  and (import_country_id <> I_import_country_id
                        or (I_comp_id    like 'MPF%'
                            or I_comp_id like 'HMF%'
                            or I_comp_id like 'TDTY%'
                            or I_comp_id like 'DUTY%'))));

BEGIN
   if (I_comp_id is NULL or
       I_ce_id   is NULL or
       I_import_country_id is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   O_valid := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_VALIDATE_CHARGES','ELC_COMP', NULL);
   open C_VALIDATE_CHARGES;
   SQL_LIB.SET_MARK('FETCH','C_VALIDATE_CHARGES','ELC_COMP', NULL);
   fetch C_VALIDATE_CHARGES into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_VALIDATE_CHARGES','ELC_COMP', NULL);
   close C_VALIDATE_CHARGES;
   ---
   if L_exists = 'Y' then
      O_valid := FALSE;
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
END VALIDATE_CHARGES;
--------------------------------------------------------------------------------------
FUNCTION UPDATE_CVB_CODE(O_error_message         IN OUT VARCHAR2,
                         I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                         I_vessel_id             IN     CE_SHIPMENT.VESSEL_ID%TYPE,
                         I_voyage_flt_id         IN     CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                         I_estimated_depart_date IN     CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                         I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                         I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                         I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                         I_hts                   IN     HTS.HTS%TYPE,
                         I_import_country_id     IN     COUNTRY.COUNTRY_ID%TYPE,
                         I_effect_from           IN     HTS.EFFECT_FROM%TYPE,
                         I_effect_to             IN     HTS.EFFECT_TO%TYPE,
                         I_cvb_code              IN     CVB_HEAD.CVB_CODE%TYPE)
 RETURN BOOLEAN IS

   L_program      VARCHAR2(50) := 'CE_CHARGES_SQL.UPDATE_CVB_CODE';
   L_table        VARCHAR2(30) := 'CE_CHARGES';
   RECORD_LOCKED  EXCEPTION;
   PRAGMA         EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_CE_CHARGES is
      select 'x'
        from ce_charges
       where ce_id                  = I_ce_id
         and vessel_id              = I_vessel_id
         and voyage_flt_id          = I_voyage_flt_id
         and estimated_depart_date  = I_estimated_depart_date
         and order_no               = I_order_no
         and item                   = I_item
         and ((pack_item            = I_pack_item
               and I_pack_item      is not NULL
               and pack_item        is not NULL)
                or (pack_item       is NULL
                    and I_pack_item is NULL))
         and hts                    = I_hts
         and effect_from            = I_effect_from
         and effect_to              = I_effect_to
         and cvb_code               is not NULL
         for update nowait;
BEGIN

   if (I_ce_id                 is NULL or
       I_vessel_id             is NULL or
       I_voyage_flt_id         is NULL or
       I_estimated_depart_date is NULL or
       I_order_no              is NULL or
       I_item                  is NULL or
       I_hts                   is NULL or
       I_import_country_id     is NULL or
       I_effect_from           is NULL or
       I_effect_to             is NULL or
       I_cvb_code              is NULL) then

      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
   open C_LOCK_CE_CHARGES;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
   close C_LOCK_CE_CHARGES;
   ---
   SQL_LIB.SET_MARK('UPDATE',NULL,'CE_CHARGES',NULL);
   update ce_charges
      set cvb_code               = I_cvb_code
    where ce_id                  = I_ce_id
      and vessel_id              = I_vessel_id
      and voyage_flt_id          = I_voyage_flt_id
      and estimated_depart_date  = I_estimated_depart_date
      and order_no               = I_order_no
      and item                   = I_item
      and ((pack_item            = I_pack_item
            and I_pack_item      is not NULL
            and pack_item        is not NULL)
             or (pack_item       is NULL
                 and I_pack_item is NULL))
      and hts                    = I_hts
      and effect_from            = I_effect_from
      and effect_to              = I_effect_to
      and cvb_code               is not NULL;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             NULL,
                                             NULL);
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_CVB_CODE;
--------------------------------------------------------------------------------------
FUNCTION CALC_PACK_QTY(O_error_message  IN OUT VARCHAR2,
                       O_pack_qty       IN OUT CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE,
                       I_pack_no        IN     ITEM_MASTER.ITEM%TYPE,
                       I_qty            IN     CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE,
                       I_uom            IN     UOM_CLASS.UOM%TYPE,
                       I_supplier       IN     SUPS.SUPPLIER%TYPE,
                       I_origin_country IN     COUNTRY.COUNTRY_ID%TYPE)
RETURN BOOLEAN IS
   L_program                 VARCHAR2(50)               := 'CE_CHARGES_SQL.CALC_PACK_QTY';
   L_uom_class               UOM_CLASS.UOM_CLASS%TYPE;
   L_item                    ITEM_MASTER.ITEM%TYPE;
   L_qty                     V_PACKSKU_QTY.QTY%TYPE     := 0;
   L_standard_uom            UOM_CLASS.UOM%TYPE;
   L_standard_class          UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor             NUMBER(20,10);
   L_packitem_qty            V_PACKSKU_QTY.QTY%TYPE     := 0;
   L_total_pack_qty          V_PACKSKU_QTY.QTY%TYPE     := 0;

   cursor C_PACKSKU_QTY is
      select item,
             qty
        from v_packsku_qty
       where pack_no = I_pack_no;

BEGIN
   if (I_pack_no is NULL or
       I_qty     is NULL or
       I_uom     is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;
   ---
   if I_uom = 'EA' then
      O_pack_qty := I_qty;
      return TRUE;
   else
      if UOM_SQL.GET_CLASS(O_error_message,
                           L_uom_class,
                           I_uom) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if L_uom_class = 'QTY' then
      if UOM_SQL.CONVERT(O_error_message,
                         O_pack_qty,
                         'EA',
                         I_qty,
                         I_uom,
                         I_pack_no,
                         I_supplier,
                         I_origin_country) = FALSE then
         return FALSE;
      end if;
   else
      for C_rec in C_PACKSKU_QTY loop
         L_item    := C_rec.item;
         L_qty     := C_rec.qty;
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
         if UOM_SQL.CONVERT(O_error_message,
                            L_packitem_qty,
                            I_uom,
                            L_qty,
                            L_standard_uom,
                            I_pack_no,
                            I_supplier,
                            I_origin_country) = FALSE then
            return FALSE;
         end if;
         ---
         -- if conversion fails return zero for pack --
         if (I_qty <> 0 and L_packitem_qty = 0) then
            O_pack_qty := 0;
            return TRUE;
         end if;
         ---
         L_total_pack_qty := L_total_pack_qty + L_packitem_qty;
      end loop;
      O_pack_qty := I_qty / L_total_pack_qty;
   end if;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CALC_PACK_QTY;
--------------------------------------------------------------------------------------
FUNCTION CALC_MPF_ORD_ITEM_CHRG(O_error_message         IN OUT VARCHAR2,
                                O_mpf_rate              IN OUT ELC_COMP.COMP_RATE%TYPE,
                                O_mpf_value             IN OUT ORDLOC_EXP.EST_EXP_VALUE%TYPE,
                                I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                                I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                                I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                                I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                                I_hts                   IN     HTS.HTS%TYPE,
                                I_effect_from           IN     HTS.EFFECT_FROM%TYPE,
                                I_effect_to             IN     HTS.EFFECT_TO%TYPE,
                                I_cvb_code              IN     CVB_HEAD.CVB_CODE%TYPE,
                                I_ce_currency_code      IN     CURRENCIES.CURRENCY_CODE%TYPE,
                                I_ce_exchange_rate      IN     ORDLOC_EXP.EXCHANGE_RATE%TYPE)
   RETURN BOOLEAN IS

   L_program                 VARCHAR2(50)                  := 'CE_CHARGES_SQL.CALC_MPF_ORD_ITEM_CHRG';
   L_ce_currency_code        CE_HEAD.CURRENCY_CODE%TYPE    := I_ce_currency_code;
   L_ce_currency_rate        CE_HEAD.EXCHANGE_RATE%TYPE    := I_ce_exchange_rate;
   L_combo_oper              CVB_DETAIL.COMBO_OPER%TYPE;
   L_comp_id                 ORDLOC_EXP.COMP_ID%TYPE;
   L_cost_zone_group         COST_ZONE_GROUP.ZONE_GROUP_ID%TYPE;
   L_cvb_vfd_rate            ELC_COMP.COMP_RATE%TYPE;
   L_est_exp_value_ce        ORDLOC_EXP.EST_EXP_VALUE%TYPE  := 0;
   L_exists                  VARCHAR2(1);
   L_exists_boolean          BOOLEAN;
   L_location                ORDLOC.LOCATION%TYPE;
   L_mpf_comp_rate           ELC_COMP.COMP_RATE%TYPE;
   L_ol_qty_ordered          ORDLOC.QTY_ORDERED%TYPE;
   L_osz_comp_currency       ORDLOC_EXP.COMP_CURRENCY%TYPE;
   L_osz_comp_rate           ORDLOC_EXP.COMP_RATE%TYPE;
   L_osz_comp_value          ORDLOC_EXP.EST_EXP_VALUE%TYPE   := 0;
   L_osz_exchange_rate       ORDLOC_EXP.EXCHANGE_RATE%TYPE;
   L_osz_per_count_uom       ORDLOC_EXP.PER_COUNT_UOM%TYPE;
   L_total_comp_rate         ORDLOC_EXP.EXCHANGE_RATE%TYPE   := 0;
   L_total_comp_value        ORDLOC_EXP.EST_EXP_VALUE%TYPE   := 0;
   L_total_ordered_qty       ORDLOC.QTY_ORDERED%TYPE;
   L_vfd                     ORDLOC_EXP.EST_EXP_VALUE%TYPE   := 0;
   L_import_country_id       COUNTRY.COUNTRY_ID%TYPE;

   cursor C_CVB_VFD is
      select e.comp_rate
        from elc_comp e,
             cvb_detail c
       where e.comp_id  = c.comp_id
         and c.cvb_code = I_cvb_code;

   cursor C_ORDLOC_EXP_COMP is
      select distinct c.comp_id,
             c.combo_oper
        from cvb_detail c,
             ordloc_exp o
       where c.comp_id   = o.comp_id
         and o.order_no  = I_order_no
         and item        = I_item
         and ((pack_item is NULL and
              I_pack_item is NULL) or
              (pack_item = I_pack_item and
               I_pack_item is not NULL))
         and c.cvb_code = 'VFD'||L_import_country_id;

   cursor C_ORDLOC is
      select distinct location,
             qty_ordered
        from ordloc
       where order_no = I_order_no
         and ((item    = I_item and
              I_pack_item is NULL) or
              (item    = I_pack_item and
              I_pack_item is not NULL));

   cursor C_ORDLOC_EXP_ZONE is
      select o.est_exp_value,
             o.comp_currency,
             o.exchange_rate
        from ordloc_exp o
       where o.order_no = I_order_no
         and o.item     = I_item
         and ((o.pack_item = I_pack_item and
              I_pack_item is not NULL) or
              (o.pack_item is NULL and
               I_pack_item is NULL))
         and o.comp_id       = L_comp_id
         and o.location = L_location;

   cursor C_ORDSKU_HTS_ASSESS is
      select comp_rate
        from ordsku_hts_assess a,
             ordsku_hts h
       where h.order_no = a.order_no
         and h.seq_no   = a.seq_no
         and h.order_no = I_order_no
         and h.item     = I_item
         and ((h.pack_item = I_pack_item and
              I_pack_item is not NULL) or
              (h.pack_item is NULL and
               I_pack_item is NULL))
         and comp_id like 'MPF%';

   cursor C_ELC_MPF is
      select comp_rate
        from elc_comp e
       where comp_id like 'MPF%'
         and e.import_country_id = L_import_country_id;

   cursor C_GET_IMP_CTRY is
      select import_country_id
        from ce_head
       where ce_id = I_ce_id;

BEGIN
   if (I_ce_id       is NULL or
      I_order_no     is NULL or
      I_item         is NULL or
      I_hts          is NULL or
      I_effect_from  is NULL or
      I_effect_to    is NULL or
      I_cvb_code     is NULL) then
      O_error_message := SQL_LIB.CREATE_MSG('INV_PARAM_PROG_UNIT',L_program,NULL,NULL);
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_IMP_CTRY','CE_HEAD','CE ID:'||to_char(I_ce_id));
   open C_GET_IMP_CTRY;
   SQL_LIB.SET_MARK('FETCH','C_GET_IMP_CTRY','CE_HEAD','CE ID:'||to_char(I_ce_id));
   fetch C_GET_IMP_CTRY into L_import_country_id;
   SQL_LIB.SET_MARK('CLOSE','C_GET_IMP_CTRY','CE_HEAD','CE ID:'||to_char(I_ce_id));
   close C_GET_IMP_CTRY;
   ---
   SQL_LIB.SET_MARK('OPEN','C_CVB_VFD','ELC_COMP, CVB_DETAIL','cvb code:'||I_cvb_code);
   open C_CVB_VFD;
   SQL_LIB.SET_MARK('FETCH','C_CVB_VFD','ELC_COMP, CVB_DETAIL','cvb code:'||I_cvb_code);
   fetch C_CVB_VFD into L_cvb_vfd_rate;
   SQL_LIB.SET_MARK('CLOSE','C_CVB_VFD','ELC_COMP, CVB_DETAIL','cvb code:'||I_cvb_code);
   close C_CVB_VFD;

   if (I_ce_currency_code is NULL or I_ce_exchange_rate is NULL) then
      if CE_SQL.GET_CURRENCY_RATE(O_error_message,
                                  L_ce_currency_code,
                                  L_ce_currency_rate,
                                  I_ce_id) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if ITEM_ATTRIB_SQL.GET_COST_ZONE_GROUP(O_error_message,
                                          L_cost_zone_group,
                                          I_item) = FALSE then
      return FALSE;
   end if;
   ---
   if ORDER_ITEM_ATTRIB_SQL.GET_QTY_ORDERED(O_error_message,
                                            L_exists_boolean,
                                            L_total_ordered_qty,
                                            I_order_no,
                                            I_item,
                                            I_pack_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_exists_boolean = FALSE then
      O_error_message := SQL_LIB.CREATE_MSG('INV_ORD_ITEM',
                                            NULL,
                                            NULL,
                                            NULL);
      return FALSE;
   end if;

   -- Calculate the weighted average VFD across all locations for the retrieved order/item. --
   FOR A_rec in C_ORDLOC_EXP_COMP LOOP
      L_comp_id        := A_rec.comp_id;
      L_combo_oper     := A_rec.combo_oper;
      ---
      FOR B_rec in C_ORDLOC LOOP
         L_location       := B_rec.location;
         L_ol_qty_ordered := B_rec.qty_ordered;
         L_total_comp_value := 0;
         ---
         FOR C_rec in C_ORDLOC_EXP_ZONE LOOP
            L_osz_comp_value    := C_rec.est_exp_value;
            L_osz_comp_currency := C_rec.comp_currency;
            L_osz_exchange_rate := C_rec.exchange_rate;
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_osz_comp_value,
                                    L_osz_comp_currency,
                                    L_ce_currency_code,
                                    L_osz_comp_value,
                                    'C',
                                    NULL,
                                    NULL,
                                    L_osz_exchange_rate,
                                    L_ce_currency_rate) = FALSE then
               return FALSE;
            end if;
            ---
            L_total_comp_value := L_total_comp_value + (L_ol_qty_ordered * L_osz_comp_value);
         END LOOP; -- exp zones
      END LOOP; -- locations
      ---
      if L_total_ordered_qty = 0 then
         L_osz_comp_value := 0;
      else
         L_osz_comp_value := L_total_comp_value / L_total_ordered_qty;
      end if;
      ---
      if L_combo_oper = '+' then
         L_vfd := L_vfd + L_osz_comp_value;
      else
         L_vfd := L_vfd - L_osz_comp_value;
      end if;
   END LOOP; -- components
   ---
   -- Calculate MPF value. Get the rate off of the ordsku_hts_assess table.  If it doesn't exist there
   -- get the MPF rate for that import country off of elc_comp table. --
   ---
   SQL_LIB.SET_MARK('OPEN','C_ORDSKU_HTS_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                    'order no:'||to_char(I_order_no)||' item:'||I_item);
   open C_ORDSKU_HTS_ASSESS;
   SQL_LIB.SET_MARK('FETCH','C_ORDSKU_HTS_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                    'order no:'||to_char(I_order_no)||' item:'||I_item);
   fetch C_ORDSKU_HTS_ASSESS into L_mpf_comp_rate;
   ---
   if C_ORDSKU_HTS_ASSESS%NOTFOUND then
      SQL_LIB.SET_MARK('OPEN','C_ELC_MPF','ELC_COMP',NULL);
      open C_ELC_MPF;
      SQL_LIB.SET_MARK('FETCH','C_ELC_MPF','ELC_COMP',NULL);
      fetch C_ELC_MPF into L_mpf_comp_rate;
      SQL_LIB.SET_MARK('CLOSE','C_ELC_MPF','ELC_COMP',NULL);
      close C_ELC_MPF;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_ORDSKU_HTS_ASSESS','ORDSKU_HTS, ORDSKU_HTS_ASSESS',
                    'order no:'||to_char(I_order_no)||' item:'||I_item);
   close C_ORDSKU_HTS_ASSESS;
   ---
   O_mpf_rate      := L_mpf_comp_rate;
   O_mpf_value     := (L_cvb_vfd_rate/100) * ((L_mpf_comp_rate/100) * L_vfd);
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CALC_MPF_ORD_ITEM_CHRG;
--------------------------------------------------------------------------------------
FUNCTION UPDATE_ORD_ITEM_MPF(O_error_message         IN OUT VARCHAR2,
                             I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                             I_vessel_id             IN     CE_SHIPMENT.VESSEL_ID%TYPE,
                             I_voyage_flt_id         IN     CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                             I_estimated_depart_date IN     CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                             I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                             I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                             I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                             I_hts                   IN     HTS.HTS%TYPE,
                             I_effect_from           IN     HTS.EFFECT_FROM%TYPE,
                             I_effect_to             IN     HTS.EFFECT_TO%TYPE,
                             I_mpf_rate              IN     ELC_COMP.COMP_RATE%TYPE,
                             I_mpf_value             IN     ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE)

   RETURN BOOLEAN IS

   L_program                 VARCHAR2(50)   := 'CE_CHARGES_SQL.UPDATE_ORD_ITEM_MPF';
   L_table                   VARCHAR2(30);
   RECORD_LOCKED             EXCEPTION;
   PRAGMA                    EXCEPTION_INIT(Record_Locked, -54);
   ---
   cursor C_LOCK_CE_CHARGES is
      select 'x'
       from ce_charges
      where ce_id                 = I_ce_id
        and vessel_id             = I_vessel_id
        and voyage_flt_id         = I_voyage_flt_id
        and estimated_depart_date = I_estimated_depart_date
        and order_no              = I_order_no
        and item                  = I_item
        and ((pack_item = I_pack_item and
              I_pack_item is not NULL) or
             (pack_item is NULL and
              I_pack_item is NULL))
        and hts                   = I_hts
        and effect_from           = I_effect_from
        and effect_to             = I_effect_to
        and comp_id               like 'MPF%'
        for update nowait;

BEGIN
  L_table := 'CE_CHARGES';
  SQL_LIB.SET_MARK('OPEN','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
  open C_LOCK_CE_CHARGES;
  SQL_LIB.SET_MARK('CLOSE','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
  close C_LOCK_CE_CHARGES;

     SQL_LIB.SET_MARK('UPDATE',NULL,'CE_CHARGES',NULL);
     update ce_charges
        set comp_rate             = NVL(I_mpf_rate, comp_rate),
            comp_value            = I_mpf_value
      where ce_id                 = I_ce_id
        and vessel_id             = I_vessel_id
        and voyage_flt_id         = I_voyage_flt_id
        and estimated_depart_date = I_estimated_depart_date
        and order_no              = I_order_no
        and item                  = I_item
        and ((pack_item = I_pack_item and
              I_pack_item is not NULL) or
             (pack_item is NULL and
              I_pack_item is NULL))
        and hts                   = I_hts
        and effect_from           = I_effect_from
        and effect_to             = I_effect_to
        and comp_id               like 'MPF%';

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_ce_id),
                                             NULL);
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END UPDATE_ORD_ITEM_MPF;
--------------------------------------------------------------------------------------
FUNCTION CALC_MPF(O_error_message   IN OUT VARCHAR2,
                  O_total_mpf       IN OUT CE_CHARGES.COMP_VALUE%TYPE,
                  I_ce_id           IN     CE_HEAD.CE_ID%TYPE)

   RETURN BOOLEAN IS
   L_program                      VARCHAR2(50)      := 'CE_CHARGES_SQL.CALC_MPF';
   L_ce_currency_code             CE_HEAD.CURRENCY_CODE%TYPE;
   L_ce_currency_rate             CE_HEAD.EXCHANGE_RATE%TYPE;
   L_conv_factor                  UOM_CONVERSION.FACTOR%TYPE;
   L_cvb_code                     CVB_HEAD.CVB_CODE%TYPE;
   L_effect_from                  HTS.EFFECT_FROM%TYPE;
   L_effect_to                    HTS.EFFECT_TO%TYPE;
   L_estimated_depart_date        TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE;
   L_hts                          HTS.HTS%TYPE;
   L_item                         ITEM_MASTER.ITEM%TYPE;
   L_item_mpf_value               ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_manifest_item_qty            CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE          := 0;
   L_manifest_item_qty_uom        CE_ORD_ITEM.MANIFEST_ITEM_QTY_UOM%TYPE;
   L_max_amt                      MPF_MIN_MAX.MAX_AMT%TYPE                    := 0;
   L_min_amt                      MPF_MIN_MAX.MIN_AMT%TYPE                    := 0;
   L_mpf_currency_code            MPF_MIN_MAX.CURRENCY_CODE%TYPE;
   L_ord_currency_code            CE_HEAD.CURRENCY_CODE%TYPE;
   L_ord_currency_rate            CE_HEAD.EXCHANGE_RATE%TYPE;
   L_ord_item_mpf_rate            ELC_COMP.COMP_RATE%TYPE;
   L_ord_item_mpf_value           ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_order_no                     ORDHEAD.ORDER_NO%TYPE;
   L_origin_country               COUNTRY.COUNTRY_ID%TYPE;
   L_pack_qty                     ORDLOC.QTY_ORDERED%TYPE                     := 0;
   L_packitem                     V_PACKSKU_QTY.ITEM%TYPE;
   L_packitem_qty                 V_PACKSKU_QTY.QTY%TYPE                      := 0;
   L_standard_class               UOM_CLASS.UOM_CLASS%TYPE;
   L_standard_uom                 UOM_CLASS.UOM%TYPE;
   L_supplier                     SUPS.SUPPLIER%TYPE;
   L_total_item_mpf_value         ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_total_item_mpf_value_ce      ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_total_mpf                    ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_total_pack_mpf_value         ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_total_pack_mpf_value_ce      ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_total_pack_mpf_value_ord     ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_total_packitem_mpf_value_ord ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE    := 0;
   L_total_packitem_mpf_value_ce  ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE     := 0;
   L_vessel_id                    TRANSPORTATION.VESSEL_ID%TYPE;
   L_voyage_flt_id                TRANSPORTATION.VOYAGE_FLT_ID%TYPE;
   L_pack_ind                     ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind                 ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind                ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type                    ITEM_MASTER.PACK_TYPE%TYPE;

   cursor C_CE_ORD_ITEM is
      select vessel_id,
             voyage_flt_id,
             estimated_depart_date,
             order_no,
             item,
             manifest_item_qty,
             manifest_item_qty_uom
        from ce_ord_item
       where ce_id = I_ce_id;

   cursor C_SUPP_CTY is
      select o.supplier,
             s.origin_country_id
        from ordhead o,
             ordsku  s
       where o.order_no   = s.order_no
         and o.order_no   = L_order_no
         and s.item       = L_item;

   cursor C_PACKSKU_QTY is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;


   cursor C_CE_CHARGES_PACK is
      select c.cvb_code,
             c.hts,
             c.effect_from,
             c.effect_to
        from ce_charges c
       where c.ce_id                 = I_ce_id
         and c.vessel_id             = L_vessel_id
         and c.voyage_flt_id         = L_voyage_flt_id
         and c.estimated_depart_date = L_estimated_depart_date
         and c.order_no              = L_order_no
         and c.item                  = L_packitem
         and c.pack_item             = L_item
         and c.comp_id               like 'MPF%';


   cursor C_CE_CHARGES_ITEM is
      select c.cvb_code,
             c.hts,
             c.effect_from,
             c.effect_to
        from ce_charges c
       where c.ce_id                 = I_ce_id
         and c.vessel_id             = L_vessel_id
         and c.voyage_flt_id         = L_voyage_flt_id
         and c.estimated_depart_date = L_estimated_depart_date
         and c.order_no              = L_order_no
         and c.item                  = L_item
         and c.pack_item             is NULL
         and c.comp_id               like 'MPF%';

   cursor C_MIN_MAX is
      select m.min_amt,
             m.max_amt,
             m.currency_code
        from mpf_min_max m,
             ce_head     c
       where m.import_country_id = c.import_country_id
         and c.ce_id             = I_ce_id;

BEGIN

   if CE_SQL.GET_CURRENCY_RATE(O_error_message,
                               L_ce_currency_code,
                               L_ce_currency_rate,
                               I_ce_id) = FALSE then
      return FALSE;
   end if;

   -- Loop through all order/items on the CE --
   FOR A_rec in C_CE_ORD_ITEM LOOP
      L_vessel_id             := A_rec.vessel_id;
      L_voyage_flt_id         := A_rec.voyage_flt_id;
      L_estimated_depart_date := A_rec.estimated_depart_date;
      L_order_no              := A_rec.order_no;
      L_item                  := A_rec.item;
      L_manifest_item_qty     := A_rec.manifest_item_qty;
      L_manifest_item_qty_uom := A_rec.manifest_item_qty_uom;
      ---
      if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                            L_ord_currency_code,
                                            L_ord_currency_rate,
                                            L_order_no) = FALSE then
         return FALSE;
      end if;
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
         SQL_LIB.SET_MARK('OPEN','C_SUPP_CTY','ORDHEAD, ORDSKU',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         open C_SUPP_CTY;
         SQL_LIB.SET_MARK('FETCH','C_SUPP_CTY','ORDHEAD, ORDSKU',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         fetch C_SUPP_CTY into L_supplier,
                               L_origin_country;
         SQL_LIB.SET_MARK('CLOSE','C_SUPP_CTY','ORDHEAD, ORDSKU',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         close C_SUPP_CTY;
         ---
         if L_manifest_item_qty <> 0 then
            if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                            L_pack_qty,
                                            L_item,
                                            L_manifest_item_qty,
                                            L_manifest_item_qty_uom,
                                            L_supplier,
                                            L_origin_country) = FALSE then
               return FALSE;
            end if;
            ---
            if L_pack_qty = 0 then
               O_error_message := SQL_LIB.CREATE_MSG('MISSING_UOM_MPF',
                                                     L_item,
                                                     NULL,
                                                     NULL);
               return FALSE;
            end if;
         end if;
         ---
         L_total_pack_mpf_value_ord := 0;
         L_total_pack_mpf_value_ce  := 0;

         -- Calculate and sum MPF values that pertain to HTS codes.   --
         FOR A_rec in C_PACKSKU_QTY LOOP
            L_packitem                   := A_rec.item;
            L_packitem_qty                := A_rec.qty;
            L_total_packitem_mpf_value_ce := 0;
            ---
            FOR B_rec in C_CE_CHARGES_PACK LOOP
               L_cvb_code     := B_rec.cvb_code;
               L_hts          := B_rec.hts;
               L_effect_from  := B_rec.effect_from;
               L_effect_to    := B_rec.effect_to;
               ---
               if CE_CHARGES_SQL.CALC_MPF_ORD_ITEM_CHRG(O_error_message,
                                                        L_ord_item_mpf_rate,
                                                        L_ord_item_mpf_value,
                                                        I_ce_id,
                                                        L_order_no,
                                                        L_packitem,
                                                        L_item,
                                                        L_hts,
                                                        L_effect_from,
                                                        L_effect_to,
                                                        L_cvb_code,
                                                        L_ce_currency_code,
                                                        L_ce_currency_rate) = FALSE then
                  return FALSE;
               end if;
               ---
               L_total_packitem_mpf_value_ce := (L_pack_qty * L_packitem_qty) * NVL(L_ord_item_mpf_value, 0);
               L_total_pack_mpf_value_ce    := L_total_pack_mpf_value_ce + L_total_packitem_mpf_value_ce;
            END LOOP;
         END LOOP;
         ---
         L_total_pack_mpf_value := L_total_pack_mpf_value_ce;

      else -- not a buyer pack
         L_packitem:= NULL;
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
         if L_manifest_item_qty <> 0 then
            SQL_LIB.SET_MARK('OPEN','C_SUPP_CTY','ORDHEAD, ORDSKU',
                             'order no:'||to_char(L_order_no)||' item:'||L_item);
            open C_SUPP_CTY;
            SQL_LIB.SET_MARK('FETCH','C_SUPP_CTY','ORDHEAD, ORDSKU',
                             'order no:'||to_char(L_order_no)||' item:'||L_item);
            fetch C_SUPP_CTY into L_supplier,
                                  L_origin_country;
            SQL_LIB.SET_MARK('CLOSE','C_SUPP_CTY','ORDHEAD, ORDSKU',
                             'order no:'||to_char(L_order_no)||' item:'||L_item);
            close C_SUPP_CTY;
            ---
            if UOM_SQL.CONVERT(O_error_message,
                               L_manifest_item_qty,
                               L_standard_uom,
                               L_manifest_item_qty,
                               L_manifest_item_qty_uom,
                               L_item,
                               L_supplier,
                               L_origin_country) = FALSE then
               return FALSE;
            end if;
            ---
            if L_manifest_item_qty = 0 then
               O_error_message := SQL_LIB.CREATE_MSG('MISSING_UOM_MPF',
                                                     L_item,
                                                     NULL,
                                                     NULL);
               return FALSE;
            end if;
         end if;
         ---
         -- Calculate and sum MPF values that pertain to HTS codes. --
         ---
         L_total_item_mpf_value_ce := 0;
         ---
         FOR B_rec in C_CE_CHARGES_ITEM LOOP
            L_cvb_code     := B_rec.cvb_code;
            L_hts          := B_rec.hts;
            L_effect_from  := B_rec.effect_from;
            L_effect_to    := B_rec.effect_to;
            ---
            if CE_CHARGES_SQL.CALC_MPF_ORD_ITEM_CHRG(O_error_message,
                                                     L_ord_item_mpf_rate,
                                                     L_ord_item_mpf_value,
                                                     I_ce_id,
                                                     L_order_no,
                                                     L_item,
                                                     NULL,
                                                     L_hts,
                                                     L_effect_from,
                                                     L_effect_to,
                                                     L_cvb_code,
                                                     L_ce_currency_code,
                                                     L_ce_currency_rate) = FALSE then
               return FALSE;
            end if;
            L_total_item_mpf_value_ce := L_total_item_mpf_value_ce + NVL(L_ord_item_mpf_value, 0);
         END LOOP;
         ---
         L_item_mpf_value       := L_total_item_mpf_value_ce;
         L_total_item_mpf_value := L_item_mpf_value * L_manifest_item_qty;
      end if; -- if buyer pack
      ---
      -- Sum all buyer pack and non-buyer pack MPF totals. --
      ---
      L_total_mpf := L_total_mpf + L_total_pack_mpf_value + L_total_item_mpf_value;
   END LOOP;  -- CE order/items
   ---
   O_total_mpf := L_total_mpf;
   ---
   -- Truncate and redistribute MPF charges. --
   ---
   SQL_LIB.SET_MARK('OPEN','C_SUM_MPF_ITEM','MPF_MIN_MAX, CE_HEAD','ce id:'||to_char(I_ce_id));
   open C_MIN_MAX;
   SQL_LIB.SET_MARK('FETCH','C_SUM_MPF_ITEM','MPF_MIN_MAX, CE_HEAD','ce id:'||to_char(I_ce_id));
   fetch C_MIN_MAX into L_min_amt,
                        L_max_amt,
                        L_mpf_currency_code;
   if C_MIN_MAX%NOTFOUND then
      O_error_message := SQL_LIB.CREATE_MSG('NO_MPF_INFO', NULL, NULL, NULL);
      SQL_LIB.SET_MARK('CLOSE','C_SUM_MPF_ITEM','MPF_MIN_MAX, CE_HEAD','ce id:'||to_char(I_ce_id));
      close C_MIN_MAX;
      return FALSE;
   end if;
   SQL_LIB.SET_MARK('CLOSE','C_SUM_MPF_ITEM','MPF_MIN_MAX, CE_HEAD','ce id:'||to_char(I_ce_id));
   close C_MIN_MAX;
   ---
   -- Convert min/max to CE currency. --
   ---
   if L_mpf_currency_code != L_ce_currency_code then
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_min_amt,
                              L_mpf_currency_code,
                              L_ce_currency_code,
                              L_min_amt,
                              'C',
                              NULL,
                              NULL,
                              NULL,
                              L_ce_currency_rate) = FALSE then
         return FALSE;
      end if;
      ---
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_max_amt,
                              L_mpf_currency_code,
                              L_ce_currency_code,
                              L_max_amt,
                              'C',
                              NULL,
                              NULL,
                              NULL,
                              L_ce_currency_rate) = FALSE then
         return FALSE;
      end if;
   end if;
   ---
   if O_total_mpf < L_min_amt then
      O_total_mpf := L_min_amt;
   elsif L_total_mpf > L_max_amt then
      O_total_mpf := L_max_amt;
   end if;
   ---
   if CE_CHARGES_SQL.DISTRIBUTE_MPF(O_error_message,
                                    I_ce_id,
                                    O_total_mpf,
                                    L_ce_currency_code,
                                    L_ce_currency_rate) = FALSE then
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
END CALC_MPF;
--------------------------------------------------------------------------------------
FUNCTION CALC_CE_MPF_COST_BASIS(O_error_message         IN OUT VARCHAR2,
                                O_total_mpf_cost_basis  IN OUT ORDLOC.UNIT_COST%TYPE,
                                I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                                I_ce_currency           IN     CURRENCIES.CURRENCY_CODE%TYPE,
                                I_ce_exchange_rate      IN     CURRENCY_RATES.EXCHANGE_RATE%TYPE)
   RETURN BOOLEAN IS

   L_program                    VARCHAR2(50)      := 'CE_CHARGES_SQL.CALC_CE_MPF_COST_BASIS';
   L_vessel_id                  TRANSPORTATION.VESSEL_ID%TYPE;
   L_voyage_flt_id              TRANSPORTATION.VOYAGE_FLT_ID%TYPE;
   L_estimated_depart_date      TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE;
   L_order_no                   ORDHEAD.ORDER_NO%TYPE;
   L_item                       ITEM_MASTER.ITEM%TYPE;
   L_manifest_item_qty          CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE         := 0;
   L_manifest_item_qty_uom      CE_ORD_ITEM.MANIFEST_ITEM_QTY_UOM%TYPE;
   L_ord_currency_code          CE_HEAD.CURRENCY_CODE%TYPE;
   L_ord_currency_rate          CE_HEAD.EXCHANGE_RATE%TYPE;
   L_pack_qty                   CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE         := 0;
   L_supplier                   SUPS.SUPPLIER%TYPE;
   L_origin_country             COUNTRY.COUNTRY_ID%TYPE;
   L_packitem                   V_PACKSKU_QTY.ITEM%TYPE;
   L_packitem_qty               V_PACKSKU_QTY.QTY%TYPE                     := 0;
   L_exists                     BOOLEAN;
   L_unit_cost                  ORDLOC.UNIT_COST%TYPE                      := 0;
   L_total_ce_cost              ORDLOC.UNIT_COST%TYPE                      := 0;
   L_total_pack_cost            ORDLOC.UNIT_COST%TYPE                      := 0;
   L_packitem_cost              ORDLOC.UNIT_COST%TYPE                      := 0;
   L_standard_class             UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor                UOM_CONVERSION.FACTOR%TYPE;
   L_standard_uom               UOM_CLASS.UOM%TYPE;
   L_total_item_cost            ORDLOC.UNIT_COST%TYPE                      := 0;
   L_pack_ind                   ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind               ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind              ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type                  ITEM_MASTER.PACK_TYPE%TYPE;

   cursor C_CE_ORD_ITEM is
      select distinct o.vessel_id,
             o.voyage_flt_id,
             o.estimated_depart_date,
             o.order_no,
             o.item,
             o.manifest_item_qty,
             o.manifest_item_qty_uom
        from ce_ord_item o,
             ordloc ol
       where o.ce_id    = I_ce_id
         and o.order_no = ol.order_no
         and o.item     = ol.item
         and ol.qty_ordered > 0
         and exists (select 'x'
                       from ce_charges c
                      where c.ce_id                 = I_ce_id
                        and c.vessel_id             = o.vessel_id
                        and c.voyage_flt_id         = o.voyage_flt_id
                        and c.estimated_depart_date = o.estimated_depart_date
                        and c.order_no              = o.order_no
                        and ((c.item      = o.item and c.pack_item is NULL) or
                             (c.pack_item = o.item and c.pack_item is not NULL))
                        and c.comp_id               like 'MPF%');

   cursor C_SUPP_CTY is
      select o.supplier,
             s.origin_country_id
        from ordhead o,
             ordsku  s
       where o.order_no   = s.order_no
         and o.order_no   = L_order_no
         and s.item       = L_item;

   cursor C_PACKSKU_QTY is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

BEGIN
   FOR A_rec in C_CE_ORD_ITEM LOOP
      L_vessel_id              := A_rec.vessel_id;
      L_voyage_flt_id          := A_rec.voyage_flt_id;
      L_estimated_depart_date  := A_rec.estimated_depart_date;
      L_order_no               := A_rec.order_no;
      L_item                   := A_rec.item;
      L_manifest_item_qty      := A_rec.manifest_item_qty;
      L_manifest_item_qty_uom  := A_rec.manifest_item_qty_uom;
      ---
      if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                            L_ord_currency_code,
                                            L_ord_currency_rate,
                                            L_order_no) = FALSE then
         return FALSE;
      end if;
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
         SQL_LIB.SET_MARK('OPEN','C_SUPP_CTY','ORDHEAD, ORDSKU',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         open C_SUPP_CTY;
         SQL_LIB.SET_MARK('FETCH','C_SUPP_CTY','ORDHEAD, ORDSKU',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         fetch C_SUPP_CTY into L_supplier,
                               L_origin_country;
         SQL_LIB.SET_MARK('CLOSE','C_SUPP_CTY','ORDHEAD, ORDSKU',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         close C_SUPP_CTY;
         ---
         if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                         L_pack_qty,
                                         L_item,
                                         L_manifest_item_qty,
                                         L_manifest_item_qty_uom,
                                         L_supplier,
                                         L_origin_country) = FALSE then
            return FALSE;
         end if;
         ---
         L_total_pack_cost := 0;
         ---
         FOR B_rec in C_PACKSKU_QTY LOOP
            L_packitem         := B_rec.item;
            L_packitem_qty     := B_rec.qty;
            ---
            if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                   L_exists,
                                                   L_unit_cost,
                                                   L_order_no,
                                                   L_packitem,
                                                   L_item,
                                                   NULL) = FALSE then
               return FALSE;
            end if;
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_unit_cost,
                                    L_ord_currency_code,
                                    I_ce_currency,
                                    L_unit_cost,
                                    'C',
                                    NULL,
                                    NULL,
                                    L_ord_currency_rate,
                                    I_ce_exchange_rate) = FALSE then
               return FALSE;
            end if;
            ---
            L_packitem_cost       := L_unit_cost * (L_packitem_qty * L_pack_qty);
            L_total_pack_cost    := L_total_pack_cost + L_packitem_cost;
         END LOOP;

      else -- not a buyer pack
         if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                L_exists,
                                                L_unit_cost,
                                                L_order_no,
                                                L_item,
                                                NULL,
                                                NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if L_manifest_item_qty <> 0 then
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
                               L_manifest_item_qty,
                               L_standard_uom,
                               L_manifest_item_qty,
                               L_manifest_item_qty_uom,
                               L_item,
                               L_supplier,
                               L_origin_country) = FALSE then
               return FALSE;
            end if;
            ---
            if L_manifest_item_qty = 0 then
               O_error_message := SQL_LIB.CREATE_MSG('MISSING_UOM_MPF',
                                                     L_item,
                                                     NULL,
                                                     NULL);
               return FALSE;
            end if;
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_unit_cost,
                                    L_ord_currency_code,
                                    I_ce_currency,
                                    L_unit_cost,
                                    'C',
                                    NULL,
                                    NULL,
                                    L_ord_currency_rate,
                                    I_ce_exchange_rate) = FALSE then
               return FALSE;
            end if;
         end if;
         ---
         L_total_item_cost := L_unit_cost * L_manifest_item_qty;

      end if;  -- if buyer pack
      ---
      L_total_ce_cost := L_total_ce_cost + L_total_item_cost + L_total_pack_cost;
   END LOOP;
   ---
   O_total_mpf_cost_basis := L_total_ce_cost;
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END CALC_CE_MPF_COST_BASIS;
--------------------------------------------------------------------------------------
FUNCTION DISTRIBUTE_MPF_PER_HTS(O_error_message         IN OUT VARCHAR2,
                                I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                                I_vessel_id             IN     CE_SHIPMENT.VESSEL_ID%TYPE,
                                I_voyage_flt_id         IN     CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                                I_estimated_depart_date IN     CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                                I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                                I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                                I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                                I_mpf_value             IN     ORDSKU_HTS_ASSESS.EST_ASSESS_VALUE%TYPE)

   RETURN BOOLEAN IS

   L_program                    VARCHAR2(50)      := 'CE_CHARGES_SQL.DISTRIBUTE_MPF_PER_HTS';
   L_hts_count                  NUMBER(2);
   L_hts                        HTS.HTS%TYPE;
   L_effect_from                HTS.EFFECT_FROM%TYPE;
   L_effect_to                  HTS.EFFECT_TO%TYPE;
   L_cvb_code                   CVB_HEAD.CVB_CODE%TYPE;
   L_comp_rate                  ELC_COMP.COMP_RATE%TYPE;

   cursor C_HTS_COUNT is
      select NVL(count(distinct(hts)), 0)
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item = I_item
         and ((pack_item = I_pack_item and I_pack_item is not NULL) or
              (pack_item is NULL  and I_pack_item is NULL));

   cursor C_HTS_INFO is
      select distinct hts,
             effect_from,
             effect_to,
             cvb_code
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item = I_item
         and ((pack_item = I_pack_item and I_pack_item is not NULL) or
              (pack_item is NULL  and I_pack_item is NULL))
         and comp_id like 'MPF%';


   cursor C_COMP_RATE is
      select e.comp_rate
        from elc_comp e,
             cvb_detail c,
             ce_charges r
       where e.comp_id               = c.comp_id
         and c.cvb_code              = r.cvb_code
         and r.ce_id                 = I_ce_id
         and r.vessel_id             = I_vessel_id
         and r.voyage_flt_id         = I_voyage_flt_id
         and r.estimated_depart_date = I_estimated_depart_date
         and r.order_no              = I_order_no
         and r.item                  = I_item
         and ((r.pack_item = I_pack_item and I_pack_item is not NULL) or
              (r.pack_item is NULL  and I_pack_item is NULL))
         and r.hts         = L_hts
         and r.effect_from = L_effect_from
         and r.effect_to   = L_effect_to
         and r.comp_id like 'MPF%'
         and r.cvb_code    = L_cvb_code;
BEGIN
   SQL_LIB.SET_MARK('OPEN','C_HTS_COUNT','CE_CHARGES',NULL);
   open C_HTS_COUNT;
   SQL_LIB.SET_MARK('FETCH','C_HTS_COUNT','CE_CHARGES',NULL);
   fetch C_HTS_COUNT into L_hts_count;
   SQL_LIB.SET_MARK('CLOSE','C_HTS_COUNT','CE_CHARGES',NULL);
   close C_HTS_COUNT;
   ---
   if L_hts_count = 1 then
      SQL_LIB.SET_MARK('OPEN','C_HTS_INFO','CE_CHARGES',NULL);
      open C_HTS_INFO;
      SQL_LIB.SET_MARK('FETCH','C_HTS_INFO','CE_CHARGES',NULL);
      fetch C_HTS_INFO into L_hts,
                            L_effect_from,
                            L_effect_to,
                            L_cvb_code;
      SQL_LIB.SET_MARK('CLOSE','C_HTS_INFO','CE_CHARGES',NULL);
      close C_HTS_INFO;
      ---
      if CE_CHARGES_SQL.UPDATE_ORD_ITEM_MPF(O_error_message,
                                            I_ce_id,
                                            I_vessel_id,
                                            I_voyage_flt_id,
                                            I_estimated_depart_date,
                                            I_order_no,
                                            I_item,
                                            I_pack_item,
                                            L_hts,
                                            L_effect_from,
                                            L_effect_to,
                                            NULL,
                                            I_mpf_value) = FALSE then
         return FALSE;
      end if;
   else  -- more than one HTS
      FOR C_rec in C_HTS_INFO LOOP
         L_hts         := C_rec.hts;
         L_effect_from := C_rec.effect_from;
         L_effect_to   := C_rec.effect_to;
         L_cvb_code    := C_rec.cvb_code;

         SQL_LIB.SET_MARK('OPEN','C_COMP_RATE','ELC_COMP, CVB_DETAIL, CE_CHARGES',NULL);
         open C_COMP_RATE;
         SQL_LIB.SET_MARK('FETCH','C_COMP_RATE','ELC_COMP, CVB_DETAIL, CE_CHARGES',NULL);
         fetch C_COMP_RATE into L_comp_rate;
         ---
         if C_COMP_RATE%NOTFOUND then
            O_error_message := SQL_LIB.CREATE_MSG('ERR_RET_COMP_RATE',NULL,NULL);
            ---
            SQL_LIB.SET_MARK('CLOSE','C_COMP_RATE','ELC_COMP, CVB_DETAIL, CE_CHARGES',NULL);
            close C_COMP_RATE;
            ---
            return FALSE;
         end if;
         ---
         SQL_LIB.SET_MARK('CLOSE','C_COMP_RATE','ELC_COMP, CVB_DETAIL, CE_CHARGES',NULL);
         close C_COMP_RATE;
         ---
         if CE_CHARGES_SQL.UPDATE_ORD_ITEM_MPF(O_error_message,
                                               I_ce_id,
                                               I_vessel_id,
                                               I_voyage_flt_id,
                                               I_estimated_depart_date,
                                               I_order_no,
                                               I_item,
                                               I_pack_item,
                                               L_hts,
                                               L_effect_from,
                                               L_effect_to,
                                               NULL,
                                               I_mpf_value * (L_comp_rate/100)) = FALSE then
            return FALSE;
         end if;
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
END DISTRIBUTE_MPF_PER_HTS;
--------------------------------------------------------------------------------------
FUNCTION DISTRIBUTE_MPF(O_error_message    IN OUT VARCHAR2,
                        I_ce_id            IN     CE_HEAD.CE_ID%TYPE,
                        I_total_mpf        IN     CE_CHARGES.COMP_VALUE%TYPE,
                        I_ce_currency      IN     CURRENCIES.CURRENCY_CODE%TYPE,
                        I_ce_exchange_rate IN     CURRENCY_RATES.EXCHANGE_RATE%TYPE)
   RETURN BOOLEAN IS

   L_program                    VARCHAR2(50)      := 'CE_CHARGES_SQL.DISTRIBUTE_MPF';
   L_vessel_id                  TRANSPORTATION.VESSEL_ID%TYPE;
   L_voyage_flt_id              TRANSPORTATION.VOYAGE_FLT_ID%TYPE;
   L_estimated_depart_date      TRANSPORTATION.ESTIMATED_DEPART_DATE%TYPE;
   L_order_no                   ORDHEAD.ORDER_NO%TYPE;
   L_item                       ITEM_MASTER.ITEM%TYPE;
   L_manifest_item_qty          CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE;
   L_manifest_item_qty_uom      CE_ORD_ITEM.MANIFEST_ITEM_QTY_UOM%TYPE;
   L_ord_currency_code          CE_HEAD.CURRENCY_CODE%TYPE;
   L_ord_currency_rate          CE_HEAD.EXCHANGE_RATE%TYPE;
   L_pack_qty                   CE_ORD_ITEM.MANIFEST_ITEM_QTY%TYPE;
   L_supplier                   SUPS.SUPPLIER%TYPE;
   L_origin_country             COUNTRY.COUNTRY_ID%TYPE;
   L_packitem                   V_PACKSKU_QTY.ITEM%TYPE;
   L_packitem_qty               V_PACKSKU_QTY.QTY%TYPE;
   L_exists                     BOOLEAN;
   L_unit_cost                  ORDLOC.UNIT_COST%TYPE                   := 0;
   L_total_mpf_cost_basis       ORDLOC.UNIT_COST%TYPE                   := 0;
   L_total_pack_cost            ORDLOC.UNIT_COST%TYPE                   := 0;
   L_packitem_cost              ORDLOC.UNIT_COST%TYPE                   := 0;
   L_mpf_pack_value             ORDLOC.UNIT_COST%TYPE                   := 0;
   L_packitem_mpf_value         ORDLOC.UNIT_COST%TYPE                   := 0;
   L_item_cost                  ORDLOC.UNIT_COST%TYPE                   := 0;
   L_mpf_item_value             ORDLOC.UNIT_COST%TYPE                   := 0;
   L_standard_class             UOM_CLASS.UOM_CLASS%TYPE;
   L_conv_factor                UOM_CONVERSION.FACTOR%TYPE;
   L_standard_uom               UOM_CLASS.UOM%TYPE;
   L_pack_ind                   ITEM_MASTER.PACK_IND%TYPE;
   L_sellable_ind               ITEM_MASTER.SELLABLE_IND%TYPE;
   L_orderable_ind              ITEM_MASTER.ORDERABLE_IND%TYPE;
   L_pack_type                  ITEM_MASTER.PACK_TYPE%TYPE;
   cursor C_CE_ORD_ITEM is
      select distinct o.vessel_id,
             o.voyage_flt_id,
             o.estimated_depart_date,
             o.order_no,
             o.item,
             o.manifest_item_qty,
             o.manifest_item_qty_uom
        from ce_ord_item o,
             ordloc ol
       where o.ce_id    = I_ce_id
         and o.order_no = ol.order_no
         and o.item     = ol.item
         and ol.qty_ordered > 0
         and exists (select 'x'
                       from ce_charges c
                      where c.ce_id                 = I_ce_id
                        and c.vessel_id             = o.vessel_id
                        and c.voyage_flt_id         = o.voyage_flt_id
                        and c.estimated_depart_date = o.estimated_depart_date
                        and c.order_no              = o.order_no
                        and ((c.item      = o.item and c.pack_item is NULL) or
                             (c.pack_item = o.item and c.pack_item is not NULL))
                        and c.comp_id               like 'MPF%');

   cursor C_SUPP_CTY is
      select o.supplier,
             s.origin_country_id
        from ordhead o,
             ordsku  s
       where o.order_no   = s.order_no
         and o.order_no   = L_order_no
         and s.item       = L_item;

   cursor C_PACKSKU_QTY is
      select item,
             qty
        from v_packsku_qty
       where pack_no = L_item;

BEGIN

   -- Calculate the total order cost that MPF charges are based on  --
   -- for the entire CE ID.                                        --
   if CALC_CE_MPF_COST_BASIS(O_error_message,
                             L_total_mpf_cost_basis,
                             I_ce_id,
                             I_ce_currency,
                             I_ce_exchange_rate) = FALSE then
      return FALSE;
   end if;
   ---
   -- Prorate MPF and distribute. --
   ---
   FOR A_rec in C_CE_ORD_ITEM LOOP
      L_vessel_id              := A_rec.vessel_id;
      L_voyage_flt_id          := A_rec.voyage_flt_id;
      L_estimated_depart_date  := A_rec.estimated_depart_date;
      L_order_no               := A_rec.order_no;
      L_item                   := A_rec.item;
      L_manifest_item_qty      := A_rec.manifest_item_qty;
      L_manifest_item_qty_uom  := A_rec.manifest_item_qty_uom;
      ---
      if ORDER_ATTRIB_SQL.GET_CURRENCY_RATE(O_error_message,
                                            L_ord_currency_code,
                                            L_ord_currency_rate,
                                            L_order_no) = FALSE then
         return FALSE;
      end if;
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
         SQL_LIB.SET_MARK('OPEN','C_SUPP_CTY','ORDHEAD, ORDLOC',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         open C_SUPP_CTY;
         SQL_LIB.SET_MARK('FETCH','C_SUPP_CTY','ORDHEAD, ORDLOC',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         fetch C_SUPP_CTY into L_supplier,
                               L_origin_country;
         SQL_LIB.SET_MARK('CLOSE','C_SUPP_CTY','ORDHEAD, ORDLOC',
                          'order no:'||to_char(L_order_no)||' item:'||L_item);
         close C_SUPP_CTY;
         ---
         if CE_CHARGES_SQL.CALC_PACK_QTY(O_error_message,
                                         L_pack_qty,
                                         L_item,
                                         L_manifest_item_qty,
                                         L_manifest_item_qty_uom,
                                         L_supplier,
                                         L_origin_country) = FALSE then
            return FALSE;
         end if;
         ---
         L_total_pack_cost := 0;
         ---
         FOR B_rec in C_PACKSKU_QTY LOOP
            L_packitem        := B_rec.item;
            L_packitem_qty    := B_rec.qty;
            ---
            if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                   L_exists,
                                                   L_unit_cost,
                                                   L_order_no,
                                                   L_packitem, -- component
                                                   L_item,     -- pack no
                                                   NULL) = FALSE then
               return FALSE;
            end if;
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_unit_cost,
                                    L_ord_currency_code,
                                    I_ce_currency,
                                    L_unit_cost,
                                    'C',
                                    NULL,
                                    NULL,
                                    L_ord_currency_rate,
                                    I_ce_exchange_rate) = FALSE then
               return FALSE;
            end if;
            ---
            L_packitem_cost      := L_unit_cost * (L_packitem_qty * L_pack_qty);
            L_total_pack_cost    := L_total_pack_cost + L_packitem_cost;
         END LOOP;
         ---
         -- Calculate the total MPF for the order/item. --
         ---
         L_mpf_pack_value  := I_total_mpf * (L_total_pack_cost/L_total_mpf_cost_basis);
         -- Distribute the total MPF for the order/item to each packitem. --
         FOR B_rec in C_PACKSKU_QTY LOOP
            L_packitem        := B_rec.item;
            L_packitem_qty    := B_rec.qty;
            ---
            if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                   L_exists,
                                                   L_unit_cost,
                                                   L_order_no,
                                                   L_packitem,
                                                   L_item,
                                                   NULL) = FALSE then
               return FALSE;
            end if;
            ---
            if CURRENCY_SQL.CONVERT(O_error_message,
                                    L_unit_cost,
                                    L_ord_currency_code,
                                    I_ce_currency,
                                    L_unit_cost,
                                    'C',
                                    NULL,
                                    NULL,
                                    L_ord_currency_rate,
                                    I_ce_exchange_rate) = FALSE then
               return FALSE;
            end if;
            ---
            L_packitem_cost       := L_unit_cost * (L_packitem_qty * L_pack_qty);
            L_packitem_mpf_value  := (L_mpf_pack_value * (L_packitem_cost/L_total_pack_cost)) / (L_packitem_qty * L_pack_qty);
            ---
            if DISTRIBUTE_MPF_PER_HTS(O_error_message,
                                      I_ce_id,
                                      L_vessel_id,
                                      L_voyage_flt_id,
                                      L_estimated_depart_date,
                                      L_order_no,
                                      L_packitem,
                                      L_item,
                                      L_packitem_mpf_value) = FALSE then
               return FALSE;
            end if;
         END LOOP; -- packitems
      else -- not a buyer pack
            if ORDER_ITEM_ATTRIB_SQL.GET_UNIT_COST(O_error_message,
                                                   L_exists,
                                                   L_unit_cost,
                                                   L_order_no,
                                                   L_item,
                                                   NULL,
                                                   NULL) = FALSE then
            return FALSE;
         end if;
         ---
         if L_manifest_item_qty <> 0 then
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
                               L_manifest_item_qty,
                               L_standard_uom,
                               L_manifest_item_qty,
                               L_manifest_item_qty_uom,
                               L_item,
                               L_supplier,
                               L_origin_country) = FALSE then
               return FALSE;
            end if;
            ---
            if L_manifest_item_qty = 0 then
               O_error_message := SQL_LIB.CREATE_MSG('MISSING_UOM_MPF',
                                                     L_item,
                                                     NULL,
                                                     NULL);
               return FALSE;
            end if;
         end if;
         ---
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_unit_cost,
                                 L_ord_currency_code,
                                 I_ce_currency,
                                 L_unit_cost,
                                 'C',
                                 NULL,
                                 NULL,
                                 L_ord_currency_rate,
                                 I_ce_exchange_rate) = FALSE then
            return FALSE;
         end if;
         ---
         L_item_cost       := L_unit_cost * L_manifest_item_qty;
         L_mpf_item_value  := (I_total_mpf * (L_item_cost/L_total_mpf_cost_basis)) / L_manifest_item_qty;
         ---
         if DISTRIBUTE_MPF_PER_HTS(O_error_message,
                                   I_ce_id,
                                   L_vessel_id,
                                   L_voyage_flt_id,
                                   L_estimated_depart_date,
                                   L_order_no,
                                   L_item,
                                   NULL,
                                   L_mpf_item_value) = FALSE then
            return FALSE;
         end if;
      end if;  -- buyer pack
   END LOOP;

   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DISTRIBUTE_MPF;
-----------------------------------------------------------------------
FUNCTION HTS_EXISTS(O_error_message          IN OUT  VARCHAR2,
                    O_exists                 IN OUT  BOOLEAN,
                    I_ce_id                  IN      CE_CHARGES.CE_ID%TYPE,
                    I_vessel_id              IN      CE_CHARGES.VESSEL_ID%TYPE,
                    I_voyage_id              IN      CE_CHARGES.VOYAGE_FLT_ID%TYPE,
                    I_estimated_depart_date  IN      CE_CHARGES.ESTIMATED_DEPART_DATE%TYPE,
                    I_order_no               IN      ORDHEAD.ORDER_NO%TYPE,
                    I_item                   IN      ITEM_MASTER.ITEM%TYPE,
                    I_pack_item              IN      ITEM_MASTER.ITEM%TYPE,
                    I_hts                    IN      HTS.HTS%TYPE,
                    I_effect_from            IN      HTS.EFFECT_FROM%TYPE,
                    I_effect_to              IN      HTS.EFFECT_TO%TYPE)
   RETURN BOOLEAN IS

   L_program   VARCHAR2(50) := 'CE_CHARGES_SQL.HTS_EXISTS';
   L_exists    VARCHAR2(1)  := 'N';

   cursor C_HTS_EXISTS is
      select 'Y'
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and ((pack_item           = I_pack_item
               and I_pack_item     is not NULL
               and pack_item is not NULL)
             or (pack_item         is NULL
                 and I_pack_item   is NULL))
         and hts                   = I_hts
         and effect_from           = I_effect_from
         and effect_to             = I_effect_to;

BEGIN
   O_exists := TRUE;
   ---
   SQL_LIB.SET_MARK('OPEN','C_HTS_EXISTS','CE_CHARGES',NULL);
   open C_HTS_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_HTS_EXISTS','CE_CHARGES',NULL);
   fetch C_HTS_EXISTS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_HTS_EXISTS','CE_CHARGES',NULL);
   close C_HTS_EXISTS;
   ---
   if L_exists = 'N' then
      O_exists := FALSE;
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
END HTS_EXISTS;
--------------------------------------------------------------------------------------
FUNCTION INSERT_ALWAYS_COMPS(O_error_message         IN OUT VARCHAR2,
                             I_ce_id                 IN     CE_HEAD.CE_ID%TYPE,
                             I_vessel_id             IN     CE_SHIPMENT.VESSEL_ID%TYPE,
                             I_voyage_flt_id         IN     CE_SHIPMENT.VOYAGE_FLT_ID%TYPE,
                             I_estimated_depart_date IN     CE_SHIPMENT.ESTIMATED_DEPART_DATE%TYPE,
                             I_order_no              IN     ORDHEAD.ORDER_NO%TYPE,
                             I_item                  IN     ITEM_MASTER.ITEM%TYPE,
                             I_pack_item             IN     ITEM_MASTER.ITEM%TYPE,
                             I_hts                   IN     HTS.HTS%TYPE,
                             I_import_country_id     IN     COUNTRY.COUNTRY_ID%TYPE,
                             I_effect_from           IN     HTS.EFFECT_FROM%TYPE,
                             I_effect_to             IN     HTS.EFFECT_TO%TYPE,
                             I_comp_id               IN     ELC_COMP.COMP_ID%TYPE,
                             I_cvb_code              IN     CVB_HEAD.CVB_CODE%TYPE)

RETURN BOOLEAN IS
   L_program             VARCHAR2(50) := 'CE_CHARGES_SQL.INSERT_ALWAYS_COMPS';
   L_exists              VARCHAR2(1)  := 'N';
   L_seq_no              CE_CHARGES.SEQ_NO%TYPE;
   L_first_record        CE_CHARGES.SEQ_NO%TYPE;
   L_ce_currency         CURRENCIES.CURRENCY_CODE%TYPE;
   L_ce_exchange_rate    CURRENCY_RATES.EXCHANGE_RATE%TYPE;
   L_ce_charge_seq_no    CE_CHARGES.SEQ_NO%TYPE;
   L_ce_comp_rate        CE_CHARGES.COMP_RATE%TYPE;
   L_ce_comp_value       CE_CHARGES.COMP_VALUE%TYPE;
   L_ce_per_count_uom    CE_CHARGES.PER_COUNT_UOM%TYPE;
   L_elc_currency        CURRENCIES.CURRENCY_CODE%TYPE;
   L_water_mode_ind      VARCHAR2(1)  := 'N';
   L_hmf_exists          VARCHAR2(1)  := 'N';
   L_table               VARCHAR2(30);
   RECORD_LOCKED         EXCEPTION;
   PRAGMA                EXCEPTION_INIT(Record_Locked, -54);

   cursor C_CHECK_EXISTS is
      select 'Y'
        from ordsku_hts
       where order_no   = I_order_no
         and item       = I_item
         and ((pack_item = I_pack_item
               and I_pack_item is not NULL)
          or (pack_item is NULL and I_pack_item is NULL))
         and hts        = I_hts;

   cursor C_CE_SHIPMENT is
      select 'Y'
        from ce_shipment
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and tran_mode_id          in (10, 11, 12);

   cursor C_HMF_EXISTS is
      select 'Y'
        from ordsku_hts_assess oha,
             ordsku_hts oh
       where oha.order_no         = oh.order_no
         and oha.seq_no           = oh.seq_no
         and oh.order_no          = I_order_no
         and oh.hts               = I_hts
         and oh.import_country_id = I_import_country_id
         and oh.effect_from       = I_effect_from
         and oh.effect_to         = I_effect_to
         and oha.comp_id          like 'HMF%';

   cursor C_LOCK_CE_CHARGES is
      select 'x'
        from ce_charges
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and ((pack_item           = I_pack_item
               and pack_item      is not NULL
               and I_pack_item    is not NULL)
             or (pack_item        is NULL
                 and I_pack_item  is NULL))
         and seq_no                = L_ce_charge_seq_no
         for update nowait;

   cursor C_CONVERT_CURRENCY is
      select elc.comp_currency,
             cc.seq_no,
             cc.comp_rate,
             cc.comp_value,
             cc.per_count_uom
        from ce_charges cc,
             elc_comp  elc
       where cc.ce_id                 = I_ce_id
         and cc.vessel_id             = I_vessel_id
         and cc.voyage_flt_id         = I_voyage_flt_id
         and cc.estimated_depart_date = I_estimated_depart_date
         and cc.order_no              = I_order_no
         and cc.item                  = I_item
         and ((pack_item              = I_pack_item
               and pack_item         is not NULL
               and I_pack_item       is not NULL)
             or (pack_item           is NULL
                 and I_pack_item     is NULL))
         and cc.seq_no                > L_first_record
         and cc.comp_id               = elc.comp_id
         and elc.comp_type            = 'A'
    order by seq_no;

BEGIN
   if GET_MAX_SEQ_NO(O_error_message,
                     L_seq_no,
                     I_ce_id,
                     I_vessel_id,
                     I_voyage_flt_id,
                     I_estimated_depart_date,
                     I_order_no,
                     I_item,
                     I_pack_item) = FALSE then
      return FALSE;
   end if;
   ---
   -- need to keep track of what records were added so the
   -- currency can be converted into customs entry currency.
   ---
   L_first_record := L_seq_no;
   ---
   -- retrieve customs entry currency for currency conversions
   ---
   if CE_SQL.GET_CURRENCY_RATE(O_error_message,
                               L_ce_currency,
                               L_ce_exchange_rate,
                               I_ce_id) = FALSE then
      return FALSE;
   end if;
   ---
   -- pull value off ordsku_hts_assesss otherwise default with zero
   ---
   SQL_LIB.SET_MARK('OPEN','C_CHECK_EXISTS','ORDSKU_HTS', NULL);
   open C_CHECK_EXISTS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_EXISTS','ORDSKU_HTS', NULL);
   fetch C_CHECK_EXISTS into L_exists;
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_EXISTS','ORDSKU_HTS', NULL);
   close C_CHECK_EXISTS;
   ---
   if I_comp_id <> 'HMF'||I_import_country_id then
      SQL_LIB.SET_MARK('OPEN','C_CE_SHIPMENT','CE_SHIPMENT',NULL);
      open C_CE_SHIPMENT;
      SQL_LIB.SET_MARK('FETCH','C_CE_SHIPMENT','CE_SHIPMENT',NULL);
      fetch C_CE_SHIPMENT into L_water_mode_ind;
      SQL_LIB.SET_MARK('CLOSE','C_CE_SHIPMENT','CE_SHIPMENT',NULL);
      close C_CE_SHIPMENT;
      ---
      -- record exists on ordsku_hts for the given hts/order/item combination
      ---
      if L_exists = 'Y' then
         SQL_LIB.SET_MARK('OPEN','C_HMF_EXISTS','ORDSKU_HTS',NULL);
         open C_HMF_EXISTS;
         SQL_LIB.SET_MARK('FETCH','C_HMF_EXISTS','ORDSKU_HTS',NULL);
         fetch C_HMF_EXISTS into L_hmf_exists;
         SQL_LIB.SET_MARK('CLOSE','C_HMF_EXISTS','ORDSKU_HTS',NULL);
         close C_HMF_EXISTS;
         ---
         if L_water_mode_ind = 'Y' and L_hmf_exists = 'N' then
            insert into ce_charges (ce_id,
                                    vessel_id,
                                    voyage_flt_id,
                                    estimated_depart_date,
                                    order_no,
                                    item,
                                    seq_no,
                                    pack_item,
                                    hts,
                                    effect_from,
                                    effect_to,
                                    comp_id,
                                    comp_rate,
                                    per_count_uom,
                                    comp_value,
                                    cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   ec.comp_id,
                   ec.comp_rate/ NVL(ec.per_count,1),
                   ec.per_count_uom,
                   0,
                   NVL(I_cvb_code, ec.cvb_code)
              from elc_comp ec
             where ec.comp_id            like 'HMF%'
               and ec.import_country_id  = I_import_country_id;
         end if;
      else  -- doesn't exist on order
         if L_water_mode_ind = 'Y' then
            insert into ce_charges (ce_id,
                                    vessel_id,
                                    voyage_flt_id,
                                    estimated_depart_date,
                                    order_no,
                                    item,
                                    seq_no,
                                    pack_item,
                                    hts,
                                    effect_from,
                                    effect_to,
                                    comp_id,
                                    comp_rate,
                                    per_count_uom,
                                    comp_value,
                                    cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   ec.comp_id,
                   ec.comp_rate/ NVL(ec.per_count,1),
                   ec.per_count_uom,
                   0,
                   NVL(I_cvb_code, ec.cvb_code)
              from elc_comp ec
             where ec.comp_id            like 'HMF%'
               and ec.import_country_id  = I_import_country_id
            and not exists (select 'x'
                              from ce_charges c
                             where c.ce_id                 = I_ce_id
                               and c.vessel_id             = I_vessel_id
                               and c.voyage_flt_id         = I_voyage_flt_id
                               and c.estimated_depart_date = I_estimated_depart_date
                               and c.order_no              = I_order_no
                               and c.item                  = I_item
                               and ((c.pack_item           = I_pack_item
                                     and I_pack_item is not NULL)
                                or (c.pack_item is NULL and I_pack_item is NULL))
                               and c.hts                   = I_hts
                               and c.effect_from           = I_effect_from
                               and c.effect_to             = I_effect_to
                               and c.comp_id               like 'HMF%');
         end if;
      end if;  -- L_exists
   end if;  -- I_comp_id not like 'HMF%'
   ---
   if GET_MAX_SEQ_NO(O_error_message,
                     L_seq_no,
                     I_ce_id,
                     I_vessel_id,
                     I_voyage_flt_id,
                     I_estimated_depart_date,
                     I_order_no,
                     I_item,
                     I_pack_item) = FALSE then
      return FALSE;
   end if;
   ---
   if L_exists = 'Y' then
         SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
         insert into ce_charges (ce_id,
                                 vessel_id,
                                 voyage_flt_id,
                                 estimated_depart_date,
                                 order_no,
                                 item,
                                 seq_no,
                                 pack_item,
                                 hts,
                                 effect_from,
                                 effect_to,
                                 comp_id,
                                 comp_rate,
                                 per_count_uom,
                                 comp_value,
                                 cvb_code)
            select I_ce_id,
                   I_vessel_id,
                   I_voyage_flt_id,
                   I_estimated_depart_date,
                   I_order_no,
                   I_item,
                   L_seq_no + rownum,
                   I_pack_item,
                   I_hts,
                   I_effect_from,
                   I_effect_to,
                   a.comp_id,
                   a.comp_rate/ NVL(a.per_count,1),
                   a.per_count_uom,
                   a.est_assess_value,
                   a.cvb_code
              from ordsku_hts o,
                   ordsku_hts_assess a,
                   elc_comp e
             where ((a.comp_id               NOT like 'HMF%'
                    and L_water_mode_ind    = 'N')
                    or L_water_mode_ind     = 'Y')
               and o.order_no           = I_order_no
               and e.comp_id            = a.comp_id
               and o.order_no           = a.order_no
               and o.seq_no             = a.seq_no
               and e.always_default_ind = 'Y'
               and o.item               = I_item
               and ((o.pack_item        = I_pack_item)
                or (o.pack_item is NULL and I_pack_item is NULL))
               and o.hts                = I_hts
               and o.import_country_id  = I_import_country_id
               and o.effect_from        = I_effect_from
               and o.effect_to          = I_effect_to
               and a.nom_flag_2        in ('+','-')
               and not exists (select 'x'
                                 from ce_charges c
                                where c.ce_id                 = I_ce_id
                                  and c.vessel_id             = I_vessel_id
                                  and c.voyage_flt_id         = I_voyage_flt_id
                                  and c.estimated_depart_date = I_estimated_depart_date
                                  and c.order_no              = I_order_no
                                  and c.item                  = I_item
                                  and ((c.pack_item           = I_pack_item
                                        and I_pack_item is not NULL)
                                   or (c.pack_item is NULL and I_pack_item is NULL))
                                  and c.hts                   = I_hts
                                  and c.effect_from           = I_effect_from
                                  and c.effect_to             = I_effect_to
                                  and c.comp_id               = a.comp_id);
   else
      ---
      -- Insert Assessments with the Always Default Indicator set to 'Y'.
      ---
      SQL_LIB.SET_MARK('INSERT', NULL, 'CE_CHARGES', NULL);
      insert into ce_charges(ce_id,
                             vessel_id,
                             voyage_flt_id,
                             estimated_depart_date,
                             order_no,
                             item,
                             seq_no,
                             pack_item,
                             hts,
                             effect_from,
                             effect_to,
                             comp_id,
                             comp_rate,
                             per_count_uom,
                             comp_value,
                             cvb_code)
         select I_ce_id,
                I_vessel_id,
                I_voyage_flt_id,
                I_estimated_depart_date,
                I_order_no,
                I_item,
                L_seq_no + rownum,
                I_pack_item,
                I_hts,
                I_effect_from,
                I_effect_to,
                ec.comp_id,
                (ec.comp_rate / NVL(ec.per_count,1)),
                ec.per_count_uom,
                0,
                DECODE(ec.calc_basis, 'S', NULL, NVL(I_cvb_code, ec.cvb_code))
           from elc_comp ec
          where ec.comp_type          = 'A'
            and ec.import_country_id  = I_import_country_id
            and ec.nom_flag_2         in ('+','-')
            and ec.always_default_ind = 'Y'
            and not exists (select 'x'
                              from ce_charges c
                             where c.ce_id                 = I_ce_id
                               and c.vessel_id             = I_vessel_id
                               and c.voyage_flt_id         = I_voyage_flt_id
                               and c.estimated_depart_date = I_estimated_depart_date
                               and c.order_no              = I_order_no
                               and c.item                  = I_item
                               and ((c.pack_item           = I_pack_item
                                     and I_pack_item is not NULL)
                                or (c.pack_item is NULL and I_pack_item is NULL))
                               and c.hts                   = I_hts
                               and c.effect_from           = I_effect_from
                               and c.effect_to             = I_effect_to
                               and c.comp_id               = ec.comp_id);
   end if;
   ---
   -- Assessment components need to be converted into customs entry
   -- currency.
   ---
   for C_CONVERT_CURRENCY_REC in C_CONVERT_CURRENCY loop
      L_elc_currency     := C_CONVERT_CURRENCY_REC.comp_currency;
      L_ce_charge_seq_no := C_CONVERT_CURRENCY_REC.seq_no;
      L_ce_comp_rate     := C_CONVERT_CURRENCY_REC.comp_rate;
      L_ce_comp_value    := C_CONVERT_CURRENCY_REC.comp_value;
      L_ce_per_count_uom := C_CONVERT_CURRENCY_REC.per_count_uom;

      --- convert from component currency to customs entry currency
      if CURRENCY_SQL.CONVERT(O_error_message,
                              L_ce_comp_value,
                              L_elc_currency,
                              L_ce_currency,
                              L_ce_comp_value,
                              'C',
                              NULL,
                              NULL,
                              NULL,
                              L_ce_exchange_rate) = FALSE then
         return FALSE;
      end if;
      ---
      if L_ce_per_count_uom is not NULL then
         if CURRENCY_SQL.CONVERT(O_error_message,
                                 L_ce_comp_rate,
                                 L_elc_currency,
                                 L_ce_currency,
                                 L_ce_comp_rate,
                                 'C',
                                 NULL,
                                 NULL,
                                 NULL,
                                 L_ce_exchange_rate) = FALSE then
            return FALSE;
         end if;
      end if;
      ---
      L_table := 'CE_CHARGES';
      ---
      SQL_LIB.SET_MARK('OPEN','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
      open C_LOCK_CE_CHARGES;
      SQL_LIB.SET_MARK('CLOSE','C_LOCK_CE_CHARGES','CE_CHARGES',NULL);
      close C_LOCK_CE_CHARGES;
      ---
      SQL_LIB.SET_MARK('UPDATE',NULL,'CE_CHARGES',NULL);
      update ce_charges
         set comp_rate  = L_ce_comp_rate,
             comp_value = L_ce_comp_value
       where ce_id                 = I_ce_id
         and vessel_id             = I_vessel_id
         and voyage_flt_id         = I_voyage_flt_id
         and estimated_depart_date = I_estimated_depart_date
         and order_no              = I_order_no
         and item                  = I_item
         and ((pack_item           = I_pack_item
               and pack_item      is not NULL
               and I_pack_item    is not NULL)
             or (pack_item        is NULL
                 and I_pack_item  is NULL))
         and seq_no                = L_ce_charge_seq_no;

   end loop;
   ---
   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                             L_table,
                                             to_char(I_ce_id),
                                             NULL);
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END INSERT_ALWAYS_COMPS;
--------------------------------------------------------------------------------------
END CE_CHARGES_SQL;
/

