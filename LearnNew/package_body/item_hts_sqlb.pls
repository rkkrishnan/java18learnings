CREATE OR REPLACE PACKAGE BODY ITEM_HTS_SQL AS
------------------------------------------------------------------------------------------------
--Mod By:      Govindarajan Karthigeyan, Govindarajan.Karthigeyan@in.tesco.com
--Mod Date:    25-Jun-2007
--Mod Ref:     Mod number. 365b1
--Mod Details: Cascading the base item hts information to its variants.
--             Appeneded TSL_COPY_BASE_HTS new function.
------------------------------------------------------------------------------------------------
FUNCTION ITEM_HTS_EXIST (O_error_message IN OUT VARCHAR2,
                         O_exists        IN OUT	BOOLEAN,
                         I_item          IN     ITEM_MASTER.ITEM%TYPE)
RETURN BOOLEAN IS

   L_exists  VARCHAR2(1);
   L_program VARCHAR2(50) := 'ITEM_HTS_SQL.ITEM_HTS_EXIST';

   cursor C_ITEM_HTS_EXIST is
      select 'x'
        from item_hts
       where item = I_item
       and ROWNUM = 1;

BEGIN
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_ITEM_HTS_EXIST','ITEM_HTS','Item: ' || I_item);
   open C_ITEM_HTS_EXIST;
   SQL_LIB.SET_MARK('FETCH','C_ITEM_HTS_EXIST','ITEM_HTS','Item: ' || I_item);
   fetch C_ITEM_HTS_EXIST into L_exists;
   ---
   if C_ITEM_HTS_EXIST%NOTFOUND then
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_ITEM_HTS_EXIST','ITEM_HTS','Item: ' || I_item);
   close C_ITEM_HTS_EXIST;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ITEM_HTS_EXIST;
--------------------------------------------------------------------------------------
FUNCTION HTS_EXIST(O_error_message     IN OUT VARCHAR2,
                   O_exists            IN OUT BOOLEAN,
                   I_item              IN     ITEM_MASTER.ITEM%TYPE,
                   I_hts               IN     HTS.HTS%TYPE,
                   I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                   I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                   I_effect_from       IN     HTS.EFFECT_FROM%TYPE,
                   I_effect_to         IN     HTS.EFFECT_TO%TYPE)
RETURN BOOLEAN IS
   L_exists  VARCHAR2(1);
   L_program VARCHAR2(50) := 'ITEM_HTS_SQL.HTS_EXIST';

   cursor C_CHECK_HTS is
      select 'Y'
        from item_hts
       where item              = I_item
         and hts               = I_hts
         and import_country_id = I_import_country_id
         and origin_country_id = I_origin_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to;

BEGIN
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_CHECK_HTS','ITEM_HTS',NULL);
   open C_CHECK_HTS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_HTS','ITEM_HTS',NULL);
   fetch C_CHECK_HTS into L_exists;
   ---
   if C_CHECK_HTS%NOTFOUND then
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_HTS','ITEM_HTS',NULL);
   close C_CHECK_HTS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END HTS_EXIST;
--------------------------------------------------------------------------------------
FUNCTION ASSESS_EXIST(O_error_message     IN OUT VARCHAR2,
                      O_exists            IN OUT BOOLEAN,
                      I_item              IN     ITEM_MASTER.ITEM%TYPE,
                      I_hts               IN     HTS.HTS%TYPE,
                      I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                      I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                      I_effect_from       IN     HTS.EFFECT_FROM%TYPE,
                      I_effect_to         IN     HTS.EFFECT_TO%TYPE,
                      I_comp_id           IN     ELC_COMP.COMP_ID%TYPE)
RETURN BOOLEAN IS
   L_exists  VARCHAR2(1);
   L_program VARCHAR2(50) := 'ITEM_HTS_SQL.ASSESS_EXIST';

   cursor C_CHECK_ASSESS is
      select 'Y'
        from item_hts_assess
       where item              = I_item
         and hts               = I_hts
         and import_country_id = I_import_country_id
         and origin_country_id = I_origin_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and comp_id           = I_comp_id;

BEGIN
   O_exists := TRUE;

   SQL_LIB.SET_MARK('OPEN','C_CHECK_ASSESS','ITEM_HTS_ASSESS',NULL);
   open C_CHECK_ASSESS;
   SQL_LIB.SET_MARK('FETCH','C_CHECK_ASSESS','ITEM_HTS_ASSESS',NULL);
   fetch C_CHECK_ASSESS into L_exists;
   ---
   if C_CHECK_ASSESS%NOTFOUND then
      O_exists := FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('CLOSE','C_CHECK_ASSESS','ITEM_HTS_ASSESS',NULL);
   close C_CHECK_ASSESS;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END ASSESS_EXIST;
--------------------------------------------------------------------------------------
FUNCTION DELETE_ASSESS(O_error_message     IN OUT VARCHAR2,
                       I_item              IN     ITEM_MASTER.ITEM%TYPE,
                       I_hts               IN     HTS.HTS%TYPE,
                       I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                       I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                       I_effect_from       IN     HTS.EFFECT_FROM%TYPE,
                       I_effect_to         IN     HTS.EFFECT_TO%TYPE)
RETURN BOOLEAN IS

   L_program     VARCHAR2(50) := 'ITEM_HTS_SQL.DELETE_ASSESS';
   L_table       VARCHAR2(30) := 'ITEM_HTS_ASSESS';
   RECORD_LOCKED EXCEPTION;
   PRAGMA        EXCEPTION_INIT(RECORD_LOCKED, -54);

   cursor C_LOCK_ITEM_HTS_ASSESS is
      select 'x'
        from item_hts_assess
        where item              = I_item
          and hts               = I_hts
          and import_country_id = I_import_country_id
          and origin_country_id = I_origin_country_id
          and effect_from       = I_effect_from
          and effect_to         = I_effect_to
          for update nowait;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_LOCK_ITEM_HTS_ASSESS','ITEM_HTS_ASSESS',NULL);
   open C_LOCK_ITEM_HTS_ASSESS;
   SQL_LIB.SET_MARK('CLOSE','C_LOCK_ITEM_HTS_ASSESS','ITEM_HTS_ASSESS',NULL);
   close C_LOCK_ITEM_HTS_ASSESS;

   SQL_LIB.SET_MARK('DELETE',NULL,'ITEM_HTS_ASSESS',NULL);
   delete from item_hts_assess
          where item            = I_item
          and hts               = I_hts
          and import_country_id = I_import_country_id
          and origin_country_id = I_origin_country_id
          and effect_from       = I_effect_from
          and effect_to         = I_effect_to;

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
END DELETE_ASSESS;
--------------------------------------------------------------------------------------
FUNCTION GET_QUANTITIES(O_error_message     IN OUT VARCHAR2,
                        O_qty_1             IN OUT NUMBER,
                        O_qty_2             IN OUT NUMBER,
                        O_qty_3             IN OUT NUMBER,
                        I_item              IN     ITEM_MASTER.ITEM%TYPE,
                        I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                        I_units_1           IN     HTS.UNITS_1%TYPE,
                        I_units_2           IN     HTS.UNITS_2%TYPE,
                        I_units_3           IN     HTS.UNITS_3%TYPE)
RETURN BOOLEAN IS
   L_supp_pack_size  ITEM_SUPP_COUNTRY.SUPP_PACK_SIZE%TYPE;
   L_ship_carton_wt  ITEM_SUPP_COUNTRY_DIM.WEIGHT%TYPE;
   L_ship_carton_hgt ITEM_SUPP_COUNTRY_DIM.HEIGHT%TYPE;
   L_ship_carton_wid ITEM_SUPP_COUNTRY_DIM.WIDTH%TYPE;
   L_ship_carton_len ITEM_SUPP_COUNTRY_DIM.LENGTH%TYPE;
   L_supplier        ITEM_SUPP_COUNTRY.SUPPLIER%TYPE;
   L_uom             UOM_CLASS.UOM%TYPE;
   L_standard_uom    UOM_CLASS.UOM%TYPE;
   L_wt_uom          UOM_CLASS.UOM%TYPE;
   L_lwh_uom         UOM_CLASS.UOM%TYPE;
   L_from_uom        UOM_CLASS.UOM%TYPE;
   L_class           UOM_CLASS.UOM_CLASS%TYPE;
   L_standard_class  UOM_CLASS.UOM_CLASS%TYPE;
   L_qty             NUMBER;
   L_from_value      NUMBER               := 0;
   L_counter         NUMBER               := 0;
   L_program         VARCHAR2(50)         := 'ITEM_HTS_SQL.GET_QUANTITIES';
   L_if_error        IF_ERRORS.ERROR%TYPE := NULL;
   L_error_ind       VARCHAR2(1);
   L_liquid_volume   ITEM_SUPP_COUNTRY_DIM.LIQUID_VOLUME%TYPE;
   L_liquid_vol_uom  UOM_CLASS.UOM%TYPE;

   cursor C_PHYSICAL_ATTRIB is
      select supp_pack_size,
             nvl(height,0),
             nvl(width,0),
             nvl(length,0),
             lwh_uom,
             nvl(weight,0),
             weight_uom,
             nvl(liquid_volume,0),
             liquid_volume_uom,
             isc.supplier
        from item_supp_country isc,
             item_supp_country_dim iscd
       where isc.item               = I_item
         and isc.origin_country_id  = I_origin_country_id
         and isc.item               = iscd.item(+)
         and isc.origin_country_id  = iscd.origin_country(+)
         and isc.supplier           = iscd.supplier(+)
         and iscd.dim_object(+)     = 'CA'
         and (primary_supp_ind  = 'Y'
              or not exists (select 'x'
                               from item_supp_country
                              where origin_country_id = I_origin_country_id
                                and item              = I_item
                                and primary_supp_ind  = 'Y'));

   cursor C_MISC_VALUE is
      select value
        from item_supp_uom
       where item     = I_item
         and supplier = L_supplier
         and uom      = L_uom;

BEGIN
   SQL_LIB.SET_MARK('OPEN','C_PHYSICAL_ATTRIB','ITEM_SUPP_COUNTRY',
                    'Item: ' || I_item ||
                    ' Origin Country: ' || I_origin_country_id);
   open C_PHYSICAL_ATTRIB;
   SQL_LIB.SET_MARK('FETCH','C_PHYSICAL_ATTRIB','ITEM_SUPP_COUNTRY',
                    'Item: ' || I_item ||
                    ' Origin Country: ' || I_origin_country_id);
   fetch C_PHYSICAL_ATTRIB into L_supp_pack_size,
                                L_ship_carton_hgt,
                                L_ship_carton_wid,
                                L_ship_carton_len,
                                L_lwh_uom,
                                L_ship_carton_wt,
                                L_wt_uom,
                                L_liquid_volume,
                                L_liquid_vol_uom,
                                L_supplier;

   if C_PHYSICAL_ATTRIB%NOTFOUND then
      SQL_LIB.SET_MARK('CLOSE','C_PHYSICAL_ATTRIB','ITEM_SUPP_COUNTRY',
                       'Item: ' || I_item ||
                       ' Origin Country: ' || I_origin_country_id);
      close C_PHYSICAL_ATTRIB;
      O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_ORIGIN_REC',I_origin_country_id,NULL,NULL);
      return FALSE;
   end if;

   SQL_LIB.SET_MARK('CLOSE','C_PHYSICAL_ATTRIB','ITEM_SUPP_COUNTRY',
                    'Item: ' || I_item ||
                    ' Origin Country: ' || I_origin_country_id);
   close C_PHYSICAL_ATTRIB;
   ---
   L_uom := I_units_1;
   loop
      L_counter   := L_counter + 1;
      L_qty       := 0;
      L_error_ind := 'N';

      if L_uom is not NULL and L_uom <> 'X' then
         if UOM_SQL.GET_CLASS(O_error_message,
                              L_class,
                              L_uom) = FALSE then
            return FALSE;
         end if;
         ---
         if L_class = 'QTY' then
            if not ITEM_ATTRIB_SQL.GET_STANDARD_UOM(O_error_message,
                                                    L_standard_uom,
                                                    L_standard_class,
                                                    L_from_value,
                                                    I_item,
                                                    'N') then
                return FALSE;
            end if;
            ---
            if L_from_value is NULL then
               if L_standard_uom = 'EA' then
                  L_from_value := 1;
               else
                  L_from_value := 0;
                  L_if_error := SQL_LIB.GET_MESSAGE_TEXT('NO_CONV_FACTOR', I_item);
                  L_error_ind := 'Y';
               end if;
               ---
            end if;
            L_from_uom := 'EA';
            ---
         elsif L_class = 'MISC' then
            SQL_LIB.SET_MARK('OPEN','C_MISC_VALUE','ITEM_SUPP_UOM',
                             'Item: ' || I_item ||
                             ' Supplier: ' || to_char(L_supplier) ||
                             ' UOM: ' || L_uom);
            open C_MISC_VALUE;
            SQL_LIB.SET_MARK('FETCH','C_MISC_VALUE','ITEM_SUPP_UOM',
                             'Item: ' || I_item ||
                             ' Supplier: ' || to_char(L_supplier) ||
                             ' UOM: ' || L_uom);
            fetch C_MISC_VALUE into L_qty;
            if C_MISC_VALUE%NOTFOUND then
               L_from_value := 0;
               L_if_error := SQL_LIB.GET_MESSAGE_TEXT('NO_MISC_CONV_INFO',
                                                       I_item,
                                                       to_char(L_supplier));
               L_error_ind := 'Y';
            end if;
            SQL_LIB.SET_MARK('CLOSE','C_MISC_VALUE','ITEM_SUPP_UOM',
                             'Item: ' || I_item ||
                             ' Supplier: ' || to_char(L_supplier) ||
                             ' UOM: ' || L_uom);
            close C_MISC_VALUE;
         elsif L_class = 'PACK' then
            L_qty := 1 / L_supp_pack_size;
         elsif L_class = 'MASS' then
            L_from_value := L_ship_carton_wt / L_supp_pack_size;
            L_from_uom   := L_wt_uom;
            if L_ship_carton_wt = 0 then
               L_error_ind := 'Y';
               L_if_error  := SQL_LIB.GET_MESSAGE_TEXT('NO_WT_INFO',
                                                       I_item,
                                                       to_char(L_supplier),
                                                       I_origin_country_id);
            end if;
         elsif L_class = 'VOL' then
            L_from_value := L_ship_carton_hgt * L_ship_carton_wid * L_ship_carton_len / L_supp_pack_size;
            L_from_uom   := L_lwh_uom || '3';
            if L_ship_carton_hgt = 0 or L_ship_carton_wid = 0 or L_ship_carton_len = 0 then
               L_error_ind := 'Y';
               L_if_error  := SQL_LIB.GET_MESSAGE_TEXT('NO_DIMEN_INFO',
                                                       I_item,
                                                       to_char(L_supplier),
                                                       I_origin_country_id);
            end if;
         elsif L_class = 'AREA' then
            L_from_value := L_ship_carton_wid * L_ship_carton_len / L_supp_pack_size;
            L_from_uom   := L_lwh_uom || '2';
            if L_ship_carton_wid = 0 or L_ship_carton_len = 0 then
               L_error_ind := 'Y';
               L_if_error   := SQL_LIB.GET_MESSAGE_TEXT('NO_DIMEN_INFO',
                                                        I_item,
                                                        to_char(L_supplier),
                                                        I_origin_country_id);
            end if;
         elsif L_class = 'DIMEN' then
            L_from_value := L_ship_carton_len / L_supp_pack_size;
            L_from_uom   := L_lwh_uom;
            if L_ship_carton_len = 0 then
               L_error_ind := 'Y';
               L_if_error   := SQL_LIB.GET_MESSAGE_TEXT('NO_DIMEN_INFO',
                                                        I_item,
                                                        to_char(L_supplier),
                                                        I_origin_country_id);
            end if;
         elsif L_class = 'LVOL' then
            L_from_value := L_liquid_volume;
            L_from_uom   := L_liquid_vol_uom;
         else
            O_error_message := SQL_LIB.CREATE_MSG('NO_QTY',L_uom,NULL,NULL);
            return FALSE;
         end if;
         if L_error_ind = 'Y' then
            if not INTERFACE_SQL.INSERT_INTERFACE_ERROR(O_error_message,
                                                        L_if_error,
                                                        L_program,
                                                        'Item: ' || I_item ||
                                                        ' Supplier: ' || to_char(L_supplier) ||
                                                        ' Origin Country: ' || I_origin_country_id) then
               return FALSE;
            end if;
         else
            if L_class in ('QTY', 'MASS', 'VOL', 'AREA', 'DIMEN','LVOL') and L_from_value <> 0 then
               if not UOM_SQL.WITHIN_CLASS(O_error_message,
                                           L_qty,
                                           L_uom,
                                           L_from_value,
                                           L_from_uom,
                                           L_class) then
                  return FALSE;
               end if;
            end if;
         end if;
      else
         L_qty := NULL;
      end if;

      if L_counter = 1 then
         O_qty_1 := L_qty;
         L_uom   := I_units_2;
      elsif L_counter = 2 then
         O_qty_2 := L_qty;
         L_uom   := I_units_3;
      else
         O_qty_3 := L_qty;
         exit;
      end if;
   end loop;

   return TRUE;
EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END GET_QUANTITIES;
--------------------------------------------------------------------------------------
FUNCTION GET_HTS_DETAILS (O_error_message     IN OUT VARCHAR2,
                          O_tariff_treatment  IN OUT HTS_TARIFF_TREATMENT.TARIFF_TREATMENT%TYPE,
                          O_qty_1             IN OUT NUMBER,
                          O_qty_2             IN OUT NUMBER,
                          O_qty_3             IN OUT NUMBER,
                          O_units_1           IN OUT HTS.UNITS_1%TYPE,
                          O_units_2           IN OUT HTS.UNITS_2%TYPE,
                          O_units_3           IN OUT HTS.UNITS_3%TYPE,
                          O_specific_rate     IN OUT HTS_TARIFF_TREATMENT.SPECIFIC_RATE%TYPE,
                          O_av_rate           IN OUT HTS_TARIFF_TREATMENT.AV_RATE%TYPE,
                          O_other_rate        IN OUT HTS_TARIFF_TREATMENT.OTHER_RATE%TYPE,
                          O_cvd_case_no       IN OUT HTS_CVD.CASE_NO%TYPE,
                          O_ad_case_no        IN OUT HTS_AD.CASE_NO%TYPE,
                          O_duty_comp_code    IN OUT HTS.DUTY_COMP_CODE%TYPE,
                          I_item              IN     ITEM_MASTER.ITEM%TYPE,
                          I_supplier          IN     SUPS.SUPPLIER%TYPE,
                          I_hts               IN     HTS.HTS%TYPE,
                          I_import_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                          I_origin_country_id IN     COUNTRY.COUNTRY_ID%TYPE,
                          I_effect_from       IN     HTS.EFFECT_FROM%TYPE,
                          I_effect_to         IN     HTS.EFFECT_TO%TYPE)
RETURN BOOLEAN IS
   L_supplier      SUPS.SUPPLIER%TYPE;
   L_mfg_id        HTS_AD.MFG_ID%TYPE;
   L_hts_desc      HTS.HTS_DESC%TYPE;
   L_chapter       HTS.CHAPTER%TYPE;
   L_quota_cat     HTS.QUOTA_CAT%TYPE;
   L_more_hts_ind  HTS.MORE_HTS_IND%TYPE;
   L_units         HTS.UNITS%TYPE;
   L_cvd_ind       HTS.CVD_IND%TYPE;
   L_ad_ind        HTS.AD_IND%TYPE;
   L_quota_ind     HTS.QUOTA_IND%TYPE;
   L_tariff        TARIFF_TREATMENT.TARIFF_TREATMENT%TYPE;
   L_specific      HTS_TARIFF_TREATMENT.SPECIFIC_RATE%TYPE;
   L_av            HTS_TARIFF_TREATMENT.AV_RATE%TYPE;
   L_other         HTS_TARIFF_TREATMENT.OTHER_RATE%TYPE;
   L_excluded      VARCHAR2(1)       := 'N';
   L_conditional   VARCHAR2(1)       := 'N';
   L_eligible      VARCHAR2(1)       := 'N';
   L_exists        VARCHAR2(1)       := 'N';
   L_prev_specific NUMBER            := 9999.99999999;
   L_prev_av       NUMBER            := 9999.99999999;
   L_prev_other    NUMBER            := 9999.99999999;
   L_vdate         PERIOD.VDATE%TYPE := GET_VDATE;
   L_program       VARCHAR2(50)      := 'ITEM_HTS_SQL.GET_HTS_DETAILS';

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

   cursor C_GET_CVD is
      select case_no
        from hts_cvd
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and origin_country_id = I_origin_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to;

   cursor C_GET_AD is
      select case_no
        from hts_ad
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and origin_country_id = I_origin_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and mfg_id            = L_mfg_id;

   cursor C_TARIFF is
      select ctt1.tariff_treatment
        from country_tariff_treatment ctt1
       where ctt1.country_id     = I_origin_country_id
         and ctt1.effective_from = (select MAX(ctt2.effective_from)
                                      from country_tariff_treatment ctt2
                                     where ctt2.tariff_treatment = ctt1.tariff_treatment
                                       and ctt2.country_id       = I_origin_country_id
                                       and L_vdate              >= ctt2.effective_from
                                       and (L_vdate             <= ctt2.effective_to
                                            or ctt2.effective_to is NULL))
       order by ctt1.tariff_treatment desc;

   cursor C_EXCLUDED is
      select 'Y'
        from hts_tt_exclusions
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and origin_country_id = I_origin_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and tariff_treatment  = L_tariff;

   cursor C_CONDITIONAL is
      select conditional_ind
        from tariff_treatment
       where tariff_treatment = L_tariff;

   cursor C_COND_TARIFF is
      select 'Y'
        from cond_tariff_treatment
       where item             = I_item
         and tariff_treatment = L_tariff;

   cursor C_GET_RATES is
      select specific_rate,
             av_rate,
             other_rate,
             'Y'
        from hts_tariff_treatment
       where hts               = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and tariff_treatment  = L_tariff;

   cursor C_GET_MFG_ID is
      select mfg_id
        from sup_import_attr
       where supplier = L_supplier;

BEGIN
   O_specific_rate    := NULL;
   O_av_rate          := NULL;
   O_other_rate       := NULL;
   O_tariff_treatment := NULL;
   ---
   if I_supplier is NULL then
      SQL_LIB.SET_MARK('OPEN','C_SUPPLIER','ITEM_SUPP_COUNTRY',
                       'Item: ' || I_item ||
                       ' Origin Country: ' || I_origin_country_id);
      open C_SUPPLIER;
      SQL_LIB.SET_MARK('FETCH','C_SUPPLIER','ITEM_SUPP_COUNTRY',
                       'Item: ' || I_item ||
                       ' Origin Country: ' || I_origin_country_id);
      fetch C_SUPPLIER into L_supplier;
      if C_SUPPLIER%NOTFOUND then
         SQL_LIB.SET_MARK('CLOSE','C_SUPPLIER','ITEM_SUPP_COUNTRY',
                          'Item: ' || I_item ||
                          ' Origin Country: ' || I_origin_country_id);
         close C_SUPPLIER;
         O_error_message := SQL_LIB.CREATE_MSG('NO_ITEM_ORIGIN_REC',I_origin_country_id,NULL,NULL);
         return FALSE;
      end if;
      ---
      SQL_LIB.SET_MARK('CLOSE','C_SUPPLIER','ITEM_SUPP_COUNTRY',
                       'Item: ' || I_item ||
                       ' Origin Country: ' || I_origin_country_id);
      close C_SUPPLIER;
   else
      L_supplier := I_supplier;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_MFG_ID','SUP_IMPORT_ATTR','Supplier: '||to_char(L_supplier));
   open C_GET_MFG_ID;
   SQL_LIB.SET_MARK('FETCH','C_GET_MFG_ID','SUP_IMPORT_ATTR','Supplier: '||to_char(L_supplier));
   fetch C_GET_MFG_ID into L_mfg_id;
   SQL_LIB.SET_MARK('CLOSE','C_GET_MFG_ID','SUP_IMPORT_ATTR','Supplier: '||to_char(L_supplier));
   close C_GET_MFG_ID;
   ---
   if L_mfg_id is not NULL then
      SQL_LIB.SET_MARK('OPEN','C_GET_AD','HTS_AD',NULL);
      open C_GET_AD;
      SQL_LIB.SET_MARK('FETCH','C_GET_AD','HTS_AD',NULL);
      fetch C_GET_AD into O_ad_case_no;
      SQL_LIB.SET_MARK('CLOSE','C_GET_CVD','HTS_AD',NULL);
      close C_GET_AD;
   end if;
   ---
   SQL_LIB.SET_MARK('OPEN','C_GET_CVD','HTS_CVD',NULL);
   open C_GET_CVD;
   SQL_LIB.SET_MARK('FETCH','C_GET_CVD','HTS_CVD',NULL);
   fetch C_GET_CVD into O_cvd_case_no;
   SQL_LIB.SET_MARK('CLOSE','C_GET_CVD','HTS_CVD',NULL);
   close C_GET_CVD;
   ---
   if HTS_SQL.GET_HTS_INFO(O_error_message,
                           L_hts_desc,
                           L_chapter,
                           L_quota_cat,
                           L_more_hts_ind,
                           O_duty_comp_code,
                           L_units,
                           O_units_1,
                           O_units_2,
                           O_units_3,
                           L_cvd_ind,
                           L_ad_ind,
                           L_quota_ind,
                           I_hts,
                           I_import_country_id,
                           I_effect_from,
                           I_effect_to) = FALSE then
      return FALSE;
   end if;
   ---
   -- Getting the tariff treatment with the best rates for the hts.
   -- Loop through all tariff treatments to retrieve tariff treatments
   -- with Country IDs equal to the Origin Country ID passed in
   ---
   SQL_LIB.SET_MARK('OPEN','C_TARIFF','COUNTRY_TARIFF_TREATMENT',
                    'Country: '|| I_origin_country_id);
   FOR C_rec in C_TARIFF LOOP
      L_tariff := C_rec.tariff_treatment;
      ---
      L_excluded := 'N';
      L_eligible := 'N';
      L_exists := 'N';
      ---
      -- Determine if the tariff treatment is supposed to be excluded by
      -- checking the hts tariff treatment exclusions table.
      ---
      SQL_LIB.SET_MARK('OPEN','C_EXCLUDED','HTS_TT_EXCLUSIONS',NULL);
      open C_EXCLUDED;
      SQL_LIB.SET_MARK('FETCH','C_EXCLUDED','HTS_TT_EXCLUSIONS',NULL);
      fetch C_EXCLUDED into L_excluded;
      SQL_LIB.SET_MARK('CLOSE','C_EXCLUDED','HTS_TT_EXCLUSIONS',NULL);
      close C_EXCLUDED;
      ---
      -- If the tariff treatment is not supposed to be excluded ('N'), then
      -- check if the tariff treatment is conditional by checking its
      --- conditional indicator
      if L_excluded = 'N' then
         SQL_LIB.SET_MARK('OPEN','C_CONDITIONAL','TARIFF_TREATMENT','Tariff: ' || L_tariff);
         open C_CONDITIONAL;
         SQL_LIB.SET_MARK('FETCH','C_CONDITIONAL','TARIFF_TREATMENT','Tariff: ' || L_tariff);
         fetch C_CONDITIONAL into L_conditional;

         if C_CONDITIONAL%NOTFOUND then
            SQL_LIB.SET_MARK('CLOSE','C_CONDITIONAL','TARIFF_TREATMENT','Tariff: ' || L_tariff);
            close C_CONDITIONAL;
            O_error_message := SQL_LIB.CREATE_MSG('TARIFF_INVALID',L_tariff,NULL,NULL);
            return FALSE;
         end if;

         SQL_LIB.SET_MARK('CLOSE','C_CONDITIONAL','TARIFF_TREATMENT','Tariff: ' || L_tariff);
         close C_CONDITIONAL;
         ---
         -- If the tariff treatment is conditional ('Y'), then check if the tariff
         -- treatment is eligible
         ---
         if L_conditional = 'Y' then
            SQL_LIB.SET_MARK('OPEN','C_COND_TARIFF','COND_TARIFF_TREATMENT',
                             'Tariff: ' || L_tariff || ', Item: ' || I_item);
            open C_COND_TARIFF;
            SQL_LIB.SET_MARK('FETCH','C_COND_TARIFF','COND_TARIFF_TREATMENT',
                             'Tariff: ' || L_tariff || ', Item: ' || I_item);
            fetch C_COND_TARIFF into L_eligible;
            SQL_LIB.SET_MARK('CLOSE','C_COND_TARIFF','COND_TARIFF_TREATMENT',
                             'Tariff: ' || L_tariff || ', Item: ' || I_item);
            close C_COND_TARIFF;
         end if;
         ---
         -- if the tariff treatment is conditional and eligible or
         -- if the tariff treatment is not condtional then
         -- retrieve the rates
         ---
         if ((L_conditional = 'Y' and L_eligible = 'Y') or
              L_conditional = 'N') then
            SQL_LIB.SET_MARK('OPEN','C_GET_RATES','HTS_TARIFF_TREATMENT',NULL);
            open C_GET_RATES;
            SQL_LIB.SET_MARK('FETCH','C_GET_RATES','HTS_TARIFF_TREATMENT',NULL);
            fetch C_GET_RATES into L_specific,
                                   L_av,
                                   L_other,
                                   L_exists;
            SQL_LIB.SET_MARK('CLOSE','C_GET_RATES','HTS_TARIFF_TREATMENT',NULL);
            close C_GET_RATES;
            if L_exists = 'Y' then
            ---
            -- These rates are compared to the previous 'best' rates to
            -- decide if these rates are better (lowest rates).  If a
            -- better rate is found, then set the variable to hold that value.
            ---
            if ((L_specific <= L_prev_specific) and
                 O_duty_comp_code in ('0','1','2','3','4','5','6','C','D','E')) or
               ((L_av <= L_prev_av) and
                 O_duty_comp_code in ('4','5','6','7','9','C','D','E')) or
               ((L_other <= L_prev_other) and
                 O_duty_comp_code in ('3','6','E')) then

               O_tariff_treatment := L_tariff;
               L_prev_specific    := L_specific;
               L_prev_av          := L_av;
               L_prev_other       := L_other;
               end if; --- rate is better
            end if; --- L_exists = 'Y'
         end if; --- L_conditional = 'N'
      end if;   --- if L_excluded = 'N'
   END LOOP;
   ---
   if O_tariff_treatment is not NULL then
      O_specific_rate := L_prev_specific;
      O_av_rate       := L_prev_av;
      O_other_rate    := L_prev_other;
   end if;
   ---
   if ITEM_HTS_SQL.GET_QUANTITIES(O_error_message,
                                  O_qty_1,
                                  O_qty_2,
                                  O_qty_3,
                                  I_item,
                                  I_origin_country_id,
                                  O_units_1,
                                  O_units_2,
                                  O_units_3) = FALSE then
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
END GET_HTS_DETAILS;
--------------------------------------------------------------------------------
FUNCTION DEFAULT_ASSESS (O_error_message        IN OUT VARCHAR2,
                         I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                         I_hts                  IN     HTS.HTS%TYPE,
                         I_import_country_id    IN     COUNTRY.COUNTRY_ID%TYPE,
                         I_origin_country_id    IN     COUNTRY.COUNTRY_ID%TYPE,
                         I_effect_from          IN     HTS.EFFECT_FROM%TYPE,
                         I_effect_to            IN     HTS.EFFECT_TO%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(65) := 'ITEM_HTS_SQL.DEFAULT_ASSESS';
   L_tariff_treatment   HTS_TARIFF_TREATMENT.TARIFF_TREATMENT%TYPE;
   L_qty_1              NUMBER;
   L_qty_2              NUMBER;
   L_qty_3              NUMBER;
   L_units_1            HTS.UNITS_1%TYPE;
   L_units_2            HTS.UNITS_2%TYPE;
   L_units_3            HTS.UNITS_3%TYPE;
   L_specific_rate      HTS_TARIFF_TREATMENT.SPECIFIC_RATE%TYPE := 0;
   L_av_rate            HTS_TARIFF_TREATMENT.AV_RATE%TYPE       := 0;
   L_other_rate         HTS_TARIFF_TREATMENT.OTHER_RATE%TYPE    := 0;
   L_comp_rate          ELC_COMP.COMP_RATE%TYPE                 := 0;
   L_per_count          ELC_COMP.PER_COUNT%TYPE;
   L_per_count_uom      ELC_COMP.PER_COUNT_UOM%TYPE;
   L_comp_id            ELC_COMP.COMP_ID%TYPE;
   L_cvd_case_no        HTS_CVD.CASE_NO%TYPE;
   L_ad_case_no         HTS_AD.CASE_NO%TYPE;
   L_duty_comp_code     HTS.DUTY_COMP_CODE%TYPE;
   L_tax_comp_code      HTS_TAX.TAX_COMP_CODE%TYPE;
   L_tax_type           HTS_TAX.TAX_TYPE%TYPE;
   L_tax_av_rate        HTS_TAX.TAX_AV_RATE%TYPE;
   L_tax_specific_rate  HTS_TAX.TAX_SPECIFIC_RATE%TYPE;
   L_fee_comp_code      HTS_FEE.FEE_COMP_CODE%TYPE;
   L_fee_type           HTS_FEE.FEE_TYPE%TYPE;
   L_fee_av_rate        HTS_FEE.FEE_AV_RATE%TYPE;
   L_fee_specific_rate  HTS_FEE.FEE_SPECIFIC_RATE%TYPE;

   cursor C_GET_CVD_RATE is
      select rate
        from hts_cvd
       where hts = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and origin_country_id = I_origin_country_id
         and case_no           = L_cvd_case_no;

   cursor C_GET_AD_RATE is
      select rate
        from hts_ad
       where hts = I_hts
         and import_country_id = I_import_country_id
         and effect_from       = I_effect_from
         and effect_to         = I_effect_to
         and origin_country_id = I_origin_country_id
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

BEGIN
   if GET_HTS_DETAILS(O_error_message,
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
                      NULL,
                      I_hts,
                      I_import_country_id,
                      I_origin_country_id,
                      I_effect_from,
                      I_effect_to) = FALSE then
      return FALSE;
   end if;
   ---
   -- Insert Assessments with the Always Default Indicator set to 'Y'.

   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
   insert into item_hts_assess (item,
                                hts,
                                import_country_id,
                                origin_country_id,
                                effect_from,
                                effect_to,
                                comp_id,
                                cvb_code,
                                comp_rate,
                                per_count,
                                per_count_uom,
                                est_assess_value,
                                nom_flag_1,
                                nom_flag_2,
                                nom_flag_3,
                                nom_flag_4,
                                nom_flag_5,
                                display_order,
                                create_datetime,
                                last_update_datetime,
                                last_update_id)
      select I_item,
             I_hts,
             I_import_country_id,
             I_origin_country_id,
             I_effect_from,
             I_effect_to,
             elc.comp_id,
             elc.cvb_code,
             elc.comp_rate,
             elc.per_count,
             elc.per_count_uom,
             0,
             elc.nom_flag_1,
             elc.nom_flag_2,
             elc.nom_flag_3,
             elc.nom_flag_4,
             elc.nom_flag_5,
             elc.display_order,
             sysdate,
             sysdate,
             user
        from elc_comp elc
       where elc.comp_type          = 'A'
         and elc.import_country_id  = I_import_country_id
         and elc.always_default_ind = 'Y'
         and not exists (select 'Y'
                           from item_hts_assess it
                          where it.item = I_item
                            and it.hts  = I_hts
                            and it.import_country_id = I_import_country_id
                            and it.origin_country_id = I_origin_country_id
                            and it.effect_from       = I_effect_from
                            and it.effect_to         = I_effect_to
                            and it.comp_id           = elc.comp_id);
   ---
   -- Insert the Duty Assessments from the Estimated Landed Cost Components table.

   if L_duty_comp_code = '0' then
      L_comp_rate     := 0;
      L_per_count     := NULL;
      L_per_count_uom := NULL;
   elsif L_duty_comp_code in ('1','3','4','6','C') then
      L_comp_rate     := L_specific_rate;
      L_per_count     := 1;
      L_per_count_uom := L_units_1;
   elsif L_duty_comp_code in ('2','5','E') then
      L_comp_rate     := L_specific_rate;
      L_per_count     := 1;
      L_per_count_uom := L_units_2;
   elsif L_duty_comp_code in ('7','9') then
      L_comp_rate     := L_av_rate;
      L_per_count     := NULL;
      L_per_count_uom := NULL;
   elsif L_duty_comp_code = 'D' then
      L_comp_rate     := L_specific_rate;
      L_per_count     := 1;
      L_per_count_uom := L_units_3;
   end if;
   ---
   L_comp_id := 'DTY'||L_duty_comp_code||'A'||I_import_country_id;
   ---
   if L_duty_comp_code in ('0','1','2','3','4','5','6','7','9','C','D','E') then
      SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
      insert into item_hts_assess (item,
                                   hts,
                                   import_country_id,
                                   origin_country_id,
                                   effect_from,
                                   effect_to,
                                   comp_id,
                                   cvb_code,
                                   comp_rate,
                                   per_count,
                                   per_count_uom,
                                   est_assess_value,
                                   nom_flag_1,
                                   nom_flag_2,
                                   nom_flag_3,
                                   nom_flag_4,
                                   nom_flag_5,
                                   display_order,
                                   create_datetime,
                                   last_update_datetime,
                                   last_update_id)
         select I_item,
                I_hts,
                I_import_country_id,
                I_origin_country_id,
                I_effect_from,
                I_effect_to,
                elc.comp_id,
                elc.cvb_code,
                NVL(L_comp_rate, elc.comp_rate),
                L_per_count,
                decode(L_duty_comp_code, '0', NULL,
                                         '7', NULL,
                                         '9', NULL,
                                         NVL(L_per_count_uom, elc.per_count_uom)),
                0,
                elc.nom_flag_1,
                elc.nom_flag_2,
                elc.nom_flag_3,
                elc.nom_flag_4,
                elc.nom_flag_5,
                elc.display_order,
                sysdate,
                sysdate,
                user
           from elc_comp elc
          where elc.comp_id           = L_comp_id
            and elc.comp_type         = 'A'
            and elc.import_country_id = I_import_country_id
            and not exists (select 'Y'
                              from item_hts_assess it
                             where it.item              = I_item
                               and it.hts               = I_hts
                               and it.import_country_id = I_import_country_id
                               and it.origin_country_id = I_origin_country_id
                               and it.effect_from       = I_effect_from
                               and it.effect_to         = I_effect_to
                               and it.comp_id           = elc.comp_id);
   end if;
   ---
   if L_duty_comp_code in ('3','6') then
      L_comp_rate     := L_other_rate;
      L_per_count     := 1;
      L_per_count_uom := L_units_2;
   elsif L_duty_comp_code in ('4','5','D') then
      L_comp_rate     := L_av_rate;
      L_per_count     := NULL;
      L_per_count_uom := NULL;
   elsif L_duty_comp_code = 'E' then
      L_comp_rate     := L_other_rate;
      L_per_count     := 1;
      L_per_count_uom := L_units_3;
   end if;
   ---
   L_comp_id := 'DTY'||L_duty_comp_code||'B'||I_import_country_id;
   ---
   if L_duty_comp_code in ('3','4','5','6','D','E') then
      SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
      insert into item_hts_assess (item,
                                   hts,
                                   import_country_id,
                                   origin_country_id,
                                   effect_from,
                                   effect_to,
                                   comp_id,
                                   cvb_code,
                                   comp_rate,
                                   per_count,
                                   per_count_uom,
                                   est_assess_value,
                                   nom_flag_1,
                                   nom_flag_2,
                                   nom_flag_3,
                                   nom_flag_4,
                                   nom_flag_5,
                                   display_order,
                                   create_datetime,
                                   last_update_datetime,
                                   last_update_id)
         select I_item,
                I_hts,
                I_import_country_id,
                I_origin_country_id,
                I_effect_from,
                I_effect_to,
                elc.comp_id,
                elc.cvb_code,
                NVL(L_comp_rate, elc.comp_rate),
                L_per_count,
                decode(L_duty_comp_code, '4', NULL,
                                         '5', NULL,
                                         'D', NULL,
                                         NVL(L_per_count_uom, elc.per_count_uom)),
                0,
                elc.nom_flag_1,
                elc.nom_flag_2,
                elc.nom_flag_3,
                elc.nom_flag_4,
                elc.nom_flag_5,
                elc.display_order,
                sysdate,
                sysdate,
                user
           from elc_comp elc
          where elc.comp_id           = L_comp_id
            and elc.comp_type         = 'A'
            and elc.import_country_id = I_import_country_id
            and not exists (select 'Y'
                              from item_hts_assess it
                             where it.item              = I_item
                               and it.hts               = I_hts
                               and it.import_country_id = I_import_country_id
                               and it.origin_country_id = I_origin_country_id
                               and it.effect_from       = I_effect_from
                               and it.effect_to         = I_effect_to
                               and it.comp_id           = elc.comp_id);
   end if;
   ---
   L_comp_id := 'DTY'||L_duty_comp_code||'C'||I_import_country_id;
   ---
   if L_duty_comp_code in ('6','E') then
      SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
      insert into item_hts_assess (item,
                                   hts,
                                   import_country_id,
                                   origin_country_id,
                                   effect_from,
                                   effect_to,
                                   comp_id,
                                   cvb_code,
                                   comp_rate,
                                   per_count,
                                   per_count_uom,
                                   est_assess_value,
                                   nom_flag_1,
                                   nom_flag_2,
                                   nom_flag_3,
                                   nom_flag_4,
                                   nom_flag_5,
                                   display_order,
                                   create_datetime,
                                   last_update_datetime,
                                   last_update_id)
         select I_item,
                I_hts,
                I_import_country_id,
                I_origin_country_id,
                I_effect_from,
                I_effect_to,
                elc.comp_id,
                elc.cvb_code,
                NVL(L_av_rate, elc.comp_rate),
                NULL,
                NULL,
                0,
                elc.nom_flag_1,
                elc.nom_flag_2,
                elc.nom_flag_3,
                elc.nom_flag_4,
                elc.nom_flag_5,
                elc.display_order,
                sysdate,
                sysdate,
                user
           from elc_comp elc
          where elc.comp_id           = L_comp_id
            and elc.comp_type         = 'A'
            and elc.import_country_id = I_import_country_id
            and not exists (select 'Y'
                              from item_hts_assess it
                             where it.item              = I_item
                               and it.hts               = I_hts
                               and it.import_country_id = I_import_country_id
                               and it.origin_country_id = I_origin_country_id
                               and it.effect_from       = I_effect_from
                               and it.effect_to         = I_effect_to
                               and it.comp_id           = elc.comp_id);
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
   insert into item_hts_assess (item,
                                hts,
                                import_country_id,
                                origin_country_id,
                                effect_from,
                                effect_to,
                                comp_id,
                                cvb_code,
                                comp_rate,
                                per_count,
                                per_count_uom,
                                est_assess_value,
                                nom_flag_1,
                                nom_flag_2,
                                nom_flag_3,
                                nom_flag_4,
                                nom_flag_5,
                                display_order,
                                create_datetime,
                                last_update_datetime,
                                last_update_id)
      select I_item,
             I_hts,
             I_import_country_id,
             I_origin_country_id,
             I_effect_from,
             I_effect_to,
             elc.comp_id,
             elc.cvb_code,
             100,
             NULL,
             NULL,
             0,
             elc.nom_flag_1,
             elc.nom_flag_2,
             elc.nom_flag_3,
             elc.nom_flag_4,
             elc.nom_flag_5,
             elc.display_order,
             sysdate,
             sysdate,
             user
        from elc_comp elc
       where elc.comp_id           = 'DUTY'||I_import_country_id
         and elc.comp_type         = 'A'
         and elc.import_country_id = I_import_country_id
         and not exists(select 'Y'
                          from item_hts_assess it
                         where it.item              = I_item
                           and it.hts               = I_hts
                           and it.import_country_id = I_import_country_id
                           and it.origin_country_id = I_origin_country_id
                           and it.effect_from       = I_effect_from
                           and it.effect_to         = I_effect_to
                           and it.comp_id           = elc.comp_id);

   -- Insert the Tax Assessments from the Estimated Landed Cost Components table.
   ---
   for T_rec in C_GET_TAX_INFO loop
      L_tax_type      := T_rec.tax_type;
      L_tax_comp_code := T_rec.tax_comp_code;
      L_specific_rate := T_rec.tax_specific_rate;
      L_av_rate       := T_rec.tax_av_rate;
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
         SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
         insert into item_hts_assess (item,
                                      hts,
                                      import_country_id,
                                      origin_country_id,
                                      effect_from,
                                      effect_to,
                                      comp_id,
                                      cvb_code,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      est_assess_value,
                                      nom_flag_1,
                                      nom_flag_2,
                                      nom_flag_3,
                                      nom_flag_4,
                                      nom_flag_5,
                                      display_order,
                                      create_datetime,
                                      last_update_datetime,
                                      last_update_id)
            select I_item,
                   I_hts,
                   I_import_country_id,
                   I_origin_country_id,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   elc.cvb_code,
                   NVL(L_comp_rate, elc.comp_rate),
                   L_per_count,
                   decode(L_tax_comp_code, '7', NULL,
                                           '9', NULL,
                                           NVL(L_per_count_uom, elc.per_count_uom)),
                   0,
                   elc.nom_flag_1,
                   elc.nom_flag_2,
                   elc.nom_flag_3,
                   elc.nom_flag_4,
                   elc.nom_flag_5,
                   elc.display_order,
                   sysdate,
                   sysdate,
                   user
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from item_hts_assess it
                                where it.item              = I_item
                                  and it.hts               = I_hts
                                  and it.import_country_id = I_import_country_id
                                  and it.origin_country_id = I_origin_country_id
                                  and it.effect_from       = I_effect_from
                                  and it.effect_to         = I_effect_to
                                  and it.comp_id           = elc.comp_id);
      end if;
      ---
      L_comp_id := L_tax_type||L_tax_comp_code||'B'||I_import_country_id;
      ---
      if L_tax_comp_code in ('4','5','D') then
         SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
         insert into item_hts_assess (item,
                                      hts,
                                      import_country_id,
                                      origin_country_id,
                                      effect_from,
                                      effect_to,
                                      comp_id,
                                      cvb_code,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      est_assess_value,
                                      nom_flag_1,
                                      nom_flag_2,
                                      nom_flag_3,
                                      nom_flag_4,
                                      nom_flag_5,
                                      display_order,
                                      create_datetime,
                                      last_update_datetime,
                                      last_update_id)
            select I_item,
                   I_hts,
                   I_import_country_id,
                   I_origin_country_id,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   elc.cvb_code,
                   NVL(L_av_rate, elc.comp_rate),
                   NULL,
                   NULL,
                   0,
                   elc.nom_flag_1,
                   elc.nom_flag_2,
                   elc.nom_flag_3,
                   elc.nom_flag_4,
                   elc.nom_flag_5,
                   elc.display_order,
                   sysdate,
                   sysdate,
                   user
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from item_hts_assess it
                                where it.item              = I_item
                                  and it.hts               = I_hts
                                  and it.import_country_id = I_import_country_id
                                  and it.origin_country_id = I_origin_country_id
                                  and it.effect_from       = I_effect_from
                                  and it.effect_to         = I_effect_to
                                  and it.comp_id           = elc.comp_id);
      end if;
   end loop;
   ---
   -- Insert the Fee Assessments from the Estimated Landed Cost Components table.
   ---
   for F_rec in C_GET_FEE_INFO loop
      L_fee_type      := F_rec.fee_type;
      L_fee_comp_code := F_rec.fee_comp_code;
      L_specific_rate := F_rec.fee_specific_rate;
      L_av_rate       := F_rec.fee_av_rate;
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
         SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
         insert into item_hts_assess(item,
                                     hts,
                                     import_country_id,
                                     origin_country_id,
                                     effect_from,
                                     effect_to,
                                     comp_id,
                                     cvb_code,
                                     comp_rate,
                                     per_count,
                                     per_count_uom,
                                     est_assess_value,
                                     nom_flag_1,
                                     nom_flag_2,
                                     nom_flag_3,
                                     nom_flag_4,
                                     nom_flag_5,
                                     display_order,
                                     create_datetime,
                                     last_update_datetime,
                                     last_update_id)
            select I_item,
                   I_hts,
                   I_import_country_id,
                   I_origin_country_id,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   elc.cvb_code,
                   NVL(L_comp_rate, elc.comp_rate),
                   L_per_count,
                   decode(L_fee_comp_code, '7', NULL,
                                           '9', NULL,
                                           NVL(L_per_count_uom, elc.per_count_uom)),
                   0,
                   elc.nom_flag_1,
                   elc.nom_flag_2,
                   elc.nom_flag_3,
                   elc.nom_flag_4,
                   elc.nom_flag_5,
                   elc.display_order,
                   sysdate,
                   sysdate,
                   user
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from item_hts_assess it
                                where it.item              = I_item
                                  and it.hts               = I_hts
                                  and it.import_country_id = I_import_country_id
                                  and it.origin_country_id = I_origin_country_id
                                  and it.effect_from       = I_effect_from
                                  and it.effect_to         = I_effect_to
                                  and it.comp_id           = elc.comp_id);
      end if;
      ---
      L_comp_id := L_fee_type||L_fee_comp_code||'B'||I_import_country_id;
      ---
      if L_fee_comp_code in ('4','5','D') then
         SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
         insert into item_hts_assess(item,
                                     hts,
                                     import_country_id,
                                     origin_country_id,
                                     effect_from,
                                     effect_to,
                                     comp_id,
                                     cvb_code,
                                     comp_rate,
                                     per_count,
                                     per_count_uom,
                                     est_assess_value,
                                     nom_flag_1,
                                     nom_flag_2,
                                     nom_flag_3,
                                     nom_flag_4,
                                     nom_flag_5,
                                     display_order,
                                     create_datetime,
                                     last_update_datetime,
                                     last_update_id)
            select I_item,
                   I_hts,
                   I_import_country_id,
                   I_origin_country_id,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   elc.cvb_code,
                   NVL(L_av_rate, elc.comp_rate),
                   NULL,
                   NULL,
                   0,
                   elc.nom_flag_1,
                   elc.nom_flag_2,
                   elc.nom_flag_3,
                   elc.nom_flag_4,
                   elc.nom_flag_5,
                   elc.display_order,
                   sysdate,
                   sysdate,
                   user
              from elc_comp elc
             where elc.comp_id           = L_comp_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from item_hts_assess it
                                where it.item              = I_item
                                  and it.hts               = I_hts
                                  and it.import_country_id = I_import_country_id
                                  and it.origin_country_id = I_origin_country_id
                                  and it.effect_from       = I_effect_from
                                  and it.effect_to         = I_effect_to
                                  and it.comp_id           = elc.comp_id);
      end if;
   end loop;
   ---
   -- Insert the CVD (Countervailing) Assessments
   -- from the Estimated Landed Cost Components table.
   if L_cvd_case_no is not NULL then
      SQL_LIB.SET_MARK('OPEN',  'C_GET_CVD_RATE', 'HTS_CVD', NULL);
      open C_GET_CVD_RATE;
      SQL_LIB.SET_MARK('FETCH',  'C_GET_CVD_RATE', 'HTS_CVD', NULL);
      fetch C_GET_CVD_RATE into L_comp_rate;
      if C_GET_CVD_RATE%FOUND then
         SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
         insert into item_hts_assess (item,
                                      hts,
                                      import_country_id,
                                      origin_country_id,
                                      effect_from,
                                      effect_to,
                                      comp_id,
                                      cvb_code,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      est_assess_value,
                                      nom_flag_1,
                                      nom_flag_2,
                                      nom_flag_3,
                                      nom_flag_4,
                                      nom_flag_5,
                                      display_order,
                                      create_datetime,
                                      last_update_datetime,
                                      last_update_id)
            select I_item,
                   I_hts,
                   I_import_country_id,
                   I_origin_country_id,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   elc.cvb_code,
                   NVL(L_comp_rate, elc.comp_rate),
                   NULL,
                   NULL,
                   0,
                   elc.nom_flag_1,
                   elc.nom_flag_2,
                   elc.nom_flag_3,
                   elc.nom_flag_4,
                   elc.nom_flag_5,
                   elc.display_order,
                   sysdate,
                   sysdate,
                   user
              from elc_comp elc
             where elc.comp_id           = 'CVD'||I_import_country_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from item_hts_assess it
                                where it.item              = I_item
                                  and it.hts               = I_hts
                                  and it.import_country_id = I_import_country_id
                                  and it.origin_country_id = I_origin_country_id
                                  and it.effect_from       = I_effect_from
                                  and it.effect_to         = I_effect_to
                                  and it.comp_id           = elc.comp_id);
      end if;
      SQL_LIB.SET_MARK('CLOSE',  'C_GET_CVD_RATE', 'HTS_CVD', NULL);
      close C_GET_CVD_RATE;
   end if;  -- L_cvd_case_no is not NULL
   ---
   -- Insert the AD (Anti-Dumping) Assessments
   -- from the Estimated Landed Cost Components table.
   ---
   if L_ad_case_no is not NULL then
      SQL_LIB.SET_MARK('OPEN',  'C_GET_AD_RATE', 'HTS_AD', NULL);
      open C_GET_AD_RATE;
      SQL_LIB.SET_MARK('FETCH',  'C_GET_AD_RATE', 'HTS_AD', NULL);
      fetch C_GET_AD_RATE into L_comp_rate;
      if C_GET_AD_RATE%FOUND then
         SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS', NULL);
         insert into item_hts_assess (item,
                                      hts,
                                      import_country_id,
                                      origin_country_id,
                                      effect_from,
                                      effect_to,
                                      comp_id,
                                      cvb_code,
                                      comp_rate,
                                      per_count,
                                      per_count_uom,
                                      est_assess_value,
                                      nom_flag_1,
                                      nom_flag_2,
                                      nom_flag_3,
                                      nom_flag_4,
                                      nom_flag_5,
                                      display_order,
                                      create_datetime,
                                      last_update_datetime,
                                      last_update_id)
            select I_item,
                   I_hts,
                   I_import_country_id,
                   I_origin_country_id,
                   I_effect_from,
                   I_effect_to,
                   elc.comp_id,
                   elc.cvb_code,
                   NVL(L_comp_rate, elc.comp_rate),
                   NULL,
                   NULL,
                   0,
                   elc.nom_flag_1,
                   elc.nom_flag_2,
                   elc.nom_flag_3,
                   elc.nom_flag_4,
                   elc.nom_flag_5,
                   elc.display_order,
                   sysdate,
                   sysdate,
                   user
              from elc_comp elc
             where elc.comp_id           = 'AD'||I_import_country_id
               and elc.comp_type         = 'A'
               and elc.import_country_id = I_import_country_id
               and not exists (select 'Y'
                                 from item_hts_assess it
                                where it.item              = I_item
                                  and it.hts               = I_hts
                                  and it.import_country_id = I_import_country_id
                                  and it.origin_country_id = I_origin_country_id
                                  and it.effect_from       = I_effect_from
                                  and it.effect_to         = I_effect_to
                                  and it.comp_id           = elc.comp_id);
      end if;
      SQL_LIB.SET_MARK('CLOSE',  'C_GET_AD_RATE', 'HTS_AD', NULL);
      close C_GET_AD_RATE;
   end if;  -- L_ad_case_no is not NULL
   ---
   return TRUE;

EXCEPTION
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END DEFAULT_ASSESS;
---------------------------------------------------------------------------------------------
FUNCTION DEFAULT_CALC_ASSESS (O_error_message        IN OUT VARCHAR2,
                              I_item                 IN     ITEM_MASTER.ITEM%TYPE,
                              I_hts                  IN     HTS.HTS%TYPE,
                              I_import_country_id    IN     COUNTRY.COUNTRY_ID%TYPE,
                              I_origin_country_id    IN     COUNTRY.COUNTRY_ID%TYPE,
                              I_effect_from          IN     HTS.EFFECT_FROM%TYPE,
                              I_effect_to            IN     HTS.EFFECT_TO%TYPE)
   RETURN BOOLEAN IS

   L_program            VARCHAR2(65) := 'ITEM_HTS_SQL.DEFAULT_CALC_ASSESS';

BEGIN
   ---
   -- Default in the assessments for the HTS code passed into the function.
   ---
   if DEFAULT_ASSESS(O_error_message,
                     I_item,
                     I_hts,
                     I_import_country_id,
                     I_origin_country_id,
                     I_effect_from,
                     I_effect_to) = FALSE then
      return FALSE;
   end if;
   ---
   -- Need to calculate all of the expenses.
   ---
   if ELC_CALC_SQL.CALC_COMP(O_error_message,
                             'IA',
                             I_item,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
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
END DEFAULT_CALC_ASSESS;
---------------------------------------------------------------------------------------------
FUNCTION COPY_DOWN_PARENT_HTS (O_error_message  IN OUT VARCHAR2,
                               I_item           IN     ITEM_MASTER.ITEM%TYPE)
   RETURN BOOLEAN IS

   L_program       VARCHAR2(65) := 'ITEM_HTS_SQL.COPY_DOWN_PARENT_HTS';
   L_table         VARCHAR2(65);
   RECORD_LOCKED   EXCEPTION;
   PRAGMA          EXCEPTION_INIT(Record_Locked, -54);

   cursor C_LOCK_ITEM_HTS_ASSESS is
      select 'x'
        from item_hts_assess
       where item in (select item
                        from item_master
                       where (item_parent = I_item
                          or item_grandparent = I_item)
                         and item_level <= tran_level)
         for update nowait;

   cursor C_LOCK_ITEM_HTS is
      select 'x'
        from item_hts
       where item in (select item
                        from item_master
                       where (item_parent = I_item
                          or item_grandparent = I_item)
                         and item_level <= tran_level)
         for update nowait;

BEGIN

   L_table := 'ITEM_HTS_ASSESS';

   open  C_LOCK_ITEM_HTS_ASSESS;
   close C_LOCK_ITEM_HTS_ASSESS;

   SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_HTS_ASSESS',
                'Item: ' || I_item);

   delete item_hts_assess
       where item in (select item
                        from item_master
                       where (item_parent = I_item
                          or item_grandparent = I_item)
                         and item_level <= tran_level);
   ---
   L_table := 'ITEM_HTS';

   open  C_LOCK_ITEM_HTS;
   close C_LOCK_ITEM_HTS;

   SQL_LIB.SET_MARK('DELETE', NULL, 'ITEM_HTS',
                'Item: ' || I_item);

   delete item_hts
       where item in (select item
                        from item_master
                       where (item_parent = I_item
                          or item_grandparent = I_item)
                         and item_level <= tran_level);
   ---
   if ELC_CALC_SQL.CALC_COMP(O_error_message,
                             'IA',
                             I_item,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL) = FALSE then
      return FALSE;
   end if;
   ---
   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS',
                'Item: ' || I_item);

   insert into item_hts (item,
                         hts,
                         import_country_id,
                         origin_country_id,
                         effect_from,
                         effect_to,
                         status,
                         create_datetime,
                         last_update_datetime,
                         last_update_id)
      select im.item,
             i.hts,
             i.import_country_id,
             i.origin_country_id,
             i.effect_from,
             i.effect_to,
             i.status,
             sysdate,
             sysdate,
             user
        from item_hts i,
             item_master im
       where i.item = I_item
         and (item_parent = i.item
          or im.item_grandparent = i.item)
         and im.item_level <= im.tran_level;

   SQL_LIB.SET_MARK('INSERT', NULL, 'ITEM_HTS_ASSESS',
                'Item: ' || I_item);

   insert into item_hts_assess (item,
                                hts,
                                import_country_id,
                                origin_country_id,
                                effect_from,
                                effect_to,
                                comp_id,
                                cvb_code,
                                comp_rate,
                                per_count,
                                per_count_uom,
                                est_assess_value,
                                nom_flag_1,
                                nom_flag_2,
                                nom_flag_3,
                                nom_flag_4,
                                nom_flag_5,
                                display_order,
                                create_datetime,
                                last_update_datetime,
                                last_update_id)
      select im.item,
             i.hts,
             i.import_country_id,
             i.origin_country_id,
             i.effect_from,
             i.effect_to,
             i.comp_id,
             i.cvb_code,
             i.comp_rate,
             i.per_count,
             i.per_count_uom,
             i.est_assess_value,
             i.nom_flag_1,
             i.nom_flag_2,
             i.nom_flag_3,
             i.nom_flag_4,
             i.nom_flag_5,
             i.display_order,
             sysdate,
             sysdate,
             user
        from item_hts_assess i,
             item_master im
       where i.item = I_item
         and (im.item_parent = i.item
          or im.item_grandparent = i.item)
         and item_level <= tran_level;

   return TRUE;

EXCEPTION
   when RECORD_LOCKED then
      O_error_message := sql_lib.create_msg('TABLE_LOCKED',
                                           L_table,
                                           I_item);
      return FALSE;
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                            SQLERRM,
                                            L_program,
                                            to_char(SQLCODE));
      return FALSE;
END COPY_DOWN_PARENT_HTS;
-------------------------------------------------------------------------------------------------------
-- 25-Jun-2007 Govindarajan - MOD 365b1 Begin
-------------------------------------------------------------------------------------------------------
-- Function Name  : TSL_COPY_BASE_HTS
-- Purpose        : Remove old ITEM_HTS and ITEM_HTS_ASSESS values of all Variant Items
--                  associated to the Base Item, get latest values for the Base Item,
--                  and insert new ITEM_HTS and ITEM_HTS_ASSESS values for the valid
--                  Variant Items.
-------------------------------------------------------------------------------------------------------
FUNCTION TSL_COPY_BASE_HTS (O_error_message IN OUT RTK_ERRORS.RTK_TEXT%TYPE,
                            I_item          IN     ITEM_MASTER.ITEM%TYPE)
   return BOOLEAN is

   L_table          VARCHAR2(65);
   L_program        VARCHAR2(300) := 'ITEM_HTS_SQL.TSL_COPY_BASE_HTS';
   RECORD_LOCKED    EXCEPTION;
   PRAGMA           EXCEPTION_INIT(RECORD_LOCKED, -54);
   L_valid          BOOLEAN;

   -- This cursor will lock the variant information
   -- on the table ITEM_HTS_ASSESS table
   cursor C_LOCK_ITEM_HTS_ASSESS is
      select 'x'
        from item_hts_assess iha
       where iha.item in (select im.item
                            from item_master im
                           where im.tsl_base_item  = I_item
                             and im.tsl_base_item != im.item
                             and im.item_level     = im.tran_level
                             and im.item_level     = 2)
         for update nowait;

   -- This cursor will lock the variant information on the table ITEM_HTS table
   cursor C_LOCK_ITEM_HTS is
      select 'x'
        from item_hts ih
       where ih.item in (select im.item
                           from item_master im
                          where im.tsl_base_item  = I_item
                            and im.tsl_base_item != im.item
                            and im.item_level     = im.tran_level
                            and im.item_level     = 2)
         for update nowait;

   -- This cursor will return the Variant Items number associated to the
   -- Base Item information.
   cursor C_INSERT_ITEM_HTS_ASSESS is
      select im.item item,
             iha.hts,
             iha.import_country_id,
             iha.origin_country_id,
             iha.effect_from,
             iha.effect_to,
             iha.comp_id,
             iha.cvb_code,
             iha.comp_rate,
             iha.per_count,
             iha.per_count_uom,
             iha.est_assess_value,
             iha.nom_flag_1,
             iha.nom_flag_2,
             iha.nom_flag_3,
             iha.nom_flag_4,
             iha.nom_flag_5,
             iha.display_order
        from item_hts_assess iha,
             item_master im
       where iha.item           = I_item
         and iha.item           = NVL(im.tsl_base_item, im.item)
         and im.tsl_base_item  != im.item
         and im.item_level      = im.tran_level
         and im.item_level      = 2;

   -- This cursor will return the Variant Items number associated to the
   -- Base Item information.
   cursor C_INSERT_ITEM_HTS is
      select im.item item,
             ih.hts,
             ih.import_country_id,
             ih.origin_country_id,
             ih.effect_from,
             ih.effect_to,
             ih.status
        from item_hts ih,
             item_master im
       where ih.item           = I_item
         and ih.item           = NVL(im.tsl_base_item, im.item)
         and im.tsl_base_item != im.item
         and im.item_level     = im.tran_level
         and im.item_level     = 2;
BEGIN
      if I_item is NULL then                                       -- L1 begin
          -- If input item is null then throws an error
          O_error_message := SQL_LIB.CREATE_MSG('REQUIRED_INPUT_IS_NULL',
                                                I_item,
                                                L_program,
                                                NULL);
          return FALSE;
      else                                                        -- L1 else

          L_table := 'ITEM_HTS_ASSESS';
          -- Opening and closing the C_LOCK_ITEM_HTS_ASSESS cursor
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_ITEM_HTS_ASSESS',
                           L_table,
                           'ITEM: ' ||I_item);
          open C_LOCK_ITEM_HTS_ASSESS;

          SQL_LIB.SET_MARK('CLOSE',
                           L_table,
                           'ITEM_HTS_ASSESS',
                           'ITEM: ' ||I_item);
          close C_LOCK_ITEM_HTS_ASSESS;

          -- Deleting the records from ITEM_HTS_ASSESS table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           L_table,
                           'ITEM: ' ||I_item);

          delete from item_hts_assess
           where item in (select im.item
                            from item_master im
                           where im.tsl_base_item  = I_item
                             and im.tsl_base_item != im.item
                             and im.item_level     = im.tran_level
                             and im.item_level     = 2);

          L_table := 'ITEM_HTS';
          -- Opening and closing the C_LOCK_ITEM_HTS cursor
          SQL_LIB.SET_MARK('OPEN',
                           'C_LOCK_ITEM_HTS',
                           L_table,
                           'ITEM: ' ||I_item);
          open C_LOCK_ITEM_HTS;

          SQL_LIB.SET_MARK('CLOSE',
                           'C_LOCK_ITEM_HTS',
                           L_table,
                           'ITEM: ' ||I_item);
          close C_LOCK_ITEM_HTS;

          -- Deleting the records from ITEM_HTS table
          SQL_LIB.SET_MARK('DELETE',
                           NULL,
                           L_table,
                           'ITEM: ' ||I_item);

          delete from item_hts
           where item in (select im.item
                            from item_master im
                           where im.tsl_base_item  = I_item
                             and im.tsl_base_item != im.item
                             and im.item_level     = im.tran_level
                             and im.item_level     = 2);

          -- calling ELC_CALC_SQL.CALC_COMP function
          L_valid := ELC_CALC_SQL.CALC_COMP (O_error_message,
                                             'IA',
                                             I_item,
                                             NULL ,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL);

          if L_valid = TRUE then              -- L2 begin

              -- Cursor for ITEM_HTS table
              -- Opening the cursor C_INSERT_ITEM_HTS
              SQL_LIB.SET_MARK('OPEN',
                               'C_INSERT_ITEM_HTS',
                               L_table,
                               'ITEM: ' ||I_item);
              FOR C_insert_item_hts_rec in C_INSERT_ITEM_HTS
              LOOP                                            -- L3 begin
                  -- Inserting records into ITEM_HTS table
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'ITEM_HTS',
                                   'ITEM: ' ||I_item);

                  insert into item_hts
                              (item,
                               hts,
                               import_country_id,
                               origin_country_id,
                               effect_from,
                               effect_to,
                               status,
                               create_datetime,
                               last_update_datetime,
                               last_update_id)
                       values (C_insert_item_hts_rec.item,
                               C_insert_item_hts_rec.hts,
                               C_insert_item_hts_rec.import_country_id,
                               C_insert_item_hts_rec.origin_country_id,
                               C_insert_item_hts_rec.effect_from,
                               C_insert_item_hts_rec.effect_to,
                               C_insert_item_hts_rec.status,
                               SYSDATE,
                               SYSDATE,
                               USER);

              END LOOP;         -- L3 end

                -- Opening the cursor C_INSERT_ITEM_HTS_ASSESS
              SQL_LIB.SET_MARK('OPEN',
                               'C_INSERT_ITEM_HTS_ASSESS',
                               L_table,
                               'ITEM: ' ||I_item);
              FOR C_insert_item_hts_assess_rec in C_INSERT_ITEM_HTS_ASSESS
              LOOP                                                            -- L4 begin
                  -- Inserting records into ITEM_HTS_ASSESS table
                  SQL_LIB.SET_MARK('INSERT',
                                   NULL,
                                   'ITEM_HTS_ASSESS',
                                   'ITEM: ' ||I_item);

                  insert into item_hts_assess
                              (item,
                               hts,
                               import_country_id,
                               origin_country_id,
                               effect_from,
                               effect_to,
                               comp_id,
                               cvb_code,
                               comp_rate,
                               per_count,
                               per_count_uom,
                               est_assess_value,
                               nom_flag_1,
                               nom_flag_2,
                               nom_flag_3,
                               nom_flag_4,
                               nom_flag_5,
                               display_order,
                               create_datetime,
                               last_update_datetime,
                               last_update_id)
                       values (C_insert_item_hts_assess_rec.item,
                               C_insert_item_hts_assess_rec.hts,
                               C_insert_item_hts_assess_rec.import_country_id,
                               C_insert_item_hts_assess_rec.origin_country_id,
                               C_insert_item_hts_assess_rec.effect_from,
                               C_insert_item_hts_assess_rec.effect_to,
                               C_insert_item_hts_assess_rec.comp_id,
                               C_insert_item_hts_assess_rec.cvb_code,
                               C_insert_item_hts_assess_rec.comp_rate,
                               C_insert_item_hts_assess_rec.per_count,
                               C_insert_item_hts_assess_rec.per_count_uom,
                               C_insert_item_hts_assess_rec.est_assess_value,
                               C_insert_item_hts_assess_rec.nom_flag_1,
                               C_insert_item_hts_assess_rec.nom_flag_2,
                               C_insert_item_hts_assess_rec.nom_flag_3,
                               C_insert_item_hts_assess_rec.nom_flag_4,
                               C_insert_item_hts_assess_rec.nom_flag_5,
                               C_insert_item_hts_assess_rec.display_order,
                               SYSDATE,
                               SYSDATE,
                               USER);
              END LOOP;                 -- L4 end

              return TRUE;
          else                       -- L2 else
              return FALSE;
          end if;                    -- L2 end
      end if;                                              -- L1 end
EXCEPTION
   -- Raising an exception for record lock error
   when RECORD_LOCKED then
      O_error_message := SQL_LIB.CREATE_MSG('TABLE_LOCKED',
                                            L_table,
                                            L_program,
                                            'ITEM: ' ||I_item);
      return FALSE;

   -- Raising an exception for others
   when OTHERS then
      O_error_message := SQL_LIB.CREATE_MSG('PACKAGE_ERROR',
                                             SQLERRM,
                                             L_program,
                                             TO_CHAR(SQLCODE));
      return FALSE;

END TSL_COPY_BASE_HTS;
-------------------------------------------------------------------------------------------------------
-- 25-Jun-2007 Govindarajan - MOD 365b1 End
-------------------------------------------------------------------------------------------------------
END ITEM_HTS_SQL;
/

